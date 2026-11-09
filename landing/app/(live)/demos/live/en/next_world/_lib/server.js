// The server: what comes after «// @server» in the logic. The app calls each function it exports with server.name({ … }).
// datos de las APIs públicas, los junta y los guarda un rato en memoria: el
// navegador solo habla con este servidor.

const UA = {
  "user-agent": "DMarlonStudio-demo/1.0 (+https://dmarlonstudio.com)",
  "Digitraffic-User": "DMarlonStudio/1.0",
  accept: "application/json",
};

async function getJson(url, headers = {}, ms = 12000) {
  const r = await fetch(url, { headers: { ...UA, ...headers }, signal: AbortSignal.timeout(ms), cache: "no-store" });
  if (!r.ok) throw new Error("HTTP " + r.status + " · " + new URL(url).host);
  return r.json();
}

// Lo último bueno de cada fuente: se pide otra vez pasado «ms» y, si falla,
// se sirve lo anterior con el error.
const memo = new Map();
async function cached(key, ms, load) {
  const c = memo.get(key) || {};
  if (c.value && Date.now() - c.at < ms) return c.value;
  if (!c.pending) {
    c.pending = load()
      .then((value) => Object.assign(c, { value: { at: Date.now(), ...value }, at: Date.now(), error: "" }))
      .catch((e) => Object.assign(c, { error: String(e.message || e), at: c.value ? Date.now() - ms / 2 : 0 }))
      .finally(() => (c.pending = null));
    memo.set(key, c);
  }
  await c.pending;
  if (!c.value) throw new Error(c.error);
  return { ...c.value, error: c.error };
}

const RAD_S = Math.PI / 180;
const r3 = (v) => Math.round(v * 1000) / 1000;
const sample = () => process.env.DMS_SAMPLE === "1";

// ------------------------------------------------------------------ el mapa
// La tierra de Natural Earth (world-atlas, 1:110 o 1:50 millones): TopoJSON a
// polígonos [lon, lat].
export async function mapa({ detalle } = {}) {
  const res = detalle === "50m" ? "50m" : "110m";
  const topo = await cached("land" + res, 864e5, () =>
    getJson(`https://cdn.jsdelivr.net/npm/world-atlas@2.0.2/land-${res}.json`),
  );
  const [sx, sy] = topo.transform.scale, [tx, ty] = topo.transform.translate;
  const arcs = topo.arcs.map((arc) => {
    let x = 0, y = 0;
    return arc.map(([dx, dy]) => {
      x += dx;
      y += dy;
      return [Math.round((x * sx + tx) * 100) / 100, Math.round((y * sy + ty) * 100) / 100];
    });
  });
  // Un anillo con las longitudes seguidas (sin saltar de 180 a -180); el que
  // da la vuelta al mundo (la Antártida) se cierra por el polo.
  const ring = (ids) => {
    const out = [];
    for (const i of ids) {
      const a = i < 0 ? arcs[~i].slice().reverse() : arcs[i];
      out.push(...(out.length ? a.slice(1) : a));
    }
    for (let k = 1; k < out.length; k++) {
      const d = out[k][0] - out[k - 1][0];
      if (Math.abs(d) > 180) out[k] = [out[k][0] - 360 * Math.sign(d), out[k][1]];
    }
    const span = out[out.length - 1][0] - out[0][0];
    if (Math.abs(span) > 180) {
      const pole = out[0][1] < 0 ? -90 : 90;
      out.push([out[out.length - 1][0], pole], [out[0][0], pole]);
    }
    return out;
  };
  const land = [];
  for (const g of topo.objects.land.geometries) {
    const polys = g.type === "Polygon" ? [g.arcs] : g.type === "MultiPolygon" ? g.arcs : [];
    for (const p of polys) {
      // Los huecos (lagos y mares interiores), en las mismas longitudes que
      // la costa que los rodea.
      const [outer, ...holes] = p.map(ring);
      const xs = outer.map((q) => q[0]);
      const mid = (Math.min(...xs) + Math.max(...xs)) / 2;
      land.push([
        outer,
        ...holes.map((h) => {
          const off = 360 * Math.round((mid - h[0][0]) / 360);
          return off ? h.map(([x, y]) => [x + off, y]) : h;
        }),
      ]);
    }
  }
  return { land };
}

// ------------------------------------------------------------------ aviones
// OpenSky Network: el mundo entero en una sola petición. Sin cuenta da unas
// 100 al día (una cada 15 minutos); con OPENSKY_CLIENT_ID y
// OPENSKY_CLIENT_SECRET (una cuenta gratis), una cada 90 segundos. Entre una
// y otra, la app mueve cada avión por su rumbo y su velocidad. Si OpenSky no
// responde, adsb.lol (gratis, sin clave) alrededor de unos puntos.
const POINTS = [[50, 5], [45, 13], [40.4, -3.7], [40.7, -74], [34, -84], [36, -118]];

