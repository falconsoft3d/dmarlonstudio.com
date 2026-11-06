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
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_web_html.dart';
import 'package:dmarlon_studio/code/tk_web_react.dart';
import 'package:dmarlon_studio/code/tk_web_vue.dart';
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
  'mp3_player',
  'train_monitor',
];

/// Las demos que se prueban en el navegador (scripts/build_live_demos.py)
/// y, las móviles, también como APK de Android (en GitHub Actions): semilla
/// y cómo se compila. Deben coincidir con landing/lib/demos.ts.
const liveDemos = <(String, String)>[
  ('flutter_store', 'flutter'),
  ('flutter_shipping', 'flutter'),
  ('flutter_todo', 'flutter'),
  ('html_store', 'html'),
  ('react_store', 'react'),
  ('vue_store', 'vue'),
];

/// Los archivos del proyecto de una demo en vivo.
Map<String, String> liveFiles(TkExample e, String kind) => switch (kind) {
  'flutter' => TkFlutter.files(e.design, e.code, name: 'dms_${e.seed}'),
  'html' => TkWebHtml.files(e.design, e.code, name: e.name),
  'react' => TkWebReact.files(e.design, e.code, name: e.name),
  _ => TkWebVue.files(e.design, e.code, name: e.name),
};

void main() {
  final live = Platform.environment['DMS_LIVE_OUT'];
  for (final lang in ['es', 'en']) {
    test('las demos en vivo en $lang', () async {
      setCatalog(
        lang == 'es'
            ? {}
            : catalogOf(File('assets/i18n/$lang.po').readAsStringSync()),
      );
      final all = tkFlutterExamples(tr);
      for (final (seed, kind) in liveDemos) {
        final e = all.firstWhere((x) => x.seed == seed);
        final files = liveFiles(e, kind);
        expect(files, isNotEmpty, reason: seed);
        if (live == null) continue;
        final dir = Directory(p.join(live, lang, seed));
        if (dir.existsSync()) await dir.delete(recursive: true);
        for (final f in files.entries) {
          final file = File(p.join(dir.path, f.key));
          await file.parent.create(recursive: true);
          await file.writeAsString(f.value);
        }
        await File(p.join(dir.path, 'demo.json')).writeAsString(
          jsonEncode({'seed': seed, 'kind': kind, 'lang': lang, 'name': e.name}),
        );
      }
      setCatalog({});
    });
  }
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
