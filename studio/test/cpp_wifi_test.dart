// La wifi de casa en C++ (FLTK): el diseño, el código, el inglés y,
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
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_wifi');

  test('diseño: C++, sin problemas, con las secciones y la contraseña', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    expect(d.prop(tkFormResizable), isTrue);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    expect(
      names,
      containsAll([
        'Menu1', 'Tick', 'Side', 'LblNet', 'LblInfo', 'Sections', //
        'BtnScan', 'BtnPassword', 'BtnCopy', 'Results', 'Status',
      ]),
    );
    final items = d.widgets
        .firstWhere((w) => w.name == 'Sections')
        .text('items')
        .split('\n');
    expect(items, [
      'Diagnóstico',
      'Mi red',
      'Redes cercanas',
      'Canales',
      'Contraseña',
      'Router',
    ]);
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
    final menu = d.widgets.firstWhere((w) => w.name == 'Menu1').text('items');
    for (final s in [
      'Comprobar la contraseña…',
      'Analizar cada minuto',
      'Copiar el informe',
      'Redes cercanas',
    ]) {
      expect(menu, contains(s), reason: s);
    }
  });

  test('código: system_profiler, netsh, nmcli, el router y la contraseña', () {
    final code = TkCpp.files(e.design, e.code)['Form1.cpp']!;
    for (final s in [
      'system_profiler SPAirPortDataType -json',
      'netsh wlan show interfaces',
      'netsh wlan show networks mode=bssid',
      'nmcli -t -f',
      'void from_mac(',
      'void from_netsh(',
      'bool tcp_open(',
      'bool upnp_answers(',
      'PassCheck check_password(',
      'std::vector<Finding> diagnose(',
      'int best_channel(',
      'DMS_WIFI_SELFTEST',
      'DMS_WIFI_SHOT',
      'DMS_WIFI_UITEST',
      'fl_password(',
    ]) {
      expect(code, contains(s), reason: s);
    }
    // La contraseña no se guarda: las preferencias solo llevan «auto».
    expect(code, contains('std::string("auto=")'));
    final used = RegExp(r'tx::([A-Z_0-9]+)').allMatches(code).map((m) => m[1]);
    for (final k in used.toSet()) {
      expect(code, contains('const char* const $k ='), reason: k);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_wifi');
    expect(x.name, 'Home Wi-Fi (C++)');
    expect(x.code, contains('const char* const APP = "Home Wi-Fi";'));
    expect(x.code, contains('const char* const DEC = ".";'));
    expect(
      x.code.substring(x.code.indexOf('namespace wf')),
      e.code.substring(e.code.indexOf('namespace wf')),
    );
    final tx = x.code.substring(
      x.code.indexOf('namespace tx'),
      x.code.indexOf('}  // namespace tx'),
    );
    for (final s in ['ñ', 'á', 'é', 'í', 'ó', 'ú', '¿']) {
      final bad = tx.split('\n').where((l) => l.contains(s));
      expect(bad, isEmpty, reason: s);
    }
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final keep = Platform.environment['DMS_WIFI_DUMP'];
      final tmp = keep != null
          ? (Directory(keep)..createSync(recursive: true))
          : await Directory.systemTemp.createTemp('dms_wifi_');
      if (keep == null) addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      final config = p.join(tmp.path, 'config');
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_WIFI_SELFTEST': '1', 'DMS_WIFI_CONFIG': config},
      ).timeout(const Duration(minutes: 2));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
      // La interfaz sin ventana: cada sección, la contraseña y el texto
      // (necesita la pantalla: solo en macOS, sin abrir nada).
      if (Platform.isMacOS) {
        final u = await Process.run(
          exe,
          const [],
          environment: {'DMS_WIFI_UITEST': '1', 'DMS_WIFI_CONFIG': config},
        ).timeout(const Duration(minutes: 2));
        expect(u.exitCode, 0, reason: '${u.stdout}${u.stderr}');
        expect('${u.stdout}', contains('uitest ok'));
      }
      // Con la ventana abierta solo si se pide (abre una ventana unos segundos).
      if (Platform.environment['DMS_WIFI_SMOKE_TEST'] == '1') {
        final s = await Process.run(
          exe,
          const [],
          environment: {'DMS_WIFI_SMOKE': '1', 'DMS_WIFI_CONFIG': config},
        ).timeout(const Duration(minutes: 1));
        expect(s.exitCode, 0, reason: '${s.stdout}${s.stderr}');
        expect('${s.stdout}', contains('smoke ok'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
