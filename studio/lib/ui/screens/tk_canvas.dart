import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../code/tk_codegen.dart';
import '../../code/tk_model.dart';

/// Rejilla del diseñador, en píxeles.
const tkGrid = 8;

/// Icono de cada componente en la paleta y en el árbol.
IconData tkIcon(String kind) => switch (kind) {
  'Label' => LucideIcons.type,
  'Button' => LucideIcons.squareMousePointer,
  'Entry' => LucideIcons.textCursorInput,
  'Text' => LucideIcons.fileText,
  'Checkbutton' => LucideIcons.squareCheck,
  'Radiobutton' => LucideIcons.circleDot,
  'Listbox' => LucideIcons.list,
  'Combobox' => LucideIcons.chevronsUpDown,
  'Scale' => LucideIcons.slidersHorizontal,
  'Frame' => LucideIcons.square,
  'Canvas' => LucideIcons.brush,
  'Treeview' => LucideIcons.table,
  'Connection' => LucideIcons.database,
  _ => LucideIcons.box,
};

/// Color de Tk: hexadecimal o uno de los nombres habituales.
Color tkColor(String? v, Color fallback) {
  final s = (v ?? '').trim().toLowerCase();
  final long = RegExp(r'^#([0-9a-f]{6})$').firstMatch(s);
  if (long != null) return Color(0xFF000000 | int.parse(long[1]!, radix: 16));
  final short = RegExp(r'^#([0-9a-f])([0-9a-f])([0-9a-f])$').firstMatch(s);
  if (short != null) {
    final h =
        '${short[1]}${short[1]}${short[2]}${short[2]}${short[3]}${short[3]}';
    return Color(0xFF000000 | int.parse(h, radix: 16));
  }
  return switch (s) {
    'white' => Colors.white,
    'black' => Colors.black,
    'red' => const Color(0xFFFF0000),
    'green' => const Color(0xFF00A000),
    'blue' => const Color(0xFF0000FF),
    'yellow' => const Color(0xFFFFFF00),
    'gray' || 'grey' => const Color(0xFF808080),
    'orange' => const Color(0xFFFFA500),
    _ => fallback,
  };
}

/// Aspecto de un componente en el diseño: una aproximación, cada sistema
/// dibuja los suyos.
class TkPreview extends StatelessWidget {
  const TkPreview(this.design, this.w, {super.key});
  final TkDesign design;
  final TkWidget w;

  static const _panel = Color(0xFFE4E5E7);
  static const _edge = Color(0xFF8A8F98);

