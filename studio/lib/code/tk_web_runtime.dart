/// Código de Python fijo de las aplicaciones web: va dentro del archivo
/// generado. Ningún texto del diseño entra aquí: los diseños llegan como datos
/// a las plantillas, que Jinja escapa, y por eso `{{ }}` en una etiqueta es
/// solo texto. No lleva ni fichas, ni contraseñas, ni direcciones: el secreto
/// de cada ejecución y lo que necesitan los datos llegan por el entorno.
class TkWebRuntime {
  TkWebRuntime._();

  static const imports = r'''
import concurrent.futures
import hmac
import importlib
import logging
import os
import re
import secrets
import sys
import threading
import traceback
import types
''';

  static const flaskImports = r'''
from collections import OrderedDict

from flask import Flask, abort, g, jsonify, request
from werkzeug.serving import make_server
''';

  /// Plantilla de cada componente y de la página, y el código del navegador:
  /// solo envía los eventos y aplica lo que responde el servidor.
  static const templates = r'''


WIDGETS = r"""
{%- macro menu_items(items) -%}
{%- for item in items -%}
{%- if item.sep %}<li class="tk-sep" role="separator"></li>
{%- elif item["items"] %}<li><span tabindex="0">{{ item.label }}</span><ul>{{ menu_items(item["items"]) }}</ul></li>
{%- else %}<li><button type="button" data-item="{{ item.path }}">{{ item.label }}</button></li>
{%- endif -%}
{%- endfor -%}
{%- endmacro -%}
{%- macro widget(w) -%}
{%- if w.kind == "Label" -%}
<label id="{{ w.name }}" class="tk tk-label" style="{{ w.style() }}" data-on="{{ w.on() }}"><span>{{ w.cget("text") }}</span></label>
{%- elif w.kind == "Button" -%}
<button id="{{ w.name }}" type="button" class="tk" style="{{ w.style() }}" data-on="{{ w.on() }}"{% if w.disabled() %} disabled{% endif %}>{{ w.cget("text") }}</button>
{%- elif w.kind == "Entry" -%}
<input id="{{ w.name }}" type="{{ "password" if w.cget("show") else "text" }}" class="tk" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="text" value="{{ w.var.get() }}"{% if w.cget("state") == "readonly" %} readonly{% endif %}{% if w.disabled() %} disabled{% endif %}>
{%- elif w.kind == "Text" -%}
<textarea id="{{ w.name }}" class="tk" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="text" wrap="{{ "off" if w.cget("wrap") == "none" else "soft" }}"{% if w.disabled() %} disabled{% endif %}>
{{ w.content }}</textarea>
{%- elif w.kind == "Checkbutton" -%}
<label id="{{ w.name }}" class="tk tk-choice" style="{{ w.style() }}" data-on="{{ w.on() }}"><input type="checkbox" data-value="check"{% if w.checked() %} checked{% endif %}{% if w.disabled() %} disabled{% endif %}><span>{{ w.cget("text") }}</span></label>
{%- elif w.kind == "Radiobutton" -%}
<label id="{{ w.name }}" class="tk tk-choice" style="{{ w.style() }}" data-on="{{ w.on() }}"><input type="radio" name="{{ w.cget("group") }}" data-value="radio"{% if w.checked() %} checked{% endif %}{% if w.disabled() %} disabled{% endif %}><span>{{ w.cget("text") }}</span></label>
{%- elif w.kind == "Listbox" -%}
<select id="{{ w.name }}" class="tk" size="{{ w.rows_shown() }}" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="list"{% if w.cget("selectmode") in ("multiple", "extended") %} multiple{% endif %}>
{%- for item in w.items %}<option value="{{ loop.index0 }}"{% if loop.index0 in w.selected %} selected{% endif %}>{{ item }}</option>{% endfor -%}
</select>
{%- elif w.kind == "Combobox" -%}
<select id="{{ w.name }}" class="tk" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="text"{% if w.disabled() %} disabled{% endif %}>
{%- for item in w.choices() %}<option value="{{ item }}"{% if item == w.var.get() %} selected{% endif %}>{{ item }}</option>{% endfor -%}
</select>
{%- elif w.kind == "Scale" -%}
<label id="{{ w.name }}" class="tk tk-scale{% if w.cget("orient") == "vertical" %} tk-vertical{% endif %}" style="{{ w.style() }}" data-on="{{ w.on() }}">
{%- if w.cget("label") %}<span>{{ w.cget("label") }}</span>{% endif -%}
<input type="range" min="{{ w.cget("from") }}" max="{{ w.cget("to") }}" step="{{ w.cget("resolution") }}" value="{{ w.var.get() }}" data-value="number">
{%- if w.cget("showvalue") %}<output>{{ w.shown() }}</output>{% endif -%}
</label>
{%- elif w.kind == "Frame" -%}
<fieldset id="{{ w.name }}" class="tk tk-frame" style="{{ w.style() }}" data-on="{{ w.on() }}">
{%- for child in w.children() %}{{ widget(child) }}{% endfor -%}
</fieldset>
{%- elif w.kind == "Menu" -%}
<nav id="{{ w.name }}" class="tk-menu" style="width:{{ w.width }}px" data-on="{{ w.on() }}"><ul>{{ menu_items(w.cget("tree") or []) }}</ul></nav>
{%- elif w.kind == "StatusBar" -%}
<div id="{{ w.name }}" class="tk tk-status" style="{{ w.style() }}" data-on="{{ w.on() }}"><span>{{ w.cget("text") }}</span></div>
{%- elif w.kind == "Progressbar" -%}
<progress id="{{ w.name }}" class="tk tk-progress" style="{{ w.style() }}" data-on="{{ w.on() }}" max="{{ w.maximum() }}"{% if w.cget("mode") != "indeterminate" %} value="{{ w.current() }}"{% endif %}></progress>
{%- elif w.kind == "PageControl" -%}
<div id="{{ w.name }}" class="tk tk-pages" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="page" data-active="{{ w.active() }}"><div class="tk-tabs" role="tablist">
{%- for title in w.pages() %}<button type="button" role="tab" class="tk-tab{% if loop.index0 == w.active() %} tk-on{% endif %}" data-page="{{ loop.index0 }}">{{ title }}</button>{% endfor -%}
</div>
{%- for title in w.pages() %}<div class="tk-page" data-page="{{ loop.index0 }}"{% if loop.index0 != w.active() %} hidden{% endif %}>
{%- for child in w.children_of(loop.index0) %}{{ widget(child) }}{% endfor -%}
</div>{% endfor -%}
</div>
{%- elif w.kind == "Canvas" -%}
<canvas id="{{ w.name }}" class="tk" width="{{ w.width }}" height="{{ w.height }}" style="{{ w.style() }}" data-on="{{ w.on() }}"></canvas>
{%- elif w.kind == "Treeview" -%}
<div id="{{ w.name }}" class="tk tk-grid" style="{{ w.style() }}" data-on="{{ w.on() }}" data-value="grid" data-selected="{{ w.chosen[0] if w.chosen else "" }}"><table><thead><tr>
{%- for column in w.columns %}<th scope="col"{% if w.widths.get(column) %} style="width:{{ w.widths[column] }}px"{% endif %}>{{ w.titles.get(column, column) }}</th>{% endfor -%}
</tr></thead><tbody>
{%- for iid, values in w.rows.items() %}<tr data-iid="{{ iid }}"{% if iid in w.chosen %} class="tk-chosen"{% endif %}>
{%- for value in values %}<td>{{ value }}</td>{% endfor -%}
</tr>{% endfor -%}
</tbody></table></div>
{%- endif -%}
{%- endmacro -%}
"""

PAGE = r"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="DMarlon Studio">
<link rel="icon" href="data:,">
<title>{{ form.root.text }}</title>
<style>
html, body { margin: 0; padding: 0; }
body { font: 13px system-ui, -apple-system, "Segoe UI", sans-serif; color: #000; }
.tk-form { position: relative; margin: 0 auto; overflow: hidden; transform-origin: top left; }
.tk { position: absolute; box-sizing: border-box; margin: 0; font: inherit; }
input.tk, textarea.tk, select.tk { background: #fff; color: #000; border: 1px solid #8a8f98; padding: 2px 4px; }
textarea.tk { resize: none; }
button.tk { cursor: pointer; padding: 0 6px; }
.tk-label { display: flex; align-items: center; justify-content: center; white-space: pre; overflow: hidden; }
.tk-choice { display: flex; align-items: center; gap: 6px; white-space: nowrap; }
.tk-choice input { margin: 0; }
.tk-scale { display: flex; align-items: center; gap: 8px; }
.tk-scale input { flex: 1; min-width: 0; margin: 0; }
.tk-vertical { flex-direction: column; }
.tk-vertical input { writing-mode: vertical-lr; direction: rtl; }
.tk-frame { padding: 0; min-width: 0; border: 0; }
.tk-grid { background: #fff; color: #000; border: 1px solid #8a8f98; overflow: auto; }
.tk-grid table { border-collapse: collapse; width: 100%; }
.tk-grid th { position: sticky; top: 0; background: #e8eaee; text-align: left; font-weight: 600; }
.tk-grid th, .tk-grid td { padding: 3px 6px; border-bottom: 1px solid #dfe1e6; white-space: nowrap; }
.tk-grid tbody tr { cursor: pointer; }
.tk-grid tr.tk-chosen td { background: #2b5797; color: #fff; }
.tk-status { display: flex; align-items: center; padding: 0 6px; border-top: 1px solid #a8acb3; white-space: nowrap; overflow: hidden; }
.tk-progress { padding: 0; }
.tk-pages { border: 1px solid #8a8f98; background: inherit; }
.tk-tabs { position: absolute; left: 0; top: 0; height: 24px; display: flex; gap: 2px; }
.tk-tab { font: inherit; padding: 0 10px; border: 1px solid #8a8f98; border-bottom: 0; background: #e4e5e7; color: #000; cursor: pointer; }
.tk-tab.tk-on { background: #fff; font-weight: 600; }
.tk-page { position: absolute; left: 0; right: 0; top: 24px; bottom: 0; border-top: 1px solid #8a8f98; }
.tk-page[hidden] { display: none; }
.tk-menu { margin: 0 auto; background: #f3f3f3; border-bottom: 1px solid #c8cbd0; position: relative; z-index: 20; }
.tk-menu ul { list-style: none; margin: 0; padding: 0; }
.tk-menu > ul { display: flex; }
.tk-menu li { position: relative; }
.tk-menu button, .tk-menu span { display: block; width: 100%; padding: 4px 12px; background: none; border: 0; font: inherit; color: inherit; text-align: left; white-space: nowrap; cursor: pointer; }
.tk-menu li ul { display: none; position: absolute; left: 0; top: 100%; min-width: 160px; background: #fff; border: 1px solid #c8cbd0; box-shadow: 0 2px 6px rgba(0, 0, 0, .2); }
.tk-menu li li ul { left: 100%; top: -1px; }
.tk-menu li:hover > ul, .tk-menu li:focus-within > ul { display: block; }
.tk-menu li:hover > span, .tk-menu button:hover, .tk-menu button:focus { background: #dce6f7; outline: none; }
.tk-menu .tk-sep { border-top: 1px solid #d6d8dc; margin: 3px 0; }
#tk-toast { position: fixed; left: 50%; bottom: 16px; transform: translateX(-50%); max-width: 80%; padding: 8px 14px; border-radius: 6px; background: #323232; color: #fff; }
#tk-toast[hidden] { display: none; }
</style>
</head>
<body style="background:{{ form.root.bg }}">
{%- for w in form._menus() %}{{ widget(w) }}{% endfor -%}
<main id="tk-form" class="tk-form" style="width:{{ form.root.width }}px;height:{{ form.root.height }}px;background:{{ form.root.bg }}" data-on="{{ form._keys("") }}">
{%- for w in form._top() %}{{ widget(w) }}{% endfor -%}
</main>
<div id="tk-toast" role="alert" hidden></div>
<script type="application/json" id="tk-boot">{{ boot|tojson }}</script>
<script nonce="{{ nonce }}">
(function () {
  "use strict";
  var boot = JSON.parse(document.getElementById("tk-boot").textContent);
  var texts = {
    en: {
      closed: "This application has been closed.",
      failed: "The server refused the request",
      stopped: "The application is no longer running.",
      error: "The application failed: see the server log.",
      process: "This application keeps its state in one process: start it with a single worker (gunicorn -w 1 --threads 4)."
    },
    es: {
      closed: "Esta aplicación se ha cerrado.",
      failed: "El servidor rechazó la petición",
      stopped: "La aplicación ya no está en marcha.",
      error: "La aplicación ha fallado: mire la salida del servidor.",
      process: "Esta aplicación guarda su estado en un solo proceso: arránquela con un único worker (gunicorn -w 1 --threads 4)."
    }
  };
  var text = texts[(navigator.language || "").slice(0, 2).toLowerCase()] || texts.en;
  var form = document.getElementById("tk-form");
  var toast = document.getElementById("tk-toast");
  var queue = Promise.resolve();
  var hide = null;

  function fit() {
    var scale = Math.min(1, document.documentElement.clientWidth / boot.width);
    form.style.transform = scale < 1 ? "scale(" + scale + ")" : "";
    document.body.style.height = scale < 1 ? boot.height * scale + "px" : "";
  }

  function say(text) {
    toast.textContent = text;
    toast.hidden = false;
    clearTimeout(hide);
    hide = setTimeout(function () { toast.hidden = true; }, 6000);
  }

  function owner(el) { return el.id ? el : el.closest("[id]"); }

  function values() {
    var out = {};
    form.querySelectorAll("[data-value]").forEach(function (el) {
      var name = owner(el).id;
      switch (el.dataset.value) {
        case "check": out[name] = el.checked ? 1 : 0; break;
        case "radio": out[name] = el.checked; break;
        case "grid": out[name] = el.dataset.selected; break;
        case "page": out[name] = Number(el.dataset.active); break;
        case "list":
          out[name] = Array.prototype.map.call(el.selectedOptions, function (o) {
            return Number(o.value);
          });
          break;
        default: out[name] = el.value;
      }
    });
    return out;
  }

  function apply(reply) {
    Object.keys(reply.html || {}).forEach(function (name) {
      var el = document.getElementById(name);
      if (!el) { return; }
      var active = document.activeElement;
      var kept = el.contains(active) && active !== document.body;
      var from = kept && "selectionStart" in active ? active.selectionStart : null;
      el.outerHTML = reply.html[name];
      if (kept) {
        var again = document.getElementById(name);
        var target = again.matches("[data-value]") ? again : again.querySelector("[data-value]") || again;
        target.focus();
        if (from !== null) {
          try { target.setSelectionRange(from, from); } catch (ignored) { /* no admite cursor */ }
        }
      }
    });
    if (reply.title) { document.title = reply.title; }
    if (reply.bg) {
      form.style.background = reply.bg;
      document.body.style.background = reply.bg;
    }
    (reply.timers || []).forEach(function (t) {
      setTimeout(function () { post({ timer: t.id }); }, t.ms);
    });
    (reply.notes || []).forEach(function (note) {
      say(typeof note === "string" ? note : text[note.key] || "");
    });
    if (reply.focus) {
      var box = document.getElementById(reply.focus);
      if (box) { (box.matches("[data-value]") ? box : box.querySelector("[data-value]") || box).focus(); }
    }
    if (reply.closed) { form.hidden = true; say(text.closed); }
  }

  function post(body) {
    body.sid = boot.sid;
    queue = queue.then(function () {
      body.values = values();
      return fetch("event", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-DMS-CSRF": boot.csrf,
          "X-DMS-Process": boot.process
        },
        body: JSON.stringify(body)
      });
    }).then(function (response) {
      if (response.status === 409) {
        return response.json().then(function (reply) {
          if (reply.error === "process") { say(text.process); } else { location.reload(); }
          return null;
        });
      }
      if (!response.ok) { say(text.failed + " (" + response.status + ")"); return null; }
      return response.json();
    }).then(function (reply) {
      if (reply) { apply(reply); }
    }).catch(function () { say(text.stopped); });
  }

  function has(el, key) {
    return !!el && (el.dataset.on || "").split(" ").indexOf(key) >= 0;
  }

  function name(el) { return el === form ? "" : el.id; }

  function detail(event) {
    return { x: event.offsetX || 0, y: event.offsetY || 0, key: event.key || "" };
  }

  function target(event) {
    var el = event.target;
    return el && el.closest ? el.closest("[data-on]") : null;
  }

  function fire(el, key, event) {
    if (has(el, key)) { post({ widget: name(el), event: key, data: detail(event) }); return true; }
    return false;
  }

  var plain = {
    mousedown: "click", dblclick: "double", contextmenu: "right", mouseup: "release",
    focusin: "focus_in", focusout: "focus_out", keydown: "key", keyup: "key_up"
  };
  Object.keys(plain).forEach(function (type) {
    document.addEventListener(type, function (event) {
      var el = target(event);
      var key = plain[type];
      if (type === "keydown" && event.key === "Enter" && el) { fire(el, "enter_key", event); }
      if (el && fire(el, key, event)) {
        if (type === "contextmenu") { event.preventDefault(); }
      } else if (key === "key" || key === "key_up") {
        fire(form, key, event);
      }
    });
  });

  document.addEventListener("mouseover", function (event) {
    var el = target(event);
    if (el && !el.contains(event.relatedTarget)) { fire(el, "enter", event); }
  });
  document.addEventListener("mouseout", function (event) {
    var el = target(event);
    if (el && !el.contains(event.relatedTarget)) { fire(el, "leave", event); }
  });

  document.addEventListener("click", function (event) {
    var choice = event.target.closest ? event.target.closest(".tk-menu [data-item]") : null;
    if (choice) {
      var menu = choice.closest(".tk-menu");
      if (document.activeElement) { document.activeElement.blur(); }
      if (has(menu, "command")) {
        post({ widget: menu.id, event: "command", data: { item: choice.dataset.item } });
      }
      return;
    }
    var tab = event.target.closest ? event.target.closest(".tk-tab") : null;
    if (tab) {
      var pages = tab.closest(".tk-pages");
      var page = tab.dataset.page;
      if (pages.dataset.active === page) { return; }
      pages.dataset.active = page;
      pages.querySelectorAll(":scope > .tk-tabs > .tk-tab").forEach(function (t) {
        t.classList.toggle("tk-on", t.dataset.page === page);
      });
      pages.querySelectorAll(":scope > .tk-page").forEach(function (p) {
        p.hidden = p.dataset.page !== page;
      });
      fire(pages, "change", event);
      return;
    }
    var el = target(event);
    if (!el) { return; }
    if (el.tagName === "BUTTON") { fire(el, "command", event); return; }
    var row = event.target.closest("tr[data-iid]");
    if (row && el.classList.contains("tk-grid")) {
      el.querySelectorAll("tr.tk-chosen").forEach(function (r) { r.classList.remove("tk-chosen"); });
      row.classList.add("tk-chosen");
      el.dataset.selected = row.dataset.iid;
      fire(el, "select", event);
    }
  });

  document.addEventListener("input", function (event) {
    var el = target(event);
    var shown = el && event.target.type === "range" ? el.querySelector("output") : null;
    if (shown) { shown.textContent = event.target.value; }
  });

  document.addEventListener("change", function (event) {
    var el = target(event);
    if (!el) { return; }
    if (el.tagName === "SELECT") { fire(el, "select", event); } else { fire(el, "command", event); }
  });

  window.addEventListener("resize", fit);
  fit();
  apply(boot);
})();
</script>
</body>
</html>
"""
''';

