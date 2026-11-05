import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/errors.dart';
import '../core/settings.dart';
import '../i18n/tr.dart';
import 'anthropic.dart';
import 'providers.dart';

export 'providers.dart';

/// Configuración del asistente (por base de datos). [apiKey], [model] y
/// [baseUrl] son los del proveedor activo; los de los demás se recuerdan en
/// [keys], [models] y [urls] para no perderlos al cambiar de proveedor.
class AiConfig {
  AiConfig({
    this.apiKey = '',
    String? model,
    String? baseUrl,
    String? voiceModel,
    this.speak = true,
    AiProvider? provider,
    this.voiceProvider,
    Map<String, String>? keys,
    Map<String, String>? models,
    Map<String, String>? urls,
  }) : provider = provider ?? AiProvider.infer(baseUrl),
       model = model ?? (provider ?? AiProvider.infer(baseUrl)).defaultModel,
       baseUrl = baseUrl ?? (provider ?? AiProvider.infer(baseUrl)).baseUrl,
       voiceModel =
           voiceModel ??
           (voiceProvider ?? provider)?.voiceModels.firstOrNull ??
           defaultVoiceModel,
       keys = {...?keys},
       models = {...?models},
       urls = {...?urls};

  AiProvider provider;
  String apiKey, model, baseUrl;

  /// Claves, modelos y URL de cada proveedor (por su id).
  final Map<String, String> keys, models, urls;

  /// Modelo de transcripción de la voz (Whisper o compatible).
  String voiceModel;

  /// Quién transcribe la voz si no es el proveedor del chat.
  AiProvider? voiceProvider;

  /// Leer en voz alta las respuestas del modo voz.
  bool speak;

  static const defaultModel = 'gpt-4.1-mini';
  static const defaultVoiceModel = 'whisper-1';
  static const defaultBaseUrl = 'https://api.openai.com/v1';

  bool get ready =>
      baseUrl.trim().isNotEmpty &&
      (!provider.needsKey || apiKey.trim().isNotEmpty);

  /// La misma configuración con otro modelo (mismo proveedor y clave).
  AiConfig copyWith({String? model}) => AiConfig(
    apiKey: apiKey,
    model: model ?? this.model,
    baseUrl: baseUrl,
    voiceModel: voiceModel,
    speak: speak,
    provider: provider,
    voiceProvider: voiceProvider,
    keys: keys,
    models: models,
    urls: urls,
  );

  /// Qué falta para usar el asistente, nombrando al proveedor elegido.
  String get missingKey => tr(
    'Configure la clave de {0} en Ajustes → Inteligencia artificial.',
    [provider.vendor],
  );

  void _remember() {
    final id = provider.id;
    apiKey.trim().isEmpty ? keys.remove(id) : keys[id] = apiKey.trim();
    if (model.trim().isNotEmpty) models[id] = model.trim();
    if (provider.editableUrl) urls[id] = baseUrl.trim();
  }

  /// Cambia de proveedor recuperando su clave, modelo y URL.
  void select(AiProvider p) {
    _remember();
    provider = p;
    apiKey = keys[p.id] ?? '';
    model = models[p.id] ?? p.defaultModel;
    baseUrl = urls[p.id] ?? p.baseUrl;
  }

  /// Clave guardada de un proveedor.
  String keyOf(AiProvider p) =>
      identical(p, provider) ? apiKey.trim() : keys[p.id] ?? '';

  /// Quién transcribe la voz: el proveedor elegido para ello o el del chat.
  /// Null si ninguno puede.
  AiProvider? get transcriber {
    final p = voiceProvider ?? provider;
    return p.voice ? p : null;
  }

  String get voiceKey => keyOf(transcriber ?? provider);

  String get voiceBaseUrl {
    final p = transcriber ?? provider;
    return identical(p, provider) ? baseUrl : urls[p.id] ?? p.baseUrl;
  }

  /// Comprueba que se pueda transcribir (lanza un error claro si no).
  void requireVoice() {
    final p = transcriber;
    if (p == null) {
      throw UserError(
        tr(
          '{0} no transcribe voz. Elija quién la transcribe en Ajustes → Inteligencia artificial.',
          [provider.vendor],
        ),
      );
    }
    if (p.needsKey && voiceKey.isEmpty) {
      throw UserError(
        tr(
          'Falta la clave de {0} para transcribir la voz. Escríbala en Ajustes → Inteligencia artificial.',
          [p.vendor],
        ),
      );
    }
  }

