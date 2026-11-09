// El mundo en directo (Next.js con servidor): la parte del servidor
// (`// @server`), el diseño y, con DMS_ELECTRON_RUNTIME (con next) y Chrome,
// la web compilada con next build y recorrida en Chrome con los datos de
// ejemplo (DMS_SAMPLE=1: no sale a internet salvo por el mapa).
//
//   DMS_NEXT_DUMP=<carpeta>: deja ahí el proyecto compilado.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';

import 'next_live.dart';

String id(String s) => s;

void main() {
  shots();
  final e = tkFlutterExamples(id).firstWhere((e) => e.seed == 'next_world');

  test('el servidor: lo que va después de // @server', () {
    final (a, b) = TkWebNext.split(
      'x\ny\n// @server: aquí\nexport const z = 1;\n',
    );
    expect(a, 'x\ny\n');
    expect(b, 'export const z = 1;\n');
    expect(TkWebNext.split('sin servidor\n'), ('sin servidor\n', null));
    final app = FlApp(
      screens: [
        FlScreen(name: 'Inicio'),
        FlScreen(name: 'Otra'),
      ],
    );
    final d = TkDesign(target: tkTargetWebNext);
    app.saveTo(d);
    final plain = TkWebNext.files(d, TkWebNext.template('//'), name: 'x');
    expect(plain.keys, isNot(contains('lib/server.js')));
    expect(plain.keys, isNot(contains('app/api/[fn]/route.js')));
    final f = TkWebNext.files(
      d,
      'import { DmsApp, server } from "./dms";\nexport class App extends DmsApp {}\n// @server\nexport async function hola({ n }) { return n + 1; }\n',
      name: 'x',
      base: '/demos/live/es/x',
      lang: 'en',
    );
    expect(f['lib/app.js'], isNot(contains('hola')));
    expect(f['lib/server.js'], contains('export async function hola'));
    expect(
      f['app/api/[fn]/route.js'],
      contains('import * as server from "../../../lib/server"'),
    );
    expect(
      f['lib/dms.js'],
      contains('export const API = "/demos/live/es/x/api";'),
    );
    expect(f['lib/dms.js'], contains('"Otra":"/demos/live/es/x/otra"'));
    expect(f['lib/dms.js'], contains('"Inicio":"/demos/live/es/x"'));
    expect(f['app/layout.js'], contains('<html lang="en">'));
  });

  test('diseño: tres pantallas, el Lienzo y el servidor', () {
    final d = e.design;
    expect(d.isWebNext, isTrue);
    final app = FlApp.of(d);
    expect([for (final s in app.screens) s.name], ['Mapa', 'Lista', 'Fuentes']);
    expect(app.navItems, hasLength(3));
    final files = TkWebNext.files(d, e.code, name: e.name);
    expect(
      files.keys,
      containsAll([
        'lib/server.js',
        'app/api/[fn]/route.js',
        'app/lista/page.js',
        'app/fuentes/page.js',
      ]),
    );
    final client = files['lib/app.js']!, srv = files['lib/server.js']!;
    for (final s in [
      'class App extends DmsApp',
      'server.datos()',
      'server',
      'dibujar(ctx, w, h)',
      'tocar(x, y)',
    ]) {
      expect(client, contains(s), reason: s);
    }
    for (final s in [
      'export async function datos(',
      'export async function mapa(',
      'opensky-network.org/api/states/all',
      'api.adsb.lol/v2/point',
      'meri.digitraffic.fi/api/ais/v1/locations',
      'gtfsrt.renfe.com/vehicle_positions.json',
      'rata.digitraffic.fi/api/v1/train-locations/latest',
      'OPENSKY_CLIENT_ID',
      'DMS_SAMPLE',
    ]) {
      expect(srv, contains(s), reason: s);
    }
    // El servidor no usa nada de la app (es otro módulo).
    for (final s in ['TX.', 'KINDS', 'fmt(', 'nf(']) {
      expect(srv, isNot(contains(s)), reason: s);
    }
    // Ni la app las APIs de fuera.
    expect(client, isNot(contains('opensky-network.org')));
    // Cada texto que usa el código está en TX.
    final used = RegExp(
      r'TX\.([A-Z_0-9]+)',
    ).allMatches(e.code).map((m) => m[1]!).toSet();
    for (final k in used) {
      expect(e.code, contains('"$k":'), reason: k);
    }
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkFlutterExamples(en).firstWhere((e) => e.seed == 'next_world');
    expect(x.name, 'Live World Map (Next.js)');
    expect(x.code, contains('"LOCALE": "en-US"'));
    expect(x.code, contains('"PLANES": "Planes"'));
    String tail(String c) => c.substring(c.indexOf('const RAD = '));
    expect(tail(x.code), tail(e.code));
    final tx = x.code.substring(
      x.code.indexOf('const TX'),
      x.code.indexOf('// ----'),
    );
    // «Renfe Cercanías» es un nombre propio.
    final lines = tx.replaceAll('Cercanías', '').split('\n');
    for (final s in ['ñ', 'á', 'é', 'í', 'ó', 'ú', '¿']) {
      expect(lines.where((l) => l.contains(s)), isEmpty, reason: s);
    }
  });

  test(
    'de verdad: next build, el servidor y la web en Chrome',
    () async {
      final live = await NextLive.start(
        e,
        sample: true,
        dump: Platform.environment['DMS_NEXT_DUMP'],
      );
      if (live == null)
        return markTestSkipped(
          'Sin DMS_ELECTRON_RUNTIME (con next), Node o Chrome.',
        );
      addTearDown(live.stop);
      // El servidor: los datos de ejemplo.
      final d = jsonDecode(await live.post('datos')) as Map<String, Object?>;
      expect((d['vuelos']! as Map)['items'], hasLength(2400));
      expect((d['barcos']! as Map)['items'], hasLength(420));
      expect((d['trenes']! as Map)['items'], hasLength(200));
      expect(await live.post('no_existe'), contains('No existe'));
      final out = await live.run(_flow);
      expect(
        out,
        'mapa,capas,zona,toque,lista:Cercanías,elegir,fuentes',
        reason: live.log,
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

/// Las capturas de la web (DMS_NEXT_SHOTS=carpeta): cuatro por idioma, de
/// 1600×1000, con datos reales (DMS_NEXT_SAMPLE=1: los de ejemplo).
void shots() {
  final out = Platform.environment['DMS_NEXT_SHOTS'];
  test('capturas', () async {
    if (out == null) return markTestSkipped('Sin DMS_NEXT_SHOTS.');
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    for (final lang in ['es', 'en']) {
      String tr(String s) => lang == 'es' ? s : (catalog[s] ?? s);
      final x = tkFlutterExamples(tr).firstWhere((e) => e.seed == 'next_world');
      final live = await NextLive.start(
        x,
        sample: Platform.environment['DMS_NEXT_SAMPLE'] == '1',
      );
      if (live == null) return markTestSkipped('Sin Next.js o Chrome.');
      try {
        final dir = Directory('$out/$lang')..createSync(recursive: true);
        for (final (name, path, prep) in _shots) {
          await live.shot(
            path,
            '${dir.path}/next_world$name.png',
            prepare: prep,
          );
        }
      } finally {
        await live.stop();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Cada captura: sufijo, ruta y lo que se hace antes.
const _wait = r"""
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  for (let i = 0; i < 300 && !(document.querySelector('canvas') && /\d{3,}/.test(document.querySelector('.chip')?.innerText || '')); i++) await sleep(100);
  await sleep(1500);
  const chip = (i) => document.querySelectorAll('button.chip')[i];
  const nav = (i) => document.querySelectorAll('.nav-item')[i];
  const type = (el, v) => { Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v); el.dispatchEvent(new Event("input", { bubbles: true })); };
""";
const _shots = [
  ('', '/', '(async () => {$_wait return 1; })()'),
  // Europa con un avión elegido.
  (
    '-1',
    '/',
    '(async () => {$_wait nav(1).click(); await sleep(800); type(document.querySelector("input"), "IBE"); await sleep(1500); const t = document.querySelector(".tile"); if (t) t.click(); await sleep(2000); return 1; })()',
  ),
  // El Báltico: los barcos.
  (
    '-2',
    '/',
    '(async () => {$_wait chip(3+5).click(); await sleep(4000); return 1; })()',
  ),
  // La lista: los trenes de Cercanías.
  (
    '-3',
    '/',
    '(async () => {$_wait nav(1).click(); await sleep(800); type(document.querySelector("input"), "Renfe"); await sleep(1200); return 1; })()',
  ),
];

/// El recorrido en la página.
const _flow = r'''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (f, what) => {
    const end = Date.now() + 15000;
    while (Date.now() < end) { const v = f(); if (v) return v; await sleep(80); }
    throw new Error("No llegó: " + what + " · " + location.pathname + " · " + document.body.innerText.slice(0, 400));
  };
  const text = () => document.body.innerText;
  const type = (el, v) => {
    Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  };
  const chip = (label) => [...document.querySelectorAll("button.chip")].find((b) => b.innerText.includes(label));
  const nav = (label) => [...document.querySelectorAll(".nav-item")].find((b) => b.innerText.includes(label));
  const log = [];
  try {
    await until(() => text().includes("Aviones · 2400") && text().includes("Barcos · 420") && text().includes("Trenes · 200"), "datos");
    const canvas = document.querySelector("canvas");
    await until(() => canvas.width > 0, "lienzo");
    log.push("mapa");
    chip("Aviones").click();
    await until(() => !chip("Aviones").className.includes("on"), "capa fuera");
    chip("Aviones").click();
    await until(() => chip("Aviones").className.includes("on"), "capa dentro");
    log.push("capas");
    chip("España").click();
    await until(() => chip("España").className.includes("on"), "zona");
    log.push("zona");
    // Tocar el primer tren que se ve en España: sale su ficha.
    const b = canvas.getBoundingClientRect();
    canvas.dispatchEvent(new MouseEvent("click", { bubbles: true, clientX: b.left + b.width / 2, clientY: b.top + b.height / 2 }));
    await sleep(200);
    log.push("toque");
    nav("Lista").click();
    await until(() => location.pathname === "/lista" && document.querySelector("input"), "lista");
    type(document.querySelector("input"), "cercan");
    await until(() => text().includes("encontrados") && document.querySelectorAll(".tile").length > 0, "buscar");
    log.push("lista:" + document.querySelector(".tile .tile-title").innerText.split(" ")[0]);
    document.querySelector(".tile").click();
    await until(() => location.pathname === "/" && text().includes("Línea"), "elegir");
    log.push("elegir");
    nav("Fuentes").click();
    await until(() => location.pathname === "/fuentes" && text().includes("Datos de ejemplo") && text().includes("Cómo funciona"), "fuentes");
    log.push("fuentes");
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';
