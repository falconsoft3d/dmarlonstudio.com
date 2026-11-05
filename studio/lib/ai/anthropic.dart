import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';

/// Adaptador de la API de mensajes de Anthropic (POST /v1/messages). La
/// conversación sigue en el formato de OpenAI, el que usa todo el asistente:
/// aquí se traduce al enviar y al recibir.
///
/// No hay SDK oficial para Dart, así que va por HTTP directo.
class AnthropicApi {
  AnthropicApi._();

  /// `max_tokens` es obligatorio. Con este valor la petición sin streaming
  /// no llega al tiempo límite de la API.
  static const maxTokens = 16000;

  /// Bloques originales de la respuesta, para devolverlos tal cual (empieza
  /// por `_`: no se envía a las API de formato OpenAI).
  static const blocksKey = '_blocks';

  static const _thinking = {'thinking', 'redacted_thinking'};

  /// Cuerpo de la petición para [history], en formato de OpenAI.
  ///
  /// Los razonamientos solo se devuelven dentro del turno en curso (entre
  /// herramienta y herramienta). Su firma cubre las indicaciones y todo lo
  /// anterior, y al retomar una conversación otro día las indicaciones
  /// cambian: devolverlos daría un error 400. Quitarlos siempre de los turnos
  /// anteriores es estable porque la ventana que se envía es contigua.
  static Map<String, Object?> request(
    List<Map<String, Object?>> history, {
    required String model,
    List<Map<String, Object?>> tools = const [],
  }) {
    final system = <String>[];
    final messages = <Map<String, Object?>>[];
    void add(String role, List<Map<String, Object?>> blocks) {
      if (blocks.isEmpty) return;
      // Los mensajes seguidos del mismo papel van juntos (los resultados de
      // herramientas, en un solo mensaje).
      if (messages.isNotEmpty && messages.last['role'] == role) {
        (messages.last['content'] as List).addAll(blocks);
      } else {
        messages.add({'role': role, 'content': blocks});
      }
    }

    final turn = history.lastIndexWhere((m) => m['role'] == 'user');
    for (final (i, m) in history.indexed) {
      switch (m['role']) {
        case 'system' || 'developer':
          final t = _plain(m['content']);
          if (t.isNotEmpty) system.add(t);
        case 'user':
          add('user', _userBlocks(m['content']));
        case 'assistant':
          add('assistant', _assistantBlocks(m, thinking: i > turn));
        case 'tool':
          add('user', [
            {
              'type': 'tool_result',
              'tool_use_id': m['tool_call_id'],
              'content': '${m['content'] ?? ''}',
            },
          ]);
      }
    }
    return {
      'model': model,
      'max_tokens': maxTokens,
      if (system.isNotEmpty) 'system': system.join('\n\n'),
      'messages': messages,
      if (tools.isNotEmpty)
        'tools': [
          for (final t in tools)
            {
              'name': (t['function'] as Map)['name'],
              'description': (t['function'] as Map)['description'],
              'input_schema': (t['function'] as Map)['parameters'],
            },
        ],
    };
  }

  static String _plain(Object? content) => content is List
      ? content
            .whereType<Map>()
            .where((p) => p['type'] == 'text')
            .map((p) => '${p['text'] ?? ''}')
            .join('\n')
      : '${content ?? ''}';

  static List<Map<String, Object?>> _userBlocks(Object? content) {
    if (content is! List) {
      final text = '${content ?? ''}';
      return text.isEmpty
          ? const []
          : [
              {'type': 'text', 'text': text},
            ];
    }
    return [
      for (final p in content.whereType<Map>())
        if (p['type'] == 'text' && '${p['text'] ?? ''}'.isNotEmpty)
          {'type': 'text', 'text': p['text']}
        else if (p['type'] == 'image_url')
          _image('${(p['image_url'] as Map?)?['url'] ?? ''}'),
    ];
  }

  static Map<String, Object?> _image(String url) {
    final data = RegExp(r'^data:([^;,]+);base64,(.*)$', dotAll: true);
    final m = data.firstMatch(url);
    return {
      'type': 'image',
      'source': m == null
          ? {'type': 'url', 'url': url}
          : {'type': 'base64', 'media_type': m[1], 'data': m[2]},
    };
  }

  static List<Map<String, Object?>> _assistantBlocks(
    Map<String, Object?> m, {
    required bool thinking,
  }) {
    final saved = m[blocksKey];
    if (saved is List) {
      return [
        for (final b in saved.cast<Map>())
          if (thinking || !_thinking.contains(b['type']))
            b.cast<String, Object?>(),
      ];
    }
    final text = _plain(m['content']);
    return [
      if (text.isNotEmpty) {'type': 'text', 'text': text},
      for (final c in ((m['tool_calls'] as List?) ?? const []).cast<Map>())
        {
          'type': 'tool_use',
          'id': c['id'],
          'name': (c['function'] as Map)['name'],
          'input': _input((c['function'] as Map)['arguments']),
        },
    ];
  }

  static Object? _input(Object? arguments) {
    if (arguments is Map) return arguments;
    try {
      final j = jsonDecode('${arguments ?? '{}'}');
      return j is Map ? j : const {};
    } on FormatException {
      return const {};
    }
  }

  /// Respuesta de la API como mensaje en formato de OpenAI.
  static Map<String, Object?> reply(Map body) {
    final blocks = ((body['content'] as List?) ?? const []).cast<Map>();
    final text = StringBuffer();
    final calls = <Map<String, Object?>>[];
    for (final b in blocks) {
      if (b['type'] == 'text') text.write(b['text'] ?? '');
      if (b['type'] == 'tool_use') {
        calls.add({
          'id': b['id'],
          'type': 'function',
          'function': {
            'name': b['name'],
            'arguments': jsonEncode(b['input'] ?? const {}),
          },
        });
      }
    }
    final stop = body['stop_reason'];
    if (stop == 'refusal') {
      throw UserError(
        tr(
          'Claude ha rechazado esta petición por sus filtros de seguridad. Reformúlela o elija otro modelo.',
        ),
      );
    }
    // Una llamada cortada no se ejecuta: sus datos pueden estar incompletos.
    if (stop == 'max_tokens' && calls.isNotEmpty) {
      throw UserError(
        tr(
          'La respuesta de la IA se cortó antes de terminar. Concrete un poco más la petición.',
        ),
      );
    }
    return {
      'role': 'assistant',
      'content': text.toString(),
      if (calls.isNotEmpty) 'tool_calls': calls,
      blocksKey: blocks,
    };
  }
}
