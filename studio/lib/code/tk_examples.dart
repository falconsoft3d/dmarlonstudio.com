import 'dart:convert';
import 'dart:math' as math;

import '../i18n/tr.dart';
import 'tk_codegen.dart';
import 'tk_flutter.dart';
import 'tk_flutter_db.dart';
import 'tk_model.dart';
import 'tk_pascal.dart';
import 'tk_unit.dart';

part 'tk_showcase.dart';
part 'tk_showcase_web.dart';
part 'tk_showcase_3d.dart';
part 'tk_showcase_ai.dart';
part 'tk_showcase_mail.dart';
part 'tk_showcase_reports.dart';
part 'tk_showcase_sites.dart';
part 'tk_showcase_electron.dart';
part 'tk_showcase_chrome.dart';
part 'tk_showcase_next.dart';
part 'tk_showcase_cpp.dart';
part 'tk_showcase_cpp_explorer.dart';
part 'tk_showcase_cpp_explorer_code.dart';
part 'tk_showcase_cpp_racing.dart';
part 'tk_showcase_cpp_racing_code.dart';
part 'tk_showcase_cpp_image_editor.dart';
part 'tk_showcase_cpp_image_editor_code.dart';
part 'tk_showcase_cpp_flights.dart';
part 'tk_showcase_cpp_flights_code.dart';
part 'tk_showcase_cpp_hardware.dart';
part 'tk_showcase_cpp_hardware_code.dart';
part 'tk_showcase_cpp_wifi.dart';
part 'tk_showcase_cpp_wifi_code.dart';
part 'tk_showcase_cpp_console.dart';
part 'tk_showcase_cpp_console_code.dart';
part 'tk_showcase_pascal.dart';
part 'tk_showcase_pascal_malecon.dart';
part 'tk_showcase_pascal_malecon_code.dart';
part 'tk_showcase_pascal_docker.dart';
part 'tk_showcase_pascal_docker_code.dart';
part 'tk_showcase_pascal_launcher.dart';
part 'tk_showcase_pascal_launcher_code.dart';
part 'tk_showcase_cpp_webmon.dart';
part 'tk_showcase_cpp_webmon_code.dart';
part 'tk_showcase_cpp_clocks.dart';
part 'tk_showcase_cpp_clocks_code.dart';
part 'tk_showcase_console.dart';
part 'tk_showcase_animals.dart';
part 'tk_showcase_flutter.dart';
part 'tk_showcase_flutter_store.dart';
part 'tk_showcase_flutter_cloud.dart';
part 'tk_showcase_flutter_desktop.dart';
part 'tk_showcase_web_next.dart';
part 'tk_showcase_windows.dart';
part 'tk_showcase_util_investor.dart';
part 'tk_showcase_util_pdf_editor.dart';
part 'tk_showcase_util_disk_usage.dart';
part 'tk_showcase_util_port_scanner.dart';
part 'tk_showcase_util_pos.dart';
part 'tk_showcase_util_file_renamer.dart';
part 'tk_showcase_util_mp3_player.dart';
part 'tk_showcase_util_train_monitor.dart';
part 'tk_showcase_domino.dart';
part 'tk_showcase_domino_code.dart';
part 'tk_showcase_web_domino.dart';
part 'tk_showcase_web_domino_code.dart';
part 'tk_showcase_next_world.dart';
part 'tk_showcase_next_world_code.dart';
part 'tk_showcase_next_speed.dart';
part 'tk_showcase_next_speed_code.dart';
part 'tk_showcase_next_flights.dart';
part 'tk_showcase_next_flights_code.dart';
part 'tk_showcase_util_pascal_odoo.dart';
part 'tk_showcase_shop.dart';

/// Comentario con el que empieza la unidad de una ventana nueva.
String tkUnitComment({
  bool web = false,
  bool electron = false,
  bool chrome = false,
  bool next = false,
  bool cpp = false,
  bool pascal = false,
}) => pascal
    ? tr(
        '// Código de la ventana, en Object Pascal (Lazarus). Cada evento del diseño es\n'
        '// un método de esta clase (con override); cada componente es el de la LCL de\n'
        '// siempre: Label1.Caption := \'Hola\', Edit1.Text, CheckBox1.Checked.\n'
        '// También ShowMessage(texto), Ask(pregunta), Close y NumToStr(número).',
      )
    : cpp
    ? tr(
        '// Código de la ventana, en C++ (FLTK). Cada evento del diseño es un método\n'
        '// de esta clase (con override); cada componente es un puntero con métodos\n'
        '// como en Delphi: Label1->text("Hola"), Entry1->text(), Check1->checked().\n'
        '// También title(), message(texto), ask(pregunta), close() y str(número).',
      )
    : next
    ? tr(
        '// Código de la página (Next.js), en JavaScript: corre en el navegador. Cada\n'
        '// evento del diseño es un método de esta clase; this.<Nombre> es cada\n'
        '// componente (this.Label1.text = "Hola"). También this.title,\n'
        '// this.message(texto), this.storage y this.notify(texto).',
      )
    : chrome
    ? tr(
        '// Código de la ventana emergente de la extensión, en JavaScript. Cada evento\n'
        '// del diseño es un método de esta clase; this.<Nombre> es cada componente\n'
        '// (this.Label1.text = "Hola"). Además: this.storage, await this.currentTab(),\n'
        '// this.openTab(url), await this.runInPage(función) y this.badge(texto).',
      )
    : electron
    ? tr(
        '// Código de la ventana, en JavaScript (Electron + React). Cada evento del\n'
        '// diseño es un método de esta clase; this.<Nombre> es cada componente,\n'
        '// con propiedades como en Delphi: this.Label1.text = "Hola". También\n'
        '// this.title, this.message(texto), this.ask(pregunta) y this.close().',
      )
    : web
    ? tr(
        '# Código de la aplicación web: corre en el servidor, en Python. Cada evento\n'
        '# del diseño es un método de esta clase; self.root es la página y\n'
        '# self.<Nombre>, cada componente, con las llamadas de tkinter. También\n'
        '# self.value("Nombre"), self.value("Nombre", valor) y self.notify(texto).\n'
        '# Ya existen en __init__; el evento «Al abrir» se ejecuta después de él.',
      )
    : tr(
        '# Código de la ventana: cada evento del diseño es un método de esta clase.\n'
        '# self.root es la ventana y self.<Nombre>, cada componente: ya existen en\n'
        '# __init__, y el evento «Al abrir» de la ventana se ejecuta después de él.',
      );

