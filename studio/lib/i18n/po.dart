/// Lectura y escritura de catálogos gettext (.po), el formato que usa Odoo y
/// que editan herramientas como Poedit.
library;

import 'tr.dart' show contextKey;

/// Entrada de un catálogo.
class PoEntry {
  PoEntry(
    this.msgid,
    this.msgstr, {
    this.context,
    this.fuzzy = false,
    this.refs = const [],
  });
  final String msgid;

  /// msgctxt: distingue textos iguales con distinto significado.
  final String? context;

  /// Clave en el catálogo (con el contexto, si lo hay).
  String get key => context == null ? msgid : contextKey(context!, msgid);
  String msgstr;
  bool fuzzy;
  List<String> refs;
}

String _unescape(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c != r'\' || i + 1 >= s.length) {
      b.write(c);
      continue;
    }
    final n = s[++i];
    b.write(switch (n) {
      'n' => '\n',
      't' => '\t',
      'r' => '\r',
      _ => n, // \" y \\
    });
  }
  return b.toString();
}

String _escape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('"', r'\"')
    .replaceAll('\t', r'\t')
    .replaceAll('\r', r'\r');

/// Entradas de un .po (sin la cabecera de msgid vacío).
List<PoEntry> parsePo(String source) {
  final entries = <PoEntry>[];
  String? field;
  final id = StringBuffer(), str = StringBuffer(), ctxt = StringBuffer();
  var hasCtxt = false;
  var fuzzy = false;
  var refs = <String>[];
  var hasEntry = false;

  void flush() {
    if (hasEntry && id.isNotEmpty) {
      entries.add(
        PoEntry(
          id.toString(),
          str.toString(),
          context: hasCtxt ? ctxt.toString() : null,
          fuzzy: fuzzy,
          refs: refs,
        ),
      );
    }
    id.clear();
    str.clear();
    ctxt.clear();
    hasCtxt = false;
    fuzzy = false;
    refs = [];
    field = null;
    hasEntry = false;
  }

  String quoted(String l) {
    final a = l.indexOf('"'), z = l.lastIndexOf('"');
    return a < 0 || z <= a ? '' : _unescape(l.substring(a + 1, z));
  }

  for (final raw in source.split('\n')) {
    final l = raw.trim();
    if (l.isEmpty) {
      continue;
    } else if (l.startsWith('#,')) {
      if (hasEntry) flush();
      fuzzy = l.contains('fuzzy');
    } else if (l.startsWith('#:')) {
      if (hasEntry) flush();
      refs = [...refs, ...l.substring(2).trim().split(RegExp(r'\s+'))];
    } else if (l.startsWith('#')) {
      if (hasEntry) flush();
    } else if (l.startsWith('msgctxt')) {
      if (hasEntry) flush();
      field = 'ctxt';
      hasCtxt = true;
      ctxt.write(quoted(l));
    } else if (l.startsWith('msgid_plural')) {
      field = 'plural';
    } else if (l.startsWith('msgid')) {
      if (hasEntry) flush();
      hasEntry = true;
      field = 'id';
      id.write(quoted(l));
    } else if (l.startsWith('msgstr')) {
      field = 'str';
      // msgstr[0] de los plurales: se toma la primera forma.
      if (!l.startsWith('msgstr[') || l.startsWith('msgstr[0]')) {
        str.write(quoted(l));
      } else {
        field = 'skip';
      }
    } else if (l.startsWith('"')) {
      if (field == 'ctxt') ctxt.write(quoted(l));
      if (field == 'id') id.write(quoted(l));
      if (field == 'str') str.write(quoted(l));
    }
  }
  flush();
  return entries;
}

/// Catálogo para [setCatalog]: sin entradas vacías ni dudosas (fuzzy), como
/// gettext.
Map<String, String> catalogOf(String source) => {
  for (final e in parsePo(source))
    if (e.msgstr.isNotEmpty && !e.fuzzy) e.key: e.msgstr,
};

String _block(String key, String v) {
  if (!v.contains('\n')) return '$key "${_escape(v)}"\n';
  final lines = v.split('\n');
  final b = StringBuffer('$key ""\n');
  for (var i = 0; i < lines.length; i++) {
    final last = i == lines.length - 1;
    if (last && lines[i].isEmpty) break;
    b.write('"${_escape(lines[i])}${last ? '' : r'\n'}"\n');
  }
  return b.toString();
}

/// Escribe un .po con su cabecera.
String writePo(List<PoEntry> entries, {required String language}) {
  final b = StringBuffer()
    ..write('# Traducción de DMarlon Studio.\n')
    ..write('# Edite este archivo con Poedit o cualquier editor de texto y\n')
    ..write(
      '# ejecute «python3 tool/extract_i18n.py» tras cambiar textos del código.\n',
    )
    ..write('msgid ""\n')
    ..write('msgstr ""\n')
    ..write('"Project-Id-Version: DMarlon Studio\\n"\n')
    ..write('"Language: $language\\n"\n')
    ..write('"MIME-Version: 1.0\\n"\n')
    ..write('"Content-Type: text/plain; charset=UTF-8\\n"\n')
    ..write('"Content-Transfer-Encoding: 8bit\\n"\n');
  for (final e in entries) {
    b.write('\n');
    if (e.refs.isNotEmpty) b.write('#: ${e.refs.join(' ')}\n');
    if (e.fuzzy) b.write('#, fuzzy\n');
    if (e.context != null) b.write(_block('msgctxt', e.context!));
    b.write(_block('msgid', e.msgid));
    b.write(_block('msgstr', e.msgstr));
  }
  return b.toString();
}
