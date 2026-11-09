// Velocidad de internet: el ping, la bajada y la subida medidos con el servidor de la web (después de // @server).
import { DmsApp, server, serverUrl } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = {
  "LOCALE": "es-ES",
  "START": "Empezar",
  "STOP": "Parar",
  "AGAIN": "Medir otra vez",
  "ERROR": "No se pudo medir: {}",
  "PHASE_IDLE": "Pulse Empezar: mide el ping, la bajada y la subida en unos 20 segundos.",
  "PHASE_PING": "Midiendo el ping…",
  "PHASE_DOWN": "Midiendo la bajada…",
  "PHASE_UP": "Midiendo la subida…",
  "PHASE_DONE": "Listo. Se ha guardado en el historial.",
  "JITTER": "jitter {} ms",
  "JITTER_NONE": "jitter —",
  "PING_MS": "{} ms",
  "ROW_TITLE": "↓ {} · ↑ {} Mbps",
  "NO_HISTORY": "Aún no hay mediciones.",
  "HISTORY_AVG": "{} mediciones · de media ↓ {} · ↑ {} Mbps · {} ms",
  "SERVER": "Servidor: {} ({})",
  "SERVER_UNKNOWN": "Buscando el servidor…",
  "YOUR_IP": "su IP: {}",
  "NEEDS": "Necesita ↓ {} y ↑ {} Mbps",
  "USE_WEB": "Navegar y correo",
  "USE_MUSIC": "Música en streaming",
  "USE_CALL": "Videollamadas en HD",
  "USE_HD": "Vídeo en Full HD",
  "USE_4K": "Vídeo en 4K",
  "USE_GAMES": "Juegos en línea (ping bajo)",
  "USE_HOME": "Una casa con varias personas a la vez",
  "USE_UPLOAD": "Subir vídeos y copias a la nube"
};
// ------------------------------------------------------------------ utilidades
const nf = (v, d = 0) =>
  new Intl.NumberFormat(TX.LOCALE, { minimumFractionDigits: d, maximumFractionDigits: d }).format(v);
const fmt = (s, ...a) => {
  let i = 0;
  return s.replace(/\{\}/g, () => String(a[i++] ?? ""));
};
const now = () => performance.now();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const median = (v) => {
  const s = [...v].sort((a, b) => a - b);
  const n = s.length;
  return n ? (n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2) : 0;
};
/// Megabits por segundo, con los decimales que tengan sentido.
const mbps = (v) => (v == null ? "—" : nf(v, v < 10 ? 2 : v < 100 ? 1 : 0));

// La escala del indicador: más sitio para las velocidades bajas.
const MARKS = [0, 5, 10, 25, 50, 100, 250, 500, 1000];
const toUnit = (v) => {
  v = Math.max(0, Math.min(1000, v || 0));
  for (let i = 1; i < MARKS.length; i++) {
    if (v <= MARKS[i]) return (i - 1 + (v - MARKS[i - 1]) / (MARKS[i] - MARKS[i - 1])) / (MARKS.length - 1);
  }
  return 1;
};

// Lo que hace falta para cada cosa (bajada y subida en Mbps, ping en ms).
const USES = [
  [TX.USE_WEB, 1, 0.5, 300],
  [TX.USE_MUSIC, 2, 0.5, 300],
  [TX.USE_CALL, 4, 3, 150],
  [TX.USE_HD, 8, 1, 300],
  [TX.USE_4K, 25, 1, 300],
  [TX.USE_GAMES, 15, 3, 50],
  [TX.USE_HOME, 100, 20, 100],
  [TX.USE_UPLOAD, 25, 50, 300],
];

const HISTORY_KEY = "dms_speed_history";

// ------------------------------------------------------------------ la app
export class App extends DmsApp {
  fase = "";           // "", "ping", "down", "up", "done", "error"
  ping = null;
  jitter = null;
  bajada = null;
  subida = null;
  ahora = 0;           // la velocidad que marca la aguja
  progreso = 0;        // 0..1 de la fase
  info = null;
  historial = [];
  error = "";
  _parar = false;

