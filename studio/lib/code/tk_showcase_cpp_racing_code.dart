part of 'tk_examples.dart';

// El código en C++ de la carrera de motos (tk_showcase_cpp_racing.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _racingCode = r'''
// ============================================================ el juego
// Pseudo-3D «a la antigua»: la pista es una lista de segmentos (cada uno con
// su curva y su altura) que se proyectan de cerca a lejos; lo que hay al
// lado (árboles, gradas, carteles) y las motos se dibujan después, de lejos
// a cerca, recortados por las cuestas.
namespace rc {

const double PI = 3.14159265358979323846;
const double SEG = 200;            // largo de un segmento
const double ROAD = 2000;          // medio ancho de la pista
const double CAM_H = 1000;         // altura de la cámara
const double DEPTH = 0.8391;       // 1 / tan(50°): 100° de campo de visión
const double PLAYER_Z = 1800;      // de la cámara a la moto del jugador
const int DRAW = 220;              // segmentos que se dibujan
const double MAXV = SEG * 60;      // velocidad máxima (unidades por segundo)
const double KMH = 318.0 / MAXV;   // de unidades por segundo a km/h
const double ACC = MAXV / 3.0;     // aceleración en parado
const double BRAKE = MAXV / 1.4;   // frenada
const double COAST = MAXV / 7.0;   // sin acelerar ni frenar
const double CENTRIFUGAL = 0.3;    // cuánto empuja la curva hacia fuera
const double CORNER = 3.2;         // la curva que se toma a fondo (rivales)
const double BIKE_H = 1000;        // alto de la moto con el piloto
const double BIKE_HALF = 0.13;     // medio ancho de la moto (en medios anchos de pista)
const int CP_EVERY = 10;           // cronometraje cada 10 segmentos
const double CPLEN = CP_EVERY * SEG;
const int RIDERS = 8;

inline Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void color(unsigned v) { fl_color(rgb(v)); }
inline double clamp(double v, double lo, double hi) { return v < lo ? lo : v > hi ? hi : v; }
inline unsigned mix(unsigned a, unsigned b, double t) {
  t = clamp(t, 0, 1);
  auto ch = [&](int s) {
    int x = (a >> s) & 255, y = (b >> s) & 255;
    return ((unsigned)std::lround(x + (y - x) * t)) & 255u;
  };
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}
inline unsigned dark(unsigned c, double t) { return mix(c, 0x000000, t); }
inline unsigned light(unsigned c, double t) { return mix(c, 0xffffff, t); }
inline double lerp(double a, double b, double t) { return a + (b - a) * t; }
inline double ease_in(double a, double b, double p) { return a + (b - a) * p * p; }
inline double ease_inout(double a, double b, double p) { return a + (b - a) * (-std::cos(p * PI) / 2 + 0.5); }
inline double posmod(double a, double m) { double r = std::fmod(a, m); return r < 0 ? r + m : r; }
inline int iround(double v) { return (int)std::lround(v); }

// Un generador de números pseudoaleatorios propio: la misma carrera con la
// misma semilla (las pruebas y las capturas dependen de ello).
struct Rng {
  uint32_t s;
  explicit Rng(uint32_t v = 1) : s(v ? v : 1) {}
  double next() {
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return (s & 0xffffff) / 16777216.0;
  }
  double range(double a, double b) { return a + (b - a) * next(); }
};

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}

// 83.456 → «1:23.456»; con clock, «01:23.456».
std::string fmt_time(double t, bool clock = false) {
  if (t < 0) t = 0;
  long ms = std::lround(t * 1000);
  char b[32];
  if (clock) std::snprintf(b, sizeof b, "%02ld:%02ld.%03ld", ms / 60000, (ms / 1000) % 60, ms % 1000);
  else std::snprintf(b, sizeof b, "%ld:%02ld.%03ld", ms / 60000, (ms / 1000) % 60, ms % 1000);
  return b;
}

std::string fmt_gap(double t) {
  char b[32];
  std::snprintf(b, sizeof b, "%+.3f", t);
  return b;
}

// ------------------------------------------------------------ la pista
enum PropKind { P_OLIVE, P_PINE, P_CYPRESS, P_BUSH, P_STAND, P_BOARD, P_TYRES, P_MARSHAL };

struct Prop {
  int kind;
  double off;     // posición lateral, en medios anchos de pista (signo: el lado)
  double size;
  uint32_t seed;
};

// Ancho (en unidades) de lo que hay al lado de la pista, para los choques.
inline double prop_width(int k) {
  switch (k) {
    case P_OLIVE: return 900;
    case P_PINE: return 800;
    case P_CYPRESS: return 380;
    case P_BUSH: return 520;
    case P_STAND: return 3400;
    case P_BOARD: return 1900;
    case P_TYRES: return 1300;
    default: return 320;
  }
}

struct Seg {
  double curve = 0, y1 = 0, y2 = 0;  // la curva y la altura al principio y al final
  bool kerb = false, sand = false;
  std::vector<Prop> props;
  // La proyección del cuadro que se está dibujando.
  double x1 = 0, sy1 = 0, w1 = 0, s1 = 0, x2 = 0, sy2 = 0, w2 = 0, s2 = 0, clip = 0;
  bool seen = false;
};

struct Track {
  std::vector<Seg> s;
  double L = 0;
  std::vector<double> mx, my;  // el minimapa, entre 0 y 1
  double map_aspect = 1;

  int n() const { return (int)s.size(); }
  int idx(double z) const { return (int)(posmod(z, L) / SEG) % n(); }
  const Seg& at(double z) const { return s[idx(z)]; }
  double last_y() const { return s.empty() ? 0 : s.back().y2; }
  double height(double z) const {
    const Seg& g = at(z);
    return lerp(g.y1, g.y2, posmod(z, SEG) / SEG);
  }

  void push(double curve, double y) {
    Seg g;
    g.curve = curve;
    g.y1 = last_y();
    g.y2 = y;
    s.push_back(g);
  }

  // Un tramo: entra en la curva, la mantiene y sale; la altura cambia en
  // [hill] segmentos de alto, suavemente.
  void add(int enter, int hold, int leave, double curve, double hill) {
    double y0 = last_y(), y1 = y0 + hill * SEG;
    double total = enter + hold + leave;
    for (int i = 0; i < enter; i++) push(ease_in(0, curve, (double)i / enter), ease_inout(y0, y1, (i + 1) / total));
    for (int i = 0; i < hold; i++) push(curve, ease_inout(y0, y1, (enter + i + 1) / total));
    for (int i = 0; i < leave; i++) push(ease_inout(curve, 0, (double)i / leave), ease_inout(y0, y1, (enter + hold + i + 1) / total));
  }

  void build() {
    s.clear();
    add(0, 100, 0, 0, 0);          // recta de meta
    add(30, 50, 30, 6, 0);         // curva 1: horquilla a la derecha
    add(40, 40, 40, 0, 22);        // subida
    add(40, 60, 40, -4, 0);        // izquierda
    add(50, 120, 50, 2.5, -14);    // curva larga a la derecha, bajando
    add(0, 80, 0, 0, 0);
    add(20, 25, 20, 5, 0);         // chicane
    add(20, 25, 20, -5, 0);
    add(50, 100, 50, 3.5, 30);     // derecha larga, subiendo
    add(60, 140, 60, 0, -38);      // recta de atrás, cuesta abajo
    add(30, 50, 30, 6, 0);         // horquilla
    add(30, 40, 30, -2.5, 0);
    add(40, 70, 40, 4, 10);
    add(40, 50, 40, -3.5, 0);
    add(40, 60, 40, 5, 0);         // última curva
    add(60, 80, 60, 0, -last_y() / SEG);  // vuelta a la altura de la meta
    add(0, 60, 0, 0, 0);
    L = n() * SEG;
    place_props();
    build_map();
  }

  void place_props() {
    Rng r(7);
    const int N = n();
    for (int i = 0; i < N; i++) {
      Seg& g = s[i];
      g.kerb = std::fabs(g.curve) > 0.6;
      g.sand = std::fabs(g.curve) >= 3.9;
      auto put = [&](int kind, double off, double size) { g.props.push_back({kind, off, size, (uint32_t)(r.next() * 1e9)}); };
      bool straight = i < 96 || i > N - 150;
      if (straight) {
        // Gradas a la izquierda y carteles a la derecha.
        if (i % 13 == 5 && i > 3) put(P_STAND, -2.85, 1);
        if (i % 26 == 12) put(P_BOARD, 1.95, 1);
        if (i % 9 == 4) put(P_CYPRESS, r.range(3.4, 5.5), r.range(0.9, 1.2));
        continue;
      }
      if (i % 6 == 0) {
        double side = r.next() < 0.5 ? -1 : 1;
        double k = r.next();
        int kind = k < 0.55 ? P_OLIVE : k < 0.8 ? P_PINE : P_CYPRESS;
        put(kind, side * r.range(2.7, 7.0), r.range(0.8, 1.3));
      }
      if (i % 11 == 3) put(P_BUSH, (r.next() < 0.5 ? -1 : 1) * r.range(2.3, 3.2), r.range(0.7, 1.2));
      if (i % 17 == 9) put(P_OLIVE, (r.next() < 0.5 ? -1 : 1) * r.range(7.5, 11), r.range(1.0, 1.4));
      // Neumáticos por fuera de las curvas cerradas.
      if (g.sand && i % 3 == 0) put(P_TYRES, (g.curve > 0 ? -1 : 1) * 2.35, 1);
      if (i % 64 == 32 && !g.sand) put(P_BOARD, (i / 64) % 2 ? 1.95 : -1.95, 1);
      if (i % 150 == 75) put(P_MARSHAL, (g.curve > 0 ? 1.75 : -1.75), 1);
    }
  }

  // El dibujo del circuito visto desde arriba: el rumbo suma las curvas
  // (escaladas para dar una vuelta entera) y el error de cierre se reparte.
  void build_map() {
    double total = 0;
    for (auto& g : s) total += g.curve;
    double k = total != 0 ? 2 * PI / total : 0;
    double h = 0, x = 0, y = 0;
    std::vector<double> px, py;
    for (auto& g : s) {
      h += g.curve * k;
      x += std::sin(h);
      y -= std::cos(h);
      px.push_back(x);
      py.push_back(y);
    }
    const int N = n();
    for (int i = 0; i < N; i++) {
      px[i] -= x * (i + 1) / N;
      py[i] -= y * (i + 1) / N;
    }
    double x0 = 1e18, x1 = -1e18, y0 = 1e18, y1 = -1e18;
    for (int i = 0; i < N; i++) {
      x0 = std::min(x0, px[i]); x1 = std::max(x1, px[i]);
      y0 = std::min(y0, py[i]); y1 = std::max(y1, py[i]);
    }
    double span = std::max(x1 - x0, y1 - y0);
    map_aspect = (x1 - x0) / std::max(1e-9, y1 - y0);
    mx.assign(N, 0);
    my.assign(N, 0);
    for (int i = 0; i < N; i++) {
      mx[i] = (px[i] - x0) / span;
      my[i] = (py[i] - y0) / span;
    }
  }

  // Lo que dice el error de cierre (pruebas): distancia del último punto al primero.
  double map_gap() const {
    return std::hypot(mx.back() - mx.front(), my.back() - my.front());
  }
};

// ------------------------------------------------------------ los pilotos
struct Rider {
  std::string name, shortname;
  int num = 0;
  unsigned c1 = 0, c2 = 0, c3 = 0;   // moto, mono y casco
  bool human = false;
  double d = 0;        // distancia desde la línea de meta (negativa en la parrilla)
  double x = 0;        // posición lateral: -1 y 1 son los bordes
  double v = 0, lean = 0, steer = 0;
  double skill = 1, bias = 0, react = 0, mistake = 1;
  int lap = 0;         // vueltas completadas
  double lap_start = 0, best = 0, last = 0, finish = -1;
  std::vector<double> cps;   // el tiempo de cada punto de cronometraje
  double crash = 0, slide = 0;
  double wear_f = 1, wear_r = 1;
  double tc = 0;       // control de tracción encendido (luz del cuadro)
  bool finished() const { return finish >= 0; }
};

