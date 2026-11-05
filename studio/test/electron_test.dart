import 'dart:io';

import 'package:dmarlon_studio/code/tk_electron.dart';
import 'package:dmarlon_studio/code/tk_electron_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

TkExample example(String seed) =>
    tkElectronExamples(id).firstWhere((e) => e.seed == seed);

Future<String?> _node() async {
  for (final n in ['/opt/homebrew/bin/node', '/usr/local/bin/node', 'node']) {
    try {
      final r = await Process.run(n, ['--version']);
      if (r.exitCode == 0) return n;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

void main() {
  const js = JsUnit();

  test('JsUnit: plantilla, métodos y renombrar', () {
    var code = js.template('Form1', '// hola');
    expect(js.hasClass(code, 'Form1'), isTrue);
    expect(js.lineOf(code, 'form_create'), 3);
    code = js.ensureMethod(code, 'Form1', 'Button1_click');
    expect(code, contains('  Button1_click() {\n  }\n}'));
    code = js.ensureMethod(code, 'Form1', 'Entry1_return', param: 'event');
    expect(code, contains('Entry1_return(event) {'));
    // Sin repetir.
    expect(js.ensureMethod(code, 'Form1', 'Button1_click'), code);
    code = js.setMethodBody(
      code,
      'Form1',
      'Button1_click',
      'this.Label1.text = "{ no es una llave }";\nthis.go();',
    );
    expect(
      code,
      contains(
        '  Button1_click() {\n    this.Label1.text = "{ no es una llave }";\n    this.go();\n  }',
      ),
    );
    // Las llaves de las cadenas y los comentarios no cuentan.
    code = js.ensureMethod(code, 'Form1', 'After');
    expect(code.trimRight(), endsWith('  After() {\n  }\n}'));
    code = js.renameWidget(code, 'Label1', 'Title');
    expect(code, contains('this.Title.text'));
    code = js.renameMethod(code, 'Button1_click', 'BtnOk_click');
    expect(js.lineOf(code, 'BtnOk_click'), isNotNull);
    expect(js.renameForm(code, 'Form1', 'Main'), contains('class Main extends'));
    // Sin la clase, la crea.
    expect(
      js.ensureMethod('', 'Form1', 'x'),
      'class Form1 extends FormDesign {\n  x() {\n  }\n}\n',
    );
    const tricky = 'a = "}" // {\n/* { */ `x \${ {} } y` + b';
    final masked = JsUnit.mask(tricky);
    expect(masked.length, tricky.length);
    expect(masked.contains('{') || masked.contains('}'), isFalse);
    expect(masked, startsWith('a = " "'));
    expect(masked, endsWith('` + b'));
    expect(tkUnitOf(TkDesign(target: tkTargetElectron)), isA<JsUnit>());
    expect(tkUnitOf(TkDesign()), isA<PyUnit>());
  });

  test('puntos de parada como debugger; en la misma línea', () {
    const code = 'class Form1 extends FormDesign {\n'
        '  go(n) {\n'
        '    const x = {\n'
        '      a: 1,\n'
        '    };\n'
        '    if (n > 1) {\n'
        '      this.total = n;\n'
        '    } else {\n'
        '      this.total = 0;\n'
        '    }\n'
        '  }\n'
        '}\n';
    final out = TkElectron.withBreakpoints(code, {
      2: '', 3: '', 4: '', 7: 'n > 5', 8: '',
    });
    final lines = out.split('\n');
    expect(lines.length, code.split('\n').length);
    expect(lines[1], '  go(n) {');
    expect(lines[2], '    debugger; const x = {');
    expect(lines[3], '      a: 1,');
    expect(lines[6], '      if (n > 5) debugger; this.total = n;');
    expect(lines[7], '    } else {');
  });

  test('el diseño: componentes que aún no hay y nombres de JavaScript', () {
    final d = TkDesign(target: tkTargetElectron)
      ..widgets.add(
        TkWidget(kind: 'Chart', name: 'Chart1', x: 0, y: 0, width: 10, height: 10),
      );
    expect(d.problems().single, contains('Electron'));
    expect(TkDesign(target: tkTargetElectron).validName('class'), isFalse);
    final round = TkDesign.parse(TkDesign(target: tkTargetElectron).toJsonString());
    expect(round.isElectron, isTrue);
  });

  test('los ejemplos generan JavaScript válido', () async {
    final node = await _node();
    final tmp = await Directory.systemTemp.createTemp('dms_electron_js_');
    addTearDown(() => tmp.delete(recursive: true));
    for (final e in tkElectronExamples(id)) {
      expect(e.design.isElectron, isTrue, reason: e.seed);
      expect(e.design.problems(), isEmpty, reason: e.seed);
      final files = TkElectron.files(e.design, e.code, name: e.name);
      expect(files.keys, containsAll(['main.js', 'index.html', 'Form1.js']));
      if (node == null) continue;
      for (final f in files.entries.where((f) => f.key.endsWith('.js'))) {
        final path = p.join(tmp.path, '${e.seed}_${f.key}');
        await File(path).writeAsString(f.value);
        final r = await Process.run(node, ['--check', path]);
        expect(r.exitCode, 0, reason: '${e.seed}/${f.key}: ${r.stderr}');
      }
    }
  });

  test('de verdad en Electron: la calculadora', () async {
    final runtime = Platform.environment['DMS_ELECTRON_RUNTIME'];
    if (runtime == null || !Directory(runtime).existsSync()) {
      return markTestSkipped('Sin DMS_ELECTRON_RUNTIME (Electron y React).');
    }
    TkElectronRuntime.dirOverride = runtime;
    final tmp = await Directory.systemTemp.createTemp('dms_electron_run_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = example('electron_calculator');
    final out = Directory(p.join(tmp.path, 'build', 'electron'))
      ..createSync(recursive: true);
    for (final f in TkElectron.files(e.design, e.code, name: e.name).entries) {
      File(p.join(out.path, f.key)).writeAsStringSync(f.value);
    }
    final script = File(p.join(tmp.path, 'check.js'))..writeAsStringSync('''
(async () => {
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  const click = (id) => document.getElementById(id).click();
  const key = (k) => document.dispatchEvent(new KeyboardEvent("keydown", { key: k, bubbles: true }));
  const shown = () => document.getElementById("Display").textContent;
  await wait(50);
  const out = { start: shown() };
  for (const id of ["Btn1", "Btn2", "BtnAdd", "Btn3", "BtnEquals"]) { click(id); await wait(10); }
  out.sum = shown();
  for (const k of ["Escape", "7", "*", "6", "Enter"]) { key(k); await wait(10); }
  out.keys = shown();
  for (const id of ["Btn1", "BtnDiv", "Btn0", "BtnEquals"]) { click(id); await wait(10); }
  out.error = shown();
  click("BtnClear"); await wait(10);
  for (const id of ["Btn1", "BtnDiv", "Btn3", "BtnEquals"]) { click(id); await wait(10); }
  out.third = shown();
  out.title = document.title;
  return out;
})()
''');
    TkElectronRuntime.extraEnv = {'DMSTUDIO_ELECTRON_TEST': script.path};
    addTearDown(() => TkElectronRuntime.extraEnv = const {});
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: e.name,
        source: e.code,
        file: p.join(out.path, 'Form1.js'),
        electron: true,
      ),
    );
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (run.running && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final line = run.lines.firstWhere(
      (l) => l.startsWith('DMSTUDIO_TEST '),
      orElse: () => run.lines.join('\n'),
    );
    expect(line, startsWith('DMSTUDIO_TEST '));
    expect(
      line,
      'DMSTUDIO_TEST {"start":"0","sum":"15","keys":"42","error":"Error",'
      '"third":"0.333333333333333","title":"Calculadora"}',
    );
    expect(run.exitCode, 0);
  });
}
