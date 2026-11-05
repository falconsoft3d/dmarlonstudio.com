import 'dart:convert';
import 'dart:io';

/// El simulador del estudio: una página con el marco de un teléfono (o de
/// una tableta) que muestra dentro la app de Flutter compilada para la web.
/// No necesita Xcode ni Android: basta Flutter y un navegador.
class TkFlutterSim {
  TkFlutterSim._(this._server, this.appUrl, this.title);

  final HttpServer _server;

  /// Donde sirve `flutter run -d web-server` la app.
  final String appUrl;
  final String title;

  /// La página del simulador.
  String get url => 'http://127.0.0.1:${_server.port}/';

  static Future<TkFlutterSim> start(String appUrl, String title) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sim = TkFlutterSim._(server, appUrl, title);
    server.listen((req) async {
      if (req.uri.path == '/version') {
        req.response.headers.contentType = ContentType.text;
        req.response.headers.set('Cache-Control', 'no-store');
        req.response.write('${sim.version}');
      } else {
        req.response.headers.contentType = ContentType.html;
        req.response.write(page(appUrl, title));
      }
      await req.response.close();
    });
    return sim;
  }

  Future<void> close() => _server.close(force: true);

  /// Sube cada vez que la app se vuelve a compilar: la página la recarga.
  int version = 0;

  /// Los dispositivos: nombre → (ancho, alto, radio, isla).
  static const devices = <String, (int, int, int, bool)>{
    'iPhone 15': (393, 852, 52, true),
    'iPhone SE': (375, 667, 18, false),
    'Pixel 8': (412, 915, 40, false),
    'Galaxy S24': (384, 832, 36, false),
    'iPad mini': (744, 1133, 28, false),
  };

  /// La página: barra con el dispositivo, girar y recargar, y el teléfono.
  static String page(String appUrl, String title) {
    final list = jsonEncode({
      for (final e in devices.entries)
        e.key: [e.value.$1, e.value.$2, e.value.$3, e.value.$4],
    });
    final esc = const HtmlEscape().convert(title);
    return '''<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$esc · DMarlon Studio</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; display: flex; flex-direction: column;
    align-items: center; background: radial-gradient(circle at 50% 0%, #2a2d36, #121318 70%);
    font: 13px -apple-system, system-ui, sans-serif; color: #c9ccd3;
  }
  .bar {
    display: flex; gap: 8px; align-items: center; margin: 14px 0 18px;
    background: #1d1f26; border: 1px solid #30333c; border-radius: 12px; padding: 6px 8px;
  }
  .bar b { color: #fff; font-weight: 600; margin: 0 6px; }
  select, button {
    background: #2a2d36; color: #e6e8eb; border: 1px solid #3a3e48; border-radius: 8px;
    padding: 6px 10px; font: inherit; cursor: pointer;
  }
  button:hover, select:hover { border-color: #7aa2f7; }
  .stage { flex: 1; display: flex; align-items: flex-start; justify-content: center; padding-bottom: 24px; }
  .phone {
    position: relative; background: #0b0c0f; padding: 12px; border-radius: 64px;
    box-shadow: 0 0 0 2px #3a3e48, 0 30px 80px rgba(0,0,0,.55);
    transform-origin: top center;
  }
  .screen { position: relative; overflow: hidden; background: #fff; display: flex; flex-direction: column; }
  .status {
    height: 44px; display: flex; align-items: center; justify-content: space-between;
    padding: 0 28px; font-weight: 600; font-size: 15px; color: #111; background: #fff; flex: none;
  }
  .island {
    position: absolute; top: 10px; left: 50%; transform: translateX(-50%);
    width: 118px; height: 34px; border-radius: 20px; background: #000; z-index: 2;
  }
  iframe { border: 0; width: 100%; flex: 1; background: #fff; display: block; }
  .home { height: 26px; flex: none; display: flex; align-items: center; justify-content: center; background: #fff; }
  .home i { width: 134px; height: 5px; border-radius: 3px; background: #111; }
  .hint { color: #7d828d; margin-top: -8px; margin-bottom: 12px; }
</style>
</head>
<body>
  <div class="bar">
    <b>$esc</b>
    <select id="device" title="Dispositivo"></select>
    <button id="rotate" title="Girar">⟳ Girar</button>
    <button id="reload" title="Recargar la app">↻ Recargar</button>
  </div>
  <div class="hint">Simulador de DMarlon Studio · la app corre con Flutter para la web</div>
  <div class="stage"><div class="phone" id="phone">
    <div class="screen" id="screen">
      <div class="island" id="island"></div>
      <div class="status" id="status"><span id="clock">9:41</span><span>●●● ▮</span></div>
      <iframe id="app" src="$appUrl" title="$esc"></iframe>
      <div class="home" id="home"><i></i></div>
    </div>
  </div></div>
<script>
  const devices = $list;
  const sel = document.getElementById('device');
  for (const name of Object.keys(devices)) sel.add(new Option(name, name));
  let landscape = false;
  const saved = localStorage.getItem('dms-device');
  if (saved && devices[saved]) sel.value = saved;
  function fit() {
    const [w0, h0, r, island] = devices[sel.value];
    const [w, h] = landscape ? [h0, w0] : [w0, h0];
    const screen = document.getElementById('screen');
    screen.style.width = w + 'px';
    screen.style.height = h + 'px';
    screen.style.borderRadius = r + 'px';
    document.getElementById('phone').style.borderRadius = (r + 12) + 'px';
    document.getElementById('island').style.display = island && !landscape ? '' : 'none';
    document.getElementById('status').style.display = landscape ? 'none' : '';
    document.getElementById('home').style.display = r > 20 ? '' : 'none';
    // Que quepa en la ventana.
    const scale = Math.min(1, (innerHeight - 110) / (h + 24), (innerWidth - 24) / (w + 24));
    document.getElementById('phone').style.transform = 'scale(' + scale + ')';
    localStorage.setItem('dms-device', sel.value);
  }
  sel.onchange = fit;
  addEventListener('resize', fit);
  document.getElementById('rotate').onclick = () => { landscape = !landscape; fit(); };
  document.getElementById('reload').onclick = () => {
    const f = document.getElementById('app'); f.src = f.src;
  };
  const clock = () => {
    const d = new Date();
    document.getElementById('clock').textContent =
      d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');
  };
  clock(); setInterval(clock, 30000);
  fit();
  // El estudio volvió a compilar la app (al guardar): se recarga sola.
  let version = null;
  setInterval(async () => {
    try {
      const v = await (await fetch('/version', { cache: 'no-store' })).text();
      if (version !== null && v !== version) {
        const f = document.getElementById('app'); f.src = f.src;
      }
      version = v;
    } catch (_) {}
  }, 1000);
</script>
</body>
</html>
''';
  }
}