/// Ejemplo incluido en DMarlon Studio.
class TkExample {
  const TkExample(
    this.seed,
    this.name,
    this.description,
    this.design,
    this.code,
  );
  final String seed, name, description;
  final TkDesign design;
  final String code;
}

TkWidget _w(
  String kind,
  String name,
  int x,
  int y,
  int width,
  int height, [
  Map<String, Object?> props = const {},
  Map<String, String> events = const {},
]) => TkWidget(
  kind: kind,
  name: name,
  x: x,
  y: y,
  width: width,
  height: height,
  props: {...props},
  events: {...events},
);

/// Los ejemplos, con sus textos pasados por [t]: `tr` al crearlos y la
/// identidad para reconocer los que siguen sin cambios en otro idioma.
List<TkExample> tkExamples(String Function(String) t) => [
  _calculator(t),
  _tasks(t),
  _converter(t),
  _contacts(t),
  _stopwatch(t),
  _customer(t),
  _notes(t),
  _apiQuery(t),
  _notepad(t),
  _agenda(t),
  _currency(t),
  _snake(t),
  _music(t),
  _lineChart(t),
  _stocks(t),
  _windows(t),
  _mail(t),
  _viewer3d(t),
  _reports(t),
  _aiTexts(t),
  tkUtilPdfEditor(t),
  tkUtilDiskUsage(t),
  tkUtilPortScanner(t),
  tkUtilInvestor(t),
  tkUtilPos(t),
  tkUtilFileRenamer(t),
  tkUtilMp3Player(t),
  tkUtilTrainMonitor(t),
  tkDomino(t),
  ...tkShopDesktopExamples(t),
];

/// Los ejemplos web: el mismo diseño y el mismo código que los de escritorio,
/// que es lo que hay que poder hacer con los de cualquier usuario.
List<TkExample> tkWebExamples(String Function(String) t) => [
  _web(
    _aiTexts(t),
    'web_ai_texts',
    t(markTr('Asistente de textos web')),
    t(markTr('El asistente de textos con Claude, en Flask.')),
  ),
  _web(
    _reports(t),
    'web_reports',
    t(markTr('Informes web')),
    t(
      markTr(
        'Los informes en Flask: el PDF y el Excel se descargan en el navegador.',
      ),
    ),
  ),
  _web(
    _calculator(t),
    'web_calculator',
    t(markTr('Calculadora web')),
    t(markTr('La calculadora de escritorio, con el mismo código, en Flask.')),
  ),
  _web(
    _tasks(t),
    'web_tasks',
    t(markTr('Tareas web')),
    t(
      markTr('Lista de tareas en Flask, guardada en un archivo de su carpeta.'),
    ),
    (code) => code.replaceAll('"tasks.json"', '"tasks_web.json"'),
  ),
  _web(
    _stopwatch(t),
    'web_stopwatch',
    t(markTr('Cronómetro web')),
    t(markTr('El cronómetro de escritorio, con el mismo código, en Flask.')),
  ),
  _web(
    _notes(t),
    'web_notes',
    t(markTr('Editor de notas web')),
    t(
      markTr(
        'El editor de notas en Flask: guardar descarga el archivo en el navegador.',
      ),
    ),
  ),
  _web(
    _apiQuery(t),
    'web_api',
    t(markTr('Consulta API web')),
    t(markTr('La consulta a una API, con el mismo código, en Flask.')),
  ),
  _web(
    _customer(t),
    'web_customer',
    t(markTr('Ficha de cliente web')),
    t(
      markTr('La ficha de cliente con páginas, con el mismo código, en Flask.'),
    ),
  ),
  _crm(t),
  _invoicing(t),
  _siteBlog(t),
  _siteShop(t),
  _web(
    _lineChart(t),
    'web_line_chart',
    t(markTr('Gráfico de líneas web')),
    t(markTr('Las ventas mensuales, con el mismo código, en Flask.')),
  ),
  _web(
    _stocks(t),
    'web_stocks',
    t(markTr('Bolsa de valores web')),
    t(
      markTr(
        'Las velas y la cotización simulada, con el mismo código, en Flask.',
      ),
    ),
  ),
];

TkExample _web(
  TkExample e,
  String seed,
  String name,
  String description, [
  String Function(String)? code,
]) => TkExample(
  seed,
  name,
  description,
  TkDesign.fromJson({...e.design.toJson(), 'target': tkTargetWeb}),
  code == null ? e.code : code(e.code),
);

