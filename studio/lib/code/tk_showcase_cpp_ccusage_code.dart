part of 'tk_examples.dart';

// El código en C++ de Uso de Claude Code (tk_showcase_cpp_ccusage.dart): va
// tal cual en Form1.cpp, después de los textos (namespace tx).
const _ccUsageIncludes = r'''#include <algorithm>
#include <array>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <thread>
#include <tuple>
#include <unordered_set>
#include <utility>
#include <vector>
#include <sys/stat.h>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <sys/wait.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _ccUsageCode = r'''
// ============================================================ lo básico
// El uso de Claude Code, día a día: los tokens, lo que cuestan y las
// sesiones. Sale de dos sitios: los registros que Claude Code guarda en el
// equipo (~/.claude/projects, sirve con cualquier plan) o la API de
// administración de Anthropic (la de Claude Code Analytics, con una clave
// sk-ant-admin de una organización de Claude Console).
namespace cu {

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
std::string trim(const std::string& s) {
  size_t a = s.find_first_not_of(" \t\r\n"), b = s.find_last_not_of(" \t\r\n");
  return a == std::string::npos ? "" : s.substr(a, b - a + 1);
}
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
bool starts(const std::string& s, const std::string& p) { return s.size() >= p.size() && s.compare(0, p.size(), p) == 0; }
bool ends(const std::string& s, const std::string& p) {
  return s.size() >= p.size() && s.compare(s.size() - p.size(), p.size(), p) == 0;
}
bool has(const std::string& s, const std::string& p) { return s.find(p) != std::string::npos; }
long long now_t() { return (long long)std::time(nullptr); }
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
// Sin tabuladores ni saltos (van en archivos de una línea por fila).
std::string clean(std::string s) {
  for (auto& c : s)
    if (c == '\t' || c == '\n' || c == '\r') c = ' ';
  return trim(s);
}

// ------------------------------------------------------------ números
// Con el separador decimal y el de miles del idioma de la interfaz.
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, std::fabs(v));
  std::string s = b, ip = s, fr;
  size_t dot = s.find('.');
  if (dot != std::string::npos) { ip = s.substr(0, dot); fr = s.substr(dot + 1); }
  std::string out;
  bool zero = s.find_first_of("123456789") == std::string::npos;
  if (v < 0 && !zero) out = "-";
  int n = (int)ip.size();
  for (int i = 0; i < n; i++) {
    out += ip[(size_t)i];
    int left = n - 1 - i;
    if (left > 0 && left % 3 == 0) out += tx::THOUSANDS;
  }
  if (!fr.empty()) out += std::string(tx::DEC) + fr;
  return out;
}
// Dólares: «12,34 $» (o «$12.34» en inglés); sin céntimos desde mil.
std::string money(double usd) {
  if (std::fabs(usd) >= 1000) return fmt(tx::MONEY, {num(usd, 0)});
  return fmt(tx::MONEY, {num(usd, 2)});
}
// «980», «12,3 k», «4,5 M», «1,2 mil M».
std::string tokens(double n) {
  if (n < 1000) return num(n, 0);
  if (n < 1e6) return fmt(tx::TOK_K, {num(n / 1e3, n < 1e4 ? 1 : 0)});
  if (n < 1e9) return fmt(tx::TOK_M, {num(n / 1e6, n < 1e7 ? 1 : 0)});
  return fmt(tx::TOK_B, {num(n / 1e9, n < 1e10 ? 1 : 0)});
}
std::string bytes(double n) {
  if (n < 1e6) return fmt(tx::SIZE_KB, {num(n / 1e3, 0)});
  if (n < 1e9) return fmt(tx::SIZE_MB, {num(n / 1e6, 0)});
  return fmt(tx::SIZE_GB, {num(n / 1e9, 1)});
}

// ------------------------------------------------------------ fechas
// Un día es un número: los días desde el 1-1-1970.
long long days_from_civil(int y, unsigned m, unsigned d) {
  y -= m <= 2;
  const long long era = (y >= 0 ? y : y - 399) / 400;
  const unsigned yoe = (unsigned)(y - era * 400);
  const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
  const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + (long long)doe - 719468;
}
void civil_from_days(long long z, int& y, unsigned& m, unsigned& d) {
  z += 719468;
  const long long era = (z >= 0 ? z : z - 146096) / 146097;
  const unsigned doe = (unsigned)(z - era * 146097);
  const unsigned yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  const long long yy = (long long)yoe + era * 400;
  const unsigned doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  const unsigned mp = (5 * doy + 2) / 153;
  d = doy - (153 * mp + 2) / 5 + 1;
  m = mp < 10 ? mp + 3 : mp - 9;
  y = (int)(yy + (m <= 2));
}
// El día de una fecha en la hora del equipo.
int local_day(long long t) {
  std::time_t tt = (std::time_t)t;
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  return (int)days_from_civil(v.tm_year + 1900, (unsigned)v.tm_mon + 1, (unsigned)v.tm_mday);
}
int today() { return local_day(now_t()); }
int utc_day(long long t) { return (int)(t >= 0 ? t / 86400 : (t - 86399) / 86400); }
// 0 = lunes … 6 = domingo (el 1-1-1970 fue jueves).
int weekday(int day) { return ((day + 3) % 7 + 7) % 7; }
// «2026-11-13T23:46:40.503Z» → segundos (UTC); -1 si no es una fecha.
long long parse_iso(const std::string& s) {
  int y, mo, d, h = 0, mi = 0, se = 0;
  if (s.size() < 10 || std::sscanf(s.c_str(), "%4d-%2d-%2d", &y, &mo, &d) != 3) return -1;
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return -1;
  if (s.size() >= 19 && (s[10] == 'T' || s[10] == ' ')) std::sscanf(s.c_str() + 11, "%2d:%2d:%2d", &h, &mi, &se);
  long long t = days_from_civil(y, (unsigned)mo, (unsigned)d) * 86400 + h * 3600 + mi * 60 + se;
  // «+01:00» o «-05:00» al final.
  if (s.size() >= 25) {
    char sign = s[s.size() - 6];
    int oh = 0, om = 0;
    if ((sign == '+' || sign == '-') && s[s.size() - 3] == ':' &&
        std::sscanf(s.c_str() + s.size() - 5, "%2d:%2d", &oh, &om) == 2)
      t -= (sign == '+' ? 1 : -1) * (oh * 3600 + om * 60);
  }
  return t;
}
std::string iso_day(int day) {
  int y;
  unsigned m, d;
  civil_from_days(day, y, m, d);
  char b[16];
  std::snprintf(b, sizeof b, "%04d-%02u-%02u", y, m, d);
  return b;
}
const char* wd_short(int i) {
  static const char* const n[] = {tx::WD_1, tx::WD_2, tx::WD_3, tx::WD_4, tx::WD_5, tx::WD_6, tx::WD_7};
  return n[((i % 7) + 7) % 7];
}
const char* wd_long(int i) {
  static const char* const n[] = {tx::WDL_1, tx::WDL_2, tx::WDL_3, tx::WDL_4, tx::WDL_5, tx::WDL_6, tx::WDL_7};
  return n[((i % 7) + 7) % 7];
}
const char* mon_short(unsigned m) {
  static const char* const n[] = {tx::MON_1, tx::MON_2, tx::MON_3, tx::MON_4, tx::MON_5, tx::MON_6,
                                  tx::MON_7, tx::MON_8, tx::MON_9, tx::MON_10, tx::MON_11, tx::MON_12};
  return n[(m - 1) % 12];
}
const char* mon_long(unsigned m) {
  static const char* const n[] = {tx::MONL_1, tx::MONL_2, tx::MONL_3, tx::MONL_4, tx::MONL_5, tx::MONL_6,
                                  tx::MONL_7, tx::MONL_8, tx::MONL_9, tx::MONL_10, tx::MONL_11, tx::MONL_12};
  return n[(m - 1) % 12];
}
// «lun 9 nov».
std::string day_short(int day) {
  int y;
  unsigned m, d;
  civil_from_days(day, y, m, d);
  return fmt(tx::DAY_SHORT, {wd_short(weekday(day)), std::to_string(d), mon_short(m)});
}
// «jueves, 13 de noviembre de 2026».
std::string day_long(int day) {
  int y;
  unsigned m, d;
  civil_from_days(day, y, m, d);
  return fmt(tx::DAY_LONG, {wd_long(weekday(day)), std::to_string(d), mon_long(m), std::to_string(y)});
}
int month_start(int day) {
  int y;
  unsigned m, d;
  civil_from_days(day, y, m, d);
  return (int)days_from_civil(y, m, 1);
}
int year_start(int day) {
  int y;
  unsigned m, d;
  civil_from_days(day, y, m, d);
  return (int)days_from_civil(y, 1, 1);
}

// ------------------------------------------------------------ precios
// Lo que cuesta un millón de tokens de cada modelo en la API (USD): entrada,
// escritura en la caché de 5 minutos y de 1 hora, lectura de la caché y salida.
// Con un plan Pro o Max no se paga así: es lo que costaría con la API.
struct Price {
  double in, w5, w1, cr, out;
};
Price price_of(const std::string& model, double prompt_tokens = 0) {
  std::string m = lower(model);
  auto is = [&](const char* k) { return m.find(k) != std::string::npos; };
  if (is("fable-5-2") || is("mythos-5-2")) return {8, 10, 16, 0.20, 40};
  if (is("fable-5-1") || is("mythos-5-1")) return {10, 12.5, 20, 0.25, 50};
  if (is("fable") || is("mythos")) return {10, 12.5, 20, 1, 50};
  if (is("opus-5-5")) return {4, 5, 8, 0.20, 20};
  if (is("opus-4-1") || is("opus-4-0") || is("opus-4-2025") || m == "claude-opus-4" || is("3-opus"))
    return {15, 18.75, 30, 1.5, 75};
  if (is("opus")) return {5, 6.25, 10, 0.5, 25};   // Opus 5, 4.8, 4.7, 4.6 y 4.5
  if (is("sonnet-5-5")) return {2, 2.5, 4, 0.10, 10};
  if (is("sonnet-5")) return {2, 2.5, 4, 0.20, 10};
  if (is("sonnet")) return {3, 3.75, 6, 0.30, 15};
  if (is("haiku-5-5")) {
    if (prompt_tokens > 100000) return {0.5, 0.625, 1, 0.05, 2.5};
    return {0.10, 0.125, 0.20, 0.01, 0.50};
  }
  if (is("haiku-4-5")) return {1, 1.25, 2, 0.10, 5};
  if (is("haiku-3-5") || is("3-5-haiku")) return {0.8, 1, 1.6, 0.08, 4};
  if (is("haiku")) return {0.25, 0.3, 0.5, 0.03, 1.25};
  return {3, 3.75, 6, 0.30, 15};
}

struct Tok {
  double in = 0, out = 0, w5 = 0, w1 = 0, cr = 0;
  double total() const { return in + out + w5 + w1 + cr; }
  double prompt() const { return in + w5 + w1 + cr; }
  void add(const Tok& o) { in += o.in; out += o.out; w5 += o.w5; w1 += o.w1; cr += o.cr; }
};
// Lo que cuesta un mensaje (el modo rápido cuesta el doble).
double cost_of(const std::string& model, const Tok& t, bool fast) {
  Price p = price_of(model, t.prompt());
  double c = (t.in * p.in + t.w5 * p.w5 + t.w1 * p.w1 + t.cr * p.cr + t.out * p.out) / 1e6;
  return fast ? c * 2 : c;
}
// «claude-opus-5-5-20260101» → «Opus 5.5».
std::string model_name(const std::string& id) {
  std::string m = lower(id);
  if (starts(m, "claude-")) m = m.substr(7);
  std::vector<std::string> parts = split(m, '-');
  std::string family, ver;
  for (const auto& p : parts) {
    if (p.empty()) continue;
    if (std::isdigit((unsigned char)p[0])) {
      if (p.size() >= 8) break;   // la fecha
      ver += (ver.empty() ? "" : ".") + p;
    } else if (family.empty()) {
      family = p;
    }
  }
  if (family.empty()) return id;
  family[0] = (char)std::toupper((unsigned char)family[0]);
  return ver.empty() ? family : family + " " + ver;
}

// ------------------------------------------------------------ los datos
// Lo de un día, un modelo y un proyecto (o un usuario, con la API).
struct Agg {
  Tok t;
  double cost = 0;
  long long msgs = 0, sessions = 0, added = 0, removed = 0, commits = 0, prs = 0;
  void add(const Agg& o) {
    t.add(o.t);
    cost += o.cost;
    msgs += o.msgs;
    sessions += o.sessions;
    added += o.added;
    removed += o.removed;
    commits += o.commits;
    prs += o.prs;
  }
  bool active() const { return msgs > 0 || sessions > 0 || cost > 0 || t.total() > 0; }
};
struct Key {
  int day = 0;
  std::string model, group;
  bool operator<(const Key& o) const { return std::tie(day, model, group) < std::tie(o.day, o.model, o.group); }
};
using Rows = std::map<Key, Agg>;

enum Metric { M_COST = 0, M_TOKENS = 1, M_SESSIONS = 2 };
double metric(const Agg& a, int m) {
  if (m == M_TOKENS) return a.t.total();
  if (m == M_SESSIONS) return (double)a.sessions;
  return a.cost;
}
std::string metric_text(double v, int m) {
  if (m == M_TOKENS) return fmt(tx::TOKENS_N, {tokens(v)});
  if (m == M_SESSIONS) return fmt(v == 1 ? tx::SESSIONS_ONE : tx::SESSIONS_N, {num(v, 0)});
  return money(v);
}

std::map<int, Agg> by_day(const Rows& rows) {
  std::map<int, Agg> out;
  for (const auto& r : rows) out[r.first.day].add(r.second);
  return out;
}
Agg total(const Rows& rows, int a, int b) {
  Agg out;
  for (const auto& r : rows)
    if (r.first.day >= a && r.first.day <= b) out.add(r.second);
  return out;
}
// Por modelo (by_group = false) o por proyecto/usuario, de más a menos coste.
std::vector<std::pair<std::string, Agg>> grouped(const Rows& rows, int a, int b, bool by_group, int m) {
  std::map<std::string, Agg> g;
  for (const auto& r : rows)
    if (r.first.day >= a && r.first.day <= b) g[by_group ? r.first.group : r.first.model].add(r.second);
  std::vector<std::pair<std::string, Agg>> out(g.begin(), g.end());
  std::stable_sort(out.begin(), out.end(), [m](const auto& x, const auto& y) {
    double vx = metric(x.second, m), vy = metric(y.second, m);
    if (vx != vy) return vx > vy;
    return x.second.cost > y.second.cost;
  });
  return out;
}

// Los periodos de las tablas.
enum Period { P_TODAY = 0, P_WEEK = 1, P_30 = 2, P_MONTH = 3, P_YEAR = 4, P_ALL = 5 };
void period_range(int p, int today, int& a, int& b) {
  b = today;
  switch (p) {
    case P_TODAY: a = today; break;
    case P_WEEK: a = today - 6; break;
    case P_MONTH: a = month_start(today); break;
    case P_YEAR: a = year_start(today); break;
    case P_ALL: a = -1000000; break;
    default: a = today - 29;
  }
}

// La racha: días seguidos con uso hasta hoy (o hasta ayer, si hoy aún no).
struct Streak {
  int current = 0, best = 0;
};
Streak streaks(const std::map<int, Agg>& days, int today) {
  Streak s;
  int run = 0, prev = 0;
  bool first = true;
  for (const auto& d : days) {
    if (d.first > today || !d.second.active()) continue;
    run = (!first && d.first == prev + 1) ? run + 1 : 1;
    first = false;
    prev = d.first;
    s.best = std::max(s.best, run);
  }
  auto on = [&](int day) {
    auto it = days.find(day);
    return it != days.end() && it->second.active();
  };
  int d = on(today) ? today : today - 1;
  while (on(d)) { s.current++; d--; }
  return s;
}

// Los cuatro tonos del mapa de calor (como GitHub): por cuartiles de los días con uso.
std::array<double, 3> quartiles(std::vector<double> v) {
  std::array<double, 3> q{0, 0, 0};
  v.erase(std::remove_if(v.begin(), v.end(), [](double x) { return x <= 0; }), v.end());
  if (v.empty()) return q;
  std::sort(v.begin(), v.end());
  for (int k = 0; k < 3; k++) q[(size_t)k] = v[(size_t)std::min(v.size() - 1, (size_t)((k + 1) * v.size() / 4))];
  return q;
}
int level(double v, const std::array<double, 3>& q) {
  if (v <= 0) return 0;
  if (v <= q[0]) return 1;
  if (v <= q[1]) return 2;
  if (v <= q[2]) return 3;
  return 4;
}

