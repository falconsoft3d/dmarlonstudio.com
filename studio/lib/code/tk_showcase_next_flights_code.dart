part of 'tk_examples.dart';

// El JavaScript del buscador de vuelos web (tk_showcase_next_flights.dart):
// va después de los textos (TX). Lo que sigue a «// @server» es el servidor.
const _nextFlightsCode = r'''// ------------------------------------------------------------------ utilidades
// «{}» toma el dato siguiente; «{0}», «{1}»…, el de ese número.
const fmt = (s, ...a) => {
  let i = 0;
  return s.replace(/\{(\d*)\}/g, (_, n) => String(a[n === "" ? i++ : +n] ?? ""));
};
const money = (v, cur) =>
  v == null
    ? "—"
    : new Intl.NumberFormat(TX.LOCALE, { style: "currency", currency: cur || "EUR", maximumFractionDigits: 0 }).format(v);
const median = (v) => {
  const s = [...v].sort((a, b) => a - b);
  const n = s.length;
  return n ? (n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2) : 0;
};
const MONTHS = TX.MONTHS.split("|");
const clock = (t) => (t ? new Date(t).toLocaleTimeString(TX.LOCALE, { hour: "2-digit", minute: "2-digit" }) : "—");
// «2026-12-14T10:05:00» → «14 dic»
const dayLabel = (at) => {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(at || "");
  return m ? +m[3] + " " + MONTHS[+m[2] - 1].slice(0, 3).toLowerCase() : "";
};
const timeLabel = (at) => (at && at.length >= 16 ? at.slice(11, 16) : "");
// «2026-12» → «diciembre de 2026»; «2026-12-20» → «20 dic 2026»
const period = (s) => {
  const m = /^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(s || "");
  if (!m) return s || "";
  return m[3] ? dayLabel(s) + " " + m[1] : fmt(TX.MONTH_YEAR, MONTHS[+m[2] - 1].toLowerCase(), m[1]);
};
const duration = (min) => (min > 0 ? fmt(TX.DURATION, Math.floor(min / 60), String(min % 60).padStart(2, "0")) : "");
const stops = (n) => (n === 0 ? TX.DIRECT : n === 1 ? TX.ONE_STOP : fmt(TX.STOPS, n));
const validDate = (s) => {
  const m = /^(\d{4})[-/.](\d{1,2})(?:[-/.](\d{1,2}))?$/.exec((s || "").trim());
  if (!m) return "";
  const y = +m[1], mo = +m[2], d = m[3] ? +m[3] : 0;
  if (mo < 1 || mo > 12 || y < 2000) return "";
  if (d && d > new Date(y, mo, 0).getDate()) return "";
  return y + "-" + String(mo).padStart(2, "0") + (d ? "-" + String(d).padStart(2, "0") : "");
};

const STORE = "dms_flights_routes";
const EVERY = 30 * 60 * 1000;   // cada media hora

// ------------------------------------------------------------------ una ruta
class Ruta {
  constructor(o) {
    Object.assign(this, { history: [], result: null, last: 0, error: "", loading: false }, o);
  }

  /// Lo que se guarda en el navegador (los 150 billetes más baratos).
  toJSON() {
    const { loading, ...rest } = this;
    if (rest.result) rest.result = { ...rest.result, tickets: (rest.result.tickets || []).slice(0, 150) };
    return rest;
  }

  get cur() {
    return this.currency || "EUR";
  }

  get corto() {
    return (this.from || this.fromText) + " → " + (this.to || this.toText);
  }

  get titulo() {
    const a = this.fromName || this.fromText, b = this.toName || this.toText;
    return a + (this.from ? " (" + this.from + ")" : "") + " → " + b + (this.to ? " (" + this.to + ")" : "");
  }

  get periodo() {
    return [period(this.depart), this.ret ? fmt(TX.RETURN_ON, period(this.ret)) : TX.ONE_WAY, this.direct ? TX.DIRECT_ONLY : ""]
      .filter(Boolean)
      .join(" · ");
  }

  get mejor() {
    const t = this.result && this.result.tickets;
    return t && t.length ? t.reduce((a, b) => (b.price < a.price ? b : a)) : null;
  }

  get precioTexto() {
    if (this.loading) return TX.ANALYZING;
    return this.mejor ? money(this.mejor.price, this.cur) : "—";
  }

  get sub() {
    if (this.error) return this.error;
    const ch = this.cambio;
    return [this.periodo, ch].filter(Boolean).join(" · ");
  }

  /// Lo que ha cambiado desde el análisis anterior.
  get cambio() {
    const h = this.history;
    if (h.length < 2) return "";
    const d = h[h.length - 1].price - h[h.length - 2].price;
    if (Math.abs(d) < 0.5) return TX.SAME;
    return fmt(d < 0 ? TX.DOWN : TX.UP, money(Math.abs(d), this.cur));
  }

  get media() {
    const t = (this.result && this.result.tickets) || [];
    return t.length ? money(median(t.map((x) => x.price)), this.cur) : "—";
  }

  get minimo() {
    if (!this.history.length) return "—";
    const m = this.history.reduce((a, b) => (b.price < a.price ? b : a));
    return fmt(TX.LOWEST_SEEN, money(m.price, this.cur), clock(m.t), new Date(m.t).toLocaleDateString(TX.LOCALE));
  }

  get resumen() {
    const b = this.mejor;
    if (this.loading && !b) return TX.ANALYZING;
    if (this.error && !b) return this.error;
    if (!b) return TX.NO_PRICES;
    return fmt(TX.BEST, money(b.price, this.cur), b.airlineName || b.airline, dayLabel(b.depart_at), stops(b.transfers));
  }

  get detalle() {
    return [fmt(TX.MEDIAN, this.media), this.cambio, this.target ? fmt(TX.ALERT_BELOW, money(this.target, this.cur)) : ""]
      .filter(Boolean)
      .join(" · ");
  }

  get cuando() {
    if (!this.last) return "";
    return fmt(TX.ANALYZED_AT, clock(this.last), clock(this.last + EVERY)) + (this.result && this.result.sample ? " · " + TX.SAMPLE : "");
  }

  /// Lo más barato de cada aerolínea, de la más barata a la más cara.
  get mejores() {
    const t = (this.result && this.result.tickets) || [];
    const by = new Map();
    for (const x of t) {
      const b = by.get(x.airline);
      if (!b) by.set(x.airline, { t: x, n: 1 });
      else {
        b.n++;
        if (x.price < b.t.price || (x.price === b.t.price && x.transfers < b.t.transfers)) b.t = x;
      }
    }
    return [...by.values()]
      .sort((a, b) => a.t.price - b.t.price)
      .map(({ t: x, n }) => ({
        nombre: x.airlineName || x.airline,
        precio: money(x.price, this.cur),
        detalle: [
          dayLabel(x.depart_at) + " " + timeLabel(x.depart_at),
          x.return_at ? "↩ " + dayLabel(x.return_at) : "",
          stops(x.transfers),
          duration(x.duration),
          n > 1 ? fmt(TX.OFFERS, n) : "",
        ]
          .filter(Boolean)
          .join(" · "),
        url: x.url,
      }));
  }

  get dias() {
    return (this.result && this.result.days) || [];
  }
}

// ------------------------------------------------------------------ la app
export class App extends DmsApp {
  rutas = [];
  modo = "";
  f = { origen: "", destino: "", ida: "", vuelta: "", aviso: "", moneda: "EUR", directo: false };
  error = "";
  aviso = "";
  _sel = -1;

  async start() {
    try {
      this.rutas = JSON.parse(localStorage.getItem(STORE) || "[]").map((o) => new Ruta(o));
    } catch {
      this.rutas = [];
    }
    if (!this.rutas.length) this.ejemplo();
    try {
      const m = await server.modo();
      this.modo = m.real ? TX.MODE_REAL : TX.MODE_SAMPLE;
    } catch (e) {
      this.modo = fmt(TX.ERROR, e.message || e);
    }
    this.notify();
    // Lo que toque al abrir y después, cada minuto, lo que ya lleve media hora.
    this.pendientes();
    setInterval(() => this.pendientes(), 60000);
  }

  /// La primera vez: dos rutas para ver cómo funciona.
  ejemplo() {
    const d = new Date();
    const next = (k) => {
      const x = new Date(d.getFullYear(), d.getMonth() + k, 1);
      return x.getFullYear() + "-" + String(x.getMonth() + 1).padStart(2, "0");
    };
    this.rutas = [
      new Ruta({ id: 1, fromText: "Madrid", toText: "La Habana", depart: next(1), ret: next(2), currency: "EUR", direct: false, target: 0 }),
      new Ruta({ id: 2, fromText: "Barcelona", toText: "Londres", depart: next(1), ret: "", currency: "EUR", direct: true, target: 60 }),
    ];
    this.guardar();
  }

  guardar() {
    try {
      localStorage.setItem(STORE, JSON.stringify(this.rutas));
    } catch {}
  }

  get proximo() {
    const due = this.rutas.filter((r) => r.last).map((r) => r.last + EVERY);
    if (!due.length) return TX.EVERY_30;
    const min = Math.max(0, Math.round((Math.min(...due) - Date.now()) / 60000));
    return fmt(TX.NEXT_IN, min);
  }

  async pendientes() {
    for (const r of this.rutas) {
      if (!r.loading && Date.now() - r.last >= EVERY) await this.analizar(r);
    }
  }

  analizarTodas() {
    for (const r of this.rutas) r.last = 0;
    return this.pendientes();
  }

  /// Pide el análisis al servidor (que tiene el token) y apunta el mejor
  /// precio en el historial de la ruta.
  async analizar(r) {
    r.loading = true;
    r.error = "";
    this.notify();
    try {
      const x = await server.buscar({
        from: r.from || r.fromText,
        to: r.to || r.toText,
        depart: r.depart,
        ret: r.ret,
        currency: r.cur,
        direct: r.direct,
        lang: TX.LOCALE.slice(0, 2),
      });
      Object.assign(r, { from: x.from, to: x.to, fromName: x.fromName, toName: x.toName, result: x, last: Date.now() });
      const b = r.mejor;
      if (b) {
        const prev = r.history.length ? r.history[r.history.length - 1].price : null;
        r.history.push({ t: Date.now(), price: b.price, airline: b.airline });
        if (r.history.length > 200) r.history.shift();
        this.avisar(r, prev, b.price);
      }
    } catch (e) {
      const m = String(e.message || e);
      r.error =
        m === "token" ? TX.ERR_TOKEN
        : m === "429" ? TX.ERR_LIMIT
        : m.startsWith("place:") ? fmt(TX.ERR_PLACE, m.slice(6))
        : fmt(TX.ERROR, m);
      r.last = Date.now();
    }
    r.loading = false;
    this.guardar();
    this.notify();
  }

  /// Un aviso cuando baja o pasa por debajo del precio de la ruta (y una
  /// notificación del navegador si se ha dado permiso).
  avisar(r, prev, now) {
    let msg = "";
    if (r.target && now <= r.target && (prev == null || prev > r.target)) msg = fmt(TX.ALERT_TARGET, r.corto, money(now, r.cur));
    else if (prev != null && now < prev - 0.5) msg = fmt(TX.ALERT_DOWN, r.corto, money(now, r.cur), money(prev - now, r.cur));
    if (!msg) return;
    this.aviso = msg;
    try {
      if (typeof Notification !== "undefined" && Notification.permission === "granted") new Notification(TX.APP, { body: msg });
    } catch {}
  }

  cerrarAviso() {
    this.aviso = "";
    this.notify();
  }

  // ---------------------------------------------------------- añadir
  moneda(c) {
    this.f.moneda = c;
    this.notify();
  }

  alternarDirecto() {
    this.f.directo = !this.f.directo;
    this.notify();
  }

  async anadir() {
    const f = this.f;
    const depart = validDate(f.ida), ret = f.vuelta.trim() ? validDate(f.vuelta) : "";
    this.error =
      !f.origen.trim() || !f.destino.trim()
        ? TX.ERR_PLACES
        : !depart
          ? TX.ERR_DEPART
          : f.vuelta.trim() && (!ret || ret.slice(0, 7) < depart.slice(0, 7))
            ? TX.ERR_RETURN
            : f.aviso.trim() && !(parseFloat(f.aviso.replace(",", ".")) > 0)
              ? TX.ERR_TARGET
              : "";
    if (this.error) {
      this.notify();
      return false;
    }
    const target = f.aviso.trim() ? parseFloat(f.aviso.replace(",", ".")) : 0;
    const r = new Ruta({
      id: Date.now(),
      fromText: f.origen.trim(),
      toText: f.destino.trim(),
      depart,
      ret,
      currency: f.moneda,
      direct: f.directo,
      target,
    });
    this.rutas.unshift(r);
    this.f = { origen: "", destino: "", ida: "", vuelta: "", aviso: "", moneda: f.moneda, directo: false };
    this.guardar();
    this.notify();
    if (target && typeof Notification !== "undefined" && Notification.permission === "default") {
      Notification.requestPermission().catch(() => {});
    }
    this.analizar(r);
    return true;
  }

  quitar(r) {
    this.rutas = this.rutas.filter((x) => x !== r);
    this.guardar();
    this.notify();
  }

  comprar(url) {
    if (url) window.open(url, "_blank", "noopener");
  }

  // ---------------------------------------------------------- dibujar
  /// El precio más barato de cada día del mes de la ida (barras; la más
  /// barata en verde). Un toque en un día abre ese vuelo.
  dibujarDias(ctx, w, h, r) {
    const days = r.dias;
    ctx.fillStyle = "#5b5f69";
    ctx.font = "12px system-ui, sans-serif";
    if (!days.length) {
      ctx.textAlign = "center";
      ctx.fillText(r.loading ? TX.ANALYZING : TX.NO_DAYS, w / 2, h / 2);
      ctx.textAlign = "left";
      return;
    }
    const prices = days.map((d) => d.price);
    const lo = Math.min(...prices), hi = Math.max(...prices);
    const top = 22, bottom = h - 22, n = days.length;
    const slot = w / n, bw = Math.min(64, slot * 0.7);
    this._bars = [];
    days.forEach((d, i) => {
      const u = hi > lo ? (d.price - lo) / (hi - lo) : 0.5;
      const bh = 12 + u * (bottom - top - 22);
      const x = i * slot + (slot - bw) / 2, y = bottom - bh;
      ctx.fillStyle = d.price === lo ? "#1E9E5A" : "#5A8DEE";
      ctx.beginPath();
      ctx.roundRect(x, y, bw, bh, 4);
      ctx.fill();
      this._bars.push([x, x + bw, d]);
      ctx.fillStyle = "#5b5f69";
      ctx.textAlign = "center";
      if (n <= 16 || i % 2 === 0) ctx.fillText(String(+d.date.slice(8, 10)), x + bw / 2, h - 6);
      if (d.price === lo || n <= 10) {
        ctx.fillStyle = d.price === lo ? "#1E9E5A" : "#5b5f69";
        ctx.font = "600 11px system-ui, sans-serif";
        ctx.fillText(money(d.price, r.cur), x + bw / 2, y - 6);
        ctx.font = "12px system-ui, sans-serif";
      }
    });
    ctx.textAlign = "left";
  }

  tocarDia(x, y, r) {
    const b = (this._bars || []).find(([a, z]) => x >= a - 2 && x <= z + 2);
    if (b) this.comprar(b[2].url);
  }

  /// Cómo cambia el mejor precio en cada análisis.
  dibujarHistoria(ctx, w, h, r) {
    const hs = r.history;
    ctx.font = "12px system-ui, sans-serif";
    ctx.fillStyle = "#5b5f69";
    if (hs.length < 2) {
      ctx.textAlign = "center";
      ctx.fillText(TX.HISTORY_SOON, w / 2, h / 2);
      ctx.textAlign = "left";
      return;
    }
    const p = hs.map((x) => x.price);
    const lo = Math.min(...p), hi = Math.max(...p);
    const pad = 28;
    const X = (i) => pad + (i * (w - pad * 2)) / (hs.length - 1);
    const Y = (v) => (hi > lo ? h - pad - ((v - lo) / (hi - lo)) * (h - pad * 2) : h / 2);
    ctx.strokeStyle = "#5A8DEE";
    ctx.lineWidth = 2;
    ctx.beginPath();
    hs.forEach((x, i) => (i ? ctx.lineTo(X(i), Y(x.price)) : ctx.moveTo(X(i), Y(x.price))));
    ctx.stroke();
    ctx.fillStyle = "#5A8DEE";
    hs.forEach((x, i) => {
      ctx.beginPath();
      ctx.arc(X(i), Y(x.price), 3, 0, Math.PI * 2);
      ctx.fill();
    });
    if (r.target && r.target >= lo && r.target <= hi) {
      ctx.strokeStyle = "#E8A800";
      ctx.setLineDash([5, 4]);
      ctx.beginPath();
      ctx.moveTo(pad, Y(r.target));
      ctx.lineTo(w - pad, Y(r.target));
      ctx.stroke();
      ctx.setLineDash([]);
    }
    ctx.fillStyle = "#5b5f69";
    ctx.fillText(money(hi, r.cur), 4, pad - 8);
    ctx.fillText(money(lo, r.cur), 4, h - 8);
    ctx.textAlign = "right";
    ctx.fillText(clock(hs[hs.length - 1].t), w - 4, h - 8);
    ctx.textAlign = "left";
  }
}

// @server: lo que sigue se ejecuta en el servidor (lib/server.js). El token
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
''';
