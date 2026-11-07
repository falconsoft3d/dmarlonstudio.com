import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mysql_client/mysql_client.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'dev_cloud_db.dart';
import 'dev_types.dart';

/// Abre una conexión: sqlite (archivo), postgres, mysql, mongodb, falcon
/// (FalconDatabase) o firebase (Cloud Firestore).
Future<DevDb> openDevDb(String kind, Map<String, Object?> c) async {
  String s(String k, [String d = '']) => '${c[k] ?? d}'.trim();
  int port(int d) => int.tryParse(s('port')) ?? d;
  try {
    switch (kind) {
      case 'sqlite':
        final path = s('path');
        if (path.isEmpty || !File(path).existsSync()) {
          throw UserError(tr('No existe el archivo {0}.', [path]));
        }
        sqfliteFfiInit();
        return _Sqlite(await databaseFactoryFfi.openDatabase(path));
      case 'postgres':
        return _Postgres(
          await pg.Connection.open(
            pg.Endpoint(
              host: s('host', 'localhost'),
              port: port(5432),
              database: s('database'),
              username: s('user'),
              password: '${c['password'] ?? ''}',
            ),
            settings: pg.ConnectionSettings(
              sslMode: c['ssl'] == true
                  ? pg.SslMode.require
                  : pg.SslMode.disable,
              connectTimeout: const Duration(seconds: 15),
            ),
          ),
        );
      case 'mysql':
        Future<MySQLConnection> connect(bool secure) async {
          final conn = await MySQLConnection.createConnection(
            host: s('host', 'localhost'),
            port: port(3306),
            userName: s('user'),
            password: '${c['password'] ?? ''}',
            databaseName: s('database').isEmpty ? null : s('database'),
            secure: secure,
          );
          await conn.connect(timeoutMs: 15000);
          return conn;
        }

        MySQLConnection conn;
        try {
          conn = await connect(c['ssl'] == true);
        } on Exception catch (e) {
          // MySQL 8 (caching_sha2_password) pide una conexión cifrada:
          // se repite con TLS.
          if (c['ssl'] == true || !'$e'.contains('secure')) rethrow;
          conn = await connect(true);
        }
        return _MySql(conn, s('database'));
      case 'falcon':
        return await FalconDb.open(c);
      case 'firebase':
        return await FirebaseDb.open(c);
      case 'mongodb':
        final uri = s('uri').isNotEmpty
            ? s('uri')
            : 'mongodb://${s('user').isEmpty ? '' : '${Uri.encodeComponent(s('user'))}:${Uri.encodeComponent('${c['password'] ?? ''}')}@'}'
                  '${s('host', 'localhost')}:${port(27017)}/${s('database')}';
        final db = await mongo.Db.create(uri);
        await db.open();
        return _Mongo(db);
    }
  } on UserError {
    rethrow;
  } catch (e) {
    throw UserError(tr('No se pudo conectar: {0}', [e]));
  }
  throw UserError(tr('Tipo no válido.'));
}

/// El texto de SQLite de una DatabaseException de sqflite, sin la consulta
/// ni los detalles de la conexión: «FOREIGN KEY constraint failed».
String sqliteMessage(String e) {
  // «… SqliteException(2067): while executing, UNIQUE constraint failed:
  // a.n, constraint failed (code 2067)\n  Causing statement: …»
  final m = RegExp(
    r'SqliteException\(\d+\):\s*(?:while (?:executing|preparing)[^,]*,\s*)?([^\n]+?)\s*(?:\(code \d+[^)]*\))?\s*(?:\n|$)',
  ).firstMatch(e);
  if (m == null) return e.split(' {details').first;
  return m[1]!.replaceFirst(RegExp(r',\s*constraint failed$'), '').trim();
}

/// INSERT, UPDATE, DELETE… (las que cuentan filas afectadas).
bool _isDml(String q) => RegExp(
  r'^\s*(insert|update|delete|replace|merge|with)\b',
  caseSensitive: false,
).hasMatch(q);

bool _isRead(String q) => RegExp(
  r'^\s*(select|with|pragma|explain|show|describe|desc|values)\b',
  caseSensitive: false,
).hasMatch(q);

class _Sqlite extends DevDb {
  _Sqlite(this.db);
  final Database db;

