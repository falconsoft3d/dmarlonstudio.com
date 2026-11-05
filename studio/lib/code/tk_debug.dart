import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/settings.dart';

/// Un marco de la pila de llamadas al detenerse.
class TkDebugFrame {
  const TkDebugFrame({
    required this.func,
    required this.file,
    required this.line,
    required this.user,
    this.unitLine,
  });

  final String func;
  final String file;

  /// Línea del archivo generado.
  final int line;

  /// Es código del usuario (su `Form1.py`).
  final bool user;

  /// Línea en el código del usuario (null: código generado o de Python).
  final int? unitLine;
}

/// Una variable (o un elemento de una lista, un campo de un objeto…).
class TkDebugVar {
  const TkDebugVar(this.name, this.type, this.value, this.ref);

  factory TkDebugVar.fromJson(Map j) => TkDebugVar(
    '${j['name'] ?? ''}',
    '${j['type'] ?? ''}',
    '${j['value'] ?? ''}',
    j['ref'] as String?,
  );

  final String name;
  final String type;
  final String value;

  /// Referencia para pedir sus hijos (null: no se despliega).
  final String? ref;
}

/// Una línea de la consola de evaluación.
class TkDebugEval {
  const TkDebugEval(this.expr, this.result, {this.ok = true, this.ref});
  final String expr;
  final String result;
  final bool ok;
  final String? ref;
}

/// Resultado de una prueba de unittest.
class TkTestResult {
  const TkTestResult(this.name, this.status, this.message);
  final String name;

  /// ok, fail, error o skip.
  final String status;
  final String message;
}

/// Una función en el informe de rendimiento.
class TkDebugStat {
  const TkDebugStat(this.func, this.line, this.calls, this.totalMs, this.maxMs);
  final String func;
  final int? line;
  final int calls;
  final double totalMs;
  final double maxMs;
  double get meanMs => calls == 0 ? 0 : totalMs / calls;
}

/// Una línea ejecutada (historial) o una llamada / vuelta (flujo).
class TkDebugStep {
  const TkDebugStep({
    required this.time,
    required this.thread,
    required this.func,
    this.line,
    this.kind = 'line',
    this.depth = 0,
    this.ms = '',
  });

  final double time;
  final String thread;
  final String func;
  final int? line;

  /// line, call o return.
  final String kind;
  final int depth;
  final String ms;
}

/// Lo que se recuerda entre sesiones mientras la app está abierta.
class TkDebugDefaults {
  TkDebugDefaults._();

  /// never, uncaught o all.
  static String exceptionMode = 'uncaught';
}

/// Puntos de parada por proyecto: línea del código del usuario (desde 1) →
/// condición ('' sin condición). Se guardan en los ajustes.
class TkBreakpoints {
  TkBreakpoints._();

  static final _byProject = <String, Map<int, String>>{};

  /// Cambia con cada punto que se pone o se quita.
  static final changes = ValueNotifier<int>(0);

  static String _key(String project) => 'debug.breakpoints:$project';

  static Map<int, String> of(String project) =>
      _byProject.putIfAbsent(project, () => {});

  static Future<void> load(String project) async {
    if (_byProject.containsKey(project)) return;
    try {
      final raw = await Settings.get(_key(project));
      final map = raw == null ? const {} : jsonDecode(raw) as Map;
      final out = <int, String>{};
      for (final e in map.entries) {
        final line = int.tryParse('${e.key}');
        if (line != null) out[line] = '${e.value}';
      }
      _byProject[project] = out;
    } on Object {
      _byProject[project] = {};
    }
    _notify();
  }

  static void toggle(String project, int line) {
    final m = of(project);
    if (m.remove(line) == null) m[line] = '';
    _save(project);
  }

  static void setCondition(String project, int line, String condition) {
    of(project)[line] = condition.trim();
    _save(project);
  }

  static void remove(String project, int line) {
    of(project).remove(line);
    _save(project);
  }

  static void clear(String project) {
    of(project).clear();
    _save(project);
  }

  /// Quita los puntos de líneas que ya no existen.
  static void trim(String project, int lines) {
    final m = of(project);
    final before = m.length;
    m.removeWhere((line, _) => line > lines);
    if (m.length != before) _save(project);
  }

  static void _save(String project) {
    _notify();
    final m = of(project);
    unawaited(() async {
      try {
        await Settings.set(
          _key(project),
          m.isEmpty
              ? null
              : jsonEncode({for (final e in m.entries) '${e.key}': e.value}),
        );
      } on Object {
        // Sin base (pruebas): solo en memoria.
      }
    }());
  }

  static void _notify() => changes.value++;
}

/// Una sesión del depurador: el servidor local al que se conecta el agente
/// (build/dms_debug.py), y lo que cuenta mientras el programa corre.
class TkDebugSession extends ChangeNotifier {
  TkDebugSession({
    required this.project,
    required this.unitStart,
    required this.unitLines,
    this.tests = false,
    this.trace = true,
    this.exceptionMode = 'uncaught',
  });

