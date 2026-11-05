import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors.dart';
import '../core/studio_db.dart';
import '../i18n/tr.dart';
import 'tk_electron.dart';

/// Node.js del equipo: lo necesita npm para instalar Electron y React.
class TkNode {
  const TkNode(this.node, this.npm);
  final String node;
  final String npm;

  /// Carpeta de node: va delante en el PATH de npm (su script la pide).
  String get dir => p.dirname(node);
}

/// El entorno compartido de Electron y React: se instala una vez (con npm)
/// en la carpeta de datos del estudio y lo usan todos los proyectos.
class TkElectronRuntime {
  TkElectronRuntime._();

  /// Carpeta del entorno en las pruebas.
  static String? dirOverride;

  /// Node fijado (las pruebas).
  static TkNode? nodeOverride;

  /// Variables de más para la aplicación (las pruebas).
  static Map<String, String> extraEnv = const {};

  static Future<String> dir() async {
    final o = dirOverride;
    if (o != null) return o;
    final base =
        StudioDb.dirOverride ?? (await getApplicationSupportDirectory()).path;
    return p.join(base, 'electron-runtime');
  }

  static String _exe(String name) => Platform.isWindows ? '$name.cmd' : name;

  /// Busca node y npm: el PATH de una app abierta desde el Finder no trae
  /// /opt/homebrew/bin ni los de nvm o volta.
  static Future<TkNode?> findNode() async {
    final o = nodeOverride;
    if (o != null) return o;
    final home = Platform.environment['HOME'] ?? '';
    final dirs = <String>[
      ...(Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '$home/.volta/bin',
      '$home/.local/bin',
      if (Platform.isWindows) ...[
        r'C:\Program Files\nodejs',
        '${Platform.environment['APPDATA'] ?? ''}\\npm',
      ],
    ];
    // Las versiones de nvm, de la más nueva a la más vieja.
    final nvm = Directory(p.join(home, '.nvm', 'versions', 'node'));
    if (nvm.existsSync()) {
      final versions = nvm.listSync().whereType<Directory>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      dirs.addAll(versions.map((v) => p.join(v.path, 'bin')));
    }
    for (final d in dirs) {
      if (d.isEmpty) continue;
      final node = p.join(d, Platform.isWindows ? 'node.exe' : 'node');
      final npm = p.join(d, _exe('npm'));
      if (File(node).existsSync() && File(npm).existsSync()) {
        return TkNode(node, npm);
      }
    }
    return null;
  }

  /// El binario de Electron del entorno (null: aún no está instalado).
  static Future<String?> electron() async {
    final root = await dir();
    final pkg = p.join(root, 'node_modules', 'electron');
    final txt = File(p.join(pkg, 'path.txt'));
    if (!txt.existsSync()) return null;
    final bin = p.join(pkg, 'dist', txt.readAsStringSync().trim());
    if (!File(bin).existsSync()) return null;
    final react = File(p.join(root, 'node_modules', 'react', 'package.json'));
    final dom = File(p.join(root, 'node_modules', 'react-dom', 'package.json'));
    return react.existsSync() && dom.existsSync() ? bin : null;
  }

  static Future<String> nodeModules() async =>
      p.join(await dir(), 'node_modules');

  /// El entorno sin la variable que convierte Electron en Node: la heredan
  /// los procesos lanzados desde otra app de Electron (como VS Code).
  static Map<String, String> environment(TkNode? node) {
    final env = Map<String, String>.of(Platform.environment)
      ..remove('ELECTRON_RUN_AS_NODE');
    if (node != null) {
      final sep = Platform.isWindows ? ';' : ':';
      env['PATH'] = '${node.dir}$sep${env['PATH'] ?? ''}';
    }
    env.addAll(extraEnv);
    return env;
  }

  static final _installing = <String, Future<String>>{};

  /// Instala el entorno si falta y devuelve el binario de Electron. [log]
  /// recibe lo que escribe npm.
  static Future<String> ensure(void Function(String line) log) async {
    final ready = await electron();
    if (ready != null) return ready;
    final root = await dir();
    return _installing[root] ??= _install(
      root,
      log,
    ).whenComplete(() => _installing.remove(root));
  }

  static Future<String> _install(String root, void Function(String) log) async {
    final node = await findNode();
    if (node == null) {
      throw UserError(
        tr(
          'Las aplicaciones de Electron necesitan Node.js. Instálelo desde nodejs.org y vuelva a intentarlo.',
        ),
      );
    }
    await Directory(root).create(recursive: true);
    await File(p.join(root, 'package.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': 'dmarlon-electron-runtime',
        'private': true,
        'dependencies': {
          'electron': TkElectron.electronVersion,
          'react': TkElectron.reactVersion,
          'react-dom': TkElectron.reactVersion,
        },
      }),
    );
    log(tr('Instalando Electron y React (solo la primera vez; unos 100 MB)…'));
    Future<void> run(String exe, List<String> args) async {
      final proc = await Process.start(
        exe,
        args,
        workingDirectory: root,
        environment: environment(node),
        includeParentEnvironment: false,
        runInShell: Platform.isWindows,
      );
      final done = [
        for (final s in [proc.stdout, proc.stderr])
          s
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter())
              .listen((l) {
                if (l.trim().isNotEmpty) log(l);
              })
              .asFuture<void>(),
      ];
      final code = await proc.exitCode.timeout(
        const Duration(minutes: 15),
        onTimeout: () {
          proc.kill();
          return -1;
        },
      );
      await Future.wait(done);
      if (code != 0) {
        throw UserError(
          tr('No se pudo instalar Electron (npm terminó con el código {0}).', [
            code,
          ]),
        );
      }
    }

    await run(node.npm, ['install', '--no-audit', '--no-fund']);
    // Algunos npm no ejecutan el script que descarga el binario.
    final txt = File(p.join(root, 'node_modules', 'electron', 'path.txt'));
    if (!txt.existsSync()) {
      await run(node.node, [p.join('node_modules', 'electron', 'install.js')]);
    }
    final bin = await electron();
    if (bin == null) {
      throw UserError(tr('No se pudo instalar Electron.'));
    }
    log(tr('Electron instalado.'));
    return bin;
  }
}
