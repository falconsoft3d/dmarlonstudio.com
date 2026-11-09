// Una web de Next.js de un ejemplo, compilada con next build y servida con
// next start, con Chrome sin ventana (CDP) para recorrerla y hacer capturas.
// Lo usan las pruebas de las webs con servidor (next_world, next_speed…).
//
// Necesita DMS_ELECTRON_RUNTIME (la carpeta del estudio con next en
// node_modules), Node.js 22 o más (WebSocket) y Chrome (DMS_CHROME o
// /Applications/Google Chrome.app).
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:path/path.dart' as p;

class NextLive {
  NextLive._(this.dir, this.node, this.web, this.cdp, this._procs);

  final Directory dir;
  final String node;
  final int web, cdp;
  final List<Process> _procs;
  final _out = StringBuffer();
  bool _keep = false;

  String get log => '$_out';
  String get base => 'http://127.0.0.1:$web';

  static Future<int> _port() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final p = s.port;
    await s.close();
    return p;
  }

  /// La web del ejemplo [e] compilada y servida (null: falta algo).
  static Future<NextLive?> start(
    TkExample e, {
    bool sample = true,
    String? dump,
    Map<String, String> env = const {},
  }) async {
    final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
    final chrome =
        Platform.environment['DMS_CHROME'] ??
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
    if (runtime == null ||
        !File(
          p.join(runtime, 'node_modules', 'next', 'package.json'),
        ).existsSync() ||
        !File(chrome).existsSync()) {
      return null;
    }
    TkElectronRuntime.dirOverride = runtime;
    final found = await TkElectronRuntime.findNode();
    if (found == null) return null;
    final dir = dump != null
        ? (Directory(dump)..createSync(recursive: true))
        : await Directory.systemTemp.createTemp('dms_next_');
    for (final f in TkWebNext.files(e.design, e.code, name: e.seed).entries) {
      File(p.join(dir.path, f.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(f.value);
    }
    final nm = Link(p.join(dir.path, 'node_modules'));
    if (!nm.existsSync()) await nm.create(p.join(runtime, 'node_modules'));
    final environment = {
      ...Platform.environment,
      'NEXT_TELEMETRY_DISABLED': '1',
      if (sample) 'DMS_SAMPLE': '1',
      ...env,
    }..remove('ELECTRON_RUN_AS_NODE');
    final next = p.join(runtime, 'node_modules', 'next', 'dist', 'bin', 'next');
    final build = await Process.run(
      found.node,
      [next, 'build', '--webpack'],
      workingDirectory: dir.path,
      environment: environment,
    );
    if (build.exitCode != 0) {
      throw StateError('next build: ${build.stdout}${build.stderr}');
    }
    final web = await _port(), cdp = await _port();
    final procs = <Process>[];
    final live = NextLive._(dir, found.node, web, cdp, procs)
      .._keep = dump != null;
    final server = await Process.start(
      found.node,
      [next, 'start', '-p', '$web'],
      workingDirectory: dir.path,
      environment: environment,
    );
    server.stdout.transform(utf8.decoder).listen(live._out.write);
    server.stderr.transform(utf8.decoder).listen(live._out.write);
    procs.add(server);
    procs.add(
      await Process.start(chrome, [
        '--headless=new',
        '--disable-gpu',
        '--hide-scrollbars',
        '--remote-debugging-port=$cdp',
        '--user-data-dir=${p.join(dir.path, '.chrome')}',
        'about:blank',
      ]),
    );
    File(p.join(dir.path, '.cdp.mjs')).writeAsStringSync(_driver);
    for (var i = 0; i < 120; i++) {
      try {
        final c = HttpClient();
        final r = await (await c.getUrl(Uri.parse('${live.base}/'))).close();
        await r.drain<void>();
        c.close();
        if (r.statusCode == 200) break;
      } on Object {
        // Aún no.
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return live;
  }

  /// Llama a una función del servidor (POST `/api/<fn>`) y devuelve el cuerpo.
  Future<String> post(String fn, [Map<String, Object?> args = const {}]) async {
    final c = HttpClient();
    final rq = await c.postUrl(Uri.parse('$base/api/$fn'));
    rq.headers.contentType = ContentType.json;
    rq.write(jsonEncode(args));
    final r = await rq.close();
    final body = await r.transform(utf8.decoder).join();
    c.close();
    return body;
  }

  /// Abre [path] y evalúa [script] (una promesa); devuelve su valor.
  Future<Object?> run(
    String script, {
    String path = '/',
    int width = 1280,
    int height = 860,
  }) async {
    final f = File(p.join(dir.path, '.flow.js'))..writeAsStringSync(script);
    final r = await Process.run(node, [
      p.join(dir.path, '.cdp.mjs'),
      '$cdp',
      '$base$path',
      'eval',
      f.path,
      '$width',
      '$height',
    ]);
    final out = '${r.stdout}';
    _out.write('$out${r.stderr}');
    final line = out
        .split('\n')
        .firstWhere((l) => l.startsWith('RESULT '), orElse: () => '');
    return line.isEmpty ? null : jsonDecode(line.substring(7));
  }

  /// Abre [path], evalúa [prepare] (puede ser vacío) y guarda una captura
  /// PNG de [width]×[height] en [png].
  Future<void> shot(
    String path,
    String png, {
    String prepare = '',
    int width = 1600,
    int height = 1000,
    double scale = 1,
    Map<String, Object?>? throttle,
  }) async {
    final f = File(p.join(dir.path, '.prep.js'))
      ..writeAsStringSync(prepare.isEmpty ? '(async () => 1)()' : prepare);
    final r = await Process.run(
      node,
      [
        p.join(dir.path, '.cdp.mjs'),
        '$cdp',
        '$base$path',
        'shot',
        f.path,
        '$width',
        '$height',
        png,
        '$scale',
      ],
      environment: {
        if (throttle != null) 'DMS_CDP_THROTTLE': jsonEncode(throttle),
      },
    );
    _out.write('${r.stdout}${r.stderr}');
    if (!File(png).existsSync()) {
      throw StateError('Sin captura: ${r.stdout}${r.stderr}');
    }
  }

  Future<void> stop() async {
    for (final pr in _procs) {
      pr.kill();
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_keep) {
      try {
        await dir.delete(recursive: true);
      } on Object {
        // Se borra solo con el tiempo.
      }
    }
  }
}

/// node .cdp.mjs puerto url eval|shot guion.js ancho alto [png escala]
const _driver = r'''
import fs from "node:fs";
const [port, url, mode, scriptFile, width, height, png, scale] = process.argv.slice(2);
const base = `http://127.0.0.1:${port}`;
for (let i = 0; i < 80; i++) {
  try { await (await fetch(base + "/json/version")).json(); break; } catch { await new Promise((r) => setTimeout(r, 250)); }
}
const target = await (await fetch(base + "/json/new?about:blank", { method: "PUT" })).json();
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let id = 0;
const pending = new Map();
ws.addEventListener("message", (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); }
});
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
// DMS_CDP_THROTTLE: una conexión más lenta (Network.emulateNetworkConditions).
if (process.env.DMS_CDP_THROTTLE) {
  await send("Network.enable");
  await send("Network.emulateNetworkConditions", { offline: false, ...JSON.parse(process.env.DMS_CDP_THROTTLE) });
}
await send("Emulation.setDeviceMetricsOverride", { width: +width, height: +height, deviceScaleFactor: +(scale || 1), mobile: +width < 600 });
await send("Page.enable");
await send("Page.navigate", { url });
await new Promise((r) => setTimeout(r, 2500));
const r = await send("Runtime.evaluate", { expression: fs.readFileSync(scriptFile, "utf8"), awaitPromise: true, returnByValue: true });
const v = r.result && r.result.result ? r.result.result.value : r;
console.log("RESULT " + JSON.stringify(v));
if (r.result && r.result.exceptionDetails) console.log("ERROR " + JSON.stringify(r.result.exceptionDetails));
if (mode === "shot") {
  await new Promise((r) => setTimeout(r, 400));
  const s = await send("Page.captureScreenshot", { format: "png" });
  fs.writeFileSync(png, Buffer.from(s.result.data, "base64"));
}
await send("Target.closeTarget", { targetId: target.id });
ws.close();
process.exit(0);
''';
