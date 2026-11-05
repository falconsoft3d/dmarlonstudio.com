import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_run_types.dart';

/// Lanza las ventanas de Python como procesos aparte, con el usuario del
/// sistema que abrió el estudio. Una ventana de Tk no se puede incrustar en
/// la de Flutter: cada una vive en su propia ventana del sistema.
class TkRunner {
  TkRunner._();

  /// Solo en escritorio.
  static bool get supported =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static TkPython? _python;

  /// Fija lo que encontraría [detect] (las pruebas de pantallas no lanzan
  /// procesos).
  static set python(TkPython? p) => _python = p;
  static final _runs = <String, TkRun>{};
  static final _starting = <String>{};

  /// Ventana lanzada del proyecto [appId] (su carpeta). Sigue aquí al
  /// terminar, con su salida, hasta el siguiente lanzamiento.
  static TkRun? runOf(String appId) => _runs[p.normalize(appId)];

  /// Ventanas en marcha, para detenerlas al cerrar el estudio.
  static Iterable<TkRun> get running => _runs.values.where((r) => r.running);

  /// Detiene todas las ventanas en marcha.
  static void stopAll() {
    for (final r in running.toList()) {
      r.stop();
    }
  }

  /// Qué instalar para tener tkinter en este sistema.
  static String get _help {
    if (Platform.isMacOS) {
      return tr(
        'Instale Python con tkinter: «brew install python-tk» con Homebrew, o el instalador de python.org, que ya lo trae.',
      );
    }
    if (Platform.isWindows) {
      return tr(
        'Instale Python desde python.org con la opción «tcl/tk and IDLE» marcada.',
      );
    }
    return tr(
      'Instale tkinter: «sudo apt install python3-tk» en Debian y Ubuntu, o «sudo dnf install python3-tkinter» en Fedora.',
    );
  }

  /// ¿Existe lo que se va a lanzar? En macOS, lanzar una ruta que no existe
  /// mata la aplicación entera sin excepción ni informe de fallo: nada se
  /// lanza sin pasar por aquí. Una orden sin ruta se busca en el PATH.
  static bool launchable(String command) {
    if (Platform.isWindows) return true;
    if (command.contains('/')) return File(command).existsSync();
    return (Platform.environment['PATH'] ?? '')
        .split(':')
        .any((dir) => File(p.join(dir, command)).existsSync());
  }

  /// Intérpretes posibles. Una aplicación abierta desde el Finder no recibe
  /// el PATH de la terminal: por eso se pregunta también al intérprete de
  /// órdenes y se miran las carpetas habituales.
  static Future<List<(String, List<String>)>> _candidates() async {
    if (Platform.isWindows) {
      return const [
        ('py', ['-3']),
        ('python', []),
        ('python3', []),
      ];
    }
    final paths = <String>['python3'];
    var shellFound = false;
    final shell = Platform.environment['SHELL'] ?? '/bin/sh';
    try {
      if (launchable(shell)) {
        final r = await Process.run(shell, [
          '-lc',
          'which -a python3',
        ], stdoutEncoding: utf8).timeout(const Duration(seconds: 8));
        final found = const LineSplitter()
            .convert('${r.stdout}')
            .map((l) => l.trim())
            .where((l) => l.startsWith('/'));
        shellFound = found.isNotEmpty;
        paths.addAll(found);
      }
    } on Object {
      // Sin intérprete de órdenes quedan las carpetas habituales.
    }
    paths.addAll(const [
      '/opt/homebrew/bin/python3',
      '/usr/local/bin/python3',
      '/Library/Frameworks/Python.framework/Versions/Current/bin/python3',
    ]);
    // Homebrew deja cada versión con su número, y tkinter puede estar solo en
    // una de ellas: python3 sin tkinter y python3.9 con él.
    for (final dir in const ['/opt/homebrew/bin', '/usr/local/bin']) {
      try {
        paths.addAll(
          Directory(dir)
              .listSync()
              .map((e) => e.path)
              .where((x) => RegExp(r'/python3\.\d+$').hasMatch(x)),
        );
      } on FileSystemException {
        // Sin Homebrew no existe la carpeta.
      }
    }
    // El de Apple es un señuelo que abre un instalador si faltan las
    // herramientas de línea de órdenes.
    var system = true;
    if (Platform.isMacOS) {
      try {
        system =
            launchable('/usr/bin/xcode-select') &&
            (await Process.run('/usr/bin/xcode-select', ['-p'])).exitCode == 0;
      } on ProcessException {
        system = false;
      }
    }
    if (system) {
      paths.add('/usr/bin/python3');
    } else {
      paths.removeWhere((x) => x == 'python3' || x == '/usr/bin/python3');
    }
    // Lanzar una ruta que no existe cierra la aplicación de escritorio en
    // macOS, sin llegar a dar error: solo se prueba lo que está en el disco.
    return [
      for (final x in paths.toSet())
        if (x.contains('/') ? File(x).existsSync() : shellFound)
          (x, const <String>[]),
    ];
  }

