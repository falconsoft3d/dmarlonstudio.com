part of 'tk_examples.dart';

// ------------------------------------------------------- escáner de puertos
/// Escáner de puertos TCP (conexión completa) con la biblioteca estándar:
/// varios hilos en segundo plano, una cola y `after` para no bloquear la
/// ventana, nombre del servicio, la respuesta (banner) de cada uno y CSV.
TkExample tkUtilPortScanner(String Function(String) t) {
  final app = t(markTr('Escáner de puertos'));
  TkWidget caption(String name, int x, int w, String text) =>
      _w('Label', name, x, 76, w, 24, _label(text));
  TkWidget button(String name, int x, int w, String text) => _w(
    'Button',
    name,
    x,
    136,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final presets = [
    t(markTr('Comunes')),
    '1–1024',
    t(markTr('Todos (1–65535)')),
    t(markTr('Personalizado')),
  ];
  final design =
      TkDesign(
          width: 900,
          height: 640,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 12, 560, 32, _title(app)),
          _w('Label', 'Warning', 16, 44, 868, 24, {
            ..._label(
              t(
                markTr(
                  'Escanee solo equipos propios o con permiso: escanear redes ajenas puede ser ilegal.',
                ),
              ),
            ),
            'fg': '#b45309',
            'font_bold': true,
          }),
          caption('LblHost', 16, 220, t(markTr('Equipo (nombre o IP)'))),
          caption('LblPreset', 248, 150, t(markTr('Puertos'))),
          caption(
            'LblPorts',
            408,
            250,
            t(markTr('Lista o rangos (p. ej. 20-25,80,443)')),
          ),
          caption('LblTimeout', 668, 110, t(markTr('Espera (s)'))),
          caption('LblWorkers', 788, 96, t(markTr('Hilos'))),
          _w(
            'Entry',
            'Host',
            16,
            100,
            220,
            28,
            {'text': '127.0.0.1'},
            {'enter_key': 'Host_return'},
          ),
          _w(
            'Combobox',
            'Preset',
            248,
            100,
            150,
            28,
            {'state': 'readonly', 'items': presets.join('\n')},
            {'select': 'Preset_select'},
          ),
          _w('Entry', 'Ports', 408, 100, 250, 28, {}, {
            'key_up': 'Ports_key_up',
            'enter_key': 'Host_return',
          }),
          _w('Entry', 'Timeout', 668, 100, 104, 28, {'text': '0.5'}),
          _w('Entry', 'Workers', 788, 100, 96, 28, {'text': '100'}),
          _w(
            'Checkbutton',
            'ShowClosed',
            16,
            140,
            240,
            24,
            {'text': t(markTr('Mostrar también los cerrados'))},
            {'command': 'ShowClosed_click'},
          ),
          _w('Checkbutton', 'Banner', 264, 140, 240, 24, {
            'text': t(markTr('Leer la respuesta (banner)')),
            'checked': true,
          }),
          button('BtnScan', 540, 104, t(markTr('Escanear'))),
          button('BtnStop', 652, 104, t(markTr('Detener'))),
          button('BtnExport', 764, 120, t(markTr('Exportar CSV…'))),
          _w('Progressbar', 'Progress', 16, 180, 868, 10),
          _w('Label', 'Summary', 16, 196, 868, 24, {
            ..._label(''),
            'fg': '#5f6672',
          }),
          _w('Treeview', 'Results', 16, 224, 868, 384, {
            'columns': [
              'port|${t(markTr('Puerto'))}|70',
              'state|${t(markTr('Estado'))}|90',
              'service|${t(markTr('Servicio'))}|130',
              'banner|${t(markTr('Respuesta del servicio'))}|560',
            ].join('\n'),
          }),
          _w('SaveDialog', 'ExportFile', 852, 12, 32, 32, {
            'title': t(markTr('Exportar los resultados')),
            'filter': 'CSV|*.csv',
            'defaultext': '.csv',
            'filename': t(markTr('puertos.csv')),
          }),
          _w('StatusBar', 'Status', 0, 616, 900, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import bisect
import concurrent.futures
import csv
import errno
import os
import queue
import re
import socket
import threading
import time
from tkinter import messagebox, ttk

APP = ${_py(app)}
PRESETS = ${_py(presets[0])}, ${_py(presets[1])}, ${_py(presets[2])}, ${_py(presets[3])}
OPEN = ${_py(t(markTr('abierto')))}
CLOSED = ${_py(t(markTr('cerrado')))}
FILTERED = ${_py(t(markTr('filtrado')))}
BAD_HOST = ${_py(t(markTr('Escriba el equipo que quiere escanear, por ejemplo 127.0.0.1.')))}
NO_PORTS = ${_py(t(markTr('Escriba los puertos: números del 1 al 65535 o rangos, por ejemplo 20-25,80,443.')))}
BAD_PORT = ${_py(t(markTr('«{0}» no es un puerto ni un rango válido.')))}
OUT_OF_RANGE = ${_py(t(markTr('«{0}» se sale del rango de puertos (1–65535).')))}
BAD_TIMEOUT = ${_py(t(markTr('La espera debe ser un número de segundos entre 0,05 y 10.')))}
BAD_WORKERS = ${_py(t(markTr('Los hilos deben ser un número entero entre 1 y 1000.')))}
NOT_FOUND = ${_py(t(markTr('No se encuentra el equipo «{0}»: {1}')))}
RESOLVING = ${_py(t(markTr('Buscando la dirección de {0}…')))}
SCANNING = ${_py(t(markTr('Escaneando {0} ({1}): {2} puertos…')))}
FINISHED = ${_py(t(markTr('Terminado: {0} puertos abiertos en {1:.1f} s.')))}
STOPPED = ${_py(t(markTr('Detenido: {0} puertos abiertos de {1} revisados.')))}
SUMMARY = ${_py(t(markTr('{0}   ·   {1} abiertos   ·   {2} de {3} puertos   ·   {4:.1f} s')))}
TABLE_LIMIT = ${_py(t(markTr('la tabla muestra {0} de {1} cerrados; el CSV los lleva todos')))}
NOTHING = ${_py(t(markTr('No hay resultados que exportar.')))}
SAVED = ${_py(t(markTr('Resultados guardados en {0}.')))}
NOT_SAVED = ${_py(t(markTr('No se pudo guardar: {0}')))}
HEADERS = (
    ${_py(t(markTr('Equipo escaneado')))}, "IP", ${_py(t(markTr('Puerto')))}, ${_py(t(markTr('Estado')))},
    ${_py(t(markTr('Servicio')))}, ${_py(t(markTr('Respuesta del servicio')))},
)
'''
      r'''
# Los puertos más usados (servicios web, correo, bases de datos, escritorio
# remoto…) y el nombre de cada uno, por si el sistema no lo conoce.
SERVICES = {
    21: "ftp", 22: "ssh", 23: "telnet", 25: "smtp", 53: "dns", 80: "http",
    110: "pop3", 111: "rpcbind", 135: "msrpc", 139: "netbios-ssn",
    143: "imap", 389: "ldap", 443: "https", 445: "microsoft-ds",
    465: "smtps", 587: "submission", 631: "ipp", 993: "imaps", 995: "pop3s",
    1433: "ms-sql", 1521: "oracle", 1723: "pptp", 3000: "http-dev",
    3306: "mysql", 3389: "rdp", 5000: "http-alt", 5432: "postgresql",
    5900: "vnc", 6379: "redis", 8000: "http-alt", 8080: "http-proxy",
    8443: "https-alt", 8888: "http-alt", 9200: "elasticsearch",
    11211: "memcached", 27017: "mongodb",
}
COMMON = "21-23,25,53,80,110,111,135,139,143,389,443,445,465,587,993,995," \
    "1433,1521,1723,3000,3306,3389,5000,5432,5900,6379,8000,8080,8443,27017"
SPECS = (COMMON, "1-1024", "1-65535")
# A estos puertos (HTTP sin cifrar) se les pide la cabecera si no dicen nada.
HTTP_PORTS = {80, 3000, 5000, 8000, 8008, 8080, 8888}
REFUSED = {errno.ECONNREFUSED, 10061}  # 10061: WSAECONNREFUSED (Windows)
BANNER_WAIT = 0.8
MAX_OTHERS = 1000  # Cerrados que caben en la tabla.


def parse_ports(text):
    """«20-25,80,443» -> [20, 21, 22, 23, 24, 25, 80, 443].

    Acepta comas, puntos y coma o espacios entre partes; ValueError con un
    mensaje para el usuario si algo no vale."""
    parts = [part for part in re.split(r"[,;\s]+", text.strip()) if part]
    if not parts:
        raise ValueError(NO_PORTS)
    ports = set()
    for part in parts:
        bounds = part.split("-")
        if len(bounds) > 2 or not all(b.isdigit() for b in bounds):
            raise ValueError(BAD_PORT.format(part))
        low, high = int(bounds[0]), int(bounds[-1])
        if low > high:
            low, high = high, low
        if low < 1 or high > 65535:
            raise ValueError(OUT_OF_RANGE.format(part))
        ports.update(range(low, high + 1))
    return sorted(ports)


def parse_number(text, kind, low, high, message):
    try:
        value = kind(text.strip().replace(",", "."))
    except ValueError:
        raise ValueError(message) from None
    if not low <= value <= high:
        raise ValueError(message)
    return value


def resolve(host):
    """(familia, ip) de host: primero IPv4. OSError si no se encuentra."""
    infos = socket.getaddrinfo(host, None, 0, socket.SOCK_STREAM)
    infos.sort(key=lambda info: info[0] != socket.AF_INET)
    family, _, _, _, address = infos[0]
    return family, address[0]


_known = None


def system_services():
    """Puerto -> nombre de la tabla de servicios del sistema, leída una vez
    (socket.getservbyport es lento para miles de puertos)."""
    found = {}
    windows = os.path.join(os.environ.get("SystemRoot", r"C:\Windows"),
                           "System32", "drivers", "etc", "services")
    for path in ("/etc/services", windows):
        try:
            with open(path, encoding="utf-8", errors="replace") as source:
                for line in source:
                    fields = line.split("#", 1)[0].split()
                    if len(fields) < 2 or not fields[1].endswith("/tcp"):
                        continue
                    number = fields[1].split("/", 1)[0]
                    if number.isdigit():
                        found.setdefault(int(number), fields[0])
        except OSError:
            continue
        if found:
            break
    return found


def service_name(port):
    global _known
    if port in SERVICES:
        return SERVICES[port]
    if _known is None:
        _known = system_services()
    return _known.get(port, "")


def summarize(data):
    """Primera línea legible de la respuesta (y el servidor, si es HTTP)."""
    text = data.decode("utf-8", "replace")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return ""
    first = lines[0]
    if first.startswith("HTTP/"):
        for line in lines[1:]:
            if line.lower().startswith("server:"):
                first += "   ·   " + line.split(":", 1)[1].strip()
                break
    first = "".join(c if c.isprintable() else " " for c in first)
    return first[:120]


def grab_banner(sock, ip, port, wait):
    sock.settimeout(wait)
    data = b""
    try:
        data = sock.recv(512)
    except OSError:
        pass  # No dice nada por sí solo (socket.timeout es un OSError).
    if not data and port in HTTP_PORTS:
        try:
            sock.sendall(("HEAD / HTTP/1.0\r\nHost: %s\r\n\r\n" % ip).encode("ascii"))
            data = sock.recv(1024)
        except OSError:
            pass
    return summarize(data)


def probe(family, ip, port, timeout, banner=False):
    """(estado, respuesta) del puerto: "open", "closed" o "filtered"."""
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        code = sock.connect_ex((ip, port))
        if code == 0:
            text = grab_banner(sock, ip, port, min(timeout, BANNER_WAIT)) if banner else ""
            return "open", text
        return ("closed" if code in REFUSED else "filtered"), ""
    except OSError:
        return "filtered", ""
    finally:
        sock.close()


class Scan(threading.Thread):
    """Escaneo en segundo plano. Deja en la cola:
    ("resolved", ip), ("error", mensaje), ("port", puerto, estado, respuesta)
    y al final ("done", segundos, detenido)."""

    def __init__(self, host, ports, timeout, workers, banner):
        super().__init__(daemon=True)
        self.host = host
        self.ports = ports
        self.timeout = timeout
        self.workers = workers
        self.banner = banner
        self.out = queue.Queue()
        self.stop = threading.Event()

    def run(self):
        started = time.monotonic()
        try:
            family, ip = resolve(self.host)
        except (OSError, UnicodeError) as error:
            self.out.put(("error", NOT_FOUND.format(self.host, error)))
            return
        self.out.put(("resolved", ip))
        pending = set()
        ports = iter(self.ports)
        # Pocas tareas en vuelo a la vez: Detener responde enseguida.
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.workers) as pool:
            while not self.stop.is_set():
                while len(pending) < self.workers * 2:
                    port = next(ports, None)
                    if port is None:
                        break
                    pending.add(pool.submit(self.one, family, ip, port))
                if not pending:
                    break
                done, pending = concurrent.futures.wait(
                    pending, timeout=0.2, return_when=concurrent.futures.FIRST_COMPLETED
                )
                for future in done:
                    self.out.put(("port",) + future.result())
        self.out.put(("done", time.monotonic() - started, self.stop.is_set()))

    def one(self, family, ip, port):
        if self.stop.is_set():
            return port, "skipped", ""
        state, text = probe(family, ip, port, self.timeout, self.banner)
        return port, state, text


class Form1(FormDesign):
    def form_create(self):
        self.scan = None
        self.job = None
        self.host = self.ip = ""
        self.results = {}  # puerto -> (estado, servicio, respuesta)
        self.shown = []  # puertos de la tabla, en orden
        self.checked = self.opened = self.others = 0
        self.started = self.elapsed = 0.0
        self.Preset.current(0)
        self.Ports_var.set(SPECS[0])
        # Tabla clara también con el modo oscuro del sistema.
        style = ttk.Style(self.root)
        style.configure("Scan.Treeview", background="#ffffff", fieldbackground="#ffffff",
                        foreground="#1b1d22", rowheight=22)
        style.configure("Scan.Treeview.Heading", foreground="#1b1d22")
        style.map("Scan.Treeview", background=[("selected", "#cfe0f7")],
                  foreground=[("selected", "#1b1d22")])
        self.Results.configure(style="Scan.Treeview")
        self.Results.tag_configure("open", background="#e3f4e8", foreground="#14532d")
        self.Results.tag_configure("closed", foreground="#8a9099")
        self.Results.tag_configure("filtered", foreground="#b0b5bd")
        self.set_running(False)
        self.Host.focus_set()
        self.Host.icursor("end")

    # ---------------------------------------------------------- opciones
    def Preset_select(self, event=None):
        index = self.Preset.current()
        if 0 <= index < len(SPECS):
            self.Ports_var.set(SPECS[index])

    def Ports_key_up(self, event=None):
        text = self.Ports_var.get().strip()
        self.Preset.current(SPECS.index(text) if text in SPECS else len(PRESETS) - 1)

    def options(self):
        """(equipo, puertos, espera, hilos) o ValueError y el campo culpable."""
        host = self.Host_var.get().strip()
        if not host:
            raise ValueError(BAD_HOST, self.Host)
        try:
            ports = parse_ports(self.Ports_var.get())
        except ValueError as error:
            raise ValueError(str(error), self.Ports) from None
        try:
            timeout = parse_number(self.Timeout_var.get(), float, 0.05, 10, BAD_TIMEOUT)
        except ValueError:
            raise ValueError(BAD_TIMEOUT, self.Timeout) from None
        try:
            workers = parse_number(self.Workers_var.get(), int, 1, 1000, BAD_WORKERS)
        except ValueError:
            raise ValueError(BAD_WORKERS, self.Workers) from None
        return host, ports, timeout, workers

    # ------------------------------------------------------------ escaneo
    def BtnScan_click(self):
        if self.scan is not None:
            return
        try:
            host, ports, timeout, workers = self.options()
        except ValueError as error:
            message, field = error.args
            self.Status.set(message, icon="warning")
            messagebox.showwarning(APP, message, parent=self.root)
            field.focus_set()
            return
        self.results = {}
        self.shown = []
        self.checked = self.opened = self.others = 0
        self.host = self.ip = host
        self.Results.delete(*self.Results.get_children())
        self.Progress.configure(maximum=len(ports), value=0)
        self.scan = Scan(host, ports, timeout, workers, bool(self.Banner_var.get()))
        self.started = time.monotonic()
        self.set_running(True)
        self.Status.set(RESOLVING.format(host), icon="refresh")
        self.scan.start()
        self.job = self.root.after(60, self.poll)

    def Host_return(self, event=None):
        self.BtnScan_click()

    def BtnStop_click(self):
        if self.scan is not None:
            self.scan.stop.set()
            self.BtnStop.configure(state="disabled")

    def poll(self):
        """Lee lo que ha dejado el hilo del escaneo (sin bloquear)."""
        self.job = None
        scan = self.scan
        if scan is None:
            return
        budget = time.monotonic() + 0.04  # La ventana nunca espera más.
        while time.monotonic() < budget:
            try:
                item = scan.out.get_nowait()
            except queue.Empty:
                break
            kind = item[0]
            if kind == "port":
                self.record(*item[1:])
            elif kind == "resolved":
                self.ip = item[1]
                self.Status.set(SCANNING.format(scan.host, item[1], len(scan.ports)), icon="refresh")
            elif kind == "error":
                self.scan = None
                self.set_running(False)
                self.Status.set(item[1], icon="warning")
                messagebox.showwarning(APP, item[1], parent=self.root)
                return
            elif kind == "done":
                return self.finish(item[1], item[2])
        self.show_summary(time.monotonic() - self.started)
        self.job = self.root.after(80, self.poll)

    def record(self, port, state, text):
        if state == "skipped":
            return
        self.checked += 1
        if state == "open":
            self.opened += 1
        self.results[port] = (state, service_name(port), text)
        self.show_row(port)

    def show_row(self, port):
        """Añade el puerto a la tabla, en orden. Los cerrados, como mucho
        MAX_OTHERS: miles de filas harían lenta la tabla (el CSV los lleva)."""
        state, service, text = self.results[port]
        if state != "open":
            if not self.ShowClosed_var.get():
                return
            if self.others >= MAX_OTHERS:
                return
            self.others += 1
        index = bisect.bisect(self.shown, port)
        self.shown.insert(index, port)
        label = {"open": OPEN, "closed": CLOSED}.get(state, FILTERED)
        self.Results.insert(
            "", index, iid=str(port), values=(port, label, service, text), tags=(state,)
        )

    def open_count(self):
        return self.opened

    def show_summary(self, seconds):
        self.Progress.configure(value=self.checked)
        total = len(self.scan.ports) if self.scan else int(float(self.Progress.cget("maximum")))
        text = SUMMARY.format(self.ip, self.opened, self.checked, total, seconds)
        others = self.checked - self.opened
        if self.ShowClosed_var.get() and others > self.others:
            text += "   ·   " + TABLE_LIMIT.format(self.others, others)
        self.Summary.configure(text=text)

    def finish(self, seconds, stopped):
        self.elapsed = seconds
        self.show_summary(seconds)
        self.scan = None
        self.set_running(False)
        if stopped:
            self.Status.set(STOPPED.format(self.open_count(), self.checked), icon="warning")
        else:
            self.Status.set(FINISHED.format(self.open_count(), seconds), icon="check")

    def set_running(self, running):
        self.BtnScan.configure(state="disabled" if running else "normal")
        self.BtnStop.configure(state="normal" if running else "disabled")
        self.BtnExport.configure(state="disabled" if running else "normal")
        for field in (self.Host, self.Ports, self.Timeout, self.Workers):
            field.configure(state="readonly" if running else "normal")
        self.Preset.configure(state="disabled" if running else "readonly")

    def ShowClosed_click(self):
        self.shown = []
        self.others = 0
        self.Results.delete(*self.Results.get_children())
        for port in sorted(self.results):
            self.show_row(port)
        if self.scan is None and self.results:
            self.show_summary(self.elapsed)

    # ---------------------------------------------------------- exportar
    def BtnExport_click(self):
        closed = bool(self.ShowClosed_var.get())
        ports = [p for p in sorted(self.results) if closed or self.results[p][0] == "open"]
        if not ports:
            self.Status.set(NOTHING, icon="info")
            return
        try:
            path = self.ExportFile.execute()
            if not path:
                return
            with open(path, "w", newline="", encoding="utf-8-sig") as target:
                writer = csv.writer(target)
                writer.writerow(HEADERS)
                for port in ports:
                    state, service, text = self.results[port]
                    label = {"open": OPEN, "closed": CLOSED}.get(state, FILTERED)
                    writer.writerow((self.host, self.ip, port, label, service, text))
        except OSError as error:
            messagebox.showerror(APP, NOT_SAVED.format(error), parent=self.root)
            return
        self.Status.set(SAVED.format(path), icon="check")

    def form_close(self, *args):
        if self.scan is not None:
            self.scan.stop.set()
        if self.job is not None:
            self.root.after_cancel(self.job)
        self.root.destroy()
''';
  return TkExample(
    'port_scanner',
    app,
    t(
      markTr(
        'Escanea los puertos TCP de un equipo con varios hilos en segundo plano: servicio y respuesta de cada uno, progreso, Detener y exportación a CSV.',
      ),
    ),
    design,
    code,
  );
}
