import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'dev_types.dart';

/// Bases de datos en la nube por su API REST: FalconDatabase (tablas de
/// PostgreSQL) y Firebase (Cloud Firestore). Las consultas son un JSON,
/// como en MongoDB.

Map<String, Object?> _spec(String query, String example) {
  try {
    final j = jsonDecode(query);
    if (j is Map) return j.cast<String, Object?>();
  } on FormatException {
    // Abajo.
  }
  throw UserError(tr('La consulta es un JSON: {0}', [example]));
}

String _need(Map<String, Object?> c, String k, String label) {
  final v = '${c[k] ?? ''}'.trim();
  if (v.isEmpty) throw UserError(tr('Falta «{0}».', [label]));
  return v;
}

Never _httpError(http.Response r) {
  var msg = r.body;
  try {
    final j = jsonDecode(r.body);
    if (j is Map) {
      final e = j['error'];
      msg = e is Map ? '${e['message'] ?? e}' : '${e ?? j['message'] ?? j}';
    }
  } on FormatException {
    // El cuerpo tal cual.
  }
  throw UserError('HTTP ${r.statusCode}: $msg');
}

// ---------------------------------------------------------- FalconDatabase

/// FalconDatabase (https://falcondatabase.com/docs/): `/api/v1/REF/tables/…`
/// con la cabecera apikey (y Authorization si se inicia sesión).
class FalconDb extends DevDb {
  FalconDb._(this._base, this._headers, this._client);

  final String _base;
  final Map<String, String> _headers;
  final http.Client _client;

  static const example =
      '{"table": "productos", "where": {"precio": "gte.10"}, "order": "id.desc", "limit": 100}';

