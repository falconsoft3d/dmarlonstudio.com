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
    reason: TkPascalTools.messages(
      '${r.stdout}${r.stderr}',
      dir.path,
    ).join('\n'),
  );
  return exe;
}

void main() {
  final e = tkPascalExamples(id).firstWhere((e) => e.seed == 'pascal_travel');

  test('diseño: Pascal, sin problemas, con los campos, el botón y la vista previa', () {
    final d = e.design;
    expect(d.isPascal, isTrue);
    expect(d.problems(), isEmpty);
    for (final w in d.widgets) {
      expect(tkPascalKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(names, containsAll(['Menu1', 'Tick', 'Side', 'Origin', 'Dest', 'Days', 'BtnPlan', 'BtnSave', 'RadImage', 'RadDossier', 'Stage', 'Status']));
    const unit = PascalUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: Claude Code, el plan, la imagen y el PDF', () {
    expect(e.code, isNot(contains('@TEXTS')));
    expect(e.code, contains("tx_K_MUSEUM = 'Museo';"));
    for (final s in [
      "P.Parameters.Add('--json-schema')",
      "'structured_output'",
      'function FindClaude',
      'TPDFDocument',
      'procedure RenderPoster',
      'procedure RenderPage',
      'DMS_TRAVEL_SELFTEST',
      'DMS_TRAVEL_SHOT',
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
    final x = tkPascalExamples(en).firstWhere((e) => e.seed == 'pascal_travel');
    expect(x.name, 'Trip Planner (Pascal)');
    expect(x.code, contains("tx_K_MUSEUM = 'Museum';"));
    String tail(String c) => c.substring(c.indexOf('// ---- fin de los textos'));
    expect(tail(x.code), tail(e.code));
  });

  test(
    'de verdad: compila con Lazarus y pasan sus pruebas internas',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final keep = Platform.environment['DMS_TRAVEL_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_travel_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_TRAVEL_SELFTEST': '1'},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  // DMS_TRAVEL_SHOTS=carpeta: las capturas de la web, en español y en inglés.
  test(
    'capturas',
    () async {
      final out = Platform.environment['DMS_TRAVEL_SHOTS'];
      if (out == null) return markTestSkipped('Sin DMS_TRAVEL_SHOTS.');
      if (TkPascalTools.lazbuild() == null) return markTestSkipped('Sin Lazarus.');
      final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
      for (final (lang, t) in [('es', id), ('en', (String s) => catalog[s] ?? s)]) {
        final x = tkPascalExamples(t).firstWhere((e) => e.seed == 'pascal_travel');
        final tmp = await Directory.systemTemp.createTemp('dms_travel_shots_');
        addTearDown(() => tmp.delete(recursive: true));
        final exe = await build(x, tmp);
        final r = await Process.run(exe, const [], environment: {
          'DMS_TRAVEL_SHOT': p.join(out, lang),
        }).timeout(const Duration(minutes: 2));
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
