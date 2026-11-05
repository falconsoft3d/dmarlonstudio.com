import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_flutter_db.dart';
import 'package:dmarlon_studio/code/tk_flutter_run.dart';
import 'package:dmarlon_studio/code/tk_flutter_templates.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_run.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

void main() {
  test('cadenas y acciones de Dart', () {
    expect(TkFlutter.str(r'Hola ${app.name}'), r"'Hola ${app.name}'");
    expect(TkFlutter.str(r"it's $5"), r"'it\'s \$5'");
    expect(
      TkFlutter.str(r'${a.map((x) => {x}).length} ok'),
      r"'${a.map((x) => {x}).length} ok'",
    );
    expect(
      TkFlutter.action('app.crear(); back'),
      'app.crear(); Navigator.of(context).maybePop();',
    );
    expect(
      TkFlutter.action('go:Detalle(item)'),
      "Navigator.of(context).pushNamed('/Detalle', arguments: item);",
    );
    expect(TkFlutter.action("app.f('a;b')"), "app.f('a;b');");
    expect(TkFlutter.color('#ff0000'), 'const Color(0xFFFF0000)');
    expect(TkFlutter.color('primary'), 'Theme.of(context).colorScheme.primary');
    expect(TkFlutter.color('=app.c(item)'), 'app.c(item)');
  });

  test('el modelo de la app va y vuelve por el diseño', () {
    final d = TkDesign(target: tkTargetFlutter);
    TkFlutter.starter('Prueba').saveTo(d);
    final back = TkDesign.fromJson(d.toJson());
    expect(back.isFlutter, isTrue);
    expect(back.codeLang, 'dart');
    final app = FlApp.of(back);
    expect(app.screens.single.name, 'Inicio');
    expect(app.screens.single.body.type, 'Center');
    expect(
      TkFlutter.main(app),
      contains("'/Inicio': (context) => const InicioScreen()"),
    );
  });

  test('las demos generan su main.dart', () {
    for (final e in tkFlutterExamples(id)) {
      final files = TkFlutter.files(e.design, e.code, name: e.seed);
      expect(files['lib/main.dart'], contains('class DmsApp'));
      expect(files['lib/app.dart'], e.code);
    }
  });

  /// Escribe una app con [backend] y [test] en una carpeta temporal.
  Future<Directory> appWith(FlBackend backend, {String? test}) async {
    final tmp = await Directory.systemTemp.createTemp('dms_db_');
    addTearDown(() => tmp.delete(recursive: true));
    final d = TkDesign(target: tkTargetFlutter);
    (TkFlutter.starter('Base')..backend = backend).saveTo(d);
    final files = TkFlutter.files(
      d,
      TkFlutter.template('// app'),
      name: 'base',
    );
    expect(files['pubspec.yaml'], contains('http: ^1.2.0'));
    for (final f in files.entries) {
      File(p.join(tmp.path, f.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          f.key == 'pubspec.yaml'
              ? f.value.replaceFirst(
                  'dev_dependencies:\n',
                  'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n',
                )
              : f.value,
        );
    }
    if (test != null) {
      File(p.join(tmp.path, 'test', 'db_test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(test);
    }
    return tmp;
  }

  test(
    'de verdad: las 20 plantillas de pantalla compilan juntas',
    () async {
      final flutter = TkFlutterTools.flutter();
      if (flutter == null) return markTestSkipped('Sin Flutter.');
      expect(flTemplates, hasLength(20));
      final d = TkDesign(target: tkTargetFlutter);
      final app = FlApp(
        title: 'Plantillas',
        screens: [
          for (final tpl in flTemplates)
            tpl.build('P${tpl.id.replaceAll('_', '')}', id),
        ],
      );
      app.saveTo(d);
      final tmp = await Directory.systemTemp.createTemp('dms_tpl_');
      addTearDown(() => tmp.delete(recursive: true));
      for (final f in TkFlutter.files(
        d,
        TkFlutter.template('// app'),
        name: 'plantillas',
      ).entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(f.value);
      }
      final r = await Process.run(flutter, [
        'analyze',
      ], workingDirectory: tmp.path);
      expect(
        '${r.stdout}',
        contains('No issues found'),
        reason: '${r.stdout}${r.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'Firebase: el lib/db.dart generado compila sin avisos',
    () async {
      final flutter = TkFlutterTools.flutter();
      if (flutter == null) return markTestSkipped('Sin Flutter.');
      final dir = await appWith(
        const FlBackend(kind: 'firebase', project: 'demo', key: 'AIza-demo'),
      );
      expect(
        File(p.join(dir.path, 'lib', 'db.dart')).readAsStringSync(),
        contains('firestore.googleapis.com'),
      );
      final r = await Process.run(flutter, [
        'analyze',
      ], workingDirectory: dir.path);
      expect(
        '${r.stdout}',
        contains('No issues found'),
        reason: '${r.stdout}${r.stderr}',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'de verdad: lib/db.dart con FalconDatabase (tablas y sesión)',
    () async {
      final flutter = TkFlutterTools.flutter();
      final falcon = Platform.environment['DMS_FALCON'];
      final user = Platform.environment['DMS_FALCON_USER'];
      if (flutter == null || falcon == null || user == null) {
        return markTestSkipped('Sin Flutter, DMS_FALCON o DMS_FALCON_USER.');
      }
      final (ref, key) = (
        falcon.split(':').first,
        falcon.split(':').skip(1).join(':'),
      );
      final (email, pass) = (
        user.split(':').first,
        user.split(':').skip(1).join(':'),
      );
      final dir = await appWith(
        FlBackend(kind: 'falcon', project: ref, key: key),
        test: _falconTest.replaceAll('EMAIL', email).replaceAll('PASS', pass),
      );
      final r = await Process.run(flutter, [
        'analyze',
      ], workingDirectory: dir.path);
      expect(
        '${r.stdout}',
        contains('No issues found'),
        reason: '${r.stdout}${r.stderr}',
      );
      final t = await Process.run(flutter, [
        'test',
      ], workingDirectory: dir.path);
      expect(t.exitCode, 0, reason: '${t.stdout}${t.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'de verdad: el ejemplo de notas en la nube contra FalconDatabase',
    () async {
      final flutter = TkFlutterTools.flutter();
      final falcon = Platform.environment['DMS_FALCON'];
      final user = Platform.environment['DMS_FALCON_USER'];
      if (flutter == null || falcon == null || user == null) {
        return markTestSkipped('Sin Flutter, DMS_FALCON o DMS_FALCON_USER.');
      }
      final (ref, key) = (
        falcon.split(':').first,
        falcon.split(':').skip(1).join(':'),
      );
      final (email, pass) = (
        user.split(':').first,
        user.split(':').skip(1).join(':'),
      );
      final e = tkFlutterExamples(
        id,
      ).firstWhere((e) => e.seed == 'flutter_cloud_notes');
      final d = TkDesign.fromJson(e.design.toJson());
      final app = FlApp.of(d)
        ..backend = FlBackend(kind: 'falcon', project: ref, key: key);
      app.saveTo(d);
      final tmp = await Directory.systemTemp.createTemp('dms_notes_');
      addTearDown(() => tmp.delete(recursive: true));
      for (final f in TkFlutter.files(d, e.code, name: 'notas').entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            f.key == 'pubspec.yaml'
                ? f.value.replaceFirst(
                    'dev_dependencies:\n',
                    'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n',
                  )
                : f.value,
          );
      }
      File(p.join(tmp.path, 'test', 'notas_test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          _notesTest.replaceAll('EMAIL', email).replaceAll('PASS', pass),
        );
      final r = await Process.run(flutter, [
        'analyze',
      ], workingDirectory: tmp.path);
      expect(
        '${r.stdout}',
        contains('No issues found'),
        reason: '${r.stdout}${r.stderr}',
      );
      final t = await Process.run(flutter, [
        'test',
      ], workingDirectory: tmp.path);
      expect(t.exitCode, 0, reason: '${t.stdout}${t.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'de verdad: el inventario de escritorio pasa su flujo (menú lateral)',
    () async {
      final flutter = TkFlutterTools.flutter();
      if (flutter == null) return markTestSkipped('Sin Flutter.');
      final tmp = await Directory.systemTemp.createTemp('dms_inv_');
      addTearDown(() => tmp.delete(recursive: true));
      final e = tkFlutterExamples(
        id,
      ).firstWhere((e) => e.seed == 'flutter_inventory');
      expect(e.design.isFlutterDesktop, isTrue);
      for (final f in TkFlutter.files(
        e.design,
        e.code,
        name: 'inventario',
      ).entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            f.key == 'pubspec.yaml'
                ? f.value.replaceFirst(
                    'dev_dependencies:\n',
                    'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n',
                  )
                : f.value,
          );
      }
      File(p.join(tmp.path, 'test', 'flujo_test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(_inventoryFlow);
      final a = await Process.run(flutter, [
        'analyze',
      ], workingDirectory: tmp.path);
      expect(
        '${a.stdout}',
        contains('No issues found'),
        reason: '${a.stdout}${a.stderr}',
      );
      final r = await Process.run(flutter, [
        'test',
      ], workingDirectory: tmp.path);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'de verdad: la app de escritorio se abre en su ventana y se recarga',
    () async {
      if (!Platform.isMacOS || TkFlutterTools.flutter() == null) {
        return markTestSkipped('Solo en macOS con Flutter.');
      }
      final tmp = await Directory.systemTemp.createTemp('dms_fldesk_');
      addTearDown(() => tmp.delete(recursive: true));
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      final dir = await ProjectStore.create(
        'Escritorio',
        design: TkDesign(target: tkTargetFlutterDesktop),
      );
      final prepared = await ProjectStore.prepareRun(dir);
      expect(prepared.desktop, isTrue);
      final run = await TkRunner.start(prepared);
      addTearDown(run.stop);
      Future<void> until(bool Function() ok, {int seconds = 300}) async {
        final end = DateTime.now().add(Duration(seconds: seconds));
        while (!ok() && run.running && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }

      await until(
        () => run.lines.any((l) => l.contains('Abierta en su ventana')),
      );
      expect(
        run.lines.any((l) => l.contains('Abierta en su ventana')),
        isTrue,
        reason: run.lines.join('\n'),
      );
      // La ventana existe (y no es un proceso en segundo plano).
      final ps = await Process.run('pgrep', [
        '-f',
        'escritorio.app/Contents/MacOS',
      ]);
      final pid = '${ps.stdout}'.trim().split('\n').first;
      expect(pid, isNotEmpty);
      // La ventana puede tardar un poco en aparecer tras el arranque.
      ProcessResult w;
      var tries = 0;
      do {
        if (tries++ > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        w = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to get {background only, count of windows} of (first process whose unix id is $pid)',
        ]);
      } while ('${w.stdout}'.trim() != 'false, 1' && tries < 30);
      // Con la pantalla bloqueada, System Events no ve ventanas: no se puede
      // comprobar.
      final lock = await Process.run('ioreg', ['-n', 'Root', '-d1', '-a']);
      final locked = RegExp(
        r'CGSSessionScreenIsLocked</key>\s*<true/>',
      ).hasMatch('${lock.stdout}');
      if (locked) {
        // ignore: avoid_print
        print('Pantalla bloqueada: no se cuentan las ventanas.');
      } else {
        expect('${w.stdout}'.trim(), 'false, 1', reason: '${w.stderr}');
      }
      // Cambiar el código y recargar.
      final app = File(prepared.file);
      await app.writeAsString(
        (await app.readAsString()).replaceFirst('counter++', 'counter += 2'),
      );
      run.input!('R');
      await until(
        () => run.lines.any((l) => l.contains('Recargada')),
        seconds: 120,
      );
      expect(
        run.lines.any((l) => l.contains('Recargada')),
        isTrue,
        reason: run.lines.join('\n'),
      );
      run.stop();
      await until(() => !run.running, seconds: 30);
      await StudioDb.close();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test(
    'de verdad: la tienda generada pasa su flujo (login, carrito y pago)',
    () async {
      final flutter = TkFlutterTools.flutter();
      if (flutter == null) return markTestSkipped('Sin Flutter.');
      final tmp = await Directory.systemTemp.createTemp('dms_store_');
      addTearDown(() => tmp.delete(recursive: true));
      final e = tkFlutterExamples(
        id,
      ).firstWhere((e) => e.seed == 'flutter_store');
      for (final f in TkFlutter.files(
        e.design,
        e.code,
        name: 'tienda',
      ).entries) {
        File(p.join(tmp.path, f.key))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            f.key == 'pubspec.yaml'
                ? f.value.replaceFirst(
                    'dev_dependencies:\n',
                    'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n',
                  )
                : f.value,
          );
      }
      File(p.join(tmp.path, 'test', 'flujo_test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(_storeFlow);
      final r = await Process.run(flutter, [
        'test',
      ], workingDirectory: tmp.path);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'de verdad: la demo de tareas en el simulador, y se recompila',
    () async {
      if (TkFlutterTools.flutter() == null) {
        return markTestSkipped('Sin Flutter.');
      }
      final tmp = await Directory.systemTemp.createTemp('dms_flutter_');
      addTearDown(() => tmp.delete(recursive: true));
      StudioDb.dirOverride = p.join(tmp.path, 'support');
      ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
      await StudioDb.open();
      final e = tkFlutterExamples(
        id,
      ).firstWhere((e) => e.seed == 'flutter_todo');
      final dir = await ProjectStore.create(
        'Tareas',
        design: e.design,
        code: e.code,
      );
      final prepared = await ProjectStore.prepareRun(dir);
      expect(prepared.flutter, isTrue);
      final run = await TkRunner.start(prepared);
      addTearDown(run.stop);
      Future<void> until(bool Function() ok, {int seconds = 300}) async {
        final end = DateTime.now().add(Duration(seconds: seconds));
        while (!ok() && run.running && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }

      await until(() => run.url != null);
      expect(run.url, isNotNull, reason: run.lines.join('\n'));
      final client = HttpClient();
      addTearDown(client.close);
      Future<String> get(String url) async {
        final r = await (await client.getUrl(Uri.parse(url))).close();
        return r.transform(const SystemEncoding().decoder).join();
      }

      final page = await get(run.url!);
      expect(page, contains('<iframe id="app"'));
      final appUrl = RegExp(r'src="(http://[^"]+)"').firstMatch(page)![1]!;
      expect(await get(appUrl), contains('flutter_bootstrap.js'));
      expect(await get('${run.url}version'), '0');
      // Al cambiar el código y pedir R, se recompila y el simulador lo sabe.
      final app = File(prepared.file);
      await app.writeAsString(
        (await app.readAsString()).replaceFirst('Comprar pan', 'Comprar leche'),
      );
      run.input!('R');
      await until(
        () => run.lines.any((l) => l.contains('Recompilada')),
        seconds: 120,
      );
      expect(await get('${run.url}version'), '1', reason: run.lines.join('\n'));
      run.stop();
      await until(() => !run.running, seconds: 20);
      await StudioDb.close();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

/// El recorrido de la tienda: se ejecuta dentro de la app generada.
const _storeFlow = r'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda/main.dart';

void main() {
  testWidgets('login, carrito y pago', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DmsApp());
    await tester.pumpAndSettle();

    // Clave mala: se queda y avisa.
    await tester.enterText(find.byType(TextField).at(0), 'demo@tienda.com');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);

    // Clave buena: al catálogo, sin vuelta atrás al login.
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Camiseta básica'), findsOneWidget);

    // Buscar y filtrar.
    await tester.enterText(find.byType(TextField).first, 'auri');
    await tester.pumpAndSettle();
    expect(find.text('Auriculares'), findsOneWidget);
    expect(find.text('Camiseta básica'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hogar'));
    await tester.pumpAndSettle();
    expect(find.text('Silla nórdica'), findsOneWidget);
    expect(find.text('Auriculares'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hogar'));
    await tester.pumpAndSettle();

    // Dos al carrito desde la lista y la ficha de uno.
    await tester.tap(find.byTooltip('Añadir al carrito').first);
    await tester.tap(find.byTooltip('Añadir al carrito').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lámpara de mesa'));
    await tester.pumpAndSettle();
    expect(find.text('24,00 €'), findsOneWidget);
    await tester.tap(find.text('Añadir al carrito'));
    await tester.tap(find.text('Ver el carrito'));
    await tester.pumpAndSettle();

    // Carrito: 2 camisetas + 1 lámpara = 49,80 €; quitar una camiseta.
    expect(find.text('2 × 12,90 €'), findsOneWidget);
    expect(find.text('49,80 €'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('36,90 €'), findsWidgets);

    // Pagar.
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Gracias por su compra, Ana!'), findsOneWidget);
    expect(find.text('PED-1001 · 36,90 €'), findsOneWidget);
    await tester.tap(find.text('Seguir comprando'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);

    // Salir: vuelve al login.
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
  });
}
''';

/// Contra FalconDatabase de verdad: «productos» es pública y «notas» pide
/// sesión.
const _falconTest = r'''
import 'package:base/db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tablas públicas', () async {
    final rows = await db.table('productos').list(order: 'id');
    expect(rows.first.keys, containsAll(['id', 'nombre', 'precio']));
    final nuevo = await db.table('productos').insert({'nombre': 'Desde Flutter', 'precio': 3.5});
    final id = nuevo['id'];
    final cambiado = await db.table('productos').update(id, {'precio': 4.25});
    expect(cambiado['precio'], 4.25);
    final caros = await db.table('productos').list(where: {'nombre': 'Desde Flutter', 'precio': 'gte.4'});
    expect(caros.map((r) => r['id']), contains(id));
    expect((await db.table('productos').get(id))?['nombre'], 'Desde Flutter');
    await db.table('productos').delete(id);
    expect(await db.table('productos').get(id), isNull);
  });

  test('sesión', () async {
    await expectLater(db.signIn('EMAIL', 'mala'), throwsA(isA<DbError>()));
    expect(() => db.table('notas').list(), throwsA(isA<DbError>()));
    final user = await db.signIn('EMAIL', 'PASS');
    expect(user['email'], 'EMAIL');
    final nota = await db.table('notas').insert({'texto': 'hola desde Flutter'});
    final notas = await db.table('notas').list();
    expect(notas.map((n) => n['texto']), contains('hola desde Flutter'));
    await db.table('notas').delete(nota['id']);
    db.signOut();
    await expectLater(db.table('notas').list(), throwsA(isA<DbError>()));
  });
}
''';

/// La lógica del ejemplo de notas, contra FalconDatabase de verdad.
const _notesTest = r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:notas/app.dart';

void main() {
  test('login, guardar, listar, borrar y salir', () async {
    final app = App();
    expect(app.configurada, isTrue);
    app.email = 'EMAIL';
    app.clave = 'mala';
    expect(await app.entrar(), isFalse);
    expect(app.error, isNotEmpty);
    app.clave = 'PASS';
    expect(await app.entrar(), isTrue);
    expect(app.usuario, 'EMAIL');
    app.nueva = 'Nota de prueba DMS';
    await app.agregar();
    expect(app.nueva, '');
    expect(app.notas.first['texto'], 'Nota de prueba DMS');
    await app.cargar();
    final nota = app.notas.firstWhere((n) => n['texto'] == 'Nota de prueba DMS');
    expect(app.fecha(nota), isNotEmpty);
    await app.borrar(nota);
    await app.cargar();
    expect(app.notas.where((n) => n['texto'] == 'Nota de prueba DMS'), isEmpty);
    app.salir();
    expect(app.usuario, '');
  });
}
''';

/// El recorrido del inventario: se ejecuta dentro de la app generada, en
/// una ventana ancha (menú lateral).
const _inventoryFlow = r'''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/main.dart';

void main() {
  testWidgets('panel, productos, existencias y alta', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DmsApp());
    await tester.pumpAndSettle();

    // Panel con el menú lateral: dos productos con poco stock.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Taladro'), findsOneWidget);
    expect(find.text('Guantes de trabajo'), findsOneWidget);
    expect(find.text('Cinta métrica'), findsNothing);

    // A Productos por el menú, y buscar.
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Productos')));
    await tester.pumpAndSettle();
    expect(find.text('Cinta métrica'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'herram');
    await tester.pumpAndSettle();
    expect(find.text('Taladro'), findsOneWidget);
    expect(find.text('Tornillos M6'), findsNothing);

    // Ficha del taladro: +10 lo saca del aviso.
    await tester.tap(find.text('Taladro'));
    await tester.pumpAndSettle();
    expect(find.text('Por debajo del mínimo (5 uds.)'), findsOneWidget);
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Por debajo del mínimo (5 uds.)'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Alta de un producto.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Martillo');
    await tester.enterText(find.widgetWithText(TextField, 'Existencias'), '2');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Martillo'), findsOneWidget);

    // En el panel, el martillo (2 uds.) aparece con poco stock.
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Panel')));
    await tester.pumpAndSettle();
    expect(find.text('Martillo'), findsOneWidget);
    expect(find.text('Taladro'), findsNothing);
  });
}
''';
