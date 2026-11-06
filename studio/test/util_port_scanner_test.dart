import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Prueba el «Escáner de puertos» con tkinter de verdad, solo contra
/// 127.0.0.1: un servidor local que saluda (abierto, con su respuesta), un
/// puerto libre (cerrado), los rangos, la validación, Detener y el CSV.
const _harness = r'''
import csv, importlib.util, json, os, socket, sys, threading, time
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
warnings = []
m.messagebox.showwarning = lambda title, text, **k: warnings.append(text)
m.messagebox.showerror = lambda title, text, **k: warnings.append(text)
out = {}

# Rangos y listas.
out["check_parse"] = m.parse_ports("20-25, 80;443 25") == [20, 21, 22, 23, 24, 25, 80, 443]
out["check_parse_reverse"] = m.parse_ports("10-8") == [8, 9, 10]
bad = []
for text in ("", "abc", "0", "70000", "1-2-3", "80-"):
    try:
        m.parse_ports(text)
    except ValueError as error:
        bad.append(str(error))
out["check_parse_errors"] = len(bad) == 6 and bad[0] == m.NO_PORTS
out["check_presets"] = len(m.parse_ports(m.SPECS[0])) >= 25 and len(m.parse_ports(m.SPECS[2])) == 65535

# Un servidor que saluda, como SSH o FTP.
server = socket.socket()
server.bind(("127.0.0.1", 0))
server.listen(50)
open_port = server.getsockname()[1]
def serve():
    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            return
        try:
            conn.sendall(b"SSH-2.0-DMSTest_1.0\r\n")
            time.sleep(0.05)
        finally:
            conn.close()
threading.Thread(target=serve, daemon=True).start()
free = socket.socket()
free.bind(("127.0.0.1", 0))
closed_port = free.getsockname()[1]
free.close()

state, text = m.probe(socket.AF_INET, "127.0.0.1", open_port, 1.0, banner=True)
out["check_probe_open"] = state == "open" and text == "SSH-2.0-DMSTest_1.0"
out["check_probe_closed"] = m.probe(socket.AF_INET, "127.0.0.1", closed_port, 1.0)[0] != "open"
out["check_resolve"] = m.resolve("localhost")[1] in ("127.0.0.1", "::1")

f = m.Form1()
f.root.withdraw()
f.root.update()

def wait(seconds=20):
    end = time.time() + seconds
    while f.scan is not None and time.time() < end:
        f.root.update()
        time.sleep(0.01)
    f.root.update()
    return f.scan is None

# Atajos de puertos.
f.Preset.current(1)
f.Preset_select()
out["check_preset_select"] = f.Ports_var.get() == "1-1024"
f.Ports_var.set("80,81")
f.Ports_key_up()
out["check_preset_custom"] = f.Preset.current() == 3

# Validación: nada empieza y el aviso dice qué falla.
for field, value, message in (
    ("Ports_var", "70000", m.OUT_OF_RANGE.format("70000")),
    ("Timeout_var", "abc", m.BAD_TIMEOUT),
    ("Workers_var", "0", m.BAD_WORKERS),
    ("Host_var", "  ", m.BAD_HOST),
):
    f.Host_var.set("127.0.0.1")
    f.Ports_var.set("80")
    f.Timeout_var.set("0,5")
    f.Workers_var.set("10")
    getattr(f, field).set(value)
    warnings.clear()
    f.BtnScan_click()
    out["check_invalid_" + field] = f.scan is None and warnings == [message]

# El escaneo de verdad: el abierto sale, el cerrado no.
f.Host_var.set("127.0.0.1")
f.Ports_var.set("%d,%d" % (open_port, closed_port))
f.Timeout_var.set("0.5")
f.Workers_var.set("10")
f.BtnScan_click()
out["check_running"] = f.scan is not None and str(f.BtnStop.cget("state")) == "normal"
out["check_finished"] = wait()
rows = [f.Results.item(i, "values") for i in f.Results.get_children()]
out["rows"] = rows
out["check_open_only"] = len(rows) == 1 and rows[0][0] == str(open_port) and rows[0][1] == m.OPEN
out["check_banner"] = rows and rows[0][3] == "SSH-2.0-DMSTest_1.0"
out["check_summary"] = "127.0.0.1" in f.Summary.cget("text") and str(f.BtnScan.cget("state")) == "normal"
out["check_status_done"] = f.Status.cget("text").startswith(m.FINISHED.split("{")[0])

# Con los cerrados a la vista salen los dos, en orden.
f.ShowClosed_var.set(1)
f.ShowClosed_click()
ports = [int(f.Results.item(i, "values")[0]) for i in f.Results.get_children()]
out["check_show_closed"] = ports == sorted([open_port, closed_port])

# CSV.
target = os.path.join(os.getcwd(), "ports.csv")
f.ExportFile.execute = lambda: target
f.BtnExport_click()
with open(target, encoding="utf-8-sig", newline="") as source:
    lines = list(csv.reader(source))
out["check_csv"] = (
    len(lines) == 3 and lines[0][0] == m.HEADERS[0]
    and lines[1][2] == str(min(open_port, closed_port))
    and any(line[3] == m.OPEN and line[5] == "SSH-2.0-DMSTest_1.0" for line in lines[1:])
)

# Detener a mitad de todos los puertos.
f.ShowClosed_var.set(0)
f.Ports_var.set("1-65535")
f.Workers_var.set("20")
f.BtnScan_click()
end = time.time() + 0.4
while time.time() < end:
    f.root.update()
    time.sleep(0.01)
f.BtnStop_click()
out["check_stopped"] = wait() and 0 < f.checked < 65535
out["check_stopped_status"] = f.Status.cget("text") == m.STOPPED.format(f.open_count(), f.checked)

# Un nombre que no existe: aviso, sin colgar la ventana.
f.Host_var.set("no-such-host.invalid")
f.Ports_var.set("80")
warnings.clear()
f.BtnScan_click()
out["check_unknown_host"] = wait() and len(warnings) == 1 and "no-such-host.invalid" in warnings[0]

f.form_close()
server.close()
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
    tmp = await Directory.systemTemp.createTemp('dms_ports_');
    example = tkUtilPortScanner((s) => s);
    path = p.join(tmp.path, 'app.py');
    await File(
      path,
    ).writeAsString(TkCodegen.generate(example.design, example.code));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('el diseño es correcto y cabe en la pantalla', () {
    expect(example.seed, 'port_scanner');
    expect(example.name, 'Escáner de puertos');
    expect(example.design.problems(), isEmpty);
    expect(example.design.connections, isEmpty);
    expect(example.design.width, lessThanOrEqualTo(1100));
    expect(example.design.height, lessThanOrEqualTo(720));
    final note = example.design.widgets.firstWhere((w) => w.name == 'Warning');
    expect(note.props['text'], startsWith('Escanee solo equipos propios'));
  });

  test('genera Python válido', () async {
    final py = await _python() ?? 'python3';
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test(
    'escanea 127.0.0.1 de verdad en tkinter',
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
