/// Código de Python que acompaña a las ventanas con datos. Va dentro del
/// archivo generado, y solo en las que lo usan: las demás no saben nada de
/// bases de datos. No lleva ni fichas, ni contraseñas, ni direcciones: todo
/// eso llega al lanzar la ventana, por el entorno, y solo existe mientras
/// dura.
class TkHelpers {
  TkHelpers._();

  /// Botón con los colores del diseño. En macOS tk.Button pinta siempre el del
  /// sistema, sea cual sea su fondo: allí se dibuja sobre una etiqueta, que lo
  /// respeta y ocupa todo su tamaño. Las pulsaciones van en su propia etiqueta
  /// de eventos para que los eventos del diseño, que usan bind sin add, no las
  /// sustituyan.
  static const colorButton = r'''


class _MacColorButton(tk.Label):
    """tk.Button for macOS, where the real one ignores its background."""

    def __init__(self, master=None, command=None, **options):
        super().__init__(master, **options)
        self._command = command
        self._pressed = False
        self.bindtags(("ColorButton",) + self.bindtags())
        self.bind_class("ColorButton", "<Button-1>", _MacColorButton._press)
        self.bind_class(
            "ColorButton", "<ButtonRelease-1>", _MacColorButton._release
        )

    def configure(self, cnf=None, **options):
        if "command" in options:
            self._command = options.pop("command")
        return super().configure(cnf, **options)

    config = configure

    def invoke(self):
        if self._command and self.cget("state") != "disabled":
            return self._command()

    @staticmethod
    def _press(event):
        self = event.widget
        if self.cget("state") == "disabled":
            return
        self._pressed = True
        shade = [c * 3 // 4 for c in self.winfo_rgb(self.cget("bg"))]
        self.configure(
            state="active",
            activebackground="#%04x%04x%04x" % tuple(shade),
            activeforeground=self.cget("fg"),
        )

    @staticmethod
    def _release(event):
        self = event.widget
        if not self._pressed:
            return
        self._pressed = False
        self.configure(state="normal")
        if (0 <= event.x < self.winfo_width()
                and 0 <= event.y < self.winfo_height()):
            self.invoke()


ColorButton = _MacColorButton if sys.platform == "darwin" else tk.Button
''';

  /// Temporizador: el componente no visual que llama a un método cada
  /// cierto número de milisegundos. Usa root.after, que existe igual en una
  /// ventana y en una aplicación web.
  static const designTimer = r'''


class DesignTimer:
    """Calls a method every interval milliseconds while enabled.

    self.Timer1.enabled = False stops it and True starts it again;
    self.Timer1.start(500) restarts it with another interval.
    """

    def __init__(self, root, interval, callback=None, enabled=True):
        self.root = root
        self.interval = max(1, int(interval))
        self.callback = callback
        self._job = None
        self._on = False
        self.enabled = enabled

    @property
    def enabled(self):
        return self._on

    @enabled.setter
    def enabled(self, on):
        on = bool(on)
        if on == self._on:
            return
        self._on = on
        if on:
            self._job = self.root.after(self.interval, self._tick)
        elif self._job is not None:
            self.root.after_cancel(self._job)
            self._job = None

    def start(self, interval=None):
        if interval is not None:
            self.interval = max(1, int(interval))
        self.stop()
        self.enabled = True

    def stop(self):
        self.enabled = False

    def _tick(self, *args):
        self._job = None
        if not self._on:
            return
        self._job = self.root.after(self.interval, self._tick)
        if self.callback is not None:
            self.callback()
''';

