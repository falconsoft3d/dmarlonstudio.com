part of 'tk_examples.dart';

// El JavaScript del dominó web (tk_showcase_web_domino.dart): va después
// de los textos (TX).
const _webDominoCode = r'''
// ------------------------------------------------------------------ reglas
// Dominó cubano de doble 9: 55 fichas, cuatro jugadores en dos parejas
// (usted y su compañero, enfrente; los rivales, a los lados), 10 fichas cada
// uno y 15 que no se juegan. Quien no lleva, pasa. La mano se acaba con
// dominó o con tranque. La partida es a 100 tantos.

const SOUTH = 0, EAST = 1, NORTH = 2, WEST = 3;
const NAMES = [TX.YOU, "Mayelín", "Yuniel", "Osmany"];
const PIP_COLORS = { 1: "#1a73e8", 2: "#2e9e45", 3: "#d93025", 4: "#8e3bd1", 5: "#202124", 6: "#e8a800", 7: "#ff6d00", 8: "#00897b", 9: "#6d4c41" };
const PIP_GRID = {
  0: [], 1: [[1, 1]], 2: [[0, 0], [2, 2]], 3: [[0, 0], [1, 1], [2, 2]],
  4: [[0, 0], [0, 2], [2, 0], [2, 2]], 5: [[0, 0], [0, 2], [1, 1], [2, 0], [2, 2]],
  6: [[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]],
  7: [[0, 0], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 2]],
  8: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 2]],
  9: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]],
};

// Un generador de números pseudoaleatorios con semilla (las pruebas).
function rng(seed) {
  let s = (seed >>> 0) || 1;
  return () => {
    s ^= s << 13; s >>>= 0;
    s ^= s >>> 17;
    s ^= s << 5; s >>>= 0;
    return s / 4294967296;
  };
}

const fullSet = () => {
  const out = [];
  for (let a = 0; a < 10; a++) for (let b = a; b < 10; b++) out.push([a, b]);
  return out;
};
const pips = (tiles) => tiles.reduce((n, [a, b]) => n + a + b, 0);
const teamOf = (p) => p % 2;
const same = (t, u) => t[0] === u[0] && t[1] === u[1];

class Game {
  constructor(seed, target = 100) {
    this.random = rng(seed ?? Math.floor(Math.random() * 1e9));
    this.target = target;
    this.scores = [0, 0];
    this.handNo = 0;
    this.opener = null;
    this.over = false;
    this.winner = null;
    this.newHand();
  }

  newHand() {
    const tiles = fullSet();
    for (let i = tiles.length - 1; i > 0; i--) {
      const j = Math.floor(this.random() * (i + 1));
      [tiles[i], tiles[j]] = [tiles[j], tiles[i]];
    }
    const byValue = (x, y) => x[0] - y[0] || x[1] - y[1];
    this.hands = [0, 1, 2, 3].map((i) => tiles.slice(i * 10, i * 10 + 10).sort(byValue));
    this.pool = tiles.slice(40);
    this.chain = [];
    this.first = null;
    this.arms = { L: [], R: [] };
    this.passes = 0;
    this.lacks = [new Set(), new Set(), new Set(), new Set()];
    this.result = null;
    this.last = null;
    this.handNo++;
    this.mustOpen = null;
    if (this.opener === null) {
      // La primera mano la abre quien tenga el doble más alto.
      let best = -1, who = 0;
      this.hands.forEach((h, p) => h.forEach((t) => { if (t[0] === t[1] && t[0] > best) { best = t[0]; who = p; } }));
      this.opener = who;
      this.mustOpen = [best, best];
    } else {
      this.opener = (this.opener + 1) % 4;
    }
    this.turn = this.opener;
  }

  ends() {
    return this.chain.length ? [this.chain[0][0], this.chain[this.chain.length - 1][1]] : null;
  }

  moves(p) {
    const hand = this.hands[p];
    if (!this.chain.length) {
      if (this.mustOpen) return hand.some((t) => same(t, this.mustOpen)) ? [[this.mustOpen, "R"]] : [];
      return hand.map((t) => [t, "R"]);
    }
    const [l, r] = this.ends();
    const out = [];
    for (const t of hand) {
      if (t.includes(l)) out.push([t, "L"]);
      if (t.includes(r) && !(l === r && t.includes(l))) out.push([t, "R"]);
    }
    return out;
  }

  play(p, tile, side) {
    if (p !== this.turn || this.result) throw new Error("no es su turno");
    if (!this.moves(p).some(([t, s]) => same(t, tile) && s === side)) throw new Error("jugada no válida");
    this.hands[p] = this.hands[p].filter((t) => !same(t, tile));
    const [a, b] = tile;
    if (!this.chain.length) {
      this.chain = [tile];
      this.first = tile;
    } else if (side === "L") {
      const left = this.chain[0][0];
      const outer = b === left ? a : b;
      this.chain.unshift([outer, left]);
      this.arms.L.push([left, outer]);
    } else {
      const right = this.chain[this.chain.length - 1][1];
      const outer = a === right ? b : a;
      this.chain.push([right, outer]);
      this.arms.R.push([right, outer]);
    }
    this.last = { p, tile, side };
    this.passes = 0;
    if (!this.hands[p].length) this.finish("domino", p);
    else this.turn = (p + 1) % 4;
  }

  pass(p) {
    if (p !== this.turn || this.moves(p).length) throw new Error("no puede pasar");
    for (const n of this.ends() ?? []) this.lacks[p].add(n);
    this.passes++;
    this.last = { p, tile: null };
    if (this.passes >= 4) this.finish("tranque", null);
    else this.turn = (p + 1) % 4;
  }

  finish(kind, player) {
    const totals = this.hands.map(pips);
    const points = totals.reduce((x, y) => x + y, 0);
    if (kind === "tranque") {
      // Gana el jugador con menos tantos; empate entre parejas: nadie.
      const low = Math.min(...totals);
      const who = [0, 1, 2, 3].filter((p) => totals[p] === low);
      player = new Set(who.map(teamOf)).size === 1 ? who[0] : null;
    }
    const team = player === null ? null : teamOf(player);
    if (team !== null) this.scores[team] += points;
    this.result = { kind, player, team, points: team === null ? 0 : points, totals };
    if (team !== null && this.scores[team] >= this.target) {
      this.over = true;
      this.winner = team;
    }
  }
}

// ------------------------------------------------------------ la computadora
// Suelta las fichas gordas y los dobles, se queda con la mano de un número,
// no le cierra el juego al compañero y pone números que los rivales no llevan.
function choose(g, p, random) {
  const moves = g.moves(p);
  if (!moves.length) return null;
  const hand = g.hands[p];
  const partner = (p + 2) % 4;
  const rivals = [(p + 1) % 4, (p + 3) % 4];
  const ends = g.ends();
  let best = null, bestScore = -Infinity;
  for (const [tile, side] of moves) {
    const [a, b] = tile;
    let exposed;
    if (!ends) exposed = [a, b];
    else {
      const conn = side === "L" ? ends[0] : ends[1];
      const outer = a === conn ? b : a;
      exposed = [outer, side === "L" ? ends[1] : ends[0]];
    }
    const rest = hand.filter((t) => !same(t, tile));
    let score = a + b + (a === b ? 6 : 0);
    for (const n of new Set(exposed)) {
      score += 2 * rest.filter((t) => t.includes(n)).length;
      if (g.lacks[partner].has(n)) score -= 6;
      for (const r of rivals) if (g.lacks[r].has(n)) score += 4;
    }
    if (random) score += random() * 0.5;
    if (score > bestScore) { best = [tile, side]; bestScore = score; }
  }
  return best;
}

// ------------------------------------------------------------ la mesa
// La mesa se dibuja en 1100×700 y el lienzo la amplía a su tamaño.
const W = 1100, H = 700, U = 26;
const BOARD = [150, 140, 950, 548];
const CENTER = [550, 344];
const FELT = "#1f6e3d", FELT_DARK = "#185c32", RIM = "#5b3a1e";
const IVORY = "#f8f4ea", IVORY_EDGE = "#cfc6b0", BACK = "#22355e", GOLD = "#f5c542";
const SEATS = { 0: [550, 618], 1: [1030, 344], 2: [550, 52], 3: [70, 344] };

// Dónde va cada ficha de la cadena: [x0, y0, x1, y1, primera, segunda]. La
// cadena sale del centro y, al llegar al borde, gira como una serpiente;
// los dobles van atravesados.
function layout(g) {
  const out = [];
  if (!g.first) return out;
  const [cx, cy] = CENTER;
  const [a, b] = g.first;
  let start;
  if (a === b) {
    out.push([cx - U / 2, cy - U, cx + U / 2, cy + U, a, b]);
    start = { R: cx + U / 2, L: cx - U / 2 };
  } else {
    out.push([cx - U, cy - U / 2, cx + U, cy + U / 2, a, b]);
    start = { R: cx + U, L: cx - U };
  }
  for (const [side, sx, vy] of [["R", 1, 1], ["L", -1, -1]]) {
    let x = start[side], y = cy, dx = sx;
    let half = a === b ? U : U / 2;
    for (const [conn, outer] of g.arms[side]) {
      const double = conn === outer;
      const need = double ? U : 2 * U;
      if ((dx > 0 && x + need > BOARD[2]) || (dx < 0 && x - need < BOARD[0])) {
        const vx0 = dx > 0 ? x - U : x;
        if (vy > 0) out.push([vx0, y + half, vx0 + U, y + half + 2 * U, conn, outer]);
        else out.push([vx0, y - half - 2 * U, vx0 + U, y - half, outer, conn]);
        y += vy * (half + 1.5 * U);
        x = dx > 0 ? vx0 : vx0 + U;
        dx = -dx;
        half = U / 2;
        continue;
      }
      half = double ? U : U / 2;
      if (double) {
        const x0 = dx > 0 ? x : x - U;
        out.push([x0, y - U, x0 + U, y + U, conn, outer]);
        x += dx * U;
      } else if (dx > 0) {
        out.push([x, y - U / 2, x + 2 * U, y + U / 2, conn, outer]);
        x += 2 * U;
      } else {
        out.push([x - 2 * U, y - U / 2, x, y + U / 2, outer, conn]);
        x -= 2 * U;
      }
    }
  }
  return out;
}

// El centro de la ficha del final de una punta (donde se elige).
function armEnd(g, side) {
  const rects = layout(g);
  if (!rects.length) return CENTER;
  if (!g.arms[side].length) {
    const [x0, y0, x1, y1] = rects[0];
    return side === "R" ? [x1 + U / 2, (y0 + y1) / 2] : [x0 - U / 2, (y0 + y1) / 2];
  }
  const r = side === "R" ? rects[g.arms.R.length] : rects[rects.length - 1];
  return [(r[0] + r[2]) / 2, (r[1] + r[3]) / 2];
}

// Las fichas del jugador, de pie, abajo.
function handRects(n) {
  const w = 44, h = 88, gap = 8;
  const x = (W - (n * w + (n - 1) * gap)) / 2;
  return Array.from({ length: n }, (_, i) => [x + i * (w + gap), 560, x + i * (w + gap) + w, 648]);
}

// ------------------------------------------------------------ el dibujo
// Un pincel sobre el contexto 2D, en las coordenadas de la mesa.
function pen(ctx, s) {
  const font = (size, bold) => `${bold ? "600 " : ""}${size * s}px system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif`;
  const path = (x0, y0, x1, y1, r) => {
    r = Math.min(r, (x1 - x0) / 2, (y1 - y0) / 2);
    ctx.beginPath();
    ctx.moveTo((x0 + r) * s, y0 * s);
    ctx.arcTo(x1 * s, y0 * s, x1 * s, y1 * s, r * s);
    ctx.arcTo(x1 * s, y1 * s, x0 * s, y1 * s, r * s);
    ctx.arcTo(x0 * s, y1 * s, x0 * s, y0 * s, r * s);
    ctx.arcTo(x0 * s, y0 * s, x1 * s, y0 * s, r * s);
    ctx.closePath();
  };
  const stroke = (color, width) => {
    if (!color) return;
    ctx.strokeStyle = color;
    ctx.lineWidth = Math.max(1, width * s);
    ctx.stroke();
  };
  return {
    rect(x0, y0, x1, y1, fill) {
      ctx.fillStyle = fill;
      ctx.fillRect(x0 * s, y0 * s, (x1 - x0) * s, (y1 - y0) * s);
    },
    round(x0, y0, x1, y1, r, fill, outline, width = 1) {
      path(x0, y0, x1, y1, r);
      ctx.fillStyle = fill;
      ctx.fill();
      stroke(outline, width);
    },
    oval(x0, y0, x1, y1, fill, outline, width = 1) {
      ctx.beginPath();
      ctx.ellipse(((x0 + x1) / 2) * s, ((y0 + y1) / 2) * s, ((x1 - x0) / 2) * s, ((y1 - y0) / 2) * s, 0, 0, Math.PI * 2);
      ctx.fillStyle = fill;
      ctx.fill();
      stroke(outline, width);
    },
    line(pts, color, width = 1) {
      ctx.beginPath();
      ctx.moveTo(pts[0] * s, pts[1] * s);
      for (let i = 2; i < pts.length; i += 2) ctx.lineTo(pts[i] * s, pts[i + 1] * s);
      ctx.lineCap = "round";
      stroke(color, width);
    },
    poly(pts, fill) {
      ctx.beginPath();
      ctx.moveTo(pts[0] * s, pts[1] * s);
      for (let i = 2; i < pts.length; i += 2) ctx.lineTo(pts[i] * s, pts[i + 1] * s);
      ctx.closePath();
      ctx.fillStyle = fill;
      ctx.fill();
    },
    text(x, y, str, size, fill, bold = false, anchor = "center") {
      ctx.font = font(size, bold);
      ctx.fillStyle = fill;
      ctx.textAlign = anchor === "w" ? "left" : anchor === "e" ? "right" : "center";
      ctx.textBaseline = "middle";
      ctx.fillText(str, x * s, y * s);
    },
  };
}

function drawPips(p, x0, y0, size, n, vertical) {
  if (!n) return;
  const m = size * 0.2, step = (size - 2 * m) / 2, r = Math.max(1.6, size * 0.085);
  for (let [row, col] of PIP_GRID[n]) {
    if (!vertical) [row, col] = [col, row];
    const cx = x0 + m + col * step, cy = y0 + m + row * step;
    p.oval(cx - r, cy - r, cx + r, cy + r, PIP_COLORS[n]);
  }
}

function drawTile(p, x0, y0, x1, y1, a, b, { face = true, glow = null, dim = false } = {}) {
  const w = x1 - x0, h = y1 - y0, vertical = h > w, r = Math.min(w, h) * 0.18;
  p.round(x0 + 1.5, y0 + 2.5, x1 + 1.5, y1 + 2.5, r, "#0e3a1f");
  if (glow) p.round(x0 - 3, y0 - 3, x1 + 3, y1 + 3, r + 3, glow);
  if (!face) {
    p.round(x0, y0, x1, y1, r, BACK, "#101a30");
    p.round(x0 + 3, y0 + 3, x1 - 3, y1 - 3, r * 0.7, "#2c4377");
    p.oval((x0 + x1) / 2 - 3, (y0 + y1) / 2 - 3, (x0 + x1) / 2 + 3, (y0 + y1) / 2 + 3, "#d9c27a");
    return;
  }
  p.round(x0, y0, x1, y1, r, dim ? "#e6e0d0" : IVORY, IVORY_EDGE);
  if (vertical) {
    p.line([x0 + w * 0.15, y0 + h / 2, x1 - w * 0.15, y0 + h / 2], "#9a9384", Math.max(1, w * 0.05));
    drawPips(p, x0, y0, w, a, true);
    drawPips(p, x0, y0 + h / 2, w, b, true);
  } else {
    p.line([x0 + w / 2, y0 + h * 0.15, x0 + w / 2, y1 - h * 0.15], "#9a9384", Math.max(1, h * 0.05));
    drawPips(p, x0, y0, h, a, false);
    drawPips(p, x0 + w / 2, y0, h, b, false);
  }
  const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
  p.oval(cx - 2, cy - 2, cx + 2, cy + 2, "#b8975a");
}

function draw(p, g, view, now) {
  p.rect(0, 0, W, H, RIM);
  p.round(10, 10, W - 10, H - 10, 40, "#6e4826");
  p.round(22, 22, W - 22, H - 22, 34, FELT_DARK);
  p.round(30, 30, W - 30, H - 30, 30, FELT);
  p.round(160, 120, W - 160, H - 140, 120, "#227743");
  // Marcador
  p.round(40, 40, 262, 120, 12, "#123f23", "#2f8a52");
  p.text(56, 58, TX.TEAM_US, 14, "#cfe9d6", true, "w");
  p.text(246, 58, String(g.scores[0]), 18, GOLD, true, "e");
  p.text(56, 84, TX.TEAM_THEM, 14, "#cfe9d6", true, "w");
  p.text(246, 84, String(g.scores[1]), 18, "#ffffff", true, "e");
  p.text(56, 107, TX.HAND.replace("{}", g.handNo) + "  ·  " + TX.TO.replace("{}", g.target), 12, "#9fc9ad", false, "w");
  // La cadena
  const rects = layout(g);
  const lastTile = g.last && g.last.tile && !g.result ? g.last.tile : null;
  for (const [x0, y0, x1, y1, a, b] of rects) {
    const glow = lastTile && ((lastTile[0] === a && lastTile[1] === b) || (lastTile[0] === b && lastTile[1] === a)) ? GOLD : null;
    drawTile(p, x0, y0, x1, y1, a, b, { glow });
  }
  if (!rects.length) p.text(CENTER[0], CENTER[1], TX.EMPTY, 16, "#9fc9ad");
  if (view.pending) {
    for (const side of ["L", "R"]) {
      const [x, y] = armEnd(g, side);
      const d = side === "L" ? -1 : 1;
      p.oval(x - 18, y - 18, x + 18, y + 18, GOLD, "#ffffff", 2);
      p.poly([x - 6 * d, y - 8, x + 8 * d, y, x - 6 * d, y + 8], "#3a2a00");
    }
  }
  for (let seat = 0; seat < 4; seat++) drawSeat(p, g, view, seat, now);
  if (view.message) {
    p.round(W / 2 - 240, 132, W / 2 + 240, 160, 14, "#123f23");
    p.text(W / 2, 146, view.message, 14, "#ffffff", true);
  }
  if (view.overlay && g.result) drawResult(p, g);
}

function drawSeat(p, g, view, seat, now) {
  const hand = g.hands[seat];
  const [x, y] = SEATS[seat];
  const turn = g.turn === seat && !g.result;
  const teamColor = teamOf(seat) === 0 ? GOLD : "#ff8a80";
  let plate;
  if (seat === SOUTH) {
    const moves = turn ? g.moves(SOUTH).map(([t]) => t) : [];
    handRects(hand.length).forEach((r, i) => {
      const t = hand[i];
      const can = moves.some((m) => same(m, t));
      const lift = can ? 6 : 0;
      const glow = can ? (view.pending && same(view.pending, t) ? GOLD : "#7fd39a") : null;
      drawTile(p, r[0], r[1] - lift, r[2], r[3] - lift, t[0], t[1], { glow, dim: turn && !can });
    });
    plate = [x - 80, 666, x + 80, 690];
  } else if (seat === NORTH) {
    const x0 = x - (hand.length * 30) / 2;
    hand.forEach((t, i) => drawTile(p, x0 + i * 30, 70, x0 + i * 30 + 26, 122, t[0], t[1], { face: view.showAll }));
    plate = [x - 80, 36, x + 80, 60];
  } else {
    const y0 = y - (hand.length * 26) / 2;
    hand.forEach((t, i) => drawTile(p, x - 26, y0 + i * 26, x + 26, y0 + i * 26 + 22, t[0], t[1], { face: view.showAll }));
    plate = [x - 60, y0 - 40, x + 60, y0 - 14];
  }
  const [px0, py0, px1, py1] = plate;
  if (turn) p.round(px0 - 3, py0 - 3, px1 + 3, py1 + 3, 15, GOLD);
  p.round(px0, py0, px1, py1, 12, "#0f2f1b", teamColor);
  p.text((px0 + px1) / 2, (py0 + py1) / 2, `${NAMES[seat]} · ${hand.length}`, 13, "#ffffff", true);
  const flash = view.flash[seat];
  if (flash && flash[1] > now) {
    const [bx, by] = { 0: [x + 130, 678], 2: [x + 130, 48], 3: [x + 6, py0 - 22], 1: [x - 6, py0 - 22] }[seat];
    p.round(bx - 34, by - 13, bx + 34, by + 13, 12, "#ffffff");
    p.text(bx, by, flash[0], 13, "#b3261e", true);
  }
}

function drawResult(p, g) {
  const res = g.result;
  p.round(250, 150, 850, 560, 22, "#0d2a17", GOLD, 2);
  p.text(550, 186, res.kind === "domino" ? TX.DOMINO.replace("{}", NAMES[res.player]) : TX.TRANQUE, 26, GOLD, true);
  let line;
  if (res.team === null) line = TX.TIE;
  else {
    line = res.kind === "tranque" ? TX.TRANQUE_WIN.replace("{}", NAMES[res.player]).replace("{}", res.totals[res.player]) + "  " : "";
    line += TX.POINTS.replace("{}", res.team === 0 ? TX.TEAM_US : TX.TEAM_THEM).replace("{}", res.points);
  }
  p.text(550, 222, line, 16, "#ffffff", true);
  p.text(550, 254, TX.LEFT_TILES, 13, "#9fc9ad");
  for (let seat = 0; seat < 4; seat++) {
    const y = 286 + seat * 48;
    p.text(282, y, NAMES[seat], 14, teamOf(seat) === 0 ? GOLD : "#ff8a80", true, "w");
    g.hands[seat].forEach((t, i) => drawTile(p, 392 + i * 44, y - 10, 392 + i * 44 + 40, y + 10, t[0], t[1]));
    p.text(818, y, String(res.totals[seat]), 15, "#ffffff", true, "e");
  }
  p.text(550, 486, `${TX.TEAM_US} ${g.scores[0]}  ·  ${TX.TEAM_THEM} ${g.scores[1]}`, 18, "#ffffff", true);
  if (g.over) {
    p.text(550, 516, g.winner === 0 ? TX.WIN_US : TX.WIN_THEM, 18, GOLD, true);
    p.text(550, 542, TX.AGAIN, 13, "#9fc9ad");
  } else {
    p.text(550, 528, TX.NEXT_HAND, 13, "#9fc9ad");
  }
}

// ------------------------------------------------------------ la app
export class App extends DmsApp {
  game = new Game();
  view = { pending: null, flash: {}, message: "", showAll: false, overlay: false };
  waitUntil = 0;
  scale = 1;

  async start() {
    this.newGame();
    // Juegan los de la computadora y pasa el que no lleva.
    setInterval(() => this.tick(), 150);
  }

  newGame() {
    const showAll = this.view.showAll;
    this.game = new Game();
    this.view = { pending: null, flash: {}, message: "", showAll, overlay: false };
    this.waitUntil = Date.now() + 1000;
    if (this.game.mustOpen) this.flash(this.game.turn, TX.OPENS);
    this.notify();
  }

  toggleAll() {
    this.view.showAll = !this.view.showAll;
    this.notify();
  }

  flash(seat, text) {
    this.view.flash[seat] = [text, Date.now() + 1600];
  }

  message() {
    const g = this.game, v = this.view;
    if (g.result) return "";
    if (g.turn === SOUTH) return v.pending ? TX.CHOOSE_END : g.moves(SOUTH).length ? TX.YOUR_TURN : TX.YOU_PASS;
    return TX.THINKING.replace("{}", NAMES[g.turn]);
  }

  tick() {
    const g = this.game, now = Date.now();
    if (g.result) {
      if (!this.view.overlay && now >= this.waitUntil) {
        this.view.overlay = true;
        this.notify();
      }
      return;
    }
    if (now < this.waitUntil) return;
    if (g.turn === SOUTH) {
      if (!g.moves(SOUTH).length) {
        g.pass(SOUTH);
        this.flash(SOUTH, TX.PASS);
        this.afterMove();
      }
      return;
    }
    const seat = g.turn;
    const move = choose(g, seat, Math.random);
    if (!move) {
      g.pass(seat);
      this.flash(seat, TX.PASS);
    } else g.play(seat, ...move);
    this.afterMove();
  }

  afterMove() {
    this.waitUntil = Date.now() + (this.game.result ? 1400 : 900);
    this.notify();
  }

  advance() {
    const g = this.game;
    if (!g.result) return;
    if (g.over) return this.newGame();
    g.newHand();
    this.view.overlay = false;
    this.view.pending = null;
    this.waitUntil = Date.now() + 1000;
    if (g.mustOpen) this.flash(g.turn, TX.OPENS);
    this.notify();
  }

  // ---- el lienzo: dibujar y tocar
  dibujar(ctx, w, h) {
    this.scale = Math.min(w / W, h / H);
    this.view.message = this.message();
    ctx.save();
    ctx.translate((w - W * this.scale) / 2, (h - H * this.scale) / 2);
    draw(pen(ctx, this.scale), this.game, this.view, Date.now());
    ctx.restore();
    this.size = [w, h];
  }

  tocar(x, y) {
    const [w, h] = this.size ?? [W, H];
    const s = this.scale;
    const ex = (x - (w - W * s) / 2) / s, ey = (y - (h - H * s) / 2) / s;
    const g = this.game, v = this.view;
    if (g.result) {
      if (v.overlay) this.advance();
      return;
    }
    if (g.turn !== SOUTH || Date.now() < this.waitUntil) return;
    if (v.pending) {
      for (const side of ["L", "R"]) {
        const [px, py] = armEnd(g, side);
        if (Math.abs(ex - px) <= 24 && Math.abs(ey - py) <= 24) return this.playMine(v.pending, side);
      }
    }
    v.pending = null;
    const rects = handRects(g.hands[SOUTH].length);
    const i = rects.findIndex((r) => ex >= r[0] && ex <= r[2] && ey >= r[1] - 12 && ey <= r[3]);
    if (i >= 0) {
      const tile = g.hands[SOUTH][i];
      const sides = g.moves(SOUTH).filter(([t]) => same(t, tile)).map(([, s]) => s);
      if (sides.length === 1) return this.playMine(tile, sides[0]);
      if (sides.length === 2) v.pending = tile;
    }
    this.notify();
  }

  playMine(tile, side) {
    this.view.pending = null;
    this.game.play(SOUTH, tile, side);
    this.afterMove();
  }
}

// ------------------------------------------------------------ pruebas
// Sin pantalla (node): partidas enteras con la computadora, la cadena que
// encaja, ninguna ficha que se pierda, la mesa sin fichas pisadas y la
// computadora contra el azar.
export function selftest() {
  const fails = [];
  const check = (ok, what) => { if (!ok) fails.push(what); };
  const key = (t) => `${Math.min(...t)}-${Math.max(...t)}`;
  check(fullSet().length === 55 && pips(fullSet()) === 495, "55 fichas y 495 tantos");
  const random = rng(5);
  let hands = 0, overlaps = 0, outside = 0, dominos = 0, tranques = 0;
  for (let n = 0; n < 30; n++) {
    const g = new Game(n + 1);
    while (!g.over && g.handNo < 60) {
      while (!g.result) {
        const m = choose(g, g.turn, random);
        if (m) g.play(g.turn, ...m); else g.pass(g.turn);
      }
      for (let i = 0; i + 1 < g.chain.length; i++) if (g.chain[i][1] !== g.chain[i + 1][0]) { check(false, "la cadena encaja"); break; }
      const all = [...g.hands.flat(), ...g.pool, ...g.chain].map(key).sort();
      check(all.join() === fullSet().map(key).sort().join(), "ninguna ficha se pierde ni se repite");
      const rects = layout(g);
      for (let i = 0; i < rects.length; i++) {
        const a = rects[i];
        if (a[0] < 40 || a[2] > W - 40 || a[1] < 130 || a[3] > 556) outside++;
        for (let j = i + 1; j < rects.length; j++) {
          const b = rects[j];
          if (Math.min(a[2], b[2]) - Math.max(a[0], b[0]) > 0.5 && Math.min(a[3], b[3]) - Math.max(a[1], b[1]) > 0.5) overlaps++;
        }
      }
      if (g.result.kind === "domino") dominos++; else tranques++;
      hands++;
      g.newHand();
    }
    check(g.over && Math.max(...g.scores) >= 100, "la partida llega a 100");
  }
  check(overlaps === 0, `las fichas no se pisan (${overlaps})`);
  check(outside === 0, `las fichas caben en la mesa (${outside})`);
  let wins = 0;
  for (let n = 0; n < 60; n++) {
    const g = new Game(1000 + n);
    while (!g.over) {
      while (!g.result) {
        const moves = g.moves(g.turn);
        if (!moves.length) g.pass(g.turn);
        else if (teamOf(g.turn) === 1) g.play(g.turn, ...choose(g, g.turn));
        else g.play(g.turn, ...moves[Math.floor(random() * moves.length)]);
      }
      g.newHand();
    }
    if (g.winner === 1) wins++;
  }
  check(wins > 33, `la computadora gana al azar (${wins} de 60)`);
  return { ok: fails.length === 0, fails, hands, dominos, tranques, wins };
}
''';
