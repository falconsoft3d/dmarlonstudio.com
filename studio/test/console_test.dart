import 'dart:io';

import 'package:dmarlon_studio/code/tk_console.dart';
import 'package:dmarlon_studio/code/tk_cpp_run.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Programas que preguntan un nombre y dos números, y escriben el saludo y
/// la suma: la pregunta sin salto de línea, como en un terminal.
const _programs = {
  'py': '''name = input("Nombre? ")
a = int(input("A? "))
b = int(input("B? "))
print(f"Hola, {name}. Suma: {a + b}")
''',
  'c': '''#include <stdio.h>
#include <string.h>

int main(void) {
  char name[64];
  int a, b;
  printf("Nombre? ");
  fgets(name, sizeof name, stdin);
  name[strcspn(name, "\\n")] = 0;
  printf("A? ");
  scanf("%d", &a);
  printf("B? ");
  scanf("%d", &b);
  printf("Hola, %s. Suma: %d\\n", name, a + b);
  return 0;
}
''',
  'cpp': '''#include <iostream>
#include <string>

int main() {
  std::string name;
  int a, b;
  std::cout << "Nombre? ";
  std::getline(std::cin, name);
  std::cout << "A? ";
  std::cin >> a;
  std::cout << "B? ";
  std::cin >> b;
  std::cout << "Hola, " << name << ". Suma: " << a + b << std::endl;
}
''',
  'pas': '''program main;

{\$mode objfpc}{\$H+}

var
  Name: string;
  A, B: Integer;

begin
  Write('Nombre? ');
  ReadLn(Name);
  Write('A? ');
  ReadLn(A);
  Write('B? ');
  ReadLn(B);
  WriteLn('Hola, ', Name, '. Suma: ', A + B);
end.
''',
};

bool _can(String lang) => switch (lang) {
  'c' || 'cpp' => TkCppTools.compiler() != null,
  'pas' => TkConsole.fpc() != null,
  _ => true,
};

String _last(TkRun run) => run.lines.isEmpty ? '' : run.lines.last;

