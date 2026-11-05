import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/core/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

TkWidget _w(
  String kind,
  String name,
  int x,
  int y,
  int width,
  int height, {
  String? parent,
  int? page,
  Map<String, Object?> props = const {},
  Map<String, String> events = const {},
}) => TkWidget(
  kind: kind,
  name: name,
  x: x,
  y: y,
  width: width,
  height: height,
  parent: parent,
  page: page,
  props: {...props},
  events: {...events},
);

/// Una ventana con los componentes nuevos.
TkDesign _design({bool web = false}) =>
    TkDesign(
        width: 400,
        height: 300,
        target: web ? tkTargetWeb : tkTargetDesktop,
      )
      ..widgets.addAll([
        _w(
          'Menu',
          'Menu1',
          360,
          8,
          32,
          32,
          props: {'items': 'Archivo\n  Abrir\n  -\n  Salir\nAyuda'},
          events: {'command': 'Menu1_click'},
        ),
        _w(
          'Timer',
          'Timer1',
          360,
          48,
          32,
          32,
          props: {'interval': 250, 'enabled': false},
          events: {'command': 'Timer1_timer'},
        ),
        _w(
          'Progressbar',
          'Progress1',
          8,
          8,
          200,
          20,
          props: {'value': 30, 'maximum': 60},
        ),
        _w(
          'PageControl',
          'Pages',
          8,
          40,
          300,
          200,
          props: {'pages': 'Uno\nDos', 'active': 1},
          events: {'change': 'Pages_change'},
        ),
        _w(
          'Button',
          'Ok',
          16,
          40,
          96,
          32,
          parent: 'Pages',
          page: 1,
          props: {'text': 'OK'},
        ),
        _w('Combobox', 'Kind', 16, 40, 120, 24, parent: 'Pages', page: 0),
        _w(
          'Listbox',
          'Items',
          16,
          72,
          120,
          80,
          parent: 'Pages',
          page: 0,
          props: {'items': 'a\nb'},
          events: {'select': 'Items_select'},
        ),
        _w('StatusBar', 'Status', 0, 276, 400, 24, props: {'text': 'Listo'}),
      ]);

const _unit = '''class Form1(FormDesign):
    def Menu1_click(self, item):
        pass
''';

