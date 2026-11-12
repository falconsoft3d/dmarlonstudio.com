// OpenD++ en Pascal (Lazarus): el diseño, el código, el inglés y, si hay
// Lazarus, que compila y pasan sus pruebas internas sin abrir la ventana.
import 'dart:io';

import 'package:dmarlon_studio/code/tk_cpp.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_pascal.dart';
import 'package:dmarlon_studio/code/tk_pascal_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

/// Escribe el proyecto en [dir] y lo compila con lazbuild.
Future<String> build(TkExample e, Directory dir) async {
  final files = TkPascal.files(
    e.design,
    e.code,
    options: await TkPascalTools.options(),
  );
  for (final f in files.entries) {
    File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
  }
  final r = await Process.run(TkPascalTools.lazbuild()!, [
    ...TkPascalTools.args(),
    'app.lpi',
  ], workingDirectory: dir.path);
  final exe = p.join(dir.path, Platform.isWindows ? 'app.exe' : 'app');
  expect(
    r.exitCode == 0 && File(exe).existsSync(),
    isTrue,
    reason: TkPascalTools.messages('${r.stdout}${r.stderr}', dir.path).join('\n'),
  );
  return exe;
}

void main() {
  final e = tkPascalExamples(id).firstWhere((e) => e.seed == 'pascal_opend');

  test('diseño: Pascal, sin problemas, con el menú, el reloj, los diálogos y el lienzo', () {
    final d = e.design;
    expect(d.isPascal, isTrue);
    expect(d.problems(), isEmpty);
    for (final w in d.widgets) {
      expect(tkPascalKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(
      names,
      containsAll(['Menu1', 'Tick', 'DlgOpen', 'DlgSave', 'DlgImage', 'DlgExport', 'Stage', 'StageHint']),
    );
    const unit = PascalUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: el rasterizador, los componentes, el prototipo y exportar', () {
    expect(e.code, isNot(contains('@TEXTS')));
    expect(e.code, contains("tx_LAYERS = 'Capas';"));
    for (final s in [
      'procedure AccLine(',
      'procedure BlurCov(',
      'function NodeToLine(',
      'procedure Relayout(',
      'procedure DrawInstance(',
      'function CssOf(',
      'function FlutterOf(',
      'function SvgOf(',
      'TFPWriterPNG',
      'procedure StartPlay',
      'DMS_OPEND_SELFTEST',
      'DMS_OPEND_SHOT',
    ]) {
      expect(e.code, contains(s), reason: s);
    }
    final used = RegExp(r'\btx_([A-Z_0-9]+)').allMatches(e.code).map((m) => m[1]);
    for (final k in used.toSet()) {
      expect(e.code, contains('  tx_$k = '), reason: k);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkPascalExamples(en).firstWhere((e) => e.seed == 'pascal_opend');
    expect(x.name, 'OpenD++ (Pascal)');
    expect(x.code, contains("tx_LAYERS = 'Layers';"));
    String tail(String c) => c.substring(c.indexOf('// ---- fin de los textos'));
    expect(tail(x.code), tail(e.code));
  });

  test(
    'de verdad: compila con Lazarus y pasan sus pruebas internas',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final keep = Platform.environment['DMS_OPEND_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_opend_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_OPEND_SELFTEST': '1'},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
