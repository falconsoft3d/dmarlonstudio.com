import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../code/tk_codegen.dart';
import '../../code/tk_model.dart';
import '../tk_project.dart';

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
  'Progressbar' => LucideIcons.chartNoAxesColumnIncreasing,
  'PageControl' => LucideIcons.panelsTopLeft,
  'StatusBar' => LucideIcons.panelBottom,
  'Menu' => LucideIcons.menu,
  'Ribbon' => LucideIcons.panelTop,
  'Timer' => LucideIcons.timer,
  'RestClient' => LucideIcons.plugZap,
  'TrayIcon' => LucideIcons.bellRing,
  'Password' => LucideIcons.keyRound,
  'Image' => LucideIcons.image,
  'OpenDialog' => LucideIcons.folderOpen,
  'SaveDialog' => LucideIcons.save,
  'Chart' => LucideIcons.chartLine,
  _ => LucideIcons.box,
};

/// Pestañas de un control de páginas, relativas a su esquina: las mismas
/// para dibujarlas y para saber cuál se pulsa.
List<Rect> tkTabRects(TkWidget w) {
  final out = <Rect>[];
  var x = 2.0;
  for (final title in tkPages(w)) {
    final tp = TextPainter(
      text: TextSpan(text: title, style: const TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = tp.width + 20;
    out.add(Rect.fromLTWH(x, 2, width, tkTabHeight - 2.0));
    x += width + 2;
  }
  return out;
}

/// Alto de la fila de pestañas de la cinta de opciones.
const tkRibbonTabsHeight = 24.0;

/// Pestañas de una cinta de opciones, relativas a su esquina: las mismas
/// para dibujarlas y para saber cuál se pulsa.
List<Rect> tkRibbonTabRects(TkWidget w) {
  final out = <Rect>[];
  var x = 4.0;
  for (final tab in tkRibbonTabs(w.text('items'))) {
    final tp = TextPainter(
      text: TextSpan(text: tab.label, style: const TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = tp.width + 24;
    out.add(Rect.fromLTWH(x, 1, width, tkRibbonTabsHeight - 1));
    x += width;
  }
  return out;
}

/// Dónde se dibuja [w] en la ventana: la barra de estado va siempre abajo
/// y de lado a lado, y la cinta de opciones arriba (bajo el menú, si hay).
Rect tkRectOf(TkDesign d, TkWidget w) {
  if (w.kind == 'Ribbon') {
    return Rect.fromLTWH(
      0,
      d.menu == null ? 0 : tkMenuBarHeight,
      d.width.toDouble(),
      w.height.toDouble(),
    );
  }
  if (w.kind == 'StatusBar') {
    return Rect.fromLTWH(
      0,
      (d.height - w.height).toDouble(),
      d.width.toDouble(),
      w.height.toDouble(),
    );
  }
  final (x, y) = d.absolute(w);
  return Rect.fromLTWH(
    x.toDouble(),
    y.toDouble(),
    w.width.toDouble(),
    w.height.toDouble(),
  );
}

/// Alto de la barra del menú en el diseño.
const tkMenuBarHeight = 20.0;

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
      case 'Ribbon':
        const line = Color(0xFFD6D6D6), accent = Color(0xFF2B579A);
        final tabs = tkRibbonTabs(w.text('items'));
        final active = design.ribbonTab(w);
        final rects = tkRibbonTabRects(w);
        const plain = TextStyle(
          fontSize: 12,
          color: Color(0xFF262626),
          decoration: TextDecoration.none,
        );
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: const Color(0xFFF3F3F3))),
              Positioned.fill(
                top: tkRibbonTabsHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: line),
                      bottom: BorderSide(color: line),
                    ),
                  ),
                  child: tabs.isEmpty
                      ? null
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final g in tabs[active].groups)
                              Container(
                                padding: const EdgeInsets.fromLTRB(4, 2, 4, 1),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: line),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (final b in g.buttons)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (b.glyph.isNotEmpty)
                                                    Text(
                                                      b.glyph,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        height: 1.1,
                                                        color: accent,
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                    ),
                                                  Text(
                                                    b.label,
                                                    maxLines: 1,
                                                    style: plain.copyWith(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      g.label,
                                      maxLines: 1,
                                      style: plain.copyWith(
                                        fontSize: 10,
                                        color: const Color(0xFF6E6E6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              for (final (i, r) in rects.indexed)
                Positioned.fromRect(
                  rect: r,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: i == active
                        ? const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: line),
                              left: BorderSide(color: line),
                              right: BorderSide(color: line),
                            ),
                          )
                        : null,
                    child: Text(
                      tabs[i].label,
                      maxLines: 1,
                      style: plain.copyWith(color: i == active ? accent : null),
                    ),
                  ),
                ),
            ],
          ),
        );
      case 'Password':
        final hint = w.text('hint');
        return _face(
          color: ownBg ?? Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: pad,
                  child: label(
                    hint.isNotEmpty ? hint : '••••••',
                    hint.isNotEmpty
                        ? dark.copyWith(color: const Color(0xFF9096A0))
                        : dark,
                  ),
                ),
              ),
              if (w.props['reveal'] != false)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    LucideIcons.eye,
                    size: 13,
                    color: Color(0xFF6E7480),
                  ),
                ),
            ],
          ),
        );
      case 'Image':
        final file = w.text('file');
        final dir = TkProject.current?.id;
        final path = file.isEmpty || dir == null
            ? null
            : p.isAbsolute(file)
            ? file
            : p.join(dir, file);
        final fit = switch (w.text('fit')) {
          'none' => BoxFit.none,
          'cover' => BoxFit.cover,
          'stretch' => BoxFit.fill,
          _ => BoxFit.contain,
        };
        Widget empty() => Center(
          child: Icon(
            LucideIcons.image,
            size: 22,
            color: _edge.withValues(alpha: .6),
          ),
        );
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: ownBg ?? bg,
            border: w.props['border'] == true
                ? Border.all(color: Colors.black)
                : Border.all(color: _edge.withValues(alpha: .35)),
          ),
          child: path != null && File(path).existsSync()
              ? Image.file(
                  File(path),
                  fit: fit,
                  errorBuilder: (_, _, _) => empty(),
                )
              : empty(),
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
      case 'Progressbar':
        final top = (w.props['maximum'] as num?)?.toDouble() ?? 100;
        final v = (w.props['value'] as num?)?.toDouble() ?? 0;
        final at = top <= 0 ? 0.0 : (v / top).clamp(0.0, 1.0);
        final vertical = w.text('orient') == 'vertical';
        final indeterminate = w.text('mode') == 'indeterminate';
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE6E7EA),
            border: Border.all(color: _edge),
          ),
          padding: const EdgeInsets.all(1),
          alignment: vertical ? Alignment.bottomCenter : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: vertical ? 1 : (indeterminate ? .3 : at),
            heightFactor: vertical ? (indeterminate ? .3 : at) : 1,
            child: const ColoredBox(color: Color(0xFF2B7BE4)),
          ),
        );
      case 'PageControl':
        final pages = tkPages(w);
        final active = design.activePage(w);
        final tabs = tkTabRects(w);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              top: tkTabHeight.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: _edge),
                ),
              ),
            ),
            for (final (i, r) in tabs.indexed)
              Positioned.fromRect(
                rect: i == active ? r.inflate(1) : r,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == active ? bg : _panel,
                    border: Border(
                      top: const BorderSide(color: _edge),
                      left: const BorderSide(color: _edge),
                      right: const BorderSide(color: _edge),
                      bottom: BorderSide(color: i == active ? bg : _edge),
                    ),
                  ),
                  child: label(
                    pages[i],
                    dark.copyWith(
                      fontSize: 12,
                      fontWeight: i == active
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
          ],
        );
      case 'StatusBar':
        final own = ownBg ?? const Color(0xFFE4E5E7);
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: own,
            border: const Border(top: BorderSide(color: _edge)),
          ),
          child: label(
            text,
            style.copyWith(
              color: w.props['fg'] == null
                  ? tkColor(
                      TkCodegen.contrast(
                        TkCodegen.color(w.props['bg']) ?? '#e4e5e7',
                      ),
                      Colors.black,
                    )
                  : fg,
            ),
          ),
        );
      case 'Menu' ||
          'Timer' ||
          'RestClient' ||
          'TrayIcon' ||
          'OpenDialog' ||
          'SaveDialog':
        return Tooltip(
          message: w.name,
          child: Container(
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _edge),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Icon(
              tkIcon(w.kind),
              size: 16,
              color: const Color(0xFF2B5797),
            ),
          ),
        );
      case 'Chart':
        return CustomPaint(
          painter: _ChartPreview(
            kind: w.text('kind'),
            title: w.text('title'),
            legend: w.props['legend'] != false,
            grid: w.props['grid'] != false,
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

/// Vista previa de un gráfico con datos de muestra, con los mismos colores
/// que dibujará la aplicación.
class _ChartPreview extends CustomPainter {
  _ChartPreview({
    required this.kind,
    required this.title,
    required this.legend,
    required this.grid,
  });
  final String kind, title;
  final bool legend, grid;

  static const _colors = [Color(0xFF2A78D6), Color(0xFFEB6834)];
  static const _up = Color(0xFF0CA30C), _down = Color(0xFFD03B3B);
  static const _surface = Color(0xFFFCFCFB), _gridColor = Color(0xFFE1E0D9);
  static const _axis = Color(0xFFC3C2B7), _ink2 = Color(0xFF52514E);

  static const _a = [12.0, 15, 14, 18, 21, 19, 24, 27, 25, 30, 33, 36];
  static const _b = [8.0, 9, 12, 11, 13, 16, 15, 17, 20, 19, 22, 24];

  void _text(
    Canvas c,
    String s,
    Offset at, {
    double size = 10,
    Color? color,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color ?? _ink2,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(c, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = _surface);
    canvas.drawRect(
      r.deflate(.5),
      Paint()
        ..color = _gridColor
        ..style = PaintingStyle.stroke,
    );
    var top = 8.0;
    if (title.isNotEmpty) {
      _text(
        canvas,
        title,
        Offset(10, top),
        size: 11,
        color: Colors.black,
        bold: true,
      );
      top += 18;
    }
    final candles = kind == 'candles';
    if (legend && !candles) {
      for (final (i, name) in ['A', 'B'].indexed) {
        final x = 10.0 + i * 40;
        canvas.drawLine(
          Offset(x, top + 6),
          Offset(x + 12, top + 6),
          Paint()
            ..color = _colors[i]
            ..strokeWidth = 2,
        );
        _text(canvas, name, Offset(x + 16, top));
      }
      top += 16;
    }
    final plot = Rect.fromLTRB(36, top + 4, size.width - 12, size.height - 20);
    if (plot.width < 20 || plot.height < 20) return;
    const lo = 0.0, hi = 40.0;
    double y(num v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;
    for (var t = 0; t <= 40; t += 10) {
      if (grid) {
        canvas.drawLine(
          Offset(plot.left, y(t)),
          Offset(plot.right, y(t)),
          Paint()..color = _gridColor,
        );
      }
      _text(canvas, '$t', Offset(plot.left - 22, y(t) - 7), size: 9);
    }
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, Paint()..color = _axis);
    final n = _a.length;
    final band = plot.width / n;
    double x(int i) => plot.left + (i + .5) * band;
    if (candles) {
      var price = 20.0;
      for (var i = 0; i < n; i++) {
        final open = price;
        price += [3.0, -2, 4, -3, 2, 5, -4, 3, -1, 4, -2, 3][i];
        final close = price;
        final up = close >= open;
        final color = up ? _up : _down;
        canvas.drawLine(
          Offset(x(i), y(([open, close].reduce((a, b) => a > b ? a : b)) + 2)),
          Offset(x(i), y(([open, close].reduce((a, b) => a < b ? a : b)) - 2)),
          Paint()..color = color,
        );
        final body = Rect.fromLTRB(
          x(i) - band * .3,
          y(up ? close : open),
          x(i) + band * .3,
          y(up ? open : close),
        );
        canvas.drawRect(body, Paint()..color = up ? _surface : color);
        canvas.drawRect(
          body,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke,
        );
      }
      return;
    }
    for (final (j, data) in [_a, _b].indexed) {
      final color = _colors[j];
      if (kind == 'bar') {
        final group = band * .8, bw = (group - 2) / 2;
        for (var i = 0; i < n; i++) {
          final x0 = x(i) - group / 2 + j * (bw + 2);
          canvas.drawRect(
            Rect.fromLTRB(x0, y(data[i]), x0 + bw, y(0)),
            Paint()..color = color,
          );
        }
        continue;
      }
      final path = Path()..moveTo(x(0), y(data[0]));
      for (var i = 1; i < n; i++) {
        path.lineTo(x(i), y(data[i]));
      }
      if (kind == 'area') {
        final fill = Path.from(path)
          ..lineTo(x(n - 1), y(0))
          ..lineTo(x(0), y(0))
          ..close();
        canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .18));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(x(n - 1), y(data.last)),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPreview o) =>
      o.kind != kind ||
      o.title != title ||
      o.legend != legend ||
      o.grid != grid;
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

/// Barra del menú de la ventana, como se verá: sus opciones de primer nivel.
class TkMenuBar extends StatelessWidget {
  const TkMenuBar(this.menu, {super.key});
  final TkWidget menu;

  @override
  Widget build(BuildContext context) => Container(
    height: tkMenuBarHeight,
    color: const Color(0xFFF3F3F3),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        for (final i in tkMenuItems(menu.text('items')))
          if (!i.separator)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                i.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
      ],
    ),
  );
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
          if (design.menu case final m?)
            Positioned(left: 0, top: 0, right: 0, child: TkMenuBar(m)),
          for (final w in design.widgets)
            if (w.component.visual && design.shown(w))
              Positioned.fromRect(
                rect: tkRectOf(design, w),
                child: TkPreview(design, w),
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

  Rect _rectOf(TkWidget w) => tkRectOf(d, w);

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
      if (d.shown(w) && _rectOf(w).contains(p)) return w;
    }
    // La barra del menú, si no hay nada encima.
    final menu = d.menu;
    if (menu != null &&
        p.dy >= 0 &&
        p.dy < tkMenuBarHeight &&
        p.dx >= 0 &&
        p.dx < d.width) {
      return menu;
    }
    return null;
  }

  /// Pestaña de un control de páginas o de una cinta de opciones bajo [p]:
  /// (componente, pestaña).
  (TkWidget, int)? _tabAt(TkWidget? w, Offset p) {
    if (w == null) return null;
    final rects = switch (w.kind) {
      'PageControl' => tkTabRects(w),
      'Ribbon' => tkRibbonTabRects(w),
      _ => const <Rect>[],
    };
    final local = p - _rectOf(w).topLeft;
    for (final (i, t) in rects.indexed) {
      if (t.contains(local)) return (w, i);
    }
    return null;
  }

  int _shownTab(TkWidget w) =>
      w.kind == 'Ribbon' ? d.ribbonTab(w) : d.activePage(w);

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
    // Pulsar una pestaña muestra esa página (y selecciona el control).
    final tab = _tabAt(w, p);
    if (tab != null && tab.$2 != _shownTab(tab.$1)) {
      final (pc, page) = tab;
      widget.onBegin();
      pc.setProp(pc.component.prop('active')!, page);
      widget.onSelect({pc.name});
      widget.onChanged(done: true);
      _drag = _Drag.none;
      return;
    }
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
            if (d.shown(w) && _rectOf(w).overlaps(band)) w.name,
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
      if (!w.component.nestable) {
        d.reparent(w, null);
        continue;
      }
      final c = _rectOf(w).center;
      TkWidget? frame;
      for (final o in d.widgets.reversed) {
        if (o.component.container &&
            d.shown(o) &&
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
                if (d.menu case final m?)
                  _positioned(
                    Rect.fromLTWH(0, 0, fw, tkMenuBarHeight),
                    key: const ValueKey('tk-menubar'),
                    child: IgnorePointer(child: TkMenuBar(m)),
                  ),
                for (final w in d.widgets)
                  if (d.shown(w))
                    _positioned(
                      _rectOf(w),
                      key: ValueKey('tk-w-${w.name}'),
                      child: IgnorePointer(child: TkPreview(d, w)),
                    ),
                // Selección.
                for (final w in selected)
                  if (d.shown(w))
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
