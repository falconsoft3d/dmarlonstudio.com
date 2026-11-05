import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/ai_usage.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';

/// Paso visible de una conversación con Claude Code.
class ClaudeCodeStep {
  const ClaudeCodeStep(this.kind, this.text);

  /// `user`, `text`, `tool`, `done` o `error`.
  final String kind;
  final String text;
}

/// Claude Code (la CLI `claude`) trabajando en la carpeta de un proyecto.
///
/// Se lanza en modo no interactivo (`-p`, `--output-format stream-json`) con
/// la sesión del usuario de Claude Code: no hace falta clave de API. Puede
/// leer y editar los archivos del proyecto (sin terminal) y la conversación
/// sigue con `--resume`.
class ClaudeCode {
  ClaudeCode(this.dir);

  /// Carpeta del proyecto: el directorio de trabajo de Claude Code.
  final String dir;

  String? sessionId;
  final steps = <ClaudeCodeStep>[];
  Process? _proc;
  bool get running => _proc != null;

  /// Conversaciones por proyecto: sobreviven a cerrar y abrir el Diseñador.
  static final _byDir = <String, ClaudeCode>{};
  static ClaudeCode of(String dir) =>
      _byDir.putIfAbsent(p.normalize(dir), () => ClaudeCode(dir));

  /// Programa que se lanza en lugar de `claude` (solo en las pruebas).
  static String? exeOverride;

