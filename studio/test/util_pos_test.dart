import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_pos_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> build() async {
    final e = tkUtilPos(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el ejemplo existe, con su nombre y un diseño sin problemas', () {
    final e = tkUtilPos(id);
    expect(e.seed, 'pos');
    expect(e.name, 'Punto de venta');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
    expect(e.design.connections, isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
  });

  test('genera Python válido', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    final path = await build();
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  /// Ejecuta [scenario] con el programa generado y un HOME temporal.
  Future<void> run(String scenario) async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final path = await build();
    // Un HOME temporal: la base de datos y las imágenes van a su carpeta de
    // datos (Application Support, AppData o ~/.local/share).
    final home = p.join(tmp.path, 'home');
    await Directory(home).create();
    final r = await Process.run(
      py,
      ['-c', _harness, path, home, scenario],
      environment: {
        'HOME': home,
        'USERPROFILE': home,
        'APPDATA': p.join(home, 'AppData'),
        'XDG_DATA_HOME': p.join(home, 'share'),
      },
    );
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
  }

  test(
    'de verdad en tkinter: pedido, teclado, cobro, imágenes y SQLite',
    () => run(_scenario),
  );

  test(
    'con un Odoo falso: conexión, productos, pedidos de venta y pendientes',
    () => run(_odooServer + _odooScenario),
  );
}

