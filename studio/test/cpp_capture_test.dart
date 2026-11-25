// Captura y prompt en C++ (FLTK): el diseño, el código, el inglés y, si hay
// compilador, que compila y pasan sus pruebas internas sin ventana.
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
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_capture');

  test('diseño: C++, sin problemas, con las herramientas, el lienzo y el panel', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(
      names,
      containsAll([
        'Menu1',
        'Tools',
        'BtnArea',
        'BtnWindow',
        'BtnScreen',
        'ToolPen',
        'ToolMark',
        'ToolArrow',
        'ToolBlur',
        'ToolCrop',
        'BtnUndo',
        'BtnRedo',
        'Color1',
        'Size',
        'Board',
        'Side',
        'Prompt',
        'Shots',
        'Comment',
        'BtnAdd',
        'Editable',
        'BtnPdf',
        'BtnPrompt',
        'Status',
      ]),
    );
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test(
    'código: la cámara de macOS, la bandeja y los atajos de Windows, el PDF a mano',
    () {
      final code = TkCpp.files(e.design, e.code)['Form1.cpp']!;
      for (final s in [
        'statusItemWithLength:',
        'camera.fill',
        'objc_allocateClassPair',
        'RegisterEventHotKey',
        'setActivationPolicy:',
        '/usr/sbin/screencapture',
        'Shell_NotifyIconW',
        'RegisterHotKey',
        'WM_HOTKEY',
        'BitBlt',
        'EnumWindows',
        'Fl_Image_Surface',
        'Fl_Copy_Surface',
        'fl_write_png',
        '/Predictor 15',
        '/FT /Tx',
        '/AcroForm',
        '/WinAnsiEncoding',
        'startxref',
        'Fl::wait(1e20)',
        'DMS_CAPTURE_SELFTEST',
        'DMS_CAPTURE_UITEST',
        'DMS_CAPTURE_SHOT',
        'DMS_CAPTURE_CONFIG',
      ]) {
        expect(code, contains(s), reason: s);
      }
      final used = RegExp(
        r'tx::([A-Z_0-9]+)',
      ).allMatches(code).map((m) => m[1]);
      for (final k in used.toSet()) {
        expect(code, contains('const char* const $k ='), reason: k);
      }
    },
  );

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_capture');
    expect(x.name, 'Capture & Prompt (C++)');
    expect(x.code, contains('const char* const APP = "Capture & Prompt";'));
    expect(
      x.code.substring(x.code.indexOf('namespace cp')),
      e.code.substring(e.code.indexOf('namespace cp')),
    );
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_CAPTURE_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_capture_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final config = p.join(tmp.path, 'config');
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_CAPTURE_SELFTEST': '1', 'DMS_CAPTURE_CONFIG': config},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      if (Platform.isMacOS) {
        final u = await Process.run(
          exe,
          const [],
          environment: {
            'DMS_CAPTURE_UITEST': '1',
            'DMS_CAPTURE_CONFIG': p.join(tmp.path, 'config-ui'),
          },
        ).timeout(const Duration(minutes: 2));
        expect(u.exitCode, 0, reason: '${u.stdout}${u.stderr}');
        expect('${u.stdout}', contains('uitest ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  // DMS_CAPTURE_SHOTS=carpeta: las capturas de la web, en español y en inglés
  // (window, session, menu y capturas.pdf en <carpeta>/<idioma>).
  test(
    'capturas',
    () async {
      final out = Platform.environment['DMS_CAPTURE_SHOTS'];
      if (out == null) return markTestSkipped('Sin DMS_CAPTURE_SHOTS.');
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
      for (final (lang, t) in [
        ('es', id),
        ('en', (String s) => catalog[s] ?? s),
      ]) {
        final x = tkCppExamples(t).firstWhere((e) => e.seed == 'cpp_capture');
        final tmp = await Directory.systemTemp.createTemp('dms_capture_shots_');
        addTearDown(() => tmp.delete(recursive: true));
        final exe = await build(x, tmp);
        final r = await Process.run(
          exe,
          const [],
          environment: {
            'DMS_CAPTURE_SHOT': p.join(out, lang),
            'DMS_CAPTURE_CONFIG': p.join(tmp.path, 'config'),
          },
        ).timeout(const Duration(minutes: 2));
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  // La parte de Windows (la bandeja, GDI, RegisterHotKey) no se compila en
  // macOS: con MinGW (brew install mingw-w64) se comprueba que compila.
  test('Windows: compila con MinGW (sin avisos)', () async {
    const gxx = 'x86_64-w64-mingw32-g++';
    final which = await Process.run('which', [gxx]);
    final cfg = TkCppTools.fltkConfig();
    if (which.exitCode != 0 || cfg == null) {
      return markTestSkipped('Sin MinGW o sin FLTK.');
    }
    final inc = (await Process.run(cfg, [
      '--includedir',
    ])).stdout.toString().trim();
    final tmp = await Directory.systemTemp.createTemp('dms_capture_win_');
    addTearDown(() => tmp.delete(recursive: true));
    for (final f in TkCpp.files(e.design, e.code).entries) {
      File(p.join(tmp.path, f.key)).writeAsStringSync(f.value);
    }
    final r = await Process.run(gxx, [
      '-std=c++17',
      '-fsyntax-only',
      '-Wall',
      '-I$inc',
      'main.cpp',
    ], workingDirectory: tmp.path);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      '${r.stderr}',
      isNot(matches(RegExp(r'Form1\.cpp:\d+:\d+: (warning|error)'))),
      reason: '${r.stderr}',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
