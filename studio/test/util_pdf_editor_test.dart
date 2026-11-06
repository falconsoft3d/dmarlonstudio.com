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
    tmp = await Directory.systemTemp.createTemp('dms_pdf_editor_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> build() async {
    final e = tkUtilPdfEditor(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el editor de PDF existe y declara pypdf', () {
    final e = tkUtilPdfEditor(id);
    expect(e.seed, 'pdf_editor');
    expect(e.name, 'Editor de PDF');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
    expect(e.code, contains('\nREQUIRES = ["pypdf"]\n'));
  });

  test('genera Python válido', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    final path = await build();
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('de verdad en tkinter con pypdf', () async {
    final py = await _python('import tkinter, pypdf; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter y pypdf.');
    final path = await build();
    final r = await Process.run(py, ['-c', _harness, path, tmp.path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
  });
}

/// Un Python con [check] sin error: DMS_TK_PYTHON o python3 (null: ninguno).
Future<String?> _python(String check) async {
  final env = Platform.environment['DMS_TK_PYTHON'];
  for (final py in [
    if (env != null && env.isNotEmpty) env,
    'python3',
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

const _harness = r'''
import importlib.util, io, json, os, sys, time
import tkinter.filedialog as fd
import tkinter.messagebox as mb
import tkinter.simpledialog as sd
from pypdf import PdfReader, PdfWriter
os.chdir(sys.argv[2])
errors = []
mb.askyesnocancel = lambda *a, **k: False
mb.showinfo = mb.showwarning = lambda *a, **k: "ok"
mb.showerror = lambda *a, **k: errors.append(a)
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}

def make(path, texts, size=(595.28, 841.89), title=None):
    w = PdfWriter()
    for text in texts:
        page = w.add_blank_page(*size)
        m.stamp_page(page, {"text": text, "place": "center", "size": 20, "color": (0, 0, 0), "rotation": 0})
    if title:
        w.add_metadata({"/Title": title})
    with open(path, "wb") as f:
        w.write(f)

def texts(path, password=None):
    r = PdfReader(path)
    if password:
        r.decrypt(password)
    return [p.extract_text().strip() for p in r.pages]

def pick(*rows):
    f.Pages.selection_set([str(i) for i in rows])
    f.root.update()

def pump(until, seconds=10):
    end = time.time() + seconds
    while time.time() < end:
        f.root.update()
        if until():
            return True
        time.sleep(0.01)
    return False

make("src.pdf", ["Uno", "Dos", "Tres", "Cuatro"], title="Original")
make("other.pdf", ["ExtraA", "ExtraB"], size=(612, 792))

f = m.Form1()
f.root.withdraw()
f.root.update()
out["check_empty"] = f.entries == [] and not errors

out["check_load"] = f.load("src.pdf") and len(f.entries) == 4
out["check_meta_loaded"] = f.DocTitle_var.get() == "Original"
row = f.Pages.item("0", "values")
out["check_size"] = "210 × 297 mm" in row[1] and "A4" in row[1]
out["check_texts"] = pump(lambda: not f.pending) and "Uno" in f.Pages.item("0", "values")[3]
pick(1)
f.show_text()
out["check_page_text"] = "Dos" in f.PageText.get("1.0", "end")

# Girar, mover, duplicar, eliminar y deshacer.
pick(0)
f.BtnRotRight_click()
out["check_rotate"] = f.Pages.item("0", "values")[2] == "90°" and "297 × 210" in f.Pages.item("0", "values")[1]
f.BtnRotLeft_click()
f.BtnRotLeft_click()
out["check_rotate_left"] = f.entries[0]["rot"] == 270
pick(3)
f.BtnUp_click()
out["check_up"] = [e["page"] for e in f.entries] == [0, 1, 3, 2] and f.chosen() == [2]
pick(0)
f.BtnUp_click()
out["check_up_top"] = [e["page"] for e in f.entries] == [0, 1, 3, 2]
pick(1, 2)
f.BtnDown_click()
out["check_down_many"] = [e["page"] for e in f.entries] == [0, 2, 1, 3] and f.chosen() == [2, 3]
pick(0)
f.BtnDuplicate_click()
out["check_duplicate"] = [e["page"] for e in f.entries] == [0, 0, 2, 1, 3] and f.chosen() == [1]
f.BtnRotRight_click()
out["check_duplicate_apart"] = f.entries[0]["rot"] == 270 and f.entries[1]["rot"] == 0
pick(3)
f.BtnDelete_click()
out["check_delete"] = [e["page"] for e in f.entries] == [0, 0, 2, 3]
f.BtnUndo_click()
out["check_undo"] = [e["page"] for e in f.entries] == [0, 0, 2, 1, 3]
f.select_all()
f.BtnDelete_click()
out["check_keep_one"] = len(f.entries) == 5

# Insertar otro PDF antes de la página 2.
sd.askinteger = lambda *a, **k: 2
f.insert_pdf(os.path.abspath("other.pdf"))
out["check_insert"] = len(f.entries) == 7 and [e["src"] for e in f.entries][1:3] == [1, 1] and f.chosen() == [1, 2]
out["check_letter"] = "Carta" in f.Pages.item("1", "values")[1] or "Letter" in f.Pages.item("1", "values")[1]

# Propiedades, sello y contraseña.
f.DocTitle_var.set("Nuevo título")
f.DocAuthor_var.set("Ana")
f.Meta_key_up()
out["check_meta"] = f.meta["title"] == "Nuevo título" and f.dirty
pick(6)
f.add_stamp({"text": "COPIA", "place": "top", "size": 18, "color": (1, 0, 0)})
out["check_stamp_row"] = "COPIA" in f.Pages.item("6", "values")[3]
answers = iter(["secreto", "secreto"])
sd.askstring = lambda *a, **k: next(answers)
f.set_password()
out["check_lock_label"] = f.password == "secreto" and f.Security.cget("text") == m.LOCK_ON

# Guardar como, con contraseña, y leerlo de vuelta.
saved = os.path.abspath("salida.pdf")
fd.asksaveasfilename = lambda **o: saved
out["check_saved"] = f.save(ask=True) is True and os.path.exists(saved) and not f.dirty
if not os.path.exists(saved):
    raise SystemExit("No se guardó: %r" % errors)
r = PdfReader(saved)
out["check_encrypted"] = r.is_encrypted and not r.decrypt("mala") and bool(r.decrypt("secreto"))
got = [p.extract_text().strip() for p in r.pages]
out["got"] = got
out["check_order"] = got[0] == "Uno" and got[1:3] == ["ExtraA", "ExtraB"] and got[3] == "Uno" and got[4] == "Tres" and got[5] == "Dos"
out["check_stamp_pdf"] = "COPIA" in got[6] and "Cuatro" in got[6]
out["check_rotation_pdf"] = r.pages[0].rotation == 270 and r.pages[3].rotation == 0 and r.pages[1].rotation == 0
out["check_meta_pdf"] = r.metadata.title == "Nuevo título" and r.metadata.author == "Ana"
out["check_title"] = f.root.title().startswith("salida.pdf")

# Guardar encima del mismo archivo.
pick(0)
f.BtnDelete_click()
f.save()
r = PdfReader(saved)
r.decrypt("secreto")
out["check_overwrite"] = len(r.pages) == 6 and not os.path.exists(saved + ".tmp")

# Extraer y dividir.
pick(1, 4)
f.extract(os.path.abspath("extracto.pdf"))
out["check_extract"] = texts("extracto.pdf") == ["ExtraB", "Dos"]
os.mkdir("partes")
f.split(os.path.abspath("partes"))
parts = sorted(os.listdir("partes"))
out["check_split"] = len(parts) == 6 and parts[0] == "salida_01.pdf" and texts(os.path.join("partes", parts[2])) == ["Uno"]

# Abrir el PDF protegido pide la contraseña.
sd.askstring = lambda *a, **k: "secreto"
f.dirty = False
out["check_open_locked"] = f.load(saved) and len(f.entries) == 6 and f.password == "secreto"
sd.askstring = lambda *a, **k: "mala"
before = len(errors)
out["check_bad_password"] = f.load(saved) is False and len(errors) == before + 1

# Sin pypdf: un aviso con la orden para instalarlo, sin errores.
m.pypdf = None
out["check_no_pypdf"] = f.ready() is False and "pip install pypdf" in str(errors[-1])
out["check_requires"] = m.REQUIRES == ["pypdf"]
f.form_close()
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str, ensure_ascii=False))
''';
