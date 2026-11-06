part of 'tk_examples.dart';

// --------------------------------------------------- seguimiento de trenes
/// Alertas de proximidad y gráfico de seguimiento (malla) con los datos
/// abiertos de Renfe: posiciones GTFS-Realtime en JSON cada 20 s y horarios
/// GTFS descargados una vez. Sin conexión, una red simulada con retrasos e
/// incidencias. Es una demo educativa, no un sistema de seguridad.
TkExample tkUtilTrainMonitor(String Function(String) t) {
  const muted = '#5f6672';
  const noteBg = '#fff4dc', noteFg = '#6b4a00';
  final app = t(markTr('Seguimiento de trenes'));
  TkWidget label(String name, int x, int y, int w, String text) =>
      _w('Label', name, x, y, w, 24, {..._label(text), 'bg': _paper});
  TkWidget combo(String name, int x, int y, int w) => _w(
    'Combobox',
    name,
    x,
    y,
    w,
    28,
    {'state': 'readonly'},
    {'select': '${name}_select'},
  );
  final design =
      TkDesign(
          width: 1100,
          height: 720,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 16, 8, 300, 30, {
            ..._title(app, size: 17),
            'bg': _paper,
          }),
          _w(
            'Radiobutton',
            'SrcLive',
            324,
            12,
            200,
            24,
            {
              'text': t(markTr('Datos en directo (Renfe)')),
              'group': 'Source',
              'value': 'live',
              'checked': true,
              'bg': _paper,
            },
            {'command': 'Source_change'},
          ),
          _w(
            'Radiobutton',
            'SrcSim',
            528,
            12,
            112,
            24,
            {
              'text': t(markTr('Simulación')),
              'group': 'Source',
              'value': 'sim',
              'bg': _paper,
            },
            {'command': 'Source_change'},
          ),
          _w('Label', 'Banner', 648, 10, 300, 28, {
            'text': '',
            'anchor': 'center',
            'bg': _paper,
            'fg': '#1b1d22',
            'font_bold': true,
          }),
          _w(
            'Button',
            'BtnHelp',
            956,
            10,
            128,
            28,
            {'text': t(markTr('¿Cómo funciona?'))},
            {'command': 'BtnHelp_click'},
          ),
          _w('Frame', 'NoteBox', 16, 44, 1068, 38, {
            'bg': noteBg,
            'relief': 'solid',
            'bd': 1,
          }),
          _w('Label', 'Note', 8, 2, 1050, 32, {
            ..._label(
              t(
                markTr(
                  'Demo educativa con datos públicos, que pueden llegar con retraso o incompletos. No es un sistema de seguridad: la separación real de los trenes la garantizan la señalización (ASFA, ERTMS) y los operadores.',
                ),
              ),
            ),
            'bg': noteBg,
            'fg': noteFg,
            'font_size': 10,
            'justify': 'left',
            'wraplength': 1040,
          })..parent = 'NoteBox',
          label('LblNucleo', 16, 90, 54, t(markTr('Núcleo'))),
          combo('Nucleo', 70, 88, 160),
          label('LblLine', 240, 90, 42, t(markTr('Línea'))),
          combo('LineBox', 282, 88, 250),
          label('LblWarn', 542, 90, 122, t(markTr('Aviso a menos de'))),
          combo('WarnKm', 664, 88, 76),
          label('LblOr', 744, 90, 16, t(markTr('o'))),
          combo('WarnMin', 762, 88, 78),
          label('LblSpeed', 850, 90, 54, t(markTr('Ritmo'))),
          combo('Speed', 904, 88, 64),
          _w(
            'Checkbutton',
            'Sound',
            980,
            90,
            104,
            24,
            {'text': t(markTr('Sonido')), 'bg': _paper},
            {'command': 'Sound_toggle'},
          ),
          _w('Progressbar', 'Loading', 16, 120, 1068, 5, {'maximum': 100}),
          _w('Canvas', 'Graph', 16, 130, 660, 282, {'bg': '#ffffff'}),
          _w('Canvas', 'Map', 686, 130, 398, 282, {'bg': '#fbfcfd'}),
          _w('Label', 'LblTrains', 16, 418, 660, 22, {
            ..._label(t(markTr('Trenes de la línea'))),
            'bg': _paper,
            'font_bold': true,
          }),
          _w('Label', 'LblAlerts', 686, 418, 398, 22, {
            ..._label(t(markTr('Alertas de proximidad'))),
            'bg': _paper,
            'font_bold': true,
          }),
          _w(
            'Treeview',
            'Trains',
            16,
            442,
            660,
            222,
            {
              'columns': [
                'id|${t(markTr('Tren'))}|70',
                'dest|${t(markTr('Hacia'))}|150',
                'next|${t(markTr('Próxima parada'))}|172',
                'delay|${t(markTr('Retraso'))}|70',
                'speed|${t(markTr('Velocidad'))}|78',
                'state|${t(markTr('Estado'))}|100',
              ].join('\n'),
            },
            {'select': 'Trains_select'},
          ),
          _w('Treeview', 'Alerts', 686, 442, 398, 222, {
            'columns': [
              'time|${t(markTr('Hora'))}|60',
              'level|${t(markTr('Nivel'))}|50',
              'line|${t(markTr('Línea'))}|42',
              'trains|${t(markTr('Trenes'))}|112',
              'gap|${t(markTr('Separación'))}|118',
            ].join('\n'),
          }),
          _w('Label', 'Attrib', 16, 670, 1068, 20, {
            ..._label(''),
            'bg': _paper,
            'fg': muted,
            'font_size': 9,
          }),
          _w(
            'Timer',
            'Timer1',
            1060,
            130,
            32,
            32,
            {'interval': 1000, 'enabled': false},
            {'command': 'Timer1_timer'},
          ),
          _w('StatusBar', 'Status', 0, 696, 1100, 24, {
            'text': '',
            'icon': 'info',
          }),
        ]);
  final code =
      '''import bisect
import collections
import csv
import datetime
import json
import math
import os
import queue
import random
import re
import ssl
import sys
import threading
import time
import urllib.request
import zipfile
from tkinter import messagebox, ttk

APP = ${_py(app)}
LIVE, SIM = "live", "sim"
# Núcleos de Cercanías y Rodalies del GTFS de Renfe (los dos primeros
# dígitos de cada ruta, viaje y servicio).
NUCLEOS = [
    ("10", "Madrid"), ("51", "Rodalies de Catalunya"), ("40", "València"),
    ("30", "Sevilla"), ("60", "Bilbao"), ("20", "Asturias"), ("32", "Málaga"),
    ("31", "Cádiz"), ("41", "Murcia/Alicante"), ("61", "San Sebastián"),
    ("62", "Santander"), ("70", "Zaragoza"), ("45", "Cartagena"),
    ("46", "Ferrol"), ("47", "León"),
]
SIM_NAME = ${_py(t(markTr('Red simulada')))}
NORMAL = ${_py(t(markTr('Normal')))}
WARNING = ${_py(t(markTr('Aviso')))}
ALERT = ${_py(t(markTr('Alerta')))}
STOPPED = ${_py(t(markTr('Detenido')))}
AT_STATION = ${_py(t(markTr('En estación')))}
OFF_TRACK = ${_py(t(markTr('Fuera del trazado')))}
ON_TIME = ${_py(t(markTr('puntual')))}
PLATFORM = ${_py(t(markTr('vía {0}')))}
NOW = ${_py(t(markTr('ahora')))}
TRAIN = ${_py(t(markTr('Tren {0}')))}
TOWARDS = ${_py(t(markTr('hacia {0}')))}
DELAY_SPEED = ${_py(t(markTr('Retraso: {0} · {1}')))}
GRAPH_TITLE = ${_py(t(markTr('Gráfico de seguimiento · {0}')))}
MAP_TITLE = ${_py(t(markTr('Mapa de la línea · {0}')))}
SCHEDULED = ${_py(t(markTr('horario previsto')))}
GATHERING = ${_py(t(markTr('Recogiendo posiciones: el recorrido real aparece con cada lectura (cada 20 s).')))}
LOADING = ${_py(t(markTr('Cargando…')))}
NO_LINE = ${_py(t(markTr('Elija una línea.')))}
TRAINS_OF = ${_py(t(markTr('Trenes de la línea {0}: {1}')))}
STOPPED_FOR = ${_py(t(markTr('parado {0}')))}
BANNER_NONE = ${_py(t(markTr('Sin alertas activas')))}
BANNER = ${_py(t(markTr('Alertas: {0} · Avisos: {1}')))}
NEW_ALERT = ${_py(t(markTr('{0} en la {1}: {2}')))}
NEW_STOP = ${_py(t(markTr('{0} en la {1}: tren {2} parado {3} fuera de una estación')))}
CONNECTING = ${_py(t(markTr('Conectando con Renfe…')))}
DOWNLOADING = ${_py(t(markTr('Descargando los horarios de Cercanías (solo la primera vez): {0} de {1}')))}
READING = ${_py(t(markTr('Leyendo los horarios de {0}…')))}
LIVE_OK = ${_py(t(markTr('Datos en directo: {0} trenes en {1}. Posiciones de las {2}; se actualizan cada 20 s.')))}
LIVE_FAIL = ${_py(t(markTr('No se pudo actualizar ({0}). Se reintenta en 20 s.')))}
OFFLINE = ${_py(t(markTr('Sin conexión con Renfe ({0}): se muestra la simulación.')))}
GTFS_FAIL = ${_py(t(markTr('No se pudieron leer los horarios de Renfe ({0}): se muestra la simulación.')))}
NO_SERVICE = ${_py(t(markTr('Los horarios no tienen servicio hoy en {0}.')))}
CANCELLED = ${_py(t(markTr('Cancelado')))}
BAD_ZIP = ${_py(t(markTr('El archivo descargado no es un GTFS.')))}
SIM_ON = ${_py(t(markTr('Simulación: estaciones reales; trenes, retrasos e incidencias inventados. Ritmo ×{0}.')))}
ATTRIB_LIVE = ${_py(t(markTr('Origen de los datos: Renfe Operadora (data.renfe.com, licencia CC BY 4.0), sin su participación ni respaldo. Posiciones: {0} · Horarios: {1}')))}
ATTRIB_SIM = ${_py(t(markTr('Datos simulados: las estaciones existen; los trenes, horarios e incidencias son inventados.')))}
LEGEND = [
    ("normal", NORMAL), ("aviso", WARNING), ("alerta", ALERT), ("detenido", STOPPED),
]
HOW = ${_py(t(markTr(
  'Datos: cada 20 s se leen las posiciones de los trenes y sus retrasos (GTFS-Realtime de Renfe, en JSON). Los horarios, estaciones y trazados (GTFS) se descargan una vez y se guardan en su carpeta de datos.\n\n'
  'Posición en la vía: cada posición se proyecta sobre el trazado de la línea y se convierte en kilómetros desde el origen. Así se sabe el orden de los trenes de cada sentido.\n\n'
  'Alertas de proximidad: entre dos trenes seguidos de la misma línea y sentido se mide la distancia por la vía y el intervalo (hace cuánto pasó el tren de delante por donde está ahora el de detrás). Por debajo de los umbrales hay aviso; por debajo de la mitad, alerta. También avisa si un tren lleva más de 3 min parado fuera de una estación.\n\n'
  'Gráfico de seguimiento: estaciones en vertical, a su distancia real, y la hora en horizontal. Cada tren es una línea: cuanto más inclinada, más rápido va; dos líneas que se juntan son dos trenes que se acercan. En gris discontinuo, el horario previsto.\n\n'
  'Límites: datos públicos que llegan con retraso, sin vías ni señales. Se supone vía doble, un sentido por vía. No sirve para circular: la seguridad real depende de la señalización (ASFA, ERTMS) y de los operadores.',
)))}
$_trainMonitorCore''';
  return TkExample(
    'train_monitor',
    app,
    t(
      markTr(
        'Trenes de Cercanías en directo con los datos abiertos de Renfe (o una simulación sin conexión): alertas de proximidad, gráfico de seguimiento y mapa de la línea. Demo educativa, no un sistema de seguridad.',
      ),
    ),
    design,
    code,
  );
}

