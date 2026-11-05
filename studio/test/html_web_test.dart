// Web en HTML, CSS y JavaScript hecha con pantallas.
//
// Sin compilar ni Node: el estudio la sirve con su propio servidor. La
// tienda se abre desde Ejecutar y se recorre en Chrome de verdad (si está).
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_web_html.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample _store() =>
    tkFlutterExamples(id).firstWhere((e) => e.seed == 'html_store');

const _chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

Future<String> _get(String url) async {
  final c = HttpClient();
  try {
    return await (await (await c.getUrl(
      Uri.parse(url),
    )).close()).transform(utf8.decoder).join();
  } finally {
    c.close();
  }
}

void main() {
  test('el destino y los archivos de la web', () {
    final e = _store();
    final d = e.design;
    expect(d.isWebHtml && d.isScreens && !d.isPython && !d.isWebReact, isTrue);
    expect(d.codeLang, 'js');
    expect(tkTargetLabel(tkTargetWebHtml), 'Web (HTML)');
    final files = TkWebHtml.files(d, e.code, name: e.name);
    expect(
      files.keys,
      containsAll([
        'index.html',
        'style.css',
        'dms.js',
        'screens.js',
        'app.js',
        'README.md',
      ]),
    );
    expect(files['app.js'], isNot(contains('import ')));
    expect(files['app.js'], contains('class App extends DmsApp'));
    expect(files['screens.js'], contains('SCREENS["Producto"]'));
    expect(files['index.html'], contains('dmsStart(App)'));
  });

  test('los archivos de JavaScript son válidos (node --check)', () async {
    final node = await TkElectronRuntime.findNode();
    if (node == null) return markTestSkipped('Sin Node.js.');
    final tmp = await Directory.systemTemp.createTemp('dms_html_chk_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = _store();
    final files = TkWebHtml.files(e.design, e.code, name: e.name);
    // Los tres juntos, como los carga la página.
    final all = File(p.join(tmp.path, 'all.js'))
      ..writeAsStringSync(
        '${files['dms.js']}\n${files['app.js']}\n${files['screens.js']}',
      );
    final r = await Process.run(node.node, ['--check', all.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test(
    'de verdad: Ejecutar la sirve, se recarga al guardar y la tienda se recorre en Chrome',
    () async {
      final tmp = await Directory.systemTemp.createTemp('dms_html_');
      final procs = <Process>[];
      addTearDown(() async {
        for (final pr in procs) {
          pr.kill();
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tmp.delete(recursive: true);
      });
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      final e = _store();
      final dir = await ProjectStore.create(
        'Tienda',
        design: e.design,
        code: e.code,
      );
      final prepared = await ProjectStore.prepareRun(dir);
      expect(prepared.html, isTrue);
      final run = await TkRunner.start(prepared);
      addTearDown(run.stop);
      expect(run.url, isNotNull, reason: run.lines.join('\n'));
      final html = await _get(run.url!);
      expect(html, contains('<div id="root">'));
      expect(html, contains('/__dms_version'));
      expect(await _get('${run.url}../../etc/passwd'), '404');
      // Al guardar (se reescriben los archivos) cambia la versión.
      final v0 = await _get('${run.url}__dms_version');
      await ProjectStore.prepareRun(dir);
      var v1 = v0;
      for (var i = 0; i < 40 && v1 == v0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        v1 = await _get('${run.url}__dms_version');
      }
      expect(v1, isNot(v0));
      final node = await TkElectronRuntime.findNode();
      if (node != null && File(_chrome).existsSync()) {
        final cdp = await () async {
          final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
          final port = s.port;
          await s.close();
          return port;
        }();
        procs.add(
          await Process.start(_chrome, [
            '--headless=new',
            '--disable-gpu',
            '--remote-debugging-port=$cdp',
            '--user-data-dir=${p.join(tmp.path, 'chrome')}',
            'about:blank',
          ]),
        );
        final driver = File(p.join(tmp.path, 'cdp.mjs'))
          ..writeAsStringSync(_driver);
        final flow = File(p.join(tmp.path, 'flow.js'))
          ..writeAsStringSync(_flow);
        final r = await Process.run(node.node, [
          driver.path,
          '$cdp',
          run.url!,
          flow.path,
        ]);
        final line = '${r.stdout}'
            .split('\n')
            .firstWhere((l) => l.startsWith('RESULT '), orElse: () => '');
        expect(
          line.isEmpty ? null : jsonDecode(line.substring(7)),
          'error,catalogo:#/catalogo,busqueda,insignia,carrito:49,80 €,36,90 €,pagado,catalogo,salir',
          reason: '${r.stdout}${r.stderr}',
        );
      }
      run.stop();
      expect(run.running, isFalse);
      await StudioDb.close();
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

const _driver = r'''
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
const ev = async (expression) => {
  const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  return r.result && r.result.result ? r.result.result.value : undefined;
};
for (let i = 0; i < 80; i++) {
  if ((await ev('document.querySelectorAll("input").length')) >= 2) break;
  await new Promise((r) => setTimeout(r, 250));
}
await new Promise((r) => setTimeout(r, 800));
console.log("RESULT " + JSON.stringify(await ev(fs.readFileSync(scriptFile, "utf8"))));
ws.close();
process.exit(0);
''';

const _flow = r'''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (f, what) => {
    const end = Date.now() + 10000;
    while (Date.now() < end) { const v = f(); if (v) return v; await sleep(50); }
    throw new Error("No llegó: " + what + " · " + location.pathname + " · " + document.body.innerText.slice(0, 300));
  };
  const text = () => document.body.innerText;
  const type = (el, v) => {
    Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  };
  const button = (label) => [...document.querySelectorAll("button")].find((b) => b.innerText.trim().endsWith(label));
  const icon = (name) => [...document.querySelectorAll("button")].find((b) => b.innerText.trim() === name);
  const log = [];
  try {
    await until(() => document.querySelectorAll("input").length >= 2, "login");
    const inputs = document.querySelectorAll("input");
    type(inputs[0], "demo@tienda.com");
    type(inputs[1], "mala");
    await sleep(100);
    button("Entrar").click();
    await until(() => text().includes("Correo o contraseña incorrectos."), "error");
    log.push("error");
    type(document.querySelectorAll("input")[1], "1234");
    await sleep(100);
    button("Entrar").click();
    await until(() => text().includes("Hola, Ana"), "catalogo");
    log.push("catalogo:" + location.hash);
    type(document.querySelector("input"), "auri");
    await until(() => text().includes("Auriculares") && !text().includes("Camiseta básica"), "busqueda");
    log.push("busqueda");
    type(document.querySelector("input"), "");
    await until(() => text().includes("Camiseta básica"), "todos");
    const add = () => document.querySelector('button[title="Añadir al carrito"]');
    if (!add()) throw new Error("sin botón: " + [...document.querySelectorAll("button")].map((b) => (b.title || "") + "/" + b.innerText.trim()).join(" | "));
    add().click();
    await sleep(80);
    add().click();
    await until(() => [...document.querySelectorAll(".badge")].some((b) => b.innerText === "2"), "insignia");
    log.push("insignia");
    [...document.querySelectorAll(".card")].find((c) => c.innerText.includes("Lámpara de mesa")).click();
    await until(() => location.hash === "#/producto" && text().includes("Ver el carrito"), "ficha");
    button("Añadir al carrito").click();
    await sleep(100);
    button("Ver el carrito").click();
    await until(() => location.hash === "#/carrito" && text().includes("49,80 €"), "carrito");
    log.push("carrito:49,80 €");
    icon("remove_circle_outline").click();
    await until(() => text().includes("36,90 €"), "quitar");
    log.push("36,90 €");
    button("Pagar").click();
    await until(() => location.hash === "#/gracias" && text().includes("PED-1001 · 36,90 €"), "pagado");
    log.push("pagado");
    button("Seguir comprando").click();
    await until(() => location.hash === "#/catalogo", "seguir");
    log.push("catalogo");
    icon("logout").click();
    await until(() => (location.hash === "" || location.hash === "#/") && document.querySelectorAll("input").length >= 2, "salir");
    log.push("salir");
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';
