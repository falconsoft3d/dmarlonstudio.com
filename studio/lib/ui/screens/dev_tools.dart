import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../db/dev_tools.dart';
import '../../core/errors.dart';
import '../../dev/api_client.dart';
import '../../dev/dev_client.dart';
import '../../dev/dev_cloud_db.dart';
import '../../dev/dev_types.dart';
import '../../i18n/i18n.dart';
import '../save_file.dart';
import '../theme.dart';
import '../widgets.dart';

const _mono = TextStyle(fontFamily: 'Menlo', fontSize: 12.5);

IconData _kindIcon(String kind) => switch (kind) {
  'ftp' => LucideIcons.folderTree,
  'mongodb' => LucideIcons.leaf,
  'falcon' => LucideIcons.cloud,
  'firebase' => LucideIcons.flame,
  _ => LucideIcons.database,
};

String _kindName(String kind) => DevTools.kinds
    .firstWhere((k) => k.$1 == kind, orElse: () => (kind, kind))
    .$2;

/// Alta o edición de una conexión (bases de datos o FTP). Devuelve true si
/// cambió algo.
Future<bool> _editConnection(
  BuildContext context, {
  Map<String, Object?>? row,
  required bool ftp,
}) async {
  final cfg = row == null ? <String, Object?>{} : DevTools.configOf(row);
  var kind = '${row?['kind'] ?? (ftp ? 'ftp' : 'postgres')}';
  final name = TextEditingController(text: '${row?['name'] ?? ''}');
  final ctl = {
    for (final k in [
      'host',
      'port',
      'database',
      'user',
      'password',
      'path',
      'uri',
      'url',
      'project',
      'key',
      'email',
      'emulator',
    ])
      k: TextEditingController(text: '${cfg[k] ?? ''}'),
  };
  var ssl = cfg['ssl'] == true;
  var security = '${cfg['security'] ?? 'ftp'}';
  String? result;
  var ok = false;
  Map<String, Object?> config() => {
    for (final e in ctl.entries)
      if (e.value.text.trim().isNotEmpty)
        e.key: e.key == 'password' ? e.value.text : e.value.text.trim(),
    if (ssl) 'ssl': true,
    if (kind == 'ftp') 'security': security,
  };
  final action = await showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        Widget f(String k, String label, {bool secret = false, String? hint}) =>
            TextField(
              controller: ctl[k],
              obscureText: secret,
              decoration: InputDecoration(labelText: label, hintText: hint),
            );
        final defaultPort = switch (kind) {
          'postgres' => '5432',
          'mysql' => '3306',
          'mongodb' => '27017',
          _ => '21',
        };
        return AlertDialog(
          title: Text(row == null ? tr('Nueva conexión') : tr('Conexión')),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: tr('Nombre')),
                  ),
                  if (!ftp) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: kind,
                      decoration: InputDecoration(labelText: tr('Tipo')),
                      items: [
                        for (final (k, n) in DevTools.kinds)
                          if (k != 'ftp')
                            DropdownMenuItem(value: k, child: Text(n)),
                      ],
                      onChanged: (v) => set(() => kind = v ?? kind),
                    ),
                  ],
                  if (kind == 'falcon') ...[
                    f(
                      'url',
                      tr('Servidor'),
                      hint: 'https://falcondatabase.com',
                    ),
                    f(
                      'project',
                      tr('Proyecto'),
                      hint: tr('La referencia de 20 letras'),
                    ),
                    f(
                      'key',
                      tr('Clave de API'),
                      secret: true,
                      hint: 'fdb_anon_… / fdb_service_…',
                    ),
                    f('email', tr('Correo (si las tablas piden sesión)')),
                    f('password', tr('Contraseña'), secret: true),
                  ] else if (kind == 'firebase') ...[
                    f('project', tr('ID del proyecto'), hint: 'mi-app-1234'),
                    f(
                      'key',
                      tr('Clave web (apiKey)'),
                      secret: true,
                      hint: 'AIza…',
                    ),
                    f('email', tr('Correo (si las reglas piden sesión)')),
                    f('password', tr('Contraseña'), secret: true),
                    f(
                      'database',
                      tr('Base de datos (opcional)'),
                      hint: '(default)',
                    ),
                    f(
                      'emulator',
                      tr('Emulador (opcional)'),
                      hint: 'localhost:8080',
                    ),
                  ] else if (kind == 'sqlite')
                    Row(
                      children: [
                        Expanded(
                          child: f(
                            'path',
                            tr('Archivo'),
                            hint: '/ruta/base.sqlite',
                          ),
                        ),
                        IconButton(
                          tooltip: tr('Elegir archivo'),
                          icon: const Icon(LucideIcons.folderOpen, size: 18),
                          onPressed: () async {
                            final x = await openFile();
                            if (x != null) {
                              set(() => ctl['path']!.text = x.path);
                            }
                          },
                        ),
                      ],
                    )
                  else ...[
                    if (kind == 'mongodb')
                      f(
                        'uri',
                        tr('URI (opcional)'),
                        hint: 'mongodb+srv://usuario:clave@cluster/base',
                      ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: f('host', tr('Servidor'), hint: 'localhost'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: f('port', tr('Puerto'), hint: defaultPort),
                        ),
                      ],
                    ),
                    if (kind != 'ftp') f('database', tr('Base de datos')),
                    f('user', tr('Usuario')),
                    f('password', tr('Contraseña'), secret: true),
                    if (kind == 'postgres' || kind == 'mysql')
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr('Conexión cifrada (SSL)')),
                        value: ssl,
                        onChanged: (v) => set(() => ssl = v),
                      ),
                    if (kind == 'ftp')
                      DropdownButtonFormField<String>(
                        initialValue: security,
                        decoration: InputDecoration(labelText: tr('Seguridad')),
                        items: [
                          DropdownMenuItem(
                            value: 'ftp',
                            child: Text(tr('FTP (sin cifrar)')),
                          ),
                          DropdownMenuItem(
                            value: 'ftpes',
                            child: Text(tr('FTPES (TLS explícito)')),
                          ),
                          DropdownMenuItem(
                            value: 'ftps',
                            child: Text(tr('FTPS (TLS implícito)')),
                          ),
                        ],
                        onChanged: (v) => set(() => security = v ?? security),
                      ),
                  ],
                  if (result != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        result!,
                        style: TextStyle(
                          color: ok ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (row != null)
              TextButton(
                onPressed: () => Navigator.pop(c, 'delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: Text(tr('Eliminar')),
              ),
            OutlinedButton(
              onPressed: () async {
                set(() => result = tr('Probando…'));
                try {
                  if (kind == 'ftp') {
                    final s = await openDevFtp(config());
                    final dir = await s.pwd();
                    await s.close();
                    set(() => result = tr('Conexión correcta: {0}', [dir]));
                  } else {
                    final d = await openDevDb(kind, config());
                    final n = (await d.schema()).length;
                    await d.close();
                    set(
                      () => result = tr('Conexión correcta: {0} tablas', [n]),
                    );
                  }
                  ok = true;
                } on UserError catch (e) {
                  set(() {
                    ok = false;
                    result = e.message;
                  });
                }
              },
              child: Text(tr('Probar conexión')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(tr('Descartar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: Text(tr('Guardar')),
            ),
          ],
        );
      },
    ),
  );
  if (!context.mounted) return false;
  if (action == 'save') {
    return await runAction(
          context,
          () => DevTools.saveConnection(
            row?['id'] as int?,
            kind: kind,
            name: name.text,
            config: config(),
          ),
        ) !=
        null;
  }
  if (action == 'delete' &&
      await confirmDialog(
        context,
        tr('Eliminar conexión'),
        tr('¿Eliminar «{0}»?', [row!['name']]),
        ok: tr('Eliminar'),
        danger: true,
      )) {
    await DevTools.deleteConnection(row['id'] as int);
    return true;
  }
  return false;
}

