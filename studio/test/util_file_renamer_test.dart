import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Prueba «Renombrar archivos» con tkinter de verdad en una carpeta
/// temporal: reglas, vista previa, conflictos, el intercambio a<->b,
/// aplicar y deshacer, sin perder ningún archivo.
const _harness = r'''
import importlib.util, json, os, sys
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
errors = []
m.messagebox.askyesno = lambda *a, **k: True
m.messagebox.showerror = lambda title, text, **k: errors.append(text)
out = {}
root = os.path.join(os.getcwd(), "files")
os.makedirs(os.path.join(root, "sub"))
contents = {}
def put(rel, text):
    path = os.path.join(root, rel)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    contents[text] = rel
for rel in ("Foto 1.JPG", "Foto 2.jpg", "notas.txt", "sub/Foto 3.jpg", ".oculto.jpg"):
    put(rel, "data:" + rel)

def listing():
    found = {}
    for top, _, names in os.walk(root):
        for name in names:
            with open(os.path.join(top, name), encoding="utf-8") as f:
                found[os.path.relpath(os.path.join(top, name), root).replace(os.sep, "/")] = f.read()
    return found
original = listing()

# Reglas sueltas.
r = m.make_rules(find="foto", replace="img", prefix="2024-", numbering="after",
                 digits="2", separator="_", case="lower", ext="lower")
out["check_rules"] = m.new_name("Foto 1.JPG", 0, r) == "2024-img 1_01.jpg"
r = m.make_rules(find=r"(\d+)", replace=r"n\1", regex=True, ext="change", new_ext=".png")
out["check_regex"] = m.new_name("Foto 12.jpg", 0, r) == "Foto n12.png"
r = m.make_rules(numbering="replace", start="10", step="5", digits="3", case="title")
out["check_numbers"] = m.new_name("x.txt", 2, r) == "020.txt"
out["check_title"] = m.title_case("hola_mundo de o'neil") == "Hola_Mundo De O'Neil"
bad = []
for kwargs in ({"find": "(", "regex": True}, {"start": "a"}, {"digits": "11"}):
    try:
        m.make_rules(**kwargs)
    except ValueError as error:
        bad.append(str(error))
out["check_bad_rules"] = len(bad) == 3
out["check_problem"] = [m.problem(n) for n in ("a?b.txt", "CON.txt", "fin.", "", "ok.txt")] == ["invalid", "invalid", "invalid", "empty", ""]
out["check_patterns"] = m.patterns_of(" jpg; *.TXT ,") == ["*.jpg", "*.txt"] and m.patterns_of("") == ["*"]

f = m.Form1()
f.root.withdraw()
f.root.update()
out["check_start"] = str(f.BtnApply.cget("state")) == "disabled" and str(f.BtnUndo.cget("state")) == "disabled"

# Carpeta que no existe.
f.Folder_var.set(os.path.join(root, "no-existe"))
f.Folder_return()
out["check_no_folder"] = f.Status.cget("text") == m.NO_FOLDER.format(os.path.join(root, "no-existe"))

# Carpeta con filtro y subcarpetas (los ocultos no salen).
f.Folder_var.set(root)
f.Filter_var.set("jpg")
f.Folder_return()
out["check_filter"] = [(r, n) for r, n in f.files] == [("", "Foto 1.JPG"), ("", "Foto 2.jpg")]
f.Subfolders_var.set(1)
f.Folder_return()
out["check_subfolders"] = len(f.files) == 3 and f.files[2] == ("sub", "Foto 3.jpg")

# Vista previa: minúsculas y numeración.
f.CaseMode.current(1)
f.ExtMode.current(1)
f.NumPos.current(1)
f.NumDigits_var.set("2")
f.NumSep_var.set(" - ")
f.refresh()
news = [f.Preview.item(i, "values")[2] for i in f.Preview.get_children()]
out["preview"] = news
out["check_preview"] = news == ["01 - foto 1.jpg", "02 - foto 2.jpg", "03 - foto 3.jpg"]
out["check_apply_on"] = str(f.BtnApply.cget("state")) == "normal"

# Conflictos: duplicados (todo el mismo nombre), un archivo que ya existe
# (y no entra en el filtro) y caracteres no válidos.
f.NumPos.current(0)
f.CaseMode.current(0)
f.ExtMode.current(0)
f.Find_var.set(r"Foto \d")
f.Regex_var.set(1)
f.Replace_var.set("same")
f.refresh()
states = [r["state"] for r in f.rows]
out["check_duplicate"] = states == ["duplicate", "duplicate", "change"]
out["check_apply_off"] = str(f.BtnApply.cget("state")) == "disabled"
f.Regex_var.set(0)
f.Find_var.set("Foto 1")
f.Replace_var.set("notas")
f.ExtMode.current(3)
f.NewExt_var.set("txt")
f.refresh()
out["check_exists"] = f.rows[0]["state"] == "exists" and str(f.BtnApply.cget("state")) == "disabled"
f.ExtMode.current(0)
f.Replace_var.set("a:b")
f.refresh()
out["check_invalid"] = f.rows[0]["state"] == "invalid" and m.STATES["invalid"] in f.Preview.item("0", "values")
f.Regex_var.set(1)
f.Find_var.set("(")
f.refresh()
out["check_regex_error"] = f.error.startswith(m.BAD_REGEX.split("{")[0]) and str(f.BtnApply.cget("state")) == "disabled"

# Intercambio a<->b con las reglas de la ventana: en «swap», 1.txt y 2.txt
# se numeran al revés (inicio 2, paso -1), así 1->2 y 2->1 a la vez.
os.makedirs(os.path.join(root, "swap"))
put("swap/1.txt", "uno")
put("swap/2.txt", "dos")
f.Folder_var.set(os.path.join(root, "swap"))
f.Subfolders_var.set(0)
f.Filter_var.set("*")
f.Folder_return()
f.Find_var.set("")
f.Regex_var.set(0)
f.Replace_var.set("")
f.ExtMode.current(0)
f.NumPos.current(3)
f.NumStart_var.set("2")
f.NumStep_var.set("-1")
f.NumDigits_var.set("0")
f.refresh()
out["check_swap_plan"] = [(r["old"], r["new"], r["state"]) for r in f.rows] == [("1.txt", "2.txt", "change"), ("2.txt", "1.txt", "change")]
f.BtnApply_click()
def read(rel):
    with open(os.path.join(root, rel), encoding="utf-8") as source:
        return source.read()
out["check_swap"] = read("swap/1.txt") == "dos" and read("swap/2.txt") == "uno" and not errors
f.BtnUndo_click()
out["check_swap_undo"] = read("swap/1.txt") == "uno" and read("swap/2.txt") == "dos"
os.remove(os.path.join(root, "swap", "1.txt"))
os.remove(os.path.join(root, "swap", "2.txt"))
os.rmdir(os.path.join(root, "swap"))
f.NumPos.current(0)
f.Folder_var.set(root)

# Aplicar de verdad desde la ventana: minúsculas en todo (con subcarpetas).
f.Subfolders_var.set(1)
f.Filter_var.set("*")
f.Folder_return()
f.CaseMode.current(1)
f.ExtMode.current(1)
f.refresh()
changes, conflicts = f.counts()
out["check_counts"] = (changes, conflicts) == (3, 0)
f.BtnApply_click()
done = listing()
out["after_apply"] = sorted(done)
out["check_applied"] = sorted(done) == sorted([".oculto.jpg", "foto 1.jpg", "foto 2.jpg", "notas.txt", "sub/foto 3.jpg"])
out["check_contents_kept"] = sorted(done.values()) == sorted(original.values())
out["check_status_done"] = f.Status.cget("text") == m.DONE.format(3)
out["check_undo_on"] = str(f.BtnUndo.cget("state")) == "normal"

# Un intercambio desde la ventana: números al revés con regex.
f.CaseMode.current(0)
f.ExtMode.current(0)
f.Regex_var.set(1)
f.Find_var.set(r"^foto ([12])$")
f.Replace_var.set("tmp")
f.refresh()
out["check_dup_again"] = sum(1 for r in f.rows if r["state"] == "duplicate") == 2

# Deshacer devuelve los nombres originales.
f.Find_var.set("")
f.Regex_var.set(0)
f.refresh()
f.BtnUndo_click()
out["check_undo"] = listing() == original and f.Status.cget("text") == m.UNDONE.format(3)
out["check_undo_off"] = str(f.BtnUndo.cget("state")) == "disabled"

# Si un destino aparece entre la vista previa y Aplicar: nada cambia.
f.Find_var.set("notas")
f.Replace_var.set("nuevo")
f.refresh()
put("nuevo.txt", "intruso")
before = listing()
f.BtnApply_click()
out["check_safe_fail"] = listing() == before and len(errors) == 1
f.form_close()
out["ok"] = all(v for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out))
''';

Future<String?> _python() async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    ?Platform.environment['DMS_TK_PYTHON'],
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
  late TkExample example;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_rename_');
    example = tkUtilFileRenamer((s) => s);
    path = p.join(tmp.path, 'app.py');
    await File(
      path,
    ).writeAsString(TkCodegen.generate(example.design, example.code));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('el diseño es correcto y cabe en la pantalla', () {
    expect(example.seed, 'file_renamer');
    expect(example.name, 'Renombrar archivos');
    expect(example.design.problems(), isEmpty);
    expect(example.design.connections, isEmpty);
    expect(example.design.width, lessThanOrEqualTo(1100));
    expect(example.design.height, lessThanOrEqualTo(720));
  });

  test('genera Python válido', () async {
    final py = await _python() ?? 'python3';
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test(
    'renombra, detecta conflictos y deshace de verdad',
    () async {
      final py = await _python();
      if (py == null) return markTestSkipped('Sin Python con tkinter.');
      final r = await Process.run(py, ['-c', _harness, path]);
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
