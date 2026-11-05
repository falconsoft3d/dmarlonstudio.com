// Web con servidor en Go hecha con pantallas.
//
// Con Go instalado: el estudio compila el servidor, la API REST guarda los
// datos, la tienda se recorre en Chrome de verdad (si está) y el pedido
// sigue ahí al reiniciar el servidor.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_web_go.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample _store() =>
    tkFlutterExamples(id).firstWhere((e) => e.seed == 'go_store');

const _chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/// Una petición a la API: (estado, cuerpo).
Future<(int, Object?)> _http(String method, String url, [Object? body]) async {
  final c = HttpClient();
  try {
    final req = await c.openUrl(method, Uri.parse(url));
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    Object? data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      data = text;
    }
    return (res.statusCode, data);
  } finally {
    c.close();
  }
}

Future<TkRun> _start(String dir) async {
  final prepared = await ProjectStore.prepareRun(dir);
  expect(prepared.go, isTrue);
  final run = await TkRunner.start(prepared);
  final end = DateTime.now().add(const Duration(minutes: 2));
  while (run.url == null && run.running && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  expect(run.url, isNotNull, reason: run.lines.join('\n'));
  return run;
}

void main() {
  test('el destino y los archivos del proyecto', () {
    final e = _store();
    final d = e.design;
    expect(d.isWebGo && d.isScreens && !d.isPython && !d.isWebHtml, isTrue);
    expect(d.codeLang, 'js');
    expect(tkTargetLabel(tkTargetWebGo), 'Web (Go)');
    final files = TkWebGo.files(d, e.code, name: e.name);
    expect(
      files.keys,
      containsAll([
        'go.mod',
        'main.go',
        'web/index.html',
        'web/dms.js',
        'web/app.js',
        'web/screens.js',
        'web/style.css',
      ]),
    );
    expect(files['web/dms.js'], contains('const api = {'));
    expect(files['web/app.js'], contains('api.add("pedidos"'));
    expect(files['web/app.js'], isNot(contains('import ')));
  });

  test(
    'de verdad: Go compila el servidor, la API guarda y la tienda se recorre en Chrome',
    () async {
      if (TkWebGo.goBinary() == null) return markTestSkipped('Sin Go.');
      final tmp = await Directory.systemTemp.createTemp('dms_go_');
      final procs = <Process>[];
      final runs = <TkRun>[];
      addTearDown(() async {
        for (final r in runs) {
          r.stop();
        }
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
      var run = await _start(dir);
      runs.add(run);
      final api = '${run.url}api';
      // La API: añadir, cambiar, filtrar y borrar.
      var (st, body) = await _http('POST', '$api/notas', {'texto': 'hola'});
      expect(st, 201);
      expect((body! as Map)['id'], 1);
      (st, body) = await _http('PATCH', '$api/notas/1', {'texto': 'adiós'});
      expect((body! as Map)['texto'], 'adiós');
      await _http('POST', '$api/notas', {'texto': 'otra'});
      (st, body) = await _http('GET', '$api/notas?texto=otra');
      expect((body! as List).length, 1);
      (st, body) = await _http('DELETE', '$api/notas/1');
      expect(st, 204);
      (st, body) = await _http('GET', '$api/notas');
      expect((body! as List).length, 1);
      (st, body) = await _http('GET', '$api/no-vale');
      expect(st, 404);
      // La web se sirve con la recarga del estudio.
      final c = HttpClient();
      final html = await (await (await c.getUrl(
        Uri.parse(run.url!),
      )).close()).transform(utf8.decoder).join();
      c.close();
      expect(html, contains('<div id="root">'));
      expect(html, contains('/__dms_version'));
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
        // El pedido quedó en el servidor (en data/pedidos.json).
        (st, body) = await _http('GET', '$api/pedidos');
        final pedidos = body! as List;
        expect(pedidos.length, 1);
        expect((pedidos.first as Map)['numero'], 1001);
        expect((pedidos.first as Map)['cliente'], 'Ana');
        expect(File(p.join(dir, 'data', 'pedidos.json')).existsSync(), isTrue);
      }
      // Se reinicia: los datos siguen.
      run.stop();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      run = await _start(dir);
      runs.add(run);
      (st, body) = await _http('GET', '${run.url}api/notas');
      expect((body! as List).length, 1);
      run.stop();
      await StudioDb.close();
    },
    timeout: const Timeout(Duration(minutes: 5)),
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