// ----------------------------------------------------------- calculadora
TkExample _calculator(String Function(String) t) {
  const size = 56, gap = 8, left = 12, top = 88;
  int cx(int c) => left + c * (size + gap);
  int cy(int r) => top + r * (size + gap);
  const dark = '#3a3f4b', orange = '#e8912d', gray = '#d4d6db';
  final keys = <(String, String, int, int, int, String)>[
    ('BtnClear', 'C', 0, 0, 1, gray),
    ('BtnSign', '±', 1, 0, 1, gray),
    ('BtnPercent', '%', 2, 0, 1, gray),
    ('BtnDiv', '÷', 3, 0, 1, orange),
    ('Btn7', '7', 0, 1, 1, ''),
    ('Btn8', '8', 1, 1, 1, ''),
    ('Btn9', '9', 2, 1, 1, ''),
    ('BtnMul', '×', 3, 1, 1, orange),
    ('Btn4', '4', 0, 2, 1, ''),
    ('Btn5', '5', 1, 2, 1, ''),
    ('Btn6', '6', 2, 2, 1, ''),
    ('BtnSub', '−', 3, 2, 1, orange),
    ('Btn1', '1', 0, 3, 1, ''),
    ('Btn2', '2', 1, 3, 1, ''),
    ('Btn3', '3', 2, 3, 1, ''),
    ('BtnAdd', '+', 3, 3, 1, orange),
    ('Btn0', '0', 0, 4, 2, ''),
    ('BtnDot', '.', 2, 4, 1, ''),
    ('BtnEquals', '=', 3, 4, 1, orange),
  ];
  final design =
      TkDesign(
          width: left * 2 + 4 * size + 3 * gap,
          height: top + 5 * size + 4 * gap + 12,
          props: {'title': t(markTr('Calculadora')), 'bg': dark},
          events: {'create': 'form_create', 'key': 'form_key'},
        )
        ..widgets.addAll([
          _w('Label', 'Display', left, 12, 4 * size + 3 * gap, 64, {
            'text': '0',
            'anchor': 'e',
            'bg': '#20232b',
            'fg': '#ffffff',
            'font_family': 'Helvetica',
            'font_size': 30,
          }),
          for (final (name, label, c, r, span, bg) in keys)
            _w(
              'Button',
              name,
              cx(c),
              cy(r),
              span * size + (span - 1) * gap,
              size,
              {
                'text': label,
                'font_family': 'Helvetica',
                'font_size': 18,
                if (bg.isNotEmpty) 'bg': bg,
              },
              {'command': '${name}_click'},
            ),
        ]);
  final digits = StringBuffer();
  for (var i = 0; i < 10; i++) {
    digits.write(
      '    def Btn${i}_click(self):\n'
      '        self.digit("$i")\n\n',
    );
  }
  final code =
      '''from decimal import Decimal


ERROR = "Error"


class Form1(FormDesign):
    def form_create(self):
        self.clear()

    # Estado: lo que se ve, el primer número y la operación pendiente.
    def clear(self):
        self.shown = "0"
        self.first = None
        self.op = None
        self.typing = False
        self.show()

    def show(self):
        self.Display.configure(text=self.shown)

    def fail(self):
        self.clear()
        self.shown = ERROR
        self.show()

    def digit(self, d):
        if self.shown == ERROR:
            self.clear()
        if not self.typing or self.shown == "0":
            self.shown = d
            self.typing = True
        elif len(self.shown.replace("-", "").replace(".", "")) < 15:
            self.shown += d
        self.show()

    def dot(self):
        if self.shown == ERROR:
            self.clear()
        if not self.typing:
            self.shown = "0"
            self.typing = True
        if "." not in self.shown:
            self.shown += "."
        self.show()

    def backspace(self):
        if self.typing:
            self.shown = self.shown[:-1] or "0"
            if self.shown in ("-", "-0"):
                self.shown = "0"
            self.show()

    def text_of(self, number):
        if number and not Decimal("1e-9") <= abs(number) < Decimal("1e15"):
            return "{:.9e}".format(number)
        whole = len(str(abs(int(number))))
        text = format(round(number, 15 - whole), "f")
        if "." in text:
            text = text.rstrip("0").rstrip(".")
        return "0" if text == "-0" else text

    def compute(self):
        if self.op is None or self.first is None or self.shown == ERROR:
            return
        a, b = self.first, Decimal(self.shown)
        try:
            if self.op == "+":
                result = a + b
            elif self.op == "-":
                result = a - b
            elif self.op == "*":
                result = a * b
            else:
                result = a / b
        except ArithmeticError:
            self.fail()
            return
        self.first = None
        self.op = None
        self.shown = self.text_of(result)
        self.typing = False
        self.show()

    def operate(self, op):
        if self.shown == ERROR:
            return
        if self.typing:
            self.compute()
        if self.shown != ERROR:
            self.first = Decimal(self.shown)
            self.op = op
            self.typing = False

    def form_key(self, event):
        key = event.char
        if not key:
            return
        if key.isdigit():
            self.digit(key)
        elif key in "+-*/":
            self.operate(key)
        elif key in ".,":
            self.dot()
        elif key in "=\\r":
            self.compute()
        elif key == "\\x1b":
            self.clear()
        elif key in "\\x08\\x7f":
            self.backspace()

$digits    def BtnDot_click(self):
        self.dot()

    def BtnClear_click(self):
        self.clear()

    def BtnSign_click(self):
        if self.shown not in (ERROR, "0"):
            self.shown = self.shown[1:] if self.shown[0] == "-" else "-" + self.shown
            self.show()

    def BtnPercent_click(self):
        if self.shown != ERROR:
            self.shown = self.text_of(Decimal(self.shown) / 100)
            self.typing = False
            self.show()

    def BtnAdd_click(self):
        self.operate("+")

    def BtnSub_click(self):
        self.operate("-")

    def BtnMul_click(self):
        self.operate("*")

    def BtnDiv_click(self):
        self.operate("/")

    def BtnEquals_click(self):
        self.compute()
''';
  return TkExample(
    'calculator',
    t(markTr('Calculadora')),
    t(markTr('Calculadora con teclado y números decimales exactos.')),
    design,
    code,
  );
}

