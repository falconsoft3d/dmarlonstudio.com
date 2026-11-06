part of 'tk_examples.dart';

// -------------------------------------------------------- renombrar archivos
/// Renombra archivos por lotes: reglas en orden (buscar y reemplazar, prefijo
/// y sufijo, numeración, mayúsculas y extensión), vista previa con los
/// conflictos en rojo, cambios seguros en dos pasos y Deshacer.
TkExample tkUtilFileRenamer(String Function(String) t) {
  final app = t(markTr('Renombrar archivos'));
  const rules = 'Rules_changed';
  TkWidget caption(String name, int x, int y, int w, String text) =>
      _w('Label', name, x, y, w, 24, _label(text));
  TkWidget section(String name, int y, String text) =>
      _w('Label', name, 16, y, 360, 24, _title(text, size: 13));
  TkWidget field(String name, int x, int y, int w, [String text = '']) =>
      _w('Entry', name, x, y, w, 26, {'text': text}, {'key_up': rules});
  TkWidget choice(String name, int x, int y, int w, List<String> items) => _w(
    'Combobox',
    name,
    x,
    y,
    w,
    26,
    {'state': 'readonly', 'items': items.join('\n')},
    {'select': rules},
  );
  TkWidget button(String name, int x, int w, String text) => _w(
    'Button',
    name,
    x,
    588,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final numbering = [
    t(markTr('Sin numerar')),
    t(markTr('Antes del nombre')),
    t(markTr('Después del nombre')),
    t(markTr('Sustituir el nombre')),
  ];
  final lower = t(markTr('minúsculas')), upper = t(markTr('MAYÚSCULAS'));
  final cases = [
    t(markTr('Sin cambios')),
    lower,
    upper,
    t(markTr('Título (cada palabra)')),
  ];
  final exts = [t(markTr('Mantener')), lower, upper, t(markTr('Cambiar a'))];
  final design =
      TkDesign(
          width: 1080,
          height: 700,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 12, 700, 32, _title(app)),
          caption('LblFolder', 16, 54, 64, t(markTr('Carpeta'))),
          _w('Entry', 'Folder', 80, 52, 640, 28, {}, {
            'enter_key': 'Folder_return',
          }),
          _w(
            'Button',
            'BtnBrowse',
            728,
            50,
            100,
            32,
            {'text': t(markTr('Elegir…'))},
            {'command': 'BtnBrowse_click'},
          ),
          _w(
            'Checkbutton',
            'Subfolders',
            840,
            54,
            224,
            24,
            {'text': t(markTr('Incluir subcarpetas'))},
            {'command': 'Folder_return'},
          ),
          caption('LblFilter', 16, 92, 64, t(markTr('Filtro'))),
          _w(
            'Entry',
            'Filter',
            80,
            90,
            240,
            28,
            {'text': '*'},
            {'key_up': 'Filter_key_up'},
          ),
          _w('Label', 'FilterHint', 332, 92, 732, 24, {
            ..._label(
              t(markTr('Patrones separados por «;», por ejemplo *.jpg;*.png')),
            ),
            'fg': '#5f6672',
          }),
          section('Sec1', 132, t(markTr('1. Buscar y reemplazar'))),
          caption('LblFind', 16, 162, 104, t(markTr('Buscar'))),
          field('Find', 120, 160, 256),
          caption('LblReplace', 16, 194, 104, t(markTr('Reemplazar por'))),
          field('Replace', 120, 192, 256),
          _w(
            'Checkbutton',
            'Regex',
            16,
            224,
            170,
            24,
            {'text': t(markTr('Expresión regular'))},
            {'command': rules},
          ),
          _w(
            'Checkbutton',
            'MatchCase',
            190,
            224,
            186,
            24,
            {'text': t(markTr('Distinguir mayúsculas'))},
            {'command': rules},
          ),
          section('Sec2', 258, t(markTr('2. Prefijo y sufijo'))),
          caption('LblPrefix', 16, 288, 104, t(markTr('Prefijo'))),
          field('Prefix', 120, 286, 256),
          caption('LblSuffix', 16, 320, 104, t(markTr('Sufijo'))),
          field('Suffix', 120, 318, 256),
          section('Sec3', 354, t(markTr('3. Numeración'))),
          caption('LblNumPos', 16, 384, 104, t(markTr('Posición'))),
          choice('NumPos', 120, 382, 256, numbering),
          caption('LblStart', 16, 416, 52, t(markTr('Desde'))),
          field('NumStart', 68, 414, 52, '1'),
          caption('LblStep', 132, 416, 44, t(markTr('Paso'))),
          field('NumStep', 176, 414, 44, '1'),
          caption('LblDigits', 232, 416, 52, t(markTr('Cifras'))),
          field('NumDigits', 284, 414, 40, '3'),
          caption('LblSep', 16, 448, 104, t(markTr('Separador'))),
          field('NumSep', 120, 446, 60, '_'),
          section('Sec4', 482, t(markTr('4. Mayúsculas y extensión'))),
          caption('LblCase', 16, 512, 104, t(markTr('Letras'))),
          choice('CaseMode', 120, 510, 256, cases),
          caption('LblExt', 16, 544, 104, t(markTr('Extensión'))),
          choice('ExtMode', 120, 542, 140, exts),
          field('NewExt', 268, 542, 108),
          button('BtnApply', 16, 116, t(markTr('Aplicar'))),
          button('BtnUndo', 140, 116, t(markTr('Deshacer'))),
          button('BtnReload', 264, 112, t(markTr('Actualizar'))),
          _w('Label', 'Note', 16, 628, 360, 40, {
            ..._label(
              t(
                markTr(
                  'Las reglas se aplican en orden al nombre sin la extensión. Nunca se borra ningún archivo.',
                ),
              ),
            ),
            'fg': '#5f6672',
          }),
          _w('Treeview', 'Preview', 392, 132, 672, 536, {
            'columns': [
              'folder|${t(markTr('Carpeta'))}|120',
              'old|${t(markTr('Nombre actual'))}|196',
              'new|${t(markTr('Nombre nuevo'))}|196',
              'state|${t(markTr('Estado'))}|144',
            ].join('\n'),
          }),
          _w('StatusBar', 'Status', 0, 676, 1080, 24, {
            'text': t(markTr('Elija una carpeta para empezar.')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import errno
import fnmatch
import os
import re
import uuid
from collections import Counter
from tkinter import filedialog, messagebox, ttk

APP = ${_py(app)}
CHOOSE = ${_py(t(markTr('Elegir la carpeta')))}
NO_FOLDER = ${_py(t(markTr('La carpeta «{0}» no existe.')))}
START = ${_py(t(markTr('Elija una carpeta para empezar.')))}
SUMMARY = ${_py(t(markTr('{0} archivos   ·   {1} cambian   ·   {2} con conflictos')))}
LIMITED = ${_py(t(markTr('Se muestran solo los primeros {0} archivos.')))}
BAD_REGEX = ${_py(t(markTr('Expresión regular no válida: {0}')))}
BAD_NUMBERS = ${_py(t(markTr('Desde, paso y cifras deben ser números enteros (cifras de 0 a 10).')))}
ASK = ${_py(t(markTr('¿Cambiar el nombre de {0} archivos?')))}
DONE = ${_py(t(markTr('Se han renombrado {0} archivos.')))}
FAILED = ${_py(t(markTr('No se pudo renombrar; no se ha cambiado nada: {0}')))}
UNDONE = ${_py(t(markTr('Deshecho: {0} archivos vuelven a su nombre anterior.')))}
UNDO_FAILED = ${_py(t(markTr('No se pudo deshacer: {0}')))}
FIX_FIRST = ${_py(t(markTr('Resuelva los conflictos (en rojo) antes de aplicar.')))}
TAKEN = ${_py(t(markTr('Ya existe un archivo con ese nombre.')))}
STATES = {
    "change": ${_py(t(markTr('cambia')))},
    "same": ${_py(t(markTr('sin cambios')))},
    "duplicate": ${_py(t(markTr('duplicado')))},
    "exists": ${_py(t(markTr('ya existe')))},
    "invalid": ${_py(t(markTr('no válido en Windows')))},
    "empty": ${_py(t(markTr('nombre vacío')))},
    "long": ${_py(t(markTr('demasiado largo')))},
}
'''
      r'''LIMIT = 5000
TEMP = ".dms-renaming-"
INVALID = set('<>:"/\\|?*')
RESERVED = {"CON", "PRN", "AUX", "NUL"} | {
    prefix + str(n) for prefix in ("COM", "LPT") for n in range(1, 10)
}
NUMBERING = ("", "before", "after", "replace")
CASES = ("", "lower", "upper", "title")


def patterns_of(text):
    """«*.jpg; png» -> ["*.jpg", "*.png"]; vacío -> ["*"]."""
    found = []
    for part in re.split(r"[;,]", text):
        part = part.strip()
        if not part:
            continue
        if not any(c in part for c in "*?["):
            part = "*." + part.lstrip(".")  # «jpg» o «.jpg»: la extensión.
        found.append(part.lower())
    return found or ["*"]


def list_files(folder, subfolders=False, patterns=("*",), limit=LIMIT):
    """[(subcarpeta relativa, nombre)] en orden, sin los ocultos."""
    found = []
    for top, dirs, names in os.walk(folder):
        dirs[:] = sorted((d for d in dirs if not d.startswith(".")), key=str.casefold)
        relative = os.path.relpath(top, folder)
        relative = "" if relative == "." else relative
        for name in sorted(names, key=str.casefold):
            if name.startswith(".") or not os.path.isfile(os.path.join(top, name)):
                continue
            if any(fnmatch.fnmatchcase(name.lower(), p) for p in patterns):
                found.append((relative, name))
                if len(found) >= limit:
                    return found
        if not subfolders:
            break
    return found


def title_case(text):
    return re.sub(r"[^\W_]+", lambda m: m.group(0)[:1].upper() + m.group(0)[1:].lower(), text)


def make_rules(find="", replace="", regex=False, match_case=False, prefix="",
               suffix="", numbering="", start="1", step="1", digits="3",
               separator="_", case="", ext="", new_ext=""):
    """Las reglas listas para new_name; ValueError con el mensaje si no valen."""
    pattern = None
    if find:
        flags = 0 if match_case else re.IGNORECASE
        try:
            pattern = re.compile(find if regex else re.escape(find), flags)
        except re.error as error:
            raise ValueError(BAD_REGEX.format(error)) from None
    try:
        start, step, digits = int(start), int(step), int(digits)
    except ValueError:
        raise ValueError(BAD_NUMBERS) from None
    if not 0 <= digits <= 10:
        raise ValueError(BAD_NUMBERS)
    return {
        "pattern": pattern, "replace": replace, "regex": regex,
        "prefix": prefix, "suffix": suffix, "numbering": numbering,
        "start": start, "step": step, "digits": digits, "separator": separator,
        "case": case, "ext": ext, "new_ext": new_ext.strip().lstrip("."),
    }


def new_name(name, index, rules):
    """El nombre nuevo de name, el archivo número index (desde 0) del lote."""
    stem, ext = os.path.splitext(name)
    pattern = rules["pattern"]
    if pattern is not None:
        if rules["regex"]:
            try:
                stem = pattern.sub(rules["replace"], stem)
            except (re.error, IndexError) as error:
                raise ValueError(BAD_REGEX.format(error)) from None
        else:
            stem = pattern.sub(lambda m: rules["replace"], stem)
    stem = rules["prefix"] + stem + rules["suffix"]
    where = rules["numbering"]
    if where:
        number = rules["start"] + index * rules["step"]
        text = ("-" if number < 0 else "") + str(abs(number)).zfill(rules["digits"])
        if where == "before":
            stem = text + rules["separator"] + stem
        elif where == "after":
            stem = stem + rules["separator"] + text
        else:
            stem = text
    if rules["case"] == "lower":
        stem = stem.lower()
    elif rules["case"] == "upper":
        stem = stem.upper()
    elif rules["case"] == "title":
        stem = title_case(stem)
    if rules["ext"] == "lower":
        ext = ext.lower()
    elif rules["ext"] == "upper":
        ext = ext.upper()
    elif rules["ext"] == "change":
        ext = "." + rules["new_ext"] if rules["new_ext"] else ""
    return stem + ext


def problem(name):
    """Por qué name no vale como nombre de archivo (en Windows tampoco)."""
    if not name.strip() or name in (".", ".."):
        return "empty"
    if len(name) > 255:
        return "long"
    if any(c in INVALID or ord(c) < 32 for c in name) or name[-1] in " .":
        return "invalid"
    if name.split(".")[0].strip().upper() in RESERVED:
        return "invalid"
    return ""


def make_plan(folder, files, rules):
    """[{rel, old, new, state}] con los conflictos de cada carpeta."""
    rows = []
    for index, (rel, old) in enumerate(files):
        rows.append({"rel": rel, "old": old, "new": new_name(old, index, rules)})
    groups = {}
    for row in rows:
        groups.setdefault(row["rel"], []).append(row)
    for rel, group in groups.items():
        try:
            present = {n.casefold() for n in os.listdir(os.path.join(folder, rel))}
        except OSError:
            present = set()
        leaving = {r["old"].casefold() for r in group if r["new"] != r["old"]}
        taken = Counter(r["new"].casefold() for r in group)
        wanted = Counter(r["new"].casefold() for r in group if r["new"] != r["old"])
        for row in group:
            old, new = row["old"], row["new"]
            if new == old:
                # Solo choca si otro archivo quiere quedarse con su nombre.
                row["state"] = "duplicate" if wanted[new.casefold()] else "same"
                continue
            row["state"] = problem(new) or "change"
            if row["state"] == "change" and taken[new.casefold()] > 1:
                row["state"] = "duplicate"
            elif row["state"] == "change" and new.casefold() != old.casefold() \
                    and new.casefold() in present and new.casefold() not in leaving:
                row["state"] = "exists"
    return rows


def rename_all(pairs):
    """Cambia los nombres de pairs [(origen, destino)] en dos pasos (antes, a
    un nombre temporal), así a->b y b->a también funcionan. Nunca
    sobrescribe: si algo falla, deshace lo hecho y lanza OSError."""
    done = []
    try:
        moved = []
        for source, target in pairs:
            temp = os.path.join(os.path.dirname(source), TEMP + uuid.uuid4().hex[:12])
            os.rename(source, temp)
            done.append((source, temp))
            moved.append((temp, target))
        for temp, target in moved:
            if os.path.lexists(target):
                raise FileExistsError(errno.EEXIST, TAKEN, target)
            os.rename(temp, target)
            done.append((temp, target))
    except OSError:
        for source, target in reversed(done):
            try:
                os.rename(target, source)
            except OSError:
                pass
        raise


class Form1(FormDesign):
    def form_create(self):
        self.folder = ""
        self.files = []
        self.rows = []
        self.history = []  # lotes aplicados: [(origen, destino)]
        self.pending = None
        self.error = ""
        for box in (self.NumPos, self.CaseMode, self.ExtMode):
            box.current(0)
        # Tabla clara también con el modo oscuro del sistema.
        style = ttk.Style(self.root)
        style.configure("Rename.Treeview", background="#ffffff", fieldbackground="#ffffff",
                        foreground="#1b1d22", rowheight=22)
        style.configure("Rename.Treeview.Heading", foreground="#1b1d22")
        style.map("Rename.Treeview", background=[("selected", "#cfe0f7")],
                  foreground=[("selected", "#1b1d22")])
        self.Preview.configure(style="Rename.Treeview")
        self.Note.configure(wraplength=356, justify="left")
        self.Preview.tag_configure("same", foreground="#8a9099")
        self.Preview.tag_configure("change", foreground="#1b4f9c")
        self.Preview.tag_configure("conflict", background="#fde2e1", foreground="#a4161a")
        self.update_buttons()
        self.Folder.focus_set()

    # ----------------------------------------------------------- carpeta
    def BtnBrowse_click(self):
        folder = filedialog.askdirectory(
            parent=self.root, title=CHOOSE, mustexist=True,
            initialdir=self.folder or os.path.expanduser("~"),
        )
        if folder:
            self.Folder_var.set(os.path.normpath(folder))
            self.load()

    def Folder_return(self, event=None):
        self.load()

    def Filter_key_up(self, event=None):
        self.later(self.load)

    def BtnReload_click(self):
        self.load()

    def load(self):
        """Vuelve a leer los archivos de la carpeta y la vista previa."""
        folder = os.path.expanduser(self.Folder_var.get().strip())
        if not folder:
            self.files = []
            self.folder = ""
            self.refresh()
            return
        if not os.path.isdir(folder):
            self.files = []
            self.folder = ""
            self.refresh()
            self.Status.set(NO_FOLDER.format(folder), icon="warning")
            return
        self.folder = os.path.abspath(folder)
        self.Folder.xview_moveto(1)  # Que se vea el final de la ruta.
        self.files = list_files(
            self.folder, bool(self.Subfolders_var.get()), patterns_of(self.Filter_var.get())
        )
        self.refresh()

    # ------------------------------------------------------------ reglas
    def Rules_changed(self, event=None):
        self.later(self.refresh)

    def later(self, action):
        """Espera a que deje de escribir para no recalcular en cada tecla."""
        if self.pending is not None:
            self.root.after_cancel(self.pending)
        self.pending = self.root.after(200, lambda: (setattr(self, "pending", None), action()))

    def rules(self):
        return make_rules(
            find=self.Find_var.get(), replace=self.Replace_var.get(),
            regex=bool(self.Regex_var.get()), match_case=bool(self.MatchCase_var.get()),
            prefix=self.Prefix_var.get(), suffix=self.Suffix_var.get(),
            numbering=NUMBERING[max(self.NumPos.current(), 0)],
            start=self.NumStart_var.get(), step=self.NumStep_var.get(),
            digits=self.NumDigits_var.get(), separator=self.NumSep_var.get(),
            case=CASES[max(self.CaseMode.current(), 0)],
            ext=("", "lower", "upper", "change")[max(self.ExtMode.current(), 0)],
            new_ext=self.NewExt_var.get(),
        )

    def refresh(self):
        """Calcula la vista previa con las reglas y la muestra."""
        self.error = ""
        try:
            self.rows = make_plan(self.folder, self.files, self.rules())
        except ValueError as error:
            self.error = str(error)
            self.rows = [dict(rel=r, old=o, new="", state="same") for r, o in self.files]
        self.Preview.delete(*self.Preview.get_children())
        first = None
        for index, row in enumerate(self.rows):
            state = row["state"]
            tag = state if state in ("same", "change") else "conflict"
            iid = self.Preview.insert(
                "", "end", iid=str(index),
                values=(row["rel"], row["old"], row["new"], STATES[state]), tags=(tag,),
            )
            if tag == "conflict" and first is None:
                first = iid
        if first is not None:
            self.Preview.see(first)
        self.update_buttons()

    def counts(self):
        changes = sum(1 for r in self.rows if r["state"] == "change")
        conflicts = sum(1 for r in self.rows if r["state"] not in ("change", "same"))
        return changes, conflicts

    def update_buttons(self):
        changes, conflicts = self.counts()
        ready = changes and not conflicts and not self.error
        self.BtnApply.configure(state="normal" if ready else "disabled")
        self.BtnUndo.configure(state="normal" if self.history else "disabled")
        if self.error:
            self.Status.set(self.error, icon="warning")
        elif not self.folder:
            self.Status.set(START, icon="info")
        else:
            text = SUMMARY.format(len(self.rows), changes, conflicts)
            if len(self.files) >= LIMIT:
                text += "   ·   " + LIMITED.format(LIMIT)
            self.Status.set(text, icon="warning" if conflicts else "info")

    # ------------------------------------------------------------ aplicar
    def BtnApply_click(self):
        if self.pending is not None:  # Reglas recién escritas: al día.
            self.root.after_cancel(self.pending)
            self.pending = None
            self.refresh()
        changes, conflicts = self.counts()
        if conflicts or self.error:
            self.Status.set(self.error or FIX_FIRST, icon="warning")
            return
        if not changes:
            return
        if not messagebox.askyesno(APP, ASK.format(changes), parent=self.root):
            return
        pairs = [
            (os.path.join(self.folder, r["rel"], r["old"]), os.path.join(self.folder, r["rel"], r["new"]))
            for r in self.rows if r["state"] == "change"
        ]
        try:
            rename_all(pairs)
        except OSError as error:
            messagebox.showerror(APP, FAILED.format(error), parent=self.root)
            self.load()
            return
        self.history.append(pairs)
        self.load()
        self.Status.set(DONE.format(len(pairs)), icon="check")

    def BtnUndo_click(self):
        if not self.history:
            return
        pairs = self.history.pop()
        try:
            rename_all([(target, source) for source, target in pairs])
        except OSError as error:
            self.history.append(pairs)
            messagebox.showerror(APP, UNDO_FAILED.format(error), parent=self.root)
            self.load()
            return
        self.load()
        self.Status.set(UNDONE.format(len(pairs)), icon="check")

    def form_close(self, *args):
        if self.pending is not None:
            self.root.after_cancel(self.pending)
        self.root.destroy()
''';
  return TkExample(
    'file_renamer',
    app,
    t(
      markTr(
        'Renombra archivos por lotes con reglas en orden (buscar y reemplazar, prefijo, numeración, mayúsculas, extensión), vista previa con conflictos y Deshacer.',
      ),
    ),
    design,
    code,
  );
}
