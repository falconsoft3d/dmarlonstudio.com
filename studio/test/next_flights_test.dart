// El buscador de vuelos web (Next.js con servidor): el diseño, el código, el
// inglés y, con DMS_ELECTRON_RUNTIME (con next) y Chrome, la web compilada,
// el servidor (sin token: datos de ejemplo) y un recorrido en Chrome.
//
//   DMS_NEXT_SHOTS=carpeta: las capturas de la web.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';

import 'next_live.dart';

String id(String s) => s;

void main() {
  final e = tkFlutterExamples(id).firstWhere((e) => e.seed == 'next_flights');

  test('diseño y código: tres pantallas y el token en el servidor', () {
    final app = FlApp.of(e.design);
    expect([for (final s in app.screens) s.name], ['Rutas', 'Nueva', 'Ruta']);
    final files = TkWebNext.files(e.design, e.code, name: e.name);
    final client = files['lib/app.js']!, srv = files['lib/server.js']!;
    for (final s in [
      'server.buscar(',
      'localStorage',
      'dibujarDias(',
      'Notification',
      'EVERY = 30 * 60 * 1000',
    ]) {
      expect(client, contains(s), reason: s);
    }
    for (final s in [
      'TRAVELPAYOUTS_TOKEN',
      'TRAVELPAYOUTS_MARKER',
      'prices_for_dates',
      'grouped_prices',
      'autocomplete.travelpayouts.com',
      'export async function buscar(',
      'export function modo(',
    ]) {
      expect(srv, contains(s), reason: s);
    }
    // El token no está en la app ni el servidor usa lo de la app.
    expect(client, isNot(contains('TRAVELPAYOUTS_TOKEN')));
    for (final s in ['TX.', 'money(', 'fmt(']) {
      expect(srv, isNot(contains(s)), reason: s);
    }
    final used = RegExp(
      r'TX\.([A-Z_0-9]+)',
    ).allMatches(e.code).map((m) => m[1]!).toSet();
    for (final k in used) {
      expect(e.code, contains('"$k":'), reason: k);
    }
    expect(files['app/ruta/page.js'], contains('app.arg("Ruta")'));
  });

  test('en inglés: los textos se traducen y el código es el mismo', () {
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    String en(String s) => catalog[s] ?? s;
    final x = tkFlutterExamples(en).firstWhere((e) => e.seed == 'next_flights');
    expect(x.name, 'Flight Finder (Next.js)');
    expect(x.code, contains('"LOCALE": "en-US"'));
    String tail(String c) => c.substring(c.indexOf('// «{}» toma'));
    expect(tail(x.code), tail(e.code));
    final tx = x.code.substring(
      x.code.indexOf('const TX'),
      x.code.indexOf('// ----'),
    );
    for (final s in ['ñ', 'á', 'é', 'í', 'ó', 'ú', '¿']) {
      expect(tx.split('\n').where((l) => l.contains(s)), isEmpty, reason: s);
    }
  });

  test(
    'de verdad: el servidor y un recorrido en Chrome',
    () async {
      final live = await NextLive.start(e, env: {'TRAVELPAYOUTS_TOKEN': ''});
      if (live == null) {
        return markTestSkipped(
          'Sin DMS_ELECTRON_RUNTIME (con next), Node o Chrome.',
        );
      }
      addTearDown(live.stop);
      expect(await live.post('modo'), '{"real":false}');
      final r =
          jsonDecode(
                await live.post('buscar', {
                  'from': 'Madrid',
                  'to': 'HAV',
                  'depart': '2026-12',
                  'ret': '2027-01',
                  'currency': 'EUR',
                  'lang': 'es',
                }),
              )
              as Map;
      expect(r['from'], 'MAD');
      expect(r['toName'], 'La Habana');
      expect(r['sample'], isTrue);
      expect((r['tickets'] as List).length, greaterThan(10));
      expect(
        ((r['tickets'] as List).first as Map)['url'],
        startsWith('https://www.aviasales.com/search/MAD'),
      );
      expect(
        await live.post('buscar', {
          'from': 'MAD',
          'to': 'HAV',
          'depart': 'mañana',
        }),
        contains('"error":"date"'),
      );
      final out = await live.run(_flow);
      expect(out, 'ejemplo:2,error,nueva:3,ruta,quitar:2', reason: live.log);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  shots();
}

const _flow = r'''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (f, what, ms = 20000) => {
    const end = Date.now() + ms;
    while (Date.now() < end) { const v = f(); if (v) return v; await sleep(100); }
    throw new Error("No llegó: " + what + " · " + location.pathname + " · " + document.body.innerText.slice(0, 500));
  };
  const text = () => document.body.innerText;
  const type = (el, v) => {
    Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v);
    el.dispatchEvent(new Event("input", { bubbles: true }));
  };
  const icon = (name) => [...document.querySelectorAll("button")].find((b) => b.innerText.trim() === name);
  const button = (label) => [...document.querySelectorAll("button")].find((b) => b.innerText.trim().endsWith(label));
  const tiles = () => document.querySelectorAll(".tile");
  const priced = () => [...document.querySelectorAll(".tile-trail")].every((t) => /\d/.test(t.innerText));
  const log = [];
  try {
    await until(() => tiles().length === 2 && priced() && text().includes("datos de ejemplo"), "ejemplo");
    log.push("ejemplo:" + tiles().length);
    icon("add").click();
    await until(() => location.pathname === "/nueva" && document.querySelectorAll("input").length >= 5, "nueva");
    button("Añadir y analizar").click();
    await until(() => text().includes("Escriba el origen y el destino"), "error");
    log.push("error");
    const f = document.querySelectorAll("input");
    type(f[0], "Valencia"); type(f[1], "Roma"); type(f[2], "2026-12-14");
    await sleep(200);
    button("Añadir y analizar").click();
    await until(() => location.pathname === "/" && tiles().length === 3 && priced(), "añadida");
    log.push("nueva:" + tiles().length);
    tiles()[0].click();
    await until(() => location.pathname === "/ruta" && text().includes("Desde") && text().includes("Lo más barato de cada aerolínea") && tiles().length > 0, "ruta");
    log.push("ruta");
    button("Quitar la ruta").click();
    await until(() => location.pathname === "/" && tiles().length === 2, "quitar");
    log.push("quitar:" + tiles().length);
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';

/// Las capturas (DMS_NEXT_SHOTS=carpeta).
void shots() {
  final out = Platform.environment['DMS_NEXT_SHOTS'];
  test('capturas', () async {
    if (out == null) return markTestSkipped('Sin DMS_NEXT_SHOTS.');
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    for (final lang in ['es', 'en']) {
      String tr(String s) => lang == 'es' ? s : (catalog[s] ?? s);
      final x = tkFlutterExamples(
        tr,
      ).firstWhere((e) => e.seed == 'next_flights');
      final live = await NextLive.start(x, env: {'TRAVELPAYOUTS_TOKEN': ''});
      if (live == null) return markTestSkipped('Sin Next.js o Chrome.');
      try {
        final dir = Directory('$out/$lang')..createSync(recursive: true);
        await live.shot('/', '${dir.path}/next_flights.png', prepare: _shot(0));
        await live.shot(
          '/',
          '${dir.path}/next_flights-1.png',
          prepare: _shot(1),
        );
        await live.shot(
          '/',
          '${dir.path}/next_flights-2.png',
          prepare: _shot(2),
        );
        await live.shot(
          '/',
          '${dir.path}/next_flights-3.png',
          prepare: _shot(3),
        );
      } finally {
        await live.stop();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// 0: las rutas; 1: una ruta nueva; 2: el detalle; 3: más abajo en el detalle.
String _shot(int k) =>
    '''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const type = (el, v) => { Object.getOwnPropertyDescriptor(el.constructor.prototype, "value").set.call(el, v); el.dispatchEvent(new Event("input", { bubbles: true })); };
  for (let i = 0; i < 100 && document.querySelectorAll(".tile").length < 2; i++) await sleep(100);
  for (let i = 0; i < 100 && /…/.test([...document.querySelectorAll(".tile-trail")].map((t) => t.innerText).join("")); i++) await sleep(100);
  await sleep(600);
  if ($k === 1) {
    [...document.querySelectorAll("button")].find((b) => b.innerText.trim() === "add").click();
    await sleep(800);
    const f = document.querySelectorAll("input");
    type(f[0], "Barcelona"); type(f[1], "Nueva York"); type(f[2], "2026-12"); type(f[3], "2027-01"); type(f[4], "450");
    await sleep(500);
  }
  if ($k >= 2) {
    document.querySelector(".tile").click();
    await sleep(1500);
    if ($k === 3) { const t = [...document.querySelectorAll("h4")].pop(); if (t) t.scrollIntoView({ block: "center" }); await sleep(500); }
  }
  return 1;
})()
''';
