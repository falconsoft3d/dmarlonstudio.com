import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

/// Un Python 3 con tkinter (o null): DMS_TK_PYTHON, python3 o el del sistema.
Future<String?> _python() async {
  final env = Platform.environment['DMS_TK_PYTHON'];
  for (final py in [
    if (env != null && env.isNotEmpty) env,
    'python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, ['-c', 'import tkinter']);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

void main() {
  final e = tkDomino(id);

  test('el ejemplo: lienzo con sus eventos, reloj y menú', () {
    expect(e.seed, 'domino');
    expect(e.design.isPython && !e.design.isWeb, isTrue);
    expect(e.design.problems(), isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
    final table = e.design.widgets.firstWhere((w) => w.name == 'Table');
    expect(table.kind, 'Canvas');
    expect(table.events.keys, containsAll(['click', 'motion', 'leave']));
    expect(e.code, contains('def Table_click(self, event):'));
    expect(e.code, contains('def Tick_timer(self):'));
    expect(e.code, contains('def Menu1_click(self, item):'));
    // Sin paquetes de pip: solo tkinter (Pillow, solo para las capturas).
    expect(e.code, isNot(contains('REQUIRES =')));
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkDomino(en);
    expect(x.name, 'Double-Nine Dominoes');
    expect(x.code, contains('TEAM_US = "Us"'));
    String tail(String c) => c.substring(
      c.indexOf('SOUTH, EAST, NORTH, WEST = '),
    );
    expect(tail(x.code), tail(e.code));
  });

  test(
    'de verdad: Python válido y pasan sus pruebas internas',
    () async {
      final py = await _python();
      if (py == null) return markTestSkipped('Sin Python.');
      final tmp = await Directory.systemTemp.createTemp('dms_domino_');
      addTearDown(() => tmp.delete(recursive: true));
      final path = p.join(tmp.path, 'app.py');
      File(path).writeAsStringSync(TkCodegen.generate(e.design, e.code));
      final dump = Platform.environment['DMS_DOMINO_DUMP'];
      if (dump != null && dump.isNotEmpty) File(path).copySync(dump);
      final c = await Process.run(py, ['-m', 'py_compile', path]);
      expect(c.exitCode, 0, reason: '${c.stderr}');
      // Partidas enteras con la computadora, la mesa sin fichas pisadas y la
      // computadora contra el azar: sin abrir ninguna ventana.
      final r = await Process.run(
        py,
        [path],
        environment: {'DMS_DOMINO_SELFTEST': '1'},
      ).timeout(const Duration(minutes: 3));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('selftest ok'));
      // La ventana de verdad, oculta antes de que se dibuje: el lienzo, el
      // reloj y los clics de una mano entera.
      final h = await Process.run(py, [
        '-c',
        _harness,
        path,
      ]).timeout(const Duration(minutes: 2));
      expect(h.exitCode, 0, reason: '${h.stdout}${h.stderr}');
      expect('${h.stdout}', contains('window ok'));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

/// Carga el programa sin su main, crea la ventana oculta y juega una mano
/// con los clics del jugador y el reloj de la computadora.
const _harness = r"""
import importlib.util, sys, time, types
spec = importlib.util.spec_from_file_location("app", sys.argv[1])
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)
form = app.Form1()
form.root.withdraw()
form._start()
g = form.game
items = len(form.Table.find_all())
assert items > 100, items
moves_done = 0
for step in range(4000):
    g = form.game
    if g.result:
        form.view.overlay = True
        break
    form.wait_until = 0
    if g.turn == app.SOUTH and g.moves(app.SOUTH):
        tile, side = g.moves(app.SOUTH)[0]
        i = g.hands[app.SOUTH].index(tile)
        r = app.hand_rects(len(g.hands[app.SOUTH]))[i]
        ev = types.SimpleNamespace(x=(r[0] + r[2]) / 2, y=(r[1] + r[3]) / 2)
        form.Table_motion(ev)
        form.Table_click(ev)
        if form.view.pending:
            x, y = app.arm_end(g, side)
            form.Table_click(types.SimpleNamespace(x=x, y=y))
        moves_done += 1
    else:
        form.Tick_timer()
assert g.result, "la mano termina"
form.redraw()
form.Table_click(types.SimpleNamespace(x=10, y=10))
assert form.game.hand_no == 2 or form.game.over, form.game.hand_no
form.Menu1_click(app.MP_SHOW_ALL)
assert form.view.show_all
form.Menu1_click(app.MP_TO200)
assert form.game.target == 200
form.root.update_idletasks()
print("window ok moves=%d items=%d" % (moves_done, items))
form.root.destroy()
""";