/// Lista lateral de conexiones.
class _ConnectionList extends StatelessWidget {
  const _ConnectionList({
    required this.rows,
    required this.selected,
    required this.onOpen,
    required this.onEdit,
    required this.onAdd,
  });
  final List<Map<String, Object?>> rows;
  final Object? selected;
  final ValueChanged<Map<String, Object?>> onOpen, onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget tile(Map<String, Object?> r) {
      final sel = selected == r['id'];
      return ListTile(
        dense: true,
        selected: sel,
        selectedTileColor: t.colorScheme.onSurface.withValues(alpha: .07),
        leading: Icon(
          _kindIcon('${r['kind']}'),
          size: 18,
          color:
              biPalette(context)[switch (r['kind']) {
                'mongodb' => 5,
                'firebase' => 3,
                'falcon' => 1,
                _ => 0,
              }],
        ),
        title: Text('${r['name']}', overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _kindName('${r['kind']}'),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          tooltip: tr('Editar'),
          icon: const Icon(LucideIcons.pencil, size: 14),
          onPressed: () => onEdit(r),
        ),
        onTap: () => onOpen(r),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr('Conexiones'),
                  style: TextStyle(
                    color: t.hintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('Nueva conexión'),
                icon: const Icon(LucideIcons.plus, size: 18),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        for (final r in rows) tile(r),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              tr('Añada una conexión con «+».'),
              style: TextStyle(color: t.hintColor),
            ),
          ),
      ],
    );
  }
}

