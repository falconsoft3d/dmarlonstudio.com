import 'dart:io';

import 'package:dmarlon_studio/code/tk_debug.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Un Python con tkinter, por su ruta (null: ninguno).
Future<String?> _python() async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    '/opt/homebrew/bin/python3',
    '$home/micromamba/bin/python3',
    '/usr/local/bin/python3',
    '/usr/bin/python3',
  ]) {
    if (!File(py).existsSync()) continue;
    final r = await Process.run(py, ['-c', 'import tkinter']);
    if (r.exitCode == 0) return py;
  }
  return null;
}

void main() {
  testWidgets('depurar desde el Diseñador', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Directory tmp;
    late String path;
    final py = await tester.runAsync(_python);
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_debug_ui_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      path = await ProjectStore.create(
        'Depurar',
        design: TkDesign(),
        code: 'LIMIT = 3\n\n\nclass Form1(FormDesign):\n    pass\n',
      );
      TkProject.open((await ProjectStore.get(path))!);
    });
    TkRunner.python = TkPython(command: py, version: '3', tk: '8.6', help: '');

    Future<void> settle([int rounds = 10]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> until(bool Function() ok) async {
      for (var i = 0; i < 300 && !ok(); i++) {
        await settle(1);
      }
      expect(ok(), isTrue);
    }

    await tester.pumpWidget(const StudioApp());
    await settle(20);

    // F5 en la pestaña Código pone un punto en la línea del cursor (la 1).
    await tester.tap(find.byKey(const ValueKey('tk-tab-1')));
    await settle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await settle();
    expect(TkBreakpoints.of(path), {1: ''});
    expect(find.byKey(const ValueKey('tk-gutter')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tk-debug')));
    await settle();
    TkDebugSession? s() => TkRunner.runOf(path)?.debug;
    await until(() => s()?.paused ?? false);
    await settle();
    expect(s()!.currentLine, 1);
    expect(find.text('Punto de parada  ·  <module>, línea 1'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('tk-dbg-over')))
          .onPressed,
      isNotNull,
    );

    // Pasar por encima: la constante ya existe.
    await tester.sendKeyEvent(LogicalKeyboardKey.f8);
    await until(() => (s()?.paused ?? false) && s()?.currentLine == 4);
    await tester.tap(find.byKey(const ValueKey('tk-dbg-tab-evaluate')));
    await settle();
    await tester.enterText(
      find.byKey(const ValueKey('tk-dbg-eval')),
      'LIMIT * 2',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await until(() => s()!.console.isNotEmpty);
    await settle();
    expect(find.text('6'), findsOneWidget);

    // Puntos de parada: se listan con su línea.
    await tester.tap(find.byKey(const ValueKey('tk-dbg-tab-breakpoints')));
    await settle();
    expect(find.text('LIMIT = 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tk-stop')));
    await until(() => s()?.ended ?? true);
    await settle();
    expect(find.byKey(const ValueKey('tk-dbg-continue')), findsNothing);

    await tester.runAsync(() async {
      TkBreakpoints.clear(path);
      for (final d in [...TkProject.opened]) {
        TkProject.close(d);
      }
      await StudioDb.close();
      await tmp.delete(recursive: true);
    });
  });
}
