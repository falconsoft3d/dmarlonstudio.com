import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_model.dart';

/// Apps de Flutter al estilo de FlutterFlow: pantallas con un árbol de
/// widgets enlazado a la lógica del usuario (lib/app.dart, una clase App que
/// extiende ChangeNotifier).
///
/// En las propiedades:
/// - un texto puede llevar `${…}` (una plantilla de Dart: `Hola ${app.user}`);
/// - un valor que empieza por `=` es una expresión de Dart (`=item.done`);
/// - una acción es código de Dart (`app.toggle(item)`), `go:Pantalla`,
///   `go:Pantalla(item)` (con argumento) o `back`, separadas por `;`.
/// Dentro de una lista enlazada, cada elemento es `item` (o el nombre de su
/// propiedad `as`). En una pantalla con argumento, este es `arg`.

/// Un widget del árbol.
class FlNode {
  FlNode(this.type, [Map<String, Object?>? props, List<FlNode>? children])
    : props = props ?? {},
      children = children ?? [];

  String type;
  final Map<String, Object?> props;
  final List<FlNode> children;

  String text(String k, [String def = '']) {
    final v = props[k];
    return v == null ? def : '$v';
  }

  Map<String, Object?> toJson() => {
    'type': type,
    if (props.isNotEmpty) 'props': props,
    if (children.isNotEmpty) 'children': [for (final c in children) c.toJson()],
  };

  static FlNode fromJson(Map j) => FlNode(
    '${j['type'] ?? 'Column'}',
    {...?(j['props'] as Map?)?.cast<String, Object?>()},
    [for (final c in (j['children'] as List?) ?? const []) fromJson(c as Map)],
  );

  FlNode copy() => fromJson(jsonDecode(jsonEncode(toJson())) as Map);
}

/// Una pantalla: barra superior, botón flotante y su cuerpo.
class FlScreen {
  FlScreen({
    required this.name,
    this.title = '',
    this.appBar = true,
    this.arg = '',
    this.fabIcon = '',
    this.fabAction = '',
    this.bar = '',
    FlNode? body,
  }) : body = body ?? FlNode('Column');

  String name, title, arg, fabIcon, fabAction;

  /// Botones de la barra superior, uno por línea: icono|acción|insignia
  /// (la insignia, opcional, es un texto como `${app.unidades}`).
  String bar;

  List<(String, String, String)> get barButtons => [
    for (final l in bar.split('\n'))
      if (l.trim().isNotEmpty)
        () {
          final p = l.split('|');
          return (
            p[0].trim(),
            p.length > 1 ? p[1].trim() : '',
            p.length > 2 ? p.sublist(2).join('|').trim() : '',
          );
        }(),
  ];
  bool appBar;
  FlNode body;

  Map<String, Object?> toJson() => {
    'name': name,
    'title': title,
    'appBar': appBar,
    if (arg.isNotEmpty) 'arg': arg,
    if (fabIcon.isNotEmpty) 'fabIcon': fabIcon,
    if (fabAction.isNotEmpty) 'fabAction': fabAction,
    if (bar.isNotEmpty) 'bar': bar,
    'body': body.toJson(),
  };

  static FlScreen fromJson(Map j) => FlScreen(
    name: '${j['name'] ?? 'Inicio'}',
    title: '${j['title'] ?? ''}',
    appBar: j['appBar'] != false,
    arg: '${j['arg'] ?? ''}',
    fabIcon: '${j['fabIcon'] ?? ''}',
    fabAction: '${j['fabAction'] ?? ''}',
    bar: '${j['bar'] ?? ''}',
    body: j['body'] is Map ? FlNode.fromJson(j['body'] as Map) : null,
  );
}

/// La app: título, color, tema y pantallas (la primera es la de inicio).
class FlApp {
  FlApp({
    this.title = 'Mi app',
    this.primary = '#2B5FD9',
    this.dark = false,
    List<FlScreen>? screens,
    List<String>? packages,
  }) : screens = screens ?? [FlScreen(name: 'Inicio', title: 'Mi app')],
       packages = packages ?? [];

  String title, primary;
  bool dark;
  final List<FlScreen> screens;

  /// Paquetes de pub.dev que usa lib/app.dart (por ejemplo,
  /// shared_preferences).
  final List<String> packages;

  FlScreen? screen(String name) =>
      screens.where((s) => s.name == name).firstOrNull;