struct RiderInfo { const char* name; const char* shortname; int num; unsigned c1, c2, c3; double skill; };

const RiderInfo RIVALS[] = {
  {"A. Navarro", "A Nav", 21, 0x1d5fd1, 0x1a2c5a, 0xf2f4f8, 1.000},
  {"K. Tanaka", "K Tan", 7, 0xf2c300, 0x222222, 0xf2c300, 0.990},
  {"L. Moreau", "L Mor", 33, 0xff7a1a, 0x2b2b2b, 0xffffff, 0.982},
  {"J. Becker", "J Bec", 18, 0x1fa35a, 0x10301f, 0xe9f5ec, 0.975},
  {"R. Silva", "R Sil", 5, 0x7b3fd1, 0x2a1748, 0xffd23f, 0.968},
  {"T. Okafor", "T Oka", 27, 0x10a6b8, 0x0b3940, 0xffffff, 0.960},
  {"E. Lindqvist", "E Lin", 64, 0x9aa5b4, 0x23262b, 0xd8262f, 0.952},
};

enum State { LIGHTS, RACE, DONE };

// Un panel semitransparente: una imagen RGBA diminuta estirada (FLTK la
// mezcla con lo de debajo).
struct Glass {
  unsigned char px[4 * 4 * 4];
  Fl_RGB_Image* img = nullptr;
  Glass(unsigned c, int a) {
    for (int i = 0; i < 16; i++) {
      px[i * 4] = (c >> 16) & 255;
      px[i * 4 + 1] = (c >> 8) & 255;
      px[i * 4 + 2] = c & 255;
      px[i * 4 + 3] = (unsigned char)a;
    }
    img = new Fl_RGB_Image(px, 4, 4, 4);
  }
  void draw(int x, int y, int w, int h) {
    if (w <= 0 || h <= 0) return;
    img->scale(w, h, 0, 1);
    img->draw(x, y);
  }
};

// Dibujo de polígonos con giro y escala: la moto se inclina alrededor de la
// rueda (el origen) y los adornos se dibujan en sus propias unidades.
struct Pen {
  double ox, oy, k, c = 1, s = 0;
  Pen(double x, double y, double k_, double angle = 0) : ox(x), oy(y), k(k_), c(std::cos(angle)), s(std::sin(angle)) {}
  double X(double x, double y) const { return ox + k * (x * c - y * s); }
  double Y(double x, double y) const { return oy + k * (x * s + y * c); }
  void v(double x, double y) const { fl_vertex(X(x, y), Y(x, y)); }
  void poly(std::initializer_list<double> p) const {
    fl_begin_complex_polygon();
    for (auto it = p.begin(); it != p.end(); it += 2) v(*it, *(it + 1));
    fl_end_complex_polygon();
  }
  void rect(double x, double y, double w, double h) const { poly({x, y, x + w, y, x + w, y + h, x, y + h}); }
  void ellipse(double cx, double cy, double rx, double ry, int n = 18) const {
    fl_begin_complex_polygon();
    for (int i = 0; i < n; i++) {
      double a = 2 * PI * i / n;
      v(cx + rx * std::cos(a), cy + ry * std::sin(a));
    }
    fl_end_complex_polygon();
  }
};

struct Tag { int x, y; int rider; };

struct Game {
  Track tr;
  std::vector<Rider> rs;
  State st = LIGHTS;
  double t = 0, race_t = 0, lights_out = 4.4, done_t = 0;
  int laps = 3, level = 1;
  bool up = false, down = false, left = false, right = false;
  bool autopilot = false, paused = false;
  bool show_tower = true, show_map = true, show_tags = true;
  double record = 0;           // récord de vuelta (se guarda)
  bool record_changed = false;
  std::string msg;
  double msg_t = 0;
  unsigned msg_c = 0xffffff;
  double shake = 0, bg_far = 0, bg_near = 0, rpm = 0;
  bool offtrack_said = false;
  Rng rng{2024};
  std::vector<Tag> tags;
  std::vector<int> order;      // la clasificación (índices de rs)

  Game() { tr.build(); }

  Rider& me() { return rs[0]; }
  const Rider& me() const { return rs[0]; }

  void say(const std::string& m, double secs, unsigned c = 0xffffff) {
    msg = m;
    msg_t = secs;
    msg_c = c;
  }

  // ---- una carrera nueva: la parrilla, el semáforo y las condiciones
  void reset(uint32_t seed) {
    rng = Rng(seed);
    rs.clear();
    const double base[] = {0.9, 0.95, 0.995};
    Rider me_;
    me_.name = tx::YOU;
    me_.shortname = tx::YOU;
    me_.num = 10;
    me_.c1 = 0xd61f26;
    me_.c2 = 0x1d1d22;
    me_.c3 = 0xd61f26;
    me_.human = true;
    me_.skill = 0.97;
    std::vector<Rider> ai;
    for (const auto& r : RIVALS) {
      Rider x;
      x.name = r.name;
      x.shortname = r.shortname;
      x.num = r.num;
      x.c1 = r.c1;
      x.c2 = r.c2;
      x.c3 = r.c3;
      x.skill = base[level] * r.skill + rng.range(-0.006, 0.006);
      x.bias = rng.range(-0.3, 0.3);
      x.react = rng.range(0.05, 0.35);
      ai.push_back(x);
    }
    // Parrilla: el jugador sale sexto.
    rs.push_back(me_);
    for (auto& x : ai) rs.push_back(x);
    const int grid_me = 5;
    int slot = 0;
    for (int i = 0; i < RIDERS; i++) {
      int pos = i == 0 ? grid_me : (slot == grid_me ? ++slot : slot);
      if (i != 0) slot++;
      Rider& r = rs[i];
      r.d = -SEG * 2 - pos * SEG * 1.7;
      r.x = pos % 2 ? 0.42 : -0.42;
    }
    st = LIGHTS;
    t = 0;
    race_t = 0;
    done_t = 0;
    lights_out = 4.0 + rng.range(0.4, 1.4);
    msg.clear();
    msg_t = 0;
    paused = false;
    offtrack_said = false;
    record_changed = false;
    rank();
  }

  int lights_on() const {
    if (st != LIGHTS) return 0;
    return (int)clamp(std::floor((t - 0.8) / 0.6) + 1, 0, 5);
  }

  // ---- el motor: aceleración según la velocidad, y la marcha
  static double accel(double v) { return ACC * (1 - 0.72 * v / MAXV); }

  static int gear_of(double v) {
    double k = v * KMH;
    const double up_[] = {68, 118, 162, 205, 250};
    int g = 1;
    for (double u : up_) if (k >= u) g++;
    return g;
  }

  static double rpm_of(double v) {
    double k = v * KMH;
    const double lo[] = {0, 68, 118, 162, 205, 250};
    const double hi[] = {68, 118, 162, 205, 250, 330};
    int g = gear_of(v) - 1;
    return clamp(5200 + 11000 * (k - lo[g]) / (hi[g] - lo[g]), 3000, 16200);
  }

  // ---- un paso de la simulación
  void update(double dt) {
    if (paused) return;
    // Pasos pequeños: el resultado no depende de los fotogramas por segundo.
    const double h = 1.0 / 120;
    while (dt > 1e-9) {
      double d = std::min(h, dt);
      step(d);
      dt -= d;
    }
  }

  void step(double dt) {
    t += dt;
    if (msg_t > 0) msg_t -= dt;
    shake = std::max(0.0, shake - dt * 3);
    Rider& p = me();
    if (st == LIGHTS) {
      // Se puede acelerar en parado: sube el cuentarrevoluciones.
      rpm = lerp(rpm, up ? 13500 : 3200, std::min(1.0, dt * (up ? 4 : 2)));
      if (t >= lights_out) {
        st = RACE;
        race_t = 0;
        say(tx::GO, 1.4, 0x7dff8a);
      }
      return;
    }
    race_t += dt;
    if (st == DONE) done_t += dt;
    double before = p.d;
    for (auto& r : rs) {
      if (r.human && !autopilot && !r.finished()) drive_human(r, dt);
      else drive_ai(r, dt);
    }
    collide();
    for (auto& r : rs) advance(r, dt);
    // El fondo se mueve con las curvas.
    double moved = (p.d - before) / SEG;
    double cur = tr.at(p.d + PLAYER_Z).curve;
    bg_far = posmod(bg_far + cur * moved * 0.0009, 1);
    bg_near = posmod(bg_near + cur * moved * 0.0022, 1);
    rpm = rpm_of(p.v);
    rank();
    if (st == RACE && p.finished()) {
      st = DONE;
      done_t = 0;
      say(tx::FINISH, 2.5, 0xffffff);
    }
  }

  void drive_human(Rider& p, double dt) {
    double sp = p.v / MAXV;
    if (p.crash > 0) {
      p.crash -= dt;
      p.v = std::max(0.0, p.v - MAXV * 0.8 * dt);
      p.x += p.slide * dt * (p.v / MAXV) * 2;
      p.lean = lerp(p.lean, p.slide > 0 ? 82 : -82, std::min(1.0, dt * 8));
      if (p.crash <= 0) {
        p.x = clamp(p.x, -0.8, 0.8);
        p.v = 0;
        p.lean = 0;
        p.steer = 0;
      }
      return;
    }
    int want = (right ? 1 : 0) - (left ? 1 : 0);
    p.steer = lerp(p.steer, want, std::min(1.0, dt * 9));
    double dx = dt * 2 * sp;
    const Seg& g = tr.at(p.d + PLAYER_Z * 0 + 1);
    double grip = 1 + (1 - std::min(p.wear_f, p.wear_r)) * 0.35;
    p.x += dx * p.steer;
    p.x -= dx * sp * g.curve * CENTRIFUGAL * grip;
    if (up) p.v += accel(p.v) * dt;
    else if (down) p.v -= BRAKE * dt;
    else p.v -= COAST * dt;
    // Control de tracción: acelerar muy inclinado recorta un poco.
    p.tc = up && std::fabs(p.lean) > 35 ? 0.25 : std::max(0.0, p.tc - dt);
    if (p.tc > 0) p.v -= accel(p.v) * 0.25 * dt;
    // Fuera de la pista.
    double ax = std::fabs(p.x);
    if (ax > 1.0 && ax <= 1.4) {
      if (p.v > MAXV * 0.72) p.v -= MAXV * 0.3 * dt;
    } else if (ax > 1.4) {
      if (p.v > MAXV * 0.28) p.v -= MAXV * 0.95 * dt;
      shake = std::min(1.0, shake + dt * 6 * sp);
      if (!offtrack_said && p.v > MAXV * 0.2) {
        say(tx::OFF_TRACK, 1.2, 0xffd166);
        offtrack_said = true;
      }
    } else {
      offtrack_said = false;
    }
    p.v = clamp(p.v, 0, MAXV);
    p.x = clamp(p.x, -6.5, 6.5);
    hit_props(p);
    // Inclinación: la que pide la curva y la que pide el piloto.
    sp = p.v / MAXV;
    double target = clamp(g.curve * sp * sp * 11 + p.steer * sp * 30, -58, 58);
    p.lean = lerp(p.lean, target, std::min(1.0, dt * 6));
    wear(p, dt, down);
  }

