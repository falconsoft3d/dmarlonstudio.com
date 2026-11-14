// Capturas de cada ejemplo abierto en el Diseñador, para el carrusel de la
// portada de la web (landing/public/examples/<idioma>/<ejemplo>.png).
//
//   DMS_SCREENSHOTS=1 flutter test test/examples_screenshots_test.dart
//
// Sin DMS_SCREENSHOTS=1 no hace nada. Las fuentes (Lato, DejaVu Sans Mono y
// los iconos Lucide) se cargan de verdad, así que las capturas se ven como la
// app. Salen en español y en inglés, en PNG a doble resolución; el script
// scripts/build-docs.mjs no las regenera: hay que lanzar esta prueba.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dmarlon_studio/code/tk_run_types.dart';
import 'package:dmarlon_studio/code/tk_run_io.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/i18n/i18n.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final _on = Platform.environment['DMS_SCREENSHOTS'] == '1';
final _out =
    Platform.environment['DMS_SCREENSHOTS_OUT'] ??
    p.normalize(
      p.join(Directory.current.path, '..', 'landing', 'public', 'examples'),
    );

Future<void> _font(String family, List<String> assets) async {
  final l = FontLoader(family);
  for (final a in assets) {
    l.addFont(rootBundle.load(a));
  }
  await l.load();
}

/// Los ejemplos del carrusel, en su orden.
const carousel = [
  'notepad',
  'line_chart',
  'stocks',
  'viewer_3d',
  'agenda',
  'mail_client',
  'currency',
  'snake',
  'music_player',
  'windows_dialogs',
  'calculator',
  'web_crm',
  'web_invoicing',
  // El blog y la tienda se ven como webs: sus capturas son de la página.
  'electron_calculator',
  'electron_notepad',
  'chrome_notes',
  'chrome_words',
  'next_tasks',
  'cpp_calculator',
  'cpp_explorer',
  'cpp_racing',
  'cpp_image_editor',
  'cpp_flights',
  'cpp_hardware',
  'cpp_wifi',
  'cpp_console',
  'pascal_malecon',
  'pascal_docker',
  'pascal_launcher',
  'pascal_opend',
  'cpp_webmon',
  'cpp_clocks',
  'cpp_recorder',
  'cpp_mywa',
  'cpp_minilang',
  'cpp_pass',
  'cpp_ccusage',
  'pascal_travel',
  'cpp_radio',
  'cpp_blocks',
  'domino',
  'pascal_calculator',
  'console_animals',
  'flutter_store',
  'flutter_inventory',
  'web_next_store',
  'rn_store',
  'flutter_shipping',
  'flutter_todo',
  'react_store',
  'html_store',
  'html_domino',
  'next_world',
  'next_speed',
  'next_flights',
  'vue_store',
  'go_store',
  'pdf_editor',
  'pdf20',
  'disk_usage',
  'port_scanner',
  'investor',
  'pos',
  'file_renamer',
  'mp3_player',
  'train_monitor',
];

/// Los ejemplos con «Cómo se hizo» en su página de demo: también la pestaña
/// Código (<ejemplo>-code.png) y la del código generado (<ejemplo>-generated.png).
const made = {'pascal_docker', 'pascal_launcher', 'cpp_webmon', 'cpp_clocks', 'cpp_recorder', 'cpp_mywa', 'cpp_minilang', 'cpp_pass', 'pascal_opend', 'cpp_ccusage', 'pascal_travel', 'cpp_radio', 'cpp_blocks', 'pdf20'};

/// DMS_SEEDS=a,b: solo esas capturas.
final _only = (Platform.environment['DMS_SEEDS'] ?? '')
    .split(',')
    .where((s) => s.isNotEmpty)
    .toSet();

void main() {
  testWidgets('capturas de los ejemplos', (tester) async {
    late Directory tmp;
    late Map<String, String> paths;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_example_shots_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
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
      paths = {
        for (final x in projects)
          if (x.seed != null) x.seed!: x.path,
      };
    });

    tester.view.physicalSize = const Size(1360 * 2, 860 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();

    Future<void> settle([int rounds = 25]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    for (final lang in ['es', 'en']) {
      await tester.runAsync(() => I18n.use(lang));
      for (final d in [...TkProject.opened]) {
        TkProject.close(d);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const StudioApp()),
      );
      await settle(60);
      for (final seed in carousel) {
        if (_only.isNotEmpty && !_only.contains(seed)) continue;
        final path = paths[seed];
        if (path == null) {
          debugPrint('Sin el ejemplo $seed');
          continue;
        }
        final x = await tester.runAsync(() => ProjectStore.get(path));
        // Uno abierto cada vez: la pestaña del anterior se cierra.
        for (final d in [...TkProject.opened]) {
          TkProject.close(d);
        }
        TkProject.open(x!);
        await settle(30);
        // El de Electron enseña su código en JavaScript.
        if (seed == 'electron_notepad' || seed == 'chrome_words') {
          await tester.tap(find.byKey(const ValueKey('tk-tab-1')));
          await settle(10);
        }
        Future<void> shot(String name) => tester.runAsync(() async {
          final ro =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await ro.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final f = File(p.join(_out, lang, '$name.png'));
          await f.parent.create(recursive: true);
          await f.writeAsBytes(bytes!.buffer.asUint8List());
        });
        await shot(seed);
        if (made.contains(seed)) {
          await tester.tap(find.byKey(const ValueKey('tk-tab-1')));
          await settle(10);
          await shot('$seed-code');
          await tester.tap(find.byKey(const ValueKey('tk-tab-2')));
          await settle(10);
          await shot('$seed-generated');
          await tester.tap(find.byKey(const ValueKey('tk-tab-0')));
          await settle(5);
        }
      }
    }

    await tester.runAsync(() async {
      await StudioDb.close();
      await tmp.delete(recursive: true);
    });
  }, skip: !_on);
}
