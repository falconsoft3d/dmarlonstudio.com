import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../code/tk_flutter.dart';
import '../../code/tk_web_next.dart';
import '../../code/tk_flutter_templates.dart';
import '../../code/tk_model.dart';
import '../../i18n/tr.dart';

/// El diseñador de apps de Flutter, al estilo de FlutterFlow: las pantallas
/// y el árbol de widgets a la izquierda, la paleta y el teléfono con la
/// vista previa en el centro, y las propiedades a la derecha.
class TkFlutterDesigner extends StatefulWidget {
  const TkFlutterDesigner({
    super.key,
    required this.design,
    required this.onBegin,
    required this.onChanged,
  });

  final TkDesign design;
  final void Function([String? key]) onBegin;
  final VoidCallback onChanged;

  @override
  State<TkFlutterDesigner> createState() => _TkFlutterDesignerState();
}

/// Iconos de Material por su nombre (la vista previa; el código generado
/// usa `Icons.nombre` y admite cualquiera).
const flIcons = <String, IconData>{
  'add': Icons.add,
  'all_inbox': Icons.all_inbox,
  'remove': Icons.remove,
  'person_add': Icons.person_add,
  'lock_reset': Icons.lock_reset,
  'waving_hand': Icons.waving_hand,
  'rocket_launch': Icons.rocket_launch,
  'dark_mode': Icons.dark_mode,
  'language': Icons.language,
  'done_all': Icons.done_all,
  'forum': Icons.forum,
  'sell': Icons.sell,
  'credit_card': Icons.credit_card,
  'location_city': Icons.location_city,
  'receipt_long': Icons.receipt_long,
  'insights': Icons.insights,
  'group': Icons.group,
  'mail': Icons.mail,
  'help': Icons.help,
  'crop_portrait': Icons.crop_portrait,
  'add_circle': Icons.add_circle,
  'add_circle_outline': Icons.add_circle_outline,
  'add_shopping_cart': Icons.add_shopping_cart,
  'remove_circle_outline': Icons.remove_circle_outline,
  'storefront': Icons.storefront,
  'payments': Icons.payments,
  'checkroom': Icons.checkroom,
  'cloud': Icons.cloud,
  'sticky_note_2': Icons.sticky_note_2,
  'chair': Icons.chair,
  'headphones': Icons.headphones,
  'watch': Icons.watch,
  'shopping_bag': Icons.shopping_bag,
  'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward,
  'calendar_today': Icons.calendar_today,
  'call': Icons.call,
  'camera_alt': Icons.camera_alt,
  'chat': Icons.chat,
  'check': Icons.check,
  'check_circle': Icons.check_circle,
  'chevron_right': Icons.chevron_right,
  'circle': Icons.circle,
  'cleaning_services': Icons.cleaning_services,
  'close': Icons.close,
  'delete': Icons.delete,
  'delete_outline': Icons.delete_outline,
  'edit': Icons.edit,
  'email': Icons.email,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'filter_list': Icons.filter_list,
  'history': Icons.history,
  'home': Icons.home,
  'image': Icons.image,
  'info': Icons.info,
  'inventory_2_outlined': Icons.inventory_2_outlined,
  'list': Icons.list,
  'local_shipping': Icons.local_shipping,
  'location_on': Icons.location_on,
  'lock': Icons.lock,
  'login': Icons.login,
  'logout': Icons.logout,
  'map': Icons.map,
  'menu': Icons.menu,
  'more_vert': Icons.more_vert,
  'notifications': Icons.notifications,
  'person': Icons.person,
  'phone': Icons.phone,
  'photo': Icons.photo,
  'place': Icons.place,
  'qr_code': Icons.qr_code,
  'refresh': Icons.refresh,
  'save': Icons.save,
  'search': Icons.search,
  'send': Icons.send,
  'settings': Icons.settings,
  'share': Icons.share,
  'shopping_cart': Icons.shopping_cart,
  'star': Icons.star,
  'star_border': Icons.star_border,
  'store': Icons.store,
  'task_alt': Icons.task_alt,
  'thumb_up': Icons.thumb_up,
  'timer': Icons.timer,
  'warning': Icons.warning,
};

IconData _iconOf(String name) => name.startsWith('=')
    ? Icons.data_object
    : flIcons[name] ?? Icons.help_outline;

/// Icono de la paleta y del árbol para un tipo de widget.
IconData flTypeIcon(String type) => switch (type) {
  'Column' => LucideIcons.rows3,
  'Row' => LucideIcons.columns3,
  'ListView' => LucideIcons.list,
  'Card' => LucideIcons.creditCard,
  'Container' => LucideIcons.square,
  'Padding' => LucideIcons.squareDashed,
  'Center' => LucideIcons.alignCenter,
  'Expanded' => LucideIcons.moveHorizontal,
  'Text' => LucideIcons.type,
  'Button' => LucideIcons.rectangleHorizontal,
  'IconButton' => LucideIcons.circlePlus,
  'TextField' => LucideIcons.textCursorInput,
  'ListTile' => LucideIcons.listCollapse,
  'Checkbox' => LucideIcons.squareCheck,
  'Switch' => LucideIcons.toggleRight,
  'Chip' => LucideIcons.tag,
  'Icon' => LucideIcons.star,
  'Image' => LucideIcons.image,
  'Progress' => LucideIcons.loader,
  'Divider' => LucideIcons.minus,
  'SizedBox' => LucideIcons.space,
  'Spacer' => LucideIcons.unfoldHorizontal,
  _ => LucideIcons.box,
};

/// Lo que trae un widget nuevo.
FlNode flNewNode(String type) => switch (type) {
  'Column' || 'Row' => FlNode(type, {'gap': 8}),
  'ListView' => FlNode('ListView', {'padding': 8}),
  'Card' => FlNode(
    'Card',
    {'padding': 12},
    [
      FlNode('Text', {'text': 'Tarjeta'}),
    ],
  ),
  'Container' => FlNode('Container', {
    'padding': 12,
    'radius': 12,
    'color': 'primaryContainer',
  }),
  'Padding' => FlNode('Padding', {'padding': 16}),
  'Text' => FlNode('Text', {'text': 'Texto'}),
  'Button' => FlNode('Button', {'text': 'Botón'}),
  'IconButton' => FlNode('IconButton', {'icon': 'favorite'}),
  'TextField' => FlNode('TextField', {'label': 'Campo'}),
  'ListTile' => FlNode('ListTile', {
    'title': 'Título',
    'subtitle': 'Subtítulo',
    'icon': 'person',
  }),
  'Chip' => FlNode('Chip', {'text': 'Etiqueta'}),
  'Icon' => FlNode('Icon', {'icon': 'star'}),
  'Image' => FlNode('Image', {'height': 160, 'radius': 12}),
  'SizedBox' => FlNode('SizedBox', {'height': 16}),
  _ => FlNode(type),
};

