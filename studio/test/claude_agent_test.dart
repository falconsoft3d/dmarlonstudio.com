import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/ai/claude_agent.dart';
import 'package:dmarlon_studio/ai/text_diff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

/// Respuesta de la API de mensajes con [content] y [stop].
http.Response _reply(List<Map<String, Object?>> content, String stop) =>
    http.Response(
      jsonEncode({
        'id': 'msg_test',
        'type': 'message',
        'role': 'assistant',
        'model': 'claude-opus-5-5',
        'content': content,
        'stop_reason': stop,
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object?> _use(String id, String name, Map<String, Object?> input) =>
    {'type': 'tool_use', 'id': id, 'name': name, 'input': input};

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('claude_agent_test_');
    await File(
      p.join(dir.path, 'main.py'),
    ).writeAsString('def saludo():\n    return "hola"\n');
  });

  tearDown(() => dir.delete(recursive: true));

  test('lee, edita, crea y solo escribe al aplicar', () async {
    final sent = <Map<String, Object?>>[];
    final replies = [
      _reply([
        {'type': 'thinking', 'thinking': 'Miro el archivo.', 'signature': 's'},
        _use('t1', 'read_file', {'path': 'main.py'}),
      ], 'tool_use'),
      _reply([
        _use('t2', 'edit_file', {
          'path': 'main.py',
          'old_string': '"hola"',
          'new_string': '"hello"',
        }),
        _use('t3', 'write_file', {
          'path': 'docs/README.md',
          'content': '# Saludo\n',
        }),
      ], 'tool_use'),
      _reply([
        {'type': 'text', 'text': 'Cambiado el saludo y añadido un README.'},
      ], 'end_turn'),
    ];
    final client = MockClient((req) async {
      expect(req.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(req.headers['x-api-key'], 'test-key');
      sent.add((jsonDecode(req.body) as Map).cast<String, Object?>());
      return replies.removeAt(0);
    });
    final steps = <ClaudeStep>[];
    final agent = ClaudeAgent(
      apiKey: 'test-key',
      root: dir.path,
      client: client,
      onStep: steps.add,
    );

    final summary = await agent.run('Pon el saludo en inglés');

    expect(summary, contains('README'));
    expect(sent.first['model'], 'claude-opus-5-5');
    expect(sent.first['fallbacks'], 'default');
    // La segunda petición devuelve el pensamiento tal cual y el resultado.
    final second = (sent[1]['messages'] as List).cast<Map>();
    expect((second[1]['content'] as List).first['type'], 'thinking');
    final result = (second[2]['content'] as List).first as Map;
    expect(result['type'], 'tool_result');
    expect('${result['content']}', contains('1\tdef saludo():'));
    // Los dos resultados de la segunda vuelta van en un solo mensaje.
    final third = (sent[2]['messages'] as List).cast<Map>();
    expect((third.last['content'] as List).length, 2);
    expect(steps.any((s) => s.kind == 'thinking'), isTrue);

    // Propuesto, aún no escrito.
    expect(agent.changes.keys, unorderedEquals(['main.py', 'docs/README.md']));
    expect(
      await File(p.join(dir.path, 'main.py')).readAsString(),
      contains('"hola"'),
    );
    expect(agent.changes['docs/README.md']!.created, isTrue);
    final (add, del) = diffStats(
      lineDiff(
        agent.changes['main.py']!.before,
        agent.changes['main.py']!.after,
      ),
    );
    expect((add, del), (1, 1));

    final done = await agent.apply();
    expect(done, hasLength(2));
    expect(
      await File(p.join(dir.path, 'main.py')).readAsString(),
      contains('"hello"'),
    );
    expect(
      await File(p.join(dir.path, 'docs', 'README.md')).readAsString(),
      '# Saludo\n',
    );
    expect(agent.changes, isEmpty);
  });

  test(
    'las herramientas no salen de la carpeta y los errores vuelven a Claude',
    () async {
      final sent = <Map<String, Object?>>[];
      final replies = [
        _reply([
          _use('t1', 'read_file', {'path': '../fuera.txt'}),
          _use('t2', 'edit_file', {
            'path': 'main.py',
            'old_string': 'no existe',
            'new_string': 'x',
          }),
        ], 'tool_use'),
        _reply([
          {'type': 'text', 'text': 'No pude.'},
        ], 'end_turn'),
      ];
      final agent = ClaudeAgent(
        apiKey: 'k',
        root: dir.path,
        client: MockClient((req) async {
          sent.add((jsonDecode(req.body) as Map).cast<String, Object?>());
          return replies.removeAt(0);
        }),
      );
      await agent.run('Prueba');
      final results =
          ((sent[1]['messages'] as List).last as Map)['content'] as List;
      expect(results, hasLength(2));
      for (final r in results.cast<Map>()) {
        expect(r['is_error'], isTrue);
      }
      expect('${(results[0] as Map)['content']}', contains('outside'));
      expect(agent.changes, isEmpty);
    },
  );

  test('sin fallbacks en la cuenta, repite la petición sin ellos', () async {
    var calls = 0;
    final agent = ClaudeAgent(
      apiKey: 'k',
      root: dir.path,
      client: MockClient((req) async {
        calls++;
        final body = jsonDecode(req.body) as Map;
        if (body.containsKey('fallbacks')) {
          return http.Response(
            jsonEncode({
              'type': 'error',
              'error': {
                'type': 'invalid_request_error',
                'message': 'fallbacks: not available',
              },
            }),
            400,
          );
        }
        expect(req.headers.containsKey('anthropic-beta'), isFalse);
        return _reply([
          {'type': 'text', 'text': 'Hecho.'},
        ], 'end_turn');
      }),
    );
    expect(await agent.run('Hola'), 'Hecho.');
    expect(calls, 2);
  });

  test(
    'aplicar falla si el archivo cambió mientras Claude trabajaba',
    () async {
      final agent = ClaudeAgent(
        apiKey: 'k',
        root: dir.path,
        client: MockClient((req) async {
          final n = ((jsonDecode(req.body) as Map)['messages'] as List).length;
          return n == 1
              ? _reply([
                  _use('t1', 'write_file', {
                    'path': 'main.py',
                    'content': 'x\n',
                  }),
                ], 'tool_use')
              : _reply([
                  {'type': 'text', 'text': 'Listo.'},
                ], 'end_turn');
        }),
      );
      await agent.run('Reescribe');
      await File(p.join(dir.path, 'main.py')).writeAsString('otro\n');
      expect(agent.apply, throwsA(anything));
      expect(await File(p.join(dir.path, 'main.py')).readAsString(), 'otro\n');
    },
  );
}
