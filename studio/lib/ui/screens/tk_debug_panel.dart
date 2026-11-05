import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:re_editor/re_editor.dart';

import '../../code/tk_debug.dart';
import '../../i18n/i18n.dart';

// Colores del panel inferior (siempre oscuro, como la consola).
const _bg = Color(0xFF1E1E1E);
const _fg = Color(0xFFD4D4D4);
const _dim = Color(0xFF8C8C8C);
const _line = Color(0xFF333333);
const _accent = Color(0xFF4FC1FF);
const _ok = Color(0xFF4EC9B0);
const _bad = Color(0xFFF14C4C);
const _warn = Color(0xFFCCA700);
const _mono = 'Menlo';
const _monoFallback = ['Consolas', 'Monaco', 'Courier New', 'monospace'];
const _text = TextStyle(color: _fg, fontSize: 12);
const _code = TextStyle(
  color: _fg,
  fontSize: 12,
  fontFamily: _mono,
  fontFamilyFallback: _monoFallback,
);

/// Color de los puntos de parada y de la línea en curso.
const tkBreakpointColor = Color(0xFFE51400);
const tkCurrentLineColor = Color(0xFFFFCC00);

// ---------------------------------------------------------------- margen
/// Margen del editor con los puntos de parada (clic: poner o quitar; clic
/// derecho: condición) y la flecha de la línea en la que está detenido.
class TkBreakpointGutter extends StatelessWidget {
  const TkBreakpointGutter({
    super.key,
    required this.controller,
    required this.notifier,
    required this.project,
    this.current,
    this.onCondition,
  });

  final CodeLineEditingController controller;
  final CodeIndicatorValueNotifier notifier;
  final String project;

  /// Línea (desde 1) en la que está detenido el depurador.
  final int? current;
  final void Function(int line)? onCondition;