  Widget _face({
    required Color color,
    required Widget child,
    bool sunken = true,
    AlignmentGeometry align = Alignment.centerLeft,
  }) => Container(
    alignment: align,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: color,
      border: Border(
        top: BorderSide(color: sunken ? _edge : Colors.white),
        left: BorderSide(color: sunken ? _edge : Colors.white),
        right: BorderSide(color: sunken ? Colors.white : _edge),
        bottom: BorderSide(color: sunken ? Colors.white : _edge),
      ),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final bg = tkColor(TkCodegen.backgroundOf(design, w), _panel);
    final ownBg = w.props['bg'] == null
        ? null
        : tkColor('${w.props['bg']}', bg);
    final fg = tkColor(
      w.props['fg'] as String?,
      tkColor(
        TkCodegen.contrast(TkCodegen.backgroundOf(design, w)),
        Colors.black,
      ),
    );
    final size = (w.props['font_size'] as num?)?.toDouble() ?? 12;
    final style = TextStyle(
      fontFamily: (w.props['font_family'] as String?) ?? 'Helvetica',
      fontSize: size,
      height: 1.15,
      color: fg,
      fontWeight: w.props['font_bold'] == true
          ? FontWeight.bold
          : FontWeight.normal,
      fontStyle: w.props['font_italic'] == true
          ? FontStyle.italic
          : FontStyle.normal,
      decoration: TextDecoration.none,
    );
    final dark = TextStyle(
      fontFamily: style.fontFamily,
      fontSize: size,
      height: 1.15,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      color: w.props['fg'] == null ? Colors.black : fg,
      decoration: TextDecoration.none,
    );
    final text = w.text('text');
    Widget label(String s, TextStyle st, {TextAlign? align, int? lines = 1}) =>
        Text(
          s,
          style: st,
          maxLines: lines,
          softWrap: lines != 1,
          overflow: TextOverflow.clip,
          textAlign: align,
        );
    final items = [
      for (final l in w.text('items').split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    const pad = EdgeInsets.symmetric(horizontal: 4);
    switch (w.kind) {
      case 'Label':
        final anchor = switch (w.text('anchor')) {
          'w' => Alignment.centerLeft,
          'e' => Alignment.centerRight,
          'n' => Alignment.topCenter,
          's' => Alignment.bottomCenter,
          _ => Alignment.center,
        };
        return Container(
          alignment: anchor,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(color: bg),
          foregroundDecoration: w.text('relief').isEmpty
              ? null
              : BoxDecoration(border: Border.all(color: _edge)),
          child: label(
            text,
            style,
            lines: w.props['wraplength'] == null ? 1 : 8,
            align: switch (w.text('justify')) {
              'left' => TextAlign.left,
              'right' => TextAlign.right,
              _ => TextAlign.center,
            },
          ),
        );
      case 'Button':
        return _face(
          color: ownBg ?? _panel,
          sunken: false,
          align: Alignment.center,
          child: label(
            text,
            w.props['state'] == 'disabled'
                ? dark.copyWith(color: const Color(0xFF9096A0))
                : dark,
          ),
        );
      case 'Entry':
        final shown = w.text('show').isEmpty
            ? text
            : w.text('show').substring(0, 1) * text.length;
        return _face(
          color: ownBg ?? Colors.white,
          child: Padding(
            padding: pad,
            child: SizedBox(
              width: double.infinity,
              child: label(
                shown,
                dark,
                align: switch (w.text('justify')) {
                  'center' => TextAlign.center,
                  'right' => TextAlign.right,
                  _ => TextAlign.left,
                },
              ),
            ),
          ),
        );
      case 'Text':
        return _face(
          color: ownBg ?? Colors.white,
          align: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: label(text, dark, lines: 200),
          ),
        );
      case 'Checkbutton' || 'Radiobutton':
        final radio = w.kind == 'Radiobutton';
        final on = w.props['checked'] == true;
        return ColoredBox(
          color: bg,
          child: Row(
            children: [
              const SizedBox(width: 2),
              Icon(
                radio
                    ? (on ? LucideIcons.circleDot : LucideIcons.circle)
                    : (on ? LucideIcons.squareCheck : LucideIcons.square),
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 4),
              Expanded(child: label(text, style)),
            ],
          ),
        );
      case 'Listbox':
        return _face(
          color: ownBg ?? Colors.white,
          align: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (final i in items.take(40)) label(i, dark)],
            ),
          ),
        );
      case 'Combobox':
        return _face(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Padding(padding: pad, child: label(text, dark)),
              ),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 2),
            ],
          ),
        );
      case 'Scale':
        final from = (w.props['from'] as num?)?.toDouble() ?? 0;
        final to = (w.props['to'] as num?)?.toDouble() ?? 100;
        final v = (w.props['value'] as num?)?.toDouble() ?? 0;
        final at = to == from
            ? 0.0
            : ((v - from) / (to - from)).clamp(0.0, 1.0);
        final vertical = w.text('orient') == 'vertical';
        return ColoredBox(
          color: bg,
          child: CustomPaint(
            painter: _ScalePainter(at, vertical, fg),
            child: Align(
              alignment: Alignment.topLeft,
              child: label(w.text('label'), style.copyWith(fontSize: 11)),
            ),
          ),
        );
      case 'Frame':
        return Container(
          decoration: BoxDecoration(
            color: bg,
            border: w.text('relief').isEmpty
                ? Border.all(color: _edge.withValues(alpha: .35))
                : Border.all(color: _edge),
          ),
        );
      case 'Treeview':
        final cols = TkCodegen.gridColumns(w);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _edge),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 22,
                color: _panel,
                child: Row(
                  children: [
                    if (cols.isEmpty) const Spacer(),
                    for (final (_, title, width) in cols)
                      SizedBox(
                        width: (width ?? 100).toDouble(),
                        child: Padding(padding: pad, child: label(title, dark)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'Connection':
        return Tooltip(
          message: w.name,
          child: Container(
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _edge),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.database,
              size: 16,
              color: Color(0xFF2B5797),
            ),
          ),
        );
      case 'Canvas':
        return Container(
          decoration: BoxDecoration(
            color: ownBg ?? Colors.white,
            border: Border.all(color: _edge.withValues(alpha: .5)),
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.brush,
            size: 18,
            color: _edge.withValues(alpha: .5),
          ),
        );
    }
    return const SizedBox.shrink();
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter(this.at, this.vertical, this.color);
  final double at;
  final bool vertical;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = const Color(0xFFB8BCC4);
    final thumb = Paint()..color = const Color(0xFF6E7480);
    if (vertical) {
      final x = size.width / 2;
      canvas.drawRect(Rect.fromLTWH(x - 3, 4, 6, size.height - 8), track);
      final y = 4 + (size.height - 22) * at;
      canvas.drawRect(Rect.fromLTWH(x - 9, y, 18, 14), thumb);
    } else {
      final y = size.height - 12;
      canvas.drawRect(Rect.fromLTWH(4, y - 3, size.width - 8, 6), track);
      final x = 4 + (size.width - 22) * at;
      canvas.drawRect(Rect.fromLTWH(x, y - 8, 14, 16), thumb);
    }
  }

  @override
  bool shouldRepaint(_ScalePainter o) =>
      o.at != at || o.vertical != vertical || o.color != color;
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = ink
      ..strokeWidth = 1;
    final dots = <Offset>[
      for (var y = 0.0; y < size.height; y += tkGrid)
        for (var x = 0.0; x < size.width; x += tkGrid) Offset(x + .5, y + .5),
    ];
    canvas.drawPoints(PointMode.points, dots, p);
  }

  @override
  bool shouldRepaint(_DotsPainter o) => o.ink != ink;
}