/// La lógica del programa, sin textos que traducir.
const _trainMonitorCore = r'''
VEHICLES_URL = "https://gtfsrt.renfe.com/vehicle_positions.json"
TRIPS_URL = "https://gtfsrt.renfe.com/trip_updates.json"
GTFS_URL = "https://ssl.renfe.com/ftransit/Fichero_CER_FOMENTO/fomento_transit.zip"
USER_AGENT = "DMarlonStudio-TrainMonitor/1.0"
LIVE_EVERY = 20  # s entre lecturas: lo que tarda Renfe en publicar otra
GTFS_MAX_AGE = 7 * 86400  # el GTFS trae unas semanas de calendario
WINDOW_PAST, WINDOW_AHEAD = 60 * 60, 15 * 60
HISTORY_STEP = 10  # s mínimos entre dos puntos del recorrido de un tren
MAX_OFFSET = 1.0  # km: más lejos del trazado, el tren no está en esta línea
STATION_RADIUS = 0.35  # km alrededor de una estación
STALE = 180  # s sin noticias: el tren deja de contar
STOP_MIN = 3  # min parado fuera de una estación para avisar
MAX_SPEED = 220  # km/h: más rápido es un salto de la posición
LEVELS = {"": 0, "aviso": 1, "alerta": 2}
COLORS = {
    "normal": "#2b5797", "aviso": "#e08a00", "alerta": "#c62828",
    "detenido": "#7a4fb3", "fuera": "#9096a0",
}
DIR_COLORS = ("#2b5797", "#0a7a32")
INK, MUTED, GRID = "#1b1d22", "#5f6672", "#e3e6eb"
KM_CHOICES = ["0,5 km", "1 km", "2 km", "3 km", "5 km"]
MIN_CHOICES = ["1 min", "2 min", "3 min", "5 min"]
SPEED_CHOICES = ["×1", "×5", "×10", "×30"]
WEEKDAYS = ("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday")


# ------------------------------------------------------------------ utilidades
def data_dir():
    """Carpeta de datos del usuario: AppData en Windows, Application Support
    en macOS y ~/.local/share en Linux."""
    home = os.path.expanduser("~")
    if sys.platform == "win32":
        base = os.environ.get("APPDATA") or home
    elif sys.platform == "darwin":
        base = os.path.join(home, "Library", "Application Support")
    else:
        base = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")
    path = os.path.join(base, "DMarlon Studio")
    os.makedirs(path, exist_ok=True)
    return path


def app_dir():
    path = os.path.join(data_dir(), "train_monitor")
    os.makedirs(path, exist_ok=True)
    return path


def gtfs_path():
    return os.path.join(app_dir(), "renfe_cercanias_gtfs.zip")


def settings_path():
    return os.path.join(app_dir(), "settings.json")


def nucleo_name(code):
    return dict(NUCLEOS).get(code, SIM_NAME if code == "SIM" else code)


def number(text, default):
    try:
        return float(str(text).split()[0].replace(",", "."))
    except (ValueError, IndexError):
        return default


def fmt_km(km):
    if km is None:
        return "—"
    return ("%.1f km" % km).replace(".", ",") if km < 10 else "%d km" % round(km)


def fmt_secs(secs):
    if secs is None:
        return "—"
    secs = int(round(secs))
    if secs < 60:
        return "%d s" % secs
    minutes, secs = divmod(secs, 60)
    return "%d min %02d s" % (minutes, secs) if minutes < 10 else "%d min" % minutes


def fmt_delay(delay):
    if delay is None:
        return "—"
    minutes = int(round(delay / 60.0))
    if minutes == 0:
        return ON_TIME
    return "%+d min" % minutes


def fmt_speed(speed):
    return "—" if speed is None else "%d km/h" % round(speed)


def clock(stamp, seconds=True):
    return datetime.datetime.fromtimestamp(stamp).strftime("%H:%M:%S" if seconds else "%H:%M")


def short_error(error):
    text = str(getattr(error, "reason", "") or error or error.__class__.__name__)
    return text if len(text) <= 90 else text[:87] + "…"


def natural(text):
    """C2 antes que C10, R2N y R2S después de R2."""
    return [int(p) if p.isdigit() else p for p in re.split(r"(\d+)", text)]


# ------------------------------------------------------------------ descargas
def ssl_context():
    """Los certificados del sistema; en un ejecutable de macOS se añaden los
    de /etc/ssl/cert.pem (o los de certifi, si va incluido)."""
    context = ssl.create_default_context()
    try:
        import certifi
        context.load_verify_locations(certifi.where())
    except Exception:
        if sys.platform == "darwin" and os.path.exists("/etc/ssl/cert.pem"):
            try:
                context.load_verify_locations("/etc/ssl/cert.pem")
            except (OSError, ssl.SSLError):
                pass
    return context


def fetch_json(url, timeout=15):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout, context=ssl_context()) as response:
        return json.loads(response.read().decode("utf-8"))


def download(url, path, progress=None, cancel=None, timeout=30):
    """Descarga a un .part y lo cambia por el bueno solo si es un GTFS."""
    part = path + ".part"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=timeout, context=ssl_context()) as response:
            total = int(response.headers.get("Content-Length") or 0)
            done, told = 0, 0
            with open(part, "wb") as out:
                while True:
                    if cancel is not None and cancel.is_set():
                        raise OSError(CANCELLED)
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    out.write(chunk)
                    done += len(chunk)
                    if progress is not None and done - told >= 262144:
                        told = done
                        progress(done, total)
        with zipfile.ZipFile(part) as check:
            if "stops.txt" not in check.namelist():
                raise OSError(BAD_ZIP)
        os.replace(part, path)
    except zipfile.BadZipFile:
        raise OSError(BAD_ZIP)
    finally:
        if os.path.exists(part):
            os.remove(part)


def needs_download(path, now=None):
    try:
        return (now or time.time()) - os.path.getmtime(path) > GTFS_MAX_AGE
    except OSError:
        return True


# ------------------------------------------------------------------ geometría
class Line:
    """Una línea con su trazado: convierte latitud y longitud en kilómetros
    desde el origen (y al revés), con las estaciones sobre el trazado."""

    def __init__(self, key, name, color, shape, nucleo=""):
        self.key, self.name, self.nucleo = key, name, nucleo
        self.color = color if re.match(r"^#[0-9A-Fa-f]{6}$", color or "") else "#2b5797"
        self.shape = list(shape)
        lat0 = sum(p[0] for p in self.shape) / len(self.shape)
        self.ky = math.pi / 180.0 * 6371.0
        self.kx = self.ky * math.cos(math.radians(lat0))
        self.xy = [(lon * self.kx, lat * self.ky) for lat, lon in self.shape]
        self.cum = [0.0]
        for (x1, y1), (x2, y2) in zip(self.xy, self.xy[1:]):
            self.cum.append(self.cum[-1] + math.hypot(x2 - x1, y2 - y1))
        self.length = self.cum[-1] or 1.0
        self.stations = []  # (stop_id, nombre, lat, lon, km)
        self.station_km = {}

    def project(self, lat, lon):
        """(km a lo largo del trazado, distancia al trazado en km)."""
        px, py = lon * self.kx, lat * self.ky
        best, best_km = None, 0.0
        for i in range(len(self.xy) - 1):
            (x1, y1), (x2, y2) = self.xy[i], self.xy[i + 1]
            dx, dy = x2 - x1, y2 - y1
            seg = dx * dx + dy * dy
            u = 0.0 if seg == 0 else max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / seg))
            qx, qy = x1 + u * dx, y1 + u * dy
            d2 = (px - qx) ** 2 + (py - qy) ** 2
            if best is None or d2 < best:
                best, best_km = d2, self.cum[i] + u * (self.cum[i + 1] - self.cum[i])
        return best_km, math.sqrt(best or 0.0)

    def point_at(self, km):
        km = max(0.0, min(self.length, km))
        i = max(1, min(len(self.cum) - 1, bisect.bisect_left(self.cum, km)))
        k1, k2 = self.cum[i - 1], self.cum[i]
        u = 0.0 if k2 == k1 else (km - k1) / (k2 - k1)
        (a1, o1), (a2, o2) = self.shape[i - 1], self.shape[i]
        return a1 + u * (a2 - a1), o1 + u * (o2 - o1)

    def add_station(self, stop_id, name, lat, lon):
        km, offset = self.project(lat, lon)
        if offset > MAX_OFFSET or stop_id in self.station_km:
            return False
        self.stations.append((stop_id, name, lat, lon, km))
        self.station_km[stop_id] = km
        return True

    def finish(self):
        self.stations.sort(key=lambda s: s[4])

    def station_near(self, km, radius=STATION_RADIUS):
        best = None
        for station in self.stations:
            d = abs(station[4] - km)
            if d <= radius and (best is None or d < abs(best[4] - km)):
                best = station
        return best

    def station_at(self, lat, lon, radius=STATION_RADIUS):
        """La estación junto a un punto (por distancia real, no por km: en una
        línea circular el principio y el final son el mismo sitio)."""
        best, best_d = None, radius
        for station in self.stations:
            d = math.hypot((lon - station[3]) * self.kx, (lat - station[2]) * self.ky)
            if d <= best_d:
                best, best_d = station, d
        return best

    def next_station(self, km, direction):
        ahead = [s for s in self.stations if (s[4] > km + 0.05 if direction == 0 else s[4] < km - 0.05)]
        if not ahead:
            return None
        return ahead[0] if direction == 0 else ahead[-1]

    def terminus(self, direction):
        if not self.stations:
            return None
        return self.stations[-1] if direction == 0 else self.stations[0]

    def title(self):
        if len(self.stations) < 2:
            return self.name
        return "%s · %s – %s" % (self.name, self.stations[0][1], self.stations[-1][1])


class Network:
    """Las líneas de un núcleo, los viajes de hoy (línea y sentido) y su
    horario previsto en kilómetros."""

    def __init__(self, name, nucleo=""):
        self.name, self.nucleo = name, nucleo
        self.lines = collections.OrderedDict()
        self.trips = {}  # viaje -> (línea, sentido 0/1 o None)
        self.schedules = {}  # viaje -> [(hora, km), ...]
        self.line_trips = collections.defaultdict(list)
        self.dest = {}  # viaje -> estación de destino
        self.updated = ""
        self.stops = {}  # parada -> nombre

    def sort_lines(self):
        ordered = sorted(self.lines.values(), key=lambda line: natural(line.name))
        self.lines = collections.OrderedDict((line.key, line) for line in ordered)


# ------------------------------------------------------------ GTFS (horarios)
def _rows(zf, name, keep=None):
    """Filas de un .txt del GTFS como diccionarios (claves y valores sin los
    espacios de relleno de Renfe). keep(línea en bytes) filtra antes de leer
    el CSV: así stop_times.txt (cientos de MB) se recorre en segundos."""
    if name not in zf.namelist():
        return
    with zf.open(name) as raw:
        header = raw.readline().decode("utf-8-sig", "replace")
        keys = [k.strip() for k in next(csv.reader([header]))]
        for line in raw:
            if keep is not None and not keep(line):
                continue
            for row in csv.reader([line.decode("utf-8", "replace")]):
                if row:
                    yield dict(zip(keys, (v.strip() for v in row)))


def gtfs_time(text):
    h, m, s = (int(p) for p in text.strip().split(":"))
    return h * 3600 + m * 60 + s


def services_on(zf, prefix, day):
    weekday, ymd = WEEKDAYS[day.weekday()], day.strftime("%Y%m%d")
    keep = (lambda line: line.startswith(prefix)) if prefix else None
    active = set()
    for r in _rows(zf, "calendar.txt", keep):
        if r.get(weekday) == "1" and r.get("start_date", "") <= ymd <= r.get("end_date", ""):
            active.add(r.get("service_id", ""))
    for r in _rows(zf, "calendar_dates.txt", keep):
        if r.get("date") == ymd:
            if r.get("exception_type") == "1":
                active.add(r.get("service_id", ""))
            elif r.get("exception_type") == "2":
                active.discard(r.get("service_id", ""))
    return active


def load_gtfs(path, nucleo, day=None):
    """Las líneas de un núcleo con sus estaciones, trazados y los viajes de
    hoy. Solo se leen las filas de ese núcleo y de hoy."""
    day = day or datetime.date.today()
    base = time.mktime(day.timetuple())
    prefix = nucleo.encode()
    network = Network(nucleo_name(nucleo), nucleo)
    with zipfile.ZipFile(path) as zf:
        try:
            network.updated = datetime.datetime(*zf.getinfo("stops.txt").date_time).strftime("%d/%m/%Y")
        except KeyError:
            pass
        services = services_on(zf, prefix, day)
        routes = {}
        for r in _rows(zf, "routes.txt", lambda line: line.startswith(prefix)):
            short = r.get("route_short_name") or r.get("route_id", "")
            routes[r.get("route_id", "")] = (nucleo + "|" + short, short, "#" + (r.get("route_color") or ""))
        trips = {}
        shape_use = collections.defaultdict(collections.Counter)
        for r in _rows(zf, "trips.txt", lambda line: line.startswith(prefix)):
            route = routes.get(r.get("route_id", ""))
            if route is None or r.get("service_id") not in services:
                continue
            shape = r.get("shape_id", "")
            trips[r.get("trip_id", "")] = (route[0], shape)
            shape_use[route[0]][shape] += 1
        wanted = set(s for uses in shape_use.values() for s in uses if s)
        shapes = collections.defaultdict(list)
        for r in _rows(zf, "shapes.txt", lambda line: line.split(b",", 1)[0].strip().decode("utf-8", "replace") in wanted):
            try:
                shapes[r["shape_id"]].append((float(r["shape_pt_sequence"]), float(r["shape_pt_lat"]), float(r["shape_pt_lon"])))
            except (KeyError, ValueError):
                pass
        stops = {}
        for r in _rows(zf, "stops.txt"):
            try:
                stops[r["stop_id"]] = (r.get("stop_name") or r["stop_id"], float(r["stop_lat"]), float(r["stop_lon"]))
            except (KeyError, ValueError):
                pass
        wanted_trips = set(t.encode() for t in trips)
        times = collections.defaultdict(list)
        for r in _rows(zf, "stop_times.txt", lambda line: line.split(b",", 1)[0].strip() in wanted_trips):
            try:
                when = r.get("departure_time") or r.get("arrival_time")
                times[r["trip_id"]].append((int(float(r["stop_sequence"])), r["stop_id"], gtfs_time(when)))
            except (KeyError, ValueError):
                pass
    network.stops = dict((k, v[0]) for k, v in stops.items())
    colors = dict((v[0], v[2]) for v in routes.values())
    names = dict((v[0], v[1]) for v in routes.values())
    by_line = collections.defaultdict(list)
    for trip, (key, _) in trips.items():
        by_line[key].append(trip)
    for key, uses in shape_use.items():
        used = sorted(set(s for t in by_line[key] for _, s, _ in times.get(t, ()) if s in stops))
        ranked = [s for s, _ in uses.most_common() if s in shapes]
        ranked.sort(key=lambda s: s.endswith("_INV"))
        candidates = [(s, [(la, lo) for _, la, lo in sorted(shapes[s])]) for s in ranked]
        # Y, por si el trazado se queda corto, las paradas del viaje más largo.
        longest = max(by_line[key], key=lambda t: len(times.get(t, ())), default=None)
        candidates.append(("", [stops[s][1:] for _, s, _ in sorted(times.get(longest, [])) if s in stops]))
        ref, points, best = "", [], -1.0
        for shape_id, pts in candidates:
            if len(pts) < 2:
                continue
            probe = Line(key, "", "", pts)
            cover = sum(1 for s in used if probe.project(*stops[s][1:])[1] <= MAX_OFFSET) / float(len(used) or 1)
            if cover > best + 0.05:
                ref, points, best = shape_id, pts, cover
            if best >= 0.8:
                break
        if len(points) < 2:
            continue
        line = Line(key, names.get(key, key), colors.get(key, ""), points, nucleo)
        for sid in used:
            line.add_station(sid, *stops[sid])
        line.finish()
        if len(line.stations) < 2:
            continue
        network.lines[key] = line
        for trip in by_line[key]:
            seq = sorted(times.get(trip, []))
            path = [(base + secs, line.station_km[sid]) for _, sid, secs in seq if sid in line.station_km]
            shape = trips[trip][1]
            if len(path) >= 2 and path[-1][1] != path[0][1]:
                direction = 0 if path[-1][1] > path[0][1] else 1
            elif shape == ref:
                direction = 0
            elif shape and (shape == ref + "_INV" or ref == shape + "_INV"):
                direction = 1
            else:
                direction = None
            network.trips[trip] = (key, direction)
            if len(path) >= 2:
                network.schedules[trip] = path
                network.line_trips[key].append(trip)
            if seq and seq[-1][1] in stops:
                network.dest[trip] = stops[seq[-1][1]][0]
    network.sort_lines()
    return network


# ----------------------------------------------- GTFS-Realtime (en directo)
def parse_positions(data, network=None):
    """Las posiciones del JSON de Renfe (vehicle_positions.json) como
    observaciones: id, viaje, línea, lat, lon, hora, estado, parada y vía."""
    header = (data or {}).get("header") or {}
    try:
        feed_ts = int(header.get("timestamp") or 0)
    except (TypeError, ValueError):
        feed_ts = 0
    out = []
    for entity in (data or {}).get("entity") or []:
        vehicle = entity.get("vehicle") or {}
        position = vehicle.get("position") or {}
        try:
            lat, lon = float(position["latitude"]), float(position["longitude"])
        except (KeyError, TypeError, ValueError):
            continue
        trip = str((vehicle.get("trip") or {}).get("tripId") or "")
        info = vehicle.get("vehicle") or {}
        label = str(info.get("label") or "")
        ident = str(info.get("id") or entity.get("id") or trip)
        if network is not None and trip in network.trips:
            line = network.trips[trip][0]
        else:
            # Etiqueta «C1-23539-PLATF.(1)» y viaje «3009V23539C1»: línea
            # C1 del núcleo 30.
            short = label.split("-")[0].strip()
            line = trip[:2] + "|" + short if short and trip[:2].isdigit() else None
        found = re.search(r"PLATF\.\((\w+)\)", label)
        try:
            ts = int(vehicle.get("timestamp") or feed_ts)
        except (TypeError, ValueError):
            ts = feed_ts
        out.append({
            "id": ident, "label": label, "trip": trip, "line": line, "lat": lat, "lon": lon,
            "ts": ts, "status": str(vehicle.get("currentStatus") or ""),
            "stop": str(vehicle.get("stopId") or ""), "platform": found.group(1) if found else "",
        })
    return out, feed_ts


def parse_delays(data):
    """Retraso en segundos de cada viaje (trip_updates.json)."""
    out = {}
    for entity in (data or {}).get("entity") or []:
        update = entity.get("tripUpdate") or {}
        trip = (update.get("trip") or {}).get("tripId")
        delay = update.get("delay")
        if delay is None:
            for stop in update.get("stopTimeUpdate") or []:
                for kind in ("arrival", "departure"):
                    delay = (stop.get(kind) or {}).get("delay")
                    if delay is not None:
                        break
                if delay is not None:
                    break
        if trip and delay is not None:
            try:
                out[str(trip)] = int(delay)
            except (TypeError, ValueError):
                pass
    return out


# ------------------------------------------------------------ seguimiento
class Train:
    def __init__(self, ident):
        self.id = ident
        self.line = self.trip = None
        self.direction = None
        self.lat = self.lon = 0.0
        self.km, self.offset = 0.0, 0.0
        self.on_track = False
        self.status = self.stop = self.platform = ""
        self.delay = self.speed = None
        self.ts = 0
        self.history = collections.deque(maxlen=1500)  # [hora, km, nivel]
        self.moved_t, self.moved_km = 0, None
        self.level, self.state, self.stopped = "", "normal", 0


class Tracker:
    """Lo que se sabe de cada tren: posición en la vía, sentido, velocidad,
    cuánto lleva parado y su recorrido de la última hora."""

    def __init__(self, network):
        self.network = network
        self.trains = {}

    def update(self, observations, now, delays=None):
        for o in observations:
            line = self.network.lines.get(o.get("line"))
            if line is None:
                continue
            train = self.trains.get(o["id"])
            if train is None or train.trip != o.get("trip") or train.line != line.key:
                # Tren nuevo, o el mismo material con otro viaje.
                train = self.trains[o["id"]] = Train(o["id"])
            train.line, train.trip = line.key, o.get("trip")
            ts = int(o.get("ts") or now)
            km, offset = line.project(o["lat"], o["lon"])
            train.lat, train.lon, train.km, train.offset = o["lat"], o["lon"], km, offset
            train.on_track = offset <= MAX_OFFSET
            train.status, train.stop = o.get("status", ""), o.get("stop", "")
            train.platform = o.get("platform", "")
            info = self.network.trips.get(train.trip)
            if info and info[1] is not None:
                train.direction = info[1]
            elif train.history:
                first = train.history[0][1]
                if abs(km - first) > 0.3:
                    train.direction = 0 if km > first else 1
            if delays is not None and train.trip in delays:
                train.delay = delays[train.trip]
            elif o.get("delay") is not None:
                train.delay = o["delay"]
            if train.on_track and (not train.history or ts - train.history[-1][0] >= HISTORY_STEP):
                train.history.append([ts, km, ""])
            elif train.on_track and train.history and ts > train.history[-1][0]:
                train.history[-1][1] = km  # la última posición, sin llenar de puntos
            if train.moved_km is None or abs(km - train.moved_km) > 0.08:
                train.moved_km, train.moved_t = km, ts
            train.ts = max(train.ts, ts)
            train.speed = self.speed_of(train)
            train.stopped = train.ts - train.moved_t
        for ident in list(self.trains):
            train = self.trains[ident]
            while train.history and train.history[0][0] < now - WINDOW_PAST - 600:
                train.history.popleft()
            if now - train.ts > WINDOW_PAST + 600:
                del self.trains[ident]

    @staticmethod
    def speed_of(train):
        """km/h entre la posición de hace 1-4 min y la de ahora."""
        for t, k, _ in train.history:
            if train.ts - 240 <= t <= train.ts - 50:
                return abs(train.km - k) / (train.ts - t) * 3600.0
        return None

    def active(self, now):
        return [t for t in self.trains.values() if now - t.ts <= STALE]

    def apply(self, events):
        for train in self.trains.values():
            train.level = ""
            train.state = "normal" if train.on_track else "fuera"
        for ev in events:
            for ident in ev["trains"]:
                train = self.trains.get(ident)
                if train is None:
                    continue
                if LEVELS[ev["level"]] > LEVELS[train.level]:
                    train.level = ev["level"]
                if ev["kind"] == "stopped":
                    train.state = "detenido"
                elif train.state != "detenido":
                    train.state = train.level
        for ev in events:
            if ev["kind"] != "proximity":
                continue
            for ident in ev["trains"]:
                train = self.trains.get(ident)
                if train is not None and train.history and LEVELS[ev["level"]] > LEVELS[train.history[-1][2]]:
                    train.history[-1][2] = ev["level"]


def headway(follower, leader):
    """Segundos desde que el tren de delante pasó por donde está ahora el de
    detrás (con su recorrido); si no hay recorrido, distancia / velocidad."""
    k = follower.km
    crossed = None
    points = list(leader.history) + [[leader.ts, leader.km, ""]]
    for (t1, k1, _), (t2, k2, _) in zip(points, points[1:]):
        if t2 <= t1 or abs(k2 - k1) / (t2 - t1) * 3600.0 > MAX_SPEED:
            continue  # un salto de la posición, no un movimiento real
        if leader.direction is not None and k1 != k2 and (k2 > k1) != (leader.direction == 0):
            continue  # marcha atrás aparente: ruido de la posición
        if k1 == k2 == k:
            crossed = t2
        elif k1 != k2 and min(k1, k2) <= k <= max(k1, k2):
            crossed = t1 + (t2 - t1) * (k - k1) / (k2 - k1)
    if crossed is not None:
        return max(0.0, follower.ts - crossed)
    if follower.speed and follower.speed > 5:
        return abs(leader.km - follower.km) / follower.speed * 3600.0
    return None


def classify(gap_km, headway_s, warn_km, warn_min):
    """Por debajo de los umbrales, aviso; por debajo de la mitad, alerta."""
    if gap_km < warn_km / 2.0 or (headway_s is not None and headway_s < warn_min * 30.0):
        return "alerta"
    if gap_km < warn_km or (headway_s is not None and headway_s < warn_min * 60.0):
        return "aviso"
    return ""


def evaluate(trains, network, warn_km=2.0, warn_min=2.0, stop_min=STOP_MIN):
    """Alertas de proximidad entre trenes seguidos de la misma línea y
    sentido, y trenes parados demasiado tiempo fuera de una estación."""
    events = []
    groups = collections.defaultdict(list)
    for train in trains:
        if train.on_track and train.direction is not None:
            groups[(train.line, train.direction)].append(train)
    for (line_key, direction), group in sorted(groups.items()):
        group.sort(key=lambda t: t.km if direction == 0 else -t.km)
        for follower, leader in zip(group, group[1:]):
            line = network.lines.get(line_key)
            here = line.station_at(follower.lat, follower.lon) if line else None
            there = line.station_at(leader.lat, leader.lon) if line else None
            if here is not None and here is there:
                continue  # en la misma estación: andenes distintos
            if there is not None and there is line.terminus(direction):
                continue  # el de delante ya ha llegado a la cabecera
            if here is not None and here is line.terminus(1 - direction):
                continue  # el de detrás aún espera en la cabecera de salida
            gap = abs(leader.km - follower.km)
            hw = headway(follower, leader)
            level = classify(gap, hw, warn_km, warn_min)
            if level:
                events.append({
                    "kind": "proximity", "level": level, "line": line_key,
                    "trains": (follower.id, leader.id), "gap": gap, "headway": hw,
                })
    for train in trains:
        line = network.lines.get(train.line)
        if line is None or not train.on_track or train.status == "STOPPED_AT":
            continue
        if train.stopped >= stop_min * 60 and line.station_at(train.lat, train.lon) is None:
            level = "alerta" if train.stopped >= 2 * stop_min * 60 else "aviso"
            events.append({
                "kind": "stopped", "level": level, "line": train.line,
                "trains": (train.id,), "gap": None, "headway": None, "stopped": train.stopped,
            })
    return events


# ------------------------------------------------------------- simulación
# Estaciones reales (coordenadas aproximadas); trenes y horarios inventados.
SIM_LINES = [
    ("C3", "#8e44ad", 8, 95, 25001, [
        ("Madrid-Atocha", 40.4065, -3.6900), ("Villaverde Bajo", 40.3570, -3.6870),
        ("San Cristóbal Industrial", 40.3380, -3.6880), ("El Casar", 40.3080, -3.7010),
        ("Getafe Industrial", 40.2930, -3.7060), ("Pinto", 40.2433, -3.6975),
        ("Valdemoro", 40.1925, -3.6739), ("Ciempozuelos", 40.1617, -3.6189),
        ("Aranjuez", 40.0336, -3.6037),
    ]),
    ("R2S", "#2a9d3c", 7, 105, 27001, [
        ("Barcelona-Sants", 41.3790, 2.1403), ("Bellvitge", 41.3612, 2.1107),
        ("El Prat de Llobregat", 41.3283, 2.0971), ("Gavà", 41.3047, 2.0019),
        ("Castelldefels", 41.2793, 1.9772), ("Garraf", 41.2537, 1.9004),
        ("Sitges", 41.2395, 1.8061), ("Vilanova i la Geltrú", 41.2201, 1.7289),
    ]),
    ("C1", "#2b84c6", 9, 100, 21001, [
        ("València Nord", 39.4661, -0.3774), ("Alfafar-Benetússer", 39.4189, -0.3846),
        ("Massanassa", 39.4105, -0.3982), ("Catarroja", 39.4027, -0.4027),
        ("Silla", 39.3625, -0.4131), ("Sollana", 39.2786, -0.3800),
        ("Sueca", 39.2027, -0.3108), ("Cullera", 39.1645, -0.2545),
    ]),
]
ACCEL, BRAKE = 0.5, 0.7  # m/s²
SAFE_GAP = 0.5  # km: la señalización simulada no deja acercarse más
DWELL, END_DWELL = 35, 120  # s en cada estación y en la cabecera


class SimTrain:
    def __init__(self, number, line, direction, planned, start):
        self.id = str(number)
        self.trip = "SIM-%s-%s" % (line.name, number)
        self.line, self.direction = line, direction
        self.planned, self.start = planned, start
        self.s, self.v = 0.0, 0.0  # km recorridos y m/s
        self.dwell_until = start
        self.index = 0  # última estación alcanzada
        self.done = False
        self.incident_until = 0
        self.arr_delay = 0.0
        self.factor = 1.0
        self.held = 0  # s retenido en esta estación para espaciar


class Simulation:
    """Una red de tres líneas con trenes cada pocos minutos, retrasos al
    azar e incidencias que paran un tren entre estaciones: el de detrás se
    acerca hasta que la señalización simulada lo detiene."""

    def __init__(self, start=None, seed=None):
        self.rng = random.Random(seed)
        self.clock = float(start if start is not None else time.time())
        self.network = Network(SIM_NAME, "SIM")
        self.trains = []
        self.specs = {}
        self.profiles = {}
        self.next_slot = {}
        self.counter = collections.Counter()
        for name, color, every, vmax, base, stations in SIM_LINES:
            line = Line("SIM|" + name, name, color, [(la, lo) for _, la, lo in stations], "SIM")
            for i, (station, la, lo) in enumerate(stations):
                stop_id = "%s-%02d" % (name, i + 1)
                line.add_station(stop_id, station, la, lo)
                self.network.stops[stop_id] = station
            line.finish()
            self.network.lines[line.key] = line
            self.specs[line.key] = (every * 60.0, vmax / 3.6, base)
            for d in (0, 1):
                self.profiles[(line.key, d)] = self.profile(line, d, vmax / 3.6)
                self.next_slot[(line.key, d)] = self.clock + self.rng.uniform(0, every * 60.0)
        self.next_incident = self.clock + self.rng.uniform(240, 480)

    @staticmethod
    def stops_s(line, direction):
        return sorted(s[4] if direction == 0 else line.length - s[4] for s in line.stations)

    def profile(self, line, direction, vmax):
        """Horario de un tren solo, sin incidencias: (llegada, salida) a cada
        estación desde la salida de origen, y puntos (s, t) del recorrido."""
        stops = self.stops_s(line, direction)
        arr, dep, points = [0.0], [0.0], [(0.0, 0.0)]
        s, v, t = 0.0, 0.0, 0.0
        for target in stops[1:]:
            while s < target - 1e-6:
                v_stop = max(1.0, math.sqrt(2 * BRAKE * max(0.0, (target - s) * 1000)))
                v_new = min(v + ACCEL, vmax, v_stop)
                s = min(target, s + (v + v_new) / 2.0 / 1000.0)
                v, t = v_new, t + 1.0
                if int(t) % 10 == 0:
                    points.append((s, t))
            v = 0.0
            arr.append(t)
            points.append((s, t))
            t += DWELL
            dep.append(t)
            points.append((s, t))
        return {"stops": stops, "arr": arr, "dep": dep, "points": points}

    def nominal(self, key, s):
        points = self.profiles[key]["points"]
        prev = points[0]
        for p in points[1:]:
            if p[0] > s:
                if p[0] == prev[0]:
                    return p[1]
                return prev[1] + (p[1] - prev[1]) * (s - prev[0]) / (p[0] - prev[0])
            prev = p
        return points[-1][1]

    def spawn(self, line, direction, planned):
        every, vmax, base = self.specs[line.key]
        if self.rng.random() < 0.15:
            extra = self.rng.uniform(60, 240)  # sale con retraso
        else:
            extra = self.rng.uniform(-10, 40)
        k = self.counter[(line.key, direction)]
        self.counter[(line.key, direction)] += 1
        train = SimTrain(base + 2 * (k % 400) + direction, line, direction, planned, planned + max(0.0, extra))
        train.factor = self.rng.uniform(0.9, 1.0)
        self.trains.append(train)
        prof = self.profiles[(line.key, direction)]
        path = [(planned, self.km_ref(line, direction, 0.0))]
        for i in range(1, len(prof["stops"])):
            km = self.km_ref(line, direction, prof["stops"][i])
            path.append((planned + prof["arr"][i], km))
            path.append((planned + prof["dep"][i], km))
        self.network.trips[train.trip] = (line.key, direction)
        self.network.schedules[train.trip] = path
        self.network.line_trips[line.key].append(train.trip)
        self.network.dest[train.trip] = line.terminus(direction)[1]
        return train

    @staticmethod
    def km_ref(line, direction, s):
        return s if direction == 0 else line.length - s

    def force_incident(self, line_name=None, duration=None):
        """Para un tren en marcha entre estaciones (la próxima, a más de 1,2 km)."""
        candidates = []
        for train in self.trains:
            if train.done or train.dwell_until > self.clock or train.v < 5:
                continue
            if line_name and train.line.name != line_name:
                continue
            stops = self.profiles[(train.line.key, train.direction)]["stops"]
            ahead = [x for x in stops if x > train.s + 1e-6]
            if ahead and ahead[0] - train.s > 1.2 and train.s > 0.5:
                candidates.append(train)
        if not candidates:
            return None
        train = self.rng.choice(candidates)
        train.incident_until = self.clock + (duration or self.rng.uniform(300, 480))
        return train

    def step(self, seconds):
        end = self.clock + seconds
        while self.clock < end - 1e-9:
            h = min(2.0, end - self.clock)
            self.clock += h
            self._advance(h)

    def _advance(self, h):
        for (key, d), slot in list(self.next_slot.items()):
            if self.clock >= slot:
                self.spawn(self.network.lines[key], d, slot)
                self.next_slot[(key, d)] = slot + self.specs[key][0]
        if self.clock >= self.next_incident:
            self.force_incident()
            self.next_incident = self.clock + self.rng.uniform(420, 840)
        groups = collections.defaultdict(list)
        for train in self.trains:
            if self.clock >= train.start - DWELL and not train.done:
                groups[(train.line.key, train.direction)].append(train)
        for key, group in groups.items():
            group.sort(key=lambda t: -t.s)  # el de delante primero
            prof = self.profiles[key]
            vmax = self.specs[key[0]][1]
            for i, train in enumerate(group):
                leader = group[i - 1] if i > 0 else None
                if train.dwell_until > self.clock:
                    continue
                if train.index >= len(prof["stops"]) - 1:
                    train.done = True
                    continue
                if (train.v == 0 and train.s == prof["stops"][train.index] and leader is not None and train.held < 120
                        and leader.s - train.s < self.specs[key[0]][0] / 120.0):
                    # Regulación: si va pegado al de delante, espera un poco
                    # en la estación (a ~1 km/min, medio intervalo).
                    train.held += 20
                    train.dwell_until = self.clock + 20
                    continue
                target = prof["stops"][train.index + 1]
                v_stop = max(1.0, math.sqrt(2 * BRAKE * max(0.0, (target - train.s) * 1000)))
                limit = vmax * train.factor
                if leader is not None:
                    room = (leader.s - train.s - SAFE_GAP) * 1000
                    v_sig = math.sqrt(2 * BRAKE * room) if room > 0 else 0.0
                else:
                    v_sig = limit
                if train.incident_until > self.clock:
                    v_new = max(0.0, train.v - 1.2 * h)
                else:
                    v_new = min(train.v + ACCEL * h, limit, v_stop, v_sig)
                s = train.s + (train.v + v_new) / 2.0 * h / 1000.0
                if leader is not None:
                    s = min(s, max(train.s, leader.s - SAFE_GAP * 0.9))
                train.v = v_new
                if s >= target - 0.002:
                    train.s, train.v = target, 0.0
                    train.index += 1
                    train.held = 0
                    late = self.clock - (train.planned + prof["arr"][train.index])
                    train.arr_delay = late
                    if train.index >= len(prof["stops"]) - 1:
                        train.dwell_until = self.clock + END_DWELL
                    else:
                        train.dwell_until = self.clock + DWELL
                else:
                    train.s = s
        self.trains = [t for t in self.trains if not (t.done and self.clock >= t.dwell_until)]

    def delay_of(self, train):
        key = (train.line.key, train.direction)
        prof = self.profiles[key]
        if train.index == 0 and train.s == 0:
            return max(0.0, self.clock - train.planned)
        if train.dwell_until > self.clock or train.s == prof["stops"][train.index]:
            i = train.index
            return max(train.arr_delay, self.clock - (train.planned + prof["dep"][min(i, len(prof["dep"]) - 1)]))
        return self.clock - train.planned - self.nominal(key, train.s)

    def observations(self):
        out = []
        for train in self.trains:
            if self.clock < train.start - DWELL:
                continue
            line = train.line
            lat, lon = line.point_at(self.km_ref(line, train.direction, train.s))
            at_station = train.dwell_until > self.clock or train.v == 0 and train.s in self.profiles[(line.key, train.direction)]["stops"]
            stops = self.stops_s(line, train.direction)
            if at_station:
                idx = train.index
            else:
                idx = min(len(stops) - 1, train.index + 1)
            ordered = line.stations if train.direction == 0 else list(reversed(line.stations))
            out.append({
                "id": train.id, "label": "%s-%s" % (line.name, train.id), "trip": train.trip,
                "line": line.key, "lat": lat, "lon": lon, "ts": int(self.clock),
                "status": "STOPPED_AT" if at_station else "IN_TRANSIT_TO",
                "stop": ordered[idx][0], "platform": str(1 + train.direction),
                "delay": self.delay_of(train),
            })
        return out


# ---------------------------------------------------------------- ajustes
def load_settings():
    try:
        with open(settings_path(), encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_settings(data):
    try:
        tmp = settings_path() + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        os.replace(tmp, settings_path())
    except OSError:
        pass


# ------------------------------------------------------------------- ventana
class Form1(FormDesign):
    def form_create(self):
        style = ttk.Style()
        # Tablas claras también con el modo oscuro de macOS.
        style.configure("Light.Treeview", background="#ffffff", fieldbackground="#ffffff", foreground=INK)
        style.configure("Light.Treeview.Heading", foreground=INK)
        style.map("Light.Treeview", background=[("selected", "#d6e4f7")], foreground=[("selected", INK)])
        for box in (self.Nucleo, self.LineBox, self.WarnKm, self.WarnMin, self.Speed):
            # Que la rueda del ratón al pasar por encima no cambie de núcleo.
            for sequence in ("<MouseWheel>", "<Button-4>", "<Button-5>"):
                box.bind(sequence, lambda event: "break")
        for tree in (self.Trains, self.Alerts):
            tree.configure(style="Light.Treeview", selectmode="browse")
            for level in ("aviso", "alerta", "detenido", "fuera"):
                tree.tag_configure(level, foreground=COLORS[level])
        for column in ("delay", "speed"):
            self.Trains.column(column, anchor="e")
        self.queue = queue.Queue()
        self.cancel = threading.Event()
        self.gen = 0
        self.settings = load_settings()
        self.source = None
        self.network = self.tracker = self.sim = None
        self.events, self.active = [], {}
        self.line_keys = []
        self.selected = None
        self.feed_busy = False
        self.last_fetch = 0.0
        self.feed_time = 0
        self.delays = {}
        self.live_day = datetime.date.today()
        self.flash = 0
        self.hover = None
        self.graph_hits, self.map_hits = [], []
        self.poll_job = None
        self.WarnKm.configure(values=KM_CHOICES)
        self.WarnMin.configure(values=MIN_CHOICES)
        self.Speed.configure(values=SPEED_CHOICES)
        self.WarnKm_var.set(self.settings.get("warn_km") if self.settings.get("warn_km") in KM_CHOICES else "2 km")
        self.WarnMin_var.set(self.settings.get("warn_min") if self.settings.get("warn_min") in MIN_CHOICES else "2 min")
        self.Speed_var.set(self.settings.get("speed") if self.settings.get("speed") in SPEED_CHOICES else "×10")
        self.Sound_var.set(1 if self.settings.get("sound", True) else 0)
        self.Graph.bind("<Motion>", self.Graph_motion)
        self.Graph.bind("<Leave>", self.Graph_leave)
        self.Graph.bind("<Button-1>", self.Graph_click)
        self.Map.bind("<Button-1>", self.Map_click)
        self.Map.configure(cursor="hand2")
        self.poll_job = self.root.after(150, self.poll)
        if self.settings.get("source") == SIM:
            self.start_sim()
        else:
            self.start_live()
        self.Timer1.start()

    # ------------------------------------------------------------- utilidades
    def now(self):
        return self.sim.clock if self.source == SIM and self.sim is not None else time.time()

    def warn_km(self):
        return number(self.WarnKm_var.get(), 2.0)

    def warn_min(self):
        return number(self.WarnMin_var.get(), 2.0)

    def speed(self):
        return number(self.Speed_var.get().replace("×", ""), 10.0)

    def say(self, text, icon="info"):
        self.Status.set(text, icon=icon)

    def current_line(self):
        key = self.settings.get("line")
        if self.network is None:
            return None
        return self.network.lines.get(key)

    def remember(self, **values):
        self.settings.update(values)
        save_settings(self.settings)

    # ------------------------------------------------------------ fuentes
    def reset_view(self):
        self.events, self.active = [], {}
        self.selected = None
        self.hover = None
        self.Alerts.delete(*self.Alerts.get_children())
        self.Trains.delete(*self.Trains.get_children())

    def start_sim(self, message=None):
        self.gen += 1
        self.cancel.set()
        self.cancel = threading.Event()
        self.source = SIM
        self.Source_var.set(SIM)
        self.Loading.stop()
        self.Loading.configure(mode="determinate", value=0)
        self.reset_view()
        self.sim = Simulation(start=time.time() - 6000)
        self.network = self.sim.network
        self.tracker = Tracker(self.network)
        # Una hora de historia antes de abrir, para que los gráficos ya cuenten algo.
        self.sim.step(2400)
        while self.sim.clock < time.time() - 1:
            self.sim.step(20)
            self.tracker.update(self.sim.observations(), self.sim.clock)
            self.check_alerts(quiet=True)
        self.Nucleo.configure(values=[SIM_NAME], state="disabled")
        self.Nucleo_var.set(SIM_NAME)
        self.Speed.configure(state="readonly")
        self.fill_lines()
        self.Attrib.configure(text=ATTRIB_SIM)
        self.say(message or SIM_ON.format(int(self.speed())), icon="⚠" if message else "play")
        self.remember(source=SIM)
        self.refresh()

    def start_live(self):
        self.gen += 1
        self.cancel.set()
        self.cancel = threading.Event()
        self.source = LIVE
        self.Source_var.set(LIVE)
        self.sim = None
        self.network = self.tracker = None
        self.reset_view()
        names = [name for _, name in NUCLEOS]
        code = self.settings.get("nucleo") if self.settings.get("nucleo") in dict(NUCLEOS) else "10"
        self.Nucleo.configure(values=names, state="readonly")
        self.Nucleo_var.set(nucleo_name(code))
        self.Speed.configure(state="disabled")
        self.LineBox.configure(values=[])
        self.LineBox_var.set("")
        self.Attrib.configure(text=ATTRIB_LIVE.format("—", "—"))
        self.say(CONNECTING, icon="refresh")
        self.Loading.configure(mode="indeterminate")
        self.Loading.start(12)
        self.feed_busy = True
        self.refresh()
        threading.Thread(target=self.load_live, args=(self.gen, code, self.cancel), daemon=True).start()

    def load_live(self, gen, code, cancel):
        """En otro hilo: comprueba el directo, descarga el GTFS si hace falta
        y lee el núcleo. Solo habla con la ventana por la cola."""
        def say(*message):
            self.queue.put((gen,) + message)
        try:
            positions = fetch_json(VEHICLES_URL)
        except Exception as error:
            return say("offline", short_error(error))
        try:
            path = gtfs_path()
            fresh = False
            if needs_download(path):
                say("progress", 0, 0)
                download(GTFS_URL, path, progress=lambda done, total: say("progress", done, total), cancel=cancel)
                fresh = True
            say("reading", code)
            network = load_gtfs(path, code)
            if not network.lines and not fresh:
                # Horarios viejos sin servicio hoy: se descargan otra vez.
                say("progress", 0, 0)
                download(GTFS_URL, path, progress=lambda done, total: say("progress", done, total), cancel=cancel)
                say("reading", code)
                network = load_gtfs(path, code)
            try:
                delays = parse_delays(fetch_json(TRIPS_URL))
            except Exception:
                delays = {}
            say("network", code, network, positions, delays)
        except Exception as error:
            say("failed", short_error(error))

    def fetch_feed(self, gen):
        def say(*message):
            self.queue.put((gen,) + message)
        try:
            positions = fetch_json(VEHICLES_URL)
        except Exception as error:
            return say("feed_error", short_error(error))
        try:
            delays = parse_delays(fetch_json(TRIPS_URL))
        except Exception:
            delays = None
        say("feed", positions, delays)

    def poll(self):
        try:
            while True:
                message = self.queue.get_nowait()
                if message[0] == self.gen:
                    self.handle(message[1], *message[2:])
        except queue.Empty:
            pass
        self.poll_job = self.root.after(150, self.poll)

    def handle(self, kind, *args):
        if kind == "offline":
            self.feed_busy = False
            self.start_sim(OFFLINE.format(args[0]))
        elif kind == "failed":
            self.feed_busy = False
            self.start_sim(GTFS_FAIL.format(args[0]))
        elif kind == "progress":
            done, total = args
            if total:
                self.Loading.stop()
                self.Loading.configure(mode="determinate", value=done * 100.0 / total)
            mb = lambda n: ("%.1f MB" % (n / 1048576.0)).replace(".", ",")
            self.say(DOWNLOADING.format(mb(done), mb(total) if total else "?"), icon="⤓")
        elif kind == "reading":
            self.Loading.configure(mode="indeterminate")
            self.Loading.start(12)
            self.say(READING.format(nucleo_name(args[0])), icon="refresh")
        elif kind == "network":
            code, network, positions, delays = args
            self.Loading.stop()
            self.Loading.configure(mode="determinate", value=0)
            self.feed_busy = False
            self.network = network
            self.tracker = Tracker(network)
            self.delays = delays
            self.live_day = datetime.date.today()
            self.remember(source=LIVE, nucleo=code)
            if not network.lines:
                self.fill_lines()
                self.say(NO_SERVICE.format(nucleo_name(code)), icon="⚠")
                return
            self.apply_feed(positions, first=True)
        elif kind == "feed":
            self.feed_busy = False
            positions, delays = args
            if delays is not None:
                self.delays = delays
            if self.network is not None:
                self.apply_feed(positions)
        elif kind == "feed_error":
            self.feed_busy = False
            self.say(LIVE_FAIL.format(args[0]), icon="⚠")

    def apply_feed(self, positions, first=False):
        observations, feed_ts = parse_positions(positions, self.network)
        self.last_fetch = time.time()
        self.feed_time = feed_ts or int(self.last_fetch)
        self.tracker.update(observations, time.time(), self.delays)
        self.check_alerts(quiet=first)
        if first:
            self.fill_lines(busiest=True)
        count = len([t for t in self.tracker.active(time.time())])
        self.say(LIVE_OK.format(count, self.network.name, clock(self.feed_time)), icon="check")
        self.Attrib.configure(text=ATTRIB_LIVE.format(clock(self.feed_time), self.network.updated or "—"))
        self.refresh()

    # ------------------------------------------------------------- alertas
    def check_alerts(self, quiet=False):
        now = self.now()
        events = evaluate(self.tracker.active(now), self.network, self.warn_km(), self.warn_min())
        self.tracker.apply(events)
        current, fresh = {}, None
        for ev in events:
            key = (ev["kind"], ev["line"], ev["trains"])
            current[key] = ev["level"]
            old = self.active.get(key)
            if old is None or LEVELS[ev["level"]] > LEVELS[old]:
                self.log_alert(ev, now)
                if fresh is None or LEVELS[ev["level"]] > LEVELS[fresh["level"]]:
                    fresh = ev
        self.active = current
        self.events = events
        if fresh is not None and not quiet:
            self.flash = 6
            if self.Sound_var.get():
                self.root.bell()
            line = self.network.lines.get(fresh["line"])
            name = line.name if line else fresh["line"]
            level = ALERT if fresh["level"] == "alerta" else WARNING
            if fresh["kind"] == "stopped":
                self.say(NEW_STOP.format(level, name, fresh["trains"][0], fmt_secs(fresh["stopped"])), icon="⚠")
            else:
                self.say(NEW_ALERT.format(level, name, self.pair_text(fresh)), icon="⚠")
        return events

    def pair_text(self, ev):
        return "%s → %s · %s · %s" % (ev["trains"][0], ev["trains"][1], fmt_km(ev["gap"]), fmt_secs(ev["headway"]))

    def log_alert(self, ev, now):
        line = self.network.lines.get(ev["line"])
        name = line.name if line else ev["line"]
        level = ALERT if ev["level"] == "alerta" else WARNING
        if ev["kind"] == "stopped":
            trains = ev["trains"][0]
            gap = STOPPED_FOR.format(fmt_secs(ev["stopped"]))
        else:
            trains = "%s → %s" % ev["trains"]
            gap = "%s · %s" % (fmt_km(ev["gap"]), fmt_secs(ev["headway"]))
        self.Alerts.insert("", 0, values=(clock(now), level, name, trains, gap), tags=(ev["level"],))
        rows = self.Alerts.get_children()
        if len(rows) > 300:
            self.Alerts.delete(*rows[300:])

    # --------------------------------------------------------------- vista
    def fill_lines(self, busiest=False):
        lines = list(self.network.lines.values()) if self.network else []
        self.line_keys = [line.key for line in lines]
        self.LineBox.configure(values=[line.title() for line in lines])
        key = self.settings.get("line")
        if self.network is None or key not in self.network.lines:
            key = None
        if key is None and lines:
            key = lines[0].key
            if busiest and self.tracker is not None:
                counts = collections.Counter(t.line for t in self.tracker.active(self.now()))
                if counts:
                    key = counts.most_common(1)[0][0]
        if key is not None:
            self.settings["line"] = key
            self.LineBox_var.set(self.network.lines[key].title())
        else:
            self.LineBox_var.set("")

    def train_rows(self, line):
        now = self.now()
        rows = []
        trains = [t for t in self.tracker.active(now) if t.line == line.key]
        trains.sort(key=lambda t: (t.direction if t.direction is not None else 2, t.km if t.direction != 1 else -t.km))
        for train in trains:
            dest = self.network.dest.get(train.trip)
            if dest is None and train.direction is not None:
                end = line.terminus(train.direction)
                dest = end[1] if end else ""
            name = self.network.stops.get(train.stop, "")
            if not name and train.direction is not None:
                nxt = line.next_station(train.km, train.direction)
                name = nxt[1] if nxt else ""
            if train.platform:
                name = "%s (%s)" % (name, PLATFORM.format(train.platform))
            if train.state == "detenido":
                state = "%s %s" % (STOPPED, fmt_secs(train.stopped))
            elif train.state in ("aviso", "alerta"):
                state = ALERT if train.state == "alerta" else WARNING
            elif train.state == "fuera":
                state = OFF_TRACK
            elif train.status == "STOPPED_AT":
                state = AT_STATION
            else:
                state = NORMAL
            rows.append((train.id, (train.id, dest or "", name, fmt_delay(train.delay), fmt_speed(train.speed), state),
                         (train.state,) if train.state != "normal" else ()))
        return rows

    def fill_trains(self):
        line = self.current_line()
        rows = self.train_rows(line) if line is not None and self.tracker is not None else []
        wanted = [iid for iid, _, _ in rows]
        for iid in self.Trains.get_children():
            if iid not in wanted:
                self.Trains.delete(iid)
        for index, (iid, values, tags) in enumerate(rows):
            if self.Trains.exists(iid):
                self.Trains.item(iid, values=values, tags=tags)
                self.Trains.move(iid, "", index)
            else:
                self.Trains.insert("", index, iid=iid, values=values, tags=tags)
        if line is not None:
            self.LblTrains.configure(text=TRAINS_OF.format(line.name, len(rows)))

    def update_banner(self):
        alerts = sum(1 for ev in self.events if ev["level"] == "alerta")
        warnings = sum(1 for ev in self.events if ev["level"] == "aviso")
        if not alerts and not warnings:
            self.Banner.configure(text=BANNER_NONE, bg="#e7f4ea", fg="#0a7a32")
            return
        text = "⚠  " + BANNER.format(alerts, warnings)
        color = COLORS["alerta"] if alerts else COLORS["aviso"]
        if self.flash > 0 and self.flash % 2 == 0:
            self.Banner.configure(text=text, bg=color, fg="#ffffff")
        else:
            self.Banner.configure(text=text, bg="#fdecea" if alerts else "#fff4dc", fg=color)

    def refresh(self):
        self.fill_trains()
        self.update_banner()
        self.draw_graph()
        self.draw_map()

    @staticmethod
    def size(canvas, width, height):
        w, h = canvas.winfo_width(), canvas.winfo_height()
        return (w if w > 20 else width), (h if h > 20 else height)

    # ------------------------------------------------- gráfico de seguimiento
    def draw_graph(self):
        c = self.Graph
        c.delete("all")
        self.graph_hits = []
        W, H = self.size(c, 660, 282)
        line = self.current_line()
        if line is None or self.tracker is None:
            c.create_text(W / 2, H / 2, text=LOADING if self.source == LIVE else NO_LINE, fill=MUTED)
            return
        left, right, top, bottom = 132, W - 12, 30, H - 22
        now = self.now()
        t0, t1 = now - WINDOW_PAST, now + WINDOW_AHEAD
        X = lambda t: left + (t - t0) / float(t1 - t0) * (right - left)
        Y = lambda km: top + km / line.length * (bottom - top)
        c.create_text(10, 13, text=GRAPH_TITLE.format(line.name), anchor="w", fill=INK, font=("TkDefaultFont", 11, "bold"))
        # Leyenda: un color por sentido y el horario previsto.
        lx = W - 12
        for text, color, dash in ((SCHEDULED, "#9aa1ac", (4, 3)),
                                  ("→ " + line.stations[0][1], DIR_COLORS[1], None),
                                  ("→ " + line.stations[-1][1], DIR_COLORS[0], None)):
            item = c.create_text(lx, 13, text=text, anchor="e", fill=MUTED, font=("TkDefaultFont", 9))
            x1 = c.bbox(item)[0] - 4
            c.create_line(x1 - 18, 13, x1, 13, fill=color, width=2, dash=dash)
            lx = x1 - 30
        # Estaciones: a su distancia real; los nombres que caben.
        last = -100
        for i, station in enumerate(line.stations):
            y = Y(station[4])
            c.create_line(left, y, right, y, fill=GRID)
            end = i in (0, len(line.stations) - 1)
            if y - last >= 11 or end:
                name = station[1] if len(station[1]) <= 19 else station[1][:18] + "…"
                c.create_text(left - 6, y, text=name, anchor="e", fill=INK if end else MUTED, font=("TkDefaultFont", 9))
                last = y
        # Horas: cada 10 minutos.
        tick = int(t0 // 600 + 1) * 600
        while tick < t1:
            x = X(tick)
            c.create_line(x, top, x, bottom, fill=GRID)
            c.create_text(x, bottom + 10, text=clock(tick, seconds=False), fill=MUTED, font=("TkDefaultFont", 9))
            tick += 600
        c.create_rectangle(left, top, right, bottom, outline="#c9ced6")
        # Horario previsto, en gris discontinuo.
        for trip in self.network.line_trips.get(line.key, ()):
            path = self.network.schedules.get(trip)
            if not path or path[0][0] > t1 or path[-1][0] < t0:
                continue
            coords = []
            for t, km in path:
                coords += [X(min(max(t, t0), t1)), Y(km)]
            if len(coords) >= 4:
                c.create_line(*coords, fill="#b8bec8", dash=(4, 3))
        # Recorrido real de cada tren; en naranja o rojo, los tramos con aviso o alerta.
        drawn = 0
        for train in self.tracker.trains.values():
            if train.line != line.key or not train.history:
                continue
            points = [p for p in train.history if p[0] >= t0]
            if not points:
                continue
            drawn += 1
            base = DIR_COLORS[train.direction or 0] if train.direction is not None else COLORS["fuera"]
            width = 3 if train.id == self.selected else 2
            run, level = [], points[0][2]
            for t, km, lev in points:
                x, y = X(t), Y(km)
                self.graph_hits.append((x, y, train.id))
                if lev != level and run:
                    run.append((x, y))
                    self.graph_run(c, run, level, base, width)
                    run, level = [], lev
                run.append((x, y))
            self.graph_run(c, run, level, base, width)
            if now - train.ts <= STALE:
                x, y = X(points[-1][0]), Y(points[-1][1])
                fill = COLORS.get(train.state, base) if train.state != "normal" else base
                c.create_oval(x - 3, y - 3, x + 3, y + 3, fill=fill, outline="#ffffff")
        x = X(now)
        c.create_line(x, top, x, bottom, fill=INK, dash=(2, 2))
        c.create_text(x + 3, top + 7, text=NOW, anchor="w", fill=INK, font=("TkDefaultFont", 9, "bold"))
        if drawn == 0 and self.source == LIVE:
            c.create_text((left + right) / 2, bottom - 14, text=GATHERING, fill=MUTED, font=("TkDefaultFont", 9))
        if self.hover is not None:
            self.show_tip(*self.hover)

    @staticmethod
    def graph_run(c, run, level, base, width):
        if len(run) == 1:
            run = run + [run[0]]
        coords = [v for p in run for v in p]
        if level:
            c.create_line(*coords, fill=COLORS[level], width=width + 2, capstyle="round")
        else:
            c.create_line(*coords, fill=base, width=width)

    def nearest(self, hits, x, y, radius):
        best = None
        for hx, hy, ident in hits:
            d = (hx - x) ** 2 + (hy - y) ** 2
            if d <= radius * radius and (best is None or d < best[0]):
                best = (d, ident)
        return best[1] if best else None

    def tip_text(self, ident):
        train = self.tracker.trains.get(ident) if self.tracker else None
        if train is None:
            return None
        line = self.network.lines.get(train.line)
        dest = self.network.dest.get(train.trip)
        if dest is None and line is not None and train.direction is not None:
            dest = line.terminus(train.direction)[1]
        head = TRAIN.format(train.id) + " · " + (line.name if line else "")
        if dest:
            head += " " + TOWARDS.format(dest)
        return head + "\n" + DELAY_SPEED.format(fmt_delay(train.delay), fmt_speed(train.speed))

    def show_tip(self, x, y):
        c = self.Graph
        c.delete("tip")
        ident = self.nearest(self.graph_hits, x, y, 10)
        if ident is None:
            return
        text = self.tip_text(ident)
        if not text:
            return
        W, _ = self.size(c, 660, 282)
        anchor = "nw" if x < W - 230 else "ne"
        dx = 12 if anchor == "nw" else -12
        item = c.create_text(x + dx, y + 12, text=text, anchor=anchor, fill=INK, font=("TkDefaultFont", 9), tags="tip")
        x1, y1, x2, y2 = c.bbox(item)
        box = c.create_rectangle(x1 - 5, y1 - 3, x2 + 5, y2 + 3, fill="#ffffe8", outline="#9096a0", tags="tip")
        c.tag_lower(box, item)

    def Graph_motion(self, event):
        self.hover = (event.x, event.y)
        self.show_tip(event.x, event.y)

    def Graph_leave(self, event=None):
        self.hover = None
        self.Graph.delete("tip")

    def Graph_click(self, event):
        ident = self.nearest(self.graph_hits, event.x, event.y, 10)
        if ident is not None:
            self.select_train(ident)

    # ------------------------------------------------------------------ mapa
    def draw_map(self):
        c = self.Map
        c.delete("all")
        self.map_hits = []
        W, H = self.size(c, 398, 282)
        line = self.current_line()
        if line is None or self.tracker is None:
            c.create_text(W / 2, H / 2, text=LOADING if self.source == LIVE else NO_LINE, fill=MUTED)
            return
        c.create_text(10, 13, text=MAP_TITLE.format(line.name), anchor="w", fill=INK, font=("TkDefaultFont", 11, "bold"))
        pad, top, bottom = 22, 30, H - 28
        xs = [x for x, _ in line.xy]
        ys = [y for _, y in line.xy]
        span_x, span_y = max(xs) - min(xs) or 1.0, max(ys) - min(ys) or 1.0
        scale = min((W - 2 * pad) / span_x, (bottom - top) / span_y)
        ox = (W - span_x * scale) / 2.0
        oy = top + ((bottom - top) - span_y * scale) / 2.0
        P = lambda lat, lon: (ox + (lon * line.kx - min(xs)) * scale, oy + (max(ys) - lat * line.ky) * scale)
        coords = [v for lat, lon in line.shape for v in P(lat, lon)]
        c.create_line(*coords, fill="#5f6672", width=7, capstyle="round", joinstyle="round")
        c.create_line(*coords, fill=line.color, width=4, capstyle="round", joinstyle="round")
        labelled = []
        for i, (_, name, lat, lon, _) in enumerate(line.stations):
            x, y = P(lat, lon)
            c.create_oval(x - 4, y - 4, x + 4, y + 4, fill="#ffffff", outline="#444a52", width=2)
            end = i in (0, len(line.stations) - 1)
            if end or all((x - a) ** 2 + (y - b) ** 2 > 60 ** 2 for a, b in labelled):
                anchor = "w" if x < W - 120 else "e"
                c.create_text(x + (8 if anchor == "w" else -8), y, text=name, anchor=anchor,
                              fill=INK if end else MUTED, font=("TkDefaultFont", 9, "bold" if end else "normal"))
                labelled.append((x, y))
        for train in self.tracker.active(self.now()):
            if train.line != line.key:
                continue
            x, y = P(train.lat, train.lon)
            fill = COLORS.get(train.state, COLORS["normal"])
            r = 7
            if train.id == self.selected:
                c.create_oval(x - 11, y - 11, x + 11, y + 11, outline=INK, width=2)
            c.create_oval(x - r, y - r, x + r, y + r, fill=fill, outline="#ffffff", width=2, tags=("train",))
            if train.id == self.selected or train.state in ("aviso", "alerta", "detenido"):
                c.create_text(x, y - 14, text=train.id, fill=fill, font=("TkDefaultFont", 9, "bold"))
            self.map_hits.append((x, y, train.id))
        # Leyenda.
        x = 10
        for state, text in LEGEND:
            c.create_oval(x, H - 17, x + 10, H - 7, fill=COLORS[state], outline="")
            item = c.create_text(x + 14, H - 12, text=text, anchor="w", fill=MUTED, font=("TkDefaultFont", 9))
            x = c.bbox(item)[2] + 12

    def Map_click(self, event):
        ident = self.nearest(self.map_hits, event.x, event.y, 13)
        if ident is not None:
            self.select_train(ident)

    def select_train(self, ident):
        self.selected = ident
        if self.Trains.exists(ident):
            if self.Trains.selection() != (ident,):
                self.Trains.selection_set(ident)
            self.Trains.see(ident)
        self.draw_graph()
        self.draw_map()

    # -------------------------------------------------------------- eventos
    def Timer1_timer(self):
        if self.flash > 0:
            self.flash -= 1
        if self.source == SIM and self.sim is not None:
            self.sim.step(self.speed())
            self.tracker.update(self.sim.observations(), self.sim.clock)
            self.check_alerts()
            self.refresh()
        elif self.source == LIVE:
            if self.network is not None and not self.feed_busy and datetime.date.today() != self.live_day:
                self.start_live()  # pasada la medianoche: los viajes de hoy
                return
            if self.network is not None and not self.feed_busy and time.time() - self.last_fetch >= LIVE_EVERY:
                self.feed_busy = True
                threading.Thread(target=self.fetch_feed, args=(self.gen,), daemon=True).start()
            self.update_banner()
            if int(time.time()) % 5 == 0:
                self.draw_graph()

    def Source_change(self):
        wanted = self.Source_var.get()
        if wanted == self.source:
            return
        if wanted == SIM:
            self.start_sim()
        else:
            self.start_live()

    def Nucleo_select(self, event=None):
        if self.source != LIVE:
            return
        names = dict((name, code) for code, name in NUCLEOS)
        code = names.get(self.Nucleo_var.get())
        if code and code != self.settings.get("nucleo"):
            self.settings["line"] = None
            self.remember(nucleo=code)
            self.start_live()

    def LineBox_select(self, event=None):
        if self.network is None:
            return
        titles = dict((line.title(), line.key) for line in self.network.lines.values())
        key = titles.get(self.LineBox_var.get())
        if key:
            self.selected = None
            self.remember(line=key)
            self.refresh()

    def WarnKm_select(self, event=None):
        self.remember(warn_km=self.WarnKm_var.get())
        if self.tracker is not None:
            self.check_alerts(quiet=True)
            self.refresh()

    def WarnMin_select(self, event=None):
        self.remember(warn_min=self.WarnMin_var.get())
        if self.tracker is not None:
            self.check_alerts(quiet=True)
            self.refresh()

    def Speed_select(self, event=None):
        self.remember(speed=self.Speed_var.get())
        if self.source == SIM:
            self.say(SIM_ON.format(int(self.speed())), icon="play")

    def Sound_toggle(self):
        self.remember(sound=bool(self.Sound_var.get()))

    def Trains_select(self, event=None):
        chosen = self.Trains.selection()
        if chosen and chosen[0] != self.selected:
            self.selected = chosen[0]
            self.draw_graph()
            self.draw_map()

    def BtnHelp_click(self):
        messagebox.showinfo(APP, HOW, parent=self.root)

    def form_close(self, *args):
        self.cancel.set()
        self.Timer1.stop()
        if self.poll_job is not None:
            self.root.after_cancel(self.poll_job)
        save_settings(self.settings)
        self.root.destroy()
''';
