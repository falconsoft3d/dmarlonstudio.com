import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_debug.dart';
import 'tk_debug_agent.dart';
import 'tk_electron.dart';
import 'tk_electron_run.dart';
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
  /// Orden exacta para instalar lo que necesita el icono de bandeja (null:
  /// ya está).
  static Future<String?> missingTray(TkPython py) async {
    if (await _hasModule(py, 'pystray') && await _hasModule(py, 'PIL')) {
      return null;
    }
    return '"${py.command}"${py.args.map((a) => ' $a').join()} '
        '-m pip install pystray pillow';
  }

  /// Orden exacta para instalar el SDK de Anthropic (null: ya está).
  static Future<String?> missingAnthropic(TkPython py) async {
    if (await _hasModule(py, 'anthropic')) return null;
    return '"${py.command}"${py.args.map((a) => ' $a').join()} '
        '-m pip install anthropic';
  }

  static Future<String?> missingFlask(TkPython py) async {
    if (await _hasModule(py, 'flask')) return null;
    return '"${py.command}"${py.args.map((a) => ' $a').join()} '
        '-m pip install flask';
  }

  /// Orden de pip que instala [packages] en [py].
  static String pipCommand(TkPython py, List<String> packages) =>
      '"${py.command}"${py.args.map((a) => ' $a').join()} -m pip install '
      '${packages.map((x) => x.contains('[') ? '"$x"' : x).join(' ')}';

  /// Lo que le falta a [py] para lanzar [prepared], en el orden en que se
  /// comprueba al lanzarlo.
  static Future<List<TkNeed>> needs(TkPrepared prepared, TkPython py) async {
    final out = <TkNeed>[];
    TkNeed need(
      String title,
      String why,
      List<String> packages, {
      bool optional = false,
    }) => TkNeed(
      title: title,
      why: why,
      packages: packages,
      command: pipCommand(py, packages),
      optional: optional,
    );
    if (prepared.web && await missingFlask(py) != null) {
      out.add(
        need(
          tr('Falta Flask'),
          tr(
            'Las aplicaciones web necesitan Flask en el Python de este equipo.',
          ),
          const ['flask'],
        ),
      );
    }
    if (prepared.ai && await missingAnthropic(py) != null) {
      out.add(
        need(
          tr('Falta el SDK de Anthropic'),
          tr(
            'El Asistente IA necesita el SDK de Anthropic en el Python de este equipo.',
          ),
          const ['anthropic'],
        ),
      );
    }
    final drivers = <String>{};
    for (final l in prepared.links) {
      if (!drivers.add(l.kind) || await missingDriver(l.kind, py) == null) {
        continue;
      }
      out.add(
        need(
          tr('Falta un controlador de base de datos'),
          tr('«{0}» necesita un controlador de Python.', [l.name]),
          [l.kind == 'postgres' ? 'psycopg[binary]' : 'pymysql[rsa]'],
        ),
      );
    }
    if (prepared.tray && await missingTray(py) != null) {
      out.add(
        need(
          tr('Faltan pystray y Pillow'),
          tr(
            'El icono de bandeja necesita pystray y Pillow. Sin ellos, la ventana funciona pero sin el icono.',
          ),
          const ['pystray', 'pillow'],
          optional: true,
        ),
      );
    }
    return out;
  }

  /// Para las pruebas: instala sin lanzar pip.
  static Future<String> Function(TkPython py, List<String> packages)?
  installOverride;

  /// Instala [packages] con el pip de [py]. Devuelve lo que escribió pip;
  /// si falla, un UserError con su salida.
  static Future<String> install(TkPython py, List<String> packages) async {
    final o = installOverride;
    if (o != null) return o(py, packages);
    final ProcessResult r;
    try {
      r = await Process.run(
        py.command!,
        [
          ...py.args,
          '-m',
          'pip',
          'install',
          '--disable-pip-version-check',
          ...packages,
        ],
        environment: const {'PYTHONIOENCODING': 'utf-8'},
      ).timeout(const Duration(minutes: 10));
    } on TimeoutException {
      throw UserError(tr('La instalación tardó demasiado.'));
    } on ProcessException catch (e) {
      throw UserError(tr('No se pudo lanzar Python: {0}', [e.message]));
    }
    final output = '${r.stdout}\n${r.stderr}'.trim();
    if (r.exitCode != 0) {
      final managed = output.contains('externally-managed-environment');
      throw UserError(
        [
          tr('No se pudo instalar {0}.', [packages.join(', ')]),
          if (managed)
            tr(
              'Este Python lo gestiona el sistema y no deja instalar paquetes con pip. Instale el Python de python.org y vuelva a intentarlo.',
            ),
          output.length > 1500
              ? output.substring(output.length - 1500)
              : output,
        ].join('\n\n'),
      );
    }
    return output;
  }

  /// Lanza la ventana [prepared]: el archivo generado en `build/` del
  /// proyecto, con su carpeta como carpeta de trabajo.
  static Future<TkRun> start(
    TkPrepared prepared, {
    TkDebugSession? debug,
    bool devtools = false,
  }) async {
    final key =
        p.normalize(prepared.id) + (debug?.tests ?? false ? '#tests' : '');
    if ((_runs[key]?.running ?? false) || !_starting.add(key)) {
      throw UserError(
        debug?.tests ?? false
            ? tr('Las pruebas de «{0}» ya están en marcha.', [prepared.name])
            : tr('«{0}» ya está abierta.', [prepared.name]),
      );
    }
    try {
      if (prepared.electron) {
        return await _launchElectron(prepared, key, devtools);
      }
      return await _launch(prepared, key, debug);
    } finally {
      _starting.remove(key);
    }
  }

  /// Lanza la aplicación de Electron de build/electron con el entorno
  /// compartido (instalándolo antes si falta). [devtools]: depurar, con las
  /// herramientas de desarrollo y los puntos de parada como `debugger;`.
  static Future<TkRun> _launchElectron(
    TkPrepared prepared,
    String key,
    bool devtools,
  ) async {
    final node = await TkElectronRuntime.findNode();
    if (node == null && await TkElectronRuntime.electron() == null) {
      throw UserError(
        tr(
          'Las aplicaciones de Electron necesitan Node.js. Instálelo desde nodejs.org y vuelva a intentarlo.',
        ),
      );
    }
    final app = File(prepared.file).parent.path;
    if (devtools) {
      await File(prepared.file).writeAsString(
        TkElectron.withBreakpoints(
          prepared.source,
          TkBreakpoints.of(prepared.id),
        ),
        flush: true,
      );
    }
    Process? proc;
    var stopped = false;
    final run = TkRun(prepared.id, prepared.name, () {
      stopped = true;
      proc?.kill();
    });
    _runs[key] = run;
    unawaited(() async {
      try {
        final bin = await TkElectronRuntime.ensure(run.add);
        if (stopped) return run.finish(-1);
        final env = TkElectronRuntime.environment(node)
          ..['DMSTUDIO_NODE_MODULES'] = await TkElectronRuntime.nodeModules();
        if (devtools) env['DMSTUDIO_DEVTOOLS'] = '1';
        final started = await Process.start(
          bin,
          [app],
          workingDirectory: prepared.id,
          environment: env,
          includeParentEnvironment: false,
        );
        proc = started;
        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen((l) {
                  if (!_electronNoise(l)) run.add(l);
                })
                .asFuture<void>(),
        ];
        final code = await started.exitCode;
        await Future.wait(
          done,
        ).timeout(const Duration(seconds: 2), onTimeout: () => const []);
        run.finish(code);
      } on UserError catch (e) {
        run.add(e.message);
        run.finish(1);
      } on Object catch (e) {
        run.add('$e');
        run.finish(1);
      }
    }());
    return run;
  }

  /// Avisos de Chromium que no dicen nada al usuario.
  static bool _electronNoise(String l) =>
      l.trim().isEmpty ||
      l.contains('Electron Security Warning') ||
      RegExp(r'^\[\d+:\d+/[\d.]+:(INFO|WARNING|VERBOSE)').hasMatch(l);

  /// Las pruebas en marcha (o las últimas) del proyecto [id].
  static TkRun? testsOf(String id) => _runs['${p.normalize(id)}#tests'];

  /// Carpeta de las pruebas de un proyecto.
  static String testsDir(String project) => p.join(project, 'tests');

  /// Argumentos del agente del depurador para [prepared] (escribe el agente
  /// en build/; con pruebas, también el programa como build/dms_app.py).
  static Future<List<String>> _debugArgs(
    TkPrepared prepared,
    File file,
    TkDebugSession debug,
  ) async {
    final build = file.parent.path;
    final agent = File(p.join(build, 'dms_debug.py'));
    await agent.writeAsString(tkDebugAgentPython, flush: true);
    var target = file.path;
    if (debug.tests) {
      target = p.join(build, 'dms_app.py');
      await File(target).writeAsString(prepared.source, flush: true);
    }
    return [
      agent.path,
      '--target',
      target,
      '--start',
      '${prepared.unitStart + 1}',
      '--end',
      '${prepared.unitStart + prepared.unitLines}',
      if (debug.tests) ...['--tests', testsDir(prepared.id)],
      if (!debug.trace) '--nodebug',
    ];
  }

  /// Variables de entorno de la ventana: lo único por donde le llegan las
  /// contraseñas de sus conexiones. Nunca al archivo generado ni al diseño.
  static Map<String, String> environment(TkPrepared p) => {
    if (p.ai && p.anthropicKey != null) 'ANTHROPIC_API_KEY': p.anthropicKey!,
    for (final e in p.vars.entries)
      if (e.key.trim().isNotEmpty)
        'DMSTUDIO_ENV_${e.key.trim().replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_').toUpperCase()}':
            e.value,
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

  static Future<TkRun> _launch(
    TkPrepared prepared,
    String key,
    TkDebugSession? debug,
  ) async {
    final found = await detect();
    // Las pruebas de una web usan su cliente de pruebas: no hay servidor.
    final web = prepared.web && !(debug?.tests ?? false);
    final py = prepared.web ? found.web : found;
    if (!py.ok) throw UserError(py.help);
    if (!launchable(py.command!)) {
      await forgetPython();
      throw UserError(tr('No se encontró Python en {0}.', [py.command]));
    }
    if (prepared.web) {
      final install = await missingFlask(py);
      if (install != null) {
        throw UserError(tr('Falta Flask. Instálelo con:\n{0}', [install]));
      }
    }
    if (prepared.ai) {
      final install = await missingAnthropic(py);
      if (install != null) {
        throw UserError(
          tr(
            'El Asistente IA necesita el SDK de Anthropic. Instálelo con:\n{0}',
            [install],
          ),
        );
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
    final script = debug == null
        ? [file.path]
        : await _debugArgs(prepared, file, debug);
    final debugPort = debug == null ? null : await debug.listen();
    final Process proc;
    try {
      proc = await Process.start(
        py.command!,
        [...py.args, '-u', ...script],
        // La carpeta del proyecto: sus archivos se abren por su nombre.
        workingDirectory: p.dirname(p.dirname(file.path)),
        environment: {
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
          'PYTHONDONTWRITEBYTECODE': '1',
          // El aviso del Tk de Apple no le dice nada al usuario.
          'TK_SILENCE_DEPRECATION': '1',
          'DMSTUDIO_WEB_SECRET': ?secret,
          if (debug != null) ...{
            'DMSTUDIO_DEBUG_PORT': '$debugPort',
            'DMSTUDIO_DEBUG_TOKEN': debug.token,
          },
          ...environment(prepared),
        },
      );
    } on ProcessException catch (e) {
      throw UserError(tr('No se pudo lanzar Python: {0}', [e.message]));
    }
    final run = TkRun(prepared.id, prepared.name, proc.kill)..debug = debug;
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
