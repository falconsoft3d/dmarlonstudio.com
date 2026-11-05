import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_cpp_run.dart';
import 'tk_run_types.dart';

/// Lo que hace falta para compilar Pascal: Lazarus (lazbuild) con Free
/// Pascal. Una app abierta desde el Finder no tiene /usr/local/bin ni
/// /Applications/Lazarus en el PATH: se busca también ahí.
class TkPascalTools {
  TkPascalTools._();

  /// lazbuild fijado (las pruebas).
  static String? override;

  static List<String> get _dirs => [
    ...(Platform.environment['PATH'] ?? '').split(
      Platform.isWindows ? ';' : ':',
    ),
    '/Applications/Lazarus',
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/usr/lib/lazarus/default',
    if (Platform.isWindows) ...[r'C:\lazarus', r'C:\Program Files\Lazarus'],
  ];

  static String? lazbuild() {
    if (override != null) return override;
    for (final d in _dirs) {
      if (d.isEmpty) continue;
      final f = p.join(d, Platform.isWindows ? 'lazbuild.exe' : 'lazbuild');
      if (File(f).existsSync()) return f;
    }
    return null;
  }

  /// Opciones de lazbuild: en un Mac con Apple Silicon, compilar para arm64
  /// con Cocoa (lazbuild es x86_64 y si no compila para Intel).
  static List<String> args() => [
    if (Platform.isMacOS) '--ws=cocoa',
    if (Abi.current() == Abi.macosArm64) '--cpu=aarch64',
  ];

  /// Opciones del compilador para el proyecto: en macOS, dónde están las
  /// bibliotecas del sistema (el SDK) y el enlazador clásico (el nuevo de
  /// Apple no acepta los objetos de Free Pascal 3.2).
  static Future<List<String>> options() async {
    if (!Platform.isMacOS) return const [];
    final r = await Process.run('xcrun', ['--show-sdk-path']);
    final sdk = '${r.stdout}'.trim();
    return [if (r.exitCode == 0 && sdk.isNotEmpty) '-XR$sdk', '-k-ld_classic'];
  }

  /// Lo que falta para compilar (vacío: nada).
  static List<TkNeed> needs() {
    if (lazbuild() != null) return const [];
    final brew = TkCppTools.brew();
    return [
      TkNeed(
        title: tr('Falta Lazarus'),
        why: tr(
          'Las aplicaciones de Pascal se compilan con Lazarus y Free Pascal (lazbuild).',
        ),
        packages: const ['lazarus'],
        command: Platform.isMacOS
            ? 'brew install fpc && brew install --cask lazarus'
            : Platform.isLinux
            ? 'sudo apt install lazarus'
            : 'https://www.lazarus-ide.org',
        installer: Platform.isMacOS && brew != null
            ? () async {
                for (final a in [
                  ['install', 'fpc'],
                  ['install', '--cask', 'lazarus'],
                ]) {
                  final r = await Process.run(brew, a);
                  if (r.exitCode != 0) {
                    throw UserError(
                      tr('No se pudo instalar Lazarus: {0}', ['${r.stderr}']),
                    );
                  }
                }
              }
            : null,
      ),
    ];
  }

  /// Las líneas de lazbuild que dicen algo al usuario: errores y avisos de
  /// su código (sin la carpeta), y los errores de enlazado.
  static List<String> messages(String output, String dir) {
    final out = <String>[];
    for (final raw in output.split('\n')) {
      final l = raw.trimRight();
      if (!RegExp(r'\b(Error|Fatal|Warning)\b').hasMatch(l)) continue;
      if (l.contains('ppcx64 returned') ||
          l.contains('ppca64 returned') ||
          l.contains('(lazarus) Compile Project') ||
          l.contains('(lazbuild) failed') ||
          l.contains('There were') ||
          l.contains('Compilation aborted') ||
          l.startsWith('ld: warning') ||
          l.contains('/Applications/Lazarus/') ||
          RegExp(r'Warning: \(lazarus\)').hasMatch(l)) {
        continue;
      }
      var line = l;
      // (En macOS, /var es /private/var: lazbuild da la ruta real.)
      try {
        final real = Directory(dir).resolveSymbolicLinksSync();
        line = line.replaceAll('$real${Platform.pathSeparator}', '');
      } on FileSystemException {
        // Sin carpeta: se queda como está.
      }
      out.add(line.replaceAll('$dir${Platform.pathSeparator}', ''));
    }
    return out;
  }
}
