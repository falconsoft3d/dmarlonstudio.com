"""Ejecuta un ejemplo de tkinter y fotografía sus ventanas de verdad.

  python3 tk_run.py main.py <salida>     (salida: <salida>-1.png, -2.png…)
  python3 tk_run.py main.py -            (sin capturas: arranca y se cierra)

Cambia mainloop: al arrancar, deja las ventanas en claro (aspecto light),
encima de todo, espera a que se dibujen, las captura con screencapture -l
(sin sombra) y cierra. Lo usa scripts/build-courses.mjs; WINID es la ruta del
ayudante compilado de winid.swift.
"""
import os
import runpy
import subprocess
import sys
import tkinter

main, out = sys.argv[1], sys.argv[2]
_mainloop = tkinter.Misc.mainloop
_done = False


def _light(w):
    # Tk 9: wm attributes -appearance; Tk 8.6: MacWindowStyle.
    try:
        w.tk.call("wm", "attributes", w._w, "-appearance", "light")
    except tkinter.TclError:
        try:
            w.tk.call("::tk::unsupported::MacWindowStyle", "appearance", w._w, "aqua")
        except tkinter.TclError:
            pass


def _windows(root):
    found = [root]
    stack = [root]
    while stack:
        for c in stack.pop().winfo_children():
            if isinstance(c, tkinter.Toplevel):
                found.append(c)
            stack.append(c)
    return found


def _shoot(root):
    global _done
    if _done:
        return
    _done = True
    if out == "-":  # solo comprobar: que arranque y se cierre
        root.after(300, root.destroy)
        return
    for w in _windows(root):
        _light(w)
        w.attributes("-topmost", True)
        w.lift()
    root.update()

    wins = _windows(root)

    def take(i=0, ids=None):
        # De una en una: cada ventana al frente, se redibuja y se captura
        # (macOS no redibuja la que queda detrás).
        if ids is None:
            root.update()
            ids = subprocess.run([os.environ["WINID"], str(os.getpid())], capture_output=True, text=True).stdout.split()
            if not ids:
                print("tk_run: no window to capture", file=sys.stderr)
        if i >= len(ids):
            root.destroy()
            return
        if i < len(wins):
            # Activa: Tk no dibuja en la captura una ventana inactiva.
            wins[i].lift()
            wins[i].focus_force()
            wins[i].update()

        def shot():
            subprocess.run(["screencapture", "-x", "-o", f"-l{ids[i]}", f"{out}-{i + 1}.png"], check=True)
            take(i + 1, ids)

        root.after(400, shot)

    root.after(1200, take)


def mainloop(self, n=0):
    _shoot(self._root())
    _mainloop(self, n)


tkinter.Misc.mainloop = mainloop
tkinter.mainloop = lambda n=0: mainloop(tkinter._get_default_root(), n)
_Tk_init = tkinter.Tk.__init__


def _tk_init(self, *a, **k):
    _Tk_init(self, *a, **k)
    _light(self)


tkinter.Tk.__init__ = _tk_init
sys.argv = [main]
runpy.run_path(main, run_name="__main__")
