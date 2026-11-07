part of 'tk_examples.dart';

// El código en C++ del explorador de archivos (tk_showcase_cpp_explorer.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _explorerCode = r'''
namespace fs = std::filesystem;

// ============================================================ utilidades
namespace ex {

#if defined(FL_API_VERSION) && FL_API_VERSION >= 10400
inline void select_text(Fl_Input* in, int from, int to) { in->insert_position(to, from); }
#else
inline void select_text(Fl_Input* in, int from, int to) { in->position(to, from); }
#endif

#ifdef __APPLE__
const int UI = 13;            // tamaño de letra de la interfaz
const unsigned BASE = 1000;   // el Finder cuenta en miles
#else
const int UI = 12;
const unsigned BASE = 1024;
#endif
const std::string COMPUTER = "::computer";   // la vista «Equipo»: los discos

// ---- colores y dibujo
// El tema: claro (al estilo de Aero) u oscuro. th(claro, oscuro) da el color.
inline bool dark = false;
inline unsigned th(unsigned light, unsigned dark_) { return dark ? dark_ : light; }

inline Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void color(unsigned v) { fl_color(rgb(v)); }

inline unsigned mixu(unsigned a, unsigned b, double t) {
  auto ch = [&](int s) {
    int x = (a >> s) & 255, y = (b >> s) & 255;
    return ((unsigned)std::lround(x + (y - x) * t)) & 255u;
  };
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}
// Un color desvaído (ocultos, cortados, desactivados): hacia el blanco.
inline unsigned dimc(unsigned v, bool dim) { return dim ? mixu(v, dark ? 0x262b33 : 0xffffff, 0.55) : v; }

inline void vgrad(int x, int y, int w, int h, unsigned top, unsigned bottom) {
  for (int i = 0; i < h; i++) {
    color(mixu(top, bottom, h > 1 ? (double)i / (h - 1) : 0));
    fl_xyline(x, y + i, x + w - 1);
  }
}

// Rectángulo redondeado con degradado vertical (fila a fila).
inline void rgrad(int x, int y, int w, int h, int r, unsigned top, unsigned bottom) {
  if (w <= 0 || h <= 0) return;
  r = std::min(r, std::min(w, h) / 2);
  for (int i = 0; i < h; i++) {
    double d = i < r ? r - i - 0.5 : (i >= h - r ? i - (h - r) + 0.5 : 0);
    int in = d > 0 ? (int)std::lround(r - std::sqrt(std::max(0.0, r * r - d * d))) : 0;
    color(mixu(top, bottom, h > 1 ? (double)i / (h - 1) : 0));
    fl_xyline(x + in, y + i, x + w - 1 - in);
  }
}

inline void rpath(double x, double y, double w, double h, double r) {
  fl_arc(x + w - r, y + r, r, 0, 90);
  fl_arc(x + r, y + r, r, 90, 180);
  fl_arc(x + r, y + h - r, r, 180, 270);
  fl_arc(x + w - r, y + h - r, r, 270, 360);
}

// El borde (suavizado) de un rectángulo redondeado.
inline void rline(int x, int y, int w, int h, int r, unsigned c) {
  color(c);
  fl_begin_loop();
  rpath(x + 0.5, y + 0.5, w - 1, h - 1, r);
  fl_end_loop();
}

typedef std::vector<std::pair<double, double>> Pts;

// Un polígono convexo con degradado vertical y, si se pide, su borde.
inline void poly(const Pts& p, unsigned top, unsigned bottom, int edge = -1) {
  double y0 = 1e9, y1 = -1e9;
  for (auto& v : p) { y0 = std::min(y0, v.second); y1 = std::max(y1, v.second); }
  for (int y = (int)std::floor(y0); y < (int)std::ceil(y1); y++) {
    double yc = y + 0.5, xl = 1e9, xr = -1e9;
    for (size_t i = 0; i < p.size(); i++) {
      auto a = p[i], b = p[(i + 1) % p.size()];
      if ((a.second <= yc && b.second > yc) || (b.second <= yc && a.second > yc)) {
        double x = a.first + (yc - a.second) * (b.first - a.first) / (b.second - a.second);
        xl = std::min(xl, x);
        xr = std::max(xr, x);
      }
    }
    if (xl < xr) {
      color(mixu(top, bottom, (yc - y0) / std::max(1.0, y1 - y0)));
      fl_xyline((int)std::lround(xl), y, (int)std::lround(xr) - 1);
    }
  }
  if (edge >= 0) {
    color((unsigned)edge);
    fl_begin_loop();
    for (auto& v : p) fl_vertex(v.first, v.second);
    fl_end_loop();
  }
}

inline void disc(double cx, double cy, double r, unsigned c) {
  color(c);
  fl_begin_polygon();
  fl_circle(cx, cy, r);
  fl_end_polygon();
}

inline void ring(double cx, double cy, double r, unsigned c) {
  color(c);
  fl_begin_loop();
  fl_circle(cx, cy, r);
  fl_end_loop();
}

inline void thick(double w) { fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, std::max(1, (int)std::lround(w))); }
inline void thin() { fl_line_style(0); }

inline void seg(double x0, double y0, double x1, double y1) {
  fl_begin_line();
  fl_vertex(x0, y0);
  fl_vertex(x1, y1);
  fl_end_line();
}

// ---- iconos (dibujados en código: 48 unidades los iconos, 20 los glifos)
enum Icon {
  IcFolder, IcFile, IcText, IcImage, IcAudio, IcVideo, IcArchive, IcPdf, IcCode, IcApp,
  IcSheet, IcSlides, IcDoc, IcWeb, IcFont, IcDisk, IcDrive, IcComputer, IcDesktop, IcHome,
  IcDownloads, IcDocuments, IcPictures, IcMusic, IcVideos, IcTrash, IcStar, IcMany,
  IcWarn, IcAsk, IcInfo,
  GBack, GForward, GUp, GRefresh, GFolders, GNewFolder, GCut, GCopy, GPaste, GDelete,
  GProps, GHidden, GIcons, GList, GDetails, GSearch, GClose, GPlus, GStar
};

void draw_icon(int kind, double x, double y, double s, bool dim = false, const std::string& ext = "");

// La carpeta amarilla (con hojas dentro) y, encima, el símbolo de su tipo.
void folder_icon(double x, double y, double k, bool dim, int overlay) {
  auto P = [&](double a, double b) { return std::make_pair(x + a * k, y + b * k); };
  unsigned edge = dimc(0xb3842a, dim);
  poly({P(3, 8), P(17, 8), P(21, 12), P(45, 12), P(45, 41), P(3, 41)}, dimc(0xe7bb52, dim), dimc(0xc9962e, dim), (int)edge);
  poly({P(8, 14), P(41, 14), P(41, 36), P(8, 36)}, dimc(0xffffff, dim), dimc(0xe9eef4, dim), (int)dimc(0xbcc6d1, dim));
  poly({P(11, 11), P(38, 11), P(38, 30), P(11, 30)}, dimc(0xfcfdfe, dim), dimc(0xf0f3f7, dim), (int)dimc(0xc9d1da, dim));
  poly({P(2, 18), P(46, 18), P(44, 43), P(4, 43)}, dimc(0xfde7a0, dim), dimc(0xf1bd45, dim), (int)edge);
  color(dimc(0xfff7d6, dim));
  seg(x + 3.5 * k, y + 19.5 * k, x + 44.5 * k, y + 19.5 * k);
  if (overlay >= 0) draw_icon(overlay, x + 22 * k, y + 22 * k, 22 * k, dim);
}

void page_icon(double x, double y, double k, bool dim, unsigned top = 0xffffff, unsigned bottom = 0xf0f3f7) {
  auto P = [&](double a, double b) { return std::make_pair(x + a * k, y + b * k); };
  poly({P(9, 3), P(30, 3), P(40, 13), P(40, 45), P(9, 45)}, dimc(top, dim), dimc(bottom, dim), (int)dimc(0x8b98aa, dim));
  poly({P(30, 3), P(30, 13), P(40, 13)}, dimc(0xf4f7fa, dim), dimc(0xd9e1ea, dim), (int)dimc(0x8b98aa, dim));
}

// Una etiqueta de color con la extensión (PDF, DOCX…) sobre la hoja.
void badge(double x, double y, double k, bool dim, unsigned c, const std::string& text) {
  auto P = [&](double a, double b) { return std::make_pair(x + a * k, y + b * k); };
  poly({P(4, 26), P(32, 26), P(32, 39), P(4, 39)}, dimc(mixu(c, 0xffffff, 0.15), dim), dimc(c, dim), (int)dimc(mixu(c, 0, 0.25), dim));
  if (k * 48 >= 30 && !text.empty()) {
    std::string t = text.substr(0, 4);
    for (auto& ch : t) ch = (char)toupper((unsigned char)ch);
    int sz = std::max(6, (int)std::lround(9 * k * (t.size() > 3 ? 0.85 : 1)));
    fl_font(FL_HELVETICA_BOLD, sz);
    color(0xffffff);
    int tw = (int)fl_width(t.c_str());
    fl_draw(t.c_str(), (int)std::lround(x + 18 * k - tw / 2.0), (int)std::lround(y + 33 * k + sz / 2.8));
  }
}

void star_shape(double cx, double cy, double R, double r, unsigned top, unsigned bottom, unsigned edge) {
  Pts p;
  for (int i = 0; i < 10; i++) {
    double a = -M_PI / 2 + i * M_PI / 5, rr = i % 2 ? r : R;
    p.push_back({cx + rr * std::cos(a), cy + rr * std::sin(a)});
  }
  // No es convexa: se rellena con FLTK (polígono complejo) y se bordea.
  fl_color(rgb(mixu(top, bottom, 0.5)));
  fl_begin_complex_polygon();
  for (auto& v : p) fl_vertex(v.first, v.second);
  fl_end_complex_polygon();
  color(top);
  fl_begin_complex_polygon();
  for (auto& v : p) fl_vertex(v.first, std::min(v.second, cy));
  fl_end_complex_polygon();
  color(edge);
  fl_begin_loop();
  for (auto& v : p) fl_vertex(v.first, v.second);
  fl_end_loop();
}

void monitor(double x, double y, double k, bool dim, unsigned s1, unsigned s2) {
  auto P = [&](double a, double b) { return std::make_pair(x + a * k, y + b * k); };
  poly({P(19, 33), P(29, 33), P(31, 40), P(17, 40)}, dimc(0xa7b1bd, dim), dimc(0x7d8794, dim));
  poly({P(11, 40), P(37, 40), P(38, 44), P(10, 44)}, dimc(0x8d97a3, dim), dimc(0x5f6975, dim), (int)dimc(0x4d5560, dim));
  poly({P(3, 5), P(45, 5), P(45, 34), P(3, 34)}, dimc(0x5d6876, dim), dimc(0x2c333c, dim), (int)dimc(0x22282f, dim));
  poly({P(6, 8), P(42, 8), P(42, 31), P(6, 31)}, dimc(s1, dim), dimc(s2, dim));
  color(dimc(mixu(s1, 0xffffff, 0.45), dim));
  seg(x + 6.5 * k, y + 8.5 * k, x + 41.5 * k, y + 8.5 * k);
}

void draw_icon(int kind, double x, double y, double s, bool dim, const std::string& ext) {
  double k = s / 48.0;   // iconos
  double g = s / 20.0;   // glifos de la barra
  auto P = [&](double a, double b) { return std::make_pair(x + a * k, y + b * k); };
  auto Q = [&](double a, double b) { return std::make_pair(x + a * g, y + b * g); };
  switch (kind) {
  case IcFolder: folder_icon(x, y, k, dim, -1); break;
  case IcDocuments: folder_icon(x, y, k, dim, IcText); break;
  case IcPictures: folder_icon(x, y, k, dim, IcImage); break;
  case IcMusic: folder_icon(x, y, k, dim, IcAudio); break;
  case IcVideos: folder_icon(x, y, k, dim, IcVideo); break;
  case IcDownloads: {
    folder_icon(x, y, k, dim, -1);
    poly({P(29, 22), P(37, 22), P(37, 31), P(42, 31), P(33, 41), P(24, 31), P(29, 31)}, dimc(0x6cc24a, dim), dimc(0x2f8f2f, dim), (int)dimc(0x22702a, dim));
    break;
  }
  case IcFile: page_icon(x, y, k, dim); if (!ext.empty()) badge(x, y, k, dim, 0x8a96a3, ext); break;
  case IcText: {
    page_icon(x, y, k, dim);
    color(dimc(0x9aa6b5, dim));
    for (int i = 0; i < 6; i++) seg(x + 14 * k, y + (17 + i * 4.5) * k, x + (i == 5 ? 26 : 35) * k, y + (17 + i * 4.5) * k);
    break;
  }
  case IcImage: {
    page_icon(x, y, k, dim);
    poly({P(13, 15), P(36, 15), P(36, 39), P(13, 39)}, dimc(0x6fbcf2, dim), dimc(0xd9efff, dim), (int)dimc(0x7d93ab, dim));
    disc(x + 30 * k, y + 21 * k, 3 * k, dimc(0xffd54a, dim));
    poly({P(13.5, 38.5), P(13.5, 32), P(20, 26), P(27, 32), P(30, 29), P(35.5, 34), P(35.5, 38.5)}, dimc(0x6cbf45, dim), dimc(0x3a8a27, dim));
    break;
  }
  case IcAudio: {
    page_icon(x, y, k, dim);
    unsigned c = dimc(0x7b4fc9, dim);
    disc(x + 18.5 * k, y + 35 * k, 3.6 * k, c);
    disc(x + 30.5 * k, y + 32 * k, 3.6 * k, c);
    poly({P(21, 18), P(33.6, 14.5), P(33.6, 32), P(31.8, 32), P(31.8, 19.5), P(22.4, 22.2), P(22.4, 35), P(21, 35)}, c, c);
    break;
  }
  case IcVideo: {
    page_icon(x, y, k, dim);
    poly({P(12, 17), P(37, 17), P(37, 37), P(12, 37)}, dimc(0x4a5260, dim), dimc(0x22262e, dim));
    color(dimc(0xffffff, dim));
    for (int i = 0; i < 6; i++) {
      fl_rectf((int)(x + (14 + i * 4) * k), (int)(y + 18.5 * k), std::max(1, (int)(2 * k)), std::max(1, (int)(1.6 * k)));
      fl_rectf((int)(x + (14 + i * 4) * k), (int)(y + 34 * k), std::max(1, (int)(2 * k)), std::max(1, (int)(1.6 * k)));
    }
    poly({P(21, 22.5), P(30, 27), P(21, 31.5)}, dimc(0xffffff, dim), dimc(0xdfe6ee, dim));
    break;
  }
  case IcArchive: {
    page_icon(x, y, k, dim, 0xfff6e5, 0xf2dfbd);
    for (int i = 0; i < 7; i++) {
      color(dimc(i % 2 ? 0xc9a66b : 0x8a6d3b, dim));
      fl_rectf((int)(x + (i % 2 ? 24 : 21) * k), (int)(y + (5 + i * 3.2) * k), std::max(1, (int)(3.5 * k)), std::max(1, (int)(3 * k)));
    }
    poly({P(20, 28), P(28, 28), P(28, 38), P(20, 38)}, dimc(0xa3824d, dim), dimc(0x7a5d2d, dim), (int)dimc(0x5e4520, dim));
    break;
  }
  case IcPdf: page_icon(x, y, k, dim); badge(x, y, k, dim, 0xd93025, "PDF"); break;
  case IcCode: page_icon(x, y, k, dim); badge(x, y, k, dim, 0x37474f, ext.empty() ? "</>" : ext); break;
  case IcSheet: page_icon(x, y, k, dim); badge(x, y, k, dim, 0x1e8e3e, ext); break;
  case IcSlides: page_icon(x, y, k, dim); badge(x, y, k, dim, 0xe8710a, ext); break;
  case IcDoc: page_icon(x, y, k, dim); badge(x, y, k, dim, 0x2b6cd4, ext); break;
  case IcWeb: page_icon(x, y, k, dim); badge(x, y, k, dim, 0x0b8bd6, ext); break;
  case IcFont: page_icon(x, y, k, dim); badge(x, y, k, dim, 0x5b5b66, ext); break;
  case IcDisk: {
    poly({P(6, 10), P(42, 10), P(42, 40), P(6, 40)}, dimc(0xeef1f5, dim), dimc(0xbfc7d1, dim), (int)dimc(0x7d8794, dim));
    disc(x + 24 * k, y + 25 * k, 11 * k, dimc(0xd3dae3, dim));
    ring(x + 24 * k, y + 25 * k, 11 * k, dimc(0x8f9aa7, dim));
    disc(x + 24 * k, y + 25 * k, 3 * k, dimc(0x8f9aa7, dim));
    break;
  }
  case IcApp: {
    poly({P(5, 8), P(43, 8), P(43, 41), P(5, 41)}, dimc(0xffffff, dim), dimc(0xe8eef6, dim), (int)dimc(0x5d7aa3, dim));
    poly({P(5, 8), P(43, 8), P(43, 15), P(5, 15)}, dimc(0x4a8ee0, dim), dimc(0x2a62b8, dim));
    poly({P(10, 20), P(22, 20), P(22, 36), P(10, 36)}, dimc(0xd6e6f8, dim), dimc(0xb6cfee, dim));
    color(dimc(0x9fb3c9, dim));
    for (int i = 0; i < 4; i++) seg(x + 26 * k, y + (22 + i * 4) * k, x + 38 * k, y + (22 + i * 4) * k);
    break;
  }
  case IcDrive: {
    rgrad((int)(x + 4 * k), (int)(y + 13 * k), (int)(40 * k), (int)(23 * k), (int)(4 * k), dimc(0xf4f6f9, dim), dimc(0xb3bcc7, dim));
    rline((int)(x + 4 * k), (int)(y + 13 * k), (int)(40 * k), (int)(23 * k), (int)(4 * k), dimc(0x77818e, dim));
    poly({P(7, 28), P(41, 28), P(41, 33), P(7, 33)}, dimc(0x8d97a4, dim), dimc(0x646e7a, dim));
    disc(x + 37 * k, y + 30.5 * k, 1.6 * k, dimc(0x52e05a, dim));
    break;
  }
  case IcComputer: monitor(x, y, k, dim, 0x1f78d1, 0x93cdf6); break;
  case IcDesktop: monitor(x, y, k, dim, 0x2aa198, 0xa6e3d7); break;
  case IcHome: {
    poly({P(9, 23), P(39, 23), P(39, 44), P(9, 44)}, dimc(0xf6e9cf, dim), dimc(0xe0c595, dim), (int)dimc(0xa07f45, dim));
    poly({P(3, 25), P(24, 5), P(45, 25)}, dimc(0xe0605a, dim), dimc(0xa83a36, dim), (int)dimc(0x8a2c28, dim));
    poly({P(20, 31), P(28, 31), P(28, 44), P(20, 44)}, dimc(0x9c6a3a, dim), dimc(0x6f4824, dim));
    poly({P(31, 28), P(36, 28), P(36, 33), P(31, 33)}, dimc(0xbfe3ff, dim), dimc(0x8cc8f5, dim));
    break;
  }
  case IcTrash: {
    poly({P(11, 13), P(37, 13), P(34, 45), P(14, 45)}, dimc(0xeef2f6, dim), dimc(0xa9b4c0, dim), (int)dimc(0x6c7784, dim));
    color(dimc(0x8f9aa7, dim));
    for (int i = 0; i < 3; i++) seg(x + (18 + i * 6) * k, y + 18 * k, x + (18.5 + i * 5.5) * k, y + 41 * k);
    poly({P(8, 8), P(40, 8), P(40, 13), P(8, 13)}, dimc(0xd3dae2, dim), dimc(0x9aa6b3, dim), (int)dimc(0x6c7784, dim));
    poly({P(19, 4), P(29, 4), P(29, 8), P(19, 8)}, dimc(0xc0c9d3, dim), dimc(0x9aa6b3, dim), (int)dimc(0x6c7784, dim));
    break;
  }
  case IcStar: star_shape(x + 24 * k, y + 25 * k, 21 * k, 9 * k, dimc(0xffe27a, dim), dimc(0xf1a81e, dim), dimc(0xc7861a, dim)); break;
  case IcMany: {
    page_icon(x - 5 * k, y - 1 * k, k * 0.95, dim);
    page_icon(x + 3 * k, y + 2 * k, k * 0.95, dim);
    break;
  }
  case IcWarn: {
    poly({P(24, 4), P(45, 42), P(3, 42)}, dimc(0xffe066, dim), dimc(0xf2b01e, dim), (int)dimc(0xb07a0c, dim));
    poly({P(22, 16), P(26, 16), P(25.2, 31), P(22.8, 31)}, 0x3b2f12, 0x3b2f12);
    disc(x + 24 * k, y + 36 * k, 2.3 * k, 0x3b2f12);
    break;
  }
  case IcAsk: case IcInfo: {
    disc(x + 24 * k, y + 24 * k, 20 * k, dimc(0x2f7fd8, dim));
    disc(x + 24 * k, y + 20 * k, 16 * k, dimc(0x5a9ce6, dim));
    ring(x + 24 * k, y + 24 * k, 20 * k, dimc(0x1d5aa8, dim));
    fl_font(FL_HELVETICA_BOLD, std::max(8, (int)std::lround(26 * k)));
    color(0xffffff);
    const char* t = kind == IcAsk ? "?" : "i";
    fl_draw(t, (int)std::lround(x + 24 * k - fl_width(t) / 2), (int)std::lround(y + 33 * k));
    break;
  }
  // ---- glifos de las barras (20 unidades)
  case GBack: case GForward: {
    unsigned c = dim ? 0xf3f5f8 : 0xffffff;
    Pts p = {Q(4, 10), Q(10, 4), Q(10, 7.6), Q(16, 7.6), Q(16, 12.4), Q(10, 12.4), Q(10, 16)};
    if (kind == GForward) for (auto& v : p) v.first = 2 * x + 20 * g - v.first;
    poly(p, c, c, (int)(dim ? 0xb8c2ce : 0x2a5b9c));
    break;
  }
  case GUp: {
    folder_icon(x - 1 * g, y + 2 * g, g * 20 / 48.0 * 0.95, dim, -1);
    poly({Q(13, 1.5), Q(19, 7.5), Q(16, 7.5), Q(16, 13), Q(10, 13), Q(10, 7.5), Q(7, 7.5)}, dimc(0x67c25a, dim), dimc(0x2f8a32, dim), (int)dimc(0x23702a, dim));
    break;
  }
  case GRefresh: {
    color(dimc(0x2f7fd8, dim));
    thick(2 * g);
    fl_begin_line();
    fl_arc(x + 10 * g, y + 10 * g, 6 * g, 60, 330);
    fl_end_line();
    thin();
    double a = 60 * M_PI / 180;
    double ex = x + 10 * g + 6 * g * std::cos(a), ey = y + 10 * g - 6 * g * std::sin(a);
    poly({{ex + 3.5 * g, ey - 2.5 * g}, {ex + 2.5 * g, ey + 4 * g}, {ex - 3 * g, ey + 1 * g}}, dimc(0x2f7fd8, dim), dimc(0x2f7fd8, dim));
    break;
  }
  case GFolders: {
    color(dimc(th(0x8a98aa, 0xaab5c3), dim));
    seg(x + 4 * g, y + 8 * g, x + 4 * g, y + 15 * g);
    seg(x + 4 * g, y + 15 * g, x + 8 * g, y + 15 * g);
    folder_icon(x + 0 * g, y + 1 * g, g * 9 / 48.0, dim, -1);
    folder_icon(x + 8 * g, y + 10 * g, g * 10 / 48.0, dim, -1);
    break;
  }
  case GNewFolder: {
    folder_icon(x, y + 2 * g, g * 18 / 48.0, dim, -1);
    unsigned c = dimc(0x2f9e44, dim);
    thick(2.2 * g);
    color(c);
    seg(x + 15.5 * g, y + 1.5 * g, x + 15.5 * g, y + 8.5 * g);
    seg(x + 12 * g, y + 5 * g, x + 19 * g, y + 5 * g);
    thin();
    break;
  }
  case GCut: {
    color(dimc(0x6b7785, dim));
    thick(1.6 * g);
    seg(x + 7 * g, y + 12 * g, x + 14 * g, y + 2 * g);
    seg(x + 13 * g, y + 12 * g, x + 6 * g, y + 2 * g);
    thin();
    color(dimc(0x2b5797, dim));
    thick(1.8 * g);
    fl_begin_loop(); fl_circle(x + 5.5 * g, y + 15 * g, 2.8 * g); fl_end_loop();
    fl_begin_loop(); fl_circle(x + 14.5 * g, y + 15 * g, 2.8 * g); fl_end_loop();
    thin();
    break;
  }
  case GCopy: {
    poly({Q(3, 2), Q(12, 2), Q(12, 13), Q(3, 13)}, dimc(0xffffff, dim), dimc(0xe8eef5, dim), (int)dimc(0x5d7aa3, dim));
    poly({Q(8, 6), Q(17, 6), Q(17, 18), Q(8, 18)}, dimc(0xffffff, dim), dimc(0xe8eef5, dim), (int)dimc(0x5d7aa3, dim));
    color(dimc(0x9fb3c9, dim));
    for (int i = 0; i < 3; i++) seg(x + 10 * g, y + (9.5 + i * 2.6) * g, x + 15 * g, y + (9.5 + i * 2.6) * g);
    break;
  }
  case GPaste: {
    poly({Q(3, 3), Q(15, 3), Q(15, 18), Q(3, 18)}, dimc(0xd9a35a, dim), dimc(0xa8742f, dim), (int)dimc(0x7d5420, dim));
    poly({Q(6.5, 1.5), Q(11.5, 1.5), Q(11.5, 5), Q(6.5, 5)}, dimc(0xdfe5ec, dim), dimc(0xa9b4c0, dim), (int)dimc(0x6c7784, dim));
    poly({Q(9, 8), Q(18, 8), Q(18, 19), Q(9, 19)}, dimc(0xffffff, dim), dimc(0xedf1f6, dim), (int)dimc(0x5d7aa3, dim));
    break;
  }
  case GDelete: {
    color(dimc(0xd9342b, dim));
    thick(2.8 * g);
    seg(x + 5 * g, y + 5 * g, x + 15 * g, y + 15 * g);
    seg(x + 15 * g, y + 5 * g, x + 5 * g, y + 15 * g);
    thin();
    break;
  }
  case GProps: {
    poly({Q(3, 1.5), Q(13, 1.5), Q(13, 18), Q(3, 18)}, dimc(0xffffff, dim), dimc(0xeaf0f6, dim), (int)dimc(0x7b8a9c, dim));
    color(dimc(0xa6b3c2, dim));
    for (int i = 0; i < 3; i++) seg(x + 5 * g, y + (5 + i * 3) * g, x + 11 * g, y + (5 + i * 3) * g);
    disc(x + 14 * g, y + 14 * g, 5 * g, dimc(0x2f7fd8, dim));
    color(0xffffff);
    thick(1.6 * g);
    seg(x + 14 * g, y + 13 * g, x + 14 * g, y + 16.5 * g);
    thin();
    disc(x + 14 * g, y + 11 * g, 0.9 * g, 0xffffff);
    break;
  }
  case GHidden: {
    color(dimc(th(0x4a5a6e, 0xaab5c3), dim));
    thick(1.4 * g);
    fl_begin_loop();
    for (int i = 0; i <= 20; i++) { double t = i / 20.0; fl_vertex(x + (2 + 16 * t) * g, y + (10 - 5.5 * std::sin(t * M_PI)) * g); }
    for (int i = 20; i >= 0; i--) { double t = i / 20.0; fl_vertex(x + (2 + 16 * t) * g, y + (10 + 5.5 * std::sin(t * M_PI)) * g); }
    fl_end_loop();
    thin();
    disc(x + 10 * g, y + 10 * g, 3.4 * g, dimc(0x2b6cd4, dim));
    disc(x + 10 * g, y + 10 * g, 1.4 * g, 0x10203a);
    break;
  }
  case GIcons: {
    for (int i = 0; i < 4; i++) {
      double a = 3 + (i % 2) * 8, b = 3 + (i / 2) * 8;
      poly({Q(a, b), Q(a + 6, b), Q(a + 6, b + 6), Q(a, b + 6)}, dimc(0x7fa3d6, dim), dimc(0x3f6fb5, dim), (int)dimc(0x2f5a96, dim));
    }
    break;
  }
  case GList: {
    for (int i = 0; i < 4; i++) {
      double b = 3 + i * 4;
      poly({Q(3, b), Q(6, b), Q(6, b + 3), Q(3, b + 3)}, dimc(0x7fa3d6, dim), dimc(0x3f6fb5, dim));
      color(dimc(th(0x6c7a8c, 0xaab5c3), dim));
      seg(x + 8 * g, y + (b + 1.5) * g, x + 17 * g, y + (b + 1.5) * g);
    }
    break;
  }
  case GDetails: {
    poly({Q(2, 3), Q(18, 3), Q(18, 6), Q(2, 6)}, dimc(0xc8d6e8, dim), dimc(0xa9bdd8, dim));
    color(dimc(th(0x6c7a8c, 0xaab5c3), dim));
    for (int i = 0; i < 3; i++) {
      double b = 9 + i * 3.6;
      seg(x + 2 * g, y + b * g, x + 9 * g, y + b * g);
      seg(x + 11 * g, y + b * g, x + 14 * g, y + b * g);
      seg(x + 15.5 * g, y + b * g, x + 18 * g, y + b * g);
    }
    break;
  }
  case GSearch: {
    color(dimc(th(0x5d6b7c, 0xaab5c3), dim));
    thick(1.8 * g);
    fl_begin_loop(); fl_circle(x + 8 * g, y + 8 * g, 5 * g); fl_end_loop();
    thick(2.6 * g);
    seg(x + 11.8 * g, y + 11.8 * g, x + 16.5 * g, y + 16.5 * g);
    thin();
    break;
  }
  case GClose: {
    color(dimc(th(0x5d6b7c, 0xaab5c3), dim));
    thick(1.5 * g);
    seg(x + 6 * g, y + 6 * g, x + 14 * g, y + 14 * g);
    seg(x + 14 * g, y + 6 * g, x + 6 * g, y + 14 * g);
    thin();
    break;
  }
  case GPlus: {
    color(dimc(th(0x4a5a6e, 0xaab5c3), dim));
    thick(1.8 * g);
    seg(x + 10 * g, y + 4 * g, x + 10 * g, y + 16 * g);
    seg(x + 4 * g, y + 10 * g, x + 16 * g, y + 10 * g);
    thin();
    break;
  }
  case GStar: star_shape(x + 10 * g, y + 10.5 * g, 8.5 * g, 3.7 * g, dimc(0xffe27a, dim), dimc(0xf1a81e, dim), dimc(0xc7861a, dim)); break;
  }
}

