import 'package:dmarlon_studio/ui/bottom_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('se minimiza, se restaura y cambia de alto al arrastrar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: SizedBox()),
              BottomPanel(
                id: 'test-panel',
                title: Text('Salida'),
                initialHeight: 200,
                child: Text('línea 1'),
              ),
            ],
          ),
        ),
      ),
    );
    double height() => tester.getSize(find.byType(BottomPanel)).height;
    expect(height(), 200);
    expect(find.text('línea 1'), findsOneWidget);

    // Arrastrar el borde superior hacia arriba lo agranda.
    await tester.drag(find.text('Salida'), const Offset(0, -80));
    await tester.pump();
    // Lo arrastrado, menos la tolerancia con la que empieza el gesto.
    final dragged = height();
    expect(dragged, greaterThan(240));
    expect(dragged, lessThanOrEqualTo(280));

    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pump();
    expect(find.text('línea 1'), findsNothing);
    expect(height(), lessThan(40));

    await tester.tap(find.byTooltip('Restaurar'));
    await tester.pump();
    expect(find.text('línea 1'), findsOneWidget);
    expect(height(), dragged);
  });
}
