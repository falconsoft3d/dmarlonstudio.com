import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _harness = r'''
import importlib.util, json, os, sys
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class Ev:
    def __init__(self, x, y): self.x, self.y = x, y

out = {}
f = m.Form1()
f.root.geometry("880x560")
f.root.update()
c = f.View
def polys(): return len(c.find_all())
out["check_cube"] = polys() == 3 or polys() == 2 or polys() == 1
before = (f.ax, f.ay)
for _ in range(5):
    f.Timer1_timer()
out["check_spins"] = f.ay > before[1]
f.View_mouse_down(Ev(100, 100))
f.View_drag(Ev(160, 130))
out["check_drag"] = abs(f.ay - before[1]) > 0.4
counts = {}
for name in m.SHAPES:
    f.Shape_var.set(name)
    f.Shape_select()
    counts[name] = polys()
out["check_shapes"] = counts[m.SHAPES[2]] > 50 and counts[m.SHAPES[3]] > 50
f.Mode_var.set("wire")
f.mode_change()
out["check_wire"] = polys() == len(f.mesh[1])
f.Zoom_var.set(150)
f.Zoom_change()
f.BtnReset_click()
out["check_reset"] = (round(f.ax, 2), round(f.ay, 2)) == (-0.5, 0.6) and float(f.Zoom_var.get()) == 100
out["check_status"] = "fps" in f.Status.cget("text")
f.root.destroy()
out["ok"] = all(v for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out))
''';

Future<String?> _python() async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
    '/opt/homebrew/bin/python3',
    '/usr/local/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, [
        '-c',
        'import tkinter; tkinter.Tk().destroy()',
      ]);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

void main() {
  test('visor 3D: genera, gira, cambia de figura y de modo', () async {
    final tmp = await Directory.systemTemp.createTemp('dms_3d_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = tkExamples((s) => s).firstWhere((e) => e.seed == 'viewer_3d');
    expect(e.design.problems(), isEmpty);
    final path = p.join(tmp.path, 'app.py');
    await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
    final c = await Process.run('python3', ['-m', 'py_compile', path]);
    expect(c.exitCode, 0, reason: '${c.stderr}');
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final r = await Process.run(py, ['-c', _harness, path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
  });
}
