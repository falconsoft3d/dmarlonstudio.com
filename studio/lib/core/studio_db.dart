import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base local del estudio (`studio.sqlite` en la carpeta de soporte de la
/// aplicación): ajustes, conexiones, peticiones de API, su historial y los
/// diagramas. Los proyectos de interfaz NO van aquí: son carpetas del disco
/// (ver `ProjectStore`), para poder versionarlas con git.
class StudioDb {
  StudioDb._();

  static Database? _db;

  /// Carpeta de la base en las pruebas.
  static String? dirOverride;

  static Database get db {
    final d = _db;
    if (d == null) throw StateError('StudioDb.open() no se ha llamado.');
    return d;
  }

  static const _version = 1;

  static Future<void> open() async {
    if (_db != null) return;
    sqfliteFfiInit();
    final dir = dirOverride ?? (await getApplicationSupportDirectory()).path;
    await Directory(dir).create(recursive: true);
    _db = await databaseFactoryFfi.openDatabase(
      p.join(dir, 'studio.sqlite'),
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, _) async {
          for (final s in _schema) {
            await db.execute(s);
          }
        },
      ),
    );
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static const _schema = [
    '''CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT)''',
    '''CREATE TABLE dev_connection (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kind TEXT NOT NULL,
      name TEXT NOT NULL,
      config TEXT NOT NULL DEFAULT '{}',
      create_date TEXT NOT NULL)''',
    '''CREATE TABLE dev_request (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      collection TEXT NOT NULL DEFAULT '',
      name TEXT NOT NULL,
      request TEXT NOT NULL,
      create_date TEXT NOT NULL)''',
    '''CREATE TABLE dev_request_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      method TEXT NOT NULL,
      url TEXT NOT NULL,
      status INTEGER,
      ms INTEGER,
      request TEXT NOT NULL,
      date TEXT NOT NULL)''',
    '''CREATE TABLE dev_diagram (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      kind TEXT NOT NULL DEFAULT 'flow',
      data TEXT NOT NULL DEFAULT '{}',
      create_date TEXT NOT NULL,
      write_date TEXT NOT NULL)''',
  ];
}