  void wear(Rider& r, double dt, bool braking) {
    double sp = r.v / MAXV, ln = std::fabs(r.lean) / 58;
    r.wear_r = std::max(0.2, r.wear_r - dt * (0.0006 + ln * sp * 0.0016 + (up && r.human ? 0.0004 : 0)));
    r.wear_f = std::max(0.2, r.wear_f - dt * (0.0005 + ln * sp * 0.0012 + (braking ? 0.0012 * sp : 0)));
  }

  // Contra un árbol, una grada o un cartel: rápido, caída; despacio, se para.
  void hit_props(Rider& p) {
    if (std::fabs(p.x) < 1.6) return;
    for (int k = 0; k < 2; k++) {
      const Seg& g = tr.at(p.d + PLAYER_Z * 0 + k * SEG);
      for (const auto& pr : g.props) {
        double half = prop_width(pr.kind) * pr.size / 2 / ROAD;
        double center = pr.off;
        if (pr.kind == P_STAND) center += (pr.off < 0 ? -1 : 1) * half;
        if (std::fabs(p.x - center) < half + BIKE_HALF) {
          if (p.v > MAXV * 0.22) crash(p);
          else {
            p.v = 0;
            p.x += p.x > center ? 0.05 : -0.05;
          }
          return;
        }
      }
    }
  }

  void crash(Rider& p) {
    if (p.crash > 0) return;
    p.crash = 2.2;
    p.slide = p.lean >= 0 ? 1 : -1;
    shake = 1;
    say(tx::CRASH, 2.0, 0xff5a5a);
  }

  void drive_ai(Rider& r, double dt) {
    if (race_t < r.react) return;
    const int N = tr.n();
    double z = posmod(r.d, tr.L);
    int i = tr.idx(z);
    double vmax = MAXV * r.skill;
    if (r.human) vmax = MAXV * r.skill;
    if (r.finished()) vmax *= 0.55;   // la vuelta de enfriamiento
    // Lo que permite lo que viene: v² ≤ vc² + 2·frenada·distancia.
    double target = vmax;
    for (int k = 0; k < 70; k++) {
      double c = std::fabs(tr.s[(i + k) % N].curve);
      if (c < 0.5) continue;
      double vc = MAXV * std::min(1.0, CORNER / c) * r.mistake * (0.97 + r.skill * 0.03);
      double dist = std::max(0.0, k * SEG - posmod(z, SEG));
      target = std::min(target, std::sqrt(vc * vc + 2 * BRAKE * 0.75 * dist));
    }
    // La trazada: por dentro de las curvas, cada uno con su costumbre en recta.
    double ahead = 0;
    for (int k = 4; k < 24; k++) ahead += tr.s[(i + k) % N].curve;
    ahead /= 20;
    double ideal = clamp(ahead * 0.16, -0.62, 0.62) + r.bias * (1 - std::min(1.0, std::fabs(ahead) / 2));
    // Los de delante: adelantar por el lado con sitio o esperar.
    for (auto& o : rs) {
      if (&o == &r || o.crash > 0) continue;
      double gap = o.d - r.d;
      if (gap <= 0 || gap > SEG * 6) continue;
      if (std::fabs(o.x - r.x) > 0.34) continue;
      if (o.v < r.v || gap < SEG * 2) {
        double side = r.x >= o.x ? 1 : -1;
        if (std::fabs(o.x + side * 0.45) > 0.86) side = -side;
        ideal = o.x + side * 0.45;
        if (gap < SEG * 1.3 && std::fabs(o.x - r.x) < 0.24) target = std::min(target, o.v * 0.98);
      }
    }
    if (r.v < target) r.v = std::min(target, r.v + accel(r.v) * (0.9 + 0.1 * r.skill) * dt);
    else r.v = std::max(target, r.v - BRAKE * dt);
    r.v = clamp(r.v, 0, MAXV);
    double was = r.x;
    double rate = 0.9 * dt * (0.4 + r.v / MAXV);
    r.x = clamp(r.x + clamp(ideal - r.x, -rate, rate), -0.9, 0.9);
    double sp = r.v / MAXV;
    double turn = dt > 0 ? (r.x - was) / dt : 0;
    double lt = clamp(tr.s[i].curve * sp * sp * 11 + turn * 18, -56, 56);
    r.lean = lerp(r.lean, lt, std::min(1.0, dt * 5));
    r.steer = 0;
    wear(r, dt, r.v > target);
    // Cada vuelta, un poco distinto (nadie es perfecto).
    if (r.d > 0 && std::fmod(r.d, tr.L) < r.v * dt) r.mistake = rng.range(0.975, 1.01);
  }

  // Choques entre motos: el de detrás frena y se aparta.
  void collide() {
    for (auto& a : rs) {
      if (a.crash > 0) continue;
      for (auto& b : rs) {
        if (&a == &b || b.crash > 0) continue;
        double gap = b.d - a.d;
        if (gap <= 0 || gap > SEG * 0.9) continue;
        if (std::fabs(a.x - b.x) >= BIKE_HALF * 2 || a.v <= b.v) continue;
        a.v = b.v * 0.92;
        a.x += a.x < b.x ? -0.04 : 0.04;
        if (a.human) shake = std::max(shake, 0.5);
      }
    }
  }

  // Avanza y cronometra: puntos de control, vueltas y meta.
  void advance(Rider& r, double dt) {
    double before = r.d;
    r.d += r.v * dt;
    if (r.d <= before || r.d < 0) return;
    double t0 = race_t - dt;
    auto when = [&](double at) { return t0 + dt * (at - before) / (r.d - before); };
    long c0 = before < 0 ? -1 : (long)std::floor(before / CPLEN);
    long c1 = (long)std::floor(r.d / CPLEN);
    for (long c = c0 + 1; c <= c1; c++) r.cps.push_back(when(c * CPLEN));
    long k0 = (long)std::floor(before / tr.L), k1 = (long)std::floor(r.d / tr.L);
    for (long k = k0 + 1; k <= k1; k++) {
      if (k <= 0) continue;   // la salida desde la parrilla no cuenta
      double tc = when(k * tr.L);
      r.last = tc - r.lap_start;
      if (r.best <= 0 || r.last < r.best) r.best = r.last;
      r.lap_start = tc;
      r.lap = (int)k;
      if (r.human && !autopilot && (record <= 0 || r.last < record)) {
        record = r.last;
        record_changed = true;
        say(tx::NEW_RECORD, 2.2, 0xc58cff);
      }
      if (k == laps && !r.finished()) r.finish = tc;
      else if (r.human && k == laps - 1 && !r.finished()) say(tx::FINAL_LAP, 2.0, 0xffffff);
    }
  }

  void rank() {
    order.resize(rs.size());
    for (size_t i = 0; i < rs.size(); i++) order[i] = (int)i;
    std::sort(order.begin(), order.end(), [&](int a, int b) {
      const Rider &x = rs[a], &y = rs[b];
      if (x.finished() != y.finished()) return x.finished();
      if (x.finished()) return x.finish < y.finish;
      return x.d > y.d;
    });
  }

  int position(int i) const {
    for (size_t k = 0; k < order.size(); k++) if (order[k] == i) return (int)k + 1;
    return 0;
  }

  // Tiempo de b detrás de a, con los puntos de cronometraje.
  double gap(int a, int b) const {
    const Rider &x = rs[a], &y = rs[b];
    if (x.finished() && y.finished()) return y.finish - x.finish;
    long k = (long)y.cps.size() - 1;
    if (k < 0 || k >= (long)x.cps.size()) return 0;
    return y.cps[k] - x.cps[k];
  }

  // ---- teclado
  bool key(int k, bool down_) {
    switch (k) {
      case FL_Up: case 'w': up = down_; return true;
      case FL_Down: case 's': down = down_; return true;
      case FL_Left: case 'a': left = down_; return true;
      case FL_Right: case 'd': right = down_; return true;
    }
    return false;
  }
  void release_keys() { up = down = left = right = false; }

  // ================================================================ dibujo
  double U = 1, HOR = 0;

  void project(Seg& g, double camx, double camy, double camz, double xoff1, double xoff2, double z1, int W) {
    double zz1 = z1 - camz, zz2 = z1 + SEG - camz;
    g.s1 = DEPTH / zz1;
    g.s2 = DEPTH / zz2;
    g.x1 = W / 2.0 + g.s1 * (xoff1 - camx) * U;
    g.x2 = W / 2.0 + g.s2 * (xoff2 - camx) * U;
    g.sy1 = HOR - g.s1 * (g.y1 - camy) * U;
    g.sy2 = HOR - g.s2 * (g.y2 - camy) * U;
    g.w1 = g.s1 * ROAD * U;
    g.w2 = g.s2 * ROAD * U;
  }

  static void quad(int ox, int oy, double x1, double y1, double w1, double x2, double y2, double w2) {
    fl_polygon(ox + iround(x1 - w1), oy + iround(y1), ox + iround(x1 + w1), oy + iround(y1),
               ox + iround(x2 + w2), oy + iround(y2), ox + iround(x2 - w2), oy + iround(y2));
  }
  // Una banda de la pista entre dos distancias al centro (a y b, en
  // fracciones del medio ancho), a un lado (side = ±1).
  static void band(int ox, int oy, const Seg& g, double a, double b, int side) {
    double p1 = g.x1 + side * g.w1 * a, q1 = g.x1 + side * g.w1 * b;
    double p2 = g.x2 + side * g.w2 * a, q2 = g.x2 + side * g.w2 * b;
    fl_polygon(ox + iround(p1), oy + iround(g.sy1), ox + iround(q1), oy + iround(g.sy1),
               ox + iround(q2), oy + iround(g.sy2), ox + iround(p2), oy + iround(g.sy2));
  }

  static const unsigned HAZE = 0xc9d9e4;

  void draw_segment(int ox, int oy, int W, const Seg& g, int i, double fog) {
    int y1 = iround(g.sy1), y2 = iround(g.sy2);
    bool alt = (i / 3) % 2;
    auto c = [&](unsigned v) { color(mix(HAZE, v, fog)); };
    c(alt ? 0x6e9c3c : 0x78a744);
    fl_rectf(ox, oy + y2, W, y1 - y2 + 1);
    // Escapatoria pintada y grava por fuera de las curvas cerradas.
    c(alt ? 0x86c6a4 : 0x8fcfad);
    quad(ox, oy, g.x1, g.sy1, g.w1 * 1.42, g.x2, g.sy2, g.w2 * 1.42);
    if (g.sand) {
      c(alt ? 0xd9c48f : 0xe0cc98);
      band(ox, oy, g, 1.42, 2.25, g.curve > 0 ? -1 : 1);
    }
    if (g.kerb) {
      c(((i / 2) % 2) ? 0xd8262f : 0xf4f4f4);
      quad(ox, oy, g.x1, g.sy1, g.w1 * 1.13, g.x2, g.sy2, g.w2 * 1.13);
    }
    c(0xf2f2f2);
    quad(ox, oy, g.x1, g.sy1, g.w1 * 1.01, g.x2, g.sy2, g.w2 * 1.01);
    c(alt ? 0x6d7177 : 0x73777d);
    quad(ox, oy, g.x1, g.sy1, g.w1 * 0.975, g.x2, g.sy2, g.w2 * 0.975);
    // La línea de meta: cuadros blancos y negros a los dos lados del cero.
    const int N = tr.n();
    if (i == 0 || i == N - 1) {
      const int cols = 16;
      for (int k = 0; k < cols; k++) {
        bool white = (k + (i == 0 ? 0 : 1)) % 2;
        c(white ? 0xf6f6f6 : 0x1b1b1b);
        double a = -0.975 + 1.95 * k / cols, b = -0.975 + 1.95 * (k + 1) / cols;
        fl_polygon(ox + iround(g.x1 + g.w1 * a), oy + y1, ox + iround(g.x1 + g.w1 * b), oy + y1,
                   ox + iround(g.x2 + g.w2 * b), oy + y2, ox + iround(g.x2 + g.w2 * a), oy + y2);
      }
    }
    // Las casillas de la parrilla.
    if (i >= N - 18 && i < N - 2 && (N - i) % 2 == 0) {
      int slot = (N - i) / 2 - 1;
      double side = slot % 2 ? 0.42 : -0.42;
      c(0xf2f2f2);
      double a = side - 0.16, b = side + 0.16;
      fl_polygon(ox + iround(g.x1 + g.w1 * a), oy + y1, ox + iround(g.x1 + g.w1 * b), oy + y1,
                 ox + iround(lerp(g.x1, g.x2, 0.12) + lerp(g.w1, g.w2, 0.12) * b), oy + iround(lerp(g.sy1, g.sy2, 0.12)),
                 ox + iround(lerp(g.x1, g.x2, 0.12) + lerp(g.w1, g.w2, 0.12) * a), oy + iround(lerp(g.sy1, g.sy2, 0.12)));
    }
  }

