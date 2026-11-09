part of 'tk_examples.dart';

// El código en C++ del editor de imágenes (tk_showcase_cpp_image_editor.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _imageEditorCode = r'''
// ============================================================ la imagen
// Un documento es una pila de capas RGBA de 8 bits (sin premultiplicar), cada
// una con su posición, visibilidad, opacidad y modo de fusión. Los píxeles de
// cada capa van en un shared_ptr: el historial guarda copias del documento
// que comparten las capas que no cambian (se copian al modificarlas).
namespace ie {

const double PI = 3.14159265358979323846;
inline int clampi(int v, int lo, int hi) { return v < lo ? lo : v > hi ? hi : v; }
inline double clampd(double v, double lo, double hi) { return v < lo ? lo : v > hi ? hi : v; }
inline int iround(double v) { return (int)std::lround(v); }
inline uint8_t u8(double v) { return (uint8_t)clampi(iround(v), 0, 255); }
inline double smooth(double t) { t = clampd(t, 0, 1); return t * t * (3 - 2 * t); }

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}

// Un número con la coma decimal del idioma: num(66.666, 1) → «66,7».
std::string num(double v, int dec = 0) {
  char b[48];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}

// Un generador pseudoaleatorio propio: el mismo ruido con la misma semilla.
struct Rng {
  uint32_t s;
  explicit Rng(uint32_t v = 1) : s(v ? v : 1) {}
  uint32_t u() { s ^= s << 13; s ^= s >> 17; s ^= s << 5; return s; }
  double next() { return (u() & 0xffffff) / 16777216.0; }
  double gauss() { double a = next() + next() + next() + next() - 2; return a * 1.7320508; }
};

struct Rect {
  int x = 0, y = 0, w = 0, h = 0;
  bool empty() const { return w <= 0 || h <= 0; }
  int r() const { return x + w; }
  int b() const { return y + h; }
  bool has(int px, int py) const { return px >= x && py >= y && px < x + w && py < y + h; }
  bool operator==(const Rect& o) const { return x == o.x && y == o.y && w == o.w && h == o.h; }
  bool operator!=(const Rect& o) const { return !(*this == o); }
  Rect moved(int dx, int dy) const { return {x + dx, y + dy, w, h}; }
  Rect grown(int d) const { return {x - d, y - d, w + 2 * d, h + 2 * d}; }
};
inline Rect inter(const Rect& a, const Rect& b) {
  int x0 = std::max(a.x, b.x), y0 = std::max(a.y, b.y);
  int x1 = std::min(a.r(), b.r()), y1 = std::min(a.b(), b.b());
  return x1 > x0 && y1 > y0 ? Rect{x0, y0, x1 - x0, y1 - y0} : Rect{};
}
inline Rect unite(const Rect& a, const Rect& b) {
  if (a.empty()) return b;
  if (b.empty()) return a;
  int x0 = std::min(a.x, b.x), y0 = std::min(a.y, b.y);
  return {x0, y0, std::max(a.r(), b.r()) - x0, std::max(a.b(), b.b()) - y0};
}
// El rectángulo entre dos esquinas (las dos incluidas).
inline Rect corners(int x0, int y0, int x1, int y1) {
  return {std::min(x0, x1), std::min(y0, y1), std::abs(x1 - x0) + 1, std::abs(y1 - y0) + 1};
}

struct Img {
  int w = 0, h = 0;
  std::vector<uint8_t> px;   // RGBA, fila a fila
  Img() = default;
  Img(int W, int H) : w(std::max(W, 0)), h(std::max(H, 0)), px((size_t)w * h * 4, 0) {}
  Img(int W, int H, uint32_t rgb, int a) : Img(W, H) {
    for (size_t i = 0; i < px.size(); i += 4) {
      px[i] = rgb >> 16; px[i + 1] = rgb >> 8; px[i + 2] = rgb; px[i + 3] = (uint8_t)a;
    }
  }
  uint8_t* at(int x, int y) { return px.data() + ((size_t)y * w + x) * 4; }
  const uint8_t* at(int x, int y) const { return px.data() + ((size_t)y * w + x) * 4; }
  Rect rect() const { return {0, 0, w, h}; }
};
using ImgP = std::shared_ptr<Img>;

enum Blend { B_NORMAL, B_MULTIPLY, B_SCREEN, B_OVERLAY, B_DARKEN, B_LIGHTEN, B_DIFFERENCE, B_ADD, B_COUNT };
inline const char* blend_name(int b) {
  static const char* const n[] = {tx::B_NORMAL, tx::B_MULTIPLY, tx::B_SCREEN, tx::B_OVERLAY,
                                  tx::B_DARKEN, tx::B_LIGHTEN, tx::B_DIFFERENCE, tx::B_ADD};
  return n[clampi(b, 0, B_COUNT - 1)];
}

struct Layer {
  std::string name;
  ImgP img;
  int x = 0, y = 0;
  bool visible = true;
  double opacity = 1;
  int blend = B_NORMAL;
  Rect bounds() const { return {x, y, img->w, img->h}; }
};

struct Doc {
  int w = 0, h = 0;
  std::vector<Layer> layers;   // la 0 es la de abajo
  int active = 0;
  Rect sel;                    // la selección (vacía: sin selección)
  Layer& cur() { return layers[active]; }
  const Layer& cur() const { return layers[active]; }
  Rect canvas() const { return {0, 0, w, h}; }
  // Los píxeles de la capa i, para cambiarlos: si el historial los comparte,
  // primero se copian.
  Img& mut(int i) {
    auto& p = layers[i].img;
    if (p.use_count() > 1) p = std::make_shared<Img>(*p);
    return *p;
  }
  // Lo que tocan los ajustes y filtros en la capa i: la selección (o todo el
  // lienzo) en las coordenadas de la capa.
  Rect area(int i) const {
    const Layer& L = layers[i];
    Rect r = inter(sel.empty() ? canvas() : sel, L.bounds());
    return r.moved(-L.x, -L.y);
  }
};

Layer make_layer(const std::string& name, int w, int h, uint32_t rgb = 0, int a = 0) {
  Layer L;
  L.name = name;
  L.img = std::make_shared<Img>(w, h, rgb, a);
  return L;
}

// ------------------------------------------------------------ historial
struct Step {
  std::string label;
  Doc doc;
};

struct History {
  std::vector<Step> steps;
  int cur = -1;
  static constexpr size_t MAX_BYTES = 600u << 20;   // 600 MB de píxeles
  static constexpr int MAX_STEPS = 50;

  void reset(const Doc& d, const std::string& label) {
    steps.clear();
    steps.push_back({label, d});
    cur = 0;
  }
  void push(const Doc& d, const std::string& label) {
    steps.resize(cur + 1);
    steps.push_back({label, d});
    cur++;
    while (steps.size() > 2 && ((int)steps.size() > MAX_STEPS || bytes() > MAX_BYTES)) {
      steps.erase(steps.begin());
      cur--;
    }
  }
  bool can_undo() const { return cur > 0; }
  bool can_redo() const { return cur + 1 < (int)steps.size(); }
  // Los bytes de las capas distintas que guarda (las compartidas, una vez).
  size_t bytes() const {
    std::vector<const Img*> seen;
    size_t n = 0;
    for (const auto& s : steps)
      for (const auto& L : s.doc.layers) {
        const Img* p = L.img.get();
        if (std::find(seen.begin(), seen.end(), p) != seen.end()) continue;
        seen.push_back(p);
        n += p->px.size();
      }
    return n;
  }
};

// ------------------------------------------------------------ fusión
inline float blendf(int mode, float b, float s) {
  switch (mode) {
    case B_MULTIPLY: return b * s;
    case B_SCREEN: return b + s - b * s;
    case B_OVERLAY: return b <= 0.5f ? 2 * b * s : 1 - 2 * (1 - b) * (1 - s);
    case B_DARKEN: return std::min(b, s);
    case B_LIGHTEN: return std::max(b, s);
    case B_DIFFERENCE: return std::fabs(b - s);
    case B_ADD: return std::min(1.f, b + s);
    default: return s;
  }
}

// Las capas visibles, de abajo arriba, en el rectángulo r de out (del
// tamaño del documento). Las cuentas, en coma flotante y premultiplicadas.
void composite(const Doc& d, Img& out, Rect r) {
  if (out.w != d.w || out.h != d.h) {
    out = Img(d.w, d.h);
    r = out.rect();
  }
  r = inter(r, out.rect());
  if (r.empty()) return;
  // Fila a fila: poca memoria aunque la imagen sea enorme.
  std::vector<float> acc((size_t)r.w * 4);
  for (int y = r.y; y < r.b(); y++) {
    std::fill(acc.begin(), acc.end(), 0.f);
    for (const Layer& L : d.layers) {
      if (!L.visible || L.opacity <= 0) continue;
      Rect q = inter({r.x, y, r.w, 1}, L.bounds());
      if (q.empty()) continue;
      const float op = (float)L.opacity / 255.f;
      const uint8_t* s = L.img->at(q.x - L.x, y - L.y);
      float* a = &acc[(size_t)(q.x - r.x) * 4];
      for (int x = 0; x < q.w; x++, s += 4, a += 4) {
        float as = s[3] * op;
        if (as <= 0) continue;
        float ab = a[3];
        float c[3] = {s[0] / 255.f, s[1] / 255.f, s[2] / 255.f};
        if (L.blend != B_NORMAL && ab > 0) {
          for (int k = 0; k < 3; k++) c[k] = (1 - ab) * c[k] + ab * blendf(L.blend, a[k] / ab, c[k]);
        }
        for (int k = 0; k < 3; k++) a[k] = as * c[k] + a[k] * (1 - as);
        a[3] = as + ab * (1 - as);
      }
    }
    const float* a = acc.data();
    uint8_t* o = out.at(r.x, y);
    for (int x = 0; x < r.w; x++, a += 4, o += 4) {
      if (a[3] <= 0.0005f) { o[0] = o[1] = o[2] = o[3] = 0; continue; }
      for (int k = 0; k < 3; k++) o[k] = u8(a[k] / a[3] * 255);
      o[3] = u8(a[3] * 255);
    }
  }
}

Img flatten(const Doc& d) {
  Img out;
  composite(d, out, d.canvas());
  return out;
}

// Sobre un color de fondo (para JPEG y BMP, que no tienen transparencia).
Img on_color(const Img& s, uint32_t rgb) {
  Img o(s.w, s.h);
  const int bg[3] = {(int)(rgb >> 16) & 255, (int)(rgb >> 8) & 255, (int)rgb & 255};
  for (size_t i = 0; i < s.px.size(); i += 4) {
    int a = s.px[i + 3];
    for (int k = 0; k < 3; k++) o.px[i + k] = (uint8_t)((s.px[i + k] * a + bg[k] * (255 - a) + 127) / 255);
    o.px[i + 3] = 255;
  }
  return o;
}

// ------------------------------------------------------------ premultiplicado
std::vector<float> to_pre(const Img& s) {
  std::vector<float> b(s.px.size());
  for (size_t i = 0; i < s.px.size(); i += 4) {
    float a = s.px[i + 3] / 255.f;
    b[i] = s.px[i] * a; b[i + 1] = s.px[i + 1] * a; b[i + 2] = s.px[i + 2] * a; b[i + 3] = a;
  }
  return b;
}
inline void from_pre(const float* p, uint8_t* o) {
  if (p[3] <= 0.0005f) { o[0] = o[1] = o[2] = o[3] = 0; return; }
  for (int k = 0; k < 3; k++) o[k] = u8(p[k] / p[3]);
  o[3] = u8(p[3] * 255);
}

// ------------------------------------------------------------ recortar, girar
Img crop_img(const Img& s, Rect r) {
  Img o(r.w, r.h);
  Rect q = inter(r, s.rect());
  for (int y = q.y; y < q.b(); y++) std::memcpy(o.at(q.x - r.x, y - r.y), s.at(q.x, y), (size_t)q.w * 4);
  return o;
}

Img rot90(const Img& s, bool cw) {
  Img o(s.h, s.w);
  for (int y = 0; y < s.h; y++)
    for (int x = 0; x < s.w; x++) {
      uint8_t* d = cw ? o.at(s.h - 1 - y, x) : o.at(y, s.w - 1 - x);
      std::memcpy(d, s.at(x, y), 4);
    }
  return o;
}

Img flip(const Img& s, bool horizontal) {
  Img o(s.w, s.h);
  for (int y = 0; y < s.h; y++)
    for (int x = 0; x < s.w; x++)
      std::memcpy(horizontal ? o.at(s.w - 1 - x, y) : o.at(x, s.h - 1 - y), s.at(x, y), 4);
  return o;
}

// El color en (fx, fy) con interpolación bilineal, premultiplicado (el
// centro del píxel i está en i). Fuera de la imagen, transparente.
inline void bilinear(const Img& s, double fx, double fy, float o[4]) {
  int x0 = (int)std::floor(fx), y0 = (int)std::floor(fy);
  float tx_ = (float)(fx - x0), ty = (float)(fy - y0);
  o[0] = o[1] = o[2] = o[3] = 0;
  for (int j = 0; j < 2; j++)
    for (int i = 0; i < 2; i++) {
      int x = x0 + i, y = y0 + j;
      if (x < 0 || y < 0 || x >= s.w || y >= s.h) continue;
      float wgt = (i ? tx_ : 1 - tx_) * (j ? ty : 1 - ty);
      const uint8_t* p = s.at(x, y);
      float a = p[3] / 255.f * wgt;
      o[0] += p[0] * a; o[1] += p[1] * a; o[2] += p[2] * a; o[3] += a;
    }
}

// ------------------------------------------------------------ cambiar el tamaño
enum Resample { RS_NEAREST, RS_BILINEAR, RS_BICUBIC };

inline double kernel(int m, double x) {
  x = std::fabs(x);
  if (m == RS_BILINEAR) return x < 1 ? 1 - x : 0;
  // Cúbica de Keys (a = -0.5), la «bicúbica» de siempre.
  if (x < 1) return (1.5 * x - 2.5) * x * x + 1;
  if (x < 2) return ((-0.5 * x + 2.5) * x - 4) * x + 2;
  return 0;
}

// Los pesos de cada píxel de destino (al reducir, el núcleo se ensancha: así
// no salen dientes de sierra).
struct Taps {
  std::vector<int> first, count;
  std::vector<float> w;
  std::vector<size_t> at;
};
Taps taps(int src, int dst, int m) {
  Taps t;
  double scale = (double)dst / src, f = std::max(1.0, 1 / scale);
  double support = (m == RS_BILINEAR ? 1 : 2) * f;
  for (int i = 0; i < dst; i++) {
    double c = (i + 0.5) / scale - 0.5;
    int lo = (int)std::ceil(c - support), hi = (int)std::floor(c + support);
    t.first.push_back(lo);
    t.count.push_back(hi - lo + 1);
    t.at.push_back(t.w.size());
    double sum = 0;
    size_t start = t.w.size();
    for (int k = lo; k <= hi; k++) {
      double v = kernel(m, (k - c) / f);
      t.w.push_back((float)v);
      sum += v;
    }
    if (sum != 0)
      for (size_t k = start; k < t.w.size(); k++) t.w[k] = (float)(t.w[k] / sum);
  }
  return t;
}

Img resample(const Img& s, int nw, int nh, int m) {
  nw = std::max(nw, 1);
  nh = std::max(nh, 1);
  Img o(nw, nh);
  if (s.w == 0 || s.h == 0) return o;
  if (m == RS_NEAREST) {
    for (int y = 0; y < nh; y++) {
      int sy = std::min(s.h - 1, (int)((y + 0.5) * s.h / nh));
      for (int x = 0; x < nw; x++) std::memcpy(o.at(x, y), s.at(std::min(s.w - 1, (int)((x + 0.5) * s.w / nw)), sy), 4);
    }
    return o;
  }
  std::vector<float> pre = to_pre(s), mid((size_t)nw * s.h * 4);
  Taps tx_ = taps(s.w, nw, m), ty = taps(s.h, nh, m);
  for (int y = 0; y < s.h; y++)
    for (int x = 0; x < nw; x++) {
      float acc[4] = {0, 0, 0, 0};
      for (int k = 0; k < tx_.count[x]; k++) {
        int sx = clampi(tx_.first[x] + k, 0, s.w - 1);
        float wgt = tx_.w[tx_.at[x] + k];
        const float* p = &pre[((size_t)y * s.w + sx) * 4];
        for (int c = 0; c < 4; c++) acc[c] += p[c] * wgt;
      }
      std::memcpy(&mid[((size_t)y * nw + x) * 4], acc, sizeof acc);
    }
  for (int y = 0; y < nh; y++)
    for (int x = 0; x < nw; x++) {
      float acc[4] = {0, 0, 0, 0};
      for (int k = 0; k < ty.count[y]; k++) {
        int sy = clampi(ty.first[y] + k, 0, s.h - 1);
        float wgt = ty.w[ty.at[y] + k];
        const float* p = &mid[((size_t)sy * nw + x) * 4];
        for (int c = 0; c < 4; c++) acc[c] += p[c] * wgt;
      }
      acc[3] = clampd(acc[3], 0, 1);
      for (int c = 0; c < 3; c++) acc[c] = (float)clampd(acc[c], 0, 255 * acc[3]);
      from_pre(acc, o.at(x, y));
    }
  return o;
}

// ------------------------------------------------------------ el documento entero
// Cambiar el tamaño de la imagen: todas las capas a escala.
void resize_doc(Doc& d, int nw, int nh, int m) {
  double sx = (double)nw / d.w, sy = (double)nh / d.h;
  for (auto& L : d.layers) {
    int lw = std::max(1, iround(L.img->w * sx)), lh = std::max(1, iround(L.img->h * sy));
    L.img = std::make_shared<Img>(resample(*L.img, lw, lh, m));
    L.x = iround(L.x * sx);
    L.y = iround(L.y * sy);
  }
  d.w = nw;
  d.h = nh;
  d.sel = {};
}

// Recortar el lienzo al rectángulo r: lo que queda fuera de cada capa se pierde.
void crop_doc(Doc& d, Rect r) {
  r = inter(r, d.canvas());
  if (r.empty()) return;
  for (auto& L : d.layers) {
    Rect q = inter(L.bounds(), r);
    if (q.empty()) q = {r.x, r.y, 1, 1};
    L.img = std::make_shared<Img>(crop_img(*L.img, q.moved(-L.x, -L.y)));
    L.x = q.x - r.x;
    L.y = q.y - r.y;
  }
  d.w = r.w;
  d.h = r.h;
  d.sel = {};
}

// Tamaño del lienzo: las capas no cambian, se mueven según el ancla (0..8,
// de izquierda a derecha y de arriba abajo).
void canvas_size(Doc& d, int nw, int nh, int anchor) {
  int ax = anchor % 3, ay = anchor / 3;
  int dx = ax == 0 ? 0 : ax == 1 ? (nw - d.w) / 2 : nw - d.w;
  int dy = ay == 0 ? 0 : ay == 1 ? (nh - d.h) / 2 : nh - d.h;
  for (auto& L : d.layers) {
    L.x += dx;
    L.y += dy;
  }
  d.w = nw;
  d.h = nh;
  d.sel = {};
  crop_doc(d, d.canvas());   // lo que se sale del lienzo nuevo se pierde
}

// Girar 90° (cw: a la derecha) o 180°, y voltear: exacto, píxel a píxel.
void rotate_doc(Doc& d, int quarter) {   // 1: 90° derecha, 2: 180°, 3: 90° izquierda
  quarter = ((quarter % 4) + 4) % 4;
  if (quarter == 0) return;
  for (auto& L : d.layers) {
    int lw = L.img->w, lh = L.img->h;
    if (quarter == 1) {
      L.img = std::make_shared<Img>(rot90(*L.img, true));
      int nx = d.h - (L.y + lh), ny = L.x;
      L.x = nx; L.y = ny;
    } else if (quarter == 3) {
      L.img = std::make_shared<Img>(rot90(*L.img, false));
      int nx = L.y, ny = d.w - (L.x + lw);
      L.x = nx; L.y = ny;
    } else {
      L.img = std::make_shared<Img>(flip(flip(*L.img, true), false));
      L.x = d.w - (L.x + lw);
      L.y = d.h - (L.y + lh);
    }
  }
  if (quarter != 2) std::swap(d.w, d.h);
  d.sel = {};
}

void flip_doc(Doc& d, bool horizontal) {
  for (auto& L : d.layers) {
    L.img = std::make_shared<Img>(flip(*L.img, horizontal));
    if (horizontal) L.x = d.w - (L.x + L.img->w);
    else L.y = d.h - (L.y + L.img->h);
  }
  d.sel = {};
}

// Girar un ángulo cualquiera (en grados, a la derecha): el lienzo crece hasta
// que cabe la imagen girada; las esquinas quedan transparentes.
void rotate_any(Doc& d, double deg) {
  double a = deg * PI / 180, c = std::cos(a), s = std::sin(a);
  int nw = std::max(1, (int)std::ceil(std::fabs(d.w * c) + std::fabs(d.h * s) - 1e-6));
  int nh = std::max(1, (int)std::ceil(std::fabs(d.w * s) + std::fabs(d.h * c) - 1e-6));
  for (auto& L : d.layers) {
    // El rectángulo girado de la capa, en el lienzo nuevo.
    double xs[4] = {(double)L.x, (double)L.x + L.img->w, (double)L.x, (double)L.x + L.img->w};
    double ys[4] = {(double)L.y, (double)L.y, (double)L.y + L.img->h, (double)L.y + L.img->h};
    double x0 = 1e18, y0 = 1e18, x1 = -1e18, y1 = -1e18;
    for (int k = 0; k < 4; k++) {
      double px = xs[k] - d.w / 2.0, py = ys[k] - d.h / 2.0;
      double qx = px * c - py * s + nw / 2.0, qy = px * s + py * c + nh / 2.0;
      x0 = std::min(x0, qx); x1 = std::max(x1, qx); y0 = std::min(y0, qy); y1 = std::max(y1, qy);
    }
    Rect b = inter(Rect{(int)std::floor(x0), (int)std::floor(y0), (int)std::ceil(x1) - (int)std::floor(x0),
                        (int)std::ceil(y1) - (int)std::floor(y0)},
                   Rect{0, 0, nw, nh});
    if (b.empty()) b = {0, 0, 1, 1};
    auto o = std::make_shared<Img>(b.w, b.h);
    for (int y = 0; y < b.h; y++)
      for (int x = 0; x < b.w; x++) {
        double qx = b.x + x + 0.5 - nw / 2.0, qy = b.y + y + 0.5 - nh / 2.0;
        double px = qx * c + qy * s + d.w / 2.0, py = -qx * s + qy * c + d.h / 2.0;
        float p[4];
        bilinear(*L.img, px - L.x - 0.5, py - L.y - 0.5, p);
        from_pre(p, o->at(x, y));
      }
    L.img = o;
    L.x = b.x;
    L.y = b.y;
  }
  d.w = nw;
  d.h = nh;
  d.sel = {};
}

// Combinar la capa i con la de debajo (con su opacidad y su modo).
void merge_down(Doc& d, int i) {
  if (i <= 0 || i >= (int)d.layers.size()) return;
  Layer& lo = d.layers[i - 1];
  const Layer& hi = d.layers[i];
  Rect b = inter(unite(lo.bounds(), hi.visible ? hi.bounds() : Rect{}), d.canvas());
  if (b.empty()) b = lo.bounds();
  Doc tmp;
  tmp.w = b.r();
  tmp.h = b.b();
  Layer a = lo, c = hi;
  a.opacity = 1;
  a.blend = B_NORMAL;
  a.visible = true;
  tmp.layers = {a, c};
  Img all;
  composite(tmp, all, b);
  auto o = std::make_shared<Img>(crop_img(all, b));
  // La opacidad de la capa de abajo pasa a los píxeles (para que no cambie nada).
  if (lo.opacity < 1)
    for (size_t k = 3; k < o->px.size(); k += 4) o->px[k] = u8(o->px[k] * lo.opacity);
  lo.img = o;
  lo.x = b.x;
  lo.y = b.y;
  lo.opacity = 1;
  lo.visible = true;
  d.layers.erase(d.layers.begin() + i);
  d.active = i - 1;
}

// Acoplar: una sola capa «Fondo», opaca sobre blanco.
void flatten_doc(Doc& d) {
  Img all = on_color(flatten(d), 0xffffff);
  Layer L;
  L.name = tx::BACKGROUND;
  L.img = std::make_shared<Img>(std::move(all));
  d.layers = {L};
  d.active = 0;
}

// ------------------------------------------------------------ ajustes
template <class F>
void each_px(Img& im, Rect r, F fn) {
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++) {
    uint8_t* p = im.at(r.x, y);
    for (int x = 0; x < r.w; x++, p += 4) fn(p);
  }
}

void apply_lut(Img& im, Rect r, const uint8_t* lut) {
  each_px(im, r, [&](uint8_t* p) { p[0] = lut[p[0]]; p[1] = lut[p[1]]; p[2] = lut[p[2]]; });
}

// Brillo de -150 a 150 y contraste de -100 a 100.
void brightness_contrast(Img& im, Rect r, double b, double c) {
  uint8_t lut[256];
  double f = std::pow(2.0, c / 50.0);
  for (int v = 0; v < 256; v++) lut[v] = u8((v + b * 0.85 - 127.5) * f + 127.5);
  apply_lut(im, r, lut);
}

// Niveles: negro y blanco de entrada, gamma y salida.
void levels(Img& im, Rect r, double ib, double gamma, double iw, double ob = 0, double ow = 255) {
  uint8_t lut[256];
  if (iw <= ib) iw = ib + 1;
  for (int v = 0; v < 256; v++) {
    double t = clampd((v - ib) / (iw - ib), 0, 1);
    t = std::pow(t, 1 / std::max(gamma, 0.01));
    lut[v] = u8(ob + t * (ow - ob));
  }
  apply_lut(im, r, lut);
}

inline void rgb_hsl(double r, double g, double b, double& h, double& s, double& l) {
  double mx = std::max({r, g, b}), mn = std::min({r, g, b});
  l = (mx + mn) / 2;
  if (mx == mn) { h = s = 0; return; }
  double dd = mx - mn;
  s = l > 0.5 ? dd / (2 - mx - mn) : dd / (mx + mn);
  if (mx == r) h = (g - b) / dd + (g < b ? 6 : 0);
  else if (mx == g) h = (b - r) / dd + 2;
  else h = (r - g) / dd + 4;
  h *= 60;
}
inline double hue2(double p, double q, double t) {
  if (t < 0) t += 1;
  if (t > 1) t -= 1;
  if (t < 1.0 / 6) return p + (q - p) * 6 * t;
  if (t < 0.5) return q;
  if (t < 2.0 / 3) return p + (q - p) * (2.0 / 3 - t) * 6;
  return p;
}
inline void hsl_rgb(double h, double s, double l, double& r, double& g, double& b) {
  if (s <= 0) { r = g = b = l; return; }
  double q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q, hh = h / 360;
  r = hue2(p, q, hh + 1.0 / 3); g = hue2(p, q, hh); b = hue2(p, q, hh - 1.0 / 3);
}

// Tono (-180..180), saturación y luminosidad (-100..100).
void hue_sat(Img& im, Rect r, double dh, double ds, double dl) {
  each_px(im, r, [&](uint8_t* p) {
    double h, s, l, R, G, B;
    rgb_hsl(p[0] / 255.0, p[1] / 255.0, p[2] / 255.0, h, s, l);
    h = std::fmod(h + dh + 360, 360);
    s = ds >= 0 ? s + (1 - s) * s * ds / 100 * 1.6 : s * (1 + ds / 100);
    s = clampd(s, 0, 1);
    l = dl >= 0 ? l + (1 - l) * dl / 100 : l * (1 + dl / 100);
    hsl_rgb(h, s, l, R, G, B);
    p[0] = u8(R * 255); p[1] = u8(G * 255); p[2] = u8(B * 255);
  });
}

inline double luma(const uint8_t* p) { return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]; }

void grayscale(Img& im, Rect r) {
  each_px(im, r, [](uint8_t* p) { p[0] = p[1] = p[2] = u8(luma(p)); });
}
void sepia(Img& im, Rect r) {
  each_px(im, r, [](uint8_t* p) {
    double R = p[0], G = p[1], B = p[2];
    p[0] = u8(R * 0.393 + G * 0.769 + B * 0.189);
    p[1] = u8(R * 0.349 + G * 0.686 + B * 0.168);
    p[2] = u8(R * 0.272 + G * 0.534 + B * 0.131);
  });
}
void invert(Img& im, Rect r) {
  each_px(im, r, [](uint8_t* p) { p[0] = 255 - p[0]; p[1] = 255 - p[1]; p[2] = 255 - p[2]; });
}
void threshold(Img& im, Rect r, int t) {
  each_px(im, r, [&](uint8_t* p) { p[0] = p[1] = p[2] = luma(p) >= t ? 255 : 0; });
}
void posterize(Img& im, Rect r, int n) {
  n = clampi(n, 2, 255);
  uint8_t lut[256];
  for (int v = 0; v < 256; v++) lut[v] = u8(std::round(std::round(v * (n - 1) / 255.0) * 255.0 / (n - 1)));
  apply_lut(im, r, lut);
}