  /// Modelos de OpenAI conocidos (si no se puede consultar la API).
  static List<String> get knownChatModels => AiProvider.openai.models;
  static List<String> get knownVoiceModels => AiProvider.openai.voiceModels;

  /// Modelos de la cuenta: los de chat y los de voz. Sin [provider], el que
  /// corresponde a la URL. Si ninguno parece de chat, todos van como de chat.
  static Future<({List<String> chat, List<String> voice})> listModels(
    String baseUrl,
    String apiKey, {
    http.Client? client,
    AiProvider? provider,
  }) async {
    final p = provider ?? AiProvider.infer(baseUrl);
    final url = Uri.parse(
      p.modelsUrl ?? '${AiProvider.trimUrl(baseUrl)}/models',
    );
    final http.Response res;
    try {
      res = await (client ?? http.Client()).get(
        url,
        headers: p.authHeaders(apiKey),
      );
    } catch (e) {
      throw UserError(tr('No se pudo conectar con {0}: {1}', [url.host, e]));
    }
    if (res.statusCode != 200) {
      throw UserError(
        tr('Error de la IA ({0}): {1}', [
          res.statusCode,
          aiErrorOf(utf8.decode(res.bodyBytes)),
        ]),
      );
    }
    final ids = AiProvider.modelIds(jsonDecode(utf8.decode(res.bodyBytes)));
    // Anthropic ya los da del más reciente al más antiguo.
    if (p.protocol != AiProtocol.anthropic) {
      ids.sort((a, b) => b.compareTo(a));
    }
    final chat = ids.where(p.isChatModel).toList();
    final voice = ids.where(AiProvider.isVoiceModel).toList();
    return (
      chat: chat.isEmpty
          ? ids.where((i) => !AiProvider.isVoiceModel(i)).toList()
          : chat,
      voice: voice,
    );
  }

  /// Nota corta sobre un modelo para la lista, de cualquier proveedor.
  static String modelHint(
    String id, [
    AiProvider provider = AiProvider.openai,
  ]) {
    if (id.toLowerCase() == provider.defaultModel) return tr('recomendado');
    // OpenRouter y Perplexity: «creador/modelo».
    final m = id.toLowerCase().split('/').last;
    bool word(String w) => RegExp('(^|[^a-z])$w([^a-z]|\$)').hasMatch(m);
    if (RegExp(r'^o\d').hasMatch(m) ||
        m.startsWith('gpt-5') && !m.contains('chat')) {
      return tr('razona más: más lento');
    }
    if (word('nano')) return tr('el más rápido y barato');
    if (['mini', 'lite', 'small', 'instant', 'flash'].any(word) ||
        m.contains('haiku')) {
      return tr('rápido y barato');
    }
    if (AiProvider.isVoiceModel(m)) return '';
    if (m.startsWith('gpt-4o') ||
        m.startsWith('gpt-4.1') ||
        m.startsWith('chatgpt')) {
      return tr('admite imágenes');
    }
    if (RegExp(r'opus|fable|argon|large|reason|magistral').hasMatch(m) ||
        word('pro')) {
      return tr('razona más: más lento');
    }
    return '';
  }