  // ---- el fondo: cielo, montañas lejanas y colinas con olivos
  static double ridge(double x, double a, double b, double c) {
    return 0.5 * std::sin(x * 2 * PI * 3 + a) + 0.3 * std::sin(x * 2 * PI * 7 + b) + 0.2 * std::sin(x * 2 * PI * 13 + c);
  }

  void draw_background(int ox, int oy, int W, int H) {
    int hor = iround(HOR);
    for (int y = 0; y < hor + 4; y += 3) {
      color(mix(0x2f6fbf, 0xd3e6f3, std::pow((double)y / std::max(1, hor), 1.4)));
      fl_rectf(ox, oy + y, W, 3);
    }
    double S = H / 720.0;
    // Montañas lejanas.
    color(0x9cb2c4);
    fl_begin_complex_polygon();
    fl_vertex(ox, oy + hor + 2);
    for (int x = 0; x <= W + 8; x += 8) {
      double u = posmod((double)x / (W * 1.6) + bg_far, 1);
      fl_vertex(ox + x, oy + hor - (46 + 34 * ridge(u, 1.3, 0.4, 2.1)) * S);
    }
    fl_vertex(ox + W, oy + hor + 2);
    fl_end_complex_polygon();
    // Colinas secas con olivos.
    color(0xc8b07a);
    fl_begin_complex_polygon();
    fl_vertex(ox, oy + hor + 2);
    for (int x = 0; x <= W + 6; x += 6) {
      double u = posmod((double)x / (W * 1.2) + bg_near, 1);
      fl_vertex(ox + x, oy + hor - (18 + 16 * ridge(u, 0.2, 2.7, 1.1)) * S);
    }
    fl_vertex(ox + W, oy + hor + 2);
    fl_end_complex_polygon();
    for (int x = 0; x < W; x += iround(std::max(4.0, 11 * S))) {
      double u = posmod((double)x / (W * 1.2) + bg_near, 1);
      double top = hor - (18 + 16 * ridge(u, 0.2, 2.7, 1.1)) * S;
      double n = ridge(u * 3.1, 0.7, 1.9, 0.3);
      if (n < -0.05) continue;
      double yy = lerp(top, hor, 0.15 + 0.6 * std::fabs(ridge(u * 5.3, 1.1, 0.2, 2.2)));
      color(n > 0.4 ? 0x55703a : 0x627d42);
      int r = std::max(2, iround(3.2 * S));
      fl_pie(ox + x - r, oy + iround(yy) - r, 2 * r, iround(1.6 * r), 0, 360);
    }
    color(0x80ab49);
    fl_rectf(ox, oy + hor, W, H - hor);
  }

  // ---- la moto vista desde atrás: rueda en el origen, una unidad de alto
  void draw_bike(double sx, double sy, double px, const Rider& r, bool shadow = true) {
    double k = px * BIKE_H;   // píxeles de una unidad de moto
    if (k < 3) return;
    double lean = r.lean * PI / 180;
    double ln = clamp(r.lean / 58, -1, 1);
    if (shadow) {
      color(0x3a3d40);
      Pen sh(sx + ln * k * 0.18, sy, k);
      sh.ellipse(0, -0.005, 0.33 + std::fabs(ln) * 0.12, 0.045);
    }
    Pen p(sx, sy, k, lean);
    unsigned c1 = r.c1, c2 = r.c2, c3 = r.c3;
    if (k < 16) {   // de lejos basta con la silueta
      color(0x16171a);
      p.rect(-0.08, -0.34, 0.16, 0.34);
      color(c1);
      p.poly({-0.26, -0.55, 0.26, -0.55, 0.2, -0.32, -0.2, -0.32});
      color(c2);
      p.poly({-0.18, -0.92, 0.18, -0.92, 0.2, -0.6, -0.2, -0.6});
      color(c3);
      p.ellipse(0, -0.97, 0.11, 0.1, 10);
      return;
    }
    double hang = ln * 0.09;   // el piloto se descuelga hacia dentro
    // Rueda trasera, basculante y escape.
    color(0x141518);
    p.ellipse(0, -0.17, 0.088, 0.17);
    color(0x2c2e33);
    p.ellipse(0, -0.18, 0.045, 0.14);
    color(0x3b3e44);
    p.rect(-0.14, -0.29, 0.28, 0.05);
    color(0x9aa0a8);
    p.poly({0.09, -0.36, 0.17, -0.36, 0.18, -0.27, 0.1, -0.27});
    color(0x2a2b2e);
    p.ellipse(0.135, -0.315, 0.03, 0.03, 10);
    // Carenado y colín.
    color(dark(c1, 0.35));
    p.poly({-0.28, -0.53, 0.28, -0.53, 0.23, -0.33, -0.23, -0.33});
    color(c1);
    p.poly({-0.25, -0.54, 0.25, -0.54, 0.21, -0.37, -0.21, -0.37});
    color(light(c1, 0.12));
    p.poly({-0.13, -0.6, 0.13, -0.6, 0.11, -0.41, -0.11, -0.41});
    color(0xff3b30);
    p.rect(-0.065, -0.445, 0.13, 0.026);
    // Piernas (la de dentro, más abierta en la curva) y botas.
    double kin = 1 + std::fabs(ln) * 0.55;
    double kl = ln < 0 ? kin : 1, kr = ln > 0 ? kin : 1;
    color(dark(c2, 0.1));
    p.poly({-0.11 + hang, -0.6, -0.3 * kl + hang, -0.53, -0.35 * kl + hang, -0.41, -0.25 * kl + hang, -0.37, -0.13 + hang, -0.47});
    p.poly({0.11 + hang, -0.6, 0.3 * kr + hang, -0.53, 0.35 * kr + hang, -0.41, 0.25 * kr + hang, -0.37, 0.13 + hang, -0.47});
    color(0x1b1c1f);
    p.poly({-0.25 * kl + hang, -0.37, -0.33 * kl + hang, -0.41, -0.3 * kl + hang, -0.31, -0.22 * kl + hang, -0.3});
    p.poly({0.25 * kr + hang, -0.37, 0.33 * kr + hang, -0.41, 0.3 * kr + hang, -0.31, 0.22 * kr + hang, -0.3});
    // Rodilleras (las que rozan el suelo).
    color(0xd9d9d9);
    p.ellipse(-0.33 * kl + hang, -0.44, 0.03, 0.035, 8);
    p.ellipse(0.33 * kr + hang, -0.44, 0.03, 0.035, 8);
    // Cuerpo, joroba y brazos.
    color(c2);
    p.ellipse(hang, -0.63, 0.17, 0.09);
    p.poly({-0.18 + hang, -0.66, 0.18 + hang, -0.66, 0.2 + hang * 1.3, -0.82, 0.12 + hang * 1.5, -0.93,
            -0.12 + hang * 1.5, -0.93, -0.2 + hang * 1.3, -0.82});
    color(light(c2, 0.14));
    p.ellipse(hang * 1.4, -0.86, 0.105, 0.07);
    color(c1);
    p.poly({-0.035 + hang, -0.66, 0.035 + hang, -0.66, 0.03 + hang * 1.4, -0.92, -0.03 + hang * 1.4, -0.92});
    color(dark(c2, 0.25));
    p.poly({-0.2 + hang * 1.3, -0.84, -0.3 + hang, -0.79, -0.28 + hang, -0.7, -0.18 + hang, -0.74});
    p.poly({0.2 + hang * 1.3, -0.84, 0.3 + hang, -0.79, 0.28 + hang, -0.7, 0.18 + hang, -0.74});
    // Casco con su franja.
    color(c3);
    p.ellipse(hang * 1.6, -0.975, 0.105, 0.095);
    color(c1 == c3 ? 0x111111 : c1);
    p.poly({-0.02 + hang * 1.6, -1.07, 0.02 + hang * 1.6, -1.07, 0.03 + hang * 1.6, -0.885, -0.03 + hang * 1.6, -0.885});
    color(0x1a1a1a);
    p.rect(-0.06 + hang * 1.6, -1.08, 0.12, 0.022);
    // El dorsal, en el colín.
    if (k > 70) {
      fl_font(FL_HELVETICA_BOLD_ITALIC, std::max(6, iround(k * 0.085)));
      std::string n = std::to_string(r.num);
      double w = fl_width(n.c_str());
      color(c1 == 0xf2c300 || c1 == 0x9aa5b4 ? 0x111111 : 0xffffff);
      double tx_ = p.X(-w / 2 / k, -0.465), ty_ = p.Y(-w / 2 / k, -0.465);
      fl_draw(-(int)std::lround(r.lean), n.c_str(), iround(tx_), iround(ty_));
    }
  }

