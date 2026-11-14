part of 'tk_examples.dart';

// El código en Python de 20pdf (tk_showcase_util_20pdf.dart); el estudio pone
// los textos en «# @TEXTS» (TX = {...}).
const _pdf20Code = r'''import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import tkinter as tk
from tkinter import colorchooser, filedialog, messagebox, simpledialog, ttk

# Paquetes de terceros que necesita el programa (las demos los instalan).
REQUIRES = ["pypdf", "pypdfium2", "pillow", "reportlab", "python-docx", "openpyxl", "python-pptx", "pdfminer.six", "pyhanko", "cryptography", 'pyobjc-framework-Vision; sys_platform == "darwin"']
# Los que van enteros en la app, con sus datos (plantillas, certificados…).
COLLECT = ["pptx", "docx", "pyhanko", "pyhanko_certvalidator", "pypdfium2", "pypdfium2_raw", "reportlab"]

MISSING = []


def _need(name):
    MISSING.append(name)
    return None


try:
    import pypdf
    from pypdf import PdfReader, PdfWriter
    from pypdf.annotations import Ellipse, FreeText, Line, Rectangle, Text
    from pypdf.constants import UserAccessPermissions as Perm
    from pypdf.generic import ArrayObject, FloatObject, NameObject
except ImportError:
    pypdf = _need("pypdf")
try:
    import pypdfium2 as pdfium
except ImportError:
    pdfium = _need("pypdfium2")
try:
    from PIL import Image, ImageDraw, ImageTk
except ImportError:
    Image = _need("pillow")
try:
    from reportlab.lib import colors as rl_colors
    from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.utils import ImageReader
    from reportlab.pdfbase.pdfmetrics import stringWidth
    from reportlab.pdfgen import canvas as rl_canvas
    from reportlab.platypus import Image as RLImage
    from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
except ImportError:
    rl_canvas = _need("reportlab")
try:
    import docx
    from docx.shared import Pt
except ImportError:
    docx = _need("python-docx")
try:
    import openpyxl
except ImportError:
    openpyxl = _need("openpyxl")
try:
    import pptx
    from pptx.util import Emu
except ImportError:
    pptx = _need("python-pptx")
try:
    from pdfminer.high_level import extract_pages
    from pdfminer.layout import LTChar, LTTextContainer, LTTextLine
except ImportError:
    extract_pages = _need("pdfminer.six")

# @TEXTS


def T(key, *args):
    s = TX.get(key, key)
    return s.format(*args) if args else s


# ============================================================ utilidades
def app_dir():
    if os.environ.get("DMS_20PDF_CONFIG"):
        return os.environ["DMS_20PDF_CONFIG"]
    home = os.path.expanduser("~")
    if sys.platform == "darwin":
        return os.path.join(home, "Library", "Application Support", "DMarlon Studio Demos", "20pdf")
    if sys.platform.startswith("win"):
        return os.path.join(os.environ.get("APPDATA", home), "DMarlon Studio Demos", "20pdf")
    return os.path.join(home, ".config", "DMarlon Studio Demos", "20pdf")


def stem(path):
    return os.path.splitext(os.path.basename(path))[0]


def free_path(path):
    """La ruta, o «nombre (2).ext» si ya existe."""
    if not os.path.exists(path):
        return path
    base, ext = os.path.splitext(path)
    n = 2
    while os.path.exists("%s (%d)%s" % (base, n, ext)):
        n += 1
    return "%s (%d)%s" % (base, n, ext)


def parse_ranges(text, total):
    """«1-3, 5, 8-» → [0, 1, 2, 4, 7, …] (índices desde 0, sin repetir, en orden)."""
    text = (text or "").strip().lower()
    if not text or text in ("todas", "all", "*"):
        return list(range(total))
    out = []
    for part in re.split(r"[,;\s]+", text):
        if not part:
            continue
        m = re.fullmatch(r"(\d*)\s*-\s*(\d*)", part)
        if m:
            a = int(m.group(1)) if m.group(1) else 1
            b = int(m.group(2)) if m.group(2) else total
        elif part.isdigit():
            a = b = int(part)
        else:
            raise ValueError(T("BAD_RANGE", part))
        if a < 1 or b > total or a > b:
            raise ValueError(T("OUT_OF_RANGE", part, total))
        for i in range(a - 1, b):
            if i not in out:
                out.append(i)
    return out


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def open_reader(path, password=""):
    r = PdfReader(path)
    if r.is_encrypted:
        if not password or not r.decrypt(password):
            raise PermissionError(T("NEEDS_PASSWORD", os.path.basename(path)))
    return r


def page_size(page):
    box = page.mediabox
    return float(box.width), float(box.height)


def overlay_page(w, h, draw):
    """Una página de reportlab de w × h con lo que dibuje [draw](c) → página de pypdf."""
    buf = io.BytesIO()
    c = rl_canvas.Canvas(buf, pagesize=(w, h))
    draw(c)
    c.showPage()
    c.save()
    buf.seek(0)
    return PdfReader(buf).pages[0]


def stamp(writer_page, w, h, draw):
    """Dibuja encima de una página (con su giro pasado al contenido)."""
    if writer_page.get("/Rotate", 0):
        writer_page.transfer_rotation_to_content()
        w, h = page_size(writer_page)
    ox, oy = float(writer_page.mediabox.left), float(writer_page.mediabox.bottom)
    ov = overlay_page(w + ox, h + oy, lambda c: (c.translate(ox, oy), draw(c, w, h)))
    writer_page.merge_page(ov)


def render(path, index, scale=1.0, password=None):
    """Una página como imagen (PIL), con pdfium."""
    pdf = pdfium.PdfDocument(path, password=password or None)
    try:
        pdf.init_forms()   # para que se vean los campos y las firmas visibles
        page = pdf[index]
        img = page.render(scale=scale, may_draw_forms=True).to_pil()
        page.close()
        return img
    finally:
        pdf.close()


def page_count(path, password=None):
    pdf = pdfium.PdfDocument(path, password=password or None)
    try:
        return len(pdf)
    finally:
        pdf.close()


def write(writer, path):
    with open(path, "wb") as f:
        writer.write(f)
    return path


def result(files, message):
    return {"files": files, "message": message}


# ============================================================ 1. Conversión
def find_soffice():
    for p in (shutil.which("soffice"), "/Applications/LibreOffice.app/Contents/MacOS/soffice",
              r"C:\Program Files\LibreOffice\program\soffice.exe"):
        if p and os.path.exists(p):
            return p
    return None


def _xml(s):
    return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _runs_markup(par, base_size):
    out = []
    for run in par.runs:
        text = _xml(run.text)
        if not text:
            continue
        if run.bold:
            text = "<b>%s</b>" % text
        if run.italic:
            text = "<i>%s</i>" % text
        if run.underline:
            text = "<u>%s</u>" % text
        size = run.font.size.pt if run.font.size else None
        color = None
        try:
            if run.font.color is not None and run.font.color.rgb is not None:
                color = "#%s" % run.font.color.rgb
        except Exception:
            color = None
        attrs = ""
        if size and abs(size - base_size) > 0.5:
            attrs += ' size="%.1f"' % size
        if color:
            attrs += ' color="%s"' % color
        if attrs:
            text = "<font%s>%s</font>" % (attrs, text)
        out.append(text)
    return "".join(out)


def _docx_images(par, doc):
    """Las imágenes de un párrafo: (bytes, ancho en puntos, alto en puntos)."""
    out = []
    ns = {"a": "http://schemas.openxmlformats.org/drawingml/2006/main",
          "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
          "wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"}
    for drawing in par._p.iter("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}drawing"):
        blip = drawing.find(".//a:blip", ns)
        extent = drawing.find(".//wp:extent", ns)
        if blip is None:
            continue
        rid = blip.get("{%s}embed" % ns["r"])
        part = doc.part.related_parts.get(rid)
        if part is None:
            continue
        w = h = None
        if extent is not None:
            w = int(extent.get("cx")) / 12700.0
            h = int(extent.get("cy")) / 12700.0
        out.append((part.blob, w, h))
    return out


def docx_to_pdf_basic(src, out):
    """Word → PDF sin Word ni LibreOffice: los párrafos con sus estilos,
    las tablas y las imágenes, con reportlab."""
    doc = docx.Document(src)
    sec = doc.sections[0]
    size = (sec.page_width.pt, sec.page_height.pt) if sec.page_width else A4
    margins = [m.pt if m is not None else 72 for m in (sec.left_margin, sec.right_margin, sec.top_margin, sec.bottom_margin)]
    styles = getSampleStyleSheet()
    body = ParagraphStyle("body", parent=styles["Normal"], fontSize=11, leading=15, spaceAfter=6)
    heads = {1: ParagraphStyle("h1", parent=body, fontSize=20, leading=25, spaceBefore=10, spaceAfter=8, fontName="Helvetica-Bold"),
             2: ParagraphStyle("h2", parent=body, fontSize=16, leading=20, spaceBefore=8, spaceAfter=6, fontName="Helvetica-Bold"),
             3: ParagraphStyle("h3", parent=body, fontSize=13, leading=17, spaceBefore=6, spaceAfter=4, fontName="Helvetica-Bold")}
    title = ParagraphStyle("title", parent=body, fontSize=26, leading=31, spaceAfter=12, fontName="Helvetica-Bold")
    aligns = {0: TA_LEFT, 1: TA_CENTER, 2: TA_RIGHT, 3: TA_JUSTIFY}
    frame_w = size[0] - margins[0] - margins[1]
    story = []
    numbered = 0
    W_NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
    for el in doc.element.body.iterchildren():
        if el.tag == W_NS + "p":
            par = docx.text.paragraph.Paragraph(el, doc)
            name = (par.style.name if par.style is not None else "") or ""
            style = body
            if name == "Title":
                style = title
            m = re.match(r"Heading (\d)", name)
            if m:
                style = heads.get(int(m.group(1)), heads[3])
            if par.alignment is not None and int(par.alignment) in aligns:
                style = ParagraphStyle("a%d" % len(story), parent=style, alignment=aligns[int(par.alignment)])
            markup = _runs_markup(par, style.fontSize)
            if name.startswith("List Bullet"):
                markup = "•&nbsp;&nbsp;" + markup
                style = ParagraphStyle("li%d" % len(story), parent=style, leftIndent=14)
            elif name.startswith("List Number"):
                numbered += 1
                markup = "%d.&nbsp;&nbsp;%s" % (numbered, markup)
                style = ParagraphStyle("ln%d" % len(story), parent=style, leftIndent=14)
            else:
                numbered = 0
            for blob, w, h in _docx_images(par, doc):
                img = ImageReader(io.BytesIO(blob))
                iw, ih = img.getSize()
                w = w or iw * 0.75
                h = h or ih * 0.75
                if w > frame_w:
                    h, w = h * frame_w / w, frame_w
                story.append(RLImage(io.BytesIO(blob), width=w, height=h))
            if markup.strip():
                story.append(Paragraph(markup, style))
            elif not _docx_images(par, doc):
                story.append(Spacer(1, 8))
            if 'w:type="page"' in el.xml:
                story.append(PageBreak())
        elif el.tag == W_NS + "tbl":
            table = docx.table.Table(el, doc)
            data = [[Paragraph(_xml(cell.text), body) for cell in row.cells] for row in table.rows]
            if data:
                t = Table(data, colWidths=[frame_w / max(1, len(data[0]))] * len(data[0]), repeatRows=1)
                t.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.5, rl_colors.HexColor("#9aa5b1")),
                                       ("BACKGROUND", (0, 0), (-1, 0), rl_colors.HexColor("#e8edf3")),
                                       ("VALIGN", (0, 0), (-1, -1), "TOP")]))
                story.append(t)
                story.append(Spacer(1, 8))
    pdf = SimpleDocTemplate(out, pagesize=size, leftMargin=margins[0], rightMargin=margins[1],
                            topMargin=margins[2], bottomMargin=margins[3], title=stem(src))
    pdf.build(story or [Paragraph("", body)])
    return out


def word_to_pdf(files, outdir, opts, progress=None):
    done = []
    office = find_soffice()
    for i, src in enumerate(files):
        out = free_path(os.path.join(outdir, stem(src) + ".pdf"))
        if office and opts.get("engine", "auto") != "basic":
            with tempfile.TemporaryDirectory() as tmp:
                subprocess.run([office, "--headless", "--convert-to", "pdf", "--outdir", tmp, src],
                               check=True, capture_output=True, timeout=180)
                shutil.move(os.path.join(tmp, stem(src) + ".pdf"), out)
        else:
            docx_to_pdf_basic(src, out)
        done.append(out)
        if progress:
            progress(i + 1, len(files))
    return result(done, T("DONE_WORD2PDF", len(done), "LibreOffice" if office and opts.get("engine") != "basic" else T("ENGINE_BASIC")))


def _lines(path, password=""):
    """El texto de cada página, por líneas: (página, x, y, tamaño, negrita, texto)."""
    out = []
    for n, layout in enumerate(extract_pages(path, password=password or "")):
        for box in layout:
            if not isinstance(box, LTTextContainer):
                continue
            for line in box:
                if not isinstance(line, LTTextLine):
                    continue
                text = line.get_text().strip()
                if not text:
                    continue
                chars = [c for c in line if isinstance(c, LTChar)]
                size = max((c.size for c in chars), default=10)
                bold = any("bold" in (c.fontname or "").lower() for c in chars[:3])
                out.append((n, line.x0, line.y1, size, bold, text, line.x1, line.y0))
    return out


def pdf_to_word(files, outdir, opts, progress=None):
    done = []
    for i, src in enumerate(files):
        reader = open_reader(src, opts.get("password", ""))
        lines = _lines(src, opts.get("password", ""))
        sizes = sorted(l[3] for l in lines) or [11]
        body = sizes[len(sizes) // 2]
        d = docx.Document()
        w, h = page_size(reader.pages[0])
        sec = d.sections[0]
        sec.page_width, sec.page_height = Pt(w), Pt(h)
        for m in ("left_margin", "right_margin", "top_margin", "bottom_margin"):
            setattr(sec, m, Pt(48))
        pages = {}
        for l in lines:
            pages.setdefault(l[0], []).append(l)
        for n in range(len(reader.pages)):
            if n > 0:
                d.add_page_break()
            plines = sorted(pages.get(n, []), key=lambda l: (-l[2], l[1]))
            if not plines:
                # Página sin texto (escaneada): va como imagen.
                img = render(src, n, 1.5, opts.get("password"))
                buf = io.BytesIO()
                img.save(buf, "PNG")
                buf.seek(0)
                d.add_picture(buf, width=Pt(w - 96))
                continue
            para, last_y, last_size = None, None, None
            for (_, x, y, size, bold, text, x1, y0) in plines:
                new = para is None or last_size is None or abs(size - last_size) > 0.6 or (last_y - y) > size * 1.8
                if new:
                    if size >= body * 1.5:
                        para = d.add_heading(level=1 if size >= body * 1.9 else 2)
                    else:
                        para = d.add_paragraph()
                    run = para.add_run(text)
                else:
                    run = para.add_run(" " + text)
                run.font.size = Pt(round(size, 1))
                run.bold = bold or None
                last_y, last_size = y, size
        out = free_path(os.path.join(outdir, stem(src) + ".docx"))
        d.save(out)
        done.append(out)
        if progress:
            progress(i + 1, len(files))
    return result(done, T("DONE_FILES", len(done)))


def _cell_text(v):
    if v is None:
        return ""
    if isinstance(v, float):
        return ("%.2f" % v).rstrip("0").rstrip(".") if abs(v - round(v)) > 1e-9 else str(int(round(v)))
    if hasattr(v, "strftime"):
        return v.strftime("%d/%m/%Y") if not getattr(v, "hour", 0) else v.strftime("%d/%m/%Y %H:%M")
    return str(v)


def excel_to_pdf(files, outdir, opts, progress=None):
    done = []
    styles = getSampleStyleSheet()
    for i, src in enumerate(files):
        wb = openpyxl.load_workbook(src, data_only=True)
        story = []
        widest = A4[0]
        for ws in wb.worksheets:
            rows = [[_cell_text(c.value) for c in row] for row in ws.iter_rows()]
            # Sin filas ni columnas vacías al final.
            while rows and not any(rows[-1]):
                rows.pop()
            ncols = max((max((k + 1 for k, v in enumerate(r) if v), default=0) for r in rows), default=0)
            rows = [r[:ncols] + [""] * (ncols - len(r[:ncols])) for r in rows]
            if not rows or not ncols:
                continue
            widths = []
            for k in range(ncols):
                letter = openpyxl.utils.get_column_letter(k + 1)
                dim = ws.column_dimensions.get(letter)
                chars = dim.width if dim is not None and dim.width else max(len(r[k]) for r in rows) + 2
                widths.append(max(28, min(260, chars * 5.6)))
            widest = max(widest, sum(widths) + 72)
            if story:
                story.append(PageBreak())
            story.append(Paragraph(_xml(ws.title), styles["Heading2"]))
            t = Table(rows, colWidths=widths, repeatRows=1)
            st = [("GRID", (0, 0), (-1, -1), 0.4, rl_colors.HexColor("#c3ccd8")),
                  ("FONTSIZE", (0, 0), (-1, -1), 8.5),
                  ("BACKGROUND", (0, 0), (-1, 0), rl_colors.HexColor("#1f6f8b")),
                  ("TEXTCOLOR", (0, 0), (-1, 0), rl_colors.white),
                  ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                  ("VALIGN", (0, 0), (-1, -1), "MIDDLE")]
            for r in range(1, len(rows)):
                if r % 2 == 0:
                    st.append(("BACKGROUND", (0, r), (-1, r), rl_colors.HexColor("#f1f5f9")))
                for k in range(ncols):
                    if re.fullmatch(r"-?[\d.,]+", rows[r][k] or "x"):
                        st.append(("ALIGN", (k, r), (k, r), "RIGHT"))
            for rng in ws.merged_cells.ranges:
                if rng.max_row <= len(rows) and rng.max_col <= ncols:
                    st.append(("SPAN", (rng.min_col - 1, rng.min_row - 1), (rng.max_col - 1, rng.max_row - 1)))
            t.setStyle(TableStyle(st))
            story.append(t)
        orient = opts.get("orientation", "auto")
        size = landscape(A4) if orient == "landscape" or (orient == "auto" and widest > A4[0]) else A4
        out = free_path(os.path.join(outdir, stem(src) + ".pdf"))
        doc = SimpleDocTemplate(out, pagesize=size, leftMargin=36, rightMargin=36, topMargin=40, bottomMargin=40,
                                title=stem(src))
        doc.build(story or [Paragraph(T("EMPTY_SHEET"), styles["Normal"])])
        done.append(out)
        if progress:
            progress(i + 1, len(files))
    return result(done, T("DONE_FILES", len(done)))


def pdf_to_images(files, outdir, opts, progress=None):
    done = []
    fmt = opts.get("format", "png").lower()
    dpi = int(opts.get("dpi", 150))
    for src in files:
        n = page_count(src, opts.get("password"))
        for k in parse_ranges(opts.get("pages", ""), n):
            img = render(src, k, dpi / 72.0, opts.get("password"))
            out = free_path(os.path.join(outdir, "%s-%d.%s" % (stem(src), k + 1, "jpg" if fmt == "jpg" else "png")))
            if fmt == "jpg":
                img.convert("RGB").save(out, "JPEG", quality=90)
            else:
                img.save(out, "PNG")
            done.append(out)
            if progress:
                progress(len(done), n)
    return result(done, T("DONE_IMAGES", len(done), dpi))


def pdf_to_pptx(files, outdir, opts, progress=None):
    done = []
    for src in files:
        reader = open_reader(src, opts.get("password", ""))
        w, h = page_size(reader.pages[0])
        prs = pptx.Presentation()
        prs.slide_width = Emu(int(12192000))
        prs.slide_height = Emu(int(12192000 * h / w))
        sw, sh = prs.slide_width, prs.slide_height
        blank = prs.slide_layouts[6]
        editable = opts.get("mode") == "text"
        lines = _lines(src, opts.get("password", "")) if editable else []
        for n, page in enumerate(reader.pages):
            slide = prs.slides.add_slide(blank)
            pw, ph = page_size(page)
            if editable:
                for (pn, x, y, size, bold, text, x1, y0) in lines:
                    if pn != n:
                        continue
                    left = int(sw * x / pw)
                    top = int(sh * (ph - y) / ph)
                    box = slide.shapes.add_textbox(left, top, int(sw * max(20, x1 - x) / pw) + Emu(91440), int(sh * size * 1.4 / ph))
                    tf = box.text_frame
                    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
                    run = tf.paragraphs[0].add_run()
                    run.text = text
                    run.font.size = pptx.util.Pt(max(6, size * (sw / 12700.0) / pw))
                    run.font.bold = bold
            else:
                img = render(src, n, 2.0, opts.get("password"))
                buf = io.BytesIO()
                img.save(buf, "PNG")
                buf.seek(0)
                slide.shapes.add_picture(buf, 0, 0, sw, sh)
                text = (page.extract_text() or "").strip()
                if text:
                    slide.notes_slide.notes_text_frame.text = text
            if progress:
                progress(n + 1, len(reader.pages))
        out = free_path(os.path.join(outdir, stem(src) + ".pptx"))
        prs.save(out)
        done.append(out)
    return result(done, T("DONE_FILES", len(done)))


# ============================================================ 2. Edición
def apply_edits(src, out, edits, password=""):
    """Textos, imágenes y recuadros que tapan (para cambiar lo que pone):
    edits = [{"page", "type": text|image|cover, "x", "y", "w", "h", "text", "size", "color", "path"}]
    en puntos del PDF (origen abajo a la izquierda)."""
    reader = open_reader(src, password)
    writer = PdfWriter(clone_from=reader)
    by_page = {}
    for e in edits:
        by_page.setdefault(e["page"], []).append(e)
    for n, items in by_page.items():
        page = writer.pages[n]
        w, h = page_size(page)

        def draw(c, w, h, items=items):
            for e in items:
                if e["type"] == "cover":
                    c.setFillColorRGB(*hex_rgb(e.get("color", "#ffffff")))
                    c.rect(e["x"], e["y"], e["w"], e["h"], stroke=0, fill=1)
            for e in items:
                if e["type"] == "text":
                    c.setFillColorRGB(*hex_rgb(e.get("color", "#000000")))
                    c.setFont("Helvetica-Bold" if e.get("bold") else "Helvetica", e.get("size", 12))
                    for k, line in enumerate(e["text"].split("\n")):
                        c.drawString(e["x"], e["y"] - k * e.get("size", 12) * 1.2, line)
                elif e["type"] == "image":
                    c.drawImage(ImageReader(e["path"]), e["x"], e["y"], e["w"], e["h"], mask="auto")

        stamp(page, w, h, draw)
    return write(writer, out)


def edit_pdf(files, outdir, opts, progress=None):
    src = files[0]
    out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_EDITED") + ".pdf"))
    apply_edits(src, out, opts.get("edits", []), opts.get("password", ""))
    return result([out], T("DONE_EDIT", len(opts.get("edits", []))))


def watermark(files, outdir, opts, progress=None):
    done = []
    text = opts.get("text") or T("WM_DEFAULT")
    size = float(opts.get("size", 60))
    alpha = float(opts.get("opacity", 25)) / 100.0
    color = hex_rgb(opts.get("color", "#c0392b"))
    logo = opts.get("image") or ""
    diagonal = opts.get("angle", "diagonal") == "diagonal"
    for src in files:
        writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
        for page in writer.pages:
            w, h = page_size(page)

            def draw(c, w, h):
                c.saveState()
                c.setFillAlpha(alpha)
                c.setStrokeAlpha(alpha)
                c.translate(w / 2, h / 2)
                if diagonal:
                    c.rotate(45 if w <= h else 30)
                if logo:
                    img = ImageReader(logo)
                    iw, ih = img.getSize()
                    s = min(w * 0.5 / iw, h * 0.5 / ih)
                    c.drawImage(img, -iw * s / 2, -ih * s / 2, iw * s, ih * s, mask="auto")
                else:
                    c.setFillColorRGB(*color)
                    c.setFont("Helvetica-Bold", size)
                    c.drawCentredString(0, -size / 3, text)
                c.restoreState()

            stamp(page, w, h, draw)
        out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_WM") + ".pdf"))
        done.append(write(writer, out))
    return result(done, T("DONE_FILES", len(done)))


NUM_POSITIONS = ["bottom-center", "bottom-right", "bottom-left", "top-center", "top-right", "top-left"]


def page_numbers(files, outdir, opts, progress=None):
    done = []
    pattern = opts.get("format") or T("NUM_FORMAT_1")
    pos = opts.get("position", "bottom-center")
    size = float(opts.get("size", 10))
    start = int(opts.get("start", 1) or 1)
    skip_first = bool(opts.get("skip_first"))
    header = opts.get("header", "")
    for src in files:
        writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
        total = len(writer.pages)
        for k, page in enumerate(writer.pages):
            if skip_first and k == 0:
                continue
            w, h = page_size(page)
            n = start + k - (1 if skip_first else 0)
            label = pattern.replace("{n}", str(n)).replace("{total}", str(total - (1 if skip_first else 0) + start - 1))

            def draw(c, w, h, label=label):
                c.setFont("Helvetica", size)
                c.setFillColorRGB(0.25, 0.27, 0.3)
                y = 24 if pos.startswith("bottom") else h - 24 - size
                if pos.endswith("center"):
                    c.drawCentredString(w / 2, y, label)
                elif pos.endswith("right"):
                    c.drawRightString(w - 36, y, label)
                else:
                    c.drawString(36, y, label)
                if header:
                    c.setFont("Helvetica-Oblique", size)
                    hy = h - 24 - size if pos.startswith("bottom") else 24
                    c.drawCentredString(w / 2, hy, header)

            stamp(page, w, h, draw)
        out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_NUM") + ".pdf"))
        done.append(write(writer, out))
    return result(done, T("DONE_FILES", len(done)))


def rotate_pages(files, outdir, opts, progress=None):
    done = []
    angle = int(opts.get("angle", 90))
    for src in files:
        writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
        for k in parse_ranges(opts.get("pages", ""), len(writer.pages)):
            writer.pages[k].rotate(angle)
        out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_ROT") + ".pdf"))
        done.append(write(writer, out))
    return result(done, T("DONE_FILES", len(done)))


def annotate(files, outdir, opts, progress=None):
    """Notas, resaltados y formas: [{"page", "type": note|highlight|rect|ellipse|line|text, "x0","y0","x1","y1", "text", "color"}]."""
    src = files[0]
    writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
    for a in opts.get("annotations", []):
        x0, y0, x1, y1 = min(a["x0"], a["x1"]), min(a["y0"], a["y1"]), max(a["x0"], a["x1"]), max(a["y0"], a["y1"])
        rect = (x0, y0, max(x1, x0 + 1), max(y1, y0 + 1))
        color = [FloatObject(v) for v in hex_rgb(a.get("color", "#ffd400"))]
        kind = a["type"]
        if kind == "note":
            an = Text(rect=(x0, y0, x0 + 24, y0 + 24), text=a.get("text", ""), open=False)
        elif kind == "text":
            an = FreeText(text=a.get("text", ""), rect=rect, font_size="12pt", font_color="000000",
                          border_color=None, background_color=None)
        elif kind == "highlight":
            # Un resaltado es un rectángulo semitransparente con el color de fondo.
            an = Rectangle(rect=rect, interior_color=a.get("color", "#ffd400").lstrip("#"))
            an[NameObject("/CA")] = FloatObject(0.35)
            an[NameObject("/BS")] = pypdf.generic.DictionaryObject({NameObject("/W"): FloatObject(0)})
        elif kind == "ellipse":
            an = Ellipse(rect=rect)
        elif kind == "line":
            an = Line(p1=(a["x0"], a["y0"]), p2=(a["x1"], a["y1"]), rect=rect)
        else:
            an = Rectangle(rect=rect)
        an[NameObject("/C")] = ArrayObject(color)
        if a.get("text") and kind not in ("text", "note"):
            an[NameObject("/Contents")] = pypdf.generic.TextStringObject(a["text"])
        writer.add_annotation(page_number=a["page"], annotation=an)
    out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_NOTES") + ".pdf"))
    write(writer, out)
    return result([out], T("DONE_NOTES", len(opts.get("annotations", []))))


# ============================================================ 3. Organización
def merge(files, outdir, opts, progress=None):
    if len(files) < 2:
        raise ValueError(T("NEED_TWO"))
    writer = PdfWriter()
    for i, src in enumerate(files):
        writer.append(open_reader(src, opts.get("password", "")))
        if progress:
            progress(i + 1, len(files))
    out = free_path(os.path.join(outdir, opts.get("name") or T("MERGED_NAME") + ".pdf"))
    write(writer, out)
    return result([out], T("DONE_MERGE", len(files), len(writer.pages)))


def split(files, outdir, opts, progress=None):
    done = []
    for src in files:
        reader = open_reader(src, opts.get("password", ""))
        n = len(reader.pages)
        mode = opts.get("mode", "each")
        if mode == "every":
            k = max(1, int(opts.get("every", 1) or 1))
            groups = [list(range(a, min(n, a + k))) for a in range(0, n, k)]
        elif mode == "ranges":
            groups = [parse_ranges(part, n) for part in re.split(r"[;|]", opts.get("ranges", "")) if part.strip()]
        else:
            groups = [[i] for i in range(n)]
        for g in groups:
            writer = PdfWriter()
            for i in g:
                writer.add_page(reader.pages[i])
            label = "%d" % (g[0] + 1) if len(g) == 1 else "%d-%d" % (g[0] + 1, g[-1] + 1)
            done.append(write(writer, free_path(os.path.join(outdir, "%s-%s.pdf" % (stem(src), label)))))
    return result(done, T("DONE_FILES", len(done)))


def organize(files, outdir, opts, progress=None):
    """El orden nuevo: [{"src": índice del archivo o -1 (página en blanco), "page", "rot"}]."""
    readers = [open_reader(f, opts.get("password", "")) for f in files]
    writer = PdfWriter()
    for item in opts.get("order", []):
        if item["src"] < 0:
            w, h = page_size(readers[0].pages[0])
            writer.add_blank_page(width=w, height=h)
        else:
            writer.add_page(readers[item["src"]].pages[item["page"]])
            if item.get("rot"):
                writer.pages[-1].rotate(item["rot"])
    out = free_path(os.path.join(outdir, stem(files[0]) + T("SUFFIX_ORG") + ".pdf"))
    write(writer, out)
    return result([out], T("DONE_ORG", len(writer.pages)))


def extract(files, outdir, opts, progress=None):
    src = files[0]
    reader = open_reader(src, opts.get("password", ""))
    pages = parse_ranges(opts.get("pages", ""), len(reader.pages))
    if not pages:
        raise ValueError(T("NO_PAGES"))
    done = []
    if opts.get("separate"):
        for i in pages:
            w = PdfWriter()
            w.add_page(reader.pages[i])
            done.append(write(w, free_path(os.path.join(outdir, "%s-p%d.pdf" % (stem(src), i + 1)))))
    else:
        w = PdfWriter()
        for i in pages:
            w.add_page(reader.pages[i])
        done.append(write(w, free_path(os.path.join(outdir, stem(src) + T("SUFFIX_EXTRACT") + ".pdf"))))
    return result(done, T("DONE_EXTRACT", len(pages)))


# ============================================================ 4. Seguridad
def protect(files, outdir, opts, progress=None):
    user = opts.get("password_new", "")
    if not user:
        raise ValueError(T("NEED_NEW_PASSWORD"))
    owner = opts.get("owner") or user + "-owner"
    perms = Perm.R1 | Perm.R2 | Perm.R7 | Perm.R8 | Perm.R13 | Perm.R14 | Perm.R15 | Perm.R16 | Perm.R17 | Perm.R18
    perms |= Perm.R19 | Perm.R20 | Perm.R21 | Perm.R22 | Perm.R23 | Perm.R24 | Perm.R25 | Perm.R26 | Perm.R27 | Perm.R28
    perms |= Perm.R29 | Perm.R30 | Perm.R31 | Perm.R32 | Perm.FILL_FORM_FIELDS | Perm.EXTRACT_TEXT_AND_GRAPHICS
    if opts.get("allow_print", True):
        perms |= Perm.PRINT | Perm.PRINT_TO_REPRESENTATION
    if opts.get("allow_copy", True):
        perms |= Perm.EXTRACT
    if opts.get("allow_modify", False):
        perms |= Perm.MODIFY | Perm.ADD_OR_MODIFY | Perm.ASSEMBLE_DOC
    done = []
    for src in files:
        writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
        writer.encrypt(user_password=user, owner_password=owner, algorithm="AES-256", permissions_flag=perms)
        done.append(write(writer, free_path(os.path.join(outdir, stem(src) + T("SUFFIX_LOCK") + ".pdf"))))
    return result(done, T("DONE_PROTECT", len(done)))


def unlock(files, outdir, opts, progress=None):
    if not opts.get("authorized"):
        raise PermissionError(T("NEED_AUTH"))
    done = []
    for src in files:
        reader = PdfReader(src)
        if reader.is_encrypted and not reader.decrypt(opts.get("password", "")):
            raise PermissionError(T("BAD_PASSWORD", os.path.basename(src)))
        writer = PdfWriter(clone_from=reader)
        done.append(write(writer, free_path(os.path.join(outdir, stem(src) + T("SUFFIX_UNLOCK") + ".pdf"))))
    return result(done, T("DONE_UNLOCK", len(done)))


def cert_paths():
    d = os.path.join(app_dir(), "firma")
    return d, os.path.join(d, "certificado.p12"), os.path.join(d, "certificado.pem")


def ensure_certificate(name, email=""):
    """Un certificado propio (autofirmado) para firmar, creado la primera vez
    y guardado solo para este usuario."""
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives.serialization import pkcs12
    from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID
    import datetime
    d, p12, pem = cert_paths()
    meta = os.path.join(d, "titular.json")
    if os.path.exists(p12) and os.path.exists(meta):
        try:
            if json.load(open(meta, encoding="utf-8")).get("name") == name:
                return p12, pem
        except Exception:
            pass
    os.makedirs(d, exist_ok=True)
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    attrs = [x509.NameAttribute(NameOID.COMMON_NAME, name or "20pdf")]
    if email:
        attrs.append(x509.NameAttribute(NameOID.EMAIL_ADDRESS, email))
    subject = x509.Name(attrs)
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(subject).issuer_name(subject).public_key(key.public_key())
            .serial_number(x509.random_serial_number()).not_valid_before(now - datetime.timedelta(minutes=5))
            .not_valid_after(now + datetime.timedelta(days=3650))
            .add_extension(x509.KeyUsage(digital_signature=True, content_commitment=True, key_encipherment=False,
                                         data_encipherment=False, key_agreement=False, key_cert_sign=True,
                                         crl_sign=False, encipher_only=False, decipher_only=False), critical=True)
            .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.EMAIL_PROTECTION]), critical=False)
            .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
            .sign(key, hashes.SHA256()))
    with open(p12, "wb") as f:
        f.write(pkcs12.serialize_key_and_certificates(b"20pdf", key, cert, None, serialization.NoEncryption()))
    with open(pem, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    json.dump({"name": name, "email": email}, open(meta, "w", encoding="utf-8"))
    for p in (p12, pem, meta):
        try:
            os.chmod(p, 0o600)
        except OSError:
            pass
    return p12, pem


def sign(files, outdir, opts, progress=None):
    """Firma digital (PAdES) con pyHanko y el certificado propio, visible en
    la página y el sitio elegidos, con la firma dibujada si la hay."""
    from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
    from pyhanko.sign import fields, signers
    from pyhanko.stamp import TextStampStyle
    from pyhanko.pdf_utils import images, text as ph_text
    name = opts.get("name") or T("SIGNER_DEFAULT")
    p12, pem = ensure_certificate(name, opts.get("email", ""))
    signer = signers.SimpleSigner.load_pkcs12(p12, passphrase=None)
    src = files[0]
    page = int(opts.get("page", 0))
    box = opts.get("box") or (36, 36, 236, 106)
    style_args = dict(stamp_text=T("SIGN_STAMP"), border_width=1,
                      text_box_style=ph_text.TextBoxStyle(font_size=9))
    if opts.get("drawing") and os.path.exists(opts["drawing"]):
        style_args["background"] = images.PdfImage(opts["drawing"])
        style_args["background_opacity"] = 0.9
    out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_SIGNED") + ".pdf"))
    with open(src, "rb") as inf:
        w = IncrementalPdfFileWriter(inf)
        field = "Firma%d" % int(time.time())
        fields.append_signature_field(w, sig_field_spec=fields.SigFieldSpec(field, on_page=page, box=tuple(box)))
        meta = signers.PdfSignatureMetadata(field_name=field, reason=opts.get("reason") or None,
                                            location=opts.get("location") or None, name=name)
        pdf_signer = signers.PdfSigner(meta, signer=signer, stamp_style=TextStampStyle(**style_args))
        with open(out, "wb") as outf:
            pdf_signer.sign_pdf(w, output=outf)
    return result([out], T("DONE_SIGN", name))


def verify_signatures(path):
    """Las firmas de un PDF: [(firmante, íntegra, de confianza, fecha)]."""
    from pyhanko.keys import load_cert_from_pemder
    from pyhanko.pdf_utils.reader import PdfFileReader
    from pyhanko.sign.validation import validate_pdf_signature
    from pyhanko_certvalidator import ValidationContext
    roots = []
    _, _, pem = cert_paths()
    if os.path.exists(pem):
        roots.append(load_cert_from_pemder(pem))
    out = []
    with open(path, "rb") as f:
        r = PdfFileReader(f)
        for sig in r.embedded_signatures:
            st = validate_pdf_signature(sig, ValidationContext(trust_roots=roots, allow_fetching=False))
            who = sig.signer_cert.subject.native.get("common_name", "?")
            out.append((who, bool(st.intact and st.valid), bool(st.trusted), str(sig.self_reported_timestamp or "")))
    return out


def find_text_boxes(path, terms, password=""):
    """Dónde aparece cada palabra o frase: {página: [(x0, y0, x1, y1)]}."""
    terms = [t.strip().lower() for t in terms if t.strip()]
    found = {}
    if not terms:
        return found
    for n, layout in enumerate(extract_pages(path, password=password or "")):
        for box in layout:
            if not isinstance(box, LTTextContainer):
                continue
            for line in box:
                if not isinstance(line, LTTextLine):
                    continue
                chars = [c for c in line if isinstance(c, LTChar)]
                text = "".join(c.get_text() for c in chars).lower()
                for t in terms:
                    start = text.find(t)
                    while start >= 0:
                        part = chars[start:start + len(t)]
                        if part:
                            found.setdefault(n, []).append((min(c.x0 for c in part) - 1, min(c.y0 for c in part) - 1,
                                                            max(c.x1 for c in part) + 1, max(c.y1 for c in part) + 1))
                        start = text.find(t, start + 1)
    return found


def redact(files, outdir, opts, progress=None):
    """Censurar de verdad: las páginas tocadas se vuelven imagen con los
    recuadros en negro, así lo de debajo desaparece del archivo."""
    src = files[0]
    password = opts.get("password", "")
    reader = open_reader(src, password)
    boxes = {}
    for b in opts.get("boxes", []):
        boxes.setdefault(b["page"], []).append((b["x0"], b["y0"], b["x1"], b["y1"]))
    for n, bs in find_text_boxes(src, opts.get("terms", []), password).items():
        boxes.setdefault(n, []).extend(bs)
    if not boxes:
        raise ValueError(T("NO_REDACTIONS"))
    dpi = int(opts.get("dpi", 200))
    writer = PdfWriter()
    for n, page in enumerate(reader.pages):
        if n not in boxes:
            writer.add_page(page)
            continue
        w, h = page_size(page)
        img = render(src, n, dpi / 72.0, password).convert("RGB")
        d = ImageDraw.Draw(img)
        sx, sy = img.width / w, img.height / h
        for (x0, y0, x1, y1) in boxes[n]:
            d.rectangle([x0 * sx, (h - y1) * sy, x1 * sx, (h - y0) * sy], fill=(0, 0, 0))
        buf = io.BytesIO()
        img.save(buf, "JPEG", quality=88)
        buf.seek(0)
        writer.add_page(overlay_page(w, h, lambda c: c.drawImage(ImageReader(buf), 0, 0, w, h)))
    writer.add_metadata({"/Producer": "20pdf"})
    out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_REDACT") + ".pdf"))
    write(writer, out)
    return result([out], T("DONE_REDACT", sum(len(v) for v in boxes.values()), len(boxes)))


# ============================================================ 5. Optimización
LEVELS = {"light": (85, 2400), "medium": (70, 1600), "strong": (50, 1100)}


def compress(files, outdir, opts, progress=None):
    done, notes = [], []
    quality, max_px = LEVELS.get(opts.get("level", "medium"), LEVELS["medium"])
    for src in files:
        writer = PdfWriter(clone_from=open_reader(src, opts.get("password", "")))
        for page in writer.pages:
            try:
                for img in page.images:
                    pil = img.image
                    if pil is None:
                        continue
                    if max(pil.size) > max_px:
                        s = max_px / float(max(pil.size))
                        pil = pil.resize((max(1, int(pil.width * s)), max(1, int(pil.height * s))))
                    if pil.mode not in ("RGB", "L"):
                        pil = pil.convert("RGB")
                    img.replace(pil, quality=quality)
            except Exception:
                pass
            page.compress_content_streams(level=9)
        try:
            writer.compress_identical_objects(remove_duplicates=True, remove_unreferenced=True)
        except TypeError:   # pypdf 4 a 6
            writer.compress_identical_objects(remove_identicals=True, remove_orphans=True)
        out = free_path(os.path.join(outdir, stem(src) + T("SUFFIX_SMALL") + ".pdf"))
        write(writer, out)
        before, after = os.path.getsize(src), os.path.getsize(out)
        if after >= before:
            shutil.copyfile(src, out)
            after = before
        done.append(out)
        notes.append(T("SIZE_CHANGE", os.path.basename(src), human(before), human(after),
                       int(round(100 - after * 100.0 / max(1, before)))))
    return result(done, "\n".join(notes))


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return ("%d %s" % (n, unit)) if unit == "B" else ("%.1f %s" % (n, unit)).replace(".", TX.get("DEC", "."))
        n /= 1024.0


def ocr_image(path, lang):
    """El texto de una imagen con sus recuadros (0..1, origen abajo a la izquierda)."""
    if sys.platform == "darwin":
        try:
            import Vision
            from Foundation import NSURL
        except ImportError:
            raise RuntimeError(T("NO_OCR_MAC"))
        req = Vision.VNRecognizeTextRequest.alloc().init()
        req.setRecognitionLevel_(Vision.VNRequestTextRecognitionLevelAccurate)
        req.setUsesLanguageCorrection_(True)
        langs = {"es": ["es-ES", "en-US"], "en": ["en-US", "es-ES"]}.get(lang, ["es-ES", "en-US"])
        req.setRecognitionLanguages_(langs)
        handler = Vision.VNImageRequestHandler.alloc().initWithURL_options_(NSURL.fileURLWithPath_(path), None)
        ok, err = handler.performRequests_error_([req], None)
        if not ok:
            raise RuntimeError(str(err))
        out = []
        for obs in req.results() or []:
            cand = obs.topCandidates_(1)
            if not cand:
                continue
            bb = obs.boundingBox()
            out.append((cand[0].string(), bb.origin.x, bb.origin.y, bb.size.width, bb.size.height))
        return out
    try:
        import pytesseract
    except ImportError:
        raise RuntimeError(T("NO_OCR_OTHER"))
    img = Image.open(path)
    data = pytesseract.image_to_data(img, lang={"es": "spa", "en": "eng"}.get(lang, "spa+eng"),
                                     output_type=pytesseract.Output.DICT)
    out = []
    for i, word in enumerate(data["text"]):
        if word.strip():
            x, y, w, h = data["left"][i], data["top"][i], data["width"][i], data["height"][i]
            out.append((word, x / img.width, 1 - (y + h) / img.height, w / img.width, h / img.height))
    return out


def ocr(files, outdir, opts, progress=None):
    """Reconoce el texto de las páginas escaneadas y lo añade, invisible, en
    su sitio: el PDF se ve igual, pero se puede buscar y copiar."""
    done = []
    lang = opts.get("lang", "es")
    found = 0
    for src in files:
        reader = open_reader(src, opts.get("password", ""))
        writer = PdfWriter(clone_from=reader)
        for n, page in enumerate(writer.pages):
            if not opts.get("force") and len((reader.pages[n].extract_text() or "").strip()) > 20:
                continue
            w, h = page_size(page)
            with tempfile.TemporaryDirectory() as tmp:
                png = os.path.join(tmp, "p.png")
                render(src, n, 300 / 72.0, opts.get("password")).save(png)
                words = ocr_image(png, lang)
            found += len(words)

            def draw(c, w, h, words=words):
                for (text, x, y, bw, bh) in words:
                    size = max(4, bh * h * 0.85)
                    tw = stringWidth(text, "Helvetica", size) or 1
                    t = c.beginText()
                    t.setTextRenderMode(3)   # invisible
                    t.setFont("Helvetica", size)
                    t.setHorizScale(max(10, min(400, bw * w / tw * 100)))
                    t.setTextOrigin(x * w, y * h + bh * h * 0.15)
                    t.textOut(text)
                    c.drawText(t)

            stamp(page, w, h, draw)
            if progress:
                progress(n + 1, len(writer.pages))
        done.append(write(writer, free_path(os.path.join(outdir, stem(src) + T("SUFFIX_OCR") + ".pdf"))))
    return result(done, T("DONE_OCR", found))


# Las 20 herramientas: (clave, grupo, función, extensiones, varios archivos, vista interactiva).
TOOLS = [
    ("word2pdf", 0, word_to_pdf, (".docx",), True, None),
    ("pdf2word", 0, pdf_to_word, (".pdf",), True, None),
    ("excel2pdf", 0, excel_to_pdf, (".xlsx", ".xlsm"), True, None),
    ("pdf2img", 0, pdf_to_images, (".pdf",), True, None),
    ("pdf2ppt", 0, pdf_to_pptx, (".pdf",), True, None),
    ("edit", 1, edit_pdf, (".pdf",), False, "edit"),
    ("watermark", 1, watermark, (".pdf",), True, None),
    ("numbers", 1, page_numbers, (".pdf",), True, None),
    ("rotate", 1, rotate_pages, (".pdf",), True, None),
    ("annotate", 1, annotate, (".pdf",), False, "annotate"),
    ("merge", 2, merge, (".pdf",), True, None),
    ("split", 2, split, (".pdf",), True, None),
    ("organize", 2, organize, (".pdf",), True, "organize"),
    ("extract", 2, extract, (".pdf",), False, None),
    ("protect", 3, protect, (".pdf",), True, None),
    ("unlock", 3, unlock, (".pdf",), True, None),
    ("sign", 3, sign, (".pdf",), False, "sign"),
    ("redact", 3, redact, (".pdf",), False, "redact"),
    ("compress", 4, compress, (".pdf",), True, None),
    ("ocr", 4, ocr, (".pdf",), True, None),
]


# ============================================================ la ventana
GROUP_COLORS = ["#2563eb", "#7c3aed", "#0f766e", "#b91c1c", "#b45309"]


class Form1(FormDesign):
    def form_create(self):
        self.tool = 0
        self.files = []
        self.outdir = ""
        self.page = 0
        self.pages = 0
        self.vars = {}
        self.marks = []        # lo que se pone en la vista: ediciones, notas, recuadros
        self.order = []        # organizar: [{"src", "page", "rot"}]
        self.picked = set()    # organizar: las elegidas
        self.sign_box = None
        self.drawing = None    # la firma dibujada (PNG)
        self.drag = None
        self.photo = None
        self.thumbs = []
        self.view = None       # (escala, x, y, ancho, alto de la página en puntos)
        self.worker = None
        self.busy = False
        self.Files.configure(selectmode="browse")
        for i, (key, group, *_rest) in enumerate(TOOLS):
            btn = getattr(self, "BtnT%d" % (i + 1))
            btn.configure(text="  " + T("TOOL_" + key.upper()), anchor="w")
        self.Preview.bind("<Configure>", lambda e: self.show())
        if MISSING:
            self.Status.set(T("MISSING", ", ".join(MISSING), PIP + " -m pip install " + " ".join(MISSING)), icon="⚠")
        self.choose(0)

    # ---- las 20 herramientas (sus etiquetas del diseño)
    def BtnT1_click(self, event=None):
        self.choose(0)

    def BtnT2_click(self, event=None):
        self.choose(1)

    def BtnT3_click(self, event=None):
        self.choose(2)

    def BtnT4_click(self, event=None):
        self.choose(3)

    def BtnT5_click(self, event=None):
        self.choose(4)

    def BtnT6_click(self, event=None):
        self.choose(5)

    def BtnT7_click(self, event=None):
        self.choose(6)

    def BtnT8_click(self, event=None):
        self.choose(7)

    def BtnT9_click(self, event=None):
        self.choose(8)

    def BtnT10_click(self, event=None):
        self.choose(9)

    def BtnT11_click(self, event=None):
        self.choose(10)

    def BtnT12_click(self, event=None):
        self.choose(11)

    def BtnT13_click(self, event=None):
        self.choose(12)

    def BtnT14_click(self, event=None):
        self.choose(13)

    def BtnT15_click(self, event=None):
        self.choose(14)

    def BtnT16_click(self, event=None):
        self.choose(15)

    def BtnT17_click(self, event=None):
        self.choose(16)

    def BtnT18_click(self, event=None):
        self.choose(17)

    def BtnT19_click(self, event=None):
        self.choose(18)

    def BtnT20_click(self, event=None):
        self.choose(19)

    # ---- elegir la herramienta
    def choose(self, i):
        self.tool = i
        key, group, fn, exts, multi, interactive = TOOLS[i]
        for k in range(len(TOOLS)):
            btn = getattr(self, "BtnT%d" % (k + 1))
            on = k == i
            btn.configure(bg=GROUP_COLORS[TOOLS[k][1]] if on else "#2a3140", fg="#ffffff" if on else "#d6dbe4")
        self.LblTool.configure(text=T("TOOL_" + key.upper()), fg=GROUP_COLORS[group])
        self.LblDesc.configure(text=T("DESC_" + key.upper()))
        self.BtnRun.configure(text=T("RUN_" + key.upper()))
        self.LblFiles.configure(text=T("FILES_MANY" if multi else "FILES_ONE", ", ".join(exts)))
        # Fuera los archivos que no sirven para esta herramienta.
        self.files = [f for f in self.files if f.lower().endswith(exts)]
        if not multi:
            self.files = self.files[:1]
        self.marks = []
        self.sign_box = None
        self.order = []
        self.picked = set()
        self.page = 0
        self.build_options()
        self.refresh_files()
        self.LblHint.configure(text=T("HINT_" + interactive.upper()) if interactive else "")

    def refresh_files(self):
        self.Files.delete(0, "end")
        for f in self.files:
            self.Files.insert("end", "  " + os.path.basename(f))
        if self.files:
            self.Files.selection_set(0)
            if not self.outdir:
                self.outdir = os.path.dirname(self.files[0])
        self.BtnOut.configure(text=T("OUT_DIR", self.outdir or T("OUT_SAME")))
        if TOOLS[self.tool][5] == "organize":
            self.reset_order()
        self.load_preview()

    # ---- las opciones de cada herramienta
    def build_options(self):
        for w in self.Opts.winfo_children():
            w.destroy()
        self.vars = {}
        self.opt_row = 0
        key = TOOLS[self.tool][0]
        pdf_in = TOOLS[self.tool][3] == (".pdf",)
        add = self.add_option
        if key == "word2pdf":
            add("engine", T("OPT_ENGINE"), "choice", "auto", [("auto", T("ENGINE_AUTO")), ("basic", T("ENGINE_BASIC"))])
        elif key == "excel2pdf":
            add("orientation", T("OPT_ORIENT"), "choice", "auto",
                [("auto", T("ORIENT_AUTO")), ("portrait", T("ORIENT_PORTRAIT")), ("landscape", T("ORIENT_LANDSCAPE"))])
        elif key == "pdf2img":
            add("format", T("OPT_FORMAT"), "choice", "png", [("png", "PNG"), ("jpg", "JPG")])
            add("dpi", T("OPT_DPI"), "choice", "150", [("72", "72 ppp"), ("150", "150 ppp"), ("300", "300 ppp")])
            add("pages", T("OPT_PAGES"), "entry", "")
        elif key == "pdf2ppt":
            add("mode", T("OPT_PPT_MODE"), "choice", "image", [("image", T("PPT_IMAGE")), ("text", T("PPT_TEXT"))])
        elif key == "edit":
            add("mode", T("OPT_EDIT_MODE"), "choice", "text",
                [("text", T("EDIT_TEXT")), ("image", T("EDIT_IMAGE")), ("cover", T("EDIT_COVER"))])
            add("text", T("OPT_TEXT"), "entry", T("EDIT_SAMPLE"))
            add("size", T("OPT_SIZE"), "spin", "12", (6, 72))
            add("color", T("OPT_COLOR"), "color", "#111827")
            add("undo", T("UNDO_LAST"), "button", self.undo_mark)
        elif key == "watermark":
            add("text", T("OPT_TEXT"), "entry", T("WM_DEFAULT"))
            add("size", T("OPT_SIZE"), "spin", "60", (10, 200))
            add("opacity", T("OPT_OPACITY"), "spin", "25", (5, 100))
            add("color", T("OPT_COLOR"), "color", "#c0392b")
            add("angle", T("OPT_ANGLE"), "choice", "diagonal", [("diagonal", T("ANGLE_DIAG")), ("flat", T("ANGLE_FLAT"))])
            add("image", T("OPT_LOGO"), "file", "")
        elif key == "numbers":
            add("format", T("OPT_NUM_FORMAT"), "combo", T("NUM_FORMAT_1"), [T("NUM_FORMAT_1"), "{n}", "{n} / {total}", "- {n} -"])
            add("position", T("OPT_POSITION"), "choice", "bottom-center", [(p, T("POS_" + p.replace("-", "_").upper())) for p in NUM_POSITIONS])
            add("start", T("OPT_START"), "spin", "1", (1, 9999))
            add("size", T("OPT_SIZE"), "spin", "10", (6, 36))
            add("header", T("OPT_HEADER"), "entry", "")
            add("skip_first", T("OPT_SKIP_FIRST"), "check", False)
        elif key == "rotate":
            add("angle", T("OPT_ANGLE"), "choice", "90", [("90", T("ROT_90")), ("180", T("ROT_180")), ("270", T("ROT_270"))])
            add("pages", T("OPT_PAGES"), "entry", "")
        elif key == "annotate":
            add("type", T("OPT_NOTE_TYPE"), "choice", "note",
                [("note", T("NOTE_NOTE")), ("highlight", T("NOTE_HIGHLIGHT")), ("rect", T("NOTE_RECT")),
                 ("ellipse", T("NOTE_ELLIPSE")), ("line", T("NOTE_LINE")), ("text", T("NOTE_TEXT"))])
            add("text", T("OPT_TEXT"), "entry", T("NOTE_SAMPLE"))
            add("color", T("OPT_COLOR"), "color", "#ffd400")
            add("undo", T("UNDO_LAST"), "button", self.undo_mark)
        elif key == "merge":
            add("name", T("OPT_NAME"), "entry", T("MERGED_NAME") + ".pdf")
        elif key == "split":
            add("mode", T("OPT_SPLIT_MODE"), "choice", "each",
                [("each", T("SPLIT_EACH")), ("every", T("SPLIT_EVERY")), ("ranges", T("SPLIT_RANGES"))])
            add("every", T("OPT_EVERY"), "spin", "2", (1, 999))
            add("ranges", T("OPT_RANGES"), "entry", "1-3; 4-6")
        elif key == "organize":
            for k, label, cmd in (("left", T("ORG_LEFT"), lambda: self.org_move(-1)),
                                  ("right", T("ORG_RIGHT"), lambda: self.org_move(1)),
                                  ("rot", T("ORG_ROTATE"), self.org_rotate),
                                  ("del", T("ORG_DELETE"), self.org_delete),
                                  ("blank", T("ORG_BLANK"), self.org_blank),
                                  ("reset", T("ORG_RESET"), self.reset_order)):
                add(k, label, "button", cmd)
        elif key == "extract":
            add("pages", T("OPT_PAGES"), "entry", "1")
            add("separate", T("OPT_SEPARATE"), "check", False)
        elif key == "protect":
            add("password_new", T("OPT_NEW_PASSWORD"), "secret", "")
            add("password_again", T("OPT_REPEAT"), "secret", "")
            add("owner", T("OPT_OWNER"), "secret", "")
            add("allow_print", T("OPT_ALLOW_PRINT"), "check", True)
            add("allow_copy", T("OPT_ALLOW_COPY"), "check", True)
            add("allow_modify", T("OPT_ALLOW_MODIFY"), "check", False)
        elif key == "unlock":
            add("password", T("OPT_PASSWORD"), "secret", "")
            add("authorized", T("OPT_AUTHORIZED"), "check", False)
        elif key == "sign":
            add("name", T("OPT_SIGNER"), "entry", self.saved_signer())
            add("email", T("OPT_EMAIL"), "entry", "")
            add("reason", T("OPT_REASON"), "entry", T("REASON_DEFAULT"))
            add("location", T("OPT_LOCATION"), "entry", "")
            add("pad", T("OPT_DRAW"), "pad", None)
            add("verify", T("VERIFY"), "button", self.verify)
        elif key == "redact":
            add("terms", T("OPT_TERMS"), "entry", "")
            add("undo", T("UNDO_LAST"), "button", self.undo_mark)
        elif key == "compress":
            add("level", T("OPT_LEVEL"), "choice", "medium",
                [("light", T("LEVEL_LIGHT")), ("medium", T("LEVEL_MEDIUM")), ("strong", T("LEVEL_STRONG"))])
        elif key == "ocr":
            add("lang", T("OPT_LANG"), "choice", "es", [("es", T("LANG_ES")), ("en", T("LANG_EN"))])
            add("force", T("OPT_FORCE"), "check", False)
        if pdf_in and key not in ("protect", "unlock"):
            add("password", T("OPT_PASSWORD_IN"), "secret", "")

    def add_option(self, key, label, kind, default, extra=None):
        row = self.opt_row
        self.opt_row += 1
        if kind == "button":
            b = ttk.Button(self.Opts, text=label, command=default)
            b.grid(row=row, column=0, columnspan=2, sticky="we", pady=2)
            return
        if kind == "check":
            v = tk.BooleanVar(value=bool(default))
            ttk.Checkbutton(self.Opts, text=label, variable=v).grid(row=row, column=0, columnspan=2, sticky="w", pady=3)
            self.vars[key] = v
            return
        ttk.Label(self.Opts, text=label).grid(row=row, column=0, sticky="w", padx=(0, 8), pady=3)
        if kind == "pad":
            self.build_pad(row)
            return
        v = tk.StringVar(value=default)
        if kind == "choice":
            labels = [b for _, b in extra]
            box = ttk.Combobox(self.Opts, values=labels, state="readonly", width=26)
            box.current([a for a, _ in extra].index(default))
            box.grid(row=row, column=1, sticky="we", pady=3)
            box.choices = extra
            self.vars[key] = box
            return
        if kind == "combo":
            w = ttk.Combobox(self.Opts, textvariable=v, values=extra, width=26)
        elif kind == "spin":
            w = ttk.Spinbox(self.Opts, textvariable=v, from_=extra[0], to=extra[1], width=8)
        elif kind == "secret":
            w = ttk.Entry(self.Opts, textvariable=v, show="•", width=28)
        elif kind == "color":
            w = tk.Button(self.Opts, text=default, bg=default, fg="#ffffff", relief="flat",
                          command=lambda: self.pick_color(key))
            self.vars[key + "_button"] = w
        elif kind == "file":
            w = ttk.Button(self.Opts, text=T("CHOOSE_FILE"), command=lambda: self.pick_file(key))
            self.vars[key + "_button"] = w
        else:
            w = ttk.Entry(self.Opts, textvariable=v, width=28)
        w.grid(row=row, column=1, sticky="we", pady=3)
        self.vars[key] = v
        self.Opts.columnconfigure(1, weight=1)

    def build_pad(self, row):
        """Un recuadro para dibujar la firma con el ratón."""
        pad = tk.Canvas(self.Opts, width=220, height=70, bg="#ffffff", highlightthickness=1, highlightbackground="#9aa5b1")
        pad.grid(row=row, column=1, sticky="w", pady=3)
        self.pad_lines = []

        def down(e):
            self.pad_lines.append([(e.x, e.y)])

        def move(e):
            if self.pad_lines:
                last = self.pad_lines[-1][-1]
                self.pad_lines[-1].append((e.x, e.y))
                pad.create_line(last[0], last[1], e.x, e.y, width=2.5, fill="#1e3a8a", capstyle="round", smooth=True)

        def clear():
            self.pad_lines = []
            pad.delete("all")

        pad.bind("<Button-1>", down)
        pad.bind("<B1-Motion>", move)
        ttk.Button(self.Opts, text=T("CLEAR_DRAWING"), command=clear).grid(row=row + 1, column=1, sticky="w")
        self.opt_row += 1
        self.pad = pad

    def pad_png(self):
        """La firma dibujada como PNG con fondo transparente (o None)."""
        lines = getattr(self, "pad_lines", [])
        if not any(len(l) > 1 for l in lines):
            return None
        img = Image.new("RGBA", (660, 210), (255, 255, 255, 0))
        d = ImageDraw.Draw(img)
        for l in lines:
            d.line([(x * 3, y * 3) for x, y in l], fill=(30, 58, 138, 255), width=7, joint="curve")
        path = os.path.join(app_dir(), "firma", "dibujo.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        img.save(path)
        return path

    def pick_color(self, key):
        c = colorchooser.askcolor(color=self.vars[key].get(), parent=self.root)
        if c and c[1]:
            self.vars[key].set(c[1])
            self.vars[key + "_button"].configure(text=c[1], bg=c[1])

    def pick_file(self, key):
        p = filedialog.askopenfilename(parent=self.root, filetypes=[(T("IMAGES"), "*.png *.jpg *.jpeg")])
        if p:
            self.vars[key].set(p)
            self.vars[key + "_button"].configure(text=os.path.basename(p))

    def opt(self, key, default=""):
        v = self.vars.get(key)
        if v is None:
            return default
        if isinstance(v, ttk.Combobox) and hasattr(v, "choices"):
            i = v.current()
            return v.choices[i][0] if i >= 0 else default
        return v.get()

    def saved_signer(self):
        try:
            return json.load(open(os.path.join(app_dir(), "firma", "titular.json"), encoding="utf-8")).get("name", "")
        except Exception:
            return ""

    # ---- los archivos
    def add_files(self, paths):
        key, group, fn, exts, multi, interactive = TOOLS[self.tool]
        ok = [p for p in paths if p.lower().endswith(exts)]
        if len(ok) < len(paths):
            self.Status.set(T("WRONG_TYPE", ", ".join(exts)), icon="⚠")
        if not ok:
            return
        self.files = (self.files + ok) if multi else ok[:1]
        self.outdir = os.path.dirname(self.files[0])
        self.marks = []
        self.page = 0
        self.refresh_files()

    def BtnAdd_click(self):
        key, group, fn, exts, multi, interactive = TOOLS[self.tool]
        types = [(T("TYPES_" + exts[0].lstrip(".").upper()), " ".join("*" + e for e in exts))]
        if multi:
            paths = filedialog.askopenfilenames(parent=self.root, filetypes=types)
        else:
            p = filedialog.askopenfilename(parent=self.root, filetypes=types)
            paths = [p] if p else []
        if paths:
            self.add_files(list(paths))

    def BtnRemove_click(self):
        sel = self.Files.curselection()
        if sel:
            del self.files[sel[0]]
            self.marks = []
            self.refresh_files()

    def move_file(self, d):
        sel = self.Files.curselection()
        if not sel:
            return
        i, j = sel[0], sel[0] + d
        if 0 <= j < len(self.files):
            self.files[i], self.files[j] = self.files[j], self.files[i]
            self.refresh_files()
            self.Files.selection_clear(0, "end")
            self.Files.selection_set(j)

    def BtnUp_click(self):
        self.move_file(-1)

    def BtnDown_click(self):
        self.move_file(1)

    def Files_select(self, event=None):
        self.page = 0
        self.load_preview()

    def BtnOut_click(self):
        d = filedialog.askdirectory(parent=self.root, initialdir=self.outdir or os.path.expanduser("~"))
        if d:
            self.outdir = d
            self.BtnOut.configure(text=T("OUT_DIR", d))

    def BtnShow_click(self):
        if self.outdir:
            open_folder(self.outdir)

    # ---- la vista previa
    def current_file(self):
        sel = self.Files.curselection()
        if sel and sel[0] < len(self.files):
            return self.files[sel[0]]
        return self.files[0] if self.files else None

    def load_preview(self):
        f = self.current_file()
        self.pages = 0
        if f and f.lower().endswith(".pdf") and pdfium is not None:
            try:
                self.pages = page_count(f, self.opt("password") or None)
            except Exception:
                self.pages = 0
        self.page = min(self.page, max(0, self.pages - 1))
        self.show()

    def show(self):
        c = self.Preview
        c.delete("all")
        self.photo = None
        self.view = None
        # Antes de que se vea, el lienzo mide 1 píxel: entonces, el tamaño del diseño.
        W, H = c.winfo_width(), c.winfo_height()
        if W <= 10 or H <= 10:
            info = c.place_info() if c.winfo_manager() == "place" else {}
            try:
                W, H = int(float(info.get("width") or 520)), int(float(info.get("height") or 520))
            except ValueError:
                W, H = 520, 520
        W, H = max(200, W), max(200, H)
        f = self.current_file()
        if TOOLS[self.tool][5] == "organize" and self.files:
            self.show_grid(W, H)
            return
        if not f:
            c.create_text(W / 2, H / 2, text=T("PREVIEW_EMPTY"), fill="#8a94a6", font=("Helvetica", 14), width=max(40, W - 60))
            self.LblPage.configure(text="")
            return
        if not f.lower().endswith(".pdf") or not self.pages:
            c.create_text(W / 2, H / 2, text=T("PREVIEW_NONE", os.path.basename(f)), fill="#8a94a6",
                          font=("Helvetica", 14), width=max(40, W - 60))
            self.LblPage.configure(text="")
            return
        try:
            pdf = pdfium.PdfDocument(f, password=self.opt("password") or None)
            pdf.init_forms()
            page = pdf[self.page]
            pw, ph = page.get_size()
            s = min((W - 30) / pw, (H - 30) / ph)
            img = page.render(scale=s * 2, may_draw_forms=True).to_pil().resize((int(pw * s), int(ph * s)))
            page.close()
            pdf.close()
        except Exception as e:
            c.create_text(W / 2, H / 2, text=str(e), fill="#b91c1c", width=max(40, W - 60))
            return
        x, y = (W - img.width) / 2, (H - img.height) / 2
        c.create_rectangle(x + 4, y + 5, x + img.width + 4, y + img.height + 5, fill="#c7ced8", outline="")
        self.photo = ImageTk.PhotoImage(img)
        c.create_image(x, y, image=self.photo, anchor="nw")
        self.view = (s, x, y, pw, ph)
        self.LblPage.configure(text=T("PAGE_OF", self.page + 1, self.pages))
        self.draw_marks()

    def to_pdf(self, cx, cy):
        s, x, y, pw, ph = self.view
        return (cx - x) / s, ph - (cy - y) / s

    def to_canvas(self, px, py):
        s, x, y, pw, ph = self.view
        return x + px * s, y + (ph - py) * s

    def draw_marks(self):
        c = self.Preview
        key = TOOLS[self.tool][0]
        for m in self.marks:
            if m["page"] != self.page:
                continue
            if m["type"] == "text":
                x, y = self.to_canvas(m["x"], m["y"])
                c.create_text(x, y, text=m["text"], anchor="sw", fill=m.get("color", "#000"),
                              font=("Helvetica", max(6, int(m.get("size", 12) * self.view[0]))))
            elif m["type"] in ("image", "cover"):
                x0, y0 = self.to_canvas(m["x"], m["y"] + m["h"])
                x1, y1 = self.to_canvas(m["x"] + m["w"], m["y"])
                if m["type"] == "cover":
                    c.create_rectangle(x0, y0, x1, y1, fill="#ffffff", outline="#9aa5b1", dash=(3, 2))
                else:
                    c.create_rectangle(x0, y0, x1, y1, outline="#2563eb", width=2)
                    c.create_text((x0 + x1) / 2, (y0 + y1) / 2, text=os.path.basename(m["path"]), fill="#2563eb")
            else:
                x0, y0 = self.to_canvas(m["x0"], m["y0"])
                x1, y1 = self.to_canvas(m["x1"], m["y1"])
                if key == "redact":
                    c.create_rectangle(x0, y0, x1, y1, fill="#000000", stipple="gray50", outline="#000000")
                elif m["type"] == "note":
                    c.create_rectangle(x0, y1 - 16, x0 + 16, y1, fill="#ffd400", outline="#a16207")
                elif m["type"] == "line":
                    c.create_line(x0, y0, x1, y1, fill=m.get("color", "#d00"), width=2)
                elif m["type"] == "ellipse":
                    c.create_oval(x0, y0, x1, y1, outline=m.get("color", "#d00"), width=2)
                elif m["type"] == "highlight":
                    c.create_rectangle(x0, y0, x1, y1, fill=m.get("color", "#ffd400"), stipple="gray50", outline="")
                elif m["type"] == "text":
                    c.create_text(x0, y1, text=m.get("text", ""), anchor="nw")
                else:
                    c.create_rectangle(x0, y0, x1, y1, outline=m.get("color", "#d00"), width=2)
        if key == "sign" and self.sign_box and self.sign_box[0] == self.page:
            _, (a, b, cc, d) = self.sign_box
            x0, y0 = self.to_canvas(a, d)
            x1, y1 = self.to_canvas(cc, b)
            c.create_rectangle(x0, y0, x1, y1, outline="#b91c1c", width=2, dash=(4, 2))
            c.create_text((x0 + x1) / 2, (y0 + y1) / 2, text=T("SIGN_HERE"), fill="#b91c1c")

    def BtnPrev_click(self):
        if self.page > 0:
            self.page -= 1
            self.show()

    def BtnNext_click(self):
        if self.page < self.pages - 1:
            self.page += 1
            self.show()

    # Clic y arrastre en la vista, según la herramienta.
    def Preview_mouse_down(self, event):
        key = TOOLS[self.tool][0]
        if key == "organize":
            self.org_click(event)
            return
        if not self.view:
            return
        px, py = self.to_pdf(event.x, event.y)
        self.drag = (event.x, event.y, px, py)
        mode = self.opt("mode") if key == "edit" else self.opt("type") if key == "annotate" else None
        if key == "edit" and mode == "text":
            text = self.opt("text") or simpledialog.askstring(T("TOOL_EDIT"), T("OPT_TEXT"), parent=self.root)
            if text:
                size = float(self.opt("size", "12") or 12)
                self.marks.append({"page": self.page, "type": "text", "x": px, "y": py, "text": text, "size": size,
                                   "color": self.opt("color", "#111827")})
                self.drag = None
                self.show()
        elif key == "edit" and mode == "image":
            p = filedialog.askopenfilename(parent=self.root, filetypes=[(T("IMAGES"), "*.png *.jpg *.jpeg")])
            if p:
                iw, ih = Image.open(p).size
                w = min(200.0, iw * 0.75)
                h = w * ih / iw
                self.marks.append({"page": self.page, "type": "image", "x": px, "y": py - h, "w": w, "h": h, "path": p})
                self.show()
            self.drag = None
        elif key == "annotate" and mode == "note":
            self.marks.append({"page": self.page, "type": "note", "x0": px, "y0": py - 24, "x1": px + 24, "y1": py,
                               "text": self.opt("text"), "color": self.opt("color", "#ffd400")})
            self.drag = None
            self.show()
        elif key == "sign":
            w, h = 220, 70
            self.sign_box = (self.page, (px - w / 2, py - h / 2, px + w / 2, py + h / 2))
            self.drag = None
            self.show()

    def Preview_drag(self, event):
        if not self.drag or not self.view:
            return
        self.show()
        x0, y0 = self.drag[0], self.drag[1]
        self.Preview.create_rectangle(x0, y0, event.x, event.y, outline="#2563eb", dash=(3, 2), width=2)

    def Preview_mouse_up(self, event):
        if not self.drag or not self.view:
            return
        key = TOOLS[self.tool][0]
        _, _, px0, py0 = self.drag
        self.drag = None
        px1, py1 = self.to_pdf(event.x, event.y)
        if abs(px1 - px0) < 3 and abs(py1 - py0) < 3:
            self.show()
            return
        x0, x1 = sorted((px0, px1))
        y0, y1 = sorted((py0, py1))
        if key == "edit":
            self.marks.append({"page": self.page, "type": "cover", "x": x0, "y": y0, "w": x1 - x0, "h": y1 - y0,
                               "color": "#ffffff"})
        elif key == "annotate":
            kind = self.opt("type")
            if kind == "line":
                self.marks.append({"page": self.page, "type": "line", "x0": px0, "y0": py0, "x1": px1, "y1": py1,
                                   "color": self.opt("color"), "text": self.opt("text")})
            else:
                self.marks.append({"page": self.page, "type": kind, "x0": x0, "y0": y0, "x1": x1, "y1": y1,
                                   "color": self.opt("color"), "text": self.opt("text")})
        elif key == "redact":
            self.marks.append({"page": self.page, "type": "box", "x0": x0, "y0": y0, "x1": x1, "y1": y1})
        self.show()

    def undo_mark(self):
        if self.marks:
            self.marks.pop()
            self.show()

    # ---- organizar: miniaturas
    def reset_order(self):
        self.order = []
        for si, f in enumerate(self.files):
            try:
                n = page_count(f, self.opt("password") or None)
            except Exception:
                n = 0
            self.order += [{"src": si, "page": p, "rot": 0} for p in range(n)]
        self.picked = set()
        self.show()

    def show_grid(self, W, H):
        c = self.Preview
        self.thumbs = []
        self.grid_cells = []
        tw, th, gap = 110, 150, 16
        cols = max(1, int((W - gap) // (tw + gap)))
        cache = {}
        for k, item in enumerate(self.order):
            col, row = k % cols, k // cols
            x, y = gap + col * (tw + gap), gap + row * (th + gap + 18)
            if y > H:
                break
            sel = k in self.picked
            c.create_rectangle(x - 4, y - 4, x + tw + 4, y + th + 4, outline="#2563eb" if sel else "", width=3)
            if item["src"] < 0:
                c.create_rectangle(x, y, x + tw, y + th, fill="#ffffff", outline="#cbd2d9")
            else:
                try:
                    img = render(self.files[item["src"]], item["page"], 0.35, self.opt("password") or None)
                    if item.get("rot"):
                        img = img.rotate(-item["rot"], expand=True)
                    img.thumbnail((tw, th))
                    ph = ImageTk.PhotoImage(img)
                    self.thumbs.append(ph)
                    c.create_image(x + (tw - img.width) / 2, y + (th - img.height) / 2, image=ph, anchor="nw")
                except Exception:
                    c.create_rectangle(x, y, x + tw, y + th, fill="#eeeeee")
            label = str(k + 1) if item["src"] < 0 else "%d · %s %d" % (k + 1, T("PAGE_SHORT"), item["page"] + 1)
            c.create_text(x + tw / 2, y + th + 12, text=label, fill="#334155", font=("Helvetica", 10))
            self.grid_cells.append((x, y, tw, th, k))
        self.LblPage.configure(text=T("ORG_COUNT", len(self.order), len(self.picked)))

    def org_click(self, event):
        for (x, y, w, h, k) in getattr(self, "grid_cells", []):
            if x <= event.x <= x + w and y <= event.y <= y + h:
                if k in self.picked:
                    self.picked.discard(k)
                else:
                    self.picked.add(k)
                self.show()
                return

    def org_move(self, d):
        if not self.picked:
            return
        idx = sorted(self.picked, reverse=d > 0)
        new = set()
        for k in idx:
            j = k + d
            if 0 <= j < len(self.order) and j not in new:
                self.order[k], self.order[j] = self.order[j], self.order[k]
                new.add(j)
            else:
                new.add(k)
        self.picked = new
        self.show()

    def org_rotate(self):
        for k in self.picked:
            self.order[k]["rot"] = (self.order[k].get("rot", 0) + 90) % 360
        self.show()

    def org_delete(self):
        self.order = [it for k, it in enumerate(self.order) if k not in self.picked]
        self.picked = set()
        self.show()

    def org_blank(self):
        at = (max(self.picked) + 1) if self.picked else len(self.order)
        self.order.insert(at, {"src": -1, "page": 0, "rot": 0})
        self.show()

    # ---- firmar: verificar
    def verify(self):
        p = filedialog.askopenfilename(parent=self.root, filetypes=[("PDF", "*.pdf")])
        if not p:
            return
        try:
            sigs = verify_signatures(p)
        except Exception as e:
            messagebox.showerror(T("VERIFY"), str(e), parent=self.root)
            return
        if not sigs:
            messagebox.showinfo(T("VERIFY"), T("NO_SIGNATURES"), parent=self.root)
            return
        lines = [T("SIG_LINE", who, T("SIG_OK") if ok else T("SIG_BAD"), T("SIG_TRUSTED") if trusted else T("SIG_UNKNOWN"), when)
                 for (who, ok, trusted, when) in sigs]
        messagebox.showinfo(T("VERIFY"), "\n\n".join(lines), parent=self.root)

    # ---- hacerlo
    def collect(self):
        key = TOOLS[self.tool][0]
        o = {k: self.opt(k) for k in self.vars if not k.endswith("_button")}
        if key == "edit":
            o["edits"] = list(self.marks)
        elif key == "annotate":
            o["annotations"] = list(self.marks)
        elif key == "organize":
            o["order"] = list(self.order)
        elif key == "redact":
            o["boxes"] = list(self.marks)
            o["terms"] = [t for t in re.split(r"[,;\n]", self.opt("terms")) if t.strip()]
        elif key == "sign":
            if self.sign_box:
                o["page"], o["box"] = self.sign_box[0], list(self.sign_box[1])
            else:
                o["page"] = self.page
            o["drawing"] = self.pad_png()
        elif key == "protect" and o.get("password_new") != o.get("password_again"):
            raise ValueError(T("PASSWORDS_DIFFER"))
        return o

    def BtnRun_click(self):
        if self.busy:
            return
        if MISSING:
            messagebox.showerror(APP, T("MISSING", ", ".join(MISSING), PIP + " -m pip install " + " ".join(MISSING)), parent=self.root)
            return
        if not self.files:
            self.Status.set(T("NEED_FILES"), icon="⚠")
            return
        try:
            opts = self.collect()
        except Exception as e:
            self.Status.set(str(e), icon="⚠")
            return
        key = TOOLS[self.tool][0]
        if key in ("edit", "annotate", "redact") and not self.marks and not opts.get("terms"):
            self.Status.set(T("NEED_MARKS"), icon="⚠")
            return
        outdir = self.outdir or os.path.dirname(self.files[0])
        fn = TOOLS[self.tool][2]
        files = list(self.files)
        self.busy = True
        self.BtnRun.configure(state="disabled")
        self.Status.set(T("WORKING"), icon="⏳")
        self.done = None

        def work():
            try:
                self.done = ("ok", fn(files, outdir, opts, self.progress))
            except Exception as e:
                self.done = ("error", e)

        self.worker = threading.Thread(target=work, daemon=True)
        self.worker.start()
        self.root.after(100, self.poll)

    def progress(self, a, b):
        self.prog = (a, b)

    def poll(self):
        if self.done is None:
            p = getattr(self, "prog", None)
            if p:
                self.Status.set(T("PROGRESS", p[0], p[1]), icon="⏳")
            self.root.after(100, self.poll)
            return
        self.busy = False
        self.prog = None
        self.BtnRun.configure(state="normal")
        kind, value = self.done
        if kind == "ok":
            names = ", ".join(os.path.basename(f) for f in value["files"][:3])
            more = "" if len(value["files"]) <= 3 else T("AND_MORE", len(value["files"]) - 3)
            self.Status.set(T("DONE", names + more), icon="✓")
            self.last_result = value
            self.LblResult.configure(text=value["message"])
        else:
            self.Status.set(T("FAILED", value), icon="⚠")
            self.LblResult.configure(text=str(value))

    def wait(self, timeout=120):
        """Para las pruebas: espera a que termine el trabajo."""
        end = time.time() + timeout
        while self.busy and time.time() < end:
            self.root.update()
            time.sleep(0.05)
        self.root.update()

    def Menu1_click(self, item):
        if item == T("MP_OPEN"):
            self.BtnAdd_click()
        elif item == T("MP_CLEAR"):
            self.files = []
            self.marks = []
            self.refresh_files()
        elif item == T("MP_SHOW"):
            self.BtnShow_click()
        elif item == T("MP_QUIT"):
            self.root.destroy()
        elif item == T("MP_HOW"):
            messagebox.showinfo(APP, T("HOW_TEXT"), parent=self.root)
        elif item == T("MP_ABOUT"):
            messagebox.showinfo(APP, T("ABOUT_TEXT"), parent=self.root)

    def form_close(self, *args):
        self.root.destroy()


def open_folder(path):
    if sys.platform == "darwin":
        subprocess.Popen(["open", path])
    elif sys.platform.startswith("win"):
        os.startfile(path)
    else:
        subprocess.Popen(["xdg-open", path])


PIP = "py" if sys.platform.startswith("win") else "python3"
APP = "20pdf"


def selftest():
    """Sin ventana (DMS_20PDF_SELFTEST=1): las bibliotecas que van dentro de la
    app funcionan (crear, leer, pintar, convertir, cifrar, firmar y el OCR)."""
    fails = []
    if MISSING:
        fails.append("faltan: " + ", ".join(MISSING))
        print("FAIL", fails[-1])
        return 1
    work = tempfile.mkdtemp()
    os.environ.setdefault("DMS_20PDF_CONFIG", os.path.join(work, "config"))
    pdf = os.path.join(work, "prueba.pdf")
    c = rl_canvas.Canvas(pdf, pagesize=A4)
    c.setFont("Helvetica", 24)
    c.drawString(72, 760, "Prueba de 20pdf 2026")
    c.showPage()
    c.save()
    d = docx.Document()
    d.add_heading("Informe", 1)
    d.add_paragraph("Hola desde 20pdf")
    dx = os.path.join(work, "informe.docx")
    d.save(dx)
    wb = openpyxl.Workbook()
    wb.active.append(["Producto", "Precio"])
    wb.active.append(["Pan", 1.5])
    xl = os.path.join(work, "precios.xlsx")
    wb.save(xl)
    checks = [
        ("word2pdf", lambda: "20pdf" in PdfReader(word_to_pdf([dx], work, {"engine": "basic"})["files"][0]).pages[0].extract_text()),
        ("excel2pdf", lambda: "Pan" in PdfReader(excel_to_pdf([xl], work, {})["files"][0]).pages[0].extract_text()),
        ("pdfium", lambda: render(pdf, 0, 0.5).width > 100),
        ("pdfminer", lambda: "20pdf" in " ".join(l[5] for l in _lines(pdf))),
        ("word", lambda: os.path.exists(pdf_to_word([pdf], work, {})["files"][0])),
        ("pptx", lambda: os.path.exists(pdf_to_pptx([pdf], work, {})["files"][0])),
        ("protect", lambda: PdfReader(protect([pdf], work, {"password_new": "x"})["files"][0]).is_encrypted),
        ("sign", lambda: verify_signatures(sign([pdf], work, {"name": "Prueba"})["files"][0])[0][1]),
    ]
    if sys.platform == "darwin":
        img = os.path.join(work, "t.png")
        render(pdf, 0, 3).save(img)
        checks.append(("vision", lambda: any("20pdf" in w[0] for w in ocr_image(img, "es"))))
    for name, fn in checks:
        try:
            ok = fn()
        except Exception as e:
            ok = False
            print("  %s: %s" % (name, e))
        if not ok:
            fails.append(name)
            print("FAIL", name)
    shutil.rmtree(work, ignore_errors=True)
    if not fails:
        print("selftest ok")
    return 1 if fails else 0


if os.environ.get("DMS_20PDF_SELFTEST"):
    sys.exit(selftest())
''';
