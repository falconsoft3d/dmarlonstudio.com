import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const py = TkPython(
    command: '/py/bin/python3',
    args: ['-X', 'utf8'],
    help: '',
  );

  tearDown(() {
    TkRunner.moduleOverride = null;
    TkRunner.installOverride = null;
  });

  test('la orden de pip cita los extras', () {
    expect(
      TkRunner.pipCommand(py, ['flask']),
      '"/py/bin/python3" -X utf8 -m pip install flask',
    );
    expect(
      TkRunner.pipCommand(py, ['psycopg[binary]', 'x']),
      '"/py/bin/python3" -X utf8 -m pip install "psycopg[binary]" x',
    );
  });

  test('needs: lo que falta, en orden, y la bandeja es opcional', () async {
    TkRunner.moduleOverride = (m) async => false;
    const prepared = TkPrepared(
      id: '/p',
      name: 'p',
      source: '',
      file: '/p/build/p.py',
      web: true,
      ai: true,
      tray: true,
    );
    final needs = await TkRunner.needs(prepared, py);
    expect(needs.map((n) => n.packages), [
      ['flask'],
      ['anthropic'],
      ['pystray', 'pillow'],
    ]);
    expect(needs.map((n) => n.optional), [false, false, true]);
    expect(needs[1].command, contains('-m pip install anthropic'));
    TkRunner.moduleOverride = (m) async => true;
    expect(await TkRunner.needs(prepared, py), isEmpty);
  });

  test('install usa el Python del proyecto', () async {
    final calls = <List<String>>[];
    TkRunner.installOverride = (p, packages) async {
      calls.add([p.command!, ...packages]);
      return 'ok';
    };
    expect(await TkRunner.install(py, ['anthropic']), 'ok');
    expect(calls, [
      ['/py/bin/python3', 'anthropic'],
    ]);
  });
}
