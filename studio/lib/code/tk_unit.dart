import 'tk_codegen.dart';
import 'tk_model.dart';

/// Lo que el Diseñador hace con el código del usuario (añadir un método,
/// cambiar su cuerpo, renombrar…), en el lenguaje del destino: Python en
/// tkinter y Flask, JavaScript en Electron.
abstract class TkUnitLang {
  const TkUnitLang();

  /// python o javascript (para el resaltado y la IA).
  String get language;

  /// Comentario de una línea.
  String get comment;

  String template(String form, String comment);
  bool hasClass(String code, String form);

  /// Línea (desde 0) donde empieza el método (null si no está).
  int? lineOf(String code, String method);
  String ensureMethod(
    String code,
    String form,
    String method, {
    String param = '',
    String? body,
  });
  String setMethodBody(
    String code,
    String form,
    String method,
    String body, {
    String param = '',
  });
  String renameMethod(String code, String from, String to);
  String renameWidget(String code, String from, String to);
  String renameForm(String code, String from, String to);
}

/// El lenguaje del código de [d].
TkUnitLang tkUnitOf(TkDesign d) =>
    d.isWebNext || d.isReactNative || d.isWebReact
    ? const JsUnit()
    : d.isFlutter
    ? const DartUnit()
    : d.isConsole
    ? switch (d.codeLang) {
        'cpp' => const CppUnit(),
        'pas' => const PascalUnit(),
        _ => const PyUnit(),
      }
    : d.isCpp
    ? const CppUnit()
    : d.isPascal
    ? const PascalUnit()
    : d.isJs
    ? const JsUnit()
    : const PyUnit();

/// Python: lo de siempre (TkUnit).
class PyUnit extends TkUnitLang {
  const PyUnit();

  @override
  String get language => 'python';
  @override
  String get comment => '#';
  @override
  String template(String form, String comment) =>
      TkUnit.template(form, comment);
  @override
  bool hasClass(String code, String form) => TkUnit.hasClass(code, form);
  @override
  int? lineOf(String code, String method) => TkUnit.lineOf(code, method);
  @override
  String ensureMethod(
    String code,
    String form,
    String method, {
    String param = '',
    String? body,
  }) => TkUnit.ensureMethod(
    code,
    form,
    method,
    param: param,
    body: body ?? 'pass',
  );
  @override
  String setMethodBody(
    String code,
    String form,
    String method,
    String body, {
    String param = '',
  }) => TkUnit.setMethodBody(code, form, method, body, param: param);
  @override
  String renameMethod(String code, String from, String to) =>
      TkUnit.renameMethod(code, from, to);
  @override
  String renameWidget(String code, String from, String to) =>
      TkUnit.renameWidget(code, from, to);
  @override
  String renameForm(String code, String from, String to) =>
      TkUnit.renameForm(code, from, to);
}

/// JavaScript: `class Form1 extends FormDesign { Button1_click(event) {…} }`.
class JsUnit extends TkUnitLang {
  const JsUnit();

  @override
  String get language => 'javascript';
  @override
  String get comment => '//';

  @override
  String template(String form, String comment) =>
      '$comment\n\nclass $form extends FormDesign {\n'
      '  form_create() {\n  }\n}\n';

  /// [code] con las cadenas, plantillas y comentarios cambiados por espacios
  /// (los saltos de línea se quedan): así las llaves y los nombres que se
  /// buscan son solo los del código.
  static String mask(String code) {
    final out = StringBuffer();
    var i = 0;
    final n = code.length;
    void blank(int from, int to) {
      for (var k = from; k < to && k < n; k++) {
        out.write(code[k] == '\n' ? '\n' : ' ');
      }
    }

    while (i < n) {
      final c = code[i];
      if (c == '/' && i + 1 < n && code[i + 1] == '/') {
        final end = code.indexOf('\n', i);
        final to = end < 0 ? n : end;
        blank(i, to);
        i = to;
      } else if (c == '/' && i + 1 < n && code[i + 1] == '*') {
        final end = code.indexOf('*/', i + 2);
        final to = end < 0 ? n : end + 2;
        blank(i, to);
        i = to;
      } else if (c == '"' || c == "'" || c == '`') {
        var k = i + 1;
        var depth = 0;
        while (k < n) {
          final d = code[k];
          if (d == r'\') {
            k += 2;
            continue;
          }
          if (c == '`' && d == r'$' && k + 1 < n && code[k + 1] == '{') {
            depth++;
            k += 2;
            continue;
          }
          if (c == '`' && depth > 0 && d == '}') {
            depth--;
            k++;
            continue;
          }
          if (d == c && depth == 0) break;
          if (d == '\n' && c != '`') break;
          k++;
        }
        out.write(c);
        blank(i + 1, k);
        if (k < n) out.write(code[k]);
        i = k + 1;
      } else {
        out.write(c);
        i++;
      }
    }
    return out.toString();
  }

