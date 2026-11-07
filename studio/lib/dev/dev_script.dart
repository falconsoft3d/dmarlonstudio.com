import '../core/errors.dart';
import '../i18n/tr.dart';
import 'dev_types.dart';

/// Scripts del módulo Bases de datos: varias consultas en el editor, que se
/// ejecutan una tras otra.
///
/// - SQL (sqlite, postgres, mysql): separadas por «;», sin contar los «;» de
///   las cadenas, los comentarios, los bloques `$$ … $$` de PostgreSQL ni el
///   cuerpo `BEGIN … END` de un `CREATE TRIGGER`. En MySQL, `DELIMITER //`
///   cambia el separador (como en MySQL Workbench) para los procedimientos.
/// - JSON (mongodb, falcon, firebase): un objeto tras otro; se admiten
///   comentarios `//` de una línea.
bool isJsonKind(String kind) =>
    const {'mongodb', 'falcon', 'firebase'}.contains(kind);

/// Las consultas de [text], sin los comentarios del principio.
List<String> splitScript(String kind, String text) =>
    isJsonKind(kind) ? _splitJson(text) : _splitSql(kind, text);

/// Si [query] cambia datos (para pedir confirmación).
bool isWriteQuery(String kind, String query) => isJsonKind(kind)
    ? RegExp(
        r'"(insert|update|delete|drop|createIndex)"',
      ).hasMatch(_stripJsonComments(query))
    : !RegExp(
            r'^(select|with|pragma|explain|values|show|describe|desc|table)\b',
            caseSensitive: false,
          ).hasMatch(query.trimLeft()) ||
          // WITH … INSERT/UPDATE/DELETE (PostgreSQL) y PRAGMA x = y.
          RegExp(
            r'^with\b[\s\S]*\b(insert|update|delete)\b',
            caseSensitive: false,
          ).hasMatch(query.trimLeft()) ||
          RegExp(r'^pragma\b[^;]*=', caseSensitive: false).hasMatch(query);

/// Un fallo en la consulta [index] (desde 0) de un script; [done]: los
/// resultados de las anteriores.
class ScriptError implements Exception {
  ScriptError(this.index, this.message, this.done, {String? detail})
    : detail = detail ?? message;
  final int index;
  final String message;

  /// El mensaje de la base de datos, sin «Consulta N:».
  final String detail;
  final List<DevResult> done;
  @override
  String toString() => message;
}

/// Ejecuta [queries] en orden. Si una falla, para y lanza [ScriptError].
Future<List<DevResult>> runScript(DevDb db, List<String> queries) async {
  final out = <DevResult>[];
  for (final (i, q) in queries.indexed) {
    final watch = Stopwatch()..start();
    try {
      final r = await db.run(q);
      r.elapsed = watch.elapsed;
      out.add(r);
    } on UserError catch (e) {
      throw ScriptError(
        i,
        queries.length == 1
            ? e.message
            : tr('Consulta {0}: {1}', [i + 1, e.message]),
        out,
        detail: e.message,
      );
    }
  }
  return out;
}

// ------------------------------------------------------------------ SQL