  @override
  Future<List<DevTable>> schema() async => [
    for (final t in await db.rawQuery(
      "SELECT name, type FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ))
      DevTable(
        '${t['name']}',
        type: '${t['type']}',
        columns: [
          for (final c in await db.rawQuery(
            'PRAGMA table_info("${t['name']}")',
          ))
            ('${c['name']}', '${c['type']}'),
        ],
      ),
  ];

  @override
  Future<DevResult> run(String query) async {
    try {
      // RETURNING: las filas que cambian, en la rejilla.
      if (_isRead(query) ||
          RegExp(r'\breturning\b', caseSensitive: false).hasMatch(query)) {
        return DevResult.fromMaps(await db.rawQuery(query));
      }
      if (RegExp(
        r'^\s*(insert|update|delete|replace)\b',
        caseSensitive: false,
      ).hasMatch(query)) {
        final n = await db.rawUpdate(query);
        return DevResult(affected: n, message: affectedMessage(n));
      }
      await db.execute(query);
      return DevResult(message: tr('Hecho'));
    } on DatabaseException catch (e) {
      throw UserError(sqliteMessage('$e'));
    }
  }

  @override
  String sampleQuery(DevTable t) => 'SELECT * FROM "${t.name}" LIMIT 100';

  @override
  Future<void> close() => db.close();
}

class _Postgres extends DevDb {
  _Postgres(this.conn);
  final pg.Connection conn;

  @override
  Future<List<DevTable>> schema() async {
    final r = await conn.execute(
      "SELECT c.table_schema, c.table_name, t.table_type, c.column_name, c.data_type FROM information_schema.columns c "
      'JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name '
      "WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY 1, 2, c.ordinal_position",
    );
    final out = <String, (String, List<(String, String)>)>{};
    for (final row in r) {
      final schema = '${row[0]}', table = '${row[1]}';
      final name = schema == 'public' ? table : '$schema.$table';
      out
          .putIfAbsent(
            name,
            () => ('${row[2]}' == 'VIEW' ? 'view' : 'table', []),
          )
          .$2
          .add(('${row[3]}', '${row[4]}'));
    }
    return [
      for (final e in out.entries)
        DevTable(e.key, type: e.value.$1, columns: e.value.$2),
    ];
  }

  @override
  Future<DevResult> run(String query) async {
    try {
      final r = await conn.execute(query);
      if (r.schema.columns.isEmpty) {
        return _isDml(query)
            ? DevResult(
                affected: r.affectedRows,
                message: affectedMessage(r.affectedRows),
              )
            : DevResult(message: tr('Hecho'));
      }
      return DevResult(
        columns: [for (final c in r.schema.columns) c.columnName ?? '?'],
        rows: [
          // Tipos que el cliente no conoce (enum, dominios…): su texto.
          for (final row in r)
            [
              for (final v in row)
                DevResult.cell(v is pg.UndecodedBytes ? v.asString : v),
            ],
        ],
      );
    } on pg.PgException catch (e) {
      throw UserError(e.message);
    }
  }

  @override
  String sampleQuery(DevTable t) =>
      'SELECT * FROM ${t.name.split('.').map((p) => '"$p"').join('.')} LIMIT 100';

  @override
  Future<void> close() => conn.close();
}

class _MySql extends DevDb {
  _MySql(this.conn, this.database);
  final MySQLConnection conn;
  final String database;

  @override
  Future<List<DevTable>> schema() async {
    final r = await conn.execute(
      'SELECT c.TABLE_NAME, t.TABLE_TYPE, c.COLUMN_NAME, c.COLUMN_TYPE FROM information_schema.COLUMNS c '
      'JOIN information_schema.TABLES t ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME '
      'WHERE c.TABLE_SCHEMA = DATABASE() ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION',
    );
    final out = <String, (String, List<(String, String)>)>{};
    for (final row in r.rows) {
      out
          .putIfAbsent(
            row.colAt(0) ?? '',
            () =>
                ((row.colAt(1) ?? '').contains('VIEW') ? 'view' : 'table', []),
          )
          .$2
          .add((row.colAt(2) ?? '', row.colAt(3) ?? ''));
    }
    return [
      for (final e in out.entries)
        DevTable(e.key, type: e.value.$1, columns: e.value.$2),
    ];
  }

  @override
  Future<DevResult> run(String query) async {
    try {
      final r = await conn.execute(query);
      final cols = [for (final c in r.cols) c.name];
      if (cols.isEmpty) {
        final n = r.affectedRows.toInt();
        return _isDml(query)
            ? DevResult(affected: n, message: affectedMessage(n))
            : DevResult(message: tr('Hecho'));
      }
      return DevResult(
        columns: cols,
        rows: [
          for (final row in r.rows)
            [for (var i = 0; i < cols.length; i++) row.colAt(i)],
        ],
      );
    } catch (e) {
      throw UserError('$e');
    }
  }

  @override
  String sampleQuery(DevTable t) => 'SELECT * FROM `${t.name}` LIMIT 100';

  @override
  Future<void> close() => conn.close();
}

/// MongoDB: la consulta es un JSON {"collection", "find"|"aggregate"|
/// "insert"|"update"|"delete", "sort", "limit"}.
class _Mongo extends DevDb {
  _Mongo(this.db);
  final mongo.Db db;

  @override
  Future<List<DevTable>> schema() async {
    final names = (await db.getCollectionNames()).whereType<String>().toList()
      ..sort();
    return [
      for (final n in names)
        DevTable(
          n,
          type: 'collection',
          columns: [
            // Campos del primer documento (Mongo no tiene esquema fijo).
            for (final e
                in ((await db.collection(n).findOne()) ??
                        const <String, dynamic>{})
                    .entries)
              (e.key, e.value.runtimeType.toString()),
          ],
        ),
    ];
  }

  @override
  Future<DevResult> run(String query) async {
    final Map spec;
    try {
      spec = jsonDecode(query) as Map;
    } catch (_) {
      throw UserError(
        tr(
          'La consulta de MongoDB es un JSON: {"collection": "clientes", "find": {}}',
        ),
      );
    }
    final name = '${spec['collection'] ?? ''}';
    if (name.isEmpty) {
      throw UserError(tr('Indique la colección («collection»).'));
    }
    final col = db.collection(name);
    Map<String, dynamic> map(Object? v) =>
        v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
    try {
      if (spec['aggregate'] is List) {
        final docs = await col
            .aggregateToStream([
              for (final s in spec['aggregate'] as List)
                map(s).cast<String, Object>(),
            ])
            .take((spec['limit'] as num?)?.toInt() ?? 500)
            .toList();
        return DevResult.fromMaps([
          for (final d in docs) d.cast<String, Object?>(),
        ]);
      }
      if (spec['insert'] != null) {
        final docs = spec['insert'] is List
            ? spec['insert'] as List
            : [spec['insert']];
        for (final d in docs) {
          _check(await col.insertOne(map(d)));
        }
        return DevResult(
          affected: docs.length,
          message: affectedMessage(docs.length),
        );
      }
      if (spec['update'] is List && (spec['update'] as List).length == 2) {
        final u = spec['update'] as List;
        final r = await col.updateMany(map(u[0]), map(u[1]));
        _check(r);
        return DevResult(
          affected: r.nModified,
          message: affectedMessage(r.nModified),
        );
      }
      if (spec['delete'] != null) {
        final r = await col.deleteMany(map(spec['delete']));
        _check(r);
        return DevResult(
          affected: r.nRemoved,
          message: affectedMessage(r.nRemoved),
        );
      }
      if (spec['drop'] == true) {
        await col.drop();
        return DevResult(message: tr('Colección «{0}» borrada', [name]));
      }
      if (spec['createIndex'] is Map) {
        final keys = map(spec['createIndex']);
        await col.createIndex(
          keys: keys,
          unique: spec['unique'] == true ? true : null,
          name: spec['name'] is String ? spec['name'] as String : null,
        );
        return DevResult(message: tr('Índice creado: {0}', [jsonEncode(keys)]));
      }
      if (spec['indexes'] == true) {
        final ix = await col.getIndexes();
        return DevResult.fromMaps([
          for (final i in ix)
            {
              'name': i['name'],
              'key': i['key'],
              if (i['unique'] == true) 'unique': true,
            },
        ]);
      }
      if (spec['count'] == true) {
        final n = await col.count(map(spec['find']));
        return DevResult.fromMaps([
          {'count': n},
        ]);
      }
      if (spec['distinct'] is String) {
        final field = spec['distinct'] as String;
        final r = await col.distinct(field, map(spec['find']));
        return DevResult.fromMaps([
          for (final v in (r['values'] as List? ?? const [])) {field: v},
        ]);
      }
      final docs = await col
          .modernFind(
            filter: map(spec['find']),
            projection: spec['projection'] is Map
                ? map(spec['projection']).cast<String, Object>()
                : null,
            sort: spec['sort'] is Map
                ? map(spec['sort']).cast<String, Object>()
                : null,
            limit: (spec['limit'] as num?)?.toInt() ?? 100,
            skip: (spec['skip'] as num?)?.toInt(),
          )
          .toList();
      return DevResult.fromMaps([
        for (final d in docs) d.cast<String, Object?>(),
      ]);
    } on UserError {
      rethrow;
    } catch (e) {
      throw UserError('$e');
    }
  }

  /// Un error de escritura (clave duplicada, tipo que no vale…): el
  /// servidor no lanza, lo dice en el resultado.
  static void _check(mongo.WriteResult r) {
    if (r.hasWriteErrors || r.hasWriteConcernError) {
      throw UserError(
        r.writeError?.errmsg ?? r.writeConcernError?.errmsg ?? r.errmsg ?? '?',
      );
    }
  }

  @override
  String sampleQuery(DevTable t) =>
      '{"collection": "${t.name}", "find": {}, "limit": 100}';

  @override
  Future<void> close() => db.close();
}

/// Abre una sesión FTP (FTP, FTPS o FTPES).
Future<DevFtp> openDevFtp(Map<String, Object?> c) async {
  final ftp = FTPConnect(
    '${c['host'] ?? ''}'.trim(),
    port: int.tryParse('${c['port'] ?? ''}'),
    user: '${c['user'] ?? ''}'.trim().isEmpty
        ? 'anonymous'
        : '${c['user']}'.trim(),
    pass: '${c['password'] ?? ''}',
    securityType: switch (c['security']) {
      'ftps' => SecurityType.ftps,
      'ftpes' => SecurityType.ftpes,
      _ => SecurityType.ftp,
    },
    timeout: 20,
  );
  try {
    await ftp.connect();
    await ftp.setTransferType(TransferType.binary);
  } catch (e) {
    throw UserError(tr('No se pudo conectar: {0}', [e]));
  }
  return _Ftp(ftp);
}

class _Ftp extends DevFtp {
  _Ftp(this.ftp);
  final FTPConnect ftp;

  Future<T> _do<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw UserError('$e');
    }
  }