  // ---- lo de los lados de la pista (k: píxeles por unidad)
  void draw_prop(const Prop& pr, double sx, double sy, double k, int ox, int oy, double fog) {
    double z = k * pr.size;
    auto c = [&](unsigned v) { color(mix(HAZE, v, fog)); };
    Pen p(ox + sx, oy + sy, z);
    switch (pr.kind) {
      case P_OLIVE:
        if (z * 2600 < 2) return;
        c(0x6b4a2b);
        p.rect(-70, -950, 140, 950);
        c(0x4b6332);
        p.ellipse(-420, -1300, 620, 470, 14);
        c(0x5a7339);
        p.ellipse(0, -1550, 900, 640, 16);
        c(0x667f42);
        p.ellipse(430, -1330, 600, 480, 14);
        c(0x7b9550);
        p.ellipse(-180, -1780, 430, 300, 12);
        break;
      case P_PINE:
        c(0x5d4127);
        p.rect(-60, -800, 120, 800);
        c(0x2f5a35);
        p.poly({-760, -700, 760, -700, 0, -1900});
        c(0x386a3e);
        p.poly({-600, -1300, 600, -1300, 0, -2400});
        c(0x41774a);
        p.poly({-420, -1850, 420, -1850, 0, -2800});
        break;
      case P_CYPRESS:
        c(0x2c4a2c);
        p.ellipse(0, -1650, 360, 1650, 14);
        c(0x36583a);
        p.ellipse(-90, -1800, 200, 1300, 12);
        break;
      case P_BUSH:
        c(0x557233);
        p.ellipse(-180, -260, 300, 240, 12);
        c(0x648540);
        p.ellipse(160, -300, 320, 280, 12);
        break;
      case P_STAND: {
        // Grada: se extiende hacia fuera de la pista.
        double side = pr.off < 0 ? -1 : 1;
        double x0 = side < 0 ? -3400 : 0, w = 3400;
        c(0x7b848f);
        p.rect(x0, -2500, w, 2500);
        c(0xe9edf1);
        p.rect(x0 - 150, -2700, w + 300, 220);
        c(0x5a626b);
        p.rect(x0 + 80, -2480, w - 160, 160);
        Rng rr(pr.seed);
        const unsigned crowd[] = {0xd8262f, 0xf4f4f4, 0x1d5fd1, 0xf2c300, 0x2b2b2b, 0x1fa35a, 0xff7a1a};
        for (int row = 0; row < 6; row++) {
          double y = -2250 + row * 360;
          c(row % 2 ? 0x98a2ad : 0xa7b0ba);
          p.rect(x0 + 60, y, w - 120, 300);
          if (z * 120 < 1.5) continue;
          for (double xx = x0 + 120; xx < x0 + w - 140; xx += 150) {
            if (rr.next() < 0.2) continue;
            c(crowd[(int)(rr.next() * 7)]);
            p.rect(xx, y + 40, 110, 140);
          }
        }
        break;
      }
      case P_BOARD: {
        c(0x6b6f75);
        p.rect(-800, -1000, 70, 1000);
        p.rect(730, -1000, 70, 1000);
        c(0xffffff);
        p.rect(-950, -1050, 1900, 620);
        c(0x1c5fc6);
        p.rect(-950, -1050, 520, 620);
        c(0xf2f2f2);
        p.poly({-860, -560, -560, -560, -600, -740, -690, -920, -800, -740});
        double th = z * 300;
        if (th >= 6) {
          const char* t = (pr.seed % 2) ? "DMarlon Studio" : "C++ \xc2\xb7 FLTK";
          fl_font(FL_HELVETICA_BOLD, iround(th));
          double tw = fl_width(t);
          if (tw > z * 1300) {
            th *= z * 1300 / tw;
            if (th < 5) break;
            fl_font(FL_HELVETICA_BOLD, iround(th));
            tw = fl_width(t);
          }
          c(0x13294b);
          fl_draw(t, iround(p.X(240, -740) - tw / 2), iround(p.Y(0, -740) + th * 0.36));
        }
        break;
      }
      case P_TYRES: {
        for (int i = 0; i < 4; i++) {
          c(i % 2 ? 0xf4f4f4 : 0xd8262f);
          p.rect(-650 + i * 325, -380, 325, 380);
        }
        c(0x202124);
        p.rect(-650, -60, 1300, 60);
        break;
      }
      case P_MARSHAL:
        c(0xf4f4f4);
        p.rect(-170, -700, 340, 700);
        c(0xf08a24);
        p.rect(-170, -700, 340, 200);
        c(0x2b2b2b);
        p.rect(-120, -440, 240, 160);
        break;
    }
  }

  // El pórtico de salida, con el semáforo, sobre la línea de meta.
  void draw_gantry(const Seg& g, int ox, int oy, double fog) {
    double k = g.s1 * U;
    if (k * 3000 < 4) return;
    auto c = [&](unsigned v) { color(mix(HAZE, v, fog)); };
    Pen p(ox + g.x1, oy + g.sy1, k);
    double half = ROAD * 1.35;
    c(0x3a3f47);
    p.rect(-half - 160, -3300, 160, 3300);
    p.rect(half, -3300, 160, 3300);
    c(0x1d2430);
    p.rect(-half - 160, -3500, 2 * half + 320, 650);
    c(0x1c5fc6);
    p.rect(-half - 160, -3520, 2 * half + 320, 70);
    double th = k * 330;
    if (th >= 6) {
      fl_font(FL_HELVETICA_BOLD_ITALIC, iround(th));
      c(0xffffff);
      const char* t = "DMarlon Studio";
      fl_draw(t, iround(p.X(-half + 300, 0)), iround(p.Y(0, -3060)));
    }
    // Cinco luces: rojas mientras se encienden; se apagan a la salida.
    int on = lights_on();
    for (int i = 0; i < 5; i++) {
      double x = half - 2100 + i * 380;
      c(0x0d0f12);
      p.ellipse(x, -3170, 160, 160, 12);
      c(i < on ? 0xff2a2a : 0x3a1010);
      p.ellipse(x, -3170, 120, 120, 12);
    }
  }

  // ---- un cuadro entero
  void render(int ox, int oy, int W, int H) {
    fl_push_clip(ox, oy, W, H);
    tags.clear();
    U = std::min(W / 2.0, H * 0.95);
    HOR = H * 0.42;
    const Rider& p = me();
    double shx = 0, shy = 0;
    if (shake > 0) {
      shx = std::sin(t * 61) * shake * 5 * H / 720;
      shy = std::cos(t * 47) * shake * 4 * H / 720;
    }
    double pz = posmod(p.d, tr.L);
    double camz_abs = p.d - PLAYER_Z;
    double camz = posmod(camz_abs, tr.L);
    const int N = tr.n();
    int base = tr.idx(camz);
    double bp = posmod(camz, SEG) / SEG;
    double py = tr.height(pz);
    double camy = py + CAM_H;
    double camx = p.x * ROAD;
    draw_background(ox, oy, W, H);
    int sox = ox + iround(shx), soy = oy + iround(shy);
    double x = 0, dx = -tr.s[base].curve * bp;
    double maxy = H;
    for (int n = 0; n < DRAW; n++) {
      int i = (base + n) % N;
      Seg& g = tr.s[i];
      double z1 = i * SEG + (i < base ? tr.L : 0);
      g.seen = false;
      g.clip = maxy;
      project(g, camx, camy, camz, x, x + dx, z1, W);
      x += dx;
      dx += g.curve;
      if (z1 - camz <= 1 || g.sy2 >= g.sy1 || g.sy2 >= maxy) continue;
      double fog = std::exp(-std::pow((double)n / DRAW, 2) * 3.2);
      draw_segment(sox, soy, W, g, i, fog);
      g.seen = true;
      maxy = g.sy2;
    }
    // De lejos a cerca: lo de los lados, las motos y la del jugador.
    std::vector<std::pair<double, int>> riders;
    for (size_t r = 1; r < rs.size(); r++) {
      double rel = posmod(rs[r].d - camz_abs, tr.L);
      // Las que van detrás del jugador no se ven (taparían la pantalla);
      // las que van a su lado, sí.
      if (rel > PLAYER_Z - 260 && rel < DRAW * SEG) riders.push_back({rel, (int)r});
    }
    std::sort(riders.begin(), riders.end(), [](auto& a, auto& b) { return a.first > b.first; });
    size_t next = 0;
    bool me_drawn = false;
    double my_y = HOR + DEPTH / PLAYER_Z * CAM_H * U;
    for (int n = DRAW - 1; n >= 1; n--) {
      int i = (base + n) % N;
      const Seg& g = tr.s[i];
      double segz = n * SEG - bp * SEG;   // distancia de la cámara al principio del segmento
      double fog = std::exp(-std::pow((double)n / DRAW, 2) * 3.2);
      if (g.s1 > 0 && g.clip > 0) {
        fl_push_clip(ox, oy, W, std::max(0, iround(g.clip)));
        if (i == 0) draw_gantry(g, sox, soy, fog);
        for (const auto& pr : g.props) {
          double k = g.s1 * U;
          if (k * 3000 * pr.size < 1.5) continue;
          draw_prop(pr, g.x1 + g.w1 * pr.off, g.sy1, k, sox, soy, fog);
        }
        // Las motos de este segmento, de la más lejana a la más cercana.
        while (next < riders.size() && riders[next].first >= segz) {
          const Rider& r = rs[riders[next].second];
          double pct = clamp((riders[next].first - segz) / SEG, 0, 1);
          double sc = lerp(g.s1, g.s2, pct);
          double sx = lerp(g.x1, g.x2, pct) + sc * r.x * ROAD * U;
          double sy = lerp(g.sy1, g.sy2, pct);
          if (!me_drawn && riders[next].first < PLAYER_Z) { draw_me(sox, soy, W, my_y); me_drawn = true; }
          draw_bike(sox + sx, soy + sy, sc * U, r);
          if (show_tags && riders[next].first < SEG * 70 && riders[next].first > PLAYER_Z * 1.2)
            tags.push_back({iround(sox + sx), iround(soy + sy - sc * U * BIKE_H * 1.12), riders[next].second});
          next++;
        }
        fl_pop_clip();
      }
      if (!me_drawn && segz <= PLAYER_Z) { draw_me(sox, soy, W, my_y); me_drawn = true; }
    }
    if (!me_drawn) draw_me(sox, soy, W, my_y);
    draw_hud(ox, oy, W, H);
    fl_pop_clip();
  }

  void draw_me(int sox, int soy, int W, double y) {
    const Rider& p = me();
    double px = DEPTH / PLAYER_Z * U;
    double bounce = p.v > 0 ? std::sin(t * 37) * 0.6 * (p.v / MAXV) : 0;
    draw_bike(sox + W / 2.0, soy + y + bounce, px, p);
  }

  // ================================================================ HUD
  void text(const std::string& s, double x, double y, int font, double size, unsigned c, int align = -1, bool outline = false) {
    fl_font(font, std::max(6, iround(size)));
    double w = fl_width(s.c_str());
    double xx = align < 0 ? x : align == 0 ? x - w / 2 : x - w;
    if (outline) {
      color(0x0b0d10);
      for (int a = -2; a <= 2; a += 2)
        for (int b = -2; b <= 2; b += 2) fl_draw(s.c_str(), iround(xx) + a, iround(y) + b);
    }
    color(c);
    fl_draw(s.c_str(), iround(xx), iround(y));
  }

  static Glass& glass(int which) {
    static Glass g0(0x0d1117, 185), g1(0x0d1117, 215), g2(0xffffff, 235);
    return which == 0 ? g0 : which == 1 ? g1 : g2;
  }

