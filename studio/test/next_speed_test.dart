// La velocidad de internet (Next.js con servidor): el diseño, el código, el
// inglés y, con DMS_ELECTRON_RUNTIME (con next) y Chrome, la web compilada
// con next build, su servidor (eco, descarga, subida e info) y una medición
// entera en Chrome.
//
//   DMS_NEXT_SHOTS=carpeta: las capturas de la web (con la conexión
//   frenada en Chrome para que parezca una de verdad).
import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_web_next.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';

import 'next_live.dart';

String id(String s) => s;

void main() {
  final e = tkFlutterExamples(id).firstWhere((e) => e.seed == 'next_speed');

  test('diseño y código: dos pantallas, el Lienzo y el servidor', () {
    final app = FlApp.of(e.design);
    expect([for (final s in app.screens) s.name], ['Prueba', 'Historial']);
    final files = TkWebNext.files(e.design, e.code, name: e.name);
    final client = files['lib/app.js']!, srv = files['lib/server.js']!;
    for (final s in [
      'medirPing',
      'medirBajada',
      'medirSubida',
      'serverUrl("descarga"',
      'localStorage',
      'dibujar(ctx, w, h)',
    ]) {
      expect(client, contains(s), reason: s);
    }
    for (final s in [
      'export function eco(',
      'export function descarga(',
      'export async function subida(',
      'export function info(',
      'x-vercel-ip-city',
    ]) {
      expect(srv, contains(s), reason: s);
    }
    for (final s in ['TX.', 'nf(', 'fmt(']) {
      expect(srv, isNot(contains(s)), reason: s);
    }
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
    final x = tkFlutterExamples(en).firstWhere((e) => e.seed == 'next_speed');
    expect(x.name, 'Internet Speed Test (Next.js)');
    expect(x.code, contains('"START": "Start"'));
    String tail(String c) => c.substring(c.indexOf('const nf = '));
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
    'de verdad: el servidor y una medición entera en Chrome',
    () async {
      final live = await NextLive.start(e);
      if (live == null) {
        return markTestSkipped(
          'Sin DMS_ELECTRON_RUNTIME (con next), Node o Chrome.',
        );
      }
      addTearDown(live.stop);
      final c = HttpClient();
      // La descarga: los bytes pedidos, sin comprimir.
      final rq = await c.getUrl(
        Uri.parse('${live.base}/api/descarga?bytes=300000'),
      );
      final r = await rq.close();
      final n = await r.fold<int>(0, (s, b) => s + b.length);
      expect(n, 300000);
      expect(r.headers.value('content-type'), 'application/octet-stream');
      // La subida: cuenta lo que llega.
      final up = await c.postUrl(Uri.parse('${live.base}/api/subida'));
      up.headers.contentType = ContentType.binary;
      up.add(List.filled(123456, 7));
      final ur = await up.close();
      expect(
        await ur.transform(const SystemEncoding().decoder).join(),
        '{"bytes":123456}',
      );
      c.close();
      expect(await live.post('info'), contains('"host":"Next.js"'));
      final out = await live.run(_flow);
      expect(out, 'listo,cifras,usos,historial:1', reason: live.log);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  shots();
}

const _flow = r'''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (f, what, ms = 15000) => {
    const end = Date.now() + ms;
    while (Date.now() < end) { const v = f(); if (v) return v; await sleep(100); }
    throw new Error("No llegó: " + what + " · " + document.body.innerText.slice(0, 500));
  };
  const text = () => document.body.innerText;
  const button = (label) => [...document.querySelectorAll("button")].find((b) => b.innerText.trim().endsWith(label));
  const nav = (label) => [...document.querySelectorAll(".nav-item")].find((b) => b.innerText.includes(label));
  const log = [];
  try {
    await until(() => button("Empezar") && text().includes("Servidor: Next.js"), "inicio");
    button("Empezar").click();
    await until(() => text().includes("Midiendo"), "midiendo");
    await until(() => text().includes("Listo."), "listo", 60000);
    log.push("listo");
    const cards = [...document.querySelectorAll(".card")].slice(0, 3).map((c) => c.innerText);
    const num = (s) => parseFloat(s.split("\n")[2].replace(/\./g, "").replace(",", "."));
    if (!(num(cards[0]) >= 0 && num(cards[1]) > 1 && num(cards[2]) > 1)) throw new Error("cifras: " + JSON.stringify(cards));
    log.push("cifras");
    await until(() => text().includes("Para qué le alcanza") && text().includes("Vídeo en 4K"), "usos");
    log.push("usos");
    nav("Historial").click();
    await until(() => location.pathname === "/historial" && document.querySelectorAll(".tile").length === 1, "historial");
    log.push("historial:" + document.querySelectorAll(".tile").length);
  } catch (e) {
    log.push(String(e));
  }
  return log.join(",");
})()
''';

/// Las capturas (DMS_NEXT_SHOTS=carpeta): la conexión frenada en Chrome
/// (latencia y ancho de banda) para que los números parezcan de una casa.
void shots() {
  final out = Platform.environment['DMS_NEXT_SHOTS'];
  test('capturas', () async {
    if (out == null) return markTestSkipped('Sin DMS_NEXT_SHOTS.');
    final catalog = catalogOf(File('assets/i18n/en.po').readAsStringSync());
    for (final lang in ['es', 'en']) {
      String tr(String s) => lang == 'es' ? s : (catalog[s] ?? s);
      final x = tkFlutterExamples(tr).firstWhere((e) => e.seed == 'next_speed');
      final live = await NextLive.start(x);
      if (live == null) return markTestSkipped('Sin Next.js o Chrome.');
      Map<String, Object?> net(int down, int up, int ms) => {
        'latency': ms,
        'downloadThroughput': down * 1e6 / 8,
        'uploadThroughput': up * 1e6 / 8,
      };
      try {
        final dir = Directory('$out/$lang')..createSync(recursive: true);
        // Dos mediciones antes, para que el historial tenga algo.
        await live.shot(
          '/',
          '${dir.path}/.a.png',
          prepare: _measure(''),
          throttle: net(180, 40, 24),
        );
        await live.shot(
          '/',
          '${dir.path}/.b.png',
          prepare: _measure(''),
          throttle: net(95, 20, 31),
        );
        await live.shot(
          '/',
          '${dir.path}/next_speed.png',
          prepare: _measure(''),
          throttle: net(310, 60, 14),
        );
        await live.shot(
          '/',
          '${dir.path}/next_speed-1.png',
          prepare: _measure('mid'),
          throttle: net(310, 60, 14),
        );
        await live.shot(
          '/',
          '${dir.path}/next_speed-2.png',
          prepare: _measure('uses'),
          throttle: net(48, 9, 38),
        );
        await live.shot(
          '/historial',
          '${dir.path}/next_speed-3.png',
          prepare:
              '(async () => { await new Promise((r) => setTimeout(r, 1200)); return 1; })()',
        );
      } finally {
        await live.stop();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Medir y esperar: hasta el final, a mitad de la bajada o hasta el final
/// bajando hasta la tarjeta de «para qué le alcanza».
String _measure(String mode) =>
    '''
(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  for (let i = 0; i < 100 && !document.querySelector(".btn"); i++) await sleep(100);
  await sleep(800);
  [...document.querySelectorAll("button.btn")].pop().click();
  if ("$mode" === "mid") { await sleep(7000); return 1; }
  for (let i = 0; i < 600 && ![...document.querySelectorAll("button.btn")].pop().innerText.match(/otra|again/i); i++) await sleep(100);
  await sleep(600);
  if ("$mode" === "uses") { const c = [...document.querySelectorAll(".card")][3]; if (c) c.scrollIntoView({ block: "center" }); await sleep(400); }
  return 1;
})()
''';
