# Una demo de DMarlon Studio en español y en inglés (scripts/build_demos.py).
#
# Lleva dentro el programa en los dos idiomas (app_es.py y app_en.py, tal
# como los exporta el estudio) y abre el del idioma elegido: el que se guardó
# en «DMarlon Studio Demos/lang» (el mismo para todas las demos) o, la primera
# vez, el del sistema. Añade a la ventana el menú Idioma / Language: al
# cambiar, la aplicación se cierra y se vuelve a abrir en el otro idioma.
import os
import runpy
import subprocess
import sys
import tkinter as tk

if False:  # para que PyInstaller lleve los dos programas
    import app_en  # noqa: F401
    import app_es  # noqa: F401

NAMES = {"es": "Español", "en": "English"}
TEXTS = {
    "es": ("Idioma", "Cambiar de idioma",
           "La aplicación se volverá a abrir en {0}. Lo que no esté guardado se perderá."),
    "en": ("Language", "Change language",
           "The app will reopen in {0}. Anything not saved will be lost."),
}


def pref_file():
    if sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support")
    elif sys.platform == "win32":
        base = os.environ.get("APPDATA") or os.path.expanduser("~")
    else:
        base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(base, "DMarlon Studio Demos", "lang")


def system_lang():
    try:
        if sys.platform == "darwin":
            out = subprocess.run(["defaults", "read", "-g", "AppleLanguages"],
                                 capture_output=True, text=True, timeout=3).stdout
            first = out.replace("(", "").replace('"', "").split(",")[0].strip()
            return "es" if first.lower().startswith("es") else "en"
        if sys.platform == "win32":
            import ctypes
            ui = ctypes.windll.kernel32.GetUserDefaultUILanguage()
            return "es" if ui & 0x3FF == 0x0A else "en"
        import locale
        code = locale.getlocale()[0] or os.environ.get("LANG", "")
        return "es" if code.lower().startswith("es") else "en"
    except Exception:
        return "en"


def wanted():
    try:
        with open(pref_file(), encoding="utf-8") as f:
            value = f.read().strip()
        if value in NAMES:
            return value
    except OSError:
        pass
    return system_lang()


LANG = wanted()
switch_to = None


def add_menu(root):
    from tkinter import messagebox

    label, title, ask = TEXTS[LANG]
    name = root.cget("menu")
    bar = root.nametowidget(name) if name else tk.Menu(root)
    var = tk.StringVar(root, LANG)
    root._dms_lang = var  # que no se pierda

    def pick(code):
        global switch_to
        var.set(LANG)
        if code == LANG or not messagebox.askokcancel(title, ask.format(NAMES[code]), parent=root):
            return
        os.makedirs(os.path.dirname(pref_file()), exist_ok=True)
        with open(pref_file(), "w", encoding="utf-8") as f:
            f.write(code)
        switch_to = code
        root.destroy()

    sub = tk.Menu(bar, tearoff=0)
    for code in NAMES:
        sub.add_radiobutton(label=NAMES[code], value=code, variable=var,
                            command=lambda c=code: pick(c))
    bar.add_cascade(label=label, menu=sub)
    if not name:
        root.config(menu=bar)


_tk_init = tk.Tk.__init__


def _init(self, *args, **kwargs):
    _tk_init(self, *args, **kwargs)
    if not getattr(tk, "_dms_lang_menu", False):
        tk._dms_lang_menu = True
        # Cuando la demo ya montó su ventana (y su menú, si tiene).
        self.after_idle(lambda: add_menu(self))


tk.Tk.__init__ = _init

if __name__ == "__main__":
    try:
        runpy.run_module("app_" + LANG, run_name="__main__", alter_sys=True)
    except SystemExit:
        pass
    if switch_to:
        if getattr(sys, "frozen", False):
            os.execv(sys.executable, [sys.executable])
        else:
            os.execv(sys.executable, [sys.executable, os.path.abspath(__file__)])
