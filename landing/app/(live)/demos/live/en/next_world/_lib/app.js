// Live world map: planes, ships and trains from public APIs on a map. The server (after // @server) downloads the data; the app draws it.
import { DmsApp, server } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = {
  "LOCALE": "en-US",
  "PLANES": "Planes",
  "SHIPS": "Ships",
  "TRAINS": "Trains",
  "PLANE": "Plane",
  "SHIP_FISHING": "Fishing",
  "SHIP_TUG": "Tug",
  "SHIP_PLEASURE": "Pleasure or sailing",
  "SHIP_SERVICE": "Port service",
  "SHIP_PASSENGER": "Passenger",
  "SHIP_CARGO": "Cargo",
  "SHIP_TANKER": "Tanker",
  "SHIP_OTHER": "Other",
  "TO_DEST": "Bound for {}",
  "NO_DEST": "No declared destination",
  "ON_GROUND": "On the ground",
  "KNOTS": "knots",
  "ALTITUDE": "Altitude: {} ({})",
  "HEADING": "Heading {}°",
  "LINE": "Line {}",
  "NO_SPEED": "No speed data",
  "SPAIN": "Renfe Cercanías · Spain",
  "FINLAND": "VR · Finland",
  "TRAIN_RENFE": "Commuter",
  "TRAIN_VR": "Train",
  "ERROR": "Could not read the data: {}",
  "LOADING": "Loading the data…",
  "LOADING_MAP": "Loading the map…",
  "UPDATING": "Updating…",
  "UPDATED": "Updated {} s ago",
  "PLANES_AT": "planes from {}",
  "AGO_S": "{} s ago",
  "AGO_MIN": "{} min ago",
  "IN_VIEW": "{} in view",
  "FOUND": "{} found",
  "SHOWING": "The first {} of {} in view",
  "SOURCE_OK": "{} · {} · {}",
  "SOURCE_ERROR": "Not responding: {}",
  "SOURCE_STALE": "the last good ones ({})",
  "SAMPLE": "Sample data",
  "EMPTY_VIEW": "Nothing in this view of the map. Zoom out or search by name.",
  "EMPTY_FOUND": "Nothing with that name in the visible layers."
};
// ------------------------------------------------------------------ utilidades
const RAD = Math.PI / 180;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const nf = (v, d = 0) =>
  new Intl.NumberFormat(TX.LOCALE, { minimumFractionDigits: d, maximumFractionDigits: d }).format(v);