  /// Cinta de opciones al estilo de Office para tkinter: pestañas arriba y,
  /// debajo, los grupos de la pestaña activa con sus botones grandes. Los
  /// botones son etiquetas (como ColorButton) para que macOS respete sus
  /// colores.
  static const designRibbon = r'''


import tkinter.font


class DesignRibbon(tk.Frame):
    """Office-style ribbon: tabs, groups of big buttons and their captions.

    command(item) gets the path of the button ("Inicio/Fuente/Negrita") and
    change() runs when the user picks another tab. select(i) shows a tab
    (without i, tells which one is shown); enable(item, False) greys out a
    button.
    """

    BAR = "#f3f3f3"
    BODY = "#ffffff"
    LINE = "#d6d6d6"
    TEXT = "#262626"
    ACCENT = "#2b579a"
    HOVER = "#e1ecfa"
    DIM = "#a6a6a6"

    def __init__(self, master, tabs, active=0, height=92, command=None,
                 change=None):
        super().__init__(master, bg=self.BAR, height=height, bd=0,
                         highlightthickness=0)
        self.tabs = list(tabs)
        self.command = command
        self.change = change
        self._active = -1
        self._off = set()
        self._buttons = {}
        base = tkinter.font.nametofont("TkDefaultFont")
        self._glyph_font = base.copy()
        self._glyph_font.configure(size=max(14, base.cget("size") + 6))
        self._small = base.copy()
        self._small.configure(size=max(8, base.cget("size") - 2))
        self.bar = tk.Frame(self, bg=self.BAR, bd=0, highlightthickness=0)
        self.bar.pack(side="top", fill="x")
        self.body = tk.Frame(self, bg=self.BODY, bd=0, highlightthickness=1,
                             highlightbackground=self.LINE)
        self.body.pack(side="top", fill="both", expand=True)
        self._tabs = []
        for index, tab in enumerate(self.tabs):
            label = tk.Label(self.bar, text=tab["label"], bg=self.BAR,
                             fg=self.TEXT, padx=12, pady=3, cursor="hand2")
            label.pack(side="left")
            label.bind("<Button-1>", lambda event, i=index: self._pick(i))
            self._tabs.append(label)
        self.select(active)

    def _pick(self, index):
        if index != self._active:
            self.select(index)
            if self.change:
                self.change()

    def select(self, index=None):
        """Show tab index; without it, the index of the tab shown."""
        if index is None:
            return self._active
        if not self.tabs:
            return 0
        index = max(0, min(int(index), len(self.tabs) - 1))
        if index == self._active:
            return index
        self._active = index
        for i, label in enumerate(self._tabs):
            on = i == index
            label.configure(bg=self.BODY if on else self.BAR,
                            fg=self.ACCENT if on else self.TEXT)
        for child in self.body.winfo_children():
            child.destroy()
        self._buttons = {}
        for number, group in enumerate(self.tabs[index]["groups"]):
            if number:
                tk.Frame(self.body, bg=self.LINE, width=1).pack(
                    side="left", fill="y", pady=6)
            self._group(group)
        return index

    def _group(self, group):
        box = tk.Frame(self.body, bg=self.BODY)
        box.pack(side="left", fill="y", padx=3)
        tk.Label(box, text=group["label"], bg=self.BODY, fg="#6e6e6e",
                 font=self._small).pack(side="bottom")
        row = tk.Frame(box, bg=self.BODY)
        row.pack(side="top", fill="both", expand=True)
        for button in group["buttons"]:
            self._button(row, button)

    def _button(self, row, button):
        path = button["path"]
        cell = tk.Frame(row, bg=self.BODY, cursor="hand2")
        cell.pack(side="left", fill="y", padx=1, pady=1)
        parts = [cell]
        if button.get("glyph"):
            glyph = tk.Label(cell, text=button["glyph"], bg=self.BODY,
                             fg=self.ACCENT, font=self._glyph_font)
            glyph.pack(side="top", padx=6)
            parts.append(glyph)
        text = tk.Label(cell, text=button["label"], bg=self.BODY,
                        fg=self.TEXT, padx=6)
        text.pack(side="top")
        parts.append(text)
        self._buttons[path] = parts

        def paint(color):
            for part in parts:
                part.configure(bg=color)

        def enter(event):
            if path not in self._off:
                paint(self.HOVER)

        def click(event):
            if path not in self._off and self.command:
                self.command(path)

        for part in parts:
            part.bind("<Enter>", enter)
            part.bind("<Leave>", lambda event: paint(self.BODY))
            part.bind("<Button-1>", click)
        self._shade(path)

    def _shade(self, path):
        parts = self._buttons.get(path)
        if not parts:
            return
        off = path in self._off
        for part in parts[1:]:
            if part is parts[-1]:
                part.configure(fg=self.DIM if off else self.TEXT)
            else:
                part.configure(fg=self.DIM if off else self.ACCENT)

    def enable(self, item, on=True):
        """Grey out (False) or enable again (True) the button item."""
        if on:
            self._off.discard(item)
        else:
            self._off.add(item)
        self._shade(item)

    def paths(self):
        return [b["path"] for t in self.tabs for g in t["groups"]
                for b in g["buttons"]]
''';