List<String> _splitSql(String kind, String text) {
  final out = <String>[];
  var delim = ';';
  final buf = StringBuffer();
  var depth = 0; // BEGIN … END de un trigger de SQLite.
  var i = 0;
  final n = text.length;

  void flush() {
    final q = _stripLeadingSqlComments(buf.toString()).trim();
    if (q.isNotEmpty) out.add(q);
    buf.clear();
    depth = 0;
  }

  bool atLineStart() {
    final s = buf.toString();
    final nl = s.lastIndexOf('\n');
    return s.substring(nl + 1).trim().isEmpty;
  }

  while (i < n) {
    final c = text[i];
    final next = i + 1 < n ? text[i + 1] : '';
    // DELIMITER x (MySQL), en una línea suya.
    if (kind == 'mysql' &&
        (c == 'D' || c == 'd') &&
        atLineStart() &&
        RegExp(
          r'^delimiter[ \t]+(\S+)[ \t]*(\r?\n|$)',
          caseSensitive: false,
        ).hasMatch(text.substring(i))) {
      final m = RegExp(
        r'^delimiter[ \t]+(\S+)[ \t]*(\r?\n|$)',
        caseSensitive: false,
      ).firstMatch(text.substring(i))!;
      flush();
      delim = m[1]!;
      i += m[0]!.length;
      continue;
    }
    // Comentarios.
    if ((c == '-' && next == '-') || (kind == 'mysql' && c == '#')) {
      final end = text.indexOf('\n', i);
      final stop = end < 0 ? n : end + 1;
      buf.write(text.substring(i, stop));
      i = stop;
      continue;
    }
    if (c == '/' && next == '*') {
      final end = text.indexOf('*/', i + 2);
      final stop = end < 0 ? n : end + 2;
      buf.write(text.substring(i, stop));
      i = stop;
      continue;
    }
    // Cadenas y nombres entre comillas.
    if (c == "'" || c == '"' || (kind == 'mysql' && c == '`')) {
      var j = i + 1;
      while (j < n) {
        if (kind == 'mysql' && c != '`' && text[j] == r'\') {
          j += 2;
          continue;
        }
        if (text[j] == c) {
          if (j + 1 < n && text[j + 1] == c) {
            j += 2;
            continue;
          }
          break;
        }
        j++;
      }
      final stop = j < n ? j + 1 : n;
      buf.write(text.substring(i, stop));
      i = stop;
      continue;
    }
    // $$ … $$ o $etiqueta$ … $etiqueta$ (PostgreSQL).
    if (kind == 'postgres' && c == r'$') {
      final m = RegExp(
        r'^\$([A-Za-z_][A-Za-z0-9_]*)?\$',
      ).firstMatch(text.substring(i));
      if (m != null) {
        final tag = m[0]!;
        final end = text.indexOf(tag, i + tag.length);
        final stop = end < 0 ? n : end + tag.length;
        buf.write(text.substring(i, stop));
        i = stop;
        continue;
      }
    }
    // BEGIN … END en CREATE TRIGGER (SQLite): CASE … END también cierra.
    if (kind == 'sqlite' && RegExp('[A-Za-z]').hasMatch(c)) {
      final prev = i > 0 ? text[i - 1] : ' ';
      if (!RegExp(r'[A-Za-z0-9_]').hasMatch(prev)) {
        final w = RegExp(r'^[A-Za-z_]+').firstMatch(text.substring(i))![0]!;
        final lw = w.toLowerCase();
        final head = _stripLeadingSqlComments(buf.toString()).toLowerCase();
        if (RegExp(r'^\s*create\s+(temp\w*\s+)?trigger\b').hasMatch(head)) {
          if (lw == 'begin' || (lw == 'case' && depth > 0)) depth++;
          if (lw == 'end' && depth > 0) depth--;
        }
        buf.write(w);
        i += w.length;
        continue;
      }
    }
    if (depth == 0 && text.startsWith(delim, i)) {
      flush();
      i += delim.length;
      continue;
    }
    buf.write(c);
    i++;
  }
  flush();
  return out;
}

String _stripLeadingSqlComments(String s) {
  var t = s;
  while (true) {
    final u = t.trimLeft();
    if (u.startsWith('--') || u.startsWith('#')) {
      final nl = u.indexOf('\n');
      t = nl < 0 ? '' : u.substring(nl + 1);
    } else if (u.startsWith('/*')) {
      final end = u.indexOf('*/');
      t = end < 0 ? '' : u.substring(end + 2);
    } else {
      return u;
    }
  }
}

// ----------------------------------------------------------------- JSON

String _stripJsonComments(String text) {
  final b = StringBuffer();
  var inStr = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inStr) {
      b.write(c);
      if (c == r'\' && i + 1 < text.length) {
        b.write(text[++i]);
      } else if (c == '"') {
        inStr = false;
      }
      continue;
    }
    if (c == '"') {
      inStr = true;
    } else if (c == '/' && i + 1 < text.length && text[i + 1] == '/') {
      final nl = text.indexOf('\n', i);
      if (nl < 0) break;
      i = nl;
      b.write('\n');
      continue;
    }
    b.write(c);
  }
  return b.toString();
}

List<String> _splitJson(String text) {
  final t = _stripJsonComments(text);
  final out = <String>[];
  var depth = 0, start = -1;
  var inStr = false;
  for (var i = 0; i < t.length; i++) {
    final c = t[i];
    if (inStr) {
      if (c == r'\') {
        i++;
      } else if (c == '"') {
        inStr = false;
      }
      continue;
    }
    if (c == '"') {
      inStr = true;
    } else if (c == '{' || c == '[') {
      if (depth == 0) start = i;
      depth++;
    } else if (c == '}' || c == ']') {
      depth--;
      if (depth == 0 && start >= 0) {
        out.add(t.substring(start, i + 1).trim());
        start = -1;
      }
    }
  }
  // Algo sin cerrar: tal cual, para que dé su error de JSON.
  if (start >= 0) out.add(t.substring(start).trim());
  if (out.isEmpty && t.trim().isNotEmpty) out.add(t.trim());
  return out;
}
