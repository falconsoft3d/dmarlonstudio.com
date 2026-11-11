part of 'tk_examples.dart';

// El código en C++ de los relojes del mundo (tk_showcase_cpp_clocks.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _clocksIncludes = r'''#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <string>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _clocksCode = r'''
// ============================================================ las horas
// La hora de cada país sin depender del sistema: su diferencia con UTC y,
// si cambia en verano, la regla del cambio (la de la Unión Europea, la de
// Estados Unidos, la de Cuba, la de Chile, la de Australia o la de Nueva
// Zelanda). Así funciona igual en macOS, Windows y Linux.
namespace wc {

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}
std::vector<std::string> split(const std::string& s, char sep) {
  std::vector<std::string> out;
  size_t a = 0;
  while (true) {
    size_t b = s.find(sep, a);
    out.push_back(s.substr(a, b == std::string::npos ? std::string::npos : b - a));
    if (b == std::string::npos) break;
    a = b + 1;
  }
  return out;
}

// ---- el calendario (algoritmos de Howard Hinnant, sin zonas horarias)
long long days_from_civil(int y, int m, int d) {
  y -= m <= 2;
  long long era = (y >= 0 ? y : y - 399) / 400;
  long long yoe = y - era * 400;
  long long doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
  long long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + doe - 719468;
}
void civil_from_days(long long z, int& y, int& m, int& d) {
  z += 719468;
  long long era = (z >= 0 ? z : z - 146096) / 146097;
  long long doe = z - era * 146097;
  long long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  long long yy = yoe + era * 400;
  long long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  long long mp = (5 * doy + 2) / 153;
  d = (int)(doy - (153 * mp + 2) / 5 + 1);
  m = (int)(mp < 10 ? mp + 3 : mp - 9);
  y = (int)(yy + (m <= 2));
}
// 0 = domingo.
int weekday(long long days) { return (int)((days % 7 + 11) % 7); }
// El día (días desde 1970) del n-ésimo domingo del mes (n = -1: el último).
long long nth_sunday(int y, int m, int n) {
  if (n > 0) {
    long long first = days_from_civil(y, m, 1);
    return first + (7 - weekday(first)) % 7 + (n - 1) * 7;
  }
  int ny = m == 12 ? y + 1 : y, nm = m == 12 ? 1 : m + 1;
  long long last = days_from_civil(ny, nm, 1) - 1;
  return last - weekday(last);
}

enum Rule { R_NONE, R_EU, R_US, R_CUBA, R_CHILE, R_AU, R_NZ };

// ¿Es horario de verano en el instante UTC [t] para la regla [r] con la
// diferencia normal [std_min]?
bool is_dst(long long t, Rule r, int std_min) {
  if (r == R_NONE) return false;
  int y, m, d;
  civil_from_days(t >= 0 ? t / 86400 : (t - 86399) / 86400, y, m, d);
  auto at = [](long long day, int hour_utc_minutes) { return day * 86400 + hour_utc_minutes * 60LL; };
  long long start = 0, end = 0;
  switch (r) {
    case R_EU:   // último domingo de marzo y de octubre, a la 1:00 UTC
      start = at(nth_sunday(y, 3, -1), 60);
      end = at(nth_sunday(y, 10, -1), 60);
      return t >= start && t < end;
    case R_US:   // segundo domingo de marzo y primero de noviembre, a las 2:00 locales
      start = at(nth_sunday(y, 3, 2), 120 - std_min);
      end = at(nth_sunday(y, 11, 1), 120 - (std_min + 60));
      return t >= start && t < end;
    case R_CUBA:   // segundo domingo de marzo a las 0:00 y primero de noviembre a la 1:00
      // Salvo de marzo de 2026 a noviembre de 2027: Cuba se quedó en el
      // horario de verano (tzdata 2026f).
      if (t >= at(days_from_civil(2026, 3, 8), 300) && t < at(days_from_civil(2027, 11, 7), 300)) return true;
      start = at(nth_sunday(y, 3, 2), 0 - std_min);
      end = at(nth_sunday(y, 11, 1), 60 - (std_min + 60));
      return t >= start && t < end;
    case R_CHILE:   // primer domingo de septiembre a las 4:00 UTC → primero de abril a las 3:00 UTC
      start = at(nth_sunday(y, 9, 1), 240);
      end = at(nth_sunday(y, 4, 1), 180);
      return t >= start || t < end;
    case R_AU:   // primer domingo de octubre a las 2:00 → primero de abril a las 3:00 (locales)
      start = at(nth_sunday(y, 10, 1), 120 - std_min);
      end = at(nth_sunday(y, 4, 1), 180 - (std_min + 60));
      return t >= start || t < end;
    case R_NZ:   // último domingo de septiembre a las 2:00 → primero de abril a las 3:00 (locales)
      start = at(nth_sunday(y, 9, -1), 120 - std_min);
      end = at(nth_sunday(y, 4, 1), 180 - (std_min + 60));
      return t >= start || t < end;
    default: return false;
  }
}