  /// Clases de lo que usa el código del usuario: lo mismo que en tkinter.
  static const classes = r'''


MAX_FORMS = 32
LOCAL_HOSTS = {"127.0.0.1", "localhost", "[::1]"}
KEY_CHARS = {
    "Enter": "\r",
    "Escape": "\x1b",
    "Backspace": "\x08",
    "Delete": "\x7f",
    "Tab": "\t",
}


def css_color(value):
    """A color, or nothing: it goes into a style of the page."""
    text = str(value or "").strip()
    pattern = r"#[0-9a-fA-F]{3}|#[0-9a-fA-F]{6}|[A-Za-z][A-Za-z0-9 ]*"
    return text if re.fullmatch(pattern, text) else ""


def css_font(value):
    """A font name, or nothing: it goes into a style of the page."""
    text = str(value or "").strip()
    return text if re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 _-]*", text) else ""


class WebVar:
    """Value of a component, read and set like a tkinter variable."""

    def __init__(self, form, cast, value):
        self.form = form
        self.cast = cast
        self.value = self.convert(value)
        self.owners = []

    def convert(self, value):
        try:
            return self.cast(value)
        except (TypeError, ValueError):
            return self.cast()

    def get(self):
        return self.value

    def set(self, value):
        self.value = self.convert(value)
        for name in self.owners:
            self.form._touch(name)


class WebEvent:
    """What a handler receives, like the event of tkinter."""

    def __init__(self, widget, data):
        self.widget = widget
        self.x = int(data.get("x") or 0)
        self.y = int(data.get("y") or 0)
        self.keysym = str(data.get("key") or "")
        self.char = KEY_CHARS.get(
            self.keysym, self.keysym if len(self.keysym) == 1 else ""
        )


class WebRoot:
    """The page: what self.root is in a window."""

    def __init__(self, form, title, width, height, bg):
        self.form = form
        self.text = title
        self.width = width
        self.height = height
        self.bg = css_color(bg)

    def title(self, text=None):
        if text is None:
            return self.text
        self.text = self.form._changes["title"] = str(text)
        return self.text

    def configure(self, **options):
        if "bg" in options:
            self.bg = self.form._changes["bg"] = css_color(options["bg"])

    config = configure

    def after(self, ms, callback=None, *args):
        self.form._timer_id += 1
        timer = self.form._timer_id
        self.form._timers[timer] = (callback, args)
        self.form._pending.append({"id": timer, "ms": max(0, int(ms))})
        return timer

    def after_idle(self, callback, *args):
        return self.after(0, callback, *args)

    def after_cancel(self, timer):
        self.form._timers.pop(timer, None)

    def destroy(self):
        self.form._changes["closed"] = True

    def focus_force(self):
        pass

    def update(self):
        pass

    def update_idletasks(self):
        pass


class WebWidget:
    """A component: the calls of tkinter, but its state lives in the server
    and the browser receives it rendered again each time it changes.
    """

    def __init__(self, form, kind, name, parent, box, options, var=None):
        self.form = form
        self.kind = kind
        self.name = name
        self.parent = parent
        self.x, self.y, self.width, self.height = box
        self.options = dict(options)
        self.var = var
        if var is not None:
            var.owners.append(name)

    def configure(self, **options):
        for key, value in options.items():
            self.options[key.rstrip("_")] = value
        self.form._touch(self.name)

    config = configure

    def cget(self, key):
        return self.options.get(key.rstrip("_"), "")

    __getitem__ = cget

    def __setitem__(self, key, value):
        self.configure(**{key: value})

    def focus_set(self):
        self.form._changes["focus"] = self.name

    focus = focus_set

    def read(self):
        """Value of the component, for WebForm.value."""
        return self.var.get() if self.var else self.cget("text")

    def write(self, value):
        if self.var:
            self.var.set(value)
        else:
            self.configure(text=value)

    def sync(self, value):
        """What the browser holds now: nothing to send back."""

    def on(self):
        return self.form._keys(self.name)

    def disabled(self):
        return self.cget("state") == "disabled"

    def children(self):
        return [w for w in self.form._visible() if w.parent == self.name]

    def style(self):
        parts = [
            "left:%dpx" % self.x,
            "top:%dpx" % self.y,
            "width:%dpx" % self.width,
            "height:%dpx" % self.height,
        ]
        options = self.options
        bg, fg = css_color(options.get("bg")), css_color(options.get("fg"))
        if bg:
            parts.append("background:" + bg)
        if fg:
            parts.append("color:" + fg)
        family = css_font(options.get("font_family"))
        if family:
            parts.append("font-family:'%s'" % family)
        size = options.get("font_size")
        if isinstance(size, int) and size > 0:
            parts.append("font-size:%dpx" % size)
        if options.get("font_bold"):
            parts.append("font-weight:bold")
        if options.get("font_italic"):
            parts.append("font-style:italic")
        anchor = options.get("anchor")
        if anchor in ("w", "e"):
            flex = "flex-start" if anchor == "w" else "flex-end"
            parts.append("justify-content:" + flex)
        elif anchor in ("n", "s"):
            flex = "flex-start" if anchor == "n" else "flex-end"
            parts.append("align-items:" + flex)
        justify = options.get("justify")
        if justify in ("left", "center", "right"):
            parts.append("text-align:" + justify)
        wrap = options.get("wraplength")
        if isinstance(wrap, int) and wrap > 0:
            parts.append("white-space:pre-wrap")
        reliefs = {
            "flat": "none",
            "raised": "outset",
            "sunken": "inset",
            "groove": "groove",
            "ridge": "ridge",
            "solid": "solid",
        }
        relief = reliefs.get(options.get("relief"))
        width = options.get("bd")
        width = width if isinstance(width, int) and width > 0 else 1
        if relief == "none":
            parts.append("border:none")
        elif relief:
            parts.append("border:%dpx %s #8a8f98" % (width, relief))
        elif width > 1:
            parts.append("border:%dpx solid #8a8f98" % width)
        return ";".join(parts)


class WebChoice(WebWidget):
    """Checkbutton and Radiobutton."""

    def checked(self):
        if self.kind == "Checkbutton":
            return bool(self.var.get())
        return str(self.var.get()) == str(self.cget("value"))

    def sync(self, value):
        if self.kind == "Checkbutton":
            self.var.value = 1 if value else 0
        elif value:
            self.var.value = self.var.convert(self.cget("value"))

    def select(self):
        self.var.set(1 if self.kind == "Checkbutton" else self.cget("value"))

    def deselect(self):
        self.var.set(0 if self.kind == "Checkbutton" else "")


class WebEntry(WebWidget):
    """Entry and Combobox: the value is their variable."""

    def get(self):
        return self.var.get()

    def set(self, value):
        self.var.set(value)

    def sync(self, value):
        self.var.value = self.var.convert(value)

    def _index(self, index, text):
        return len(text) if index == "end" else max(0, int(index))

    def insert(self, index, value):
        text = self.var.get()
        at = self._index(index, text)
        self.var.set(text[:at] + str(value) + text[at:])

    def delete(self, first, last=None):
        text = self.var.get()
        start = self._index(first, text)
        end = start + 1 if last is None else self._index(last, text)
        self.var.set(text[:start] + text[end:])

    def choices(self):
        items = [str(item) for item in self.options.get("values") or ()]
        value = str(self.var.get())
        return items if not value or value in items else [value] + items

    def current(self, index=None):
        items = list(self.options.get("values") or ())
        if index is not None:
            self.var.set(items[index])
        value = self.var.get()
        return items.index(value) if value in items else -1


class WebText(WebWidget):
    """Text: the whole content, from "1.0" to "end"."""

    def __init__(self, form, kind, name, parent, box, options, var=None):
        WebWidget.__init__(self, form, kind, name, parent, box, options, var)
        self.content = str(self.options.pop("text", ""))

    def get(self, first="1.0", last="end"):
        return self.content + ("" if last == "end-1c" else "\n")

    def insert(self, index, text):
        text = str(text)
        at_start = str(index) == "1.0"
        self.content = text + self.content if at_start else self.content + text
        self.form._touch(self.name)

    def delete(self, first="1.0", last="end"):
        self.content = ""
        self.form._touch(self.name)

    def see(self, index):
        pass

    def read(self):
        return self.content

    def write(self, value):
        self.content = str(value)
        self.form._touch(self.name)

    def sync(self, value):
        self.content = str(value)


class WebListbox(WebWidget):
    """Listbox: its items and the positions chosen."""

    def __init__(self, form, kind, name, parent, box, options, var=None):
        WebWidget.__init__(self, form, kind, name, parent, box, options, var)
        self.items = [str(item) for item in self.options.pop("items", ())]
        self.selected = []

    def _index(self, index):
        return len(self.items) if index == "end" else int(index)

    def rows_shown(self):
        return max(2, self.height // 20)

    def insert(self, index, *items):
        at = self._index(index)
        self.items[at:at] = [str(item) for item in items]
        self.form._touch(self.name)

    def delete(self, first, last=None):
        start = self._index(first)
        end = start + 1 if last is None else self._index(last) + 1
        del self.items[start:end]
        self.selected = []
        self.form._touch(self.name)

    def get(self, first, last=None):
        if last is None:
            return self.items[self._index(first)]
        return tuple(self.items[self._index(first) : self._index(last) + 1])

    def size(self):
        return len(self.items)

    def curselection(self):
        return tuple(self.selected)

    def selection_set(self, first, last=None):
        end = self._index(first) if last is None else self._index(last)
        for index in range(self._index(first), min(end + 1, len(self.items))):
            if index not in self.selected:
                self.selected.append(index)
        self.selected.sort()
        self.form._touch(self.name)

    select_set = selection_set

    def selection_clear(self, first=0, last="end"):
        self.selected = []
        self.form._touch(self.name)

    select_clear = selection_clear

    def activate(self, index):
        pass

    def see(self, index):
        pass

    def read(self):
        return [self.items[index] for index in self.selected]

    def sync(self, value):
        chosen = value if isinstance(value, list) else []
        self.selected = sorted(
            i for i in chosen if isinstance(i, int) and 0 <= i < len(self.items)
        )


class WebScale(WebWidget):
    """Scale: the value is its variable."""

    def get(self):
        return self.var.get()

    def set(self, value):
        self.var.set(value)

    def shown(self):
        return "%g" % self.var.get()

    def sync(self, value):
        self.var.value = self.var.convert(value)


class WebGrid(WebWidget):
    """Data grid: rendered as a table by the server."""

    def __init__(self, form, kind, name, parent, box, options, var=None):
        WebWidget.__init__(self, form, kind, name, parent, box, options, var)
        self.columns = [str(c) for c in self.options.pop("columns", ())]
        self.titles = {}
        self.widths = {}
        self.rows = {}
        self.chosen = []
        self.next_row = 0

    def configure(self, **options):
        if "columns" in options:
            self.columns = [str(c) for c in options.pop("columns")]
        WebWidget.configure(self, **options)

    config = configure

    def heading(self, column, text=None, **options):
        if text is not None:
            self.titles[column] = str(text)
            self.form._touch(self.name)

    def column(self, column, width=None, **options):
        if width is not None:
            self.widths[column] = int(width)
            self.form._touch(self.name)

    def get_children(self, item=""):
        return tuple(self.rows)

    def insert(self, parent, index, iid=None, values=(), **options):
        if iid is None:
            self.next_row += 1
            iid = "I%03d" % self.next_row
        self.rows[str(iid)] = [str(value) for value in values]
        self.form._touch(self.name)
        return str(iid)

    def delete(self, *items):
        for item in items:
            self.rows.pop(str(item), None)
        self.chosen = [item for item in self.chosen if item in self.rows]
        self.form._touch(self.name)

    def selection(self):
        return tuple(self.chosen)

    def selection_set(self, *items):
        self.chosen = [str(item) for item in items if str(item) in self.rows]
        self.form._touch(self.name)

    def item(self, iid, option=None):
        values = list(self.rows.get(str(iid), ()))
        return values if option == "values" else {"values": values}

    def see(self, iid):
        pass

    def read(self):
        return self.item(self.chosen[0], "values") if self.chosen else None

    def sync(self, value):
        self.chosen = [str(value)] if str(value) in self.rows else []


class WebMenu(WebWidget):
    """The menu of the window: a bar at the top of the page."""

    def paths(self):
        found = []

        def walk(items):
            for item in items:
                if item.get("sep"):
                    continue
                if item.get("items"):
                    walk(item["items"])
                else:
                    found.append(item.get("path"))

        walk(self.cget("tree") or [])
        return found


class WebProgress(WebWidget):
    """ttk.Progressbar: value, maximum, step, start and stop."""

    def maximum(self):
        top = self.options.get("maximum", 100)
        return top if isinstance(top, (int, float)) and top > 0 else 100

    def current(self):
        value = self.options.get("value", 0)
        return value if isinstance(value, (int, float)) else 0

    def step(self, amount=1.0):
        value = self.current() + amount
        if value >= self.maximum():
            value -= self.maximum()
        self.configure(value=value)

    def start(self, interval=None):
        """In a page the indeterminate bar moves by itself."""

    def stop(self):
        pass


class WebPages(WebWidget):
    """ttk.Notebook: one page of components per tab."""

    def pages(self):
        return list(self.options.get("pages") or [])

    def active(self):
        index = self.options.get("active", 0)
        count = len(self.pages())
        return index if isinstance(index, int) and 0 <= index < count else 0

    def children_of(self, page):
        return [
            w
            for w in self.form._visible()
            if w.parent == self.name and int(w.options.get("page", 0)) == page
        ]

    def select(self, tab_id=None):
        """With an index, show that page; without one, the current index."""
        if tab_id is None:
            return self.active()
        self.options["active"] = int(tab_id)
        self.form._touch(self.name)
        return self.active()

    def index(self, tab_id):
        if tab_id in ("current", None):
            return self.active()
        if tab_id == "end":
            return len(self.pages())
        return int(tab_id)

    def tabs(self):
        return list(range(len(self.pages())))

    def sync(self, value):
        try:
            index = int(value)
        except (TypeError, ValueError):
            return
        if 0 <= index < len(self.pages()):
            self.options["active"] = index


WEB_CLASSES = {
    "Menu": WebMenu,
    "Progressbar": WebProgress,
    "PageControl": WebPages,
    "Checkbutton": WebChoice,
    "Radiobutton": WebChoice,
    "Entry": WebEntry,
    "Combobox": WebEntry,
    "Text": WebText,
    "Listbox": WebListbox,
    "Scale": WebScale,
    "Treeview": WebGrid,
}


_ACTIVE = []


def _shown(title, message=None, **options):
    text = title if message is None else message
    if _ACTIVE:
        _ACTIVE[-1].notify(text)
    else:
        print(text, flush=True)
    return "ok"


def _asked(answer):
    def ask(title, message=None, **options):
        _shown(title, message)
        print(
            "messagebox has no dialog in a web app: the question was answered no. "
            "Use a button to ask.",
            flush=True,
        )
        return answer

    return ask


def _install_messagebox():
    """A page has no dialogs, and in a server tkinter's messagebox aborts the
    whole process on macOS: it shows the message on the page instead, and a
    question is answered no.
    """
    box = types.ModuleType("tkinter.messagebox")
    box.showinfo = box.showwarning = box.showerror = _shown
    box.askyesno = box.askokcancel = box.askretrycancel = _asked(False)
    box.askyesnocancel = _asked(None)
    box.askquestion = _asked("no")
    sys.modules["tkinter.messagebox"] = box
    # Only so that tkinter.messagebox reaches the page too; without Tk an
    # empty package is enough.
    try:
        tkinter = importlib.import_module("tkinter")
    except ImportError:
        tkinter = types.ModuleType("tkinter")
        tkinter.__path__ = []
        sys.modules["tkinter"] = tkinter
    tkinter.messagebox = box


_install_messagebox()


class WebForm:
    """The form of one open page: handlers work on it as they do on a window."""

    def __init__(self, title, width, height, bg):
        self.root = WebRoot(self, title, width, height, bg)
        self._widgets = {}
        self._handlers = {}
        self._dirty = set()
        self._changes = {}
        self._notes = []
        self._timers = {}
        self._pending = []
        self._timer_id = 0
        self._render = None

    # What the handlers use besides the calls of tkinter.
    def value(self, name, *new):
        """Read a component by name or, with a second argument, set it."""
        widget = self._widgets[name]
        if new:
            widget.write(new[0])
        return widget.read()

    def notify(self, text):
        """Show a message on the page."""
        self._notes.append(str(text))

    # Design.
    def _add(self, kind, name, parent, box, options, var=None):
        widget = WEB_CLASSES.get(kind, WebWidget)(
            self, kind, name, parent, box, options, var
        )
        self._widgets[name] = widget
        return widget

    def _on(self, name, key, handler):
        self._handlers.setdefault((name, key), []).append(handler)

    def _keys(self, name):
        return " ".join(sorted(key for owner, key in self._handlers if owner == name))

    def _visible(self):
        return list(self._widgets.values())

    def _start(self):
        """The create event of the design, once the form exists."""

    def _top(self):
        return [
            w
            for w in self._widgets.values()
            if w.parent is None and w.kind != "Menu"
        ]

    def _menus(self):
        return [w for w in self._widgets.values() if w.kind == "Menu"]

    def _touch(self, name):
        self._dirty.add(name)

    # Requests.
    def _call(self, handler, *args):
        """Run user code: an error is for the log, not for the browser."""
        _ACTIVE.append(self)
        try:
            handler(*args)
        except DataError as error:
            self.notify(error)
        except Exception:
            traceback.print_exc()
            self._notes.append({"key": "error"})
        finally:
            _ACTIVE.pop()

    def _sync(self, values):
        if isinstance(values, dict):
            for name, value in values.items():
                widget = self._widgets.get(name)
                if widget is not None:
                    widget.sync(value)

    def _event(self, data):
        """An event of the browser. It only reaches the handlers of the design:
        the name of a method never comes from the request.
        """
        self._sync(data.get("values"))
        timer = data.get("timer")
        if timer is not None:
            callback, args = self._timers.pop(timer, (None, ()))
            if callback is not None:
                self._call(callback, *args)
            return self._reply()
        name = str(data.get("widget") or "")
        key = str(data.get("event") or "")
        info = data.get("data") if isinstance(data.get("data"), dict) else {}
        widget = self._widgets.get(name)
        if widget is not None and widget.kind == "Menu":
            item = str(info.get("item") or "")
            if key == "command" and item in widget.paths():
                for handler in self._handlers.get((name, key), ()):
                    self._call(handler, item)
            return self._reply()
        for handler in self._handlers.get((name, key), ()):
            if key != "command":
                self._call(handler, WebEvent(widget, info))
            elif widget is not None and widget.kind == "Scale":
                self._call(handler, widget.shown())
            else:
                self._call(handler)
        return self._reply()

    def _reply(self):
        html = {
            name: str(self._render(self._widgets[name]))
            for name in sorted(self._dirty)
            if name in self._widgets
        }
        reply = dict(self._changes)
        reply.update(html=html, notes=self._notes, timers=self._pending)
        self._dirty, self._changes, self._notes, self._pending = set(), {}, [], []
        return reply

    @staticmethod
    def _text(value):
        if value is None or value is False:
            return ""
        if isinstance(value, list) and len(value) == 2:
            return str(value[1])
        return str(value)

    def _fill(self, grid, columns, load):
        try:
            rows = load()
        except Exception as error:
            self.notify(error)
            return []
        if not columns and rows:
            columns = list(rows[0])
            grid.configure(columns=columns)
        grid.delete(*grid.get_children())
        for index, row in enumerate(rows):
            values = [self._text(row.get(column)) for column in columns]
            grid.insert("", "end", iid=str(index), values=values)
        return rows
''';