  Map<String, Object?> toJson() => {
    'title': title,
    'primary': primary,
    'dark': dark,
    'screens': [for (final s in screens) s.toJson()],
    if (packages.isNotEmpty) 'packages': packages,
  };

  static FlApp fromJson(Map j) => FlApp(
    title: '${j['title'] ?? 'Mi app'}',
    primary: '${j['primary'] ?? '#2B5FD9'}',
    dark: j['dark'] == true,
    screens: [
      for (final s in (j['screens'] as List?) ?? const [])
        FlScreen.fromJson(s as Map),
    ],
    packages: [for (final p in (j['packages'] as List?) ?? const []) '$p'],
  );

  /// La app del diseño [d] (guardada en sus propiedades).
  static FlApp of(TkDesign d) {
    final j = d.props['flutter'];
    final app = j is Map ? fromJson(j) : FlApp(title: d.title);
    if (app.screens.isEmpty) app.screens.add(FlScreen(name: 'Inicio'));
    return app;
  }

  void saveTo(TkDesign d) => d.props['flutter'] = toJson();
}

/// Los widgets de la paleta: tipo → (nombre, contenedor de cuántos hijos:
/// 0 ninguno, 1 uno, 2 varios).
final flWidgets = <String, (String, int)>{
  'Column': (markTr('Columna'), 2),
  'Row': (markTr('Fila'), 2),
  'ListView': (markTr('Lista'), 2),
  'Card': (markTr('Tarjeta'), 1),
  'Container': (markTr('Contenedor'), 1),
  'Padding': (markTr('Margen'), 1),
  'Center': (markTr('Centrado'), 1),
  'Expanded': (markTr('Expandido'), 1),
  'Text': (markTr('Texto'), 0),
  'Button': (markTr('Botón'), 0),
  'IconButton': (markTr('Botón de icono'), 0),
  'TextField': (markTr('Campo de texto'), 0),
  'ListTile': (markTr('Fila de lista'), 0),
  'Checkbox': (markTr('Casilla'), 0),
  'Switch': (markTr('Interruptor'), 0),
  'Chip': (markTr('Etiqueta'), 0),
  'Icon': (markTr('Icono'), 0),
  'Image': (markTr('Imagen'), 0),
  'Progress': (markTr('Progreso'), 0),
  'Divider': (markTr('Separador'), 0),
  'SizedBox': (markTr('Espacio'), 0),
  'Spacer': (markTr('Relleno'), 0),
};

/// Genera el proyecto de Flutter: lib/main.dart a partir de las pantallas
/// y lib/app.dart, el código del usuario, tal cual.
class TkFlutter {
  TkFlutter._();

  /// Una cadena de Dart con la plantilla [t] (respeta `${…}`).
  static String str(String t) {
    final out = StringBuffer("'");
    for (var i = 0; i < t.length; i++) {
      final c = t[i];
      if (c == r'$' && i + 1 < t.length && t[i + 1] == '{') {
        // La expresión, hasta su llave.
        var depth = 0;
        var k = i + 1;
        for (; k < t.length; k++) {
          if (t[k] == '{') depth++;
          if (t[k] == '}' && --depth == 0) break;
        }
        out.write(t.substring(i, k + 1));
        i = k;
        continue;
      }
      out.write(switch (c) {
        "'" => r"\'",
        r'\' => r'\\',
        r'$' => r'\$',
        '\n' => r'\n',
        _ => c,
      });
    }
    out.write("'");
    return out.toString();
  }

