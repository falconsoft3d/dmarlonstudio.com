import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:dmarlon_studio/code/tk_chrome.dart';
import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample example(String seed) =>
    tkChromeExamples(id).firstWhere((e) => e.seed == seed);

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

/// Escribe la extensión de [e] (con React) y su vista previa en [root].
Future<String> _write(TkExample e, String root, String runtime) async {
  final ext = Directory(p.join(root, 'build', 'extension'))
    ..createSync(recursive: true);
  for (final f in TkChrome.files(e.design, e.code, name: e.name).entries) {
    File(p.join(ext.path, f.key)).writeAsStringSync(f.value);
  }
  final preview = Directory(p.join(root, 'build', 'extension-preview'))
    ..createSync(recursive: true);
  for (final f in TkChrome.preview(e.design, e.name).entries) {
    File(p.join(preview.path, f.key)).writeAsStringSync(f.value);
  }
  File(
    p.join(ext.path, 'react.js'),
  ).writeAsStringSync(TkChrome.reactBundle(p.join(runtime, 'node_modules')));
  return ext.path;
}

void main() {
  test('destino Chrome: JavaScript, sin menú y su manifiesto', () {
    final d = TkDesign(target: tkTargetChrome);
    expect(d.isJs && d.isChrome && !d.isElectron, isTrue);
    expect(tkUnitOf(d), isA<JsUnit>());
    d.widgets.add(
      TkWidget(kind: 'Menu', name: 'Menu1', x: 0, y: 0, width: 24, height: 24),
    );
    expect(d.problems().single, contains('Chrome'));
    expect(
      TkDesign.parse(TkDesign(target: tkTargetChrome).toJsonString()).isChrome,
      isTrue,
    );
    final e = example('chrome_notes');
    final files = TkChrome.files(
      e.design,
      e.code,
      name: e.name,
      description: 'x',
    );
    final manifest = jsonDecode(files['manifest.json']!) as Map;
    expect(manifest['manifest_version'], 3);
    expect(manifest['action']['default_popup'], 'popup.html');
    expect(
      manifest['permissions'],
      containsAll(['storage', 'activeTab', 'scripting']),
    );
    expect(files['popup.html'], contains('<script src="react.js"></script>'));
    expect(files['popup.html'], contains('width: 360px; height: 380px;'));
  });

  test('los ejemplos generan JavaScript válido', () async {
    final node = await _node();
    final tmp = await Directory.systemTemp.createTemp('dms_chrome_js_');
    addTearDown(() => tmp.delete(recursive: true));
    for (final e in tkChromeExamples(id)) {
      expect(e.design.isChrome, isTrue, reason: e.seed);
      expect(e.design.problems(), isEmpty, reason: e.seed);
      if (node == null) continue;
      final all = {
        ...TkChrome.files(e.design, e.code, name: e.name),
        ...{
          for (final f in TkChrome.preview(e.design, e.name).entries)
            'preview_${f.key}': f.value,
        },
      };
      for (final f in all.entries.where((f) => f.key.endsWith('.js'))) {
        final path = p.join(tmp.path, '${e.seed}_${f.key}');
        await File(path).writeAsString(f.value);
        final r = await Process.run(node, ['--check', path]);
        expect(r.exitCode, 0, reason: '${e.seed}/${f.key}: ${r.stderr}');
      }
    }
  });

  test('de verdad: vista previa en Electron (Notas por sitio)', () async {
    final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
    if (runtime == null || !Directory(runtime).existsSync()) {
      return markTestSkipped('Sin DMS_ELECTRON_RUNTIME (Electron y React).');
    }
    TkElectronRuntime.dirOverride = runtime;
    final tmp = await Directory.systemTemp.createTemp('dms_chrome_run_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = example('chrome_notes');
    final ext = await _write(e, tmp.path, runtime);
    final node = await _node();
    if (node != null) {
      final r = await Process.run(node, ['--check', p.join(ext, 'react.js')]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
    }
    final script = File(p.join(tmp.path, 'check.js'))
      ..writeAsStringSync('''
(async () => {
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  const \$ = (id) => document.getElementById(id);
  await wait(200);
  const out = { host: DMS_HOST.kind, site: \$("Site").textContent, address: \$("Address").textContent };
  const area = \$("Note");
  Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, "value").set.call(area, "volver mañana");
  area.dispatchEvent(new Event("input", { bubbles: true }));
  await wait(30);
  \$("Save").click();
  await wait(150);
  out.status = \$("Status").textContent;
  out.sites = Array.from(\$("Sites").options, (o) => o.textContent);
  out.stored = JSON.parse(localStorage.getItem("dms:notes"));
  return out;
})()
''');
    TkElectronRuntime.extraEnv = {'DMSTUDIO_ELECTRON_TEST': script.path};
    addTearDown(() => TkElectronRuntime.extraEnv = const {});
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: e.name,
        source: e.code,
        file: p.join(ext, 'Form1.js'),
        electron: true,
        chrome: true,
      ),
    );
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (run.running && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final line = run.lines.firstWhere(
      (l) => l.startsWith('DMSTUDIO_TEST '),
      orElse: () => run.lines.join('\n'),
    );
    expect(line, startsWith('DMSTUDIO_TEST '));
    final out = jsonDecode(line.substring('DMSTUDIO_TEST '.length)) as Map;
    expect(out['host'], 'preview');
    expect(out['site'], 'Example Domain');
    expect(out['address'], 'example.com');
    expect(out['status'], 'Nota guardada.');
    expect(out['sites'], ['example.com']);
    expect(out['stored'], {'example.com': 'volver mañana'});
  });

  test('de verdad en Chromium: la extensión cargada', () async {
    final chromium = Platform.environment['DMS_CHROMIUM'];
    final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
    final node = await _node();
    if (chromium == null || runtime == null || node == null) {
      return markTestSkipped('Sin DMS_CHROMIUM y DMS_ELECTRON_RUNTIME.');
    }
    final tmp = await Directory.systemTemp.createTemp('dms_chromium_');
    addTearDown(() => tmp.delete(recursive: true));
    final ext = await _write(example('chrome_notes'), tmp.path, runtime);
    final real = Directory(ext).resolveSymbolicLinksSync();
    // El id de una extensión sin empaquetar sale de su ruta.
    final hash = sha256.convert(utf8.encode(real)).toString().substring(0, 32);
    final extId = String.fromCharCodes(
      hash.codeUnits.map(
        (c) => 'a'.codeUnitAt(0) + int.parse(String.fromCharCode(c), radix: 16),
      ),
    );
    final cdp = File(p.join(tmp.path, 'cdp.mjs'))..writeAsStringSync(_cdp);
    final check = File(p.join(tmp.path, 'check.js'))
      ..writeAsStringSync('''
(async () => {
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  await wait(300);
  const area = document.getElementById("Note");
  Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, "value").set.call(area, "en chrome");
  area.dispatchEvent(new Event("input", { bubbles: true }));
  await wait(30);
  document.getElementById("Save").click();
  await wait(300);
  const notes = (await chrome.storage.local.get("notes")).notes || {};
  return { host: DMS_HOST.kind, saved: Object.values(notes), badge: await chrome.action.getBadgeText({}) };
})()
''');
    const port = 9347;
    final browser = await Process.start(chromium, [
      '--headless=new',
      '--disable-gpu',
      '--user-data-dir=${p.join(tmp.path, 'profile')}',
      '--load-extension=$real',
      '--disable-extensions-except=$real',
      '--remote-debugging-port=$port',
    ]);
    addTearDown(browser.kill);
    final r = await Process.run(node, [
      cdp.path,
      '$port',
      'chrome-extension://$extId/popup.html',
      check.path,
    ]).timeout(const Duration(seconds: 60));
    final line = '${r.stdout}'
        .split('\n')
        .firstWhere(
          (l) => l.startsWith('RESULT '),
          orElse: () => '${r.stdout}${r.stderr}',
        );
    expect(line, startsWith('RESULT '));
    final out = jsonDecode(line.substring(7)) as Map;
    expect(out['host'], 'chrome');
    expect(out['saved'], ['en chrome']);
    expect(out['badge'], '1');
  });
}

/// Abre una página por el protocolo de DevTools y evalúa un guion.
const _cdp = r'''
import fs from "node:fs";
const [port, url, scriptFile] = process.argv.slice(2);
const base = `http://127.0.0.1:${port}`;
for (let i = 0; i < 80; i++) {
  try { await (await fetch(base + "/json/version")).json(); break; } catch { await new Promise((r) => setTimeout(r, 250)); }
}
await new Promise((r) => setTimeout(r, 800));
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
await new Promise((r) => setTimeout(r, 1200));
const r = await send("Runtime.evaluate", { expression: fs.readFileSync(scriptFile, "utf8"), awaitPromise: true, returnByValue: true });
console.log("RESULT " + JSON.stringify(r.result && r.result.result ? r.result.result.value : r));
ws.close();
process.exit(0);
''';