// ========================================================== bases de datos
/// Código → Bases de datos: SQLite, PostgreSQL, MySQL y MongoDB.
class DbManagerScreen extends StatefulWidget {
  const DbManagerScreen({super.key});
  @override
  State<DbManagerScreen> createState() => _DbManagerScreenState();
}

class _DbManagerScreenState extends State<DbManagerScreen> {
  List<Map<String, Object?>> _conns = [];
  Map<String, Object?>? _current;
  DevDb? _db;
  List<DevTable> _schema = [];
  final _query = TextEditingController();
  DevResult? _result;
  String? _error;
  bool _busy = false;
  String _filter = '';

  /// Filas que se dibujan como mucho (el CSV las lleva todas).
  static const _maxShown = 1000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db?.close();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await DevTools.connections();
    if (mounted) setState(() => _conns = rows);
  }

  Future<void> _open(Map<String, Object?> r) async {
    await _db?.close();
    setState(() {
      _busy = true;
      _db = null;
      _schema = [];
      _result = null;
      _error = null;
      _current = r;
    });
    try {
      final db = await openDevDb('${r['kind']}', DevTools.configOf(r));
      final schema = await db.schema();
      if (!mounted) return;
      setState(() {
        _db = db;
        _schema = schema;
        if (_query.text.trim().isEmpty && schema.isNotEmpty) {
          _query.text = db.sampleQuery(schema.first);
        }
      });
    } on UserError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run() async {
    final db = _db;
    final q = _query.text.trim();
    if (db == null || q.isEmpty || _busy) return;
    final kind = '${_current?['kind']}';
    final read = const {'mongodb', 'falcon', 'firebase'}.contains(kind)
        ? !RegExp(r'"(insert|update|delete)"').hasMatch(q)
        : RegExp(
            r'^\s*(select|with|pragma|explain|values|show|describe|desc)\b',
            caseSensitive: false,
          ).hasMatch(q);
    if (!read &&
        !await confirmDialog(
          context,
          tr('Modificar datos'),
          tr('Esta consulta cambia la base de datos «{0}». ¿Ejecutarla?', [
            _current?['name'],
          ]),
          ok: tr('Ejecutar'),
          danger: true,
        )) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final watch = Stopwatch()..start();
    try {
      final r = await db.run(q);
      r.elapsed = watch.elapsed;
      if (!read) _schema = await db.schema();
      if (mounted) setState(() => _result = r);
    } on UserError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _result = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _csv() async {
    final r = _result;
    if (r == null) return;
    final path = await saveBytes(
      utf8.encode(r.toCsv()),
      suggestedName: 'consulta.csv',
      typeLabel: 'CSV',
      extension: 'csv',
    );
    if (path != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Guardado en {0}', [path]))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final kind = '${_current?['kind'] ?? ''}';
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 270,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: t.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConnectionList(
                    rows: _conns,
                    selected: _current?['id'],
                    onOpen: _open,
                    onEdit: (r) async {
                      if (await _editConnection(context, row: r, ftp: false)) {
                        _load();
                      }
                    },
                    onAdd: () async {
                      if (await _editConnection(context, ftp: false)) _load();
                    },
                  ),
                  const Divider(height: 16),
                  if (_schema.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.search, size: 16),
                          hintText: tr('Filtrar tablas'),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            setState(() => _filter = v.trim().toLowerCase()),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final tb in _schema.where(
                          (x) =>
                              _filter.isEmpty ||
                              x.name.toLowerCase().contains(_filter),
                        ))
                          ExpansionTile(
                            dense: true,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: Icon(
                              tb.type == 'view'
                                  ? LucideIcons.eye
                                  : tb.type == 'collection'
                                  ? LucideIcons.folder
                                  : LucideIcons.table2,
                              size: 15,
                            ),
                            title: GestureDetector(
                              onDoubleTap: () {
                                _query.text = _db!.sampleQuery(tb);
                                _run();
                              },
                              child: Text(
                                tb.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: tr('Ver datos'),
                              icon: const Icon(LucideIcons.play, size: 14),
                              onPressed: () {
                                _query.text = _db!.sampleQuery(tb);
                                _run();
                              },
                            ),
                            children: [
                              for (final (c, type) in tb.columns)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    44,
                                    1,
                                    12,
                                    1,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: t.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ControlPanel(
                  crumbs: [
                    Crumb(
                      _current == null
                          ? tr('Bases de datos')
                          : '${_current!['name']}',
                    ),
                  ],
                  actions: [
                    FilledButton.icon(
                      onPressed: _db == null || _busy ? null : _run,
                      icon: const Icon(LucideIcons.play, size: 16),
                      label: Text(tr('Ejecutar')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _result == null || _result!.columns.isEmpty
                          ? null
                          : _csv,
                      icon: const Icon(LucideIcons.fileDown, size: 16),
                      label: Text(tr('CSV')),
                    ),
                  ],
                  trailing: [
                    if (_current != null)
                      StateBadge(_kindName(kind), AppColors.info),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(
                        LogicalKeyboardKey.enter,
                        meta: true,
                      ): _run,
                      const SingleActivator(
                        LogicalKeyboardKey.enter,
                        control: true,
                      ): _run,
                    },
                    child: TextField(
                      controller: _query,
                      minLines: 5,
                      maxLines: 10,
                      style: _mono,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(10),
                        hintText: kind == 'mongodb'
                            ? '{"collection": "clientes", "find": {"ciudad": "Madrid"}, "sort": {"nombre": 1}, "limit": 50}'
                            : kind == 'falcon'
                            ? FalconDb.example
                            : kind == 'firebase'
                            ? FirebaseDb.example
                            : _db == null
                            ? tr('Elija una conexión a la izquierda.')
                            : 'SELECT … (⌘↵ ${tr('para ejecutar')})',
                      ),
                    ),
                  ),
                ),
                Expanded(child: _results(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(ThemeData t) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _error!,
          style: const TextStyle(color: AppColors.danger),
        ),
      );
    }
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    final ms = r.elapsed.inMilliseconds;
    if (r.columns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${r.message ?? tr('Hecho')} · $ms ms',
          style: const TextStyle(color: AppColors.success),
        ),
      );
    }
    const w = 170.0;
    final rows = r.rows.take(_maxShown).toList();
    final width = r.columns.length * w + 50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Text(
            '${tr('{0} filas', [r.rows.length])} · $ms ms'
            '${r.rows.length > _maxShown ? ' · ${tr('se muestran {0}', [_maxShown])}' : ''}',
            style: TextStyle(color: t.hintColor, fontSize: 12),
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Container(
                      color: t.colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          const SizedBox(width: 50),
                          for (final c in r.columns)
                            SizedBox(
                              width: w,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                child: Text(
                                  c,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) => Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: t.dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${i + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: t.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              for (final v in rows[i])
                                SizedBox(
                                  width: w,
                                  child: Tooltip(
                                    message: v == null ? 'NULL' : '$v',
                                    waitDuration: const Duration(
                                      milliseconds: 600,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        v == null ? 'NULL' : '$v',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: v is num
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        style: _mono.copyWith(
                                          color: v == null ? t.hintColor : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================== API
Color _methodColor(BuildContext context, String m) {
  final p = biPalette(context);
  return switch (m) {
    'GET' => p[2],
    'POST' => p[3],
    'PUT' => p[0],
    'PATCH' => p[6],
    'DELETE' => p[7],
    _ => p[4],
  };
}

/// Código → API: un cliente como Postman (colecciones, historial y
/// variables de entorno).
class ApiClientScreen extends StatefulWidget {
  const ApiClientScreen({super.key});
  @override
  State<ApiClientScreen> createState() => _ApiClientScreenState();
}

class _ApiClientScreenState extends State<ApiClientScreen> {
  ApiRequest _req = ApiRequest(
    url: 'https://jsonplaceholder.typicode.com/todos/1',
  );
  int? _savedId;
  String _savedName = '', _savedCollection = '';
  final _url = TextEditingController(
    text: 'https://jsonplaceholder.typicode.com/todos/1',
  );
  final _body = TextEditingController(), _token = TextEditingController();
  final _user = TextEditingController(), _password = TextEditingController();
  ApiReply? _res;
  String? _error;
  bool _busy = false, _showHeaders = false;
  List<Map<String, Object?>> _saved = [], _history = [];
  Map<String, String> _env = {};
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_url, _body, _token, _user, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await DevTools.requests();
    final history = await DevTools.history();
    final env = await DevTools.env();
    if (mounted) {
      setState(() {
        _saved = saved;
        _history = history;
        _env = env;
      });
    }
  }

  void _sync() {
    _req
      ..url = _url.text
      ..body = _body.text
      ..token = _token.text
      ..user = _user.text
      ..password = _password.text;
  }

  void _set(ApiRequest r, {int? id, String name = '', String collection = ''}) {
    setState(() {
      _req = r;
      _savedId = id;
      _savedName = name;
      _savedCollection = collection;
      _url.text = r.url;
      _body.text = r.body;
      _token.text = r.token;
      _user.text = r.user;
      _password.text = r.password;
      _res = null;
      _error = null;
    });
  }

  Future<void> _send() async {
    _sync();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ApiClient.send(_req, _env);
      await DevTools.addHistory(
        _req.toJson(),
        status: res.status,
        ms: res.elapsed.inMilliseconds,
      );
      if (mounted) setState(() => _res = res);
    } on UserError catch (e) {
      await DevTools.addHistory(_req.toJson());
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
      _load();
    }
  }

  Future<void> _save({bool asNew = false}) async {
    _sync();
    final name = TextEditingController(
      text: _savedName.isEmpty
          ? '${_req.method} ${Uri.tryParse(_req.url)?.path ?? ''}'
          : _savedName,
    );
    final col = TextEditingController(text: _savedCollection);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Guardar petición')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(labelText: tr('Nombre')),
              ),
              TextField(
                controller: col,
                decoration: InputDecoration(
                  labelText: tr('Colección'),
                  hintText: tr('p. ej. Mi API'),
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
            child: Text(tr('Guardar')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = await runAction(
      context,
      () => DevTools.saveRequest(
        asNew ? null : _savedId,
        collection: col.text,
        name: name.text,
        request: _req.toJson(),
      ),
    );
    if (id != null) {
      setState(() {
        _savedId = id;
        _savedName = name.text.trim();
        _savedCollection = col.text.trim();
      });
    }
    _load();
  }

  Future<void> _editEnv() async {
    final c = TextEditingController(
      text: [for (final e in _env.entries) '${e.key}=${e.value}'].join('\n'),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Variables de entorno')),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  'Una por línea: nombre=valor. Úselas como {{nombre}} en la dirección, los parámetros, las cabeceras, el cuerpo o la autorización.',
                ),
                style: TextStyle(color: Theme.of(d).hintColor, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c,
                maxLines: 10,
                minLines: 6,
                style: _mono,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: tr('base_url=https://api.miempresa.com\ntoken=…'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(tr('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(tr('Guardar')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DevTools.setEnv({
      for (final line in c.text.split('\n'))
        if (line.contains('='))
          line.substring(0, line.indexOf('=')).trim(): line
              .substring(line.indexOf('=') + 1)
              .trim(),
    });
    _load();
  }

  Future<void> _menu(String v) async {
    switch (v) {
      case 'new':
        _set(ApiRequest());
      case 'saveas':
        await _save(asNew: true);
      case 'curl':
        _sync();
        try {
          await Clipboard.setData(
            ClipboardData(text: ApiClient.curl(_req, _env)),
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(tr('Orden curl copiada'))));
          }
        } on UserError catch (e) {
          if (mounted) await showErrorDialog(context, e.message);
        }
      case 'env':
        await _editEnv();
      case 'clear':
        await DevTools.clearHistory();
        _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 270, child: _sidebar(t)),
          VerticalDivider(width: 1, color: t.dividerColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _savedName.isEmpty
                              ? tr('Petición nueva')
                              : '${_savedCollection.isEmpty ? '' : '$_savedCollection / '}$_savedName',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _editEnv,
                        icon: const Icon(LucideIcons.braces, size: 16),
                        label: Text(tr('Variables ({0})', [_env.length])),
                      ),
                      OutlinedButton.icon(
                        onPressed: _save,
                        icon: const Icon(LucideIcons.save, size: 16),
                        label: Text(tr('Guardar')),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          LucideIcons.ellipsisVertical,
                          size: 18,
                        ),
                        onSelected: _menu,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'new',
                            child: Text(tr('Petición nueva')),
                          ),
                          PopupMenuItem(
                            value: 'saveas',
                            child: Text(tr('Guardar como nueva…')),
                          ),
                          PopupMenuItem(
                            value: 'curl',
                            child: Text(tr('Copiar como curl')),
                          ),
                          PopupMenuItem(
                            value: 'env',
                            child: Text(tr('Variables de entorno…')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          initialValue: _req.method,
                          isExpanded: true,
                          items: [
                            for (final m in ApiRequest.methods)
                              DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    color: _methodColor(context, m),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _req.method = v ?? _req.method),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.enter):
                                _send,
                          },
                          child: TextField(
                            controller: _url,
                            style: _mono.copyWith(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: tr('https://… o {{base_url}}/ruta'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _busy ? null : _send,
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: Text(tr('Enviar')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(flex: 5, child: _requestTabs(t)),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                Divider(height: 1, color: t.dividerColor),
                Expanded(flex: 6, child: _response(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar(ThemeData t) {
    final groups = <String, List<Map<String, Object?>>>{};
    for (final r in _saved) {
      groups.putIfAbsent('${r['collection'] ?? ''}', () => []).add(r);
    }
    Widget method(String m) => SizedBox(
      width: 52,
      child: Text(
        m,
        style: TextStyle(
          color: _methodColor(context, m),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: tr('Colecciones')),
              Tab(text: tr('Historial')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _saved.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            tr('Guarde peticiones para tenerlas a mano.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.hintColor),
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final e in groups.entries)
                            ExpansionTile(
                              initiallyExpanded: true,
                              dense: true,
                              leading: const Icon(LucideIcons.folder, size: 16),
                              title: Text(
                                e.key.isEmpty ? tr('Sin colección') : e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                for (final r in e.value)
                                  ListTile(
                                    dense: true,
                                    selected: r['id'] == _savedId,
                                    leading: method(
                                      '${(jsonDecode('${r['request']}') as Map)['method']}',
                                    ),
                                    title: Text(
                                      '${r['name']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      tooltip: tr('Eliminar'),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 14,
                                      ),
                                      onPressed: () async {
                                        await DevTools.deleteRequest(
                                          r['id'] as int,
                                        );
                                        if (_savedId == r['id']) {
                                          _savedId = null;
                                        }
                                        _load();
                                      },
                                    ),
                                    onTap: () => _set(
                                      ApiRequest.fromJson(
                                        jsonDecode('${r['request']}') as Map,
                                      ),
                                      id: r['id'] as int,
                                      name: '${r['name']}',
                                      collection: '${r['collection'] ?? ''}',
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final h in _history)
                            ListTile(
                              dense: true,
                              leading: method('${h['method']}'),
                              title: Text(
                                '${h['url']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              subtitle: Text(
                                '${h['status'] ?? tr('Error')} · ${h['ms'] ?? '-'} ms · ${Fmt.dateTime(h['date'])}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (h['status'] as int? ?? 999) < 400
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              onTap: () => _set(
                                ApiRequest.fromJson(
                                  jsonDecode('${h['request']}') as Map,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_history.isNotEmpty)
                      TextButton(
                        onPressed: () => _menu('clear'),
                        child: Text(tr('Borrar historial')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(List<KeyValue> list, {String keyHint = 'clave'}) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    children: [
      for (final kv in list)
        Row(
          key: ObjectKey(kv),
          children: [
            Checkbox(
              value: kv.enabled,
              onChanged: (v) => setState(() => kv.enabled = v ?? true),
            ),
            Expanded(
              child: TextFormField(
                initialValue: kv.key,
                style: _mono,
                decoration: InputDecoration(hintText: keyHint, isDense: true),
                onChanged: (v) => kv.key = v,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: kv.value,
                style: _mono,
                decoration: InputDecoration(
                  hintText: tr('valor'),
                  isDense: true,
                ),
                onChanged: (v) => kv.value = v,
              ),
            ),
            IconButton(
              tooltip: tr('Quitar'),
              icon: const Icon(LucideIcons.x, size: 14),
              onPressed: () => setState(() => list.remove(kv)),
            ),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => list.add(KeyValue('', ''))),
          icon: const Icon(LucideIcons.plus, size: 14),
          label: Text(tr('Añadir')),
        ),
      ),
    ],
  );

  Widget _requestTabs(ThemeData t) {
    final labels = [
      '${tr('Parámetros')}${_req.params.isEmpty ? '' : ' (${_req.params.length})'}',
      '${tr('Cabeceras')}${_req.headers.isEmpty ? '' : ' (${_req.headers.length})'}',
      tr('Cuerpo'),
      tr('Autorización'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i]),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: switch (_tab) {
            0 => _kv(_req.params, keyHint: tr('parámetro')),
            1 => _kv(_req.headers, keyHint: 'Content-Type'),
            2 => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'none', label: Text(tr('Ninguno'))),
                      const ButtonSegment(value: 'json', label: Text('JSON')),
                      ButtonSegment(value: 'text', label: Text(tr('Texto'))),
                      ButtonSegment(
                        value: 'form',
                        label: Text(tr('Formulario')),
                      ),
                    ],
                    selected: {_req.bodyType},
                    onSelectionChanged: (v) =>
                        setState(() => _req.bodyType = v.first),
                  ),
                  const SizedBox(height: 8),
                  if (_req.bodyType != 'none')
                    Expanded(
                      child: TextField(
                        controller: _body,
                        expands: true,
                        maxLines: null,
                        style: _mono,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.all(10),
                          hintText: _req.bodyType == 'form'
                              ? 'nombre=Ana\nemail=ana@x.com'
                              : '{\n  "nombre": "Ana"\n}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _ => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'none', label: Text(tr('Ninguna'))),
                      const ButtonSegment(
                        value: 'bearer',
                        label: Text('Bearer'),
                      ),
                      const ButtonSegment(value: 'basic', label: Text('Basic')),
                    ],
                    selected: {_req.authType},
                    onSelectionChanged: (v) =>
                        setState(() => _req.authType = v.first),
                  ),
                  if (_req.authType == 'bearer')
                    TextField(
                      controller: _token,
                      style: _mono,
                      decoration: InputDecoration(
                        labelText: tr('Token'),
                        hintText: '{{token}}',
                      ),
                    ),
                  if (_req.authType == 'basic') ...[
                    TextField(
                      controller: _user,
                      decoration: InputDecoration(labelText: tr('Usuario')),
                    ),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(labelText: tr('Contraseña')),
                    ),
                  ],
                ],
              ),
            ),
          },
        ),
      ],
    );
  }

  Widget _response(ThemeData t) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _error!,
          style: const TextStyle(color: AppColors.danger),
        ),
      );
    }
    final r = _res;
    if (r == null) {
      return Center(
        child: Text(
          tr('Pulse «Enviar» para ver la respuesta.'),
          style: TextStyle(color: t.hintColor),
        ),
      );
    }
    final okColor = r.status < 300
        ? AppColors.success
        : (r.status < 400 ? AppColors.warning : AppColors.danger);
    final size = r.bytes.length < 1024
        ? '${r.bytes.length} B'
        : '${(r.bytes.length / 1024).toStringAsFixed(1)} KB';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
          child: Row(
            children: [
              StateBadge('${r.status} ${r.reason}', okColor),
              const SizedBox(width: 12),
              Text(
                '${r.elapsed.inMilliseconds} ms · $size',
                style: TextStyle(color: t.hintColor, fontSize: 12.5),
              ),
              const Spacer(),
              ChoiceChip(
                label: Text(tr('Cuerpo')),
                selected: !_showHeaders,
                onSelected: (_) => setState(() => _showHeaders = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(tr('Cabeceras ({0})', [r.headers.length])),
                selected: _showHeaders,
                onSelected: (_) => setState(() => _showHeaders = true),
              ),
              IconButton(
                tooltip: tr('Copiar'),
                icon: const Icon(LucideIcons.copy, size: 16),
                onPressed: () => Clipboard.setData(
                  ClipboardData(
                    text: _showHeaders
                        ? r.headers.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n')
                        : r.pretty,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainerHighest.withValues(
                alpha: .5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _showHeaders
                    ? r.headers.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n')
                    : r.pretty,
                style: _mono,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================== FTP
/// Código → FTP: explorar, subir, descargar, renombrar y borrar.
class FtpScreen extends StatefulWidget {
  const FtpScreen({super.key});
  @override
  State<FtpScreen> createState() => _FtpScreenState();
}

class _FtpScreenState extends State<FtpScreen> {
  List<Map<String, Object?>> _conns = [];
  Map<String, Object?>? _current;
  DevFtp? _ftp;
  String _pwd = '';
  List<DevFtpEntry> _entries = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ftp?.close();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await DevTools.connections(ftp: true);
    if (mounted) setState(() => _conns = rows);
  }

  Future<void> _task(Future<void> Function(DevFtp f) task) async {
    final f = _ftp;
    if (f == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task(f);
      final pwd = await f.pwd();
      final entries = await f.list();
      if (mounted) {
        setState(() {
          _pwd = pwd;
          _entries = entries;
        });
      }
    } on UserError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, Object?> r) async {
    await _ftp?.close();
    setState(() {
      _ftp = null;
      _current = r;
      _entries = [];
      _pwd = '';
      _busy = true;
      _error = null;
    });
    try {
      _ftp = await openDevFtp(DevTools.configOf(r));
    } on UserError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
      return;
    }
    await _task((_) async {});
  }

  Future<void> _upload() async {
    final files = await openFiles();
    if (files.isEmpty) return;
    await _task((f) async {
      for (final x in files) {
        await f.upload(x.path, remoteName: x.name);
      }
    });
  }

  Future<void> _download(DevFtpEntry e) async {
    final loc = await getSaveLocation(suggestedName: e.name);
    if (loc == null) return;
    await _task((f) => f.download(e.name, loc.path));
    if (mounted && _error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Guardado en {0}', [loc.path]))),
      );
    }
  }

  Future<void> _entryMenu(DevFtpEntry e, String v) async {
    switch (v) {
      case 'download':
        await _download(e);
      case 'rename':
        final name = await promptText(context, tr('Nuevo nombre'), e.name);
        if (name == null || name.trim().isEmpty || name == e.name) return;
        await _task((f) => f.rename(e.name, name.trim()));
      case 'delete':
        if (await confirmDialog(
          context,
          tr('Eliminar'),
          e.dir
              ? tr('¿Eliminar la carpeta «{0}» y su contenido?', [e.name])
              : tr('¿Eliminar «{0}»?', [e.name]),
          ok: tr('Eliminar'),
          danger: true,
        )) {
          await _task((f) => f.delete(e));
        }
    }
  }

  String _size(int? b) => b == null
      ? ''
      : b < 1024
      ? '$b B'
      : b < 1024 * 1024
      ? '${(b / 1024).toStringAsFixed(1)} KB'
      : '${(b / 1024 / 1024).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final connected = _ftp != null;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: t.dividerColor)),
              ),
              child: _ConnectionList(
                rows: _conns,
                selected: _current?['id'],
                onOpen: _open,
                onEdit: (r) async {
                  if (await _editConnection(context, row: r, ftp: true)) {
                    _load();
                  }
                },
                onAdd: () async {
                  if (await _editConnection(context, ftp: true)) _load();
                },
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ControlPanel(
                  crumbs: [
                    Crumb(
                      _current == null ? tr('FTP') : '${_current!['name']}',
                    ),
                  ],
                  actions: [
                    IconButton(
                      tooltip: tr('Carpeta superior'),
                      icon: const Icon(LucideIcons.arrowUp, size: 18),
                      onPressed: connected && !_busy
                          ? () => _task((f) => f.cd('..'))
                          : null,
                    ),
                    IconButton(
                      tooltip: tr('Actualizar'),
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: connected && !_busy
                          ? () => _task((_) async {})
                          : null,
                    ),
                    FilledButton.icon(
                      onPressed: connected && !_busy ? _upload : null,
                      icon: const Icon(LucideIcons.upload, size: 16),
                      label: Text(tr('Subir archivos')),
                    ),
                    OutlinedButton.icon(
                      onPressed: connected && !_busy
                          ? () async {
                              final name = await promptText(
                                context,
                                tr('Nueva carpeta'),
                                '',
                              );
                              if (name == null || name.trim().isEmpty) return;
                              await _task((f) => f.mkdir(name.trim()));
                            }
                          : null,
                      icon: const Icon(LucideIcons.folderPlus, size: 16),
                      label: Text(tr('Nueva carpeta')),
                    ),
                  ],
                  trailing: [
                    if (_pwd.isNotEmpty)
                      Text(_pwd, style: _mono.copyWith(color: t.hintColor)),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                Expanded(
                  child: !connected
                      ? Center(
                          child: Text(
                            _conns.isEmpty
                                ? tr('Añada un servidor FTP con «+».')
                                : tr('Elija un servidor a la izquierda.'),
                            style: TextStyle(color: t.hintColor),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final e in _entries)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  e.dir ? LucideIcons.folder : LucideIcons.file,
                                  size: 18,
                                  color: e.dir
                                      ? const Color(0xFFE0A100)
                                      : t.hintColor,
                                ),
                                title: Text(e.name),
                                subtitle: Text(
                                  [
                                    if (!e.dir) _size(e.size),
                                    if (e.modified != null)
                                      DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(e.modified!),
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: e.dir
                                    ? () => _task((f) => f.cd(e.name))
                                    : () => _download(e),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    LucideIcons.ellipsisVertical,
                                    size: 16,
                                  ),
                                  onSelected: (v) => _entryMenu(e, v),
                                  itemBuilder: (_) => [
                                    if (!e.dir)
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Text(tr('Descargar')),
                                      ),
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
                              ),
                            if (_entries.isEmpty && !_busy)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  tr('Carpeta vacía.'),
                                  style: TextStyle(color: t.hintColor),
                                ),
                              ),
                          ],
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

/// Etiqueta de color con un estado (tipo de conexión, código HTTP…).
class StateBadge extends StatelessWidget {
  const StateBadge(this.label, this.color, {super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .5)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(color, Colors.white, .35)
            : Color.lerp(color, Colors.black, .25),
      ),
    ),
  );
}
