import 'dart:convert';

import 'tk_codegen.dart';

/// Método copiado con sus componentes: la línea `def …` y su cuerpo sin
/// sangría.
typedef CopiedMethod = ({String def, String body});

/// Componentes copiados en el Diseñador, con el código de sus eventos.
///
/// Van al portapapeles del sistema como JSON, así que se pegan en otro
/// proyecto, en otra ventana del estudio o después de reiniciarlo.
class ComponentClip {
  ComponentClip(this.widgets, this.methods);

  /// Componentes (el JSON de cada uno, marcos con su contenido).
  final List<Map<String, Object?>> widgets;

  /// Métodos de sus eventos, por nombre.
  final Map<String, CopiedMethod> methods;

  static const _tag = 'dmarlonstudio/components';

  String encode() => jsonEncode({
    'type': _tag,
    'version': 1,
    'widgets': widgets,
    'methods': {
      for (final e in methods.entries)
        e.key: {'def': e.value.def, 'body': e.value.body},
    },
  });

  /// Lo copiado, o null si [text] no son componentes del estudio.
  static ComponentClip? decode(String? text) {
    if (text == null || !text.trimLeft().startsWith('{')) return null;
    try {
      final j = jsonDecode(text);
      if (j is! Map || j['type'] != _tag || j['widgets'] is! List) return null;
      return ComponentClip(
        [
          for (final w in (j['widgets'] as List).whereType<Map>())
            w.cast<String, Object?>(),
        ],
        {
          for (final e in ((j['methods'] as Map?) ?? const {}).entries)
            if (e.value is Map)
              '${e.key}': (
                def: '${(e.value as Map)['def'] ?? ''}',
                body: '${(e.value as Map)['body'] ?? 'pass'}',
              ),
        },
      );
    } on FormatException {
      return null;
    }
  }

  /// La definición y el cuerpo de [method] en [code] (null si no está).
  static CopiedMethod? methodOf(String code, String method) {
    final at = TkUnit.lineOf(code, method);
    if (at == null) return null;
    final lines = code.split('\n');
    final indent = RegExp(r'^[ \t]*').stringMatch(lines[at])!.length;
    // La definición puede ocupar varias líneas.
    var first = at;
    while (first < lines.length - 1 &&
        !lines[first].trimRight().endsWith(':')) {
      first++;
    }
    var end = lines.length;
    for (var i = first + 1; i < lines.length; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      if (RegExp(r'^[ \t]*').stringMatch(l)!.length <= indent) {
        end = i;
        break;
      }
    }
    while (end > first + 1 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    final body = lines.sublist(first + 1, end);
    final inner = body
        .where((l) => l.trim().isNotEmpty)
        .map((l) => RegExp(r'^[ \t]*').stringMatch(l)!.length)
        .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
    return (
      def: [
        for (var i = at; i <= first; i++) lines[i].substring(indent),
      ].join('\n'),
      body: inner == null
          ? 'pass'
          : [
              for (final l in body) l.trim().isEmpty ? '' : l.substring(inner),
            ].join('\n'),
    );
  }

  /// Añade [m] como método [name] de la clase [form] (con su firma
  /// original, renombrada).
  static String addMethod(
    String code,
    String form,
    String from,
    String name,
    CopiedMethod m,
  ) {
    var out = TkUnit.ensureMethod(code, form, name);
    final at = TkUnit.lineOf(out, name)!;
    final lines = out.split('\n');
    final indent = RegExp(r'^[ \t]*').stringMatch(lines[at])!;
    final def = m.def.replaceFirst(
      RegExp('\\bdef\\s+${RegExp.escape(from)}\\b'),
      'def $name',
    );
    final defLines = def.split('\n');
    if (defLines.length == 1) {
      lines[at] = '$indent${defLines.single.trim()}';
      out = lines.join('\n');
    }
    // Una firma de varias líneas se queda con la del estudio; el cuerpo sí
    // es el copiado.
    return TkUnit.setMethodBody(out, form, name, m.body);
  }
}
