import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_pascal.dart';
import 'package:dmarlon_studio/code/tk_pascal_run.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/code/tk_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  const pas = PascalUnit();

  test('PascalUnit: declarar, implementar, cuerpo y renombrar', () {
    var code = pas.template('Form1', '// hola');
    expect(pas.hasClass(code, 'Form1'), isTrue);
    expect(pas.lineOf(code, 'form_create'), 19);
    code = pas.ensureMethod(code, 'Form1', 'Button1_click');
    expect(code, contains('    procedure Button1_click; override;\n  end;'));
    expect(
      code,
      contains('procedure TForm1.Button1_click;\nbegin\nend;\n\nend.\n'),
    );
    code = pas.ensureMethod(code, 'Form1', 'Scale1_change', param: 'value');
    expect(code, contains('procedure Scale1_change(Value: Double); override;'));
    expect(code, contains('procedure TForm1.Scale1_change(Value: Double);'));
    code = pas.ensureMethod(code, 'Form1', 'Open_select', param: 'path');
    expect(code, contains('procedure TForm1.Open_select(const Path: string);'));
    code = pas.setMethodBody(
      code,
      'Form1',
      'Button1_click',
      "if True then\nbegin\n  Label1.Caption := 'end;';\nend;",
    );
    expect(
      code,
      contains(
        "procedure TForm1.Button1_click;\nbegin\n  if True then\n  begin\n"
        "    Label1.Caption := 'end;';\n  end;\nend;",
      ),
    );
    // Cambiar otra vez el cuerpo (con begin/end dentro) no se lleva nada más.
    code = pas.setMethodBody(code, 'Form1', 'Button1_click', 'Close;');
    expect(
      code,
      contains('procedure TForm1.Button1_click;\nbegin\n  Close;\nend;'),
    );
    expect(code, contains('procedure TForm1.Scale1_change'));
    code = pas.renameWidget(code, 'Label1', 'Title');
    code = pas.setMethodBody(
      code,
      'Form1',
      'Button1_click',
      "Label1.Caption := 'x';",
    );
    expect(
      pas.renameWidget(code, 'Label1', 'Title'),
      contains('Title.Caption'),
    );
    code = pas.renameMethod(code, 'Button1_click', 'Ok_click');
    expect(pas.lineOf(code, 'Ok_click'), isNotNull);
    expect(code, contains('procedure Ok_click; override;'));
    final main = pas.renameForm(code, 'Form1', 'Main');
    expect(main, contains('unit Main;'));
    expect(main, contains('TMain = class(TFormDesign)'));
    expect(main, contains('procedure TMain.Ok_click;'));
    expect(tkUnitOf(TkDesign(target: tkTargetPascal)), isA<PascalUnit>());
    final d = TkDesign(target: tkTargetPascal);
    expect(d.isPascal && !d.isPython && !d.isJs && !d.isCpp, isTrue);
    expect(d.validName('Begin'), isFalse);
    expect(d.validName('Caption'), isFalse);
    expect(d.validName('Label1'), isTrue);
  });

  test('cadenas de Pascal', () {
    expect(TkPascal.str(''), "''");
    expect(TkPascal.str("it's"), "'it''s'");
    expect(TkPascal.str("a'\nb"), "'a'''#10'b'");
    expect(TkPascal.str('a\n'), "'a'#10");
  });

  test('design.pas: métodos virtuales, eventos y menú', () {
    final e = tkPascalExamples(id).single;
    final files = TkPascal.files(e.design, e.code);
    expect(
      files.keys,
      containsAll(['dms.pas', 'design.pas', 'Form1.pas', 'app.lpr', 'app.lpi']),
    );
    expect(
      files['design.pas'],
      contains('procedure BtnEquals_click; virtual;'),
    );
    expect(
      files['design.pas'],
      contains('BtnEquals.OnClick := @dms_BtnEquals_command;'),
    );
    expect(files['app.lpr'], contains('Application.CreateForm(TForm1, F);'));
    expect(files['Form1.pas'], e.code);
  });

  Future<TkRun> start(TkDesign d, String code) async {
    final tmp = await Directory.systemTemp.createTemp('dms_pas_');
    addTearDown(() => tmp.delete(recursive: true));
    final dir = Directory(p.join(tmp.path, 'build', 'pascal'))
      ..createSync(recursive: true);
    final files = TkPascal.files(
      d,
      code,
      options: await TkPascalTools.options(),
    );
    for (final f in files.entries) {
      File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
    }
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: 'pascal',
        source: code,
        file: p.join(dir.path, '${d.name}.pas'),
        pascal: true,
      ),
    );
    final end = DateTime.now().add(const Duration(minutes: 4));
    while (run.running && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return run;
  }

  test(
    'de verdad: la calculadora compila con Lazarus',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final e = tkPascalExamples(id).single;
      // Se cierra sola al abrir: solo interesa que compile.
      final code = e.code.replaceFirst(
        'procedure TForm1.form_create;\nbegin\n  Clear;',
        'procedure TForm1.form_create;\nbegin\n  Clear;\n  Digit(\'7\'); Operate(\'*\'); Digit(\'6\'); Compute;\n  WriteLn(Display.Caption);\n  Application.Terminate;',
      );
      final run = await start(e.design, code);
      expect(run.exitCode, 0, reason: run.lines.join('\n'));
      expect(run.lines, contains('42'));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'de verdad: componentes, temporizador y lista',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final d =
          TkDesign(
              name: 'Main',
              width: 300,
              height: 200,
              target: tkTargetPascal,
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
                props: {'text': "Hola 'ñ'"},
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
      var code = const PascalUnit().template('Main', '// prueba');
      code = const PascalUnit().setMethodBody(
        code,
        'Main',
        'form_create',
        "List1.ItemIndex := 1;\nLabel1.Caption := 'Elegido: ' + List1.Items[List1.ItemIndex];\nWriteLn(Label1.Caption);",
      );
      code = const PascalUnit().ensureMethod(
        code,
        'Main',
        'Timer1_timer',
        body:
            "Inc(Ticks);\nif Ticks = 3 then\nbegin\n  WriteLn('ticks ', Ticks, ' ', NumToStr(2.5));\n  Close;\nend;",
      );
      code = code.replaceFirst('  public\n', '  public\n    Ticks: Integer;\n');
      final run = await start(d, code);
      expect(run.exitCode, 0, reason: run.lines.join('\n'));
      expect(run.lines, containsAll(['Elegido: dos', 'ticks 3 2.5']));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'un error de compilación dice su línea de Form1.pas',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final d = TkDesign(target: tkTargetPascal);
      final code = const PascalUnit()
          .template('Form1', '// error')
          .replaceFirst('begin\nend;', 'begin\n  Nope;\nend;');
      final run = await start(d, code);
      expect(run.exitCode, isNot(0));
      expect(
        run.lines.any((l) => l.startsWith('Form1.pas(22,')),
        isTrue,
        reason: run.lines.join('\n'),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
