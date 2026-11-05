/// Informes en PDF y en Excel para las aplicaciones generadas (componentes
/// «Informe PDF» e «Informe Excel»): solo la biblioteca estándar de Python.
const tkReportsPython = r'''
# ---------------------------------------------------------------- informes
# Informes en PDF y en Excel con la biblioteca estándar de Python: no hace
# falta instalar nada en el equipo donde se ejecute la aplicación.
import datetime as _dt
import io as _io
import os as _os
import struct as _struct
import subprocess as _subprocess
import sys as _sys
import zipfile as _zipfile
import zlib as _zlib
from xml.sax.saxutils import escape as _xml_escape

# Anchos de Helvetica (por mil del cuerpo) de los caracteres 32 a 126.
_HELV = [
    278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
    1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
    667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
    333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
    556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
]
_HELV_BOLD = [
    278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611,
    975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778,
    667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556,
    333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611,
    611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584,
]


def _text_width(text, size, bold=False):
    table = _HELV_BOLD if bold else _HELV
    total = 0
    for ch in str(text):
        n = ord(ch)
        total += table[n - 32] if 32 <= n <= 126 else 556
    return total * size / 1000.0


def _pdf_string(text):
    raw = str(text).encode("cp1252", "replace")
    raw = raw.replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)")
    return b"(" + raw + b")"


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _cell_text(value):
    if value is None:
        return ""
    if isinstance(value, float):
        return ("%.2f" % value).replace(".", ",")
    if isinstance(value, _dt.datetime):
        return value.strftime("%d/%m/%Y %H:%M")
    if isinstance(value, _dt.date):
        return value.strftime("%d/%m/%Y")
    return str(value)


def _open_file(path):
    """Abre el archivo con la aplicación del sistema."""
    if _sys.platform.startswith("win"):
        _os.startfile(path)  # noqa: S606 - el archivo lo acaba de crear la app
    elif _sys.platform == "darwin":
        _subprocess.Popen(["open", path])
    else:
        _subprocess.Popen(["xdg-open", path])


class _ReportBase:
    extension = ""
    mime = "application/octet-stream"
    file_types = []

    def __init__(self, owner, web=False, filename=""):
        self._owner = owner
        self._web = web
        self.filename = filename or ("informe" + self.extension)
        self.path = None

    def to_bytes(self):
        raise NotImplementedError

    def save(self, path=None):
        """Guarda en path (o en el nombre por defecto) y devuelve la ruta."""
        path = path or self.filename
        if not _os.path.splitext(path)[1]:
            path += self.extension
        with open(path, "wb") as f:
            f.write(self.to_bytes())
        self.path = _os.path.abspath(path)
        return self.path

    def save_dialog(self, title=None):
        """Pregunta dónde guardar (en una página web, lo descarga)."""
        if self._web:
            return self.download()
        from tkinter import filedialog
        path = filedialog.asksaveasfilename(
            parent=self._owner,
            title=title or "",
            initialfile=_os.path.basename(self.filename),
            defaultextension=self.extension,
            filetypes=self.file_types + [("*", "*.*")],
        )
        return self.save(path) if path else None

    def download(self, name=None):
        """En una página web: envía el informe al navegador."""
        import base64
        name = name or _os.path.basename(self.filename)
        self._owner._downloads.append({
            "name": name,
            "data": base64.b64encode(self.to_bytes()).decode("ascii"),
            "type": self.mime,
        })
        return name

    def open(self, path=None):
        """Guarda (si hace falta) y abre el archivo con la aplicación del sistema."""
        if self._web:
            return self.download()
        target = path or self.path or self.save()
        _open_file(target)
        return target


class PdfReport(_ReportBase):
    """Informe en PDF: title, heading, text, table, image (JPEG), line,
    space y page_break van añadiendo contenido; save, save_dialog, open o
    download lo generan. Página A4 vertical u horizontal, con número de
    página al pie."""

    extension = ".pdf"
    mime = "application/pdf"
    file_types = [("PDF", "*.pdf")]

    def __init__(self, owner, web=False, filename="", title="", author="",
                 orientation="portrait", page_numbers=True, margin=50):
        super().__init__(owner, web, filename)
        self.doc_title = title
        self.author = author
        self.landscape = orientation == "landscape"
        self.page_numbers = page_numbers
        self.margin = margin
        self.clear()

    @property
    def width(self):
        return 842 if self.landscape else 595

    @property
    def height(self):
        return 595 if self.landscape else 842

    def clear(self):
        self._items = []
        return self

    # -------------------------------------------------------- contenido
    def title(self, text):
        self._items.append(("text", str(text), 20, True, 10))
        return self

    def heading(self, text):
        self._items.append(("text", str(text), 14, True, 6))
        return self

    def text(self, text, size=10, bold=False):
        for paragraph in str(text).split("\n"):
            self._items.append(("text", paragraph, size, bold, 4))
        return self

    def space(self, points=12):
        self._items.append(("space", points))
        return self

    def line(self):
        self._items.append(("line",))
        return self

    def page_break(self):
        self._items.append(("break",))
        return self

    def table(self, headers, rows, widths=None, totals=None):
        """headers: títulos; rows: filas (listas); widths: proporciones de
        las columnas; totals: una fila final en negrita."""
        rows = [list(r) for r in rows]
        if totals is not None:
            rows.append(("__total__", list(totals)))
        self._items.append(("table", list(headers), rows, widths))
        return self

    def image(self, path, width=None):
        """Una imagen JPEG (la anchura en puntos; por defecto, la de la página)."""
        self._items.append(("image", path, width))
        return self

    # -------------------------------------------------------- maquetación
    def _layout(self):
        pages, ops = [], []
        images = []
        left, right = self.margin, self.width - self.margin
        top, bottom = self.height - self.margin, self.margin + 24
        y = top

        def new_page():
            nonlocal ops, y
            pages.append(ops)
            ops = []
            y = top

        def text_at(x, yy, text, size, bold=False, gray=0.0):
            font = "/F2" if bold else "/F1"
            ops.append(b"BT %s %.1f Tf %.3f g %.2f %.2f Td %s Tj ET" % (
                font.encode(), size, gray, x, yy, _pdf_string(text)))

        def wrap(text, size, bold, width):
            words, lines, current = str(text).split(" "), [], ""
            for word in words:
                trial = word if not current else current + " " + word
                if _text_width(trial, size, bold) <= width or not current:
                    current = trial
                else:
                    lines.append(current)
                    current = word
            lines.append(current)
            return lines

        for item in self._items:
            kind = item[0]
            if kind == "text":
                _, text, size, bold, after = item
                for line in wrap(text, size, bold, right - left):
                    if y - size * 1.3 < bottom:
                        new_page()
                    y -= size * 1.3
                    text_at(left, y, line, size, bold)
                y -= after
            elif kind == "space":
                y -= item[1]
            elif kind == "line":
                y -= 6
                ops.append(b"0.75 G 0.8 w %.2f %.2f m %.2f %.2f l S" % (left, y, right, y))
                y -= 6
            elif kind == "break":
                new_page()
            elif kind == "image":
                _, path, width = item
                data, w, h = _jpeg_info(path)
                width = min(width or (right - left), right - left)
                height = width * h / w
                if y - height < bottom:
                    new_page()
                y -= height
                name = b"/Im%d" % (len(images) + 1)
                images.append((name, data, w, h))
                ops.append(b"q %.2f 0 0 %.2f %.2f %.2f cm %s Do Q" % (width, height, left, y, name))
                y -= 8
            elif kind == "table":
                _, headers, rows, widths = item
                n = len(headers)
                if not widths:
                    widths = []
                    for i in range(n):
                        longest = max([_text_width(headers[i], 9, True)] + [
                            _text_width(_cell_text((r[1] if r[0] == "__total__" else r)[i] if i < len(r[1] if r[0] == "__total__" else r) else ""), 9)
                            for r in rows
                        ] or [0])
                        widths.append(max(longest, 30))
                total = float(sum(widths)) or 1.0
                cols = [(right - left) * w / total for w in widths]
                row_h, size = 18, 9

                def row(values, bold=False, fill=None, numeric=None):
                    nonlocal y
                    if y - row_h < bottom:
                        new_page()
                        row(headers, True, 0.88, numeric)
                    y -= row_h
                    if fill is not None:
                        ops.append(b"%.3f g %.2f %.2f %.2f %.2f re f" % (fill, left, y, right - left, row_h))
                    x = left
                    for i in range(n):
                        value = values[i] if i < len(values) else ""
                        text = _cell_text(value)
                        room = cols[i] - 8
                        while text and _text_width(text, size, bold) > room:
                            text = text[:-2] + "…" if len(text) > 2 else ""
                        right_align = numeric[i] if numeric else False
                        tx = x + cols[i] - 4 - _text_width(text, size, bold) if right_align else x + 4
                        text_at(tx, y + 6, text, size, bold)
                        x += cols[i]
                    ops.append(b"0.82 G 0.5 w %.2f %.2f m %.2f %.2f l S" % (left, y, right, y))

                numeric = [
                    any(_is_number((r[1] if r[0] == "__total__" else r)[i]) for r in rows
                        if i < len(r[1] if r[0] == "__total__" else r))
                    for i in range(n)
                ]
                row(headers, True, 0.88, numeric)
                for k, r in enumerate(rows):
                    if r and r[0] == "__total__":
                        row(r[1], True, 0.94, numeric)
                    else:
                        row(r, False, 0.97 if k % 2 else None, numeric)
                y -= 10
        pages.append(ops)
        return pages, images

    def to_bytes(self):
        pages, images = self._layout()
        count = len(pages)
        objects = []

        def add(data):
            objects.append(data)
            return len(objects)

        catalog = add(None)
        tree = add(None)
        f1 = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        f2 = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
        image_refs = []
        for name, data, w, h in images:
            ref = add(b"<< /Type /XObject /Subtype /Image /Width %d /Height %d "
                      b"/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode "
                      b"/Length %d >>\nstream\n" % (w, h, len(data)) + data + b"\nendstream")
            image_refs.append(b"%s %d 0 R" % (name, ref))
        resources = b"<< /Font << /F1 %d 0 R /F2 %d 0 R >> /XObject << %s >> >>" % (
            f1, f2, b" ".join(image_refs))
        kids = []
        for number, ops in enumerate(pages, 1):
            if self.page_numbers:
                label = "%d / %d" % (number, count)
                x = self.width / 2 - _text_width(label, 8) / 2
                ops = ops + [b"BT /F1 8 Tf 0.45 g %.2f %.2f Td %s Tj ET" % (
                    x, self.margin / 2, _pdf_string(label))]
            stream = _zlib.compress(b"\n".join(ops))
            content = add(b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(stream)
                          + stream + b"\nendstream")
            kids.append(add(b"<< /Type /Page /Parent %d 0 R /MediaBox [0 0 %d %d] "
                            b"/Resources %s /Contents %d 0 R >>" % (
                                tree, self.width, self.height, resources, content)))
        objects[catalog - 1] = b"<< /Type /Catalog /Pages %d 0 R >>" % tree
        objects[tree - 1] = b"<< /Type /Pages /Kids [%s] /Count %d >>" % (
            b" ".join(b"%d 0 R" % k for k in kids), count)
        info = add(b"<< /Title %s /Author %s /Producer (DMarlon Studio) >>" % (
            _pdf_string(self.doc_title), _pdf_string(self.author)))
        out = _io.BytesIO()
        out.write(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        offsets = []
        for i, data in enumerate(objects, 1):
            offsets.append(out.tell())
            out.write(b"%d 0 obj\n" % i + data + b"\nendobj\n")
        xref = out.tell()
        out.write(b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1))
        for off in offsets:
            out.write(b"%010d 00000 n \n" % off)
        out.write(b"trailer\n<< /Size %d /Root %d 0 R /Info %d 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (
            len(objects) + 1, catalog, info, xref))
        return out.getvalue()


def _jpeg_info(path):
    """Bytes, anchura y altura de un JPEG (los PDF lo incluyen tal cual)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:2] != b"\xff\xd8":
        raise ValueError("Solo se admiten imágenes JPEG en el informe PDF: " + str(path))
    i = 2
    while i < len(data):
        if data[i] != 0xFF:
            i += 1
            continue
        marker = data[i + 1]
        length = _struct.unpack(">H", data[i + 2:i + 4])[0]
        if marker in (0xC0, 0xC1, 0xC2):
            h, w = _struct.unpack(">HH", data[i + 5:i + 9])
            return data, w, h
        i += 2 + length
    raise ValueError("JPEG sin tamaño: " + str(path))


def _column_name(index):
    name = ""
    index += 1
    while index:
        index, rest = divmod(index - 1, 26)
        name = chr(65 + rest) + name
    return name


class ExcelReport(_ReportBase):
    """Libro de Excel (.xlsx): sheet(nombre) abre una hoja; write_row,
    write_rows y header escriben filas (texto, números, fechas y
    verdadero/falso con su tipo); save, save_dialog, open o download lo
    generan. Columnas con el ancho de su contenido, cabecera en negrita,
    fija y con filtro."""

    extension = ".xlsx"
    mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    file_types = [("Excel", "*.xlsx")]

    def __init__(self, owner, web=False, filename="", sheet=""):
        super().__init__(owner, web, filename)
        self._first = sheet or "Hoja1"
        self.clear()

    def clear(self):
        self._sheets = []
        self._current = None
        return self

    def sheet(self, name):
        clean = "".join(c for c in str(name) if c not in "[]:*?/\\")[:31] or "Hoja"
        taken = {s["name"] for s in self._sheets}
        base, n = clean, 2
        while clean in taken:
            clean = (base[:28] + " %d" % n)
            n += 1
        self._current = {"name": clean, "rows": [], "header": None}
        self._sheets.append(self._current)
        return self

    def _sheet(self):
        if self._current is None:
            self.sheet(self._first)
        return self._current

    def header(self, values):
        s = self._sheet()
        s["header"] = len(s["rows"])
        s["rows"].append(list(values))
        return self

    def write_row(self, values):
        self._sheet()["rows"].append(list(values))
        return self

    def write_rows(self, rows, header=False):
        rows = [list(r) for r in rows]
        if header and rows:
            self.header(rows[0])
            rows = rows[1:]
        for r in rows:
            self.write_row(r)
        return self

    def _sheet_xml(self, s):
        widths = {}
        out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
               '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">']
        if s["header"] is not None:
            out.append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="%d" topLeftCell="A%d" '
                       'activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
                       % (s["header"] + 1, s["header"] + 2))
        rows_xml = []
        for r_index, values in enumerate(s["rows"]):
            cells = []
            bold = r_index == s["header"]
            for c_index, value in enumerate(values):
                ref = "%s%d" % (_column_name(c_index), r_index + 1)
                text = _cell_text(value)
                widths[c_index] = max(widths.get(c_index, 0), len(text))
                if value is None or value == "":
                    continue
                if isinstance(value, bool):
                    cells.append('<c r="%s" t="b"%s><v>%d</v></c>' % (ref, ' s="1"' if bold else "", value))
                elif _is_number(value):
                    style = ' s="1"' if bold else (' s="3"' if isinstance(value, float) else "")
                    cells.append('<c r="%s"%s><v>%r</v></c>' % (ref, style, value))
                elif isinstance(value, (_dt.date, _dt.datetime)):
                    epoch = _dt.datetime(1899, 12, 30)
                    moment = value if isinstance(value, _dt.datetime) else _dt.datetime(value.year, value.month, value.day)
                    serial = (moment - epoch).total_seconds() / 86400
                    cells.append('<c r="%s" s="2"><v>%r</v></c>' % (ref, serial))
                else:
                    cells.append('<c r="%s" t="inlineStr"%s><is><t xml:space="preserve">%s</t></is></c>'
                                 % (ref, ' s="1"' if bold else "", _xml_escape(str(value))))
            rows_xml.append('<row r="%d">%s</row>' % (r_index + 1, "".join(cells)))
        if widths:
            out.append("<cols>%s</cols>" % "".join(
                '<col min="%d" max="%d" width="%.1f" customWidth="1"/>' % (i + 1, i + 1, min(max(w + 2, 8), 60))
                for i, w in sorted(widths.items())))
        out.append("<sheetData>%s</sheetData>" % "".join(rows_xml))
        if s["header"] is not None and s["rows"]:
            last = _column_name(max(len(r) for r in s["rows"]) - 1)
            out.append('<autoFilter ref="A%d:%s%d"/>' % (s["header"] + 1, last, len(s["rows"])))
        out.append("</worksheet>")
        return "".join(out)

    def to_bytes(self):
        self._sheet()
        sheets = self._sheets
        buf = _io.BytesIO()
        with _zipfile.ZipFile(buf, "w", _zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml",
                       '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                       '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                       '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                       '<Default Extension="xml" ContentType="application/xml"/>'
                       '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                       '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
                       + "".join('<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' % (i + 1)
                                 for i in range(len(sheets)))
                       + "</Types>")
            z.writestr("_rels/.rels",
                       '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                       '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                       '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
                       "</Relationships>")
            z.writestr("xl/workbook.xml",
                       '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                       '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
                       'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
                       + "".join('<sheet name="%s" sheetId="%d" r:id="rId%d"/>' % (_xml_escape(s["name"], {'"': "&quot;"}), i + 1, i + 1)
                                 for i, s in enumerate(sheets))
                       + "</sheets></workbook>")
            z.writestr("xl/_rels/workbook.xml.rels",
                       '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                       '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                       + "".join('<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet%d.xml"/>' % (i + 1, i + 1)
                                 for i in range(len(sheets)))
                       + '<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' % (len(sheets) + 1)
                       + "</Relationships>")
            z.writestr("xl/styles.xml",
                       '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                       '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                       '<numFmts count="1"><numFmt numFmtId="164" formatCode="dd/mm/yyyy"/></numFmts>'
                       '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
                       '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
                       '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
                       '<fill><patternFill patternType="solid"><fgColor rgb="FFE8EEF8"/></patternFill></fill></fills>'
                       '<borders count="1"><border/></borders>'
                       '<cellStyleXfs count="1"><xf/></cellStyleXfs>'
                       '<cellXfs count="4"><xf/><xf fontId="1" fillId="2" applyFont="1" applyFill="1"/>'
                       '<xf numFmtId="164" applyNumberFormat="1"/><xf numFmtId="4" applyNumberFormat="1"/></cellXfs>'
                       "</styleSheet>")
            for i, s in enumerate(sheets):
                z.writestr("xl/worksheets/sheet%d.xml" % (i + 1), self._sheet_xml(s))
        return buf.getvalue()
''';
