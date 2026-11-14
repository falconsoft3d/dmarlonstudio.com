// 20pdf: el ejemplo, el Python que genera y, con un Python que tenga las
// bibliotecas (DMS_TK_PYTHON), las 20 herramientas y la ventana de verdad.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_20pdf_');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<String> build([String Function(String) t = id]) async {
    final e = tkUtil20pdf(t);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el ejemplo existe, con las 20 herramientas', () {
    final e = tkUtil20pdf(id);
    expect(e.seed, 'pdf20');
    expect(e.design.problems(), isEmpty);
    final names = {for (final w in e.design.widgets) w.name};
    for (var i = 1; i <= 20; i++) {
      expect(names, contains('BtnT$i'));
      expect(e.code, contains('def BtnT${i}_click('));
    }
    expect(names, containsAll(['Files', 'Opts', 'Preview', 'BtnRun', 'Status']));
    expect(e.code, isNot(contains('# @TEXTS')));
  });

  test('genera Python válido (también en inglés)', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    var r = await Process.run(py, ['-m', 'py_compile', await build()]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    r = await Process.run(py, ['-m', 'py_compile', await build((s) => catalog[s] ?? s)]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('arranca como la app de verdad (con la ventana oculta)', () async {
    final py = await _python('import tkinter, pypdf, pypdfium2, reportlab, docx, openpyxl, pptx, pdfminer, pyhanko');
    if (py == null) return markTestSkipped('Sin Python con las bibliotecas (DMS_TK_PYTHON).');
    final path = await build();
    // Como el lanzador de las demos: el programa entero como __main__, sin
    // tocar nada antes; la ventana se esconde y se cierra a los 2 segundos.
    const run = r'''
import runpy, sys, tkinter as tk
_init = tk.Tk.__init__
def init(self, *a, **k):
    _init(self, *a, **k)
    self.withdraw()
    self.after(2000, self.destroy)
tk.Tk.__init__ = init
runpy.run_path(sys.argv[1], run_name="__main__")
print("arranque ok")
''';
    final r = await Process.run(py, ['-c', run, path]);
    expect('${r.stdout}', contains('arranque ok'), reason: '${r.stdout}\n${r.stderr}');
  });

  test(
    'de verdad: las 20 herramientas y la ventana',
    () async {
      final py = await _python('import tkinter, pypdf, pypdfium2, reportlab, docx, openpyxl, pptx, pdfminer, pyhanko');
      if (py == null) return markTestSkipped('Sin Python con las bibliotecas (DMS_TK_PYTHON).');
      final path = await build();
      final r = await Process.run(py, ['-c', _harness, path, tmp.path]);
      final last = '${r.stdout}'.trim().split('\n').last;
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode(last) as Map;
      expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
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
import importlib.util, io, json, os, sys, tempfile, time, traceback
import tkinter.messagebox as mb
mb.showinfo = lambda *a, **k: "ok"
mb.showerror = lambda *a, **k: None
spec = importlib.util.spec_from_file_location("app", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
m = vars(mod)
os.environ["DMS_20PDF_CONFIG"] = os.path.join(sys.argv[2], "config")
work = sys.argv[2]
FAILS = []
out = os.path.join(work, "out"); os.makedirs(out)
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
pdf = os.path.join(work, "factura.pdf")
c = canvas.Canvas(pdf, pagesize=A4)
for p in range(3):
    c.setFont("Helvetica-Bold", 22); c.drawString(72, 760, "Factura %d de 2026" % (p + 1))
    c.setFont("Helvetica", 12); c.drawString(72, 720, "Cliente: Juan Pérez · DNI 12345678Z")
    c.drawString(72, 700, "Importe total: 1.250,00 euros"); c.showPage()
c.save()
import docx
from docx.shared import Pt
d = docx.Document(); d.add_heading("Informe trimestral", 0); d.add_heading("Ventas", 1)
p = d.add_paragraph("Las ventas "); p.add_run("subieron").bold = True; p.add_run(" un 12 %.")
d.add_paragraph("Primera idea", style="List Bullet"); d.add_paragraph("Segunda idea", style="List Bullet")
t = d.add_table(rows=2, cols=2); t.cell(0,0).text="Mes"; t.cell(0,1).text="Total"; t.cell(1,0).text="Enero"; t.cell(1,1).text="300"
docx_path = os.path.join(work, "informe.docx"); d.save(docx_path)
import openpyxl
wb = openpyxl.Workbook(); ws = wb.active; ws.title = "Ventas"
ws.append(["Producto", "Unidades", "Precio"]); [ws.append(["Artículo %d" % i, i * 3, i * 1.5]) for i in range(1, 30)]
xlsx = os.path.join(work, "ventas.xlsx"); wb.save(xlsx)
from PIL import Image, ImageDraw, ImageFont
img = Image.new("RGB", (1240, 1754), "white"); dr = ImageDraw.Draw(img)
try: f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 48)
except Exception: f = ImageFont.load_default()
dr.text((120, 200), "Contrato de alquiler escaneado", fill="black", font=f)
dr.text((120, 300), "Firmado en Madrid el 3 de marzo", fill="black", font=f)
scan = os.path.join(work, "escaneado.pdf"); img.save(scan, "PDF", resolution=150)
R = {}
def run(name, fn, files, opts):
    try:
        r = fn(files, out, opts); R[name] = r; print("OK  ", name, "→", [os.path.basename(x) for x in r["files"]][:4], r["message"][:80])
    except Exception as e:
        print("FAIL", name, e); traceback.print_exc(limit=3); FAILS.append(name)
run("word2pdf", m["word_to_pdf"], [docx_path], {"engine": "basic"})
run("pdf2word", m["pdf_to_word"], [pdf], {})
run("excel2pdf", m["excel_to_pdf"], [xlsx], {})
run("pdf2img", m["pdf_to_images"], [pdf], {"format": "png", "dpi": 72})
run("pdf2ppt", m["pdf_to_pptx"], [pdf], {"mode": "image"})
run("pdf2ppt_text", m["pdf_to_pptx"], [pdf], {"mode": "text"})
run("edit", m["edit_pdf"], [pdf], {"edits": [{"page": 0, "type": "cover", "x": 70, "y": 695, "w": 300, "h": 18}, {"page": 0, "type": "text", "x": 72, "y": 700, "text": "Importe total: 990,00 euros", "size": 12}]})
run("watermark", m["watermark"], [pdf], {"text": "CONFIDENCIAL"})
run("numbers", m["page_numbers"], [pdf], {"format": "Página {n} de {total}"})
run("rotate", m["rotate_pages"], [pdf], {"angle": 90, "pages": "2"})
run("annotate", m["annotate"], [pdf], {"annotations": [{"page": 0, "type": "note", "x0": 400, "y0": 700, "x1": 420, "y1": 720, "text": "Revisar"}, {"page": 0, "type": "highlight", "x0": 70, "y0": 698, "x1": 300, "y1": 714}, {"page": 1, "type": "ellipse", "x0": 60, "y0": 740, "x1": 330, "y1": 790, "color": "#ff0000"}, {"page": 1, "type": "line", "x0": 72, "y0": 690, "x1": 300, "y1": 690}, {"page": 2, "type": "text", "x0": 72, "y0": 600, "x1": 300, "y1": 630, "text": "Pagado"}]})
run("merge", m["merge"], [pdf, R["excel2pdf"]["files"][0]], {})
run("split", m["split"], [pdf], {"mode": "each"})
run("organize", m["organize"], [pdf], {"order": [{"src": 0, "page": 2}, {"src": -1}, {"src": 0, "page": 0, "rot": 180}]})
run("extract", m["extract"], [pdf], {"pages": "1,3"})
run("protect", m["protect"], [pdf], {"password_new": "clave123", "allow_copy": False})
run("unlock", m["unlock"], [R["protect"]["files"][0]], {"password": "clave123", "authorized": True})
run("sign", m["sign"], [pdf], {"name": "Marlon Prueba", "reason": "Aprobado", "page": 0, "box": [300, 60, 540, 130]})
run("redact", m["redact"], [pdf], {"terms": ["12345678Z", "Juan Pérez"], "boxes": [{"page": 2, "x0": 70, "y0": 695, "x1": 320, "y1": 712}]})
run("compress", m["compress"], [scan], {"level": "strong"})
run("ocr", m["ocr"], [scan], {"lang": "es"})
from pypdf import PdfReader
def chk(c, w):
    print(("  ✓ " if c else "  ✗ ") + w)
    if not c:
        FAILS.append(w)
chk(len(PdfReader(R["word2pdf"]["files"][0]).pages) >= 1 and "Informe" in PdfReader(R["word2pdf"]["files"][0]).pages[0].extract_text(), "Word→PDF con texto")
dd = docx.Document(R["pdf2word"]["files"][0]); chk("Factura 1" in "\n".join(p.text for p in dd.paragraphs), "PDF→Word con texto")
chk("Artículo 29" in "".join(p.extract_text() for p in PdfReader(R["excel2pdf"]["files"][0]).pages), "Excel→PDF con todas las filas")
chk(len(R["pdf2img"]["files"]) == 3, "tres imágenes")
import pptx; chk(len(pptx.Presentation(R["pdf2ppt"]["files"][0]).slides) == 3, "tres diapositivas")
chk("990,00" in PdfReader(R["edit"]["files"][0]).pages[0].extract_text(), "texto editado")
chk("CONFIDENCIAL" in PdfReader(R["watermark"]["files"][0]).pages[1].extract_text(), "marca de agua")
chk("Página 2 de 3" in PdfReader(R["numbers"]["files"][0]).pages[1].extract_text(), "numeración")
chk(PdfReader(R["rotate"]["files"][0]).pages[1].rotation == 90, "rotación")
chk(len(PdfReader(R["annotate"]["files"][0]).pages[0]["/Annots"]) == 2, "anotaciones")
chk(len(PdfReader(R["merge"]["files"][0]).pages) >= 4, "unir")
chk(len(R["split"]["files"]) == 3, "dividir")
o = PdfReader(R["organize"]["files"][0]); chk(len(o.pages) == 3 and "Factura 3" in o.pages[0].extract_text() and o.pages[2].rotation == 180, "organizar")
chk(len(PdfReader(R["extract"]["files"][0]).pages) == 2, "extraer")
p = PdfReader(R["protect"]["files"][0]); chk(p.is_encrypted and p.decrypt("clave123") and not PdfReader(R["protect"]["files"][0]).decrypt("mal"), "proteger AES-256")
chk(not PdfReader(R["unlock"]["files"][0]).is_encrypted, "desbloquear")
v = m["verify_signatures"](R["sign"]["files"][0]); print("    firmas:", v); chk(v and v[0][1] and v[0][0] == "Marlon Prueba", "firma íntegra")
t = "".join(pg.extract_text() or "" for pg in PdfReader(R["redact"]["files"][0]).pages); chk("12345678Z" not in t and "Juan" not in t, "censurado sin rastro")
print("   ", R["compress"]["message"])
if sys.platform == "darwin":
    t = PdfReader(R["ocr"]["files"][0]).pages[0].extract_text(); print("    OCR:", t[:80].replace("\n", " | ")); chk("alquiler" in t.lower(), "OCR encuentra el texto")
chk(m["parse_ranges"]("1-3, 5, 8-", 9) == [0, 1, 2, 4, 7, 8], "páginas: 1-3, 5, 8-")
chk(len(m["TOOLS"]) == 20, "veinte herramientas")
# ---- La ventana, sin mostrarla.
f = m["Form1"]()
f.root.withdraw()
f.root.update()
chk(f.LblTool.cget("text") == m["T"]("TOOL_WORD2PDF"), "empieza en Word a PDF")
f.BtnT13_click()
chk(f.tool == 12 and "▶" in f.BtnRun.cget("text"), "elegir Organizar")
f.add_files([pdf])
f.root.update()
chk(len(f.order) == 3 and f.Files.size() == 1, "las páginas en miniatura")
f.picked = {2}
f.org_move(-1); f.org_move(-1)
chk(f.order[0]["page"] == 2, "mover la última al principio")
f.org_rotate(); f.org_blank()
f.BtnRun_click(); f.wait()
o = PdfReader(f.last_result["files"][0]); chk(len(o.pages) == 4 and o.pages[0].rotation == 90, "guardar el PDF ordenado")
f.BtnT6_click()   # Editar
f.add_files([pdf]); f.root.update(); f.show(); f.root.update()
chk(f.view is not None and f.pages == 3, "vista previa de la página")
cx, cy = f.to_canvas(72, 600)
class E: pass
e = E(); e.x, e.y = cx, cy
f.vars["text"].set("Añadido en la vista")
f.Preview_mouse_down(e)
chk(len(f.marks) == 1 and f.marks[0]["type"] == "text", "clic: texto")
f.BtnRun_click(); f.wait()
chk("Añadido en la vista" in PdfReader(f.last_result["files"][0]).pages[0].extract_text(), "texto puesto desde la vista")
f.BtnT18_click()  # Censurar
f.add_files([pdf]); f.root.update(); f.show(); f.root.update()
a = E(); a.x, a.y = f.to_canvas(60, 730); b = E(); b.x, b.y = f.to_canvas(400, 690)
f.Preview_mouse_down(a); f.Preview_drag(b); f.Preview_mouse_up(b)
chk(len(f.marks) == 1, "arrastrar: un recuadro")
f.BtnRun_click(); f.wait()
chk("Juan" not in (PdfReader(f.last_result["files"][0]).pages[0].extract_text() or ""), "censurado desde la vista")
f.BtnT15_click()  # Proteger: contraseñas distintas
f.add_files([pdf]); f.vars["password_new"].set("a1"); f.vars["password_again"].set("b2")
f.done = "sin tocar"
f.BtnRun_click(); f.root.update()
chk(not f.busy and f.done == "sin tocar", "contraseñas distintas: no se hace")
f.BtnT1_click()
f.add_files([pdf])
chk(f.files == [], "un PDF no vale para Word a PDF")
f.root.destroy()
print(json.dumps({"ok": not FAILS, "fails": FAILS}))

''';