// Un icono como imagen de FLTK (para los botones de las barras).
class Glyph : public Fl_Image {
public:
  Glyph(int kind, int size, bool dim = false) : Fl_Image(size, size, 0), kind_(kind), dim_(dim) {}
  using Fl_Image::draw;
  void draw(int X, int Y, int W, int H, int cx = 0, int cy = 0) override {
    (void)W; (void)H; (void)cx; (void)cy;
    // FLTK escribe el texto del botón después, con el color y la letra de
    // ahora: se dejan como estaban.
    Fl_Color c = fl_color();
    Fl_Font f = fl_font();
    Fl_Fontsize s = fl_size();
    draw_icon(kind_, X, Y, w(), dim_);
    fl_font(f, s);
    fl_color(c);
  }

private:
  int kind_;
  bool dim_;
};

// ---- textos
std::string fmt(const char* tpl, std::initializer_list<std::string> args) {
  std::string out = tpl;
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = out.find(key); p != std::string::npos; p = out.find(key, p + a.size())) out.replace(p, key.size(), a);
  }
  return out;
}

std::string lower(std::string s) {
  for (auto& c : s) c = (char)tolower((unsigned char)c);
  return s;
}

// La clave para ordenar y buscar: minúsculas y sin tildes.
std::string fold(const std::string& s) {
  std::string out;
  const char* p = s.c_str();
  const char* end = p + s.size();
  while (p < end) {
    int len = 0;
    unsigned c = fl_utf8decode(p, end, &len);
    if (len < 1) len = 1;
    p += len;
    c = (unsigned)fl_tolower(c);
    if (c >= 0xe0 && c <= 0xe5) c = 'a';
    else if (c == 0xe7) c = 'c';
    else if (c >= 0xe8 && c <= 0xeb) c = 'e';
    else if (c >= 0xec && c <= 0xef) c = 'i';
    else if (c == 0xf1) c = 'n';
    else if ((c >= 0xf2 && c <= 0xf6) || c == 0xf8) c = 'o';
    else if (c >= 0xf9 && c <= 0xfc) c = 'u';
    else if (c == 0xfd || c == 0xff) c = 'y';
    char buf[8];
    int n = fl_utf8encode(c, buf);
    out.append(buf, n);
  }
  return out;
}

// Orden «natural»: archivo2 va antes que archivo10.
int natcmp(const std::string& a, const std::string& b) {
  size_t i = 0, j = 0;
  while (i < a.size() && j < b.size()) {
    unsigned char ca = a[i], cb = b[j];
    if (isdigit(ca) && isdigit(cb)) {
      size_t i2 = i, j2 = j;
      while (i2 < a.size() && isdigit((unsigned char)a[i2])) i2++;
      while (j2 < b.size() && isdigit((unsigned char)b[j2])) j2++;
      size_t ia = i, jb = j;
      while (ia + 1 < i2 && a[ia] == '0') ia++;
      while (jb + 1 < j2 && b[jb] == '0') jb++;
      if (i2 - ia != j2 - jb) return i2 - ia < j2 - jb ? -1 : 1;
      int c = a.compare(ia, i2 - ia, b, jb, j2 - jb);
      if (c) return c < 0 ? -1 : 1;
      i = i2;
      j = j2;
      continue;
    }
    if (ca != cb) return ca < cb ? -1 : 1;
    i++;
    j++;
  }
  size_t ra = a.size() - i, rb = b.size() - j;
  return ra < rb ? -1 : ra > rb ? 1 : 0;
}

// Buscar: un trozo del nombre o un patrón con * y ?.
bool glob(const std::string& p, const std::string& s) {
  size_t i = 0, j = 0, star = std::string::npos, mark = 0;
  while (j < s.size()) {
    if (i < p.size() && (p[i] == '?' || p[i] == s[j])) { i++; j++; }
    else if (i < p.size() && p[i] == '*') { star = i++; mark = j; }
    else if (star != std::string::npos) { i = star + 1; j = ++mark; }
    else return false;
  }
  while (i < p.size() && p[i] == '*') i++;
  return i == p.size();
}

bool matches(const std::string& key, const std::string& query) {
  if (query.empty()) return true;
  if (query.find_first_of("*?") != std::string::npos) return glob(query, key);
  return key.find(query) != std::string::npos;
}

std::string group(uintmax_t v) {
  std::string s = std::to_string(v), out;
  const char sep = tx::DECIMAL[0] == ',' ? '.' : ',';
  int n = 0;
  for (int i = (int)s.size() - 1; i >= 0; i--) {
    out.insert(out.begin(), s[i]);
    if (++n % 3 == 0 && i > 0) out.insert(out.begin(), sep);
  }
  return out;
}

std::string size_text(uintmax_t b) {
  if (b < BASE) return fmt(tx::BYTES, {group(b)});
  static const char* units[] = {"KB", "MB", "GB", "TB", "PB"};
  double v = (double)b;
  int u = -1;
  while (v >= BASE && u < 4) { v /= BASE; u++; }
  char buf[32];
  std::snprintf(buf, sizeof buf, v < 10 ? "%.2f" : v < 100 ? "%.1f" : "%.0f", v);
  std::string s = buf;
  for (auto& c : s) if (c == '.') c = tx::DECIMAL[0];
  return s + " " + units[u];
}

std::string date_text(time_t t) {
  if (t <= 0) return "";
  char buf[64];
  std::tm* tm = std::localtime(&t);
  if (!tm || !std::strftime(buf, sizeof buf, tx::DATE_FMT, tm)) return "";
  return buf;
}

// Lo que cabe en [w] píxeles, con «…» al final si no cabe entero.
std::string ellipsis(const std::string& s, int w) {
  if (w <= 0) return "";
  if (fl_width(s.c_str()) <= w) return s;
  std::vector<size_t> cuts;
  for (size_t i = 0; i < s.size();) {
    int n = fl_utf8len(s[i]);
    i += n < 1 ? 1 : n;
    cuts.push_back(i);
  }
  int lo = 0, hi = (int)cuts.size() - 1, best = -1;
  while (lo <= hi) {
    int mid = (lo + hi) / 2;
    std::string t = s.substr(0, cuts[mid]) + "\xe2\x80\xa6";
    if (fl_width(t.c_str()) <= w) { best = mid; lo = mid + 1; } else hi = mid - 1;
  }
  return best < 0 ? "\xe2\x80\xa6" : s.substr(0, cuts[best]) + "\xe2\x80\xa6";
}

// El nombre en dos líneas como mucho (la segunda, con «…»).
std::vector<std::string> wrap2(const std::string& s, int w) {
  std::vector<std::string> out;
  if (fl_width(s.c_str()) <= w) return {s};
  size_t i = 0, fit = 0, brk = std::string::npos;
  while (i < s.size()) {
    int n = fl_utf8len(s[i]);
    size_t next = i + (n < 1 ? 1 : n);
    if (fl_width(s.c_str(), (int)next) > w) break;
    if (s[i] == ' ' || s[i] == '-' || s[i] == '_' || s[i] == '.') brk = next;
    i = next;
    fit = i;
  }
  size_t cut = brk != std::string::npos && brk > 0 ? brk : fit;
  if (cut == 0) cut = 1;
  out.push_back(s.substr(0, cut));
  out.push_back(ellipsis(s.substr(cut), w));
  return out;
}

// ---- rutas: UTF-8 por dentro en todos los sistemas
inline fs::path P(const std::string& s) { return fs::u8path(s); }
inline std::string U(const fs::path& p) { return p.u8string(); }
inline bool is_virtual(const std::string& p) { return p.rfind("::", 0) == 0; }
inline std::string join(const std::string& dir, const std::string& name) { return U(P(dir) / P(name)); }
inline std::string base_name(const std::string& p) { return U(P(p).filename()); }

#ifdef _WIN32
std::wstring W(const std::string& s) {
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  if (n) MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
  return w;
}
std::string N(const std::wstring& w) {
  int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), nullptr, 0, nullptr, nullptr);
  std::string s(n, '\0');
  if (n) WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), &s[0], n, nullptr, nullptr);
  return s;
}
#endif

// ¿Son la misma ruta? (En Windows, sin distinguir mayúsculas.)
bool same(const std::string& a, const std::string& b) {
#ifdef _WIN32
  return lower(a) == lower(b);
#else
  return a == b;
#endif
}

// ¿Está [path] dentro de [dir] (o es la misma)?
bool inside(const std::string& path, const std::string& dir) {
  if (dir.empty() || is_virtual(dir) || is_virtual(path)) return false;
  std::string a = path, b = dir;
#ifdef _WIN32
  a = lower(a);
  b = lower(b);
#endif
  if (a == b) return true;
  if (a.compare(0, b.size(), b) != 0) return false;
  char last = b.back();
  if (last == '/' || last == '\\') return true;
  return a.size() > b.size() && (a[b.size()] == '/' || a[b.size()] == '\\');
}

std::string home_dir() {
#ifdef _WIN32
  if (const wchar_t* h = _wgetenv(L"USERPROFILE")) return N(h);
  return "C:\\";
#else
  if (const char* h = getenv("HOME")) return h;
  if (passwd* pw = getpwuid(getuid())) return pw->pw_dir;
  return "/";
#endif
}

// Las carpetas del usuario: 0 escritorio, 1 descargas, 2 documentos,
// 3 imágenes, 4 música, 5 vídeos.
std::string user_dir(int which) {
#ifdef _WIN32
  static const GUID ids[] = {
    {0xB4BFCC3A, 0xDB2C, 0x424C, {0xB0, 0x29, 0x7F, 0xE9, 0x9A, 0x87, 0xC6, 0x41}},
    {0x374DE290, 0x123F, 0x4565, {0x91, 0x64, 0x39, 0xC4, 0x92, 0x5E, 0x46, 0x7B}},
    {0xFDD39AD0, 0x238F, 0x46AF, {0xAD, 0xB4, 0x6C, 0x85, 0x48, 0x03, 0x69, 0xC7}},
    {0x33E28130, 0x4E1E, 0x4676, {0x83, 0x5A, 0x98, 0x39, 0x5C, 0x3B, 0xC3, 0xBB}},
    {0x4BD8D571, 0x6D19, 0x48D3, {0xBE, 0x97, 0x42, 0x22, 0x20, 0x08, 0x0E, 0x43}},
    {0x18989B1D, 0x99B5, 0x455B, {0x84, 0x1C, 0xAB, 0x7C, 0x74, 0xE4, 0xDD, 0xFC}},
  };
  PWSTR p = nullptr;
  std::string out;
  if (SUCCEEDED(SHGetKnownFolderPath(ids[which], 0, nullptr, &p)) && p) out = N(p);
  if (p) CoTaskMemFree(p);
  if (!out.empty()) return out;
#endif
#ifdef __APPLE__
  static const char* names[] = {"Desktop", "Downloads", "Documents", "Pictures", "Music", "Movies"};
#else
  static const char* names[] = {"Desktop", "Downloads", "Documents", "Pictures", "Music", "Videos"};
#endif
  return join(home_dir(), names[which]);
}

std::string config_dir() {
  if (const char* o = getenv("DMS_EXPLORER_CONFIG")) return o;
#ifdef _WIN32
  if (const wchar_t* a = _wgetenv(L"APPDATA")) return join(join(N(a), "DMarlon Studio"), "Explorer");
  return join(home_dir(), "DMarlon Studio Explorer");
#elif defined(__APPLE__)
  return join(home_dir(), "Library/Application Support/DMarlon Studio/Explorer");
#else
  const char* x = getenv("XDG_CONFIG_HOME");
  return join(x && *x ? x : join(home_dir(), ".config"), "dmarlon-studio-explorer");
#endif
}

// ---- datos de un archivo
struct Meta {
  bool ok = false, dir = false, link = false, hidden = false;
  uintmax_t size = 0;
  time_t mtime = 0, ctime = 0, atime = 0;
};

#ifdef _WIN32
time_t ft2t(const FILETIME& f) {
  ULARGE_INTEGER u;
  u.LowPart = f.dwLowDateTime;
  u.HighPart = f.dwHighDateTime;
  if (u.QuadPart < 116444736000000000ULL) return 0;
  return (time_t)((u.QuadPart - 116444736000000000ULL) / 10000000ULL);
}

Meta meta(const std::string& p) {
  Meta m;
  WIN32_FILE_ATTRIBUTE_DATA d;
  if (!GetFileAttributesExW(W(p).c_str(), GetFileExInfoStandard, &d)) return m;
  m.ok = true;
  m.dir = (d.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  m.link = (d.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
  m.hidden = (d.dwFileAttributes & (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM)) != 0;
  m.size = ((uintmax_t)d.nFileSizeHigh << 32) | d.nFileSizeLow;
  m.mtime = ft2t(d.ftLastWriteTime);
  m.ctime = ft2t(d.ftCreationTime);
  m.atime = ft2t(d.ftLastAccessTime);
  // La raíz de un disco no es oculta aunque lo diga.
  if (!P(p).has_relative_path()) m.hidden = false;
  return m;
}

bool read_only(const std::string& p) {
  DWORD a = GetFileAttributesW(W(p).c_str());
  return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_READONLY);
}
#else
Meta meta(const std::string& p) {
  Meta m;
  struct stat l, s;
  if (lstat(p.c_str(), &l) != 0) return m;
  m.ok = true;
  m.link = S_ISLNK(l.st_mode);
  const struct stat& st = (m.link && stat(p.c_str(), &s) == 0) ? s : l;
  m.dir = S_ISDIR(st.st_mode);
  m.size = (uintmax_t)st.st_size;
  m.mtime = st.st_mtime;
  m.atime = st.st_atime;
#ifdef __APPLE__
  m.ctime = st.st_birthtimespec.tv_sec;
  m.hidden = (l.st_flags & UF_HIDDEN) != 0;
#else
  m.ctime = st.st_ctime;
#endif
  std::string name = base_name(p);
  if (!name.empty() && name[0] == '.') m.hidden = true;
  return m;
}

bool read_only(const std::string& p) { return access(p.c_str(), W_OK) != 0; }
#endif

inline bool exists(const std::string& p) {
  std::error_code ec;
  return fs::exists(fs::symlink_status(P(p), ec));
}

struct Entry {
  std::string name, path, key, ext, type;
  uintmax_t size = 0, free = 0;
  time_t mtime = 0;
  bool dir = false, link = false, hidden = false, drive = false, bundle = false;
  int icon = IcFile;
};

// El icono y el tipo según la extensión.
int classify(const std::string& ext, std::string& type) {
  static const std::map<std::string, int> kinds = [] {
    std::map<std::string, int> m;
    auto add = [&](const char* list, int icon) {
      std::string s = list, e;
      for (size_t i = 0; i <= s.size(); i++) {
        if (i == s.size() || s[i] == ' ') { if (!e.empty()) m[e] = icon; e.clear(); }
        else e += s[i];
      }
    };
    add("txt md markdown log ini cfg conf nfo yaml yml toml", IcText);
    add("jpg jpeg png gif bmp tif tiff webp heic heif svg ico icns raw cr2 nef psd avif", IcImage);
    add("mp3 wav flac aac m4a ogg opus aiff aif wma mid midi", IcAudio);
    add("mp4 mov avi mkv wmv webm m4v mpg mpeg flv 3gp", IcVideo);
    add("zip rar 7z tar gz tgz bz2 xz zst jar", IcArchive);
    add("pdf", IcPdf);
    add("c cc cpp cxx h hh hpp hxx py js mjs ts tsx jsx java cs go rs rb php swift kt m mm dart pas pp lpr lpi sh bash zsh bat cmd ps1 lua pl r sql json xml", IcCode);
    add("html htm css url webloc", IcWeb);
    add("exe msi app com apk ipa command pkg deb rpm", IcApp);
    add("xls xlsx ods numbers csv tsv", IcSheet);
    add("ppt pptx odp key", IcSlides);
    add("doc docx odt pages rtf epub", IcDoc);
    add("ttf otf woff woff2 fon ttc", IcFont);
    add("iso dmg img vhd vhdx vmdk", IcDisk);
    return m;
  }();
  std::string up = ext;
  for (auto& c : up) c = (char)toupper((unsigned char)c);
  auto it = kinds.find(ext);
  int icon = it == kinds.end() ? IcFile : it->second;
  switch (icon) {
  case IcText: type = tx::TYPE_TEXT; break;
  case IcImage: type = fmt(tx::TYPE_IMAGE, {up}); break;
  case IcAudio: type = fmt(tx::TYPE_AUDIO, {up}); break;
  case IcVideo: type = fmt(tx::TYPE_VIDEO, {up}); break;
  case IcArchive: type = fmt(tx::TYPE_ARCHIVE, {up}); break;
  case IcPdf: type = tx::TYPE_PDF; break;
  case IcCode: type = fmt(tx::TYPE_CODE, {up}); break;
  case IcWeb: type = fmt(tx::TYPE_WEB, {up}); break;
  case IcApp: type = tx::TYPE_APP; break;
  case IcSheet: type = fmt(tx::TYPE_SHEET, {up}); break;
  case IcSlides: type = fmt(tx::TYPE_SLIDES, {up}); break;
  case IcDoc: type = fmt(tx::TYPE_DOC, {up}); break;
  case IcFont: type = fmt(tx::TYPE_FONT, {up}); break;
  case IcDisk: type = fmt(tx::TYPE_DISK, {up}); break;
  default: type = ext.empty() ? std::string(tx::TYPE_NOEXT) : fmt(tx::TYPE_FILE, {up});
  }
  return icon;
}

Entry make_entry(const std::string& path) {
  Entry e;
  e.path = path;
  e.name = base_name(path);
  if (e.name.empty()) e.name = path;
  Meta m = meta(path);
  e.dir = m.dir;
  e.link = m.link;
  e.hidden = m.hidden;
  e.size = m.dir ? 0 : m.size;
  e.mtime = m.mtime;
  size_t dot = e.name.find_last_of('.');
  if (dot != std::string::npos && dot > 0 && dot + 1 < e.name.size()) e.ext = lower(e.name.substr(dot + 1));
  if (e.dir) {
#ifdef __APPLE__
    e.bundle = e.ext == "app";
#endif
    e.icon = e.bundle ? IcApp : IcFolder;
    e.type = e.bundle ? tx::TYPE_APP : tx::TYPE_FOLDER;
  } else {
    e.icon = classify(e.ext, e.type);
  }
  if (e.link) e.type = fmt(tx::TYPE_LINK, {e.type});
  e.key = fold(e.name);
  return e;
}

// El texto de un error del sistema de archivos.
std::string error_text(const std::error_code& ec) {
  if (ec == std::errc::permission_denied || ec == std::errc::operation_not_permitted) return tx::ERR_DENIED;
  return ec.message();
}

bool list_dir(const std::string& dir, bool hidden, std::vector<Entry>& out, std::string& err) {
  out.clear();
  std::error_code ec;
  fs::directory_iterator it(P(dir), ec), end;
  if (ec) { err = error_text(ec); return false; }
  for (; it != end; it.increment(ec)) {
    if (ec) break;
    Entry e = make_entry(U(it->path()));
    if (hidden || !e.hidden) out.push_back(std::move(e));
  }
  if (ec) err = error_text(ec);
  return true;
}

// Las subcarpetas (para el árbol): nombre y ruta, en orden.
std::vector<std::pair<std::string, std::string>> subfolders(const std::string& dir, bool hidden, size_t limit = 100000) {
  std::vector<std::pair<std::string, std::string>> out;
  if (is_virtual(dir)) return out;
  std::error_code ec;
  fs::directory_iterator it(P(dir), ec), end;
  for (; !ec && it != end && out.size() < limit; it.increment(ec)) {
    std::string p = U(it->path());
    Meta m = meta(p);
    if (!m.dir || (m.hidden && !hidden)) continue;
#ifdef __APPLE__
    if (lower(p).size() > 4 && lower(p).compare(p.size() - 4, 4, ".app") == 0) continue;
#endif
    out.push_back({base_name(p), p});
  }
  std::sort(out.begin(), out.end(), [](const std::pair<std::string, std::string>& a, const std::pair<std::string, std::string>& b) {
    int c = natcmp(fold(a.first), fold(b.first));
    return c ? c < 0 : a.first < b.first;
  });
  return out;
}

// Carpetas primero; luego la columna elegida y, si empatan, el nombre.
bool less_entry(const Entry& a, const Entry& b, int col, bool desc) {
  if (a.dir != b.dir) return a.dir;
  int c = 0;
  switch (col) {
  case 1: c = a.drive ? (a.free < b.free ? -1 : a.free > b.free) : (a.mtime < b.mtime ? -1 : a.mtime > b.mtime); break;
  case 2: c = natcmp(fold(a.type), fold(b.type)); break;
  case 3: c = a.size < b.size ? -1 : a.size > b.size; break;
  }
  if (c == 0) c = natcmp(a.key, b.key);
  if (c == 0) c = a.name.compare(b.name);
  return desc ? c > 0 : c < 0;
}

// ---- discos (la vista Equipo)
struct Drive {
  std::string path, name, type;
  int icon = IcDrive;
  uintmax_t total = 0, free = 0;
};

void space_of(Drive& d) {
  std::error_code ec;
  fs::space_info s = fs::space(P(d.path), ec);
  if (!ec) { d.total = s.capacity; d.free = s.available; }
}

std::string mac_root_name() {
  std::error_code ec;
  for (fs::directory_iterator it(P("/Volumes"), ec), end; !ec && it != end; it.increment(ec)) {
    std::error_code e2;
    if (fs::is_symlink(it->symlink_status(e2)) && U(fs::read_symlink(it->path(), e2)) == "/") return U(it->path().filename());
  }
  return "Macintosh HD";
}

std::vector<Drive> drives() {
  std::vector<Drive> out;
#ifdef _WIN32
  UINT old = SetErrorMode(SEM_FAILCRITICALERRORS);
  DWORD mask = GetLogicalDrives();
  for (int i = 0; i < 26; i++) {
    if (!(mask & (1u << i))) continue;
    Drive d;
    d.path = std::string(1, (char)('A' + i)) + ":\\";
    std::wstring root = W(d.path);
    UINT t = GetDriveTypeW(root.c_str());
    d.type = t == DRIVE_REMOVABLE ? tx::TYPE_REMOVABLE : t == DRIVE_REMOTE ? tx::TYPE_NETDRIVE : t == DRIVE_CDROM ? tx::TYPE_CD : tx::TYPE_DRIVE;
    wchar_t label[MAX_PATH + 1] = L"";
    std::string name;
    if (t == DRIVE_FIXED || t == DRIVE_REMOTE || t == DRIVE_REMOVABLE) {
      if (GetVolumeInformationW(root.c_str(), label, MAX_PATH, nullptr, nullptr, nullptr, nullptr, 0)) name = N(label);
    }
    d.name = (name.empty() ? d.type : name) + " (" + d.path.substr(0, 2) + ")";
    if (t == DRIVE_FIXED || t == DRIVE_REMOTE) space_of(d);
    out.push_back(d);
  }
  SetErrorMode(old);
#else
  Drive root;
  root.path = "/";
#ifdef __APPLE__
  root.name = mac_root_name();
#else
  root.name = tx::TYPE_DRIVE;
#endif
  root.type = tx::TYPE_DRIVE;
  space_of(root);
  out.push_back(root);
#ifdef __APPLE__
  const char* places[] = {"/Volumes"};
#else
  std::string user = base_name(home_dir());
  std::string media = "/media/" + user, run = "/run/media/" + user;
  const char* places[] = {media.c_str(), run.c_str(), "/mnt"};
#endif
  for (const char* place : places) {
    std::error_code ec;
    for (fs::directory_iterator it(P(place), ec), end; !ec && it != end; it.increment(ec)) {
      std::error_code e2;
      if (fs::is_symlink(it->symlink_status(e2)) || ex::base_name(ex::U(it->path())).rfind(".", 0) == 0) continue;
      if (!fs::is_directory(it->status(e2))) continue;
      Drive d;
      d.path = U(it->path());
      d.name = U(it->path().filename());
      d.type = tx::TYPE_REMOVABLE;
      space_of(d);
      out.push_back(d);
    }
  }
#endif
  return out;
}

// El nombre que se ve de una ruta (la raíz de un disco, con su nombre).
std::string display_name(const std::string& p) {
  if (p == COMPUTER) return tx::COMPUTER;
  fs::path x = P(p);
  if (!x.has_relative_path()) {
#ifdef _WIN32
    for (auto& d : drives()) if (same(d.path, U(x))) return d.name;
#elif defined(__APPLE__)
    static std::string root = mac_root_name();
    return root;
#endif
    return U(x);
  }
  std::string n = U(x.filename());
  return n.empty() ? p : n;
}

std::string parent_of(const std::string& p) {
  if (is_virtual(p) || p.empty()) return "";
  fs::path x = P(p);
  if (!x.has_relative_path()) return COMPUTER;
  return U(x.parent_path());
}

std::string trash_dir() {
#ifdef __APPLE__
  return join(home_dir(), ".Trash");
#elif defined(_WIN32)
  return "";
#else
  return join(home_dir(), ".local/share/Trash/files");
#endif
}

// ---- abrir con el sistema, Papelera, terminal
#ifndef _WIN32
int spawn(const std::vector<std::string>& args, bool wait) {
  std::vector<char*> argv;
  for (auto& a : args) argv.push_back(const_cast<char*>(a.c_str()));
  argv.push_back(nullptr);
  pid_t pid;
  if (posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ) != 0) return -1;
  int st = 0;
  if (wait) {
    if (waitpid(pid, &st, 0) < 0) return -1;
    return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
  }
  std::thread([pid] { int s; waitpid(pid, &s, 0); }).detach();
  return 0;
}
#endif

bool os_open(const std::string& path) {
#ifdef _WIN32
  return (INT_PTR)ShellExecuteW(nullptr, L"open", W(path).c_str(), nullptr, nullptr, SW_SHOWNORMAL) > 32;
#elif defined(__APPLE__)
  return spawn({"open", path}, true) == 0;
#else
  return spawn({"xdg-open", path}, false) == 0;
#endif
}

bool os_reveal(const std::string& path) {
#ifdef _WIN32
  std::wstring args = L"/select,\"" + W(path) + L"\"";
  return (INT_PTR)ShellExecuteW(nullptr, L"open", L"explorer.exe", args.c_str(), nullptr, SW_SHOWNORMAL) > 32;
#elif defined(__APPLE__)
  return spawn({"open", "-R", path}, true) == 0;
#else
  return spawn({"xdg-open", parent_of(path)}, false) == 0;
#endif
}

bool os_terminal(const std::string& dir) {
#ifdef _WIN32
  return (INT_PTR)ShellExecuteW(nullptr, L"open", L"cmd.exe", nullptr, W(dir).c_str(), SW_SHOWNORMAL) > 32;
#elif defined(__APPLE__)
  return spawn({"open", "-a", "Terminal", dir}, true) == 0;
#else
  return spawn({"sh", "-c", "cd \"$1\" && exec x-terminal-emulator", "sh", dir}, false) == 0;
#endif
}

#ifdef __APPLE__
// Llamadas a Cocoa desde C++ (sin Objective-C): la clase, el mensaje y sus datos.
inline id cls(const char* n) { return (id)objc_getClass(n); }
inline SEL msel(const char* n) { return sel_registerName(n); }
inline id msg(id o, const char* s) { return ((id(*)(id, SEL))objc_msgSend)(o, msel(s)); }
inline id msg(id o, const char* s, id a) { return ((id(*)(id, SEL, id))objc_msgSend)(o, msel(s), a); }
inline id msg(id o, const char* s, id a, id b) { return ((id(*)(id, SEL, id, id))objc_msgSend)(o, msel(s), a, b); }
inline long msg_long(id o, const char* s) { return ((long(*)(id, SEL))objc_msgSend)(o, msel(s)); }
inline id nsstr(const std::string& v) {
  return ((id(*)(id, SEL, const char*))objc_msgSend)(cls("NSString"), msel("stringWithUTF8String:"), v.c_str());
}
inline std::string cstr(id s) {
  const char* c = s ? ((const char* (*)(id, SEL))objc_msgSend)(s, msel("UTF8String")) : nullptr;
  return c ? c : "";
}
#endif

// ---- el portapapeles de archivos del sistema: lo que se copia aquí se pega
// en otra ventana, en otro explorador, en el Finder o en el Explorador de
// Windows, y al revés.
#ifdef __APPLE__
const char* const CUT_TYPE = "com.dmarlonstudio.explorer.cut";
#endif

void clip_put(const std::vector<std::string>& paths, bool cut) {
#ifdef __APPLE__
  id pb = msg(cls("NSPasteboard"), "generalPasteboard");
  msg_long(pb, "clearContents");
  // Un elemento por archivo (su URL); el primero lleva además las rutas en
  // texto y, si es para mover, la marca de cortar.
  id list = msg(cls("NSMutableArray"), "array");
  std::string text;
  for (auto& p : paths) text += (text.empty() ? "" : "\n") + p;
  for (size_t i = 0; i < paths.size(); i++) {
    id item = msg(msg(cls("NSPasteboardItem"), "alloc"), "init");
    id url = msg(msg(cls("NSURL"), "fileURLWithPath:", nsstr(paths[i])), "absoluteString");
    msg(item, "setString:forType:", url, nsstr("public.file-url"));
    if (i == 0) {
      msg(item, "setString:forType:", nsstr(text), nsstr("public.utf8-plain-text"));
      if (cut) msg(item, "setString:forType:", nsstr("1"), nsstr(CUT_TYPE));
    }
    msg(list, "addObject:", item);
    msg(item, "release");
  }
  ((BOOL(*)(id, SEL, id))objc_msgSend)(pb, msel("writeObjects:"), list);
#elif defined(_WIN32)
  if (!OpenClipboard(nullptr)) return;
  EmptyClipboard();
  std::vector<std::wstring> w;
  size_t chars = 1;
  for (auto& p : paths) { w.push_back(W(p)); chars += w.back().size() + 1; }
  HGLOBAL h = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, sizeof(DROPFILES) + chars * sizeof(wchar_t));
  if (h) {
    auto* df = static_cast<DROPFILES*>(GlobalLock(h));
    df->pFiles = sizeof(DROPFILES);
    df->fWide = TRUE;
    auto* dst = reinterpret_cast<wchar_t*>(reinterpret_cast<char*>(df) + sizeof(DROPFILES));
    for (auto& s : w) { std::memcpy(dst, s.c_str(), s.size() * sizeof(wchar_t)); dst += s.size() + 1; }
    GlobalUnlock(h);
    SetClipboardData(CF_HDROP, h);
  }
  // Cortar o copiar, como lo entiende el Explorador de Windows.
  HGLOBAL e = GlobalAlloc(GMEM_MOVEABLE, sizeof(DWORD));
  if (e) {
    *static_cast<DWORD*>(GlobalLock(e)) = cut ? DROPEFFECT_MOVE : DROPEFFECT_COPY;
    GlobalUnlock(e);
    SetClipboardData(RegisterClipboardFormatW(L"Preferred DropEffect"), e);
  }
  CloseClipboard();
