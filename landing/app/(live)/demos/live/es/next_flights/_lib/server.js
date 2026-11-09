// El servidor: lo que va después de «// @server» en la lógica. Cada función que exporta la llama la app con server.nombre({ … }).
// de Travelpayouts (TRAVELPAYOUTS_TOKEN) y el marcador de afiliado
// (TRAVELPAYOUTS_MARKER) van en .env.local o en las variables de entorno de
// Vercel: nunca llegan al navegador. Sin token, datos de ejemplo creíbles.

const API = "https://api.travelpayouts.com";
const token = () => (process.env.TRAVELPAYOUTS_TOKEN || "").trim();

/// ¿Datos de verdad o de ejemplo?
export function modo() {
  return { real: !!token() };
}

// Ciudades conocidas (para no preguntar y para los datos de ejemplo).
const CITIES = [
  ["MAD", "Madrid", "Madrid", 40.42, -3.7], ["BCN", "Barcelona", "Barcelona", 41.39, 2.17],
  ["VLC", "Valencia", "Valencia", 39.47, -0.38], ["SVQ", "Sevilla", "Seville", 37.39, -5.98],
  ["AGP", "Málaga", "Malaga", 36.72, -4.42], ["BIO", "Bilbao", "Bilbao", 43.26, -2.93],
  ["PMI", "Palma de Mallorca", "Palma de Mallorca", 39.57, 2.65], ["LPA", "Gran Canaria", "Gran Canaria", 27.93, -15.39],
  ["TCI", "Tenerife", "Tenerife", 28.29, -16.63], ["LIS", "Lisboa", "Lisbon", 38.72, -9.14],
  ["PAR", "París", "Paris", 48.86, 2.35], ["LON", "Londres", "London", 51.51, -0.13],
  ["ROM", "Roma", "Rome", 41.9, 12.5], ["MIL", "Milán", "Milan", 45.46, 9.19],
  ["FRA", "Fráncfort", "Frankfurt", 50.11, 8.68], ["AMS", "Ámsterdam", "Amsterdam", 52.37, 4.9],
  ["BER", "Berlín", "Berlin", 52.52, 13.4], ["IST", "Estambul", "Istanbul", 41.01, 28.98],
  ["HAV", "La Habana", "Havana", 23.11, -82.37], ["MIA", "Miami", "Miami", 25.76, -80.19],
  ["NYC", "Nueva York", "New York", 40.71, -74.01], ["MEX", "Ciudad de México", "Mexico City", 19.43, -99.13],
  ["CUN", "Cancún", "Cancun", 21.16, -86.85], ["BOG", "Bogotá", "Bogota", 4.71, -74.07],
  ["MDE", "Medellín", "Medellin", 6.24, -75.58], ["LIM", "Lima", "Lima", -12.05, -77.04],
  ["SCL", "Santiago de Chile", "Santiago", -33.45, -70.67], ["BUE", "Buenos Aires", "Buenos Aires", -34.6, -58.38],
  ["MVD", "Montevideo", "Montevideo", -34.9, -56.16], ["SDQ", "Santo Domingo", "Santo Domingo", 18.49, -69.93],
  ["PUJ", "Punta Cana", "Punta Cana", 18.58, -68.4], ["SJU", "San Juan", "San Juan", 18.47, -66.11],
  ["CCS", "Caracas", "Caracas", 10.48, -66.9], ["PTY", "Panamá", "Panama City", 8.98, -79.52],
  ["SJO", "San José (Costa Rica)", "San Jose (Costa Rica)", 9.93, -84.08], ["LAX", "Los Ángeles", "Los Angeles", 34.05, -118.24],
  ["ORL", "Orlando", "Orlando", 28.54, -81.38], ["SAO", "São Paulo", "Sao Paulo", -23.55, -46.63],
  ["RIO", "Río de Janeiro", "Rio de Janeiro", -22.91, -43.17], ["TYO", "Tokio", "Tokyo", 35.68, 139.69],
  ["DXB", "Dubái", "Dubai", 25.2, 55.27],
];
const AIRLINES = {
  IB: "Iberia", UX: "Air Europa", "2W": "World2fly", PU: "Plus Ultra", CU: "Cubana", AF: "Air France", KL: "KLM",
  LH: "Lufthansa", TP: "TAP Air Portugal", TK: "Turkish Airlines", BA: "British Airways", DL: "Delta", UA: "United",
  AA: "American Airlines", AM: "Aeroméxico", CM: "Copa Airlines", AV: "Avianca", LA: "LATAM", VY: "Vueling",
  FR: "Ryanair", U2: "easyJet", EK: "Emirates", AR: "Aerolíneas Argentinas", B6: "JetBlue", AZ: "ITA Airways",
};