  /// Con el trazador: puntos de parada, pasos, historial y rendimiento. Sin
  /// él (pruebas sin depurar) solo llegan los resultados.
  final bool trace;

  final String project;

  /// Líneas del archivo generado antes del código del usuario.
  final int unitStart;
  final int unitLines;

  /// Ejecuta las pruebas (unittest) en lugar del programa.
  final bool tests;

  /// never, uncaught o all.
  String exceptionMode;

  final String token = List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  ServerSocket? _server;
  Socket? _socket;
  final _pending = <int, Completer<Map>>{};
  var _nextId = 0;

  bool connected = false;
  bool paused = false;
  bool ended = false;
  String? python;

  /// Por qué se detuvo: breakpoint, step, pause, cursor o exception.
  String? reason;
  String? note;
  Map? exception;
  String? thread;
  List<TkDebugFrame> frames = const [];
  int frameIndex = 0;
  List<TkDebugVar> locals = const [];
  List<TkDebugVar> globals = const [];
  final console = <TkDebugEval>[];

  /// Pruebas: resultados según llegan y el resumen final.
  final testResults = <TkTestResult>[];
  Map? testSummary;

  int get firstLine => unitStart + 1;
  int get lastLine => unitStart + unitLines;

  int? toUnit(int line) {
    final u = line - unitStart;
    return u >= 1 && u <= unitLines ? u : null;
  }

  int toGenerated(int unitLine) => unitStart + unitLine;

  /// Línea del usuario donde está detenido (marco elegido).
  int? get currentLine =>
      paused && frameIndex < frames.length ? frames[frameIndex].unitLine : null;

