import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/tr.dart';

/// Panel inferior (consola, terminal) que se redimensiona arrastrando su
/// borde superior y se minimiza a su barra de título. El alto y el estado
/// se recuerdan por [id] mientras la app está abierta.
class BottomPanel extends StatefulWidget {
  const BottomPanel({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.actions = const [],
    this.background,
    this.iconColor,
    this.initialHeight = 180,
  });

  final String id;
  final Widget title;
  final List<Widget> actions;
  final Widget child;
  final Color? background;
  final Color? iconColor;
  final double initialHeight;

  static final _heights = <String, double>{};
  static final _minimized = <String, bool>{};

  @override
  State<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel> {
  static const _min = 70.0, _bar = 30.0;

  double get _height => BottomPanel._heights[widget.id] ?? widget.initialHeight;
  bool get _minimized => BottomPanel._minimized[widget.id] ?? false;

  void _toggle() =>
      setState(() => BottomPanel._minimized[widget.id] = !_minimized);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        // Nunca más de dos tercios de lo que hay encima.
        final max = (MediaQuery.sizeOf(context).height * .66).clamp(
          _min + 1,
          2000.0,
        );
        final h = _minimized ? _bar : _height.clamp(_min, max).toDouble();
        return Container(
          height: h,
          decoration: BoxDecoration(
            color: widget.background ?? t.colorScheme.surface,
            border: Border(top: BorderSide(color: t.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tirador: arrastrar el borde cambia el alto.
              MouseRegion(
                cursor: _minimized
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _minimized
                      ? null
                      : (d) => setState(
                          () => BottomPanel._heights[widget.id] =
                              (h - d.delta.dy).clamp(_min, max).toDouble(),
                        ),
                  child: SizedBox(
                    height: 26,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 2),
                      child: Row(
                        children: [
                          Expanded(child: widget.title),
                          ...widget.actions,
                          IconButton(
                            tooltip: _minimized
                                ? tr('Restaurar')
                                : tr('Minimizar'),
                            iconSize: 15,
                            visualDensity: VisualDensity.compact,
                            color: widget.iconColor,
                            icon: Icon(
                              _minimized
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                            ),
                            onPressed: _toggle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!_minimized) Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}