// ------------------------------------------------------------ archivos
std::string home() {
#ifdef _WIN32
  const char* h = fl_getenv("USERPROFILE");
#else
  const char* h = fl_getenv("HOME");
#endif
  return h ? h : ".";
}
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_CCUSAGE_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\ccusage";
#elif defined(__APPLE__)
  return home() + "/Library/Application Support/DMarlon Studio Demos/ccusage";
#else
  return home() + "/.config/DMarlon Studio Demos/ccusage";
#endif
}
// Dónde guarda Claude Code sus conversaciones: una carpeta por proyecto y un
// .jsonl por sesión (con los subagentes en subcarpetas).
std::vector<std::string> default_log_dirs() {
  std::vector<std::string> out;
  if (const char* o = fl_getenv("DMS_CCUSAGE_LOGS")) {
    out.push_back(o);
    return out;
  }
  if (const char* c = fl_getenv("CLAUDE_CONFIG_DIR"))
    for (const auto& p : split(c, ','))
      if (!trim(p).empty()) out.push_back(trim(p) + "/projects");
  out.push_back(home() + "/.claude/projects");
  out.push_back(home() + "/.config/claude/projects");
  return out;
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[65536];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  std::fclose(f);
  return true;
}
// Para lo privado (la clave): solo lo lee su dueño.
void private_file(const std::string& path) {
#ifndef _WIN32
  chmod(path.c_str(), 0600);
#else
  (void)path;
#endif
}
bool write_file(const std::string& path, const std::string& data, bool secret = false) {
  std::string tmp = path + ".tmp";
  FILE* f = fl_fopen(tmp.c_str(), "wb");
  if (!f) return false;
  if (secret) private_file(tmp);
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  ok = std::fclose(f) == 0 && ok;
  if (ok) {
    std::remove(path.c_str());
    ok = std::rename(tmp.c_str(), path.c_str()) == 0;
  }
  return ok;
}
long long file_size(const std::string& path) {
  struct stat st;
  if (fl_stat(path.c_str(), &st) != 0) return -1;
  return (long long)st.st_size;
}
bool is_dir(const std::string& path) { return fl_filename_isdir(path.c_str()) != 0; }

uint64_t hash64(const std::string& s) {
  uint64_t h = 1469598103934665603ULL;
  for (unsigned char c : s) { h ^= c; h *= 1099511628211ULL; }
  return h;
}

