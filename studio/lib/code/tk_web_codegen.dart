import '../core/errors.dart';
import 'tk_codegen.dart';
import 'tk_helpers.dart';
import 'tk_model.dart';
import 'tk_web_runtime.dart';

/// Genera la aplicación web de un diseño: un solo archivo de Python con
/// Flask, con las plantillas dentro, más el código del usuario tal cual, igual
/// que [TkCodegen] genera una ventana. La clase `FormDesign` se usa igual en
/// los dos destinos, así que el código de los eventos sigue siendo Python.
///
/// Los textos del diseño van como cadenas de Python en `_build`, nunca dentro
/// de una plantilla: llegan a Jinja como datos y este los escapa. La misma
/// entrada da siempre el mismo archivo, carácter a carácter (de ahí sale su
/// huella): no lleva fechas, ni rutas, ni el idioma del usuario.
class TkWebCodegen {
  TkWebCodegen._();

  static const _in = '        ';

  static const _inherits = {
    'Label',
    'Checkbutton',
    'Radiobutton',
    'Scale',
    'Frame',
  };

  /// Propiedades que la plantilla no recibe como opción.
  static const _apart = {
    'Entry': {'text', 'data_grid', 'data_field'},
    'Combobox': {'text', 'items'},
    'Checkbutton': {'checked'},
    'Radiobutton': {'checked', 'group', 'value'},
    'Scale': {'value'},
    'Treeview': {
      'source',
      'model',
      'query',
      'columns',
      'limit',
      'order',
      'autoload',
    },
    'Listbox': {'items'},
  };

  /// [v] como literal de Python, según su tipo (null: no se escribe).
  static String? _literal(TkProp p, Object? v) {
    if ((v == p.def && !p.always) || v == null) return null;
    return switch (p.type) {
      TkPropType.text || TkPropType.multiline => TkPy.str('$v'),
      TkPropType.integer => '${TkPy.integer(v)}',
      TkPropType.number => TkPy.number(v),
      TkPropType.boolean => v == true ? 'True' : 'False',
      TkPropType.color => switch (TkCodegen.color(v)) {
        final c? => TkPy.str(c),
        _ => null,
      },
      TkPropType.choice =>
        p.choices.contains('$v') && '$v'.isNotEmpty ? TkPy.str('$v') : null,
      TkPropType.connection || TkPropType.reference => null,
    };
  }

  static String _dict(Map<String, String> m) =>
      '{${m.entries.map((e) => '${TkPy.str(e.key)}: ${e.value}').join(', ')}}';

  /// Lo que recibe la plantilla de [w].
  static Map<String, String> _options(TkDesign d, TkWidget w) {
    final out = <String, String>{};
    final apart = _apart[w.kind] ?? const <String>{};
    for (final p in w.component.props) {
      if (apart.contains(p.key)) continue;
      final v = _literal(p, w.prop(p));
      if (v != null) out[p.key] = v;
    }
    if (_inherits.contains(w.kind) && w.kind != 'Frame') {
      final fg = TkCodegen.color(w.props['fg']);
      if (fg == null) {
        out['fg'] = TkPy.str(TkCodegen.contrast(TkCodegen.backgroundOf(d, w)));
      }
    }
    if (w.kind == 'Scale') {
      // La plantilla necesita los límites aunque tengan su valor de serie.
      for (final key in const ['from', 'to', 'resolution']) {
        final p = w.component.prop(key)!;
        out[key] = TkPy.number(w.prop(p));
      }
      out['showvalue'] = w.prop(w.component.prop('showvalue')!) == false
          ? 'False'
          : 'True';
    }
    switch (w.kind) {
      case 'Listbox':
        out['items'] = TkPy.list(TkCodegen.items(w));
      case 'Combobox':
        out['values'] = TkPy.list(TkCodegen.items(w));
      case 'Radiobutton':
        out['group'] = TkPy.str(TkCodegen.group(w));
        out['value'] = TkPy.str(_radioValue(w));
      case 'Treeview':
        out['columns'] = TkPy.list([
          for (final c in TkCodegen.gridColumns(w)) c.$1,
        ]);
    }
    return out;
  }

  static String _radioValue(TkWidget w) =>
      w.text('value').isEmpty ? w.name : w.text('value');

  static void _variable(StringBuffer b, TkDesign d, TkWidget w) {
    final self = 'self.${w.name}';
    switch (w.kind) {
      case 'Entry' || 'Combobox':
        b.writeln(
          '$_in${self}_var = WebVar(self, str, ${TkPy.str(w.text('text'))})',
        );
      case 'Checkbutton':
        final on = w.props['checked'] == true ? 1 : 0;
        b.writeln('$_in${self}_var = WebVar(self, int, $on)');
      case 'Radiobutton':
        final g = TkCodegen.group(w);
        final group = d.widgets.where(
          (o) => o.kind == 'Radiobutton' && TkCodegen.group(o) == g,
        );
        if (group.first == w) {
          final on = group.where((o) => o.props['checked'] == true).firstOrNull;
          final start = on == null ? '' : _radioValue(on);
          b.writeln(
            '${_in}self.${g}_var = WebVar(self, str, ${TkPy.str(start)})',
          );
        }
      case 'Scale':
        final v = TkPy.number(w.props['value'] ?? 0);
        b.writeln('$_in${self}_var = WebVar(self, float, $v)');
    }
  }

  static String? _var(TkWidget w) => switch (w.kind) {
    'Entry' || 'Combobox' || 'Checkbutton' || 'Scale' => 'self.${w.name}_var',
    'Radiobutton' => 'self.${TkCodegen.group(w)}_var',
    _ => null,
  };

