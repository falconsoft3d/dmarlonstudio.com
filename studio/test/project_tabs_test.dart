import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter_test/flutter_test.dart';

StudioProject _p(String path, String name) => StudioProject(
  path: path,
  name: name,
  design: TkDesign(),
  code: 'class Form1(FormDesign):\n    pass\n',
);

void main() {
  test('varios proyectos abiertos, cada uno en su pestaña', () {
    final a = TkProject.open(_p('/tmp/a', 'A'));
    final b = TkProject.open(_p('/tmp/b', 'B'));
    expect(TkProject.opened, [a, b]);
    expect(TkProject.current, b);
    expect(a.isOpen && b.isOpen, isTrue);

    // Lo no guardado de A sigue ahí al volver a abrirlo.
    a.setCode('class Form1(FormDesign):\n    x = 1\n');
    expect(a.dirty, isTrue);
    final again = TkProject.open(_p('/tmp/a', 'A'));
    expect(again, same(a));
    expect(a.dirty, isTrue);
    expect(TkProject.opened, hasLength(2));
    expect(TkProject.current, a);

    // La lista de proyectos no cierra nada.
    TkProject.activate(null);
    expect(TkProject.current, isNull);
    expect(TkProject.opened, hasLength(2));

    // Cerrar la activa pasa a la vecina.
    TkProject.activate(b);
    TkProject.close();
    expect(b.isOpen, isFalse);
    expect(TkProject.current, a);
    TkProject.close(a);
    expect(TkProject.opened, isEmpty);
    expect(TkProject.current, isNull);
  });
}
