import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

TkWidget _w(
  String kind,
  String name,
  int x,
  int y,
  int width,
  int height, {
  Map<String, Object?> props = const {},
  Map<String, String> events = const {},
}) => TkWidget(
  kind: kind,
  name: name,
  x: x,
  y: y,
  width: width,
  height: height,
  props: {...props},
  events: {...events},
);

const _ribbonItems = '''Inicio
  Portapapeles
    Pegar | paste
    Copiar | copy
  Fuente
    Negrita | bold
Insertar
  Tablas
    Tabla | table
    Raro | ❖''';

TkDesign design({bool web = false}) =>
    TkDesign(
        width: 480,
        height: 320,
        target: web ? tkTargetWeb : tkTargetDesktop,
      )
      ..widgets.addAll([
        _w(
          'Ribbon',
          'Ribbon1',
          0,
          0,
          480,
          92,
          props: {'items': _ribbonItems, 'active': 1},
          events: {'command': 'Ribbon1_click', 'change': 'Ribbon1_change'},
        ),
        _w(
          'RestClient',
          'Api1',
          440,
          100,
          32,
          32,
          props: {
            'base_url': 'http://127.0.0.1:{{port}}/api',
            'auth': 'bearer',
            'token_env': 'API_TOKEN',
            'headers': 'X-Trace: {{trace}}',
            'timeout': 5,
          },
          events: {'done': 'Api1_done', 'error': 'Api1_error'},
        ),
        _w(
          'TrayIcon',
          'Tray1',
          440,
          140,
          32,
          32,
          props: {'tooltip': 'Notas', 'items': 'Abrir\n-\nSalir'},
          events: {'click': 'Tray1_click', 'command': 'Tray1_menu'},
        ),
        _w(
          'StatusBar',
          'Status',
          0,
          296,
          480,
          24,
          props: {'text': 'Listo', 'icon': 'check'},
        ),
      ]);

const unit = '''class Form1(FormDesign):
    def Ribbon1_click(self, item):
        self.Status.set(item, icon="info")

    def Api1_done(self, result):
        pass
''';