  void _ok(bool done, String what) {
    if (!done) throw UserError(tr('El servidor no permitió: {0}', [what]));
  }

  @override
  Future<String> pwd() => _do(ftp.currentDirectory);

  @override
  Future<List<DevFtpEntry>> list() => _do(() async {
    final entries = await ftp.listDirectoryContent();
    return [
      for (final e in entries)
        if (e.name != '.' && e.name != '..')
          DevFtpEntry(
            e.name,
            dir: e.type == FTPEntryType.dir,
            size: e.size,
            modified: e.modifyTime,
          ),
    ]..sort(
      (a, b) => a.dir != b.dir
          ? (a.dir ? -1 : 1)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  });

  @override
  Future<void> cd(String dir) async =>
      _ok(await _do(() => ftp.changeDirectory(dir)), dir);

  @override
  Future<void> upload(String localPath, {String? remoteName}) async => _ok(
    await _do(
      () => ftp.uploadFile(File(localPath), sRemoteName: remoteName ?? ''),
    ),
    localPath,
  );

  @override
  Future<void> download(String remoteName, String localPath) async => _ok(
    await _do(() => ftp.downloadFile(remoteName, File(localPath))),
    remoteName,
  );

  @override
  Future<void> mkdir(String name) async =>
      _ok(await _do(() => ftp.makeDirectory(name)), name);

  @override
  Future<void> delete(DevFtpEntry e) async => _ok(
    await _do(
      () => e.dir ? ftp.deleteDirectory(e.name) : ftp.deleteFile(e.name),
    ),
    e.name,
  );

  @override
  Future<void> rename(String from, String to) async =>
      _ok(await _do(() => ftp.rename(from, to)), from);

  @override
  Future<void> close() async {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
}
