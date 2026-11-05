import 'dart:convert';

import '../i18n/tr.dart';

/// Tipo de una propiedad del inspector de objetos.
enum TkPropType {
  text,
  multiline,
  integer,
  number,
  boolean,
  color,
  choice,

  /// Conexión guardada en Bases de datos, por su nombre.
  connection,

  /// Otro componente de esta ventana, de la clase [TkProp.refKind].
  reference,
}

/// Lado mínimo de un componente.
const tkMinSize = 8;

/// Destino de una aplicación: una ventana de tkinter o una aplicación web de
/// Flask. El diseño y el código (Python, con la misma clase) son los mismos.
const tkTargetDesktop = 'desktop';
const tkTargetWeb = 'web';

/// Escritorio con Electron y React: el mismo diseño, con el código en
/// JavaScript.
const tkTargetElectron = 'electron';

/// Componentes que ya tiene el destino Electron.
const tkElectronKinds = {
  'Label',
  'Button',
  'Entry',
  'Password',
  'Image',
  'Text',
  'Checkbutton',
  'Radiobutton',
  'Listbox',
  'Combobox',
  'Scale',
  'Frame',
  'HtmlView',
  'Treeview',
  'Progressbar',
  'PageControl',
  'StatusBar',
  'Menu',
  'Timer',
  'OpenDialog',
  'SaveDialog',
};

/// Extensión de Chrome (Manifest V3): la ventana emergente se diseña igual
/// y su código, en JavaScript, es el mismo de Electron.
const tkTargetChrome = 'chrome';

/// Web con Next.js: la página es el diseño, con el mismo código JavaScript.
const tkTargetNext = 'nextjs';

/// Escritorio en C++ con FLTK: el código del usuario, en C++.
const tkTargetCpp = 'cpp';

/// Componentes que ya tiene el destino C++ (FLTK).
const tkCppKinds = {
  'Label',
  'Button',
  'Entry',
  'Password',
  'Image',
  'Text',
  'Checkbutton',
  'Radiobutton',
  'Listbox',
  'Combobox',
  'Scale',
  'Frame',
  'Progressbar',
  'PageControl',
  'StatusBar',
  'Menu',
  'Timer',
  'OpenDialog',
  'SaveDialog',
};

/// Escritorio en Pascal con Lazarus (LCL): el código del usuario, en Object
/// Pascal, con los componentes de siempre (TLabel, TButton, TEdit…).
const tkTargetPascal = 'pascal';

/// Componentes que ya tiene el destino Pascal: los de C++.
const tkPascalKinds = tkCppKinds;

/// Aplicación de consola, sin ventana: un solo archivo (main.py, main.c,
/// main.cpp o main.pas) con la entrada y la salida en la pestaña Salida.
const tkTargetConsolePy = 'console_py';
const tkTargetConsoleC = 'console_c';
const tkTargetConsoleCpp = 'console_cpp';
const tkTargetConsolePas = 'console_pas';
const tkConsoleTargets = {
  tkTargetConsolePy,
  tkTargetConsoleC,
  tkTargetConsoleCpp,
  tkTargetConsolePas,
};

/// App de Flutter (móvil y escritorio), al estilo de FlutterFlow: varias
/// pantallas con su árbol de widgets y la lógica en Dart (lib/app.dart).
const tkTargetFlutter = 'flutter';

/// La misma app de Flutter, para escritorio (macOS, Windows o Linux).
const tkTargetFlutterDesktop = 'flutter_desktop';

/// Nombre del destino [target] para el usuario.
String tkTargetLabel(String target) => switch (target) {
  tkTargetWeb => tr('Web (Flask)'),
  tkTargetElectron => tr('Electron + React'),
  tkTargetChrome => tr('Extensión de Chrome'),
  tkTargetNext => tr('Web (Next.js)'),
  tkTargetCpp => tr('C++ (FLTK)'),
  tkTargetPascal => tr('Pascal (Lazarus)'),
  tkTargetFlutter => tr('Flutter (móvil)'),
  tkTargetFlutterDesktop => tr('Flutter (escritorio)'),
  tkTargetConsolePy => tr('Consola (Python)'),
  tkTargetConsoleC => tr('Consola (C)'),
  tkTargetConsoleCpp => tr('Consola (C++)'),
  tkTargetConsolePas => tr('Consola (Pascal)'),
  _ => tr('Escritorio (Python)'),
};

/// Componentes de una extensión de Chrome: los de Electron menos el menú
/// (una ventana emergente no tiene barra de menús).
final tkChromeKinds = {...tkElectronKinds}..remove('Menu');

/// Componentes que tiene el destino de [d] (null: todos).
Set<String>? tkTargetKinds(TkDesign d) => d.isCpp
    ? tkCppKinds
    : d.isPascal
    ? tkPascalKinds
    : d.isChrome || d.isNext
    ? tkChromeKinds
    : d.isElectron
    ? tkElectronKinds
    : null;

/// Por qué [kind] aún no está en el destino de JavaScript de [d] (null: sí
/// está, o el destino es Python).
String? tkJsGap(TkDesign d, String kind) {
  final kinds = tkTargetKinds(d);
  if (kinds == null || kinds.contains(kind)) return null;
  if (d.isCpp) {
    return tr('«{0}» todavía no está disponible en C++.', [
      tr(tkComponent(kind)?.label ?? kind),
    ]);
  }
  if (d.isPascal) {
    return tr('«{0}» todavía no está disponible en Pascal.', [
      tr(tkComponent(kind)?.label ?? kind),
    ]);
  }
  if (d.isNext) {
    return tr('«{0}» no está disponible en Next.js.', [
      tr(tkComponent(kind)?.label ?? kind),
    ]);
  }
  return d.isChrome
      ? tr('«{0}» no está disponible en las extensiones de Chrome.', [
          tr(tkComponent(kind)?.label ?? kind),
        ])
      : tkElectronGap(kind);
}

/// Por qué [kind] aún no está en Electron (null: sí está).
String? tkElectronGap(String kind) => tkElectronKinds.contains(kind)
    ? null
    : tr('«{0}» todavía no está disponible en Electron.', [
        tr(tkComponent(kind)?.label ?? kind),
      ]);

/// Palabras de C++ (y de FLTK) que no sirven como nombres.
const tkCppReserved = {
  'auto',
  'bool',
  'char',
  'double',
  'float',
  'int',
  'long',
  'namespace',
  'operator',
  'short',
  'signed',
  'sizeof',
  'struct',
  'template',
  'typedef',
  'typename',
  'union',
  'unsigned',
  'using',
  'virtual',
  'volatile',
  'main',
  'std',
  'Fl',
  'DmsForm',
};

/// Palabras de Pascal (en minúsculas: Pascal no distingue mayúsculas) y
/// propiedades de la ventana de la LCL que no sirven como nombres.
const tkPascalReserved = {
  'and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const',
  'constructor', 'destructor', 'div', 'do', 'downto', 'else', 'end',
  'except', 'exports', 'file', 'finalization', 'finally', 'for', 'function',
  'goto', 'if', 'implementation', 'in', 'inherited', 'initialization',
  'inline', 'interface', 'is', 'label', 'library', 'mod', 'nil', 'not',
  'object', 'of', 'on', 'operator', 'or', 'out', 'packed', 'procedure',
  'program', 'property', 'raise', 'record', 'repeat', 'resourcestring',
  'self', 'set', 'shl', 'shr', 'string', 'then', 'threadvar', 'to', 'try',
  'type', 'unit', 'until', 'uses', 'var', 'while', 'with', 'xor', 'result',
  'true', 'false', 'integer', 'boolean', 'double', 'char', 'application',
  // De TForm: un componente con ese nombre los taparía.
  'caption', 'color', 'font', 'width', 'height', 'left', 'top', 'name',
  'tag', 'text', 'menu', 'hint', 'parent', 'owner', 'visible', 'enabled',
  'close', 'show', 'hide', 'message', 'ask', 'title', 'design', 'dms',
  'components', 'controls', 'canvas', 'align', 'icon', 'position',
};

