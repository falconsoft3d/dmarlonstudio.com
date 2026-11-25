part of 'tk_examples.dart';

// El código en C++ de Captura y prompt (tk_showcase_cpp_capture.dart): va
// tal cual en Form1.cpp, después de los textos (namespace tx).
const _captureIncludes = r'''#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>
#include <FL/Fl_Copy_Surface.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#include <FL/filename.H>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>
#else
#include <fcntl.h>
#include <spawn.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif
#ifdef __APPLE__
#include <dlfcn.h>
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _captureCode = _captureCore + _captureUi;

const _captureCore = r'''
// ============================================================ el núcleo
// Todo lo que no es la ventana: las marcas y su deshacer, la imagen, el
// dibujo, la sesión del PDF, el prompt y el PDF (escrito a mano).
namespace cp {

// ------------------------------------------------------------ textos
std::string fmt(const std::string& f, const std::vector<std::string>& a) {
  std::string o;
  for (size_t i = 0; i < f.size(); i++) {
    if (f[i] == '{' && i + 2 < f.size() && f[i + 2] == '}' && std::isdigit((unsigned char)f[i + 1])) {
      size_t k = (size_t)(f[i + 1] - '0');
      if (k < a.size()) o += a[k];
      i += 2;
    } else {
      o += f[i];
    }
  }
  return o;
}
std::string trim(const std::string& s) {
  size_t b = s.find_first_not_of(" \t\r\n");
  if (b == std::string::npos) return "";
  size_t e = s.find_last_not_of(" \t\r\n");
  return s.substr(b, e - b + 1);
}
std::vector<std::string> split(const std::string& s, char c) {
  std::vector<std::string> out;
  std::string cur;
  for (char ch : s) {
    if (ch == c) {
      out.push_back(cur);
      cur.clear();
    } else {
      cur += ch;
    }
  }
  out.push_back(cur);
  return out;
}
std::string one_line(const std::string& s) {
  std::string o;
  for (char c : s) o += (c == '\n' || c == '\r' || c == '\t') ? ' ' : c;
  return trim(o);
}

// ------------------------------------------------------------ archivos
#ifdef _WIN32
const char* const SEP = "\\";
std::wstring wide(const std::string& s) {
  unsigned n = fl_utf8towc(s.c_str(), (unsigned)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  fl_utf8towc(s.c_str(), (unsigned)s.size(), &w[0], n + 1);
  return w;
}
#else
const char* const SEP = "/";
#endif
std::string join(const std::string& dir, const std::string& name) {
  if (dir.empty()) return name;
  char last = dir.back();
  return (last == '/' || last == '\\') ? dir + name : dir + SEP + name;
}
std::string base_name(const std::string& p) {
  size_t k = p.find_last_of("/\\");
  return k == std::string::npos ? p : p.substr(k + 1);
}
std::string dir_name(const std::string& p) {
  size_t k = p.find_last_of("/\\");
  return k == std::string::npos ? "." : p.substr(0, k);
}
std::string stem(const std::string& p) {
  size_t k = p.find_last_of('.');
  size_t s = p.find_last_of("/\\");
  return (k == std::string::npos || (s != std::string::npos && k < s)) ? p : p.substr(0, k);
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[16384];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  std::fclose(f);
  return true;
}
bool write_file(const std::string& path, const std::string& data) {
  FILE* f = fl_fopen(path.c_str(), "wb");
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  return std::fclose(f) == 0 && ok;
}
bool exists(const std::string& path) {
  struct stat st;
  return fl_stat(path.c_str(), &st) == 0;
}
bool testing() { return fl_getenv("DMS_CAPTURE_CONFIG") != nullptr; }
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_CAPTURE_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\capture";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/capture";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/capture";
#endif
}
// Las capturas van a Imágenes/«Captura y prompt».
std::string pictures_dir() {
  if (testing()) return join(config_dir(), "captures");
#ifdef _WIN32
  const char* h = fl_getenv("USERPROFILE");
  return std::string(h ? h : ".") + "\\Pictures\\" + tx::DEFAULT_FOLDER;
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Pictures/" + tx::DEFAULT_FOLDER;
#endif
}
struct tm local(long long t) {
  time_t tt = (time_t)t;
  struct tm v;
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  return v;
}
long long now_t() { return (long long)std::time(nullptr); }
// «2026-11-25 21.30.15» (sirve de nombre de archivo en todos los sistemas).
std::string stamp(long long t) {
  struct tm v = local(t);
  char b[40];
  std::strftime(b, sizeof b, "%Y-%m-%d %H.%M.%S", &v);
  return b;
}
std::string date_text(long long t) {
  struct tm v = local(t);
  char b[40];
  std::strftime(b, sizeof b, "%d/%m/%Y %H:%M", &v);
  return b;
}
// Un nombre libre en la carpeta: «Captura 2026-11-25 21.30.15.png», «… (2).png».
std::string free_name(const std::string& dir, const std::string& name, const std::string& ext) {
  std::string p = join(dir, name + ext);
  for (int i = 2; exists(p) && i < 1000; i++) p = join(dir, name + " (" + std::to_string(i) + ")" + ext);
  return p;
}
std::string new_capture_path() {
  fl_make_path(pictures_dir().c_str());
  return free_name(pictures_dir(), fmt(tx::CAPTURE_NAME, {stamp(now_t())}), ".png");
}
// La imagen marcada va al lado: «Captura … -marcada.png» (si ya lo es, la misma).
std::string marked_path(const std::string& src) {
  std::string s = stem(src), suf = tx::MARKED_SUFFIX;
  if (s.size() >= suf.size() && s.compare(s.size() - suf.size(), suf.size(), suf) == 0) return s + ".png";
  return s + suf + ".png";
}

// ------------------------------------------------------------ las marcas
struct Pt {
  double x = 0, y = 0;
};
struct Box {
  double x = 0, y = 0, w = 0, h = 0;
  Box norm() const {
    Box r = *this;
    if (r.w < 0) { r.x += r.w; r.w = -r.w; }
    if (r.h < 0) { r.y += r.h; r.h = -r.h; }
    return r;
  }
  bool empty(double m = 2) const {
    Box n = norm();
    return n.w < m || n.h < m;
  }
  Box clip(const Box& o) const {
    Box a = norm(), b = o.norm();
    double x1 = std::max(a.x, b.x), y1 = std::max(a.y, b.y);
    double x2 = std::min(a.x + a.w, b.x + b.w), y2 = std::min(a.y + a.h, b.y + b.h);
    if (x2 <= x1 || y2 <= y1) return Box{x1, y1, 0, 0};
    return Box{x1, y1, x2 - x1, y2 - y1};
  }
};
enum Tool { T_PEN, T_MARK, T_ARROW, T_LINE, T_RECT, T_OVAL, T_TEXT, T_NUM, T_BLUR, T_CROP, T_COUNT };
struct Shape {
  int tool = T_PEN;
  unsigned color = 0xf23333;  // 0xRRGGBB
  double width = 8;           // el trazo, en píxeles de la imagen
  double font = 40;           // texto y números
  std::vector<Pt> pts;
  std::string text;
  int number = 0;
  Box box() const {
    if (pts.empty()) return {};
    return Box{pts.front().x, pts.front().y, pts.back().x - pts.front().x, pts.back().y - pts.front().y}.norm();
  }
  bool meaningful() const {
    switch (tool) {
      case T_TEXT: return !trim(text).empty() && !pts.empty();
      case T_NUM: return !pts.empty();
      case T_PEN:
      case T_MARK: return pts.size() >= 2;
      case T_ARROW:
      case T_LINE:
        return pts.size() >= 2 && std::hypot(pts.back().x - pts.front().x, pts.back().y - pts.front().y) >= 4;
      default: return pts.size() >= 2 && !box().empty(4);
    }
  }
};
// Las marcas de una imagen, con deshacer y rehacer. El recorte es una marca
// más: vale la última (y deshacerla lo quita).
class Doc {
public:
  Doc(double w = 0, double h = 0) : w_(w), h_(h) {}
  double w() const { return w_; }
  double h() const { return h_; }
  void add(Shape s) {
    shapes_.push_back(std::move(s));
    redo_.clear();
  }
  bool undo() {
    if (shapes_.empty()) return false;
    redo_.push_back(std::move(shapes_.back()));
    shapes_.pop_back();
    return true;
  }
  bool redo() {
    if (redo_.empty()) return false;
    shapes_.push_back(std::move(redo_.back()));
    redo_.pop_back();
    return true;
  }
  bool can_undo() const { return !shapes_.empty(); }
  bool can_redo() const { return !redo_.empty(); }
  void clear() {
    shapes_.clear();
    redo_.clear();
  }
  const std::vector<Shape>& shapes() const { return shapes_; }
  Box crop() const {
    Box full{0, 0, w_, h_};
    for (auto it = shapes_.rbegin(); it != shapes_.rend(); ++it) {
      if (it->tool != T_CROP) continue;
      Box r = it->box().clip(full);
      if (!r.empty()) return r;
    }
    return full;
  }
  bool has_crop() const {
    for (const auto& s : shapes_)
      if (s.tool == T_CROP) return true;
    return false;
  }
  int next_number() const {
    int n = 0;
    for (const auto& s : shapes_)
      if (s.tool == T_NUM) n = std::max(n, s.number);
    return n + 1;
  }

private:
  double w_, h_;
  std::vector<Shape> shapes_, redo_;
};
// La punta de una flecha: el triángulo y dónde acaba el palo.
struct Head {
  Pt tip, left, right, base;
};
Head arrow_head(Pt a, Pt b, double width) {
  double dx = b.x - a.x, dy = b.y - a.y, len = std::hypot(dx, dy);
  if (len < 1e-6) return {b, b, b, b};
  double ux = dx / len, uy = dy / len;
  double hl = std::min(std::max(width * 4.0, 14.0), len * 0.6), hw = hl * 0.55;
  Pt base{b.x - ux * hl, b.y - uy * hl};
  return {b, {base.x - uy * hw, base.y + ux * hw}, {base.x + uy * hw, base.y - ux * hw},
          {b.x - ux * hl * 0.7, b.y - uy * hl * 0.7}};
}
// Mayúsculas: líneas a 45° y formas cuadradas.
Pt constrain(int tool, Pt a, Pt p) {
  double dx = p.x - a.x, dy = p.y - a.y;
  if (tool == T_ARROW || tool == T_LINE) {
    const double q = 3.14159265358979 / 4;
    double ang = std::round(std::atan2(dy, dx) / q) * q, len = std::hypot(dx, dy);
    return {a.x + std::cos(ang) * len, a.y + std::sin(ang) * len};
  }
  double m = std::max(std::fabs(dx), std::fabs(dy));
  return {a.x + (dx < 0 ? -m : m), a.y + (dy < 0 ? -m : m)};
}

// ------------------------------------------------------------ la imagen
// RGB, 3 bytes por píxel, sin relleno.
struct Img {
  int w = 0, h = 0;
  std::vector<unsigned char> px;
  bool empty() const { return w <= 0 || h <= 0 || px.size() < (size_t)w * h * 3; }
};
// De cualquier Fl_Image de FLTK (gris, RGB o con transparencia, sobre blanco).
bool from_fl(const Fl_Image* im, Img& out) {
  if (!im || im->data_w() <= 0 || im->data_h() <= 0 || im->count() != 1 || !im->data()) return false;
  int W = im->data_w(), H = im->data_h(), d = im->d();
  if (d < 1 || d > 4) return false;
  int ld = im->ld() ? im->ld() : W * d;
  const unsigned char* p = (const unsigned char*)im->data()[0];
  out.w = W;
  out.h = H;
  out.px.assign((size_t)W * H * 3, 255);
  for (int y = 0; y < H; y++) {
    const unsigned char* row = p + (size_t)y * ld;
    unsigned char* o = &out.px[(size_t)y * W * 3];
    for (int x = 0; x < W; x++) {
      const unsigned char* s = row + (size_t)x * d;
      unsigned r, g, b, a = 255;
      if (d < 3) {
        r = g = b = s[0];
        if (d == 2) a = s[1];
      } else {
        r = s[0], g = s[1], b = s[2];
        if (d == 4) a = s[3];
      }
      o[x * 3] = (unsigned char)((r * a + 255 * (255 - a)) / 255);
      o[x * 3 + 1] = (unsigned char)((g * a + 255 * (255 - a)) / 255);
      o[x * 3 + 2] = (unsigned char)((b * a + 255 * (255 - a)) / 255);
    }
  }
  return true;
}
bool load_image(const std::string& path, Img& out) {
  Fl_Shared_Image* si = Fl_Shared_Image::get(path.c_str());
  if (!si) return false;
  bool ok = from_fl(si->image() ? si->image() : si, out);
  si->release();   // sin caché: si se cambió en Vista Previa, se lee de nuevo
  return ok;
}
bool save_png(const std::string& path, const Img& im) {
  if (im.empty()) return false;
  fl_make_path(dir_name(path).c_str());
  return fl_write_png(path.c_str(), im.px.data(), im.w, im.h, 3) == 0;
}
// Recortar y reducir (para el PDF: como mucho «max» píxeles de lado).
Img crop_img(const Img& im, const Box& r0) {
  Box r = r0.clip(Box{0, 0, (double)im.w, (double)im.h});
  Img o;
  o.w = (int)std::lround(r.w);
  o.h = (int)std::lround(r.h);
  int x0 = (int)std::lround(r.x), y0 = (int)std::lround(r.y);
  o.w = std::min(o.w, im.w - x0);
  o.h = std::min(o.h, im.h - y0);
  if (o.w <= 0 || o.h <= 0) return Img{};
  o.px.resize((size_t)o.w * o.h * 3);
  for (int y = 0; y < o.h; y++)
    std::memcpy(&o.px[(size_t)y * o.w * 3], &im.px[((size_t)(y + y0) * im.w + x0) * 3], (size_t)o.w * 3);
  return o;
}
Img shrink(const Img& im, int max) {
  int k = 1;
  while (std::max(im.w, im.h) / k > max) k++;
  if (k == 1) return im;
  Img o;
  o.w = im.w / k;
  o.h = im.h / k;
  o.px.resize((size_t)o.w * o.h * 3);
  for (int y = 0; y < o.h; y++)
    for (int x = 0; x < o.w; x++)
      for (int c = 0; c < 3; c++) {
        unsigned s = 0;
        for (int j = 0; j < k; j++)
          for (int i = 0; i < k; i++) s += im.px[((size_t)(y * k + j) * im.w + (x * k + i)) * 3 + c];
        o.px[((size_t)y * o.w + x) * 3 + c] = (unsigned char)(s / (unsigned)(k * k));
      }
  return o;
}

// ------------------------------------------------------------ pixelar
// Bloques del color medio de la imagen (tapan contraseñas, correos, datos).
struct Block {
  Box b;
  unsigned rgb;
};
int block_size(const Img& im) { return std::max(8, std::max(im.w, im.h) / 110); }
std::vector<Block> pixel_blocks(const Img& im, const Box& r0) {
  std::vector<Block> out;
  if (im.empty()) return out;
  Box r = r0.clip(Box{0, 0, (double)im.w, (double)im.h});
  if (r.empty(1)) return out;
  int bs = block_size(im);
  int x0 = (int)std::floor(r.x), y0 = (int)std::floor(r.y);
  int x1 = (int)std::ceil(r.x + r.w), y1 = (int)std::ceil(r.y + r.h);
  for (int by = y0; by < y1; by += bs)
    for (int bx = x0; bx < x1; bx += bs) {
      int ex = std::min(bx + bs, x1), ey = std::min(by + bs, y1);
      unsigned long s[3] = {0, 0, 0}, n = 0;
      for (int y = by; y < ey; y++)
        for (int x = bx; x < ex; x++) {
          const unsigned char* p = &im.px[((size_t)y * im.w + x) * 3];
          s[0] += p[0], s[1] += p[1], s[2] += p[2], n++;
        }
      if (!n) continue;
      unsigned rgb = (unsigned)(s[0] / n) << 16 | (unsigned)(s[1] / n) << 8 | (unsigned)(s[2] / n);
      out.push_back({Box{(double)bx, (double)by, (double)(ex - bx), (double)(ey - by)}, rgb});
    }
  return out;
}

// ------------------------------------------------------------ el resaltador
// FLTK no dibuja líneas transparentes: el trazo se pinta en una imagen RGBA
// (cápsulas con borde suave) y se dibuja encima.
struct Raster {
  int x = 0, y = 0, w = 0, h = 0;
  std::vector<unsigned char> px;   // RGBA
};
Raster raster_stroke(const std::vector<Pt>& pts, double half, unsigned rgb, double alpha) {
  Raster r;
  if (pts.empty()) return r;
  double minx = pts[0].x, maxx = minx, miny = pts[0].y, maxy = miny;
  for (const auto& p : pts) {
    minx = std::min(minx, p.x), maxx = std::max(maxx, p.x);
    miny = std::min(miny, p.y), maxy = std::max(maxy, p.y);
  }
  r.x = (int)std::floor(minx - half - 1);
  r.y = (int)std::floor(miny - half - 1);
  r.w = std::min(12000, (int)std::ceil(maxx + half + 1) - r.x + 1);
  r.h = std::min(12000, (int)std::ceil(maxy + half + 1) - r.y + 1);
  if (r.w <= 0 || r.h <= 0) return Raster{};
  r.px.assign((size_t)r.w * r.h * 4, 0);
  for (size_t i = 0; i < (size_t)r.w * r.h; i++) {
    r.px[i * 4] = (unsigned char)(rgb >> 16);
    r.px[i * 4 + 1] = (unsigned char)(rgb >> 8);
    r.px[i * 4 + 2] = (unsigned char)rgb;
  }
  for (size_t k = 0; k < pts.size(); k++) {
    Pt a = pts[k], b = pts[k + 1 < pts.size() ? k + 1 : k];
    double bx0 = std::min(a.x, b.x) - half - 1, bx1 = std::max(a.x, b.x) + half + 1;
    double by0 = std::min(a.y, b.y) - half - 1, by1 = std::max(a.y, b.y) + half + 1;
    double vx = b.x - a.x, vy = b.y - a.y, vv = vx * vx + vy * vy;
    for (int y = std::max(0, (int)by0 - r.y); y <= std::min(r.h - 1, (int)by1 - r.y); y++)
      for (int x = std::max(0, (int)bx0 - r.x); x <= std::min(r.w - 1, (int)bx1 - r.x); x++) {
        double px = r.x + x + 0.5, py = r.y + y + 0.5;
        double t = vv > 0 ? std::clamp(((px - a.x) * vx + (py - a.y) * vy) / vv, 0.0, 1.0) : 0.0;
        double d = std::hypot(px - (a.x + t * vx), py - (a.y + t * vy));
        double cov = std::clamp(half + 0.5 - d, 0.0, 1.0);
        unsigned char v = (unsigned char)std::lround(cov * alpha * 255);
        unsigned char& dst = r.px[((size_t)y * r.w + x) * 4 + 3];
        if (v > dst) dst = v;
      }
  }
  return r;
}

// ------------------------------------------------------------ dibujar
// Las mismas funciones dibujan el lienzo (escalado) y la imagen final (1:1).
struct View {
  double s = 1, ox = 0, oy = 0;
  double X(double x) const { return ox + x * s; }
  double Y(double y) const { return oy + y * s; }
};
Fl_Color rgb(unsigned c) { return fl_rgb_color((uchar)(c >> 16), (uchar)(c >> 8), (uchar)c); }
bool light(unsigned c) { return 0.299 * (c >> 16 & 255) + 0.587 * (c >> 8 & 255) + 0.114 * (c & 255) > 160; }
// Texto con un halo, para que se lea sobre cualquier fondo.
void halo_text(const char* t, int x, int y, unsigned color, int size) {
  int r = std::max(1, size / 14);
  fl_color(light(color) ? fl_rgb_color(20, 20, 20) : FL_WHITE);
  for (int dy = -r; dy <= r; dy++)
    for (int dx = -r; dx <= r; dx++)
      if (dx || dy) fl_draw(t, x + dx, y + dy);
  fl_color(rgb(color));
  fl_draw(t, x, y);
}
void ellipse_path(double cx, double cy, double rx, double ry) {
  for (int i = 0; i < 96; i++) {
    double a = i * 2 * 3.14159265358979 / 96;
    fl_vertex(cx + rx * std::cos(a), cy + ry * std::sin(a));
  }
}
void draw_shape(const Shape& sh, const Img& base, const View& v, bool preview) {
  if (sh.pts.empty()) return;
  int lw = std::max(1, (int)std::lround(sh.width * v.s));
  const Pt a = sh.pts.front(), b = sh.pts.back();
  fl_color(rgb(sh.color));
  switch (sh.tool) {
    case T_PEN:
      if (sh.pts.size() == 1) {
        fl_pie((int)(v.X(a.x) - lw / 2.0), (int)(v.Y(a.y) - lw / 2.0), lw, lw, 0, 360);
        break;
      }
      fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, lw);
      fl_begin_line();
      for (const auto& p : sh.pts) fl_vertex(v.X(p.x), v.Y(p.y));
      fl_end_line();
      break;
    case T_MARK: {
      std::vector<Pt> dev;
      for (const auto& p : sh.pts) dev.push_back({v.X(p.x), v.Y(p.y)});
      Raster r = raster_stroke(dev, sh.width * 2.2 * v.s, sh.color, 0.38);
      if (!r.px.empty()) {
        Fl_RGB_Image img(r.px.data(), r.w, r.h, 4);
        img.draw(r.x, r.y);
      }
      break;
    }
    case T_LINE:
      fl_line_style(FL_SOLID | FL_CAP_ROUND, lw);
      fl_begin_line();
      fl_vertex(v.X(a.x), v.Y(a.y));
      fl_vertex(v.X(b.x), v.Y(b.y));
      fl_end_line();
      break;
    case T_ARROW: {
      Head hd = arrow_head(a, b, sh.width);
      fl_line_style(FL_SOLID | FL_CAP_ROUND, lw);
      fl_begin_line();
      fl_vertex(v.X(a.x), v.Y(a.y));
      fl_vertex(v.X(hd.base.x), v.Y(hd.base.y));
      fl_end_line();
      fl_line_style(0);
      fl_begin_polygon();
      fl_vertex(v.X(hd.tip.x), v.Y(hd.tip.y));
      fl_vertex(v.X(hd.left.x), v.Y(hd.left.y));
      fl_vertex(v.X(hd.right.x), v.Y(hd.right.y));
      fl_end_polygon();
      break;
    }
    case T_RECT: {
      Box r = sh.box();
      fl_line_style(FL_SOLID | FL_JOIN_ROUND, lw);
      fl_begin_loop();
      fl_vertex(v.X(r.x), v.Y(r.y));
      fl_vertex(v.X(r.x + r.w), v.Y(r.y));
      fl_vertex(v.X(r.x + r.w), v.Y(r.y + r.h));
      fl_vertex(v.X(r.x), v.Y(r.y + r.h));
      fl_end_loop();
      break;
    }
    case T_OVAL: {
      Box r = sh.box();
      fl_line_style(FL_SOLID, lw);
      fl_begin_loop();
      ellipse_path(v.X(r.x + r.w / 2), v.Y(r.y + r.h / 2), r.w * v.s / 2, r.h * v.s / 2);
      fl_end_loop();
      break;
    }
    case T_TEXT: {
      int size = std::max(6, (int)std::lround(sh.font * v.s));
      fl_font(FL_HELVETICA_BOLD, size);
      halo_text(sh.text.c_str(), (int)std::lround(v.X(a.x)), (int)std::lround(v.Y(a.y)) + fl_height() - fl_descent(),
                sh.color, size);
      break;
    }
    case T_NUM: {
      double r = sh.font * 0.8 * v.s;
      int cx = (int)std::lround(v.X(a.x)), cy = (int)std::lround(v.Y(a.y)), ir = std::max(4, (int)std::lround(r));
      fl_pie(cx - ir, cy - ir, 2 * ir, 2 * ir, 0, 360);
      fl_color(FL_WHITE);
      fl_line_style(FL_SOLID, std::max(1, ir / 9));
      fl_begin_loop();
      ellipse_path(cx, cy, ir, ir);
      fl_end_loop();
      fl_line_style(0);
      int size = std::max(6, (int)std::lround(sh.font * v.s));
      fl_font(FL_HELVETICA_BOLD, size);
      std::string n = std::to_string(sh.number);
      fl_color(light(sh.color) ? fl_rgb_color(20, 20, 20) : FL_WHITE);
      fl_draw(n.c_str(), cx - (int)(fl_width(n.c_str()) / 2), cy + fl_height() / 2 - fl_descent());
      break;
    }
    case T_BLUR: {
      if (preview) {
        Box r = sh.box();
        fl_color(fl_rgb_color(120, 120, 128));
        fl_line_style(FL_DASH, 2);
        fl_rect((int)v.X(r.x), (int)v.Y(r.y), (int)(r.w * v.s), (int)(r.h * v.s));
        break;
      }
      for (const auto& bl : pixel_blocks(base, sh.box())) {
        int x0 = (int)std::floor(v.X(bl.b.x)), y0 = (int)std::floor(v.Y(bl.b.y));
        int x1 = (int)std::ceil(v.X(bl.b.x + bl.b.w)), y1 = (int)std::ceil(v.Y(bl.b.y + bl.b.h));
        fl_color(rgb(bl.rgb));
        fl_rectf(x0, y0, x1 - x0, y1 - y0);
      }
      break;
    }
    default: break;   // el recorte se ve aparte y se aplica al guardar
  }
  fl_line_style(0);
}
void draw_shapes(const Doc& d, const Img& base, const View& v, const Shape* cur) {
  for (const auto& s : d.shapes()) draw_shape(s, base, v, false);
  if (cur) draw_shape(*cur, base, v, true);
}
// La imagen final: la captura con sus marcas y el recorte aplicado.
bool render_final(const Doc& d, const Img& base, Img& out) {
  if (base.empty()) return false;
  Box c = d.crop();
  int W = (int)std::lround(c.w), H = (int)std::lround(c.h);
  if (W < 1 || H < 1) return false;
  Fl_Image_Surface surf(W, H, 0);
  Fl_Surface_Device::push_current(&surf);
  fl_color(FL_WHITE);
  fl_rectf(0, 0, W, H);
  int ox = -(int)std::lround(c.x), oy = -(int)std::lround(c.y);
  Fl_RGB_Image bi(base.px.data(), base.w, base.h, 3);
  bi.draw(ox, oy);
  draw_shapes(d, base, View{1.0, (double)ox, (double)oy}, nullptr);
  Fl_RGB_Image* r = surf.image();
  Fl_Surface_Device::pop_current();
  Img tmp;
  bool ok = r && from_fl(r, tmp);
  delete r;
  if (!ok) return false;
  if (tmp.w == W && tmp.h == H) {
    out = std::move(tmp);
    return true;
  }
  // Con la pantalla escalada (Windows al 150 %), al tamaño de la imagen.
  out.w = W;
  out.h = H;
  out.px.resize((size_t)W * H * 3);
  for (int y = 0; y < H; y++)
    for (int x = 0; x < W; x++) {
      int sx = std::min(tmp.w - 1, x * tmp.w / W), sy = std::min(tmp.h - 1, y * tmp.h / H);
      std::memcpy(&out.px[((size_t)y * W + x) * 3], &tmp.px[((size_t)sy * tmp.w + sx) * 3], 3);
    }
  return true;
}