  static Future<AiConfig> load() async {
    final p = await Settings.get('ai.config');
    // Sin configurar: Claude, la IA recomendada del estudio.
    if (p == null) return AiConfig(provider: AiProvider.anthropic);
    try {
      final j = jsonDecode(p) as Map<String, Object?>;
      Map<String, String> map(String k) => {
        for (final e in ((j[k] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      };
      // Sin proveedor (versiones anteriores): según la URL.
      final provider =
          AiProvider.byId(j['provider']) ??
          AiProvider.infer(j['base_url'] as String?);
      final keys = map('keys');
      return AiConfig(
        provider: provider,
        apiKey: keys[provider.id] ?? '${j['api_key'] ?? ''}',
        model: '${j['model'] ?? provider.defaultModel}',
        baseUrl: '${j['base_url'] ?? provider.baseUrl}',
        voiceModel: '${j['voice_model'] ?? defaultVoiceModel}',
        voiceProvider: AiProvider.byId(j['voice_provider']),
        speak: j['speak'] != false,
        keys: keys,
        models: map('models'),
        urls: map('urls'),
      );
    } on FormatException {
      return AiConfig(provider: AiProvider.anthropic);
    }
  }

  Future<void> save() {
    _remember();
    return Settings.set(
      'ai.config',
      jsonEncode({
        'provider': provider.id,
        'api_key': apiKey.trim(),
        'model': model.trim(),
        'base_url': baseUrl.trim(),
        'voice_model': voiceModel.trim(),
        'voice_provider': ?voiceProvider?.id,
        'speak': speak,
        'keys': keys,
        'models': models,
        'urls': urls,
      }),
    );
  }
}

/// Cliente de chat de la IA para el estudio: una petición, una respuesta.
/// Habla con APIs compatibles con OpenAI (/chat/completions y /responses) y
/// con la API de mensajes de Anthropic, según el proveedor configurado.
class Assistant {
  Assistant({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final AiConfig config;
  final http.Client _client;

  /// Modelos que solo atienden /responses (se recuerda).
  static final _responsesModels = <String>{};

  bool get _useResponses =>
      config.provider.protocol == AiProtocol.responses ||
      _responsesModels.contains(config.model);

  Map<String, String> get _headers => {
    ...config.provider.authHeaders(config.apiKey),
    'Content-Type': 'application/json',
  };

  String get _base => AiProvider.trimUrl(config.baseUrl);

  Future<http.Response> _post(Uri url, Map<String, Object?> body) async {
    try {
      return await _client.post(url, headers: _headers, body: jsonEncode(body));
    } catch (e) {
      throw UserError(tr('No se pudo conectar con {0}: {1}', [url.host, e]));
    }
  }

  static String _errorOf(String body) => aiErrorOf(body);

  /// Responde a [messages] (formato de OpenAI). Con [json], pide un único
  /// objeto JSON y quita el bloque de código con que algunos lo envuelven.
  Future<String> chat(
    List<Map<String, Object?>> messages, {
    bool json = false,
  }) async {
    if (!config.ready) throw UserError(config.missingKey);
    final provider = config.provider;
    // Sin modo JSON en la API, se pide en las indicaciones.
    final sent = json && !provider.jsonMode
        ? [
            {'role': 'system', 'content': aiJsonNote},
            ...messages,
          ]
        : messages;
    final out = provider.protocol == AiProtocol.anthropic
        ? await _chatAnthropic(sent)
        : await _chatOpenAi(sent, json && provider.jsonMode);
    return json ? _unfenced(out) : out;
  }

  static String _unfenced(String text) =>
      RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$').firstMatch(text)?[1] ?? text;

  /// Modelos de Claude con fallback del servidor ante un rechazo de sus
  /// filtros de seguridad (`fallbacks: "default"`).
  static bool _hasFallbacks(String model) => const {
    'claude-fable-5-1',
    'claude-opus-5-5',
    'claude-opus-5',
    'claude-sonnet-5-5',
  }.contains(model.trim());

  /// Cuentas o modelos que rechazaron los fallbacks: no se vuelven a pedir.
  static final _noFallbacks = <String>{};

  Future<String> _chatAnthropic(List<Map<String, Object?>> messages) async {
    final fallbacks =
        _hasFallbacks(config.model) && !_noFallbacks.contains(config.model);
    Future<http.Response> send(bool withFallbacks) async {
      final url = Uri.parse('$_base/messages');
      final body = {
        ...AnthropicApi.request(messages, model: config.model),
        if (withFallbacks) 'fallbacks': 'default',
      };
      try {
        return await _client.post(
          url,
          headers: {
            ..._headers,
            if (withFallbacks)
              'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode(body),
        );
      } catch (e) {
        throw UserError(tr('No se pudo conectar con {0}: {1}', [url.host, e]));
      }
    }

    var res = await send(fallbacks);
    var body = utf8.decode(res.bodyBytes);
    if (fallbacks &&
        res.statusCode == 400 &&
        _errorOf(body).contains('fallback')) {
      _noFallbacks.add(config.model);
      res = await send(false);
      body = utf8.decode(res.bodyBytes);
    }
    if (res.statusCode != 200) {
      throw UserError(
        tr('Error de la IA ({0}): {1}', [res.statusCode, _errorOf(body)]),
      );
    }
    return '${AnthropicApi.reply(jsonDecode(body) as Map)['content']}'.trim();
  }

  Future<String> _chatOpenAi(
    List<Map<String, Object?>> messages,
    bool json,
  ) async {
    bool rejectsJson(String msg) => RegExp(
      'response_format|json_object|text\\.format',
      caseSensitive: false,
    ).hasMatch(msg);
    if (!_useResponses) {
      Future<http.Response> post(bool asJson) =>
          _post(Uri.parse('$_base/chat/completions'), {
            'model': config.model,
            'messages': messages,
            if (asJson) 'response_format': {'type': 'json_object'},
          });
      var res = await post(json);
      var body = utf8.decode(res.bodyBytes);
      if (json && res.statusCode == 400 && rejectsJson(_errorOf(body))) {
        res = await post(false);
        body = utf8.decode(res.bodyBytes);
      }
      if (res.statusCode == 200) {
        return _text(_messageOf(body)['content']).trim();
      }
      final msg = _errorOf(body);
      if (res.statusCode != 400 ||
          !RegExp(
            '/v1/responses|responses api|reasoning_effort',
            caseSensitive: false,
          ).hasMatch(msg)) {
        throw UserError(tr('Error de la IA ({0}): {1}', [res.statusCode, msg]));
      }
      _responsesModels.add(config.model);
    }
    // Modelos que solo atienden /responses.
    Future<http.Response> post(bool asJson) =>
        _post(Uri.parse('$_base/responses'), {
          'model': config.model,
          'input': _input(messages),
          'store': false,
          if (asJson)
            'text': {
              'format': {'type': 'json_object'},
            },
        });
    var res = await post(json);
    var body = utf8.decode(res.bodyBytes);
    if (json && res.statusCode == 400 && rejectsJson(_errorOf(body))) {
      res = await post(false);
      body = utf8.decode(res.bodyBytes);
    }
    if (res.statusCode != 200) {
      throw UserError(
        tr('Error de la IA ({0}): {1}', [res.statusCode, _errorOf(body)]),
      );
    }
    return _responsesText(body).trim();
  }

  /// El mensaje de una respuesta de /chat/completions.
  static Map<String, Object?> _messageOf(String body) {
    final choices = (jsonDecode(body) as Map)['choices'];
    if (choices is! List || choices.isEmpty) {
      throw UserError(tr('Error de la IA ({0}): {1}', [200, _errorOf(body)]));
    }
    return ((choices.first as Map)['message'] as Map).cast<String, Object?>();
  }

  /// Texto de un `content`, que algunos proveedores dan por partes.
  static String _text(Object? content) => content is List
      ? content.whereType<Map>().map((p) => '${p['text'] ?? ''}').join()
      : '${content ?? ''}';

  /// Texto de una respuesta de /responses.
  static String _responsesText(String body) {
    final j = jsonDecode(body) as Map;
    if (j['status'] == 'failed') {
      throw UserError(tr('Error de la IA ({0}): {1}', [200, _errorOf(body)]));
    }
    final b = StringBuffer();
    for (final item in (j['output'] as List?) ?? const []) {
      if (item is! Map || item['type'] != 'message') continue;
      for (final c in (item['content'] as List?) ?? const []) {
        if (c is Map && c['type'] == 'output_text') b.write(c['text'] ?? '');
      }
    }
    return b.toString();
  }

  /// La conversación para /responses de este proveedor.
  List<Map<String, Object?>> _input(List<Map<String, Object?>> history) {
    final items = responsesInput(history);
    // La Agent API de Perplexity tipa también los mensajes.
    return identical(config.provider, AiProvider.perplexity)
        ? [
            for (final i in items)
              i.containsKey('role') ? {'type': 'message', ...i} : i,
          ]
        : items;
  }

  /// La conversación en el formato de /responses.
  static List<Map<String, Object?>> responsesInput(
    List<Map<String, Object?>> history,
  ) {
    Object? content(Object? c) => c is List
        ? [
            for (final p in c)
              if (p is Map && p['type'] == 'text')
                {'type': 'input_text', 'text': p['text']}
              else if (p is Map && p['type'] == 'image_url')
                {
                  'type': 'input_image',
                  'image_url': (p['image_url'] as Map?)?['url'],
                },
          ]
        : '${c ?? ''}';
    return [
      for (final m in history)
        ...switch (m['role']) {
          'system' || 'user' => [
            {'role': m['role'], 'content': content(m['content'])},
          ],
          'assistant' => [
            if ('${m['content'] ?? ''}'.isNotEmpty)
              {'role': 'assistant', 'content': '${m['content']}'},
            for (final c in (m['tool_calls'] as List?) ?? const [])
              if (c is Map)
                {
                  'type': 'function_call',
                  'call_id': c['id'],
                  'name': (c['function'] as Map)['name'],
                  'arguments': '${(c['function'] as Map)['arguments'] ?? '{}'}',
                  'thought_signature': ?c['thought_signature'],
                },
          ],
          'tool' => [
            {
              'type': 'function_call_output',
              'call_id': m['tool_call_id'],
              'output': '${m['content'] ?? ''}',
            },
          ],
          _ => const <Map<String, Object?>>[],
        },
    ];
  }
}