// ---------------------------------------------------------------- tareas
TkExample _tasks(String Function(String) t) {
  const accent = '#2b5797';
  final design =
      TkDesign(
          width: 440,
          height: 480,
          props: {'title': t(markTr('Tareas')), 'bg': '#f4f5f7'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 16, 12, 408, 32, {
            'text': t(markTr('Mis tareas')),
            'anchor': 'w',
            'fg': accent,
            'font_family': 'Helvetica',
            'font_size': 20,
            'font_bold': true,
          }),
          _w(
            'Entry',
            'NewTask',
            16,
            56,
            320,
            28,
            {'font_size': 13},
            {'enter_key': 'NewTask_return'},
          ),
          _w(
            'Button',
            'BtnAdd',
            344,
            56,
            80,
            28,
            {'text': t(markTr('Añadir'))},
            {'command': 'BtnAdd_click'},
          ),
          _w(
            'Listbox',
            'Tasks',
            16,
            96,
            408,
            304,
            {'font_size': 13},
            {'double': 'Tasks_double_click', 'select': 'Tasks_select'},
          ),
          _w(
            'Button',
            'BtnDone',
            16,
            412,
            128,
            32,
            {'text': t(markTr('Hecha / pendiente')), 'state': 'disabled'},
            {'command': 'BtnDone_click'},
          ),
          _w(
            'Button',
            'BtnDelete',
            152,
            412,
            96,
            32,
            {'text': t(markTr('Borrar')), 'state': 'disabled'},
            {'command': 'BtnDelete_click'},
          ),
          _w(
            'Button',
            'BtnClean',
            256,
            412,
            168,
            32,
            {'text': t(markTr('Quitar las hechas'))},
            {'command': 'BtnClean_click'},
          ),
          _w('Label', 'Status', 16, 448, 408, 24, {'anchor': 'w'}),
        ]);
  final summary = TkPy.str(t(markTr('{0} tareas, {1} pendientes')));
  final code =
      '''import json
from pathlib import Path


class Form1(FormDesign):
    # Las tareas se guardan en un archivo de la carpeta del usuario.
    path = Path.home() / ".dmarlonstudio" / "tasks.json"

    def form_create(self):
        self.tasks = self.load()
        self.refresh()
        self.NewTask.focus_set()

    def load(self):
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
            return [{"text": str(x["text"]), "done": bool(x["done"])} for x in data]
        except (OSError, ValueError, KeyError, TypeError):
            return []

    def save(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        text = json.dumps(self.tasks, ensure_ascii=False, indent=1)
        self.path.write_text(text, encoding="utf-8")

    def refresh(self):
        self.Tasks.delete(0, "end")
        for task in self.tasks:
            mark = "✓ " if task["done"] else "○ "
            self.Tasks.insert("end", mark + task["text"])
        pending = sum(1 for task in self.tasks if not task["done"])
        self.Status.configure(text=$summary.format(len(self.tasks), pending))
        self.Tasks_select()

    def selected(self):
        chosen = self.Tasks.curselection()
        return chosen[0] if chosen else None

    def add(self):
        text = self.NewTask_var.get().strip()
        if text:
            self.tasks.append({"text": text, "done": False})
            self.NewTask_var.set("")
            self.save()
            self.refresh()

    def toggle(self):
        i = self.selected()
        if i is not None:
            self.tasks[i]["done"] = not self.tasks[i]["done"]
            self.save()
            self.refresh()
            self.Tasks.selection_set(i)
            self.Tasks_select()

    def NewTask_return(self, event=None):
        self.add()

    def BtnAdd_click(self):
        self.add()

    def Tasks_double_click(self, event=None):
        self.toggle()

    def Tasks_select(self, event=None):
        state = "disabled" if self.selected() is None else "normal"
        self.BtnDone.configure(state=state)
        self.BtnDelete.configure(state=state)

    def BtnDone_click(self):
        self.toggle()

    def BtnDelete_click(self):
        i = self.selected()
        if i is not None:
            del self.tasks[i]
            self.save()
            self.refresh()

    def BtnClean_click(self):
        self.tasks = [task for task in self.tasks if not task["done"]]
        self.save()
        self.refresh()
''';
  return TkExample(
    'tasks',
    t(markTr('Tareas')),
    t(markTr('Lista de tareas que se guarda en un archivo de su carpeta.')),
    design,
    code,
  );
}