  int? _lineAt(double dy) {
    final value = notifier.value;
    if (value == null) return null;
    for (final para in value.paragraphs) {
      if (dy >= para.top && dy < para.bottom) {
        return controller.index2lineIndex(para.index) + 1;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('tk-gutter'),
    behavior: HitTestBehavior.opaque,
    onTapUp: (d) {
      final line = _lineAt(d.localPosition.dy);
      if (line != null) TkBreakpoints.toggle(project, line);
    },
    onSecondaryTapUp: (d) {
      final line = _lineAt(d.localPosition.dy);
      if (line != null) onCondition?.call(line);
    },
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      // Solo se repinta: el editor cambia las líneas mientras se coloca.
      child: CustomPaint(
        size: const Size(26, double.infinity),
        painter: _GutterPainter(
          notifier: notifier,
          lineOf: (i) => controller.index2lineIndex(i) + 1,
          project: project,
          current: current,
        ),
      ),
    ),
  );
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.notifier,
    required this.lineOf,
    required this.project,
    required this.current,
  }) : super(repaint: Listenable.merge([notifier, TkBreakpoints.changes]));

  final CodeIndicatorValueNotifier notifier;
  final int Function(int index) lineOf;
  final String project;
  final int? current;

  @override
  void paint(Canvas canvas, Size size) {
    final points = TkBreakpoints.of(project);
    for (final para in notifier.value?.paragraphs ?? const []) {
      final line = lineOf(para.index);
      final cy = para.top + para.preferredLineHeight / 2;
      final condition = points[line];
      if (condition != null) {
        final paint = Paint()..color = tkBreakpointColor;
        canvas.drawCircle(Offset(8, cy), 5, paint);
        if (condition.isNotEmpty) {
          // Con condición: un punto blanco dentro.
          canvas.drawCircle(Offset(8, cy), 1.8, Paint()..color = Colors.white);
        }
      }
      if (line == current) {
        final path = Path()
          ..moveTo(12, cy - 5)
          ..lineTo(18, cy - 5)
          ..lineTo(24, cy)
          ..lineTo(18, cy + 5)
          ..lineTo(12, cy + 5)
          ..close();
        canvas.drawPath(path, Paint()..color = tkCurrentLineColor);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black54
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.current != current || old.project != project;
}

/// Pide la condición de un punto de parada (null: cancelar).
Future<String?> askBreakpointCondition(
  BuildContext context,
  int line,
  String current,
) {
  final ctl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('Condición del punto de parada (línea {0})', [line])),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Una expresión de Python: se detiene solo cuando es verdadera. Vacía: siempre.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('tk-bp-condition'),
              controller: ctl,
              autofocus: true,
              style: const TextStyle(fontFamily: _mono, fontSize: 13),
              decoration: const InputDecoration(hintText: 'n > 10'),
              onSubmitted: (v) => Navigator.pop(c, v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, ctl.text),
          child: Text(tr('Aceptar')),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------------ panel
/// Pestañas del panel inferior.
enum TkDebugTab {
  output,
  variables,
  stack,
  evaluate,
  breakpoints,
  history,
  flow,
  performance,
  objects,
  tests,
}

String tkDebugTabLabel(TkDebugTab t) => switch (t) {
  TkDebugTab.output => tr('Salida'),
  TkDebugTab.variables => tr('Variables'),
  TkDebugTab.stack => tr('Pila'),
  TkDebugTab.evaluate => tr('Evaluar'),
  TkDebugTab.breakpoints => tr('Puntos de parada'),
  TkDebugTab.history => tr('Historial'),
  TkDebugTab.flow => tr('Llamadas'),
  TkDebugTab.performance => tr('Rendimiento'),
  TkDebugTab.objects => tr('Objetos'),
  TkDebugTab.tests => tr('Pruebas'),
};

/// Fila de pestañas para el título del panel inferior.
class TkDebugTabs extends StatelessWidget {
  const TkDebugTabs({
    super.key,
    required this.tab,
    required this.onTab,
    this.trailing,
  });

  final TkDebugTab tab;
  final ValueChanged<TkDebugTab> onTab;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        flex: 4,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in TkDebugTab.values)
                InkWell(
                  key: ValueKey('tk-dbg-tab-${t.name}'),
                  onTap: () => onTab(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: t == tab ? _accent : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Text(
                      tkDebugTabLabel(t),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: t == tab ? _fg : _dim,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (trailing != null) ...[
        const SizedBox(width: 10),
        Flexible(child: trailing!),
      ],
    ],
  );
}

/// Contenido de las pestañas del depurador (todas menos la salida).
class TkDebugPanel extends StatefulWidget {
  const TkDebugPanel({
    super.key,
    required this.tab,
    required this.project,
    required this.session,
    required this.tests,
    required this.lineText,
    required this.onJump,
    required this.onRunTests,
    required this.onCreateTest,
    required this.hasTests,
    this.electron = false,
  });

  /// Proyecto de Electron: se depura con las herramientas de Chromium.
  final bool electron;

  final TkDebugTab tab;
  final String project;

  /// Sesión del programa en marcha (null: no se está depurando).
  final TkDebugSession? session;

  /// Sesión de las últimas pruebas.
  final TkDebugSession? tests;

  /// Texto de la línea [n] del código del usuario.
  final String Function(int n) lineText;
  final void Function(int line) onJump;
  final void Function({required bool debug}) onRunTests;
  final VoidCallback onCreateTest;
  final bool hasTests;

  @override
  State<TkDebugPanel> createState() => _TkDebugPanelState();
}

class _TkDebugPanelState extends State<TkDebugPanel> {
  List<TkDebugStep>? _history;
  List<TkDebugStep>? _flow;
  List<TkDebugStat>? _stats;
  List<(int, int)>? _hot;
  List<(String, int)>? _objects;
  Timer? _timer;
  final _evalCtl = TextEditingController();
  final _evalFocus = FocusNode();
  final _evalScroll = ScrollController();
  String? _openTest;

  TkDebugSession? get s => widget.session;

  @override
  void initState() {
    super.initState();
    s?.addListener(_changed);
    widget.tests?.addListener(_changed);
    _refresh();
    _schedule();
  }

  @override
  void didUpdateWidget(TkDebugPanel old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session?.removeListener(_changed);
      s?.addListener(_changed);
      _history = _flow = null;
      _stats = null;
      _hot = null;
      _objects = null;
    }
    if (old.tests != widget.tests) {
      old.tests?.removeListener(_changed);
      widget.tests?.addListener(_changed);
    }
    if (old.tab != widget.tab || old.session != widget.session) {
      _refresh();
      _schedule();
    }
  }

  @override
  void dispose() {
    s?.removeListener(_changed);
    widget.tests?.removeListener(_changed);
    _timer?.cancel();
    _evalCtl.dispose();
    _evalFocus.dispose();
    _evalScroll.dispose();
    super.dispose();
  }

  bool _wasPaused = false;

  void _changed() {
    if (!mounted) return;
    final paused = s?.paused ?? false;
    // Al detenerse, lo que se ve se pone al día.
    if (paused && !_wasPaused) _refresh();
    _wasPaused = paused;
    setState(() {});
  }

  /// El rendimiento y el historial se refrescan solos mientras corre.
  void _schedule() {
    _timer?.cancel();
    if (s == null) return;
    if (!const {
      TkDebugTab.performance,
      TkDebugTab.history,
      TkDebugTab.flow,
    }.contains(widget.tab)) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (s?.connected == true && !(s?.paused ?? false)) _refresh();
    });
  }

  Future<void> _refresh() async {
    final x = s;
    if (x == null || !x.connected) return;
    switch (widget.tab) {
      case TkDebugTab.history:
        final h = await x.history();
        if (mounted) setState(() => _history = h);
      case TkDebugTab.flow:
        final f = await x.flow();
        if (mounted) setState(() => _flow = f);
      case TkDebugTab.performance:
        final (f, l) = await x.stats();
        if (mounted) {
          setState(() {
            _stats = f;
            _hot = l;
          });
        }
      case TkDebugTab.objects:
        final o = await x.objects();
        if (mounted) setState(() => _objects = o);
      default:
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: _text,
    child: widget.electron && widget.tab != TkDebugTab.breakpoints
        ? _hint(
            widget.tab == TkDebugTab.tests
                ? tr(
                    'Las pruebas de las aplicaciones de Electron llegarán en una próxima versión.',
                  )
                : tr(
                    'En Electron, «Depurar» (Mayús+F9) abre la aplicación con las herramientas de desarrollo de Chromium: se detiene en sus puntos de parada y allí están las variables, la pila, la consola, el paso a paso y el rendimiento. Lo que escribe console.log sale en la pestaña Salida.',
                  ),
          )
        : switch (widget.tab) {
            TkDebugTab.output => const SizedBox.shrink(),
            TkDebugTab.variables => _variables(),
            TkDebugTab.stack => _stack(),
            TkDebugTab.evaluate => _evaluate(),
            TkDebugTab.breakpoints => _breakpoints(),
            TkDebugTab.history => _historyView(),
            TkDebugTab.flow => _flowView(),
            TkDebugTab.performance => _performance(),
            TkDebugTab.objects => _objectsView(),
            TkDebugTab.tests => _testsView(),
          },
  );

  Widget _hint(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _dim, fontSize: 12),
      ),
    ),
  );

  String get _notDebugging => tr(
    'Inicie la depuración con «Depurar» (Mayús+F9). Ponga puntos de parada haciendo clic a la izquierda de los números de línea, en la pestaña Código (F5 en la línea del cursor).',
  );

  Widget? _needPaused() {
    final x = s;
    if (x == null || x.ended) return _hint(_notDebugging);
    if (!x.paused) {
      return _hint(
        tr(
          'El programa está en marcha. Se detendrá en un punto de parada, o pulse Pausar.',
        ),
      );
    }
    return null;
  }

  Widget _bar(List<Widget> children) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(children: children),
  );

  Widget _barButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    Key? key,
  }) => TextButton.icon(
    key: key,
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: _fg,
      disabledForegroundColor: _dim.withValues(alpha: .5),
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 12),
    ),
    icon: Icon(icon, size: 14),
    label: Text(label),
  );

  // ------------------------------------------------------------ variables
  Widget _variables() {
    final wait = _needPaused();
    if (wait != null) return wait;
    final x = s!;
    return ListView(
      key: const ValueKey('tk-dbg-variables'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        _stopBanner(x),
        _section(tr('Locales')),
        if (x.locals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Text(tr('(ninguna)'), style: const TextStyle(color: _dim)),
          ),
        for (final v in x.locals) _VarRow(session: x, v: v, depth: 0),
        _section(tr('Globales')),
        for (final v in x.globals) _VarRow(session: x, v: v, depth: 0),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _dim,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
      ),
    ),
  );

  String _reason(TkDebugSession x) => switch (x.reason) {
    'breakpoint' => tr('Punto de parada'),
    'step' => tr('Paso'),
    'pause' => tr('En pausa'),
    'cursor' => tr('Hasta el cursor'),
    'exception' => tr('Excepción'),
    _ => '${x.reason}',
  };

  Widget _stopBanner(TkDebugSession x) {
    final f = x.frames.isEmpty ? null : x.frames[x.frameIndex];
    final exc = x.exception;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: exc != null ? const Color(0x33F14C4C) : const Color(0x22FFCC00),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              _reason(x),
              if (f != null)
                f.unitLine != null
                    ? tr('{0}, línea {1}', [f.func, f.unitLine])
                    : '${f.func} (${f.file}:${f.line})',
              if (x.thread != null && x.thread != 'MainThread')
                tr('hilo {0}', [x.thread]),
            ].join('  ·  '),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (exc != null)
            SelectableText(
              '${exc['text']}',
              style: _code.copyWith(color: const Color(0xFFFF8A80)),
            ),
          if (x.note != null)
            Text(
              tr('Error en la condición: {0}', [x.note]),
              style: const TextStyle(color: _warn),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- pila
  Widget _stack() {
    final wait = _needPaused();
    if (wait != null) return wait;
    final x = s!;
    final exc = x.exception;
    return ListView(
      key: const ValueKey('tk-dbg-stack'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        _stopBanner(x),
        for (final (i, f) in x.frames.indexed)
          InkWell(
            key: ValueKey('tk-dbg-frame-$i'),
            onTap: () {
              x.selectFrame(i);
              if (f.unitLine != null) widget.onJump(f.unitLine!);
            },
            child: Container(
              color: i == x.frameIndex ? const Color(0xFF094771) : null,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Row(
                children: [
                  Icon(
                    f.user ? LucideIcons.cornerDownRight : LucideIcons.layers,
                    size: 13,
                    color: f.user ? _accent : _dim,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f.func,
                    style: _code.copyWith(color: f.user ? _fg : _dim),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.unitLine != null
                          ? tr('línea {0}: {1}', [
                              f.unitLine,
                              widget.lineText(f.unitLine!).trim(),
                            ])
                          : '${f.file}:${f.line}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _dim, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (exc != null && exc['traceback'] != null) ...[
          _section(tr('Traza')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SelectableText('${exc['traceback']}', style: _code),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------- evaluar
  Future<void> _submitEval() async {
    final text = _evalCtl.text.trim();
    if (text.isEmpty || s == null) return;
    _evalCtl.clear();
    await s!.evaluate(text);
    _evalFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_evalScroll.hasClients) {
        _evalScroll.jumpTo(_evalScroll.position.maxScrollExtent);
      }
    });
  }

  Widget _evaluate() {
    final x = s;
    final ready = x != null && x.paused;
    final lines = x?.console ?? const <TkDebugEval>[];
    return Column(
      children: [
        Expanded(
          child: lines.isEmpty
              ? _hint(
                  ready
                      ? tr(
                          'Escriba una expresión (self.total, len(items)…) o una asignación (n = 5) y pulse Intro: se evalúa en el marco elegido en la pila.',
                        )
                      : x == null
                      ? _notDebugging
                      : tr(
                          'Se puede evaluar cuando el programa está detenido.',
                        ),
                )
              : ListView(
                  key: const ValueKey('tk-dbg-console'),
                  controller: _evalScroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  children: [
                    for (final e in lines) ...[
                      Text('› ${e.expr}', style: _code.copyWith(color: _dim)),
                      if (e.ref != null)
                        _VarRow(
                          session: x!,
                          v: TkDebugVar('', '', e.result, e.ref),
                          depth: 0,
                        )
                      else
                        SelectableText(
                          e.result,
                          style: _code.copyWith(color: e.ok ? _fg : _bad),
                        ),
                    ],
                  ],
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('›', style: TextStyle(color: _accent, fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  key: const ValueKey('tk-dbg-eval'),
                  controller: _evalCtl,
                  focusNode: _evalFocus,
                  enabled: ready,
                  style: _code,
                  cursorColor: _fg,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: tr('Expresión de Python'),
                    hintStyle: const TextStyle(color: _dim, fontSize: 12),
                  ),
                  onSubmitted: (_) => _submitEval(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------- puntos de parada
  Widget _breakpoints() {
    final points = TkBreakpoints.of(widget.project).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final x = s;
    return Column(
      children: [
        if (!widget.electron)
          _bar([
            Text(tr('Detenerse en excepciones:'), style: _text),
            const SizedBox(width: 8),
            DropdownButton<String>(
              key: const ValueKey('tk-dbg-exceptions'),
              value: x?.exceptionMode ?? TkDebugDefaults.exceptionMode,
              dropdownColor: const Color(0xFF252526),
              style: _text,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [
                DropdownMenuItem(value: 'never', child: Text(tr('Nunca'))),
                DropdownMenuItem(
                  value: 'uncaught',
                  child: Text(tr('Las no controladas')),
                ),
                DropdownMenuItem(
                  value: 'all',
                  child: Text(tr('Todas (también las controladas)')),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                TkDebugDefaults.exceptionMode = v;
                x?.setExceptionMode(v);
                setState(() {});
              },
            ),
            const Spacer(),
            _barButton(
              LucideIcons.trash2,
              tr('Quitar todos'),
              points.isEmpty
                  ? null
                  : () {
                      TkBreakpoints.clear(widget.project);
                      s?.sendBreakpoints();
                      setState(() {});
                    },
            ),
          ]),
        Expanded(
          child: points.isEmpty
              ? _hint(
                  tr(
                    'No hay puntos de parada. Haga clic a la izquierda de un número de línea en la pestaña Código, o pulse F5 en la línea del cursor. Con clic derecho se le pone una condición.',
                  ),
                )
              : ListView(
                  key: const ValueKey('tk-dbg-breakpoints'),
                  children: [
                    for (final e in points)
                      InkWell(
                        onTap: () => widget.onJump(e.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: tkBreakpointColor,
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 64,
                                child: Text(tr('línea {0}', [e.key])),
                              ),
                              Expanded(
                                child: Text(
                                  widget.lineText(e.key).trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _code.copyWith(color: _dim),
                                ),
                              ),
                              if (e.value.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    tr('si {0}', [e.value]),
                                    style: _code.copyWith(color: _warn),
                                  ),
                                ),
                              IconButton(
                                tooltip: tr('Condición'),
                                iconSize: 14,
                                color: _dim,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(LucideIcons.textCursorInput),
                                onPressed: () async {
                                  final c = await askBreakpointCondition(
                                    context,
                                    e.key,
                                    e.value,
                                  );
                                  if (c == null) return;
                                  TkBreakpoints.setCondition(
                                    widget.project,
                                    e.key,
                                    c,
                                  );
                                  s?.sendBreakpoints();
                                },
                              ),
                              IconButton(
                                tooltip: tr('Quitar'),
                                iconSize: 14,
                                color: _dim,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(LucideIcons.x),
                                onPressed: () {
                                  TkBreakpoints.remove(widget.project, e.key);
                                  s?.sendBreakpoints();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ historial
  String _clock(double t) {
    final d = DateTime.fromMillisecondsSinceEpoch((t * 1000).round());
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}.'
        '${d.millisecond.toString().padLeft(3, '0')}';
  }

  Widget _refreshBar(String info) => _bar([
    Expanded(
      child: Text(info, style: const TextStyle(color: _dim, fontSize: 11.5)),
    ),
    _barButton(
      LucideIcons.refreshCw,
      tr('Actualizar'),
      s == null ? null : _refresh,
    ),
    _barButton(
      LucideIcons.rotateCcw,
      tr('Reiniciar'),
      s == null
          ? null
          : () async {
              await s!.resetStats();
              await _refresh();
            },
    ),
  ]);

  Widget _historyView() {
    final x = s;
    if (x == null) return _hint(_notDebugging);
    final items = (_history ?? const <TkDebugStep>[]).reversed.toList();
    return Column(
      children: [
        _refreshBar(
          tr(
            'Las últimas líneas de su código que se ejecutaron (la más reciente arriba).',
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('tk-dbg-history'),
            itemCount: items.length,
            itemExtent: 20,
            itemBuilder: (_, i) {
              final h = items[i];
              return InkWell(
                onTap: h.line == null ? null : () => widget.onJump(h.line!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          _clock(h.time),
                          style: _code.copyWith(color: _dim, fontSize: 11),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          h.func,
                          overflow: TextOverflow.ellipsis,
                          style: _code.copyWith(fontSize: 11.5),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${h.line ?? ''}',
                          textAlign: TextAlign.right,
                          style: _code.copyWith(color: _accent, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          h.line == null ? '' : widget.lineText(h.line!).trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _code.copyWith(color: _dim, fontSize: 11.5),
                        ),
                      ),
                      if (h.thread != 'MainThread')
                        Text(
                          h.thread,
                          style: const TextStyle(color: _dim, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ llamadas
  Widget _flowView() {
    final x = s;
    if (x == null) return _hint(_notDebugging);
    final items = _flow ?? const <TkDebugStep>[];
    return Column(
      children: [
        _refreshBar(
          tr(
            'Cada llamada a una función de su código y su vuelta, con lo que tardó.',
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('tk-dbg-flow'),
            itemCount: items.length,
            itemExtent: 20,
            itemBuilder: (_, i) {
              final f = items[i];
              final call = f.kind == 'call';
              return InkWell(
                onTap: f.line == null ? null : () => widget.onJump(f.line!),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 10 + 14.0 * f.depth.clamp(0, 30),
                    right: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        call ? '→ ' : '← ',
                        style: _code.copyWith(color: call ? _accent : _ok),
                      ),
                      Text(
                        call ? '${f.func}()' : f.func,
                        style: _code.copyWith(fontSize: 11.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        call
                            ? tr('línea {0}', [f.line ?? '?'])
                            : tr('{0} ms', [f.ms]),
                        style: const TextStyle(color: _dim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------- rendimiento
  Widget _performance() {
    final x = s;
    if (x == null) return _hint(_notDebugging);
    final rows = _stats ?? const <TkDebugStat>[];
    final hot = _hot ?? const <(int, int)>[];
    final maxTotal = rows.isEmpty
        ? 1.0
        : rows.map((r) => r.totalMs).reduce((a, b) => a > b ? a : b);
    Widget cell(String t, double w, {bool right = true, Color? color}) =>
        SizedBox(
          width: w,
          child: Text(
            t,
            textAlign: right ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: _code.copyWith(fontSize: 11.5, color: color),
          ),
        );
    return Column(
      children: [
        _refreshBar(
          tr(
            'Tiempo dentro de cada función de su código (sin contar las pausas del depurador). Se actualiza solo.',
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('tk-dbg-performance'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              Row(
                children: [
                  cell(tr('Función'), 180, right: false, color: _dim),
                  cell(tr('Línea'), 50, color: _dim),
                  cell(tr('Llamadas'), 70, color: _dim),
                  cell(tr('Total ms'), 80, color: _dim),
                  cell(tr('Media ms'), 80, color: _dim),
                  cell(tr('Máx. ms'), 80, color: _dim),
                ],
              ),
              for (final r in rows)
                InkWell(
                  onTap: r.line == null ? null : () => widget.onJump(r.line!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        cell(r.func, 180, right: false),
                        cell('${r.line ?? ''}', 50, color: _accent),
                        cell('${r.calls}', 70),
                        cell(r.totalMs.toStringAsFixed(2), 80),
                        cell(r.meanMs.toStringAsFixed(3), 80),
                        cell(r.maxMs.toStringAsFixed(2), 80),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (r.totalMs / maxTotal).clamp(
                                .01,
                                1.0,
                              ),
                              child: Container(height: 6, color: _accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hot.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  tr('Líneas más ejecutadas'),
                  style: const TextStyle(color: _dim, fontSize: 11.5),
                ),
                for (final (line, n) in hot.take(12))
                  InkWell(
                    onTap: () => widget.onJump(line),
                    child: Row(
                      children: [
                        cell('$line', 50, color: _accent),
                        cell('×$n', 80),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.lineText(line).trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _code.copyWith(color: _dim, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (rows.isEmpty && hot.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    tr('Aún no se ha ejecutado ninguna función de su código.'),
                    style: const TextStyle(color: _dim),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- objetos
  Widget _objectsView() {
    final x = s;
    if (x == null) return _hint(_notDebugging);
    final items = _objects ?? const <(String, int)>[];
    return Column(
      children: [
        _bar([
          Expanded(
            child: Text(
              tr(
                'Objetos vivos de las clases de su programa (y componentes de tkinter). Para ver su estado, despliéguelos en Variables.',
              ),
              style: const TextStyle(color: _dim, fontSize: 11.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _barButton(LucideIcons.refreshCw, tr('Actualizar'), _refresh),
        ]),
        Expanded(
          child: ListView(
            key: const ValueKey('tk-dbg-objects'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              for (final (type, n) in items)
                Row(
                  children: [
                    SizedBox(width: 220, child: Text(type, style: _code)),
                    Text('$n', style: _code.copyWith(color: _accent)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- pruebas
  Widget _testsView() {
    final t = widget.tests;
    final results = t?.testResults ?? const <TkTestResult>[];
    final summary = t?.testSummary;
    final running = t != null && !t.ended;
    return Column(
      children: [
        _bar([
          _barButton(
            LucideIcons.play,
            tr('Ejecutar pruebas'),
            running || !widget.hasTests
                ? null
                : () => widget.onRunTests(debug: false),
            key: const ValueKey('tk-tests-run'),
          ),
          _barButton(
            LucideIcons.bugPlay,
            tr('Depurar pruebas'),
            running || !widget.hasTests
                ? null
                : () => widget.onRunTests(debug: true),
            key: const ValueKey('tk-tests-debug'),
          ),
          _barButton(
            LucideIcons.flaskConical,
            tr('Crear una prueba de ejemplo'),
            widget.onCreateTest,
            key: const ValueKey('tk-tests-create'),
          ),
          const Spacer(),
          if (running)
            Text(tr('En marcha…'), style: const TextStyle(color: _dim))
          else if (summary != null)
            Text(
              tr('{0} pruebas · {1} fallos · {2} errores · {3} omitidas', [
                summary['run'],
                summary['failures'],
                summary['errors'],
                summary['skipped'],
              ]),
              style: TextStyle(
                color:
                    (summary['failures'] as int? ?? 0) +
                            (summary['errors'] as int? ?? 0) ==
                        0
                    ? _ok
                    : _bad,
              ),
            ),
        ]),
        Expanded(
          child: results.isEmpty
              ? _hint(
                  widget.hasTests
                      ? tr(
                          'Las pruebas están en la carpeta tests del proyecto (archivos test_*.py con unittest). Importan su programa con «from dms_app import Form1».',
                        )
                      : tr(
                          'Aún no hay pruebas. «Crear una prueba de ejemplo» añade tests/test_form1.py al proyecto: pruebas de unittest que importan su programa con «from dms_app import Form1».',
                        ),
                )
              : ListView(
                  key: const ValueKey('tk-tests-results'),
                  children: [
                    for (final r in results) ...[
                      InkWell(
                        onTap: r.message.isEmpty
                            ? null
                            : () => setState(
                                () => _openTest = _openTest == r.name
                                    ? null
                                    : r.name,
                              ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                switch (r.status) {
                                  'ok' => LucideIcons.circleCheck,
                                  'skip' => LucideIcons.circleMinus,
                                  'fail' => LucideIcons.circleX,
                                  _ => LucideIcons.circleAlert,
                                },
                                size: 14,
                                color: switch (r.status) {
                                  'ok' => _ok,
                                  'skip' => _dim,
                                  _ => _bad,
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: _code.copyWith(fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_openTest == r.name)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 10, 6),
                          child: SelectableText(
                            r.message,
                            style: _code.copyWith(
                              fontSize: 11.5,
                              color: const Color(0xFFFF8A80),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Una variable que se despliega (sus campos, elementos o claves).
class _VarRow extends StatefulWidget {
  const _VarRow({required this.session, required this.v, required this.depth});

  final TkDebugSession session;
  final TkDebugVar v;
  final int depth;

  @override
  State<_VarRow> createState() => _VarRowState();
}

class _VarRowState extends State<_VarRow> {
  bool _open = false;
  List<TkDebugVar>? _kids;

  Future<void> _toggle() async {
    if (widget.v.ref == null) return;
    if (_open) return setState(() => _open = false);
    _kids ??= await widget.session.children(widget.v.ref!);
    if (mounted) setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.v;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: v.ref == null ? null : _toggle,
          onLongPress: () => Clipboard.setData(ClipboardData(text: v.value)),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + widget.depth * 14,
              right: 10,
              top: 1,
              bottom: 1,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 14,
                  child: v.ref == null
                      ? null
                      : Icon(
                          _open
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 12,
                          color: _dim,
                        ),
                ),
                if (v.name.isNotEmpty) ...[
                  Text(
                    v.name,
                    style: _code.copyWith(color: const Color(0xFF9CDCFE)),
                  ),
                  const Text(' = ', style: TextStyle(color: _dim)),
                ],
                Expanded(
                  child: Text(
                    v.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _code.copyWith(color: const Color(0xFFCE9178)),
                  ),
                ),
                if (v.type.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      v.type,
                      style: const TextStyle(color: _dim, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final k in _kids ?? const <TkDebugVar>[])
            _VarRow(session: widget.session, v: k, depth: widget.depth + 1),
      ],
    );
  }
}

/// Plantilla de la prueba de ejemplo (tests/test_form1.py).
String tkTestTemplate({required bool web, required String form}) => web
    ? '''import unittest

from dms_app import app


class TestApp(unittest.TestCase):
    """Pruebas de la aplicación web: el cliente de pruebas de Flask."""

    def setUp(self):
        self.client = app.test_client()

    def test_home_page(self):
        reply = self.client.get("/")
        self.assertEqual(reply.status_code, 200)


if __name__ == "__main__":
    unittest.main()
'''
    : '''import unittest

from dms_app import $form


class Test$form(unittest.TestCase):
    """Pruebas de la ventana: se crea sin mostrarla."""

    def setUp(self):
        self.form = $form()
        self.form.root.withdraw()

    def tearDown(self):
        self.form.root.destroy()

    def test_title(self):
        self.assertTrue(self.form.root.title())


if __name__ == "__main__":
    unittest.main()
''';

/// Por si se usa como fondo.
const tkDebugBackground = _bg;
