import 'dart:math' as math;

import '../core/errors.dart';
import 'tk_chart.dart';
import 'tk_cpp.dart';
import 'tk_electron.dart';
import 'tk_helpers.dart';
import 'tk_html_view.dart';
import 'tk_ai_component.dart';
import 'tk_reports.dart';
import 'tk_model.dart';
import 'tk_web_codegen.dart';

/// Literales de Python.
class TkPy {
  TkPy._();

  /// [s] como cadena de Python: el texto de un componente nunca puede salir
  /// de sus comillas, venga de donde venga el diseño.
  static String str(String s) {
    final b = StringBuffer('"');
    for (final c in s.runes) {
      switch (c) {
        case 0x5C:
          b.write(r'\\');
        case 0x22:
          b.write(r'\"');
        case 0x0A:
          b.write(r'\n');
        case 0x0D:
          b.write(r'\r');
        case 0x09:
          b.write(r'\t');
        default:
          if (c < 0x20 || c == 0x7F) {
            b.write(r'\x');
            b.write(c.toRadixString(16).padLeft(2, '0'));
          } else if (c >= 0xD800 && c <= 0xDFFF ||
              c == 0x2028 ||
              c == 0x2029 ||
              c == 0x85) {
            b.write(r'\u');
            b.write(c.toRadixString(16).padLeft(4, '0'));
          } else {
            b.writeCharCode(c);
          }
      }
    }
    b.write('"');
    return b.toString();
  }

  static String list(List<String> items) => '[${items.map(str).join(', ')}]';

  static int integer(Object? v) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static String number(Object? v) {
    final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    if (!n.isFinite) return '0';
    return n == n.roundToDouble() && n.abs() < 1e15 ? '${n.toInt()}' : '$n';
  }
}

/// El código del usuario: una unidad de Python con la clase de la ventana,
/// que hereda de la generada desde el diseño. Se guarda y se copia al
/// archivo tal cual; estas funciones solo añaden métodos o renombran lo que
/// el diseñador cambió.
class TkUnit {
  TkUnit._();

  /// Unidad de una ventana nueva.
  static String template(String form, String comment) =>
      '$comment\n\n\nclass $form(FormDesign):\n    pass\n';

  /// ¿Empieza cada línea dentro de una cadena de varias líneas?
  static List<bool> _inString(List<String> lines) {
    final out = <bool>[];
    String? open;
    for (final l in lines) {
      out.add(open != null);
      var i = 0;
      while (i < l.length) {
        if (open != null) {
          if (l[i] == r'\') {
            i += 2;
          } else if (l.startsWith(open, i)) {
            i += 3;
            open = null;
          } else {
            i++;
          }
          continue;
        }
        final c = l[i];
        if (c == '#') break;
        if (c == '"' || c == "'") {
          final triple = c * 3;
          if (l.startsWith(triple, i)) {
            open = triple;
            i += 3;
            continue;
          }
          i++;
          while (i < l.length && l[i] != c) {
            i += l[i] == r'\' ? 2 : 1;
          }
        }
        i++;
      }
    }
    return out;
  }

  /// Primera línea de la clase [form] y la que sigue a su última línea con
  /// contenido (null si no está).
  static (int, int)? _classRange(List<String> lines, String form) {
    final strings = _inString(lines);
    final head = RegExp('^class\\s+${RegExp.escape(form)}\\b');
    for (var i = 0; i < lines.length; i++) {
      if (strings[i] || !head.hasMatch(lines[i])) continue;
      var end = lines.length;
      for (var j = i + 1; j < lines.length; j++) {
        final l = lines[j];
        if (strings[j] || l.trim().isEmpty) continue;
        if (!l.startsWith(RegExp(r'[\s#]'))) {
          end = j;
          break;
        }
      }
      while (end > i + 1 && lines[end - 1].trim().isEmpty) {
        end--;
      }
      return (i, end);
    }
    return null;
  }

  /// ¿Define la unidad la clase de la ventana?
  static bool hasClass(String code, String form) =>
      _classRange(code.split('\n'), form) != null;

  /// Línea (desde 0) donde empieza el método [method] (null si no está).
  static int? lineOf(String code, String method) {
    final lines = code.split('\n');
    final strings = _inString(lines);
    final def = RegExp('^[ \\t]+def\\s+${RegExp.escape(method)}\\s*\\(');
    for (var i = 0; i < lines.length; i++) {
      if (!strings[i] && def.hasMatch(lines[i])) return i;
    }
    return null;
  }

  /// Añade el método al final de la clase si aún no existe (el resto del
  /// texto no cambia).
  static String ensureMethod(
    String code,
    String form,
    String method, {
    String param = '',
    String body = 'pass',
  }) {
    if (lineOf(code, method) != null) return code;
    final sig = param.isEmpty ? '(self)' : '(self, $param=None)';
    final lines = code.split('\n');
    final range = _classRange(lines, form);
    if (range == null) {
      final base = code.trimRight();
      return '${base.isEmpty ? '' : '$base\n\n\n'}'
          'class $form(FormDesign):\n'
          '    def $method$sig:\n'
          '${_indented(body, '        ').join('\n')}\n';
    }
    final (start, end) = range;
    final content = [
      for (var i = start + 1; i < end; i++)
        if (lines[i].trim().isNotEmpty) i,
    ];
    final indent = content.isEmpty
        ? '    '
        : RegExp(r'^[ \t]*').stringMatch(lines[content.first])!;
    final stub = ['${indent}def $method$sig:', ..._indented(body, indent * 2)];
    if (content.length == 1 && lines[content.first].trim() == 'pass') {
      lines.replaceRange(content.first, content.first + 1, stub);
    } else if (content.isEmpty) {
      lines.insertAll(end, stub);
    } else {
      lines.insertAll(end, ['', ...stub]);
    }
    return lines.join('\n');
  }

