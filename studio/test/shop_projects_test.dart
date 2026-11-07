// Los proyectos de los cursos de bases de datos de la web: la tienda del
// curso en cada base de datos (lib/code/tk_showcase_shop.dart), y el cliente
// de MongoDB de las ventanas (SqlClient con pymongo).
//
//   flutter test test/shop_projects_test.dart
//       Comprueba los seis proyectos y el SqlClient. Con un MongoDB en
//       127.0.0.1:27027 (DMS_TEST_MONGO=uri) y un Python con pymongo
//       (DMS_PYMONGO_PYTHON, o python3), también contra MongoDB de verdad.
//
//   DMS_SHOP_OUT=<carpeta> DMS_SHOP_CONN=<carpeta> flutter test test/shop_projects_test.dart
//       Además exporta cada proyecto, por curso y por idioma, en
//       <carpeta>/<curso>/<idioma>/: project/ (el proyecto tal como lo guarda
//       el estudio), app.py y env.json (la ventana generada y las variables
//       DMSTUDIO_DB_SHOP_* que le daría el estudio con la conexión
//       DMS_SHOP_CONN/conn_<tipo>.json) o web/ (la app de Flutter, para
//       compilarla). Lo usa landing/scripts/courses/build_projects.py.
import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_flutter_db.dart';
import 'package:dmarlon_studio/code/tk_helpers.dart';
import 'package:dmarlon_studio/code/tk_run_io.dart';
import 'package:dmarlon_studio/code/tk_run_types.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/dev/dev_client.dart';
import 'package:dmarlon_studio/dev/dev_types.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:dmarlon_studio/i18n/tr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

/// El tipo de conexión de cada curso de escritorio.
const desktop = {
  'sqlite': 'sqlite',
  'postgres': 'postgres',
  'mysql': 'mysql',
  'mongodb': 'mongodb',
};

TkPrepared prepared(String kind, Map<String, Object?> conn) => TkPrepared(
  id: '/tmp/shop',
  name: 'shop',
  source: '',
  file: '/tmp/shop/build/shop.py',
  links: [TkDbLink('Shop', 'shop', kind, conn)],
);

/// Un programa de Python con el SqlClient del estudio y [body].
String clientScript(String body) =>
    'import json\nimport os\nimport sys\n\n\n'
    'class DataError(Exception):\n    pass\n'
    '${TkHelpers.sqlClient}\n\n$body\n';

