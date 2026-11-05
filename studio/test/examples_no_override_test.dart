import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Ningún ejemplo tapa un método de FormDesign: el lanzador llama a
/// `Form1().run()` y un `run` propio (u otro) rompe la ventana al abrirla.
const _check = r'''
import ast, json, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
classes = {n.name: n for n in tree.body if isinstance(n, ast.ClassDef)}
def methods(c):
    return {f.name for f in c.body if isinstance(f, (ast.FunctionDef, ast.AsyncFunctionDef))}
base = methods(classes["FormDesign"]) if "FormDesign" in classes else set()
mine = methods(classes["Form1"]) if "Form1" in classes else set()
# __init__ propio es válido: la ventana ya existe (se crea en __new__).
handlers = set(json.loads(sys.argv[2]))
clash = sorted((base & mine) - {"__init__"} - handlers)
print(json.dumps(clash))
''';

void main() {
  test('ningún ejemplo redefine métodos de FormDesign', () async {
    final tmp = await Directory.systemTemp.createTemp('dms_override_');
    addTearDown(() => tmp.delete(recursive: true));
    final problems = <String>[];
    for (final e in [...tkExamples((s) => s), ...tkWebExamples((s) => s)]) {
      final path = p.join(tmp.path, '${e.seed}.py');
      await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
      // Los métodos de los eventos del diseño sí se redefinen.
      final handlers = {
        ...e.design.events.values,
        for (final w in e.design.widgets) ...w.events.values,
      };
      final r = await Process.run('python3', [
        '-c',
        _check,
        path,
        jsonEncode(handlers.toList()),
      ]);
      expect(r.exitCode, 0, reason: '${e.seed}: ${r.stderr}');
      final out = '${r.stdout}'.trim();
      if (out != '[]') problems.add('${e.seed}: $out');
    }
    expect(problems, isEmpty);
  });
}
