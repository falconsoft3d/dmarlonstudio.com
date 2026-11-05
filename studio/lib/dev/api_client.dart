import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/errors.dart';
import '../i18n/tr.dart';

/// Fila clave/valor activable (parámetros, cabeceras, formulario).
class KeyValue {
  KeyValue(this.key, this.value, {this.enabled = true});
  String key, value;
  bool enabled;

  Map<String, Object?> toJson() => {
    'k': key,
    'v': value,
    if (!enabled) 'off': true,
  };
  factory KeyValue.fromJson(Map j) =>
      KeyValue('${j['k'] ?? ''}', '${j['v'] ?? ''}', enabled: j['off'] != true);
}

/// Petición HTTP (como en Postman).
class ApiRequest {
  ApiRequest({
    this.method = 'GET',
    this.url = '',
    List<KeyValue>? params,
    List<KeyValue>? headers,
    this.bodyType = 'none',
    this.body = '',
    this.authType = 'none',
    this.token = '',
    this.user = '',
    this.password = '',
  }) : params = params ?? [],
       headers = headers ?? [];

  static const methods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

  String method, url, bodyType, body, authType, token, user, password;
  List<KeyValue> params, headers;

  Map<String, Object?> toJson() => {
    'method': method,
    'url': url,
    'params': [for (final p in params) p.toJson()],
    'headers': [for (final h in headers) h.toJson()],
    'body_type': bodyType,
    'body': body,
    'auth': {
      'type': authType,
      'token': token,
      'user': user,
      'password': password,
    },
  };

  factory ApiRequest.fromJson(Map j) {
    final auth = j['auth'] is Map ? j['auth'] as Map : const {};
    List<KeyValue> kv(Object? l) => [
      for (final e in (l is List ? l : const [])) KeyValue.fromJson(e as Map),
    ];
    return ApiRequest(
      method: '${j['method'] ?? 'GET'}',
      url: '${j['url'] ?? ''}',
      params: kv(j['params']),
      headers: kv(j['headers']),
      bodyType: '${j['body_type'] ?? 'none'}',
      body: '${j['body'] ?? ''}',
      authType: '${auth['type'] ?? 'none'}',
      token: '${auth['token'] ?? ''}',
      user: '${auth['user'] ?? ''}',
      password: '${auth['password'] ?? ''}',
    );
  }

  ApiRequest copy() =>
      ApiRequest.fromJson(jsonDecode(jsonEncode(toJson())) as Map);
}

/// Respuesta de una petición.
class ApiReply {
  ApiReply({
    required this.status,
    required this.reason,
    required this.headers,
    required this.bytes,
    required this.elapsed,
  });
  final int status;
  final String reason;
  final Map<String, String> headers;
  final Uint8List bytes;
  final Duration elapsed;

  String get text => utf8.decode(bytes, allowMalformed: true);

  /// El cuerpo con sangría si es JSON.
  String get pretty {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } on FormatException {
      return text;
    }
  }

  bool get isJson {
    try {
      jsonDecode(text);
      return true;
    } on FormatException {
      return false;
    }
  }
}

/// Envía peticiones con las variables de entorno {{nombre}} sustituidas.
class ApiClient {
  ApiClient._();

  /// Cliente HTTP (las pruebas ponen uno simulado).
  static http.Client Function()? clientFactory;

  static String fill(String s, Map<String, String> env) => s.replaceAllMapped(
    RegExp(r'\{\{\s*([\w.-]+)\s*\}\}'),
    (m) => env[m[1]] ?? m[0]!,
  );

  /// URL final con los parámetros activos.
  static Uri uri(ApiRequest r, Map<String, String> env) {
    final raw = fill(r.url.trim(), env);
    if (raw.isEmpty) throw UserError(tr('Indique la dirección.'));
    final base = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (base == null || base.host.isEmpty) {
      throw UserError(tr('Dirección no válida: {0}', [raw]));
    }
    final extra = {
      for (final p in r.params)
        if (p.enabled && p.key.trim().isNotEmpty)
          fill(p.key.trim(), env): fill(p.value, env),
    };
    return extra.isEmpty
        ? base
        : base.replace(queryParameters: {...base.queryParameters, ...extra});
  }

  static Map<String, String> headersOf(ApiRequest r, Map<String, String> env) {
    final h = <String, String>{
      for (final x in r.headers)
        if (x.enabled && x.key.trim().isNotEmpty)
          fill(x.key.trim(), env): fill(x.value, env),
    };
    bool has(String k) => h.keys.any((x) => x.toLowerCase() == k);
    switch (r.authType) {
      case 'bearer':
        h['Authorization'] = 'Bearer ${fill(r.token, env)}';
      case 'basic':
        h['Authorization'] =
            'Basic ${base64Encode(utf8.encode('${fill(r.user, env)}:${fill(r.password, env)}'))}';
    }
    if (!has('content-type')) {
      switch (r.bodyType) {
        case 'json':
          h['Content-Type'] = 'application/json';
        case 'form':
          h['Content-Type'] = 'application/x-www-form-urlencoded';
        case 'text':
          h['Content-Type'] = 'text/plain; charset=utf-8';
      }
    }
    return h;
  }

  static String? bodyOf(ApiRequest r, Map<String, String> env) {
    if (r.bodyType == 'none' || r.method == 'GET' || r.method == 'HEAD') {
      return null;
    }
    final b = fill(r.body, env);
    if (r.bodyType == 'form') {
      // Una línea «clave=valor» por campo.
      return [
        for (final line in b.split('\n'))
          if (line.contains('='))
            '${Uri.encodeQueryComponent(line.substring(0, line.indexOf('=')).trim())}='
                '${Uri.encodeQueryComponent(line.substring(line.indexOf('=') + 1).trim())}',
      ].join('&');
    }
    return b;
  }

  static Future<ApiReply> send(ApiRequest r, Map<String, String> env) async {
    final req = http.Request(r.method, uri(r, env))
      ..headers.addAll(headersOf(r, env));
    final body = bodyOf(r, env);
    if (body != null) req.body = body;
    final client = clientFactory?.call() ?? http.Client();
    final watch = Stopwatch()..start();
    try {
      final res = await client.send(req).timeout(const Duration(seconds: 60));
      final bytes = await res.stream.toBytes();
      watch.stop();
      return ApiReply(
        status: res.statusCode,
        reason: res.reasonPhrase ?? '',
        headers: res.headers,
        bytes: bytes,
        elapsed: watch.elapsed,
      );
    } on UserError {
      rethrow;
    } catch (e) {
      throw UserError(tr('No se pudo conectar: {0}', [e]));
    } finally {
      client.close();
    }
  }

  /// La petición como orden curl (para compartirla).
  static String curl(ApiRequest r, Map<String, String> env) {
    String q(String s) => "'${s.replaceAll("'", "'\\''")}'";
    final parts = ['curl', '-X', r.method, q('${uri(r, env)}')];
    for (final e in headersOf(r, env).entries) {
      parts.addAll(['-H', q('${e.key}: ${e.value}')]);
    }
    final body = bodyOf(r, env);
    if (body != null && body.isNotEmpty) parts.addAll(['--data', q(body)]);
    return parts.join(' ');
  }
}