  /// Integración con una API HTTP/JSON: solo la biblioteca estándar
  /// (urllib), igual en una ventana y en una aplicación web. Los secretos no
  /// van en el archivo: se leen de variables de entorno, y las variables de
  /// la API de DMarlon Studio llegan como `DMSTUDIO_ENV_<NOMBRE>`.
  static const apiClient = r'''


import base64
import json
import os
import queue
import re
import threading
import urllib.error
import urllib.parse
import urllib.request


class ApiError(Exception):
    """An API call failed: status is the HTTP code (0 = no answer)."""

    def __init__(self, message, status=0, body=""):
        super().__init__(message)
        self.status = status
        self.body = body


class ApiClient:
    """HTTP/JSON API: get(path, params), post(path, data), put, patch and
    delete return the answer (JSON as Python values, otherwise text) or raise
    ApiError. get_async, post_async... run in the background and call the
    done event with the result, or the error event with the ApiError.

    {{name}} in the base URL and the headers is the API variable name of
    DMarlon Studio (passed as DMSTUDIO_ENV_NAME) or the environment variable
    name. Tokens and passwords are read from environment variables.
    """

    def __init__(self, root, base_url="", auth="none", token="", token_env="",
                 user="", password_env="", header_name="X-API-Key",
                 headers="", timeout=30, done=None, error=None):
        self.root = root
        self.base_url = base_url
        self.auth = auth
        self.token = token
        self.token_env = token_env
        self.user = user
        self.password_env = password_env
        self.header_name = header_name or "X-API-Key"
        self.headers = headers
        self.timeout = timeout
        self.done = done
        self.error = error
        self.status = None

    @staticmethod
    def env(name):
        """An API variable of DMarlon Studio, or an environment variable."""
        name = (name or "").strip()
        if not name:
            return ""
        key = "DMSTUDIO_ENV_" + re.sub(r"[^A-Za-z0-9_]", "_", name).upper()
        return os.environ.get(key) or os.environ.get(name, "")

    def expand(self, text):
        return re.sub(
            r"\{\{\s*([^{}\s]+)\s*\}\}",
            lambda m: self.env(m.group(1)),
            text or "",
        )

    def secret(self):
        return self.token or self.env(self.token_env)

    def url(self, path="", params=None):
        path = self.expand(path or "")
        if re.match(r"^[a-z][a-z0-9+.-]*://", path, re.I):
            url = path
        else:
            base = self.expand(self.base_url).rstrip("/")
            url = base + ("/" + path.lstrip("/") if path else "")
        if params:
            query = urllib.parse.urlencode(params, doseq=True)
            url += ("&" if "?" in url else "?") + query
        return url

    def request_headers(self):
        out = {"Accept": "application/json"}
        for line in (self.headers or "").splitlines():
            if ":" in line:
                name, value = line.split(":", 1)
                if name.strip():
                    out[name.strip()] = self.expand(value.strip())
        if self.auth == "bearer" and self.secret():
            out["Authorization"] = "Bearer " + self.secret()
        elif self.auth == "basic":
            pair = "%s:%s" % (self.expand(self.user), self.env(self.password_env))
            out["Authorization"] = "Basic " + base64.b64encode(
                pair.encode("utf-8")).decode("ascii")
        elif self.auth == "header" and self.secret():
            out[self.header_name] = self.secret()
        return out

    def request(self, method, path="", data=None, params=None, headers=None):
        """One call. data: dict/list (sent as JSON), str or bytes."""
        method = method.upper()
        url = self.url(path, params)
        sent = self.request_headers()
        body = None
        if data is not None:
            if isinstance(data, (bytes, bytearray)):
                body = bytes(data)
            elif isinstance(data, str):
                body = data.encode("utf-8")
                sent.setdefault("Content-Type", "text/plain; charset=utf-8")
            else:
                body = json.dumps(data).encode("utf-8")
                sent.setdefault("Content-Type", "application/json")
        if headers:
            sent.update(headers)
        call = urllib.request.Request(url, data=body, headers=sent,
                                      method=method)
        try:
            with urllib.request.urlopen(call, timeout=self.timeout) as answer:
                self.status = answer.status
                kind = answer.headers.get("Content-Type", "")
                return self._parse(answer.read(), kind)
        except urllib.error.HTTPError as failure:
            self.status = failure.code
            text = failure.read().decode("utf-8", "replace")
            raise ApiError("%s %s: HTTP %s %s" % (
                method, url, failure.code, text[:300]), failure.code,
                text) from None
        except (urllib.error.URLError, OSError, ValueError) as failure:
            self.status = 0
            reason = getattr(failure, "reason", failure)
            raise ApiError("%s %s: %s" % (method, url, reason)) from None

    @staticmethod
    def _parse(raw, kind):
        text = raw.decode("utf-8", "replace")
        if not text.strip():
            return None
        if "json" in kind or text.lstrip()[:1] in ("{", "["):
            try:
                return json.loads(text)
            except ValueError:
                pass
        return text

    def get(self, path="", params=None, headers=None):
        return self.request("GET", path, None, params, headers)

    def post(self, path="", data=None, params=None, headers=None):
        return self.request("POST", path, data, params, headers)

    def put(self, path="", data=None, params=None, headers=None):
        return self.request("PUT", path, data, params, headers)

    def patch(self, path="", data=None, params=None, headers=None):
        return self.request("PATCH", path, data, params, headers)

    def delete(self, path="", params=None, headers=None):
        return self.request("DELETE", path, None, params, headers)

    def _background(self, method, path, data=None, params=None):
        """In a window the call runs in a thread and the events arrive on
        the window's thread; in a web app it runs at once on the server.
        """
        def call():
            return self.request(method, path, data, params)

        if not hasattr(self.root, "tk"):
            try:
                result = call()
            except ApiError as failure:
                return self._fire(self.error, failure)
            return self._fire(self.done, result)
        box = queue.Queue()

        def work():
            try:
                box.put((True, call()))
            except Exception as failure:
                box.put((False, failure))

        def check():
            try:
                ok, value = box.get_nowait()
            except queue.Empty:
                self.root.after(40, check)
                return
            self._fire(self.done if ok else self.error, value)

        threading.Thread(target=work, daemon=True).start()
        self.root.after(40, check)

    @staticmethod
    def _fire(handler, value):
        if handler is not None:
            handler(value)
        elif isinstance(value, Exception):
            raise value

    def get_async(self, path="", params=None):
        self._background("GET", path, None, params)

    def post_async(self, path="", data=None, params=None):
        self._background("POST", path, data, params)

    def put_async(self, path="", data=None, params=None):
        self._background("PUT", path, data, params)

    def patch_async(self, path="", data=None, params=None):
        self._background("PATCH", path, data, params)

    def delete_async(self, path="", params=None):
        self._background("DELETE", path, None, params)
''';

