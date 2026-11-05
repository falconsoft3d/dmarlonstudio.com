import 'dart:convert';

import '../ai/assistant.dart';
import '../core/errors.dart';
import '../i18n/i18n.dart';
import 'tk_codegen.dart';
import 'tk_model.dart';

/// Propuesta de la IA: aún no se ha aplicado a nada.
class TkAiChange {
  TkAiChange({
    required this.design,
    required this.code,
    required this.summary,
    this.notes = const [],
    this.methods = const [],
  });
  final TkDesign design;
  final String code;
  final String summary;

  /// Lo que se descartó o se corrigió.
  final List<String> notes;

  /// Métodos nuevos o reescritos.
  final List<String> methods;
}

/// La IA diseña ventanas: devuelve el mismo JSON que guarda el diseñador. Lo
/// que devuelve es una propuesta que hay que validar (aquí, contra el
/// catálogo) y que el usuario acepta o descarta; su código es tan poco de
/// fiar como cualquier otro y pasa por la misma aprobación antes de ejecutarse.
/// La IA no ve fichas ni contraseñas: de una conexión solo conoce el nombre.
class TkAi {
  TkAi._();

  /// Solo en las pruebas.
  static Future<String> Function(List<Map<String, Object?>> messages)?
  aiOverride;

  /// Qué falta para poder pedirle algo a la IA (null: nada).
  static Future<String?> missing() async {
    if (aiOverride != null) return null;
    final c = await AiConfig.load();
    return c.ready ? null : c.missingKey;
  }

  static Future<String> _ai(List<Map<String, Object?>> messages) =>
      aiOverride?.call(messages) ??
      AiConfig.load().then(
        (c) => Assistant(config: c).chat(messages, json: true),
      );

  static String _typeOf(TkProp p) => switch (p.type) {
    TkPropType.text => 'text',
    TkPropType.multiline => 'multi-line text',
    TkPropType.integer => 'integer',
    TkPropType.number => 'number',
    TkPropType.boolean => 'boolean',
    TkPropType.color => '"#rrggbb" color',
    TkPropType.choice =>
      'one of ${p.choices.where((c) => c.isNotEmpty).join('|')}',
    TkPropType.connection => 'name of a saved connection',
    TkPropType.reference => 'name of a ${p.refKind} component',
  };

  static String _events(List<TkEvent> events) => events
      .map((e) => '${e.key}(${e.param.isEmpty ? 'self' : 'self, ${e.param}'})')
      .join(', ');

  /// Los componentes, propiedades y eventos que existen, sacados del modelo:
  /// es lo único que la IA puede usar. Con [web], sin lo que no tiene
  /// equivalente en una página.
  static String catalog({bool web = false}) {
    final form = _formProps(web);
    final b = StringBuffer();
    b.writeln(
      'Window (design level): width, height; props: '
      '${form.map((p) => '${p.key} (${_typeOf(p)})').join(', ')}; '
      'events: ${_events(_formEvents(web))}.',
    );
    b.writeln('Components (kind, default size, props, events):');
    for (final c in tkComponents) {
      if (web && tkWebNoKinds.contains(c.kind)) continue;
      final events = [
        for (final e in c.events)
          if (!web || tkWebHasEvent(e)) e,
      ];
      b.writeln(
        '- ${c.kind} (${c.width}x${c.height})'
        '${c.container ? ', can contain other components' : ''}'
        '${c.visual ? '' : ', invisible at run time'}: props: '
        '${c.props.map((p) => '${p.key} (${_typeOf(p)})').join(', ')}; '
        'events: ${_events(events)}.',
      );
    }
    return b.toString();
  }

  static List<TkProp> _formProps(bool web) => [
    for (final p in tkFormProps)
      if (!web || !tkWebNoFormProps.contains(p.key)) p,
  ];

  static List<TkEvent> _formEvents(bool web) => [
    for (final e in tkFormEvents)
      if (!web || tkWebHasEvent(e, form: true)) e,
  ];