// El histograma de la luminosidad (lo que hay dentro de r).
std::vector<int> histogram(const Img& im, Rect r) {
  std::vector<int> h(256, 0);
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++) {
    const uint8_t* p = im.at(r.x, y);
    for (int x = 0; x < r.w; x++, p += 4)
      if (p[3]) h[clampi(iround(luma(p)), 0, 255)]++;
  }
  return h;
}

// ------------------------------------------------------------ filtros
// Desenfoque gaussiano aproximado con tres desenfoques de caja (rápido con
// cualquier radio). b: premultiplicado, w×h.
void box_pass(std::vector<float>& b, std::vector<float>& t, int w, int h, int r, bool horiz) {
  int n = horiz ? w : h, lines = horiz ? h : w;
  size_t step = horiz ? 4 : (size_t)w * 4;
  float inv = 1.f / (2 * r + 1);
  for (int l = 0; l < lines; l++) {
    size_t base = horiz ? (size_t)l * w * 4 : (size_t)l * 4;
    for (int c = 0; c < 4; c++) {
      auto at = [&](int i) { return b[base + (size_t)clampi(i, 0, n - 1) * step + c]; };
      float acc = 0;
      for (int i = -r; i <= r; i++) acc += at(i);
      for (int i = 0; i < n; i++) {
        t[base + (size_t)i * step + c] = acc * inv;
        acc += at(i + r + 1) - at(i - r);
      }
    }
  }
  b.swap(t);
}

void blur_buf(std::vector<float>& b, int w, int h, double sigma) {
  if (sigma < 0.2 || w == 0 || h == 0) return;
  const int n = 3;
  double wi = std::sqrt(12 * sigma * sigma / n + 1);
  int wl = (int)std::floor(wi);
  if (wl % 2 == 0) wl--;
  int wu = wl + 2;
  int m = iround((12 * sigma * sigma - n * wl * wl - 4 * n * wl - 3 * n) / (-4.0 * wl - 4));
  std::vector<float> t(b.size());
  for (int i = 0; i < n; i++) {
    int r = ((i < m ? wl : wu) - 1) / 2;
    if (r < 1) continue;
    box_pass(b, t, w, h, r, true);
    box_pass(b, t, w, h, r, false);
  }
}

Img blurred(const Img& im, double sigma) {
  std::vector<float> b = to_pre(im);
  blur_buf(b, im.w, im.h, sigma);
  Img o(im.w, im.h);
  for (size_t i = 0; i < b.size(); i += 4) from_pre(&b[i], &o.px[i]);
  return o;
}

// Copia en im lo que hay en src dentro de r.
void paste_rect(Img& im, const Img& src, Rect r) {
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++) std::memcpy(im.at(r.x, y), src.at(r.x, y), (size_t)r.w * 4);
}

void gaussian(Img& im, Rect r, double sigma) {
  Img b = blurred(im, sigma);
  paste_rect(im, b, r);
}

// Máscara de enfoque: cantidad en %, radio y umbral.
void unsharp(Img& im, Rect r, double amount, double sigma, int thr) {
  Img b = blurred(im, sigma);
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++) {
    uint8_t* p = im.at(r.x, y);
    const uint8_t* q = b.at(r.x, y);
    for (int x = 0; x < r.w; x++, p += 4, q += 4)
      for (int c = 0; c < 3; c++) {
        int diff = p[c] - q[c];
        if (std::abs(diff) >= thr) p[c] = u8(p[c] + amount / 100 * diff);
      }
  }
}

void add_noise(Img& im, Rect r, double amount, bool mono, uint32_t seed) {
  Rng rng(seed);
  double k = amount * 1.28;
  each_px(im, r, [&](uint8_t* p) {
    if (mono) {
      double n = rng.gauss() * k;
      for (int c = 0; c < 3; c++) p[c] = u8(p[c] + n);
    } else {
      for (int c = 0; c < 3; c++) p[c] = u8(p[c] + rng.gauss() * k);
    }
  });
}

// Pixelar: cuadros de n×n del color medio (alineados con el lienzo).
void pixelate(Img& im, Rect r, int n, int ox, int oy) {
  n = std::max(n, 1);
  r = inter(r, im.rect());
  int x0 = r.x - ((r.x + ox) % n + n) % n, y0 = r.y - ((r.y + oy) % n + n) % n;
  for (int cy = y0; cy < r.b(); cy += n)
    for (int cx = x0; cx < r.r(); cx += n) {
      Rect c = inter({cx, cy, n, n}, r);
      if (c.empty()) continue;
      double acc[4] = {0, 0, 0, 0};
      for (int y = c.y; y < c.b(); y++)
        for (int x = c.x; x < c.r(); x++) {
          const uint8_t* p = im.at(x, y);
          double a = p[3] / 255.0;
          acc[0] += p[0] * a; acc[1] += p[1] * a; acc[2] += p[2] * a; acc[3] += a;
        }
      double cnt = (double)c.w * c.h;
      uint8_t v[4] = {0, 0, 0, 0};
      if (acc[3] > 0) {
        for (int k = 0; k < 3; k++) v[k] = u8(acc[k] / acc[3]);
        v[3] = u8(acc[3] / cnt * 255);
      }
      for (int y = c.y; y < c.b(); y++)
        for (int x = c.x; x < c.r(); x++) std::memcpy(im.at(x, y), v, 4);
    }
}

// Hallar bordes (Sobel): fondo blanco y los bordes oscuros.
void find_edges(Img& im, Rect r) {
  Img s = im;
  r = inter(r, im.rect());
  auto P = [&](int x, int y, int c) { return (int)s.at(clampi(x, 0, s.w - 1), clampi(y, 0, s.h - 1))[c]; };
  for (int y = r.y; y < r.b(); y++)
    for (int x = r.x; x < r.r(); x++) {
      uint8_t* p = im.at(x, y);
      for (int c = 0; c < 3; c++) {
        int gx = -P(x - 1, y - 1, c) - 2 * P(x - 1, y, c) - P(x - 1, y + 1, c) + P(x + 1, y - 1, c) + 2 * P(x + 1, y, c) + P(x + 1, y + 1, c);
        int gy = -P(x - 1, y - 1, c) - 2 * P(x, y - 1, c) - P(x + 1, y - 1, c) + P(x - 1, y + 1, c) + 2 * P(x, y + 1, c) + P(x + 1, y + 1, c);
        p[c] = u8(255 - std::sqrt((double)gx * gx + gy * gy) * 0.5);
      }
    }
}

void emboss(Img& im, Rect r) {
  Img s = im;
  r = inter(r, im.rect());
  auto L = [&](int x, int y) { return luma(s.at(clampi(x, 0, s.w - 1), clampi(y, 0, s.h - 1))); };
  for (int y = r.y; y < r.b(); y++)
    for (int x = r.x; x < r.r(); x++) {
      double v = 128 + (L(x + 1, y + 1) - L(x - 1, y - 1)) * 1.5 + (L(x + 1, y) - L(x - 1, y)) * 0.5;
      uint8_t* p = im.at(x, y);
      p[0] = p[1] = p[2] = u8(v);
    }
}

// Viñeta: oscurece hacia las esquinas del lienzo (cantidad y tamaño en %).
void vignette(Img& im, Rect r, double amount, double size, int ox, int oy, int cw, int ch) {
  double r0 = clampd(size / 100, 0, 0.98);
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++)
    for (int x = r.x; x < r.r(); x++) {
      double dx = (x + ox + 0.5 - cw / 2.0) / (cw / 2.0), dy = (y + oy + 0.5 - ch / 2.0) / (ch / 2.0);
      double dd = std::sqrt(dx * dx + dy * dy) / std::sqrt(2.0);
      double t = smooth((dd - r0) / (1 - r0));
      double f = 1 - amount / 100 * t;
      uint8_t* p = im.at(x, y);
      for (int c = 0; c < 3; c++) p[c] = u8(p[c] * f);
    }
}

// ------------------------------------------------------------ pintar
// Mezcla un color sobre el píxel con la opacidad a (0..1).
inline void over(uint8_t* p, uint32_t rgb, double a) {
  if (a <= 0) return;
  double da = p[3] / 255.0, oa = a + da * (1 - a);
  const double c[3] = {(double)((rgb >> 16) & 255), (double)((rgb >> 8) & 255), (double)(rgb & 255)};
  for (int k = 0; k < 3; k++) p[k] = u8((c[k] * a + p[k] * da * (1 - a)) / oa);
  p[3] = u8(oa * 255);
}

// Bote de pintura: rellena los píxeles parecidos al de (sx, sy) (tolerancia
// 0..255), solo los vecinos (contiguo) o todos, dentro de clip.
int flood_fill(Img& im, int sx, int sy, uint32_t rgb, double op, int tol, bool contiguous, Rect clip) {
  clip = inter(clip, im.rect());
  if (!clip.has(sx, sy)) return 0;
  uint8_t ref[4];
  std::memcpy(ref, im.at(sx, sy), 4);
  auto like = [&](int x, int y) {
    const uint8_t* p = im.at(x, y);
    if (ref[3] == 0 && p[3] == 0) return true;
    int d = std::max({std::abs(p[0] - ref[0]), std::abs(p[1] - ref[1]), std::abs(p[2] - ref[2]), std::abs(p[3] - ref[3])});
    return d <= tol;
  };
  std::vector<uint8_t> mark((size_t)im.w * im.h, 0);
  int n = 0;
  if (!contiguous) {
    for (int y = clip.y; y < clip.b(); y++)
      for (int x = clip.x; x < clip.r(); x++)
        if (like(x, y)) { mark[(size_t)y * im.w + x] = 1; n++; }
  } else {
    std::vector<std::pair<int, int>> st{{sx, sy}};
    while (!st.empty()) {
      auto [x, y] = st.back();
      st.pop_back();
      int l = x;
      while (l > clip.x && !mark[(size_t)y * im.w + l - 1] && like(l - 1, y)) l--;
      int r = x;
      while (r + 1 < clip.r() && !mark[(size_t)y * im.w + r + 1] && like(r + 1, y)) r++;
      for (int i = l; i <= r; i++) {
        if (mark[(size_t)y * im.w + i]) continue;
        mark[(size_t)y * im.w + i] = 1;
        n++;
        for (int dy : {-1, 1}) {
          int ny = y + dy;
          if (ny < clip.y || ny >= clip.b()) continue;
          if (!mark[(size_t)ny * im.w + i] && like(i, ny)) st.push_back({i, ny});
        }
      }
    }
  }
  for (int y = clip.y; y < clip.b(); y++)
    for (int x = clip.x; x < clip.r(); x++)
      if (mark[(size_t)y * im.w + x]) {
        uint8_t* p = im.at(x, y);
        if (op >= 1) { p[0] = rgb >> 16; p[1] = rgb >> 8; p[2] = rgb; p[3] = 255; }
        else over(p, rgb, op);
      }
  return n;
}

// Degradado del color a al b, de (x0, y0) a (x1, y1); radial: desde el centro.
void gradient(Img& im, Rect r, int ox, int oy, double x0, double y0, double x1, double y1, uint32_t a, uint32_t b,
              double op, bool radial) {
  double dx = x1 - x0, dy = y1 - y0, len2 = std::max(dx * dx + dy * dy, 1e-9);
  r = inter(r, im.rect());
  for (int y = r.y; y < r.b(); y++)
    for (int x = r.x; x < r.r(); x++) {
      double px = x + ox + 0.5 - x0, py = y + oy + 0.5 - y0;
      double t = radial ? std::sqrt((px * px + py * py) / len2) : (px * dx + py * dy) / len2;
      t = clampd(t, 0, 1);
      uint32_t c = 0;
      for (int s = 16; s >= 0; s -= 8) {
        int ca = (a >> s) & 255, cb = (b >> s) & 255;
        c |= (uint32_t)u8(ca + (cb - ca) * t) << s;
      }
      over(im.at(x, y), c, op);
    }
}

// Una forma rellena (0 rectángulo, 1 redondeado, 2 elipse) con bordes suaves.
void shape(Img& im, Rect box, int kind, uint32_t rgb) {
  Rect r = inter(box.grown(1), im.rect());
  double bx0 = box.x, by0 = box.y, bx1 = box.r(), by1 = box.b();
  double cx = (bx0 + bx1) / 2, cy = (by0 + by1) / 2, rx = (bx1 - bx0) / 2, ry = (by1 - by0) / 2;
  double rr = std::min(rx, ry) * 0.35;
  auto inside = [&](double x, double y) {
    if (x < bx0 || x > bx1 || y < by0 || y > by1) return false;
    if (kind == 2) { double u = (x - cx) / rx, v = (y - cy) / ry; return u * u + v * v <= 1; }
    if (kind == 1) {
      double qx = std::max(std::fabs(x - cx) - (rx - rr), 0.0), qy = std::max(std::fabs(y - cy) - (ry - rr), 0.0);
      return qx * qx + qy * qy <= rr * rr;
    }
    return true;
  };
  for (int y = r.y; y < r.b(); y++)
    for (int x = r.x; x < r.r(); x++) {
      int hit = 0;
      for (int j = 0; j < 4; j++)
        for (int i = 0; i < 4; i++) hit += inside(x + (i + 0.5) / 4, y + (j + 0.5) / 4);
      if (hit) over(im.at(x, y), rgb, hit / 16.0);
    }
}

// Las fronteras de una pincelada: la máscara (lo pintado, 0..1) y la capa
// tal como estaba al empezar.
struct Stroke {
  ImgP base;
  std::vector<float> mask;
  bool erase = false;
  uint32_t rgb = 0;
  double size = 20, hard = 0.8, op = 1;
  double lx = 0, ly = 0;     // el último toque (coordenadas de la capa)
  double carry = 0;          // lo recorrido desde el último toque
};

// Un toque del pincel en (x, y): devuelve el rectángulo que cambia.
Rect dab(Stroke& s, Img& im, double x, double y, Rect clip) {
  double rad = std::max(s.size / 2, 0.5), inner = rad * clampd(s.hard, 0, 1);
  Rect r = inter(Rect{(int)std::floor(x - rad - 1), (int)std::floor(y - rad - 1), (int)std::ceil(rad * 2 + 3),
                      (int)std::ceil(rad * 2 + 3)},
                 inter(clip, im.rect()));
  for (int py = r.y; py < r.b(); py++)
    for (int px = r.x; px < r.r(); px++) {
      double d = std::hypot(px + 0.5 - x, py + 0.5 - y);
      if (d >= rad + 0.5) continue;
      double f = d <= inner ? 1 : 1 - smooth((d - inner) / std::max(rad - inner, 1e-6));
      f *= clampd(rad - d + 0.5, 0, 1);
      float& m = s.mask[(size_t)py * im.w + px];
      if (f <= m) continue;
      m = (float)f;
      uint8_t* p = im.at(px, py);
      std::memcpy(p, s.base->at(px, py), 4);
      if (s.erase) p[3] = u8(p[3] * (1 - m * s.op));
      else over(p, s.rgb, m * s.op);
    }
  return r;
}

// Del último toque a (x, y), un toque cada cierta distancia.
Rect stroke_to(Stroke& s, Img& im, double x, double y, Rect clip) {
  double step = std::max(1.0, s.size * 0.12);
  double dx = x - s.lx, dy = y - s.ly, len = std::hypot(dx, dy);
  Rect ch;
  double t = step - s.carry;
  while (t <= len) {
    ch = unite(ch, dab(s, im, s.lx + dx * t / len, s.ly + dy * t / len, clip));
    t += step;
  }
  s.carry = len - (t - step);
  s.lx = x;
  s.ly = y;
  return ch;
}

// ------------------------------------------------------------ texto
// El texto, pintado con las fuentes del sistema en una imagen fuera de la
// pantalla: lo blanco sobre negro da la transparencia.
Img render_text(const std::string& s, Fl_Font font, int size, uint32_t rgb) {
  fl_font(font, size);
  int w = 0, h = 0;
  fl_measure(s.c_str(), w, h, 0);
  int pad = size / 4 + 2, W = std::max(1, w + 2 * pad), H = std::max(1, h + 2 * pad);
  Fl_Image_Surface surf(W, H, 0);
  Fl_Surface_Device::push_current(&surf);
  fl_color(FL_BLACK);
  fl_rectf(0, 0, W, H);
  fl_color(FL_WHITE);
  fl_font(font, size);
  fl_draw(s.c_str(), pad, pad, w, h, FL_ALIGN_TOP_LEFT | FL_ALIGN_INSIDE, nullptr, 0);
  Fl_RGB_Image* im = surf.image();
  Fl_Surface_Device::pop_current();
  Img o(W, H);
  if (im) {
    const uchar* data = (const uchar*)im->data()[0];
    int d = im->d(), ld = im->ld() ? im->ld() : im->w() * d;
    for (int y = 0; y < std::min(H, im->h()); y++)
      for (int x = 0; x < std::min(W, im->w()); x++) {
        const uchar* p = data + (size_t)y * ld + (size_t)x * d;
        uint8_t* q = o.at(x, y);
        q[0] = rgb >> 16; q[1] = rgb >> 8; q[2] = rgb;
        q[3] = d >= 3 ? std::max({p[0], p[1], p[2]}) : p[0];
      }
    delete im;
  }
  return o;
}

// ------------------------------------------------------------ la imagen de ejemplo
// Un atardecer en el Malecón, hecho en código: cielo, sol, nubes, el mar con
// el reflejo, la costa y el muro; y una palmera en su propia capa.
inline double hash2(int x, int y, int s) {
  uint32_t h = (uint32_t)x * 374761393u + (uint32_t)y * 668265263u + (uint32_t)s * 2246822519u;
  h = (h ^ (h >> 13)) * 1274126177u;
  return ((h ^ (h >> 16)) & 0xffffff) / 16777216.0;
}
inline double vnoise(double x, double y, int s) {
  int ix = (int)std::floor(x), iy = (int)std::floor(y);
  double fx = x - ix, fy = y - iy;
  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  double a = hash2(ix, iy, s), b = hash2(ix + 1, iy, s), c = hash2(ix, iy + 1, s), d = hash2(ix + 1, iy + 1, s);
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
}
inline double fbm(double x, double y, int s, int oct = 5) {
  double v = 0, amp = 0.5;
  for (int i = 0; i < oct; i++) { v += vnoise(x, y, s + i) * amp; x *= 2.02; y *= 2.02; amp *= 0.5; }
  return v;
}
inline uint32_t mixc(uint32_t a, uint32_t b, double t) {
  t = clampd(t, 0, 1);
  uint32_t c = 0;
  for (int s = 16; s >= 0; s -= 8) {
    int x = (a >> s) & 255, y = (b >> s) & 255;
    c |= (uint32_t)u8(x + (y - x) * t) << s;
  }
  return c;
}
inline void put(uint8_t* p, uint32_t c) { p[0] = c >> 16; p[1] = c >> 8; p[2] = c; p[3] = 255; }

uint32_t sky_at(double t) {   // 0 arriba, 1 el horizonte
  static const std::pair<double, uint32_t> stops[] = {
      {0, 0x1d2350}, {0.35, 0x4a3a78}, {0.62, 0xc0587a}, {0.82, 0xf08a5d}, {1, 0xffcf7a}};
  for (int i = 1; i < 5; i++)
    if (t <= stops[i].first)
      return mixc(stops[i - 1].second, stops[i].second, (t - stops[i - 1].first) / (stops[i].first - stops[i - 1].first));
  return stops[4].second;
}

Img sample_scene(int W, int H) {
  Img im(W, H);
  const double hor = H * 0.64, sunx = W * 0.6, suny = H * 0.555, sunr = H * 0.075;
  const double sx = W / 1600.0;
  for (int y = 0; y < H; y++)
    for (int x = 0; x < W; x++) {
      uint8_t* p = im.at(x, y);
      double fx = x + 0.5, fy = y + 0.5;
      if (fy < hor) {
        uint32_t c = sky_at(fy / hor);
        double ds = std::hypot(fx - sunx, fy - suny);
        double glow = std::exp(-ds / (sunr * 2.6)) * 0.75 + std::exp(-ds / (sunr * 8)) * 0.25;
        c = mixc(c, 0xffe3a6, glow);
        // Nubes: bandas alargadas de ruido.
        double n = fbm(fx / (330 * sx), fy / (70 * sx), 7);
        double band = smooth((n - 0.52) / 0.2) * smooth((hor * 0.86 - fy) / (hor * 0.2)) * (0.35 + 0.65 * smooth(fy / (hor * 0.5)));
        double lit = clampd(1 - std::fabs(fy - suny) / (hor * 0.6), 0, 1);
        uint32_t cloud = mixc(0x3b2a55, 0xff9b7a, lit * (1 - std::exp(-std::fabs(fx - sunx) / (W * 0.6))) + lit * 0.4);
        c = mixc(c, cloud, band * 0.85);
        if (ds < sunr) c = mixc(c, 0xfff6dc, clampd(sunr - ds, 0, 1.5) / 1.5);
        // Costa lejana a la izquierda.
        double ridge = hor - (30 + 55 * fbm(fx / (260 * sx), 3.3, 11, 4)) * sx * smooth((W * 0.42 - fx) / (W * 0.3));
        if (fy > ridge) c = mixc(0x5a3d6e, 0x7b4d78, (fy - ridge) / 40);
        put(p, c);
      } else {
        double t = (fy - hor) / (H - hor);
        uint32_t c = mixc(0x5b3f73, 0x1f2347, std::pow(t, 0.7));
        // Olas: rayas horizontales que se ensanchan hacia delante.
        double wave = fbm(fx / ((40 + 400 * t) * sx), fy / ((3 + 18 * t) * sx), 21, 4);
        c = mixc(c, 0xb06a8a, smooth((wave - 0.55) / 0.2) * (0.5 - 0.3 * t));
        // El reflejo del sol: una columna de destellos.
        double spread = (sunr * 0.9 + t * W * 0.12);
        double colm = std::exp(-std::pow((fx - sunx) / spread, 2));
        double sparkle = smooth((fbm(fx / (18 * sx), fy / ((2 + 6 * t) * sx), 31, 3) - 0.45) / 0.18);
        c = mixc(c, 0xffd28a, colm * sparkle * (0.95 - 0.5 * t));
        c = mixc(c, 0xffe9b8, colm * std::exp(-(fy - hor) / (8 * sx)) * 0.8);
        put(p, c);
      }
    }
  // El muro del Malecón: abajo, con su remate y farolas.
  const double wall = H * 0.865;
  for (int y = (int)wall; y < H; y++)
    for (int x = 0; x < W; x++) {
      double fy = y + 0.5;
      double stone = fbm(x / (9.0 * sx), y / (9.0 * sx), 41, 3);
      uint32_t c = fy < wall + 10 * sx ? mixc(0x6b4a62, 0x4a3450, (fy - wall) / (10 * sx))
                                       : mixc(0x2c2038, 0x1a1424, (fy - wall) / (H - wall));
      c = mixc(c, 0x000000, (stone - 0.5) * 0.35);
      put(im.at(x, y), c);
    }
  for (int k = 0; k < 4; k++) {
    double lx = W * (0.12 + k * 0.27);
    for (int y = (int)(H * 0.70); y < (int)wall; y++)
      for (int x = (int)(lx - 3 * sx); x < (int)(lx + 3 * sx); x++)
        if (x >= 0 && x < W) put(im.at(x, y), 0x1a1424);
    double gy = H * 0.70;
    for (int y = (int)(gy - 40 * sx); y < (int)(gy + 40 * sx); y++)
      for (int x = (int)(lx - 40 * sx); x < (int)(lx + 40 * sx); x++) {
        if (x < 0 || y < 0 || x >= W || y >= H) continue;
        double d = std::hypot(x - lx, y - gy) / sx;
        uint8_t* p = im.at(x, y);
        uint32_t c = ((uint32_t)p[0] << 16) | (p[1] << 8) | p[2];
        put(p, mixc(c, 0xffe7a8, d < 7 ? 1 : std::exp(-(d - 7) / 9) * 0.55));
      }
  }
  return im;
}

// La palmera, en una capa transparente: tronco curvo y hojas con foliolos.
Img sample_palm(int W, int H) {
  Img im(W, H);
  std::vector<float> m((size_t)W * H, 0);
  double s = H / 1000.0;
  auto disc = [&](double x, double y, double r) {
    for (int py = (int)(y - r - 1); py <= (int)(y + r + 1); py++)
      for (int px = (int)(x - r - 1); px <= (int)(x + r + 1); px++) {
        if (px < 0 || py < 0 || px >= W || py >= H) continue;
        double f = clampd(r - std::hypot(px + 0.5 - x, py + 0.5 - y) + 0.5, 0, 1);
        float& v = m[(size_t)py * W + px];
        v = std::max(v, (float)f);
      }
  };
  auto bez = [](double a, double b, double c, double t) { return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c; };
  // Tronco: de abajo a la derecha hasta la copa.
  double bx = W * 0.86, by = H * 1.02, cx = W * 0.93, cy = H * 0.62, tx_ = W * 0.80, ty = H * 0.25;
  for (int i = 0; i <= 400; i++) {
    double t = i / 400.0;
    double r = (17 - 7 * t) * s * (1 + 0.05 * std::sin(t * 70));
    disc(bez(bx, cx, tx_, t), bez(by, cy, ty, t), r);
  }
  // Hojas: arcos que caen, con foliolos a los lados.
  const double ang[] = {-170, -140, -110, -75, -40, -10, 20, 200, 160};
  const double len[] = {300, 320, 270, 250, 300, 330, 280, 240, 260};
  for (int f = 0; f < 9; f++) {
    double a = ang[f] * PI / 180, L = len[f] * s;
    double ex = tx_ + std::cos(a) * L, ey = ty + std::sin(a) * L * 0.55 + L * 0.45;
    double mx = tx_ + std::cos(a) * L * 0.55, my = ty + std::sin(a) * L * 0.55 - L * 0.12;
    double px = tx_, py = ty;
    for (int i = 1; i <= 160; i++) {
      double t = i / 160.0;
      double x = bez(tx_, mx, ex, t), y = bez(ty, my, ey, t);
      disc(x, y, (4.5 - 3.5 * t) * s);
      if (i % 4 == 0 && t > 0.08) {
        double dx = x - px, dy = y - py, dl = std::hypot(dx, dy);
        dx /= dl; dy /= dl;
        double ll = (70 - 50 * t) * s * (0.85 + 0.3 * hash2(f, i, 3));
        for (int side : {-1, 1}) {
          double nx = -dy * side, ny = dx * side;
          for (int k = 0; k <= 24; k++) {
            double u = k / 24.0;
            disc(x + (nx * 0.8 + dx * 0.5) * ll * u, y + (ny * 0.8 + dy * 0.5) * ll * u + u * u * ll * 0.45,
                 (2.2 - 1.6 * u) * s);
          }
        }
      }
      px = x; py = y;
    }
  }
  // Cocos.
  for (int k = 0; k < 3; k++) disc(tx_ - 12 * s + k * 13 * s, ty + 16 * s + (k % 2) * 6 * s, 10 * s);
  for (size_t i = 0; i < m.size(); i++) {
    if (m[i] <= 0) continue;
    uint8_t* p = &im.px[i * 4];
    p[0] = 0x16; p[1] = 0x10; p[2] = 0x1e; p[3] = u8(m[i] * 255);
  }
  return im;
}

}  // namespace ie

