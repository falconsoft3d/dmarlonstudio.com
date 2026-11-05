import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Escritorio: el PDF y el Excel se generan de verdad (el diálogo de guardar
/// se sustituye por una ruta fija) y se comprueba su contenido.
const _desktop = r'''
import importlib.util, json, os, sys, zipfile, xml.dom.minidom
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
from tkinter import filedialog
paths = iter([os.path.abspath("out.pdf"), os.path.abspath("out.xlsx")])
filedialog.asksaveasfilename = lambda **k: next(paths)
out = {}
f = m.Form1()
f.root.withdraw()
f.root.update()
out["check_rows"] = len(f.Sales.get_children()) == 40
f.BtnPdf_click()
data = open("out.pdf", "rb").read()
out["check_pdf"] = data.startswith(b"%PDF-1.4") and b"%%EOF" in data[-20:] and b"/Count " in data
out["check_pdf_pages"] = b"/Count 2" in data or b"/Count 3" in data
f.BtnExcel_click()
z = zipfile.ZipFile("out.xlsx")
for n in z.namelist():
    if n.endswith((".xml", ".rels")):
        xml.dom.minidom.parseString(z.read(n))
sheet = z.read("xl/worksheets/sheet1.xml").decode()
out["check_xlsx"] = "xl/worksheets/sheet2.xml" in z.namelist() and "autoFilter" in sheet and "<v>" in sheet
out["check_status"] = "out.xlsx" in f.Status.cget("text")
f.root.destroy()
out["ok"] = all(v for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out))
''';

/// Web: los dos informes llegan al navegador como descargas.
const _web = r'''
import base64, importlib.util, json, os, re, sys
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
client = m.app.test_client()
page = client.get("/").get_data(as_text=True)
boot = json.loads(re.search(r'id="tk-boot">(.*?)</script>', page).group(1))
headers = {"X-DMS-CSRF": boot["csrf"], "X-DMS-Process": boot["process"]}
def event(widget):
    reply = client.post("/event", json={"widget": widget, "event": "command", "values": {}, "sid": boot["sid"]}, headers=headers)
    assert reply.status_code == 200, reply.status_code
    return reply.get_json()
out = {}
pdf = event("BtnPdf").get("downloads", [])
out["check_pdf"] = len(pdf) == 1 and pdf[0]["name"].endswith(".pdf") and base64.b64decode(pdf[0]["data"]).startswith(b"%PDF")
xlsx = event("BtnExcel").get("downloads", [])
out["check_xlsx"] = len(xlsx) == 1 and xlsx[0]["name"].endswith(".xlsx") and base64.b64decode(xlsx[0]["data"])[:2] == b"PK"
out["ok"] = all(v for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out))
''';

Future<String?> _python(String check) async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
    '/opt/homebrew/bin/python3',
    '/usr/local/bin/python3',
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

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('dms_rep_'));
  tearDown(() => tmp.delete(recursive: true));

  Future<String> build(String seed) async {
    final e = [
      ...tkExamples((s) => s),
      ...tkWebExamples((s) => s),
    ].firstWhere((e) => e.seed == seed);
    expect(e.design.problems(), isEmpty);
    final path = p.join(tmp.path, '$seed.py');
    await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
    final c = await Process.run('python3', ['-m', 'py_compile', path]);
    expect(c.exitCode, 0, reason: '${c.stderr}');
    return path;
  }

  Future<void> run(String py, String harness, String path) async {
    final r = await Process.run(py, ['-c', harness, path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
  }

  test('informes en escritorio: PDF y Excel de verdad', () async {
    final path = await build('reports');
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    await run(py, _desktop, path);
  });

  test('informes en web: se descargan', () async {
    final path = await build('web_reports');
    final py = await _python('import flask');
    if (py == null) return markTestSkipped('Sin Flask.');
    await run(py, _web, path);
  });
}