  /// Instrucciones para una aplicación web: el código sigue siendo Python.
  static String _webSystem(List<String> connections, TkDesign current) {
    final lang = I18n.lang.value == 'en' ? 'English' : 'Spanish';
    return '''You are the assistant of a visual interface designer for web applications. A Python Flask application is generated from the design and every handler runs in Python on the server. You never write HTML, CSS, JavaScript or Flask routes. You answer with one JSON object and nothing else:
{"summary": "one short sentence in $lang", "design": {"width": 400, "height": 300, "props": {}, "events": {"event": "method"}, "widgets": [{"kind": "Button", "name": "Button1", "x": 16, "y": 16, "width": 96, "height": 32, "parent": null, "props": {}, "events": {"command": "Button1_click"}}]}, "methods": {"Button1_click": {"param": "", "body": "self.Label1.configure(text=\\"Hola\\")"}}, "imports": ["import json"]}

${catalog(web: true)}
Rules:
- Use only the components, props and events listed above. Nothing else exists: there is no canvas drawing, and no mouse move or drag events.
- Omit every prop that keeps its default value.
- x, y, width and height are integers in pixels on an 8 pixel grid, inside the page. A child of a Frame (parent = the Frame's name) is positioned relative to the Frame, and a Frame comes before its children.
- Names start with a letter, use only ASCII letters, digits and _, and are unique. Use descriptive names (BtnSave, Customer).
- The user's code is a subclass of the generated class and works as in tkinter: self.root is the page, self.<Name> each component, and self.<Name>_var the value of an Entry, Combobox, Checkbutton or Scale. A Radiobutton group shares self.<group>_var.
- Components answer to the usual tkinter calls: configure, cget, Entry get/insert/delete, Text get/insert/delete, Listbox insert/delete/get/size/curselection/selection_set, Combobox get/set/current, Scale get/set, Treeview insert/delete/get_children/selection, and self.root.title and self.root.after.
- self.value("Name") reads a component and self.value("Name", x) sets it.
- self.notify(text) shows a message on the page. Never import or use tkinter, messagebox or dialogs.
- A PageControl holds tabs (its pages prop, one caption per line). A child of a PageControl has parent = the PageControl's name and "page": the 0-based tab index; its x and y are relative to the PageControl, and y must be at least 24 (below the tabs). self.<PageControl>.select(i) shows a tab and self.<PageControl>.index("current") tells which one is shown.
- A Menu (at most one per window, never inside a Frame or PageControl) lists its options in the items prop, one per line: indentation makes a submenu and "-" a separator. Choosing an option calls its command handler with item = the option path, e.g. "Archivo/Salir".
- A Timer calls its command handler every interval milliseconds while enabled: self.<Timer>.enabled = False stops it, self.<Timer>.start(ms) restarts it.
- A StatusBar is always docked at the bottom of the window, full width: only its height counts. Set its text with self.<StatusBar>.configure(text=...).
- A Progressbar shows its value prop out of maximum: self.<Progressbar>.configure(value=40) or self.<Progressbar>["value"] = 40.
- A Ribbon is an Office-style ribbon docked at the top of the window, full width (only its height counts; never inside a Frame or PageControl; at most one). Its items prop: lines without indentation are tabs, indented once are groups, indented twice are buttons "Label | icon" (icon names: new, open, save, print, cut, copy, paste, bold, italic, underline, table, image, chart, find, settings, help, info, undo, redo, refresh, delete, add, edit, user, mail, calendar, home, play, stop, star, check). Its command handler gets item = "Tab/Group/Button"; its change handler runs when the tab changes. self.<Ribbon>.select(i) shows a tab and self.<Ribbon>.enable("Tab/Group/Button", False) greys out a button. Place other components below its height.
- A StatusBar can show an icon (icon prop, same names as the Ribbon): self.<StatusBar>.set("text", icon="save").
- A RestClient calls an HTTP/JSON API with the standard library: self.<RestClient>.get(path, params), .post(path, data), .put, .patch and .delete return the parsed JSON (or text) and raise ApiError (with .status and .body) on failure; get_async(path), post_async(path, data)... run in the background and call its done handler with the result or its error handler with the ApiError. base_url and headers may contain {{name}}, the API variables of DMarlon Studio. Never put tokens or passwords in props or code: set auth and token_env (or password_env) to the name of a variable.
- A Password is an entry that hides its text: self.<Password>.get() reads it (or self.<Password>_var), and self.<Password>_visible(True) shows it.
- An Image shows a file of the project's images folder (file prop, e.g. "images/logo.png"; fit: none, contain, cover or stretch). self.<Image>_load("images/other.png") shows another one.
- There is no TrayIcon or OpenDialog in a web app. A SaveDialog downloads a file in the browser: self.<SaveDialog>.write_text(text) or self.<SaveDialog>.download(name, data).
- Put start-up code in the window's create event. Defining __init__ in the class is allowed (self.root and every component already exist there, with or without super().__init__()), and the create event runs after it.
- Every handler receives what the event list shows: param is "", "event", "value", "item", "result", "error" or "path".
- "body" holds only the Python statements of the method, without the def line, with no base indentation. Do not include methods that already exist unless asked.
- User-visible text is in $lang.
- Database data comes only through a Connection whose connection prop is one of the saved names (never empty): self.<Connection>.query(sql, params) and execute(sql, params), always with ? parameters, never by joining text into SQL. A Treeview shows them (its query prop), and self.<Grid>_refresh() reloads it. Without saved connections, do not add a Connection.
- Saved connections: ${connections.isEmpty ? 'none' : connections.join(', ')}.
- Never write passwords, tokens, keys, hosts or credentials in the code, and do not read them from the environment: the server receives what it needs (a RestClient names its variables in token_env and password_env).
- Keep the window name ${current.name}: it is the class name.''';
  }

