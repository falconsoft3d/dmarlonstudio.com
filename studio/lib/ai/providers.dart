import 'dart:convert';

import '../i18n/tr.dart';

/// Formato de la API de un proveedor.
enum AiProtocol {
  /// /chat/completions de OpenAI (la mayoría de proveedores).
  chat,

  /// /responses de OpenAI, sin /chat/completions.
  responses,

  /// /messages de Anthropic.
  anthropic,
}

/// Proveedor de IA: dónde está su API y qué admite. Las URL, las cabeceras y
/// los modelos salen de la documentación de cada uno (octubre de 2026). Los
/// modelos de la cuenta se consultan a la API; los de aquí son la lista corta
/// de reserva.
class AiProvider {
  const AiProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.defaultModel,
    this.models = const [],
    this.protocol = AiProtocol.chat,
    this.needsKey = true,
    this.keyHint = '',
    this.editableUrl = false,
    this.modelsUrl,
    this.voice = false,
    this.voiceModels = const [],
    this.voiceNeedsLanguage = false,
    this.jsonMode = true,
    this.replayKeys = const [],
  });

  final String id, label, baseUrl, defaultModel, keyHint;

  /// Modelos de chat conocidos (si no se puede consultar la API).
  final List<String> models;
  final AiProtocol protocol;

  /// Sin clave no funciona (Ollama no la pide).
  final bool needsKey;

  /// La dirección la pone el usuario (servidores propios).
  final bool editableUrl;

  /// Dónde se listan los modelos, si no es `<baseUrl>/models`.
  final String? modelsUrl;

  /// Transcribe la voz con /audio/transcriptions al estilo de Whisper.
  final bool voice;
  final List<String> voiceModels;

  /// Su /audio/transcriptions exige el idioma.
  final bool voiceNeedsLanguage;

  /// Tiene modo JSON sin esquema (response_format o text.format).
  final bool jsonMode;

  /// Campos del mensaje del asistente que la API pide de vuelta.
  final List<String> replayKeys;

  static const _openAiModels = [
    'gpt-5',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4.1-mini',
    'gpt-4.1-nano',
    'gpt-4o',
    'gpt-4o-mini',
    'o4-mini',
    'o3',
    'o3-mini',
  ];
  static const _openAiVoiceModels = [
    'whisper-1',
    'gpt-4o-transcribe',
    'gpt-4o-mini-transcribe',
  ];

  static const openai = AiProvider(
    id: 'openai',
    label: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4.1-mini',
    keyHint: 'sk-…',
    models: _openAiModels,
    voice: true,
    voiceModels: _openAiVoiceModels,
  );

  /// API propia (/v1/messages): la única sin formato de OpenAI.
  static const anthropic = AiProvider(
    id: 'anthropic',
    label: 'Anthropic (Claude)',
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-opus-5-5',
    keyHint: 'sk-ant-…',
    protocol: AiProtocol.anthropic,
    modelsUrl: 'https://api.anthropic.com/v1/models?limit=1000',
    models: [
      'claude-fable-5-1',
      'claude-opus-5-5',
      'claude-sonnet-5-5',
      'claude-haiku-5-5',
    ],
    jsonMode: false,
  );

  /// Por su API compatible con OpenAI: admite herramientas, imágenes y
  /// JSON. Los `tool_calls` guardan `extra_content` con la firma del
  /// razonamiento que Gemini 3 exige de vuelta.
  static const gemini = AiProvider(
    id: 'gemini',
    label: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    defaultModel: 'gemini-3.8-flash',
    keyHint: 'AIza…',
    models: ['gemini-3.8-flash', 'gemini-4-argon', 'gemini-3.5-flash-lite'],
  );

  /// /chat/completions es «legado» pero sigue documentado, con herramientas
  /// y JSON. Su voz va por /v1/stt, que no sigue el formato de Whisper.
  static const xai = AiProvider(
    id: 'xai',
    label: 'xAI (Grok)',
    baseUrl: 'https://api.x.ai/v1',
    defaultModel: 'grok-4.7',
    keyHint: 'xai-…',
    models: ['grok-4.7', 'grok-4.6', 'grok-4.5'],
  );

  /// Sin /v1 en la URL documentada. Con herramientas exige que se le
  /// devuelva `reasoning_content`.
  static const deepseek = AiProvider(
    id: 'deepseek',
    label: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com',
    defaultModel: 'deepseek-flash',
    keyHint: 'sk-…',
    models: ['deepseek-flash', 'deepseek-v4-pro'],
    replayKeys: ['reasoning_content'],
  );

  static const mistral = AiProvider(
    id: 'mistral',
    label: 'Mistral',
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModel: 'mistral-large-latest',
    models: ['mistral-large-latest', 'mistral-small-latest'],
    voice: true,
    voiceModels: ['voxtral-mini-latest'],
  );

  static const groq = AiProvider(
    id: 'groq',
    label: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
    keyHint: 'gsk_…',
    models: [
      'llama-3.3-70b-versatile',
      'openai/gpt-oss-120b',
      'llama-3.1-8b-instant',
    ],
    voice: true,
    voiceModels: ['whisper-large-v3-turbo', 'whisper-large-v3'],
  );

  /// Por su API de compatibilidad; los modelos se listan en la nativa.
  static const cohere = AiProvider(
    id: 'cohere',
    label: 'Cohere',
    baseUrl: 'https://api.cohere.ai/compatibility/v1',
    defaultModel: 'command-a-plus-05-2026',
    modelsUrl: 'https://api.cohere.com/v1/models?endpoint=chat&page_size=1000',
    models: ['command-a-plus-05-2026', 'command-a-03-2025'],
    voice: true,
    voiceModels: ['cohere-transcribe-03-2026'],
    voiceNeedsLanguage: true,
  );

  static const openrouter = AiProvider(
    id: 'openrouter',
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'openrouter/auto',
    keyHint: 'sk-or-…',
    models: ['openrouter/auto'],
    voice: true,
    voiceModels: ['openai/whisper-large-v3'],
    replayKeys: ['reasoning_details'],
  );

  /// Sonar Chat Completions terminó el 27/09/2026: se usa la Agent API, con
  /// /responses como alias de /agent. Solo admite JSON con esquema.
  static const perplexity = AiProvider(
    id: 'perplexity',
    label: 'Perplexity',
    baseUrl: 'https://api.perplexity.ai/v1',
    defaultModel: 'openai/gpt-5.6-sol',
    keyHint: 'pplx-…',
    protocol: AiProtocol.responses,
    models: [
      'openai/gpt-5.6-sol',
      'anthropic/claude-sonnet-5-5',
      'perplexity/sonar',
    ],
    jsonMode: false,
  );

  /// En este equipo o en otro de la red: no pide clave.
  static const ollama = AiProvider(
    id: 'ollama',
    label: 'Ollama (local)',
    baseUrl: 'http://localhost:11434/v1',
    defaultModel: 'gpt-oss:20b',
    needsKey: false,
    editableUrl: true,
    voice: true,
  );

  /// Cualquier API compatible con OpenAI en la URL que se indique.
  static const custom = AiProvider(
    id: 'custom',
    label: 'Personalizada',
    baseUrl: '',
    defaultModel: 'gpt-4.1-mini',
    models: _openAiModels,
    editableUrl: true,
    voice: true,
    voiceModels: _openAiVoiceModels,
    replayKeys: ['reasoning_content'],
  );

  static const all = [
    openai,
    anthropic,
    gemini,
    xai,
    deepseek,
    mistral,
    groq,
    cohere,
    openrouter,
    perplexity,
    ollama,
    custom,
  ];

  /// Nombre para la pantalla.
  String get name => identical(this, custom) ? tr('Personalizada') : label;

  /// Cómo se nombra al proveedor en una frase.
  String get vendor =>
      identical(this, custom) ? tr('la API personalizada') : label;

  static AiProvider? byId(Object? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Proveedor de una configuración sin ese dato (antes de elegir proveedor
  /// solo existía la URL): OpenAI con la URL de siempre, si no, personalizada.
  static AiProvider infer(String? url) {
    if (url == null || url.trim().isEmpty) return openai;
    return trimUrl(url) == openai.baseUrl ? openai : custom;
  }

  static String trimUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Cabeceras de autenticación.
  Map<String, String> authHeaders(String apiKey) {
    final key = apiKey.trim();
    if (protocol == AiProtocol.anthropic) {
      return {'x-api-key': key, 'anthropic-version': anthropicVersion};
    }
    return key.isEmpty ? const {} : {'Authorization': 'Bearer $key'};
  }

  /// Versión de la API de Anthropic que espera el adaptador.
  static const anthropicVersion = '2026-10-21';

  static bool isVoiceModel(String id) {
    final m = id.toLowerCase();
    return m.contains('whisper') ||
        m.contains('transcribe') ||
        m.contains('voxtral');
  }

  /// Si [model] puede leer imágenes. Ninguna API lo dice: se descartan solo
  /// los que se sabe que no; a los demás se les envía y, si la rechazan, se
  /// avisa con su respuesta.
  bool readsImages(String model) {
    final m = model.toLowerCase();
    if (RegExp('vision|scout|maverick').hasMatch(m)) return true;
    if (identical(this, deepseek) ||
        identical(this, groq) ||
        identical(this, cohere)) {
      return false;
    }
    return !RegExp(r'gpt-oss|gpt-3\.5|o3-mini').hasMatch(m);
  }

  /// Si un modelo de la lista de la API sirve para conversar.
  bool isChatModel(String id) {
    final m = id.toLowerCase();
    if (identical(this, openai)) {
      if (!RegExp(r'^(gpt-|chatgpt-|o\d)').hasMatch(m)) return false;
      const skip = [
        'search',
        'instruct',
        'computer-use',
        'codex',
        'deep-research',
      ];
      if (skip.any(m.contains)) return false;
    }
    if (identical(this, anthropic) && !m.startsWith('claude')) return false;
    const skip = [
      'embed',
      'rerank',
      'moderation',
      'guard',
      'tts',
      'stt',
      'speech',
      'voice',
      'transcribe',
      'whisper',
      'voxtral',
      'orpheus',
      'realtime',
      'audio',
      'dall-e',
      'image',
      'imagine',
      'veo-',
      'video',
      'lyria',
      'ocr',
      'aqa',
    ];
    return !skip.any(m.contains);
  }

  /// Modelos de la respuesta de /models: `data[].id` en casi todos,
  /// `models[].name` en Cohere y `models/…` en Gemini.
  static List<String> modelIds(Object? json) {
    if (json is! Map) return [];
    final data = json['data'], models = json['models'];
    return [
      for (final m in (data is List ? data : const []))
        if (m is Map && m['id'] != null)
          '${m['id']}'.replaceFirst('models/', ''),
      for (final m in (models is List ? models : const []))
        if (m is Map && m['name'] != null) '${m['name']}',
    ];
  }
}

/// Indicación para pedir JSON a una API sin modo JSON sin esquema. Con los
/// modelos actuales de Claude tampoco se puede empezar la respuesta por «{».
const aiJsonNote =
    'Reply with one valid JSON object and nothing else: no Markdown, no code fences, no text around it.';

/// Mensaje de error de la respuesta de una API, sea cual sea su forma:
/// `{error: {message}}`, `[{error: …}]` (Gemini), `{error: "…"}`,
/// `{message: "…"}` (Cohere) o `{detail: "…"}`.
String aiErrorOf(String body) {
  try {
    var j = jsonDecode(body);
    if (j is List && j.isNotEmpty) j = j.first;
    if (j is Map) {
      final e = j['error'];
      if (e is Map && e['message'] != null) return '${e['message']}';
      if (e is String) return e;
      for (final k in ['message', 'detail']) {
        if (j[k] is String) return '${j[k]}';
      }
    }
  } catch (_) {
    // No es JSON: se devuelve tal cual.
  }
  return body;
}
