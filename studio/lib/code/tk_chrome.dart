import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_codegen.dart';
import 'tk_electron.dart';
import 'tk_electron_runtime.dart';
import 'tk_model.dart';
import 'tk_unit.dart';

/// Genera una extensión de Chrome (Manifest V3) cuya ventana emergente es el
/// diseño: el mismo motor de React que Electron, con React empaquetado
/// dentro (una extensión no puede cargar código de fuera) y un anfitrión que
/// usa las API de Chrome. Sin ellas (la vista previa del estudio), las imita.
class TkChrome {
  TkChrome._();

  /// Los archivos de React que se empaquetan (del entorno compartido).
  static const _react = {
    'react': 'react/cjs/react.production.js',
    'scheduler': 'scheduler/cjs/scheduler.production.js',
    'react-dom': 'react-dom/cjs/react-dom.production.js',
    'react-dom/client': 'react-dom/cjs/react-dom-client.production.js',
  };

  /// react.js: React y React DOM con un `require` mínimo (window.dmsRequire).
  static String reactBundle(String nodeModules) {
    final b = StringBuffer()
      ..writeln('// React (MIT, Meta Platforms) packed by DMarlon Studio.')
      ..writeln('(function () {')
      ..writeln('  "use strict";')
      ..writeln('  var defs = {};');
    for (final MapEntry(key: name, value: file) in _react.entries) {
      final f = File(p.join(nodeModules, file));
      if (!f.existsSync()) {
        throw UserError(tr('Falta {0} en el entorno de React.', [file]));
      }
      b
        ..writeln(
          '  defs[${jsonEncode(name)}] = function (module, exports, require) {',
        )
        ..writeln(f.readAsStringSync())
        ..writeln('  };');
    }
    b
      ..writeln('  var cache = {};')
      ..writeln('  function req(name) {')
      ..writeln('    if (cache[name]) return cache[name].exports;')
      ..writeln(
        '    if (!defs[name]) throw new Error("Cannot find module " + name);',
      )
      ..writeln('    var module = { exports: {} };')
      ..writeln('    cache[name] = module;')
      ..writeln('    defs[name](module, module.exports, req);')
      ..writeln('    return module.exports;')
      ..writeln('  }')
      ..writeln('  window.dmsRequire = req;')
      ..writeln('})();');
    return b.toString();
  }

  static String _npmName(String name) {
    final s = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'dmarlon-extension' : s;
  }

  /// El manifest.json de la extensión.
  static String manifest(TkDesign d, String name, String description) =>
      const JsonEncoder.withIndent('  ').convert({
        'manifest_version': 3,
        'name': d.title.isEmpty ? name : d.title,
        'version': '1.0.0',
        if (description.isNotEmpty) 'description': description,
        'action': {
          'default_popup': 'popup.html',
          'default_title': d.title.isEmpty ? name : d.title,
        },
        'permissions': ['storage', 'activeTab', 'scripting'],
      });

  static String _popup(TkDesign d, String unit) {
    final bg = TkCodegen.color(d.prop(tkFormBg)) ?? '#f0f0f0';
    return '<!doctype html>\n<html>\n<head>\n<meta charset="utf-8">\n'
        '<title>${const HtmlEscape().convert(d.title)}</title>\n'
        '<style>$tkElectronCss\n'
        // Una ventana emergente toma el tamaño de su contenido (800×600 como
        // mucho).
        'body { width: ${d.width.clamp(25, 800)}px; height: ${d.height.clamp(25, 600)}px; background: $bg; }\n'
        '#root { width: 100%; height: 100%; }\n'
        '.dms-modal { position: fixed; inset: 0; background: rgba(0,0,0,.35); display: flex; align-items: center; justify-content: center; z-index: 100; }\n'
        '.dms-modal div { background: #fff; color: #000; border-radius: 6px; padding: 14px 16px; max-width: 80%; box-shadow: 0 6px 24px rgba(0,0,0,.3); white-space: pre-wrap; }\n'
        '.dms-modal button { display: block; margin: 12px 0 0 auto; padding: 4px 14px; }\n'
        '</style>\n</head>\n<body>\n<div id="root"></div>\n'
        '<script src="react.js"></script>\n<script src="host.js"></script>\n'
        '<script src="runtime.js"></script>\n<script src="design.js"></script>\n'
        '<script src="$unit"></script>\n<script src="start.js"></script>\n'
        '</body>\n</html>\n';
  }

