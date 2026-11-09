part of 'tk_examples.dart';

// El código en Python del dominó (tk_showcase_domino.dart): va después de
// los textos.
const _dominoCode = r'''
# ------------------------------------------------------------------ reglas
# Dominó cubano de doble 9: 55 fichas, cuatro jugadores en dos parejas
# (usted y su compañero, enfrente; los rivales, a los lados), 10 fichas cada
# uno y 15 que no se juegan. Sin robar: quien no lleva, pasa. La mano se
# acaba con dominó (alguien se queda sin fichas) o con tranque (nadie puede
# jugar). La partida es a 100 tantos.

SOUTH, EAST, NORTH, WEST = 0, 1, 2, 3
PIP_COLORS = {
    1: "#1a73e8", 2: "#2e9e45", 3: "#d93025", 4: "#8e3bd1", 5: "#202124",
    6: "#e8a800", 7: "#ff6d00", 8: "#00897b", 9: "#6d4c41",
}
PIP_GRID = {
    0: [], 1: [(1, 1)], 2: [(0, 0), (2, 2)], 3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (0, 2), (2, 0), (2, 2)],
    5: [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
    6: [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)],
    7: [(0, 0), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 2)],
    8: [(0, 0), (0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2)],
    9: [(r, c) for r in range(3) for c in range(3)],
}


def full_set():
    return [(a, b) for a in range(10) for b in range(a, 10)]


def pips(tiles):
    return sum(a + b for a, b in tiles)


def team_of(player):
    return player % 2


class Game:
    """Las reglas, sin pantalla: una partida entera se puede jugar desde las
    pruebas."""

    def __init__(self, seed=None, target=100):
        self.rng = random.Random(seed)
        self.target = target
        self.scores = [0, 0]
        self.hand_no = 0
        self.opener = None
        self.over = False
        self.winner = None
        self.new_hand()

    # ---- una mano nueva
    def new_hand(self):
        tiles = full_set()
        self.rng.shuffle(tiles)
        self.hands = [sorted(tiles[i * 10:(i + 1) * 10]) for i in range(4)]
        self.pool = tiles[40:]
        self.chain = []
        self.first = None
        self.arms = {"L": [], "R": []}
        self.passes = 0
        self.lacks = [set() for _ in range(4)]
        self.result = None
        self.last = None
        self.hand_no += 1
        self.must_open = None
        if self.opener is None:
            # La primera mano la abre quien tenga el doble más alto.
            doubles = [(t[0], p) for p in range(4) for t in self.hands[p] if t[0] == t[1]]
            value, player = max(doubles)
            self.opener = player
            self.must_open = (value, value)
        else:
            self.opener = (self.opener + 1) % 4
        self.turn = self.opener

    def ends(self):
        if not self.chain:
            return None
        return self.chain[0][0], self.chain[-1][1]

    def moves(self, player):
        """Lo que puede jugar: [(ficha, punta)] con punta "L" o "R"."""
        hand = self.hands[player]
        if not self.chain:
            if self.must_open:
                return [(self.must_open, "R")] if self.must_open in hand else []
            return [(t, "R") for t in hand]
        left, right = self.ends()
        out = []
        for t in hand:
            if left in t:
                out.append((t, "L"))
            if right in t and not (left == right and left in t):
                out.append((t, "R"))
        return out

    def play(self, player, tile, side):
        assert player == self.turn and not self.result
        assert (tile, side) in self.moves(player), (tile, side)
        self.hands[player].remove(tile)
        a, b = tile
        if not self.chain:
            self.chain = [tile]
            self.first = tile
        elif side == "L":
            left = self.chain[0][0]
            outer = a if b == left else b
            self.chain.insert(0, (outer, left))
            self.arms["L"].append((left, outer))
        else:
            right = self.chain[-1][1]
            outer = b if a == right else a
            self.chain.append((right, outer))
            self.arms["R"].append((right, outer))
        self.last = (player, tile, side)
        self.passes = 0
        if not self.hands[player]:
            self.finish("domino", player)
        else:
            self.turn = (player + 1) % 4

    def pass_turn(self, player):
        assert player == self.turn and not self.moves(player)
        self.lacks[player].update(self.ends() or ())
        self.passes += 1
        self.last = (player, None, None)
        if self.passes >= 4:
            self.finish("tranque", None)
        else:
            self.turn = (player + 1) % 4

    def finish(self, kind, player):
        totals = [pips(h) for h in self.hands]
        points = sum(totals)
        if kind == "tranque":
            # Gana el jugador con menos tantos; empate entre parejas: nadie.
            low = min(totals)
            who = [p for p in range(4) if totals[p] == low]
            teams = {team_of(p) for p in who}
            player = who[0] if len(teams) == 1 else None
        team = team_of(player) if player is not None else None
        if team is not None:
            self.scores[team] += points
        self.result = {"kind": kind, "player": player, "team": team,
                       "points": points if team is not None else 0, "totals": totals}
        if team is not None and self.scores[team] >= self.target:
            self.over = True
            self.winner = team

    def next_hand(self):
        if not self.over:
            self.new_hand()


# ------------------------------------------------------------ la computadora
def choose(game, player, rng=None):
    """La jugada de la computadora: suelta las fichas gordas y los dobles,
    se queda con la mano de un número, no le cierra el juego al compañero y
    pone números que los rivales no llevan."""
    moves = game.moves(player)
    if not moves:
        return None
    hand = game.hands[player]
    partner = (player + 2) % 4
    rivals = ((player + 1) % 4, (player + 3) % 4)
    ends = game.ends()
    best, best_score = None, None
    for tile, side in moves:
        a, b = tile
        if ends is None:
            exposed = (a, b)
        else:
            conn = ends[0] if side == "L" else ends[1]
            outer = b if a == conn else a
            other = ends[1] if side == "L" else ends[0]
            exposed = (outer, other)
        rest = [t for t in hand if t != tile]
        score = a + b
        if a == b:
            score += 6
        for n in set(exposed):
            score += 2 * sum(1 for t in rest if n in t)
            if n in game.lacks[partner]:
                score -= 6
            for r in rivals:
                if n in game.lacks[r]:
                    score += 4
        if rng is not None:
            score += rng.random() * 0.5
        if best_score is None or score > best_score:
            best, best_score = (tile, side), score
    return best


# ------------------------------------------------------------ la mesa
W, H = 1100, 700
U = 26                                  # media ficha en la mesa
BOARD = (150, 140, 950, 548)            # donde va la cadena
CENTER = (550, 344)
FELT, FELT_DARK, RIM = "#1f6e3d", "#185c32", "#5b3a1e"
IVORY, IVORY_EDGE = "#f8f4ea", "#cfc6b0"
BACK = "#22355e"
GOLD = "#f5c542"
SEATS = {
    SOUTH: (550, 618), EAST: (1030, 344), NORTH: (550, 52), WEST: (70, 344),
}


def layout(game):
    """Dónde va cada ficha de la cadena: [(x0, y0, x1, y1, primera, segunda)]
    con las mitades de izquierda a derecha o de arriba abajo. La cadena sale
    del centro hacia los dos lados y, al llegar al borde, gira como una
    serpiente (hacia abajo la derecha, hacia arriba la izquierda). Los dobles
    van atravesados."""
    out = []
    if not game.first:
        return out
    cx, cy = CENTER
    a, b = game.first
    if a == b:
        out.append((cx - U / 2, cy - U, cx + U / 2, cy + U, a, b))
        start = {"R": cx + U / 2, "L": cx - U / 2}
    else:
        out.append((cx - U, cy - U / 2, cx + U, cy + U / 2, a, b))
        start = {"R": cx + U, "L": cx - U}
    for side, sx, vy in (("R", 1, 1), ("L", -1, -1)):
        x, y, dx = start[side], cy, sx
        # Lo que sobresale la última ficha de la fila (un doble, más).
        half = U if a == b else U / 2
        for conn, outer in game.arms[side]:
            double = conn == outer
            need = U if double else 2 * U
            if (dx > 0 and x + need > BOARD[2]) or (dx < 0 and x - need < BOARD[0]):
                # La curva: una ficha de pie bajo (o sobre) el final de la fila.
                vx0 = x - U if dx > 0 else x
                if vy > 0:
                    y0 = y + half
                    out.append((vx0, y0, vx0 + U, y0 + 2 * U, conn, outer))
                else:
                    y1 = y - half
                    out.append((vx0, y1 - 2 * U, vx0 + U, y1, outer, conn))
                y += vy * (half + 1.5 * U)
                x = vx0 if dx > 0 else vx0 + U
                dx = -dx
                half = U / 2
                continue
            half = U if double else U / 2
            if double:
                x0 = x if dx > 0 else x - U
                out.append((x0, y - U, x0 + U, y + U, conn, outer))
                x += dx * U
            elif dx > 0:
                out.append((x, y - U / 2, x + 2 * U, y + U / 2, conn, outer))
                x += 2 * U
            else:
                out.append((x - 2 * U, y - U / 2, x, y + U / 2, outer, conn))
                x -= 2 * U
    return out


def arm_end(game, side):
    """El punto de la mesa donde se pondría la próxima ficha de esa punta."""
    rects = layout(game)
    if not rects:
        return CENTER
    if side == "R" and not game.arms["R"] or side == "L" and not game.arms["L"]:
        x0, y0, x1, y1 = rects[0][:4]
        return (x1 + U / 2, (y0 + y1) / 2) if side == "R" else (x0 - U / 2, (y0 + y1) / 2)
    # La última ficha de ese lado en la lista de rects
    n_right = len(game.arms["R"])
    rect = rects[n_right] if side == "R" else rects[-1]
    x0, y0, x1, y1 = rect[:4]
    return ((x0 + x1) / 2, (y0 + y1) / 2)


def hand_rects(n):
    """Las fichas del jugador, de pie, abajo."""
    w, h, gap = 44, 88, 8
    total = n * w + (n - 1) * gap
    x = (W - total) / 2
    return [(x + i * (w + gap), 560, x + i * (w + gap) + w, 560 + h) for i in range(n)]


# ------------------------------------------------------------ el dibujo
class Painter:
    """Lo que hace falta para pintar la mesa. TkPainter lo hace en el
    lienzo; PilPainter, en una imagen (las capturas, sin ventana)."""

    def rect(self, x0, y0, x1, y1, fill, outline=None, width=1): ...
    def round_rect(self, x0, y0, x1, y1, r, fill, outline=None, width=1): ...
    def oval(self, x0, y0, x1, y1, fill, outline=None, width=1): ...
    def line(self, pts, fill, width=1): ...
    def text(self, x, y, s, size, fill, bold=False, anchor="center"): ...
    def poly(self, pts, fill): ...


class TkPainter(Painter):
    """Pinta en el lienzo con la mesa a escala: la mesa se diseña en
    1100×700 y se amplía (sin deformarse) al tamaño de la ventana; lo que
    sobra queda como borde de madera."""

    def __init__(self, canvas):
        self.c = canvas
        self.fonts = {}
        self.s, self.ox, self.oy = 1.0, 0.0, 0.0

    def fit(self, width, height):
        """El tamaño del lienzo: calcula la escala y el margen."""
        self.s = max(0.3, min(width / W, height / H))
        self.ox = (width - W * self.s) / 2
        self.oy = (height - H * self.s) / 2

    def to_table(self, x, y):
        """De un punto del lienzo (el ratón) a la mesa."""
        return (x - self.ox) / self.s, (y - self.oy) / self.s

    def to_screen(self, x, y):
        return x * self.s + self.ox, y * self.s + self.oy

    def _p(self, *v):
        return [v[k] * self.s + (self.ox if k % 2 == 0 else self.oy) for k in range(len(v))]

    def clear(self):
        self.c.delete("all")

    def font(self, size, bold):
        px = max(6, round(size * self.s))
        key = (px, bold)
        if key not in self.fonts:
            self.fonts[key] = tkfont.Font(family="Helvetica", size=-px, weight="bold" if bold else "normal")
        return self.fonts[key]

    def rect(self, x0, y0, x1, y1, fill, outline=None, width=1):
        self.c.create_rectangle(*self._p(x0, y0, x1, y1), fill=fill, outline=outline or "", width=width * self.s)

    def round_rect(self, x0, y0, x1, y1, r, fill, outline=None, width=1):
        p = [x0 + r, y0, x1 - r, y0, x1, y0, x1, y0 + r, x1, y1 - r, x1, y1,
             x1 - r, y1, x0 + r, y1, x0, y1, x0, y1 - r, x0, y0 + r, x0, y0]
        self.c.create_polygon(self._p(*p), smooth=True, fill=fill, outline=outline or "", width=width * self.s)

    def oval(self, x0, y0, x1, y1, fill, outline=None, width=1):
        self.c.create_oval(*self._p(x0, y0, x1, y1), fill=fill, outline=outline or "", width=width * self.s)

    def line(self, pts, fill, width=1):
        self.c.create_line(*self._p(*pts), fill=fill, width=max(1, width * self.s), capstyle="round")

    def poly(self, pts, fill):
        self.c.create_polygon(*self._p(*pts), fill=fill, outline="")

    def text(self, x, y, s, size, fill, bold=False, anchor="center"):
        x, y = self._p(x, y)
        self.c.create_text(x, y, text=s, fill=fill, font=self.font(size, bold), anchor=anchor)


class PilPainter(Painter):
    ANCHORS = {"center": "mm", "w": "lm", "e": "rm", "n": "mt", "s": "mb"}

    def __init__(self, scale=2):
        from PIL import Image, ImageDraw
        self.s = scale
        self.img = Image.new("RGB", (W * scale, H * scale), FELT)
        self.d = ImageDraw.Draw(self.img)
        self.fonts = {}

    def font(self, size, bold):
        from PIL import ImageFont
        key = (size, bold)
        if key not in self.fonts:
            for path, index in (("/System/Library/Fonts/Helvetica.ttc", 1 if bold else 0),
                                ("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf", 0)):
                try:
                    self.fonts[key] = ImageFont.truetype(path, int(size * self.s), index=index)
                    break
                except OSError:
                    continue
            else:
                self.fonts[key] = ImageFont.load_default()
        return self.fonts[key]

    def _b(self, *v):
        return [round(x * self.s) for x in v]

    def rect(self, x0, y0, x1, y1, fill, outline=None, width=1):
        self.d.rectangle(self._b(x0, y0, x1, y1), fill=fill, outline=outline, width=max(1, round(width * self.s)) if outline else 0)

    def round_rect(self, x0, y0, x1, y1, r, fill, outline=None, width=1):
        self.d.rounded_rectangle(self._b(x0, y0, x1, y1), radius=round(r * self.s), fill=fill,
                                 outline=outline, width=max(1, round(width * self.s)) if outline else 0)

    def oval(self, x0, y0, x1, y1, fill, outline=None, width=1):
        self.d.ellipse(self._b(x0, y0, x1, y1), fill=fill, outline=outline, width=max(1, round(width * self.s)) if outline else 0)

    def line(self, pts, fill, width=1):
        self.d.line(self._b(*pts), fill=fill, width=max(1, round(width * self.s)), joint="curve")

    def poly(self, pts, fill):
        self.d.polygon(self._b(*pts), fill=fill)

    def text(self, x, y, s, size, fill, bold=False, anchor="center"):
        self.d.text(self._b(x, y), s, fill=fill, font=self.font(size, bold), anchor=self.ANCHORS.get(anchor, "mm"))

    def save(self, path):
        self.img.save(path)


class Recorder(Painter):
    """Para las pruebas: cuenta lo que se dibuja."""

    def __init__(self):
        self.n = 0
        self.texts = []

    def rect(self, *a, **k): self.n += 1
    def round_rect(self, *a, **k): self.n += 1
    def oval(self, *a, **k): self.n += 1
    def line(self, *a, **k): self.n += 1
    def poly(self, *a, **k): self.n += 1

    def text(self, x, y, s, *a, **k):
        self.n += 1
        self.texts.append(s)


def draw_pips(p, x0, y0, size, n, vertical_tile):
    """Los puntos de una mitad (un cuadrado de lado size)."""
    if n == 0:
        return
    m = size * 0.2
    step = (size - 2 * m) / 2
    r = max(1.6, size * 0.085)
    for row, col in PIP_GRID[n]:
        if not vertical_tile:
            row, col = col, row
        cx = x0 + m + col * step
        cy = y0 + m + row * step
        p.oval(cx - r, cy - r, cx + r, cy + r, PIP_COLORS[n])


def draw_tile(p, x0, y0, x1, y1, a, b, face=True, glow=None, dim=False):
    w, h = x1 - x0, y1 - y0
    vertical = h > w
    r = min(w, h) * 0.18
    p.round_rect(x0 + 1.5, y0 + 2.5, x1 + 1.5, y1 + 2.5, r, "#0e3a1f")
    if glow:
        p.round_rect(x0 - 3, y0 - 3, x1 + 3, y1 + 3, r + 3, glow)
    if not face:
        p.round_rect(x0, y0, x1, y1, r, BACK, "#101a30", 1)
        p.round_rect(x0 + 3, y0 + 3, x1 - 3, y1 - 3, r * 0.7, "#2c4377")
        p.oval((x0 + x1) / 2 - 3, (y0 + y1) / 2 - 3, (x0 + x1) / 2 + 3, (y0 + y1) / 2 + 3, "#d9c27a")
        return
    p.round_rect(x0, y0, x1, y1, r, "#e6e0d0" if dim else IVORY, IVORY_EDGE, 1)
    if vertical:
        s = w
        p.line((x0 + s * 0.15, y0 + h / 2, x1 - s * 0.15, y0 + h / 2), "#9a9384", max(1, s * 0.05))
        draw_pips(p, x0, y0, s, a, True)
        draw_pips(p, x0, y0 + h / 2, s, b, True)
    else:
        s = h
        p.line((x0 + w / 2, y0 + s * 0.15, x0 + w / 2, y1 - s * 0.15), "#9a9384", max(1, s * 0.05))
        draw_pips(p, x0, y0, s, a, False)
        draw_pips(p, x0 + w / 2, y0, s, b, False)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    p.oval(cx - 2, cy - 2, cx + 2, cy + 2, "#b8975a")


class View:
    """Lo que no son reglas: el ratón, lo seleccionado, los avisos."""

    def __init__(self):
        self.hover = None
        self.pending = None       # ficha que cabe por las dos puntas
        self.flash = {}           # jugador -> (texto, hasta)
        self.message = ""
        self.show_all = False
        self.overlay = False
        self.thinking = 0


def draw(p, game, view, now=0.0):
    # La mesa: madera y paño
    p.rect(0, 0, W, H, RIM)
    p.round_rect(10, 10, W - 10, H - 10, 40, "#6e4826")
    p.round_rect(22, 22, W - 22, H - 22, 34, FELT_DARK)
    p.round_rect(30, 30, W - 30, H - 30, 30, FELT)
    p.round_rect(160, 120, W - 160, H - 140, 120, "#227743")
    # Marcador
    p.round_rect(40, 40, 262, 120, 12, "#123f23", "#2f8a52", 1)
    p.text(56, 58, TEAM_US, 14, "#cfe9d6", True, "w")
    p.text(246, 58, str(game.scores[0]), 18, GOLD, True, "e")
    p.text(56, 84, TEAM_THEM, 14, "#cfe9d6", True, "w")
    p.text(246, 84, str(game.scores[1]), 18, "#ffffff", True, "e")
    p.text(56, 107, HAND_FMT.format(game.hand_no) + "  ·  " + TO_FMT.format(game.target), 12, "#9fc9ad", False, "w")
    # La cadena
    rects = layout(game)
    last_tile = game.last[1] if game.last and game.last[1] else None
    for x0, y0, x1, y1, a, b in rects:
        glow = GOLD if last_tile and {a, b} == set(last_tile) and (a, b) in (last_tile, last_tile[::-1]) and not game.result else None
        draw_tile(p, x0, y0, x1, y1, a, b, glow=glow)
    if not rects:
        p.text(CENTER[0], CENTER[1], EMPTY_BOARD, 16, "#9fc9ad")
    # Las puntas para elegir
    if view.pending:
        for side in ("L", "R"):
            x, y = arm_end(game, side)
            p.oval(x - 16, y - 16, x + 16, y + 16, GOLD, "#ffffff", 2)
            d = -1 if side == "L" else 1
            p.poly((x - 6 * d, y - 8, x + 8 * d, y, x - 6 * d, y + 8), "#3a2a00")
    # Los jugadores
    for seat in range(4):
        draw_seat(p, game, view, seat, now)
    # El aviso de arriba
    if view.message:
        p.round_rect(W / 2 - 230, 132, W / 2 + 230, 160, 14, "#123f23")
        p.text(W / 2, 146, view.message, 14, "#ffffff", True)
    if view.overlay and game.result:
        draw_result(p, game)


def draw_seat(p, game, view, seat, now):
    hand = game.hands[seat]
    name = PLAYER_NAMES[seat]
    x, y = SEATS[seat]
    turn = game.turn == seat and not game.result
    team_color = GOLD if team_of(seat) == 0 else "#ff8a80"
    if seat == SOUTH:
        moves = {t for t, _ in game.moves(SOUTH)} if turn else set()
        for i, (r, t) in enumerate(zip(hand_rects(len(hand)), hand)):
            lift = 0
            glow = None
            if t in moves:
                lift = 10 if view.hover == i else 4
                glow = GOLD if view.pending == t else "#7fd39a"
            draw_tile(p, r[0], r[1] - lift, r[2], r[3] - lift, t[0], t[1], glow=glow, dim=turn and t not in moves)
        plate = (x - 80, 666, x + 80, 690)
    elif seat == NORTH:
        n = len(hand)
        x0 = x - (n * 30) / 2
        for i, t in enumerate(hand):
            draw_tile(p, x0 + i * 30, 70, x0 + i * 30 + 26, 122, t[0], t[1], face=view.show_all)
        plate = (x - 80, 36, x + 80, 60)
    else:
        n = len(hand)
        y0 = y - (n * 26) / 2
        for i, t in enumerate(hand):
            xx = x - 26 if seat == WEST else x - 26
            draw_tile(p, xx, y0 + i * 26, xx + 52, y0 + i * 26 + 22, t[0], t[1], face=view.show_all)
        plate = (x - 60, y0 - 40, x + 60, y0 - 14)
    # La placa con el nombre
    px0, py0, px1, py1 = plate
    if turn:
        p.round_rect(px0 - 3, py0 - 3, px1 + 3, py1 + 3, 15, GOLD)
    p.round_rect(px0, py0, px1, py1, 12, "#0f2f1b", team_color, 1)
    p.text((px0 + px1) / 2, (py0 + py1) / 2, "%s · %d" % (name, len(hand)), 13, "#ffffff", True)
    flash = view.flash.get(seat)
    if flash and flash[1] > now:
        bx, by = {SOUTH: (x + 130, 678), NORTH: (x + 130, 48), WEST: (x + 6, py0 - 22), EAST: (x - 6, py0 - 22)}[seat]
        p.round_rect(bx - 34, by - 13, bx + 34, by + 13, 12, "#ffffff")
        p.text(bx, by, flash[0], 13, "#b3261e", True)


def draw_result(p, game):
    res = game.result
    p.round_rect(250, 150, 850, 560, 22, "#0d2a17", GOLD, 2)
    if res["kind"] == "domino":
        title = DOMINO_FMT.format(PLAYER_NAMES[res["player"]])
    else:
        title = TRANQUE
    p.text(550, 186, title, 26, GOLD, True)
    if res["team"] is None:
        line = TIE
    else:
        if res["kind"] == "tranque":
            line = TRANQUE_WIN_FMT.format(PLAYER_NAMES[res["player"]], res["totals"][res["player"]]) + "  "
        else:
            line = ""
        line += POINTS_FMT.format(TEAM_US if res["team"] == 0 else TEAM_THEM, res["points"])
    p.text(550, 222, line, 16, "#ffffff", True)
    p.text(550, 254, LEFT_TILES, 13, "#9fc9ad")
    for seat in range(4):
        y = 286 + seat * 48
        p.text(282, y, PLAYER_NAMES[seat], 14, GOLD if team_of(seat) == 0 else "#ff8a80", True, "w")
        for i, t in enumerate(game.hands[seat]):
            draw_tile(p, 392 + i * 44, y - 10, 392 + i * 44 + 40, y + 10, t[0], t[1])
        p.text(818, y, str(res["totals"][seat]), 15, "#ffffff", True, "e")
    p.text(550, 486, "%s %d  ·  %s %d" % (TEAM_US, game.scores[0], TEAM_THEM, game.scores[1]), 18, "#ffffff", True)
    if game.over:
        p.text(550, 516, WIN_US if game.winner == 0 else WIN_THEM, 18, GOLD, True)
        p.text(550, 542, AGAIN, 13, "#9fc9ad")
    else:
        p.text(550, 528, NEXT_HAND, 13, "#9fc9ad")


# ------------------------------------------------------------------ ventana
class Form1(FormDesign):
    def form_create(self):
        self.TableHint.destroy()   # el aviso del Diseñador
        self.painter = TkPainter(self.Table)
        # La mesa ocupa toda la ventana, que se puede agrandar y maximizar.
        self.Table.configure(bg="#3a2512")
        self.Table.place_forget()
        self.Table.place(x=0, y=0, relwidth=1, relheight=1)
        self.root.resizable(True, True)
        self.root.minsize(660, 420)
        self.Table.bind("<Configure>", self.table_resized)
        self.root.bind("<F11>", lambda e: self.toggle_fullscreen())
        self.root.bind("<Escape>", lambda e: self.toggle_fullscreen(False))
        self.view = View()
        self.target = 100
        self.rng = random.Random()
        self.root.bind("<Return>", lambda e: self.advance())
        self.root.bind("<space>", lambda e: self.advance())
        self.new_game()

    # ---- partida
    def new_game(self):
        self.game = Game(target=self.target)
        self.view = View() if not hasattr(self, "view") else self._fresh_view()
        self.wait_until = time.time() + 1.0
        self.announce_opening()
        self.redraw()

    def _fresh_view(self):
        v = View()
        v.show_all = self.view.show_all
        return v

    def announce_opening(self):
        g = self.game
        if g.must_open:
            self.flash(g.turn, OPENS_FLASH)
        self.update_message()

    def advance(self):
        g = self.game
        if not g.result:
            return
        if g.over:
            self.new_game()
            return
        g.next_hand()
        self.view.overlay = False
        self.view.pending = None
        self.wait_until = time.time() + 1.0
        self.announce_opening()
        self.redraw()

    def flash(self, seat, text):
        self.view.flash[seat] = (text, time.time() + 1.6)

    def update_message(self):
        g, v = self.game, self.view
        if g.result:
            v.message = ""
        elif g.turn == SOUTH:
            v.message = CHOOSE_END if v.pending else (YOUR_TURN if g.moves(SOUTH) else YOU_PASS)
        else:
            v.message = THINKING_FMT.format(PLAYER_NAMES[g.turn])

    def table_resized(self, event):
        self.painter.fit(event.width, event.height)
        self.redraw()

    def toggle_fullscreen(self, on=None):
        now = bool(self.root.attributes("-fullscreen"))
        self.root.attributes("-fullscreen", (not now) if on is None else on)

    def redraw(self):
        self.update_message()
        self.painter.clear()
        draw(self.painter, self.game, self.view, time.time())

    # ---- el reloj: juega la computadora y pasa el que no lleva
    def Tick_timer(self):
        g, now = self.game, time.time()
        if g.result:
            if not self.view.overlay and now >= self.wait_until:
                self.view.overlay = True
                self.redraw()
            return
        if now < self.wait_until:
            return
        if g.turn == SOUTH:
            if not g.moves(SOUTH):
                g.pass_turn(SOUTH)
                self.flash(SOUTH, PASS)
                self.after_move()
            return
        move = choose(g, g.turn, self.rng)
        seat = g.turn
        if move is None:
            g.pass_turn(seat)
            self.flash(seat, PASS)
        else:
            g.play(seat, *move)
        self.after_move()

    def after_move(self):
        self.wait_until = time.time() + (1.4 if self.game.result else 0.9)
        self.redraw()

    # ---- el ratón
    def tile_at(self, x, y):
        for i, r in enumerate(hand_rects(len(self.game.hands[SOUTH]))):
            if r[0] <= x <= r[2] and r[1] - 12 <= y <= r[3]:
                return i
        return None

    def Table_click(self, event):
        ex, ey = self.painter.to_table(event.x, event.y)
        g, v = self.game, self.view
        if g.result:
            if v.overlay:
                self.advance()
            return
        if g.turn != SOUTH or time.time() < self.wait_until:
            return
        if v.pending:
            for side in ("L", "R"):
                x, y = arm_end(g, side)
                if abs(ex - x) <= 20 and abs(ey - y) <= 20:
                    self.play(v.pending, side)
                    return
        i = self.tile_at(ex, ey)
        v.pending = None
        if i is not None:
            tile = g.hands[SOUTH][i]
            sides = [s for t, s in g.moves(SOUTH) if t == tile]
            if len(sides) == 1:
                self.play(tile, sides[0])
                return
            if len(sides) == 2:
                v.pending = tile
        self.redraw()

    def play(self, tile, side):
        self.view.pending = None
        self.game.play(SOUTH, tile, side)
        self.after_move()

    def Table_motion(self, event):
        i = self.tile_at(*self.painter.to_table(event.x, event.y))
        if i != self.view.hover:
            self.view.hover = i
            self.redraw()

    def Table_leave(self, event):
        if self.view.hover is not None:
            self.view.hover = None
            self.redraw()

    # ---- el menú
    def Menu1_click(self, item):
        if item == MP_NEW:
            self.new_game()
        elif item in (MP_TO100, MP_TO200):
            self.target = 100 if item == MP_TO100 else 200
            self.new_game()
        elif item == MP_FULLSCREEN:
            self.toggle_fullscreen()
        elif item == MP_SHOW_ALL:
            self.view.show_all = not self.view.show_all
            self.redraw()
        elif item == MP_RULES:
            messagebox.showinfo(L_RULES, RULES_TEXT, parent=self.root)
        elif item == MP_ABOUT:
            messagebox.showinfo(L_ABOUT, ABOUT_TEXT, parent=self.root)
        elif item == MP_QUIT:
            self.form_close()

    def form_close(self, *args):
        self.root.destroy()


# ------------------------------------------------------------------ pruebas
def selftest():
    """Sin ventana: DMS_DOMINO_SELFTEST=1."""
    fails = []

    def check(ok, what):
        if not ok:
            fails.append(what)
            print("FAIL", what)

    tiles = full_set()
    check(len(tiles) == 55 and len(set(tiles)) == 55, "55 fichas distintas")
    check(pips(tiles) == 495, "495 tantos en total")
    g = Game(seed=1)
    check(all(len(h) == 10 for h in g.hands) and len(g.pool) == 15, "10 fichas cada uno y 15 fuera")
    best = max(t[0] for h in g.hands for t in h if t[0] == t[1])
    check(g.must_open == (best, best) and (best, best) in g.hands[g.turn], "abre el doble más alto")
    check(g.moves(g.turn) == [((best, best), "R")], "la primera jugada es ese doble")
    # Muchas partidas enteras, todos con la computadora
    rng = random.Random(5)
    hands = dominos = tranques = 0
    overlaps = outside = 0
    for game_no in range(40):
        g = Game(seed=game_no, target=100)
        while not g.over and g.hand_no < 60:
            while not g.result:
                seat = g.turn
                move = choose(g, seat, rng)
                if move is None:
                    g.pass_turn(seat)
                else:
                    g.play(seat, *move)
                # La cadena encaja y no hay fichas repetidas
                ok = all(g.chain[i][1] == g.chain[i + 1][0] for i in range(len(g.chain) - 1))
                if not ok:
                    check(False, "la cadena encaja")
                    break
            rects = layout(g)
            for i in range(len(rects)):
                ax0, ay0, ax1, ay1 = rects[i][:4]
                if ax0 < 40 or ax1 > W - 40 or ay0 < 130 or ay1 > 556:
                    outside += 1
                for j in range(i + 1, len(rects)):
                    bx0, by0, bx1, by1 = rects[j][:4]
                    if min(ax1, bx1) - max(ax0, bx0) > 0.5 and min(ay1, by1) - max(ay0, by0) > 0.5:
                        if not overlaps:
                            print("se pisan:", rects[i], rects[j], "brazos", g.arms, "primera", g.first)
                        overlaps += 1
            seen = [t for h in g.hands for t in h] + g.pool + [tuple(sorted(t)) for t in g.chain]
            check(sorted(seen) == sorted(full_set()), "ninguna ficha se pierde ni se repite")
            hands += 1
            if g.result["kind"] == "domino":
                dominos += 1
                check(not g.hands[g.result["player"]], "el que domina no tiene fichas")
            else:
                tranques += 1
            r = g.result
            check(r["points"] in (0, sum(r["totals"])), "se anotan todos los tantos que quedan")
            render = Recorder()
            view = View()
            view.overlay = True
            draw(render, g, view)
            check(render.n > 100, "se dibuja la mesa")
            g.next_hand()
        check(g.over and max(g.scores) >= 100, "la partida llega a 100")
    check(overlaps == 0, "las fichas de la mesa no se pisan (%d)" % overlaps)
    check(outside == 0, "las fichas caben en la mesa (%d)" % outside)
    check(dominos > 0 and tranques > 0, "hay dominós y tranques")
    # La computadora juega mejor que al azar
    wins = 0
    for game_no in range(60):
        g = Game(seed=1000 + game_no, target=100)
        while not g.over:
            while not g.result:
                seat = g.turn
                moves = g.moves(seat)
                if not moves:
                    g.pass_turn(seat)
                elif team_of(seat) == 1:
                    g.play(seat, *choose(g, seat))
                else:
                    g.play(seat, *rng.choice(moves))
            g.next_hand()
        wins += g.winner == 1
    check(wins > 33, "la computadora gana a quien juega al azar (%d de 60)" % wins)
    print("selftest %s hands=%d dominos=%d tranques=%d ai_wins=%d/60" % (
        "FAILED" if fails else "ok", hands, dominos, tranques, wins))
    return 1 if fails else 0


def shots(folder):
    """Capturas sin abrir la ventana: DMS_DOMINO_SHOT=<carpeta>."""
    os.makedirs(folder, exist_ok=True)
    rng = random.Random(3)

    def play_until(g, stop):
        while not g.result and not stop(g):
            seat = g.turn
            move = choose(g, seat, rng)
            if move is None:
                g.pass_turn(seat)
            else:
                g.play(seat, *move)

    def save(g, view, name):
        p = PilPainter(2)
        draw(p, g, view, 0.0)
        p.save(os.path.join(folder, name))

    def message(g, view):
        if g.result:
            view.message = ""
        elif g.turn == SOUTH:
            view.message = CHOOSE_END if view.pending else (YOUR_TURN if g.moves(SOUTH) else YOU_PASS)
        else:
            view.message = THINKING_FMT.format(PLAYER_NAMES[g.turn])

    # 1. Al empezar: su mano y la primera ficha
    g = Game(seed=11)
    play_until(g, lambda g: g.turn == SOUTH and g.chain and g.moves(SOUTH))
    v = View()
    v.hover = 2
    message(g, v)
    save(g, v, "salida.png")
    # 2. A mitad de la mano: la cadena ya gira
    g = Game(seed=11)
    play_until(g, lambda g: g.turn == SOUTH and len(g.chain) >= 22 and len(g.moves(SOUTH)) >= 1)
    v = View()
    v.flash[WEST] = (PASS, 1e9)
    moves = g.moves(SOUTH)
    message(g, v)
    save(g, v, "mesa.png")
    # 3. Una ficha que va por las dos puntas
    g = Game(seed=4)
    for _ in range(400):
        play_until(g, lambda g: g.turn == SOUTH and any(
            len([s for t2, s in g.moves(SOUTH) if t2 == t]) == 2 for t, _ in g.moves(SOUTH)))
        if not g.result:
            break
        g.next_hand()
    v = View()
    if not g.result:
        v.pending = next(t for t, _ in g.moves(SOUTH)
                         if len([s for t2, s in g.moves(SOUTH) if t2 == t]) == 2)
    message(g, v)
    save(g, v, "puntas.png")
    # 4. El final de una mano
    g = Game(seed=11)
    play_until(g, lambda g: False)
    v = View()
    v.overlay = True
    save(g, v, "resultado.png")
    print("shots ok", folder)
    return 0


if os.environ.get("DMS_DOMINO_SELFTEST"):
    sys.exit(selftest())
if os.environ.get("DMS_DOMINO_SHOT"):
    sys.exit(shots(os.environ["DMS_DOMINO_SHOT"]))
''';
