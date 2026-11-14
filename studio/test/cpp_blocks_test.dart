// Bloques Neón en C++ (FLTK): el diseño, el código, el inglés y,
// si hay compilador, que compila y pasan sus pruebas internas sin ventana.
import 'dart:io';

import 'package:dmarlon_studio/code/tk_cpp.dart';
import 'package:dmarlon_studio/code/tk_cpp_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

/// Escribe el proyecto del ejemplo en [dir] y lo compila con FLTK.
Future<String> build(TkExample e, Directory dir) async {
  for (final f in TkCpp.files(e.design, e.code).entries) {
    File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
  }
  final (cflags, ldflags) = await TkCppTools.flags();
  final exe = p.join(dir.path, Platform.isWindows ? 'app.exe' : 'app');
  final r = await Process.run(TkCppTools.compiler()!, [
    '-std=c++17',
    '-O2',
    '-Wall',
    ...cflags,
    'main.cpp',
    '-o',
    exe,
    ...ldflags,
  ], workingDirectory: dir.path);
  expect(r.exitCode, 0, reason: '${r.stderr}');
  // Sin avisos del compilador en el código (los del enlazador no cuentan).
  expect(
    '${r.stderr}',
    isNot(matches(RegExp(r'\.(cpp|h):\d+:\d+: warning'))),
    reason: '${r.stderr}',
  );
  return exe;
}

bool get _canBuild =>
    TkCppTools.compiler() != null && TkCppTools.fltkConfig() != null;

void main() {
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_blocks');

  test('diseño: C++, sin problemas, con el menú, el reloj y el tablero', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(names, containsAll(['Menu1', 'Tick', 'Board']));
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: las piezas, la bolsa, la reserva y el teclado', () {
    final code = TkCpp.files(e.design, e.code)['Form1.cpp']!;
    for (final s in [
      'SHAPES[PIECES][4][4]',
      'bag_fill',
      'hard_drop',
      'do_hold',
      'class Arena',
      'FL_KEYUP',
      'DMS_BLOCKS_SELFTEST',
      'DMS_BLOCKS_UITEST',
      'DMS_BLOCKS_SHOT',
    ]) {
      expect(code, contains(s), reason: s);
    }
    final used = RegExp(r'tx::([A-Z_0-9]+)').allMatches(code).map((m) => m[1]);
    for (final k in used.toSet()) {
      expect(code, contains('const char* const $k ='), reason: k);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_blocks');
    expect(x.name, 'Neon Blocks (C++)');
    expect(x.code, contains('const char* const HOLD = "HOLD";'));
    expect(
      x.code.substring(x.code.indexOf('namespace nb')),
      e.code.substring(e.code.indexOf('namespace nb')),
    );
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_BLOCKS_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_blocks_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final config = p.join(tmp.path, 'config');
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_BLOCKS_SELFTEST': '1', 'DMS_BLOCKS_CONFIG': config},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      if (Platform.isMacOS) {
        final u = await Process.run(
          exe,
          const [],
          environment: {'DMS_BLOCKS_UITEST': '1', 'DMS_BLOCKS_CONFIG': config},
        ).timeout(const Duration(minutes: 2));
        expect(u.exitCode, 0, reason: '${u.stdout}${u.stderr}');
        expect('${u.stdout}', contains('uitest ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  // DMS_BLOCKS_SHOTS=carpeta: las capturas de la web, en español y en inglés
  // (window, tokens, menu, menu-days, menu-models y settings en <carpeta>/<idioma>).
  test(
    'capturas',
    () async {
      final out = Platform.environment['DMS_BLOCKS_SHOTS'];
      if (out == null) return markTestSkipped('Sin DMS_BLOCKS_SHOTS.');
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
      for (final (lang, t) in [('es', id), ('en', (String s) => catalog[s] ?? s)]) {
        final x = tkCppExamples(t).firstWhere((e) => e.seed == 'cpp_blocks');
        final tmp = await Directory.systemTemp.createTemp('dms_blocks_shots_');
        addTearDown(() => tmp.delete(recursive: true));
        final exe = await build(x, tmp);
        final r = await Process.run(exe, const [], environment: {
          'DMS_BLOCKS_SHOT': p.join(out, lang),
          'DMS_BLOCKS_CONFIG': p.join(tmp.path, 'config'),
        }).timeout(const Duration(minutes: 2));
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