  /// Barra de estado con un icono opcional a la izquierda del texto.
  static const designStatus = r'''


class DesignStatus(tk.Label):
    """Status bar docked at the bottom, with an optional icon at the left.

    configure(text=..., icon=...) or set(text, icon) change them; icon is a
    name (save, info, check, mail...) or a character.
    """

    def __init__(self, master=None, icon="", **options):
        self._text = str(options.pop("text", ""))
        self._icon = _glyph(icon)
        super().__init__(master, text=self._shown(), **options)

    def _shown(self):
        return self._icon + "  " + self._text if self._icon else self._text

    def configure(self, cnf=None, **options):
        touched = False
        if "icon" in options:
            self._icon = _glyph(options.pop("icon"))
            touched = True
        if "text" in options:
            self._text = str(options.pop("text"))
            touched = True
        if touched:
            options["text"] = self._shown()
        return super().configure(cnf, **options)

    config = configure

    def cget(self, key):
        if key == "text":
            return self._text
        if key == "icon":
            return self._icon
        return super().cget(key)

    __getitem__ = cget

    def __setitem__(self, key, value):
        self.configure(**{key: value})

    def set(self, text=None, icon=None):
        """Change the text and/or the icon."""
        options = {}
        if text is not None:
            options["text"] = text
        if icon is not None:
            options["icon"] = icon
        self.configure(**options)
''';

