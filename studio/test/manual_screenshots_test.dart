// Capturas de la app para el manual de la web (landing/public/manual).
//
//   DMS_SCREENSHOTS=1 flutter test test/manual_screenshots_test.dart
//
// Sin DMS_SCREENSHOTS=1 no hace nada. Las fuentes (Lato, DejaVu Sans Mono y
// los iconos Lucide) se cargan de verdad, así que las capturas se ven como la
// app. Salen en español y en inglés, en PNG a doble resolución; el script
// scripts/build-docs.mjs no las regenera: hay que lanzar esta prueba.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dmarlon_studio/code/tk_run_types.dart';
import 'package:dmarlon_studio/code/tk_run_io.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/settings.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/db/dev_tools.dart';
import 'package:dmarlon_studio/db/diagrams.dart';
import 'package:dmarlon_studio/dev/diagram.dart';
import 'package:dmarlon_studio/i18n/i18n.dart';
import 'package:dmarlon_studio/i18n/po.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _on = Platform.environment['DMS_SCREENSHOTS'] == '1';
final _out =
    Platform.environment['DMS_SCREENSHOTS_OUT'] ??
    p.normalize(
      p.join(Directory.current.path, '..', 'landing', 'public', 'manual'),
    );

Future<void> _font(String family, List<String> assets) async {
  final l = FontLoader(family);
  for (final a in assets) {
    l.addFont(rootBundle.load(a));
  }
  await l.load();
}

