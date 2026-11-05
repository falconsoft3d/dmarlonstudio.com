import 'dart:io';

import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('Flutter: editar pantallas al estilo de FlutterFlow', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Directory tmp;
    late String path;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_flutter_ui_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      path = await ProjectStore.create(
        'Contador',
        design: TkDesign(target: tkTargetFlutter),
      );
      TkProject.open((await ProjectStore.get(path))!);
    });

    Future<void> settle([int rounds = 10]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    await tester.pumpWidget(const StudioApp());
    await settle(20);

    // El proyecto nuevo trae la pantalla de inicio con su árbol.
    expect(find.byKey(const ValueKey('fl-phone')), findsOneWidget);
    expect(find.byKey(const ValueKey('fl-screen-Inicio')), findsOneWidget);
    expect(find.text('Ha pulsado el botón:'), findsWidgets);

    // El primer texto: Centro → Columna → Texto (camino 0.0).
    await tester.tap(find.byKey(const ValueKey('fl-tree-0.0')));
    await settle(3);
    await tester.enterText(
      find.byKey(const ValueKey('fl-prop-p-text')),
      'Pulsaciones:',
    );
    await settle(3);
    expect(find.text('Pulsaciones:'), findsWidgets);

    // Un botón desde la paleta, detrás del texto elegido.
    await tester.tap(find.byKey(const ValueKey('fl-add-Button')));
    await settle(3);
    await tester.enterText(
      find.byKey(const ValueKey('fl-prop-p-onTap')),
      'app.increment()',
    );
    await settle(3);

    // Una pantalla nueva.
    await tester.tap(find.byKey(const ValueKey('fl-screen-add')));
    await settle(3);
    expect(find.byKey(const ValueKey('fl-screen-Pantalla2')), findsOneWidget);

    // Todo queda en el diseño (y en el Dart que se genera).
    final d = TkProject.current!.design;
    final app = FlApp.of(d);
    expect(app.screens.map((s) => s.name), ['Inicio', 'Pantalla2']);
    final main = TkFlutter.main(app);
    expect(main, contains("Text('Pulsaciones:'"));
    expect(
      main,
      contains('FilledButton(onPressed: () async { app.increment(); }'),
    );
    expect(
      main,
      contains("'/Pantalla2': (context) => const Pantalla2Screen()"),
    );
    expect(TkProject.current!.dirty, isTrue);

    await tester.runAsync(() async {
      await StudioDb.close();
      await tmp.delete(recursive: true);
    });
    debugDefaultTargetPlatformOverride = null;
  });
}
