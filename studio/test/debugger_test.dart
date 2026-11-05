import 'dart:io';

import 'package:dmarlon_studio/code/tk_debug.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Dos líneas de «código generado» y después el del usuario (líneas 1-20).
const _head = '# generado\nGENERATED = True\n';
const _unit = '''def double(x):
    return x * 2


class Form1:
    def __init__(self):
        self.total = 0
        self.items = [1, 2, 3]

    def add(self, n):
        value = double(n)
        self.total += value
        return self.total

    def run(self):
        for i in self.items:
            self.add(i)
        print("total", self.total)
        raise ValueError("boom")
    # fin''';
const _main = '\n\nif __name__ == "__main__":\n    Form1().run()\n';

Future<String?> _python() async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
    '/opt/homebrew/bin/python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, ['-c', 'import sys']);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

Future<void> _until(bool Function() ok, {int seconds = 15}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!ok()) {
    if (DateTime.now().isAfter(end)) fail('Tiempo agotado.');
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  late Directory tmp;
  late TkPrepared prepared;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_debug_');
    final file = p.join(tmp.path, 'build', 'app.py');
    final source = '$_head$_unit$_main';
    await File(file).create(recursive: true);
    await File(file).writeAsString(source);
    prepared = TkPrepared(
      id: tmp.path,
      name: 'debug',
      source: source,
      file: file,
      unitStart: 2,
      unitLines: _unit.split('\n').length,
    );
  });

  tearDown(() async {
    TkBreakpoints.clear(tmp.path);
    await tmp.delete(recursive: true);
  });

  test('puntos de parada, pasos, variables, evaluar y excepciones', () async {
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python.');
    TkRunner.python = TkPython(command: py, help: '', tk: '8.6');
    TkBreakpoints.toggle(tmp.path, 12);
    TkBreakpoints.setCondition(tmp.path, 12, 'n == 2');
    final s = TkDebugSession(
      project: tmp.path,
      unitStart: prepared.unitStart,
      unitLines: prepared.unitLines,
    );
    final run = await TkRunner.start(prepared, debug: s);
    expect(run.debug, same(s));
    await _until(() => s.paused);
    expect(s.reason, 'breakpoint');
    expect(s.currentLine, 12);
    expect(s.frames.map((f) => f.func).take(3), ['add', 'run', '<module>']);
    await _until(() => s.locals.isNotEmpty);
    expect(s.locals.firstWhere((v) => v.name == 'n').value, '2');
    final self = s.locals.firstWhere((v) => v.name == 'self');
    final fields = await s.children(self.ref!);
    expect(fields.map((v) => v.name), containsAll(['total', 'items']));
    expect((await s.evaluate('value + 1')).result, '5');
    await s.evaluate('value = 100');
    expect((await s.evaluate('nope')).ok, isFalse);

    s.stepOver();
    await _until(() => s.paused && s.currentLine == 13);
    s.stepOut();
    await _until(() => s.paused && s.frames.first.func == 'run');

    // Seleccionar otro marco cambia las variables.
    s.selectFrame(1);
    await _until(() => s.locals.any((v) => v.name == 'i') == false);

    TkBreakpoints.clear(tmp.path);
    s.sendBreakpoints();
    s.resume();
    await _until(() => s.paused && s.reason == 'exception');
    expect(s.exception?['text'], 'ValueError: boom');
    expect(s.currentLine, 19);
    expect((await s.evaluate('self.total')).result, '108');

    final history = await s.history();
    expect(history.map((h) => h.line), contains(12));
    final flow = await s.flow();
    expect(
      flow.where((f) => f.kind == 'call' && f.func == 'add'),
      hasLength(3),
    );
    final (funcs, lines) = await s.stats();
    expect(funcs.firstWhere((f) => f.func == 'add').calls, 3);
    expect(lines, isNotEmpty);
    expect(await s.objects(), contains(('Form1', 1)));

    s.resume();
    await _until(() => !run.running && s.ended);
    expect(run.exitCode, 1);
    expect(run.lines, contains('total 108'));
  });

  test('pausar un programa en marcha', () async {
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python.');
    TkRunner.python = TkPython(command: py, help: '', tk: '8.6');
    const unit =
        'import time\n\n\nclass Form1:\n    def run(self):\n'
        '        n = 0\n        while True:\n            n += 1\n'
        '            time.sleep(0.01)';
    final source = '$_head$unit$_main';
    await File(prepared.file).writeAsString(source);
    final x = TkPrepared(
      id: tmp.path,
      name: 'loop',
      source: source,
      file: prepared.file,
      unitStart: 2,
      unitLines: unit.split('\n').length,
    );
    final s = TkDebugSession(
      project: tmp.path,
      unitStart: 2,
      unitLines: x.unitLines,
    );
    final run = await TkRunner.start(x, debug: s);
    await _until(() => s.connected);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    s.pause();
    await _until(() => s.paused);
    expect(s.reason, 'pause');
    expect([8, 9, 7], contains(s.currentLine));
    s.runTo(9);
    await _until(() => s.paused && s.reason == 'cursor');
    expect(s.currentLine, 9);
    run.stop();
    await _until(() => s.ended);
  });

  test('pruebas de unittest, sin y con el depurador', () async {
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python.');
    TkRunner.python = TkPython(command: py, help: '', tk: '8.6');
    final tests = Directory(TkRunner.testsDir(tmp.path))..createSync();
    File(p.join(tests.path, 'test_form1.py')).writeAsStringSync('''
import unittest

from dms_app import Form1


class TestForm1(unittest.TestCase):
    def test_add(self):
        f = Form1()
        self.assertEqual(f.add(2), 4)

    def test_wrong(self):
        self.assertEqual(Form1().add(1), 3)

    @unittest.skip("luego")
    def test_later(self):
        pass
''');
    final s = TkDebugSession(
      project: tmp.path,
      unitStart: 2,
      unitLines: prepared.unitLines,
      tests: true,
      trace: false,
    );
    final run = await TkRunner.start(prepared, debug: s);
    await _until(() => !run.running && s.ended);
    expect(s.testSummary?['run'], 3);
    expect(s.testSummary?['failures'], 1);
    final byName = {for (final t in s.testResults) t.name.split('.').last: t};
    expect(byName['test_add']?.status, 'ok');
    expect(byName['test_wrong']?.status, 'fail');
    expect(byName['test_wrong']?.message, contains('AssertionError'));
    expect(byName['test_later']?.status, 'skip');

    // Depurar las pruebas: se detiene en el código del usuario.
    TkBreakpoints.toggle(tmp.path, 12);
    final d = TkDebugSession(
      project: tmp.path,
      unitStart: 2,
      unitLines: prepared.unitLines,
      tests: true,
    );
    final run2 = await TkRunner.start(prepared, debug: d);
    await _until(() => d.paused);
    expect(d.currentLine, 12);
    expect(d.frames.any((f) => f.func.startsWith('test_')), isTrue);
    TkBreakpoints.clear(tmp.path);
    d.sendBreakpoints();
    d.resume();
    await _until(() => !run2.running && d.ended);
    expect(d.testSummary?['run'], 3);
  });
}
