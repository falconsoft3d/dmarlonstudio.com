import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_mp3_player_');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<String> build() async {
    final e = tkUtilMp3Player(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  /// Corre [harness] con el programa generado y una carpeta personal de
  /// pruebas (los datos guardados no tocan los del usuario).
  Future<Map> run(String py, String harness) async {
    final path = await build();
    final home = Directory(p.join(tmp.path, 'home'))..createSync();
    final r = await Process.run(
      py,
      ['-c', harness, path, tmp.path],
      environment: {
        'HOME': home.path,
        'APPDATA': p.join(home.path, 'AppData'),
        'XDG_DATA_HOME': p.join(home.path, 'share'),
        // Sin sonar por los altavoces.
        'SDL_AUDIODRIVER': 'dummy',
      },
    );
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    final failed = [
      for (final e in out.entries)
        if (e.key.toString().startsWith('check_') && e.value != true) e.key,
    ];
    expect(failed, isEmpty, reason: '${r.stdout}\n${r.stderr}');
    return out;
  }

  test('el ejemplo existe', () {
    final e = tkUtilMp3Player(id);
    expect(e.seed, 'mp3_player');
    expect(e.name, 'Reproductor MP3');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
    // El empaquetador de las demos lee esta línea tal cual.
    expect(e.code, contains('\nREQUIRES = ["pygame"]\n'));
  });

  test('genera Python válido', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    final path = await build();
    final dump = Platform.environment['DMS_MP3_DUMP'];
    if (dump != null && dump.isNotEmpty) File(path).copySync(dump);
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('etiquetas, formato, lista, M3U y ventana en tkinter', () async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final out = await run(py, _harness);
    expect(out['ok'], isTrue);
  });

  test('suena de verdad con pygame', () async {
    final py = await _python(
      'import os; os.environ["SDL_AUDIODRIVER"] = "dummy"; '
      'import tkinter, pygame; pygame.mixer.init(); tkinter.Tk().destroy()',
    );
    if (py == null) return markTestSkipped('Sin Python con tkinter y pygame.');
    final out = await run(py, _pygameHarness);
    expect(out['ok'], isTrue);
  });
}