  /// Llave que cierra la que se abre en [open] (en el texto enmascarado).
  static int? _close(String masked, int open) {
    var depth = 0;
    for (var i = open; i < masked.length; i++) {
      final c = masked[i];
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }

  /// Posiciones de la llave que abre la clase y de la que la cierra.
  static (int, int)? _classRange(String code, String form) {
    final m = mask(code);
    final head = RegExp(
      '\\bclass\\s+${RegExp.escape(form)}\\b[^{]*\\{',
    ).firstMatch(m);
    if (head == null) return null;
    final open = head.end - 1;
    final close = _close(m, open);
    return close == null ? null : (open, close);
  }

  @override
  bool hasClass(String code, String form) => _classRange(code, form) != null;

  /// La cabecera de [method] en una línea (enmascarada).
  RegExp defPattern(String method) => RegExp(
    '^[ \\t]*(?:async[ \\t]+)?${RegExp.escape(method)}[ \\t]*\\([^)]*\\)[ \\t]*\\{',
  );

  /// La primera línea de un método nuevo.
  String header(String method, String param) =>
      '$method(${param.isEmpty ? '' : param}) {';

  /// Una clase nueva con [stub] dentro.
  String newClass(String form, String stub) =>
      'class $form extends FormDesign {\n$stub\n}\n';

  @override
  int? lineOf(String code, String method) {
    final lines = mask(code).split('\n');
    final def = defPattern(method);
    for (var i = 0; i < lines.length; i++) {
      if (def.hasMatch(lines[i])) return i;
    }
    return null;
  }

  static List<String> _indented(String body, String indent) => [
    for (final l in body.replaceAll('\r\n', '\n').trimRight().split('\n'))
      l.trim().isEmpty ? '' : '$indent$l',
  ];

  static String _body(String? body) =>
      body == null || body.trim() == 'pass' ? '' : body;

  @override
  String ensureMethod(
    String code,
    String form,
    String method, {
    String param = '',
    String? body,
  }) {
    if (lineOf(code, method) != null) return code;
    final inner = _body(body);
    String stub(String indent) => [
      '$indent${header(method, param)}',
      if (inner.isNotEmpty) ..._indented(inner, '$indent  '),
      '$indent}',
    ].join('\n');
    final range = _classRange(code, form);
    if (range == null) {
      final base = code.trimRight();
      return '${base.isEmpty ? '' : '$base\n\n'}${newClass(form, stub('  '))}';
    }
    final (open, close) = range;
    // La sangría de los métodos que ya hay (dos espacios si no hay).
    final members = code.substring(open + 1, close);
    // (Sin contar «public:» y las demás etiquetas de acceso de C++.)
    final firstLine = members
        .split('\n')
        .firstWhere(
          (l) =>
              l.trim().isNotEmpty &&
              !RegExp(r'^\s*(public|private|protected)\s*:').hasMatch(l),
          orElse: () => '',
        );
    final indent = firstLine.isEmpty
        ? '  '
        : RegExp(r'^[ \t]*').stringMatch(firstLine)!;
    final before = code.substring(0, close).trimRight();
    final empty = members.trim().isEmpty;
    return '$before\n${empty ? '' : '\n'}${stub(indent)}\n'
        '${code.substring(close)}';
  }

  @override
  String setMethodBody(
    String code,
    String form,
    String method,
    String body, {
    String param = '',
  }) {
    final at = lineOf(code, method);
    if (at == null) {
      return ensureMethod(code, form, method, param: param, body: body);
    }
    final m = mask(code);
    var offset = 0;
    final lines = code.split('\n');
    for (var i = 0; i < at; i++) {
      offset += lines[i].length + 1;
    }
    final open = m.indexOf('{', offset);
    final close = _close(m, open);
    if (close == null) return code;
    final indent = RegExp(r'^[ \t]*').stringMatch(lines[at])!;
    final step = indent.isEmpty ? '  ' : indent;
    final inner = _body(body);
    final text = inner.isEmpty
        ? '\n$indent'
        : '\n${_indented(inner, '$indent$step').join('\n')}\n$indent';
    return '${code.substring(0, open + 1)}$text${code.substring(close)}';
  }

  static String _replace(String code, String pattern, String by) =>
      code.replaceAllMapped(
        RegExp(pattern, multiLine: true),
        (m) => '${m[1] ?? ''}$by',
      );

  @override
  String renameMethod(String code, String from, String to) {
    final f = RegExp.escape(from);
    return _replace(
      _replace(code, '^([ \\t]*(?:async[ \\t]+)?)$f(?=[ \\t]*\\()', to),
      '(\\bthis\\.)$f\\b',
      to,
    );
  }

  @override
  String renameWidget(String code, String from, String to) =>
      _replace(code, '(\\bthis\\.)${RegExp.escape(from)}\\b', to);

  @override
  String renameForm(String code, String from, String to) =>
      _replace(code, '(\\bclass\\s+)${RegExp.escape(from)}\\b', to);
}

/// C++ (FLTK): `class Form1 : public FormDesign { public: void X() override {…} };`.
/// Las llaves, cadenas y comentarios se leen como en JavaScript.
class CppUnit extends JsUnit {
  const CppUnit();

