import 'dart:io';

import 'package:dmarlon_studio/code/tk_cpp.dart';
import 'package:dmarlon_studio/code/tk_cpp_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  const cpp = CppUnit();

  test('CppUnit: métodos con tipo, cuerpo y renombrar', () {
    var code = cpp.template('Form1', '// hola');
    expect(cpp.hasClass(code, 'Form1'), isTrue);
    expect(cpp.lineOf(code, 'form_create'), 4);
    code = cpp.ensureMethod(code, 'Form1', 'Button1_click');
    expect(code, contains('  void Button1_click() override {\n  }\n};'));
    code = cpp.ensureMethod(code, 'Form1', 'Scale1_change', param: 'value');
    expect(code, contains('void Scale1_change(double value) override {'));
    code = cpp.ensureMethod(code, 'Form1', 'Open_select', param: 'path');
    expect(
      code,
      contains('void Open_select(const std::string& path) override {'),
    );
    code = cpp.setMethodBody(
      code,
      'Form1',
      'Button1_click',
      'Label1->text("}");',
    );
    expect(
      code,
      contains(
        '  void Button1_click() override {\n    Label1->text("}");\n  }',
      ),
    );
    code = cpp.renameWidget(code, 'Label1', 'Title');
    expect(code, contains('Title->text("}")'));
    code = cpp.renameMethod(code, 'Button1_click', 'Ok_click');
    expect(cpp.lineOf(code, 'Ok_click'), isNotNull);
    expect(
      cpp.renameForm(code, 'Form1', 'Main'),
      contains('class Main : public'),
    );
    expect(tkUnitOf(TkDesign(target: tkTargetCpp)), isA<CppUnit>());
    final d = TkDesign(target: tkTargetCpp);
    expect(d.isCpp && !d.isPython && !d.isJs, isTrue);
    expect(d.validName('int'), isFalse);
  });

  test('design.h: métodos virtuales y menú', () {
    final e = tkCppExamples(id).single;
    final files = TkCpp.files(e.design, e.code);
    expect(
      files.keys,
      containsAll(['dms.h', 'design.h', 'main.cpp', 'Form1.cpp', 'Makefile']),
    );
    expect(files['design.h'], contains('virtual void BtnEquals_click() {}'));
    expect(files['main.cpp'], contains('#include "Form1.cpp"'));
    expect(files['Form1.cpp'], e.code);
  });

  Future<String?> build(Map<String, String> files, String dir) async {
    for (final f in files.entries) {
      File(p.join(dir, f.key)).writeAsStringSync(f.value);
    }
    final cxx = TkCppTools.compiler();
    final (cflags, ldflags) = await TkCppTools.flags();
    final r = await Process.run(cxx!, [
      '-std=c++17',
      ...cflags,
      'main.cpp',
      '-o',
      'app',
      ...ldflags,
    ], workingDirectory: dir);
    return r.exitCode == 0 ? null : '${r.stderr}';
  }

  test('de verdad: la calculadora compila con FLTK', () async {
    if (TkCppTools.compiler() == null || TkCppTools.fltkConfig() == null) {
      return markTestSkipped('Sin compilador de C++ o sin FLTK.');
    }
    final tmp = await Directory.systemTemp.createTemp('dms_cpp_');
    addTearDown(() => tmp.delete(recursive: true));
    final e = tkCppExamples(id).single;
    expect(await build(TkCpp.files(e.design, e.code), tmp.path), isNull);
    expect(File(p.join(tmp.path, 'app')).existsSync(), isTrue);
  });

  test('de verdad: compilar y ejecutar desde el estudio', () async {
    if (TkCppTools.compiler() == null || TkCppTools.fltkConfig() == null) {
      return markTestSkipped('Sin compilador de C++ o sin FLTK.');
    }
    final tmp = await Directory.systemTemp.createTemp('dms_cpp_run_');
    addTearDown(() => tmp.delete(recursive: true));
    final d =
        TkDesign(
            width: 300,
            height: 200,
            target: tkTargetCpp,
            events: {'create': 'form_create'},
          )
          ..widgets.addAll([
            TkWidget(
              kind: 'Label',
              name: 'Label1',
              x: 10,
              y: 10,
              width: 200,
              height: 24,
              props: {'text': 'Hola'},
            ),
            TkWidget(
              kind: 'Listbox',
              name: 'List1',
              x: 10,
              y: 40,
              width: 200,
              height: 80,
              props: {'items': 'uno\ndos'},
            ),
            TkWidget(
              kind: 'Timer',
              name: 'Timer1',
              x: 0,
              y: 0,
              width: 24,
              height: 24,
              props: {'interval': 50},
              events: {'command': 'Timer1_timer'},
            ),
          ]);
    const code = '''#include <iostream>

class Form1 : public FormDesign {
public:
  int ticks = 0;

  void form_create() override {
    List1->index(1);
    Label1->text("Elegido: " + List1->selected());
    std::cout << Label1->text() << std::endl;
  }

  void Timer1_timer() override {
    if (++ticks == 3) {
      std::cout << "ticks " << ticks << " " << str(2.5) << std::endl;
      close();
    }
  }
};
''';
    final dir = Directory(p.join(tmp.path, 'build', 'cpp'))
      ..createSync(recursive: true);
    for (final f in TkCpp.files(d, code).entries) {
      File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
    }
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: 'cpp',
        source: code,
        file: p.join(dir.path, 'Form1.cpp'),
        cpp: true,
      ),
    );
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (run.running && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(run.exitCode, 0, reason: run.lines.join('\n'));
    expect(run.lines, containsAll(['Elegido: dos', 'ticks 3 2.5']));
  });

  test('un error de compilación dice su línea de Form1.cpp', () async {
    if (TkCppTools.compiler() == null || TkCppTools.fltkConfig() == null) {
      return markTestSkipped('Sin compilador de C++ o sin FLTK.');
    }
    final tmp = await Directory.systemTemp.createTemp('dms_cpp_err_');
    addTearDown(() => tmp.delete(recursive: true));
    final d = TkDesign(target: tkTargetCpp);
    const code =
        'class Form1 : public FormDesign {\npublic:\n  void form_create() override {\n    nope();\n  }\n};\n';
    final dir = Directory(p.join(tmp.path, 'build', 'cpp'))
      ..createSync(recursive: true);
    for (final f in TkCpp.files(d, code).entries) {
      File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
    }
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: 'err',
        source: code,
        file: p.join(dir.path, 'Form1.cpp'),
        cpp: true,
      ),
    );
    while (run.running) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(run.exitCode, isNot(0));
    expect(
      run.lines.any((l) => l.startsWith('Form1.cpp:4:')),
      isTrue,
      reason: run.lines.join('\n'),
    );
  });
}