  /// La extensión (nombre → contenido), sin react.js: ese sale del entorno
  /// con [reactBundle].
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
    String description = '',
    Map<int, String> breakpoints = const {},
  }) {
    final unit = code.replaceAll('\r\n', '\n');
    if (!const JsUnit().hasClass(unit, d.name)) {
      throw UserError(
        tr('El código debe definir «class {0} extends FormDesign».', [d.name]),
      );
    }
    final file = '${d.name}.js';
    return {
      'manifest.json': manifest(d, name, description),
      'popup.html': _popup(d, file),
      'host.js': tkChromeHostJs,
      'runtime.js': tkElectronRuntimeJs,
      'design.js': TkElectron.design(d),
      file: TkElectron.withBreakpoints(unit, breakpoints),
      'start.js': TkElectron.start(d.name),
    };
  }

  /// La vista previa en el estudio: una ventana de Electron con la
  /// ventana emergente (sin Node y con las API de Chrome imitadas).
  static Map<String, String> preview(TkDesign d, String name) => {
    'package.json': const JsonEncoder.withIndent('  ').convert({
      'name': '${_npmName(name)}-preview',
      'version': '1.0.0',
      'private': true,
      'main': 'main.js',
    }),
    'main.js': tkChromePreviewMainJs,
    'window.json': const JsonEncoder.withIndent('  ').convert({
      ...TkElectron.window(d),
      'width': d.width.clamp(25, 800),
      'height': d.height.clamp(25, 600),
    }),
  };
}

/// DMS_HOST de una extensión de Chrome. Sin las API de Chrome (la vista
/// previa del estudio) las imita: datos en localStorage y una pestaña de
/// ejemplo.
const tkChromeHostJs = r'''"use strict";
// Generated by DMarlon Studio. Do not edit.
(function () {
  const ext = typeof chrome !== "undefined" && !!(chrome.storage && chrome.storage.local);
  // Una página web (Next.js, HTML): la pestaña es la propia página.
  const web = !ext && !!window.DMS_WEB;
  const files = new Map();

  function accept(filters) {
    const out = [];
    for (const f of filters || []) {
      for (const e of f.extensions || []) if (e !== "*") out.push("." + e);
    }
    return out.join(",");
  }

  function pick(options) {
    return new Promise((resolve) => {
      const input = document.createElement("input");
      input.type = "file";
      input.accept = accept(options.filters);
      input.multiple = !!options.multiple;
      input.addEventListener("change", async () => {
        const list = Array.from(input.files || []);
        for (const f of list) files.set(f.name, await f.text());
        if (!list.length) return resolve(null);
        resolve(options.multiple ? list.map((f) => f.name) : list[0].name);
      });
      input.addEventListener("cancel", () => resolve(null));
      input.click();
    });
  }

  function download(name, text) {
    const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = String(name).split(/[\\/]/).pop() || "archivo.txt";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  }

  function modal(text, title) {
    const back = document.createElement("div");
    back.className = "dms-modal";
    const box = document.createElement("div");
    box.textContent = title ? title + "\n\n" + text : text;
    const ok = document.createElement("button");
    ok.textContent = "OK";
    ok.addEventListener("click", () => back.remove());
    box.appendChild(ok);
    back.appendChild(box);
    document.body.appendChild(back);
    ok.focus();
  }

  const local = {
    async get(k, fallback) {
      const v = localStorage.getItem("dms:" + k);
      return v === null ? fallback : JSON.parse(v);
    },
    async set(k, value) { localStorage.setItem("dms:" + k, JSON.stringify(value)); },
    async remove(k) { localStorage.removeItem("dms:" + k); },
  };

  const chromeStorage = {
    async get(k, fallback) {
      const r = await chrome.storage.local.get(k);
      return k in r ? r[k] : fallback;
    },
    set: (k, value) => chrome.storage.local.set({ [k]: value }),
    remove: (k) => chrome.storage.local.remove(k),
  };

  const sample = { id: 0, url: "https://example.com/", title: "Example Domain" };

  async function currentTab() {
    if (web) return { id: 0, url: location.href, title: document.title };
    if (!ext) return Object.assign({}, sample);
    const [t] = await chrome.tabs.query({ active: true, currentWindow: true });
    return t ? { id: t.id, url: t.url || "", title: t.title || "" } : null;
  }

  window.DMS_HOST = {
    kind: ext ? "chrome" : web ? "web" : "preview",
    need: (name) => window.dmsRequire(name),
    imageUrl: (file) => String(file).replace(/\\/g, "/"),
    dialog: (kind, options) => kind === "open"
      ? pick(options)
      : Promise.resolve(options.filename || "archivo.txt"),
    readText: (name) => {
      if (!files.has(name)) throw new Error("Abra el archivo con un diálogo Abrir primero: " + name);
      return files.get(name);
    },
    writeText: (name, text) => download(name, text),
    alert: (text, title) => modal(text, title),
    menu: () => {},
    ready: () => { window.dmsReady = true; },
    onGo: (fn) => {
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
      else fn();
    },
    storage: ext ? chromeStorage : local,
    currentTab,
    openTab: (address) => ext ? chrome.tabs.create({ url: address }) : window.open(address),
    runInPage: async (fn, ...args) => {
      if (web) return fn(...args);
      if (!ext) {
        console.log("Preview: runInPage has no page here; it returns null.");
        return null;
      }
      const tab = await currentTab();
      const [r] = await chrome.scripting.executeScript({ target: { tabId: tab.id }, func: fn, args });
      return r ? r.result : null;
    },
    badge: (text, color) => {
      if (!ext) return console.log("Badge: " + text);
      chrome.action.setBadgeText({ text: String(text) });
      if (color) chrome.action.setBadgeBackgroundColor({ color });
    },
  };
})();
''';