  void draw_hud(int ox, int oy, int W, int H) {
    double S = std::min(W / 1280.0, H / 720.0);
    S = std::max(S, 0.62);
    const Rider& p = me();
    const int BI = FL_HELVETICA_BOLD_ITALIC, B = FL_HELVETICA_BOLD;
    // ---- nombres sobre los rivales: del más cercano al más lejano, sin
    // montarse unos sobre otros
    std::vector<std::array<int, 4>> placed;
    for (auto it = tags.rbegin(); it != tags.rend(); ++it) {
      const Tag& tg = *it;
      const Rider& r = rs[tg.rider];
      std::string pos = std::to_string(position(tg.rider));
      fl_font(B, iround(12 * S));
      double wn = fl_width(r.name.c_str()), wp = 20 * S, wnum = 26 * S;
      double w = wp + wn + 10 * S + wnum, h = 20 * S;
      int x0 = iround(tg.x - w / 2), y0 = iround(tg.y - h);
      bool overlap = false;
      for (auto& q : placed)
        if (x0 < q[0] + q[2] + 4 && q[0] < x0 + w + 4 && y0 < q[1] + q[3] + 2 && q[1] < y0 + h + 2) overlap = true;
      if (overlap) continue;
      placed.push_back({x0, y0, iround(w), iround(h)});
      glass(1).draw(x0, y0, iround(w), iround(h));
      text(pos, x0 + wp / 2, y0 + h * 0.72, B, 12 * S, 0xffffff, 0);
      text(r.name, x0 + wp + 2 * S, y0 + h * 0.72, B, 12 * S, 0xffffff);
      color(r.c1);
      fl_rectf(iround(x0 + w - wnum), y0, iround(wnum), iround(h));
      text(std::to_string(r.num), x0 + w - wnum / 2, y0 + h * 0.72, BI, 12 * S, r.c1 == 0xf2c300 || r.c1 == 0x9aa5b4 ? 0x111111 : 0xffffff, 0);
    }
    // ---- vuelta y clasificación (arriba a la izquierda)
    double x = ox + 18 * S, y = oy + 18 * S;
    int lapn = std::min(laps, p.lap + 1);
    if (st == LIGHTS) lapn = 1;
    text(std::to_string(lapn), x, y + 30 * S, BI, 34 * S, 0xffffff, -1, true);
    fl_font(BI, iround(34 * S));
    double lw = fl_width(std::to_string(lapn).c_str());
    text("/" + std::to_string(laps) + "  " + tx::LAP, x + lw - 1 * S, y + 30 * S, BI, 17 * S, 0xffffff, -1, true);
    y += 42 * S;
    if (show_tower) {
      double rw = 168 * S, rh = 23 * S;
      int mine = position(0);
      for (size_t k = 0; k < order.size(); k++) {
        int i = order[k];
        const Rider& r = rs[i];
        bool me_ = i == 0;
        // Diferencias con el de delante y el de detrás, como en la tele.
        if (me_ && k > 0 && st != LIGHTS) {
          glass(1).draw(iround(x), iround(y), iround(rw), iround(17 * S));
          text(tx::GAP, x + 8 * S, y + 13 * S, B, 11 * S, 0xc9d1dc);
          text(fmt_gap(gap(order[k - 1], 0)), x + rw - 8 * S, y + 13 * S, B, 11 * S, 0xffd166, 1);
          y += 17 * S;
        }
        glass(me_ ? 2 : 0).draw(iround(x), iround(y), iround(rw), iround(rh));
        unsigned fg = me_ ? 0x111111 : 0xffffff;
        text(std::to_string(k + 1), x + 13 * S, y + rh * 0.72, B, 13 * S, fg, 0);
        color(me_ ? r.c1 : 0xffffff);
        fl_rectf(iround(x + 26 * S), iround(y + 3 * S), std::max(1, iround(2 * S)), iround(rh - 6 * S));
        text(r.shortname, x + 34 * S, y + rh * 0.72, B, 13 * S, fg);
        color(r.c1);
        fl_rectf(iround(x + rw - 36 * S), iround(y), iround(36 * S), iround(rh));
        text(std::to_string(r.num), x + rw - 18 * S, y + rh * 0.74, BI, 14 * S, r.c1 == 0xf2c300 || r.c1 == 0x9aa5b4 ? 0x111111 : 0xffffff, 0);
        if (r.finished() && st != LIGHTS) {
          color(0xffffff);
          for (int q = 0; q < 3; q++)
            for (int w = 0; w < 2; w++)
              if ((q + w) % 2 == 0) fl_rectf(iround(x + rw - 52 * S + q * 4 * S), iround(y + 6 * S + w * 4 * S), iround(4 * S), iround(4 * S));
        }
        y += rh + 1;
        if (me_ && k + 1 < order.size() && st != LIGHTS) {
          glass(1).draw(iround(x), iround(y), iround(rw), iround(17 * S));
          text(tx::GAP, x + 8 * S, y + 13 * S, B, 11 * S, 0xc9d1dc);
          text(fmt_gap(-gap(0, order[k + 1])), x + rw - 8 * S, y + 13 * S, B, 11 * S, 0x7dff8a, 1);
          y += 18 * S;
        }
      }
      (void)mine;
    }
    // ---- tiempos (arriba a la derecha)
    double rx = ox + W - 18 * S;
    text(fmt_time(st == LIGHTS ? 0 : (p.finished() ? p.finish : race_t), true), rx, oy + 46 * S, BI, 30 * S, 0xffffff, 1, true);
    double ty = oy + 70 * S;
    auto line = [&](const char* label, double v, unsigned c) {
      if (v <= 0) return;
      glass(0).draw(iround(rx - 210 * S), iround(ty - 15 * S), iround(210 * S), iround(21 * S));
      text(label, rx - 202 * S, ty, B, 12 * S, 0xc9d1dc);
      text(fmt_time(v), rx - 8 * S, ty, B, 13 * S, c, 1);
      ty += 23 * S;
    };
    line(tx::LAST, p.last, 0xffffff);
    line(tx::BEST, p.best, 0x7dff8a);
    line(tx::RECORD, record, 0xc58cff);
    // ---- minimapa (abajo a la izquierda)
    if (show_map) {
      double mw = 200 * S, mh = 150 * S, mx0 = ox + 18 * S, my0 = oy + H - mh - 40 * S;
      double sc = std::min(mw, mh / std::max(0.3, 1 / tr.map_aspect));
      auto MX = [&](int i) { return mx0 + tr.mx[i] * sc; };
      auto MY = [&](int i) { return my0 + tr.my[i] * sc; };
      const int N = tr.n();
      for (int pass = 0; pass < 2; pass++) {
        color(pass == 0 ? 0x0b0d10 : 0xffffff);
        fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, std::max(1, iround((pass == 0 ? 7 : 3.5) * S)));
        fl_begin_line();
        for (int i = 0; i < N; i += 4) fl_vertex(MX(i), MY(i));
        fl_vertex(MX(0), MY(0));
        fl_end_line();
      }
      fl_line_style(0);
      color(0xd8262f);
      fl_rectf(iround(MX(0) - 3 * S), iround(MY(0) - 3 * S), iround(6 * S), iround(6 * S));
      for (int k = (int)order.size() - 1; k >= 0; k--) {
        int i = order[k];
        int si = tr.idx(rs[i].d);
        double r = (i == 0 ? 6.5 : 4.5) * S;
        color(i == 0 ? 0xffffff : 0x0b0d10);
        fl_pie(iround(MX(si) - r - S), iround(MY(si) - r - S), iround(2 * r + 2 * S), iround(2 * r + 2 * S), 0, 360);
        color(i == 0 ? 0xd61f26 : rs[i].c1);
        fl_pie(iround(MX(si) - r), iround(MY(si) - r), iround(2 * r), iround(2 * r), 0, 360);
      }
      text(tx::CIRCUIT, mx0, oy + H - 16 * S, B, 13 * S, 0xffffff, -1, true);
    }
    draw_dash(ox, oy, W, H, S);
    // ---- semáforo y mensajes
    if (st == LIGHTS) {
      int on = lights_on();
      double lw2 = 5 * 52 * S + 24 * S, lh = 70 * S;
      double lx = ox + W / 2.0 - lw2 / 2, ly = oy + 80 * S;
      glass(1).draw(iround(lx), iround(ly), iround(lw2), iround(lh));
      for (int i = 0; i < 5; i++) {
        double cx = lx + 12 * S + 26 * S + i * 52 * S, cy = ly + lh / 2, r = 19 * S;
        color(0x050607);
        fl_pie(iround(cx - r - 2 * S), iround(cy - r - 2 * S), iround(2 * r + 4 * S), iround(2 * r + 4 * S), 0, 360);
        color(i < on ? 0xff2a2a : 0x3b1414);
        fl_pie(iround(cx - r), iround(cy - r), iround(2 * r), iround(2 * r), 0, 360);
        if (i < on) {
          color(0xff9a9a);
          fl_pie(iround(cx - r * 0.45), iround(cy - r * 0.6), iround(r * 0.5), iround(r * 0.4), 0, 360);
        }
      }
      text(tx::GET_READY, ox + W / 2.0, ly + lh + 30 * S, B, 16 * S, 0xffffff, 0, true);
    }
    if (msg_t > 0 && !msg.empty()) {
      double a = clamp(msg_t * 3, 0, 1);
      text(msg, ox + W / 2.0, oy + H * 0.3, BI, 46 * S * (0.85 + 0.15 * a), msg_c, 0, true);
    }
    if (st == DONE && done_t > 2.0) draw_results(ox, oy, W, H, S);
    if (paused) {
      double pw = 360 * S, ph = 120 * S;
      double px0 = ox + (W - pw) / 2, py0 = oy + (H - ph) / 2;
      glass(1).draw(iround(px0), iround(py0), iround(pw), iround(ph));
      text(tx::PAUSED, ox + W / 2.0, py0 + 58 * S, BI, 40 * S, 0xffffff, 0);
      text(tx::RESUME, ox + W / 2.0, py0 + 92 * S, B, 14 * S, 0xc9d1dc, 0);
    }
  }

  // El cuadro de mandos: marcha, velocidad, revoluciones y neumáticos.
  void draw_dash(int ox, int oy, int W, int H, double S) {
    const Rider& p = me();
    const int BI = FL_HELVETICA_BOLD_ITALIC, B = FL_HELVETICA_BOLD;
    double dw = 300 * S, dh = 132 * S;
    double x = ox + W - dw - 18 * S, y = oy + H - dh - 18 * S;
    glass(1).draw(iround(x), iround(y), iround(dw), iround(dh));
    color(0x3a4452);
    fl_rect(iround(x), iround(y), iround(dw), iround(dh));
    // Revoluciones: barra de segmentos verde, amarillo y rojo.
    const int segs = 24;
    double bx = x + 12 * S, by = y + 10 * S, bw = dw - 24 * S, bh = 12 * S;
    double frac = clamp((rpm - 3000) / 13200, 0, 1);
    for (int i = 0; i < segs; i++) {
      double sx = bx + i * bw / segs;
      bool on = (i + 0.5) / segs <= frac;
      unsigned c = i < 15 ? 0x39d353 : i < 20 ? 0xffd23f : 0xff3b30;
      color(on ? c : dark(c, 0.78));
      fl_rectf(iround(sx), iround(by), std::max(1, iround(bw / segs - 2 * S)), iround(bh));
    }
    int gear = st == LIGHTS ? 1 : gear_of(p.v);
    if (p.v < 1 && st != LIGHTS) gear = 1;
    text(std::to_string(gear), x + 40 * S, y + 86 * S, BI, 58 * S, 0xffffff, 0);
    text(std::to_string(iround(p.v * KMH)), x + 120 * S, y + 74 * S, BI, 34 * S, 0xffffff, 0);
    text("km/h", x + 120 * S, y + 94 * S, B, 12 * S, 0xc9d1dc, 0);
    // Luces: control de tracción y antiwheelie.
    auto lamp = [&](const char* name, double lx, bool on) {
      color(on ? 0xffd23f : 0x2a313b);
      fl_rectf(iround(lx), iround(y + 104 * S), iround(36 * S), iround(17 * S));
      text(name, lx + 18 * S, y + 117 * S, B, 11 * S, on ? 0x111111 : 0x8b95a3, 0);
    };
    lamp("TC", x + 12 * S, p.tc > 0 && std::fmod(t, 0.2) < 0.12);
    lamp("AW", x + 52 * S, up && gear <= 2 && p.v > 1 && st == RACE);
    // Neumáticos delantero y trasero.
    auto tyre = [&](const char* name, double cx, double w) {
      text(name, cx, y + 40 * S, B, 11 * S, 0xc9d1dc, 0);
      double tw = 20 * S, th = 58 * S, tx0 = cx - tw / 2, ty0 = y + 46 * S;
      color(0x0b0d10);
      fl_rectf(iround(tx0 - 2 * S), iround(ty0 - 2 * S), iround(tw + 4 * S), iround(th + 4 * S));
      unsigned c = w > 0.7 ? 0x9be15d : w > 0.45 ? 0xffd23f : 0xff3b30;
      color(dark(c, 0.7));
      fl_rectf(iround(tx0), iround(ty0), iround(tw), iround(th));
      color(c);
      double fh = th * w;
      fl_rectf(iround(tx0), iround(ty0 + th - fh), iround(tw), iround(fh));
      text(std::to_string(iround(w * 100)) + "%", cx, y + 122 * S, B, 11 * S, 0xffffff, 0);
    };
    tyre(tx::FRONT, x + dw - 92 * S, p.wear_f);
    tyre(tx::REAR, x + dw - 38 * S, p.wear_r);
  }

  void draw_results(int ox, int oy, int W, int H, double S) {
    const int BI = FL_HELVETICA_BOLD_ITALIC, B = FL_HELVETICA_BOLD;
    double rw = 620 * S, row = 30 * S, rh = 120 * S + row * order.size() + 60 * S;
    double x = ox + (W - rw) / 2, y = oy + std::max(10.0, (H - rh) / 2);
    glass(1).draw(iround(x), iround(y), iround(rw), iround(rh));
    color(0xd8262f);
    fl_rectf(iround(x), iround(y), iround(rw), iround(5 * S));
    text(tx::RESULTS, x + 24 * S, y + 44 * S, BI, 26 * S, 0xffffff);
    double cy = y + 76 * S;
    double cPos = x + 24 * S, cName = x + 74 * S, cTime = x + rw - 200 * S, cBest = x + rw - 24 * S;
    text(tx::COL_POS, cPos, cy, B, 12 * S, 0x8b95a3);
    text(tx::COL_RIDER, cName, cy, B, 12 * S, 0x8b95a3);
    text(tx::COL_TIME, cTime, cy, B, 12 * S, 0x8b95a3, 1);
    text(tx::COL_BEST, cBest, cy, B, 12 * S, 0x8b95a3, 1);
    cy += 10 * S;
    int first = order.empty() ? 0 : order[0];
    for (size_t k = 0; k < order.size(); k++) {
      int i = order[k];
      const Rider& r = rs[i];
      if (i == 0) glass(2).draw(iround(x + 12 * S), iround(cy), iround(rw - 24 * S), iround(row - 2 * S));
      unsigned fg = i == 0 ? 0x111111 : 0xffffff;
      double base = cy + row * 0.7;
      text(std::to_string(k + 1), cPos + 8 * S, base, BI, 16 * S, fg, 0);
      color(r.c1);
      fl_rectf(iround(cName), iround(cy + 4 * S), iround(34 * S), iround(row - 10 * S));
      text(std::to_string(r.num), cName + 17 * S, base - 1 * S, BI, 13 * S, r.c1 == 0xf2c300 || r.c1 == 0x9aa5b4 ? 0x111111 : 0xffffff, 0);
      text(r.name, cName + 44 * S, base, B, 15 * S, fg);
      std::string tm = !r.finished() ? std::string(tx::RUNNING) : k == 0 ? fmt_time(r.finish) : "+" + fmt_time(r.finish - rs[first].finish).substr(0);
      if (r.finished() && k > 0) {
        double g_ = r.finish - rs[first].finish;
        tm = g_ < 60 ? fmt_gap(g_) : "+" + fmt_time(g_);
      }
      text(tm, cTime, base, B, 14 * S, fg, 1);
      text(r.best > 0 ? fmt_time(r.best) : "-", cBest, base, B, 14 * S, i == 0 ? 0x111111 : 0xc9d1dc, 1);
      cy += row;
    }
    int pos = position(0);
    std::string verdict = pos == 1 ? std::string(tx::WON) : fmt(tx::FINAL_POS, {std::to_string(pos), std::to_string(order.size())});
    text(verdict, x + rw / 2, cy + 32 * S, BI, 20 * S, pos == 1 ? 0xffd23f : 0xffffff, 0);
    text(tx::AGAIN, x + rw / 2, cy + 54 * S, B, 13 * S, 0xc9d1dc, 0);
  }
};