  /// La aplicación de Flask: solo escucha en este equipo, comprueba el Host
  /// (nadie llega con DNS rebinding) y exige la marca CSRF en cada evento.
  static const server = r'''


def create_app(form_class):
    """The Flask application of a form.

    Launched by DMarlon Studio, DMSTUDIO_WEB_SECRET is the secret of this run: the
    page asks for it and nobody else on this computer can open it. Exported,
    the file makes up its own. DMSTUDIO_WEB_HOSTS lists the host names of a
    server it was deployed to; by default only this computer's are accepted.
    """
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024
    launched = os.environ.get("DMSTUDIO_WEB_SECRET", "")
    secret = (launched or secrets.token_urlsafe(32)).encode("utf-8")
    csrf = hmac.new(secret, b"csrf", "sha256").hexdigest()
    # Each process has its own pages and its own secret: with several
    # workers an event can reach one that did not open the page.
    process = secrets.token_urlsafe(8)
    extra = os.environ.get("DMSTUDIO_WEB_HOSTS", "")
    hosts = LOCAL_HOSTS | {h.strip().lower() for h in extra.split(",") if h.strip()}
    forms = OrderedDict()
    render = app.jinja_env.from_string(WIDGETS).module.widget
    page = app.jinja_env.from_string(PAGE)
    # All user code runs on one thread, as in a window: handlers never overlap
    # and a database connection stays on the thread that opened it.
    worker = concurrent.futures.ThreadPoolExecutor(max_workers=1)

    def same(given, expected):
        return hmac.compare_digest(given.encode("utf-8"), expected)

    def open_form():
        form = form_class()
        form._render = render
        form._start()
        return form, form._reply()

    @app.before_request
    def check():
        host = request.host.lower()
        if ":" in host and not host.endswith("]"):
            host = host.rsplit(":", 1)[0]
        if host not in hosts:
            abort(403)
        if request.method not in ("GET", "HEAD", "OPTIONS"):
            if request.headers.get("X-DMS-Process", process) != process:
                return jsonify(error="process"), 409
            if not same(request.headers.get("X-DMS-CSRF", ""), csrf.encode()):
                abort(403)

    @app.after_request
    def harden(response):
        nonce = getattr(g, "nonce", "")
        script = "script-src 'nonce-%s'; " % nonce if nonce else ""
        response.headers["Content-Security-Policy"] = (
            "default-src 'none'; " + script + "style-src 'unsafe-inline'; "
            "img-src data:; connect-src 'self'; form-action 'none'; "
            "base-uri 'none'; frame-ancestors 'none'"
        )
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        # The log never shows the query: the page address carries the secret.
        print(request.method, request.path, response.status_code, flush=True)
        return response

    @app.get("/")
    def index():
        if launched and not same(request.args.get("key", ""), secret):
            abort(403)
        form, reply = worker.submit(open_form).result()
        sid = secrets.token_urlsafe(16)
        forms[sid] = form
        while len(forms) > MAX_FORMS:
            forms.popitem(last=False)
        boot = dict(reply, sid=sid, csrf=csrf, process=process)
        boot.update(width=form.root.width, height=form.root.height)
        g.nonce = secrets.token_urlsafe(16)
        return page.render(form=form, widget=render, boot=boot, nonce=g.nonce)

    @app.post("/event")
    def event():
        data = request.get_json(silent=True)
        if not isinstance(data, dict):
            abort(400)
        form = forms.get(str(data.get("sid")))
        if form is None:
            return jsonify(error="expired"), 409
        return jsonify(worker.submit(form._event, data).result())

    return app


def watch_studio():
    """An app has no window to close: it ends with DMarlon Studio, which launched it."""
    try:
        sys.stdin.read()
    finally:
        os._exit(0)


def serve(app):
    """Only on this computer: 127.0.0.1, without debug mode or reloader. From
    DMarlon Studio it takes a free port and says which one when it is listening.
    By hand it uses PORT or 8000: on macOS the system takes 5000. A port in
    use stops it with werkzeug's message.
    """
    logging.getLogger("werkzeug").disabled = True
    launched = bool(os.environ.get("DMSTUDIO_WEB_SECRET"))
    port = 0 if launched else int(os.environ.get("PORT") or 8000)
    server = make_server("127.0.0.1", port, app, threaded=True)
    if launched:
        threading.Thread(target=watch_studio, daemon=True).start()
        print("DMSTUDIO_WEB_READY", server.server_port, flush=True)
    else:
        print("http://127.0.0.1:%d/" % server.server_port, flush=True)
    server.serve_forever()
''';
}
