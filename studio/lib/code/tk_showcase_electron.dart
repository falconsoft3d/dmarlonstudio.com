part of 'tk_examples.dart';

// Ejemplos de Electron + React: el mismo diseñador, con el código en
// JavaScript. Los componentes son objetos con propiedades (this.Label1.text).

String _jsStr(String s) => jsonEncode(s);

TkDesign _toElectron(TkDesign d) =>
    TkDesign.fromJson({...d.toJson(), 'target': tkTargetElectron});

/// Los ejemplos de Electron.
List<TkExample> tkElectronExamples(String Function(String) t) => [
  _electronCalculator(t),
  _electronNotepad(t),
];

// ----------------------------------------------------------- calculadora
TkExample _electronCalculator(String Function(String) t) {
  final base = _calculator(t);
  final digits = StringBuffer();
  for (var i = 0; i < 10; i++) {
    digits.write('  Btn${i}_click() {\n    this.digit("$i");\n  }\n\n');
  }
  final code =
      '''// ${t(markTr('Calculadora en JavaScript: cada botón llama a su método.'))}
const ERROR = "Error";

class Form1 extends FormDesign {
  form_create() {
    this.clear();
  }

  // Estado: lo que se ve, el primer número y la operación pendiente.
  clear() {
    this.shown = "0";
    this.first = null;
    this.op = null;
    this.typing = false;
    this.show();
  }

  show() {
    this.Display.text = this.shown;
  }

  digit(d) {
    if (this.shown === ERROR) this.clear();
    if (!this.typing || this.shown === "0") {
      this.shown = d;
      this.typing = true;
    } else if (this.shown.replace(/[-.]/g, "").length < 15) {
      this.shown += d;
    }
    this.show();
  }

  dot() {
    if (this.shown === ERROR) this.clear();
    if (!this.typing) {
      this.shown = "0";
      this.typing = true;
    }
    if (!this.shown.includes(".")) this.shown += ".";
    this.show();
  }

  backspace() {
    if (!this.typing) return;
    this.shown = this.shown.slice(0, -1) || "0";
    if (this.shown === "-" || this.shown === "-0") this.shown = "0";
    this.show();
  }

  textOf(n) {
    if (!Number.isFinite(n)) return ERROR;
    if (n !== 0 && (Math.abs(n) >= 1e15 || Math.abs(n) < 1e-9)) return n.toExponential(9);
    const text = String(Number(n.toPrecision(15)));
    return text === "-0" ? "0" : text;
  }

  compute() {
    if (this.op === null || this.first === null || this.shown === ERROR) return;
    const a = this.first;
    const b = Number(this.shown);
    const result = { "+": a + b, "-": a - b, "*": a * b, "/": a / b }[this.op];
    this.first = null;
    this.op = null;
    this.shown = this.textOf(result);
    this.typing = false;
    this.show();
  }

  operate(op) {
    if (this.shown === ERROR) return;
    if (this.typing) this.compute();
    if (this.shown !== ERROR) {
      this.first = Number(this.shown);
      this.op = op;
      this.typing = false;
    }
  }

  form_key(event) {
    const key = event.key;
    if (/^[0-9]\$/.test(key)) this.digit(key);
    else if ("+-*/".includes(key) && key.length === 1) this.operate(key);
    else if (key === "." || key === ",") this.dot();
    else if (key === "=" || key === "Enter") this.compute();
    else if (key === "Escape") this.clear();
    else if (key === "Backspace" || key === "Delete") this.backspace();
  }

$digits  BtnDot_click() {
    this.dot();
  }

  BtnClear_click() {
    this.clear();
  }

  BtnSign_click() {
    if (this.shown === ERROR || this.shown === "0") return;
    this.shown = this.shown.startsWith("-") ? this.shown.slice(1) : "-" + this.shown;
    this.show();
  }

  BtnPercent_click() {
    if (this.shown === ERROR) return;
    this.shown = this.textOf(Number(this.shown) / 100);
    this.typing = false;
    this.show();
  }

  BtnAdd_click() {
    this.operate("+");
  }

  BtnSub_click() {
    this.operate("-");
  }

  BtnMul_click() {
    this.operate("*");
  }

  BtnDiv_click() {
    this.operate("/");
  }

  BtnEquals_click() {
    this.compute();
  }
}
''';
  return TkExample(
    'electron_calculator',
    t(markTr('Calculadora (Electron)')),
    t(
      markTr(
        'La calculadora de escritorio hecha con Electron y React: el mismo diseño, con el código en JavaScript.',
      ),
    ),
    _toElectron(base.design),
    code,
  );
}

