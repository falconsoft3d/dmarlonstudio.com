import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_next.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample example(String seed) =>
    tkNextExamples(id).firstWhere((e) => e.seed == seed);

Future<String?> _node() async {
  for (final n in ['/opt/homebrew/bin/node', '/usr/local/bin/node', 'node']) {
    try {
      final r = await Process.run(n, ['--version']);
      if (r.exitCode == 0) return n;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

void main() {
  test('Next.js: destino JavaScript, proyecto y módulos', () async {
    final d = TkDesign(target: tkTargetNext);
    expect(d.isNext && d.isJs, isTrue);
    expect(tkUnitOf(d), isA<JsUnit>());
    expect(tkTargetLabel(tkTargetNext), 'Web (Next.js)');
    final e = example('next_tasks');
    final files = TkNext.files(e.design, e.code, name: e.name);
    final pkg = jsonDecode(files['package.json']!) as Map;
    expect(pkg['scripts']['dev'], 'next dev --webpack');
    expect((pkg['dependencies'] as Map).keys, containsAll(['next', 'react', 'react-dom']));
    expect(files['app/page.js'], contains('ssr: false'));
    // El código del usuario conserva sus números de línea.
    final unit = files['app/dms/Form1.js']!.split('\n');
    final original = e.code.split('\n');
    expect(unit.first, startsWith('import { FormDesign } from "./design"; '));
    for (var i = 1; i < original.length - 1; i++) {
      expect(unit[i], original[i], reason: 'línea ${i + 1}');
    }
    expect(files['app/dms/runtime.js'], contains('export { DmsForm'));
    final node = await _node();
    if (node == null) return;
    final tmp = await Directory.systemTemp.createTemp('dms_next_js_');
    addTearDown(() => tmp.delete(recursive: true));
    for (final f in ['app/dms/runtime.js', 'app/dms/design.js', 'app/dms/Form1.js', 'app/dms/host.js']) {
      final path = p.join(tmp.path, '${p.basenameWithoutExtension(f)}.mjs');
      await File(path).writeAsString(files[f]!);
      final r = await Process.run(node, ['--check', path]);
      expect(r.exitCode, 0, reason: '$f: ${r.stderr}');
    }
  });

  test('de verdad: next dev y la página en Chromium', () async {
    final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
    final chromium = Platform.environment['DMS_CHROMIUM'];
    final node = await _node();
    if (runtime == null || chromium == null || node == null ||
        !File(p.join(runtime, 'node_modules', 'next', 'package.json')).existsSync()) {
      return markTestSkipped('Sin DMS_ELECTRON_RUNTIME (con Next.js) y DMS_CHROMIUM.');
    }
    TkElectronRuntime.dirOverride = runtime;
    final tmp = await Directory.systemTemp.createTemp('dms_next_run_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = example('next_tasks');
    final root = Directory(p.join(tmp.path, 'build', 'nextjs'));
    for (final f in TkNext.files(e.design, e.code, name: e.name).entries) {
      File(p.join(root.path, f.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(f.value);
    }
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: e.name,
        source: e.code,
        file: p.join(root.path, 'app', 'dms', 'Form1.js'),
        next: true,
      ),
    );
    addTearDown(run.stop);
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (run.url == null && run.running && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(run.url, isNotNull, reason: run.lines.join('\n'));
    final check = File(p.join(tmp.path, 'check.js'))..writeAsStringSync('''
(async () => {
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  for (let i = 0; i < 100 && !document.getElementById("NewTask"); i++) await wait(200);
  const input = document.getElementById("NewTask");
  const set = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;
  for (const text of ["pan", "leche"]) {
    set.call(input, text);
    input.dispatchEvent(new Event("input", { bubbles: true }));
    await wait(30);
    document.getElementById("Add").click();
    await wait(60);
  }
  const list = document.getElementById("Tasks");
  list.options[0].selected = true;
  list.dispatchEvent(new Event("change", { bubbles: true }));
  await wait(30);
  document.getElementById("Done").click();
  await wait(60);
  return {
    host: DMS_HOST.kind,
    items: Array.from(list.options, (o) => o.textContent),
    status: document.getElementById("Status").textContent,
    stored: JSON.parse(localStorage.getItem("dms:tasks")).length,
  };
})()
''');
    final cdp = File(p.join(tmp.path, 'cdp.mjs'))..writeAsStringSync(_cdp);
    const port = 9353;
    final browser = await Process.start(chromium, [
      '--headless=new',
      '--disable-gpu',
      '--user-data-dir=${p.join(tmp.path, 'profile')}',
      '--remote-debugging-port=$port',
    ]);
    addTearDown(browser.kill);
    final r = await Process.run(node, [cdp.path, '$port', run.url!, check.path])
        .timeout(const Duration(seconds: 90));
    final line = '${r.stdout}'.split('\n').firstWhere(
      (l) => l.startsWith('RESULT '),
      orElse: () => '${r.stdout}${r.stderr}',
    );
    expect(line, startsWith('RESULT '));
    final out = jsonDecode(line.substring(7)) as Map;
    expect(out['host'], 'web');
    expect(out['items'], ['✓ pan', 'leche']);
    expect(out['status'], '1 pendientes de 2');
    expect(out['stored'], 2);
  });
}

const _cdp = r'''
import fs from "node:fs";
const [port, url, scriptFile] = process.argv.slice(2);
const base = `http://127.0.0.1:${port}`;
for (let i = 0; i < 80; i++) {
  try { await (await fetch(base + "/json/version")).json(); break; } catch { await new Promise((r) => setTimeout(r, 250)); }
}
const target = await (await fetch(base + "/json/new?" + url, { method: "PUT" })).json();
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let id = 0;
const pending = new Map();
ws.addEventListener("message", (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); }
});
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await new Promise((r) => setTimeout(r, 2000));
const r = await send("Runtime.evaluate", { expression: fs.readFileSync(scriptFile, "utf8"), awaitPromise: true, returnByValue: true });
console.log("RESULT " + JSON.stringify(r.result && r.result.result ? r.result.result.value : r));
ws.close();
process.exit(0);
''';
