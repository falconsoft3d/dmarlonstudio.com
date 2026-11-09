// El editor de imágenes en C++ (FLTK): el diseño, el código, el inglés y,
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
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_image_editor');

  test('diseño: C++, sin problemas, con el menú, el reloj y el área', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    expect(d.prop(tkFormResizable), isTrue);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(names, containsAll(['Menu1', 'Tick', 'Workspace', 'WorkspaceHint']));
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
    final items = d.widgets.firstWhere((w) => w.name == 'Menu1').text('items');
    for (final s in ['Archivo', 'Capa', 'Filtro', 'Niveles…', 'Recortar']) {
      expect(items, contains(s), reason: s);
    }
  });

  test('código: capas, historial, filtros y los formatos', () {
    final code = TkCpp.files(e.design, e.code)['Form1.cpp']!;
    for (final s in [
      'struct Layer',
      'struct History',
      'void composite(',
      'B_MULTIPLY',
      'Img resample(',
      'void rotate_any(',
      'void crop_doc(',
      'void levels(',
      'void hue_sat(',
      'void gaussian(',
      'int flood_fill(',
      'namespace jpeg',
      'std::string bmp_bytes(',
      'std::string dmi_bytes(',
      'fl_write_png',
      'Fl_Shared_Image::get',
      'Fl_Native_File_Chooser',
      'Fl_Copy_Surface',
      'DMS_IMAGE_SELFTEST',
      'DMS_IMAGE_SHOT',
      'DMS_IMAGE_UITEST',
      'fullscreen()',
    ]) {
      expect(code, contains(s), reason: s);
    }
    // Cada texto que usa el código está en namespace tx.
    final used = RegExp(r'tx::([A-Z_0-9]+)').allMatches(code).map((m) => m[1]);
    for (final k in used.toSet()) {
      expect(code, contains('const char* const $k ='), reason: k);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_image_editor');
    expect(x.name, 'Image Editor (C++)');
    expect(x.code, contains('const char* const APP = "Image Editor";'));
    expect(x.code, contains('"Layer/New layer"'));
    expect(x.code, contains('const char* const T_HAND = "Hand";'));
    expect(x.code, contains('const char* const DEC = ".";'));
    expect(
      x.code.substring(x.code.indexOf('namespace ie')),
      e.code.substring(e.code.indexOf('namespace ie')),
    );
    // Ningún texto se queda en español.
    final tx = x.code.substring(
      x.code.indexOf('namespace tx'),
      x.code.indexOf('}  // namespace tx'),
    );
    for (final s in ['ñ', 'á', 'é', 'í', 'ó', 'ú', '¿']) {
      final bad = tx
          .split('\n')
          .where((l) => l.contains(s) && !l.contains('Malecón'));
      expect(bad, isEmpty, reason: s);
    }
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_IMAGE_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_image_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_IMAGE_SELFTEST': '1', 'TMPDIR': tmp.path},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
      // La interfaz sin ventana: cada herramienta, orden y diálogo, y un clic
      // en cada zona (necesita la pantalla: solo en macOS, sin abrir nada).
      if (Platform.isMacOS) {
        final u = await Process.run(
          exe,
          const [],
          environment: {'DMS_IMAGE_UITEST': '1'},
        ).timeout(const Duration(minutes: 2));
        expect(u.exitCode, 0, reason: '${u.stdout}${u.stderr}');
        expect('${u.stdout}', contains('uitest ok'));
      }
      // Con la ventana abierta solo si se pide (abre una ventana unos segundos).
      if (Platform.environment['DMS_IMAGE_SMOKE_TEST'] == '1') {
        final s = await Process.run(
          exe,
          const [],
          environment: {'DMS_IMAGE_SMOKE': '1'},
        ).timeout(const Duration(minutes: 1));
        expect(s.exitCode, 0, reason: '${s.stdout}${s.stderr}');
        expect('${s.stdout}', contains('smoke ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