  /// Un valor: con `=`, la expresión; si no, [literal].
  static String? _expr(Object? v, String Function(String) literal) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return s.startsWith('=') ? s.substring(1).trim() : literal(s);
  }

  /// Un color: #rrggbb, `=expresión` o el nombre de un color del tema
  /// (primary, secondary, error, surface…).
  static String? color(Object? v) => _expr(v, (s) {
    final hex = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(s);
    if (hex != null) return 'const Color(0xFF${hex[1]!.toUpperCase()})';
    return 'Theme.of(context).colorScheme.$s';
  });

  static String? _num(Object? v) => _expr(v, (s) => '${num.tryParse(s) ?? 0}');

  static String? _bool(Object? v) =>
      v is bool ? '$v' : _expr(v, (s) => s == 'true' ? 'true' : 'false');

  static String _icon(String name) => name.startsWith('=')
      ? name.substring(1).trim()
      : 'Icons.${name.isEmpty ? 'circle' : name}';

  /// El código de una acción (sin llaves).
  static String action(String a, {String context = 'context'}) {
    final out = <String>[];
    for (final raw in _split(a)) {
      final s = raw.trim();
      if (s.isEmpty) continue;
      // if (condición) acción: la acción solo si se cumple.
      if (RegExp(r'^if\s*\(').hasMatch(s)) {
        final open = s.indexOf('(');
        var depth = 0, close = -1;
        for (var i = open; i < s.length; i++) {
          if (s[i] == '(') depth++;
          if (s[i] == ')' && --depth == 0) {
            close = i;
            break;
          }
        }
        final rest = close < 0 ? '' : s.substring(close + 1).trim();
        if (rest.isNotEmpty && !rest.startsWith('{')) {
          out.add(
            'if ${s.substring(open, close + 1)} { ${action(rest, context: context)} }',
          );
          continue;
        }
      }
      if (s.startsWith('home:')) {
        final m = RegExp(r'^home:\s*(\w+)$').firstMatch(s);
        if (m == null) throw UserError(tr('Acción no válida: {0}', [s]));
        out.add(
          "Navigator.of($context).pushNamedAndRemoveUntil('/${m[1]}', (r) => false);",
        );
      } else if (s == 'back') {
        out.add('Navigator.of($context).maybePop();');
      } else if (s.startsWith('go:')) {
        final m = RegExp(r'^go:\s*(\w+)\s*(?:\((.*)\))?$').firstMatch(s);
        if (m == null) throw UserError(tr('Acción no válida: {0}', [s]));
        final arg = (m[2] ?? '').trim();
        out.add(
          "Navigator.of($context).pushNamed('/${m[1]}'"
          "${arg.isEmpty ? '' : ', arguments: $arg'});",
        );
      } else {
        out.add(s.endsWith(';') ? s : '$s;');
      }
    }
    return out.join(' ');
  }

  /// Las acciones separadas por `;` (sin partir paréntesis ni cadenas).
  static List<String> _split(String a) {
    final out = <String>[];
    var depth = 0;
    String? quote;
    var start = 0;
    for (var i = 0; i < a.length; i++) {
      final c = a[i];
      if (quote != null) {
        if (c == quote) quote = null;
        continue;
      }
      if (c == "'" || c == '"') quote = c;
      if (c == '(' || c == '{' || c == '[') depth++;
      if (c == ')' || c == '}' || c == ']') depth--;
      if (c == ';' && depth == 0) {
        out.add(a.substring(start, i));
        start = i + 1;
      }
    }
    out.add(a.substring(start));
    return out;
  }

  static String _cb(String a) =>
      a.trim().isEmpty ? 'null' : '() { ${action(a)} }';

  /// El código de [n]. [inFlex]: su padre es una fila o una columna.
  static String widget(
    FlNode n,
    FlGen g, {
    bool inFlex = false,
    String indent = '',
  }) {
    final p = n.props;
    final i2 = '$indent  ';
    String kids({bool flex = false}) => [
      for (final c in n.children) _child(c, g, flex: flex, indent: i2),
    ].join();
    String one() => n.children.isEmpty
        ? 'const SizedBox.shrink()'
        : widget(n.children.first, g, indent: i2);
    String pad(String w) {
      final v = _num(p['padding']);
      return v == null ? w : 'Padding(padding: EdgeInsets.all($v), child: $w)';
    }

    final code = switch (n.type) {
      'Row' when p['wrap'] == true => pad(
        'Wrap(spacing: ${_num(p['gap']) ?? 8}, runSpacing: ${_num(p['gap']) ?? 8}, '
        'crossAxisAlignment: WrapCrossAlignment.center, children: [\n${kids()}$i2])',
      ),
      'Column' || 'Row' => pad(
        '${n.type}(\n'
        '${i2}mainAxisAlignment: MainAxisAlignment.${n.text('main', 'start')},\n'
        '${i2}crossAxisAlignment: CrossAxisAlignment.${n.text('cross', n.type == 'Column' ? 'stretch' : 'center')},\n'
        '${_num(p['gap']) == null ? '' : '${i2}spacing: ${_num(p['gap'])},\n'}'
        '${i2}children: [\n${kids(flex: true)}$i2],\n$indent)',
      ),
      'ListView' => _list(n, g, indent),
      'Card' =>
        'Card(${color(p['color']) == null ? '' : 'color: ${color(p['color'])}, '}'
            'child: Padding(padding: EdgeInsets.all(${_num(p['padding']) ?? 12}), child: ${one()}))',
      'Container' =>
        'Container(${_num(p['height']) == null ? '' : 'height: ${_num(p['height'])}, '}'
            '${_num(p['width']) == null ? '' : 'width: ${_num(p['width'])}, '}'
            'padding: EdgeInsets.all(${_num(p['padding']) ?? 0}), '
            'decoration: BoxDecoration(${color(p['color']) == null ? '' : 'color: ${color(p['color'])}, '}'
            'borderRadius: BorderRadius.circular(${_num(p['radius']) ?? 0})), child: ${one()})',
      'Padding' =>
        'Padding(padding: EdgeInsets.all(${_num(p['padding']) ?? 16}), child: ${one()})',
      'Center' => 'Center(child: ${one()})',
      'Expanded' => 'Expanded(flex: ${_num(p['flex']) ?? 1}, child: ${one()})',
      'Text' => _text(n),
      'Button' => _button(n),
      'IconButton' =>
        'IconButton(icon: Icon(${_icon(n.text('icon', 'add'))}), '
            '${p['tooltip'] == null ? '' : 'tooltip: ${str(n.text('tooltip'))}, '}'
            'onPressed: ${_cb(n.text('onTap'))})',
      'TextField' => _field(n, g),
      'ListTile' => _tile(n),
      'Checkbox' =>
        'Checkbox(value: ${_bool(p['value']) ?? 'false'}, onChanged: (v) { ${action(n.text('onChanged'))} })',
      'Switch' =>
        'Switch(value: ${_bool(p['value']) ?? 'false'}, onChanged: (v) { ${action(n.text('onChanged'))} })',
      'Chip' when p['selected'] != null =>
        'ChoiceChip(label: Text(${str(n.text('text', 'Etiqueta'))}), '
            'selected: ${_bool(p['selected'])}, '
            'onSelected: (_) { ${action(n.text('onTap'))} })',
      'Chip' =>
        'Chip(label: Text(${str(n.text('text', 'Etiqueta'))}), '
            '${n.text('icon').isEmpty ? '' : 'avatar: Icon(${_icon(n.text('icon'))}, size: 18), '}'
            '${color(p['color']) == null ? '' : 'backgroundColor: ${color(p['color'])}, '}'
            'visualDensity: VisualDensity.compact)',
      'Icon' =>
        'Icon(${_icon(n.text('icon', 'star'))}, size: ${_num(p['size']) ?? 24}'
            '${color(p['color']) == null ? '' : ', color: ${color(p['color'])}'})',
      'Image' => _image(n),
      'Progress' =>
        'LinearProgressIndicator(${_num(p['value']) == null ? '' : 'value: ${_num(p['value'])}'})',
      'Divider' => 'const Divider()',
      'SizedBox' =>
        'SizedBox(height: ${_num(p['height']) ?? 16}, width: ${_num(p['width']) ?? 0})',
      'Spacer' => 'const Spacer()',
      _ => throw UserError(tr('Widget desconocido: {0}', [n.type])),
    };
    // Una lista dentro de una fila o columna ocupa lo que queda.
    final sized = inFlex && n.type == 'ListView'
        ? 'Expanded(child: $code)'
        : code;
    final tap = n.text('onTap');
    final tappable =
        tap.isNotEmpty &&
            const {
              'Card',
              'Container',
              'Image',
              'Icon',
              'Text',
            }.contains(n.type)
        ? 'InkWell(onTap: ${_cb(tap)}, child: $sized)'
        : sized;
    return tappable;
  }

  /// Un hijo de una lista de hijos, con su condición de visibilidad.
  static String _child(
    FlNode c,
    FlGen g, {
    required bool flex,
    required String indent,
  }) {
    final w = widget(c, g, inFlex: flex, indent: indent);
    final vis = _bool(c.props['visible']);
    return vis == null || vis == 'true'
        ? '$indent$w,\n'
        : '${indent}if ($vis) $w,\n';
  }

  static String _list(FlNode n, FlGen g, String indent) {
    final items = n.text('items').trim();
    final i2 = '$indent  ';
    final pad = _num(n.props['padding']) ?? 0;
    final sep = n.props['separated'] == true;
    if (items.isEmpty) {
      return 'ListView(padding: EdgeInsets.all($pad), children: [\n'
          '${[for (final c in n.children) _child(c, g, flex: false, indent: i2)].join()}$indent])';
    }
    final expr = items.startsWith('=') ? items.substring(1).trim() : items;
    final name = n.text('as', 'item');
    final tpl = n.children.isEmpty
        ? 'Text(\'\$$name\')'
        : widget(n.children.first, g, indent: '$i2  ');
    final empty = n.text('empty');
    final list =
        'ListView.${sep ? 'separated' : 'builder'}(\n'
        '${i2}padding: EdgeInsets.all($pad),\n'
        '${i2}itemCount: ($expr).length,\n'
        '${sep ? '${i2}separatorBuilder: (context, i) => const Divider(height: 1),\n' : ''}'
        '${i2}itemBuilder: (context, i) {\n'
        '$i2  final $name = ($expr)[i];\n'
        '$i2  return $tpl;\n'
        '$i2},\n$indent)';
    return empty.isEmpty
        ? list
        : '($expr).isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), '
              'child: Text(${str(empty)}, textAlign: TextAlign.center))) : $list';
  }

  static String _text(FlNode n) {
    final p = n.props;
    final style = n.text('style', 'bodyLarge');
    final extra = [
      if (color(p['color']) != null) 'color: ${color(p['color'])}',
      if (p['bold'] == true) 'fontWeight: FontWeight.bold',
      if (_bool(p['strike']) case final s? when s != 'false')
        'decoration: $s ? TextDecoration.lineThrough : null',
    ];
    return 'Text(${str(n.text('text', 'Texto'))}, '
        'style: Theme.of(context).textTheme.$style'
        '${extra.isEmpty ? '' : '?.copyWith(${extra.join(', ')})'}'
        '${p['align'] == null ? '' : ', textAlign: TextAlign.${p['align']}'}'
        '${_num(p['maxLines']) == null ? '' : ', maxLines: ${_num(p['maxLines'])}, overflow: TextOverflow.ellipsis'})';
  }

  static String _button(FlNode n) {
    final kind = switch (n.text('variant', 'filled')) {
      'outlined' => 'OutlinedButton',
      'text' => 'TextButton',
      'tonal' => 'FilledButton.tonal',
      'elevated' => 'ElevatedButton',
      _ => 'FilledButton',
    };
    final icon = n.text('icon');
    final label = 'Text(${str(n.text('text', 'Botón'))})';
    final enabled = _bool(n.props['enabled']);
    final cb = _cb(n.text('onTap'));
    final on = enabled == null || enabled == 'true'
        ? cb
        : '($enabled) ? $cb : null';
    final kindIcon = kind == 'FilledButton.tonal'
        ? 'FilledButton.tonalIcon'
        : '$kind.icon';
    return icon.isEmpty
        ? '$kind(onPressed: $on, child: $label)'
        : '$kindIcon(onPressed: $on, icon: Icon(${_icon(icon)}), label: $label)';
  }

  static String _field(FlNode n, FlGen g) {
    final bind = n.text('bind').trim();
    final ctl = bind.isEmpty ? null : g.controller(bind);
    final keyboard = switch (n.text('keyboard')) {
      'number' => 'TextInputType.number',
      'email' => 'TextInputType.emailAddress',
      'phone' => 'TextInputType.phone',
      'multiline' => 'TextInputType.multiline',
      _ => 'TextInputType.text',
    };
    final submit = n.text('onSubmit');
    return 'TextField('
        '${ctl == null ? '' : 'controller: $ctl, onChanged: (v) => setState(() => $bind = v), '}'
        'keyboardType: $keyboard, '
        '${n.props['obscure'] == true ? 'obscureText: true, ' : ''}'
        '${_num(n.props['lines']) == null ? '' : 'maxLines: ${_num(n.props['lines'])}, '}'
        '${submit.isEmpty ? '' : 'onSubmitted: (v) { ${action(submit)} }, '}'
        'decoration: InputDecoration('
        '${n.text('label').isEmpty ? '' : 'labelText: ${str(n.text('label'))}, '}'
        '${n.text('hint').isEmpty ? '' : 'hintText: ${str(n.text('hint'))}, '}'
        '${n.text('icon').isEmpty ? '' : 'prefixIcon: Icon(${_icon(n.text('icon'))}), '}'
        'border: const OutlineInputBorder()))';
  }

  static String _tile(FlNode n) {
    final p = n.props;
    final trailing = n.text('trailing');
    final trailingIcon = n.text('trailingIcon');
    final leadingColor = color(p['leadingColor']);
    return 'ListTile('
        '${n.text('icon').isEmpty ? '' : 'leading: ${leadingColor == null ? 'Icon(${_icon(n.text('icon'))})' : 'CircleAvatar(backgroundColor: $leadingColor, foregroundColor: Colors.white, child: Icon(${_icon(n.text('icon'))}))'}, '}'
        'title: Text(${str(n.text('title', 'Título'))}), '
        '${n.text('subtitle').isEmpty ? '' : 'subtitle: Text(${str(n.text('subtitle'))}), '}'
        '${trailing.isNotEmpty
            ? 'trailing: Text(${str(trailing)}), '
            : trailingIcon.isNotEmpty
            ? 'trailing: Icon(${_icon(trailingIcon)}), '
            : ''}'
        'onTap: ${_cb(n.text('onTap'))})';
  }

  static String _image(FlNode n) {
    final src = n.text('src').trim();
    final h = _num(n.props['height']) ?? 160;
    final fit = n.text('fit', 'cover');
    final img = src.startsWith('=')
        ? 'Image.network(${src.substring(1)}, height: $h, fit: BoxFit.$fit)'
        : src.startsWith('http')
        ? 'Image.network(${str(src)}, height: $h, fit: BoxFit.$fit)'
        : src.isEmpty
        ? 'SizedBox(height: $h, child: const Placeholder())'
        : 'Image.asset(${str(src)}, height: $h, fit: BoxFit.$fit)';
    final r = _num(n.props['radius']);
    return r == null
        ? img
        : 'ClipRRect(borderRadius: BorderRadius.circular($r), child: $img)';
  }

  /// lib/main.dart.
  static String main(FlApp app) {
    if (app.screens.isEmpty) throw UserError(tr('La app no tiene pantallas.'));
    final names = <String>{};
    for (final s in app.screens) {
      if (!RegExp(r'^[A-Za-z]\w*$').hasMatch(s.name)) {
        throw UserError(
          tr('«{0}» no sirve como nombre de pantalla.', [s.name]),
        );
      }
      if (!names.add(s.name)) {
        throw UserError(tr('Hay dos pantallas llamadas «{0}».', [s.name]));
      }
    }
    final screens = StringBuffer();
    for (final s in app.screens) {
      final g = FlGen();
      final body = widget(s.body, g, indent: '        ');
      final argLine = s.arg.isEmpty
          ? ''
          : '    final arg = ModalRoute.of(context)!.settings.arguments as ${s.arg};\n';
      screens.writeln('''
class ${_cls(s.name)} extends StatefulWidget {
  const ${_cls(s.name)}({super.key});

  @override
  State<${_cls(s.name)}> createState() => _${_cls(s.name)}State();
}

class _${_cls(s.name)}State extends State<${_cls(s.name)}> {
${g.fields()}
  @override
  Widget build(BuildContext context) {
$argLine${g.syncs()}    return Scaffold(
${s.appBar ? '      appBar: AppBar(title: Text(${str(s.title.isEmpty ? s.name : s.title)})${_barActions(s)}),\n' : ''}      body: SafeArea(
        child: $body,
      ),
${s.fabIcon.isEmpty ? '' : '      floatingActionButton: FloatingActionButton(onPressed: ${_cb(s.fabAction)}, child: Icon(${_icon(s.fabIcon)})),\n'}    );
  }
}''');
    }
    final hex =
        RegExp(r'#?([0-9a-fA-F]{6})').firstMatch(app.primary)?[1] ?? '2B5FD9';
    return '''// Generado por DMarlon Studio a partir de las pantallas. No lo edite.
// ignore_for_file: unused_local_variable, prefer_const_constructors, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'package:flutter/material.dart';

import 'app.dart';

/// La lógica de la app (lib/app.dart): la misma en todas las pantallas.
final app = App();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  app.start();
  runApp(const DmsApp());
}

class DmsApp extends StatelessWidget {
  const DmsApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) => MaterialApp(
      title: ${str(app.title)},
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF${hex.toUpperCase()}),
        brightness: Brightness.${app.dark ? 'dark' : 'light'},
      ),
      initialRoute: '/${app.screens.first.name}',
      routes: {
${[for (final s in app.screens) "        '/${s.name}': (context) => const ${_cls(s.name)}(),"].join('\n')}
      },
    ),
  );
}

$screens''';
  }

  /// Los botones de la barra superior (con su insignia).
  static String _barActions(FlScreen s) {
    final b = s.barButtons;
    if (b.isEmpty) return '';
    return ', actions: [${[for (final (icon, act, badge) in b) 'IconButton(onPressed: ${_cb(act)}, icon: ${badge.isEmpty ? 'Icon(${_icon(icon)})' : "Badge(isLabelVisible: ${str(badge)} != '0' && ${str(badge)}.isNotEmpty, label: Text(${str(badge)}), child: Icon(${_icon(icon)}))"})'].join(', ')}]';
  }

  static String _cls(String screen) =>
      '${screen[0].toUpperCase()}${screen.substring(1)}Screen';

  /// Un proyecto nuevo: la lógica de partida.
  static String template(String comment) => '''$comment
import 'package:flutter/material.dart';

/// Los datos y la lógica de la app. Las pantallas los leen como `app` y
/// se vuelven a dibujar al llamar a notifyListeners().
class App extends ChangeNotifier {
  int counter = 0;

  /// Al arrancar la app (cargar datos guardados, por ejemplo).
  Future<void> start() async {}

  void increment() {
    counter++;
    notifyListeners();
  }
}
''';

  /// Las pantallas de un proyecto nuevo.
  static FlApp starter(String title) => FlApp(
    title: title,
    screens: [
      FlScreen(
        name: 'Inicio',
        title: title,
        fabIcon: 'add',
        fabAction: 'app.increment()',
        body: FlNode('Center', {}, [
          FlNode(
            'Column',
            {'main': 'center', 'cross': 'center', 'gap': 8},
            [
              FlNode('Text', {'text': 'Ha pulsado el botón:'}),
              FlNode('Text', {
                'text': r'${app.counter}',
                'style': 'displayMedium',
                'color': 'primary',
              }),
            ],
          ),
        ]),
      ),
    ],
  );

  /// Todos los archivos del proyecto de Flutter (sin las carpetas de cada
  /// plataforma, que crea `flutter create`).
  static Map<String, String> files(TkDesign d, String code, {String? name}) {
    final app = FlApp.of(d);
    final pkg = (name ?? 'dms_app')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return {
      'pubspec.yaml': pubspec(
        pkg.isEmpty || RegExp(r'^\d').hasMatch(pkg) ? 'app_$pkg' : pkg,
        app,
      ),
      'lib/main.dart': main(app),
      'lib/app.dart': code.replaceAll('\r\n', '\n'),
      'analysis_options.yaml': 'include: package:flutter_lints/flutter.yaml\n',
    };
  }

  static String pubspec(String pkg, FlApp app) =>
      '''name: $pkg
description: ${jsonEncode(app.title)}
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
${[for (final p in app.packages) '  $p'].join('\n')}

dev_dependencies:
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
''';

  /// Lo que se ve en la pestaña «Dart generado».
  static String preview(TkDesign d) => main(FlApp.of(d));
}