// ---- los países
struct Zone {
  const char* key;    // ES, AR…
  const char* code;   // las dos letras de la bandera
  const char* iana;   // la zona del sistema (solo para las pruebas)
  int std_min;
  Rule rule;
};
const Zone ZONES[] = {
    {"ES", "ES", "Europe/Madrid", 60, R_EU},
    {"ES_CN", "ES", "Atlantic/Canary", 0, R_EU},
    {"AR", "AR", "America/Argentina/Buenos_Aires", -180, R_NONE},
    {"VE", "VE", "America/Caracas", -240, R_NONE},
    {"DO", "DO", "America/Santo_Domingo", -240, R_NONE},
    {"CU", "CU", "America/Havana", -300, R_CUBA},
    {"MX", "MX", "America/Mexico_City", -360, R_NONE},
    {"CO", "CO", "America/Bogota", -300, R_NONE},
    {"PE", "PE", "America/Lima", -300, R_NONE},
    {"EC", "EC", "America/Guayaquil", -300, R_NONE},
    {"CL", "CL", "America/Santiago", -240, R_CHILE},
    {"UY", "UY", "America/Montevideo", -180, R_NONE},
    {"PY", "PY", "America/Asuncion", -180, R_NONE},
    {"BO", "BO", "America/La_Paz", -240, R_NONE},
    {"BR", "BR", "America/Sao_Paulo", -180, R_NONE},
    {"PA", "PA", "America/Panama", -300, R_NONE},
    {"CR", "CR", "America/Costa_Rica", -360, R_NONE},
    {"GT", "GT", "America/Guatemala", -360, R_NONE},
    {"SV", "SV", "America/El_Salvador", -360, R_NONE},
    {"HN", "HN", "America/Tegucigalpa", -360, R_NONE},
    {"NI", "NI", "America/Managua", -360, R_NONE},
    {"PR", "PR", "America/Puerto_Rico", -240, R_NONE},
    {"US_NY", "US", "America/New_York", -300, R_US},
    {"US_MIA", "US", "America/New_York", -300, R_US},
    {"US_CHI", "US", "America/Chicago", -360, R_US},
    {"US_LA", "US", "America/Los_Angeles", -480, R_US},
    {"CA_TOR", "CA", "America/Toronto", -300, R_US},
    {"GB", "GB", "Europe/London", 0, R_EU},
    {"PT", "PT", "Europe/Lisbon", 0, R_EU},
    {"FR", "FR", "Europe/Paris", 60, R_EU},
    {"IT", "IT", "Europe/Rome", 60, R_EU},
    {"DE", "DE", "Europe/Berlin", 60, R_EU},
    {"AE", "AE", "Asia/Dubai", 240, R_NONE},
    {"IN", "IN", "Asia/Kolkata", 330, R_NONE},
    {"CN", "CN", "Asia/Shanghai", 480, R_NONE},
    {"JP", "JP", "Asia/Tokyo", 540, R_NONE},
    {"AU_SYD", "AU", "Australia/Sydney", 600, R_AU},
    {"NZ", "NZ", "Pacific/Auckland", 720, R_NZ},
    {"UTC", "UN", "UTC", 0, R_NONE},
};
const int ZONE_N = (int)(sizeof ZONES / sizeof ZONES[0]);
const char* const DEFAULTS[] = {"ES", "AR", "VE", "DO", "CU"};

int zone_index(const std::string& key) {
  for (int i = 0; i < ZONE_N; i++)
    if (key == ZONES[i].key) return i;
  return -1;
}
// El nombre: «España · Madrid» (traducido; ver la lista NAMES de los textos).
std::string zone_name(int i) {
  auto names = split(tx::ZONE_NAMES, '|');
  return i >= 0 && i < (int)names.size() ? names[(size_t)i] : ZONES[i].key;
}
std::string country_of(int i) {
  std::string n = zone_name(i);
  size_t p = n.find(" · ");
  return p == std::string::npos ? n : n.substr(0, p);
}
// La bandera como emoji (para el menú de macOS): dos letras regionales.
std::string flag(int i) {
  const char* c = ZONES[i].code;
  if (std::strcmp(c, "UN") == 0) return "🌐";
  std::string out;
  for (int k = 0; k < 2; k++) {
    unsigned cp = 0x1F1E6 + (unsigned)(c[k] - 'A');
    char b[8];
    int n = fl_utf8encode(cp, b);
    out.append(b, (size_t)n);
  }
  return out;
}
// La diferencia con UTC, en minutos, en el instante [t].
int offset_min(int i, long long t) {
  const Zone& z = ZONES[i];
  return z.std_min + (is_dst(t, z.rule, z.std_min) ? 60 : 0);
}

struct Clock {
  int y, mo, d, h, mi, s, wd;
};
Clock clock_at(long long t, int off_min) {
  long long lt = t + off_min * 60LL;
  long long days = lt >= 0 ? lt / 86400 : (lt - 86399) / 86400;
  long long sec = lt - days * 86400;
  Clock c;
  civil_from_days(days, c.y, c.mo, c.d);
  c.h = (int)(sec / 3600);
  c.mi = (int)(sec % 3600 / 60);
  c.s = (int)(sec % 60);
  c.wd = weekday(days);
  return c;
}
// La diferencia de este equipo con UTC (la del sistema).
int local_offset_min(long long t) {
  time_t tt = (time_t)t;
  struct tm lo, gm;
#ifdef _WIN32
  localtime_s(&lo, &tt);
  gmtime_s(&gm, &tt);
#else
  localtime_r(&tt, &lo);
  gmtime_r(&tt, &gm);
#endif
  long long a = days_from_civil(lo.tm_year + 1900, lo.tm_mon + 1, lo.tm_mday) * 1440 + lo.tm_hour * 60 + lo.tm_min;
  long long b = days_from_civil(gm.tm_year + 1900, gm.tm_mon + 1, gm.tm_mday) * 1440 + gm.tm_hour * 60 + gm.tm_min;
  return (int)(a - b);
}