// ------------------------------------------------------------- conversor
TkExample _converter(String Function(String) t) {
  final length = t(markTr('Longitud'));
  final weight = t(markTr('Peso'));
  final volume = t(markTr('Volumen'));
  final area = t(markTr('Superficie'));
  final temperature = t(markTr('Temperatura'));
  final categories = [length, weight, volume, area, temperature];
  final design =
      TkDesign(
          width: 440,
          height: 320,
          props: {'title': t(markTr('Conversor de unidades')), 'bg': '#f4f5f7'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'LblCategory', 16, 16, 96, 24, {
            'text': t(markTr('Magnitud')),
            'anchor': 'w',
          }),
          _w(
            'Combobox',
            'Category',
            120,
            16,
            304,
            24,
            {
              'items': categories.join('\n'),
              'text': length,
              'state': 'readonly',
            },
            {'select': 'Category_select'},
          ),
          _w('Label', 'LblValue', 16, 56, 96, 24, {
            'text': t(markTr('Cantidad')),
            'anchor': 'w',
          }),
          _w(
            'Entry',
            'Value',
            120,
            56,
            304,
            24,
            {'text': '1', 'justify': 'right'},
            {'key_up': 'Value_key_up'},
          ),
          _w('Label', 'LblFrom', 16, 96, 96, 24, {
            'text': t(markTr('De')),
            'anchor': 'w',
          }),
          _w(
            'Combobox',
            'UnitFrom',
            120,
            96,
            120,
            24,
            {'state': 'readonly'},
            {'select': 'Unit_select'},
          ),
          _w(
            'Button',
            'BtnSwap',
            248,
            94,
            48,
            28,
            {'text': '⇄'},
            {'command': 'BtnSwap_click'},
          ),
          _w(
            'Combobox',
            'UnitTo',
            304,
            96,
            120,
            24,
            {'state': 'readonly'},
            {'select': 'Unit_select'},
          ),
          _w(
            'Scale',
            'Decimals',
            16,
            136,
            408,
            64,
            {'label': t(markTr('Decimales')), 'to': 10, 'value': 4},
            {'command': 'Decimals_change'},
          ),
          _w('Label', 'Result', 16, 216, 408, 80, {
            'text': '',
            'bg': '#ffffff',
            'fg': '#2b5797',
            'relief': 'groove',
            'font_family': 'Helvetica',
            'font_size': 18,
            'font_bold': true,
          }),
        ]);
  final invalid = TkPy.str(t(markTr('Escriba un número')));
  final code =
      '''# Factores respecto de la unidad base de cada magnitud.
UNITS = {
    ${TkPy.str(length)}: {
        "mm": 0.001,
        "cm": 0.01,
        "m": 1,
        "km": 1000,
        "in": 0.0254,
        "ft": 0.3048,
        "yd": 0.9144,
        "mi": 1609.344,
    },
    ${TkPy.str(weight)}: {
        "mg": 0.000001,
        "g": 0.001,
        "kg": 1,
        "t": 1000,
        "oz": 0.028349523125,
        "lb": 0.45359237,
    },
    ${TkPy.str(volume)}: {
        "ml": 0.001,
        "l": 1,
        "m³": 1000,
        "gal": 3.785411784,
        "pt": 0.473176473,
    },
    ${TkPy.str(area)}: {
        "m²": 1,
        "ha": 10000,
        "km²": 1000000,
        "ft²": 0.09290304,
        "acre": 4046.8564224,
    },
}
TEMPERATURE = ${TkPy.str(temperature)}
DEGREES = ["°C", "°F", "K"]


def to_celsius(value, unit):
    if unit == "°F":
        return (value - 32) * 5 / 9
    return value - 273.15 if unit == "K" else value


def from_celsius(value, unit):
    if unit == "°F":
        return value * 9 / 5 + 32
    return value + 273.15 if unit == "K" else value


class Form1(FormDesign):
    def form_create(self):
        self.load_units()

    def units(self):
        category = self.Category_var.get()
        return DEGREES if category == TEMPERATURE else list(UNITS[category])

    def load_units(self):
        names = self.units()
        self.UnitFrom.configure(values=names)
        self.UnitTo.configure(values=names)
        self.UnitFrom_var.set(names[0])
        self.UnitTo_var.set(names[1])
        self.convert()

    def result(self, value):
        source, target = self.UnitFrom_var.get(), self.UnitTo_var.get()
        if self.Category_var.get() == TEMPERATURE:
            return from_celsius(to_celsius(value, source), target)
        factors = UNITS[self.Category_var.get()]
        return value * factors[source] / factors[target]

    def convert(self):
        text = self.Value_var.get().strip().replace(",", ".")
        try:
            value = float(text)
        except ValueError:
            self.Result.configure(text=$invalid)
            return
        digits = int(self.Decimals_var.get())
        amount = "{:,.{}f}".format(self.result(value), digits)
        self.Result.configure(text=amount + " " + self.UnitTo_var.get())

    def Category_select(self, event=None):
        self.load_units()

    def Unit_select(self, event=None):
        self.convert()

    def Value_key_up(self, event=None):
        self.convert()

    def Decimals_change(self, value=None):
        self.convert()

    def BtnSwap_click(self):
        source = self.UnitFrom_var.get()
        self.UnitFrom_var.set(self.UnitTo_var.get())
        self.UnitTo_var.set(source)
        self.convert()
''';
  return TkExample(
    'converter',
    t(markTr('Conversor de unidades')),
    t(markTr('Longitud, peso, volumen, superficie y temperatura.')),
    design,
    code,
  );
}