// ------------------------------------------------------------ JSON
// Los registros pesan gigas: cada línea se recorre sin copiarla, leyendo solo
// las claves que interesan y saltando el resto (el texto de la conversación).
class Lite {
public:
  Lite(const char* b, const char* e) : p(b), end(e) {}
  const char* p;
  const char* end;
  void ws() {
    while (p < end && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
  }
  static void utf8(std::string& o, unsigned c) {
    if (c < 0x80) o += (char)c;
    else if (c < 0x800) { o += (char)(0xc0 | (c >> 6)); o += (char)(0x80 | (c & 63)); }
    else { o += (char)(0xe0 | (c >> 12)); o += (char)(0x80 | ((c >> 6) & 63)); o += (char)(0x80 | (c & 63)); }
  }
  bool str(std::string* out) {
    ws();
    if (p >= end || *p != '"') return false;
    p++;
    while (p < end) {
      char c = *p++;
      if (c == '"') return true;
      if (c != '\\') {
        if (out) *out += c;
        continue;
      }
      if (p >= end) return false;
      char e = *p++;
      if (e == 'u') {
        if (end - p < 4) return false;
        unsigned v = 0;
        for (int k = 0; k < 4; k++) {
          char h = *p++;
          v <<= 4;
          if (h >= '0' && h <= '9') v |= (unsigned)(h - '0');
          else if (h >= 'a' && h <= 'f') v |= (unsigned)(h - 'a' + 10);
          else if (h >= 'A' && h <= 'F') v |= (unsigned)(h - 'A' + 10);
          else return false;
        }
        if (out) utf8(*out, v >= 0xd800 && v < 0xe000 ? '?' : v);
        continue;
      }
      if (!out) continue;
      switch (e) {
        case 'n': *out += '\n'; break;
        case 't': *out += '\t'; break;
        case 'r': *out += '\r'; break;
        case 'b': case 'f': break;
        default: *out += e;
      }
    }
    return false;
  }
  bool number(double* v) {
    ws();
    const char* s = p;
    while (p < end && (std::isdigit((unsigned char)*p) || *p == '-' || *p == '+' || *p == '.' || *p == 'e' || *p == 'E')) p++;
    if (p == s) return false;
    if (v) *v = std::strtod(std::string(s, p).c_str(), nullptr);
    return true;
  }
  bool skip() {
    ws();
    if (p >= end) return false;
    char c = *p;
    if (c == '"') return str(nullptr);
    if (c == '{' || c == '[') {
      int depth = 0;
      while (p < end) {
        char d = *p;
        if (d == '"') {
          if (!str(nullptr)) return false;
          continue;
        }
        p++;
        if (d == '{' || d == '[') depth++;
        else if ((d == '}' || d == ']') && --depth == 0) return true;
      }
      return false;
    }
    const char* s = p;
    while (p < end && *p != ',' && *p != '}' && *p != ']' && !std::isspace((unsigned char)*p)) p++;
    return p > s;
  }
  // Un objeto: [on] lee el valor de las claves que quiere (true); las demás se saltan.
  template <class F>
  bool object(F on) {
    ws();
    if (p >= end || *p != '{') return false;
    p++;
    ws();
    if (p < end && *p == '}') { p++; return true; }
    std::string key;
    while (true) {
      key.clear();
      if (!str(&key)) return false;
      ws();
      if (p >= end || *p != ':') return false;
      p++;
      ws();
      const char* before = p;
      if (!on(key)) {
        p = before;
        if (!skip()) return false;
      }
      ws();
      if (p < end && *p == ',') { p++; continue; }
      if (p < end && *p == '}') { p++; return true; }
      return false;
    }
  }
};

// Lo que interesa de una línea del registro de Claude Code.
struct LogMsg {
  std::string type, ts, session, request, cwd, id, model, speed;
  Tok t;
  bool usage = false;
};
bool parse_log_line(const char* b, const char* e, LogMsg& m) {
  Lite j(b, e);
  double cc = 0, c5 = -1, c1 = -1;
  bool ok = j.object([&](const std::string& k) {
    if (k == "type") return j.str(&m.type);
    if (k == "timestamp") return j.str(&m.ts);
    if (k == "sessionId") return j.str(&m.session);
    if (k == "requestId") return j.str(&m.request);
    if (k == "cwd") return j.str(&m.cwd);
    if (k != "message") return false;
    return j.object([&](const std::string& mk) {
      if (mk == "id") return j.str(&m.id);
      if (mk == "model") return j.str(&m.model);
      if (mk != "usage") return false;
      m.usage = true;
      return j.object([&](const std::string& uk) {
        if (uk == "input_tokens") return j.number(&m.t.in);
        if (uk == "output_tokens") return j.number(&m.t.out);
        if (uk == "cache_read_input_tokens") return j.number(&m.t.cr);
        if (uk == "cache_creation_input_tokens") return j.number(&cc);
        if (uk == "speed") return j.str(&m.speed);
        if (uk != "cache_creation") return false;
        return j.object([&](const std::string& ck) {
          if (ck == "ephemeral_5m_input_tokens") return j.number(&c5);
          if (ck == "ephemeral_1h_input_tokens") return j.number(&c1);
          return false;
        });
      });
    });
  });
  if (!ok) return false;
  if (c5 < 0 && c1 < 0) m.t.w5 = cc;
  else {
    m.t.w1 = std::max(0.0, c1);
    m.t.w5 = c5 >= 0 ? c5 : std::max(0.0, cc - m.t.w1);
  }
  return true;
}

// El nombre del proyecto: la carpeta donde se abrió Claude Code.
std::string project_name(const std::string& cwd, const std::string& folder) {
  std::string c = cwd;
  while (!c.empty() && (c.back() == '/' || c.back() == '\\')) c.pop_back();
  size_t k = c.find_last_of("/\\");
  std::string name = k == std::string::npos ? c : c.substr(k + 1);
  if (name.empty()) name = folder;
  name = clean(name);
  return name.empty() ? std::string(tx::NO_PROJECT) : name;
}

// ------------------------------------------------------------ leer los registros
// Se leen una vez: de cada archivo se recuerda hasta dónde se leyó y, de cada
// mensaje, que ya se contó (el mismo mensaje sale en varias líneas, una por
// trozo de la respuesta, y a veces en varios archivos).
struct FileState {
  long long size = 0, offset = 0;
};
struct LocalCache {
  std::map<std::string, FileState> files;
  std::unordered_set<uint64_t> seen;
  Rows rows;
  long long msgs = 0;
};
struct ScanStats {
  int files = 0, read = 0;
  long long bytes = 0, total_bytes = 0, msgs = 0;
};

void count_line(const char* b, const char* e, const std::string& folder, LocalCache& c, ScanStats& st) {
  std::string_view sv(b, (size_t)(e - b));
  if (sv.find("\"usage\"") == std::string_view::npos || sv.find("\"assistant\"") == std::string_view::npos) return;
  LogMsg m;
  if (!parse_log_line(b, e, m) || m.type != "assistant" || !m.usage) return;
  if (!starts(m.model, "claude")) return;   // «<synthetic>»: avisos de Claude Code, sin coste
  long long t = parse_iso(m.ts);
  if (t < 0) return;
  if (!m.id.empty() && !c.seen.insert(hash64("m:" + m.id + ":" + m.request)).second) return;
  int day = local_day(t);
  Agg a;
  a.t = m.t;
  a.cost = cost_of(m.model, m.t, m.speed == "fast");
  a.msgs = 1;
  if (!m.session.empty() && c.seen.insert(hash64("s:" + m.session + ":" + std::to_string(day))).second) a.sessions = 1;
  c.rows[{day, m.model, project_name(m.cwd, folder)}].add(a);
  c.msgs++;
  st.msgs++;
}

bool seek64(FILE* f, long long off) {
#ifdef _WIN32
  return _fseeki64(f, off, SEEK_SET) == 0;
#else
  return fseeko(f, (off_t)off, SEEK_SET) == 0;
#endif
}

// Lee lo nuevo de un archivo (desde donde se quedó). Una línea a medias
// (Claude Code escribiendo) se deja para la próxima vez.
void scan_file(const std::string& path, const std::string& folder, long long size, FileState& fs, LocalCache& c,
               ScanStats& st, const std::atomic<bool>* cancel) {
  if (fs.offset > size) fs.offset = 0;   // el archivo se ha rehecho
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return;
  if (!seek64(f, fs.offset)) {
    std::fclose(f);
    return;
  }
  std::string buf;
  std::vector<char> chunk(1 << 20);
  size_t n;
  long long pos = fs.offset;
  while ((n = std::fread(chunk.data(), 1, chunk.size(), f)) > 0) {
    buf.append(chunk.data(), n);
    st.bytes += (long long)n;
    size_t start = 0, nl;
    while ((nl = buf.find('\n', start)) != std::string::npos) {
      count_line(buf.data() + start, buf.data() + nl, folder, c, st);
      start = nl + 1;
    }
    pos += (long long)start;
    buf.erase(0, start);
    if (cancel && cancel->load()) break;
  }
  std::fclose(f);
  fs.offset = pos;
  fs.size = size;
  st.read++;
}

void list_logs(const std::string& dir, std::vector<std::string>& out, int depth) {
  if (depth > 5) return;
  dirent** list = nullptr;
  int n = fl_filename_list(dir.c_str(), &list);
  for (int i = 0; i < n; i++) {
    std::string name = list[i]->d_name;
    if (name == "./" || name == "../" || name == "." || name == "..") continue;
    bool dir_name = !name.empty() && name.back() == '/';
    if (dir_name) name.pop_back();
    std::string path = dir + "/" + name;
    if (dir_name || (!ends(name, ".jsonl") && is_dir(path))) list_logs(path, out, depth + 1);
    else if (ends(name, ".jsonl")) out.push_back(path);
  }
  if (list) fl_filename_free_list(&list, n);
}
// La carpeta del proyecto de un archivo (la que cuelga de «projects»).
std::string folder_of(const std::string& root, const std::string& path) {
  std::string rest = path.substr(std::min(path.size(), root.size() + 1));
  size_t k = rest.find('/');
  return k == std::string::npos ? "" : rest.substr(0, k);
}

// Lee todo lo nuevo de las carpetas; [progress] recibe cómo va.
void scan_all(const std::vector<std::string>& roots, LocalCache& c, ScanStats& st, const std::atomic<bool>* cancel,
              const std::function<void(const ScanStats&)>& progress) {
  std::vector<std::pair<std::string, std::string>> files;   // ruta y carpeta
  for (const auto& root : roots) {
    if (!is_dir(root)) continue;
    std::vector<std::string> found;
    list_logs(root, found, 0);
    std::sort(found.begin(), found.end());
    for (auto& f : found) files.emplace_back(f, folder_of(root, f));
  }
  st.files = (int)files.size();
  std::vector<long long> sizes;
  for (const auto& f : files) {
    long long s = file_size(f.first);
    sizes.push_back(s);
    FileState& fs = c.files[f.first];
    if (s > fs.offset) st.total_bytes += s - fs.offset;
    else if (s >= 0 && s < fs.offset) st.total_bytes += s;
  }
  for (size_t i = 0; i < files.size(); i++) {
    if (cancel && cancel->load()) break;
    long long s = sizes[i];
    if (s < 0) continue;
    FileState& fs = c.files[files[i].first];
    if (fs.size == s && fs.offset >= s) continue;   // sin cambios
    scan_file(files[i].first, files[i].second, s, fs, c, st, cancel);
    if (progress) progress(st);
  }
}

// El caché en el disco: los archivos leídos y lo sumado (texto) y los
// mensajes ya contados (binario).
std::string row_line(const Key& k, const Agg& a) {
  char b[512];
  std::snprintf(b, sizeof b, "\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.10g\t%lld\t%lld\t%lld\t%lld\t%lld\t%lld\n", a.t.in, a.t.out,
                a.t.w5, a.t.w1, a.t.cr, a.cost, a.msgs, a.sessions, a.added, a.removed, a.commits, a.prs);
  return "R\t" + std::to_string(k.day) + "\t" + clean(k.model) + "\t" + clean(k.group) + b;
}
bool parse_row(const std::vector<std::string>& f, Rows& rows) {
  if (f.size() < 16 || f[0] != "R") return false;
  Key k{std::atoi(f[1].c_str()), f[2], f[3]};
  Agg a;
  a.t.in = std::atof(f[4].c_str());
  a.t.out = std::atof(f[5].c_str());
  a.t.w5 = std::atof(f[6].c_str());
  a.t.w1 = std::atof(f[7].c_str());
  a.t.cr = std::atof(f[8].c_str());
  a.cost = std::atof(f[9].c_str());
  a.msgs = std::atoll(f[10].c_str());
  a.sessions = std::atoll(f[11].c_str());
  a.added = std::atoll(f[12].c_str());
  a.removed = std::atoll(f[13].c_str());
  a.commits = std::atoll(f[14].c_str());
  a.prs = std::atoll(f[15].c_str());
  rows[k].add(a);
  return true;
}
const char* const CACHE_V = "CCUSAGE-LOCAL 1";
std::string cache_text(const LocalCache& c) {
  std::string out = std::string(CACHE_V) + "\n";
  for (const auto& f : c.files)
    out += "F\t" + std::to_string(f.second.size) + "\t" + std::to_string(f.second.offset) + "\t" + f.first + "\n";
  for (const auto& r : c.rows) out += row_line(r.first, r.second);
  out += "N\t" + std::to_string(c.msgs) + "\n";
  return out;
}
bool parse_cache(const std::string& text, LocalCache& c) {
  auto lines = split(text, '\n');
  if (lines.empty() || trim(lines[0]) != CACHE_V) return false;
  for (size_t i = 1; i < lines.size(); i++) {
    auto f = split(lines[i], '\t');
    if (f[0] == "F" && f.size() >= 4) {
      FileState s;
      s.size = std::atoll(f[1].c_str());
      s.offset = std::atoll(f[2].c_str());
      std::string path = f[3];
      for (size_t k = 4; k < f.size(); k++) path += "\t" + f[k];
      c.files[path] = s;
    } else if (f[0] == "R") {
      parse_row(f, c.rows);
    } else if (f[0] == "N" && f.size() >= 2) {
      c.msgs = std::atoll(f[1].c_str());
    }
  }
  return true;
}
std::string seen_bytes(const std::unordered_set<uint64_t>& seen) {
  std::string out;
  out.reserve(seen.size() * 8);
  for (uint64_t h : seen)
    for (int k = 0; k < 8; k++) out += (char)((h >> (8 * k)) & 0xff);
  return out;
}
void parse_seen(const std::string& data, std::unordered_set<uint64_t>& seen) {
  seen.reserve(data.size() / 8 + 1024);
  for (size_t i = 0; i + 8 <= data.size(); i += 8) {
    uint64_t h = 0;
    for (int k = 0; k < 8; k++) h |= (uint64_t)(unsigned char)data[i + (size_t)k] << (8 * k);
    seen.insert(h);
  }
}
bool load_local(LocalCache& c) {
  std::string text, seen;
  if (!read_file(config_dir() + "/local.cache", text) || !read_file(config_dir() + "/local.seen", seen)) return false;
  LocalCache n;
  if (!parse_cache(text, n)) return false;
  parse_seen(seen, n.seen);
  c = std::move(n);
  return true;
}
void save_local(const LocalCache& c) {
  fl_make_path(config_dir().c_str());
  write_file(config_dir() + "/local.seen", seen_bytes(c.seen));
  write_file(config_dir() + "/local.cache", cache_text(c));
}
// ------------------------------------------------------------ JSON (las respuestas de la API)
struct Json {
  enum T { NUL, BOOL, NUM, STR, ARR, OBJ } t = NUL;
  bool b = false;
  double n = 0;
  std::string s;
  std::vector<Json> a;
  std::vector<std::pair<std::string, Json>> o;
  const Json& operator[](const std::string& k) const {
    static const Json none;
    for (const auto& p : o)
      if (p.first == k) return p.second;
    return none;
  }
  const Json& operator[](size_t i) const {
    static const Json none;
    return i < a.size() ? a[i] : none;
  }
  std::string str(const std::string& def = "") const {
    if (t == STR) return s;
    if (t == NUM) {
      char buf[32];
      std::snprintf(buf, sizeof buf, "%.15g", n);
      return buf;
    }
    return def;
  }
  double num(double def = 0) const {
    if (t == NUM) return n;
    if (t == STR && !s.empty()) return std::atof(s.c_str());
    if (t == BOOL) return b;
    return def;
  }
  bool truthy() const { return t == BOOL ? b : t == NUM ? n != 0 : false; }
};

class JsonParser {
public:
  explicit JsonParser(const std::string& text) : s(text) {}
  bool parse(Json& out) {
    ws();
    if (!value(out, 0)) return false;
    ws();
    return i == s.size();
  }

private:
  const std::string& s;
  size_t i = 0;
  void ws() { while (i < s.size() && std::isspace((unsigned char)s[i])) i++; }
  bool lit(const char* w) {
    size_t n = std::strlen(w);
    if (s.compare(i, n, w) != 0) return false;
    i += n;
    return true;
  }
  static void utf8(std::string& o, uint32_t c) {
    if (c < 0x80) o += (char)c;
    else if (c < 0x800) { o += (char)(0xc0 | (c >> 6)); o += (char)(0x80 | (c & 63)); }
    else if (c < 0x10000) { o += (char)(0xe0 | (c >> 12)); o += (char)(0x80 | ((c >> 6) & 63)); o += (char)(0x80 | (c & 63)); }
    else { o += (char)(0xf0 | (c >> 18)); o += (char)(0x80 | ((c >> 12) & 63)); o += (char)(0x80 | ((c >> 6) & 63)); o += (char)(0x80 | (c & 63)); }
  }
  bool hex4(uint32_t& v) {
    if (i + 4 > s.size()) return false;
    v = 0;
    for (int k = 0; k < 4; k++) {
      char c = s[i++];
      v <<= 4;
      if (c >= '0' && c <= '9') v |= c - '0';
      else if (c >= 'a' && c <= 'f') v |= c - 'a' + 10;
      else if (c >= 'A' && c <= 'F') v |= c - 'A' + 10;
      else return false;
    }
    return true;
  }
  bool string(std::string& o) {
    if (i >= s.size() || s[i] != '"') return false;
    i++;
    while (i < s.size()) {
      char c = s[i++];
      if (c == '"') return true;
      if (c != '\\') { o += c; continue; }
      if (i >= s.size()) return false;
      char e = s[i++];
      switch (e) {
        case '"': o += '"'; break;
        case '\\': o += '\\'; break;
        case '/': o += '/'; break;
        case 'b': o += '\b'; break;
        case 'f': o += '\f'; break;
        case 'n': o += '\n'; break;
        case 'r': o += '\r'; break;
        case 't': o += '\t'; break;
        case 'u': {
          uint32_t c1;
          if (!hex4(c1)) return false;
          if (c1 >= 0xd800 && c1 < 0xdc00 && s.compare(i, 2, "\\u") == 0) {
            i += 2;
            uint32_t c2;
            if (!hex4(c2)) return false;
            c1 = 0x10000 + ((c1 - 0xd800) << 10) + (c2 - 0xdc00);
          }
          utf8(o, c1);
          break;
        }
        default: return false;
      }
    }
    return false;
  }
  bool value(Json& v, int depth) {
    if (depth > 64 || i >= s.size()) return false;
    char c = s[i];
    if (c == '{') {
      v.t = Json::OBJ;
      i++;
      ws();
      if (i < s.size() && s[i] == '}') { i++; return true; }
      while (true) {
        ws();
        std::string k;
        if (!string(k)) return false;
        ws();
        if (i >= s.size() || s[i++] != ':') return false;
        ws();
        Json x;
        if (!value(x, depth + 1)) return false;
        v.o.emplace_back(std::move(k), std::move(x));
        ws();
        if (i < s.size() && s[i] == ',') { i++; continue; }
        if (i < s.size() && s[i] == '}') { i++; return true; }
        return false;
      }
    }
    if (c == '[') {
      v.t = Json::ARR;
      i++;
      ws();
      if (i < s.size() && s[i] == ']') { i++; return true; }
      while (true) {
        ws();
        Json x;
        if (!value(x, depth + 1)) return false;
        v.a.push_back(std::move(x));
        ws();
        if (i < s.size() && s[i] == ',') { i++; continue; }
        if (i < s.size() && s[i] == ']') { i++; return true; }
        return false;
      }
    }
    if (c == '"') { v.t = Json::STR; return string(v.s); }
    if (lit("true")) { v.t = Json::BOOL; v.b = true; return true; }
    if (lit("false")) { v.t = Json::BOOL; return true; }
    if (lit("null")) return true;
    size_t start = i;
    if (s[i] == '-') i++;
    while (i < s.size() && (std::isdigit((unsigned char)s[i]) || s[i] == '.' || s[i] == 'e' || s[i] == 'E' || s[i] == '+' || s[i] == '-')) i++;
    if (i == start) return false;
    v.t = Json::NUM;
    v.n = std::strtod(s.substr(start, i - start).c_str(), nullptr);
    return true;
  }
};

bool parse_json(const std::string& text, Json& out) { return JsonParser(text).parse(out); }

// ------------------------------------------------------------ la API (curl)
// La API de Claude Code Analytics da, para cada día (UTC), una fila por
// persona o clave con sus sesiones, líneas, commits y, por modelo, tokens y
// coste estimado (en centavos). Hace falta una clave de administrador
// (sk-ant-admin…). No incluye el uso con planes Pro, Max, Team o Enterprise.
struct Http {
  int code = 0;
  std::string body, error;
};
std::string url_encode(const std::string& s) {
  std::string o;
  char b[4];
  for (unsigned char c : s) {
    if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') o += (char)c;
    else {
      std::snprintf(b, sizeof b, "%%%02X", c);
      o += b;
    }
  }
  return o;
}
std::string curl_quote(const std::string& s) {
  std::string o = "\"";
  for (char c : s) {
    if (c == '"' || c == '\\') o += '\\';
    if (c == '\n' || c == '\r') continue;
    o += c;
  }
  return o + "\"";
}
std::string curl_config(const std::string& url, const std::vector<std::string>& headers) {
  std::string c = "url = " + curl_quote(url) + "\n";
  for (const auto& h : headers) c += "header = " + curl_quote(h) + "\n";
  c += "silent\nshow-error\nmax-time = 40\nconnect-timeout = 15\n";
  c += "user-agent = \"DMarlonStudio-ClaudeCodeUsage/1.0\"\n";
  c += "write-out = \"\\n%{http_code}\"\n";
  return c;
}
// Lo que dijo curl: la respuesta y, en la última línea, el código HTTP.
Http parse_http(const std::string& out, int exit_code) {
  Http h;
  size_t nl = out.find_last_of('\n');
  std::string last = trim(nl == std::string::npos ? out : out.substr(nl + 1));
  if (!last.empty() && std::isdigit((unsigned char)last[0])) h.code = std::atoi(last.c_str());
  h.body = nl == std::string::npos ? "" : out.substr(0, nl);
  if (h.code == 0) {
    if (exit_code < 0) h.error = tx::ERR_NO_CURL;
    else {
      std::string e = trim(h.body);
      size_t k = e.find(") ");
      if (starts(e, "curl:") && k != std::string::npos) e = e.substr(k + 2);
      h.error = e.empty() ? std::string(tx::ERR_NO_ANSWER) : e;
    }
  }
  return h;
}
#ifdef _WIN32
std::wstring wide(const std::string& s) {
  unsigned n = fl_utf8towc(s.c_str(), (unsigned)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  fl_utf8towc(s.c_str(), (unsigned)s.size(), &w[0], n + 1);
  return w;
}
#endif
int run_capture(const std::string& cfg_path, std::string& out) {
  out.clear();
#ifdef _WIN32
  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE rd = nullptr, wr = nullptr;
  if (!CreatePipe(&rd, &wr, &sa, 0)) return -1;
  SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0);
  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdOutput = wr;
  si.hStdError = wr;
  si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  PROCESS_INFORMATION pi{};
  std::wstring cmd = L"curl.exe -K \"" + wide(cfg_path) + L"\"";
  BOOL ok = CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
  CloseHandle(wr);
  if (!ok) { CloseHandle(rd); return -1; }
  char buf[8192];
  DWORD n = 0;
  while (ReadFile(rd, buf, sizeof buf, &n, nullptr) && n > 0) out.append(buf, n);
  CloseHandle(rd);
  WaitForSingleObject(pi.hProcess, INFINITE);
  DWORD code = 1;
  GetExitCodeProcess(pi.hProcess, &code);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  return (int)code;
#else
  std::string q = "'";
  for (char c : cfg_path) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  q += "'";
  // Abierta desde el Finder, el PATH es el mínimo: curl está en /usr/bin.
  std::string cmd = "/usr/bin/curl -K " + q + " 2>&1";
  if (access("/usr/bin/curl", X_OK) != 0) cmd = "curl -K " + q + " 2>&1";
  FILE* p = popen(cmd.c_str(), "r");
  if (!p) return -1;
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
  int st = pclose(p);
  if (!WIFEXITED(st)) return -1;
  return WEXITSTATUS(st) == 127 ? -1 : WEXITSTATUS(st);
#endif
}
// Un GET con cabeceras. La clave va en un archivo de configuración de curl
// que solo lee el usuario (no en la línea de órdenes, que ven los demás).
Http http_get(const std::string& url, const std::vector<std::string>& headers) {
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = dir + "/req-" + std::to_string((long long)(now_s() * 1000)) + "-" + std::to_string(counter++) + ".cfg";
  if (!write_file(path, curl_config(url, headers), true)) {
    Http h;
    h.error = tx::ERR_NO_ANSWER;
    return h;
  }
  std::string out;
  int code = run_capture(path, out);
  std::remove(path.c_str());
  return parse_http(out, code);
}

std::string api_base() {
  if (const char* b = fl_getenv("DMS_CCUSAGE_API")) return b;
  return "https://api.anthropic.com";
}
const char* const API_VERSION = "2026-10-21";
bool looks_like_admin_key(const std::string& k) { return starts(trim(k), "sk-ant-admin"); }

// El error de la API en palabras.
std::string api_error(const Http& h) {
  if (h.code == 0) return h.error;
  if (h.code == 401) return tx::API_401;
  if (h.code == 403) return tx::API_403;
  if (h.code == 404) return tx::API_404;
  if (h.code == 429) return tx::API_429;
  Json j;
  std::string msg;
  if (parse_json(h.body, j)) msg = j["error"]["message"].str();
  if (msg.empty()) msg = trim(h.body).substr(0, 160);
  return fmt(tx::API_ERR, {std::to_string(h.code), msg});
}

// Una página del informe de un día → filas (día, modelo, persona).
bool parse_report(const std::string& body, Rows& rows, std::string& next, bool& more) {
  Json j;
  if (!parse_json(body, j) || j["data"].t != Json::ARR) return false;
  for (const auto& r : j["data"].a) {
    long long t = parse_iso(r["date"].str());
    if (t < 0) continue;
    int day = utc_day(t);
    const Json& a = r["actor"];
    std::string who = a["email_address"].str();
    if (who.empty()) who = a["api_key_name"].str();
    if (who.empty()) who = tx::UNKNOWN;
    who = clean(who);
    const Json& cm = r["core_metrics"];
    Agg extra;
    extra.sessions = (long long)cm["num_sessions"].num();
    extra.added = (long long)cm["lines_of_code"]["added"].num();
    extra.removed = (long long)cm["lines_of_code"]["removed"].num();
    extra.commits = (long long)cm["commits_by_claude_code"].num();
    extra.prs = (long long)cm["pull_requests_by_claude_code"].num();
    bool first = true;
    for (const auto& m : r["model_breakdown"].a) {
      Agg g;
      const Json& tk = m["tokens"];
      g.t.in = tk["input"].num();
      g.t.out = tk["output"].num();
      g.t.cr = tk["cache_read"].num();
      g.t.w5 = tk["cache_creation"].num();
      g.cost = m["estimated_cost"]["amount"].num() / 100.0;   // centavos → dólares
      if (first) {
        g.sessions = extra.sessions;
        g.added = extra.added;
        g.removed = extra.removed;
        g.commits = extra.commits;
        g.prs = extra.prs;
        first = false;
      }
      std::string model = clean(m["model"].str());
      rows[{day, model.empty() ? std::string(tx::UNKNOWN) : model, who}].add(g);
    }
    if (first && extra.active()) rows[{day, tx::UNKNOWN, who}].add(extra);
  }
  more = j["has_more"].truthy();
  next = j["next_page"].str();
  return true;
}
// Todas las páginas de un día.
bool fetch_day(const std::string& key, int day, Rows& rows, std::string& err, int& code) {
  std::vector<std::string> hdr = {"x-api-key: " + trim(key), std::string("anthropic-version: ") + API_VERSION,
                                  "Accept: application/json"};
  std::string page;
  for (int k = 0; k < 50; k++) {
    std::string url = api_base() + "/v1/organizations/usage_report/claude_code?starting_at=" + iso_day(day) + "&limit=1000";
    if (!page.empty()) url += "&page=" + url_encode(page);
    Http h = http_get(url, hdr);
    code = h.code;
    if (h.code != 200) {
      err = api_error(h);
      return false;
    }
    bool more = false;
    std::string next;
    if (!parse_report(h.body, rows, next, more)) {
      err = tx::ERR_BAD_ANSWER;
      return false;
    }
    if (!more || next.empty()) return true;
    page = next;
  }
  return true;
}

// Lo bajado de la API: las filas y cuándo se bajó cada día. Un día está
// cerrado dos horas después de su medianoche (UTC); hasta entonces se repite.
struct ApiCache {
  Rows rows;
  std::map<int, long long> fetched;
};
bool day_final(int day, long long fetched_at) { return fetched_at >= (long long)(day + 1) * 86400 + 7200; }
std::vector<int> days_to_fetch(const ApiCache& c, int today_utc, int n) {
  std::vector<int> out;
  for (int d = today_utc; d > today_utc - n; d--) {
    auto it = c.fetched.find(d);
    if (it == c.fetched.end() || !day_final(d, it->second)) out.push_back(d);
  }
  return out;
}
void replace_day(Rows& rows, int day, const Rows& fresh) {
  for (auto it = rows.lower_bound(Key{day, "", ""}); it != rows.end() && it->first.day == day;) it = rows.erase(it);
  for (const auto& r : fresh) rows[r.first].add(r.second);
}
const char* const API_V = "CCUSAGE-API 1";
std::string api_text(const ApiCache& c) {
  std::string out = std::string(API_V) + "\n";
  for (const auto& d : c.fetched) out += "D\t" + std::to_string(d.first) + "\t" + std::to_string(d.second) + "\n";
  for (const auto& r : c.rows) out += row_line(r.first, r.second);
  return out;
}
bool parse_api(const std::string& text, ApiCache& c) {
  auto lines = split(text, '\n');
  if (lines.empty() || trim(lines[0]) != API_V) return false;
  for (size_t i = 1; i < lines.size(); i++) {
    auto f = split(lines[i], '\t');
    if (f[0] == "D" && f.size() >= 3) c.fetched[std::atoi(f[1].c_str())] = std::atoll(f[2].c_str());
    else if (f[0] == "R") parse_row(f, c.rows);
  }
  return true;
}

// ------------------------------------------------------------ ajustes
struct Settings {
  int source = 0, metric = M_COST, period = P_30, every = 15, api_days = 90;
  double budget = 0;
  std::string key, logs;
  int alerted_month = 0;   // el mes del último aviso del presupuesto
};
const int EVERY[] = {5, 15, 30, 60};
const int EVERY_N = 4;
const int API_DAYS[] = {30, 90, 180, 365};
const int API_DAYS_N = 4;
std::string settings_text(const Settings& s) {
  char b[64];
  std::snprintf(b, sizeof b, "%.2f", s.budget);
  return "source=" + std::to_string(s.source) + "\nmetric=" + std::to_string(s.metric) + "\nperiod=" +
         std::to_string(s.period) + "\nevery=" + std::to_string(s.every) + "\napi_days=" + std::to_string(s.api_days) +
         "\nbudget=" + b + "\nalerted=" + std::to_string(s.alerted_month) + "\nlogs=" + clean(s.logs) +
         "\nkey=" + clean(s.key) + "\n";
}
Settings parse_settings(const std::string& text) {
  Settings s;
  for (const auto& line : split(text, '\n')) {
    size_t eq = line.find('=');
    if (eq == std::string::npos) continue;
    std::string k = trim(line.substr(0, eq)), v = trim(line.substr(eq + 1));
    int n = std::atoi(v.c_str());
    if (k == "source") s.source = n == 1 ? 1 : 0;
    else if (k == "metric") s.metric = std::max(0, std::min(2, n));
    else if (k == "period") s.period = std::max(0, std::min(5, n));
    else if (k == "every") s.every = std::max(1, std::min(240, n));
    else if (k == "api_days") s.api_days = std::max(1, std::min(365, n));
    else if (k == "budget") s.budget = std::max(0.0, std::atof(v.c_str()));
    else if (k == "alerted") s.alerted_month = n;
    else if (k == "logs") s.logs = v;
    else if (k == "key") s.key = v;
  }
  return s;
}
// «200», «200,50» o «$ 1.200» → dólares (-1 si no es un número).
double parse_money(const std::string& raw) {
  std::string s;
  for (char c : raw)
    if (std::isdigit((unsigned char)c) || c == ',' || c == '.') s += c;
  if (s.empty()) return trim(raw).empty() ? 0 : -1;
  // La última coma o punto con 1 o 2 cifras detrás es el decimal; los demás, miles.
  size_t k = s.find_last_of(",.");
  std::string ip = s, fr;
  if (k != std::string::npos && s.size() - k - 1 <= 2) { ip = s.substr(0, k); fr = s.substr(k + 1); }
  std::string digits;
  for (char c : ip)
    if (std::isdigit((unsigned char)c)) digits += c;
  return std::atof((digits.empty() ? "0" : digits).c_str()) + (fr.empty() ? 0 : std::atof(("0." + fr).c_str()));
}

// ------------------------------------------------------------ el menú de la barra
// El menú del icono, como datos (el de macOS se hace con ellos y las pruebas
// y las capturas los miran).
struct MenuEntry {
  std::string title;
  int tag = 0;   // la acción (0: solo texto)
  bool enabled = true, checked = false, sep = false;
  int color = -1;   // el punto de color de un modelo
  std::vector<MenuEntry> sub;
};
enum Act { A_REFRESH = 1, A_WINDOW = 2, A_TO_BAR = 3, A_QUIT = 4, A_SETTINGS = 5, A_SRC = 10, A_METRIC = 20, A_DAY = 100 };
MenuEntry text_entry(const std::string& t) {
  MenuEntry e;
  e.title = t;
  e.enabled = false;
  return e;
}
MenuEntry act_entry(const std::string& t, int tag, bool checked = false) {
  MenuEntry e;
  e.title = t;
  e.tag = tag;
  e.checked = checked;
  return e;
}
MenuEntry sep_entry() {
  MenuEntry e;
  e.sep = true;
  return e;
}
// Una barrita de texto para el menú: ▰▰▰▱▱▱.
std::string spark(double v, double max, int n = 8) {
  int k = max > 0 ? (int)std::lround(v / max * n) : 0;
  if (v > 0 && k == 0) k = 1;
  std::string s;
  for (int i = 0; i < n; i++) s += i < k ? "▰" : "▱";
  return s;
}
const char* metric_label(int m) { return m == M_TOKENS ? tx::M_TOKENS_L : m == M_SESSIONS ? tx::M_SESSIONS_L : tx::M_COST_L; }
std::vector<MenuEntry> bar_menu(const Rows& rows, int today, const Settings& s, bool window_shown, const std::string& busy) {
  std::vector<MenuEntry> m;
  Agg td = total(rows, today, today), wk = total(rows, today - 6, today), mo = total(rows, month_start(today), today);
  m.push_back(text_entry(fmt(tx::BAR_TODAY, {money(td.cost), tokens(td.t.total())})));
  m.push_back(text_entry(fmt(tx::BAR_WEEK, {money(wk.cost), tokens(wk.t.total())})));
  if (s.budget > 0)
    m.push_back(text_entry(fmt(tx::BAR_MONTH_OF, {money(mo.cost), money(s.budget), num(mo.cost / s.budget * 100, 0)})));
  else
    m.push_back(text_entry(fmt(tx::BAR_MONTH, {money(mo.cost), tokens(mo.t.total())})));
  if (!busy.empty()) m.push_back(text_entry(busy));
  m.push_back(sep_entry());
  MenuEntry days = act_entry(tx::LAST_7, 0);
  double mx = 0;
  for (int k = 0; k < 7; k++) mx = std::max(mx, metric(total(rows, today - k, today - k), s.metric));
  for (int k = 0; k < 7; k++) {
    double v = metric(total(rows, today - k, today - k), s.metric);
    days.sub.push_back(act_entry(day_short(today - k) + "   " + spark(v, mx) + "   " + metric_text(v, s.metric), A_DAY + k));
  }
  m.push_back(days);
  MenuEntry models = act_entry(tx::BY_MODEL_MONTH, 0);
  int i = 0;
  for (const auto& g : grouped(rows, month_start(today), today, false, M_COST)) {
    MenuEntry e = text_entry(model_name(g.first) + "   " + money(g.second.cost) + " · " + tokens(g.second.t.total()));
    e.color = i++;
    models.sub.push_back(e);
    if (i >= 6) break;
  }
  if (models.sub.empty()) models.sub.push_back(text_entry(tx::NO_DATA_PERIOD));
  m.push_back(models);
  m.push_back(sep_entry());
  m.push_back(act_entry(tx::REFRESH_NOW, A_REFRESH));
  MenuEntry src = act_entry(tx::SOURCE_MENU, 0);
  src.sub.push_back(act_entry(tx::SRC_LOCAL, A_SRC + 0, s.source == 0));
  src.sub.push_back(act_entry(tx::SRC_API, A_SRC + 1, s.source == 1));
  m.push_back(src);
  MenuEntry show = act_entry(tx::SHOW_MENU, 0);
  for (int k = 0; k < 3; k++) show.sub.push_back(act_entry(metric_label(k), A_METRIC + k, s.metric == k));
  m.push_back(show);
  m.push_back(sep_entry());
  m.push_back(window_shown ? act_entry(tx::TO_BAR, A_TO_BAR) : act_entry(tx::OPEN_WINDOW, A_WINDOW));
  m.push_back(act_entry(tx::SETTINGS_DOTS, A_SETTINGS));
  m.push_back(act_entry(tx::QUIT, A_QUIT));
  return m;
}
// Lo que se ve en la barra junto al icono.
std::string bar_title(const Rows& rows, int today, int m) {
  double v = metric(total(rows, today, today), m);
  if (m == M_TOKENS) return " " + tokens(v);
  if (m == M_SESSIONS) return " " + num(v, 0);
  return " " + money(v);
}

// Un aviso del sistema (en macOS).
void notify(const std::string& title, const std::string& text) {
#ifdef __APPLE__
  auto safe = [](std::string s) {
    std::string o;
    for (char c : s)
      if (c != '"' && c != '\\' && c != '\'' && c != '\n') o += c;
    return o;
  };
  std::string cmd = "/usr/bin/osascript -e 'display notification \"" + safe(text) + "\" with title \"" + safe(title) +
                    "\"' >/dev/null 2>&1";
  std::thread([cmd] { int r = std::system(cmd.c_str()); (void)r; }).detach();
#else
  (void)title;
  (void)text;
#endif
}

// ------------------------------------------------------------ CSV
std::string csv(const Rows& rows) {
  std::string out = "date,model,group,input_tokens,output_tokens,cache_write_5m,cache_write_1h,cache_read,cost_usd,messages,sessions\n";
  auto q = [](const std::string& s) {
    std::string o = "\"";
    for (char c : s) o += c == '"' ? std::string("\"\"") : std::string(1, c);
    return o + "\"";
  };
  char b[256];
  for (const auto& r : rows) {
    const Agg& a = r.second;
    std::snprintf(b, sizeof b, ",%.0f,%.0f,%.0f,%.0f,%.0f,%.4f,%lld,%lld\n", a.t.in, a.t.out, a.t.w5, a.t.w1, a.t.cr, a.cost,
                  a.msgs, a.sessions);
    out += iso_day(r.first.day) + "," + q(r.first.model) + "," + q(r.first.group) + b;
  }
  return out;
}

// ------------------------------------------------------------ dibujar
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)((v >> 8) & 255), (uchar)(v & 255)); }
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color border) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(border);
  fl_rounded_rect(x, y, w, h, r);
}
const unsigned HEAT[5] = {0xebedf0, 0x9be9a8, 0x40c463, 0x30a14e, 0x216e39};
const unsigned MODEL_COL[7] = {0xd97757, 0x6a9bcc, 0x788c5d, 0xc9a227, 0x9b7bc8, 0x4fb3a9, 0x9ca3af};
Fl_Color model_color(int i) { return rgb(MODEL_COL[(size_t)std::max(0, std::min(6, i))]); }
// El texto cortado con «…» para que quepa en [w] píxeles (con la letra actual).
std::string fit(const std::string& s, int w) {
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty() && (int)fl_width((t + "…").c_str()) > w) {
    t.pop_back();
    while (!t.empty() && ((unsigned char)t.back() & 0xc0) == 0x80) t.pop_back();
    if (!t.empty() && ((unsigned char)t.back() & 0xc0) == 0xc0) t.pop_back();
  }
  return t + "…";
}
void text(const std::string& s, int x, int y, int size, unsigned color, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  fl_color(rgb(color));
  fl_draw(s.c_str(), x, y);
}
void text_right(const std::string& s, int right, int y, int size, unsigned color, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  fl_color(rgb(color));
  fl_draw(s.c_str(), right - (int)fl_width(s.c_str()), y);
}
// Un tope redondo para el eje: 1, 2, 2,5 o 5 por una potencia de 10.
double nice_max(double v) {
  if (v <= 0) return 1;
  double p = std::pow(10, std::floor(std::log10(v)));
  for (double k : {1.0, 2.0, 2.5, 5.0, 10.0})
    if (v <= k * p) return k * p;
  return 10 * p;
}
std::string axis_text(double v, int m) {
  if (m == M_TOKENS) return tokens(v);
  if (m == M_SESSIONS) return num(v, 0);
  return fmt(tx::MONEY, {num(v, v < 10 && v != std::floor(v) ? 1 : 0)});
}

