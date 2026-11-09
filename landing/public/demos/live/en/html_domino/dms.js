// DMarlon Studio: el motor de la web en HTML. Generado: no lo edite.
"use strict";

const ROUTES = {"Mesa":"/"};
const NAV = [];

/// Escapa un texto para ponerlo en el HTML.
function esc(v) {
  return String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

/// Un valor de CSS: los números van en px.
function css(v) {
  if (v === null || v === undefined || v === false) return "unset";
  return typeof v === "number" ? v + "px" : String(v);
}

/// La base de App: notify() vuelve a dibujar; go y home cambian de pantalla.
class DmsApp {
  _args = {};

  notify() {
    dmsRender();
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

const router = {
  path() {
    return window.location.hash.slice(1) || "/";
  },
  push(path) {
    window.location.hash = path;
  },
  replace(path) {
    window.history.replaceState(null, "", "#" + path);
    dmsRender();
  },
  back() {
    window.history.back();
  },
};

/// Los manejadores de la pantalla dibujada (data-click="n"…) y lo que
/// dibuja cada lienzo (data-paint="n").
const ui = {
  handlers: [],
  paints: [],
  on(f) {
    this.handlers.push(f);
    return this.handlers.length - 1;
  },
  paint(f) {
    this.paints.push(f);
    return this.paints.length - 1;
  },
};

/// Dibuja los lienzos de la pantalla, a la resolución de la pantalla.
function dmsPaint() {
  if (!root) return;
  root.querySelectorAll("canvas[data-paint]").forEach((c) => {
    const f = ui.paints[+c.dataset.paint];
    if (!f) return;
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
    f(ctx, w, h);
  });
}

function dmsScreen(ui, router, { title, back, actions, fab, body }) {
  const path = router.path();
  const inNav = NAV.some((n) => n.path === path);
  const screen = `<div class="screen">
    ${title === null ? "" : `<header class="bar">
      ${back ? `<button type="button" class="icon-btn" aria-label="Volver" data-click="${ui.on(() => router.back())}"><span class="ms">arrow_back</span></button>` : ""}
      <h1 class="bar-title">${esc(title)}</h1>
      ${actions.map((a) => `<button type="button" class="icon-btn"${a.on === null ? "" : ` data-click="${a.on}"`}><span class="ms">${esc(a.icon)}</span>${a.badge !== null && a.badge !== "0" && a.badge !== "" ? `<span class="badge">${esc(a.badge)}</span>` : ""}</button>`).join("")}
    </header>`}
    <main class="content">${body}</main>
    ${fab ? `<button type="button" class="fab" data-click="${fab.on}"><span class="ms">${esc(fab.icon)}</span></button>` : ""}
  </div>`;
  if (!inNav) return screen;
  return `<div class="shell"><nav class="nav">${NAV.map((n) => `<button type="button" class="nav-item${n.path === path ? " on" : ""}" data-click="${ui.on(() => router.replace(n.path))}"><span class="ms">${esc(n.icon)}</span><span>${esc(n.label)}</span></button>`).join("")}</nav><div class="shell-main">${screen}</div></div>`;
}

function dmsMissing(ui, router) {
  return `<div class="screen"><main class="content center col" style="gap:12px;padding:32px">
    <span class="ms" style="font-size:48px">link_off</span>
    <p>Esta pantalla se abre desde la app.</p>
    <button type="button" class="btn btn-filled" data-click="${ui.on(() => router.replace("/"))}">Ir al inicio</button>
  </main></div>`;
}

let app;
let root;

/// Dibuja la pantalla de la ruta; los campos conservan el foco y el cursor.
function dmsRender() {
  if (!root) return;
  const active = document.activeElement;
  const key = active && active.dataset ? active.dataset.key : null;
  const start = key ? active.selectionStart : null;
  const end = key ? active.selectionEnd : null;
  const path = router.path();
  const name = Object.keys(ROUTES).find((k) => ROUTES[k] === path) || Object.keys(ROUTES)[0];
  ui.handlers = [];
  ui.paints = [];
  root.innerHTML = SCREENS[name](app, ui, router);
  dmsPaint();
  if (key) {
    const el = root.querySelector(`[data-key="${key}"]`);
    if (el) {
      el.focus();
      try {
        el.setSelectionRange(start, end);
      } catch (_) {}
    }
  }
}

function dmsStart(App) {
  app = new App();
  root = document.getElementById("root");
  const call = (el, attr, ...args) => {
    const id = el.getAttribute(attr);
    if (id !== null && ui.handlers[+id]) ui.handlers[+id](...args);
  };
  root.addEventListener("click", (e) => {
    // Un toque en un lienzo: sus coordenadas en píxeles CSS.
    const cv = e.target.closest("canvas[data-tap]");
    if (cv) {
      const b = cv.getBoundingClientRect();
      call(cv, "data-tap", e.clientX - b.left, e.clientY - b.top);
      return;
    }
    const el = e.target.closest("[data-click]");
    if (!el || el.disabled) return;
    // Lo de dentro de una tarjeta no la toca a ella (como en Flutter).
    const own = e.target.closest("[data-stop]");
    if (own && own !== el && el.contains(own)) return;
    call(el, "data-click");
  });
  root.addEventListener("input", (e) => {
    if (e.target.matches("[data-input]")) call(e.target, "data-input", e.target.value);
  });
  root.addEventListener("change", (e) => {
    if (e.target.matches("[data-change]")) call(e.target, "data-change", e.target.checked);
  });
  root.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && e.target.matches("[data-enter]")) call(e.target, "data-enter");
  });
  window.addEventListener("hashchange", dmsRender);
  window.addEventListener("resize", dmsPaint);
  dmsRender();
  Promise.resolve(app.start()).then(() => dmsRender());
}
