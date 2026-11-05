import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/core/mcp_server.dart';
import 'package:dmarlon_studio/core/project_store.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_mcp_');
    StudioDb.dirOverride = p.join(tmp.path, 'support');
    ProjectStore.workspaceOverride = p.join(tmp.path, 'Proyectos');
    await StudioDb.open();
    await McpServer.start(port: 0);
  });

  tearDown(() async {
    await McpServer.stop();
    await StudioDb.close();
    StudioDb.dirOverride = null;
    ProjectStore.workspaceOverride = null;
    await tmp.delete(recursive: true);
  });

  Future<(int, Object?)> post(
    Object body, {
    String? token,
    String? origin,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(McpServer.url));
      req.headers.contentType = ContentType.json;
      req.headers.set('accept', 'application/json, text/event-stream');
      req.headers.set('authorization', 'Bearer ${token ?? McpServer.token}');
      if (origin != null) req.headers.set('origin', origin);
      req.write(jsonEncode(body));
      final res = await req.close();
      final text = await utf8.decodeStream(res);
      return (res.statusCode, text.isEmpty ? null : jsonDecode(text));
    } finally {
      client.close();
    }
  }

  var nextId = 0;
  Future<Map> call(String tool, [Map<String, Object?> args = const {}]) async {
    final (code, body) = await post({
      'jsonrpc': '2.0',
      'id': ++nextId,
      'method': 'tools/call',
      'params': {'name': tool, 'arguments': args},
    });
    expect(code, 200);
    return (body as Map)['result'] as Map;
  }

  String text(Map result) => '${(result['content'] as List).first['text']}';

  test('protocolo, seguridad y herramientas', () async {
    final (code, init) = await post({
      'jsonrpc': '2.0',
      'id': 0,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-06-18',
        'capabilities': {},
        'clientInfo': {'name': 'test', 'version': '1'},
      },
    });
    expect(code, 200);
    expect((init as Map)['result']['serverInfo']['name'], 'dmarlon-studio');
    expect(init['result']['capabilities'], contains('tools'));

    // Las notificaciones no llevan respuesta.
    final (n, _) = await post({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    });
    expect(n, 202);

    // Sin token o desde otra web, nada.
    expect(
      (await post({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'ping',
      }, token: 'x')).$1,
      401,
    );
    expect(
      (await post({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'ping',
      }, origin: 'https://evil.example')).$1,
      403,
    );

    final (_, list) = await post({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'tools/list',
    });
    final names = [for (final t in (list as Map)['result']['tools']) t['name']];
    expect(
      names,
      containsAll([
        'list_projects',
        'add_component',
        'update_code',
        'run_project',
      ]),
    );

    // Crear, añadir un botón con su evento y generar el Python.
    final created = await call('create_project', {'name': 'Desde Claude'});
    expect(created['isError'], isFalse);
    final added = await call('add_component', {
      'project': 'Desde Claude',
      'kind': 'Button',
      'name': 'BtnHola',
      'x': 20,
      'y': 30,
      'props': {'text': 'Hola'},
      'events': {'command': 'BtnHola_click'},
    });
    expect(added['isError'], isFalse, reason: text(added));
    final project =
        jsonDecode(text(await call('get_project', {'project': 'Desde Claude'})))
            as Map;
    final widgets = (project['design'] as Map)['widgets'] as List;
    expect(widgets.single['name'], 'BtnHola');
    expect(project['code'], contains('def BtnHola_click(self)'));

    await call('update_component', {
      'project': 'Desde Claude',
      'name': 'BtnHola',
      'width': 160,
      'props': {'text': 'Saludar'},
    });
    final py = text(await call('generate_python', {'project': 'Desde Claude'}));
    expect(py, contains('Saludar'));
    expect(py, isNot(contains('Problems:')));

    // Los errores vuelven como resultado con isError, no como fallo.
    final bad = await call('add_component', {
      'project': 'Desde Claude',
      'kind': 'Nada',
    });
    expect(bad['isError'], isTrue);
    expect(text(bad), contains('list_components'));
    final missing = await call('get_project', {'project': 'No existe'});
    expect(missing['isError'], isTrue);

    final catalog = jsonDecode(text(await call('list_components'))) as List;
    expect(catalog.map((c) => c['kind']), contains('AiAssistant'));
  });
}
