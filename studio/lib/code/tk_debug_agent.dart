/// Agente del depurador: el estudio lo escribe en `build/dms_debug.py` y lo
/// lanza en lugar del programa. Ejecuta el archivo generado con un trazador
/// propio (solo la biblioteca estándar) y habla con el estudio por un socket
/// local: líneas JSON, con el token de esta ejecución.
///
/// Solo se detiene en las líneas del código del usuario (`--start` a `--end`
/// del archivo generado): el código que genera el diseño no se depura.
const tkDebugAgentPython =
    r'''"""Depurador de DMarlon Studio (no lo edite: se escribe en cada ejecución)."""
import collections
import gc
import json
import os
import queue
import reprlib
import runpy
import socket
import sys
import threading
import time
import traceback

IGNORED = (StopIteration, StopAsyncIteration, GeneratorExit, KeyboardInterrupt, SystemExit)
RESUME = {"continue": "run", "into": "into", "over": "over", "out": "out", "to": "to"}


class Agent:
    def __init__(self, target, start, end, debug=True):
        self.target = os.path.normcase(os.path.abspath(target))
        self.start, self.end = start, end
        self.debug = debug
        self.breaks = {}
        self.hits = collections.Counter()
        self.mode = "run"
        self.step_frame = None
        self.run_to = None
        self.pause_req = False
        self.exc_mode = "uncaught"
        self.stop_lock = threading.Lock()
        self.commands = queue.Queue()
        self.stopped = None
        self.refs = {}
        self.history = collections.deque(maxlen=2000)
        self.flow = collections.deque(maxlen=2000)
        self.stats = {}
        self.line_hits = collections.Counter()
        self.seen = collections.deque(maxlen=64)
        self.codes = {}
        self.local = threading.local()
        self.paused_total = 0.0
        self.alive = True
        self.started = threading.Event()
        self.wlock = threading.Lock()
        self.sock = None
        self.repr = reprlib.Repr()
        self.repr.maxstring = self.repr.maxother = 160
        self.repr.maxlist = self.repr.maxtuple = self.repr.maxdict = self.repr.maxset = 12
        self.repr.maxlevel = 3

    # ------------------------------------------------------------- canal
    def connect(self, port, token):
        self.sock = socket.create_connection(("127.0.0.1", port), timeout=20)
        self.sock.settimeout(None)
        self.send({"ev": "hello", "token": token, "pid": os.getpid(),
                   "python": sys.version.split()[0]})
        threading.Thread(target=self.reader, name="dms-debug", daemon=True).start()
        if not self.started.wait(30):
            raise SystemExit("El estudio no respondió al depurador.")

    def send(self, msg):
        data = (json.dumps(msg, default=str) + "\n").encode("utf-8")
        with self.wlock:
            try:
                self.sock.sendall(data)
            except OSError:
                self.detach()

    def reply(self, cmd, result):
        self.send(dict(result, ev="result", id=cmd.get("id")))

    def detach(self):
        """Sin el estudio, el programa sigue sin detenerse."""
        self.alive = False
        self.started.set()
        self.commands.put({"cmd": "continue"})

    def reader(self):
        buf = b""
        while True:
            try:
                chunk = self.sock.recv(65536)
            except OSError:
                chunk = b""
            if not chunk:
                return self.detach()
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    cmd = json.loads(line.decode("utf-8"))
                except ValueError:
                    continue
                self.command(cmd)

    def command(self, cmd):
        kind = cmd.get("cmd")
        if kind == "breakpoints":
            self.breaks = {int(k): str(v or "") for k, v in (cmd.get("lines") or {}).items()}
        elif kind == "exceptions":
            self.exc_mode = cmd.get("mode") if cmd.get("mode") in ("never", "uncaught", "all") else "uncaught"
        elif kind == "start":
            self.started.set()
        elif kind == "pause":
            self.pause_req = True
        elif kind == "history":
            self.reply(cmd, {"ok": True, "items": list(self.history)[-int(cmd.get("limit") or 500):]})
        elif kind == "flow":
            self.reply(cmd, {"ok": True, "items": list(self.flow)[-int(cmd.get("limit") or 500):]})
        elif kind == "stats":
            self.reply(cmd, self.stats_result())
        elif kind == "objects":
            self.reply(cmd, self.objects_result())
        elif kind == "reset":
            self.stats.clear()
            self.line_hits.clear()
            self.history.clear()
            self.flow.clear()
            self.reply(cmd, {"ok": True})
        elif kind in RESUME or kind in ("evaluate", "vars"):
            if self.stopped is None:
                if kind in ("evaluate", "vars"):
                    self.reply(cmd, {"ok": False, "error": "running"})
                return
            self.commands.put(cmd)

    # ---------------------------------------------------------- trazador
    def user_code(self, code):
        mine = self.codes.get(code)
        if mine is None:
            mine = (os.path.normcase(os.path.abspath(code.co_filename)) == self.target and
                    (code.co_name == "<module>" or self.start <= code.co_firstlineno <= self.end))
            self.codes[code] = mine
        return mine

    def busy(self):
        return getattr(self.local, "busy", False)

    def trace(self, frame, event, arg):
        if not self.alive or self.busy() or not self.user_code(frame.f_code):
            return None
        if frame.f_code.co_name != "<module>":
            self.on_call(frame)
        return self.trace_local

    def trace_local(self, frame, event, arg):
        if not self.alive:
            return None
        if self.busy():
            return self.trace_local
        if event == "line":
            self.on_line(frame)
        elif event == "return":
            self.on_return(frame)
        elif event == "exception":
            self.on_exception(frame, arg)
        return self.trace_local

    def depth(self):
        return getattr(self.local, "depth", 0)

    def function(self, code):
        """Una función del usuario (no el cuerpo de una clase)."""
        return code.co_flags & 2 and self.start <= code.co_firstlineno <= self.end

    def on_call(self, frame):
        code = frame.f_code
        if not self.function(code):
            return
        d = self.depth()
        self.local.depth = d + 1
        stack = getattr(self.local, "stack", None)
        if stack is None:
            stack = self.local.stack = {}
        stack[id(frame)] = (time.perf_counter(), self.paused_total)
        self.flow.append(("call", round(time.time(), 3), threading.current_thread().name, d,
                          code.co_name, frame.f_lineno, ""))

    def on_return(self, frame):
        code = frame.f_code
        if self.mode in ("over", "out") and frame is self.step_frame:
            self.mode, self.step_frame = "into", None
        if not self.function(code):
            return
        began = getattr(self.local, "stack", {}).pop(id(frame), None)
        self.local.depth = max(0, self.depth() - 1)
        if began is None:
            return
        spent = time.perf_counter() - began[0] - (self.paused_total - began[1])
        row = self.stats.setdefault(code, [code.co_name, code.co_firstlineno, 0, 0.0, 0.0])
        row[2] += 1
        row[3] += spent
        row[4] = max(row[4], spent)
        self.flow.append(("return", round(time.time(), 3), threading.current_thread().name,
                          self.depth(), code.co_name, frame.f_lineno, "%.3f" % (spent * 1000)))

    def on_line(self, frame):
        line = frame.f_lineno
        if not self.start <= line <= self.end:
            return
        self.history.append((round(time.time(), 3), threading.current_thread().name,
                             frame.f_code.co_name, line))
        self.line_hits[line] += 1
        reason = note = None
        if self.pause_req:
            reason = "pause"
        elif self.mode == "into":
            reason = "step"
        elif self.mode == "over" and frame is self.step_frame:
            reason = "step"
        elif self.mode == "to" and line == self.run_to:
            reason = "cursor"
        if reason is None and line in self.breaks:
            self.hits[line] += 1
            condition = self.breaks[line]
            hit = True
            if condition:
                try:
                    hit = bool(eval(condition, frame.f_globals, frame.f_locals))
                except Exception as e:
                    note = "%s: %s" % (type(e).__name__, e)
            if hit:
                reason = "breakpoint"
        if reason:
            self.stop(frame, reason, note=note)

    def on_exception(self, frame, arg):
        if self.exc_mode != "all":
            return
        kind, exc, tb = arg
        if issubclass(kind, IGNORED) or id(exc) in self.seen:
            return
        self.seen.append(id(exc))
        if self.start <= frame.f_lineno <= self.end:
            self.stop(frame, "exception", exception=self.exc_text(exc, tb))

    @staticmethod
    def exc_text(exc, tb=None):
        text = "".join(traceback.format_exception_only(type(exc), exc)).strip()
        return {"text": text, "type": type(exc).__name__,
                "traceback": "".join(traceback.format_exception(type(exc), exc, tb)) if tb else text}

    def post_mortem(self, exc, tb):
        """Una excepción que nadie controló (en un evento o al terminar)."""
        if not self.alive or self.exc_mode == "never" or self.busy():
            return
        if isinstance(exc, IGNORED) or id(exc) in self.seen:
            return
        self.seen.append(id(exc))
        frames, lines = [], []
        while tb is not None:
            frames.append(tb.tb_frame)
            lines.append(tb.tb_lineno)
            tb = tb.tb_next
        mine = [i for i, f in enumerate(frames) if self.user_code(f.f_code) and self.start <= lines[i] <= self.end]
        if not mine:
            return
        deepest = mine[-1]
        chain = list(zip(frames[:deepest + 1], lines[:deepest + 1]))[::-1]
        outer = frames[0].f_back
        while outer is not None and len(chain) < 60:
            chain.append((outer, outer.f_lineno))
            outer = outer.f_back
        self.stop(None, "exception", exception=self.exc_text(exc, exc.__traceback__), chain=chain)

    # ------------------------------------------------------------ parada
    def stop(self, frame, reason, note=None, exception=None, chain=None):
        self.local.busy = True
        try:
            with self.stop_lock:
                if not self.alive:
                    return
                began = time.perf_counter()
                self.pause_req = False
                self.mode, self.step_frame, self.run_to = "run", None, None
                if chain is None:
                    chain, f = [], frame
                    while f is not None and len(chain) < 60:
                        chain.append((f, f.f_lineno))
                        f = f.f_back
                # Sin los marcos del propio depurador ni de runpy.
                chain = [(f, line) for f, line in chain if not self.internal(f)]
                self.stopped = [f for f, _ in chain]
                self.refs = {}
                self.send({
                    "ev": "stopped", "reason": reason, "note": note, "exception": exception,
                    "thread": threading.current_thread().name,
                    "frames": [self.describe(f, line) for f, line in chain],
                })
                while self.alive:
                    cmd = self.commands.get()
                    kind = cmd.get("cmd")
                    if kind in RESUME:
                        self.mode = RESUME[kind]
                        if kind in ("over", "out"):
                            if frame is None:
                                # Tras una excepción, el marco ya terminó.
                                self.mode = "into"
                            else:
                                self.step_frame = self.stopped[0]
                        if kind == "to":
                            self.run_to = int(cmd.get("line") or 0)
                        break
                    if kind == "evaluate":
                        self.reply(cmd, self.evaluate(cmd))
                    elif kind == "vars":
                        self.reply(cmd, self.variables(cmd))
                self.stopped = None
                self.refs = {}
                self.paused_total += time.perf_counter() - began
                self.send({"ev": "running"})
        finally:
            self.local.busy = False

    @staticmethod
    def internal(f):
        name = os.path.basename(f.f_code.co_filename)
        return name in ("dms_debug.py", "runpy.py", "<frozen runpy>")

    def describe(self, f, line):
        code = f.f_code
        user = self.user_code(code) and self.start <= line <= self.end
        return {"func": code.co_name, "file": os.path.basename(code.co_filename), "line": line,
                "user": bool(user)}

    def frame(self, cmd):
        index = int(cmd.get("frame") or 0)
        if not 0 <= index < len(self.stopped):
            raise IndexError("frame")
        return self.stopped[index]

    def evaluate(self, cmd):
        expr = str(cmd.get("expr") or "").strip()
        if not expr:
            return {"ok": False, "error": "empty"}
        try:
            f = self.frame(cmd)
            try:
                code = compile(expr, "<evaluar>", "eval")
            except SyntaxError:
                code = compile(expr, "<evaluar>", "exec")
                scope = f.f_locals
                exec(code, f.f_globals, scope)
                if sys.version_info < (3, 13) and isinstance(scope, dict):
                    try:
                        import ctypes
                        ctypes.pythonapi.PyFrame_LocalsToFast(ctypes.py_object(f), ctypes.c_int(0))
                    except Exception:
                        pass
                return {"ok": True, "name": expr, "type": "", "value": "", "ref": None}
            value = eval(code, f.f_globals, f.f_locals)
            return dict(self.value(expr, value), ok=True)
        except Exception as e:
            return {"ok": False, "error": "%s: %s" % (type(e).__name__, e)}

    @staticmethod
    def plain(value):
        return not (isinstance(value, (type, type(sys), type(len))) or callable(value))

    def expandable(self, value):
        if isinstance(value, (str, bytes, int, float, complex, bool, type(None))):
            return False
        if isinstance(value, (dict, list, tuple, set, frozenset)):
            return len(value) > 0
        return hasattr(value, "__dict__") or hasattr(type(value), "__slots__")

    def value(self, name, value):
        try:
            text = self.repr.repr(value)
        except Exception as e:
            text = "<repr: %s>" % e
        ref = None
        if self.expandable(value):
            ref = "O%d" % (len(self.refs) + 1)
            self.refs[ref] = value
        return {"name": str(name), "type": type(value).__name__, "value": text, "ref": ref}

    def children(self, value):
        if isinstance(value, dict):
            return [(self.repr.repr(k), v) for k, v in list(value.items())[:300]]
        if isinstance(value, (list, tuple)):
            return [("[%d]" % i, v) for i, v in enumerate(value[:300])]
        if isinstance(value, (set, frozenset)):
            return [("{%d}" % i, v) for i, v in enumerate(sorted(value, key=repr)[:300])]
        out = []
        try:
            out = [(k, v) for k, v in sorted(vars(value).items()) if not k.startswith("__")]
        except TypeError:
            pass
        for k in getattr(type(value), "__slots__", ()):
            if hasattr(value, k):
                out.append((k, getattr(value, k)))
        return out[:300]

    def variables(self, cmd):
        ref = str(cmd.get("ref") or "")
        try:
            if ref[:1] in ("L", "G"):
                f = self.frame({"frame": ref[1:]})
                if ref[0] == "L":
                    items = sorted(f.f_locals.items()) if f.f_code.co_name != "<module>" else []
                else:
                    items = sorted((k, v) for k, v in f.f_globals.items()
                                   if not k.startswith("_") and self.plain(v))
            elif ref in self.refs:
                items = self.children(self.refs[ref])
            else:
                return {"ok": False, "error": "ref"}
            return {"ok": True, "items": [self.value(k, v) for k, v in items]}
        except Exception as e:
            return {"ok": False, "error": "%s: %s" % (type(e).__name__, e)}

    # ------------------------------------------------------ rendimiento
    def stats_result(self):
        rows = sorted(([r[0], r[1], r[2], round(r[3] * 1000, 3), round(r[4] * 1000, 3)]
                       for r in list(self.stats.values())), key=lambda r: -r[3])
        hot = self.line_hits.most_common(30)
        return {"ok": True, "functions": rows[:200], "lines": hot}

    def objects_result(self):
        counts = collections.Counter()
        widgets = 0
        tk = sys.modules.get("tkinter")
        for o in gc.get_objects():
            t = type(o)
            if getattr(t, "__module__", "") == "__main__":
                counts[t.__name__] += 1
            elif tk is not None and isinstance(o, tk.Misc):
                widgets += 1
        rows = counts.most_common(40)
        if widgets:
            rows.append(("tkinter", widgets))
        return {"ok": True, "items": rows}


def run_tests(agent, directory):
    import unittest

    class Result(unittest.TextTestResult):
        def report(self, test, status, message=""):
            agent.send({"ev": "test", "name": test.id(), "status": status, "message": message})

        def addSuccess(self, test):
            super().addSuccess(test)
            self.report(test, "ok")

        def addFailure(self, test, err):
            super().addFailure(test, err)
            self.report(test, "fail", self._exc_info_to_string(err, test))

        def addError(self, test, err):
            super().addError(test, err)
            self.report(test, "error", self._exc_info_to_string(err, test))

        def addSkip(self, test, reason):
            super().addSkip(test, reason)
            self.report(test, "skip", reason)

        def addExpectedFailure(self, test, err):
            super().addExpectedFailure(test, err)
            self.report(test, "ok", "expected failure")

        def addUnexpectedSuccess(self, test):
            super().addUnexpectedSuccess(test)
            self.report(test, "fail", "unexpected success")

    sys.path.insert(0, os.path.dirname(agent.target))
    suite = unittest.defaultTestLoader.discover(directory, pattern="test*.py", top_level_dir=directory)
    result = unittest.TextTestRunner(stream=sys.stdout, verbosity=2, resultclass=Result).run(suite)
    agent.send({"ev": "tests", "run": result.testsRun, "failures": len(result.failures),
                "errors": len(result.errors), "skipped": len(result.skipped)})
    return result.wasSuccessful()


def main():
    args = sys.argv[1:]
    opts = {"--tests": None}
    while args and args[0].startswith("--"):
        key = args.pop(0)
        if key == "--nodebug":
            opts[key] = True
        else:
            opts[key] = args.pop(0)
    agent = Agent(opts["--target"], int(opts["--start"]), int(opts["--end"]),
                  debug=not opts.get("--nodebug"))
    agent.connect(int(os.environ["DMSTUDIO_DEBUG_PORT"]), os.environ["DMSTUDIO_DEBUG_TOKEN"])
    sys.dmstudio_post_mortem = agent.post_mortem
    previous = sys.excepthook
    sys.excepthook = lambda kind, exc, tb: (agent.post_mortem(exc, tb), previous(kind, exc, tb))
    threading.excepthook = lambda a: (agent.post_mortem(a.exc_value, a.exc_traceback),
                                      threading.__excepthook__(a))
    try:
        import tkinter
        report = tkinter.Tk.report_callback_exception

        def report_callback(root, kind, exc, tb):
            agent.post_mortem(exc, tb)
            return report(root, kind, exc, tb)

        tkinter.Tk.report_callback_exception = report_callback
    except Exception:
        pass
    code = 0
    if agent.debug:
        threading.settrace(agent.trace)
        sys.settrace(agent.trace)
    try:
        if opts["--tests"]:
            code = 0 if run_tests(agent, opts["--tests"]) else 1
        else:
            sys.argv = [opts["--target"]]
            runpy.run_path(opts["--target"], run_name="__main__")
    except SystemExit as e:
        code = e.code if isinstance(e.code, int) else (0 if e.code is None else 1)
    except BaseException as e:
        agent.post_mortem(e, e.__traceback__)
        traceback.print_exc()
        code = 1
    finally:
        sys.settrace(None)
        threading.settrace(None)
        agent.send({"ev": "exit", "code": code})
    sys.stdout.flush()
    os._exit(code)


if __name__ == "__main__":
    main()
''';