  @override
  String get language => 'cpp';

  @override
  String template(String form, String comment) =>
      '$comment\n\nclass $form : public FormDesign {\npublic:\n'
      '  void form_create() override {\n  }\n};\n';

  /// El tipo de C++ del argumento de un evento.
  static String typed(String param) => switch (param) {
    'value' => 'double value',
    'path' => 'const std::string& path',
    'item' => 'const std::string& item',
    _ => '',
  };

  @override
  RegExp defPattern(String method) => RegExp(
    '^[ \\t]*(?:virtual[ \\t]+)?(?:[\\w:<>&*]+[ \\t]+)+${RegExp.escape(method)}'
    '[ \\t]*\\([^)]*\\)[ \\t]*(?:const[ \\t]*)?(?:override[ \\t]*)?\\{',
  );

  @override
  String header(String method, String param) =>
      'void $method(${typed(param)}) override {';

  @override
  String newClass(String form, String stub) =>
      'class $form : public FormDesign {\npublic:\n$stub\n};\n';

  @override
  String renameMethod(String code, String from, String to) {
    final f = RegExp.escape(from);
    return JsUnit._replace(
      JsUnit._replace(code, '(\\bvoid[ \\t]+)$f(?=[ \\t]*\\()', to),
      '(\\bthis->)$f\\b',
      to,
    );
  }

  @override
  String renameWidget(String code, String from, String to) {
    final f = RegExp.escape(from);
    return JsUnit._replace(
      JsUnit._replace(code, '(\\bthis->)$f\\b', to),
      '(^|[^\\w.>:])$f(?=[ \\t]*(?:->|\\.))',
      to,
    );
  }

  @override
  String renameForm(String code, String from, String to) =>
      JsUnit._replace(code, '(\\bclass\\s+)${RegExp.escape(from)}\\b', to);
}

/// Object Pascal (Lazarus): la unidad Form1 con
/// `TForm1 = class(TFormDesign)`. Cada método se declara en la clase
/// (`procedure Button1_click; override;`) y se escribe en implementation
/// (`procedure TForm1.Button1_click; begin … end;`). Pascal no distingue
/// mayúsculas.
class PascalUnit extends TkUnitLang {
  const PascalUnit();

  @override
  String get language => 'pascal';
  @override
  String get comment => '//';

