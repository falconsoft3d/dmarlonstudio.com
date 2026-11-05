import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/core/errors.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_test_');
    StudioDb.dirOverride = p.join(tmp.path, 'support');
    ProjectStore.workspaceOverride = p.join(tmp.path, 'ws');
    await StudioDb.open();
  });

  tearDown(() async {
    await StudioDb.close();
    await tmp.delete(recursive: true);
  });

  test('los ejemplos se cargan una vez y generan Python válido', () async {
    final first = await ProjectStore.list();
    expect(first, isNotEmpty);
    expect(await ProjectStore.list(), hasLength(first.length));
    for (final x in first) {
      final src = TkCodegen.generate(x.design, x.code);
      final f = File(p.join(tmp.path, '${ProjectStore.slug(x.name)}.py'));
      await f.writeAsString(src);
      final r = await Process.run('python3', ['-m', 'py_compile', f.path]);
      expect(r.exitCode, 0, reason: '${x.name}: ${r.stderr}');
    }
  });

  test('crear, renombrar la ventana, duplicar y borrar', () async {
    final dir = await ProjectStore.create('Mi App');
    expect(p.basename(dir), 'mi_app');
    var x = (await ProjectStore.get(dir))!;
    expect(File(p.join(dir, 'Form1.py')).existsSync(), isTrue);
    final d = x.design..name = 'Principal';
    await ProjectStore.save(
      dir,
      design: d,
      code: TkUnit.renameForm(x.code, 'Form1', 'Principal'),
    );
    expect(File(p.join(dir, 'Form1.py')).existsSync(), isFalse);
    x = (await ProjectStore.get(dir))!;
    expect(x.design.name, 'Principal');
    expect(x.code, contains('class Principal'));
    final copy = await ProjectStore.duplicate(dir);
    expect(p.basename(copy), 'mi_app_copia');
    final prepared = await ProjectStore.prepareRun(dir);
    expect(File(prepared.file).existsSync(), isTrue);
    await ProjectStore.delete(dir);
    expect(Directory(dir).existsSync(), isFalse);
  });

  test('una conexión sin elegir no se puede generar', () {
    final d = TkDesign()
      ..widgets.add(
        TkWidget(
          kind: 'Connection',
          name: 'Db',
          x: 0,
          y: 0,
          width: 32,
          height: 32,
        ),
      );
    expect(
      () => TkCodegen.generate(d, TkUnit.template(d.name, '')),
      throwsA(isA<UserError>()),
    );
  });
}