/// Vista de una ventana sin nada que tocar (galería y miniaturas).
class TkFormThumbnail extends StatelessWidget {
  const TkFormThumbnail(this.design, {super.key});
  final TkDesign design;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: Container(
      width: design.width.toDouble(),
      height: design.height.toDouble(),
      color: tkColor('${design.prop(tkFormBg)}', TkPreview._panel),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final w in design.widgets)
            Builder(
              builder: (_) {
                final (x, y) = design.absolute(w);
                return Positioned(
                  left: x.toDouble(),
                  top: y.toDouble(),
                  width: w.width.toDouble(),
                  height: w.height.toDouble(),
                  child: TkPreview(design, w),
                );
              },
            ),
        ],
      ),
    ),
  );
}

enum _Drag { none, move, resize, band, form }

/// Superficie de diseño: se seleccionan, mueven y redimensionan los
/// componentes con el ratón y se sueltan los de la paleta.
class TkFormCanvas extends StatefulWidget {
  const TkFormCanvas({
    super.key,
    required this.design,
    required this.selection,
    required this.snap,
    required this.onSelect,
    required this.onBegin,
    required this.onChanged,
    required this.onDrop,
    required this.onOpen,
    required this.onMenu,
    required this.onKey,
  });

  final TkDesign design;

  /// Nombres de los componentes seleccionados (vacío = la ventana).
  final Set<String> selection;
  final bool snap;
  final ValueChanged<Set<String>> onSelect;