  /// Las unidades que usa el código del usuario.
  static const uses =
      'Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,\n'
      '  ExtCtrls, ComCtrls, Menus, dms, design';

  @override
  String template(String form, String comment) =>
      '$comment\nunit $form;\n\n{\$mode objfpc}{\$H+}\n\ninterface\n\n'
      'uses\n  $uses;\n\ntype\n  T$form = class(TFormDesign)\n  public\n'
      '    procedure form_create; override;\n  end;\n\nimplementation\n\n'
      'procedure T$form.form_create;\nbegin\nend;\n\nend.\n';

  /// El tipo del argumento de un evento.
  static String typed(String param) => switch (param) {
    'value' => 'Value: Double',
    'path' => 'const Path: string',
    'item' => 'const Item: string',
    _ => '',
  };

  /// [code] con las cadenas y los comentarios cambiados por espacios (los
  /// saltos de línea se quedan).
  static String mask(String code) {
    final out = StringBuffer();
    var i = 0;
    final n = code.length;
    void blank(int from, int to) {
      for (var k = from; k < to && k < n; k++) {
        out.write(code[k] == '\n' ? '\n' : ' ');
      }
    }

    while (i < n) {
      final c = code[i];
      int? to;
      if (c == '/' && i + 1 < n && code[i + 1] == '/') {
        final end = code.indexOf('\n', i);
        to = end < 0 ? n : end;
      } else if (c == '{') {
        final end = code.indexOf('}', i + 1);
        to = end < 0 ? n : end + 1;
      } else if (c == '(' && i + 1 < n && code[i + 1] == '*') {
        final end = code.indexOf('*)', i + 2);
        to = end < 0 ? n : end + 2;
      }
      if (to != null) {
        blank(i, to);
        i = to;
      } else if (c == "'") {
        var k = i + 1;
        while (k < n && code[k] != "'" && code[k] != '\n') {
          k++;
        }
        out.write(c);
        blank(i + 1, k);
        if (k < n) out.write(code[k]);
        i = k + 1;
      } else {
        out.write(c);
        i++;
      }
    }
    return out.toString();
  }

  static RegExp _ci(String pattern) =>
      RegExp(pattern, caseSensitive: false, multiLine: true);

  /// La clase: dónde empieza su cabecera y dónde está su «end;».
  static (int, int)? _classRange(String code, String form) {
    final m = mask(code);
    final head = _ci(
      '\\bT${RegExp.escape(form)}\\s*=\\s*class\\s*\\([^)]*\\)',
    ).firstMatch(m);
    if (head == null) return null;
    final end = _ci(r'^[ \t]*end[ \t]*;').firstMatch(m.substring(head.end));
    return end == null ? null : (head.end, head.end + end.start);
  }

  @override
  bool hasClass(String code, String form) => _classRange(code, form) != null;

  RegExp _impl(String method) => _ci(
    '^[ \\t]*procedure[ \\t]+[A-Za-z_]\\w*[ \\t]*\\.[ \\t]*'
    '${RegExp.escape(method)}[ \\t]*[(;]',
  );

  @override
  int? lineOf(String code, String method) {
    final lines = mask(code).split('\n');
    final def = _impl(method);
    for (var i = 0; i < lines.length; i++) {
      if (def.hasMatch(lines[i])) return i;
    }
    return null;
  }

  static String _args(String param) {
    final t = typed(param);
    return t.isEmpty ? '' : '($t)';
  }

  static List<String> _indented(String body, String indent) => [
    for (final l in body.replaceAll('\r\n', '\n').trimRight().split('\n'))
      l.trim().isEmpty ? '' : '$indent$l',
  ];

  static String _body(String? body) =>
      body == null || body.trim() == 'pass' ? '' : body;