  /// [c]: url (por defecto https://falcondatabase.com), project (la
  /// referencia), key (anon o service) y, si las tablas lo piden, email y
  /// password.
  static Future<FalconDb> open(
    Map<String, Object?> c, {
    http.Client? client,
  }) async {
    final url = '${c['url'] ?? ''}'.trim().isEmpty
        ? 'https://falcondatabase.com'
        : '${c['url']}'.trim().replaceAll(RegExp(r'/+$'), '');
    final ref = _need(c, 'project', tr('Proyecto'));
    final key = _need(c, 'key', tr('Clave de API'));
    final http.Client cl = client ?? http.Client();
    final base = '$url/api/v1/$ref';
    final headers = {'apikey': key, 'Content-Type': 'application/json'};
    final email = '${c['email'] ?? ''}'.trim();
    if (email.isNotEmpty) {
      final r = await cl.post(
        Uri.parse('$base/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': '${c['password'] ?? ''}',
        }),
      );
      if (r.statusCode >= 400) _httpError(r);
      final token = (jsonDecode(r.body) as Map)['token'];
      if (token is String) headers['Authorization'] = 'Bearer $token';
    }
    final db = FalconDb._(base, headers, cl);
    await db.schema(); // Comprueba la conexión y la clave.
    return db;
  }

  Future<Object?> _call(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$_base$path');
    final r = await switch (method) {
      'POST' => _client.post(uri, headers: _headers, body: jsonEncode(body)),
      'PATCH' => _client.patch(uri, headers: _headers, body: jsonEncode(body)),
      'DELETE' => _client.delete(uri, headers: _headers),
      _ => _client.get(uri, headers: _headers),
    };
    if (r.statusCode >= 400) _httpError(r);
    return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
  }

  @override
  Future<List<DevTable>> schema() async {
    final j = await _call('GET', '');
    final tables = j is Map && j['tables'] is List ? j['tables'] as List : [];
    return [
      for (final t in tables.whereType<Map>())
        DevTable(
          '${t['name']}',
          type: 'table',
          columns: [
            for (final c in (t['columns'] as List? ?? []).whereType<Map>())
              ('${c['name']}', '${c['type']}'),
          ],
        ),
    ];
  }

  static final _op = RegExp(r'^(eq|neq|gt|gte|lt|lte|like|ilike|is|in)\.');

  @override
  Future<DevResult> run(String query) async {
    final s = _spec(query, example);
    final table = '${s['table'] ?? s['collection'] ?? ''}'.trim();
    if (table.isEmpty) throw UserError(tr('Indique la tabla («table»).'));
    final path = '/tables/${Uri.encodeComponent(table)}';
    List<Map<String, Object?>> rows(Object? data) => [
      for (final r in data is List ? data : [data])
        if (r is Map) r.cast<String, Object?>(),
    ];
    if (s['insert'] != null) {
      final j = await _call('POST', path, s['insert']);
      final out = rows(j is Map ? j['data'] : j);
      return DevResult.fromMaps(
        out,
      )._with(affectedMessage(out.length), out.length);
    }
    if (s['update'] is Map) {
      final u = (s['update'] as Map).cast<String, Object?>();
      final set = u['set'];
      if ((u['id'] == null && u['where'] is! Map) || set is! Map) {
        throw UserError(
          tr('«update» es {"id": 1, "set": {…}} o {"where": {…}, "set": {…}}.'),
        );
      }
      // Con «where»: cada fila que cumple el filtro.
      final ids = u['id'] != null
          ? [u['id']]
          : await _ids(path, u['where'] as Map);
      final out = <Map<String, Object?>>[];
      for (final id in ids) {
        final j = await _call('PATCH', '$path/$id', set);
        out.addAll(rows(j is Map ? j['data'] : j));
      }
      return DevResult.fromMaps(
        out,
      )._with(affectedMessage(ids.length), ids.length);
    }
    if (s['delete'] != null) {
      final d = s['delete'];
      final ids = d is Map && d['where'] is Map
          ? await _ids(path, d['where'] as Map)
          : [d];
      for (final id in ids) {
        await _call('DELETE', '$path/$id');
      }
      return DevResult(
        affected: ids.length,
        message: affectedMessage(ids.length),
      );
    }
    final q = <String, String>{
      if (s['where'] is Map) ..._filters(s['where'] as Map),
      for (final k in ['order', 'limit', 'offset', 'select'])
        if (s[k] != null) k: '${s[k]}',
    };
    q.putIfAbsent('limit', () => '100');
    final j = await _call('GET', '$path?${Uri(queryParameters: q).query}');
    final out = DevResult.fromMaps(rows(j is Map ? j['data'] : j));
    final count = j is Map ? j['count'] : null;
    return count == null
        ? out
        : out._with(
            count == 1
                ? tr('1 fila en total')
                : tr('{0} filas en total', [count]),
            null,
          );
  }

  /// Los filtros de «where»: columna → «op.valor» (sin operador, eq).
  static Map<String, String> _filters(Map where) => {
    for (final MapEntry(:key, :value) in where.entries)
      '$key': value is String && _op.hasMatch(value)
          ? value
          : 'eq.${value is String ? value : jsonEncode(value)}',
  };

  /// Los id de las filas de [path] que cumplen [where].
  Future<List<Object?>> _ids(String path, Map where) async {
    final ids = <Object?>[];
    while (true) {
      final q = {
        ..._filters(where),
        'select': 'id',
        'order': 'id',
        'limit': '1000',
        'offset': '${ids.length}',
      };
      final j = await _call('GET', '$path?${Uri(queryParameters: q).query}');
      final data = j is Map ? j['data'] : j;
      final page = [
        for (final r in data is List ? data : const [])
          if (r is Map) r['id'],
      ];
      ids.addAll(page);
      if (page.length < 1000) return ids;
    }
  }

  @override
  String sampleQuery(DevTable t) => '{"table": "${t.name}", "limit": 100}';

  @override
  Future<void> close() async => _client.close();
}

// ------------------------------------------------------------- Firebase

/// Cloud Firestore por REST: colecciones y documentos. Con la clave web y,
/// si las reglas lo piden, un usuario de Firebase Authentication (correo y
/// contraseña). Con «emulator» (host:puerto) usa el emulador local.
class FirebaseDb extends DevDb {
  FirebaseDb._(this._base, this._key, this._token, this._client);

  final String _base;
  final String? _key;
  final String? _token;
  final http.Client _client;

  static const example =
      '{"collection": "productos", "where": {"precio": {"gte": 10}}, "order": "precio desc", "limit": 100}';

