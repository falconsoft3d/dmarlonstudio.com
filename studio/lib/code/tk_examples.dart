import '../i18n/tr.dart';
import 'tk_codegen.dart';
import 'tk_model.dart';

/// Comentario con el que empieza la unidad de una ventana nueva.
String tkUnitComment({bool web = false}) => web
    ? tr(
        '# Código de la aplicación web: corre en el servidor, en Python. Cada evento\n'
        '# del diseño es un método de esta clase; self.root es la página y\n'
        '# self.<Nombre>, cada componente, con las llamadas de tkinter. También\n'
        '# self.value("Nombre"), self.value("Nombre", valor) y self.notify(texto).',
      )
    : tr(
        '# Código de la ventana: cada evento del diseño es un método de esta clase.\n'
        '# self.root es la ventana y self.<Nombre>, cada componente.',
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
];

/// Los ejemplos web: el mismo diseño y el mismo código que los de escritorio,
/// que es lo que hay que poder hacer con los de cualquier usuario.
List<TkExample> tkWebExamples(String Function(String) t) => [
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