  @override
  String ensureMethod(
    String code,
    String form,
    String method, {
    String param = '',
    String? body,
  }) {
    if (lineOf(code, method) != null) return code;
    var src = code;
    if (_classRange(src, form) == null) {
      final base = src.trimRight();
      src = template(form, base.isEmpty ? comment : base);
      if (lineOf(src, method) != null) {
        return setMethodBody(src, form, method, _body(body), param: param);
      }
    }
    final (start, end) = _classRange(src, form)!;
    // La declaración, con la sangría de los demás miembros.
    final members = src.substring(start, end).split('\n');
    final first = members.firstWhere(
      (l) =>
          l.trim().isNotEmpty &&
          !_ci(r'^\s*(public|private|protected|published)\s*$').hasMatch(l),
      orElse: () => '',
    );
    final indent = first.isEmpty
        ? '    '
        : RegExp(r'^[ \t]*').stringMatch(first)!;
    final decl = '${indent}procedure $method${_args(param)}; override;\n';
    src = '${src.substring(0, end)}$decl${src.substring(end)}';
    // La implementación, antes del «end.» final.
    final inner = _body(body);
    final impl = [
      'procedure T$form.$method${_args(param)};',
      'begin',
      if (inner.isNotEmpty) ..._indented(inner, '  '),
      'end;',
    ].join('\n');
    final last = _ci(r'^[ \t]*end[ \t]*\.').allMatches(mask(src)).lastOrNull;
    if (last == null) return '${src.trimRight()}\n\n$impl\n';
    final before = src.substring(0, last.start).trimRight();
    return '$before\n\n$impl\n\n${src.substring(last.start)}';
  }

  /// Dónde está el «begin» del método de la línea [at] y su «end».
  static (int, int)? _block(String code, int at) {
    final m = mask(code);
    var offset = 0;
    final lines = code.split('\n');
    for (var i = 0; i < at; i++) {
      offset += lines[i].length + 1;
    }
    int? begin;
    var depth = 0;
    for (final t in RegExp(r'[A-Za-z_]\w*').allMatches(m, offset)) {
      final w = t[0]!.toLowerCase();
      if (begin == null) {
        if (w == 'begin') {
          begin = t.end;
          depth = 1;
        }
        continue;
      }
      if (const {'begin', 'case', 'try', 'asm', 'record'}.contains(w)) {
        depth++;
      } else if (w == 'end') {
        depth--;
        if (depth == 0) return (begin, t.start);
      }
    }
    return null;
  }

  @override
  String setMethodBody(
    String code,
    String form,
    String method,
    String body, {
    String param = '',
  }) {
    final at = lineOf(code, method);
    if (at == null) {
      return ensureMethod(code, form, method, param: param, body: body);
    }
    final block = _block(code, at);
    if (block == null) return code;
    final (open, close) = block;
    final indent = RegExp(r'^[ \t]*').stringMatch(code.split('\n')[at])!;
    final inner = _body(body);
    final text = inner.isEmpty
        ? '\n$indent'
        : '\n${_indented(inner, '$indent  ').join('\n')}\n$indent';
    return '${code.substring(0, open)}$text${code.substring(close)}';
  }

  static String _replace(String code, String pattern, String by) =>
      code.replaceAllMapped(_ci(pattern), (m) => '${m[1] ?? ''}$by');

  @override
  String renameMethod(String code, String from, String to) {
    final f = RegExp.escape(from);
    var out = _replace(code, '(\\bprocedure[ \\t]+)$f\\b', to);
    out = _replace(
      out,
      '(\\bprocedure[ \\t]+[A-Za-z_]\\w*[ \\t]*\\.)$f\\b',
      to,
    );
    return _replace(out, '(\\bSelf\\.)$f\\b', to);
  }

  @override
  String renameWidget(String code, String from, String to) {
    final f = RegExp.escape(from);
    return _replace(
      _replace(code, '(\\bSelf\\.)$f\\b', to),
      '(^|[^\\w.])$f(?=[ \\t]*\\.)',
      to,
    );
  }

  @override
  String renameForm(String code, String from, String to) {
    final f = RegExp.escape(from);
    return _replace(
      _replace(code, '(^[ \\t]*unit[ \\t]+)$f\\b', to),
      '(^|[^\\w])T$f\\b',
      'T$to',
    );
  }
}

/// Dart (Flutter): las llaves, cadenas y comentarios se leen como en
/// JavaScript; el código es la clase App de lib/app.dart.
class DartUnit extends JsUnit {
  const DartUnit();

  @override
  String get language => 'dart';
}
