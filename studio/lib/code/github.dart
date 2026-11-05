import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/settings.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';

/// Repositorio de GitHub (de la lista del usuario o recién creado).
typedef GitHubRepo = ({
  String fullName,
  String name,
  String description,
  bool private,
  String cloneUrl,
  String htmlUrl,
  DateTime? updated,
});

/// Token de GitHub del usuario: git lo usa para traer, subir y clonar
/// repositorios de github.com sin pedir la contraseña.
class GitHubAuth {
  GitHubAuth._();

  /// Token cargado (null = sin token: git usa las credenciales del sistema).
  static String? token;

  static String get _key => 'code.github';

  static Future<String?> load() async {
    final t = (await Settings.get(_key))?.trim();
    return token = (t == null || t.isEmpty) ? null : t;
  }

  static Future<void> save(String? value) async {
    final t = value?.trim() ?? '';
    await Settings.set(_key, t);
    token = t.isEmpty ? null : t;
  }

  /// Opciones de git para autenticarse en github.com con el token (solo
  /// para esa orden: no queda en la configuración del repositorio).
  static List<String> args([String? value]) {
    final t = value ?? token;
    if (t == null || t.isEmpty) return const [];
    final basic = base64.encode(utf8.encode('x-access-token:$t'));
    return [
      '-c',
      'http.https://github.com/.extraheader=AUTHORIZATION: basic $basic',
    ];
  }

  /// Página web de un remoto de GitHub (https o ssh); null si no es GitHub.
  static String? webUrl(String remote) {
    final m = RegExp(
      r'github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$',
    ).firstMatch(remote.trim());
    return m == null ? null : 'https://github.com/${m[1]}/${m[2]}';
  }
}

/// API de GitHub: el usuario, sus repositorios y crear uno nuevo.
class GitHub {
  GitHub._();

  /// Para las pruebas (un cliente falso).
  static http.Client Function()? clientFactory;

  static const _api = 'https://api.github.com';

  /// Página para crear un token con permiso sobre los repositorios.
  static const newTokenUrl =
      'https://github.com/settings/tokens/new?scopes=repo&description=DMarlonStudio';

  static Future<Object?> _call(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final t = token ?? GitHubAuth.token;
    if (t == null || t.isEmpty) {
      throw UserError(tr('Configure primero su token de GitHub.'));
    }
    final client = clientFactory?.call() ?? http.Client();
    try {
      final req = http.Request(method, Uri.parse('$_api$path'))
        ..headers.addAll({
          'Authorization': 'Bearer $t',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(
        await client.send(req).timeout(const Duration(seconds: 30)),
      );
      final data = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode == 401) {
        throw UserError(
          tr('GitHub no aceptó el token (revíselo o cree otro).'),
        );
      }
      if (res.statusCode >= 300) {
        final msg = data is Map ? '${data['message'] ?? ''}' : '';
        final errors = data is Map && data['errors'] is List
            ? (data['errors'] as List)
                  .map((e) => e is Map ? '${e['message'] ?? ''}' : '$e')
                  .where((e) => e.isNotEmpty)
                  .join('; ')
            : '';
        throw UserError(
          tr('GitHub respondió {0}: {1}', [
            res.statusCode,
            [msg, errors].where((x) => x.isNotEmpty).join(' — '),
          ]),
        );
      }
      return data;
    } on UserError {
      rethrow;
    } catch (e) {
      throw UserError(tr('No se pudo conectar con GitHub: {0}', [e]));
    } finally {
      client.close();
    }
  }

  /// Usuario del token (su «login»).
  static Future<String> user({String? token}) async {
    final u = await _call('GET', '/user', token: token);
    return u is Map ? '${u['login'] ?? ''}' : '';
  }

  static GitHubRepo _repo(Map r) => (
    fullName: '${r['full_name'] ?? ''}',
    name: '${r['name'] ?? ''}',
    description: '${r['description'] ?? ''}',
    private: r['private'] == true,
    cloneUrl: '${r['clone_url'] ?? ''}',
    htmlUrl: '${r['html_url'] ?? ''}',
    updated: DateTime.tryParse('${r['pushed_at'] ?? r['updated_at'] ?? ''}'),
  );

  /// Repositorios del usuario (propios, de colaborador y de sus
  /// organizaciones), los últimos usados primero.
  static Future<List<GitHubRepo>> repos({int pages = 5}) async {
    final out = <GitHubRepo>[];
    for (var page = 1; page <= pages; page++) {
      final list = await _call(
        'GET',
        '/user/repos?per_page=100&sort=pushed&page=$page',
      );
      if (list is! List || list.isEmpty) break;
      out.addAll(list.whereType<Map>().map(_repo));
      if (list.length < 100) break;
    }
    return out;
  }

  /// Crea el repositorio [name] en la cuenta del usuario.
  static Future<GitHubRepo> create(
    String name, {
    String description = '',
    bool private = true,
  }) async {
    final n = name.trim();
    if (n.isEmpty) throw UserError(tr('Escriba el nombre del repositorio.'));
    final r = await _call(
      'POST',
      '/user/repos',
      body: {'name': n, 'description': description.trim(), 'private': private},
    );
    if (r is! Map) throw UserError(tr('GitHub no devolvió el repositorio.'));
    return _repo(r);
  }
}
