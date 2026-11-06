// Exporta las demos descargables de la landing (dmarlonstudio.com/demos):
// los ejemplos del estudio en español y en inglés, cada uno como el proyecto
// que daría «Exportar» (app.py), listos para que scripts/build_demos.py los
// compile con PyInstaller para macOS y Windows.
//
//   DMS_DEMOS_OUT=/ruta flutter test test/demos_export_test.dart
//
// Sin DMS_DEMOS_OUT solo comprueba que se generan.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:dmarlon_studio/i18n/tr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Las demos: diez utilidades (tkinter). Deben coincidir con
/// landing/lib/demos.ts.
const demos = [
  'calculator',
  'notepad',
  'pdf_editor',
  'disk_usage',
  'port_scanner',
  'investor',
  'pos',
  'agenda',
  'currency',
  'file_renamer',
];

void main() {
  final out = Platform.environment['DMS_DEMOS_OUT'];
  for (final lang in ['es', 'en']) {
    test('las demos en $lang', () async {
      setCatalog(
        lang == 'es'
            ? {}
            : catalogOf(File('assets/i18n/$lang.po').readAsStringSync()),
      );
      final all = tkExamples(tr);
      for (final seed in demos) {
        final e = all.firstWhere((x) => x.seed == seed);
        expect(e.design.isPython && !e.design.isWeb, isTrue, reason: seed);
        final files = {'app.py': TkCodegen.generate(e.design, e.code)};
        if (out == null) continue;
        final dir = Directory(p.join(out, lang, seed));
        if (dir.existsSync()) await dir.delete(recursive: true);
        for (final f in files.entries) {
          final file = File(p.join(dir.path, f.key));
          await file.parent.create(recursive: true);
          await file.writeAsString(f.value);
        }
        await File(p.join(dir.path, 'demo.json')).writeAsString(
          jsonEncode({
            'seed': seed,
            'lang': lang,
            'name': e.name,
          }),
        );
      }
      setCatalog({});
    });
  }
}