std::string two(int v) {
  char b[8];
  std::snprintf(b, sizeof b, "%02d", v);
  return b;
}
std::string time_text(const Clock& c, bool h24, bool secs = false) {
  std::string s;
  if (h24) s = two(c.h) + ":" + two(c.mi);
  else {
    int h = c.h % 12;
    if (h == 0) h = 12;
    s = std::to_string(h) + ":" + two(c.mi);
  }
  if (secs) s += ":" + two(c.s);
  if (!h24) s += std::string(" ") + (c.h < 12 ? tx::AM : tx::PM);
  return s;
}
std::string date_text(const Clock& c) {
  auto wd = split(tx::WEEKDAYS, ',');
  auto mo = split(tx::MONTHS, ',');
  return fmt(tx::DATE, {wd[(size_t)c.wd], std::to_string(c.d), mo[(size_t)(c.mo - 1)]});
}
// «+5 h», «−3 h 30 min», «misma hora».
std::string diff_text(int minutes) {
  if (minutes == 0) return tx::SAME_TIME;
  std::string sign = minutes > 0 ? "+" : "−";
  int a = std::abs(minutes);
  std::string s = sign + std::to_string(a / 60) + " h";
  if (a % 60) s += " " + std::to_string(a % 60) + " min";
  return s;
}
// «hoy», «mañana» o «ayer» respecto a este equipo.
std::string day_rel(const Clock& there, const Clock& here) {
  long long a = days_from_civil(there.y, there.mo, there.d), b = days_from_civil(here.y, here.mo, here.d);
  if (a > b) return tx::TOMORROW;
  if (a < b) return tx::YESTERDAY;
  return "";
}
bool is_day(const Clock& c) { return c.h >= 7 && c.h < 20; }

// ---- los ajustes: los relojes (en orden), los de la barra y el formato
struct Settings {
  std::vector<std::string> clocks;
  std::vector<std::string> in_bar;
  bool h24 = true;
};
Settings defaults() {
  Settings s;
  for (const char* k : DEFAULTS) s.clocks.push_back(k);
  s.in_bar = {"ES"};
  return s;
}
std::string serialize(const Settings& s) {
  std::string o = "h24=" + std::string(s.h24 ? "1" : "0") + "\n";
  for (const auto& k : s.clocks) o += "clock=" + k + "\n";
  for (const auto& k : s.in_bar) o += "bar=" + k + "\n";
  return o;
}
Settings parse(const std::string& text) {
  Settings s;
  bool any = false;
  for (const auto& l : split(text, '\n')) {
    if (l.rfind("h24=", 0) == 0) s.h24 = l.substr(4) != "0";
    else if (l.rfind("clock=", 0) == 0 && zone_index(l.substr(6)) >= 0) { s.clocks.push_back(l.substr(6)); any = true; }
    else if (l.rfind("bar=", 0) == 0 && zone_index(l.substr(4)) >= 0) s.in_bar.push_back(l.substr(4));
  }
  if (!any) {
    Settings d = defaults();
    d.h24 = s.h24;
    return d;
  }
  return s;
}
bool contains(const std::vector<std::string>& v, const std::string& k) { return std::find(v.begin(), v.end(), k) != v.end(); }