/// Un Python de este equipo que ejecuta [check] sin error (null: ninguno).
/// PYTHON_TK elige uno concreto.
Future<String?> _python(String check) async {
  final env = Platform.environment;
  final home = env['HOME'] ?? '';
  for (final py in [
    ?env['PYTHON_TK'],
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

/// Carga el programa generado con el HOME temporal en argv[2], ejecuta el
/// escenario (argv[3]) y escribe `out` en JSON. Los diálogos no bloquean.
const _harness = r'''
import importlib.util, json, os, sys, time
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
os.environ["no_proxy"] = os.environ["NO_PROXY"] = "127.0.0.1,localhost"
mb.askyesno = lambda *a, **k: True
mb.showinfo = mb.showerror = mb.showwarning = lambda *a, **k: "ok"
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
def open_form():
    f = m.Form1()
    f.root.withdraw()
    f.root.update()
    return f
def pump(f, until, seconds=10):
    """Deja correr la ventana (y los resultados del hilo de la red)."""
    end = time.time() + seconds
    while time.time() < end:
        f.root.update()
        if until():
            return True
        time.sleep(0.01)
    return False
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';

const _scenario = r'''
P = m.PRODUCTS
def by_id(pid):
    return [p for p in P if p[0] == pid][0]
CAFE_LECHE, CRUASAN, CAPUCHINO = by_id(2), by_id(11), by_id(4)
# ---- el pedido, sin ventana
o = m.Order()
o.add(CAFE_LECHE)
o.add(CAFE_LECHE)
o.add(CRUASAN)
out["check_merge"] = len(o.lines) == 2 and o.lines[0]["qty"] == 2 and o.selected == 1
out["check_total"] = o.total() == 4.7
o.set_mode("disc")
o.press("1")
o.press("0")
out["check_discount"] = o.lines[1]["discount"] == 10 and o.total() == 4.55
o.press("5")
out["check_discount_max"] = o.lines[1]["discount"] == 100 and o.buffer == "100"
o.press("back")
out["check_discount_back"] = o.lines[1]["discount"] == 10
o.add(CRUASAN)
out["check_no_merge_discounted"] = len(o.lines) == 3
o.select(0)
o.set_mode("price")
o.press("2")
out["check_price"] = o.lines[0]["price"] == 2.0 and o.line_total(o.lines[0]) == 4.0
o.press(",")
o.press("5")
o.press("5")
o.press("5")
o.press(",")
out["check_decimals"] = o.lines[0]["price"] == 2.55 and o.buffer == "2,55"
o.set_mode("price")
o.press("back")
out["check_list_price"] = o.lines[0]["price"] == 1.6
o.set_mode("qty")
o.press("5")
out["check_qty"] = o.lines[0]["qty"] == 5
o.press("back")
out["check_qty_zero"] = o.lines[0]["qty"] == 0 and len(o.lines) == 3
o.press("back")
out["check_removed"] = len(o.lines) == 2 and o.lines[0]["name"] == CRUASAN[1]
o.add(CAPUCHINO)
o.press("sign")
out["check_refund"] = o.lines[-1]["qty"] == -1 and o.total() == round(1.35 + 1.5 - 2.2, 2)
o.press("sign")
o.press("back")
o.clean()
out["check_clean"] = len(o.lines) == 2
t = m.Order()
for _ in range(5):
    t.add(by_id(17))  # 5 × 4,50 = 22,50 (IVA incluido)
t.add(by_id(12))  # + 1,10
out["check_taxes"] = t.total() == 23.6 and t.taxes() == [(0.1, 21.45, 2.15)] and t.tax_total() == 2.15
# ---- el cobro
pay = m.Payment(8.75)
out["check_pay_empty"] = not pay.valid() and pay.change() == -8.75
pay.press("2")
pay.press("0")
out["check_pay_cash"] = pay.valid() and pay.change() == 11.25
pay.set_amount(9)
pay.press("5")
out["check_pay_cents"] = pay.buffer == "9,00"
pay.buffer = ""
pay.method = "card"
out["check_pay_card"] = pay.valid() and pay.amount() == 8.75 and not pay.press("1")
out["check_format"] = m.money(-0.001) == "0,00 €" and m.money(1234.5) == "1.234,50 €" and m.number(2.0) == "2" and m.number(0.5) == "0,5"
out["check_plain"] = m.plain("Café CON Leche") == "cafe con leche"
# ---- SQLite, sin ventana
db = m.open_db(":memory:")
r = m.Order()
r.add(CAFE_LECHE)
r.customer = "Ana Torres"
cash = m.Payment(r.total())
cash.set_amount(5)
oid, text = m.save_order(db, r, cash)
out["check_saved"] = oid == 1 and db.execute("SELECT total, change, customer FROM pos_order").fetchone()[:] == (1.6, 3.4, "Ana Torres")
out["check_lines_saved"] = db.execute("SELECT COUNT(*) FROM pos_line WHERE order_id = 1").fetchone()[0] == 1
out["check_receipt"] = "00001" in text and "Ana Torres" in text and "3,40 €" in text and all(len(l) <= m.WIDTH for l in text.split("\n"))
out["check_session"] = m.session(db) == (1, 1.6, 1.6, 0.0)
# ---- la ventana
f = open_form()
home = os.path.realpath(sys.argv[2])
out["check_data_in_home"] = os.path.realpath(f.db_path).startswith(home) and os.path.exists(f.db_path)
# ---- las imágenes: una por producto, que Tk sabe leer
import tkinter as tk
ids = [p[0] for p in P]
decoded = [tk.PhotoImage(master=f.root, data=m.IMAGES[i]) for i in ids]
generic = tk.PhotoImage(master=f.root, data=m.IMAGES[0])  # la bolsa: productos sin imagen
out["check_images"] = sorted(m.IMAGES) == [0] + sorted(ids) and all((d.width(), d.height()) == (96, 96) for d in decoded + [generic])
out["check_images_size"] = sum(len(v) for v in m.IMAGES.values()) < 150000
out["check_tiles"] = len(f.tiles) == 20 and len(f.grid.winfo_children()) == 20
out["check_tile_images"] = all(str(f.tiles[i].cget("image")) == str(f.photos[i]) for i in ids)
out["check_thumbs"] = all(f.thumbs[i].width() == 24 for i in ids)
out["check_scroll"] = float(f.grid_canvas.cget("scrollregion").split()[3]) > 532
f.BtnCat2_click()
out["check_category"] = len(f.tiles) == 5
f.Search_var.set("cafe")
f.Search_key_up()
out["check_search"] = len(f.tiles) == 2
f.Search_var.set("zzz")
f.Search_key_up()
out["check_no_match"] = f.grid.winfo_children()[0].cget("text") == m.NO_MATCH
f.BtnClearSearch_click()
f.BtnCatAll_click()
f.add_product(by_id(1))
f.add_product(by_id(1))
f.ModeDisc_click()
f.Key5_click()
out["check_line_thumb"] = str(f.Lines.item(f.Lines.get_children()[0], "image")[0]) == str(f.thumbs[1])
row = f.Lines.item(f.Lines.get_children()[0], "values")
out["check_line_row"] = row[1] == "2" and row[3] == "5 %" and row[4] == "2,47 €"
f.ModeQty_click()
f.Key1_click()
f.root.update()  # la selección de la tabla no reinicia lo tecleado
f.Key2_click()
class Key:
    def __init__(self, char, keysym):
        self.widget, self.char, self.keysym = f.root, char, keysym
f.form_key(Key("3", "3"))
out["check_keys"] = f.order.lines[0]["qty"] == 123
f.form_key(Key("", "BackSpace"))
out["check_keyboard_back"] = f.order.lines[0]["qty"] == 12
out["check_total_label"] = f.Total.cget("text") == m.TOTAL.format(m.money(f.order.total()))
f.set_customer("Pedro Gil")
out["check_customer"] = "Pedro Gil" in f.customers() and f.BtnCustomer.cget("text") == "Pedro Gil"
f.BtnPay_click()
out["check_payment_screen"] = f.screen == "payment" and str(f.BtnValidate.cget("state")) == "disabled"
f.Key5_click()
out["check_missing"] = f.PayChange.cget("text").startswith(m.MISSING.split("{0}")[0])
f.add_cash(50)
due = f.payment.total
oid = f.validate()
out["check_validated"] = oid == 1 and f.screen == "receipt" and not f.order.lines
out["check_receipt_shown"] = "Pedro Gil" in f.Receipt.get("1.0", "end") and m.money(due) in f.Receipt.get("1.0", "end")
f.new_order()
f.add_product(CAPUCHINO)
f.start_payment()
f.set_method("card")
out["check_card"] = f.validate() == 2
f.new_order()
f.BtnOrders_click()
out["check_orders"] = f.screen == "orders" and len(f.OrderList.get_children()) == 2 and "00002" in f.OrderReceipt.get("1.0", "end")
day_total = m.money(round(due + 2.2, 2))
out["check_summary"] = day_total in f.OrdersSummary.cget("text") and day_total in f.Session.cget("text")
f.BtnOrders_click()
f.BtnPay_click()
out["check_empty_pay"] = f.screen == "products" and f.Status.cget("text") == m.EMPTY
d = m.CustomerDialog(f.root, f.customers(), "", f.set_customer)
d.new.set("Rosa Vidal")
d.pick()
out["check_dialog"] = f.order.customer == "Rosa Vidal" and not d.winfo_exists()
f.add_product(CRUASAN)
f.BtnClear_click()
out["check_clear"] = not f.order.lines and not f.order.customer
# ---- cambiar la imagen de un producto
big = tk.PhotoImage(master=f.root, width=300, height=200)
big.put("#2a9d8f", to=(0, 0, 300, 200))
src = os.path.join(sys.argv[2], "mi_cruasan.png")
big.write(src, format="png")
out["check_changed"] = f.change_image(CRUASAN, src) is True
out["check_scaled"] = (f.photos[11].width(), f.photos[11].height()) == (75, 50)
out["check_tile_updated"] = str(f.tiles[11].cget("image")) == str(f.photos[11])
copied = f.custom_image(11)
out["check_copied"] = copied is not None and os.path.dirname(copied) == f.image_dir and os.path.exists(copied)
bad = os.path.join(sys.argv[2], "roto.png")
open(bad, "w").write("no es una imagen")
out["check_bad_image"] = f.change_image(CRUASAN, bad) is False and f.custom_image(11) == copied
out["check_others_default"] = f.photos[12].width() == 96
f.form_close()
g = open_form()
out["check_restored"] = m.session(g.db)[0] == 2 and "2" in g.Session.cget("text")
out["check_image_restored"] = (g.photos[11].width(), g.photos[11].height()) == (75, 50) and str(g.tiles[11].cget("image")) == str(g.photos[11])
# ---- quitarla: vuelve la de siempre, también al abrir otra vez
out["check_removed_image"] = g.remove_image(CRUASAN) is True and g.photos[11].width() == 96 and not os.path.exists(copied)
out["check_remove_again"] = g.remove_image(CRUASAN) is False
g.form_close()
h = open_form()
out["check_default_back"] = h.custom_image(11) is None and h.photos[11].width() == 96
h.form_close()
''';

/// Un Odoo falso en este proceso, con solo lo que usa el punto de venta: las
/// rutas del cliente web (`/web/database/list`, `/web/session/authenticate` y
/// `/web/dataset/call_kw/<modelo>/<método>`) en JSON-RPC 2.0, con la cookie
/// session_id y los errores como los serializa Odoo. Anota en
/// FAKE["problems"] cualquier petición que no tenga la forma esperada.
const _odooServer = r'''
import threading, uuid as _uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
PNG = m.IMAGES[3]
JPEG = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8U"
FAKE = {
    "dbs": ["demo"], "users": {"admin": "secret"}, "twofa": {"jefe": "secret"},
    "sessions": set(), "log": [], "problems": [], "fail_after_create": False,
    "partners": {1: "Ana Torres"}, "sales": {},
}
ODOO_PRODUCTS = [
    {"id": 7, "name": "Café de Odoo", "lst_price": 1.5, "default_code": "CAF7", "barcode": "8400000000017",
     "categ_id": [1, "All / Saleable"], "pos_categ_ids": [3], "taxes_id": [1], "image_128": PNG},
    {"id": 8, "name": "Tarta de Odoo", "lst_price": 3.0, "default_code": "", "barcode": False,
     "categ_id": [1, "All / Saleable"], "pos_categ_ids": [4], "taxes_id": [2], "image_128": JPEG},
    {"id": 9, "name": "Agua de Odoo", "lst_price": 1.0, "default_code": False, "barcode": False,
     "categ_id": [2, "All / Bebidas"], "pos_categ_ids": [], "taxes_id": [], "image_128": False},
]
TAXES = {1: {"id": 1, "amount": 10.0, "amount_type": "percent", "price_include": False},
         2: {"id": 2, "amount": 21.0, "amount_type": "percent", "price_include": True}}
POS_CATEGORIES = {3: "Cafés Odoo", 4: "Postres"}

class OdooFault(Exception):
    def __init__(self, name, message, code=200):
        super().__init__(message)
        self.name, self.message, self.code = name, message, code

def problem(text):
    FAKE["problems"].append(text)

def call_kw(model, method, args, kwargs):
    if method == "fields_get":
        if kwargs != {"attributes": ["type"]}:
            problem("fields_get %r" % kwargs)
        names = {"product.product": ["name", "lst_price", "default_code", "barcode", "categ_id", "pos_categ_ids",
                                     "taxes_id", "image_128", "sale_ok", "available_in_pos"],
                 "account.tax": ["amount", "amount_type", "price_include"]}[model]
        return {n: {"type": "char"} for n in names}
    if (model, method) == ("product.product", "search_read"):
        if args != [[["sale_ok", "=", True], ["available_in_pos", "=", True]]]:
            problem("product domain %r" % args)
        fields = kwargs.get("fields") or []
        if "image_128" not in fields or "lst_price" not in fields:
            problem("product fields %r" % fields)
        return [dict({"id": p["id"]}, **{f: p[f] for f in fields if f in p}) for p in ODOO_PRODUCTS]
    if (model, method) == ("account.tax", "read"):
        return [TAXES[i] for i in args[0]]
    if (model, method) == ("pos.category", "read"):
        return [{"id": i, "name": POS_CATEGORIES[i]} for i in args[0]]
    if (model, method) == ("res.partner", "search_read"):
        (field, op, value), = args[0]
        return [{"id": i} for i, n in FAKE["partners"].items() if n == value][:kwargs.get("limit") or None]
    if (model, method) == ("res.partner", "create"):
        if not isinstance(args[0], dict):
            problem("partner create %r" % args)
        new = max(FAKE["partners"]) + 1
        FAKE["partners"][new] = args[0]["name"]
        return new
    if (model, method) == ("sale.order", "search_read"):
        (field, op, ref), = args[0]
        if field != "client_order_ref":
            problem("sale search %r" % args)
        return [{"id": i, "name": s["name"], "state": s["state"]} for i, s in FAKE["sales"].items()
                if s["vals"]["client_order_ref"] == ref][:1]
    if (model, method) == ("sale.order", "create"):
        vals = args[0]
        if set(vals) != {"partner_id", "client_order_ref", "order_line"}:
            problem("sale vals %r" % vals)
        for command in vals["order_line"]:
            if command[:2] != [0, 0] or set(command[2]) != {"product_id", "product_uom_qty", "price_unit", "discount"}:
                problem("sale line %r" % command)
        new = len(FAKE["sales"]) + 1
        FAKE["sales"][new] = {"name": "S%05d" % new, "state": "draft", "vals": vals}
        return new
    if (model, method) == ("sale.order", "action_confirm"):
        for i in args[0]:
            FAKE["sales"][i]["state"] = "sale"
        return True
    if (model, method) == ("sale.order", "read"):
        return [{"id": i, "name": FAKE["sales"][i]["name"]} for i in args[0]]
    raise OdooFault("builtins.AttributeError", "The method '%s.%s' does not exist" % (model, method))

class Odoo(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if self.headers.get("Content-Type") != "application/json":
            problem("content type %r" % self.headers.get("Content-Type"))
        body = json.loads(raw.decode("utf-8"))
        if body.get("jsonrpc") != "2.0" or body.get("method") != "call" or not isinstance(body.get("params"), dict):
            problem("envelope %r" % body)
        params, path, cookie, sid = body.get("params") or {}, self.path, None, None
        for part in (self.headers.get("Cookie") or "").split(";"):
            if part.strip().startswith("session_id="):
                sid = part.strip()[len("session_id="):]
        FAKE["log"].append((path, params))
        try:
            if path == "/web/database/list":
                result = list(FAKE["dbs"])
            elif path == "/web/session/authenticate":
                if set(params) != {"db", "login", "password"}:
                    problem("authenticate params %r" % sorted(params))
                if params["db"] not in FAKE["dbs"]:
                    raise OdooFault("odoo.exceptions.AccessError", "Database not found.")
                login, password = params["login"], params["password"]
                if FAKE["twofa"].get(login) == password:
                    result = {"uid": None}  # verificación en dos pasos: sin sesión
                elif FAKE["users"].get(login) == password:
                    sid = _uuid.uuid4().hex
                    FAKE["sessions"].add(sid)
                    cookie = "session_id=%s; Path=/; HttpOnly" % sid
                    result = {"uid": 2, "db": params["db"], "name": "Mitchell Admin", "username": login,
                              "user_companies": {"current_company": 1,
                                                 "allowed_companies": {"1": {"id": 1, "name": "Mi Empresa"}}}}
                else:
                    raise OdooFault("odoo.exceptions.AccessDenied", "Access Denied")
            elif path.startswith("/web/dataset/call_kw/"):
                if sid not in FAKE["sessions"]:
                    raise OdooFault("odoo.http.SessionExpiredException", "Session expired", code=100)
                if set(params) != {"model", "method", "args", "kwargs"}:
                    problem("call_kw params %r" % sorted(params))
                if path != "/web/dataset/call_kw/%s/%s" % (params["model"], params["method"]):
                    problem("call_kw path %s" % path)
                result = call_kw(params["model"], params["method"], params["args"], params["kwargs"])
                if FAKE["fail_after_create"] and path.endswith("/sale.order/create"):
                    # Creado en Odoo, pero la respuesta no llega.
                    FAKE["fail_after_create"] = False
                    self.send_response(502)
                    self.end_headers()
                    return
            else:
                self.send_response(404)
                self.end_headers()
                return
            reply = {"jsonrpc": "2.0", "id": body.get("id"), "result": result}
        except OdooFault as fault:
            reply = {"jsonrpc": "2.0", "id": body.get("id"), "error": {
                "code": fault.code,
                "message": "Odoo Session Expired" if fault.code == 100 else "Odoo Server Error",
                "data": {"name": fault.name, "message": fault.message, "arguments": [fault.message],
                         "context": {}, "debug": ""}}}
        data = json.dumps(reply).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        if cookie:
            self.send_header("Set-Cookie", cookie)
        self.end_headers()
        self.wfile.write(data)

def start_odoo(port=0):
    server = ThreadingHTTPServer(("127.0.0.1", port), Odoo)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server

def stop_odoo(server):
    server.shutdown()
    server.server_close()

def calls(path):
    return sum(1 for p, _ in FAKE["log"] if p == path)
''';

const _odooScenario = r'''
server = start_odoo()
URL = "http://127.0.0.1:%d" % server.server_address[1]
k = open_form()
out["check_off"] = k.client is None and k.OdooState.cget("text") == m.ODOO_OFF
# ---- probar la conexión (en el hilo de la red, sin parar la ventana)
def try_login(**values):
    got = []
    settings = dict({"url": URL, "db": "", "login": "admin", "password": "secret"}, **values)
    k.test_connection(settings, lambda client, error: got.append((client, error)))
    pump(k, lambda: got)
    return got[0] if got else (None, "sin respuesta")
client, error = try_login()
out["check_login"] = error is None and client.db == "demo" and client.uid == 2 and client.company() == "Mi Empresa"
out["check_db_detected"] = calls("/web/database/list") == 1
client, error = try_login(password="mal")
out["check_bad_password"] = getattr(error, "kind", "") == "auth" and str(error) == m.ERR_LOGIN
client, error = try_login(login="jefe")
out["check_2fa"] = getattr(error, "kind", "") == "2fa" and str(error) == m.ERR_2FA
client, error = try_login(db="otra")
out["check_bad_db"] = str(error) == m.ERR_DB.format("otra")
FAKE["dbs"] = ["demo", "pruebas"]
client, error = try_login()
out["check_need_db"] = str(error) == m.ERR_NEED_DB
client, error = try_login(db="pruebas")
out["check_chosen_db"] = error is None and client.db == "pruebas"
FAKE["dbs"] = ["demo"]
client, error = try_login(url="http://127.0.0.1:9")
out["check_no_network"] = getattr(error, "kind", "") == "network"
out["check_problems_login"] = FAKE["problems"] == []
# ---- el diálogo: probar, mostrar la contraseña y guardar
d = m.OdooDialog(k)
for key, value in (("url", URL + "/"), ("login", "admin"), ("password", "secret")):
    d.vars[key].set(value)
d.test()
pump(k, lambda: d.result.cget("text") != m.TESTING)
out["check_dialog_test"] = "Mitchell Admin" in d.result.cget("text") and d.vars["db"].get() == "demo"
d.reveal.set(1)
d.toggle()
out["check_reveal"] = d.password.cget("show") == ""
d.save()
out["check_saved_settings"] = m.load_settings(k.db) == {"url": URL + "/", "db": "demo", "login": "admin", "password": "secret", "partner": m.DEFAULT_PARTNER}
out["check_connected"] = pump(k, lambda: k.odoo_state == "on") and k.OdooState.cget("text") == m.ODOO_ON
# ---- descargar los productos
k.download_products()
out["check_downloaded"] = pump(k, lambda: len(k.catalog) == 3)
cafe, tarta, agua = sorted(k.catalog, key=lambda p: -p[0])
out["check_catalog"] = [p[1] for p in (cafe, tarta, agua)] == ["Café de Odoo", "Tarta de Odoo", "Agua de Odoo"]
# 1,50 sin IVA del 10 % = 1,65 con IVA; la tarta lleva el IVA incluido; el agua, sin impuestos.
out["check_prices"] = (cafe[3], cafe[4], tarta[3], tarta[4], agua[3], agua[4]) == (1.65, 0.10, 3.0, 0.21, 1.0, 0.0)
out["check_categories"] = k.categories == ["Cafés Odoo", "Postres", "Bebidas"] and len(k.tiles) == 3
out["check_png_kept"] = k.default_images[-7] == PNG and str(k.tiles[-7].cget("image")) == str(k.photos[-7])
out["check_jpeg_dropped"] = k.default_images[-8] == "" and k.photos[-8].width() == 96
k.Search_var.set("8400000000017")
k.Search_return()
out["check_barcode"] = len(k.order.lines) == 1 and k.order.lines[0]["id"] == -7
# ---- un pedido: pedido de venta confirmado en Odoo
k.add_product(cafe)
k.ModeDisc_click()
k.Key1_click()
k.Key0_click()
k.ModeQty_click()
k.add_product(tarta)
k.set_customer("Ana Torres")
k.start_payment()
k.set_method("card")
first = k.validate()
def state(order_id):
    return k.db.execute("SELECT odoo_state, odoo_name, ref FROM pos_order WHERE id = ?", (order_id,)).fetchone()
out["check_sent"] = pump(k, lambda: state(first)[0] == "sent")
sale = FAKE["sales"].get(1, {"vals": {}, "state": ""})
lines = sale["vals"].get("order_line")
out["check_sale"] = len(FAKE["sales"]) == 1 and sale["state"] == "sale" and sale["vals"]["partner_id"] == 1
out["check_sale_ref"] = sale["vals"].get("client_order_ref") == state(first)[2] and state(first)[1] == "S00001"
out["check_sale_lines"] = lines == [
    [0, 0, {"product_id": 7, "product_uom_qty": 2.0, "price_unit": 1.5, "discount": 10.0}],
    [0, 0, {"product_id": 8, "product_uom_qty": 1.0, "price_unit": 3.0, "discount": 0.0}],
]
out["check_receipt_odoo"] = m.R_ODOO.format("S00001") in k.Receipt.get("1.0", "end")
# ---- sin conexión: el pedido queda pendiente
stop_odoo(server)
k.new_order()
k.add_product(agua)
k.start_payment()
k.set_method("card")
second = k.validate()
out["check_pending"] = pump(k, lambda: not k.sending) and state(second)[0] == "pending" and k.odoo_state == "down"
out["check_pending_label"] = k.OdooState.cget("text") == m.ODOO_DOWN + m.ODOO_PENDING.format(1)
out["check_pending_receipt"] = m.R_ODOO_PENDING in k.Receipt.get("1.0", "end")
# ---- vuelve el servidor; el pedido se crea pero la respuesta se pierde
server = start_odoo(int(URL.rsplit(":", 1)[1]))
FAKE["fail_after_create"] = True
k.connect()
pump(k, lambda: len(FAKE["sales"]) == 2 and not k.sending)
out["check_lost_reply"] = state(second)[0] == "pending" and FAKE["sales"][2]["state"] == "draft"
# Al reintentar (con la sesión caducada) se usa el mismo, sin duplicarlo.
FAKE["sessions"].clear()
logins = calls("/web/session/authenticate")
k.connect()
out["check_synced"] = pump(k, lambda: state(second)[0] == "sent") and state(second)[1] == "S00002"
out["check_no_duplicate"] = len(FAKE["sales"]) == 2 and FAKE["sales"][2]["state"] == "sale"
out["check_default_partner"] = FAKE["partners"][FAKE["sales"][2]["vals"]["partner_id"]] == m.DEFAULT_PARTNER
k.sync()
pump(k, lambda: not k.sending, 1)
out["check_nothing_left"] = len(FAKE["sales"]) == 2 and m.pending_count(k.db) == 0
out["check_relogin"] = calls("/web/session/authenticate") > logins
# Una sesión caducada en medio: se entra otra vez una vez y se repite la llamada.
FAKE["sessions"].clear()
logins = calls("/web/session/authenticate")
k.download_products()
out["check_expired_retry"] = pump(k, lambda: k.odoo_state == "on") and calls("/web/session/authenticate") == logins + 1
out["check_label_ok"] = k.OdooState.cget("text") == m.ODOO_ON
# ---- al abrir otra vez: la conexión y el catálogo de Odoo siguen
k.form_close()
g = open_form()
out["check_reopen"] = g.client is not None and len(g.catalog) == 3 and pump(g, lambda: g.odoo_state == "on")
# Productos del catálogo de ejemplo: el pedido no se envía.
g.demo_catalog()
g.add_product(m.PRODUCTS[0])
g.start_payment()
g.set_method("card")
third = g.validate()
out["check_local_only"] = g.db.execute("SELECT odoo_state FROM pos_order WHERE id = ?", (third,)).fetchone()[0] == "local"
out["check_local_status"] = g.Status.cget("text") == m.LOCAL_ONLY and len(FAKE["sales"]) == 2
g.form_close()
out["problems"] = FAKE["problems"]
out["check_requests_ok"] = FAKE["problems"] == []
stop_odoo(server)
''';