  /// Ruta de `claude`. Una app abierta desde el Finder no recibe el PATH
  /// de la terminal: se miran también las carpetas donde se instala.
  static String? find() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final names = Platform.isWindows
        ? ['claude.exe', 'claude.cmd']
        : ['claude'];
    final dirs = [
      ...(Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ),
      if (home != null) ...[
        p.join(home, '.local', 'bin'),
        p.join(home, '.claude', 'local'),
        p.join(home, '.npm-global', 'bin'),
        if (Platform.isWindows)
          p.join(Platform.environment['APPDATA'] ?? '', 'npm'),
      ],
      if (!Platform.isWindows) ...['/opt/homebrew/bin', '/usr/local/bin'],
    ];
    for (final d in dirs) {
      if (d.isEmpty) continue;
      for (final n in names) {
        final f = p.join(d, n);
        if (File(f).existsSync()) return f;
      }
    }
    return null;
  }

  /// Lo que Claude Code debe saber del proyecto, además de lo que lea.
  static String _context(String formName, String unit) =>
      '''You are working inside DMarlon Studio, a visual desktop IDE. The current folder is a DMarlon Studio project:
- project.dmsproj: JSON with the project metadata and "design": the window ("name", "props" such as title/width/height, "events") and "widgets" (each with "kind", "name", "x", "y", "width", "height", "parent", "props", "events" mapping an event key to a method name). The visual designer reads this file.
- $unit: the user's Python code for the window class $formName (it subclasses the generated FormDesign, which creates self.root and every widget as self.<Name>). Event handlers are methods of that class named in the design's "events". Put startup logic in the form's create event handler; if you define __init__, call super().__init__() first.
- build/: generated output. Never edit it.
When the user asks for interface changes, edit the design in project.dmsproj (keep valid JSON, unique widget names, integer coordinates) and add or change the handler methods in $unit so every event in the design has its method. Keep changes minimal. Do not run commands. Reply briefly, in the language the user writes in, saying what you changed.''';

  /// Envía [prompt]. [onStep] recibe cada paso; el futuro termina cuando
  /// Claude Code acaba (devuelve si cambió algún archivo).
  Future<bool> send(
    String prompt, {
    required String formName,
    required String unit,
    required void Function(ClaudeCodeStep step) onStep,
  }) async {
    if (running) throw UserError(tr('Claude Code ya está trabajando.'));
    await AiUsage.check(project: dir);
    final exe = exeOverride ?? find();
    if (exe == null) {
      throw UserError(
        tr(
          'No se encontró Claude Code. Instálelo desde https://claude.com/claude-code e inicie sesión una vez con «claude» en una terminal.',
        ),
      );
    }
    void add(ClaudeCodeStep s) {
      steps.add(s);
      onStep(s);
    }

    add(ClaudeCodeStep('user', prompt));
    var edited = false;
    final Process proc;
    try {
      proc = await Process.start(
        exe,
        [
          '-p',
          prompt,
          '--output-format',
          'stream-json',
          '--verbose',
          '--permission-mode',
          'acceptEdits',
          '--allowedTools',
          'Read,Edit,Write,Glob,Grep',
          '--disallowedTools',
          'Bash',
          '--append-system-prompt',
          _context(formName, unit),
          if (sessionId != null) ...['--resume', sessionId!],
        ],
        workingDirectory: dir,
        environment: {
          // Las carpetas habituales, por si se lanzó desde el Finder.
          if (!Platform.isWindows)
            'PATH': [
              Platform.environment['PATH'] ?? '',
              p.dirname(exe),
              '/opt/homebrew/bin',
              '/usr/local/bin',
            ].join(':'),
        },
      );
    } on ProcessException catch (e) {
      throw UserError(tr('No se pudo lanzar Claude Code: {0}', [e.message]));
    }
    _proc = proc;
    final err = StringBuffer();
    final errDone = proc.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(err.write)
        .asFuture<void>();
    // Sin entrada: se cierra para que no espere nada por ella.
    unawaited(proc.stdin.close());
    var gotResult = false;
    await for (final line
        in proc.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())) {
      final Map<String, Object?> e;
      try {
        final j = jsonDecode(line);
        if (j is! Map) continue;
        e = j.cast<String, Object?>();
      } on FormatException {
        continue;
      }
      final id = e['session_id'];
      if (id is String && id.isNotEmpty) sessionId = id;
      switch (e['type']) {
        case 'assistant':
          final content = ((e['message'] as Map?)?['content'] as List?) ?? [];
          for (final b in content.whereType<Map>()) {
            if (b['type'] == 'text') {
              final t = '${b['text'] ?? ''}'.trim();
              if (t.isNotEmpty) add(ClaudeCodeStep('text', t));
            } else if (b['type'] == 'tool_use') {
              final name = '${b['name']}';
              final input = (b['input'] as Map?) ?? const {};
              final file = p.basename(
                '${input['file_path'] ?? input['path'] ?? input['pattern'] ?? ''}',
              );
              if (const {'Edit', 'Write', 'MultiEdit'}.contains(name)) {
                edited = true;
              }
              add(
                ClaudeCodeStep('tool', switch (name) {
                  'Read' => tr('Leyendo {0}', [file]),
                  'Edit' || 'MultiEdit' => tr('Editando {0}', [file]),
                  'Write' => tr('Escribiendo {0}', [file]),
                  'Glob' || 'Grep' => tr('Buscando {0}', [file]),
                  _ => name,
                }),
              );
            }
          }
        case 'result':
          gotResult = true;
          final cost = e['total_cost_usd'];
          final usage = (e['usage'] as Map?) ?? const {};
          final models = (e['modelUsage'] as Map?)?.keys.toList() ?? [];
          int n(String k) => (usage[k] as num?)?.toInt() ?? 0;
          await AiUsage.record(
            project: dir,
            tool: 'claude_code',
            model: models.isEmpty ? 'claude-code' : models.join(', '),
            input: n('input_tokens'),
            output: n('output_tokens'),
            cacheRead: n('cache_read_input_tokens'),
            cacheWrite: n('cache_creation_input_tokens'),
            cost: cost is num ? cost.toDouble() : null,
          );
          if (e['is_error'] == true) {
            add(
              ClaudeCodeStep(
                'error',
                '${e['result'] ?? e['subtype'] ?? tr('Claude Code terminó con un error.')}',
              ),
            );
          } else {
            add(
              ClaudeCodeStep(
                'done',
                cost is num && cost > 0
                    ? tr('Listo · {0} US\$', [cost.toStringAsFixed(4)])
                    : tr('Listo'),
              ),
            );
          }
      }
    }
    final code = await proc.exitCode;
    await errDone.timeout(const Duration(seconds: 2), onTimeout: () {});
    _proc = null;
    if (!gotResult) {
      final msg = err.toString().trim();
      add(
        ClaudeCodeStep(
          'error',
          msg.isNotEmpty
              ? msg
              : tr('Claude Code terminó con el código {0}.', [code]),
        ),
      );
    }
    return edited;
  }

  void stop() => _proc?.kill();

  /// Conversación nueva.
  void reset() {
    stop();
    sessionId = null;
    steps.clear();
  }
}