  static Future<FirebaseDb> open(
    Map<String, Object?> c, {
    http.Client? client,
  }) async {
    final project = _need(c, 'project', tr('Proyecto'));
    final key = '${c['key'] ?? ''}'.trim();
    final emulator = '${c['emulator'] ?? ''}'.trim();
    final database = '${c['database'] ?? ''}'.trim().isEmpty
        ? '(default)'
        : '${c['database']}'.trim();
    final http.Client cl = client ?? http.Client();
    final host = emulator.isEmpty
        ? 'https://firestore.googleapis.com'
        : (emulator.startsWith('http') ? emulator : 'http://$emulator');
    final base = '$host/v1/projects/$project/databases/$database/documents';
    String? token;
    final email = '${c['email'] ?? ''}'.trim();
    if (emulator.isNotEmpty) {
      token = 'owner'; // El emulador: sin reglas.
    } else if (email.isNotEmpty) {
      if (key.isEmpty) throw UserError(tr('Falta «{0}».', [tr('Clave web')]));
      final r = await cl.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': '${c['password'] ?? ''}',
          'returnSecureToken': true,
        }),
      );
      if (r.statusCode >= 400) _httpError(r);
      token = '${(jsonDecode(r.body) as Map)['idToken']}';
    }
    final db = FirebaseDb._(base, key.isEmpty ? null : key, token, cl);
    await db._collections(); // Comprueba la conexión.
    return db;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String path, [Map<String, Object>? q]) {
    final u = Uri.parse('$_base$path');
    final all = <String, Object>{
      ...u.queryParametersAll,
      ...?q,
      if (_key != null && _token == null) 'key': _key,
    };
    return u.replace(queryParameters: all.isEmpty ? null : all);
  }

  Future<Object?> _call(
    String method,
    String path, {
    Object? body,
    Map<String, Object>? q,
  }) async {
    final uri = _uri(path, q);
    final r = await switch (method) {
      'POST' => _client.post(uri, headers: _headers, body: jsonEncode(body)),
      'PATCH' => _client.patch(uri, headers: _headers, body: jsonEncode(body)),
      'DELETE' => _client.delete(uri, headers: _headers),
      _ => _client.get(uri, headers: _headers),
    };
    if (r.statusCode >= 400) _httpError(r);
    return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<List<String>> _collections() async {
    final j = await _call('POST', ':listCollectionIds', body: const {});
    final ids = j is Map ? j['collectionIds'] : null;
    return [for (final i in ids is List ? ids : const []) '$i']..sort();
  }

  /// Un valor de Dart como valor de Firestore.
  static Map<String, Object?> encode(Object? v) => switch (v) {
    null => {'nullValue': null},
    final bool b => {'booleanValue': b},
    final int i => {'integerValue': '$i'},
    final double d => {'doubleValue': d},
    final List l => {
      'arrayValue': {'values': l.map(encode).toList()},
    },
    final Map m => {
      'mapValue': {'fields': fields(m.cast<String, Object?>())},
    },
    _ => {'stringValue': '$v'},
  };

  /// «hours.close»: el subcampo dentro de su mapa ({"hours": {"close": …}}),
  /// para que la máscara «hours.close» cambie solo ese subcampo.
  static Map<String, Object?> nest(Map<String, Object?> m) {
    final out = <String, Object?>{};
    for (final MapEntry(:key, :value) in m.entries) {
      final parts = key.split('.');
      var node = out;
      for (final part in parts.take(parts.length - 1)) {
        final next = node[part];
        if (next is Map<String, Object?>) {
          node = next;
        } else {
          final child = <String, Object?>{};
          node[part] = child;
          node = child;
        }
      }
      node[parts.last] = value;
    }
    return out;
  }

  static Map<String, Object?> fields(Map<String, Object?> m) => {
    for (final e in m.entries) e.key: encode(e.value),
  };

  /// Un valor de Firestore como valor de Dart.
  static Object? decode(Object? v) {
    if (v is! Map) return v;
    final (k, x) = (v.keys.first as String, v.values.first);
    return switch (k) {
      'nullValue' => null,
      'integerValue' => int.tryParse('$x') ?? x,
      'doubleValue' => (x as num).toDouble(),
      'arrayValue' => [
        for (final i in (x is Map ? x['values'] as List? : null) ?? const [])
          decode(i),
      ],
      'mapValue' => {
        for (final e
            in ((x is Map ? x['fields'] as Map? : null) ?? const {}).entries)
          '${e.key}': decode(e.value),
      },
      'geoPointValue' => '${(x as Map)['latitude']}, ${x['longitude']}',
      _ => x,
    };
  }

  /// Un documento como fila: _id y sus campos.
  static Map<String, Object?> row(Map doc) => {
    '_id': '${doc['name']}'.split('/').last,
    for (final e in ((doc['fields'] as Map?) ?? const {}).entries)
      '${e.key}': decode(e.value),
  };

  @override
  Future<List<DevTable>> schema() async => [
    for (final c in await _collections())
      DevTable(
        c,
        type: 'collection',
        columns: [
          // Campos del primer documento (Firestore no tiene esquema fijo).
          for (final e in await () async {
            final j = await _call('GET', '/$c', q: {'pageSize': '1'});
            final docs = j is Map ? j['documents'] as List? : null;
            final first = docs == null || docs.isEmpty ? null : docs.first;
            return first is Map
                ? ((first['fields'] as Map?) ?? const {}).entries
                : const <MapEntry>[];
          }())
            (
              '${e.key}',
              '${(e.value as Map).keys.first}'.replaceAll('Value', ''),
            ),
        ],
      ),
  ];

  static const _ops = {
    'eq': 'EQUAL',
    'neq': 'NOT_EQUAL',
    'gt': 'GREATER_THAN',
    'gte': 'GREATER_THAN_OR_EQUAL',
    'lt': 'LESS_THAN',
    'lte': 'LESS_THAN_OR_EQUAL',
    'in': 'IN',
    'nin': 'NOT_IN',
    'contains': 'ARRAY_CONTAINS',
    'containsAny': 'ARRAY_CONTAINS_ANY',
  };

  @override
  Future<DevResult> run(String query) async {
    final s = _spec(query, example);
    final col = '${s['collection'] ?? s['table'] ?? ''}'.trim();
    if (col.isEmpty) {
      throw UserError(tr('Indique la colección («collection»).'));
    }
    if (s['insert'] != null) {
      final docs = s['insert'] is List ? s['insert'] as List : [s['insert']];
      final out = <Map<String, Object?>>[];
      for (final d in docs.whereType<Map>()) {
        final m = d.cast<String, Object?>();
        final id = m.remove('_id');
        final j = await _call(
          'POST',
          '/$col',
          body: {'fields': fields(m)},
          q: id == null ? null : {'documentId': '$id'},
        );
        if (j is Map) out.add(row(j));
      }
      return DevResult.fromMaps(
        out,
      )._with(affectedMessage(out.length), out.length);
    }
    if (s['update'] is Map) {
      final u = (s['update'] as Map).cast<String, Object?>();
      final id = u['id'] ?? u['_id'];
      final set = u['set'];
      if ((id == null && u['where'] is! Map) || set is! Map) {
        throw UserError(
          tr(
            '«update» es {"id": "…", "set": {…}} o {"where": {…}, "set": {…}}.',
          ),
        );
      }
      final m = set.cast<String, Object?>();
      // Con «where»: cada documento que cumple el filtro.
      final paths = id != null
          ? ['/$col/$id']
          : await _paths(col, {...s, 'where': u['where']});
      final out = <Map<String, Object?>>[];
      for (final path in paths) {
        final j = await _call(
          'PATCH',
          path,
          body: {'fields': fields(nest(m))},
          q: {
            'updateMask.fieldPaths': m.keys.toList(),
            'currentDocument.exists': 'true',
          },
        );
        if (j is Map) out.add(row(j));
      }
      return DevResult.fromMaps(
        out,
      )._with(affectedMessage(paths.length), paths.length);
    }
    if (s['delete'] != null) {
      final d = s['delete'];
      final paths = d is Map && d['where'] is Map
          ? await _paths(col, {...s, 'where': d['where']})
          : ['/$col/$d'];
      for (final path in paths) {
        await _call('DELETE', path);
      }
      return DevResult(
        affected: paths.length,
        message: affectedMessage(paths.length),
      );
    }
    if (s['id'] != null) {
      final j = await _call('GET', '/$col/${s['id']}');
      return DevResult.fromMaps([if (j is Map) row(j)]);
    }
    final (parent, sq) = _query(col, s);
    // count, sum y avg: una fila con el resultado.
    final aggs = [
      if (s['count'] == true) {'alias': 'count', 'count': <String, Object?>{}},
      for (final k in const ['sum', 'avg'])
        if (s[k] is String)
          {
            'alias': '${k}_${s[k]}',
            k: {
              'field': {'fieldPath': s[k]},
            },
          },
    ];
    if (aggs.isNotEmpty) {
      sq.remove('limit');
      final j = await _call(
        'POST',
        '$parent:runAggregationQuery',
        body: {
          'structuredAggregationQuery': {
            'structuredQuery': sq,
            'aggregations': aggs,
          },
        },
      );
      final first = j is List && j.isNotEmpty ? j.first : null;
      final f = first is Map && first['result'] is Map
          ? (first['result'] as Map)['aggregateFields'] as Map?
          : null;
      return DevResult.fromMaps([
        {
          for (final a in aggs)
            '${a['alias']}': decode(f?[a['alias']] ?? {'nullValue': null}),
        },
      ]);
    }
    final j = await _call(
      'POST',
      '$parent:runQuery',
      body: {'structuredQuery': sq},
    );
    return DevResult.fromMaps([
      for (final r in j is List ? j : const [])
        if (r is Map && r['document'] is Map) row(r['document'] as Map),
    ]);
  }

  /// La consulta de [s] sobre [col] («pedidos» o la subcolección
  /// «pedidos/p1/lineas»): (ruta del padre, structuredQuery).
  (String, Map<String, Object?>) _query(String col, Map<String, Object?> s) {
    final slash = col.lastIndexOf('/');
    final parent = slash < 0 ? '' : '/${col.substring(0, slash)}';
    final id = slash < 0 ? col : col.substring(slash + 1);
    final where = s['where'] is Map ? s['where'] as Map : const {};
    final filters = <Map<String, Object?>>[];
    for (final MapEntry(:key, :value) in where.entries) {
      final conds = value is Map ? value : {'eq': value};
      for (final MapEntry(key: op, value: v) in conds.entries) {
        // null: IS_NULL / IS_NOT_NULL (un campo que falta no es null).
        if (v == null && (op == 'eq' || op == 'neq')) {
          filters.add({
            'unaryFilter': {
              'field': {'fieldPath': '$key'},
              'op': op == 'eq' ? 'IS_NULL' : 'IS_NOT_NULL',
            },
          });
          continue;
        }
        final fop = _ops['$op'];
        if (fop == null) throw UserError(tr('Operador no válido: {0}', [op]));
        filters.add({
          'fieldFilter': {
            'field': {'fieldPath': '$key'},
            'op': fop,
            'value': encode(v),
          },
        });
      }
    }
    // «precio desc, nombre»: varios campos.
    final order = [
      for (final p in '${s['order'] ?? ''}'.split(','))
        if (p.trim().isNotEmpty) p.trim().split(RegExp(r'\s+')),
    ];
    final select = s['select'];
    final sq = <String, Object?>{
      'from': [
        {'collectionId': id, if (s['group'] == true) 'allDescendants': true},
      ],
      if (filters.length == 1) 'where': filters.single,
      if (filters.length > 1)
        'where': {
          'compositeFilter': {'op': 'AND', 'filters': filters},
        },
      if (order.isNotEmpty)
        'orderBy': [
          for (final o in order)
            {
              'field': {'fieldPath': o.first},
              'direction': o.length > 1 && o[1].toLowerCase() == 'desc'
                  ? 'DESCENDING'
                  : 'ASCENDING',
            },
        ],
      if (select != null)
        'select': {
          'fields': [
            for (final f in select is List ? select : '$select'.split(','))
              if ('$f'.trim().isNotEmpty) {'fieldPath': '$f'.trim()},
          ],
        },
      if (s['offset'] is num) 'offset': (s['offset'] as num).toInt(),
      'limit': (s['limit'] as num?)?.toInt() ?? 100,
    };
    // Consulta de grupo: desde la raíz, en todas las subcolecciones con ese
    // nombre.
    return (s['group'] == true ? '' : parent, sq);
  }

  /// Las rutas (/colección/id) de los documentos que cumplen la consulta.
  Future<List<String>> _paths(String col, Map<String, Object?> s) async {
    final (parent, sq) = _query(col, {...s, 'limit': 10000});
    sq.remove('select');
    final j = await _call(
      'POST',
      '$parent:runQuery',
      body: {'structuredQuery': sq},
    );
    return [
      for (final r in j is List ? j : const [])
        if (r is Map && r['document'] is Map)
          '${(r['document'] as Map)['name']}'
              .split('/documents')
              .skip(1)
              .join('/documents'),
    ];
  }

  @override
  String sampleQuery(DevTable t) => '{"collection": "${t.name}", "limit": 100}';

  @override
  Future<void> close() async => _client.close();
}

extension on DevResult {
  DevResult _with(String message, int? affected) => DevResult(
    columns: columns,
    rows: rows,
    affected: affected,
    message: message,
  );
}
