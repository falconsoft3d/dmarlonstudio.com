"use client";
// DMarlon Studio: la base de la app web. Generado: no lo edite.
import { usePathname, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef } from "react";

/// Las rutas de las pantallas y el menú.
export const ROUTES = {"Rutas":"/demos/live/es/next_flights","Nueva":"/demos/live/es/next_flights/nueva","Ruta":"/demos/live/es/next_flights/ruta"};
export const NAV = [];

/// El servidor: cada función que exporta lib/server.js (lo que va después
/// de «// @server» en la lógica) se llama con await server.nombre({ … }) y
/// devuelve lo que ella devuelva.
export const API = "/demos/live/es/next_flights/api";
export const server = new Proxy(
  {},
  {
    get: (_, fn) =>
      typeof fn !== "string" || fn === "then"
        ? undefined
        : async (args = {}) => {
            const r = await fetch(API + "/" + fn, {
              method: "POST",
              headers: { "content-type": "application/json" },
              body: JSON.stringify(args),
            });
            const data = await r.json().catch(() => null);
            if (!r.ok) throw new Error((data && data.error) || r.status + " " + r.statusText);
            return data;
          },
  },
);

/// La dirección de una función del servidor (para fetch, enlaces o descargas).
export function serverUrl(fn, args) {
  const q = args ? "?" + new URLSearchParams(args) : "";
  return API + "/" + fn + q;
}

/// La base de App: notify() vuelve a dibujar las pantallas; go y home
/// cambian de pantalla.
export class DmsApp {
  _subs = new Set();
  _version = 0;
  _args = {};

  subscribe = (f) => {
    this._subs.add(f);
    return () => this._subs.delete(f);
  };

  version = () => this._version;

  notify() {
    this._version++;
    for (const f of this._subs) f();
  }

  go(router, screen, arg) {
    this._args[screen] = arg;
    router.push(ROUTES[screen]);
  }

  home(router, screen) {
    router.replace(ROUTES[screen]);
  }

  arg(screen) {
    return this._args[screen];
  }

  async start() {}
}

/// Un lienzo: lo dibuja paint(ctx, w, h) (el contexto 2D y el tamaño en
/// píxeles CSS) cada vez que la app avisa, y onTap(x, y) recibe los toques.
export function DmsCanvas({ aspect = 1.6, height, paint, onTap }) {
  const ref = useRef(null);
  const draw = useRef(paint);
  useEffect(() => {
    draw.current = paint;
  });
  const redraw = useCallback(() => {
    const c = ref.current;
    if (!c) return;
    const w = c.clientWidth;
    const h = c.clientHeight;
    const r = window.devicePixelRatio || 1;
    if (c.width !== Math.round(w * r) || c.height !== Math.round(h * r)) {
      c.width = Math.round(w * r);
      c.height = Math.round(h * r);
    }
    const ctx = c.getContext("2d");
    ctx.setTransform(r, 0, 0, r, 0, 0);
    ctx.clearRect(0, 0, w, h);
    draw.current(ctx, w, h);
  }, []);
  useEffect(() => {
    redraw();
  });
  useEffect(() => {
    const ro = new ResizeObserver(redraw);
    ro.observe(ref.current);
    return () => ro.disconnect();
  }, [redraw]);
  const tap = (e) => {
    const b = e.currentTarget.getBoundingClientRect();
    onTap(e.clientX - b.left, e.clientY - b.top);
  };
  return (
    <canvas
      ref={ref}
      className="canvas"
      style={height ? { height } : { aspectRatio: String(aspect), width: `min(100%, calc((100dvh - 96px) * ${aspect}))` }}
      onClick={onTap ? tap : undefined}
    />
  );
}

export function DmsScreen({ title, back, actions = [], fab, children }) {
  const router = useRouter();
  return (
    <div className="screen">
      {title !== null && (
        <header className="bar">
          {back && (
            <button type="button" className="icon-btn" aria-label="Volver" onClick={() => router.back()}>
              <span className="ms">arrow_back</span>
            </button>
          )}
          <h1 className="bar-title">{title}</h1>
          {actions.map((a, i) => (
            <button key={i} type="button" className="icon-btn" onClick={a.onClick}>
              <span className="ms">{a.icon}</span>
              {a.badge !== null && a.badge !== "0" && a.badge !== "" && <span className="badge">{a.badge}</span>}
            </button>
          ))}
        </header>
      )}
      <main className="content">{children}</main>
      {fab && (
        <button type="button" className="fab" onClick={fab.onClick}>
          <span className="ms">{fab.icon}</span>
        </button>
      )}
    </div>
  );
}

export function DmsMissing({ router }) {
  return (
    <div className="screen">
      <main className="content center col" style={{ gap: 12, padding: 32 }}>
        <span className="ms" style={{ fontSize: 48 }}>link_off</span>
        <p>Esta pantalla se abre desde la app.</p>
        <button type="button" className="btn btn-filled" onClick={() => router.replace("/")}>Ir al inicio</button>
      </main>
    </div>
  );
}

/// El menú: barra lateral en pantallas anchas y barra abajo en las estrechas.
export function DmsShell({ children }) {
  const path = usePathname();
  const router = useRouter();
  const inNav = NAV.some((n) => n.path === path);
  if (!inNav) return children;
  return (
    <div className="shell">
      <nav className="nav">
        {NAV.map((n) => (
          <button
            key={n.path}
            type="button"
            className={"nav-item" + (n.path === path ? " on" : "")}
            onClick={() => router.replace(n.path)}
          >
            <span className="ms">{n.icon}</span>
            <span>{n.label}</span>
          </button>
        ))}
      </nav>
      <div className="shell-main">{children}</div>
    </div>
  );
}
