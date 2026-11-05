/// Código de Python del componente Gráfico. El núcleo ([core]) guarda los
/// datos y dibuja con unas pocas primitivas; la ventana ([designChart]) las
/// pinta en un tk.Canvas y la página ([webChart]), en un SVG. Así los dos
/// destinos dibujan exactamente lo mismo.
///
/// Colores: la paleta categórica validada (orden fijo, nunca se repite: a
/// partir de la novena serie, gris), verde y rojo de estado para las velas
/// (la que sube, hueca; la que baja, rellena: no solo el color) y tintas de
/// texto, rejilla y ejes neutras. Un solo eje Y; el volumen va en un panel
/// aparte debajo del precio.
class TkChart {
  TkChart._();

  static const core = r'''


import math

CHART_COLORS = (
    "#2a78d6", "#eb6834", "#1baf7a", "#eda100",
    "#e87ba4", "#008300", "#6250d6", "#e34948",
)
CHART_OTHER = "#898781"
CHART_UP, CHART_DOWN = "#0ca30c", "#d03b3b"
CHART_SURFACE = "#fcfcfb"
CHART_INK, CHART_INK2, CHART_MUTED = "#0b0b0b", "#52514e", "#898781"
CHART_GRID, CHART_AXIS = "#e1e0d9", "#c3c2b7"


def nice_ticks(lo, hi, count=5):
    """Round values for an axis that covers lo..hi ("nice numbers")."""
    lo, hi = float(lo), float(hi)
    if hi < lo:
        lo, hi = hi, lo
    if hi == lo:
        pad = abs(lo) * 0.1 or 1.0
        lo, hi = lo - pad, hi + pad

    def nice(x, rounding):
        exp = math.floor(math.log10(x))
        f = x / 10 ** exp
        if rounding:
            n = 1 if f < 1.5 else 2 if f < 3 else 5 if f < 7 else 10
        else:
            n = 1 if f <= 1 else 2 if f <= 2 else 5 if f <= 5 else 10
        return n * 10 ** exp

    step = nice(nice(hi - lo, False) / max(1, count - 1), True)
    value = math.floor(lo / step) * step
    ticks = [round(value, 10)]
    # Up to hi: the last tick is never below the maximum.
    while ticks[-1] < hi - step * 1e-9 or len(ticks) < 2:
        value += step
        ticks.append(round(value, 10))
    return ticks


def chart_blend(color, alpha, base=CHART_SURFACE):
    """color over base with some transparency (Tk has no alpha)."""
    c = [int(color[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(base[i:i + 2], 16) for i in (1, 3, 5)]
    return "#%02x%02x%02x" % tuple(
        int(round(b[k] + (c[k] - b[k]) * alpha)) for k in range(3)
    )


def chart_short(value):
    """1234567 -> 1.2M, for the volume axis."""
    v = abs(value)
    for limit, suffix in ((1e9, "B"), (1e6, "M"), (1e3, "K")):
        if v >= limit:
            return "%.1f%s" % (value / limit, suffix)
    return "%d" % value


class ChartCore:
    """Data and drawing of a chart: the same on a window and on a page.

    set_series(name, values, x=None), add_point(name, value, x=None),
    set_candles(rows), add_candle(x, open, high, low, close, volume=None),
    show_series(name, visible), remove_series(name), clear(), set_title(t),
    set_kind(kind), set_labels(x=None, y=None), set_max_points(count) and
    set_format(decimals=None, prefix=None, suffix=None).
    """

    KINDS = ("line", "area", "bar", "candles")

    def _chart_init(self, options):
        self._opts = {
            "kind": "line", "title": "", "xlabel": "", "ylabel": "",
            "legend": True, "grid": True, "decimals": 0, "prefix": "",
            "suffix": "", "maxpoints": 0,
        }
        for key, value in options.items():
            if key in self._opts:
                self._opts[key] = value
        self._series = {}
        self._slots = {}
        self._hidden = set()
        self._candles = []
        self._spots = []

    def _changed(self):
        """Draw again (each destination knows how)."""

    # -- data
    def _slot(self, name):
        if name not in self._slots:
            self._slots[name] = len(self._slots)
        return self._slots[name]

    def color(self, name):
        """Fixed color of a series: it follows the series, not its rank."""
        slot = self._slot(name)
        return CHART_COLORS[slot] if slot < len(CHART_COLORS) else CHART_OTHER

    def _trim(self, rows):
        limit = int(self._opts.get("maxpoints") or 0)
        return rows[-limit:] if limit > 0 else rows

    def labels(self):
        """The x values, in order (candles first, then the series)."""
        seen, out = set(), []
        for x in [c[0] for c in self._candles] + [
            x for rows in self._series.values() for x, _ in rows
        ]:
            if x not in seen:
                seen.add(x)
                out.append(x)
        return out

    @staticmethod
    def _next(last, count):
        try:
            return str(int(float(last)) + 1)
        except (TypeError, ValueError):
            return str(count + 1)

    def set_series(self, name, values, x=None):
        """Replace a series. Without x, the x of the chart (or 1, 2, 3...)."""
        values = [float(v) for v in values]
        if x is None:
            labels = self.labels()
            if len(labels) == len(values):
                x = labels
            else:
                x = [str(i + 1) for i in range(len(values))]
        self._slot(name)
        self._series[name] = self._trim(
            [(str(a), b) for a, b in zip(x, values)]
        )
        self._changed()

    def add_point(self, name, value, x=None):
        """Add a point at the end; with max points, the oldest goes."""
        rows = list(self._series.get(name, []))
        self._slot(name)
        if x is None:
            x = self._next(rows[-1][0], len(rows)) if rows else "1"
        rows.append((str(x), float(value)))
        self._series[name] = self._trim(rows)
        self._changed()

    def values(self, name):
        return [y for _, y in self._series.get(name, [])]

    def remove_series(self, name):
        self._series.pop(name, None)
        self._changed()

    def show_series(self, name, visible=True):
        if visible:
            self._hidden.discard(name)
        else:
            self._hidden.add(name)
        self._changed()

    @staticmethod
    def _candle(row):
        row = list(row)
        volume = float(row[5]) if len(row) > 5 and row[5] is not None else None
        return (str(row[0]), float(row[1]), float(row[2]), float(row[3]),
                float(row[4]), volume)

    def set_candles(self, rows):
        """Rows of (x, open, high, low, close[, volume])."""
        self._candles = self._trim([self._candle(r) for r in rows])
        self._changed()

    def add_candle(self, x, open, high, low, close, volume=None):
        self._candles = self._trim(
            self._candles + [self._candle((x, open, high, low, close, volume))]
        )
        self._changed()

    def candles(self):
        return list(self._candles)

    def clear(self):
        """No data (each series keeps its color)."""
        self._series = {}
        self._candles = []
        self._changed()

    def set_title(self, text):
        self._opts["title"] = str(text or "")
        self._changed()

    def set_kind(self, kind):
        self._opts["kind"] = kind if kind in self.KINDS else "line"
        self._changed()

    def set_labels(self, x=None, y=None):
        if x is not None:
            self._opts["xlabel"] = str(x)
        if y is not None:
            self._opts["ylabel"] = str(y)
        self._changed()

    def set_format(self, decimals=None, prefix=None, suffix=None):
        if decimals is not None:
            self._opts["decimals"] = int(decimals)
        if prefix is not None:
            self._opts["prefix"] = str(prefix)
        if suffix is not None:
            self._opts["suffix"] = str(suffix)
        self._changed()

    def set_max_points(self, count):
        """Keep only the last count points (0 = all), now and from now on."""
        self._opts["maxpoints"] = max(0, int(count or 0))
        self._series = {n: self._trim(rows) for n, rows in self._series.items()}
        self._candles = self._trim(self._candles)
        self._changed()

    def fmt(self, value):
        """A value with the chart's decimals, prefix and suffix."""
        decimals = max(0, int(self._opts.get("decimals") or 0))
        text = "{:,.{}f}".format(value, decimals)
        return "%s%s%s" % (self._opts.get("prefix") or "", text,
                           self._opts.get("suffix") or "")

    # -- drawing
    def _draw(self, p, width, height):
        """Draw with the primitives of p: rect, line, polygon, oval, text
        and hotspot (the area of each x, with its values as text).
        """
        o = self._opts
        self._spots = []
        kind = o.get("kind") if o.get("kind") in self.KINDS else "line"
        p.rect(0, 0, width, height, CHART_SURFACE, CHART_GRID)
        shown = [
            n for n, rows in self._series.items() if rows and n not in self._hidden
        ]
        candles = self._candles if kind == "candles" else []
        top = 10
        if o.get("title"):
            p.text(12, top, o["title"], "nw", CHART_INK, 11, True)
            top += 22
        items = [(n, self.color(n)) for n in shown]
        if candles and items:
            items.insert(0, (None, None))
        if o.get("legend") and len(items) >= 2:
            x = 12
            for name, color in items:
                if name is None:
                    p.rect(x, top + 2, x + 6, top + 12, CHART_SURFACE, CHART_UP)
                    p.rect(x + 9, top + 2, x + 15, top + 12, CHART_DOWN, CHART_DOWN)
                    x += 21
                    label = "OHLC"
                else:
                    p.line([(x, top + 7), (x + 16, top + 7)], color, 2)
                    x += 21
                    label = str(name)
                p.text(x, top + 7, label, "w", CHART_INK2, 9)
                x += 7 * len(label) + 16
            top += 20
        if not shown and not candles:
            p.text(width / 2, (top + height) / 2, "-", "center", CHART_MUTED, 11)
            return
        seen, labels = set(), []
        for x in [c[0] for c in candles] + [
            x for n in shown for x, _ in self._series[n]
        ]:
            if x not in seen:
                seen.add(x)
                labels.append(x)
        labels = labels or [""]
        index = {x: i for i, x in enumerate(labels)}
        values = {n: dict(self._series[n]) for n in shown}
        ys = [y for n in shown for y in values[n].values()]
        ys += [c[2] for c in candles] + [c[3] for c in candles]
        lo, hi = min(ys), max(ys)
        if kind in ("bar", "area"):
            lo, hi = min(lo, 0.0), max(hi, 0.0)
        ticks = nice_ticks(lo, hi, 5)
        y_min, y_max = ticks[0], ticks[-1]
        tick_text = [self.fmt(t) for t in ticks]
        left = 12 + max(len(t) for t in tick_text) * 6.5 + 8
        if o.get("ylabel"):
            left += 18
        right = width - 12
        if kind in ("line", "area") and shown:
            right -= max(len(self.fmt(self._series[n][-1][1])) for n in shown) * 6.5 + 12
        floor = height - 22 - (16 if o.get("xlabel") else 0)
        bottom = floor
        volumes = [c[5] for c in candles if c[5] is not None]
        vol_top = None
        if volumes:
            vol_top = floor - max(24.0, (floor - top) * 0.22)
            bottom = vol_top - 10
        if bottom - top < 30 or right - left < 30:
            return
        count = len(labels)
        band = (right - left) / count

        def X(i):
            return left + (i + 0.5) * band

        def Y(v):
            return bottom - (v - y_min) / (y_max - y_min) * (bottom - top)

        for t, s in zip(ticks, tick_text):
            y = Y(t)
            if o.get("grid"):
                p.line([(left, y), (right, y)], CHART_GRID, 1)
            p.text(left - 6, y, s, "e", CHART_INK2, 9)
        p.line([(left, bottom), (right, bottom)], CHART_AXIS, 1)
        if kind in ("bar", "area") and y_min < 0 < y_max:
            p.line([(left, Y(0)), (right, Y(0))], CHART_AXIS, 1)
        step = max(1, int(math.ceil(count / max(1.0, (right - left) / 64.0))))
        shown_x = [i for i in range(count) if i % step == 0]
        if count - 1 not in shown_x and (not shown_x or count - 1 - shown_x[-1] >= step / 2.0):
            shown_x.append(count - 1)
        for i in shown_x:
            p.text(X(i), floor + 6, labels[i], "n", CHART_INK2, 9)
        if o.get("xlabel"):
            p.text((left + right) / 2, height - 6, o["xlabel"], "s", CHART_MUTED, 9)
        if o.get("ylabel"):
            p.text(14, (top + bottom) / 2, o["ylabel"], "center", CHART_MUTED, 9,
                   angle=90)
        # Candles and volume.
        if candles:
            body = max(1.0, band * 0.6)
            for x, op, hi_, lo_, cl, vol in candles:
                cx = X(index[x])
                up = cl >= op
                color = CHART_UP if up else CHART_DOWN
                p.line([(cx, Y(hi_)), (cx, Y(lo_))], color, 1)
                y0, y1 = Y(max(op, cl)), Y(min(op, cl))
                if y1 - y0 < 1:
                    y1 = y0 + 1
                p.rect(cx - body / 2, y0, cx + body / 2, y1,
                       CHART_SURFACE if up else color, color)
            if volumes:
                top_vol = max(volumes) or 1.0
                p.line([(left, floor), (right, floor)], CHART_AXIS, 1)
                p.text(left - 6, vol_top, chart_short(top_vol), "e", CHART_INK2, 9)
                for x, op, hi_, lo_, cl, vol in candles:
                    if vol is None:
                        continue
                    cx = X(index[x])
                    h = (floor - vol_top) * (vol / top_vol)
                    color = CHART_UP if cl >= op else CHART_DOWN
                    p.rect(cx - body / 2, floor - h, cx + body / 2, floor,
                           chart_blend(color, 0.45), "")
        # Bars, grouped: a gap of 2 px between them.
        if kind == "bar" and shown:
            group = band * 0.8
            gap = 2.0
            bw = max(1.0, (group - gap * (len(shown) - 1)) / len(shown))
            for j, n in enumerate(shown):
                for x, y in self._series[n]:
                    x0 = X(index[x]) - group / 2 + j * (bw + gap)
                    y0, y1 = Y(max(y, 0.0)), Y(min(y, 0.0))
                    p.rect(x0, y0, x0 + bw, max(y1, y0 + 1), self.color(n), "")
        # Lines (and areas, and the lines over the candles).
        if kind != "bar":
            for n in shown:
                rows = [(index[x], y) for x, y in self._series[n] if x in index]
                if not rows:
                    continue
                pts = [(X(i), Y(y)) for i, y in rows]
                if kind == "area":
                    base = Y(max(y_min, 0.0))
                    p.polygon(
                        [(pts[0][0], base)] + pts + [(pts[-1][0], base)],
                        chart_blend(self.color(n), 0.18),
                    )
                if len(pts) > 1:
                    p.line(pts, self.color(n), 2)
                last = pts[-1]
                p.oval(last[0], last[1], 4, self.color(n), CHART_SURFACE)
                if kind != "candles":
                    p.text(last[0] + 8, last[1], self.fmt(rows[-1][1]), "w",
                           CHART_INK, 9)
        # The area of each x, with its values: tooltip and hover.
        candle_at = {c[0]: c for c in candles}
        end = floor if volumes else bottom
        for i, x in enumerate(labels):
            lines = [x]
            c = candle_at.get(x)
            if c is not None:
                lines.append("O %s  H %s" % (self.fmt(c[1]), self.fmt(c[2])))
                lines.append("L %s  C %s" % (self.fmt(c[3]), self.fmt(c[4])))
                if c[5] is not None:
                    lines.append("V %s" % chart_short(c[5]))
            for n in shown:
                if x in values[n]:
                    lines.append("%s: %s" % (n, self.fmt(values[n][x])))
            x0 = left + i * band
            points = [
                (Y(values[n][x]), self.color(n)) for n in shown if x in values[n]
            ]
            self._spots.append((x0, top, x0 + band, end, X(i), "\n".join(lines),
                                points))
            p.hotspot(x0, top, x0 + band, end, "\n".join(lines))
''';