  async start() {
    try {
      this.historial = JSON.parse(localStorage.getItem(HISTORY_KEY) || "[]");
    } catch {
      this.historial = [];
    }
    try {
      this.info = await server.info();
    } catch (e) {
      this.info = null;
    }
    this.notify();
  }

  get midiendo() {
    return this.fase === "ping" || this.fase === "down" || this.fase === "up";
  }

  get boton() {
    return this.midiendo ? TX.STOP : this.fase === "done" || this.fase === "error" ? TX.AGAIN : TX.START;
  }

  get botonIcono() {
    return this.midiendo ? "stop" : "speed";
  }

  alternar() {
    if (this.midiendo) this._parar = true;
    else this.medir();
  }

  // ---------------------------------------------------------- medir
  async medir() {
    this._parar = false;
    this.ping = this.jitter = this.bajada = this.subida = null;
    this.error = "";
    try {
      await this.medirPing();
      if (!this._parar) await this.medirBajada();
      if (!this._parar) await this.medirSubida();
      if (this._parar) {
        this.fase = "";
        this.ahora = 0;
      } else {
        this.fase = "done";
        this.ahora = this.bajada;
        this.guardar();
      }
    } catch (e) {
      this.fase = "error";
      this.error = fmt(TX.ERROR, e.message || e);
      this.ahora = 0;
    }
    this.notify();
  }

  /// La latencia: doce peticiones mínimas, una tras otra (la primera no
  /// cuenta: abre la conexión). El ping es la mediana; el jitter, cuánto
  /// cambia de una a la siguiente.
  async medirPing() {
    this.fase = "ping";
    this.progreso = 0;
    this.notify();
    const times = [];
    for (let i = 0; i < 12 && !this._parar; i++) {
      const t = now();
      const r = await fetch(serverUrl("eco", { n: i, t: Date.now() }), { cache: "no-store" });
      await r.arrayBuffer();
      if (i > 0) times.push(now() - t);
      this.progreso = (i + 1) / 12;
      this.ping = median(times);
      this.notify();
    }
    let j = 0;
    for (let i = 1; i < times.length; i++) j += Math.abs(times[i] - times[i - 1]);
    this.ping = median(times);
    this.jitter = times.length > 1 ? j / (times.length - 1) : 0;
  }

  /// La bajada: cuatro descargas a la vez durante unos 10 segundos. Se
  /// cuentan los bytes según llegan; el primer segundo no cuenta (la
  /// conexión aún acelera).
  async medirBajada() {
    this.fase = "down";
    this.progreso = 0;
    this.ahora = 0;
    this.notify();
    // Como mucho 100 MB: las conexiones muy rápidas acaban antes (y la
    // web no gasta de más).
    const dur = 10000, warm = 1000, maxBytes = 100e6;
    const t0 = now();
    let total = 0, counted = 0, tc = 0, size = 1e6;
    const samples = [];
    const worker = async () => {
      while (!this._parar && now() - t0 < dur && total < maxBytes) {
        const r = await fetch(serverUrl("descarga", { bytes: Math.round(size), n: Math.random() }), { cache: "no-store" });
        if (!r.ok || !r.body) throw new Error("HTTP " + r.status);
        const reader = r.body.getReader();
        const ts = now();
        for (;;) {
          const { done, value } = await reader.read();
          if (done) break;
          total += value.length;
          if (now() - t0 > warm) {
            if (!tc) tc = now();
            counted += value.length;
          }
          if (this._parar || now() - t0 > dur) {
            reader.cancel().catch(() => {});
            break;
          }
        }
        // Más grande si la petición fue rápida (menos tiempo perdido entre una y otra).
        if (now() - ts < 1500) size = Math.min(size * 2, 25e6);
      }
    };
    const timer = setInterval(() => {
      const t = now() - t0;
      samples.push([t, total]);
      // La aguja: lo que ha llegado en el último segundo.
      const old = samples.find((s) => s[0] >= t - 1000) || samples[0];
      const dt = (t - old[0]) / 1000;
      if (dt > 0.2) this.ahora = ((total - old[1]) * 8) / dt / 1e6;
      if (tc) this.bajada = (counted * 8) / ((now() - tc) / 1000) / 1e6;
      this.progreso = Math.min(1, t / dur);
      this.notify();
    }, 200);
    try {
      await Promise.all([worker(), worker(), worker(), worker()]);
    } finally {
      clearInterval(timer);
    }
    const secs = tc ? (now() - tc) / 1000 : (now() - t0) / 1000;
    this.bajada = ((tc ? counted : total) * 8) / Math.max(0.001, secs) / 1e6;
  }