std::string config_dir() {
  if (const char* o = fl_getenv("DMS_CLOCKS_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\clocks";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/clocks";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/clocks";
#endif
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[4096];
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

// ---- el texto de la barra: «🇪🇸 17:02  🇨🇺 11:02»
std::string bar_title(const Settings& s, long long t) {
  std::string o;
  for (const auto& k : s.clocks) {
    if (!contains(s.in_bar, k)) continue;
    int i = zone_index(k);
    if (!o.empty()) o += "   ";
    o += flag(i) + " " + time_text(clock_at(t, offset_min(i, t)), s.h24);
  }
  return o;
}

// ---- el menú de la barra (como datos: el de macOS se hace con ellos)
struct MenuEntry {
  std::string title;
  int tag = 0;
  bool enabled = true, checked = false, sep = false;
  std::vector<MenuEntry> sub;
};
enum Act { A_BAR = 1, A_WINDOW = 100, A_TO_BAR = 101, A_H24 = 102, A_QUIT = 103 };
inline int tag(int act, int i) { return act * 1000 + i; }

std::vector<MenuEntry> bar_menu(const Settings& s, long long t, bool window_shown) {
  std::vector<MenuEntry> m;
  Clock here = clock_at(t, local_offset_min(t));
  MenuEntry head;
  head.title = fmt(tx::HERE, {time_text(here, s.h24), date_text(here)});
  head.enabled = false;
  m.push_back(head);
  MenuEntry sep;
  sep.sep = true;
  m.push_back(sep);
  for (size_t n = 0; n < s.clocks.size(); n++) {
    int i = zone_index(s.clocks[n]);
    int off = offset_min(i, t);
    Clock c = clock_at(t, off);
    std::string rel = day_rel(c, here);
    MenuEntry e;
    e.title = flag(i) + "  " + zone_name(i) + "    " + time_text(c, s.h24) + (rel.empty() ? "" : " (" + rel + ")") + "  ·  " +
              diff_text(off - local_offset_min(t));
    e.tag = tag(A_BAR, (int)n);   // clic: mostrarlo u ocultarlo en la barra
    e.checked = contains(s.in_bar, s.clocks[n]);
    m.push_back(e);
  }
  m.push_back(sep);
  MenuEntry h;
  h.title = tx::FORMAT_24;
  h.tag = tag(A_H24, 0);
  h.checked = s.h24;
  m.push_back(h);
  MenuEntry w;
  w.title = window_shown ? tx::TO_BAR : tx::OPEN_WINDOW;
  w.tag = tag(window_shown ? A_TO_BAR : A_WINDOW, 0);
  m.push_back(w);
  MenuEntry q;
  q.title = tx::QUIT;
  q.tag = tag(A_QUIT, 0);
  m.push_back(q);
  return m;
}

// ---- dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(line);
  fl_rounded_rect(x, y, w, h, r);
}
// El texto que cabe en [w] píxeles (con «…»).
std::string fit(const std::string& s, int w) {
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty() && (int)fl_width((t + "…").c_str()) > w) {
    t.pop_back();
    while (!t.empty() && ((unsigned char)t.back() & 0xC0) == 0x80) t.pop_back();
  }
  return t + "…";
}
// La bandera dibujada: las dos letras del país en un rectángulo.
void flag_badge(int x, int y, int i) {
  round_box(x, y, 34, 22, 5, rgb(0x1f2937), rgb(0x1f2937));
  fl_font(FL_HELVETICA_BOLD, 12);
  fl_color(FL_WHITE);
  fl_draw(ZONES[i].code, x, y, 34, 22, FL_ALIGN_CENTER);
}
// Una esfera: las horas, las agujas y, de noche, oscura.
void dial(int cx, int cy, int r, const Clock& c) {
  bool day = is_day(c);
  fl_color(day ? rgb(0xffffff) : rgb(0x1e293b));
  fl_pie(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
  fl_color(day ? rgb(0xd1d5db) : rgb(0x334155));
  fl_line_style(FL_SOLID, 2);
  fl_arc(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
  for (int k = 0; k < 12; k++) {
    double a = k * M_PI / 6;
    int l = k % 3 == 0 ? r / 5 : r / 9;
    fl_color(day ? rgb(0x6b7280) : rgb(0x94a3b8));
    fl_line(cx + (int)((r - 4) * std::sin(a)), cy - (int)((r - 4) * std::cos(a)), cx + (int)((r - 4 - l) * std::sin(a)),
            cy - (int)((r - 4 - l) * std::cos(a)));
  }
  auto hand = [&](double frac, double len, int width, Fl_Color col) {
    double a = frac * 2 * M_PI;
    fl_color(col);
    fl_line_style(FL_SOLID | FL_CAP_ROUND, width);
    fl_line(cx, cy, cx + (int)(len * std::sin(a)), cy - (int)(len * std::cos(a)));
  };
  Fl_Color ink = day ? rgb(0x111827) : rgb(0xf8fafc);
  hand(((c.h % 12) + c.mi / 60.0) / 12.0, r * 0.5, 4, ink);
  hand((c.mi + c.s / 60.0) / 60.0, r * 0.75, 3, ink);
  hand(c.s / 60.0, r * 0.82, 1, rgb(0xef4444));
  fl_line_style(0);
  fl_color(rgb(0xef4444));
  fl_pie(cx - 3, cy - 3, 6, 6, 0, 360);
}

struct Hit {
  int x, y, w, h, act, idx;
};

// Los relojes en tarjetas: esfera, hora, fecha, diferencia y botones.
class ClocksView : public Fl_Widget {
public:
  Settings* set = nullptr;
  long long now = 0;
  int hover = -1, scroll = 0, content_h = 0;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;

  ClocksView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int hit_at(int mx, int my) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (mx >= h.x && mx < h.x + h.w && my >= h.y && my < h.y + h.h) return i;
    }
    return -1;
  }
  int button(int x, int y, const char* text, int act, int idx, Fl_Color fg, bool on) {
    fl_font(FL_HELVETICA_BOLD, 12);
    int w = (int)fl_width(text) + 20, h = 26;
    bool hot = (int)hits.size() == hover;
    hits.push_back({x, y, w, h, act, idx});
    round_box(x, y, w, h, 7, on ? rgb(0xe0ecff) : hot ? rgb(0xeef2f8) : FL_WHITE, on ? rgb(0x93b4f5) : rgb(0xd5dae2));
    fl_color(fg);
    fl_draw(text, x, y, w, h, FL_ALIGN_CENTER);
    return x + w;
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0xf4f6f9));
    fl_rectf(x(), y(), w(), h());
    if (!set) { fl_pop_clip(); return; }
    int here = local_offset_min(now);
    const int CW = 300, CH = 236, G = 16;
    int cols = std::max(1, (w() - G) / (CW + G));
    int x0 = x() + (w() - cols * (CW + G) + G) / 2;
    for (size_t n = 0; n < set->clocks.size(); n++) {
      int i = zone_index(set->clocks[n]);
      int off = offset_min(i, now);
      Clock c = clock_at(now, off);
      int cx = x0 + (int)(n % (size_t)cols) * (CW + G), cy = y() + G - scroll + (int)(n / (size_t)cols) * (CH + G);
      round_box(cx, cy, CW, CH, 16, FL_WHITE, rgb(0xe3e7ee));
      dial(cx + 70, cy + 92, 54, c);
      flag_badge(cx + 150, cy + 22, i);
      fl_font(FL_HELVETICA_BOLD, 15);
      fl_color(rgb(0x1f2937));
      fl_draw(fit(country_of(i), CW - 204).c_str(), cx + 192, cy + 38);
      std::string full = zone_name(i);
      size_t p = full.find(" · ");
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(0x6b7280));
      fl_draw(p == std::string::npos ? "" : full.substr(p + 3).c_str(), cx + 150, cy + 62);
      fl_font(FL_HELVETICA_BOLD, 30);
      fl_color(rgb(0x111827));
      fl_draw(time_text(c, set->h24).c_str(), cx + 150, cy + 104);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(0x374151));
      Clock hc = clock_at(now, here);
      std::string rel = day_rel(c, hc);
      fl_draw((date_text(c) + (rel.empty() ? "" : " · " + rel)).c_str(), cx + 150, cy + 128);
      fl_color(rgb(0x6b7280));
      fl_draw((diff_text(off - here) + "  ·  UTC" + (off >= 0 ? "+" : "−") + std::to_string(std::abs(off) / 60) +
               (std::abs(off) % 60 ? ":" + two(std::abs(off) % 60) : ""))
                  .c_str(),
              cx + 150, cy + 150);
      fl_draw(is_day(c) ? tx::DAY : tx::NIGHT, cx + 20, cy + 176);
      int bx = cx + 20, by = cy + CH - 42;
      bool on = wc::contains(set->in_bar, set->clocks[n]);
      bx = button(bx, by, on ? tx::IN_BAR_ON : tx::IN_BAR_OFF, 1, (int)n, rgb(0x1d4ed8), on) + 6;
      if (n > 0) bx = button(bx, by, "←", 2, (int)n, rgb(0x1f2937), false) + 6;
      if (n + 1 < set->clocks.size()) bx = button(bx, by, "→", 3, (int)n, rgb(0x1f2937), false) + 6;
      button(cx + CW - 20 - 70, by, tx::REMOVE, 4, (int)n, rgb(0xdc2626), false);
    }
    int rows = ((int)set->clocks.size() + cols - 1) / cols;
    content_h = G + rows * (CH + G);
    if (set->clocks.empty()) {
      fl_font(FL_HELVETICA, 15);
      fl_color(rgb(0x6b7280));
      fl_draw(tx::EMPTY, x(), y() + 60, w(), 30, FL_ALIGN_CENTER);
    }
    fl_pop_clip();
  }

  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i != hover) { hover = i; redraw(); }
        window()->cursor(i >= 0 ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        window()->cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_PUSH: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i >= 0 && on_act) on_act(hits[(size_t)i].act, hits[(size_t)i].idx);
        return 1;
      }
      case FL_MOUSEWHEEL:
        scroll = std::max(0, std::min(scroll + Fl::event_dy() * 30, std::max(0, content_h - h())));
        redraw();
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ---- las pruebas
// Compara las reglas con la base de zonas del sistema (en macOS y Linux):
// cada 3 horas de 2025 a 2027, para cada país.
int compare_with_system(int& checked) {
  int bad = 0;
  checked = 0;
#ifndef _WIN32
  const char* old = std::getenv("TZ");
  std::string saved = old ? old : "";
  long long from = days_from_civil(2025, 1, 1) * 86400, to = days_from_civil(2028, 1, 1) * 86400;
  for (int i = 0; i < ZONE_N; i++) {
    setenv("TZ", ZONES[i].iana, 1);
    tzset();
    for (long long t = from; t < to; t += 3 * 3600) {
      int sys = local_offset_min(t), ours = offset_min(i, t);
      checked++;
      if (sys != ours) {
        if (bad < 8) std::printf("FAIL %s %lld: sistema %d, nuestro %d\n", ZONES[i].key, t, sys, ours);
        bad++;
      }
    }
  }
  if (old) setenv("TZ", saved.c_str(), 1);
  else unsetenv("TZ");
  tzset();
#endif
  return bad;
}