void main() {
  testWidgets('capturas del manual', (tester) async {
    late Directory tmp;
    Directory? shared;
    late String calc;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_shots_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      // Una ruta con aspecto normal en las capturas (no la temporal).
      shared = Directory('/Users/Shared/DMarlon Studio');
      if (shared!.existsSync()) shared = null;
      ProjectStore.workspaceOverride = p.join(
        shared?.path ?? p.join(tmp.path, 'DMarlon Studio'),
        'Proyectos',
      );
      await StudioDb.open();
      await _font('Lato', [
        'assets/fonts/Lato-Regular.ttf',
        'assets/fonts/Lato-Bold.ttf',
      ]);
      // Los editores piden Menlo/Consolas: aquí, la monoespaciada del estudio.
      for (final f in ['DejaVuSansMono', 'Menlo', 'Consolas', 'monospace']) {
        await _font(f, [
          'assets/fonts/DejaVuSansMono.ttf',
          'assets/fonts/DejaVuSansMono-Bold.ttf',
        ]);
      }
      // Las fuentes de Material vienen con Flutter, junto al motor de pruebas.
      var dir = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
      while (!Directory(p.join(dir, 'material_fonts')).existsSync() &&
          p.dirname(dir) != dir) {
        dir = p.dirname(dir);
      }
      final material = p.join(dir, 'material_fonts');
      Future<void> fileFont(String family, List<String> files) async {
        final l = FontLoader(family);
        for (final f in files) {
          l.addFont(
            File(
              p.join(material, f),
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        }
        await l.load();
      }

      await fileFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
      // El lienzo pinta los componentes con Helvetica (la de Tk) y algunos
      // textos no piden familia: aquí, Roboto.
      for (final f in [
        'Roboto',
        'Helvetica',
        'Arial',
        'TkDefaultFont',
        'FlutterTest',
      ]) {
        await fileFont(f, ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']);
      }
      await _font('packages/lucide_icons_flutter/Lucide', [
        'packages/lucide_icons_flutter/assets/lucide.ttf',
      ]);
      TkRunner.python = const TkPython(
        command: '/opt/homebrew/bin/python3',
        version: '3.13.1',
        tk: '8.6.15',
        help: '',
      );
      final projects = await ProjectStore.list();
      calc = projects.firstWhere((x) => x.name.contains('Calcul')).path;
      await Settings.set('code.recent', jsonEncode([calc]));

      // Una base SQLite de ejemplo para Bases de datos y Diagramas.
      sqfliteFfiInit();
      final dbPath = p.join(tmp.path, 'tienda.sqlite');
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      await db.execute(
        'CREATE TABLE clientes (id INTEGER PRIMARY KEY, nombre TEXT, correo TEXT, ciudad TEXT)',
      );
      await db.execute(
        'CREATE TABLE pedidos (id INTEGER PRIMARY KEY, cliente_id INTEGER REFERENCES clientes(id), fecha TEXT, total REAL)',
      );
      for (final (n, c, ci) in [
        ('Ana Pérez', 'ana@ejemplo.com', 'Madrid'),
        ('Luis Gómez', 'luis@ejemplo.com', 'Valencia'),
        ('Marta Ruiz', 'marta@ejemplo.com', 'Sevilla'),
        ('Jorge Díaz', 'jorge@ejemplo.com', 'Bilbao'),
      ]) {
        await db.insert('clientes', {'nombre': n, 'correo': c, 'ciudad': ci});
      }
      await db.close();
      await DevTools.saveConnection(
        null,
        kind: 'sqlite',
        name: 'Tienda (SQLite)',
        config: {'path': dbPath},
      );
      await DevTools.saveRequest(
        null,
        collection: 'GitHub',
        name: 'Repositorio de DMarlon Studio',
        request: {
          'method': 'GET',
          'url': 'https://api.github.com/repos/falconsoft3d/dmarlonstudio.com',
        },
      );
      await Diagrams.create(
        'Alta de cliente',
        'flow',
        diagram: Diagram(
          nodes: [
            DNode(id: 'a', type: 'start', text: 'Inicio', x: 60, y: 40),
            DNode(
              id: 'b',
              type: 'io',
              text: 'Pedir nombre y correo',
              x: 60,
              y: 150,
            ),
            DNode(
              id: 'c',
              type: 'decision',
              text: '¿Correo válido?',
              x: 65,
              y: 260,
            ),
            DNode(
              id: 'd',
              type: 'process',
              text: 'Guardar cliente',
              x: 60,
              y: 400,
            ),
            DNode(
              id: 'e',
              type: 'note',
              text: 'Mostrar el error',
              x: 320,
              y: 268,
            ),
            DNode(id: 'f', type: 'start', text: 'Fin', x: 60, y: 510),
          ],
          edges: [
            DEdge('a', 'b'),
            DEdge('b', 'c'),
            DEdge('c', 'd'),
            DEdge('c', 'e'),
            DEdge('d', 'f'),
          ],
        ),
      );
    });

    tester.view.physicalSize = const Size(1360 * 2, 860 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();

    // La app lee archivos y la base de verdad: se alterna tiempo real (para
    // que lleguen) con fotogramas (para que se pinten).
    Future<void> settle([int rounds = 25]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String lang, String name, {double cropBottom = 0}) async {
      await settle();
      await tester.runAsync(() async {
        final ro =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        var image = await ro.toImage(pixelRatio: 2);
        if (cropBottom > 0) {
          // Sin la franja de abajo (la barra de estado del Editor).
          final rec = ui.PictureRecorder();
          final h = (image.height - cropBottom * 2).round();
          Canvas(rec).drawImage(image, Offset.zero, Paint());
          image = await rec.endRecording().toImage(image.width, h);
        }
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final f = File(p.join(_out, lang, '$name.png'));
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    Future<void> tap(Finder f) async {
      if (f.evaluate().isEmpty) {
        debugPrint('Captura: no encontrado $f');
        return;
      }
      await tester.tap(f.first, warnIfMissed: false);
      await settle();
    }

    for (final lang in ['es', 'en']) {
      await tester.runAsync(() async {
        await I18n.use(lang);
        // La web no nombra a otros productos: en las capturas, estos dos
        // textos sin la comparación (los demás, tal cual en la app).
        final cat = lang == 'es'
            ? <String, String>{}
            : catalogOf(await rootBundle.loadString('assets/i18n/en.po'));
        const studio =
            'IDE visual al estilo de Delphi para crear aplicaciones de Python (tkinter y Flask). Próximamente, Electron.';
        const designer =
            'Diseñe ventanas de escritorio con tkinter arrastrando componentes, como en Delphi. Cada una se abre en su propia ventana del sistema y se ejecuta en este equipo con los permisos de su usuario. En macOS, los botones tienen el aspecto del sistema y no toman el color de fondo.';
        cat[studio] = lang == 'es'
            ? 'IDE visual para crear aplicaciones de Python (tkinter y Flask). Próximamente, Electron.'
            : 'Visual IDE for building Python apps (tkinter and Flask). Electron coming soon.';
        cat[designer] = lang == 'es'
            ? 'Diseñe ventanas de escritorio con tkinter arrastrando componentes. Cada una se abre en su propia ventana del sistema y se ejecuta en este equipo con los permisos de su usuario. En macOS, los botones tienen el aspecto del sistema y no toman el color de fondo.'
            : 'Design tkinter desktop windows by dragging components. Each one opens in its own system window and runs on this computer with your user’s permissions. On macOS, buttons use the system look and ignore the background color.';
        setCatalog(cat);
      });
      // Cada idioma empieza en la lista de proyectos.
      TkProject.close();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const StudioApp()),
      );
      await settle(60);

      // Diseñador: proyectos, un proyecto, su código y Claude Code.
      await tap(find.byKey(const ValueKey('nav-0')));
      await shot(lang, 'designer-projects');
      await tap(find.byKey(ValueKey('tk-app-${p.normalize(calc)}')));
      if (find.byKey(const ValueKey('tk-tab-0')).evaluate().isEmpty) {
        await tap(find.text(lang == 'es' ? 'Calculadora' : 'Calculator'));
      }
      await shot(lang, 'designer');
      await tap(find.byKey(const ValueKey('tk-tab-1')));
      await shot(lang, 'designer-code');
      await tap(find.byKey(const ValueKey('tk-tab-2')));
      await shot(lang, 'designer-generated');
      await tap(find.byKey(const ValueKey('tk-tab-0')));
      await tap(find.byKey(const ValueKey('tk-claude')));
      await shot(lang, 'designer-claude');
      await tap(find.byKey(const ValueKey('tk-claude')));

      // Editor con la carpeta del proyecto y su código.
      await tap(find.byKey(const ValueKey('nav-1')));
      await tap(find.textContaining('calculadora'));
      await tap(find.text('Form1.py'));
      await shot(lang, 'editor', cropBottom: 24);

      // Herramientas.
      await tap(find.byKey(const ValueKey('nav-2')));
      await tap(find.text('Tienda (SQLite)'));
      await shot(lang, 'databases');
      await tap(find.byKey(const ValueKey('nav-3')));
      await tap(find.text('Repositorio de DMarlon Studio'));
      await shot(lang, 'api');
      await tap(find.byKey(const ValueKey('nav-4')));
      await shot(lang, 'ftp');
      await tap(find.byKey(const ValueKey('nav-5')));
      await tap(find.text('Alta de cliente'));
      await shot(lang, 'diagrams');
      // El diagrama se abre encima: se vuelve a la lista.
      await tester.runAsync(() async {});
      tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
      await settle();
      await tap(find.byKey(const ValueKey('nav-6')));
      await shot(lang, 'settings');
    }

    await tester.runAsync(() async {
      await StudioDb.close();
      await tmp.delete(recursive: true);
      if (shared != null && shared!.existsSync()) {
        await shared!.delete(recursive: true);
      }
    });
  }, skip: !_on);
}