/// Lo que necesita Flutter: el ejecutable `flutter`. Una app abierta desde
/// el Finder no tiene /opt/homebrew/bin en el PATH: se busca también ahí.
class TkFlutterTools {
  TkFlutterTools._();

  static String? flutter() {
    final home = Platform.environment['HOME'] ?? '';
    for (final d in [
      ...(Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '$home/flutter/bin',
      '$home/development/flutter/bin',
      if (Platform.isWindows) r'C:\src\flutter\bin',
    ]) {
      if (d.isEmpty) continue;
      final f =
          '$d${Platform.pathSeparator}${Platform.isWindows ? 'flutter.bat' : 'flutter'}';
      if (File(f).existsSync()) return f;
    }
    return null;
  }

  /// Un puerto libre de este equipo.
  static Future<int> freePort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  /// Las líneas de `flutter run` que no dicen nada al usuario.
  static bool noise(String l) {
    final t = l.trim();
    return t.isEmpty ||
        t.startsWith('Launching lib/main.dart') ||
        t.startsWith('Waiting for connection') ||
        t.startsWith('Debug service listening') ||
        t.startsWith('Flutter run key commands') ||
        t.startsWith('This app is linked to the debug service') ||
        t.startsWith('A Dart VM Service') ||
        t.startsWith('The Flutter DevTools') ||
        RegExp(r'^[rRhdcq] ').hasMatch(t) ||
        t.contains('--no-wasm-dry-run') ||
        t.contains('Wasm dry run') ||
        t.startsWith('For more information, see') ||
        t.startsWith('To hot restart') ||
        t.startsWith('Running with sound null safety') ||
        t.contains('requires the Dart Debug Chrome extension') ||
        t.contains('is being served at') ||
        t.startsWith('Performing hot restart') ||
        t.startsWith('Recompile complete') ||
        t.startsWith('Restarted application') ||
        t.contains('🔥');
  }
}
