// Bases de datos en la nube del módulo Bases de datos.
//
//   DMS_FALCON=referencia:clave  (opcional DMS_FALCON_URL): FalconDatabase de
//   verdad, con una tabla «productos» (nombre text, precio decimal).
//
// Firebase se prueba contra un servidor local con las rutas REST de Cloud
// Firestore (y, con DMS_FIRESTORE_EMULATOR=host:puerto, contra el emulador).
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/dev/dev_client.dart';
import 'package:dmarlon_studio/dev/dev_cloud_db.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un Firestore mínimo en memoria: las rutas que usa FirebaseDb.
Future<HttpServer> _fakeFirestore(List<String> auth) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final cols = <String, Map<String, Map<String, Object?>>>{};
  var next = 0;
  const root = '/v1/projects/demo/databases/(default)/documents';
  Map<String, Object?> doc(String col, String id) => {
    'name': 'projects/demo/databases/(default)/documents/$col/$id',
    'fields': cols[col]![id],
  };
  Object? value(Map v) =>
      v.values.first is String && v.keys.first == 'integerValue'
      ? int.parse(v.values.first as String)
      : v.values.first;
  server.listen((req) async {
    auth.add(req.headers.value('authorization') ?? '');
    final body = await utf8.decoder.bind(req).join();
    final j = body.isEmpty ? null : jsonDecode(body);
    final path = Uri.decodeFull(req.uri.path);
    Object? out;
    var status = 200;
    if (path == '$root:listCollectionIds') {
      out = {'collectionIds': cols.keys.toList()};
    } else if (path == '$root:runQuery') {
      final sq = (j as Map)['structuredQuery'] as Map;
      final col = ((sq['from'] as List).first as Map)['collectionId'] as String;
      final w = sq['where'] as Map?;
      final filters = w == null
          ? const []
          : w['fieldFilter'] != null
          ? [w]
          : (w['compositeFilter'] as Map)['filters'] as List;
      var ids = (cols[col] ?? {}).keys.where((id) {
        for (final f in filters) {
          final ff = (f as Map)['fieldFilter'] as Map;
          final field = (ff['field'] as Map)['fieldPath'];
          final a = value(
            (cols[col]![id]![field] as Map?) ?? {'nullValue': null},
          );
          final b = value(ff['value'] as Map);
          final ok = switch (ff['op']) {
            'EQUAL' => a == b,
            'GREATER_THAN_OR_EQUAL' => a is num && b is num && a >= b,
            'LESS_THAN' => a is num && b is num && a < b,
            _ => false,
          };
          if (!ok) return false;
        }
        return true;
      }).toList();
      final ob = sq['orderBy'] as List?;
      if (ob != null) {
        final o = ob.first as Map;
        final field = (o['field'] as Map)['fieldPath'];
        ids.sort((x, y) {
          final a = value(cols[col]![x]![field] as Map) as Comparable;
          final b = value(cols[col]![y]![field] as Map) as Comparable;
          return o['direction'] == 'DESCENDING'
              ? b.compareTo(a)
              : a.compareTo(b);
        });
      }
      ids = ids.take((sq['limit'] as int?) ?? 1000).toList();
      out = [
        for (final id in ids) {'document': doc(col, id)},
      ];
    } else if (path.startsWith('$root/')) {
      final parts = path.substring(root.length + 1).split('/');
      final col = parts[0];
      if (parts.length == 1 && req.method == 'GET') {
        final size =
            int.tryParse(req.uri.queryParameters['pageSize'] ?? '') ?? 100;
        out = {
          'documents': [
            for (final id in (cols[col] ?? {}).keys.take(size)) doc(col, id),
          ],
        };
      } else if (parts.length == 1 && req.method == 'POST') {
        final id = req.uri.queryParameters['documentId'] ?? 'd${++next}';
        (cols[col] ??= {})[id] = ((j as Map)['fields'] as Map).cast();
        out = doc(col, id);
      } else if (parts.length == 2 && req.method == 'PATCH') {
        final mask = req.uri.queryParametersAll['updateMask.fieldPaths'] ?? [];
        final f = ((j as Map)['fields'] as Map).cast<String, Object?>();
        for (final k in mask) {
          cols[col]![parts[1]]![k] = f[k];
        }
        out = doc(col, parts[1]);
      } else if (parts.length == 2 && req.method == 'DELETE') {
        cols[col]!.remove(parts[1]);
        out = {};
      } else {
        status = 404;
        out = {
          'error': {'message': 'not found'},
        };
      }
    }
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(out));
    await req.response.close();
  });
  return server;
}

