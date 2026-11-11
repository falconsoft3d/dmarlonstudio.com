// DMarlonPass en C++ (FLTK): el diseño, el código, el inglés y,
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
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_pass');

  test('diseño: C++, sin problemas, con la barra, el tablero y la clave maestra', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(names, containsAll(['Menu1', 'Tick', 'DlgOpen', 'DlgSave', 'DlgKey', 'Top', 'Search', 'Board', 'Master', 'BtnUnlock', 'Status']));
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: KDBX 4, la criptografía y las pruebas con KeePassXC', () {
    final code = TkCpp.files(e.design, e.code)['Form1.cpp']!;
    for (final s in [
      '0x9AA2D903',
      'argon2',
      'struct Aes256',
      'struct ChaCha20',
      'hmac_sha256',
      'FIXTURE_3',
      'FIXTURE_4',
      'DMS_PASS_SELFTEST',
      'DMS_PASS_UITEST',
      'DMS_PASS_SHOT',
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
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_pass');
    expect(x.name, 'DMarlonPass (C++)');
    expect(x.code, contains('const char* const G_BANKING = "Banking";'));
    expect(
      x.code.substring(x.code.indexOf('namespace kp')),
      e.code.substring(e.code.indexOf('namespace kp')),
    );
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_PASS_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_pass_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final config = p.join(tmp.path, 'config');
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_PASS_SELFTEST': '1', 'DMS_PASS_DIR': config},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      if (Platform.isMacOS) {
        final u = await Process.run(
          exe,
          const [],
          environment: {'DMS_PASS_UITEST': '1', 'DMS_PASS_DIR': config},
        ).timeout(const Duration(minutes: 2));
        expect(u.exitCode, 0, reason: '${u.stdout}${u.stderr}');
        expect('${u.stdout}', contains('uitest ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
