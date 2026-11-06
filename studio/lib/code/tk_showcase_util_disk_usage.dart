part of 'tk_examples.dart';

// --------------------------------------------------------- espacio en disco
/// Espacio en disco, al estilo de WinDirStat: el uso del disco y el análisis
/// de una carpeta en un hilo aparte (con progreso y Cancelar), el árbol de
/// carpetas, un mapa de rectángulos por tamaño y tipo, los 100 archivos más
/// grandes y el total por tipo. Abre, muestra en la carpeta o mueve a la
/// Papelera lo elegido (nunca borra para siempre).
TkExample tkUtilDiskUsage(String Function(String) t) {
  final app = t(markTr('Espacio en disco'));
  final file = t(markTr('Archivo')), view = t(markTr('Ver'));
  final selection = t(markTr('Selección')), help = t(markTr('Ayuda'));
  final choose = t(markTr('Elegir la carpeta…'));
  final scan = t(markTr('Analizar')), cancel = t(markTr('Cancelar'));
  final quit = t(markTr('Salir'));
  final reveal = t(markTr('Mostrar en la carpeta'));
  final open = t(markTr('Abrir'));
  final trash = t(markTr('Mover a la Papelera…'));
  final folders = t(markTr('Carpetas'));
  final largest = t(markTr('Archivos más grandes'));
  final types = t(markTr('Por tipo'));
  final up = t(markTr('Subir un nivel'));
  final about = t(markTr('Acerca de'));
  final items = [
    file,
    '  $choose',
    '  $scan',
    '  $cancel',
    '  -',
    '  $quit',
    view,
    '  $folders',
    '  $largest',
    '  $types',
    '  -',
    '  $up',
    selection,
    '  $reveal',
    '  $open',
    '  -',
    '  $trash',
    help,
    '  $about',
  ].join('\n');
  final size = t(markTr('Tamaño')), share = t(markTr('Proporción'));
  final count = t(markTr('Archivos'));
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget button(String name, int x, int y, int w, String text) => _w(
    'Button',
    name,
    x,
    y,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final design =
      TkDesign(
          width: 1100,
          height: 720,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1052,
            96,
            32,
            32,
            {'items': items},
            {'command': 'Menu1_click'},
          ),
          _w('Label', 'LblDisk', 16, 8, 520, 26, _title(app, size: 15)),
          _w('Label', 'DiskInfo', 540, 10, 544, 22, {
            'text': '',
            'anchor': 'e',
          }),
          _w('Progressbar', 'DiskBar', 16, 38, 1068, 12, {'maximum': 100}),
          _w(
            'Label',
            'LblFolder',
            16,
            62,
            64,
            26,
            _label(t(markTr('Carpeta'))),
          ),
          _w('Entry', 'Folder', 80, 62, 440, 26, {}, {
            'enter_key': 'Folder_return',
          }),
          button('BtnChoose', 528, 59, 92, t(markTr('Elegir…'))),
          button('BtnScan', 628, 59, 100, scan),
          button('BtnCancel', 736, 59, 92, cancel),
          _w('Checkbutton', 'SameDisk', 840, 62, 180, 26, {
            'text': t(markTr('Solo este disco')),
          }),
          _w('Progressbar', 'ScanBar', 16, 104, 150, 10, {'maximum': 100}),
          _w('Label', 'ScanInfo', 176, 97, 908, 22, {
            ..._label(t(markTr('Elija una carpeta y pulse Analizar.'))),
            'fg': '#5f6672',
          }),
          // A la izquierda, las listas.
          _w('PageControl', 'Pages', 16, 126, 480, 514, {
            'pages': [folders, largest, types].join('\n'),
          }),
          on(
            _w(
              'Treeview',
              'Folders',
              8,
              32,
              460,
              470,
              {
                'columns': [
                  'size|$size|80',
                  'pct|%|64',
                  'files|$count|70',
                ].join('\n'),
              },
              {'select': 'Folders_select'},
            ),
            0,
          ),
          on(
            _w(
              'Treeview',
              'Largest',
              8,
              32,
              460,
              470,
              {
                'columns': [
                  'size|$size|72',
                  'name|${t(markTr('Nombre'))}|130',
                  'folder|${t(markTr('Carpeta'))}|110',
                  'modified|${t(markTr('Modificado'))}|104',
                ].join('\n'),
              },
              {'select': 'Largest_select', 'double': 'Largest_double'},
            ),
            1,
          ),
          on(
            _w('Treeview', 'Types', 8, 32, 460, 470, {
              'columns': [
                'ext|${t(markTr('Tipo'))}|90',
                'files|$count|66',
                'size|$size|80',
                'pct|%|64',
                'bar|$share|104',
              ].join('\n'),
            }),
            2,
          ),
          // A la derecha, el mapa.
          button('BtnUp', 508, 124, 100, '▲  ${t(markTr('Subir'))}'),
          _w('Label', 'Crumb', 616, 128, 468, 24, {
            ..._label(''),
            'fg': '#5f6672',
          }),
          _w('Canvas', 'Treemap', 508, 158, 576, 438, {'bg': '#1d2127'}),
          _w('Canvas', 'Legend', 508, 600, 576, 40, {'bg': _paper}),
          // Lo que se hace con lo elegido.
          button('BtnReveal', 16, 650, 176, reveal),
          button('BtnOpen', 200, 650, 96, open),
          button('BtnTrash', 304, 650, 192, trash),
          _w('Label', 'Hint', 508, 654, 576, 24, {
            ..._label(
              t(
                markTr(
                  'Clic: elegir   ·   Doble clic: entrar en la carpeta   ·   Clic derecho: acciones',
                ),
              ),
            ),
            'fg': '#5f6672',
          }),
          _w('StatusBar', 'Status', 0, 696, 1100, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import datetime
import heapq
import os
import queue
import shutil
import stat
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import filedialog, messagebox

APP = ${_py(app)}
WINDOWS = sys.platform.startswith("win")
# Separador decimal del idioma (el de miles es el otro).
DECIMAL = ${_py(t(markTr(',')))}
THOUSANDS = "." if DECIMAL == "," else ","
# El Finder cuenta en miles; Windows, en 1024.
BASE = 1000 if sys.platform == "darwin" else 1024
UNITS = ("B", "KB", "MB", "GB", "TB", "PB")
TOP = 100
MAX_CHILDREN = 300
MIN_AREA = 12      # px²: lo más pequeño se junta en un solo bloque gris.
MAX_ITEMS = 5000   # Dibujos del mapa como máximo (para que vaya rápido).

DISK_TITLE = ${_py(t(markTr('Disco de «{0}»')))}
DISK_INFO = ${_py(t(markTr('{0} en total   ·   {1} usados ({2})   ·   {3} libres')))}
NOT_FOLDER = ${_py(t(markTr('«{0}» no es una carpeta.')))}
CHOOSE = ${_py(t(markTr('Elija la carpeta que quiere analizar')))}
SCANNING = ${_py(t(markTr('Analizando «{0}»…')))}
PROGRESS = ${_py(t(markTr('{0} archivos   ·   {1}   ·   {2}')))}
DONE = ${_py(t(markTr('{0} archivos   ·   {1}   ·   {2} carpetas   ·   {3} s')))}
CANCELLING = ${_py(t(markTr('Cancelando…')))}
CANCELLED = ${_py(t(markTr('Análisis cancelado: los datos están incompletos.')))}
FINISHED = ${_py(t(markTr('Análisis terminado.')))}
SKIP_DENIED = ${_py(t(markTr('{0} sin permiso de lectura')))}
SKIP_LINKS = ${_py(t(markTr('{0} enlaces sin seguir')))}
SKIP_DISKS = ${_py(t(markTr('{0} carpetas de otros discos')))}
FAILED = ${_py(t(markTr('No se pudo analizar: {0}')))}
FILES_HERE = ${_py(t(markTr('[{0} archivos en esta carpeta]')))}
MORE = ${_py(t(markTr('… y {0} carpetas más')))}
DENIED = ${_py(t(markTr(' (sin permiso)')))}
NO_EXT = ${_py(t(markTr('(sin extensión)')))}
PICK_FIRST = ${_py(t(markTr('Elija primero un archivo o una carpeta de la lista.')))}
REVEALED = ${_py(t(markTr('Mostrando: {0}')))}
SELECTED = ${_py(t(markTr('{0}   ·   {1}')))}
MAP_EMPTY = ${_py(t(markTr('Aquí verá el mapa de lo que ocupa la carpeta.')))}
ASK_TRASH = ${_py(t(markTr('¿Mover «{0}» ({1}) a la Papelera?')))}
PROTECTED = ${_py(t(markTr('Por seguridad no se mueve a la Papelera la carpeta analizada, la carpeta personal ni la raíz de un disco: {0}')))}
CANT_TRASH = ${_py(t(markTr('No se pudo mover a la Papelera: {0}')))}
FREED = ${_py(t(markTr('En la Papelera: {0}   ·   {1} liberados (al vaciarla)')))}
BUSY = ${_py(t(markTr('Espere a que termine el análisis.')))}
FOLDER_COLUMN = ${_py(folders)}
REVEAL, OPEN, TRASH = ${_py(reveal)}, ${_py(open)}, ${_py(trash)}
ABOUT = ${_py(t(markTr('Espacio en disco, ejemplo de DMarlon Studio al estilo de WinDirStat: analiza una carpeta en segundo plano sin seguir enlaces ni contar dos veces el mismo archivo y dibuja un mapa de lo que ocupa. Solo mueve a la Papelera lo que usted confirme; nunca borra para siempre.')))}

# Familias de archivos del mapa: (clave, nombre, color, extensiones).
FAMILIES = [
    ("images", ${_py(t(markTr('Imágenes')))}, "#e9b949", "jpg jpeg png gif bmp tif tiff heic heif webp svg raw cr2 nef arw dng psd ico"),
    ("video", ${_py(t(markTr('Vídeo')))}, "#e05a6d", "mp4 mov avi mkv wmv m4v webm flv mpg mpeg 3gp mts"),
    ("audio", ${_py(t(markTr('Audio')))}, "#a77bdb", "mp3 wav flac aac m4a ogg aif aiff wma opus mid"),
    ("docs", ${_py(t(markTr('Documentos')))}, "#4f8fe6", "pdf doc docx xls xlsx ppt pptx odt ods odp txt rtf md csv pages numbers key epub tex"),
    ("archives", ${_py(t(markTr('Comprimidos')))}, "#f08c45", "zip rar 7z tar gz tgz bz2 xz zst dmg iso pkg cab"),
    ("code", ${_py(t(markTr('Código')))}, "#4cb38f", "py js ts jsx tsx java c cc cpp h hpp cs go rs rb php html css scss json xml yml yaml toml sh bat ps1 dart swift kt sql ipynb lua"),
    ("apps", ${_py(t(markTr('Programas')))}, "#6d8fb3", "exe dll app so dylib msi bin jar apk class o a lib sys deb rpm appimage"),
    ("other", ${_py(t(markTr('Otros')))}, "#9aa0a6", ""),
]
FAMILY_OF = {"." + ext: key for key, _, _, exts in FAMILIES for ext in exts.split()}
FOLDER_FILL, FOLDER_LINE, REST_FILL = "#2b3038", "#15181c", "#5c6370"


def family(name):
    return FAMILY_OF.get(os.path.splitext(name)[1].lower(), "other")


def shade(color, factor):
    """color más oscuro (factor < 1) o más claro (factor > 1)."""
    rgb = [int(color[i:i + 2], 16) for i in (1, 3, 5)]
    if factor > 1:
        rgb = [int(c + (255 - c) * (factor - 1)) for c in rgb]
    else:
        rgb = [int(c * factor) for c in rgb]
    return "#%02x%02x%02x" % tuple(max(0, min(255, c)) for c in rgb)


# Relleno, borde y brillo de cada familia (el brillo da el relieve).
PALETTE = {key: (color, shade(color, 0.6), shade(color, 1.45), shade(color, 0.75))
           for key, _, color, _ in FAMILIES}


# ------------------------------------------------------------- formatos
def fmt_int(number):
    return "{:,}".format(int(number)).replace(",", THOUSANDS)


def fmt_size(size):
    value, unit = float(size), 0
    while value >= BASE and unit < len(UNITS) - 1:
        value /= BASE
        unit += 1
    if unit == 0:
        return "%d %s" % (value, UNITS[0])
    text = "%.1f" % value if value < 100 else "%.0f" % value
    return text.replace(".", DECIMAL) + " " + UNITS[unit]


def fmt_pct(part, total):
    value = part * 100.0 / total if total else 0.0
    return ("%.1f" % value).replace(".", DECIMAL) + " %"


def bar(part, total, width=12):
    """Barra de texto: un bloque por cada 1/width del total."""
    filled = int(round(width * part / total)) if total else 0
    return "█" * filled if filled else ("▏" if part else "")


def fmt_date(seconds):
    if not seconds:
        return ""
    try:
        return datetime.datetime.fromtimestamp(seconds).strftime("%Y-%m-%d %H:%M")
    except (OverflowError, OSError, ValueError):
        return ""


def short(path, size=80):
    return path if len(path) <= size else "…" + path[-(size - 1):]


# -------------------------------------------------------------- análisis
class Folder:
    __slots__ = ("name", "path", "parent", "children", "filelist", "size", "files", "own", "own_files", "denied")

    def __init__(self, name, path, parent):
        self.name, self.path, self.parent = name, path, parent
        self.children = []
        self.filelist = []   # [(tamaño, nombre)] de los archivos de esta carpeta.
        self.size = self.files = self.own = self.own_files = 0
        self.denied = False


class Result:
    def __init__(self, path):
        self.path = path
        self.root = Folder(os.path.basename(path.rstrip("/" + os.sep)) or path, path, None)
        self.folders = 1
        self.files = self.bytes = 0
        self.errors = self.links = self.hardlinks = self.other_disks = 0
        self.types = {}      # extensión: [archivos, bytes]
        self.largest = []    # [(tamaño, ruta, modificado, carpeta, nombre)], de mayor a menor
        self.cancelled = False
        self.seconds = 0.0


def same_disk_devices(root_dev):
    """Los dispositivos que cuentan como «este disco». En macOS el sistema y
    los datos son dos volúmenes del mismo disco (/Users está en el segundo)."""
    devices = {root_dev}
    if sys.platform == "darwin":
        try:
            pair = {os.stat("/").st_dev, os.stat("/System/Volumes/Data").st_dev}
            if root_dev in pair:
                devices |= pair
        except OSError:
            pass
    return devices


def scan(path, cancel=None, progress=None, same_disk=True):
    """Recorre path sin seguir enlaces simbólicos ni uniones y sin contar dos
    veces un archivo con enlaces duros. Se puede llamar desde otro hilo:
    progress(archivos, bytes, carpeta) avisa cada décima de segundo y
    cancel (un threading.Event) lo detiene."""
    result = Result(path)
    try:
        info = os.stat(path)
    except OSError:
        result.errors += 1
        return result
    devices = same_disk_devices(info.st_dev)
    seen_folders = {(info.st_dev, info.st_ino)}
    seen_files = set()
    folders = [result.root]
    stack = [result.root]
    largest = []
    counter = 0
    last = None
    while stack:
        if cancel is not None and cancel.is_set():
            result.cancelled = True
            break
        folder = stack.pop()
        try:
            with os.scandir(folder.path) as found:
                entries = list(found)
        except OSError:
            folder.denied = True
            result.errors += 1
            continue
        for entry in entries:
            try:
                if entry.is_symlink():
                    result.links += 1
                    continue
                if entry.is_dir(follow_symlinks=False):
                    # En Windows, DirEntry.stat() no trae el dispositivo ni el inodo.
                    info = os.stat(entry.path, follow_symlinks=False) if WINDOWS else entry.stat(follow_symlinks=False)
                    if getattr(info, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0):
                        result.links += 1  # Unión o punto de montaje de Windows.
                        continue
                    if same_disk and info.st_dev not in devices:
                        result.other_disks += 1
                        continue
                    key = (info.st_dev, info.st_ino)
                    if info.st_ino and key in seen_folders:
                        continue  # La misma carpeta por otro camino.
                    seen_folders.add(key)
                    child = Folder(entry.name, entry.path, folder)
                    folder.children.append(child)
                    folders.append(child)
                    stack.append(child)
                elif entry.is_file(follow_symlinks=False):
                    info = entry.stat(follow_symlinks=False)
                    if info.st_nlink > 1:
                        key = (info.st_dev, info.st_ino)
                        if key in seen_files:
                            result.hardlinks += 1
                            continue
                        seen_files.add(key)
                    size = info.st_size
                    folder.filelist.append((size, entry.name))
                    folder.own += size
                    folder.own_files += 1
                    result.files += 1
                    result.bytes += size
                    ext = os.path.splitext(entry.name)[1].lower()
                    kind = result.types.setdefault(ext, [0, 0])
                    kind[0] += 1
                    kind[1] += size
                    counter += 1
                    item = (size, counter, entry.path, info.st_mtime, folder, entry.name)
                    if len(largest) < TOP:
                        heapq.heappush(largest, item)
                    elif size > largest[0][0]:
                        heapq.heapreplace(largest, item)
            except OSError:
                result.errors += 1
        now = time.monotonic()
        if progress is not None and (last is None or now - last >= 0.1):
            last = now
            progress(result.files, result.bytes, folder.path)
    # Tamaños de abajo arriba: cada carpeta suma las suyas a la de arriba.
    for folder in reversed(folders):
        folder.size += folder.own
        folder.files += folder.own_files
        if folder.parent is not None:
            folder.parent.size += folder.size
            folder.parent.files += folder.files
    for folder in folders:
        folder.children.sort(key=lambda child: child.size, reverse=True)
    result.folders = len(folders)
    largest.sort(key=lambda item: (item[0], item[1]), reverse=True)
    result.largest = [(size, path, modified, folder, name) for size, _, path, modified, folder, name in largest]
    return result


# ------------------------------------------- lo elegido: carpeta o archivo
# Un elemento es una Folder o un archivo (carpeta, nombre, tamaño).
def node_folder(node):
    return node if isinstance(node, Folder) else node[0]


def node_path(node):
    return node.path if isinstance(node, Folder) else os.path.join(node[0].path, node[1])


def node_size(node):
    return node.size if isinstance(node, Folder) else node[2]


def node_key(node):
    return id(node) if isinstance(node, Folder) else (id(node[0]), node[1])


def contains(folder, node):
    """True si node es folder o está dentro de ella."""
    current = node_folder(node)
    while current is not None:
        if current is folder:
            return True
        current = current.parent
    return False


def walk(folder):
    stack = [folder]
    while stack:
        current = stack.pop()
        yield current
        stack.extend(current.children)


def top_files(root):
    """Los TOP archivos más grandes del árbol (tras quitar alguno)."""
    found = heapq.nlargest(
        TOP, ((size, folder, name) for folder in walk(root) for size, name in folder.filelist),
        key=lambda item: item[0])
    out = []
    for size, folder, name in found:
        path = os.path.join(folder.path, name)
        try:
            modified = os.stat(path, follow_symlinks=False).st_mtime
        except OSError:
            modified = 0
        out.append((size, path, modified, folder, name))
    return out


def drop_type(result, name, size):
    ext = os.path.splitext(name)[1].lower()
    kind = result.types.get(ext)
    if kind is not None:
        kind[0] -= 1
        kind[1] -= size
        if kind[0] <= 0:
            del result.types[ext]


def remove_node(result, node):
    """Quita node de los resultados (ya está en la Papelera) y descuenta su
    tamaño de las carpetas de arriba, los totales, los tipos y la lista de
    los más grandes, sin volver a analizar. Devuelve los bytes liberados."""
    path = node_path(node)
    if isinstance(node, Folder):
        node.parent.children.remove(node)
        size, files = node.size, node.files
        gone = list(walk(node))
        for folder in gone:
            for file_size, name in folder.filelist:
                drop_type(result, name, file_size)
        result.folders -= len(gone)
        above = node.parent
    else:
        folder, name, size = node
        folder.filelist.remove((size, name))
        folder.own -= size
        folder.own_files -= 1
        drop_type(result, name, size)
        files = 1
        above = folder
    while above is not None:
        above.size -= size
        above.files -= files
        if above.parent is not None:
            above.parent.children.sort(key=lambda child: child.size, reverse=True)
        above = above.parent
    result.bytes -= size
    result.files -= files
    before = len(result.largest)
    inside = path + os.sep
    result.largest = [item for item in result.largest if item[1] != path and not item[1].startswith(inside)]
    if len(result.largest) < before and before >= TOP:
        result.largest = top_files(result.root)
    return size


def protected(path, root):
    """La carpeta analizada, la personal (o una que la contenga) y la raíz
    de un disco nunca van a la Papelera."""
    path = os.path.normcase(os.path.abspath(path))
    if path == os.path.normcase(os.path.abspath(root)):
        return True
    home = os.path.normcase(os.path.abspath(os.path.expanduser("~")))
    try:
        if os.path.commonpath([path, home]) == path:
            return True
    except ValueError:
        pass  # Otra unidad de Windows.
    return os.path.dirname(path) == path or os.path.ismount(path)


# ---------------------------------------------------------------- sistema
def reveal(path):
    """Abre el Finder o el Explorador con path elegido."""
    if sys.platform == "darwin":
        subprocess.Popen(["open", "-R", path])
    elif WINDOWS:
        subprocess.Popen('explorer /select,"%s"' % os.path.normpath(path))
    else:
        subprocess.Popen(["xdg-open", path if os.path.isdir(path) else os.path.dirname(path)])


def open_path(path):
    """Abre el archivo con su programa (o la carpeta)."""
    if sys.platform == "darwin":
        subprocess.Popen(["open", path])
    elif WINDOWS:
        os.startfile(path)
    else:
        subprocess.Popen(["xdg-open", path])


def move_to_trash(path):
    """Mueve path a la Papelera del sistema (se puede recuperar). Nunca borra
    para siempre: si no hay Papelera, lanza OSError y no toca nada."""
    path = os.path.abspath(path)
    if sys.platform == "darwin":
        slash = chr(92)
        quoted = path.replace(slash, slash + slash).replace('"', slash + '"')
        script = 'tell application "Finder" to delete POSIX file "%s"' % quoted
        done = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
        if done.returncode != 0:
            raise OSError(done.stderr.strip() or "osascript")
    elif WINDOWS:
        import ctypes
        from ctypes import wintypes

        class SHFILEOPSTRUCTW(ctypes.Structure):
            _fields_ = [
                ("hwnd", wintypes.HWND), ("wFunc", wintypes.UINT),
                ("pFrom", wintypes.LPCWSTR), ("pTo", wintypes.LPCWSTR),
                ("fFlags", ctypes.c_ushort), ("fAnyOperationsAborted", wintypes.BOOL),
                ("hNameMappings", ctypes.c_void_p), ("lpszProgressTitle", wintypes.LPCWSTR),
            ]

        FO_DELETE, FOF_SILENT, FOF_NOCONFIRMATION, FOF_ALLOWUNDO, FOF_NOERRORUI = 3, 0x4, 0x10, 0x40, 0x400
        operation = SHFILEOPSTRUCTW(
            None, FO_DELETE, path + chr(0), None,
            FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT | FOF_NOERRORUI, False, None, None)
        code = ctypes.windll.shell32.SHFileOperationW(ctypes.byref(operation))
        if code != 0 or operation.fAnyOperationsAborted:
            raise OSError("SHFileOperationW: %d" % code)
    else:
        done = subprocess.run(["gio", "trash", path], capture_output=True, text=True)
        if done.returncode != 0:
            raise OSError(done.stderr.strip() or "gio trash")


# ------------------------------------------------------------------ mapa
def squarify(sizes, x, y, width, height):
    """Rectángulos (x, y, ancho, alto) que reparten el área en proporción a
    sizes (mejor de mayor a menor), lo más cuadrados posible."""
    total = float(sum(sizes))
    if total <= 0 or width <= 0 or height <= 0:
        return [(x, y, 0.0, 0.0) for _ in sizes]
    scale = width * height / total
    areas = [size * scale for size in sizes]
    rects = []

    def worst(row, side):
        s = sum(row)
        if s <= 0 or min(row) <= 0:
            return float("inf")
        return max(side * side * max(row) / (s * s), s * s / (side * side * min(row)))

    i = 0
    while i < len(areas):
        side = min(width, height)
        row = [areas[i]]
        i += 1
        while i < len(areas) and areas[i] > 0 and worst(row + [areas[i]], side) <= worst(row, side):
            row.append(areas[i])
            i += 1
        row_sum = sum(row)
        if width >= height:   # Una columna a la izquierda.
            column = row_sum / height if height > 0 else 0.0
            top = y
            for area in row:
                h = area / column if column > 0 else 0.0
                rects.append((x, top, column, h))
                top += h
            x += column
            width = max(0.0, width - column)
        else:                 # Una fila arriba.
            line = row_sum / width if width > 0 else 0.0
            left = x
            for area in row:
                w = area / line if line > 0 else 0.0
                rects.append((left, y, w, line))
                left += w
            y += line
            height = max(0.0, height - line)
    return rects


class Form1(FormDesign):
    def form_create(self):
        self.queue = queue.Queue()
        self.worker = None
        self.cancel = None
        self.result = None
        self.poller = None
        self.redraw_job = None
        self.nodes, self.iids = {}, {}
        self.files, self.file_iids = {}, {}
        self.zoom = None
        self.current = None
        self.hits, self.drawn = {}, {}
        self.quiet_tree = self.quiet_largest = None
        self.message = ("", "info")
        self.SameDisk_var.set(1)
        self.Folder_var.set(os.path.expanduser("~"))
        # Cada lista llena su página (el margen de las pestañas cambia con el sistema).
        for tree, scroll in ((self.Folders, self.Folders_scroll), (self.Largest, self.Largest_scroll),
                             (self.Types, self.Types_scroll)):
            tree.place_configure(x=0, y=0, width=-16, height=0, relwidth=1.0, relheight=1.0)
            scroll.place_configure(x=-16, y=0, width=16, height=0, relx=1.0, relheight=1.0)
        self.Folders.configure(show="tree headings", selectmode="browse")
        self.Largest.configure(selectmode="browse")
        self.Folders.heading("#0", text=FOLDER_COLUMN, anchor="w")
        self.Folders.column("#0", width=190)
        for tree, columns in ((self.Folders, ("size", "pct", "files")),
                              (self.Largest, ("size",)),
                              (self.Types, ("files", "size", "pct"))):
            for column in columns:
                tree.column(column, anchor="e")
        self.Folders.tag_configure("note", foreground="#7a7f87")
        self.Folders.bind("<<TreeviewOpen>>", self.Folders_open)
        # El mapa: pasar por encima, clic, doble clic y tamaño.
        self.Treemap.configure(highlightthickness=0, cursor="hand2")
        self.Treemap.bind("<Motion>", self.Treemap_motion)
        self.Treemap.bind("<Leave>", self.Treemap_leave)
        self.Treemap.bind("<Button-1>", self.Treemap_click)
        self.Treemap.bind("<Double-Button-1>", self.Treemap_double)
        self.Treemap.bind("<Configure>", self.Treemap_resize)
        # Menú contextual (clic derecho; en el Mac también Ctrl+clic).
        self.menu = tk.Menu(self.root, tearoff=0)
        self.menu.add_command(label=REVEAL, command=self.reveal_selected)
        self.menu.add_command(label=OPEN, command=self.open_selected)
        self.menu.add_separator()
        self.menu.add_command(label=TRASH, command=self.trash_selected)
        clicks = ["<Button-3>"] + (["<Button-2>", "<Control-Button-1>"] if sys.platform == "darwin" else [])
        for widget in (self.Folders, self.Largest, self.Treemap):
            for sequence in clicks:
                widget.bind(sequence, self.popup)
            widget.bind("<Delete>", lambda event: self.trash_selected())
        self.BtnCancel.configure(state="disabled")
        self.BtnUp.configure(state="disabled")
        self.show_disk(self.Folder_var.get())
        self.draw_treemap()
        self.draw_legend()

    def say(self, text, icon="info"):
        self.message = (text, icon)
        self.Status.set(text, icon=icon)

    # --------------------------------------------------------------- disco
    def show_disk(self, path):
        try:
            usage = shutil.disk_usage(path)
        except OSError:
            return
        self.LblDisk.configure(text=DISK_TITLE.format(short(path, 40)))
        self.DiskBar.configure(value=usage.used * 100.0 / usage.total if usage.total else 0)
        self.DiskInfo.configure(text=DISK_INFO.format(
            fmt_size(usage.total), fmt_size(usage.used), fmt_pct(usage.used, usage.total), fmt_size(usage.free)))

    # ------------------------------------------------------------ análisis
    def scanning(self):
        return self.worker is not None

    def choose(self):
        folder = filedialog.askdirectory(parent=self.root, title=CHOOSE, initialdir=self.Folder_var.get())
        if folder:
            self.Folder_var.set(os.path.normpath(folder))
            self.start_scan()

    def start_scan(self):
        if self.scanning():
            return
        path = os.path.abspath(os.path.expanduser(self.Folder_var.get().strip() or "~"))
        if not os.path.isdir(path):
            self.say(NOT_FOLDER.format(path), "⚠")
            return
        self.Folder_var.set(path)
        self.show_disk(path)
        self.result, self.zoom, self.current = None, None, None
        self.fill_all()
        messages = self.queue = queue.Queue()
        cancel = self.cancel = threading.Event()
        same = bool(self.SameDisk_var.get())

        def work():
            started = time.monotonic()
            try:
                result = scan(path, cancel, lambda *args: messages.put(("progress",) + args), same)
            except Exception as error:  # Nunca deja la ventana esperando.
                messages.put(("error", error))
                return
            result.seconds = time.monotonic() - started
            messages.put(("done", result))

        self.worker = threading.Thread(target=work, daemon=True)
        self.worker.start()
        for widget in (self.BtnScan, self.BtnChoose, self.BtnTrash):
            widget.configure(state="disabled")
        self.BtnCancel.configure(state="normal")
        self.ScanBar.configure(mode="indeterminate")
        self.ScanBar.start(15)
        self.ScanInfo.configure(text=SCANNING.format(path))
        self.say(SCANNING.format(path), "find")
        self.poller = self.root.after(100, self.poll)

    def poll(self):
        """Lee lo que manda el hilo del análisis (tkinter, solo en este)."""
        self.poller = None
        latest = None
        try:
            while True:
                message = self.queue.get_nowait()
                if message[0] == "progress":
                    latest = message
                elif message[0] == "done":
                    return self.finish(message[1])
                else:
                    return self.finish(None, message[1])
        except queue.Empty:
            pass
        if latest is not None:
            _, files, size, folder = latest
            self.ScanInfo.configure(text=PROGRESS.format(fmt_int(files), fmt_size(size), short(folder)))
        if self.scanning():
            self.poller = self.root.after(100, self.poll)

    def stop_scan(self):
        if self.cancel is not None and self.scanning():
            self.cancel.set()
            self.BtnCancel.configure(state="disabled")
            self.say(CANCELLING)

    def finish(self, result, error=None):
        self.worker = None
        self.ScanBar.stop()
        self.ScanBar.configure(mode="determinate", value=100 if result and not result.cancelled else 0)
        for widget in (self.BtnScan, self.BtnChoose, self.BtnTrash):
            widget.configure(state="normal")
        self.BtnCancel.configure(state="disabled")
        if result is None:
            self.ScanInfo.configure(text="")
            self.say(FAILED.format(error), "⚠")
            return
        self.result = result
        self.zoom = result.root
        self.fill_all()
        text = CANCELLED if result.cancelled else FINISHED
        skipped = [message.format(fmt_int(count)) for message, count in (
            (SKIP_DENIED, result.errors), (SKIP_LINKS, result.links), (SKIP_DISKS, result.other_disks)) if count]
        if skipped:
            text += "   " + "   ·   ".join(skipped)
        self.say(text, "⚠" if result.cancelled else "check")

    def show_totals(self):
        result = self.result
        self.ScanInfo.configure(text=DONE.format(
            fmt_int(result.files), fmt_size(result.bytes), fmt_int(result.folders),
            ("%.1f" % result.seconds).replace(".", DECIMAL)))

    # ------------------------------------------------------------- listas
    def fill_all(self):
        for tree in (self.Folders, self.Largest, self.Types):
            tree.delete(*tree.get_children())
        self.nodes, self.iids, self.files, self.file_iids = {}, {}, {}, {}
        if self.result is not None:
            self.fill_folders()
            self.fill_largest()
            self.fill_types()
            self.show_totals()
        self.update_crumb()
        self.draw_treemap()
        self.draw_legend()

    def folder_values(self, size, files):
        return (fmt_size(size), fmt_pct(size, self.result.bytes), fmt_int(files))

    def fill_folders(self):
        root = self.result.root
        self.nodes["f0"] = root
        self.iids[id(root)] = "f0"
        self.Folders.insert("", "end", iid="f0", text=root.path, open=True,
                            values=self.folder_values(root.size, root.files))
        self.add_children("f0", root)

    def add_children(self, iid, folder):
        rows = [(child.size, child) for child in folder.children[:MAX_CHILDREN]]
        if folder.own_files:
            rows.append((folder.own, None))
        rows.sort(key=lambda row: row[0], reverse=True)
        for size, child in rows:
            if child is None:
                note = "%s~files" % iid
                self.nodes[note] = folder
                self.Folders.insert(iid, "end", iid=note, text=FILES_HERE.format(fmt_int(folder.own_files)),
                                    values=self.folder_values(folder.own, folder.own_files), tags=("note",))
                continue
            cid = "f%d" % len(self.nodes)
            self.nodes[cid] = child
            self.iids[id(child)] = cid
            name = child.name + (DENIED if child.denied else "")
            self.Folders.insert(iid, "end", iid=cid, text=name, values=self.folder_values(child.size, child.files))
            if child.children or child.own_files:
                self.Folders.insert(cid, "end", iid=cid + "~more", text="…")
        hidden = len(folder.children) - MAX_CHILDREN
        if hidden > 0:
            self.Folders.insert(iid, "end", iid=iid + "~hidden", text=MORE.format(fmt_int(hidden)), tags=("note",))

    def expand(self, iid):
        placeholder = iid + "~more"
        if self.Folders.exists(placeholder):
            self.Folders.delete(placeholder)
            self.add_children(iid, self.nodes[iid])

    def Folders_open(self, event=None):
        self.expand(self.Folders.focus())

    def ensure_row(self, folder):
        """La fila de folder en el árbol (abriendo las de arriba), o la más
        cercana que haya."""
        if id(folder) in self.iids:
            return self.iids[id(folder)]
        if folder.parent is None:
            return None
        above = self.ensure_row(folder.parent)
        if above is None:
            return None
        self.expand(above)
        self.Folders.item(above, open=True)
        return self.iids.get(id(folder), above)

    def fill_largest(self):
        for index, item in enumerate(self.result.largest):
            size, path, modified = item[:3]
            iid = "l%d" % index
            self.files[iid] = item
            self.file_iids[path] = iid
            folder, name = os.path.split(path)
            self.Largest.insert("", "end", iid=iid, values=(fmt_size(size), name, folder, fmt_date(modified)))

    def fill_types(self):
        total = self.result.bytes
        kinds = sorted(self.result.types.items(), key=lambda item: item[1][1], reverse=True)
        for ext, (files, size) in kinds:
            self.Types.insert("", "end", values=(
                ext or NO_EXT, fmt_int(files), fmt_size(size), fmt_pct(size, total), bar(size, total)))

    # ---------------------------------------------------------- selección
    def select(self, node, source=""):
        """Elige node y lo muestra en el árbol, la lista y el mapa."""
        self.current = node
        if self.zoom is not None and not contains(self.zoom, node):
            self.zoom = self.result.root
            self.update_crumb()
            self.draw_treemap()
        else:
            self.highlight()
        if source != "tree":
            iid = self.ensure_row(node_folder(node))
            if iid is not None and self.Folders.selection() != (iid,):
                self.quiet_tree = iid
                self.Folders.selection_set(iid)
            if iid is not None:
                self.Folders.see(iid)
                self.Folders.focus(iid)
        if source != "largest":
            iid = None if isinstance(node, Folder) else self.file_iids.get(node_path(node))
            if iid is not None:
                if self.Largest.selection() != (iid,):
                    self.quiet_largest = iid
                    self.Largest.selection_set(iid)
                self.Largest.see(iid)
            elif self.Largest.selection():
                self.Largest.selection_remove(*self.Largest.selection())
        self.say(SELECTED.format(node_path(node), fmt_size(node_size(node))))

    def Folders_select(self, event=None):
        chosen = self.Folders.selection()
        if not chosen:
            return
        if chosen[0] == self.quiet_tree:
            self.quiet_tree = None
            return
        self.quiet_tree = None
        node = self.nodes.get(chosen[0])
        if node is not None:
            self.select(node, "tree")

    def Largest_select(self, event=None):
        chosen = self.Largest.selection()
        if not chosen:
            return
        if chosen[0] == self.quiet_largest:
            self.quiet_largest = None
            return
        self.quiet_largest = None
        item = self.files.get(chosen[0])
        if item is not None:
            size, path, modified, folder, name = item
            self.select((folder, name, size), "largest")

    def Largest_double(self, event=None):
        self.root.after_idle(self.reveal_selected)

    # ---------------------------------------------------------------- mapa
    def canvas_size(self, canvas):
        width, height = canvas.winfo_width(), canvas.winfo_height()
        if width <= 1 or height <= 1:  # Aún sin mostrar: el tamaño del diseño.
            info = canvas.place_info()
            width, height = int(float(info.get("width") or 1)), int(float(info.get("height") or 1))
        return width, height

    def Treemap_resize(self, event=None):
        # Se redibuja cuando el tamaño deja de cambiar.
        if self.redraw_job is not None:
            self.root.after_cancel(self.redraw_job)
        self.redraw_job = self.root.after(150, self.draw_treemap)

    def draw_treemap(self):
        self.redraw_job = None
        canvas = self.Treemap
        canvas.delete("all")
        self.hits, self.drawn = {}, {}
        width, height = self.canvas_size(canvas)
        if self.result is None or self.zoom is None or self.zoom.size <= 0:
            canvas.create_text(width / 2, height / 2, text=MAP_EMPTY, fill="#9aa0a6")
            return
        self.budget = MAX_ITEMS
        self.draw_folder(self.zoom, 0, 0, width, height, 0)
        self.highlight()

    def box(self, x, y, w, h):
        return int(round(x)), int(round(y)), int(round(x + w)) - 1, int(round(y + h)) - 1

    def draw_folder(self, folder, x, y, w, h, depth):
        canvas = self.Treemap
        x0, y0, x1, y1 = self.box(x, y, w, h)
        self.drawn[id(folder)] = (x0, y0, x1, y1)
        self.budget -= 1
        if w < 6 or h < 6 or self.budget <= 0:
            item = canvas.create_rectangle(x0, y0, x1, y1, fill=REST_FILL, outline=FOLDER_LINE)
            self.hits[item] = folder
            return
        item = canvas.create_rectangle(x0, y0, x1, y1, fill=FOLDER_FILL, outline=FOLDER_LINE)
        self.hits[item] = folder
        top = 1
        if 0 < depth <= 3 and w >= 80 and h >= 44:
            # Las carpetas grandes llevan su nombre arriba.
            label = folder.name if len(folder.name) * 7 < w - 8 else folder.name[:max(1, int((w - 8) / 7) - 1)] + "…"
            text = canvas.create_text(x0 + 4, y0 + 1, text=label, anchor="nw", fill="#d7dbe0", font=("Helvetica", 9))
            self.hits[text] = folder
            top = 14
        self.draw_items(folder, x + 1, y + top, w - 2, h - top - 1, depth)

    def draw_items(self, folder, x, y, w, h, depth):
        if w < 1 or h < 1 or folder.size <= 0:
            return
        scale = w * h / float(folder.size)
        items = [(child.size, child) for child in folder.children if child.size > 0]
        items += [(size, (folder, name, size)) for size, name in folder.filelist if size > 0]
        items.sort(key=lambda item: item[0], reverse=True)
        keep, rest = [], 0
        for size, node in items:
            if size * scale >= MIN_AREA and len(keep) < 600:
                keep.append((size, node))
            else:
                rest += size  # Lo diminuto, junto en un bloque.
        rects = squarify([size for size, _ in keep] + ([rest] if rest else []), x, y, w, h)
        for (size, node), rect in zip(keep, rects):
            if self.budget <= 0:
                return
            if isinstance(node, Folder):
                self.draw_folder(node, *(rect + (depth + 1,)))
            else:
                self.draw_file(node, *rect)
        if rest and self.budget > 0:
            x0, y0, x1, y1 = self.box(*rects[-1])
            item = self.Treemap.create_rectangle(x0, y0, x1, y1, fill=REST_FILL, outline=FOLDER_LINE)
            self.hits[item] = folder

    def draw_file(self, node, x, y, w, h):
        canvas = self.Treemap
        fill, line, light, dark = PALETTE[family(node[1])]
        x0, y0, x1, y1 = self.box(x, y, w, h)
        self.drawn[node_key(node)] = (x0, y0, x1, y1)
        item = canvas.create_rectangle(x0, y0, x1, y1, fill=fill, outline=line)
        self.hits[item] = node
        self.budget -= 1
        if x1 - x0 >= 8 and y1 - y0 >= 8:
            # Relieve: borde claro arriba a la izquierda y oscuro abajo a la derecha.
            glow = canvas.create_line(x0 + 1, y1 - 1, x0 + 1, y0 + 1, x1 - 1, y0 + 1, fill=light, width=2)
            shadow = canvas.create_line(x0 + 2, y1 - 1, x1 - 1, y1 - 1, x1 - 1, y0 + 2, fill=dark, width=2)
            self.hits[glow] = self.hits[shadow] = node
            self.budget -= 2

    def highlight(self):
        """Marca en blanco lo elegido (o la carpeta dibujada que lo contiene)."""
        canvas = self.Treemap
        canvas.delete("selected")
        node = self.current
        if node is None:
            return
        rect = self.drawn.get(node_key(node))
        folder = node_folder(node) if rect is None else None
        while rect is None and folder is not None:
            rect = self.drawn.get(id(folder))
            folder = folder.parent
        if rect is not None:
            canvas.create_rectangle(*rect, outline="#ffffff", width=2, tags="selected")

    def hit(self, x, y):
        for item in reversed(self.Treemap.find_overlapping(x, y, x, y)):
            if item in self.hits:
                return self.hits[item]
        return None

    def Treemap_motion(self, event):
        node = self.hit(event.x, event.y)
        if node is not None:
            self.Status.set(SELECTED.format(node_path(node), fmt_size(node_size(node))), icon="find")

    def Treemap_leave(self, event=None):
        self.Status.set(self.message[0], icon=self.message[1])

    def Treemap_click(self, event):
        node = self.hit(event.x, event.y)
        if node is not None:
            self.select(node, "map")

    def Treemap_double(self, event):
        node = self.hit(event.x, event.y)
        if node is not None:
            self.zoom_to(node_folder(node))

    def zoom_to(self, folder):
        if self.result is None or folder is self.zoom:
            return
        self.zoom = folder
        self.update_crumb()
        self.draw_treemap()

    def zoom_up(self):
        if self.zoom is not None and self.zoom.parent is not None:
            self.zoom_to(self.zoom.parent)

    def update_crumb(self):
        if self.zoom is None:
            self.Crumb.configure(text="")
            self.BtnUp.configure(state="disabled")
            return
        self.Crumb.configure(text=SELECTED.format(short(self.zoom.path, 44), fmt_size(self.zoom.size)))
        self.BtnUp.configure(state="normal" if self.zoom.parent is not None else "disabled")

    def draw_legend(self):
        canvas = self.Legend
        canvas.delete("all")
        totals = {key: 0 for key, _, _, _ in FAMILIES}
        for ext, (_, size) in (self.result.types.items() if self.result else ()):
            totals[FAMILY_OF.get(ext, "other")] += size
        width, _ = self.canvas_size(canvas)
        column = width / 4.0
        for index, (key, name, color, _) in enumerate(FAMILIES):
            x = 2 + column * (index % 4)
            y = 3 + 19 * (index // 4)
            canvas.create_rectangle(x, y + 2, x + 12, y + 14, fill=color, outline=shade(color, 0.6))
            text = name + ("  " + fmt_size(totals[key]) if self.result else "")
            canvas.create_text(x + 18, y + 8, text=text, anchor="w", font=("Helvetica", 10), fill="#30343a")

    # ------------------------------------------------------------ acciones
    def chosen(self):
        if self.current is None:
            self.say(PICK_FIRST)
        return self.current

    def reveal_selected(self):
        node = self.chosen()
        if node is None:
            return
        try:
            reveal(node_path(node))
        except OSError as error:
            messagebox.showerror(APP, str(error), parent=self.root)
            return
        self.say(REVEALED.format(node_path(node)), "open")

    def open_selected(self):
        node = self.chosen()
        if node is None:
            return
        try:
            open_path(node_path(node))
        except OSError as error:
            messagebox.showerror(APP, str(error), parent=self.root)

    def trash_selected(self):
        if self.scanning():
            return self.say(BUSY)
        node = self.chosen()
        if node is None or self.result is None:
            return
        path = node_path(node)
        if protected(path, self.result.root.path):
            messagebox.showwarning(APP, PROTECTED.format(path), parent=self.root)
            return
        question = ASK_TRASH.format(os.path.basename(path), fmt_size(node_size(node)))
        if not messagebox.askyesno(APP, question, detail=path, icon="warning", parent=self.root):
            return
        try:
            move_to_trash(path)
        except Exception as error:
            messagebox.showerror(APP, CANT_TRASH.format(error), parent=self.root)
            return
        above = node.parent if isinstance(node, Folder) else node[0]
        if isinstance(node, Folder) and contains(node, self.zoom):
            self.zoom = above
        freed = remove_node(self.result, node)
        self.current = None
        self.fill_all()
        self.show_disk(self.result.root.path)
        self.select(above)
        self.say(FREED.format(os.path.basename(path), fmt_size(freed)), "delete")

    def popup(self, event):
        """Clic derecho: elige lo que hay debajo y abre el menú de acciones."""
        widget = event.widget
        if widget is self.Treemap:
            node = self.hit(event.x, event.y)
            if node is not None:
                self.select(node, "map")
        else:
            row = widget.identify_row(event.y)
            if row:
                widget.selection_set(row)
                if widget is self.Folders and row in self.nodes:
                    self.select(self.nodes[row], "tree")
                elif widget is self.Largest and row in self.files:
                    size, path, modified, folder, name = self.files[row]
                    self.select((folder, name, size), "largest")
        if self.current is None:
            return
        try:
            self.menu.tk_popup(event.x_root, event.y_root)
        finally:
            self.menu.grab_release()

    # ------------------------------------------------------------- eventos
    def BtnChoose_click(self):
        self.choose()

    def BtnScan_click(self):
        self.start_scan()

    def BtnCancel_click(self):
        self.stop_scan()

    def BtnUp_click(self):
        self.zoom_up()

    def BtnReveal_click(self):
        self.reveal_selected()

    def BtnOpen_click(self):
        self.open_selected()

    def BtnTrash_click(self):
        self.trash_selected()

    def Folder_return(self, event=None):
        self.start_scan()

    def Menu1_click(self, item):
        actions = {
            ${_py('$file/$choose')}: self.choose,
            ${_py('$file/$scan')}: self.start_scan,
            ${_py('$file/$cancel')}: self.stop_scan,
            ${_py('$file/$quit')}: self.form_close,
            ${_py('$view/$folders')}: lambda: self.Pages.select(0),
            ${_py('$view/$largest')}: lambda: self.Pages.select(1),
            ${_py('$view/$types')}: lambda: self.Pages.select(2),
            ${_py('$view/$up')}: self.zoom_up,
            ${_py('$selection/$reveal')}: self.reveal_selected,
            ${_py('$selection/$open')}: self.open_selected,
            ${_py('$selection/$trash')}: self.trash_selected,
            ${_py('$help/$about')}: lambda: messagebox.showinfo(APP, ABOUT, parent=self.root),
        }
        action = actions.get(item)
        if action is not None:
            action()

    def form_close(self, *args):
        if self.cancel is not None:
            self.cancel.set()
        for job in (self.poller, self.redraw_job):
            if job is not None:
                self.root.after_cancel(job)
        self.root.destroy()
''';
  return TkExample(
    'disk_usage',
    app,
    t(
      markTr(
        'Qué llena el disco, al estilo de WinDirStat: analiza una carpeta en segundo plano y la dibuja como un mapa por tamaño y tipo, con el árbol de carpetas, los archivos más grandes y la Papelera a mano.',
      ),
    ),
    design,
    code,
  );
}