  static const designChart = r'''


class _TkChartPainter:
    """The primitives of ChartCore on a tk.Canvas."""

    def __init__(self, canvas):
        self.c = canvas

    @staticmethod
    def _flat(points):
        return [v for point in points for v in point]

    def rect(self, x0, y0, x1, y1, fill, outline):
        self.c.create_rectangle(x0, y0, x1, y1, fill=fill or "",
                                outline=outline or "", tags="chart")

    def line(self, points, color, width=1):
        self.c.create_line(*self._flat(points), fill=color, width=width,
                           capstyle="round", joinstyle="round", tags="chart")

    def polygon(self, points, fill):
        self.c.create_polygon(*self._flat(points), fill=fill, outline="",
                              tags="chart")

    def oval(self, x, y, r, fill, outline):
        self.c.create_oval(x - r, y - r, x + r, y + r, fill=fill,
                           outline=outline, width=1, tags="chart")

    def text(self, x, y, text, anchor, color, size, bold=False, angle=0):
        font = ("Helvetica", size + 2, "bold" if bold else "normal")
        try:
            self.c.create_text(x, y, text=text, anchor=anchor, fill=color,
                               font=font, angle=angle, tags="chart")
        except tk.TclError:
            # Tk 8.5 (the one of macOS) does not turn text.
            self.c.create_text(x, y, text=text, anchor=anchor, fill=color,
                               font=font, tags="chart")

    def hotspot(self, *args):
        pass


class DesignChart(tk.Canvas, ChartCore):
    """Line, area, bar or candlestick chart on a canvas.

    It draws again when it changes size; the mouse shows the values of the
    x under it, and a click calls the point event with them.
    """

    def __init__(self, master, command=None, **options):
        tk.Canvas.__init__(self, master, bg=CHART_SURFACE,
                           highlightthickness=0, bd=0)
        self._chart_init(options)
        self._command = command
        self._job = None
        self.bind("<Configure>", lambda e: self._changed(), add="+")
        self.bind("<Motion>", self._hover, add="+")
        self.bind("<Leave>", lambda e: self.delete("hover"), add="+")
        self.bind("<Button-1>", self._click, add="+")

    def _changed(self):
        # Many changes in a row draw once.
        if self._job is None:
            self._job = self.after_idle(self.redraw)

    def redraw(self):
        """Draw now."""
        self._job = None
        self.delete("chart")
        self.delete("hover")
        w, h = self.winfo_width(), self.winfo_height()
        if w < 20 or h < 20:
            w = int(self.cget("width") or 0)
            h = int(self.cget("height") or 0)
        self._draw(_TkChartPainter(self), w, h)

    def _spot(self, x, y):
        for spot in self._spots:
            if spot[0] <= x < spot[2] and spot[1] <= y <= spot[3]:
                return spot
        return None

    def _hover(self, event):
        self.delete("hover")
        spot = self._spot(event.x, event.y)
        if spot is None:
            return
        x0, top, x1, end, cx, text, points = spot
        self.create_line(cx, top, cx, end, fill=CHART_AXIS, dash=(3, 3),
                         tags="hover")
        for y, color in points:
            self.create_oval(cx - 4, y - 4, cx + 4, y + 4, fill=color,
                             outline=CHART_SURFACE, tags="hover")
        right = cx + 12 + 160 < self.winfo_width()
        item = self.create_text(cx + 12 if right else cx - 12, top + 4,
                                text=text, anchor="nw" if right else "ne",
                                fill=CHART_INK, font=("Helvetica", 11),
                                justify="left", tags="hover")
        box = self.bbox(item)
        if box:
            back = self.create_rectangle(box[0] - 6, box[1] - 4, box[2] + 6,
                                         box[3] + 4, fill="#ffffff",
                                         outline=CHART_AXIS, tags="hover")
            self.tag_lower(back, item)

    def _click(self, event):
        spot = self._spot(event.x, event.y)
        if spot is None or self._command is None:
            return
        x = spot[5].split("\n")[0]
        point = {
            "x": x,
            "index": self.labels().index(x) if x in self.labels() else -1,
            "values": {
                n: dict(rows)[x] for n, rows in self._series.items()
                if x in dict(rows)
            },
        }
        self._command(point)
''';

