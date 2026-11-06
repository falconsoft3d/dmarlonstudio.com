part of 'tk_examples.dart';

// ------------------------------------------------------------ reproductor MP3
/// Un reproductor de MP3 al estilo de los clásicos de escritorio de principios
/// de los 2000: un panel metálico oscuro con la pantalla LCD (reloj, título
/// que se desplaza, kbps, kHz, espectro animado), la barra de posición, el
/// volumen y los botones dibujados, y debajo la lista de reproducción negra
/// con letras verdes. Lee las etiquetas ID3 y las cabeceras MPEG sin
/// bibliotecas externas, suena con pygame y recuerda la lista.
TkExample tkUtilMp3Player(String Function(String) t) {
  const deck = '#2b2e37', engraved = '#8b93a5';
  const button = '#3a3f4b', ink = '#d5dae3';
  final app = t(markTr('Reproductor MP3'));
  TkWidget metal(String name, int x, int y, int w, int h) => _w(
    'Canvas',
    name,
    x,
    y,
    w,
    h,
    {'bg': deck},
    {
      'click': 'Button_down',
      'release': 'Button_up',
      'enter': 'Button_enter',
      'leave': 'Button_leave',
    },
  );
  TkWidget listButton(String name, int x, String text) => _w(
    'Button',
    name,
    x,
    532,
    84,
    28,
    {'text': text, 'bg': button, 'fg': ink},
    {'command': '${name}_click'},
  );
  final design =
      TkDesign(
          width: 550,
          height: 592,
          props: {'title': app, 'bg': deck, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          // El panel principal: pantalla, posición, volumen y botones.
          _w(
            'Canvas',
            'Lcd',
            12,
            12,
            212,
            104,
            {'bg': '#000000'},
            {'click': 'Lcd_click'},
          ),
          _w('Canvas', 'Marquee', 236, 12, 302, 28, {'bg': '#000000'}),
          _w('Canvas', 'Info', 236, 48, 302, 24, {'bg': deck}),
          _w(
            'Canvas',
            'Volume',
            236,
            82,
            302,
            26,
            {'bg': deck},
            {
              'click': 'Volume_drag',
              'drag': 'Volume_drag',
              'release': 'Volume_release',
            },
          ),
          _w(
            'Canvas',
            'Seek',
            12,
            124,
            526,
            16,
            {'bg': deck},
            {
              'click': 'Seek_drag',
              'drag': 'Seek_drag',
              'release': 'Seek_release',
            },
          ),
          metal('BtnPrev', 12, 148, 44, 34),
          metal('BtnPlay', 58, 148, 44, 34),
          metal('BtnPause', 104, 148, 44, 34),
          metal('BtnStop', 150, 148, 44, 34),
          metal('BtnNext', 196, 148, 44, 34),
          metal('BtnEject', 250, 148, 40, 34),
          metal('Shuffle', 346, 153, 92, 24),
          metal('Repeat', 446, 153, 92, 24),
          _w('Frame', 'Divider', 0, 192, 550, 2, {'bg': '#16181d'}),
          // La lista de reproducción.
          _w('Label', 'LblList', 12, 200, 300, 20, {
            ..._label(t(markTr('Lista de reproducción')).toUpperCase()),
            'bg': deck,
            'fg': engraved,
            'font_size': 10,
            'font_bold': true,
          }),
          _w('Label', 'Totals', 312, 200, 226, 20, {
            'text': '',
            'anchor': 'e',
            'bg': deck,
            'fg': engraved,
            'font_size': 10,
          }),
          _w(
            'Treeview',
            'Playlist',
            12,
            224,
            526,
            300,
            {
              'columns': [
                'title|${t(markTr('Título'))}|446',
                'time|${t(markTr('Duración'))}|64',
              ].join('\n'),
            },
            {
              'select': 'Playlist_select',
              'double': 'Playlist_double_click',
              'right': 'Playlist_right_click',
            },
          ),
          listButton('BtnAdd', 12, t(markTr('Añadir…'))),
          listButton('BtnRemove', 100, t(markTr('Quitar…'))),
          listButton('BtnSort', 188, t(markTr('Ordenar…'))),
          listButton('BtnList', 276, t(markTr('Lista…'))),
          _w('Label', 'Times', 368, 532, 170, 28, {
            'text': '0:00/0:00',
            'anchor': 'center',
            'bg': '#000000',
            'fg': '#2df06a',
          }),
          _w(
            'Timer',
            'Tick',
            500,
            200,
            32,
            32,
            {'interval': 50, 'enabled': true},
            {'command': 'Tick_timer'},
          ),
          _w('OpenDialog', 'AddFiles', 460, 200, 32, 32, {
            'title': t(markTr('Añadir canciones')),
            'filter': '${t(markTr('Audio'))}|*.mp3;*.ogg;*.wav',
            'multiple': true,
          }),
          _w('OpenDialog', 'OpenList', 420, 200, 32, 32, {
            'title': t(markTr('Abrir una lista M3U')),
            'filter': '${t(markTr('Lista M3U'))}|*.m3u;*.m3u8',
          }),
          _w('SaveDialog', 'SaveList', 380, 200, 32, 32, {
            'title': t(markTr('Guardar la lista M3U')),
            'filter': '${t(markTr('Lista M3U'))}|*.m3u;*.m3u8',
            'defaultext': '.m3u',
            'filename': t(markTr('lista.m3u')),
          }),
          _w('StatusBar', 'Status', 0, 568, 550, 24, {
            'text': '',
            'icon': 'play',
            'bg': '#1b1d22',
            'fg': '#aab2c0',
          }),
        ]);
  final code =
      '''import json
import math
import os
import random
import struct
import sys
import time
import tkinter as tk
import tkinter.font as tkfont
import wave
import zlib
from tkinter import filedialog, messagebox, ttk

# El empaquetador de las demos instala esto antes de crear el ejecutable.
REQUIRES = ["pygame"]

APP = ${_py(app)}
TRACK_LABEL = ${_py(t(markTr('PISTA')))}
VOL_LABEL = ${_py(t(markTr('VOL')))}
STEREO_LABEL = ${_py(t(markTr('estéreo')))}
MONO_LABEL = ${_py(t(markTr('mono')))}
MODE_NAMES = {
    "stereo": ${_py(t(markTr('Estéreo')))},
    "joint": ${_py(t(markTr('Estéreo conjunto')))},
    "dual": ${_py(t(markTr('Dos canales')))},
    "mono": ${_py(t(markTr('Mono')))},
}
DECIMAL = ${_py(t(markTr(',')))}
SHUFFLE = ${_py(t(markTr('Aleatorio')))}
REPEAT = ${_py(t(markTr('Repetir')))}
PREV = ${_py(t(markTr('Anterior')))}
PLAY = ${_py(t(markTr('Reproducir')))}
PAUSE = ${_py(t(markTr('Pausa')))}
STOP = ${_py(t(markTr('Detener')))}
NEXT = ${_py(t(markTr('Siguiente')))}
EJECT = ${_py(t(markTr('Abrir archivos…')))}
FILES = ${_py(t(markTr('Archivos…')))}
FOLDER = ${_py(t(markTr('Carpeta…')))}
REMOVE_SELECTED = ${_py(t(markTr('Quitar las elegidas')))}
REMOVE_MISSING = ${_py(t(markTr('Quitar las que no se encuentran')))}
CLEAR = ${_py(t(markTr('Vaciar la lista')))}
BY_TITLE = ${_py(t(markTr('Por título')))}
BY_ARTIST = ${_py(t(markTr('Por artista')))}
BY_FILE = ${_py(t(markTr('Por nombre de archivo')))}
RANDOMIZE = ${_py(t(markTr('Al azar')))}
NEW_LIST = ${_py(t(markTr('Nueva lista')))}
OPEN_LIST = ${_py(t(markTr('Abrir una lista M3U…')))}
SAVE_LIST = ${_py(t(markTr('Guardar la lista M3U…')))}
INFO = ${_py(t(markTr('Información del archivo…')))}
FOLDER_TITLE = ${_py(t(markTr('Elija una carpeta con música')))}
INFO_FIELDS = (
    ${_py(t(markTr('Título')))},
    ${_py(t(markTr('Artista')))},
    ${_py(t(markTr('Álbum')))},
    ${_py(t(markTr('Duración')))},
    ${_py(t(markTr('Formato')))},
    ${_py(t(markTr('Tamaño')))},
    ${_py(t(markTr('Archivo')))},
)
HINT = ${_py(t(markTr('Espacio: reproducir o pausa  ·  ←/→: 5 s  ·  ↑/↓: volumen  ·  Supr: quitar')))}
EMPTY = ${_py(t(markTr('Pulse Añadir para elegir canciones MP3, OGG o WAV.')))}
NO_PYGAME = ${_py(t(markTr('Para oír la música hace falta pygame: {0}')))}
NEED_PYGAME = ${_py(t(markTr('Este reproductor usa pygame para el sonido y no está instalado. Instálelo con este comando y vuelva a abrir el reproductor:')))}
COPIED = ${_py(t(markTr('El comando se ha copiado al portapapeles.')))}
NO_AUDIO = ${_py(t(markTr('No se pudo abrir la salida de sonido: {0}')))}
PLAYING = ${_py(t(markTr('Sonando: {0}')))}
PAUSED = ${_py(t(markTr('En pausa: {0}')))}
STOPPED = ${_py(t(markTr('Detenido')))}
CANT_PLAY = ${_py(t(markTr('No se pudo reproducir {0}: {1}')))}
MISSING = ${_py(t(markTr('No se encuentra el archivo: {0}')))}
END = ${_py(t(markTr('Fin de la lista.')))}
ADDED = ${_py(t(markTr('{0} canciones añadidas.')))}
DUPLICATES = ${_py(t(markTr('{0} ya estaban en la lista.')))}
NONE_FOUND = ${_py(t(markTr('No hay archivos MP3, OGG ni WAV en esa carpeta.')))}
REMOVED = ${_py(t(markTr('Quitadas de la lista: {0}.')))}
NOTHING_SELECTED = ${_py(t(markTr('Elija primero una canción de la lista.')))}
SORTED = ${_py(t(markTr('Lista ordenada: {0}.')))}
ASK_CLEAR = ${_py(t(markTr('¿Vaciar la lista de reproducción?')))}
LIST_SAVED = ${_py(t(markTr('Lista guardada en {0}')))}
LIST_OPENED = ${_py(t(markTr('Lista abierta: {0} canciones.')))}
NOT_FOUND = ${_py(t(markTr('{0} no se encontraron.')))}
CANT_SAVE = ${_py(t(markTr('No se pudo guardar: {0}')))}
CANT_OPEN = ${_py(t(markTr('No se pudo abrir la lista: {0}')))}
NO_SEEK = ${_py(t(markTr('No se puede saltar dentro de este archivo.')))}
VOLUME_FMT = ${_py(t(markTr('Volumen: {0} %')))}
SEEK_FMT = ${_py(t(markTr('Ir a {0} / {1}')))}
ON_FMT = ${_py(t(markTr('{0}: activado')))}
OFF_FMT = ${_py(t(markTr('{0}: desactivado')))}
TRACKS = ${_py(t(markTr('Pistas: {0}')))}
RESTORED = ${_py(t(markTr('Lista recuperada: {0} canciones.')))}
'''
      r'''
WINDOWS = sys.platform.startswith("win")
MAC = sys.platform == "darwin"
INSTALL = ("py" if WINDOWS else "python3") + " -m pip install pygame"
AUDIO_EXT = (".mp3", ".ogg", ".wav")
STATE_FILE = "mp3_player.json"
SEEK_STEP = 5
VOLUME_STEP = 5
MAX_TAG = 512 * 1024   # De una etiqueta ID3 enorme (carátulas) basta el principio.
SCAN = 128 * 1024      # Dónde buscar la primera trama MPEG.

UI = "Helvetica"
MONO = "Menlo" if MAC else ("Consolas" if WINDOWS else "DejaVu Sans Mono")
SMALL = 10 if MAC else 8
NORMAL = 12 if MAC else 10

DECK = "#2b2e37"
LCD = "#000000"
GREEN = "#2df06a"
GHOST = "#0c2614"          # Segmentos apagados del LCD.
CELL_OFF = "#0a1a0f"
PEAK = "#c8ccd4"
ENGRAVED = "#8b93a5"
DIM = "#4a505c"
GLYPH = "#1d2026"
PL_BG = "#000000"
PL_FG = "#1fe05a"
PL_CURRENT = "#ffffff"
PL_MISSING = "#5d6470"
PL_SELECT = "#1c3fc8"
BARS = 20
ROWS = 15
KNOB_W = 28


# ------------------------------------------------------------------ utilidades
def data_dir():
    """Carpeta de datos del usuario: AppData en Windows, Application Support
    en macOS y ~/.local/share en Linux."""
    home = os.path.expanduser("~")
    if WINDOWS:
        base = os.environ.get("APPDATA") or home
    elif MAC:
        base = os.path.join(home, "Library", "Application Support")
    else:
        base = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")
    path = os.path.join(base, "DMarlon Studio")
    os.makedirs(path, exist_ok=True)
    return path


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_state(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    os.replace(tmp, path)


def fmt_time(seconds):
    """83 -> 1:23; 3725 -> 1:02:05; None -> vacío."""
    if seconds is None:
        return ""
    total = max(0, int(seconds))
    hours, rest = divmod(total, 3600)
    minutes, secs = divmod(rest, 60)
    return "%d:%02d:%02d" % (hours, minutes, secs) if hours else "%d:%02d" % (minutes, secs)


def fmt_length(seconds):
    return fmt_time(round(seconds)) if seconds else ""


def blend(a, b, t):
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#%02x%02x%02x" % tuple(int(round(x + (y - x) * t)) for x, y in zip(ca, cb))


def ramp(stops, t):
    """Color en t (0..1) de una escala [(posición, color)]."""
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if t <= p1:
            return blend(c0, c1, (t - p0) / float(p1 - p0) if p1 > p0 else 0)
    return stops[-1][1]


LEVEL = [(0.0, "#14c83c"), (0.55, "#d8e81c"), (1.0, "#ff3b1f")]
ROW_COLORS = [ramp(LEVEL, r / float(ROWS - 1)) for r in range(ROWS)]


def audio_files(folder):
    """Los MP3, OGG y WAV de una carpeta y sus subcarpetas, en orden."""
    found = []
    for path, dirs, files in os.walk(folder):
        dirs.sort(key=str.lower)
        for name in sorted(files, key=str.lower):
            if name.lower().endswith(AUDIO_EXT) and not name.startswith("."):
                found.append(os.path.join(path, name))
    return found


# ------------------------------------------------------------------ ID3
ID3_FIELDS = {
    "TIT2": "title", "TPE1": "artist", "TALB": "album",
    "TT2": "title", "TP1": "artist", "TAL": "album",
}


def synchsafe(data):
    """Entero de 7 bits por byte (los tamaños de ID3v2)."""
    value = 0
    for byte in bytearray(data):
        value = (value << 7) | (byte & 0x7F)
    return value


def unsynchronise(data):
    """Deshace la «desincronización» de ID3v2 (FF 00 -> FF)."""
    return data.replace(b"\xff\x00", b"\xff")


def decode_text(data):
    """Texto de un marco ID3v2: el primer byte dice la codificación
    (0 Latin-1, 1 UTF-16 con BOM, 2 UTF-16BE, 3 UTF-8). Varios valores
    (separados por nulos en ID3v2.4) se juntan con « / »."""
    if not data:
        return ""
    encoding, raw = bytearray(data[:1])[0], bytes(data[1:])
    if encoding in (1, 2):
        if len(raw) % 2:
            raw = raw[:-1]
        if encoding == 1 and raw[:2] not in (b"\xff\xfe", b"\xfe\xff"):
            text = raw.decode("utf-16-le", "replace")
        else:
            text = raw.decode("utf-16" if encoding == 1 else "utf-16-be", "replace")
    elif encoding == 3:
        text = raw.decode("utf-8", "replace")
    else:
        text = raw.decode("latin-1")
    parts = [p.replace("﻿", "").strip() for p in text.split("\x00")]
    return " / ".join(p for p in parts if p)


def id3v2_size(header):
    """Bytes que ocupa la etiqueta ID3v2 del principio (0 si no hay)."""
    if len(header) < 10 or header[:3] != b"ID3":
        return 0
    size = synchsafe(header[6:10]) + 10
    if bytearray(header[5:6])[0] & 0x10:
        size += 10  # Pie de la etiqueta (v2.4).
    return size


def parse_id3v2(data):
    """Título, artista y álbum de una etiqueta ID3v2.2, 2.3 o 2.4."""
    tags = {}
    if len(data) < 10 or data[:3] != b"ID3":
        return tags
    major, flags = bytearray(data[3:4])[0], bytearray(data[5:6])[0]
    if major not in (2, 3, 4):
        return tags
    body = data[10:10 + synchsafe(data[6:10])]
    if flags & 0x80 and major < 4:
        body = unsynchronise(body)
    pos = 0
    if flags & 0x40 and major == 3 and len(body) >= 4:
        pos = 4 + struct.unpack(">I", body[:4])[0]
    elif flags & 0x40 and major == 4 and len(body) >= 4:
        pos = synchsafe(body[:4])
    head = 6 if major == 2 else 10
    while pos + head <= len(body):
        if major == 2:
            fid = body[pos:pos + 3]
            size = struct.unpack(">I", b"\x00" + body[pos + 3:pos + 6])[0]
            fflags = 0
        else:
            fid = body[pos:pos + 4]
            raw = body[pos + 4:pos + 8]
            # Algunos programas escriben en v2.4 tamaños normales, no synchsafe.
            if major == 4 and not any(b & 0x80 for b in bytearray(raw)):
                size = synchsafe(raw)
            else:
                size = struct.unpack(">I", raw)[0]
            fflags = struct.unpack(">H", body[pos + 8:pos + 10])[0]
        if not all(48 <= c <= 57 or 65 <= c <= 90 for c in bytearray(fid)):
            break  # Relleno o basura: se acabaron los marcos.
        start = pos + head
        frame = body[start:start + size]
        pos = start + size
        key = ID3_FIELDS.get(fid.decode("latin-1"))
        if not key or key in tags:
            continue
        compressed = False
        if major == 4:
            if fflags & 0x0004:
                continue  # Cifrado.
            if fflags & 0x0040:
                frame = frame[1:]  # Grupo.
            if fflags & 0x0001:
                frame = frame[4:]  # Longitud de los datos.
            if fflags & 0x0002:
                frame = unsynchronise(frame)
            compressed = bool(fflags & 0x0008)
        elif major == 3:
            if fflags & 0x0040:
                continue
            if fflags & 0x0080:
                frame = frame[4:]
                compressed = True
            if fflags & 0x0020:
                frame = frame[1:]
        if compressed:
            try:
                frame = zlib.decompress(frame)
            except zlib.error:
                continue
        text = decode_text(frame)
        if text:
            tags[key] = text
    return tags


def parse_id3v1(data):
    """Título, artista y álbum de los últimos 128 bytes («TAG»)."""
    data = data[-128:]
    if len(data) < 128 or data[:3] != b"TAG":
        return {}
    tags = {}
    for key, a, b in (("title", 3, 33), ("artist", 33, 63), ("album", 63, 93)):
        value = data[a:b].split(b"\x00")[0].decode("latin-1").strip()
        if value:
            tags[key] = value
    return tags


# ------------------------------------------------------------- tramas MPEG
BITRATES = {
    (1, 1): (0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448),
    (1, 2): (0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384),
    (1, 3): (0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320),
    (2, 1): (0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256),
    (2, 2): (0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160),
}
BITRATES[(2, 3)] = BITRATES[(2, 2)]
for _layer in (1, 2, 3):
    BITRATES[(25, _layer)] = BITRATES[(2, _layer)]
SAMPLE_RATES = {1: (44100, 48000, 32000), 2: (22050, 24000, 16000), 25: (11025, 12000, 8000)}
MODES = ("stereo", "joint", "dual", "mono")


def parse_frame_header(data, pos=0):
    """La cabecera de 4 bytes de una trama MPEG en pos (None si no lo es)."""
    if pos < 0 or pos + 4 > len(data):
        return None
    b0, b1, b2, b3 = bytearray(data[pos:pos + 4])
    if b0 != 0xFF or (b1 & 0xE0) != 0xE0:
        return None
    version = {0: 25, 2: 2, 3: 1}.get((b1 >> 3) & 3)
    layer = {1: 3, 2: 2, 3: 1}.get((b1 >> 1) & 3)
    index, rate_index = b2 >> 4, (b2 >> 2) & 3
    if version is None or layer is None or index in (0, 15) or rate_index == 3:
        return None
    bitrate = BITRATES[(version, layer)][index]
    rate = SAMPLE_RATES[version][rate_index]
    padding = (b2 >> 1) & 1
    if layer == 1:
        samples = 384
        length = (12 * bitrate * 1000 // rate + padding) * 4
    elif layer == 2:
        samples = 1152
        length = 144 * bitrate * 1000 // rate + padding
    else:
        samples = 1152 if version == 1 else 576
        length = (144 if version == 1 else 72) * bitrate * 1000 // rate + padding
    return {
        "version": version, "layer": layer, "bitrate": bitrate, "rate": rate,
        "mode": MODES[b3 >> 6], "samples": samples, "length": length,
    }


def find_frame(data, start=0):
    """(posición, cabecera) de la primera trama MPEG, comprobada con la
    siguiente para no confundirse con bytes FF sueltos; (-1, None) si no hay."""
    pos = data.find(b"\xff", start)
    while 0 <= pos <= len(data) - 4:
        header = parse_frame_header(data, pos)
        if header:
            after = pos + header["length"]
            if after + 4 > len(data):
                return pos, header
            other = parse_frame_header(data, after)
            if other and all(other[k] == header[k] for k in ("version", "layer", "rate")):
                return pos, header
        pos = data.find(b"\xff", pos + 1)
    return -1, None


def parse_vbr(data, pos, header):
    """(tramas, bytes, es_vbr) de la cabecera Xing/Info o VBRI de la primera
    trama; (None, None, False) si no tiene."""
    if header["version"] == 1:
        side = 17 if header["mode"] == "mono" else 32
    else:
        side = 9 if header["mode"] == "mono" else 17
    at = pos + 4 + side
    try:
        tag = data[at:at + 4]
        if tag in (b"Xing", b"Info"):
            flags = struct.unpack(">I", data[at + 4:at + 8])[0]
            cursor, frames, size = at + 8, None, None
            if flags & 1:
                frames = struct.unpack(">I", data[cursor:cursor + 4])[0]
                cursor += 4
            if flags & 2:
                size = struct.unpack(">I", data[cursor:cursor + 4])[0]
            return frames, size, tag == b"Xing"
        at = pos + 4 + 32
        if data[at:at + 4] == b"VBRI":
            size, frames = struct.unpack(">II", data[at + 10:at + 18])
            return frames, size, True
    except struct.error:
        pass
    return None, None, False


# ----------------------------------------------------------------- canciones
class Track:
    """Una canción de la lista con lo que se sabe de ella."""

    def __init__(self, path):
        self.path = path
        self.title = self.artist = self.album = ""
        self.duration = None
        self.bitrate = 0       # kbps (la media si es VBR).
        self.rate = 0          # Hz
        self.mode = ""         # stereo, joint, dual o mono.
        self.vbr = False
        self.codec = ""
        self.size = 0
        self.missing = False

    @property
    def name(self):
        """«Artista - Título» (o el nombre del archivo, si no hay etiquetas)."""
        title = self.title or os.path.splitext(os.path.basename(self.path))[0]
        return "%s - %s" % (self.artist, title) if self.artist else title


def read_mp3(track, f, size):
    tags, start = {}, 0
    tag_size = id3v2_size(f.read(10))
    if tag_size:
        f.seek(0)
        tags = parse_id3v2(f.read(min(tag_size, MAX_TAG)))
        start = tag_size
    f.seek(start)
    data = f.read(SCAN)
    tail = b""
    if size >= 128:
        f.seek(size - 128)
        tail = f.read(128)
    v1 = parse_id3v1(tail)
    for key, value in v1.items():
        tags.setdefault(key, value)
    track.title = tags.get("title", "")
    track.artist = tags.get("artist", "")
    track.album = tags.get("album", "")
    pos, header = find_frame(data)
    if not header:
        return
    version = "2.5" if header["version"] == 25 else str(header["version"])
    track.codec = "MPEG-%s Layer %s" % (version, "I" * header["layer"])
    track.rate, track.mode, track.bitrate = header["rate"], header["mode"], header["bitrate"]
    audio = size - start - pos - (128 if v1 or tail[:3] == b"TAG" else 0)
    frames, nbytes, vbr = parse_vbr(data, pos, header)
    if frames:
        track.duration = frames * header["samples"] / float(header["rate"])
        track.vbr = vbr
        if vbr and track.duration > 0:
            track.bitrate = int(round((nbytes or audio) * 8 / track.duration / 1000))
    elif header["bitrate"]:
        track.duration = max(0, audio) * 8.0 / (header["bitrate"] * 1000)


def read_ogg(track, f, size):
    head = f.read(65536)
    at = head.find(b"\x01vorbis")
    if at >= 0 and len(head) >= at + 28:
        channels = bytearray(head[at + 11:at + 12])[0]
        track.rate = struct.unpack("<I", head[at + 12:at + 16])[0]
        nominal = struct.unpack("<i", head[at + 20:at + 24])[0]
        track.codec = "Ogg Vorbis"
        track.mode = "mono" if channels == 1 else "stereo"
        track.bitrate = nominal // 1000 if nominal > 0 else 0
    at = head.find(b"\x03vorbis")
    if at >= 0:
        try:
            cursor = at + 7
            vendor = struct.unpack("<I", head[cursor:cursor + 4])[0]
            cursor += 4 + vendor
            count = struct.unpack("<I", head[cursor:cursor + 4])[0]
            cursor += 4
            for _ in range(min(count, 200)):
                length = struct.unpack("<I", head[cursor:cursor + 4])[0]
                cursor += 4
                key, _, value = head[cursor:cursor + length].decode("utf-8", "replace").partition("=")
                cursor += length
                field = {"TITLE": "title", "ARTIST": "artist", "ALBUM": "album"}.get(key.upper())
                if field and value and not getattr(track, field):
                    setattr(track, field, value.strip())
        except struct.error:
            pass
    f.seek(max(0, size - 65536))
    tail = f.read()
    at = tail.rfind(b"OggS")
    if at >= 0 and len(tail) >= at + 14 and track.rate:
        granule = struct.unpack("<q", tail[at + 6:at + 14])[0]
        if granule > 0:
            track.duration = granule / float(track.rate)
            track.bitrate = int(round(size * 8 / track.duration / 1000))
            track.vbr = True


def read_wav(track, f):
    w = wave.open(f)
    rate, channels, width, frames = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
    track.codec = "WAV PCM"
    track.rate = rate
    track.mode = "mono" if channels == 1 else "stereo"
    track.bitrate = rate * channels * width * 8 // 1000
    track.duration = frames / float(rate) if rate else None


def read_info(path):
    """Una canción con sus etiquetas, formato y duración leídos del archivo
    (sin bibliotecas externas). Si no se puede leer, solo con el nombre."""
    track = Track(path)
    try:
        track.size = os.path.getsize(path)
        ext = os.path.splitext(path)[1].lower()
        with open(path, "rb") as f:
            if ext == ".wav":
                read_wav(track, f)
            elif ext == ".ogg":
                read_ogg(track, f, track.size)
            else:
                read_mp3(track, f, track.size)
    except OSError:
        track.missing = not os.path.isfile(path)
    except Exception:
        pass  # Un archivo dañado no debe parar la lista.
    return track


def describe(track):
    parts = [track.codec] if track.codec else []
    if track.bitrate:
        parts.append("%d kbps%s" % (track.bitrate, " VBR" if track.vbr else ""))
    if track.rate:
        khz = ("%.1f" % (track.rate / 1000.0)).rstrip("0").rstrip(".")
        parts.append(khz.replace(".", DECIMAL) + " kHz")
    if track.mode:
        parts.append(MODE_NAMES.get(track.mode, track.mode))
    return "  ·  ".join(parts) or "–"


# ------------------------------------------------------------------- la lista
def path_key(path):
    return os.path.normcase(os.path.abspath(path))


class Playlist:
    """Las canciones, la que suena y el orden de reproducción (con
    aleatorio y repetir). No sabe nada de la ventana ni del sonido."""

    def __init__(self, rng=None):
        self.tracks = []
        self.current = None
        self.shuffle = False
        self.repeat = False
        self.rng = rng or random.Random()
        self.order = []  # Orden aleatorio: cada canción una vez por vuelta.

    def __len__(self):
        return len(self.tracks)

    def track(self, index=None):
        index = self.current if index is None else index
        return self.tracks[index] if index is not None and 0 <= index < len(self.tracks) else None

    def add(self, paths, reader=read_info):
        """Añade las que no estén ya: (añadidas, repetidas)."""
        known = set(path_key(t.path) for t in self.tracks)
        added = repeated = 0
        for path in paths:
            key = path_key(path)
            if key in known:
                repeated += 1
                continue
            known.add(key)
            self.tracks.append(reader(os.path.abspath(path)))
            added += 1
        self.order = []
        return added, repeated

    def _index_of(self, track):
        for index, other in enumerate(self.tracks):
            if other is track:
                return index
        return None

    def remove(self, indexes):
        drop = set(i for i in indexes if 0 <= i < len(self.tracks))
        current = self.track()
        self.tracks = [t for i, t in enumerate(self.tracks) if i not in drop]
        self.current = self._index_of(current)
        self.order = []
        return len(drop)

    def clear(self):
        self.tracks, self.current, self.order = [], None, []

    def sort(self, how):
        """how: title, artist, file o shuffle. La que suena sigue siendo la misma."""
        current = self.track()
        if how == "shuffle":
            self.rng.shuffle(self.tracks)
        else:
            def title(t):
                return (t.title or os.path.splitext(os.path.basename(t.path))[0]).lower()
            keys = {
                "title": lambda t: (title(t), t.artist.lower()),
                "artist": lambda t: (not t.artist, t.artist.lower(), t.album.lower(), title(t)),
                "file": lambda t: (os.path.basename(t.path).lower(), t.path.lower()),
            }
            self.tracks.sort(key=keys[how])
        self.current = self._index_of(current)
        self.order = []

    def total(self, indexes=None):
        """(segundos, cuántas sin duración conocida)."""
        chosen = range(len(self.tracks)) if indexes is None else indexes
        seconds, unknown = 0.0, 0
        for index in chosen:
            duration = self.tracks[index].duration
            if duration:
                seconds += duration
            else:
                unknown += 1
        return seconds, unknown

    def _reshuffle(self, first=None):
        rest = [i for i in range(len(self.tracks)) if i != first]
        self.rng.shuffle(rest)
        if first is None and self.current is not None and len(rest) > 1 and rest[0] == self.current:
            rest.append(rest.pop(0))  # Que la vuelta nueva no empiece repitiendo.
        self.order = ([first] if first is not None else []) + rest

    def select(self, index, chosen=False):
        """Pasa a sonar index. chosen: la eligió el usuario (en aleatorio, la
        vuelta empieza por ella)."""
        self.current = index
        if self.shuffle and (chosen or index not in self.order):
            self._reshuffle(index)

    def next_index(self, step=1, auto=False):
        """La canción de después (step=1) o de antes (-1). auto: porque acabó
        la anterior; sin repetir, al final de la lista da None."""
        count = len(self.tracks)
        if count == 0:
            return None
        if self.shuffle and count > 1:
            if sorted(self.order) != list(range(count)):
                self._reshuffle(self.current)
            pos = self.order.index(self.current) if self.current in self.order else -1
            target = pos + step
            if 0 <= target < count:
                return self.order[target]
            if auto and not self.repeat:
                return None
            if target >= count:
                self._reshuffle()
                return self.order[0]
            return self.order[-1]
        if self.current is None:
            return 0 if step > 0 else count - 1
        target = self.current + step
        if 0 <= target < count:
            return target
        if auto and not self.repeat:
            return None
        return target % count


# ----------------------------------------------------------------------- M3U
def m3u_path(path, folder):
    """Ruta relativa si la canción está dentro de la carpeta de la lista;
    absoluta si no (u otra unidad en Windows)."""
    try:
        rel = os.path.relpath(path, folder)
    except ValueError:
        return path
    if rel == os.pardir or rel.startswith(os.pardir + os.sep):
        return path
    return rel


def save_m3u(path, tracks):
    folder = os.path.dirname(os.path.abspath(path))
    lines = ["#EXTM3U"]
    for track in tracks:
        seconds = int(round(track.duration)) if track.duration else -1
        lines.append("#EXTINF:%d,%s" % (seconds, track.name))
        lines.append(m3u_path(track.path, folder))
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def load_m3u(path):
    """(rutas absolutas que existen, cuántas no se encontraron)."""
    with open(path, "rb") as f:
        raw = f.read()
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")
    folder = os.path.dirname(os.path.abspath(path))
    found, missing = [], 0
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.lower().startswith("file://"):
            from urllib.parse import unquote, urlparse
            line = unquote(urlparse(line).path)
            if WINDOWS and len(line) > 2 and line[0] == "/" and line[2] == ":":
                line = line[1:]
        elif "://" in line:
            missing += 1  # Emisoras de internet: este reproductor no las abre.
            continue
        if not WINDOWS:
            line = line.replace("\\", "/")
        full = os.path.normpath(line if os.path.isabs(line) else os.path.join(folder, line))
        if os.path.isfile(full) and full.lower().endswith(AUDIO_EXT):
            found.append(full)
        else:
            missing += 1
    return found, missing


# --------------------------------------------------------------------- sonido
NEEDS_PYGAME = "pygame"


class Engine:
    """El sonido, con pygame.mixer.music (MP3, OGG y WAV). Sin pygame, ok es
    False y error dice por qué."""

    def __init__(self):
        self.pygame = None
        self.error = None
        self.path = None
        self.playing = self.paused = False
        self.offset = 0.0
        self.volume = 0.8
        os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
        try:
            import pygame
        except ImportError:
            self.error = NEEDS_PYGAME
            return
        try:
            pygame.mixer.init()
        except Exception as error:
            self.error = str(error) or error.__class__.__name__
            return
        self.pygame = pygame

    @property
    def ok(self):
        return self.pygame is not None

    @property
    def music(self):
        return self.pygame.mixer.music

    def play(self, path):
        self.music.load(path)
        self.music.set_volume(self.volume)
        self.music.play()
        self.path, self.offset = path, 0.0
        self.playing, self.paused = True, False

    def pause(self):
        if self.playing and not self.paused:
            self.music.pause()
            self.paused = True

    def resume(self):
        if self.playing and self.paused:
            self.music.unpause()
            self.paused = False

    def stop(self):
        if self.ok and self.playing:
            self.music.stop()
            try:
                self.music.unload()  # Suelta el archivo (pygame 2).
            except Exception:
                pass
        self.playing = self.paused = False
        self.offset = 0.0

    def seek(self, seconds):
        """Salta a seconds; False si el formato no lo permite."""
        if not self.playing:
            return False
        seconds = max(0.0, seconds)
        try:
            self.music.set_pos(seconds)
            self.offset = seconds - max(0, self.music.get_pos()) / 1000.0
        except Exception:
            try:
                self.music.play(start=seconds)
                self.offset = seconds
                if self.paused:
                    self.music.pause()
            except Exception:
                return False
        return True

    def position(self):
        if not self.playing:
            return 0.0
        return max(0.0, self.offset + max(0, self.music.get_pos()) / 1000.0)

    def finished(self):
        """Acabó la canción (sonando y sin pausa, pero el mezclador callado)."""
        return self.playing and not self.paused and not self.music.get_busy()

    def set_volume(self, value):
        self.volume = max(0.0, min(1.0, value))
        if self.ok:
            self.music.set_volume(self.volume)

    def quit(self):
        if self.ok:
            try:
                self.pygame.mixer.quit()
            except Exception:
                pass


# ------------------------------------------------------------------- espectro
class Spectrum:
    """Barras que bailan mientras suena: una animación que sigue al estado
    de la reproducción y al volumen (pygame no da las muestras del sonido)."""

    def __init__(self, bars=BARS, rng=None):
        self.rng = rng or random.Random(7)
        self.values = [0.0] * bars
        self.peaks = [0.0] * bars
        self.hold = [0] * bars
        self.phase = 0.0

    def step(self, state, level=1.0, dt=0.05):
        """state: play, pause o stop. En pausa, todo se queda quieto."""
        if state == "pause":
            return
        count = len(self.values)
        if state == "play" and level > 0:
            self.phase += dt
            beat = 0.62 + 0.38 * max(0.0, math.cos(self.phase * math.pi * 4)) ** 6
            raw = []
            for i in range(count):
                tilt = 1.0 - 0.5 * i / float(count - 1)
                raw.append(tilt * beat * (0.3 + 0.7 * self.rng.random()))
            amp = 0.45 + 0.55 * level
            for i in range(count):
                left, right = raw[max(0, i - 1)], raw[min(count - 1, i + 1)]
                target = min(1.0, amp * (left + 2 * raw[i] + right) / 4.0 * 1.25)
                self.values[i] = max(target, self.values[i] - 0.07)
        else:
            self.values = [max(0.0, v - 0.07) for v in self.values]
        for i, value in enumerate(self.values):
            if value >= self.peaks[i]:
                self.peaks[i], self.hold[i] = value, 8
            elif self.hold[i] > 0:
                self.hold[i] -= 1
            else:
                self.peaks[i] = max(0.0, self.peaks[i] - 0.025)


# -------------------------------------------------------------------- dibujo
SEGMENTS = {
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
    "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg",
    "-": "g", " ": "",
}


def segment_polys(x, y, w, h, t):
    """Los siete segmentos (a-g) de un dígito, con las puntas en bisel."""
    half = t / 2.0
    left, right, top, bottom = x + half, x + w - half, y + half, y + h - half
    mid = y + h / 2.0
    gap = 1

    def horiz(cy, x1, x2):
        return (x1, cy, x1 + half, cy - half, x2 - half, cy - half, x2, cy, x2 - half, cy + half, x1 + half, cy + half)

    def vert(cx, y1, y2):
        return (cx, y1, cx + half, y1 + half, cx + half, y2 - half, cx, y2, cx - half, y2 - half, cx - half, y1 + half)

    return {
        "a": horiz(top, left + gap, right - gap),
        "g": horiz(mid, left + gap, right - gap),
        "d": horiz(bottom, left + gap, right - gap),
        "f": vert(left, top + gap, mid - gap),
        "b": vert(right, top + gap, mid - gap),
        "e": vert(left, mid + gap, bottom - gap),
        "c": vert(right, mid + gap, bottom - gap),
    }


METAL = [(0.0, "#d3d7de"), (0.45, "#9ba1ac"), (0.55, "#8a909b"), (1.0, "#5c616c")]
METAL_DOWN = [(0.0, "#5a5f69"), (0.5, "#7a808b"), (1.0, "#959ba6")]


def draw_metal(canvas, w, h, pressed=False, tag="face"):
    """Fondo de botón de metal cepillado, con relieve (o hundido)."""
    canvas.delete(tag)
    stops = METAL_DOWN if pressed else METAL
    for y in range(h):
        canvas.create_line(0, y, w, y, fill=ramp(stops, y / float(max(1, h - 1))), tags=tag)
    light, dark = ("#40444d", "#b5bac3") if pressed else ("#f2f4f7", "#3a3e46")
    canvas.create_line(1, h - 2, 1, 1, w - 2, 1, fill=light, tags=tag)
    canvas.create_line(1, h - 2, w - 2, h - 2, w - 2, 1, fill=dark, tags=tag)
    canvas.create_rectangle(0, 0, w - 1, h - 1, outline="#121418", tags=tag)


def draw_glyph(canvas, kind, cx, cy, color=GLYPH):
    def rect(x0, y0, x1, y1):
        canvas.create_rectangle(x0, y0, x1, y1, fill=color, outline="", tags="face")

    def poly(*points):
        canvas.create_polygon(*points, fill=color, outline="", tags="face")

    if kind == "play":
        poly(cx - 5, cy - 7, cx - 5, cy + 7, cx + 7, cy)
    elif kind == "pause":
        rect(cx - 6, cy - 6, cx - 2, cy + 7)
        rect(cx + 2, cy - 6, cx + 6, cy + 7)
    elif kind == "stop":
        rect(cx - 6, cy - 6, cx + 6, cy + 6)
    elif kind == "prev":
        rect(cx - 9, cy - 6, cx - 6, cy + 6)
        poly(cx + 1, cy - 6, cx - 6, cy, cx + 1, cy + 6)
        poly(cx + 8, cy - 6, cx + 1, cy, cx + 8, cy + 6)
    elif kind == "next":
        rect(cx + 6, cy - 6, cx + 9, cy + 6)
        poly(cx - 1, cy - 6, cx + 6, cy, cx - 1, cy + 6)
        poly(cx - 8, cy - 6, cx - 1, cy, cx - 8, cy + 6)
    elif kind == "eject":
        poly(cx - 7, cy + 1, cx + 7, cy + 1, cx, cy - 7)
        rect(cx - 7, cy + 3, cx + 7, cy + 6)


def size(widget):
    """Ancho y alto con los que se colocó un componente."""
    info = widget.place_info()
    return int(info.get("width") or 0), int(info.get("height") or 0)


# ------------------------------------------------------------------- ventana
class Form1(FormDesign):
    def form_create(self):
        self.list = Playlist()
        self.engine = Engine()
        self.spectrum = Spectrum(BARS)
        self.state_path = os.path.join(data_dir(), STATE_FILE)
        self.volume = 80
        self.remaining = False
        self.pressed = None
        self.seeking = None
        self.flash_text, self.flash_until = None, 0.0
        self.marquee_text = None
        self.scroll_width = 0
        self.clock_text = None
        self.shown = {}
        self.warned = False
        self.marquee_font = tkfont.Font(family=MONO, size=NORMAL + 1)
        self.buttons = {
            str(self.BtnPrev): ("prev", PREV, lambda: self.move(-1)),
            str(self.BtnPlay): ("play", PLAY, self.play),
            str(self.BtnPause): ("pause", PAUSE, self.pause),
            str(self.BtnStop): ("stop", STOP, self.stop),
            str(self.BtnNext): ("next", NEXT, lambda: self.move(1)),
            str(self.BtnEject): ("eject", EJECT, lambda: self.add_files(play=True)),
            str(self.Shuffle): ("shuffle", SHUFFLE, self.toggle_shuffle),
            str(self.Repeat): ("repeat", REPEAT, self.toggle_repeat),
        }
        self.setup_style()
        self.build_lcd()
        self.build_info()
        self.build_seek()
        self.build_volume()
        self.make_menus()
        self.bind_keys()
        restored = self.restore()
        for name in self.buttons:
            self.draw_button(self.root.nametowidget(name))
        self.fill()
        self.track_changed()
        self.draw_volume()
        self.Playlist.focus_set()
        if not self.engine.ok:
            self.require_audio(explain=False)
        elif restored:
            self.status(RESTORED.format(len(self.list)), "check")
        else:
            self.status(HINT, "info")

    # ------------------------------------------------------------ aspecto
    def setup_style(self):
        style = ttk.Style()
        try:
            style.theme_use("clam")  # El único tema que deja pintar la lista.
        except tk.TclError:
            pass
        row = 20 if MAC else 18
        style.configure("Skin.Treeview", background=PL_BG, fieldbackground=PL_BG, foreground=PL_FG,
                        borderwidth=0, rowheight=row, font=(UI, NORMAL))
        style.map("Skin.Treeview", background=[("selected", PL_SELECT)], foreground=[("selected", "#ffffff")])
        style.layout("Skin.Treeview", [("Treeview.treearea", {"sticky": "nswe"})])
        style.configure("Vertical.TScrollbar", background="#3a3e48", troughcolor="#121317",
                        bordercolor="#121317", arrowcolor="#c9ced8", lightcolor="#4a4f5b",
                        darkcolor="#23262d", gripcount=0)
        style.map("Vertical.TScrollbar", background=[("active", "#4a4f5b")])
        tree = self.Playlist
        tree.configure(style="Skin.Treeview", show="", selectmode="extended")
        tree.column("title", stretch=True)
        tree.column("time", anchor="e", stretch=False)
        tree.tag_configure("current", foreground=PL_CURRENT)
        tree.tag_configure("missing", foreground=PL_MISSING)
        self.Times.configure(font=(MONO, NORMAL))
        for button in (self.BtnAdd, self.BtnRemove, self.BtnSort, self.BtnList):
            button.configure(activebackground="#4a505d", activeforeground="#ffffff", cursor="hand2")

    def build_lcd(self):
        c = self.Lcd
        w, h = size(c)
        c.create_rectangle(0, 0, w - 1, h - 1, outline="#1c2027")
        c.create_polygon(9, 12, 9, 26, 21, 19, fill=GREEN, outline="", tags=("icon", "icon_play"))
        c.create_rectangle(9, 12, 13, 26, fill=GREEN, outline="", tags=("icon", "icon_pause"))
        c.create_rectangle(17, 12, 21, 26, fill=GREEN, outline="", tags=("icon", "icon_pause"))
        c.create_rectangle(9, 13, 21, 25, fill=GREEN, outline="", tags=("icon", "icon_stop"))
        # Reloj de siete segmentos: signo, minutos, dos puntos y segundos.
        self.cells = []
        for x, width in ((30, 10), (44, 20), (68, 20), (102, 20), (126, 20)):
            polys = segment_polys(x, 8, width, 36, 4)
            self.cells.append(dict((k, c.create_polygon(*p, fill=GHOST, outline="")) for k, p in polys.items()))
        self.colon = [c.create_rectangle(94, y, 98, y + 4, fill=GHOST, outline="") for y in (17, 31)]
        c.create_text(w - 8, 9, anchor="ne", text=TRACK_LABEL, fill="#1e7a3c", font=(MONO, SMALL))
        self.counter = c.create_text(w - 8, 24, anchor="ne", text="", fill=GREEN, font=(MONO, SMALL + 1, "bold"))
        # Espectro: BARS barras de ROWS celdas, más la marca del pico.
        base = h - 5
        self.grid = []
        for i in range(BARS):
            x = 7 + i * 10
            column = [c.create_rectangle(x, base - r * 3 - 2, x + 8, base - r * 3, fill=CELL_OFF, outline="")
                      for r in range(ROWS)]
            self.grid.append(column)
        self.peak_items = [c.create_rectangle(7 + i * 10, base, 15 + i * 10, base + 1, fill=PEAK, outline="",
                                              state="hidden") for i in range(BARS)]
        self.lit = [0] * BARS
        self.peak_rows = [-1] * BARS
        self.spectrum_base = base

    def build_info(self):
        c = self.Info
        small = (UI, SMALL, "bold")
        # Hasta 4 cifras de kbps (un WAV de CD son 1411).
        c.create_rectangle(0, 2, 44, 21, fill=LCD, outline="#15171c")
        self.kbps = c.create_text(40, 12, anchor="e", text="", fill=GREEN, font=(MONO, NORMAL, "bold"))
        c.create_text(49, 12, anchor="w", text="kbps", fill=ENGRAVED, font=small)
        c.create_rectangle(88, 2, 114, 21, fill=LCD, outline="#15171c")
        self.khz = c.create_text(110, 12, anchor="e", text="", fill=GREEN, font=(MONO, NORMAL, "bold"))
        c.create_text(119, 12, anchor="w", text="kHz", fill=ENGRAVED, font=small)
        self.vbr_item = c.create_text(154, 12, anchor="w", text="VBR", fill=DIM, font=small)
        self.mono_item = c.create_text(194, 12, anchor="w", text=MONO_LABEL, fill=DIM, font=small)
        w, _ = size(c)
        self.stereo_item = c.create_text(w - 2, 12, anchor="e", text=STEREO_LABEL, fill=DIM, font=small)

    def build_seek(self):
        c = self.Seek
        w, h = size(c)
        c.create_rectangle(0, 4, w - 1, h - 5, fill="#121317", outline="#0b0c0f")
        c.create_line(1, h - 4, w - 1, h - 4, fill="#3d414b")
        c.create_rectangle(1, 5, 1, h - 6, fill="#1d6b35", outline="", tags="fill")
        for y in range(1, h - 1):
            c.create_line(0, y, KNOB_W, y, fill=ramp(METAL, (y - 1) / float(h - 3)), tags="knob")
        c.create_rectangle(0, 1, KNOB_W - 1, h - 2, outline="#121418", tags="knob")
        c.create_line(KNOB_W // 2 - 3, 4, KNOB_W // 2 - 3, h - 4, fill="#5c616c", tags="knob")
        c.create_line(KNOB_W // 2, 4, KNOB_W // 2, h - 4, fill="#5c616c", tags="knob")
        c.create_line(KNOB_W // 2 + 3, 4, KNOB_W // 2 + 3, h - 4, fill="#5c616c", tags="knob")
        c.itemconfigure("knob", state="hidden")
        self.seek_x = 0

    def build_volume(self):
        c = self.Volume
        w, h = size(c)
        c.create_text(0, h // 2, anchor="w", text=VOL_LABEL, fill=ENGRAVED, font=(UI, SMALL, "bold"))
        self.vol_x0, self.vol_x1 = 36, w - 2
        c.create_rectangle(self.vol_x0, 9, self.vol_x1, h - 9, fill="#121317", outline="#0b0c0f")
        c.create_rectangle(self.vol_x0 + 1, 10, self.vol_x0 + 1, h - 10, fill=GREEN, outline="", tags="fill")
        for y in range(2, h - 2):
            c.create_line(0, y, 14, y, fill=ramp(METAL, (y - 2) / float(h - 5)), tags="knob")
        c.create_rectangle(0, 2, 13, h - 3, outline="#121418", tags="knob")
        c.create_line(4, h // 2, 10, h // 2, fill="#4a4f59", tags="knob")
        self.vol_knob = 0

    def draw_button(self, widget, pressed=False):
        kind, label, _ = self.buttons[str(widget)]
        w, h = size(widget)
        if kind in ("shuffle", "repeat"):
            on = self.list.shuffle if kind == "shuffle" else self.list.repeat
            draw_metal(widget, w, h, pressed or on)
            shift = 1 if pressed or on else 0
            led = "#3cff74" if on else "#163a20"
            widget.create_rectangle(8 + shift, h // 2 - 3 + shift, 16 + shift, h // 2 + 3 + shift,
                                    fill=led, outline="#0c1f12", tags="face")
            widget.create_text(22 + shift, h // 2 + shift, anchor="w", text=label, fill=GLYPH,
                               font=(UI, SMALL, "bold"), tags="face")
        else:
            draw_metal(widget, w, h, pressed)
            shift = 1 if pressed else 0
            draw_glyph(widget, kind, w // 2 + shift, h // 2 + shift)

    # -------------------------------------------------------------- menús
    def make_menus(self):
        def menu(items):
            m = tk.Menu(self.root, tearoff=0)
            for label, action in items:
                if label is None:
                    m.add_separator()
                else:
                    m.add_command(label=label, command=action)
            return m

        self.menus = {
            "add": menu([(FILES, self.add_files), (FOLDER, self.add_folder)]),
            "remove": menu([(REMOVE_SELECTED, self.remove_selected), (REMOVE_MISSING, self.remove_missing),
                            (None, None), (CLEAR, self.clear_list)]),
            "sort": menu([(BY_TITLE, lambda: self.sort_by("title")), (BY_ARTIST, lambda: self.sort_by("artist")),
                          (BY_FILE, lambda: self.sort_by("file")), (None, None),
                          (RANDOMIZE, lambda: self.sort_by("shuffle"))]),
            "list": menu([(NEW_LIST, self.clear_list), (None, None), (OPEN_LIST, self.open_list),
                          (SAVE_LIST, self.save_list)]),
            "context": menu([(PLAY, self.play_selected), (REMOVE_SELECTED, self.remove_selected),
                             (None, None), (INFO, self.show_info)]),
        }

    def popup(self, name, widget):
        menu = self.menus[name]
        try:
            menu.tk_popup(widget.winfo_rootx(), widget.winfo_rooty() + widget.winfo_height())
        finally:
            menu.grab_release()

    def bind_keys(self):
        keys = [
            ("<space>", self.key_space),
            ("<Left>", lambda e: self.key_seek(-SEEK_STEP)),
            ("<Right>", lambda e: self.key_seek(SEEK_STEP)),
            ("<Up>", lambda e: self.key_volume(VOLUME_STEP)),
            ("<Down>", lambda e: self.key_volume(-VOLUME_STEP)),
            ("<Return>", self.key_enter),
            ("<KP_Enter>", self.key_enter),
            ("<Delete>", self.key_delete),
            ("<BackSpace>", self.key_delete),
        ]
        for widget in (self.root, self.Playlist):
            for sequence, handler in keys:
                widget.bind(sequence, handler)
        for modifier in ("Control", "Command"):
            try:
                self.Playlist.bind("<%s-a>" % modifier, self.select_all)
            except tk.TclError:
                pass  # Cmd solo existe en macOS.

    # ------------------------------------------------------------- estado
    def status(self, text, icon="info"):
        self.Status.set(text, icon=icon)

    def flash(self, text, seconds=1.5):
        """Un aviso corto en la pantalla del título."""
        self.flash_text, self.flash_until = text, time.monotonic() + seconds
        self.set_marquee(text)

    def play_state(self):
        if not self.engine.playing:
            return "stop"
        return "pause" if self.engine.paused else "play"

    def position(self):
        if self.seeking is not None:
            return self.seeking
        return self.engine.position() if self.engine.playing else 0.0

    def save(self):
        data = {
            "tracks": [t.path for t in self.list.tracks],
            "current": self.list.current,
            "volume": self.volume,
            "shuffle": self.list.shuffle,
            "repeat": self.list.repeat,
            "remaining": self.remaining,
        }
        try:
            save_state(self.state_path, data)
            return True
        except OSError:
            return False

    def restore(self):
        data = load_state(self.state_path)
        paths = [p for p in data.get("tracks") or [] if isinstance(p, str)]
        self.list.add(paths)
        current = data.get("current")
        if isinstance(current, int) and 0 <= current < len(self.list):
            self.list.current = current
        self.list.shuffle = bool(data.get("shuffle"))
        self.list.repeat = bool(data.get("repeat"))
        self.remaining = bool(data.get("remaining"))
        volume = data.get("volume", 80)
        self.set_volume(volume if isinstance(volume, (int, float)) else 80, flash=False)
        return bool(paths)

    # ---------------------------------------------------------- la lista
    def row_tags(self, index):
        if index == self.list.current:
            return ("current",)
        return ("missing",) if self.list.tracks[index].missing else ()

    def fill(self, select=()):
        tree = self.Playlist
        tree.delete(*tree.get_children())
        for index, track in enumerate(self.list.tracks):
            tree.insert("", "end", iid=str(index), tags=self.row_tags(index),
                        values=("%d. %s" % (index + 1, track.name), fmt_length(track.duration)))
        chosen = [str(i) for i in select if 0 <= i < len(self.list)]
        if chosen:
            tree.selection_set(chosen)
            tree.focus(chosen[0])
            tree.see(chosen[0])
        self.Totals.configure(text=TRACKS.format(len(self.list)) if self.list.tracks else "")
        self.update_times()

    def retag(self, *indexes):
        for index in indexes:
            if index is not None and 0 <= index < len(self.list):
                self.Playlist.item(str(index), tags=self.row_tags(index))

    def selected_indexes(self):
        return sorted(int(i) for i in self.Playlist.selection())

    def update_times(self):
        chosen = self.selected_indexes()
        sel, sel_unknown = self.list.total(chosen)
        total, unknown = self.list.total()
        self.Times.configure(text="%s%s/%s%s" % (
            fmt_time(sel) or "0:00", "+" if sel_unknown else "",
            fmt_time(total) or "0:00", "+" if unknown else ""))

    def track_changed(self, old=None):
        """La canción actual cambió: lista, pantalla y datos del formato."""
        self.retag(old, self.list.current)
        if self.list.current is not None:
            self.Playlist.see(str(self.list.current))
        track = self.list.track()
        self.Info.itemconfigure(self.kbps, text=str(track.bitrate) if track and track.bitrate else "")
        self.Info.itemconfigure(self.khz, text=str(int(round(track.rate / 1000.0))) if track and track.rate else "")
        self.Info.itemconfigure(self.vbr_item, fill=GREEN if track and track.vbr else DIM)
        mono = bool(track and track.mode == "mono")
        stereo = bool(track and track.mode and not mono)
        self.Info.itemconfigure(self.mono_item, fill=GREEN if mono else DIM)
        self.Info.itemconfigure(self.stereo_item, fill=GREEN if stereo else DIM)
        count = len(self.list)
        current = "%d" % (self.list.current + 1) if self.list.current is not None else "-"
        self.Lcd.itemconfigure(self.counter, text="%s/%d" % (current, count) if count else "")
        self.flash_until = 0.0
        self.redraw()

    def add_paths(self, paths, play=False):
        paths = [p for p in paths if p.lower().endswith(AUDIO_EXT)]
        if not paths:
            self.status(NONE_FOUND, "⚠")
            return 0
        first = len(self.list)
        self.root.configure(cursor="watch")
        self.root.update_idletasks()
        try:
            added, repeated = self.list.add(paths)
        finally:
            self.root.configure(cursor="")
        self.fill(select=range(first, len(self.list)))
        self.track_changed()
        text = ADDED.format(added)
        if repeated:
            text += "  ·  " + DUPLICATES.format(repeated)
        self.status(text, "add")
        self.save()
        if play and added and not self.engine.playing:
            self.play_index(first, chosen=True)
        return added

    def add_files(self, play=False):
        chosen = self.AddFiles.execute()
        if chosen:
            self.add_paths(chosen if isinstance(chosen, list) else [chosen], play)

    def add_folder(self):
        folder = filedialog.askdirectory(parent=self.root, title=FOLDER_TITLE, mustexist=True)
        if folder:
            self.add_paths(audio_files(folder))

    def remove_indexes(self, indexes):
        if not indexes:
            self.status(NOTHING_SELECTED, "info")
            return 0
        if self.list.current in indexes and self.engine.playing:
            self.stop()
        removed = self.list.remove(indexes)
        first = min(indexes)
        self.fill(select=[min(first, len(self.list) - 1)] if self.list.tracks else ())
        self.track_changed()
        self.status(REMOVED.format(removed), "delete")
        self.save()
        return removed

    def remove_selected(self):
        return self.remove_indexes(self.selected_indexes())

    def remove_missing(self):
        gone = [i for i, t in enumerate(self.list.tracks) if not os.path.isfile(t.path)]
        return self.remove_indexes(gone)

    def clear_list(self, ask=True):
        if self.list.tracks and ask and not messagebox.askyesno(APP, ASK_CLEAR, parent=self.root):
            return
        self.stop()
        self.list.clear()
        self.fill()
        self.track_changed()
        self.save()
        self.status(EMPTY, "new")

    def sort_by(self, how):
        self.list.sort(how)
        current = self.list.current
        self.fill(select=[current] if current is not None else ())
        self.track_changed()
        label = {"title": BY_TITLE, "artist": BY_ARTIST, "file": BY_FILE, "shuffle": RANDOMIZE}[how]
        self.status(SORTED.format(label.lower()), "check")
        self.save()

    def open_list(self, path=None):
        path = path or self.OpenList.execute()
        if not path:
            return
        try:
            paths, missing = load_m3u(path)
        except OSError as error:
            self.status(CANT_OPEN.format(error), "⚠")
            return
        self.stop()
        self.list.clear()
        self.list.add(paths)
        self.fill(select=[0] if self.list.tracks else ())
        self.track_changed()
        text = LIST_OPENED.format(len(self.list))
        if missing:
            text += "  ·  " + NOT_FOUND.format(missing)
        self.status(text, "open")
        self.save()

    def save_list(self, path=None):
        if not self.list.tracks:
            self.status(EMPTY, "info")
            return
        path = path or self.SaveList.execute()
        if not path:
            return
        try:
            save_m3u(path, self.list.tracks)
        except OSError as error:
            self.status(CANT_SAVE.format(error), "⚠")
            return
        self.status(LIST_SAVED.format(path), "save")

    def show_info(self):
        chosen = self.selected_indexes()
        track = self.list.track(chosen[0] if chosen else None)
        if track is None:
            self.status(NOTHING_SELECTED, "info")
            return
        megabytes = ("%.1f MB" % (track.size / 1048576.0)).replace(".", DECIMAL)
        values = (track.title, track.artist, track.album, fmt_length(track.duration), describe(track),
                  megabytes, track.path)
        text = "\n".join("%s: %s" % (k, v or "–") for k, v in zip(INFO_FIELDS, values))
        messagebox.showinfo(APP, text, parent=self.root)

    # -------------------------------------------------------- reproducción
    def require_audio(self, explain=True):
        """True si hay sonido; si no, dice cómo conseguirlo."""
        if self.engine.ok:
            return True
        if self.engine.error == NEEDS_PYGAME:
            self.status(NO_PYGAME.format(INSTALL), "⚠")
            if explain and not self.warned:
                self.warned = True
                lines = [NEED_PYGAME, INSTALL]
                try:
                    self.root.clipboard_clear()
                    self.root.clipboard_append(INSTALL)
                    lines.append(COPIED)
                except tk.TclError:
                    pass
                messagebox.showinfo(APP, "\n\n".join(lines), parent=self.root)
        else:
            self.status(NO_AUDIO.format(self.engine.error), "⚠")
        return False

    def play_index(self, index, chosen=False):
        track = self.list.track(index)
        if track is None or not self.require_audio():
            return False
        if not os.path.isfile(track.path):
            track.missing = True
            self.retag(index)
            self.status(MISSING.format(track.path), "⚠")
            return False
        old = self.list.current
        try:
            self.engine.play(track.path)
        except Exception as error:
            self.status(CANT_PLAY.format(os.path.basename(track.path), error), "⚠")
            return False
        track.missing = False
        self.list.select(index, chosen)
        self.track_changed(old)
        self.status(PLAYING.format(track.name), "play")
        self.save()
        return True

    def play(self):
        if not self.require_audio():
            return
        if self.engine.paused:
            return self.pause()
        chosen = self.selected_indexes()
        if not self.engine.playing and chosen:
            return self.play_index(chosen[0], chosen=True)
        index = self.list.current if self.list.current is not None else self.list.next_index(1)
        if index is None:
            self.status(EMPTY, "info")
            return
        self.play_index(index)

    def play_selected(self):
        chosen = self.selected_indexes()
        if chosen:
            self.play_index(chosen[0], chosen=True)
        else:
            self.status(NOTHING_SELECTED, "info")

    def pause(self):
        """Pausa, o sigue si ya estaba en pausa."""
        if not self.require_audio() or not self.engine.playing:
            return
        track = self.list.track()
        name = track.name if track else ""
        if self.engine.paused:
            self.engine.resume()
            self.status(PLAYING.format(name), "play")
        else:
            self.engine.pause()
            self.status(PAUSED.format(name), "⏸")
        self.redraw()

    def stop(self):
        was = self.engine.playing
        self.engine.stop()
        self.seeking = None
        if was:
            self.status(STOPPED, "stop")
        self.redraw()

    def move(self, step):
        """Anterior o siguiente: suena si ya sonaba; si no, solo la elige."""
        if not self.require_audio():
            return
        index = self.list.next_index(step)
        if index is None:
            return
        if self.engine.playing:
            self.play_index(index)
        else:
            old = self.list.current
            self.list.select(index)
            self.track_changed(old)
            self.save()

    def track_ended(self):
        """Acabó la canción: la siguiente según aleatorio y repetir."""
        for _ in range(len(self.list)):
            index = self.list.next_index(1, auto=True)
            if index is None:
                break
            if self.play_index(index):
                return
            self.list.select(index)  # No se pudo: se prueba con la de después.
        self.stop()
        self.status(END, "stop")

    def seek_to(self, seconds):
        track = self.list.track()
        if not self.engine.playing or track is None or not track.duration:
            return False
        seconds = max(0.0, min(seconds, track.duration - 0.5))
        if not self.engine.seek(seconds):
            self.status(NO_SEEK, "⚠")
            return False
        self.redraw()
        return True

    def set_volume(self, value, flash=True):
        self.volume = max(0, min(100, int(round(value))))
        self.engine.set_volume(self.volume / 100.0)
        self.draw_volume()
        if flash:
            self.flash(VOLUME_FMT.format(self.volume), 1.0)

    def toggle_shuffle(self):
        self.list.shuffle = not self.list.shuffle
        if self.list.shuffle and self.list.current is not None:
            self.list.select(self.list.current, chosen=True)
        self.draw_button(self.Shuffle)
        self.flash((ON_FMT if self.list.shuffle else OFF_FMT).format(SHUFFLE))
        self.save()

    def toggle_repeat(self):
        self.list.repeat = not self.list.repeat
        self.draw_button(self.Repeat)
        self.flash((ON_FMT if self.list.repeat else OFF_FMT).format(REPEAT))
        self.save()

    # ------------------------------------------------------------ pantalla
    def marquee(self):
        if self.flash_text and time.monotonic() < self.flash_until:
            return self.flash_text
        if not self.engine.ok and self.engine.error == NEEDS_PYGAME:
            return NO_PYGAME.format(INSTALL)
        track = self.list.track()
        if track is None:
            return EMPTY if not self.list.tracks else APP
        length = " (%s)" % fmt_length(track.duration) if track.duration else ""
        return "%d. %s%s" % (self.list.current + 1, track.name, length)

    def set_marquee(self, text):
        if text == self.marquee_text:
            return
        self.marquee_text = text
        c = self.Marquee
        c.delete("text")
        w, h = size(c)
        width = self.marquee_font.measure(text)
        if width <= w - 12:
            c.create_text(6, h // 2, anchor="w", text=text, fill=GREEN, font=self.marquee_font, tags="text")
            self.scroll_width = 0
            return
        loop = text + "   ***   "
        self.scroll_width = self.marquee_font.measure(loop)
        for x in (6, 6 + self.scroll_width):
            c.create_text(x, h // 2, anchor="w", text=loop, fill=GREEN, font=self.marquee_font, tags="text")
        self.scroll_x = 0

    def scroll_marquee(self):
        if not self.scroll_width:
            return
        self.Marquee.move("text", -1, 0)
        self.scroll_x -= 1
        if self.scroll_x <= -self.scroll_width:
            self.Marquee.move("text", self.scroll_width, 0)
            self.scroll_x += self.scroll_width

    def draw_clock(self):
        track = self.list.track()
        state = self.play_state()
        position = self.position()
        sign = " "
        if self.remaining and state != "stop" and track is not None and track.duration:
            position, sign = max(0.0, track.duration - position), "-"
        total = int(position)
        text = sign + "%02d%02d" % (min(99, total // 60), total % 60)
        blink = state == "pause" and int(time.monotonic() * 2) % 2 == 1
        shown = "     " if blink else text
        if shown != self.clock_text:
            self.clock_text = shown
            for cell, char in zip(self.cells, shown):
                on = SEGMENTS.get(char, "")
                for key, item in cell.items():
                    self.Lcd.itemconfigure(item, fill=GREEN if key in on else GHOST)
            for item in self.colon:
                self.Lcd.itemconfigure(item, fill=GHOST if blink else GREEN)
        if self.shown.get("icon") != state:
            self.shown["icon"] = state
            self.Lcd.itemconfigure("icon", state="hidden")
            self.Lcd.itemconfigure("icon_" + state, state="normal")

    def draw_spectrum(self):
        c = self.Lcd
        for i, value in enumerate(self.spectrum.values):
            lit = int(round(value * ROWS))
            old = self.lit[i]
            if lit > old:
                for r in range(old, lit):
                    c.itemconfigure(self.grid[i][r], fill=ROW_COLORS[r])
            elif lit < old:
                for r in range(lit, old):
                    c.itemconfigure(self.grid[i][r], fill=CELL_OFF)
            self.lit[i] = lit
            peak = self.spectrum.peaks[i]
            row = min(ROWS - 1, int(peak * ROWS)) if peak > 0.02 else -1
            if row != self.peak_rows[i]:
                self.peak_rows[i] = row
                if row < 0:
                    c.itemconfigure(self.peak_items[i], state="hidden")
                else:
                    x = 7 + i * 10
                    y = self.spectrum_base - row * 3 - 3
                    c.coords(self.peak_items[i], x, y, x + 8, y + 1)
                    c.itemconfigure(self.peak_items[i], state="normal")

    def draw_seek(self):
        c = self.Seek
        w, h = size(c)
        track = self.list.track()
        active = self.engine.playing and track is not None and bool(track.duration)
        frac = min(1.0, self.position() / track.duration) if active else 0.0
        x = int(round(frac * (w - KNOB_W)))
        if self.shown.get("seek") == (x, active):
            return
        self.shown["seek"] = (x, active)
        c.coords("fill", 1, 5, max(1, x + KNOB_W // 2) if active else 1, h - 6)
        c.move("knob", x - self.seek_x, 0)
        self.seek_x = x
        c.itemconfigure("knob", state="normal" if active else "hidden")

    def draw_volume(self):
        c = self.Volume
        w, h = size(c)
        span = self.vol_x1 - self.vol_x0 - 14
        x = self.vol_x0 + int(round(span * self.volume / 100.0))
        c.coords("fill", self.vol_x0 + 1, 10, x + 7, h - 10)
        c.itemconfigure("fill", fill=ramp(LEVEL, self.volume / 100.0))
        c.move("knob", x - self.vol_knob, 0)
        self.vol_knob = x

    def redraw(self):
        self.draw_clock()
        self.draw_seek()
        self.set_marquee(self.marquee())

    # ------------------------------------------------------------ eventos
    def Tick_timer(self):
        if self.engine.ok and self.engine.finished():
            self.track_ended()
        self.spectrum.step(self.play_state(), self.volume / 100.0)
        self.draw_spectrum()
        self.redraw()
        self.scroll_marquee()

    def Button_down(self, event):
        self.pressed = event.widget
        self.draw_button(event.widget, True)

    def Button_up(self, event):
        widget = event.widget
        was, self.pressed = self.pressed is widget, None
        w, h = size(widget)
        self.draw_button(widget)
        if was and 0 <= event.x < w and 0 <= event.y < h:
            self.buttons[str(widget)][2]()

    def Button_enter(self, event):
        self.flash(self.buttons[str(event.widget)][1], 1.2)

    def Button_leave(self, event):
        self.flash_until = 0.0
        if self.pressed is event.widget:
            self.pressed = None
            self.draw_button(event.widget)

    def Lcd_click(self, event):
        if event.y < 50:
            self.remaining = not self.remaining
            self.draw_clock()
            self.save()

    def Seek_drag(self, event):
        track = self.list.track()
        if not self.engine.playing or track is None or not track.duration:
            return
        w, _ = size(self.Seek)
        frac = (event.x - KNOB_W / 2.0) / float(w - KNOB_W)
        self.seeking = max(0.0, min(1.0, frac)) * track.duration
        self.flash(SEEK_FMT.format(fmt_time(self.seeking), fmt_length(track.duration)), 1.0)
        self.redraw()

    def Seek_release(self, event):
        if self.seeking is None:
            return
        target, self.seeking = self.seeking, None
        self.seek_to(target)

    def Volume_drag(self, event):
        span = self.vol_x1 - self.vol_x0 - 14
        self.set_volume((event.x - self.vol_x0 - 7) * 100.0 / span)

    def Volume_release(self, event):
        self.save()

    def Playlist_select(self, event=None):
        self.update_times()

    def Playlist_double_click(self, event):
        row = self.Playlist.identify_row(event.y)
        if row:
            self.play_index(int(row), chosen=True)
        return "break"

    def Playlist_right_click(self, event):
        row = self.Playlist.identify_row(event.y)
        if row and row not in self.Playlist.selection():
            self.Playlist.selection_set(row)
        try:
            self.menus["context"].tk_popup(event.x_root, event.y_root)
        finally:
            self.menus["context"].grab_release()

    def BtnAdd_click(self):
        self.popup("add", self.BtnAdd)

    def BtnRemove_click(self):
        self.popup("remove", self.BtnRemove)

    def BtnSort_click(self):
        self.popup("sort", self.BtnSort)

    def BtnList_click(self):
        self.popup("list", self.BtnList)

    # ------------------------------------------------------------- teclado
    def key_space(self, event=None):
        if self.engine.playing:
            self.pause()
        else:
            self.play()
        return "break"

    def key_seek(self, step):
        self.seek_to(self.position() + step)
        return "break"

    def key_volume(self, step):
        self.set_volume(self.volume + step)
        self.save()
        return "break"

    def key_enter(self, event=None):
        self.play_selected()
        return "break"

    def key_delete(self, event=None):
        self.remove_selected()
        return "break"

    def select_all(self, event=None):
        self.Playlist.selection_set(self.Playlist.get_children())
        return "break"

    def form_close(self, *args):
        self.Tick.stop()
        self.engine.stop()
        self.save()
        self.engine.quit()
        self.root.destroy()
''';
  return TkExample(
    'mp3_player',
    app,
    t(
      markTr(
        'Reproductor de MP3 con aspecto clásico: pantalla LCD con reloj y espectro, lista de reproducción, listas M3U y etiquetas ID3 leídas del archivo.',
      ),
    ),
    design,
    code,
  );
}
