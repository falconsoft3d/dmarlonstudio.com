import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/ui/screens/project_browser.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<StudioProject> _projects(int n) => [
  for (var i = 1; i <= n; i++)
    StudioProject(
      path: '/ws/p$i',
      name: 'Proyecto ${i.toString().padLeft(2, '0')}',
      description: i == 7 ? 'el de las facturas' : null,
      design: TkDesign(target: i.isEven ? tkTargetWeb : tkTargetDesktop),
      code: '',
      modified: '2026-11-${i.toString().padLeft(2, '0')} 10:00:00',
    ),
];

void main() {
  testWidgets('páginas, orden, búsqueda y menús', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[], actions = <String>[], added = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectBrowser(
              projects: _projects(23),
              card: (a) => Text('card ${a.name}'),
              onOpen: (a) => opened.add(a.name),
              onAction: (a, v) => actions.add('$v ${a.name}'),
              onAdd: added.add,
            ),
          ),
        ),
      ),
    );
    // 15 por página, los más recientes primero.
    expect(find.text('1–15 de 23 proyectos'), findsOneWidget);
    expect(find.text('Proyecto 23'), findsOneWidget);
    expect(find.text('Proyecto 08'), findsNothing);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pump();
    expect(find.text('16–23 de 23 proyectos'), findsOneWidget);
    expect(find.text('Proyecto 01'), findsOneWidget);

    // Ordenar por nombre (A→Z) vuelve a la primera página.
    await tester.tap(find.text('Nombre'));
    await tester.pump();
    expect(find.text('Proyecto 01'), findsOneWidget);
    expect(find.text('Proyecto 16'), findsNothing);

    // Buscar por la descripción.
    await tester.enterText(find.byKey(const ValueKey('tk-search')), 'factura');
    await tester.pump();
    expect(find.text('1–1 de 1 proyectos'), findsOneWidget);
    await tester.tap(find.text('Proyecto 07'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Proyecto 07'));
    await tester.pumpAndSettle();
    expect(opened, ['Proyecto 07']);

    // Botón derecho sobre el proyecto: sus acciones.
    await tester.tap(find.text('Proyecto 07'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicar'));
    await tester.pumpAndSettle();
    expect(actions, ['copy Proyecto 07']);

    // Botón derecho sobre el fondo: Agregar nuevo › Proyecto web.
    await tester.enterText(find.byKey(const ValueKey('tk-search')), 'nada');
    await tester.pump();
    await tester.tap(
      find.text('Ningún proyecto coincide con la búsqueda.'),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyecto web (Flask)'));
    await tester.pumpAndSettle();
    expect(added, ['web']);
  });
}
