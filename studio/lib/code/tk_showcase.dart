part of 'tk_examples.dart';

// Ejemplos de muestra: aplicaciones completas para enseñar lo que se puede
// hacer con el Diseñador. Guardan sus datos en la carpeta del proyecto (el
// programa generado se ejecuta con ella como carpeta de trabajo).

String _py(String s) => TkPy.str(s);

const _accent = '#2b5797';
const _paper = '#f4f5f7';

Map<String, Object?> _title(String text, {int size = 18}) => {
  'text': text,
  'anchor': 'w',
  'fg': _accent,
  'font_size': size,
  'font_bold': true,
};

Map<String, Object?> _label(String text) => {'text': text, 'anchor': 'w'};

// ------------------------------------------------------------ bloc de notas
TkExample _notepad(String Function(String) t) {
  final app = t(markTr('Bloc de notas'));
  final file = t(markTr('Archivo')), edit = t(markTr('Edición'));
  final help = t(markTr('Ayuda'));
  final newDoc = t(markTr('Nuevo')), open = t(markTr('Abrir…'));
  final save = t(markTr('Guardar')), saveAs = t(markTr('Guardar como…'));
  final quit = t(markTr('Salir'));
  final undo = t(markTr('Deshacer')), redo = t(markTr('Rehacer'));
  final cut = t(markTr('Cortar')), copy = t(markTr('Copiar'));
  final paste = t(markTr('Pegar')), all = t(markTr('Seleccionar todo'));
  final about = t(markTr('Acerca de'));
  final items = [
    file,
    '  $newDoc',
    '  $open',
    '  $save',
    '  $saveAs',
    '  -',
    '  $quit',
    edit,
    '  $undo',
    '  $redo',
    '  -',
    '  $cut',
    '  $copy',
    '  $paste',
    '  -',
    '  $all',
    help,
    '  $about',
  ].join('\n');
  final filter = '${t(markTr('Texto'))}|*.txt';
  final design =
      TkDesign(
          width: 720,
          height: 520,
          props: {'title': app, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            680,
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
            496,
            {'wrap': 'word', 'font_family': 'Courier', 'font_size': 13},
            {'key_up': 'Editor_key_up', 'click': 'Editor_mouse_down'},
          ),
          _w('OpenDialog', 'OpenFile', 680, 48, 32, 32, {
            'title': t(markTr('Abrir un archivo de texto')),
            'filter': filter,
          }),
          _w('SaveDialog', 'SaveFile', 680, 88, 32, 32, {
            'title': t(markTr('Guardar el archivo de texto')),
            'filter': filter,
            'defaultext': '.txt',
            'filename': t(markTr('sin_titulo.txt')),
          }),
          _w('StatusBar', 'Status', 0, 496, 720, 24, {
            'text': t(markTr('Listo')),
            'icon': 'edit',
          }),
        ]);
  final code =
      '''import os
import tkinter
from tkinter import messagebox

APP = ${_py(app)}
UNTITLED = ${_py(t(markTr('Sin título')))}
STATUS = ${_py(t(markTr('{0}   ·   Línea {1}, columna {2}   ·   {3} caracteres')))}
ASK_SAVE = ${_py(t(markTr('¿Guardar los cambios de «{0}»?')))}
ABOUT = ${_py(t(markTr('Bloc de notas de ejemplo de DMarlon Studio: menú, diálogos Abrir y Guardar y barra de estado.')))}


class Form1(FormDesign):
    def form_create(self):
        self.path = None
        self.saved = ""
        self.Editor.configure(undo=True, maxundo=-1, autoseparators=True)
        # Atajos: Ctrl en Windows y Linux, Cmd en macOS.
        for key, action in (("n", self.new), ("o", self.open), ("s", self.save)):
            for modifier in ("Control", "Command"):
                try:
                    self.Editor.bind(
                        "<%s-%s>" % (modifier, key),
                        lambda event, run=action: (run(), "break")[1],
                    )
                except tkinter.TclError:
                    pass  # Cmd solo existe en macOS.
        self.Editor.focus_set()
        self.refresh()

    # ------------------------------------------------------------ estado
    def text(self):
        return self.Editor.get("1.0", "end-1c")

    def name(self):
        return os.path.basename(self.path) if self.path else UNTITLED

    def dirty(self):
        return self.text() != self.saved

    def refresh(self):
        line, column = self.Editor.index("insert").split(".")
        self.Status.set(
            STATUS.format(self.name(), line, int(column) + 1, len(self.text())),
            icon="edit",
        )
        mark = "* " if self.dirty() else ""
        self.root.title("%s%s - %s" % (mark, self.name(), APP))

    def show(self, path, text):
        self.Editor.delete("1.0", "end")
        self.Editor.insert("1.0", text)
        self.Editor.edit_reset()
        self.Editor.mark_set("insert", "1.0")
        self.path = path
        self.saved = text
        self.refresh()

    def keep_going(self):
        """True si se puede dejar el texto actual (guardado o descartado)."""
        if not self.dirty():
            return True
        answer = messagebox.askyesnocancel(APP, ASK_SAVE.format(self.name()), parent=self.root)
        if answer is None:
            return False
        return self.save() if answer else True

    # ---------------------------------------------------------- archivos
    def new(self):
        if self.keep_going():
            self.show(None, "")

    def open(self):
        if not self.keep_going():
            return
        try:
            found = self.OpenFile.read_text()
        except (OSError, UnicodeDecodeError) as error:
            messagebox.showerror(APP, str(error), parent=self.root)
            return
        if found:
            path, text = found
            self.show(path, text)

    def save(self, ask=False):
        text = self.text()
        try:
            if self.path and not ask:
                with open(self.path, "w", encoding="utf-8") as f:
                    f.write(text)
                path = self.path
            else:
                if self.path:
                    self.SaveFile.suggested = os.path.basename(self.path)
                path = self.SaveFile.write_text(text)
        except OSError as error:
            messagebox.showerror(APP, str(error), parent=self.root)
            return False
        if not path:
            return False
        self.path = path
        self.saved = text
        self.refresh()
        return True

    # ----------------------------------------------------------- edición
    def undo(self):
        try:
            self.Editor.edit_undo()
        except tkinter.TclError:
            pass  # Nada que deshacer.

    def redo(self):
        try:
            self.Editor.edit_redo()
        except tkinter.TclError:
            pass

    def select_all(self):
        self.Editor.tag_add("sel", "1.0", "end-1c")
        self.Editor.mark_set("insert", "end-1c")

    # ------------------------------------------------------------ eventos
    def Menu1_click(self, item):
        if item == ${_py('$file/$quit')}:
            return self.form_close()
        actions = {
            ${_py('$file/$newDoc')}: self.new,
            ${_py('$file/$open')}: self.open,
            ${_py('$file/$save')}: self.save,
            ${_py('$file/$saveAs')}: lambda: self.save(ask=True),
            ${_py('$edit/$undo')}: self.undo,
            ${_py('$edit/$redo')}: self.redo,
            ${_py('$edit/$cut')}: lambda: self.Editor.event_generate("<<Cut>>"),
            ${_py('$edit/$copy')}: lambda: self.Editor.event_generate("<<Copy>>"),
            ${_py('$edit/$paste')}: lambda: self.Editor.event_generate("<<Paste>>"),
            ${_py('$edit/$all')}: self.select_all,
            ${_py('$help/$about')}: lambda: messagebox.showinfo(APP, ABOUT, parent=self.root),
        }
        action = actions.get(item)
        if action is not None:
            action()
            self.refresh()

    def Editor_key_up(self, event=None):
        self.refresh()

    def Editor_mouse_down(self, event=None):
        # El cursor se mueve después del clic.
        self.root.after_idle(self.refresh)

    def form_close(self, *args):
        if self.keep_going():
            self.root.destroy()
''';
  return TkExample(
    'notepad',
    app,
    t(
      markTr(
        'Editor de texto clásico con menús, abrir y guardar, deshacer y una barra de estado con la línea y la columna.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------------------ agenda
TkExample _agenda(String Function(String) t) {
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  final pages = [t(markTr('Contactos')), t(markTr('Citas'))].join('\n');
  final design =
      TkDesign(
          width: 760,
          height: 540,
          props: {
            'title': t(markTr('Agenda')),
            'bg': _paper,
            'position': 'center',
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('PageControl', 'Pages', 8, 8, 744, 500, {'pages': pages}),
          // Contactos.
          on(
            _w(
              'Label',
              'LblSearch',
              16,
              40,
              64,
              24,
              _label(t(markTr('Buscar'))),
            ),
            0,
          ),
          on(
            _w('Entry', 'Search', 80, 40, 312, 24, {}, {
              'key_up': 'Search_key_up',
            }),
            0,
          ),
          on(
            _w(
              'Treeview',
              'Contacts',
              16,
              72,
              376,
              408,
              {
                'columns': [
                  'name|${t(markTr('Nombre'))}|150',
                  'phone|${t(markTr('Teléfono'))}|100',
                  'email|${t(markTr('Correo'))}|110',
                ].join('\n'),
              },
              {'select': 'Contacts_select'},
            ),
            0,
          ),
          on(
            _w(
              'Label',
              'LblName',
              408,
              40,
              96,
              24,
              _label(t(markTr('Nombre'))),
            ),
            0,
          ),
          on(_w('Entry', 'ContactName', 504, 40, 224, 24), 0),
          on(
            _w(
              'Label',
              'LblPhone',
              408,
              80,
              96,
              24,
              _label(t(markTr('Teléfono'))),
            ),
            0,
          ),
          on(_w('Entry', 'ContactPhone', 504, 80, 224, 24), 0),
          on(
            _w(
              'Label',
              'LblEmail',
              408,
              120,
              96,
              24,
              _label(t(markTr('Correo'))),
            ),
            0,
          ),
          on(_w('Entry', 'ContactEmail', 504, 120, 224, 24), 0),
          on(
            _w(
              'Label',
              'LblNotes',
              408,
              160,
              96,
              24,
              _label(t(markTr('Notas'))),
            ),
            0,
          ),
          on(_w('Text', 'ContactNotes', 504, 160, 224, 200), 0),
          on(
            _w(
              'Button',
              'BtnNewContact',
              408,
              376,
              104,
              32,
              {'text': t(markTr('Nuevo'))},
              {'command': 'BtnNewContact_click'},
            ),
            0,
          ),
          on(
            _w(
              'Button',
              'BtnSaveContact',
              520,
              376,
              104,
              32,
              {'text': t(markTr('Guardar'))},
              {'command': 'BtnSaveContact_click'},
            ),
            0,
          ),
          on(
            _w(
              'Button',
              'BtnDeleteContact',
              632,
              376,
              96,
              32,
              {'text': t(markTr('Eliminar'))},
              {'command': 'BtnDeleteContact_click'},
            ),
            0,
          ),
          // Citas.
          on(
            _w('Label', 'LblDate', 16, 40, 64, 24, _label(t(markTr('Fecha')))),
            1,
          ),
          on(_w('Entry', 'AppDate', 80, 40, 104, 24), 1),
          on(
            _w('Label', 'LblTime', 200, 40, 48, 24, _label(t(markTr('Hora')))),
            1,
          ),
          on(_w('Entry', 'AppTime', 248, 40, 64, 24), 1),
          on(
            _w('Label', 'LblWith', 328, 40, 72, 24, _label(t(markTr('Con')))),
            1,
          ),
          on(
            _w('Combobox', 'AppContact', 400, 40, 200, 24, {
              'state': 'readonly',
            }),
            1,
          ),
          on(
            _w(
              'Label',
              'LblSubject',
              16,
              80,
              64,
              24,
              _label(t(markTr('Asunto'))),
            ),
            1,
          ),
          on(
            _w('Entry', 'AppSubject', 80, 80, 520, 24, {}, {
              'enter_key': 'AppSubject_return',
            }),
            1,
          ),
          on(
            _w(
              'Button',
              'BtnAddAppointment',
              616,
              76,
              112,
              32,
              {'text': t(markTr('Añadir cita'))},
              {'command': 'BtnAddAppointment_click'},
            ),
            1,
          ),
          on(
            _w('Treeview', 'Appointments', 16, 120, 712, 312, {
              'columns': [
                'date|${t(markTr('Fecha'))}|100',
                'time|${t(markTr('Hora'))}|60',
                'with|${t(markTr('Con'))}|180',
                'subject|${t(markTr('Asunto'))}|356',
              ].join('\n'),
            }),
            1,
          ),
          on(
            _w(
              'Button',
              'BtnDeleteAppointment',
              16,
              440,
              136,
              32,
              {'text': t(markTr('Eliminar cita'))},
              {'command': 'BtnDeleteAppointment_click'},
            ),
            1,
          ),
          on(
            _w('Label', 'LblHint', 168, 444, 560, 24, {
              ..._label(
                t(
                  markTr(
                    'Las citas de hoy salen resaltadas. Fecha: AAAA-MM-DD; hora: HH:MM.',
                  ),
                ),
              ),
              'fg': '#5f6672',
            }),
            1,
          ),
          _w('StatusBar', 'Status', 0, 516, 760, 24, {
            'text': t(markTr('Listo')),
            'icon': 'calendar',
          }),
        ]);
  final code =
      '''import datetime
import sqlite3
from tkinter import messagebox

DB = "agenda.sqlite"
APP = ${_py(t(markTr('Agenda')))}
NO_CONTACT = ${_py(t(markTr('(sin contacto)')))}
STATUS = ${_py(t(markTr('{0} contactos   ·   {1} citas próximas   ·   {2} hoy')))}


class Form1(FormDesign):
    def form_create(self):
        self.db = sqlite3.connect(DB)
        self.db.row_factory = sqlite3.Row
        self.create_tables()
        self.contact_id = None
        self.choices = []
        self.Appointments.tag_configure("today", background="#fff4ce")
        self.AppDate_var.set(datetime.date.today().isoformat())
        self.AppTime_var.set("09:00")
        self.load_contacts()
        self.load_appointments()
        self.Search.focus_set()

    def create_tables(self):
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS contact (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                phone TEXT NOT NULL DEFAULT '',
                email TEXT NOT NULL DEFAULT '',
                notes TEXT NOT NULL DEFAULT '');
            CREATE TABLE IF NOT EXISTS appointment (
                id INTEGER PRIMARY KEY,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                contact_id INTEGER REFERENCES contact(id) ON DELETE SET NULL,
                subject TEXT NOT NULL);
        """)
        if self.db.execute("SELECT COUNT(*) FROM contact").fetchone()[0]:
            return
        # La primera vez, unos datos de ejemplo.
        self.db.executemany(
            "INSERT INTO contact (name, phone, email, notes) VALUES (?, ?, ?, ?)",
            [
                ("Ana Torres", "600 111 222", "ana@example.com", ${_py(t(markTr('Prefiere que la llamen por la tarde.')))}),
                ("Luis Moreno", "600 333 444", "luis@example.com", ""),
                ("Marta Díaz", "600 555 666", "marta@example.com", ${_py(t(markTr('Cliente desde 2020.')))}),
            ],
        )
        today = datetime.date.today()
        self.db.executemany(
            "INSERT INTO appointment (date, time, contact_id, subject) VALUES (?, ?, ?, ?)",
            [
                (today.isoformat(), "10:30", 1, ${_py(t(markTr('Revisar el presupuesto')))}),
                ((today + datetime.timedelta(days=2)).isoformat(), "16:00", 3, ${_py(t(markTr('Reunión de seguimiento')))}),
            ],
        )
        self.db.commit()

    # ---------------------------------------------------------- contactos
    def load_contacts(self, select=None):
        like = "%" + self.Search_var.get().strip() + "%"
        rows = self.db.execute(
            "SELECT * FROM contact WHERE name LIKE ? OR phone LIKE ? OR email LIKE ? "
            "ORDER BY name COLLATE NOCASE",
            (like, like, like),
        ).fetchall()
        self.Contacts.delete(*self.Contacts.get_children())
        for row in rows:
            self.Contacts.insert(
                "", "end", iid=str(row["id"]), values=(row["name"], row["phone"], row["email"])
            )
        if select is not None and self.Contacts.exists(str(select)):
            self.Contacts.selection_set(str(select))
            self.Contacts.see(str(select))
        # Los contactos para elegir en una cita.
        self.choices = [(None, NO_CONTACT)] + [
            (row["id"], row["name"])
            for row in self.db.execute("SELECT id, name FROM contact ORDER BY name COLLATE NOCASE")
        ]
        self.AppContact.configure(values=[name for _, name in self.choices])
        if self.AppContact.current() < 0:
            self.AppContact.current(0)
        self.update_status()

    def clear_contact(self):
        self.contact_id = None
        for var in (self.ContactName_var, self.ContactPhone_var, self.ContactEmail_var):
            var.set("")
        self.ContactNotes.delete("1.0", "end")

    def Search_key_up(self, event=None):
        self.load_contacts()

    def Contacts_select(self, event=None):
        chosen = self.Contacts.selection()
        if not chosen:
            return
        row = self.db.execute("SELECT * FROM contact WHERE id = ?", (int(chosen[0]),)).fetchone()
        if row is None:
            return
        self.contact_id = row["id"]
        self.ContactName_var.set(row["name"])
        self.ContactPhone_var.set(row["phone"])
        self.ContactEmail_var.set(row["email"])
        self.ContactNotes.delete("1.0", "end")
        self.ContactNotes.insert("1.0", row["notes"])

    def BtnNewContact_click(self):
        self.Contacts.selection_set(())
        self.clear_contact()
        self.ContactName.focus_set()

    def BtnSaveContact_click(self):
        name = self.ContactName_var.get().strip()
        if not name:
            self.Status.set(${_py(t(markTr('Escriba el nombre del contacto.')))}, icon="warning")
            self.ContactName.focus_set()
            return
        data = (
            name,
            self.ContactPhone_var.get().strip(),
            self.ContactEmail_var.get().strip(),
            self.ContactNotes.get("1.0", "end-1c").strip(),
        )
        if self.contact_id is None:
            cursor = self.db.execute(
                "INSERT INTO contact (name, phone, email, notes) VALUES (?, ?, ?, ?)", data
            )
            self.contact_id = cursor.lastrowid
        else:
            self.db.execute(
                "UPDATE contact SET name = ?, phone = ?, email = ?, notes = ? WHERE id = ?",
                data + (self.contact_id,),
            )
        self.db.commit()
        self.load_contacts(select=self.contact_id)
        self.load_appointments()
        self.Status.set(${_py(t(markTr('Contacto guardado: {0}')))}.format(name), icon="check")

    def BtnDeleteContact_click(self):
        if self.contact_id is None:
            return
        name = self.ContactName_var.get().strip()
        if not messagebox.askyesno(APP, ${_py(t(markTr('¿Eliminar a «{0}»? Sus citas quedan sin contacto.')))}.format(name), parent=self.root):
            return
        self.db.execute("UPDATE appointment SET contact_id = NULL WHERE contact_id = ?", (self.contact_id,))
        self.db.execute("DELETE FROM contact WHERE id = ?", (self.contact_id,))
        self.db.commit()
        self.clear_contact()
        self.load_contacts()
        self.load_appointments()

    # -------------------------------------------------------------- citas
    def load_appointments(self):
        today = datetime.date.today().isoformat()
        rows = self.db.execute(
            """SELECT a.id, a.date, a.time, a.subject, c.name
               FROM appointment a LEFT JOIN contact c ON c.id = a.contact_id
               WHERE a.date >= ? ORDER BY a.date, a.time""",
            (today,),
        ).fetchall()
        self.Appointments.delete(*self.Appointments.get_children())
        for row in rows:
            day = datetime.date.fromisoformat(row["date"]).strftime("%d/%m/%Y")
            self.Appointments.insert(
                "", "end", iid=str(row["id"]),
                values=(day, row["time"], row["name"] or "", row["subject"]),
                tags=("today",) if row["date"] == today else (),
            )
        self.update_status()

    def BtnAddAppointment_click(self):
        try:
            day = datetime.datetime.strptime(self.AppDate_var.get().strip(), "%Y-%m-%d").date()
        except ValueError:
            self.Status.set(${_py(t(markTr('La fecha debe ser AAAA-MM-DD, por ejemplo 2026-12-31.')))}, icon="warning")
            return self.AppDate.focus_set()
        try:
            hour = datetime.datetime.strptime(self.AppTime_var.get().strip(), "%H:%M").strftime("%H:%M")
        except ValueError:
            self.Status.set(${_py(t(markTr('La hora debe ser HH:MM, por ejemplo 09:30.')))}, icon="warning")
            return self.AppTime.focus_set()
        subject = self.AppSubject_var.get().strip()
        if not subject:
            self.Status.set(${_py(t(markTr('Escriba el asunto de la cita.')))}, icon="warning")
            return self.AppSubject.focus_set()
        index = self.AppContact.current()
        contact = self.choices[index][0] if 0 <= index < len(self.choices) else None
        self.db.execute(
            "INSERT INTO appointment (date, time, contact_id, subject) VALUES (?, ?, ?, ?)",
            (day.isoformat(), hour, contact, subject),
        )
        self.db.commit()
        self.AppSubject_var.set("")
        self.load_appointments()
        self.Status.set(${_py(t(markTr('Cita añadida para el {0} a las {1}.')))}.format(day.strftime("%d/%m/%Y"), hour), icon="check")

    def AppSubject_return(self, event=None):
        self.BtnAddAppointment_click()

    def BtnDeleteAppointment_click(self):
        chosen = self.Appointments.selection()
        if not chosen:
            self.Status.set(${_py(t(markTr('Elija la cita que quiere eliminar.')))}, icon="info")
            return
        self.db.execute("DELETE FROM appointment WHERE id = ?", (int(chosen[0]),))
        self.db.commit()
        self.load_appointments()

    def update_status(self):
        today = datetime.date.today().isoformat()
        contacts = self.db.execute("SELECT COUNT(*) FROM contact").fetchone()[0]
        upcoming = self.db.execute("SELECT COUNT(*) FROM appointment WHERE date >= ?", (today,)).fetchone()[0]
        now = self.db.execute("SELECT COUNT(*) FROM appointment WHERE date = ?", (today,)).fetchone()[0]
        self.Status.set(STATUS.format(contacts, upcoming, now), icon="calendar")

    def form_close(self, *args):
        self.db.close()
        self.root.destroy()
''';
  return TkExample(
    'agenda',
    t(markTr('Agenda')),
    t(
      markTr(
        'Contactos y citas en SQLite, con páginas, búsqueda al escribir y las citas de hoy resaltadas.',
      ),
    ),
    design,
    code,
  );
}

// ---------------------------------------------------- conversor de moneda
TkExample _currency(String Function(String) t) {
  final design =
      TkDesign(
          width: 480,
          height: 320,
          props: {
            'title': t(markTr('Conversor de moneda')),
            'bg': _paper,
            'position': 'center',
          },
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Label',
            'Heading',
            16,
            12,
            400,
            32,
            _title(t(markTr('Conversor de moneda'))),
          ),
          _w(
            'Label',
            'LblAmount',
            16,
            56,
            160,
            24,
            _label(t(markTr('Importe'))),
          ),
          _w(
            'Entry',
            'Amount',
            16,
            80,
            160,
            32,
            {'font_size': 14},
            {'key_up': 'Amount_key_up'},
          ),
          _w('Label', 'LblFrom', 192, 56, 104, 24, _label(t(markTr('De')))),
          _w(
            'Combobox',
            'From',
            192,
            80,
            104,
            32,
            {'state': 'readonly'},
            {'select': 'Currency_select'},
          ),
          _w(
            'Button',
            'BtnSwap',
            304,
            80,
            40,
            32,
            {'text': '⇄'},
            {'command': 'BtnSwap_click'},
          ),
          _w('Label', 'LblTo', 352, 56, 112, 24, _label(t(markTr('A')))),
          _w(
            'Combobox',
            'To',
            352,
            80,
            112,
            32,
            {'state': 'readonly'},
            {'select': 'Currency_select'},
          ),
          _w('Label', 'Result', 16, 128, 448, 48, {
            'text': '',
            'anchor': 'w',
            'fg': '#1b1d22',
            'font_size': 24,
            'font_bold': true,
          }),
          _w('Label', 'Rate', 16, 176, 448, 24, {
            'text': '',
            'anchor': 'w',
            'fg': '#5f6672',
          }),
          _w('Progressbar', 'Loading', 16, 212, 448, 8, {
            'mode': 'indeterminate',
          }),
          _w(
            'Button',
            'BtnRefresh',
            16,
            240,
            176,
            32,
            {'text': t(markTr('Actualizar los tipos'))},
            {'command': 'BtnRefresh_click'},
          ),
          _w(
            'RestClient',
            'Rates',
            440,
            12,
            32,
            32,
            {'base_url': 'https://api.frankfurter.app', 'timeout': 10},
            {'done': 'Rates_done', 'error': 'Rates_error'},
          ),
          _w('StatusBar', 'Status', 0, 296, 480, 24, {
            'text': t(markTr('Cargando los tipos de cambio…')),
            'icon': 'refresh',
          }),
        ]);
  final code =
      '''# Tipos de cambio de Frankfurter (datos del Banco Central Europeo, sin
# clave). Sin conexión se usa una tabla de reserva aproximada.

# Unidades de cada moneda por 1 euro: solo de reserva, aproximadas.
FALLBACK = {
    "EUR": 1.0, "USD": 1.08, "GBP": 0.85, "JPY": 162.0, "CHF": 0.95,
    "CAD": 1.47, "AUD": 1.63, "MXN": 19.5, "BRL": 5.9, "CNY": 7.8,
}
NO_DECIMALS = {"JPY", "KRW", "ISK", "HUF"}
DATED = ${_py(t(markTr('Tipos del {0} (BCE)')))}
OFFLINE = ${_py(t(markTr('Sin conexión: tipos aproximados de reserva, no para operaciones reales.')))}
BAD_AMOUNT = ${_py(t(markTr('Escriba un importe, por ejemplo 125,50')))}


def parse_amount(text):
    text = text.strip().replace(" ", "")
    if "," in text and "." in text:
        text = text.replace(".", "").replace(",", ".")
    else:
        text = text.replace(",", ".")
    return float(text)


def money(value, code):
    decimals = 0 if code in NO_DECIMALS else 2
    text = "{:,.{}f}".format(value, decimals)
    # Formato español: punto de miles y coma decimal.
    return text.replace(",", "_").replace(".", ",").replace("_", ".") + " " + code


def convert(amount, rates, source, target):
    return amount / rates[source] * rates[target]


class Form1(FormDesign):
    def form_create(self):
        self.rates = dict(FALLBACK)
        self.fill_currencies("EUR", "USD")
        self.Amount_var.set("100")
        self.show()
        self.refresh_rates()

    def fill_currencies(self, source, target):
        codes = sorted(self.rates)
        self.From.configure(values=codes)
        self.To.configure(values=codes)
        self.From_var.set(source if source in self.rates else "EUR")
        self.To_var.set(target if target in self.rates else codes[0])

    def show(self):
        source, target = self.From_var.get(), self.To_var.get()
        try:
            amount = parse_amount(self.Amount_var.get())
        except ValueError:
            self.Result.configure(text="")
            self.Rate.configure(text=BAD_AMOUNT)
            return
        result = convert(amount, self.rates, source, target)
        self.Result.configure(text=money(result, target))
        one = convert(1, self.rates, source, target)
        self.Rate.configure(text="1 %s = %s" % (source, money(one, target).replace(" " + target, " " + target)))

    def refresh_rates(self):
        self.BtnRefresh.configure(state="disabled")
        self.Loading.start(12)
        self.Rates.get_async("latest", params={"from": "EUR"})

    def done_loading(self):
        self.Loading.stop()
        self.BtnRefresh.configure(state="normal")

    def Rates_done(self, result):
        self.done_loading()
        rates = dict((result or {}).get("rates") or {})
        if not rates:
            return self.Rates_error(None)
        rates["EUR"] = 1.0
        self.rates = rates
        self.fill_currencies(self.From_var.get(), self.To_var.get())
        self.show()
        self.Status.set(DATED.format(result.get("date", "")), icon="check")

    def Rates_error(self, error):
        self.done_loading()
        self.rates = dict(FALLBACK)
        self.fill_currencies(self.From_var.get(), self.To_var.get())
        self.show()
        self.Status.set(OFFLINE, icon="warning")

    def Amount_key_up(self, event=None):
        self.show()

    def Currency_select(self, event=None):
        self.show()

    def BtnSwap_click(self):
        source, target = self.From_var.get(), self.To_var.get()
        self.From_var.set(target)
        self.To_var.set(source)
        self.show()

    def BtnRefresh_click(self):
        self.Status.set(${_py(t(markTr('Cargando los tipos de cambio…')))}, icon="refresh")
        self.refresh_rates()
''';
  return TkExample(
    'currency',
    t(markTr('Conversor de moneda')),
    t(
      markTr(
        'Convierte divisas con los tipos del BCE leídos de una API en segundo plano, con tabla de reserva sin conexión.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------------- la serpiente
TkExample _snake(String Function(String) t) {
  final game = t(markTr('Juego')), help = t(markTr('Ayuda'));
  final newGame = t(markTr('Nueva partida')), pause = t(markTr('Pausa'));
  final quit = t(markTr('Salir')), how = t(markTr('Cómo se juega'));
  final design =
      TkDesign(
          width: 480,
          height: 544,
          props: {
            'title': t(markTr('La serpiente')),
            'bg': '#16211a',
            'position': 'center',
          },
          events: {'create': 'form_create', 'key': 'form_key'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            440,
            8,
            32,
            32,
            {
              'items':
                  '$game\n  $newGame\n  $pause\n  -\n  $quit\n$help\n  $how',
            },
            {'command': 'Menu1_click'},
          ),
          _w(
            'Timer',
            'Timer1',
            400,
            8,
            32,
            32,
            {'interval': 150, 'enabled': false},
            {'command': 'Timer1_timer'},
          ),
          _w('Label', 'Score', 20, 8, 200, 32, {
            'text': '0',
            'anchor': 'w',
            'bg': '#16211a',
            'fg': '#e8f5e9',
            'font_size': 18,
            'font_bold': true,
          }),
          _w('Label', 'Best', 220, 8, 240, 32, {
            'text': '',
            'anchor': 'e',
            'bg': '#16211a',
            'fg': '#a5d6a7',
            'font_size': 13,
          }),
          _w('Canvas', 'Board', 20, 48, 440, 440, {'bg': '#0f1712'}),
          _w('StatusBar', 'Status', 0, 520, 480, 24, {
            'text': '',
            'icon': 'info',
          }),
        ]);
  final code =
      '''import json
import random
from tkinter import messagebox

CELL = 22
COLS = ROWS = 20
START_SPEED = 150
FASTEST = 60
RECORD = "serpiente_record.json"
DIRECTIONS = {
    "Up": (0, -1), "w": (0, -1), "W": (0, -1),
    "Down": (0, 1), "s": (0, 1), "S": (0, 1),
    "Left": (-1, 0), "a": (-1, 0), "A": (-1, 0),
    "Right": (1, 0), "d": (1, 0), "D": (1, 0),
}
POINTS = ${_py(t(markTr('Puntos: {0}')))}
BEST = ${_py(t(markTr('Récord: {0}')))}
HINT = ${_py(t(markTr('Flechas o WASD para moverse · Espacio: pausa · Intro: nueva partida')))}
OVER = ${_py(t(markTr('Fin de la partida')))}
AGAIN = ${_py(t(markTr('Intro para jugar otra vez')))}
PAUSED = ${_py(t(markTr('Pausa')))}
NEW_RECORD = ${_py(t(markTr('¡Nuevo récord!')))}


class Form1(FormDesign):
    def form_create(self):
        self.best = self.load_best()
        self.new_game()

    # ------------------------------------------------------------ récord
    def load_best(self):
        try:
            with open(RECORD, encoding="utf-8") as f:
                return int(json.load(f).get("best", 0))
        except (OSError, ValueError, TypeError, AttributeError):
            return 0

    def save_best(self):
        try:
            with open(RECORD, "w", encoding="utf-8") as f:
                json.dump({"best": self.best}, f)
        except OSError:
            pass

    # ----------------------------------------------------------- partida
    def new_game(self):
        x, y = COLS // 2, ROWS // 2
        self.snake = [(x, y), (x - 1, y), (x - 2, y)]
        self.direction = self.queued = (1, 0)
        self.score = 0
        self.alive = True
        self.paused = False
        self.food = self.place_food()
        self.Timer1.start(START_SPEED)
        self.show_score()
        self.Status.set(HINT, icon="info")
        self.draw()

    def place_food(self):
        free = [(x, y) for x in range(COLS) for y in range(ROWS) if (x, y) not in self.snake]
        return random.choice(free) if free else None

    def step(self):
        self.direction = self.queued
        head = (self.snake[0][0] + self.direction[0], self.snake[0][1] + self.direction[1])
        outside = not (0 <= head[0] < COLS and 0 <= head[1] < ROWS)
        if outside or head in self.snake[:-1]:
            return self.game_over()
        self.snake.insert(0, head)
        if head == self.food:
            self.score += 1
            self.food = self.place_food()
            # Cada 5 puntos, un poco más rápido.
            if self.score % 5 == 0:
                self.Timer1.start(max(FASTEST, self.Timer1.interval - 12))
            self.show_score()
        else:
            self.snake.pop()
        self.draw()

    def game_over(self):
        self.alive = False
        self.Timer1.stop()
        record = self.score > self.best
        if record:
            self.best = self.score
            self.save_best()
            self.show_score()
        self.draw()
        self.banner(OVER, (NEW_RECORD + "  " if record else "") + AGAIN)

    def toggle_pause(self):
        if not self.alive:
            return
        self.paused = not self.paused
        self.draw()
        if self.paused:
            self.banner(PAUSED, HINT)

    # ------------------------------------------------------------ dibujo
    def show_score(self):
        self.Score.configure(text=POINTS.format(self.score))
        self.Best.configure(text=BEST.format(self.best))

    def cell(self, x, y, color, inset=1, oval=False):
        box = (x * CELL + inset, y * CELL + inset, (x + 1) * CELL - inset, (y + 1) * CELL - inset)
        shape = self.Board.create_oval if oval else self.Board.create_rectangle
        shape(*box, fill=color, outline="")

    def draw(self):
        self.Board.delete("all")
        if self.food is not None:
            self.cell(*self.food, "#ef5350", inset=3, oval=True)
        for i, (x, y) in enumerate(self.snake):
            self.cell(x, y, "#c5e1a5" if i == 0 else "#66bb6a")

    def banner(self, title, subtitle):
        middle = COLS * CELL // 2
        self.Board.create_rectangle(40, middle - 50, COLS * CELL - 40, middle + 50, fill="#0b120d", outline="#66bb6a")
        self.Board.create_text(middle, middle - 14, text=title, fill="#e8f5e9", font=("Helvetica", 20, "bold"))
        self.Board.create_text(middle, middle + 18, text=subtitle, fill="#a5d6a7", font=("Helvetica", 11))

    # ----------------------------------------------------------- eventos
    def Timer1_timer(self):
        if self.alive and not self.paused:
            self.step()

    def form_key(self, event=None):
        key = getattr(event, "keysym", "")
        if key in ("Return", "KP_Enter"):
            if not self.alive:
                self.new_game()
        elif key == "space":
            self.toggle_pause()
        elif key in DIRECTIONS and self.alive and not self.paused:
            dx, dy = DIRECTIONS[key]
            # No puede dar media vuelta sobre sí misma.
            if (dx, dy) != (-self.direction[0], -self.direction[1]):
                self.queued = (dx, dy)

    def Menu1_click(self, item):
        if item == ${_py('$game/$newGame')}:
            self.new_game()
        elif item == ${_py('$game/$pause')}:
            self.toggle_pause()
        elif item == ${_py('$game/$quit')}:
            self.root.destroy()
        elif item == ${_py('$help/$how')}:
            messagebox.showinfo(${_py(t(markTr('La serpiente')))}, ${_py(t(markTr('Coma las manzanas para crecer sin chocar con los bordes ni consigo misma. Cada cinco manzanas va más rápido.')))} + "\\n\\n" + HINT, parent=self.root)
''';
  return TkExample(
    'snake',
    t(markTr('La serpiente')),
    t(
      markTr(
        'Juego en un lienzo movido por un temporizador, con teclado, puntuación y récord guardado.',
      ),
    ),
    design,
    code,
  );
}
