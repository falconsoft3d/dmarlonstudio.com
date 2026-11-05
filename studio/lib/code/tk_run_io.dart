import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_debug.dart';
import 'tk_chrome.dart';
import 'tk_cpp_run.dart';
import 'tk_console.dart';
import 'tk_flutter_run.dart';
import 'tk_rn_run.dart';
import 'tk_pascal_run.dart';
import 'tk_debug_agent.dart';
import 'tk_electron.dart';
import 'tk_electron_run.dart';
import 'tk_next.dart';
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
      if (prepared.next) return await _launchNext(prepared, key, devtools);
      if (prepared.cpp) return await _launchCpp(prepared, key, devtools);
      if (prepared.pascal) return await _launchPascal(prepared, key);
      if (prepared.flutter) return await _launchFlutter(prepared, key);
      if (prepared.reactNative) return await _launchReactNative(prepared, key);
      if (prepared.react) return await _launchWebReact(prepared, key);
      if (prepared.html) return await _launchWebHtml(prepared, key);
      if (prepared.console != null) {
        return await _launchConsole(prepared, key, devtools);
      }
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
    final appCode = File(prepared.file).parent.path;
    // Una extensión se abre en su vista previa (la carpeta de al lado).
    final app = prepared.chrome
        ? p.join(p.dirname(appCode), 'extension-preview')
        : appCode;
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
        if (prepared.chrome) {
          await File(p.join(appCode, 'react.js')).writeAsString(
            TkChrome.reactBundle(await TkElectronRuntime.nodeModules()),
          );
        }
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

  /// Arranca el servidor de desarrollo de Next.js (con los módulos del
  /// entorno compartido) y, cuando está listo, deja su dirección en el
  /// TkRun. [devtools]: con los puntos de parada como `debugger;`.
  static Future<TkRun> _launchNext(
    TkPrepared prepared,
    String key,
    bool devtools,
  ) async {
    final node = await TkElectronRuntime.findNode();
    if (node == null) {
      throw UserError(
        tr(
          'Las aplicaciones de Next.js necesitan Node.js. Instálelo desde nodejs.org y vuelva a intentarlo.',
        ),
      );
    }
    // La carpeta del proyecto: la que tiene el package.json.
    var root = p.dirname(prepared.file);
    while (!File(p.join(root, 'package.json')).existsSync() &&
        p.dirname(root) != root) {
      root = p.dirname(root);
    }
    if (devtools && p.basename(p.dirname(prepared.file)) == 'dms') {
      await File(prepared.file).writeAsString(
        TkNext.unitModule(
          prepared.source,
          p.basenameWithoutExtension(prepared.file),
          breakpoints: TkBreakpoints.of(prepared.id),
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
        await TkElectronRuntime.ensure(run.add, next: true);
        if (stopped) return run.finish(-1);
        // Los módulos del entorno, sin instalarlos en cada proyecto.
        final modules = p.join(root, 'node_modules');
        if (!Link(modules).existsSync() && !Directory(modules).existsSync()) {
          await Link(modules).create(await TkElectronRuntime.nodeModules());
        }
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = server.port;
        await server.close();
        final env = TkElectronRuntime.environment(node)
          ..['NEXT_TELEMETRY_DISABLED'] = '1'
          ..['BROWSER'] = 'none';
        final started = await Process.start(
          node.node,
          [
            await TkElectronRuntime.nextBin(),
            'dev',
            '--webpack',
            '-p',
            '$port',
          ],
          workingDirectory: root,
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
                  if (run.url == null && l.contains('Ready')) {
                    run.url = run.address = 'http://localhost:$port';
                  }
                  if (l.trim().isNotEmpty) run.add(l);
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

  /// Compila la aplicación de C++ de build/cpp (los errores van a la
  /// salida, con las líneas de Form1.cpp) y la abre. [debug]: con
  /// información de depuración y sin optimizar.
  static Future<TkRun> _launchCpp(
    TkPrepared prepared,
    String key,
    bool debug,
  ) async {
    final cxx = TkCppTools.compiler();
    if (cxx == null || TkCppTools.fltkConfig() == null) {
      throw UserError(TkCppTools.needs().map((n) => n.why).join('\n'));
    }
    final dir = File(prepared.file).parent.path;
    final exe = p.join(dir, Platform.isWindows ? 'app.exe' : 'app');
    Process? proc;
    var stopped = false;
    final run = TkRun(prepared.id, prepared.name, () {
      stopped = true;
      proc?.kill();
    });
    _runs[key] = run;
    unawaited(() async {
      try {
        run.add(tr('Compilando…'));
        final (cflags, ldflags) = await TkCppTools.flags();
        final build = await Process.run(cxx, [
          '-std=c++17',
          if (debug) ...['-g', '-O0'] else '-O1',
          ...cflags,
          'main.cpp',
          '-o',
          exe,
          ...ldflags,
        ], workingDirectory: dir);
        for (final l in '${build.stderr}${build.stdout}'.split('\n')) {
          if (l.trim().isEmpty || l.startsWith('ld: warning')) continue;
          run.add(
            l
                .replaceAll('$dir${Platform.pathSeparator}', '')
                .replaceAllMapped(RegExp(r'(^|\s)\./'), (m) => m[1]!),
          );
        }
        if (build.exitCode != 0) {
          run.add(tr('No se pudo compilar.'));
          return run.finish(build.exitCode);
        }
        if (stopped) return run.finish(-1);
        final started = await Process.start(
          exe,
          const [],
          workingDirectory: prepared.id,
        );
        proc = started;
        run.add(
          tr(
            'Compilada: la aplicación está abierta (ciérrela o pulse Detener para terminar).',
          ),
        );
        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen(run.add)
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

  /// La web en HTML de build/html: un servidor propio (sin Node) que la
  /// sirve tal cual. La página pregunta por /__dms_version y se recarga al
  /// cambiar los archivos (al guardar).
  static Future<TkRun> _launchWebHtml(TkPrepared prepared, String key) async {
    final root = p.dirname(prepared.file);
    HttpServer? server;
    StreamSubscription<FileSystemEvent>? watch;
    late final TkRun run;
    run = TkRun(prepared.id, prepared.name, () {
      watch?.cancel();
      server?.close(force: true);
      run.finish(-1);
    });
    _runs[key] = run;
    try {
      var version = 0;
      watch = Directory(root).watch(recursive: true).listen((_) => version++);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      const reload =
          '<script>(() => { let v = null; setInterval(async () => { try { '
          'const n = await (await fetch("/__dms_version")).text(); '
          'if (v !== null && n !== v) location.reload(); v = n; } catch (_) {} }, 700); })();</script>';
      server.listen((req) async {
        final res = req.response;
        try {
          final path = Uri.decodeComponent(req.uri.path);
          if (path == '/__dms_version') {
            res.headers.contentType = ContentType.text;
            res.headers.set('cache-control', 'no-store');
            res.write('$version');
            return;
          }
          final file = File(
            p.normalize(
              p.join(root, path == '/' ? 'index.html' : path.substring(1)),
            ),
          );
          if (!p.isWithin(root, file.path) || !file.existsSync()) {
            res.statusCode = HttpStatus.notFound;
            res.write('404');
            return;
          }
          res.headers.set('cache-control', 'no-store');
          res.headers.contentType = switch (p.extension(file.path)) {
            '.html' => ContentType.html,
            '.js' => ContentType('text', 'javascript', charset: 'utf-8'),
            '.css' => ContentType('text', 'css', charset: 'utf-8'),
            '.json' => ContentType.json,
            '.svg' => ContentType('image', 'svg+xml'),
            '.png' => ContentType('image', 'png'),
            '.jpg' || '.jpeg' => ContentType('image', 'jpeg'),
            _ => ContentType.binary,
          };
          if (p.extension(file.path) == '.html') {
            res.write(
              (await file.readAsString()).replaceFirst(
                '</body>',
                '$reload\n</body>',
              ),
            );
          } else {
            await res.addStream(file.openRead());
          }
        } on Object catch (e) {
          res.statusCode = HttpStatus.internalServerError;
          res.write('$e');
        } finally {
          await res.close();
        }
      });
      run.url = run.address = 'http://127.0.0.1:${server.port}/';
      run.add(tr('Abierta en el navegador: {0}', [run.url]));
    } on Object catch (e) {
      run.add('$e');
      await watch?.cancel();
      await server?.close(force: true);
      run.finish(1);
    }
    return run;
  }

  /// La web de React de build/react: `vite` con el entorno compartido (se
  /// recarga sola al cambiar los archivos, al guardar).
  static Future<TkRun> _launchWebReact(TkPrepared prepared, String key) async {
    var root = p.dirname(prepared.file);
    while (!File(p.join(root, 'package.json')).existsSync() &&
        p.dirname(root) != root) {
      root = p.dirname(root);
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
        final node = await TkViteRuntime.ensure(run.add);
        if (stopped) return run.finish(-1);
        final modules = p.join(root, 'node_modules');
        if (!Link(modules).existsSync() && !Directory(modules).existsSync()) {
          await Link(modules).create(await TkViteRuntime.nodeModules());
        }
        final port = await TkFlutterTools.freePort();
        final started = await Process.start(
          node.node,
          [
            await TkViteRuntime.vite(),
            '--port',
            '$port',
            '--strictPort',
            '--host',
            '127.0.0.1',
          ],
          workingDirectory: root,
          environment: TkElectronRuntime.environment(node),
          includeParentEnvironment: false,
        );
        proc = started;
        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen((l) {
                  final clean = l.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
                  if (run.url == null && clean.contains('Local:')) {
                    run.url = run.address = 'http://127.0.0.1:$port/';
                    run.add(tr('Abierta en el navegador: {0}', [run.url]));
                    return;
                  }
                  if (clean.trim().isNotEmpty) run.add(clean);
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

  /// La app de React Native de build/reactnative: `expo start --web` con el
  /// entorno compartido, dentro del simulador del estudio. Expo recarga la
  /// app sola al cambiar los archivos (al guardar).
  static Future<TkRun> _launchReactNative(
    TkPrepared prepared,
    String key,
  ) async {
    var root = p.dirname(prepared.file);
    while (!File(p.join(root, 'package.json')).existsSync() &&
        p.dirname(root) != root) {
      root = p.dirname(root);
    }
    Process? proc;
    TkFlutterSim? sim;
    var stopped = false;
    final run = TkRun(prepared.id, prepared.name, () {
      stopped = true;
      proc?.kill();
      sim?.close();
    });
    _runs[key] = run;
    unawaited(() async {
      try {
        final node = await TkRnRuntime.ensure(run.add);
        if (stopped) return run.finish(-1);
        final modules = p.join(root, 'node_modules');
        if (!Link(modules).existsSync() && !Directory(modules).existsSync()) {
          await Link(modules).create(await TkRnRuntime.nodeModules());
        }
        run.add(tr('Arrancando Expo…'));
        final port = await TkFlutterTools.freePort();
        final env = TkElectronRuntime.environment(node)
          ..['EXPO_NO_TELEMETRY'] = '1'
          ..['BROWSER'] = 'none';
        final started = await Process.start(
          node.node,
          [await TkRnRuntime.expoCli(), 'start', '--web', '--port', '$port'],
          workingDirectory: root,
          environment: env,
          includeParentEnvironment: false,
        );
        proc = started;
        void onLine(String l) {
          if (sim == null && l.contains('Waiting on http')) {
            unawaited(() async {
              sim = await TkFlutterSim.start(
                'http://localhost:$port',
                prepared.name,
              );
              run.url = sim!.url;
              run.address = sim!.url;
              run.add(tr('Abierta en el simulador: {0}', [sim!.url]));
              final ip = await TkRnRuntime.lanAddress();
              if (ip != null) {
                run.add(
                  tr(
                    'En su teléfono: abra Expo Go (en la misma red) e introduzca exp://{0}:{1}',
                    [ip, port],
                  ),
                );
              }
            }());
            return;
          }
          final t = l.trim();
          if (t.isEmpty ||
              t.startsWith('Starting project at') ||
              t.startsWith('Starting Metro') ||
              t.startsWith('Waiting on') ||
              t.startsWith('Logs for your project')) {
            return;
          }
          run.add(l);
        }

        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen(onLine)
                .asFuture<void>(),
        ];
        final code = await started.exitCode;
        await Future.wait(
          done,
        ).timeout(const Duration(seconds: 2), onTimeout: () => const []);
        await sim?.close();
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

  /// La app de Flutter de build/flutter: la prepara la primera vez
  /// (`flutter create`), la sirve con `flutter run -d web-server` y la abre
  /// en el simulador del estudio. Lo que se escribe en la entrada le llega a
  /// `flutter run` (R: volver a compilar).
  static Future<TkRun> _launchFlutter(TkPrepared prepared, String key) async {
    final flutter = TkFlutterTools.flutter();
    if (flutter == null) {
      throw UserError(
        tr(
          'Falta Flutter: instálelo desde flutter.dev (o con: brew install --cask flutter).',
        ),
      );
    }
    final dir = File(prepared.file).parent.parent.path;
    Process? proc;
    TkFlutterSim? sim;
    var stopped = false;
    final run = TkRun(prepared.id, prepared.name, () {
      stopped = true;
      proc?.kill();
      sim?.close();
    });
    _runs[key] = run;
    unawaited(() async {
      try {
        Future<bool> step(List<String> args, String label) async {
          run.add(label);
          final r = await Process.run(flutter, args, workingDirectory: dir);
          if (r.exitCode == 0) return true;
          for (final l in '${r.stdout}${r.stderr}'.split('\n')) {
            if (l.trim().isNotEmpty) run.add(l);
          }
          return false;
        }

        if (!Directory(p.join(dir, 'web')).existsSync()) {
          // flutter create no toca lo que ya hay, pero por si acaso.
          final keep = {
            for (final f in ['pubspec.yaml', 'lib/main.dart', 'lib/app.dart'])
              f: await File(p.join(dir, f)).readAsString(),
          };
          final name = RegExp(
            r'^name:\s*(\S+)',
            multiLine: true,
          ).firstMatch(keep['pubspec.yaml']!)?[1];
          if (!await step([
            'create',
            '--platforms',
            'web,ios,android,macos',
            '--org',
            'com.dmarlonstudio',
            if (name != null) ...['--project-name', name],
            '.',
          ], tr('Creando el proyecto de Flutter (solo la primera vez)…'))) {
            return run.finish(1);
          }
          for (final e in keep.entries) {
            await File(p.join(dir, e.key)).writeAsString(e.value);
          }
          final tests = Directory(p.join(dir, 'test'));
          if (tests.existsSync()) await tests.delete(recursive: true);
        }
        if (!await step(['pub', 'get'], tr('Preparando los paquetes…'))) {
          return run.finish(1);
        }
        if (stopped) return run.finish(-1);
        final desktop = prepared.desktop;
        run.add(
          desktop
              ? tr('Compilando la app de escritorio…')
              : tr('Compilando para el simulador…'),
        );
        final port = await TkFlutterTools.freePort();
        final started = await Process.start(
          flutter,
          desktop
              ? [
                  'run',
                  '-d',
                  Platform.isMacOS
                      ? 'macos'
                      : Platform.isWindows
                      ? 'windows'
                      : 'linux',
                ]
              : [
                  'run',
                  '-d',
                  'web-server',
                  '--web-hostname',
                  '127.0.0.1',
                  '--web-port',
                  '$port',
                ],
          workingDirectory: dir,
        );
        proc = started;
        run.input = (line) => started.stdin.write('$line\n');
        void onLine(String l) {
          final served = RegExp(
            r'is being served at (http://\S+)',
          ).firstMatch(l);
          if (served != null && sim == null) {
            unawaited(() async {
              sim = await TkFlutterSim.start(served[1]!, prepared.name);
              run.url = sim!.url;
              run.address = sim!.url;
              run.add(tr('Abierta en el simulador: {0}', [sim!.url]));
            }());
            return;
          }
          if (desktop && l.contains('Flutter run key commands')) {
            run.add(
              tr('Abierta en su ventana: al guardar se vuelve a cargar.'),
            );
            return;
          }
          if (l.startsWith('Recompile complete') ||
              l.startsWith('Restarted application')) {
            sim?.version++;
            run.add(
              desktop
                  ? tr('Recargada.')
                  : tr('Recompilada: el simulador se recarga.'),
            );
            return;
          }
          if (!TkFlutterTools.noise(l)) run.add(l);
        }

        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen(onLine)
                .asFuture<void>(),
        ];
        final code = await started.exitCode;
        await Future.wait(
          done,
        ).timeout(const Duration(seconds: 2), onTimeout: () => const []);
        run.input = null;
        await sim?.close();
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

  /// Compila (si hace falta) la aplicación de consola de build/console y la
  /// ejecuta con la entrada abierta: lo que se escribe en la Salida le llega
  /// por stdin.
  static Future<TkRun> _launchConsole(
    TkPrepared prepared,
    String key,
    bool debug,
  ) async {
    final lang = prepared.console!;
    final dir = File(prepared.file).parent.path;
    final exe = p.join(dir, Platform.isWindows ? 'app.exe' : 'app');
    (String, List<String>)? python;
    if (lang == 'py') {
      final py = (await detect()).web;
      if (py.command == null) throw UserError(py.help);
      python = (py.command!, [...py.args, '-u', prepared.file]);
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
        var command = python;
        if (command == null) {
          run.add(tr('Compilando…'));
          final (cc, args) = (await TkConsole.compile(
            lang,
            dir,
            exe,
            debug: debug,
          ))!;
          final build = await Process.run(cc, args, workingDirectory: dir);
          for (final l in TkConsole.messages(
            '${build.stdout}${build.stderr}',
            dir,
          )) {
            run.add(l);
          }
          if (build.exitCode != 0 || !File(exe).existsSync()) {
            run.add(tr('No se pudo compilar.'));
            return run.finish(build.exitCode == 0 ? 1 : build.exitCode);
          }
          command = (exe, const <String>[]);
        }
        if (stopped) return run.finish(-1);
        final started = await Process.start(
          command.$1,
          command.$2,
          workingDirectory: prepared.id,
          environment: const {'PYTHONIOENCODING': 'utf-8'},
        );
        proc = started;
        run.input = (line) {
          try {
            started.stdin.write('$line\n');
          } on Object {
            // El programa ya no lee.
          }
        };
        final done = [
          started.stdout
              .transform(const Utf8Decoder(allowMalformed: true))
              .listen(run.addText)
              .asFuture<void>(),
          started.stderr
              .transform(const Utf8Decoder(allowMalformed: true))
              .listen(run.addText)
              .asFuture<void>(),
        ];
        final code = await started.exitCode;
        await Future.wait(
          done,
        ).timeout(const Duration(seconds: 2), onTimeout: () => const []);
        run.input = null;
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

  /// Compila con lazbuild la aplicación de Pascal de build/pascal (los
  /// errores van a la salida, con las líneas de Form1.pas) y la abre.
  static Future<TkRun> _launchPascal(TkPrepared prepared, String key) async {
    final lazbuild = TkPascalTools.lazbuild();
    if (lazbuild == null) {
      throw UserError(TkPascalTools.needs().map((n) => n.why).join('\n'));
    }
    final dir = File(prepared.file).parent.path;
    final exe = p.join(dir, Platform.isWindows ? 'app.exe' : 'app');
    Process? proc;
    var stopped = false;
    final run = TkRun(prepared.id, prepared.name, () {
      stopped = true;
      proc?.kill();
    });
    _runs[key] = run;
    unawaited(() async {
      try {
        run.add(tr('Compilando…'));
        final build = await Process.run(lazbuild, [
          ...TkPascalTools.args(),
          'app.lpi',
        ], workingDirectory: dir);
        final out = '${build.stdout}${build.stderr}';
        for (final l in TkPascalTools.messages(out, dir)) {
          run.add(l);
        }
        if (build.exitCode != 0 || !File(exe).existsSync()) {
          run.add(tr('No se pudo compilar.'));
          return run.finish(build.exitCode == 0 ? 1 : build.exitCode);
        }
        if (stopped) return run.finish(-1);
        final started = await Process.start(
          exe,
          const [],
          workingDirectory: prepared.id,
        );
        proc = started;
        run.add(
          tr(
            'Compilada: la aplicación está abierta (ciérrela o pulse Detener para terminar).',
          ),
        );
        final done = [
          for (final s in [started.stdout, started.stderr])
            s
                .transform(const Utf8Decoder(allowMalformed: true))
                .transform(const LineSplitter())
                .listen(run.add)
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