#else
  std::string s;
  for (auto& p : paths) s += "file://" + p + "\n";
  Fl::copy(s.c_str(), (int)s.size(), 1);
  (void)cut;
#endif
}

// Las rutas del portapapeles (vacío si no hay archivos) y si son para mover.
std::vector<std::string> clip_get(bool& cut) {
  std::vector<std::string> out;
  cut = false;
#ifdef __APPLE__
  id pb = msg(cls("NSPasteboard"), "generalPasteboard");
  id classes = msg(cls("NSArray"), "arrayWithObject:", cls("NSURL"));
  id yes = ((id(*)(id, SEL, BOOL))objc_msgSend)(cls("NSNumber"), msel("numberWithBool:"), YES);
  id opts = msg(cls("NSDictionary"), "dictionaryWithObject:forKey:", yes, nsstr("NSPasteboardURLReadingFileURLsOnlyKey"));
  id urls = msg(pb, "readObjectsForClasses:options:", classes, opts);
  long n = urls ? msg_long(urls, "count") : 0;
  for (long i = 0; i < n; i++) {
    id u = ((id(*)(id, SEL, unsigned long))objc_msgSend)(urls, msel("objectAtIndex:"), (unsigned long)i);
    std::string p = cstr(msg(u, "path"));
    if (!p.empty()) out.push_back(p);
  }
  cut = !out.empty() && msg(pb, "stringForType:", nsstr(CUT_TYPE)) != nullptr;
#elif defined(_WIN32)
  if (!IsClipboardFormatAvailable(CF_HDROP) || !OpenClipboard(nullptr)) return out;
  if (HANDLE h = GetClipboardData(CF_HDROP)) {
    auto drop = static_cast<HDROP>(h);
    UINT n = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < n; i++) {
      UINT len = DragQueryFileW(drop, i, nullptr, 0);
      std::wstring b(len + 1, L'\0');
      DragQueryFileW(drop, i, &b[0], len + 1);
      b.resize(len);
      out.push_back(N(b));
    }
  }
  if (HANDLE e = GetClipboardData(RegisterClipboardFormatW(L"Preferred DropEffect"))) {
    if (auto* v = static_cast<DWORD*>(GlobalLock(e))) {
      cut = (*v & DROPEFFECT_MOVE) != 0;
      GlobalUnlock(e);
    }
  }
  CloseClipboard();
#endif
  return out;
}

// ¿Hay archivos en el portapapeles? (Rápido: para activar Pegar.)
bool clip_has() {
#ifdef __APPLE__
  id pb = msg(cls("NSPasteboard"), "generalPasteboard");
  id types = msg(pb, "types");
  return types && ((BOOL(*)(id, SEL, id))objc_msgSend)(types, msel("containsObject:"), nsstr("public.file-url"));
#elif defined(_WIN32)
  return IsClipboardFormatAvailable(CF_HDROP) != 0;
#else
  return false;
#endif
}

// Un número que cambia cada vez que alguien usa el portapapeles.
long clip_seq() {
#ifdef __APPLE__
  return msg_long(msg(cls("NSPasteboard"), "generalPasteboard"), "changeCount");
#elif defined(_WIN32)
  return (long)GetClipboardSequenceNumber();
#else
  return 0;
#endif
}

void clip_clear() {
#ifdef __APPLE__
  msg_long(msg(cls("NSPasteboard"), "generalPasteboard"), "clearContents");
#elif defined(_WIN32)
  if (OpenClipboard(nullptr)) { EmptyClipboard(); CloseClipboard(); }
#endif
}

// ¿El sistema está en modo oscuro?
bool system_dark() {
#ifdef __APPLE__
  id d = msg(cls("NSUserDefaults"), "standardUserDefaults");
  return cstr(msg(d, "stringForKey:", nsstr("AppleInterfaceStyle"))) == "Dark";
#elif defined(_WIN32)
  DWORD v = 1, size = sizeof v;
  if (RegGetValueW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", L"AppsUseLightTheme",
                   RRF_RT_REG_DWORD, nullptr, &v, &size) != ERROR_SUCCESS) return false;
  return v == 0;
#else
  return false;
#endif
}

// La barra de título del sistema, clara u oscura como el tema.
void title_bar(Fl_Window* w, bool on) {
#ifdef __APPLE__
  (void)w;
  id ap = msg(cls("NSAppearance"), "appearanceNamed:", nsstr(on ? "NSAppearanceNameDarkAqua" : "NSAppearanceNameAqua"));
  msg(msg(cls("NSApplication"), "sharedApplication"), "setAppearance:", ap);
#elif defined(_WIN32)
  static auto set = reinterpret_cast<HRESULT(WINAPI*)(HWND, DWORD, LPCVOID, DWORD)>(
      reinterpret_cast<void*>(GetProcAddress(LoadLibraryW(L"dwmapi.dll"), "DwmSetWindowAttribute")));
  if (!set || !w->shown()) return;
  BOOL v = on;
  set(fl_xid(w), 20, &v, sizeof v);   // DWMWA_USE_IMMERSIVE_DARK_MODE
#else
  (void)w; (void)on;
#endif
}

// Mueve a la Papelera (false y [err] si no se puede).
bool to_trash(const std::string& path, std::string& err) {
#ifdef __APPLE__
  id fm = msg(cls("NSFileManager"), "defaultManager");
  id url = msg(cls("NSURL"), "fileURLWithPath:", nsstr(path));
  id error = nullptr;
  BOOL ok = ((BOOL(*)(id, SEL, id, id*, id*))objc_msgSend)(fm, msel("trashItemAtURL:resultingItemURL:error:"), url, nullptr, &error);
  if (!ok) err = error ? cstr(msg(error, "localizedDescription")) : "?";
  return ok;
#elif defined(_WIN32)
  std::wstring w = W(path);
  std::vector<wchar_t> from(w.begin(), w.end());
  from.push_back(0);
  from.push_back(0);
  SHFILEOPSTRUCTW op{};
  op.wFunc = FO_DELETE;
  op.pFrom = from.data();
  // FOF_WANTNUKEWARNING: si no se puede reciclar, Windows avisa antes de borrar.
  op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT | FOF_NOERRORUI | FOF_WANTNUKEWARNING;
  int r = SHFileOperationW(&op);
  if (r != 0 || op.fAnyOperationsAborted) { err = "SHFileOperation " + std::to_string(r); return false; }
  return true;
#else
  if (spawn({"gio", "trash", "--", path}, true) == 0) return true;
  err = "gio trash";
  return false;
#endif
}

// ---- archivos de texto con rutas UTF-8
std::string read_file(const std::string& p) {
#ifdef _WIN32
  FILE* f = _wfopen(W(p).c_str(), L"rb");
#else
  FILE* f = fopen(p.c_str(), "rb");
#endif
  std::string out;
  if (!f) return out;
  char buf[8192];
  size_t n;
  while ((n = fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  fclose(f);
  return out;
}

bool write_file(const std::string& p, const std::string& data) {
  std::error_code ec;
  fs::create_directories(P(p).parent_path(), ec);
  std::string tmp = p + ".tmp";
#ifdef _WIN32
  FILE* f = _wfopen(W(tmp).c_str(), L"wb");
#else
  FILE* f = fopen(tmp.c_str(), "wb");
#endif
  if (!f) return false;
  bool ok = fwrite(data.data(), 1, data.size(), f) == data.size();
  ok = fclose(f) == 0 && ok;
  if (ok) fs::rename(P(tmp), P(p), ec);
  return ok && !ec;
}

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
      o += n == 't' ? '\t' : n == 'n' ? '\n' : n;
    } else o += s[i];
  }
  return o;
}

std::vector<std::string> split(const std::string& s, char sep) {
  std::vector<std::string> out(1);
  for (char c : s) {
    if (c == sep) out.emplace_back();
    else out.back() += c;
  }
  return out;
}

// ---- marcadores: una carpeta (un nivel) y si salen en la barra
struct Mark {
  std::string name, path, desc, folder;
  bool bar = false;
};

void save_marks(const std::string& file, const std::vector<std::string>& folders, const std::vector<Mark>& marks) {
  std::string s = "# DMarlon Studio Explorer bookmarks v1\n";
  for (auto& f : folders) s += "F\t" + esc(f) + "\n";
  for (auto& m : marks) s += "B\t" + esc(m.folder) + "\t" + esc(m.name) + "\t" + esc(m.path) + "\t" + esc(m.desc) + "\t" + (m.bar ? "1" : "0") + "\n";
  write_file(file, s);
}

bool load_marks(const std::string& file, std::vector<std::string>& folders, std::vector<Mark>& marks) {
  if (!exists(file)) return false;
  folders.clear();
  marks.clear();
  for (auto& line : split(read_file(file), '\n')) {
    auto f = split(line, '\t');
    if (f[0] == "F" && f.size() >= 2) folders.push_back(unesc(f[1]));
    if (f[0] == "B" && f.size() >= 6) marks.push_back({unesc(f[2]), unesc(f[3]), unesc(f[4]), unesc(f[1]), f[5] == "1"});
  }
  return true;
}

// ---- nombres nuevos
std::string unique_in(const std::string& dir, const std::string& name, bool is_dir) {
  if (!exists(join(dir, name))) return name;
  std::string stem = name, ext;
  size_t dot = name.find_last_of('.');
  if (!is_dir && dot != std::string::npos && dot > 0) { stem = name.substr(0, dot); ext = name.substr(dot); }
  for (int i = 2; i < 100000; i++) {
    std::string n = stem + " (" + std::to_string(i) + ")" + ext;
    if (!exists(join(dir, n))) return n;
  }
  return name;
}

// «informe - copia.txt», «informe - copia (2).txt»…
std::string copy_name(const std::string& dir, const std::string& name, bool is_dir) {
  std::string stem = name, ext;
  size_t dot = name.find_last_of('.');
  if (!is_dir && dot != std::string::npos && dot > 0) { stem = name.substr(0, dot); ext = name.substr(dot); }
  return unique_in(dir, stem + tx::COPY_SUFFIX + ext, is_dir);
}

// Lo que no puede llevar un nombre (en Windows, más cosas).
std::string bad_chars() {
#ifdef _WIN32
  return "\\/:*?\"<>|";
#else
  return "/";
#endif
}

// ---- copiar, mover y eliminar en otro hilo
struct Job {
  enum Kind { Copy, Move, Remove };
  Kind kind = Copy;
  std::vector<std::pair<std::string, std::string>> items;   // origen → destino
  std::vector<bool> replace;
  std::string dest;
  std::atomic<bool> cancel{false}, done{false};
  std::atomic<long> total{0}, count{0};
  std::mutex mu;
  std::string current;
  std::vector<std::string> errors;

  void fail(const std::string& what, const std::error_code& ec) {
    std::lock_guard<std::mutex> lock(mu);
    if (errors.size() < 200) errors.push_back(what + ": " + error_text(ec));
  }
  void now(const std::string& what) {
    std::lock_guard<std::mutex> lock(mu);
    current = what;
  }
};