  /// Cambia el cuerpo de [method] por [body] (si no existe, lo crea).
  static String setMethodBody(
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
    final lines = code.split('\n');
    final strings = _inString(lines);
    final indent = RegExp(r'^[ \t]*').stringMatch(lines[at])!;
    var end = lines.length;
    for (var i = at + 1; i < lines.length; i++) {
      final l = lines[i];
      if (strings[i] || l.trim().isEmpty) continue;
      if (RegExp(r'^[ \t]*').stringMatch(l)!.length <= indent.length) {
        end = i;
        break;
      }
    }
    while (end > at + 1 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    // Una definición puede ocupar varias líneas.
    var first = at + 1;
    while (first < end && !lines[first - 1].trimRight().endsWith(':')) {
      first++;
    }
    final step = indent.isEmpty ? '    ' : indent;
    lines.replaceRange(first, end, _indented(body, '$indent$step'));
    return lines.join('\n');
  }

  static List<String> _indented(String body, String indent) => [
    for (final l in body.replaceAll('\r\n', '\n').trimRight().split('\n'))
      l.trim().isEmpty ? '' : '$indent$l',
  ];

  static String _replaceWord(String code, String pattern, String by) =>
      code.replaceAllMapped(RegExp(pattern, multiLine: true), (m) {
        return '${m[1] ?? ''}$by';
      });

  /// Renombra un método y las llamadas `self.método`.
  static String renameMethod(String code, String from, String to) {
    final f = RegExp.escape(from);
    return _replaceWord(
      _replaceWord(code, '(\\bdef\\s+)$f(?=\\s*\\()', to),
      '(\\bself\\.)$f\\b',
      to,
    );
  }

  /// Renombra las referencias a un componente y a lo que se genera con su
  /// nombre: la variable y, en una Tabla de datos, sus filas, la barra y los
  /// métodos de rellenar y de leer la fila elegida.
  static String renameWidget(String code, String from, String to) {
    final f = RegExp.escape(from);
    var r = code;
    for (final s in _generated) {
      r = _replaceWord(r, '(\\bself\\.)${f}_$s\\b', '${to}_$s');
    }
    r = _replaceWord(r, '(\\bself\\._)${f}_bound\\b', '${to}_bound');
    return _replaceWord(r, '(\\bself\\.)$f\\b', to);
  }

  static const _generated = ['var', 'rows', 'row', 'refresh', 'scroll'];

  /// Renombra la clase de la ventana.
  static String renameForm(String code, String from, String to) =>
      _replaceWord(code, '^(class\\s+)${RegExp.escape(from)}\\b', to);
}

/// Genera el archivo de Python de una ventana: el diseño (siempre con
/// `place()`) más el código del usuario, tal cual. La misma entrada da
/// siempre el mismo archivo, carácter a carácter (de ahí sale su huella): no
/// lleva fechas, ni rutas, ni el idioma del usuario.
class TkCodegen {
  TkCodegen._();

  static const _in = '        ';

  /// Clases que toman el fondo de quien las contiene.
  /// Clases con fondo blanco y tinta negra de serie.
  static const _fields = {'Entry', 'Text', 'Listbox'};

  static const _inherits = {
    'Label',
    'Checkbutton',
    'Radiobutton',
    'Scale',
    'Frame',
  };

  static String _call(String target, List<String> args) {
    final one = '$_in$target(${args.join(', ')})';
    if (one.length <= 88) return one;
    return '$_in$target(\n${args.map((a) => '$_in    $a,').join('\n')}\n$_in)';
  }

  /// [v] si es un color válido de Tk.
  static String? color(Object? v) => _color(v);

  static String? _color(Object? v) {
    final s = '${v ?? ''}'.trim();
    return RegExp(
          r'^(#[0-9a-fA-F]{3}|#[0-9a-fA-F]{6}|[A-Za-z][A-Za-z0-9 ]*)$',
        ).hasMatch(s)
        ? s
        : null;
  }

  /// Negro o blanco, lo que se lea mejor sobre [bg].
  static String contrast(String bg) {
    final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(bg);
    if (m == null) return '#000000';
    final v = int.parse(m[1]!, radix: 16);
    final r = v >> 16 & 255, g = v >> 8 & 255, b = v & 255;
    return 0.299 * r + 0.587 * g + 0.114 * b < 128 ? '#ffffff' : '#000000';
  }

  /// Color de fondo con el que se ve [w] (el suyo o el de quien lo contiene).
  static String backgroundOf(TkDesign d, TkWidget w) {
    final own = _color(w.props['bg']);
    if (own != null && own.isNotEmpty) return own;
    return parentBackground(d, w);
  }

  /// Fondo de lo que contiene a [w].
  static String parentBackground(TkDesign d, TkWidget w) {
    final p = w.parent == null ? null : d.byName(w.parent!);
    return p != null
        ? backgroundOf(d, p)
        : _color(d.prop(tkFormBg)) ?? '#f0f0f0';
  }

  /// Valor de la opción [p] de [w] para Python (null = no se escribe).
  static String? _value(TkProp p, Object? v) {
    if ((v == p.def && !p.always) || v == null) return null;
    return switch (p.type) {
      TkPropType.text || TkPropType.multiline => TkPy.str('$v'),
      TkPropType.integer => '${TkPy.integer(v)}',
      TkPropType.number => TkPy.number(v),
      TkPropType.boolean => v == true ? 'True' : 'False',
      TkPropType.color => switch (_color(v)) {
        final c? => TkPy.str(c),
        _ => null,
      },
      TkPropType.choice =>
        p.choices.contains('$v') && '$v'.isNotEmpty ? TkPy.str('$v') : null,
      // Las trata el generador.
      TkPropType.connection || TkPropType.reference => null,
    };
  }

  static String? _font(TkWidget w) {
    final family = '${w.props['font_family'] ?? ''}'.trim();
    final size = TkPy.integer(w.props['font_size']);
    final style = [
      if (w.props['font_bold'] == true) 'bold',
      if (w.props['font_italic'] == true) 'italic',
    ].join(' ');
    if (family.isEmpty && size <= 0 && style.isEmpty) return null;
    return '(${[TkPy.str(family.isEmpty ? 'TkDefaultFont' : family), '${size > 0 ? size : 12}', if (style.isNotEmpty) TkPy.str(style)].join(', ')})';
  }

  /// Variable del grupo de opciones de [w].
  static String group(TkWidget w) => _group(w);

  static String _group(TkWidget w) {
    final g = w.text('group').trim();
    return RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(g) ? g : 'group1';
  }

  /// Elementos de una lista.
  static List<String> items(TkWidget w) => _items(w);

