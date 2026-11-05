import 'dart:convert';

import 'package:dmarlon_studio/code/tk_chrome.dart';
import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_cpp.dart';
import 'package:dmarlon_studio/code/tk_electron.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/ui/icon_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el SVG de la IA: solo uno limpio', () {
    const ok =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" fill="#2563eb"/></svg>';
    expect(svgOf('Aquí está:\n```svg\n$ok\n```'), ok);
    expect(svgOf('sin icono'), isNull);
    expect(svgOf('<svg><script>alert(1)</script></svg>'), isNull);
    expect(svgOf('<svg><image href="http://x/y.png"/></svg>'), isNull);
  });

  testWidgets('el SVG se convierte en un PNG de 512', (tester) async {
    const svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><rect width="64" height="64" rx="12" fill="#2563eb"/><circle cx="32" cy="32" r="14" fill="#fff"/></svg>';
    final png = await tester.runAsync(() => svgToPng(svg));
    expect(png, isNotNull);
    // Cabecera de PNG, ancho y alto 512.
    expect(png!.sublist(1, 4), utf8.encode('PNG'));
    int be(int at) =>
        (png[at] << 24) |
        (png[at + 1] << 16) |
        (png[at + 2] << 8) |
        png[at + 3];
    expect(be(16), 512);
    expect(be(20), 512);
  });

  test('el icono de la aplicación en cada destino', () {
    TkDesign design(String target) =>
        TkDesign(target: target)..appIcon = 'images/app_icon.png';
    // tkinter
    final py = TkCodegen.generate(
      design(tkTargetDesktop),
      'class Form1(FormDesign):\n    pass\n',
    );
    expect(py, contains('self.root.iconphoto(True, self._app_icon)'));
    // Electron
    expect(
      TkElectron.window(design(tkTargetElectron))['icon'],
      'images/app_icon.png',
    );
    // Chrome
    const js = 'class Form1 extends FormDesign {\n}\n';
    final manifest =
        jsonDecode(
              TkChrome.files(
                design(tkTargetChrome),
                js,
                name: 'x',
              )['manifest.json']!,
            )
            as Map;
    expect(manifest['icons']['128'], 'images/app_icon.png');
    expect(manifest['action']['default_icon'], 'images/app_icon.png');
    // C++
    final h = TkCpp.files(
      design(tkTargetCpp),
      'class Form1 : public FormDesign {\npublic:\n};\n',
    )['design.h']!;
    expect(h, contains('app_icon("images/app_icon.png");'));
    // Se guarda con el diseño y se puede quitar.
    final d = TkDesign.parse(design(tkTargetDesktop).toJsonString());
    expect(d.appIcon, 'images/app_icon.png');
    d.appIcon = null;
    expect(d.props.containsKey('app_icon'), isFalse);
  });
}