Future<void> _compiles(Directory tmp, String name, String src) async {
  final f = File(p.join(tmp.path, '$name.py'));
  await f.writeAsString(src);
  final r = await Process.run('python3', ['-m', 'py_compile', f.path]);
  expect(r.exitCode, 0, reason: '$name: ${r.stderr}');
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_components_');
  });

  tearDown(() => tmp.delete(recursive: true));

  test('el menú se lee con sangría, separadores y rutas', () {
    final items = tkMenuItems(
      'Archivo\n  Nuevo\n  -\n  Exportar\n    PDF\n    CSV\nAyuda',
    );
    expect(items.map((i) => i.label), ['Archivo', 'Ayuda']);
    expect(items.first.items.map((i) => i.label), ['Nuevo', '-', 'Exportar']);
    expect(items.first.items[1].separator, isTrue);
    expect(tkMenuPaths(items), [
      'Archivo/Nuevo',
      'Archivo/Exportar/PDF',
      'Archivo/Exportar/CSV',
      'Ayuda',
    ]);
  });

  test('páginas: la de cada componente y lo que se ve', () {
    final d = _design();
    final pages = d.byName('Pages')!;
    expect(tkPages(pages), ['Uno', 'Dos']);
    expect(d.activePage(pages), 1);
    expect(d.shown(d.byName('Ok')!), isTrue);
    expect(d.shown(d.byName('Kind')!), isFalse);
    // Sin página, la activa; al mover dentro, la que se ve.
    final b = _w('Label', 'L', 200, 100, 40, 20);
    d.widgets.add(b);
    d.reparent(b, 'Pages');
    expect(b.page, 1);
    expect(d.pageOf(b), 1);
    // Solo un menú por ventana.
    d.widgets.add(_w('Menu', 'Menu2', 0, 0, 32, 32));
    expect(d.problems(), contains(contains('Menu2')));
  });

  test(
    'tkinter: menú, temporizador, progreso, páginas y barra de estado',
    () async {
      final src = TkCodegen.generate(_design(), _unit);
      expect(src, contains('self.Menu1 = tk.Menu(self.root)'));
      expect(src, contains('add_cascade'));
      expect(src, contains('add_separator()'));
      expect(src, contains('lambda: self.Menu1_click("Archivo/Abrir")'));
      expect(src, contains('self.root.config(menu=self.Menu1)'));
      expect(src, contains('class DesignTimer'));
      expect(
        src,
        contains(
          'self.Timer1 = DesignTimer(self.root, 250, self.Timer1_timer, False)',
        ),
      );
      expect(src, contains('ttk.Progressbar(self.root, value=30, maximum=60)'));
      expect(src, contains('self.Pages = ttk.Notebook(self.root)'));
      expect(src, contains('self.Pages.add(self.Pages_page1, text="Dos")'));
      expect(src, contains('self.Pages.select(1)'));
      expect(src, contains('"<<NotebookTabChanged>>", self.Pages_change'));
      // Debajo de las pestañas, en su página.
      expect(src, contains('ColorButton(\n            self.Pages_page1,'));
      expect(src, contains('self.Ok.place(x=16, y=16,'));
      expect(src, contains('ttk.Combobox(self.Pages_page0'));
      expect(src, contains('relwidth=1.0, height=24'));
      await _compiles(tmp, 'desktop', src);
    },
  );

  test('web: los mismos componentes generan Python válido', () async {
    final src = TkCodegen.generate(_design(web: true), _unit);
    expect(src, contains('class DesignTimer'));
    expect(src, contains('"tree": [{"label": "Archivo"'));
    expect(src, contains('"page": 1'));
    expect(src, contains('(0, 276, 400, 24)'));
    await _compiles(tmp, 'web', src);
  });

  test('un menú dentro de un marco se genera en la ventana', () {
    final d = TkDesign()
      ..widgets.addAll([
        _w('Frame', 'F', 0, 0, 100, 100),
        _w('Menu', 'M', 8, 8, 32, 32, parent: 'F'),
      ]);
    final src = TkCodegen.generate(d, TkUnit.template('Form1', ''));
    expect(src, contains('self.M = tk.Menu(self.root)'));
    expect(() => TkCodegen.generate(d, ''), throwsA(isA<UserError>()));
  });

  test(
    'un __init__ propio sin super(): la ventana ya existe y Al abrir va después',
    () async {
      final d = TkDesign(events: {'create': 'form_create'})
        ..widgets.add(_w('Label', 'Shown', 8, 8, 200, 24));
      const unit = """class Form1(FormDesign):
    def __init__(self):
        self.greeting = "hola"
        self.seen_root = self.root is not None

    def form_create(self):
        self.Shown.configure(text=self.greeting)
        self.created = True
""";
      final desktop = TkCodegen.generate(d, unit);
      expect(desktop, contains('def __new__(cls, *args, **kwargs):'));
      await _compiles(tmp, 'init_desktop', desktop);
      final web = TkCodegen.generate(
        TkDesign.fromJson({...d.toJson(), 'target': tkTargetWeb}),
        unit,
      );
      await _compiles(tmp, 'init_web', web);

      // Con un Python que tenga tkinter (y Flask), se ejecuta de verdad.
      final tk = await _python('import tkinter; tkinter.Tk().destroy()');
      if (tk != null) {
        final r = await Process.run(tk, [
          '-c',
          _harness,
          p.join(tmp.path, 'init_desktop.py'),
        ]);
        expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
        expect('${r.stdout}', contains('hola True True'));
      }
      final flask = await _python('import flask');
      if (flask != null) {
        final r = await Process.run(flask, [
          '-c',
          _webHarness,
          p.join(tmp.path, 'init_web.py'),
        ]);
        expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
        expect('${r.stdout}', contains('<span>hola</span>'));
      }
    },
  );
}

/// Un Python de este equipo que ejecuta [check] sin error (null: ninguno).
Future<String?> _python(String check) async {
  for (final py in const [
    'python3',
    '/opt/homebrew/bin/python3',
    '/usr/local/bin/python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, ['-c', check]);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

/// Crea la ventana sin mostrarla, deja correr el bucle un momento y dice lo
/// que vio el código del usuario.
const _harness = """
import importlib.util, sys
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
f = m.Form1()
f.root.withdraw()
for _ in range(5):
    f.root.update()
print(f.Shown.cget("text"), f.seen_root, getattr(f, "created", False))
f.root.destroy()
""";

const _webHarness = """
import importlib.util, sys
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
page = m.app.test_client().get("/")
print(page.status_code, page.get_data(as_text=True))
""";
