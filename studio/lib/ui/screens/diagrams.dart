import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../db/dev_tools.dart';
import '../../db/diagrams.dart';
import '../../core/errors.dart';
import '../../dev/dev_client.dart';
import '../../dev/diagram.dart';
import '../../i18n/i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import '../save_file.dart';

final _flowTypes = <(String, String, IconData)>[
  ('start', markTr('Inicio / fin'), LucideIcons.circlePlay),
  ('process', markTr('Proceso'), LucideIcons.square),
  ('decision', markTr('Decisión'), LucideIcons.diamond),
  ('io', markTr('Entrada / salida'), LucideIcons.fileInput),
  ('note', markTr('Nota'), LucideIcons.stickyNote),
];

Future<T?> _busy<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
  try {
    return await runAction(context, task);
  } finally {
    nav.pop();
  }
}

// =================================================================== lista
/// Código → Diagramas: de flujo y de base de datos.
class DiagramsScreen extends StatefulWidget {
  const DiagramsScreen({super.key});
  @override
  State<DiagramsScreen> createState() => _DiagramsScreenState();
}

class _DiagramsScreenState extends State<DiagramsScreen> {
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await Diagrams.all();
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _open(int id) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DiagramEditorScreen(id: id)));
    _load();
  }

  /// Nombre, tipo y (para la IA) la descripción del diagrama nuevo.
  Future<(String, String, String)?> _ask({bool ai = false}) async {
    final name = TextEditingController();
    final desc = TextEditingController();
    var kind = 'flow';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(ai ? tr('Diagrama con IA') : tr('Nuevo diagrama')),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'flow',
                      icon: const Icon(LucideIcons.workflow, size: 16),
                      label: Text(tr('De flujo')),
                    ),
                    ButtonSegment(
                      value: 'er',
                      icon: const Icon(LucideIcons.database, size: 16),
                      label: Text(tr('De base de datos')),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (v) => set(() => kind = v.first),
                ),
                TextField(
                  controller: name,
                  autofocus: !ai,
                  decoration: InputDecoration(labelText: tr('Nombre')),
                ),
                if (ai)
                  TextField(
                    controller: desc,
                    autofocus: true,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: tr('¿Qué debe mostrar?'),
                      hintText: kind == 'er'
                          ? tr(
                              'p. ej. Una tienda online con clientes, pedidos, líneas de pedido y productos',
                            )
                          : tr(
                              'p. ej. El proceso de login: pedir usuario y clave, validar y bloquear tras 3 intentos',
                            ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr('Cancelar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(ai ? tr('Diseñar') : tr('Crear')),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    final n = name.text.trim().isEmpty
        ? (ai ? desc.text.trim() : '')
        : name.text.trim();
    return (
      n.length > 60 ? '${n.substring(0, 57)}…' : n,
      kind,
      desc.text.trim(),
    );
  }

  Future<void> _fromDb() async {
    final conns = await DevTools.connections();
    if (!mounted) return;
    Object? source = conns.firstOrNull?['id'];
    if (source == null) {
      await showErrorDialog(
        context,
        tr('Primero añada una conexión en Bases de datos.'),
      );
      return;
    }
    final filter = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(tr('Diagrama desde una base de datos')),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Object?>(
                  initialValue: source,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('Base de datos')),
                  items: [
                    for (final r in conns)
                      DropdownMenuItem(
                        value: r['id'],
                        child: Text('${r['name']}'),
                      ),
                  ],
                  onChanged: (v) => set(() => source = v),
                ),
                TextField(
                  controller: filter,
                  decoration: InputDecoration(
                    labelText: tr(
                      'Solo las tablas que empiecen por (opcional)',
                    ),
                    hintText: 'sale_, account_',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr('Cancelar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('Crear')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final id = await _busy(context, tr('Leyendo las tablas…'), () async {
      final row = conns.where((r) => r['id'] == source).firstOrNull;
      final db = await openDevDb('${row!['kind']}', DevTools.configOf(row));
      try {
        final prefixes = filter.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        var tables = (await db.schema())
            .where((t) => prefixes.isEmpty || prefixes.any(t.name.startsWith))
            .toList();
        if (tables.length > 60) tables = tables.take(60).toList();
        if (tables.isEmpty) throw UserError(tr('No hay tablas que coincidan.'));
        return Diagrams.create(
          '${row['name']}${prefixes.isEmpty ? '' : ' (${prefixes.join(', ')})'}',
          'er',
          diagram: Diagram.fromSchema(tables),
        );
      } finally {
        await db.close();
      }
    });
    if (id != null) await _open(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = biPalette(context);
    return Scaffold(
      body: Column(
        children: [
          ControlPanel(
            crumbs: [Crumb(tr('Diagramas'))],
            actions: [
              FilledButton(
                onPressed: () async {
                  final a = await _ask();
                  if (a == null || !context.mounted) return;
                  final id = await runAction(
                    context,
                    () => Diagrams.create(a.$1, a.$2),
                  );
                  if (id != null) await _open(id);
                },
                child: Text(tr('Nuevo')),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final a = await _ask(ai: true);
                  if (a == null || !context.mounted) return;
                  final id = await _busy(
                    context,
                    tr('La IA está diseñando el diagrama…'),
                    () async {
                      final d = await Diagram.design(a.$3, er: a.$2 == 'er');
                      return Diagrams.create(
                        a.$1.isEmpty ? tr('Diagrama') : a.$1,
                        a.$2,
                        diagram: d,
                      );
                    },
                  );
                  if (id != null) await _open(id);
                },
                icon: const Icon(LucideIcons.sparkles, size: 16),
                label: Text(tr('Con IA')),
              ),
              OutlinedButton.icon(
                onPressed: _fromDb,
                icon: const Icon(LucideIcons.databaseZap, size: 16),
                label: Text(tr('Desde una base de datos')),
              ),
            ],
          ),
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Text(
                      tr('Cree un diagrama de flujo o de base de datos.'),
                      style: TextStyle(color: t.hintColor),
                    ),
                  )
                : GridView.extent(
                    padding: const EdgeInsets.all(16),
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      for (final r in _rows)
                        Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _open(r['id'] as int),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    r['kind'] == 'er'
                                        ? LucideIcons.database
                                        : LucideIcons.workflow,
                                    color: r['kind'] == 'er' ? p[2] : p[0],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${r['name']}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${r['kind'] == 'er' ? tr('Base de datos') : tr('Flujo')} · ${Fmt.dateTime(r['write_date'])}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: t.hintColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      LucideIcons.ellipsisVertical,
                                      size: 16,
                                    ),
                                    onSelected: (v) async {
                                      if (v == 'rename') {
                                        final n = await promptText(
                                          context,
                                          tr('Nombre del diagrama'),
                                          '${r['name']}',
                                        );
                                        if (n != null && context.mounted) {
                                          await runAction(
                                            context,
                                            () => Diagrams.rename(
                                              r['id'] as int,
                                              n,
                                            ),
                                          );
                                        }
                                      } else if (await confirmDialog(
                                        context,
                                        tr('Eliminar diagrama'),
                                        tr('¿Eliminar «{0}»?', [r['name']]),
                                        ok: tr('Eliminar'),
                                        danger: true,
                                      )) {
                                        await Diagrams.delete(r['id'] as int);
                                      }
                                      _load();
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text(tr('Renombrar…')),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(tr('Eliminar')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ================================================================== editor
/// Editor de un diagrama: lienzo con las figuras y panel de la elegida.
class DiagramEditorScreen extends StatefulWidget {
  const DiagramEditorScreen({super.key, required this.id});
  final int id;
  @override
  State<DiagramEditorScreen> createState() => _DiagramEditorScreenState();
}

class _DiagramEditorScreenState extends State<DiagramEditorScreen> {
  Map<String, Object?>? _row;
  Diagram _d = Diagram();
  String? _sel, _connectFrom;
  Timer? _save;
  final _canvasKey = GlobalKey();
  final _view = TransformationController();

  bool get _er => _row?['kind'] == 'er';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (_save?.isActive ?? false) {
      _save!.cancel();
      Diagrams.save(widget.id, _d);
    }
    _view.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await Diagrams.get(widget.id);
    if (!mounted || r == null) return;
    setState(() {
      _row = r;
      _d = Diagram.fromJson('${r['data']}');
    });
  }

  /// Guarda medio segundo después del último cambio.
  void _changed() {
    setState(() {});
    _save?.cancel();
    _save = Timer(
      const Duration(milliseconds: 500),
      () => Diagrams.save(widget.id, _d),
    );
  }

  /// Centro de lo que se ve, en coordenadas del lienzo.
  Offset _center() {
    final box = context.size ?? const Size(900, 600);
    return _view.toScene(Offset(box.width / 2 - 200, box.height / 2 - 100));
  }

  void _add(String type) {
    final c = _center();
    final n = DNode(
      id: _d.newId(),
      type: type,
      text: type == 'entity'
          ? 'tabla_${_d.nodes.length + 1}'
          : tr(
              _flowTypes
                  .firstWhere(
                    (t) => t.$1 == type,
                    orElse: () => (type, 'Nota', LucideIcons.square),
                  )
                  .$2,
            ),
      x: math.max(0, c.dx),
      y: math.max(0, c.dy),
      columns: type == 'entity'
          ? [DColumn('id', type: 'INTEGER', pk: true)]
          : null,
    );
    _d.nodes.add(n);
    _sel = n.id;
    _changed();
  }

  void _tapNode(DNode n) {
    final from = _connectFrom;
    if (from != null && from != n.id) {
      if (!_d.edges.any((e) => e.from == from && e.to == n.id)) {
        _d.edges.add(DEdge(from, n.id, kind: _er ? '1:N' : ''));
      }
      _connectFrom = null;
      _sel = n.id;
      _changed();
      return;
    }
    setState(() {
      _connectFrom = null;
      _sel = n.id;
    });
  }

  Future<void> _designAi() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Cambiar el diagrama con IA')),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: c,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _er
                  ? tr(
                      'p. ej. Añade una tabla de facturas relacionada con clientes',
                    )
                  : tr(
                      'p. ej. Añade un paso de enviar correo de confirmación al final',
                    ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(tr('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(tr('Diseñar')),
          ),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty || !mounted) return;
    final d = await _busy(
      context,
      tr('La IA está diseñando el diagrama…'),
      () => Diagram.design(c.text, er: _er, current: _d),
    );
    if (d == null) return;
    setState(() {
      _d = d;
      _sel = null;
    });
    _changed();
  }

  Future<void> _pdf() async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final img = await boundary.toImage(pixelRatio: 2);
    final png = (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    img.dispose();
    final name = '${_row?['name'] ?? tr('Diagrama')}';
    final bytes = () async {
      final doc = pw.Document(title: name);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
      return doc.save();
    }();
    if (!mounted) return;
    await runAction(
      context,
      () async => saveBytes(
        await bytes,
        suggestedName: '${name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')}.pdf',
        typeLabel: 'PDF',
        extension: 'pdf',
      ),
    );
  }

  Future<void> _sql() async {
    final sql = _d.toSql();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('SQL del diagrama')),
        content: SizedBox(
          width: 640,
          height: 420,
          child: SingleChildScrollView(
            child: SelectableText(
              sql.isEmpty ? tr('No hay tablas.') : sql,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 12.5),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: sql)),
            icon: const Icon(LucideIcons.copy, size: 16),
            label: Text(tr('Copiar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('Cerrar')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sel = _sel == null ? null : _d.node(_sel!);
    final palette = _er
        ? <(String, String, IconData)>[
            ('entity', markTr('Tabla'), LucideIcons.table2),
            ('note', markTr('Nota'), LucideIcons.stickyNote),
          ]
        : _flowTypes;
    return Scaffold(
      body: Column(
        children: [
          ControlPanel(
            crumbs: [
              Crumb(tr('Diagramas'), () => Navigator.of(context).pop()),
              Crumb('${_row?['name'] ?? ''}'),
            ],
            actions: [
              for (final (k, label, icon) in palette)
                Tooltip(
                  message: tr('Añadir {0}', [tr(label).toLowerCase()]),
                  child: OutlinedButton.icon(
                    onPressed: () => _add(k),
                    icon: Icon(icon, size: 16),
                    label: Text(tr(label)),
                  ),
                ),
            ],
            trailing: [
              IconButton(
                tooltip: tr('Ordenar'),
                icon: const Icon(LucideIcons.layoutGrid, size: 18),
                onPressed: () {
                  _d.layout(er: _er);
                  _changed();
                },
              ),
              IconButton(
                tooltip: tr('Cambiar con IA'),
                icon: const Icon(LucideIcons.sparkles, size: 18),
                onPressed: _designAi,
              ),
              if (_er)
                IconButton(
                  tooltip: tr('SQL'),
                  icon: const Icon(LucideIcons.fileCode, size: 18),
                  onPressed: _sql,
                ),
              IconButton(
                tooltip: tr('Exportar a PDF'),
                icon: const Icon(LucideIcons.printer, size: 18),
                onPressed: _pdf,
              ),
            ],
          ),
          if (_connectFrom != null)
            Container(
              width: double.infinity,
              color: AppColors.info.withValues(alpha: .12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('Elija la figura de destino de la conexión.'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _connectFrom = null),
                    child: Text(tr('Cancelar')),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _canvas(t)),
                if (sel != null) SizedBox(width: 340, child: _panel(t, sel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvas(ThemeData t) {
    final p = biPalette(context);
    var w = 1200.0, h = 800.0;
    for (final n in _d.nodes) {
      w = math.max(w, n.x + n.w + 200);
      h = math.max(h, n.y + n.h + 200);
    }
    return GestureDetector(
      onTap: () => setState(() {
        _sel = null;
        _connectFrom = null;
      }),
      child: InteractiveViewer(
        transformationController: _view,
        constrained: false,
        minScale: .25,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(600),
        child: RepaintBoundary(
          key: _canvasKey,
          child: Container(
            width: w,
            height: h,
            color: t.scaffoldBackgroundColor,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgesPainter(
                      _d,
                      er: _er,
                      line: t.hintColor,
                      text: AppColors.ink(context),
                      bg: t.scaffoldBackgroundColor,
                      selected: _sel,
                    ),
                  ),
                ),
                for (final n in _d.nodes)
                  Positioned(
                    left: n.x,
                    top: n.y,
                    child: GestureDetector(
                      onTap: () => _tapNode(n),
                      onPanStart: (_) => setState(() => _sel = n.id),
                      onPanUpdate: (d) {
                        n
                          ..x = math.max(0, n.x + d.delta.dx)
                          ..y = math.max(0, n.y + d.delta.dy);
                        setState(() {});
                      },
                      onPanEnd: (_) => _changed(),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: _NodeView(
                          node: n,
                          color: p[n.color % p.length],
                          selected: n.id == _sel,
                          connecting: _connectFrom != null,
                        ),
                      ),
                    ),
                  ),
                if (_sel != null && _d.node(_sel!) != null)
                  () {
                    final n = _d.node(_sel!)!;
                    return Positioned(
                      left: n.x + n.w + 6,
                      top: n.y + n.h / 2 - 14,
                      child: Tooltip(
                        message: tr('Conectar con otra figura'),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _connectFrom = n.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: p[0],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.arrowRight,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(ThemeData t, DNode n) {
    final p = biPalette(context);
    final edges = _d.edges
        .where((e) => e.from == n.id || e.to == n.id)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        border: Border(left: BorderSide(color: t.dividerColor)),
      ),
      child: ListView(
        key: ValueKey('panel-${n.id}'),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  n.type == 'entity'
                      ? tr('Tabla')
                      : tr(
                          _flowTypes
                              .firstWhere(
                                (x) => x.$1 == n.type,
                                orElse: () =>
                                    (n.type, 'Nota', LucideIcons.square),
                              )
                              .$2,
                        ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('Cerrar'),
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () => setState(() => _sel = null),
              ),
            ],
          ),
          TextFormField(
            initialValue: n.text,
            maxLines: n.type == 'entity' ? 1 : 4,
            minLines: 1,
            decoration: InputDecoration(
              labelText: n.type == 'entity'
                  ? tr('Nombre de la tabla')
                  : tr('Texto'),
            ),
            onChanged: (v) {
              n.text = v;
              _changed();
            },
          ),
          if (!_er && n.type != 'note') ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: n.type,
              decoration: InputDecoration(labelText: tr('Forma')),
              items: [
                for (final (k, label, icon) in _flowTypes)
                  DropdownMenuItem(
                    value: k,
                    child: Row(
                      children: [
                        Icon(icon, size: 16),
                        const SizedBox(width: 8),
                        Text(tr(label)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                n.type = v ?? n.type;
                _changed();
              },
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < p.length; i++)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    n.color = i;
                    _changed();
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: p[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: n.color % p.length == i
                            ? AppColors.ink(context)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (n.type == 'entity') ...[
            const SizedBox(height: 14),
            Text(
              tr('Columnas'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final c in n.columns)
              Row(
                key: ObjectKey(c),
                children: [
                  Tooltip(
                    message: tr('Clave primaria'),
                    child: Checkbox(
                      value: c.pk,
                      onChanged: (v) {
                        c.pk = v ?? false;
                        _changed();
                      },
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: c.name,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: tr('columna'),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        c.name = v;
                        _changed();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: c.type,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'TEXT',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        c.type = v.toUpperCase();
                        _changed();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Quitar'),
                    icon: const Icon(LucideIcons.x, size: 14),
                    onPressed: () {
                      n.columns.remove(c);
                      _changed();
                    },
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  n.columns.add(DColumn('columna_${n.columns.length + 1}'));
                  _changed();
                },
                icon: const Icon(LucideIcons.plus, size: 14),
                label: Text(tr('Añadir columna')),
              ),
            ),
          ],
          const Divider(height: 24),
          Text(
            tr('Conexiones'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (edges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                tr('Pulse → junto a la figura para conectarla con otra.'),
                style: TextStyle(color: t.hintColor, fontSize: 12.5),
              ),
            ),
          for (final e in edges)
            Padding(
              key: ObjectKey(e),
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.from == n.id
                              ? '→ ${_d.node(e.to)?.text ?? e.to}'
                              : '← ${_d.node(e.from)?.text ?? e.from}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        TextFormField(
                          initialValue: e.label,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: _er
                                ? tr('columna (p. ej. cliente_id)')
                                : tr('etiqueta (p. ej. Sí)'),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            e.label = v;
                            _changed();
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_er)
                    DropdownButton<String>(
                      value: ['1:1', '1:N', 'N:M'].contains(e.kind)
                          ? e.kind
                          : '1:N',
                      items: [
                        for (final k in ['1:1', '1:N', 'N:M'])
                          DropdownMenuItem(value: k, child: Text(k)),
                      ],
                      onChanged: (v) {
                        e.kind = v ?? e.kind;
                        _changed();
                      },
                    ),
                  IconButton(
                    tooltip: tr('Quitar la conexión'),
                    icon: const Icon(LucideIcons.x, size: 14),
                    onPressed: () {
                      _d.edges.remove(e);
                      _changed();
                    },
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              _d.nodes.remove(n);
              _d.edges.removeWhere((e) => e.from == n.id || e.to == n.id);
              _sel = null;
              _changed();
            },
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: Text(tr('Quitar la figura')),
          ),
        ],
      ),
    );
  }
}

/// Una figura: forma del diagrama de flujo o tabla con sus columnas.
class _NodeView extends StatelessWidget {
  const _NodeView({
    required this.node,
    required this.color,
    required this.selected,
    required this.connecting,
  });
  final DNode node;
  final Color color;
  final bool selected, connecting;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ink = AppColors.ink(context);
    final border = selected
        ? ink
        : (connecting ? color : color.withValues(alpha: .8));
    if (node.type == 'entity') {
      return Container(
        width: node.w,
        height: node.h,
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          border: Border.all(color: border, width: selected ? 2.5 : 1.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Text(
                node.text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final c in node.columns)
              SizedBox(
                height: 22,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        child: c.pk
                            ? Icon(
                                LucideIcons.keyRound,
                                size: 12,
                                color: AppColors.warning,
                              )
                            : c.fk.isNotEmpty
                            ? Icon(
                                LucideIcons.link,
                                size: 12,
                                color: t.hintColor,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: c.pk ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                      Text(
                        c.type,
                        style: TextStyle(fontSize: 10.5, color: t.hintColor),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      width: node.w,
      height: node.h,
      child: CustomPaint(
        painter: _ShapePainter(
          node.type,
          fill: node.type == 'note'
              ? AppColors.warning.withValues(alpha: .16)
              : color.withValues(alpha: .14),
          border: node.type == 'note' ? AppColors.warning : border,
          width: selected ? 2.5 : 1.6,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: node.type == 'decision' ? 30 : 14,
              vertical: 6,
            ),
            child: Text(
              node.text,
              textAlign: TextAlign.center,
              maxLines: node.type == 'note' ? 5 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: node.type == 'note' ? null : FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(
    this.type, {
    required this.fill,
    required this.border,
    required this.width,
  });
  final String type;
  final Color fill, border;
  final double width;

  @override
  void paint(Canvas canvas, Size s) {
    final path = switch (type) {
      'start' =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & s,
            Radius.circular(s.height / 2),
          ),
        ),
      'decision' =>
        Path()
          ..moveTo(s.width / 2, 0)
          ..lineTo(s.width, s.height / 2)
          ..lineTo(s.width / 2, s.height)
          ..lineTo(0, s.height / 2)
          ..close(),
      'io' =>
        Path()
          ..moveTo(18, 0)
          ..lineTo(s.width, 0)
          ..lineTo(s.width - 18, s.height)
          ..lineTo(0, s.height)
          ..close(),
      _ =>
        Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(8)),
        ),
    };
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter o) =>
      o.type != type ||
      o.fill != fill ||
      o.border != border ||
      o.width != width;
}

/// Conexiones: líneas con flecha (flujo) o con la cardinalidad (tablas).
class _EdgesPainter extends CustomPainter {
  _EdgesPainter(
    this.d, {
    required this.er,
    required this.line,
    required this.text,
    required this.bg,
    this.selected,
  });
  final Diagram d;
  final bool er;
  final Color line, text, bg;
  final String? selected;

  /// Punto del borde del rectángulo de [n] en la dirección de [to].
  Offset _edge(DNode n, Offset to) {
    final c = Offset(n.x + n.w / 2, n.y + n.h / 2);
    final dir = to - c;
    if (dir.distance == 0) return c;
    final tx = dir.dx == 0 ? double.infinity : (n.w / 2) / dir.dx.abs();
    final ty = dir.dy == 0 ? double.infinity : (n.h / 2) / dir.dy.abs();
    return c + dir * math.min(tx, ty);
  }

  void _label(
    Canvas canvas,
    String s,
    Offset at, {
    double size = 11,
    bool box = true,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: text,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromCenter(
      center: at,
      width: tp.width + 8,
      height: tp.height + 4,
    );
    if (box) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = bg,
      );
    }
    tp.paint(canvas, r.topLeft + const Offset(4, 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in d.edges) {
      final a = d.node(e.from), b = d.node(e.to);
      if (a == null || b == null) continue;
      final hot = selected == a.id || selected == b.id;
      final p = Paint()
        ..color = hot ? text : line
        ..strokeWidth = hot ? 2 : 1.5
        ..style = PaintingStyle.stroke;
      final ca = Offset(a.x + a.w / 2, a.y + a.h / 2),
          cb = Offset(b.x + b.w / 2, b.y + b.h / 2);
      final from = _edge(a, cb), to = _edge(b, ca);
      canvas.drawLine(from, to, p);
      final dir = (to - from) / math.max(1, (to - from).distance);
      if (!er) {
        // Punta de flecha.
        final n = Offset(-dir.dy, dir.dx);
        final tip = Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo((to - dir * 11 + n * 5).dx, (to - dir * 11 + n * 5).dy)
          ..lineTo((to - dir * 11 - n * 5).dx, (to - dir * 11 - n * 5).dy)
          ..close();
        canvas.drawPath(tip, Paint()..color = hot ? text : line);
      } else {
        final (x, y) = switch (e.kind) {
          '1:1' => ('1', '1'),
          'N:M' => ('N', 'M'),
          _ => ('1', 'N'),
        };
        _label(canvas, x, from + dir * 14, box: true);
        _label(canvas, y, to - dir * 14, box: true);
      }
      if (e.label.isNotEmpty) {
        _label(canvas, e.label, (from + to) / 2, size: 10.5);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter o) => true;
}
