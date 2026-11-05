import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample example(String seed) =>
    [...tkExamples(id), ...tkWebExamples(id)].firstWhere((e) => e.seed == seed);

const seeds = ['line_chart', 'stocks', 'web_line_chart', 'web_stocks'];

/// Un diseño con un gráfico, para probar su código suelto.
TkDesign chartDesign({bool web = false}) =>
    TkDesign(
        width: 500,
        height: 320,
        target: web ? tkTargetWeb : tkTargetDesktop,
      )
      ..widgets.add(
        TkWidget(
          kind: 'Chart',
          name: 'Chart1',
          x: 10,
          y: 10,
          width: 460,
          height: 280,
          props: {'title': 'Ventas <b>', 'suffix': ' €', 'decimals': 1},
          events: {'point': 'Chart1_point'},
        ),
      );

const chartUnit = '''class Form1(FormDesign):
    def Chart1_point(self, point):
        self.last = point
''';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_chart_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> write(String name, String source) async {
    final dir = Directory(p.join(tmp.path, name));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'app.py'));
    await file.writeAsString(source);
    return file.path;
  }

  Future<String> build(String seed) {
    final e = example(seed);
    return write(seed, TkCodegen.generate(e.design, e.code));
  }

  Future<Map> run(
    String py,
    String path,
    String harness,
    String scenario,
  ) async {
    final r = await Process.run(py, [
      '-c',
      harness,
      path,
      p.dirname(path),
      scenario,
    ]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
    return out;
  }

  test(
    'el gráfico está en la paleta y solo el clic en un punto no va a la web',
    () {
      final c = tkComponent('Chart')!;
      expect(c.visual, isTrue);
      expect(c.prop('kind')!.choices, ['line', 'area', 'bar', 'candles']);
      expect(tkWebHasEvent(c.events.single), isFalse);
      final opts = TkCodegen.chartOptions(chartDesign().widgets.single);
      expect(opts, {
        'title': "'Ventas <b>'",
        'decimals': '1',
        'suffix': "' €'",
      });
    },
  );

  test('los cuatro ejemplos existen y generan Python válido', () async {
    for (final s in seeds) {
      final e = example(s);
      expect(e.design.problems(), isEmpty, reason: s);
      expect(e.design.isWeb, s.startsWith('web_'), reason: s);
      final path = await build(s);
      final r = await Process.run('python3', ['-m', 'py_compile', path]);
      expect(r.exitCode, 0, reason: '$s: ${r.stderr}');
    }
  });

  test('escalas «nice numbers» que siempre cubren los datos', () async {
    final path = await write(
      'core',
      TkCodegen.generate(chartDesign(), chartUnit),
    );
    final r = await Process.run('python3', ['-c', _ticks, path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    expect('${r.stdout}'.trim(), 'ok');
  });

  test('de verdad en tkinter: componente suelto', () async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final path = await write(
      'tk',
      TkCodegen.generate(chartDesign(), chartUnit),
    );
    await run(py, path, _desktopHarness, _component);
  });

  for (final (seed, scenario) in [('line_chart', _line), ('stocks', _stocks)]) {
    test('de verdad en tkinter: $seed', () async {
      final py = await _python('import tkinter; tkinter.Tk().destroy()');
      if (py == null) return markTestSkipped('Sin Python con tkinter.');
      await run(py, await build(seed), _desktopHarness, scenario);
    });
  }

  test('de verdad en Flask: SVG escapado del componente suelto', () async {
    final py = await _python('import flask');
    if (py == null) return markTestSkipped('Sin Python con Flask.');
    final path = await write(
      'web',
      TkCodegen.generate(chartDesign(web: true), chartUnit),
    );
    await run(py, path, _webHarness, _webComponent);
  });

  for (final (seed, scenario) in [
    ('web_line_chart', _webLine),
    ('web_stocks', _webStocks),
  ]) {
    test('de verdad en Flask: $seed', () async {
      final py = await _python('import flask');
      if (py == null) return markTestSkipped('Sin Python con Flask.');
      await run(py, await build(seed), _webHarness, scenario);
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

/// Comprueba nice_ticks del archivo generado (argv[1]) sin abrir ventanas:
/// solo se ejecuta hasta definir las funciones.
const _ticks = r'''
import ast, math, random, sys
src = open(sys.argv[1], encoding="utf-8").read()
tree = ast.parse(src)
code = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "nice_ticks"]
ns = {"math": math}
exec(compile(ast.Module(body=code, type_ignores=[]), "ticks", "exec"), ns)
nice_ticks = ns["nice_ticks"]
assert nice_ticks(0, 97) == [0, 20, 40, 60, 80, 100], nice_ticks(0, 97)
assert nice_ticks(-3.2, 7.9) == [-5, 0, 5, 10]
assert nice_ticks(1234, 1876)[-1] >= 1876
t = nice_ticks(5, 5)
assert t[0] < 5 < t[-1]
r = random.Random(7)
for _ in range(3000):
    lo = r.uniform(-1e6, 1e6)
    hi = lo + r.uniform(0, 1e5) * r.choice([1e-6, 1e-3, 1, 10])
    t = nice_ticks(lo, hi)
    assert t[0] <= lo + 1e-6 and t[-1] >= hi - 1e-6, (lo, hi, t)
    assert 2 <= len(t) <= 12, (lo, hi, t)
    steps = {round(b - a, 9) for a, b in zip(t, t[1:])}
    assert len(steps) == 1 or max(steps) - min(steps) < 1e-6 * max(steps), (t, steps)
print("ok")
''';

const _desktopHarness = r'''
import importlib.util, json, os, sys, time
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
f = m.Form1()
f.root.withdraw()
for _ in range(5):
    f.root.update()
class Ev:
    def __init__(self, x, y):
        self.x, self.y = x, y
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
try:
    f.root.destroy()
except Exception:
    pass
''';

const _component = r'''
c = f.Chart1
c.set_series("A", [10, 12, 9, 15], x=["ene", "feb", "mar", "abr"])
c.set_series("B", [5, 7, 8, 6])
out["check_shared_x"] = c.labels() == ["ene", "feb", "mar", "abr"]
out["check_colors"] = (c.color("A"), c.color("B")) == ("#2a78d6", "#eb6834")
c.redraw()
out["check_drawn"] = len(c.find_withtag("chart")) > 20 and len(c._spots) == 4
s = c._spots[2]
c._hover(Ev(int(s[4]), int(s[1] + 10)))
out["check_hover"] = len(c.find_withtag("hover")) >= 4
c._click(Ev(int(s[4]), int(s[1] + 10)))
out["check_click"] = f.last == {"x": "mar", "index": 2, "values": {"A": 9.0, "B": 8.0}}
c.show_series("A", False)
c.redraw()
out["check_hidden"] = len(c._spots[0][6]) == 1
c.show_series("A", True)
c.set_max_points(3)
c.add_point("A", 20)
out["check_trim"] = c.values("A") == [9.0, 15.0, 20.0]
out["check_fmt"] = c.fmt(1234.5) == "1,234.5 €"
c.remove_series("A")
out["check_color_follows"] = c.color("B") == "#eb6834"
c.clear()
c.set_kind("candles")
c.set_candles([("d1", 10, 12, 9, 11, 1000), ("d2", 11, 11.5, 8, 9, 3000)])
c.add_candle("d3", 9, 10, 8.5, 9.5, 2000)
c.redraw()
out["check_candles"] = len(c.candles()) == 3 and len(c._spots) == 3
out["check_ohlc_tip"] = "O 10.0 €" in c._spots[0][5] and "V 1.0K" in c._spots[0][5]
for kind in ("line", "area", "bar"):
    c.set_kind(kind)
    c.set_series("A", [1, -2, 3])
    c.redraw()
out["check_kinds"] = len(c.find_withtag("chart")) > 10
''';

const _line = r'''
c = f.Chart1
out["check_months"] = len(c.labels()) == 12 and len(c.values(m.PRODUCTS[0])) == 12
out["check_status"] = "2026" in f.Status.cget("text")
first = c.values(m.PRODUCTS[0])
f.Year_var.set("2025")
f.Year_select()
out["check_year"] = c.values(m.PRODUCTS[0]) != first
f.Year_var.set("2026")
f.Year_select()
out["check_deterministic"] = c.values(m.PRODUCTS[0]) == first
f.ChkC_var.set(0)
f.series_toggle()
out["check_toggle"] = m.PRODUCTS[2] in c._hidden
f.Kind_var.set("bar")
f.kind_change()
out["check_kind"] = c._opts["kind"] == "bar"
f.BtnLive_click()
out["check_live"] = f.live and f.Timer1.enabled
for _ in range(14):
    f.Timer1_timer()
out["check_window"] = len(c.values(m.PRODUCTS[0])) == 12 and c.labels()[-1] == "+14"
f.BtnLive_click()
out["check_stopped"] = not f.live and not f.Timer1.enabled and len(c.labels()) == 12
c.redraw()
out["check_drawn"] = len(c.find_withtag("chart")) > 30
''';

const _stocks = r'''
c = f.Chart1
out["check_candles"] = len(c.candles()) == 66
out["check_average"] = len(c.values(m.AVERAGE)) == 66 - 19
text = f.Change.cget("text")
out["check_arrow"] = text[0] in "▲▼" and f.Change.cget("fg") in (m.UP, m.DOWN)
out["check_simulated"] = "simulados" in f.Simulated.cget("text").lower()
first = c.candles()[-1][4]
f.Ticker_var.set("ACME")
f.Ticker_select()
acme = c.candles()[-1][4]
f.Ticker_var.set("DMS")
f.Ticker_select()
out["check_seeded"] = c.candles()[-1][4] == first and acme != first
f.Btn1M_click()
out["check_frame"] = len(c.candles()) == 22 and c.candles()[0][0].count("/") == 1
f.BtnStart_click()
out["check_running"] = f.Timer1.enabled and str(f.BtnStop.cget("state")) == "normal"
last = c.candles()[-1][0]
for _ in range(3):
    f.Timer1_timer()
out["check_live"] = len(c.candles()) == 22 and c.candles()[-1][0] != last
f.BtnStop_click()
out["check_stopped"] = not f.Timer1.enabled
c.redraw()
out["check_volume"] = len(c.find_withtag("chart")) > 100
''';

const _webHarness = r'''
import importlib.util, json, os, re, sys
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
client = m.app.test_client()
page = client.get("/").get_data(as_text=True)
boot = json.loads(re.search(r'id="tk-boot">(.*?)</script>', page).group(1))
headers = {"X-DMS-CSRF": boot["csrf"], "X-DMS-Process": boot["process"]}
def post(body):
    body = dict(body, sid=boot["sid"])
    reply = client.post("/event", json=body, headers=headers)
    assert reply.status_code == 200, reply.status_code
    return reply.get_json()
def event(widget, kind="command", **values):
    return post({"widget": widget, "event": kind, "values": values})
def tick(reply):
    return post({"timer": reply["timers"][0]["id"]})
def html(reply):
    return json.dumps(reply.get("html", {}), ensure_ascii=False)
out = {}
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';

const _webComponent = r'''
out["check_svg"] = '<div id="Chart1" class="tk tk-chart"' in page and "<svg" in page
out["check_escaped"] = "Ventas &lt;b&gt;" in page and "Ventas <b>" not in page
''';

const _webLine = r'''
out["check_svg"] = "<svg" in page and "Portátiles" in page and "<title>ene" in page
reply = event("Year", "select", Year="2025")
out["check_year"] = "Chart1" in reply["html"] and "2025" in html(reply)
reply = event("RadBar", RadBar=True)
out["check_bars"] = "<rect" in reply["html"].get("Chart1", "")
reply = event("BtnLive")
out["check_timer"] = len(reply["timers"]) == 1
reply = tick(reply)
out["check_tick"] = "+1" in reply["html"].get("Chart1", "")
''';

const _webStocks = r'''
out["check_svg"] = "<svg" in page and "OHLC" in page and "Datos simulados" in page
reply = event("Btn1M")
out["check_frame"] = reply["html"]["Chart1"].count('class="hot"') == 22
reply = event("BtnStart")
out["check_timer"] = len(reply["timers"]) == 1
reply = tick(reply)
out["check_tick"] = "Chart1" in reply["html"] and ("▲" in html(reply) or "▼" in html(reply))
''';
