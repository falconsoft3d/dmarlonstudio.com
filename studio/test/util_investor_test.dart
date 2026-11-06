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
    tmp = await Directory.systemTemp.createTemp('dms_investor_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> build() async {
    final e = tkUtilInvestor(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el ejemplo existe, con su nombre y un diseño sin problemas', () {
    final e = tkUtilInvestor(id);
    expect(e.seed, 'investor');
    expect(e.name, 'Inversor de bolsa (demo)');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
    expect(e.design.connections, isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
    // Solo empresas inventadas y nada de sintaxis de Python 3.10.
    expect(e.code, isNot(contains('match ')));
  });

  test('genera Python válido', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    final path = await build();
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('de verdad en tkinter: cuentas, órdenes y cartera guardada', () async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final path = await build();
    final r = await Process.run(py, ['-c', _harness, path, tmp.path, _scenario]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
  });
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

/// Carga el programa generado con la carpeta de datos en argv[2], ejecuta el
/// escenario (argv[3]) y escribe `out` en JSON. Los diálogos no bloquean.
const _harness = r'''
import importlib.util, json, os, sys
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
mb.askyesno = lambda *a, **k: True
mb.showinfo = mb.showerror = mb.showwarning = lambda *a, **k: "ok"
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
m.data_dir = lambda: sys.argv[2]
out = {}
def open_form():
    f = m.Form1()
    f.root.withdraw()
    f.root.update()
    f.Timer1.stop()
    return f
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';

const _scenario = r'''
import random
# ---- cuentas, sin ventana
P = m.Portfolio()
P.buy("LUMX", 10, 50.0)
out["check_buy"] = P.cash == 9499.0 and P.shares("LUMX") == 10
out["check_average"] = abs(P.average("LUMX") - 50.1) < 1e-9
sold = P.sell("LUMX", 4, 60.0)
# 240 - 1 de comisión - 4 × 50,10 de coste = 38,60
out["check_sell"] = sold["result"] == 38.6 and P.cash == 9738.0 and P.shares("LUMX") == 6
out["check_cost_left"] = P.positions["LUMX"]["cost"] == 300.6 and P.realized == 38.6
def fails(action):
    try:
        action()
    except m.TradeError:
        return True
    return False
out["check_no_shares"] = fails(lambda: P.sell("LUMX", 7, 60.0))
out["check_no_cash"] = fails(lambda: P.buy("NBTR", 1000, 126.0))
out["check_bad_qty"] = fails(lambda: P.buy("NBTR", 0, 126.0)) and fails(lambda: P.sell("LUMX", -1, 1.0))
out["check_fee"] = m.fee_for(100) == 1.0 and m.fee_for(20000) == 20.0
Q = m.Portfolio()
n = Q.max_buy(33.0)
out["check_max"] = n > 0 and fails(lambda: m.Portfolio().buy("ZNKR", n + 1, 33.0)) and not fails(lambda: Q.buy("ZNKR", n, 33.0))
P.sell("LUMX", 6, 40.0)
out["check_closed"] = "LUMX" not in P.positions and len(P.orders) == 3
again = m.Portfolio.from_dict(json.loads(json.dumps(P.to_dict())))
out["check_roundtrip"] = again.cash == P.cash and again.orders == P.orders and again.realized == P.realized
out["check_money"] = m.money(1234.5) == "1.234,50 €" and m.signed(-2) == "-2,00 €" and m.signed(3) == "+3,00 €"
mk = m.Market(prices={"LUMX": 99.99}, rng=random.Random(1))
out["check_market_restored"] = mk.prices["LUMX"] == 99.99 and mk.history["LUMX"][-1][1] == 99.99
for _ in range(200):
    mk.step()
out["check_market_walk"] = all(v >= 0.5 for v in mk.prices.values()) and len(mk.history["PXLB"]) == m.HISTORY
out["check_fictional"] = len(m.COMPANIES) == 8
# ---- la ventana
f = open_form()
out["check_market_rows"] = len(f.Market.get_children()) == 8
out["check_cash_card"] = f.CashValue.cget("text") == "10.000,00 €"
f.Market.selection_set("NBTR")
f.Market_select()
out["check_selected"] = f.selected == "NBTR" and f.OrderTicker_var.get() == "NBTR"
f.Qty_var.set("10")
price = f.market.prices["NBTR"]
f.BtnBuy_click()
out["check_bought"] = f.book.shares("NBTR") == 10 and len(f.Holdings.get_children()) == 1 and len(f.Orders.get_children()) == 1
out["check_saved"] = json.load(open(m.SAVE_FILE))["positions"]["NBTR"]["shares"] == 10
for _ in range(3):
    f.Timer1_timer()
out["check_chart"] = len(f.Chart1.values("NBTR")) == m.HISTORY and len(f.Chart1.values(m.AVERAGE)) == m.HISTORY
out["check_moved"] = f.Market.item("NBTR", "values")[2] == m.money(f.market.prices["NBTR"])
f.Qty_var.set("abc")
f.BtnBuy_click()
out["check_bad_status"] = f.Status.cget("text") == m.BAD_QTY
f.Qty_var.set("11")
f.BtnSell_click()
out["check_too_many"] = "10" in f.Status.cget("text") and f.book.shares("NBTR") == 10
f.Holdings.selection_set("NBTR")
f.Holdings_select()
out["check_sell_all_ready"] = f.Qty_var.get() == "10"
f.BtnSell_click()
out["check_sold"] = f.book.shares("NBTR") == 0 and not f.Holdings.get_children() and len(f.Orders.get_children()) == 2
f.Market.selection_set("VLMR")
f.Market_select()
f.BtnMax_click()
f.BtnBuy_click()
out["check_max_buy"] = f.book.shares("VLMR") > 0 and f.book.cash < f.market.prices["VLMR"] * 1.01 + 1
f.BtnPause_click()
out["check_paused"] = not f.running
f.BtnPause_click()
out["check_running"] = f.running
cash = f.book.cash
f.form_close()
# ---- al abrir otra vez, la misma cartera
g = open_form()
out["check_restored"] = g.book.cash == cash and g.book.shares("VLMR") > 0 and len(g.Orders.get_children()) == 3
g.BtnReset_click()
out["check_reset"] = g.book.cash == 10000.0 and not g.Holdings.get_children() and not g.Orders.get_children()
out["check_reset_saved"] = json.load(open(m.SAVE_FILE))["cash"] == 10000.0
g.form_close()
''';