// ------------------------------------------------------------ la sesión
// Las capturas del PDF, cada una con su comentario, y el prompt general.
struct Entry {
  std::string path, comment;
};
struct Session {
  std::string title, prompt;
  std::vector<Entry> entries;
  bool editable = true;
};
std::string esc(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '\\') o += "\\\\";
    else if (c == '\t') o += "\\t";
    else if (c == '\n') o += "\\n";
    else if (c != '\r') o += c;
  }
  return o;
}
std::string unesc(const std::string& s) {
  std::string o;
  for (size_t i = 0; i < s.size(); i++) {
    if (s[i] == '\\' && i + 1 < s.size()) {
      char n = s[++i];
      o += n == 'n' ? '\n' : n == 't' ? '\t' : n;
    } else {
      o += s[i];
    }
  }
  return o;
}
std::string session_text(const Session& s) {
  std::string o = "DMCAPTURE 1\n";
  o += "T\t" + esc(s.title) + "\n";
  o += "P\t" + esc(s.prompt) + "\n";
  o += std::string("X\t") + (s.editable ? "1" : "0") + "\n";
  for (const auto& e : s.entries) o += "E\t" + esc(e.path) + "\t" + esc(e.comment) + "\n";
  return o;
}
bool parse_session(const std::string& text, Session& s) {
  auto lines = split(text, '\n');
  if (lines.empty() || trim(lines[0]) != "DMCAPTURE 1") return false;
  s = Session{};
  for (size_t i = 1; i < lines.size(); i++) {
    auto f = split(lines[i], '\t');
    if (f[0] == "T" && f.size() >= 2) s.title = unesc(f[1]);
    else if (f[0] == "P" && f.size() >= 2) s.prompt = unesc(f[1]);
    else if (f[0] == "X" && f.size() >= 2) s.editable = f[1] != "0";
    else if (f[0] == "E" && f.size() >= 3) s.entries.push_back({unesc(f[1]), unesc(f[2])});
  }
  return true;
}
// El texto para pegar en un asistente: el prompt y cada captura con su ruta.
std::string to_prompt(const Session& s) {
  std::string o, g = trim(s.prompt);
  if (!g.empty()) o += g + "\n\n";
  for (size_t i = 0; i < s.entries.size(); i++) {
    o += "## " + fmt(tx::PAGE_TITLE, {std::to_string(i + 1)}) + "\n";
    o += fmt(tx::PROMPT_IMAGE, {s.entries[i].path}) + "\n";
    std::string c = trim(s.entries[i].comment);
    if (!c.empty()) o += c + "\n";
    o += "\n";
  }
  return trim(o) + "\n";
}

// ------------------------------------------------------------ el PDF
// Escrito a mano: Helvetica (WinAnsi), las imágenes en PNG tal cual (con el
// predictor de PNG, sin descomprimir) y, si se pide, los comentarios como
// campos de formulario que se pueden reescribir en Vista Previa o Acrobat.
const double PW = 842, PH = 595, PM = 32;   // A4 apaisado
// Anchos de Helvetica (milésimas de em) de los caracteres 32 a 126.
const short HELV[95] = {278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
                        556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
                        1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
                        667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
                        333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
                        556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584};
