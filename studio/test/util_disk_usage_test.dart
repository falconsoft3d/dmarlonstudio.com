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
    tmp = await Directory.systemTemp.createTemp('dms_disk_usage_');
  });

  tearDown(() async {
    // La carpeta sin permiso se vuelve a abrir para poder borrarla.
    final denied = Directory(p.join(tmp.path, 'tree', 'denied'));
    if (denied.existsSync() && !Platform.isWindows) {
      await Process.run('chmod', ['755', denied.path]);
    }
    await tmp.delete(recursive: true);
  });

  Future<String> build() async {
    final e = tkUtilDiskUsage(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el ejemplo existe', () {
    final e = tkUtilDiskUsage(id);
    expect(e.seed, 'disk_usage');
    expect(e.name, 'Espacio en disco');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
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

  test('de verdad en tkinter', () async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
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
import importlib.util, json, os, shutil, sys, threading, time
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
shown = []
asked = []
mb.showinfo = lambda *a, **k: "ok"
mb.showwarning = lambda *a, **k: shown.append(("warning",) + a)
mb.showerror = lambda *a, **k: shown.append(("error",) + a)
mb.askyesno = lambda *a, **k: asked.append(a) or True
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
posix = os.name == "posix"

def write(path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"x" * size)

root = os.path.abspath("tree")
write(os.path.join(root, "a", "big.bin"), 5000)
write(os.path.join(root, "a", "x.txt"), 100)
write(os.path.join(root, "a", "sub", "deep.dat"), 3000)
write(os.path.join(root, "b", "y.txt"), 200)
write(os.path.join(root, "b", "z.TXT"), 300)
write(os.path.join(root, "top.log"), 50)
write(os.path.join(root, "noext"), 10)
links = 0
try:
    os.symlink(os.path.join(root, "a"), os.path.join(root, "link_dir"))
    os.symlink(os.path.join(root, "a", "big.bin"), os.path.join(root, "link_file"))
    links = 2
except (OSError, NotImplementedError):
    pass
hard = False
try:
    os.link(os.path.join(root, "a", "big.bin"), os.path.join(root, "a", "hard.bin"))
    hard = True
except (OSError, AttributeError):
    pass
denied = False
if posix and os.geteuid() != 0:
    os.makedirs(os.path.join(root, "denied"))
    write(os.path.join(root, "denied", "secret.bin"), 999)
    os.chmod(os.path.join(root, "denied"), 0)
    denied = True

# ---- El análisis, sin ventana.
calls = []
r = m.scan(root, progress=lambda *a: calls.append(a))
out["files"], out["bytes"] = r.files, r.bytes
out["check_totals"] = r.files == 7 and r.bytes == 8660 and r.root.size == 8660
names = {c.name: c for c in r.root.children}
out["check_tree"] = names["a"].size == 8100 and names["a"].files == 3 and names["a"].children[0].name == "sub" and names["b"].size == 500
out["check_filelist"] = sorted(s for s, _ in names["b"].filelist) == [200, 300]
out["check_sorted"] = [c.name for c in r.root.children][:2] == ["a", "b"]
out["check_no_follow"] = r.links == links and "link_dir" not in names
out["check_hardlink"] = (r.hardlinks == 1) if hard else True
out["check_denied"] = (r.errors == 1 and names["denied"].denied) if denied else True
out["check_largest"] = [item[0] for item in r.largest] == [5000, 3000, 300, 200, 100, 50, 10] and os.path.basename(r.largest[0][1]) in ("big.bin", "hard.bin")
out["check_types"] = r.types[".txt"] == [3, 600] and r.types[""] == [1, 10] and r.types[".bin"] == [1, 5000]
out["check_progress"] = len(calls) >= 1 and calls[0][0] >= 0
stop = threading.Event()
stop.set()
r2 = m.scan(root, cancel=stop)
out["check_cancel"] = r2.cancelled and r2.files == 0
out["check_fmt"] = m.fmt_size(10) == "10 B" and m.fmt_size(1536).endswith(" KB") and m.fmt_pct(1, 4) == "25,0 %" and m.fmt_int(1234567) == "1.234.567"
out["check_family"] = m.family("Foto.JPG") == "images" and m.family("a.tar.gz") == "archives" and m.family("x.unknown") == "other"

# ---- El mapa: squarify reparte el área en proporción, dentro y sin solapes.
sizes = [6, 6, 4, 3, 2, 2, 1]
rects = m.squarify(sizes, 10, 20, 600, 400)
scale = 600 * 400 / float(sum(sizes))
inside = all(x >= 10 - 1e-6 and y >= 20 - 1e-6 and x + w <= 610 + 1e-6 and y + h <= 420 + 1e-6 for x, y, w, h in rects)
proportional = all(abs(w * h - s * scale) < 1e-6 for s, (x, y, w, h) in zip(sizes, rects))
def overlap(a, b):
    dx = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    dy = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return dx > 1e-6 and dy > 1e-6
apart = not any(overlap(a, b) for i, a in enumerate(rects) for b in rects[i + 1:])
ratio = max(max(w / h, h / w) for x, y, w, h in rects)
out["check_squarify"] = len(rects) == 7 and inside and proportional and apart and ratio < 4
out["check_squarify_zero"] = m.squarify([0, 0], 0, 0, 10, 10) == [(0, 0, 0.0, 0.0)] * 2 and len(m.squarify([5, 0, 1], 0, 0, 10, 10)) == 3

# ---- La ventana: analiza en otro hilo y llena listas y mapa.
f = m.Form1()
f.root.withdraw()
f.root.update()
out["check_disk"] = "%" in f.DiskInfo.cget("text") and float(f.DiskBar.cget("value")) > 0
f.Folder_var.set(root)
f.BtnScan_click()
out["check_busy"] = f.scanning() and str(f.BtnScan.cget("state")) == "disabled"
def wait():
    end = time.time() + 20
    while f.scanning() and time.time() < end:
        f.root.update()
        time.sleep(0.02)
    f.root.update()
wait()
out["check_done"] = not f.scanning() and f.result is not None and f.result.bytes == 8660
top = f.Folders.get_children("")
out["check_root_row"] = len(top) == 1 and f.Folders.item(top[0], "values")[1] == "100,0 %"
kids = f.Folders.get_children(top[0])
first = f.Folders.item(kids[0])
out["check_children"] = first["text"] == "a" and first["values"][1] == m.fmt_pct(8100, 8660)
out["check_files_here"] = any("[" in f.Folders.item(k, "text") for k in kids)
f.Folders.focus(kids[0])
f.Folders.item(kids[0], open=True)
f.Folders_open()
sub = [f.Folders.item(k, "text") for k in f.Folders.get_children(kids[0])]
out["check_expand"] = "sub" in sub and len(sub) == 2 and sub[0].startswith("[2 ")
out["check_largest_rows"] = len(f.Largest.get_children()) == 7 and f.Largest.item("l0", "values")[1] in ("big.bin", "hard.bin")
types = [f.Types.item(k, "values")[0] for k in f.Types.get_children()]
out["check_types_rows"] = types[0] == ".bin" and ".txt" in types and m.NO_EXT in types
legend = [f.Legend.itemcget(i, "text") for i in f.Legend.find_all() if f.Legend.type(i) == "text"]
out["check_legend"] = len(legend) == 8 and any(m.fmt_size(600) in t for t in legend)

# El mapa dibujado: todo dentro del lienzo; los archivos, en proporción.
W, H = f.canvas_size(f.Treemap)
res = f.result
a = [c for c in res.root.children if c.name == "a"][0]
b = [c for c in res.root.children if c.name == "b"][0]
sub_folder = a.children[0]
out["check_map_inside"] = len(f.drawn) >= 8 and all(0 <= x0 <= x1 <= W and 0 <= y0 <= y1 <= H for x0, y0, x1, y1 in f.drawn.values())
def area(key):
    x0, y0, x1, y1 = f.drawn[key]
    return (x1 - x0 + 1) * (y1 - y0 + 1)
ab = area(id(a)) / float(area(id(b)))
out["map_ratio"] = ab
out["check_map_proportional"] = 8100 / 500.0 * 0.6 < ab < 8100 / 500.0 * 1.6
def boxes_apart(keys):
    boxes = [f.drawn[k] for k in keys]
    return not any(min(p[2], q[2]) - max(p[0], q[0]) > 0 and min(p[3], q[3]) - max(p[1], q[1]) > 0
                   for i, p in enumerate(boxes) for q in boxes[i + 1:])
out["check_map_apart"] = boxes_apart([id(c) for c in res.root.children if id(c) in f.drawn])

class E:
    def __init__(self, x, y):
        self.x, self.y, self.x_root, self.y_root, self.widget = x, y, x, y, f.Treemap
def center(key):
    x0, y0, x1, y1 = f.drawn[key]
    return E((x0 + x1) // 2, (y0 + y1) // 2)

# Clic en el mapa: lo elige en el árbol y en la lista.
f.Treemap_click(center((id(sub_folder), "deep.dat")))
f.root.update()
deep = os.path.join(root, "a", "sub", "deep.dat")
out["check_click"] = m.node_path(f.current) == deep
out["check_click_tree"] = f.Folders.selection() == (f.iids[id(sub_folder)],)
out["check_click_list"] = f.Largest.selection() == (f.file_iids[deep],)
out["check_click_outline"] = f.Treemap.coords("selected") == [float(v) for v in f.drawn[(id(sub_folder), "deep.dat")]]
f.Treemap_motion(center((id(sub_folder), "deep.dat")))
out["check_hover"] = f.Status.cget("text") == m.SELECTED.format(deep, m.fmt_size(3000))
f.Treemap_leave()
out["check_leave"] = f.Status.cget("text") == f.message[0]
# Del árbol y de la lista al mapa.
f.Folders.selection_set(f.iids[id(b)])
f.root.update()
out["check_tree_to_map"] = f.current is b and f.Treemap.coords("selected") == [float(v) for v in f.drawn[id(b)]]
f.Pages.select(1)
f.Largest.selection_set("l1")
f.root.update()
out["check_list_to_map"] = m.node_path(f.current) == deep and f.Treemap.coords("selected") == [float(v) for v in f.drawn[(id(sub_folder), "deep.dat")]]

# Doble clic: entra en la carpeta; Subir vuelve.
f.Treemap_double(center((id(a), "x.txt")))
out["check_zoom"] = f.zoom is a and f.drawn[id(a)][:2] == (0, 0) and str(f.BtnUp.cget("state")) == "normal" and id(b) not in f.drawn
f.Treemap_double(center(id(sub_folder)))
out["check_zoom_deeper"] = f.zoom is sub_folder
f.BtnUp_click()
f.BtnUp_click()
out["check_zoom_up"] = f.zoom is res.root and str(f.BtnUp.cget("state")) == "disabled"

# ---- La Papelera (de pruebas: una carpeta, nunca la de verdad).
bin_dir = os.path.abspath("papelera")
os.mkdir(bin_dir)
trashed = []
def fake_trash(path):
    trashed.append(path)
    shutil.move(path, os.path.join(bin_dir, os.path.basename(path)))
m.move_to_trash = fake_trash
f.Treemap_click(center((id(a), "x.txt")))
f.BtnTrash_click()
x_txt = os.path.join(root, "a", "x.txt")
out["check_trash_asked"] = len(asked) == 1 and "x.txt" in asked[0][1]
out["check_trash_file"] = trashed == [x_txt] and os.path.exists(os.path.join(bin_dir, "x.txt")) and not os.path.exists(x_txt)
out["check_trash_sizes"] = res.bytes == 8560 and res.files == 6 and a.size == 8000 and res.root.size == 8560 and res.types[".txt"] == [2, 500]
out["check_trash_views"] = len(f.Largest.get_children()) == 6 and f.Folders.item("f0", "values")[0] == m.fmt_size(8560) and (id(a), "x.txt") not in f.drawn
out["check_trash_status"] = m.fmt_size(100) in f.Status.cget("text") and f.current is a
# Una carpeta entera.
f.Folders.selection_set(f.iids[id(b)])
f.root.update()
f.trash_selected()
out["check_trash_folder"] = os.path.isdir(os.path.join(bin_dir, "b")) and res.bytes == 8060 and b not in res.root.children
out["check_trash_folder_lists"] = ".txt" not in res.types and len(f.Largest.get_children()) == 4 and res.folders == r.folders - 1 and id(b) not in f.drawn
# Lo que nunca se mueve: la carpeta analizada, la personal, la raíz.
home = os.path.expanduser("~")
before = len(trashed)
f.select(res.root)
f.trash_selected()
out["check_refuse_root"] = len(trashed) == before and shown and shown[-1][0] == "warning"
out["check_protected"] = m.protected(home, root) and m.protected(os.path.dirname(home), root) and m.protected(os.path.abspath(os.sep), root) and m.protected(root, root) and not m.protected(deep, root)
# Si falla la Papelera, no cambia nada.
def broken(path):
    raise OSError("sin papelera")
m.move_to_trash = broken
f.Treemap_click(center((id(sub_folder), "deep.dat")))
f.trash_selected()
out["check_trash_error"] = shown[-1][0] == "error" and os.path.exists(deep) and res.bytes == 8060
# El menú contextual tiene las tres acciones.
out["check_menu"] = f.menu.index("end") == 3
# Mostrar en la carpeta y Abrir, con lo elegido.
opened = []
m.reveal = opened.append
m.open_path = opened.append
f.BtnReveal_click()
f.BtnOpen_click()
out["check_reveal_open"] = opened == [deep, deep]
# Cancelar a mitad: termina enseguida y la ventana sigue viva.
f.BtnScan_click()
f.BtnCancel_click()
wait()
out["check_cancel_ui"] = not f.scanning() and str(f.BtnScan.cget("state")) == "normal"
f.Folder_var.set(os.path.join(root, "nope"))
f.BtnScan_click()
out["check_not_folder"] = not f.scanning() and "nope" in f.Status.cget("text")
f.form_close()
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str, ensure_ascii=False))
''';
