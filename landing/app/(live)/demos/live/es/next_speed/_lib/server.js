// El servidor: lo que va después de «// @server» en la lógica. Cada función que exporta la llama la app con server.nombre({ … }).
// respuestas para medir y quién pregunta.

// Un bloque de 1 MB al azar (no se puede comprimir) que se repite.
const RANDOM = new Uint8Array(1 << 20);
for (let i = 0; i < RANDOM.length; i += 65536) crypto.getRandomValues(RANDOM.subarray(i, i + 65536));

const NO_CACHE = { "cache-control": "no-store, no-transform", pragma: "no-cache" };

/// Una respuesta mínima, para medir la latencia.
export function eco() {
  return new Response("1", { headers: { ...NO_CACHE, "content-type": "text/plain" } });
}

/// «bytes» bytes al azar (como mucho 25 MB), según se van enviando.
export function descarga({ bytes }) {
  let left = Math.max(1, Math.min(25e6, Math.floor(+bytes || 1e6)));
  const size = left;
  let pos = 0;
  const stream = new ReadableStream({
    pull(c) {
      if (left <= 0) return c.close();
      const n = Math.min(left, 65536, RANDOM.length - pos);
      c.enqueue(RANDOM.slice(pos, pos + n));
      pos = (pos + n) % RANDOM.length;
      left -= n;
    },
  });
  return new Response(stream, {
    headers: { ...NO_CACHE, "content-type": "application/octet-stream", "content-length": String(size) },
  });
}

/// Lee lo que envía el navegador y dice cuánto ha llegado.
export async function subida(_, request) {
  let bytes = 0;
  if (request.body) {
    const reader = request.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      bytes += value.length;
    }
  }
  return Response.json({ bytes }, { headers: NO_CACHE });
}

/// Quién pregunta (la IP y, en Vercel, la ciudad y el país) y dónde está el
/// servidor.
export function info(_, request) {
  const h = (k) => request.headers.get(k) || "";
  let ip = (h("x-forwarded-for").split(",")[0].trim() || h("x-real-ip")).replace(/^::ffff:/, "");
  // Una IP local o privada no le dice nada a nadie.
  if (/^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|::1$|fc|fd|fe80)/i.test(ip)) ip = "";
  const city = decodeURIComponent(h("x-vercel-ip-city") || "");
  return {
    ip,
    city,
    country: h("x-vercel-ip-country"),
    host: process.env.VERCEL ? "Vercel" : "Next.js",
    region: process.env.VERCEL_REGION || "local",
  };
}