  /// Icono en la barra de menús (macOS) o en el área de notificación
  /// (Windows y Linux) con pystray y Pillow. Sin ellos, avisa en la salida y
  /// la ventana sigue funcionando. Los clics llegan en otro hilo: pasan a la
  /// ventana por una cola que se lee con root.after.
  static const designTray = r'''


import queue
import sys
import threading


class DesignTray:
    """Icon in the menu bar (macOS) or the notification area (Windows,
    Linux). Needs pystray and Pillow: python3 -m pip install pystray pillow.
    Without them it says so in the output and the window works as usual.

    show() and hide() show or hide it; notify(title, message) shows a
    notification where the system allows it.
    """

    def __init__(self, root, tooltip="", icon="", items=(), click=None,
                 command=None):
        self.root = root
        self.tooltip = tooltip or root.title()
        self.click = click
        self.command = command
        self.available = False
        self._icon = None
        self._started = False
        self._events = queue.Queue()
        try:
            import pystray
            from PIL import Image, ImageDraw
        except ImportError:
            print(
                "The tray icon needs pystray and Pillow: "
                "python3 -m pip install pystray pillow",
                flush=True,
            )
            return
        self._pystray = pystray
        image = self._image(icon, Image, ImageDraw)
        entries = [pystray.MenuItem(self.tooltip, self._clicked, default=True,
                                    visible=False)]
        entries += self._entries(items)
        self._icon = pystray.Icon("dmarlonstudio", image, self.tooltip,
                                  pystray.Menu(*entries))
        self.available = True
        root.bind("<Destroy>", self._closed, add="+")
        self.root.after(100, self._pump)
        self.show()

    def _image(self, path, Image, ImageDraw):
        if path:
            try:
                return Image.open(path)
            except OSError:
                print("Tray icon image not found: " + path, flush=True)
        size = 64
        image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((2, 2, size - 2, size - 2), radius=14,
                               fill=(43, 95, 217, 255))
        letter = (self.tooltip.strip() or "D")[0].upper()
        draw.text((size // 2, size // 2), letter, fill=(255, 255, 255, 255),
                  anchor="mm")
        return image

    def _entries(self, items):
        out = []
        for item in items:
            if item.get("sep"):
                out.append(self._pystray.Menu.SEPARATOR)
            elif item.get("items"):
                out.append(self._pystray.MenuItem(
                    item["label"],
                    self._pystray.Menu(*self._entries(item["items"]))))
            else:
                path = item["path"]
                out.append(self._pystray.MenuItem(
                    item["label"],
                    lambda icon, entry, path=path: self._events.put(path)))
        return out

    def _clicked(self, icon=None, entry=None):
        self._events.put(None)

    def _pump(self):
        try:
            while True:
                path = self._events.get_nowait()
                if path is None:
                    if self.click:
                        self.click()
                elif self.command:
                    self.command(path)
        except queue.Empty:
            pass
        try:
            self.root.after(100, self._pump)
        except tk.TclError:
            pass

    def show(self):
        if not self.available:
            return
        if not self._started:
            self._started = True
            try:
                if sys.platform == "darwin":
                    self._icon.run_detached()
                else:
                    threading.Thread(target=self._icon.run,
                                     daemon=True).start()
            except Exception as error:
                self.available = False
                print("The tray icon could not start: %s" % error,
                      flush=True)
                return
        self._icon.visible = True

    def hide(self):
        if self.available and self._started:
            self._icon.visible = False

    def notify(self, title, message=""):
        if not self.available:
            return
        try:
            self._icon.notify(message or title, title if message else None)
        except Exception:
            print("%s: %s" % (title, message), flush=True)

    def stop(self):
        if self.available and self._started:
            self._started = False
            try:
                self._icon.stop()
            except Exception:
                pass

    def _closed(self, event):
        if event.widget is self.root:
            self.stop()
''';

  /// Campo de contraseña: oculta lo escrito y, si se quiere, un botón para
  /// verlo. Se usa como un Entry (get, insert, delete, bind…).
  static const designPassword = r'''


class DesignPassword(tk.Frame):
    """Password field: an Entry that hides its text, with an optional
    button to show it. get(), insert(), delete() and bind() work as in an
    Entry; visible(True) shows the text and visible(False) hides it again.
    """

    HIDDEN = "•"

    def __init__(self, master, textvariable=None, reveal=True, maxlength=0,
                 hint="", state="normal", **options):
        bg = options.get("bg", "#ffffff")
        fg = options.get("fg", "#000000")
        super().__init__(master, bg=bg, bd=0, highlightthickness=1,
                         highlightbackground="#8a8f98",
                         highlightcolor="#2b579a")
        self.var = textvariable or tk.StringVar()
        self.maxlength = int(maxlength or 0)
        self.entry = tk.Entry(self, textvariable=self.var, show=self.HIDDEN,
                              bd=0, highlightthickness=0,
                              insertbackground=fg, **options)
        self.entry.pack(side="left", fill="both", expand=True, padx=(4, 0))
        self.eye = None
        if reveal:
            self.eye = tk.Label(self, text="◉", bg=bg, fg="#6e7480",
                                padx=4, cursor="hand2")
            self.eye.pack(side="right", fill="y")
            self.eye.bind("<Button-1>", lambda event: self.visible(
                self.entry.cget("show") != ""))
        self.hint = None
        if hint:
            self.hint = tk.Label(self, text=hint, bg=bg, fg="#9096a0",
                                 anchor="w")
            self.hint.bind("<Button-1>", lambda event: self.entry.focus_set())
            for name in ("<FocusIn>", "<FocusOut>"):
                self.entry.bind(name, lambda event: self._hint(), add="+")
        self.var.trace_add("write", lambda *args: self._changed())
        if state != "normal":
            self.entry.configure(state=state)
        self._hint()

    def _changed(self):
        text = self.var.get()
        if self.maxlength and len(text) > self.maxlength:
            self.var.set(text[: self.maxlength])
        self._hint()

    def _hint(self):
        if self.hint is None:
            return
        empty = not self.var.get() and self.focus_get() is not self.entry
        if empty:
            self.hint.place(x=4, y=0, relheight=1.0)
        else:
            self.hint.place_forget()

    def visible(self, on=True):
        """Show (True) or hide (False) the text."""
        self.entry.configure(show="" if on else self.HIDDEN)
        if self.eye is not None:
            self.eye.configure(text="○" if on else "◉")

    def get(self):
        return self.var.get()

    def insert(self, index, text):
        self.entry.insert(index, text)

    def delete(self, first, last=None):
        self.entry.delete(first, last)

    def focus_set(self):
        self.entry.focus_set()

    def bind(self, sequence=None, func=None, add=None):
        return self.entry.bind(sequence, func, add)

    def configure(self, cnf=None, **options):
        if "state" in options:
            self.entry.configure(state=options.pop("state"))
        if options or cnf:
            return self.entry.configure(cnf, **options)

    config = configure

    def cget(self, key):
        return self.entry.cget(key)
''';

