import 'package:flutter/material.dart';

import '../../code/tk_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../core/project_store.dart';
import '../../core/settings.dart';
import '../../core/studio_db.dart';
import '../../i18n/i18n.dart';
import '../widgets.dart';

/// Lista de proyectos del Diseñador, como un explorador de archivos: columnas
/// que se ordenan, búsqueda, páginas y menú del botón derecho (sobre un
/// proyecto, sus acciones; sobre el fondo, «Agregar nuevo»). También se
/// puede ver en tarjetas.
class ProjectBrowser extends StatefulWidget {
  const ProjectBrowser({
    super.key,
    required this.projects,
    required this.card,
    required this.onOpen,
    required this.onAction,
    required this.onAdd,
  });

  final List<StudioProject> projects;

  /// Tarjeta de un proyecto (la vista de tarjetas).
  final Widget Function(StudioProject) card;
  final void Function(StudioProject) onOpen;

  /// `open`, `run`, `reveal`, `github`, `budget`, `copy` o `delete`.
  final void Function(StudioProject, String) onAction;

  /// `desktop`, `web`, `folder` o `refresh`.
  final void Function(String) onAdd;

  @override
  State<ProjectBrowser> createState() => _ProjectBrowserState();
}

enum _Col { name, kind, size, modified, folder }

class _ProjectBrowserState extends State<ProjectBrowser> {
  static const _sizes = [10, 15, 25, 50];

  String _query = '';
  _Col _sort = _Col.modified;
  bool _asc = false;
  int _page = 0;
  int _perPage = 15;
  // Por defecto, las tarjetas (se ve el diseño de cada proyecto).
  bool _cards = true;
  String? _selected;

  final _menu = MenuController();
  final _area = GlobalKey();
  StudioProject? _menuFor;

  @override
  void initState() {
    super.initState();
    if (!StudioDb.isOpen) return;
    Settings.get('designer.view').then((v) {
      if (mounted) setState(() => _cards = v != 'list');
    });
    Settings.get('designer.per_page').then((v) {
      final n = int.tryParse(v ?? '');
      if (mounted && n != null && _sizes.contains(n)) {
        setState(() => _perPage = n);
      }
    });
  }

  // ------------------------------------------------------------- datos
  String _kind(StudioProject a) => tkTargetLabel(a.design.target);

  String _folder(StudioProject a) => p.basename(p.dirname(a.path));