  /// La subida: tres envíos a la vez durante unos 8 segundos, de 1 a 4 MB
  /// cada uno (el límite de Vercel es de 4,5 MB por petición). Cuenta lo que
  /// el servidor dice que ha recibido.
  async medirSubida() {
    this.fase = "up";
    this.progreso = 0;
    this.ahora = 0;
    this.notify();
    const dur = 8000, maxBytes = 25e6;
    const block = new Uint8Array(4e6);
    for (let i = 0; i < block.length; i += 65536) crypto.getRandomValues(block.subarray(i, Math.min(block.length, i + 65536)));
    const t0 = now();
    let total = 0, size = 1e6;
    const worker = async () => {
      while (!this._parar && now() - t0 < dur && total < maxBytes) {
        const ts = now();
        const r = await fetch(serverUrl("subida", { n: Math.random() }), {
          method: "POST",
          headers: { "content-type": "application/octet-stream" },
          body: block.subarray(0, size),
        });
        const d = await r.json();
        if (!r.ok) throw new Error(d.error || "HTTP " + r.status);
        total += d.bytes;
        if (now() - ts < 1000) size = Math.min(size * 2, 4e6);
        const secs = (now() - t0) / 1000;
        this.subida = (total * 8) / secs / 1e6;
        this.ahora = this.subida;
        this.progreso = Math.min(1, (now() - t0) / dur);
        this.notify();
      }
    };
    await Promise.all([worker(), worker(), worker()]);
    this.subida = (total * 8) / Math.max(0.001, (now() - t0) / 1000) / 1e6;
  }

  // ---------------------------------------------------------- el historial
  guardar() {
    this.historial = [
      { at: Date.now(), ping: this.ping, jitter: this.jitter, bajada: this.bajada, subida: this.subida, donde: this.donde },
      ...this.historial,
    ].slice(0, 30);
    try {
      localStorage.setItem(HISTORY_KEY, JSON.stringify(this.historial));
    } catch {}
  }

  borrar() {
    this.historial = [];
    try {
      localStorage.removeItem(HISTORY_KEY);
    } catch {}
    this.notify();
  }

  get filas() {
    return this.historial.map((h) => ({
      title: fmt(TX.ROW_TITLE, mbps(h.bajada), mbps(h.subida)),
      sub: [new Date(h.at).toLocaleString(TX.LOCALE, { dateStyle: "medium", timeStyle: "short" }), h.donde].filter(Boolean).join(" · "),
      ping: fmt(TX.PING_MS, nf(h.ping || 0)),
    }));
  }

  get resumenHistorial() {
    const n = this.historial.length;
    if (!n) return TX.NO_HISTORY;
    const avg = (k) => this.historial.reduce((s, h) => s + (h[k] || 0), 0) / n;
    return fmt(TX.HISTORY_AVG, nf(n), mbps(avg("bajada")), mbps(avg("subida")), nf(avg("ping")));
  }

  // ---------------------------------------------------------- textos
  get pingTexto() {
    return this.ping == null ? "—" : nf(this.ping);
  }

  get jitterTexto() {
    return this.jitter == null ? TX.JITTER_NONE : fmt(TX.JITTER, nf(this.jitter, 1));
  }

  get bajadaTexto() {
    return mbps(this.bajada);
  }

  get subidaTexto() {
    return mbps(this.subida);
  }

  get donde() {
    const i = this.info;
    if (!i) return "";
    return [i.city, i.country].filter(Boolean).join(", ");
  }

  get servidor() {
    const i = this.info;
    if (!i) return TX.SERVER_UNKNOWN;
    return fmt(TX.SERVER, i.host, i.region) + (i.ip ? " · " + fmt(TX.YOUR_IP, i.ip) : "") + (this.donde ? " · " + this.donde : "");
  }

