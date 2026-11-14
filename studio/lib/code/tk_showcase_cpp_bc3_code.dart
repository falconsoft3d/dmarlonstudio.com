part of 'tk_examples.dart';

// El código en C++ del Visor BC3 (tk_showcase_cpp_bc3.dart): va tal cual
// en Form1.cpp, después de los textos (namespace tx).
const _bc3Includes = r'''#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Table_Row.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Tree_Item.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#include <FL/platform.H>
''';

const _bc3Code = r'''
// ============================================================ el modelo
namespace bv {

// ---- textos y números
inline std::string fmt(const char* pat, std::initializer_list<std::string> a) {
  std::vector<std::string> v(a);
  std::string s = pat, out;
  for (size_t i = 0; i < s.size(); i++) {
    if (s[i] == '{' && i + 2 < s.size() && s[i + 2] == '}' && s[i + 1] >= '0' && s[i + 1] <= '9') {
      size_t k = (size_t)(s[i + 1] - '0');
      if (k < v.size()) out += v[k];
      i += 2;
    } else {
      out += s[i];
    }
  }
  return out;
}
inline std::string trim(const std::string& s) {
  size_t a = s.find_first_not_of(" \t\r\n");
  if (a == std::string::npos) return "";
  size_t b = s.find_last_not_of(" \t\r\n");
  return s.substr(a, b - a + 1);
}
inline std::vector<std::string> split(const std::string& s, char c) {
  std::vector<std::string> v;
  std::string cur;
  for (char ch : s) {
    if (ch == c) {
      v.push_back(cur);
      cur.clear();
    } else {
      cur += ch;
    }
  }
  v.push_back(cur);
  return v;
}
inline bool ends_with(const std::string& s, const char* e) {
  size_t n = std::strlen(e);
  return s.size() >= n && s.compare(s.size() - n, n, e) == 0;
}
// «12.5» o «12,5»; vacío: no hay número.
inline bool num(const std::string& s0, double& out) {
  std::string s = trim(s0);
  if (s.empty()) return false;
  for (auto& ch : s)
    if (ch == ',') ch = '.';
  char* e = nullptr;
  double v = std::strtod(s.c_str(), &e);
  if (e == s.c_str()) return false;
  out = v;
  return true;
}
inline double round2(double v) { return (v >= 0 ? std::floor(v * 100 + 0.5 + 1e-9) : -std::floor(-v * 100 + 0.5 + 1e-9)) / 100; }
// Con los separadores de miles y decimales del idioma.
inline std::string number(double v, int dec = 2, bool thousands = true) {
  char buf[64];
  std::snprintf(buf, sizeof buf, "%.*f", dec, std::fabs(v));
  std::string s = buf, ip = s, fp;
  size_t dot = s.find('.');
  if (dot != std::string::npos) {
    ip = s.substr(0, dot);
    fp = s.substr(dot + 1);
  }
  std::string o;
  int n = 0;
  for (int i = (int)ip.size() - 1; i >= 0; i--) {
    o.insert(o.begin(), ip[(size_t)i]);
    if (thousands && ++n % 3 == 0 && i > 0) o.insert(0, tx::THOUSANDS);
  }
  if (!fp.empty()) o += std::string(tx::DECIMAL) + fp;
  bool zero = std::fabs(v) * std::pow(10.0, dec) < 0.5;
  return (v < 0 && !zero ? "-" : "") + o;
}
// Cantidades: hasta 3 decimales, sin ceros de sobra (pero al menos 2).
inline std::string qty(double v) {
  std::string s = number(v, 3);
  size_t d = s.find(tx::DECIMAL);
  if (d == std::string::npos) return s;
  while (s.size() > d + std::strlen(tx::DECIMAL) + 2 && s.back() == '0') s.pop_back();
  return s;
}
// Minúsculas y sin acentos, para buscar.
inline std::string fold(const std::string& s) {
  static const char* m = "aaaaaaaceeeeiiiidnooooo/ouuuuyty";
  std::string o;
  for (size_t i = 0; i < s.size(); i++) {
    unsigned char c = (unsigned char)s[i];
    if (c < 128) {
      o += (char)std::tolower(c);
    } else if (c == 0xC3 && i + 1 < s.size()) {
      unsigned char d = (unsigned char)s[++i];
      o += d >= 0x80 && d <= 0xBF ? m[d & 0x1F] : '?';
    } else {
      o += (char)c;
    }
  }
  return o;
}

// ---- juegos de caracteres: FIEBDC-3 usa 850 (por defecto), 437 o ANSI (Windows-1252)
const char* const CP850[128] = {
    "\xc3\x87", "\xc3\xbc", "\xc3\xa9", "\xc3\xa2", "\xc3\xa4", "\xc3\xa0", "\xc3\xa5", "\xc3\xa7",
    "\xc3\xaa", "\xc3\xab", "\xc3\xa8", "\xc3\xaf", "\xc3\xae", "\xc3\xac", "\xc3\x84", "\xc3\x85",
    "\xc3\x89", "\xc3\xa6", "\xc3\x86", "\xc3\xb4", "\xc3\xb6", "\xc3\xb2", "\xc3\xbb", "\xc3\xb9",
    "\xc3\xbf", "\xc3\x96", "\xc3\x9c", "\xc3\xb8", "\xc2\xa3", "\xc3\x98", "\xc3\x97", "\xc6\x92",
    "\xc3\xa1", "\xc3\xad", "\xc3\xb3", "\xc3\xba", "\xc3\xb1", "\xc3\x91", "\xc2\xaa", "\xc2\xba",
    "\xc2\xbf", "\xc2\xae", "\xc2\xac", "\xc2\xbd", "\xc2\xbc", "\xc2\xa1", "\xc2\xab", "\xc2\xbb",
    "\xe2\x96\x91", "\xe2\x96\x92", "\xe2\x96\x93", "\xe2\x94\x82", "\xe2\x94\xa4", "\xc3\x81", "\xc3\x82", "\xc3\x80",
    "\xc2\xa9", "\xe2\x95\xa3", "\xe2\x95\x91", "\xe2\x95\x97", "\xe2\x95\x9d", "\xc2\xa2", "\xc2\xa5", "\xe2\x94\x90",
    "\xe2\x94\x94", "\xe2\x94\xb4", "\xe2\x94\xac", "\xe2\x94\x9c", "\xe2\x94\x80", "\xe2\x94\xbc", "\xc3\xa3", "\xc3\x83",
    "\xe2\x95\x9a", "\xe2\x95\x94", "\xe2\x95\xa9", "\xe2\x95\xa6", "\xe2\x95\xa0", "\xe2\x95\x90", "\xe2\x95\xac", "\xc2\xa4",
    "\xc3\xb0", "\xc3\x90", "\xc3\x8a", "\xc3\x8b", "\xc3\x88", "\xc4\xb1", "\xc3\x8d", "\xc3\x8e",
    "\xc3\x8f", "\xe2\x94\x98", "\xe2\x94\x8c", "\xe2\x96\x88", "\xe2\x96\x84", "\xc2\xa6", "\xc3\x8c", "\xe2\x96\x80",
    "\xc3\x93", "\xc3\x9f", "\xc3\x94", "\xc3\x92", "\xc3\xb5", "\xc3\x95", "\xc2\xb5", "\xc3\xbe",
    "\xc3\x9e", "\xc3\x9a", "\xc3\x9b", "\xc3\x99", "\xc3\xbd", "\xc3\x9d", "\xc2\xaf", "\xc2\xb4",
    "\xc2\xad", "\xc2\xb1", "\xe2\x80\x97", "\xc2\xbe", "\xc2\xb6", "\xc2\xa7", "\xc3\xb7", "\xc2\xb8",
    "\xc2\xb0", "\xc2\xa8", "\xc2\xb7", "\xc2\xb9", "\xc2\xb3", "\xc2\xb2", "\xe2\x96\xa0", "\xc2\xa0"};
const char* const CP437[128] = {
    "\xc3\x87", "\xc3\xbc", "\xc3\xa9", "\xc3\xa2", "\xc3\xa4", "\xc3\xa0", "\xc3\xa5", "\xc3\xa7",
    "\xc3\xaa", "\xc3\xab", "\xc3\xa8", "\xc3\xaf", "\xc3\xae", "\xc3\xac", "\xc3\x84", "\xc3\x85",
    "\xc3\x89", "\xc3\xa6", "\xc3\x86", "\xc3\xb4", "\xc3\xb6", "\xc3\xb2", "\xc3\xbb", "\xc3\xb9",
    "\xc3\xbf", "\xc3\x96", "\xc3\x9c", "\xc2\xa2", "\xc2\xa3", "\xc2\xa5", "\xe2\x82\xa7", "\xc6\x92",
    "\xc3\xa1", "\xc3\xad", "\xc3\xb3", "\xc3\xba", "\xc3\xb1", "\xc3\x91", "\xc2\xaa", "\xc2\xba",
    "\xc2\xbf", "\xe2\x8c\x90", "\xc2\xac", "\xc2\xbd", "\xc2\xbc", "\xc2\xa1", "\xc2\xab", "\xc2\xbb",
    "\xe2\x96\x91", "\xe2\x96\x92", "\xe2\x96\x93", "\xe2\x94\x82", "\xe2\x94\xa4", "\xe2\x95\xa1", "\xe2\x95\xa2", "\xe2\x95\x96",
    "\xe2\x95\x95", "\xe2\x95\xa3", "\xe2\x95\x91", "\xe2\x95\x97", "\xe2\x95\x9d", "\xe2\x95\x9c", "\xe2\x95\x9b", "\xe2\x94\x90",
    "\xe2\x94\x94", "\xe2\x94\xb4", "\xe2\x94\xac", "\xe2\x94\x9c", "\xe2\x94\x80", "\xe2\x94\xbc", "\xe2\x95\x9e", "\xe2\x95\x9f",
    "\xe2\x95\x9a", "\xe2\x95\x94", "\xe2\x95\xa9", "\xe2\x95\xa6", "\xe2\x95\xa0", "\xe2\x95\x90", "\xe2\x95\xac", "\xe2\x95\xa7",
    "\xe2\x95\xa8", "\xe2\x95\xa4", "\xe2\x95\xa5", "\xe2\x95\x99", "\xe2\x95\x98", "\xe2\x95\x92", "\xe2\x95\x93", "\xe2\x95\xab",
    "\xe2\x95\xaa", "\xe2\x94\x98", "\xe2\x94\x8c", "\xe2\x96\x88", "\xe2\x96\x84", "\xe2\x96\x8c", "\xe2\x96\x90", "\xe2\x96\x80",
    "\xce\xb1", "\xc3\x9f", "\xce\x93", "\xcf\x80", "\xce\xa3", "\xcf\x83", "\xc2\xb5", "\xcf\x84",
    "\xce\xa6", "\xce\x98", "\xce\xa9", "\xce\xb4", "\xe2\x88\x9e", "\xcf\x86", "\xce\xb5", "\xe2\x88\xa9",
    "\xe2\x89\xa1", "\xc2\xb1", "\xe2\x89\xa5", "\xe2\x89\xa4", "\xe2\x8c\xa0", "\xe2\x8c\xa1", "\xc3\xb7", "\xe2\x89\x88",
    "\xc2\xb0", "\xe2\x88\x99", "\xc2\xb7", "\xe2\x88\x9a", "\xe2\x81\xbf", "\xc2\xb2", "\xe2\x96\xa0", "\xc2\xa0"};
const char* const CP1252[128] = {
    "\xe2\x82\xac", "\xc2\x81", "\xe2\x80\x9a", "\xc6\x92", "\xe2\x80\x9e", "\xe2\x80\xa6", "\xe2\x80\xa0", "\xe2\x80\xa1",
    "\xcb\x86", "\xe2\x80\xb0", "\xc5\xa0", "\xe2\x80\xb9", "\xc5\x92", "\xc2\x8d", "\xc5\xbd", "\xc2\x8f",
    "\xc2\x90", "\xe2\x80\x98", "\xe2\x80\x99", "\xe2\x80\x9c", "\xe2\x80\x9d", "\xe2\x80\xa2", "\xe2\x80\x93", "\xe2\x80\x94",
    "\xcb\x9c", "\xe2\x84\xa2", "\xc5\xa1", "\xe2\x80\xba", "\xc5\x93", "\xc2\x9d", "\xc5\xbe", "\xc5\xb8",
    "\xc2\xa0", "\xc2\xa1", "\xc2\xa2", "\xc2\xa3", "\xc2\xa4", "\xc2\xa5", "\xc2\xa6", "\xc2\xa7",
    "\xc2\xa8", "\xc2\xa9", "\xc2\xaa", "\xc2\xab", "\xc2\xac", "\xc2\xad", "\xc2\xae", "\xc2\xaf",
    "\xc2\xb0", "\xc2\xb1", "\xc2\xb2", "\xc2\xb3", "\xc2\xb4", "\xc2\xb5", "\xc2\xb6", "\xc2\xb7",
    "\xc2\xb8", "\xc2\xb9", "\xc2\xba", "\xc2\xbb", "\xc2\xbc", "\xc2\xbd", "\xc2\xbe", "\xc2\xbf",
    "\xc3\x80", "\xc3\x81", "\xc3\x82", "\xc3\x83", "\xc3\x84", "\xc3\x85", "\xc3\x86", "\xc3\x87",
    "\xc3\x88", "\xc3\x89", "\xc3\x8a", "\xc3\x8b", "\xc3\x8c", "\xc3\x8d", "\xc3\x8e", "\xc3\x8f",
    "\xc3\x90", "\xc3\x91", "\xc3\x92", "\xc3\x93", "\xc3\x94", "\xc3\x95", "\xc3\x96", "\xc3\x97",
    "\xc3\x98", "\xc3\x99", "\xc3\x9a", "\xc3\x9b", "\xc3\x9c", "\xc3\x9d", "\xc3\x9e", "\xc3\x9f",
    "\xc3\xa0", "\xc3\xa1", "\xc3\xa2", "\xc3\xa3", "\xc3\xa4", "\xc3\xa5", "\xc3\xa6", "\xc3\xa7",
    "\xc3\xa8", "\xc3\xa9", "\xc3\xaa", "\xc3\xab", "\xc3\xac", "\xc3\xad", "\xc3\xae", "\xc3\xaf",
    "\xc3\xb0", "\xc3\xb1", "\xc3\xb2", "\xc3\xb3", "\xc3\xb4", "\xc3\xb5", "\xc3\xb6", "\xc3\xb7",
    "\xc3\xb8", "\xc3\xb9", "\xc3\xba", "\xc3\xbb", "\xc3\xbc", "\xc3\xbd", "\xc3\xbe", "\xc3\xbf"};
inline bool valid_utf8(const std::string& s, bool& any) {
  any = false;
  for (size_t i = 0; i < s.size();) {
    unsigned char c = (unsigned char)s[i];
    int n = c < 0x80 ? 0 : (c >> 5) == 6 ? 1 : (c >> 4) == 14 ? 2 : (c >> 3) == 30 ? 3 : -1;
    if (n < 0 || i + (size_t)n >= s.size() + (n ? 0 : 1)) return false;
    for (int k = 1; k <= n; k++)
      if (i + (size_t)k >= s.size() || ((unsigned char)s[i + (size_t)k] >> 6) != 2) return false;
    if (n) any = true;
    i += (size_t)n + 1;
  }
  return true;
}
inline std::string upper(std::string s) {
  for (auto& c : s) c = (char)std::toupper((unsigned char)c);
  return s;
}
inline std::string decode(const std::string& raw, const std::string& charset) {
  std::string cs = upper(trim(charset));
  bool any = false;
  if (cs == "UTF-8" || cs == "UTF8") return raw;
  // Si ya viene en UTF-8 (con acentos), se respeta.
  if (valid_utf8(raw, any) && any) return raw;
  const char* const* t = CP850;
  if (cs == "ANSI" || cs == "1252" || cs == "CP1252" || cs == "WINDOWS-1252") t = CP1252;
  else if (cs == "437") t = CP437;
  std::string o;
  o.reserve(raw.size() + raw.size() / 8);
  for (unsigned char c : raw) {
    if (c < 128) o += (char)c;
    else o += t[c - 128];
  }
  return o;
}

// ---- el presupuesto
enum Kind { K_ROOT, K_CHAPTER, K_UNIT, K_AUX, K_LABOR, K_MACHINE, K_MATERIAL, K_PERCENT, K_WASTE, K_OTHER, K_COUNT };
enum Cat { C_LABOR, C_MACHINE, C_MATERIAL, C_WASTE, C_PCT, C_CI, C_UNDEC, C_OTHER, C_COUNT };

struct Child {
  std::string code;
  double factor = 1, rend = 1;
  bool has_rend = false;
};
struct MLine {
  int type = 0;   // 0 normal, 1 subtotal parcial, 2 subtotal acumulado, 3 fórmula
  std::string comment, f[4];
  double partial = 0;
  bool has = false;
};
struct Measure {
  double total = 0, computed = 0;
  bool has_total = false;
  std::string label;
  std::vector<MLine> lines;
};
struct Concept {
  std::string code, unit, summary, text, type_s;
  double price = 0;
  bool has_price = false, from_c = false;   // from_c: tiene su registro ~C
  int type = 0;
  std::vector<Child> kids;
  std::vector<std::pair<std::string, std::string>> pliego;
};
struct Line {
  std::string code;
  Kind kind = K_OTHER;
  double qty = 0, price = 0, amount = 0;
};

// Fórmulas de las mediciones (tipo 3): + - * / ^, paréntesis y las variables a, b, c y d
// (unidades, longitud, latitud y altura).
struct Expr {
  const char* p;
  const double* v;
  bool ok = true;
  void sp() { while (*p == ' ') p++; }
  double atom() {
    sp();
    if (*p == '(') {
      p++;
      double r = sum();
      sp();
      if (*p == ')') p++;
      else ok = false;
      return r;
    }
    if (*p == '-') { p++; return -atom(); }
    if (*p == '+') { p++; return atom(); }
    char c = (char)std::tolower((unsigned char)*p);
    if (c >= 'a' && c <= 'd') { p++; return v[c - 'a']; }
    if ((*p >= '0' && *p <= '9') || *p == '.' || *p == ',') {
      std::string n;
      while ((*p >= '0' && *p <= '9') || *p == '.' || *p == ',') n += *p++;
      double r = 0;
      if (!num(n, r)) ok = false;
      return r;
    }
    ok = false;
    return 0;
  }
  double power() {
    double b = atom();
    sp();
    if (*p == '^') { p++; return std::pow(b, power()); }
    return b;
  }
  double prod() {
    double r = power();
    for (;;) {
      sp();
      if (*p == '*') { p++; r *= power(); }
      else if (*p == '/') { p++; double d = power(); if (d == 0) ok = false; else r /= d; }
      else return r;
    }
  }
  double sum() {
    double r = prod();
    for (;;) {
      sp();
      if (*p == '+') { p++; r += prod(); }
      else if (*p == '-') { p++; r -= prod(); }
      else return r;
    }
  }
};
inline bool eval(const std::string& e, const double v[4], double& out) {
  Expr x{e.c_str(), v};
  out = x.sum();
  x.sp();
  return x.ok && *x.p == 0;
}
inline void compute(Measure& m) {
  double total = 0, since = 0;
  for (auto& l : m.lines) {
    double v[4] = {0, 0, 0, 0};
    bool present[4];
    for (int k = 0; k < 4; k++) present[k] = num(l.f[k], v[k]);
    l.has = false;
    if (l.type == 1) { l.partial = since; l.has = true; since = 0; continue; }
    if (l.type == 2) { l.partial = total; l.has = true; continue; }
    if (l.type == 3) {
      double r;
      if (eval(l.comment, v, r)) { l.partial = r; l.has = true; }
    } else {
      double r = 1;
      for (int k = 0; k < 4; k++)
        if (present[k]) { r *= v[k]; l.has = true; }
      l.partial = l.has ? r : 0;
    }
    if (l.has) { total += l.partial; since += l.partial; }
  }
  m.computed = total;
}

struct Budget {
  std::string file, owner, version, date, program, charset, comment, currency = "EUR";
  double ci = 0, gg = 0, bi = 0, iva = 0;
  bool ci_mode = false;   // el CI del ~K se suma al precio de cada partida (cuadra con el archivo)
  std::map<std::string, Concept> c;
  std::map<std::string, Measure> m;   // «CAPÍTULO\PARTIDA» o «\PARTIDA»
  std::map<std::string, std::string> sections;   // títulos del pliego (~L sin código)
  std::vector<std::string> order;
  std::string root;
  int records = 0;
  mutable std::map<std::string, double> memo_unit, memo_total;
  mutable std::set<std::string> busy;
  mutable bool cycle = false;

  const Concept* get(const std::string& code) const {
    auto it = c.find(code);
    return it == c.end() ? nullptr : &it->second;
  }
  Concept& add(const std::string& code) {
    auto it = c.find(code);
    if (it != c.end()) return it->second;
    order.push_back(code);
    Concept& x = c[code];
    x.code = code;
    return x;
  }
  static bool chapterish(const std::string& code) { return ends_with(code, "#"); }
  Kind kind_of(const std::string& code, Kind parent) const {
    if (ends_with(code, "##")) return K_ROOT;
    if (ends_with(code, "#")) return K_CHAPTER;
    const Concept* x = get(code);
    if (code.find('%') != std::string::npos || (x && x->unit == "%")) return K_PERCENT;
    if (parent == K_ROOT || parent == K_CHAPTER) return K_UNIT;
    if (x && !x->kids.empty()) return K_AUX;
    switch (x ? x->type : 0) {
      case 1: return K_LABOR;
      case 2: return K_MACHINE;
      case 3: return K_MATERIAL;
      case 4: case 5: return K_WASTE;
      default: return K_OTHER;
    }
  }
  Kind kind_in(const std::string& code, const std::string& parent) const {
    if (parent.empty()) return code == root ? K_ROOT : kind_of(code, K_OTHER);
    return kind_of(code, chapterish(parent) ? K_CHAPTER : K_UNIT);
  }
  const Measure* measure(const std::string& parent, const std::string& code) const {
    auto it = m.find(parent + "\\" + code);
    if (it == m.end()) it = m.find("\\" + code);
    return it == m.end() ? nullptr : &it->second;
  }
  void clear_memo() const {
    memo_unit.clear();
    memo_total.clear();
  }

  // Las líneas de la descomposición, con sus importes redondeados al céntimo.
  std::vector<Line> lines(const std::string& code) const {
    std::vector<Line> out;
    const Concept* x = get(code);
    if (!x || x->kids.empty()) return out;
    if (busy.count(code)) { cycle = true; return out; }
    busy.insert(code);
    bool chap = chapterish(code);
    for (auto& k : x->kids) {
      Line l;
      l.code = k.code;
      l.kind = kind_of(k.code, chap ? K_CHAPTER : K_UNIT);
      double q = k.factor * k.rend;
      if (!k.has_rend) {
        if (const Measure* me = measure(code, k.code)) q = k.factor * (me->has_total ? me->total : me->computed);
      }
      l.qty = q;
      if (l.kind == K_PERCENT) {
        // El código antes del % es la máscara: se aplica a las líneas anteriores que empiezan así.
        std::string mask = k.code.substr(0, k.code.find('%'));
        double base = 0;
        for (auto& p : out)
          if (p.code.compare(0, mask.size(), mask) == 0) base += p.amount;
        l.price = base;
        l.amount = round2(base * q);
      } else if (l.kind == K_CHAPTER || l.kind == K_ROOT) {
        l.price = total(k.code);
        l.amount = round2(l.price * q);
      } else {
        double p = unit(k.code);
        if (chap && ci_mode && ci > 0) p = round2(p * (1 + ci / 100));
        l.price = p;
        l.amount = round2(p * q);
      }
      out.push_back(l);
    }
    busy.erase(code);
    return out;
  }
  double sum(const std::string& code) const {
    double s = 0;
    for (auto& l : lines(code)) s += l.amount;
    return round2(s);
  }
  // Precio unitario: el del archivo; si no lo trae, el de su descomposición.
  double unit(const std::string& code) const {
    auto it = memo_unit.find(code);
    if (it != memo_unit.end()) return it->second;
    const Concept* x = get(code);
    double v = 0;
    if (x) {
      if (chapterish(code)) v = total(code);
      else if (x->has_price) v = x->price;
      else if (!x->kids.empty()) v = sum(code);
    }
    memo_unit[code] = v;
    return v;
  }
  // Importe de un capítulo (o del presupuesto): siempre calculado.
  double total(const std::string& code) const {
    auto it = memo_total.find(code);
    if (it != memo_total.end()) return it->second;
    double v = sum(code);
    memo_total[code] = v;
    return v;
  }

  // ¿En qué se va el dinero? Mano de obra, maquinaria, materiales…
  void explode(const std::string& code, double mult, double* acc, int depth) const {
    auto ls = lines(code);
    if (ls.empty() || depth > 30) { acc[C_UNDEC] += mult * unit(code); return; }
    for (auto& l : ls) {
      const Concept* x = get(l.code);
      if (l.kind == K_PERCENT) acc[C_PCT] += mult * l.amount;
      else if (x && !x->kids.empty()) explode(l.code, mult * l.qty, acc, depth + 1);
      else if (l.kind == K_LABOR) acc[C_LABOR] += mult * l.amount;
      else if (l.kind == K_MACHINE) acc[C_MACHINE] += mult * l.amount;
      else if (l.kind == K_MATERIAL) acc[C_MATERIAL] += mult * l.amount;
      else if (l.kind == K_WASTE) acc[C_WASTE] += mult * l.amount;
      else acc[C_OTHER] += mult * l.amount;
    }
  }
  void breakdown(const std::string& code, double mult, double* acc, std::map<std::string, double>& items, int depth = 0) const {
    if (depth > 30) return;
    for (auto& l : lines(code)) {
      if (l.kind == K_CHAPTER || l.kind == K_ROOT) { breakdown(l.code, mult * l.qty, acc, items, depth + 1); continue; }
      double q = mult * l.qty;
      if (l.kind == K_PERCENT) { acc[C_PCT] += mult * l.amount; continue; }
      items[l.code] += mult * l.amount;
      explode(l.code, q, acc, 0);
      acc[C_CI] += q * (l.price - unit(l.code));
    }
  }
  // Capítulos y partidas que cuelgan del presupuesto (cada código una vez).
  void count(const std::string& code, std::set<std::string>& ch, std::set<std::string>& it, int depth = 0) const {
    if (depth > 30) return;
    const Concept* x = get(code);
    if (!x) return;
    for (auto& k : x->kids) {
      if (chapterish(k.code)) {
        if (ch.insert(k.code).second) count(k.code, ch, it, depth + 1);
      } else if (kind_of(k.code, K_CHAPTER) != K_PERCENT) {
        it.insert(k.code);
      }
    }
  }
};

inline std::string first_sub(const std::string& f) {
  size_t p = f.find('\\');
  return trim(p == std::string::npos ? f : f.substr(0, p));
}

// Lee un archivo FIEBDC-3 (.bc3) ya cargado en memoria.
inline bool parse(const std::string& raw, Budget& b, std::string& err) {
  std::string cs;
  size_t v = raw.find("~V|");
  if (v != std::string::npos) {
    size_t e = raw.find('~', v + 1);
    auto f = split(raw.substr(v, e == std::string::npos ? std::string::npos : e - v), '|');
    if (f.size() > 5) cs = trim(f[5]);
  }
  std::string s = decode(raw, cs);
  b = Budget();
  b.charset = cs.empty() ? "850" : cs;
  size_t i = s.find('~');
  while (i != std::string::npos) {
    size_t j = s.find('~', i + 1);
    std::string rec = s.substr(i + 1, j == std::string::npos ? std::string::npos : j - i - 1);
    i = j;
    size_t bar = rec.find('|');
    if (bar == std::string::npos) continue;
    std::string type = upper(trim(rec.substr(0, bar)));
    bool text = type == "T" || type == "L";
    std::string clean;
    for (char ch : rec)
      if (ch != '\r' && ch != '\x1a' && (text || ch != '\n')) clean += ch;
    auto f = split(clean, '|');
    for (auto& x : f) x = trim(x);
    auto at = [&](size_t k) { return k < f.size() ? f[k] : std::string(); };
    b.records++;
    if (type == "V") {
      b.owner = at(1);
      auto vd = split(at(2), '\\');
      b.version = trim(vd[0]);
      if (vd.size() > 1) b.date = trim(vd[1]);
      b.program = at(3);
      if (!at(5).empty()) b.charset = at(5);
      b.comment = at(6);
    } else if (type == "K") {
      auto p = split(at(2), '\\');
      double* dst[5] = {&b.ci, &b.gg, &b.bi, nullptr, &b.iva};
      for (size_t k = 0; k < p.size() && k < 5; k++)
        if (dst[k]) num(p[k], *dst[k]);
      for (size_t fi : {1, 3})
        for (auto& tok : split(at(fi), '\\')) {
          std::string t2 = trim(tok);
          if (t2.size() == 3 && std::isalpha((unsigned char)t2[0])) b.currency = upper(t2);
        }
    } else if (type == "C") {
      std::string code = first_sub(at(1));
      if (code.empty()) continue;
      Concept& x = b.add(code);
      x.from_c = true;
      x.unit = at(2);
      x.summary = at(3);
      double pr;
      if (num(first_sub(at(4)), pr)) { x.price = pr; x.has_price = true; }
      x.type_s = at(6);
      double t;
      x.type = num(x.type_s, t) ? (int)t : 0;
      if (b.root.empty() && ends_with(code, "##")) b.root = code;
    } else if (type == "D" || type == "Y") {
      std::string parent = first_sub(at(1));
      if (parent.empty()) continue;
      Concept& x = b.add(parent);
      if (type == "D") x.kids.clear();
      std::string list = at(2);
      size_t step = 3;
      if (list.empty() && !at(3).empty()) { list = at(3); step = 4; }
      auto p = split(list, '\\');
      for (size_t k = 0; k < p.size(); k += step) {
        Child ch;
        ch.code = trim(p[k]);
        if (ch.code.empty()) continue;
        double val;
        if (k + 1 < p.size() && num(p[k + 1], val)) ch.factor = val;
        if (k + 2 < p.size() && num(p[k + 2], val)) { ch.rend = val; ch.has_rend = true; }
        x.kids.push_back(ch);
      }
    } else if (type == "T") {
      std::string code = first_sub(at(1));
      if (!code.empty()) b.add(code).text = at(2);
    } else if (type == "M") {
      auto key = split(at(1), '\\');
      std::string parent = key.size() > 1 ? trim(key[0]) : "", code = trim(key.size() > 1 ? key[1] : key[0]);
      if (code.empty()) continue;
      Measure me;
      me.has_total = num(at(3), me.total);
      me.label = at(5);
      auto p = split(at(4), '\\');
      for (size_t k = 0; k + 5 < p.size(); k += 6) {
        MLine l;
        double t;
        l.type = num(p[k], t) ? (int)t : 0;
        l.comment = trim(p[k + 1]);
        for (int q = 0; q < 4; q++) l.f[q] = trim(p[k + 2 + (size_t)q]);
        me.lines.push_back(l);
      }
      compute(me);
      b.m[parent + "\\" + code] = me;
    } else if (type == "L") {
      std::string code = first_sub(at(1));
      auto p = split(at(2), '\\');
      for (size_t k = 0; k + 1 < p.size(); k += 2) {
        std::string a = trim(p[k]), t = trim(p[k + 1]);
        if (a.empty()) continue;
        if (code.empty()) b.sections[a] = t;
        else b.add(code).pliego.push_back({a, t});
      }
    }
  }
  if (b.c.empty()) { err = tx::ERR_EMPTY; return false; }
  // En las referencias se puede omitir el # de los capítulos: «C01» es «C01#».
  auto base = [](std::string k) { while (!k.empty() && k.back() == '#') k.pop_back(); return k; };
  std::map<std::string, std::string> alias;
  for (auto& code : b.order)
    if (ends_with(code, "#") || !alias.count(base(code))) alias[base(code)] = code;
  auto resolve = [&](const std::string& k) {
    if (k.empty()) return k;
    auto it = alias.find(base(k));
    auto own = b.c.find(k);
    if (it != alias.end() && (own == b.c.end() || !own->second.from_c)) return it->second;
    return k;
  };
  for (auto& code : std::vector<std::string>(b.order)) {
    std::string to = resolve(code);
    if (to == code || !b.c.count(to) || b.c[code].from_c) continue;
    Concept from = b.c[code];
    Concept& t = b.c[to];
    if (t.kids.empty()) t.kids = from.kids;
    if (t.text.empty()) t.text = from.text;
    if (!t.has_price && from.has_price) { t.price = from.price; t.has_price = true; }
    if (t.summary.empty()) t.summary = from.summary;
    b.c.erase(code);
    b.order.erase(std::find(b.order.begin(), b.order.end(), code));
  }
  for (auto& [k, x] : b.c)
    for (auto& ch : x.kids) ch.code = resolve(ch.code);
  std::map<std::string, Measure> ms;
  for (auto& [k, me] : b.m) {
    size_t sl = k.find('\\');
    ms[resolve(k.substr(0, sl)) + "\\" + resolve(k.substr(sl + 1))] = me;
  }
  b.m = ms;
  if (!b.root.empty()) b.root = resolve(b.root);
  // Sin raíz ##: el concepto con hijos del que nadie cuelga.
  if (b.root.empty()) {
    std::set<std::string> kids;
    for (auto& [k, x] : b.c)
      for (auto& ch : x.kids) kids.insert(ch.code);
    for (auto& code : b.order)
      if (!b.c[code].kids.empty() && !kids.count(code)) { b.root = code; break; }
    if (b.root.empty()) b.root = b.order.front();
  }
  // El CI del ~K: ¿va dentro de los precios de las partidas? Se elige lo que cuadra con el archivo.
  const Concept* r = b.get(b.root);
  if (b.ci > 0 && r && r->has_price) {
    b.ci_mode = false;
    b.clear_memo();
    double without = b.total(b.root);
    b.ci_mode = true;
    b.clear_memo();
    double with = b.total(b.root);
    b.ci_mode = std::fabs(with - r->price) < std::fabs(without - r->price);
  }
  b.clear_memo();
  return true;
}

inline bool read_file(const std::string& path, std::string& out) {
  std::ifstream in(path, std::ios::binary);
  if (!in) return false;
  std::ostringstream ss;
  ss << in.rdbuf();
  out = ss.str();
  return true;
}
inline bool write_file(const std::string& path, const std::string& data) {
  std::ofstream out(path, std::ios::binary);
  if (!out) return false;
  out << data;
  return (bool)out;
}

// ---- exportar: capítulos y partidas en CSV (separado por ;)
inline std::string csv_cell(const std::string& s) {
  if (s.find_first_of(";\"\n") == std::string::npos) return s;
  std::string o = "\"";
  for (char c : s) o += c == '"' ? std::string("\"\"") : std::string(1, c);
  return o + "\"";
}
inline const char* kind_name(Kind k) {
  static const char* const n[K_COUNT] = {tx::KN_ROOT, tx::KN_CHAPTER, tx::KN_UNIT, tx::KN_AUX, tx::KN_LABOR, tx::KN_MACHINE, tx::KN_MATERIAL, tx::KN_PERCENT, tx::KN_WASTE, tx::KN_OTHER};
  return n[k];
}
inline void csv_rows(const Budget& b, const std::string& code, int level, std::string& out, int depth = 0) {
  if (depth > 30) return;
  for (auto& l : b.lines(code)) {
    const Concept* x = b.get(l.code);
    out += std::to_string(level) + ";" + csv_cell(l.code) + ";" + csv_cell(kind_name(l.kind)) + ";" + csv_cell(x ? x->unit : "") + ";" +
           csv_cell(x ? x->summary : "") + ";" + number(l.kind == K_PERCENT ? l.qty * 100 : l.qty, 3, false) + ";" +
           number(l.price, 2, false) + ";" + number(l.amount, 2, false) + "\n";
    if (l.kind == K_CHAPTER) csv_rows(b, l.code, level + 1, out, depth + 1);
  }
}
inline std::string to_csv(const Budget& b) {
  std::string out = "\xEF\xBB\xBF";   // BOM: Excel lo abre con los acentos bien
  out += std::string(tx::CSV_LEVEL) + ";" + tx::COL_CODE + ";" + tx::COL_KIND + ";" + tx::COL_UNIT + ";" + tx::COL_SUMMARY + ";" + tx::COL_QTY + ";" + tx::COL_PRICE + ";" + tx::COL_AMOUNT + "\n";
  const Concept* r = b.get(b.root);
  out += "0;" + csv_cell(b.root) + ";" + csv_cell(tx::KN_ROOT) + ";;" + csv_cell(r ? r->summary : "") + ";1;" + number(b.total(b.root), 2, false) + ";" + number(b.total(b.root), 2, false) + "\n";
  csv_rows(b, b.root, 1, out);
  return out;
}

// ---- buscar: todos los caminos del árbol, en orden (sin ciclos)
struct PathNode {
  int parent;
  std::string code;
};
inline void walk(const Budget& b, std::vector<PathNode>& out, int parent, const std::string& code, std::vector<std::string>& stack) {
  if (out.size() > 60000 || std::find(stack.begin(), stack.end(), code) != stack.end()) return;
  out.push_back({parent, code});
  int me = (int)out.size() - 1;
  const Concept* x = b.get(code);
  if (!x) return;
  stack.push_back(code);
  for (auto& k : x->kids) walk(b, out, me, k.code, stack);
  stack.pop_back();
}
inline std::vector<std::string> path_of(const std::vector<PathNode>& nodes, int i) {
  std::vector<std::string> p;
  for (; i >= 0; i = nodes[(size_t)i].parent) p.insert(p.begin(), nodes[(size_t)i].code);
  return p;
}
// Los nodos cuyo código o resumen contienen el texto (sin mayúsculas ni acentos).
inline std::vector<int> find(const Budget& b, const std::vector<PathNode>& nodes, const std::string& q) {
  std::vector<int> hits;
  std::string fq = fold(trim(q));
  if (fq.empty()) return hits;
  for (size_t i = 0; i < nodes.size(); i++) {
    const Concept* x = b.get(nodes[i].code);
    if (fold(nodes[i].code).find(fq) != std::string::npos || (x && fold(x->summary).find(fq) != std::string::npos)) hits.push_back((int)i);
  }
  return hits;
}

// ---- el ejemplo: una reforma de vivienda con capítulos, partidas, auxiliares, porcentajes y mediciones
const char* const SAMPLE = R"BC3(~V|DMarlon Studio|FIEBDC-3/2016\14112026|Visor BC3|Reforma de vivienda\|UTF-8|Presupuesto de ejemplo del visor BC3 de DMarlon Studio|1||||
~K|\2\2\3\2\2\2\2\EUR\|0\13\6\\21\|
~C|REF24##||Reforma integral de vivienda en la calle Mayor, 12|6646.70|141126|0|
~D|REF24##|01#\1\1\02#\1\1\03#\1\1\04#\1\1\05#\1\1\06#\1\1\|
~T|REF24##|Reforma integral de una vivienda de 85 m²: nueva distribución del baño y la cocina, revestimientos, pavimentos e instalaciones de fontanería y electricidad.|
~C|01#||Demoliciones|347.04|141126|0|
~D|01#|DEM010\1\17.445\DEM020\1\17.94\DEM030\1\3\|
~C|02#||Albañilería|1049.51|141126|0|
~D|02#|ALB010\1\15.94\ALB020\1\21.19\ALB030\1\1\|
~C|03#||Revestimientos y pavimentos|2773.97|141126|0|
~D|03#|REV010\1\45.48\REV020\1\20.64\PAV010\1\36.66\PAV020\1\28.7\|
~C|04#||Instalaciones|1818.53|141126|0|
~D|04#|04.1#\1\1\04.2#\1\1\|
~C|04.1#||Fontanería|500.90|141126|0|
~D|04.1#|FON010\1\1\FON020\1\1\|
~C|04.2#||Electricidad|1317.63|141126|0|
~D|04.2#|ELE010\1\7\ELE020\1\19\ELE030\1\1\|
~C|05#||Gestión de residuos|237.65|141126|0|
~D|05#|RES010\1\6.5\RES020\1\9.75\|
~C|06#||Seguridad y salud|420.00|141126|0|
~D|06#|SYS010\1\1\|
~C|DEM010|m²|Demolición de tabique de ladrillo hueco con medios manuales|8.31|141126|0|
~D|DEM010|O01OA070\1\0.42\M11HV120\1\0.18\%MA\1\0.02\|
~T|DEM010|Demolición de tabique de ladrillo hueco de hasta 10 cm de espesor, con medios manuales y martillo eléctrico, incluso limpieza y acopio de escombros a pie de carga. Medida la superficie realmente demolida, deduciendo huecos mayores de 2 m².|
~C|DEM020|m²|Levantado de pavimento cerámico y rodapié|7.22|141126|0|
~D|DEM020|O01OA070\1\0.35\M11HV120\1\0.25\%MA\1\0.02\|
~T|DEM020|Levantado de pavimento cerámico, rodapié y capa de mortero de agarre, con medios manuales y mecánicos, incluso retirada de escombros.|
~C|DEM030|ud|Desmontaje de aparatos sanitarios|24.18|141126|0|
~D|DEM030|O01OB170\1\0.6\O01OA070\1\0.6\|
~T|DEM030|Desmontaje de inodoro, lavabo o bañera con recuperación de griferías, taponado de las tomas y retirada.|
~C|ALB010|m²|Tabique de ladrillo hueco doble de 8 cm|18.43|141126|0|
~D|ALB010|O01OA030\1\0.44\O01OA070\1\0.22\P01LH020\1\0.034\A02A080\1\0.012\O01%HM\1\0.03\%MA\1\0.015\|
~T|ALB010|Tabique de ladrillo cerámico hueco doble de 24x11,5x8 cm, recibido con mortero de cemento M-7,5, incluso replanteo, nivelación, aplomado, mermas y roturas. Medido deduciendo huecos mayores de 2 m².|
~C|ALB020|m²|Trasdosado autoportante de placa de yeso laminado|23.90|141126|0|
~D|ALB020|O01OA030\1\0.32\O01OA050\1\0.32\P04PY032\1\1.05\P04PW080\1\2.1\O01%HM\1\0.03\|
~T|ALB020|Trasdosado autoportante con una placa de yeso laminado de 15 mm atornillada a perfilería de acero galvanizado de 48 mm, con juntas tratadas, listo para pintar.|
~C|ALB030|ud|Ayudas de albañilería a instalaciones|249.30|141126|0|
~D|ALB030|O01OA030\1\6\O01OA070\1\6\A02A080\1\0.05\%MA\1\0.03\|
~T|ALB030|Ayudas de albañilería a las instalaciones de fontanería y electricidad: rozas, pasos y recibido de cajas.|
~C|REV010|m²|Guarnecido y enlucido de yeso en paramentos verticales|9.01|141126|0|
~D|REV010|O01OA030\1\0.25\O01OA070\1\0.13\P04RR070\1\11.5\P01DW050\1\0.006\|
~T|REV010|Guarnecido maestreado y enlucido de yeso de 15 mm de espesor en paredes, incluso guardavivos.|
~C|REV020|m²|Alicatado con azulejo cerámico 20x40 cm|32.53|141126|0|
~D|REV020|O01OA030\1\0.48\O01OA070\1\0.24\P09ABC010\1\1.05\P01FA405\1\4.5\%MA\1\0.02\|
~T|REV020|Alicatado con azulejo cerámico blanco de 20x40 cm, recibido con adhesivo cementoso C2 TE, incluso cortes, juntas y limpieza.|
~C|PAV010|m²|Pavimento de gres porcelánico 60x60 cm|40.10|141126|0|
~D|PAV010|O01OA030\1\0.38\O01OA070\1\0.19\P08EPP010\1\1.05\P01FA405\1\5\O01%HM\1\0.03\|
~T|PAV010|Solado de gres porcelánico rectificado de 60x60 cm, recibido con adhesivo cementoso C2 TE sobre la base existente, incluso rejuntado y limpieza.|
~C|PAV020|m|Rodapié de gres porcelánico de 8 cm|7.76|141126|0|
~D|PAV020|O01OA030\1\0.12\P08EPP020\1\1.05\P01FA405\1\0.6\|
~T|PAV020|Rodapié de gres porcelánico de 8 cm de altura, recibido con adhesivo.|
~C|FON010|ud|Instalación de fontanería de baño completo|272.12|141126|0|
~D|FON010|O01OB170\1\9.5\P17XT030\1\22\%MA\1\0.04\|
~T|FON010|Instalación interior de fontanería de baño con tubería multicapa para agua fría y caliente, desde la llave de paso hasta los aparatos.|
~C|FON020|ud|Plato de ducha de resina 80x120 cm|228.78|141126|0|
~D|FON020|O01OB170\1\1.8\P17SD010\1\1\|
~T|FON020|Plato de ducha de resina extraplano de 80x120 cm, con válvula, colocado y sellado.|
~C|ELE010|ud|Punto de luz sencillo|36.83|141126|0|
~D|ELE010|O01OB200\1\0.45\O01OB220\1\0.45\P15GA010\1\18\P15GK050\1\7\P15MSA010\1\1\|
~T|ELE010|Punto de luz sencillo con conductor de cobre H07V-K de 2,5 mm² bajo tubo corrugado e interruptor.|
~C|ELE020|ud|Toma de corriente de 16 A|37.18|141126|0|
~D|ELE020|O01OB200\1\0.4\O01OB220\1\0.4\P15GA010\1\21\P15GK050\1\7\P15MSC020\1\1\|
~T|ELE020|Toma de corriente de 16 A con toma de tierra, conductor de 2,5 mm² y mecanismo.|
~C|ELE030|ud|Cuadro general de mando y protección|353.40|141126|0|
~D|ELE030|O01OB200\1\4\P15CA010\1\1\|
~T|ELE030|Cuadro general de mando y protección con interruptor general, diferenciales y 8 circuitos.|
~C|RES010|m³|Carga y transporte de escombros en contenedor|14.81|141126|0|
~D|RES010|O01OA070\1\0.3\M07AC020\1\0.55\M07CB010\1\0.08\|
~T|RES010|Carga manual de escombros en contenedor de 6 m³ y transporte a planta de tratamiento autorizada.|
~C|RES020|t|Canon de vertido de residuos mixtos|14.50|141126|0|
~D|RES020|GR010\1\1\|
~T|RES020|Canon de entrega de residuos mixtos de construcción y demolición en gestor autorizado.|
~C|SYS010|ud|Seguridad y salud en la obra|420.00|141126|0|
~T|SYS010|Protecciones colectivas e individuales, señalización y medios de seguridad y salud según el estudio básico.|
~C|A02A080|m³|Mortero de cemento M-7,5 hecho en obra|82.75|141126|0|
~D|A02A080|O01OA070\1\1.7\P01CC020\1\0.27\P01AA020\1\1.09\P01DW050\1\0.26\|
~T|A02A080|Mortero de cemento CEM II/B-L 32,5 N y arena de río, tipo M-7,5, confeccionado en obra con hormigonera.|
~C|%MA|%|Medios auxiliares|1|141126|0|
~C|O01%HM|%|Herramientas y pequeño material (sobre la mano de obra)|1|141126|0|
~C|O01OA030|h|Oficial 1ª construcción|21.45|141126|1|
~C|O01OA050|h|Ayudante construcción|19.80|141126|1|
~C|O01OA070|h|Peón ordinario construcción|18.20|141126|1|
~C|O01OB170|h|Oficial 1ª fontanero|22.10|141126|1|
~C|O01OB200|h|Oficial 1ª electricista|22.10|141126|1|
~C|O01OB220|h|Ayudante electricista|19.90|141126|1|
~C|M11HV120|h|Martillo eléctrico demoledor|2.85|141126|2|
~C|M07CB010|h|Camión basculante 4x2 de 10 t|38.50|141126|2|
~C|M07AC020|h|Contenedor de escombros 6 m³ (alquiler y recogida)|11.40|141126|2|
~C|P01CC020|t|Cemento CEM II/B-L 32,5 N en sacos|112.00|141126|3|
~C|P01AA020|m³|Arena de río 0/6 mm|19.50|141126|3|
~C|P01DW050|m³|Agua|1.20|141126|3|
~C|P01LH020|mu|Ladrillo hueco doble 24x11,5x8 cm|98.00|141126|3|
~C|P04PY032|m²|Placa de yeso laminado 15 mm|5.90|141126|3|
~C|P04PW080|m|Perfil de acero galvanizado 48 mm|1.95|141126|3|
~C|P04RR070|kg|Yeso de construcción B1|0.11|141126|3|
~C|P09ABC010|m²|Azulejo cerámico blanco 20x40 cm|14.60|141126|3|
~C|P08EPP010|m²|Gres porcelánico rectificado 60x60 cm|24.80|141126|3|
~C|P01FA405|kg|Adhesivo cementoso C2 TE|0.42|141126|3|
~C|P08EPP020|m|Rodapié de gres porcelánico 8 cm|4.70|141126|3|
~C|P17SD010|ud|Plato de ducha de resina 80x120 cm|189.00|141126|3|
~C|P17XT030|m|Tubería multicapa 16 mm|2.35|141126|3|
~C|P15GA010|m|Conductor H07V-K 2,5 mm²|0.52|141126|3|
~C|P15MSC020|ud|Mecanismo de toma de corriente|6.80|141126|3|
~C|P15MSA010|ud|Mecanismo de interruptor|5.90|141126|3|
~C|P15CA010|ud|Cuadro general con 8 circuitos|265.00|141126|3|
~C|P15GK050|m|Tubo corrugado 20 mm|0.38|141126|3|
~C|GR010|t|Canon de vertido de residuos mixtos|14.50|141126|5|
~M|01#\DEM010|1\|17.445|\Cocina - baño\1\3.1\\2.6\\Dormitorio 2\1\4.25\\2.6\\A deducir puerta\-1\0.82\\2.03\|
~M|01#\DEM020|1\|17.94|\Cocina\1\3.2\2.85\\\Baño\1\2.1\1.9\\\Pasillo\1\4.6\1.05\\|
~M|01#\DEM030|1\|3|\Inodoro, lavabo y bañera\3\\\\|
~M|02#\ALB010|1\|15.94|\Nueva distribución baño\1\2.4\\2.6\\Cierre de cocina\1\3.05\\2.6\1\Subtotal tabiques\\\\\3\A*B*D-2\1\1.45\\2.6\|
~M|02#\ALB020|1\|21.19|\Fachada salón\1\4.8\\2.6\\Fachada dormitorio 1\1\3.35\\2.6\|
~M|02#\ALB030|1\|1|\Vivienda\1\\\\|
~M|03#\REV010|1\|45.48|\Salón\2\4.8\\2.6\\Dormitorios\2\3.35\\2.6\\Cocina (zona sin alicatar)\1\3.1\\1\|
~M|03#\REV020|1\|20.64|\Baño\1\7.8\\2.4\\Cocina frente\1\3.2\\0.6\|
~M|03#\PAV010|1\|36.66|\Salón\1\4.8\3.9\\\Cocina\1\3.2\2.85\\\Baño\1\2.1\1.9\\\Pasillo\1\4.6\1.05\\|
~M|03#\PAV020|1\|28.7|\Salón\1\17.4\\\\Pasillo\1\11.3\\\|
~M|04.1#\FON010|1\|1|\Baño\1\\\\|
~M|04.1#\FON020|1\|1|\Baño\1\\\\|
~M|04.2#\ELE010|1\|7|\Salón\2\\\\\Dormitorios\2\\\\\Cocina y baño\3\\\\|
~M|04.2#\ELE020|1\|19|\Salón\5\\\\\Dormitorios\6\\\\\Cocina\6\\\\\Baño\2\\\\|
~M|04.2#\ELE030|1\|1|\Vivienda\1\\\\|
~M|05#\RES010|1\|6.5|\Escombros de demolición\1\6.5\\\|
~M|05#\RES020|1\|9.75|\Densidad 1,5 t/m³\1\6.5\1.5\\|
~M|06#\SYS010|1\|1|\Obra\1\\\\|
~L||DES\Descripción\EJE\Ejecución\MED\Medición y abono\|
~L|ALB010|EJE\Se replantea la distribución, se humedecen las piezas y se colocan a rompejuntas, aplomadas y niveladas.\MED\Se mide la superficie ejecutada deduciendo los huecos mayores de 2 m².\|
)BC3";

// ---- pruebas internas (DMS_BC3_SELFTEST=1), sin ventana
inline int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const std::string& what) {
    if (!ok) { std::printf("FAIL %s\n", what.c_str()); f++; }
  };
  auto near = [](double a, double b) { return std::fabs(a - b) < 0.005; };
  std::string err;
  // El ejemplo: totales calculados = los que trae el archivo.
  Budget b;
  chk(parse(SAMPLE, b, err), "ejemplo: " + err);
  chk(b.root == "REF24##", "raíz del ejemplo");
  chk(near(b.total(b.root), 6646.70), "total del ejemplo " + std::to_string(b.total(b.root)));
  chk(near(b.total("02#"), 1049.51) && near(b.total("04#"), 1818.53) && near(b.total("04.2#"), 1317.63), "capítulos y subcapítulos");
  chk(near(b.sum("ALB010"), 18.43) && near(b.unit("ALB010"), 18.43), "partida con auxiliar y porcentajes");
  chk(near(b.sum("A02A080"), 82.75), "auxiliar");
  const Measure* me = b.measure("02#", "ALB010");
  chk(me && me->lines.size() == 4 && near(me->computed, 15.94) && me->lines[2].type == 1 && near(me->lines[2].partial, 14.17), "medición con subtotal y fórmula");
  chk(me && me->lines[3].type == 3 && near(me->lines[3].partial, 1.77), "fórmula A*B*D-2");
  auto ls = b.lines("ALB010");
  chk(ls.size() == 6 && ls[4].kind == K_PERCENT && ls[5].kind == K_PERCENT, "líneas de porcentaje");
  double mo = ls.size() == 6 ? ls[0].amount + ls[1].amount : 0;
  chk(ls.size() == 6 && near(ls[4].price, mo), "base de O01%HM");
  chk(b.kind_in("02#", b.root) == K_CHAPTER && b.kind_in("ALB010", "02#") == K_UNIT && b.kind_in("A02A080", "ALB010") == K_AUX && b.kind_in("O01OA030", "ALB010") == K_LABOR && b.kind_in("P01LH020", "ALB010") == K_MATERIAL && b.kind_in("M11HV120", "DEM010") == K_MACHINE && b.kind_in("GR010", "RES020") == K_WASTE, "tipos");
  chk(!b.ci_mode && b.charset == "UTF-8" && b.version == "FIEBDC-3/2016", "cabecera");
  chk(b.get("ALB010")->pliego.size() == 2 && b.sections["EJE"] == "Ejecución", "pliego");
  double acc[C_COUNT] = {0};
  std::map<std::string, double> items;
  b.breakdown(b.root, 1, acc, items);
  double s = 0;
  for (double v : acc) s += v;
  chk(std::fabs(s - b.total(b.root)) < 1.0, "el desglose suma el total " + std::to_string(s));
  chk(acc[C_LABOR] > 0 && acc[C_MATERIAL] > 0 && acc[C_MACHINE] > 0 && near(acc[C_UNDEC], 420), "desglose por naturaleza");
  std::set<std::string> ch, it;
  b.count(b.root, ch, it);
  chk(ch.size() == 8 && it.size() == 18, "capítulos y partidas: " + std::to_string(ch.size()) + " " + std::to_string(it.size()));
  std::vector<PathNode> nodes;
  std::vector<std::string> st;
  walk(b, nodes, -1, b.root, st);
  auto hits = find(b, nodes, "TABIQUE");
  chk(!hits.empty() && path_of(nodes, hits[0]).size() == 3, "buscar «tabique»");
  chk(!find(b, nodes, "demolicion").empty(), "buscar sin acentos");
  std::string csv = to_csv(b);
  chk(csv.find("02#") != std::string::npos && csv.find("ALB010") != std::string::npos && csv.find("O01OA030") == std::string::npos, "CSV con capítulos y partidas");

  // El CI del ~K dentro de los precios (como hacen varios programas), máscara MO% y sinónimos.
  Budget c;
  chk(parse(R"(~V|x|FIEBDC-3/2024\01012026|prueba||ANSI|ci|1||||
~K|2\2\2\2\2\2\2\2\EUR\|5\13\6\0\21|
~C|T01##\||Prueba|953.40\|01012026\|OB|
~D|T01##|C01#\\1\|
~C|C01#\||Movimiento de tierras|953.40\|01012026\||
~D|C01#|UO01\1\10\|
~C|UO01\|m3|Excavacion|90.80\|01012026\|EU|
~D|UO01|MO01\1\2\MT01\1\1\MO%AUX\1\0.02\|
~C|MO01|h|Peon|20.00\|01012026\|1|
~C|MT01|m3|Material|50.00\|01012026\|3|
~C|MO%AUX|%|Medios auxiliares|1\|\|0|
)", c, err), "CI: " + err);
  chk(c.root == "T01##" && c.ci_mode && near(c.ci, 5), "CI dentro de las partidas");
  chk(near(c.total(c.root), 953.40) && near(c.sum("UO01"), 90.80), "totales con CI");
  // Registros partidos en varias líneas, factor vacío y medición en otra línea.
  Budget d;
  chk(parse("~C|R##||Root|22.4||0|\n~D|R##\n|A\\\\2\n\\B\\\\1\n\\|\n~C|A||a|10||0|\n~C|B||b|2.4||0|\n~M|R##\\A|1\\|2|\n\\Linea\\2\\\\\\\\|\n", d, err), "registros partidos");
  chk(near(d.total("R##"), 22.4) && d.kind_in("A", "R##") == K_UNIT, "factor vacío = 1");
  const Measure* md = d.measure("R##", "A");
  chk(md && md->lines.size() == 1 && md->lines[0].comment == "Linea" && near(md->computed, 2), "medición partida en líneas");
  // Referencias sin el # del capítulo (como exportan algunos programas).
  Budget k;
  chk(parse("~C|O##||Obra|60||0|\n~D|O##|C1\\1\\1\\|\n~C|C1#||Cap|60||0|\n~D|C1|E1\\1\\4\\|\n~M|C1\\E1|1\\|4|\\Uno\\4\\\\\\\\|\n~C|E1|u|E|15||0|\n", k, err), "sin #: " + err);
  chk(k.c.count("C1") == 0 && k.get("C1#") && k.get("O##")->kids[0].code == "C1#" && k.get("C1#")->kids.size() == 1, "C1 es C1#");
  chk(near(k.total(k.root), 60) && k.measure("C1#", "E1") != nullptr, "totales y mediciones sin #");
  // Ciclos: no se cuelga.
  Budget e;
  chk(parse("~C|X||x|||0|\n~D|X|Y\\1\\1\\|\n~D|Y|X\\1\\1\\|\n", e, err), "ciclo");
  e.total("X");
  chk(e.cycle, "ciclo detectado");
  // Juegos de caracteres.
  chk(decode("PE\xD3N", "ANSI") == "PE\xC3\x93N", "ANSI");
  chk(decode("Pe\xA2n", "850") == "Pe\xC3\xB3n", "850");
  chk(decode("Espa\xA4" "a", "437") == "Espa\xC3\xB1" "a", "437");
  chk(decode("Pe\xA2n", "") == "Pe\xC3\xB3n", "850 por defecto");
  chk(decode("Pe\xC3\xB3n", "850") == "Pe\xC3\xB3n", "ya en UTF-8");
  Budget g;
  chk(parse(std::string("~V|x|FIEBDC-3/2002|x||ANSI|\n~C|E01|m2|DEMOLICI\xD3N|3.47||0|\n"), g, err) && g.get("E01")->summary == "DEMOLICI\xC3\x93N", "ANSI en el archivo");
  // Fórmulas y números.
  double v[4] = {4, 2.5, 0, 2}, r = 0;
  chk(eval("A*B-2", v, r) && near(r, 8), "fórmula");
  chk(eval("(a+b)*d^2", v, r) && near(r, 26), "fórmula con potencia");
  chk(!eval("2*", v, r) && !eval("x+1", v, r), "fórmula mal escrita");
  chk(number(1234567.891) == "1" + std::string(tx::THOUSANDS) + "234" + tx::THOUSANDS + "567" + tx::DECIMAL + "89", "miles");
  chk(qty(17.445) == "17" + std::string(tx::DECIMAL) + "445" && qty(2.5) == "2" + std::string(tx::DECIMAL) + "50", "cantidades");
  chk(fold("Demolición TABIQUE Ñ") == "demolicion tabique n", "plegar acentos");
  std::string empty_err;
  Budget h;
  chk(!parse("hola", h, empty_err) && !empty_err.empty(), "archivo sin conceptos");
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace bv

// ============================================================ los widgets
namespace bv {

const Fl_Color INK = 0x0f172a00, MUTED = 0x64748b00, LINE = 0xe2e8f000, CARD = 0xffffff00, BG = 0xf3f5f900, ACCENT = 0x2563eb00, SOFT = 0xeef2ff00;
inline Fl_Color kind_color(Kind k) {
  static const Fl_Color c[K_COUNT] = {0x0f172a00, 0x2563eb00, 0x0d948800, 0x7c3aed00, 0xea580c00, 0xca8a0400, 0x16a34a00, 0x64748b00, 0x92400e00, 0x94a3b800};
  return c[k];
}
inline const char* kind_badge(Kind k) {
  static const char* const b[K_COUNT] = {tx::KB_ROOT, tx::KB_CHAPTER, tx::KB_UNIT, tx::KB_AUX, tx::KB_LABOR, tx::KB_MACHINE, tx::KB_MATERIAL, tx::KB_PERCENT, tx::KB_WASTE, tx::KB_OTHER};
  return b[k];
}
inline void badge(int x, int y, int w, int h, Kind k) {
  fl_color(kind_color(k));
  fl_rounded_rectf(x, y, w, h, 4);
  fl_color(FL_WHITE);
  fl_font(FL_HELVETICA_BOLD, 10);
  fl_draw(kind_badge(k), x, y, w, h, FL_ALIGN_CENTER);
}
// Texto recortado con «…» si no cabe.
inline std::string fit(const std::string& s, int w) {
  if (w <= 8) return "";
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string o = s;
  while (!o.empty() && (int)fl_width((o + "…").c_str()) > w) {
    o.pop_back();
    while (!o.empty() && ((unsigned char)o.back() & 0xC0) == 0x80) o.pop_back();
  }
  return o + "…";
}
inline std::string money(double v, const std::string& cur) { return number(v) + (cur == "EUR" ? " €" : " " + cur); }

// ---- un nodo del árbol: insignia, código, resumen e importe a la derecha
class Item : public Fl_Tree_Item {
public:
  std::string code, pcode;   // su código y el de su padre
  Kind kind = K_OTHER;
  double amount = 0;
  bool loaded = false, has_kids = false;
  Item(Fl_Tree* t, const std::string& c) : Fl_Tree_Item(t), code(c) {}
  int draw_item_content(int render) override {
    int X = label_x(), Y = label_y(), W = label_w() - Fl::scrollbar_size() - 2, H = label_h();
    if (!render) return X + W;
    const Budget* b = budget;
    fl_color(drawbgcolor());
    fl_rectf(X, Y, W, H);
    Fl_Color fg = is_selected() ? FL_WHITE : INK;
    badge(X + 2, Y + (H - 16) / 2, 40, 16, kind);
    int x = X + 50;
    fl_font(FL_HELVETICA_BOLD, 13);
    std::string am = kind == K_PERCENT || !b ? "" : money(amount, b->currency);
    int aw = am.empty() ? 0 : (int)fl_width(am.c_str()) + 14;
    fl_color(fg);
    fl_draw(code.c_str(), x, Y, W, H, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    int cw = (int)fl_width(code.c_str()) + 10;
    const Concept* cc = b ? b->get(code) : nullptr;
    fl_font(kind == K_CHAPTER || kind == K_ROOT ? FL_HELVETICA_BOLD : FL_HELVETICA, 13);
    fl_color(is_selected() ? FL_WHITE : kind == K_CHAPTER || kind == K_ROOT ? INK : 0x33415500);
    if (cc) fl_draw(fit(cc->summary, X + W - x - cw - aw).c_str(), x + cw, Y, W, H, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    if (!am.empty()) {
      fl_font(kind == K_CHAPTER || kind == K_ROOT ? FL_HELVETICA_BOLD : FL_HELVETICA, 13);
      fl_color(is_selected() ? FL_WHITE : kind == K_CHAPTER || kind == K_ROOT ? ACCENT : MUTED);
      fl_draw(am.c_str(), X, Y, W - 8, H, FL_ALIGN_RIGHT | FL_ALIGN_INSIDE);
    }
    return X + W;
  }
  static const Budget*& budget_ref() {
    static const Budget* b = nullptr;
    return b;
  }
private:
  const Budget* budget = budget_ref();
};

// ---- el árbol: también acepta que suelten un archivo encima
class Tree : public Fl_Tree {
public:
  std::function<void(const std::string&)> on_drop;
  Tree(int x, int y, int w, int h) : Fl_Tree(x, y, w, h) {}
  int handle(int e) override {
    if (e == FL_DND_ENTER || e == FL_DND_DRAG || e == FL_DND_RELEASE) return 1;
    if (e == FL_PASTE) {
      std::string t = Fl::event_text() ? Fl::event_text() : "";
      std::string path = trim(t.substr(0, t.find('\n')));
      if (path.rfind("file://", 0) == 0) path = path.substr(7);
      if (!path.empty() && on_drop) on_drop(path);
      return 1;
    }
    return Fl_Tree::handle(e);
  }
};

// ---- una tabla sencilla (descomposición y mediciones)
struct Col {
  std::string title;
  int weight;
  bool right;
};
struct Row {
  std::vector<std::string> cells;
  Kind kind = K_OTHER;
  bool badge = false, total = false, note = false;
};
class Grid : public Fl_Table_Row {
public:
  std::vector<Col> cols;
  std::vector<Row> data;
  std::string empty;
  std::function<void(int)> on_pick;
  Grid(int x, int y, int w, int h) : Fl_Table_Row(x, y, w, h) {
    type(SELECT_SINGLE);
    col_header(1);
    col_header_height(28);
    row_height_all(26);
    box(FL_FLAT_BOX);
    color(CARD);
    selection_color(SOFT);
    when(FL_WHEN_RELEASE);
    callback([](Fl_Widget* w, void*) {
      Grid* g = (Grid*)w;
      if (g->callback_context() == CONTEXT_CELL && g->on_pick && Fl::event() == FL_RELEASE) g->on_pick(g->callback_row());
    });
    end();
  }
  void set(std::vector<Col> c, std::vector<Row> d, const std::string& e) {
    cols = std::move(c);
    data = std::move(d);
    empty = e;
    cols_n();
    rows((int)data.size());
    select_all_rows(0);
    redraw();
  }
  void cols_n() {
    Fl_Table_Row::cols((int)cols.size());
    widths();
  }
  void widths() {
    int total = 0;
    for (auto& c : cols) total += c.weight;
    int avail = tiw - 2, used = 0;
    for (size_t i = 0; i < cols.size(); i++) {
      int w = i + 1 == cols.size() ? avail - used : avail * cols[i].weight / std::max(1, total);
      col_width((int)i, std::max(30, w));
      used += w;
    }
  }
  void resize(int x, int y, int w, int h) override {
    Fl_Table_Row::resize(x, y, w, h);
    widths();
  }
  void draw() override {
    Fl_Table_Row::draw();
    if (data.empty() && !empty.empty()) {
      fl_font(FL_HELVETICA, 14);
      fl_color(MUTED);
      fl_draw(empty.c_str(), x() + 20, y() + 40, w() - 40, 60, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
    }
  }
  void draw_cell(TableContext ctx, int R, int C, int X, int Y, int W, int H) override {
    if (ctx == CONTEXT_STARTPAGE) { fl_font(FL_HELVETICA, 13); return; }
    if (ctx == CONTEXT_COL_HEADER) {
      fl_push_clip(X, Y, W, H);
      fl_color(0xf8fafc00);
      fl_rectf(X, Y, W, H);
      fl_color(LINE);
      fl_xyline(X, Y + H - 1, X + W);
      fl_font(FL_HELVETICA_BOLD, 11);
      fl_color(MUTED);
      if (C < (int)cols.size()) fl_draw(cols[(size_t)C].title.c_str(), X + 8, Y, W - 16, H, (cols[(size_t)C].right ? FL_ALIGN_RIGHT : FL_ALIGN_LEFT) | FL_ALIGN_INSIDE);
      fl_pop_clip();
      return;
    }
    if (ctx != CONTEXT_CELL || R >= (int)data.size()) return;
    const Row& r = data[(size_t)R];
    fl_push_clip(X, Y, W, H);
    fl_color(r.total ? 0xf1f5f900 : row_selected(R) ? SOFT : CARD);
    fl_rectf(X, Y, W, H);
    fl_color(LINE);
    fl_xyline(X, Y + H - 1, X + W);
    std::string s = C < (int)r.cells.size() ? r.cells[(size_t)C] : "";
    int x = X + 8;
    if (C == 0 && r.badge) {
      badge(x, Y + (H - 16) / 2, 40, 16, r.kind);
      x += 46;
    }
    fl_font(r.total || (C == 0 && r.badge) ? FL_HELVETICA_BOLD : FL_HELVETICA, 13);
    fl_color(r.note ? MUTED : r.total ? INK : C == (int)cols.size() - 1 && !r.note ? INK : 0x33415500);
    bool right = C < (int)cols.size() && cols[(size_t)C].right;
    fl_draw(fit(s, X + W - x - 8).c_str(), x, Y, X + W - x - 8, H, (right ? FL_ALIGN_RIGHT : FL_ALIGN_LEFT) | FL_ALIGN_INSIDE);
    fl_pop_clip();
  }
};

// ---- la cabecera del concepto elegido
struct CardData {
  std::string path, code, summary, unit, qty, price, amount, note;
  Kind kind = K_OTHER;
  bool empty = true;
};
class Card : public Fl_Widget {
public:
  CardData d;
  Card(int x, int y, int w, int h) : Fl_Widget(x, y, w, h) {}
  void draw() override {
    fl_color(BG);
    fl_rectf(x(), y(), w(), h());
    int X = x() + 14, Y = y() + 12, W = w() - 28, H = h() - 20;
    fl_color(CARD);
    fl_rounded_rectf(X, Y, W, H, 10);
    fl_color(LINE);
    fl_rounded_rect(X, Y, W, H, 10);
    if (d.empty) {
      fl_font(FL_HELVETICA_BOLD, 20);
      fl_color(INK);
      fl_draw(tx::EMPTY_TITLE, X + 24, Y + 22, W - 48, 30, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      fl_font(FL_HELVETICA, 14);
      fl_color(MUTED);
      fl_draw(tx::EMPTY_HINT, X + 24, Y + 58, W - 48, 50, FL_ALIGN_LEFT | FL_ALIGN_INSIDE | FL_ALIGN_WRAP | FL_ALIGN_TOP);
      return;
    }
    fl_font(FL_HELVETICA, 11);
    fl_color(MUTED);
    fl_draw(fit(d.path, W - 36).c_str(), X + 18, Y + 8, W - 36, 16, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    badge(X + 18, Y + 30, 46, 20, d.kind);
    fl_font(FL_HELVETICA_BOLD, 20);
    fl_color(INK);
    fl_draw(d.code.c_str(), X + 74, Y + 26, W - 90, 28, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    int cw = (int)fl_width(d.code.c_str());
    fl_font(FL_HELVETICA, 12);
    fl_color(kind_color(d.kind));
    fl_draw(kind_name(d.kind), X + 84 + cw, Y + 26, 200, 28, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    fl_font(FL_HELVETICA, 14);
    fl_color(0x33415500);
    fl_draw(d.summary.c_str(), X + 18, Y + 56, W - 36, 36, FL_ALIGN_LEFT | FL_ALIGN_INSIDE | FL_ALIGN_WRAP | FL_ALIGN_TOP | FL_ALIGN_CLIP);
    // Cuatro cifras: unidad, cantidad, precio e importe.
    const char* lab[4] = {tx::LBL_UNIT, tx::LBL_QTY, tx::LBL_PRICE, tx::LBL_AMOUNT};
    const std::string* val[4] = {&d.unit, &d.qty, &d.price, &d.amount};
    int bw = (W - 36) / 4, by = Y + H - 46;
    for (int i = 0; i < 4; i++) {
      int bx = X + 18 + i * bw;
      fl_font(FL_HELVETICA_BOLD, 10);
      fl_color(MUTED);
      fl_draw(lab[i], bx, by, bw - 10, 14, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      fl_font(FL_HELVETICA_BOLD, i == 3 ? 18 : 16);
      fl_color(i == 3 ? ACCENT : INK);
      fl_draw(val[i]->empty() ? "—" : val[i]->c_str(), bx, by + 14, bw - 10, 24, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    }
    if (!d.note.empty()) {
      fl_font(FL_HELVETICA, 11);
      fl_color(0xb4530900);
      fl_draw(fit(d.note, W / 2).c_str(), X + W / 2, Y + 8, W / 2 - 18, 16, FL_ALIGN_RIGHT | FL_ALIGN_INSIDE);
    }
  }
};

// ---- el resumen del presupuesto: datos del archivo, totales, desglose y las partidas mayores
class Summary : public Fl_Widget {
public:
  const Budget* b = nullptr;
  double acc[C_COUNT] = {0};
  std::vector<std::pair<std::string, double>> top;
  int n_ch = 0, n_it = 0;
  Summary(int x, int y, int w, int h) : Fl_Widget(x, y, w, h) {}
  void refresh(const Budget* bb) {
    b = bb;
    for (double& v : acc) v = 0;
    top.clear();
    n_ch = n_it = 0;
    if (b) {
      std::map<std::string, double> items;
      b->breakdown(b->root, 1, acc, items);
      top.assign(items.begin(), items.end());
      std::sort(top.begin(), top.end(), [](auto& a, auto& c) { return a.second > c.second; });
      if (top.size() > 8) top.resize(8);
      std::set<std::string> ch, it;
      b->count(b->root, ch, it);
      n_ch = (int)ch.size();
      n_it = (int)it.size();
    }
    redraw();
  }
  void draw() override {
    fl_color(CARD);
    fl_rectf(x(), y(), w(), h());
    if (!b) return;
    fl_push_clip(x(), y(), w(), h());
    int X = x() + 20, Y = y() + 16, colw = std::min(360, (w() - 60) / 2), kw = 118;
    auto row = [&](const char* k, const std::string& v, int& yy, bool strong = false) {
      fl_font(FL_HELVETICA, 12);
      fl_color(MUTED);
      fl_draw(k, X, yy, colw, 18, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      fl_font(strong ? FL_HELVETICA_BOLD : FL_HELVETICA, strong ? 14 : 12);
      fl_color(strong ? INK : 0x33415500);
      fl_draw(fit(v, colw - kw).c_str(), X + kw, yy, colw - kw, 18, FL_ALIGN_RIGHT | FL_ALIGN_INSIDE);
      yy += strong ? 22 : 19;
    };
    int yy = Y;
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(INK);
    fl_draw(tx::S_FILE, X, yy, colw, 18, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    yy += 24;
    std::string date = b->date.size() == 8 ? b->date.substr(0, 2) + "/" + b->date.substr(2, 2) + "/" + b->date.substr(4) : b->date;
    row(tx::S_NAME, b->file, yy);
    row(tx::S_VERSION, b->version + (date.empty() ? "" : "  ·  " + date), yy);
    row(tx::S_PROGRAM, b->program, yy);
    row(tx::S_OWNER, b->owner, yy);
    row(tx::S_CHARSET, b->charset, yy);
    row(tx::S_CONTENT, fmt(tx::S_COUNTS, {std::to_string(b->c.size()), std::to_string(n_ch), std::to_string(n_it)}), yy);
    yy += 10;
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(INK);
    fl_draw(tx::S_TOTALS, X, yy, colw, 18, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    yy += 24;
    double pem = b->total(b->root), gg = pem * b->gg / 100, bi = pem * b->bi / 100, pec = round2(pem + gg + bi), iva = round2(pec * b->iva / 100);
    row(tx::S_PEM, money(pem, b->currency), yy, true);
    row(fmt(tx::S_GG, {number(b->gg, 0)}).c_str(), money(gg, b->currency), yy);
    row(fmt(tx::S_BI, {number(b->bi, 0)}).c_str(), money(bi, b->currency), yy);
    row(tx::S_PEC, money(pec, b->currency), yy, true);
    row(fmt(tx::S_IVA, {number(b->iva, 0)}).c_str(), money(iva, b->currency), yy);
    row(tx::S_TOTAL, money(pec + iva, b->currency), yy, true);
    if (b->ci > 0) {
      fl_font(FL_HELVETICA, 11);
      fl_color(MUTED);
      fl_draw(fmt(b->ci_mode ? tx::S_CI_IN : tx::S_CI_OUT, {number(b->ci, 0)}).c_str(), X, yy + 4, colw, 32, FL_ALIGN_LEFT | FL_ALIGN_INSIDE | FL_ALIGN_WRAP | FL_ALIGN_TOP);
    }
    // Desglose por naturaleza, con barras.
    int RX = X + colw + 30, RW = x() + w() - RX - 20;
    int ry = Y;
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(INK);
    fl_draw(tx::S_NATURE, RX, ry, RW, 18, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    ry += 26;
    static const char* const names[C_COUNT] = {tx::CAT_LABOR, tx::CAT_MACHINE, tx::CAT_MATERIAL, tx::CAT_WASTE, tx::CAT_PCT, tx::CAT_CI, tx::CAT_UNDEC, tx::CAT_OTHER};
    static const Fl_Color cc[C_COUNT] = {0xea580c00, 0xca8a0400, 0x16a34a00, 0x92400e00, 0x64748b00, 0x7c3aed00, 0x0d948800, 0x94a3b800};
    double sum = 0;
    for (double v : acc) sum += v;
    for (int i = 0; i < C_COUNT; i++) {
      if (acc[i] < 0.005) continue;
      double pc = sum > 0 ? acc[i] / sum : 0;
      fl_font(FL_HELVETICA, 12);
      fl_color(0x33415500);
      fl_draw(names[i], RX, ry, RW, 16, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(INK);
      fl_draw((number(pc * 100, 1) + " %   " + money(acc[i], b->currency)).c_str(), RX, ry, RW, 16, FL_ALIGN_RIGHT | FL_ALIGN_INSIDE);
      fl_color(0xf1f5f900);
      fl_rounded_rectf(RX, ry + 19, RW, 8, 4);
      fl_color(cc[i]);
      fl_rounded_rectf(RX, ry + 19, std::max(6, (int)(RW * pc)), 8, 4);
      ry += 36;
    }
    ry += 6;
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(INK);
    fl_draw(tx::S_TOP, RX, ry, RW, 18, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    ry += 24;
    double mx = top.empty() ? 1 : std::max(0.01, top.front().second);
    for (auto& [code, v] : top) {
      if (ry + 22 > y() + h()) break;
      const Concept* c = b->get(code);
      fl_color(SOFT);
      fl_rectf(RX, ry, (int)(RW * v / mx), 20);
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(INK);
      fl_draw(code.c_str(), RX + 6, ry, 80, 20, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      std::string am = money(v, b->currency);
      int aw = (int)fl_width(am.c_str());
      fl_draw(am.c_str(), RX, ry, RW - 6, 20, FL_ALIGN_RIGHT | FL_ALIGN_INSIDE);
      fl_font(FL_HELVETICA, 12);
      fl_color(0x33415500);
      if (c) fl_draw(fit(c->summary, RW - 100 - aw).c_str(), RX + 86, ry, RW - 100 - aw, 20, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      ry += 23;
    }
    fl_pop_clip();
  }
};

}  // namespace bv

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  bv::Budget budget;
  bool loaded = false, live = true;
  bv::Tree* tree = nullptr;
  bv::Card* card = nullptr;
  Fl_Tabs* tabs = nullptr;
  Fl_Group *pDecomp = nullptr, *pMeas = nullptr, *pText = nullptr, *pSummary = nullptr;
  bv::Grid *decomp = nullptr, *meas = nullptr;
  Fl_Text_Display* text = nullptr;
  Fl_Text_Buffer* textbuf = nullptr;
  bv::Summary* summary = nullptr;
  bv::Item* current = nullptr;
  std::vector<bv::Line> cur_lines;
  std::vector<bv::PathNode> nodes;
  std::vector<int> hits;
  std::string last_query, message;
  int hit = -1;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }
  Form1() {
    if (fl_getenv("DMS_BC3_SELFTEST")) std::exit(bv::selftest());
    if (fl_getenv("DMS_BC3_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_BC3_SHOT")) { set_fonts(); std::exit(shots(d)); }
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

  // ---- montar la ventana
  void setup() {
    self() = this;
    BoardHint->hide();
    bv::Item::budget_ref() = &budget;
    color(bv::BG);
    TreeHost->box(FL_FLAT_BOX);
    DetailHost->box(FL_FLAT_BOX);
    TreeHost->begin();
    tree = new bv::Tree(TreeHost->x(), TreeHost->y(), TreeHost->w(), TreeHost->h());
    tree->showroot(0);
    tree->item_labelsize(13);
    tree->linespacing(2);
    tree->usericonmarginleft(0);
    tree->connectorstyle(FL_TREE_CONNECTOR_DOTTED);
    tree->selectmode(FL_TREE_SELECT_SINGLE);
    tree->item_reselect_mode(FL_TREE_SELECTABLE_ALWAYS);
    tree->color(bv::CARD);
    tree->selection_color(bv::ACCENT);
    tree->box(FL_FLAT_BOX);
    tree->callback([](Fl_Widget*, void*) { if (self()) self()->tree_event(); });
    tree->on_drop = [](const std::string& p) { if (self()) self()->open_path(p); };
    TreeHost->end();
    TreeHost->resizable(tree);

    DetailHost->begin();
    int X = DetailHost->x(), Y = DetailHost->y(), W = DetailHost->w(), H = DetailHost->h();
    card = new bv::Card(X, Y, W, 160);
    tabs = new Fl_Tabs(X + 14, Y + 164, W - 28, H - 176);
    tabs->box(FL_FLAT_BOX);
    tabs->color(bv::BG);
    tabs->selection_color(bv::CARD);
    tabs->labelsize(13);
    int tx0 = tabs->x(), ty0 = tabs->y() + 30, tw = tabs->w(), th = tabs->h() - 30;
    auto page = [&](const char* title) {
      Fl_Group* g = new Fl_Group(tx0, ty0, tw, th, title);
      g->box(FL_FLAT_BOX);
      g->color(bv::CARD);
      g->labelsize(13);
      return g;
    };
    pDecomp = page(tx::TAB_DECOMP);
    decomp = new bv::Grid(tx0, ty0, tw, th);
    decomp->on_pick = [](int r) { if (self()) self()->pick_line(r); };
    pDecomp->end();
    pDecomp->resizable(decomp);
    pMeas = page(tx::TAB_MEAS);
    meas = new bv::Grid(tx0, ty0, tw, th);
    pMeas->end();
    pMeas->resizable(meas);
    pText = page(tx::TAB_TEXT);
    textbuf = new Fl_Text_Buffer();
    text = new Fl_Text_Display(tx0 + 14, ty0 + 10, tw - 28, th - 20);
    text->buffer(textbuf);
    text->wrap_mode(Fl_Text_Display::WRAP_AT_BOUNDS, 0);
    text->textsize(14);
    text->box(FL_FLAT_BOX);
    text->color(bv::CARD);
    text->textcolor(bv::INK);
    pText->end();
    pText->resizable(text);
    pSummary = page(tx::TAB_SUMMARY);
    summary = new bv::Summary(tx0, ty0, tw, th);
    pSummary->end();
    pSummary->resizable(summary);
    tabs->end();
    tabs->resizable(pDecomp);
    DetailHost->end();
    DetailHost->resizable(tabs);
    resizable(DetailHost);
    size_range(980, 620);

    Search->tooltip(tx::SEARCH_HINT);
    Search->when(FL_WHEN_ENTER_KEY_ALWAYS);
    show_empty();
  }
  void form_create() override {
    set_fonts();
    setup();
#ifdef __APPLE__
    fl_open_callback([](const char* p) { if (self() && p) self()->open_path(p); });
#endif
    status();
  }

  // ---- abrir
  bool load_text(const std::string& raw, const std::string& name) {
    bv::Budget b;
    std::string err;
    if (!bv::parse(raw, b, err)) {
      if (live) fl_alert("%s", err.c_str());
      message = err;
      return false;
    }
    b.file = name;
    budget = std::move(b);
    loaded = true;
    nodes.clear();
    std::vector<std::string> st;
    bv::walk(budget, nodes, -1, budget.root, st);
    hits.clear();
    hit = -1;
    last_query.clear();
    summary->refresh(&budget);
    tabs->show();
    build_tree();
    title(std::string(tx::APP) + " — " + name);
    message.clear();
    status();
    return true;
  }
  bool open_path(const std::string& path) {
    std::string raw;
    if (!bv::read_file(path, raw)) {
      message = bv::fmt(tx::ERR_READ, {path});
      if (live) fl_alert("%s", message.c_str());
      status();
      return false;
    }
    return load_text(raw, fl_filename_name(path.c_str()));
  }
  void open_sample() { load_text(bv::SAMPLE, tx::SAMPLE_NAME); }

  // ---- el árbol, que se llena al abrir cada rama
  static Fl_RGB_Image* row_icon() {
    static unsigned char px[1 * 24 * 4] = {0};
    static Fl_RGB_Image* img = new Fl_RGB_Image(px, 1, 24, 4);
    return img;
  }
  bv::Item* add_item(Fl_Tree_Item* parent, const bv::Line& l, const std::string& pcode) {
    auto* it = new bv::Item(tree, l.code);
    it->usericon(row_icon());   // un icono invisible de 24 px: todas las filas igual de altas
    it->pcode = pcode;
    it->kind = l.kind;
    it->amount = l.amount;
    const bv::Concept* c = budget.get(l.code);
    it->has_kids = c && !c->kids.empty() && l.kind != bv::K_PERCENT;
    parent->add(tree->prefs(), l.code.c_str(), it);
    if (it->has_kids) it->add(tree->prefs(), "…");   // marcador: se cambia por los hijos al abrir
    it->close();
    return it;
  }
  void populate(bv::Item* it) {
    if (!it || it->loaded || !it->has_kids) return;
    it->clear_children();
    for (auto& l : budget.lines(it->code)) add_item(it, l, it->code);
    it->loaded = true;
  }
  void build_tree() {
    tree->clear_children(tree->root());
    current = nullptr;
    bv::Line r;
    r.code = budget.root;
    r.kind = bv::K_ROOT;
    r.amount = budget.total(budget.root);
    r.qty = 1;
    auto* top = add_item(tree->root(), r, "");
    populate(top);
    top->open();
    // Los capítulos de primer nivel, abiertos.
    for (int i = 0; i < top->children(); i++) {
      auto* ch = (bv::Item*)top->child(i);
      if (ch->kind == bv::K_CHAPTER) { populate(ch); ch->open(); }
    }
    tree->select_only(top, 0);
    show_item(top);
    tabs->value(pSummary);
    tree->redraw();
  }
  void expand(bool open) {
    if (!loaded) return;
    auto* top = (bv::Item*)tree->root()->child(0);
    std::function<void(bv::Item*)> rec = [&](bv::Item* it) {
      if (it->kind != bv::K_ROOT && it->kind != bv::K_CHAPTER) return;
      if (open) { populate(it); it->open(); }
      else if (it != top) it->close();
      for (int i = 0; i < it->children(); i++)
        if (it->loaded) rec((bv::Item*)it->child(i));
    };
    rec(top);
    tree->redraw();
  }
  void tree_event() {
    auto* it = dynamic_cast<bv::Item*>(tree->callback_item());
    if (!it) return;
    switch (tree->callback_reason()) {
      case FL_TREE_REASON_OPENED:
        populate(it);
        tree->redraw();
        break;
      case FL_TREE_REASON_SELECTED:
      case FL_TREE_REASON_RESELECTED:
        show_item(it);
        break;
      default:
        break;
    }
  }

  // ---- el detalle del concepto elegido
  std::string path_text(bv::Item* it) {
    std::vector<std::string> parts;
    for (Fl_Tree_Item* p = it->parent(); p && p != tree->root(); p = p->parent()) parts.insert(parts.begin(), ((bv::Item*)p)->code);
    std::string s = tx::BUDGET;
    for (auto& p : parts) s += "  ›  " + p;
    return s;
  }
  void show_item(bv::Item* it) {
    current = it;
    const bv::Concept* c = budget.get(it->code);
    bv::CardData d;
    d.empty = false;
    d.code = it->code;
    d.kind = it->kind;
    d.path = path_text(it);
    d.summary = c ? c->summary : "";
    d.unit = c ? c->unit : "";
    // La línea de su padre: cantidad y precio.
    bv::Line pl;
    bool in_parent = false;
    if (!it->pcode.empty())
      for (auto& l : budget.lines(it->pcode))
        if (l.code == it->code) { pl = l; in_parent = true; break; }
    bool chap = it->kind == bv::K_ROOT || it->kind == bv::K_CHAPTER;
    if (it->kind == bv::K_ROOT) {
      d.qty = "1";
      d.price = d.amount = bv::money(budget.total(it->code), budget.currency);
    } else if (in_parent) {
      d.qty = it->kind == bv::K_PERCENT ? bv::number(pl.qty * 100, 2) + " %" : bv::qty(pl.qty);
      d.price = bv::money(pl.price, budget.currency);
      d.amount = bv::money(pl.amount, budget.currency);
    }
    // ¿Cuadra el precio del archivo con su descomposición?
    if (c && c->has_price && !c->kids.empty() && it->kind != bv::K_PERCENT) {
      double calc = chap ? budget.total(it->code) : budget.sum(it->code);
      if (std::fabs(calc - c->price) > 0.011) d.note = bv::fmt(tx::PRICE_DIFF, {bv::money(c->price, budget.currency), bv::money(calc, budget.currency)});
    }
    card->d = d;
    card->redraw();
    fill_decomp(it);
    fill_meas(it, c);
    fill_text(c);
  }
  void fill_decomp(bv::Item* it) {
    cur_lines = budget.lines(it->code);
    std::vector<bv::Col> cols = {{tx::COL_CODE, 18, false}, {tx::COL_UNIT, 6, false}, {tx::COL_SUMMARY, 40, false}, {tx::COL_QTY, 11, true}, {tx::COL_PRICE, 12, true}, {tx::COL_AMOUNT, 13, true}};
    std::vector<bv::Row> rows;
    double sum = 0;
    for (auto& l : cur_lines) {
      const bv::Concept* c = budget.get(l.code);
      bv::Row r;
      r.badge = true;
      r.kind = l.kind;
      bool pct = l.kind == bv::K_PERCENT;
      r.cells = {l.code, c ? c->unit : "", c ? c->summary : "", pct ? bv::number(l.qty * 100, 2) + " %" : bv::qty(l.qty), bv::number(l.price), bv::number(l.amount)};
      rows.push_back(r);
      sum += l.amount;
    }
    if (!rows.empty()) {
      bv::Row t;
      t.total = true;
      t.cells = {"", "", tx::TOTAL, "", "", bv::number(bv::round2(sum))};
      rows.push_back(t);
    }
    decomp->set(cols, rows, it->kind == bv::K_PERCENT ? tx::PCT_HINT : tx::NO_DECOMP);
  }
  void fill_meas(bv::Item* it, const bv::Concept*) {
    const bv::Measure* m = it->pcode.empty() ? nullptr : budget.measure(it->pcode, it->code);
    std::vector<bv::Col> cols = {{tx::COL_COMMENT, 38, false}, {tx::COL_N, 10, true}, {tx::COL_L, 12, true}, {tx::COL_W, 12, true}, {tx::COL_H, 12, true}, {tx::COL_PARTIAL, 14, true}};
    std::vector<bv::Row> rows;
    if (m) {
      for (auto& l : m->lines) {
        bv::Row r;
        std::string com = l.comment;
        if (l.type == 1) com = l.comment.empty() ? tx::MT_PARTIAL : l.comment;
        if (l.type == 2) com = l.comment.empty() ? tx::MT_ACCUM : l.comment;
        if (l.type == 3) com = std::string("ƒ  ") + l.comment;
        r.note = !l.has;
        r.total = l.type == 1 || l.type == 2;
        auto f = [](const std::string& s) { double v; return bv::num(s, v) ? bv::qty(v) : std::string(); };
        r.cells = {com, f(l.f[0]), f(l.f[1]), f(l.f[2]), f(l.f[3]), l.has ? bv::qty(l.partial) : ""};
        rows.push_back(r);
      }
      bv::Row t;
      t.total = true;
      t.cells = {tx::MEAS_TOTAL, "", "", "", "", bv::qty(m->computed)};
      rows.push_back(t);
      if (m->has_total && std::fabs(m->total - m->computed) > 0.0015) {
        bv::Row n;
        n.note = true;
        n.cells = {bv::fmt(tx::MEAS_FILE, {bv::qty(m->total)}), "", "", "", "", ""};
        rows.push_back(n);
      }
    }
    meas->set(cols, rows, tx::NO_MEAS);
  }
  void fill_text(const bv::Concept* c) {
    std::string s;
    if (c) {
      s = c->text;
      for (auto& [sec, t] : c->pliego) {
        auto it = budget.sections.find(sec);
        s += std::string(s.empty() ? "" : "\n\n") + "— " + (it != budget.sections.end() ? it->second : sec) + " —\n" + t;
      }
    }
    textbuf->text(s.empty() ? tx::NO_TEXT : s.c_str());
  }
  // Clic en una línea de la descomposición: se va a ese concepto.
  void pick_line(int r) {
    if (!current || r < 0 || r >= (int)cur_lines.size()) return;
    populate(current);
    current->open();
    for (int i = 0; i < current->children(); i++) {
      auto* ch = (bv::Item*)current->child(i);
      if (i == r && ch->code == cur_lines[(size_t)r].code) { select(ch); return; }
    }
  }
  void select(bv::Item* it) {
    for (Fl_Tree_Item* p = it->parent(); p && p != tree->root(); p = p->parent()) p->open();
    tree->select_only(it, 0);
    tree->calc_tree();
    tree->show_item_middle(it);
    show_item(it);
    tree->redraw();
  }

  // ---- buscar (Intro: el siguiente resultado)
  void search() {
    if (!loaded) return;
    std::string q = Search->text();
    if (q != last_query) {
      last_query = q;
      hits = bv::find(budget, nodes, q);
      hit = -1;
    }
    if (hits.empty()) {
      message = q.empty() ? "" : bv::fmt(tx::NOT_FOUND, {q});
      status();
      return;
    }
    hit = (hit + 1) % (int)hits.size();
    reveal(bv::path_of(nodes, hits[(size_t)hit]));
    message = bv::fmt(tx::FOUND, {std::to_string(hit + 1), std::to_string(hits.size())});
    status();
  }
  bool reveal(const std::vector<std::string>& path) {
    if (path.empty() || tree->root()->children() == 0) return false;
    auto* it = (bv::Item*)tree->root()->child(0);
    if (it->code != path[0]) return false;
    for (size_t k = 1; k < path.size(); k++) {
      populate(it);
      it->open();
      bv::Item* next = nullptr;
      for (int i = 0; i < it->children(); i++)
        if (((bv::Item*)it->child(i))->code == path[k]) { next = (bv::Item*)it->child(i); break; }
      if (!next) return false;
      it = next;
    }
    select(it);
    if (it->kind != bv::K_ROOT && tabs->value() == pSummary) tabs->value(pDecomp);
    return true;
  }

  // ---- exportar
  bool export_csv(const std::string& path) {
    if (!loaded) return false;
    bool ok = bv::write_file(path, bv::to_csv(budget));
    message = ok ? bv::fmt(tx::EXPORTED, {path}) : bv::fmt(tx::ERR_READ, {path});
    status();
    return ok;
  }

  void show_empty() {
    tabs->hide();
    card->d = bv::CardData();
    decomp->set({}, {}, "");
    meas->set({}, {}, "");
    textbuf->text("");
    summary->refresh(nullptr);
  }
  void status() {
    if (!message.empty()) { Status->text(" " + message); return; }
    if (!loaded) { Status->text(std::string(" ") + tx::ST_EMPTY); return; }
    std::set<std::string> ch, it;
    budget.count(budget.root, ch, it);
    Status->text(" " + budget.file + "  ·  " + budget.version + "  ·  " + budget.program + "  ·  " +
                 bv::fmt(tx::S_COUNTS, {std::to_string(budget.c.size()), std::to_string(ch.size()), std::to_string(it.size())}) + "  ·  " + tx::S_PEM + ": " +
                 bv::money(budget.total(budget.root), budget.currency));
  }

  // ---- los eventos del diseño
  void Search_enter() override { search(); }
  void BtnOpen_click() override { std::string p = DlgOpen.execute(); if (!p.empty()) open_path(p); }
  void BtnSample_click() override { open_sample(); }
  void BtnExport_click() override {
    if (!loaded) return;
    DlgSave.filename(budget.file.empty() ? "presupuesto.csv" : std::string(budget.file.substr(0, budget.file.rfind('.'))) + ".csv");
    std::string p = DlgSave.execute();
    if (!p.empty() && export_csv(p) && live) fl_message("%s", message.c_str());
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_OPEN) BtnOpen_click();
    else if (item == tx::MP_SAMPLE) open_sample();
    else if (item == tx::MP_EXPORT) BtnExport_click();
    else if (item == tx::MP_QUIT) hide();
    else if (item == tx::MP_EXPAND) expand(true);
    else if (item == tx::MP_COLLAPSE) expand(false);
    else if (item == tx::MP_SUMMARY) { if (loaded) tabs->value(pSummary); }
    else if (item == tx::MP_FIND) Search->take_focus();
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
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
  bool find_show(const std::string& code) {
    for (size_t i = 0; i < nodes.size(); i++)
      if (nodes[i].code == code) return reveal(bv::path_of(nodes, (int)i));
    return false;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    live = false;
    setup();
    status();
    render_to(dir + "/empty.png");
    open_sample();
    render_to(dir + "/summary.png");
    find_show("ALB010");
    tabs->value(pDecomp);
    render_to(dir + "/window.png");
    tabs->value(pMeas);
    render_to(dir + "/measures.png");
    tabs->value(pText);
    render_to(dir + "/text.png");
    find_show("A02A080");
    tabs->value(pDecomp);
    render_to(dir + "/aux.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    live = false;
    setup();
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    status();
    render_to("");
    chk(!loaded && card->d.empty, "sin presupuesto al empezar");
    open_sample();
    chk(loaded && budget.root == "REF24##", "abrir el ejemplo");
    auto* top = (bv::Item*)tree->root()->child(0);
    chk(top && top->code == "REF24##" && top->children() == 6, "raíz con seis capítulos");
    chk(current == top && tabs->value() == pSummary, "empieza en el resumen");
    chk(summary->n_ch == 8 && summary->n_it == 18 && !summary->top.empty(), "resumen calculado");
    render_to("");
    // Abrir una partida: su descomposición, mediciones y texto.
    chk(find_show("ALB010"), "llegar a ALB010");
    chk(current && current->code == "ALB010" && current->pcode == "02#", "ALB010 elegida");
    chk(decomp->data.size() == 7 && decomp->data.back().total, "seis líneas y el total");
    chk(decomp->data.size() == 7 && decomp->data.back().cells[5] == bv::number(18.43), "total de la descomposición");
    chk(meas->data.size() == 5 && meas->data[4].cells[5] == bv::qty(15.94), "mediciones de ALB010");
    chk(std::string(textbuf->text()).find("ladrillo") != std::string::npos && std::string(textbuf->text()).find("—") != std::string::npos, "texto y pliego");
    chk(card->d.amount == bv::money(bv::round2(18.43 * 15.94), budget.currency), "importe en la cabecera");
    render_to("");
    // Clic en la línea del mortero: baja a la partida auxiliar.
    pick_line(3);
    chk(current && current->code == "A02A080" && current->kind == bv::K_AUX, "ir al auxiliar desde la tabla");
    chk(decomp->data.size() == 5, "descomposición del mortero");
    // Buscar: «electricista» está en varias partidas; Intro pasa al siguiente.
    Search->value("electricista");
    search();
    chk(!hits.empty() && current && current->kind == bv::K_LABOR, "buscar");
    std::string first = current ? current->pcode + "/" + current->code : "";
    search();
    chk(hits.size() > 2 && current && current->pcode + "/" + current->code != first && hit == 1, "siguiente resultado");
    Search->value("nada-de-esto");
    search();
    chk(message.find("nada-de-esto") != std::string::npos, "sin resultados");
    expand(true);
    expand(false);
    chk(top->is_open(), "contraer deja la raíz");
    // Exportar y volver a abrir desde un archivo en ANSI (Windows-1252).
    std::string tmp = std::string(fl_getenv("DMS_BC3_TMP") ? fl_getenv("DMS_BC3_TMP") : "/tmp");
    chk(export_csv(tmp + "/bc3_test.csv"), "exportar CSV");
    std::string csv;
    chk(bv::read_file(tmp + "/bc3_test.csv", csv) && csv.find("ALB010") != std::string::npos, "CSV escrito");
    chk(bv::write_file(tmp + "/ansi.bc3", "~V|x|FIEBDC-3/2002|Prueba||ANSI|\r\n~C|OB##||OBRA AN\xD3NIMA|10||0|\r\n~D|OB##|E1\\1\\2\\|\r\n~C|E1|m\xB2|PE\xD3N|5||1|\r\n"), "archivo ANSI");
    chk(open_path(tmp + "/ansi.bc3"), "abrir archivo ANSI");
    chk(budget.get("OB##") && budget.get("OB##")->summary == "OBRA AN\xC3\x93NIMA" && budget.get("E1")->unit == "m\xC2\xB2", "acentos de ANSI");
    chk(std::fabs(budget.total("OB##") - 10) < 0.001, "total del archivo ANSI");
    chk(!open_path(tmp + "/no-existe.bc3") && !message.empty(), "archivo que no existe");
    render_to("");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