int char_width(unsigned char c) {
  if (c >= 32 && c <= 126) return HELV[c - 32];
  if (c >= 0xC0 && c <= 0xC5) return 667;
  if (c >= 0xC8 && c <= 0xCB) return 667;
  if (c >= 0xCC && c <= 0xCF) return 278;
  if (c >= 0xD2 && c <= 0xD6) return 778;
  if ((c >= 0xD9 && c <= 0xDC) || c == 0xD1 || c == 0xC7) return 722;
  if (c >= 0xEC && c <= 0xEF) return 278;
  if (c == 0xE7) return 500;
  if (c == 0x85 || c == 0x97) return 1000;
  if (c == 0x91 || c == 0x92 || c == 0xB7) return 278;
  if (c == 0x93 || c == 0x94 || c == 0xA1) return 333;
  return 556;
}
double text_width(const std::string& winansi, double size) {
  double w = 0;
  for (unsigned char c : winansi) w += char_width(c);
  return w * size / 1000.0;
}
// UTF-8 → WinAnsi (lo que no cabe, «?»).
std::string winansi(const std::string& s) {
  std::string o;
  const char* p = s.c_str();
  const char* e = p + s.size();
  while (p < e) {
    int len = 1;
    unsigned c = fl_utf8decode(p, e, &len);
    p += len > 0 ? len : 1;
    if (c == '\t') c = ' ';
    if (c == '\r') continue;
    if (c < 128 || (c >= 0xA0 && c <= 0xFF)) {
      o += (char)c;
      continue;
    }
    struct M { unsigned u; unsigned char b; };
    static const M map[] = {{0x20AC, 0x80}, {0x201A, 0x82}, {0x201E, 0x84}, {0x2026, 0x85}, {0x2018, 0x91},
                            {0x2019, 0x92}, {0x201C, 0x93}, {0x201D, 0x94}, {0x2022, 0x95}, {0x2013, 0x96},
                            {0x2014, 0x97}, {0x2122, 0x99}};
    char b = '?';
    for (const auto& m : map)
      if (m.u == c) b = (char)m.b;
    o += b;
  }
  return o;
}
// Una cadena literal de PDF: «(…)» con \, ( y ) escapados y lo raro en octal.
std::string pdf_str(const std::string& bytes) {
  std::string o = "(";
  for (unsigned char c : bytes) {
    if (c == '\\' || c == '(' || c == ')') {
      o += '\\';
      o += (char)c;
    } else if (c < 32 || c > 126) {
      char b[8];
      std::snprintf(b, sizeof b, "\\%03o", c);
      o += b;
    } else {
      o += (char)c;
    }
  }
  return o + ")";
}
// UTF-16BE con BOM, en hexadecimal (los valores de los campos y el título).
std::string utf16_hex(const std::string& s) {
  std::string o = "<FEFF";
  const char* p = s.c_str();
  const char* e = p + s.size();
  auto put = [&](unsigned u) {
    char b[8];
    std::snprintf(b, sizeof b, "%04X", u & 0xFFFF);
    o += b;
  };
  while (p < e) {
    int len = 1;
    unsigned c = fl_utf8decode(p, e, &len);
    p += len > 0 ? len : 1;
    if (c == '\r') continue;
    if (c >= 0x10000) {
      c -= 0x10000;
      put(0xD800 + (c >> 10));
      put(0xDC00 + (c & 0x3FF));
    } else {
      put(c);
    }
  }
  return o + ">";
}
// Las líneas (ya en WinAnsi) que caben en «width» puntos.
std::vector<std::string> wrap(const std::string& utf8, double size, double width) {
  std::vector<std::string> out;
  for (const auto& para : split(winansi(utf8), '\n')) {
    std::string line;
    for (const auto& word0 : split(para, ' ')) {
      std::string word = word0;
      std::string next = line.empty() ? word : line + " " + word;
      if (text_width(next, size) <= width) {
        line = next;
        continue;
      }
      if (!line.empty()) out.push_back(line);
      line.clear();
      // Una palabra más larga que la línea se parte.
      while (text_width(word, size) > width && word.size() > 1) {
        size_t k = 1;
        while (k < word.size() && text_width(word.substr(0, k + 1), size) <= width) k++;
        out.push_back(word.substr(0, k));
        word = word.substr(k);
      }
      line = word;
    }
    out.push_back(line);
  }
  return out;
}
std::string num(double v) {
  char b[32];
  std::snprintf(b, sizeof b, "%.2f", v);
  for (char* c = b; *c; c++)
    if (*c == ',') *c = '.';
  return b;
}
// Los datos de un PNG (8 bits, RGB, sin entrelazar) listos para el PDF.
struct Png {
  int w = 0, h = 0;
  std::string idat;
};
unsigned be32(const std::string& s, size_t i) {
  return (unsigned)(unsigned char)s[i] << 24 | (unsigned)(unsigned char)s[i + 1] << 16 |
         (unsigned)(unsigned char)s[i + 2] << 8 | (unsigned)(unsigned char)s[i + 3];
}
bool png_chunks(const std::string& d, Png& out) {
  static const char sig[] = "\x89PNG\r\n\x1a\n";
  if (d.size() < 33 || d.compare(0, 8, sig, 8) != 0) return false;
  size_t i = 8;
  bool rgb8 = false;
  out = Png{};
  while (i + 12 <= d.size()) {
    unsigned len = be32(d, i);
    std::string type = d.substr(i + 4, 4);
    if (i + 12 + len > d.size()) return false;
    if (type == "IHDR" && len >= 13) {
      out.w = (int)be32(d, i + 8);
      out.h = (int)be32(d, i + 12);
      rgb8 = d[i + 16] == 8 && d[i + 17] == 2 && d[i + 20] == 0;
    } else if (type == "IDAT") {
      out.idat.append(d, i + 8, len);
    } else if (type == "IEND") {
      break;
    }
    i += 12 + len;
  }
  return rgb8 && out.w > 0 && out.h > 0 && !out.idat.empty();
}
// La imagen de una captura para el PDF: reducida y guardada como PNG RGB.
bool pdf_image(const std::string& path, const std::string& tmp, Png& out) {
  Img im;
  if (!load_image(path, im)) return false;
  Img small = shrink(im, 1800);
  std::string data;
  return save_png(tmp, small) && read_file(tmp, data) && png_chunks(data, out);
}

class Pdf {
public:
  int reserve() {
    objs_.emplace_back();
    return (int)objs_.size();
  }
  void set(int id, const std::string& body) { objs_[(size_t)id - 1] = body; }
  static std::string stream(const std::string& dict, const std::string& data) {
    return "<< /Length " + std::to_string(data.size()) + dict + " >>\nstream\n" + data + "\nendstream";
  }
  std::string bytes(int root, int info) const {
    std::string o = "%PDF-1.5\n%\xE2\xE3\xCF\xD3\n";
    std::vector<size_t> at;
    for (size_t i = 0; i < objs_.size(); i++) {
      at.push_back(o.size());
      o += std::to_string(i + 1) + " 0 obj\n" + objs_[i] + "\nendobj\n";
    }
    size_t xref = o.size();
    o += "xref\n0 " + std::to_string(objs_.size() + 1) + "\n0000000000 65535 f \n";
    for (size_t a : at) {
      char b[32];
      std::snprintf(b, sizeof b, "%010lu 00000 n \n", (unsigned long)a);
      o += b;
    }
    o += "trailer\n<< /Size " + std::to_string(objs_.size() + 1) + " /Root " + std::to_string(root) +
         " 0 R /Info " + std::to_string(info) + " 0 R >>\nstartxref\n" + std::to_string(xref) + "\n%%EOF\n";
    return o;
  }

private:
  std::vector<std::string> objs_;
};
std::string ref(int id) { return std::to_string(id) + " 0 R"; }
// Un texto en la página: «BT /F1 11 Tf … Tj ET».
std::string text_op(const char* font, double size, double x, double y, const std::string& winansi_text,
                    const char* gray = "0") {
  return "BT /" + std::string(font) + " " + num(size) + " Tf " + gray + " g 1 0 0 1 " + num(x) + " " + num(y) +
         " Tm " + pdf_str(winansi_text) + " Tj ET\n";
}
std::string lines_op(const std::vector<std::string>& lines, double size, double x, double top, double bottom) {
  std::string o;
  double y = top - size;
  for (const auto& l : lines) {
    if (y < bottom) break;
    o += text_op("F1", size, x, y, l);
    y -= size * 1.3;
  }
  return o;
}
std::string box_op(double x, double y, double w, double h) {
  return "0.97 0.97 0.98 rg " + num(x) + " " + num(y) + " " + num(w) + " " + num(h) + " re f 0.78 0.78 0.82 RG 0.8 w " +
         num(x) + " " + num(y) + " " + num(w) + " " + num(h) + " re S\n";
}
struct Field {
  double x, y, w, h, size;
  std::string name, value;
};
// Un campo de texto de varias líneas, con su aspecto (lo que se ve sin tocarlo).
int add_field(Pdf& pdf, int page, int font, const Field& f) {
  int ap = pdf.reserve(), annot = pdf.reserve();
  std::string body = "0.97 0.97 0.98 rg 0 0 " + num(f.w) + " " + num(f.h) + " re f 0.70 0.70 0.76 RG 1 w 0.5 0.5 " +
                     num(f.w - 1) + " " + num(f.h - 1) + " re S\n/Tx BMC q 1 1 " + num(f.w - 2) + " " +
                     num(f.h - 2) + " re W n\nBT /Helv " + num(f.size) + " Tf 0 g ET\n";
  double y = f.h - 4 - f.size;
  for (const auto& l : wrap(f.value, f.size, f.w - 8)) {
    if (y < 2) break;
    body += "BT /Helv " + num(f.size) + " Tf 0 g 4 " + num(y) + " Td " + pdf_str(l) + " Tj ET\n";
    y -= f.size * 1.3;
  }
  body += "Q EMC";
  pdf.set(ap, Pdf::stream(" /Type /XObject /Subtype /Form /BBox [0 0 " + num(f.w) + " " + num(f.h) +
                              "] /Resources << /Font << /Helv " + ref(font) + " >> >>",
                          body));
  pdf.set(annot, "<< /Type /Annot /Subtype /Widget /FT /Tx /Ff 4096 /F 4 /T " + pdf_str(f.name) + " /V " +
                     utf16_hex(f.value) + " /DA (/Helv " + num(f.size) + " Tf 0 g) /Rect [" + num(f.x) + " " +
                     num(f.y) + " " + num(f.x + f.w) + " " + num(f.y + f.h) + "] /P " + ref(page) +
                     " /MK << /BG [0.97 0.97 0.98] /BC [0.70 0.70 0.76] >> /BS << /W 1 >> /AP << /N " + ref(ap) +
                     " >> >>");
  return annot;
}
// El PDF entero. «tmp»: un PNG de trabajo para las imágenes.
std::string build_pdf(const Session& s, const std::string& date, const std::string& tmp) {
  Pdf pdf;
  int catalog = pdf.reserve(), pages = pdf.reserve(), f1 = pdf.reserve(), f2 = pdf.reserve();
  int acro = s.editable ? pdf.reserve() : 0, info = pdf.reserve();
  pdf.set(f1, "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>");
  pdf.set(f2, "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>");
  std::vector<int> kids, fields;
  const std::string fonts = "/Font << /F1 " + ref(f1) + " /F2 " + ref(f2) + " >>";
  auto page = [&](const std::string& content, const std::string& xobj, const std::vector<int>& annots, int id) {
    int c = pdf.reserve();
    pdf.set(c, Pdf::stream("", content));
    std::string a;
    for (int x : annots) a += ref(x) + " ";
    pdf.set(id, "<< /Type /Page /Parent " + ref(pages) + " /MediaBox [0 0 " + num(PW) + " " + num(PH) +
                    "] /Resources << " + fonts + (xobj.empty() ? "" : " /XObject << " + xobj + " >>") +
                    " >> /Contents " + ref(c) + (annots.empty() ? "" : " /Annots [" + a + "]") + " >>");
    kids.push_back(id);
  };
  std::string title = trim(s.title).empty() ? tx::TITLE_DEFAULT : s.title;
  // La portada: el prompt general.
  {
    int id = pdf.reserve();
    double top = PH - PM;
    std::string c = text_op("F2", 22, PM, top - 22, winansi(title));
    c += text_op("F1", 10, PM, top - 42, winansi(fmt(tx::COVER_SUB, {std::to_string(s.entries.size()), date})), "0.45");
    c += text_op("F2", 11, PM, top - 72, winansi(tx::COVER_LABEL), "0.3");
    double bx = PM, by = PM, bw = PW - 2 * PM, bh = top - 82 - PM;
    std::vector<int> annots;
    if (s.editable) {
      int a = add_field(pdf, id, f1, Field{bx, by, bw, bh, 12, "prompt_general", s.prompt});
      annots.push_back(a);
      fields.push_back(a);
    } else {
      c += box_op(bx, by, bw, bh) + lines_op(wrap(s.prompt, 12, bw - 20), 12, bx + 10, by + bh - 8, by + 6);
    }
    page(c, "", annots, id);
  }
  // Una página por captura: la imagen y su comentario.
  for (size_t i = 0; i < s.entries.size(); i++) {
    const Entry& e = s.entries[i];
    int id = pdf.reserve();
    double top = PH - PM, ch = 120;
    std::string c = text_op("F2", 14, PM, top - 14, winansi(fmt(tx::PAGE_TITLE, {std::to_string(i + 1)})));
    c += text_op("F1", 9, PM + 110, top - 12, winansi(base_name(e.path)), "0.45");
    c += text_op("F2", 10, PM, PM + ch + 6, winansi(tx::PAGE_LABEL), "0.3");
    double ax = PM, ay = PM + ch + 26, aw = PW - 2 * PM, ah = top - 28 - ay;
    std::string xobj;
    Png png;
    if (pdf_image(e.path, tmp, png)) {
      int im = pdf.reserve();
      pdf.set(im, Pdf::stream(" /Type /XObject /Subtype /Image /Width " + std::to_string(png.w) + " /Height " +
                                  std::to_string(png.h) +
                                  " /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode"
                                  " /DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent 8 /Columns " +
                                  std::to_string(png.w) + " >>",
                              png.idat));
      double k = std::min(aw / png.w, ah / png.h), w = png.w * k, h = png.h * k;
      double x = ax + (aw - w) / 2, y = ay + (ah - h) / 2;
      c += "q " + num(w) + " 0 0 " + num(h) + " " + num(x) + " " + num(y) + " cm /Im0 Do Q\n";
      c += "0.8 0.8 0.83 RG 0.5 w " + num(x) + " " + num(y) + " " + num(w) + " " + num(h) + " re S\n";
      xobj = "/Im0 " + ref(im);
    } else {
      c += box_op(ax, ay, aw, ah) + "0.8 0 0 rg\n" + text_op("F1", 11, ax + 12, ay + ah - 24, winansi(tx::MISSING_IMAGE), "0.6") +
           lines_op(wrap(e.path, 10, aw - 24), 10, ax + 12, ay + ah - 32, ay + 8);
    }
    std::vector<int> annots;
    if (s.editable) {
      int a = add_field(pdf, id, f1, Field{PM, PM, PW - 2 * PM, ch, 11, "comentario_" + std::to_string(i + 1), e.comment});
      annots.push_back(a);
      fields.push_back(a);
    } else {
      c += box_op(PM, PM, PW - 2 * PM, ch) + lines_op(wrap(e.comment, 11, PW - 2 * PM - 20), 11, PM + 10, PM + ch - 8, PM + 4);
    }
    page(c, xobj, annots, id);
  }
  std::string k;
  for (int x : kids) k += ref(x) + " ";
  pdf.set(pages, "<< /Type /Pages /Kids [" + k + "] /Count " + std::to_string(kids.size()) + " >>");
  if (acro) {
    std::string f;
    for (int x : fields) f += ref(x) + " ";
    pdf.set(acro, "<< /Fields [" + f + "] /NeedAppearances false /DR << /Font << /Helv " + ref(f1) +
                      " >> >> /DA (/Helv 0 Tf 0 g) >>");
  }
  pdf.set(catalog, "<< /Type /Catalog /Pages " + ref(pages) + (acro ? " /AcroForm " + ref(acro) : "") + " >>");
  pdf.set(info, "<< /Title " + utf16_hex(title) + " /Creator " + pdf_str("DMarlon Studio") + " /Producer " +
                    pdf_str(winansi(tx::APP)) + " >>");
  return pdf.bytes(catalog, info);
}