async function adsbLol() {
  // De uno en uno: en paralelo, adsb.lol responde 429 (demasiadas peticiones).
  const seen = new Map();
  for (const [la, lo] of POINTS) {
    let d = null;
    for (let tries = 0; tries < 2 && !d; tries++) {
      try {
        d = await getJson(`https://api.adsb.lol/v2/point/${la}/${lo}/250`, {}, 8000);
      } catch (e) {
        if (!String(e.message).includes("429")) break;
        await new Promise((r) => setTimeout(r, 1500));
      }
    }
    for (const a of (d && d.ac) || []) {
      if (a.lat == null || a.lon == null || a.alt_baro === "ground" || seen.has(a.hex)) continue;
      seen.set(a.hex, [
        a.hex,
        (a.flight || "").trim(),
        a.r || "",
        a.t || "",
        r3(a.lon),
        r3(a.lat),
        Math.round((+a.alt_baro || +a.alt_geom || 0) * 0.3048),
        Math.round((a.gs || 0) * 0.5144),
        a.track == null ? null : Math.round(a.track),
      ]);
    }
  }
  if (!seen.size) throw new Error("api.adsb.lol");
  return { fuente: "adsb.lol", items: [...seen.values()] };
}

let openskyToken = { value: "", until: 0 };
async function openSky() {
  const id = process.env.OPENSKY_CLIENT_ID, secret = process.env.OPENSKY_CLIENT_SECRET;
  const headers = {};
  if (id && secret) {
    if (Date.now() > openskyToken.until) {
      const r = await fetch(
        "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token",
        {
          method: "POST",
          headers: { "content-type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({ grant_type: "client_credentials", client_id: id, client_secret: secret }),
          signal: AbortSignal.timeout(10000),
        },
      );
      if (!r.ok) throw new Error("OpenSky: HTTP " + r.status);
      const t = await r.json();
      openskyToken = { value: t.access_token, until: Date.now() + (t.expires_in - 60) * 1000 };
    }
    headers.authorization = "Bearer " + openskyToken.value;
  }
  const d = await getJson("https://opensky-network.org/api/states/all", headers, 20000);
  const items = [];
  for (const s of d.states || []) {
    if (s[5] == null || s[6] == null || s[8]) continue;
    items.push([s[0], (s[1] || "").trim(), s[2] || "", "", r3(s[5]), r3(s[6]), Math.round(s[7] ?? s[13] ?? 0), Math.round(s[9] || 0), s[10] == null ? null : Math.round(s[10])]);
  }
  return { fuente: "OpenSky Network", items, at: (d.time || 0) * 1000 || Date.now() };
}

async function vuelos() {
  if (sample()) return sampleData().vuelos;
  const withAccount = process.env.OPENSKY_CLIENT_ID && process.env.OPENSKY_CLIENT_SECRET;
  return cached("planes", withAccount ? 90e3 : 9e5, async () => {
    try {
      return await openSky();
    } catch (e) {
      return adsbLol();
    }
  });
}

// ------------------------------------------------------------------ barcos
// El AIS del mar Báltico de Fintraffic (Digitraffic): posiciones y fichas.
async function barcos() {
  if (sample()) return sampleData().barcos;
  return cached("ships", 60e3, async () => {
    const [pos, info] = await Promise.all([
      getJson("https://meri.digitraffic.fi/api/ais/v1/locations"),
      cached("ships-info", 36e5, async () => ({ list: await getJson("https://meri.digitraffic.fi/api/ais/v1/vessels") })).catch(() => ({ list: [] })),
    ]);
    const names = new Map(info.list.map((v) => [v.mmsi, v]));
    const items = [];
    for (const f of pos.features || []) {
      const [lon, lat] = f.geometry.coordinates;
      if (Math.abs(lon) > 180 || Math.abs(lat) > 90) continue;
      const p = f.properties, v = names.get(p.mmsi) || {};
      items.push([p.mmsi, v.name || "", v.shipType || 0, r3(lon), r3(lat), p.sog >= 102 ? null : p.sog, p.cog >= 360 ? null : Math.round(p.cog), (v.destination || "").trim()]);
    }
    return { fuente: "Fintraffic (Digitraffic)", items };
  });
}

// ------------------------------------------------------------------ trenes
// Cercanías de Renfe (GTFS en tiempo real) y los trenes de Finlandia (VR).
async function trenes() {
  if (sample()) return sampleData().trenes;
  return cached("trains", 30e3, async () => {
    const [renfe, vr] = await Promise.allSettled([
      getJson("https://gtfsrt.renfe.com/vehicle_positions.json"),
      getJson("https://rata.digitraffic.fi/api/v1/train-locations/latest"),
    ]);
    const items = [];
    if (renfe.status === "fulfilled") {
      for (const e of renfe.value.entity || []) {
        const v = e.vehicle || {}, p = v.position;
        if (!p) continue;
        const label = (v.vehicle && v.vehicle.label) || e.id;
        const [line, num] = String(label).split("-");
        items.push(["es" + e.id, num || line, "Renfe", r3(p.longitude), r3(p.latitude), null, num ? line : ""]);
      }
    }
    if (vr.status === "fulfilled") {
      for (const t of vr.value || []) {
        const [lon, lat] = t.location.coordinates;
        items.push(["fi" + t.trainNumber, String(t.trainNumber), "VR", r3(lon), r3(lat), t.speed, ""]);
      }
    }
    if (!items.length) throw new Error("gtfsrt.renfe.com · rata.digitraffic.fi");
    const parts = [renfe.status === "fulfilled" ? "Renfe" : "", vr.status === "fulfilled" ? "Digitraffic" : ""];
    return { fuente: parts.filter(Boolean).join(" · "), items };
  });
}

// ------------------------------------------------------------------ todo junto
const settle = async (f) => {
  const t = Date.now();
  try {
    const r = await f();
    return { at: Date.now(), ...r, ms: Date.now() - t };
  } catch (e) {
    return { fuente: "", items: [], error: String(e.message || e), ms: Date.now() - t };
  }
};

/// Los aviones, los barcos y los trenes, y cómo ha ido cada fuente.
export async function datos() {
  const [v, b, t] = await Promise.all([settle(vuelos), settle(barcos), settle(trenes)]);
  const fuente = (kind, x) => ({ kind, fuente: x.fuente, n: x.items.length, ms: x.ms, at: x.at, error: x.error || "", sample: sample() });
  return {
    now: Date.now(),
    vuelos: { at: v.at, items: v.items },
    barcos: { at: b.at, items: b.items },
    trenes: { at: t.at, items: t.items },
    fuentes: [fuente("plane", v), fuente("ship", b), fuente("train", t)],
  };
}

// ------------------------------------------------------------------ ejemplo
// DMS_SAMPLE=1: datos inventados (siempre los mismos) para las pruebas y las
// capturas, sin salir a internet salvo por el mapa.
function rng(seed) {
  let s = seed >>> 0 || 1;
  return () => {
    s ^= s << 13;
    s >>>= 0;
    s ^= s >>> 17;
    s ^= s << 5;
    s >>>= 0;
    return s / 4294967296;
  };
}

// Un punto de la ruta más corta entre a y b (fracción f) y el rumbo.
function along([la1, lo1], [la2, lo2], f) {
  const RAD = RAD_S;
  const p1 = la1 * RAD, l1 = lo1 * RAD, p2 = la2 * RAD, l2 = lo2 * RAD;
  const d = 2 * Math.asin(Math.sqrt(Math.sin((p2 - p1) / 2) ** 2 + Math.cos(p1) * Math.cos(p2) * Math.sin((l2 - l1) / 2) ** 2));
  const A = Math.sin((1 - f) * d) / Math.sin(d), B = Math.sin(f * d) / Math.sin(d);
  const x = A * Math.cos(p1) * Math.cos(l1) + B * Math.cos(p2) * Math.cos(l2);
  const y = A * Math.cos(p1) * Math.sin(l1) + B * Math.cos(p2) * Math.sin(l2);
  const z = A * Math.sin(p1) + B * Math.sin(p2);
  const lat = Math.atan2(z, Math.sqrt(x * x + y * y)), lon = Math.atan2(y, x);
  const hdg = Math.atan2(Math.sin(l2 - lon) * Math.cos(p2), Math.cos(lat) * Math.sin(p2) - Math.sin(lat) * Math.cos(p2) * Math.cos(l2 - lon));
  return [lat / RAD, lon / RAD, ((hdg / RAD) + 360) % 360];
}

const HUBS = [
  [40.47, -3.56], [51.47, -0.45], [49.01, 2.55], [50.03, 8.56], [41.26, 28.74], [25.25, 55.36], [28.56, 77.1],
  [1.36, 103.99], [22.31, 113.92], [40.08, 116.58], [35.77, 140.39], [-33.94, 151.18], [40.64, -73.78],
  [33.64, -84.43], [41.98, -87.9], [33.94, -118.41], [19.44, -99.07], [-23.43, -46.47], [4.7, -74.14],
  [-26.13, 28.24], [30.12, 31.41], [22.99, -82.41], [25.79, -80.29], [43.68, -79.62], [-33.39, -70.79],
  [41.3, 2.08], [52.31, 4.76], [25.27, 51.61], [37.46, 126.44], [55.97, 37.41], [60.32, 24.96], [-12.02, -77.11],
];
const CALLS = ["IBE", "VLG", "AEA", "RYR", "EZY", "BAW", "AFR", "DLH", "KLM", "THY", "UAE", "QTR", "AAL", "DAL", "UAL", "AMX", "AVA", "LAN", "CPA", "JAL", "SIA", "QFA"];
const MODELS = ["A320", "A20N", "A321", "B738", "B38M", "A333", "A359", "B789", "B77W", "E190", "AT76", "A388"];
const SHIP_WORDS = ["BALTIC", "NORDIC", "STAR", "WIND", "AURORA", "VIKING", "FINN", "SEA", "SILJA", "POLARIS", "LADY", "EXPRESS", "QUEEN", "NOVA", "ARCTIC", "MARE"];
const LANES = [
  [[60.15, 24.95], [59.45, 24.75]], [[60.45, 22.25], [59.33, 18.07]], [[59.33, 18.07], [56.95, 24.1]],
  [[54.35, 18.65], [55.7, 12.6]], [[54.32, 10.14], [55.7, 21.1]], [[60.15, 24.95], [59.9, 30.2]],
  [[57.7, 11.9], [58.9, 5.7]], [[65.6, 22.1], [60.45, 22.25]], [[53.55, 9.95], [54.4, 6.5]],
];
const TRACKS = [
  ["C1", [40.42, -3.69], [40.33, -3.77]], ["C3", [40.42, -3.69], [40.03, -3.6]], ["C4", [40.45, -3.69], [40.56, -3.65]],
  ["C5", [40.4, -3.68], [40.32, -3.87]], ["R2", [41.39, 2.17], [41.54, 2.44]], ["R4", [41.39, 2.17], [41.56, 1.99]],
  ["C1", [37.39, -5.98], [37.5, -5.75]], ["C3", [39.47, -0.38], [39.2, -0.42]], ["C1", [43.26, -2.93], [43.37, -3.0]],
];
const FI_TRACKS = [[[60.17, 24.94], [61.5, 23.76]], [[60.17, 24.94], [60.98, 25.66]], [[61.5, 23.76], [65.01, 25.47]], [[60.45, 22.27], [61.5, 23.76]]];

let sampleCache = null;
function sampleData() {
  if (sampleCache) return sampleCache;
  const r = rng(20261109);
  const pick = (a) => a[Math.floor(r() * a.length)];
  const planes = [];
  for (let i = 0; i < 2400; i++) {
    const a = pick(HUBS);
    let b = pick(HUBS);
    if (a === b) b = HUBS[(HUBS.indexOf(a) + 7) % HUBS.length];
    const [lat, lon, hdg] = along(a, b, 0.04 + r() * 0.92);
    const call = pick(CALLS) + (100 + Math.floor(r() * 8900));
    planes.push([(0x300000 + i * 97).toString(16), call, "", pick(MODELS), r3(lon), r3(lat), 9000 + Math.round(r() * 3200), 215 + Math.round(r() * 45), Math.round(hdg)]);
  }
  const ships = [];
  for (let i = 0; i < 420; i++) {
    const [a, b] = pick(LANES);
    const back = r() < 0.5;
    const [lat, lon, hdg] = along(back ? b : a, back ? a : b, r());
    const moored = r() < 0.25;
    const name = pick(SHIP_WORDS) + " " + pick(SHIP_WORDS);
    ships.push([230000000 + i * 1373, name, pick([60, 70, 70, 70, 80, 80, 30, 52, 37]), r3(lon + (r() - 0.5) * 0.3), r3(lat + (r() - 0.5) * 0.15), moored ? 0 : Math.round((8 + r() * 12) * 10) / 10, Math.round(hdg), pick(["HELSINKI", "TALLINN", "STOCKHOLM", "RIGA", "GDANSK", "KIEL", "ST PETERSBURG", ""])]);
  }
  const trains = [];
  for (let i = 0; i < 140; i++) {
    const [line, a, b] = pick(TRACKS);
    const [lat, lon] = along(a, b, r());
    const n = 17000 + Math.floor(r() * 9000);
    trains.push(["es" + n, String(n), "Renfe", r3(lon), r3(lat), null, line]);
  }
  for (let i = 0; i < 60; i++) {
    const [a, b] = pick(FI_TRACKS);
    const [lat, lon] = along(a, b, r());
    const n = 1 + Math.floor(r() * 990);
    trains.push(["fi" + n, String(n), "VR", r3(lon), r3(lat), Math.round(40 + r() * 160), ""]);
  }
  const f = "sample";
  sampleCache = { vuelos: { fuente: f, items: planes }, barcos: { fuente: f, items: ships }, trenes: { fuente: f, items: trains } };
  return sampleCache;
}