Future<String?> python(String module) async {
  for (final py in [
    Platform.environment['DMS_PYMONGO_PYTHON'],
    'python3',
  ].whereType<String>()) {
    try {
      final r = await Process.run(py, ['-c', 'import $module']);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      continue;
    }
  }
  return null;
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('dms_shop_'));
  tearDown(() => tmp.delete(recursive: true));

  test('los seis proyectos, uno por curso', () {
    final all = tkShopCourseExamples(id);
    expect(all.keys, [
      'sqlite',
      'postgres',
      'mysql',
      'mongodb',
      'falcondatabase',
      'firebase',
    ]);
    final seeds = {
      ...tkExamples(id).map((e) => e.seed),
      ...tkFlutterExamples(id).map((e) => e.seed),
    };
    for (final MapEntry(key: course, value: e) in all.entries) {
      expect(seeds, contains(e.seed), reason: course);
      if (desktop.containsKey(course)) {
        expect(e.design.isPython && !e.design.isWeb, isTrue, reason: course);
        expect(e.design.problems(), isEmpty, reason: course);
        // Una conexión a la guardada «shop» y tres tablas que leen de ella.
        expect([
          for (final c in e.design.connections) c.text('connection'),
        ], ['shop']);
        final grids = e.design.widgets.where((w) => w.kind == 'Treeview');
        expect(grids.length, 3);
        for (final g in grids) {
          expect(g.text('source'), 'Shop');
          expect(g.text('query'), isNotEmpty);
        }
      } else {
        expect(e.design.isFlutter, isTrue, reason: course);
      }
    }
  });

  test('las ventanas generan Python válido', () async {
    for (final course in desktop.keys) {
      final e = tkShopCourseExamples(id)[course]!;
      final f = File(p.join(tmp.path, '$course.py'));
      await f.writeAsString(TkCodegen.generate(e.design, e.code));
      final r = await Process.run('python3', ['-m', 'py_compile', f.path]);
      expect(r.exitCode, 0, reason: '$course: ${r.stderr}');
    }
  });

  test('las consultas de MongoDB son el JSON del módulo Bases de datos', () {
    final e = tkShopCourseExamples(id)['mongodb']!;
    for (final g in e.design.widgets.where((w) => w.kind == 'Treeview')) {
      final spec = jsonDecode(g.text('query')) as Map;
      expect(spec['collection'], isA<String>());
      expect(spec['aggregate'], isA<List>());
    }
  });

  test('las apps de Flutter llevan su base de datos', () {
    final all = tkShopCourseExamples(id);
    final falcon = TkFlutter.files(
      all['falcondatabase']!.design,
      all['falcondatabase']!.code,
    );
    expect(falcon['lib/db.dart'], contains(tkShopFalconRef));
    expect(falcon['lib/db.dart'], contains(tkShopFalconKey));
    expect(falcon['lib/app.dart'], contains("db.table('products')"));
    final fire = TkFlutter.files(
      all['firebase']!.design,
      all['firebase']!.code,
    );
    expect(
      fire['lib/db.dart'],
      contains(
        'Db("$tkShopFirebaseProject", "", "http://$tkShopFirebaseEmulator")',
      ),
    );
  });

  test('Firebase: sin emulador, la nube; con él, su dirección', () {
    const cloud = FlBackend(kind: 'firebase', project: 'p', key: 'k');
    expect(cloud.file(), contains('final db = Db("p", "k");'));
    const emu = FlBackend(
      kind: 'firebase',
      project: 'p',
      url: 'http://localhost:8080/',
    );
    expect(emu.file(), contains('Db("p", "", "http://localhost:8080")'));
  });

  group('MongoDB en las ventanas', () {
    test('el entorno lleva la URI o el servidor', () {
      final uri = TkRunner.environment(
        prepared('mongodb', {'uri': 'mongodb://h:1/shop', 'host': 'x'}),
      );
      expect(uri['DMSTUDIO_DB_SHOP_KIND'], 'mongodb');
      expect(uri['DMSTUDIO_DB_SHOP_URI'], 'mongodb://h:1/shop');
      final host = TkRunner.environment(
        prepared('mongodb', {
          'host': 'db',
          'port': '27018',
          'database': 'shop',
          'user': 'ana',
          'password': 's',
        }),
      );
      expect(host.containsKey('DMSTUDIO_DB_SHOP_URI'), isFalse);
      expect(host['DMSTUDIO_DB_SHOP_HOST'], 'db');
      expect(host['DMSTUDIO_DB_SHOP_PORT'], '27018');
      expect(host['DMSTUDIO_DB_SHOP_DATABASE'], 'shop');
      expect(host['DMSTUDIO_DB_SHOP_PASSWORD'], 's');
      // Lo de siempre no cambia.
      final pg = TkRunner.environment(prepared('postgres', {'uri': 'x'}));
      expect(pg.containsKey('DMSTUDIO_DB_SHOP_URI'), isFalse);
      expect(
        TkRunner.environment(prepared('sqlite', {'path': '/a.db'})),
        {'DMSTUDIO_DB_SHOP_KIND': 'sqlite', 'DMSTUDIO_DB_SHOP_PATH': '/a.db'},
      );
    });

    test('el controlador es pymongo, con el aviso de instalar', () async {
      expect(TkRunner.driverPackage('mongodb'), 'pymongo');
      expect(TkRunner.driverPackage('postgres'), 'psycopg[binary]');
      expect(TkRunner.driverPackage('mysql'), 'pymysql[rsa]');
      const py = TkPython(command: '/nada/python3', help: '');
      expect(
        await TkRunner.missingDriver('mongodb', py),
        '"/nada/python3" -m pip install pymongo',
      );
      expect(ProjectStore.sqlKinds, contains('mongodb'));
    });

    test('los ? del JSON toman los parámetros, sin unir texto', () async {
      final f = File(p.join(tmp.path, 'spec.py'));
      await f.writeAsString(
        clientScript(r'''
spec = SqlClient.mongo_spec(
    '{"collection": "p", "find": {"name": {"$regex": "?"}, "stock": {"$gt": "?"}}}',
    ["a\"b", 3],
)
assert spec["find"] == {"name": {"$regex": 'a"b'}, "stock": {"$gt": 3}}, spec
# Sin parámetros, un "?" es un texto más.
assert SqlClient.mongo_spec({"collection": "p", "find": {"x": "?"}})["find"] == {"x": "?"}
for bad, params in [("{", ()), ('{"collection": "p", "find": {"x": "?"}}', [1, 2]),
                    ('{"collection": "p", "find": {"x": "?", "y": "?"}}', [1])]:
    try:
        SqlClient.mongo_spec(bad, params)
    except DataError:
        pass
    else:
        raise SystemExit("no error: " + bad)
print("ok")
'''),
      );
      final r = await Process.run('python3', [f.path]);
      expect('${r.stdout}${r.stderr}'.trim(), 'ok');
    });

    test('SQLite sigue igual', () async {
      final f = File(p.join(tmp.path, 'sqlite.py'));
      await f.writeAsString(
        clientScript(r'''
db = SqlClient("shop")
db.execute("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)")
assert db.execute("INSERT INTO t (name) VALUES (?), (?)", ("a", "b")) == 2
assert db.query("SELECT name FROM t WHERE name LIKE ? ORDER BY id", ("%b%",)) == [{"name": "b"}]
print("ok")
'''),
      );
      final r = await Process.run(
        'python3',
        [f.path],
        environment: TkRunner.environment(
          prepared('sqlite', {'path': p.join(tmp.path, 'a.db')}),
        ),
      );
      expect('${r.stdout}${r.stderr}'.trim(), 'ok');
    });

    test('de verdad, con pymongo', () async {
      final py = await python('pymongo');
      if (py == null) return markTestSkipped('Sin un Python con pymongo.');
      final uri =
          Platform.environment['DMS_TEST_MONGO'] ??
          'mongodb://127.0.0.1:27027/dms_test_sqlclient';
      final DevDb db;
      try {
        db = await openDevDb('mongodb', {'uri': uri});
      } on Object {
        return markTestSkipped('Sin MongoDB en $uri.');
      }
      try {
        await db.run('{"collection": "items", "drop": true}');
        await db.run(
          jsonEncode({
            'collection': 'items',
            'insert': [
              {'_id': 1, 'name': 'Baguette', 'kind': 'bread', 'price': 1.2},
              {'_id': 2, 'name': 'Croissant', 'kind': 'bread', 'price': 1.5},
              {'_id': 3, 'name': 'Green tea', 'kind': 'tea', 'price': 4.5},
            ],
          }),
        );
        final f = File(p.join(tmp.path, 'mongo.py'));
        await f.writeAsString(
          clientScript(r'''
import re
db = SqlClient("shop")
rows = db.query('{"collection": "items", "find": {"name": {"$regex": "?", "$options": "i"}}, "projection": {"_id": 0, "name": 1}, "sort": {"name": -1}}', (re.escape("a"),))
assert rows == [{"name": "Green tea"}, {"name": "Croissant"}, {"name": "Baguette"}], rows
rows = db.query({"collection": "items", "find": {}, "sort": {"price": -1}, "skip": 1, "limit": 1})
assert [r["_id"] for r in rows] == [2], rows
rows = db.query('{"collection": "items", "aggregate": [{"$group": {"_id": "$kind", "n": {"$sum": 1}}}, {"$sort": {"_id": 1}}]}')
assert rows == [{"_id": "bread", "n": 2}, {"_id": "tea", "n": 1}], rows
assert db.query('{"collection": "items", "count": true, "find": {"kind": "?"}}', ("bread",)) == [{"count": 2}]
assert db.query('{"collection": "items", "distinct": "kind"}') == [{"kind": "bread"}, {"kind": "tea"}]
assert db.execute('{"collection": "items", "insert": {"name": "Rye"}}') == 1
inserted = db.query('{"collection": "items", "find": {"name": "Rye"}}')[0]
assert isinstance(inserted["_id"], str), inserted
assert db.execute('{"collection": "items", "update": [{"kind": "?"}, {"$set": {"fresh": true}}]}', ("bread",)) == 2
assert db.execute({"collection": "items", "delete": {"name": "Rye"}}) == 1
assert db.run('{"collection": "items", "count": true}') == [{"count": 3}]
try:
    db.query('{"collection": "items", "aggregate": [{"$nope": 1}]}')
except DataError:
    pass
else:
    raise SystemExit("no error")
print("ok")
'''),
        );
        final r = await Process.run(
          py,
          [f.path],
          environment: TkRunner.environment(prepared('mongodb', {'uri': uri})),
        );
        expect('${r.stdout}${r.stderr}'.trim(), 'ok');
      } finally {
        await db.run('{"collection": "items", "drop": true}');
        await db.close();
      }
    });
  });

  // ------------------------------------------------------------ exportar
  final out = Platform.environment['DMS_SHOP_OUT'];
  final conns = Platform.environment['DMS_SHOP_CONN'];
  test('exportar los proyectos', () async {
    for (final lang in ['es', 'en']) {
      setCatalog(
        lang == 'es'
            ? {}
            : catalogOf(File('assets/i18n/$lang.po').readAsStringSync()),
      );
      for (final MapEntry(key: course, value: e)
          in tkShopCourseExamples(tr).entries) {
        final dir = Directory(p.join(out!, course, lang));
        if (dir.existsSync()) await dir.delete(recursive: true);
        await dir.create(recursive: true);
        // El proyecto tal como lo guarda el estudio.
        final project = await ProjectStore.create(
          e.name,
          description: e.description,
          design: e.design,
          code: e.code,
          seed: e.seed,
          parent: p.join(dir.path, 'project'),
          sub: true,
        );
        final unit = ProjectStore.unitPath(project, e.design);
        final kind = desktop[course];
        if (kind != null) {
          await File(
            p.join(dir.path, 'app.py'),
          ).writeAsString(TkCodegen.generate(e.design, e.code));
          final conn = File(p.join(conns!, 'conn_$kind.json'));
          final env = TkRunner.environment(
            prepared(
              kind,
              (jsonDecode(conn.readAsStringSync()) as Map)
                  .cast<String, Object?>(),
            ),
          );
          await File(
            p.join(dir.path, 'env.json'),
          ).writeAsString(jsonEncode(env));
        } else {
          // Para fotografiarla: Firebase, con el emulador y el proyecto de
          // DMS_SHOP_CONN/conn_firebase.json.
          final design = e.design;
          if (course == 'firebase') {
            final c =
                jsonDecode(
                      File(
                        p.join(conns!, 'conn_firebase.json'),
                      ).readAsStringSync(),
                    )
                    as Map;
            final app = FlApp.of(design);
            app.backend = app.backend.copyWith(
              url: '${c['emulator']}',
              project: '${c['project']}',
            );
            app.saveTo(design);
          }
          final files = TkFlutter.files(design, e.code, name: 'dms_${e.seed}');
          for (final f in files.entries) {
            final file = File(p.join(dir.path, 'web', f.key));
            await file.parent.create(recursive: true);
            await file.writeAsString(f.value);
          }
        }
        await File(p.join(dir.path, 'meta.json')).writeAsString(
          jsonEncode({
            'course': course,
            'seed': e.seed,
            'name': e.name,
            'kind': kind ?? 'flutter',
            'folder': p.basename(project),
            'unit': p.relative(unit, from: project),
            'code': e.code,
          }),
        );
      }
    }
    setCatalog({});
  }, skip: out == null || conns == null);
}
