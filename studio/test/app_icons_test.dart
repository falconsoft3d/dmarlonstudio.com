import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dmarlon_studio/ui/app_icons.dart';

void main() {
  test('500 iconos distintos', () {
    expect(appIconSet.length, 500);
    expect(appIconSet.map((e) => e.name).toSet().length, 500);
  });

  test('el icono sale del nombre del proyecto', () {
    String icon(String name, [String? description]) =>
        autoAppIcon(name, description).icon.name;
    expect(icon('Calculadora'), 'calculator');
    expect(icon('Agenda'), 'calendar-days');
    expect(icon('Punto de venta'), 'shopping-cart');
    expect(icon('Tienda online'), 'store');
    expect(icon('Reproductor MP3'), 'music');
    expect(icon('Bloc de notas'), 'notebook-pen');
    expect(icon('Inversor de bolsa'), 'chart-candlestick');
    expect(icon('Gestión de clientes'), 'users');
    expect(icon('Facturación'), 'receipt');
    expect(icon('Seguimiento de trenes'), 'train-front');
    expect(icon('Weather station'), isNot(isEmpty));
    expect(icon('Mi proyecto', 'control de inventario'), 'package');
  });

  test('sin palabras conocidas: siempre el mismo para el mismo nombre', () {
    final a = autoAppIcon('Zarquix 3000');
    final b = autoAppIcon('Zarquix 3000');
    expect(a.key, b.key);
    expect(AppIconPick.parse(a.key)!.key, a.key);
    expect(AppIconPick.parse('nada:1'), isNull);
  });

  testWidgets('se dibuja como PNG', (tester) async {
    final png = await tester.runAsync(
      () => renderAppIcon(autoAppIcon('Calculadora'), size: 128),
    );
    final bytes = Uint8List.fromList(png!);
    expect(bytes.sublist(1, 4), [0x50, 0x4E, 0x47]); // PNG
  });
}