/// Lo que necesita una pantalla: un controlador por cada campo de texto
/// enlazado, que sigue al valor de App.
class FlGen {
  final _binds = <String, String>{};

  String controller(String bind) =>
      _binds.putIfAbsent(bind, () => '_text${_binds.length}');

  /// Los campos de la pantalla y su ciclo de vida: escucha a App para
  /// volver a dibujarse cuando cambia (notifyListeners).
  String fields() => [
    for (final c in _binds.values) '  final $c = TextEditingController();',
    '',
    '  @override',
    '  void initState() {',
    '    super.initState();',
    '    app.addListener(_refresh);',
    '  }',
    '',
    '  void _refresh() {',
    '    if (mounted) setState(() {});',
    '  }',
    '',
    '  @override',
    '  void dispose() {',
    '    app.removeListener(_refresh);',
    for (final c in _binds.values) '    $c.dispose();',
    '    super.dispose();',
    '  }',
  ].join('\n');

  /// En cada dibujo, los campos muestran el valor de App (si lo cambió la
  /// lógica, por ejemplo al vaciarlo tras guardar).
  String syncs() => [
    for (final MapEntry(key: bind, value: c) in _binds.entries)
      "    if ($c.text != '\${$bind}') $c.text = '\${$bind}';\n",
  ].join();
}