// -------------------------------------------------------- contactos (API)
TkExample _contacts(String Function(String) t) {
  final design =
      TkDesign(
          width: 520,
          height: 520,
          props: {
            'title': t(markTr('Contactos de Odoo / ERPSqlite')),
            'bg': '#f4f5f7',
          },
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Help', 16, 8, 488, 40, {
            'text': t(
              markTr(
                'Lee los contactos de un Odoo o un ERPSqlite con su API XML-RPC (en ERPSqlite: Ajustes → API externa). La clave no se guarda.',
              ),
            ),
            'anchor': 'w',
            'justify': 'left',
            'wraplength': 488,
          }),
          _w('Label', 'LblUrl', 16, 56, 80, 24, {
            'text': t(markTr('Servidor')),
            'anchor': 'w',
          }),
          _w('Entry', 'Url', 104, 56, 400, 24, {
            'text': 'http://127.0.0.1:8169',
          }),
          _w('Label', 'LblDb', 16, 88, 80, 24, {
            'text': t(markTr('Base')),
            'anchor': 'w',
          }),
          _w('Entry', 'Db', 104, 88, 400, 24),
          _w('Label', 'LblLogin', 16, 120, 80, 24, {
            'text': t(markTr('Usuario')),
            'anchor': 'w',
          }),
          _w('Entry', 'Login', 104, 120, 160, 24),
          _w('Label', 'LblKey', 280, 120, 56, 24, {
            'text': t(markTr('Clave')),
            'anchor': 'w',
          }),
          _w('Entry', 'Key', 344, 120, 160, 24, {'show': '•'}),
          _w('Label', 'LblSearch', 16, 160, 80, 24, {
            'text': t(markTr('Buscar')),
            'anchor': 'w',
          }),
          _w('Entry', 'Search', 104, 160, 296, 24, const {}, {
            'enter_key': 'Search_return',
          }),
          _w(
            'Button',
            'BtnSearch',
            408,
            156,
            96,
            32,
            {'text': t(markTr('Consultar'))},
            {'command': 'BtnSearch_click'},
          ),
          _w('Listbox', 'Results', 16, 200, 488, 180, const {}, {
            'select': 'Results_select',
          }),
          _w('Text', 'Detail', 16, 392, 488, 88, {'state': 'disabled'}),
          _w('Label', 'Status', 16, 488, 488, 24, {'anchor': 'w'}),
        ]);
  final missing = TkPy.str(
    t(markTr('Rellene servidor, base, usuario y clave.')),
  );
  final denied = TkPy.str(t(markTr('Usuario o clave incorrectos.')));
  final found = TkPy.str(t(markTr('{0} contactos')));
  final failed = TkPy.str(t(markTr('No se pudo consultar: {0}')));
  final code =
      '''import socket
import xmlrpc.client


class Form1(FormDesign):
    def form_create(self):
        self.rows = []
        socket.setdefaulttimeout(10)

    def query(self, term):
        """Busca contactos por la API (como la de Odoo)."""
        url = self.Url_var.get().strip().rstrip("/")
        db = self.Db_var.get().strip()
        login = self.Login_var.get().strip()
        key = self.Key_var.get()
        if not (url and db and login and key):
            raise ValueError($missing)
        common = xmlrpc.client.ServerProxy(url + "/xmlrpc/2/common", allow_none=True)
        uid = common.authenticate(db, login, key, {})
        if not uid:
            raise ValueError($denied)
        models = xmlrpc.client.ServerProxy(url + "/xmlrpc/2/object", allow_none=True)
        domain = [["name", "ilike", term]] if term else []
        return models.execute_kw(
            db,
            uid,
            key,
            "res.partner",
            "search_read",
            [domain],
            {"fields": ["name", "email", "phone", "city"], "limit": 100},
        )

    def search(self):
        self.show("")
        self.Results.delete(0, "end")
        try:
            self.rows = self.query(self.Search_var.get().strip())
        except (OSError, ValueError, xmlrpc.client.Error) as error:
            self.rows = []
            self.Status.configure(text=$failed.format(error))
            return
        for row in self.rows:
            self.Results.insert("end", row["name"])
        self.Status.configure(text=$found.format(len(self.rows)))

    def show(self, text):
        self.Detail.configure(state="normal")
        self.Detail.delete("1.0", "end")
        self.Detail.insert("1.0", text)
        self.Detail.configure(state="disabled")

    def Search_return(self, event=None):
        self.search()

    def BtnSearch_click(self):
        self.search()

    def Results_select(self, event=None):
        chosen = self.Results.curselection()
        if chosen:
            row = self.rows[chosen[0]]
            lines = [row.get(k) for k in ("name", "email", "phone", "city")]
            self.show("\\n".join(str(x) for x in lines if x))
''';
  return TkExample(
    'contacts',
    t(markTr('Contactos de Odoo / ERPSqlite')),
    t(markTr('Consulta los contactos de un Odoo o un ERPSqlite con XML-RPC.')),
    design,
    code,
  );
}

// ------------------------------------------------------------ cronómetro
TkExample _stopwatch(String Function(String) t) {
  final file = t(markTr('Archivo')), help = t(markTr('Ayuda'));
  final reset = t(markTr('Reiniciar')), quit = t(markTr('Salir'));
  final about = t(markTr('Acerca de'));
  final start = t(markTr('Iniciar')), stop = t(markTr('Parar'));
  final design =
      TkDesign(
          width: 360,
          height: 240,
          props: {'title': t(markTr('Cronómetro')), 'bg': '#f4f5f7'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            320,
            8,
            32,
            32,
            {'items': '$file\n  $reset\n  -\n  $quit\n$help\n  $about'},
            {'command': 'Menu1_click'},
          ),
          _w(
            'Timer',
            'Timer1',
            320,
            48,
            32,
            32,
            {'interval': 100, 'enabled': false},
            {'command': 'Timer1_timer'},
          ),
          _w('Label', 'Display', 16, 24, 296, 64, {
            'text': '00:00.0',
            'font_family': 'Helvetica',
            'font_size': 40,
            'font_bold': true,
            'fg': '#2b5797',
          }),
          _w('Progressbar', 'Progress', 16, 104, 328, 16, {'maximum': 60}),
          _w(
            'Button',
            'BtnStart',
            16,
            136,
            160,
            36,
            {'text': start},
            {'command': 'BtnStart_click'},
          ),
          _w(
            'Button',
            'BtnReset',
            184,
            136,
            160,
            36,
            {'text': reset},
            {'command': 'BtnReset_click'},
          ),
          _w('StatusBar', 'Status', 0, 216, 360, 24, {
            'text': t(markTr('Listo')),
          }),
        ]);
  String py(String s) => TkPy.str(s);
  final code =
      '''import time
from tkinter import messagebox


class Form1(FormDesign):
    def form_create(self):
        self.started = None
        self.elapsed = 0.0
        self.show()

    def now(self):
        running = time.monotonic() - self.started if self.started is not None else 0.0
        return self.elapsed + running

    def show(self):
        minutes, seconds = divmod(self.now(), 60)
        self.Display.configure(text="%02d:%04.1f" % (minutes, seconds))
        self.Progress.configure(value=seconds)

    def Timer1_timer(self):
        self.show()

    def BtnStart_click(self):
        if self.started is None:
            self.started = time.monotonic()
            self.Timer1.start()
            self.BtnStart.configure(text=${py(stop)})
            self.Status.configure(text=${py(t(markTr('En marcha')))})
        else:
            self.elapsed = self.now()
            self.started = None
            self.Timer1.stop()
            self.BtnStart.configure(text=${py(start)})
            self.Status.configure(text=${py(t(markTr('Parado')))})
        self.show()

    def BtnReset_click(self):
        self.elapsed = 0.0
        if self.started is not None:
            self.started = time.monotonic()
        self.show()
        self.Status.configure(text=${py(t(markTr('Reiniciado')))})

    def Menu1_click(self, item):
        if item == ${py('$file/$reset')}:
            self.BtnReset_click()
        elif item == ${py('$file/$quit')}:
            self.root.destroy()
        elif item == ${py('$help/$about')}:
            messagebox.showinfo(
                ${py(t(markTr('Cronómetro')))},
                ${py(t(markTr('Ejemplo de DMarlon Studio con menú, temporizador, barra de progreso y barra de estado.')))},
            )
''';
  return TkExample(
    'stopwatch',
    t(markTr('Cronómetro')),
    t(
      markTr(
        'Cronómetro con menú, temporizador, barra de progreso y barra de estado.',
      ),
    ),
    design,
    code,
  );
}

