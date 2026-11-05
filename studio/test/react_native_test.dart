// React Native (Expo) hecho con pantallas.
//
//   DMS_RN_RUNTIME=carpeta con node_modules de Expo (la que instala el
//   estudio en rn-runtime): la tienda se exporta para la web, se recorre en
//   Chrome de verdad y se arranca con expo start desde el estudio.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_react_native.dart';
import 'package:dmarlon_studio/code/tk_rn_run.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample _store() =>
    tkFlutterExamples(id).firstWhere((e) => e.seed == 'rn_store');

String? _runtime() {
  final r = Platform.environment['DMS_RN_RUNTIME'];
  return r != null &&
          File(p.join(r, 'node_modules', 'expo', 'package.json')).existsSync()
      ? r
      : null;
}

const _chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

void main() {
  test('el destino y los archivos de la app', () {
    final e = _store();
    final d = e.design;
    expect(
      d.isReactNative && d.isScreens && !d.isPython && !d.isWebNext,
      isTrue,
    );
    expect(d.codeLang, 'js');
    expect(tkTargetLabel(tkTargetReactNative), 'React Native (móvil)');
    final files = TkReactNative.files(d, e.code, name: e.name);
    expect(
      files.keys,
      containsAll([
        'package.json',
        'app.json',
        'index.js',
        'App.js',
        'screens/Login.js',
        'screens/Catalogo.js',
        'screens/Producto.js',
        'screens/Carrito.js',
        'screens/Gracias.js',
        'lib/dms.js',
        'lib/state.js',
        'lib/app.js',
      ]),
    );
    final pkg = jsonDecode(files['package.json']!) as Map;
    expect(
      (pkg['dependencies'] as Map).keys,
      containsAll(['expo', 'react-native', 'react-native-web']),
    );
    expect(
      files['screens/Catalogo.js'],
      contains('accessibilityRole="button"'),
    );
    expect(files['screens/Producto.js'], contains('const arg = router.arg;'));
  });

  test(
    'de verdad: la tienda se exporta y se recorre en Chrome',
    () async {
      final runtime = _runtime();
      if (runtime == null || !File(_chrome).existsSync()) {
        return markTestSkipped('Sin DMS_RN_RUNTIME o sin Chrome.');
      }
      final node = await TkElectronRuntime.findNode();
      if (node == null) return markTestSkipped('Sin Node.js.');
      final tmp = await Directory.systemTemp.createTemp('dms_rn_');
      final procs = <Process>[];
      HttpServer? server;
      addTearDown(() async {
        for (final pr in procs) {
          pr.kill();
        }
        await server?.close(force: true);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tmp.delete(recursive: true);
      });
      final e = _store();
      for (final f in TkReactNative.files(
        e.design,
        e.code,
        name: 'Tienda',
      ).entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(f.value);
      }
      await Link(
        p.join(tmp.path, 'node_modules'),
      ).create(p.join(runtime, 'node_modules'));
      final env = {...Platform.environment, 'EXPO_NO_TELEMETRY': '1'}
        ..remove('ELECTRON_RUN_AS_NODE');
      final export = await Process.run(
        node.node,
        [
          p.join(runtime, 'node_modules', 'expo', 'bin', 'cli'),
          'export',
          '--platform',
          'web',
        ],
        workingDirectory: tmp.path,
        environment: env,
      );
      expect(export.exitCode, 0, reason: '${export.stdout}${export.stderr}');
      // Sirve dist/ (la página para todas las rutas).
      final dist = p.join(tmp.path, 'dist');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        var f = File(p.join(dist, req.uri.path.substring(1)));
        if (!f.existsSync() || req.uri.path == '/') {
          f = File(p.join(dist, 'index.html'));
        }
        req.response.headers.contentType = switch (p.extension(f.path)) {
          '.js' => ContentType('application', 'javascript', charset: 'utf-8'),
          '.html' => ContentType.html,
          '.ttf' => ContentType('font', 'ttf'),
          _ => ContentType.binary,
        };
        await req.response.addStream(f.openRead());
        await req.response.close();
      });
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
      final flow = File(p.join(tmp.path, 'flow.js'))..writeAsStringSync(_flow);
      final r = await Process.run(node.node, [
        driver.path,
        '$cdp',
        'http://127.0.0.1:${server.port}/',
        flow.path,
      ]);
      final line = '${r.stdout}'
          .split('\n')
          .firstWhere((l) => l.startsWith('RESULT '), orElse: () => '');
      expect(
        line.isEmpty ? null : jsonDecode(line.substring(7)),
        'error,catalogo,busqueda,insignia,carrito:49,80 €,36,90 €,pagado',
        reason: '${r.stdout}${r.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  test(
    'de verdad: Ejecutar arranca Expo y abre el simulador',
    () async {
      final runtime = _runtime();
      if (runtime == null) return markTestSkipped('Sin DMS_RN_RUNTIME.');
      final tmp = await Directory.systemTemp.createTemp('dms_rn_run_');
      addTearDown(() => tmp.delete(recursive: true));
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      TkRnRuntime.dirOverride = runtime;
      await StudioDb.open();
      final dir = await ProjectStore.create(
        'Movil',
        design: TkDesign(target: tkTargetReactNative),
      );
      final prepared = await ProjectStore.prepareRun(dir);
      expect(prepared.reactNative, isTrue);
      final run = await TkRunner.start(prepared);
      addTearDown(run.stop);
      final end = DateTime.now().add(const Duration(minutes: 2));
      while (run.url == null && run.running && DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(run.url, isNotNull, reason: run.lines.join('\n'));
      final c = HttpClient();
      final page = await (await (await c.getUrl(
        Uri.parse(run.url!),
      )).close()).transform(utf8.decoder).join();
      expect(page, contains('<iframe id="app"'));
      final appUrl = RegExp(r'src="(http://[^"]+)"').firstMatch(page)![1]!;
      final html = await (await (await c.getUrl(
        Uri.parse(appUrl),
      )).close()).transform(utf8.decoder).join();
      expect(html, contains('<div id="root">'));
      c.close();
      run.stop();
      await StudioDb.close();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

/// Abre la página por CDP, espera a que la app esté pintada (sin perder el
/// contexto si se recarga al arrancar) y evalúa el guion.
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

/// El recorrido de la tienda (React Native en la web).
const _flow = r'''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (f, what) => {
    const end = Date.now() + 10000;
    while (Date.now() < end) { const v = f(); if (v) return v; await sleep(50); }
    throw new Error("No llegó: " + what + " · " + document.body.innerText.slice(0, 300));
  };
  const text = () => document.body.innerText;
  const type = (el, v) => {
    Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  };
  const buttons = () => [...document.querySelectorAll('[role="button"]')];
  const button = (label) => buttons().find((b) => b.innerText.trim().endsWith(label));
  const aria = (label) => document.querySelector(`[aria-label="${label}"]`);
  const log = [];
  try {
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
    log.push("catalogo");
    type(document.querySelector("input"), "auri");
    await until(() => text().includes("Auriculares") && !text().includes("Camiseta básica"), "busqueda");
    log.push("busqueda");
    type(document.querySelector("input"), "");
    await until(() => text().includes("Camiseta básica"), "todos");
    aria("Añadir al carrito").click();
    await sleep(80);
    aria("Añadir al carrito").click();
    await until(() => [...document.querySelectorAll("div")].some((d) => d.innerText === "2" && d.childElementCount <= 1), "insignia");
    log.push("insignia");
    buttons().find((b) => b.innerText.includes("Lámpara de mesa") && b.innerText.includes("24,00 €")).click();
    await until(() => text().includes("Ver el carrito"), "ficha");
    button("Añadir al carrito").click();
    await sleep(100);
    button("Ver el carrito").click();
    await until(() => text().includes("49,80 €"), "carrito");
    log.push("carrito:49,80 €");
    aria("remove_circle_outline").click();
    await until(() => text().includes("36,90 €"), "quitar");
    log.push("36,90 €");
    button("Pagar").click();
    await until(() => text().includes("PED-1001 · 36,90 €"), "pagado");
    log.push("pagado");
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';