// ============================================================ archivos
// Abrir: PNG, JPEG, BMP, GIF, SVG… (lo que lee FLTK) y el proyecto con capas
// (.dmi). Guardar: PNG con transparencia, JPEG y BMP (codificadores propios,
// sin más bibliotecas) y .dmi.
namespace ie {

std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
std::string ext_of(const std::string& path) {
  size_t slash = path.find_last_of("/\\"), dot = path.find_last_of('.');
  if (dot == std::string::npos || (slash != std::string::npos && dot < slash)) return "";
  return lower(path.substr(dot + 1));
}
std::string base_name(const std::string& path) {
  size_t slash = path.find_last_of("/\\");
  return slash == std::string::npos ? path : path.substr(slash + 1);
}
std::string strip_ext(const std::string& name) {
  size_t dot = name.find_last_of('.');
  return dot == std::string::npos || dot == 0 ? name : name.substr(0, dot);
}

enum Format { F_PNG, F_JPEG, F_BMP, F_DMI, F_COUNT };
int format_of(const std::string& path) {
  std::string e = ext_of(path);
  if (e == "jpg" || e == "jpeg" || e == "jpe") return F_JPEG;
  if (e == "bmp") return F_BMP;
  if (e == "dmi") return F_DMI;
  if (e == "png") return F_PNG;
  return -1;
}
const char* format_ext(int f) {
  static const char* const e[] = {"png", "jpg", "bmp", "dmi"};
  return e[clampi(f, 0, F_COUNT - 1)];
}

// ------------------------------------------------------------ PNG
bool save_png(const std::string& path, const Img& im) {
  return fl_write_png(path.c_str(), im.px.data(), im.w, im.h, 4, 0) == 0;
}

// ------------------------------------------------------------ BMP (24 bits)
inline void le16(std::string& o, unsigned v) { o += (char)(v & 255); o += (char)((v >> 8) & 255); }
inline void le32(std::string& o, uint32_t v) { for (int i = 0; i < 4; i++) o += (char)((v >> (8 * i)) & 255); }

std::string bmp_bytes(const Img& src) {
  Img im = on_color(src, 0xffffff);
  int row = (im.w * 3 + 3) & ~3;
  uint32_t data = (uint32_t)row * im.h;
  std::string o;
  o += "BM";
  le32(o, 54 + data); le32(o, 0); le32(o, 54);
  le32(o, 40); le32(o, (uint32_t)im.w); le32(o, (uint32_t)im.h);
  le16(o, 1); le16(o, 24); le32(o, 0); le32(o, data);
  le32(o, 2835); le32(o, 2835); le32(o, 0); le32(o, 0);   // 72 ppp
  for (int y = im.h - 1; y >= 0; y--) {
    size_t start = o.size();
    for (int x = 0; x < im.w; x++) {
      const uint8_t* p = im.at(x, y);
      o += (char)p[2]; o += (char)p[1]; o += (char)p[0];
    }
    o.append(row - (o.size() - start), '\0');
  }
  return o;
}

bool write_file(const std::string& path, const std::string& bytes) {
  FILE* f = fl_fopen(path.c_str(), "wb");
  if (!f) return false;
  bool ok = std::fwrite(bytes.data(), 1, bytes.size(), f) == bytes.size();
  return std::fclose(f) == 0 && ok;
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  char buf[65536];
  size_t n;
  out.clear();
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  std::fclose(f);
  return true;
}

// ------------------------------------------------------------ JPEG
// Un codificador JPEG «baseline» completo: YCbCr sin submuestreo, DCT de 8×8,
// las tablas de cuantificación del estándar escaladas por la calidad y las
// tablas de Huffman del anexo K.
namespace jpeg {

const uint8_t ZZ[64] = {0,  1,  8,  16, 9,  2,  3,  10, 17, 24, 32, 25, 18, 11, 4,  5,  12, 19, 26, 33, 40, 48,
                        41, 34, 27, 20, 13, 6,  7,  14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23,
                        30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63};
const uint8_t QL[64] = {16, 11, 10, 16, 24,  40,  51,  61,  12, 12, 14, 19, 26,  58,  60,  55,
                        14, 13, 16, 24, 40,  57,  69,  56,  14, 17, 22, 29, 51,  87,  80,  62,
                        18, 22, 37, 56, 68,  109, 103, 77,  24, 35, 55, 64, 81,  104, 113, 92,
                        49, 64, 78, 87, 103, 121, 120, 101, 72, 92, 95, 98, 112, 100, 103, 99};
const uint8_t QC[64] = {17, 18, 24, 47, 99, 99, 99, 99, 18, 21, 26, 66, 99, 99, 99, 99, 24, 26, 56, 99, 99, 99,
                        99, 99, 47, 66, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
                        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99};
const uint8_t DC_L_BITS[16] = {0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0};
const uint8_t DC_C_BITS[16] = {0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0};
const uint8_t DC_VALS[12] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
const uint8_t AC_L_BITS[16] = {0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d};
const uint8_t AC_L_VALS[162] = {
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14,
    0x32, 0x81, 0x91, 0xa1, 0x08, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0, 0x24, 0x33, 0x62, 0x72, 0x82, 0x09,
    0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a,
    0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65,
    0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88,
    0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9,
    0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca,
    0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
    0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa};
const uint8_t AC_C_BITS[16] = {0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77};
const uint8_t AC_C_VALS[162] = {
    0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, 0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71, 0x13, 0x22, 0x32,
    0x81, 0x08, 0x14, 0x42, 0x91, 0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0, 0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16,
    0x24, 0x34, 0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64,
    0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86,
    0x87, 0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8,
    0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
    0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa};

struct Huff {
  uint16_t code[256] = {};
  uint8_t len[256] = {};
  Huff(const uint8_t* bits, const uint8_t* vals) {
    int k = 0;
    uint16_t c = 0;
    for (int l = 1; l <= 16; l++) {
      for (int i = 0; i < bits[l - 1]; i++, k++) {
        code[vals[k]] = c++;
        len[vals[k]] = (uint8_t)l;
      }
      c <<= 1;
    }
  }
};

struct Bits {
  std::string& o;
  uint32_t acc = 0;
  int n = 0;
  explicit Bits(std::string& out) : o(out) {}
  void put(uint32_t v, int len) {
    for (int i = len - 1; i >= 0; i--) {
      acc = (acc << 1) | ((v >> i) & 1);
      if (++n == 8) {
        o += (char)acc;
        if ((acc & 255) == 0xff) o += '\0';   // relleno tras 0xFF
        acc = 0;
        n = 0;
      }
    }
  }
  void flush() { while (n) put(1, 1); }
};

inline void marker(std::string& o, int m, int len) { o += (char)0xff; o += (char)m; o += (char)(len >> 8); o += (char)(len & 255); }

void block(Bits& b, const float in[64], const uint8_t* q, int& dc, const Huff& hdc, const Huff& hac) {
  static float cs[8][8];
  static bool init = false;
  if (!init) {
    for (int u = 0; u < 8; u++)
      for (int x = 0; x < 8; x++) cs[u][x] = (float)((u ? 0.5 : 0.5 / std::sqrt(2.0)) * std::cos((2 * x + 1) * u * PI / 16));
    init = true;
  }
  float t[64], f[64];
  for (int y = 0; y < 8; y++)
    for (int u = 0; u < 8; u++) {
      float s = 0;
      for (int x = 0; x < 8; x++) s += cs[u][x] * in[y * 8 + x];
      t[y * 8 + u] = s;
    }
  for (int u = 0; u < 8; u++)
    for (int v = 0; v < 8; v++) {
      float s = 0;
      for (int y = 0; y < 8; y++) s += cs[v][y] * t[y * 8 + u];
      f[v * 8 + u] = s;
    }
  int z[64];
  for (int k = 0; k < 64; k++) z[k] = iround(f[ZZ[k]] / q[ZZ[k]]);
  auto cat = [](int v) { int a = std::abs(v), n = 0; while (a) { n++; a >>= 1; } return n; };
  auto bits = [](int v, int n) { return (uint32_t)(v < 0 ? v + (1 << n) - 1 : v); };
  int diff = z[0] - dc;
  dc = z[0];
  int n = cat(diff);
  b.put(hdc.code[n], hdc.len[n]);
  if (n) b.put(bits(diff, n), n);
  int run = 0;
  for (int k = 1; k < 64; k++) {
    if (z[k] == 0) { run++; continue; }
    while (run > 15) { b.put(hac.code[0xf0], hac.len[0xf0]); run -= 16; }
    int c = cat(z[k]), sym = (run << 4) | c;
    b.put(hac.code[sym], hac.len[sym]);
    b.put(bits(z[k], c), c);
    run = 0;
  }
  if (run) b.put(hac.code[0], hac.len[0]);
}

std::string encode(const Img& src, int quality) {
  Img im = on_color(src, 0xffffff);
  quality = clampi(quality, 1, 100);
  int scale = quality < 50 ? 5000 / quality : 200 - quality * 2;
  uint8_t ql[64], qc[64];
  for (int i = 0; i < 64; i++) {
    ql[i] = (uint8_t)clampi((QL[i] * scale + 50) / 100, 1, 255);
    qc[i] = (uint8_t)clampi((QC[i] * scale + 50) / 100, 1, 255);
  }
  std::string o;
  o += (char)0xff; o += (char)0xd8;
  marker(o, 0xe0, 16);
  o.append("JFIF\0", 5);
  o += (char)1; o += (char)1; o += (char)0;
  o += (char)0; o += (char)1; o += (char)0; o += (char)1; o += (char)0; o += (char)0;
  marker(o, 0xdb, 2 + 65 * 2);
  o += (char)0;
  for (int k = 0; k < 64; k++) o += (char)ql[ZZ[k]];
  o += (char)1;
  for (int k = 0; k < 64; k++) o += (char)qc[ZZ[k]];
  marker(o, 0xc0, 17);
  o += (char)8;
  o += (char)(im.h >> 8); o += (char)(im.h & 255); o += (char)(im.w >> 8); o += (char)(im.w & 255);
  o += (char)3;
  for (int c = 1; c <= 3; c++) { o += (char)c; o += (char)0x11; o += (char)(c == 1 ? 0 : 1); }
  auto dht = [&](int cls_id, const uint8_t* bits, const uint8_t* vals) {
    int n = 0;
    for (int i = 0; i < 16; i++) n += bits[i];
    marker(o, 0xc4, 2 + 1 + 16 + n);
    o += (char)cls_id;
    o.append((const char*)bits, 16);
    o.append((const char*)vals, n);
  };
  dht(0x00, DC_L_BITS, DC_VALS);
  dht(0x10, AC_L_BITS, AC_L_VALS);
  dht(0x01, DC_C_BITS, DC_VALS);
  dht(0x11, AC_C_BITS, AC_C_VALS);
  marker(o, 0xda, 12);
  o += (char)3;
  o += (char)1; o += (char)0x00; o += (char)2; o += (char)0x11; o += (char)3; o += (char)0x11;
  o += (char)0; o += (char)63; o += (char)0;
  static const Huff hdl(DC_L_BITS, DC_VALS), hal(AC_L_BITS, AC_L_VALS), hdc(DC_C_BITS, DC_VALS), hac(AC_C_BITS, AC_C_VALS);
  Bits b(o);
  int dy = 0, du = 0, dv = 0;
  float Y[64], U[64], V[64];
  for (int by = 0; by < im.h; by += 8)
    for (int bx = 0; bx < im.w; bx += 8) {
      for (int j = 0; j < 8; j++)
        for (int i = 0; i < 8; i++) {
          const uint8_t* p = im.at(std::min(bx + i, im.w - 1), std::min(by + j, im.h - 1));
          float r = p[0], g = p[1], bl = p[2];
          Y[j * 8 + i] = 0.299f * r + 0.587f * g + 0.114f * bl - 128;
          U[j * 8 + i] = -0.168736f * r - 0.331264f * g + 0.5f * bl;
          V[j * 8 + i] = 0.5f * r - 0.418688f * g - 0.081312f * bl;
        }
      block(b, Y, ql, dy, hdl, hal);
      block(b, U, qc, du, hdc, hac);
      block(b, V, qc, dv, hdc, hac);
    }
  b.flush();
  o += (char)0xff; o += (char)0xd9;
  return o;
}

}  // namespace jpeg

// ------------------------------------------------------------ el proyecto (.dmi)
// «DMI1», el lienzo y la capa activa; luego cada capa: nombre, posición,
// tamaño, visible, modo, opacidad (en milésimas) y los píxeles comprimidos
// por tramos (un byte n: n < 128, n+1 píxeles tal cual; si no, el siguiente
// píxel repetido n-126 veces).
inline uint32_t rd32(const std::string& s, size_t& i) {
  if (i + 4 > s.size()) throw 1;
  uint32_t v = 0;
  for (int k = 0; k < 4; k++) v |= (uint32_t)(uint8_t)s[i + k] << (8 * k);
  i += 4;
  return v;
}

std::string dmi_bytes(const Doc& d) {
  std::string o = "DMI1";
  le32(o, (uint32_t)d.w); le32(o, (uint32_t)d.h); le32(o, (uint32_t)d.layers.size()); le32(o, (uint32_t)d.active);
  for (const Layer& L : d.layers) {
    le32(o, (uint32_t)L.name.size());
    o += L.name;
    le32(o, (uint32_t)L.x); le32(o, (uint32_t)L.y); le32(o, (uint32_t)L.img->w); le32(o, (uint32_t)L.img->h);
    o += (char)(L.visible ? 1 : 0);
    o += (char)L.blend;
    le32(o, (uint32_t)iround(L.opacity * 1000));
    const uint32_t* p = reinterpret_cast<const uint32_t*>(L.img->px.data());
    size_t n = (size_t)L.img->w * L.img->h, i = 0;
    auto px = [&](size_t k) { o.append(reinterpret_cast<const char*>(p + k), 4); };
    while (i < n) {
      size_t run = 1;
      while (i + run < n && run < 129 && p[i + run] == p[i]) run++;
      if (run >= 2) {
        o += (char)(126 + run);
        px(i);
        i += run;
        continue;
      }
      size_t lit = 1;
      while (i + lit < n && lit < 128 && !(i + lit + 1 < n && p[i + lit] == p[i + lit + 1])) lit++;
      o += (char)(lit - 1);
      for (size_t k = 0; k < lit; k++) px(i + k);
      i += lit;
    }
  }
  return o;
}

bool dmi_parse(const std::string& s, Doc& d) {
  try {
    if (s.compare(0, 4, "DMI1") != 0) return false;
    size_t i = 4;
    Doc r;
    r.w = (int)rd32(s, i); r.h = (int)rd32(s, i);
    uint32_t n = rd32(s, i);
    r.active = (int)rd32(s, i);
    if (r.w <= 0 || r.h <= 0 || r.w > 30000 || r.h > 30000 || n == 0 || n > 500) return false;
    for (uint32_t k = 0; k < n; k++) {
      Layer L;
      uint32_t nl = rd32(s, i);
      if (nl > 1000 || i + nl > s.size()) return false;
      L.name = s.substr(i, nl);
      i += nl;
      L.x = (int)rd32(s, i); L.y = (int)rd32(s, i);
      int w = (int)rd32(s, i), h = (int)rd32(s, i);
      if (w <= 0 || h <= 0 || w > 30000 || h > 30000 || i + 6 > s.size()) return false;
      L.visible = s[i++] != 0;
      L.blend = clampi((uint8_t)s[i++], 0, B_COUNT - 1);
      L.opacity = clampd(rd32(s, i) / 1000.0, 0, 1);
      L.img = std::make_shared<Img>(w, h);
      uint8_t* out = L.img->px.data();
      size_t total = (size_t)w * h, j = 0;
      while (j < total) {
        if (i >= s.size()) return false;
        int c = (uint8_t)s[i++];
        size_t cnt = c < 128 ? (size_t)c + 1 : (size_t)c - 126;
        if (j + cnt > total) return false;
        if (c < 128) {
          if (i + cnt * 4 > s.size()) return false;
          std::memcpy(out + j * 4, s.data() + i, cnt * 4);
          i += cnt * 4;
        } else {
          if (i + 4 > s.size()) return false;
          for (size_t q = 0; q < cnt; q++) std::memcpy(out + (j + q) * 4, s.data() + i, 4);
          i += 4;
        }
        j += cnt;
      }
      r.layers.push_back(std::move(L));
    }
    r.active = clampi(r.active, 0, (int)r.layers.size() - 1);
    d = std::move(r);
    return true;
  } catch (int) {
    return false;
  }
}

// ------------------------------------------------------------ abrir y guardar
// Una imagen de FLTK (RGB, gris, con o sin alfa, o un mapa de colores) a RGBA.
bool from_fl(const Fl_Image* src, Img& out) {
  if (!src || src->w() <= 0 || src->h() <= 0) return false;
  std::unique_ptr<Fl_RGB_Image> tmp;
  const Fl_RGB_Image* rgb = dynamic_cast<const Fl_RGB_Image*>(src);
  if (!rgb) {
    if (auto* pm = dynamic_cast<const Fl_Pixmap*>(src)) {
      tmp.reset(new Fl_RGB_Image(pm));
      rgb = tmp.get();
    }
  }
  if (!rgb || rgb->d() < 1 || !rgb->data() || !rgb->data()[0]) return false;
  int w = rgb->data_w(), h = rgb->data_h(), d = rgb->d(), ld = rgb->ld() ? rgb->ld() : w * d;
  const uchar* data = (const uchar*)rgb->data()[0];
  out = Img(w, h);
  for (int y = 0; y < h; y++)
    for (int x = 0; x < w; x++) {
      const uchar* p = data + (size_t)y * ld + (size_t)x * d;
      uint8_t* q = out.at(x, y);
      if (d >= 3) { q[0] = p[0]; q[1] = p[1]; q[2] = p[2]; q[3] = d == 4 ? p[3] : 255; }
      else { q[0] = q[1] = q[2] = p[0]; q[3] = d == 2 ? p[1] : 255; }
    }
  return true;
}

// Abrir: un .dmi (con sus capas) o una imagen (una capa «Fondo»).
bool open_doc(const std::string& path, Doc& d, std::string& err) {
  if (format_of(path) == F_DMI) {
    std::string bytes;
    if (!read_file(path, bytes)) { err = tx::ERR_READ; return false; }
    if (!dmi_parse(bytes, d)) { err = tx::ERR_FORMAT; return false; }
    return true;
  }
  Fl_Shared_Image* sh = Fl_Shared_Image::get(path.c_str());
  if (!sh) { err = tx::ERR_FORMAT; return false; }
  Img im;
  bool ok = from_fl(sh->image() ? sh->image() : sh, im);
  sh->release();
  if (!ok) { err = tx::ERR_FORMAT; return false; }
  Doc r;
  r.w = im.w;
  r.h = im.h;
  Layer L;
  L.name = tx::BACKGROUND;
  L.img = std::make_shared<Img>(std::move(im));
  r.layers.push_back(L);
  d = std::move(r);
  return true;
}

bool save_doc(const std::string& path, const Doc& d, int quality, std::string& err) {
  int f = format_of(path);
  bool ok;
  if (f == F_DMI) ok = write_file(path, dmi_bytes(d));
  else if (f == F_JPEG) ok = write_file(path, jpeg::encode(flatten(d), quality));
  else if (f == F_BMP) ok = write_file(path, bmp_bytes(flatten(d)));
  else ok = save_png(path, flatten(d));
  if (!ok) err = tx::ERR_WRITE;
  return ok;
}

}  // namespace ie

// ============================================================ el editor
// Toda la interfaz (herramientas, opciones, el lienzo, los paneles Color,
// Capas e Historial, los cuadros de diálogo y la barra de estado) es un solo
// widget que se dibuja en código. Cada vez que se dibuja apunta las zonas
// que responden al ratón (hots): así los controles son una línea cada uno.
namespace ie {

const uint32_t C_BG = 0x1e1e1e, C_WORK = 0x282828, C_PANEL = 0x323232, C_HEAD = 0x292929, C_LINE = 0x161616,
               C_LINE2 = 0x444444, C_TEXT = 0xdedede, C_DIM = 0x959595, C_ACCENT = 0x2f80ed, C_HOVER = 0x3d3d3d,
               C_SELROW = 0x2f4b6e, C_FIELD = 0x1c1c1c, C_ERR = 0xc8402f;

inline Fl_Color rgb(uint32_t v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void col(uint32_t v) { fl_color(rgb(v)); }
inline void fill(Rect r, uint32_t c) { col(c); fl_rectf(r.x, r.y, r.w, r.h); }
inline void frame(Rect r, uint32_t c) { col(c); fl_rect(r.x, r.y, r.w, r.h); }
inline void rbox(Rect r, uint32_t c) { fl_draw_box(FL_RFLAT_BOX, r.x, r.y, r.w, r.h, rgb(c)); }
std::string hex(uint32_t c) {
  char b[16];
  std::snprintf(b, sizeof b, "#%06X", c & 0xffffff);
  return b;
}

inline void ui_font(int size = 12, bool bold = false) { fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size); }
// Texto centrado en vertical en la fila r, alineado a la izquierda, al centro o a la derecha.
void text_in(const std::string& s, Rect r, uint32_t c, int align = -1, int size = 12, bool bold = false) {
  ui_font(size, bold);
  col(c);
  int tw = (int)fl_width(s.c_str());
  int x = align < 0 ? r.x : align == 0 ? r.x + (r.w - tw) / 2 : r.r() - tw;
  fl_draw(s.c_str(), x, r.y + (r.h + fl_height()) / 2 - fl_descent());
}
// Recorta el texto con «…» para que quepa en w puntos.
std::string fit(const std::string& s, int w) {
  if (fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty()) {
    do t.pop_back(); while (!t.empty() && ((uint8_t)t.back() & 0xc0) == 0x80);
    if (!t.empty()) t.pop_back();
    std::string u = t + "…";
    if (fl_width(u.c_str()) <= w) return u;
  }
  return "…";
}
// «Tamaño de imagen…» → «Tamaño de imagen» (para el historial).
std::string no_dots(std::string s) {
  if (s.size() >= 3 && s.compare(s.size() - 3, 3, "…") == 0) s.resize(s.size() - 3);
  return s;
}
void pop_utf8(std::string& s) {
  while (!s.empty() && ((uint8_t)s.back() & 0xc0) == 0x80) s.pop_back();
  if (!s.empty()) s.pop_back();
}

inline void rgb_hsv(uint32_t c, double& h, double& s, double& v) {
  double r = ((c >> 16) & 255) / 255.0, g = ((c >> 8) & 255) / 255.0, b = (c & 255) / 255.0;
  double mx = std::max({r, g, b}), mn = std::min({r, g, b}), d = mx - mn;
  v = mx;
  s = mx > 0 ? d / mx : 0;
  if (d <= 0) return;   // gris: el tono se queda como estaba
  if (mx == r) h = std::fmod((g - b) / d + 6, 6.0);
  else if (mx == g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  h *= 60;
}
inline uint32_t hsv_rgb(double h, double s, double v) {
  h = std::fmod(h, 360.0);
  if (h < 0) h += 360;
  double c = v * s, x = c * (1 - std::fabs(std::fmod(h / 60, 2.0) - 1)), m = v - c, r = 0, g = 0, b = 0;
  if (h < 60) { r = c; g = x; } else if (h < 120) { r = x; g = c; } else if (h < 180) { g = c; b = x; }
  else if (h < 240) { g = x; b = c; } else if (h < 300) { r = x; b = c; } else { r = c; b = x; }
  return ((uint32_t)u8((r + m) * 255) << 16) | ((uint32_t)u8((g + m) * 255) << 8) | u8((b + m) * 255);
}

enum Tool { T_MOVE, T_MARQUEE, T_CROP, T_BRUSH, T_ERASER, T_FILL, T_GRADIENT, T_SHAPE, T_TEXT, T_PICKER, T_HAND, T_ZOOM, T_COUNT };
const char TOOL_KEYS[T_COUNT] = {'v', 'm', 'c', 'b', 'e', 'g', 'r', 'u', 't', 'i', 'h', 'z'};
const char* tool_name(int t) {
  static const char* const n[] = {tx::T_MOVE, tx::T_MARQUEE, tx::T_CROP, tx::T_BRUSH, tx::T_ERASER, tx::T_FILL,
                                  tx::T_GRADIENT, tx::T_SHAPE, tx::T_TEXT, tx::T_PICKER, tx::T_HAND, tx::T_ZOOM};
  return n[t];
}
const char* tool_hint(int t) {
  static const char* const n[] = {tx::H_MOVE, tx::H_MARQUEE, tx::H_CROP, tx::H_BRUSH, tx::H_ERASER, tx::H_FILL,
                                  tx::H_GRADIENT, tx::H_SHAPE, tx::H_TEXT, tx::H_PICKER, tx::H_HAND, tx::H_ZOOM};
  return n[t];
}

enum Cmd {
  C_NEW, C_OPEN, C_PLACE, C_SAVE, C_SAVE_AS, C_SAMPLE, C_UNDO, C_REDO, C_CUT, C_COPY, C_PASTE, C_CLEAR, C_FILL,
  C_SELECT_ALL, C_DESELECT, C_IMAGE_SIZE, C_CANVAS_SIZE, C_CROP_SEL, C_ROT_CW, C_ROT_CCW, C_ROT_180, C_ROT_ANY,
  C_FLIP_H, C_FLIP_V, C_BRIGHT, C_HUESAT, C_LEVELS, C_GRAY, C_SEPIA, C_INVERT, C_THRESHOLD, C_POSTERIZE, C_BLUR,
  C_SHARPEN, C_NOISE, C_PIXELATE, C_EDGES, C_EMBOSS, C_VIGNETTE, C_LAYER_NEW, C_LAYER_DUP, C_LAYER_DEL, C_LAYER_UP,
  C_LAYER_DOWN, C_MERGE, C_FLATTEN, C_LAYER_PROPS, C_ZOOM_IN, C_ZOOM_OUT, C_FIT, C_ACTUAL, C_GRID
};

// ------------------------------------------------------------ los iconos
void line_w(int w) { fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, w); }
void tool_icon(int t, int cx, int cy, uint32_t c) {
  col(c);
  line_w(2);
  switch (t) {
    case T_MOVE:
      fl_line(cx - 8, cy, cx + 8, cy);
      fl_line(cx, cy - 8, cx, cy + 8);
      fl_polygon(cx - 9, cy, cx - 5, cy - 3, cx - 5, cy + 3);
      fl_polygon(cx + 9, cy, cx + 5, cy - 3, cx + 5, cy + 3);
      fl_polygon(cx, cy - 9, cx - 3, cy - 5, cx + 3, cy - 5);
      fl_polygon(cx, cy + 9, cx - 3, cy + 5, cx + 3, cy + 5);
      break;
    case T_MARQUEE:
      line_w(1);
      for (int i = -8; i < 8; i += 4) {
        fl_line(cx + i, cy - 6, cx + i + 2, cy - 6);
        fl_line(cx + i, cy + 6, cx + i + 2, cy + 6);
      }
      for (int i = -6; i < 6; i += 4) {
        fl_line(cx - 8, cy + i, cx - 8, cy + i + 2);
        fl_line(cx + 8, cy + i, cx + 8, cy + i + 2);
      }
      break;
    case T_CROP:
      fl_line(cx - 5, cy - 9, cx - 5, cy + 5, cx + 9, cy + 5);
      fl_line(cx - 9, cy - 5, cx + 5, cy - 5, cx + 5, cy + 9);
      break;
    case T_BRUSH:
      line_w(3);
      fl_line(cx + 7, cy - 8, cx - 1, cy + 1);
      line_w(1);
      fl_pie(cx - 8, cy + 1, 9, 9, 0, 360);
      break;
    case T_ERASER:
      fl_loop(cx - 9, cy + 3, cx, cy - 6, cx + 8, cy + 2, cx - 1, cy + 11);
      fl_polygon(cx - 9, cy + 3, cx - 4, cy - 2, cx + 4, cy + 6, cx - 1, cy + 11);
      break;
    case T_FILL:
      fl_loop(cx - 7, cy, cx, cy - 7, cx + 7, cy, cx, cy + 7);
      line_w(1);
      fl_polygon(cx - 7, cy, cx + 7, cy, cx, cy + 7);
      fl_pie(cx + 6, cy + 2, 6, 8, 0, 360);
      break;
    case T_GRADIENT:
      line_w(1);
      for (int i = 0; i < 18; i++) {
        col(mixc(c, 0x202020, i / 17.0));
        fl_line(cx - 9 + i, cy - 6, cx - 9 + i, cy + 6);
      }
      frame({cx - 9, cy - 6, 18, 13}, c);
      break;
    case T_SHAPE:
      line_w(1);
      frame({cx - 9, cy - 7, 11, 11}, c);
      fl_pie(cx - 3, cy - 2, 12, 12, 0, 360);
      break;
    case T_TEXT:
      line_w(3);
      fl_line(cx - 7, cy - 7, cx + 7, cy - 7);
      fl_line(cx, cy - 7, cx, cy + 8);
      break;
    case T_PICKER:
      line_w(3);
      fl_line(cx - 7, cy + 7, cx + 2, cy - 2);
      line_w(1);
      fl_pie(cx + 1, cy - 9, 9, 9, 0, 360);
      break;
    case T_HAND:
      line_w(1);
      fl_pie(cx - 6, cy - 2, 12, 11, 0, 360);
      fl_rectf(cx - 6, cy + 2, 12, 6);
      line_w(2);
      for (int i = 0; i < 4; i++) fl_line(cx - 5 + i * 3 + 1, cy - 1, cx - 5 + i * 3 + 1, cy - 7 + (i == 0 || i == 3 ? 2 : 0));
      fl_line(cx - 7, cy + 1, cx - 9, cy - 2);
      break;
    case T_ZOOM:
      fl_arc(cx - 9, cy - 9, 13, 13, 0, 360);
      line_w(3);
      fl_line(cx + 2, cy + 2, cx + 8, cy + 8);
      break;
  }
  fl_line_style(0);
}

enum Icon { I_NEW, I_DUP, I_UP, I_DOWN, I_MERGE, I_DEL, I_EYE, I_SWAP, I_PROPS };
void icon(int k, int cx, int cy, uint32_t c) {
  col(c);
  line_w(2);
  switch (k) {
    case I_NEW: fl_line(cx - 6, cy, cx + 6, cy); fl_line(cx, cy - 6, cx, cy + 6); break;
    case I_DUP:
      line_w(1);
      frame({cx - 6, cy - 6, 9, 9}, c);
      fl_rectf(cx - 2, cy - 2, 9, 9);
      break;
    case I_UP: fl_line(cx, cy + 6, cx, cy - 5); fl_line(cx - 5, cy, cx, cy - 6, cx + 5, cy); break;
    case I_DOWN: fl_line(cx, cy - 6, cx, cy + 5); fl_line(cx - 5, cy, cx, cy + 6, cx + 5, cy); break;
    case I_MERGE:
      fl_line(cx, cy - 7, cx, cy + 2); fl_line(cx - 4, cy - 2, cx, cy + 2, cx + 4, cy - 2);
      fl_line(cx - 6, cy + 6, cx + 6, cy + 6);
      break;
    case I_DEL:
      line_w(1);
      fl_line(cx - 6, cy - 5, cx + 6, cy - 5);
      fl_line(cx - 2, cy - 7, cx + 2, cy - 7);
      fl_loop(cx - 5, cy - 4, cx + 5, cy - 4, cx + 4, cy + 7, cx - 4, cy + 7);
      fl_line(cx - 2, cy - 2, cx - 2, cy + 5); fl_line(cx + 2, cy - 2, cx + 2, cy + 5);
      break;
    case I_EYE:
      line_w(1);
      fl_arc(cx - 8, cy - 5, 16, 10, 0, 360);
      fl_pie(cx - 3, cy - 3, 6, 6, 0, 360);
      break;
    case I_SWAP:
      line_w(1);
      fl_line(cx - 5, cy - 3, cx + 3, cy - 3); fl_line(cx + 1, cy - 5, cx + 3, cy - 3, cx + 1, cy - 1);
      fl_line(cx + 5, cy + 3, cx - 3, cy + 3); fl_line(cx - 1, cy + 1, cx - 3, cy + 3, cx - 1, cy + 5);
      break;
    case I_PROPS:
      line_w(1);
      for (int i = -4; i <= 4; i += 4) fl_line(cx - 6, cy + i, cx + 6, cy + i);
      break;
  }
  fl_line_style(0);
}

// ------------------------------------------------------------ cuadros de diálogo
struct Field {
  enum Kind { SLIDER, NUMBER, CHECK, CHOICE, TEXT, HISTO, ANCHOR, INFO } kind = INFO;
  std::string label, unit, s;
  double v = 0, lo = 0, hi = 1;
  int dec = 0;
  bool logs = false;
  std::vector<std::string> opts;
};
Field f_slider(const std::string& l, double v, double lo, double hi, int dec = 0, const std::string& unit = "", bool logs = false) {
  Field f; f.kind = Field::SLIDER; f.label = l; f.v = v; f.lo = lo; f.hi = hi; f.dec = dec; f.unit = unit; f.logs = logs;
  return f;
}
Field f_number(const std::string& l, double v, double lo, double hi, const std::string& unit = "") {
  Field f; f.kind = Field::NUMBER; f.label = l; f.v = v; f.lo = lo; f.hi = hi; f.unit = unit; f.s = std::to_string((int)v);
  return f;
}
Field f_check(const std::string& l, bool on) { Field f; f.kind = Field::CHECK; f.label = l; f.v = on; return f; }
Field f_choice(const std::string& l, std::vector<std::string> o, int i) {
  Field f; f.kind = Field::CHOICE; f.label = l; f.opts = std::move(o); f.v = i;
  return f;
}
Field f_text(const std::string& l, const std::string& s) { Field f; f.kind = Field::TEXT; f.label = l; f.s = s; return f; }
Field f_histo() { Field f; f.kind = Field::HISTO; return f; }
Field f_anchor(const std::string& l, int i) { Field f; f.kind = Field::ANCHOR; f.label = l; f.v = i; return f; }
Field f_info(const std::string& s) { Field f; f.kind = Field::INFO; f.s = s; return f; }

struct Dialog {
  std::string title, ok_label;
  std::vector<Field> f;
  int focus = -1, w = 470;
  std::vector<int> histo;
  std::function<void(int)> change;
  std::function<bool()> ok;
  std::function<void()> cancel;
};

struct Hot {
  Rect r;
  std::function<void(int, int, int)> fn;
};

struct Lay {
  Rect all, opts, tools, tabs, canvas, right, status, color, layers, history;
};

class Editor : public Fl_Widget {
public:
  // ---- el documento
  Doc doc, base;           // base: el documento antes del diálogo abierto
  History hist;
  std::string path, name;
  bool dirty = false;
  int untitled = 0;
  Img comp;                // las capas fusionadas
  Rect comp_dirty;
  std::function<void()> on_state;   // el título y el menú
  std::function<void()> on_quit;
  bool shooting = false;