// ----------------------------------------------------- ficha de cliente
TkExample _customer(String Function(String) t) {
  const top = 40, gap = 40;
  final pages = [
    t(markTr('General')),
    t(markTr('Contacto')),
    t(markTr('Notas')),
  ].join('\n');
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  final design =
      TkDesign(
          width: 480,
          height: 400,
          props: {'title': t(markTr('Ficha de cliente')), 'bg': '#f4f5f7'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'PageControl',
            'Pages',
            16,
            16,
            448,
            288,
            {'pages': pages},
            {'change': 'Pages_change'},
          ),
          on(
            _w('Label', 'LblName', 16, top, 112, 24, {
              'text': t(markTr('Nombre')),
              'anchor': 'w',
            }),
            0,
          ),
          on(_w('Entry', 'CustName', 136, top, 280, 24), 0),
          on(
            _w('Label', 'LblKind', 16, top + gap, 112, 24, {
              'text': t(markTr('Tipo')),
              'anchor': 'w',
            }),
            0,
          ),
          on(
            _w('Combobox', 'Kind', 136, top + gap, 200, 24, {
              'items': [
                t(markTr('Particular')),
                t(markTr('Empresa')),
                t(markTr('Autónomo')),
              ].join('\n'),
              'state': 'readonly',
            }),
            0,
          ),
          on(
            _w('Checkbutton', 'Vip', 136, top + gap * 2, 200, 24, {
              'text': t(markTr('Cliente preferente')),
            }),
            0,
          ),
          on(
            _w('Label', 'LblEmail', 16, top, 112, 24, {
              'text': t(markTr('Correo')),
              'anchor': 'w',
            }),
            1,
          ),
          on(_w('Entry', 'Email', 136, top, 280, 24), 1),
          on(
            _w('Label', 'LblPhone', 16, top + gap, 112, 24, {
              'text': t(markTr('Teléfono')),
              'anchor': 'w',
            }),
            1,
          ),
          on(_w('Entry', 'Phone', 136, top + gap, 200, 24), 1),
          on(
            _w('Label', 'LblChannels', 16, top + gap * 2, 112, 24, {
              'text': t(markTr('Avisar por')),
              'anchor': 'w',
            }),
            1,
          ),
          on(
            _w('Listbox', 'Channels', 136, top + gap * 2, 200, 88, {
              'items': [
                t(markTr('Correo')),
                t(markTr('Teléfono')),
                'WhatsApp',
              ].join('\n'),
              'selectmode': 'multiple',
            }),
            1,
          ),
          on(_w('Text', 'Notes', 16, top, 400, 216), 2),
          _w(
            'Button',
            'BtnSave',
            16,
            320,
            120,
            32,
            {'text': t(markTr('Guardar'))},
            {'command': 'BtnSave_click'},
          ),
          _w('StatusBar', 'Status', 0, 376, 480, 24, {
            'text': t(markTr('Ficha nueva')),
          }),
        ]);
  String py(String s) => TkPy.str(s);
  final code =
      '''class Form1(FormDesign):
    def form_create(self):
        self.Kind.current(0)
        self.CustName.focus_set()

    def Pages_change(self, event=None):
        page = self.Pages.index("current")
        self.Status.configure(text=${py(t(markTr('Página {0}')))}.format(page + 1))

    def BtnSave_click(self):
        name = self.CustName_var.get().strip()
        if not name:
            self.Pages.select(0)
            self.CustName.focus_set()
            self.Status.configure(text=${py(t(markTr('Escriba el nombre del cliente.')))})
            return
        channels = [self.Channels.get(i) for i in self.Channels.curselection()]
        text = ${py(t(markTr('Guardado: {0} ({1}), avisar por: {2}')))}
        self.Status.configure(
            text=text.format(name, self.Kind_var.get(), ", ".join(channels) or "-")
        )
''';
  return TkExample(
    'customer',
    t(markTr('Ficha de cliente')),
    t(
      markTr(
        'Ficha con un control de páginas, listas desplegables, una lista y barra de estado.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------- editor de notas
TkExample _notes(String Function(String) t) {
  final home = t(markTr('Inicio')), file = t(markTr('Archivo'));
  final edit = t(markTr('Edición')), insert = t(markTr('Insertar'));
  final dates = t(markTr('Fechas'));
  final newDoc = t(markTr('Nuevo')), open = t(markTr('Abrir'));
  final save = t(markTr('Guardar')), upper = t(markTr('Mayúsculas'));
  final lower = t(markTr('Minúsculas')), clear = t(markTr('Borrar todo'));
  final today = t(markTr('Fecha')), now = t(markTr('Hora'));
  final items = [
    home,
    '  $file',
    '    $newDoc | new',
    '    $open | open',
    '    $save | save',
    '  $edit',
    '    $upper | up',
    '    $lower | down',
    '    $clear | delete',
    insert,
    '  $dates',
    '    $today | calendar',
    '    $now | refresh',
  ].join('\n');
  final filter =
      '${t(markTr('Texto'))}|*.txt\n'
      '${t(markTr('Markdown'))}|*.md';
  final design =
      TkDesign(
          width: 560,
          height: 400,
          props: {'title': t(markTr('Editor de notas')), 'position': 'center'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Ribbon',
            'Ribbon1',
            0,
            0,
            560,
            92,
            {'items': items},
            {'command': 'Ribbon1_click'},
          ),
          _w('Text', 'Note', 8, 100, 544, 268, {'wrap': 'word'}),
          _w('OpenDialog', 'OpenNote', 520, 100, 32, 32, {
            'title': t(markTr('Abrir una nota')),
            'filter': filter,
          }),
          _w('SaveDialog', 'SaveNote', 520, 140, 32, 32, {
            'title': t(markTr('Guardar la nota')),
            'filter': filter,
            'defaultext': '.txt',
            'filename': t(markTr('nota.txt')),
          }),
          _w('StatusBar', 'Status', 0, 376, 560, 24, {
            'text': t(markTr('Nota nueva')),
            'icon': 'edit',
          }),
        ]);
  String py(String s) => TkPy.str(s);
  final code =
      '''import datetime


class Form1(FormDesign):
    def form_create(self):
        self.Note.focus_set()

    def text(self):
        return self.Note.get("1.0", "end-1c")

    def set_text(self, text):
        self.Note.delete("1.0", "end")
        self.Note.insert("1.0", text)

    def Ribbon1_click(self, item):
        if item == ${py('$home/$file/$newDoc')}:
            self.set_text("")
            self.Status.set(${py(t(markTr('Nota nueva')))}, icon="new")
        elif item == ${py('$home/$file/$open')}:
            found = self.OpenNote.read_text()
            if found:
                path, text = found
                self.set_text(text)
                self.Status.set(path, icon="open")
        elif item == ${py('$home/$file/$save')}:
            path = self.SaveNote.write_text(self.text())
            if path:
                self.Status.set(${py(t(markTr('Guardada: {0}')))}.format(path), icon="check")
        elif item == ${py('$home/$edit/$upper')}:
            self.set_text(self.text().upper())
        elif item == ${py('$home/$edit/$lower')}:
            self.set_text(self.text().lower())
        elif item == ${py('$home/$edit/$clear')}:
            self.set_text("")
        elif item == ${py('$insert/$dates/$today')}:
            self.Note.insert("end", datetime.date.today().isoformat())
        elif item == ${py('$insert/$dates/$now')}:
            self.Note.insert("end", datetime.datetime.now().strftime("%H:%M"))
''';
  return TkExample(
    'notes',
    t(markTr('Editor de notas')),
    t(
      markTr(
        'Editor con cinta de opciones, diálogos Abrir y Guardar y barra de estado con icono.',
      ),
    ),
    design,
    code,
  );
}

// ---------------------------------------------------------- consulta API
TkExample _apiQuery(String Function(String) t) {
  final design =
      TkDesign(
          width: 560,
          height: 400,
          props: {'title': t(markTr('Consulta API')), 'position': 'center'},
        )
        ..widgets.addAll([
          _w('Label', 'LblKey', 16, 16, 120, 24, {
            'text': t(markTr('Clave (opcional)')),
            'anchor': 'w',
          }),
          _w('Password', 'ApiKey', 136, 16, 200, 24, {
            'hint': t(markTr('Solo si la API la pide')),
          }),
          _w(
            'Button',
            'BtnLoad',
            352,
            12,
            120,
            32,
            {'text': t(markTr('Cargar'))},
            {'command': 'BtnLoad_click'},
          ),
          _w('Treeview', 'Users', 16, 56, 528, 304, {
            'columns': [
              'id|#|40',
              'name|${t(markTr('Nombre'))}|180',
              'email|${t(markTr('Correo'))}|180',
              'city|${t(markTr('Ciudad'))}|120',
            ].join('\n'),
          }),
          _w(
            'RestClient',
            'Api',
            496,
            8,
            32,
            32,
            {'base_url': 'https://jsonplaceholder.typicode.com', 'timeout': 15},
            {'done': 'Api_done', 'error': 'Api_error'},
          ),
          _w('StatusBar', 'Status', 0, 376, 560, 24, {
            'text': t(markTr('Pulse Cargar para leer los usuarios.')),
            'icon': 'info',
          }),
        ]);
  String py(String s) => TkPy.str(s);
  final code =
      '''class Form1(FormDesign):
    def BtnLoad_click(self):
        key = self.ApiKey.get().strip()
        self.Api.headers = "X-Api-Key: " + key if key else ""
        self.Status.set(${py(t(markTr('Cargando…')))}, icon="refresh")
        self.Api.get_async("users")

    def Api_done(self, result):
        self.Users.delete(*self.Users.get_children())
        for user in result or []:
            city = (user.get("address") or {}).get("city", "")
            self.Users.insert(
                "", "end", values=(user.get("id"), user.get("name"), user.get("email"), city)
            )
        self.Status.set(${py(t(markTr('{0} usuarios')))}.format(len(result or [])), icon="check")

    def Api_error(self, error):
        self.Status.set(str(error), icon="delete")
''';
  return TkExample(
    'api_query',
    t(markTr('Consulta API')),
    t(
      markTr(
        'Lee una API JSON en segundo plano y la muestra en una tabla, con una clave opcional.',
      ),
    ),
    design,
    code,
  );
}
