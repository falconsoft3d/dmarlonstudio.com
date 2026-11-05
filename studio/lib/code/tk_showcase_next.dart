part of 'tk_examples.dart';

// Ejemplos de Next.js: la página es el diseño y el código, el mismo
// JavaScript de Electron (corre en el navegador).

/// Los ejemplos de Next.js.
List<TkExample> tkNextExamples(String Function(String) t) {
  final calc = _electronCalculator(t);
  return [
    TkExample(
      'next_calculator',
      t(markTr('Calculadora (Next.js)')),
      t(
        markTr(
          'La calculadora como página de Next.js: el mismo diseño y el mismo JavaScript que la de Electron.',
        ),
      ),
      TkDesign.fromJson({...calc.design.toJson(), 'target': tkTargetNext}),
      calc.code,
    ),
    _nextTasks(t),
  ];
}

// ------------------------------------------------------------------ tareas
TkExample _nextTasks(String Function(String) t) {
  final app = t(markTr('Lista de tareas'));
  final design =
      TkDesign(
          width: 460,
          height: 420,
          target: tkTargetNext,
          props: {'title': app, 'bg': '#ffffff'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 12, 428, 32, {
            'text': app,
            'anchor': 'w',
            'font_size': 20,
            'font_bold': true,
            'fg': '#111827',
          }),
          _w('Entry', 'NewTask', 16, 54, 320, 30, {}, {
            'enter_key': 'NewTask_return',
          }),
          _w(
            'Button',
            'Add',
            344,
            54,
            100,
            30,
            {'text': t(markTr('Añadir')), 'bg': '#111827', 'fg': '#ffffff'},
            {'command': 'Add_click'},
          ),
          _w('Listbox', 'Tasks', 16, 94, 428, 250, {}, {
            'double': 'Tasks_double',
          }),
          _w(
            'Button',
            'Done',
            16,
            354,
            200,
            30,
            {'text': t(markTr('Marcar como hecha'))},
            {'command': 'Done_click'},
          ),
          _w(
            'Button',
            'Clear',
            224,
            354,
            220,
            30,
            {'text': t(markTr('Quitar las hechas'))},
            {'command': 'Clear_click'},
          ),
          _w('StatusBar', 'Status', 0, 396, 460, 24, {'text': ''}),
        ]);
  final code =
      '''// ${t(markTr('Tareas guardadas en el navegador con this.storage.'))}
const DONE = "✓ ";
const PENDING = ${_jsStr(t(markTr('{0} pendientes de {1}')))};

class Form1 extends FormDesign {
  async form_create() {
    this.tasks = await this.storage.get("tasks", []);
    this.show();
  }

  show() {
    this.Tasks.items = this.tasks.map((task) => (task.done ? DONE : "") + task.text);
    const pending = this.tasks.filter((task) => !task.done).length;
    this.Status.text = PENDING.replace("{0}", pending).replace("{1}", this.tasks.length);
    this.storage.set("tasks", this.tasks);
  }

  Add_click() {
    const text = this.NewTask.text.trim();
    if (!text) return;
    this.tasks.push({ text, done: false });
    this.NewTask.text = "";
    this.show();
    this.NewTask.focus();
  }

  NewTask_return(event) {
    this.Add_click();
  }

  Done_click() {
    const i = this.Tasks.index;
    if (i < 0) return;
    this.tasks[i].done = !this.tasks[i].done;
    this.show();
  }

  Tasks_double(event) {
    this.Done_click();
  }

  Clear_click() {
    this.tasks = this.tasks.filter((task) => !task.done);
    this.show();
  }
}
''';
  return TkExample(
    'next_tasks',
    t(markTr('Lista de tareas (Next.js)')),
    t(
      markTr(
        'Una página de Next.js con tareas que se guardan en el navegador: añadir, marcar como hecha y quitar las hechas.',
      ),
    ),
    design,
    code,
  );
}