  List<StudioProject> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final a in widget.projects)
        if (q.isEmpty ||
            a.name.toLowerCase().contains(q) ||
            (a.description ?? '').toLowerCase().contains(q))
          a,
    ];
    int cmp(StudioProject a, StudioProject b) => switch (_sort) {
      _Col.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      _Col.kind => _kind(a).compareTo(_kind(b)),
      _Col.size => a.design.widgets.length.compareTo(b.design.widgets.length),
      _Col.modified => a.modified.compareTo(b.modified),
      _Col.folder => _folder(a).compareTo(_folder(b)),
    };
    list.sort((a, b) {
      final c = cmp(a, b);
      if (c != 0) return _asc ? c : -c;
      // A igualdad, por nombre: el orden no cambia entre una vez y otra.
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  void _sortBy(_Col c) => setState(() {
    if (_sort == c) {
      _asc = !_asc;
    } else {
      _sort = c;
      _asc = c == _Col.name || c == _Col.kind || c == _Col.folder;
    }
    _page = 0;
  });

  // -------------------------------------------------------------- menús
  /// Abre el menú en [global]: el de un proyecto o, sin él, el del fondo.
  void _openMenu(Offset global, StudioProject? on) {
    final box = _area.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() {
      _menuFor = on;
      if (on != null) _selected = on.path;
    });
    _menu.open(position: box.globalToLocal(global));
  }

  List<Widget> _menuItems() {
    final a = _menuFor;
    MenuItemButton item(IconData icon, String text, VoidCallback onTap) =>
        MenuItemButton(
          leadingIcon: Icon(icon, size: 16),
          onPressed: onTap,
          child: Text(text),
        );
    final add = SubmenuButton(
      leadingIcon: const Icon(LucideIcons.plus, size: 16),
      menuChildren: [
        item(
          LucideIcons.appWindowMac,
          tr('Proyecto de escritorio (Python)'),
          () => widget.onAdd('desktop'),
        ),
        item(
          LucideIcons.globe,
          tr('Proyecto web (Flask)'),
          () => widget.onAdd('web'),
        ),
        const Divider(height: 1),
        item(
          LucideIcons.folderOpen,
          tr('Abrir carpeta…'),
          () => widget.onAdd('folder'),
        ),
      ],
      child: Text(tr('Agregar nuevo')),
    );
    if (a == null) {
      return [
        add,
        item(
          LucideIcons.refreshCw,
          tr('Actualizar'),
          () => widget.onAdd('refresh'),
        ),
      ];
    }
    void act(String v) => widget.onAction(a, v);
    return [
      item(LucideIcons.squarePen, tr('Abrir'), () => act('open')),
      item(LucideIcons.play, tr('Ejecutar'), () => act('run')),
      item(
        LucideIcons.folderOpen,
        tr('Mostrar la carpeta'),
        () => act('reveal'),
      ),
      const Divider(height: 1),
      item(LucideIcons.gitFork, tr('GitHub…'), () => act('github')),
      item(LucideIcons.wallet, tr('Presupuesto de IA'), () => act('budget')),
      const Divider(height: 1),
      item(LucideIcons.copy, tr('Duplicar'), () => act('copy')),
      item(LucideIcons.trash2, tr('Eliminar'), () => act('delete')),
      const Divider(height: 1),
      add,
    ];
  }

  // -------------------------------------------------------------- vista
  Widget _header(ThemeData t, _Col c, String label, {int flex = 1}) {
    final on = _sort == c;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _sortBy(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelMedium?.copyWith(
                    color: on ? t.colorScheme.onSurface : t.hintColor,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (on)
                Icon(
                  _asc ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(ThemeData t, String text, {int flex = 1}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.textTheme.bodySmall,
      ),
    ),
  );

  Widget _row(ThemeData t, StudioProject a) {
    final on = _selected == a.path;
    return GestureDetector(
      key: ValueKey('tk-row-${a.path}'),
      onSecondaryTapDown: (d) => _openMenu(d.globalPosition, a),
      child: InkWell(
        onTap: () => setState(() => _selected = a.path),
        onDoubleTap: () => widget.onOpen(a),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: on ? t.colorScheme.primary.withValues(alpha: .10) : null,
            border: Border(bottom: BorderSide(color: t.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        a.design.isWebHtml
                            ? LucideIcons.fileCode
                            : a.design.isWebReact
                            ? LucideIcons.atom
                            : a.design.isReactNative
                            ? LucideIcons.tabletSmartphone
                            : a.design.isWebNext
                            ? LucideIcons.panelsTopLeft
                            : a.design.isFlutterDesktop
                            ? LucideIcons.monitor
                            : a.design.isFlutter
                            ? LucideIcons.smartphone
                            : a.design.isConsole
                            ? LucideIcons.squareTerminal
                            : a.isCpp
                            ? LucideIcons.cpu
                            : a.isPascal
                            ? LucideIcons.feather
                            : a.isNext
                            ? LucideIcons.panelsTopLeft
                            : a.isChrome
                            ? LucideIcons.puzzle
                            : a.isElectron
                            ? LucideIcons.atom
                            : a.isWeb
                            ? LucideIcons.globe
                            : LucideIcons.appWindowMac,
                        size: 18,
                        color: t.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((a.description ?? '').isNotEmpty)
                              Text(
                                a.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: t.hintColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _cell(t, _kind(a), flex: 2),
              _cell(t, '${a.design.widgets.length}'),
              _cell(t, Fmt.dateTime(a.modified), flex: 2),
              _cell(t, _folder(a), flex: 2),
              IconButton(
                tooltip: tr('Ejecutar'),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.play, color: Color(0xFF2F9E44)),
                onPressed: () => widget.onAction(a, 'run'),
              ),
              Builder(
                builder: (b) => IconButton(
                  tooltip: tr('Más acciones'),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.ellipsis),
                  onPressed: () {
                    final box = b.findRenderObject() as RenderBox;
                    _openMenu(
                      box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                      a,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pager(ThemeData t, int total, int pages) {
    final from = total == 0 ? 0 : _page * _perPage + 1;
    final to = ((_page + 1) * _perPage).clamp(0, total);
    // Números de página alrededor de la actual.
    final shown = <int>{
      0,
      pages - 1,
      for (var i = _page - 2; i <= _page + 2; i++)
        if (i >= 0 && i < pages) i,
    }.toList()..sort();
    final buttons = <Widget>[];
    for (var k = 0; k < shown.length; k++) {
      if (k > 0 && shown[k] - shown[k - 1] > 1) {
        buttons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('…'),
          ),
        );
      }
      final i = shown[k];
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: i == _page
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(34, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {},
                  child: Text('${i + 1}'),
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(34, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => setState(() => _page = i),
                  child: Text('${i + 1}'),
                ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            tr('{0}–{1} de {2} proyectos', [from, to, total]),
            style: t.textTheme.bodySmall,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Por página'), style: t.textTheme.bodySmall),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _perPage,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  for (final n in _sizes)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n == null) return;
                  setState(() {
                    _perPage = n;
                    _page = 0;
                  });
                  if (StudioDb.isOpen) Settings.set('designer.per_page', '$n');
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: tr('Página anterior'),
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                onPressed: _page == 0 ? null : () => setState(() => _page--),
              ),
              ...buttons,
              IconButton(
                tooltip: tr('Página siguiente'),
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                onPressed: _page >= pages - 1
                    ? null
                    : () => setState(() => _page++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final all = _filtered;
    final pages = ((all.length + _perPage - 1) ~/ _perPage).clamp(1, 1 << 30);
    if (_page >= pages) _page = pages - 1;
    final items = all.skip(_page * _perPage).take(_perPage).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                key: const ValueKey('tk-search'),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: tr('Buscar proyectos'),
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                  _page = 0;
                }),
              ),
            ),
            const Spacer(),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(LucideIcons.list, size: 16),
                  tooltip: tr('Lista'),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(LucideIcons.layoutGrid, size: 16),
                  tooltip: tr('Tarjetas'),
                ),
              ],
              selected: {_cards},
              onSelectionChanged: (v) {
                setState(() => _cards = v.first);
                if (StudioDb.isOpen) {
                  Settings.set('designer.view', _cards ? null : 'list');
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        MenuAnchor(
          controller: _menu,
          menuChildren: _menuItems(),
          child: GestureDetector(
            key: _area,
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: (d) => _openMenu(d.globalPosition, null),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          tr('Ningún proyecto coincide con la búsqueda.'),
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: t.hintColor,
                          ),
                        ),
                      ),
                    )
                  : _cards
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final a in items)
                            GestureDetector(
                              onSecondaryTapDown: (d) =>
                                  _openMenu(d.globalPosition, a),
                              child: widget.card(a),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: t.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                        color: t.colorScheme.surface,
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: t.dividerColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                _header(t, _Col.name, tr('Nombre'), flex: 4),
                                _header(t, _Col.kind, tr('Tipo'), flex: 2),
                                _header(t, _Col.size, tr('Componentes')),
                                _header(
                                  t,
                                  _Col.modified,
                                  tr('Modificado'),
                                  flex: 2,
                                ),
                                _header(t, _Col.folder, tr('Carpeta'), flex: 2),
                                const SizedBox(width: 80),
                              ],
                            ),
                          ),
                          for (final a in items) _row(t, a),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        _pager(t, all.length, pages),
      ],
    );
  }
}
