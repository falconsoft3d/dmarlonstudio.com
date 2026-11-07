import 'dart:convert';

/// La base de datos de una app de Flutter: lib/db.dart, un cliente de
/// FalconDatabase o de Firebase (Cloud Firestore y Authentication) por su
/// API REST, con la misma forma en los dos:
///
/// ```dart
/// final user = await db.signIn(email, clave);
/// final filas = await db.table('productos').list(order: 'precio');
/// await db.table('productos').insert({'nombre': 'Pan', 'precio': 1.2});
/// ```
class FlBackend {
  const FlBackend({
    this.kind = '',
    this.url = '',
    this.project = '',
    this.key = '',
  });

  /// falcon, firebase o '' (ninguna).
  final String kind;

  /// FalconDatabase: el servidor (por defecto https://falcondatabase.com).
  /// Firebase: el emulador de Firestore (host:puerto; vacío, la nube).
  final String url;

  /// La referencia del proyecto (FalconDatabase) o su ID (Firebase).
  final String project;

  /// La clave pública: anon de FalconDatabase o la clave web de Firebase.
  final String key;

  bool get on => kind == 'falcon' || kind == 'firebase';

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (url.isNotEmpty) 'url': url,
    if (project.isNotEmpty) 'project': project,
    if (key.isNotEmpty) 'key': key,
  };

  static FlBackend fromJson(Object? j) => j is Map
      ? FlBackend(
          kind: '${j['kind'] ?? ''}',
          url: '${j['url'] ?? ''}',
          project: '${j['project'] ?? ''}',
          key: '${j['key'] ?? ''}',
        )
      : const FlBackend();

  FlBackend copyWith({
    String? kind,
    String? url,
    String? project,
    String? key,
  }) => FlBackend(
    kind: kind ?? this.kind,
    url: url ?? this.url,
    project: project ?? this.project,
    key: key ?? this.key,
  );

  /// El paquete que necesita lib/db.dart.
  static const package = 'http: ^1.2.0';

  /// lib/db.dart.
  String file() => switch (kind) {
    'firebase' => _firebase(),
    _ => _falcon(),
  };

  String _str(String s) => jsonEncode(s);

  String get _common => r'''
/// Un error de la base de datos, con un mensaje para el usuario.
class DbError implements Exception {
  DbError(this.message);

  final String message;

  @override
  String toString() => message;
}
''';

  String _falcon() {
    final server = url.trim().isEmpty
        ? 'https://falcondatabase.com'
        : url.trim().replaceAll(RegExp(r'/+$'), '');
    return '''// Generado por DMarlon Studio: FalconDatabase. No lo edite (cambie la
// conexión en las propiedades de la app).
import 'dart:convert';

import 'package:http/http.dart' as http;

$_common
/// FalconDatabase (https://falcondatabase.com/docs/): tablas y sesión.
class Db {
  Db(this.url, this.project, this.key);

  final String url, project, key;

  /// La sesión: el token y el usuario (null: sin sesión).
  String? token;
  Map<String, dynamic>? user;

  bool get configured => project.isNotEmpty && key.isNotEmpty;

  String get _base => '\$url/api/v1/\$project';

  Map<String, String> get _headers => {
    'apikey': key,
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer \$token',
  };

  Future<dynamic> send(String method, String path, [Object? body]) async {
    if (!configured) throw DbError('Falta configurar FalconDatabase.');
    final uri = Uri.parse('\$_base\$path');
    final http.Response r;
    try {
      r = await switch (method) {
        'POST' => http.post(uri, headers: _headers, body: jsonEncode(body)),
        'PATCH' => http.patch(uri, headers: _headers, body: jsonEncode(body)),
        'DELETE' => http.delete(uri, headers: _headers),
        _ => http.get(uri, headers: _headers),
      };
    } catch (e) {
      throw DbError('Sin conexión con la base de datos.');
    }
    final text = utf8.decode(r.bodyBytes);
    final j = text.isEmpty ? null : jsonDecode(text);
    if (r.statusCode >= 400) {
      throw DbError(j is Map ? '\${j['error'] ?? j}' : 'Error \${r.statusCode}');
    }
    return j;
  }

  /// Entra con correo y contraseña; devuelve el usuario.
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final j = await send('POST', '/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    token = j['token'] as String?;
    user = (j['user'] as Map).cast<String, dynamic>();
    return user!;
  }

  /// Crea una cuenta (si el proyecto lo permite) y entra.
  Future<Map<String, dynamic>> signUp(
    String email,
    String password, [
    Map<String, dynamic> data = const {},
  ]) async {
    final j = await send('POST', '/auth/signup', {
      'email': email.trim(),
      'password': password,
      'data': data,
    });
    token = j['token'] as String?;
    user = (j['user'] as Map).cast<String, dynamic>();
    return user!;
  }

  void signOut() {
    token = null;
    user = null;
  }

  DbTable table(String name) => DbTable(this, name);
}

/// Una tabla: list, get, insert, update y delete.
class DbTable {
  DbTable(this.db, this.name);

  final Db db;
  final String name;

  String get _path => '/tables/\${Uri.encodeComponent(name)}';

  /// Las filas. where: columna → valor (o «gte.10», «ilike.%pan%»…);
  /// order: «precio» o «precio.desc».
  Future<List<Map<String, dynamic>>> list({
    Map<String, Object?> where = const {},
    String? order,
    int? limit,
    int? offset,
  }) async {
    final q = <String, String>{
      for (final e in where.entries)
        e.key: e.value is String &&
                RegExp(r'^(eq|neq|gt|gte|lt|lte|like|ilike|is|in)\\.').hasMatch(e.value as String)
            ? e.value as String
            : 'eq.\${e.value}',
      if (order != null) 'order': order,
      if (limit != null) 'limit': '\$limit',
      if (offset != null) 'offset': '\$offset',
    };
    final j = await db.send(
      'GET',
      q.isEmpty ? _path : '\$_path?\${Uri(queryParameters: q).query}',
    );
    return [for (final r in j['data'] as List) (r as Map).cast<String, dynamic>()];
  }

  Future<Map<String, dynamic>?> get(Object id) async {
    try {
      final j = await db.send('GET', '\$_path/\$id');
      return (j['data'] as Map).cast<String, dynamic>();
    } on DbError {
      return null;
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> row) async {
    final j = await db.send('POST', _path, row);
    return (j['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> update(Object id, Map<String, dynamic> values) async {
    final j = await db.send('PATCH', '\$_path/\$id', values);
    return (j['data'] as Map).cast<String, dynamic>();
  }

  Future<void> delete(Object id) => db.send('DELETE', '\$_path/\$id');
}

/// La base de datos de la app.
final db = Db(${_str(server)}, ${_str(project.trim())}, ${_str(key.trim())});
''';
  }

  /// Firebase: la dirección del emulador (vacía: la nube de Google).
  String get _emulator {
    final e = url.trim().replaceAll(RegExp(r'/+$'), '');
    return e.isEmpty || e.startsWith('http') ? e : 'http://$e';
  }

  String _firebase() =>
      '''// Generado por DMarlon Studio: Firebase (Cloud Firestore y
// Authentication por REST). No lo edite (cambie la conexión en las
// propiedades de la app).
import 'dart:convert';

import 'package:http/http.dart' as http;

$_common
/// Firebase: colecciones de Firestore como tablas, y sesión con correo y
/// contraseña.
class Db {
  Db(this.project, this.key, [this.emulator = '']);

  /// emulator: el emulador de Firestore (http://host:puerto) o '' (la nube).
  final String project, key, emulator;

  /// La sesión: el token y el usuario (null: sin sesión).
  String? token;
  Map<String, dynamic>? user;

  bool get configured =>
      project.isNotEmpty && (key.isNotEmpty || emulator.isNotEmpty);

  String get _base =>
      '\${emulator.isEmpty ? 'https://firestore.googleapis.com' : emulator}/v1/projects/\$project/databases/(default)/documents';

  Future<dynamic> send(String method, Uri uri, [Object? body]) async {
    if (!configured) throw DbError('Falta configurar Firebase.');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer \$token',
    };
    final http.Response r;
    try {
      r = await switch (method) {
        'POST' => http.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => http.patch(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };
    } catch (e) {
      throw DbError('Sin conexión con la base de datos.');
    }
    final text = utf8.decode(r.bodyBytes);
    final j = text.isEmpty ? null : jsonDecode(text);
    if (r.statusCode >= 400) {
      final e = j is Map ? j['error'] : null;
      throw DbError(e is Map ? '\${e['message']}' : 'Error \${r.statusCode}');
    }
    return j;
  }

  Uri uri(String path, [Map<String, dynamic>? q]) => Uri.parse('\$_base\$path')
      .replace(queryParameters: {...?q, if (token == null && key.isNotEmpty) 'key': key});

  Future<Map<String, dynamic>> _auth(String what, String email, String password) async {
    final j = await send(
      'POST',
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:\$what?key=\$key'),
      {'email': email.trim(), 'password': password, 'returnSecureToken': true},
    );
    token = j['idToken'] as String?;
    user = {'id': j['localId'], 'email': j['email']};
    return user!;
  }

  /// Entra con correo y contraseña; devuelve el usuario.
  Future<Map<String, dynamic>> signIn(String email, String password) =>
      _auth('signInWithPassword', email, password);

  /// Crea una cuenta y entra.
  Future<Map<String, dynamic>> signUp(
    String email,
    String password, [
    Map<String, dynamic> data = const {},
  ]) => _auth('signUp', email, password);

  void signOut() {
    token = null;
    user = null;
  }

  DbTable table(String name) => DbTable(this, name);
}

Map<String, dynamic> _encode(Object? v) => switch (v) {
  null => {'nullValue': null},
  bool b => {'booleanValue': b},
  int i => {'integerValue': '\$i'},
  double d => {'doubleValue': d},
  List l => {'arrayValue': {'values': [for (final x in l) _encode(x)]}},
  Map m => {'mapValue': {'fields': {for (final e in m.entries) '\${e.key}': _encode(e.value)}}},
  _ => {'stringValue': '\$v'},
};

Object? _decode(Object? v) {
  if (v is! Map || v.isEmpty) return v;
  final k = v.keys.first as String, x = v.values.first;
  return switch (k) {
    'nullValue' => null,
    'integerValue' => int.tryParse('\$x') ?? x,
    'doubleValue' => (x as num).toDouble(),
    'arrayValue' => [for (final i in (x as Map)['values'] as List? ?? []) _decode(i)],
    'mapValue' => {
      for (final e in ((x as Map)['fields'] as Map? ?? {}).entries) '\${e.key}': _decode(e.value),
    },
    _ => x,
  };
}

Map<String, dynamic> _row(Map doc) => {
  'id': '\${doc['name']}'.split('/').last,
  for (final e in ((doc['fields'] as Map?) ?? {}).entries) '\${e.key}': _decode(e.value),
};

/// Una colección: list, get, insert, update y delete.
class DbTable {
  DbTable(this.db, this.name);

  final Db db;
  final String name;

  static const _ops = {
    'eq': 'EQUAL', 'neq': 'NOT_EQUAL', 'gt': 'GREATER_THAN',
    'gte': 'GREATER_THAN_OR_EQUAL', 'lt': 'LESS_THAN',
    'lte': 'LESS_THAN_OR_EQUAL',
  };

  /// Los documentos. where: campo → valor (o «gte.10»…); order: «precio»
  /// o «precio.desc».
  Future<List<Map<String, dynamic>>> list({
    Map<String, Object?> where = const {},
    String? order,
    int? limit,
    int? offset,
  }) async {
    if (where.isEmpty && order == null) {
      final j = await db.send('GET', db.uri('/\$name', {if (limit != null) 'pageSize': '\$limit'}));
      return [for (final d in (j?['documents'] as List?) ?? []) _row(d as Map)];
    }
    final filters = [
      for (final e in where.entries)
        () {
          var op = 'EQUAL';
          Object? value = e.value;
          final m = value is String ? RegExp(r'^(eq|neq|gt|gte|lt|lte)\\.(.*)\$').firstMatch(value) : null;
          if (m != null) {
            op = _ops[m[1]]!;
            value = num.tryParse(m[2]!) ?? m[2];
          }
          return {'fieldFilter': {'field': {'fieldPath': e.key}, 'op': op, 'value': _encode(value)}};
        }(),
    ];
    final parts = order?.split('.');
    final j = await db.send('POST', db.uri(':runQuery'), {
      'structuredQuery': {
        'from': [{'collectionId': name}],
        if (filters.length == 1) 'where': filters.single,
        if (filters.length > 1) 'where': {'compositeFilter': {'op': 'AND', 'filters': filters}},
        if (parts != null)
          'orderBy': [{
            'field': {'fieldPath': parts.first},
            'direction': parts.length > 1 && parts[1] == 'desc' ? 'DESCENDING' : 'ASCENDING',
          }],
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    });
    return [
      for (final r in j as List)
        if (r is Map && r['document'] is Map) _row(r['document'] as Map),
    ];
  }

  Future<Map<String, dynamic>?> get(Object id) async {
    try {
      return _row(await db.send('GET', db.uri('/\$name/\$id')) as Map);
    } on DbError {
      return null;
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> row) async {
    final j = await db.send('POST', db.uri('/\$name'), {
      'fields': {for (final e in row.entries) e.key: _encode(e.value)},
    });
    return _row(j as Map);
  }

  Future<Map<String, dynamic>> update(Object id, Map<String, dynamic> values) async {
    final j = await db.send(
      'PATCH',
      db.uri('/\$name/\$id', {'updateMask.fieldPaths': values.keys.toList()}),
      {'fields': {for (final e in values.entries) e.key: _encode(e.value)}},
    );
    return _row(j as Map);
  }

  Future<void> delete(Object id) => db.send('DELETE', db.uri('/\$name/\$id'));
}

/// La base de datos de la app.
final db = Db(${_str(project.trim())}, ${_str(key.trim())}${_emulator.isEmpty ? '' : ', ${_str(_emulator)}'});
''';
}