  // ---- la vista
  double zoom = 1, cx = 0, cy = 0;
  bool need_fit = true, grid = false;
  Lay L;
  std::vector<uint8_t> disp;
  std::unique_ptr<Fl_RGB_Image> dimg;
  int dw = 0, dh = 0;
  double dscale = 1;
  Rect disp_canvas;
  bool view_dirty = true;
  Rect disp_part;          // lo que cambió del documento (sin mover la vista)

  // ---- herramientas y colores
  int tool = T_BRUSH;
  uint32_t fg = 0x1d2350, bg = 0xffffff;
  bool edit_bg = false;
  double ph = 0, ps = 0, pv = 0;   // el color que se edita, en HSV
  double size_[T_COUNT], hard_[T_COUNT], op_[T_COUNT];   // px, %, %
  double fill_tol = 32;
  bool fill_contig = true;
  int grad_kind = 0, shape_kind = 0, crop_ratio = 0, pick_all = 1;
  int text_font = 0;
  bool text_bold = true;
  double text_size = 96;

  // ---- interacción
  std::vector<Hot> hots;
  std::function<void(int, int, int)> capture;
  int hover_x = -10000, hover_y = -10000;
  bool space = false;
  Stroke stroke;
  bool stroking = false, has_last = false;
  double last_x = 0, last_y = 0;      // el final de la última pincelada (Mayús: línea recta)
  double ax = 0, ay = 0, bx = 0, by = 0;
  bool dragging = false;
  int drag_mode = 0, start_lx = 0, start_ly = 0;
  Rect start_rect;
  bool crop_on = false;
  Rect crop;
  int layer_scroll = 0, hist_scroll = 0;
  std::unique_ptr<Dialog> dlg;
  std::string toast;
  bool toast_err = false;
  double toast_t = 0;
  int ants = 0;
  Img clip;
  bool has_clip = false;
  int last_cursor = -1;

