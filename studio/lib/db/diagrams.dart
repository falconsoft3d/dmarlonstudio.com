import '../core/errors.dart';
import '../core/studio_db.dart';
import '../dev/diagram.dart';
import '../i18n/tr.dart';

/// Diagramas guardados: de flujo (programación) y de base de datos
/// (entidad-relación).
class Diagrams {
  Diagrams._();

  static Future<List<Map<String, Object?>>> all() =>
      StudioDb.db.query('dev_diagram', orderBy: 'write_date DESC');

  static Future<Map<String, Object?>?> get(int id) async =>
      (await StudioDb.db.query(
        'dev_diagram',
        where: 'id = ?',
        whereArgs: [id],
      )).firstOrNull;

  static Future<int> create(
    String name,
    String kind, {
    Diagram? diagram,
  }) async {
    if (name.trim().isEmpty) throw UserError(tr('Indique un nombre.'));
    final now = nowStr();
    return StudioDb.db.insert('dev_diagram', {
      'name': name.trim(),
      'kind': kind == 'er' ? 'er' : 'flow',
      'data': (diagram ?? Diagram()).toJsonString(),
      'create_date': now,
      'write_date': now,
    });
  }

  static Future<void> save(int id, Diagram d) => StudioDb.db.update(
    'dev_diagram',
    {'data': d.toJsonString(), 'write_date': nowStr()},
    where: 'id = ?',
    whereArgs: [id],
  );

  static Future<void> rename(int id, String name) async {
    if (name.trim().isEmpty) throw UserError(tr('Indique un nombre.'));
    await StudioDb.db.update(
      'dev_diagram',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) =>
      StudioDb.db.delete('dev_diagram', where: 'id = ?', whereArgs: [id]);
}