long count_files(const fs::path& p, Job& j) {
  std::error_code ec;
  auto st = fs::symlink_status(p, ec);
  if (ec || !fs::is_directory(st)) return 1;
  long n = 0;
  for (fs::recursive_directory_iterator it(p, fs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
    if (j.cancel) break;
    std::error_code e2;
    if (!fs::is_directory(it->symlink_status(e2))) n++;
  }
  return std::max(1L, n);
}

void copy_tree(const fs::path& s, const fs::path& d, bool overwrite, Job& j) {
  if (j.cancel) return;
  std::error_code ec;
  auto st = fs::symlink_status(s, ec);
  if (ec) { j.fail(U(s), ec); return; }
  if (fs::is_symlink(st)) {
    if (overwrite && exists(U(d))) fs::remove(d, ec);
    fs::copy_symlink(s, d, ec);
    if (ec) j.fail(U(s), ec);
    j.count++;
    return;
  }
  if (fs::is_directory(st)) {
    if (!fs::is_directory(d)) fs::create_directory(d, s, ec);
    if (ec) { j.fail(U(d), ec); return; }
    fs::directory_iterator it(s, ec), end;
    if (ec) { j.fail(U(s), ec); return; }
    for (; it != end && !j.cancel; it.increment(ec)) {
      if (ec) { j.fail(U(s), ec); break; }
      copy_tree(it->path(), d / it->path().filename(), overwrite, j);
    }
    return;
  }
  j.now(U(s.filename()));
  fs::copy_file(s, d, overwrite ? fs::copy_options::overwrite_existing : fs::copy_options::none, ec);
  if (ec) j.fail(U(s), ec);
  j.count++;
}

void run_job(std::shared_ptr<Job> j) {
  if (j->kind != Job::Move) {
    long n = 0;
    for (auto& it : j->items) n += count_files(P(it.first), *j);
    j->total = n;
  } else {
    j->total = (long)j->items.size();
  }
  for (size_t i = 0; i < j->items.size() && !j->cancel; i++) {
    fs::path s = P(j->items[i].first), d = P(j->items[i].second);
    bool over = i < j->replace.size() && j->replace[i];
    std::error_code ec;
    if (j->kind == Job::Remove) {
      j->now(U(s.filename()));
      fs::remove_all(s, ec);
      if (ec) j->fail(U(s), ec);
      j->count += count_files(s, *j);
      continue;
    }
    if (j->kind == Job::Move) {
      j->now(U(s.filename()));
      if (!over || !fs::is_directory(fs::symlink_status(d, ec))) {
        if (over && exists(U(d))) fs::remove(d, ec);
        fs::rename(s, d, ec);
        if (!ec) { j->count++; continue; }
      }
      // Otro disco (o carpeta que se combina): copiar y luego borrar.
      size_t before = j->errors.size();
      ec.clear();
      copy_tree(s, d, over, *j);
      if (!j->cancel && j->errors.size() == before) fs::remove_all(s, ec);
      if (ec) j->fail(U(s), ec);
      continue;
    }
    copy_tree(s, d, over, *j);
  }
  j->done = true;
}

// ---- el tamaño de una selección (para Propiedades), en otro hilo
struct SizeJob {
  std::atomic<bool> cancel{false}, done{false};
  std::atomic<uintmax_t> bytes{0};
  std::atomic<long> files{0}, dirs{0};
};

void count_size(std::shared_ptr<SizeJob> j, std::vector<std::string> paths) {
  for (auto& p : paths) {
    if (j->cancel) break;
    std::error_code ec;
    auto st = fs::symlink_status(P(p), ec);
    if (fs::is_directory(st)) {
      for (fs::recursive_directory_iterator it(P(p), fs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        if (j->cancel) break;
        std::error_code e2;
        auto s2 = it->symlink_status(e2);
        if (fs::is_directory(s2)) j->dirs++;
        else {
          j->files++;
          if (fs::is_regular_file(s2)) {
            uintmax_t n = it->file_size(e2);
            if (!e2) j->bytes += n;
          }
        }
      }
    } else if (!ec) {
      j->files++;
      if (fs::is_regular_file(st)) {
        uintmax_t n = fs::file_size(P(p), ec);
        if (!ec) j->bytes += n;
      }
    }
  }
  j->done = true;
}

// ---- cajas de la interfaz (degradados del estilo Aero)
enum {
  BX_NAV = FL_FREE_BOXTYPE, BX_CMD, BX_BAR, BX_PANE, BX_STATUS, BX_HOVER, BX_DOWN, BX_ON,
  BX_FIELD, BX_BTN, BX_BTN_DOWN, BX_ORB, BX_ORB_HOVER, BX_ORB_DOWN, BX_MENU, BX_FOOTER
};

void box_nav(int x, int y, int w, int h, Fl_Color) {
  vgrad(x, y, w, h, th(0xe6eff9, 0x2d3542), th(0xcadbef, 0x232932));
  color(th(0xf7faff, 0x3a4352)); fl_xyline(x, y, x + w - 1);
  color(th(0x9fb4cf, 0x12161b)); fl_xyline(x, y + h - 1, x + w - 1);
}
void box_cmd(int x, int y, int w, int h, Fl_Color) {
  int half = h / 2;
  vgrad(x, y, w, half, th(0xfbfdff, 0x2f3540), th(0xeff5fb, 0x2a3039));
  vgrad(x, y + half, w, h - half, th(0xe2ebf6, 0x252a32), th(0xe8eff8, 0x272c34));
  color(th(0xa7b9d0, 0x14181d)); fl_xyline(x, y + h - 1, x + w - 1);
}
void box_bar(int x, int y, int w, int h, Fl_Color) {
  vgrad(x, y, w, h, th(0xf8fafd, 0x272c34), th(0xedf2f9, 0x23272e));
  color(th(0xcfd9e6, 0x171a1f)); fl_xyline(x, y + h - 1, x + w - 1);
}
void box_pane(int x, int y, int w, int h, Fl_Color) {
  vgrad(x, y, w, h, th(0xf9fbfe, 0x262b32), th(0xe6edf7, 0x1f2329));
  color(th(0xc3d0e2, 0x343b46)); fl_xyline(x, y, x + w - 1);
}
void box_status(int x, int y, int w, int h, Fl_Color) {
  vgrad(x, y, w, h, th(0xf4f7fb, 0x23272d), th(0xe7edf5, 0x1d2025));
  color(th(0xc8d3e2, 0x343b46)); fl_xyline(x, y, x + w - 1);
}
void box_hover(int x, int y, int w, int h, Fl_Color) {
  rgrad(x + 1, y + 1, w - 2, h - 2, 3, th(0xfdfeff, 0x3a4b63), th(0xe2edfb, 0x2f3d52));
  rline(x, y, w, h, 3, th(0x9dbde6, 0x5279ad));
}
void box_down(int x, int y, int w, int h, Fl_Color) {
  rgrad(x + 1, y + 1, w - 2, h - 2, 3, th(0xc6daf2, 0x24344a), th(0xdbe8f8, 0x2d4058));
  rline(x, y, w, h, 3, th(0x7b9ecb, 0x4a6fa3));
}
void box_on(int x, int y, int w, int h, Fl_Color) {
  rgrad(x + 1, y + 1, w - 2, h - 2, 3, th(0xe4eefb, 0x33445c), th(0xcfe0f6, 0x2b3a4f));
  rline(x, y, w, h, 3, th(0x8eaed8, 0x4f72a3));
}
void box_field(int x, int y, int w, int h, Fl_Color) {
  color(th(0xffffff, 0x1a1d22)); fl_rectf(x + 1, y + 1, w - 2, h - 2);
  rline(x, y, w, h, 2, Fl::draw_box_active() ? th(0x8fa5c2, 0x4a5566) : th(0xc5ced9, 0x343b46));
}
void box_btn(int x, int y, int w, int h, Fl_Color) {
  bool on = Fl::draw_box_active();
  int half = h / 2;
  if (dark) {
    rgrad(x + 1, y + 1, w - 2, h - 2, 2, on ? 0x434a55 : 0x30353c, on ? 0x353b44 : 0x2b3036);
    rline(x, y, w, h, 3, on ? 0x67717f : 0x434a55);
    return;
  }
  rgrad(x + 1, y + 1, w - 2, half, 2, on ? 0xf7f7f7 : 0xf4f4f4, on ? 0xebebeb : 0xf0f0f0);
  rgrad(x + 1, y + half, w - 2, h - half - 1, 2, on ? 0xdddddd : 0xeeeeee, on ? 0xd0d0d0 : 0xe8e8e8);
  rline(x, y, w, h, 3, on ? 0x8a8a8a : 0xbdbdbd);
}
void box_btn_down(int x, int y, int w, int h, Fl_Color) {
  rgrad(x + 1, y + 1, w - 2, h - 2, 2, th(0xe4f3fc, 0x2d4a6b), th(0xc4e3f5, 0x27405d));
  rline(x, y, w, h, 3, th(0x2c628b, 0x4f86c6));
}
void orb(int x, int y, int w, int h, unsigned top, unsigned bottom, unsigned edge) {
  int s = std::min(w, h), ox = x + (w - s) / 2, oy = y + (h - s) / 2;
  rgrad(ox, oy, s, s, s / 2, top, bottom);
  rgrad(ox + s / 5, oy + 2, s * 3 / 5, s * 2 / 5, s / 5, mixu(top, 0xffffff, 0.55), mixu(top, 0xffffff, 0.1));
  rline(ox, oy, s, s, s / 2, edge);
}
void box_orb(int x, int y, int w, int h, Fl_Color) {
  if (Fl::draw_box_active()) orb(x, y, w, h, 0x4f93dc, 0x1b4f95, 0x1a467f);
  else if (dark) orb(x, y, w, h, 0x4a525e, 0x3a414b, 0x2b3038);
  else orb(x, y, w, h, 0xdfe5ec, 0xb9c3cf, 0x9eaab8);
}
void box_orb_hover(int x, int y, int w, int h, Fl_Color) { orb(x, y, w, h, 0x63b0f5, 0x2166b8, 0x1a467f); }
void box_orb_down(int x, int y, int w, int h, Fl_Color) { orb(x, y, w, h, 0x2d6db5, 0x163f78, 0x10325f); }
void box_menu(int x, int y, int w, int h, Fl_Color) {
  vgrad(x, y, w, h, th(0xfcfdff, 0x2a2f37), th(0xe9eff7, 0x252a31));
  color(th(0xd3dce8, 0x171a1f)); fl_xyline(x, y + h - 1, x + w - 1);
}
void box_footer(int x, int y, int w, int h, Fl_Color) {
  color(th(0xf0f0f0, 0x2a2e35)); fl_rectf(x, y, w, h);
  color(th(0xdfdfdf, 0x3a404a)); fl_xyline(x, y, x + w - 1);
}

void setup_boxes() {
  Fl::set_boxtype((Fl_Boxtype)BX_NAV, box_nav, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_CMD, box_cmd, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_BAR, box_bar, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_PANE, box_pane, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_STATUS, box_status, 0, 1, 0, 1);
  Fl::set_boxtype((Fl_Boxtype)BX_HOVER, box_hover, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_DOWN, box_down, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_ON, box_on, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_FIELD, box_field, 3, 2, 6, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_BTN, box_btn, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_BTN_DOWN, box_btn_down, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_ORB, box_orb, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_ORB_HOVER, box_orb_hover, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_ORB_DOWN, box_orb_down, 0, 0, 0, 0);
  Fl::set_boxtype((Fl_Boxtype)BX_MENU, box_menu, 2, 2, 4, 4);
  Fl::set_boxtype((Fl_Boxtype)BX_FOOTER, box_footer, 0, 0, 0, 0);
}

inline Fl_Boxtype bx(int b) { return (Fl_Boxtype)b; }

// La selección de una fila o un icono: azul claro con borde (gris sin foco).
void draw_selection(int x, int y, int w, int h, bool selected, bool hover, bool focused) {
  if (selected && focused) {
    rgrad(x + 1, y + 1, w - 2, h - 2, 3, hover ? th(0xe6f1fd, 0x335583) : th(0xdcebfc, 0x2c4a72), hover ? th(0xcbe2fc, 0x2b4a74) : th(0xc1dbfc, 0x264066));
    rline(x, y, w, h, 3, th(0x7da2ce, 0x4a7cc0));
  } else if (selected) {
    rgrad(x + 1, y + 1, w - 2, h - 2, 3, th(0xf8f8f8, 0x30353d), th(0xe5e5e5, 0x2b3037));
    rline(x, y, w, h, 3, th(0xc4c4c4, 0x4a515c));
  } else if (hover) {
    rgrad(x + 1, y + 1, w - 2, h - 2, 3, th(0xfafcff, 0x262f3b), th(0xe8f1fd, 0x232b36));
    rline(x, y, w, h, 3, th(0xb8d6fb, 0x3c5170));
  }
}

// Las pausas de una lista larga en un menú emergente (FLTK interpreta «/», «&», «_»).
std::string menu_label(const std::string& s) {
  std::string out;
  for (char c : s) {
    if (c == '/' || c == '\\' || c == '&' || c == '_') out += '\\';
    out += c;
  }
  return out;
}

}  // namespace ex

// ===================================================== componentes propios
const int SB = 16;   // ancho de las barras de desplazamiento

// La vista de archivos: iconos grandes, lista o detalles.
class FileView : public Fl_Group {
public:
  enum { Icons, List, Details };
  std::vector<ex::Entry> items;
  std::vector<char> sel;
  int mode = Icons, focus = -1, anchor = -1, hover = -1, hover_col = -1;
  int sort_col = 0;
  bool desc = false, drives = false;
  int colw[4] = {300, 150, 170, 100};
  std::string heads[4];
  std::string empty_text;
  std::set<std::string> faded;   // cortados: se ven desvaídos
  int scroll = 0, editing = -1;
  std::function<void(int)> on_open;
  std::function<void()> on_select;
  std::function<void(int, int, int)> on_menu;
  std::function<void(int)> on_sort;
  std::function<void(int, const std::string&)> on_rename;
  std::function<int(int)> on_key;
  Fl_Scrollbar* vbar;
  Fl_Scrollbar* hbar;
  Fl_Input* edit;

  FileView(int X, int Y, int W, int H) : Fl_Group(X, Y, W, H) {
    box(FL_NO_BOX);
    vbar = new Fl_Scrollbar(X + W - SB, Y, SB, H);
    vbar->type(FL_VERTICAL);
    vbar->callback(scrolled, this);
    hbar = new Fl_Scrollbar(X, Y + H - SB, W, SB);
    hbar->type(FL_HORIZONTAL);
    hbar->callback(scrolled, this);
    hbar->hide();
    edit = new Fl_Input(X, Y, 10, 10);
    edit->hide();
    edit->box(FL_BORDER_BOX);
    edit->textsize(ex::UI);
    edit->when(FL_WHEN_ENTER_KEY_ALWAYS);
    edit->callback(edited, this);
    end();
    resizable(nullptr);
  }

  // ---- geometría
  static const int HEAD = 24;
  int row_h() const { return 22; }
  int cell_w() const { return drives ? 260 : 104; }
  int cell_h() const { return drives ? 66 : 100; }
  int list_cw = 200;
  int ax() const { return x() + 1; }
  int ay() const { return y() + 1 + (mode == Details ? HEAD : 0); }
  int aw() const { return w() - 2 - (vbar->visible() ? SB : 0); }
  int ah() const { return h() - 2 - (mode == Details ? HEAD : 0) - (hbar->visible() ? SB : 0); }
  int cols() const { return std::max(1, (aw() - 8) / cell_w()); }
  int rows() const { return std::max(1, (ah() - 4) / row_h()); }
  int n() const { return (int)items.size(); }
  int names_w() const { return colw[0] + colw[1] + colw[2] + colw[3]; }

  int content() const {
    if (mode == Icons) return 8 + ((n() + cols() - 1) / cols()) * cell_h();
    if (mode == List) return 4 + ((n() + rows() - 1) / rows()) * list_cw;
    return 4 + n() * row_h();
  }
  int viewport() const { return mode == List ? aw() : ah(); }

  void item_rect(int i, int& X, int& Y, int& W, int& H) const {
    if (mode == Icons) {
      int c = cols();
      X = ax() + 4 + (i % c) * cell_w();
      Y = ay() + 4 + (i / c) * cell_h() - scroll;
      W = cell_w() - 4;
      H = cell_h() - 4;
    } else if (mode == List) {
      int r = rows();
      X = ax() + 2 + (i / r) * list_cw - scroll;
      Y = ay() + 2 + (i % r) * row_h();
      W = list_cw - 4;
      H = row_h();
    } else {
      X = ax() + 1;
      Y = ay() + 2 + i * row_h() - scroll;
      W = std::min(names_w(), aw() - 2);
      H = row_h();
    }
  }

  int hit(int mx, int my) const {
    if (mx < ax() || my < ay() || mx >= ax() + aw() || my >= ay() + ah()) return -1;
    int i = -1;
    if (mode == Icons) {
      int c = (mx - ax() - 4) / cell_w(), r = (my - ay() - 4 + scroll) / cell_h();
      if (mx - ax() - 4 < 0 || my - ay() - 4 + scroll < 0 || c >= cols()) return -1;
      i = r * cols() + c;
    } else if (mode == List) {
      int c = (mx - ax() - 2 + scroll) / list_cw, r = (my - ay() - 2) / row_h();
      if (my - ay() - 2 < 0 || r >= rows()) return -1;
      i = c * rows() + r;
    } else {
      if (my - ay() - 2 + scroll < 0) return -1;
      i = (my - ay() - 2 + scroll) / row_h();
    }
    if (i < 0 || i >= n()) return -1;
    int X, Y, W, H;
    item_rect(i, X, Y, W, H);
    if (mode == List) {
      fl_font(FL_HELVETICA, ex::UI);
      W = std::min(W, 26 + (int)fl_width(items[i].name.c_str()));
    }
    return mx >= X && mx < X + W && my >= Y && my < Y + H ? i : -1;
  }

  void clamp_scroll() { scroll = std::max(0, std::min(scroll, content() - viewport())); }

  void update_bars() {
    if (mode == List) {
      vbar->hide();
      hbar->hide();
      fl_font(FL_HELVETICA, ex::UI);
      int widest = 80;
      for (auto& e : items) widest = std::max(widest, (int)fl_width(e.name.c_str()));
      list_cw = std::min(320, widest + 34);
      if (content() > aw()) hbar->show();
      hbar->resize(x() + 1, y() + h() - 1 - SB, w() - 2, SB);
    } else {
      hbar->hide();
      vbar->hide();
      if (content() > ah()) vbar->show();
      vbar->resize(x() + w() - 1 - SB, ay(), SB, ah());
    }
    clamp_scroll();
    if (mode == List) {
      hbar->value(scroll, aw(), 0, std::max(content(), aw()));
      hbar->linesize(list_cw / 2);
    } else {
      vbar->value(scroll, ah(), 0, std::max(content(), ah()));
      vbar->linesize(mode == Icons ? cell_h() / 2 : row_h());
    }
  }

  void resize(int X, int Y, int W, int H) override {
    Fl_Group::resize(X, Y, W, H);
    finish_rename(true);
    update_bars();
  }

  // ---- datos
  void set_items(std::vector<ex::Entry> v, const std::vector<std::string>& keep, int scroll_to) {
    finish_rename(true);
    items = std::move(v);
    sel.assign(items.size(), 0);
    focus = anchor = hover = -1;
    for (int i = 0; i < n(); i++) {
      for (auto& k : keep) {
        if (items[i].name == k) {
          sel[i] = 1;
          if (focus < 0) focus = anchor = i;
        }
      }
    }
    scroll = scroll_to;
    update_bars();
    if (focus >= 0 && scroll_to == 0) ensure_visible(focus);
    redraw();
  }

  std::vector<int> selected() const {
    std::vector<int> out;
    for (int i = 0; i < n(); i++) if (sel[i]) out.push_back(i);
    return out;
  }
  std::vector<std::string> selected_names() const {
    std::vector<std::string> out;
    for (int i : selected()) out.push_back(items[i].name);
    return out;
  }
  std::vector<std::string> selected_paths() const {
    std::vector<std::string> out;
    for (int i : selected()) out.push_back(items[i].path);
    return out;
  }

  void select_only(int i) {
    std::fill(sel.begin(), sel.end(), 0);
    if (i >= 0 && i < n()) sel[i] = 1;
  }
  void select_range(int a, int b) {
    std::fill(sel.begin(), sel.end(), 0);
    for (int i = std::min(a, b); i <= std::max(a, b); i++) if (i >= 0 && i < n()) sel[i] = 1;
  }
  void select_all() { std::fill(sel.begin(), sel.end(), 1); changed(); }
  void invert() { for (auto& s : sel) s = !s; changed(); }
  void changed() { redraw(); if (on_select) on_select(); }

  void ensure_visible(int i) {
    if (i < 0 || i >= n()) return;
    int X, Y, W, H;
    item_rect(i, X, Y, W, H);
    if (mode == List) {
      if (X < ax()) scroll -= ax() - X + 2;
      else if (X + W > ax() + aw()) scroll += X + W - ax() - aw() + 4;
    } else {
      if (Y < ay()) scroll -= ay() - Y + 2;
      else if (Y + H > ay() + ah()) scroll += Y + H - ay() - ah() + 4;
    }
    update_bars();
    redraw();
  }

  void scroll_by(int d) {
    scroll += d;
    update_bars();
    redraw();
  }

  static void scrolled(Fl_Widget* w, void* p) {
    auto* v = static_cast<FileView*>(p);
    v->scroll = static_cast<Fl_Scrollbar*>(w)->value();
    v->finish_rename(true);
    v->redraw();
  }

  // ---- cambiar el nombre aquí mismo
  void start_rename(int i) {
    if (i < 0 || i >= n() || items[i].drive) return;
    ensure_visible(i);
    editing = i;
    int X, Y, W, H;
    item_rect(i, X, Y, W, H);
    if (mode == Icons) edit->resize(X, Y + 56, W, 22);
    else if (mode == List) edit->resize(X + 20, Y, std::max(160, W - 20), H);
    else edit->resize(ax() + 26, Y, std::max(140, colw[0] - 30), H);
    const std::string& name = items[i].name;
    edit->value(name.c_str());
    size_t dot = name.find_last_of('.');
    int stop = (!items[i].dir && dot != std::string::npos && dot > 0) ? (int)dot : (int)name.size();
    edit->show();
    edit->take_focus();
    ex::select_text(edit, 0, stop);
    redraw();
  }

  void finish_rename(bool commit) {
    if (editing < 0) return;
    int i = editing;
    editing = -1;
    std::string v = edit->value();
    edit->hide();
    if (Fl::focus() == edit || !Fl::focus()) Fl::focus(this);
    redraw();
    if (commit && on_rename && i < n() && v != items[i].name) on_rename(i, v);
  }

  static void edited(Fl_Widget*, void* p) { static_cast<FileView*>(p)->finish_rename(true); }

  // ---- dibujo
  void draw_header() {
    int hx = x() + 1, hy = y() + 1, hw = w() - 2;
    ex::vgrad(hx, hy, hw, HEAD, ex::th(0xffffff, 0x23272d), ex::th(0xf2f5f9, 0x1f2328));
    ex::color(ex::th(0xd5dfe8, 0x343b46));
    fl_xyline(hx, hy + HEAD - 1, hx + hw - 1);
    fl_font(FL_HELVETICA, ex::UI);
    int cx = hx + 1;
    for (int c = 0; c < 4; c++) {
      int cw = colw[c];
      if (c == hover_col) ex::vgrad(cx, hy, cw - 1, HEAD - 1, ex::th(0xf3f9ff, 0x2c3a4d), ex::th(0xdcebfc, 0x263347));
      if (c == sort_col) {
        double mx = cx + cw / 2.0;
        ex::color(0x7c93b0);
        if (desc) ex::poly({{mx - 4, hy + 2}, {mx + 4, hy + 2}, {mx, hy + 6}}, 0x7c93b0, 0x7c93b0);
        else ex::poly({{mx, hy + 2}, {mx + 4, hy + 6}, {mx - 4, hy + 6}}, 0x7c93b0, 0x7c93b0);
      }
      ex::color(ex::th(0x4c607a, 0xaab6c6));
      std::string t = ex::ellipsis(heads[c], cw - 14);
      int tw = (int)fl_width(t.c_str());
      fl_draw(t.c_str(), c == 3 ? cx + cw - 8 - tw : cx + 8, hy + HEAD / 2 + fl_height() / 2 - fl_descent());
      ex::color(ex::th(0xe0e6ee, 0x343b46));
      fl_yxline(cx + cw - 1, hy + 3, hy + HEAD - 4);
      cx += cw;
    }
  }

  void draw_item(int i, int X, int Y, int W, int H, bool focused) {
    const ex::Entry& e = items[i];
    bool dim = e.hidden || faded.count(e.path) > 0;
    unsigned ink = dim ? ex::th(0x8a96a6, 0x6c7787) : ex::th(0x1b1b1b, 0xe6e9ee), grey = dim ? ex::th(0xa8b2bf, 0x5d6775) : ex::th(0x6d6d6d, 0x9aa4b2);
    fl_font(FL_HELVETICA, ex::UI);
    if (mode == Icons && e.drive) {
      ex::draw_selection(X, Y, W, H, sel[i], i == hover, focused);
      ex::draw_icon(e.icon, X + 6, Y + 8, 48, dim);
      int tx = X + 62, tw = W - 70;
      ex::color(ink);
      fl_draw(ex::ellipsis(e.name, tw).c_str(), tx, Y + 18);
      if (e.size > 0) {
        double used = 1.0 - (double)e.free / (double)e.size;
        unsigned c1 = used > 0.9 ? 0xe0584f : 0x2f8ae0, c2 = used > 0.9 ? 0xb3261e : 0x1f63b5;
        ex::vgrad(tx, Y + 25, tw, 12, ex::th(0xf3f3f3, 0x2c3138), ex::th(0xdedede, 0x262a30));
        ex::vgrad(tx + 1, Y + 26, std::max(0, (int)std::lround((tw - 2) * used)), 10, c1, c2);
        ex::color(ex::th(0xa6a6a6, 0x4a515c));
        fl_rect(tx, Y + 25, tw, 12);
        fl_font(FL_HELVETICA, ex::UI - 2);
        ex::color(grey);
        fl_draw(ex::ellipsis(ex::fmt(tx::FREE_OF, {ex::size_text(e.free), ex::size_text(e.size)}), tw).c_str(), tx, Y + 52);
      } else {
        ex::color(grey);
        fl_draw(e.type.c_str(), tx, Y + 38);
      }
      return;
    }
    if (mode == Icons) {
      ex::draw_selection(X, Y, W, H, sel[i], i == hover, focused);
      ex::draw_icon(e.icon, X + (W - 48) / 2.0, Y + 5, 48, dim, e.ext);
      fl_font(FL_HELVETICA, ex::UI);
      auto lines = ex::wrap2(e.name, W - 8);
      ex::color(ink);
      int ly = Y + 56 + fl_height() - fl_descent();
      for (auto& l : lines) {
        int lw = (int)fl_width(l.c_str());
        fl_draw(l.c_str(), X + (W - lw) / 2, ly);
        ly += fl_height();
      }
      return;
    }
    if (mode == List) {
      int tw = std::min(W, 26 + (int)fl_width(e.name.c_str()));
      ex::draw_selection(X, Y, tw, H, sel[i], i == hover, focused);
      ex::draw_icon(e.icon, X + 3, Y + 3, 16, dim);
      ex::color(ink);
      fl_draw(ex::ellipsis(e.name, W - 26).c_str(), X + 23, Y + H / 2 + fl_height() / 2 - fl_descent());
      return;
    }
    ex::draw_selection(X, Y, W, H, sel[i], i == hover, focused);
    int base = Y + H / 2 + fl_height() / 2 - fl_descent();
    int cx = ax() + 2;
    ex::draw_icon(e.icon, cx + 4, Y + 3, 16, dim);
    ex::color(ink);
    fl_draw(ex::ellipsis(e.name, colw[0] - 32).c_str(), cx + 26, base);
    cx += colw[0];
    ex::color(grey);
    std::string c1 = e.drive ? (e.size ? ex::size_text(e.free) : "") : ex::date_text(e.mtime);
    fl_draw(ex::ellipsis(c1, colw[1] - 14).c_str(), cx + 7, base);
    cx += colw[1];
    fl_draw(ex::ellipsis(e.type, colw[2] - 14).c_str(), cx + 7, base);
    cx += colw[2];
    if (!e.dir || e.drive) {
      std::string s = e.drive ? (e.size ? ex::size_text(e.size) : "") : ex::size_text(e.size);
      s = ex::ellipsis(s, colw[3] - 14);
      fl_draw(s.c_str(), cx + colw[3] - 8 - (int)fl_width(s.c_str()), base);
    }
  }

  bool band = false;
  int bx0 = 0, by0 = 0, bx1 = 0, by1 = 0;
  std::vector<char> band_base;

  void draw() override {
    update_bars();
    fl_push_clip(x(), y(), w(), h());
    ex::color(ex::th(0xffffff, 0x1b1e23));
    fl_rectf(x(), y(), w(), h());
    if (mode == Details) draw_header();
    fl_push_clip(ax(), ay(), aw(), ah());
    bool focused = Fl::focus() == this || Fl::focus() == edit;
    int first = 0, last = n() - 1;
    if (mode == Icons) {
      first = std::max(0, (scroll / cell_h()) * cols());
      last = std::min(n() - 1, ((scroll + ah()) / cell_h() + 1) * cols());
    } else if (mode == Details) {
      first = std::max(0, scroll / row_h() - 1);
      last = std::min(n() - 1, (scroll + ah()) / row_h() + 1);
    } else {
      first = std::max(0, (scroll / list_cw) * rows());
      last = std::min(n() - 1, ((scroll + aw()) / list_cw + 1) * rows());
    }
    for (int i = first; i <= last; i++) {
      int X, Y, W, H;
      item_rect(i, X, Y, W, H);
      draw_item(i, X, Y, W, H, focused);
    }
    if (items.empty() && !empty_text.empty()) {
      fl_font(FL_HELVETICA_ITALIC, ex::UI);
      ex::color(ex::th(0x6d7b8d, 0x8792a2));
      fl_draw(empty_text.c_str(), ax() + 20, ay() + 14, aw() - 40, 40, FL_ALIGN_TOP | FL_ALIGN_CENTER | FL_ALIGN_WRAP);
    }
    if (band) {
      int X0 = std::min(bx0, bx1), Y0 = std::min(by0, by1);
      int sx = mode == List ? scroll : 0, sy = mode == List ? 0 : scroll;
      ex::color(0x3399ff);
      fl_rect(ax() + X0 - sx, ay() + Y0 - sy, std::abs(bx1 - bx0) + 1, std::abs(by1 - by0) + 1);
    }
    fl_pop_clip();
    draw_children();
    fl_pop_clip();
  }

  // ---- eventos
  int pending_only = -1, drag_col = -1, drag_x0 = 0, drag_w0 = 0, pressed_col = -1;
  std::string typed;
  double typed_at = 0;

  int head_col(int mx, bool& edge) const {
    int cx = x() + 2;
    edge = false;
    for (int c = 0; c < 4; c++) {
      if (std::abs(mx - (cx + colw[c])) <= 4) { edge = true; return c; }
      if (mx >= cx && mx < cx + colw[c]) return c;
      cx += colw[c];
    }
    return -1;
  }

  void update_band() {
    for (int i = 0; i < n(); i++) {
      int X, Y, W, H;
      item_rect(i, X, Y, W, H);
      int sx = mode == List ? scroll : 0, sy = mode == List ? 0 : scroll;
      int cx = X - ax() + sx, cy = Y - ay() + sy;
      bool in = cx < std::max(bx0, bx1) && cx + W > std::min(bx0, bx1) && cy < std::max(by0, by1) && cy + H > std::min(by0, by1);
      sel[i] = (i < (int)band_base.size() && band_base[i]) || in;
    }
  }

  int handle(int e) override {
    int mx = Fl::event_x(), my = Fl::event_y();
    switch (e) {
    case FL_PUSH: {
      if ((vbar->visible() && Fl::event_inside(vbar)) || (hbar->visible() && Fl::event_inside(hbar)) || (editing >= 0 && Fl::event_inside(edit)))
        return Fl_Group::handle(e);
      finish_rename(true);
      Fl::focus(this);
      if (mode == Details && my < ay()) {
        bool edge;
        int c = head_col(mx, edge);
        if (c >= 0 && edge) { drag_col = c; drag_x0 = mx; drag_w0 = colw[c]; }
        else pressed_col = c;
        return 1;
      }
      int i = hit(mx, my);
      bool cmd = Fl::event_state(FL_COMMAND) != 0, shift = Fl::event_state(FL_SHIFT) != 0;
      if (Fl::event_button() == FL_RIGHT_MOUSE) {
        if (i >= 0 && !sel[i]) select_only(i);
        if (i < 0) select_only(-1);
        if (i >= 0) focus = anchor = i;
        changed();
        if (on_menu) on_menu(i, mx, my);
        return 1;
      }
      if (i < 0) {
        if (!cmd && !shift) select_only(-1);
        band = true;
        int sx = mode == List ? scroll : 0, sy = mode == List ? 0 : scroll;
        bx0 = bx1 = mx - ax() + sx;
        by0 = by1 = my - ay() + sy;
        band_base = sel;
        changed();
        return 1;
      }
      if (Fl::event_clicks() && !cmd && !shift) {
        select_only(i);
        focus = anchor = i;
        changed();
        if (on_open) on_open(i);
        return 1;
      }
      if (cmd) { sel[i] = !sel[i]; anchor = i; }
      else if (shift && anchor >= 0) select_range(anchor, i);
      else {
        if (!sel[i]) select_only(i);
        else pending_only = i;
        anchor = i;
      }
      focus = i;
      changed();
      return 1;
    }
    case FL_DRAG: {
      if (drag_col >= 0) {
        colw[drag_col] = std::max(50, drag_w0 + mx - drag_x0);
        redraw();
        return 1;
      }
      if (band) {
        int sx = mode == List ? scroll : 0, sy = mode == List ? 0 : scroll;
        if (mode != List && my < ay()) scroll_by(-row_h());
        if (mode != List && my > ay() + ah()) scroll_by(row_h());
        if (mode == List && mx < ax()) scroll_by(-list_cw / 4);
        if (mode == List && mx > ax() + aw()) scroll_by(list_cw / 4);
        sx = mode == List ? scroll : 0;
        sy = mode == List ? 0 : scroll;
        bx1 = std::max(0, std::min(mx - ax(), aw())) + sx;
        by1 = std::max(0, std::min(my - ay(), ah())) + sy;
        update_band();
        changed();
      }
      pending_only = -1;
      return 1;
    }
    case FL_RELEASE: {
      if (drag_col >= 0) { drag_col = -1; return 1; }
      if (pressed_col >= 0) {
        bool edge;
        int c = head_col(mx, edge);
        if (c == pressed_col && my < ay() && on_sort) on_sort(c);
        pressed_col = -1;
        return 1;
      }
      if (band) { band = false; redraw(); return 1; }
      if (pending_only >= 0) {
        select_only(pending_only);
        pending_only = -1;
        changed();
      }
      return 1;
    }
    case FL_MOVE: {
      int h0 = hover, c0 = hover_col;
      hover = hit(mx, my);
      hover_col = -1;
      bool edge = false;
      if (mode == Details && my < ay() && my >= y()) hover_col = head_col(mx, edge);
      if (window()) window()->cursor(edge ? FL_CURSOR_WE : FL_CURSOR_DEFAULT);
      if (h0 != hover || c0 != hover_col) redraw();
      return 1;
    }
    case FL_ENTER: return 1;
    case FL_LEAVE:
      hover = hover_col = -1;
      if (window()) window()->cursor(FL_CURSOR_DEFAULT);
      redraw();
      return 1;
    case FL_FOCUS: case FL_UNFOCUS: redraw(); return 1;
    case FL_MOUSEWHEEL: {
      if (!Fl::event_inside(this)) return 0;
      int d = mode == List ? (Fl::event_dx() ? Fl::event_dx() : Fl::event_dy()) : Fl::event_dy();
      scroll_by(d * (mode == Icons ? 34 : mode == List ? 40 : row_h() * 2));
      finish_rename(true);
      return 1;
    }
    case FL_KEYBOARD: return key();
    }
    return Fl_Group::handle(e);
  }

  int key() {
    int k = Fl::event_key();
    bool shift = Fl::event_state(FL_SHIFT) != 0, cmd = Fl::event_state(FL_COMMAND) != 0, alt = Fl::event_state(FL_ALT) != 0;
    if (on_key && on_key(k)) return 1;
    if (n() == 0) return 0;
    int to = focus < 0 ? 0 : focus;
    int page = mode == Icons ? std::max(1, ah() / cell_h()) * cols() : std::max(1, ah() / row_h());
    switch (k) {
    case FL_Left:
      if (alt || cmd) return 0;
      if (mode == Details) return 0;
      to -= mode == Icons ? 1 : rows();
      break;
    case FL_Right:
      if (alt || cmd) return 0;
      if (mode == Details) return 0;
      to += mode == Icons ? 1 : rows();
      break;
    case FL_Up: if (alt || cmd) return 0; to -= mode == Icons ? cols() : 1; break;
    case FL_Down: if (alt || cmd) return 0; to += mode == Icons ? cols() : 1; break;
    case FL_Home: to = 0; break;
    case FL_End: to = n() - 1; break;
    case FL_Page_Up: to -= page; break;
    case FL_Page_Down: to += page; break;
    case FL_Enter: case FL_KP_Enter:
      if (focus >= 0 && on_open) { on_open(focus); return 1; }
      return 0;
    default: {
      const char* t = Fl::event_text();
      if (cmd || alt || Fl::event_length() == 0 || (unsigned char)t[0] < 32 || t[0] == 127) return 0;
      // Escribir las primeras letras lleva al primer nombre que empieza así.
      double now = (double)clock() / CLOCKS_PER_SEC;
      if (now - typed_at > 1.0) typed.clear();
      typed_at = now;
      typed += ex::fold(t);
      int start = typed.size() == ex::fold(t).size() ? focus + 1 : std::max(0, focus);
      for (int j = 0; j < n(); j++) {
        int i = (start + j) % n();
        if (items[i].key.compare(0, typed.size(), typed) == 0) {
          select_only(i);
          focus = anchor = i;
          ensure_visible(i);
          changed();
          break;
        }
      }
      return 1;
    }
    }
    to = std::max(0, std::min(n() - 1, to));
    if (shift) {
      if (anchor < 0) anchor = focus < 0 ? 0 : focus;
      select_range(anchor, to);
    } else if (!cmd) {
      select_only(to);
      anchor = to;
    }
    focus = to;
    ensure_visible(to);
    changed();
    return 1;
  }
};

// El árbol de carpetas (se carga al abrir cada rama).
class NavTree : public Fl_Group {
public:
  struct Node {
    std::string label, path;
    int icon = ex::IcFolder, depth = 0, parent = -1;
    bool open = false, loaded = false, can_open = true, gap = false;
    std::vector<int> kids;
  };
  std::vector<Node> nodes;
  std::vector<int> tops, rows, row_y, roots, quick;
  int selected = -1, hover = -1, scroll = 0;
  bool hidden = false;
  Fl_Scrollbar* vbar;
  std::function<void(int)> on_pick;
  std::function<void(int, int, int)> on_menu;
  static const int RH = 22;

  NavTree(int X, int Y, int W, int H) : Fl_Group(X, Y, W, H) {
    box(FL_NO_BOX);
    vbar = new Fl_Scrollbar(X + W - SB, Y, SB, H);
    vbar->type(FL_VERTICAL);
    vbar->callback([](Fl_Widget* w, void* p) {
      auto* t = static_cast<NavTree*>(p);
      t->scroll = static_cast<Fl_Scrollbar*>(w)->value();
      t->redraw();
    }, this);
    end();
    resizable(nullptr);
  }

  int add(int parent, const std::string& label, const std::string& path, int icon, bool can_open = true) {
    Node n;
    n.label = label;
    n.path = path;
    n.icon = icon;
    n.parent = parent;
    n.can_open = can_open;
    n.depth = parent < 0 ? 0 : nodes[parent].depth + 1;
    nodes.push_back(n);
    int id = (int)nodes.size() - 1;
    if (parent < 0) tops.push_back(id);
    else nodes[parent].kids.push_back(id);
    return id;
  }

  void clear_all() {
    nodes.clear();
    tops.clear();
    roots.clear();
    quick.clear();
    selected = hover = -1;
  }

  void load(int id) {
    Node& n = nodes[id];
    if (n.loaded || n.path.empty() || ex::is_virtual(n.path)) return;
    n.loaded = true;
    auto subs = ex::subfolders(n.path, hidden);
    for (auto& s : subs) add(id, s.first, s.second, ex::IcFolder);
    if (nodes[id].kids.empty()) nodes[id].can_open = false;
  }

  // Vuelve a leer las ramas abiertas (al crear, borrar o renombrar).
  void refresh(const std::string& path) {
    for (int id = 0; id < (int)nodes.size(); id++) {
      if (!nodes[id].loaded || !ex::same(nodes[id].path, path)) continue;
      std::set<std::string> open;
      for (int k : nodes[id].kids) if (nodes[k].open) open.insert(nodes[k].path);
      nodes[id].kids.clear();
      nodes[id].loaded = false;
      nodes[id].can_open = true;
      load(id);
      for (int k : nodes[id].kids) if (open.count(nodes[k].path)) { load(k); nodes[k].open = true; }
    }
    rebuild();
  }

  void toggle(int id) {
    if (id < 0) return;
    load(id);
    if (!nodes[id].can_open) return;
    nodes[id].open = !nodes[id].open;
    rebuild();
  }

  void walk(int id) {
    rows.push_back(id);
    if (nodes[id].open) for (int k : nodes[id].kids) walk(k);
  }

  void rebuild() {
    rows.clear();
    row_y.clear();
    for (int t : tops) walk(t);
    int y0 = 6;
    for (int id : rows) {
      if (nodes[id].gap && id != rows.front()) y0 += 10;
      row_y.push_back(y0);
      y0 += RH;
    }
    total = y0 + 6;
    update_bar();
    redraw();
  }

  int total = 0;
  void update_bar() {
    if (total > h()) vbar->show(); else vbar->hide();
    scroll = std::max(0, std::min(scroll, total - h()));
    vbar->resize(x() + w() - SB, y(), SB, h());
    vbar->value(scroll, h(), 0, std::max(total, h()));
    vbar->linesize(RH);
  }

  void resize(int X, int Y, int W, int H) override {
    Fl_Group::resize(X, Y, W, H);
    update_bar();
  }

  int row_at(int my) const {
    for (size_t i = 0; i < rows.size(); i++) {
      int ry = y() + row_y[i] - scroll;
      if (my >= ry && my < ry + RH) return (int)i;
    }
    return -1;
  }

  void show_row(int id) {
    for (size_t i = 0; i < rows.size(); i++) {
      if (rows[i] != id) continue;
      if (row_y[i] < scroll) scroll = row_y[i] - 4;
      else if (row_y[i] + RH > scroll + h()) scroll = row_y[i] + RH - h() + 4;
      update_bar();
      redraw();
    }
  }

  // Marca (y despliega hasta) la carpeta de [path].
  void reveal(const std::string& path) {
    for (int q : quick) {
      if (ex::same(nodes[q].path, path)) { selected = q; rebuild(); show_row(q); return; }
    }
    int best = -1;
    size_t len = 0;
    for (int r : roots) {
      if (ex::inside(path, nodes[r].path) && nodes[r].path.size() >= len) { best = r; len = nodes[r].path.size(); }
      if (nodes[r].path == path) { best = r; break; }
    }
    if (best < 0) {
      selected = -1;
      for (int id = 0; id < (int)nodes.size(); id++) if (nodes[id].path == path) selected = id;
      rebuild();
      if (selected >= 0) show_row(selected);
      return;
    }
    int cur = best;
    while (!ex::same(nodes[cur].path, path)) {
      load(cur);
      int next = -1;
      for (int k : nodes[cur].kids) if (ex::inside(path, nodes[k].path)) { next = k; break; }
      if (next < 0) break;
      nodes[cur].open = true;
      cur = next;
    }
    for (int p = nodes[cur].parent; p >= 0; p = nodes[p].parent) nodes[p].open = true;
    selected = cur;
    rebuild();
    show_row(cur);
  }

  void draw() override {
    fl_push_clip(x(), y(), w(), h());
    ex::color(ex::th(0xffffff, 0x1b1e23));
    fl_rectf(x(), y(), w(), h());
    int cw = w() - (vbar->visible() ? SB : 0);
    bool focused = Fl::focus() == this;
    for (size_t i = 0; i < rows.size(); i++) {
      int ry = y() + row_y[i] - scroll;
      if (ry + RH < y() || ry > y() + h()) continue;
      const Node& n = nodes[rows[i]];
      int ix = x() + 6 + n.depth * 16;
      if (rows[i] == selected || rows[i] == hover)
        ex::draw_selection(x() + 2, ry, cw - 4, RH, rows[i] == selected, rows[i] == hover, focused);
      if (n.can_open && !n.path.empty()) {
        double cx = ix + 5, cy = ry + RH / 2.0;
        unsigned dk = ex::th(0x3c3c3c, 0xc9ced6);
        if (n.open) ex::poly({{cx + 3.5, cy - 3}, {cx + 3.5, cy + 3.5}, {cx - 3, cy + 3.5}}, dk, dk, (int)dk);
        else {
          ex::color(rows[i] == hover ? 0x4fb3e6 : ex::th(0x8c8c8c, 0x8a93a0));
          fl_begin_loop();
          fl_vertex(cx - 2, cy - 4.5);
          fl_vertex(cx + 2.5, cy);
          fl_vertex(cx - 2, cy + 4.5);
          fl_end_loop();
        }
      }
      ex::draw_icon(n.icon, ix + 14, ry + 3, 16);
      fl_font(FL_HELVETICA, ex::UI);
      ex::color(ex::th(0x1b1b1b, 0xe6e9ee));
      fl_draw(ex::ellipsis(n.label, cw - (ix - x()) - 40).c_str(), ix + 35, ry + RH / 2 + fl_height() / 2 - fl_descent());
    }
    draw_children();
    fl_pop_clip();
  }

  int handle(int e) override {
    switch (e) {
    case FL_PUSH: {
      if (vbar->visible() && Fl::event_inside(vbar)) return Fl_Group::handle(e);
      Fl::focus(this);
      int r = row_at(Fl::event_y());
      if (r < 0) return 1;
      int id = rows[r];
      int ix = x() + 6 + nodes[id].depth * 16;
      if (Fl::event_button() == FL_RIGHT_MOUSE) {
        if (on_menu) on_menu(id, Fl::event_x(), Fl::event_y());
        return 1;
      }
      if (Fl::event_x() < ix + 13 || nodes[id].path.empty() || Fl::event_clicks()) {
        toggle(id);
        if (nodes[id].path.empty() || Fl::event_x() < ix + 13) return 1;
      }
      selected = id;
      redraw();
      if (on_pick) on_pick(id);
      return 1;
    }
    case FL_MOVE: {
      int r = row_at(Fl::event_y());
      int h0 = hover;
      hover = r < 0 ? -1 : rows[r];
      if (h0 != hover) redraw();
      return 1;
    }
    case FL_ENTER: return 1;
    case FL_LEAVE: hover = -1; redraw(); return 1;
    case FL_FOCUS: case FL_UNFOCUS: redraw(); return 1;
    case FL_MOUSEWHEEL:
      if (!Fl::event_inside(this)) return 0;
      scroll += Fl::event_dy() * RH;
      update_bar();
      redraw();
      return 1;
    case FL_KEYBOARD: {
      int k = Fl::event_key();
      int at = -1;
      for (size_t i = 0; i < rows.size(); i++) if (rows[i] == selected) at = (int)i;
      if (k == FL_Up || k == FL_Down) {
        int to = at < 0 ? 0 : std::max(0, std::min((int)rows.size() - 1, at + (k == FL_Up ? -1 : 1)));
        if (rows.empty()) return 1;
        selected = rows[to];
        show_row(selected);
        if (on_pick && !nodes[selected].path.empty()) on_pick(selected);
        return 1;
      }
      if (selected < 0) return 0;
      if (k == FL_Right) {
        if (!nodes[selected].open) toggle(selected);
        else if (!nodes[selected].kids.empty()) { selected = nodes[selected].kids[0]; show_row(selected); if (on_pick) on_pick(selected); }
        return 1;
      }
      if (k == FL_Left) {
        if (nodes[selected].open) toggle(selected);
        else if (nodes[selected].parent >= 0) { selected = nodes[selected].parent; show_row(selected); if (on_pick && !nodes[selected].path.empty()) on_pick(selected); }
        return 1;
      }
      if (k == FL_Enter || k == FL_KP_Enter) { if (on_pick) on_pick(selected); return 1; }
      return 0;
    }
    }
    return Fl_Group::handle(e);
  }
};

// Las pestañas: una por carpeta abierta, con su cierre y «+».
class TabStrip : public Fl_Widget {
public:
  std::vector<std::string> labels;
  int active = 0, hover = -1;
  bool hover_close = false, hover_plus = false;
  std::function<void(int)> on_pick, on_close;
  std::function<void()> on_new;
  std::function<void(int, int, int)> on_menu;

  TabStrip(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void geometry(std::vector<int>& xs, std::vector<int>& ws) const {
    xs.clear();
    ws.clear();
    fl_font(FL_HELVETICA, ex::UI);
    int avail = w() - 16 - 30, sum = 0;
    for (auto& l : labels) {
      int tw = std::max(110, std::min(220, (int)fl_width(l.c_str()) + 58));
      ws.push_back(tw);
      sum += tw;
    }
    if (sum > avail && sum > 0) for (auto& v : ws) v = std::max(60, v * avail / sum);
    int cx = x() + 8;
    for (int v : ws) { xs.push_back(cx); cx += v - 1; }
  }

  void plus_rect(int& X, int& Y, int& W, int& H) const {
    std::vector<int> xs, ws;
    geometry(xs, ws);
    X = xs.empty() ? x() + 8 : xs.back() + ws.back() + 4;
    Y = y() + 4;
    W = 24;
    H = h() - 7;
  }

  void draw() override {
    ex::vgrad(x(), y(), w(), h(), ex::th(0xe4ecf7, 0x262b33), ex::th(0xd6e2f2, 0x20242a));
    int bottom = y() + h() - 1;
    ex::color(ex::th(0x9fb3cd, 0x3d4756));
    fl_xyline(x(), bottom, x() + w() - 1);
    std::vector<int> xs, ws;
    geometry(xs, ws);
    fl_push_clip(x(), y(), w(), h());
    for (int pass = 0; pass < 2; pass++) {
      for (size_t i = 0; i < labels.size(); i++) {
        bool on = (int)i == active;
        if ((pass == 1) != on) continue;
        int tx = xs[i], ty = y() + (on ? 3 : 5), tw = ws[i], th = h() - (on ? 3 : 5) + 6;
        unsigned paper = ex::th(0xffffff, 0x1b1e23);
        if (on) ex::rgrad(tx, ty, tw, th, 4, paper, paper);
        else ex::rgrad(tx, ty, tw, th, 4, (int)i == hover ? ex::th(0xf8fbfe, 0x353c46) : ex::th(0xeef3fa, 0x2c323b),
                       (int)i == hover ? ex::th(0xe7eff9, 0x2f353e) : ex::th(0xdbe5f2, 0x272c34));
        ex::rline(tx, ty, tw, th, 4, on ? ex::th(0x8ea6c6, 0x3d4756) : ex::th(0xa9bad1, 0x3a424e));
        if (on) { ex::color(paper); fl_xyline(tx + 1, bottom, tx + tw - 2); }
        ex::draw_icon(ex::IcFolder, tx + 8, ty + (h() - ty + y() - 16) / 2.0 - 1, 16);
        fl_font(on ? FL_HELVETICA_BOLD : FL_HELVETICA, ex::UI);
        ex::color(on ? ex::th(0x1b1b1b, 0xe6e9ee) : ex::th(0x3d4a5c, 0xaab4c2));
        int room = tw - 34 - (labels.size() > 1 ? 18 : 0);
        fl_draw(ex::ellipsis(labels[i], room).c_str(), tx + 29, y() + h() / 2 + fl_height() / 2 - fl_descent() + (on ? 0 : 1));
        if (labels.size() > 1) {
          int cx = tx + tw - 21, cy = y() + h() / 2 - 8 + (on ? 0 : 1);
          if ((int)i == hover && hover_close) ex::rgrad(cx, cy, 16, 16, 3, 0xf2b7b2, 0xe0857c);
          ex::draw_icon(ex::GClose, cx, cy, 16);
        }
      }
    }
    int px, py, pw, ph;
    plus_rect(px, py, pw, ph);
    if (hover_plus) box_hover_draw(px, py, pw, ph);
    ex::draw_icon(ex::GPlus, px + 4, py + (ph - 16) / 2.0, 16);
    fl_pop_clip();
  }

  static void box_hover_draw(int X, int Y, int W, int H) { ex::box_hover(X, Y, W, H, 0); }

  int at(int mx, int my, bool& close) const {
    std::vector<int> xs, ws;
    geometry(xs, ws);
    close = false;
    for (int i = (int)labels.size() - 1; i >= 0; i--) {
      if (mx >= xs[i] && mx < xs[i] + ws[i] && my >= y() + 3) {
        close = labels.size() > 1 && mx >= xs[i] + ws[i] - 22 && mx < xs[i] + ws[i] - 4;
        return i;
      }
    }
    return -1;
  }

  int handle(int e) override {
    int mx = Fl::event_x(), my = Fl::event_y();
    switch (e) {
    case FL_PUSH: {
      bool close;
      int i = at(mx, my, close);
      int px, py, pw, ph;
      plus_rect(px, py, pw, ph);
      if (i < 0) {
        if ((mx >= px && mx < px + pw) || Fl::event_clicks()) { if (on_new) on_new(); }
        return 1;
      }
      if (Fl::event_button() == FL_RIGHT_MOUSE) { if (on_menu) on_menu(i, mx, my); return 1; }
      if (close || Fl::event_button() == FL_MIDDLE_MOUSE) { if (on_close) on_close(i); return 1; }
      if (on_pick) on_pick(i);
      return 1;
    }
    case FL_MOVE: case FL_ENTER: {
      bool close;
      int h0 = hover;
      bool c0 = hover_close, p0 = hover_plus;
      hover = at(mx, my, close);
      hover_close = close;
      int px, py, pw, ph;
      plus_rect(px, py, pw, ph);
      hover_plus = hover < 0 && mx >= px && mx < px + pw && my >= py && my < py + ph;
      if (h0 != hover || c0 != hover_close || p0 != hover_plus) redraw();
      return 1;
    }
    case FL_LEAVE: hover = -1; hover_close = hover_plus = false; redraw(); return 1;
    }
    return 0;
  }
};

// La barra de marcadores: un botón por marcador con «Mostrar en la barra».
class MarkBar : public Fl_Widget {
public:
  std::vector<std::pair<std::string, int>> chips;   // texto, marcador
  std::string hint;
  int hover = -1;
  std::function<void(int)> on_pick;
  std::function<void(int, int, int)> on_menu;

  MarkBar(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int chip_w(size_t i) const {
    fl_font(FL_HELVETICA, ex::UI);
    return std::min(180, (int)std::ceil(fl_width(chips[i].first.c_str())) + 2) + 30;
  }

  void draw() override {
    ex::box_bar(x(), y(), w(), h(), 0);
    fl_push_clip(x(), y(), w(), h());
    int cx = x() + 6;
    if (chips.empty()) {
      fl_font(FL_HELVETICA_ITALIC, ex::UI - 1);
      ex::color(ex::th(0x7a889a, 0x8792a2));
      ex::draw_icon(ex::GStar, cx, y() + (h() - 16) / 2.0, 16, true);
      fl_draw(ex::ellipsis(hint, w() - 40).c_str(), cx + 22, y() + h() / 2 + fl_height() / 2 - fl_descent());
    }
    for (size_t i = 0; i < chips.size(); i++) {
      int cw = chip_w(i);
      if ((int)i == hover) ex::box_hover(cx, y() + 2, cw, h() - 5, 0);
      ex::draw_icon(ex::GStar, cx + 5, y() + (h() - 16) / 2.0 - 1, 16);
      fl_font(FL_HELVETICA, ex::UI);
      ex::color(ex::th(0x1e395b, 0x9cc3f0));
      fl_draw(ex::ellipsis(chips[i].first, cw - 28).c_str(), cx + 24, y() + h() / 2 + fl_height() / 2 - fl_descent() - 1);
      cx += cw + 2;
    }
    fl_pop_clip();
  }

  int at(int mx) const {
    int cx = x() + 6;
    for (size_t i = 0; i < chips.size(); i++) {
      int cw = chip_w(i);
      if (mx >= cx && mx < cx + cw) return (int)i;
      cx += cw + 2;
    }
    return -1;
  }

  int handle(int e) override {
    switch (e) {
    case FL_PUSH: {
      int i = at(Fl::event_x());
      if (i < 0) return 1;
      if (Fl::event_button() == FL_RIGHT_MOUSE) { if (on_menu) on_menu(chips[i].second, Fl::event_x(), Fl::event_y()); }
      else if (on_pick) on_pick(chips[i].second);
      return 1;
    }
    case FL_MOVE: case FL_ENTER: {
      int h0 = hover;
      hover = at(Fl::event_x());
      if (h0 != hover) redraw();
      return 1;
    }
    case FL_LEAVE: hover = -1; redraw(); return 1;
    }
    return 0;
  }
};

// La barra de direcciones con «migas»: cada carpeta es un botón y su flecha
// abre la lista de subcarpetas. Un clic en el hueco la vuelve editable.
class Crumbs : public Fl_Widget {
public:
  struct Seg { std::string label, path; int x = 0, w = 0; };
  std::vector<Seg> segs;
  int first = 0, hover = -1, icon = ex::IcFolder;
  bool hover_arrow = false, hover_more = false, hidden_files = false;
  std::function<void(const std::string&)> on_go;
  std::function<void()> on_edit;

  Crumbs(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void set(const std::string& path) {
    segs.clear();
    // Lo que está en la carpeta personal empieza en ella (como en Aero).
    std::vector<std::string> chain;
    const std::string home = ex::home_dir();
    bool in_home = false;
    for (std::string p = path; !p.empty(); p = ex::parent_of(p)) {
      chain.push_back(p);
      if (p == ex::COMPUTER) break;
      if (ex::same(p, home)) { in_home = true; break; }
    }
    for (auto it = chain.rbegin(); it != chain.rend(); ++it) segs.push_back({ex::display_name(*it), *it});
    icon = path == ex::COMPUTER ? ex::IcComputer : in_home ? ex::IcHome : ex::IcFolder;
    hover = -1;
    redraw();
  }

  static const int ARROW = 15;
  void geometry() {
    fl_font(FL_HELVETICA, ex::UI);
    int room = w() - 30 - 22;
    int used = 0;
    first = (int)segs.size();
    for (int i = (int)segs.size() - 1; i >= 0; i--) {
      int sw = (int)fl_width(segs[i].label.c_str()) + 12 + ARROW;
      if (used + sw > room && i < (int)segs.size() - 1) break;
      segs[i].w = sw;
      used += sw;
      first = i;
    }
    int cx = x() + 26 + (first > 0 ? 20 : 0);
    for (int i = first; i < (int)segs.size(); i++) { segs[i].x = cx; cx += segs[i].w; }
  }

  void draw() override {
    geometry();
    ex::box_field(x(), y(), w(), h(), 0);
    ex::draw_icon(icon, x() + 5, y() + (h() - 16) / 2.0, 16);
    fl_push_clip(x() + 1, y() + 1, w() - 2, h() - 2);
    int ty = y() + h() / 2 + fl_height() / 2 - fl_descent();
    if (first > 0) {
      if (hover_more) ex::box_hover(x() + 24, y() + 1, 18, h() - 2, 0);
      fl_font(FL_HELVETICA_BOLD, ex::UI);
      ex::color(ex::th(0x3d4a5c, 0xaab4c2));
      fl_draw("\xc2\xab", x() + 29, ty);
    }
    fl_font(FL_HELVETICA, ex::UI);
    for (int i = first; i < (int)segs.size(); i++) {
      const Seg& s = segs[i];
      if (i == hover) {
        ex::box_hover(s.x, y() + 1, s.w - ARROW, h() - 2, 0);
        ex::box_hover(s.x + s.w - ARROW - 1, y() + 1, ARROW + 1, h() - 2, 0);
        if (hover_arrow) ex::box_down(s.x + s.w - ARROW - 1, y() + 1, ARROW + 1, h() - 2, 0);
      }
      ex::color(ex::th(0x1b1b1b, 0xe6e9ee));
      fl_draw(s.label.c_str(), s.x + 6, ty);
      double ax = s.x + s.w - ARROW / 2.0 - 1, ay = y() + h() / 2.0;
      unsigned ac = ex::th(0x4a4a4a, 0xaab4c2);
      ex::poly({{ax - 2, ay - 4}, {ax + 2.5, ay}, {ax - 2, ay + 4}}, ac, ac);
    }
    fl_pop_clip();
  }

  int at(int mx, bool& arrow) const {
    arrow = false;
    for (int i = first; i < (int)segs.size(); i++) {
      if (mx >= segs[i].x && mx < segs[i].x + segs[i].w) {
        arrow = mx >= segs[i].x + segs[i].w - ARROW - 1;
        return i;
      }
    }
    return -1;
  }

  void popup(const std::vector<std::pair<std::string, std::string>>& list, int px, int py, const std::string& current) {
    if (list.empty()) return;
    std::vector<Fl_Menu_Item> items;
    std::vector<std::string> keep;
    keep.reserve(list.size());
    size_t limit = std::min<size_t>(list.size(), 400);
    for (size_t i = 0; i < limit; i++) keep.push_back(list[i].first);
    for (size_t i = 0; i < limit; i++) {
      Fl_Menu_Item m = {keep[i].c_str(), 0, nullptr, (void*)(intptr_t)i, 0, 0, 0, 0, 0};
      if (ex::same(list[i].second, current)) m.labelfont_ = FL_HELVETICA_BOLD;
      m.labelsize_ = ex::UI;
      items.push_back(m);
    }
    items.push_back(Fl_Menu_Item{nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0});
    const Fl_Menu_Item* r = items[0].popup(px, py);
    if (r && on_go) on_go(list[(size_t)(intptr_t)r->user_data()].second);
  }

  int handle(int e) override {
    int mx = Fl::event_x();
    switch (e) {
    case FL_PUSH: {
      geometry();
      if (first > 0 && mx >= x() + 24 && mx < x() + 44) {
        std::vector<std::pair<std::string, std::string>> up;
        for (int i = first - 1; i >= 0; i--) up.push_back({segs[i].label, segs[i].path});
        popup(up, x() + 24, y() + h(), "");
        return 1;
      }
      bool arrow;
      int i = at(mx, arrow);
      if (i < 0) { if (on_edit) on_edit(); return 1; }
      if (arrow) {
        std::vector<std::pair<std::string, std::string>> list;
        if (segs[i].path == ex::COMPUTER) for (auto& d : ex::drives()) list.push_back({d.name, d.path});
        else list = ex::subfolders(segs[i].path, hidden_files, 400);
        hover_arrow = true;
        redraw();
        popup(list, segs[i].x + segs[i].w - ARROW, y() + h(), i + 1 < (int)segs.size() ? segs[i + 1].path : "");
        hover_arrow = false;
        redraw();
        return 1;
      }
      if (on_go) on_go(segs[i].path);
      return 1;
    }
    case FL_MOVE: case FL_ENTER: {
      bool arrow;
      int h0 = hover;
      bool a0 = hover_arrow, m0 = hover_more;
      hover = at(mx, arrow);
      hover_arrow = false;
      hover_more = first > 0 && mx >= x() + 24 && mx < x() + 44;
      if (h0 != hover || a0 != hover_arrow || m0 != hover_more) redraw();
      return 1;
    }
    case FL_LEAVE: hover = -1; hover_more = false; redraw(); return 1;
    }
    return 0;
  }
};

// Lo que se ve en la caja de búsqueda vacía: «Buscar en …» y la lupa.
class SearchFace : public Fl_Widget {
public:
  std::string text;
  std::function<void()> on_click;
  SearchFace(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}
  void draw() override {
    ex::box_field(x(), y(), w(), h(), 0);
    fl_font(FL_HELVETICA_ITALIC, ex::UI);
    ex::color(ex::th(0x7d8a99, 0x7f8a98));
    fl_push_clip(x() + 2, y() + 1, w() - 26, h() - 2);
    fl_draw(ex::ellipsis(text, w() - 34).c_str(), x() + 7, y() + h() / 2 + fl_height() / 2 - fl_descent());
    fl_pop_clip();
    ex::draw_icon(ex::GSearch, x() + w() - 21, y() + (h() - 16) / 2.0, 16);
  }
  int handle(int e) override {
    if (e == FL_PUSH) { if (on_click) on_click(); return 1; }
    return e == FL_ENTER || e == FL_LEAVE ? 1 : 0;
  }
};

// Un icono grande (el del panel de detalles y los diálogos).
class BigIcon : public Fl_Widget {
public:
  int icon = ex::IcFolder;
  std::string ext;
  BigIcon(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}
  void draw() override { ex::draw_icon(icon, x(), y(), std::min(w(), h()), false, ext); }
};

// El separador entre el árbol y la vista, para cambiar su ancho.
class Splitter : public Fl_Widget {
public:
  std::function<void(int)> on_drag;
  int start = 0;
  Splitter(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}
  void draw() override {
    ex::color(ex::th(0xe9eef6, 0x1f2329));
    fl_rectf(x(), y(), w(), h());
    ex::color(ex::th(0xd2dceb, 0x2f3540));
    fl_yxline(x() + w() / 2, y(), y() + h() - 1);
  }
  int handle(int e) override {
    switch (e) {
    case FL_ENTER: if (window()) window()->cursor(FL_CURSOR_WE); return 1;
    case FL_LEAVE: if (window()) window()->cursor(FL_CURSOR_DEFAULT); return 1;
    case FL_PUSH: start = Fl::event_x(); return 1;
    case FL_DRAG: if (on_drag) on_drag(Fl::event_x() - start); start = Fl::event_x(); return 1;
    case FL_RELEASE: return 1;
    }
    return 0;
  }
};

// ============================================================= diálogos
namespace dlg {

Fl_Button* button(int x, int y, int w, int h, const char* text) {
  auto* b = new Fl_Button(x, y, w, h);
  b->copy_label(text);
  b->box(ex::bx(ex::BX_BTN));
  b->down_box(ex::bx(ex::BX_BTN_DOWN));
  b->labelsize(ex::UI);
  return b;
}

// Los colores de los textos: 0 es el normal; los demás, su versión del tema.
unsigned ink(unsigned c) {
  switch (c) {
  case 0x003399: return ex::th(0x003399, 0x8fb8ff);
  case 0x3b4656: return ex::th(0x3b4656, 0xb3bdca);
  case 0x5a6779: return ex::th(0x5a6779, 0x9aa4b2);
  default: return ex::th(0x1b1b1b, 0xe6e9ee);
  }
}

Fl_Box* text(int x, int y, int w, int h, const std::string& s, Fl_Font font = FL_HELVETICA, int size = ex::UI, unsigned color = 0) {
  auto* b = new Fl_Box(x, y, w, h);
  b->copy_label(s.c_str());
  b->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP);
  b->labelfont(font);
  b->labelsize(size);
  b->labelcolor(ex::rgb(ink(color)));
  return b;
}

int text_h(const std::string& s, int w, Fl_Font font = FL_HELVETICA, int size = ex::UI) {
  fl_font(font, size);
  int ww = w, hh = 0;
  fl_measure(s.c_str(), ww, hh, 0);
  return hh;
}

void center(Fl_Window* d) {
  Fl_Window* p = Fl::first_window();
  while (p && p->modal()) p = Fl::next_window(p);
  if (p && p != d) d->position(p->x() + (p->w() - d->w()) / 2, p->y() + std::max(40, (p->h() - d->h()) / 3));
}

void run(Fl_Window* d) {
  center(d);
  d->set_modal();
  d->show();
  while (d->shown()) Fl::wait();
}

struct Pick { int value = -1; Fl_Window* win = nullptr; };

// Una pregunta al estilo de los cuadros de diálogo de Aero: la instrucción en
// azul, el texto, (si hay) la ficha del archivo y los botones abajo. Da el
// número del botón pulsado (-1: se cerró).
int ask(const std::string& main, const std::string& detail, const std::vector<std::string>& buttons, int icon,
        const ex::Entry* item = nullptr, const char* check = nullptr, bool* checked = nullptr, int def = 0) {
  const int W = 460, pad = 18, left = 74;
  int tw = W - left - pad;
  int mh = text_h(main, tw, FL_HELVETICA, ex::UI + 3), dh = detail.empty() ? 0 : text_h(detail, tw);
  int y = pad + mh + (dh ? 10 + dh : 0) + 12;
  int item_y = y;
  if (item) y += 64;
  int check_y = y;
  if (check) y += 28;
  int H = y + 50;
  Pick r;
  auto* d = new Fl_Double_Window(W, H, tx::APP);
  r.win = d;
  d->color(ex::rgb(ex::th(0xffffff, 0x23272e)));
  auto* ic = new BigIcon(pad, pad, 40, 40);
  ic->icon = icon;
  text(left, pad, tw, mh, main, FL_HELVETICA, ex::UI + 3, 0x003399);
  if (dh) text(left, pad + mh + 10, tw, dh, detail);
  if (item) {
    auto* big = new BigIcon(left, item_y + 4, 48, 48);
    big->icon = item->icon;
    big->ext = item->ext;
    text(left + 60, item_y + 4, tw - 60, 18, item->name, FL_HELVETICA_BOLD);
    text(left + 60, item_y + 22, tw - 60, 18, item->type, FL_HELVETICA, ex::UI, 0x5a6779);
    std::string more = (item->dir ? "" : ex::size_text(item->size) + "  \xc2\xb7  ") + ex::date_text(item->mtime);
    text(left + 60, item_y + 40, tw - 60, 18, more, FL_HELVETICA, ex::UI, 0x5a6779)->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_CLIP);
  }
  Fl_Check_Button* cb = nullptr;
  if (check) {
    cb = new Fl_Check_Button(left, check_y, tw, 22);
    cb->copy_label(check);
    cb->labelsize(ex::UI);
    cb->value(checked && *checked);
  }
  auto* foot = new Fl_Box(0, H - 46, W, 46);
  foot->box(ex::bx(ex::BX_FOOTER));
  int bx = W - pad;
  for (int i = (int)buttons.size() - 1; i >= 0; i--) {
    fl_font(FL_HELVETICA, ex::UI);
    int bw = std::max(86, (int)fl_width(buttons[i].c_str()) + 28);
    bx -= bw;
    auto* b = button(bx, H - 36, bw, 26, buttons[i].c_str());
    b->user_data((void*)(intptr_t)i);
    b->callback([](Fl_Widget* w, void* p) {
      auto* pk = static_cast<Pick*>(w->window()->user_data());
      pk->value = (int)(intptr_t)p;
      pk->win->hide();
    }, (void*)(intptr_t)i);
    if (i == def) { b->shortcut(FL_Enter); b->take_focus(); }
    bx -= 8;
  }
  d->user_data(&r);
  d->end();
  run(d);
  if (cb && checked) *checked = cb->value() != 0;
  Fl::delete_widget(d);
  return r.value;
}

void error(const std::string& main, const std::string& detail = "") {
  ask(main, detail, {tx::OK}, ex::IcWarn);
}

// Pedir un texto.
bool input(const std::string& question, std::string& value) {
  const int W = 420;
  auto* d = new Fl_Double_Window(W, 130, tx::APP);
  d->color(ex::rgb(ex::th(0xffffff, 0x23272e)));
  text(18, 16, W - 36, 20, question);
  auto* in = new Fl_Input(18, 42, W - 36, 26);
  in->box(ex::bx(ex::BX_FIELD));
  in->textsize(ex::UI);
  in->value(value.c_str());
  auto* foot = new Fl_Box(0, 84, W, 46);
  foot->box(ex::bx(ex::BX_FOOTER));
  static int result;
  result = 0;
  auto* ok = button(W - 18 - 2 * 86 - 8, 94, 86, 26, tx::OK);
  auto* cancel = button(W - 18 - 86, 94, 86, 26, tx::CANCEL);
  ok->shortcut(FL_Enter);
  ok->callback([](Fl_Widget* w, void*) { result = 1; w->window()->hide(); });
  cancel->callback([](Fl_Widget* w, void*) { w->window()->hide(); });
  d->end();
  in->take_focus();
  run(d);
  value = in->value();
  Fl::delete_widget(d);
  return result == 1;
}

}  // namespace dlg

// La ventana de Propiedades (no es modal: puede haber varias abiertas).
class PropsWin : public Fl_Double_Window {
public:
  std::shared_ptr<ex::SizeJob> job;
  Fl_Box* size_v = nullptr;
  Fl_Box* contains_v = nullptr;
  bool counting_dirs = false;

  PropsWin(const std::vector<ex::Entry>& items, const std::string& location) : Fl_Double_Window(400, 470) {
    color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    bool one = items.size() == 1;
    const ex::Entry& e = items.front();
    copy_label(ex::fmt(tx::PROPS_TITLE, {one ? e.name : ex::fmt(tx::N_ITEMS, {std::to_string(items.size())})}).c_str());
    auto* icon = new BigIcon(18, 16, 40, 40);
    icon->icon = one ? e.icon : ex::IcMany;
    icon->ext = one ? e.ext : "";
    auto* name = new Fl_Output(78, 24, 300, 24);
    name->box(ex::bx(ex::BX_FIELD));
    name->textsize(ex::UI);
    name->value(one ? e.name.c_str() : ex::fmt(tx::N_ITEMS, {std::to_string(items.size())}).c_str());
    int y = 70;
    auto line = [&]() {
      auto* b = new Fl_Box(18, y, 364, 1);
      b->box(FL_FLAT_BOX);
      b->color(ex::rgb(ex::th(0xdfe3e8, 0x3a404a)));
      y += 10;
    };
    auto row = [&](const char* label, const std::string& value) {
      dlg::text(18, y, 110, 20, label, FL_HELVETICA, ex::UI, 0x3b4656);
      int hh = std::max(20, dlg::text_h(value, 250));
      Fl_Box* v = dlg::text(130, y, 250, hh, value);
      y += hh + 6;
      return v;
    };
    line();
    std::string type = e.type;
    for (auto& x : items) if (x.type != e.type) type = tx::P_VARIOUS;
    row(tx::P_TYPE, type);
    row(tx::P_LOCATION, location);
    bool any_dir = false;
    for (auto& x : items) if (x.dir && !x.drive) any_dir = true;
    if (one && e.drive) {
      row(tx::P_TOTAL, e.size ? ex::size_text(e.size) : "");
      row(tx::P_FREE, e.size ? ex::size_text(e.free) : "");
    } else {
      size_v = row(tx::P_SIZE, tx::P_COUNTING);
      if (any_dir) contains_v = row(tx::P_CONTAINS, tx::P_COUNTING);
    }
    if (one && e.link) {
      std::error_code ec;
      row(tx::P_TARGET, ex::U(fs::read_symlink(ex::P(e.path), ec)));
    }
    line();
    if (one) {
      ex::Meta m = ex::meta(e.path);
      if (m.ctime) row(tx::P_CREATED, ex::date_text(m.ctime));
      row(tx::P_MODIFIED, ex::date_text(m.mtime));
      if (m.atime) row(tx::P_ACCESSED, ex::date_text(m.atime));
      line();
      dlg::text(18, y + 2, 110, 20, tx::P_ATTRS, FL_HELVETICA, ex::UI, 0x3b4656);
      auto* ro = new Fl_Check_Button(130, y, 120, 22, tx::P_READONLY);
      ro->labelsize(ex::UI);
      ro->value(!e.drive && ex::read_only(e.path));
      ro->deactivate();
      auto* hd = new Fl_Check_Button(250, y, 120, 22, tx::P_HIDDEN);
      hd->labelsize(ex::UI);
      hd->value(e.hidden);
      hd->deactivate();
      y += 30;
    }
    auto* foot = new Fl_Box(0, y + 6, 400, 46);
    foot->box(ex::bx(ex::BX_FOOTER));
    auto* ok = dlg::button(400 - 18 - 90, y + 16, 90, 26, tx::OK);
    ok->shortcut(FL_Enter);
    ok->callback([](Fl_Widget* w, void*) { w->window()->do_callback(); });
    end();
    size(400, y + 52);
    callback([](Fl_Widget* w, void*) {
      auto* p = static_cast<PropsWin*>(w);
      if (p->job) p->job->cancel = true;
      Fl::remove_timeout(poll, p);
      p->hide();
      Fl::delete_widget(p);
    });
    if (size_v) {
      job = std::make_shared<ex::SizeJob>();
      std::vector<std::string> paths;
      for (auto& x : items) paths.push_back(x.path);
      std::thread(ex::count_size, job, paths).detach();
      Fl::add_timeout(0.1, poll, this);
    }
    dlg::center(this);
  }

  static void poll(void* p) {
    auto* w = static_cast<PropsWin*>(p);
    auto& j = *w->job;
    uintmax_t b = j.bytes;
    std::string s = ex::fmt(tx::P_SIZE_FMT, {ex::size_text(b), ex::group(b)});
    if (!j.done) s += "  \xe2\x80\xa6";
    w->size_v->copy_label(s.c_str());
    if (w->contains_v) w->contains_v->copy_label(ex::fmt(tx::P_CONTAINS_FMT, {ex::group((uintmax_t)j.files), ex::group((uintmax_t)j.dirs)}).c_str());
    w->redraw();
    if (!j.done) Fl::repeat_timeout(0.15, poll, p);
  }
};

// El progreso de copiar, mover o eliminar (aparece si tarda).
class JobWin : public Fl_Double_Window {
public:
  std::shared_ptr<ex::Job> job;
  std::function<void(ex::Job&)> on_done;
  Fl_Box* what;
  Fl_Box* file;
  Fl_Progress* bar;
  double started;

  JobWin(std::shared_ptr<ex::Job> j, const std::string& title) : Fl_Double_Window(440, 150), job(j) {
    copy_label(tx::APP);
    color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    what = dlg::text(18, 14, 404, 40, title, FL_HELVETICA, ex::UI + 2, 0x003399);
    file = dlg::text(18, 56, 404, 20, "", FL_HELVETICA, ex::UI, 0x5a6779);
    bar = new Fl_Progress(18, 78, 404, 16);
    bar->selection_color(ex::rgb(0x2fb24c));
    bar->color(ex::rgb(ex::th(0xe6e6e6, 0x30353c)));
    bar->box(FL_BORDER_BOX);
    auto* foot = new Fl_Box(0, 106, 440, 44);
    foot->box(ex::bx(ex::BX_FOOTER));
    auto* cancel = dlg::button(440 - 18 - 90, 115, 90, 26, tx::CANCEL);
    cancel->callback([](Fl_Widget* w, void*) { static_cast<JobWin*>(w->window())->job->cancel = true; });
    end();
    callback([](Fl_Widget* w, void*) { static_cast<JobWin*>(w)->job->cancel = true; });
    started = (double)clock() / CLOCKS_PER_SEC;
    Fl::add_timeout(0.1, poll, this);
  }

  static void poll(void* p) {
    auto* w = static_cast<JobWin*>(p);
    auto& j = *w->job;
    if (j.done) {
      w->hide();
      if (w->on_done) w->on_done(j);
      Fl::delete_widget(w);
      return;
    }
    if (!w->shown()) {
      dlg::center(w);
      w->show();
    }
    long total = j.total, count = j.count;
    std::string cur;
    {
      std::lock_guard<std::mutex> lock(j.mu);
      cur = j.current;
    }
    w->file->copy_label(total ? (ex::fmt(tx::JOB_FILES, {ex::group((uintmax_t)count), ex::group((uintmax_t)total)}) + "   " + cur).c_str() : tx::JOB_COUNTING);
    w->bar->maximum(total ? (float)total : 1.f);
    w->bar->value(total ? (float)std::min(count, total) : 0.f);
    Fl::repeat_timeout(0.1, poll, p);
  }
};

// ========================================================== la ventana
enum Act {
  ActOpen, ActOpenTab, ActNewTab, ActCloseTab, ActNewFolder, ActRename, ActDelete, ActDeleteNow, ActProps, ActQuit,
  ActCut, ActCopy, ActPaste, ActCopyPath, ActSelectAll, ActInvert,
  ActViewIcons, ActViewList, ActViewDetails, ActSortName, ActSortDate, ActSortType, ActSortSize, ActSortDesc,
  ActShowTree, ActShowMarks, ActShowDetails, ActShowHidden, ActRefresh,
  ActBack, ActForward, ActUp, ActHome, ActDesktop, ActComputer, ActGoto, ActFind,
  ActAddMark, ActOrganize, ActTerminal, ActReveal, ActKeys, ActAbout,
  ActThemeLight, ActThemeDark, ActThemeSystem, ActNone
};

// Pruebas del código sin ventana: DMS_EXPLORER_SELFTEST=<carpeta vacía>.
int explorer_selftest(const std::string& dir) {
  int fails = 0;
  auto check = [&](bool ok, const std::string& what) {
    std::printf("%s %s\n", ok ? "ok" : "FAIL", what.c_str());
    if (!ok) fails++;
  };
  using namespace ex;
  check(natcmp("a2", "a10") < 0 && natcmp("a10", "a2") > 0 && natcmp("b", "a10") > 0, "natcmp");
  check(fold("Árbol Ñandú") == "arbol nandu", "fold");
  check(matches(fold("Informe.TXT"), "*.txt") && matches(fold("Informe"), "form") && !matches("x", "y"), "matches");
  check(size_text(512) == fmt(tx::BYTES, {"512"}), "size bytes");
  check(size_text((uintmax_t)BASE * BASE * 3 / 2).find("MB") != std::string::npos, "size MB");
  check(group(1234567) == std::string("1") + (tx::DECIMAL[0] == ',' ? "." : ",") + "234" + (tx::DECIMAL[0] == ',' ? "." : ",") + "567", "group");
  std::string t;
  check(classify("jpg", t) == IcImage && t == fmt(tx::TYPE_IMAGE, {"JPG"}), "classify jpg");
  check(classify("", t) == IcFile && t == tx::TYPE_NOEXT, "classify sin extensión");
  // Una carpeta de prueba.
  std::error_code ec;
  fs::create_directories(P(dir), ec);
  for (auto n : {"b.txt", "a10.txt", "a2.txt", ".oculto"}) write_file(join(dir, n), "hola");
  fs::create_directory(P(join(dir, "Carpeta")), ec);
  write_file(join(join(dir, "Carpeta"), "dentro.md"), "# dentro");
  std::vector<Entry> list;
  std::string err;
  check(list_dir(dir, false, list, err) && list.size() == 4, "list_dir sin ocultos");
  std::sort(list.begin(), list.end(), [](const Entry& a, const Entry& b) { return less_entry(a, b, 0, false); });
  check(list.size() == 4 && list[0].name == "Carpeta" && list[1].name == "a2.txt" && list[2].name == "a10.txt", "orden natural, carpetas primero");
  std::vector<Entry> all;
  check(list_dir(dir, true, all, err) && all.size() == 5, "list_dir con ocultos");
  check(unique_in(dir, "Carpeta", true) == "Carpeta (2)", "unique_in");
  check(copy_name(dir, "b.txt", false) == std::string("b") + tx::COPY_SUFFIX + ".txt", "copy_name");
  auto subs = subfolders(dir, false);
  check(subs.size() == 1 && subs[0].first == "Carpeta", "subfolders");
  // Copiar, mover y borrar con el mismo código de la aplicación.
  auto job = std::make_shared<Job>();
  job->kind = Job::Copy;
  job->items = {{join(dir, "Carpeta"), join(dir, "Copia")}, {join(dir, "b.txt"), join(dir, copy_name(dir, "b.txt", false))}};
  run_job(job);
  check(job->errors.empty() && exists(join(join(dir, "Copia"), "dentro.md")) && exists(join(dir, copy_name(dir, "b.txt", false) == "b.txt" ? "x" : std::string("b") + tx::COPY_SUFFIX + ".txt")), "copiar");
  job = std::make_shared<Job>();
  job->kind = Job::Move;
  job->items = {{join(dir, "Copia"), join(dir, "Movida")}};
  run_job(job);
  check(job->errors.empty() && !exists(join(dir, "Copia")) && exists(join(join(dir, "Movida"), "dentro.md")), "mover");
  check(inside(join(join(dir, "Carpeta"), "x"), join(dir, "Carpeta")) && !inside(join(dir, "Carpeta2"), join(dir, "Carpeta")), "inside");
  job = std::make_shared<Job>();
  job->kind = Job::Remove;
  job->items = {{join(dir, "Movida"), ""}};
  run_job(job);
  check(job->errors.empty() && !exists(join(dir, "Movida")), "eliminar definitivamente");
  // Marcadores: guardar y leer (con tabuladores y saltos en la descripción).
  std::string file = join(join(dir, "config"), "bookmarks.tsv");
  std::vector<std::string> folders = {"Trabajo"};
  std::vector<Mark> marks = {{"Casa", home_dir(), "línea 1\nlínea\t2", "", true}, {"Docs", dir, "", "Trabajo", false}};
  save_marks(file, folders, marks);
  std::vector<std::string> f2;
  std::vector<Mark> m2;
  check(load_marks(file, f2, m2) && f2 == folders && m2.size() == 2 && m2[0].desc == "línea 1\nlínea\t2" && m2[0].bar && m2[1].folder == "Trabajo", "marcadores");
  // El tamaño (Propiedades) en otro hilo.
  auto sj = std::make_shared<SizeJob>();
  std::thread th(count_size, sj, std::vector<std::string>{dir});
  th.join();
  check(sj->done && sj->files >= 5 && sj->dirs >= 2 && sj->bytes > 0, "tamaño en segundo plano");
  check(parent_of(dir) == U(P(dir).parent_path()) && parent_of(U(P(dir).root_path())) == COMPUTER, "parent_of");
  check(!drives().empty(), "discos");
  std::printf(fails ? "selftest FAIL %d\n" : "selftest ok\n", fails);
  return fails ? 1 : 0;
}

class Form1 : public FormDesign {
public:
  struct Tab {
    std::string path;
    std::vector<std::string> back, fwd, sel;
    int scroll = 0;
  };
  std::vector<Tab> tabs;
  int cur = 0;
  NavTree* tree = nullptr;
  FileView* view = nullptr;
  TabStrip* tabstrip = nullptr;
  MarkBar* markbar = nullptr;
  Crumbs* crumbs = nullptr;
  SearchFace* face = nullptr;
  BigIcon* detail_icon = nullptr;
  Splitter* split = nullptr;
  std::vector<ex::Mark> marks;
  std::vector<std::string> mark_folders;
  std::vector<std::string> clip;   // lo último que se copió o cortó aquí
  bool clip_cut = false;
  long clip_mark = -1;             // el portapapeles cuando se copió
  int theme = 2;                   // 0 claro, 1 oscuro, 2 el del sistema
  bool was_dark = false;
  bool show_hidden = false, show_tree = true, show_marks = true, show_details = true;
  int tree_w = 230, view_mode = FileView::Icons, sort_col = 0;
  bool sort_desc = false;
  std::vector<ex::Entry> listing;
  std::string list_error, filter;
  time_t watched = 0;
  uintmax_t free_space = 0;
  std::string cfg;
  std::vector<std::pair<Fl_Button*, int>> tools;   // botón, glifo
  Fl_Widget* hovered = nullptr;
  std::map<std::string, Act> actions;
  std::map<int, int> shortcuts;
  inline static Form1* self = nullptr;

  Form1() {
    if (const char* d = getenv("DMS_EXPLORER_SELFTEST")) std::exit(explorer_selftest(d));
    set_app_icon();
  }

  // ---- el logotipo: una carpeta abierta blanca sobre un cuadrado azul,
  // dibujado aquí y convertido en el icono de la ventana (y, en macOS, del
  // Dock cuando la app no va dentro de un paquete .app con el suyo).
  static void draw_logo(int s) {
    int m = s / 10, q = s - 2 * m;
    ex::rgrad(m, m, q, q, q * 22 / 100, 0x74b9f4, 0x1f5fc4);
    double k = s * 0.5 / 24, ox = s / 2.0 - 12 * k, oy = s / 2.0 - 12 * k;
    auto V = [&](double a, double b) { fl_vertex(ox + a * k, oy + b * k); };
    ex::color(0xffffff);
    ex::thick(std::max(1.0, s * 0.035));
    fl_begin_line();
    V(6, 14); V(7.5, 11.1); V(9.24, 10); V(20, 10); V(21.94, 12.5); V(20.4, 18.5); V(18.45, 20); V(4, 20); V(2, 18);
    V(2, 5); V(4, 3); V(7.9, 3); V(9.6, 3.9); V(10.4, 5.1); V(12.1, 6); V(18, 6); V(20, 8); V(20, 10);
    fl_end_line();
    ex::thin();
  }

  static Fl_RGB_Image* logo_image(int s) {
    // Dos veces, sobre negro y sobre blanco: la diferencia da la transparencia.
    unsigned char* px[2] = {nullptr, nullptr};
    for (int pass = 0; pass < 2; pass++) {
      auto* surf = new Fl_Image_Surface(s, s);
#if defined(FL_API_VERSION) && FL_API_VERSION >= 10400
      Fl_Surface_Device::push_current(surf);
#else
      surf->set_current();
#endif
      fl_color(pass ? FL_WHITE : FL_BLACK);
      fl_rectf(0, 0, s, s);
      draw_logo(s);
      Fl_RGB_Image* img = surf->image();
#if defined(FL_API_VERSION) && FL_API_VERSION >= 10400
      Fl_Surface_Device::pop_current();
#else
      Fl_Display_Device::display_device()->set_current();
#endif
      delete surf;
      if (!img || img->d() < 3) { delete img; return nullptr; }
      px[pass] = new unsigned char[s * s * 3];
      int ld = img->ld() ? img->ld() : img->w() * img->d();
      for (int y = 0; y < s && y < img->h(); y++)
        for (int x = 0; x < s && x < img->w(); x++)
          for (int c = 0; c < 3; c++) px[pass][(y * s + x) * 3 + c] = ((const unsigned char*)img->array)[y * ld + x * img->d() + c];
      delete img;
    }
    auto* rgba = new unsigned char[s * s * 4];
    for (int i = 0; i < s * s; i++) {
      int a = 255 - (px[1][i * 3] - px[0][i * 3]);
      a = std::max(0, std::min(255, a));
      rgba[i * 4 + 3] = (unsigned char)a;
      for (int c = 0; c < 3; c++) rgba[i * 4 + c] = (unsigned char)(a ? std::min(255, px[0][i * 3 + c] * 255 / a) : 0);
    }
    delete[] px[0];
    delete[] px[1];
    auto* out = new Fl_RGB_Image(rgba, s, s, 4);
    out->alloc_array = 1;
    return out;
  }

  void set_app_icon() {
    (void)Fl::w();   // abre la conexión con la pantalla
    Fl_RGB_Image* img = logo_image(128);
    if (!img) return;
#ifdef __APPLE__
    char exe[2048] = "";
    uint32_t n = sizeof exe;
    if (_NSGetExecutablePath(exe, &n) == 0 && std::strstr(exe, ".app/Contents/MacOS/")) { delete img; return; }
    // NSBitmapImageRep con los píxeles → NSImage → icono del Dock.
    id rep = ((id(*)(id, SEL, unsigned char**, long, long, long, long, BOOL, BOOL, id, long, long))objc_msgSend)(
        ex::msg(ex::cls("NSBitmapImageRep"), "alloc"), ex::msel("initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:"),
        nullptr, 128, 128, 8, 4, YES, NO, ex::nsstr("NSDeviceRGBColorSpace"), 128 * 4, 32);
    unsigned char* data = ((unsigned char* (*)(id, SEL))objc_msgSend)(rep, ex::msel("bitmapData"));
    if (data) {
      // Cocoa espera el color premultiplicado por la transparencia.
      const unsigned char* src = (const unsigned char*)img->array;
      for (int i = 0; i < 128 * 128; i++) {
        int a = src[i * 4 + 3];
        for (int c = 0; c < 3; c++) data[i * 4 + c] = (unsigned char)(src[i * 4 + c] * a / 255);
        data[i * 4 + 3] = (unsigned char)a;
      }
      struct Size { double w, h; };
      id image = ((id(*)(id, SEL, Size))objc_msgSend)(ex::msg(ex::cls("NSImage"), "alloc"), ex::msel("initWithSize:"), Size{128, 128});
      ex::msg(image, "addRepresentation:", rep);
      ex::msg(ex::msg(ex::cls("NSApplication"), "sharedApplication"), "setApplicationIconImage:", image);
    }
    delete img;
#else
    Fl_Window::default_icon(img);
    icon(img);
    delete img;
#endif
  }

  // ------------------------------------------------------------ arranque
  void form_create() override {
    self = this;
    cfg = ex::config_dir();
#ifdef _WIN32
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
    Fl::set_font(FL_HELVETICA_ITALIC, "ISegoe UI");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
    Fl::set_font(FL_HELVETICA_ITALIC, "HelveticaNeue-Italic");
#endif
    FL_NORMAL_SIZE = ex::UI;
    Fl::background(240, 240, 240);
    Fl::set_color(FL_SELECTION_COLOR, 0x33, 0x99, 0xff);
    Fl_Tooltip::size(ex::UI - 1);
    Fl_Tooltip::color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    ex::setup_boxes();
    build();
    setup_menu();
    load_settings();
    apply_theme();
    load_marks();
    callback(window_cb, this);
    size_range(760, 480);
    Fl::event_dispatch(dispatch);
    std::string start = ex::home_dir();
    if (const char* s = getenv("DMS_EXPLORER_START")) start = s;
    tabs.push_back(Tab());
    tabs[0].path = start;
    load_listing();
    show_tab();
    view->take_focus();
    layout();
    if (getenv("DMS_EXPLORER_SMOKE")) Fl::add_timeout(0.3, smoke, this);
  }

  void form_close() override { save_settings(); }

  // Los componentes propios, dentro de los marcos del diseño.
  void build() {
    for (Fl_Group* g : {(Fl_Group*)NavBar, (Fl_Group*)CommandBar, (Fl_Group*)BookmarkBar, (Fl_Group*)TabBar, (Fl_Group*)TreeHost, (Fl_Group*)ViewHost, (Fl_Group*)DetailsPane})
      g->resizable(nullptr);
    NavBar->box(ex::bx(ex::BX_NAV));
    CommandBar->box(ex::bx(ex::BX_CMD));
    BookmarkBar->box(FL_NO_BOX);
    TabBar->box(FL_NO_BOX);
    TreeHost->box(FL_NO_BOX);
    ViewHost->box(FL_NO_BOX);
    DetailsPane->box(ex::bx(ex::BX_PANE));
    Status->box(ex::bx(ex::BX_STATUS));
    Status->labelsize(ex::UI - 1);
    Status->labelcolor(ex::rgb(0x2e3b4e));
    Menu1->box(ex::bx(ex::BX_MENU));
    Menu1->textsize(ex::UI);
    Menu1->selection_color(ex::rgb(0x3d7fd6));
    for (Fl_Input* in : {(Fl_Input*)Address, (Fl_Input*)Search}) {
      in->box(ex::bx(ex::BX_FIELD));
      in->textsize(ex::UI);
    }
    Search->when(FL_WHEN_CHANGED | FL_WHEN_ENTER_KEY_ALWAYS);
    Address->hide();
    Search->hide();

    tree = new NavTree(TreeHost->x(), TreeHost->y(), TreeHost->w(), TreeHost->h());
    TreeHost->add(tree);
    tree->on_pick = [this](int id) { tree_pick(id); };
    tree->on_menu = [this](int id, int mx, int my) { tree_menu(id, mx, my); };

    view = new FileView(ViewHost->x(), ViewHost->y(), ViewHost->w(), ViewHost->h());
    ViewHost->add(view);
    view->on_open = [this](int i) { open_item(view->items[i], false); };
    view->on_select = [this] { selection_changed(); };
    view->on_menu = [this](int i, int mx, int my) { view_menu(i, mx, my); };
    view->on_sort = [this](int c) {
      if (c == sort_col) sort_desc = !sort_desc;
      else { sort_col = c; sort_desc = false; }
      apply_view(view->selected_names(), 0);
      sync_menu();
    };
    view->on_rename = [this](int i, const std::string& name) { rename_item(i, name); };
    view->on_key = [this](int k) { return view_key(k); };

    tabstrip = new TabStrip(TabBar->x(), TabBar->y(), TabBar->w(), TabBar->h());
    TabBar->add(tabstrip);
    tabstrip->on_pick = [this](int i) { switch_tab(i); };
    tabstrip->on_close = [this](int i) { close_tab(i); };
    tabstrip->on_new = [this] { add_tab(tabs[cur].path); };
    tabstrip->on_menu = [this](int i, int mx, int my) { tab_menu(i, mx, my); };

    markbar = new MarkBar(BookmarkBar->x(), BookmarkBar->y(), BookmarkBar->w(), BookmarkBar->h());
    BookmarkBar->add(markbar);
    markbar->hint = ex::fmt(tx::MARKS_HINT, {fl_shortcut_label(FL_COMMAND + 'd')});
    markbar->on_pick = [this](int m) { open_mark(m, false); };
    markbar->on_menu = [this](int m, int mx, int my) { mark_menu(m, mx, my); };

    crumbs = new Crumbs(Address->x(), Address->y(), Address->w(), Address->h());
    NavBar->add(crumbs);
    crumbs->on_go = [this](const std::string& p) { go(p); };
    crumbs->on_edit = [this] { edit_address(); };
    face = new SearchFace(Search->x(), Search->y(), Search->w(), Search->h());
    NavBar->add(face);
    face->on_click = [this] {
      face->hide();
      Search->show();
      Search->take_focus();
    };

    detail_icon = new BigIcon(DetailsPane->x() + 14, DetailsPane->y() + 8, 48, 48);
    DetailsPane->add(detail_icon);
    DetailName->labelsize(ex::UI + 2);
    for (DmsLabel* l : {DetailName, DetailType, DetailInfo, DetailMore}) {
      l->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_CLIP);
      if (l != DetailName) l->labelsize(ex::UI);
    }

    split = new Splitter(0, 0, 5, 10);
    add(split);
    split->on_drag = [this](int dx) {
      tree_w = std::max(140, std::min(w() / 2, tree_w + dx));
      layout();
    };

    // Los botones de las barras: el texto del diseño pasa a ser su ayuda.
    auto setup = [this](DmsButton* b, int glyph, int size, bool keep_text) {
      b->copy_tooltip(b->text().c_str());
      if (!keep_text) b->text("");
      else b->text(" " + b->text());
      b->image(new ex::Glyph(glyph, size));
      b->deimage(new ex::Glyph(glyph, size, true));
      b->align(FL_ALIGN_CENTER | FL_ALIGN_INSIDE | FL_ALIGN_IMAGE_NEXT_TO_TEXT);
      b->labelsize(ex::UI);
      b->labelcolor(ex::rgb(0x1e395b));
      b->box(FL_NO_BOX);
      b->down_box(ex::bx(ex::BX_DOWN));
      b->visible_focus(0);
      tools.push_back({b, glyph});
    };
    setup(Back, ex::GBack, 18, false);
    setup(Forward, ex::GForward, 18, false);
    for (DmsButton* b : {Back, Forward}) {
      b->box(ex::bx(ex::BX_ORB));
      b->down_box(ex::bx(ex::BX_ORB_DOWN));
    }
    setup(Refresh, ex::GRefresh, 16, false);
    Refresh->box(ex::bx(ex::BX_FIELD));
    setup(Up, ex::GUp, 20, false);
    setup(Folders, ex::GFolders, 18, true);
    setup(NewFolder, ex::GNewFolder, 20, false);
    setup(Cut, ex::GCut, 20, false);
    setup(Copy, ex::GCopy, 20, false);
    setup(Paste, ex::GPaste, 20, false);
    setup(Delete, ex::GDelete, 18, false);
    setup(Properties, ex::GProps, 20, false);
    setup(Hidden, ex::GHidden, 20, false);
    setup(ViewIcons, ex::GIcons, 18, false);
    setup(ViewList, ex::GList, 18, false);
    setup(ViewDetails, ex::GDetails, 18, false);
  }

  // ---- el menú: rutas → acciones, atajos y casillas
  void setup_menu() {
    const std::pair<const char*, Act> table[] = {
      {tx::MP_OPEN, ActOpen}, {tx::MP_OPEN_TAB, ActOpenTab}, {tx::MP_NEW_TAB, ActNewTab}, {tx::MP_CLOSE_TAB, ActCloseTab},
      {tx::MP_NEW_FOLDER, ActNewFolder}, {tx::MP_RENAME, ActRename}, {tx::MP_DELETE, ActDelete}, {tx::MP_DELETE_NOW, ActDeleteNow},
      {tx::MP_PROPS, ActProps}, {tx::MP_QUIT, ActQuit}, {tx::MP_CUT, ActCut}, {tx::MP_COPY, ActCopy}, {tx::MP_PASTE, ActPaste},
      {tx::MP_COPY_PATH, ActCopyPath}, {tx::MP_SELECT_ALL, ActSelectAll}, {tx::MP_INVERT, ActInvert},
      {tx::MP_VIEW_ICONS, ActViewIcons}, {tx::MP_VIEW_LIST, ActViewList}, {tx::MP_VIEW_DETAILS, ActViewDetails},
      {tx::MP_SORT_NAME, ActSortName}, {tx::MP_SORT_DATE, ActSortDate}, {tx::MP_SORT_TYPE, ActSortType}, {tx::MP_SORT_SIZE, ActSortSize},
      {tx::MP_SORT_DESC, ActSortDesc}, {tx::MP_SHOW_TREE, ActShowTree}, {tx::MP_SHOW_MARKS, ActShowMarks},
      {tx::MP_SHOW_DETAILS, ActShowDetails}, {tx::MP_SHOW_HIDDEN, ActShowHidden}, {tx::MP_REFRESH, ActRefresh},
      {tx::MP_BACK, ActBack}, {tx::MP_FORWARD, ActForward}, {tx::MP_UP, ActUp}, {tx::MP_HOME, ActHome}, {tx::MP_DESKTOP, ActDesktop},
      {tx::MP_COMPUTER, ActComputer}, {tx::MP_GOTO, ActGoto}, {tx::MP_FIND, ActFind}, {tx::MP_ADD_MARK, ActAddMark},
      {tx::MP_ORGANIZE, ActOrganize}, {tx::MP_TERMINAL, ActTerminal}, {tx::MP_REVEAL, ActReveal}, {tx::MP_KEYS, ActKeys},
      {tx::MP_ABOUT, ActAbout}, {tx::MP_THEME_LIGHT, ActThemeLight}, {tx::MP_THEME_DARK, ActThemeDark},
      {tx::MP_THEME_SYSTEM, ActThemeSystem},
    };
    for (auto& t : table) actions[t.first] = t.second;
#ifdef __APPLE__
    const int del = FL_COMMAND + FL_BackSpace, del_now = FL_COMMAND + FL_ALT + FL_BackSpace, props = FL_COMMAND + 'i';
    const int back = FL_COMMAND + '[', fwd = FL_COMMAND + ']', up = FL_COMMAND + FL_Up, hidden = FL_COMMAND + FL_SHIFT + '.';
    const int path = FL_COMMAND + FL_ALT + 'c';
#else
    const int del = FL_Delete, del_now = FL_SHIFT + FL_Delete, props = FL_ALT + FL_Enter;
    const int back = FL_ALT + FL_Left, fwd = FL_ALT + FL_Right, up = FL_ALT + FL_Up, hidden = FL_COMMAND + 'h';
    const int path = FL_COMMAND + FL_SHIFT + 'c';
#endif
    const std::pair<const char*, int> keys[] = {
      {tx::MP_OPEN, FL_COMMAND + 'o'}, {tx::MP_NEW_TAB, FL_COMMAND + 't'}, {tx::MP_CLOSE_TAB, FL_COMMAND + 'w'},
      {tx::MP_NEW_FOLDER, FL_COMMAND + FL_SHIFT + 'n'}, {tx::MP_RENAME, FL_F + 2}, {tx::MP_DELETE, del}, {tx::MP_DELETE_NOW, del_now},
      {tx::MP_PROPS, props}, {tx::MP_CUT, FL_COMMAND + 'x'}, {tx::MP_COPY, FL_COMMAND + 'c'}, {tx::MP_PASTE, FL_COMMAND + 'v'},
      {tx::MP_COPY_PATH, path}, {tx::MP_SELECT_ALL, FL_COMMAND + 'a'}, {tx::MP_VIEW_ICONS, FL_COMMAND + '1'},
      {tx::MP_VIEW_LIST, FL_COMMAND + '2'}, {tx::MP_VIEW_DETAILS, FL_COMMAND + '3'}, {tx::MP_SHOW_MARKS, FL_COMMAND + FL_SHIFT + 'b'},
      {tx::MP_SHOW_HIDDEN, hidden}, {tx::MP_REFRESH, FL_F + 5}, {tx::MP_BACK, back}, {tx::MP_FORWARD, fwd}, {tx::MP_UP, up},
      {tx::MP_HOME, FL_COMMAND + FL_SHIFT + 'h'}, {tx::MP_DESKTOP, FL_COMMAND + FL_SHIFT + 'd'}, {tx::MP_COMPUTER, FL_COMMAND + FL_SHIFT + 'k'},
      {tx::MP_GOTO, FL_COMMAND + 'l'}, {tx::MP_FIND, FL_COMMAND + 'f'}, {tx::MP_ADD_MARK, FL_COMMAND + 'd'}, {tx::MP_KEYS, FL_F + 1},
    };
    for (auto& k : keys) {
      int i = Menu1->find_index(k.first);
      if (i >= 0) { Menu1->shortcut(i, k.second); shortcuts[actions[k.first]] = k.second; }
    }
    auto flag = [this](const char* p, int f) {
      int i = Menu1->find_index(p);
      if (i >= 0) Menu1->mode(i, Menu1->mode(i) | f);
    };
    for (auto p : {tx::MP_VIEW_ICONS, tx::MP_VIEW_LIST, tx::MP_VIEW_DETAILS, tx::MP_SORT_NAME, tx::MP_SORT_DATE, tx::MP_SORT_TYPE, tx::MP_SORT_SIZE,
                   tx::MP_THEME_LIGHT, tx::MP_THEME_DARK, tx::MP_THEME_SYSTEM})
      flag(p, FL_MENU_RADIO);
    for (auto p : {tx::MP_SORT_DESC, tx::MP_SHOW_TREE, tx::MP_SHOW_MARKS, tx::MP_SHOW_DETAILS, tx::MP_SHOW_HIDDEN}) flag(p, FL_MENU_TOGGLE);
  }

  void set_check(const char* p, bool on) {
    int i = Menu1->find_index(p);
    if (i < 0) return;
    int m = Menu1->mode(i);
    Menu1->mode(i, on ? m | FL_MENU_VALUE : m & ~FL_MENU_VALUE);
  }

  void set_active(const char* p, bool on) {
    int i = Menu1->find_index(p);
    if (i < 0) return;
    int m = Menu1->mode(i);
    Menu1->mode(i, on ? m & ~FL_MENU_INACTIVE : m | FL_MENU_INACTIVE);
  }

  void sync_menu() {
    set_check(tx::MP_VIEW_ICONS, view_mode == FileView::Icons);
    set_check(tx::MP_VIEW_LIST, view_mode == FileView::List);
    set_check(tx::MP_VIEW_DETAILS, view_mode == FileView::Details);
    set_check(tx::MP_SORT_NAME, sort_col == 0);
    set_check(tx::MP_SORT_DATE, sort_col == 1);
    set_check(tx::MP_SORT_TYPE, sort_col == 2);
    set_check(tx::MP_SORT_SIZE, sort_col == 3);
    set_check(tx::MP_SORT_DESC, sort_desc);
    set_check(tx::MP_SHOW_TREE, show_tree);
    set_check(tx::MP_SHOW_MARKS, show_marks);
    set_check(tx::MP_SHOW_DETAILS, show_details);
    set_check(tx::MP_SHOW_HIDDEN, show_hidden);
    set_check(tx::MP_THEME_LIGHT, theme == 0);
    set_check(tx::MP_THEME_DARK, theme == 1);
    set_check(tx::MP_THEME_SYSTEM, theme == 2);
    const Tab& t = tabs[cur];
    bool real = !ex::is_virtual(t.path) && list_error.empty();
    bool any = !view->selected().empty();
    bool editable = any && !ex::is_virtual(t.path);
    set_active(tx::MP_OPEN, any);
    set_active(tx::MP_OPEN_TAB, any);
    set_active(tx::MP_CLOSE_TAB, tabs.size() > 1);
    set_active(tx::MP_NEW_FOLDER, real);
    set_active(tx::MP_RENAME, editable && view->selected().size() == 1);
    set_active(tx::MP_DELETE, editable);
    set_active(tx::MP_DELETE_NOW, editable);
    set_active(tx::MP_CUT, editable);
    set_active(tx::MP_COPY, editable);
    bool can_paste = ex::clip_has() || !clip.empty();
    set_active(tx::MP_PASTE, real && can_paste);
    set_active(tx::MP_BACK, !t.back.empty());
    set_active(tx::MP_FORWARD, !t.fwd.empty());
    set_active(tx::MP_UP, !ex::parent_of(t.path).empty());
    set_active(tx::MP_TERMINAL, !ex::is_virtual(t.path));
    set_active(tx::MP_REVEAL, !ex::is_virtual(t.path));
    Back->enabled(!t.back.empty());
    Forward->enabled(!t.fwd.empty());
    Up->enabled(!ex::parent_of(t.path).empty());
    NewFolder->enabled(real);
    for (DmsButton* b : {Cut, Copy, Delete}) b->enabled(editable);
    Properties->enabled(any || real);
    Paste->enabled(real && can_paste);
    NavBar->redraw();
    CommandBar->redraw();
  }

  // ------------------------------------------------------------ tema
  void apply_theme() {
    bool d = theme == 1 || (theme == 2 && ex::system_dark());
    was_dark = d;
    ex::dark = d;
    if (d) {
      Fl::background(0x2a, 0x2e, 0x35);
      Fl::background2(0x1a, 0x1d, 0x22);
      Fl::foreground(0xe6, 0xe9, 0xee);
    } else {
      Fl::background(240, 240, 240);
      Fl::background2(255, 255, 255);
      Fl::foreground(0, 0, 0);
    }
    Fl_Tooltip::color(ex::rgb(ex::th(0xffffff, 0x30353d)));
    Fl_Tooltip::textcolor(ex::rgb(ex::th(0x1b1b1b, 0xe6e9ee)));
    color(ex::rgb(ex::th(0xe9eef6, 0x1f2329)));
    for (auto& t : tools) t.first->labelcolor(ex::rgb(ex::th(0x1e395b, 0xc9daf0)));
    DetailName->labelcolor(ex::rgb(ex::th(0x1e395b, 0x9cc3f0)));
    for (DmsLabel* l : {DetailType, DetailInfo, DetailMore}) l->labelcolor(ex::rgb(ex::th(0x5a6779, 0x9aa4b2)));
    Status->labelcolor(ex::rgb(ex::th(0x2e3b4e, 0xc3ccd8)));
    for (Fl_Input* in : {(Fl_Input*)Address, (Fl_Input*)Search, view->edit}) {
      in->textcolor(FL_FOREGROUND_COLOR);
      in->cursor_color(FL_FOREGROUND_COLOR);
      in->color(FL_BACKGROUND2_COLOR);
    }
    for (Fl_Scrollbar* b : {view->vbar, view->hbar, tree->vbar}) b->color(ex::rgb(ex::th(0xe8e8e8, 0x2a2e35)));
    Menu1->textcolor(FL_FOREGROUND_COLOR);
    Menu1->selection_color(ex::rgb(ex::th(0x3d7fd6, 0x3d6fb0)));
    ex::title_bar(this, d);
    for (Fl_Window* w = Fl::first_window(); w; w = Fl::next_window(w)) w->redraw();
    redraw();
  }

  // ------------------------------------------------------------ medidas
  void resize(int X, int Y, int W, int H) override {
    FormDesign::resize(X, Y, W, H);
    layout();
  }

  void layout() {
    if (!view) return;
    const int W = w(), H = h();
    int y = 0;
    Menu1->resize(0, 0, W, Menu1->h());
    y += Menu1->h();
    NavBar->resize(0, y, W, 40);
    Back->resize(8, y + 6, 28, 28);
    Forward->resize(38, y + 6, 28, 28);
    int sw = std::max(170, std::min(300, W / 4));
    Search->resize(W - 10 - sw, y + 8, sw, 24);
    face->resize(Search->x(), Search->y(), Search->w(), Search->h());
    Refresh->resize(Search->x() - 10 - 26, y + 8, 26, 24);
    Address->resize(76, y + 8, Refresh->x() - 76 + 1, 24);
    crumbs->resize(Address->x(), Address->y(), Address->w(), Address->h());
    y += 40;
    CommandBar->resize(0, y, W, 32);
    int cx = 6;
    auto place = [&](DmsButton* b, int bw, int gap = 2) {
      b->resize(cx, y + 3, bw, 26);
      cx += bw + gap;
    };
    place(Up, 32, 8);
    fl_font(FL_HELVETICA, ex::UI);
    place(Folders, (int)fl_width(Folders->text().c_str()) + 36, 12);
    place(NewFolder, 32, 10);
    place(Cut, 32);
    place(Copy, 32);
    place(Paste, 32, 10);
    place(Delete, 32);
    place(Properties, 32);
    cx = W - 6 - 3 * 30;
    place(ViewIcons, 30, 0);
    place(ViewList, 30, 0);
    place(ViewDetails, 30, 0);
    Hidden->resize(W - 6 - 3 * 30 - 12 - 32, y + 3, 32, 26);
    y += 32;
    if (show_marks) {
      BookmarkBar->show();
      BookmarkBar->resize(0, y, W, 26);
      markbar->resize(0, y, W, 26);
      y += 26;
    } else BookmarkBar->hide();
    TabBar->resize(0, y, W, 28);
    tabstrip->resize(0, y, W, 28);
    y += 28;
    const int status_h = 22, details_h = show_details ? 64 : 0;
    int bottom = H - status_h - details_h;
    Status->resize(0, H - status_h, W, status_h);
    if (show_details) {
      DetailsPane->show();
      DetailsPane->resize(0, bottom, W, details_h);
      detail_icon->resize(16, bottom + 8, 48, 48);
      int col = std::max(330, W / 2);
      DetailName->resize(76, bottom + 9, col - 90, 22);
      DetailType->resize(76, bottom + 33, col - 90, 20);
      DetailInfo->resize(col, bottom + 11, W - col - 16, 20);
      DetailMore->resize(col, bottom + 33, W - col - 16, 20);
    } else DetailsPane->hide();
    int mh = std::max(40, bottom - y);
    if (show_tree) {
      tree_w = std::max(140, std::min(std::max(140, W / 2), tree_w));
      TreeHost->show();
      split->show();
      TreeHost->resize(0, y, tree_w, mh);
      tree->resize(0, y, tree_w, mh);
      split->resize(tree_w, y, 5, mh);
      ViewHost->resize(tree_w + 5, y, W - tree_w - 5, mh);
    } else {
      TreeHost->hide();
      split->hide();
      ViewHost->resize(0, y, W, mh);
    }
    view->resize(ViewHost->x(), ViewHost->y(), ViewHost->w(), ViewHost->h());
    paint_tools();
    redraw();
  }

  // El aspecto de los botones: pulsado, encendido, bajo el ratón o plano.
  void paint_tools() {
    for (auto& t : tools) {
      Fl_Button* b = t.first;
      bool orb = b == Back || b == Forward;
      bool on = (b == ViewIcons && view_mode == FileView::Icons) || (b == ViewList && view_mode == FileView::List) ||
                (b == ViewDetails && view_mode == FileView::Details) || (b == Folders && show_tree) || (b == Hidden && show_hidden);
      Fl_Boxtype want = orb ? ex::bx(b == hovered && b->active() ? ex::BX_ORB_HOVER : ex::BX_ORB)
                      : b == Refresh ? ex::bx(b == hovered ? ex::BX_HOVER : ex::BX_FIELD)
                      : b == hovered && b->active() ? ex::bx(ex::BX_HOVER)
                      : on ? ex::bx(ex::BX_ON) : FL_NO_BOX;
      if (b->box() != want) {
        b->box(want);
        if (b->parent()) b->parent()->redraw();
      }
    }
  }

  // Cada evento pasa por aquí: el botón bajo el ratón, la búsqueda y la
  // dirección cuando pierden el foco, y terminar de cambiar un nombre.
  static int dispatch(int e, Fl_Window* w) {
    int r = Fl::handle_(e, w);
    if (self && self->view) self->after_event(e, w);
    return r;
  }

  void after_event(int e, Fl_Window* w) {
    if (w == this && (e == FL_MOVE || e == FL_ENTER || e == FL_LEAVE || e == FL_DRAG || e == FL_RELEASE || e == FL_PUSH)) {
      Fl_Widget* h = nullptr;
      if (e != FL_LEAVE) {
        for (auto& t : tools) if (t.first->visible_r() && Fl::event_inside(t.first)) h = t.first;
      }
      if (h != hovered || e == FL_RELEASE || e == FL_PUSH) {
        Fl_Widget* old = hovered;
        hovered = h;
        paint_tools();
        if (old && old->parent()) old->parent()->redraw();
        if (h && h->parent()) h->parent()->redraw();
      }
    }
    Fl_Widget* f = Fl::focus();
    if (view->editing >= 0 && f != view->edit && f != view) view->finish_rename(true);
    if (Address->visible() && f != Address && e != FL_SHORTCUT) end_address();
    if (Search->visible() && f != Search && filter.empty()) {
      Search->hide();
      face->show();
      NavBar->redraw();
    }
  }

  static void window_cb(Fl_Widget* w, void* p) {
    auto* f = static_cast<Form1*>(p);
    if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) { f->escape(); return; }
    f->form_close();
    w->hide();
  }

  void escape() {
    if (view->editing >= 0) { view->finish_rename(false); return; }
    if (Address->visible()) { end_address(); view->take_focus(); return; }
    if (!filter.empty() || Search->visible()) {
      Search->value("");
      Search_enter();
      Search->hide();
      face->show();
      view->take_focus();
      return;
    }
    if (!view->selected().empty()) { view->select_only(-1); view->changed(); }
  }

  // ------------------------------------------------------------ carpetas
  void build_tree() {
    tree->clear_all();
    tree->hidden = show_hidden;
    int q = tree->add(-1, tx::QUICK, "", ex::IcStar);
    tree->nodes[q].open = true;
    tree->nodes[q].loaded = true;
    const int icons[] = {ex::IcDesktop, ex::IcDownloads, ex::IcDocuments, ex::IcPictures, ex::IcMusic, ex::IcVideos};
    const char* names[] = {tx::DESKTOP, tx::DOWNLOADS, tx::DOCUMENTS, tx::PICTURES, tx::MUSIC, tx::VIDEOS};
    for (int i = 0; i < 6; i++) {
      std::string p = ex::user_dir(i);
      if (ex::meta(p).dir) tree->quick.push_back(tree->add(q, names[i], p, icons[i]));
    }
    std::string home = ex::home_dir();
    int h = tree->add(-1, ex::base_name(home).empty() ? home : ex::base_name(home), home, ex::IcHome);
    tree->nodes[h].gap = true;
    tree->roots.push_back(h);
    int c = tree->add(-1, tx::COMPUTER, ex::COMPUTER, ex::IcComputer);
    tree->nodes[c].gap = true;
    tree->nodes[c].open = true;
    tree->nodes[c].loaded = true;
    for (auto& d : ex::drives()) tree->roots.push_back(tree->add(c, d.name, d.path, ex::IcDrive));
#ifdef _WIN32
    int t = tree->add(-1, tx::TRASH, "::trash", ex::IcTrash, false);
#else
    int t = tree->add(-1, tx::TRASH, ex::trash_dir(), ex::IcTrash, false);
#endif
    tree->nodes[t].gap = true;
    tree->rebuild();
  }

  void tree_pick(int id) {
    const std::string& p = tree->nodes[id].path;
    if (p.empty()) return;
#ifdef _WIN32
    if (p == "::trash") {
      ShellExecuteW(nullptr, L"open", L"explorer.exe", L"shell:RecycleBinFolder", nullptr, SW_SHOWNORMAL);
      return;
    }
#endif
    go(p);
  }

  void tree_menu(int id, int mx, int my) {
    const std::string p = tree->nodes[id].path;
    if (p.empty() || p == "::trash") return;
    Fl_Menu_Item items[] = {
      {tx::L_OPEN, 0, nullptr, (void*)(intptr_t)1, 0, 0, 0, 0, 0},
      {tx::L_OPEN_TAB, 0, nullptr, (void*)(intptr_t)2, FL_MENU_DIVIDER, 0, 0, 0, 0},
      {tx::L_ADD_MARK, 0, nullptr, (void*)(intptr_t)3, 0, 0, 0, 0, 0},
      {tx::L_PROPS, 0, nullptr, (void*)(intptr_t)4, 0, 0, 0, 0, 0},
      {nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0},
    };
    for (auto& it : items) it.labelsize_ = ex::UI;
    const Fl_Menu_Item* r = items[0].popup(mx, my);
    int a = r ? (int)(intptr_t)r->user_data() : 0;
    if (a == 1) go(p);
    if (a == 2) add_tab(p);
    if (a == 3) add_mark(p);
    if (a == 4 && !ex::is_virtual(p)) {
      ex::Entry e = ex::make_entry(p);
      e.name = tree->nodes[id].label;
      (new PropsWin({e}, ex::parent_of(p)))->show();
    }
  }

  // ------------------------------------------------------------ navegar
  // Una dirección escrita: ~, relativa, una carpeta o un archivo (se abre
  // su carpeta y se marca el archivo). "" si no existe.
  std::string resolve(std::string s, std::string& select) {
    while (!s.empty() && (s.back() == ' ' || s.back() == '"' || s.back() == '\'')) s.pop_back();
    while (!s.empty() && (s[0] == ' ' || s[0] == '"' || s[0] == '\'')) s.erase(0, 1);
    if (s.empty()) return "";
    if (s == ex::COMPUTER || ex::fold(s) == ex::fold(tx::COMPUTER)) return ex::COMPUTER;
    if (s[0] == '~') s = ex::home_dir() + s.substr(1);
#ifdef _WIN32
    if (s.size() == 2 && s[1] == ':') s += '\\';
#endif
    fs::path p = ex::P(s);
    if (p.is_relative() && !ex::is_virtual(tabs[cur].path)) p = ex::P(tabs[cur].path) / p;
    std::string r = ex::U(p.lexically_normal());
    while (r.size() > 1 && (r.back() == '/' || r.back() == '\\') && ex::P(r.substr(0, r.size() - 1)).has_relative_path()) r.pop_back();
    ex::Meta m = ex::meta(r);
    if (!m.ok) return "";
    if (!m.dir || ex::make_entry(r).bundle) {
      select = ex::base_name(r);
      r = ex::parent_of(r);
    }
    return r;
  }

  void go(const std::string& path, bool record = true, const std::string& select = "") {
    if (path.empty()) return;
    Tab& t = tabs[cur];
    if (record && !t.path.empty() && !ex::same(t.path, path)) {
      t.back.push_back(t.path);
      t.fwd.clear();
    }
    t.path = path;
    t.sel.clear();
    if (!select.empty()) t.sel.push_back(select);
    t.scroll = 0;
    filter.clear();
    Search->value("");
    load_listing();
    show_tab();
  }

  void load_listing() {
    Tab& t = tabs[cur];
    listing.clear();
    list_error.clear();
    free_space = 0;
    if (t.path == ex::COMPUTER) {
      for (auto& d : ex::drives()) {
        ex::Entry e;
        e.name = d.name;
        e.path = d.path;
        e.type = d.type;
        e.dir = e.drive = true;
        e.icon = d.icon;
        e.size = d.total;
        e.free = d.free;
        e.key = ex::fold(d.name);
        listing.push_back(e);
      }
    } else {
      ex::list_dir(t.path, show_hidden, listing, list_error);
      std::error_code ec;
      fs::space_info s = fs::space(ex::P(t.path), ec);
      if (!ec) free_space = s.available;
    }
    watched = ex::meta(t.path).mtime;
    apply_view(t.sel, t.scroll);
  }

  // Filtra, ordena y pasa a la vista (conservando lo elegido).
  void apply_view(const std::vector<std::string>& keep, int scroll) {
    std::string q = ex::fold(filter);
    std::vector<ex::Entry> shown;
    for (auto& e : listing) if (ex::matches(e.key, q)) shown.push_back(e);
    std::stable_sort(shown.begin(), shown.end(), [this](const ex::Entry& a, const ex::Entry& b) { return ex::less_entry(a, b, sort_col, sort_desc); });
    bool drives = tabs[cur].path == ex::COMPUTER;
    view->drives = drives;
    view->mode = view_mode;
    view->sort_col = sort_col;
    view->desc = sort_desc;
    view->heads[0] = tx::COL_NAME;
    view->heads[1] = drives ? tx::COL_FREE : tx::COL_DATE;
    view->heads[2] = tx::COL_TYPE;
    view->heads[3] = drives ? tx::COL_TOTAL : tx::COL_SIZE;
    view->empty_text = !list_error.empty() ? ex::fmt(tx::ERR_LIST, {list_error}) : listing.empty() ? tx::EMPTY : tx::NO_MATCH;
    view->faded.clear();
    if (clip_cut) view->faded.insert(clip.begin(), clip.end());
    view->set_items(shown, keep, scroll);
    selection_changed();
  }

  void show_tab() {
    Tab& t = tabs[cur];
    crumbs->set(t.path);
    crumbs->hidden_files = show_hidden;
    std::string name = ex::display_name(t.path);
    face->text = ex::fmt(tx::SEARCH_IN, {name});
    face->redraw();
    copy_label((name + " \xe2\x80\x94 " + tx::APP).c_str());
    tabstrip->labels.clear();
    for (auto& x : tabs) tabstrip->labels.push_back(ex::display_name(x.path));
    tabstrip->active = cur;
    tabstrip->redraw();
    if (tree->nodes.empty()) build_tree();
    tree->reveal(t.path);
    end_address();
    sync_menu();
  }

  void refresh(bool keep_scroll = true) {
    Tab& t = tabs[cur];
    t.sel = view->selected_names();
    t.scroll = keep_scroll ? view->scroll : 0;
    load_listing();
    sync_menu();
  }

  void Back_click() override {
    Tab& t = tabs[cur];
    if (t.back.empty()) return;
    std::string from = t.path, to = t.back.back();
    t.back.pop_back();
    t.fwd.push_back(from);
    go(to, false, ex::same(ex::parent_of(from), to) ? ex::base_name(from) : "");
  }

  void Forward_click() override {
    Tab& t = tabs[cur];
    if (t.fwd.empty()) return;
    std::string to = t.fwd.back();
    t.fwd.pop_back();
    t.back.push_back(t.path);
    go(to, false);
  }

  void Up_click() override {
    std::string from = tabs[cur].path, to = ex::parent_of(from);
    if (to.empty()) return;
    go(to, true, to == ex::COMPUTER ? "" : ex::base_name(from));
    if (to == ex::COMPUTER) {
      for (int i = 0; i < view->n(); i++) if (ex::same(view->items[i].path, from)) { view->select_only(i); view->focus = i; view->changed(); }
    }
  }

  void Refresh_click() override {
    tree->refresh(tabs[cur].path);
    refresh();
  }

  void Watch_timer() override {
    if (theme == 2 && ex::system_dark() != was_dark) apply_theme();
    clip_check();
    sync_menu();
    const Tab& t = tabs[cur];
    if (ex::is_virtual(t.path) || view->editing >= 0 || view->band) return;
    ex::Meta m = ex::meta(t.path);
    if (m.ok && m.mtime != watched) refresh();
  }

  void open_item(const ex::Entry& e, bool new_tab) {
    if (e.dir && !e.bundle) {
      if (new_tab) add_tab(e.path);
      else go(e.path);
      return;
    }
    if (!ex::os_open(e.path)) dlg::error(ex::fmt(tx::ERR_OPEN, {e.name}));
  }

  int view_key(int k) {
    bool cmd = Fl::event_state(FL_COMMAND) != 0;
    if (k == FL_BackSpace && !cmd) { Back_click(); return 1; }
#ifdef __APPLE__
    if (cmd && k == FL_Down) { if (view->focus >= 0) open_item(view->items[view->focus], false); return 1; }
#endif
    if (k == FL_Delete) { act(ActDelete); return 1; }
    return 0;
  }

  // ---- la dirección: migas o texto
  void edit_address() {
    crumbs->hide();
    Address->show();
    Address->value(ex::is_virtual(tabs[cur].path) ? tx::COMPUTER : tabs[cur].path.c_str());
    Address->take_focus();
    ex::select_text(Address, 0, (int)std::strlen(Address->value()));
    NavBar->redraw();
  }

  void end_address() {
    if (!Address->visible()) return;
    Address->hide();
    crumbs->show();
    NavBar->redraw();
  }

  void Address_enter() override {
    std::string typed = Address->value(), select;
    std::string p = resolve(typed, select);
    if (p.empty()) {
      dlg::error(ex::fmt(tx::ERR_NOT_FOUND, {typed}));
      Address->take_focus();
      return;
    }
    end_address();
    view->take_focus();
    go(p, true, select);
  }

  void Search_enter() override {
    std::string q = Search->value();
    if (q == filter) return;
    filter = q;
    apply_view(view->selected_names(), 0);
  }

  // ---- pestañas
  void save_tab() {
    if (cur < (int)tabs.size()) {
      tabs[cur].sel = view->selected_names();
      tabs[cur].scroll = view->scroll;
    }
  }

  void add_tab(const std::string& path) {
    save_tab();
    Tab t;
    t.path = path;
    tabs.push_back(t);
    cur = (int)tabs.size() - 1;
    filter.clear();
    Search->value("");
    load_listing();
    show_tab();
  }

  void switch_tab(int i) {
    if (i == cur || i < 0 || i >= (int)tabs.size()) return;
    save_tab();
    cur = i;
    filter.clear();
    Search->value("");
    load_listing();
    show_tab();
  }

  void close_tab(int i) {
    if (tabs.size() < 2 || i < 0 || i >= (int)tabs.size()) return;
    save_tab();
    tabs.erase(tabs.begin() + i);
    if (cur >= i && cur > 0) cur--;
    cur = std::min(cur, (int)tabs.size() - 1);
    load_listing();
    show_tab();
  }

  void tab_menu(int i, int mx, int my) {
    Fl_Menu_Item items[] = {
      {tx::TAB_NEW, 0, nullptr, (void*)(intptr_t)1, FL_MENU_DIVIDER, 0, 0, 0, 0},
      {tx::TAB_CLOSE, 0, nullptr, (void*)(intptr_t)2, tabs.size() > 1 ? 0 : FL_MENU_INACTIVE, 0, 0, 0, 0},
      {tx::TAB_OTHERS, 0, nullptr, (void*)(intptr_t)3, tabs.size() > 1 ? 0 : FL_MENU_INACTIVE, 0, 0, 0, 0},
      {nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0},
    };
    for (auto& it : items) it.labelsize_ = ex::UI;
    const Fl_Menu_Item* r = items[0].popup(mx, my);
    int a = r ? (int)(intptr_t)r->user_data() : 0;
    if (a == 1) add_tab(tabs[i].path);
    if (a == 2) close_tab(i);
    if (a == 3) {
      save_tab();
      Tab keep = tabs[i];
      tabs = {keep};
      cur = 0;
      load_listing();
      show_tab();
    }
  }

  // ---- selección: panel de detalles y barra de estado
  void selection_changed() {
    auto idx = view->selected();
    const Tab& t = tabs[cur];
    uintmax_t bytes = 0;
    for (int i : idx) if (!view->items[i].dir) bytes += view->items[i].size;
    std::string info, more, type;
    if (idx.empty()) {
      detail_icon->icon = t.path == ex::COMPUTER ? ex::IcComputer : ex::IcFolder;
      detail_icon->ext.clear();
      DetailName->text(ex::display_name(t.path));
      type = listing.size() == 1 ? tx::ONE_ITEM : ex::fmt(tx::N_ITEMS, {ex::group(listing.size())});
      if (!ex::is_virtual(t.path)) {
        info = ex::fmt(tx::D_MODIFIED, {ex::date_text(ex::meta(t.path).mtime)});
        more = ex::fmt(tx::FREE_SPACE, {ex::size_text(free_space)});
      }
    } else if (idx.size() == 1) {
      const ex::Entry& e = view->items[idx[0]];
      detail_icon->icon = e.icon;
      detail_icon->ext = e.ext;
      DetailName->text(e.name);
      type = e.type;
      if (e.drive) {
        info = e.size ? ex::fmt(tx::D_FREE, {ex::size_text(e.free)}) : "";
        more = e.size ? ex::fmt(tx::D_TOTAL, {ex::size_text(e.size)}) : "";
      } else {
        info = ex::fmt(tx::D_MODIFIED, {ex::date_text(e.mtime)});
        if (!e.dir) more = ex::fmt(tx::D_SIZE, {ex::size_text(e.size)});
      }
    } else {
      detail_icon->icon = ex::IcMany;
      detail_icon->ext.clear();
      DetailName->text(ex::fmt(tx::N_SELECTED, {ex::group(idx.size())}));
      if (bytes) info = ex::fmt(tx::D_SIZE, {ex::size_text(bytes)});
    }
    DetailType->text(type);
    DetailInfo->text(info);
    DetailMore->text(more);
    DetailsPane->redraw();
    const char* dot = "    \xc2\xb7    ";
    std::string s = view->n() == 1 ? tx::ONE_ITEM : ex::fmt(tx::N_ITEMS, {ex::group(view->n())});
    if (!filter.empty()) s += dot + ex::fmt(tx::FILTERED, {ex::group(view->n()), ex::group(listing.size())});
    if (!idx.empty()) {
      s += dot + (idx.size() == 1 ? std::string(tx::ONE_SELECTED) : ex::fmt(tx::N_SELECTED, {ex::group(idx.size())}));
      if (bytes) s += "  (" + ex::size_text(bytes) + ")";
    }
    if (!ex::is_virtual(t.path) && list_error.empty()) s += dot + ex::fmt(tx::FREE_SPACE, {ex::size_text(free_space)});
    Status->text(s);
    sync_menu();
  }

  // ------------------------------------------------------------ acciones
  void Menu1_click(const std::string& item) override {
    auto it = actions.find(item);
    if (it != actions.end()) act(it->second);
  }

  void Folders_click() override { act(ActShowTree); }
  void NewFolder_click() override { act(ActNewFolder); }
  void Cut_click() override { act(ActCut); }
  void Copy_click() override { act(ActCopy); }
  void Paste_click() override { act(ActPaste); }
  void Delete_click() override { act(ActDelete); }
  void Properties_click() override { act(ActProps); }
  void Hidden_click() override { act(ActShowHidden); }
  void ViewIcons_click() override { act(ActViewIcons); }
  void ViewList_click() override { act(ActViewList); }
  void ViewDetails_click() override { act(ActViewDetails); }

  std::vector<ex::Entry> chosen() {
    std::vector<ex::Entry> out;
    for (int i : view->selected()) out.push_back(view->items[i]);
    return out;
  }

  void set_view(int mode) {
    view_mode = mode;
    apply_view(view->selected_names(), 0);
    paint_tools();
    sync_menu();
  }

  void act(Act a) {
    const std::string here = tabs[cur].path;
    bool real = !ex::is_virtual(here);
    auto sel = chosen();
    switch (a) {
    case ActOpen: for (auto& e : sel) { open_item(e, false); if (e.dir && !e.bundle) break; } break;
    case ActOpenTab:
      for (auto& e : sel) if (e.dir && !e.bundle) add_tab(e.path);
      break;
    case ActNewTab: add_tab(here); break;
    case ActCloseTab: close_tab(cur); break;
    case ActNewFolder: if (real) new_folder(); break;
    case ActRename: if (real && view->selected().size() == 1) view->start_rename(view->selected()[0]); break;
    case ActDelete: if (real) delete_items(sel, false); break;
    case ActDeleteNow: if (real) delete_items(sel, true); break;
    case ActProps:
      if (!sel.empty()) (new PropsWin(sel, ex::display_name(here) == here ? here : (real ? here : tx::COMPUTER)))->show();
      else if (real) {
        ex::Entry e = ex::make_entry(here);
        e.name = ex::display_name(here);
        (new PropsWin({e}, ex::parent_of(here) == ex::COMPUTER ? tx::COMPUTER : ex::parent_of(here)))->show();
      }
      break;
    case ActQuit: do_callback(); break;
    case ActCut: case ActCopy:
      if (!real || sel.empty()) break;
      clip.clear();
      for (auto& e : sel) clip.push_back(e.path);
      clip_cut = a == ActCut;
      ex::clip_put(clip, clip_cut);
      clip_mark = ex::clip_seq();
      view->faded.clear();
      if (clip_cut) view->faded.insert(clip.begin(), clip.end());
      view->redraw();
      sync_menu();
      break;
    case ActPaste: if (real) paste(); break;
    case ActCopyPath: {
      std::string s;
      for (auto& e : sel) s += (s.empty() ? "" : "\n") + e.path;
      if (s.empty()) s = here;
      Fl::copy(s.c_str(), (int)s.size(), 1);
      break;
    }
    case ActSelectAll: view->select_all(); break;
    case ActInvert: view->invert(); break;
    case ActViewIcons: set_view(FileView::Icons); break;
    case ActViewList: set_view(FileView::List); break;
    case ActViewDetails: set_view(FileView::Details); break;
    case ActSortName: case ActSortDate: case ActSortType: case ActSortSize:
      sort_col = a - ActSortName;
      apply_view(view->selected_names(), 0);
      break;
    case ActSortDesc: sort_desc = !sort_desc; apply_view(view->selected_names(), 0); break;
    case ActShowTree: show_tree = !show_tree; layout(); break;
    case ActShowMarks: show_marks = !show_marks; layout(); break;
    case ActShowDetails: show_details = !show_details; layout(); break;
    case ActShowHidden:
      show_hidden = !show_hidden;
      tree->nodes.clear();
      build_tree();
      tree->reveal(here);
      refresh();
      paint_tools();
      break;
    case ActRefresh: Refresh_click(); break;
    case ActBack: Back_click(); break;
    case ActForward: Forward_click(); break;
    case ActUp: Up_click(); break;
    case ActHome: go(ex::home_dir()); break;
    case ActDesktop: go(ex::user_dir(0)); break;
    case ActComputer: go(ex::COMPUTER); break;
    case ActGoto: edit_address(); break;
    case ActFind: face->hide(); Search->show(); Search->take_focus(); NavBar->redraw(); break;
    case ActAddMark: {
      std::string p = here;
      if (sel.size() == 1 && sel[0].dir && !sel[0].bundle) p = sel[0].path;
      add_mark(p);
      break;
    }
    case ActOrganize: organize_marks(); break;
    case ActTerminal: if (real && !ex::os_terminal(here)) dlg::error(tx::ERR_TERMINAL); break;
    case ActReveal: if (real) ex::os_reveal(sel.empty() ? here : sel[0].path); break;
    case ActKeys: show_keys(); break;
    case ActAbout: {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", Fl::api_version() / 10000, Fl::api_version() / 100 % 100, Fl::api_version() % 100);
      dlg::ask(tx::APP, ex::fmt(tx::ABOUT_TEXT, {v}), {tx::OK}, ex::IcFolder);
      break;
    }
    case ActThemeLight: case ActThemeDark: case ActThemeSystem:
      theme = a - ActThemeLight;
      apply_theme();
      break;
    case ActNone: break;
    }
    sync_menu();
  }

  // ---- menús contextuales
  void view_menu(int i, int mx, int my) {
    const std::string here = tabs[cur].path;
    bool real = !ex::is_virtual(here);
    auto sel = chosen();
    int off = FL_MENU_INACTIVE;
    std::vector<Fl_Menu_Item> m;
    auto add = [&](const char* label, Act a, int flags = 0) {
      Fl_Menu_Item it = {label, shortcuts.count(a) ? shortcuts[a] : 0, nullptr, (void*)(intptr_t)a, flags, 0, 0, ex::UI, 0};
      m.push_back(it);
    };
    auto sub = [&](const char* label) {
      Fl_Menu_Item it = {label, 0, nullptr, nullptr, FL_SUBMENU, 0, 0, ex::UI, 0};
      m.push_back(it);
    };
    auto end = [&](int flags = 0) {
      m.push_back(Fl_Menu_Item{nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0});
      if (flags && m.size() >= 2) {
        // El separador va en el submenú (el elemento que lo abre).
        for (int k = (int)m.size() - 2; k >= 0; k--) if (m[k].flags & FL_SUBMENU) { m[k].flags |= flags; break; }
      }
    };
    if (i >= 0) {
      bool folder = sel.size() == 1 && sel[0].dir && !sel[0].bundle;
      add(tx::L_OPEN, ActOpen, folder ? 0 : FL_MENU_DIVIDER);
      if (folder) add(tx::L_OPEN_TAB, ActOpenTab, FL_MENU_DIVIDER);
      add(tx::L_CUT, ActCut, real ? 0 : off);
      add(tx::L_COPY, ActCopy, real ? FL_MENU_DIVIDER : off | FL_MENU_DIVIDER);
      add(tx::L_COPY_PATH, ActCopyPath, FL_MENU_DIVIDER);
      add(tx::L_DELETE, ActDelete, real ? 0 : off);
      add(tx::L_RENAME, ActRename, real && sel.size() == 1 ? FL_MENU_DIVIDER : off | FL_MENU_DIVIDER);
      if (folder) add(tx::L_ADD_MARK, ActAddMark);
      add(tx::L_REVEAL, ActReveal, real ? FL_MENU_DIVIDER : off | FL_MENU_DIVIDER);
      add(tx::L_PROPS, ActProps);
    } else {
      sub(tx::M_VIEW);
      add(tx::L_VIEW_ICONS, ActViewIcons, FL_MENU_RADIO | (view_mode == FileView::Icons ? FL_MENU_VALUE : 0));
      add(tx::L_VIEW_LIST, ActViewList, FL_MENU_RADIO | (view_mode == FileView::List ? FL_MENU_VALUE : 0));
      add(tx::L_VIEW_DETAILS, ActViewDetails, FL_MENU_RADIO | (view_mode == FileView::Details ? FL_MENU_VALUE : 0));
      end();
      sub(tx::M_SORT);
      add(tx::L_SORT_NAME, ActSortName, FL_MENU_RADIO | (sort_col == 0 ? FL_MENU_VALUE : 0));
      add(tx::L_SORT_DATE, ActSortDate, FL_MENU_RADIO | (sort_col == 1 ? FL_MENU_VALUE : 0));
      add(tx::L_SORT_TYPE, ActSortType, FL_MENU_RADIO | (sort_col == 2 ? FL_MENU_VALUE : 0));
      add(tx::L_SORT_SIZE, ActSortSize, FL_MENU_RADIO | (sort_col == 3 ? FL_MENU_VALUE : 0) | FL_MENU_DIVIDER);
      add(tx::L_SORT_DESC, ActSortDesc, FL_MENU_TOGGLE | (sort_desc ? FL_MENU_VALUE : 0));
      end();
      add(tx::L_REFRESH, ActRefresh, FL_MENU_DIVIDER);
      add(tx::L_PASTE, ActPaste, (real && (ex::clip_has() || !clip.empty()) ? 0 : off) | FL_MENU_DIVIDER);
      add(tx::L_NEW_FOLDER, ActNewFolder, (real ? 0 : off) | FL_MENU_DIVIDER);
      add(tx::L_TERMINAL, ActTerminal, real ? 0 : off);
      add(tx::L_ADD_MARK, ActAddMark, FL_MENU_DIVIDER);
      add(tx::L_PROPS, ActProps, real ? 0 : off);
    }
    m.push_back(Fl_Menu_Item{nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0});
    const Fl_Menu_Item* r = m[0].popup(mx, my);
    if (r && r->user_data()) act((Act)(intptr_t)r->user_data());
    else if (r && r->label() == m[0].label() && i >= 0) act(ActOpen);
  }

  // ---- crear, renombrar, borrar
  void new_folder() {
    const std::string here = tabs[cur].path;
    std::string name = ex::unique_in(here, tx::NEW_FOLDER_NAME, true);
    std::error_code ec;
    fs::create_directory(ex::P(ex::join(here, name)), ec);
    if (ec) { dlg::error(ex::fmt(tx::ERR_NEW_FOLDER, {ex::error_text(ec)})); return; }
    tree->refresh(here);
    tabs[cur].sel = {name};
    tabs[cur].scroll = view->scroll;
    filter.clear();
    Search->value("");
    load_listing();
    for (int i = 0; i < view->n(); i++) if (view->items[i].name == name) view->start_rename(i);
  }

  void rename_item(int i, std::string name) {
    const ex::Entry e = view->items[i];
    while (!name.empty() && (name.back() == ' ' || name.back() == '.')) name.pop_back();
    while (!name.empty() && name[0] == ' ') name.erase(0, 1);
    if (name.empty() || name == e.name) return;
    std::string bad = ex::bad_chars();
    if (name.find_first_of(bad) != std::string::npos) {
      std::string shown;
      for (char c : bad) { shown += c; shown += ' '; }
      dlg::error(ex::fmt(tx::ERR_BAD_NAME, {shown}));
      view->start_rename(i);
      return;
    }
    const std::string here = tabs[cur].path;
    std::string to = ex::join(here, name);
    if (ex::exists(to) && ex::lower(name) != ex::lower(e.name)) {
      dlg::error(ex::fmt(tx::ERR_EXISTS, {name}));
      view->start_rename(i);
      return;
    }
    if (!e.dir) {
      size_t a = e.name.find_last_of('.'), b = name.find_last_of('.');
      std::string ea = a == std::string::npos || a == 0 ? "" : ex::lower(e.name.substr(a));
      std::string eb = b == std::string::npos || b == 0 ? "" : ex::lower(name.substr(b));
      if (ea != eb && dlg::ask(tx::ASK_EXT, "", {tx::B_YES, tx::B_NO}, ex::IcWarn, &e, nullptr, nullptr, 1) != 0) return;
    }
    std::error_code ec;
    fs::rename(ex::P(e.path), ex::P(to), ec);
    if (ec) { dlg::error(ex::fmt(tx::ERR_RENAME, {ex::error_text(ec)})); return; }
    for (auto& m : marks) if (ex::same(m.path, e.path)) m.path = to;
    tree->refresh(here);
    tabs[cur].sel = {name};
    tabs[cur].scroll = view->scroll;
    load_listing();
  }

  void delete_items(const std::vector<ex::Entry>& sel, bool now) {
    if (sel.empty()) return;
    const std::string here = tabs[cur].path;
    std::string q = sel.size() == 1 ? ex::fmt(now ? tx::DEL_NOW_ONE : tx::DEL_ONE, {sel[0].name})
                                    : ex::fmt(now ? tx::DEL_NOW_MANY : tx::DEL_MANY, {ex::group(sel.size())});
    int r = dlg::ask(q, now ? tx::DEL_NOW_NOTE : tx::DEL_NOTE, {now ? tx::B_DELETE_NOW : tx::B_TRASH, tx::CANCEL},
                     ex::IcWarn, sel.size() == 1 ? &sel[0] : nullptr);
    if (r != 0) return;
    std::vector<std::string> left;
    std::string why;
    if (!now) {
      fl_cursor(FL_CURSOR_WAIT);
      Fl::flush();
      for (auto& e : sel) {
        std::string err;
        if (!ex::to_trash(e.path, err)) { left.push_back(e.path); why += "\n" + e.name + ": " + err; }
      }
      fl_cursor(FL_CURSOR_DEFAULT);
      if (left.empty()) { after_change(here); return; }
      // Lo que no se pudo reciclar: se pregunta otra vez, ahora para siempre.
      r = dlg::ask(std::string(tx::TRASH_FAILED) + why, tx::TRASH_FAILED_ASK, {tx::B_DELETE_NOW, tx::CANCEL}, ex::IcWarn, nullptr, nullptr, nullptr, 1);
      if (r != 0) { after_change(here); return; }
    } else {
      for (auto& e : sel) left.push_back(e.path);
    }
    auto job = std::make_shared<ex::Job>();
    job->kind = ex::Job::Remove;
    for (auto& p : left) job->items.push_back({p, ""});
    start_job(job, ex::fmt(tx::JOB_DELETE, {ex::group(left.size())}), here);
  }

  void after_change(const std::string& dir) {
    tree->refresh(dir);
    if (ex::same(tabs[cur].path, dir)) refresh();
  }

  void start_job(std::shared_ptr<ex::Job> job, const std::string& title, const std::string& dir, std::vector<std::string> select = {}) {
    auto* w = new JobWin(job, title);
    w->on_done = [this, dir, select](ex::Job& j) {
      if (!j.errors.empty()) {
        std::string s;
        for (size_t i = 0; i < j.errors.size() && i < 12; i++) s += j.errors[i] + "\n";
        if (j.errors.size() > 12) s += "\xe2\x80\xa6";
        dlg::error(tx::JOB_ERRORS, s);
      }
      tree->refresh(dir);
      for (auto& it : j.items) tree->refresh(ex::parent_of(it.first));
      if (ex::same(tabs[cur].path, dir)) {
        if (!select.empty()) tabs[cur].sel = select;
        else tabs[cur].sel = view->selected_names();
        tabs[cur].scroll = view->scroll;
        load_listing();
      } else if (j.kind != ex::Job::Copy) refresh();
      sync_menu();
    };
    std::thread(ex::run_job, job).detach();
  }

  // Si otro programa cambió el portapapeles, lo cortado aquí ya no se pega.
  void clip_check() {
    if (clip_mark < 0 || ex::clip_seq() == clip_mark) return;
    clip_mark = -1;
#if defined(__APPLE__) || defined(_WIN32)
    clip.clear();
    clip_cut = false;
#endif
    if (!view->faded.empty()) { view->faded.clear(); view->redraw(); }
  }

  void paste() {
    const std::string here = tabs[cur].path;
    clip_check();
    // Lo del portapapeles del sistema (de esta ventana, de otro explorador,
    // del Finder o del Explorador de Windows); si no hay, lo de aquí.
    bool cut = false;
    std::vector<std::string> from = ex::clip_get(cut);
    bool native = !from.empty();
    if (!native) { from = clip; cut = clip_cut; }
    if (from.empty()) return;
    auto job = std::make_shared<ex::Job>();
    job->kind = cut ? ex::Job::Move : ex::Job::Copy;
    job->dest = here;
    int all = -1;   // lo elegido para todos los conflictos
    std::vector<std::string> select;
    for (auto& src : from) {
      if (!ex::exists(src)) continue;
      std::string name = ex::base_name(src);
      bool is_dir = ex::meta(src).dir;
      if (is_dir && ex::inside(here, src)) { dlg::error(ex::fmt(tx::ERR_INTO_ITSELF, {name})); return; }
      bool same_dir = ex::same(ex::parent_of(src), here);
      if (same_dir && cut) continue;
      std::string target = same_dir ? ex::copy_name(here, name, is_dir) : name;
      bool replace = false;
      if (!same_dir && ex::exists(ex::join(here, target))) {
        int choice = all;
        if (choice < 0) {
          bool for_all = false;
          ex::Entry existing = ex::make_entry(ex::join(here, target));
          choice = dlg::ask(ex::fmt(tx::CONFLICT_TEXT, {target, ex::display_name(here)}), tx::CONFLICT_ASK,
                            {tx::B_REPLACE, tx::B_KEEP_BOTH, tx::B_SKIP, tx::CANCEL}, ex::IcWarn, &existing, tx::CONFLICT_ALL, &for_all, 1);
          if (choice < 0 || choice == 3) return;
          if (for_all) all = choice;
        }
        if (choice == 2) continue;
        if (choice == 1) target = ex::unique_in(here, target, is_dir);
        else replace = true;
      }
      job->items.push_back({src, ex::join(here, target)});
      job->replace.push_back(replace);
      select.push_back(target);
    }
    if (job->items.empty()) return;
    std::string title = ex::fmt(cut ? tx::JOB_MOVE : tx::JOB_COPY, {ex::group(job->items.size()), ex::display_name(here)});
    if (cut) {
      // Lo movido ya no está donde se cortó: se vacía el portapapeles.
      clip.clear();
      clip_cut = false;
      clip_mark = -1;
      view->faded.clear();
      if (native) ex::clip_clear();
    }
    start_job(job, title, here, select);
  }

  // ------------------------------------------------------------ marcadores
  std::string marks_file() const { return ex::join(cfg, "bookmarks.tsv"); }

  void load_marks() {
    if (!ex::load_marks(marks_file(), mark_folders, marks)) {
      // La primera vez: la carpeta personal y Descargas, en la barra.
      marks = {{ex::base_name(ex::home_dir()), ex::home_dir(), "", "", true}, {tx::DOWNLOADS, ex::user_dir(1), "", "", true}};
    }
    marks_changed(false);
  }

  void marks_changed(bool save = true) {
    if (save) ex::save_marks(marks_file(), mark_folders, marks);
    markbar->chips.clear();
    for (size_t i = 0; i < marks.size(); i++) if (marks[i].bar) markbar->chips.push_back({marks[i].name, (int)i});
    markbar->redraw();
    int base = Menu1->find_index(tx::M_MARKS);
    if (base < 0) return;
    int first = base + 3;   // Añadir y Organizar se quedan
    while (first < Menu1->size() && Menu1->menu()[first].label()) Menu1->remove(first);
    std::set<std::string> used;
    for (size_t i = 0; i < marks.size(); i++) {
      std::string path = std::string(tx::M_MARKS) + "/";
      if (!marks[i].folder.empty()) path += ex::menu_label(marks[i].folder) + "/";
      std::string label = ex::menu_label(marks[i].name), full = path + label;
      for (int n = 2; used.count(full); n++) full = path + label + " (" + std::to_string(n) + ")";
      used.insert(full);
      Menu1->add(full.c_str(), 0, [](Fl_Widget*, void* p) { self->open_mark((int)(intptr_t)p, false); }, (void*)(intptr_t)i);
    }
    if (marks.empty()) Menu1->add((std::string(tx::M_MARKS) + "/" + ex::menu_label(tx::NO_MARKS)).c_str(), 0, nullptr, nullptr, FL_MENU_INACTIVE);
    for (int i = 0; i < Menu1->size(); i++) {
      auto* it = const_cast<Fl_Menu_Item*>(&Menu1->menu()[i]);
      if (it->label()) it->labelsize(ex::UI);
    }
  }

  void open_mark(int i, bool new_tab) {
    if (i < 0 || i >= (int)marks.size()) return;
    std::string select;
    std::string p = marks[i].path == ex::COMPUTER ? ex::COMPUTER : resolve(marks[i].path, select);
    if (p.empty()) { dlg::error(ex::fmt(tx::ERR_MARK_PATH, {marks[i].path})); return; }
    if (new_tab) add_tab(p);
    else go(p, true, select);
  }

  void mark_menu(int i, int mx, int my) {
    Fl_Menu_Item items[] = {
      {tx::B_OPEN, 0, nullptr, (void*)(intptr_t)1, 0, 0, 0, 0, 0},
      {tx::L_OPEN_TAB, 0, nullptr, (void*)(intptr_t)2, FL_MENU_DIVIDER, 0, 0, 0, 0},
      {tx::B_EDIT, 0, nullptr, (void*)(intptr_t)3, 0, 0, 0, 0, 0},
      {tx::B_DELETE, 0, nullptr, (void*)(intptr_t)4, 0, 0, 0, 0, 0},
      {nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0},
    };
    for (auto& it : items) it.labelsize_ = ex::UI;
    const Fl_Menu_Item* r = items[0].popup(mx, my);
    int a = r ? (int)(intptr_t)r->user_data() : 0;
    if (a == 1) open_mark(i, false);
    if (a == 2) open_mark(i, true);
    if (a == 3) edit_mark(i);
    if (a == 4) remove_mark(i);
  }

  void remove_mark(int i) {
    if (dlg::ask(ex::fmt(tx::ASK_DELETE_MARK, {marks[i].name}), tx::MARK_DELETE_NOTE, {tx::B_DELETE, tx::CANCEL}, ex::IcAsk) != 0) return;
    marks.erase(marks.begin() + i);
    marks_changed();
  }

  void add_mark(const std::string& path) {
    ex::Mark m;
    m.name = ex::display_name(path);
    m.path = path;
    m.bar = false;
    if (mark_dialog(m, tx::ADD_MARK_TITLE)) {
      marks.push_back(m);
      marks_changed();
    }
  }

  void edit_mark(int i) {
    ex::Mark m = marks[i];
    if (mark_dialog(m, tx::EDIT_MARK_TITLE)) {
      marks[i] = m;
      marks_changed();
    }
  }

  // El diálogo «Añadir marcador»: nombre, dónde, ubicación, descripción y si
  // sale en la barra.
  bool mark_dialog(ex::Mark& m, const char* title) {
    const int W = 470, L = 18, F = 118, FW = W - F - 18;
    auto* d = new Fl_Double_Window(W, 336, title);
    d->color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    auto* icon = new BigIcon(L, 16, 32, 32);
    icon->icon = ex::IcStar;
    dlg::text(L + 44, 20, W - 80, 24, title, FL_HELVETICA, ex::UI + 3, 0x003399);
    auto field_label = [&](int y, const char* t) { dlg::text(L, y + 4, F - L - 6, 20, t, FL_HELVETICA, ex::UI, 0x3b4656); };
    field_label(62, tx::F_NAME);
    auto* name = new Fl_Input(F, 62, FW, 26);
    name->value(m.name.c_str());
    field_label(98, tx::F_CREATE_IN);
    auto* where = new Fl_Choice(F, 98, FW - 130, 26);
    where->textsize(ex::UI);
    auto fill = [&](const std::string& pick) {
      where->clear();
      where->add(ex::menu_label(tx::M_MARKS).c_str());
      where->value(0);
      for (size_t i = 0; i < mark_folders.size(); i++) {
        where->add(ex::menu_label(mark_folders[i]).c_str());
        if (mark_folders[i] == pick) where->value((int)i + 1);
      }
    };
    fill(m.folder);
    auto* newf = dlg::button(W - 18 - 122, 98, 122, 26, tx::F_NEW_FOLDER);
    field_label(134, tx::F_LOCATION);
    auto* loc = new Fl_Input(F, 134, FW, 26);
    // Lo de la carpeta personal, con «~» (se entiende al escribirlo).
    std::string shown = m.path == ex::COMPUTER ? std::string(tx::COMPUTER) : m.path;
    const std::string home = ex::home_dir();
    if (ex::inside(m.path, home)) shown = "~" + m.path.substr(home.size());
    loc->value(shown.c_str());
    field_label(170, tx::F_DESC);
    auto* desc = new Fl_Multiline_Input(F, 170, FW, 70);
    desc->wrap(1);
    desc->value(m.desc.c_str());
    auto* bar = new Fl_Check_Button(F, 250, FW, 24, tx::F_ON_BAR);
    bar->labelsize(ex::UI);
    bar->value(m.bar);
    for (Fl_Input_* in : {(Fl_Input_*)name, (Fl_Input_*)loc, (Fl_Input_*)desc}) {
      in->box(ex::bx(ex::BX_FIELD));
      in->textsize(ex::UI);
    }
    auto* foot = new Fl_Box(0, 290, W, 46);
    foot->box(ex::bx(ex::BX_FOOTER));
    auto* ok = dlg::button(W - 18 - 2 * 90 - 8, 300, 90, 26, tx::OK);
    auto* cancel = dlg::button(W - 18 - 90, 300, 90, 26, tx::CANCEL);
    static int result;
    result = 0;
    ok->shortcut(FL_Enter);
    ok->callback([](Fl_Widget* w, void*) { result = 1; w->window()->hide(); });
    cancel->callback([](Fl_Widget* w, void*) { w->window()->hide(); });
    struct NewFolder { Form1* f; std::function<void(const std::string&)> fill; };
    NewFolder nf{this, fill};
    newf->callback([](Fl_Widget*, void* p) {
      auto* n = static_cast<NewFolder*>(p);
      std::string v;
      if (!dlg::input(tx::ASK_MARK_FOLDER, v)) return;
      while (!v.empty() && v.back() == ' ') v.pop_back();
      if (v.empty()) return;
      auto& fs_ = n->f->mark_folders;
      if (std::find(fs_.begin(), fs_.end(), v) == fs_.end()) fs_.push_back(v);
      n->fill(v);
    }, &nf);
    d->end();
    name->take_focus();
    while (true) {
      result = 0;
      dlg::run(d);
      if (result != 1) break;
      std::string n = name->value(), select;
      std::string p = loc->value();
      std::string where_to = p == tx::COMPUTER ? ex::COMPUTER : resolve(p, select);
      if (n.empty()) { dlg::error(tx::ERR_MARK_NAME); continue; }
      if (where_to.empty()) { dlg::error(ex::fmt(tx::ERR_MARK_PATH, {p})); continue; }
      m.name = n;
      m.path = select.empty() ? where_to : ex::join(where_to, select);
      m.desc = desc->value();
      m.bar = bar->value() != 0;
      m.folder = where->value() > 0 ? mark_folders[where->value() - 1] : "";
      break;
    }
    Fl::delete_widget(d);
    marks_changed();
    return result == 1;
  }

  // «Organizar marcadores»: abrir, editar, quitar y cambiar el orden.
  void organize_marks() {
    const int W = 520, H = 360;
    auto* d = new Fl_Double_Window(W, H, tx::ORGANIZE_TITLE);
    d->color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    auto* list = new Fl_Hold_Browser(14, 14, W - 150, H - 28);
    list->format_char(0);
    list->textsize(ex::UI);
    list->box(ex::bx(ex::BX_FIELD));
    struct Ctx { Form1* f; Fl_Hold_Browser* list; Fl_Window* win; };
    static Ctx ctx;
    ctx = {this, list, d};
    auto fill = [](int pick) {
      ctx.list->clear();
      for (auto& m : ctx.f->marks) {
        std::string t = (m.folder.empty() ? "" : m.folder + " / ") + m.name + "   \xe2\x80\x94   " + (m.path == ex::COMPUTER ? std::string(tx::COMPUTER) : m.path);
        ctx.list->add(t.c_str());
      }
      if (pick > 0 && pick <= ctx.list->size()) ctx.list->value(pick);
    };
    fill(1);
    const char* names[] = {tx::B_OPEN, tx::B_EDIT, tx::B_DELETE, tx::B_UP, tx::B_DOWN, tx::B_CLOSE};
    for (int i = 0; i < 6; i++) {
      auto* b = dlg::button(W - 124, 14 + i * 34 + (i == 5 ? H - 14 - 26 - 14 - 5 * 34 : 0), 110, 26, names[i]);
      b->callback([](Fl_Widget*, void* p) {
        int what = (int)(intptr_t)p, at = ctx.list->value() - 1;
        auto& ms = ctx.f->marks;
        if (what == 5) { ctx.win->hide(); return; }
        if (at < 0 || at >= (int)ms.size()) return;
        if (what == 0) { ctx.win->hide(); ctx.f->open_mark(at, false); return; }
        if (what == 1) ctx.f->edit_mark(at);
        if (what == 2) { ctx.f->remove_mark(at); at = std::min(at, (int)ms.size() - 1); }
        if (what == 3 && at > 0) { std::swap(ms[at], ms[at - 1]); at--; ctx.f->marks_changed(); }
        if (what == 4 && at + 1 < (int)ms.size()) { std::swap(ms[at], ms[at + 1]); at++; ctx.f->marks_changed(); }
        auto refill = [](int pick) {
          ctx.list->clear();
          for (auto& m : ctx.f->marks) {
            std::string t = (m.folder.empty() ? "" : m.folder + " / ") + m.name + "   \xe2\x80\x94   " + (m.path == ex::COMPUTER ? std::string(tx::COMPUTER) : m.path);
            ctx.list->add(t.c_str());
          }
          if (pick > 0 && pick <= ctx.list->size()) ctx.list->value(pick);
        };
        refill(at + 1);
      }, (void*)(intptr_t)i);
    }
    d->end();
    dlg::run(d);
    Fl::delete_widget(d);
  }

  // ------------------------------------------------------------ ayuda
  void show_keys() {
    std::string s;
    const std::pair<Act, const char*> list[] = {
      {ActNewTab, tx::L_NEW_TAB}, {ActCloseTab, tx::L_CLOSE_TAB}, {ActNewFolder, tx::L_NEW_FOLDER}, {ActRename, tx::L_RENAME},
      {ActDelete, tx::L_DELETE}, {ActDeleteNow, tx::L_DELETE_NOW}, {ActProps, tx::L_PROPS}, {ActCut, tx::L_CUT}, {ActCopy, tx::L_COPY},
      {ActPaste, tx::L_PASTE}, {ActCopyPath, tx::L_COPY_PATH}, {ActSelectAll, tx::L_SELECT_ALL}, {ActViewIcons, tx::L_VIEW_ICONS},
      {ActViewList, tx::L_VIEW_LIST}, {ActViewDetails, tx::L_VIEW_DETAILS}, {ActShowHidden, tx::L_SHOW_HIDDEN},
      {ActShowMarks, tx::L_SHOW_MARKS}, {ActRefresh, tx::L_REFRESH}, {ActBack, tx::L_BACK}, {ActForward, tx::L_FORWARD},
      {ActUp, tx::L_UP}, {ActHome, tx::L_HOME}, {ActDesktop, tx::L_DESKTOP}, {ActComputer, tx::L_COMPUTER}, {ActGoto, tx::L_GOTO},
      {ActFind, tx::L_FIND}, {ActAddMark, tx::L_ADD_MARK},
    };
    for (auto& k : list) {
      if (!shortcuts.count(k.first)) continue;
      s += std::string(fl_shortcut_label(shortcuts[k.first])) + "\t" + k.second + "\n";
    }
    const int W = 470;
    auto* d = new Fl_Double_Window(W, 520, tx::L_KEYS);
    d->color(ex::rgb(ex::th(0xffffff, 0x23272e)));
    dlg::text(18, 14, W - 36, 24, tx::L_KEYS, FL_HELVETICA, ex::UI + 3, 0x003399);
    auto* b = new Fl_Hold_Browser(18, 46, W - 36, 330);
    b->format_char(0);
    b->textsize(ex::UI);
    static int widths[] = {150, 0};
    b->column_widths(widths);
    b->column_char('\t');
    for (auto& l : ex::split(s, '\n')) if (!l.empty()) b->add(l.c_str());
    int th = dlg::text_h(tx::KEYS_EXTRA, W - 36);
    dlg::text(18, 386, W - 36, th, tx::KEYS_EXTRA, FL_HELVETICA, ex::UI, 0x3b4656);
    int y = 386 + th + 14;
    auto* foot = new Fl_Box(0, y, W, 46);
    foot->box(ex::bx(ex::BX_FOOTER));
    auto* ok = dlg::button(W - 18 - 90, y + 10, 90, 26, tx::OK);
    ok->shortcut(FL_Enter);
    ok->callback([](Fl_Widget* w, void*) { w->window()->hide(); });
    d->end();
    d->size(W, y + 46);
    dlg::run(d);
    Fl::delete_widget(d);
  }

  // ------------------------------------------------------------ ajustes
  std::string settings_file() const { return ex::join(cfg, "settings.txt"); }

  void load_settings() {
    std::map<std::string, int> v;
    for (auto& line : ex::split(ex::read_file(settings_file()), '\n')) {
      auto eq = line.find('=');
      if (eq != std::string::npos) v[line.substr(0, eq)] = std::atoi(line.c_str() + eq + 1);
    }
    auto get = [&](const char* k, int def) { return v.count(k) ? v[k] : def; };
    view_mode = std::max(0, std::min(2, get("view", FileView::Icons)));
    sort_col = std::max(0, std::min(3, get("sort", 0)));
    sort_desc = get("desc", 0) != 0;
    show_hidden = get("hidden", 0) != 0;
    show_tree = get("tree", 1) != 0;
    show_marks = get("marks", 1) != 0;
    show_details = get("details", 1) != 0;
    theme = std::max(0, std::min(2, get("theme", 2)));
    tree_w = get("tree_w", 230);
    for (int i = 0; i < 4; i++) view->colw[i] = std::max(50, get(("col" + std::to_string(i)).c_str(), view->colw[i]));
    int ww = get("w", 0), hh = get("h", 0);
    if (ww >= 760 && hh >= 480 && ww <= Fl::w() && hh <= Fl::h()) {
      size(ww, hh);
      position((Fl::w() - ww) / 2, std::max(30, (Fl::h() - hh) / 2));
    } else {
      position((Fl::w() - w()) / 2, std::max(30, (Fl::h() - h()) / 2));
    }
  }

  void save_settings() {
    std::string s;
    auto put = [&](const std::string& k, int v) { s += k + "=" + std::to_string(v) + "\n"; };
    put("view", view_mode);
    put("sort", sort_col);
    put("desc", sort_desc);
    put("hidden", show_hidden);
    put("tree", show_tree);
    put("marks", show_marks);
    put("details", show_details);
    put("theme", theme);
    put("tree_w", tree_w);
    for (int i = 0; i < 4; i++) put("col" + std::to_string(i), view->colw[i]);
    put("w", w());
    put("h", h());
    ex::write_file(settings_file(), s);
  }

  // Prueba de humo con la ventana abierta: DMS_EXPLORER_SMOKE=1.
  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::string dir = getenv("DMS_EXPLORER_START") ? getenv("DMS_EXPLORER_START") : ex::home_dir();
    f->go(dir);
    int items = f->view->n();
    for (int m : {FileView::Details, FileView::List, FileView::Icons}) { f->set_view(m); Fl::check(); }
    f->act(ActSelectAll);
    f->add_tab(dir);
    f->go(ex::COMPUTER);
    int drives = f->view->n();
    f->act(ActBack);
    f->act(ActShowHidden);
    f->act(ActShowHidden);
    // El tema cambia en caliente: claro, oscuro y vuelta al del sistema.
    f->act(ActThemeLight);
    bool light = !ex::dark;
    f->act(ActThemeDark);
    bool dark = ex::dark;
    f->act(ActThemeSystem);
    std::printf("smoke ok items=%d tabs=%d drives=%d marks=%d themes=%d\n", items, (int)f->tabs.size(), drives, (int)f->marks.size(), light && dark);
    std::fflush(stdout);
    f->hide();
  }
};
''';
