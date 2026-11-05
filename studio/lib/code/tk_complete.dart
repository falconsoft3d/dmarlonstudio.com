import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import 'tk_model.dart';

/// Autocompletado del código del Diseñador: sabe qué componentes tiene la
/// ventana y qué tiene cada uno en el lenguaje del destino.
///
/// - Tras `self.` / `this.` / `this->`: los componentes y lo de la ventana.
/// - Tras `self.Entry1.` / `this.Entry1.` / `Entry1->`: lo del componente.
/// - En otro sitio: palabras clave, componentes y métodos del código.
class TkCompletion implements CodeAutocompletePromptsBuilder {
  TkCompletion({required this.design, required this.code});

  /// El diseño y el código de ahora (se leen al completar).
  final TkDesign Function() design;
  final String Function() code;

  /// Ctrl+Espacio: completar aunque no se haya escrito nada.
  bool force = false;

  String get _lang => design().isCpp
      ? 'cpp'
      : design().isJs
      ? 'js'
      : 'py';

  static final _ident = RegExp(r'[A-Za-z0-9_$]');

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    final forced = force;
    final text = codeLine.text;
    final at = selection.extentOffset.clamp(0, text.length);
    final before = text.substring(0, at);
    // Dentro de una cadena o de un comentario, nada.
    if (_inString(before)) return null;
    var start = at;
    while (start > 0 && _ident.hasMatch(before[start - 1])) {
      start--;
    }
    final input = before.substring(start);
    final head = before.substring(0, start);
    final member = _memberOf(head);
    final List<CodePrompt> all;
    if (member != null) {
      all = member;
    } else {
      if (input.isEmpty && !forced) return null;
      all = _free();
    }
    if (input.isEmpty && member == null && !forced) return null;
    final lower = input.toLowerCase();
    final seen = <String>{};
    final prompts = [
      for (final p in all)
        if (p.word.toLowerCase().startsWith(lower) &&
            p.word != input &&
            seen.add(p.word))
          p,
    ];
    if (prompts.isEmpty) return null;
    return CodeAutocompleteEditingValue(
      input: input,
      prompts: prompts,
      index: 0,
    );
  }

  static bool _inString(String s) {
    final noEsc = s.replaceAll(RegExp(r'\\.'), '');
    if (RegExp(r'(^|\s)(#|//)').hasMatch(noEsc) &&
        !RegExp('["\']').hasMatch(noEsc.split(RegExp(r'#|//')).first)) {
      return true;
    }
    return '"'.allMatches(noEsc).length.isOdd ||
        "'".allMatches(noEsc).length.isOdd;
  }

  /// Lo que va tras un punto o una flecha (null: no es un miembro).
  List<CodePrompt>? _memberOf(String head) {
    final d = design();
    final names = {for (final w in d.widgets) w.name: w};
    final lang = _lang;
    final self = lang == 'py' ? 'self' : 'this';
    // Lo de un componente: self.X. / this.X. / X-> / this->X-> / X.
    final m = RegExp(
      lang == 'cpp'
          ? r'(?:this->)?([A-Za-z_]\w*)\s*(->|\.)$'
          : '$self\\.([A-Za-z_]\\w*)\\.\$',
    ).firstMatch(head);
    if (m != null && names.containsKey(m[1])) {
      return _widget(names[m[1]]!);
    }
    // Lo de la ventana.
    if (RegExp(lang == 'cpp' ? r'this->$' : '\\b$self\\.\$').hasMatch(head)) {
      return [..._components(), ..._form(), ..._methods()];
    }
    return null;
  }

  List<CodePrompt> _components() => [
    for (final w in design().widgets)
      CodeFieldPrompt(word: w.name, type: w.kind),
    if (_lang == 'py')
      for (final w in design().widgets)
        if (const {
          'Entry',
          'Combobox',
          'Checkbutton',
          'Radiobutton',
          'Scale',
          'Password',
        }.contains(w.kind))
          CodeFieldPrompt(word: '${w.name}_var', type: 'Variable'),
  ];

  /// Métodos que ya hay en el código del usuario.
  List<CodePrompt> _methods() {
    final re = switch (_lang) {
      'py' => RegExp(r'^\s+def\s+([A-Za-z_]\w*)\s*\(', multiLine: true),
      'cpp' => RegExp(
        r'^\s*(?:virtual\s+)?[\w:<>&*]+\s+([A-Za-z_]\w*)\s*\(',
        multiLine: true,
      ),
      _ => RegExp(
        r'^\s+(?:async\s+)?([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{',
        multiLine: true,
      ),
    };
    const skip = {'if', 'for', 'while', 'switch', 'catch', 'return', 'else'};
    return [
      for (final m in re.allMatches(code()))
        if (!skip.contains(m[1])) CodeFieldPrompt(word: m[1]!, type: 'método'),
    ];
  }

  List<CodePrompt> _free() {
    final lang = _lang;
    return [
      if (lang == 'py') const CodeKeywordPrompt(word: 'self'),
      if (lang != 'py') const CodeKeywordPrompt(word: 'this'),
      // En C++ los componentes se usan sin this->.
      if (lang == 'cpp') ..._components(),
      if (lang == 'cpp') ..._form(),
      ..._methods(),
      for (final k in _keywords[lang]!) CodeKeywordPrompt(word: k),
    ];
  }

  List<CodePrompt> _form() => [
    for (final (word, type) in _formApi[_lang]!)
      CodeFieldPrompt(word: word, type: type),
  ];

  List<CodePrompt> _widget(TkWidget w) {
    final lang = _lang;
    final api = _api[lang]!;
    return [
      for (final (word, type) in [...?api[w.kind], ...?api['*']])
        CodeFieldPrompt(word: word, type: type),
    ];
  }

  // ------------------------------------------------------------- tablas
  static const _keywords = {
    'py': [
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
      'not',
      'or',
      'pass',
      'raise',
      'return',
      'try',
      'while',
      'with',
      'yield',
      'print',
      'len',
      'range',
      'str',
      'int',
      'float',
      'list',
      'dict',
      'enumerate',
      'isinstance',
      'round',
      'sorted',
      'open',
    ],
    'js': [
      'async',
      'await',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'default',
      'else',
      'false',
      'finally',
      'for',
      'function',
      'if',
      'let',
      'new',
      'null',
      'return',
      'switch',
      'this',
      'throw',
      'true',
      'try',
      'typeof',
      'undefined',
      'while',
      'console',
      'JSON',
      'Math',
      'Number',
      'String',
      'Array',
      'Object',
      'Promise',
      'Date',
      'parseInt',
      'parseFloat',
      'setTimeout',
      'require',
    ],
    'cpp': [
      'auto',
      'bool',
      'break',
      'case',
      'char',
      'class',
      'const',
      'continue',
      'default',
      'double',
      'else',
      'false',
      'for',
      'if',
      'int',
      'nullptr',
      'override',
      'public',
      'return',
      'static_cast',
      'std',
      'string',
      'switch',
      'true',
      'void',
      'while',
      'vector',
      'str',
      'readText',
      'writeText',
      'std::string',
      'std::vector',
      'std::cout',
      'std::endl',
    ],
  };

  static const _formApi = {
    'py': [('root', 'Tk'), ('notify', 'web'), ('value', 'web')],
    'js': [
      ('title', 'texto'),
      ('message', 'método'),
      ('ask', 'método'),
      ('notify', 'método'),
      ('after', 'método'),
      ('close', 'método'),
      ('storage', 'datos'),
      ('currentTab', 'método'),
      ('openTab', 'método'),
      ('runInPage', 'método'),
      ('badge', 'método'),
      ('widgets', 'lista'),
    ],
    'cpp': [
      ('title', 'método'),
      ('message', 'método'),
      ('ask', 'método'),
      ('close', 'método'),
      ('bg', 'método'),
    ],
  };

  static const _api = <String, Map<String, List<(String, String)>>>{
    'py': {
      '*': [
        ('configure', 'método'),
        ('cget', 'método'),
        ('focus_set', 'método'),
        ('bind', 'método'),
        ('place', 'método'),
        ('place_forget', 'método'),
        ('after', 'método'),
      ],
      'Entry': [('get', 'método'), ('insert', 'método'), ('delete', 'método')],
      'Password': [
        ('get', 'método'),
        ('insert', 'método'),
        ('delete', 'método'),
      ],
      'Text': [
        ('get', 'método'),
        ('insert', 'método'),
        ('delete', 'método'),
        ('see', 'método'),
        ('tag_add', 'método'),
      ],
      'Listbox': [
        ('insert', 'método'),
        ('delete', 'método'),
        ('get', 'método'),
        ('curselection', 'método'),
        ('selection_set', 'método'),
        ('size', 'método'),
      ],
      'Combobox': [('get', 'método'), ('set', 'método'), ('current', 'método')],
      'Treeview': [
        ('insert', 'método'),
        ('delete', 'método'),
        ('get_children', 'método'),
        ('selection', 'método'),
        ('item', 'método'),
        ('focus', 'método'),
      ],
      'Checkbutton': [
        ('select', 'método'),
        ('deselect', 'método'),
        ('invoke', 'método'),
      ],
      'Radiobutton': [('select', 'método'), ('invoke', 'método')],
      'Scale': [('get', 'método'), ('set', 'método')],
      'Progressbar': [
        ('start', 'método'),
        ('stop', 'método'),
        ('step', 'método'),
      ],
      'StatusBar': [('set', 'método')],
      'Timer': [('start', 'método'), ('stop', 'método')],
      'OpenDialog': [('execute', 'método')],
      'SaveDialog': [('execute', 'método')],
      'PageControl': [('select', 'método'), ('index', 'método')],
      'HtmlView': [('set_html', 'método'), ('content', 'método')],
      'Chart': [
        ('set_series', 'método'),
        ('add_point', 'método'),
        ('clear', 'método'),
        ('redraw', 'método'),
        ('set_kind', 'método'),
      ],
      'AiAssistant': [
        ('ask', 'método'),
        ('chat', 'método'),
        ('summarize', 'método'),
        ('translate', 'método'),
        ('classify', 'método'),
        ('extract', 'método'),
        ('ask_async', 'método'),
        ('chat_async', 'método'),
        ('reset', 'método'),
      ],
      'PdfReport': [
        ('clear', 'método'),
        ('title', 'método'),
        ('heading', 'método'),
        ('text', 'método'),
        ('table', 'método'),
        ('save_dialog', 'método'),
        ('open', 'método'),
      ],
      'ExcelReport': [
        ('clear', 'método'),
        ('sheet', 'método'),
        ('write_row', 'método'),
        ('write_rows', 'método'),
        ('save_dialog', 'método'),
      ],
    },
    'js': {
      '*': [
        ('text', 'texto'),
        ('value', 'valor'),
        ('enabled', 'bool'),
        ('visible', 'bool'),
        ('bg', 'color'),
        ('fg', 'color'),
        ('x', 'número'),
        ('y', 'número'),
        ('width', 'número'),
        ('height', 'número'),
        ('focus', 'método'),
        ('configure', 'método'),
      ],
      'Checkbutton': [('checked', 'bool')],
      'Radiobutton': [('checked', 'bool')],
      'Listbox': [
        ('items', 'lista'),
        ('index', 'número'),
        ('selected', 'texto'),
        ('selection', 'lista'),
        ('add', 'método'),
        ('clear', 'método'),
        ('remove', 'método'),
      ],
      'Combobox': [
        ('items', 'lista'),
        ('index', 'número'),
        ('selected', 'texto'),
        ('add', 'método'),
        ('clear', 'método'),
      ],
      'Treeview': [
        ('columns', 'lista'),
        ('rows', 'lista'),
        ('addRow', 'método'),
        ('index', 'número'),
        ('selectedRow', 'fila'),
        ('clear', 'método'),
      ],
      'PageControl': [('page', 'número'), ('pages', 'lista')],
      'HtmlView': [('html', 'texto'), ('setHtml', 'método')],
      'StatusBar': [('icon', 'texto'), ('set', 'método')],
      'Image': [('file', 'texto'), ('load', 'método')],
      'Progressbar': [
        ('maximum', 'número'),
        ('start', 'método'),
        ('stop', 'método'),
      ],
      'Timer': [
        ('interval', 'número'),
        ('start', 'método'),
        ('stop', 'método'),
      ],
      'OpenDialog': [('execute', 'método'), ('readText', 'método')],
      'SaveDialog': [('execute', 'método'), ('writeText', 'método')],
    },
    'cpp': {
      '*': [
        ('enabled', 'método'),
        ('visible', 'método'),
        ('bg', 'método'),
        ('fg', 'método'),
        ('size', 'método'),
        ('redraw', 'FLTK'),
        ('label', 'FLTK'),
        ('tooltip', 'FLTK'),
      ],
      'Label': [('text', 'método'), ('left', 'método'), ('right', 'método')],
      'Button': [('text', 'método')],
      'StatusBar': [('text', 'método'), ('set', 'método')],
      'Entry': [('text', 'método'), ('value', 'FLTK')],
      'Password': [('text', 'método'), ('value', 'FLTK')],
      'Text': [('text', 'método'), ('value', 'FLTK')],
      'Checkbutton': [('checked', 'método'), ('text', 'método')],
      'Radiobutton': [('checked', 'método'), ('text', 'método')],
      'Listbox': [
        ('items', 'método'),
        ('add', 'método'),
        ('clear', 'método'),
        ('index', 'método'),
        ('selected', 'método'),
      ],
      'Combobox': [
        ('items', 'método'),
        ('index', 'método'),
        ('text', 'método'),
        ('selected', 'método'),
      ],
      'Scale': [('value', 'método'), ('range', 'FLTK'), ('step', 'FLTK')],
      'Progressbar': [('value', 'método'), ('maximum', 'método')],
      'PageControl': [('page', 'método')],
      'Image': [('load', 'método')],
      'Timer': [
        ('start', 'método'),
        ('stop', 'método'),
        ('interval', 'método'),
      ],
      'OpenDialog': [
        ('execute', 'método'),
        ('title', 'método'),
        ('filter', 'método'),
      ],
      'SaveDialog': [
        ('execute', 'método'),
        ('title', 'método'),
        ('filename', 'método'),
      ],
    },
  };
}