  /// Ruta de un archivo del proyecto (imágenes): se ejecuta desde la carpeta
  /// del proyecto, pero también junto al archivo generado si se exportó.
  static const projectFile = r'''


import os


def _project_file(path):
    """Path of a file of the project: from the project folder (where
    DMarlon Studio runs the window) or next to this file."""
    if not path or os.path.isabs(path):
        return path
    here = os.path.dirname(os.path.abspath(__file__))
    for base in (os.getcwd(), os.path.dirname(here), here):
        candidate = os.path.join(base, path)
        if os.path.exists(candidate):
            return candidate
    return path
''';

  /// Imagen de un archivo. PNG y GIF van con Tk; JPG y el ajuste al tamaño,
  /// con Pillow si está (sin él, la imagen va a su tamaño o un aviso).
  static const designImage = r'''


class DesignImage(tk.Label):
    """Shows an image file. fit: none, contain, cover or stretch.
    load(path) shows another one. PNG and GIF need nothing else; JPG and
    fitting the image to the size need Pillow (python3 -m pip install pillow).
    """

    def __init__(self, master, file="", fit="contain", width=160,
                 height=120, **options):
        options.setdefault("bg", "#ffffff")
        super().__init__(master, **options)
        self.fit = fit
        self.box = (max(1, int(width)), max(1, int(height)))
        self.photo = None
        self.file = ""
        if file:
            self.load(file)

    def load(self, path):
        """Show the image of path (relative to the project folder)."""
        self.file = path
        real = _project_file(path)
        try:
            self.photo = self._pillow(real)
        except ImportError:
            self.photo = self._plain(real)
        except OSError:
            self.photo = None
        if self.photo is None:
            self.configure(image="", text=os.path.basename(path) or "?")
        else:
            self.configure(image=self.photo, text="")

    def _pillow(self, real):
        from PIL import Image, ImageTk

        image = Image.open(real)
        w, h = self.box
        if self.fit == "stretch":
            image = image.resize((w, h))
        elif self.fit == "contain":
            scale = min(w / image.width, h / image.height)
            image = image.resize((max(1, int(image.width * scale)),
                                  max(1, int(image.height * scale))))
        elif self.fit == "cover":
            scale = max(w / image.width, h / image.height)
            image = image.resize((max(1, int(image.width * scale)),
                                  max(1, int(image.height * scale))))
            left = (image.width - w) // 2
            top = (image.height - h) // 2
            image = image.crop((left, top, left + w, top + h))
        return ImageTk.PhotoImage(image)

    def _plain(self, real):
        if not real.lower().endswith((".png", ".gif")):
            print("Showing %s needs Pillow: python3 -m pip install pillow"
                  % os.path.basename(real), flush=True)
            return None
        try:
            photo = tk.PhotoImage(file=real)
        except tk.TclError:
            return None
        w, h = self.box
        if self.fit in ("contain", "cover", "stretch"):
            factor = max(1, -(-photo.width() // w), -(-photo.height() // h))
            if factor > 1:
                photo = photo.subsample(factor)
        return photo
''';