/// Un Python con [check] sin error: DMS_TK_PYTHON o python3 (null: ninguno).
Future<String?> _python(String check) async {
  final env = Platform.environment['DMS_TK_PYTHON'];
  for (final py in [
    if (env != null && env.isNotEmpty) env,
    'python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, [
        '-c',
        check,
      ], environment: {'SDL_AUDIODRIVER': 'dummy'});
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

/// Lo común: carga el programa, archivos de audio sintéticos y un motor de
/// sonido de mentira para probar la ventana sin pygame.
const _common = r'''
import importlib.util, json, math, os, struct, sys, time, wave, zlib
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
shown = []
mb.showinfo = lambda *a, **k: shown.append(a) or "ok"
mb.showwarning = lambda *a, **k: shown.append(a) or "ok"
mb.showerror = lambda *a, **k: shown.append(a) or "ok"
mb.askyesno = lambda *a, **k: True
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}


def ss(n):
    return bytes([(n >> 21) & 0x7F, (n >> 14) & 0x7F, (n >> 7) & 0x7F, n & 0x7F])


def frame(header, length, payload=b""):
    return header + payload + b"\x00" * (length - 4 - len(payload))


def v1(title, artist, album):
    pad = lambda s, n: s.encode("latin-1")[:n].ljust(n, b"\x00")
    return b"TAG" + pad(title, 30) + pad(artist, 30) + pad(album, 30) + b"2001" + b"\x00" * 30 + b"\x0c"


def write(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return os.path.abspath(path)


def make_wav(path, seconds, rate=22050, channels=1, freq=440.0):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    w = wave.open(path, "wb")
    w.setnchannels(channels)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames = bytearray()
    for i in range(int(seconds * rate)):
        sample = struct.pack("<h", int(3000 * math.sin(2 * math.pi * freq * i / rate)))
        frames += sample * channels
    w.writeframes(bytes(frames))
    w.close()
    return os.path.abspath(path)


# MPEG-1 Layer III, 128 kbps, 44,1 kHz: estéreo, estéreo conjunto y mono.
H128 = b"\xff\xfb\x90\x00"
H128J = b"\xff\xfb\x90\x40"
H192J = b"\xff\xfb\xb0\x40"
# MPEG-2 Layer III, 64 kbps, 22,05 kHz, mono.
H64M = b"\xff\xf3\x80\xc0"


class FakeEngine:
    """Motor de sonido de mentira: la ventana sin pygame ni altavoces."""

    def __init__(self, ok=True):
        self.pygame = object() if ok else None
        self.error = None if ok else m.NEEDS_PYGAME
        self.playing = self.paused = self.done = False
        self.pos, self.volume = 0.0, 0.8
        self.played, self.seeks = [], []

    @property
    def ok(self):
        return self.pygame is not None

    def play(self, path):
        self.played.append(path)
        self.playing, self.paused, self.done, self.pos = True, False, False, 0.0

    def pause(self):
        self.paused = self.playing

    def resume(self):
        self.paused = False

    def stop(self):
        self.playing = self.paused = False
        self.pos = 0.0

    def seek(self, seconds):
        self.seeks.append(seconds)
        self.pos = seconds
        return True

    def position(self):
        return self.pos if self.playing else 0.0

    def finished(self):
        return self.playing and not self.paused and self.done

    def set_volume(self, value):
        self.volume = value

    def quit(self):
        pass


class E:
    def __init__(self, widget=None, x=0, y=0):
        self.widget, self.x, self.y, self.x_root, self.y_root = widget, x, y, x, y


def new_form():
    f = m.Form1()
    f.root.withdraw()
    f.root.update()
    return f
''';

const _harness =
    '$_common'
    r'''
# ---- ID3v2.3: latín-1, UTF-16 con BOM, UTF-8, relleno; ID3v1 detrás.
tit = b"\x00" + "Canción del mar".encode("latin-1")
tpe = b"\x01" + "Ñandú Trío".encode("utf-16") + b"\x00\x00"
tal = b"\x03" + "Álbum €".encode("utf-8")
body = b"".join(fid + struct.pack(">I", len(d)) + b"\x00\x00" + d for fid, d in
                ((b"TIT2", tit), (b"TPE1", tpe), (b"TALB", tal))) + b"\x00" * 100
tag23 = b"ID3\x03\x00\x00" + ss(len(body)) + body
cbr = write("music/cbr.mp3", tag23 + b"".join(frame(H128, 417) for _ in range(40)) + v1("Otro", "Otra", "Otro"))
t = m.read_info(cbr)
out["check_v23"] = (t.title, t.artist, t.album) == ("Canción del mar", "Ñandú Trío", "Álbum €")
out["check_cbr"] = (t.bitrate, t.rate, t.mode, t.vbr, t.codec) == (128, 44100, "stereo", False, "MPEG-1 Layer III")
out["cbr_duration"] = t.duration
out["check_cbr_duration"] = abs(t.duration - 40 * 417 * 8 / 128000.0) < 1e-6
out["check_name"] = t.name == "Ñandú Trío - Canción del mar"
h = m.parse_frame_header(H128)
out["check_header"] = (h["version"], h["layer"], h["bitrate"], h["rate"], h["length"], h["samples"]) == (1, 3, 128, 44100, 417, 1152)
h = m.parse_frame_header(H64M)
out["check_header_mpeg2"] = (h["version"], h["bitrate"], h["rate"], h["mode"], h["length"], h["samples"]) == (2, 64, 22050, "mono", 208, 576)
out["check_header_bad"] = m.parse_frame_header(b"\xff\xfb\xf0\x00") is None and m.parse_frame_header(b"\xff\xfb\x9c\x00") is None and m.parse_frame_header(b"\x00\xfb\x90\x00") is None
h = m.parse_frame_header(b"\xff\xfd\x90\x00")  # MPEG-1 Layer II
out["check_header_layer2"] = h["layer"] == 2 and h["bitrate"] == 160 and h["length"] == 522

# ---- ID3v2.4: cabecera extendida, tamaños synchsafe (> 127), UTF-16BE,
# varios valores y un marco con indicador de longitud. Xing con 1000 tramas.
long_title = "Título VBR " + "x" * 150
tit = b"\x02" + long_title.encode("utf-16-be")
tpe = b"\x03" + "Ana\x00Luis".encode("utf-8")
raw_alb = b"\x00Disco"
tal = ss(len(raw_alb)) + raw_alb
frames24 = b"".join(fid + ss(len(d)) + flags + d for fid, flags, d in
                    ((b"TIT2", b"\x00\x00", tit), (b"TPE1", b"\x00\x00", tpe), (b"TALB", b"\x00\x01", tal)))
ext = ss(6) + b"\x01\x00"
body = ext + frames24 + b"\x00" * 50
tag24 = b"ID3\x04\x00\x40" + ss(len(body)) + body
xing = b"Xing" + struct.pack(">III", 3, 1000, 300000)
audio = frame(H128J, 417, b"\x00" * 32 + xing)
audio += b"".join(frame(H192J if i % 2 else H128J, 626 if i % 2 else 417) for i in range(30))
junk = b"\xff\xfb\x90\x00" + b"\x01" * 20  # Una cabecera falsa que no sigue.
vbr = write("music/vbr.mp3", tag24 + junk + audio)
t = m.read_info(vbr)
out["check_v24"] = (t.title, t.artist, t.album) == (long_title, "Ana / Luis", "Disco")
out["vbr"] = [t.duration, t.bitrate, t.mode, t.vbr]
out["check_xing"] = abs(t.duration - 1000 * 1152 / 44100.0) < 1e-6 and t.vbr and t.mode == "joint"
out["check_xing_bitrate"] = t.bitrate == int(round(300000 * 8 / (1000 * 1152 / 44100.0) / 1000))
out["check_find_frame"] = m.find_frame(junk + audio)[0] == len(junk)
# Info (de LAME, CBR): la duración sale de las tramas, sin marcar VBR.
info = b"Info" + struct.pack(">II", 1, 500)
t = m.read_info(write("music/info.mp3", frame(H128J, 417, b"\x00" * 32 + info) + frame(H128J, 417) * 3))
out["check_info_tag"] = abs(t.duration - 500 * 1152 / 44100.0) < 1e-6 and not t.vbr and t.bitrate == 128
# VBRI (de Fraunhofer) en la posición 36.
vbri = b"VBRI" + b"\x00\x01\x00\x00\x00\x50" + struct.pack(">II", 200000, 800)
t = m.read_info(write("music/vbri.mp3", frame(H128, 417, b"\x00" * 32 + vbri) + frame(H128, 417) * 3))
out["check_vbri"] = abs(t.duration - 800 * 1152 / 44100.0) < 1e-6 and t.vbr

# ---- Solo ID3v1, MPEG-2 mono.
mono = write("music/mono.mp3", b"".join(frame(H64M, 208) for _ in range(50)) + v1("Solo v1", "Mono", "Uno"))
t = m.read_info(mono)
out["check_v1"] = (t.title, t.artist, t.album) == ("Solo v1", "Mono", "Uno")
out["check_mono"] = (t.rate, t.mode, t.bitrate, t.codec) == (22050, "mono", 64, "MPEG-2 Layer III")
out["check_mono_duration"] = abs(t.duration - 50 * 208 * 8 / 64000.0) < 1e-6

# ---- Sin nada: el nombre del archivo.
t = m.read_info(write("music/Sin etiquetas.mp3", b"no es audio" * 50))
out["check_fallback"] = t.name == "Sin etiquetas" and t.duration is None and t.bitrate == 0
t = m.read_info(os.path.abspath("music/no existe.mp3"))
out["check_missing"] = t.missing and t.name == "no existe"

# ---- ID3v2.3 desincronizado con un marco comprimido; ID3v2.2; textos.
raw = b"\x00Comprimido"
tpe = struct.pack(">I", len(raw)) + zlib.compress(raw)
tit = b"\x00" + "Señal ÿ".encode("latin-1")
body = (b"TIT2" + struct.pack(">I", len(tit)) + b"\x00\x00" + tit +
        b"TPE1" + struct.pack(">I", len(tpe)) + b"\x00\x80" + tpe)
body = body.replace(b"\xff", b"\xff\x00")
tags = m.parse_id3v2(b"ID3\x03\x00\x80" + ss(len(body)) + body)
out["check_unsync_zlib"] = tags == {"title": "Señal ÿ", "artist": "Comprimido"}
body = b"TT2" + struct.pack(">I", 6)[1:] + b"\x00Viejo" + b"TP1" + struct.pack(">I", 4)[1:] + b"\x00Sol"
out["check_v22"] = m.parse_id3v2(b"ID3\x02\x00\x00" + ss(len(body)) + body) == {"title": "Viejo", "artist": "Sol"}
out["check_decode"] = (m.decode_text(b"\x01" + "Hola".encode("utf-16-le")) == "Hola" and
                       m.decode_text(b"\x01\xfe\xff" + "Hola".encode("utf-16-be")) == "Hola" and
                       m.decode_text(b"\x03Uno\x00Dos\x00") == "Uno / Dos" and m.decode_text(b"") == "")
out["check_synchsafe"] = m.synchsafe(ss(300000)) == 300000 and m.id3v2_size(b"ID3\x04\x00\x10" + ss(100)) == 120

# ---- WAV y Ogg Vorbis.
wav = make_wav("music/tono.wav", 1.5)
t = m.read_info(wav)
out["check_wav"] = (t.rate, t.mode, t.bitrate, t.codec) == (22050, "mono", 352, "WAV PCM") and abs(t.duration - 1.5) < 1e-3
ident = b"\x01vorbis" + struct.pack("<IBIiii", 0, 2, 44100, 0, 160000, 0) + b"\xb8\x01"
comments = [b"TITLE=Ogg canci\xc3\xb3n", b"ARTIST=Vorbis"]
comment = b"\x03vorbis" + struct.pack("<I", 4) + b"test" + struct.pack("<I", len(comments))
comment += b"".join(struct.pack("<I", len(c)) + c for c in comments)
last = b"OggS\x00\x04" + struct.pack("<q", 44100 * 3) + b"\x00" * 20
ogg = write("music/vorbis.ogg", b"OggS" + b"\x00" * 24 + ident + b"OggS" + b"\x00" * 24 + comment + b"\x00" * 2000 + last)
t = m.read_info(ogg)
out["check_ogg"] = (t.title, t.artist, t.rate, t.mode, t.codec) == ("Ogg canción", "Vorbis", 44100, "stereo", "Ogg Vorbis") and abs(t.duration - 3.0) < 1e-6
out["check_describe"] = m.describe(m.read_info(cbr)) == "MPEG-1 Layer III  ·  128 kbps  ·  44,1 kHz  ·  " + m.MODE_NAMES["stereo"]
out["check_fmt"] = m.fmt_time(83) == "1:23" and m.fmt_time(3725) == "1:02:05" and m.fmt_time(None) == "" and m.fmt_length(0.6) == "0:01"

# ---- La lista.
def fake_reader(meta):
    def read(path):
        track = m.Track(path)
        track.title, track.artist, track.duration = meta.get(os.path.basename(path), ("", "", None))
        return track
    return read

meta = {"b.mp3": ("Zeta", "Beta", 100.0), "a.mp3": ("Alfa", "Gamma", 50.0), "c.mp3": ("Medio", "", None)}
pl = m.Playlist(rng=__import__("random").Random(3))
added = pl.add(["/x/b.mp3", "/x/a.mp3", "/x/c.mp3", "/x/a.mp3"], reader=fake_reader(meta))
out["check_add"] = added == (3, 1) and len(pl) == 3
pl.current = 1
names = lambda: [os.path.basename(t.path) for t in pl.tracks]
pl.sort("title")
out["check_sort_title"] = names() == ["a.mp3", "c.mp3", "b.mp3"] and pl.current == 0
pl.sort("artist")
out["check_sort_artist"] = names() == ["b.mp3", "a.mp3", "c.mp3"] and pl.current == 1
pl.sort("file")
out["check_sort_file"] = names() == ["a.mp3", "b.mp3", "c.mp3"] and pl.current == 0
pl.sort("shuffle")
out["check_sort_shuffle"] = sorted(names()) == ["a.mp3", "b.mp3", "c.mp3"] and names()[pl.current] == "a.mp3"
pl.sort("file")
out["check_total"] = pl.total() == (150.0, 1) and pl.total([0]) == (50.0, 0)
# Sin aleatorio.
pl.current = None
seq = [pl.next_index(1)]
pl.current = 2
seq += [pl.next_index(1, auto=True), pl.next_index(1)]
pl.repeat = True
seq.append(pl.next_index(1, auto=True))
pl.current = 0
seq.append(pl.next_index(-1))
pl.repeat = False
out["check_next"] = seq == [0, None, 0, 0, 2]
# Aleatorio: cada una una vez por vuelta; sin repetir, al final None.
pl.shuffle = True
pl.select(1, chosen=True)
visited = [1]
for _ in range(2):
    index = pl.next_index(1, auto=True)
    pl.select(index)
    visited.append(index)
out["check_shuffle_cycle"] = sorted(visited) == [0, 1, 2] and pl.order[0] == 1
out["check_shuffle_end"] = pl.next_index(1, auto=True) is None
back = pl.next_index(-1)
out["check_shuffle_prev"] = back == visited[1]
pl.repeat = True
again = pl.next_index(1, auto=True)
out["check_shuffle_repeat"] = again is not None and again != visited[-1] and sorted(pl.order) == [0, 1, 2]
# Quitar: la que suena se sigue sabiendo cuál es.
pl = m.Playlist()
pl.add(["/x/%d.mp3" % i for i in range(5)], reader=fake_reader({}))
pl.current = 3
pl.remove([0])
out["check_remove_shift"] = pl.current == 2 and len(pl) == 4
pl.remove([1, 2])
out["check_remove_current"] = pl.current is None and [os.path.basename(t.path) for t in pl.tracks] == ["1.mp3", "4.mp3"]

# ---- M3U: relativas dentro de la carpeta de la lista; absolutas fuera.
inside = make_wav("lists/music/dentro.wav", 0.2)
outside = make_wav("outside/fuera.wav", 0.2)
tracks = [m.read_info(inside), m.read_info(outside)]
m3u = os.path.abspath("lists/mix.m3u")
m.save_m3u(m3u, tracks)
lines = open(m3u, encoding="utf-8").read().splitlines()
out["m3u"] = lines
out["check_m3u_text"] = lines[0] == "#EXTM3U" and lines[1] == "#EXTINF:0,dentro" and lines[2] == os.path.join("music", "dentro.wav") and lines[4] == outside
found, missing = m.load_m3u(m3u)
out["check_m3u_roundtrip"] = found == [inside, outside] and missing == 0
from urllib.request import pathname2url
hand = "\n".join(["#EXTM3U", "#EXTINF:1,Uno", "music\\dentro.wav", outside, "file://" + pathname2url(outside),
                  "no_esta.mp3", "http://radio.example/stream", ""])
with open("lists/hand.m3u8", "w", encoding="utf-8-sig") as f:
    f.write(hand)
found, missing = m.load_m3u("lists/hand.m3u8")
out["check_m3u_load"] = found == [inside, outside, outside] and missing == 2

# ---- La ventana, con el motor de mentira.
m.Engine = FakeEngine
f = new_form()
data_file = f.state_path
expected_dir = m.data_dir()
out["check_data_dir"] = os.path.dirname(data_file) == expected_dir and expected_dir.startswith(os.environ["HOME"]) and expected_dir.endswith("DMarlon Studio")
out["check_empty"] = f.marquee_text == m.EMPTY and f.Playlist.get_children() == () and f.Times.cget("text") == "0:00/0:00"
out["check_style"] = f.Playlist.cget("style") == "Skin.Treeview" and f.Playlist.cget("show") in ("", ())
out["check_menus"] = f.menus["sort"].index("end") == 4 and f.menus["list"].index("end") == 3
out["check_binds"] = all(f.Playlist.bind(k) for k in ("<space>", "<Left>", "<Right>", "<Up>", "<Down>", "<Return>", "<Delete>"))
out["check_root_binds"] = all(f.root.bind(k) for k in ("<space>", "<Left>", "<Up>"))
f.add_paths([cbr, vbr, mono, wav, os.path.abspath("lists/mix.m3u")])
rows = [f.Playlist.item(i, "values") for i in f.Playlist.get_children()]
out["rows"] = rows
out["check_rows"] = len(rows) == 4 and tuple(rows[0]) == ("1. Ñandú Trío - Canción del mar", "0:01") and rows[1][1] == "0:26"
out["check_selected_added"] = len(f.Playlist.selection()) == 4
f.Playlist.selection_set(())
f.update_times()
out["times"] = f.Times.cget("text")
out["check_times"] = f.Times.cget("text") == "0:00/" + m.fmt_time(40 * 417 * 8 / 128000.0 + 1000 * 1152 / 44100.0 + 1.3 + 1.5)
out["check_totals"] = f.Totals.cget("text") == m.TRACKS.format(4)
f.add_paths([cbr])
out["check_duplicate"] = len(f.list) == 4 and m.DUPLICATES.format(1) in f.Status.cget("text")
# Reproducir la primera: pantalla, formato y lista.
f.Playlist.selection_set(())
f.play_index(0, chosen=True)
f.root.update()
out["check_playing"] = f.engine.played == [cbr] and f.play_state() == "play" and f.list.current == 0
out["check_marquee"] = f.marquee_text == "1. Ñandú Trío - Canción del mar (0:01)"
info = lambda item: (f.Info.itemcget(item, "text"), f.Info.itemcget(item, "fill"))
out["check_info"] = info(f.kbps)[0] == "128" and info(f.khz)[0] == "44" and info(f.stereo_item)[1] == m.GREEN and info(f.mono_item)[1] == m.DIM
out["check_current_tag"] = f.Playlist.item("0", "tags") == ["current"] or f.Playlist.item("0", "tags") == ("current",)
out["check_counter"] = f.Lcd.itemcget(f.counter, "text") == "1/4"
# El reloj y el espectro.
f.engine.pos = 65.4
for _ in range(10):
    f.Tick_timer()
f.root.update()
out["clock"] = f.clock_text
out["check_clock"] = f.clock_text == " 0105"
out["check_icon"] = f.Lcd.itemcget("icon_play", "state") == "normal" and f.Lcd.itemcget("icon_stop", "state") == "hidden"
lit = sum(f.lit)
out["check_spectrum"] = lit > 10 and all(f.Lcd.itemcget(f.grid[i][r], "fill") == m.ROW_COLORS[r] for i in range(m.BARS) for r in range(f.lit[i]))
out["check_spectrum_off"] = all(f.Lcd.itemcget(f.grid[i][r], "fill") == m.CELL_OFF for i in range(m.BARS) for r in range(f.lit[i], m.ROWS))
# El segundo: VBR, conjunto; tiempo restante al pulsar el reloj.
f.move(1)
out["check_next_button"] = f.list.current == 1 and f.engine.played[-1] == vbr and info(f.vbr_item)[1] == m.GREEN
f.engine.pos = 5.0
f.Lcd_click(E(f.Lcd, 60, 20))
f.Tick_timer()
out["check_remaining"] = f.remaining and f.clock_text == "-0021"
f.Lcd_click(E(f.Lcd, 60, 20))
f.Tick_timer()
out["check_elapsed"] = f.clock_text == " 0005"
# Posición: arrastrar la barra salta a la mitad.
w, _ = m.size(f.Seek)
t_vbr = 1000 * 1152 / 44100.0 / 2
f.Seek_drag(E(f.Seek, w // 2, 8))
out["check_seeking"] = abs(f.seeking - t_vbr) < 0.6
f.Seek_release(E(f.Seek, w // 2, 8))
out["check_seek"] = len(f.engine.seeks) == 1 and abs(f.engine.seeks[0] - t_vbr) < 0.6 and f.seeking is None
f.Tick_timer()
out["check_seek_knob"] = abs(f.seek_x - (w - m.KNOB_W) / 2) <= 2 and f.Seek.itemcget("knob", "state") == "normal"
f.key_seek(5)
out["check_key_seek"] = abs(f.engine.seeks[-1] - (t_vbr + 5)) < 0.7
# Volumen: arrastrar y teclas.
f.Volume_drag(E(f.Volume, f.vol_x0 + 7 + (f.vol_x1 - f.vol_x0 - 14) // 2, 10))
out["check_volume"] = f.volume == 50 and abs(f.engine.volume - 0.5) < 1e-9 and f.marquee_text == m.VOLUME_FMT.format(50)
f.key_volume(5)
f.key_volume(5)
f.key_volume(-5)
out["check_key_volume"] = f.volume == 55
f.Volume_drag(E(f.Volume, 1000, 10))
out["check_volume_max"] = f.volume == 100
# Pausa: el espectro se queda quieto y el reloj parpadea.
f.key_space()
before = list(f.spectrum.values)
f.Tick_timer()
out["check_pause"] = f.play_state() == "pause" and f.spectrum.values == before and f.Lcd.itemcget("icon_pause", "state") == "normal"
f.key_space()
out["check_resume"] = f.play_state() == "play"
# Los botones dibujados: pulsar y soltar dentro.
f.Button_down(E(f.BtnStop, 5, 5))
out["check_pressed"] = f.pressed is f.BtnStop
f.Button_up(E(f.BtnStop, 5, 5))
out["check_stop_button"] = f.play_state() == "stop" and f.pressed is None
for _ in range(40):
    f.Tick_timer()
out["check_spectrum_falls"] = sum(f.lit) == 0 and f.clock_text == " 0000"
f.Button_down(E(f.BtnPlay, 5, 5))
f.Button_up(E(f.BtnPlay, 500, 5))  # Soltar fuera: no hace nada.
out["check_release_outside"] = f.play_state() == "stop"
f.Button_enter(E(f.BtnNext))
out["check_hover"] = f.marquee_text == m.NEXT
f.Button_leave(E(f.BtnNext))
# Aleatorio y repetir desde sus botones.
f.Button_down(E(f.Repeat, 5, 5))
f.Button_up(E(f.Repeat, 5, 5))
out["check_repeat"] = f.list.repeat and f.marquee_text == m.ON_FMT.format(m.REPEAT)
f.toggle_repeat()
# Fin de la canción: la siguiente; al acabar la lista, se para.
f.play_index(2, chosen=True)
f.engine.done = True
f.Tick_timer()
out["check_auto_next"] = f.list.current == 3 and f.engine.played[-1] == wav
f.engine.done = True
f.Tick_timer()
out["check_end"] = f.play_state() == "stop" and f.Status.cget("text") == m.END
f.toggle_repeat()
f.play_index(3)
f.engine.done = True
f.Tick_timer()
out["check_repeat_wraps"] = f.list.current == 0 and f.play_state() == "play"
f.toggle_repeat()
# Un archivo que ya no está: se salta.
gone = write("music/gone.mp3", tag23 + frame(H128, 417) * 3)
f.add_paths([gone])
os.remove(gone)
f.play_index(3)
f.engine.done = True
f.Tick_timer()
out["check_skip_missing"] = f.list.tracks[4].missing and f.play_state() == "stop"
out["check_missing_tag"] = "missing" in f.Playlist.item("4", "tags")
f.remove_missing()
out["check_remove_missing"] = len(f.list) == 4
# Teclas: Intro reproduce lo elegido; Supr lo quita.
f.Playlist.selection_set("2")
f.key_enter()
out["check_enter"] = f.list.current == 2 and f.engine.played[-1] == mono
f.Playlist.selection_set(("0", "1"))
f.update_times()
out["check_selection_times"] = f.Times.cget("text").startswith("0:27/")
f.key_delete()
out["check_delete"] = len(f.list) == 2 and f.list.current == 0 and f.list.track().path == mono and f.Playlist.selection() == ("0",)
f.select_all()
out["check_select_all"] = len(f.Playlist.selection()) == 2
# Ordenar desde la ventana.
f.add_paths([cbr, vbr])
f.sort_by("title")
titles = [f.Playlist.item(i, "values")[0] for i in f.Playlist.get_children()]
out["sorted"] = titles
out["check_sort_window"] = titles[0].startswith("1. Ñandú Trío - Canción") and f.list.track().path == mono and f.Playlist.item(str(f.list.current), "tags") in (["current"], ("current",))
# Información del archivo.
f.Playlist.selection_set("0")
f.show_info()
out["check_info_dialog"] = "128 kbps" in shown[-1][1] and cbr in shown[-1][1]
# Listas M3U desde la ventana.
saved = os.path.abspath("lists/ventana.m3u")
f.save_list(saved)
f.clear_list()
out["check_clear"] = len(f.list) == 0 and f.play_state() == "stop"
f.open_list(saved)
out["check_open_list"] = len(f.list) == 4 and m.LIST_OPENED.format(4) in f.Status.cget("text")
# Un título largo se desplaza en la pantalla.
f.list.select(len(f.list) - 1)
f.track_changed()
f.flash_until = 0
f.redraw()
out["check_scroll"] = f.scroll_width > 0 and len(f.Marquee.find_withtag("text")) == 2
x0 = f.Marquee.coords(f.Marquee.find_withtag("text")[0])[0]
f.scroll_marquee()
out["check_scroll_moves"] = f.Marquee.coords(f.Marquee.find_withtag("text")[0])[0] == x0 - 1

# ---- Se recuerda todo: lista, la última, volumen, aleatorio y repetir.
f.set_volume(35, flash=False)
f.toggle_shuffle()
f.toggle_repeat()
f.list.select(1)
paths = [t.path for t in f.list.tracks]
f.form_close()
saved_state = json.load(open(data_file, encoding="utf-8"))
out["check_saved"] = saved_state["tracks"] == paths and saved_state["volume"] == 35 and saved_state["current"] == 1
f = new_form()
out["check_restored"] = ([t.path for t in f.list.tracks] == paths and f.volume == 35 and f.list.shuffle and
                         f.list.repeat and f.list.current == 1 and f.engine.volume == 0.35)
out["check_restored_view"] = len(f.Playlist.get_children()) == 4 and m.RESTORED.format(4) in f.Status.cget("text")
out["check_toggle_drawn"] = len(f.Shuffle.find_all()) > 20
f.form_close()

# ---- Sin pygame: se abre igual y dice cómo instalarlo.
m.Engine = lambda: FakeEngine(ok=False)
f = new_form()
out["check_no_pygame_marquee"] = m.INSTALL in f.marquee_text and m.INSTALL in f.Status.cget("text")
count = len(shown)
f.play()
out["check_no_pygame_dialog"] = len(shown) == count + 1 and m.INSTALL in shown[-1][1]
out["check_clipboard"] = f.root.clipboard_get() == m.INSTALL
f.pause()
f.move(1)
out["check_no_pygame_once"] = len(shown) == count + 1 and f.play_state() == "stop"
f.form_close()
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str, ensure_ascii=False))
''';

const _pygameHarness =
    '$_common'
    r'''
# ---- El motor de verdad (pygame con la salida de sonido de pruebas).
e = m.Engine()
out["check_engine"] = e.ok and e.error is None
wav = make_wav("music/tres.wav", 3.0, rate=44100, channels=2)
e.set_volume(0.05)
e.play(wav)
time.sleep(0.8)
p1 = e.position()
out["p1"] = p1
out["check_position"] = 0.3 < p1 < 2.0 and e.music.get_busy() and not e.finished()
out["check_seek_real"] = e.seek(2.0)
time.sleep(0.3)
p2 = e.position()
out["p2"] = p2
out["check_seek_position"] = 2.0 <= p2 < 2.9
e.pause()
p3 = e.position()
time.sleep(0.4)
p4 = e.position()
out["check_pause_real"] = abs(p4 - p3) < 0.05 and not e.finished()
e.resume()
end = time.time() + 4
while not e.finished() and time.time() < end:
    time.sleep(0.05)
out["check_finished_real"] = e.finished()
e.play(wav)
e.stop()
out["check_stop_real"] = not e.playing and e.position() == 0.0 and not e.music.get_busy()
e.quit()

# ---- La ventana con sonido de verdad: al acabar una, suena la siguiente.
a = make_wav("music/a.wav", 0.6)
b = make_wav("music/b.wav", 0.6, freq=660.0)
f = new_form()
f.set_volume(5, flash=False)
f.add_paths([a, b])
f.play_index(0, chosen=True)
seen = []
end = time.time() + 6
while time.time() < end:
    f.Tick_timer()
    f.root.update()
    seen.append((f.list.current, f.play_state()))
    if seen[-1] == (1, "stop"):
        break
    time.sleep(0.05)
out["seen_tail"] = seen[-3:]
out["check_window_next"] = (1, "play") in seen and seen[-1] == (1, "stop") and f.Status.cget("text") == m.END
out["check_window_spectrum"] = any(v > 0 for v in f.spectrum.peaks)
f.form_close()
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str, ensure_ascii=False))
''';
