import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_flutter.dart';
import 'tk_model.dart';
import 'tk_web_next.dart';

/// Web con React (Vite) a partir de las pantallas: el mismo editor y el
/// mismo JSX y CSS que la web de Next.js, pero como una página estática con
/// rutas tras `#` (se sube tal cual a cualquier hosting). La lógica es
/// src/lib/app.js, la misma clase App (DmsApp con notify()).
class TkWebReact {
  TkWebReact._();

  /// Lo que necesita (y el entorno compartido del estudio).
  static const dependencies = {'react': '19.3.0', 'react-dom': '19.3.0'};
  static const devDependencies = {
    'vite': '^8.3.6',
    '@vitejs/plugin-react': '^6.2.1',
  };

  static String _cls(String s) =>
      '${s[0].toUpperCase()}${s.substring(1).replaceAll(RegExp(r'\W'), '')}Page';

  /// src/screens/Pantalla.jsx.
  static String page(FlApp app, FlScreen s) {
    final first = app.screens.first.name == s.name;
    final bar = [
      for (final (icon, act, badge) in s.barButtons)
        '{ icon: ${icon.startsWith('=') ? TkWebNext.js(icon.substring(1)) : jsonEncode(icon)}, badge: ${badge.isEmpty ? 'null' : TkWebNext.tpl(badge)}, onClick: ${act.trim().isEmpty ? 'undefined' : 'async () => { ${TkWebNext.action(act)} }'} }',
    ];
    return '''// Generado por DMarlon Studio a partir de la pantalla «${s.name}». No lo edite.
import { app, useApp } from "../lib/state";
import { DmsScreen, DmsMissing, DmsCanvas, useRouter } from "../lib/dms";

export default function ${_cls(s.name)}() {
  useApp();
  const router = useRouter();
${s.arg.isEmpty ? '' : '  const arg = app.arg("${s.name}");\n  if (arg === undefined) return <DmsMissing router={router} />;\n'}  return (
    <DmsScreen
      title={${s.appBar ? TkWebNext.tpl(s.title.isEmpty ? s.name : s.title) : 'null'}}
      back={${!first && !app.inNav(s.name)}}
      actions={[${bar.join(', ')}]}
${s.fabIcon.isEmpty ? '' : '      fab={{ icon: ${s.fabIcon.startsWith('=') ? TkWebNext.js(s.fabIcon.substring(1)) : jsonEncode(s.fabIcon)}, onClick: async () => { ${TkWebNext.action(s.fabAction)} } }}\n'}    >
      ${TkWebNext.jsx(s.body, indent: '      ')}
    </DmsScreen>
  );
}
''';
  }

  /// src/lib/dms.jsx: lo de Next.js (la base de App, la pantalla, el menú)
  /// con un enrutador propio: las rutas van tras `#`.
  static String dms(FlApp app) {
    final next = TkWebNext.dms(app)
        .replaceFirst('"use client";\n', '')
        .replaceFirst(
          'import { usePathname, useRouter } from "next/navigation";\n',
          '''import { useSyncExternalStore } from "react";

/// La ruta actual (lo que va tras #).
function currentPath() {
  return window.location.hash.slice(1) || "/";
}

function subscribe(f) {
  window.addEventListener("hashchange", f);
  return () => window.removeEventListener("hashchange", f);
}

export function usePathname() {
  return useSyncExternalStore(subscribe, currentPath, () => "/");
}

const router = {
  push(path) {
    window.location.hash = path;
  },
  replace(path) {
    window.history.replaceState(null, "", "#" + path);
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  },
  back() {
    window.history.back();
  },
};

export function useRouter() {
  return router;
}
''',
        );
    return next;
  }

  /// src/App.jsx: la pantalla de la ruta actual, dentro del menú.
  static String appJsx(FlApp app) =>
      '''// Generado por DMarlon Studio. No lo edite.
import { DmsShell, usePathname, ROUTES } from "./lib/dms";
${[for (final s in app.screens) 'import ${_cls(s.name)} from "./screens/${s.name}";'].join('\n')}

const PAGES = { ${[for (final s in app.screens) '[ROUTES.${s.name}]: ${_cls(s.name)}'].join(', ')} };

export default function App() {
  const path = usePathname();
  const Page = PAGES[path] || PAGES["/"];
  return (
    <DmsShell>
      <Page key={path} />
    </DmsShell>
  );
}
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
          'import react from "@vitejs/plugin-react";\n\n'
          '// base "./": la web funciona en cualquier carpeta del hosting.\n'
          'export default defineConfig({ plugins: [react()], base: "./" });\n',
      'index.html':
          '<!doctype html>\n<html lang="es">\n  <head>\n'
          '    <meta charset="utf-8" />\n'
          '    <meta name="viewport" content="width=device-width, initial-scale=1" />\n'
          '    <title>$esc</title>\n'
          '    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block" />\n'
          '  </head>\n  <body>\n    <div id="root"></div>\n'
          '    <script type="module" src="/src/main.jsx"></script>\n'
          '  </body>\n</html>\n',
      'src/main.jsx':
          '// Generado por DMarlon Studio. No lo edite.\n'
          'import { createRoot } from "react-dom/client";\n'
          'import "./globals.css";\n'
          'import App from "./App";\n\n'
          'createRoot(document.getElementById("root")).render(<App />);\n',
      'src/globals.css': TkWebNext.css(app),
      'src/App.jsx': appJsx(app),
      for (final s in app.screens) 'src/screens/${s.name}.jsx': page(app, s),
      'src/lib/dms.jsx': dms(app),
      'src/lib/state.js': TkWebNext.state.replaceFirst('"use client";\n', ''),
      'src/lib/app.js': code.replaceAll('\r\n', '\n'),
      'README.md':
          '# $title\n\n'
          '${tr('Web de React (Vite) creada con DMarlon Studio.')}\n\n'
          '```\nnpm install\nnpm run dev\nnpm run build   # dist/: súbala a cualquier hosting\n```\n',
    };
  }

  /// Lo que se ve en la pestaña «JavaScript generado».
  static String preview(TkDesign d) {
    final app = FlApp.of(d);
    return [
      for (final s in app.screens)
        '// ---- src/screens/${s.name}.jsx\n${page(app, s)}',
    ].join('\n');
  }
}
