import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_flutter.dart';
import 'tk_model.dart';
import 'tk_next.dart';

/// Web con Next.js a partir de las pantallas (el mismo editor que Flutter):
/// cada pantalla es una ruta con su componente de React, en HTML y CSS
/// adaptables (contenido centrado en escritorio; menú lateral o barra de
/// abajo según el ancho). La lógica es lib/app.js: una clase App que
/// extiende DmsApp y llama a this.notify() al cambiar.
///
/// Las propiedades se escriben igual que en Flutter: `${…}` en los textos,
/// `=expresión` (de JavaScript) y las acciones `go:Pantalla(item)`,
/// `home:Pantalla`, `back` o código, separadas por `;`.
class TkWebNext {
  TkWebNext._();

  /// La ruta de una pantalla: la primera es «/».
  static String route(FlApp app, String screen) =>
      app.screens.isNotEmpty && app.screens.first.name == screen
      ? '/'
      : '/${_kebab(screen)}';

  static String _kebab(String s) => s
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}')
      .toLowerCase();

  /// Un texto con `${…}` como literal de plantilla de JavaScript.
  static String tpl(String t) {
    final out = StringBuffer('`');
    for (var i = 0; i < t.length; i++) {
      final c = t[i];
      if (c == r'$' && i + 1 < t.length && t[i + 1] == '{') {
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
        '`' => r'\`',
        r'\' => r'\\',
        _ => c,
      });
    }
    out.write('`');
    return out.toString();
  }

  /// `{`…`}` para el JSX.
  static String _text(String t) => '{${tpl(t)}}';

  /// Una expresión, con lo más habitual de Dart pasado a JavaScript (así
  /// las mismas pantallas valen para Flutter y para la web).
  static String js(String e) => e
      .replaceAllMapped(RegExp(r'\.isNotEmpty\b'), (_) => '.length > 0')
      .replaceAllMapped(RegExp(r'\.isEmpty\b'), (_) => '.length === 0');

  static String? _expr(Object? v, String Function(String) literal) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return s.startsWith('=') ? js(s.substring(1).trim()) : literal(s);
  }

  static String? _num(Object? v) => _expr(v, (s) => '${num.tryParse(s) ?? 0}');

  static String? _bool(Object? v) =>
      v is bool ? '$v' : _expr(v, (s) => s == 'true' ? 'true' : 'false');

  /// Un color: #rrggbb, `=expresión` o un color del tema (primary…).
  static String? color(Object? v) => _expr(v, (s) {
    if (RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s)) {
      return jsonEncode(s.startsWith('#') ? s : '#$s');
    }
    final name = s.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
    return jsonEncode('var(--$name)');
  });

  static String _icon(String name) => name.startsWith('=')
      ? '{${name.substring(1).trim()}}'
      : (name.isEmpty ? 'circle' : name);

  /// Las acciones de una propiedad, como código de JavaScript.
  static String action(String a) {
    final out = <String>[];
    for (final raw in TkFlutter.splitActions(a)) {
      final s = raw.trim();
      if (s.isEmpty) continue;
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
          out.add('if ${js(s.substring(open, close + 1))} { ${action(rest)} }');
          continue;
        }
      }
      if (s == 'back') {
        out.add('router.back();');
      } else if (s.startsWith('home:')) {
        final m = RegExp(r'^home:\s*(\w+)$').firstMatch(s);
        if (m == null) throw UserError(tr('Acción no válida: {0}', [s]));
        out.add("app.home(router, '${m[1]}');");
      } else if (s.startsWith('go:')) {
        final m = RegExp(r'^go:\s*(\w+)\s*(?:\((.*)\))?$').firstMatch(s);
        if (m == null) throw UserError(tr('Acción no válida: {0}', [s]));
        final arg = (m[2] ?? '').trim();
        out.add("app.go(router, '${m[1]}'${arg.isEmpty ? '' : ', $arg'});");
      } else {
        final code = js(s.replaceAll('debugPrint(', 'console.log('));
        out.add(code.endsWith(';') ? code : '$code;');
      }
    }
    return out.join(' ');
  }

  static String _cb(String a) =>
      a.trim().isEmpty ? 'undefined' : 'async () => { ${action(a)} }';

  /// Un control dentro de algo que también se toca (una tarjeta): el clic
  /// se queda en el control, como en Flutter.
  static String _own(String a) => a.trim().isEmpty
      ? '(e) => e.stopPropagation()'
      : 'async (e) => { e.stopPropagation(); ${action(a)} }';

  /// El JSX de [n].
  static String jsx(FlNode n, {String indent = ''}) {
    final p = n.props;
    final i2 = '$indent  ';
    String kids() => [for (final c in n.children) _child(c, indent: i2)].join();
    String one() => n.children.isEmpty ? '' : jsx(n.children.first, indent: i2);
    String style(Map<String, String?> m) {
      final e = [
        for (final MapEntry(:key, :value) in m.entries)
          if (value != null) '$key: $value',
      ];
      return e.isEmpty ? '' : ' style={{ ${e.join(', ')} }}';
    }

    final tap = n.text('onTap');
    final click = tap.isEmpty ? '' : ' onClick={${_cb(tap)}}';
    final code = switch (n.type) {
      'Column' || 'Row' =>
        '<div className="${n.type == 'Column' ? 'col${n.text('cross', 'stretch') == 'stretch' ? ' st' : ''}' : 'row'}${p['wrap'] == true ? ' wrap' : ''}"'
            '${style({'gap': _num(p['gap']), 'padding': _num(p['padding']), 'justifyContent': _justify(n.text('main', 'start')), 'alignItems': _align(n.text('cross', n.type == 'Column' ? 'stretch' : 'center'))})}>\n'
            '${kids()}$indent</div>',
      'ListView' => _list(n, indent),
      'Card' =>
        '<div className="card${tap.isEmpty ? '' : ' tap'}"$click'
            '${style({'padding': _num(p['padding']) ?? '12', 'background': color(p['color'])})}>\n'
            '$i2${one()}\n$indent</div>',
      'Container' =>
        '<div className="box${tap.isEmpty ? '' : ' tap'}"$click'
            '${style({'height': _num(p['height']), 'width': _num(p['width']), 'padding': _num(p['padding']), 'background': color(p['color']), 'borderRadius': _num(p['radius'])})}>\n'
            '$i2${one()}\n$indent</div>',
      'Padding' =>
        '<div${style({'padding': _num(p['padding']) ?? '16'})}>\n$i2${one()}\n$indent</div>',
      'Center' => '<div className="center">\n$i2${one()}\n$indent</div>',
      'Expanded' =>
        '<div className="grow"${style({'flex': _num(p['flex']) ?? '1'})}>\n$i2${one()}\n$indent</div>',
      'Text' => _textNode(n, click),
      'Button' => _button(n),
      'IconButton' =>
        '<button className="icon-btn" type="button"'
            '${p['tooltip'] == null ? '' : ' title=${jsonEncode(n.text('tooltip'))} aria-label=${jsonEncode(n.text('tooltip'))}'}'
            ' onClick={${_own(n.text('onTap'))}}><span className="ms">${_icon(n.text('icon', 'add'))}</span></button>',
      'TextField' => _field(n),
      'ListTile' => _tile(n),
      'Checkbox' =>
        '<input type="checkbox" className="check" onClick={(e) => e.stopPropagation()} checked={!!(${_bool(p['value']) ?? 'false'})}'
            ' onChange={async (e) => { const v = e.target.checked; ${action(n.text('onChanged'))} }} />',
      'Switch' =>
        '<label className="switch" onClick={(e) => e.stopPropagation()}><input type="checkbox" checked={!!(${_bool(p['value']) ?? 'false'})}'
            ' onChange={async (e) => { const v = e.target.checked; ${action(n.text('onChanged'))} }} /><span /></label>',
      'Chip' =>
        '<button type="button" className={"chip" + ((${_bool(p['selected']) ?? 'false'}) ? " on" : "")}'
            '${style({'background': color(p['color'])})} onClick={${_own(tap)}}>'
            '${n.text('icon').isEmpty ? '' : '<span className="ms">${_icon(n.text('icon'))}</span>'}'
            '${_text(n.text('text', 'Etiqueta'))}</button>',
      'Icon' =>
        '<span className="ms${tap.isEmpty ? '' : ' tap'}"$click'
            '${style({'fontSize': _num(p['size']) ?? '24', 'color': color(p['color'])})}>${_icon(n.text('icon', 'star'))}</span>',
      'Image' => _image(n, click),
      'Progress' =>
        _num(p['value']) == null
            ? '<progress className="progress" />'
            : '<progress className="progress" max={1} value={${_num(p['value'])}} />',
      'Divider' => '<hr className="divider" />',
      'SizedBox' =>
        '<div${style({'height': _num(p['height']) ?? '16', 'width': _num(p['width'])})} />',
      'Spacer' => '<div className="grow" />',
      _ => throw UserError(tr('Widget desconocido: {0}', [n.type])),
    };
    return code;
  }

  static String? _justify(String v) => switch (v) {
    'center' => '"center"',
    'end' => '"flex-end"',
    'spaceBetween' => '"space-between"',
    'spaceAround' => '"space-around"',
    'spaceEvenly' => '"space-evenly"',
    _ => null,
  };

  static String? _align(String v) => switch (v) {
    'start' => '"flex-start"',
    'center' => '"center"',
    'end' => '"flex-end"',
    _ => null,
  };

  static String _child(FlNode c, {required String indent}) {
    final w = jsx(c, indent: indent);
    final vis = _bool(c.props['visible']);
    return vis == null || vis == 'true'
        ? '$indent$w\n'
        : '$indent{($vis) && (\n$indent  $w\n$indent)}\n';
  }

  static String _list(FlNode n, String indent) {
    final items = n.text('items').trim();
    final i2 = '$indent  ';
    final sep = n.props['separated'] == true ? ' sep' : '';
    final pad = _num(n.props['padding']);
    final padStyle = pad == null ? '' : ' style={{ padding: $pad }}';
    if (items.isEmpty) {
      return '<div className="list$sep"$padStyle>\n'
          '${[for (final c in n.children) _child(c, indent: i2)].join()}$indent</div>';
    }
    final expr = js(items.startsWith('=') ? items.substring(1).trim() : items);
    final name = n.text('as', 'item');
    final body = n.children.isEmpty
        ? '{String($name)}'
        : jsx(n.children.first, indent: '$i2    ');
    final empty = n.text('empty');
    return '<div className="list$sep"$padStyle>\n'
        '$i2{($expr).map(($name, i) => (\n'
        '$i2  <div className="item" key={i}>\n'
        '$i2    $body\n'
        '$i2  </div>\n'
        '$i2))}\n'
        '${empty.isEmpty ? '' : '$i2{($expr).length === 0 && <p className="empty">${_text(empty)}</p>}\n'}'
        '$indent</div>';
  }

  static String _textNode(FlNode n, String click) {
    final p = n.props;
    final st = n.text('style', 'bodyLarge');
    final tag = switch (st) {
      'displayMedium' || 'displaySmall' => 'h1',
      'headlineMedium' || 'headlineSmall' => 'h2',
      'titleLarge' => 'h3',
      'titleMedium' || 'titleSmall' => 'h4',
      'labelLarge' || 'labelSmall' => 'span',
      _ => 'p',
    };
    final strike = _bool(p['strike']);
    final s = <String, String?>{
      'color': color(p['color']),
      if (p['bold'] == true) 'fontWeight': '700',
      if (strike != null && strike != 'false')
        'textDecoration': '($strike) ? "line-through" : undefined',
      if (p['align'] != null) 'textAlign': jsonEncode(p['align']),
      if (_num(p['maxLines']) != null) 'WebkitLineClamp': _num(p['maxLines']),
    };
    final e = [
      for (final MapEntry(:key, :value) in s.entries)
        if (value != null) '$key: $value',
    ];
    return '<$tag className="t-$st${_num(p['maxLines']) == null ? '' : ' clamp'}${click.isEmpty ? '' : ' tap'}"$click'
        '${e.isEmpty ? '' : ' style={{ ${e.join(', ')} }}'}>${_text(n.text('text', 'Texto'))}</$tag>';
  }

  static String _button(FlNode n) {
    final enabled = _bool(n.props['enabled']);
    final icon = n.text('icon');
    return '<button type="button" className="btn btn-${n.text('variant', 'filled')}"'
        '${enabled == null || enabled == 'true' ? '' : ' disabled={!($enabled)}'}'
        ' onClick={${_own(n.text('onTap'))}}>'
        '${icon.isEmpty ? '' : '<span className="ms">${_icon(icon)}</span>'}'
        '${_text(n.text('text', 'Botón'))}</button>';
  }

  static String _field(FlNode n) {
    final bind = n.text('bind').trim();
    final type = n.props['obscure'] == true
        ? 'password'
        : switch (n.text('keyboard')) {
            'number' => 'number',
            'email' => 'email',
            'phone' => 'tel',
            _ => 'text',
          };
    final lines = _num(n.props['lines']);
    final multi =
        n.text('keyboard') == 'multiline' || (lines != null && lines != '1');
    final submit = n.text('onSubmit');
    final attrs = [
      if (n.text('hint').isNotEmpty) 'placeholder=${_text(n.text('hint'))}',
      if (bind.isNotEmpty) ...[
        'value={$bind ?? ""}',
        'onChange={(e) => { $bind = e.target.value; app.notify(); }}',
      ],
      if (submit.isNotEmpty && !multi)
        'onKeyDown={async (e) => { if (e.key === "Enter") { ${action(submit)} } }}',
    ].join(' ');
    final input = multi
        ? '<textarea rows={${lines ?? 4}} $attrs />'
        : '<input type="$type" $attrs />';
    return '<label className="field" onClick={(e) => e.stopPropagation()}>'
        '${n.text('label').isEmpty ? '' : '<span className="field-label">${_text(n.text('label'))}</span>'}'
        '<span className="field-box">'
        '${n.text('icon').isEmpty ? '' : '<span className="ms">${_icon(n.text('icon'))}</span>'}'
        '$input</span></label>';
  }

  static String _tile(FlNode n) {
    final p = n.props;
    final tap = n.text('onTap');
    final lead = n.text('icon');
    final c = color(p['leadingColor']);
    final trailing = n.text('trailing');
    final trailingIcon = n.text('trailingIcon');
    return '<div className="tile${tap.isEmpty ? '' : ' tap'}"${tap.isEmpty ? '' : ' onClick={${_cb(tap)}}'}>'
        '${lead.isEmpty
            ? ''
            : c == null
            ? '<span className="ms tile-icon">${_icon(lead)}</span>'
            : '<span className="avatar" style={{ background: $c }}><span className="ms">${_icon(lead)}</span></span>'}'
        '<div className="tile-text"><div className="tile-title">${_text(n.text('title', 'Título'))}</div>'
        '${n.text('subtitle').isEmpty ? '' : '<div className="tile-sub">${_text(n.text('subtitle'))}</div>'}</div>'
        '${trailing.isNotEmpty
            ? '<span className="tile-trail">${_text(trailing)}</span>'
            : trailingIcon.isNotEmpty
            ? '<span className="ms tile-trail">${_icon(trailingIcon)}</span>'
            : ''}'
        '</div>';
  }

  static String _image(FlNode n, String click) {
    final src = n.text('src').trim();
    final h = _num(n.props['height']) ?? '160';
    final r = _num(n.props['radius']) ?? '0';
    final fit = n.text('fit', 'cover');
    if (src.isEmpty) {
      return '<div className="img-ph"$click style={{ height: $h, borderRadius: $r }}><span className="ms">image</span></div>';
    }
    final s = src.startsWith('=')
        ? '{${src.substring(1).trim()}}'
        : jsonEncode(
            src.startsWith('http')
                ? src
                : '/${src.replaceFirst(RegExp(r'^/'), '')}',
          );
    return '<img className="img"$click alt="" src=$s style={{ height: $h, borderRadius: $r, objectFit: "$fit" }} />';
  }

  /// La página de una pantalla.
  static String page(FlApp app, FlScreen s, {required int depth}) {
    final up = depth == 0 ? './' : '../' * depth;
    final first = app.screens.first.name == s.name;
    final bar = [
      for (final (icon, act, badge) in s.barButtons)
        '{ icon: ${icon.startsWith('=') ? icon.substring(1) : jsonEncode(icon)}, badge: ${badge.isEmpty ? 'null' : tpl(badge)}, onClick: ${_cb(act)} }',
    ];
    final body = jsx(s.body, indent: '      ');
    return '''"use client";
// Generado por DMarlon Studio a partir de la pantalla «${s.name}». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "${up}lib/state";
import { DmsScreen, DmsMissing } from "${up}lib/dms";

export default function ${_cls(s.name)}() {
  useApp();
  const router = useRouter();
${s.arg.isEmpty ? '' : '  const arg = app.arg("${s.name}");\n  if (arg === undefined) return <DmsMissing router={router} />;\n'}  return (
    <DmsScreen
      title={${s.appBar ? tpl(s.title.isEmpty ? s.name : s.title) : 'null'}}
      back={${!first && !app.inNav(s.name)}}
      actions={[${bar.join(', ')}]}
${s.fabIcon.isEmpty ? '' : '      fab={{ icon: ${s.fabIcon.startsWith('=') ? s.fabIcon.substring(1) : jsonEncode(s.fabIcon)}, onClick: ${_cb(s.fabAction)} }}\n'}    >
      $body
    </DmsScreen>
  );
}
''';
  }

  static String _cls(String s) =>
      '${s[0].toUpperCase()}${s.substring(1).replaceAll(RegExp(r'\W'), '')}Page';

  /// lib/dms.js: la base de App, la pantalla y el menú.
  static String dms(FlApp app) =>
      '''"use client";
// DMarlon Studio: la base de la app web. Generado: no lo edite.
import { usePathname, useRouter } from "next/navigation";

/// Las rutas de las pantallas y el menú.
export const ROUTES = ${jsonEncode({for (final s in app.screens) s.name: route(app, s.name)})};
export const NAV = ${jsonEncode([
        for (final (screen, icon, label) in app.navItems) {'screen': screen, 'icon': icon, 'label': label, 'path': route(app, screen)},
      ])};

/// La base de App: notify() vuelve a dibujar las pantallas; go y home
/// cambian de pantalla.
export class DmsApp {
  _subs = new Set();
  _version = 0;
  _args = {};

  subscribe = (f) => {
    this._subs.add(f);
    return () => this._subs.delete(f);
  };

  version = () => this._version;

  notify() {
    this._version++;
    for (const f of this._subs) f();
  }

  go(router, screen, arg) {
    this._args[screen] = arg;
    router.push(ROUTES[screen]);
  }

  home(router, screen) {
    router.replace(ROUTES[screen]);
  }

  arg(screen) {
    return this._args[screen];
  }

  async start() {}
}

export function DmsScreen({ title, back, actions = [], fab, children }) {
  const router = useRouter();
  return (
    <div className="screen">
      {title !== null && (
        <header className="bar">
          {back && (
            <button type="button" className="icon-btn" aria-label="Volver" onClick={() => router.back()}>
              <span className="ms">arrow_back</span>
            </button>
          )}
          <h1 className="bar-title">{title}</h1>
          {actions.map((a, i) => (
            <button key={i} type="button" className="icon-btn" onClick={a.onClick}>
              <span className="ms">{a.icon}</span>
              {a.badge !== null && a.badge !== "0" && a.badge !== "" && <span className="badge">{a.badge}</span>}
            </button>
          ))}
        </header>
      )}
      <main className="content">{children}</main>
      {fab && (
        <button type="button" className="fab" onClick={fab.onClick}>
          <span className="ms">{fab.icon}</span>
        </button>
      )}
    </div>
  );
}

export function DmsMissing({ router }) {
  return (
    <div className="screen">
      <main className="content center col" style={{ gap: 12, padding: 32 }}>
        <span className="ms" style={{ fontSize: 48 }}>link_off</span>
        <p>Esta pantalla se abre desde la app.</p>
        <button type="button" className="btn btn-filled" onClick={() => router.replace("/")}>Ir al inicio</button>
      </main>
    </div>
  );
}

/// El menú: barra lateral en pantallas anchas y barra abajo en las estrechas.
export function DmsShell({ children }) {
  const path = usePathname();
  const router = useRouter();
  const inNav = NAV.some((n) => n.path === path);
  if (!inNav) return children;
  return (
    <div className="shell">
      <nav className="nav">
        {NAV.map((n) => (
          <button
            key={n.path}
            type="button"
            className={"nav-item" + (n.path === path ? " on" : "")}
            onClick={() => router.replace(n.path)}
          >
            <span className="ms">{n.icon}</span>
            <span>{n.label}</span>
          </button>
        ))}
      </nav>
      <div className="shell-main">{children}</div>
    </div>
  );
}
''';

  /// lib/state.js: la App de la web y el gancho que vuelve a dibujar.
  static const state = '''"use client";
// DMarlon Studio: el estado de la app. Generado: no lo edite.
import { useSyncExternalStore } from "react";
import { App } from "./app";

export const app = new App();

let started = false;

/// Las pantallas se vuelven a dibujar cuando App llama a notify().
export function useApp() {
  if (typeof window !== "undefined" && !started) {
    started = true;
    Promise.resolve(app.start()).then(() => app.notify());
  }
  useSyncExternalStore(app.subscribe, app.version, app.version);
  return app;
}
''';

  /// Una lógica de partida.
  static String template(String comment) => '''$comment
import { DmsApp } from "./dms";

/// Los datos y la lógica de la app. Las pantallas los leen como app y se
/// vuelven a dibujar al llamar a this.notify().
export class App extends DmsApp {
  counter = 0;

  /// Al abrir la web (cargar datos, por ejemplo).
  async start() {}

  increment() {
    this.counter++;
    this.notify();
  }
}
''';

  /// globals.css: el tema (del color principal) y los componentes.
  static String css(FlApp app) {
    final hex =
        RegExp(r'#?([0-9a-fA-F]{6})').firstMatch(app.primary)?[1] ?? '2B5FD9';
    final dark = app.dark;
    return '''/* Generado por DMarlon Studio. No lo edite. */
:root {
  --primary: #$hex;
  --on-primary: #fff;
  --primary-container: color-mix(in srgb, var(--primary) 16%, ${dark ? '#1b1c20' : 'white'});
  --secondary: color-mix(in srgb, var(--primary) 55%, #6b7280);
  --secondary-container: color-mix(in srgb, var(--primary) 10%, ${dark ? '#1b1c20' : '#f1f2f5'});
  --tertiary: color-mix(in srgb, var(--primary) 40%, #a855f7);
  --error: #ba1a1a;
  --surface: ${dark ? '#121316' : '#fbfbfd'};
  --surface-container: ${dark ? '#1e2024' : '#f0f1f4'};
  --surface-container-high: ${dark ? '#26282d' : '#e8e9ee'};
  --on-surface: ${dark ? '#e4e4e8' : '#1b1c20'};
  --muted: ${dark ? '#a3a6ad' : '#5b5f69'};
  --line: ${dark ? '#34363c' : '#dfe1e6'};
  --radius: 14px;
  color-scheme: ${dark ? 'dark' : 'light'};
}
* { box-sizing: border-box; }
html, body { margin: 0; background: var(--surface); color: var(--on-surface); font: 16px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
h1, h2, h3, h4, p { margin: 0; }
button { font: inherit; color: inherit; }
.ms { font-family: "Material Symbols Outlined"; font-weight: normal; font-style: normal; font-size: 24px; line-height: 1; letter-spacing: normal; text-transform: none; display: inline-block; white-space: nowrap; direction: ltr; -webkit-font-smoothing: antialiased; }
.screen { min-height: 100vh; display: flex; flex-direction: column; }
.bar { position: sticky; top: 0; z-index: 5; display: flex; align-items: center; gap: 4px; padding: 10px 16px; background: color-mix(in srgb, var(--surface) 88%, transparent); backdrop-filter: blur(10px); border-bottom: 1px solid var(--line); }
.bar-title { flex: 1; font-size: 20px; font-weight: 600; margin-left: 6px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.content { flex: 1; width: 100%; max-width: 960px; margin: 0 auto; display: flex; flex-direction: column; }
.col { display: flex; flex-direction: column; }
.col.st > .ms { align-self: center; }
.row { display: flex; flex-direction: row; align-items: center; }
.row.wrap { flex-wrap: wrap; }
.grow { flex: 1; min-width: 0; }
.center { display: flex; align-items: center; justify-content: center; flex: 1; }
.list { display: flex; flex-direction: column; }
.list.sep > .item + .item { border-top: 1px solid var(--line); }
.list > .item > .card { margin: 4px 0; }
.empty { padding: 24px; text-align: center; color: var(--muted); }
.card { background: var(--surface-container); border-radius: var(--radius); border: 1px solid var(--line); }
.box { overflow: hidden; }
.tap { cursor: pointer; }
.card.tap:hover, .tile.tap:hover { background: var(--surface-container-high); }
.t-displayMedium { font-size: 44px; line-height: 1.15; }
.t-displaySmall { font-size: 36px; line-height: 1.2; }
.t-headlineMedium { font-size: 28px; line-height: 1.25; }
.t-headlineSmall { font-size: 24px; line-height: 1.3; }
.t-titleLarge { font-size: 22px; font-weight: 500; }
.t-titleMedium, .t-titleSmall { font-size: 16px; font-weight: 600; }
.t-bodyMedium { font-size: 15px; }
.t-bodySmall { font-size: 13px; color: var(--muted); }
.t-labelLarge { font-size: 14px; font-weight: 500; }
.t-labelSmall { font-size: 12px; color: var(--muted); }
.clamp { display: -webkit-box; -webkit-box-orient: vertical; overflow: hidden; }
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 42px; padding: 0 20px; border-radius: 999px; border: 1px solid transparent; cursor: pointer; font-weight: 600; }
.btn .ms { font-size: 20px; }
.btn:disabled { opacity: .45; cursor: default; }
.btn-filled, .btn-elevated { background: var(--primary); color: var(--on-primary); }
.btn-elevated { box-shadow: 0 2px 6px rgba(0,0,0,.18); }
.btn-tonal { background: var(--primary-container); }
.btn-outlined { background: transparent; border-color: var(--line); color: var(--primary); }
.btn-text { background: transparent; color: var(--primary); }
.btn:not(:disabled):hover { filter: brightness(1.06); }
.icon-btn { position: relative; width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: 50%; background: transparent; cursor: pointer; }
.icon-btn:hover { background: var(--surface-container-high); }
.badge { position: absolute; top: 2px; right: 2px; min-width: 18px; height: 18px; padding: 0 5px; border-radius: 9px; background: var(--error); color: #fff; font-size: 11px; line-height: 18px; text-align: center; }
.field { display: flex; flex-direction: column; gap: 6px; }
.field-label { font-size: 13px; color: var(--muted); }
.field-box { display: flex; align-items: center; gap: 8px; padding: 0 12px; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); }
.field-box:focus-within { border-color: var(--primary); box-shadow: 0 0 0 3px color-mix(in srgb, var(--primary) 20%, transparent); }
.field-box .ms { color: var(--muted); font-size: 20px; }
.field input, .field textarea { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; color: inherit; font: inherit; padding: 11px 0; }
.tile { display: flex; align-items: center; gap: 14px; padding: 12px 16px; }
.tile-icon { color: var(--muted); }
.avatar { width: 40px; height: 40px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; color: #fff; flex: none; }
.avatar .ms { font-size: 22px; }
.tile-text { flex: 1; min-width: 0; }
.tile-title { font-weight: 500; }
.tile-sub { font-size: 14px; color: var(--muted); }
.tile-trail { color: var(--muted); font-size: 14px; }
.check { width: 20px; height: 20px; accent-color: var(--primary); }
.switch { position: relative; width: 46px; height: 28px; flex: none; }
.switch input { opacity: 0; width: 0; height: 0; }
.switch span { position: absolute; inset: 0; border-radius: 14px; background: var(--line); transition: .2s; cursor: pointer; }
.switch span::before { content: ""; position: absolute; width: 22px; height: 22px; left: 3px; top: 3px; border-radius: 50%; background: #fff; transition: .2s; }
.switch input:checked + span { background: var(--primary); }
.switch input:checked + span::before { transform: translateX(18px); }
.chip { display: inline-flex; align-items: center; gap: 6px; height: 34px; padding: 0 14px; border-radius: 10px; border: 1px solid var(--line); background: transparent; cursor: pointer; font-size: 14px; }
.chip .ms { font-size: 18px; }
.chip.on { background: var(--primary-container); border-color: transparent; font-weight: 600; }
.img { width: 100%; display: block; }
.img-ph { display: flex; align-items: center; justify-content: center; background: var(--secondary-container); color: var(--muted); }
.img-ph .ms { font-size: 44px; }
.progress { width: 100%; accent-color: var(--primary); }
.divider { border: 0; border-top: 1px solid var(--line); margin: 4px 0; }
.fab { position: fixed; right: 24px; bottom: 24px; width: 56px; height: 56px; border-radius: 16px; border: 0; background: var(--primary-container); box-shadow: 0 4px 14px rgba(0,0,0,.2); cursor: pointer; z-index: 6; }
.shell { display: flex; min-height: 100vh; }
.shell-main { flex: 1; min-width: 0; }
.nav { position: sticky; top: 0; height: 100vh; width: 96px; flex: none; display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 16px 0; border-right: 1px solid var(--line); background: var(--surface); }
.nav-item { display: flex; flex-direction: column; align-items: center; gap: 4px; width: 80px; padding: 6px 0; border: 0; background: transparent; cursor: pointer; font-size: 12px; font-weight: 500; }
.nav-item .ms { padding: 4px 18px; border-radius: 16px; }
.nav-item.on .ms { background: var(--primary-container); }
@media (max-width: 699px) {
  .shell { display: block; }
  .shell-main { padding-bottom: 80px; }
  .nav { position: fixed; top: auto; bottom: 0; left: 0; right: 0; height: 72px; width: auto; flex-direction: row; justify-content: space-around; padding: 6px 0; border-right: 0; border-top: 1px solid var(--line); z-index: 7; }
  .fab { bottom: 92px; }
  .content { max-width: none; }
}
''';
  }

  /// Todos los archivos del proyecto (ruta → contenido).
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
  }) {
    final app = FlApp.of(d);
    if (app.screens.isEmpty) throw UserError(tr('La app no tiene pantallas.'));
    final seen = <String>{};
    for (final s in app.screens) {
      if (!RegExp(r'^[A-Za-z]\w*$').hasMatch(s.name)) {
        throw UserError(
          tr('«{0}» no sirve como nombre de pantalla.', [s.name]),
        );
      }
      if (!seen.add(route(app, s.name))) {
        throw UserError(tr('Hay dos pantallas llamadas «{0}».', [s.name]));
      }
    }
    for (final (screen, _, _) in app.navItems) {
      if (app.screen(screen) == null) {
        throw UserError(
          tr('El menú nombra la pantalla «{0}», que no existe.', [screen]),
        );
      }
    }
    final title = app.title.isEmpty ? name : app.title;
    return {
      'package.json': TkNext.packageJson(name),
      'next.config.mjs':
          '// Generated by DMarlon Studio.\n'
          'export default { reactStrictMode: false };\n',
      'jsconfig.json': '{ "compilerOptions": { "baseUrl": "." } }\n',
      'app/globals.css': css(app),
      'app/layout.js':
          '// Generado por DMarlon Studio. No lo edite.\n'
          'import "./globals.css";\n'
          'import { DmsShell } from "../lib/dms";\n\n'
          'export const metadata = { title: ${jsonEncode(title)} };\n'
          'export const viewport = { width: "device-width", initialScale: 1 };\n\n'
          'export default function RootLayout({ children }) {\n'
          '  return (\n'
          '    <html lang="es">\n'
          '      <head>\n'
          '        <link\n'
          '          rel="stylesheet"\n'
          '          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block"\n'
          '        />\n'
          '      </head>\n'
          '      <body>\n'
          '        <DmsShell>{children}</DmsShell>\n'
          '      </body>\n'
          '    </html>\n'
          '  );\n'
          '}\n',
      for (final s in app.screens)
        if (route(app, s.name) == '/')
          'app/page.js': page(app, s, depth: 1)
        else
          'app${route(app, s.name)}/page.js': page(app, s, depth: 2),
      'lib/dms.js': dms(app),
      'lib/state.js': state,
      'lib/app.js': code.replaceAll('\r\n', '\n'),
      'README.md':
          '# $title\n\n'
          '${tr('Aplicación web de Next.js creada con DMarlon Studio.')}\n\n'
          '```\nnpm install\nnpm run dev\n```\n',
    };
  }

  /// Lo que se ve en la pestaña «JavaScript generado»: las páginas.
  static String preview(TkDesign d) {
    final app = FlApp.of(d);
    return [
      for (final s in app.screens)
        '// ---- app${route(app, s.name) == '/' ? '' : route(app, s.name)}/page.js\n${page(app, s, depth: route(app, s.name) == '/' ? 1 : 2)}',
    ].join('\n');
  }
}
