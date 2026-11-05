import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../core/ai_usage.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';
import 'assistant.dart';
import 'attachments.dart';

/// Cambio propuesto por Claude a un archivo de la carpeta abierta.
class ClaudeChange {
  ClaudeChange(this.path, this.before, this.after);

  /// Ruta relativa a la carpeta abierta.
  final String path;

  /// Contenido en el disco antes del cambio (null = el archivo no existía).
  final String? before;

  /// Contenido nuevo (null = se borra).
  String? after;

  bool get created => before == null && after != null;
  bool get deleted => after == null;
}

/// Paso visible del agente: lo que hizo o lo que pensó.
class ClaudeStep {
  const ClaudeStep(this.kind, this.text);

  /// `thinking`, `tool`, `text` o `error`.
  final String kind;
  final String text;
}

/// Claude implementa cambios en la carpeta abierta del Editor.
///
/// Bucle de herramientas propio sobre la API de mensajes de Anthropic
/// (`POST /v1/messages`, por HTTP: Dart no tiene SDK oficial). Claude
/// explora con `list_files`, `read_file` y `search`, y propone cambios con
/// `write_file`, `edit_file` y `delete_file`. Nada se escribe en el disco
/// aquí: los cambios quedan en [changes] para que el usuario los revise y los
/// aplique con [apply].
class ClaudeAgent {
  ClaudeAgent({
    required this.apiKey,
    required this.root,
    this.model = defaultModel,
    this.onStep,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const defaultModel = 'claude-opus-5-5';
  static const _url = 'https://api.anthropic.com/v1/messages';
  static const _fallbackBeta = 'server-side-fallback-2026-07-01';

  /// Máximo de vueltas del bucle por petición.
  static const maxSteps = 60;

  final String apiKey;
  final String root;
  final String model;
  final void Function(ClaudeStep step)? onStep;
  final http.Client _client;

  /// Conversación en el formato de la API (las respuestas, tal cual).
  final _messages = <Map<String, Object?>>[];

  /// Cambios propuestos, por ruta relativa.
  final changes = <String, ClaudeChange>{};

  /// Con fallbacks del servidor (se apagan si la cuenta no los admite).
  bool _fallbacks = true;

  bool _cancelled = false;
  void cancel() => _cancelled = true;

  /// Cambios que el usuario descartó: Claude lo sabrá en el próximo mensaje.
  final _discarded = <String>{};

  /// Configuración de Ajustes: la clave y el modelo de Anthropic.
  static Future<ClaudeAgent> fromSettings({
    required String root,
    void Function(ClaudeStep step)? onStep,
  }) async {
    final c = await AiConfig.load();
    final key = c.keyOf(AiProvider.anthropic);
    if (key.isEmpty) {
      throw UserError(
        tr(
          'Falta la clave de Anthropic. Escríbala en Ajustes → Inteligencia artificial (proveedor «Anthropic (Claude)»).',
        ),
      );
    }
    final chosen = identical(c.provider, AiProvider.anthropic)
        ? c.model
        : c.models[AiProvider.anthropic.id];
    return ClaudeAgent(
      apiKey: key,
      root: root,
      model: (chosen ?? '').trim().isEmpty ? defaultModel : chosen!.trim(),
      onStep: onStep,
    );
  }

  // ------------------------------------------------------------- petición
  String get _system =>
      '''You are Claude, working inside DMarlon Studio, a desktop IDE. You implement the change the user asks for in the folder they have open: $root

Work like a careful senior engineer:
- Explore before editing: list_files, search and read_file the code you will touch and the code that uses it. Never edit a file you have not read in this conversation.
- Make the smallest complete change that does what was asked, in the style of the surrounding code. Do not reformat or rewrite unrelated code.
- Prefer edit_file for changes to existing files; use write_file for new files or when most of a file changes.
- Your edits are proposals: the user reviews them before anything is written to disk, so do not ask for confirmation, just make them.
- You cannot run commands. If something should be run or tested, say so at the end.
- When you are done, reply with a short summary of what you changed and why, in the language the user wrote in.''';

  static const _tools = <Map<String, Object?>>[
    {
      'name': 'list_files',
      'description':
          'Lists files and folders under a folder of the project (relative path, "" for the root), up to the given depth. Skips .git, build outputs and dependency folders.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Relative folder path.'},
          'depth': {
            'type': 'integer',
            'description': 'How many levels to descend (1-6, default 2).',
          },
        },
        'required': ['path'],
      },
    },
    {
      'name': 'read_file',
      'description':
          'Reads a text file. Each line is prefixed with its number and a tab; that prefix is NOT part of the file. Use offset/limit for long files.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Relative file path.'},
          'offset': {
            'type': 'integer',
            'description': 'First line to read (1-based, default 1).',
          },
          'limit': {
            'type': 'integer',
            'description': 'Number of lines (default 2000).',
          },
        },
        'required': ['path'],
      },
    },
    {
      'name': 'search',
      'description':
          'Searches the project for a regular expression (case-insensitive) and returns matching lines as path:line: text.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'pattern': {'type': 'string', 'description': 'Regular expression.'},
          'path': {
            'type': 'string',
            'description':
                'Relative folder or file to search in (default the root).',
          },
        },
        'required': ['pattern'],
      },
    },
    {
      'name': 'write_file',
      'description':
          'Creates a file or replaces its whole content. The change is proposed to the user, not written yet.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Relative file path.'},
          'content': {'type': 'string', 'description': 'Full new content.'},
        },
        'required': ['path', 'content'],
      },
    },
    {
      'name': 'edit_file',
      'description':
          'Replaces old_string with new_string in a file. old_string must match the file exactly (without the line-number prefix of read_file) and be unique unless replace_all is true.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Relative file path.'},
          'old_string': {'type': 'string'},
          'new_string': {'type': 'string'},
          'replace_all': {'type': 'boolean'},
        },
        'required': ['path', 'old_string', 'new_string'],
      },
    },
    {
      'name': 'delete_file',
      'description': 'Deletes a file (proposed to the user, not done yet).',
      'input_schema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Relative file path.'},
        },
        'required': ['path'],
      },
    },
  ];

  Map<String, Object?> _body() => {
    'model': model,
    'max_tokens': 16000,
    'system': _system,
    'tools': _tools,
    'messages': _messages,
    // Pensamiento adaptativo con resumen visible: se enseña como progreso.
    'thinking': {'type': 'adaptive', 'display': 'summarized'},
    'output_config': {'effort': 'high'},
    // La conversación crece en cada vuelta: se reutiliza lo ya enviado.
    'cache_control': {'type': 'ephemeral'},
    if (_fallbacks) 'fallbacks': 'default',
  };

  Future<Map<String, Object?>> _send() async {
    for (;;) {
      final http.Response res;
      try {
        res = await _client.post(
          Uri.parse(_url),
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': AiProvider.anthropicVersion,
            if (_fallbacks) 'anthropic-beta': _fallbackBeta,
          },
          body: jsonEncode(_body()),
        );
      } on Object catch (e) {
        throw UserError(tr('No se pudo conectar con Anthropic: {0}', [e]));
      }
      final text = utf8.decode(res.bodyBytes);
      if (res.statusCode == 200) {
        final body = (jsonDecode(text) as Map).cast<String, Object?>();
        await AiUsage.recordAnthropic(
          body,
          fallbackModel: model,
          project: root,
          tool: 'claude_agent',
        );
        return body;
      }
      final msg = aiErrorOf(text);
      // Una cuenta o un modelo sin fallbacks del servidor: sin ellos.
      if (res.statusCode == 400 && _fallbacks && msg.contains('fallback')) {
        _fallbacks = false;
        continue;
      }
      throw UserError(tr('Error de Claude ({0}): {1}', [res.statusCode, msg]));
    }
  }

  // --------------------------------------------------------------- bucle
  /// Pide a Claude [task] y lo deja trabajar hasta que termina. Devuelve su
  /// resumen final. Se puede llamar otra vez para seguir la conversación.
  Future<String> run(
    String task, {
    List<ChatAttachment> attachments = const [],
  }) async {
    _cancelled = false;
    final note = _discarded.isEmpty
        ? ''
        : '(The user discarded your proposed changes to: ${_discarded.join(', ')}. Those files are as on disk.)\n\n';
    _discarded.clear();
    _messages.add({
      'role': 'user',
      'content': ChatAttachment.anthropicBlocks('$note$task', attachments),
    });
    for (var step = 0; step < maxSteps; step++) {
      if (_cancelled) return tr('Detenido.');
      await AiUsage.check(project: root);
      final r = await _send();
      final content = ((r['content'] as List?) ?? const []).cast<Map>();
      final stop = r['stop_reason'];
      if (stop == 'refusal') {
        // La respuesta rechazada no se guarda: la conversación sigue limpia.
        throw UserError(
          tr(
            'Claude ha rechazado esta petición por sus filtros de seguridad. Reformúlela.',
          ),
        );
      }
      // Los bloques vuelven tal cual (también los de pensamiento).
      _messages.add({'role': 'assistant', 'content': content});
      final text = StringBuffer();
      final uses = <Map>[];
      for (final b in content) {
        switch (b['type']) {
          case 'thinking':
            final t = '${b['thinking'] ?? ''}'.trim();
            if (t.isNotEmpty) onStep?.call(ClaudeStep('thinking', t));
          case 'text':
            text.write(b['text'] ?? '');
          case 'tool_use':
            uses.add(b);
        }
      }
      if (uses.isEmpty) {
        if (stop == 'max_tokens') {
          text.write(
            '\n\n${tr('(La respuesta se cortó por su longitud: pida que continúe.)')}',
          );
        }
        final out = text.toString().trim();
        onStep?.call(ClaudeStep('text', out));
        return out;
      }
      if (text.toString().trim().isNotEmpty) {
        onStep?.call(ClaudeStep('text', text.toString().trim()));
      }
      // Todos los resultados en un solo mensaje.
      final results = <Map<String, Object?>>[];
      for (final u in uses) {
        final input = u['input'] is Map
            ? (u['input'] as Map).cast<String, Object?>()
            : <String, Object?>{};
        String out;
        var error = false;
        if (stop == 'max_tokens') {
          // Una llamada cortada puede traer datos a medias: no se ejecuta.
          out =
              'The response was cut off by max_tokens before this call was complete. Retry it, splitting large writes into smaller edit_file calls.';
          error = true;
        } else {
          try {
            out = await _runTool('${u['name']}', input);
          } on _ToolError catch (e) {
            out = e.message;
            error = true;
            onStep?.call(ClaudeStep('error', e.message));
          }
        }
        results.add({
          'type': 'tool_result',
          'tool_use_id': u['id'],
          'content': out,
          if (error) 'is_error': true,
        });
      }
      _messages.add({'role': 'user', 'content': results});
    }
    return tr(
      'Claude se ha detenido tras demasiados pasos. Los cambios propuestos hasta ahora se pueden revisar.',
    );
  }

  // ---------------------------------------------------------- herramientas
  static const _skip = {
    '.git',
    'node_modules',
    'build',
    '.dart_tool',
    '__pycache__',
    '.venv',
    'venv',
    '.next',
    '.idea',
    'Pods',
    '.gradle',
    'dist',
    '.papelera',
  };

  /// Ruta absoluta de [rel], sin salir de la carpeta abierta.
  String _abs(Object? rel) {
    final r = '${rel ?? ''}'.trim().replaceAll('\\', '/');
    final abs = p.normalize(p.join(root, r));
    if (abs != p.normalize(root) && !p.isWithin(root, abs)) {
      throw _ToolError('Path outside the project: $r');
    }
    return abs;
  }

  String _rel(String abs) => p.relative(abs, from: root).replaceAll('\\', '/');

  /// Contenido actual: el propuesto, o el del disco.
  Future<String?> _read(String abs) async {
    final c = changes[_rel(abs)];
    if (c != null) return c.after;
    final f = File(abs);
    if (!await f.exists()) return null;
    try {
      return await f.readAsString();
    } on FileSystemException {
      throw _ToolError('Not a text file (or not UTF-8): ${_rel(abs)}');
    }
  }

  Future<String?> _disk(String abs) async {
    final f = File(abs);
    if (!await f.exists()) return null;
    try {
      return await f.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _propose(String abs, String? after) async {
    final rel = _rel(abs);
    final c = changes[rel];
    if (c != null) {
      c.after = after;
      // Volvió a quedar como estaba: ya no es un cambio.
      if (c.after == c.before) changes.remove(rel);
      return;
    }
    final before = await _disk(abs);
    if (before == after) return;
    changes[rel] = ClaudeChange(rel, before, after);
  }

  Future<String> _runTool(String name, Map<String, Object?> a) async {
    int? intOf(Object? v) => v is int ? v : int.tryParse('${v ?? ''}');
    String need(String k) {
      final v = a[k];
      if (v is! String) throw _ToolError('Missing string parameter "$k".');
      return v;
    }

    switch (name) {
      case 'list_files':
        final dir = _abs(a['path']);
        final depth = (intOf(a['depth']) ?? 2).clamp(1, 6);
        onStep?.call(
          ClaudeStep('tool', tr('Explorando {0}', [_label(_rel(dir))])),
        );
        if (!await Directory(dir).exists()) {
          throw _ToolError('Folder not found: ${_rel(dir)}');
        }
        final out = <String>[];
        Future<void> walk(String d, int level) async {
          final items = await Directory(d).list(followLinks: false).toList()
            ..sort((x, y) => x.path.compareTo(y.path));
          for (final e in items) {
            if (out.length >= 800) return;
            final base = p.basename(e.path);
            if (_skip.contains(base) || base == '.DS_Store') continue;
            final isDir = e is Directory;
            out.add('${_rel(e.path)}${isDir ? '/' : ''}');
            if (isDir && level < depth) await walk(e.path, level + 1);
          }
        }

        await walk(dir, 1);
        // Los archivos nuevos propuestos también existen.
        for (final c in changes.values) {
          if (c.created && !out.contains(c.path)) out.add('${c.path} (new)');
        }
        if (out.length >= 800) out.add('… (truncated)');
        return out.isEmpty ? '(empty)' : out.join('\n');

      case 'read_file':
        final abs = _abs(need('path'));
        onStep?.call(ClaudeStep('tool', tr('Leyendo {0}', [_rel(abs)])));
        final text = await _read(abs);
        if (text == null) throw _ToolError('File not found: ${_rel(abs)}');
        final lines = const LineSplitter().convert(text);
        final from = (intOf(a['offset']) ?? 1).clamp(1, lines.length + 1);
        final count = (intOf(a['limit']) ?? 2000).clamp(1, 5000);
        final end = (from - 1 + count).clamp(0, lines.length);
        final b = StringBuffer();
        for (var i = from - 1; i < end; i++) {
          b.writeln('${i + 1}\t${lines[i]}');
        }
        if (end < lines.length) {
          b.writeln('… (${lines.length - end} more lines; use offset)');
        }
        return b.isEmpty ? '(empty file)' : b.toString();

      case 'search':
        final pattern = need('pattern');
        final RegExp re;
        try {
          re = RegExp(pattern, caseSensitive: false);
        } on FormatException catch (e) {
          throw _ToolError('Invalid regular expression: ${e.message}');
        }
        final start = _abs(a['path']);
        onStep?.call(ClaudeStep('tool', tr('Buscando «{0}»', [pattern])));
        final hits = <String>[];
        Future<void> scan(String abs) async {
          if (hits.length >= 200) return;
          final text = await _read(abs).catchError((_) => null);
          if (text == null || text.length > 2000000) return;
          final lines = const LineSplitter().convert(text);
          for (var i = 0; i < lines.length && hits.length < 200; i++) {
            if (re.hasMatch(lines[i])) {
              final l = lines[i].length > 240
                  ? '${lines[i].substring(0, 240)}…'
                  : lines[i];
              hits.add('${_rel(abs)}:${i + 1}: $l');
            }
          }
        }

        if (await File(start).exists()) {
          await scan(start);
        } else {
          Future<void> walk(String d) async {
            if (!await Directory(d).exists()) return;
            await for (final e in Directory(d).list(followLinks: false)) {
              if (hits.length >= 200) return;
              final base = p.basename(e.path);
              if (_skip.contains(base)) continue;
              if (e is Directory) {
                await walk(e.path);
              } else if (e is File && !_binary(base)) {
                await scan(e.path);
              }
            }
          }

          await walk(start);
        }
        return hits.isEmpty ? 'No matches.' : hits.join('\n');

      case 'write_file':
        final abs = _abs(need('path'));
        if (await Directory(abs).exists()) {
          throw _ToolError('That path is a folder: ${_rel(abs)}');
        }
        final existed = await _read(abs) != null;
        onStep?.call(
          ClaudeStep(
            'tool',
            existed
                ? tr('Reescribiendo {0}', [_rel(abs)])
                : tr('Creando {0}', [_rel(abs)]),
          ),
        );
        await _propose(abs, need('content'));
        return 'OK: ${existed ? 'replaced' : 'created'} ${_rel(abs)} (proposed).';

      case 'edit_file':
        final abs = _abs(need('path'));
        final old = need('old_string'), neu = need('new_string');
        final text = await _read(abs);
        if (text == null) throw _ToolError('File not found: ${_rel(abs)}');
        if (old.isEmpty) throw _ToolError('old_string is empty.');
        final n = old.allMatches(text).length;
        if (n == 0) {
          throw _ToolError(
            'old_string was not found in ${_rel(abs)}. Read the file again and copy the text exactly.',
          );
        }
        final all = a['replace_all'] == true;
        if (n > 1 && !all) {
          throw _ToolError(
            'old_string appears $n times in ${_rel(abs)}. Add surrounding lines to make it unique, or set replace_all.',
          );
        }
        onStep?.call(ClaudeStep('tool', tr('Editando {0}', [_rel(abs)])));
        await _propose(
          abs,
          all ? text.replaceAll(old, neu) : text.replaceFirst(old, neu),
        );
        return 'OK: edited ${_rel(abs)} (proposed).';

      case 'delete_file':
        final abs = _abs(need('path'));
        if (await _read(abs) == null) {
          throw _ToolError('File not found: ${_rel(abs)}');
        }
        onStep?.call(ClaudeStep('tool', tr('Borrando {0}', [_rel(abs)])));
        await _propose(abs, null);
        return 'OK: deleted ${_rel(abs)} (proposed).';
    }
    throw _ToolError('Unknown tool: $name');
  }

  String _label(String rel) => rel.isEmpty || rel == '.' ? '/' : rel;

  static bool _binary(String name) => RegExp(
    r'\.(png|jpe?g|gif|webp|ico|icns|pdf|zip|gz|tar|7z|jar|class|so|dylib|dll|exe|bin|ttf|otf|woff2?|mp[34]|mov|wav|sqlite|db|lock)$',
    caseSensitive: false,
  ).hasMatch(name);

  // ------------------------------------------------------------- aplicar
  /// Escribe en el disco los cambios de [paths] (todos, sin ellos). Antes
  /// comprueba que nadie haya tocado esos archivos mientras Claude
  /// trabajaba. Devuelve las rutas escritas.
  Future<List<String>> apply([Iterable<String>? paths]) async {
    final chosen = [
      for (final c in changes.values)
        if (paths == null || paths.contains(c.path)) c,
    ];
    for (final c in chosen) {
      if (await _disk(_abs(c.path)) != c.before) {
        throw UserError(
          tr(
            '«{0}» cambió en el disco mientras Claude trabajaba. Descarte ese cambio o pídalo de nuevo.',
            [c.path],
          ),
        );
      }
    }
    final done = <String>[];
    for (final c in chosen) {
      final f = File(_abs(c.path));
      if (c.after == null) {
        if (await f.exists()) await f.delete();
      } else {
        await f.parent.create(recursive: true);
        await f.writeAsString(c.after!, flush: true);
      }
      changes.remove(c.path);
      done.add(c.path);
    }
    return done;
  }

  void discard([Iterable<String>? paths]) {
    for (final x in (paths ?? changes.keys).toList()) {
      if (changes.remove(x) != null) _discarded.add(x);
    }
  }
}

class _ToolError implements Exception {
  _ToolError(this.message);
  final String message;
}