// El panel: las cifras, el mapa de calor del año, las barras de 30 días y
// las tablas por modelo y por proyecto (o por persona, con la API).
class Dash : public Fl_Widget {
public:
  struct Hit {
    int x, y, w, h, day;
  };
  const Rows* rows = nullptr;
  int metric = M_COST, period = P_30, source = 0, today = 0, selected = -1, hover = -1, hx = 0, hy = 0;
  double budget = 0;
  std::string empty_title, empty_help;
  std::function<void(int)> on_pick;
  std::vector<Hit> hits;
  std::map<int, Agg> days;

  Dash(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H, nullptr) {}

  int hit_at(int X, int Y) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (X >= h.x && X < h.x + h.w && Y >= h.y && Y < h.y + h.h) return i;
    }
    return -1;
  }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        int d = i >= 0 ? hits[(size_t)i].day : -1;
        if (d != hover || d >= 0) {
          hover = d;
          hx = Fl::event_x();
          hy = Fl::event_y();
          redraw();
        }
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        redraw();
        return 1;
      case FL_PUSH: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i < 0) return 0;
        selected = hits[(size_t)i].day;
        if (on_pick) on_pick(selected);
        redraw();
        return 1;
      }
    }
    return Fl_Widget::handle(e);
  }

  Agg day_agg(int d) const {
    auto it = days.find(d);
    return it == days.end() ? Agg() : it->second;
  }
  std::string others(const Agg& a) const {
    std::vector<std::string> p;
    for (int k = 0; k < 3; k++)
      if (k != metric) p.push_back(metric_text(::cu::metric(a, k), k));
    return p[0] + " · " + p[1];
  }

  void draw() override {
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0xf4f6f9));
    fl_rectf(x(), y(), w(), h());
    hits.clear();
    days = rows ? by_day(*rows) : std::map<int, Agg>();
    int X = x() + 16, W = w() - 32, Y = y() + 14;
    draw_kpis(X, Y, W);
    Y += 96 + 14;
    draw_heat(X, Y, W, 206);
    Y += 206 + 14;
    int H3 = std::max(220, y() + h() - 14 - Y);
    int bw = W * 44 / 100, mw = (W - bw - 28) / 2;
    draw_bars(X, Y, bw, H3);
    draw_table(X + bw + 14, Y, mw, H3, false);
    draw_table(X + bw + 28 + mw, Y, W - bw - 28 - mw, H3, true);
    draw_tip();
    fl_pop_clip();
  }

  void draw_kpis(int X, int Y, int W) {
    const int n = 5, gap = 12, H = 96;
    int cw = (W - (n - 1) * gap) / n;
    Agg td = rows ? total(*rows, today, today) : Agg();
    Agg wk = rows ? total(*rows, today - 6, today) : Agg();
    Agg mo = rows ? total(*rows, month_start(today), today) : Agg();
    Agg yr = rows ? total(*rows, year_start(today), today) : Agg();
    Streak st = streaks(days, today);
    struct Card {
      std::string title, value, sub;
      double frac;
    };
    std::vector<Card> cards = {
        {tx::K_TODAY, metric_text(::cu::metric(td, metric), metric), others(td), -1},
        {tx::K_WEEK, metric_text(::cu::metric(wk, metric), metric), others(wk), -1},
        {tx::K_MONTH, metric_text(::cu::metric(mo, metric), metric), others(mo), budget > 0 ? mo.cost / budget : -1},
        {tx::K_YEAR, metric_text(::cu::metric(yr, metric), metric), others(yr), -1},
        {tx::K_STREAK, fmt(st.current == 1 ? tx::DAYS_ONE : tx::DAYS_N, {std::to_string(st.current)}),
         fmt(tx::BEST_STREAK, {std::to_string(st.best)}), -1},
    };
    if (budget > 0)
      cards[2].sub = fmt(tx::OF_BUDGET, {num(mo.cost / budget * 100, 0), money(budget)});
    for (int i = 0; i < n; i++) {
      const Card& c = cards[(size_t)i];
      int cx = X + i * (cw + gap);
      round_box(cx, Y, cw, H, 12, FL_WHITE, rgb(0xe3e6ec));
      text(fit(c.title, cw - 32), cx + 16, Y + 26, 13, 0x6b7280);
      fl_font(FL_HELVETICA_BOLD, 26);
      std::string v = c.value;
      int size = 26;
      while (size > 15 && (int)fl_width(v.c_str()) > cw - 32) fl_font(FL_HELVETICA_BOLD, --size);
      text(v, cx + 16, Y + 60, size, 0x111827, true);
      fl_font(FL_HELVETICA, 12);
      text(fit(c.sub, cw - 32), cx + 16, Y + 82, 12, 0x6b7280);
      if (c.frac >= 0) {
        int bw = cw - 32;
        fl_color(rgb(0xeef0f4));
        fl_rounded_rectf(cx + 16, Y + 88, bw, 4, 2);
        unsigned col = c.frac >= 1 ? 0xdc2626 : c.frac >= 0.8 ? 0xf59e0b : 0x30a14e;
        fl_color(rgb(col));
        fl_rounded_rectf(cx + 16, Y + 88, std::max(4, (int)(bw * std::min(1.0, c.frac))), 4, 2);
      }
    }
  }

  void draw_heat(int X, int Y, int W, int H) {
    round_box(X, Y, W, H, 12, FL_WHITE, rgb(0xe3e6ec));
    const int cell = 12, step = 15, cols = 53;
    int gx = X + 18 + 34, gy = Y + 62;
    int start = today - weekday(today) - (cols - 1) * 7;
    std::vector<double> vals;
    double sum = 0;
    int active = 0;
    for (int d = start; d <= today; d++) {
      Agg a = day_agg(d);
      double v = ::cu::metric(a, metric);
      vals.push_back(v);
      sum += v;
      if (a.active()) active++;
    }
    auto q = quartiles(vals);
    text(fmt(tx::HEAT_TITLE, {metric_label(metric)}), X + 18, Y + 30, 16, 0x111827, true);
    text_right(fmt(tx::HEAT_TOTAL, {metric_text(sum, metric), std::to_string(active)}), gx + cols * step - 3, Y + 30, 13,
               0x6b7280);
    // Los meses, arriba; los días de la semana, a la izquierda.
    int last_label = -100;
    for (int c = 0; c < cols; c++) {
      int d0 = start + c * 7;
      int y0, y1;
      unsigned m0, m1, dd0, dd1;
      civil_from_days(d0, y0, m0, dd0);
      civil_from_days(d0 - 7, y1, m1, dd1);
      int lx = gx + c * step;
      if ((c == 0 || m0 != m1) && lx - last_label >= 34 && c < cols - 1) {
        text(mon_short(m0), lx, gy - 9, 11, 0x6b7280);
        last_label = lx;
      }
    }
    for (int r : {0, 2, 4}) text(wd_short(r), X + 18, gy + r * step + 10, 10, 0x6b7280);
    for (int c = 0; c < cols; c++)
      for (int r = 0; r < 7; r++) {
        int d = start + c * 7 + r;
        if (d > today) break;
        int cx = gx + c * step, cy = gy + r * step;
        fl_color(rgb(HEAT[level(::cu::metric(day_agg(d), metric), q)]));
        fl_rounded_rectf(cx, cy, cell, cell, 3);
        if (d == selected) {
          fl_color(rgb(0x1f2937));
          fl_line_style(FL_SOLID, 2);
          fl_rounded_rect(cx - 1, cy - 1, cell + 2, cell + 2, 3);
          fl_line_style(0);
        }
        hits.push_back({cx - 1, cy - 1, step, step, d});
      }
    // La leyenda.
    int ly = gy + 7 * step + 12, lr = gx + cols * step - 3;
    fl_font(FL_HELVETICA, 11);
    int lw = (int)fl_width(tx::LESS) + (int)fl_width(tx::MORE) + 5 * 15 + 16;
    int lx = lr - lw;
    text(tx::LESS, lx, ly + 10, 11, 0x6b7280);
    lx += (int)fl_width(tx::LESS) + 6;
    for (int k = 0; k < 5; k++) {
      fl_color(rgb(HEAT[k]));
      fl_rounded_rectf(lx + k * 15, ly, cell, cell, 3);
    }
    text(tx::MORE, lx + 5 * 15 + 4, ly + 10, 11, 0x6b7280);
    text(tx::HEAT_HINT, gx, ly + 10, 11, 0x9ca3af);
    // El detalle del día elegido, a la derecha.
    int dx = gx + cols * step + 24, dw = X + W - 18 - dx;
    if (dw >= 150) {
      fl_color(rgb(0xeef0f4));
      fl_line(dx - 12, Y + 16, dx - 12, Y + H - 16);
      draw_detail(dx, Y + 16, dw, H - 32, selected >= 0 ? selected : today);
    }
    if (!rows || rows->empty()) {
      int bw = std::min(560, cols * step - 40), bx = gx + (cols * step - bw) / 2, by = gy + 10;
      round_box(bx, by, bw, 84, 12, rgb(0xffffff), rgb(0xe3e6ec));
      text(fit(empty_title, bw - 32), bx + 16, by + 30, 15, 0x111827, true);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(0x4b5563));
      fl_draw(empty_help.c_str(), bx + 16, by + 38, bw - 32, 40, FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP | FL_ALIGN_INSIDE, nullptr, 0);
    }
  }

  void draw_detail(int X, int Y, int W, int H, int day) {
    (void)H;
    Agg a = day_agg(day);
    text(fit(day == today ? std::string(tx::TODAY_CAP) + " · " + day_short(day) : day_long(day), W), X, Y + 16, 14, 0x111827, true);
    if (!a.active()) {
      text(tx::D_NONE, X, Y + 44, 13, 0x6b7280);
      return;
    }
    text(money(a.cost), X, Y + 48, 24, 0x111827, true);
    text(fmt(tx::TOKENS_N, {tokens(a.t.total())}), X, Y + 68, 13, 0x374151);
    int yy = Y + 90;
    auto line = [&](const std::string& s) {
      text(fit(s, W), X, yy, 12, 0x4b5563);
      yy += 18;
    };
    line(fmt(tx::D_IN_OUT, {tokens(a.t.in), tokens(a.t.out)}));
    line(fmt(tx::D_CACHE, {tokens(a.t.w5 + a.t.w1), tokens(a.t.cr)}));
    std::string sess = metric_text((double)a.sessions, M_SESSIONS);
    if (source == 0) line(fmt(tx::D_SESS_MSGS, {sess, num((double)a.msgs, 0)}));
    else line(fmt(tx::D_SESS_LINES, {sess, num((double)a.added, 0), num((double)a.removed, 0)}));
    if (!rows) return;
    int i = 0;
    for (const auto& g : grouped(*rows, day, day, false, M_COST)) {
      if (yy > Y + H) break;
      fl_color(model_color(i));
      fl_pie(X, yy - 9, 9, 9, 0, 360);
      fl_font(FL_HELVETICA, 12);
      std::string v = money(g.second.cost);
      int vw = (int)fl_width(v.c_str());
      text(fit(model_name(g.first), W - vw - 26), X + 15, yy, 12, 0x374151);
      text_right(v, X + W, yy, 12, 0x374151);
      yy += 18;
      if (++i >= 3) break;
    }
  }

  // Las barras de los 30 últimos días, por modelo.
  void draw_bars(int X, int Y, int W, int H) {
    round_box(X, Y, W, H, 12, FL_WHITE, rgb(0xe3e6ec));
    text(fmt(tx::BARS_TITLE, {metric_label(metric)}), X + 18, Y + 30, 16, 0x111827, true);
    const int n = 30;
    int a = today - n + 1;
    std::vector<std::string> top;
    if (rows && metric != M_SESSIONS)
      for (const auto& g : grouped(*rows, a, today, false, metric)) {
        if ((int)top.size() >= 4) break;
        top.push_back(g.first);
      }
    // Lo de cada día, por serie (las 4 primeras y «otros»).
    std::vector<std::vector<double>> v((size_t)n, std::vector<double>(top.size() + 1, 0));
    double mx = 0;
    if (rows)
      for (const auto& r : *rows) {
        int d = r.first.day - a;
        if (d < 0 || d >= n) continue;
        size_t s = top.size();
        for (size_t k = 0; k < top.size(); k++)
          if (top[k] == r.first.model) s = k;
        v[(size_t)d][s] += ::cu::metric(r.second, metric);
      }
    for (const auto& d : v) {
      double t = 0;
      for (double x : d) t += x;
      mx = std::max(mx, t);
    }
    mx = nice_max(mx);
    int ax = X + 64, ay = Y + 50, aw = W - 64 - 18, ah = H - 50 - 64;
    if (ah < 40) return;
    for (int k = 0; k <= 4; k++) {
      int gyy = ay + ah - ah * k / 4;
      fl_color(rgb(k == 0 ? 0xd1d5db : 0xeef0f4));
      fl_line(ax, gyy, ax + aw, gyy);
      text_right(axis_text(mx * k / 4, metric), ax - 8, gyy + 4, 11, 0x9ca3af);
    }
    double bw = aw / (double)n;
    for (int i = 0; i < n; i++) {
      int bx = ax + (int)(i * bw) + 2, bwi = std::max(2, (int)bw - 4), d = a + i;
      if (d == selected) {
        fl_color(rgb(0xf3f4f6));
        fl_rectf(bx - 2, ay, bwi + 4, ah);
      }
      double acc = 0;
      for (size_t s = 0; s < v[(size_t)i].size(); s++) {
        double val = v[(size_t)i][s];
        if (val <= 0) continue;
        int y0 = ay + ah - (int)std::lround(acc / mx * ah), y1 = ay + ah - (int)std::lround((acc + val) / mx * ah);
        fl_color(metric == M_SESSIONS ? rgb(HEAT[3]) : s < top.size() ? model_color((int)s) : model_color(6));
        fl_rectf(bx, y1, bwi, std::max(1, y0 - y1));
        acc += val;
      }
      hits.push_back({bx - 2, ay, bwi + 4, ah, d});
      int yy, dd;
      unsigned mm, ddu;
      civil_from_days(d, yy, mm, ddu);
      dd = (int)ddu;
      if (i % 5 == 4 || i == 0) {
        std::string l = std::to_string(dd);
        fl_font(FL_HELVETICA, 11);
        text(l, bx + bwi / 2 - (int)fl_width(l.c_str()) / 2, ay + ah + 16, 11, d == today ? 0x111827 : 0x9ca3af, d == today);
      }
    }
    // La leyenda de colores.
    int lx = ax, ly = Y + H - 22;
    fl_font(FL_HELVETICA, 12);
    auto key = [&](Fl_Color c, const std::string& name) {
      fl_color(c);
      fl_rounded_rectf(lx, ly - 9, 10, 10, 2);
      std::string t = fit(name, X + W - 18 - lx - 16);
      text(t, lx + 15, ly, 12, 0x4b5563);
      lx += 15 + (int)fl_width(t.c_str()) + 16;
    };
    if (metric == M_SESSIONS) key(rgb(HEAT[3]), tx::M_SESSIONS_L);
    for (size_t k = 0; k < top.size() && lx < X + W - 60; k++) key(model_color((int)k), model_name(top[k]));
    bool other = false;
    for (const auto& d : v) other = other || d.back() > 0;
    if (!top.empty() && other && lx < X + W - 60) key(model_color(6), tx::OTHERS);
  }

  void draw_table(int X, int Y, int W, int H, bool by_group) {
    round_box(X, Y, W, H, 12, FL_WHITE, rgb(0xe3e6ec));
    const char* title = by_group ? (source == 0 ? tx::BY_PROJECT : tx::BY_USER) : tx::BY_MODEL;
    text(fit(title, W - 36), X + 18, Y + 30, 16, 0x111827, true);
    static const char* const names[] = {tx::PER_TODAY, tx::PER_WEEK, tx::PER_30, tx::PER_MONTH, tx::PER_YEAR, tx::PER_ALL};
    text(fit(names[period], W - 36), X + 18, Y + 48, 12, 0x6b7280);
    int a, b;
    period_range(period, today, a, b);
    std::vector<std::pair<std::string, Agg>> g;
    if (rows) g = grouped(*rows, a, b, by_group, metric);
    double sum = 0;
    for (const auto& r : g) sum += ::cu::metric(r.second, metric);
    int yy = Y + 66;
    if (g.empty() || sum <= 0) {
      text(tx::NO_DATA_PERIOD, X + 18, yy + 16, 13, 0x9ca3af);
      return;
    }
    const int rowh = 40;
    int i = 0;
    for (const auto& r : g) {
      if (yy + rowh > Y + H - 8) {
        text(fmt(tx::AND_MORE, {std::to_string(g.size() - (size_t)i)}), X + 18, yy + 14, 12, 0x9ca3af);
        break;
      }
      double v = ::cu::metric(r.second, metric);
      std::string val = metric_text(v, metric);
      fl_font(FL_HELVETICA_BOLD, 13);
      int vw = (int)fl_width(val.c_str());
      int nx = X + 18;
      if (!by_group) {
        fl_color(model_color(i));
        fl_pie(nx, yy + 6, 10, 10, 0, 360);
        nx += 16;
      }
      std::string name = by_group ? r.first : model_name(r.first);
      fl_font(FL_HELVETICA, 13);
      text(fit(name, X + W - 18 - vw - 12 - nx), nx, yy + 16, 13, 0x1f2937);
      text_right(val, X + W - 18, yy + 16, 13, 0x111827, true);
      int bx = X + 18, bwid = W - 36;
      fl_color(rgb(0xeef0f4));
      fl_rounded_rectf(bx, yy + 24, bwid, 6, 3);
      fl_color(by_group ? rgb(HEAT[3]) : model_color(i));
      fl_rounded_rectf(bx, yy + 24, std::max(6, (int)(bwid * v / sum)), 6, 3);
      yy += rowh;
      i++;
    }
  }

  void draw_tip() {
    if (hover < 0) return;
    Agg a = day_agg(hover);
    std::string l1 = hover == today ? std::string(tx::TODAY_CAP) + " · " + day_short(hover) : day_short(hover);
    std::string l2 = a.active() ? metric_text(::cu::metric(a, metric), metric) + " · " + others(a) : std::string(tx::D_NONE);
    fl_font(FL_HELVETICA_BOLD, 12);
    int w1 = (int)fl_width(l1.c_str());
    fl_font(FL_HELVETICA, 12);
    int w2 = (int)fl_width(l2.c_str());
    int tw = std::max(w1, w2) + 24, th = 46;
    int tx0 = std::min(hx + 14, x() + w() - tw - 6), ty0 = hy - th - 10;
    if (ty0 < y() + 4) ty0 = hy + 18;
    fl_color(rgb(0x1f2937));
    fl_rounded_rectf(tx0, ty0, tw, th, 8);
    text(l1, tx0 + 12, ty0 + 19, 12, 0xffffff, true);
    text(l2, tx0 + 12, ty0 + 36, 12, 0xd1d5db);
  }
};