  /// Justo antes de cambiar el diseño (para deshacer).
  final VoidCallback onBegin;

  /// El diseño cambió: [done] al soltar.
  final void Function({required bool done}) onChanged;

  /// Se soltó un componente de la paleta en esa posición de la ventana.
  final void Function(String kind, int x, int y) onDrop;

  /// Doble clic: abrir el evento principal ([w] null = la ventana).
  final ValueChanged<TkWidget?> onOpen;

  /// Menú contextual en esa posición de la pantalla.
  final ValueChanged<Offset> onMenu;

  /// Tecla con la superficie enfocada.
  final KeyEventResult Function(KeyEvent) onKey;

  @override
  State<TkFormCanvas> createState() => _TkFormCanvasState();
}

class _TkFormCanvasState extends State<TkFormCanvas> {
  /// Margen alrededor de la ventana y altura de su barra de título.
  static const _pad = 16.0, _titleBar = 26.0;
  static const _handle = 7.0;
  static const _doubleClick = Duration(milliseconds: 350);

  final _focus = FocusNode(debugLabel: 'tk-canvas');

  var _drag = _Drag.none;
  var _begun = false;
  Offset _start = Offset.zero;
  int _handleIndex = 0;
  Map<String, (int, int, int, int)> _origin = {};
  (int, int) _formOrigin = (0, 0);
  Rect? _band;
  Set<String> _bandBase = {};

  String? _lastTarget;
  DateTime _lastDown = DateTime(0);

  TkDesign get d => widget.design;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Offset _toForm(Offset local) => local - const Offset(_pad, _pad + _titleBar);

