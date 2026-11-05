import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample example(String seed) =>
    [...tkExamples(id), ...tkWebExamples(id)].firstWhere((e) => e.seed == seed);

const desktopSeeds = ['notepad', 'agenda', 'currency', 'snake', 'music_player'];
const webSeeds = ['web_crm', 'web_invoicing', 'web_blog', 'web_shop'];

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_showcase_');
  });

  tearDown(() => tmp.delete(recursive: true));

  /// Genera el ejemplo [seed] en una carpeta de proyecto y devuelve el .py.
  Future<String> build(String seed) async {
    final e = example(seed);
    final project = Directory(p.join(tmp.path, seed));
    await project.create(recursive: true);
    final file = File(p.join(project.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('los nueve ejemplos existen, con su destino y nombres únicos', () {
    final all = [...tkExamples(id), ...tkWebExamples(id)];
    expect(all.map((e) => e.seed).toSet().length, all.length);
    for (final s in desktopSeeds) {
      expect(example(s).design.isWeb, isFalse, reason: s);
    }
    for (final s in webSeeds) {
      expect(example(s).design.isWeb, isTrue, reason: s);
    }
    // Funcionan sin conexiones guardadas del estudio.
    for (final s in [...desktopSeeds, ...webSeeds]) {
      expect(example(s).design.connections, isEmpty, reason: s);
      expect(example(s).design.problems(), isEmpty, reason: s);
    }
  });

  test('todos generan Python válido', () async {
    for (final s in [...desktopSeeds, ...webSeeds]) {
      final path = await build(s);
      final r = await Process.run('python3', ['-m', 'py_compile', path]);
      expect(r.exitCode, 0, reason: '$s: ${r.stderr}');
    }
  });

  final scenarios = {
    'notepad': ('', _notepad),
    'agenda': ('', _agenda),
    'currency': (_currencyBefore, _currency),
    'snake': ('', _snake),
    'music_player': (_musicBefore, _music),
  };
  for (final MapEntry(key: seed, value: (before, scenario))
      in scenarios.entries) {
    test('de verdad en tkinter: $seed', () async {
      final py = await _python('import tkinter; tkinter.Tk().destroy()');
      if (py == null) return markTestSkipped('Sin Python con tkinter.');
      final path = await build(seed);
      final r = await Process.run(py, [
        '-c',
        _desktopHarness,
        path,
        p.dirname(path),
        scenario,
        before,
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
    });
  }

  final web = {
    'web_crm': _crm,
    'web_invoicing': _invoicing,
    'web_blog': _blog,
    'web_shop': _shop,
  };
  for (final MapEntry(key: seed, value: scenario) in web.entries) {
    test('de verdad en Flask: $seed', () async {
      final py = await _python('import flask');
      if (py == null) return markTestSkipped('Sin Python con Flask.');
      final path = await build(seed);
      final r = await Process.run(py, [
        '-c',
        _webHarness,
        path,
        p.dirname(path),
        scenario,
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
    });
  }
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

/// Carga el programa generado, crea la ventana oculta, ejecuta el
/// escenario (argv[3]) y escribe `out` en JSON. Los diálogos no bloquean.
const _desktopHarness = r'''
import datetime, importlib.util, json, os, sys, time
import tkinter.filedialog as fd
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
mb.askyesnocancel = lambda *a, **k: False
mb.askyesno = lambda *a, **k: True
mb.showinfo = mb.showerror = mb.showwarning = lambda *a, **k: "ok"
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
def pump(until, seconds=5):
    end = time.time() + seconds
    while time.time() < end:
        f.root.update()
        if until():
            return True
        time.sleep(0.01)
    return False
before = sys.argv[4] if len(sys.argv) > 4 else ""
exec(before)
f = m.Form1()
f.root.withdraw()
exec(sys.argv[5] if len(sys.argv) > 5 else "")
f.root.update()
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
try:
    f.root.destroy()
except Exception:
    pass
''';

const _notepad = r'''
f.Editor.insert("1.0", "hola\nmundo")
f.refresh()
out["check_dirty"] = f.root.title().startswith("* ")
out["check_status"] = "2" in f.Status.cget("text") and "10" in f.Status.cget("text")
saved = os.path.join(os.getcwd(), "nota")
fd.asksaveasfilename = lambda **o: saved
out["check_saved"] = f.save() is True
out["check_file"] = open(saved + ".txt", encoding="utf-8").read() == "hola\nmundo"
out["check_clean"] = not f.root.title().startswith("* ")
f.new()
out["check_new"] = f.text() == ""
fd.askopenfilename = lambda **o: saved + ".txt"
f.open()
out["check_open"] = f.text() == "hola\nmundo" and f.path.endswith("nota.txt")
f.select_all()
out["check_select"] = f.Editor.get("sel.first", "sel.last") == "hola\nmundo"
f.Editor.insert("end", "!")
f.Menu1_click("Edición/Deshacer")
out["check_undo"] = f.text() == "hola\nmundo"
f.Editor.insert("end", "?")
f.form_close()
out["check_closed"] = True
''';

const _agenda = r'''
out["check_seeded"] = len(f.Contacts.get_children()) == 3
f.Search_var.set("ana")
f.Search_key_up()
out["check_search"] = len(f.Contacts.get_children()) == 1
f.Search_var.set("")
f.Search_key_up()
f.BtnNewContact_click()
f.ContactName_var.set("Pedro Gil")
f.ContactPhone_var.set("611")
f.BtnSaveContact_click()
out["check_added"] = len(f.Contacts.get_children()) == 4
out["check_selected"] = f.Contacts.selection() == (str(f.contact_id),)
f.AppDate_var.set("2020-13-01")
f.BtnAddAppointment_click()
out["check_bad_date"] = "AAAA" in f.Status.cget("text")
f.AppDate_var.set(datetime.date.today().isoformat())
f.AppTime_var.set("7:5")
f.AppSubject_var.set("Llamar")
f.BtnAddAppointment_click()
out["check_time_normalized"] = len(f.Appointments.get_children()) == 3
first = f.Appointments.get_children()[0]
out["check_today"] = "today" in f.Appointments.item(first, "tags")
out["check_order"] = f.Appointments.item(first, "values")[1] == "07:05"
import sqlite3
db = sqlite3.connect("agenda.sqlite")
out["check_db"] = db.execute("SELECT COUNT(*) FROM contact").fetchone()[0] == 4
f.Contacts.selection_set(str(f.contact_id))
f.Contacts_select()
f.BtnDeleteContact_click()
out["check_deleted"] = db.execute("SELECT COUNT(*) FROM contact").fetchone()[0] == 3
f.form_close()
''';

const _currencyServer = r'''
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass
    def do_GET(self):
        body = json.dumps({"amount": 1.0, "base": "EUR", "date": "2026-11-04",
                           "rates": {"USD": 2.0, "SEK": 11.0}, "path": self.path}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)
server = HTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
''';

const _currencyBefore =
    _currencyServer +
    r'''
first = {"done": False}
original = m.Form1.refresh_rates
def local_first(self):
    # La primera carga va al servidor de pruebas, nunca a la red.
    if not first["done"]:
        first["done"] = True
        self.Rates.base_url = "http://127.0.0.1:%d" % server.server_port
    original(self)
m.Form1.refresh_rates = local_first
''';

const _currency = r'''
out["check_loaded"] = pump(lambda: "SEK" in f.rates)
out["check_date"] = "2026-11-04" in f.Status.cget("text")
f.Amount_var.set("10")
f.From_var.set("EUR")
f.To_var.set("USD")
f.show()
out["check_result"] = f.Result.cget("text") == "20,00 USD"
f.BtnSwap_click()
out["check_swap"] = f.Result.cget("text") == "5,00 EUR"
f.Amount_var.set("abc")
f.Amount_key_up()
out["check_bad"] = f.Result.cget("text") == ""
f.Rates.base_url = "http://127.0.0.1:9"
f.refresh_rates()
out["check_offline"] = pump(lambda: str(f.BtnRefresh.cget("state")) == "normal")
out["check_fallback"] = "GBP" in f.rates and "SEK" not in f.rates
''';

const _snake = r'''
class Key:
    def __init__(self, keysym):
        self.keysym = keysym
out["check_start"] = f.alive and len(f.snake) == 3 and f.score == 0
f.food = (f.snake[0][0] + 1, f.snake[0][1])
f.step()
out["check_eat"] = f.score == 1 and len(f.snake) == 4
f.form_key(Key("Left"))
out["check_no_reverse"] = f.queued == (1, 0)
f.form_key(Key("w"))
f.step()
out["check_turn"] = f.direction == (0, -1)
f.food = None
for _ in range(40):
    if not f.alive:
        break
    f.step()
out["check_over"] = not f.alive
out["check_record"] = f.best == 1 and json.load(open("serpiente_record.json"))["best"] == 1
f.form_key(Key("Return"))
out["check_restart"] = f.alive and f.score == 0
f.form_key(Key("space"))
out["check_pause"] = f.paused
''';

const _musicBefore = r'''
class FakePlayer:
    full = True
    def __init__(self):
        self.log = []
        self.length = 120
        self.pos = 0
        self.done = False
        self.vol = None
    def play(self, path):
        self.log.append("play " + os.path.basename(path))
        self.pos = 0
        self.done = False
    def pause(self):
        self.log.append("pause")
    def resume(self):
        self.log.append("resume")
    def stop(self):
        self.log.append("stop")
    def volume(self, value):
        self.vol = value
    def position(self):
        return self.pos
    def finished(self):
        return self.done
m.make_player = FakePlayer
''';

const _music = r'''
import random
out["check_time"] = m.fmt_time(125) == "2:05" and m.fmt_time(None) == "0:00"
out["check_next"] = m.next_index(1, 3) == 2 and m.next_index(2, 3) is None
out["check_repeat"] = m.next_index(2, 3, repeat=True) == 0 and m.next_index(0, 3, step=-1, repeat=True) == 2
out["check_shuffle"] = m.next_index(1, 3, shuffle=True, rng=random.Random(3)) in (0, 2)
fd.askopenfilenames = lambda **o: ("/m/a.mp3", "/m/b.mp3", "/m/c.mp3")
fd.askopenfilename = lambda **o: "/m/a.mp3"
f.add_songs()
out["check_added"] = len(f.songs) == 3 and f.Playlist.size() == 3
f.toggle()
out["check_play"] = f.player.log[-1] == "play a.mp3" and f.playing
f.player.pos = 61
f.Clock_timer()
out["check_clock"] = f.Elapsed.cget("text") == "1:01" and abs(float(f.Position.cget("value")) - 50.83) < 0.1
f.toggle()
f.toggle()
out["check_pause"] = f.player.log[-2:] == ["pause", "resume"]
f.skip(1)
out["check_skip"] = f.player.log[-1] == "play b.mp3"
f.player.done = True
f.Clock_timer()
out["check_auto_next"] = f.player.log[-1] == "play c.mp3"
f.player.done = True
f.Clock_timer()
out["check_end"] = not f.playing
f.Repeat_var.set(1)
f.play(2)
f.player.done = True
f.Clock_timer()
out["check_wrap"] = f.player.log[-1] == "play a.mp3"
f.Volume_change(50)
out["check_volume"] = f.player.vol == 0.5
f.form_close()
saved = json.load(open("playlist.json"))
out["check_saved"] = len(saved["songs"]) == 3 and saved["repeat"] is True
''';

/// Cliente de pruebas de Flask: abre la página y envía eventos como el
/// navegador (con los valores de los campos).
const _webHarness = r'''
import datetime, importlib.util, json, os, re, sqlite3, sys
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
client = m.app.test_client()
page = client.get("/").get_data(as_text=True)
boot = json.loads(re.search(r'id="tk-boot">(.*?)</script>', page).group(1))
headers = {"X-DMS-CSRF": boot["csrf"], "X-DMS-Process": boot["process"]}
def event(widget, kind="command", **values):
    body = {"sid": boot["sid"], "widget": widget, "event": kind, "values": values}
    reply = client.post("/event", json=body, headers=headers)
    assert reply.status_code == 200, reply.status_code
    return reply.get_json()
def html(reply):
    return json.dumps(reply.get("html", {}), ensure_ascii=False)
out = {}
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';

const _crm = r'''
db = sqlite3.connect("crm.sqlite")
out["check_page"] = "Comercial Norte" in page and "Valor en curso" in page
reply = event("BtnSave", Client="ACME", OppTitle="Web", Amount="1.500,50", Stage="Nuevo")
row = db.execute("SELECT id, amount, stage FROM opportunity WHERE client = 'ACME'").fetchone()
out["check_saved"] = row is not None and row[1] == "1500.50" and row[2] == "new"
out["check_listed"] = "ACME" in html(reply)
event("Opps", "select", Opps=str(row[0]))
event("BtnNext")
out["check_next"] = db.execute("SELECT stage FROM opportunity WHERE id = ?", (row[0],)).fetchone()[0] == "qualified"
event("BtnWon")
out["check_won"] = db.execute("SELECT stage FROM opportunity WHERE id = ?", (row[0],)).fetchone()[0] == "won"
reply = event("BtnNext")
out["check_closed"] = "cerrada" in html(reply)
reply = event("StageFilter", "select", StageFilter="Perdido")
out["check_filter"] = "Grupo Sur" in html(reply) and "ACME" not in html(reply)
reply = event("BtnSave", Client="", OppTitle="x")
out["check_validation"] = db.execute("SELECT COUNT(*) FROM opportunity").fetchone()[0] == 6
event("BtnDelete")
out["check_deleted"] = db.execute("SELECT COUNT(*) FROM opportunity WHERE client = 'ACME'").fetchone()[0] == 0
''';

const _invoicing = r'''
db = sqlite3.connect("facturas.sqlite")
year = datetime.date.today().year
out["check_seeded"] = db.execute("SELECT COUNT(*) FROM invoice").fetchone()[0] == 2
out["check_numbers"] = "F-%d-0002" % year in page
event("BtnAddLine", InvProduct="WEB · Diseño web (1.200,00 €)", InvQty="2")
reply = event("BtnAddLine", InvProduct="LIBRO · Libro técnico (35,00 €)", InvQty="1")
out["check_draft"] = "2.435,00" in html(reply) and "2.940,40" in html(reply)
reply = event("BtnIssue", InvClient="Ana Torres", InvDate=datetime.date.today().isoformat())
number = "F-%d-0003" % year
row = db.execute("SELECT subtotal, vat, total, paid FROM invoice WHERE number = ?", (number,)).fetchone()
out["check_issued"] = row == ("2435.00", "505.40", "2940.40", 0)
event("Invoices", "select", Invoices=number)
reply = event("BtnDownload", Invoices=number)
downloads = reply.get("downloads", [])
out["check_download"] = [d["name"] for d in downloads] == [number + ".html"]
import base64
text = base64.b64decode(downloads[0]["data"]).decode()
out["check_html"] = "Ana Torres" in text and "2.940,40" in text
event("BtnPaid", Invoices=number)
out["check_paid"] = db.execute("SELECT paid FROM invoice WHERE number = ?", (number,)).fetchone()[0] == 1
reply = event("BtnAddLine", InvProduct="WEB · Diseño web (1.200,00 €)", InvQty="-1")
out["check_qty"] = "mayor que cero" in json.dumps(reply, ensure_ascii=False)
event("BtnAddClient", ClientName="Nuevo Cliente", ClientTax="X1")
out["check_client"] = db.execute("SELECT COUNT(*) FROM client").fetchone()[0] == 4
event("BtnAddProduct", ProdCode="kit", ProdName="Kit", ProdPrice="10,5", ProdVat="10")
out["check_product"] = db.execute("SELECT price, vat FROM product WHERE code = 'KIT'").fetchone() == ("10.50", "10")
''';

const _blog = r'''
def act(_action, arg="", **form):
    body = {"sid": boot["sid"], "widget": "Site", "event": "action",
            "data": {"action": _action, "arg": str(arg), "form": form}}
    reply = client.post("/event", json=body, headers=headers).get_json()
    assert reply["notes"] == [], reply["notes"]
    return reply.get("html", {}).get("Site", "")
out["check_page"] = "Bitácora" in page and "Últimas entradas" in page and "tk-full" in page
import sqlite3
h = act("dashboard")
out["check_need_login"] = "Entra en tu cuenta" in h and "Entra con tu cuenta para continuar" in h
h = act("register", name="Eva", email="eva@x.com", password="short", password2="short")
out["check_short"] = "al menos 8" in h
h = act("register", name="Eva", email="Eva@X.com", password="secreto123", password2="secreto123")
out["check_admin_dash"] = "Panel del blog" in h and "Hola, Eva." in h   # vuelve al panel pedido
db = sqlite3.connect("blog.sqlite")
row = db.execute("SELECT email, role, hash FROM account").fetchone()
out["check_stored"] = row[0] == "eva@x.com" and row[1] == "admin" and "secreto" not in row[2]
h = act("save", "", title="Nueva <b>", category="1", author="0", published="1", summary="r", body="## Hola\n- uno")
out["check_saved"] = "Nueva &lt;b&gt;" in h and "<h2>Hola</h2>" in h
h = act("logout")
out["check_logout"] = "Has salido" in h and "Crear cuenta" in h
h = act("register", name="Leo", email="leo@x.com", password="secreto123", password2="secreto123")
out["check_user_role"] = db.execute("SELECT role FROM account WHERE email='leo@x.com'").fetchone()[0] == "user"
h = act("dashboard")
out["check_no_panel"] = "solo para administración" in h
h = act("comment", 1, text="<i>hola</i>")
out["check_comment_as_user"] = db.execute("SELECT name FROM comment ORDER BY id DESC").fetchone()[0] == "Leo" and "&lt;i&gt;hola" in h
act("logout")
for i in range(5):
    h = act("signin", email="eva@x.com", password="mala")
h = act("signin", email="eva@x.com", password="secreto123")
out["check_locked"] = "Demasiados intentos" in h
''';

const _shop = r'''
def act(_action, arg="", **form):
    body = {"sid": boot["sid"], "widget": "Site", "event": "action",
            "data": {"action": _action, "arg": str(arg), "form": form}}
    reply = client.post("/event", json=body, headers=headers).get_json()
    assert reply["notes"] == [], reply["notes"]
    return reply.get("html", {}).get("Site", "")
out["check_page"] = "Voltia" in page and "Ofertas de la semana" in page
import sqlite3
db = sqlite3.connect("tienda.sqlite")
out["check_seeded"] = db.execute("SELECT COUNT(*) FROM product").fetchone()[0] == 12
h = act("add", 6, qty="2")
out["check_added"] = "se ha añadido" in h and "<span>2</span>" in h
h = act("add", 6, qty="5")
out["check_stock_limit"] = "Solo quedan 3" in h
h = act("checkout")
out["check_need_login"] = "Entra en tu cuenta" in h
h = act("register", name="Ana", email="ana@x.com", password="secreto123", password2="secreto123")
out["check_back_to_checkout"] = "Datos de envío" in h and "ana@x.com" in h and 'value="Ana"' in h
h = act("pay", name="Ana", address="", city="", zip="")
out["check_validation"] = "Revise sus datos" in h and db.execute("SELECT COUNT(*) FROM orders").fetchone()[0] == 0
h = act("pay", name="Ana <b>", address="Calle 1", city="Sevilla", zip="41001", payment="cod")
order = db.execute("SELECT id, total, user_id, payment, name FROM orders").fetchone()
out["check_order"] = order is not None and order[1] == 49800 and order[2] == 1 and order[3] == "Contra reembolso"
out["check_escaped"] = "Ana &lt;b&gt;" in h and "Ana <b>" not in h
out["check_stock"] = db.execute("SELECT stock, sold FROM product WHERE id = 6").fetchone()[0] == 1
h = act("account")
out["check_my_orders"] = "Pulse ANC × 2" in h
h = act("dashboard")
out["check_admin_dash"] = "Panel de la tienda" in h and "498,00 €" in h
h = act("ship", order[0])
out["check_shipped"] = db.execute("SELECT status FROM orders").fetchone()[0] == "shipped"
h = act("restock", 6, qty="20")
out["check_restock"] = db.execute("SELECT stock FROM product WHERE id = 6").fetchone()[0] == 21
act("logout")
act("register", name="Bea", email="bea@x.com", password="secreto123", password2="secreto123")
h = act("dashboard")
out["check_not_admin"] = "solo para administración" in h
h = act("restock", 6, qty="20")
out["check_no_restock"] = db.execute("SELECT stock FROM product WHERE id = 6").fetchone()[0] == 21
h = act("account")
out["check_own_orders_only"] = "Aún no has hecho" in h
''';
