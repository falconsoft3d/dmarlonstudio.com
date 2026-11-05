import 'dart:convert';

import '../core/errors.dart';
import '../core/settings.dart';
import '../core/studio_db.dart';
import '../i18n/tr.dart';

/// Herramientas: conexiones (bases de datos y FTP), peticiones de API
/// guardadas por colecciones, su historial y las variables de entorno.
class DevTools {
  DevTools._();

  /// Tipos de conexión: (clave, nombre).
  static final kinds = <(String, String)>[
    ('sqlite', 'SQLite'),
    ('postgres', 'PostgreSQL'),
    ('mysql', 'MySQL / MariaDB'),
    ('mongodb', 'MongoDB'),
    ('ftp', 'FTP'),
  ];

  static Map<String, Object?> configOf(Map<String, Object?> row) {
    try {
      final j = jsonDecode('${row['config'] ?? '{}'}');
      return j is Map ? j.cast<String, Object?>() : {};
    } on FormatException {
      return {};
    }
  }

  // ------------------------------------------------------------ conexiones
  static Future<List<Map<String, Object?>>> connections({bool ftp = false}) =>
      StudioDb.db.query(
        'dev_connection',
        where: ftp ? "kind = 'ftp'" : "kind <> 'ftp'",
        orderBy: 'lower(name), id',
      );

  static Future<int> saveConnection(
    int? id, {
    required String kind,
    required String name,
    required Map<String, Object?> config,
  }) async {
    if (name.trim().isEmpty) throw UserError(tr('Indique un nombre.'));
    if (!kinds.any((k) => k.$1 == kind)) throw UserError(tr('Tipo no válido.'));
    final v = {'kind': kind, 'name': name.trim(), 'config': jsonEncode(config)};
    if (id == null) {
      return StudioDb.db.insert('dev_connection', {
        ...v,
        'create_date': nowStr(),
      });
    }
    await StudioDb.db.update(
      'dev_connection',
      v,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  static Future<void> deleteConnection(int id) =>
      StudioDb.db.delete('dev_connection', where: 'id = ?', whereArgs: [id]);

  // -------------------------------------------------------- peticiones API
  static Future<List<Map<String, Object?>>> requests() => StudioDb.db.query(
    'dev_request',
    orderBy: 'lower(collection), lower(name), id',
  );

  static Future<int> saveRequest(
    int? id, {
    required String collection,
    required String name,
    required Map<String, Object?> request,
  }) async {
    if (name.trim().isEmpty) throw UserError(tr('Indique un nombre.'));
    final v = {
      'collection': collection.trim(),
      'name': name.trim(),
      'request': jsonEncode(request),
    };
    if (id == null) {
      return StudioDb.db.insert('dev_request', {...v, 'create_date': nowStr()});
    }
    await StudioDb.db.update(
      'dev_request',
      v,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  static Future<void> deleteRequest(int id) =>
      StudioDb.db.delete('dev_request', where: 'id = ?', whereArgs: [id]);

  /// Historial: las 100 últimas peticiones enviadas.
  static Future<List<Map<String, Object?>>> history() =>
      StudioDb.db.query('dev_request_history', orderBy: 'id DESC', limit: 100);

  static Future<void> addHistory(
    Map<String, Object?> request, {
    int? status,
    int? ms,
  }) async {
    await StudioDb.db.insert('dev_request_history', {
      'method': '${request['method'] ?? 'GET'}',
      'url': '${request['url'] ?? ''}',
      'status': status,
      'ms': ms,
      'request': jsonEncode(request),
      'date': nowStr(),
    });
    // Solo las 100 últimas.
    await StudioDb.db.execute(
      'DELETE FROM dev_request_history WHERE id NOT IN '
      '(SELECT id FROM dev_request_history ORDER BY id DESC LIMIT 100)',
    );
  }

  static Future<void> clearHistory() =>
      StudioDb.db.delete('dev_request_history');

  // ----------------------------------------------- variables de entorno
  /// Variables {{nombre}} para las peticiones (p. ej. base_url, token).
  static Future<Map<String, String>> env() async {
    try {
      final j = jsonDecode(await Settings.get('dev.env') ?? '{}');
      return j is Map
          ? {for (final e in j.entries) '${e.key}': '${e.value}'}
          : {};
    } on FormatException {
      return {};
    }
  }

  static Future<void> setEnv(Map<String, String> vars) =>
      Settings.set('dev.env', jsonEncode(vars));
}