/// Palabras reservadas de JavaScript: no sirven como nombres.
const tkJsReserved = {
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'debugger',
  'default',
  'delete',
  'do',
  'else',
  'enum',
  'export',
  'extends',
  'false',
  'finally',
  'for',
  'function',
  'if',
  'implements',
  'import',
  'in',
  'instanceof',
  'interface',
  'let',
  'new',
  'null',
  'package',
  'private',
  'protected',
  'public',
  'return',
  'static',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'typeof',
  'var',
  'void',
  'while',
  'with',
  'yield',
  'FormDesign',
  'React',
  'h',
};

/// Propiedad de un componente. [option] es la opción de Tk que la recibe;
/// sin ella, la trata el generador (texto inicial, variables, elementos…).
class TkProp {
  const TkProp(
    this.key,
    this.label,
    this.type, {
    this.option,
    this.def,
    this.choices = const [],
    this.always = false,
    this.refKind,
    this.labels = const {},
  });
  final String key;
  final String label;
  final TkPropType type;
  final String? option;
  final Object? def;
  final List<String> choices;

  /// Se escribe aunque tenga el valor de serie, que aquí no es el de Tk.
  final bool always;

  /// Clase de componente a la que apunta una referencia.
  final String? refKind;

  /// Nombre que ve el usuario de cada opción de [choices] (marcado con
  /// markTr; sin él, la opción tal cual).
  final Map<String, String> labels;
}

/// Evento de un componente. Sin [sequences] es la opción `command`; con
/// ellas, un `bind`. [param] es el argumento del método además de `self`.
class TkEvent {
  const TkEvent(
    this.key,
    this.label,
    this.suffix, {
    this.sequences = const [],
    this.param = '',
  });
  final String key;
  final String label;

  /// Final del nombre del método de serie (`Button1_click`).
  final String suffix;
  final List<String> sequences;
  final String param;

  bool get isCommand => sequences.isEmpty;
}

/// Componente de la paleta.
class TkComponent {
  const TkComponent(
    this.kind,
    this.label,
    this.width,
    this.height,
    this.props,
    this.events, {
    this.ttk = false,
    this.container = false,
    this.visual = true,
  });

  /// Clase de Tk (`Button`, `Entry`…).
  final String kind;
  final String label;
  final int width, height;
  final List<TkProp> props;
  final List<TkEvent> events;

  /// Está en `tkinter.ttk`, no en `tkinter`.
  final bool ttk;

  /// Puede contener otros componentes.
  final bool container;

  /// Se ve en la ventana; si no, solo existe en el código, como los
  /// componentes no visuales de otros diseñadores.
  final bool visual;

  TkProp? prop(String key) => props.where((p) => p.key == key).firstOrNull;

  /// Puede ir dentro de un marco o de una página. Los no visuales, la barra
  /// de estado y el menú son siempre de la ventana.
  bool get nestable => visual && !tkDocked.contains(kind);
}

/// Componentes que se pegan a un borde de la ventana: su posición no cuenta.
const tkDocked = {'StatusBar', 'Menu', 'Ribbon'};

/// Alto de la fila de pestañas de un control de páginas: los componentes de
/// una página empiezan debajo.
const tkTabHeight = 24;

/// Opción de un menú: [path] es la ruta que recibe el método
/// (`Archivo/Abrir`); un separador no tiene ruta.
class TkMenuItem {
  const TkMenuItem(this.label, this.path, [this.items = const []]);
  const TkMenuItem.separator() : label = '-', path = '', items = const [];
  final String label;
  final String path;
  final List<TkMenuItem> items;

  bool get separator => path.isEmpty;
}

/// Opciones del texto de un menú: una por línea, con sangría para los
/// submenús y «-» para un separador.
List<TkMenuItem> tkMenuItems(String text) {
  final lines = <(int, String)>[
    for (final raw in text.replaceAll('\t', '  ').split('\n'))
      if (raw.trim().isNotEmpty)
        (raw.length - raw.trimLeft().length, raw.trim()),
  ];
  var at = 0;
  List<TkMenuItem> level(int indent, String prefix) {
    final out = <TkMenuItem>[];
    // Hasta que la sangría vuelve a un nivel superior o cambia.
    while (at < lines.length && lines[at].$1 == indent) {
      final (depth, label) = lines[at];
      at++;
      if (label == '-' || RegExp(r'^-{2,}$').hasMatch(label)) {
        out.add(const TkMenuItem.separator());
        continue;
      }
      final clean = label.replaceAll('/', '-');
      final path = prefix.isEmpty ? clean : '$prefix/$clean';
      final children = at < lines.length && lines[at].$1 > depth
          ? level(lines[at].$1, path)
          : <TkMenuItem>[];
      out.add(TkMenuItem(clean, path, children));
    }
    return out;
  }

  final out = <TkMenuItem>[];
  while (at < lines.length) {
    out.addAll(level(lines[at].$1, ''));
  }
  return out;
}

/// Rutas de las opciones que se pueden elegir (las hojas del menú).
List<String> tkMenuPaths(List<TkMenuItem> items) => [
  for (final i in items)
    if (!i.separator) ...(i.items.isEmpty ? [i.path] : tkMenuPaths(i.items)),
];

/// Botón de una cinta de opciones: [path] es la ruta que recibe el método
/// (`Inicio/Portapapeles/Pegar`) y [glyph], el símbolo que lo ilustra.
class TkRibbonButton {
  const TkRibbonButton(this.label, this.glyph, this.path);
  final String label, glyph, path;
}

/// Grupo de botones de una pestaña de la cinta.
class TkRibbonGroup {
  const TkRibbonGroup(this.label, this.buttons);
  final String label;
  final List<TkRibbonButton> buttons;
}

/// Pestaña de la cinta de opciones.
class TkRibbonTab {
  const TkRibbonTab(this.label, this.groups);
  final String label;
  final List<TkRibbonGroup> groups;
}

/// Símbolos de los botones de la cinta, por nombre. Todos del plano básico
/// de Unicode: el Tk 8.6 no dibuja los emoji de fuera de él.
const tkRibbonGlyphs = {
  'new': '☐',
  'open': '⏏',
  'save': '⤓',
  'print': '⎙',
  'cut': '✂',
  'copy': '⧉',
  'paste': '⎘',
  'clipboard': '⎘',
  'bold': 'B',
  'italic': 'I',
  'underline': 'U',
  'font': 'A',
  'table': '▦',
  'image': '▣',
  'chart': '▥',
  'find': '⌕',
  'settings': '⚙',
  'help': '?',
  'info': 'ℹ',
  'undo': '↶',
  'redo': '↷',
  'refresh': '⟳',
  'delete': '✖',
  'add': '✚',
  'edit': '✎',
  'user': '☺',
  'mail': '✉',
  'calendar': '▤',
  'home': '⌂',
  'play': '▶',
  'stop': '■',
  'star': '★',
  'check': '✔',
  'up': '▲',
  'down': '▼',
  'zoom': '⊕',
  'left': '◀',
  'right': '▶',
};

/// Símbolo de [icon]: un nombre de [tkRibbonGlyphs] o un carácter tal cual.
String tkRibbonGlyph(String icon) {
  final i = icon.trim();
  if (i.isEmpty) return '';
  return tkRibbonGlyphs[i.toLowerCase()] ?? (i.runes.length <= 2 ? i : '');
}

/// Pestañas de la cinta a partir de su texto: las líneas sin sangría son
/// pestañas, con una sangría grupos y con más, botones (`Pegar | paste`).
List<TkRibbonTab> tkRibbonTabs(String text) {
  final tabs = <(String, List<(String, List<TkRibbonButton>)>)>[];
  int? tabIndent, groupIndent;
  String clean(String s) => s.trim().replaceAll('/', '-');
  for (final raw in text.replaceAll('\t', '  ').split('\n')) {
    if (raw.trim().isEmpty) continue;
    final indent = raw.length - raw.trimLeft().length;
    final line = raw.trim();
    if (tabIndent == null || indent <= tabIndent) {
      tabIndent = indent;
      groupIndent = null;
      tabs.add((clean(line), []));
      continue;
    }
    final groups = tabs.last.$2;
    if (groupIndent == null || indent <= groupIndent) {
      groupIndent = indent;
      groups.add((clean(line), []));
      continue;
    }
    final bar = line.lastIndexOf('|');
    final label = clean(bar < 0 ? line : line.substring(0, bar));
    final glyph = bar < 0 ? '' : tkRibbonGlyph(line.substring(bar + 1));
    if (label.isEmpty) continue;
    final tab = tabs.last.$1;
    final (group, buttons) = groups.last;
    buttons.add(TkRibbonButton(label, glyph, '$tab/$group/$label'));
  }
  return [
    for (final (label, groups) in tabs)
      TkRibbonTab(label, [
        for (final (g, buttons) in groups) TkRibbonGroup(g, buttons),
      ]),
  ];
}

