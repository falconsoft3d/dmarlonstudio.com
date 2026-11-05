import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_run_types.dart';

/// Lo que hace falta para compilar C++ con FLTK: un compilador y
/// fltk-config. Una app abierta desde el Finder no tiene /opt/homebrew/bin
/// en el PATH: se busca también ahí.
class TkCppTools {
  TkCppTools._();

  /// Herramientas fijadas (las pruebas).
  static ({String cxx, String fltk})? override;

  static List<String> get _dirs => [
    ...(Platform.environment['PATH'] ?? '').split(
      Platform.isWindows ? ';' : ':',
    ),
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    if (Platform.isWindows) ...[
      r'C:\msys64\ucrt64\bin',
      r'C:\msys64\mingw64\bin',
    ],
  ];

  static String? _find(List<String> names) {
    for (final d in _dirs) {
      if (d.isEmpty) continue;
      for (final n in names) {
        final f = p.join(d, Platform.isWindows ? '$n.exe' : n);
        if (File(f).existsSync()) return f;
      }
    }
    return null;
  }

  static String? compiler() =>
      override?.cxx ?? _find(['c++', 'clang++', 'g++']);

  static String? fltkConfig() {
    final o = override;
    if (o != null) return o.fltk;
    final found = _find(['fltk-config']);
    if (found != null) return found;
    // En Windows (MSYS2) es un script de sh sin .exe.
    for (final d in _dirs) {
      final f = p.join(d, 'fltk-config');
      if (d.isNotEmpty && File(f).existsSync()) return f;
    }
    return null;
  }

  static String? brew() => _find(['brew']);

  /// Lo que falta para compilar (vacío: nada).
  static List<TkNeed> needs() {
    final out = <TkNeed>[];
    if (compiler() == null) {
      out.add(
        TkNeed(
          title: tr('Falta un compilador de C++'),
          why: tr(
            'Para compilar C++ hace falta un compilador: en macOS, las herramientas de línea de órdenes de Xcode; en Linux, g++; en Windows, MSYS2.',
          ),
          packages: const ['c++'],
          command: Platform.isMacOS
              ? 'xcode-select --install'
              : Platform.isLinux
              ? 'sudo apt install g++'
              : 'pacman -S mingw-w64-ucrt-x86_64-gcc',
          installer: Platform.isMacOS
              ? () async {
                  await Process.run('xcode-select', ['--install']);
                  throw UserError(
                    tr(
                      'Se abrió el instalador de Apple: termine la instalación y vuelva a ejecutar.',
                    ),
                  );
                }
              : null,
        ),
      );
    }
    if (fltkConfig() == null) {
      final brew = TkCppTools.brew();
      out.add(
        TkNeed(
          title: tr('Falta FLTK'),
          why: tr(
            'Las aplicaciones de C++ usan la biblioteca FLTK para sus ventanas.',
          ),
          packages: const ['fltk'],
          command: Platform.isMacOS
              ? 'brew install fltk'
              : Platform.isLinux
              ? 'sudo apt install libfltk1.3-dev'
              : 'pacman -S mingw-w64-ucrt-x86_64-fltk',
          installer: brew == null
              ? null
              : () async {
                  final r = await Process.run(brew, ['install', 'fltk']);
                  if (r.exitCode != 0) {
                    throw UserError(
                      tr('No se pudo instalar FLTK: {0}', ['${r.stderr}']),
                    );
                  }
                },
        ),
      );
    }
    return out;
  }

  /// Las opciones de compilación y de enlazado de FLTK (con imágenes).
  static Future<(List<String>, List<String>)> flags() async {
    final cfg = fltkConfig();
    if (cfg == null) throw UserError(tr('Falta FLTK'));
    Future<List<String>> run(String what) async {
      final r = await Process.run(Platform.isWindows ? 'sh' : cfg, [
        if (Platform.isWindows) cfg,
        '--use-images',
        what,
      ]);
      return '${r.stdout}'
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final ld = await run('--ldflags');
    // fltk-config de Homebrew puede apuntar a una versión de libpng que ya
    // no está: las carpetas de bibliotecas de Homebrew van antes.
    final extra = [
      for (final d in ['/opt/homebrew/lib', '/usr/local/lib'])
        if (Directory(d).existsSync()) '-L$d',
    ];
    return (await run('--cxxflags'), [...extra, ...ld]);
  }
}