  static List<String> _items(TkWidget w) => [
    for (final l in w.text('items').split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  /// Columnas de una tabla: (campo, título, ancho).
  static List<(String, String, int?)> gridColumns(TkWidget w) => [
    for (final l in w.text('columns').split('\n'))
      if (l.trim().isNotEmpty)
        () {
          final f = l.split('|').map((x) => x.trim()).toList();
          return (
            f[0],
            f.length > 1 && f[1].isNotEmpty ? f[1] : f[0],
            f.length > 2 ? int.tryParse(f[2]) : null,
          );
        }(),
  ];

  /// La conexión de la que lee la tabla [w], si existe.
  static TkWidget? source(TkDesign d, TkWidget w) => _source(d, w);

  static TkWidget? _source(TkDesign d, TkWidget w) =>
      d.reference(w.text('source'), 'Connection');

  /// Campos enlazados a la tabla [w].
  static Iterable<TkWidget> bound(TkDesign d, TkWidget w) => _bound(d, w);

  static Iterable<TkWidget> _bound(TkDesign d, TkWidget w) => d.widgets.where(
    (o) =>
        o.kind == 'Entry' &&
        o.text('data_grid') == w.name &&
        o.text('data_field').trim().isNotEmpty,
  );

  /// Tabla: cabeceras, barra de desplazamiento y lista de filas leídas.
  static void _treeview(
    StringBuffer b,
    TkDesign d,
    TkWidget w,
    String parent,
    bool withBound,
  ) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    final cols = gridColumns(w);
    b
      ..writeln('$_in# ${w.name}')
      ..writeln(
        _call('$self = ttk.Treeview', [
          parent,
          'columns=${TkPy.list([for (final c in cols) c.$1])}',
          'show="headings"',
        ]),
      )
      ..writeln(
        '$_in$self.place(x=$x, y=$y, '
        'width=${w.width - 16}, height=${w.height})',
      );
    for (final (field, title, width) in cols) {
      final f = TkPy.str(field);
      b.writeln('$_in$self.heading($f, text=${TkPy.str(title)})');
      if (width != null) b.writeln('$_in$self.column($f, width=$width)');
    }
    b
      ..writeln(
        _call('${self}_scroll = ttk.Scrollbar', [
          parent,
          'orient="vertical"',
          'command=$self.yview',
        ]),
      )
      ..writeln(
        '$_in${self}_scroll.place(x=${x + w.width - 16}, y=$y, '
        'width=16, height=${w.height})',
      )
      ..writeln('$_in$self.configure(yscrollcommand=${self}_scroll.set)')
      ..writeln('$_in${self}_rows = []');
    if (withBound) {
      b.writeln('$_in$self.bind("<<TreeviewSelect>>", self._${w.name}_bound)');
    }
    for (final e in w.component.events) {
      final m = w.events[e.key];
      if (m == null) continue;
      for (final s in e.sequences) {
        b.writeln('$_in$self.bind(${TkPy.str(s)}, self.$m, add="+")');
      }
    }
  }

  /// Métodos de la tabla [w], iguales en los dos destinos.
  static void gridMethods(StringBuffer b, TkDesign d, TkWidget w) =>
      _gridMethods(b, d, w);

  /// Métodos de la tabla [w]: recargar, fila elegida y campos enlazados.
  static void _gridMethods(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final source = _source(d, w);
    final fields = TkPy.list([for (final c in gridColumns(w)) c.$1]);
    b.writeln();
    if (source == null) {
      b
        ..writeln('    def ${w.name}_refresh(self, *args):')
        ..writeln('${_in}pass');
    } else if (source.text('connection').isEmpty) {
      final model = TkPy.str(w.text('model').trim());
      final order = w.text('order').trim();
      final limit = TkPy.integer(w.props['limit'] ?? 200);
      b
        ..writeln('    def ${w.name}_refresh(self, domain=()):')
        ..writeln('$_in"""Reload from the ERP; domain narrows the rows."""')
        ..writeln(
          _call('${self}_rows = self._fill', [
            self,
            fields,
            'lambda: self.${source.name}.search(\n'
                '$_in        $model,\n'
                '$_in        domain,\n'
                '$_in        $fields or None,\n'
                '$_in        $limit,\n'
                '$_in        ${order.isEmpty ? 'None' : TkPy.str(order)},\n'
                '$_in    )',
          ]),
        );
    } else {
      b
        ..writeln('    def ${w.name}_refresh(self, params=()):')
        ..writeln('$_in"""Reload the query; params fill its ? marks."""')
        ..writeln(
          _call('${self}_rows = self._fill', [
            self,
            fields,
            'lambda: self.${source.name}.query(\n'
                '$_in        ${TkPy.str(w.text('query'))},\n'
                '$_in        params,\n'
                '$_in    )',
          ]),
        );
    }
    b
      ..writeln()
      ..writeln('    def ${w.name}_row(self):')
      ..writeln('$_in"""The selected row, as a dictionary."""')
      ..writeln('${_in}chosen = $self.selection()')
      ..writeln(
        '${_in}return ${self}_rows[int(chosen[0])] if chosen else None',
      );
    final bound = _bound(d, w).toList();
    if (bound.isNotEmpty) {
      b
        ..writeln()
        ..writeln('    def _${w.name}_bound(self, event=None):')
        ..writeln('${_in}row = self.${w.name}_row()')
        ..writeln('${_in}if row is None:')
        ..writeln('$_in    return');
      for (final f in bound) {
        final field = TkPy.str(f.text('data_field').trim());
        b.writeln('${_in}self.${f.name}_var.set(self._text(row.get($field)))');
      }
    }
  }

  /// Dónde se crea [w]: la ventana, un marco o la página de un control de
  /// páginas.
  static String parentOf(TkDesign d, TkWidget w) {
    final p = w.parent == null ? null : d.byName(w.parent!);
    if (p == null || !w.component.nestable) return 'self.root';
    if (p.kind == 'PageControl') return 'self.${p.name}_page${d.pageOf(w)}';
    return 'self.${p.name}';
  }

  /// Posición de [w] dentro de lo que lo contiene: en una página, debajo de
  /// las pestañas.
  static (int, int) placeOf(TkDesign d, TkWidget w) =>
      d.pageControlOf(w) == null || !w.component.nestable
      ? (w.x, w.y)
      : (w.x, w.y - tkTabHeight);

  /// Intervalo de un temporizador, en milisegundos.
  static int interval(TkWidget w) =>
      math.max(1, TkPy.integer(w.props['interval'] ?? 1000));

  /// Línea que crea el temporizador [w] (la misma en los dos destinos).
  static String timer(TkWidget w) {
    final m = w.events['command'];
    return _call('self.${w.name} = DesignTimer', [
      'self.root',
      '${interval(w)}',
      m == null ? 'None' : 'self.$m',
      w.props['enabled'] == false ? 'False' : 'True',
    ]);
  }

  /// Diálogo Abrir o Guardar [w] ([web]: en una página).
  static String dialog(TkWidget w, {bool web = false}) {
    String? text(String key) {
      final v = w.text(key);
      return v.isEmpty ? null : '$key=${TkPy.str(v)}';
    }

    final open = w.kind == 'OpenDialog';
    final cls = web
        ? (open ? 'WebOpenDialog' : 'WebSaveDialog')
        : (open ? 'DesignOpenDialog' : 'DesignSaveDialog');
    return _call('self.${w.name} = $cls', [
      web ? 'self' : 'self.root',
      ?text('title'),
      ?text('filter'),
      ?text('defaultext'),
      ?text('initialdir'),
      if (open && w.props['multiple'] == true) 'multiple=True',
      if (!open) ?text('filename'),
      if (!open && w.props['overwrite'] == false) 'overwrite=False',
      if (w.events['select'] case final m?) 'select=self.$m',
    ]);
  }

  /// Asistente de IA (Claude, con el SDK oficial de Anthropic).
  static String aiAssistant(TkWidget w, {bool web = false}) {
    String? text(String key) {
      final p = w.component.prop(key)!;
      final v = '${w.prop(p) ?? ''}';
      return v == '${p.def ?? ''}' || v.isEmpty ? null : '$key=${TkPy.str(v)}';
    }

    final max = TkPy.integer(w.props['max_tokens'] ?? 16000);
    return _call('self.${w.name} = AiAssistant', [
      web ? 'self' : 'self.root',
      if (web) 'web=True',
      ?text('model'),
      ?text('system'),
      ?text('effort'),
      if (max != 16000) 'max_tokens=${max < 256 ? 256 : max}',
      if (w.events['done'] case final m?) 'done=self.$m',
      if (w.events['error'] case final m?) 'error=self.$m',
    ]);
  }

  /// Informe en PDF o en Excel (en una página web, se descarga).
  static String report(TkWidget w, {bool web = false}) {
    String? text(String key) {
      final v = w.text(key);
      return v.isEmpty ? null : '$key=${TkPy.str(v)}';
    }

    final pdf = w.kind == 'PdfReport';
    return _call('self.${w.name} = ${pdf ? 'PdfReport' : 'ExcelReport'}', [
      web ? 'self' : 'self.root',
      if (web) 'web=True',
      ?text('filename'),
      if (pdf) ...[
        ?text('title'),
        ?text('author'),
        if (w.text('orientation') == 'landscape') 'orientation="landscape"',
        if (w.props['page_numbers'] == false) 'page_numbers=False',
      ] else
        ?text('sheet'),
    ]);
  }

  /// Enlaces de los eventos con secuencia de [w] (bind).
  static void _binds(StringBuffer b, TkWidget w) {
    for (final e in w.component.events) {
      final m = w.events[e.key];
      if (m == null || e.isCommand) continue;
      for (final s in e.sequences) {
        b.writeln('$_in${'self.${w.name}'}.bind(${TkPy.str(s)}, self.$m)');
      }
    }
  }

  /// Campo de contraseña.
  static void _password(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    final max = TkPy.integer(w.props['maxlength'] ?? 0);
    final bg = _color(w.props['bg']) ?? '#ffffff';
    final fg = _color(w.props['fg']) ?? '#000000';
    final state = w.text('state');
    b
      ..writeln('$_in# ${w.name}')
      ..writeln('$_in${self}_var = tk.StringVar()')
      ..writeln(
        _call('$self = DesignPassword', [
          parentOf(d, w),
          'textvariable=${self}_var',
          if (w.props['reveal'] == false) 'reveal=False',
          if (max > 0) 'maxlength=$max',
          if (w.text('hint').isNotEmpty) 'hint=${TkPy.str(w.text('hint'))}',
          if (state != 'normal' && state.isNotEmpty) 'state=${TkPy.str(state)}',
          'bg=${TkPy.str(bg)}',
          'fg=${TkPy.str(fg)}',
          if (_font(w) case final f?) 'font=$f',
        ]),
      )
      ..writeln(
        '$_in$self.place(x=$x, y=$y, width=${w.width}, height=${w.height})',
      );
    _binds(b, w);
  }

  /// Opciones de un gráfico distintas de las de serie, como `clave=valor`
  /// de Python (las mismas en los dos destinos).
  static Map<String, String> chartOptions(TkWidget w) => {
    for (final p in w.component.props)
      if (w.prop(p) case final v? when v != p.def)
        p.key: switch (p.type) {
          TkPropType.boolean => v == true ? 'True' : 'False',
          TkPropType.integer => '${TkPy.integer(v)}',
          TkPropType.number => TkPy.number(v),
          _ => TkPy.str('$v'),
        },
  };

  /// Gráfico: un lienzo que se dibuja solo (DesignChart).
  static void _chart(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    b
      ..writeln('$_in# ${w.name}')
      ..writeln(
        _call('$self = DesignChart', [
          parentOf(d, w),
          if (w.events['point'] case final m?) 'command=self.$m',
          for (final e in chartOptions(w).entries) '${e.key}=${e.value}',
        ]),
      )
      ..writeln(
        '$_in$self.place(x=$x, y=$y, width=${w.width}, height=${w.height})',
      );
  }

  /// Vista HTML: el HTML sencillo en un texto (DesignHtml). A página
  /// completa ocupa toda la ventana.
  static void _htmlView(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    final size = w.props['font_size'];
    final full = w.props['full_page'] == true && w.parent == null;
    b
      ..writeln('$_in# ${w.name}')
      ..writeln(
        _call('$self = DesignHtml', [
          parentOf(d, w),
          if (w.text('html').isNotEmpty) 'html=${TkPy.str(w.text('html'))}',
          if (w.events['action'] case final m?) 'command=self.$m',
          'bg=${TkPy.str(color(w.props['bg']) ?? '#ffffff')}',
          if (size is int && size > 0) 'font_size=$size',
        ]),
      )
      ..writeln(
        full
            ? '$_in$self.place(x=0, y=0, relwidth=1, relheight=1)'
            : '$_in$self.place(x=$x, y=$y, width=${w.width}, height=${w.height})',
      );
  }

  /// Imagen de un archivo del proyecto.
  static void _image(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    final fit = w.text('fit');
    b
      ..writeln('$_in# ${w.name}')
      ..writeln(
        _call('$self = DesignImage', [
          parentOf(d, w),
          if (w.text('file').isNotEmpty) 'file=${TkPy.str(w.text('file'))}',
          if (fit != 'contain') 'fit=${TkPy.str(fit)}',
          'width=${w.width}',
          'height=${w.height}',
          'bg=${TkPy.str(backgroundOf(d, w))}',
          if (w.props['border'] == true) ...['bd=1', 'relief="solid"'],
        ]),
      )
      ..writeln(
        '$_in$self.place(x=$x, y=$y, width=${w.width}, height=${w.height})',
      );
    _binds(b, w);
  }

  /// Métodos de la ventana para los componentes que los tienen
  /// (`Password1_visible`, `Image1_load`): iguales en los dos destinos.
  static void helperMethods(StringBuffer b, TkDesign d) {
    for (final w in d.widgets) {
      switch (w.kind) {
        case 'Password':
          b
            ..writeln()
            ..writeln('    def ${w.name}_visible(self, on=True):')
            ..writeln('$_in"""Show (True) or hide (False) the password."""')
            ..writeln('${_in}self.${w.name}.visible(on)');
        case 'Image':
          b
            ..writeln()
            ..writeln('    def ${w.name}_load(self, path):')
            ..writeln('$_in"""Show another image (path inside the project)."""')
            ..writeln('${_in}self.${w.name}.load(path)');
      }
    }
  }

  /// Símbolos de los iconos por nombre, para cambiarlos desde el código
  /// (`self.StatusBar1.set(icon="save")`).
  static String glyphTable() {
    final b = StringBuffer()
      ..writeln()
      ..writeln()
      ..writeln('GLYPHS = {');
    for (final e in tkRibbonGlyphs.entries) {
      b.writeln('    ${TkPy.str(e.key)}: ${TkPy.str(e.value)},');
    }
    b
      ..writeln('}')
      ..writeln()
      ..writeln()
      ..writeln('def _glyph(icon):')
      ..writeln('    """A glyph name of GLYPHS, or the character itself."""')
      ..writeln('    icon = str(icon or "").strip()')
      ..writeln(
        '    return GLYPHS.get(icon.lower(), icon if len(icon) <= 2 else "")',
      );
    return b.toString();
  }

  /// Opciones de un menú como lista de Python (menú de la ventana en web y
  /// menú del icono de bandeja).
  static String menuTree(List<TkMenuItem> items) =>
      '[${[for (final i in items) i.separator ? '{"sep": True}' : '{"label": ${TkPy.str(i.label)}, "path": ${TkPy.str(i.path)}, '
                  '"items": ${menuTree(i.items)}}'].join(', ')}]';

