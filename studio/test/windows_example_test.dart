import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Prueba el ejemplo «Ventanas y diálogos» con tkinter de verdad: los
/// diálogos del sistema se sustituyen por respuestas fijas; la ficha, el
/// diálogo modal y las notas se abren y se cierran de verdad.
const _harness = r'''
import importlib.util, json, os, sys
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
m.messagebox.showinfo = lambda *a, **k: "ok"
m.messagebox.showwarning = lambda *a, **k: "ok"
m.messagebox.showerror = lambda *a, **k: "ok"
m.messagebox.askyesnocancel = lambda *a, **k: None
m.simpledialog.askstring = lambda *a, **k: "Marlon"
m.simpledialog.askinteger = lambda *a, **k: 42
m.colorchooser.askcolor = lambda *a, **k: ((1, 2, 3), "#010203")
# Con la ventana principal oculta no hay nada que ver ni que capturar.
m.OptionsDialog.wait_visibility = lambda self: None
m.OptionsDialog.grab_set = lambda self: None
out = {}
f = m.Form1()
f.root.withdraw()
f.root.update()
for b in ("BtnInfo", "BtnWarning", "BtnError", "BtnAsk", "BtnName", "BtnAge", "BtnColor"):
    getattr(f, b + "_click")()
log = list(f.Log.get(0, "end"))
out["check_log"] = len(log) == 7 and "Marlon" in log[4] and "42" in log[5]
out["check_cancel"] = m.T_CANCELLED in log[3]
out["check_color"] = f.Status.cget("bg") == "#010203"

# Ficha: un correo sin @ no se acepta; uno válido vuelve a la principal.
f.BtnCustomer_click()
w = [c for c in f.root.winfo_children() if isinstance(c, m.CustomerWindow)][-1]
w.mail.set("sin-arroba")
w.save()
out["check_validation"] = w.winfo_exists() and w.error.cget("text") == m.T_MAIL_BAD
w.name.set("Luis")
w.mail.set("luis@example.com")
w.save()
out["check_customer"] = f.customer == {"name": "Luis", "mail": "luis@example.com"}

# Modal: la principal espera; al aceptar lee el resultado.
def accept():
    d = [c for c in f.root.winfo_children() if isinstance(c, m.OptionsDialog)][-1]
    d.dark.set(True)
    d.size.set(16)
    d.accept()
f.root.after(50, accept)
f.BtnOptions_click()
out["check_modal"] = f.options == {"dark": True, "size": 16} and f.Log.cget("bg") == "#1e1f22"
def cancel():
    [c for c in f.root.winfo_children() if isinstance(c, m.OptionsDialog)][-1].destroy()
f.root.after(50, cancel)
f.BtnOptions_click()
out["check_modal_cancel"] = f.options["size"] == 16 and m.T_CANCELLED in f.Log.get("end")

# Notas no modales: varias a la vez, y se cierran todas.
for _ in range(3):
    f.BtnNote_click()
out["check_notes"] = len(f.notes) == 3 and all(n.winfo_exists() for n in f.notes)
f.close_note(f.notes[0])
out["check_close_one"] = len(f.notes) == 2
f.BtnCloseAll_click()
out["check_close_all"] = f.notes == []
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
    '/usr/bin/python3',
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
  late Directory tmp;
  late String path;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_windows_');
    final e = tkExamples(
      (s) => s,
    ).firstWhere((e) => e.seed == 'windows_dialogs');
    expect(e.design.problems(), isEmpty);
    path = p.join(tmp.path, 'app.py');
    await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('genera Python válido', () async {
    final r = await Process.run('python3', ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('ventanas y diálogos de verdad en tkinter', () async {
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final r = await Process.run(py, ['-c', _harness, path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
  });
}
