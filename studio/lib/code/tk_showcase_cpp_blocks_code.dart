part of 'tk_examples.dart';

// El código en C++ de Bloques Neón (tk_showcase_cpp_blocks.dart): va tal cual
// en Form1.cpp, después de los textos (namespace tx).
const _blocksIncludes = r'''#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <string>
#include <thread>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifndef _WIN32
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif
''';

const _blocksCode = r'''
// ============================================================ el juego
// Bloques Neón: piezas de cuatro bloques que caen en un pozo de 10 × 20.
// Al llenar una fila, desaparece; cuantas más a la vez y más seguidas
// (combo), más puntos. Cada 10 filas sube el nivel y caen más deprisa.
namespace nb {

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}
// «1.452.890» (con el separador de miles del idioma).
std::string thousands(long long v) {
  std::string d = std::to_string(v < 0 ? -v : v), o;
  int n = (int)d.size();
  for (int i = 0; i < n; i++) {
    o += d[(size_t)i];
    int left = n - 1 - i;
    if (left > 0 && left % 3 == 0) o += tx::THOUSANDS;
  }
  return (v < 0 ? "-" : "") + o;
}
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}

const int W = 10, H = 20, HIDDEN = 2;   // dos filas ocultas encima del pozo
// Las siete piezas (I, O, T, S, Z, J, L): sus bloques en cada giro, en una
// caja de 4 × 4 (columna, fila).
struct Cell {
  int x, y;
};
const int PIECES = 7;
const unsigned PIECE_COLOR[PIECES] = {0x22d3ee, 0xfacc15, 0xa855f7, 0x22c55e, 0xef4444, 0x3b82f6, 0xf97316};
const Cell SHAPES[PIECES][4][4] = {
    // I
    {{{0, 1}, {1, 1}, {2, 1}, {3, 1}}, {{2, 0}, {2, 1}, {2, 2}, {2, 3}}, {{0, 2}, {1, 2}, {2, 2}, {3, 2}}, {{1, 0}, {1, 1}, {1, 2}, {1, 3}}},
    // O
    {{{1, 0}, {2, 0}, {1, 1}, {2, 1}}, {{1, 0}, {2, 0}, {1, 1}, {2, 1}}, {{1, 0}, {2, 0}, {1, 1}, {2, 1}}, {{1, 0}, {2, 0}, {1, 1}, {2, 1}}},
    // T
    {{{1, 0}, {0, 1}, {1, 1}, {2, 1}}, {{1, 0}, {1, 1}, {2, 1}, {1, 2}}, {{0, 1}, {1, 1}, {2, 1}, {1, 2}}, {{1, 0}, {0, 1}, {1, 1}, {1, 2}}},
    // S
    {{{1, 0}, {2, 0}, {0, 1}, {1, 1}}, {{1, 0}, {1, 1}, {2, 1}, {2, 2}}, {{1, 1}, {2, 1}, {0, 2}, {1, 2}}, {{0, 0}, {0, 1}, {1, 1}, {1, 2}}},
    // Z
    {{{0, 0}, {1, 0}, {1, 1}, {2, 1}}, {{2, 0}, {1, 1}, {2, 1}, {1, 2}}, {{0, 1}, {1, 1}, {1, 2}, {2, 2}}, {{1, 0}, {0, 1}, {1, 1}, {0, 2}}},
    // J
    {{{0, 0}, {0, 1}, {1, 1}, {2, 1}}, {{1, 0}, {2, 0}, {1, 1}, {1, 2}}, {{0, 1}, {1, 1}, {2, 1}, {2, 2}}, {{1, 0}, {1, 1}, {0, 2}, {1, 2}}},
    // L
    {{{2, 0}, {0, 1}, {1, 1}, {2, 1}}, {{1, 0}, {1, 1}, {1, 2}, {2, 2}}, {{0, 1}, {1, 1}, {2, 1}, {0, 2}}, {{0, 0}, {1, 0}, {1, 1}, {1, 2}}},
};

struct Piece {
  int kind = 0, rot = 0, x = 3, y = 0;
};

// Lo que pasó al fijar una pieza (para los efectos y el texto grande).
struct Clear {
  std::vector<int> rows;   // las filas que se limpiaron (en el pozo, antes de bajar)
  int lines = 0, combo = 0, points = 0;
  bool b2b = false, level_up = false;
};

class Game {
public:
  int grid[H + HIDDEN][W];   // 0 vacío; 1..7 la pieza (kind + 1)
  Piece cur;
  int hold = -1;
  bool hold_used = false, over = false, paused = false;
  std::vector<int> queue;   // las siguientes
  long long score = 0;
  int lines = 0, level = 1, combo = -1;
  bool last_quad = false;
  int start_level = 1;
  double fall_acc = 0, lock_timer = 0;
  int lock_moves = 0;
  uint32_t seed = 1;

  Game() { reset(1, 12345); }

  void reset(int lvl, uint32_t s) {
    for (auto& r : grid)
      for (auto& c : r) c = 0;
    seed = s ? s : 1;
    queue.clear();
    bag_fill();
    hold = -1;
    hold_used = false;
    over = false;
    paused = false;
    score = 0;
    lines = 0;
    start_level = level = std::max(1, std::min(15, lvl));
    combo = -1;
    last_quad = false;
    fall_acc = lock_timer = 0;
    lock_moves = 0;
    spawn(next_kind());
  }
  // La bolsa de siete: cada siete piezas salen las siete, en otro orden.
  uint32_t rnd() {
    seed ^= seed << 13;
    seed ^= seed >> 17;
    seed ^= seed << 5;
    return seed;
  }
  void bag_fill() {
    while (queue.size() < 7) {
      int bag[PIECES] = {0, 1, 2, 3, 4, 5, 6};
      for (int i = PIECES - 1; i > 0; i--) std::swap(bag[i], bag[rnd() % (uint32_t)(i + 1)]);
      for (int k : bag) queue.push_back(k);
    }
  }
  int next_kind() {
    int k = queue.front();
    queue.erase(queue.begin());
    bag_fill();
    return k;
  }
  bool fits(const Piece& p) const {
    for (const Cell& c : SHAPES[p.kind][p.rot]) {
      int x = p.x + c.x, y = p.y + c.y;
      if (x < 0 || x >= W || y >= H + HIDDEN) return false;
      if (y >= 0 && grid[y][x]) return false;
    }
    return true;
  }
  void spawn(int kind) {
    cur = Piece();
    cur.kind = kind;
    cur.x = kind == 1 ? 3 : 3;
    cur.y = kind == 0 ? 0 : 0;
    lock_timer = 0;
    lock_moves = 0;
    fall_acc = 0;
    if (!fits(cur)) over = true;
  }
  bool on_floor() const {
    Piece p = cur;
    p.y++;
    return !fits(p);
  }
  // Mover a un lado: true si se pudo. Al moverse en el suelo, se aplaza el
  // momento de fijarla (como mucho 15 veces).
  bool shift(int dx) {
    if (over || paused) return false;
    Piece p = cur;
    p.x += dx;
    if (!fits(p)) return false;
    cur = p;
    touch();
    return true;
  }
  // Girar (+1 a la derecha, -1 a la izquierda), probando a empujarla un poco
  // si choca con la pared o con otros bloques.
  bool rotate(int dir) {
    if (over || paused || cur.kind == 1) return false;
    static const Cell KICKS[] = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {-2, 0}, {2, 0}, {-1, -1}, {1, -1}};
    Piece p = cur;
    p.rot = (p.rot + dir + 4) % 4;
    for (const Cell& k : KICKS) {
      Piece q = p;
      q.x += k.x;
      q.y += k.y;
      if (fits(q)) {
        cur = q;
        touch();
        return true;
      }
    }
    return false;
  }
  void touch() {
    if (on_floor() && lock_moves < 15) {
      lock_timer = 0;
      lock_moves++;
    }
  }
  // Bajar una fila (caída suave: 1 punto).
  bool soft_drop() {
    if (over || paused) return false;
    Piece p = cur;
    p.y++;
    if (!fits(p)) return false;
    cur = p;
    score += 1;
    fall_acc = 0;
    return true;
  }
  int ghost_y() const {
    Piece p = cur;
    while (true) {
      p.y++;
      if (!fits(p)) return p.y - 1;
    }
  }
  // Caída rápida: 2 puntos por fila y se fija enseguida.
  Clear hard_drop() {
    if (over || paused) return Clear();
    int gy = ghost_y();
    score += 2 * (gy - cur.y);
    cur.y = gy;
    return lock();
  }
  // Guardar la pieza (una vez por pieza).
  bool do_hold() {
    if (over || paused || hold_used) return false;
    int k = cur.kind;
    if (hold < 0) spawn(next_kind());
    else spawn(hold);
    hold = k;
    hold_used = true;
    return true;
  }
  // Segundos por fila según el nivel (cada vez más deprisa).
  double gravity() const {
    double t = 0.8 - (level - 1) * 0.007;
    return std::max(0.012, std::pow(t, level - 1));
  }
  // Avanzar el tiempo [dt] segundos (y la caída suave si [soft]).
  Clear step(double dt) {
    Clear c;
    if (over || paused) return c;
    if (on_floor()) {
      lock_timer += dt;
      if (lock_timer >= 0.5) return lock();
      return c;
    }
    fall_acc += dt;
    double g = gravity();
    while (fall_acc >= g) {
      fall_acc -= g;
      Piece p = cur;
      p.y++;
      if (!fits(p)) break;
      cur = p;
    }
    return c;
  }
  // Fijar la pieza, limpiar las filas llenas y sacar la siguiente.
  Clear lock() {
    Clear c;
    bool above = true;
    for (const Cell& b : SHAPES[cur.kind][cur.rot]) {
      int x = cur.x + b.x, y = cur.y + b.y;
      if (y >= 0 && y < H + HIDDEN) grid[y][x] = cur.kind + 1;
      if (y >= HIDDEN) above = false;
    }
    for (int y = 0; y < H + HIDDEN; y++) {
      bool full = true;
      for (int x = 0; x < W; x++) full = full && grid[y][x];
      if (full) c.rows.push_back(y);
    }
    for (int y : c.rows) {
      for (int yy = y; yy > 0; yy--)
        for (int x = 0; x < W; x++) grid[yy][x] = grid[yy - 1][x];
      for (int x = 0; x < W; x++) grid[0][x] = 0;
    }
    c.lines = (int)c.rows.size();
    if (c.lines > 0) {
      static const int BASE[5] = {0, 100, 300, 500, 800};
      combo++;
      int pts = BASE[c.lines] * level;
      if (c.lines == 4 && last_quad) {
        pts = pts * 3 / 2;   // dos de cuatro seguidas: la mitad más
        c.b2b = true;
      }
      last_quad = c.lines == 4;
      pts += 50 * combo * level;
      c.points = pts;
      c.combo = combo;
      score += pts;
      int before = level;
      lines += c.lines;
      level = std::max(start_level, 1 + lines / 10);
      c.level_up = level > before;
    } else {
      combo = -1;
    }
    hold_used = false;
    if (above && c.lines == 0) over = true;   // fijada entera fuera del pozo
    else spawn(next_kind());
    return c;
  }
  // Las filas que faltan para el nivel siguiente.
  int goal_done() const { return lines % 10; }
};

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_BLOCKS_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\blocks";
#else
  const char* h = fl_getenv("HOME");
#ifdef __APPLE__
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/blocks";
#else
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/blocks";
#endif
#endif
}
long long read_best() {
  FILE* f = fl_fopen((config_dir() + "/record.txt").c_str(), "rb");
  if (!f) return 0;
  long long v = 0;
  if (std::fscanf(f, "%lld", &v) != 1) v = 0;
  std::fclose(f);
  return v;
}
void write_best(long long v) {
  fl_make_path(config_dir().c_str());
  FILE* f = fl_fopen((config_dir() + "/record.txt").c_str(), "wb");
  if (!f) return;
  std::fprintf(f, "%lld\n", v);
  std::fclose(f);
}

// ------------------------------------------------------------ sonido
// Los sonidos del sistema (macOS), sin esperar.
void sound(const char* name) {
#ifdef __APPLE__
  std::string path = std::string("/System/Library/Sounds/") + name + ".aiff";
  if (access(path.c_str(), R_OK) != 0) return;
  const char* argv[] = {"/usr/bin/afplay", "-v", "0.6", path.c_str(), nullptr};
  pid_t pid;
  if (posix_spawn(&pid, argv[0], nullptr, nullptr, const_cast<char**>(argv), environ) == 0) {
    std::thread([pid] {
      int st = 0;
      waitpid(pid, &st, 0);
    }).detach();
  }
#else
  (void)name;
#endif
}

// ------------------------------------------------------------ dibujar
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)((v >> 8) & 255), (uchar)(v & 255)); }
unsigned mix(unsigned a, unsigned b, double t) {
  t = std::max(0.0, std::min(1.0, t));
  auto ch = [&](int s) { return (unsigned)std::lround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t); };
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}
void rect(int x, int y, int w, int h, unsigned c) {
  fl_color(rgb(c));
  fl_rectf(x, y, w, h);
}
// Un borde que brilla: varias rayas cada vez más tenues hacia fuera.
void glow_frame(int x, int y, int w, int h, unsigned c, unsigned bg, int r) {
  for (int k = 6; k >= 1; k--) {
    fl_color(rgb(mix(c, bg, 0.55 + k * 0.07)));
    fl_rounded_rect(x - k, y - k, w + 2 * k, h + 2 * k, r + k);
  }
  fl_color(rgb(c));
  fl_line_style(FL_SOLID, 2);
  fl_rounded_rect(x, y, w, h, r);
  fl_line_style(0);
}
void glow_text(const std::string& s, int x, int y, int size, unsigned c, unsigned bg, bool bold = true) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  for (int k = 3; k >= 1; k--) {
    fl_color(rgb(mix(c, bg, 0.6 + k * 0.1)));
    for (int dx = -k; dx <= k; dx += k)
      for (int dy = -k; dy <= k; dy += k) fl_draw(s.c_str(), x + dx, y + dy);
  }
  fl_color(rgb(mix(c, 0xffffff, 0.35)));
  fl_draw(s.c_str(), x, y);
}
int text_w(const std::string& s, int size, bool bold = true) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  return (int)fl_width(s.c_str());
}
// Un bloque de cristal: el color con luz arriba y un filo claro.
void block(int x, int y, int s, unsigned c) {
  rect(x, y, s, s, mix(c, 0x000000, 0.35));
  rect(x + 2, y + 2, s - 4, s - 4, c);
  rect(x + 2, y + 2, s - 4, (s - 4) * 4 / 10, mix(c, 0xffffff, 0.28));
  rect(x + 4, y + 4, s - 8, 2, mix(c, 0xffffff, 0.65));
  rect(x + 2, y + s - 5, s - 4, 3, mix(c, 0x000000, 0.2));
  fl_color(rgb(mix(c, 0xffffff, 0.45)));
  fl_rect(x + 1, y + 1, s - 2, s - 2);
}
void ghost(int x, int y, int s, unsigned c) {
  fl_color(rgb(mix(c, 0x0b1020, 0.35)));
  fl_line_style(FL_SOLID, 2);
  fl_rect(x + 3, y + 3, s - 6, s - 6);
  fl_line_style(0);
}
// Una pieza pequeña, centrada en una caja (para la reserva y las siguientes).
void mini(int kind, int cx, int cy, int s, bool dim = false) {
  int minx = 9, maxx = -9, miny = 9, maxy = -9;
  for (const Cell& c : SHAPES[kind][0]) {
    minx = std::min(minx, c.x);
    maxx = std::max(maxx, c.x);
    miny = std::min(miny, c.y);
    maxy = std::max(maxy, c.y);
  }
  int w = (maxx - minx + 1) * s, h = (maxy - miny + 1) * s;
  unsigned col = dim ? mix(PIECE_COLOR[kind], 0x1a1f2e, 0.6) : PIECE_COLOR[kind];
  for (const Cell& c : SHAPES[kind][0]) block(cx - w / 2 + (c.x - minx) * s, cy - h / 2 + (c.y - miny) * s, s, col);
}

struct Particle {
  double x, y, vx, vy, life, max;
  unsigned c;
};
// El texto grande que salta (¡4 LÍNEAS!, COMBO x5…).
struct Banner {
  std::string big, small;
  unsigned c = 0x22d3ee;
  double t0 = -100;
};

const unsigned BG = 0x070a18;

// La pantalla del juego: la ciudad, el pozo, los paneles y los efectos.
class Arena : public Fl_Widget {
public:
  Game* g = nullptr;
  int mode = 0;   // 0 título, 1 jugando, 2 fin
  long long best = 0;
  bool new_best = false;
  std::vector<Particle> parts;
  std::vector<int> flash_rows;
  double flash_t0 = -100, shake_t0 = -100, now = 0;
  Banner banner;
  std::function<void(int, bool)> on_key;
  std::function<void()> on_click;
  int cell = 30, bx = 0, by = 0;   // dónde está el pozo (después de dibujar)

  Arena(int X, int Y, int W_, int H_) : Fl_Widget(X, Y, W_, H_, nullptr) {}

  int handle(int e) override {
    switch (e) {
      case FL_FOCUS:
      case FL_UNFOCUS: return 1;
      case FL_PUSH:
        if (window() && window()->shown()) take_focus();
        if (on_click) on_click();
        return 1;
      case FL_KEYBOARD:
        if (on_key) on_key(Fl::event_key(), true);
        return 1;
      case FL_KEYUP:
        if (on_key) on_key(Fl::event_key(), false);
        return 1;
    }
    return Fl_Widget::handle(e);
  }

  // Los efectos de unas filas limpiadas (en coordenadas del pozo).
  void burst(const Clear& c, uint32_t& seed) {
    auto r = [&]() {
      seed = seed * 1664525u + 1013904223u;
      return (seed >> 8) / 16777216.0;
    };
    flash_rows = c.rows;
    flash_t0 = now;
    for (int row : c.rows) {
      for (int k = 0; k < 46; k++) {
        Particle p;
        p.x = r() * W;
        p.y = row - HIDDEN + 0.5;
        double side = r() < 0.5 ? -1 : 1;
        p.vx = side * (3 + r() * 14);
        p.vy = (r() - 0.6) * 9;
        p.max = p.life = 0.5 + r() * 0.7;
        const unsigned cs[] = {0xffffff, 0x9fe8ff, 0x22d3ee, 0x60a5fa};
        p.c = cs[(int)(r() * 4) % 4];
        parts.push_back(p);
      }
    }
    if (c.lines == 4) shake_t0 = now;
  }
  void advance(double dt) {
    for (auto& p : parts) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 14 * dt;
      p.life -= dt;
    }
    parts.erase(std::remove_if(parts.begin(), parts.end(), [](const Particle& p) { return p.life <= 0; }), parts.end());
  }

  void draw() override {
    fl_push_clip(x(), y(), w(), h());
    double sh = now - shake_t0;
    int ox = 0, oy = 0;
    if (sh < 0.35) {
      double a = (0.35 - sh) / 0.35 * 7;
      ox = (int)std::lround(std::sin(sh * 90) * a);
      oy = (int)std::lround(std::cos(sh * 70) * a * 0.6);
    }
    city(x(), y(), w(), h());
    cell = std::max(18, std::min(32, (h() - 120) / H));
    int pw = W * cell, ph = H * cell;
    bx = x() + (w() - pw) / 2 + ox;
    by = y() + (h() - ph) / 2 + 10 + oy;
    well(bx, by);
    panels(bx, by, pw, ph);
    if (mode == 0) title_screen(bx, by, pw, ph);
    else if (g && g->paused) overlay(bx, by, pw, ph, tx::PAUSED, tx::PAUSED_HINT, 0x22d3ee);
    else if (mode == 2) game_over(bx, by, pw, ph);
    fl_pop_clip();
  }

  // ---- la ciudad de noche (siempre la misma: semilla fija)
  void city(int X, int Y, int Wd, int Hd) {
    for (int yy = 0; yy < Hd; yy += 2) rect(X, Y + yy, Wd, 2, mix(0x05071a, 0x2a0f45, (double)yy / Hd));
    uint32_t s = 7;
    auto r = [&]() {
      s = s * 1664525u + 1013904223u;
      return (s >> 8) / 16777216.0;
    };
    for (int k = 0; k < 70; k++) {
      int sx = X + (int)(r() * Wd), sy = Y + (int)(r() * Hd * 0.35);
      rect(sx, sy, 2, 2, mix(0xffffff, 0x05071a, 0.3 + r() * 0.5));
    }
    // Edificios lejanos y cercanos, con ventanas encendidas.
    for (int layer = 0; layer < 2; layer++) {
      int xx = X - 20;
      while (xx < X + Wd) {
        int bw = 50 + (int)(r() * (layer ? 110 : 80));
        int bh = (int)(Hd * (layer ? 0.35 + r() * 0.45 : 0.45 + r() * 0.35));
        int top = Y + Hd - bh;
        unsigned body = layer ? 0x0c1024 : 0x161a38;
        rect(xx, top, bw, bh, body);
        for (int wy = top + 12; wy < Y + Hd - 40; wy += 14)
          for (int wx = xx + 8; wx < xx + bw - 8; wx += 12)
            if (r() < (layer ? 0.32 : 0.18)) {
              const unsigned wc[] = {0xffd27a, 0x7fd8ff, 0xff8fd8, 0xfff1c1};
              rect(wx, wy, 6, 8, mix(wc[(int)(r() * 4) % 4], body, layer ? 0.15 : 0.55));
            }
        xx += bw + (int)(r() * 16);
      }
    }
    // Letreros de neón (sus propios textos).
    const char* signs[] = {tx::SIGN_1, tx::SIGN_2, tx::SIGN_3, tx::SIGN_4, tx::SIGN_5};
    const unsigned sc[] = {0xff4fd8, 0x22d3ee, 0xfacc15, 0xa855f7, 0xff6b4a};
    int sx[] = {X + 28, X + 92, X + Wd - 110, X + Wd - 56, X + 92};
    int sy[] = {Y + 70, Y + 280, Y + 90, Y + 300, Y + Hd - 140};
    for (int k = 0; k < 5; k++) {
      std::string t = signs[k];
      bool vertical = k == 0 || k == 2 || k == 3;
      if (vertical) {
        int n = 0;
        for (size_t i = 0; i < t.size(); i++)
          if (((unsigned char)t[i] & 0xc0) != 0x80) n++;
        int bh = n * 30 + 20;
        rect(sx[k], sy[k], 46, bh, 0x0a0c1c);
        glow_frame(sx[k], sy[k], 46, bh, sc[k], 0x0a0c1c, 6);
        int row = 0;
        for (size_t i = 0; i < t.size();) {
          size_t len = 1;
          unsigned char c0 = (unsigned char)t[i];
          if (c0 >= 0xf0) len = 4;
          else if (c0 >= 0xe0) len = 3;
          else if (c0 >= 0xc0) len = 2;
          std::string ch = t.substr(i, len);
          glow_text(ch, sx[k] + 23 - text_w(ch, 22) / 2, sy[k] + 34 + row * 30, 22, sc[k], 0x0a0c1c);
          i += len;
          row++;
        }
      } else {
        int bw = text_w(t, 24) + 30;
        rect(sx[k] - bw / 2, sy[k], bw, 44, 0x0a0c1c);
        glow_frame(sx[k] - bw / 2, sy[k], bw, 44, sc[k], 0x0a0c1c, 8);
        glow_text(t, sx[k] - bw / 2 + 15, sy[k] + 31, 24, sc[k], 0x0a0c1c);
      }
    }
    // La barandilla y la calle con luces.
    rect(X, Y + Hd - 46, Wd, 46, 0x0b0d1a);
    rect(X, Y + Hd - 48, Wd, 3, 0x2b3150);
    for (int k = 0; k < 14; k++) {
      int lx = X + (int)(r() * Wd), lw = 30 + (int)(r() * 90);
      rect(lx, Y + Hd - 30 + (int)(r() * 20), lw, 2, r() < 0.5 ? 0xff5a5a : 0xfff1c1);
    }
  }

  // ---- el pozo
  void well(int X, int Y) {
    int pw = W * cell, ph = H * cell;
    rect(X - 10, Y - 10, pw + 20, ph + 20, 0x0a0f22);
    glow_frame(X - 10, Y - 10, pw + 20, ph + 20, 0x38bdf8, BG, 10);
    rect(X, Y, pw, ph, 0x060914);
    fl_color(rgb(0x121a33));
    for (int i = 1; i < W; i++) fl_line(X + i * cell, Y, X + i * cell, Y + ph);
    for (int j = 1; j < H; j++) fl_line(X, Y + j * cell, X + pw, Y + j * cell);
    if (!g) return;
    for (int yy = HIDDEN; yy < H + HIDDEN; yy++)
      for (int xx = 0; xx < W; xx++)
        if (g->grid[yy][xx]) block(X + xx * cell, Y + (yy - HIDDEN) * cell, cell, PIECE_COLOR[g->grid[yy][xx] - 1]);
    if (mode == 1 && !g->over) {
      int gy = g->ghost_y();
      for (const Cell& c : SHAPES[g->cur.kind][g->cur.rot]) {
        int yy = gy + c.y - HIDDEN;
        if (yy >= 0) ghost(X + (g->cur.x + c.x) * cell, Y + yy * cell, cell, PIECE_COLOR[g->cur.kind]);
      }
      for (const Cell& c : SHAPES[g->cur.kind][g->cur.rot]) {
        int yy = g->cur.y + c.y - HIDDEN;
        if (yy >= 0) block(X + (g->cur.x + c.x) * cell, Y + yy * cell, cell, PIECE_COLOR[g->cur.kind]);
      }
    }
    // El destello de las filas que se acaban de limpiar.
    double ft = now - flash_t0;
    if (ft < 0.45)
      for (int row : flash_rows) {
        double a = 1 - ft / 0.45;
        int ry = Y + (row - HIDDEN) * cell;
        rect(X - 14, ry - 2, pw + 28, cell + 4, mix(0x060914, 0xbff3ff, a * 0.85));
        rect(X - 40, ry + cell / 2 - 1, pw + 80, 3, mix(0x060914, 0xffffff, a));
      }
    for (const auto& p : parts) {
      double a = p.life / p.max;
      int px = X + (int)(p.x * cell), py = Y + (int)(p.y * cell);
      int sz = a > 0.5 ? 3 : 2;
      rect(px, py, sz, sz, mix(BG, p.c, a));
    }
  }

  // ---- los paneles
  void box(int X, int Y, int Wd, int Hd, const char* title) {
    rect(X, Y, Wd, Hd, 0x0b1022);
    glow_frame(X, Y, Wd, Hd, 0x5b6b9a, BG, 8);
    std::string t = title;
    glow_text(t, X + (Wd - text_w(t, 18)) / 2, Y + 28, 18, 0xe2e8ff, 0x0b1022);
  }
  void stat(int X, int Y, int Wd, const std::string& label, const std::string& value, unsigned c, int size) {
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(0x94a3c8));
    fl_draw(label.c_str(), X + 16, Y);
    glow_text(value, X + Wd - 16 - text_w(value, size), Y + 2, size, c, 0x0b1022);
  }
  void panels(int X, int Y, int pw, int ph) {
    int side = 200, gap = 34;
    int lx = X - gap - side, rx = X + pw + gap;
    // La reserva.
    box(lx, Y, side, 130, tx::HOLD);
    if (g && g->hold >= 0) mini(g->hold, lx + side / 2, Y + 82, 24, g->hold_used);
    // Nivel, puntos y meta.
    int sy = Y + ph - 250;
    rect(lx, sy, side, 250, 0x0b1022);
    glow_frame(lx, sy, side, 250, 0x5b6b9a, BG, 8);
    if (g) {
      stat(lx, sy + 40, side, tx::LEVEL, std::to_string(g->level), 0xffffff, 24);
      fl_color(rgb(0x1f2a4a));
      fl_line(lx + 12, sy + 62, lx + side - 12, sy + 62);
      fl_font(FL_HELVETICA_BOLD, 15);
      fl_color(rgb(0x94a3c8));
      fl_draw(tx::SCORE, lx + 16, sy + 92);
      std::string sc = thousands(g->score);
      int size = 30;
      while (size > 16 && text_w(sc, size) > side - 32) size -= 2;
      glow_text(sc, lx + side - 16 - text_w(sc, size), sy + 132, size, 0x7dd3fc, 0x0b1022);
      fl_color(rgb(0x1f2a4a));
      fl_line(lx + 12, sy + 152, lx + side - 12, sy + 152);
      stat(lx, sy + 186, side, tx::GOAL, fmt(tx::GOAL_N, {std::to_string(g->goal_done())}), 0xfacc15, 22);
      stat(lx, sy + 226, side, tx::BEST, thousands(std::max(best, g->score)), 0xa5b4fc, 16);
    }
    // Las siguientes.
    box(rx, Y, side, 300, tx::NEXT);
    if (g)
      for (int k = 0; k < 3 && k < (int)g->queue.size(); k++) mini(g->queue[(size_t)k], rx + side / 2, Y + 86 + k * 76, k == 0 ? 26 : 22);
    // Las líneas.
    rect(rx, Y + ph - 70, side, 70, 0x0b1022);
    glow_frame(rx, Y + ph - 70, side, 70, 0x5b6b9a, BG, 8);
    if (g) stat(rx, Y + ph - 26, side, tx::LINES, thousands(g->lines), 0xffffff, 24);
    // El texto grande, a la derecha del pozo.
    double bt = now - banner.t0;
    if (bt < 1.8 && !banner.big.empty()) {
      double pop = bt < 0.18 ? 1.35 - 0.35 * (bt / 0.18) : 1.0;
      double fade = bt > 1.3 ? (bt - 1.3) / 0.5 : 0;
      // Centrado sobre el pozo, como un rótulo que salta.
      int base = 46;
      while (base > 20 && text_w(banner.big, base) > pw + 120) base -= 2;
      int size = (int)std::lround(base * pop);
      unsigned c = mix(banner.c, BG, fade);
      int cx = X + pw / 2, ty = Y + ph / 3;
      glow_text(banner.big, cx - text_w(banner.big, size) / 2, ty, size, c, BG);
      if (!banner.small.empty())
        glow_text(banner.small, cx - text_w(banner.small, 28) / 2, ty + 48, 28, mix(0xffffff, BG, fade), BG);
    }
  }

  // ---- encima del pozo
  void overlay(int X, int Y, int pw, int ph, const std::string& big, const std::string& small, unsigned c) {
    rect(X, Y + ph / 2 - 70, pw, 140, 0x070b18);
    glow_frame(X, Y + ph / 2 - 70, pw, 140, c, BG, 6);
    int s = 34;
    while (s > 18 && text_w(big, s) > pw - 20) s -= 2;
    glow_text(big, X + (pw - text_w(big, s)) / 2, Y + ph / 2 - 6, s, c, 0x070b18);
    fl_font(FL_HELVETICA, 14);
    fl_color(rgb(0xc7d2fe));
    fl_draw(small.c_str(), X + 10, Y + ph / 2 + 18, pw - 20, 40, FL_ALIGN_CENTER | FL_ALIGN_TOP | FL_ALIGN_WRAP | FL_ALIGN_INSIDE, nullptr, 0);
  }
  void title_screen(int X, int Y, int pw, int ph) {
    rect(X, Y + 60, pw, ph - 120, 0x070b18);
    glow_frame(X, Y + 60, pw, ph - 120, 0xff4fd8, BG, 8);
    std::string t1 = tx::TITLE_1, t2 = tx::TITLE_2;
    int s = 44;
    while (s > 20 && std::max(text_w(t1, s), text_w(t2, s)) > pw - 30) s -= 2;
    glow_text(t1, X + (pw - text_w(t1, s)) / 2, Y + 140, s, 0x22d3ee, 0x070b18);
    glow_text(t2, X + (pw - text_w(t2, s)) / 2, Y + 140 + s + 8, s, 0xff4fd8, 0x070b18);
    // Unas piezas de adorno.
    mini(2, X + pw / 2 - 70, Y + 270, 20);
    mini(0, X + pw / 2 + 50, Y + 260, 20);
    std::string go = tx::PRESS_START;
    double blink = std::fmod(now, 1.2) < 0.8 ? 0 : 0.6;
    glow_text(go, X + (pw - text_w(go, 18)) / 2, Y + 340, 18, mix(0xfacc15, 0x070b18, blink), 0x070b18);
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(0xa5b4fc));
    fl_draw(tx::CONTROLS, X + 16, Y + 370, pw - 32, ph - 450, FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP | FL_ALIGN_INSIDE, nullptr, 0);
  }
  void game_over(int X, int Y, int pw, int ph) {
    std::string sub = fmt(tx::OVER_SCORE, {thousands(g ? g->score : 0)});
    if (new_best) sub += "\n" + std::string(tx::NEW_BEST);
    sub += "\n" + std::string(tx::PRESS_START);
    rect(X, Y + ph / 2 - 90, pw, 180, 0x070b18);
    glow_frame(X, Y + ph / 2 - 90, pw, 180, 0xef4444, BG, 6);
    std::string big = tx::GAME_OVER;
    int s = 36;
    while (s > 18 && text_w(big, s) > pw - 20) s -= 2;
    glow_text(big, X + (pw - text_w(big, s)) / 2, Y + ph / 2 - 30, s, 0xef4444, 0x070b18);
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(0xe2e8ff));
    fl_draw(sub.c_str(), X + 10, Y + ph / 2 - 10, pw - 20, 90, FL_ALIGN_CENTER | FL_ALIGN_TOP | FL_ALIGN_WRAP | FL_ALIGN_INSIDE, nullptr, 0);
  }
};

// ------------------------------------------------------------ pruebas
int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  Game g;
  // La bolsa: las siete primeras son las siete piezas.
  {
    Game b;
    b.reset(1, 99);
    std::vector<int> seen = {b.cur.kind};
    for (int k = 0; k < 6; k++) seen.push_back(b.queue[(size_t)k]);
    std::sort(seen.begin(), seen.end());
    bool all = true;
    for (int k = 0; k < 7; k++) all = all && seen[(size_t)k] == k;
    chk(all, "bolsa de siete");
  }
  // Cada giro de cada pieza tiene cuatro bloques distintos dentro de la caja.
  for (int p = 0; p < PIECES; p++)
    for (int r = 0; r < 4; r++) {
      bool ok = true;
      for (int a = 0; a < 4; a++)
        for (int b = a + 1; b < 4; b++)
          ok = ok && !(SHAPES[p][r][a].x == SHAPES[p][r][b].x && SHAPES[p][r][a].y == SHAPES[p][r][b].y);
      chk(ok, "bloques de las piezas");
    }
  // Mover hasta la pared y no más.
  g.reset(1, 5);
  int moved = 0;
  while (g.shift(-1)) moved++;
  int x0 = g.cur.x;
  chk(moved > 0 && !g.shift(-1), "pared izquierda");
  // Girar la I pegada a la pared: el rebote la deja dentro.
  g.reset(1, 5);
  g.cur.kind = 0;
  g.cur.rot = 1;
  g.cur.x = -2;   // vertical, en la columna 0
  chk(g.fits(g.cur), "I vertical en la pared");
  chk(g.rotate(1) && g.fits(g.cur), "giro con rebote en la pared");
  (void)x0;
  // La fantasma y la caída rápida (2 puntos por fila).
  g.reset(1, 5);
  int gy = g.ghost_y();
  long long s0 = g.score;
  int y0 = g.cur.y;
  g.hard_drop();
  chk(g.score - s0 == 2 * (gy - y0), "caída rápida");
  // Limpiar cuatro filas a la vez con una I vertical.
  g.reset(1, 5);
  for (int y = H + HIDDEN - 4; y < H + HIDDEN; y++)
    for (int x = 0; x < W; x++) g.grid[y][x] = x == 9 ? 0 : 3;
  g.cur.kind = 0;
  g.cur.rot = 1;
  g.cur.x = 7;   // la columna 9
  g.cur.y = 0;
  chk(g.fits(g.cur), "I sobre el hueco");
  Clear c = g.hard_drop();
  chk(c.lines == 4 && g.lines == 4, "cuatro filas");
  bool empty = true;
  for (int y = 0; y < H + HIDDEN; y++)
    for (int x = 0; x < W; x++) empty = empty && !g.grid[y][x];
  chk(empty, "el pozo vacío");
  chk(c.points == 800 && c.combo == 0, "puntos de cuatro filas");
  // Otra de cuatro seguida: la mitad más y combo 1.
  for (int y = H + HIDDEN - 4; y < H + HIDDEN; y++)
    for (int x = 0; x < W; x++) g.grid[y][x] = x == 0 ? 0 : 5;
  g.cur.kind = 0;
  g.cur.rot = 1;
  g.cur.x = -2;
  g.cur.y = 0;
  c = g.hard_drop();
  chk(c.lines == 4 && c.b2b && c.combo == 1 && c.points == 1200 + 50, "dos de cuatro seguidas y combo");
  // Una pieza que no limpia rompe el combo.
  g.cur.kind = 1;
  g.cur.rot = 0;
  g.cur.x = 3;
  g.cur.y = 0;
  g.hard_drop();
  chk(g.combo == -1, "combo roto");
  // Subir de nivel cada 10 filas y caer más deprisa.
  Game l;
  l.reset(1, 3);
  double g1 = l.gravity();
  l.lines = 9;
  for (int x = 0; x < W; x++) l.grid[H + HIDDEN - 1][x] = x == 4 ? 0 : 2;
  l.cur.kind = 0;
  l.cur.rot = 1;
  l.cur.x = 2;
  l.cur.y = 0;
  c = l.hard_drop();
  chk(c.lines == 1 && l.level == 2 && c.level_up, "subir de nivel");
  chk(l.gravity() < g1, "más deprisa");
  // Guardar la pieza: una vez por pieza.
  g.reset(1, 8);
  int k0 = g.cur.kind;
  chk(g.do_hold() && g.hold == k0 && !g.do_hold(), "reserva una vez");
  // Fijar al quedarse medio segundo en el suelo.
  g.reset(1, 8);
  g.cur.y = g.ghost_y();
  int kind = g.cur.kind;
  g.step(0.3);
  chk(g.cur.kind == kind && g.cur.y == g.ghost_y(), "todavía no se fija");
  c = g.step(0.3);
  chk(g.cur.y < 5, "se fija y sale otra");
  // Fin: el pozo lleno hasta arriba.
  g.reset(1, 8);
  for (int y = 0; y < H + HIDDEN; y++)
    for (int x = 0; x < W; x++) g.grid[y][x] = (x + y) % 2 ? 1 : 0;
  g.spawn(2);
  chk(g.over, "fin de la partida");
  chk(thousands(1452890) == "1" + std::string(tx::THOUSANDS) + "452" + tx::THOUSANDS + "890", "miles");
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace nb

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  nb::Game game;
  nb::Arena* arena = nullptr;
  double last = 0, das_t = 0, soft_t = 0;
  int held = 0;   // -1 izquierda, +1 derecha
  bool soft = false, sound = true, live = true;
  uint32_t fx_seed = 99;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }
  Form1() {
    if (fl_getenv("DMS_BLOCKS_SELFTEST")) std::exit(nb::selftest());
    if (fl_getenv("DMS_BLOCKS_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_BLOCKS_SHOT")) { set_fonts(); std::exit(shots(d)); }
  }
  static void set_fonts() {
#ifdef _WIN32
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
#endif
  }
  void setup() {
    self() = this;
    BoardHint->hide();
    Board->box(FL_FLAT_BOX);
    resizable(Board);
    size_range(900, 640);
    arena = new nb::Arena(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(arena);
    Board->resizable(arena);
    arena->g = &game;
    arena->on_key = [](int k, bool down) { if (self()) self()->key(k, down); };
    arena->on_click = [] { if (self() && self()->arena->mode != 1) self()->new_game(); };
    // Esc no cierra la ventana (es la pausa).
    callback([](Fl_Widget* w, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      w->hide();
    });
  }
  void form_create() override {
    set_fonts();
    setup();
    arena->best = nb::read_best();
    arena->take_focus();
  }

  void new_game() {
    game.reset(1, (uint32_t)(nb::now_s() * 1000) ^ 0x9e3779b9u);
    arena->mode = 1;
    arena->new_best = false;
    arena->parts.clear();
    arena->banner = nb::Banner();
    held = 0;
    soft = false;
    if (live) arena->take_focus();
  }
  void play(const char* name) {
    if (sound && live) nb::sound(name);
  }
  // Lo que pasó al fijar una pieza: efectos, texto y sonido.
  void cleared(const nb::Clear& c) {
    if (c.lines == 0) return;
    arena->burst(c, fx_seed);
    static const char* const big[5] = {"", tx::L1, tx::L2, tx::L3, tx::L4};
    static const unsigned col[5] = {0, 0x22d3ee, 0x22c55e, 0xfacc15, 0xff4fd8};
    int n = std::min(4, c.lines);
    arena->banner.big = big[n];
    arena->banner.c = col[n];
    arena->banner.small.clear();
    if (c.combo >= 1) arena->banner.small = nb::fmt(tx::COMBO, {std::to_string(c.combo + 1)});
    if (c.b2b) arena->banner.small = tx::B2B + std::string(arena->banner.small.empty() ? "" : "  ") + arena->banner.small;
    if (c.level_up) arena->banner.small = nb::fmt(tx::LEVEL_UP, {std::to_string(game.level)});
    arena->banner.t0 = arena->now;
    play(c.lines == 4 ? "Glass" : c.level_up ? "Hero" : "Pop");
  }
  void finished() {
    arena->mode = 2;
    held = 0;
    soft = false;
    if (game.score > arena->best) {
      arena->best = game.score;
      arena->new_best = true;
      if (live) nb::write_best(game.score);
    }
    play("Basso");
  }

  void key(int k, bool down) {
    if (!down) {
      if ((k == FL_Left && held < 0) || (k == FL_Right && held > 0)) held = 0;
      if (k == FL_Down) soft = false;
      return;
    }
    if (arena->mode != 1) {
      if (k == FL_Enter || k == FL_KP_Enter || k == ' ') new_game();
      return;
    }
    if (k == FL_Escape || k == 'p') {
      game.paused = !game.paused;
      held = 0;
      soft = false;
      arena->redraw();
      return;
    }
    if (game.paused) return;
    if (k == FL_Left || k == FL_Right) {
      int d = k == FL_Left ? -1 : 1;
      if (held == d) return;   // la repetición del teclado no cuenta: la hace el reloj
      held = d;
      das_t = 0;
      game.shift(d);
    } else if (k == FL_Down) {
      if (!soft) {
        soft = true;
        soft_t = 0;
        game.soft_drop();
      }
    } else if (k == FL_Up || k == 'x') {
      if (game.rotate(1)) play("Tink");
    } else if (k == 'z' || k == FL_Control_L) {
      if (game.rotate(-1)) play("Tink");
    } else if (k == ' ') {
      cleared(game.hard_drop());
    } else if (k == 'c' || k == FL_Shift_L || k == FL_Shift_R) {
      game.do_hold();
    } else if (k == 'r') {
      new_game();
    }
    if (game.over) finished();
    arena->redraw();
  }

  // Cada fotograma: los movimientos sostenidos, la caída y los efectos.
  void frame(double dt) {
    arena->now += dt;
    arena->advance(dt);
    if (arena->mode == 1 && !game.paused && !game.over) {
      if (held) {
        das_t += dt;
        while (das_t > 0.17) {   // tras 0,17 s, una columna cada 0,05 s
          if (!game.shift(held)) break;
          das_t -= 0.05;
        }
      }
      if (soft) {
        soft_t += dt;
        while (soft_t > 0.04) {
          soft_t -= 0.04;
          game.soft_drop();
        }
      }
      cleared(game.step(dt));
      if (game.over) finished();
    }
    arena->redraw();
  }
  void Tick_timer() override {
    double n = nb::now_s();
    frame(last > 0 ? std::min(0.1, n - last) : 0.016);
    last = n;
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_NEW) new_game();
    else if (item == tx::MP_PAUSE) key(FL_Escape, true);
    else if (item == tx::MP_SOUND) sound = !sound;
    else if (item == tx::MP_QUIT) hide();
    else if (item == tx::MP_CONTROLS) fl_message("%s", tx::CONTROLS);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
    if (live) arena->take_focus();
  }

  // ---- capturas y pruebas, sin ventana
  void render_to(const std::string& file) {
    Fl_Image_Surface surf(w(), h(), 0);
    Fl_Surface_Device::push_current(&surf);
    fl_color(color());
    fl_rectf(0, 0, w(), h());
    for (int i = 0; i < children(); i++) {
      Fl_Widget* c = child(i);
      if (c->visible()) surf.draw(c, c->x(), c->y());
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    if (!file.empty()) fl_write_png(file.c_str(), img);
    delete img;
  }
  // Una partida avanzada de ejemplo: el pozo casi lleno y una I sobre el hueco.
  void demo_board() {
    game.reset(15, 4242);
    uint32_t s = 11;
    auto r = [&]() {
      s = s * 1664525u + 1013904223u;
      return (s >> 8) % 1000;
    };
    for (int y = nb::H + nb::HIDDEN - 11; y < nb::H + nb::HIDDEN; y++)
      for (int x = 0; x < nb::W; x++)
        if (x != 6 || y < nb::H + nb::HIDDEN - 4) game.grid[y][x] = y < nb::H + nb::HIDDEN - 9 && r() < 450 ? 0 : 1 + (int)(r() % 7);
    for (int x = 0; x < nb::W; x++) game.grid[nb::H + nb::HIDDEN - 11][x] = 0;
    // La columna 6 vacía de arriba abajo: el pozo para la pieza larga.
    for (int y = 0; y < nb::H + nb::HIDDEN; y++) game.grid[y][6] = 0;
    game.cur.kind = 0;
    game.cur.rot = 1;
    game.cur.x = 4;
    game.cur.y = 5;
    game.hold = 5;
    game.score = 1452890;
    game.lines = 145;
    game.level = 15;
    game.combo = 4;
    arena->best = 1980450;
    arena->mode = 1;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    live = false;
    setup();
    size(1100, 760);
    arena->best = 1980450;
    arena->now = 3;
    render_to(dir + "/title.png");
    demo_board();
    arena->now = 10;
    render_to(dir + "/play.png");
    // ¡Cuatro filas! con combo: el destello, las chispas y el texto.
    cleared(game.hard_drop());
    for (int k = 0; k < 9; k++) frame(0.012);
    render_to(dir + "/quad.png");
    // Fin de la partida con récord.
    for (int y = 3; y < nb::H + nb::HIDDEN; y++)
      for (int x = 0; x < nb::W; x++) game.grid[y][x] = (x * 7 + y * 3) % 5 == 0 ? 0 : 1 + (x + y) % 7;
    game.score = 2104330;
    arena->parts.clear();
    arena->banner = nb::Banner();
    finished();
    render_to(dir + "/over.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    live = false;
    setup();
    size(1100, 760);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    auto press = [&](int k) {
      Fl::e_keysym = k;
      arena->handle(FL_KEYBOARD);
    };
    auto release = [&](int k) {
      Fl::e_keysym = k;
      arena->handle(FL_KEYUP);
    };
    render_to("");
    chk(arena->mode == 0, "pantalla de título");
    press(FL_Enter);
    chk(arena->mode == 1 && !game.over, "empezar con Enter");
    int x = game.cur.x;
    press(FL_Left);
    chk(game.cur.x == x - 1, "izquierda");
    press(FL_Left);   // la repetición del teclado no mueve
    chk(game.cur.x == x - 1, "sin repetición del teclado");
    frame(0.4);   // sostenida: se sigue moviendo sola
    chk(game.cur.x < x - 1, "izquierda sostenida");
    release(FL_Left);
    int x2 = game.cur.x;
    frame(0.4);
    chk(game.cur.x == x2, "al soltar, se para");
    int rot = game.cur.rot;
    press(FL_Up);
    chk(game.cur.kind == 1 || game.cur.rot != rot, "girar");
    int kind = game.cur.kind;
    press('c');
    chk(game.hold == kind, "reservar");
    long long s0 = game.score;
    press(' ');
    chk(game.score > s0, "caída rápida");
    press(FL_Escape);
    chk(game.paused, "pausa");
    int y = game.cur.y;
    frame(2);
    chk(game.cur.y == y, "en pausa no cae");
    press(FL_Escape);
    chk(!game.paused, "seguir");
    // Cuatro filas: efectos y texto grande.
    demo_board();
    game.cur.x = 4;
    cleared(game.hard_drop());
    chk(!arena->parts.empty() && arena->banner.big == tx::L4 && !arena->banner.small.empty(), "efectos de cuatro filas");
    render_to("");
    chk(arena->cell >= 18 && arena->bx > 0, "el pozo dibujado");
    // Perder: fin de partida y récord.
    for (int yy = 0; yy < nb::H + nb::HIDDEN; yy++)
      for (int xx = 0; xx < nb::W; xx++) game.grid[yy][xx] = (xx + yy) % 2 ? 1 : 0;
    game.score = arena->best + 10;
    game.spawn(3);
    chk(game.over, "pozo lleno");
    finished();
    chk(arena->mode == 2 && arena->new_best && arena->best == game.score, "fin con récord");
    render_to("");
    press(FL_Enter);
    chk(arena->mode == 1 && game.score == 0, "otra partida");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
