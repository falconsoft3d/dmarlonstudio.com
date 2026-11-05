import 'studio_db.dart';

/// Ajustes del estudio (clave → texto), en la base local. Sustituye a los
/// parámetros por compañía del ERP: aquí solo hay un usuario.
class Settings {
  Settings._();

  static Future<String?> get(String key) async {
    final r = await StudioDb.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return r.isEmpty ? null : r.first['value'] as String?;
  }

  /// Guarda [value] en [key]; null lo borra.
  static Future<void> set(String key, String? value) async {
    if (value == null) {
      await StudioDb.db.delete('settings', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await StudioDb.db.rawInsert(
      'INSERT INTO settings (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }
}