// ------------------------------------------------------------ ajustes
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_RACING_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio\\Racing";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio/Racing";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/dmarlon-studio-racing";
#endif
}

void make_dirs(const std::string& path) {
  for (size_t i = 1; i <= path.size(); i++) {
    if (i == path.size() || path[i] == '/' || path[i] == '\\') fl_mkdir(path.substr(0, i).c_str(), 0755);
  }
}

// ------------------------------------------------------------ pruebas
// Sin ventana: DMS_RACING_SELFTEST=1. La pista, una carrera entera con todos
// pilotando solos, la física del jugador y las diferencias.
int selftest() {
  int fails = 0;
  auto check = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); fails++; }
  };
  Game g;
  const Track& tr = g.tr;
  check(tr.n() > 1500, "la pista tiene más de 1500 segmentos");
  check(std::fabs(tr.s.back().y2) < 1e-6, "la pista vuelve a la altura de la meta");
  check(tr.map_gap() < 0.02, "el minimapa cierra");
  int props = 0;
  for (auto& s : tr.s) props += (int)s.props.size();
  check(props > 300, "hay árboles, gradas y carteles");
  // ---- una carrera entera, todos solos
  g.laps = 3;
  g.level = 1;
  g.reset(99);
  g.autopilot = true;
  double t = 0;
  while (t < 900 && !(g.st == DONE && std::all_of(g.rs.begin(), g.rs.end(), [](const Rider& r) { return r.finished(); }))) {
    g.update(1.0 / 60);
    t += 1.0 / 60;
  }
  bool all = true;
  for (auto& r : g.rs) all = all && r.finished() && r.lap >= g.laps;
  check(all, "todos terminan las tres vueltas");
  for (auto& r : g.rs) {
    check(r.best > 25 && r.best < 120, "las vueltas duran lo razonable");
    check(std::isfinite(r.d) && std::isfinite(r.x), "sin NaN");
    check(r.cps.size() >= (size_t)(g.laps * tr.L / CPLEN), "cada punto de cronometraje tiene su tiempo");
  }
  for (size_t k = 1; k < g.order.size(); k++)
    check(g.rs[g.order[k]].finish >= g.rs[g.order[k - 1]].finish, "la clasificación va por tiempo");
  check(g.gap(g.order[0], g.order[1]) >= 0, "la diferencia con el de delante es positiva");
  const Rider& win = g.rs[g.order[0]];
  double win_time = win.finish, win_best = win.best;
  // ---- el jugador: acelerar, frenar, salirse y caerse
  Game h;
  h.reset(5);
  h.st = RACE;
  Rider& p = h.me();
  p.d = 0;
  p.x = 0;
  p.v = 0;
  h.up = true;
  for (int i = 0; i < 6 * 120; i++) {
    p.x = 0;
    h.drive_human(p, 1.0 / 120);
  }
  check(p.v > MAXV * 0.85, "a fondo en recta pasa de 270 km/h");
  double top = p.v * KMH;
  h.up = false;
  h.down = true;
  for (int i = 0; i < (int)(2.5 * 120); i++) h.drive_human(p, 1.0 / 120);
  check(p.v < MAXV * 0.15, "frena");
  h.down = false;
  // Fuera de la pista se pierde velocidad.
  p.v = MAXV;
  p.x = 1.7;
  for (int i = 0; i < 120; i++) {
    p.x = 1.7;
    p.d = 50 * SEG;
    h.drive_human(p, 1.0 / 120);
  }
  check(p.v < MAXV * 0.45, "la hierba frena");
  // A fondo en la horquilla, sin girar, se sale por fuera.
  int hairpin = 0;
  for (int i = 0; i < tr.n(); i++) if (tr.s[i].curve >= 6) { hairpin = i; break; }
  p.d = hairpin * SEG;
  p.x = 0;
  p.v = MAXV;
  p.crash = 0;
  h.up = true;
  for (int i = 0; i < 90; i++) h.drive_human(p, 1.0 / 120);
  check(p.x < -0.7, "demasiado rápido en curva se abre");
  // Contra un árbol a 200 km/h: caída; luego, de vuelta a la pista.
  int tree = -1;
  double toff = 0;
  for (int i = 200; i < tr.n() && tree < 0; i++)
    for (auto& pr : tr.s[i].props)
      if (pr.kind == P_OLIVE && std::fabs(pr.off) < 4) { tree = i; toff = pr.off; break; }
  check(tree >= 0, "hay un olivo cerca de la pista");
  if (tree >= 0) {
    p.crash = 0;
    p.d = tree * SEG - 10;
    p.x = toff;
    p.v = MAXV * 0.65;
    h.up = false;
    h.drive_human(p, 1.0 / 120);
    check(p.crash > 0, "contra un árbol, caída");
    for (int i = 0; i < 3 * 120; i++) h.drive_human(p, 1.0 / 120);
    check(p.crash <= 0 && std::fabs(p.x) <= 0.8 && p.v == 0, "tras la caída, de vuelta en la pista");
  }
  // Con los mandos del jugador (las teclas, sin trampas): frena antes de las
  // curvas, gira hacia su trazada y termina una vuelta sin caerse.
  {
    Game b;
    b.laps = 2;
    b.reset(3);
    double tt = 0;
    int crashes = 0;
    const int N = tr.n();
    while (tt < 300 && !b.me().finished()) {
      Rider& q = b.me();
      double z = posmod(q.d, tr.L);
      int i = tr.idx(z);
      double target = MAXV;
      for (int k = 0; k < 70; k++) {
        double c = std::fabs(tr.s[(i + k) % N].curve);
        if (c < 0.5) continue;
        double vc = MAXV * std::min(1.0, 3.0 / c);
        target = std::min(target, std::sqrt(vc * vc + 2 * BRAKE * 0.7 * std::max(0.0, k * SEG - posmod(z, SEG))));
      }
      double ahead = 0;
      for (int k = 4; k < 24; k++) ahead += tr.s[(i + k) % N].curve;
      double ideal = clamp(ahead / 20 * 0.16, -0.6, 0.6);
      double sp = q.v / MAXV;
      double want = sp * tr.s[i].curve * CENTRIFUGAL + (ideal - q.x) * 3;
      b.up = q.v < target - 100;
      b.down = q.v > target + 400;
      b.right = want > 0.12;
      b.left = want < -0.12;
      bool was = q.crash > 0;
      b.update(1.0 / 60);
      if (!was && q.crash > 0) crashes++;
      tt += 1.0 / 60;
    }
    const Rider& q = b.me();
    check(q.finished(), "con las teclas se termina la carrera");
    check(crashes == 0, "con las teclas, sin caídas");
    check(q.best > 30 && q.best < 52, "con las teclas, vueltas de carrera");
    std::printf("keys best=%s pos=%d\n", fmt_time(q.best).c_str(), b.position(0));
  }
  // Marchas y revoluciones.
  check(Game::gear_of(0) == 1 && Game::gear_of(MAXV) == 6, "seis marchas");
  check(Game::rpm_of(MAXV * 0.5) > 5000, "revoluciones");
  check(fmt_time(83.456) == "1:23.456" && fmt_time(83.456, true) == "01:23.456", "formato de tiempos");
  check(fmt("{0} de {1}", {"3", "8"}) == "3 de 8", "textos con huecos");
  std::printf("selftest %s segs=%d props=%d laps=%d winner=%s time=%s best=%s top=%.0f\n",
              fails ? "FAILED" : "ok", tr.n(), props, g.laps, win.name.c_str(),
              fmt_time(win_time).c_str(), fmt_time(win_best).c_str(), top);
  std::fflush(stdout);
  return fails ? 1 : 0;
}

// ------------------------------------------------------------ capturas
// Sin abrir la ventana: DMS_RACING_SHOT=<carpeta> deja salida.png, carrera.png,
// curva.png y meta.png (DMS_RACING_SHOT_SIZE=1600x900 para otro tamaño).
void shot(Game& g, const std::string& file, int W, int H) {
  Fl_Image_Surface surf(W, H, 0);
  Fl_Surface_Device::push_current(&surf);
  g.render(0, 0, W, H);
  Fl_RGB_Image* img = surf.image();
  Fl_Surface_Device::pop_current();
  fl_write_png(file.c_str(), img);
  delete img;
}