  Editor(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {
    for (int t = 0; t < T_COUNT; t++) { size_[t] = 30; hard_[t] = 80; op_[t] = 100; }
    size_[T_ERASER] = 60; hard_[T_ERASER] = 50;
    sync_picker();
  }

  // ================================================== el documento
  void set_doc(Doc d, const std::string& nm, const std::string& p, const std::string& step) {
    doc = std::move(d);
    doc.active = clampi(doc.active, 0, (int)doc.layers.size() - 1);
    name = nm;
    path = p;
    hist.reset(doc, step);
    dirty = false;
    crop_on = false;
    stroking = false;
    has_last = false;
    dlg.reset();
    need_fit = true;
    layer_scroll = hist_scroll = 0;
    touch_all();
    notify();
  }

  void open_sample() {
    Doc d;
    d.w = 1600;
    d.h = 1000;
    Layer bgl;
    bgl.name = tx::BACKGROUND;
    bgl.img = std::make_shared<Img>(sample_scene(d.w, d.h));
    d.layers.push_back(bgl);
    Layer palm;
    palm.name = tx::SAMPLE_PALM;
    palm.img = std::make_shared<Img>(sample_palm(d.w, d.h));
    d.layers.push_back(palm);
    if (fl_display_ready()) {
      Layer t;
      t.name = tx::SAMPLE_TEXT;
      t.img = std::make_shared<Img>(render_text(tx::SAMPLE_TEXT, FL_HELVETICA_BOLD, 120, 0xfff4e0));
      t.x = 90;
      t.y = 70;
      t.opacity = 0.9;
      t.blend = B_NORMAL;
      d.layers.push_back(t);
    }
    d.active = 1;
    set_doc(d, tx::SAMPLE_NAME, "", tx::S_SAMPLE);
  }

  static bool fl_display_ready() { return Fl::screen_count() > 0; }

  void notify() {
    if (on_state) on_state();
  }

  void touch(Rect r) {
    comp_dirty = unite(comp_dirty, r);
    disp_part = unite(disp_part, r);
    redraw();
  }
  void touch_all() {
    comp_dirty = doc.canvas();
    view_dirty = true;
    redraw();
  }

  // Un paso del historial con el documento tal como está.
  void commit(const std::string& label) {
    hist.push(doc, label);
    dirty = true;
    notify();
    redraw();
  }

  void undo() {
    if (!hist.can_undo()) return;
    hist.cur--;
    restore();
  }
  void redo() {
    if (!hist.can_redo()) return;
    hist.cur++;
    restore();
  }
  void go_step(int i) {
    if (i < 0 || i >= (int)hist.steps.size() || i == hist.cur) return;
    hist.cur = i;
    restore();
  }
  void restore() {
    bool resized = doc.w != hist.steps[hist.cur].doc.w || doc.h != hist.steps[hist.cur].doc.h;
    doc = hist.steps[hist.cur].doc;
    crop_on = false;
    has_last = false;
    if (resized) need_fit = true;
    dirty = true;
    touch_all();
    notify();
  }

  void say(const std::string& s, bool err = false) {
    toast = s;
    toast_err = err;
    toast_t = 3.2;
    redraw();
  }

  // ¿Se puede pintar en la capa activa? (no si está oculta)
  bool paintable() {
    if (!doc.cur().visible) {
      say(tx::MSG_HIDDEN, true);
      return false;
    }
    return true;
  }

  // ================================================== la vista
  void layout_rects(int X, int Y, int W, int H) {
    const int OB = 40, TW = 46, RW = 290, SB = 24, TB = 28;
    L.all = {X, Y, W, H};
    L.opts = {X, Y, W, OB};
    L.status = {X, Y + H - SB, W, SB};
    int top = Y + OB, bot = Y + H - SB;
    L.tools = {X, top, TW, bot - top};
    L.right = {X + W - RW, top, RW, bot - top};
    L.tabs = {X + TW, top, W - TW - RW, TB};
    L.canvas = {X + TW, top + TB, W - TW - RW, bot - top - TB};
    L.color = {L.right.x, top, RW, 200};
    int hh = std::min(180, std::max(100, (bot - top - 200) / 3));
    L.history = {L.right.x, bot - hh, RW, hh};
    L.layers = {L.right.x, top + 200, RW, bot - hh - top - 200};
  }

  double dev() const {
    if (shooting) return 1;
    double s = 1;
    if (window()) s = Fl::screen_scale(window()->screen_num());
#ifdef __APPLE__
    s *= 2;
#endif
    return s;
  }

  double sx_of(double dx) const { return L.canvas.x + L.canvas.w / 2.0 + (dx - cx) * zoom; }
  double sy_of(double dy) const { return L.canvas.y + L.canvas.h / 2.0 + (dy - cy) * zoom; }
  double dx_of(double sx) const { return cx + (sx - L.canvas.x - L.canvas.w / 2.0) / zoom; }
  double dy_of(double sy) const { return cy + (sy - L.canvas.y - L.canvas.h / 2.0) / zoom; }

  void fit_view() {
    if (doc.w <= 0 || L.canvas.empty()) return;
    zoom = std::min((L.canvas.w - 48.0) / doc.w, (L.canvas.h - 48.0) / doc.h);
    zoom = clampd(zoom, 1 / 64.0, 64);
    cx = doc.w / 2.0;
    cy = doc.h / 2.0;
    view_dirty = true;
    redraw();
  }

  void set_zoom(double z, double sx, double sy) {
    z = clampd(z, 1 / 64.0, 64);
    double px = dx_of(sx), py = dy_of(sy);
    zoom = z;
    cx = px - (sx - L.canvas.x - L.canvas.w / 2.0) / zoom;
    cy = py - (sy - L.canvas.y - L.canvas.h / 2.0) / zoom;
    clamp_pan();
    view_dirty = true;
    redraw();
  }
  void clamp_pan() {
    cx = clampd(cx, 0, doc.w);
    cy = clampd(cy, 0, doc.h);
  }
  static double zoom_step(double z, bool in) {
    static const double lv[] = {1 / 32.0, 1 / 24.0, 1 / 16.0, 1 / 12.0, 1 / 8.0, 1 / 6.0, 0.25, 1 / 3.0, 0.5, 2 / 3.0,
                                1, 1.5, 2, 3, 4, 5, 6, 8, 12, 16, 24, 32, 48, 64};
    if (in) {
      for (double v : lv) if (v > z * 1.01) return v;
      return 64;
    }
    for (int i = (int)(sizeof lv / sizeof lv[0]) - 1; i >= 0; i--) if (lv[i] < z / 1.01) return lv[i];
    return 1 / 32.0;
  }
  void zoom_center(bool in) {
    set_zoom(zoom_step(zoom, in), L.canvas.x + L.canvas.w / 2.0, L.canvas.y + L.canvas.h / 2.0);
  }

  void update_comp() {
    if (comp.w != doc.w || comp.h != doc.h) comp_dirty = doc.canvas();
    if (comp_dirty.empty()) return;
    composite(doc, comp, comp_dirty);
    comp_dirty = {};
  }

  // La imagen del lienzo, en píxeles del dispositivo (el doble en Retina):
  // las capas fusionadas sobre el damero, el resto del área de trabajo gris.
  void build_display() {
    update_comp();
    const Rect c = L.canvas;
    double d = dev();
    int nw = std::max(1, (int)std::ceil(c.w * d)), nh = std::max(1, (int)std::ceil(c.h * d));
    bool full = view_dirty || nw != dw || nh != dh || d != dscale || c != disp_canvas || !dimg;
    if (!full && disp_part.empty()) return;
    int i0 = 0, i1 = nw, j0 = 0, j1 = nh;
    if (!full) {
      i0 = clampi((int)std::floor((sx_of(disp_part.x) - c.x) * d) - 2, 0, nw);
      i1 = clampi((int)std::ceil((sx_of(disp_part.r()) - c.x) * d) + 2, 0, nw);
      j0 = clampi((int)std::floor((sy_of(disp_part.y) - c.y) * d) - 2, 0, nh);
      j1 = clampi((int)std::ceil((sy_of(disp_part.b()) - c.y) * d) + 2, 0, nh);
    } else {
      dw = nw; dh = nh; dscale = d; disp_canvas = c;
      disp.assign((size_t)dw * dh * 3, 0);
    }
    disp_part = {};
    view_dirty = false;
    double z = zoom * d;
    int n = z >= 1 ? 1 : std::min(3, (int)std::ceil(1 / z - 1e-9));
    std::vector<int> xi((size_t)(i1 - i0) * n), yi((size_t)(j1 - j0) * n);
    for (int i = i0; i < i1; i++)
      for (int k = 0; k < n; k++) {
        double v = std::floor(cx + ((i + (k + 0.5) / n) / d - c.w / 2.0) / zoom);
        xi[(size_t)(i - i0) * n + k] = v >= 0 && v < doc.w ? (int)v : -1;
      }
    for (int j = j0; j < j1; j++)
      for (int k = 0; k < n; k++) {
        double v = std::floor(cy + ((j + (k + 0.5) / n) / d - c.h / 2.0) / zoom);
        yi[(size_t)(j - j0) * n + k] = v >= 0 && v < doc.h ? (int)v : -1;
      }
    const int cs = std::max(1, iround(8 * d));
    const uint8_t work = 0x28;
    for (int j = j0; j < j1; j++) {
      uint8_t* o = &disp[((size_t)j * dw + i0) * 3];
      const int* yr = &yi[(size_t)(j - j0) * n];
      for (int i = i0; i < i1; i++, o += 3) {
        const int* xr = &xi[(size_t)(i - i0) * n];
        int r = 0, g = 0, b = 0, a = 0, cnt = 0;
        for (int ky = 0; ky < n; ky++) {
          if (yr[ky] < 0) continue;
          for (int kx = 0; kx < n; kx++) {
            if (xr[kx] < 0) continue;
            const uint8_t* p = comp.at(xr[kx], yr[ky]);
            r += p[0] * p[3]; g += p[1] * p[3]; b += p[2] * p[3]; a += p[3];
            cnt++;
          }
        }
        if (!cnt) { o[0] = o[1] = o[2] = work; continue; }
        int ck = ((i / cs + j / cs) & 1) ? 204 : 255;
        double al = a / (cnt * 255.0);
        double f = 1;
        if (crop_on && !crop.empty()) {
          int mx = xr[n / 2], my = yr[n / 2];
          if (!crop.has(mx, my)) f = 0.38;
        }
        if (a > 0) {
          o[0] = u8((r / (double)a * al + ck * (1 - al)) * f);
          o[1] = u8((g / (double)a * al + ck * (1 - al)) * f);
          o[2] = u8((b / (double)a * al + ck * (1 - al)) * f);
        } else {
          o[0] = o[1] = o[2] = u8(ck * f);
        }
      }
    }
    // La cuadrícula de píxeles, con mucho zoom.
    if (grid && zoom >= 6) {
      for (int j = j0; j < j1; j++) {
        bool row = j > 0 && yi[(size_t)(j - j0) * n] >= 0 &&
                   std::floor(cy + ((j + 0.5) / d - c.h / 2.0) / zoom) != std::floor(cy + ((j - 0.5) / d - c.h / 2.0) / zoom);
        uint8_t* o = &disp[((size_t)j * dw + i0) * 3];
        for (int i = i0; i < i1; i++, o += 3) {
          if (xi[(size_t)(i - i0) * n] < 0 || yi[(size_t)(j - j0) * n] < 0) continue;
          bool colb = i > 0 && std::floor(cx + ((i + 0.5) / d - c.w / 2.0) / zoom) != std::floor(cx + ((i - 0.5) / d - c.w / 2.0) / zoom);
          if (row || colb)
            for (int k = 0; k < 3; k++) o[k] = (uint8_t)((o[k] * 3 + 0x80) / 4);
        }
      }
    }
    if (full || !dimg) {
      dimg.reset(new Fl_RGB_Image(disp.data(), dw, dh, 3));
      dimg->scale(c.w, c.h, 0, 1);
    } else {
      dimg->uncache();
    }
  }

  // Pinta un búfer RGB (bw×bh) en r a toda la resolución de la pantalla.
  void blit(const std::vector<uint8_t>& buf, int bw, int bh, Rect r, int depth = 3) {
    Fl_RGB_Image im(buf.data(), bw, bh, depth);
    im.scale(r.w, r.h, 0, 1);
    im.draw(r.x, r.y);
  }

  // ================================================== los controles
  void hot(Rect r, std::function<void(int, int, int)> fn) { hots.push_back({r, std::move(fn)}); }
  void on_click(Rect r, std::function<void()> fn) {
    hot(r, [fn](int e, int, int) { if (e == FL_PUSH) fn(); });
  }
  bool over(Rect r) const { return r.has(hover_x, hover_y) && !capture; }

  void button(Rect r, const std::string& s, std::function<void()> fn, bool primary = false, bool on = false) {
    uint32_t c = primary ? C_ACCENT : on ? C_SELROW : over(r) ? 0x4a4a4a : 0x3b3b3b;
    rbox(r, c);
    text_in(s, r, primary || on ? 0xffffff : C_TEXT, 0, 12, primary);
    on_click(r, std::move(fn));
  }

  void icon_button(Rect r, int k, std::function<void()> fn, bool enabled = true) {
    if (enabled && over(r)) rbox(r, C_HOVER);
    icon(k, r.x + r.w / 2, r.y + r.h / 2, enabled ? C_TEXT : 0x606060);
    if (enabled) on_click(r, std::move(fn));
  }

  // Botones segmentados: una opción de varias.
  void segmented(Rect r, const std::vector<std::string>& opts, int v, std::function<void(int)> pick) {
    ui_font(12);
    int n = (int)opts.size(), x = r.x;
    rbox(r, 0x262626);
    for (int i = 0; i < n; i++) {
      int w = i == n - 1 ? r.r() - x : r.w / n;
      Rect b{x, r.y, w, r.h};
      if (i == v) rbox(b.grown(-2), C_ACCENT);
      else if (over(b)) rbox(b.grown(-2), C_HOVER);
      text_in(fit(opts[i], w - 8), b, i == v ? 0xffffff : C_TEXT, 0);
      on_click(b, [pick, i] { pick(i); });
      x += w;
    }
  }

  void checkbox(Rect r, const std::string& s, bool v, std::function<void()> toggle) {
    Rect b{r.x, r.y + (r.h - 14) / 2, 14, 14};
    rbox(b, v ? C_ACCENT : 0x1c1c1c);
    frame(b, v ? C_ACCENT : 0x5a5a5a);
    if (v) {
      col(0xffffff);
      line_w(2);
      fl_line(b.x + 3, b.y + 7, b.x + 6, b.y + 10, b.x + 11, b.y + 4);
      fl_line_style(0);
    }
    text_in(s, {b.r() + 6, r.y, r.w - 20, r.h}, C_TEXT);
    on_click(r, std::move(toggle));
  }

  static double to_pos(double v, double lo, double hi, bool logs) {
    if (logs) return std::log(std::max(v, lo) / lo) / std::log(hi / lo);
    return (v - lo) / (hi - lo);
  }
  static double from_pos(double p, double lo, double hi, bool logs) {
    p = clampd(p, 0, 1);
    if (logs) return lo * std::pow(hi / lo, p);
    return lo + (hi - lo) * p;
  }

  // Un deslizador: se arrastra en la pista. changed, mientras; done, al soltar.
  void slider(Rect r, double& v, double lo, double hi, bool logs, int dec, std::function<void()> changed,
              std::function<void()> done = {}) {
    int ty = r.y + r.h / 2;
    double p = clampd(to_pos(v, lo, hi, logs), 0, 1);
    int kx = r.x + 6 + iround(p * (r.w - 12));
    fill({r.x + 6, ty - 2, r.w - 12, 4}, 0x1a1a1a);
    fill({r.x + 6, ty - 2, kx - r.x - 6, 4}, C_ACCENT);
    col(over(r) ? 0xffffff : 0xe6e6e6);
    fl_pie(kx - 6, ty - 6, 12, 12, 0, 360);
    double* pv_ = &v;
    double step = std::pow(10.0, -dec);
    hot(r, [=](int e, int mx, int) {
      if (e == FL_PUSH || e == FL_DRAG) {
        double nv = from_pos((mx - r.x - 6.0) / (r.w - 12), lo, hi, logs);
        nv = std::round(nv / step) * step;
        if (nv != *pv_) {
          *pv_ = nv;
          if (changed) changed();
        }
      } else if (e == FL_RELEASE && done) {
        done();
      }
    });
  }

  // En la barra de opciones: «Nombre: ——o—— 30 px».
  void opt_slider(int& x, const std::string& name_, double& v, double lo, double hi, int dec, const std::string& unit,
                  bool logs = false) {
    Rect bar = L.opts;
    ui_font(12);
    int lw = (int)fl_width(name_.c_str()) + 6;
    text_in(name_, {x, bar.y, lw, bar.h}, C_DIM);
    x += lw;
    slider({x, bar.y + 8, 120, bar.h - 16}, v, lo, hi, logs, dec, [this] { redraw(); });
    x += 124;
    std::string vs = num(v, dec) + (unit.empty() ? "" : " " + unit);
    text_in(vs, {x, bar.y, 64, bar.h}, C_TEXT);
    x += 64 + 14;
  }

  // ================================================== dibujar
  void draw() override { render(x(), y(), w(), h()); }

  void render(int X, int Y, int W, int H) {
    layout_rects(X, Y, W, H);
    if (need_fit && !L.canvas.empty()) {
      need_fit = false;
      fit_view();
    }
    hots.clear();
    fl_push_clip(X, Y, W, H);
    fill(L.all, C_BG);
    draw_canvas();
    draw_tabs();
    draw_tools();
    draw_options();
    draw_right();
    draw_status();
    if (dlg) draw_dialog();
    draw_toast();
    fl_pop_clip();
  }

  void draw_canvas() {
    const Rect c = L.canvas;
    hot(c, [this](int e, int mx, int my) { canvas_event(e, mx, my); });
    if (doc.layers.empty()) { fill(c, C_WORK); return; }
    build_display();
    fl_push_clip(c.x, c.y, c.w, c.h);
    if (dimg) dimg->draw(c.x, c.y);
    // El borde del lienzo.
    int x0 = iround(sx_of(0)), y0 = iround(sy_of(0)), x1 = iround(sx_of(doc.w)), y1 = iround(sy_of(doc.h));
    frame({x0 - 1, y0 - 1, x1 - x0 + 2, y1 - y0 + 2}, 0x111111);
    // La capa activa, con la herramienta Mover.
    if (tool == T_MOVE && doc.layers.size() > 1) {
      Rect b = doc.cur().bounds();
      dashed_rect(scr_rect(b), 0x6fb1ff, 0x1f1f1f, 0);
    }
    if (!doc.sel.empty()) dashed_rect(scr_rect(doc.sel), 0xffffff, 0x000000, ants);
    if (crop_on && !crop.empty()) draw_crop();
    // Lo que se está arrastrando.
    if (dragging && tool == T_GRADIENT) {
      col(0xffffff);
      line_w(2);
      fl_line(iround(sx_of(ax)), iround(sy_of(ay)), iround(sx_of(bx)), iround(sy_of(by)));
      fl_line_style(0);
      for (auto [px, py] : {std::pair<double, double>{ax, ay}, {bx, by}}) {
        col(0xffffff);
        fl_pie(iround(sx_of(px)) - 5, iround(sy_of(py)) - 5, 10, 10, 0, 360);
        col(0x000000);
        fl_arc(iround(sx_of(px)) - 5, iround(sy_of(py)) - 5, 10, 10, 0, 360);
      }
    }
    if (dragging && tool == T_SHAPE) {
      Rect s = scr_rect(shape_box());
      col(0xffffff);
      if (shape_kind == 2) fl_arc(s.x, s.y, s.w, s.h, 0, 360);
      else fl_rect(s.x, s.y, s.w, s.h);
      col(0x000000);
      if (shape_kind == 2) fl_arc(s.x + 1, s.y + 1, s.w - 2, s.h - 2, 0, 360);
      else fl_rect(s.x + 1, s.y + 1, s.w - 2, s.h - 2);
    }
    // El contorno del pincel o del borrador.
    if ((tool == T_BRUSH || tool == T_ERASER) && !space && c.has(hover_x, hover_y) && !dlg) {
      int r = std::max(2, iround(size_[tool] * zoom / 2));
      col(0x000000);
      fl_arc(hover_x - r - 1, hover_y - r - 1, 2 * r + 2, 2 * r + 2, 0, 360);
      col(0xffffff);
      fl_arc(hover_x - r, hover_y - r, 2 * r, 2 * r, 0, 360);
    }
    fl_pop_clip();
  }

  Rect scr_rect(Rect r) const {
    int x0 = iround(sx_of(r.x)), y0 = iround(sy_of(r.y)), x1 = iround(sx_of(r.r())), y1 = iround(sy_of(r.b()));
    return {x0, y0, std::max(1, x1 - x0), std::max(1, y1 - y0)};
  }

  // Un rectángulo de rayas (las «hormigas» de la selección si avanza la fase).
  void dashed_rect(Rect r, uint32_t a, uint32_t b, int phase) {
    auto seg = [&](int x0, int y0, int x1, int y1) {
      int len = std::max(std::abs(x1 - x0), std::abs(y1 - y0));
      int sx = x1 > x0 ? 1 : x1 < x0 ? -1 : 0, sy = y1 > y0 ? 1 : y1 < y0 ? -1 : 0;
      for (int i = 0; i < len; i += 4) {
        bool on = ((i / 4 + phase) & 1) != 0;
        col(on ? a : b);
        int e = std::min(i + 4, len);
        fl_line(x0 + sx * i, y0 + sy * i, x0 + sx * (e - 1), y0 + sy * (e - 1));
      }
    };
    seg(r.x, r.y, r.r(), r.y);
    seg(r.r() - 1, r.y, r.r() - 1, r.b());
    seg(r.r() - 1, r.b() - 1, r.x - 1, r.b() - 1);
    seg(r.x, r.b() - 1, r.x, r.y - 1);
  }

  void draw_crop() {
    Rect s = scr_rect(crop);
    frame(s, 0xffffff);
    col(0xffffff);
    for (int k = 1; k < 3; k++) {
      int x = s.x + s.w * k / 3, y = s.y + s.h * k / 3;
      fl_line_style(FL_DOT, 1);
      fl_line(x, s.y, x, s.b() - 1);
      fl_line(s.x, y, s.r() - 1, y);
    }
    fl_line_style(0);
    for (auto [hx, hy] : crop_handles()) {
      fill({hx - 5, hy - 5, 10, 10}, 0xffffff);
      frame({hx - 5, hy - 5, 10, 10}, 0x000000);
    }
    std::string sz = std::to_string(crop.w) + " × " + std::to_string(crop.h) + " px";
    ui_font(12, true);
    int tw = (int)fl_width(sz.c_str()) + 16;
    Rect tag{s.x, s.y - 26, tw, 20};
    if (tag.y < L.canvas.y + 4) tag.y = s.y + 6;
    rbox(tag, 0x000000);
    text_in(sz, tag, 0xffffff, 0, 12, true);
  }

  std::vector<std::pair<int, int>> crop_handles() const {
    Rect s = scr_rect(crop);
    int mx = s.x + s.w / 2, my = s.y + s.h / 2;
    return {{s.x, s.y}, {mx, s.y}, {s.r(), s.y}, {s.r(), my}, {s.r(), s.b()}, {mx, s.b()}, {s.x, s.b()}, {s.x, my}};
  }

  void draw_tabs() {
    Rect t = L.tabs;
    fill(t, C_HEAD);
    fill({t.x, t.b() - 1, t.w, 1}, C_LINE);
    std::string s = name + " @ " + num(zoom * 100, zoom < 1 ? 1 : 0) + " % (" + doc.cur().name + ", RGB/8)" + (dirty ? " *" : "");
    ui_font(12);
    int tw = std::min((int)fl_width(s.c_str()) + 28, t.w - 4);
    Rect tab{t.x + 2, t.y + 3, tw, t.h - 3};
    fill(tab, C_PANEL);
    text_in(fit(s, tw - 20), tab.grown(-10), C_TEXT);
  }

  void draw_tools() {
    Rect t = L.tools;
    fill(t, C_PANEL);
    fill({t.r() - 1, t.y, 1, t.h}, C_LINE);
    for (int i = 0; i < T_COUNT; i++) {
      Rect b{t.x + 5, t.y + 8 + i * 36 + (i >= 3 ? 8 : 0) + (i >= 8 ? 8 : 0) + (i >= 10 ? 8 : 0), 36, 32};
      if (i == tool) rbox(b, 0x4b4b4b);
      else if (over(b)) rbox(b, C_HOVER);
      tool_icon(i, b.x + b.w / 2, b.y + b.h / 2, i == tool ? 0xffffff : 0xc4c4c4);
      on_click(b, [this, i] { set_tool(i); });
    }
    // Los colores frontal y de fondo, abajo del todo.
    int y = t.y + 8 + T_COUNT * 36 + 32;
    if (y + 46 < t.b()) {
      Rect bgr{t.x + 17, y + 14, 22, 22}, fgr{t.x + 7, y + 4, 22, 22};
      fill(bgr, bg); frame(bgr, 0x000000); frame(bgr.grown(-1), 0xffffff);
      fill(fgr, fg); frame(fgr, 0x000000); frame(fgr.grown(-1), 0xffffff);
      on_click(fgr, [this] { edit_bg = false; sync_picker(); redraw(); });
      on_click(bgr, [this] { edit_bg = true; sync_picker(); redraw(); });
    }
  }

  void set_tool(int t) {
    if (t == tool) return;
    if (tool == T_CROP && crop_on) {
      crop_on = false;
      view_dirty = true;
    }
    tool = t;
    if (tool == T_CROP) start_crop();
    last_cursor = -1;
    update_cursor();
    redraw();
  }

  void draw_options() {
    Rect bar = L.opts;
    fill(bar, C_PANEL);
    fill({bar.x, bar.b() - 1, bar.w, 1}, C_LINE);
    tool_icon(tool, bar.x + 23, bar.y + bar.h / 2, 0xffffff);
    int x = bar.x + 46;
    ui_font(12, true);
    std::string tn = tool_name(tool);
    text_in(tn, {x, bar.y, 200, bar.h}, C_TEXT, -1, 12, true);
    x += (int)fl_width(tn.c_str()) + 14;
    fill({x, bar.y + 9, 1, bar.h - 18}, C_LINE2);
    x += 14;
    auto seg = [&](int w, std::vector<std::string> o, int& v, std::function<void()> f = {}) {
      int* p = &v;   // un miembro del editor
      segmented({x, bar.y + 8, w, bar.h - 16}, o, v, [this, p, f](int i) { *p = i; if (f) f(); redraw(); });
      x += w + 14;
    };
    auto cap = [&](const std::string& s) {
      ui_font(12);
      int w = (int)fl_width(s.c_str()) + 8;
      text_in(s, {x, bar.y, w, bar.h}, C_DIM);
      x += w;
    };
    switch (tool) {
      case T_BRUSH:
      case T_ERASER:
        opt_slider(x, tx::O_SIZE, size_[tool], 1, 500, 0, "px", true);
        opt_slider(x, tx::O_HARDNESS, hard_[tool], 0, 100, 0, "%");
        opt_slider(x, tx::O_OPACITY, op_[tool], 1, 100, 0, "%");
        break;
      case T_FILL:
        opt_slider(x, tx::O_TOLERANCE, fill_tol, 0, 255, 0, "");
        checkbox({x, bar.y, 110, bar.h}, tx::O_CONTIGUOUS, fill_contig, [this] { fill_contig = !fill_contig; redraw(); });
        x += 110;
        opt_slider(x, tx::O_OPACITY, op_[tool], 1, 100, 0, "%");
        break;
      case T_GRADIENT:
        seg(170, {tx::O_LINEAR, tx::O_RADIAL}, grad_kind);
        opt_slider(x, tx::O_OPACITY, op_[tool], 1, 100, 0, "%");
        cap(tx::O_GRAD_HINT);
        break;
      case T_SHAPE:
        seg(260, {tx::O_RECT, tx::O_ROUNDED, tx::O_ELLIPSE}, shape_kind);
        cap(tx::O_SHAPE_HINT);
        break;
      case T_TEXT:
        seg(190, {"Sans", "Serif", "Mono"}, text_font);
        checkbox({x, bar.y, 90, bar.h}, tx::O_BOLD, text_bold, [this] { text_bold = !text_bold; redraw(); });
        x += 90;
        opt_slider(x, tx::O_SIZE, text_size, 8, 400, 0, "px", true);
        break;
      case T_CROP:
        cap(tx::O_RATIO);
        seg(360, {tx::O_FREE, "1:1", "4:3", "3:2", "16:9", tx::O_ORIGINAL}, crop_ratio, [this] { apply_ratio(); });
        if (crop_on) {
          button({x, bar.y + 8, 84, bar.h - 16}, tx::O_APPLY, [this] { apply_crop(); }, true);
          x += 92;
          button({x, bar.y + 8, 84, bar.h - 16}, tx::CANCEL, [this] { cancel_crop(); });
          x += 92;
        }
        break;
      case T_MARQUEE:
        button({x, bar.y + 8, 130, bar.h - 16}, tx::L_SELECT_ALL, [this] { command(C_SELECT_ALL); });
        x += 138;
        button({x, bar.y + 8, 110, bar.h - 16}, tx::L_DESELECT, [this] { command(C_DESELECT); });
        x += 124;
        if (!doc.sel.empty()) cap(fmt(tx::O_SEL_SIZE, {std::to_string(doc.sel.w), std::to_string(doc.sel.h)}));
        break;
      case T_MOVE: {
        const Layer& l = doc.cur();
        cap(fmt(tx::O_LAYER_POS, {l.name, std::to_string(l.x), std::to_string(l.y)}));
        break;
      }
      case T_PICKER:
        cap(tx::O_SAMPLE);
        seg(240, {tx::O_CUR_LAYER, tx::O_ALL_LAYERS}, pick_all);
        break;
      case T_HAND:
      case T_ZOOM:
        button({x, bar.y + 8, 70, bar.h - 16}, "100 %", [this] { command(C_ACTUAL); });
        x += 78;
        button({x, bar.y + 8, 120, bar.h - 16}, tx::O_FIT, [this] { command(C_FIT); });
        x += 128;
        button({x, bar.y + 8, 36, bar.h - 16}, "+", [this] { command(C_ZOOM_IN); });
        x += 44;
        button({x, bar.y + 8, 36, bar.h - 16}, "−", [this] { command(C_ZOOM_OUT); });
        x += 50;
        break;
    }
  }

  // ---- los paneles de la derecha
  void panel_head(Rect r, const std::string& s) {
    fill({r.x, r.y, r.w, 24}, C_HEAD);
    fill({r.x, r.y, r.w, 1}, C_LINE);
    fill({r.x, r.y + 23, r.w, 1}, C_LINE);
    text_in(s, {r.x + 10, r.y, r.w - 20, 24}, C_TEXT, -1, 12, true);
  }

  void draw_right() {
    Rect r = L.right;
    fill(r, C_PANEL);
    fill({r.x, r.y, 1, r.h}, C_LINE);
    draw_color();
    draw_layers();
    draw_history();
  }

  void sync_picker() {
    rgb_hsv(edit_bg ? bg : fg, ph, ps, pv);
  }
  void set_color(uint32_t c, bool background = false) {
    (background ? bg : fg) = c;
    if (background == edit_bg) sync_picker();
    redraw();
  }
  void picker_changed() {
    (edit_bg ? bg : fg) = hsv_rgb(ph, ps, pv);
    redraw();
  }

  void draw_color() {
    Rect p = L.color;
    panel_head(p, tx::P_COLOR);
    int y0 = p.y + 24;
    // Frontal y fondo.
    Rect bgr{p.x + 32, y0 + 30, 36, 36}, fgr{p.x + 12, y0 + 10, 36, 36};
    fill(bgr, bg); frame(bgr, 0x000000); frame(bgr.grown(-1), edit_bg ? C_ACCENT : 0xffffff);
    fill(fgr, fg); frame(fgr, 0x000000); frame(fgr.grown(-1), !edit_bg ? C_ACCENT : 0xffffff);
    on_click(bgr, [this] { edit_bg = true; sync_picker(); redraw(); });
    on_click(fgr, [this] { edit_bg = false; sync_picker(); redraw(); });
    icon_button({p.x + 52, y0 + 6, 18, 18}, I_SWAP, [this] { command_key('x'); });
    Rect rs{p.x + 12, y0 + 54, 14, 14};
    fill({rs.x + 5, rs.y + 5, 9, 9}, 0xffffff);
    fill({rs.x, rs.y, 9, 9}, 0x000000);
    frame({rs.x, rs.y, 9, 9}, 0x888888);
    on_click(rs, [this] { command_key('d'); });
    // Muestras.
    static const uint32_t presets[] = {0x000000, 0xffffff, 0x808080, 0xd7263d, 0xf46036, 0xffd23f,
                                       0x2e933c, 0x1b998b, 0x2f80ed, 0x1d2350, 0x8e44ad, 0xe85d9f};
    for (int i = 0; i < 12; i++) {
      Rect s{p.x + 10 + (i % 4) * 17, y0 + 82 + (i / 4) * 17, 14, 14};
      fill(s, presets[i]);
      frame(s, over(s) ? 0xffffff : 0x1a1a1a);
      uint32_t c = presets[i];
      on_click(s, [this, c] { set_color(c, edit_bg); });
    }
    // El cuadro de saturación y brillo, y la barra del tono.
    Rect sv{p.x + 86, y0 + 10, p.w - 86 - 40, 124}, hb{p.r() - 30, y0 + 10, 16, 124};
    double d = dev();
    int bw = std::max(1, iround(sv.w * d)), bh = std::max(1, iround(sv.h * d));
    std::vector<uint8_t> buf((size_t)bw * bh * 3);
    for (int j = 0; j < bh; j++)
      for (int i = 0; i < bw; i++) {
        uint32_t c = hsv_rgb(ph, (i + 0.5) / bw, 1 - (j + 0.5) / bh);
        uint8_t* o = &buf[((size_t)j * bw + i) * 3];
        o[0] = c >> 16; o[1] = c >> 8; o[2] = c;
      }
    blit(buf, bw, bh, sv);
    int hw = std::max(1, iround(hb.w * d)), hh = std::max(1, iround(hb.h * d));
    std::vector<uint8_t> hbuf((size_t)hw * hh * 3);
    for (int j = 0; j < hh; j++) {
      uint32_t c = hsv_rgb(360.0 * (j + 0.5) / hh, 1, 1);
      for (int i = 0; i < hw; i++) {
        uint8_t* o = &hbuf[((size_t)j * hw + i) * 3];
        o[0] = c >> 16; o[1] = c >> 8; o[2] = c;
      }
    }
    blit(hbuf, hw, hh, hb);
    frame(sv.grown(1), 0x161616);
    frame(hb.grown(1), 0x161616);
    int mx = sv.x + iround(ps * (sv.w - 1)), my = sv.y + iround((1 - pv) * (sv.h - 1));
    col(pv > 0.6 ? 0x000000 : 0xffffff);
    fl_arc(mx - 6, my - 6, 12, 12, 0, 360);
    int hy = hb.y + iround(ph / 360 * (hb.h - 1));
    fill({hb.x - 3, hy - 2, hb.w + 6, 4}, 0xffffff);
    frame({hb.x - 3, hy - 2, hb.w + 6, 4}, 0x000000);
    hot(sv, [this, sv](int e, int x, int y) {
      if (e == FL_RELEASE) return;
      ps = clampd((x - sv.x) / (double)(sv.w - 1), 0, 1);
      pv = clampd(1 - (y - sv.y) / (double)(sv.h - 1), 0, 1);
      picker_changed();
    });
    hot(hb.grown(3), [this, hb](int e, int, int y) {
      if (e == FL_RELEASE) return;
      ph = clampd((y - hb.y) / (double)(hb.h - 1), 0, 1) * 359.9;
      picker_changed();
    });
    // El código del color: se puede escribir.
    Rect hx{sv.x, y0 + 142, 96, 24};
    rbox(hx, C_FIELD);
    text_in(hex(edit_bg ? bg : fg), hx.grown(-6), C_TEXT);
    on_click(hx, [this] { hex_dialog(); });
    char rgbs[48];
    uint32_t c = edit_bg ? bg : fg;
    std::snprintf(rgbs, sizeof rgbs, "R %d  G %d  B %d", (int)(c >> 16) & 255, (int)(c >> 8) & 255, (int)c & 255);
    text_in(rgbs, {hx.r() + 10, hx.y, p.r() - hx.r() - 14, hx.h}, C_DIM, -1, 11);
  }

  // Una miniatura de la capa sobre el damero.
  void thumb(const Layer& l, Rect r) {
    double d = dev();
    int bw = std::max(1, iround(r.w * d)), bh = std::max(1, iround(r.h * d));
    std::vector<uint8_t> buf((size_t)bw * bh * 3);
    double sc = std::min((double)doc.w / bw, (double)doc.h / bh);
    double s = std::max((double)doc.w / bw, (double)doc.h / bh);
    (void)sc;
    double ox = (bw * s - doc.w) / 2, oy = (bh * s - doc.h) / 2;
    for (int j = 0; j < bh; j++)
      for (int i = 0; i < bw; i++) {
        int dx = (int)std::floor((i + 0.5) * s - ox), dy = (int)std::floor((j + 0.5) * s - oy);
        uint8_t* o = &buf[((size_t)j * bw + i) * 3];
        if (dx < 0 || dy < 0 || dx >= doc.w || dy >= doc.h) { o[0] = o[1] = o[2] = 0x26; continue; }
        int ck = (((int)(i / d) / 4 + (int)(j / d) / 4) & 1) ? 204 : 255;
        int lx = dx - l.x, ly = dy - l.y;
        if (lx < 0 || ly < 0 || lx >= l.img->w || ly >= l.img->h) { o[0] = o[1] = o[2] = (uint8_t)ck; continue; }
        const uint8_t* p = l.img->at(lx, ly);
        for (int k = 0; k < 3; k++) o[k] = (uint8_t)((p[k] * p[3] + ck * (255 - p[3])) / 255);
      }
    blit(buf, bw, bh, r);
  }

  void draw_layers() {
    Rect p = L.layers;
    panel_head(p, tx::P_LAYERS);
    // El modo de fusión y la opacidad de la capa activa.
    Layer& cur = doc.cur();
    Rect mode{p.x + 8, p.y + 30, 124, 24};
    rbox(mode, C_FIELD);
    ui_font(12);
    text_in(fit(blend_name(cur.blend), mode.w - 26), mode.grown(-7), C_TEXT);
    col(C_DIM);
    fl_polygon(mode.r() - 16, mode.y + 10, mode.r() - 8, mode.y + 10, mode.r() - 12, mode.y + 15);
    on_click(mode, [this, mode] { blend_menu(mode); });
    text_in(tx::O_OPACITY, {mode.r() + 8, mode.y, 60, 24}, C_DIM, -1, 11);
    static double opv = 100;
    opv = cur.opacity * 100;
    slider({mode.r() + 64, mode.y, p.r() - mode.r() - 64 - 44, 24}, opv, 0, 100, false, 0,
           [this] { doc.cur().opacity = opv / 100; touch_all(); },
           [this] { commit(tx::S_OPACITY); });
    text_in(num(cur.opacity * 100) + " %", {p.r() - 44, mode.y, 38, 24}, C_TEXT, 1, 11);
    // La lista: la capa de arriba primero.
    Rect list{p.x, p.y + 60, p.w, p.h - 60 - 32};
    const int RH = 46;
    int n = (int)doc.layers.size();
    int maxs = std::max(0, n * RH - list.h);
    layer_scroll = clampi(layer_scroll, 0, maxs);
    fl_push_clip(list.x, list.y, list.w, list.h);
    for (int k = 0; k < n; k++) {
      int i = n - 1 - k;
      Layer& l = doc.layers[i];
      Rect row{list.x + 1, list.y + k * RH - layer_scroll, list.w - 1, RH};
      if (row.b() < list.y || row.y > list.b()) continue;
      fill(row, i == doc.active ? C_SELROW : over(row) ? 0x383838 : C_PANEL);
      fill({row.x, row.b() - 1, row.w, 1}, 0x262626);
      Rect eye{row.x + 4, row.y + 8, 26, 30};
      if (l.visible) icon(I_EYE, eye.x + 13, eye.y + 15, C_TEXT);
      else frame({eye.x + 7, eye.y + 9, 12, 12}, 0x5a5a5a);
      Rect th{row.x + 34, row.y + 5, 54, 36};
      thumb(l, th);
      frame(th.grown(1), i == doc.active ? 0xffffff : 0x161616);
      Rect nm{th.r() + 10, row.y + 6, row.r() - th.r() - 16, 18};
      ui_font(12, i == doc.active);
      text_in(fit(l.name, nm.w), nm, l.visible ? C_TEXT : C_DIM, -1, 12, i == doc.active);
      std::string info = l.blend != B_NORMAL || l.opacity < 1
                             ? std::string(blend_name(l.blend)) + " · " + num(l.opacity * 100) + " %"
                             : std::to_string(l.img->w) + " × " + std::to_string(l.img->h);
      ui_font(11);
      text_in(fit(info, nm.w), {nm.x, row.y + 24, nm.w, 16}, C_DIM, -1, 11);
      on_click(eye, [this, i] {
        doc.layers[i].visible = !doc.layers[i].visible;
        touch_all();
        commit(doc.layers[i].visible ? tx::S_SHOW : tx::S_HIDE);
      });
      Rect rest{th.x, row.y, row.r() - th.x, row.h};
      on_click(rest, [this, i] {
        if (Fl::event_clicks() && doc.active == i) {
          Fl::event_clicks(0);
          command(C_LAYER_PROPS);
          return;
        }
        doc.active = i;
        redraw();
        notify();
      });
    }
    fl_pop_clip();
    // Los botones de abajo.
    Rect b{p.x, p.b() - 32, p.w, 32};
    fill(b, C_HEAD);
    fill({b.x, b.y, b.w, 1}, C_LINE);
    int bx_ = b.x + 8;
    auto ib = [&](int k, int c, bool en = true) {
      icon_button({bx_, b.y + 4, 28, 24}, k, [this, c] { command(c); }, en);
      bx_ += 32;
    };
    ib(I_NEW, C_LAYER_NEW);
    ib(I_DUP, C_LAYER_DUP);
    ib(I_UP, C_LAYER_UP, doc.active < n - 1);
    ib(I_DOWN, C_LAYER_DOWN, doc.active > 0);
    ib(I_MERGE, C_MERGE, doc.active > 0);
    ib(I_PROPS, C_LAYER_PROPS);
    bx_ = b.r() - 36;
    ib(I_DEL, C_LAYER_DEL, n > 1);
  }

  void blend_menu(Rect at) {
    if (shooting) return;
    std::vector<Fl_Menu_Item> items(B_COUNT + 1);
    for (int i = 0; i < B_COUNT; i++) {
      std::memset(&items[i], 0, sizeof(Fl_Menu_Item));
      items[i].text = blend_name(i);
      if (i == doc.cur().blend) items[i].flags = FL_MENU_RADIO | FL_MENU_VALUE;
    }
    std::memset(&items[B_COUNT], 0, sizeof(Fl_Menu_Item));
    const Fl_Menu_Item* m = items[0].popup(at.x, at.b());
    if (!m) return;
    int i = (int)(m - &items[0]);
    if (i == doc.cur().blend) return;
    doc.cur().blend = i;
    touch_all();
    commit(tx::S_BLEND);
  }

  void draw_history() {
    Rect p = L.history;
    panel_head(p, tx::P_HISTORY);
    Rect list{p.x, p.y + 24, p.w, p.h - 24};
    const int RH = 22;
    int n = (int)hist.steps.size();
    int maxs = std::max(0, n * RH - list.h);
    // Que se vea el paso actual.
    int cur_y = hist.cur * RH;
    if (cur_y < hist_scroll) hist_scroll = cur_y;
    if (cur_y + RH > hist_scroll + list.h) hist_scroll = cur_y + RH - list.h;
    hist_scroll = clampi(hist_scroll, 0, maxs);
    fl_push_clip(list.x, list.y, list.w, list.h);
    for (int i = 0; i < n; i++) {
      Rect row{list.x + 1, list.y + i * RH - hist_scroll, list.w - 1, RH};
      if (row.b() < list.y || row.y > list.b()) continue;
      bool now = i == hist.cur, future = i > hist.cur;
      fill(row, now ? C_SELROW : over(row) ? 0x383838 : C_PANEL);
      if (now) fill({row.x, row.y, 3, row.h}, C_ACCENT);
      text_in(fit(hist.steps[i].label, row.w - 30), {row.x + 14, row.y, row.w - 20, row.h},
            future ? 0x707070 : C_TEXT, -1, 12);
      on_click(row, [this, i] { go_step(i); });
    }
    fl_pop_clip();
  }

  void draw_status() {
    Rect s = L.status;
    fill(s, C_HEAD);
    fill({s.x, s.y, s.w, 1}, C_LINE);
    std::string left = num(zoom * 100, zoom < 1 ? 1 : 0) + " %    " + std::to_string(doc.w) + " × " +
                       std::to_string(doc.h) + " px    " + tool_hint(space ? T_HAND : tool);
    ui_font(11);
    text_in(fit(left, s.w - 320), {s.x + 12, s.y, s.w - 330, s.h}, C_DIM, -1, 11);
    if (L.canvas.has(hover_x, hover_y) && !doc.layers.empty()) {
      int px = (int)std::floor(dx_of(hover_x)), py = (int)std::floor(dy_of(hover_y));
      if (px >= 0 && py >= 0 && px < doc.w && py < doc.h) {
        update_comp();
        const uint8_t* c = comp.at(px, py);
        uint32_t v = ((uint32_t)c[0] << 16) | (c[1] << 8) | c[2];
        std::string t = "X " + std::to_string(px) + "   Y " + std::to_string(py) + "   " + hex(v) + "  " +
                        tx::ALPHA + " " + std::to_string(c[3] * 100 / 255) + " %";
        ui_font(11);
        int tw = (int)fl_width(t.c_str());
        Rect sw{s.r() - tw - 34, s.y + 6, 12, 12};
        fill(sw, v);
        frame(sw, 0x000000);
        text_in(t, {sw.r() + 8, s.y, tw + 4, s.h}, C_TEXT, -1, 11);
      }
    }
  }

  void draw_toast() {
    if (toast.empty() || toast_t <= 0) return;
    ui_font(13);
    int tw = std::min((int)fl_width(toast.c_str()) + 36, L.canvas.w - 40);
    Rect r{L.canvas.x + (L.canvas.w - tw) / 2, L.canvas.b() - 56, tw, 34};
    rbox(r, toast_err ? C_ERR : 0x101010);
    text_in(fit(toast, tw - 30), r, 0xffffff, 0, 13);
  }

  // ---- el cuadro de diálogo abierto
  int field_h(const Field& f) const {
    switch (f.kind) {
      case Field::SLIDER: return 36;
      case Field::NUMBER: case Field::CHOICE: case Field::TEXT: return 34;
      case Field::CHECK: return 28;
      case Field::HISTO: return 112;
      case Field::ANCHOR: return 76;
      default: return 24;
    }
  }

  void draw_dialog() {
    Dialog& D = *dlg;
    // Oscurece lo de detrás (y no deja tocarlo).
    if (fl_can_do_alpha_blending()) {
      static const uint8_t shade[4] = {0, 0, 0, 110};
      Fl_RGB_Image s(shade, 1, 1, 4);
      s.scale(L.all.w, L.all.h, 0, 1);
      s.draw(L.all.x, L.all.y);
    }
    hot(L.all, [](int, int, int) {});
    int h = 46 + 56 + 12;
    for (auto& f : D.f) h += field_h(f);
    Rect r{L.all.x + (L.all.w - D.w) / 2, L.all.y + std::max(20, (L.all.h - h) / 2 - 30), D.w, h};
    fill(r, 0x353535);
    frame(r, 0x505050);
    frame(r.grown(1), 0x121212);
    text_in(no_dots(D.title), {r.x + 18, r.y, r.w - 36, 44}, 0xffffff, -1, 14, true);
    fill({r.x, r.y + 44, r.w, 1}, 0x262626);
    int y = r.y + 54;
    const int lx = r.x + 18, cxl = r.x + 150, cw = r.r() - 18 - cxl;
    for (int i = 0; i < (int)D.f.size(); i++) {
      Field& f = D.f[i];
      int fh = field_h(f);
      Rect row{lx, y, r.w - 36, fh};
      auto changed = [this, i] { if (dlg && dlg->change) dlg->change(i); redraw(); };
      switch (f.kind) {
        case Field::SLIDER: {
          text_in(f.label, {lx, y, cxl - lx - 6, fh}, C_TEXT);
          slider({cxl, y + 6, cw - 76, fh - 12}, f.v, f.lo, f.hi, f.logs, f.dec, changed);
          Rect vb{r.r() - 18 - 68, y + 6, 68, fh - 12};
          rbox(vb, C_FIELD);
          text_in(num(f.v, f.dec) + (f.unit.empty() ? "" : " " + f.unit), vb.grown(-6), C_TEXT, 1);
          break;
        }
        case Field::NUMBER:
        case Field::TEXT: {
          text_in(f.label, {lx, y, cxl - lx - 6, fh}, C_TEXT);
          int fw = f.kind == Field::NUMBER ? 110 : cw;
          Rect b{cxl, y + 4, fw, fh - 8};
          rbox(b, C_FIELD);
          frame(b, D.focus == i ? C_ACCENT : 0x4a4a4a);
          std::string shown = f.s;
          ui_font(13);
          text_in(shown, b.grown(-8), C_TEXT, -1, 13);
          if (D.focus == i && (ants & 2) == 0) {
            int cx_ = b.x + 8 + (int)fl_width(shown.c_str()) + 1;
            fill({cx_, b.y + 5, 1, b.h - 10}, 0xffffff);
          }
          if (!f.unit.empty()) text_in(f.unit, {b.r() + 8, y, 60, fh}, C_DIM);
          on_click(b, [this, i] { dlg->focus = i; Fl::compose_reset(); redraw(); });
          break;
        }
        case Field::CHECK: {
          checkbox(row, f.label, f.v != 0, [this, i, changed] { dlg->f[i].v = dlg->f[i].v ? 0 : 1; changed(); });
          break;
        }
        case Field::CHOICE: {
          text_in(f.label, {lx, y, cxl - lx - 6, fh}, C_TEXT);
          if (f.opts.size() <= 4) {
            segmented({cxl, y + 4, cw, fh - 8}, f.opts, (int)f.v, [this, i, changed](int k) { dlg->f[i].v = k; changed(); });
          } else {
            Rect b{cxl, y + 4, cw, fh - 8};
            rbox(b, C_FIELD);
            text_in(f.opts[clampi((int)f.v, 0, (int)f.opts.size() - 1)], b.grown(-8), C_TEXT);
            col(C_DIM);
            fl_polygon(b.r() - 18, b.y + 11, b.r() - 8, b.y + 11, b.r() - 13, b.y + 17);
            on_click(b, [this, i, b, changed] {
              if (shooting) return;
              Field& ff = dlg->f[i];
              std::vector<Fl_Menu_Item> items(ff.opts.size() + 1);
              for (size_t k = 0; k <= ff.opts.size(); k++) std::memset(&items[k], 0, sizeof(Fl_Menu_Item));
              for (size_t k = 0; k < ff.opts.size(); k++) items[k].text = ff.opts[k].c_str();
              const Fl_Menu_Item* m = items[0].popup(b.x, b.b());
              if (m) { ff.v = (double)(m - &items[0]); changed(); }
            });
          }
          break;
        }
        case Field::HISTO: {
          Rect hb{lx, y + 4, r.w - 36, fh - 12};
          fill(hb, C_FIELD);
          int mx = 1;
          for (int v : D.histo) mx = std::max(mx, v);
          col(0xb8b8b8);
          for (int k = 0; k < (int)D.histo.size(); k++) {
            int x0 = hb.x + k * hb.w / 256, x1 = hb.x + (k + 1) * hb.w / 256;
            int hh = iround(std::sqrt(D.histo[k] / (double)mx) * (hb.h - 4));
            fl_rectf(x0, hb.b() - hh, std::max(1, x1 - x0), hh);
          }
          // Las marcas de los niveles (campos 1 y 3: negro y blanco).
          if (D.f.size() > 3) {
            for (int k : {1, 3}) {
              int x = hb.x + iround(D.f[k].v / 255 * (hb.w - 1));
              col(k == 1 ? 0x000000 : 0xffffff);
              fl_polygon(x, hb.b() - 8, x - 5, hb.b(), x + 5, hb.b());
              col(0x808080);
              fl_loop(x, hb.b() - 8, x - 5, hb.b(), x + 5, hb.b());
            }
          }
          break;
        }
        case Field::ANCHOR: {
          text_in(f.label, {lx, y, cxl - lx - 6, 30}, C_TEXT);
          for (int k = 0; k < 9; k++) {
            Rect b{cxl + (k % 3) * 24, y + 4 + (k / 3) * 23, 21, 20};
            rbox(b, k == (int)f.v ? C_ACCENT : over(b) ? C_HOVER : 0x262626);
            on_click(b, [this, i, k, changed] { dlg->f[i].v = k; changed(); });
          }
          break;
        }
        case Field::INFO:
          text_in(f.s, {lx, y, r.w - 36, fh}, C_DIM, -1, 12);
          break;
      }
      y += fh;
    }
    int by_ = r.b() - 52;
    fill({r.x, by_ - 6, r.w, 1}, 0x262626);
    button({r.r() - 18 - 110, by_ + 6, 110, 30}, D.ok_label.empty() ? tx::OK : D.ok_label, [this] { dialog_ok(); }, true);
    button({r.r() - 18 - 110 - 10 - 110, by_ + 6, 110, 30}, tx::CANCEL, [this] { dialog_cancel(); });
  }

  // ok puede cerrar el diálogo él mismo; si devuelve false, sigue abierto.
  void dialog_ok() {
    if (!dlg) return;
    auto ok = dlg->ok;   // una copia: el diálogo puede cerrarse mientras corre
    Dialog* before = dlg.get();
    bool done = !ok || ok();
    if (done && dlg.get() == before) dlg.reset();
    redraw();
  }
  void dialog_cancel() {
    if (!dlg) return;
    auto c = dlg->cancel;
    dlg.reset();
    if (c) c();
    redraw();
  }

  // Abre un diálogo de ajuste o filtro: lo que hace apply se ve mientras se
  // mueven los controles; Aceptar lo deja en el historial y Cancelar lo quita.
  void adjust(const std::string& title, std::vector<Field> f, std::function<void(Img&, Rect, const std::vector<Field>&)> apply,
              bool live = true) {
    if (doc.layers.empty() || !paintable()) return;
    base = doc;
    dlg.reset(new Dialog);
    dlg->title = title;
    dlg->f = std::move(f);
    std::string step = no_dots(title);
    auto run = [this, apply] {
      doc = base;
      Img& im = doc.mut(doc.active);
      Rect a = doc.area(doc.active);
      if (!a.empty()) apply(im, a, dlg->f);
      Rect lb = doc.cur().bounds();
      touch(lb);
    };
    if (live) dlg->change = [run](int) { run(); };
    dlg->ok = [this, run, step] {
      run();
      commit(step);
      return true;
    };
    dlg->cancel = [this] {
      doc = base;
      touch_all();
    };
    if (live) run();
    redraw();
  }

  // Un diálogo que cambia el documento entero (tamaño, girar…).
  void doc_dialog(const std::string& title, std::vector<Field> f, std::function<void(Doc&, const std::vector<Field>&)> apply,
                  bool live, std::function<void(int, std::vector<Field>&)> linked = {}) {
    base = doc;
    dlg.reset(new Dialog);
    dlg->title = title;
    dlg->f = std::move(f);
    std::string step = no_dots(title);
    auto run = [this, apply](const std::vector<Field>& ff) {
      doc = base;
      apply(doc, ff);
      if (doc.w != base.w || doc.h != base.h) need_fit = true;
      touch_all();
    };
    dlg->change = [this, run, live, linked](int i) {
      if (linked) linked(i, dlg->f);
      if (live) run(dlg->f);
    };
    dlg->ok = [this, run, step] {
      run(dlg->f);
      commit(step);
      return true;
    };
    dlg->cancel = [this] {
      bool resized = doc.w != base.w || doc.h != base.h;
      doc = base;
      if (resized) need_fit = true;
      touch_all();
    };
    redraw();
  }

  // ================================================== el ratón
  void canvas_event(int e, int mx, int my) {
    if (doc.layers.empty()) return;
    double dx = dx_of(mx), dy = dy_of(my);
    int t = space ? T_HAND : tool;
    bool alt = Fl::event_state(FL_ALT) != 0, shift = Fl::event_state(FL_SHIFT) != 0;
    switch (t) {
      case T_HAND:
        if (e == FL_PUSH) { ax = mx; ay = my; bx = cx; by = cy; }
        else if (e == FL_DRAG) {
          cx = bx - (mx - ax) / zoom;
          cy = by - (my - ay) / zoom;
          clamp_pan();
          view_dirty = true;
        }
        break;
      case T_ZOOM:
        if (e == FL_PUSH) set_zoom(zoom_step(zoom, !alt), mx, my);
        break;
      case T_MOVE: {
        Layer& l = doc.cur();
        if (e == FL_PUSH) { ax = dx; ay = dy; start_lx = l.x; start_ly = l.y; dragging = true; }
        else if (e == FL_DRAG && dragging) {
          Rect old = l.bounds();
          l.x = start_lx + iround(dx - ax);
          l.y = start_ly + iround(dy - ay);
          touch(unite(old, l.bounds()));
        } else if (e == FL_RELEASE && dragging) {
          dragging = false;
          if (l.x != start_lx || l.y != start_ly) commit(tx::S_MOVE);
        }
        break;
      }
      case T_MARQUEE: {
        int px = clampi((int)std::floor(dx), 0, doc.w), py = clampi((int)std::floor(dy), 0, doc.h);
        if (e == FL_PUSH) {
          dragging = true;
          ax = px; ay = py;
          drag_mode = !doc.sel.empty() && doc.sel.has(px, py) && !shift ? 1 : 0;
          start_rect = doc.sel;
        } else if (e == FL_DRAG && dragging) {
          if (drag_mode == 1) {
            Rect s = start_rect.moved(px - (int)ax, py - (int)ay);
            doc.sel = s;
          } else {
            int w = px - (int)ax, h = py - (int)ay;
            if (shift) {
              int m = std::max(std::abs(w), std::abs(h));
              w = w < 0 ? -m : m;
              h = h < 0 ? -m : m;
            }
            Rect s{std::min((int)ax, (int)ax + w), std::min((int)ay, (int)ay + h), std::abs(w), std::abs(h)};
            doc.sel = inter(s, doc.canvas());
          }
        } else if (e == FL_RELEASE && dragging) {
          dragging = false;
          if (drag_mode == 0 && (doc.sel.w < 2 || doc.sel.h < 2)) doc.sel = {};
          notify();
        }
        break;
      }
      case T_CROP:
        crop_event(e, mx, my, dx, dy);
        break;
      case T_BRUSH:
      case T_ERASER:
        brush_event(e, dx, dy, shift);
        break;
      case T_FILL:
        if (e == FL_PUSH) {
          if (!paintable()) return;
          Layer& l = doc.cur();
          int lx = (int)std::floor(dx) - l.x, ly = (int)std::floor(dy) - l.y;
          Rect a = doc.area(doc.active);
          if (!a.has(lx, ly)) return;
          Img& im = doc.mut(doc.active);
          flood_fill(im, lx, ly, fg, op_[T_FILL] / 100, (int)fill_tol, fill_contig, a);
          touch(l.bounds());
          commit(tx::S_FILL);
        }
        break;
      case T_GRADIENT:
        if (e == FL_PUSH) {
          if (!paintable()) return;
          dragging = true;
          ax = bx = dx; ay = by = dy;
        } else if (e == FL_DRAG && dragging) {
          bx = dx; by = dy;
          if (shift) {   // en pasos de 45°
            double a = std::atan2(by - ay, bx - ax), len = std::hypot(bx - ax, by - ay);
            a = std::round(a / (PI / 4)) * (PI / 4);
            bx = ax + std::cos(a) * len; by = ay + std::sin(a) * len;
          }
        } else if (e == FL_RELEASE && dragging) {
          dragging = false;
          if (std::hypot(bx - ax, by - ay) < 2) break;
          Img& im = doc.mut(doc.active);
          const Layer& l = doc.cur();
          gradient(im, doc.area(doc.active), l.x, l.y, ax, ay, bx, by, fg, bg, op_[T_GRADIENT] / 100, grad_kind == 1);
          touch(l.bounds());
          commit(tx::S_GRADIENT);
        }
        break;
      case T_SHAPE:
        if (e == FL_PUSH) { dragging = true; ax = bx = dx; ay = by = dy; }
        else if (e == FL_DRAG && dragging) {
          bx = dx; by = dy;
          if (shift) {
            double m = std::max(std::fabs(bx - ax), std::fabs(by - ay));
            bx = ax + (bx < ax ? -m : m);
            by = ay + (by < ay ? -m : m);
          }
        } else if (e == FL_RELEASE && dragging) {
          dragging = false;
          Rect b = shape_box();
          if (b.w < 2 || b.h < 2) break;
          static const char* const names[] = {tx::O_RECT, tx::O_ROUNDED, tx::O_ELLIPSE};
          Layer nl = make_layer(names[shape_kind], doc.w, doc.h);
          shape(*nl.img, b, shape_kind, fg);
          add_layer(nl);
          touch(b);
          commit(tx::S_SHAPE);
        }
        break;
      case T_TEXT:
        if (e == FL_PUSH) text_dialog(dx, dy);
        break;
      case T_PICKER:
        if (e == FL_PUSH || e == FL_DRAG) {
          int px = (int)std::floor(dx), py = (int)std::floor(dy);
          uint32_t c;
          if (!sample(px, py, c)) break;
          set_color(c, alt);
        }
        break;
    }
    redraw();
  }

  bool sample(int px, int py, uint32_t& c) {
    if (px < 0 || py < 0 || px >= doc.w || py >= doc.h) return false;
    const uint8_t* p;
    if (pick_all) {
      update_comp();
      p = comp.at(px, py);
    } else {
      const Layer& l = doc.cur();
      int lx = px - l.x, ly = py - l.y;
      if (lx < 0 || ly < 0 || lx >= l.img->w || ly >= l.img->h) return false;
      p = l.img->at(lx, ly);
    }
    if (p[3] == 0) return false;
    c = ((uint32_t)p[0] << 16) | (p[1] << 8) | p[2];
    return true;
  }

  Rect shape_box() const {
    int x0 = iround(std::min(ax, bx)), y0 = iround(std::min(ay, by));
    int x1 = iround(std::max(ax, bx)), y1 = iround(std::max(ay, by));
    return {x0, y0, x1 - x0, y1 - y0};
  }

  void add_layer(const Layer& l) {
    doc.layers.insert(doc.layers.begin() + doc.active + 1, l);
    doc.active++;
    layer_scroll = 0;
  }

  void brush_event(int e, double dx, double dy, bool shift) {
    if (e == FL_PUSH) {
      if (!paintable()) return;
      Layer& l = doc.cur();
      stroke.base = l.img;
      Img& im = doc.mut(doc.active);
      stroke.mask.assign((size_t)im.w * im.h, 0.f);
      stroke.erase = tool == T_ERASER;
      stroke.rgb = fg;
      stroke.size = size_[tool];
      stroke.hard = hard_[tool] / 100;
      stroke.op = op_[tool] / 100;
      stroke.carry = 0;
      double lx = dx - l.x, ly = dy - l.y;
      Rect clip = doc.area(doc.active);
      Rect ch;
      if (shift && has_last) {
        stroke.lx = last_x - l.x;
        stroke.ly = last_y - l.y;
        ch = dab(stroke, im, stroke.lx, stroke.ly, clip);
        ch = unite(ch, stroke_to(stroke, im, lx, ly, clip));
      } else {
        stroke.lx = lx;
        stroke.ly = ly;
        ch = dab(stroke, im, lx, ly, clip);
      }
      stroking = true;
      touch(ch.moved(l.x, l.y));
    } else if (e == FL_DRAG && stroking) {
      Layer& l = doc.cur();
      Img& im = *l.img;
      Rect ch = stroke_to(stroke, im, dx - l.x, dy - l.y, doc.area(doc.active));
      touch(ch.moved(l.x, l.y));
    } else if (e == FL_RELEASE && stroking) {
      stroking = false;
      has_last = true;
      last_x = dx;
      last_y = dy;
      stroke.base.reset();
      stroke.mask.clear();
      stroke.mask.shrink_to_fit();
      commit(tool == T_ERASER ? tx::S_ERASER : tx::S_BRUSH);
    }
  }

  // ---- recortar
  void start_crop() {
    crop_on = true;
    crop = doc.canvas();
    apply_ratio();
    view_dirty = true;
  }
  double ratio() const {
    static const double r[] = {0, 1, 4 / 3.0, 3 / 2.0, 16 / 9.0, 0};
    if (crop_ratio == 5) return (double)doc.w / doc.h;
    return r[clampi(crop_ratio, 0, 5)];
  }
  // La proporción elegida, centrada en el recorte que hay.
  void apply_ratio() {
    double r = ratio();
    if (r > 0 && crop_on) {
      if (doc.w / (double)doc.h > r) { crop.h = doc.h; crop.w = iround(doc.h * r); }
      else { crop.w = doc.w; crop.h = iround(doc.w / r); }
      crop.x = (doc.w - crop.w) / 2;
      crop.y = (doc.h - crop.h) / 2;
    }
    view_dirty = true;
    redraw();
  }
  void apply_crop() {
    if (!crop_on || crop.empty()) return;
    if (crop == doc.canvas()) { cancel_crop(); return; }
    crop_doc(doc, crop);
    crop_on = false;
    need_fit = true;
    touch_all();
    commit(tx::S_CROP);
    if (tool == T_CROP) start_crop();
  }
  void cancel_crop() {
    crop_on = false;
    view_dirty = true;
    if (tool == T_CROP) start_crop();
    redraw();
  }

  void crop_event(int e, int mx, int my, double dx, double dy) {
    int px = clampi(iround(dx), 0, doc.w), py = clampi(iround(dy), 0, doc.h);
    if (e == FL_PUSH) {
      if (Fl::event_clicks() && crop.has(px, py)) { Fl::event_clicks(0); apply_crop(); return; }
      if (!crop_on) start_crop();
      drag_mode = 0;
      auto hs = crop_handles();
      static const int edge[8] = {1 | 4, 4, 2 | 4, 2, 2 | 8, 8, 1 | 8, 1};   // izq 1, der 2, arriba 4, abajo 8
      for (int k = 0; k < 8; k++)
        if (std::abs(mx - hs[k].first) <= 8 && std::abs(my - hs[k].second) <= 8) drag_mode = 16 | edge[k];
      if (!drag_mode && crop.has(px, py)) drag_mode = 32;
      ax = px; ay = py;
      start_rect = crop;
      dragging = true;
    } else if (e == FL_DRAG && dragging) {
      Rect r = start_rect;
      double rt = ratio();
      if (drag_mode == 32) {
        r.x = clampi(start_rect.x + px - (int)ax, 0, doc.w - r.w);
        r.y = clampi(start_rect.y + py - (int)ay, 0, doc.h - r.h);
      } else if (drag_mode & 16) {
        int x0 = r.x, y0 = r.y, x1 = r.r(), y1 = r.b();
        if (drag_mode & 1) x0 = std::min(px, x1 - 1);
        if (drag_mode & 2) x1 = std::max(px, x0 + 1);
        if (drag_mode & 4) y0 = std::min(py, y1 - 1);
        if (drag_mode & 8) y1 = std::max(py, y0 + 1);
        if (rt > 0) {
          int w = x1 - x0, h = y1 - y0;
          if ((drag_mode & 12) && !(drag_mode & 3)) w = iround(h * rt);
          else h = iround(w / rt);
          if (drag_mode & 1) x0 = x1 - w; else x1 = x0 + w;
          if (drag_mode & 4) y0 = y1 - h; else y1 = y0 + h;
        }
        r = inter(Rect{x0, y0, x1 - x0, y1 - y0}, doc.canvas());
      } else {
        int w = px - (int)ax, h = py - (int)ay;
        if (rt > 0) {
          int ah = iround(std::abs(w) / rt);
          h = h < 0 ? -ah : ah;
        }
        r = inter(Rect{std::min((int)ax, (int)ax + w), std::min((int)ay, (int)ay + h), std::abs(w), std::abs(h)}, doc.canvas());
      }
      if (r.w >= 1 && r.h >= 1) crop = r;
      view_dirty = true;
    } else if (e == FL_RELEASE) {
      dragging = false;
    }
  }

  // ================================================== el teclado
  int handle(int e) override {
    switch (e) {
      case FL_ENTER:
        update_cursor();
        return 1;
      case FL_LEAVE:
        hover_x = hover_y = -10000;
        set_cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_FOCUS:
        return 1;
      case FL_UNFOCUS:
        space = false;
        return 1;
      case FL_MOVE:
        hover_x = Fl::event_x();
        hover_y = Fl::event_y();
        update_cursor();
        redraw();
        return 1;
      case FL_PUSH: {
        take_focus();
        hover_x = Fl::event_x();
        hover_y = Fl::event_y();
        capture = nullptr;
        for (int i = (int)hots.size() - 1; i >= 0; i--)
          if (hots[i].r.has(hover_x, hover_y)) {
            capture = hots[i].fn;
            break;
          }
        if (capture) {
          auto c = capture;
          c(FL_PUSH, hover_x, hover_y);
        }
        redraw();
        return 1;
      }
      case FL_DRAG:
        hover_x = Fl::event_x();
        hover_y = Fl::event_y();
        if (capture) {
          auto c = capture;
          c(FL_DRAG, hover_x, hover_y);
        }
        redraw();
        return 1;
      case FL_RELEASE:
        if (capture) {
          auto c = capture;
          capture = nullptr;
          c(FL_RELEASE, Fl::event_x(), Fl::event_y());
        }
        redraw();
        return 1;
      case FL_MOUSEWHEEL:
        wheel();
        return 1;
      case FL_KEYDOWN:
        return key(Fl::event_key(), true);
      case FL_KEYUP:
        return key(Fl::event_key(), false);
      case FL_DND_ENTER:
      case FL_DND_DRAG:
      case FL_DND_LEAVE:
      case FL_DND_RELEASE:
        return 1;
      case FL_PASTE:
        pasted();
        return 1;
    }
    return Fl_Widget::handle(e);
  }

  void wheel() {
    int mx = Fl::event_x(), my = Fl::event_y();
    int dx = Fl::event_dx(), dy = Fl::event_dy();
    if (dlg) return;
    if (L.canvas.has(mx, my)) {
      if (Fl::event_state(FL_COMMAND | FL_CTRL | FL_ALT)) {
        set_zoom(zoom * std::pow(1.15, -(dy ? dy : dx)), mx, my);
      } else {
        cx += dx * 24 / zoom;
        cy += dy * 24 / zoom;
        clamp_pan();
        view_dirty = true;
        redraw();
      }
    } else if (L.layers.has(mx, my)) {
      layer_scroll += dy * 20;
      redraw();
    } else if (L.history.has(mx, my)) {
      hist_scroll += dy * 20;
      redraw();
    }
  }

  void set_cursor(Fl_Cursor c) {
    if ((int)c == last_cursor || !window()) return;
    last_cursor = (int)c;
    window()->cursor(c);
  }
  void update_cursor() {
    if (!L.canvas.has(hover_x, hover_y) || dlg) { set_cursor(FL_CURSOR_DEFAULT); return; }
    int t = space ? T_HAND : tool;
    switch (t) {
      case T_HAND: set_cursor(FL_CURSOR_MOVE); break;
      case T_MOVE: set_cursor(FL_CURSOR_MOVE); break;
      case T_TEXT: set_cursor(FL_CURSOR_INSERT); break;
      case T_ZOOM: set_cursor(FL_CURSOR_HAND); break;
      default: set_cursor(FL_CURSOR_CROSS); break;
    }
  }

  int key(int k, bool down) {
    if (dlg) return down ? dialog_key(k) : 1;
    if (k == ' ') {
      if (space != down) {
        space = down;
        last_cursor = -1;
        update_cursor();
        redraw();
      }
      return 1;
    }
    if (!down) return 0;
    if (Fl::event_state(FL_COMMAND | FL_CTRL | FL_ALT | FL_META)) return 0;   // los atajos del menú
    return command_key(k) ? 1 : 0;
  }

  bool command_key(int k) {
    if (k >= 'A' && k <= 'Z') k += 'a' - 'A';
    for (int t = 0; t < T_COUNT; t++)
      if (k == TOOL_KEYS[t]) { set_tool(t); return true; }
    switch (k) {
      case 'd': fg = 0x000000; bg = 0xffffff; sync_picker(); redraw(); return true;
      case 'x': std::swap(fg, bg); sync_picker(); redraw(); return true;
      case '[': case ']': {
        int t = tool == T_ERASER ? T_ERASER : T_BRUSH;
        double s = size_[t];
        double step = s < 10 ? 1 : s < 50 ? 5 : s < 100 ? 10 : 25;
        size_[t] = clampd(k == '[' ? s - step : s + step, 1, 500);
        redraw();
        return true;
      }
      case FL_Enter:
      case FL_KP_Enter:
        if (crop_on && tool == T_CROP) { apply_crop(); return true; }
        return false;
      case FL_Escape:
        if (tool == T_CROP && crop_on) { cancel_crop(); return true; }
        if (!doc.sel.empty()) { command(C_DESELECT); return true; }
        return true;   // Esc no cierra la ventana
      case FL_Delete:
      case FL_BackSpace:
        command(C_CLEAR);
        return true;
      case FL_Left: case FL_Right: case FL_Up: case FL_Down:
        if (tool == T_MOVE) {
          int s = Fl::event_state(FL_SHIFT) ? 10 : 1;
          Layer& l = doc.cur();
          Rect old = l.bounds();
          if (k == FL_Left) l.x -= s;
          if (k == FL_Right) l.x += s;
          if (k == FL_Up) l.y -= s;
          if (k == FL_Down) l.y += s;
          touch(unite(old, l.bounds()));
          commit(tx::S_MOVE);
          return true;
        }
        return false;
    }
    return false;
  }

  int dialog_key(int k) {
    if (Fl::event_state(FL_COMMAND | FL_CTRL)) return 0;   // los atajos del menú
    if (k == FL_Escape) { dialog_cancel(); return 1; }
    if (k == FL_Enter || k == FL_KP_Enter) { dialog_ok(); return 1; }
    Dialog& D = *dlg;
    if (k == FL_Tab) {
      int n = (int)D.f.size();
      for (int s = 1; s <= n; s++) {
        int i = ((D.focus < 0 ? -1 : D.focus) + s + n) % n;
        if (D.f[i].kind == Field::NUMBER || D.f[i].kind == Field::TEXT) { D.focus = i; break; }
      }
      redraw();
      return 1;
    }
    if (D.focus < 0) return 1;
    Field& f = D.f[D.focus];
    int i = D.focus;
    bool changed = false;
    if (k == FL_BackSpace) {
      pop_utf8(f.s);
      changed = true;
    } else if (f.kind == Field::NUMBER && (k == FL_Up || k == FL_Down)) {
      f.v = clampd(f.v + (k == FL_Up ? 1 : -1), f.lo, f.hi);
      f.s = std::to_string((int)f.v);
      changed = true;
    } else {
      int del = 0;
      if (Fl::compose(del)) {
        std::string t = Fl::event_text();
        while (del-- > 0) pop_utf8(f.s);
        if (f.kind == Field::NUMBER) {
          std::string keep;
          for (char c : t) if ((c >= '0' && c <= '9')) keep += c;
          t = keep;
          if (f.s.size() + t.size() > 6) t.clear();
        } else if (f.s.size() + t.size() > 200) {
          t.clear();
        }
        f.s += t;
        changed = !t.empty() || del;
      }
    }
    if (changed) {
      if (f.kind == Field::NUMBER) f.v = f.s.empty() ? 0 : std::atof(f.s.c_str());
      if (D.change) D.change(i);
      redraw();
    }
    return 1;
  }

  void tick(double dt) {
    ants++;
    if (toast_t > 0) {
      toast_t -= dt;
      if (toast_t <= 0) toast.clear();
    }
    if (!doc.sel.empty() || dlg || toast_t > 0) redraw();
  }

  // ================================================== los comandos (menú)
  bool confirm_discard() {
    if (!dirty || shooting) return true;
    fl_message_title(tx::APP);
    return fl_choice("%s", tx::CANCEL, tx::DISCARD, nullptr, tx::ASK_DISCARD) == 1;
  }

  void open_path(const std::string& p) {
    Doc d;
    std::string err;
    if (!open_doc(p, d, err)) {
      say(fmt(tx::ERR_OPEN, {base_name(p), err}), true);
      return;
    }
    set_doc(std::move(d), base_name(p), p, tx::S_OPEN);
    say(fmt(tx::MSG_OPENED, {base_name(p), std::to_string(doc.w), std::to_string(doc.h)}));
  }

  void place_path(const std::string& p) {
    Doc d;
    std::string err;
    if (!open_doc(p, d, err)) {
      say(fmt(tx::ERR_OPEN, {base_name(p), err}), true);
      return;
    }
    Img im = flatten(d);
    Layer l;
    l.name = strip_ext(base_name(p));
    l.x = (doc.w - im.w) / 2;
    l.y = (doc.h - im.h) / 2;
    l.img = std::make_shared<Img>(std::move(im));
    add_layer(l);
    touch_all();
    commit(tx::S_PLACE);
  }

  std::string choose_open(const char* title) {
    Fl_Native_File_Chooser c;
    c.title(title);
    c.type(Fl_Native_File_Chooser::BROWSE_FILE);
    std::string f = std::string(tx::F_IMAGES) + "\t*.{png,jpg,jpeg,bmp,gif,svg,dmi}\n" + tx::F_ALL_FILES + "\t*";
    c.filter(f.c_str());
    if (c.show() != 0) return "";
    return c.filename() ? c.filename() : "";
  }

  void save_as() {
    Fl_Native_File_Chooser c;
    c.title(tx::SAVE_TITLE);
    c.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    // En el orden de Format: PNG, JPEG, BMP y el proyecto.
    std::string flt = std::string("PNG\t*.png\nJPEG\t*.jpg\nBMP\t*.bmp\n") + tx::F_PROJECT + " (DMI)\t*.dmi";
    c.filter(flt.c_str());
    int f = path.empty() ? (doc.layers.size() > 1 ? F_DMI : F_PNG) : std::max(0, format_of(path));
    c.filter_value(f);
    c.preset_file((strip_ext(name) + "." + format_ext(f)).c_str());
    c.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM | Fl_Native_File_Chooser::NEW_FOLDER);
    if (c.show() != 0 || !c.filename()) return;
    std::string p = c.filename();
    if (format_of(p) < 0) p += std::string(".") + format_ext(clampi(c.filter_value(), 0, F_COUNT - 1));
    write_to(p);
  }

