part of 'tk_examples.dart';

// Aplicaciones de consola: «Adivina el número» en Python, C, C++ y Pascal.
// Leen lo que se escribe en la pestaña Salida.

/// Los ejemplos de consola.
List<TkExample> tkConsoleExamples(String Function(String) t) => [
  _consoleAnimals(t),
  ..._consoleGuess(t),
];

List<TkExample> _consoleGuess(String Function(String) t) {
  final intro = t(markTr('Adivine el número entre 1 y 100.'));
  final ask = t(markTr('Su número: '));
  final low = t(markTr('Más alto.'));
  final high = t(markTr('Más bajo.'));
  final win = t(markTr('¡Correcto! En {0} intentos.'));
  final bad = t(markTr('Escriba un número.'));
  String c(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  String pas(String s) => s.replaceAll("'", "''");
  TkExample ex(
    String lang,
    String target,
    String name,
    String code,
  ) => TkExample(
    'console_guess_$lang',
    t(markTr('Adivina el número ({0})')).replaceAll('{0}', name),
    t(
      markTr(
        'Un juego de consola: el programa piensa un número y usted lo adivina escribiendo en la pestaña Salida.',
      ),
    ),
    TkDesign(target: target, props: {'title': name}),
    code,
  );
  final (winA, winB) = (win.split('{0}').first, win.split('{0}').last);
  return [
    ex(
      'py',
      tkTargetConsolePy,
      'Python',
      '''# ${t(markTr('Adivina el número: input() lee lo que escribe en la pestaña Salida.'))}
import random

secret = random.randint(1, 100)
tries = 0
print("${c(intro)}")
while True:
    text = input("${c(ask)}")
    if not text.strip().isdigit():
        print("${c(bad)}")
        continue
    tries += 1
    guess = int(text)
    if guess < secret:
        print("${c(low)}")
    elif guess > secret:
        print("${c(high)}")
    else:
        print("${c(winA)}" + str(tries) + "${c(winB)}")
        break
''',
    ),
    ex(
      'c',
      tkTargetConsoleC,
      'C',
      '''// ${t(markTr('Adivina el número: scanf lee lo que escribe en la pestaña Salida.'))}
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
  srand((unsigned) time(NULL));
  int secret = rand() % 100 + 1, tries = 0, guess;
  printf("${c(intro)}\\n");
  for (;;) {
    printf("${c(ask)}");
    if (scanf("%d", &guess) != 1) {
      int ch;
      while ((ch = getchar()) != '\\n' && ch != EOF) {}
      if (ch == EOF) return 1;
      printf("${c(bad)}\\n");
      continue;
    }
    tries++;
    if (guess < secret) printf("${c(low)}\\n");
    else if (guess > secret) printf("${c(high)}\\n");
    else {
      printf("${c(winA)}%d${c(winB)}\\n", tries);
      return 0;
    }
  }
}
''',
    ),
    ex(
      'cpp',
      tkTargetConsoleCpp,
      'C++',
      '''// ${t(markTr('Adivina el número: std::cin lee lo que escribe en la pestaña Salida.'))}
#include <iostream>
#include <random>
#include <string>

int main() {
  std::mt19937 rng(std::random_device{}());
  const int secret = std::uniform_int_distribution<int>(1, 100)(rng);
  int tries = 0;
  std::cout << "${c(intro)}" << std::endl;
  std::string line;
  while (std::cout << "${c(ask)}", std::getline(std::cin, line)) {
    int guess;
    try {
      guess = std::stoi(line);
    } catch (...) {
      std::cout << "${c(bad)}" << std::endl;
      continue;
    }
    ++tries;
    if (guess < secret) std::cout << "${c(low)}" << std::endl;
    else if (guess > secret) std::cout << "${c(high)}" << std::endl;
    else {
      std::cout << "${c(winA)}" << tries << "${c(winB)}" << std::endl;
      return 0;
    }
  }
}
''',
    ),
    ex(
      'pas',
      tkTargetConsolePas,
      'Pascal',
      '''// ${t(markTr('Adivina el número: ReadLn lee lo que escribe en la pestaña Salida.'))}
program main;

{\$mode objfpc}{\$H+}

uses
  SysUtils;

var
  Secret, Tries, Guess: Integer;
  Text: string;

begin
  Randomize;
  Secret := Random(100) + 1;
  Tries := 0;
  WriteLn('${pas(intro)}');
  repeat
    Write('${pas(ask)}');
    if EOF then Halt(1);
    ReadLn(Text);
    if not TryStrToInt(Trim(Text), Guess) then
    begin
      WriteLn('${pas(bad)}');
      Continue;
    end;
    Inc(Tries);
    if Guess < Secret then
      WriteLn('${pas(low)}')
    else if Guess > Secret then
      WriteLn('${pas(high)}');
  until Guess = Secret;
  WriteLn('${pas(winA)}', Tries, '${pas(winB)}');
end.
''',
    ),
  ];
}