void main() {
  test('Firestore: valores de ida y vuelta', () {
    final v = {
      'n': 3,
      'x': 2.5,
      's': 'ñ',
      'b': true,
      'z': null,
      'l': [1, 'a'],
      'm': {'k': 1},
    };
    expect({
      for (final e in FirebaseDb.fields(v).entries)
        e.key: FirebaseDb.decode(e.value),
    }, v);
  });

  test('Firebase: colecciones, insertar, filtrar, cambiar y borrar', () async {
    final auth = <String>[];
    final server = await _fakeFirestore(auth);
    addTearDown(server.close);
    final emulator =
        Platform.environment['DMS_FIRESTORE_EMULATOR'] ??
        '127.0.0.1:${server.port}';
    final db = await openDevDb('firebase', {
      'project': 'demo',
      'emulator': emulator,
    });
    addTearDown(db.close);
    final ins = await db.run(
      '{"collection": "productos", "insert": [{"_id": "pan", "nombre": "Pan", "precio": 1.2}, {"nombre": "Café ñ", "precio": 2.5, "stock": 3}]}',
    );
    expect(ins.affected, 2);
    final t = (await db.schema()).firstWhere((t) => t.name == 'productos');
    expect(t.columns.map((c) => c.$1), containsAll(['nombre', 'precio']));
    final all = await db.run(db.sampleQuery(t));
    expect(all.rows.length, 2);
    expect(all.columns, contains('_id'));
    final cheap = await db.run(
      '{"collection": "productos", "where": {"precio": {"gte": 2}}, "order": "precio desc"}',
    );
    expect(cheap.rows.length, 1);
    expect(cheap.rows.single[cheap.columns.indexOf('nombre')], 'Café ñ');
    await db.run(
      '{"collection": "productos", "update": {"id": "pan", "set": {"precio": 1.3}}}',
    );
    final pan = await db.run(
      '{"collection": "productos", "where": {"nombre": "Pan"}}',
    );
    expect(pan.rows.single[pan.columns.indexOf('precio')], 1.3);
    await db.run('{"collection": "productos", "delete": "pan"}');
    expect((await db.run(db.sampleQuery(t))).rows.length, 1);
    if (!Platform.environment.containsKey('DMS_FIRESTORE_EMULATOR')) {
      expect(auth.every((a) => a == 'Bearer owner'), isTrue);
    }
  });

  test('FalconDatabase de verdad', () async {
    final v = Platform.environment['DMS_FALCON'];
    if (v == null || !v.contains(':')) {
      return markTestSkipped('Sin DMS_FALCON.');
    }
    final (ref, key) = (v.split(':').first, v.split(':').skip(1).join(':'));
    final db = await openDevDb('falcon', {
      'url': Platform.environment['DMS_FALCON_URL'],
      'project': ref,
      'key': key,
    });
    addTearDown(db.close);
    final t = (await db.schema()).firstWhere((t) => t.name == 'productos');
    expect(t.columns.map((c) => c.$1), containsAll(['id', 'nombre', 'precio']));
    final ins = await db.run(
      '{"table": "productos", "insert": {"nombre": "Prueba DMS", "precio": 9.75}}',
    );
    expect(ins.affected, 1);
    final id = ins.rows.single[ins.columns.indexOf('id')];
    final found = await db.run(
      '{"table": "productos", "where": {"nombre": "Prueba DMS", "precio": "gte.9"}, "order": "id.desc"}',
    );
    expect(found.rows.length, greaterThanOrEqualTo(1));
    expect(found.message, contains('total'));
    await db.run(
      '{"table": "productos", "update": {"id": $id, "set": {"precio": 9.5}}}',
    );
    final again = await db.run('{"table": "productos", "where": {"id": $id}}');
    expect(again.rows.single[again.columns.indexOf('precio')], 9.5);
    await db.run('{"table": "productos", "delete": $id}');
    final gone = await db.run('{"table": "productos", "where": {"id": $id}}');
    expect(gone.rows, isEmpty);
    // Una tabla que no existe: el error de la API, legible.
    expect(
      () => db.run('{"table": "nada"}'),
      throwsA(predicate((e) => '$e'.contains('nada'))),
    );
  });

  test('FalconDatabase: una clave mala no conecta', () async {
    if (Platform.environment['DMS_FALCON'] == null) {
      return markTestSkipped('Sin DMS_FALCON.');
    }
    final ref = Platform.environment['DMS_FALCON']!.split(':').first;
    expect(
      () => FalconDb.open({'project': ref, 'key': 'fdb_anon_mala'}),
      throwsA(anything),
    );
  });
}