  get estado() {
    switch (this.fase) {
      case "ping":
        return TX.PHASE_PING;
      case "down":
        return TX.PHASE_DOWN;
      case "up":
        return TX.PHASE_UP;
      case "done":
        return TX.PHASE_DONE;
      case "error":
        return this.error;
      default:
        return TX.PHASE_IDLE;
    }
  }

  /// Para qué alcanza la conexión medida.
  get usos() {
    if (this.fase !== "done") return [];
    return USES.map(([what, down, up, ping]) => {
      const ok = this.bajada >= down && this.subida >= up && this.ping <= ping;
      return { what, ok, icon: ok ? "check_circle" : "cancel", color: ok ? "#2E9E6A" : "#C2453B", need: fmt(TX.NEEDS, nf(down), nf(up)) };
    });
  }

  get hayUsos() {
    return this.fase === "done";
  }

  // ---------------------------------------------------------- el indicador
  dibujar(ctx, w, h) {
    // Los colores del tema oscuro de la app.
    const fg = "#E8EAED", muted = "#9AA0A6", track = "#2A2F37";
    const cx = w / 2, cy = h * 0.58, r = Math.min(w * 0.4, h * 0.5);
    const a0 = Math.PI * 0.8, a1 = Math.PI * 2.2;
    const at = (u) => a0 + (a1 - a0) * u;
    const lw = Math.max(10, r * 0.11);
    ctx.lineCap = "round";
    ctx.lineWidth = lw;
    ctx.strokeStyle = track;
    ctx.beginPath();
    ctx.arc(cx, cy, r, a0, a1);
    ctx.stroke();
    // Lo que marca, con un degradado.
    const u = toUnit(this.ahora);
    if (u > 0.002) {
      const g = ctx.createLinearGradient(cx - r, 0, cx + r, 0);
      const up = this.fase === "up";
      g.addColorStop(0, up ? "#8E5CF7" : "#1FA2FF");
      g.addColorStop(1, up ? "#E85CF7" : "#12D8A5");
      ctx.strokeStyle = g;
      ctx.beginPath();
      ctx.arc(cx, cy, r, a0, at(u));
      ctx.stroke();
    }
    // Las marcas.
    ctx.fillStyle = muted;
    ctx.font = `${Math.max(10, r * 0.075)}px system-ui, sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    MARKS.forEach((m, i) => {
      const a = at(i / (MARKS.length - 1));
      ctx.fillText(String(m), cx + Math.cos(a) * (r - lw * 1.6), cy + Math.sin(a) * (r - lw * 1.6));
    });
    // La aguja.
    const a = at(u);
    ctx.strokeStyle = fg;
    ctx.lineWidth = Math.max(2, r * 0.02);
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(a) * r * 0.12, cy + Math.sin(a) * r * 0.12);
    ctx.lineTo(cx + Math.cos(a) * (r - lw * 2.4), cy + Math.sin(a) * (r - lw * 2.4));
    ctx.stroke();
    ctx.fillStyle = fg;
    ctx.beginPath();
    ctx.arc(cx, cy, r * 0.06, 0, Math.PI * 2);
    ctx.fill();
    // El número.
    const big = this.fase === "ping" ? this.pingTexto : this.ahora ? mbps(this.ahora) : "0";
    ctx.font = `600 ${Math.max(22, r * 0.3)}px system-ui, sans-serif`;
    ctx.fillText(big, cx, cy + r * 0.3);
    ctx.fillStyle = muted;
    ctx.font = `${Math.max(12, r * 0.09)}px system-ui, sans-serif`;
    ctx.fillText(this.fase === "ping" ? "ms" : "Mbps", cx, cy + r * 0.52);
    // La barra de la fase.
    if (this.midiendo) {
      const bw = r * 0.9, by = cy + r * 0.66;
      ctx.fillStyle = track;
      ctx.fillRect(cx - bw / 2, by, bw, 4);
      ctx.fillStyle = this.fase === "up" ? "#B35CF7" : "#1FA2FF";
      ctx.fillRect(cx - bw / 2, by, bw * this.progreso, 4);
    }
  }
}