Future<void> compiles(Directory tmp, String name, String src) async {
  final f = File(p.join(tmp.path, '$name.py'));
  await f.writeAsString(src);
  final r = await Process.run('python3', ['-m', 'py_compile', f.path]);
  expect(r.exitCode, 0, reason: '$name: ${r.stderr}');
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_components2_');
  });

  tearDown(() => tmp.delete(recursive: true));

  test('la cinta se lee en pestañas, grupos y botones con su icono', () {
    final tabs = tkRibbonTabs(_ribbonItems);
    expect(tabs.map((t) => t.label), ['Inicio', 'Insertar']);
    expect(tabs.first.groups.map((g) => g.label), ['Portapapeles', 'Fuente']);
    final paste = tabs.first.groups.first.buttons.first;
    expect(paste.label, 'Pegar');
    expect(paste.glyph, tkRibbonGlyphs['paste']);
    expect(paste.path, 'Inicio/Portapapeles/Pegar');
    expect(tabs.last.groups.first.buttons.last.glyph, '❖');
    expect(tkRibbonPaths(tabs), hasLength(5));
    final d = design();
    expect(d.ribbonTab(d.byName('Ribbon1')!), 1);
    d.widgets.add(_w('Ribbon', 'Ribbon2', 0, 0, 10, 92));
    expect(d.problems(), contains(contains('Ribbon2')));
  });

  test('ventanas nuevas centradas; las guardadas siguen igual', () {
    expect(TkDesign().prop(tkFormPosition), 'center');
    expect(
      TkDesign.fromJson({'name': 'Form1'}).prop(tkFormPosition),
      'default',
    );
  });

  test('tkinter: cinta, API, bandeja, barra de estado y posición', () async {
    final src = TkCodegen.generate(design(), unit);
    expect(src, contains('class DesignRibbon(tk.Frame)'));
    expect(src, contains('self.Ribbon1 = DesignRibbon('));
    expect(src, contains('"path": "Inicio/Portapapeles/Pegar"'));
    expect(src, contains('active=1'));
    expect(src, contains('command=self.Ribbon1_click'));
    expect(
      src,
      contains('self.Ribbon1.place(x=0, y=0, relwidth=1.0, height=92)'),
    );
    expect(src, contains('class ApiClient'));
    expect(src, contains('token_env="API_TOKEN"'));
    final call = src.substring(src.indexOf('self.Api1 = ApiClient('));
    expect(call.substring(0, call.indexOf(')')), isNot(contains(' token=')));
    expect(src, contains('done=self.Api1_done'));
    expect(src, contains('class DesignTray'));
    expect(src, contains('self.Tray1 = DesignTray('));
    expect(src, contains('class DesignStatus(tk.Label)'));
    expect(src, contains('icon="${tkRibbonGlyphs['check']}"'));
    expect(src, contains('winfo_screenwidth()'));
    await compiles(tmp, 'desktop', src);
  });

  test('web: los mismos componentes generan Python válido', () async {
    final src = TkCodegen.generate(design(web: true), unit);
    expect(src, contains('"Ribbon",'));
    expect(src, contains('"tabs": [{"label": "Inicio"'));
    expect(src, contains('class ApiClient'));
    expect(src, contains('self.Tray1 = WebNoTray()'));
    expect(src, contains('GLYPHS = {'));
    await compiles(tmp, 'web', src);
  });

  test('de verdad: tkinter y Flask con API local, diálogos e imagen', () async {
    final project = Directory(p.join(tmp.path, 'proyecto'));
    await Directory(p.join(project.path, 'images')).create(recursive: true);
    await File(
      p.join(project.path, 'images', 'dot.png'),
    ).writeAsBytes(base64Decode(_png));
    await File(p.join(project.path, 'project.json')).writeAsString('{}');
    final desktop = TkCodegen.generate(full(), fullUnit);
    final web = TkCodegen.generate(full(web: true), fullUnit);
    await compiles(tmp, 'full_desktop', desktop);
    await compiles(tmp, 'full_web', web);

    final tk = await _python('import tkinter; tkinter.Tk().destroy()');
    if (tk != null) {
      final r = await Process.run(tk, [
        '-c',
        _desktopHarness,
        p.join(tmp.path, 'full_desktop.py'),
        project.path,
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      expect(out['tab'], 1);
      expect(out['status'], 'Inicio/Fuente/Negrita');
      expect(out['icon'], tkRibbonGlyphs['info']);
      expect(out['log'], ['Inicio/Fuente/Negrita', 'change']);
      expect(out['auth'], 'Bearer tok');
      expect(out['trace'], 't1');
      expect(out['path'], '/api/users');
      expect(out['missing'], 404);
      expect(out['async'], 'api Bearer tok');
      expect(out['password'], 'abcd');
      expect(out['shown'], '');
      expect(out['image'], isTrue);
      expect('${out['saved']}', endsWith('out.txt'));
      expect(out['read'], [out['saved'], 'hola']);
      expect(out['selected'], out['saved']);
      // Sin pystray avisa y la ventana sigue.
      if ('${r.stdout}'.contains('pystray')) expect(out['tray'], isFalse);
      expect('${out['geometry']}', contains('+'));
    }

    final flask = await _python('import flask');
    if (flask != null) {
      final r = await Process.run(flask, [
        '-c',
        _webHarness,
        p.join(tmp.path, 'full_web.py'),
        project.path,
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      expect(out['ribbon'], isTrue);
      expect(out['password'], isTrue);
      expect(out['img'], isTrue);
      expect(out['image_ok'], 200);
      expect(out['image_out'], 404);
      expect(out['status_html'], isTrue);
      expect(out['download'], ['file.txt']);
      expect(out['bad'], isEmpty);
      expect(out['api'], 'Bearer tok');
    }
  });

  test('la imagen elegida se copia a images/ y se reutiliza', () async {
    // La lógica de copia está en el inspector: aquí, la ruta que genera.
    final d = full();
    final src = TkCodegen.generate(d, fullUnit);
    expect(src, contains('def _project_file(path):'));
    expect(src, contains('file="images/dot.png"'));
    expect(src, contains('def Img1_load(self, path):'));
    expect(src, contains('def Pass1_visible(self, on=True):'));
    expect(src, contains('class DesignSaveDialog(_DesignDialog)'));
  });
}

/// Un Python de este equipo que ejecuta [check] sin error (null: ninguno).
Future<String?> _python(String check) async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
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

/// Ventana con todo lo nuevo para ejecutarla de verdad.
TkDesign full({bool web = false}) => design(web: web)
  ..widgets.addAll([
    _w(
      'Password',
      'Pass1',
      16,
      100,
      160,
      24,
      props: {'maxlength': 4, 'hint': 'Clave'},
    ),
    _w(
      'Image',
      'Img1',
      16,
      140,
      64,
      64,
      props: {'file': 'images/dot.png', 'fit': 'stretch'},
    ),
    _w(
      'OpenDialog',
      'Open1',
      400,
      100,
      32,
      32,
      props: {'filter': 'Texto|*.txt'},
      events: {'select': 'Open1_select'},
    ),
    _w(
      'SaveDialog',
      'Save1',
      400,
      140,
      32,
      32,
      props: {'defaultext': 'txt', 'filter': 'Texto|*.txt'},
    ),
  ]);

const fullUnit = r"""class Form1(FormDesign):
    def __init__(self):
        self.log = []

    def Ribbon1_click(self, item):
        self.log.append(item)
        self.Status.set(item, icon="info")
        if item.endswith("Tabla"):
            self.Save1.write_text("hola")

    def Ribbon1_change(self):
        self.log.append("change")

    def Api1_done(self, result):
        self.log.append(("done", result))
        self.Status.set("api %s" % result[0]["auth"])

    def Api1_error(self, error):
        self.log.append(("error", error.status))

    def Open1_select(self, path):
        self.log.append(("select", path))
""";

/// Un PNG de 1×1.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// Servidor HTTP de pruebas: responde con lo que recibió.
const _server = r"""
import json, os, threading
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path.endswith("/missing"):
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"no")
            return
        body = json.dumps([{"id": 1, "path": self.path,
                            "auth": self.headers.get("Authorization"),
                            "trace": self.headers.get("X-Trace")}]).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

server = HTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
os.environ["DMSTUDIO_ENV_PORT"] = str(server.server_port)
os.environ["DMSTUDIO_ENV_TRACE"] = "t1"
os.environ["API_TOKEN"] = "tok"
""";

const _desktopHarness =
    _server +
    r"""
import importlib.util, sys, tkinter.filedialog as fd
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
f = m.Form1()
f.root.withdraw()
f.root.update()
out = {}
out["tab"] = f.Ribbon1.select()
f.Ribbon1.command("Inicio/Fuente/Negrita")
out["status"] = f.Status.cget("text")
out["icon"] = f.Status.cget("icon")
f.Ribbon1._pick(0)
out["log"] = list(f.log)
users = f.Api1.get("users")
out["auth"] = users[0]["auth"]
out["trace"] = users[0]["trace"]
out["path"] = users[0]["path"]
try:
    f.Api1.get("missing")
except m.ApiError as error:
    out["missing"] = error.status
f.Api1.get_async("users")
for _ in range(200):
    f.root.update()
    if any(isinstance(x, tuple) and x[0] == "done" for x in f.log):
        break
    import time; time.sleep(0.01)
out["async"] = f.Status.cget("text")
f.Pass1_var.set("abcdef")
out["password"] = f.Pass1.get()
f.Pass1_visible(True)
out["shown"] = f.Pass1.entry.cget("show")
out["image"] = f.Img1.photo is not None
saved = os.path.join(sys.argv[2], "out")
fd.asksaveasfilename = lambda **options: saved
out["saved"] = f.Save1.write_text("hola")
fd.askopenfilename = lambda **options: out["saved"]
out["read"] = list(f.Open1.read_text())
out["selected"] = [x for x in f.log if isinstance(x, tuple) and x[0] == "select"][0][1]
out["tray"] = f.Tray1.available
out["geometry"] = f.root.geometry()
print(json.dumps(out))
f.root.destroy()
""";

const _webHarness =
    _server +
    r"""
import importlib.util, re, sys
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
client = m.app.test_client()
page = client.get("/").get_data(as_text=True)
boot = json.loads(re.search(r'id="tk-boot">(.*?)</script>', page).group(1))
headers = {"X-DMS-CSRF": boot["csrf"], "X-DMS-Process": boot["process"]}
def event(**body):
    body["sid"] = boot["sid"]
    return client.post("/event", json=body, headers=headers).get_json()
out = {}
out["ribbon"] = "tk-ribbon" in page and "Inicio/Portapapeles/Pegar" in page
out["password"] = 'type="password"' in page and "tk-eye" in page
out["img"] = 'src="/images/dot.png"' in page
out["image_ok"] = client.get("/images/dot.png").status_code
out["image_out"] = client.get("/images/../project.json").status_code
reply = event(widget="Ribbon1", event="command", data={"item": "Insertar/Tablas/Tabla"})
out["status_html"] = "Insertar/Tablas/Tabla" in json.dumps(reply.get("html", {}))
out["download"] = [d["name"] for d in reply.get("downloads", [])]
bad = event(widget="Ribbon1", event="command", data={"item": "No/Existe"})
out["bad"] = bad.get("html", {})
form = m.Form1()
out["api"] = form.Api1.get("users")[0]["auth"]
print(json.dumps(out))
""";