  static const webChart = r'''


import html


class _SvgChartPainter:
    """The primitives of ChartCore as SVG (the tooltip of each x is a title)."""

    ANCHORS = {
        "nw": ("start", "hanging"), "n": ("middle", "hanging"),
        "ne": ("end", "hanging"), "w": ("start", "central"),
        "center": ("middle", "central"), "e": ("end", "central"),
        "sw": ("start", "auto"), "s": ("middle", "auto"),
        "se": ("end", "auto"),
    }

    def __init__(self):
        self.parts = []
        self.spots = []

    @staticmethod
    def _e(text):
        return html.escape(str(text), quote=True)

    @staticmethod
    def _n(v):
        return "%.1f" % v

    def rect(self, x0, y0, x1, y1, fill, outline):
        self.parts.append(
            '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"%s/>' % (
                self._n(min(x0, x1)), self._n(min(y0, y1)),
                self._n(abs(x1 - x0)), self._n(abs(y1 - y0)), fill or "none",
                ' stroke="%s"' % outline if outline else "",
            )
        )

    def line(self, points, color, width=1):
        pts = " ".join("%s,%s" % (self._n(x), self._n(y)) for x, y in points)
        self.parts.append(
            '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" '
            'stroke-linecap="round" stroke-linejoin="round"/>' % (pts, color, width)
        )

    def polygon(self, points, fill):
        pts = " ".join("%s,%s" % (self._n(x), self._n(y)) for x, y in points)
        self.parts.append('<polygon points="%s" fill="%s"/>' % (pts, fill))

    def oval(self, x, y, r, fill, outline):
        self.parts.append(
            '<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="%s"/>' % (
                self._n(x), self._n(y), r, fill, outline,
            )
        )

    def text(self, x, y, text, anchor, color, size, bold=False, angle=0):
        h, v = self.ANCHORS.get(anchor, ("start", "auto"))
        turn = (' transform="rotate(%d %s %s)"' % (-angle, self._n(x), self._n(y))
                if angle else "")
        self.parts.append(
            '<text x="%s" y="%s" fill="%s" font-size="%d" text-anchor="%s" '
            'dominant-baseline="%s"%s%s>%s</text>' % (
                self._n(x), self._n(y), color, size + 2, h, v,
                ' font-weight="600"' if bold else "", turn, self._e(text),
            )
        )

    def hotspot(self, x0, y0, x1, y1, text):
        self.spots.append(
            '<rect class="hot" x="%s" y="%s" width="%s" height="%s" '
            'fill="transparent"><title>%s</title></rect>' % (
                self._n(x0), self._n(y0), self._n(x1 - x0), self._n(y1 - y0),
                self._e(text),
            )
        )


class WebChart(WebWidget, ChartCore):
    """Chart of a page: drawn as SVG in the server each time it changes."""

    def __init__(self, *args, **kwargs):
        WebWidget.__init__(self, *args, **kwargs)
        self._chart_init(self.options)

    def _changed(self):
        self.form._touch(self.name)

    def redraw(self):
        self._changed()

    def svg(self):
        p = _SvgChartPainter()
        self._draw(p, self.width, self.height)
        return (
            '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
            'viewBox="0 0 %d %d" font-family="system-ui, sans-serif" role="img">'
            '%s%s</svg>' % (self.width, self.height, self.width, self.height,
                            "".join(p.parts), "".join(p.spots))
        )


WEB_CLASSES["Chart"] = WebChart
''';
}