  /// Icono de bandeja [w]: solo en escritorio.
  static String tray(TkWidget w) => _call('self.${w.name} = DesignTray', [
    'self.root',
    if (w.text('tooltip').isNotEmpty) 'tooltip=${TkPy.str(w.text('tooltip'))}',
    if (w.text('icon').isNotEmpty) 'icon=${TkPy.str(w.text('icon'))}',
    'items=${menuTree(tkMenuItems(w.text('items')))}',
    if (w.events['click'] case final m?) 'click=self.$m',
    if (w.events['command'] case final m?) 'command=self.$m',
  ]);

  /// Líneas que colocan la ventana según su propiedad Posición.
  static void place(StringBuffer b, TkDesign d) {
    switch (d.prop(tkFormPosition)) {
      case 'center':
        b
          ..writeln('${_in}self.root.update_idletasks()')
          ..writeln(
            '${_in}left = max(0, (self.root.winfo_screenwidth() - ${d.width}) // 2)',
          )
          ..writeln(
            '${_in}top = max(0, (self.root.winfo_screenheight() - ${d.height}) // 2)',
          )
          ..writeln(
            '${_in}self.root.geometry("${d.width}x${d.height}+%d+%d" % (left, top))',
          );
      case 'manual':
        final left = TkPy.integer(d.prop(tkFormLeft) ?? 0);
        final top = TkPy.integer(d.prop(tkFormTop) ?? 0);
        b.writeln(
          '${_in}self.root.geometry("${d.width}x${d.height}+$left+$top")',
        );
    }
  }