int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  int y, m, d;
  civil_from_days(days_from_civil(2026, 11, 11), y, m, d);
  chk(y == 2026 && m == 11 && d == 11, "calendario");
  chk(weekday(days_from_civil(2026, 11, 11)) == 3, "miércoles");
  chk(nth_sunday(2026, 3, -1) == days_from_civil(2026, 3, 29), "último domingo de marzo");
  chk(nth_sunday(2026, 3, 2) == days_from_civil(2026, 3, 8), "segundo domingo de marzo");
  chk(nth_sunday(2026, 11, 1) == days_from_civil(2026, 11, 1), "primer domingo de noviembre");
  // España: 17:02 en invierno y en verano.
  long long winter = days_from_civil(2026, 1, 15) * 86400 + 16 * 3600 + 2 * 60;
  long long summer = days_from_civil(2026, 7, 15) * 86400 + 15 * 3600 + 2 * 60;
  chk(time_text(clock_at(winter, offset_min(zone_index("ES"), winter)), true) == "17:02", "España en invierno");
  chk(time_text(clock_at(summer, offset_min(zone_index("ES"), summer)), true) == "17:02", "España en verano");
  chk(offset_min(zone_index("CU"), summer) == -240 && offset_min(zone_index("CU"), winter) == -300, "Cuba");
  long long nov26 = days_from_civil(2026, 11, 11) * 86400 + 12 * 3600;
  chk(offset_min(zone_index("CU"), nov26) == -240, "Cuba sigue en verano en noviembre de 2026");
  chk(offset_min(zone_index("AR"), summer) == -180, "Argentina");
  chk(offset_min(zone_index("CL"), winter) == -180 && offset_min(zone_index("CL"), summer) == -240, "Chile (al revés)");
  chk(time_text(clock_at(winter, 60), false) == std::string("5:02 ") + tx::PM, "12 horas");
  chk(diff_text(-300) == "−5 h" && diff_text(330) == "+5 h 30 min" && diff_text(0) == tx::SAME_TIME, "diferencias");
  chk(flag(zone_index("ES")) == "🇪🇸", "bandera");
  // Ajustes.
  Settings s = defaults();
  chk(s.clocks.size() == 5 && s.clocks[4] == "CU" && s.in_bar.size() == 1, "por defecto");
  s.h24 = false;
  s.in_bar.push_back("CU");
  Settings r = parse(serialize(s));
  chk(!r.h24 && r.clocks == s.clocks && r.in_bar == s.in_bar, "guardar y leer");
  chk(parse("").clocks.size() == 5, "sin archivo, los de siempre");
  chk(parse("clock=XX\nclock=JP\n").clocks.size() == 1, "países que no existen");
  std::string bt = bar_title(r, winter);
  chk(bt.find("🇪🇸") != std::string::npos && bt.find("🇨🇺") != std::string::npos, "título de la barra");
  auto menu = bar_menu(r, winter, false);
  chk(menu.size() == 2 + 5 + 4 && menu[2].checked && !menu[3].checked && menu[6].checked, "menú de la barra");
  int checked = 0;
  int bad = compare_with_system(checked);
  std::printf("zonas: %d horas comparadas con el sistema, %d distintas\n", checked, bad);
  chk(bad == 0, "las reglas coinciden con el sistema");
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace wc

