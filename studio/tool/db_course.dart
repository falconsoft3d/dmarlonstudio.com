// Ejecuta una lección de los cursos de bases de datos de la web con el mismo
// cliente que el módulo Bases de datos del estudio (lib/dev):
//
//   dart run tool/db_course.dart <tipo> <conexión.json> <script> [datos]
//
// Primero deja la base de datos vacía (cada tipo a su manera), después
// ejecuta [datos] (los datos del curso, sin guardar sus resultados) y el
// script de la lección. Escribe un JSON: {"results": […], "schema": […]}
// y, si una consulta falla, "error": {"index", "message"}.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/core/errors.dart';
import 'package:dmarlon_studio/dev/dev_client.dart';
import 'package:dmarlon_studio/dev/dev_script.dart';
import 'package:dmarlon_studio/dev/dev_types.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  _en = catalogOf(File('assets/i18n/en.po').readAsStringSync());
  // --batch <trabajos.json>: [{kind, conn, script, seed?}, …] → una línea
  // JSON por trabajo (no arranca Dart en cada lección).
  if (args.length == 2 && args[0] == '--batch') {
    final jobs = jsonDecode(File(args[1]).readAsStringSync()) as List;
    for (final j in jobs.cast<Map>()) {
      stdout.writeln(
        jsonEncode(
          await _job(
            '${j['kind']}',
            (j['conn'] as Map).cast<String, Object?>(),
            '${j['script']}',
            j['seed'] as String?,
          ),
        ),
      );
    }
    exit(0);
  }
  if (args.length < 3) {
    stderr.writeln('db_course <tipo> <conexión.json> <script> [datos]');
    stderr.writeln('db_course --batch <trabajos.json>');
    exit(2);
  }
  final out = await _job(
    args[0],
    (jsonDecode(File(args[1]).readAsStringSync()) as Map)
        .cast<String, Object?>(),
    File(args[2]).readAsStringSync(),
    args.length > 3 ? File(args[3]).readAsStringSync() : null,
  );
  stdout.writeln(jsonEncode(out));
  exit(out['fatal'] == null ? 0 : 1);
}

/// Una lección: {results, schema, error?} o {fatal} si no se pudo ni
/// empezar (sin conexión, datos que fallan…).
Future<Map<String, Object?>> _job(
  String kind,
  Map<String, Object?> conn,
  String script,
  String? seed,
) async {
  final out = <String, Object?>{};
  DevDb? db;
  try {
    await _reset(kind, conn);
    db = await openDevDb(kind, conn);
    if (seed != null) {
      try {
        await runScript(db, splitScript(kind, seed));
      } on ScriptError catch (e) {
        throw UserError('datos: ${e.message}');
      }
    }
    try {
      out['results'] = [
        for (final r in await runScript(db, splitScript(kind, script))) _res(r),
      ];
    } on ScriptError catch (e) {
      out['results'] = [for (final r in e.done) _res(r)];
      out['error'] = {'index': e.index, 'message': e.detail};
    }
    out['schema'] = [
      for (final t in await db.schema())
        {
          'name': t.name,
          'type': t.type,
          'columns': [for (final c in t.columns) c.$1],
        },
    ];
  } on UserError catch (e) {
    return {'fatal': e.message};
  } catch (e) {
    return {'fatal': '$e'};
  } finally {
    await db?.close();
  }
  return out;
}

Map<String, Object?> _res(DevResult r) => {
  if (r.columns.isNotEmpty) 'columns': r.columns,
  if (r.columns.isNotEmpty) 'rows': r.rows,
  if (r.message != null) 'message': r.message,
  if (r.message != null) 'message_en': _english(r.message!),
  if (r.affected != null) 'affected': r.affected,
};

var _en = <String, String>{};

/// El mensaje [es] (ya con sus valores) en inglés, con el catálogo del
/// estudio: «3 filas afectadas» → «3 rows affected».
String _english(String es) {
  if (_en[es] != null) return _en[es]!;
  for (final MapEntry(key: k, value: v) in _en.entries) {
    if (!k.contains('{0}')) continue;
    final names = <String>[];
    final pattern = k.splitMapJoin(
      RegExp(r'\{(\d+)\}'),
      onMatch: (m) {
        names.add(m[1]!);
        return '(.+?)';
      },
      onNonMatch: RegExp.escape,
    );
    final m = RegExp('^$pattern\$').firstMatch(es);
    if (m == null) continue;
    return v.replaceAllMapped(RegExp(r'\{(\d+)\}'), (x) {
      final i = names.indexOf(x[1]!);
      return i < 0 ? x[0]! : m[i + 1]!;
    });
  }
  return es;
}

/// Deja la base de datos vacía.
Future<void> _reset(String kind, Map<String, Object?> c) async {
  switch (kind) {
    case 'sqlite':
      final f = File('${c['path']}');
      if (f.existsSync()) f.deleteSync();
      f.createSync(recursive: true);
    case 'postgres':
      final admin = await openDevDb(kind, {...c, 'database': 'postgres'});
      try {
        await admin.run(
          'DROP DATABASE IF EXISTS "${c['database']}" WITH (FORCE)',
        );
        await admin.run('CREATE DATABASE "${c['database']}"');
      } finally {
        await admin.close();
      }
    case 'mysql':
      final admin = await openDevDb(kind, {...c, 'database': ''});
      try {
        await admin.run('DROP DATABASE IF EXISTS `${c['database']}`');
        await admin.run(
          'CREATE DATABASE `${c['database']}` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci',
        );
      } finally {
        await admin.close();
      }
    case 'mongodb':
      final db = await openDevDb(kind, c);
      try {
        for (final t in await db.schema()) {
          await db.run(jsonEncode({'collection': t.name, 'drop': true}));
        }
      } finally {
        await db.close();
      }
    case 'firebase':
      final host = '${c['emulator']}';
      final r = await http.delete(
        Uri.parse(
          '${host.startsWith('http') ? host : 'http://$host'}/emulator/v1/projects/${c['project']}/databases/(default)/documents',
        ),
      );
      if (r.statusCode >= 400) throw UserError('emulador: ${r.body}');
    case 'falcon':
      // Las tablas las crea el proyecto del curso; aquí se vacían.
      final db = await openDevDb(kind, c);
      try {
        for (final t in await db.schema()) {
          await db.run(
            jsonEncode({
              'table': t.name,
              'delete': {
                'where': {'id': 'gt.0'},
              },
            }),
          );
        }
      } finally {
        await db.close();
      }
  }
}