const fmt = (s, ...a) => {
  let i = 0;
  return s.replace(/\{\}/g, () => String(a[i++] ?? ""));
};
const fold = (s) =>
  String(s ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();

// «hace 40 s», «hace 12 min».
const edad = (t) => {
  const s = Math.max(0, Math.round((Date.now() - t) / 1000));
  return s < 90 ? fmt(TX.AGO_S, s) : fmt(TX.AGO_MIN, Math.round(s / 60));
};

// Mercator, como los mapas de la web: la latitud estirada (en «grados»).
const mercY = (lat) => Math.log(Math.tan(Math.PI / 4 + (clamp(lat, -85, 85) * RAD) / 2)) / RAD;
const mercLat = (y) => (2 * Math.atan(Math.exp(y * RAD)) - Math.PI / 2) / RAD;
// La longitud más cerca de «c» (el mapa da la vuelta).
const near = (lon, c) => lon - 360 * Math.round((lon - c) / 360);

// Las vistas de cada zona: centro y zoom (1: el mundo entero).
const REGIONS = {
  world: { lon: 10, lat: 28, zoom: 1 },
  europe: { lon: 12, lat: 50, zoom: 4.2 },
  namerica: { lon: -97, lat: 40, zoom: 3 },
  samerica: { lon: -60, lat: -20, zoom: 2.4 },
  asia: { lon: 108, lat: 28, zoom: 2.4 },
  baltic: { lon: 22, lat: 60, zoom: 9 },
  spain: { lon: -3.6, lat: 40.2, zoom: 12 },
};

const KINDS = {
  plane: { icon: "flight", color: "#FFC24B" },
  ship: { icon: "directions_boat", color: "#3EE0C5" },
  train: { icon: "train", color: "#FF6B81" },
};

const SHIP_TYPES = [
  [30, 30, TX.SHIP_FISHING],
  [31, 32, TX.SHIP_TUG],
  [36, 37, TX.SHIP_PLEASURE],
  [50, 59, TX.SHIP_SERVICE],
  [60, 69, TX.SHIP_PASSENGER],
  [70, 79, TX.SHIP_CARGO],
  [80, 89, TX.SHIP_TANKER],
];
const shipType = (t) => (SHIP_TYPES.find(([a, b]) => t >= a && t <= b) || [0, 0, TX.SHIP_OTHER])[2];

// ------------------------------------------------------------------ un vehículo
// Lo que llega del servidor, con la posición «a ojo» entre una lectura y la
// siguiente (por la velocidad y el rumbo).
class Vehiculo {
  constructor(k, r, t0) {
    this.k = k;
    this.t0 = t0;
    if (k === "plane") {
      // [id, indicativo, matrícula o país, tipo, lon, lat, altitud m, m/s, rumbo]
      [this.id, this.name, this.from, this.model, this.lon, this.lat, this.alt, this.v, this.hdg] = r;
    } else if (k === "ship") {
      // [mmsi, nombre, tipo, lon, lat, nudos, rumbo, destino]
      [this.id, this.name, this.type, this.lon, this.lat, this.knots, this.hdg, this.dest] = r;
      this.v = (this.knots || 0) * 0.5144;
    } else {
      // [id, número, operador, lon, lat, km/h, línea]
      [this.id, this.num, this.op, this.lon, this.lat, this.kmh, this.line] = r;
      this.name = (this.op === "VR" ? TX.TRAIN_VR : TX.TRAIN_RENFE) + " " + this.num;
      this.v = 0;
    }
    this.name = String(this.name || this.id).trim() || String(this.id);
    this.key = k + ":" + this.id;
  }

  get icon() {
    return KINDS[this.k].icon;
  }

  get color() {
    return KINDS[this.k].color;
  }

  /// La posición ahora: la de la lectura, movida por la velocidad y el rumbo
  /// (como mucho 20 minutos los aviones y 10 los barcos).
  at(now) {
    if (!this.v || this.hdg == null || this.v < 0.5) return [this.lon, this.lat];
    const d = this.v * Math.min(this.k === "plane" ? 1200 : 600, Math.max(0, (now - this.t0) / 1000));
    const lat = this.lat + (d * Math.cos(this.hdg * RAD)) / 111320;
    const lon = this.lon + (d * Math.sin(this.hdg * RAD)) / (111320 * Math.max(0.2, Math.cos(this.lat * RAD)));
    return [lon, lat];
  }

  get sub() {
    if (this.k === "plane") {
      return [this.model, this.from, this.alt > 0 ? nf(this.alt) + " m" : TX.ON_GROUND].filter(Boolean).join(" · ");
    }
    if (this.k === "ship") {
      return [shipType(this.type), this.dest ? fmt(TX.TO_DEST, this.dest) : ""].filter(Boolean).join(" · ");
    }
    return [this.op, this.line].filter(Boolean).join(" · ");
  }

  get vel() {
    if (this.k === "plane") return this.v ? nf(this.v * 3.6) + " km/h" : "";
    if (this.k === "ship") return this.knots != null ? nf(this.knots, 1) + " " + TX.KNOTS : "";
    return this.kmh ? nf(this.kmh) + " km/h" : "";
  }

  /// Las líneas de la ficha.
  get lines() {
    if (this.k === "plane") {
      return [
        [this.model, this.from].filter(Boolean).join(" · ") || TX.PLANE,
        this.alt > 0 ? fmt(TX.ALTITUDE, nf(this.alt) + " m", nf(Math.round(this.alt / 0.3048 / 100) * 100) + " ft") : TX.ON_GROUND,
        [this.vel, this.hdg != null ? fmt(TX.HEADING, Math.round(this.hdg)) : ""].filter(Boolean).join(" · "),
        "ICAO " + String(this.id).toUpperCase(),
      ];
    }
    if (this.k === "ship") {
      return [
        shipType(this.type),
        this.dest ? fmt(TX.TO_DEST, this.dest) : TX.NO_DEST,
        [this.vel, this.hdg != null ? fmt(TX.HEADING, Math.round(this.hdg)) : ""].filter(Boolean).join(" · "),
        "MMSI " + this.id,
      ];
    }
    return [this.op === "VR" ? TX.FINLAND : TX.SPAIN, this.line ? fmt(TX.LINE, this.line) : "", this.vel || TX.NO_SPEED, ""];
  }
}

// ------------------------------------------------------------------ la app
export class App extends DmsApp {
  capas = { plane: true, ship: true, train: true };
  region = "world";
  view = { ...REGIONS.world };
  land = [];
  land50 = [];
  _pedido = {};
  items = [];
  fuentes = [];
  at = 0;
  sel = null;
  selKey = "";
  seguir = false;
  busqueda = "";
  cargando = false;
  error = "";
  leido = null;
  _w = 800;
  _h = 500;

  async start() {
    this.cargarMapa("110m");
    await this.actualizar();
    // Los datos cada 30 segundos; el dibujo (y «hace X s»), cada segundo.
    setInterval(() => this.actualizar(), 30000);
    setInterval(() => this.tick(), 1000);
  }

  /// La tierra: la de 1:110 millones al abrir y la de 1:50 millones (más
  /// detalle, más pesada) la primera vez que se acerca el mapa.
  cargarMapa(detalle) {
    this._pedido = { ...this._pedido, [detalle]: true };
    server
      .mapa({ detalle })
      .then((m) => {
        const land = m.land.map((rings) => {
          let a = Infinity, b = -Infinity, c = 90, d = -90;
          for (const r of rings)
            for (const [lo, la] of r) {
              a = Math.min(a, lo);
              b = Math.max(b, lo);
              c = Math.min(c, la);
              d = Math.max(d, la);
            }
          return { rings, box: [a, b, c, d] };
        });
        if (detalle === "50m") this.land50 = land;
        else this.land = land;
        this.notify();
      })
      .catch((e) => {
        this.error = fmt(TX.ERROR, e.message || e);
        this.notify();
      });
  }

  async actualizar() {
    if (this.cargando) return;
    this.cargando = true;
    this.notify();
    try {
      const d = await server.datos();
      const now = Date.now();
      // La hora de cada lectura, en el reloj de este navegador.
      const t0 = (x) => now - Math.max(0, d.now - (x.at || d.now));
      const items = [];
      for (const r of d.vuelos.items) items.push(new Vehiculo("plane", r, t0(d.vuelos)));
      for (const r of d.barcos.items) items.push(new Vehiculo("ship", r, t0(d.barcos)));
      for (const r of d.trenes.items) items.push(new Vehiculo("train", r, t0(d.trenes)));
      this.leido = { plane: t0(d.vuelos), ship: t0(d.barcos), train: t0(d.trenes) };
      this.items = items;
      this.fuentes = d.fuentes.map((f) => ({
        icon: KINDS[f.kind].icon,
        color: KINDS[f.kind].color,
        name: { plane: TX.PLANES, ship: TX.SHIPS, train: TX.TRAINS }[f.kind],
        detail:
          f.error && !f.n
            ? fmt(TX.SOURCE_ERROR, f.error)
            : fmt(TX.SOURCE_OK, f.sample ? TX.SAMPLE : f.fuente, nf(f.n), edad(Date.now() - Math.max(0, d.now - f.at))) +
              (f.error ? " · " + fmt(TX.SOURCE_STALE, f.error) : ""),
        n: nf(f.n),
      }));
      this.at = now;
      this.error = "";
      if (this.selKey) this.sel = items.find((i) => i.key === this.selKey) || null;
    } catch (e) {
      this.error = fmt(TX.ERROR, e.message || e);
    }
    this.cargando = false;
    this.notify();
  }

  tick() {
    if (this.view.zoom >= 3.5 && !this._pedido["50m"]) this.cargarMapa("50m");
    if (this.seguir && this.sel) {
      const [lon, lat] = this.sel.at(Date.now());
      this.view.lon = lon;
      this.view.lat = lat;
    }
    this.notify();
  }

  // ---------------------------------------------------------- contar
  cuenta(k) {
    let n = 0;
    for (const i of this.items) if (i.k === k) n++;
    return n;
  }

  get nAviones() {
    return nf(this.cuenta("plane"));
  }

  get nBarcos() {
    return nf(this.cuenta("ship"));
  }

  get nTrenes() {
    return nf(this.cuenta("train"));
  }

  get estado() {
    if (this.error) return this.error;
    if (!this.at) return TX.LOADING;
    const s = Math.round((Date.now() - this.at) / 1000);
    const planes = this.leido && this.capas.plane ? " · " + fmt(TX.PLANES_AT, edad(this.leido.plane)) : "";
    return (this.cargando ? TX.UPDATING : fmt(TX.UPDATED, s)) + planes + " · " + fmt(TX.IN_VIEW, nf(this.visibles().length));
  }

  // ---------------------------------------------------------- capas y zonas
  capa(k) {
    this.capas = { ...this.capas, [k]: !this.capas[k] };
    if (this.sel && !this.capas[this.sel.k]) this.cerrar();
    this.notify();
  }

  zona(r) {
    this.region = r;
    this.view = { ...REGIONS[r] };
    this.seguir = false;
    this.notify();
  }

  acercar() {
    if (this.sel) {
      [this.view.lon, this.view.lat] = this.sel.at(Date.now());
    }
    this.view.zoom = Math.min(256, this.view.zoom * 2);
    this.region = "";
    this.notify();
  }

  alejar() {
    this.view.zoom = Math.max(1, this.view.zoom / 2);
    this.region = "";
    this.notify();
  }

  // ---------------------------------------------------------- la ficha
  elegir(it) {
    this.sel = it;
    this.selKey = it ? it.key : "";
    if (it) {
      [this.view.lon, this.view.lat] = it.at(Date.now());
      if (this.view.zoom < 6) this.view.zoom = it.k === "train" ? 24 : 8;
      this.region = "";
    }
    this.notify();
  }

  cerrar() {
    this.sel = null;
    this.selKey = "";
    this.seguir = false;
    this.notify();
  }

  alternarSeguir() {
    this.seguir = !this.seguir;
    this.notify();
  }

  get selTitulo() {
    return this.sel ? this.sel.name : "";
  }

  selLinea(i) {
    return this.sel ? this.sel.lines[i] || "" : "";
  }

  get selIcono() {
    return this.sel ? this.sel.icon : "place";
  }

  get selColor() {
    return this.sel ? this.sel.color : "#888888";
  }

  // ---------------------------------------------------------- dibujar
  /// Los de las capas visibles que caen en la vista.
  visibles() {
    const v = this.view;
    const k = (this._w / 360) * v.zoom;
    const cy = mercY(v.lat);
    const now = Date.now();
    const out = [];
    for (const it of this.items) {
      if (!this.capas[it.k]) continue;
      const [lo, la] = it.at(now);
      const x = this._w / 2 + (near(lo, v.lon) - v.lon) * k;
      const y = this._h / 2 - (mercY(la) - cy) * k;
      if (x >= -8 && y >= -8 && x <= this._w + 8 && y <= this._h + 8) out.push([it, x, y]);
    }
    return out;
  }

  dibujar(ctx, w, h) {
    this._w = w;
    this._h = h;
    const v = this.view;
    const k = (w / 360) * v.zoom;
    const cy = mercY(v.lat);
    const X = (lon) => w / 2 + (lon - v.lon) * k;
    const Y = (lat) => h / 2 - (mercY(lat) - cy) * k;
    // El mar y la cuadrícula.
    ctx.fillStyle = "#0A1B2E";
    ctx.fillRect(0, 0, w, h);
    const step = v.zoom >= 8 ? 5 : v.zoom >= 3 ? 10 : 30;
    ctx.strokeStyle = "rgba(120,170,220,0.10)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    const lonA = v.lon - w / 2 / k, lonB = v.lon + w / 2 / k;
    for (let lo = Math.ceil(lonA / step) * step; lo <= lonB; lo += step) {
      ctx.moveTo(X(lo), 0);
      ctx.lineTo(X(lo), h);
    }
    for (let la = -80; la <= 80; la += step) {
      ctx.moveTo(0, Y(la));
      ctx.lineTo(w, Y(la));
    }
    ctx.stroke();
    // La tierra (tres veces si la vista cruza la línea de cambio de fecha).
    ctx.fillStyle = "#1C3550";
    ctx.strokeStyle = "#2E5579";
    ctx.lineWidth = 0.8;
    const land = v.zoom >= 3.5 && this.land50.length ? this.land50 : this.land;
    for (const shift of [-360, 0, 360]) {
      for (const p of land) {
        const [a, b, c, d] = p.box;
        if (X(b + shift) < 0 || X(a + shift) > w || Y(c) < 0 || Y(d) > h) continue;
        ctx.beginPath();
        for (const r of p.rings) {
          for (let i = 0; i < r.length; i++) {
            const x = X(r[i][0] + shift), y = Y(r[i][1]);
            if (i) ctx.lineTo(x, y);
            else ctx.moveTo(x, y);
          }
          ctx.closePath();
        }
        ctx.fill("evenodd");
        ctx.stroke();
      }
    }
    if (!this.land.length) {
      ctx.fillStyle = "rgba(255,255,255,0.6)";
      ctx.font = "14px system-ui, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(TX.LOADING_MAP, w / 2, h / 2);
      ctx.textAlign = "left";
    }
    // Los vehículos: una sola ruta por tipo (miles de puntos, rápido).
    const vis = this.visibles();
    const s = clamp(1.4 + v.zoom * 0.35, 2, 6);
    const paths = { plane: new Path2D(), ship: new Path2D(), train: new Path2D() };
    for (const [it, x, y] of vis) {
      const p = paths[it.k];
      if (it.k === "plane") {
        const a = (it.hdg || 0) * RAD;
        const dx = Math.sin(a), dy = -Math.cos(a);
        p.moveTo(x + dx * s * 1.7, y + dy * s * 1.7);
        p.lineTo(x - dx * s - dy * s, y - dy * s + dx * s);
        p.lineTo(x - dx * s * 0.4, y - dy * s * 0.4);
        p.lineTo(x - dx * s + dy * s, y - dy * s - dx * s);
        p.closePath();
      } else if (it.k === "ship") {
        p.moveTo(x + s * 0.9, y);
        p.arc(x, y, s * 0.9, 0, Math.PI * 2);
      } else {
        p.rect(x - s, y - s, s * 2, s * 2);
      }
    }
    for (const kk of ["ship", "train", "plane"]) {
      ctx.fillStyle = KINDS[kk].color;
      ctx.fill(paths[kk]);
    }
    // El elegido.
    if (this.sel && this.capas[this.sel.k]) {
      const [lo, la] = this.sel.at(Date.now());
      const x = X(near(lo, v.lon)), y = Y(la);
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(x, y, s * 2.6 + 3, 0, Math.PI * 2);
      ctx.stroke();
      ctx.font = "600 13px system-ui, sans-serif";
      const label = this.sel.name;
      const tw = ctx.measureText(label).width;
      const lx = clamp(x + s * 2.6 + 8, 4, w - tw - 12), ly = clamp(y - 10, 4, h - 24);
      ctx.fillStyle = "rgba(10,20,35,0.85)";
      ctx.fillRect(lx - 4, ly, tw + 8, 20);
      ctx.fillStyle = "#ffffff";
      ctx.fillText(label, lx, ly + 14);
    }
  }

  /// Un toque: el vehículo más cerca (a 14 px) o, si no hay, centrar ahí.
  tocar(x, y) {
    let best = null, bd = 14 * 14;
    for (const [it, ix, iy] of this.visibles()) {
      const d = (ix - x) ** 2 + (iy - y) ** 2;
      if (d < bd) {
        bd = d;
        best = it;
      }
    }
    if (best) {
      this.sel = best;
      this.selKey = best.key;
    } else {
      const v = this.view, k = (this._w / 360) * v.zoom;
      v.lon = near(v.lon + (x - this._w / 2) / k, 0);
      v.lat = clamp(mercLat(mercY(v.lat) - (y - this._h / 2) / k), -70, 80);
      this.seguir = false;
      this.region = "";
    }
    this.notify();
  }

  // ---------------------------------------------------------- la lista
  get lista() {
    const q = fold(this.busqueda.trim());
    let out;
    if (q) {
      out = this.items.filter(
        (i) =>
          this.capas[i.k] &&
          fold([i.name, i.id, i.from, i.model, i.dest, i.line, i.op].filter(Boolean).join(" ")).includes(q),
      );
    } else {
      out = this.visibles().map(([it]) => it);
    }
    // Primero los que empiezan por lo buscado; después, por nombre.
    const first = (i) => (q && fold(i.name).startsWith(q) ? 0 : 1);
    out.sort((a, b) => first(a) - first(b) || a.name.localeCompare(b.name));
    this._total = out.length;
    return out.slice(0, 200);
  }

  get vacio() {
    return this.busqueda.trim() ? TX.EMPTY_FOUND : TX.EMPTY_VIEW;
  }

  get listaTitulo() {
    const n = this.lista.length;
    return this.busqueda.trim()
      ? fmt(TX.FOUND, nf(this._total))
      : n < this._total
        ? fmt(TX.SHOWING, nf(n), nf(this._total))
        : fmt(TX.IN_VIEW, nf(this._total));
  }
}
