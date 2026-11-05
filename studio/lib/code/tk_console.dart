import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_cpp_run.dart';
import 'tk_model.dart';
import 'tk_pascal_run.dart';
import 'tk_run_types.dart';

/// Aplicaciones de consola: un solo archivo, sin ventana. La entrada y la
/// salida van por la pestaña Salida del estudio.
class TkConsole {
  TkConsole._();

  /// Extensión del archivo de [lang] (py, c, cpp o pas).
  static String ext(String lang) => lang;

  /// Nombre del archivo del código.
  static String file(TkDesign d) => 'main.${ext(d.consoleLang ?? 'py')}';

  /// El programa de un proyecto nuevo.
  static String template(String lang) => switch (lang) {
    'c' =>
      '// ${tr('Aplicación de consola en C. Lo que escribe printf sale en la pestaña Salida; scanf y fgets leen lo que escriba abajo.')}\n'
          '#include <stdio.h>\n#include <string.h>\n\n'
          'int main(void) {\n'
          '  char name[100];\n'
          '  printf("${tr('¿Cómo se llama? ')}");\n'
          '  if (fgets(name, sizeof name, stdin)) {\n'
          '    name[strcspn(name, "\\n")] = 0;\n'
          '    printf("${tr('Hola, %s.')}\\n", name);\n'
          '  }\n'
          '  return 0;\n'
          '}\n',
    'cpp' =>
      '// ${tr('Aplicación de consola en C++. Lo que escribe std::cout sale en la pestaña Salida; std::cin y std::getline leen lo que escriba abajo.')}\n'
          '#include <iostream>\n#include <string>\n\n'
          'int main() {\n'
          '  std::string name;\n'
          '  std::cout << "${tr('¿Cómo se llama? ')}";\n'
          '  std::getline(std::cin, name);\n'
          '  std::cout << "${tr('Hola, ')}" << name << "." << std::endl;\n'
          '  return 0;\n'
          '}\n',
    'pas' =>
      '// ${tr('Aplicación de consola en Pascal. Lo que escribe WriteLn sale en la pestaña Salida; ReadLn lee lo que escriba abajo.')}\n'
          'program main;\n\n{\$mode objfpc}{\$H+}\n\n'
          'uses\n  SysUtils;\n\n'
          'var\n  Name: string;\n\n'
          'begin\n'
          "  Write('${tr('¿Cómo se llama? ')}');\n"
          '  ReadLn(Name);\n'
          "  WriteLn('${tr('Hola, ')}', Name, '.');\n"
          'end.\n',
    _ =>
      '# ${tr('Aplicación de consola en Python. Lo que escribe print sale en la pestaña Salida; input lee lo que escriba abajo.')}\n\n'
          'name = input("${tr('¿Cómo se llama? ')}")\n'
          'print(f"${tr('Hola, ')}{name}.")\n',
  };

  /// Hace que C y C++ escriban sin esperar (por una tubería, stdio guarda
  /// la salida hasta el final y no se verían las preguntas).
  static const unbuffered =
      '''// DMarlon Studio: salida sin búfer. Generado: no lo edite.
#include <stdio.h>
__attribute__((constructor)) static void dms_unbuffered(void) {
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);
}
''';

  /// Pascal: por una tubería, Free Pascal guarda la salida hasta el final;
  /// esta unidad (que se carga sola con -Fa) la escribe al momento.
  static const pascalFlush =
      '''// DMarlon Studio: salida sin búfer. Generado: no lo edite.
unit dms_console;

interface

implementation

initialization
  TextRec(Output).FlushFunc := TextRec(Output).InOutFunc;
  TextRec(StdErr).FlushFunc := TextRec(StdErr).InOutFunc;
end.
''';

  /// Free Pascal (fpc) del equipo.
  static String? fpc() {
    final dirs = [
      ...(Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ),
      '/usr/local/bin',
      '/opt/homebrew/bin',
      '/usr/bin',
      if (Platform.isWindows) ...[
        r'C:\FPC\3.2.2\bin\x86_64-win64',
        r'C:\lazarus\fpc\3.2.2\bin\x86_64-win64',
      ],
    ];
    for (final d in dirs) {
      if (d.isEmpty) continue;
      final f = p.join(d, Platform.isWindows ? 'fpc.exe' : 'fpc');
      if (File(f).existsSync()) return f;
    }
    return null;
  }

