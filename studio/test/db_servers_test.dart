// Bases de datos de verdad: crear una tabla, insertar, leer el esquema y
// consultar con el cliente del módulo Bases de datos. Cada una necesita su
// servidor; sin la variable se salta:
//
//   DMS_PG=host:puerto:base:usuario
//   DMS_MYSQL=host:puerto:base:usuario
//   DMS_MONGO=mongodb://host:puerto/base
import 'dart:io';

import 'package:dmarlon_studio/dev/dev_client.dart';
import 'package:dmarlon_studio/dev/dev_types.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?>? _sql(String env) {
  final v = Platform.environment[env];
  if (v == null || v.isEmpty) return null;
  final p = v.split(':');
  return {
    'host': p[0],
    'port': p[1],
    'database': p[2],
    'user': p[3],
    'password': p.length > 4 ? p[4] : '',
  };
}

Future<void> _roundTrip(DevDb db, String table) async {
  await db.run('DROP TABLE IF EXISTS $table');
  await db.run(
    'CREATE TABLE $table (id INTEGER PRIMARY KEY, nombre VARCHAR(40), precio DECIMAL(8,2))',
  );
  final ins = await db.run(
    "INSERT INTO $table (id, nombre, precio) VALUES (1, 'Pan', 1.20), (2, 'Café ñ', 2.50)",
  );
  expect(ins.affected, 2);
  final tables = await db.schema();
  final t = tables.firstWhere((t) => t.name == table);
  expect(t.columns.map((c) => c.$1), containsAll(['id', 'nombre', 'precio']));
  final r = await db.run(db.sampleQuery(t));
  expect(r.rows.length, 2);
  final sum = await db.run(
    "SELECT nombre FROM $table WHERE precio > 2 ORDER BY id",
  );
  expect(sum.rows.single.single, 'Café ñ');
  await db.run('DROP TABLE $table');
}

void main() {
  test('SQLite: un archivo', () async {
    final tmp = await Directory.systemTemp.createTemp('dms_sqlite_');
    addTearDown(() => tmp.delete(recursive: true));
    final file = File('${tmp.path}/datos.db')..createSync();
    final db = await openDevDb('sqlite', {'path': file.path});
    addTearDown(db.close);
    await _roundTrip(db, 'productos');
  });

  test('PostgreSQL', () async {
    final c = _sql('DMS_PG');
    if (c == null) return markTestSkipped('Sin DMS_PG.');
    final db = await openDevDb('postgres', c);
    addTearDown(db.close);
    await _roundTrip(db, 'dms_productos');
  });

  test('MySQL / MariaDB', () async {
    final c = _sql('DMS_MYSQL');
    if (c == null) return markTestSkipped('Sin DMS_MYSQL.');
    final db = await openDevDb('mysql', c);
    addTearDown(db.close);
    await _roundTrip(db, 'dms_productos');
  });

  test('MongoDB', () async {
    final uri = Platform.environment['DMS_MONGO'];
    if (uri == null || uri.isEmpty) return markTestSkipped('Sin DMS_MONGO.');
    final db = await openDevDb('mongodb', {'uri': uri});
    addTearDown(db.close);
    await db.run('{"collection": "dms_productos", "delete": {}}');
    await db.run(
      '{"collection": "dms_productos", "insert": [{"nombre": "Pan", "precio": 1.2}, {"nombre": "Café ñ", "precio": 2.5}]}',
    );
    final t = (await db.schema()).firstWhere((t) => t.name == 'dms_productos');
    expect(t.columns.map((c) => c.$1), containsAll(['nombre', 'precio']));
    final r = await db.run(
      '{"collection": "dms_productos", "find": {"precio": {"\$gt": 2}}}',
    );
    expect(r.rows.length, 1);
    expect(r.columns, contains('nombre'));
  });
}
