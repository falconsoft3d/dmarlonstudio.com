// Web con Next.js hecha con pantallas.
//
//   DMS_ELECTRON_RUNTIME=…/electron-runtime (con next): la tienda se compila
//   con next build y se recorre en Chrome de verdad (CDP). Chrome se busca en
//   DMS_CHROME o en /Applications/Google Chrome.app.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_flutter_templates.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  test('plantillas, acciones y rutas de JavaScript', () {
    expect(TkWebNext.tpl(r'Hola ${app.name}'), r'`Hola ${app.name}`');
    expect(TkWebNext.tpl('a`b'), r'`a\`b`');
    expect(
      TkWebNext.action('if (app.entrar()) home:Catalogo'),
      "if (app.entrar()) { app.home(router, 'Catalogo'); }",
    );
    expect(
      TkWebNext.action('app.crear(); go:Detalle(item); back'),
      "app.crear(); app.go(router, 'Detalle', item); router.back();",
    );
    expect(TkWebNext.action("debugPrint('x')"), "console.log('x');");
    final app = FlApp(
      screens: [
        FlScreen(name: 'Inicio'),
        FlScreen(name: 'MisPedidos'),
      ],
    );
    expect(TkWebNext.route(app, 'Inicio'), '/');
    expect(TkWebNext.route(app, 'MisPedidos'), '/mis-pedidos');
    expect(TkWebNext.color('primary'), '"var(--primary)"');
    expect(TkWebNext.color('primaryContainer'), '"var(--primary-container)"');
  });

  test('el destino y los archivos de la tienda', () {
    final e = tkFlutterExamples(
      id,
    ).firstWhere((e) => e.seed == 'web_next_store');
    final d = e.design;
    expect(d.isWebNext && d.isScreens && !d.isFlutter && !d.isPython, isTrue);
    expect(d.codeLang, 'js');
    expect(tkTargetLabel(tkTargetWebNext), 'Web (Next.js)');
    final files = TkWebNext.files(d, e.code, name: e.name);
    expect(
      files.keys,
      containsAll([
        'package.json',
        'app/layout.js',
        'app/page.js',
        'app/catalogo/page.js',
        'app/producto/page.js',
        'app/carrito/page.js',
        'app/gracias/page.js',
        'lib/dms.js',
        'lib/state.js',
        'lib/app.js',
      ]),
    );
    expect(files['lib/app.js'], e.code);
    expect(files['app/producto/page.js'], contains('app.arg("Producto")'));
    // Las 20 plantillas también generan su página.
    final all = FlApp(
      screens: [
        for (final t in flTemplates)
          t.build('P${t.id.replaceAll('_', '')}', id),
      ],
    );
    final dd = TkDesign(target: tkTargetWebNext);
    all.saveTo(dd);
    expect(
      TkWebNext.files(
        dd,
        TkWebNext.template('//'),
        name: 'x',
      ).keys.where((k) => k.endsWith('page.js')),
      hasLength(20),
    );
  });

  test(
    'de verdad: la tienda web se compila y se recorre en Chrome',
    () async {
      final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
      final chrome =
          Platform.environment['DMS_CHROME'] ??
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
      if (runtime == null ||
          !File(
            p.join(runtime, 'node_modules', 'next', 'package.json'),
          ).existsSync() ||
          !File(chrome).existsSync()) {
        return markTestSkipped(
          'Sin DMS_ELECTRON_RUNTIME (con next) o sin Chrome.',
        );
      }
      TkElectronRuntime.dirOverride = runtime;
      final node = await TkElectronRuntime.findNode();
      if (node == null) return markTestSkipped('Sin Node.js.');
      final tmp = await Directory.systemTemp.createTemp('dms_webnext_');
      final procs = <Process>[];
      addTearDown(() async {
        for (final pr in procs) {
          pr.kill();
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tmp.delete(recursive: true);
      });
      final e = tkFlutterExamples(
        id,
      ).firstWhere((e) => e.seed == 'web_next_store');
      for (final f in TkWebNext.files(
        e.design,
        e.code,
        name: 'tienda',
      ).entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(f.value);
      }
      await Link(
        p.join(tmp.path, 'node_modules'),
      ).create(p.join(runtime, 'node_modules'));
      final env = {...Platform.environment, 'NEXT_TELEMETRY_DISABLED': '1'}
        ..remove('ELECTRON_RUN_AS_NODE');
      final next = p.join(
        runtime,
        'node_modules',
        'next',
        'dist',
        'bin',
        'next',
      );
      final build = await Process.run(
        node.node,
        [next, 'build', '--webpack'],
        workingDirectory: tmp.path,
        environment: env,
      );
      expect(build.exitCode, 0, reason: '${build.stdout}${build.stderr}');
      Future<int> port() async {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final p = s.port;
        await s.close();
        return p;
      }

      final web = await port(), cdp = await port();
      procs.add(
        await Process.start(
          node.node,
          [next, 'start', '-p', '$web'],
          workingDirectory: tmp.path,
          environment: env,
        ),
      );
      procs.add(
        await Process.start(chrome, [
          '--headless=new',
          '--disable-gpu',
          '--remote-debugging-port=$cdp',
          '--user-data-dir=${p.join(tmp.path, 'chrome')}',
          'about:blank',
        ]),
      );
      final driver = File(p.join(tmp.path, 'cdp.mjs'))
        ..writeAsStringSync(_driver);
      final flow = File(p.join(tmp.path, 'flow.js'))..writeAsStringSync(_flow);
      // Esperar al servidor.
      for (var i = 0; i < 80; i++) {
        try {
          final c = HttpClient();
          final r = await (await c.getUrl(
            Uri.parse('http://127.0.0.1:$web/'),
          )).close();
          c.close();
          if (r.statusCode == 200) break;
        } on Object {
          // Aún no.
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      final r = await Process.run(node.node, [
        driver.path,
        '$cdp',
        'http://127.0.0.1:$web/',
        flow.path,
      ]);
      final out = '${r.stdout}';
      final line = out
          .split('\n')
          .firstWhere((l) => l.startsWith('RESULT '), orElse: () => '');
      expect(
        line.isEmpty ? null : jsonDecode(line.substring(7)),
        'error,catalogo:/catalogo,busqueda,insignia,carrito:49,80 €,36,90 €,pagado,catalogo,salir',
        reason: '$out${r.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

/// Abre una página por CDP y evalúa un guion: node cdp.mjs puerto url guion.js
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
await new Promise((r) => setTimeout(r, 2500));
const r = await send("Runtime.evaluate", { expression: fs.readFileSync(scriptFile, "utf8"), awaitPromise: true, returnByValue: true });
const v = r.result && r.result.result ? r.result.result.value : r;
console.log("RESULT " + JSON.stringify(v));
if (r.result && r.result.exceptionDetails) console.log("ERROR " + JSON.stringify(r.result.exceptionDetails));
ws.close();
process.exit(0);
''';

/// El recorrido de la tienda en la página.
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
    log.push("catalogo:" + location.pathname);
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
    await until(() => location.pathname === "/producto" && text().includes("Ver el carrito"), "ficha");
    button("Añadir al carrito").click();
    await sleep(100);
    button("Ver el carrito").click();
    await until(() => location.pathname === "/carrito" && text().includes("49,80 €"), "carrito");
    log.push("carrito:49,80 €");
    icon("remove_circle_outline").click();
    await until(() => text().includes("36,90 €"), "quitar");
    log.push("36,90 €");
    button("Pagar").click();
    await until(() => location.pathname === "/gracias" && text().includes("PED-1001 · 36,90 €"), "pagado");
    log.push("pagado");
    button("Seguir comprando").click();
    await until(() => location.pathname === "/catalogo", "seguir");
    log.push("catalogo");
    icon("logout").click();
    await until(() => location.pathname === "/" && document.querySelectorAll("input").length >= 2, "salir");
    log.push("salir");
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';