Future<void> _wait(TkRun run, bool Function() ok) async {
  final end = DateTime.now().add(const Duration(minutes: 2));
  while (!ok() && run.running && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test('una línea a medias se completa con lo que escribe el usuario', () {
    final run = TkRun('x', 'x', () {})..input = (_) {};
    run.addText('Hola\nNombre? ');
    expect(run.lines, ['Hola', 'Nombre? ']);
    run.send('Ana');
    expect(run.lines, ['Hola', 'Nombre? Ana']);
    run.addText('Bien');
    run.addText(', Ana\n');
    expect(run.lines.last, 'Bien, Ana');
  });

  test('las plantillas compilan y saludan', () {
    for (final lang in ['py', 'c', 'cpp', 'pas']) {
      expect(TkConsole.template(lang), isNotEmpty);
    }
    final d = TkDesign(target: tkTargetConsoleCpp);
    expect(d.isConsole && !d.isPython && !d.isCpp, isTrue);
    expect(d.codeLang, 'cpp');
    expect(TkConsole.file(d), 'main.cpp');
    expect(
      TkDesign.fromJson({'target': tkTargetConsolePas}).consoleLang,
      'pas',
    );
  });

  for (final lang in _programs.keys) {
    test(
      'de verdad: consola en $lang con entrada',
      () async {
        if (!_can(lang)) return markTestSkipped('Sin compilador de $lang.');
        final tmp = await Directory.systemTemp.createTemp('dms_console_');
        addTearDown(() => tmp.delete(recursive: true));
        final dir = Directory(p.join(tmp.path, 'build', 'console'))
          ..createSync(recursive: true);
        final file = File(p.join(dir.path, 'main.$lang'))
          ..writeAsStringSync(_programs[lang]!);
        final run = await TkRunner.start(
          TkPrepared(
            id: tmp.path,
            name: lang,
            source: _programs[lang]!,
            file: file.path,
            console: lang,
          ),
        );
        await _wait(run, () => run.lines.any((l) => l.startsWith('Nombre?')));
        expect(
          run.lines.last,
          'Nombre? ',
          reason:
              'la pregunta se ve antes de responder\n${run.lines.join('\n')}',
        );
        run.send('Ana');
        await _wait(run, () => _last(run) == 'A? ');
        run.send('20');
        await _wait(run, () => _last(run) == 'B? ');
        run.send('22');
        await _wait(run, () => !run.running);
        expect(run.exitCode, 0, reason: run.lines.join('\n'));
        expect(
          run.lines,
          containsAllInOrder([
            'Nombre? Ana',
            'A? 20',
            'B? 22',
            'Hola, Ana. Suma: 42',
          ]),
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }

  test(
    'de verdad: gestión de animales (altas, vacunas, baja)',
    () async {
      final e = tkConsoleExamples(
        (s) => s,
      ).firstWhere((e) => e.seed == 'console_animals');
      final tmp = await Directory.systemTemp.createTemp('dms_animals_');
      addTearDown(() => tmp.delete(recursive: true));
      final dir = Directory(p.join(tmp.path, 'build', 'console'))
        ..createSync(recursive: true);
      final file = File(p.join(dir.path, 'main.py'))..writeAsStringSync(e.code);
      final run = await TkRunner.start(
        TkPrepared(
          id: tmp.path,
          name: 'animales',
          source: e.code,
          file: file.path,
          console: 'py',
        ),
      );
      final soon = DateTime.now()
          .add(const Duration(days: 10))
          .toIso8601String()
          .substring(0, 10);
      Future<void> say(String prompt, String answer) async {
        // Una pregunta aún sin contestar (termina en espacio).
        bool asked() =>
            _last(run).startsWith(prompt) && _last(run).endsWith(' ');
        await _wait(run, asked);
        expect(_last(run), startsWith(prompt), reason: run.lines.join('\n'));
        run.send(answer);
      }

      // Dos altas.
      await say('Opción: ', '2');
      await say('Nombre: ', 'Luna');
      await say('Especie', 'perro');
      await say('Fecha de nacimiento', '2021-04-02');
      await say('Opción: ', '2');
      await say('Nombre: ', 'Michi');
      await say('Especie', 'gato');
      await say(
        'Fecha de nacimiento',
        'ayer',
      ); // Fecha mala: la vuelve a pedir.
      await say('Fecha de nacimiento', '');
      // Una vacuna con la próxima dosis en 10 días.
      await say('Opción: ', '4');
      await say('Número del animal: ', '1');
      await say('Vacuna: ', 'Rabia');
      await say('Fecha de aplicación', '');
      await say('Próxima dosis', soon);
      await say('Opción: ', '6');
      await say('Opción: ', '1');
      // Baja de Michi.
      await say('Opción: ', '3');
      await say('Número del animal: ', '2');
      await say('Motivo de la baja: ', 'Adoptado');
      await say('¿Dar de baja a Michi?', 's');
      await say('Opción: ', '1');
      await say('Opción: ', '5');
      await say('Número del animal: ', '1');
      await say('Opción: ', '0');
      await _wait(run, () => !run.running);
      final out = run.lines.join('\n');
      expect(run.exitCode, 0, reason: out);
      expect(out, contains('Dado de alta con el número 1'));
      expect(out, contains('Fecha no válida.'));
      expect(out, contains('Vacuna registrada para Luna.'));
      expect(out, matches(RegExp('$soon  Luna +Rabia +pronto')));
      expect(out, contains('Michi queda dado de baja.'));
      expect(out, contains('Hasta luego.'));
      // Se guardó en la carpeta del proyecto.
      final json = File(p.join(tmp.path, 'animales.json')).readAsStringSync();
      expect(json, contains('"motivo": "Adoptado"'));
      expect(json, contains('"nombre": "Rabia"'));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  for (final e in tkConsoleExamples(
    (s) => s,
  ).where((e) => e.seed.startsWith('console_guess'))) {
    final lang = e.design.consoleLang!;
    test(
      'de verdad: ${e.seed} se gana adivinando',
      () async {
        if (!_can(lang)) return markTestSkipped('Sin compilador de $lang.');
        final tmp = await Directory.systemTemp.createTemp('dms_guess_');
        addTearDown(() => tmp.delete(recursive: true));
        final dir = Directory(p.join(tmp.path, 'build', 'console'))
          ..createSync(recursive: true);
        final file = File(p.join(dir.path, TkConsole.file(e.design)))
          ..writeAsStringSync(e.code);
        final run = await TkRunner.start(
          TkPrepared(
            id: tmp.path,
            name: e.seed,
            source: e.code,
            file: file.path,
            console: lang,
          ),
        );
        // Búsqueda binaria con las pistas del programa.
        var (lo, hi) = (1, 100);
        var answers = 0;
        for (var turn = 0; turn < 12 && run.running; turn++) {
          await _wait(run, () => _last(run) == 'Su número: ');
          if (!run.running) break;
          final hint = run.lines.length > 1
              ? run.lines[run.lines.length - 2]
              : '';
          if (turn > 0) {
            final g = (lo + hi) ~/ 2;
            if (hint.endsWith('Más alto.')) lo = g + 1;
            if (hint.endsWith('Más bajo.')) hi = g - 1;
          }
          if (turn == 0) {
            run.send('hola'); // No es un número: lo dice y vuelve a preguntar.
            await _wait(run, () => run.lines.contains('Escriba un número.'));
            await _wait(run, () => _last(run) == 'Su número: ');
          }
          run.send('${(lo + hi) ~/ 2}');
          answers++;
          await _wait(
            run,
            () =>
                !run.running ||
                _last(run) == 'Su número: ' &&
                    run.lines[run.lines.length - 2] !=
                        'Su número: ${(lo + hi) ~/ 2}' ||
                run.lines.any((l) => l.startsWith('¡Correcto!')),
          );
        }
        await _wait(run, () => !run.running);
        expect(run.exitCode, 0, reason: run.lines.join('\n'));
        expect(
          run.lines.last,
          '¡Correcto! En $answers intentos.',
          reason: run.lines.join('\n'),
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }

  test('un error de compilación dice su línea de main.c', () async {
    if (!_can('c')) return markTestSkipped('Sin compilador de C.');
    final tmp = await Directory.systemTemp.createTemp('dms_console_err_');
    addTearDown(() => tmp.delete(recursive: true));
    final dir = Directory(p.join(tmp.path, 'build', 'console'))
      ..createSync(recursive: true);
    const code = 'int main(void) {\n  nope();\n  return 0\n}\n';
    final file = File(p.join(dir.path, 'main.c'))..writeAsStringSync(code);
    final run = await TkRunner.start(
      TkPrepared(
        id: tmp.path,
        name: 'err',
        source: code,
        file: file.path,
        console: 'c',
      ),
    );
    await _wait(run, () => !run.running);
    expect(run.exitCode, isNot(0));
    expect(
      run.lines.any((l) => l.startsWith('main.c:')),
      isTrue,
      reason: run.lines.join('\n'),
    );
  });
}
