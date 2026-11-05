import 'dart:io';

import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Un Python 3, por su ruta (null: ninguno).
String? _python() {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    '/opt/homebrew/bin/python3',
    '$home/micromamba/bin/python3',
    '/usr/local/bin/python3',
    '/usr/bin/python3',
  ]) {
    if (File(py).existsSync()) return py;
  }
  return null;
}

void main() {
  testWidgets('consola: ejecutar y responder desde la Salida', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final py = _python();
    if (py == null) return markTestSkipped('Sin Python.');
    late Directory tmp;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_console_ui_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      final path = await ProjectStore.create(
        'Consola',
        design: TkDesign(target: tkTargetConsolePy),
      );
      TkProject.open((await ProjectStore.get(path))!);
    });
    TkRunner.python = TkPython(command: py, version: '3', help: '');

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

    String output() => [
      for (final e
          in find
              .descendant(
                of: find.byKey(const ValueKey('tk-output')),
                matching: find.byType(SelectableText),
              )
              .evaluate())
        (e.widget as SelectableText).data ?? '',
    ].join('\n');

    await tester.pumpWidget(const StudioApp());
    await settle(20);

    // Sin diseño: solo la pestaña de código, sin paleta.
    expect(find.byKey(const ValueKey('tk-tab-0')), findsNothing);
    expect(find.byKey(const ValueKey('tk-tab-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('tk-tab-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tk-run')));
    await until(
      () =>
          find.byKey(const ValueKey('tk-console-input')).evaluate().isNotEmpty,
    );
    await until(() => output().contains('¿Cómo se llama? '));
    await tester.enterText(
      find.byKey(const ValueKey('tk-console-input')),
      'Ana',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await until(() => output().contains('Hola, Ana.'));
    expect(output(), contains('¿Cómo se llama? Ana'));
    // Al terminar, el campo de entrada se va.
    await until(
      () => find.byKey(const ValueKey('tk-console-input')).evaluate().isEmpty,
    );

    await tester.runAsync(() async {
      await StudioDb.close();
      await tmp.delete(recursive: true);
    });
    debugDefaultTargetPlatformOverride = null;
  });
}
