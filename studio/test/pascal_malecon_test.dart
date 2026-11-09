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
  final e = tkPascalExamples(id).firstWhere((e) => e.seed == 'pascal_malecon');

  test(
    'diseño: Pascal, sin problemas, con el menú, el reloj y la pantalla',
    () {
      final d = e.design;
      expect(d.isPascal, isTrue);
      expect(d.problems(), isEmpty);
      for (final w in d.widgets) {
        expect(tkPascalKinds, contains(w.kind), reason: w.name);
      }
      final names = {for (final w in d.widgets) w.name};
      expect(names, containsAll(['Menu1', 'Tick', 'Stage', 'StageHint']));
      expect(d.events['key'], 'form_key');
      const unit = PascalUnit();
      for (final m in TkCpp.handlers(d).keys) {
        if (m == 'form_create' || m == 'form_close') continue;
        expect(unit.lineOf(e.code, m), isNotNull, reason: m);
      }
      expect(unit.hasClass(e.code, 'Form1'), isTrue);
    },
  );

  test('código: textos en su sitio, pixel art en código, sin imágenes', () {
    expect(e.code, isNot(contains('@TEXTS')));
    expect(e.code, contains("tx_LOC_MALECON = 'Malecón';"));
    for (final s in [
      'Init_BPP32_B8G8R8A8_BIO_TTB',
      'fqNonAntialiased',
      'TFPWriterPNG',
      'DMS_MALECON_SELFTEST',
      'DMS_MALECON_SHOT',
    ]) {
      expect(e.code, contains(s), reason: s);
    }
    // No carga ninguna imagen (las capturas sí se escriben en PNG).
    for (final s in ['LoadFromFile', 'TPortableNetworkGraphic', 'TJPEGImage']) {
      expect(e.code, isNot(contains(s)), reason: s);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkPascalExamples(
      en,
    ).firstWhere((e) => e.seed == 'pascal_malecon');
    expect(x.name, 'Under the Shadow of the Malecón (Pascal)');
    expect(x.code, contains("tx_B_TALK = 'TALK';"));
    String tail(String c) =>
        c.substring(c.indexOf('// ---- fin de los textos'));
    expect(tail(x.code), tail(e.code));
  });

  test(
    'de verdad: compila con Lazarus y pasan sus pruebas internas',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final keep = Platform.environment['DMS_MALECON_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_malecon_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_MALECON_SELFTEST': '1'},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
