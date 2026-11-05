import 'package:dmarlon_studio/code/component_clipboard.dart';
import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const source = '''
class Form1(FormDesign):
    def Button1_click(self):
        total = self.helper(2)
        if total > 1:
            self.Label1.configure(text=str(total))

    def helper(self, n):
        return n * 2
''';

  test('extrae un método con su cuerpo sin sangría', () {
    final m = ComponentClip.methodOf(source, 'Button1_click')!;
    expect(m.def, 'def Button1_click(self):');
    expect(m.body.split('\n').first, 'total = self.helper(2)');
    expect(m.body, contains('\n    self.Label1.configure'));
    expect(ComponentClip.methodOf(source, 'no_existe'), isNull);
  });

  test('viaja por el portapapeles y se añade a otra unidad', () {
    final clip = ComponentClip(
      [
        {
          'kind': 'Button',
          'name': 'Button1',
          'events': {'click': 'Button1_click'},
        },
      ],
      {'Button1_click': ComponentClip.methodOf(source, 'Button1_click')!},
    );
    final back = ComponentClip.decode(clip.encode())!;
    expect(back.widgets.single['name'], 'Button1');
    expect(ComponentClip.decode('texto cualquiera'), isNull);
    expect(ComponentClip.decode('{"a": 1}'), isNull);

    // En otro proyecto, con otro nombre y otra ventana.
    final target = TkUnit.template('Ventana', '# Otro proyecto');
    final m = back.methods['Button1_click']!;
    final code = ComponentClip.addMethod(
      target,
      'Ventana',
      'Button1_click',
      'Button3_click',
      (def: m.def, body: TkUnit.renameWidget(m.body, 'Label1', 'Label4')),
    );
    expect(code, contains('def Button3_click(self):'));
    expect(code, contains('self.Label4.configure(text=str(total))'));
    expect(
      ComponentClip.methodOf(code, 'Button3_click')!.body,
      m.body.replaceAll('Label1', 'Label4'),
    );
  });
}