  static String _system(List<String> connections, TkDesign current) {
    if (current.isWeb) return _webSystem(connections, current);
    final lang = I18n.lang.value == 'en' ? 'English' : 'Spanish';
    return '''You are the assistant of a visual interface designer for Python tkinter windows. You answer with one JSON object and nothing else:
{"summary": "one short sentence in $lang", "design": {"width": 400, "height": 300, "props": {}, "events": {"event": "method"}, "widgets": [{"kind": "Button", "name": "Button1", "x": 16, "y": 16, "width": 96, "height": 32, "parent": null, "props": {}, "events": {"command": "Button1_click"}}]}, "methods": {"Button1_click": {"param": "", "body": "self.Label1.configure(text=\\"Hola\\")"}}, "imports": ["import json"]}

${catalog()}
Rules:
- Use only the components, props and events listed above. Nothing else exists.
- Omit every prop that keeps its default value.
- x, y, width and height are integers in pixels on an 8 pixel grid, inside the window. A child of a Frame (parent = the Frame's name) is positioned relative to the Frame, and a Frame comes before its children.
- Names start with a letter, use only ASCII letters, digits and _, and are unique. Use descriptive names (BtnSave, Customer).
- The user's code is a subclass of the generated window class: self.root is the window, self.<Name> each component, and self.<Name>_var the value of an Entry, Combobox, Checkbutton or Scale. A Radiobutton group shares self.<group>_var.
- A PageControl holds tabs (its pages prop, one caption per line). A child of a PageControl has parent = the PageControl's name and "page": the 0-based tab index; its x and y are relative to the PageControl, and y must be at least 24 (below the tabs). self.<PageControl>.select(i) shows a tab and self.<PageControl>.index("current") tells which one is shown.
- A Menu (at most one per window, never inside a Frame or PageControl) lists its options in the items prop, one per line: indentation makes a submenu and "-" a separator. Choosing an option calls its command handler with item = the option path, e.g. "Archivo/Salir".
- A Timer calls its command handler every interval milliseconds while enabled: self.<Timer>.enabled = False stops it, self.<Timer>.start(ms) restarts it.
- A StatusBar is always docked at the bottom of the window, full width: only its height counts. Set its text with self.<StatusBar>.configure(text=...).
- A Progressbar shows its value prop out of maximum: self.<Progressbar>.configure(value=40) or self.<Progressbar>["value"] = 40.
- A Ribbon is an Office-style ribbon docked at the top of the window, full width (only its height counts; never inside a Frame or PageControl; at most one). Its items prop: lines without indentation are tabs, indented once are groups, indented twice are buttons "Label | icon" (icon names: new, open, save, print, cut, copy, paste, bold, italic, underline, table, image, chart, find, settings, help, info, undo, redo, refresh, delete, add, edit, user, mail, calendar, home, play, stop, star, check). Its command handler gets item = "Tab/Group/Button"; its change handler runs when the tab changes. self.<Ribbon>.select(i) shows a tab and self.<Ribbon>.enable("Tab/Group/Button", False) greys out a button. Place other components below its height.
- A StatusBar can show an icon (icon prop, same names as the Ribbon): self.<StatusBar>.set("text", icon="save").
- A RestClient calls an HTTP/JSON API with the standard library: self.<RestClient>.get(path, params), .post(path, data), .put, .patch and .delete return the parsed JSON (or text) and raise ApiError (with .status and .body) on failure; get_async(path), post_async(path, data)... run in the background and call its done handler with the result or its error handler with the ApiError. base_url and headers may contain {{name}}, the API variables of DMarlon Studio. Never put tokens or passwords in props or code: set auth and token_env (or password_env) to the name of a variable.
- A Password is an entry that hides its text: self.<Password>.get() reads it (or self.<Password>_var), and self.<Password>_visible(True) shows it.
- An Image shows a file of the project's images folder (file prop, e.g. "images/logo.png"; fit: none, contain, cover or stretch). self.<Image>_load("images/other.png") shows another one.
- A TrayIcon puts an icon in the menu bar (macOS) or the notification area: its click handler runs on a click and its command handler gets item = the path of its menu option (items prop, like a Menu). self.<TrayIcon>.notify(title, message), .show() and .hide().
- OpenDialog and SaveDialog are file dialogs: path = self.<OpenDialog>.execute() returns the path chosen or None (a list with multiple), and self.<OpenDialog>.read_text() returns (path, text) or None; self.<SaveDialog>.execute() returns the path (with the default extension) or None, and self.<SaveDialog>.write_text(text) asks and writes, returning the path or None. filter: one "Name|*.ext;*.ext2" per line.
- The window's position prop: default, center or manual (with left and top).
- Put start-up code in the window's create event. Defining __init__ in the class is allowed (self.root and every component already exist there, with or without super().__init__()), and the create event runs after it.
- Every handler receives what the event list shows: param is "", "event", "value", "item", "result", "error" or "path".
- "body" holds only the Python statements of the method, without the def line, with no base indentation. Do not include methods that already exist unless asked.
- User-visible text is in $lang.
- Database data comes only through a Connection whose connection prop is one of the saved names (never empty): self.<Connection>.query(sql, params) and execute(sql, params), always with ? parameters, never by joining text into SQL. A Treeview shows them (its query prop), and self.<Grid>_refresh() reloads it. Without saved connections, do not add a Connection.
- Saved connections: ${connections.isEmpty ? 'none' : connections.join(', ')}.
- Never write passwords, tokens, keys, hosts or credentials in the code, and do not read them from the environment: the window receives what it needs (a RestClient names its variables in token_env and password_env).
- Keep the window name ${current.name}: it is the class name.''';
  }