int shots(const std::string& dir, int W, int H) {
  Fl::screen_count();   // abre la conexión con la pantalla, sin ventana
  make_dirs(dir);
  const double dt = 1.0 / 60;
  // 1. La parrilla con tres luces encendidas.
  {
    Game g;
    g.reset(31);
    g.record = 0;
    while (g.lights_on() < 3) g.update(dt);
    g.update(0.2);
    shot(g, dir + "/salida.png", W, H);
  }
  // 2. En carrera: el momento de la primera vuelta y media con la moto más
  // inclinada y más rivales delante.
  auto play = [&](Game& g, double until) {
    g.laps = 3;
    g.reset(31);
    g.autopilot = true;
    g.me().skill = 0.95;
    double t = 0;
    while (t < until) { g.update(dt); t += dt; }
  };
  {
    Game g;
    play(g, 0);
    double t = 0, best = -1, at = 20;
    while (t < 100) {
      g.update(dt);
      t += dt;
      if (g.st != RACE || t < 28) continue;
      const Rider& p = g.me();
      int ahead = 0;
      for (size_t i = 1; i < g.rs.size(); i++) {
        double rel = g.rs[i].d - p.d;
        if (rel > SEG * 3 && rel < SEG * 45 && std::fabs(g.rs[i].x - p.x) < 1.1) ahead++;
      }
      double score = std::min(std::fabs(p.lean), 45.0) / 45 * 2 + std::min(ahead, 3);
      if (score > best) { best = score; at = t; }
    }
    Game h;
    play(h, at);
    h.record = 0;
    shot(h, dir + "/carrera.png", W, H);
  }
  // 3. Una curva cerrada, inclinado y con un rival cerca, ya en la segunda vuelta.
  {
    Game g;
    play(g, 0);
    double t = 0, best = -1, at = 60;
    while (t < 110) {
      g.update(dt);
      t += dt;
      if (g.st != RACE || g.me().lap < 1) continue;
      const Rider& p = g.me();
      double c = std::fabs(g.tr.at(p.d + PLAYER_Z).curve);
      if (c < 3.9) continue;
      int near_ = 0;
      for (size_t i = 1; i < g.rs.size(); i++) {
        double rel = g.rs[i].d - p.d;
        if (rel > SEG * 4 && rel < SEG * 25) near_++;
      }
      double score = std::min(std::fabs(p.lean), 50.0) / 50 * 2 + std::min(near_, 2);
      if (score > best) { best = score; at = t; }
    }
    Game h;
    play(h, at);
    h.record = 0;
    shot(h, dir + "/curva.png", W, H);
  }
  // 4. La clasificación final.
  {
    Game g;
    play(g, 0);
    double t = 0;
    while (t < 900 && !std::all_of(g.rs.begin(), g.rs.end(), [](const Rider& r) { return r.finished(); })) {
      g.update(dt);
      t += dt;
    }
    g.done_t = 10;
    g.st = DONE;
    g.msg_t = 0;
    shot(g, dir + "/meta.png", W, H);
  }
  std::printf("shots ok %s\n", dir.c_str());
  return 0;
}

}  // namespace rc

// ============================================================ la vista
class RaceView : public Fl_Widget {
public:
  rc::Game* game = nullptr;
  std::function<bool(int)> on_key;   // teclas que no son de pilotar
  RaceView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void draw() override {
    if (game) game->render(x(), y(), w(), h());
  }

  int handle(int e) override {
    switch (e) {
      case FL_FOCUS:
        return 1;
      case FL_UNFOCUS:
        if (game) game->release_keys();
        return 1;
      case FL_PUSH:
        take_focus();
        return 1;
      case FL_KEYDOWN:
      case FL_KEYUP: {
        int k = Fl::event_key();
        if (k >= 'A' && k <= 'Z') k += 'a' - 'A';
        if (game && game->key(k, e == FL_KEYDOWN)) return 1;
        if (e == FL_KEYDOWN && on_key && on_key(k)) return 1;
        return 0;
      }
    }
    return Fl_Widget::handle(e);
  }
};

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  rc::Game game;
  RaceView* view = nullptr;
  std::chrono::steady_clock::time_point last;
  std::string cfg;
  int frames = 0;

  Form1() {
    if (fl_getenv("DMS_RACING_SELFTEST")) std::exit(rc::selftest());
    if (const char* d = fl_getenv("DMS_RACING_SHOT")) {
      int W = 1600, H = 900;
      if (const char* s = fl_getenv("DMS_RACING_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
      set_fonts();
      std::exit(rc::shots(d, W, H));
    }
  }

  static void set_fonts() {
#ifdef _WIN32
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
    Fl::set_font(FL_HELVETICA_BOLD_ITALIC, "PSegoe UI Black");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
    Fl::set_font(FL_HELVETICA_BOLD_ITALIC, "HelveticaNeue-CondensedBlack");
#endif
  }

  void form_create() override {
    set_fonts();
    cfg = rc::config_dir();
    load_settings();
    Track->box(FL_NO_BOX);
    Track->resizable(nullptr);
    TrackHint->hide();   // el aviso del Diseñador
    Menu1->box(FL_FLAT_BOX);
    Menu1->color(rc::rgb(0x1b2129));
    Menu1->textcolor(FL_WHITE);
    Menu1->selection_color(rc::rgb(0xd61f26));
    view = new RaceView(Track->x(), Track->y(), Track->w(), Track->h());
    Track->add(view);
    view->game = &game;
    view->on_key = [this](int k) { return command_key(k); };
    setup_menu();
    callback(window_cb, this);
    size_range(640, 400);
    new_race();
    layout();
    view->take_focus();
    last = std::chrono::steady_clock::now();
    if (fl_getenv("DMS_RACING_SMOKE")) Fl::add_timeout(2.5, smoke, this);
  }

  void form_close() override { save_settings(); }

  void resize(int X, int Y, int W, int H) override {
    FormDesign::resize(X, Y, W, H);
    layout();
  }

  void layout() {
    if (!view) return;
    int top = Menu1->visible() ? Menu1->h() : 0;
    Menu1->resize(0, 0, w(), Menu1->h());
    Track->resize(0, top, w(), h() - top);
    view->resize(0, top, w(), h() - top);
    redraw();
  }

  // ---- el reloj del juego (el Timer del diseño, cada 16 ms)
  void Tick_timer() override {
    auto now = std::chrono::steady_clock::now();
    double dt = std::chrono::duration<double>(now - last).count();
    last = now;
    game.update(std::min(dt, 0.05));
    if (game.record_changed) {
      game.record_changed = false;
      save_settings();
    }
    frames++;
    view->redraw();
  }

  void new_race() {
    game.reset((uint32_t)std::chrono::steady_clock::now().time_since_epoch().count());
    sync_menu();
  }

  // Teclas que no son de pilotar: pausa, nueva carrera.
  bool command_key(int k) {
    if (k == 'p' || k == FL_Escape) {
      if (game.st != rc::LIGHTS || game.t > 0) game.paused = !game.paused;
      sync_menu();
      return true;
    }
    if ((k == FL_Enter || k == FL_KP_Enter) && game.st == rc::DONE) {
      new_race();
      return true;
    }
    return false;
  }

  static void window_cb(Fl_Widget* w, void* p) {
    auto* f = static_cast<Form1*>(p);
    // Esc es la pausa, no cerrar la ventana.
    if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) {
      f->command_key(FL_Escape);
      return;
    }
    f->form_close();
    w->hide();
  }

  // ---- el menú: marcas de las opciones y atajos de teclado
  void mark(const char* path, int flags, bool on, int shortcut = 0) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    Menu1->mode(i, (Menu1->mode(i) & FL_MENU_DIVIDER) | flags | (on ? FL_MENU_VALUE : 0));
    if (shortcut) Menu1->shortcut(i, shortcut);
  }

  void setup_menu() {
    mark(tx::MP_NEW, 0, false, FL_F + 2);
    mark(tx::MP_FULLSCREEN, 0, false, FL_F + 11);
    sync_menu();
  }

  void sync_menu() {
    mark(tx::MP_PAUSE, FL_MENU_TOGGLE, game.paused);
    mark(tx::MP_LAPS1, FL_MENU_RADIO, game.laps == 1);
    mark(tx::MP_LAPS3, FL_MENU_RADIO, game.laps == 3);
    mark(tx::MP_LAPS5, FL_MENU_RADIO, game.laps == 5);
    mark(tx::MP_EASY, FL_MENU_RADIO, game.level == 0);
    mark(tx::MP_NORMAL, FL_MENU_RADIO, game.level == 1);
    mark(tx::MP_HARD, FL_MENU_RADIO, game.level == 2);
    mark(tx::MP_TOWER, FL_MENU_TOGGLE, game.show_tower);
    mark(tx::MP_MAP, FL_MENU_TOGGLE, game.show_map);
    mark(tx::MP_TAGS, FL_MENU_TOGGLE, game.show_tags);
    Menu1->redraw();
  }

  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_NEW) new_race();
    else if (item == tx::MP_PAUSE) command_key('p');
    else if (item == tx::MP_LAPS1 || item == tx::MP_LAPS3 || item == tx::MP_LAPS5) {
      game.laps = item == tx::MP_LAPS1 ? 1 : item == tx::MP_LAPS3 ? 3 : 5;
      new_race();
    } else if (item == tx::MP_EASY || item == tx::MP_NORMAL || item == tx::MP_HARD) {
      game.level = item == tx::MP_EASY ? 0 : item == tx::MP_NORMAL ? 1 : 2;
      new_race();
    } else if (item == tx::MP_TOWER) game.show_tower = !game.show_tower;
    else if (item == tx::MP_MAP) game.show_map = !game.show_map;
    else if (item == tx::MP_TAGS) game.show_tags = !game.show_tags;
    else if (item == tx::MP_FULLSCREEN) {
      if (fullscreen_active()) fullscreen_off();
      else fullscreen();
    } else if (item == tx::MP_KEYS) {
      game.paused = true;
      fl_message_title(tx::L_KEYS);
      fl_message("%s", tx::KEYS_TEXT);
    } else if (item == tx::MP_ABOUT) {
      game.paused = true;
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", rc::fmt(tx::ABOUT_TEXT, {v}).c_str());
    } else if (item == tx::MP_QUIT) {
      form_close();
      hide();
      return;
    }
    if (item == tx::MP_TOWER || item == tx::MP_MAP || item == tx::MP_TAGS) save_settings();
    sync_menu();
    last = std::chrono::steady_clock::now();
    view->take_focus();
  }

  // ---- ajustes: vueltas, dificultad, lo que se ve y el récord
  std::string settings_file() const { return cfg + "/settings.txt"; }

  void load_settings() {
    FILE* f = fl_fopen(settings_file().c_str(), "r");
    if (!f) return;
    char line[256];
    while (std::fgets(line, sizeof line, f)) {
      char key[64];
      double v;
      if (std::sscanf(line, "%63[^=]=%lf", key, &v) != 2) continue;
      std::string k = key;
      if (k == "laps" && (v == 1 || v == 3 || v == 5)) game.laps = (int)v;
      else if (k == "level" && v >= 0 && v <= 2) game.level = (int)v;
      else if (k == "tower") game.show_tower = v != 0;
      else if (k == "map") game.show_map = v != 0;
      else if (k == "tags") game.show_tags = v != 0;
      else if (k == "record" && v > 0) game.record = v;
    }
    std::fclose(f);
  }

  void save_settings() {
    rc::make_dirs(cfg);
    FILE* f = fl_fopen(settings_file().c_str(), "w");
    if (!f) return;
    std::fprintf(f, "laps=%d\nlevel=%d\ntower=%d\nmap=%d\ntags=%d\nrecord=%.3f\n", game.laps, game.level,
                 game.show_tower, game.show_map, game.show_tags, game.record);
    std::fclose(f);
  }

  // Prueba de humo con la ventana abierta: DMS_RACING_SMOKE=1.
  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok frames=%d state=%d\n", f->frames, (int)f->game.st);
    std::fflush(stdout);
    f->hide();
  }
};
''';
