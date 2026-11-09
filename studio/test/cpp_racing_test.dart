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
  return exe;
}

bool get _canBuild =>
    TkCppTools.compiler() != null && TkCppTools.fltkConfig() != null;

void main() {
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_racing');

  test('diseño: C++, sin problemas, con el menú, el reloj y la pista', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    expect(d.prop(tkFormResizable), isTrue);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(names, containsAll(['Menu1', 'Tick', 'Track', 'TrackHint']));
    final tick = d.widgets.firstWhere((w) => w.name == 'Tick');
    expect(tick.props['interval'], 16);
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: todo se dibuja, sin imágenes, y guarda los ajustes', () {
    final files = TkCpp.files(e.design, e.code);
    final code = files['Form1.cpp']!;
    for (final s in [
      'fl_begin_complex_polygon',
      'Fl_Image_Surface',
      'fl_write_png',
      'DMS_RACING_SELFTEST',
      'DMS_RACING_SHOT',
      'settings.txt',
      'Application Support',
      'APPDATA',
      'fullscreen()',
    ]) {
      expect(code, contains(s), reason: s);
    }
    // No carga ninguna imagen (las capturas sí se escriben en PNG).
    for (final s in [
      'Fl_Shared_Image::get',
      'new Fl_PNG_Image',
      'new Fl_JPEG_Image',
      'load(',
    ]) {
      expect(code, isNot(contains(s)), reason: s);
    }
    expect(files['design.h'], contains('Tick.interval(0.016)'));
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_racing');
    expect(x.name, 'Motorbike Racing (C++)');
    expect(x.code, contains('const char* const APP = "Motorbike Racing";'));
    expect(x.code, contains('"Game/New race"'));
    expect(
      x.design.widgets.firstWhere((w) => w.name == 'Menu1').text('items'),
      contains('Difficulty'),
    );
    expect(
      x.code.substring(x.code.indexOf('namespace rc')),
      e.code.substring(e.code.indexOf('namespace rc')),
    );
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_RACING_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_racing_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      // La pista, una carrera entera con todos pilotando solos y la física
      // del jugador, sin ventana.
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_RACING_SELFTEST': '1'},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
      // Con la ventana abierta solo si se pide (abre una ventana unos segundos).
      if (Platform.environment['DMS_RACING_SMOKE_TEST'] == '1') {
        final s = await Process.run(
          exe,
          const [],
          environment: {
            'DMS_RACING_SMOKE': '1',
            'DMS_RACING_CONFIG': p.join(tmp.path, 'config'),
          },
        ).timeout(const Duration(minutes: 1));
        expect(s.exitCode, 0, reason: '${s.stdout}${s.stderr}');
        expect('${s.stdout}', contains('smoke ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