// ------------------------------------------------------------ el sistema
// Una sola copia abierta (la cámara de la barra es una).
bool single_instance() {
  if (testing()) return true;
#ifdef _WIN32
  HANDLE m = CreateMutexW(nullptr, TRUE, L"Local\\DMarlonStudio.CapturePrompt");
  return m && GetLastError() != ERROR_ALREADY_EXISTS;
#else
  fl_make_path(config_dir().c_str());
  int fd = open(join(config_dir(), "app.lock").c_str(), O_RDWR | O_CREAT, 0600);
  return fd < 0 || flock(fd, LOCK_EX | LOCK_NB) == 0;   // el descriptor queda abierto
#endif
}
#ifndef _WIN32
// Lanza un programa sin esperar (y recoge su final para que no quede zombi).
pid_t spawn(const std::vector<std::string>& args) {
  std::vector<char*> argv;
  for (const auto& a : args) argv.push_back(const_cast<char*>(a.c_str()));
  argv.push_back(nullptr);
  pid_t pid = 0;
  if (posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ) != 0) return 0;
  return pid;
}
#endif
// Abrir una carpeta o un archivo con su programa; «Vista Previa» en macOS.
void open_path(const std::string& path, bool markup = false) {
#ifdef _WIN32
  ShellExecuteW(nullptr, markup ? L"edit" : L"open", wide(path).c_str(), nullptr, nullptr, SW_SHOWNORMAL);
#elif defined(__APPLE__)
  pid_t p = markup ? spawn({"/usr/bin/open", "-a", "Preview", path}) : spawn({"/usr/bin/open", path});
  if (p > 0) {
    int st;
    waitpid(p, &st, 0);
  }
#else
  (void)markup;
  pid_t p = spawn({"xdg-open", path});
  if (p > 0) {
    int st;
    waitpid(p, &st, 0);
  }
#endif
}