/// La vista previa de la ventana emergente en Electron.
const tkChromePreviewMainJs = r'''"use strict";
// Generated by DMarlon Studio. Do not edit.
process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "true";
const { app, BrowserWindow, Menu, shell } = require("electron");
const fs = require("fs");
const path = require("path");
const WINDOW = require("./window.json");

const debug = process.env.DMSTUDIO_DEVTOOLS === "1";
const testScript = process.env.DMSTUDIO_ELECTRON_TEST || "";

function out(text) {
  process.stdout.write(String(text) + "\n");
}

app.whenReady().then(() => {
  if (process.platform === "darwin") {
    Menu.setApplicationMenu(Menu.buildFromTemplate([{ role: "appMenu" }, { role: "editMenu" }]));
  } else {
    Menu.setApplicationMenu(null);
  }
  const win = new BrowserWindow({
    width: WINDOW.width,
    height: WINDOW.height,
    useContentSize: true,
    title: WINDOW.title,
    backgroundColor: WINDOW.bg,
    resizable: false,
    center: true,
    show: !testScript,
    webPreferences: { nodeIntegration: false, contextIsolation: true },
  });
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
  win.webContents.on("console-message", (...args) => {
    const e = args[0] && args[0].message !== undefined ? args[0] : { level: args[1], message: args[2], lineNumber: args[3], sourceId: args[4] };
    if (/React DevTools|react-devtools/.test(String(e.message))) return;
    const level = typeof e.level === "number" ? ["log", "info", "warning", "error"][e.level] || "log" : e.level;
    const where = e.sourceId ? path.basename(String(e.sourceId)) + ":" + e.lineNumber : "";
    if (level === "error" || level === "warning") out((where ? "[" + where + "] " : "") + e.message);
    else out(e.message);
  });
  const popup = path.join(__dirname, "..", "extension", "popup.html");
  if (debug) {
    // Las herramientas, antes de cargar: así se detiene también al abrir.
    win.webContents.once("devtools-opened", () => setTimeout(() => win.loadFile(popup), 400));
    win.webContents.openDevTools({ mode: "detach" });
  } else {
    win.loadFile(popup);
  }
  win.webContents.on("did-finish-load", async () => {
    if (!testScript) return;
    await new Promise((r) => setTimeout(r, 300));
    try {
      const result = await win.webContents.executeJavaScript(fs.readFileSync(testScript, "utf8"));
      out("DMSTUDIO_TEST " + JSON.stringify(result));
      app.exit(0);
    } catch (error) {
      out("DMSTUDIO_TEST_ERROR " + (error && error.stack ? error.stack : error));
      app.exit(1);
    }
  });
});
app.on("window-all-closed", () => app.quit());
''';