  /// Diálogos Abrir y Guardar (tkinter.filedialog). Recuerdan la última
  /// carpeta; Guardar añade la extensión por defecto si falta.
  static const designDialogs = r'''


import os
import tkinter.filedialog


def _filetypes(text):
    """[(name, patterns)] from lines like "Text|*.txt" or
    "Images|*.png;*.jpg", always ending with every file."""
    out = []
    for line in (text or "").splitlines():
        if "|" not in line:
            continue
        name, patterns = line.split("|", 1)
        found = tuple(p.strip() for p in patterns.replace(",", ";").split(";")
                      if p.strip())
        if name.strip() and found:
            out.append((name.strip(), found if len(found) > 1 else found[0]))
    out.append(("*.*", "*.*"))
    return out


class _DesignDialog:
    def __init__(self, root, title="", filter="", defaultext="",
                 initialdir="", select=None):
        self.root = root
        self.title = title
        self.filter = filter
        self.defaultext = defaultext
        self.initialdir = initialdir
        self.select = select
        self.filename = None
        self.filenames = []
        self._last = None

    def _options(self):
        options = {"filetypes": _filetypes(self.filter)}
        if self.root is not None:
            options["parent"] = self.root
        if self.title:
            options["title"] = self.title
        folder = self._last or self.initialdir
        if folder and not os.path.isabs(folder):
            folder = os.path.join(os.getcwd(), folder)
        if folder:
            options["initialdir"] = folder
        return options

    def _chosen(self, path):
        self._last = os.path.dirname(path[0] if isinstance(path, list) else path)
        if self.select:
            self.select(path)
        return path

    def with_extension(self, path):
        """path with the default extension when it has none."""
        ext = (self.defaultext or "").strip()
        if ext and not ext.startswith("."):
            ext = "." + ext
        if ext and not os.path.splitext(path)[1]:
            path += ext
        return path


class DesignOpenDialog(_DesignDialog):
    """Open dialog: execute() returns the path chosen (a list with
    multiple), or None; read_text() and read_bytes() also read it."""

    def __init__(self, root, multiple=False, **options):
        super().__init__(root, **options)
        self.multiple = multiple

    def execute(self):
        if self.multiple:
            paths = list(tkinter.filedialog.askopenfilenames(
                **self._options()) or ())
            if not paths:
                return None
            self.filenames = paths
            self.filename = paths[0]
            return self._chosen(paths)
        path = tkinter.filedialog.askopenfilename(**self._options())
        if not path:
            return None
        self.filename = path
        self.filenames = [path]
        return self._chosen(path)

    def read_text(self, encoding="utf-8"):
        """(path, text) of the file chosen, or None."""
        path = self.execute()
        if not path:
            return None
        path = path[0] if isinstance(path, list) else path
        with open(path, encoding=encoding) as source:
            return path, source.read()

    def read_bytes(self):
        """(path, bytes) of the file chosen, or None."""
        path = self.execute()
        if not path:
            return None
        path = path[0] if isinstance(path, list) else path
        with open(path, "rb") as source:
            return path, source.read()


class DesignSaveDialog(_DesignDialog):
    """Save dialog: execute() returns the path chosen (with the default
    extension), or None; write_text() and write_bytes() also write it."""

    def __init__(self, root, filename="", overwrite=True, **options):
        super().__init__(root, **options)
        self.suggested = filename
        self.overwrite = overwrite

    def execute(self):
        options = self._options()
        if self.suggested:
            options["initialfile"] = self.suggested
        if self.defaultext:
            ext = self.defaultext.strip()
            options["defaultextension"] = ext if ext.startswith(".") else "." + ext
        options["confirmoverwrite"] = bool(self.overwrite)
        path = tkinter.filedialog.asksaveasfilename(**options)
        if not path:
            return None
        path = self.with_extension(path)
        self.filename = path
        self.filenames = [path]
        self.suggested = os.path.basename(path)
        return self._chosen(path)

    def write_text(self, text, encoding="utf-8"):
        """Ask where and write text there: the path, or None."""
        path = self.execute()
        if path:
            with open(path, "w", encoding=encoding) as target:
                target.write(text)
        return path

    def write_bytes(self, data):
        """Ask where and write data there: the path, or None."""
        path = self.execute()
        if path:
            with open(path, "wb") as target:
                target.write(data)
        return path
''';

  static const dataError = r'''


class DataError(Exception):
    """A data source failed: the message is for the user."""
''';

