import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_flutter.dart';
import 'tk_model.dart';
import 'tk_web_next.dart';

/// Web en HTML, CSS y JavaScript sin nada más (sin compilar ni dependencias)
/// a partir de las pantallas: el mismo editor y el mismo CSS que la web de
/// Next.js. Un motor pequeño (dms.js) dibuja la pantalla de la ruta (tras
/// `#`) y la vuelve a dibujar cuando App llama a notify(). La lógica es
/// app.js, la misma clase App (las líneas import y export se ignoran).
class TkWebHtml {
  TkWebHtml._();

  static String _esc(String t) => '\${esc(${TkWebNext.tpl(t)})}';

  static String? _expr(Object? v, String Function(String) literal) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return s.startsWith('=') ? TkWebNext.js(s.substring(1).trim()) : literal(s);
  }

  static String? _num(Object? v) => _expr(v, (s) => '${num.tryParse(s) ?? 0}');

  static String? _bool(Object? v) =>
      v is bool ? '$v' : _expr(v, (s) => s == 'true' ? 'true' : 'false');

  static String? _color(Object? v) => _expr(v, (s) {
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
      ? '\${esc(${TkWebNext.js(name.substring(1).trim())})}'
      : (name.isEmpty ? 'circle' : name);

  /// Un estilo en línea: propiedad CSS → expresión de JavaScript (null: no
  /// va). Los números van en px.
  static String _style(Map<String, String?> m) {
    final e = [
      for (final MapEntry(:key, :value) in m.entries)
        if (value != null && value.trim() != 'null')
          '$key:\${css(${value.trim()})}',
    ];
    return e.isEmpty ? '' : ' style="${e.join(';')}"';
  }

  /// Un manejador: `data-on="…"` con el código de la acción.
  static String _on(String event, String a, {String args = ''}) =>
      a.trim().isEmpty && event != 'click-stop'
      ? ''
      : ' data-$event="\${ui.on(async ($args) => { ${TkWebNext.action(a)} })}"';

  static String _justify(String v) => switch (v) {
    'center' => '"center"',
    'end' => '"flex-end"',
    'spaceBetween' => '"space-between"',
    'spaceAround' => '"space-around"',
    'spaceEvenly' => '"space-evenly"',
    _ => 'null',
  };

  static String _align(String v) => switch (v) {
    'start' => '"flex-start"',
    'center' => '"center"',
    'end' => '"flex-end"',
    _ => 'null',
  };

  /// El HTML de [n] (dentro de un literal de plantilla de JavaScript).
  static String html(FlNode n, String key) {
    final p = n.props;
    String kids() =>
        [for (final (i, c) in n.children.indexed) _child(c, '$key.$i')].join();
    String one() => n.children.isEmpty ? '' : html(n.children.first, '$key.0');
    final tap = n.text('onTap');
    final click = _on('click', tap);
    return switch (n.type) {
      'Column' || 'Row' =>
        '<div class="${n.type == 'Column' ? 'col${n.text('cross', 'stretch') == 'stretch' ? ' st' : ''}' : 'row'}${p['wrap'] == true ? ' wrap' : ''}"'
            '${_style({'gap': _num(p['gap']), 'padding': _num(p['padding']), 'justify-content': _justify(n.text('main', 'start')), 'align-items': _align(n.text('cross', n.type == 'Column' ? 'stretch' : 'center'))})}>'
            '${kids()}</div>',
      'ListView' => _list(n, key),
      'Card' =>
        '<div class="card${tap.isEmpty ? '' : ' tap'}"$click${_style({'padding': _num(p['padding']) ?? '12', 'background': _color(p['color'])})}>${one()}</div>',
      'Container' =>
        '<div class="box${tap.isEmpty ? '' : ' tap'}"$click${_style({'height': _num(p['height']), 'width': _num(p['width']), 'padding': _num(p['padding']), 'background': _color(p['color']), 'border-radius': _num(p['radius'])})}>${one()}</div>',
      'Padding' =>
        '<div${_style({'padding': _num(p['padding']) ?? '16'})}>${one()}</div>',
      'Center' => '<div class="center">${one()}</div>',
      'Expanded' =>
        '<div class="grow"${_style({'flex': _num(p['flex']) ?? '1'})}>${one()}</div>',
      'Text' => _text(n, click),
      'Button' => _button(n),
      'IconButton' =>
        '<button class="icon-btn" type="button"'
            '${p['tooltip'] == null ? '' : ' title="${_esc(n.text('tooltip'))}" aria-label="${_esc(n.text('tooltip'))}"'}'
            '${_on('click', n.text('onTap'))} data-stop><span class="ms">${_icon(n.text('icon', 'add'))}</span></button>',
      'TextField' => _field(n, key),
      'ListTile' => _tile(n),
      'Checkbox' =>
        '<input type="checkbox" class="check" data-stop \${(${_bool(p['value']) ?? 'false'}) ? "checked" : ""}'
            '${_on('change', n.text('onChanged'), args: 'v')} />',
      'Switch' =>
        '<label class="switch" data-stop><input type="checkbox" \${(${_bool(p['value']) ?? 'false'}) ? "checked" : ""}'
            '${_on('change', n.text('onChanged'), args: 'v')} /><span></span></label>',
      'Chip' =>
        '<button type="button" class="chip\${(${_bool(p['selected']) ?? 'false'}) ? " on" : ""}"'
            '${_style({'background': _color(p['color'])})}$click data-stop>'
            '${n.text('icon').isEmpty ? '' : '<span class="ms">${_icon(n.text('icon'))}</span>'}'
            '${_esc(n.text('text', 'Etiqueta'))}</button>',
      'Icon' =>
        '<span class="ms${tap.isEmpty ? '' : ' tap'}"$click${_style({'font-size': _num(p['size']) ?? '24', 'color': _color(p['color'])})}>${_icon(n.text('icon', 'star'))}</span>',
      'Image' => _image(n, click),
      'Progress' =>
        _num(p['value']) == null
            ? '<progress class="progress"></progress>'
            : '<progress class="progress" max="1" value="\${${_num(p['value'])}}"></progress>',
      'Canvas' =>
        '<canvas class="canvas" data-paint="\${ui.paint((ctx, w, h) => { ${TkWebNext.action(n.text('paint'))} })}"'
            '${_on('tap', n.text('onTap'), args: 'x, y')}'
            '${_style({if (_num(p['height']) != null) 'height': _num(p['height']) else ...{'aspect-ratio': '"${_num(p['aspect']) ?? '1.6'}"', 'width': '"min(100%, calc((100dvh - 96px) * ${_num(p['aspect']) ?? '1.6'}))"'}})}></canvas>',
      'Divider' => '<hr class="divider" />',
      'SizedBox' =>
        '<div${_style({'height': _num(p['height']) ?? '16', 'width': _num(p['width'])})}></div>',
      'Spacer' => '<div class="grow"></div>',
      _ => throw UserError(tr('Widget desconocido: {0}', [n.type])),
    };
  }

  static String _child(FlNode c, String key) {
    final w = html(c, key);
    final vis = _bool(c.props['visible']);
    return vis == null || vis == 'true' ? w : '\${($vis) ? `$w` : ""}';
  }

  static String _list(FlNode n, String key) {
    final items = n.text('items').trim();
    final sep = n.props['separated'] == true ? ' sep' : '';
    final pad = _num(n.props['padding']);
    final padStyle = pad == null ? '' : _style({'padding': pad});
    if (items.isEmpty) {
      return '<div class="list$sep"$padStyle>${[for (final (i, c) in n.children.indexed) _child(c, '$key.$i')].join()}</div>';
    }
    final expr = TkWebNext.js(
      items.startsWith('=') ? items.substring(1).trim() : items,
    );
    final name = n.text('as', 'item');
    final body = n.children.isEmpty
        ? '\${esc(String($name))}'
        : html(n.children.first, '$key.0');
    final empty = n.text('empty');
    return '<div class="list$sep"$padStyle>'
        '\${($expr).map(($name, i) => `<div class="item">$body</div>`).join("")}'
        '${empty.isEmpty ? '' : '\${($expr).length === 0 ? `<p class="empty">${_esc(empty)}</p>` : ""}'}'
        '</div>';
  }

  static String _text(FlNode n, String click) {
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
    return '<$tag class="t-$st${_num(p['maxLines']) == null ? '' : ' clamp'}${click.isEmpty ? '' : ' tap'}"$click'
        '${_style({'color': _color(p['color']), if (p['bold'] == true) 'font-weight': '700', if (strike != null && strike != 'false') 'text-decoration': '($strike) ? "line-through" : null', if (p['align'] != null) 'text-align': jsonEncode(p['align']), if (_num(p['maxLines']) != null) '-webkit-line-clamp': '"" + (${_num(p['maxLines'])})'})}>${_esc(n.text('text', 'Texto'))}</$tag>';
  }

  static String _button(FlNode n) {
    final enabled = _bool(n.props['enabled']);
    final icon = n.text('icon');
    return '<button type="button" class="btn btn-${n.text('variant', 'filled')}"'
        '${enabled == null || enabled == 'true' ? '' : ' \${($enabled) ? "" : "disabled"}'}'
        '${_on('click', n.text('onTap'))} data-stop>'
        '${icon.isEmpty ? '' : '<span class="ms">${_icon(icon)}</span>'}'
        '${_esc(n.text('text', 'Botón'))}</button>';
  }

  static String _field(FlNode n, String key) {
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
      'data-key="$key"',
      if (n.text('hint').isNotEmpty) 'placeholder="${_esc(n.text('hint'))}"',
      if (bind.isNotEmpty)
        'data-input="\${ui.on((v) => { $bind = v; app.notify(); })}"',
      if (submit.isNotEmpty && !multi)
        'data-enter="\${ui.on(async () => { ${TkWebNext.action(submit)} })}"',
    ].join(' ');
    final value = bind.isEmpty ? '' : '\${esc($bind ?? "")}';
    final input = multi
        ? '<textarea rows="${lines ?? 4}" $attrs>$value</textarea>'
        : '<input type="$type" $attrs value="$value" />';
    return '<label class="field" data-stop>'
        '${n.text('label').isEmpty ? '' : '<span class="field-label">${_esc(n.text('label'))}</span>'}'
        '<span class="field-box">'
        '${n.text('icon').isEmpty ? '' : '<span class="ms">${_icon(n.text('icon'))}</span>'}'
        '$input</span></label>';
  }

  static String _tile(FlNode n) {
    final p = n.props;
    final tap = n.text('onTap');
    final lead = n.text('icon');
    final c = _color(p['leadingColor']);
    final trailing = n.text('trailing');
    final trailingIcon = n.text('trailingIcon');
    return '<div class="tile${tap.isEmpty ? '' : ' tap'}"${_on('click', tap)}>'
        '${lead.isEmpty
            ? ''
            : c == null
            ? '<span class="ms tile-icon">${_icon(lead)}</span>'
            : '<span class="avatar"${_style({'background': c})}><span class="ms">${_icon(lead)}</span></span>'}'
        '<div class="tile-text"><div class="tile-title">${_esc(n.text('title', 'Título'))}</div>'
        '${n.text('subtitle').isEmpty ? '' : '<div class="tile-sub">${_esc(n.text('subtitle'))}</div>'}</div>'
        '${trailing.isNotEmpty
            ? '<span class="tile-trail">${_esc(trailing)}</span>'
            : trailingIcon.isNotEmpty
            ? '<span class="ms tile-trail">${_icon(trailingIcon)}</span>'
            : ''}'
        '</div>';
  }

  static String _image(FlNode n, String click) {
    final src = n.text('src').trim();
    final h = _num(n.props['height']) ?? '160';
    final r = _num(n.props['radius']) ?? '0';
    if (src.isEmpty) {
      return '<div class="img-ph"$click${_style({'height': h, 'border-radius': r})}><span class="ms">image</span></div>';
    }
    final s = src.startsWith('=')
        ? '\${esc(${TkWebNext.js(src.substring(1).trim())})}'
        : const HtmlEscape().convert(src);
    return '<img class="img"$click alt="" src="$s"${_style({'height': h, 'border-radius': r, 'object-fit': jsonEncode(n.text('fit', 'cover'))})} />';
  }

  /// screens.js: una función por pantalla que devuelve su HTML.
  static String screens(FlApp app) {
    final out = StringBuffer(
      '// Generado por DMarlon Studio a partir de las pantallas. No lo edite.\n'
      'const SCREENS = {};\n\n',
    );
    for (final s in app.screens) {
      final first = app.screens.first.name == s.name;
      final bar = [
        for (final (icon, act, badge) in s.barButtons)
          '{ icon: ${icon.startsWith('=') ? TkWebNext.js(icon.substring(1)) : jsonEncode(icon)}, badge: ${badge.isEmpty ? 'null' : TkWebNext.tpl(badge)}, on: ${act.trim().isEmpty ? 'null' : 'ui.on(async () => { ${TkWebNext.action(act)} })'} }',
      ];
      out.writeln('''SCREENS[${jsonEncode(s.name)}] = (app, ui, router) => {
${s.arg.isEmpty ? '' : '  const arg = app.arg(${jsonEncode(s.name)});\n  if (arg === undefined) return dmsMissing(ui, router);\n'}  return dmsScreen(ui, router, {
    title: ${s.appBar ? TkWebNext.tpl(s.title.isEmpty ? s.name : s.title) : 'null'},
    back: ${!first && !app.inNav(s.name)},
    actions: [${bar.join(', ')}],
    fab: ${s.fabIcon.isEmpty ? 'null' : '{ icon: ${s.fabIcon.startsWith('=') ? TkWebNext.js(s.fabIcon.substring(1)) : jsonEncode(s.fabIcon)}, on: ui.on(async () => { ${TkWebNext.action(s.fabAction)} }) }'},
    body: `${html(s.body, s.name)}`,
  });
};
''');
    }
    return out.toString();
  }

  /// dms.js: el motor (rutas tras #, dibujar, eventos y foco) y la base de
  /// App.
  static String dms(FlApp app) =>
      '''// DMarlon Studio: el motor de la web en HTML. Generado: no lo edite.
"use strict";

const ROUTES = ${jsonEncode({for (final s in app.screens) s.name: TkWebNext.route(app, s.name)})};
const NAV = ${jsonEncode([
        for (final (screen, icon, label) in app.navItems) {'screen': screen, 'icon': icon, 'label': label, 'path': TkWebNext.route(app, screen)},
      ])};

/// Escapa un texto para ponerlo en el HTML.
function esc(v) {
  return String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

/// Un valor de CSS: los números van en px.
function css(v) {
  if (v === null || v === undefined || v === false) return "unset";
  return typeof v === "number" ? v + "px" : String(v);
}

/// La base de App: notify() vuelve a dibujar; go y home cambian de pantalla.
class DmsApp {
  _args = {};

  notify() {
    dmsRender();
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

const router = {
  path() {
    return window.location.hash.slice(1) || "/";
  },
  push(path) {
    window.location.hash = path;
  },
  replace(path) {
    window.history.replaceState(null, "", "#" + path);
    dmsRender();
  },
  back() {
    window.history.back();
  },
};

/// Los manejadores de la pantalla dibujada (data-click="n"…) y lo que
/// dibuja cada lienzo (data-paint="n").
const ui = {
  handlers: [],
  paints: [],
  on(f) {
    this.handlers.push(f);
    return this.handlers.length - 1;
  },
  paint(f) {
    this.paints.push(f);
    return this.paints.length - 1;
  },
};

/// Dibuja los lienzos de la pantalla, a la resolución de la pantalla.
function dmsPaint() {
  if (!root) return;
  root.querySelectorAll("canvas[data-paint]").forEach((c) => {
    const f = ui.paints[+c.dataset.paint];
    if (!f) return;
    const w = c.clientWidth;
    const h = c.clientHeight;
    const r = window.devicePixelRatio || 1;
    if (c.width !== Math.round(w * r) || c.height !== Math.round(h * r)) {
      c.width = Math.round(w * r);
      c.height = Math.round(h * r);
    }
    const ctx = c.getContext("2d");
    ctx.setTransform(r, 0, 0, r, 0, 0);
    ctx.clearRect(0, 0, w, h);
    f(ctx, w, h);
  });
}

function dmsScreen(ui, router, { title, back, actions, fab, body }) {
  const path = router.path();
  const inNav = NAV.some((n) => n.path === path);
  const screen = `<div class="screen">
    \${title === null ? "" : `<header class="bar">
      \${back ? `<button type="button" class="icon-btn" aria-label="Volver" data-click="\${ui.on(() => router.back())}"><span class="ms">arrow_back</span></button>` : ""}
      <h1 class="bar-title">\${esc(title)}</h1>
      \${actions.map((a) => `<button type="button" class="icon-btn"\${a.on === null ? "" : ` data-click="\${a.on}"`}><span class="ms">\${esc(a.icon)}</span>\${a.badge !== null && a.badge !== "0" && a.badge !== "" ? `<span class="badge">\${esc(a.badge)}</span>` : ""}</button>`).join("")}
    </header>`}
    <main class="content">\${body}</main>
    \${fab ? `<button type="button" class="fab" data-click="\${fab.on}"><span class="ms">\${esc(fab.icon)}</span></button>` : ""}
  </div>`;
  if (!inNav) return screen;
  return `<div class="shell"><nav class="nav">\${NAV.map((n) => `<button type="button" class="nav-item\${n.path === path ? " on" : ""}" data-click="\${ui.on(() => router.replace(n.path))}"><span class="ms">\${esc(n.icon)}</span><span>\${esc(n.label)}</span></button>`).join("")}</nav><div class="shell-main">\${screen}</div></div>`;
}

function dmsMissing(ui, router) {
  return `<div class="screen"><main class="content center col" style="gap:12px;padding:32px">
    <span class="ms" style="font-size:48px">link_off</span>
    <p>Esta pantalla se abre desde la app.</p>
    <button type="button" class="btn btn-filled" data-click="\${ui.on(() => router.replace("/"))}">Ir al inicio</button>
  </main></div>`;
}

let app;
let root;

/// Dibuja la pantalla de la ruta; los campos conservan el foco y el cursor.
function dmsRender() {
  if (!root) return;
  const active = document.activeElement;
  const key = active && active.dataset ? active.dataset.key : null;
  const start = key ? active.selectionStart : null;
  const end = key ? active.selectionEnd : null;
  const path = router.path();
  const name = Object.keys(ROUTES).find((k) => ROUTES[k] === path) || Object.keys(ROUTES)[0];
  ui.handlers = [];
  ui.paints = [];
  root.innerHTML = SCREENS[name](app, ui, router);
  dmsPaint();
  if (key) {
    const el = root.querySelector(`[data-key="\${key}"]`);
    if (el) {
      el.focus();
      try {
        el.setSelectionRange(start, end);
      } catch (_) {}
    }
  }
}

function dmsStart(App) {
  app = new App();
  root = document.getElementById("root");
  const call = (el, attr, ...args) => {
    const id = el.getAttribute(attr);
    if (id !== null && ui.handlers[+id]) ui.handlers[+id](...args);
  };
  root.addEventListener("click", (e) => {
    // Un toque en un lienzo: sus coordenadas en píxeles CSS.
    const cv = e.target.closest("canvas[data-tap]");
    if (cv) {
      const b = cv.getBoundingClientRect();
      call(cv, "data-tap", e.clientX - b.left, e.clientY - b.top);
      return;
    }
    const el = e.target.closest("[data-click]");
    if (!el || el.disabled) return;
    // Lo de dentro de una tarjeta no la toca a ella (como en Flutter).
    const own = e.target.closest("[data-stop]");
    if (own && own !== el && el.contains(own)) return;
    call(el, "data-click");
  });
  root.addEventListener("input", (e) => {
    if (e.target.matches("[data-input]")) call(e.target, "data-input", e.target.value);
  });
  root.addEventListener("change", (e) => {
    if (e.target.matches("[data-change]")) call(e.target, "data-change", e.target.checked);
  });
  root.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && e.target.matches("[data-enter]")) call(e.target, "data-enter");
  });
  window.addEventListener("hashchange", dmsRender);
  window.addEventListener("resize", dmsPaint);
  dmsRender();
  Promise.resolve(app.start()).then(() => dmsRender());
}
''';

  /// La lógica del usuario como script (sin import ni export, que valen en
  /// las otras webs): las líneas se conservan para los errores.
  static String script(String code) => code
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map(
        (l) => RegExp(r'^\s*import\s.*from\s').hasMatch(l)
            ? ''
            : l.replaceFirst(RegExp(r'^export\s+'), ''),
      )
      .join('\n');

  /// Todos los archivos (se abren tal cual: index.html).
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
    String api = '',
  }) {
    final app = FlApp.of(d);
    if (app.screens.isEmpty) throw UserError(tr('La app no tiene pantallas.'));
    final routes = <String>{};
    for (final s in app.screens) {
      if (!RegExp(r'^[A-Za-z]\w*$').hasMatch(s.name)) {
        throw UserError(
          tr('«{0}» no sirve como nombre de pantalla.', [s.name]),
        );
      }
      if (!routes.add(TkWebNext.route(app, s.name))) {
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
    final title = const HtmlEscape().convert(
      app.title.isEmpty ? name : app.title,
    );
    return {
      'index.html':
          '<!doctype html>\n<html lang="es">\n  <head>\n'
          '    <meta charset="utf-8" />\n'
          '    <meta name="viewport" content="width=device-width, initial-scale=1" />\n'
          '    <title>$title</title>\n'
          '    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block" />\n'
          '    <link rel="stylesheet" href="style.css" />\n'
          '  </head>\n  <body>\n    <div id="root"></div>\n'
          '    <script src="dms.js"></script>\n'
          '    <script src="app.js"></script>\n'
          '    <script src="screens.js"></script>\n'
          '    <script>dmsStart(App);</script>\n'
          '  </body>\n</html>\n',
      'style.css': TkWebNext.css(app),
      'dms.js': dms(app) + api,
      'screens.js': screens(app),
      'app.js': script(code),
      'README.md':
          '# $title\n\n'
          '${tr('Web en HTML, CSS y JavaScript creada con DMarlon Studio: abra index.html o súbala a cualquier hosting.')}\n',
    };
  }

  /// Lo que se ve en la pestaña «JavaScript generado».
  static String preview(TkDesign d) => screens(FlApp.of(d));
}