/// Cuántos hijos admite: 0, 1 o varios (2).
int flKids(String type) => flWidgets[type]?.$2 ?? 0;

class _TkFlutterDesignerState extends State<TkFlutterDesigner> {
  late FlApp _app = FlApp.of(widget.design);
  int _screen = 0;

  /// Web: la vista previa en un teléfono en lugar de la ventana.
  bool _mobile = false;

  /// El widget elegido: el camino de índices desde el cuerpo (vacío: el
  /// cuerpo; null: la pantalla).
  List<int>? _sel;

  @override
  void didUpdateWidget(TkFlutterDesigner old) {
    super.didUpdateWidget(old);
    // Deshacer cambia el diseño entero.
    if (!identical(old.design, widget.design) ||
        widget.design.props['flutter'] != null &&
            !identical(widget.design.props['flutter'], _saved)) {
      _app = FlApp.of(widget.design);
      if (_screen >= _app.screens.length) _screen = 0;
      if (_sel != null && _node(_sel!) == null) _sel = null;
    }
  }

  Object? _saved;

  FlScreen get _cur => _app.screens[_screen.clamp(0, _app.screens.length - 1)];

  FlNode? _node(List<int> path) {
    FlNode? n = _cur.body;
    for (final i in path) {
      if (n == null || i < 0 || i >= n.children.length) return null;
      n = n.children[i];
    }
    return n;
  }

  /// Un cambio: queda para deshacer y se guarda en el diseño.
  void _edit(void Function() f, [String? key]) {
    widget.onBegin(key);
    setState(f);
    _app.saveTo(widget.design);
    _saved = widget.design.props['flutter'];
    widget.onChanged();
  }

  // ------------------------------------------------------------- árbol
  void _add(String type) {
    final node = flNewNode(type);
    final sel = _sel ?? const <int>[];
    final target = _node(sel);
    _edit(() {
      if (target != null && flKids(target.type) == 2) {
        target.children.add(node);
        _sel = [...sel, target.children.length - 1];
      } else if (target != null &&
          flKids(target.type) == 1 &&
          target.children.isEmpty) {
        target.children.add(node);
        _sel = [...sel, 0];
      } else if (sel.isNotEmpty) {
        final parent = _node(sel.sublist(0, sel.length - 1))!;
        if (flKids(parent.type) == 2) {
          parent.children.insert(sel.last + 1, node);
          _sel = [...sel.sublist(0, sel.length - 1), sel.last + 1];
        } else {
          // El padre solo admite uno: se envuelve en una columna.
          final old = parent.children.first;
          parent.children[0] = FlNode('Column', {'gap': 8}, [old, node]);
          _sel = [...sel, 1];
        }
      } else {
        // El cuerpo no admite más: pasa a ser una columna.
        _cur.body = FlNode('Column', {'gap': 8}, [_cur.body, node]);
        _sel = [1];
      }
    });
  }

  void _delete() {
    final sel = _sel;
    if (sel == null || sel.isEmpty) return;
    _edit(() {
      _node(sel.sublist(0, sel.length - 1))!.children.removeAt(sel.last);
      _sel = sel.length == 1 ? <int>[] : sel.sublist(0, sel.length - 1);
    });
  }

  void _move(int delta) {
    final sel = _sel;
    if (sel == null || sel.isEmpty) return;
    final parent = _node(sel.sublist(0, sel.length - 1))!;
    final to = sel.last + delta;
    if (to < 0 || to >= parent.children.length) return;
    _edit(() {
      final n = parent.children.removeAt(sel.last);
      parent.children.insert(to, n);
      _sel = [...sel.sublist(0, sel.length - 1), to];
    });
  }

  void _duplicate() {
    final sel = _sel;
    if (sel == null || sel.isEmpty) return;
    final parent = _node(sel.sublist(0, sel.length - 1))!;
    if (flKids(parent.type) != 2) return;
    _edit(() {
      parent.children.insert(sel.last + 1, _node(sel)!.copy());
      _sel = [...sel.sublist(0, sel.length - 1), sel.last + 1];
    });
  }

  /// Nueva pantalla: en blanco o desde una de las plantillas.
  Future<void> _addScreen() async {
    final screen = await showDialog<FlScreen>(
      context: context,
      builder: (_) =>
          FlTemplateGallery(app: _app, desktop: widget.design.isFlutterDesktop),
    );
    if (screen == null || !mounted) return;
    _edit(() {
      _app.screens.add(screen);
      _screen = _app.screens.length - 1;
      _sel = null;
    });
  }