  static void _widget(StringBuffer b, TkDesign d, TkWidget w) {
    b.writeln('$_in# ${w.name}');
    if (w.kind == 'Connection') {
      final saved = w.text('connection');
      b.writeln(
        saved.isEmpty
            ? '${_in}self.${w.name} = ErpClient()'
            : '${_in}self.${w.name} = SqlClient(${TkPy.str(w.name)})',
      );
      return;
    }
    _variable(b, d, w);
    final name = TkPy.str(w.name);
    final parent = w.parent == null ? 'None' : TkPy.str(w.parent!);
    final box = '(${w.x}, ${w.y}, ${w.width}, ${w.height})';
    final args = [
      TkPy.str(w.kind),
      name,
      parent,
      box,
      _dict(_options(d, w)),
      ?_var(w),
    ];
    final one = '${_in}self.${w.name} = self._add(${args.join(', ')})';
    b.writeln(
      one.length <= 88
          ? one
          : '${_in}self.${w.name} = self._add(\n'
                '${args.map((a) => '$_in    $a,').join('\n')}\n$_in)',
    );
    if (w.kind == 'Treeview') {
      for (final (field, title, width) in TkCodegen.gridColumns(w)) {
        final f = TkPy.str(field);
        b.writeln('${_in}self.${w.name}.heading($f, text=${TkPy.str(title)})');
        if (width != null) {
          b.writeln('${_in}self.${w.name}.column($f, width=$width)');
        }
      }
      if (TkCodegen.bound(d, w).isNotEmpty) {
        b.writeln(
          '${_in}self._on($name, ${TkPy.str('select')}, self._${w.name}_bound)',
        );
      }
    }
    for (final e in w.component.events) {
      final m = w.events[e.key];
      if (m == null || !tkWebHasEvent(e)) continue;
      b.writeln('${_in}self._on($name, ${TkPy.str(e.key)}, self.$m)');
    }
  }

  /// Todo lo que va antes del código del usuario.
  static String _head(TkDesign d) {
    final conns = d.connections.toList();
    final erp = conns.any((c) => c.text('connection').isEmpty);
    final sql = conns.any((c) => c.text('connection').isNotEmpty);
    final grids = d.widgets.where((w) => w.kind == 'Treeview').toList();
    final bg = TkCodegen.color(d.prop(tkFormBg)) ?? '#f0f0f0';
    final b = StringBuffer()
      ..writeln('#!/usr/bin/env python3')
      ..writeln('# -*- coding: utf-8 -*-')
      ..writeln('# Generated by DMarlon Studio (Interface designer, web app).')
      ..writeln(
        '# Do not edit: change the design or the code in DMarlon Studio.',
      )
      ..writeln('# Needs Flask (pip install flask).')
      ..write(TkWebRuntime.imports);
    if (erp) b.writeln('import json');
    if (erp) {
      b
        ..writeln('import urllib.error')
        ..writeln('import urllib.request');
    }
    b
      ..write(TkWebRuntime.flaskImports)
      ..write(TkHelpers.dataError);
    if (erp) b.write(TkHelpers.erpClient);
    if (sql) b.write(TkHelpers.sqlClient);
    b
      ..write(TkWebRuntime.templates)
      ..write(TkWebRuntime.classes)
      ..write(TkWebRuntime.server)
      ..writeln()
      ..writeln()
      ..writeln('class FormDesign(WebForm):')
      ..writeln('    """Page built from the design."""')
      ..writeln()
      ..writeln('    def __init__(self):')
      ..writeln(
        '${_in}WebForm.__init__(self, ${TkPy.str(d.title)}, '
        '${d.width}, ${d.height}, ${TkPy.str(bg)})',
      )
      ..writeln('${_in}self._build()');
    final key = d.events['key'];
    if (key != null) {
      b.writeln('${_in}self._on("", ${TkPy.str('key')}, self.$key)');
    }
    for (final g in grids) {
      if (TkCodegen.source(d, g) != null && g.props['autoload'] != false) {
        b.writeln('${_in}self.root.after(100, self.${g.name}_refresh)');
      }
    }
    final create = d.events['create'];
    if (create != null) b.writeln('${_in}self._call(self.$create)');
    b
      ..writeln()
      ..writeln('    def _build(self):');
    if (d.widgets.isEmpty) b.writeln('${_in}pass');
    for (final w in d.widgets) {
      _widget(b, d, w);
    }
    for (final g in grids) {
      TkCodegen.gridMethods(b, d, g);
    }
    // Métodos sin código todavía: la clase de abajo los sustituye.
    for (final m in TkCodegen.handlers(d)) {
      b
        ..writeln()
        ..writeln('    def $m(self, *args):')
        ..writeln('${_in}pass');
    }
    b
      ..writeln()
      ..writeln();
    return b.toString();
  }

  /// Línea (desde 0) del archivo en la que empieza el código del usuario.
  static int codeLine(TkDesign d) => '\n'.allMatches(_head(d)).length;

  /// El archivo de la aplicación web. Lanza [UserError] si el diseño o la
  /// clase de la ventana tienen un problema.
  static String generate(TkDesign d, String code) {
    final problems = d.problems();
    if (problems.isNotEmpty) throw UserError(problems.join('\n'));
    final unit = code.replaceAll('\r\n', '\n').trimRight();
    if (!TkUnit.hasClass(unit, d.name)) {
      throw UserError(tkMissingClass(d.name));
    }
    return '${_head(d)}$unit\n\n\n'
        'app = create_app(${d.name})\n\n\n'
        'if __name__ == "__main__":\n'
        '    serve(app)\n';
  }
}
