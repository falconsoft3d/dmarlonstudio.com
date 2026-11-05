import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_flutter.dart';
import 'package:dmarlon_studio/code/tk_flutter_run.dart';
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