const fold = (s) =>
  String(s || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase();
const findCity = (text) => CITIES.find((c) => [c[0], c[1], c[2]].some((x) => fold(x) === fold(text)));
const isIata = (s) => /^[A-Za-z]{3}$/.test((s || "").trim());

async function getJson(url, headers = {}) {
  const r = await fetch(url, { headers: { accept: "application/json", ...headers }, signal: AbortSignal.timeout(15000), cache: "no-store" });
  if (r.status === 401 || r.status === 403) throw new Error("token");
  if (r.status === 429) throw new Error("429");
  if (!r.ok) throw new Error("HTTP " + r.status);
  return r.json();
}

/// Un origen o un destino a su código: los conocidos sin preguntar; el
/// resto, con el autocompletado de Travelpayouts.
async function resolve(text, lang) {
  const c = findCity(text);
  if (c) return [c[0], lang === "es" ? c[1] : c[2]];
  try {
    const list = await getJson(
      "https://autocomplete.travelpayouts.com/places2?term=" + encodeURIComponent(text) + "&locale=" + lang + "&types[]=city&types[]=airport",
    );
    const p = (list || []).find((x) => isIata(x.code));
    if (p) return [p.code.toUpperCase(), p.name || p.code];
  } catch {}
  if (isIata(text)) return [text.trim().toUpperCase(), text.trim().toUpperCase()];
  throw new Error("place:" + text);
}

/// Los nombres de las aerolíneas (sin token; una vez al día).
let airlines = { at: 0, lang: "", map: {} };
async function airlineNames(lang) {
  if (Date.now() - airlines.at < 864e5 && airlines.lang === lang) return airlines.map;
  try {
    const list = await getJson(`${API}/data/${lang}/airlines.json`);
    const map = {};
    for (const a of list) if (a.code) map[a.code] = (a.name_translations && a.name_translations[lang]) || a.name || a.code;
    airlines = { at: Date.now(), lang, map };
  } catch {}
  return airlines.map;
}

// El «link» de la API es una ruta de Aviasales: solo se aceptan rutas del
// propio sitio, con el marcador de afiliado si lo hay.
function bookingUrl(link) {
  if (!/^\/[^/\\]/.test(link || "") || /[\s"\\@]/.test(link)) return "";
  const m = (process.env.TRAVELPAYOUTS_MARKER || "").trim();
  return "https://www.aviasales.com" + link + (/^\d+$/.test(m) ? (link.includes("?") ? "&" : "?") + "marker=" + m : "");
}
// Sin link (o en los datos de ejemplo): la búsqueda de esa ruta y esas fechas.
function routeLink(from, to, departAt, returnAt) {
  const d = /^\d{4}-(\d{2})-(\d{2})/.exec(departAt || "");
  if (!d) return "";
  const r = /^\d{4}-(\d{2})-(\d{2})/.exec(returnAt || "");
  return "/search/" + from + d[2] + d[1] + to + (r ? r[2] + r[1] : "") + "1";
}
const market = (c) => ({ USD: "us", GBP: "uk", MXN: "mx", COP: "co", ARS: "ar" })[c] || "es";

/// El análisis de una ruta: los billetes de todas las aerolíneas y lo más
/// barato de cada día del mes de la ida.
export async function buscar({ from, to, depart, ret, currency, direct, lang }) {
  lang = lang === "en" ? "en" : "es";
  currency = /^[A-Z]{3}$/.test(currency || "") ? currency : "EUR";
  if (!/^\d{4}-\d{2}(-\d{2})?$/.test(depart || "")) throw new Error("date");
  if (ret && !/^\d{4}-\d{2}(-\d{2})?$/.test(ret)) throw new Error("date");
  const [fromCode, fromName] = await resolve(from, lang);
  const [toCode, toName] = await resolve(to, lang);
  const base = { from: fromCode, to: toCode, fromName, toName };
  if (!token()) return { ...base, ...sample(fromCode, toCode, depart, ret, currency, !!direct), sample: true };
  const q = new URLSearchParams({
    origin: fromCode,
    destination: toCode,
    departure_at: depart,
    currency: currency.toLowerCase(),
    market: market(currency),
    sorting: "price",
    limit: "1000",
    unique: "false",
    one_way: ret ? "false" : "true",
  });
  if (ret) q.set("return_at", ret);
  if (direct) q.set("direct", "true");
  const h = { "X-Access-Token": token() };
  const cal = new URLSearchParams({
    origin: fromCode,
    destination: toCode,
    group_by: "departure_at",
    departure_at: depart.slice(0, 7),
    currency: currency.toLowerCase(),
    market: market(currency),
  });
  if (ret) cal.set("return_at", ret.slice(0, 7));
  if (direct) cal.set("direct", "true");
  const [prices, calendar, names] = await Promise.all([
    getJson(`${API}/aviasales/v3/prices_for_dates?${q}`, h),
    getJson(`${API}/aviasales/v3/grouped_prices?${cal}`, h).catch(() => ({ data: {} })),
    airlineNames(lang),
  ]);
  if (prices.success === false) throw new Error(prices.error || "API");
  const ticket = (j) => ({
    airline: j.airline,
    airlineName: names[j.airline] || AIRLINES[j.airline] || j.airline,
    price: j.price,
    transfers: j.transfers || 0,
    depart_at: j.departure_at || "",
    return_at: j.return_at || "",
    duration: j.duration || 0,
    url: bookingUrl(j.link || routeLink(fromCode, toCode, j.departure_at, j.return_at)),
  });
  const tickets = (prices.data || []).filter((j) => j.price > 0).map(ticket);
  const days = Object.values(calendar.data || {})
    .filter((j) => j.price > 0)
    .map((j) => ({ date: (j.departure_at || "").slice(0, 10), price: j.price, airline: j.airline, url: bookingUrl(j.link || routeLink(fromCode, toCode, j.departure_at, j.return_at)) }))
    .sort((a, b) => a.date.localeCompare(b.date));
  return { ...base, tickets, days, sample: false };
}

// ------------------------------------------------------------------ ejemplo
// Precios inventados pero creíbles (por la distancia), que cambian un poco
// cada media hora. Siempre se marcan como ejemplo.
const hash = (s, h = 2166136261) => {
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619) >>> 0;
  return h >>> 0;
};
const unit = (h) => {
  h = Math.imul(h ^ (h >>> 15), 2246822519) >>> 0;
  h = Math.imul(h ^ (h >>> 13), 3266489917) >>> 0;
  return ((h ^ (h >>> 16)) & 0xffffff) / 16777216;
};
const RATES = { USD: 1.08, GBP: 0.85, MXN: 19.5, COP: 4300, ARS: 1050 };
const km = (a, b) => {
  const R = Math.PI / 180;
  const h = Math.sin(((b[3] - a[3]) * R) / 2) ** 2 + Math.cos(a[3] * R) * Math.cos(b[3] * R) * Math.sin(((b[4] - a[4]) * R) / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
};

function sample(from, to, depart, ret, currency, direct) {
  const a = findCity(from), b = findCity(to);
  const dist = a && b ? km(a, b) : 2500 + 6000 * unit(hash(from + to));
  const [y, m, d0] = depart.split("-").map(Number);
  const round = !!ret;
  const base = (35 + dist * 0.052) * (round ? 1.72 : 1) * (RATES[currency] || 1);
  const seed = hash(from + ">" + to + depart + ret + currency + (direct ? "d" : ""));
  const slot = Math.floor(Date.now() / 1800000);
  const codes = Object.keys(AIRLINES);
  let pool = codes.filter((c) => !(dist > 3000 && ["VY", "FR", "U2"].includes(c)) && unit(seed ^ hash(c)) < (dist > 3000 ? 0.48 : 0.36));
  if (pool.length < 5) pool = [...new Set([...pool, "IB", "UX", "AF", "TP", "TK"])];
  pool = pool.slice(0, 11);
  const nDays = new Date(y, m, 0).getDate();
  const days = d0 ? [d0] : Array.from({ length: nDays }, (_, i) => i + 1);
  const [ry, rm, rd] = ret ? ret.split("-").map(Number) : [0, 0, 0];
  const tickets = [];
  pool.forEach((code, k) => {
    const h = (seed ^ Math.imul(hash(code), 2654435761)) >>> 0;
    const af = 0.82 + 0.5 * unit(h);
    const stopsMin = direct ? 0 : unit(h + 7) < 0.45 ? 0 : 1;
    const n = 3 + Math.floor(unit(h + 3) * 5);
    for (let i = 0; i < n; i++) {
      const day = days[Math.floor(unit(h + 100 + i) * days.length) % days.length];
      const drift = 1 + 0.03 * Math.sin(slot * 0.37 + k * 1.7 + i) + 0.02 * Math.sin(slot * 0.113 + k * 0.9) + 0.025 * (unit(hash(String(slot), h + i)) - 0.5);
      const dayf = 0.9 + 0.25 * unit(seed + day * 31) + (day % 7 === 5 || day % 7 === 6 ? 0.08 : 0);
      const transfers = direct ? 0 : Math.min(2, stopsMin + (unit(h + 200 + i) < 0.3 ? 1 : 0));
      const price = Math.max(19, Math.round(base * af * dayf * drift * (1 - 0.07 * transfers)));
      const hour = 6 + Math.floor(unit(h + 300 + i) * 16), minute = Math.floor(unit(h + 400 + i) * 12) * 5;
      const pad = (v) => String(v).padStart(2, "0");
      const departAt = `${y}-${pad(m)}-${pad(day)}T${pad(hour)}:${pad(minute)}:00`;
      let returnAt = "";
      if (round) {
        const back = rd || Math.min(new Date(ry, rm, 0).getDate(), Math.max(1, day + 7 + Math.floor(unit(h + i) * 10)) % 28 || 1);
        returnAt = `${ry}-${pad(rm)}-${pad(back)}T${pad((hour + 7) % 24)}:${pad(minute)}:00`;
      }
      tickets.push({
        airline: code,
        airlineName: AIRLINES[code],
        price,
        transfers,
        depart_at: departAt,
        return_at: returnAt,
        duration: Math.round(dist / 820 * 60 + 40 + transfers * (95 + unit(h + i) * 120)) * (round ? 2 : 1),
        url: bookingUrl(routeLink(from, to, departAt, returnAt)),
      });
    }
  });
  tickets.sort((x, z) => x.price - z.price);
  const out = [];
  for (const day of days) {
    const t = tickets.filter((x) => +x.depart_at.slice(8, 10) === day).sort((x, z) => x.price - z.price)[0];
    if (t) out.push({ date: t.depart_at.slice(0, 10), price: t.price, airline: t.airline, url: t.url });
  }
  return { tickets, days: out };
}
