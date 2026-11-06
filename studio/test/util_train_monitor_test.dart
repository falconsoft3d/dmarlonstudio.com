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
    tmp = await Directory.systemTemp.createTemp('dms_train_monitor_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> build() async {
    final e = tkUtilTrainMonitor(id);
    final file = File(p.join(tmp.path, 'app.py'));
    await file.writeAsString(TkCodegen.generate(e.design, e.code));
    return file.path;
  }

  test('el ejemplo existe, con su nombre y un diseño sin problemas', () {
    final e = tkUtilTrainMonitor(id);
    expect(e.seed, 'train_monitor');
    expect(e.name, 'Seguimiento de trenes');
    expect(e.design.isWeb, isFalse);
    expect(e.design.problems(), isEmpty);
    expect(e.design.connections, isEmpty);
    expect(e.design.width, lessThanOrEqualTo(1100));
    expect(e.design.height, lessThanOrEqualTo(720));
    // Nada de sintaxis de Python 3.10 y la advertencia siempre a la vista.
    expect(e.code, isNot(contains('match ')));
    final note = e.design.widgets.firstWhere((w) => w.name == 'Note');
    expect(note.props['text'], contains('No es un sistema de seguridad'));
    expect(e.code, contains('No sirve para circular'));
    expect(e.code, contains('Origen de los datos: Renfe Operadora'));
  });

  test('genera Python válido', () async {
    final py = await _python('import sys');
    if (py == null) return markTestSkipped('Sin Python.');
    final path = await build();
    final r = await Process.run(py, ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test(
    'de verdad en tkinter: GTFS, tiempo real, alertas, simulación y gráficos',
    () async {
      // Con update(): el Tk 8.5 de Apple se queda colgado en macOS recientes.
      final py = await _python(
        'import tkinter; r = tkinter.Tk(); r.update(); r.destroy()',
      );
      if (py == null) return markTestSkipped('Sin Python con tkinter.');
      final path = await build();
      final r = await Process.run(py, [
        '-c',
        _harness,
        path,
        tmp.path,
      ]).timeout(const Duration(minutes: 3));
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
      final failed = out.entries
          .where((e) => '${e.key}'.startsWith('check_') && e.value != true)
          .map((e) => e.key)
          .toList();
      expect(failed, isEmpty, reason: '${r.stdout}\n${r.stderr}');
      expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

/// Un Python con [check] sin error en 20 s: DMS_TK_PYTHON o python3 (null:
/// ninguno).
Future<String?> _python(String check) async {
  final env = Platform.environment['DMS_TK_PYTHON'];
  for (final py in [
    if (env != null && env.isNotEmpty) env,
    'python3',
    '/usr/bin/python3',
  ]) {
    try {
      final proc = await Process.start(py, ['-c', check]);
      final code = await proc.exitCode.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          proc.kill();
          return -1;
        },
      );
      if (code == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

/// Carga el programa generado con la carpeta de datos en argv[2]. Nunca usa
/// la red: fetch_json se cambia por datos inventados con el formato exacto de
/// Renfe, y el GTFS es un zip pequeño hecho aquí.
const _harness = r'''
import datetime, importlib.util, io, json, os, sys, time, zipfile
import tkinter.messagebox as mb
os.chdir(sys.argv[2])
mb.showinfo = mb.showerror = mb.showwarning = lambda *a, **k: "ok"
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
m.data_dir = lambda: sys.argv[2]
out = {}

def near(a, b, tol):
    return abs(a - b) <= tol

# ------------------------------------------------- GTFS pequeño, como el de Renfe
today = datetime.date.today()
ymd = today.strftime("%Y%m%d")
other = (today + datetime.timedelta(days=3)).strftime("%Y%m%d")
day = m.WEEKDAYS[today.weekday()]
flags = ",".join("1" if w == day else "0" for w in m.WEEKDAYS)
pad = lambda v, n=12: v + " " * max(0, n - len(v))
files = {
    "agency.txt": "agency_id,agency_name,agency_url,agency_timezone\n1071VC,Renfe Cercanias,https://www.renfe.com,Europe/Madrid\n",
    "calendar.txt": "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date     \n"
                    "1099X,%s,%s,%s\n1098X,%s,%s,%s\n" % (flags, ymd, ymd, flags, other, other),
    "routes.txt": "route_id,route_short_name,route_long_name,route_type,route_color,route_text_color          \n"
                  "%s,%s,Alfa -Delta,2,FF0000,FFFFFF\n%s,%s,Delta -Alfa,2,FF0000,FFFFFF\n%s,C1,Otro,2,00FF00,FFFFFF\n"
                  % (pad("10T0001C9"), pad("C9", 5), pad("10T0002C9"), pad("C9", 5), pad("30T0001C1")),
    "trips.txt": "route_id,service_id,trip_id,trip_headsign,wheelchair_accessible,block_id,shape_id        \n"
                 "10T0001C9,1099X,1099X00001C9,  ,1,1,10_C9\n"
                 "10T0001C9,1099X,1099X00003C9,  ,1,1,10_C9\n"
                 "10T0002C9,1099X,1099X00002C9,  ,1,1,10_C9_INV\n"
                 "10T0001C9,1098X,1098X00009C9,  ,1,1,10_C9\n"
                 "30T0001C1,3099X,3099X00001C1,  ,1,1,30_C1\n",
    "stops.txt": "stop_id,stop_name,stop_lat,stop_lon,wheelchair_boarding    \n"
                 "90001,Alfa,40.0,-3.0,1\n90002,Beta,40.0,-2.9,1\n90003,Gamma,40.0,-2.8,1\n"
                 "90004,Delta,40.0,-2.7,1\n90009,Lejos,41.0,-3.0,1\n",
    "shapes.txt": "shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence\n"
                  + "".join("10_C9,40.0,%s,%d\n" % (lon, i + 1) for i, lon in enumerate((-3.0, -2.9, -2.8, -2.7)))
                  + "".join("10_C9_INV,40.0,%s,%d\n" % (lon, i + 1) for i, lon in enumerate((-2.7, -2.8, -2.9, -3.0)))
                  + "30_C1,37.0,-6.0,1\n30_C1,37.1,-6.0,2\n",
    "stop_times.txt": "trip_id,arrival_time,departure_time,stop_id,stop_sequence\n"
                      "1099X00001C9,08:00:00,08:00:00,90001,001\n1099X00001C9,08:06:00,08:06:30,90002,002\n"
                      "1099X00001C9,08:12:00,08:12:30,90003,003\n1099X00001C9,08:18:00,08:18:00,90004,004\n"
                      "1099X00001C9,08:30:00,08:30:00,90009,005\n"
                      "1099X00003C9,23:50:00,23:50:00,90001,001\n1099X00003C9,24:08:00,24:08:00,90004,002\n"
                      "1099X00002C9,09:00:00,09:00:00,90004,001\n1099X00002C9,09:18:00,09:18:00,90001,002\n"
                      "1098X00009C9,10:00:00,10:00:00,90001,001\n1098X00009C9,10:18:00,10:18:00,90004,002\n",
}
gtfs = os.path.join(sys.argv[2], "gtfs.zip")
with zipfile.ZipFile(gtfs, "w") as z:
    for name, text in files.items():
        z.writestr(name, text)
net = m.load_gtfs(gtfs, "10", day=today)
line = net.lines.get("10|C9")
base = time.mktime(today.timetuple())
out["check_gtfs_lines"] = list(net.lines) == ["10|C9"] and line.name == "C9" and line.color == "#FF0000"
out["check_gtfs_stations"] = [s[1] for s in line.stations] == ["Alfa", "Beta", "Gamma", "Delta"]
km_b = line.station_km["90002"]
out["check_gtfs_km"] = near(km_b, 8.52, 0.05) and near(line.length, 25.57, 0.1)
out["check_gtfs_trips"] = (net.trips.get("1099X00001C9") == ("10|C9", 0) and net.trips.get("1099X00002C9") == ("10|C9", 1)
                           and "1098X00009C9" not in net.trips)
sched = net.schedules["1099X00001C9"]
out["check_gtfs_schedule"] = len(sched) == 4 and sched[0][0] == base + 8 * 3600 and sched[1][0] == base + 8 * 3600 + 390
out["check_gtfs_after_midnight"] = net.schedules["1099X00003C9"][-1][0] == base + 24 * 3600 + 480
out["check_gtfs_dest"] = net.dest["1099X00001C9"] == "Lejos" and net.dest["1099X00002C9"] == "Alfa"
out["check_gtfs_title"] = line.title() == "C9 · Alfa – Delta"

# ------------------------------------------------------ geometría a lo largo de la vía
km, off = line.project(40.001, -2.95)
out["check_project"] = near(km, 4.26, 0.03) and near(off, 0.111, 0.005)
lat, lon = line.point_at(km)
out["check_point_at"] = near(lat, 40.0, 1e-6) and near(lon, -2.95, 1e-4)
out["check_next_station"] = line.next_station(km, 0)[1] == "Beta" and line.next_station(km, 1)[1] == "Alfa"
out["check_station_near"] = line.station_near(km_b + 0.2)[1] == "Beta" and line.station_near(km) is None

# ------------------------------------------------------------- GTFS-Realtime (JSON)
now = int(time.time())
def vp(ident, trip, lat, lon, ts, status="IN_TRANSIT_TO", stop="90003", label=None):
    return {"id": "VP_C9-" + ident, "vehicle": {
        "trip": {"tripId": trip}, "position": {"latitude": lat, "longitude": lon},
        "currentStatus": status, "timestamp": str(ts), "stopId": stop,
        "vehicle": {"id": ident, "label": label or "C9-%s-PLATF.(2)" % ident}}}
sample = {"header": {"gtfsRealtimeVersion": "2.0", "timestamp": str(now)}, "entity": [
    vp("00001", "1099X00001C9", 40.001, -2.95, now - 8),
    {"id": "VP_C3-1", "vehicle": {"trip": {"tripId": "3009V12345C3"}, "currentStatus": "IN_TRANSIT_TO",
                                  "vehicle": {"id": "12345", "label": "C3-12345"}}},
    vp("12346", "3009V12346C3", 37.0, -6.0, now, label="C3-12346"),
]}
obs, feed_ts = m.parse_positions(sample, net)
out["check_rt_parse"] = (feed_ts == now and len(obs) == 2 and obs[0]["line"] == "10|C9" and obs[0]["ts"] == now - 8
                         and obs[0]["platform"] == "2" and obs[0]["status"] == "IN_TRANSIT_TO" and obs[0]["stop"] == "90003")
out["check_rt_unknown_line"] = obs[1]["line"] == "30|C3" and obs[1]["platform"] == ""
delays = m.parse_delays({"entity": [
    {"id": "TU1", "tripUpdate": {"trip": {"tripId": "1099X00001C9"}, "delay": 180}},
    {"id": "TU2", "tripUpdate": {"trip": {"tripId": "1099X00002C9"}, "stopTimeUpdate": [{"arrival": {"delay": 300, "time": "1"}, "stopId": "90003"}]}},
    {"id": "TU3", "tripUpdate": {"trip": {"tripId": "X"}}},
]})
out["check_rt_delays"] = delays == {"1099X00001C9": 180, "1099X00002C9": 300}

# ------------------------------------------------- distancia, intervalo y niveles
T = m.Train
lead, foll = T("A"), T("B")
t0 = 1000000
lead.history.extend([[t0, 2.0, ""], [t0 + 60, 3.0, ""], [t0 + 120, 4.0, ""]])
lead.ts, lead.km = t0 + 120, 4.0
foll.ts, foll.km = t0 + 120, 3.0
out["check_headway_history"] = near(m.headway(foll, lead), 60.0, 1e-6)
fresh = T("C"); fresh.ts, fresh.km = t0, 6.0
foll.speed = 60.0
out["check_headway_speed"] = near(m.headway(foll, fresh), 180.0, 1e-6)
# Un salto de la posición (de 8 a 2,5 km en 20 s) no cuenta como paso.
jumpy = T("J"); jumpy.direction = 0
jumpy.history.extend([[t0, 8.0, ""], [t0 + 20, 2.5, ""], [t0 + 40, 8.1, ""]])
jumpy.ts, jumpy.km = t0 + 40, 8.1
back = T("F"); back.ts, back.km, back.speed = t0 + 40, 3.0, 60.0
out["check_headway_jump"] = near(m.headway(back, jumpy), 306.0, 1e-6)
out["check_levels"] = (m.classify(1.0, 60, 2, 2) == "aviso" and m.classify(0.9, 300, 2, 2) == "alerta"
                       and m.classify(3, 200, 2, 2) == "" and m.classify(3, 100, 2, 2) == "aviso"
                       and m.classify(3, 50, 2, 2) == "alerta" and m.classify(3, None, 2, 2) == ""
                       and m.classify(1.5, None, 1, 1) == "")
# Dos trenes del mismo sentido a 1,7 km y uno de vuelta, que no cuenta.
tr = m.Tracker(net)
def feed(entities, ts):
    o, _ = m.parse_positions({"header": {"timestamp": str(ts)}, "entity": entities}, net)
    tr.update(o, ts, delays)
lon_at = lambda k: -3.0 + k / line.length * 0.3
feed([vp("00001", "1099X00001C9", 40.0, lon_at(10.0), t0), vp("00003", "1099X00003C9", 40.0, lon_at(8.3), t0),
      vp("00002", "1099X00002C9", 40.0, lon_at(9.0), t0)], t0)
feed([vp("00001", "1099X00001C9", 40.0, lon_at(11.0), t0 + 60), vp("00003", "1099X00003C9", 40.0, lon_at(9.3), t0 + 60),
      vp("00002", "1099X00002C9", 40.0, lon_at(8.0), t0 + 60)], t0 + 60)
events = m.evaluate(tr.active(t0 + 60), net, 2.0, 2.0)
prox = [e for e in events if e["kind"] == "proximity"]
out["check_proximity"] = (len(prox) == 1 and prox[0]["trains"] == ("00003", "00001") and prox[0]["level"] == "aviso"
                          and near(prox[0]["gap"], 1.7, 0.02))
# El de delante no ha pasado aún por donde está el de detrás: 1,7 km a 60 km/h.
out["check_proximity_headway"] = bool(prox) and near(prox[0]["headway"], 102.0, 1.0)
out["check_delay_from_feed"] = tr.trains["00001"].delay == 180 and tr.trains["00001"].direction == 0
out["check_speed"] = tr.trains["00001"].speed is not None and near(tr.trains["00001"].speed, 60.0, 0.5)
tr.apply(events)
out["check_apply"] = tr.trains["00003"].state == "aviso" and tr.trains["00002"].state == "normal" and tr.trains["00003"].history[-1][2] == "aviso"
out["check_threshold_off"] = not [e for e in m.evaluate(tr.active(t0 + 60), net, 1.0, 0.5) if e["kind"] == "proximity"]
# Dos trenes parados en la misma estación (dos andenes): sin alerta.
tr2 = m.Tracker(net)
o, _ = m.parse_positions({"entity": [vp("00001", "1099X00001C9", 40.0, -2.9, t0, "STOPPED_AT", "90002"),
                                     vp("00003", "1099X00003C9", 40.0, -2.9005, t0, "STOPPED_AT", "90002")]}, net)
tr2.update(o, t0)
out["check_same_station"] = not m.evaluate(tr2.active(t0), net)
# Un tren parado fuera de una estación: aviso a los 3 min, alerta a los 6.
tr3 = m.Tracker(net)
for k in range(0, 8 * 60 + 1, 20):
    o, _ = m.parse_positions({"entity": [vp("00001", "1099X00001C9", 40.0, lon_at(13.0), t0 + k)]}, net)
    tr3.update(o, t0 + k)
    if k == 4 * 60:
        mid = m.evaluate(tr3.active(t0 + k), net)
end = m.evaluate(tr3.active(t0 + 8 * 60), net)
out["check_stopped"] = ([e["level"] for e in mid] == ["aviso"] and [e["level"] for e in end] == ["alerta"]
                        and end[0]["kind"] == "stopped")

# -------------------------------------------------------------------- simulación
sim = m.Simulation(start=1800000000, seed=3)
st = m.Tracker(sim.network)
sim.step(2400)
seen = set()
closest = 99.0
def sim_run(seconds):
    global closest
    stop = sim.clock + seconds
    while sim.clock < stop:
        sim.step(20)
        st.update(sim.observations(), sim.clock)
        evs = m.evaluate(st.active(sim.clock), sim.network)
        st.apply(evs)
        for e in evs:
            seen.add((e["kind"], e["level"], e["line"]))
        groups = {}
        for t in sim.trains:
            if sim.clock >= t.start - m.DWELL and not t.done:
                groups.setdefault((t.line.key, t.direction), []).append(t.s)
        for ss in groups.values():
            ss.sort()
            for a, b in zip(ss, ss[1:]):
                closest = min(closest, b - a)
out["sim_trains"] = len(sim.trains)
victim = sim.force_incident("C3", 540)
out["check_sim_incident"] = victim is not None
sim_run(900)
out["sim_seen"] = sorted(seen)
out["check_sim_convergence"] = ("proximity", "alerta", "SIM|C3") in seen
out["check_sim_stopped"] = any(k == "stopped" and l == "SIM|C3" for k, _, l in seen)
out["check_sim_no_collision"] = closest >= m.SAFE_GAP * 0.85
out["sim_closest"] = closest
obs = sim.observations()
out["check_sim_obs"] = all(o["line"] in sim.network.lines for o in obs) and len(obs) >= 20
out["check_sim_delay"] = any(o["delay"] > 120 for o in obs) and all(o["delay"] > -120 for o in obs)
out["check_sim_schedules"] = all(t.trip in sim.network.schedules for t in sim.trains)

# ------------------------------------------------------------- descarga (sin red)
dest = os.path.join(sys.argv[2], "copy.zip")
told = []
m.download("file://" + gtfs.replace(os.sep, "/") if os.name != "nt" else "file:///" + gtfs.replace(os.sep, "/"),
           dest, progress=lambda d, t: told.append((d, t)))
out["check_download"] = os.path.exists(dest) and zipfile.is_zipfile(dest) and not os.path.exists(dest + ".part")
bad = os.path.join(sys.argv[2], "bad.txt")
open(bad, "w").write("hola")
try:
    m.download("file://" + bad.replace(os.sep, "/"), os.path.join(sys.argv[2], "bad.zip"))
    out["check_download_bad"] = False
except OSError:
    out["check_download_bad"] = not os.path.exists(os.path.join(sys.argv[2], "bad.zip"))

# ------------------------------------------------------------- la ventana
def pump(cond, seconds=20):
    end = time.time() + seconds
    while time.time() < end:
        f.root.update()
        if cond():
            return True
        time.sleep(0.02)
    return False

calls = []
def offline(url, timeout=15):
    calls.append(url)
    raise OSError("sin red")
m.fetch_json = offline
f = m.Form1()
f.root.update()
out["check_offline_to_sim"] = pump(lambda: f.source == m.SIM) and f.Source_var.get() == m.SIM
out["check_offline_message"] = f.Status.cget("text") == m.OFFLINE.format("sin red")
f.Timer1.stop()
f.root.update()
out["check_window_size"] = f.root.winfo_width() <= 1100 and f.root.winfo_height() <= 720
out["check_sim_lines"] = len(f.LineBox.cget("values")) == 3 and f.current_line() is not None
rows = f.Trains.get_children()
out["check_train_rows"] = len(rows) >= 4
out["check_graph_drawn"] = len(f.Graph.find_all()) > 40 and len(f.graph_hits) > 20
out["check_map_drawn"] = len(f.Map.find_withtag("train")) == len(rows)
hx, hy, hid = f.graph_hits[len(f.graph_hits) // 2]
class E: pass
ev = E(); ev.x, ev.y = int(hx), int(hy)
f.Graph_motion(ev)
out["check_tooltip"] = bool(f.Graph.find_withtag("tip"))
f.Graph_leave()
mx, my, mid_id = f.map_hits[0]
ev.x, ev.y = int(mx) + 2, int(my) + 1
f.Map_click(ev)
out["check_map_click"] = f.selected is not None and f.Trains.selection() == (f.selected,) and f.selected in [h[2] for h in f.map_hits]
for title in f.LineBox.cget("values"):
    f.LineBox_var.set(title)
    f.LineBox_select()
    f.root.update()
out["check_line_switch"] = f.settings["line"] == "SIM|C1" and len(f.Graph.find_all()) > 40
f.Speed_var.set("×30")
f.Speed_select()
for _ in range(40):
    f.Timer1_timer()
out["check_ticks"] = f.sim.clock > time.time() + 600
f.sim.force_incident(None, 600)
for _ in range(40):
    f.Timer1_timer()
f.root.update()
out["check_alert_rows"] = len(f.Alerts.get_children()) > 0
out["check_banner"] = f.Banner.cget("text") != ""
f.WarnKm_var.set("5 km")
f.WarnKm_select()
f.WarnMin_var.set("5 min")
f.WarnMin_select()
out["check_wider_threshold"] = len(f.events) >= 1
f.BtnHelp_click()
f.form_close()
out["check_settings"] = json.load(open(m.settings_path()))["source"] == m.SIM

# ------------------------------------------- en directo, con datos inventados
os.replace(gtfs, m.gtfs_path())
now = int(time.time())
live = {"n": 0}
def positions(n):
    t = now + 20 * n
    return {"header": {"gtfsRealtimeVersion": "2.0", "timestamp": str(t)}, "entity": [
        vp("00001", "1099X00001C9", 40.0, lon_at(12.0 + 0.3 * n), t),
        vp("00003", "1099X00003C9", 40.0, lon_at(8.0 + 1.2 * n), t),
        vp("00002", "1099X00002C9", 40.0, lon_at(20.0 - 0.3 * n), t, label="C9-00002"),
    ]}
def fake(url, timeout=15):
    calls.append(url)
    if "vehicle_positions" in url:
        live["n"] += 1
        return positions(live["n"] - 1)
    return {"entity": [{"id": "TU", "tripUpdate": {"trip": {"tripId": "1099X00001C9"}, "delay": 240}}]}
m.fetch_json = fake
f = m.Form1()  # se acuerda de la simulación
f.Timer1.stop()
f.root.update()
out["check_restart_sim"] = f.source == m.SIM
f.Source_var.set(m.LIVE)
f.Source_change()
out["check_live_loaded"] = pump(lambda: f.source == m.LIVE and f.network is not None and f.Trains.get_children())
out["check_live_urls"] = m.VEHICLES_URL in calls and m.TRIPS_URL in calls
out["check_live_line"] = f.settings.get("line") == "10|C9" and f.LineBox_var.get() == "C9 · Alfa – Delta"
rows = f.Trains.get_children()
out["check_live_rows"] = set(rows) == {"00001", "00002", "00003"}
out["check_live_delay"] = f.Trains.item("00001", "values")[3] == "+4 min"
out["check_live_platform"] = "2" in f.Trains.item("00001", "values")[2]
out["check_live_status"] = f.Status.cget("text").startswith(m.LIVE_OK.split("{")[0])
out["check_attrib"] = "Renfe Operadora" in f.Attrib.cget("text") and "CC BY 4.0" in f.Attrib.cget("text")
out["check_live_graph"] = len(f.Graph.find_all()) > 20 and len(f.Map.find_withtag("train")) == 3
for n in range(1, 4):
    f.last_fetch = 0
    f.Timer1_timer()
    pump(lambda: not f.feed_busy, 5)
out["check_live_polls"] = live["n"] == 4
# 00003 va más deprisa y alcanza a 00001: de 4 km a 1,3 km.
out["check_live_alert"] = any(e["kind"] == "proximity" and e["trains"] == ("00003", "00001") for e in f.events)
out["check_live_alert_row"] = len(f.Alerts.get_children()) >= 1
out["live_status"] = f.Status.cget("text")
f.form_close()
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';