  /// Escucha en 127.0.0.1 y devuelve el puerto para el agente.
  Future<int> listen() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_accept);
    return server.port;
  }

  void _accept(Socket socket) {
    if (_socket != null) {
      socket.destroy();
      return;
    }
    var hello = false;
    socket
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            Map msg;
            try {
              msg = jsonDecode(line) as Map;
            } on FormatException {
              return;
            }
            if (!hello) {
              // Solo el agente de esta ejecución conoce el token.
              if (msg['ev'] != 'hello' || msg['token'] != token) {
                socket.destroy();
                return;
              }
              hello = true;
              _socket = socket;
              _server?.close();
              _server = null;
              connected = true;
              python = '${msg['python'] ?? ''}';
              _configure();
              notifyListeners();
              return;
            }
            _event(msg);
          },
          onDone: _closed,
          onError: (_) => _closed(),
          cancelOnError: true,
        );
  }

  void _configure() {
    sendBreakpoints();
    _send({'cmd': 'exceptions', 'mode': exceptionMode});
    _send({'cmd': 'start'});
  }

  void _send(Map cmd) {
    final s = _socket;
    if (s == null || ended) return;
    try {
      s.write('${jsonEncode(cmd)}\n');
    } on Object {
      // El proceso terminó.
    }
  }

  Future<Map> _request(Map cmd) {
    final id = ++_nextId;
    final c = Completer<Map>();
    _pending[id] = c;
    _send({...cmd, 'id': id});
    return c.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        return {'ok': false, 'error': 'timeout'};
      },
    );
  }

  void _event(Map msg) {
    switch (msg['ev']) {
      case 'stopped':
        paused = true;
        reason = msg['reason'] as String?;
        note = msg['note'] as String?;
        exception = msg['exception'] as Map?;
        thread = msg['thread'] as String?;
        frames = [
          for (final f in (msg['frames'] as List? ?? const []).cast<Map>())
            TkDebugFrame(
              func: '${f['func']}',
              file: '${f['file']}',
              line: f['line'] as int? ?? 0,
              user: f['user'] == true,
              unitLine: f['user'] == true
                  ? toUnit(f['line'] as int? ?? 0)
                  : null,
            ),
        ];
        // El primer marco del usuario.
        frameIndex = max(0, frames.indexWhere((f) => f.unitLine != null));
        locals = globals = const [];
        notifyListeners();
        unawaited(loadScopes());
      case 'running':
        paused = false;
        frames = const [];
        locals = globals = const [];
        notifyListeners();
      case 'result':
        _pending.remove(msg['id'])?.complete(msg);
      case 'test':
        testResults.add(
          TkTestResult(
            '${msg['name']}',
            '${msg['status']}',
            '${msg['message'] ?? ''}',
          ),
        );
        notifyListeners();
      case 'tests':
        testSummary = msg;
        notifyListeners();
      case 'exit':
        _closed();
    }
  }

  void _closed() {
    if (ended) return;
    ended = true;
    paused = false;
    connected = false;
    for (final c in _pending.values) {
      c.complete({'ok': false, 'error': 'ended'});
    }
    _pending.clear();
    _socket?.destroy();
    _server?.close();
    notifyListeners();
  }

  /// El proceso terminó (aunque el agente no llegara a conectarse).
  void finished() => _closed();

  // ------------------------------------------------------------- órdenes
  void sendBreakpoints() {
    _send({
      'cmd': 'breakpoints',
      'lines': {
        for (final e in TkBreakpoints.of(project).entries)
          if (e.key >= 1 && e.key <= unitLines)
            '${toGenerated(e.key)}': e.value,
      },
    });
  }

  void setExceptionMode(String mode) {
    exceptionMode = mode;
    _send({'cmd': 'exceptions', 'mode': mode});
    notifyListeners();
  }

  void resume() => _resume('continue');
  void stepInto() => _resume('into');
  void stepOver() => _resume('over');
  void stepOut() => _resume('out');

  /// Sigue hasta la línea [unitLine] del código del usuario.
  void runTo(int unitLine) => _resume('to', {'line': toGenerated(unitLine)});

  void _resume(String cmd, [Map extra = const {}]) {
    if (!paused) return;
    _send({'cmd': cmd, ...extra});
  }

  void pause() {
    if (connected && !paused) _send({'cmd': 'pause'});
  }

  void selectFrame(int i) {
    if (i < 0 || i >= frames.length) return;
    frameIndex = i;
    notifyListeners();
    unawaited(loadScopes());
  }

  Future<void> loadScopes() async {
    final i = frameIndex;
    final l = await children('L$i');
    final g = await children('G$i');
    if (i != frameIndex || !paused) return;
    locals = l;
    globals = g;
    notifyListeners();
  }

  /// Los hijos de una referencia (`L<marco>`, `G<marco>` u `O<n>`).
  Future<List<TkDebugVar>> children(String ref) async {
    if (!paused) return const [];
    final r = await _request({'cmd': 'vars', 'ref': ref});
    if (r['ok'] != true) return const [];
    return [
      for (final v in (r['items'] as List? ?? const []).cast<Map>())
        TkDebugVar.fromJson(v),
    ];
  }

  /// Evalúa [expr] en el marco elegido (también asignaciones: `x = 5`).
  Future<TkDebugEval> evaluate(String expr) async {
    final r = paused
        ? await _request({'cmd': 'evaluate', 'expr': expr, 'frame': frameIndex})
        : {'ok': false, 'error': 'running'};
    final e = r['ok'] == true
        ? TkDebugEval(expr, '${r['value']}', ref: r['ref'] as String?)
        : TkDebugEval(expr, '${r['error']}', ok: false);
    console.add(e);
    if (console.length > 200) console.removeAt(0);
    notifyListeners();
    // Una asignación cambia las variables.
    if (r['ok'] == true) unawaited(loadScopes());
    return e;
  }

  Future<List<TkDebugStep>> history() async {
    final r = await _request({'cmd': 'history', 'limit': 1000});
    return [
      for (final i in (r['items'] as List? ?? const []).cast<List>())
        TkDebugStep(
          time: (i[0] as num).toDouble(),
          thread: '${i[1]}',
          func: '${i[2]}',
          line: toUnit(i[3] as int),
        ),
    ];
  }

  Future<List<TkDebugStep>> flow() async {
    final r = await _request({'cmd': 'flow', 'limit': 1000});
    return [
      for (final i in (r['items'] as List? ?? const []).cast<List>())
        TkDebugStep(
          kind: '${i[0]}',
          time: (i[1] as num).toDouble(),
          thread: '${i[2]}',
          depth: i[3] as int,
          func: '${i[4]}',
          line: toUnit(i[5] as int),
          ms: '${i[6]}',
        ),
    ];
  }

  /// Funciones por tiempo y las líneas más ejecutadas (línea, veces).
  Future<(List<TkDebugStat>, List<(int, int)>)> stats() async {
    final r = await _request({'cmd': 'stats'});
    final funcs = [
      for (final f in (r['functions'] as List? ?? const []).cast<List>())
        TkDebugStat(
          '${f[0]}',
          toUnit(f[1] as int),
          f[2] as int,
          (f[3] as num).toDouble(),
          (f[4] as num).toDouble(),
        ),
    ];
    final lines = <(int, int)>[
      for (final l in (r['lines'] as List? ?? const []).cast<List>())
        if (toUnit(l[0] as int) case final u?) (u, l[1] as int),
    ];
    return (funcs, lines);
  }

  /// Objetos vivos de las clases del programa (tipo, cuántos).
  Future<List<(String, int)>> objects() async {
    final r = await _request({'cmd': 'objects'});
    return [
      for (final o in (r['items'] as List? ?? const []).cast<List>())
        ('${o[0]}', o[1] as int),
    ];
  }

  Future<void> resetStats() => _request({'cmd': 'reset'});

  @override
  void dispose() {
    _closed();
    super.dispose();
  }
}