  /// Lo que falta para ejecutar [lang] (vacío: nada).
  static List<TkNeed> needs(String lang) => switch (lang) {
    'c' || 'cpp' =>
      TkCppTools.needs().where((n) => n.packages.first == 'c++').toList(),
    'pas' =>
      fpc() != null
          ? const []
          : [
              for (final n in TkPascalTools.needs())
                TkNeed(
                  title: tr('Falta Free Pascal'),
                  why: tr(
                    'Las aplicaciones de consola de Pascal se compilan con Free Pascal (fpc).',
                  ),
                  packages: const ['fpc'],
                  command: Platform.isMacOS
                      ? 'brew install fpc'
                      : Platform.isLinux
                      ? 'sudo apt install fpc'
                      : 'https://www.freepascal.org',
                  installer: n.installer,
                ),
            ],
    _ => const [],
  };

  /// La orden que compila el main de [lang] de [dir] en [exe] (null:
  /// Python, no se compila).
  static Future<(String, List<String>)?> compile(
    String lang,
    String dir,
    String exe, {
    bool debug = false,
  }) async {
    switch (lang) {
      case 'c' || 'cpp':
        final cxx = TkCppTools.compiler();
        if (cxx == null) {
          throw UserError(TkCppTools.needs().map((n) => n.why).join('\n'));
        }
        final c = lang == 'c';
        final helper = c ? 'dms_unbuffered.c' : 'dms_unbuffered.cpp';
        await File(p.join(dir, helper)).writeAsString(unbuffered);
        return (
          c
              ? p.join(p.dirname(cxx), Platform.isWindows ? 'gcc.exe' : 'cc')
              : cxx,
          [
            if (c) '-std=c11' else '-std=c++17',
            if (debug) ...['-g', '-O0'] else '-O1',
            if (c) 'main.c' else 'main.cpp',
            helper,
            '-o',
            exe,
            if (c) '-lm',
          ],
        );
      case 'pas':
        final fpc = TkConsole.fpc();
        if (fpc == null) throw UserError(tr('Falta Free Pascal'));
        await File(p.join(dir, 'dms_console.pas')).writeAsString(pascalFlush);
        return (
          fpc,
          [
            '-Mobjfpc',
            '-Sh',
            if (debug) '-g' else '-O1',
            if (Abi.current() == Abi.macosArm64) '-Paarch64',
            ...await TkPascalTools.options(),
            '-FE.',
            '-Fadms_console',
            '-o${p.basename(exe)}',
            'main.pas',
          ],
        );
    }
    return null;
  }

  /// Las líneas del compilador que dicen algo (sin la carpeta).
  static List<String> messages(String output, String dir) {
    final out = <String>[];
    String real = dir;
    try {
      real = Directory(dir).resolveSymbolicLinksSync();
    } on FileSystemException {
      // Se queda como está.
    }
    for (final raw in output.split('\n')) {
      final l = raw.trimRight();
      if (l.trim().isEmpty ||
          l.startsWith('ld: warning') ||
          l.startsWith('Free Pascal Compiler') ||
          l.startsWith('Copyright (c)') ||
          l.startsWith('Target OS:') ||
          l.startsWith('Compiling ') ||
          l.startsWith('Linking ') ||
          l.startsWith('Assembling ') ||
          l.contains('lines compiled,') ||
          l.contains('-macosx_version_min') ||
          l.contains('ld_classic is deprecated') ||
          l.contains('-multiply_defined') ||
          l.contains('ignoring duplicate libraries') ||
          l.contains('Error: ') && l.contains('returned an error exitcode') ||
          l.startsWith('Fatal: Compilation aborted') ||
          RegExp(r'^\(\d+\) ').hasMatch(l) && !l.contains('Error')) {
        continue;
      }
      out.add(
        l
            .replaceAll('$real${Platform.pathSeparator}', '')
            .replaceAll('$dir${Platform.pathSeparator}', '')
            .replaceAllMapped(RegExp(r'(^|\s)\./'), (m) => m[1]!),
      );
    }
    return out;
  }
}
