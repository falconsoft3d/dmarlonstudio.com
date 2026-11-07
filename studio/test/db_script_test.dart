// Scripts del módulo Bases de datos: varias consultas en el editor.
import 'package:dmarlon_studio/core/errors.dart';
import 'package:dmarlon_studio/dev/dev_script.dart';
import 'package:dmarlon_studio/dev/dev_types.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDb extends DevDb {
  final ran = <String>[];
  @override
  Future<DevResult> run(String query) async {
    ran.add(query);
    if (query.contains('boom')) throw UserError('falla');
    return DevResult(message: 'ok');
  }

  @override
  Future<List<DevTable>> schema() async => [];
  @override
  String sampleQuery(DevTable t) => '';
  @override
  Future<void> close() async {}
}

void main() {
  test('SQL: separa por «;» sin contar cadenas ni comentarios', () {
    final q = splitScript('sqlite', '''
-- Products
SELECT 'a;b' AS x; /* ; */ SELECT "c;d";
-- fin; sin consulta
''');
    expect(q, ["SELECT 'a;b' AS x", 'SELECT "c;d"']);
  });

  test('SQL: una sola consulta sin «;»', () {
    expect(splitScript('postgres', 'SELECT 1'), ['SELECT 1']);
    expect(splitScript('postgres', '  \n-- nada\n'), isEmpty);
  });

  test('SQLite: el cuerpo de un trigger (con CASE … END) va entero', () {
    final q = splitScript('sqlite', '''
CREATE TRIGGER t AFTER INSERT ON p BEGIN
  UPDATE p SET x = CASE WHEN new.x < 0 THEN 0 ELSE new.x END WHERE id = new.id;
  INSERT INTO log VALUES (new.id);
END;
BEGIN;
SELECT 1;
''');
    expect(q, hasLength(3));
    expect(q[0], endsWith('END'));
    expect(q[1], 'BEGIN');
  });

  test(r'PostgreSQL: los bloques $$ … $$ y $tag$ … $tag$', () {
    final q = splitScript('postgres', r'''
CREATE FUNCTION f() RETURNS int AS $$ BEGIN RETURN 1; END; $$ LANGUAGE plpgsql;
CREATE FUNCTION g() RETURNS text AS $body$ SELECT 'x;y'; $body$ LANGUAGE sql;
SELECT f(), g();
''');
    expect(q, hasLength(3));
    expect(q[0], contains('RETURN 1; END;'));
  });

  test('MySQL: DELIMITER cambia el separador', () {
    final q = splitScript('mysql', '''
DELIMITER //
CREATE PROCEDURE p(OUT n INT)
BEGIN
  SELECT count(*) INTO n FROM t;
END //
DELIMITER ;
CALL p(@n);
SELECT @n;
''');
    expect(q, hasLength(3));
    expect(q[0], startsWith('CREATE PROCEDURE'));
    expect(q[0], contains('INTO n FROM t;'));
    expect(q.last, 'SELECT @n');
  });

  test('MySQL: comillas escapadas y # como comentario', () {
    final q = splitScript('mysql', r"""
# comentario; con punto y coma
SELECT 'it\'s; fine';
SELECT 2;
""");
    expect(q, [r"SELECT 'it\'s; fine'", 'SELECT 2']);
  });

  test('JSON: un objeto tras otro, con comentarios //', () {
    final q = splitScript('mongodb', '''
// Products
{"collection": "p", "find": {"name": "a // b"}}
{"collection": "p",
 "count": true}  // cuántos
''');
    expect(q, hasLength(2));
    expect(q[0], contains('"a // b"'));
    expect(q[1], contains('"count": true'));
  });

  test('isWriteQuery', () {
    expect(isWriteQuery('sqlite', 'SELECT 1'), isFalse);
    expect(isWriteQuery('postgres', 'WITH x AS (SELECT 1) SELECT * FROM x'), isFalse);
    expect(isWriteQuery('postgres', 'WITH d AS (DELETE FROM t RETURNING *) SELECT 1'), isTrue);
    expect(isWriteQuery('sqlite', 'PRAGMA table_info(t)'), isFalse);
    expect(isWriteQuery('sqlite', 'PRAGMA foreign_keys = ON'), isTrue);
    expect(isWriteQuery('sqlite', 'UPDATE t SET a = 1'), isTrue);
    expect(isWriteQuery('falcon', '{"table": "t", "where": {"a": 1}}'), isFalse);
    expect(isWriteQuery('falcon', '{"table": "t", "delete": 3}'), isTrue);
    expect(isWriteQuery('mongodb', '{"collection": "t", "drop": true}'), isTrue);
  });

  test('runScript: para en la que falla y devuelve las anteriores', () async {
    final db = _FakeDb();
    final r = await runScript(db, ['SELECT 1', 'SELECT 2']);
    expect(r, hasLength(2));
    ScriptError? se;
    try {
      await runScript(db, ['SELECT 1', 'boom', 'SELECT 3']);
    } on ScriptError catch (e) {
      se = e;
    }
    expect(se, isNotNull);
    se!;
    expect(se.index, 1);
    expect(se.done, hasLength(1));
    expect(db.ran.last, 'boom');
  });

  test('affectedMessage: singular y plural', () {
    expect(affectedMessage(1), '1 fila afectada');
    expect(affectedMessage(3), '3 filas afectadas');
  });
}
