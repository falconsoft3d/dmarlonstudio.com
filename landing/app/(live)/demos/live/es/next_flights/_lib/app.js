// Buscador de vuelos: vigila rutas cada 30 minutos con los precios de Travelpayouts. El servidor (después de // @server) guarda el token y hace las consultas.
import { DmsApp, server } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = {
  "APP": "Buscador de vuelos",
  "LOCALE": "es-ES",
  "MONTHS": "enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre",
  "MONTH_YEAR": "{0} de {1}",
  "DURATION": "{0} h {1} min",
  "DIRECT": "directo",
  "ONE_STOP": "1 escala",
  "STOPS": "{0} escalas",
  "ONE_WAY": "solo ida",
  "DIRECT_ONLY": "solo directos",
  "RETURN_ON": "vuelta: {0}",
  "OFFERS": "{0} ofertas",
  "MODE_SAMPLE": "datos de ejemplo (sin token)",
  "MODE_REAL": "precios de Travelpayouts (Aviasales)",
  "SAMPLE": "ejemplo",
  "ANALYZING": "Analizando…",
  "ANALYZED_AT": "Analizada a las {} · la siguiente, a las {}",
  "EVERY_30": "Se analizan al abrir y cada 30 minutos",
  "NEXT_IN": "Próximo análisis en {} min",
  "NO_PRICES": "Sin precios para esas fechas",
  "NO_DAYS": "Sin precios por día",
  "HISTORY_SOON": "La evolución sale a partir del segundo análisis",
  "BEST": "Desde {} con {} · {} · {}",
  "MEDIAN": "precio medio {}",
  "SAME": "igual que antes",
  "DOWN": "▼ {} menos",
  "UP": "▲ {} más",
  "LOWEST_SEEN": "Lo más barato visto: {} ({}, {})",
  "ALERT_BELOW": "aviso por debajo de {}",
  "ALERT_TARGET": "{}: {}, por debajo de su precio",
  "ALERT_DOWN": "{}: ha bajado a {} ({} menos)",
  "ERROR": "No se pudo analizar: {}",
  "ERR_PLACES": "Escriba el origen y el destino",
  "ERR_DEPART": "La ida debe ser un mes (2026-12) o un día (2026-12-20)",
  "ERR_RETURN": "La vuelta debe ser un mes o un día, y no antes de la ida (o déjela vacía)",
  "ERR_TARGET": "El precio para avisar debe ser un número",
  "ERR_PLACE": "No se encuentra «{0}»: pruebe con el código IATA de la ciudad (por ejemplo, MAD)",
  "ERR_TOKEN": "El token de Travelpayouts del servidor no es válido",
  "ERR_LIMIT": "Demasiadas consultas: se reintenta en el próximo análisis"
};
// ------------------------------------------------------------------ utilidades
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
