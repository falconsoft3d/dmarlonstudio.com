import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_flutter.dart';
import 'tk_model.dart';
import 'tk_web_next.dart';

/// Web de Vue (Vite) a partir de las pantallas: el mismo editor y el mismo
/// CSS que las otras webs. Cada pantalla es un componente de un solo archivo
/// (src/screens/Pantalla.vue) con su plantilla; las rutas van tras `#` y se
/// publica como archivos estáticos. La lógica es src/lib/app.js, la misma
/// clase App: notify() sube la versión que leen las pantallas y Vue las
/// vuelve a dibujar.
class TkWebVue {
  TkWebVue._();

  /// Lo que necesita (y el entorno compartido de Vite del estudio).
  static const dependencies = {'vue': '^3.5.45'};
  static const devDependencies = {
    'vite': '^8.3.6',
    '@vitejs/plugin-vue': '^6.0.10',
  };

  /// Una expresión dentro de un atributo entre comillas dobles.
  static String _a(String e) =>
      e.replaceAll('&', '&amp;').replaceAll('"', '&quot;');

  /// Un texto con `${…}` dentro de la plantilla.
  static String _t(String t) => '{{ ${TkWebNext.tpl(t)} }}';

  static String? _expr(Object? v, String Function(String) literal) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return s.startsWith('=') ? TkWebNext.js(s.substring(1).trim()) : literal(s);
  }

  static String? _num(Object? v) => _expr(v, (s) => '${num.tryParse(s) ?? 0}');

  static String? _bool(Object? v) =>
      v is bool ? '$v' : _expr(v, (s) => s == 'true' ? 'true' : 'false');

  static String _icon(String name) => name.startsWith('=')
      ? '{{ ${TkWebNext.js(name.substring(1).trim())} }}'
      : (name.isEmpty ? 'circle' : name);

  static String _iconExpr(String name) => name.startsWith('=')
      ? TkWebNext.js(name.substring(1).trim())
      : jsonEncode(name.isEmpty ? 'circle' : name);

  /// `:style` con las propiedades que van (los números, en px).
  static String _style(Map<String, String?> m) {
    final e = [
      for (final MapEntry(:key, :value) in m.entries)
        if (value != null && value.trim() != 'null')
          "'$key': px(${value.trim()})",
    ];
    return e.isEmpty ? '' : ' :style="${_a('{ ${e.join(', ')} }')}"';
  }

  /// Un manejador de clic (vacío: nada).
  static String _click(String a) => a.trim().isEmpty
      ? ''
      : ' @click="${_a('async () => { ${TkWebNext.action(a)} }')}"';

  /// Un control dentro de algo que también se toca: el clic se queda en él.
  static String _own(String a) => a.trim().isEmpty
      ? ' @click.stop'
      : ' @click.stop="${_a('async () => { ${TkWebNext.action(a)} }')}"';

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

  /// La plantilla de [n].
  static String node(FlNode n) {
    final p = n.props;
    String kids() => [for (final c in n.children) _child(c)].join();
    String one() => n.children.isEmpty ? '' : node(n.children.first);
    final tap = n.text('onTap');
    final click = _click(tap);
    return switch (n.type) {
      'Column' || 'Row' =>
        '<div class="${n.type == 'Column' ? 'col${n.text('cross', 'stretch') == 'stretch' ? ' st' : ''}' : 'row'}${p['wrap'] == true ? ' wrap' : ''}"'
            '${_style({'gap': _num(p['gap']), 'padding': _num(p['padding']), 'justify-content': _justify(n.text('main', 'start')), 'align-items': _align(n.text('cross', n.type == 'Column' ? 'stretch' : 'center'))})}>'
            '${kids()}</div>',
      'ListView' => _list(n),
      'Card' =>
        '<div class="card${tap.isEmpty ? '' : ' tap'}"$click${_style({'padding': _num(p['padding']) ?? '12', 'background': TkWebNext.color(p['color'])})}>${one()}</div>',
      'Container' =>
        '<div class="box${tap.isEmpty ? '' : ' tap'}"$click${_style({'height': _num(p['height']), 'width': _num(p['width']), 'padding': _num(p['padding']), 'background': TkWebNext.color(p['color']), 'border-radius': _num(p['radius'])})}>${one()}</div>',
      'Padding' =>
        '<div${_style({'padding': _num(p['padding']) ?? '16'})}>${one()}</div>',
      'Center' => '<div class="center">${one()}</div>',
      'Expanded' =>
        '<div class="grow"${_style({'flex': _num(p['flex']) ?? '1'})}>${one()}</div>',
      'Text' => _text(n, click),
      'Button' => _button(n),
      'IconButton' =>
        '<button class="icon-btn" type="button"'
            '${p['tooltip'] == null ? '' : ' :title="${_a(TkWebNext.tpl(n.text('tooltip')))}" :aria-label="${_a(TkWebNext.tpl(n.text('tooltip')))}"'}'
            '${_own(n.text('onTap'))}><span class="ms">${_icon(n.text('icon', 'add'))}</span></button>',
      'TextField' => _field(n),
      'ListTile' => _tile(n),
      'Checkbox' =>
        '<input type="checkbox" class="check" @click.stop :checked="${_a('!!(${_bool(p['value']) ?? 'false'})')}"'
            ' @change="${_a('async (e) => { const v = e.target.checked; ${TkWebNext.action(n.text('onChanged'))} }')}" />',
      'Switch' =>
        '<label class="switch" @click.stop><input type="checkbox" :checked="${_a('!!(${_bool(p['value']) ?? 'false'})')}"'
            ' @change="${_a('async (e) => { const v = e.target.checked; ${TkWebNext.action(n.text('onChanged'))} }')}" /><span></span></label>',
      'Chip' =>
        '<button type="button" class="chip" :class="${_a('{ on: !!(${_bool(p['selected']) ?? 'false'}) }')}"'
            '${_style({'background': TkWebNext.color(p['color'])})}${_own(tap)}>'
            '${n.text('icon').isEmpty ? '' : '<span class="ms">${_icon(n.text('icon'))}</span>'}'
            '${_t(n.text('text', 'Etiqueta'))}</button>',
      'Icon' =>
        '<span class="ms${tap.isEmpty ? '' : ' tap'}"$click${_style({'font-size': _num(p['size']) ?? '24', 'color': TkWebNext.color(p['color'])})}>${_icon(n.text('icon', 'star'))}</span>',
      'Image' => _image(n, click),
      'Progress' =>
        _num(p['value']) == null
            ? '<progress class="progress"></progress>'
            : '<progress class="progress" max="1" :value="${_a(_num(p['value'])!)}"></progress>',
      'Divider' => '<hr class="divider" />',
      'SizedBox' =>
        '<div${_style({'height': _num(p['height']) ?? '16', 'width': _num(p['width'])})}></div>',
      'Spacer' => '<div class="grow"></div>',
      _ => throw UserError(tr('Widget desconocido: {0}', [n.type])),
    };
  }

  static String _child(FlNode c) {
    final w = node(c);
    final vis = _bool(c.props['visible']);
    return vis == null || vis == 'true'
        ? w
        : '<template v-if="${_a(vis)}">$w</template>';
  }

  static String _list(FlNode n) {
    final items = n.text('items').trim();
    final sep = n.props['separated'] == true ? ' sep' : '';
    final style = _style({'padding': _num(n.props['padding'])});
    if (items.isEmpty) {
      return '<div class="list$sep"$style>${[for (final c in n.children) _child(c)].join()}</div>';
    }
    final expr = TkWebNext.js(
      items.startsWith('=') ? items.substring(1).trim() : items,
    );
    final name = n.text('as', 'item');
    final body = n.children.isEmpty
        ? '{{ String($name) }}'
        : node(n.children.first);
    final empty = n.text('empty');
    return '<div class="list$sep"$style>'
        '<div class="item" v-for="${_a('($name, i) in ($expr)')}" :key="i">$body</div>'
        '${empty.isEmpty ? '' : '<p class="empty" v-if="${_a('($expr).length === 0')}">${_t(empty)}</p>'}'
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
    final lines = _num(p['maxLines']);
    return '<$tag class="t-$st${lines == null ? '' : ' clamp'}${click.isEmpty ? '' : ' tap'}"$click'
        '${_style({'color': TkWebNext.color(p['color']), if (p['bold'] == true) 'font-weight': '"700"', if (strike != null && strike != 'false') 'text-decoration': '($strike) ? "line-through" : null', if (p['align'] != null) 'text-align': jsonEncode(p['align']), if (lines != null) '-webkit-line-clamp': '"" + ($lines)'})}>${_t(n.text('text', 'Texto'))}</$tag>';
  }

  static String _button(FlNode n) {
    final enabled = _bool(n.props['enabled']);
    final icon = n.text('icon');
    return '<button type="button" class="btn btn-${n.text('variant', 'filled')}"'
        '${enabled == null || enabled == 'true' ? '' : ' :disabled="${_a('!($enabled)')}"'}'
        '${_own(n.text('onTap'))}>'
        '${icon.isEmpty ? '' : '<span class="ms">${_icon(icon)}</span>'}'
        '${_t(n.text('text', 'Botón'))}</button>';
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
      if (n.text('hint').isNotEmpty)
        ':placeholder="${_a(TkWebNext.tpl(n.text('hint')))}"',
      if (bind.isNotEmpty) ...[
        ':value="${_a('$bind ?? ""')}"',
        '@input="${_a('(e) => { $bind = e.target.value; app.notify(); }')}"',
      ],
      if (submit.isNotEmpty && !multi)
        '@keydown.enter="${_a('async () => { ${TkWebNext.action(submit)} }')}"',
    ].join(' ');
    final input = multi
        ? '<textarea :rows="${_a(lines ?? '4')}" $attrs></textarea>'
        : '<input type="$type" $attrs />';
    return '<label class="field" @click.stop>'
        '${n.text('label').isEmpty ? '' : '<span class="field-label">${_t(n.text('label'))}</span>'}'
        '<span class="field-box">'
        '${n.text('icon').isEmpty ? '' : '<span class="ms">${_icon(n.text('icon'))}</span>'}'
        '$input</span></label>';
  }

  static String _tile(FlNode n) {
    final p = n.props;
    final tap = n.text('onTap');
    final lead = n.text('icon');
    final c = TkWebNext.color(p['leadingColor']);
    final trailing = n.text('trailing');
    final trailingIcon = n.text('trailingIcon');
    return '<div class="tile${tap.isEmpty ? '' : ' tap'}"${_click(tap)}>'
        '${lead.isEmpty
            ? ''
            : c == null
            ? '<span class="ms tile-icon">${_icon(lead)}</span>'
            : '<span class="avatar"${_style({'background': c})}><span class="ms">${_icon(lead)}</span></span>'}'
        '<div class="tile-text"><div class="tile-title">${_t(n.text('title', 'Título'))}</div>'
        '${n.text('subtitle').isEmpty ? '' : '<div class="tile-sub">${_t(n.text('subtitle'))}</div>'}</div>'
        '${trailing.isNotEmpty
            ? '<span class="tile-trail">${_t(trailing)}</span>'
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
        ? TkWebNext.js(src.substring(1).trim())
        : jsonEncode(src);
    return '<img class="img"$click alt="" :src="${_a(s)}"'
        '${_style({'height': h, 'border-radius': r, 'object-fit': jsonEncode(n.text('fit', 'cover'))})} />';
  }

  static String _cls(String s) =>
      '${s[0].toUpperCase()}${s.substring(1).replaceAll(RegExp(r'\W'), '')}Page';

  /// src/screens/Pantalla.vue.
  static String page(FlApp app, FlScreen s) {
    final first = app.screens.first.name == s.name;
    final bar = [
      for (final (icon, act, badge) in s.barButtons)
        '{ icon: ${_iconExpr(icon)}, badge: ${badge.isEmpty ? 'null' : TkWebNext.tpl(badge)}, onClick: ${act.trim().isEmpty ? 'undefined' : 'async () => { ${TkWebNext.action(act)} }'} }',
    ];
    final fab = s.fabIcon.isEmpty
        ? 'null'
        : '{ icon: ${_iconExpr(s.fabIcon)}, onClick: async () => { ${TkWebNext.action(s.fabAction)} } }';
    final missing = s.arg.isEmpty;
    return '''<!-- Generado por DMarlon Studio a partir de la pantalla «${s.name}». No lo edite. -->
<script setup>
import { app, ver } from "../lib/state";
import { router, px } from "../lib/dms";
import DmsScreen from "../lib/DmsScreen.vue";
${missing ? '' : 'import DmsMissing from "../lib/DmsMissing.vue";\n\nconst arg = app.arg("${s.name}");\n'}</script>

<template>
${missing ? '' : '  <DmsMissing v-if="arg === undefined" />\n'}  <DmsScreen
    ${missing ? '' : 'v-else\n    '}:ver="ver"
    :title="${_a(s.appBar ? TkWebNext.tpl(s.title.isEmpty ? s.name : s.title) : 'null')}"
    :back="${!first && !app.inNav(s.name)}"
    :actions="${_a('[${bar.join(', ')}]')}"
    :fab="${_a(fab)}"
  >
    ${node(s.body)}
  </DmsScreen>
</template>
''';
  }

  /// src/lib/dms.js: las rutas tras `#`, la versión y la base de App.
  static String dms(FlApp app) =>
      '''// DMarlon Studio: la base de la web de Vue. Generado: no lo edite.
import { ref } from "vue";

/// Las rutas de las pantallas y el menú.
export const ROUTES = ${jsonEncode({for (final s in app.screens) s.name: TkWebNext.route(app, s.name)})};
export const NAV = ${jsonEncode([
        for (final (screen, icon, label) in app.navItems) {'screen': screen, 'icon': icon, 'label': label, 'path': TkWebNext.route(app, screen)},
      ])};

/// Sube con cada notify(): las pantallas la leen y Vue las vuelve a dibujar.
export const ver = ref(0);

function currentPath() {
  return window.location.hash.slice(1) || "/";
}

/// La ruta actual (lo que va tras #).
export const path = ref(currentPath());
window.addEventListener("hashchange", () => {
  path.value = currentPath();
});

export const router = {
  push(p) {
    window.location.hash = p;
  },
  replace(p) {
    window.history.replaceState(null, "", "#" + p);
    path.value = p;
  },
  back() {
    window.history.back();
  },
};

/// Un valor de estilo: los números van en px.
export function px(v) {
  if (v === null || v === undefined || v === false) return undefined;
  return typeof v === "number" ? v + "px" : v;
}

/// La base de App: notify() vuelve a dibujar las pantallas; go y home
/// cambian de pantalla.
export class DmsApp {
  _args = {};

  notify() {
    ver.value++;
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
''';

  static const _screenVue =
      '''<!-- DMarlon Studio: la pantalla (barra, contenido y botón flotante). Generado: no lo edite. -->
<script setup>
import { router } from "./dms";

defineProps({
  ver: Number,
  title: { type: String, default: null },
  back: Boolean,
  actions: { type: Array, default: () => [] },
  fab: { type: Object, default: null },
});
</script>

<template>
  <div class="screen">
    <header v-if="title !== null" class="bar">
      <button v-if="back" type="button" class="icon-btn" aria-label="Volver" @click="router.back()">
        <span class="ms">arrow_back</span>
      </button>
      <h1 class="bar-title">{{ title }}</h1>
      <button v-for="(a, i) in actions" :key="i" type="button" class="icon-btn" @click="a.onClick && a.onClick()">
        <span class="ms">{{ a.icon }}</span>
        <span v-if="a.badge !== null && a.badge !== '0' && a.badge !== ''" class="badge">{{ a.badge }}</span>
      </button>
    </header>
    <main class="content"><slot /></main>
    <button v-if="fab" type="button" class="fab" @click="fab.onClick()">
      <span class="ms">{{ fab.icon }}</span>
    </button>
  </div>
</template>
''';

  static const _missingVue = '''<!-- DMarlon Studio. Generado: no lo edite. -->
<script setup>
import { router } from "./dms";
</script>

<template>
  <div class="screen">
    <main class="content center col" style="gap: 12px; padding: 32px">
      <span class="ms" style="font-size: 48px">link_off</span>
      <p>Esta pantalla se abre desde la app.</p>
      <button type="button" class="btn btn-filled" @click="router.replace('/')">Ir al inicio</button>
    </main>
  </div>
</template>
''';

  static const _shellVue =
      '''<!-- DMarlon Studio: el menú (barra lateral en pantallas anchas y abajo en las estrechas). Generado: no lo edite. -->
<script setup>
import { computed } from "vue";
import { NAV, path, router } from "./dms";

const inNav = computed(() => NAV.some((n) => n.path === path.value));
</script>

<template>
  <div v-if="inNav" class="shell">
    <nav class="nav">
      <button
        v-for="n in NAV"
        :key="n.path"
        type="button"
        class="nav-item"
        :class="{ on: n.path === path }"
        @click="router.replace(n.path)"
      >
        <span class="ms">{{ n.icon }}</span>
        <span>{{ n.label }}</span>
      </button>
    </nav>
    <div class="shell-main"><slot /></div>
  </div>
  <slot v-else />
</template>
''';

  static const _state =
      '''// DMarlon Studio: el estado de la app. Generado: no lo edite.
import { App } from "./app";
export { ver } from "./dms";

export const app = new App();
Promise.resolve(app.start()).then(() => app.notify());
''';

  /// src/App.vue: la pantalla de la ruta actual, dentro del menú.
  static String appVue(FlApp app) =>
      '''<!-- Generado por DMarlon Studio. No lo edite. -->
<script setup>
import { computed } from "vue";
import { path, ROUTES } from "./lib/dms";
import DmsShell from "./lib/DmsShell.vue";
${[for (final s in app.screens) 'import ${_cls(s.name)} from "./screens/${s.name}.vue";'].join('\n')}

const PAGES = { ${[for (final s in app.screens) '[ROUTES.${s.name}]: ${_cls(s.name)}'].join(', ')} };
const page = computed(() => PAGES[path.value] || PAGES["/"]);
</script>

<template>
  <DmsShell>
    <component :is="page" :key="path" />
  </DmsShell>
</template>
''';

  /// Todos los archivos (sin node_modules).
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
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
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final title = app.title.isEmpty ? name : app.title;
    final esc = const HtmlEscape().convert(title);
    return {
      'package.json': const JsonEncoder.withIndent('  ').convert({
        'name': slug.isEmpty ? 'dmarlon-web' : slug,
        'version': '1.0.0',
        'private': true,
        'type': 'module',
        'scripts': {
          'dev': 'vite',
          'build': 'vite build',
          'preview': 'vite preview',
        },
        'dependencies': dependencies,
        'devDependencies': devDependencies,
      }),
      'vite.config.js':
          '// Generado por DMarlon Studio.\n'
          'import { defineConfig } from "vite";\n'
          'import vue from "@vitejs/plugin-vue";\n\n'
          '// base "./": la web funciona en cualquier carpeta del hosting.\n'
          'export default defineConfig({ plugins: [vue()], base: "./" });\n',
      'index.html':
          '<!doctype html>\n<html lang="es">\n  <head>\n'
          '    <meta charset="utf-8" />\n'
          '    <meta name="viewport" content="width=device-width, initial-scale=1" />\n'
          '    <title>$esc</title>\n'
          '    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block" />\n'
          '  </head>\n  <body>\n    <div id="root"></div>\n'
          '    <script type="module" src="/src/main.js"></script>\n'
          '  </body>\n</html>\n',
      'src/main.js':
          '// Generado por DMarlon Studio. No lo edite.\n'
          'import { createApp } from "vue";\n'
          'import "./globals.css";\n'
          'import App from "./App.vue";\n\n'
          'createApp(App).mount("#root");\n',
      'src/globals.css': TkWebNext.css(app),
      'src/App.vue': appVue(app),
      for (final s in app.screens) 'src/screens/${s.name}.vue': page(app, s),
      'src/lib/dms.js': dms(app),
      'src/lib/DmsScreen.vue': _screenVue,
      'src/lib/DmsMissing.vue': _missingVue,
      'src/lib/DmsShell.vue': _shellVue,
      'src/lib/state.js': _state,
      'src/lib/app.js': code.replaceAll('\r\n', '\n'),
      'README.md':
          '# $title\n\n'
          '${tr('Web de Vue (Vite) creada con DMarlon Studio.')}\n\n'
          '```\nnpm install\nnpm run dev\nnpm run build   # dist/: súbala a cualquier hosting\n```\n',
    };
  }

  /// Lo que se ve en la pestaña «JavaScript generado».
  static String preview(TkDesign d) {
    final app = FlApp.of(d);
    return [
      for (final s in app.screens)
        '<!-- ---- src/screens/${s.name}.vue -->\n${page(app, s)}',
    ].join('\n');
  }
}