// ============================================================ la barra de menús
// En macOS, un NSStatusItem hecho desde C++ con el runtime de Objective-C:
// las horas elegidas con su bandera y un menú con todas.
namespace bar {
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

inline std::function<void(int)>& handler() {
  static std::function<void(int)> h;
  return h;
}
void on_act(id, SEL, id sender) {
  long t = msg<long>(sender, "tag");
  if (handler()) handler()((int)t);
}
id target() {
  static id t = nullptr;
  if (!t) {
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsWorldClocksTarget", 0);
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
bool create() {
  Pool pool;
  id sb = msg(cls("NSStatusBar"), "systemStatusBar");
  if (!sb) return false;
  id it = msg<id, double>(sb, "statusItemWithLength:", -1.0);
  if (!it) return false;
  msg(it, "retain");
  item() = it;
  return true;
}
// Sin relojes en la barra, el símbolo del reloj del sistema.
void set(const std::string& title) {
  if (!item()) return;
  Pool pool;
  id b = msg(item(), "button");
  if (!b) return;
  id img = nullptr;
  if (title.empty() &&
      class_getClassMethod((Class)objc_getClass("NSImage"), sel_registerName("imageWithSystemSymbolName:accessibilityDescription:")))
    img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str("clock"), str("clock"));
  if (img) msg<void, BOOL>(img, "setTemplate:", YES);
  msg<void, id>(b, "setImage:", img);
  msg<void, id>(b, "setTitle:", str(title));
}
id build(const std::vector<wc::MenuEntry>& entries) {
  id m = msg(msg(cls("NSMenu"), "alloc"), "init");
  msg<void, BOOL>(m, "setAutoenablesItems:", NO);
  for (const auto& e : entries) {
    if (e.sep) {
      msg<void, id>(m, "addItem:", msg(cls("NSMenuItem"), "separatorItem"));
      continue;
    }
    SEL action = e.tag ? sel_registerName("dmsAct:") : (SEL) nullptr;
    id it = msg<id, id, SEL, id>(msg(cls("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", str(e.title), action, str(""));
    msg<void, id>(it, "setTarget:", target());
    msg<void, long>(it, "setTag:", (long)e.tag);
    msg<void, BOOL>(it, "setEnabled:", e.enabled ? YES : NO);
    if (e.checked) msg<void, long>(it, "setState:", 1L);
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
  return m;
}
void menu(const std::vector<wc::MenuEntry>& entries) {
  if (!item()) return;
  Pool pool;
  id m = build(entries);
  msg<void, id>(item(), "setMenu:", m);
  msg<void>(m, "release");
}
void dock(bool visible) {
  Pool pool;
  id app = msg(cls("NSApplication"), "sharedApplication");
  msg<void, long>(app, "setActivationPolicy:", visible ? 0L : 1L);
  if (visible) msg<void, BOOL>(app, "activateIgnoringOtherApps:", YES);
}
void remove() {
  if (!item()) return;
  Pool pool;
  msg<void, id>(msg(cls("NSStatusBar"), "systemStatusBar"), "removeStatusItem:", item());
  msg<void>(item(), "release");
  item() = nullptr;
}
#else
inline std::function<void(int)>& handler() {
  static std::function<void(int)> h;
  return h;
}
bool available() { return false; }
bool create() { return false; }
void set(const std::string&) {}
void menu(const std::vector<wc::MenuEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  wc::Settings set;
  wc::ClocksView* view = nullptr;
  bool in_bar = false, quitting = false;
  long long fixed_now = 0;   // las capturas: una hora fija
  bool demo = false;         // las capturas y las pruebas no guardan nada
  std::string last_menu;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_CLOCKS_SELFTEST")) std::exit(wc::selftest());
    if (fl_getenv("DMS_CLOCKS_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_CLOCKS_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
  long long now() const { return fixed_now ? fixed_now : (long long)std::time(nullptr); }

  void setup() {
    self() = this;
    BoardHint->hide();
    Board->box(FL_FLAT_BOX);
    Top->resizable(nullptr);
    resizable(Board);
    view = new wc::ClocksView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    view->set = &set;
    view->on_act = [](int act, int n) { if (self()) self()->card_act(act, n); };
    std::vector<std::string> names;
    for (int i = 0; i < wc::ZONE_N; i++) names.push_back(wc::zone_name(i));
    Zone->items(names);
    Zone->index(wc::zone_index("MX"));
    Format->items({tx::FMT_24, tx::FMT_12});
    // El botón de cerrar esconde la ventana en la barra; un cierre desde el
    // código (el menú Idioma de las demos) cierra de verdad.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE && bar::available()) self()->to_bar();
      else self()->close_for_good();
    });
  }

  void form_create() override {
    set_fonts();
    setup();
    load();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    else BtnBar->copy_label(tx::MINIMIZE);
    refresh();
  }
  void form_close() override { save(); }

  std::string data_file() const { return wc::config_dir() + "/clocks.txt"; }
  void load() {
    std::string text;
    set = wc::read_file(data_file(), text) ? wc::parse(text) : wc::defaults();
    Format->index(set.h24 ? 0 : 1);
  }
  void save() {
    if (demo) return;
    fl_make_path(wc::config_dir().c_str());
    wc::write_file(data_file(), wc::serialize(set));
  }

  void refresh() {
    long long t = now();
    view->now = t;
    view->redraw();
    wc::Clock here = wc::clock_at(t, wc::local_offset_min(t));
    Status->text(" " + wc::fmt(tx::STATUS, {wc::time_text(here, set.h24, true), std::to_string(set.clocks.size())}));
    if (bar::available()) {
      bar::set(wc::bar_title(set, t));
      // El menú se rehace solo cuando cambia (cada minuto).
      auto m = wc::bar_menu(set, t, shown() && !in_bar);
      std::string sig;
      for (const auto& e : m) sig += e.title + (e.checked ? "*" : "") + "\n";
      if (sig != last_menu) {
        last_menu = sig;
        bar::menu(m);
      }
    }
  }

  void to_bar() {
    if (!bar::available()) { iconize(); return; }
    if (in_bar) return;
    save();
    in_bar = true;
    hide();
    bar::dock(false);
    refresh();
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
  void close_for_good() {
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
    save();
    bar::remove();
    hide();
    std::exit(0);
  }

  void toggle_bar(int n) {
    if (n < 0 || n >= (int)set.clocks.size()) return;
    const std::string& k = set.clocks[(size_t)n];
    auto it = std::find(set.in_bar.begin(), set.in_bar.end(), k);
    if (it == set.in_bar.end()) set.in_bar.push_back(k);
    else set.in_bar.erase(it);
    save();
    refresh();
  }
  void bar_act(int t) {
    int act = t / 1000, n = t % 1000;
    switch (act) {
      case wc::A_BAR: toggle_bar(n); break;
      case wc::A_H24:
        set.h24 = !set.h24;
        Format->index(set.h24 ? 0 : 1);
        save();
        refresh();
        break;
      case wc::A_WINDOW: from_bar(); break;
      case wc::A_TO_BAR: to_bar(); break;
      case wc::A_QUIT: quit(); break;
    }
  }
  void card_act(int act, int n) {
    if (n < 0 || n >= (int)set.clocks.size()) return;
    if (act == 1) { toggle_bar(n); return; }
    if (act == 2 && n > 0) std::swap(set.clocks[(size_t)n], set.clocks[(size_t)n - 1]);
    if (act == 3 && n + 1 < (int)set.clocks.size()) std::swap(set.clocks[(size_t)n], set.clocks[(size_t)n + 1]);
    if (act == 4) {
      std::string k = set.clocks[(size_t)n];
      set.clocks.erase(set.clocks.begin() + n);
      set.in_bar.erase(std::remove(set.in_bar.begin(), set.in_bar.end(), k), set.in_bar.end());
    }
    save();
    refresh();
  }
  bool add_zone(int i) {
    if (i < 0 || i >= wc::ZONE_N) return false;
    if (wc::contains(set.clocks, wc::ZONES[i].key)) return false;
    set.clocks.push_back(wc::ZONES[i].key);
    save();
    refresh();
    return true;
  }

  // ---- eventos del diseño
  void BtnAdd_click() override { add_zone(Zone->index()); }
  void BtnBar_click() override { to_bar(); }
  void Format_select() override {
    set.h24 = Format->index() != 1;
    save();
    refresh();
  }
  void Tick_timer() override { refresh(); }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_RESET) {
      set = wc::defaults();
      save();
      refresh();
    } else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
  }

  // ---- capturas y pruebas sin ventana
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
    demo = true;
    setup();
    size(W, H);
    set = wc::defaults();
    set.in_bar = {"ES", "CU"};
    Format->index(0);
    // El 11 de noviembre de 2026 a las 17:02:24 en España.
    fixed_now = wc::days_from_civil(2026, 11, 11) * 86400 + 16 * 3600 + 2 * 60 + 24;
    refresh();
  }
  static int draw_menu(int x, int y, const std::vector<wc::MenuEntry>& m, int hi) {
    const int rowh = 34, seph = 12;
    fl_font(FL_HELVETICA, 16);
    int w = 300, h = 12;
    for (const auto& e : m) {
      w = std::max(w, (int)fl_width(e.title.c_str()) + 60);
      h += e.sep ? seph : rowh;
    }
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(40 - 4 * k), (uchar)(52 - 4 * k), (uchar)(80 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, w + 2 * k, h + 2 * k, 14 + k);
    }
    wc::round_box(x, y, w, h, 14, wc::rgb(0xf3f3f5), wc::rgb(0xc4c4ca));
    int yy = y + 6;
    for (int i = 0; i < (int)m.size(); i++) {
      const auto& e = m[(size_t)i];
      if (e.sep) {
        fl_color(wc::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + w - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      Fl_Color col = e.enabled ? wc::rgb(0x1d1d1f) : wc::rgb(0x8e8e93);
      if (i == hi) {
        fl_color(wc::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, w - 12, rowh, 8);
        col = FL_WHITE;
      }
      if (e.checked) {
        fl_color(col);
        fl_font(FL_HELVETICA_BOLD, 15);
        fl_draw("✓", x + 12, yy + 23);
      }
      fl_font(FL_HELVETICA, 16);
      fl_color(col);
      fl_draw(e.title.c_str(), x + 34, yy + 23);
      yy += rowh;
    }
    return x + w;
  }
  void desk(const std::string& file, int hi) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(30 + 160 * t), (uchar)(70 + 60 * t), (uchar)(110 - 20 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(wc::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(wc::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    std::string title = wc::bar_title(set, now());
    fl_font(FL_HELVETICA, 16);
    int iw = (int)fl_width(title.c_str()) + 20, ix = W - 900;
    fl_color(wc::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 10, 5, iw, BarH - 10, 8);
    fl_color(wc::rgb(0x1d1d1f));
    fl_draw(title.c_str(), ix, 26);
    draw_menu(ix - 10, BarH + 4, wc::bar_menu(set, now(), false), hi);
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1600, 1000);
    render_to(dir + "/window.png");
    desk(dir + "/menu.png", -1);
    desk(dir + "/menu-pick.png", 4);
    Zone->index(wc::zone_index("MX"));
    add_zone(wc::zone_index("MX"));
    add_zone(wc::zone_index("US_MIA"));
    render_to(dir + "/added.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1100, 720);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(set.clocks.size() == 5, "los cinco de siempre");
    Zone->index(wc::zone_index("JP"));
    BtnAdd_click();
    chk(set.clocks.size() == 6 && set.clocks.back() == "JP", "añadir Japón");
    BtnAdd_click();
    chk(set.clocks.size() == 6, "no repetir");
    Format->index(1);
    Format_select();
    chk(!set.h24, "formato de 12 horas");
    render_to("");
    chk(view->hits.size() >= set.clocks.size() * 2, "dibujado");
    // Clic de verdad en «En la barra» del segundo reloj y en «Quitar» del último.
    auto click = [&](int act, int idx) {
      for (const auto& h : view->hits)
        if (h.act == act && h.idx == idx) {
          Fl::e_x = h.x + h.w / 2;
          Fl::e_y = h.y + h.h / 2;
          view->handle(FL_PUSH);
          render_to("");
          return true;
        }
      return false;
    };
    chk(click(1, 1) && wc::contains(set.in_bar, "AR"), "clic: Argentina en la barra");
    chk(click(2, 1) && set.clocks[0] == "AR", "clic: mover a la izquierda");
    chk(click(4, 5) && set.clocks.size() == 5 && !wc::contains(set.clocks, "JP"), "clic: quitar");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