  void write_to(const std::string& p) {
    if (format_of(p) == F_JPEG) {
      jpeg_dialog(p);
      return;
    }
    finish_write(p, 90);
  }

  void finish_write(const std::string& p, int quality) {
    std::string err;
    if (!save_doc(p, doc, quality, err)) {
      say(fmt(tx::ERR_SAVE, {base_name(p), err}), true);
      return;
    }
    path = p;
    name = base_name(p);
    dirty = false;
    notify();
    std::string msg = fmt(tx::MSG_SAVED, {name});
    if (format_of(p) != F_DMI && doc.layers.size() > 1) msg += " · " + std::string(tx::MSG_FLAT);
    say(msg);
  }

  void jpeg_dialog(const std::string& p) {
    base = doc;
    dlg.reset(new Dialog);
    dlg->title = tx::JPEG_TITLE;
    dlg->f = {f_slider(tx::F_QUALITY, 85, 1, 100), f_info("")};
    auto est = [this] {
      size_t n = jpeg::encode(flatten(doc), (int)dlg->f[0].v).size();
      dlg->f[1].s = fmt(tx::F_EST_SIZE, {num(n / 1024.0, n < 102400 ? 1 : 0)});
    };
    est();
    dlg->change = [est](int) { est(); };
    dlg->ok = [this, p] {
      int q = (int)dlg->f[0].v;
      dlg.reset();
      finish_write(p, q);
      return true;
    };
    dlg->ok_label = tx::SAVE;
  }

  void hex_dialog() {
    dlg.reset(new Dialog);
    dlg->title = tx::HEX_TITLE;
    dlg->f = {f_text(tx::F_HEX, hex(edit_bg ? bg : fg).substr(1)), f_info(tx::F_HEX_HINT)};
    dlg->focus = 0;
    dlg->ok = [this] {
      std::string s = dlg->f[0].s;
      if (!s.empty() && s[0] == '#') s.erase(0, 1);
      if (s.size() == 3) s = std::string{s[0], s[0], s[1], s[1], s[2], s[2]};
      char* end = nullptr;
      unsigned long v = std::strtoul(s.c_str(), &end, 16);
      if (s.size() != 6 || !end || *end) return false;
      dlg.reset();
      set_color((uint32_t)v, edit_bg);
      return true;
    };
  }