/// Rutas de los botones de la cinta.
List<String> tkRibbonPaths(List<TkRibbonTab> tabs) => [
  for (final t in tabs)
    for (final g in t.groups)
      for (final b in g.buttons) b.path,
];

/// Cabeceras de una integración API: una por línea, `Nombre: valor`.
List<(String, String)> tkApiHeaders(String text) => [
  for (final l in text.split('\n'))
    if (l.contains(':') && l.split(':').first.trim().isNotEmpty)
      (l.split(':').first.trim(), l.substring(l.indexOf(':') + 1).trim()),
];

/// Páginas de un control de páginas.
List<String> tkPages(TkWidget w) {
  final pages = [
    for (final l in w.text('pages').split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];
  return pages.isEmpty ? const ['1'] : pages;
}

// ----------------------------------------------------------- propiedades
final _bg = TkProp(
  'bg',
  markTr('Color de fondo'),
  TkPropType.color,
  option: 'bg',
  def: '',
);
final _fg = TkProp(
  'fg',
  markTr('Color del texto'),
  TkPropType.color,
  option: 'fg',
  def: '',
);
final _fontFamily = TkProp(
  'font_family',
  markTr('Fuente'),
  TkPropType.text,
  def: '',
);
final _fontSize = TkProp(
  'font_size',
  markTr('Tamaño de fuente'),
  TkPropType.integer,
  def: 0,
);
final _fontBold = TkProp(
  'font_bold',
  markTr('Negrita'),
  TkPropType.boolean,
  def: false,
);
final _fontItalic = TkProp(
  'font_italic',
  markTr('Cursiva'),
  TkPropType.boolean,
  def: false,
);
final _font = [_fontFamily, _fontSize, _fontBold, _fontItalic];
final _text = TkProp(
  'text',
  markTr('Texto'),
  TkPropType.text,
  option: 'text',
  def: '',
);
final _initial = TkProp(
  'text',
  markTr('Texto inicial'),
  TkPropType.text,
  def: '',
);
final _state = TkProp(
  'state',
  markTr('Estado'),
  TkPropType.choice,
  option: 'state',
  def: 'normal',
  choices: const ['normal', 'disabled'],
);
final _relief = TkProp(
  'relief',
  markTr('Relieve'),
  TkPropType.choice,
  option: 'relief',
  def: '',
  choices: const ['', 'flat', 'raised', 'sunken', 'groove', 'ridge', 'solid'],
);
final _justify = TkProp(
  'justify',
  markTr('Justificación'),
  TkPropType.choice,
  option: 'justify',
  def: '',
  choices: const ['', 'left', 'center', 'right'],
);

// --------------------------------------------------------------- eventos
final _command = TkEvent('command', markTr('Al pulsar'), 'click');
final _mouse = [
  TkEvent(
    'click',
    markTr('Clic'),
    'mouse_down',
    sequences: const ['<Button-1>'],
    param: 'event',
  ),
  TkEvent(
    'double',
    markTr('Doble clic'),
    'double_click',
    sequences: const ['<Double-Button-1>'],
    param: 'event',
  ),
  // En macOS el botón derecho es el 2; en el resto, el 3.
  TkEvent(
    'right',
    markTr('Clic derecho'),
    'right_click',
    sequences: const ['<Button-2>', '<Button-3>'],
    param: 'event',
  ),
  TkEvent(
    'enter',
    markTr('Entrar el ratón'),
    'enter',
    sequences: const ['<Enter>'],
    param: 'event',
  ),
  TkEvent(
    'leave',
    markTr('Salir el ratón'),
    'leave',
    sequences: const ['<Leave>'],
    param: 'event',
  ),
];
final _keyboard = [
  TkEvent(
    'focus_in',
    markTr('Recibir el foco'),
    'focus_in',
    sequences: const ['<FocusIn>'],
    param: 'event',
  ),
  TkEvent(
    'focus_out',
    markTr('Perder el foco'),
    'focus_out',
    sequences: const ['<FocusOut>'],
    param: 'event',
  ),
  TkEvent(
    'key',
    markTr('Tecla pulsada'),
    'key',
    sequences: const ['<KeyPress>'],
    param: 'event',
  ),
  TkEvent(
    'key_up',
    markTr('Tecla soltada'),
    'key_up',
    sequences: const ['<KeyRelease>'],
    param: 'event',
  ),
  TkEvent(
    'enter_key',
    markTr('Tecla Intro'),
    'return',
    sequences: const ['<Return>'],
    param: 'event',
  ),
];
final _canvasMouse = [
  TkEvent(
    'drag',
    markTr('Arrastrar'),
    'drag',
    sequences: const ['<B1-Motion>'],
    param: 'event',
  ),
  TkEvent(
    'release',
    markTr('Soltar el botón'),
    'mouse_up',
    sequences: const ['<ButtonRelease-1>'],
    param: 'event',
  ),
  TkEvent(
    'motion',
    markTr('Mover el ratón'),
    'motion',
    sequences: const ['<Motion>'],
    param: 'event',
  ),
];

/// Paleta de componentes, en el orden en que se muestra.
final tkComponents = <TkComponent>[
  TkComponent('Label', markTr('Etiqueta'), 96, 24, [
    _text,
    _bg,
    _fg,
    ..._font,
    TkProp(
      'anchor',
      markTr('Alineación'),
      TkPropType.choice,
      option: 'anchor',
      def: '',
      choices: const ['', 'w', 'center', 'e', 'n', 's'],
    ),
    _justify,
    _relief,
    TkProp(
      'wraplength',
      markTr('Ajuste de línea'),
      TkPropType.integer,
      option: 'wraplength',
      def: 0,
    ),
  ], _mouse),
  TkComponent(
    'Button',
    markTr('Botón'),
    96,
    32,
    [_text, _bg, _fg, ..._font, _state, _relief],
    [_command, ..._mouse],
  ),
  TkComponent(
    'Entry',
    markTr('Campo de texto'),
    152,
    24,
    [
      _initial,
      _bg,
      _fg,
      ..._font,
      _justify,
      TkProp(
        'show',
        markTr('Ocultar con'),
        TkPropType.text,
        option: 'show',
        def: '',
      ),
      TkProp(
        'state',
        markTr('Estado'),
        TkPropType.choice,
        option: 'state',
        def: 'normal',
        choices: const ['normal', 'disabled', 'readonly'],
      ),
      TkProp(
        'data_grid',
        markTr('Tabla enlazada'),
        TkPropType.reference,
        def: '',
        refKind: 'Treeview',
      ),
      TkProp('data_field', markTr('Campo enlazado'), TkPropType.text, def: ''),
    ],
    [..._keyboard, ..._mouse],
  ),
  TkComponent(
    'Password',
    markTr('Contraseña'),
    152,
    24,
    [
      TkProp(
        'hint',
        markTr('Texto de ayuda (vacío)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'reveal',
        markTr('Botón para ver la contraseña'),
        TkPropType.boolean,
        def: true,
      ),
      TkProp(
        'maxlength',
        markTr('Longitud máxima (0 = sin límite)'),
        TkPropType.integer,
        def: 0,
      ),
      _bg,
      _fg,
      ..._font,
      TkProp(
        'state',
        markTr('Estado'),
        TkPropType.choice,
        def: 'normal',
        choices: const ['normal', 'disabled', 'readonly'],
      ),
    ],
    [..._keyboard, ..._mouse],
  ),
  TkComponent('Image', markTr('Imagen'), 160, 120, [
    TkProp(
      'file',
      markTr('Archivo (en la carpeta images del proyecto)'),
      TkPropType.text,
      def: '',
    ),
    TkProp(
      'fit',
      markTr('Ajuste'),
      TkPropType.choice,
      def: 'contain',
      choices: const ['none', 'contain', 'cover', 'stretch'],
      labels: {
        'none': markTr('Tamaño original'),
        'contain': markTr('Entera, sin deformar'),
        'cover': markTr('Rellenar, recortando'),
        'stretch': markTr('Estirar'),
      },
    ),
    _bg,
    TkProp('border', markTr('Borde'), TkPropType.boolean, def: false),
  ], _mouse),
  TkComponent(
    'Text',
    markTr('Texto largo'),
    224,
    120,
    [
      TkProp('text', markTr('Texto inicial'), TkPropType.multiline, def: ''),
      _bg,
      _fg,
      ..._font,
      TkProp(
        'wrap',
        markTr('Ajuste de línea'),
        TkPropType.choice,
        option: 'wrap',
        def: 'word',
        always: true,
        choices: const ['word', 'char', 'none'],
      ),
      // Se aplica después de escribir el texto inicial.
      TkProp(
        'state',
        markTr('Estado'),
        TkPropType.choice,
        def: 'normal',
        choices: const ['normal', 'disabled'],
      ),
    ],
    [..._keyboard, ..._mouse],
  ),
  TkComponent(
    'Checkbutton',
    markTr('Casilla'),
    120,
    24,
    [
      _text,
      _bg,
      _fg,
      ..._font,
      _state,
      TkProp('checked', markTr('Marcada'), TkPropType.boolean, def: false),
    ],
    [_command, ..._mouse],
  ),
  TkComponent(
    'Radiobutton',
    markTr('Opción'),
    120,
    24,
    [
      _text,
      _bg,
      _fg,
      ..._font,
      _state,
      TkProp('group', markTr('Grupo'), TkPropType.text, def: 'group1'),
      TkProp('value', markTr('Valor'), TkPropType.text, def: ''),
      TkProp('checked', markTr('Marcada'), TkPropType.boolean, def: false),
    ],
    [_command, ..._mouse],
  ),
  TkComponent(
    'Listbox',
    markTr('Lista'),
    160,
    120,
    [
      TkProp(
        'items',
        markTr('Elementos (uno por línea)'),
        TkPropType.multiline,
        def: '',
      ),
      _bg,
      _fg,
      ..._font,
      TkProp(
        'selectmode',
        markTr('Selección'),
        TkPropType.choice,
        option: 'selectmode',
        def: 'browse',
        choices: const ['browse', 'single', 'multiple', 'extended'],
      ),
    ],
    [
      TkEvent(
        'select',
        markTr('Al seleccionar'),
        'select',
        sequences: const ['<<ListboxSelect>>'],
        param: 'event',
      ),
      ..._keyboard,
      ..._mouse,
    ],
  ),
  TkComponent(
    'Combobox',
    markTr('Lista desplegable'),
    160,
    24,
    [
      TkProp(
        'items',
        markTr('Elementos (uno por línea)'),
        TkPropType.multiline,
        def: '',
      ),
      _initial,
      ..._font,
      _justify,
      TkProp(
        'state',
        markTr('Estado'),
        TkPropType.choice,
        option: 'state',
        def: 'normal',
        choices: const ['normal', 'readonly', 'disabled'],
      ),
    ],
    [
      TkEvent(
        'select',
        markTr('Al seleccionar'),
        'select',
        sequences: const ['<<ComboboxSelected>>'],
        param: 'event',
      ),
      ..._keyboard,
      ..._mouse,
    ],
    ttk: true,
  ),
  TkComponent(
    'Scale',
    markTr('Deslizador'),
    200,
    48,
    [
      TkProp(
        'label',
        markTr('Título'),
        TkPropType.text,
        option: 'label',
        def: '',
      ),
      TkProp(
        'from',
        markTr('Desde'),
        TkPropType.number,
        option: 'from_',
        def: 0,
      ),
      TkProp('to', markTr('Hasta'), TkPropType.number, option: 'to', def: 100),
      TkProp(
        'resolution',
        markTr('Paso'),
        TkPropType.number,
        option: 'resolution',
        def: 1,
      ),
      TkProp('value', markTr('Valor'), TkPropType.number, def: 0),
      TkProp(
        'orient',
        markTr('Orientación'),
        TkPropType.choice,
        option: 'orient',
        def: 'horizontal',
        always: true,
        choices: const ['horizontal', 'vertical'],
      ),
      TkProp(
        'showvalue',
        markTr('Mostrar el valor'),
        TkPropType.boolean,
        option: 'showvalue',
        def: true,
      ),
      _bg,
      _fg,
    ],
    [
      TkEvent('command', markTr('Al cambiar'), 'change', param: 'value'),
      ..._mouse,
    ],
  ),
  TkComponent(
    'Frame',
    markTr('Marco'),
    200,
    120,
    [
      _bg,
      _relief,
      TkProp('bd', markTr('Borde'), TkPropType.integer, option: 'bd', def: 0),
    ],
    _mouse,
    container: true,
  ),
  TkComponent(
    'Canvas',
    markTr('Lienzo'),
    200,
    160,
    [_bg],
    [..._mouse, ..._canvasMouse],
  ),
  TkComponent(
    'Chart',
    markTr('Gráfico'),
    360,
    220,
    [
      TkProp(
        'kind',
        markTr('Tipo'),
        TkPropType.choice,
        def: 'line',
        choices: const ['line', 'area', 'bar', 'candles'],
        labels: {
          'line': markTr('Líneas'),
          'area': markTr('Áreas'),
          'bar': markTr('Barras'),
          'candles': markTr('Velas (bolsa)'),
        },
      ),
      TkProp('title', markTr('Título'), TkPropType.text, def: ''),
      TkProp('xlabel', markTr('Título del eje X'), TkPropType.text, def: ''),
      TkProp('ylabel', markTr('Título del eje Y'), TkPropType.text, def: ''),
      TkProp('legend', markTr('Leyenda'), TkPropType.boolean, def: true),
      TkProp('grid', markTr('Rejilla'), TkPropType.boolean, def: true),
      TkProp('decimals', markTr('Decimales'), TkPropType.integer, def: 0),
      TkProp(
        'prefix',
        markTr('Prefijo de los valores'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'suffix',
        markTr('Sufijo de los valores (p. ej. « €»)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'maxpoints',
        markTr('Puntos como máximo (0 = todos)'),
        TkPropType.integer,
        def: 0,
      ),
    ],
    [
      TkEvent(
        'point',
        markTr('Al hacer clic en un punto'),
        'point',
        param: 'point',
      ),
    ],
  ),
  TkComponent(
    'HtmlView',
    markTr('Vista HTML'),
    420,
    300,
    [
      TkProp('html', markTr('HTML'), TkPropType.multiline, def: ''),
      TkProp(
        'full_page',
        markTr('Página completa (web)'),
        TkPropType.boolean,
        def: false,
      ),
      _bg,
      TkProp(
        'font_size',
        markTr('Tamaño de letra'),
        TkPropType.integer,
        def: 0,
      ),
    ],
    [
      TkEvent(
        'action',
        markTr('Al pulsar un enlace o enviar un formulario'),
        'action',
        param: 'action',
      ),
    ],
  ),
  TkComponent(
    'Treeview',
    markTr('Tabla de datos'),
    320,
    160,
    [
      TkProp(
        'source',
        markTr('Fuente de datos'),
        TkPropType.reference,
        def: '',
        refKind: 'Connection',
      ),
      TkProp('query', markTr('Consulta SQL'), TkPropType.multiline, def: ''),
      TkProp(
        'columns',
        markTr('Columnas (campo|título|ancho)'),
        TkPropType.multiline,
        def: '',
      ),
      TkProp('limit', markTr('Límite'), TkPropType.integer, def: 200),
      TkProp('order', markTr('Orden'), TkPropType.text, def: ''),
      TkProp(
        'autoload',
        markTr('Cargar al abrir'),
        TkPropType.boolean,
        def: true,
      ),
    ],
    [
      TkEvent(
        'select',
        markTr('Al seleccionar'),
        'select',
        sequences: const ['<<TreeviewSelect>>'],
        param: 'event',
      ),
      ..._mouse,
    ],
    ttk: true,
  ),
  TkComponent(
    'Progressbar',
    markTr('Barra de progreso'),
    200,
    20,
    [
      TkProp(
        'value',
        markTr('Valor'),
        TkPropType.number,
        option: 'value',
        def: 0,
      ),
      TkProp(
        'maximum',
        markTr('Máximo'),
        TkPropType.number,
        option: 'maximum',
        def: 100,
      ),
      TkProp(
        'mode',
        markTr('Modo'),
        TkPropType.choice,
        option: 'mode',
        def: 'determinate',
        choices: const ['determinate', 'indeterminate'],
      ),
      TkProp(
        'orient',
        markTr('Orientación'),
        TkPropType.choice,
        option: 'orient',
        def: 'horizontal',
        choices: const ['horizontal', 'vertical'],
      ),
    ],
    _mouse,
    ttk: true,
  ),
  TkComponent(
    'PageControl',
    markTr('Control de páginas'),
    320,
    200,
    [
      TkProp(
        'pages',
        markTr('Páginas (una por línea)'),
        TkPropType.multiline,
        def: 'Página 1\nPágina 2',
      ),
      TkProp('active', markTr('Página activa'), TkPropType.integer, def: 0),
      _bg,
    ],
    [
      TkEvent(
        'change',
        markTr('Al cambiar de página'),
        'change',
        sequences: const ['<<NotebookTabChanged>>'],
        param: 'event',
      ),
      ..._mouse,
    ],
    container: true,
  ),
  TkComponent('StatusBar', markTr('Barra de estado'), 400, 24, [
    _text,
    TkProp(
      'icon',
      markTr('Icono (nombre, como en la cinta, o un carácter)'),
      TkPropType.text,
      def: '',
    ),
    _bg,
    _fg,
    ..._font,
  ], _mouse),
  TkComponent(
    'Ribbon',
    markTr('Cinta de opciones'),
    400,
    92,
    [
      TkProp(
        'items',
        markTr('Pestañas, grupos y botones (sangría; «Botón | icono»)'),
        TkPropType.multiline,
        def:
            'Inicio\n  Portapapeles\n    Pegar | paste\n    Copiar | copy\n    Cortar | cut\n  Fuente\n    Negrita | bold\n    Cursiva | italic\nInsertar\n  Ilustraciones\n    Imagen | image\n    Gráfico | chart',
      ),
      TkProp('active', markTr('Pestaña activa'), TkPropType.integer, def: 0),
    ],
    [
      TkEvent('command', markTr('Al pulsar un botón'), 'click', param: 'item'),
      TkEvent('change', markTr('Al cambiar de pestaña'), 'change'),
    ],
  ),
  TkComponent(
    'Menu',
    markTr('Menú'),
    32,
    32,
    [
      TkProp(
        'items',
        markTr('Opciones (una por línea; sangría = submenú; - = separador)'),
        TkPropType.multiline,
        def: 'Archivo\n  Salir\nAyuda\n  Acerca de',
      ),
    ],
    [
      TkEvent(
        'command',
        markTr('Al elegir una opción'),
        'click',
        param: 'item',
      ),
    ],
    visual: false,
  ),
  TkComponent(
    'Timer',
    markTr('Temporizador'),
    32,
    32,
    [
      TkProp(
        'interval',
        markTr('Intervalo (ms)'),
        TkPropType.integer,
        def: 1000,
      ),
      TkProp('enabled', markTr('Activo'), TkPropType.boolean, def: true),
    ],
    [TkEvent('command', markTr('Cada intervalo'), 'timer')],
    visual: false,
  ),
  TkComponent(
    'RestClient',
    markTr('Integración API'),
    32,
    32,
    [
      TkProp('base_url', markTr('URL base'), TkPropType.text, def: ''),
      TkProp(
        'auth',
        markTr('Autenticación'),
        TkPropType.choice,
        def: 'none',
        choices: const ['none', 'bearer', 'basic', 'header'],
        labels: {
          'none': markTr('Ninguna'),
          'bearer': markTr('Token (Bearer)'),
          'basic': markTr('Básica (usuario y contraseña)'),
          'header': markTr('Clave en una cabecera'),
        },
      ),
      TkProp(
        'token_env',
        markTr('Variable con el token o la clave'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'token',
        markTr('Token o clave (mejor en una variable)'),
        TkPropType.text,
        def: '',
      ),
      TkProp('user', markTr('Usuario (básica)'), TkPropType.text, def: ''),
      TkProp(
        'password_env',
        markTr('Variable con la contraseña (básica)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'header_name',
        markTr('Cabecera de la clave'),
        TkPropType.text,
        def: 'X-API-Key',
      ),
      TkProp(
        'headers',
        markTr('Cabeceras (Nombre: valor; {{variable}})'),
        TkPropType.multiline,
        def: '',
      ),
      TkProp(
        'timeout',
        markTr('Tiempo máximo (s)'),
        TkPropType.integer,
        def: 30,
      ),
    ],
    [
      TkEvent(
        'done',
        markTr('Al terminar una llamada'),
        'done',
        param: 'result',
      ),
      TkEvent('error', markTr('Si falla una llamada'), 'error', param: 'error'),
    ],
    visual: false,
  ),
  TkComponent(
    'TrayIcon',
    markTr('Icono de bandeja'),
    32,
    32,
    [
      TkProp(
        'tooltip',
        markTr('Texto al pasar el ratón'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'icon',
        markTr('Imagen (ruta en el proyecto; vacía = una de serie)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'items',
        markTr('Menú (una opción por línea; - = separador)'),
        TkPropType.multiline,
        def: 'Mostrar\n-\nSalir',
      ),
    ],
    [
      TkEvent('click', markTr('Al hacer clic en el icono'), 'click'),
      TkEvent(
        'command',
        markTr('Al elegir una opción del menú'),
        'menu',
        param: 'item',
      ),
    ],
    visual: false,
  ),
  TkComponent(
    'OpenDialog',
    markTr('Diálogo Abrir'),
    32,
    32,
    [
      TkProp('title', markTr('Título'), TkPropType.text, def: ''),
      TkProp(
        'filter',
        markTr('Tipos (una línea: «Texto|*.txt» o «Imágenes|*.png;*.jpg»)'),
        TkPropType.multiline,
        def: '',
      ),
      TkProp(
        'defaultext',
        markTr('Extensión por defecto'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'initialdir',
        markTr('Carpeta inicial (vacía = la última)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'multiple',
        markTr('Elegir varios archivos'),
        TkPropType.boolean,
        def: false,
      ),
    ],
    [
      TkEvent(
        'select',
        markTr('Al elegir un archivo'),
        'select',
        param: 'path',
      ),
    ],
    visual: false,
  ),
  TkComponent(
    'SaveDialog',
    markTr('Diálogo Guardar'),
    32,
    32,
    [
      TkProp('title', markTr('Título'), TkPropType.text, def: ''),
      TkProp(
        'filter',
        markTr('Tipos (una línea: «Texto|*.txt» o «Imágenes|*.png;*.jpg»)'),
        TkPropType.multiline,
        def: '',
      ),
      TkProp(
        'defaultext',
        markTr('Extensión por defecto'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'initialdir',
        markTr('Carpeta inicial (vacía = la última)'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'filename',
        markTr('Nombre del archivo'),
        TkPropType.text,
        def: '',
      ),
      TkProp(
        'overwrite',
        markTr('Preguntar antes de sobrescribir'),
        TkPropType.boolean,
        def: true,
      ),
    ],
    [
      TkEvent(
        'select',
        markTr('Al elegir un archivo'),
        'select',
        param: 'path',
      ),
    ],
    visual: false,
  ),
  TkComponent(
    'AiAssistant',
    markTr('Asistente IA'),
    32,
    32,
    [
      TkProp(
        'model',
        markTr('Modelo de Claude'),
        TkPropType.choice,
        def: 'claude-opus-5-5',
        choices: const [
          'claude-opus-5-5',
          'claude-sonnet-5-5',
          'claude-haiku-5-5',
          'claude-fable-5-1',
        ],
      ),
      TkProp(
        'system',
        markTr('Instrucciones (cómo debe responder)'),
        TkPropType.multiline,
        def: '',
      ),
      TkProp(
        'effort',
        markTr('Esfuerzo'),
        TkPropType.choice,
        def: 'medium',
        choices: const ['low', 'medium', 'high', 'xhigh'],
      ),
      TkProp(
        'max_tokens',
        markTr('Longitud máxima de la respuesta (tokens)'),
        TkPropType.integer,
        def: 16000,
      ),
    ],
    [
      TkEvent(
        'done',
        markTr('Al llegar la respuesta'),
        'done',
        param: 'result',
      ),
      TkEvent('error', markTr('Si falla la petición'), 'error', param: 'error'),
    ],
    visual: false,
  ),
  TkComponent(
    'PdfReport',
    markTr('Informe PDF'),
    32,
    32,
    [
      TkProp('title', markTr('Título del documento'), TkPropType.text, def: ''),
      TkProp(
        'filename',
        markTr('Nombre del archivo'),
        TkPropType.text,
        def: 'informe.pdf',
      ),
      TkProp(
        'orientation',
        markTr('Orientación'),
        TkPropType.choice,
        def: 'portrait',
        choices: const ['portrait', 'landscape'],
      ),
      TkProp('author', markTr('Autor'), TkPropType.text, def: ''),
      TkProp(
        'page_numbers',
        markTr('Números de página'),
        TkPropType.boolean,
        def: true,
      ),
    ],
    const [],
    visual: false,
  ),
  TkComponent(
    'ExcelReport',
    markTr('Informe Excel'),
    32,
    32,
    [
      TkProp(
        'filename',
        markTr('Nombre del archivo'),
        TkPropType.text,
        def: 'informe.xlsx',
      ),
      TkProp('sheet', markTr('Primera hoja'), TkPropType.text, def: 'Hoja1'),
    ],
    const [],
    visual: false,
  ),
  TkComponent(
    'Connection',
    markTr('Conexión de datos'),
    32,
    32,
    [TkProp('connection', markTr('Conexión'), TkPropType.connection, def: '')],
    const [],
    visual: false,
  ),
];

/// Componente de la clase [kind] (null si no existe).
TkComponent? tkComponent(String kind) =>
    tkComponents.where((c) => c.kind == kind).firstOrNull;

/// Eventos de la ventana.
final tkFormEvents = <TkEvent>[
  TkEvent('create', markTr('Al abrir'), 'create'),
  TkEvent('close', markTr('Al cerrar'), 'close'),
  TkEvent(
    'key',
    markTr('Tecla pulsada'),
    'key',
    sequences: const ['<KeyPress>'],
    param: 'event',
  ),
  TkEvent(
    'resize',
    markTr('Al cambiar de tamaño'),
    'resize',
    sequences: const ['<Configure>'],
    param: 'event',
  ),
];

/// Propiedades de la ventana (las que no son posición ni tamaño).
final tkFormTitle = TkProp(
  'title',
  markTr('Título'),
  TkPropType.text,
  def: 'Form1',
);
final tkFormBg = TkProp(
  'bg',
  markTr('Color de fondo'),
  TkPropType.color,
  def: '#f0f0f0',
);
final tkFormResizable = TkProp(
  'resizable',
  markTr('Redimensionable'),
  TkPropType.boolean,
  def: false,
);
final tkFormTopmost = TkProp(
  'topmost',
  markTr('Siempre encima'),
  TkPropType.boolean,
  def: false,
);

/// Dónde se abre la ventana. Las ventanas nuevas se centran; las que ya
/// existían siguen donde las ponga el sistema.
final tkFormPosition = TkProp(
  'position',
  markTr('Posición'),
  TkPropType.choice,
  def: 'default',
  choices: const ['default', 'center', 'manual'],
  labels: {
    'default': markTr('Por defecto'),
    'center': markTr('Centrada en la pantalla'),
    'manual': markTr('Manual'),
  },
);
final tkFormLeft = TkProp(
  'left',
  markTr('Izquierda'),
  TkPropType.integer,
  def: 0,
);
final tkFormTop = TkProp('top', markTr('Arriba'), TkPropType.integer, def: 0);
final tkFormProps = [
  tkFormTitle,
  tkFormBg,
  tkFormPosition,
  tkFormLeft,
  tkFormTop,
  tkFormResizable,
  tkFormTopmost,
];

/// Propiedades de la ventana que solo cuentan con la posición manual.
const tkFormManualProps = {'left', 'top'};

/// Mensaje de una unidad sin la clase de la ventana.
String tkMissingClass(String form) =>
    tr('El código debe definir la clase {0}(FormDesign).', [form]);

/// Nombres que no puede tener un componente ni un método: palabras de
/// Python y lo que usa la clase generada.
const tkReserved = {
  'False',
  'None',
  'True',
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'class',
  'continue',
  'def',
  'del',
  'elif',
  'else',
  'except',
  'finally',
  'for',
  'from',
  'global',
  'if',
  'import',
  'in',
  'is',
  'lambda',
  'nonlocal',
  'not',
  'or',
  'pass',
  'raise',
  'return',
  'self',
  'try',
  'while',
  'with',
  'yield',
  'tk',
  'ttk',
  'root',
  'run',
  'FormDesign',
  'ColorButton',
  'DesignTimer',
  'DesignRibbon',
  'DesignStatus',
  'DesignTray',
  'DesignPassword',
  'DesignImage',
  'DesignOpenDialog',
  'DesignSaveDialog',
  'GLYPHS',
  'ApiClient',
  'ApiError',
};

/// ¿Sirve [s] como identificador en el archivo generado?
bool tkValidName(String s) =>
    RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(s) && !tkReserved.contains(s);

/// Nombres que además usa el archivo de una aplicación web.
const tkWebReserved = {
  'DataError',
  'DesignTimer',
  'WebMenu',
  'WebPages',
  'WebRibbon',
  'WebStatus',
  'WebNoTray',
  'WebImage',
  'WebSaveDialog',
  'WebOpenDialog',
  'GLYPHS',
  'WebProgress',
  'ErpClient',
  'Flask',
  'KEY_CHARS',
  'LOCAL_HOSTS',
  'MAX_FORMS',
  'OrderedDict',
  'PAGE',
  'SqlClient',
  'WEB_CLASSES',
  'WIDGETS',
  'WebChoice',
  'WebEntry',
  'WebEvent',
  'WebForm',
  'WebGrid',
  'WebListbox',
  'WebRoot',
  'WebScale',
  'WebText',
  'WebVar',
  'WebWidget',
  'abort',
  'app',
  'concurrent',
  'create_app',
  'css_color',
  'css_font',
  'g',
  'hmac',
  'importlib',
  'json',
  'jsonify',
  'logging',
  'make_server',
  'notify',
  'os',
  're',
  'request',
  'secrets',
  'serve',
  'sys',
  'threading',
  'traceback',
  'types',
  'urllib',
  'value',
  'watch_studio',
};

/// Eventos sin equivalente en una página: se envían al servidor uno a uno y
/// arrastrar o mover el ratón serían cientos de peticiones por segundo.
const tkWebNoEvents = {'drag', 'motion', 'point'};

/// Eventos de la ventana sin equivalente en una página.
const tkWebNoFormEvents = {'close', 'resize'};

/// Propiedades de la ventana sin equivalente en una página.
const tkWebNoFormProps = {'resizable', 'topmost'};

/// Componentes sin equivalente en una página.
const tkWebNoKinds = {'Canvas', 'TrayIcon', 'OpenDialog'};

/// ¿Tiene equivalente web el evento [e] de un componente ([form]: la ventana)?
bool tkWebHasEvent(TkEvent e, {bool form = false}) =>
    !(form ? tkWebNoFormEvents : tkWebNoEvents).contains(e.key);

/// Por qué el componente [kind] no funciona igual en una aplicación web (null
/// si funciona).
String? tkWebGap(String kind) => switch (kind) {
  'Canvas' => tr(
    'En una aplicación web el lienzo no dibuja: se ve el recuadro vacío, porque el código corre en el servidor y sus métodos de dibujo no existen.',
  ),
  'TrayIcon' => tr(
    'Una página web no puede poner un icono en la barra del sistema: en una aplicación web este componente no hace nada.',
  ),
  'OpenDialog' => tr(
    'En una aplicación web el código corre en el servidor y no puede abrir archivos del equipo del usuario: execute() devuelve None y avisa en la página.',
  ),
  _ => null,
};

/// Componente colocado en la ventana.
class TkWidget {
  TkWidget({
    required this.kind,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.parent,
    this.page,
    Map<String, Object?>? props,
    Map<String, String>? events,
  }) : props = props ?? {},
       events = events ?? {};

  String kind, name;

  /// Página del control de páginas que lo contiene (null = la activa al
  /// colocarlo; solo cuenta si [parent] es un control de páginas).
  int? page;
  int x, y, width, height;

  /// Nombre del marco que lo contiene (null = la ventana). [x] e [y] son
  /// relativos a él.
  String? parent;

  /// Solo las propiedades distintas de su valor de serie.
  final Map<String, Object?> props;

  /// Clave del evento → nombre del método.
  final Map<String, String> events;

  TkComponent get component => tkComponent(kind)!;

  Object? prop(TkProp p) => props[p.key] ?? p.def;

  /// Valor de la propiedad [key] como texto.
  String text(String key) => '${props[key] ?? component.prop(key)?.def ?? ''}';

  void setProp(TkProp p, Object? v) {
    if (v == p.def || v == null) {
      props.remove(p.key);
    } else {
      props[p.key] = v;
    }
  }

  TkWidget clone() => TkWidget.fromJson(toJson());

  Map<String, Object?> toJson() => {
    'kind': kind,
    'name': name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'parent': ?parent,
    'page': ?page,
    if (props.isNotEmpty) 'props': _sorted(props),
    if (events.isNotEmpty) 'events': _sorted(events),
  };

  static TkWidget fromJson(Map<String, Object?> j) => TkWidget(
    kind: '${j['kind']}',
    name: '${j['name']}',
    x: _int(j['x']),
    y: _int(j['y']),
    width: _int(j['width'], 1),
    height: _int(j['height'], 1),
    parent: j['parent'] as String?,
    page: j['page'] is num ? (j['page'] as num).toInt() : null,
    props: {...?(j['props'] as Map?)?.cast<String, Object?>()},
    events: {...?(j['events'] as Map?)?.map((k, v) => MapEntry('$k', '$v'))},
  );
}

int _int(Object? v, [int min = -100000]) {
  final n = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  return n < min ? min : n;
}

Map<String, T> _sorted<T>(Map<String, T> m) => {
  for (final k in m.keys.toList()..sort()) k: m[k] as T,
};

/// Diseño de una ventana: lo que se guarda en la base como JSON.
class TkDesign {
  TkDesign({
    this.name = 'Form1',
    this.width = 400,
    this.height = 300,
    this.target = tkTargetDesktop,
    Map<String, Object?>? props,
    Map<String, String>? events,
    List<TkWidget>? widgets,
  }) : props = props ?? {'position': 'center'},
       events = events ?? {},
       widgets = widgets ?? [];

  /// Nombre de la clase de la ventana.
  String name;
  int width, height;

  /// [tkTargetDesktop] o [tkTargetWeb]. Va en el JSON solo si es web: las
  /// aplicaciones que ya existen no cambian.
  final String target;
  final Map<String, Object?> props;
  final Map<String, String> events;

  bool get isWeb => target == tkTargetWeb;
  bool get isElectron => target == tkTargetElectron;
  bool get isChrome => target == tkTargetChrome;
  bool get isNext => target == tkTargetNext;
  bool get isCpp => target == tkTargetCpp;
  bool get isPascal => target == tkTargetPascal;

  /// App de Flutter: pantallas en lugar de una ventana.
  bool get isFlutter =>
      target == tkTargetFlutter || target == tkTargetFlutterDesktop;

  /// Flutter de escritorio: ventana del sistema en lugar de teléfono.
  bool get isFlutterDesktop => target == tkTargetFlutterDesktop;

  /// Aplicación de consola (sin ventana ni diseño).
  bool get isConsole => tkConsoleTargets.contains(target);

  /// Lenguaje de la consola: py, c, cpp o pas (null: no es de consola).
  String? get consoleLang => isConsole ? target.substring(8) : null;

  /// Lenguaje del código para el editor, la ayuda y el autocompletado: py,
  /// js, cpp o pas (C usa lo de C++).
  String get codeLang => switch (consoleLang) {
    'py' => 'py',
    'c' || 'cpp' => 'cpp',
    'pas' => 'pas',
    _ =>
      isFlutter
          ? 'dart'
          : isJs
          ? 'js'
          : isCpp
          ? 'cpp'
          : isPascal
          ? 'pas'
          : 'py',
  };

  /// El código es JavaScript (Electron y extensiones de Chrome).
  bool get isJs => isElectron || isChrome || isNext;

  /// Icono de la aplicación (ruta dentro del proyecto, como images/…), o
  /// null. Se define en el nodo Proyecto.
  String? get appIcon {
    final v = props['app_icon'];
    return v is String && v.isNotEmpty ? v : null;
  }

  set appIcon(String? v) {
    if (v == null || v.isEmpty) {
      props.remove('app_icon');
    } else {
      props['app_icon'] = v;
    }
  }

  /// El código es Python (tkinter o Flask).
  bool get isPython => !isJs && !isCpp && !isPascal && !isConsole && !isFlutter;

  /// ¿Sirve [s] como nombre en el archivo de este destino?
  bool validName(String s) =>
      tkValidName(s) &&
      !(isWeb && tkWebReserved.contains(s)) &&
      !((isJs || isCpp) && tkJsReserved.contains(s)) &&
      !(isCpp && tkCppReserved.contains(s)) &&
      !(isPascal && tkPascalReserved.contains(s.toLowerCase()));

  /// En orden de creación, que es también el orden de apilado; un marco va
  /// siempre antes que sus componentes.
  final List<TkWidget> widgets;

  Object? prop(TkProp p) => props[p.key] ?? p.def;

  void setProp(TkProp p, Object? v) {
    if (v == p.def || v == null) {
      props.remove(p.key);
    } else {
      props[p.key] = v;
    }
  }

  String get title => '${prop(tkFormTitle)}';

  TkWidget? byName(String name) =>
      widgets.where((w) => w.name == name).firstOrNull;

  /// Componentes que leen datos.
  Iterable<TkWidget> get connections =>
      widgets.where((w) => w.kind == 'Connection');

  /// Página activa del control de páginas [w].
  int activePage(TkWidget w) {
    final n = tkPages(w).length;
    final a = w.props['active'];
    final i = a is num ? a.toInt() : int.tryParse('${a ?? ''}') ?? 0;
    return i.clamp(0, n - 1);
  }

  /// El control de páginas que contiene directamente a [w] (null si no).
  TkWidget? pageControlOf(TkWidget w) {
    final p = w.parent == null ? null : byName(w.parent!);
    return p?.kind == 'PageControl' ? p : null;
  }

  /// Página de [w] dentro de su control de páginas (0 si no está en uno).
  int pageOf(TkWidget w) {
    final pc = pageControlOf(w);
    if (pc == null) return 0;
    final n = tkPages(pc).length;
    return (w.page ?? activePage(pc)).clamp(0, n - 1);
  }

  /// ¿Se ve [w] en el diseño? No, si está en una página que no es la activa
  /// (o dentro de algo que lo está).
  bool shown(TkWidget w) {
    TkWidget? o = w;
    for (var i = 0; o != null && i <= widgets.length; i++) {
      final pc = pageControlOf(o);
      if (pc != null && pageOf(o) != activePage(pc)) return false;
      o = o.parent == null ? null : byName(o.parent!);
    }
    return true;
  }

  /// El menú de la ventana, si tiene.
  TkWidget? get menu => widgets.where((w) => w.kind == 'Menu').firstOrNull;

  /// La cinta de opciones de la ventana, si tiene.
  TkWidget? get ribbon => widgets.where((w) => w.kind == 'Ribbon').firstOrNull;

  /// Pestaña que se ve de la cinta [w].
  int ribbonTab(TkWidget w) {
    final n = tkRibbonTabs(w.text('items')).length;
    if (n == 0) return 0;
    final a = w.props['active'];
    final i = a is num ? a.toInt() : int.tryParse('${a ?? ''}') ?? 0;
    return i.clamp(0, n - 1);
  }

  /// El componente de la clase [kind] al que apunta la referencia [name].
  TkWidget? reference(String name, String kind) {
    final w = byName(name);
    return w?.kind == kind ? w : null;
  }

  /// Un componente cambió de nombre: lo siguen quienes apuntan a él.
  void renameReferences(String from, String to) {
    for (final w in widgets) {
      for (final p in w.component.props) {
        if (p.type == TkPropType.reference && w.props[p.key] == from) {
          w.props[p.key] = to;
        }
      }
    }
  }

  /// Primer nombre libre para un componente de la clase [kind].
  String freeName(String kind, [Set<String> also = const {}]) {
    for (var i = 1; ; i++) {
      final n = '$kind$i';
      if (byName(n) == null && !also.contains(n)) return n;
    }
  }

  /// ¿Está [w] dentro de [ancestor] (a cualquier nivel)?
  bool isInside(TkWidget w, String ancestor) {
    var p = w.parent;
    for (var i = 0; p != null && i < widgets.length; i++) {
      if (p == ancestor) return true;
      p = byName(p)?.parent;
    }
    return false;
  }

  /// Posición de [w] respecto de la ventana.
  (int, int) absolute(TkWidget w) {
    var x = w.x, y = w.y;
    var p = w.parent == null ? null : byName(w.parent!);
    for (var i = 0; p != null && i < widgets.length; i++) {
      x += p.x;
      y += p.y;
      p = p.parent == null ? null : byName(p.parent!);
    }
    return (x, y);
  }

  /// Quita [w] y lo que contiene; devuelve los nombres quitados.
  Set<String> remove(TkWidget w) {
    final gone = {
      w.name,
      for (final o in widgets)
        if (isInside(o, w.name)) o.name,
    };
    widgets.removeWhere((o) => gone.contains(o.name));
    return gone;
  }

  /// Deja [w] y su contenido al final (encima de los demás) o al principio.
  void reorder(TkWidget w, {required bool front}) {
    final group = [
      for (final o in widgets)
        if (o == w || isInside(o, w.name)) o,
    ];
    widgets.removeWhere(group.contains);
    if (front) {
      // Encima de sus hermanos, sin salir del marco que lo contiene.
      var at = widgets.length;
      if (w.parent != null) {
        final inside = [
          for (final (i, o) in widgets.indexed)
            if (o.name == w.parent || isInside(o, w.parent!)) i,
        ];
        if (inside.isNotEmpty) at = inside.last + 1;
      }
      widgets.insertAll(at, group);
    } else {
      final p = w.parent == null
          ? -1
          : widgets.indexWhere((o) => o.name == w.parent);
      widgets.insertAll(p + 1, group);
    }
  }

  /// Pasa [w] al marco [parent] (null = la ventana) sin moverlo de sitio.
  void reparent(TkWidget w, String? parent) {
    if (w.parent == parent) return;
    final (ax, ay) = absolute(w);
    final target = parent == null ? null : byName(parent);
    final (px, py) = target == null ? (0, 0) : absolute(target);
    w
      ..parent = parent
      ..x = ax - px
      ..y = ay - py
      // En un control de páginas, va a la página que se ve.
      ..page = target?.kind == 'PageControl' ? activePage(target!) : null;
    if (target != null) {
      // El marco debe crearse antes que sus componentes.
      final group = [
        for (final o in widgets)
          if (o == w || isInside(o, w.name)) o,
      ];
      if (widgets.indexOf(target) > widgets.indexOf(w)) {
        widgets.removeWhere(group.contains);
        widgets.insertAll(widgets.indexOf(target) + 1, group);
      }
    }
  }

  /// Problemas que impiden generar el archivo (vacío = ninguno).
  List<String> problems() {
    final out = <String>[];
    if (!validName(name)) {
      out.add(tr('«{0}» no es un nombre válido para la ventana.', [name]));
    }
    final seen = <String>{name};
    final position = <String, int>{};
    for (final (i, w) in widgets.indexed) {
      if (tkComponent(w.kind) == null) {
        out.add(tr('Componente desconocido: {0}.', [w.kind]));
        continue;
      }
      if (tkJsGap(this, w.kind) case final gap?) out.add(gap);
      if (!validName(w.name)) {
        out.add(
          tr('«{0}» no es un nombre válido para un componente.', [w.name]),
        );
      } else if (!seen.add(w.name)) {
        out.add(tr('El nombre «{0}» está repetido.', [w.name]));
      }
      final p = w.parent;
      if (p != null && position[p] == null) {
        out.add(tr('«{0}» está en un marco que no existe.', [w.name]));
      }
      position[w.name] = i;
      if (w.kind == 'Menu' && menu != w) {
        out.add(
          tr('Una ventana solo puede tener un menú: sobra «{0}».', [w.name]),
        );
      }
      if (w.kind == 'Ribbon' && ribbon != w) {
        out.add(
          tr(
            'Una ventana solo puede tener una cinta de opciones: sobra «{0}».',
            [w.name],
          ),
        );
      }
      // En el estudio no hay un ERP detrás: cada conexión de datos lee de
      // una de las guardadas en Bases de datos.
      if (w.kind == 'Connection' && w.text('connection').trim().isEmpty) {
        out.add(
          tr(
            '«{0}» no tiene conexión: elija una de las guardadas en Bases de datos.',
            [w.name],
          ),
        );
      }
      for (final m in w.events.values) {
        if (!validName(m)) {
          out.add(tr('«{0}» no es un nombre válido para un método.', [m]));
        }
      }
    }
    for (final m in events.values) {
      if (!validName(m)) {
        out.add(tr('«{0}» no es un nombre válido para un método.', [m]));
      }
    }
    return out;
  }

  Map<String, Object?> toJson() => {
    'name': name,
    if (target != tkTargetDesktop) 'target': target,
    'width': width,
    'height': height,
    if (props.isNotEmpty) 'props': _sorted(props),
    if (events.isNotEmpty) 'events': _sorted(events),
    'widgets': [for (final w in widgets) w.toJson()],
  };

  String toJsonString() => jsonEncode(toJson());

  static TkDesign fromJson(Map<String, Object?> j) => TkDesign(
    name: '${j['name'] ?? 'Form1'}',
    target: switch (j['target']) {
      tkTargetWeb => tkTargetWeb,
      tkTargetElectron => tkTargetElectron,
      tkTargetChrome => tkTargetChrome,
      tkTargetNext => tkTargetNext,
      tkTargetCpp => tkTargetCpp,
      tkTargetPascal => tkTargetPascal,
      tkTargetFlutter => tkTargetFlutter,
      tkTargetFlutterDesktop => tkTargetFlutterDesktop,
      final String t when tkConsoleTargets.contains(t) => t,
      _ => tkTargetDesktop,
    },
    width: _int(j['width'], 80),
    height: _int(j['height'], 60),
    props: {...?(j['props'] as Map?)?.cast<String, Object?>()},
    events: {...?(j['events'] as Map?)?.map((k, v) => MapEntry('$k', '$v'))},
    widgets: [
      for (final w in (j['widgets'] as List?) ?? const [])
        TkWidget.fromJson((w as Map).cast<String, Object?>()),
    ],
  );

  /// Lee el diseño guardado en la base; uno ilegible queda vacío (el código
  /// del usuario no se toca).
  static TkDesign parse(String? s) {
    try {
      final j = jsonDecode(s ?? '{}');
      return j is Map ? fromJson(j.cast<String, Object?>()) : TkDesign();
    } on FormatException {
      return TkDesign();
    } on TypeError {
      return TkDesign();
    }
  }

  TkDesign clone() =>
      fromJson((jsonDecode(toJsonString()) as Map).cast<String, Object?>());
}