  Rect _rectOf(TkWidget w) {
    final (x, y) = d.absolute(w);
    return Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      w.width.toDouble(),
      w.height.toDouble(),
    );
  }

  /// Centros de los ocho tiradores: en el sentido de las agujas del reloj
  /// desde la esquina superior izquierda.
  List<Offset> _handles(Rect r) => [
    r.topLeft,
    r.topCenter,
    r.topRight,
    r.centerRight,
    r.bottomRight,
    r.bottomCenter,
    r.bottomLeft,
    r.centerLeft,
  ];

  TkWidget? get _single =>
      widget.selection.length == 1 ? d.byName(widget.selection.first) : null;

  int? _handleAt(Offset p) {
    final w = _single;
    if (w == null) return null;
    for (final (i, c) in _handles(_rectOf(w)).indexed) {
      if ((p - c).distance <= _handle) return i;
    }
    return null;
  }

  TkWidget? _widgetAt(Offset p) {
    for (final w in d.widgets.reversed) {
      if (_rectOf(w).contains(p)) return w;
    }
    return null;
  }

  bool get _shift =>
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  void _down(PointerDownEvent e) {
    _focus.requestFocus();
    final p = _toForm(e.localPosition);
    _start = p;
    _begun = false;
    if (e.buttons == kSecondaryButton) {
      final w = _widgetAt(p);
      if (w != null && !widget.selection.contains(w.name)) {
        widget.onSelect({w.name});
      }
      widget.onMenu(e.position);
      return;
    }
    final h = _handleAt(p);
    if (h != null) {
      final w = _single!;
      _handleIndex = h;
      _origin = {w.name: (w.x, w.y, w.width, w.height)};
      _drag = _Drag.resize;
      return;
    }
    final w = _widgetAt(p);
    final corner = Offset(d.width.toDouble(), d.height.toDouble());
    final onFormEdge =
        w == null &&
        (p.dx >= d.width || p.dy >= d.height) &&
        (p - corner).distance <= 14;
    final target = w?.name ?? (onFormEdge ? null : '');
    final now = DateTime.now();
    final twice =
        target == _lastTarget && now.difference(_lastDown) < _doubleClick;
    _lastTarget = target;
    _lastDown = now;
    if (twice && target != null) {
      _lastTarget = null;
      _drag = _Drag.none;
      widget.onOpen(w);
      return;
    }
    if (onFormEdge) {
      _formOrigin = (d.width, d.height);
      _drag = _Drag.form;
      return;
    }
    if (w == null) {
      _bandBase = _shift ? {...widget.selection} : {};
      if (!_shift) widget.onSelect({});
      _band = Rect.fromPoints(p, p);
      _drag = _Drag.band;
      setState(() {});
      return;
    }
    var selection = widget.selection;
    if (_shift) {
      selection = {...selection};
      if (!selection.remove(w.name)) selection.add(w.name);
      widget.onSelect(selection);
      if (!selection.contains(w.name)) {
        _drag = _Drag.none;
        return;
      }
    } else if (!selection.contains(w.name)) {
      selection = {w.name};
      widget.onSelect(selection);
    }
    // Lo que está dentro de un marco seleccionado se mueve con él.
    _origin = {
      for (final n in selection)
        if (d.byName(n) case final o?)
          if (!selection.any((s) => s != n && d.isInside(o, s)))
            n: (o.x, o.y, o.width, o.height),
    };
    _drag = _Drag.move;
  }

  int _snapped(num v) =>
      widget.snap ? (v / tkGrid).round() * tkGrid : v.round();

  void _begin() {
    if (_begun) return;
    _begun = true;
    widget.onBegin();
  }

  void _move(PointerMoveEvent e) {
    if (_drag == _Drag.none) return;
    final p = _toForm(e.localPosition);
    final delta = p - _start;
    if (!_begun && delta.distance < 3) return;
    switch (_drag) {
      case _Drag.move:
        _begin();
        // Con varios, se ajusta el primero y los demás lo siguen.
        final (fx, fy, _, _) = _origin.values.first;
        final dx = _snapped(fx + delta.dx) - fx;
        final dy = _snapped(fy + delta.dy) - fy;
        for (final MapEntry(key: n, value: o) in _origin.entries) {
          final w = d.byName(n);
          if (w == null) continue;
          w
            ..x = o.$1 + dx
            ..y = o.$2 + dy;
        }
        widget.onChanged(done: false);
      case _Drag.resize:
        _begin();
        _resize(delta);
        widget.onChanged(done: false);
      case _Drag.form:
        _begin();
        d
          ..width = math.max(80, _snapped(_formOrigin.$1 + delta.dx))
          ..height = math.max(60, _snapped(_formOrigin.$2 + delta.dy));
        widget.onChanged(done: false);
      case _Drag.band:
        final band = Rect.fromPoints(_start, p);
        final inside = {
          for (final w in d.widgets)
            if (_rectOf(w).overlaps(band)) w.name,
        };
        setState(() => _band = band);
        widget.onSelect({..._bandBase, ...inside});
      case _Drag.none:
        break;
    }
  }

  void _resize(Offset delta) {
    final w = _single;
    if (w == null) return;
    final (x0, y0, w0, h0) = _origin[w.name]!;
    var left = x0, top = y0, right = x0 + w0, bottom = y0 + h0;
    final i = _handleIndex;
    if (i == 0 || i == 6 || i == 7) left = _snapped(x0 + delta.dx);
    if (i == 2 || i == 3 || i == 4) right = _snapped(x0 + w0 + delta.dx);
    if (i == 0 || i == 1 || i == 2) top = _snapped(y0 + delta.dy);
    if (i == 4 || i == 5 || i == 6) bottom = _snapped(y0 + h0 + delta.dy);
    const min = tkGrid;
    if (right - left < min) {
      i == 0 || i == 6 || i == 7 ? left = right - min : right = left + min;
    }
    if (bottom - top < min) {
      i == 0 || i == 1 || i == 2 ? top = bottom - min : bottom = top + min;
    }
    w
      ..x = left
      ..y = top
      ..width = right - left
      ..height = bottom - top;
  }

  /// Al soltar, lo movido queda dentro del marco que tenga debajo.
  void _settleParents() {
    for (final n in _origin.keys) {
      final w = d.byName(n);
      if (w == null) continue;
      final c = _rectOf(w).center;
      TkWidget? frame;
      for (final o in d.widgets.reversed) {
        if (o.component.container &&
            o != w &&
            !d.isInside(o, w.name) &&
            !_origin.containsKey(o.name) &&
            _rectOf(o).contains(c)) {
          frame = o;
          break;
        }
      }
      d.reparent(w, frame?.name);
    }
  }

  void _up([PointerEvent? _]) {
    final drag = _drag;
    _drag = _Drag.none;
    if (drag == _Drag.band) setState(() => _band = null);
    if (_begun) {
      if (drag == _Drag.move) _settleParents();
      widget.onChanged(done: true);
    }
    _begun = false;
  }

  Offset get _origin0 => const Offset(_pad, _pad + _titleBar);

  Widget _positioned(Rect r, {required Widget child, Key? key}) {
    final at = r.shift(_origin0);
    return Positioned(
      key: key,
      left: at.left,
      top: at.top,
      width: at.width,
      height: at.height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bg = tkColor('${d.prop(tkFormBg)}', TkPreview._panel);
    final fw = d.width.toDouble(), fh = d.height.toDouble();
    final selected = [for (final n in widget.selection) ?d.byName(n)];
    final accent = t.colorScheme.primary;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) => widget.onKey(e),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          final box = context.findRenderObject() as RenderBox;
          final p = _toForm(box.globalToLocal(details.offset));
          _focus.requestFocus();
          widget.onDrop(
            details.data,
            _snapped(p.dx.clamp(0, d.width - tkGrid)),
            _snapped(p.dy.clamp(0, d.height - tkGrid)),
          );
        },
        builder: (context, candidate, _) => Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: SizedBox(
            width: fw + _pad * 2 + 8,
            height: fh + _titleBar + _pad * 2 + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Barra de título, como la que tendrá la ventana.
                Positioned(
                  left: _pad,
                  top: _pad,
                  width: fw,
                  height: _titleBar,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2B5797),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      d.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                // La ventana, con la rejilla de puntos.
                Positioned(
                  key: const ValueKey('tk-form'),
                  left: _pad,
                  top: _pad + _titleBar,
                  width: fw,
                  height: fh,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: candidate.isNotEmpty
                          ? Border.all(color: accent, width: 2)
                          : null,
                    ),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _DotsPainter(
                          TkCodegen.contrast('${d.prop(tkFormBg)}') == '#ffffff'
                              ? const Color(0x55FFFFFF)
                              : const Color(0x55000000),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final w in d.widgets)
                  _positioned(
                    _rectOf(w),
                    key: ValueKey('tk-w-${w.name}'),
                    child: IgnorePointer(child: TkPreview(d, w)),
                  ),
                // Selección.
                for (final w in selected)
                  _positioned(
                    _rectOf(w).inflate(1),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accent.withValues(alpha: .7),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_single != null)
                  for (final (i, c) in _handles(_rectOf(_single!)).indexed)
                    _positioned(
                      Rect.fromCenter(center: c, width: 7, height: 7),
                      key: ValueKey('tk-handle-$i'),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            border: Border.all(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                // Esquina para cambiar el tamaño de la ventana.
                _positioned(
                  Rect.fromCenter(
                    center: Offset(fw + 5, fh + 5),
                    width: 10,
                    height: 10,
                  ),
                  key: const ValueKey('tk-form-corner'),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.colorScheme.surface,
                        border: Border.all(color: accent),
                      ),
                    ),
                  ),
                ),
                if (_band != null)
                  _positioned(
                    _band!,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .1),
                          border: Border.all(color: accent),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