  void text_dialog(double dx, double dy) {
    if (shooting && !fl_display_ready()) return;
    base = doc;
    int x0 = iround(dx), y0 = iround(dy);
    dlg.reset(new Dialog);
    dlg->title = tx::TEXT_TITLE;
    dlg->f = {f_text(tx::F_TEXT, tx::TEXT_DEFAULT), f_choice(tx::F_FONT, {"Sans", "Serif", "Mono"}, text_font),
              f_slider(tx::O_SIZE, text_size, 8, 400, 0, "px", true), f_check(tx::O_BOLD, text_bold)};
    dlg->focus = 0;
    auto run = [this, x0, y0] {
      doc = base;
      const auto& f = dlg->f;
      if (f[0].s.empty()) { touch_all(); return; }
      static const Fl_Font fonts[3][2] = {{FL_HELVETICA, FL_HELVETICA_BOLD}, {FL_TIMES, FL_TIMES_BOLD}, {FL_COURIER, FL_COURIER_BOLD}};
      int fi = clampi((int)f[1].v, 0, 2);
      Fl_Font font = fonts[fi][f[3].v ? 1 : 0];
      int size = std::max(4, iround(f[2].v));
      Layer l;
      l.name = f[0].s.size() > 40 ? f[0].s.substr(0, 40) : f[0].s;
      l.img = std::make_shared<Img>(render_text(f[0].s, font, size, fg));
      l.x = x0 - size / 4 - 2;
      l.y = y0 - size / 4 - 2 - size / 2;
      add_layer(l);
      touch_all();
    };
    dlg->change = [run](int) { run(); };
    dlg->ok = [this, run] {
      const auto& f = dlg->f;
      text_font = (int)f[1].v;
      text_size = f[2].v;
      text_bold = f[3].v != 0;
      bool empty = f[0].s.empty();
      run();
      dlg.reset();
      if (!empty) commit(tx::S_TEXT);
      return true;
    };
    dlg->cancel = [this] { doc = base; touch_all(); };
    run();
  }

  void new_dialog() {
    dlg.reset(new Dialog);
    dlg->title = tx::NEW_TITLE;
    dlg->f = {f_number(tx::F_WIDTH, 1920, 1, 16000, "px"), f_number(tx::F_HEIGHT, 1080, 1, 16000, "px"),
              f_choice(tx::F_BACKGROUND, {tx::BG_WHITE, tx::BG_TRANSPARENT, tx::BG_COLOR}, 0)};
    dlg->focus = 0;
    dlg->ok = [this] {
      auto f = dlg->f;
      int w = clampi((int)f[0].v, 1, 16000), h = clampi((int)f[1].v, 1, 16000);
      if (f[0].v < 1 || f[1].v < 1) return false;
      dlg.reset();
      if (!confirm_discard()) return true;
      Doc d;
      d.w = w;
      d.h = h;
      int k = (int)f[2].v;
      d.layers.push_back(k == 1 ? make_layer(tx::LAYER_1, w, h) : make_layer(tx::BACKGROUND, w, h, k == 0 ? 0xffffff : bg, 255));
      set_doc(d, fmt(tx::UNTITLED, {std::to_string(++untitled)}), "", tx::S_NEW);
      return true;
    };
  }

  void image_size_dialog() {
    int w0 = doc.w, h0 = doc.h;
    doc_dialog(
        tx::L_IMAGE_SIZE,
        {f_info(fmt(tx::F_NOW, {std::to_string(w0), std::to_string(h0)})), f_number(tx::F_WIDTH, w0, 1, 16000, "px"),
         f_number(tx::F_HEIGHT, h0, 1, 16000, "px"), f_check(tx::F_KEEP, true),
         f_choice(tx::F_RESAMPLE, {tx::RS_NEAREST, tx::RS_BILINEAR, tx::RS_BICUBIC}, 2)},
        [](Doc& d, const std::vector<Field>& f) {
          int w = clampi((int)f[1].v, 1, 16000), h = clampi((int)f[2].v, 1, 16000);
          if (w != d.w || h != d.h) resize_doc(d, w, h, (int)f[4].v);
        },
        false,
        [w0, h0](int i, std::vector<Field>& f) {
          if (!f[3].v) return;
          if (i == 1 && f[1].v > 0) { f[2].v = std::max(1, iround(f[1].v * h0 / w0)); f[2].s = std::to_string((int)f[2].v); }
          if (i == 2 && f[2].v > 0) { f[1].v = std::max(1, iround(f[2].v * w0 / h0)); f[1].s = std::to_string((int)f[1].v); }
          if (i == 3 && f[3].v) { f[2].v = std::max(1, iround(f[1].v * h0 / w0)); f[2].s = std::to_string((int)f[2].v); }
        });
    dlg->focus = 1;
  }

  void canvas_size_dialog() {
    doc_dialog(tx::L_CANVAS_SIZE,
               {f_info(fmt(tx::F_NOW, {std::to_string(doc.w), std::to_string(doc.h)})),
                f_number(tx::F_WIDTH, doc.w, 1, 16000, "px"), f_number(tx::F_HEIGHT, doc.h, 1, 16000, "px"),
                f_anchor(tx::F_ANCHOR, 4)},
               [](Doc& d, const std::vector<Field>& f) {
                 int w = clampi((int)f[1].v, 1, 16000), h = clampi((int)f[2].v, 1, 16000);
                 canvas_size(d, w, h, (int)f[3].v);
               },
               false);
    dlg->focus = 1;
  }

  void layer_dialog() {
    base = doc;
    dlg.reset(new Dialog);
    dlg->title = tx::LAYER_TITLE;
    std::vector<std::string> modes;
    for (int i = 0; i < B_COUNT; i++) modes.push_back(blend_name(i));
    const Layer& l = doc.cur();
    dlg->f = {f_text(tx::F_NAME, l.name), f_slider(tx::O_OPACITY, l.opacity * 100, 0, 100, 0, "%"),
              f_choice(tx::F_MODE, modes, l.blend)};
    dlg->focus = 0;
    auto run = [this] {
      doc = base;
      Layer& c = doc.cur();
      c.name = dlg->f[0].s.empty() ? c.name : dlg->f[0].s;
      c.opacity = dlg->f[1].v / 100;
      c.blend = (int)dlg->f[2].v;
      touch_all();
    };
    dlg->change = [run](int) { run(); };
    dlg->ok = [this, run] { run(); dlg.reset(); commit(tx::S_LAYER_PROPS); return true; };
    dlg->cancel = [this] { doc = base; touch_all(); };
  }

  void copy_sel(bool cut) {
    const Layer& l = doc.cur();
    Rect a = doc.area(doc.active);
    if (a.empty()) { say(tx::MSG_NOTHING, true); return; }
    clip = crop_img(*l.img, a);
    has_clip = true;
    if (!shooting) {
      // También al portapapeles del sistema (como imagen).
      Fl_Copy_Surface cs(clip.w, clip.h);
      Fl_Surface_Device::push_current(&cs);
      Img flat = on_color(clip, 0xffffff);
      Fl_RGB_Image im(flat.px.data(), flat.w, flat.h, 4);
      im.draw(0, 0);
      Fl_Surface_Device::pop_current();
    }
    if (cut) {
      Img& im = doc.mut(doc.active);
      each_px(im, a, [](uint8_t* p) { p[3] = 0; });
      touch(doc.cur().bounds());
      commit(tx::S_CUT);
    } else {
      say(tx::MSG_COPIED);
    }
  }

  void paste_img(Img im, const std::string& nm) {
    Layer l;
    l.name = nm;
    Rect at = doc.sel.empty() ? doc.canvas() : doc.sel;
    l.x = at.x + (at.w - im.w) / 2;
    l.y = at.y + (at.h - im.h) / 2;
    l.img = std::make_shared<Img>(std::move(im));
    add_layer(l);
    touch_all();
    commit(tx::S_PASTE);
  }

  // Lo que llega del portapapeles o de arrastrar archivos a la ventana.
  void pasted() {
    if (std::strcmp(Fl::event_clipboard_type(), Fl::clipboard_image) == 0) {
      auto* im = static_cast<Fl_RGB_Image*>(Fl::event_clipboard());
      Img o;
      if (im && from_fl(im, o)) paste_img(std::move(o), tx::S_PASTE);
      delete im;
      return;
    }
    std::string t = Fl::event_text() ? std::string(Fl::event_text(), Fl::event_length()) : "";
    std::string first = t.substr(0, t.find_first_of("\r\n"));
    if (first.rfind("file://", 0) == 0) {
      first = first.substr(7);
      std::string dec;
      for (size_t i = 0; i < first.size(); i++) {
        if (first[i] == '%' && i + 2 < first.size()) {
          dec += (char)std::strtol(first.substr(i + 1, 2).c_str(), nullptr, 16);
          i += 2;
        } else {
          dec += first[i];
        }
      }
      first = dec;
    }
    if (first.empty()) return;
    if (format_of(first) < 0 && ext_of(first) != "gif" && ext_of(first) != "svg" && ext_of(first) != "jpeg" &&
        ext_of(first) != "xpm" && ext_of(first) != "pnm" && ext_of(first) != "ppm" && ext_of(first) != "ico")
      return;
    if (!confirm_discard()) return;
    open_path(first);
  }

  void command(int c) {
    if (dlg && c != C_FIT && c != C_ZOOM_IN && c != C_ZOOM_OUT && c != C_ACTUAL) return;
    if (stroking || dragging) return;
    Doc& d = doc;
    switch (c) {
      case C_NEW: new_dialog(); break;
      case C_OPEN: {
        if (!confirm_discard()) break;
        std::string p = choose_open(tx::OPEN_TITLE);
        if (!p.empty()) open_path(p);
        break;
      }
      case C_PLACE: {
        std::string p = choose_open(tx::PLACE_TITLE);
        if (!p.empty()) place_path(p);
        break;
      }
      case C_SAVE:
        if (path.empty() || format_of(path) < 0) save_as();
        else write_to(path);
        break;
      case C_SAVE_AS: save_as(); break;
      case C_SAMPLE:
        if (confirm_discard()) open_sample();
        break;
      case C_UNDO: undo(); break;
      case C_REDO: redo(); break;
      case C_CUT: copy_sel(true); break;
      case C_COPY: copy_sel(false); break;
      case C_PASTE:
        if (has_clip) paste_img(clip, tx::S_PASTE);
        else if (!shooting && Fl::clipboard_contains(Fl::clipboard_image)) Fl::paste(*this, 1, Fl::clipboard_image);
        else say(tx::MSG_EMPTY_CLIP, true);
        break;
      case C_CLEAR: {
        if (d.sel.empty()) { say(tx::MSG_NO_SEL, true); break; }
        if (!paintable()) break;
        Img& im = d.mut(d.active);
        each_px(im, d.area(d.active), [](uint8_t* p) { p[3] = 0; });
        touch(d.cur().bounds());
        commit(tx::S_CLEAR);
        break;
      }
      case C_FILL: {
        if (!paintable()) break;
        Img& im = d.mut(d.active);
        uint32_t col_ = fg;
        each_px(im, d.area(d.active), [col_](uint8_t* p) { p[0] = col_ >> 16; p[1] = col_ >> 8; p[2] = col_; p[3] = 255; });
        touch(d.cur().bounds());
        commit(tx::S_FILL);
        break;
      }
      case C_SELECT_ALL: d.sel = d.canvas(); redraw(); notify(); break;
      case C_DESELECT: d.sel = {}; redraw(); notify(); break;
      case C_IMAGE_SIZE: image_size_dialog(); break;
      case C_CANVAS_SIZE: canvas_size_dialog(); break;
      case C_CROP_SEL:
        if (d.sel.empty()) { say(tx::MSG_NO_SEL, true); break; }
        crop_doc(d, d.sel);
        need_fit = true;
        touch_all();
        commit(tx::S_CROP);
        break;
      case C_ROT_CW: case C_ROT_CCW: case C_ROT_180:
        rotate_doc(d, c == C_ROT_CW ? 1 : c == C_ROT_CCW ? 3 : 2);
        need_fit = true;
        touch_all();
        commit(c == C_ROT_CW ? tx::L_ROT_CW : c == C_ROT_CCW ? tx::L_ROT_CCW : tx::L_ROT_180);
        break;
      case C_ROT_ANY:
        doc_dialog(tx::L_ROT_ANY, {f_slider(tx::F_ANGLE, 15, -180, 180, 1, "°")},
                   [](Doc& dd, const std::vector<Field>& f) { if (f[0].v != 0) rotate_any(dd, f[0].v); }, true);
        dlg->change(0);
        break;
      case C_FLIP_H: case C_FLIP_V:
        flip_doc(d, c == C_FLIP_H);
        touch_all();
        commit(c == C_FLIP_H ? tx::L_FLIP_H : tx::L_FLIP_V);
        break;
      case C_BRIGHT:
        adjust(tx::L_BRIGHT, {f_slider(tx::F_BRIGHTNESS, 0, -150, 150), f_slider(tx::F_CONTRAST, 0, -100, 100)},
               [](Img& im, Rect r, const std::vector<Field>& f) { brightness_contrast(im, r, f[0].v, f[1].v); });
        break;
      case C_HUESAT:
        adjust(tx::L_HUESAT,
               {f_slider(tx::F_HUE, 0, -180, 180, 0, "°"), f_slider(tx::F_SATURATION, 0, -100, 100),
                f_slider(tx::F_LIGHTNESS, 0, -100, 100)},
               [](Img& im, Rect r, const std::vector<Field>& f) { hue_sat(im, r, f[0].v, f[1].v, f[2].v); });
        break;
      case C_LEVELS:
        adjust(tx::L_LEVELS,
               {f_histo(), f_slider(tx::F_IN_BLACK, 0, 0, 253), f_slider(tx::F_GAMMA, 1, 0.1, 9.99, 2, "", true),
                f_slider(tx::F_IN_WHITE, 255, 2, 255), f_slider(tx::F_OUT_BLACK, 0, 0, 255),
                f_slider(tx::F_OUT_WHITE, 255, 0, 255)},
               [](Img& im, Rect r, const std::vector<Field>& f) { levels(im, r, f[1].v, f[2].v, f[3].v, f[4].v, f[5].v); });
        if (dlg) dlg->histo = histogram(*base.cur().img, base.area(base.active));
        break;
      case C_GRAY: case C_SEPIA: case C_INVERT: case C_EDGES: case C_EMBOSS: {
        if (!paintable()) break;
        Img& im = d.mut(d.active);
        Rect a = d.area(d.active);
        if (c == C_GRAY) grayscale(im, a);
        else if (c == C_SEPIA) sepia(im, a);
        else if (c == C_INVERT) invert(im, a);
        else if (c == C_EDGES) find_edges(im, a);
        else emboss(im, a);
        touch(d.cur().bounds());
        commit(c == C_GRAY ? tx::L_GRAY : c == C_SEPIA ? tx::L_SEPIA : c == C_INVERT ? tx::L_INVERT
               : c == C_EDGES ? tx::L_EDGES : tx::L_EMBOSS);
        break;
      }
      case C_THRESHOLD:
        adjust(tx::L_THRESHOLD, {f_histo(), f_slider(tx::F_LEVEL, 128, 1, 255)},
               [](Img& im, Rect r, const std::vector<Field>& f) { threshold(im, r, (int)f[1].v); });
        if (dlg) dlg->histo = histogram(*base.cur().img, base.area(base.active));
        break;
      case C_POSTERIZE:
        adjust(tx::L_POSTERIZE, {f_slider(tx::F_LEVELS, 4, 2, 32)},
               [](Img& im, Rect r, const std::vector<Field>& f) { posterize(im, r, (int)f[0].v); });
        break;
      case C_BLUR:
        adjust(tx::L_BLUR, {f_slider(tx::F_RADIUS, 4, 0.1, 100, 1, "px", true)},
               [](Img& im, Rect r, const std::vector<Field>& f) { gaussian(im, r, f[0].v); });
        break;
      case C_SHARPEN:
        adjust(tx::L_SHARPEN,
               {f_slider(tx::F_AMOUNT, 100, 1, 500, 0, "%"), f_slider(tx::F_RADIUS, 1.5, 0.1, 50, 1, "px", true),
                f_slider(tx::F_THRESHOLD, 0, 0, 255)},
               [](Img& im, Rect r, const std::vector<Field>& f) { unsharp(im, r, f[0].v, f[1].v, (int)f[2].v); });
        break;
      case C_NOISE:
        adjust(tx::L_NOISE, {f_slider(tx::F_AMOUNT, 12, 0, 100, 0, "%"), f_check(tx::F_MONO, true)},
               [](Img& im, Rect r, const std::vector<Field>& f) { add_noise(im, r, f[0].v, f[1].v != 0, 1234); });
        break;
      case C_PIXELATE: {
        int ox = d.cur().x, oy = d.cur().y;
        adjust(tx::L_PIXELATE, {f_slider(tx::F_CELL, 12, 2, 200, 0, "px", true)},
               [ox, oy](Img& im, Rect r, const std::vector<Field>& f) { pixelate(im, r, (int)f[0].v, ox, oy); });
        break;
      }
      case C_VIGNETTE: {
        int ox = d.cur().x, oy = d.cur().y, cw = d.w, ch = d.h;
        adjust(tx::L_VIGNETTE, {f_slider(tx::F_AMOUNT, 50, 0, 100, 0, "%"), f_slider(tx::F_SIZE, 40, 0, 95, 0, "%")},
               [=](Img& im, Rect r, const std::vector<Field>& f) { vignette(im, r, f[0].v, f[1].v, ox, oy, cw, ch); });
        break;
      }
      case C_LAYER_NEW: {
        int n = 1;
        for (const auto& l : d.layers) {
          int k = 0;
          if (std::sscanf(l.name.c_str(), (std::string(tx::LAYER_N_PREFIX) + "%d").c_str(), &k) == 1) n = std::max(n, k + 1);
        }
        add_layer(make_layer(fmt(tx::LAYER_N, {std::to_string(n)}), d.w, d.h));
        touch_all();
        commit(tx::S_LAYER_NEW);
        break;
      }
      case C_LAYER_DUP: {
        Layer l = d.cur();
        l.name = fmt(tx::LAYER_COPY, {l.name});
        add_layer(l);
        touch_all();
        commit(tx::S_LAYER_DUP);
        break;
      }
      case C_LAYER_DEL:
        if (d.layers.size() <= 1) { say(tx::MSG_LAST_LAYER, true); break; }
        d.layers.erase(d.layers.begin() + d.active);
        d.active = clampi(d.active - 1, 0, (int)d.layers.size() - 1);
        touch_all();
        commit(tx::S_LAYER_DEL);
        break;
      case C_LAYER_UP: case C_LAYER_DOWN: {
        int j = d.active + (c == C_LAYER_UP ? 1 : -1);
        if (j < 0 || j >= (int)d.layers.size()) break;
        std::swap(d.layers[d.active], d.layers[j]);
        d.active = j;
        touch_all();
        commit(c == C_LAYER_UP ? tx::S_LAYER_UP : tx::S_LAYER_DOWN);
        break;
      }
      case C_MERGE:
        if (d.active == 0) break;
        merge_down(d, d.active);
        touch_all();
        commit(tx::S_MERGE);
        break;
      case C_FLATTEN:
        flatten_doc(d);
        touch_all();
        commit(tx::S_FLATTEN);
        break;
      case C_LAYER_PROPS: layer_dialog(); break;
      case C_ZOOM_IN: zoom_center(true); break;
      case C_ZOOM_OUT: zoom_center(false); break;
      case C_FIT: fit_view(); break;
      case C_ACTUAL: set_zoom(1, L.canvas.x + L.canvas.w / 2.0, L.canvas.y + L.canvas.h / 2.0); break;
      case C_GRID:
        grid = !grid;
        view_dirty = true;
        break;
    }
    redraw();
    notify();
  }
};

}  // namespace ie