// ------------------------------------------------------------ datos de ejemplo
// Un año inventado (siempre el mismo) para las capturas y las pruebas.
Rows demo_rows(int today) {
  Rows rows;
  uint32_t seed = 12345;
  auto rnd = [&]() {
    seed = seed * 1664525u + 1013904223u;
    return (seed >> 8) / 16777216.0;
  };
  const char* projects[] = {"tienda-online", "api-pedidos", "app-movil", "web-empresa", "scripts"};
  for (int d = today - 370; d <= today; d++) {
    int wd = weekday(d);
    double busy = wd >= 5 ? 0.25 : 0.85;
    if (d > today - 120) busy += 0.08;   // cada vez más
    if (rnd() > busy && d < today - 1) continue;   // hoy y ayer, con uso
    int sessions = 1 + (int)(rnd() * (wd >= 5 ? 2 : 6));
    for (int s = 0; s < sessions; s++) {
      std::string project = projects[(int)(rnd() * 5) % 5];
      std::string model = rnd() < 0.78 ? "claude-opus-5-5" : rnd() < 0.85 ? "claude-sonnet-5-5" : "claude-haiku-5-5";
      Agg a;
      double size = 0.3 + rnd() * rnd() * 3.0;
      a.msgs = (long long)(20 + 160 * size);
      a.t.in = 4000 * size;
      a.t.out = 90000 * size;
      a.t.w1 = 350000 * size;
      a.t.cr = 6500000 * size;
      a.cost = cost_of(model, a.t, false);
      a.sessions = 1;
      a.added = (long long)(300 * size);
      a.removed = (long long)(120 * size);
      rows[{d, model, project}].add(a);
    }
  }
  return rows;
}