// ------------------------------------------------------------ pruebas internas
int fails = 0;
void check(bool ok, const char* what) {
  if (!ok) {
    std::printf("FAIL %s\n", what);
    fails++;
  }
}
// Una imagen de prueba: degradado con un recuadro.
Img test_image(int W, int H) {
  Img im;
  im.w = W;
  im.h = H;
  im.px.resize((size_t)W * H * 3);
  for (int y = 0; y < H; y++)
    for (int x = 0; x < W; x++) {
      unsigned char* p = &im.px[((size_t)y * W + x) * 3];
      bool in = x > W / 4 && x < W / 2 && y > H / 4 && y < H / 2;
      p[0] = in ? 20 : (unsigned char)(x * 255 / W);
      p[1] = in ? 40 : (unsigned char)(y * 255 / H);
      p[2] = in ? 200 : 128;
    }
  return im;
}
int selftest() {
  fl_register_images();
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  // las marcas y el deshacer
  Doc d(1200, 800);
  check(!d.can_undo() && d.next_number() == 1, "doc vacío");
  Shape s;
  s.tool = T_ARROW;
  s.pts = {{700, 420}, {520, 230}};
  d.add(s);
  Shape n;
  n.tool = T_NUM;
  n.pts = {{60, 110}};
  n.number = d.next_number();
  d.add(n);
  check(d.next_number() == 2, "números de paso");
  Shape c;
  c.tool = T_CROP;
  c.pts = {{1150, 750}, {20, 90}};   // arrastrado al revés
  d.add(c);
  Box cr = d.crop();
  check(d.has_crop() && cr.x == 20 && cr.y == 90 && cr.w == 1130 && cr.h == 660, "recorte");
  check(d.undo() && !d.has_crop() && d.can_redo(), "deshacer el recorte");
  check(d.redo() && d.has_crop(), "rehacer");
  d.undo();
  d.add(s);
  check(!d.can_redo(), "una marca nueva borra el rehacer");
  Shape tiny;
  tiny.tool = T_RECT;
  tiny.pts = {{5, 5}, {6, 6}};
  check(!tiny.meaningful(), "un clic no es un rectángulo");
  Shape tx0;
  tx0.tool = T_TEXT;
  tx0.pts = {{1, 1}};
  tx0.text = "  ";
  check(!tx0.meaningful(), "texto vacío");
  Head h = arrow_head({0, 0}, {100, 0}, 8);
  check(std::fabs(h.tip.x - 100) < 1e-9 && h.left.y > 0 && h.right.y < 0 && h.base.x < 100, "punta de flecha");
  Pt q = constrain(T_LINE, {0, 0}, {100, 90});
  check(std::fabs(q.x - q.y) < 1e-6, "Mayúsculas: 45°");
  Pt sq = constrain(T_RECT, {0, 0}, {-30, 80});
  check(sq.x == -80 && sq.y == 80, "Mayúsculas: cuadrado");
  // rutas
  check(marked_path("/a/Captura 1.png") == std::string("/a/Captura 1") + tx::MARKED_SUFFIX + ".png", "ruta marcada");
  check(marked_path(marked_path("/a/b.jpg")) == marked_path("/a/b.jpg"), "la marcada no se vuelve a marcar");
  check(fmt("{0} de {1}", {"3", "5"}) == "3 de 5", "fmt");
  // pixelar y resaltador
  Img im = test_image(400, 300);
  auto blocks = pixel_blocks(im, Box{0, 0, 400, 300});
  check(!blocks.empty() && blocks[0].b.w == block_size(im), "bloques");
  auto inside = pixel_blocks(im, Box{120, 90, 60, 40});
  bool blue = !inside.empty() && (inside[0].rgb & 0xff) == 200 && (inside[0].rgb >> 16) == 20;
  check(blue, "el color medio de un bloque");
  check(pixel_blocks(im, Box{500, 500, 10, 10}).empty(), "pixelar fuera de la imagen");
  Raster r = raster_stroke({{10, 10}, {60, 10}}, 5, 0xffd60a, 0.4);
  auto alpha = [&](int x, int y) { return (int)r.px[((size_t)(y - r.y) * r.w + (x - r.x)) * 4 + 3]; };
  check(alpha(30, 10) > 90 && alpha(30, 10) <= 102 && alpha(30, 20) == 0, "el resaltador");
  // la sesión
  Session ses;
  ses.title = "Odoo · producto";
  ses.prompt = "Corrige el formulario.\nUsa los campos\tmarcados \\n literal.";
  ses.editable = false;
  ses.entries = {{"/x/Captura 1.png", "1) Precio con impuestos.\n2) Ocultar el código."}, {"/x/b.png", ""}};
  Session back;
  check(parse_session(session_text(ses), back), "leer la sesión");
  check(back.title == ses.title && back.prompt == ses.prompt && !back.editable && back.entries.size() == 2 &&
            back.entries[0].comment == ses.entries[0].comment,
        "la sesión, igual al volver a leerla");
  check(!parse_session("otra cosa", back), "un archivo que no es de la sesión");
  std::string p = to_prompt(ses);
  check(p.find("Corrige el formulario.") == 0 && p.find("## " + fmt(tx::PAGE_TITLE, {"2"})) != std::string::npos &&
            p.find("/x/Captura 1.png") != std::string::npos,
        "el prompt");
  // el PDF
  check(winansi("ñ€…✓") == std::string("\xF1\x80\x85?"), "WinAnsi");
  check(pdf_str("a(b)\\") == "(a\\(b\\)\\\\)", "cadena de PDF");
  check(utf16_hex("añ😀") == "<FEFF006100F1D83DDE00>", "UTF-16");
  auto lines = wrap("uno dos tres cuatro cinco seis siete ocho nueve diez", 12, 80);
  bool fit = lines.size() > 2;
  for (const auto& l : lines) fit = fit && text_width(l, 12) <= 80;
  check(fit, "partir las líneas");
  check(wrap("a\n\nb", 12, 200).size() == 3, "párrafos");
  std::string a = join(dir, "a.png"), b = join(dir, "b.png");
  check(save_png(a, im) && save_png(b, test_image(3000, 1000)), "guardar PNG");
  Png png;
  std::string data;
  check(read_file(a, data) && png_chunks(data, png) && png.w == 400 && png.h == 300, "leer un PNG");
  check(!png_chunks("nada", png), "no es un PNG");
  Img loaded;
  check(load_image(a, loaded) && loaded.w == 400 && loaded.px == im.px, "abrir la imagen");
  check(shrink(test_image(3000, 1000), 1800).w == 1500, "reducir para el PDF");
  for (int editable = 0; editable < 2; editable++) {
    Session t;
    t.title = "Prueba";
    t.prompt = "Prompt general ñ";
    t.editable = editable == 1;
    t.entries = {{a, "Comentario uno (con paréntesis)"}, {b, ""}, {join(dir, "no-existe.png"), "x"}};
    std::string out = build_pdf(t, "25/11/2026", join(dir, "tmp.png"));
    check(out.compare(0, 8, "%PDF-1.5") == 0 && out.find("%%EOF") != std::string::npos, "cabecera y final del PDF");
    size_t pages = 0, at = 0;
    while ((at = out.find("/Type /Page ", at)) != std::string::npos) pages++, at++;
    check(pages == 4, "una portada y una página por captura");
    size_t predictor = 0;
    at = 0;
    while ((at = out.find("/Predictor 15", at)) != std::string::npos) predictor++, at++;
    check(predictor == 2, "las dos imágenes, en PNG");
    bool fields = out.find("/FT /Tx") != std::string::npos && out.find("/AcroForm") != std::string::npos;
    check(editable ? fields : !fields, "campos editables solo si se piden");
    check(editable || out.find("(Comentario uno \\(con par\\351ntesis\\))") != std::string::npos, "el comentario en la página");
    // la tabla xref apunta a cada objeto
    size_t x = out.rfind("startxref\n");
    size_t xref = (size_t)std::atol(out.c_str() + x + 10);
    bool ok = out.compare(xref, 4, "xref") == 0;
    size_t line = out.find('\n', out.find('\n', xref) + 1) + 1;   // tras «0 N» y la entrada libre
    for (int obj = 1; ok; obj++) {
      if (out.compare(line + 18, 1, "n") != 0) break;
      size_t off = (size_t)std::atol(out.c_str() + line);
      ok = out.compare(off, std::to_string(obj).size() + 6, std::to_string(obj) + " 0 obj") == 0;
      line += 20;
    }
    check(ok, "la tabla xref");
    if (editable) write_file(join(dir, "prueba.pdf"), out);
  }
  std::printf(fails ? "selftest: %d fallos\n" : "selftest ok\n", fails);
  return fails ? 1 : 0;
}

}  // namespace cp
''';

const _captureUi = r'''
// ============================================================ la barra
// macOS: un NSStatusItem (la cámara) hecho desde C++ con el runtime de
// Objective-C, y los atajos globales con RegisterEventHotKey (Carbon, que ya
// está cargado). Windows: un icono junto al reloj (Shell_NotifyIcon) con su
// menú y los atajos con RegisterHotKey. Linux: la ventana se minimiza.
namespace bar {
struct Entry {
  std::string title;
  int tag = 0;
  bool enabled = true, sep = false;
  char key = 0;   // el atajo: ⌃⌥⌘key (Windows: Ctrl+Alt+Mayús+key)
};
enum Act { A_AREA = 1, A_WINDOW = 2, A_SCREEN = 3, A_SHOW = 4, A_PDF = 5, A_PROMPT = 6, A_FOLDER = 7, A_QUIT = 8 };
inline std::function<void(int)>& handler() {
  static std::function<void(int)> h;
  return h;
}
// Las acciones llegan desde el sistema: se hacen después, en el bucle de FLTK.
void fire(void* p) {
  if (handler()) handler()((int)(intptr_t)p);
}
void later(int t) { Fl::add_timeout(0.0, fire, (void*)(intptr_t)t); }
#ifdef __APPLE__
template <class R = id, class... A>
R msg(id o, const char* s, A... a) {
  return ((R(*)(id, SEL, A...))objc_msgSend)(o, sel_registerName(s), a...);
}
inline id cls(const char* n) { return (id)objc_getClass(n); }
inline id str(const std::string& s) { return msg(cls("NSString"), "stringWithUTF8String:", s.c_str()); }
extern "C" void* objc_autoreleasePoolPush(void);
extern "C" void objc_autoreleasePoolPop(void*);
struct Pool {
  void* p = objc_autoreleasePoolPush();
  ~Pool() { objc_autoreleasePoolPop(p); }
};
void on_act(id, SEL, id sender) { later((int)msg<long>(sender, "tag")); }
id target() {
  static id t = nullptr;
  if (!t) {
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsCapturePromptTarget", 0);
    class_addMethod(c, sel_registerName("dmsAct:"), (IMP)on_act, "v@:@");
    objc_registerClassPair(c);
    t = msg(msg((id)c, "alloc"), "init");
  }
  return t;
}
id& item() {
  static id i = nullptr;
  return i;
}
bool available() { return item() != nullptr; }
// Los atajos globales: ⌃⌥⌘4 área, ⌃⌥⌘5 ventana, ⌃⌥⌘3 pantalla.
struct HkId {
  uint32_t sig, id;
};
struct EvType {
  uint32_t cls, kind;
};
typedef int32_t (*HandlerFn)(void*, void*, void*);
typedef int32_t (*GetParamFn)(void*, uint32_t, uint32_t, uint32_t*, unsigned long, unsigned long*, void*);
GetParamFn& get_param() {
  static GetParamFn f = nullptr;
  return f;
}
int32_t on_hotkey(void*, void* ev, void*) {
  HkId k{0, 0};
  if (get_param() && get_param()(ev, 0x2D2D2D2D /* '----' */, 0x686B6964 /* 'hkid' */, nullptr, sizeof k, nullptr, &k) == 0)
    later((int)k.id);
  return 0;
}
bool hotkeys() {
  void* h = dlopen("/System/Library/Frameworks/Carbon.framework/Carbon", RTLD_LAZY);
  if (!h) return false;
  typedef void* (*TargetFn)();
  typedef int32_t (*InstallFn)(void*, HandlerFn, unsigned long, const EvType*, void*, void**);
  typedef int32_t (*RegisterFn)(uint32_t, uint32_t, HkId, void*, uint32_t, void**);
  auto app_target = (TargetFn)dlsym(h, "GetApplicationEventTarget");
  auto install = (InstallFn)dlsym(h, "InstallEventHandler");
  auto reg = (RegisterFn)dlsym(h, "RegisterEventHotKey");
  get_param() = (GetParamFn)dlsym(h, "GetEventParameter");
  if (!app_target || !install || !reg || !get_param()) return false;
  void* t = app_target();
  EvType spec{0x6B657962 /* 'keyb' */, 5 /* kEventHotKeyPressed */};
  if (install(t, on_hotkey, 1, &spec, nullptr, nullptr) != 0) return false;
  const uint32_t mods = 0x100 | 0x800 | 0x1000;   // cmd, option, control
  const struct { uint32_t code; int act; } keys[] = {{0x15, A_AREA}, {0x17, A_WINDOW}, {0x14, A_SCREEN}};
  bool ok = true;
  for (const auto& k : keys) {
    void* ref = nullptr;
    ok = reg(k.code, mods, HkId{0x444D4350 /* 'DMCP' */, (uint32_t)k.act}, t, 0, &ref) == 0 && ok;
  }
  return ok;
}
bool create() {
  Pool pool;
  id sb = msg(cls("NSStatusBar"), "systemStatusBar");
  if (!sb) return false;
  id it = msg<id, double>(sb, "statusItemWithLength:", -2.0);   // NSSquareStatusItemLength
  if (!it) return false;
  msg(it, "retain");
  item() = it;
  id b = msg(it, "button");
  id img = nullptr;
  if (class_getClassMethod((Class)objc_getClass("NSImage"), sel_registerName("imageWithSystemSymbolName:accessibilityDescription:")))
    img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str("camera.fill"), str(tx::APP));
  if (b && img) {
    msg<void, BOOL>(img, "setTemplate:", YES);
    msg<void, id>(b, "setImage:", img);
  } else if (b) {
    msg<void, id>(b, "setTitle:", str("◉"));
  }
  if (b) msg<void, id>(b, "setToolTip:", str(tx::APP));
  hotkeys();
  return true;
}
void menu(const std::vector<Entry>& entries) {
  if (!item()) return;
  Pool pool;
  id m = msg(msg(cls("NSMenu"), "alloc"), "init");
  msg<void, BOOL>(m, "setAutoenablesItems:", NO);
  for (const auto& e : entries) {
    if (e.sep) {
      msg<void, id>(m, "addItem:", msg(cls("NSMenuItem"), "separatorItem"));
      continue;
    }
    SEL action = e.tag ? sel_registerName("dmsAct:") : (SEL) nullptr;
    id it = msg<id, id, SEL, id>(msg(cls("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", str(e.title),
                                 action, str(e.key ? std::string(1, e.key) : std::string()));
    if (e.key) msg<void, unsigned long>(it, "setKeyEquivalentModifierMask:", (1UL << 18) | (1UL << 19) | (1UL << 20));
    msg<void, id>(it, "setTarget:", target());
    msg<void, long>(it, "setTag:", (long)e.tag);
    msg<void, BOOL>(it, "setEnabled:", e.enabled && e.tag ? YES : NO);
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
  msg<void, id>(item(), "setMenu:", m);
  msg<void>(m, "release");
}
// Con la ventana escondida, la app sale del Dock (solo queda la cámara).
void dock(bool visible) {
  Pool pool;
  id app = msg(cls("NSApplication"), "sharedApplication");
  msg<void, long>(app, "setActivationPolicy:", visible ? 0L : 1L);
  if (visible) msg<void, BOOL>(app, "activateIgnoringOtherApps:", YES);
}
void activate() {
  Pool pool;
  msg<void, BOOL>(msg(cls("NSApplication"), "sharedApplication"), "activateIgnoringOtherApps:", YES);
}
// Píxeles de la pantalla por punto (2 en Retina): para el grosor de las marcas.
double pixel_ratio() {
  Pool pool;
  id scr = msg(cls("NSScreen"), "mainScreen");
  double r = scr ? msg<double>(scr, "backingScaleFactor") : 1.0;
  return r >= 1 ? r : 1.0;
}
void remove() {
  if (!item()) return;
  Pool pool;
  msg<void, id>(msg(cls("NSStatusBar"), "systemStatusBar"), "removeStatusItem:", item());
  msg<void>(item(), "release");
  item() = nullptr;
}
#elif defined(_WIN32)
const UINT WM_TRAY = WM_APP + 21;
struct Tray {
  HWND hwnd = nullptr;
  NOTIFYICONDATAW nid{};
  std::vector<Entry> entries;
  UINT created_msg = 0;
  bool added = false;
};
Tray& tray() {
  static Tray t;
  return t;
}
void copy_w(wchar_t* dst, size_t n, const std::string& s) {
  std::wstring w = cp::wide(s);
  if (w.size() >= n) w = w.substr(0, n - 1);
  wcsncpy(dst, w.c_str(), n);
  dst[n - 1] = 0;
}
void add_icon() {
  Tray& t = tray();
  t.added = Shell_NotifyIconW(NIM_ADD, &t.nid) != FALSE;
}
void popup() {
  Tray& t = tray();
  HMENU m = CreatePopupMenu();
  for (const auto& e : t.entries) {
    if (e.sep) {
      AppendMenuW(m, MF_SEPARATOR, 0, nullptr);
      continue;
    }
    std::string title = e.title;
    if (e.key) title += "\t" + cp::fmt(tx::KEY_WIN, {std::string(1, e.key)});
    std::wstring w = cp::wide(title), safe;
    for (wchar_t c : w) {   // «&» marca la tecla de acceso
      if (c == L'&') safe += L'&';
      safe += c;
    }
    AppendMenuW(m, MF_STRING | (e.enabled && e.tag ? 0 : MF_GRAYED), (UINT_PTR)e.tag, safe.c_str());
  }
  POINT pt;
  GetCursorPos(&pt);
  SetForegroundWindow(t.hwnd);
  TrackPopupMenu(m, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN, pt.x, pt.y, 0, t.hwnd, nullptr);
  PostMessageW(t.hwnd, WM_NULL, 0, 0);
  DestroyMenu(m);
}
LRESULT CALLBACK proc(HWND h, UINT m, WPARAM w, LPARAM l) {
  Tray& t = tray();
  if (m == WM_TRAY) {
    if (l == WM_LBUTTONUP || l == WM_RBUTTONUP || l == WM_CONTEXTMENU) popup();
    else if (l == WM_LBUTTONDBLCLK) later(A_SHOW);
    return 0;
  }
  if (m == WM_HOTKEY) {
    later((int)w);
    return 0;
  }
  if (m == WM_COMMAND && HIWORD(w) == 0) {
    if (LOWORD(w)) later((int)LOWORD(w));
    return 0;
  }
  if (t.created_msg && m == t.created_msg) {   // el Explorador se reinició
    add_icon();
    return 0;
  }
  return DefWindowProcW(h, m, w, l);
}
bool available() { return tray().hwnd != nullptr && tray().added; }
bool create() {
  Tray& t = tray();
  HINSTANCE inst = GetModuleHandleW(nullptr);
  WNDCLASSW wc{};
  wc.lpfnWndProc = proc;
  wc.hInstance = inst;
  wc.lpszClassName = L"DmsCapturePromptTray";
  RegisterClassW(&wc);
  t.hwnd = CreateWindowExW(WS_EX_TOOLWINDOW, wc.lpszClassName, L"", WS_POPUP, 0, 0, 0, 0, nullptr, nullptr, inst, nullptr);
  if (!t.hwnd) return false;
  t.created_msg = RegisterWindowMessageW(L"TaskbarCreated");
  t.nid.cbSize = sizeof(t.nid);
  t.nid.hWnd = t.hwnd;
  t.nid.uID = 1;
  t.nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  t.nid.uCallbackMessage = WM_TRAY;
  wchar_t exe[MAX_PATH * 2];
  GetModuleFileNameW(nullptr, exe, MAX_PATH * 2);
  HICON icon = ExtractIconW(inst, exe, 0);
  if ((UINT_PTR)icon <= 1) icon = LoadIconW(nullptr, MAKEINTRESOURCEW(32512));   // IDI_APPLICATION
  t.nid.hIcon = icon;
  copy_w(t.nid.szTip, 128, tx::APP);
  add_icon();
  // Ctrl+Alt+Mayús+4, 5 y 3 (MOD_NOREPEAT: 0x4000).
  const UINT mods = MOD_CONTROL | MOD_ALT | MOD_SHIFT | 0x4000;
  RegisterHotKey(t.hwnd, A_AREA, mods, '4');
  RegisterHotKey(t.hwnd, A_WINDOW, mods, '5');
  RegisterHotKey(t.hwnd, A_SCREEN, mods, '3');
  return t.added;
}
void menu(const std::vector<Entry>& entries) { tray().entries = entries; }
void dock(bool) {}
void activate() {}
double pixel_ratio() { return std::max(1.0f, Fl::screen_scale(0)); }
void remove() {
  Tray& t = tray();
  if (t.added) Shell_NotifyIconW(NIM_DELETE, &t.nid);
  t.added = false;
  if (t.hwnd) DestroyWindow(t.hwnd);
  t.hwnd = nullptr;
}
#else
bool available() { return false; }
bool create() { return false; }
void menu(const std::vector<Entry>&) {}
void dock(bool) {}
void activate() {}
double pixel_ratio() { return std::max(1.0f, Fl::screen_scale(0)); }
void remove() {}
#endif
}  // namespace bar

// ============================================================ capturar
// macOS: screencapture (el de ⇧⌘4: área, ventana con la barra espaciadora).
// Windows y Linux: la pantalla entera y, encima, una capa para elegir el
// área o la ventana.
namespace snap {
enum { AREA = 1, WINDOW = 2, SCREEN = 3 };
// Oscurecer: una imagen negra translúcida, estirada.
void shade(int x, int y, int w, int h, int alpha) {
  if (w <= 0 || h <= 0) return;
  unsigned char px[8 * 8 * 4];
  for (int i = 0; i < 64; i++) px[i * 4] = px[i * 4 + 1] = px[i * 4 + 2] = 0, px[i * 4 + 3] = (unsigned char)alpha;
  Fl_RGB_Image im(px, 8, 8, 4);
  im.scale(w, h, 0, 1);
  im.draw(x, y);
}
class Overlay : public Fl_Double_Window {
public:
  const cp::Img& img;
  int mode;
  std::vector<cp::Box> wins;   // en píxeles de la captura
  Fl_RGB_Image* fl;
  bool done = false, ok = false, dragging = false;
  cp::Pt a, b;
  int hover = -1;
  cp::Box result;
  Overlay(const cp::Img& im, int m, std::vector<cp::Box> w, int X, int Y, int W, int H)
      : Fl_Double_Window(X, Y, W, H), img(im), mode(m), wins(std::move(w)) {
    border(0);
    fl = new Fl_RGB_Image(im.px.data(), im.w, im.h, 3);
    end();
    callback([](Fl_Widget* o, void*) { static_cast<Overlay*>(o)->done = true; });
  }
  ~Overlay() { delete fl; }
  double kx() const { return (double)img.w / w(); }
  double ky() const { return (double)img.h / h(); }
  cp::Box selection() const {   // en la ventana
    if (mode == AREA) return cp::Box{a.x, a.y, b.x - a.x, b.y - a.y}.norm();
    if (hover < 0) return cp::Box{};
    const cp::Box& r = wins[(size_t)hover];
    return cp::Box{r.x / kx(), r.y / ky(), r.w / kx(), r.h / ky()};
  }
  void draw() override {
    fl->scale(w(), h(), 0, 1);
    fl->draw(0, 0);
    cp::Box s = selection();
    if (s.empty(1)) {
      shade(0, 0, w(), h(), 110);
    } else {
      int x = (int)s.x, y = (int)s.y, sw = (int)s.w, sh = (int)s.h;
      shade(0, 0, w(), y, 110);
      shade(0, y + sh, w(), h() - y - sh, 110);
      shade(0, y, x, sh, 110);
      shade(x + sw, y, w() - x - sw, sh, 110);
      fl_color(FL_WHITE);
      fl_line_style(FL_SOLID, 2);
      fl_rect(x, y, sw, sh);
      fl_line_style(0);
      std::string size = std::to_string((int)std::lround(s.w * kx())) + " × " + std::to_string((int)std::lround(s.h * ky()));
      fl_font(FL_HELVETICA, 13);
      int tw = (int)fl_width(size.c_str()) + 12;
      fl_color(fl_rgb_color(30, 30, 34));
      fl_rectf(x, std::max(0, y - 24), tw, 22);
      fl_color(FL_WHITE);
      fl_draw(size.c_str(), x + 6, std::max(0, y - 24) + 16);
    }
    const char* hint = mode == AREA ? tx::OVERLAY_AREA : tx::OVERLAY_WINDOW;
    fl_font(FL_HELVETICA_BOLD, 16);
    int tw = (int)fl_width(hint) + 40;
    fl_color(fl_rgb_color(30, 30, 34));
    fl_rounded_rectf((w() - tw) / 2, 24, tw, 40, 12);
    fl_color(FL_WHITE);
    fl_draw(hint, (w() - tw) / 2 + 20, 50);
  }
  int handle(int e) override {
    switch (e) {
      case FL_PUSH:
        if (Fl::event_button() != 1) {
          done = true;
          return 1;
        }
        if (mode == AREA) {
          dragging = true;
          a = b = cp::Pt{(double)Fl::event_x(), (double)Fl::event_y()};
          redraw();
        }
        return 1;
      case FL_DRAG:
        if (dragging) {
          b = cp::Pt{(double)Fl::event_x(), (double)Fl::event_y()};
          redraw();
        }
        return 1;
      case FL_RELEASE: {
        cp::Box s = selection();
        if (!s.empty(3)) {
          result = cp::Box{s.x * kx(), s.y * ky(), s.w * kx(), s.h * ky()}.clip(cp::Box{0, 0, (double)img.w, (double)img.h});
          ok = !result.empty(3);
        }
        dragging = false;
        done = true;
        return 1;
      }
      case FL_MOVE:
        if (mode == WINDOW) {
          double px = Fl::event_x() * kx(), py = Fl::event_y() * ky();
          int h0 = hover;
          hover = -1;
          for (size_t i = 0; i < wins.size() && hover < 0; i++)   // de delante a atrás
            if (px >= wins[i].x && py >= wins[i].y && px < wins[i].x + wins[i].w && py < wins[i].y + wins[i].h)
              hover = (int)i;
          if (hover != h0) redraw();
        }
        return 1;
      case FL_ENTER:
        cursor(FL_CURSOR_CROSS);
        return 1;
      case FL_KEYBOARD:
      case FL_SHORTCUT:
        if (Fl::event_key() == FL_Escape) {
          done = true;
          return 1;
        }
        break;
      case FL_FOCUS:
      case FL_UNFOCUS:
        return 1;
    }
    return Fl_Double_Window::handle(e);
  }
};
bool pick(const cp::Img& full, int mode, const std::vector<cp::Box>& wins, cp::Box& out) {
  int X, Y, W, H;
  Fl::screen_xywh(X, Y, W, H, 0);
  Overlay o(full, mode, wins, X, Y, W, H);
  o.set_modal();
  o.show();
  o.take_focus();
  while (o.shown() && !o.done) Fl::wait(0.1);
  o.hide();
  if (o.ok) out = o.result;
  return o.ok;
}
#ifdef __APPLE__
pid_t start(int mode, const std::string& file) {
  std::vector<std::string> a = {"/usr/sbin/screencapture"};
  if (mode == AREA) a.push_back("-i");
  else if (mode == WINDOW) a.insert(a.end(), {"-i", "-W"});
  a.push_back(file);
  return cp::spawn(a);
}
bool finished(pid_t pid) {
  int st;
  pid_t r = waitpid(pid, &st, WNOHANG);
  return r == pid || r < 0;
}
#elif defined(_WIN32)
struct WinList {
  std::vector<cp::Box> boxes;
  DWORD self;
};
BOOL CALLBACK enum_win(HWND h, LPARAM l) {
  auto* wl = (WinList*)l;
  if (!IsWindowVisible(h) || IsIconic(h)) return TRUE;
  DWORD pid = 0;
  GetWindowThreadProcessId(h, &pid);
  if (pid == wl->self || (GetWindowLongW(h, GWL_EXSTYLE) & WS_EX_TOOLWINDOW) || GetWindowTextLengthW(h) == 0) return TRUE;
  RECT r;
  if (!GetWindowRect(h, &r) || r.right - r.left < 40 || r.bottom - r.top < 30) return TRUE;
  wl->boxes.push_back({(double)r.left, (double)r.top, (double)(r.right - r.left), (double)(r.bottom - r.top)});
  return TRUE;
}
// La pantalla principal con GDI, y las ventanas abiertas (de delante a atrás).
bool grab(cp::Img& out, std::vector<cp::Box>* wins) {
  int W = GetSystemMetrics(SM_CXSCREEN), H = GetSystemMetrics(SM_CYSCREEN);
  HDC scr = GetDC(nullptr);
  HDC mem = CreateCompatibleDC(scr);
  BITMAPINFO bi{};
  bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth = W;
  bi.bmiHeader.biHeight = -H;
  bi.bmiHeader.biPlanes = 1;
  bi.bmiHeader.biBitCount = 32;
  bi.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HBITMAP bmp = CreateDIBSection(scr, &bi, DIB_RGB_COLORS, &bits, nullptr, 0);
  bool ok = false;
  if (bmp && bits) {
    HGDIOBJ old = SelectObject(mem, bmp);
    ok = BitBlt(mem, 0, 0, W, H, scr, 0, 0, SRCCOPY | CAPTUREBLT) != FALSE;
    if (ok) {
      out.w = W;
      out.h = H;
      out.px.resize((size_t)W * H * 3);
      const unsigned char* s = (const unsigned char*)bits;
      for (size_t i = 0; i < (size_t)W * H; i++) {
        out.px[i * 3] = s[i * 4 + 2];
        out.px[i * 3 + 1] = s[i * 4 + 1];
        out.px[i * 3 + 2] = s[i * 4];
      }
    }
    SelectObject(mem, old);
    DeleteObject(bmp);
  }
  DeleteDC(mem);
  ReleaseDC(nullptr, scr);
  if (wins) {
    WinList wl;
    wl.self = GetCurrentProcessId();
    EnumWindows(enum_win, (LPARAM)&wl);
    *wins = wl.boxes;
  }
  return ok;
}
#else
// Linux: la herramienta de capturas que haya.
bool grab_linux(const std::string& file) {
  const std::vector<std::vector<std::string>> tools = {
      {"gnome-screenshot", "-f", file}, {"spectacle", "-b", "-n", "-f", "-o", file},
      {"grim", file}, {"import", "-window", "root", file}, {"scrot", "-o", file}};
  for (const auto& t : tools) {
    fl_unlink(file.c_str());
    pid_t p = cp::spawn(t);
    if (p <= 0) continue;
    int st;
    waitpid(p, &st, 0);
    if (cp::exists(file)) return true;
  }
  return false;
}
#endif
}  // namespace snap

// ============================================================ el lienzo
// El texto se escribe en un campo encima de la imagen; Intro lo deja, Esc no.
class TextIn : public Fl_Input {
public:
  std::function<void(bool)> done;
  TextIn(int x, int y, int w, int h) : Fl_Input(x, y, w, h) {}
  void finish(bool keep) {
    if (!done) return;
    auto d = done;
    done = nullptr;
    d(keep);
  }
  int handle(int e) override {
    if (e == FL_KEYBOARD) {
      int k = Fl::event_key();
      if (k == FL_Escape) {
        finish(false);
        return 1;
      }
      if (k == FL_Enter || k == FL_KP_Enter) {
        finish(true);
        return 1;
      }
    }
    if (e == FL_UNFOCUS) {
      int r = Fl_Input::handle(e);
      finish(true);
      return r;
    }
    return Fl_Input::handle(e);
  }
};

// La captura con sus marcas: se dibuja ajustada al hueco y se marca con el ratón.
class Canvas : public Fl_Widget {
public:
  cp::Doc* doc = nullptr;
  const cp::Img* base = nullptr;
  Fl_RGB_Image* fl = nullptr;
  int tool = cp::T_ARROW, size = 1;
  unsigned color = 0xf23333;
  double ppu = 1;   // píxeles de pantalla por unidad (2 en Retina)
  bool has_cur = false;
  cp::Shape cur;
  TextIn* tin = nullptr;
  cp::Pt tin_at;
  std::function<void()> changed;
  std::function<void(int)> on_tool;
  std::function<void(const std::string&)> dropped;

  Canvas(int x, int y, int w, int h) : Fl_Widget(x, y, w, h, nullptr) { box(FL_FLAT_BOX); }
  ~Canvas() { delete fl; }
  void image(const cp::Img* b) {
    commit_text(false);
    delete fl;
    fl = nullptr;
    base = b;
    if (b && !b->empty()) fl = new Fl_RGB_Image(b->px.data(), b->w, b->h, 3);
    has_cur = false;
    redraw();
  }
  double stroke_px() const {
    static const double S[3] = {2, 4, 8};
    return S[std::clamp(size, 0, 2)] * ppu;
  }
  double font_px() const {
    static const double F[3] = {14, 20, 32};
    return F[std::clamp(size, 0, 2)] * ppu;
  }
  cp::View view() const {
    cp::View v;
    if (!base || base->empty()) return v;
    double s = std::min((w() - 24.0) / base->w, (h() - 24.0) / base->h);
    v.s = std::clamp(s, 0.02, 1.0 / ppu);
    v.ox = x() + std::floor((w() - base->w * v.s) / 2);
    v.oy = y() + std::floor((h() - base->h * v.s) / 2);
    return v;
  }
  cp::Pt to_img(int ex, int ey) const {
    cp::View v = view();
    return cp::Pt{std::clamp((ex - v.ox) / v.s, 0.0, (double)base->w), std::clamp((ey - v.oy) / v.s, 0.0, (double)base->h)};
  }
  cp::Shape shape_at(cp::Pt p) const {
    cp::Shape s;
    s.tool = tool;
    s.color = color;
    s.width = stroke_px();
    s.font = font_px();
    s.pts.push_back(p);
    return s;
  }
  void draw() override {
    fl_push_clip(x(), y(), w(), h());
    fl_color(fl_rgb_color(42, 44, 49));
    fl_rectf(x(), y(), w(), h());
    if (!fl || !doc) {
      draw_empty();
      fl_pop_clip();
      return;
    }
    cp::View v = view();
    int dw = (int)std::lround(base->w * v.s), dh = (int)std::lround(base->h * v.s);
    int ix = (int)std::lround(v.ox), iy = (int)std::lround(v.oy);
    fl_color(fl_rgb_color(24, 25, 28));
    fl_rectf(ix + 3, iy + 4, dw, dh);
    fl->scale(dw, dh, 0, 1);
    fl->draw(ix, iy);
    fl_push_clip(ix, iy, dw, dh);
    cp::draw_shapes(*doc, *base, v, has_cur && cur.tool != cp::T_CROP ? &cur : nullptr);
    bool cropping = has_cur && cur.tool == cp::T_CROP;
    if (doc->has_crop() || cropping) {
      cp::Box c = cropping ? cur.box() : doc->crop();
      int cx = (int)std::lround(v.X(c.x)), cy = (int)std::lround(v.Y(c.y));
      int cw = (int)std::lround(c.w * v.s), ch = (int)std::lround(c.h * v.s);
      snap::shade(ix, iy, dw, cy - iy, 140);
      snap::shade(ix, cy + ch, dw, iy + dh - cy - ch, 140);
      snap::shade(ix, cy, cx - ix, ch, 140);
      snap::shade(cx + cw, cy, ix + dw - cx - cw, ch, 140);
      fl_color(FL_WHITE);
      fl_line_style(FL_DASH, 1);
      fl_rect(cx, cy, cw, ch);
      fl_line_style(0);
    }
    fl_pop_clip();
    fl_pop_clip();
  }
  // Sin captura: una cámara y cómo empezar.
  void draw_empty() {
    int cx = x() + w() / 2, cy = y() + h() / 2 - 60;
    fl_color(fl_rgb_color(120, 126, 140));
    fl_rounded_rectf(cx - 60, cy - 36, 120, 84, 16);
    fl_rounded_rectf(cx - 22, cy - 50, 44, 20, 6);
    fl_color(fl_rgb_color(42, 44, 49));
    fl_pie(cx - 26, cy - 22, 52, 52, 0, 360);
    fl_color(fl_rgb_color(120, 126, 140));
    fl_pie(cx - 15, cy - 11, 30, 30, 0, 360);
    fl_color(fl_rgb_color(226, 232, 240));
    fl_font(FL_HELVETICA_BOLD, 22);
    fl_draw(tx::EMPTY_TITLE, x() + 40, cy + 70, w() - 80, 30, FL_ALIGN_CENTER);
    fl_color(fl_rgb_color(148, 163, 184));
    fl_font(FL_HELVETICA, 15);
    fl_draw(tx::EMPTY_HELP, x() + 80, cy + 104, w() - 160, 60, FL_ALIGN_CENTER | FL_ALIGN_TOP | FL_ALIGN_WRAP);
  }
  void begin_text(cp::Pt p) {
    commit_text(true);
    cp::View v = view();
    int fs = std::max(9, (int)std::lround(font_px() * v.s));
    int tx0 = (int)std::lround(v.X(p.x)), ty0 = (int)std::lround(v.Y(p.y));
    tin_at = p;
    tin = new TextIn(tx0 - 3, ty0 - 3, std::max(260, fs * 14), fs + 12);
    tin->textsize(fs);
    tin->textfont(FL_HELVETICA_BOLD);
    tin->textcolor(cp::rgb(color));
    tin->box(FL_BORDER_BOX);
    tin->color(fl_rgb_color(255, 255, 245));
    tin->done = [this](bool keep) { commit_text(keep); };
    if (parent()) parent()->add(tin);
    tin->show();
    tin->take_focus();
    if (parent()) parent()->redraw();
  }
  void commit_text(bool keep) {
    if (!tin) return;
    TextIn* t = tin;
    tin = nullptr;
    t->done = nullptr;
    std::string text = t->value() ? t->value() : "";
    t->hide();
    Fl::delete_widget(t);
    if (keep && doc && !cp::trim(text).empty()) {
      cp::Shape s = shape_at(tin_at);
      s.tool = cp::T_TEXT;
      s.text = text;
      doc->add(s);
      if (changed) changed();
    }
    redraw();
  }
  int handle(int e) override {
    switch (e) {
      case FL_PUSH: {
        take_focus();
        if (!fl || !doc || Fl::event_button() != 1) return 1;
        commit_text(true);
        cp::Pt p = to_img(Fl::event_x(), Fl::event_y());
        if (tool == cp::T_TEXT) {
          begin_text(p);
          return 1;
        }
        if (tool == cp::T_NUM) {
          cp::Shape s = shape_at(p);
          s.number = doc->next_number();
          doc->add(s);
          redraw();
          if (changed) changed();
          return 1;
        }
        cur = shape_at(p);
        cur.pts.push_back(p);
        has_cur = true;
        redraw();
        return 1;
      }
      case FL_DRAG: {
        if (!has_cur) return 1;
        cp::Pt p = to_img(Fl::event_x(), Fl::event_y());
        if (cur.tool == cp::T_PEN || cur.tool == cp::T_MARK) {
          const cp::Pt& l = cur.pts.back();
          if (std::hypot(p.x - l.x, p.y - l.y) >= 1.5) cur.pts.push_back(p);
        } else {
          if (Fl::event_state(FL_SHIFT)) p = cp::constrain(cur.tool, cur.pts.front(), p);
          cur.pts.back() = p;
        }
        redraw();
        return 1;
      }
      case FL_RELEASE:
        if (has_cur) {
          has_cur = false;
          if (cur.meaningful()) {
            doc->add(cur);
            if (changed) changed();
          }
          redraw();
        }
        return 1;
      case FL_FOCUS:
      case FL_UNFOCUS:
        return 1;
      case FL_ENTER:
      case FL_MOVE:
        if (window()) window()->cursor(fl ? (tool == cp::T_TEXT ? FL_CURSOR_INSERT : FL_CURSOR_CROSS) : FL_CURSOR_DEFAULT);
        return 1;
      case FL_LEAVE:
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        return 1;
      case FL_KEYBOARD: {
        if (Fl::event_state(FL_COMMAND | FL_CTRL | FL_ALT)) return 0;
        const char* t = Fl::event_text();
        if (!t || !t[0] || t[1]) return 0;
        static const char* keys = "phalrotnbc";   // las herramientas, en orden
        const char* f = std::strchr(keys, std::tolower((unsigned char)t[0]));
        if (!f) return 0;
        if (on_tool) on_tool((int)(f - keys));
        return 1;
      }
      // Soltar una imagen encima la abre.
      case FL_DND_ENTER:
      case FL_DND_DRAG:
      case FL_DND_LEAVE:
      case FL_DND_RELEASE:
        return 1;
      case FL_PASTE: {
        std::string p = Fl::event_text() ? Fl::event_text() : "";
        p = cp::split(p, '\n')[0];
        if (!p.empty() && p.back() == '\r') p.pop_back();
        if (p.compare(0, 7, "file://") == 0) {
          std::string d;
          for (size_t i = 7; i < p.size(); i++) {
            if (p[i] == '%' && i + 2 < p.size()) {
              d += (char)std::strtol(p.substr(i + 1, 2).c_str(), nullptr, 16);
              i += 2;
            } else {
              d += p[i];
            }
          }
          p = d;
        }
        if (!p.empty() && dropped) dropped(p);
        return 1;
      }
    }
    return Fl_Widget::handle(e);
  }
};

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  cp::Session ses;
  cp::Doc doc;
  cp::Img base;
  Canvas* canvas = nullptr;
  std::string src, saved;   // la imagen abierta y su versión marcada
  int sel = -1;             // su captura en el PDF (-1: todavía no está)
  bool dirty = false, in_bar = false, quitting = false, live = true, busy = false, syncing = false;
  std::vector<DmsButton*> tools, swatches;
  static constexpr unsigned PALETTE[6] = {0xf23333, 0xff9500, 0xffd60a, 0x34c759, 0x0a84ff, 0x1d1d1f};

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_CAPTURE_SELFTEST")) std::exit(cp::selftest());
    if (fl_getenv("DMS_CAPTURE_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_CAPTURE_SHOT")) { set_fonts(); std::exit(shots(d)); }
    if (!cp::single_instance()) {
      fl_message("%s", tx::ALREADY_OPEN);
      std::exit(0);
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

  void setup() {
    self() = this;
    BoardHint->hide();   // el aviso del Diseñador
    for (Fl_Group* g : {(Fl_Group*)Board, (Fl_Group*)Tools, (Fl_Group*)Side}) g->box(FL_FLAT_BOX);
    Tools->resizable(nullptr);
    Side->resizable(Shots);
    resizable(Board);
    size_range(980, 640);
    canvas = new Canvas(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(canvas);
    Board->resizable(canvas);
    canvas->doc = &doc;
    canvas->changed = [] { if (self()) self()->marks_changed(); };
    canvas->on_tool = [](int t) { if (self()) self()->pick_tool(t); };
    canvas->dropped = [](const std::string& p) { if (self()) self()->open_file(p); };
    tools = {ToolPen, ToolMark, ToolArrow, ToolLine, ToolRect, ToolOval, ToolText, ToolNum, ToolBlur, ToolCrop};
    swatches = {Color1, Color2, Color3, Color4, Color5, Color6};
    for (auto* s : swatches) {
      s->box(FL_BORDER_BOX);
      s->down_box(FL_BORDER_BOX);
      s->selection_color(s->color());
    }
    // Deshacer y rehacer: flechas de FLTK (el texto del Diseñador, de ayuda).
    for (DmsButton* b : {BtnUndo, BtnRedo}) {
      b->copy_tooltip(b->label());
      b->label(b == BtnUndo ? "@<-" : "@->");
      b->labelsize(16);
    }
    Size->index(1);
    Shots->format_char(0);   // los comentarios no son formato de FLTK
    Shots->has_scrollbar(Fl_Browser_::VERTICAL);
    Comment->when(FL_WHEN_CHANGED);
    Comment->callback([](Fl_Widget*, void*) { if (self()) self()->comment_changed(); });
    Prompt->when(FL_WHEN_CHANGED);
    Prompt->callback([](Fl_Widget*, void*) { if (self()) self()->prompt_changed(); });
    auto key = [this](const char* path, int k) {
      int i = Menu1->find_index(path);
      if (i >= 0) Menu1->shortcut(i, k);
    };
    key(tx::MP_UNDO, FL_COMMAND + 'z');
    key(tx::MP_REDO, FL_COMMAND + FL_SHIFT + 'z');
    key(tx::MP_SAVE, FL_COMMAND + 's');
    key(tx::MP_COPY, FL_COMMAND + 'c');
    key(tx::MP_OPEN, FL_COMMAND + 'o');
    key(tx::MP_PDF, FL_COMMAND + 'e');
    // El botón de cerrar esconde la ventana en la barra (si la hay); Esc no
    // hace nada. Un cierre desde el código (el menú Idioma de las demos)
    // cierra de verdad: Fl::run termina y la app se vuelve a abrir.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE) self()->close_clicked();
      else self()->close_for_good();
    });
    refresh_tools();
    refresh_swatches();
  }

  void form_create() override {
    set_fonts();
    setup();
    canvas->ppu = bar::pixel_ratio();
    load();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    refresh();
    status(cp::fmt(tx::ST_READY, {std::to_string(ses.entries.size())}));
  }
  void form_close() override { save(); }

  // ---- guardar la sesión
  std::string session_file() const { return cp::join(cp::config_dir(), "session.txt"); }
  void load() {
    std::string text;
    if (!cp::read_file(session_file(), text) || !cp::parse_session(text, ses)) ses = cp::Session{};
    if (cp::trim(ses.title).empty()) ses.title = tx::TITLE_DEFAULT;
    syncing = true;
    Prompt->text(ses.prompt);
    Editable->checked(ses.editable);
    syncing = false;
  }
  void save() {
    if (!live) return;
    fl_make_path(cp::config_dir().c_str());
    cp::write_file(session_file(), cp::session_text(ses));
  }

  // ---- lo que se ve
  void status(const std::string& s) { Status->text(s); }
  void refresh_tools() {
    for (size_t i = 0; i < tools.size(); i++) {
      bool on = (int)i == canvas->tool;
      tools[i]->color(on ? fl_rgb_color(219, 234, 254) : FL_BACKGROUND_COLOR);
      tools[i]->labelcolor(on ? fl_rgb_color(29, 78, 216) : FL_FOREGROUND_COLOR);
      tools[i]->labelfont(on ? FL_HELVETICA_BOLD : FL_HELVETICA);
      tools[i]->redraw();
    }
  }
  void refresh_swatches() {
    for (size_t i = 0; i < swatches.size(); i++) {
      bool on = PALETTE[i] == canvas->color;
      swatches[i]->copy_label(on ? "•" : "");
      swatches[i]->labelcolor(cp::light(PALETTE[i]) ? FL_BLACK : FL_WHITE);
      swatches[i]->labelfont(FL_HELVETICA_BOLD);
      swatches[i]->labelsize(18);
      swatches[i]->redraw();
    }
  }
  std::string row(size_t i) const {
    std::string c = cp::one_line(ses.entries[i].comment);
    if (fl_utf_nb_char((const unsigned char*)c.c_str(), (int)c.size()) > 44) {
      int n = 0;
      size_t k = 0;
      while (k < c.size() && n < 42) k += (size_t)std::max(1, fl_utf8len1(c[k])), n++;
      c = c.substr(0, k) + "…";
    }
    return std::to_string(i + 1) + ". " + (c.empty() ? std::string(tx::NO_COMMENT) : c);
  }
  void refresh_list() {
    Shots->clear();
    for (size_t i = 0; i < ses.entries.size(); i++) Shots->add(row(i));
    if (sel >= 0 && sel < (int)ses.entries.size()) Shots->index(sel);
  }
  void refresh_buttons() {
    bool has = !base.empty();
    BtnUndo->enabled(doc.can_undo());
    BtnRedo->enabled(doc.can_redo());
    for (auto* b : {BtnSave, BtnCopy, BtnPreview, BtnAdd}) b->enabled(has);
    BtnAdd->text(sel >= 0 ? tx::UPDATE : tx::ADD);
    bool picked = Shots->index() >= 0;
    BtnUp->enabled(picked && Shots->index() > 0);
    BtnDown->enabled(picked && Shots->index() + 1 < (int)ses.entries.size());
    BtnRemove->enabled(picked);
    std::string t = tx::APP;
    if (!src.empty()) t += std::string(" — ") + cp::base_name(src);
    if (dirty) t += " •";
    copy_label(t.c_str());
  }
  void refresh_bar() {
    using bar::Entry;
    auto act = [](const std::string& t, int tag, char key = 0) {
      Entry e;
      e.title = t;
      e.tag = tag;
      e.key = key;
      return e;
    };
    Entry sep;
    sep.sep = true;
    Entry count;
    count.title = cp::fmt(tx::BAR_COUNT, {std::to_string(ses.entries.size())});
    count.enabled = false;
    bar::menu({act(tx::BAR_AREA, bar::A_AREA, '4'), act(tx::BAR_WINDOW, bar::A_WINDOW, '5'),
               act(tx::BAR_SCREEN, bar::A_SCREEN, '3'), sep, act(tx::BAR_SHOW, bar::A_SHOW), sep, count,
               act(tx::BAR_PDF, bar::A_PDF), act(tx::BAR_PROMPT, bar::A_PROMPT), act(tx::BAR_FOLDER, bar::A_FOLDER), sep,
               act(tx::BAR_QUIT, bar::A_QUIT)});
  }
  void refresh() {
    refresh_list();
    refresh_buttons();
    refresh_bar();
    canvas->redraw();
  }

  // ---- la imagen abierta
  bool open_image(const std::string& path, int index) {
    cp::Img im;
    bool ok = cp::load_image(path, im);
    base = ok ? std::move(im) : cp::Img{};
    doc = cp::Doc(base.w, base.h);
    src = path;
    saved.clear();   // se guarda en la copia «-marcada» (la original no se toca)
    dirty = false;
    sel = index;
    canvas->image(&base);
    syncing = true;
    Comment->text(index >= 0 ? ses.entries[(size_t)index].comment : "");
    syncing = false;
    if (!ok) status(cp::fmt(tx::E_OPEN, {path}));
    refresh();
    return ok;
  }
  void open_file(const std::string& path) {
    canvas->commit_text(true);
    autosave();
    if (open_image(path, -1)) status(path);
  }
  bool write_marked(const std::string& dest) {
    cp::Img out;
    if (!cp::render_final(doc, base, out) || !cp::save_png(dest, out)) {
      status(cp::fmt(tx::E_SAVE, {dest}));
      return false;
    }
    saved = dest;
    dirty = false;
    refresh_buttons();
    return true;
  }
  // Lo marcado no se pierde: se guarda al cambiar de captura.
  void autosave() {
    if (!dirty || base.empty()) return;
    std::string d = saved.empty() ? cp::marked_path(src) : saved;
    if (write_marked(d) && sel >= 0 && sel < (int)ses.entries.size()) {
      ses.entries[(size_t)sel].path = d;
      save();
    }
  }
  std::string ensure_saved() {
    canvas->commit_text(true);
    if (!saved.empty() && !dirty) return saved;
    std::string d = saved.empty() ? cp::marked_path(src) : saved;
    return write_marked(d) ? d : "";
  }
  void marks_changed() {
    dirty = true;
    refresh_buttons();
  }
  void pick_tool(int t) {
    canvas->commit_text(true);
    canvas->tool = t;
    refresh_tools();
  }
  void pick_color(int i) {
    canvas->color = PALETTE[i];
    refresh_swatches();
  }

  // ---- capturar
  void pause(double s) {
    auto end = std::chrono::steady_clock::now() + std::chrono::duration<double>(s);
    while (std::chrono::steady_clock::now() < end) Fl::wait(0.05);
  }
  bool grab_to(int mode, const std::string& file) {
#ifdef __APPLE__
    pid_t pid = snap::start(mode, file);
    if (pid <= 0) {
      status(tx::E_CAPTURE);
      return false;
    }
    while (!snap::finished(pid)) Fl::wait(0.1);
    if (!cp::exists(file)) {
      status(tx::ST_CANCEL);   // Esc
      return false;
    }
    return true;
#else
    cp::Img full;
    std::vector<cp::Box> wins;
#ifdef _WIN32
    bool ok = snap::grab(full, &wins);
#else
    std::string tmp = cp::join(cp::config_dir(), "screen.png");
    fl_make_path(cp::config_dir().c_str());
    bool ok = snap::grab_linux(tmp) && cp::load_image(tmp, full);
#endif
    if (!ok) {
      status(tx::E_CAPTURE);
      return false;
    }
    cp::Img out = full;
    if (mode != snap::SCREEN) {
      cp::Box r;
      if (!snap::pick(full, mode, wins, r)) {
        status(tx::ST_CANCEL);
        return false;
      }
      out = cp::crop_img(full, r);
    }
    if (!cp::save_png(file, out)) {
      status(cp::fmt(tx::E_SAVE, {file}));
      return false;
    }
    return true;
#endif
  }
  void capture(int mode) {
    if (busy || !live) return;
    busy = true;
    canvas->commit_text(true);
    autosave();
    bool was_visible = shown() && visible() && !in_bar;
    if (was_visible) hide();   // que no salga en la captura
    pause(0.3);
    std::string file = cp::new_capture_path();
    bool ok = grab_to(mode, file);
    busy = false;
    if (ok && open_image(file, -1)) status(cp::fmt(tx::ST_CAPTURED, {file}));
    if (in_bar && ok) from_bar();
    else if (was_visible || ok) show();
    bar::activate();
  }

  // ---- la barra
  void to_bar() {
    if (!bar::available()) {
      iconize();
      return;
    }
    if (in_bar) return;
    canvas->commit_text(true);
    autosave();
    save();
    in_bar = true;
    hide();
    bar::dock(false);
    // Sin ventanas, Fl::run terminaría: aquí sigue la app (como un diálogo).
    while (in_bar && !quitting) Fl::wait(1e20);
    if (quitting) quit_now();
  }
  void from_bar() {
    bar::dock(true);
    in_bar = false;
    show();
    refresh();
  }
  void close_clicked() {
    if (bar::available()) to_bar();
    else quit();
  }
  void close_for_good() {
    canvas->commit_text(true);
    autosave();
    save();
    bar::remove();
    in_bar = false;
    hide();
  }
  void quit() {
    quitting = true;
    if (!in_bar) quit_now();
  }
  void quit_now() {
    canvas->commit_text(true);
    autosave();
    save();
    bar::remove();
    hide();
    std::exit(0);
  }
  void bar_act(int t) {
    switch (t) {
      case bar::A_AREA: capture(snap::AREA); break;
      case bar::A_WINDOW: capture(snap::WINDOW); break;
      case bar::A_SCREEN: capture(snap::SCREEN); break;
      case bar::A_SHOW:
        if (in_bar) from_bar();
        else show();
        bar::activate();
        break;
      case bar::A_PDF: export_pdf(); break;
      case bar::A_PROMPT: copy_prompt(); break;
      case bar::A_FOLDER: cp::open_path(cp::pictures_dir()); break;
      case bar::A_QUIT: quit(); break;
    }
  }

  // ---- el PDF y el prompt
  void comment_changed() {
    if (syncing || sel < 0 || sel >= (int)ses.entries.size()) return;
    ses.entries[(size_t)sel].comment = Comment->text();
    save();
    Shots->text(sel + 1, row((size_t)sel).c_str());
  }
  void prompt_changed() {
    if (syncing) return;
    ses.prompt = Prompt->text();
    save();
  }
  void add_to_pdf() {
    if (base.empty()) return;
    std::string p = ensure_saved();
    if (p.empty()) return;
    if (sel >= 0 && sel < (int)ses.entries.size()) {
      ses.entries[(size_t)sel] = cp::Entry{p, Comment->text()};
      status(cp::fmt(tx::ST_UPDATED, {std::to_string(sel + 1)}));
    } else {
      ses.entries.push_back(cp::Entry{p, Comment->text()});
      sel = (int)ses.entries.size() - 1;
      status(cp::fmt(tx::ST_ADDED, {std::to_string(sel + 1)}));
    }
    src = p;
    save();
    refresh();
  }
  void copy_prompt() {
    std::string t = cp::to_prompt(ses);
    Fl::copy(t.c_str(), (int)t.size(), 1);
    status(cp::fmt(tx::ST_PROMPT, {std::to_string(ses.entries.size())}));
  }
  std::string ask_save(const char* title, const char* filter, const std::string& dir, const std::string& name) {
    Fl_Native_File_Chooser ch;
    ch.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    ch.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM | Fl_Native_File_Chooser::NEW_FOLDER);
    ch.title(title);
    ch.filter(filter);
    fl_make_path(dir.c_str());
    ch.directory(dir.c_str());
    ch.preset_file(name.c_str());
    if (ch.show() != 0 || !ch.filename()) return "";
    return ch.filename();
  }
  void export_pdf() {
    canvas->commit_text(true);
    autosave();
    if (ses.entries.empty() && cp::trim(ses.prompt).empty()) {
      status(tx::ST_NOTHING);
      return;
    }
    std::string path = ask_save(tx::BAR_PDF, "PDF\t*.pdf", cp::pictures_dir(), cp::fmt(tx::PDF_NAME, {cp::stamp(cp::now_t())}) + ".pdf");
    if (path.empty()) return;
    if (path.size() < 4 || fl_utf_strcasecmp(path.c_str() + path.size() - 4, ".pdf") != 0) path += ".pdf";
    std::string bytes = cp::build_pdf(ses, cp::date_text(cp::now_t()), cp::join(cp::config_dir(), "pdf-image.png"));
    if (!cp::write_file(path, bytes)) {
      fl_alert("%s", cp::fmt(tx::E_PDF, {path}).c_str());
      return;
    }
    status(cp::fmt(tx::ST_PDF, {path}));
    cp::open_path(path);
  }
  void copy_image() {
    canvas->commit_text(true);
    cp::Img out;
    if (!cp::render_final(doc, base, out)) return;
    Fl_Copy_Surface* cs = new Fl_Copy_Surface(out.w, out.h);
    Fl_Surface_Device::push_current(cs);
    Fl_RGB_Image im(out.px.data(), out.w, out.h, 3);
    im.draw(0, 0);
    Fl_Surface_Device::pop_current();
    delete cs;   // al borrarla, la imagen va al portapapeles
    status(tx::ST_COPIED);
  }

  // ---- los eventos del diseño
  void BtnArea_click() override { capture(snap::AREA); }
  void BtnWindow_click() override { capture(snap::WINDOW); }
  void BtnScreen_click() override { capture(snap::SCREEN); }
  void ToolPen_click() override { pick_tool(cp::T_PEN); }
  void ToolMark_click() override { pick_tool(cp::T_MARK); }
  void ToolArrow_click() override { pick_tool(cp::T_ARROW); }
  void ToolLine_click() override { pick_tool(cp::T_LINE); }
  void ToolRect_click() override { pick_tool(cp::T_RECT); }
  void ToolOval_click() override { pick_tool(cp::T_OVAL); }
  void ToolText_click() override { pick_tool(cp::T_TEXT); }
  void ToolNum_click() override { pick_tool(cp::T_NUM); }
  void ToolBlur_click() override { pick_tool(cp::T_BLUR); }
  void ToolCrop_click() override { pick_tool(cp::T_CROP); }
  void BtnUndo_click() override {
    canvas->commit_text(true);
    if (doc.undo()) marks_changed();
    canvas->redraw();
  }
  void BtnRedo_click() override {
    if (doc.redo()) marks_changed();
    canvas->redraw();
  }
  void Color1_click() override { pick_color(0); }
  void Color2_click() override { pick_color(1); }
  void Color3_click() override { pick_color(2); }
  void Color4_click() override { pick_color(3); }
  void Color5_click() override { pick_color(4); }
  void Color6_click() override { pick_color(5); }
  void Size_select() override { canvas->size = std::max(0, Size->index()); }
  void Shots_select() override {
    int i = Shots->index();
    refresh_buttons();
    if (i < 0 || i == sel || i >= (int)ses.entries.size()) return;
    canvas->commit_text(true);
    autosave();
    open_image(ses.entries[(size_t)i].path, i);
  }
  void move_entry(int d) {
    int i = Shots->index(), j = i + d;
    if (i < 0 || j < 0 || j >= (int)ses.entries.size()) return;
    std::swap(ses.entries[(size_t)i], ses.entries[(size_t)j]);
    if (sel == i) sel = j;
    else if (sel == j) sel = i;
    save();
    refresh_list();
    Shots->index(j);
    refresh_buttons();
  }
  void BtnUp_click() override { move_entry(-1); }
  void BtnDown_click() override { move_entry(1); }
  void BtnRemove_click() override {
    int i = Shots->index();
    if (i < 0 || i >= (int)ses.entries.size()) return;
    ses.entries.erase(ses.entries.begin() + i);
    if (sel == i) sel = -1;
    else if (sel > i) sel--;
    save();
    refresh();
  }
  void BtnAdd_click() override { add_to_pdf(); }
  void BtnSave_click() override {
    std::string p = ensure_saved();
    if (!p.empty()) status(cp::fmt(tx::ST_SAVED, {p}));
  }
  void BtnCopy_click() override { copy_image(); }
  void BtnPreview_click() override {
    std::string p = ensure_saved();
    if (p.empty()) return;
    cp::open_path(p, true);
#ifdef __APPLE__
    status(tx::ST_PREVIEW);
#endif
  }
  void Editable_click() override {
    ses.editable = Editable->checked();
    save();
  }
  void BtnPdf_click() override { export_pdf(); }
  void BtnPrompt_click() override { copy_prompt(); }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_AREA) capture(snap::AREA);
    else if (item == tx::MP_WINDOW) capture(snap::WINDOW);
    else if (item == tx::MP_SCREEN) capture(snap::SCREEN);
    else if (item == tx::MP_OPEN) {
      Fl_Native_File_Chooser ch;
      ch.type(Fl_Native_File_Chooser::BROWSE_FILE);
      ch.filter((std::string(tx::FILTER_IMAGES) + "\t*.{png,jpg,jpeg,gif,bmp}").c_str());
      ch.directory(cp::pictures_dir().c_str());
      if (ch.show() == 0 && ch.filename()) open_file(ch.filename());
    } else if (item == tx::MP_SAVE) BtnSave_click();
    else if (item == tx::MP_SAVE_AS) {
      if (base.empty()) return;
      std::string p = ask_save(tx::MP_SAVE_AS, "PNG\t*.png", cp::dir_name(src), cp::base_name(cp::marked_path(src)));
      if (!p.empty() && write_marked(p)) status(cp::fmt(tx::ST_SAVED, {p}));
    } else if (item == tx::MP_COPY) copy_image();
    else if (item == tx::MP_PDF) export_pdf();
    else if (item == tx::MP_PROMPT) copy_prompt();
    else if (item == tx::MP_FOLDER) cp::open_path(cp::pictures_dir());
    else if (item == tx::MP_CLEAR) {
      if (fl_choice("%s", tx::ASK_NO, tx::ASK_YES, nullptr, tx::ASK_CLEAR) != 1) return;
      ses.entries.clear();
      ses.prompt.clear();
      sel = -1;
      syncing = true;
      Prompt->text("");
      syncing = false;
      save();
      refresh();
    } else if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_UNDO) BtnUndo_click();
    else if (item == tx::MP_REDO) BtnRedo_click();
    else if (item == tx::MP_WIPE) {
      doc.clear();
      marks_changed();
      canvas->redraw();
    } else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
  }

  // ---- capturas de la web y pruebas, sin ventana
  // Una pantalla de ejemplo: el formulario de producto de un ERP cualquiera.
  static cp::Img sample_screen(int W, int H) {
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    fl_color(fl_rgb_color(243, 244, 246));
    fl_rectf(0, 0, W, H);
    fl_color(fl_rgb_color(91, 75, 138));
    fl_rectf(0, 0, W, 52);
    fl_color(FL_WHITE);
    fl_font(FL_HELVETICA_BOLD, 18);
    fl_draw(tx::SAMPLE_APP, 24, 33);
    fl_font(FL_HELVETICA, 15);
    fl_draw(tx::SAMPLE_MENU, 170, 33);
    fl_color(FL_WHITE);
    fl_rectf(40, 80, W - 80, H - 120);
    fl_color(fl_rgb_color(209, 213, 219));
    fl_rect(40, 80, W - 80, H - 120);
    fl_color(fl_rgb_color(17, 24, 39));
    fl_font(FL_HELVETICA_BOLD, 28);
    fl_draw(tx::SAMPLE_TITLE, 80, 150);
    int y = 220;
    for (const auto& line : cp::split(tx::SAMPLE_FIELDS, '\n')) {
      auto f = cp::split(line, '|');
      fl_font(FL_HELVETICA, 16);
      fl_color(fl_rgb_color(107, 114, 128));
      fl_draw(f[0].c_str(), 80, y);
      fl_color(fl_rgb_color(17, 24, 39));
      if (f.size() > 1) fl_draw(f[1].c_str(), 330, y);
      fl_color(fl_rgb_color(229, 231, 235));
      fl_line(80, y + 14, 640, y + 14);
      y += 46;
    }
    fl_color(fl_rgb_color(37, 99, 235));
    fl_rounded_rectf(W - 320, 110, 110, 36, 6);
    fl_color(fl_rgb_color(229, 231, 235));
    fl_rounded_rectf(W - 200, 110, 110, 36, 6);
    fl_color(fl_rgb_color(249, 250, 251));
    fl_rectf(720, 200, W - 800, H - 280);
    fl_color(fl_rgb_color(229, 231, 235));
    fl_rect(720, 200, W - 800, H - 280);
    for (int k = 0; k < 4; k++) {
      fl_color(fl_rgb_color(209, 213, 219));
      fl_pie(744, 228 + k * 70, 34, 34, 0, 360);
      fl_rectf(792, 232 + k * 70, 220 - k * 30, 10);
      fl_rectf(792, 250 + k * 70, 320 - k * 40, 8);
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    cp::Img out;
    cp::from_fl(img, out);
    delete img;
    return out;
  }
  static cp::Shape mark(int tool, std::vector<cp::Pt> pts, unsigned color, double width = 6, double font = 26) {
    cp::Shape s;
    s.tool = tool;
    s.pts = std::move(pts);
    s.color = color;
    s.width = width;
    s.font = font;
    return s;
  }
  // Las marcas de las capturas de la web, sobre la pantalla de ejemplo.
  static void sample_marks(cp::Doc& d) {
    cp::Shape n1 = mark(cp::T_NUM, {{310, 255}}, 0xf23333);
    n1.number = 1;
    d.add(mark(cp::T_RECT, {{322, 238}, {470, 276}}, 0xf23333));
    d.add(n1);
    d.add(mark(cp::T_ARROW, {{640, 330}, {482, 266}}, 0xf23333));
    cp::Shape t = mark(cp::T_TEXT, {{560, 336}}, 0xf23333);
    t.text = tx::SAMPLE_NOTE;
    d.add(t);
    d.add(mark(cp::T_MARK, {{80, 140}, {300, 140}, {420, 140}}, 0xffd60a, 6));
    d.add(mark(cp::T_BLUR, {{322, 480}, {520, 512}}, 0));
    cp::Shape n2 = mark(cp::T_NUM, {{310, 497}}, 0x0a84ff);
    n2.number = 2;
    d.add(n2);
    d.add(mark(cp::T_OVAL, {{300, 344}, {460, 376}}, 0x34c759));
  }
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
  void demo_state(int W, int H) {
    Fl::screen_count();
    live = false;
    setup();
    size(W, H);
    std::string dir = cp::config_dir();
    fl_make_path(dir.c_str());
    cp::Img sample = sample_screen(1440, 900);
    // Tres capturas ya en el PDF, cada una con su comentario.
    cp::Doc d1(sample.w, sample.h);
    sample_marks(d1);
    cp::Img m1, m2, m3;
    cp::render_final(d1, sample, m1);
    cp::Doc d2(sample.w, sample.h);
    d2.add(mark(cp::T_BLUR, {{322, 480}, {520, 512}}, 0));
    d2.add(mark(cp::T_RECT, {{300, 466}, {540, 526}}, 0x0a84ff));
    d2.add(mark(cp::T_CROP, {{40, 80}, {700, 560}}, 0));
    cp::render_final(d2, sample, m2);
    cp::Doc d3(sample.w, sample.h);
    d3.add(mark(cp::T_ARROW, {{560, 420}, {470, 395}}, 0x34c759));
    d3.add(mark(cp::T_RECT, {{322, 376}, {470, 412}}, 0x34c759));
    cp::render_final(d3, sample, m3);
    std::string p0 = cp::join(dir, cp::fmt(tx::CAPTURE_NAME, {"1"}) + ".png");
    std::string p1 = cp::join(dir, cp::fmt(tx::CAPTURE_NAME, {"1"}) + tx::MARKED_SUFFIX + ".png");
    std::string p2 = cp::join(dir, cp::fmt(tx::CAPTURE_NAME, {"2"}) + tx::MARKED_SUFFIX + ".png");
    std::string p3 = cp::join(dir, cp::fmt(tx::CAPTURE_NAME, {"3"}) + tx::MARKED_SUFFIX + ".png");
    cp::save_png(p0, sample);
    cp::save_png(p1, m1);
    cp::save_png(p2, m2);
    cp::save_png(p3, m3);
    ses = cp::Session{};
    ses.title = tx::TITLE_DEFAULT;
    ses.prompt = tx::SAMPLE_PROMPT;
    ses.entries = {{p1, tx::SAMPLE_C1}, {p2, tx::SAMPLE_C2}, {p3, tx::SAMPLE_C3}};
    syncing = true;
    Prompt->text(ses.prompt);
    Editable->checked(true);
    syncing = false;
    // En el lienzo, la primera, con sus marcas todavía editables.
    open_image(p0, 0);
    sample_marks(doc);
    dirty = true;
    canvas->tool = cp::T_ARROW;
    refresh_tools();
    refresh();
    status(cp::fmt(tx::ST_ADDED, {"3"}));
  }
  // El escritorio con la barra de menús y el menú de la cámara abierto.
  void desk(const std::string& file) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(30 + 50 * t), (uchar)(40 + 60 * t), (uchar)(80 + 70 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(fl_rgb_color(222, 223, 230));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(fl_rgb_color(29, 29, 31));
    fl_draw("21:30", W - 70, 26);
    // La cámara de la barra.
    int ix = W - 560;
    fl_color(fl_rgb_color(196, 198, 208));
    fl_rounded_rectf(ix - 10, 5, 44, BarH - 10, 8);
    fl_color(fl_rgb_color(29, 29, 31));
    fl_rounded_rectf(ix, 14, 24, 16, 3);
    fl_rectf(ix + 8, 11, 8, 4);
    fl_color(fl_rgb_color(196, 198, 208));
    fl_pie(ix + 7, 17, 10, 10, 0, 360);
    // El menú.
    std::vector<std::pair<std::string, std::string>> rows = {
        {tx::BAR_AREA, "⌃⌥⌘4"}, {tx::BAR_WINDOW, "⌃⌥⌘5"}, {tx::BAR_SCREEN, "⌃⌥⌘3"}, {"-", ""},
        {tx::BAR_SHOW, ""}, {"-", ""}, {cp::fmt(tx::BAR_COUNT, {std::to_string(ses.entries.size())}), "~"},
        {tx::BAR_PDF, ""}, {tx::BAR_PROMPT, ""}, {tx::BAR_FOLDER, ""}, {"-", ""}, {tx::BAR_QUIT, ""}};
    fl_font(FL_HELVETICA, 16);
    int mw = 360, mh = 12;
    for (const auto& r : rows) {
      mw = std::max(mw, (int)fl_width(r.first.c_str()) + 140);
      mh += r.first == "-" ? 12 : 34;
    }
    int mx = ix - 12, my = BarH + 4;
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(30 - 3 * k), (uchar)(40 - 3 * k), (uchar)(70 - 3 * k)));
      fl_rounded_rectf(mx - k, my - k + 4, mw + 2 * k, mh + 2 * k, 14 + k);
    }
    fl_color(fl_rgb_color(243, 243, 245));
    fl_rounded_rectf(mx, my, mw, mh, 14);
    int yy = my + 6;
    for (size_t i = 0; i < rows.size(); i++) {
      const auto& r = rows[i];
      if (r.first == "-") {
        fl_color(fl_rgb_color(216, 216, 220));
        fl_line(mx + 16, yy + 6, mx + mw - 16, yy + 6);
        yy += 12;
        continue;
      }
      Fl_Color col = r.second == "~" ? fl_rgb_color(142, 142, 147) : fl_rgb_color(29, 29, 31);
      if (i == 0) {
        fl_color(fl_rgb_color(47, 111, 234));
        fl_rounded_rectf(mx + 6, yy, mw - 12, 34, 8);
        col = FL_WHITE;
      }
      fl_font(FL_HELVETICA, 16);
      fl_color(col);
      fl_draw(r.first.c_str(), mx + 22, yy + 23);
      if (r.second.size() > 1) {
        fl_color(i == 0 ? FL_WHITE : fl_rgb_color(142, 142, 147));
        fl_draw(r.second.c_str(), mx + mw - 22 - (int)fl_width(r.second.c_str()), yy + 23);
      }
      yy += 34;
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1440, 900);
    render_to(cp::join(dir, "window.png"));
    // El panel con la segunda captura (pixelada y recortada) elegida.
    Shots->index(1);
    Shots_select();
    status(cp::fmt(tx::ST_PROMPT, {"3"}));
    render_to(cp::join(dir, "session.png"));
    desk(cp::join(dir, "menu.png"));
    cp::write_file(cp::join(dir, "capturas.pdf"), cp::build_pdf(ses, cp::date_text(cp::now_t()), cp::join(cp::config_dir(), "pdf-image.png")));
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1280, 805);
    int f = 0;
    auto chk = [&](bool ok, const char* what) {
      if (!ok) {
        std::printf("FAIL %s\n", what);
        f++;
      }
    };
    chk(ses.entries.size() == 3 && Shots->size() == 3, "la lista de capturas");
    chk(sel == 0 && Comment->text() == std::string(tx::SAMPLE_C1), "la captura elegida y su comentario");
    chk(doc.shapes().size() == 8 && BtnUndo->enabled(), "las marcas");
    // La imagen final: el rectángulo rojo y el pixelado.
    cp::Img out;
    chk(cp::render_final(doc, base, out) && out.w == 1440 && out.h == 900, "la imagen final");
    auto at = [&](int x, int y) { return &out.px[((size_t)y * out.w + x) * 3]; };
    const unsigned char* red = at(396, 238);
    chk(red[0] > 200 && red[1] < 90, "el rectángulo rojo");
    const unsigned char* blk = at(330, 488);
    const unsigned char* orig = &base.px[((size_t)488 * base.w + 330) * 3];
    chk(std::abs((int)blk[0] - (int)orig[0]) + std::abs((int)blk[1] - (int)orig[1]) < 120, "el pixelado");
    // Recortar y deshacer.
    doc.add(mark(cp::T_CROP, {{100, 100}, {500, 400}}, 0));
    chk(cp::render_final(doc, base, out) && out.w == 400 && out.h == 300, "el recorte");
    BtnUndo_click();
    chk(!doc.has_crop() && BtnRedo->enabled(), "deshacer el recorte");
    // Las herramientas.
    ToolText_click();
    chk(canvas->tool == cp::T_TEXT, "elegir el texto");
    Color5_click();
    chk(canvas->color == 0x0a84ff && std::string(Color5->label()) == "•", "elegir el color");
    Size->index(2);
    Size_select();
    chk(canvas->size == 2 && canvas->font_px() == 32, "el tamaño");
    // Añadir: guarda la marcada y actualiza la captura 1.
    Comment->text("hola, prompt");
    comment_changed();
    BtnAdd_click();
    chk(ses.entries[0].comment == "hola, prompt" && cp::exists(ses.entries[0].path), "actualizar en el PDF");
    chk(ses.entries[0].path == cp::marked_path(cp::join(cp::config_dir(), cp::fmt(tx::CAPTURE_NAME, {"1"}) + ".png")), "la ruta marcada");
    chk(std::string(BtnAdd->label()) == tx::UPDATE, "el botón Actualizar");
    // Ordenar y quitar.
    Shots->index(0);
    BtnDown_click();
    chk(sel == 1 && ses.entries[1].comment == "hola, prompt", "bajar");
    Shots->index(2);
    BtnRemove_click();
    chk(ses.entries.size() == 2 && sel == 1, "quitar");
    std::string p = cp::to_prompt(ses);
    chk(p.find("hola, prompt") != std::string::npos && p.find(tx::SAMPLE_PROMPT) == 0, "el prompt");
    std::string pdf = cp::build_pdf(ses, "25/11/2026", cp::join(cp::config_dir(), "pdf-image.png"));
    chk(pdf.find("/Predictor 15") != std::string::npos && pdf.find("comentario_2") != std::string::npos, "el PDF");
    std::printf(f ? "uitest: %d fallos\n" : "uitest ok\n", f);
    return f ? 1 : 0;
  }
};
''';