  static String _clip(String s, [int max = 24000]) =>
      s.length <= max ? s : '${s.substring(0, max)}\n# …';

  static Map<String, Object?>? _object(String out) {
    final a = out.indexOf('{'), b = out.lastIndexOf('}');
    if (a < 0 || b <= a) return null;
    try {
      final j = jsonDecode(out.substring(a, b + 1));
      return j is Map ? j.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  static int _int(Object? v, int fallback) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

  /// Valor de la propiedad [p], o null si no le vale.
  static Object? _coerce(TkProp p, Object? v, List<String> connections) =>
      switch (p.type) {
        TkPropType.text ||
        TkPropType.multiline => v is String || v is num ? '$v' : null,
        TkPropType.integer =>
          v is num ? v.toInt() : (v is String ? int.tryParse(v) : null),
        TkPropType.number =>
          v is num ? v : (v is String ? num.tryParse(v) : null),
        TkPropType.boolean => v is bool ? v : null,
        TkPropType.color =>
          v == '' || TkCodegen.color(v) != null ? '$v'.trim() : null,
        TkPropType.choice => p.choices.contains('$v') ? '$v' : null,
        TkPropType.connection => connections.contains('$v') ? '$v' : null,
        TkPropType.reference => v is String ? v : null,
      };

  /// Comprueba el diseño de la IA contra el catálogo: lo que no existe queda
  /// fuera y se anota en `errors`; lo que se sale de la ventana se recoloca.
  static ({TkDesign design, List<String> errors, List<String> notes}) validate(
    Map<String, Object?> j, {
    required TkDesign current,
    List<String> connections = const [],
  }) {
    final errors = <String>[], notes = <String>[];
    final web = current.isWeb;
    final out = TkDesign(
      name: current.name,
      target: current.target,
      width: _int(j['width'], current.width).clamp(80, 1920),
      height: _int(j['height'], current.height).clamp(60, 1200),
    );
    void props(
      Map? from,
      String owner,
      TkProp? Function(String) find,
      void Function(TkProp, Object?) set,
    ) {
      for (final e in (from ?? const {}).entries) {
        final p = find('${e.key}');
        if (p == null) {
          errors.add('$owner has no prop ${e.key}');
          continue;
        }
        final v = _coerce(p, e.value, connections);
        if (v == null) {
          errors.add('$owner: invalid value for ${e.key}: ${e.value}');
        } else {
          set(p, v);
        }
      }
    }

    void events(
      Map? from,
      String owner,
      List<TkEvent> known,
      Map<String, String> to,
    ) {
      for (final e in (from ?? const {}).entries) {
        if (!known.any((k) => k.key == e.key)) {
          errors.add('$owner has no event ${e.key}');
        } else if (!out.validName('${e.value}')) {
          errors.add('$owner: invalid method name ${e.value}');
        } else {
          to['${e.key}'] = '${e.value}';
        }
      }
    }

    props(
      j['props'] as Map?,
      'window',
      (k) => _formProps(web).where((p) => p.key == k).firstOrNull,
      out.setProp,
    );
    events(j['events'] as Map?, 'window', _formEvents(web), out.events);

    final raw = j['widgets'];
    final widgets = <TkWidget>[];
    final parents = <TkWidget, String?>{};
    for (final x in raw is List ? raw : const []) {
      if (x is! Map) {
        errors.add('widgets must be objects');
        continue;
      }
      final kind = '${x['kind']}', name = '${x['name']}';
      final c = tkComponent(kind);
      if (c == null) {
        errors.add('unknown component $kind');
        continue;
      }
      if (web && tkWebNoKinds.contains(kind)) {
        errors.add('$kind has no web equivalent');
        continue;
      }
      if (!out.validName(name) ||
          name == out.name ||
          widgets.any((w) => w.name == name)) {
        errors.add('invalid or repeated name $name');
        continue;
      }
      final w = TkWidget(
        kind: kind,
        name: name,
        x: _int(x['x'], 8),
        y: _int(x['y'], 8),
        width: _int(x['width'], c.width),
        height: _int(x['height'], c.height),
      );
      props(x['props'] as Map?, name, c.prop, w.setProp);
      events(x['events'] as Map?, name, [
        for (final e in c.events)
          if (!web || tkWebHasEvent(e)) e,
      ], w.events);
      if (x['page'] is num) w.page = (x['page'] as num).toInt();
      parents[w] = x['parent'] is String && c.nestable
          ? x['parent'] as String
          : null;
      widgets.add(w);
    }

    // Marcos: el contenedor debe existir, poder contener y crearse antes.
    TkWidget? parentOf(TkWidget w) {
      final name = parents[w];
      if (name == null) return null;
      final p = widgets.where((o) => o.name == name).firstOrNull;
      if (p == null || !p.component.container || p == w) {
        errors.add('${w.name}: invalid parent $name');
        return null;
      }
      return p;
    }

    final seen = <TkWidget>{};
    void add(TkWidget w, Set<TkWidget> path) {
      if (seen.contains(w)) return;
      final p = parentOf(w);
      if (p != null && path.contains(p)) {
        errors.add('${w.name}: parent cycle');
      } else if (p != null) {
        add(p, {...path, w});
        w.parent = p.name;
      }
      seen.add(w);
      out.widgets.add(w);
    }

    for (final w in widgets) {
      add(w, {w});
    }

    // Dentro de la ventana o de su marco.
    for (final w in out.widgets) {
      final p = w.parent == null ? null : out.byName(w.parent!);
      final pw = p?.width ?? out.width, ph = p?.height ?? out.height;
      final x = w.x.clamp(0, (pw - tkMinSize).clamp(0, pw));
      final y = w.y.clamp(0, (ph - tkMinSize).clamp(0, ph));
      final width = w.width.clamp(tkMinSize, (pw - x).clamp(tkMinSize, pw));
      final height = w.height.clamp(tkMinSize, (ph - y).clamp(tkMinSize, ph));
      if (x != w.x || y != w.y || width != w.width || height != w.height) {
        notes.add(
          tr('«{0}» se salía de la ventana: se ha recolocado.', [w.name]),
        );
      }
      w
        ..x = x
        ..y = y
        ..width = width
        ..height = height;
    }
    return (design: out, errors: errors, notes: notes);
  }

  /// Las credenciales de la ventana están en el entorno: el código de la IA
  /// no tiene nada que hacer con ellas.
  static bool _touchesSecrets(String body) => body.contains('DMSTUDIO_');

  /// Añade al código lo que pide la IA. Lo que ya existe no se toca.
  static (String, List<String>, List<String>) _merge(
    String code,
    TkDesign design,
    Map<String, Object?> j,
  ) {
    final form = design.name;
    var out = code;
    final added = <String>[], notes = <String>[];
    final imports = j['imports'];
    final lines = <String>[];
    for (final i in imports is List ? imports : const []) {
      final s = '$i'.trim();
      // Una aplicación web corre en un servidor, sin ventanas.
      if (design.isWeb && RegExp(r'\btkinter\b').hasMatch(s)) {
        notes.add(tr('«{0}» no sirve en una aplicación web: descartado.', [s]));
        continue;
      }
      if (RegExp(
            r'^(import\s+[\w.]+(\s*,\s*[\w.]+)*|from\s+[\w.]+\s+import\s+[\w.*, ]+)$',
          ).hasMatch(s) &&
          !out.split('\n').contains(s)) {
        lines.add(s);
      }
    }
    if (lines.isNotEmpty) out = '${lines.join('\n')}\n$out';
    final methods = j['methods'];
    if (methods is Map) {
      for (final e in methods.entries) {
        final name = '${e.key}';
        if (!design.validName(name)) continue;
        if (TkUnit.lineOf(out, name) != null) {
          notes.add(tr('«{0}» ya tenía código: no se ha cambiado.', [name]));
          continue;
        }
        final m = e.value;
        final body = m is Map ? '${m['body'] ?? 'pass'}' : '$m';
        final param = m is Map ? '${m['param'] ?? ''}' : '';
        if (_touchesSecrets(body)) {
          notes.add(tr('«{0}» leía las credenciales: descartado.', [name]));
          continue;
        }
        out = TkUnit.ensureMethod(
          out,
          form,
          name,
          param: const {'event', 'value', 'item'}.contains(param) ? param : '',
          body: body.trim().isEmpty ? 'pass' : body,
        );
        added.add(name);
      }
    }
    return (out, added, notes);
  }

  /// Pide una ventana nueva ([fresh]) o un cambio sobre la que hay. Si la
  /// respuesta trae algo que no existe, se le devuelve el error una vez; lo
  /// que siga mal se descarta y se dice en las notas.
  static Future<TkAiChange> change(
    String prompt, {
    required TkDesign current,
    required String code,
    bool fresh = false,
    List<String> connections = const [],
    String? imageUrl,
  }) async {
    final context = fresh
        ? ''
        : 'Current design:\n${current.toJsonString()}\n\n'
              'Current code (keep it; add only what is new):\n${_clip(code)}\n\n'
              'Return the whole design with the change applied, keeping every '
              'component and event the request does not touch.\n\n';
    final text = '${context}Request: $prompt';
    final messages = <Map<String, Object?>>[
      {'role': 'system', 'content': _system(connections, current)},
      {
        'role': 'user',
        'content': imageUrl == null
            ? text
            : [
                {'type': 'text', 'text': text},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl},
                },
              ],
      },
    ];
    Map<String, Object?>? answer;
    ({TkDesign design, List<String> errors, List<String> notes})? checked;

    void read(String reply) {
      final j = _object(reply);
      final design = j?['design'];
      if (j == null || design is! Map) return;
      answer = j;
      checked = validate(
        design.cast<String, Object?>(),
        current: current,
        connections: connections,
      );
    }

    var reply = await _ai(messages);
    read(reply);
    if (checked == null || checked!.errors.isNotEmpty) {
      final why = checked == null
          ? 'Your answer was not the JSON object requested.'
          : 'These are not valid:\n- ${checked!.errors.join('\n- ')}';
      reply = await _ai([
        ...messages,
        {'role': 'assistant', 'content': reply},
        {
          'role': 'user',
          'content':
              '$why\nAnswer again with the whole JSON, using only what the catalog lists.',
        },
      ]);
      read(reply);
    }
    final result = checked;
    if (result == null || answer == null) {
      throw UserError(tr('La IA no devolvió una ventana válida.'));
    }
    final (merged, added, notes) = _merge(code, current, answer!);
    return TkAiChange(
      design: result.design,
      code: merged,
      summary: '${answer!['summary'] ?? ''}',
      notes: [
        ...result.notes,
        ...notes,
        for (final e in result.errors) tr('Descartado: {0}', [e]),
      ],
      methods: added,
    );
  }

