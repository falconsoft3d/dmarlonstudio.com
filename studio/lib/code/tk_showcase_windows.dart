part of 'tk_examples.dart';

// ------------------------------------------------------- ventanas y diálogos
/// Ventanas que abren otras y todos los diálogos de tkinter: mensajes,
/// preguntas, pedir datos, una ventana secundaria que devuelve un resultado,
/// un diálogo modal propio y varias ventanas no modales a la vez.
TkExample _windows(String Function(String) t) {
  final app = t(markTr('Ventanas y diálogos'));
  Map<String, Object?> button(String text) => {'text': text};
  TkWidget btn(String name, int x, int y, String text) => _w(
    'Button',
    name,
    x,
    y,
    224,
    32,
    button(text),
    {'command': '${name}_click'},
  );
  final design =
      TkDesign(
          width: 760,
          height: 560,
          props: {'title': app, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 24, 16, 712, 32, _title(app)),
          _w(
            'Label',
            'Intro',
            24,
            48,
            712,
            24,
            _label(
              t(
                markTr(
                  'Cada botón abre un diálogo u otra ventana; lo que devuelven queda en el registro.',
                ),
              ),
            ),
          ),
          _w(
            'Label',
            'Messages',
            24,
            88,
            224,
            24,
            _title(t(markTr('Mensajes')), size: 13),
          ),
          btn('BtnInfo', 24, 120, t(markTr('Información'))),
          btn('BtnWarning', 24, 160, t(markTr('Aviso'))),
          btn('BtnError', 24, 200, t(markTr('Error'))),
          btn('BtnAsk', 24, 240, t(markTr('Pregunta Sí / No / Cancelar'))),
          _w(
            'Label',
            'Ask',
            268,
            88,
            224,
            24,
            _title(t(markTr('Pedir datos')), size: 13),
          ),
          btn('BtnName', 268, 120, t(markTr('Pedir un nombre'))),
          btn('BtnAge', 268, 160, t(markTr('Pedir un número'))),
          btn('BtnColor', 268, 200, t(markTr('Elegir un color'))),
          btn('BtnFile', 268, 240, t(markTr('Elegir un archivo'))),
          _w(
            'Label',
            'Windows',
            512,
            88,
            224,
            24,
            _title(t(markTr('Otras ventanas')), size: 13),
          ),
          btn('BtnCustomer', 512, 120, t(markTr('Ficha de cliente…'))),
          btn('BtnOptions', 512, 160, t(markTr('Opciones (modal)…'))),
          btn('BtnNote', 512, 200, t(markTr('Nueva nota'))),
          btn('BtnCloseAll', 512, 240, t(markTr('Cerrar las notas'))),
          _w(
            'Label',
            'LogTitle',
            24,
            292,
            712,
            24,
            _title(t(markTr('Registro')), size: 13),
          ),
          _w('Listbox', 'Log', 24, 320, 712, 196),
          _w('OpenDialog', 'PickFile', 712, 16, 24, 24, {
            'title': t(markTr('Elegir un archivo')),
          }),
          _w('StatusBar', 'Status', 0, 536, 760, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import tkinter as tk
from tkinter import colorchooser, messagebox, simpledialog

APP = ${_py(app)}
T_INFO = ${_py(t(markTr('Los datos se han guardado.')))}
T_WARNING = ${_py(t(markTr('Queda poco espacio en el disco.')))}
T_ERROR = ${_py(t(markTr('No se pudo conectar con el servidor.')))}
T_ASK = ${_py(t(markTr('¿Guardar los cambios antes de salir?')))}
T_NAME = ${_py(t(markTr('¿Cómo se llama?')))}
T_AGE = ${_py(t(markTr('¿Cuántos años tiene?')))}
T_YES = ${_py(t(markTr('Sí')))}
T_NO = ${_py(t(markTr('No')))}
T_CANCELLED = ${_py(t(markTr('cancelado')))}
T_CUSTOMER = ${_py(t(markTr('Ficha de cliente')))}
T_FIELD_NAME = ${_py(t(markTr('Nombre')))}
T_FIELD_MAIL = ${_py(t(markTr('Correo')))}
T_SAVE = ${_py(t(markTr('Guardar')))}
T_CANCEL = ${_py(t(markTr('Cancelar')))}
T_MAIL_BAD = ${_py(t(markTr('Escriba un correo con @.')))}
T_OPTIONS = ${_py(t(markTr('Opciones')))}
T_DARK = ${_py(t(markTr('Modo oscuro')))}
T_SIZE = ${_py(t(markTr('Tamaño de letra')))}
T_ACCEPT = ${_py(t(markTr('Aceptar')))}
T_NOTE = ${_py(t(markTr('Nota {0}')))}
T_NOTE_TEXT = ${_py(t(markTr('Escriba aquí. Esta ventana no bloquea a las demás.')))}
T_LOG = ${_py(t(markTr('{0}: {1}')))}
T_OPEN = ${_py(t(markTr('{0} notas abiertas')))}


class CustomerWindow(tk.Toplevel):
    """Ventana secundaria: recibe datos, deja editarlos y devuelve el
    resultado a quien la abrió con on_save."""

    def __init__(self, parent, data, on_save):
        super().__init__(parent)
        self.title(T_CUSTOMER)
        self.resizable(False, False)
        self.transient(parent)
        self.on_save = on_save
        self.columnconfigure(1, weight=1)
        self.name = tk.StringVar(value=data.get("name", ""))
        self.mail = tk.StringVar(value=data.get("mail", ""))
        for row, (label, var) in enumerate(
            ((T_FIELD_NAME, self.name), (T_FIELD_MAIL, self.mail))
        ):
            tk.Label(self, text=label).grid(row=row, column=0, sticky="w", padx=12, pady=6)
            tk.Entry(self, textvariable=var, width=32).grid(
                row=row, column=1, sticky="ew", padx=12, pady=6
            )
        self.error = tk.Label(self, text="", fg="#c62828")
        self.error.grid(row=2, column=0, columnspan=2, sticky="w", padx=12)
        buttons = tk.Frame(self)
        buttons.grid(row=3, column=0, columnspan=2, sticky="e", padx=12, pady=12)
        tk.Button(buttons, text=T_CANCEL, command=self.destroy).pack(side="right")
        tk.Button(buttons, text=T_SAVE, command=self.save).pack(side="right", padx=6)
        self.bind("<Return>", lambda event: self.save())
        self.bind("<Escape>", lambda event: self.destroy())
        center_over(self, parent)

    def save(self):
        if "@" not in self.mail.get():
            self.error.configure(text=T_MAIL_BAD)
            return
        self.on_save({"name": self.name.get().strip(), "mail": self.mail.get().strip()})
        self.destroy()


class OptionsDialog(tk.Toplevel):
    """Diálogo modal propio: la ventana principal espera hasta que se
    cierre y lee result (None si se canceló)."""

    def __init__(self, parent, options):
        super().__init__(parent)
        self.title(T_OPTIONS)
        self.resizable(False, False)
        self.transient(parent)
        self.result = None
        self.dark = tk.BooleanVar(value=options["dark"])
        self.size = tk.IntVar(value=options["size"])
        tk.Checkbutton(self, text=T_DARK, variable=self.dark).pack(anchor="w", padx=16, pady=(14, 4))
        tk.Label(self, text=T_SIZE).pack(anchor="w", padx=16)
        tk.Scale(self, from_=9, to=24, orient="horizontal", variable=self.size).pack(
            fill="x", padx=16
        )
        buttons = tk.Frame(self)
        buttons.pack(anchor="e", padx=16, pady=12)
        tk.Button(buttons, text=T_CANCEL, command=self.destroy).pack(side="right")
        tk.Button(buttons, text=T_ACCEPT, command=self.accept).pack(side="right", padx=6)
        self.bind("<Escape>", lambda event: self.destroy())
        center_over(self, parent)
        # Modal: todos los clics van a este diálogo hasta que se cierre.
        self.wait_visibility()
        self.grab_set()
        self.focus_set()

    def accept(self):
        self.result = {"dark": self.dark.get(), "size": self.size.get()}
        self.destroy()


def center_over(window, parent):
    """Centra window sobre parent."""
    window.update_idletasks()
    x = parent.winfo_rootx() + (parent.winfo_width() - window.winfo_width()) // 2
    y = parent.winfo_rooty() + (parent.winfo_height() - window.winfo_height()) // 3
    window.geometry("+%d+%d" % (max(x, 0), max(y, 0)))


class Form1(FormDesign):
    def form_create(self):
        self.customer = {"name": "Ana García", "mail": "ana@example.com"}
        self.options = {"dark": False, "size": 12}
        self.notes = []
        self.count = 0

    def log(self, what, value):
        self.Log.insert("end", T_LOG.format(what, value))
        self.Log.see("end")
        self.Status.set(T_LOG.format(what, value))

    # ---------------------------------------------------------- mensajes
    def BtnInfo_click(self):
        messagebox.showinfo(APP, T_INFO, parent=self.root)
        self.log("showinfo", "ok")

    def BtnWarning_click(self):
        messagebox.showwarning(APP, T_WARNING, parent=self.root)
        self.log("showwarning", "ok")

    def BtnError_click(self):
        messagebox.showerror(APP, T_ERROR, parent=self.root)
        self.log("showerror", "ok")

    def BtnAsk_click(self):
        answer = messagebox.askyesnocancel(APP, T_ASK, parent=self.root)
        self.log("askyesnocancel", {True: T_YES, False: T_NO}.get(answer, T_CANCELLED))

    # ------------------------------------------------------- pedir datos
    def BtnName_click(self):
        name = simpledialog.askstring(APP, T_NAME, parent=self.root)
        self.log("askstring", name if name is not None else T_CANCELLED)

    def BtnAge_click(self):
        age = simpledialog.askinteger(APP, T_AGE, parent=self.root, minvalue=0, maxvalue=130)
        self.log("askinteger", age if age is not None else T_CANCELLED)

    def BtnColor_click(self):
        rgb, color = colorchooser.askcolor(parent=self.root, title=APP)
        if color:
            self.Status.configure(bg=color)
        self.log("askcolor", color or T_CANCELLED)

    def BtnFile_click(self):
        path = self.PickFile.execute()
        self.log("OpenDialog", path or T_CANCELLED)

    # ---------------------------------------------------- otras ventanas
    def BtnCustomer_click(self):
        CustomerWindow(self.root, self.customer, self.customer_saved)

    def customer_saved(self, data):
        self.customer = data
        self.log(T_CUSTOMER, "%s <%s>" % (data["name"], data["mail"]))

    def BtnOptions_click(self):
        dialog = OptionsDialog(self.root, self.options)
        self.root.wait_window(dialog)
        if dialog.result is None:
            return self.log(T_OPTIONS, T_CANCELLED)
        self.options = dialog.result
        self.Log.configure(font=("TkDefaultFont", self.options["size"]))
        dark = self.options["dark"]
        self.Log.configure(bg="#1e1f22" if dark else "white", fg="#e6e8eb" if dark else "black")
        self.log(T_OPTIONS, self.options)

    def BtnNote_click(self):
        self.count += 1
        note = tk.Toplevel(self.root)
        note.title(T_NOTE.format(self.count))
        note.geometry("320x200+%d+%d" % (
            self.root.winfo_rootx() + 40 * (self.count % 8),
            self.root.winfo_rooty() + 40 * (self.count % 8),
        ))
        text = tk.Text(note, wrap="word", bg="#fff8c4")
        text.insert("1.0", T_NOTE_TEXT)
        text.pack(fill="both", expand=True)
        note.protocol("WM_DELETE_WINDOW", lambda: self.close_note(note))
        self.notes.append(note)
        self.log(T_NOTE.format(self.count), T_OPEN.format(len(self.notes)))

    def close_note(self, note):
        if note in self.notes:
            self.notes.remove(note)
        note.destroy()
        self.Status.set(T_OPEN.format(len(self.notes)))

    def BtnCloseAll_click(self):
        for note in list(self.notes):
            self.close_note(note)
        self.log(T_NOTE.format("*"), T_OPEN.format(0))

    def form_close(self, *args):
        self.root.destroy()
''';
  return TkExample(
    'windows_dialogs',
    app,
    t(
      markTr(
        'Ventanas que abren otras y todos los diálogos: mensajes, preguntas, pedir datos, una ficha que devuelve el resultado, un diálogo modal y notas no modales.',
      ),
    ),
    design,
    code,
  );
}