// ============================================================ pruebas
// Sin ventana: DMS_IMAGE_SELFTEST=1. Girar, voltear, fusionar, el historial,
// cambiar el tamaño, recortar, los ajustes y filtros, pintar y los archivos
// (PNG, JPEG, BMP y .dmi de ida y vuelta).
namespace ie {

int fails = 0;
void check(bool ok, const char* what) {
  if (ok) return;
  std::printf("FAIL %s\n", what);
  fails++;
}
bool same(const Img& a, const Img& b) { return a.w == b.w && a.h == b.h && a.px == b.px; }
int max_diff(const Img& a, const Img& b) {
  if (a.w != b.w || a.h != b.h) return 999;
  int m = 0;
  for (size_t i = 0; i < a.px.size(); i++) m = std::max(m, std::abs(a.px[i] - b.px[i]));
  return m;
}
Img noise_img(int w, int h, uint32_t seed, bool opaque) {
  Rng r(seed);
  Img im(w, h);
  for (auto& v : im.px) v = (uint8_t)(r.u() & 255);
  if (opaque)
    for (size_t i = 3; i < im.px.size(); i += 4) im.px[i] = 255;
  return im;
}
std::string temp_dir() {
  const char* t = fl_getenv("TMPDIR");
  if (!t) t = fl_getenv("TEMP");
  if (!t) t = fl_getenv("TMP");
  std::string d = t ? t : ".";
  while (d.size() > 1 && (d.back() == '/' || d.back() == '\\')) d.pop_back();
  return d;
}

int selftest() {
  // 1. Girar y voltear, píxel a píxel.
  Img a = noise_img(37, 23, 7, false);
  check(same(rot90(rot90(rot90(rot90(a, true), true), true), true), a), "rot90 x4");
  check(same(rot90(rot90(a, true), false), a), "rot90 cw+ccw");
  check(same(flip(flip(a, true), true), a), "flip x2");
  Img r1 = rot90(a, true);
  check(r1.w == 23 && r1.h == 37 && std::memcmp(r1.at(22, 0), a.at(0, 0), 4) == 0, "rot90 cw");
  Doc d;
  d.w = 40;
  d.h = 30;
  d.layers.push_back(make_layer("bg", 40, 30, 0xffffff, 255));
  Layer red = make_layer("red", 10, 5, 0xff0000, 255);
  red.x = 3;
  red.y = 4;
  d.layers.push_back(red);
  Img f0 = flatten(d);
  {
    Doc x = d;
    for (int i = 0; i < 4; i++) rotate_doc(x, 1);
    check(same(flatten(x), f0), "rotate_doc x4");
    x = d; rotate_doc(x, 1); rotate_doc(x, 3);
    check(same(flatten(x), f0), "rotate_doc cw+ccw");
    x = d; rotate_doc(x, 2); rotate_doc(x, 2);
    check(same(flatten(x), f0), "rotate_doc 180 x2");
    x = d; flip_doc(x, true); flip_doc(x, true); flip_doc(x, false); flip_doc(x, false);
    check(same(flatten(x), f0), "flip_doc");
    x = d; rotate_doc(x, 1);
    Img f = flatten(x);
    check(x.w == 30 && x.h == 40, "rotate_doc size");
    check(f.at(25, 3)[0] == 255 && f.at(25, 3)[1] == 0 && f.at(26, 3)[1] == 255, "rotate_doc pixel");
  }
  // 2. Fusión de capas.
  {
    Doc m;
    m.w = m.h = 4;
    m.layers.push_back(make_layer("b", 4, 4, 0x0000ff, 255));
    Layer t = make_layer("r", 4, 4, 0xff0000, 255);
    t.opacity = 0.5;
    m.layers.push_back(t);
    Img f = flatten(m);
    const uint8_t* p = f.at(1, 1);
    check(std::abs(p[0] - 128) <= 1 && p[1] == 0 && std::abs(p[2] - 128) <= 1 && p[3] == 255, "normal 50%");
    m.layers[0] = make_layer("b", 4, 4, 0x808080, 255);
    m.layers[1] = make_layer("o", 4, 4, 0xff8000, 255);
    m.layers[1].blend = B_MULTIPLY;
    f = flatten(m);
    p = f.at(0, 0);
    check(std::abs(p[0] - 128) <= 1 && std::abs(p[1] - 64) <= 1 && p[2] == 0, "multiply");
    m.layers[1].blend = B_SCREEN;
    f = flatten(m);
    p = f.at(0, 0);
    check(p[0] == 255 && std::abs(p[1] - 192) <= 1 && std::abs(p[2] - 128) <= 1, "screen");
    m.layers[1].blend = B_DIFFERENCE;
    f = flatten(m);
    p = f.at(0, 0);
    check(std::abs(p[0] - 127) <= 1 && std::abs(p[1] - 0) <= 1 && std::abs(p[2] - 128) <= 1, "difference");
    m.layers[1].visible = false;
    f = flatten(m);
    check(f.at(0, 0)[0] == 128, "hidden layer");
    Doc e;
    e.w = e.h = 2;
    e.layers.push_back(make_layer("t", 2, 2));
    check(flatten(e).at(0, 0)[3] == 0, "transparent");
  }
  // 3. Historial: las capas que no cambian se comparten.
  {
    Doc h;
    h.w = h.h = 8;
    h.layers.push_back(make_layer("a", 8, 8, 0x112233, 255));
    h.layers.push_back(make_layer("b", 8, 8));
    History hs;
    hs.reset(h, "abrir");
    h.mut(1).at(0, 0)[3] = 200;
    hs.push(h, "pintar");
    check(hs.steps[0].doc.layers[1].img->at(0, 0)[3] == 0, "cow: old intact");
    check(hs.steps[0].doc.layers[0].img == hs.steps[1].doc.layers[0].img, "cow: shared");
    check(hs.bytes() == 8 * 8 * 4 * 3, "history bytes");
    hs.cur--;
    check(hs.can_redo() && !hs.can_undo(), "undo state");
    hs.push(hs.steps[0].doc, "otra");
    check(hs.steps.size() == 2 && !hs.can_redo(), "redo cut");
    for (int i = 0; i < 80; i++) hs.push(h, "x");
    check((int)hs.steps.size() <= History::MAX_STEPS, "history limit");
  }
  // 4. Cambiar el tamaño.
  {
    Img s(50, 30, 0x3366cc, 255);
    for (int m : {RS_NEAREST, RS_BILINEAR, RS_BICUBIC}) {
      Img r = resample(s, 17, 91, m);
      bool flat = r.w == 17 && r.h == 91;
      for (size_t i = 0; i < r.px.size(); i += 4)
        if (std::abs(r.px[i] - 0x33) > 1 || std::abs(r.px[i + 2] - 0xcc) > 1 || r.px[i + 3] < 254) flat = false;
      check(flat, "resample flat");
    }
    Img big = resample(noise_img(64, 64, 5, true), 640, 640, RS_BICUBIC);
    Img back = resample(big, 64, 64, RS_BILINEAR);
    check(back.w == 64 && back.h == 64, "resample up/down");
    Doc x = d;
    resize_doc(x, 80, 60, RS_BILINEAR);
    check(x.w == 80 && x.h == 60 && x.layers[1].x == 6 && x.layers[1].img->w == 20, "resize_doc");
  }
  // 5. Recortar y tamaño del lienzo.
  {
    Doc c = d;
    crop_doc(c, {2, 2, 10, 10});
    check(c.w == 10 && c.h == 10 && c.layers[1].x == 1 && c.layers[1].y == 2 && c.layers[1].img->w == 9 &&
              c.layers[1].img->h == 5, "crop_doc");
    c = d;
    canvas_size(c, 60, 50, 4);
    Img f = flatten(c);
    check(c.w == 60 && c.h == 50 && c.layers[0].x == 10 && c.layers[0].y == 10, "canvas_size");
    check(f.at(0, 0)[3] == 0 && f.at(10, 10)[3] == 255, "canvas_size border");
    c = d;
    canvas_size(c, 20, 20, 0);
    check(c.w == 20 && c.layers[0].img->w == 20 && c.layers[0].img->h == 20, "canvas_size smaller");
  }
  // 6. Girar un ángulo cualquiera.
  {
    Doc g = d;
    rotate_any(g, 30);
    int ew = (int)std::ceil(40 * std::cos(PI / 6) + 30 * 0.5 - 1e-6);
    Img f = flatten(g);
    check(g.w == ew && f.at(0, 0)[3] == 0 && f.at(g.w / 2, g.h / 2)[3] == 255, "rotate_any");
  }
  // 7. Ajustes.
  {
    Img src = noise_img(20, 20, 3, true), b = src;
    brightness_contrast(b, b.rect(), 0, 0);
    check(same(src, b), "brightness neutral");
    b = src; levels(b, b.rect(), 0, 1, 255);
    check(same(src, b), "levels neutral");
    b = src; hue_sat(b, b.rect(), 0, 0, 0);
    check(max_diff(src, b) <= 1, "hue/sat neutral");
    b = src; hue_sat(b, b.rect(), 360, 0, 0);
    check(max_diff(src, b) <= 1, "hue 360");
    b = src; invert(b, b.rect()); invert(b, b.rect());
    check(same(src, b), "invert x2");
    b = src; threshold(b, b.rect(), 128);
    bool bw = true;
    for (size_t i = 0; i < b.px.size(); i += 4) if ((b.px[i] != 0 && b.px[i] != 255) || b.px[i] != b.px[i + 1]) bw = false;
    check(bw, "threshold");
    b = src; posterize(b, b.rect(), 2);
    bool two = true;
    for (size_t i = 0; i < b.px.size(); i += 4) if (b.px[i] != 0 && b.px[i] != 255) two = false;
    check(two, "posterize");
    b = src; grayscale(b, b.rect());
    check(b.at(3, 3)[0] == b.at(3, 3)[2], "grayscale");
    b = src; brightness_contrast(b, b.rect(), 60, 0);
    check(b.at(4, 4)[0] >= src.at(4, 4)[0], "brighter");
    b = src; invert(b, {5, 5, 3, 3});
    check(std::memcmp(b.at(0, 0), src.at(0, 0), 4) == 0 && b.at(6, 6)[0] == 255 - src.at(6, 6)[0], "only the area");
    std::vector<int> hh = histogram(Img(10, 10, 0x808080, 255), {0, 0, 10, 10});
    check(hh[128] == 100, "histogram");
  }
  // 8. Filtros.
  {
    Img s(40, 40, 0x808080, 255), b = blurred(s, 5);
    check(std::abs(b.at(20, 20)[0] - 128) <= 1 && b.at(0, 0)[3] == 255, "blur flat");
    Img e(40, 10, 0x000000, 255);
    for (int y = 0; y < 10; y++)
      for (int x = 20; x < 40; x++) put(e.at(x, y), 0xffffff);
    Img eb = blurred(e, 3);
    check(eb.at(19, 5)[0] > 40 && eb.at(19, 5)[0] < 215 && eb.at(2, 5)[0] < 5, "blur edge");
    Img p = noise_img(30, 30, 9, true);
    pixelate(p, p.rect(), 10, 0, 0);
    check(std::memcmp(p.at(0, 0), p.at(9, 9), 4) == 0 && std::memcmp(p.at(10, 0), p.at(19, 9), 4) == 0, "pixelate");
    Img f(20, 20, 0x808080, 255);
    find_edges(f, f.rect());
    check(f.at(10, 10)[0] == 255, "edges flat");
    Img u(20, 20, 0x808080, 255);
    unsharp(u, u.rect(), 200, 2, 0);
    check(u.at(10, 10)[0] == 128, "unsharp flat");
    Img v(40, 40, 0xffffff, 255);
    vignette(v, v.rect(), 100, 20, 0, 0, 40, 40);
    check(v.at(20, 20)[0] == 255 && v.at(0, 0)[0] < 40, "vignette");
    Img n(30, 30, 0x808080, 255);
    add_noise(n, n.rect(), 50, true, 7);
    check(n.at(3, 3)[0] == n.at(3, 3)[2] && max_diff(n, Img(30, 30, 0x808080, 255)) > 10, "noise");
  }
  // 9. Pintar.
  {
    Img c(20, 20, 0xffffff, 255);
    for (int x = 0; x < 20; x++) put(c.at(x, 10), 0x000000);
    check(flood_fill(c, 2, 2, 0xff0000, 1, 10, true, c.rect()) == 200, "fill contiguous");
    check(c.at(5, 15)[1] == 255, "fill stops at the line");
    check(flood_fill(c, 2, 15, 0x00ff00, 1, 10, false, c.rect()) == 180, "fill global");
    check(flood_fill(c, 2, 2, 0x0000ff, 1, 10, true, {0, 0, 5, 5}) == 25, "fill clip");
    Img t(50, 50);
    Stroke s;
    s.base = std::make_shared<Img>(t);
    s.mask.assign(50 * 50, 0);
    s.rgb = 0x0000ff; s.size = 10; s.hard = 1; s.op = 1; s.lx = 10; s.ly = 25;
    dab(s, t, 10, 25, t.rect());
    stroke_to(s, t, 40, 25, t.rect());
    check(t.at(25, 25)[2] == 255 && t.at(25, 25)[3] == 255 && t.at(25, 10)[3] == 0, "brush");
    s.erase = true;
    s.base = std::make_shared<Img>(t);
    s.mask.assign(50 * 50, 0);
    s.lx = 25; s.ly = 25;
    dab(s, t, 25, 25, t.rect());
    check(t.at(25, 25)[3] == 0 && t.at(12, 25)[3] == 255, "eraser");
    Img o(50, 50);
    Stroke h;
    h.base = std::make_shared<Img>(o);
    h.mask.assign(50 * 50, 0);
    h.rgb = 0xff0000; h.size = 20; h.hard = 1; h.op = 0.5; h.lx = 5; h.ly = 25;
    dab(h, o, 5, 25, o.rect());
    stroke_to(h, o, 45, 25, o.rect());
    stroke_to(h, o, 5, 25, o.rect());
    check(std::abs(o.at(25, 25)[3] - 128) <= 1, "opacity does not pile up");
    Img g(10, 1);
    gradient(g, g.rect(), 0, 0, 0, 0, 10, 0, 0x000000, 0xffffff, 1, false);
    check(g.at(0, 0)[0] < 20 && g.at(9, 0)[0] > 235 && g.at(9, 0)[3] == 255, "gradient");
    Img sh(40, 40);
    shape(sh, {10, 10, 20, 20}, 2, 0xff0000);
    check(sh.at(20, 20)[3] == 255 && sh.at(10, 10)[3] == 0, "ellipse");
    Img sr(40, 40);
    shape(sr, {10, 10, 20, 20}, 0, 0xff0000);
    check(sr.at(10, 10)[3] == 255 && sr.at(30, 30)[3] == 0, "rectangle");
  }
  // 10. Combinar y acoplar.
  {
    Doc m = d;
    m.layers[1].opacity = 0.5;
    Img before = flatten(m);
    merge_down(m, 1);
    check(m.layers.size() == 1 && max_diff(flatten(m), before) <= 1, "merge down");
    Doc fl = d;
    flatten_doc(fl);
    check(fl.layers.size() == 1 && fl.layers[0].img->w == 40 && same(flatten(fl), f0), "flatten");
  }
  // 11. Archivos de ida y vuelta.
  {
    std::string dir = temp_dir();
    Doc t;
    t.w = 64;
    t.h = 48;
    Layer bgl = make_layer(tx::BACKGROUND, 64, 48, 0, 255);
    for (int y = 0; y < 48; y++)
      for (int x = 0; x < 64; x++) {
        uint8_t* p = bgl.img->at(x, y);
        p[0] = (uint8_t)(x * 4); p[1] = (uint8_t)(y * 5); p[2] = 128;
      }
    t.layers.push_back(bgl);
    Layer top = make_layer("Ñandú", 20, 10, 0xff0000, 200);
    top.x = 5; top.y = 6; top.opacity = 0.7; top.blend = B_SCREEN;
    t.layers.push_back(top);
    t.active = 1;
    Img ref = flatten(t);
    std::string err;
    std::string png = dir + "/dms_ie_test.png", jpg = dir + "/dms_ie_test.jpg", bmp = dir + "/dms_ie_test.bmp",
                dmi = dir + "/dms_ie_test.dmi";
    Doc o;
    check(save_doc(png, t, 90, err) && open_doc(png, o, err), "png save/open");
    check(o.w == 64 && o.h == 48 && o.layers.size() == 1 && same(*o.layers[0].img, ref), "png pixels");
    Doc od;
    check(save_doc(dmi, t, 90, err) && open_doc(dmi, od, err), "dmi save/open");
    check(od.layers.size() == 2 && od.active == 1 && od.layers[1].x == 5 && od.layers[1].blend == B_SCREEN &&
              std::fabs(od.layers[1].opacity - 0.7) < 1e-3 && od.layers[1].name == "Ñandú", "dmi layers");
    check(same(flatten(od), ref), "dmi pixels");
    Doc ob;
    check(save_doc(bmp, t, 90, err) && open_doc(bmp, ob, err), "bmp save/open");
    check(ob.w == 64 && same(*ob.layers[0].img, on_color(ref, 0xffffff)), "bmp pixels");
    Doc oj;
    check(save_doc(jpg, t, 95, err) && open_doc(jpg, oj, err), "jpeg save/open");
    if (oj.layers.size() == 1 && oj.w == 64 && oj.h == 48) {
      Img want = on_color(ref, 0xffffff);
      double sum = 0;
      for (size_t i = 0; i < want.px.size(); i++)
        if (i % 4 != 3) sum += std::abs(want.px[i] - oj.layers[0].img->px[i]);
      double mean = sum / (64 * 48 * 3);
      std::printf("jpeg: mean error %.2f\n", mean);
      check(mean < 4, "jpeg quality");
    } else {
      check(false, "jpeg size");
    }
    Img wide = noise_img(333, 77, 4, true);
    check(jpeg::encode(wide, 10).size() < jpeg::encode(wide, 95).size(), "jpeg size by quality");
    std::string bytes = dmi_bytes(t);
    Doc bad;
    check(!dmi_parse(bytes.substr(0, bytes.size() / 2), bad) && !dmi_parse("PNG...", bad), "dmi damaged");
    check(!open_doc(dir + "/no_such_file.png", bad, err), "missing file");
    for (const auto& f : {png, jpg, bmp, dmi}) std::remove(f.c_str());
    check(format_of("a/b.JPG") == F_JPEG && format_of("x.png") == F_PNG && format_of("x") < 0, "formats");
  }
  // 12. La imagen de ejemplo.
  {
    Img sc = sample_scene(320, 200), pm = sample_palm(320, 200);
    int opaque = 0;
    for (size_t i = 3; i < pm.px.size(); i += 4) opaque += pm.px[i] > 128;
    check(sc.at(10, 10)[3] == 255 && opaque > 500 && opaque < 320 * 200 / 2, "sample image");
  }
  std::printf("selftest %s fails=%d\n", fails ? "FAILED" : "ok", fails);
  std::fflush(stdout);
  return fails ? 1 : 0;
}

// ------------------------------------------------------------ capturas
// Sin abrir la ventana: DMS_IMAGE_SHOT=<carpeta> deja editor.png, ajustes.png,
// recortar.png y niveles.png (DMS_IMAGE_SHOT_SIZE=1600x1000 para otro tamaño).
void shot(Editor& ed, const std::string& file, int W, int H, const std::vector<std::string>& menus) {
  Fl_Image_Surface surf(W, H, 0);
  Fl_Surface_Device::push_current(&surf);
  const int MB = 25;
  fill({0, 0, W, MB}, 0x2b2b2b);
  int x = 10;
  for (const auto& m : menus) {
    ui_font(13);
    text_in(m, {x, 0, 200, MB}, 0xf0f0f0, -1, 13);
    x += (int)fl_width(m.c_str()) + 22;
  }
  ed.render(0, MB, W, H - MB);
  Fl_RGB_Image* img = surf.image();
  Fl_Surface_Device::pop_current();
  fl_write_png(file.c_str(), img);
  delete img;
}

int shots(const std::string& dir, int W, int H, const std::vector<std::string>& menus) {
  Fl::screen_count();   // abre la conexión con la pantalla, sin ventana
  fl_make_path(dir.c_str());
  std::vector<std::string> bar = menus;
  if (const char* m = fl_getenv("DMS_IMAGE_SHOT_LANG_MENU")) bar.push_back(m);   // el menú Idioma de las demos
  auto fresh = [&](Editor& ed) {
    ed.shooting = true;
    ed.open_sample();
    ed.layout_rects(0, 25, W, H - 25);
    ed.fit_view();
    ed.need_fit = false;
  };
  // 1. El editor con la imagen de ejemplo, unos pasos en el historial y el pincel.
  {
    Editor ed(0, 25, W, H - 25);
    fresh(ed);
    ed.doc.active = 0;
    ed.command(C_LEVELS);
    ed.dlg->f[1].v = 12; ed.dlg->f[2].v = 1.1; ed.dlg->f[3].v = 240;
    ed.dlg->change(1);
    ed.dialog_ok();
    ed.command(C_LAYER_NEW);
    ed.tool = T_BRUSH;
    ed.set_color(0xffd23f);
    // Unas estrellas en la capa nueva.
    Rng r(5);
    for (int i = 0; i < 12; i++) {
      double sx = 130 + r.next() * 1300, sy = 230 + r.next() * 150;
      int mx = iround(ed.sx_of(sx)), my = iround(ed.sy_of(sy));
      ed.size_[T_BRUSH] = 3 + r.next() * 5;
      ed.canvas_event(FL_PUSH, mx, my);
      ed.canvas_event(FL_RELEASE, mx, my);
    }
    ed.size_[T_BRUSH] = 26;
    ed.command(C_LAYER_PROPS);
    ed.dlg->f[0].s = tx::SAMPLE_STARS;
    ed.dlg->f[1].v = 85;
    ed.dlg->change(0);
    ed.dialog_ok();
    ed.doc.active = 0;
    ed.command(C_VIGNETTE);
    ed.dlg->f[0].v = 35;
    ed.dlg->change(0);
    ed.dialog_ok();
    ed.doc.active = 1;
    ed.hover_x = iround(ed.sx_of(1180));
    ed.hover_y = iround(ed.sy_of(300));
    ed.toast.clear();
    shot(ed, dir + "/editor.png", W, H, bar);
  }
  // 2. Tono y saturación con la vista previa, sobre el fondo seleccionado.
  {
    Editor ed(0, 25, W, H - 25);
    fresh(ed);
    ed.doc.active = 0;
    ed.tool = T_MARQUEE;
    ed.doc.sel = {760, 120, 760, 700};
    ed.command(C_HUESAT);
    ed.dlg->f[0].v = -28; ed.dlg->f[1].v = 45; ed.dlg->f[2].v = 3;
    ed.dlg->change(0);
    ed.ants = 1;
    shot(ed, dir + "/ajustes.png", W, H, bar);
  }
  // 3. Recortar a 16:9.
  {
    Editor ed(0, 25, W, H - 25);
    fresh(ed);
    ed.set_tool(T_CROP);
    ed.crop_ratio = 4;
    ed.apply_ratio();
    ed.crop = {300, 140, 1120, 630};
    ed.view_dirty = true;
    shot(ed, dir + "/recortar.png", W, H, bar);
  }
  // 4. Niveles con el histograma, tras dar la vuelta a la imagen y una viñeta.
  {
    Editor ed(0, 25, W, H - 25);
    fresh(ed);
    ed.doc.active = 0;
    ed.command(C_VIGNETTE);
    ed.dialog_ok();
    ed.command(C_LEVELS);
    ed.dlg->f[1].v = 28; ed.dlg->f[2].v = 1.35; ed.dlg->f[3].v = 228;
    ed.dlg->change(1);
    ed.tool = T_PICKER;
    shot(ed, dir + "/niveles.png", W, H, bar);
  }
  std::printf("shots ok %s\n", dir.c_str());
  return 0;
}

// ------------------------------------------------------------ la interfaz, sin ventana
// DMS_IMAGE_UITEST=1 (necesita la pantalla, pero no abre ninguna ventana):
// cada herramienta en el lienzo, cada orden del menú con sus diálogos,
// deshacer y rehacer hasta el principio, y un clic en cada zona de la
// interfaz; tras cada paso se dibuja todo fuera de la pantalla.
int ui_test() {
  Fl::screen_count();
  const int W = 1400, H = 875;
  Editor ed(0, 0, W, H);
  ed.shooting = true;
  ed.open_sample();
  int steps = 0;
  auto draw = [&] {
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    ed.render(0, 0, W, H);
    Fl_Surface_Device::pop_current();
    steps++;
  };
  auto drag = [&](double x0, double y0, double x1, double y1) {
    int a = iround(ed.sx_of(x0)), b = iround(ed.sy_of(y0));
    ed.canvas_event(FL_PUSH, a, b);
    for (int k = 1; k <= 6; k++)
      ed.canvas_event(FL_DRAG, iround(ed.sx_of(x0 + (x1 - x0) * k / 6)), iround(ed.sy_of(y0 + (y1 - y0) * k / 6)));
    ed.canvas_event(FL_RELEASE, iround(ed.sx_of(x1)), iround(ed.sy_of(y1)));
    draw();
  };
  draw();
  const int layers0 = (int)ed.doc.layers.size();
  // Las herramientas en el lienzo.
  for (int t = 0; t < T_COUNT; t++) {
    ed.set_tool(t);
    draw();
    size_t before = ed.hist.steps.size();
    drag(400, 300, 700, 520);
    if (ed.dlg) {   // el texto abre su diálogo
      ed.dlg->f[0].s = "Hola";
      ed.dlg->change(0);
      ed.dialog_ok();
      draw();
    }
    bool paints = t == T_MOVE || t == T_BRUSH || t == T_ERASER || t == T_FILL || t == T_GRADIENT || t == T_SHAPE ||
                  t == T_TEXT;
    if (paints && ed.hist.steps.size() <= before) std::printf("FAIL tool %d left no step\n", t), fails++;
  }
  check((int)ed.doc.layers.size() == layers0 + 2, "shape and text layers");
  // Recortar con la herramienta.
  ed.set_tool(T_CROP);
  ed.crop = {100, 100, 800, 500};
  ed.apply_crop();
  draw();
  check(ed.doc.w == 800 && ed.doc.h == 500, "crop tool");
  // Cada orden del menú (salvo las de archivos, que abren diálogos del sistema).
  ed.doc.sel = {50, 50, 300, 200};
  for (int c = C_UNDO; c <= C_GRID; c++) {
    if (c == C_UNDO || c == C_REDO) continue;
    ed.command(c);
    draw();
    if (ed.dlg) {
      for (int i = 0; i < (int)ed.dlg->f.size(); i++)
        if (ed.dlg->change) ed.dlg->change(i);
      draw();
      ed.dialog_ok();
      if (ed.dlg) ed.dialog_cancel();
      draw();
    }
    if (ed.doc.layers.empty() || ed.doc.active < 0 || ed.doc.active >= (int)ed.doc.layers.size())
      std::printf("FAIL command %d broke the layers\n", c), fails++;
    if (c == C_CROP_SEL) ed.doc.sel = {10, 10, 100, 80};
  }
  // Deshacer hasta el principio y rehacer hasta el final.
  int n = (int)ed.hist.steps.size();
  while (ed.hist.can_undo()) { ed.undo(); draw(); }
  check(ed.doc.w == 1600 && ed.doc.h == 1000 && (int)ed.doc.layers.size() == layers0, "undo to start");
  while (ed.hist.can_redo()) { ed.redo(); draw(); }
  check(ed.hist.cur == n - 1, "redo to end");
  // Un clic en cada zona que responde (el lienzo aparte).
  ed.command(C_SAMPLE);
  ed.set_tool(T_BRUSH);
  draw();
  for (int i = 0; i < 400; i++) {
    if (i >= (int)ed.hots.size()) break;
    Hot h = ed.hots[i];
    if (h.r == ed.L.canvas || h.r == ed.L.all) continue;
    int x = h.r.x + h.r.w / 2, y = h.r.y + h.r.h / 2;
    h.fn(FL_PUSH, x, y);
    h.fn(FL_DRAG, x + 3, y);
    h.fn(FL_RELEASE, x + 3, y);
    if (ed.dlg) { draw(); ed.dialog_cancel(); }
    draw();
  }
  check(!ed.doc.layers.empty(), "clicks");
  std::printf("uitest %s steps=%d history=%d\n", fails ? "FAILED" : "ok", steps, (int)ed.hist.steps.size());
  std::fflush(stdout);
  return fails ? 1 : 0;
}

}  // namespace ie

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  ie::Editor* ed = nullptr;
  std::chrono::steady_clock::time_point last;
  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  struct Item {
    const char* path;
    int cmd, key;
  };
  static const std::vector<Item>& items() {
    using namespace ie;
    static const std::vector<Item> v = {
        {tx::MP_NEW, C_NEW, FL_COMMAND + 'n'}, {tx::MP_OPEN, C_OPEN, FL_COMMAND + 'o'},
        {tx::MP_PLACE, C_PLACE, FL_COMMAND + FL_SHIFT + 'o'}, {tx::MP_SAVE, C_SAVE, FL_COMMAND + 's'},
        {tx::MP_SAVE_AS, C_SAVE_AS, FL_COMMAND + FL_SHIFT + 's'}, {tx::MP_SAMPLE, C_SAMPLE, 0},
        {tx::MP_UNDO, C_UNDO, FL_COMMAND + 'z'}, {tx::MP_REDO, C_REDO, FL_COMMAND + FL_SHIFT + 'z'},
        {tx::MP_CUT, C_CUT, FL_COMMAND + 'x'}, {tx::MP_COPY, C_COPY, FL_COMMAND + 'c'},
        {tx::MP_PASTE, C_PASTE, FL_COMMAND + 'v'}, {tx::MP_CLEAR, C_CLEAR, 0},
        {tx::MP_FILL, C_FILL, FL_ALT + FL_BackSpace}, {tx::MP_SELECT_ALL, C_SELECT_ALL, FL_COMMAND + 'a'},
        {tx::MP_DESELECT, C_DESELECT, FL_COMMAND + 'd'}, {tx::MP_IMAGE_SIZE, C_IMAGE_SIZE, FL_COMMAND + FL_ALT + 'i'},
        {tx::MP_CANVAS_SIZE, C_CANVAS_SIZE, FL_COMMAND + FL_ALT + 'c'}, {tx::MP_CROP_SEL, C_CROP_SEL, 0},
        {tx::MP_ROT_CW, C_ROT_CW, 0}, {tx::MP_ROT_CCW, C_ROT_CCW, 0}, {tx::MP_ROT_180, C_ROT_180, 0},
        {tx::MP_ROT_ANY, C_ROT_ANY, 0}, {tx::MP_FLIP_H, C_FLIP_H, 0}, {tx::MP_FLIP_V, C_FLIP_V, 0},
        {tx::MP_BRIGHT, C_BRIGHT, 0}, {tx::MP_HUESAT, C_HUESAT, FL_COMMAND + 'u'},
        {tx::MP_LEVELS, C_LEVELS, FL_COMMAND + 'l'}, {tx::MP_GRAY, C_GRAY, FL_COMMAND + FL_SHIFT + 'u'},
        {tx::MP_SEPIA, C_SEPIA, 0}, {tx::MP_INVERT, C_INVERT, FL_COMMAND + 'i'}, {tx::MP_THRESHOLD, C_THRESHOLD, 0},
        {tx::MP_POSTERIZE, C_POSTERIZE, 0}, {tx::MP_LAYER_NEW, C_LAYER_NEW, FL_COMMAND + FL_SHIFT + 'n'},
        {tx::MP_LAYER_DUP, C_LAYER_DUP, FL_COMMAND + 'j'}, {tx::MP_LAYER_DEL, C_LAYER_DEL, 0},
        {tx::MP_LAYER_UP, C_LAYER_UP, FL_COMMAND + ']'}, {tx::MP_LAYER_DOWN, C_LAYER_DOWN, FL_COMMAND + '['},
        {tx::MP_MERGE, C_MERGE, FL_COMMAND + 'e'}, {tx::MP_FLATTEN, C_FLATTEN, 0},
        {tx::MP_LAYER_PROPS, C_LAYER_PROPS, 0}, {tx::MP_BLUR, C_BLUR, 0}, {tx::MP_SHARPEN, C_SHARPEN, 0},
        {tx::MP_NOISE, C_NOISE, 0}, {tx::MP_PIXELATE, C_PIXELATE, 0}, {tx::MP_EDGES, C_EDGES, 0},
        {tx::MP_EMBOSS, C_EMBOSS, 0}, {tx::MP_VIGNETTE, C_VIGNETTE, 0}, {tx::MP_ZOOM_IN, C_ZOOM_IN, FL_COMMAND + '='},
        {tx::MP_ZOOM_OUT, C_ZOOM_OUT, FL_COMMAND + '-'}, {tx::MP_FIT, C_FIT, FL_COMMAND + '0'},
        {tx::MP_ACTUAL, C_ACTUAL, FL_COMMAND + '1'}, {tx::MP_GRID, C_GRID, FL_COMMAND + '\''},
    };
    return v;
  }
  // Los menús de arriba (para las capturas, que no llevan la barra de FLTK).
  static std::vector<std::string> menu_titles() {
    std::vector<std::string> t;
    for (const char* p : {tx::MP_NEW, tx::MP_UNDO, tx::MP_IMAGE_SIZE, tx::MP_LAYER_NEW, tx::MP_BLUR, tx::MP_ZOOM_IN, tx::MP_KEYS}) {
      std::string s = p;
      t.push_back(s.substr(0, s.find('/')));
    }
    return t;
  }

  Form1() {
    if (fl_getenv("DMS_IMAGE_SELFTEST")) std::exit(ie::selftest());
    if (fl_getenv("DMS_IMAGE_UITEST")) {
      set_fonts();
      std::exit(ie::ui_test());
    }
    if (const char* d = fl_getenv("DMS_IMAGE_SHOT")) {
      int W = 1600, H = 1000;
      if (const char* s = fl_getenv("DMS_IMAGE_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
      set_fonts();
      std::exit(ie::shots(d, W, H, menu_titles()));
    }
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

  void form_create() override {
    set_fonts();
    self() = this;
    Workspace->box(FL_NO_BOX);
    Workspace->resizable(nullptr);
    WorkspaceHint->hide();   // el aviso del Diseñador
    Menu1->box(FL_FLAT_BOX);
    Menu1->color(ie::rgb(0x2b2b2b));
    Menu1->textcolor(ie::rgb(0xf0f0f0));
    Menu1->selection_color(ie::rgb(ie::C_ACCENT));
    ed = new ie::Editor(Workspace->x(), Workspace->y(), Workspace->w(), Workspace->h());
    Workspace->add(ed);
    ed->on_state = [this] { sync(); };
    for (const auto& it : items()) mark(it.path, 0, false, it.key);
    mark(tx::MP_FULLSCREEN, 0, false, FL_F + 11);
    mark(tx::MP_QUIT, 0, false, FL_COMMAND + 'q');
    callback(window_cb, this);
    size_range(1000, 660);
    ed->open_sample();
    layout();
    ed->take_focus();
    last = std::chrono::steady_clock::now();
#ifdef __APPLE__
    fl_open_callback(open_cb);
#endif
    if (fl_getenv("DMS_IMAGE_SMOKE")) Fl::add_timeout(2.0, smoke, this);
  }

  static void open_cb(const char* p) {
    Form1* f = self();
    if (f && f->ed && p && f->ed->confirm_discard()) f->ed->open_path(p);
  }

  void resize(int X, int Y, int W, int H) override {
    FormDesign::resize(X, Y, W, H);
    layout();
  }

  void layout() {
    if (!ed) return;
    int top = Menu1->visible() ? Menu1->h() : 0;
    Menu1->resize(0, 0, w(), Menu1->h());
    Workspace->resize(0, top, w(), h() - top);
    ed->resize(0, top, w(), h() - top);
    redraw();
  }

  // ---- el reloj (el Timer del diseño): las hormigas de la selección y los avisos
  void Tick_timer() override {
    auto now = std::chrono::steady_clock::now();
    double dt = std::chrono::duration<double>(now - last).count();
    last = now;
    if (ed) ed->tick(std::min(dt, 0.5));
  }

  // El título (con * si hay cambios sin guardar) y lo que se puede hacer.
  void sync() {
    std::string t = ed->name + (ed->dirty ? " *" : "") + " — " + tx::APP;
    copy_label(t.c_str());
    active(tx::MP_UNDO, ed->hist.can_undo());
    active(tx::MP_REDO, ed->hist.can_redo());
    active(tx::MP_CROP_SEL, !ed->doc.sel.empty());
    active(tx::MP_CLEAR, !ed->doc.sel.empty());
    active(tx::MP_DESELECT, !ed->doc.sel.empty());
    active(tx::MP_MERGE, ed->doc.active > 0);
    active(tx::MP_LAYER_DEL, ed->doc.layers.size() > 1);
    active(tx::MP_FLATTEN, ed->doc.layers.size() > 1);
    mark(tx::MP_GRID, FL_MENU_TOGGLE, ed->grid);
    Menu1->redraw();
  }

  void mark(const char* path, int flags, bool on, int shortcut = 0) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    Menu1->mode(i, (Menu1->mode(i) & (FL_MENU_DIVIDER | FL_MENU_INACTIVE)) | flags | (on ? FL_MENU_VALUE : 0));
    if (shortcut) Menu1->shortcut(i, shortcut);
  }
  void active(const char* path, bool on) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    int m = Menu1->mode(i);
    Menu1->mode(i, on ? (m & ~FL_MENU_INACTIVE) : (m | FL_MENU_INACTIVE));
  }

  static void window_cb(Fl_Widget* w, void* p) {
    auto* f = static_cast<Form1*>(p);
    // Esc es para la herramienta, no para cerrar la ventana.
    if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
    if (f->ed && !f->ed->confirm_discard()) return;
    w->hide();
  }

  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_QUIT) {
      if (ed->confirm_discard()) hide();
      return;
    }
    if (item == tx::MP_FULLSCREEN) {
      if (fullscreen_active()) fullscreen_off();
      else fullscreen();
    } else if (item == tx::MP_KEYS) {
      fl_message_title(tx::L_KEYS);
      fl_message("%s", tx::KEYS_TEXT);
    } else if (item == tx::MP_ABOUT) {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", ie::fmt(tx::ABOUT_TEXT, {v}).c_str());
    } else {
      for (const auto& it : items())
        if (item == it.path) {
          ed->command(it.cmd);
          break;
        }
    }
    sync();
    ed->take_focus();
  }

  // Prueba de humo con la ventana abierta: DMS_IMAGE_SMOKE=1.
  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok layers=%d %dx%d\n", (int)f->ed->doc.layers.size(), f->ed->doc.w, f->ed->doc.h);
    std::fflush(stdout);
    f->hide();
  }
};
''';