  /// Intérpretes que se probarían, para las pruebas.
  static Future<List<(String, List<String>)>> candidates() => _candidates();

  static Future<(String, String?)?> _probe(
    String cmd,
    List<String> args,
  ) async {
    if (!launchable(cmd)) return null;
    try {
      final r = await Process.run(cmd, [
        ...args,
        '-c',
        'import sys\n'
            'print(sys.version.split()[0])\n'
            'import tkinter\n'
            'print(tkinter.Tcl().eval("info patchlevel"))\n',
      ], stdoutEncoding: utf8).timeout(const Duration(seconds: 15));
      final out = const LineSplitter().convert('${r.stdout}');
      if (out.isEmpty || !out.first.startsWith('3.')) return null;
      return (out.first, r.exitCode == 0 && out.length > 1 ? out[1] : null);
    } on Object {
      return null;
    }
  }

  /// Número de versión para comparar («8.6.13» → 80613).
  static int _rank(String? v) {
    final n = (v ?? '').split('.').map((x) => int.tryParse(x) ?? 0).toList();
    return [
      for (var i = 0; i < 3; i++) i < n.length ? n[i] : 0,
    ].fold(0, (a, x) => a * 100 + x);
  }

  /// Busca Python con tkinter y se queda con el de Tk más reciente: en macOS
  /// el del sistema trae un Tk 8.5 obsoleto y el de Homebrew puede no traer
  /// ninguno.
  static Future<TkPython> detect({bool refresh = false}) async {
    if (_python != null && !refresh) return _python!;
    if (!supported) {
      return TkPython(
        help: tr(
          'Las ventanas de Python solo se abren en macOS, Windows o Linux.',
        ),
      );
    }
    TkPython? best;
    String? without;
    (String, List<String>)? plain;
    for (final (cmd, args) in await _candidates()) {
      final r = await _probe(cmd, args);
      if (r == null) continue;
      final (version, tk) = r;
      if (tk == null) {
        without ??= '$cmd ($version)';
        plain ??= (cmd, args);
        continue;
      }
      final tkRank = _rank(tk), bestTk = _rank(best?.tk);
      if (best == null ||
          tkRank > bestTk ||
          (tkRank == bestTk && _rank(version) > _rank(best.version))) {
        best = TkPython(
          command: cmd,
          args: args,
          version: version,
          tk: tk,
          help: _help,
        );
      }
    }
    return _python =
        best ??
        TkPython(
          withoutTk: without,
          serverCommand: plain?.$1,
          serverArgs: plain?.$2 ?? const [],
          help: _help,
        );
  }

  static Future<void> forgetPython() async => _python = null;

  /// Comprobación de módulos de Python (solo en las pruebas).
  static Future<bool> Function(String module)? moduleOverride;

  static Future<bool> _hasModule(TkPython py, String module) async {
    final o = moduleOverride;
    if (o != null) return o(module);
    if (!launchable(py.command!)) return false;
    try {
      final r = await Process.run(py.command!, [
        ...py.args,
        '-c',
        'import $module',
      ]).timeout(const Duration(seconds: 20));
      return r.exitCode == 0;
    } on Object {
      return false;
    }
  }

  /// Orden exacta para instalar el controlador de [kind] (null: no hace
  /// falta o ya está).
  static Future<String?> missingDriver(String kind, TkPython py) async {
    final modules = switch (kind) {
      'postgres' => const ['psycopg', 'psycopg2'],
      'mysql' => const ['pymysql'],
      _ => const <String>[],
    };
    if (modules.isEmpty) return null;
    for (final m in modules) {
      if (await _hasModule(py, m)) return null;
    }
    // Sin «rsa», pymysql no entra en un MySQL 8 con su autenticación de serie.
    final package = kind == 'postgres' ? '"psycopg[binary]"' : '"pymysql[rsa]"';
    return '"${py.command}"${py.args.map((a) => ' $a').join()} '
        '-m pip install $package';
  }

  /// Orden exacta para instalar Flask (null: ya está).
  static Future<String?> missingFlask(TkPython py) async {
    if (await _hasModule(py, 'flask')) return null;
    return '"${py.command}"${py.args.map((a) => ' $a').join()} '
        '-m pip install flask';
  }