// ---------------------------------------------------------- bloc de notas
TkExample _electronNotepad(String Function(String) t) {
  final app = t(markTr('Bloc de notas (Electron)'));
  final file = t(markTr('Archivo'));
  final help = t(markTr('Ayuda'));
  final newDoc = t(markTr('Nuevo')), open = t(markTr('Abrir…'));
  final save = t(markTr('Guardar')), saveAs = t(markTr('Guardar como…'));
  final quit = t(markTr('Salir'));
  final about = t(markTr('Acerca de'));
  final items = [
    file,
    '  $newDoc',
    '  $open',
    '  $save',
    '  $saveAs',
    '  -',
    '  $quit',
    help,
    '  $about',
  ].join('\n');
  final filter = '${t(markTr('Texto'))}|*.txt';
  final design =
      TkDesign(
          width: 720,
          height: 480,
          target: tkTargetElectron,
          props: {'title': app, 'position': 'center', 'resizable': true},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            640,
            8,
            32,
            32,
            {'items': items},
            {'command': 'Menu1_click'},
          ),
          _w(
            'Text',
            'Editor',
            0,
            0,
            720,
            456,
            {'font_family': 'Menlo', 'font_size': 14},
            {'key_up': 'Editor_key_up'},
          ),
          _w('StatusBar', 'Status', 0, 456, 720, 24, {
            'text': t(markTr('Listo')),
          }),
          _w('OpenDialog', 'OpenFile', 600, 8, 32, 32, {
            'title': open,
            'filter': filter,
          }),
          _w('SaveDialog', 'SaveFile', 560, 8, 32, 32, {
            'title': saveAs,
            'filter': filter,
            'filename': 'nota.txt',
          }),
        ]);
  final code =
      '''// ${t(markTr('Bloc de notas en JavaScript: menú nativo, abrir y guardar con los diálogos del sistema.'))}
const APP = ${_jsStr(app)};
const MENU = {
  NEW: ${_jsStr('$file/$newDoc')},
  OPEN: ${_jsStr('$file/$open')},
  SAVE: ${_jsStr('$file/$save')},
  SAVE_AS: ${_jsStr('$file/$saveAs')},
  QUIT: ${_jsStr('$file/$quit')},
  ABOUT: ${_jsStr('$help/$about')},
};
const UNTITLED = ${_jsStr(t(markTr('Sin título')))};
const STATUS = ${_jsStr(t(markTr('Línea {0} · {1} caracteres')))};

class Form1 extends FormDesign {
  form_create() {
    this.path = null;
    this.refresh();
  }

  refresh() {
    const name = this.path ? require("path").basename(this.path) : UNTITLED;
    this.title = name + " — " + APP;
    const text = this.Editor.text;
    const lines = text.split("\\n").length;
    this.Status.text = STATUS.replace("{0}", lines).replace("{1}", text.length);
  }

  async open() {
    const path = await this.OpenFile.execute();
    if (!path) return;
    this.Editor.text = this.OpenFile.readText(path);
    this.path = path;
    this.refresh();
  }

  async save(ask = false) {
    let path = this.path;
    if (ask || !path) path = await this.SaveFile.execute();
    if (!path) return;
    this.SaveFile.writeText(path, this.Editor.text);
    this.path = path;
    this.refresh();
    this.notify(${_jsStr(t(markTr('Guardado.')))});
  }

  Menu1_click(item) {
    if (item === MENU.NEW) {
      this.Editor.text = "";
      this.path = null;
      this.refresh();
    } else if (item === MENU.OPEN) {
      this.open();
    } else if (item === MENU.SAVE) {
      this.save();
    } else if (item === MENU.SAVE_AS) {
      this.save(true);
    } else if (item === MENU.QUIT) {
      this.close();
    } else if (item === MENU.ABOUT) {
      this.message(${_jsStr(t(markTr('Un bloc de notas hecho con DMarlon Studio, Electron y React.')))}, APP);
    }
  }

  Editor_key_up(event) {
    this.refresh();
  }
}
''';
  return TkExample(
    'electron_notepad',
    app,
    t(
      markTr(
        'Bloc de notas con Electron y React: menú nativo, abrir y guardar archivos con los diálogos del sistema.',
      ),
    ),
    design,
    code,
  );
}
