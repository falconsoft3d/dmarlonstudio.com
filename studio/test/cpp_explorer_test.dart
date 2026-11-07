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

/// Compila el ejemplo con FLTK en [dir] y devuelve el ejecutable.
Future<String> build(TkExample e, Directory dir) async {
  for (final f in TkCpp.files(e.design, e.code).entries) {
    File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
  }
  final (cflags, ldflags) = await TkCppTools.flags();
  final exe = p.join(dir.path, Platform.isWindows ? 'app.exe' : 'app');
  final r = await Process.run(TkCppTools.compiler()!, [
    '-std=c++17',
    '-O1',
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
  final e = tkCppExamples(id).firstWhere((e) => e.seed == 'cpp_explorer');

  test('diseño: C++, sin problemas y con lo que usa el código', () {
    final d = e.design;
    expect(d.isCpp, isTrue);
    expect(d.problems(), isEmpty);
    expect(d.prop(tkFormResizable), isTrue);
    for (final w in d.widgets) {
      expect(tkCppKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    for (final n in [
      'Menu1',
      'Watch',
      'NavBar',
      'Back',
      'Forward',
      'Address',
      'Search',
      'CommandBar',
      'Folders',
      'Paste',
      'ViewDetails',
      'BookmarkBar',
      'TabBar',
      'TreeHost',
      'ViewHost',
      'DetailsPane',
      'DetailName',
      'Status',
    ]) {
      expect(names, contains(n));
    }
    // Cada evento del diseño es un método de Form1 (con override) que el
    // estudio sabe encontrar.
    const unit = CppUnit();
    for (final m in TkCpp.handlers(d).keys) {
      if (m == 'form_create' || m == 'form_close') continue;
      expect(e.code, contains('void $m('), reason: m);
      expect(unit.lineOf(e.code, m), isNotNull, reason: m);
    }
    expect(unit.hasClass(e.code, 'Form1'), isTrue);
  });

  test('código: sistema de archivos, Papelera, portapapeles y temas', () {
    final files = TkCpp.files(e.design, e.code);
    final code = files['Form1.cpp']!;
    for (final s in [
      'std::filesystem',
      'recursive_directory_iterator',
      'std::thread',
      // Papelera: siempre preguntando antes.
      'trashItemAtURL',
      'SHFileOperationW',
      'FOF_ALLOWUNDO',
      'FOF_WANTNUKEWARNING',
      'tx::DEL_ONE',
      // Abrir con el sistema.
      'ShellExecuteW',
      '"open"',
      // El portapapeles de archivos del sistema (entre ventanas y con el
      // Finder o el Explorador de Windows).
      'NSPasteboard',
      'public.file-url',
      'CF_HDROP',
      'Preferred DropEffect',
      'DROPEFFECT_MOVE',
      // Temas claro y oscuro, y el del sistema.
      'AppleInterfaceStyle',
      'AppsUseLightTheme',
      'NSAppearanceNameDarkAqua',
      // El logotipo, dibujado en código.
      'Fl_Image_Surface',
      'setApplicationIconImage',
      'default_icon',
      // Marcadores guardados en la carpeta de configuración.
      'bookmarks.tsv',
      'Application Support',
      'APPDATA',
    ]) {
      expect(code, contains(s), reason: s);
    }
    // Los separadores del menú del diseño llegan a FLTK.
    expect(files['dms.h'], contains('FL_MENU_DIVIDER'));
    expect(files['design.h'], contains('Menu1->item("Ver/-");'));
    // Ninguna ruta de un archivo de imagen: los iconos se dibujan.
    expect(code, isNot(contains('.png"')));
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkCppExamples(en).firstWhere((e) => e.seed == 'cpp_explorer');
    expect(x.name, 'File Explorer (C++)');
    expect(x.code, contains('const char* const APP = "File Explorer";'));
    expect(x.code, contains('"Computer"'));
    expect(x.code, contains('"Actions/Back"'));
    expect(
      x.design.widgets.firstWhere((w) => w.name == 'Menu1').text('items'),
      contains('Bookmarks'),
    );
    // Lo que no son textos no cambia.
    expect(
      x.code.substring(x.code.indexOf('namespace fs')),
      e.code.substring(e.code.indexOf('namespace fs')),
    );
  });

  test(
    'de verdad: compila con FLTK y pasan sus pruebas internas',
    () async {
      if (!_canBuild) return markTestSkipped('Sin compilador de C++ o FLTK.');
      final tmp = await Directory.systemTemp.createTemp('dms_explorer_');
      addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(e, tmp);
      // Ordenar, filtrar, nombres nuevos, copiar, mover y borrar en otro
      // hilo, marcadores y el tamaño en segundo plano, con el código de la app.
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_EXPLORER_SELFTEST': p.join(tmp.path, 'prueba')},
      ).timeout(const Duration(minutes: 1));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      expect('${r.stdout}', isNot(contains('FAIL')));
      // Con la ventana abierta (macOS y Windows): vistas, pestañas, Equipo,
      // ocultos y los tres temas.
      if (Platform.isMacOS || Platform.isWindows) {
        final dir = Directory(p.join(tmp.path, 'carpeta'))..createSync();
        for (final n in ['a.txt', 'b.pdf', 'c.jpg']) {
          File(p.join(dir.path, n)).writeAsStringSync(n);
        }
        final s = await Process.run(
          exe,
          const [],
          environment: {
            'DMS_EXPLORER_SMOKE': '1',
            'DMS_EXPLORER_START': dir.path,
            'DMS_EXPLORER_CONFIG': p.join(tmp.path, 'config'),
          },
        ).timeout(const Duration(minutes: 1));
        expect(s.exitCode, 0, reason: '${s.stdout}${s.stderr}');
        expect('${s.stdout}', contains('smoke ok items=3 tabs=2'));
        expect('${s.stdout}', contains('themes=1'));
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