  /// Lanza la ventana [prepared]: el archivo generado en `build/` del
  /// proyecto, con su carpeta como carpeta de trabajo.
  static Future<TkRun> start(TkPrepared prepared) async {
    final key = p.normalize(prepared.id);
    if ((_runs[key]?.running ?? false) || !_starting.add(key)) {
      throw UserError(tr('«{0}» ya está abierta.', [prepared.name]));
    }
    try {
      return await _launch(prepared, key);
    } finally {
      _starting.remove(key);
    }
  }

  /// Variables de entorno de la ventana: lo único por donde le llegan las
  /// contraseñas de sus conexiones. Nunca al archivo generado ni al diseño.
  static Map<String, String> environment(TkPrepared p) => {
    for (final l in p.links)
      ...() {
        final prefix = 'DMSTUDIO_DB_${l.component.toUpperCase()}_';
        String s(String k) => '${l.config[k] ?? ''}';
        return {
          '${prefix}KIND': l.kind,
          if (l.kind == 'sqlite')
            '${prefix}PATH': s('path').trim()
          else ...{
            '${prefix}HOST': s('host').trim(),
            '${prefix}PORT': s('port').trim(),
            '${prefix}DATABASE': s('database').trim(),
            '${prefix}USER': s('user').trim(),
            '${prefix}PASSWORD': s('password'),
            '${prefix}SSL': l.config['ssl'] == true ? '1' : '0',
          },
        };
      }(),
  };

  /// Línea con la que la aplicación web dice que ya escucha, y en qué puerto.
  static const readyMark = 'DMSTUDIO_WEB_READY ';

  /// Lo que tarda como mucho en escuchar una aplicación web.
  static const readyTimeout = Duration(seconds: 30);

  static String _secret() {
    final r = Random.secure();
    return List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static Future<TkRun> _launch(TkPrepared prepared, String key) async {
    final found = await detect();
    final web = prepared.web;
    final py = web ? found.web : found;
    if (!py.ok) throw UserError(py.help);
    if (!launchable(py.command!)) {
      await forgetPython();
      throw UserError(tr('No se encontró Python en {0}.', [py.command]));
    }
    if (web) {
      final install = await missingFlask(py);
      if (install != null) {
        throw UserError(tr('Falta Flask. Instálelo con:\n{0}', [install]));
      }
    }
    for (final l in prepared.links) {
      final install = await missingDriver(l.kind, py);
      if (install != null) {
        throw UserError(
          tr('«{0}» necesita un controlador de Python. Instálelo con:\n{1}', [
            l.name,
            install,
          ]),
        );
      }
    }
    // Vale para esta ejecución y solo llega al proceso, por el entorno.
    final secret = web ? _secret() : null;
    final file = File(prepared.file);
    if (!file.existsSync()) {
      await file.parent.create(recursive: true);
      await file.writeAsString(prepared.source, flush: true);
    }
    final Process proc;
    try {
      proc = await Process.start(
        py.command!,
        [...py.args, '-u', file.path],
        // La carpeta del proyecto: sus archivos se abren por su nombre.
        workingDirectory: p.dirname(p.dirname(file.path)),
        environment: {
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
          'PYTHONDONTWRITEBYTECODE': '1',
          // El aviso del Tk de Apple no le dice nada al usuario.
          'TK_SILENCE_DEPRECATION': '1',
          'DMSTUDIO_WEB_SECRET': ?secret,
          ...environment(prepared),
        },
      );
    } on ProcessException catch (e) {
      throw UserError(tr('No se pudo lanzar Python: {0}', [e.message]));
    }
    final run = TkRun(prepared.id, prepared.name, proc.kill);
    _runs[key] = run;
    final ready = Completer<int?>();
    void line(String l) {
      if (!web || !l.startsWith(readyMark)) return run.add(l);
      if (!ready.isCompleted) {
        ready.complete(int.tryParse(l.substring(readyMark.length)));
      }
    }

    final done = <Future<void>>[
      for (final s in [proc.stdout, proc.stderr])
        s
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(line)
            .asFuture<void>(),
    ];
    unawaited(() async {
      final code = await proc.exitCode;
      await Future.wait(
        done,
      ).timeout(const Duration(seconds: 2), onTimeout: () => const []);
      if (!ready.isCompleted) ready.complete(null);
      run.finish(code);
    }());
    if (web) {
      final port = await ready.future.timeout(
        readyTimeout,
        onTimeout: () => null,
      );
      if (port == null) {
        proc.kill();
        throw UserError(
          tr('La aplicación web no arrancó: {0}', [
            run.lines.lastOrNull ?? run.exitCode ?? '',
          ]),
        );
      }
      run
        ..address = 'http://127.0.0.1:$port/'
        ..url = 'http://127.0.0.1:$port/?key=$secret';
    }
    return run;
  }
}