// ------------------------------------------------------------ pruebas
int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  std::string D = tx::DEC, T = tx::THOUSANDS;
  chk(num(1234.5, 2) == "1" + T + "234" + D + "50", "número con miles");
  chk(num(-0.001, 2) == "0" + D + "00", "sin -0");
  chk(tokens(980) == "980" && tokens(12345) == fmt(tx::TOK_K, {"12"}) && tokens(4500000) == fmt(tx::TOK_M, {"4" + D + "5"}),
      "tokens");
  chk(money(12.345) == fmt(tx::MONEY, {"12" + D + "35"}) || money(12.345) == fmt(tx::MONEY, {"12" + D + "34"}), "dinero");
  // Fechas.
  chk(days_from_civil(1970, 1, 1) == 0 && days_from_civil(2026, 11, 14) == 20771, "días");
  int y;
  unsigned m, d;
  civil_from_days(20771, y, m, d);
  chk(y == 2026 && m == 11 && d == 14, "día → fecha");
  chk(weekday(20773) == 0 && weekday(20771) == 5, "día de la semana (lunes 16-11-2026)");
  chk(parse_iso("2026-11-13T23:46:40.503Z") == 20770LL * 86400 + 23 * 3600 + 46 * 60 + 40, "fecha ISO");
  chk(parse_iso("2026-11-14T00:30:00+01:00") == 20770LL * 86400 + 23 * 3600 + 30 * 60, "fecha con zona");
  chk(parse_iso("nada") < 0, "fecha mala");
  chk(iso_day(20771) == "2026-11-14" && month_start(20771) == (int)days_from_civil(2026, 11, 1), "iso y mes");
  // Precios.
  Tok t;
  t.in = 1e6;
  chk(std::fabs(cost_of("claude-opus-5-5", t, false) - 4) < 1e-9, "Opus 5.5: 4 $ el millón");
  chk(std::fabs(cost_of("claude-opus-5-5", t, true) - 8) < 1e-9, "modo rápido: el doble");
  Tok u;
  u.out = 1e6;
  u.cr = 1e6;
  u.w1 = 1e6;
  chk(std::fabs(cost_of("claude-sonnet-5-5", u, false) - (10 + 0.10 + 4)) < 1e-9, "Sonnet 5.5");
  chk(std::fabs(cost_of("claude-opus-4-5-20251101", t, false) - 5) < 1e-9, "Opus 4.5");
  chk(std::fabs(cost_of("claude-opus-4-1-20250805", t, false) - 15) < 1e-9, "Opus 4.1");
  chk(std::fabs(cost_of("claude-haiku-5-5", t, false) - 0.5) < 1e-9, "Haiku 5.5 largo (más de 100.000)");
  Tok s;
  s.in = 50000;
  chk(std::fabs(cost_of("claude-haiku-5-5", s, false) - 0.005) < 1e-9, "Haiku 5.5 corto");
  chk(model_name("claude-opus-5-5") == "Opus 5.5" && model_name("claude-haiku-4-5-20251001") == "Haiku 4.5" &&
          model_name("claude-sonnet-5") == "Sonnet 5",
      "nombres de modelos");
  // Una línea del registro, con «"usage":{…}» también dentro del texto.
  std::string line =
      R"({"parentUuid":"a","type":"assistant","cwd":"/Users/x/Proyectos/mi-app","sessionId":"S1","message":{"model":"claude-opus-5-5","id":"msg_1","content":[{"type":"text","text":"{\"usage\":{\"input_tokens\":999999}} \"assistant\""}],"usage":{"input_tokens":2,"cache_creation_input_tokens":300,"cache_read_input_tokens":5000,"output_tokens":40,"cache_creation":{"ephemeral_5m_input_tokens":100,"ephemeral_1h_input_tokens":200},"speed":"standard","server_tool_use":{"web_search_requests":0}}},"requestId":"req_1","timestamp":"2026-11-13T10:00:00.000Z"})";
  LogMsg lm;
  chk(parse_log_line(line.data(), line.data() + line.size(), lm), "línea del registro");
  chk(lm.type == "assistant" && lm.model == "claude-opus-5-5" && lm.id == "msg_1" && lm.request == "req_1" && lm.session == "S1",
      "claves de la línea");
  chk(lm.t.in == 2 && lm.t.out == 40 && lm.t.cr == 5000 && lm.t.w5 == 100 && lm.t.w1 == 200, "tokens de la línea");
  chk(project_name(lm.cwd, "x") == "mi-app" && project_name("", "carpeta") == "carpeta", "proyecto");
  // Leer una carpeta de registros: repetidos, sintéticos, línea a medias y lo nuevo.
  std::string dir = config_dir() + "/selftest-logs";
  std::string pdir = dir + "/-Users-x-Proyectos-mi-app";
  fl_make_path((pdir + "/S2/subagents").c_str());
  auto msg = [](const std::string& id, const std::string& session, const std::string& ts, int out, const std::string& model) {
    return R"({"type":"assistant","cwd":"/Users/x/Proyectos/mi-app","sessionId":")" + session +
           R"(","message":{"model":")" + model + R"(","id":")" + id +
           R"(","usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":)" +
           std::to_string(out) + R"(}},"requestId":"r)" + id + R"(","timestamp":")" + ts + "\"}\n";
  };
  std::string ts = "2026-11-13T12:00:00.000Z";
  std::string a1 = msg("m1", "S1", ts, 100, "claude-opus-5-5");
  std::string file1 = a1 + a1 + R"({"type":"user","message":{"role":"user","content":"hola"}})" "\n" +
                      msg("m2", "S1", ts, 50, "claude-sonnet-5-5") + msg("m3", "S1", ts, 70, "<synthetic>") +
                      "{\"type\":\"assistant\",\"usage\":{";   // a medias
  write_file(pdir + "/S1.jsonl", file1);
  write_file(pdir + "/S2/subagents/agent-1.jsonl", msg("m4", "S2", ts, 30, "claude-haiku-5-5") + a1);
  LocalCache c;
  ScanStats st;
  scan_all({dir}, c, st, nullptr, nullptr);
  int day = local_day(parse_iso(ts));
  Agg all = total(c.rows, day, day);
  chk(st.files == 2 && st.read == 2, "dos archivos (uno de un subagente)");
  chk(all.msgs == 3 && all.t.out == 180, "mensajes contados una vez");
  chk(all.sessions == 2, "dos sesiones");
  chk(grouped(c.rows, day, day, true, M_COST).size() == 1 && grouped(c.rows, day, day, true, M_COST)[0].first == "mi-app",
      "por proyecto");
  chk(grouped(c.rows, day, day, false, M_COST).size() == 3, "por modelo");
  // Se completa la línea a medias y llega otra: solo se lee lo nuevo.
  FILE* fa = fl_fopen((pdir + "/S1.jsonl").c_str(), "ab");
  std::string rest = "\"input_tokens\":1}}\n" + msg("m5", "S1", ts, 5, "claude-opus-5-5");
  std::fwrite(rest.data(), 1, rest.size(), fa);
  std::fclose(fa);
  ScanStats st2;
  scan_all({dir}, c, st2, nullptr, nullptr);
  all = total(c.rows, day, day);
  chk(st2.read == 1 && all.msgs == 4 && all.t.out == 185 && all.sessions == 2, "lo nuevo de un archivo");
  ScanStats st3;
  scan_all({dir}, c, st3, nullptr, nullptr);
  chk(st3.read == 0, "sin cambios no se lee nada");
  // El caché guardado y leído da lo mismo.
  LocalCache back;
  chk(parse_cache(cache_text(c), back) && back.files.size() == 2 && back.msgs == c.msgs, "caché");
  parse_seen(seen_bytes(c.seen), back.seen);
  chk(back.seen == c.seen, "mensajes vistos");
  chk(std::fabs(total(back.rows, day, day).cost - all.cost) < 1e-9, "coste del caché");
  std::remove((pdir + "/S1.jsonl").c_str());
  std::remove((pdir + "/S2/subagents/agent-1.jsonl").c_str());
  // La API: dos filas de la misma persona (dos terminales) y una clave.
  std::string body = R"({"data":[
    {"date":"2026-11-10T00:00:00Z","actor":{"type":"user_actor","email_address":"ana@example.com"},"terminal_type":"vscode",
     "core_metrics":{"num_sessions":3,"lines_of_code":{"added":120,"removed":30},"commits_by_claude_code":2,"pull_requests_by_claude_code":1},
     "model_breakdown":[{"model":"claude-opus-5-5","tokens":{"input":1000,"output":500,"cache_read":9000,"cache_creation":800},"estimated_cost":{"currency":"USD","amount":113}},
                        {"model":"claude-haiku-5-5","tokens":{"input":10,"output":5,"cache_read":0,"cache_creation":0},"estimated_cost":{"currency":"USD","amount":1}}]},
    {"date":"2026-11-10T00:00:00Z","actor":{"type":"user_actor","email_address":"ana@example.com"},"terminal_type":"iTerm.app",
     "core_metrics":{"num_sessions":1,"lines_of_code":{"added":10,"removed":0},"commits_by_claude_code":0,"pull_requests_by_claude_code":0},
     "model_breakdown":[{"model":"claude-opus-5-5","tokens":{"input":100,"output":50,"cache_read":0,"cache_creation":0},"estimated_cost":{"currency":"USD","amount":20}}]},
    {"date":"2026-11-10T00:00:00Z","actor":{"type":"api_actor","api_key_name":"ci-bot"},
     "core_metrics":{"num_sessions":1,"lines_of_code":{"added":0,"removed":0},"commits_by_claude_code":0,"pull_requests_by_claude_code":0},
     "model_breakdown":[]}],
    "has_more":true,"next_page":"page_MjAyNS0wNS0xNFQwMDowMDowMFo="})";
  Rows ar;
  std::string next;
  bool more = false;
  chk(parse_report(body, ar, next, more), "respuesta de la API");
  int aday = (int)days_from_civil(2026, 11, 10);
  Agg at = total(ar, aday, aday);
  chk(more && next == "page_MjAyNS0wNS0xNFQwMDowMDowMFo=", "páginas");
  chk(std::fabs(at.cost - 1.34) < 1e-9 && at.sessions == 5 && at.added == 130 && at.commits == 2 && at.prs == 1, "suma de la API");
  auto users = grouped(ar, aday, aday, true, M_COST);
  chk(users.size() == 2 && users[0].first == "ana@example.com" && users[1].first == "ci-bot", "por persona");
  chk(url_encode("page_a=+/") == "page_a%3D%2B%2F", "url");
  ApiCache ac;
  ac.rows = ar;
  ac.fetched[aday] = (long long)(aday + 1) * 86400 + 9000;
  ac.fetched[aday + 1] = (long long)(aday + 1) * 86400 + 600;
  ApiCache ab;
  chk(parse_api(api_text(ac), ab) && ab.fetched.size() == 2 && std::fabs(total(ab.rows, aday, aday).cost - 1.34) < 1e-9, "caché de la API");
  auto todo = days_to_fetch(ac, aday + 2, 3);
  chk(todo.size() == 2 && todo[0] == aday + 2 && todo[1] == aday + 1, "qué días se bajan");
  Rows fresh;
  fresh[{aday, "claude-opus-5-5", "ana@example.com"}].cost = 9;
  replace_day(ac.rows, aday, fresh);
  chk(std::fabs(total(ac.rows, aday, aday).cost - 9) < 1e-9, "un día se sustituye entero");
  Http h401;
  h401.code = 401;
  chk(api_error(h401) == tx::API_401, "error 401");
  Http hx = parse_http("{\"error\":{\"message\":\"boom\"}}\n500", 0);
  chk(hx.code == 500 && api_error(hx) == fmt(tx::API_ERR, {"500", "boom"}), "error con mensaje");
  chk(parse_http("curl: (6) Could not resolve host: x\n000", 6).error == "Could not resolve host: x", "error de curl");
  chk(curl_config("https://a/b", {"x-api-key: k\"1"}).find("header = \"x-api-key: k\\\"1\"") != std::string::npos, "comillas en curl");
  chk(looks_like_admin_key("sk-ant-admin01-abc") && !looks_like_admin_key("sk-ant-api03-abc"), "clave de administrador");
  // Ajustes.
  Settings se;
  se.source = 1;
  se.metric = 2;
  se.budget = 200.5;
  se.key = "sk-ant-admin01-x";
  se.logs = "/tmp/logs";
  Settings sb = parse_settings(settings_text(se));
  chk(sb.source == 1 && sb.metric == 2 && std::fabs(sb.budget - 200.5) < 1e-9 && sb.key == se.key && sb.logs == se.logs, "ajustes");
  chk(parse_money("200") == 200 && std::fabs(parse_money("1.200,50") - 1200.5) < 1e-9 && parse_money("$ 99.9") == 99.9 &&
          parse_money("") == 0 && parse_money("abc") < 0,
      "presupuesto");
  // Rachas y tonos.
  std::map<int, Agg> dd;
  for (int k : {1, 2, 3, 5, 6, 9, 10})
    dd[k].msgs = 1;
  Streak sk = streaks(dd, 10);
  chk(sk.current == 2 && sk.best == 3, "rachas");
  chk(streaks(dd, 11).current == 2 && streaks(dd, 12).current == 0, "racha hasta ayer");
  auto q = quartiles({0, 1, 2, 3, 4, 5, 6, 7, 8});
  chk(level(0, q) == 0 && level(1, q) == 1 && level(8, q) == 4, "tonos del mapa");
  chk(nice_max(7.3) == 10 && nice_max(0.18) == 0.2 && nice_max(2100) == 2500, "eje");
  // El menú de la barra.
  int td = today();
  Rows demo = demo_rows(td);
  auto menu = bar_menu(demo, td, se, true, "");
  bool has7 = false, hasq = false;
  for (const auto& e : menu) {
    if (e.title == tx::LAST_7 && e.sub.size() == 7 && e.sub[0].tag == A_DAY) has7 = true;
    if (e.tag == A_QUIT) hasq = true;
  }
  Agg dt = total(demo, td, td);
  chk(has7 && hasq && menu[0].title == fmt(tx::BAR_TODAY, {money(dt.cost), tokens(dt.t.total())}), "menú de la barra");
  chk(spark(5, 10, 8) == "▰▰▰▰▱▱▱▱", "barrita");
  chk(!csv(demo).empty() && csv(demo).find("claude-opus-5-5") != std::string::npos, "CSV");

  // De verdad: DMS_CCUSAGE_REAL=1 lee los registros de este equipo (sin guardar).
  if (fl_getenv("DMS_CCUSAGE_REAL")) {
    LocalCache rc;
    ScanStats rs;
    double t0 = now_s();
    scan_all(default_log_dirs(), rc, rs, nullptr, nullptr);
    int tdy = today();
    Agg a = total(rc.rows, tdy - 29, tdy), all2 = total(rc.rows, -1000000, tdy);
    std::printf("real: %d archivos, %s en %.1f s, %lld mensajes · 30 días: %s, %s tokens · todo: %s\n", rs.files,
                bytes((double)rs.bytes).c_str(), now_s() - t0, (long long)rc.msgs, money(a.cost).c_str(),
                tokens(a.t.total()).c_str(), money(all2.cost).c_str());
    for (const auto& g : grouped(rc.rows, tdy - 29, tdy, false, M_COST))
      std::printf("  %s: %s\n", model_name(g.first).c_str(), money(g.second.cost).c_str());
  }
  // De verdad: DMS_CCUSAGE_KEY=sk-ant-admin… baja ayer de la API.
  if (const char* k = fl_getenv("DMS_CCUSAGE_KEY")) {
    Rows r;
    std::string err;
    int code = 0;
    bool ok = fetch_day(k, utc_day(now_t()) - 1, r, err, code);
    std::printf("api: %s %d %s · %zu filas\n", ok ? "ok" : "error", code, err.c_str(), r.size());
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace cu

// ============================================================ la barra de menús
// En macOS, un NSStatusItem hecho desde C++ con el runtime de Objective-C
// (objc_msgSend): un icono del sistema, lo gastado hoy y el menú. En Windows
// y Linux, la ventana se minimiza.
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsClaudeUsageTarget", 0);
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
  id it = msg<id, double>(sb, "statusItemWithLength:", -1.0);   // NSVariableStatusItemLength
  if (!it) return false;
  msg(it, "retain");
  item() = it;
  return true;
}
// El icono (un símbolo del sistema, que se pinta del color de la barra) y el texto.
void set(const char* symbol, const std::string& title) {
  if (!item()) return;
  Pool pool;
  id b = msg(item(), "button");
  if (!b) return;
  id img = nullptr;
  if (class_getClassMethod((Class)objc_getClass("NSImage"), sel_registerName("imageWithSystemSymbolName:accessibilityDescription:")))
    img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str(symbol), str(title));
  if (img) {
    msg<void, BOOL>(img, "setTemplate:", YES);
    msg<void, id>(b, "setImage:", img);
    msg<void, long>(b, "setImagePosition:", 2);   // NSImageLeft
  }
  msg<void, id>(b, "setTitle:", str(title));
}
struct Size2 {
  double w, h;
};
struct Rect4 {
  double x, y, w, h;
};
// Un puntito de color (el de cada modelo) como imagen del menú.
id dot_image(unsigned rgb) {
  id img = msg<id, Size2>(msg(cls("NSImage"), "alloc"), "initWithSize:", Size2{10, 10});
  msg<void>(img, "lockFocus");
  id col = msg<id, double, double, double, double>(cls("NSColor"), "colorWithSRGBRed:green:blue:alpha:", (rgb >> 16) / 255.0,
                                                   ((rgb >> 8) & 255) / 255.0, (rgb & 255) / 255.0, 1.0);
  msg<void>(col, "setFill");
  id path = msg<id, Rect4>(cls("NSBezierPath"), "bezierPathWithOvalInRect:", Rect4{0, 0, 10, 10});
  msg<void>(path, "fill");
  msg<void>(img, "unlockFocus");
  return img;
}
id build(const std::vector<cu::MenuEntry>& entries) {
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
    msg<void, BOOL>(it, "setEnabled:", (e.tag || !e.sub.empty()) ? YES : NO);
    if (e.checked) msg<void, long>(it, "setState:", 1L);
    if (e.color >= 0) {
      id img = dot_image(cu::MODEL_COL[(size_t)std::min(6, e.color)]);
      msg<void, id>(it, "setImage:", img);
      msg<void>(img, "release");
    }
    if (!e.sub.empty()) {
      id sm = build(e.sub);
      msg<void, id>(it, "setSubmenu:", sm);
      msg<void>(sm, "release");
    }
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
  return m;
}
void menu(const std::vector<cu::MenuEntry>& entries) {
  if (!item()) return;
  Pool pool;
  id m = build(entries);
  msg<void, id>(item(), "setMenu:", m);
  msg<void>(m, "release");
}
// Con la ventana escondida, la app sale del Dock (solo queda en la barra).
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
void set(const char*, const std::string&) {}
void menu(const std::vector<cu::MenuEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
// Lo que mandan los hilos a la ventana (con Fl::awake).
struct ScanMsg {
  bool done = false;
  cu::Rows rows;
  cu::ScanStats st;
  std::unique_ptr<cu::LocalCache> cache;
};
struct ApiMsg {
  bool done = false, ok = true;
  int day = 0, n = 0, total = 0;
  long long t = 0;
  cu::Rows rows;
  std::string error;
};
// Los ajustes, en su ventana.
struct SettingsUI {
  Fl_Double_Window* win = nullptr;
  Fl_Secret_Input* key = nullptr;
  Fl_Choice* days = nullptr;
  Fl_Choice* every = nullptr;
  Fl_Input* budget = nullptr;
  Fl_Input* logs = nullptr;
  int result = -1;   // 0 cancelar, 1 guardar
  ~SettingsUI() { delete win; }
};

class Form1 : public FormDesign {
public:
  cu::Settings set;
  std::unique_ptr<cu::LocalCache> local;   // vacío mientras lo tiene el hilo que lee
  cu::Rows local_rows;
  cu::ApiCache api;
  cu::Dash* dash = nullptr;
  bool scanning = false, fetching = false, reset_local = false, in_bar = false, quitting = false, live = true;
  long long next_refresh = 0, updated = 0;
  int shown_today = 0;
  std::string busy, message, last_error;
  double message_until = 0;
  std::atomic<bool> cancel{false};

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_CCUSAGE_SELFTEST")) std::exit(cu::selftest());
    if (fl_getenv("DMS_CCUSAGE_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_CCUSAGE_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    Board->box(FL_FLAT_BOX);
    Top->resizable(nullptr);
    resizable(Board);
    size_range(980, 660);
    dash = new cu::Dash(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(dash);
    Board->resizable(dash);
    dash->on_pick = [](int d) { if (self()) self()->picked(d); };
    Source->items({tx::SRC_LOCAL, tx::SRC_API});
    Metric->items({tx::M_COST_L, tx::M_TOKENS_L, tx::M_SESSIONS_L});
    Period->items({tx::PER_TODAY, tx::PER_WEEK, tx::PER_30, tx::PER_MONTH, tx::PER_YEAR, tx::PER_ALL});
    // El botón de cerrar esconde la ventana en la barra (si la hay); Esc no
    // hace nada. Un cierre desde el código (el menú Idioma de las demos)
    // cierra de verdad: Fl::run termina y la app se vuelve a abrir.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE) self()->close_clicked();
      else self()->close_for_good();
    });
  }
  void show_settings_in_ui() {
    Source->index(set.source);
    Metric->index(set.metric);
    Period->index(set.period);
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // los hilos que leen y bajan avisan a la ventana
    setup();
    load();
    show_settings_in_ui();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    else BtnBar->copy_label(tx::MINIMIZE);
    refresh_data();
    refresh();
  }
  void form_close() override { save_settings(); }

  // ---- guardar
  std::string settings_file() const { return cu::config_dir() + "/settings.txt"; }
  std::string api_file() const { return cu::config_dir() + "/api.cache"; }
  void load() {
    std::string text;
    if (cu::read_file(settings_file(), text)) set = cu::parse_settings(text);
    if (cu::read_file(api_file(), text)) cu::parse_api(text, api);
  }
  void save_settings() {
    if (!live) return;   // las capturas y las pruebas no guardan nada
    fl_make_path(cu::config_dir().c_str());
    cu::write_file(settings_file(), cu::settings_text(set), true);
  }
  void save_api() {
    if (!live) return;
    fl_make_path(cu::config_dir().c_str());
    cu::write_file(api_file(), cu::api_text(api));
  }
  const cu::Rows& rows() const { return set.source == 0 ? local_rows : api.rows; }
  std::vector<std::string> log_dirs() const {
    return cu::trim(set.logs).empty() ? cu::default_log_dirs() : std::vector<std::string>{cu::trim(set.logs)};
  }

  // ---- leer y bajar
  void refresh_data() {
    next_refresh = cu::now_t() + set.every * 60;
    if (set.source == 0) start_scan();
    else start_fetch();
  }
  void start_scan() {
    if (scanning || !live) return;
    scanning = true;
    cancel = false;
    busy = tx::READING;
    std::unique_ptr<cu::LocalCache> c = std::move(local);
    std::vector<std::string> roots = log_dirs();
    std::atomic<bool>* stop = &cancel;
    std::thread([c = std::move(c), roots, stop]() mutable {
      if (!c) {
        c.reset(new cu::LocalCache);
        cu::load_local(*c);
        auto* m = new ScanMsg;
        m->rows = c->rows;
        Fl::awake(scan_msg, m);
      }
      cu::ScanStats st;
      double last = cu::now_s();
      cu::LocalCache* cp = c.get();
      cu::scan_all(roots, *c, st, stop, [&](const cu::ScanStats& s) {
        if (cu::now_s() - last < 0.6) return;
        last = cu::now_s();
        auto* m = new ScanMsg;
        m->st = s;
        m->rows = cp->rows;
        Fl::awake(scan_msg, m);
      });
      if (st.read > 0) cu::save_local(*c);
      auto* m = new ScanMsg;
      m->done = true;
      m->st = st;
      m->rows = c->rows;
      m->cache = std::move(c);
      Fl::awake(scan_msg, m);
    }).detach();
    refresh();
  }
  static void scan_msg(void* p) {
    std::unique_ptr<ScanMsg> m(static_cast<ScanMsg*>(p));
    if (self()) self()->scanned(*m);
  }
  void scanned(ScanMsg& m) {
    local_rows = std::move(m.rows);
    if (!m.done) {
      if (m.st.total_bytes > 0)
        busy = cu::fmt(tx::READING_N, {cu::bytes((double)m.st.bytes), cu::bytes((double)m.st.total_bytes)});
      refresh();
      return;
    }
    local = std::move(m.cache);
    scanning = false;
    busy.clear();
    updated = cu::now_t();
    if (reset_local) {
      reset_local = false;
      clear_local();
      start_scan();
    }
    refresh();
  }
  void clear_local() {
    local.reset(new cu::LocalCache);
    local_rows.clear();
    if (!live) return;
    std::remove((cu::config_dir() + "/local.cache").c_str());
    std::remove((cu::config_dir() + "/local.seen").c_str());
  }

  void start_fetch() {
    if (fetching || !live) return;
    last_error.clear();
    if (cu::trim(set.key).empty()) {
      refresh();
      return;
    }
    std::vector<int> days = cu::days_to_fetch(api, cu::utc_day(cu::now_t()), set.api_days);
    if (days.empty()) {
      updated = cu::now_t();
      refresh();
      return;
    }
    fetching = true;
    busy = cu::fmt(tx::DOWNLOADING, {"0", std::to_string(days.size())});
    std::string key = set.key;
    std::thread([days, key] {
      int i = 0;
      for (int d : days) {
        auto* m = new ApiMsg;
        m->day = d;
        m->n = ++i;
        m->total = (int)days.size();
        int code = 0;
        m->ok = cu::fetch_day(key, d, m->rows, m->error, code);
        m->t = cu::now_t();
        bool stop = !m->ok;
        Fl::awake(api_msg, m);
        if (stop) break;
      }
      auto* e = new ApiMsg;
      e->done = true;
      Fl::awake(api_msg, e);
    }).detach();
    refresh();
  }
  static void api_msg(void* p) {
    std::unique_ptr<ApiMsg> m(static_cast<ApiMsg*>(p));
    if (self()) self()->fetched(*m);
  }
  void fetched(ApiMsg& m) {
    if (m.done) {
      fetching = false;
      busy.clear();
      updated = cu::now_t();
      save_api();
    } else if (m.ok) {
      cu::replace_day(api.rows, m.day, m.rows);
      api.fetched[m.day] = m.t;
      busy = cu::fmt(tx::DOWNLOADING, {std::to_string(m.n), std::to_string(m.total)});
    } else {
      last_error = m.error;
    }
    refresh();
  }

  // ---- lo que se ve
  void say(const std::string& m) {
    message = m;
    message_until = cu::now_s() + 5;
    update_status();
  }
  void update_status() {
    std::string s;
    if (!message.empty() && cu::now_s() < message_until) s = message;
    else if (!busy.empty()) s = busy;
    else if (!last_error.empty()) s = last_error;
    else if (set.source == 1 && cu::trim(set.key).empty()) s = tx::NEED_KEY;
    else if (updated > 0)
      s = cu::fmt(tx::STATUS_LINE, {set.source == 0 ? tx::SRC_LOCAL : tx::SRC_API, clock_text(updated),
                                    cu::fmt(tx::MINUTES, {std::to_string(std::max(0LL, (next_refresh - cu::now_t() + 59) / 60))})});
    Status->text(" " + s);
  }
  static std::string clock_text(long long t) {
    std::time_t tt = (std::time_t)t;
    std::tm v{};
#ifdef _WIN32
    localtime_s(&v, &tt);
#else
    localtime_r(&tt, &v);
#endif
    char b[16];
    std::strftime(b, sizeof b, "%H:%M", &v);
    return b;
  }
  void refresh() {
    int td = cu::today();
    shown_today = td;
    dash->rows = &rows();
    dash->metric = set.metric;
    dash->period = set.period;
    dash->source = set.source;
    dash->today = td;
    dash->budget = set.budget;
    if (set.source == 0) {
      dash->empty_title = scanning ? tx::READING : tx::EMPTY_LOCAL_T;
      std::string dirs;
      for (const auto& d : log_dirs()) dirs += (dirs.empty() ? "" : ", ") + d;
      dash->empty_help = scanning ? std::string(tx::READING_HELP) : cu::fmt(tx::EMPTY_LOCAL_H, {dirs});
    } else if (cu::trim(set.key).empty()) {
      dash->empty_title = tx::EMPTY_API_T;
      dash->empty_help = tx::EMPTY_API_H;
    } else {
      dash->empty_title = fetching ? tx::DOWNLOADING_T : tx::EMPTY_API_NONE_T;
      dash->empty_help = last_error.empty() ? std::string(tx::EMPTY_API_NONE_H) : last_error;
    }
    dash->redraw();
    update_status();
    check_budget(td);
    if (bar::available()) {
      bar::set(set.source == 1 && cu::trim(set.key).empty() ? "exclamationmark.triangle" : "chart.bar.fill",
               cu::bar_title(rows(), td, set.metric));
      bar::menu(cu::bar_menu(rows(), td, set, shown() && !in_bar, busy));
    }
  }
  void check_budget(int td) {
    if (!live || set.budget <= 0 || set.alerted_month == cu::month_start(td)) return;
    double c = cu::total(rows(), cu::month_start(td), td).cost;
    if (c < set.budget) return;
    set.alerted_month = cu::month_start(td);
    save_settings();
    cu::notify(tx::BUDGET_TITLE, cu::fmt(tx::BUDGET_TEXT, {cu::money(c), cu::money(set.budget)}));
  }
  void picked(int day) {
    dash->selected = day;
    refresh();
  }
  void set_metric(int m) {
    set.metric = std::max(0, std::min(2, m));
    Metric->index(set.metric);
    save_settings();
    refresh();
  }
  void set_period(int p) {
    set.period = std::max(0, std::min(5, p));
    Period->index(set.period);
    save_settings();
    refresh();
  }
  void set_source(int s) {
    if (s == set.source) return;
    set.source = s == 1 ? 1 : 0;
    Source->index(set.source);
    last_error.clear();
    save_settings();
    refresh_data();
    refresh();
    if (set.source == 1 && cu::trim(set.key).empty()) say(tx::NEED_KEY);
  }

  // ---- ajustes
  void make_settings(SettingsUI& ui) {
    const int W = 600, H = 410;
    ui.win = new Fl_Double_Window(W, H, tx::SETTINGS_TITLE);
    ui.win->color(fl_rgb_color(0xf6, 0xf7, 0xfb));
    int y = 20;
    auto label = [&](const char* t, int h = 20, int size = 13, bool bold = true) {
      Fl_Box* b = new Fl_Box(20, y, W - 40, h);
      b->copy_label(t);
      b->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP);
      b->labelsize(size);
      b->labelfont(bold ? FL_HELVETICA_BOLD : FL_HELVETICA);
      if (!bold) b->labelcolor(fl_rgb_color(0x4b, 0x55, 0x63));
      y += h + 2;
      return b;
    };
    label(tx::S_KEY);
    ui.key = new Fl_Secret_Input(20, y, W - 40 - 150, 30);
    ui.key->value(set.key.c_str());
    Fl_Button* create = new Fl_Button(W - 160, y, 140, 30, tx::S_CREATE_KEY);
    create->callback([](Fl_Widget*, void*) { fl_open_uri("https://platform.claude.com/settings/admin-keys"); });
    y += 36;
    label(tx::S_KEY_NOTE, 52, 12, false);
    y += 6;
    auto choice = [&](const char* t, Fl_Choice*& c, const int* vals, int n, int cur, const char* item) {
      Fl_Box* b = new Fl_Box(20, y, 300, 30);
      b->copy_label(t);
      b->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
      b->labelsize(13);
      b->labelfont(FL_HELVETICA_BOLD);
      c = new Fl_Choice(330, y, 150, 30);
      int sel = 0;
      for (int k = 0; k < n; k++) {
        c->add(cu::fmt(item, {std::to_string(vals[k])}).c_str());
        if (vals[k] == cur) sel = k;
      }
      c->value(sel);
      y += 40;
    };
    choice(tx::S_DAYS, ui.days, cu::API_DAYS, cu::API_DAYS_N, set.api_days, tx::S_DAYS_ITEM);
    choice(tx::S_EVERY, ui.every, cu::EVERY, cu::EVERY_N, set.every, tx::MINUTES);
    Fl_Box* bl = new Fl_Box(20, y, 300, 30);
    bl->copy_label(tx::S_BUDGET);
    bl->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
    bl->labelsize(13);
    bl->labelfont(FL_HELVETICA_BOLD);
    ui.budget = new Fl_Input(330, y, 150, 30);
    if (set.budget > 0) ui.budget->value(cu::num(set.budget, set.budget == std::floor(set.budget) ? 0 : 2).c_str());
    y += 40;
    label(tx::S_LOGS);
    ui.logs = new Fl_Input(20, y, W - 40 - 110, 30);
    ui.logs->value(set.logs.c_str());
    Fl_Button* pick = new Fl_Button(W - 120, y, 100, 30, tx::S_PICK);
    pick->callback([](Fl_Widget*, void* d) {
      Fl_Native_File_Chooser ch;
      ch.type(Fl_Native_File_Chooser::BROWSE_DIRECTORY);
      if (ch.show() == 0 && ch.filename()) static_cast<Fl_Input*>(d)->value(ch.filename());
    }, ui.logs);
    y += 36;
    std::string dirs;
    for (const auto& d : cu::default_log_dirs()) dirs += (dirs.empty() ? "" : ", ") + d;
    label(cu::fmt(tx::S_LOGS_NOTE, {dirs}).c_str(), 36, 12, false);
    Fl_Button* cancel_b = new Fl_Button(W - 260, H - 50, 110, 32, tx::CANCEL);
    Fl_Return_Button* save_b = new Fl_Return_Button(W - 140, H - 50, 120, 32, tx::SAVE);
    cancel_b->callback([](Fl_Widget*, void* d) { static_cast<SettingsUI*>(d)->result = 0; }, &ui);
    save_b->callback([](Fl_Widget*, void* d) { static_cast<SettingsUI*>(d)->result = 1; }, &ui);
    ui.win->callback([](Fl_Widget*, void* d) { static_cast<SettingsUI*>(d)->result = 0; }, &ui);
    ui.win->end();
  }
  // Lo escrito en la ventana de ajustes → los ajustes ("" si vale; si no, el error).
  std::string apply_settings(SettingsUI& ui) {
    double budget = cu::parse_money(ui.budget->value());
    if (budget < 0) return tx::S_BAD_BUDGET;
    std::string key = cu::trim(ui.key->value());
    std::string logs = cu::trim(ui.logs->value());
    if (!logs.empty() && !cu::is_dir(logs)) return cu::fmt(tx::S_BAD_LOGS, {logs});
    bool key_changed = key != set.key, logs_changed = logs != cu::trim(set.logs);
    set.key = key;
    set.logs = logs;
    set.budget = budget;
    set.api_days = cu::API_DAYS[std::max(0, ui.days->value())];
    set.every = cu::EVERY[std::max(0, ui.every->value())];
    set.alerted_month = 0;
    next_refresh = cu::now_t() + set.every * 60;
    save_settings();
    if (key_changed) {   // otra organización: lo bajado ya no vale
      api = cu::ApiCache();
      save_api();
    }
    if (logs_changed) {
      if (scanning) {
        reset_local = true;
        cancel = true;
      } else {
        clear_local();
      }
    }
    if (key_changed || logs_changed) refresh_data();
    refresh();
    if (!key.empty() && !cu::looks_like_admin_key(key)) say(tx::S_NOT_ADMIN);
    else say(tx::S_SAVED);
    return "";
  }
  void settings_dialog() {
    SettingsUI ui;
    make_settings(ui);
    ui.win->set_modal();
    ui.win->show();
    while (true) {
      ui.result = -1;
      while (ui.win->shown() && ui.result < 0) Fl::wait();
      if (ui.result != 1) break;
      std::string err = apply_settings(ui);
      if (err.empty()) break;
      fl_alert("%s", err.c_str());
    }
    ui.win->hide();
  }

  void export_csv() {
    Fl_Native_File_Chooser ch;
    ch.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    ch.filter("CSV\t*.csv");
    ch.preset_file(("claude-code-" + cu::iso_day(cu::today()) + ".csv").c_str());
    ch.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM);
    if (ch.show() != 0 || !ch.filename()) return;
    std::string path = ch.filename();
    if (!cu::ends(cu::lower(path), ".csv")) path += ".csv";
    say(cu::write_file(path, cu::csv(rows())) ? cu::fmt(tx::EXPORTED, {path}) : std::string(tx::EXPORT_FAILED));
  }

  // ---- la barra
  void to_bar() {
    if (!bar::available()) { iconize(); return; }
    if (in_bar) return;
    save_settings();
    in_bar = true;
    hide();
    bar::dock(false);
    refresh();
    // Sin ventanas, Fl::run terminaría: aquí sigue la app (como un diálogo).
    while (in_bar && !quitting) Fl::wait(1e20);
    if (quitting) quit_now();
  }
  void from_bar() {
    if (!live) return;
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
    save_settings();
    cancel = true;
    bar::remove();
    in_bar = false;
    hide();
  }
  void quit() {
    quitting = true;
    if (!in_bar) quit_now();
  }
  void quit_now() {
    save_settings();
    cancel = true;
    bar::remove();
    hide();
    std::exit(0);
  }
  void bar_act(int t) {
    int td = cu::today();
    if (t >= cu::A_DAY && t < cu::A_DAY + 7) {
      dash->selected = td - (t - cu::A_DAY);
      from_bar();
      refresh();
      return;
    }
    if (t >= cu::A_METRIC && t < cu::A_METRIC + 3) { set_metric(t - cu::A_METRIC); return; }
    if (t >= cu::A_SRC && t < cu::A_SRC + 2) { set_source(t - cu::A_SRC); return; }
    switch (t) {
      case cu::A_REFRESH: refresh_data(); say(tx::REFRESHING); break;
      case cu::A_WINDOW: from_bar(); break;
      case cu::A_TO_BAR: to_bar(); break;
      case cu::A_SETTINGS:
        from_bar();
        if (live) settings_dialog();
        break;
      case cu::A_QUIT: quit(); break;
    }
  }

  // ---- eventos del diseño
  void Source_select() override { set_source(Source->index()); }
  void Metric_select() override { set_metric(Metric->index()); }
  void Period_select() override { set_period(Period->index()); }
  void BtnRefresh_click() override {
    refresh_data();
    say(tx::REFRESHING);
  }
  void BtnSettings_click() override { settings_dialog(); }
  void BtnBar_click() override { to_bar(); }
  void Tick_timer() override {
    if (next_refresh > 0 && cu::now_t() >= next_refresh) refresh_data();
    if (cu::today() != shown_today) refresh();   // pasó la medianoche
    else update_status();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_REFRESH) BtnRefresh_click();
    else if (item == tx::MP_EXPORT) export_csv();
    else if (item == tx::MP_SETTINGS) settings_dialog();
    else if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_COST) set_metric(cu::M_COST);
    else if (item == tx::MP_TOKENS) set_metric(cu::M_TOKENS);
    else if (item == tx::MP_SESSIONS) set_metric(cu::M_SESSIONS);
    else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_PRICES) fl_message("%s", tx::PRICES_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
  }

  // ---- capturas y pruebas de la interfaz, sin ventana
  static void render_group(Fl_Group* g, const std::string& file) {
    Fl_Image_Surface surf(g->w(), g->h(), 0);
    Fl_Surface_Device::push_current(&surf);
    fl_color(g->color());
    fl_rectf(0, 0, g->w(), g->h());
    for (int i = 0; i < g->children(); i++) {
      Fl_Widget* c = g->child(i);
      if (c->visible()) surf.draw(c, c->x(), c->y());
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    if (!file.empty()) fl_write_png(file.c_str(), img);
    delete img;
  }
  void render_to(const std::string& file) { render_group(this, file); }
  void demo_state(int W, int H) {
    Fl::screen_count();
    live = false;
    setup();
    size(W, H);
    int td = cu::today();
    local_rows = cu::demo_rows(td);
    set = cu::Settings();
    set.budget = 250;
    show_settings_in_ui();
    long long now = cu::now_t();
    updated = now - 3 * 60;
    next_refresh = now + 12 * 60;
    dash->selected = td;
    refresh();
  }
  // El escritorio con la barra de menús y el menú del icono abierto (como
  // en macOS), dibujado con los mismos datos del menú.
  static int draw_menu(int x, int y, const std::vector<cu::MenuEntry>& m, int hi, int* hi_y) {
    const int rowh = 32, seph = 12;
    fl_font(FL_HELVETICA, 15);
    int w = 280, h = 12;
    for (const auto& e : m) {
      w = std::max(w, (int)fl_width(e.title.c_str()) + (e.color >= 0 ? 66 : 48) + (e.sub.empty() ? 0 : 30));
      h += e.sep ? seph : rowh;
    }
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(40 - 4 * k), (uchar)(52 - 4 * k), (uchar)(80 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, w + 2 * k, h + 2 * k, 14 + k);
    }
    cu::round_box(x, y, w, h, 14, cu::rgb(0xf3f3f5), cu::rgb(0xc4c4ca));
    int yy = y + 6;
    for (int i = 0; i < (int)m.size(); i++) {
      const auto& e = m[(size_t)i];
      if (e.sep) {
        fl_color(cu::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + w - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      Fl_Color col = e.tag || !e.sub.empty() ? cu::rgb(0x1d1d1f) : cu::rgb(0x6e6e73);
      if (i == hi) {
        fl_color(cu::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, w - 12, rowh, 8);
        col = FL_WHITE;
        if (hi_y) *hi_y = yy;
      }
      int tx0 = x + 28;
      if (e.checked) {
        fl_color(col);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_draw("✓", x + 10, yy + 22);
      }
      if (e.color >= 0) {
        fl_color(cu::model_color(e.color));
        fl_pie(x + 28, yy + rowh / 2 - 5, 10, 10, 0, 360);
        tx0 = x + 46;
      }
      fl_font(FL_HELVETICA, 15);
      fl_color(col);
      fl_draw(e.title.c_str(), tx0, yy + 22);
      if (!e.sub.empty()) {
        fl_font(FL_HELVETICA, 20);
        fl_draw("›", x + w - 24, yy + 23);
      }
      yy += rowh;
    }
    return x + w;
  }
  void desk(const std::string& file, const char* open_sub, int sub_hi) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(30 + 110 * t), (uchar)(40 + 50 * t), (uchar)(70 + 60 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(cu::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(cu::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    // El icono: unas barras y lo de hoy.
    int td = cu::today(), ix = W - 760;
    std::string title = cu::bar_title(rows(), td, set.metric);
    fl_font(FL_HELVETICA, 16);
    int iw = 26 + (int)fl_width(title.c_str()) + 12;
    fl_color(cu::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 8, 5, iw + 8, BarH - 10, 8);
    fl_color(cu::rgb(0x1d1d1f));
    fl_rectf(ix + 1, 20, 4, 9);
    fl_rectf(ix + 7, 14, 4, 15);
    fl_rectf(ix + 13, 17, 4, 12);
    fl_draw(title.c_str(), ix + 22, 26);
    auto m = cu::bar_menu(rows(), td, set, false, "");
    int item = -1;
    for (int i = 0; i < (int)m.size(); i++)
      if (open_sub && m[(size_t)i].title == open_sub) item = i;
    int hy = 0;
    int right = draw_menu(ix - 12, BarH + 4, m, item, &hy);
    if (item >= 0) draw_menu(right + 2, hy - 6, m[(size_t)item].sub, sub_hi, nullptr);
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  // El centro de la casilla de un día en el mapa (después de dibujar).
  bool cell_of(int day, int& cx, int& cy) {
    for (const auto& h : dash->hits)
      if (h.day == day && h.w == 15) {
        cx = h.x + h.w / 2;
        cy = h.y + h.h / 2;
        return true;
      }
    return false;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    fl_putenv("DMS_CCUSAGE_LOGS=~/.claude/projects");   // sin la carpeta de quien hace las capturas
    demo_state(1200, 820);
    render_to(dir + "/window.png");
    int td = cu::today(), cx = 0, cy = 0;
    // Tokens, este mes y un día con el ratón encima.
    set_metric(cu::M_TOKENS);
    set_period(cu::P_MONTH);
    dash->selected = td - 8;
    render_to("");
    if (cell_of(td - 150, cx, cy)) {
      dash->hover = td - 150;
      dash->hx = cx;
      dash->hy = cy;
    }
    render_to(dir + "/tokens.png");
    dash->hover = -1;
    set_metric(cu::M_COST);
    set_period(cu::P_30);
    dash->selected = td;
    desk(dir + "/menu.png", nullptr, -1);
    desk(dir + "/menu-days.png", tx::LAST_7, 0);
    desk(dir + "/menu-models.png", tx::BY_MODEL_MONTH, -1);
    SettingsUI ui;
    set.key = "sk-ant-admin01-xxxxxxxxxxxxxxxxxxxxxxxx";
    set.budget = 250;
    make_settings(ui);
    render_group(ui.win, dir + "/settings.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1200, 820);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    int td = cu::today();
    render_to("");
    int cells = 0;
    for (const auto& h : dash->hits)
      if (h.w == 15) cells++;
    chk(cells >= 52 * 7 + 1 && cells <= 53 * 7, "el mapa tiene un año de casillas");
    int cx = 0, cy = 0;
    chk(cell_of(td, cx, cy), "hoy está en el mapa");
    int i = dash->hit_at(cx, cy);
    chk(i >= 0 && dash->hits[(size_t)i].day == td, "la casilla de hoy es hoy");
    // Un clic de verdad (el evento FL_PUSH del panel) en otro día.
    chk(cell_of(td - 10, cx, cy), "hace 10 días está en el mapa");
    Fl::e_x = cx;
    Fl::e_y = cy;
    dash->handle(FL_PUSH);
    chk(dash->selected == td - 10, "clic en un día");
    // Pasar el ratón enseña el día.
    Fl::e_x = cx;
    Fl::e_y = cy;
    dash->handle(FL_MOVE);
    chk(dash->hover == td - 10, "el ratón encima de un día");
    dash->handle(FL_LEAVE);
    chk(dash->hover == -1, "el ratón se va");
    // Ver tokens y otro periodo, desde los combos.
    Metric->index(1);
    Metric_select();
    chk(set.metric == cu::M_TOKENS && dash->metric == cu::M_TOKENS, "ver tokens");
    Period->index(cu::P_YEAR);
    Period_select();
    chk(set.period == cu::P_YEAR && dash->period == cu::P_YEAR, "periodo");
    render_to("");
    // Una barra de los 30 días también elige el día.
    bool bar_hit = false;
    for (const auto& h : dash->hits)
      if (h.w != 15 && h.day == td - 3) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h - 2;
        dash->handle(FL_PUSH);
        bar_hit = dash->selected == td - 3;
      }
    chk(bar_hit, "clic en una barra");
    // El menú de la barra.
    bar_act(cu::A_METRIC + 2);
    chk(set.metric == cu::M_SESSIONS, "ver sesiones desde la barra");
    bar_act(cu::A_DAY + 4);
    chk(dash->selected == td - 4, "un día desde la barra");
    auto m = cu::bar_menu(rows(), td, set, true, "");
    bool to_bar_item = false;
    for (const auto& e : m)
      if (e.tag == cu::A_TO_BAR) to_bar_item = true;
    chk(to_bar_item, "con la ventana abierta, «Minimizar a la barra»");
    // Origen API sin clave: avisa.
    Source->index(1);
    Source_select();
    chk(set.source == 1 && dash->empty_title == tx::EMPTY_API_T, "API sin clave");
    std::string st = Status->text();
    chk(st.find(tx::NEED_KEY) != std::string::npos, "aviso de la clave");
    Source->index(0);
    Source_select();
    chk(set.source == 0 && !rows().empty(), "volver a los registros");
    // Los ajustes: un presupuesto mal escrito no vale; bien, sí.
    SettingsUI ui;
    make_settings(ui);
    ui.budget->value("doscientos");
    chk(apply_settings(ui) == tx::S_BAD_BUDGET, "presupuesto mal escrito");
    ui.budget->value("300");
    ui.every->value(2);
    ui.days->value(3);
    ui.key->value("sk-ant-admin01-abc");
    chk(apply_settings(ui).empty() && set.budget == 300 && set.every == 30 && set.api_days == 365 && set.key == "sk-ant-admin01-abc",
        "guardar los ajustes");
    ui.logs->value("/no/existe/esta/carpeta");
    chk(!apply_settings(ui).empty(), "carpeta que no existe");
    chk(!cu::csv(rows()).empty(), "exportar");
    render_to("");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