  /// Escribe el cuerpo del método [method]. El resto no cambia.
  static Future<TkAiChange> handler(
    String prompt, {
    required TkDesign current,
    required String code,
    required String method,
    required String param,
    required String event,
    List<String> connections = const [],
  }) async {
    final messages = <Map<String, Object?>>[
      {
        'role': 'system',
        'content':
            '${_system(connections, current)}\n\nFor this request answer only: {"summary": "...", "body": "python statements of the method"}',
      },
      {
        'role': 'user',
        'content':
            'Current design:\n${current.toJsonString()}\n\n'
            'Current code:\n${_clip(code)}\n\n'
            'Write the body of the method $method, called by: $event.\n'
            'Request: $prompt',
      },
    ];
    var reply = await _ai(messages);
    var j = _object(reply);
    if (j == null || j['body'] is! String) {
      reply = await _ai([
        ...messages,
        {'role': 'assistant', 'content': reply},
        {'role': 'user', 'content': 'Answer only with {"summary", "body"}.'},
      ]);
      j = _object(reply);
    }
    final body = j?['body'];
    if (body is! String || body.trim().isEmpty) {
      throw UserError(tr('La IA no devolvió el código.'));
    }
    if (_touchesSecrets(body)) {
      throw UserError(tr('«{0}» leía las credenciales: descartado.', [method]));
    }
    return TkAiChange(
      design: current.clone(),
      code: TkUnit.setMethodBody(
        code,
        current.name,
        method,
        body,
        param: param,
      ),
      summary: '${j?['summary'] ?? ''}',
      methods: [method],
    );
  }
}
