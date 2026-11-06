part of 'tk_examples.dart';

// ------------------------------------------------------------ editor de PDF
/// Editor de PDF con pypdf: ordenar, girar, eliminar, duplicar e insertar
/// páginas de otro PDF, extraer y dividir, ver el texto, propiedades, sellos
/// de texto y contraseña. Todo queda en memoria hasta Guardar.
TkExample tkUtilPdfEditor(String Function(String) t) {
  final app = t(markTr('Editor de PDF'));
  final file = t(markTr('Archivo')), edit = t(markTr('Edición'));
  final doc = t(markTr('Documento')), help = t(markTr('Ayuda'));
  final open = t(markTr('Abrir…'));
  final insert = t(markTr('Insertar páginas de otro PDF…'));
  final save = t(markTr('Guardar')), saveAs = t(markTr('Guardar como…'));
  final extract = t(markTr('Extraer las páginas elegidas…'));
  final split = t(markTr('Dividir en un PDF por página…'));
  final quit = t(markTr('Salir'));
  final undo = t(markTr('Deshacer'));
  final selectAll = t(markTr('Seleccionar todas'));
  final rotLeft = t(markTr('Girar a la izquierda'));
  final rotRight = t(markTr('Girar a la derecha'));
  final up = t(markTr('Subir')), down = t(markTr('Bajar'));
  final duplicate = t(markTr('Duplicar')), delete = t(markTr('Eliminar'));
  final stamp = t(markTr('Añadir un sello de texto…'));
  final password = t(markTr('Contraseña…'));
  final about = t(markTr('Acerca de'));
  final items = [
    file,
    '  $open',
    '  $insert',
    '  -',
    '  $save',
    '  $saveAs',
    '  -',
    '  $extract',
    '  $split',
    '  -',
    '  $quit',
    edit,
    '  $undo',
    '  -',
    '  $selectAll',
    '  -',
    '  $rotLeft',
    '  $rotRight',
    '  $up',
    '  $down',
    '  $duplicate',
    '  $delete',
    doc,
    '  $stamp',
    '  $password',
    help,
    '  $about',
  ].join('\n');
  final filter = '${t(markTr('Documentos PDF'))}|*.pdf';
  TkWidget tool(String name, int x, int w, String text) => _w(
    'Button',
    name,
    x,
    8,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  TkWidget side(String name, int x, int y, String text) => _w(
    'Button',
    name,
    x,
    y,
    180,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  TkWidget field(String name, int y, String label) =>
      _w('Label', 'Lbl$name', 624, y, 72, 24, _label(label));
  TkWidget entry(String name, int y) =>
      _w('Entry', name, 696, y, 296, 24, {}, {'key_up': 'Meta_key_up'});
  final design =
      TkDesign(
          width: 1000,
          height: 680,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            960,
            48,
            32,
            32,
            {'items': items},
            {'command': 'Menu1_click'},
          ),
          _w('OpenDialog', 'OpenPdf', 920, 48, 32, 32, {
            'title': t(markTr('Abrir un PDF')),
            'filter': filter,
          }),
          _w('OpenDialog', 'InsertPdf', 880, 48, 32, 32, {
            'title': t(
              markTr('Elegir el PDF con las páginas que quiere insertar'),
            ),
            'filter': filter,
          }),
          _w('SaveDialog', 'SavePdf', 840, 48, 32, 32, {
            'title': t(markTr('Guardar el PDF')),
            'filter': filter,
            'defaultext': '.pdf',
            'filename': t(markTr('documento.pdf')),
          }),
          // Barra de herramientas.
          tool('BtnOpen', 8, 80, t(markTr('Abrir'))),
          tool('BtnSave', 92, 84, save),
          tool('BtnUndo', 188, 88, undo),
          tool('BtnRotLeft', 288, 96, '↺  ${t(markTr('Izquierda'))}'),
          tool('BtnRotRight', 388, 96, '↻  ${t(markTr('Derecha'))}'),
          tool('BtnUp', 496, 80, '▲  $up'),
          tool('BtnDown', 580, 80, '▼  $down'),
          tool('BtnDuplicate', 672, 84, duplicate),
          tool('BtnDelete', 760, 84, delete),
          tool('BtnInsert', 856, 136, t(markTr('Insertar PDF…'))),
          // Páginas.
          _w(
            'Label',
            'LblPages',
            8,
            48,
            600,
            24,
            _title(t(markTr('Páginas')), size: 13),
          ),
          _w(
            'Treeview',
            'Pages',
            8,
            76,
            600,
            572,
            {
              'columns': [
                'n|${t(markTr('Nº'))}|48',
                'size|${t(markTr('Tamaño'))}|150',
                'rot|${t(markTr('Giro'))}|56',
                'text|${t(markTr('Texto'))}|330',
              ].join('\n'),
            },
            {'select': 'Pages_select'},
          ),
          // Texto de la página elegida.
          _w(
            'Label',
            'LblText',
            624,
            48,
            368,
            24,
            _title(t(markTr('Texto de la página')), size: 13),
          ),
          _w('Text', 'PageText', 624, 76, 368, 196, {
            'wrap': 'word',
            'font_size': 11,
          }),
          // Propiedades del documento.
          _w(
            'Label',
            'LblProps',
            624,
            284,
            368,
            24,
            _title(t(markTr('Propiedades')), size: 13),
          ),
          field('DocTitle', 314, t(markTr('Título'))),
          entry('DocTitle', 314),
          field('DocAuthor', 346, t(markTr('Autor'))),
          entry('DocAuthor', 346),
          field('DocSubject', 378, t(markTr('Asunto'))),
          entry('DocSubject', 378),
          // Lo que se hace con las páginas elegidas.
          _w(
            'Label',
            'LblSelected',
            624,
            416,
            368,
            24,
            _title(t(markTr('Páginas elegidas')), size: 13),
          ),
          side('BtnExtract', 624, 444, t(markTr('Extraer a un PDF…'))),
          side('BtnSplit', 812, 444, t(markTr('Dividir por páginas…'))),
          side('BtnStamp', 624, 484, t(markTr('Sello de texto…'))),
          side('BtnPassword', 812, 484, password),
          _w('Label', 'Security', 624, 524, 368, 24, {
            ..._label(t(markTr('Sin contraseña.'))),
            'fg': '#5f6672',
          }),
          _w('Label', 'Hint', 624, 556, 368, 88, {
            ..._label(
              t(
                markTr(
                  'Elija varias páginas con Mayús o Ctrl (Cmd en el Mac). Los cambios quedan en memoria hasta que pulse Guardar.',
                ),
              ),
            ),
            'fg': '#5f6672',
            'justify': 'left',
            'wraplength': 360,
          }),
          _w('StatusBar', 'Status', 0, 656, 1000, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import io
import math
import os
import sys
import time
import tkinter as tk
import unicodedata
from tkinter import filedialog, messagebox, simpledialog, ttk

# Paquetes de terceros que necesita el programa (las demos los instalan).
REQUIRES = ["pypdf"]

try:
    import pypdf
    from pypdf import PageObject, PdfReader, PdfWriter
    from pypdf.errors import DependencyError
    from pypdf.generic import DecodedStreamObject, DictionaryObject, FloatObject, NameObject
except ImportError:
    pypdf = None

PIP = "py" if sys.platform.startswith("win") else "python3"
INSTALL = PIP + " -m pip install pypdf"
INSTALL_CRYPTO = PIP + " -m pip install cryptography"

APP = ${_py(app)}
UNTITLED = ${_py(t(markTr('Sin título')))}
NO_PYPDF = ${_py(t(markTr('Para editar PDF hace falta el paquete pypdf. Instálelo con: {0}')))}
EMPTY = ${_py(t(markTr('Abra un PDF con el botón Abrir o con Archivo → Abrir…')))}
STATUS = ${_py(t(markTr('{0} páginas   ·   {1} elegidas')))}
ASK_SAVE = ${_py(t(markTr('¿Guardar los cambios de «{0}»?')))}
ASK_PASSWORD = ${_py(t(markTr('«{0}» está protegido. Escriba la contraseña:')))}
BAD_PASSWORD = ${_py(t(markTr('La contraseña no es correcta.')))}
NEEDS_CRYPTO = ${_py(t(markTr('Este PDF usa un cifrado que necesita el paquete cryptography. Instálelo con: {0}')))}
CANT_OPEN = ${_py(t(markTr('No se pudo abrir «{0}»: {1}')))}
CANT_SAVE = ${_py(t(markTr('No se pudo guardar: {0}')))}
OPENED = ${_py(t(markTr('Abierto: {0} ({1} páginas)')))}
SAVED = ${_py(t(markTr('Guardado: {0}')))}
SAVED_LOCKED = ${_py(t(markTr('Guardado con contraseña ({1}): {0}')))}
NO_SELECTION = ${_py(t(markTr('Elija una o varias páginas de la lista.')))}
NO_DOCUMENT = ${_py(t(markTr('Primero abra un PDF.')))}
DONE = ${_py(t(markTr('{0}: {1} páginas')))}
KEEP_ONE = ${_py(t(markTr('Un PDF necesita al menos una página: no se pueden eliminar todas.')))}
INSERT_WHERE = ${_py(t(markTr('¿Antes de qué página se insertan las {0} páginas? ({1} = al final)')))}
INSERTED = ${_py(t(markTr('Insertadas {0} páginas de «{1}».')))}
EXTRACTED = ${_py(t(markTr('{0} páginas extraídas en «{1}».')))}
SPLIT_FOLDER = ${_py(t(markTr('Elija la carpeta para los PDF de cada página')))}
SPLIT_DONE = ${_py(t(markTr('{0} archivos creados en «{1}».')))}
EXTRACT_SUFFIX = ${_py(t(markTr('_extracto')))}
UNDONE = ${_py(t(markTr('Deshecho: {0}')))}
NOTHING_TO_UNDO = ${_py(t(markTr('No hay nada que deshacer.')))}
PASSWORD_ASK = ${_py(t(markTr('Contraseña para abrir el PDF (vacía = sin contraseña):')))}
PASSWORD_REPEAT = ${_py(t(markTr('Repita la contraseña:')))}
PASSWORD_MISMATCH = ${_py(t(markTr('Las contraseñas no coinciden.')))}
PASSWORD_LABEL = ${_py(t(markTr('Contraseña')))}
LOCK_ON = ${_py(t(markTr('Se guardará protegido con contraseña.')))}
LOCK_OFF = ${_py(t(markTr('Sin contraseña.')))}
PROPERTIES = ${_py(t(markTr('Propiedades')))}
STAMP_LABEL = ${_py(t(markTr('Sello')))}
STAMP_MARK = ${_py(t(markTr('[Sello: {0}] ')))}
PAGE_TEXT = ${_py(t(markTr('Texto de la página {0}')))}
NO_TEXT = ${_py(t(markTr('(Esta página no tiene texto: puede ser una imagen escaneada.)')))}
LETTER = ${_py(t(markTr('Carta')))}
ABOUT = ${_py(t(markTr('Editor de PDF de ejemplo de DMarlon Studio, hecho con pypdf: ordene, gire, elimine, una y divida páginas, cambie las propiedades, añada sellos y proteja el PDF con contraseña. Nada cambia en el disco hasta que pulse Guardar.')))}
# Diálogo del sello.
STAMP_TITLE = ${_py(t(markTr('Sello de texto')))}
STAMP_TEXT = ${_py(t(markTr('Texto')))}
STAMP_DEFAULT = ${_py(t(markTr('BORRADOR')))}
STAMP_PLACE = ${_py(t(markTr('Posición')))}
STAMP_SIZE = ${_py(t(markTr('Tamaño')))}
STAMP_COLOR = ${_py(t(markTr('Color')))}
OK = ${_py(t(markTr('Aceptar')))}
CANCEL = ${_py(t(markTr('Cancelar')))}
PLACES = [
    ("top", ${_py(t(markTr('Arriba')))}),
    ("center", ${_py(t(markTr('En el centro')))}),
    ("bottom", ${_py(t(markTr('Abajo')))}),
    ("diagonal", ${_py(t(markTr('En diagonal (marca de agua)')))}),
]
COLORS = [
    ((0.80, 0.12, 0.12), ${_py(t(markTr('Rojo')))}),
    ((0.10, 0.30, 0.70), ${_py(t(markTr('Azul')))}),
    ((0.10, 0.50, 0.20), ${_py(t(markTr('Verde')))}),
    ((0.45, 0.45, 0.45), ${_py(t(markTr('Gris')))}),
    ((0.0, 0.0, 0.0), ${_py(t(markTr('Negro')))}),
]
PAPERS = (("A3", 297, 420), ("A4", 210, 297), ("A5", 148, 210), (LETTER, 216, 279), ("Legal", 216, 356))

# Anchos de la Helvetica (1/1000 del cuerpo) de los caracteres 32 a 126,
# para centrar los sellos.
HELVETICA = [
    278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
    1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
    667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
    333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
    556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
]


# ------------------------------------------------------------ utilidades
def text_width(text, size):
    """Ancho en puntos de text en Helvetica de cuerpo size."""
    total = 0
    for char in text:
        base = unicodedata.normalize("NFD", char)[:1] or char
        code = ord(base)
        total += HELVETICA[code - 32] if 32 <= code <= 126 else 556
    return total * size / 1000.0


def pdf_string(text):
    """text como cadena literal de PDF en WinAnsi: (texto)."""
    data = text.encode("cp1252", "replace")
    slash = bytes([92])
    for char in (slash, b"(", b")"):
        data = data.replace(char, slash + char)
    return b"(" + data + b")"


def paper_name(width_mm, height_mm):
    small, large = sorted((width_mm, height_mm))
    for name, a, b in PAPERS:
        if abs(small - a) <= 2 and abs(large - b) <= 2:
            return name
    return ""


def page_size(page, rotation):
    """«210 × 297 mm · A4» tal como se ve la página (con el giro)."""
    box = page.cropbox
    width, height = float(box.width), float(box.height)
    if rotation % 180:
        width, height = height, width
    w_mm, h_mm = round(width * 25.4 / 72), round(height * 25.4 / 72)
    text = "%d × %d mm" % (w_mm, h_mm)
    name = paper_name(w_mm, h_mm)
    return text + "  ·  " + name if name else text


def first_words(text, count=14):
    words = text.split()
    preview = " ".join(words[:count])
    return preview + (" …" if len(words) > count else "")


def stamp_page(page, stamp):
    """Dibuja el sello en el contenido de la página (lo ve cualquier lector).

    stamp: {"text", "place", "size", "color", "rotation"}; rotation es el
    giro que tenía la página al poner el sello, para que salga derecho."""
    box = page.cropbox
    left, bottom = float(box.left), float(box.bottom)
    width, height = float(box.width), float(box.height)
    rotation = stamp.get("rotation", 0) % 360
    # De las coordenadas de la página tal como se ve a las del PDF.
    matrix = {
        0: (1, 0, 0, 1, left, bottom),
        90: (0, 1, -1, 0, left + width, bottom),
        180: (-1, 0, 0, -1, left + width, bottom + height),
        270: (0, -1, 1, 0, left, bottom + height),
    }[rotation]
    seen_w, seen_h = (height, width) if rotation in (90, 270) else (width, height)
    size = float(stamp["size"])
    text = stamp["text"]
    text_w = text_width(text, size)
    red, green, blue = stamp["color"]
    ops = ["q", "%.4f %.4f %.4f %.4f %.4f %.4f cm" % matrix]
    if stamp["place"] == "diagonal":
        angle = math.atan2(seen_h, seen_w)
        cos, sin = math.cos(angle), math.sin(angle)
        ops.append("1 0 0 1 %.2f %.2f cm" % (seen_w / 2, seen_h / 2))
        ops.append("%.4f %.4f %.4f %.4f 0 0 cm" % (cos, sin, -sin, cos))
        ops.append("/DMSAlpha gs")
        x, y = -text_w / 2, -size * 0.35
    else:
        x = (seen_w - text_w) / 2
        margin = 28
        y = {
            "top": seen_h - margin - size,
            "center": (seen_h - size * 0.7) / 2,
            "bottom": margin + size * 0.3,
        }[stamp["place"]]
        pad = size * 0.3
        ops.append("%.3f %.3f %.3f RG %.2f w" % (red, green, blue, max(1.0, size / 14)))
        ops.append("%.2f %.2f %.2f %.2f re S" % (x - pad, y - pad, text_w + 2 * pad, size * 0.72 + 2 * pad))
    ops.append("%.3f %.3f %.3f rg BT /DMSHelv %.2f Tf %.2f %.2f Td" % (red, green, blue, size, x, y))
    data = " ".join(ops).encode("ascii") + b" " + pdf_string(text) + b" Tj ET Q"
    font = DictionaryObject({
        NameObject("/Type"): NameObject("/Font"),
        NameObject("/Subtype"): NameObject("/Type1"),
        NameObject("/BaseFont"): NameObject("/Helvetica"),
        NameObject("/Encoding"): NameObject("/WinAnsiEncoding"),
    })
    alpha = DictionaryObject({
        NameObject("/Type"): NameObject("/ExtGState"),
        NameObject("/ca"): FloatObject(0.3),
        NameObject("/CA"): FloatObject(0.3),
    })
    layer = PageObject.create_blank_page(width=left + width, height=bottom + height)
    layer[NameObject("/Resources")] = DictionaryObject({
        NameObject("/Font"): DictionaryObject({NameObject("/DMSHelv"): font}),
        NameObject("/ExtGState"): DictionaryObject({NameObject("/DMSAlpha"): alpha}),
    })
    content = DecodedStreamObject()
    content.set_data(data)
    layer[NameObject("/Contents")] = content
    page.merge_page(layer)


_AES = []


def aes_available():
    """True si pypdf puede cifrar con AES (con cryptography o pycryptodome)."""
    if not _AES:
        try:
            probe = PdfWriter()
            probe.add_blank_page(72, 72)
            probe.encrypt("x", algorithm="AES-256")
            probe.write(io.BytesIO())
            _AES.append(True)
        except DependencyError:
            _AES.append(False)
    return _AES[0]


def protect(writer, password):
    """Cifra con AES-256 si se puede; si no, con RC4 de 128 bits, que pypdf
    hace sin nada más. Devuelve el algoritmo."""
    algorithm = "AES-256" if aes_available() else "RC4-128"
    writer.encrypt(password, algorithm=algorithm)
    return algorithm


def build_pdf(sources, entries, meta=None, password=""):
    """Un PdfWriter con las páginas de entries, en ese orden: (writer, cifrado)."""
    writer = PdfWriter()
    for entry in entries:
        page = writer.add_page(sources[entry["src"]].pages[entry["page"]])
        if entry["rot"]:
            page.rotate(entry["rot"])
        for stamp in entry["stamps"]:
            stamp_page(page, stamp)
    info = {"/Producer": "DMarlon Studio · pypdf"}
    for key, name in (("title", "/Title"), ("author", "/Author"), ("subject", "/Subject")):
        value = (meta or {}).get(key, "").strip()
        if value:
            info[name] = value
    writer.add_metadata(info)
    algorithm = protect(writer, password) if password else ""
    return writer, algorithm


def write_pdf(writer, path):
    """Escribe en un temporal y lo cambia por path: nunca deja el PDF a medias."""
    temp = path + ".tmp"
    try:
        with open(temp, "wb") as target:
            writer.write(target)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.remove(temp)


class StampDialog(tk.Toplevel):
    """Pide el texto, la posición, el tamaño y el color del sello."""

    def __init__(self, parent):
        super().__init__(parent)
        self.title(STAMP_TITLE)
        self.resizable(False, False)
        self.transient(parent)
        self.result = None
        self.text_var = tk.StringVar(value=STAMP_DEFAULT)
        self.size_var = tk.IntVar(value=28)
        self.columnconfigure(1, weight=1)
        rows = (STAMP_TEXT, STAMP_PLACE, STAMP_SIZE, STAMP_COLOR)
        for row, label in enumerate(rows):
            tk.Label(self, text=label).grid(row=row, column=0, sticky="w", padx=12, pady=6)
        entry = tk.Entry(self, textvariable=self.text_var, width=30)
        entry.grid(row=0, column=1, sticky="ew", padx=12, pady=6)
        self.place_box = ttk.Combobox(self, state="readonly", values=[name for _, name in PLACES])
        self.place_box.current(0)
        self.place_box.grid(row=1, column=1, sticky="ew", padx=12, pady=6)
        tk.Spinbox(self, from_=8, to=120, textvariable=self.size_var, width=6).grid(
            row=2, column=1, sticky="w", padx=12, pady=6
        )
        self.color_box = ttk.Combobox(self, state="readonly", values=[name for _, name in COLORS])
        self.color_box.current(0)
        self.color_box.grid(row=3, column=1, sticky="ew", padx=12, pady=6)
        buttons = tk.Frame(self)
        buttons.grid(row=4, column=0, columnspan=2, sticky="e", padx=12, pady=12)
        tk.Button(buttons, text=CANCEL, command=self.destroy).pack(side="right")
        tk.Button(buttons, text=OK, command=self.accept).pack(side="right", padx=6)
        self.bind("<Return>", lambda event: self.accept())
        self.bind("<Escape>", lambda event: self.destroy())
        self.update_idletasks()
        x = parent.winfo_rootx() + (parent.winfo_width() - self.winfo_width()) // 2
        y = parent.winfo_rooty() + (parent.winfo_height() - self.winfo_height()) // 3
        self.geometry("+%d+%d" % (max(x, 0), max(y, 0)))
        entry.focus_set()
        entry.select_range(0, "end")
        self.wait_visibility()
        self.grab_set()

    def accept(self):
        text = self.text_var.get().strip()
        if not text:
            return
        try:
            size = max(6, min(200, int(self.size_var.get())))
        except (tk.TclError, ValueError):
            size = 28
        self.result = {
            "text": text,
            "place": PLACES[max(0, self.place_box.current())][0],
            "size": size,
            "color": COLORS[max(0, self.color_box.current())][0],
        }
        self.destroy()


class Form1(FormDesign):
    def form_create(self):
        self.sources = []   # Los PDF abiertos o insertados (PdfReader).
        self.entries = []   # Cada página: {"src", "page", "rot", "stamps"}.
        self.meta = {"title": "", "author": "", "subject": ""}
        self.password = ""
        self.path = None
        self.dirty = False
        self.history = []
        self.texts = {}
        self.pending = []
        self.loader = None
        self.last_selection = ()
        self.Pages.configure(selectmode="extended")
        self.Pages.column("n", anchor="e")
        self.PageText.configure(state="disabled")
        shortcuts = (("o", self.open), ("s", self.save), ("z", self.undo), ("a", self.select_all))
        for key, action in shortcuts:
            for modifier in ("Control", "Command"):
                try:
                    self.Pages.bind(
                        "<%s-%s>" % (modifier, key),
                        lambda event, run=action: (run(), "break")[1],
                    )
                except tk.TclError:
                    pass  # Cmd solo existe en macOS.
        self.Pages.bind("<Delete>", lambda event: self.delete())
        self.Pages.bind("<BackSpace>", lambda event: self.delete())
        self.refresh()
        if pypdf is None:
            self.Status.set(NO_PYPDF.format(INSTALL), icon="⚠")
        else:
            self.Status.set(EMPTY, icon="info")
            # Abrir con: el PDF que llega como argumento.
            for arg in sys.argv[1:]:
                if arg.lower().endswith(".pdf") and os.path.isfile(arg):
                    self.load(arg)
                    break

    # ------------------------------------------------------------- estado
    def ready(self, need_document=True):
        if pypdf is None:
            messagebox.showerror(APP, NO_PYPDF.format(INSTALL), parent=self.root)
            return False
        if need_document and not self.entries:
            self.Status.set(NO_DOCUMENT, icon="info")
            return False
        return True

    def chosen(self):
        return sorted(int(iid) for iid in self.Pages.selection())

    def page(self, entry):
        return self.sources[entry["src"]].pages[entry["page"]]

    def rotation(self, entry):
        return (self.page(entry).rotation + entry["rot"]) % 360

    def name(self):
        return os.path.basename(self.path) if self.path else UNTITLED

    def update_title(self):
        mark = "* " if self.dirty else ""
        self.root.title("%s%s - %s" % (mark, self.name(), APP) if self.entries else APP)

    def preview(self, entry):
        key = (entry["src"], entry["page"])
        marks = "".join(STAMP_MARK.format(stamp["text"]) for stamp in entry["stamps"])
        if key not in self.texts:
            return marks + "…"
        return marks + first_words(self.texts[key])

    def row(self, index, entry):
        rotation = self.rotation(entry)
        return (index + 1, page_size(self.page(entry), rotation), "%d°" % rotation, self.preview(entry))

    def refresh(self, select=None):
        """Vuelve a llenar la lista y deja elegidas las páginas select."""
        self.Pages.delete(*self.Pages.get_children())
        for index, entry in enumerate(self.entries):
            self.Pages.insert(
                "", "end", iid=str(index), values=self.row(index, entry)
            )
        if select:
            iids = [str(i) for i in select if 0 <= i < len(self.entries)]
            self.Pages.selection_set(iids)
            if iids:
                self.Pages.see(iids[0])
                self.Pages.focus(iids[0])
        self.last_selection = self.Pages.selection()
        # Las filas sin texto todavía se completan poco a poco.
        self.pending = [i for i, e in enumerate(self.entries) if (e["src"], e["page"]) not in self.texts]
        self.update_title()
        self.show_text()
        self.update_status()
        if self.pending and self.loader is None:
            self.loader = self.root.after(10, self.load_some_texts)

    def update_status(self, text=None, icon="info"):
        if text is None:
            if not self.entries:
                return
            text = STATUS.format(len(self.entries), len(self.Pages.selection()))
        self.Status.set(text, icon=icon)

    def changed(self, select, message=None, icon="check"):
        self.dirty = True
        self.refresh(select)
        if message:
            self.update_status(message, icon)

    # ----------------------------------------------------- texto de las páginas
    def page_text(self, entry):
        key = (entry["src"], entry["page"])
        if key not in self.texts:
            try:
                self.texts[key] = self.page(entry).extract_text() or ""
            except Exception:
                self.texts[key] = ""
        return self.texts[key]

    def load_some_texts(self):
        """Lee el texto de unas pocas páginas cada vez, sin bloquear la ventana."""
        self.loader = None
        done = set()
        until = time.monotonic() + 0.05
        while self.pending and time.monotonic() < until:
            index = self.pending.pop(0)
            if index < len(self.entries):
                entry = self.entries[index]
                self.page_text(entry)
                done.add((entry["src"], entry["page"]))
        # Muestra lo leído en las filas de esas páginas (y sus copias).
        for index, entry in enumerate(self.entries):
            if (entry["src"], entry["page"]) in done and self.Pages.exists(str(index)):
                self.Pages.set(str(index), "text", self.preview(entry))
        if self.pending:
            self.loader = self.root.after(10, self.load_some_texts)

    def show_text(self):
        selected = self.chosen()
        self.PageText.configure(state="normal")
        self.PageText.delete("1.0", "end")
        if selected:
            index = selected[0]
            text = self.page_text(self.entries[index]).strip()
            self.LblText.configure(text=PAGE_TEXT.format(index + 1))
            self.PageText.insert("1.0", text or NO_TEXT)
        self.PageText.configure(state="disabled")

    # ------------------------------------------------------------ deshacer
    def remember(self, label):
        """Guarda cómo está todo antes de un cambio, para Deshacer."""
        pages = [dict(entry, stamps=list(entry["stamps"])) for entry in self.entries]
        self.history.append((label, pages, dict(self.meta), self.password, self.dirty))
        del self.history[:-50]

    def undo(self):
        if not self.history:
            self.update_status(NOTHING_TO_UNDO)
            return
        label, pages, meta, password, dirty = self.history.pop()
        selected = self.chosen()
        self.entries, self.meta, self.password = pages, meta, password
        self.show_meta()
        self.dirty = True
        self.refresh(selected)
        self.update_status(UNDONE.format(label), "check")

    # ------------------------------------------------------------ archivos
    def read(self, path):
        """PdfReader de path (pide la contraseña si hace falta): (lector, contraseña)."""
        name = os.path.basename(path)
        try:
            with open(path, "rb") as source:
                reader = PdfReader(io.BytesIO(source.read()))
            used = ""
            if reader.is_encrypted and not reader.decrypt(""):
                answer = simpledialog.askstring(APP, ASK_PASSWORD.format(name), show="*", parent=self.root)
                if answer is None:
                    return None, ""
                if not reader.decrypt(answer):
                    messagebox.showerror(APP, BAD_PASSWORD, parent=self.root)
                    return None, ""
                used = answer
            if not len(reader.pages):
                raise ValueError("0")
            return reader, used
        except DependencyError:
            messagebox.showerror(APP, NEEDS_CRYPTO.format(INSTALL_CRYPTO), parent=self.root)
        except Exception as error:
            messagebox.showerror(APP, CANT_OPEN.format(name, error), parent=self.root)
        return None, ""

    def load(self, path):
        reader, used = self.read(path)
        if reader is None:
            return False
        self.sources = [reader]
        self.entries = [{"src": 0, "page": i, "rot": 0, "stamps": []} for i in range(len(reader.pages))]
        info = reader.metadata or {}
        self.meta = {
            "title": str(info.get("/Title") or ""),
            "author": str(info.get("/Author") or ""),
            "subject": str(info.get("/Subject") or ""),
        }
        self.password = used
        self.path = path
        self.dirty = False
        self.history = []
        self.texts = {}
        self.SavePdf.suggested = os.path.basename(path)
        self.show_meta()
        self.refresh([0])
        self.update_status(OPENED.format(os.path.basename(path), len(self.entries)), "check")
        return True

    def keep_going(self):
        """True si se puede dejar el PDF actual (guardado o descartado)."""
        if not self.dirty or not self.entries:
            return True
        answer = messagebox.askyesnocancel(APP, ASK_SAVE.format(self.name()), parent=self.root)
        if answer is None:
            return False
        return self.save() if answer else True

    def open(self, path=None):
        if not self.ready(need_document=False) or not self.keep_going():
            return
        path = path or self.OpenPdf.execute()
        if path:
            self.load(path)

    def save(self, ask=False):
        if not self.ready():
            return False
        path = self.path if self.path and not ask else self.SavePdf.execute()
        if not path:
            return False
        try:
            writer, algorithm = build_pdf(self.sources, self.entries, self.meta, self.password)
            write_pdf(writer, path)
        except Exception as error:
            messagebox.showerror(APP, CANT_SAVE.format(error), parent=self.root)
            return False
        self.path = path
        self.dirty = False
        self.update_title()
        name = os.path.basename(path)
        if algorithm:
            self.update_status(SAVED_LOCKED.format(name, algorithm), "check")
        else:
            self.update_status(SAVED.format(name), "check")
        return True

    def insert_pdf(self, path=None):
        if not self.ready(need_document=False):
            return
        if not self.entries:
            return self.open(path)
        path = path or self.InsertPdf.execute()
        if not path:
            return
        reader, _ = self.read(path)
        if reader is None:
            return
        count = len(reader.pages)
        selected = self.chosen()
        last = len(self.entries) + 1
        where = simpledialog.askinteger(
            APP, INSERT_WHERE.format(count, last), parent=self.root,
            initialvalue=selected[-1] + 2 if selected else last, minvalue=1, maxvalue=last,
        )
        if where is None:
            return
        self.remember(insert_label())
        self.sources.append(reader)
        source = len(self.sources) - 1
        new = [{"src": source, "page": i, "rot": 0, "stamps": []} for i in range(count)]
        self.entries[where - 1:where - 1] = new
        self.changed(range(where - 1, where - 1 + count))
        self.update_status(INSERTED.format(count, os.path.basename(path)), "check")

    def extract(self, path=None):
        selected = self.chosen()
        if not self.ready():
            return
        if not selected:
            return self.update_status(NO_SELECTION)
        if path is None:
            base = os.path.splitext(self.name())[0]
            self.SavePdf.suggested = base + EXTRACT_SUFFIX + ".pdf"
            path = self.SavePdf.execute()
            self.SavePdf.suggested = self.name()
        if not path:
            return
        try:
            writer, _ = build_pdf(self.sources, [self.entries[i] for i in selected], self.meta)
            write_pdf(writer, path)
        except Exception as error:
            return messagebox.showerror(APP, CANT_SAVE.format(error), parent=self.root)
        self.update_status(EXTRACTED.format(len(selected), os.path.basename(path)), "check")

    def split(self, folder=None):
        if not self.ready():
            return
        folder = folder or filedialog.askdirectory(parent=self.root, title=SPLIT_FOLDER)
        if not folder:
            return
        base = os.path.splitext(self.name())[0]
        digits = len(str(len(self.entries)))
        try:
            for index, entry in enumerate(self.entries):
                writer, _ = build_pdf(self.sources, [entry], self.meta)
                name = "%s_%0*d.pdf" % (base, max(2, digits), index + 1)
                write_pdf(writer, os.path.join(folder, name))
        except Exception as error:
            return messagebox.showerror(APP, CANT_SAVE.format(error), parent=self.root)
        self.update_status(SPLIT_DONE.format(len(self.entries), folder), "check")

    # ------------------------------------------------------------- páginas
    def selection_or_warn(self):
        if not self.ready():
            return []
        selected = self.chosen()
        if not selected:
            self.update_status(NO_SELECTION, "info")
        return selected

    def select_all(self):
        if self.entries:
            self.Pages.selection_set([str(i) for i in range(len(self.entries))])

    def rotate(self, degrees, label):
        selected = self.selection_or_warn()
        if not selected:
            return
        self.remember(label)
        for index in selected:
            entry = self.entries[index]
            entry["rot"] = (entry["rot"] + degrees) % 360
        self.changed(selected, DONE.format(label, len(selected)))

    def delete(self):
        selected = self.selection_or_warn()
        if not selected:
            return
        if len(selected) == len(self.entries):
            messagebox.showwarning(APP, KEEP_ONE, parent=self.root)
            return
        self.remember(delete_label())
        for index in reversed(selected):
            del self.entries[index]
        self.changed([min(selected[0], len(self.entries) - 1)], DONE.format(delete_label(), len(selected)))

    def move(self, step, label):
        selected = self.selection_or_warn()
        if not selected:
            return
        if (step < 0 and selected[0] == 0) or (step > 0 and selected[-1] == len(self.entries) - 1):
            return
        self.remember(label)
        for index in (selected if step < 0 else reversed(selected)):
            other = index + step
            self.entries[index], self.entries[other] = self.entries[other], self.entries[index]
        self.changed([i + step for i in selected], DONE.format(label, len(selected)))

    def duplicate(self):
        selected = self.selection_or_warn()
        if not selected:
            return
        self.remember(duplicate_label())
        for index in reversed(selected):
            entry = self.entries[index]
            self.entries.insert(index + 1, dict(entry, stamps=list(entry["stamps"])))
        copies = [index + 1 + k for k, index in enumerate(selected)]
        self.changed(copies, DONE.format(duplicate_label(), len(selected)))

    def add_stamp(self, stamp=None):
        selected = self.selection_or_warn()
        if not selected:
            return
        if stamp is None:
            dialog = StampDialog(self.root)
            self.root.wait_window(dialog)
            stamp = dialog.result
        if not stamp:
            return
        self.remember(STAMP_LABEL)
        for index in selected:
            entry = self.entries[index]
            entry["stamps"].append(dict(stamp, rotation=self.rotation(entry)))
        self.changed(selected, DONE.format(STAMP_LABEL, len(selected)))

    def set_password(self):
        if not self.ready():
            return
        first = simpledialog.askstring(APP, PASSWORD_ASK, show="*", parent=self.root)
        if first is None:
            return
        if first:
            second = simpledialog.askstring(APP, PASSWORD_REPEAT, show="*", parent=self.root)
            if second is None:
                return
            if second != first:
                messagebox.showerror(APP, PASSWORD_MISMATCH, parent=self.root)
                return
        if first == self.password:
            return
        self.remember(PASSWORD_LABEL)
        self.password = first
        self.show_meta()
        self.changed(self.chosen(), LOCK_ON if first else LOCK_OFF)

    # --------------------------------------------------------- propiedades
    def show_meta(self):
        self.DocTitle_var.set(self.meta["title"])
        self.DocAuthor_var.set(self.meta["author"])
        self.DocSubject_var.set(self.meta["subject"])
        self.Security.configure(text=LOCK_ON if self.password else LOCK_OFF)

    def Meta_key_up(self, event=None):
        meta = {
            "title": self.DocTitle_var.get(),
            "author": self.DocAuthor_var.get(),
            "subject": self.DocSubject_var.get(),
        }
        if meta != self.meta and self.entries:
            if not self.history or self.history[-1][0] != PROPERTIES:
                self.remember(PROPERTIES)
            self.meta = meta
            self.dirty = True
            self.update_title()

    # ------------------------------------------------------------- eventos
    def Pages_select(self, event=None):
        # Tras un cambio, la selección la pone refresh: se deja su mensaje.
        selection = self.Pages.selection()
        if selection != self.last_selection:
            self.last_selection = selection
            self.show_text()
            self.update_status()

    def BtnOpen_click(self):
        self.open()

    def BtnSave_click(self):
        self.save()

    def BtnUndo_click(self):
        self.undo()

    def BtnRotLeft_click(self):
        self.rotate(-90, ${_py(rotLeft)})

    def BtnRotRight_click(self):
        self.rotate(90, ${_py(rotRight)})

    def BtnUp_click(self):
        self.move(-1, ${_py(up)})

    def BtnDown_click(self):
        self.move(1, ${_py(down)})

    def BtnDuplicate_click(self):
        self.duplicate()

    def BtnDelete_click(self):
        self.delete()

    def BtnInsert_click(self):
        self.insert_pdf()

    def BtnExtract_click(self):
        self.extract()

    def BtnSplit_click(self):
        self.split()

    def BtnStamp_click(self):
        self.add_stamp()

    def BtnPassword_click(self):
        self.set_password()

    def Menu1_click(self, item):
        actions = {
            ${_py('$file/$open')}: self.open,
            ${_py('$file/$insert')}: self.insert_pdf,
            ${_py('$file/$save')}: self.save,
            ${_py('$file/$saveAs')}: lambda: self.save(ask=True),
            ${_py('$file/$extract')}: self.extract,
            ${_py('$file/$split')}: self.split,
            ${_py('$file/$quit')}: self.form_close,
            ${_py('$edit/$undo')}: self.undo,
            ${_py('$edit/$selectAll')}: self.select_all,
            ${_py('$edit/$rotLeft')}: self.BtnRotLeft_click,
            ${_py('$edit/$rotRight')}: self.BtnRotRight_click,
            ${_py('$edit/$up')}: self.BtnUp_click,
            ${_py('$edit/$down')}: self.BtnDown_click,
            ${_py('$edit/$duplicate')}: self.duplicate,
            ${_py('$edit/$delete')}: self.delete,
            ${_py('$doc/$stamp')}: self.add_stamp,
            ${_py('$doc/$password')}: self.set_password,
            ${_py('$help/$about')}: lambda: messagebox.showinfo(APP, ABOUT, parent=self.root),
        }
        action = actions.get(item)
        if action is not None:
            action()

    def form_close(self, *args):
        if self.keep_going():
            if self.loader is not None:
                self.root.after_cancel(self.loader)
            self.root.destroy()


def insert_label():
    return ${_py(t(markTr('Insertar páginas')))}


def delete_label():
    return ${_py(delete)}


def duplicate_label():
    return ${_py(duplicate)}
''';
  return TkExample(
    'pdf_editor',
    app,
    t(
      markTr(
        'Ordene, gire, elimine, duplique e inserte páginas de otro PDF; extraiga, divida, cambie las propiedades, añada sellos y proteja con contraseña. Con pypdf.',
      ),
    ),
    design,
    code,
  );
}