  static const erpClient = r'''


class ErpClient:
    """ERP data through its API, with the rights of whoever opened the window.

    search, read, create and update work on the models of the ERP API.
    """

    def __init__(self):
        self.url = os.environ.get("DMSTUDIO_API_URL", "")
        self.token = os.environ.get("DMSTUDIO_API_TOKEN", "")
        # Never through a proxy: the token is for the local server only.
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def call(self, model, method, args=(), kwargs=None):
        if not self.url or not self.token:
            raise DataError("Open this window from the ERP: it needs its API.")
        body = {
            "model": model,
            "method": method,
            "args": list(args),
            "kwargs": kwargs or {},
        }
        request = urllib.request.Request(
            self.url + "/api/tk/call",
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer " + self.token,
            },
        )
        try:
            with self.opener.open(request, timeout=30) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            try:
                data = json.loads(error.read().decode("utf-8"))
            except ValueError:
                raise DataError(str(error)) from None
        except (OSError, ValueError) as error:
            raise DataError("The ERP API did not answer: {}".format(error)) from None
        if "error" in data:
            raise DataError(data["error"].get("message", "ERP error"))
        return data["result"]

    def search(self, model, domain=(), fields=None, limit=100, order=None):
        options = {"limit": limit}
        if fields:
            options["fields"] = list(fields)
        if order:
            options["order"] = order
        return self.call(model, "search_read", [list(domain)], options)

    def read(self, model, ids, fields=None):
        options = {"fields": list(fields)} if fields else {}
        return self.call(model, "read", [list(ids)], options)

    def create(self, model, values):
        return self.call(model, "create", [values])

    def update(self, model, ids, values):
        return self.call(model, "write", [list(ids), values])
''';

  static const sqlClient = r'''


class SqlClient:
    """Another database. Its connection data arrives in the environment.

    Queries always go with parameters: write ? and pass the values apart,
    never joined into the text. SQLite needs nothing else; PostgreSQL needs
    psycopg or psycopg2, and MySQL needs pymysql.
    """

    def __init__(self, name):
        self.prefix = "DMSTUDIO_DB_" + name.upper() + "_"
        self.name = name
        self.kind = self.value("KIND")
        self.connection = None

    def value(self, key):
        return os.environ.get(self.prefix + key, "")

    def open(self):
        if self.connection is not None:
            return self.connection
        ssl = self.value("SSL") == "1"
        try:
            if self.kind == "sqlite":
                import sqlite3

                self.connection = sqlite3.connect(self.value("PATH"))
            elif self.kind == "postgres":
                try:
                    import psycopg as driver
                except ImportError:
                    import psycopg2 as driver
                self.connection = driver.connect(
                    host=self.value("HOST"),
                    port=int(self.value("PORT") or 5432),
                    dbname=self.value("DATABASE"),
                    user=self.value("USER"),
                    password=self.value("PASSWORD"),
                    sslmode="require" if ssl else "disable",
                )
            elif self.kind == "mysql":
                import pymysql

                self.connection = pymysql.connect(
                    host=self.value("HOST"),
                    port=int(self.value("PORT") or 3306),
                    database=self.value("DATABASE"),
                    user=self.value("USER"),
                    password=self.value("PASSWORD"),
                    ssl={"ssl": {}} if ssl else None,
                )
            else:
                raise DataError(
                    "Open this window from DMarlon Studio: it needs " + self.name + "."
                )
        except DataError:
            raise
        except Exception as error:
            raise DataError(str(error)) from None
        return self.connection

    def statement(self, text, params):
        """Turn the ? marks into those of the driver (never inside quotes)."""
        if self.kind == "sqlite" or not params:
            return text
        out, quote = [], None
        for char in text:
            if quote:
                quote = None if char == quote else quote
                out.append("%%" if char == "%" else char)
            elif char in "'\"`":
                quote = char
                out.append(char)
            elif char == "?":
                out.append("%s")
            elif char == "%":
                out.append("%%")
            else:
                out.append(char)
        return "".join(out)

    def run(self, text, params):
        connection = self.open()
        cursor = connection.cursor()
        values = tuple(params)
        try:
            if values:
                cursor.execute(self.statement(text, values), values)
            else:
                cursor.execute(text)
            return cursor
        except Exception as error:
            connection.rollback()
            raise DataError(str(error)) from None

    def query(self, text, params=()):
        """The rows of a SELECT, as dictionaries."""
        cursor = self.run(text, params)
        names = [column[0] for column in cursor.description or []]
        rows = [dict(zip(names, row)) for row in cursor.fetchall()]
        cursor.close()
        self.connection.commit()
        return rows

    def execute(self, text, params=()):
        """Run INSERT, UPDATE or DELETE; returns the rows changed."""
        cursor = self.run(text, params)
        count = cursor.rowcount
        cursor.close()
        self.connection.commit()
        return count
''';

  static const gridFill = r'''

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
            tkinter.messagebox.showerror(self.root.title(), str(error))
            return []
        if not columns and rows:
            columns = list(rows[0])
            grid.configure(columns=columns)
            for column in columns:
                grid.heading(column, text=column)
        grid.delete(*grid.get_children())
        for index, row in enumerate(rows):
            values = [self._text(row.get(column)) for column in columns]
            grid.insert("", "end", iid=str(index), values=values)
        return rows
''';
}