  void _deleteScreen() {
    if (_app.screens.length < 2) return;
    _edit(() {
      _app.screens.removeAt(_screen);
      _screen = 0;
      _sel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 250, child: _left(t)),
        VerticalDivider(width: 1, color: t.dividerColor),
        Expanded(child: _center(t)),
        VerticalDivider(width: 1, color: t.dividerColor),
        SizedBox(
          width: 300,
          child: TkFlutterProps(
            key: ValueKey('fl-props-$_screen-${_sel?.join('.')}'),
            app: _app,
            screen: _cur,
            node: _sel == null ? null : _node(_sel!),
            onEdit: _edit,
            web: widget.design.isWebNext || widget.design.isReactNative,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- izquierda
  Widget _left(ThemeData t) {
    Widget head(String text, [List<Widget> actions = const []]) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
                color: t.hintColor,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
    Widget act(IconData i, String tip, VoidCallback? f, {Key? key}) =>
        IconButton(
          key: key,
          tooltip: tip,
          iconSize: 15,
          visualDensity: VisualDensity.compact,
          onPressed: f,
          icon: Icon(i),
        );
    final rows = <Widget>[];
    void tree(FlNode n, List<int> path, int depth) {
      final sel = _sel != null && _sel!.join('.') == path.join('.');
      final label = switch (n.type) {
        'Text' => n.text('text'),
        'Button' || 'Chip' => n.text('text'),
        'ListTile' => n.text('title'),
        'TextField' => n.text('label', n.text('hint')),
        'ListView' => n.text('items'),
        _ => '',
      };
      rows.add(
        InkWell(
          key: ValueKey('fl-tree-${path.join('.')}'),
          onTap: () => setState(() => _sel = path),
          child: Container(
            color: sel ? t.colorScheme.primary.withValues(alpha: .14) : null,
            padding: EdgeInsets.only(
              left: 10.0 + depth * 14,
              top: 4,
              bottom: 4,
              right: 8,
            ),
            child: Row(
              children: [
                Icon(
                  flTypeIcon(n.type),
                  size: 14,
                  color: t.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr(flWidgets[n.type]?.$1 ?? n.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: t.hintColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      for (final (i, c) in n.children.indexed) {
        tree(c, [...path, i], depth + 1);
      }
    }

    tree(_cur.body, const [], 0);
    final hasSel = _sel != null && _sel!.isNotEmpty;
    return ColoredBox(
      color: t.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head(tr('PANTALLAS'), [
            act(
              LucideIcons.plus,
              tr('Nueva pantalla'),
              _addScreen,
              key: const ValueKey('fl-screen-add'),
            ),
          ]),
          for (final (i, s) in _app.screens.indexed)
            InkWell(
              key: ValueKey('fl-screen-${s.name}'),
              onTap: () => setState(() {
                _screen = i;
                _sel = null;
              }),
              child: Container(
                color: i == _screen
                    ? t.colorScheme.primary.withValues(alpha: .14)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      i == 0 ? LucideIcons.house : LucideIcons.smartphone,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.arg.isNotEmpty)
                      Text(
                        '(${s.arg})',
                        style: TextStyle(fontSize: 11, color: t.hintColor),
                      ),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
          head(tr('WIDGETS'), [
            act(
              LucideIcons.arrowUp,
              tr('Subir'),
              hasSel ? () => _move(-1) : null,
            ),
            act(
              LucideIcons.arrowDown,
              tr('Bajar'),
              hasSel ? () => _move(1) : null,
            ),
            act(LucideIcons.copy, tr('Duplicar'), hasSel ? _duplicate : null),
            act(
              LucideIcons.trash2,
              tr('Eliminar'),
              hasSel ? _delete : null,
              key: const ValueKey('fl-delete'),
            ),
          ]),
          InkWell(
            key: const ValueKey('fl-tree-screen'),
            onTap: () => setState(() => _sel = null),
            child: Container(
              color: _sel == null
                  ? t.colorScheme.primary.withValues(alpha: .14)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.smartphone, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr('Pantalla «{0}»', [_cur.name]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: ListView(children: rows)),
          if (_app.screens.length > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: _deleteScreen,
                icon: const Icon(LucideIcons.trash2, size: 14),
                label: Text(tr('Eliminar la pantalla')),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- centro
  Widget _center(ThemeData t) {
    return ColoredBox(
      color: t.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Paleta: se añade dentro del elegido (o detrás).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainerHigh,
              border: Border(bottom: BorderSide(color: t.dividerColor)),
            ),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.design.isWebNext)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SegmentedButton<bool>(
                      key: const ValueKey('fl-web-device'),
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        ButtonSegment(
                          value: false,
                          icon: const Icon(
                            Icons.desktop_windows_outlined,
                            size: 16,
                          ),
                          tooltip: tr('Escritorio'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: const Icon(Icons.smartphone, size: 16),
                          tooltip: tr('Móvil'),
                        ),
                      ],
                      selected: {_mobile},
                      onSelectionChanged: (v) =>
                          setState(() => _mobile = v.first),
                    ),
                  ),
                for (final MapEntry(key: type, value: (name, _))
                    in flWidgets.entries)
                  Tooltip(
                    message: tr(name),
                    child: InkWell(
                      key: ValueKey('fl-add-$type'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _add(type),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(flTypeIcon(type), size: 17),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final desktop =
                    widget.design.isFlutterDesktop ||
                    widget.design.isWebNext && !_mobile;
                final size = FlPhone.sizeOf(desktop: desktop);
                final scale = [
                  (box.maxHeight - 32) / size.height,
                  (box.maxWidth - 32) / size.width,
                ].reduce((a, b) => a < b ? a : b).clamp(.25, 1.0);
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: OverflowBox(
                      maxHeight: size.height,
                      maxWidth: size.width,
                      child: FlPhone(
                        app: _app,
                        screen: _cur,
                        desktop: desktop,
                        url: widget.design.isWebNext
                            ? 'localhost${TkWebNext.route(_app, _cur.name)}'
                            : null,
                        back: _screen > 0,
                        sel: _sel,
                        onPick: (p) => setState(() => _sel = p),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// El teléfono con la vista previa real de una pantalla: el editor (que
/// elige widgets al tocarlos) y la galería de plantillas.
class FlPhone extends StatefulWidget {
  const FlPhone({
    super.key,
    required this.app,
    required this.screen,
    this.back = false,
    this.sel,
    this.onPick,
    this.desktop = false,
    this.url,
  });

  final FlApp app;
  final FlScreen screen;

  /// Web: la dirección que se ve en la barra (en lugar del título).
  final String? url;

  /// Una ventana de escritorio en lugar de un teléfono.
  final bool desktop;

  /// Lo que ocupa (con su marco).
  static Size sizeOf({required bool desktop}) =>
      desktop ? const Size(1100, 700) : const Size(417, 876);

  /// Con la flecha de volver en la barra (no es la primera pantalla).
  final bool back;

  /// El widget elegido (se ve con un marco) y al tocar uno.
  final List<int>? sel;
  final void Function(List<int>? path)? onPick;

  @override
  State<FlPhone> createState() => _FlPhoneState();
}

class _FlPhoneState extends State<FlPhone> {
  /// El puntero que ya eligió un widget (el más profundo gana).
  int? _claimed;

  List<int>? get _sel => widget.sel;
  FlApp get _app => widget.app;

  @override
  Widget build(BuildContext context) => widget.desktop
      ? _window(Theme.of(context), 1100, 700)
      : _phone(Theme.of(context), 393, 852);

  Widget _phone(ThemeData t, double w, double h) {
    final seed = RegExp(r'#?([0-9a-fA-F]{6})').firstMatch(_app.primary)?[1];
    final theme = ThemeData(
      colorSchemeSeed: Color(int.parse('FF${seed ?? '2B5FD9'}', radix: 16)),
      brightness: _app.dark ? Brightness.dark : Brightness.light,
    );
    final s = widget.screen;
    return Container(
      key: const ValueKey('fl-phone'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C0F),
        borderRadius: BorderRadius.circular(64),
        boxShadow: const [BoxShadow(blurRadius: 30, color: Color(0x55000000))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(52),
        child: SizedBox(
          width: w,
          height: h,
          child: Theme(
            data: theme,
            child: Builder(
              builder: (context) => Material(
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Barra de estado con la isla.
                    SizedBox(
                      height: 50,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '9:41',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.signal_cellular_alt,
                                    size: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.battery_full,
                                    size: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, -.2),
                            child: Container(
                              width: 118,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ?_appBar(s),
                    Expanded(child: _body(s)),
                    if (_app.inNav(s.name)) _bottomNav(s),
                    Container(
                      height: 26,
                      alignment: Alignment.center,
                      child: Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData get _theme {
    final seed = RegExp(r'#?([0-9a-fA-F]{6})').firstMatch(_app.primary)?[1];
    return ThemeData(
      colorSchemeSeed: Color(int.parse('FF${seed ?? '2B5FD9'}', radix: 16)),
      brightness: _app.dark ? Brightness.dark : Brightness.light,
    );
  }

  /// La barra superior de la pantalla (null: no tiene).
  Widget? _appBar(FlScreen s) => !s.appBar
      ? null
      : Listener(
          onPointerDown: (e) => _pick(e.pointer, null),
          child: AppBar(
            actions: [
              for (final (icon, _, badge) in s.barButtons)
                IconButton(
                  onPressed: () {},
                  icon: Badge(
                    isLabelVisible: badge.isNotEmpty,
                    label: Text(_template(badge)),
                    child: Icon(_iconOf(icon)),
                  ),
                ),
            ],
            title: Text(_template(s.title.isEmpty ? s.name : s.title)),
            automaticallyImplyLeading: false,
            leading: widget.back && !_app.inNav(s.name)
                ? const Icon(Icons.arrow_back)
                : null,
          ),
        );

  /// El cuerpo, con el botón flotante.
  Widget _body(FlScreen s) => Stack(
    children: [
      Positioned.fill(child: _preview(s.body, const [], flex: false)),
      if (s.fabIcon.isNotEmpty)
        Positioned(
          right: 16,
          bottom: 16,
          child: Listener(
            onPointerDown: (e) => _pick(e.pointer, null),
            child: FloatingActionButton(
              onPressed: () {},
              child: Icon(_iconOf(s.fabIcon)),
            ),
          ),
        ),
    ],
  );

  int _navIndex(FlScreen s) => _app.navItems.indexWhere((n) => n.$1 == s.name);

  /// El menú abajo (teléfono).
  Widget _bottomNav(FlScreen s) => NavigationBar(
    selectedIndex: _navIndex(s),
    destinations: [
      for (final (_, icon, label) in _app.navItems)
        NavigationDestination(icon: Icon(_iconOf(icon)), label: label),
    ],
  );

  /// Escritorio: una ventana de macOS con su barra de título y, si la
  /// pantalla está en el menú, la barra lateral.
  Widget _window(ThemeData t, double w, double h) {
    final theme = _theme;
    final s = widget.screen;
    Widget dot(Color c) => Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Container(
      key: const ValueKey('fl-window'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33000000)),
        boxShadow: const [BoxShadow(blurRadius: 40, color: Color(0x44000000))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: w,
          height: h,
          child: Theme(
            data: theme,
            child: Builder(
              builder: (context) => Material(
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 32,
                      color: theme.colorScheme.surfaceContainerHigh,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          dot(const Color(0xFFFF5F57)),
                          dot(const Color(0xFFFEBC2E)),
                          dot(const Color(0xFF28C840)),
                          Expanded(
                            child: widget.url != null
                                ? Center(
                                    child: Container(
                                      width: 420,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text(
                                        widget.url!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _app.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ),
                    ?_appBar(s),
                    Expanded(
                      child: _app.inNav(s.name)
                          ? Row(
                              children: [
                                NavigationRail(
                                  selectedIndex: _navIndex(s),
                                  labelType: NavigationRailLabelType.all,
                                  destinations: [
                                    for (final (_, icon, label)
                                        in _app.navItems)
                                      NavigationRailDestination(
                                        icon: Icon(_iconOf(icon)),
                                        label: Text(label),
                                      ),
                                  ],
                                ),
                                const VerticalDivider(width: 1),
                                Expanded(child: _body(s)),
                              ],
                            )
                          : _body(s),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pick(int pointer, List<int>? path) {
    if (_claimed == pointer) return;
    _claimed = pointer;
    widget.onPick?.call(path);
  }

  /// Una plantilla en la vista previa: `${item.titulo}` se ve como
  /// «titulo».
  static String _template(String s) => s.replaceAllMapped(
    RegExp(r'\$\{([^}]*)\}'),
    (m) => '«${m[1]!.replaceAll(RegExp(r'\(.*'), '').split('.').last.trim()}»',
  );

  Color? _color(BuildContext context, Object? v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s.startsWith('=')) return null;
    final hex = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(s);
    if (hex != null) return Color(int.parse('FF${hex[1]}', radix: 16));
    final cs = Theme.of(context).colorScheme;
    return switch (s) {
      'primary' => cs.primary,
      'secondary' => cs.secondary,
      'tertiary' => cs.tertiary,
      'error' => cs.error,
      'surface' => cs.surface,
      'primaryContainer' => cs.primaryContainer,
      'secondaryContainer' => cs.secondaryContainer,
      'surfaceContainer' => cs.surfaceContainer,
      'onPrimary' => cs.onPrimary,
      _ => null,
    };
  }

  double? _num(Object? v) => v is num
      ? v.toDouble()
      : v is String && !v.startsWith('=')
      ? double.tryParse(v)
      : null;

  /// La vista previa de [n]: el widget de verdad, que se elige al tocarlo.
  Widget _preview(FlNode n, List<int> path, {required bool flex}) {
    final sel = _sel != null && _sel!.join('.') == path.join('.');
    final kids = flKids(n.type);
    Widget build(BuildContext context) {
      final p = n.props;
      Widget child(int i, {bool inFlex = false}) =>
          _preview(n.children[i], [...path, i], flex: inFlex);
      Widget one() => n.children.isEmpty
          ? Container(
              height: 40,
              alignment: Alignment.center,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .06),
              child: Text(tr('Vacío'), style: const TextStyle(fontSize: 11)),
            )
          : child(0);
      final tt = Theme.of(context).textTheme;
      Widget w = switch (n.type) {
        'Row' when p['wrap'] == true => Wrap(
          spacing: _num(p['gap']) ?? 8,
          runSpacing: _num(p['gap']) ?? 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [for (var i = 0; i < n.children.length; i++) child(i)],
        ),
        'Column' || 'Row' => Flex(
          direction: n.type == 'Column' ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.values.firstWhere(
            (e) => e.name == n.text('main', 'start'),
            orElse: () => MainAxisAlignment.start,
          ),
          crossAxisAlignment: CrossAxisAlignment.values.firstWhere(
            (e) =>
                e.name ==
                n.text('cross', n.type == 'Column' ? 'stretch' : 'center'),
            orElse: () => CrossAxisAlignment.center,
          ),
          spacing: _num(p['gap']) ?? 0,
          children: [
            for (var i = 0; i < n.children.length; i++) child(i, inFlex: true),
            if (n.children.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr('Añada widgets desde la paleta'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        'ListView' => _listPreview(n, path),
        'Card' => Card(
          color: _color(context, p['color']),
          child: Padding(
            padding: EdgeInsets.all(_num(p['padding']) ?? 12),
            child: one(),
          ),
        ),
        'Container' => Container(
          height: _num(p['height']),
          width: _num(p['width']),
          padding: EdgeInsets.all(_num(p['padding']) ?? 0),
          decoration: BoxDecoration(
            color: _color(context, p['color']),
            borderRadius: BorderRadius.circular(_num(p['radius']) ?? 0),
          ),
          child: n.children.isEmpty ? null : child(0),
        ),
        'Padding' => Padding(
          padding: EdgeInsets.all(_num(p['padding']) ?? 16),
          child: one(),
        ),
        'Center' => Center(child: one()),
        'Expanded' => one(),
        'Text' => Text(
          _template(n.text('text', 'Texto')),
          maxLines: _num(p['maxLines'])?.toInt(),
          textAlign: TextAlign.values
              .where((a) => a.name == p['align'])
              .firstOrNull,
          style: _textStyle(tt, n.text('style', 'bodyLarge'))?.copyWith(
            color: _color(context, p['color']),
            fontWeight: p['bold'] == true ? FontWeight.bold : null,
          ),
        ),
        'Button' => _buttonPreview(n),
        'IconButton' => IconButton(
          onPressed: () {},
          icon: Icon(_iconOf(n.text('icon', 'add'))),
        ),
        'TextField' => TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: n.text('label').isEmpty
                ? null
                : _template(n.text('label')),
            hintText: n.text('hint').isEmpty ? null : _template(n.text('hint')),
            prefixIcon: n.text('icon').isEmpty
                ? null
                : Icon(_iconOf(n.text('icon'))),
            border: const OutlineInputBorder(),
          ),
        ),
        'ListTile' => ListTile(
          leading: n.text('icon').isEmpty
              ? null
              : p['leadingColor'] == null
              ? Icon(_iconOf(n.text('icon')))
              : CircleAvatar(
                  backgroundColor:
                      _color(context, p['leadingColor']) ??
                      Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: Icon(_iconOf(n.text('icon'))),
                ),
          title: Text(_template(n.text('title', 'Título'))),
          subtitle: n.text('subtitle').isEmpty
              ? null
              : Text(_template(n.text('subtitle'))),
          trailing: n.text('trailing').isNotEmpty
              ? Text(_template(n.text('trailing')))
              : n.text('trailingIcon').isNotEmpty
              ? Icon(_iconOf(n.text('trailingIcon')))
              : null,
        ),
        'Checkbox' => Checkbox(value: p['value'] == true, onChanged: (_) {}),
        'Switch' => Switch(value: p['value'] == true, onChanged: (_) {}),
        'Chip' =>
          p['selected'] != null
              ? ChoiceChip(
                  label: Text(_template(n.text('text', 'Etiqueta'))),
                  selected: p['selected'] == true,
                  onSelected: (_) {},
                )
              : Chip(
                  label: Text(_template(n.text('text', 'Etiqueta'))),
                  avatar: n.text('icon').isEmpty
                      ? null
                      : Icon(_iconOf(n.text('icon')), size: 18),
                  backgroundColor: _color(context, p['color']),
                ),
        'Icon' => Icon(
          _iconOf(n.text('icon', 'star')),
          size: _num(p['size']) ?? 24,
          color: _color(context, p['color']),
        ),
        'Image' => ClipRRect(
          borderRadius: BorderRadius.circular(_num(p['radius']) ?? 0),
          child: Container(
            height: _num(p['height']) ?? 160,
            color: Theme.of(context).colorScheme.secondaryContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.image,
              size: 40,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        'Progress' => LinearProgressIndicator(value: _num(p['value']) ?? .4),
        'Divider' => const Divider(),
        'SizedBox' => SizedBox(
          height: _num(p['height']) ?? 16,
          width: _num(p['width']),
        ),
        'Spacer' => const SizedBox.shrink(),
        _ => Text(n.type),
      };
      // El margen de filas, columnas y listas.
      final pad = _num(p['padding']);
      if ((n.type == 'Column' || n.type == 'Row') && pad != null) {
        w = Padding(padding: EdgeInsets.all(pad), child: w);
      }
      return w;
    }

    Widget framed = Builder(
      builder: (context) {
        final inner = build(context);
        return Listener(
          onPointerDown: (e) => _pick(e.pointer, path),
          child: Container(
            foregroundDecoration: sel
                ? BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF2B5FD9),
                      width: 2,
                    ),
                  )
                : null,
            child: kids == 0 ? IgnorePointer(child: inner) : inner,
          ),
        );
      },
    );
    // Fuera de la vista previa, nada se mueve: los botones no hacen nada.
    final grow =
        n.type == 'Expanded' || n.type == 'Spacer' || n.type == 'ListView';
    if (flex && grow) {
      final f = _num(n.props['flex'])?.toInt() ?? 1;
      return Expanded(flex: f, child: framed);
    }
    return framed;
  }

  TextStyle? _textStyle(TextTheme tt, String name) => switch (name) {
    'displayMedium' => tt.displayMedium,
    'displaySmall' => tt.displaySmall,
    'headlineMedium' => tt.headlineMedium,
    'headlineSmall' => tt.headlineSmall,
    'titleLarge' => tt.titleLarge,
    'titleMedium' => tt.titleMedium,
    'titleSmall' => tt.titleSmall,
    'bodyMedium' => tt.bodyMedium,
    'bodySmall' => tt.bodySmall,
    'labelLarge' => tt.labelLarge,
    'labelSmall' => tt.labelSmall,
    _ => tt.bodyLarge,
  };

  Widget _buttonPreview(FlNode n) {
    final label = Text(_template(n.text('text', 'Botón')));
    final icon = n.text('icon');
    final i = icon.isEmpty ? null : Icon(_iconOf(icon));
    void f() {}
    return switch (n.text('variant', 'filled')) {
      'outlined' =>
        i == null
            ? OutlinedButton(onPressed: f, child: label)
            : OutlinedButton.icon(onPressed: f, icon: i, label: label),
      'text' =>
        i == null
            ? TextButton(onPressed: f, child: label)
            : TextButton.icon(onPressed: f, icon: i, label: label),
      'tonal' =>
        i == null
            ? FilledButton.tonal(onPressed: f, child: label)
            : FilledButton.tonalIcon(onPressed: f, icon: i, label: label),
      'elevated' =>
        i == null
            ? ElevatedButton(onPressed: f, child: label)
            : ElevatedButton.icon(onPressed: f, icon: i, label: label),
      _ =>
        i == null
            ? FilledButton(onPressed: f, child: label)
            : FilledButton.icon(onPressed: f, icon: i, label: label),
    };
  }

  /// Una lista enlazada se ve con tres copias de su plantilla.
  Widget _listPreview(FlNode n, List<int> path) {
    final bound = n.text('items').trim().isNotEmpty;
    final pad = _num(n.props['padding']) ?? 0;
    final sep = n.props['separated'] == true;
    final items = <Widget>[];
    if (bound) {
      for (var k = 0; k < 3; k++) {
        if (n.children.isEmpty) {
          items.add(
            ListTile(title: Text('«${n.text('as', 'item')}» ${k + 1}')),
          );
        } else {
          // La primera copia se elige; las otras se ven más claras.
          items.add(
            k == 0
                ? _preview(n.children.first, [...path, 0], flex: false)
                : Opacity(
                    opacity: .55,
                    child: IgnorePointer(
                      child: _preview(n.children.first, [
                        ...path,
                        0,
                      ], flex: false),
                    ),
                  ),
          );
        }
        if (sep && k < 2) items.add(const Divider(height: 1));
      }
    } else {
      for (var i = 0; i < n.children.length; i++) {
        items.add(_preview(n.children[i], [...path, i], flex: false));
      }
    }
    return ListView(
      padding: EdgeInsets.all(pad),
      physics: const ClampingScrollPhysics(),
      children: items.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr('Lista vacía'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ]
          : items,
    );
  }
}

/// Una propiedad: clave, nombre, tipo (text, num, bool, choice, color,
/// icon, action, expr) y opciones.
typedef FlProp = (String key, String label, String kind, List<String> options);

const _main = [
  'start',
  'center',
  'end',
  'spaceBetween',
  'spaceAround',
  'spaceEvenly',
];
const _cross = ['start', 'center', 'end', 'stretch'];
const _styles = [
  'displayMedium',
  'displaySmall',
  'headlineMedium',
  'headlineSmall',
  'titleLarge',
  'titleMedium',
  'titleSmall',
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelLarge',
  'labelSmall',
];

/// Las propiedades de cada tipo de widget.
List<FlProp> flProps(String type) => [
  ...switch (type) {
    'Column' || 'Row' => <FlProp>[
      if (type == 'Row')
        ('wrap', markTr('Ajustar (varias líneas)'), 'bool', <String>[]),
      ('main', markTr('Eje principal'), 'choice', _main),
      ('cross', markTr('Eje cruzado'), 'choice', _cross),
      ('gap', markTr('Separación'), 'num', []),
      ('padding', markTr('Margen'), 'num', []),
    ],
    'ListView' => <FlProp>[
      ('items', markTr('Elementos (lista de App)'), 'expr', []),
      ('as', markTr('Nombre de cada elemento'), 'text', []),
      ('separated', markTr('Con separadores'), 'bool', []),
      ('empty', markTr('Texto si está vacía'), 'text', []),
      ('padding', markTr('Margen'), 'num', []),
    ],
    'Card' => <FlProp>[
      ('padding', markTr('Margen'), 'num', []),
      ('color', markTr('Color'), 'color', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Container' => <FlProp>[
      ('height', markTr('Alto'), 'num', []),
      ('width', markTr('Ancho'), 'num', []),
      ('padding', markTr('Margen'), 'num', []),
      ('color', markTr('Color'), 'color', []),
      ('radius', markTr('Radio de las esquinas'), 'num', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Padding' => <FlProp>[('padding', markTr('Margen'), 'num', [])],
    'Expanded' => <FlProp>[('flex', markTr('Proporción'), 'num', [])],
    'Text' => <FlProp>[
      ('text', markTr('Texto'), 'text', []),
      ('style', markTr('Estilo'), 'choice', _styles),
      ('color', markTr('Color'), 'color', []),
      ('bold', markTr('Negrita'), 'bool', []),
      ('strike', markTr('Tachado (expresión)'), 'expr', []),
      ('align', markTr('Alineación'), 'choice', ['left', 'center', 'right']),
      ('maxLines', markTr('Líneas como máximo'), 'num', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Button' => <FlProp>[
      ('text', markTr('Texto'), 'text', []),
      (
        'variant',
        markTr('Estilo'),
        'choice',
        ['filled', 'tonal', 'outlined', 'text', 'elevated'],
      ),
      ('icon', markTr('Icono'), 'icon', []),
      ('enabled', markTr('Activo (expresión)'), 'expr', []),
      ('onTap', markTr('Al pulsar'), 'action', []),
    ],
    'IconButton' => <FlProp>[
      ('icon', markTr('Icono'), 'icon', []),
      ('tooltip', markTr('Ayuda'), 'text', []),
      ('onTap', markTr('Al pulsar'), 'action', []),
    ],
    'TextField' => <FlProp>[
      ('label', markTr('Etiqueta'), 'text', []),
      ('hint', markTr('Indicación'), 'text', []),
      ('icon', markTr('Icono'), 'icon', []),
      ('bind', markTr('Guarda en (campo de App)'), 'text', []),
      (
        'keyboard',
        markTr('Teclado'),
        'choice',
        ['text', 'number', 'email', 'phone', 'multiline'],
      ),
      ('obscure', markTr('Contraseña'), 'bool', []),
      ('lines', markTr('Líneas'), 'num', []),
      ('onSubmit', markTr('Al pulsar Intro'), 'action', []),
    ],
    'ListTile' => <FlProp>[
      ('title', markTr('Título'), 'text', []),
      ('subtitle', markTr('Subtítulo'), 'text', []),
      ('icon', markTr('Icono'), 'icon', []),
      ('leadingColor', markTr('Color del icono'), 'color', []),
      ('trailing', markTr('Texto a la derecha'), 'text', []),
      ('trailingIcon', markTr('Icono a la derecha'), 'icon', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Checkbox' || 'Switch' => <FlProp>[
      ('value', markTr('Valor (expresión)'), 'expr', []),
      ('onChanged', markTr('Al cambiar (v: el valor nuevo)'), 'action', []),
    ],
    'Chip' => <FlProp>[
      ('text', markTr('Texto'), 'text', []),
      ('icon', markTr('Icono'), 'icon', []),
      ('color', markTr('Color'), 'color', []),
      ('selected', markTr('Elegida (expresión)'), 'expr', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Icon' => <FlProp>[
      ('icon', markTr('Icono'), 'icon', []),
      ('size', markTr('Tamaño'), 'num', []),
      ('color', markTr('Color'), 'color', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Image' => <FlProp>[
      ('src', markTr('Imagen (URL, assets/… o =expresión)'), 'text', []),
      ('height', markTr('Alto'), 'num', []),
      ('fit', markTr('Ajuste'), 'choice', ['cover', 'contain', 'fill']),
      ('radius', markTr('Radio de las esquinas'), 'num', []),
      ('onTap', markTr('Al tocar'), 'action', []),
    ],
    'Progress' => <FlProp>[('value', markTr('Valor de 0 a 1'), 'expr', [])],
    'SizedBox' => <FlProp>[
      ('height', markTr('Alto'), 'num', []),
      ('width', markTr('Ancho'), 'num', []),
    ],
    _ => <FlProp>[],
  },
  ('visible', markTr('Visible si (expresión)'), 'expr', []),
];

/// El panel de propiedades: las del widget elegido, o las de la pantalla y
/// la app.
class TkFlutterProps extends StatelessWidget {
  const TkFlutterProps({
    super.key,
    required this.app,
    required this.screen,
    required this.node,
    required this.onEdit,
    this.web = false,
  });

  /// La web de Next.js: sin paquetes de pub.dev ni base de datos (aún).
  final bool web;

  final FlApp app;
  final FlScreen screen;
  final FlNode? node;
  final void Function(void Function() f, [String? key]) onEdit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final n = node;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .6,
          color: t.hintColor,
        ),
      ),
    );
    return ColoredBox(
      color: t.colorScheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: n == null
            ? [
                section(tr('PANTALLA')),
                _field(
                  'screen-name',
                  tr('Nombre'),
                  screen.name,
                  (v) => screen.name = v.replaceAll(RegExp(r'\W'), ''),
                ),
                _field(
                  'screen-title',
                  tr('Título'),
                  screen.title,
                  (v) => screen.title = v,
                ),
                _field(
                  'screen-bar',
                  tr('Botones de la barra (icono|acción|insignia)'),
                  screen.bar,
                  (v) => screen.bar = v,
                  hint: r'shopping_cart|go:Carrito|${app.unidades}',
                  lines: 2,
                  mono: true,
                ),
                _switch(
                  tr('Barra superior'),
                  screen.appBar,
                  (v) => screen.appBar = v,
                ),
                _field(
                  'screen-arg',
                  web ? tr('Recibe (un dato)') : tr('Recibe (tipo de Dart)'),
                  screen.arg,
                  (v) => screen.arg = v.trim(),
                  hint: 'Envio',
                ),
                _field(
                  'screen-fab',
                  tr('Botón flotante: icono'),
                  screen.fabIcon,
                  (v) => screen.fabIcon = v.trim(),
                  hint: 'add',
                ),
                _field(
                  'screen-fab-action',
                  tr('Botón flotante: acción'),
                  screen.fabAction,
                  (v) => screen.fabAction = v,
                  hint: 'go:Nuevo',
                  mono: true,
                ),
                section(tr('APP')),
                _field(
                  'app-title',
                  tr('Título'),
                  app.title,
                  (v) => app.title = v,
                ),
                _field(
                  'app-color',
                  tr('Color principal'),
                  app.primary,
                  (v) => app.primary = v.trim(),
                  hint: '#2B5FD9',
                ),
                _switch(tr('Tema oscuro'), app.dark, (v) => app.dark = v),
                _field(
                  'app-nav',
                  tr('Menú (Pantalla|icono|texto, una por línea)'),
                  app.nav,
                  (v) => app.nav = v,
                  hint: 'Inicio|home|Inicio',
                  lines: 3,
                  mono: true,
                ),
                if (!web)
                  _field(
                    'app-packages',
                    tr('Paquetes de pub.dev (uno por línea)'),
                    app.packages.join('\n'),
                    (v) => app.packages
                      ..clear()
                      ..addAll(
                        v
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty),
                      ),
                    hint: 'shared_preferences: ^2.3.0',
                    lines: 3,
                    mono: true,
                  ),
                if (!web) ...[
                  section(tr('BASE DE DATOS')),
                  _choice(
                    tr('Conectar con'),
                    app.backend.kind,
                    const ['falcon', 'firebase'],
                    (v) => app.backend = app.backend.copyWith(kind: v),
                    labels: const {
                      'falcon': 'FalconDatabase',
                      'firebase': 'Firebase',
                    },
                  ),
                  if (app.backend.kind == 'falcon')
                    _field(
                      'db-url',
                      tr('Servidor'),
                      app.backend.url,
                      (v) => app.backend = app.backend.copyWith(url: v.trim()),
                      hint: 'https://falcondatabase.com',
                    ),
                  if (app.backend.on) ...[
                    _field(
                      'db-project',
                      app.backend.kind == 'falcon'
                          ? tr('Proyecto (referencia)')
                          : tr('ID del proyecto'),
                      app.backend.project,
                      (v) =>
                          app.backend = app.backend.copyWith(project: v.trim()),
                    ),
                    _field(
                      'db-key',
                      app.backend.kind == 'falcon'
                          ? tr('Clave anon (pública)')
                          : tr('Clave web (apiKey)'),
                      app.backend.key,
                      (v) => app.backend = app.backend.copyWith(key: v.trim()),
                      mono: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        tr(
                          "El estudio genera lib/db.dart: en App, await db.signIn(correo, clave), await db.table('productos').list(), insert, update y delete. Use solo la clave pública: va dentro de la app.",
                        ),
                        style: TextStyle(fontSize: 11.5, color: t.hintColor),
                      ),
                    ),
                  ],
                ],
                _help(context),
              ]
            : [
                section(tr(flWidgets[n.type]?.$1 ?? n.type).toUpperCase()),
                for (final (key, label, kind, options) in flProps(n.type))
                  switch (kind) {
                    'bool' => _switch(tr(label), n.props[key] == true, (v) {
                      if (v) {
                        n.props[key] = true;
                      } else {
                        n.props.remove(key);
                      }
                    }),
                    'choice' => _choice(tr(label), n.text(key), options, (v) {
                      if (v.isEmpty) {
                        n.props.remove(key);
                      } else {
                        n.props[key] = v;
                      }
                    }),
                    _ => _field(
                      'p-$key',
                      tr(label),
                      n.text(key),
                      (v) {
                        if (v.trim().isEmpty) {
                          n.props.remove(key);
                        } else if (kind == 'num' &&
                            num.tryParse(v.trim()) != null) {
                          n.props[key] = num.parse(v.trim());
                        } else {
                          n.props[key] = v;
                        }
                      },
                      hint: switch (kind) {
                        'action' => 'app.metodo() · go:Pantalla(item) · back',
                        'expr' => '=item.hecha',
                        'color' => 'primary · #FF5722 · =app.color(item)',
                        'icon' => 'favorite · =app.icono(item)',
                        _ =>
                          key == 'text' || key == 'title'
                              ? r'Hola ${app.nombre}'
                              : null,
                      },
                      mono: kind == 'action' || kind == 'expr',
                    ),
                  },
              ],
      ),
    );
  }

  Widget _help(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      tr(
        r'Los textos admiten ${…} (Hola ${app.nombre}); un valor con = es una expresión de Dart (=item.hecha); las acciones son código (app.guardar()), go:Pantalla, go:Pantalla(item) o back, separadas por «;». En una lista enlazada, cada elemento es item; en una pantalla que recibe algo, es arg.',
      ),
      style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
    ),
  );

  Widget _field(
    String id,
    String label,
    String value,
    void Function(String) set, {
    String? hint,
    int lines = 1,
    bool mono = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: TextFormField(
      key: ValueKey('fl-prop-$id'),
      initialValue: value,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      style: TextStyle(fontSize: 13, fontFamily: mono ? 'Menlo' : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => onEdit(() => set(v), id),
    ),
  );

  Widget _switch(String label, bool value, void Function(bool) set) =>
      SwitchListTile(
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: (v) => onEdit(() => set(v)),
      );

  Widget _choice(
    String label,
    String value,
    List<String> options,
    void Function(String) set, {
    Map<String, String> labels = const {},
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : '',
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        for (final o in options)
          DropdownMenuItem(value: o, child: Text(labels[o] ?? o)),
      ],
      onChanged: (v) => onEdit(() => set(v ?? '')),
    ),
  );
}

/// La galería de plantillas: en blanco o una de las 20 pantallas más
/// usadas, con su vista previa real.
class FlTemplateGallery extends StatefulWidget {
  const FlTemplateGallery({super.key, required this.app, this.desktop = false});

  final FlApp app;

  /// Vista previa en una ventana de escritorio.
  final bool desktop;

  @override
  State<FlTemplateGallery> createState() => _FlTemplateGalleryState();
}

class _FlTemplateGalleryState extends State<FlTemplateGallery> {
  /// -1: en blanco.
  int _pick = 0;
  late final _name = TextEditingController(text: _suggest());

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Un nombre de pantalla libre a partir del de la plantilla.
  String _suggest() {
    final base = _pick < 0 ? tr('Pantalla') : tr(flTemplates[_pick].name);
    var id = base
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
    if (id.isEmpty || RegExp(r'^\d').hasMatch(id)) id = 'Pantalla$id';
    var name = id;
    var i = 2;
    while (widget.app.screen(name) != null) {
      name = '$id${i++}';
    }
    return name;
  }

  FlScreen _build(String name) => _pick < 0
      ? FlScreen(
          name: name,
          title: name,
          body: FlNode('Column', {'padding': 16, 'gap': 12}),
        )
      : flTemplates[_pick].build(name, tr);

  void _choose(int i) => setState(() {
    _pick = i;
    _name.text = _suggest();
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final name = _name.text.trim();
    final valid =
        RegExp(r'^[A-Za-z]\w*$').hasMatch(name) &&
        widget.app.screen(name) == null;
    Widget item(int i, IconData icon, String title, String sub) => ListTile(
      key: ValueKey('fl-template-${i < 0 ? 'blank' : flTemplates[i].id}'),
      dense: true,
      selected: _pick == i,
      selectedTileColor: t.colorScheme.primary.withValues(alpha: .1),
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _choose(i),
    );
    return Dialog(
      key: const ValueKey('fl-template-gallery'),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: 640,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      tr('Nueva pantalla'),
                      style: t.textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        item(
                          -1,
                          Icons.crop_portrait,
                          tr('En blanco'),
                          tr('Una columna vacía.'),
                        ),
                        const Divider(height: 8),
                        for (final (i, tpl) in flTemplates.indexed)
                          item(
                            i,
                            flIcons[tpl.icon] ?? Icons.smartphone,
                            tr(tpl.name),
                            tr(tpl.description),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: t.dividerColor),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: t.colorScheme.surfaceContainerLow,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final size = FlPhone.sizeOf(desktop: widget.desktop);
                          final scale = [
                            (box.maxHeight - 24) / size.height,
                            (box.maxWidth - 24) / size.width,
                          ].reduce((a, b) => a < b ? a : b).clamp(.25, 1.0);
                          return Center(
                            child: Transform.scale(
                              scale: scale,
                              child: OverflowBox(
                                maxHeight: size.height,
                                maxWidth: size.width,
                                child: IgnorePointer(
                                  child: FlPhone(
                                    key: ValueKey('fl-template-preview-$_pick'),
                                    app: widget.app,
                                    desktop: widget.desktop,
                                    screen: _build(valid ? name : 'Pantalla'),
                                    back: true,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('fl-template-name'),
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: tr('Nombre de la pantalla'),
                              errorText: valid
                                  ? null
                                  : tr(
                                      'Use letras y números, sin repetir otra pantalla.',
                                    ),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(tr('Cancelar')),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.icon(
                          key: const ValueKey('fl-template-add'),
                          onPressed: valid
                              ? () => Navigator.pop(context, _build(name))
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(tr('Añadir la pantalla')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