  /// Pestañas de la cinta [w] como lista de Python (la misma en los dos
  /// destinos).
  static String ribbonTabs(TkWidget w) => _pyList([
    for (final t in tkRibbonTabs(w.text('items')))
      '{"label": ${TkPy.str(t.label)}, "groups": ${_pyList([
        for (final g in t.groups) '{"label": ${TkPy.str(g.label)}, "buttons": ${_pyList([for (final b in g.buttons) '{"label": ${TkPy.str(b.label)}, "glyph": ${TkPy.str(b.glyph)}, '
                '"path": ${TkPy.str(b.path)}}'])}}',
      ])}}',
  ]);

  static String _pyList(List<String> items) => '[${items.join(', ')}]';

  /// Línea que crea la integración API [w] (la misma en los dos destinos).
  /// Los secretos no se escriben: solo el nombre de su variable de entorno,
  /// salvo que el usuario haya puesto un token literal.
  static String api(TkWidget w) {
    String? text(String key) {
      final p = w.component.prop(key)!;
      final v = '${w.prop(p) ?? ''}';
      return v == '${p.def ?? ''}' ? null : '$key=${TkPy.str(v)}';
    }

    final timeout = TkPy.integer(w.props['timeout'] ?? 30);
    return _call('self.${w.name} = ApiClient', [
      'self.root',
      ?text('base_url'),
      ?text('auth'),
      ?text('token'),
      ?text('token_env'),
      ?text('user'),
      ?text('password_env'),
      ?text('header_name'),
      ?text('headers'),
      if (timeout != 30) 'timeout=${timeout < 1 ? 1 : timeout}',
      if (w.events['done'] case final m?) 'done=self.$m',
      if (w.events['error'] case final m?) 'error=self.$m',
    ]);
  }

  /// Cinta de opciones de la ventana: pegada arriba, de lado a lado.
  static void _ribbon(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final click = w.events['command'], change = w.events['change'];
    b
      ..writeln('$_in# ${w.name}')
      ..writeln(
        _call('$self = DesignRibbon', [
          'self.root',
          ribbonTabs(w),
          'active=${d.ribbonTab(w)}',
          'height=${w.height}',
          if (click != null) 'command=self.$click',
          if (change != null) 'change=self.$change',
        ]),
      )
      ..writeln('$_in$self.place(x=0, y=0, relwidth=1.0, height=${w.height})');
  }

  /// Menú de la ventana: una opción llama al método con su ruta.
  static void _menu(StringBuffer b, TkWidget w) {
    final self = 'self.${w.name}';
    final m = w.events['command'];
    var n = 0;
    b
      ..writeln('$_in# ${w.name}')
      ..writeln('$_in$self = tk.Menu(self.root)');
    void items(String menu, List<TkMenuItem> list) {
      for (final i in list) {
        if (i.separator) {
          b.writeln('$_in$menu.add_separator()');
        } else if (i.items.isNotEmpty) {
          final sub = '${self}_m${n++}';
          b
            ..writeln('$_in$sub = tk.Menu($menu, tearoff=0)')
            ..writeln(
              _call('$menu.add_cascade', [
                'label=${TkPy.str(i.label)}',
                'menu=$sub',
              ]),
            );
          items(sub, i.items);
        } else {
          b.writeln(
            _call('$menu.add_command', [
              'label=${TkPy.str(i.label)}',
              if (m != null) 'command=lambda: self.$m(${TkPy.str(i.path)})',
            ]),
          );
        }
      }
    }

    items(self, tkMenuItems(w.text('items')));
    b.writeln('${_in}self.root.config(menu=$self)');
  }

  /// Control de páginas: un ttk.Notebook con un marco por página.
  static void _pages(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    final (x, y) = placeOf(d, w);
    final bg = TkPy.str(backgroundOf(d, w));
    b
      ..writeln('$_in# ${w.name}')
      ..writeln('$_in$self = ttk.Notebook(${parentOf(d, w)})')
      ..writeln(
        '$_in$self.place(x=$x, y=$y, width=${w.width}, height=${w.height})',
      );
    for (final (i, title) in tkPages(w).indexed) {
      b
        ..writeln('$_in${self}_page$i = tk.Frame($self, bg=$bg)')
        ..writeln('$_in$self.add(${self}_page$i, text=${TkPy.str(title)})');
    }
    final active = d.activePage(w);
    if (active > 0) b.writeln('$_in$self.select($active)');
    for (final e in w.component.events) {
      final m = w.events[e.key];
      if (m == null) continue;
      for (final s in e.sequences) {
        b.writeln('$_in$self.bind(${TkPy.str(s)}, self.$m)');
      }
    }
  }

  static void _widget(StringBuffer b, TkDesign d, TkWidget w) {
    if (w.kind == 'Menu') return _menu(b, w);
    if (w.kind == 'Ribbon') return _ribbon(b, d, w);
    if (w.kind == 'Password') return _password(b, d, w);
    if (w.kind == 'Image') return _image(b, d, w);
    if (w.kind == 'Chart') return _chart(b, d, w);
    if (w.kind == 'HtmlView') return _htmlView(b, d, w);
    if (w.kind == 'PageControl') return _pages(b, d, w);
    if (w.kind == 'RestClient') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(api(w));
      return;
    }
    if (w.kind == 'TrayIcon') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(tray(w));
      return;
    }
    if (w.kind == 'OpenDialog' || w.kind == 'SaveDialog') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(dialog(w));
      return;
    }
    if (w.kind == 'PdfReport' || w.kind == 'ExcelReport') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(report(w));
      return;
    }
    if (w.kind == 'AiAssistant') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(aiAssistant(w));
      return;
    }
    if (w.kind == 'Timer') {
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(timer(w));
      return;
    }
    if (w.kind == 'Connection') {
      final saved = w.text('connection');
      b
        ..writeln('$_in# ${w.name}')
        ..writeln(
          saved.isEmpty
              ? '${_in}self.${w.name} = ErpClient()'
              : '${_in}self.${w.name} = SqlClient(${TkPy.str(w.name)})',
        );
      return;
    }
    if (w.kind == 'Treeview') {
      _treeview(b, d, w, parentOf(d, w), _bound(d, w).isNotEmpty);
      return;
    }
    final c = w.component;
    final self = 'self.${w.name}';
    final args = [parentOf(d, w)];
    b.writeln('$_in# ${w.name}');
    for (final p in c.props) {
      if (p.option == null) continue;
      final v = _value(p, w.prop(p));
      if (v != null) args.add('${p.option}=$v');
    }
    final font = _font(w);
    if (font != null) args.add('font=$font');
    final bg = _color(w.props['bg']), fg = _color(w.props['fg']);
    if (_inherits.contains(w.kind)) {
      final own = backgroundOf(d, w);
      if (bg == null) args.add('bg=${TkPy.str(own)}');
      if (w.kind != 'Frame' && fg == null) {
        args.add('fg=${TkPy.str(contrast(own))}');
      }
    }
    // Sin esto, los campos toman los colores del tema del sistema (oscuros
    // en macOS con el modo oscuro) y no los del diseño.
    if (_fields.contains(w.kind)) {
      if (bg == null) args.add('bg="#ffffff"');
      if (fg == null) args.add('fg="#000000"');
      if (w.kind != 'Listbox') {
        args.add('insertbackground=${TkPy.str(fg ?? '#000000')}');
      }
      if (w.kind == 'Entry') {
        args.add('readonlybackground=${TkPy.str(bg ?? '#ffffff')}');
      }
    }
    // Los mismos colores que en el lienzo del Diseñador.
    if (w.kind == 'Button') {
      if (bg == null) args.add('bg="#e4e5e7"');
      if (fg == null) args.add('fg="#000000"');
      args.add('disabledforeground="#9096a0"');
    }
    // Barra de estado: una etiqueta hundida pegada abajo.
    if (w.kind == 'StatusBar') {
      final own = bg ?? '#e4e5e7';
      if (bg == null) args.add('bg=${TkPy.str(own)}');
      if (fg == null) args.add('fg=${TkPy.str(contrast(own))}');
      args.addAll(['anchor="w"', 'relief="sunken"', 'bd=1', 'padx=6']);
      final icon = tkRibbonGlyph(w.text('icon'));
      if (icon.isNotEmpty) args.add('icon=${TkPy.str(icon)}');
    }
    if (!c.ttk &&
        w.kind != 'Label' &&
        w.kind != 'Frame' &&
        w.kind != 'StatusBar') {
      args.add('highlightbackground=${TkPy.str(parentBackground(d, w))}');
    }
    // Variables: el valor de un componente se lee con self.<Nombre>_var.
    switch (w.kind) {
      case 'Entry' || 'Combobox':
        b.writeln(
          '$_in${self}_var = tk.StringVar(value=${TkPy.str(w.text('text'))})',
        );
        args.add('textvariable=${self}_var');
      case 'Checkbutton':
        final on = w.props['checked'] == true ? 1 : 0;
        b.writeln('$_in${self}_var = tk.IntVar(value=$on)');
        args.add('variable=${self}_var');
      case 'Radiobutton':
        final g = _group(w);
        final group = d.widgets.where(
          (o) => o.kind == 'Radiobutton' && _group(o) == g,
        );
        final value = w.text('value').isEmpty ? w.name : w.text('value');
        if (group.first == w) {
          final on = group.where((o) => o.props['checked'] == true).firstOrNull;
          final start = on == null
              ? ''
              : on.text('value').isEmpty
              ? on.name
              : on.text('value');
          b.writeln(
            '${_in}self.${g}_var = tk.StringVar(value=${TkPy.str(start)})',
          );
        }
        args.add('variable=self.${g}_var');
        args.add('value=${TkPy.str(value)}');
      case 'Scale':
        final v = TkPy.number(w.props['value'] ?? 0);
        b.writeln('$_in${self}_var = tk.DoubleVar(value=$v)');
        args.add('variable=${self}_var');
      case 'Canvas':
        args.add('highlightthickness=0');
    }
    if (w.kind == 'Combobox') {
      final items = _items(w);
      if (items.isNotEmpty) args.add('values=${TkPy.list(items)}');
    }
    for (final e in c.events) {
      final m = w.events[e.key];
      if (m != null && e.isCommand) args.add('command=self.$m');
    }
    final cls = c.ttk
        ? 'ttk.${w.kind}'
        : w.kind == 'Button'
        ? 'ColorButton'
        : w.kind == 'StatusBar'
        ? 'DesignStatus'
        : 'tk.${w.kind}';
    b.writeln(_call('$self = $cls', args));
    if (w.kind == 'StatusBar') {
      b.writeln(
        '$_in$self.place(relx=0, rely=1.0, anchor="sw", '
        'relwidth=1.0, height=${w.height})',
      );
    } else {
      final (x, y) = placeOf(d, w);
      b.writeln(
        '$_in$self.place(x=$x, y=$y, '
        'width=${w.width}, height=${w.height})',
      );
    }
    if (w.kind == 'Listbox') {
      final items = _items(w);
      if (items.isNotEmpty) {
        b.writeln(
          _call('$self.insert', [TkPy.str('end'), ...items.map(TkPy.str)]),
        );
      }
    }
    if (w.kind == 'Text') {
      final t = w.text('text');
      if (t.isNotEmpty) {
        b.writeln(_call('$self.insert', [TkPy.str('1.0'), TkPy.str(t)]));
      }
      if (w.text('state') == 'disabled') {
        b.writeln('$_in$self.configure(state="disabled")');
      }
    }
    for (final e in c.events) {
      final m = w.events[e.key];
      if (m == null || e.isCommand) continue;
      for (final s in e.sequences) {
        b.writeln('$_in$self.bind(${TkPy.str(s)}, self.$m)');
      }
    }
  }

  /// Métodos a los que apunta el diseño, por nombre.
  static List<String> handlers(TkDesign d) {
    final out = <String>{
      ...d.events.values,
      for (final w in d.widgets) ...w.events.values,
    }.toList();
    return out..sort();
  }

  /// Todo lo que va antes del código del usuario.
  static String _head(TkDesign d) {
    final conns = d.connections.toList();
    final erp = conns.any((c) => c.text('connection').isEmpty);
    final sql = conns.any((c) => c.text('connection').isNotEmpty);
    final grids = d.widgets.where((w) => w.kind == 'Treeview').toList();
    final data = conns.isNotEmpty || grids.isNotEmpty;
    final b = StringBuffer()
      ..writeln('#!/usr/bin/env python3')
      ..writeln('# -*- coding: utf-8 -*-')
      ..writeln('# Generated by DMarlon Studio (Interface designer).')
      ..writeln(
        '# Do not edit: change the design or the code in DMarlon Studio.',
      );
    if (erp) b.writeln('import json');
    final buttons = d.widgets.any((w) => w.kind == 'Button');
    if (data) b.writeln('import os');
    if (buttons) b.writeln('import sys');
    b.writeln('import tkinter as tk');
    if (data) b.writeln('import tkinter.messagebox');
    if (erp) {
      b
        ..writeln('import urllib.error')
        ..writeln('import urllib.request');
    }
    b.writeln('from tkinter import ttk');
    if (buttons) b.write(TkHelpers.colorButton);
    if (d.widgets.any((w) => w.kind == 'Timer')) {
      b.write(TkHelpers.designTimer);
    }
    if (d.widgets.any((w) => w.kind == 'Ribbon')) {
      b.write(TkHelpers.designRibbon);
    }
    if (d.widgets.any((w) => w.kind == 'StatusBar')) {
      b
        ..write(glyphTable())
        ..write(TkHelpers.designStatus);
    }
    if (d.widgets.any((w) => w.kind == 'TrayIcon')) {
      b.write(TkHelpers.designTray);
    }
    if (d.widgets.any((w) => w.kind == 'Password')) {
      b.write(TkHelpers.designPassword);
    }
    if (d.widgets.any(
      (w) => w.kind == 'OpenDialog' || w.kind == 'SaveDialog',
    )) {
      b.write(TkHelpers.designDialogs);
    }
    if (d.widgets.any((w) => w.kind == 'Image')) {
      b
        ..write(TkHelpers.projectFile)
        ..write(TkHelpers.designImage);
    }
    if (d.widgets.any((w) => w.kind == 'RestClient')) {
      b.write(TkHelpers.apiClient);
    }
    if (d.widgets.any(
      (w) => w.kind == 'PdfReport' || w.kind == 'ExcelReport',
    )) {
      b.write(tkReportsPython);
    }
    if (d.widgets.any((w) => w.kind == 'AiAssistant')) {
      b.write(tkAiAssistantPython);
    }
    if (d.widgets.any((w) => w.kind == 'HtmlView')) {
      b.write(tkHtmlViewPython);
    }
    if (d.widgets.any((w) => w.kind == 'Chart')) {
      b
        ..write(TkChart.core)
        ..write(TkChart.designChart);
    }
    if (data) b.write(TkHelpers.dataError);
    if (erp) b.write(TkHelpers.erpClient);
    if (sql) b.write(TkHelpers.sqlClient);
    b
      ..writeln()
      ..writeln()
      ..writeln('class FormDesign:')
      ..writeln('    """Window built from the design.')
      ..writeln()
      ..writeln('    The window and its components are created before __init__')
      ..writeln(
        '    runs, so the code of the window can define its own __init__',
      )
      ..writeln('    (with or without super().__init__()) and use them there.')
      ..writeln(
        '    The create event runs after __init__, before the window shows.',
      )
      ..writeln('    """')
      ..writeln()
      ..writeln('    def __new__(cls, *args, **kwargs):')
      ..writeln('${_in}self = super().__new__(cls)')
      ..writeln('${_in}FormDesign._setup(self)')
      ..writeln('${_in}return self')
      ..writeln()
      ..writeln('    def __init__(self, *args, **kwargs):')
      ..writeln('$_in"""Everything is ready: see _setup."""')
      ..writeln()
      ..writeln('    def _setup(self):')
      ..writeln('${_in}self._started = False')
      ..writeln('${_in}self.root = tk.Tk()')
      ..writeln('${_in}self.root.title(${TkPy.str(d.title)})')
      ..write(
        d.appIcon == null
            ? ''
            : '${_in}try:\n'
                  '$_in    self._app_icon = tk.PhotoImage(file=${TkPy.str(d.appIcon!)})\n'
                  '$_in    self.root.iconphoto(True, self._app_icon)\n'
                  '${_in}except tk.TclError:\n'
                  '$_in    pass\n',
      )
      ..writeln('${_in}self.root.geometry("${d.width}x${d.height}")');
    place(b, d);
    final resizable = d.prop(tkFormResizable) == true ? 'True' : 'False';
    b
      ..writeln('${_in}self.root.resizable($resizable, $resizable)')
      ..writeln(
        '${_in}self.root.configure(bg=${TkPy.str(_color(d.prop(tkFormBg)) ?? '#f0f0f0')})',
      )
      ..writeln('${_in}self._build()');
    for (final e in tkFormEvents) {
      final m = d.events[e.key];
      if (m == null || e.key == 'create') continue;
      if (e.key == 'close') {
        b.writeln('${_in}self.root.protocol("WM_DELETE_WINDOW", self.$m)');
      } else {
        for (final s in e.sequences) {
          b.writeln('${_in}self.root.bind(${TkPy.str(s)}, self.$m)');
        }
      }
    }
    if (d.prop(tkFormTopmost) == true) {
      b.writeln('${_in}self.root.attributes("-topmost", True)');
    }
    // Lanzada desde el estudio, tiene que salir delante; en macOS, solo con la
    // ventana ya en pantalla y por la fuerza.
    b.writeln('${_in}self.root.after(50, self.root.focus_force)');
    for (final g in grids) {
      if (_source(d, g) != null && g.props['autoload'] != false) {
        b.writeln('${_in}self.root.after(100, self.${g.name}_refresh)');
      }
    }
    // Al abrir: después del __init__ del usuario (aunque nadie llame a run).
    b.writeln('${_in}self.root.after(0, self._start)');
    b
      ..writeln()
      ..writeln('    def _build(self):');
    if (d.widgets.isEmpty) b.writeln('${_in}pass');
    for (final w in d.widgets) {
      _widget(b, d, w);
    }
    final create = d.events['create'];
    b
      ..writeln()
      ..writeln('    def _start(self):')
      ..writeln('$_in"""Once, after __init__: the create event."""')
      ..writeln('${_in}if self._started:')
      ..writeln('$_in    return')
      ..writeln('${_in}self._started = True');
    if (create != null) b.writeln('${_in}self.$create()');
    b
      ..writeln()
      ..writeln('    def run(self):')
      ..writeln('${_in}self._start()')
      ..writeln('${_in}self.root.mainloop()');
    helperMethods(b, d);
    if (grids.isNotEmpty) b.write(TkHelpers.gridFill);
    for (final g in grids) {
      _gridMethods(b, d, g);
    }
    // Métodos sin código todavía: la clase de abajo los sustituye.
    for (final m in handlers(d)) {
      b
        ..writeln()
        ..writeln('    def $m(self, *args):')
        ..writeln(
          m == d.events['close'] ? '${_in}self.root.destroy()' : '${_in}pass',
        );
    }
    b
      ..writeln()
      ..writeln();
    return b.toString();
  }

  /// Línea (desde 0) del archivo en la que empieza el código del usuario.
  static int codeLine(TkDesign d) => '\n'.allMatches(_head(d)).length;

  /// El archivo de Python de la ventana (o de la aplicación web, según su
  /// destino). Lanza [UserError] si el diseño o la clase de la ventana tienen
  /// un problema.
  static String generate(TkDesign d, String code) {
    if (d.isWeb) return TkWebCodegen.generate(d, code);
    if (d.isJs) return TkElectron.preview(d, code);
    if (d.isCpp) return TkCpp.preview(d, code);
    final problems = d.problems();
    if (problems.isNotEmpty) throw UserError(problems.join('\n'));
    final unit = code.replaceAll('\r\n', '\n').trimRight();
    if (!TkUnit.hasClass(unit, d.name)) {
      throw UserError(tkMissingClass(d.name));
    }
    return '${_head(d)}$unit\n\n\nif __name__ == "__main__":\n'
        '    ${d.name}().run()\n';
  }
}
