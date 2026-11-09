// El componente Lienzo del editor de pantallas en todos los destinos, y el
// dominó web (HTML) que lo usa: sus reglas y su dibujo, con node.
import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_react_native.dart';
import 'package:dmarlon_studio/code/tk_web_html.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:dmarlon_studio/code/tk_web_react.dart';
import 'package:dmarlon_studio/code/tk_web_vue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  final e = tkFlutterExamples(id).firstWhere((e) => e.seed == 'html_domino');
  TkDesign as(String target) =>
      TkDesign.fromJson({...e.design.toJson(), 'target': target});

  test('el Lienzo está en la paleta del editor de pantallas', () {
    expect(flWidgets.keys, contains('Canvas'));
    expect(flWidgets["Canvas"]!.$2, 0);
  });

  test('HTML: un <canvas> que dibuja App y recibe los toques', () {
    final f = TkWebHtml.files(e.design, e.code, name: e.name);
    expect(f['screens.js'], contains('<canvas class="canvas" data-paint='));
    expect(f['screens.js'], contains('app.dibujar(ctx, w, h)'));
    expect(f['screens.js'], contains('data-tap='));
    expect(f['screens.js'], contains('app.tocar(x, y)'));
    expect(f['dms.js'], contains('function dmsPaint()'));
    expect(f['dms.js'], contains('devicePixelRatio'));
    expect(f['style.css'], contains('.canvas {'));
  });

  test('React, Next.js y Vue: el componente DmsCanvas', () {
    final react = TkWebReact.files(as(tkTargetWebReact), e.code, name: e.name);
    expect(react['src/lib/dms.jsx'], contains('export function DmsCanvas('));
    expect(
      react['src/screens/Mesa.jsx'],
      contains('<DmsCanvas aspect={1.5714}'),
    );
    final next = TkWebNext.files(as(tkTargetWebNext), e.code, name: e.name);
    expect(next['lib/dms.js'], contains('export function DmsCanvas('));
    final vue = TkWebVue.files(as(tkTargetWebVue), e.code, name: e.name);
    expect(vue['src/lib/DmsCanvas.vue'], contains('<canvas'));
    expect(vue['src/screens/Mesa.vue'], contains('<DmsCanvas :ver="ver"'));
  });

  test('DMS_CANVAS_DUMP=<carpeta>: los proyectos, para compilarlos a mano', () {
    final out = Platform.environment['DMS_CANVAS_DUMP'];
    if (out == null) return;
    final projects = {
      'react': TkWebReact.files(as(tkTargetWebReact), e.code, name: e.name),
      'vue': TkWebVue.files(as(tkTargetWebVue), e.code, name: e.name),
      'flutter': TkFlutter.files(as(tkTargetFlutter), _dartApp, name: 'dms_x'),
    };
    for (final MapEntry(key: k, value: files) in projects.entries) {
      for (final f in files.entries) {
        File(p.join(out, k, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(f.value);
      }
    }
  });

  test('Flutter: un CustomPaint; React Native: un aviso', () {
    final flutter = TkFlutter.files(as(tkTargetFlutter), e.code, name: 'dms_x');
    expect(
      flutter['lib/main.dart'],
      contains('class DmsCanvas extends StatelessWidget'),
    );
    expect(flutter['lib/main.dart'], contains('DmsCanvas(aspect: 1.5714'));
    final rn = TkReactNative.files(
      as(tkTargetReactNative),
      e.code,
      name: e.name,
    );
    expect(rn.values.join('\n'), contains('Lienzo: en la web y en Flutter'));
  });

  test(
    'de verdad: el dominó web en node (reglas, mesa y dibujo)',
    () async {
      final node = await TkElectronRuntime.findNode();
      if (node == null) return markTestSkipped('Sin Node.js.');
      final tmp = await Directory.systemTemp.createTemp('dms_canvas_');
      addTearDown(() => tmp.delete(recursive: true));
      for (final f in TkWebHtml.files(e.design, e.code, name: e.name).entries) {
        File(p.join(tmp.path, f.key)).writeAsStringSync(f.value);
      }
      for (final f in ['dms.js', 'app.js', 'screens.js']) {
        final c = await Process.run(node.node, [
          '--check',
          p.join(tmp.path, f),
        ]);
        expect(c.exitCode, 0, reason: '$f: ${c.stderr}');
      }
      final harness = File(p.join(tmp.path, 'harness.cjs'))
        ..writeAsStringSync(_harness);
      final r = await Process.run(node.node, [harness.path, tmp.path]);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('"ok":true'));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// Carga app.js con un DmsApp de mentira, corre sus pruebas y dibuja la mesa
/// en un contexto 2D de mentira.
const _harness = r'''
const fs = require("fs"), vm = require("vm");
const ctx = { console, setInterval: () => 0, Date, Math };
vm.createContext(ctx);
vm.runInContext("class DmsApp { notify() {} }\n" + fs.readFileSync(process.argv[2] + "/app.js", "utf8") + "\nthis.r = selftest(); this.App = App;", ctx);
let calls = 0;
const fake = new Proxy({}, { get: (t, k) => (k in t ? t[k] : () => { calls++; }), set: (t, k, v) => { t[k] = v; return true; } });
const app = new ctx.App();
app.newGame();
app.dibujar(fake, 1100, 700);
app.tocar(550, 600);
console.log(JSON.stringify({ ...ctx.r, calls }));
process.exit(ctx.r.ok && calls > 200 ? 0 : 1);
''';

/// Una App de Dart con lo que llama la pantalla (para compilar en Flutter).
const _dartApp = '''
import 'package:flutter/material.dart';

class App extends ChangeNotifier {
  void start() {}
  void newGame() => notifyListeners();
  void toggleAll() => notifyListeners();
  void dibujar(Canvas ctx, double w, double h) {
    ctx.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1F6E3D));
  }
  Future<void> tocar(double x, double y) async {}
}
''';
