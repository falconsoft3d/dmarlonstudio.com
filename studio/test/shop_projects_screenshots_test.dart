// Los proyectos de los cursos de bases de datos (la tienda del curso) abiertos
// en el Diseñador, en español y en inglés, para su página de la web:
//
//   DMS_SHOP_OUT=<carpeta> flutter test test/shop_projects_screenshots_test.dart
//
// Escribe <carpeta>/<curso>/designer-<idioma>.png. Sin DMS_SHOP_OUT no hace
// nada. Como el usuario, el estudio tiene guardada la conexión «shop» (de su
// tipo) en Bases de datos. Lo lanza landing/scripts/courses/build_projects.py.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:dmarlon_studio/db/dev_tools.dart';
import 'package:dmarlon_studio/i18n/i18n.dart';
import 'package:dmarlon_studio/main.dart';
import 'package:dmarlon_studio/ui/tk_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final _out = Platform.environment['DMS_SHOP_OUT'];

/// El tamaño de la ventana del estudio en las capturas.
const _size = Size(1600, 980);

Future<void> _font(String family, List<Object> sources) async {
  final l = FontLoader(family);
  for (final s in sources) {
    l.addFont(
      s is File
          ? s.readAsBytes().then((b) => ByteData.sublistView(b))
          : rootBundle.load('$s'),
    );
  }
  await l.load();
}

void main() {
  testWidgets('la tienda de cada curso, en el Diseñador', (tester) async {
    late Directory tmp;
    await tester.runAsync(() async {
      tmp = await Directory.systemTemp.createTemp('dms_shop_shots_');
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      await _font('Lato', [
        'assets/fonts/Lato-Regular.ttf',
        'assets/fonts/Lato-Bold.ttf',
      ]);
      for (final f in ['DejaVuSansMono', 'Menlo', 'Consolas', 'monospace']) {
        await _font(f, [
          'assets/fonts/DejaVuSansMono.ttf',
          'assets/fonts/DejaVuSansMono-Bold.ttf',
        ]);
      }
      var dir = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
      while (!Directory(p.join(dir, 'material_fonts')).existsSync() &&
          p.dirname(dir) != dir) {
        dir = p.dirname(dir);
      }
      File m(String f) => File(p.join(dir, 'material_fonts', f));
      await _font('MaterialIcons', [m('MaterialIcons-Regular.otf')]);
      for (final f in [
        'Roboto',
        'Helvetica',
        'Arial',
        'TkDefaultFont',
        'FlutterTest',
      ]) {
        await _font(f, [m('Roboto-Regular.ttf'), m('Roboto-Bold.ttf')]);
      }
      await _font('packages/lucide_icons_flutter/Lucide', [
        'packages/lucide_icons_flutter/assets/lucide.ttf',
      ]);
    });

    tester.view.physicalSize = _size * 2;
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

    const kinds = {
      'sqlite': 'sqlite',
      'postgres': 'postgres',
      'mysql': 'mysql',
      'mongodb': 'mongodb',
    };
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
      for (final MapEntry(key: course, value: e)
          in tkShopCourseExamples(tr).entries) {
        final kind = kinds[course];
        final path = await tester.runAsync(() async {
          // La conexión «shop» guardada, como la tendría el usuario.
          for (final r in await DevTools.connections()) {
            await DevTools.deleteConnection(r['id'] as int);
          }
          if (kind != null) {
            await DevTools.saveConnection(
              null,
              kind: kind,
              name: 'shop',
              config: kind == 'sqlite'
                  ? {'path': p.join(tmp.path, 'shop.db')}
                  : {'host': 'localhost', 'database': 'shop'},
            );
          }
          return ProjectStore.create(
            e.name,
            description: e.description,
            design: e.design,
            code: e.code,
            seed: e.seed,
          );
        });
        final x = await tester.runAsync(() => ProjectStore.get(path!));
        for (final d in [...TkProject.opened]) {
          TkProject.close(d);
        }
        TkProject.open(x!);
        await settle(40);
        // En las ventanas, la tabla de productos elegida: el inspector
        // enseña su fuente de datos, su consulta y sus columnas.
        if (kind != null) {
          await tester.tap(find.byKey(const ValueKey('tk-w-Products')));
          await settle(15);
        }
        await tester.runAsync(() async {
          final ro =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await ro.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final f = File(p.join(_out!, course, 'designer-$lang.png'));
          await f.parent.create(recursive: true);
          await f.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
    }

    await tester.runAsync(() async {
      await StudioDb.close();
      await tmp.delete(recursive: true);
    });
  }, skip: _out == null);
}
