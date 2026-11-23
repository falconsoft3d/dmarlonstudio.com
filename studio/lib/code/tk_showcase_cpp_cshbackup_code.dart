part of 'tk_examples.dart';

// El código en C++ de los respaldos de community.sh
// (tk_showcase_cpp_cshbackup.dart): va tal cual en Form1.cpp, después de los
// textos (namespace tx).
const _cshbkIncludes = r'''#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <memory>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
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
#include <crt_externs.h>
#include <mach-o/dyld.h>
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _cshbkCode = r'''
// ============================================================ los datos
// Las instancias del panel de community.sh y sus respaldos. Todo va por la
// API REST del panel con un token personal (Authorization: Bearer csh_…):
//   GET  /api/instances/                     las instancias
//   POST /api/instances/<id>/backup/         un respaldo nuevo (una tarea)
//   GET  /api/tasks/<id>/                    cómo va esa tarea
//   GET  /api/backups/?instance=<nombre>     sus respaldos, el último primero
//   GET  /api/backups/<id>/download/         el archivo
// Las peticiones las hace curl (lo traen macOS y Windows 10 y posteriores)
// en otro hilo; el token va en un archivo temporal que solo lee el usuario.
// También servidores Linux (Ubuntu…) por SSH, con clave o contraseña: cada
// base de datos de PostgreSQL se vuelca con pg_dump a un archivo del equipo.
namespace cb {

inline int imax(int a, int b) { return a > b ? a : b; }
inline int imin(int a, int b) { return a < b ? a : b; }

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
bool starts(const std::string& s, const std::string& p) { return s.compare(0, p.size(), p) == 0; }
bool ends(const std::string& s, const std::string& p) {
  return s.size() >= p.size() && s.compare(s.size() - p.size(), p.size(), p) == 0;
}
// Sin tabuladores ni saltos de línea (para guardar en una línea).
std::string clean(const std::string& s) {
  std::string o;
  for (char c : s) o += (c == '\t' || c == '\n' || c == '\r') ? ' ' : c;
  return trim(o);
}
long long now_t() { return (long long)std::time(nullptr); }
// Un número entero o decimal escrito con punto (sin depender del idioma).
double parse_num(const std::string& s) {
  size_t i = 0;
  while (i < s.size() && s[i] == ' ') i++;
  bool neg = i < s.size() && s[i] == '-';
  if (i < s.size() && (s[i] == '-' || s[i] == '+')) i++;
  double v = 0;
  while (i < s.size() && std::isdigit((unsigned char)s[i])) v = v * 10 + (s[i++] - '0');
  if (i < s.size() && s[i] == '.') {
    i++;
    double f = 0.1;
    while (i < s.size() && std::isdigit((unsigned char)s[i])) {
      v += (s[i++] - '0') * f;
      f /= 10;
    }
  }
  return neg ? -v : v;
}
long long to_ll(const std::string& s) { return (long long)parse_num(s); }

// ------------------------------------------------------------ JSON
// Lo justo para leer lo que contesta el panel.
struct J {
  enum T { NUL, BOOL, NUM, STR, ARR, OBJ } t = NUL;
  bool b = false;
  double n = 0;
  std::string s;
  std::vector<J> items;               // la lista, o los valores del objeto
  std::vector<std::string> keys;      // las claves del objeto
  const J& operator[](const std::string& k) const {
    static const J none;
    for (size_t i = 0; i < keys.size(); i++)
      if (keys[i] == k) return items[i];
    return none;
  }
  std::string str() const {
    if (t == STR) return s;
    if (t == NUM) {
      char buf[40];
      std::snprintf(buf, sizeof buf, "%.0f", n);
      return buf;
    }
    if (t == BOOL) return b ? "true" : "false";
    return "";
  }
  long long num() const { return t == NUM ? (long long)n : t == STR ? to_ll(s) : 0; }
  bool truthy() const { return t == BOOL ? b : t == NUM ? n != 0 : t == STR ? (s == "true" || s == "1") : false; }
};

struct JParser {
  const std::string& s;
  size_t i = 0;
  bool ok = true;
  explicit JParser(const std::string& text) : s(text) {}
  void ws() {
    while (i < s.size() && (s[i] == ' ' || s[i] == '\n' || s[i] == '\r' || s[i] == '\t')) i++;
  }
  bool lit(const char* w) {
    size_t n = std::strlen(w);
    if (s.compare(i, n, w) != 0) return false;
    i += n;
    return true;
  }
  unsigned hex4() {
    unsigned v = 0;
    for (int k = 0; k < 4; k++, i++) {
      if (i >= s.size()) { ok = false; return 0; }
      char c = s[i];
      v <<= 4;
      if (c >= '0' && c <= '9') v |= (unsigned)(c - '0');
      else if (c >= 'a' && c <= 'f') v |= (unsigned)(c - 'a' + 10);
      else if (c >= 'A' && c <= 'F') v |= (unsigned)(c - 'A' + 10);
      else ok = false;
    }
    return v;
  }
  static void utf8(std::string& o, unsigned c) {
    if (c < 0x80) o += (char)c;
    else if (c < 0x800) { o += (char)(0xC0 | (c >> 6)); o += (char)(0x80 | (c & 0x3F)); }
    else if (c < 0x10000) { o += (char)(0xE0 | (c >> 12)); o += (char)(0x80 | ((c >> 6) & 0x3F)); o += (char)(0x80 | (c & 0x3F)); }
    else {
      o += (char)(0xF0 | (c >> 18));
      o += (char)(0x80 | ((c >> 12) & 0x3F));
      o += (char)(0x80 | ((c >> 6) & 0x3F));
      o += (char)(0x80 | (c & 0x3F));
    }
  }
  std::string string() {
    std::string o;
    i++;   // la comilla
    while (i < s.size() && s[i] != '"') {
      char c = s[i++];
      if (c != '\\') { o += c; continue; }
      if (i >= s.size()) break;
      char e = s[i++];
      switch (e) {
        case 'n': o += '\n'; break;
        case 't': o += '\t'; break;
        case 'r': o += '\r'; break;
        case 'b': o += '\b'; break;
        case 'f': o += '\f'; break;
        case 'u': {
          unsigned c1 = hex4();
          if (c1 >= 0xD800 && c1 < 0xDC00 && s.compare(i, 2, "\\u") == 0) {
            i += 2;
            unsigned c2 = hex4();
            if (c2 >= 0xDC00 && c2 < 0xE000) c1 = 0x10000 + ((c1 - 0xD800) << 10) + (c2 - 0xDC00);
          }
          utf8(o, c1);
          break;
        }
        default: o += e;
      }
    }
    if (i >= s.size()) ok = false;
    else i++;
    return o;
  }
  J value(int depth) {
    J v;
    ws();
    if (i >= s.size() || depth > 64) { ok = false; return v; }
    char c = s[i];
    if (c == '{' || c == '[') {
      bool obj = c == '{';
      v.t = obj ? J::OBJ : J::ARR;
      i++;
      ws();
      if (i < s.size() && s[i] == (obj ? '}' : ']')) { i++; return v; }
      while (ok) {
        if (obj) {
          ws();
          if (i >= s.size() || s[i] != '"') { ok = false; break; }
          v.keys.push_back(string());
          ws();
          if (i >= s.size() || s[i] != ':') { ok = false; break; }
          i++;
        }
        v.items.push_back(value(depth + 1));
        ws();
        if (i < s.size() && s[i] == ',') { i++; continue; }
        if (i < s.size() && s[i] == (obj ? '}' : ']')) { i++; break; }
        ok = false;
      }
    } else if (c == '"') {
      v.t = J::STR;
      v.s = string();
    } else if (lit("true")) {
      v.t = J::BOOL;
      v.b = true;
    } else if (lit("false")) {
      v.t = J::BOOL;
    } else if (lit("null")) {
    } else {
      size_t st = i;
      while (i < s.size() && (std::isdigit((unsigned char)s[i]) || s[i] == '-' || s[i] == '+' || s[i] == '.' || s[i] == 'e' || s[i] == 'E')) i++;
      if (st == i) { ok = false; return v; }
      v.t = J::NUM;
      v.n = parse_num(s.substr(st, i - st));
    }
    return v;
  }
};
bool parse_json(const std::string& text, J& out) {
  JParser p(text);
  out = p.value(0);
  p.ws();
  return p.ok && p.i == text.size();
}

// ------------------------------------------------------------ el modelo
enum State { B_IDLE = 0, B_QUEUED, B_CREATING, B_LISTING, B_DOWNLOADING, B_OK, B_SKIPPED, B_ERROR };

struct Inst {
  int id = 0;
  int src = 0;   // 0: el panel; si no, el id del servidor SSH
  std::string name, version, status;   // en un servidor: la base, el servidor y usuario@host
  std::string rel;   // su carpeta, dentro de la de los respaldos (y su clave en los bajados)
  bool on = true;   // se respalda
  // El último respaldo en el panel.
  int cloud_id = 0;
  std::string cloud_file, cloud_date;
  long long cloud_size = 0;
  bool cloud_fs = false;
  // En este equipo.
  int state = B_IDLE;
  std::string error, local_file, part;
  long long local_t = 0, local_size = 0, total = 0, got = 0;
};

struct Backup {
  int id = 0;
  std::string instance, filename, created;
  long long size = 0;
  bool fs = false;
};

// La lista del panel (la API la da entera; si algún día pagina, en «results»).
const J& rows_of(const J& j) { return j.t == J::OBJ && j["results"].t == J::ARR ? j["results"] : j; }

std::vector<Inst> parse_instances(const J& j) {
  std::vector<Inst> out;
  const J& rows = rows_of(j);
  for (const auto& r : rows.items) {
    if (r.t != J::OBJ) continue;
    Inst in;
    in.id = (int)r["id"].num();
    in.name = clean(r["name"].str());
    in.version = clean(r["odoo_version"].str());
    in.status = clean(r["status"].str());
    if (in.id > 0 && !in.name.empty()) out.push_back(in);
  }
  return out;
}
std::vector<Backup> parse_backups(const J& j) {
  std::vector<Backup> out;
  for (const auto& r : rows_of(j).items) {
    if (r.t != J::OBJ) continue;
    Backup b;
    b.id = (int)r["id"].num();
    b.instance = r["instance"].str();
    b.filename = r["filename"].str();
    b.created = r["created_at"].str();
    b.size = r["file_size"].num();
    b.fs = r["include_filestore"].truthy();
    if (b.id > 0 && !b.filename.empty()) out.push_back(b);
  }
  return out;
}
// El más reciente (el panel ya los ordena, pero por si acaso: la fecha ISO).
int newest(const std::vector<Backup>& list) {
  int best = -1;
  for (int i = 0; i < (int)list.size(); i++)
    if (best < 0 || list[(size_t)i].created > list[(size_t)best].created) best = i;
  return best;
}
// Lo que dice una tarea fallida: su resultado o la última línea de su registro.
std::string task_error(const J& t) {
  std::string r = t["result"].t == J::STR ? t["result"].s : t["result"]["error"].str();
  if (trim(r).empty()) {
    auto lines = split(t["log"].str(), '\n');
    for (auto it = lines.rbegin(); it != lines.rend(); ++it)
      if (!trim(*it).empty()) { r = trim(*it); break; }
  }
  r = clean(r);
  return r.size() > 200 ? r.substr(0, 200) + "…" : r;
}

// «communitysh.xyz», «https://communitysh.xyz/» o «…/api» → «https://communitysh.xyz».
std::string normalize_base(const std::string& raw) {
  std::string u = trim(raw);
  if (u.empty() || u.find(' ') != std::string::npos) return "";
  if (!starts(lower(u), "http://") && !starts(lower(u), "https://")) u = "https://" + u;
  while (!u.empty() && u.back() == '/') u.pop_back();
  if (ends(lower(u), "/api")) u = u.substr(0, u.size() - 4);
  while (!u.empty() && u.back() == '/') u.pop_back();
  size_t host = u.find("://") + 3;
  if (host >= u.size() || u.find('.', host) == std::string::npos) {
    // localhost:8000 vale para probar
    if (u.find("localhost", host) == std::string::npos && u.find("127.0.0.1", host) == std::string::npos) return "";
  }
  return u;
}
std::string url_encode(const std::string& s) {
  std::string o;
  const char* hex = "0123456789ABCDEF";
  for (unsigned char c : s) {
    if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') o += (char)c;
    else {
      o += '%';
      o += hex[c >> 4];
      o += hex[c & 15];
    }
  }
  return o;
}
// Un nombre de archivo o de carpeta válido en macOS y en Windows.
std::string safe_name(const std::string& s) {
  std::string o;
  for (char c : s) {
    unsigned char u = (unsigned char)c;
    o += (u < 32 || std::strchr("<>:\"/\\|?*", c)) ? '_' : c;
  }
  while (!o.empty() && (o.back() == '.' || o.back() == ' ')) o.pop_back();
  while (!o.empty() && (o[0] == '.' || o[0] == ' ')) o.erase(0, 1);
  return o.empty() ? "_" : o;
}
#ifdef _WIN32
const char* const SEP = "\\";
#else
const char* const SEP = "/";
#endif
std::string join(const std::string& dir, const std::string& name) {
  if (dir.empty()) return name;
  char last = dir.back();
  return (last == '/' || last == '\\') ? dir + name : dir + SEP + name;
}

// ------------------------------------------------------------ números y fechas
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}
// «512 B», «45,6 KB», «1,2 GB».
std::string human(long long bytes) {
  if (bytes < 0) bytes = 0;
  const char* units[] = {"B", "KB", "MB", "GB", "TB"};
  double v = (double)bytes;
  int u = 0;
  while (v >= 1024 && u < 4) { v /= 1024; u++; }
  return (u == 0 ? std::to_string(bytes) : num(v, v < 10 ? 1 : 0)) + " " + units[u];
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
std::string hhmm(const struct tm& v) {
  char b[16];
  std::snprintf(b, sizeof b, "%02d:%02d", v.tm_hour, v.tm_min);
  return b;
}
std::string day_name(int monday0, bool shrt) {
  auto names = split(shrt ? tx::WD_SHORT : tx::WDAYS, ',');
  return monday0 >= 0 && monday0 < (int)names.size() ? trim(names[(size_t)monday0]) : "";
}
// «hoy 03:00», «mañana 03:00», «ayer 15:12», «lun 24/11 03:00».
std::string when(long long t, long long now) {
  if (t <= 0) return tx::NEVER;
  struct tm v = local(t), n = local(now);
  long long day = (long long)(v.tm_year) * 400 + v.tm_yday, today = (long long)(n.tm_year) * 400 + n.tm_yday;
  if (v.tm_year == n.tm_year) {
    if (day == today) return fmt(tx::TODAY, {hhmm(v)});
    if (day == today + 1) return fmt(tx::TOMORROW, {hhmm(v)});
    if (day == today - 1) return fmt(tx::YESTERDAY, {hhmm(v)});
  }
  char b[32];
  std::snprintf(b, sizeof b, "%02d/%02d %s", v.tm_mday, v.tm_mon + 1, hhmm(v).c_str());
  return day_name((v.tm_wday + 6) % 7, true) + " " + b;
}
// «2026-11-23T03:10:05.12+01:00» → «23/11/2026 03:10».
std::string iso_date(const std::string& iso) {
  if (iso.size() < 16 || iso[4] != '-' || iso[7] != '-') return iso;
  return iso.substr(8, 2) + "/" + iso.substr(5, 2) + "/" + iso.substr(0, 4) + " " + iso.substr(11, 5);
}

// ------------------------------------------------------------ la secuencia
// Cada hora, cada 2, 3, 4, 6 o 12 horas (contadas desde la hora elegida),
// cada día o cada semana el día elegido, siempre a la hora en punto. Si el
// equipo estaba apagado o dormido a esa hora, el respaldo se hace en cuanto
// vuelve. Se guarda en horas (168: cada semana).
const int EVERY_H[] = {1, 2, 3, 4, 6, 12, 24, 168};
const int EVERY_N = 8;
const int WEEK_H = 168;
int every_index(int hours) {
  for (int i = 0; i < EVERY_N; i++)
    if (EVERY_H[i] == hours) return i;
  return 6;   // cada día
}
// Borrar los bajados tras N días (0: nunca); 3 por defecto.
const int DAYS[] = {1, 2, 3, 7, 14, 30, 0};
const int DAYS_N = 7;

long long next_slot(long long from, int every, int hour, int wday) {
  struct tm d = local(from);
  d.tm_min = 0;
  d.tm_sec = 0;
  int step = every >= 24 ? 24 : (every < 1 ? 1 : every);
  for (int k = 0; k <= 24 * 8; k++) {
    struct tm c = d;
    c.tm_hour = d.tm_hour + k;
    c.tm_isdst = -1;
    time_t x = std::mktime(&c);
    if ((long long)x <= from) continue;
    struct tm v = local((long long)x);
    if (v.tm_min != 0) continue;
    int dh = ((v.tm_hour - hour) % 24 + 24) % 24;
    if (dh % step != 0) continue;
    if (every == WEEK_H && (v.tm_wday + 6) % 7 != wday) continue;
    return (long long)x;
  }
  return from + 86400;
}

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_CSHBK_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\cshbackup";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/cshbackup";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/cshbackup";
#endif
}
bool testing() { return fl_getenv("DMS_CSHBK_CONFIG") != nullptr; }
std::string default_folder() {
#ifdef _WIN32
  const char* h = fl_getenv("USERPROFILE");
  return std::string(h ? h : ".") + "\\Documents\\" + tx::DEFAULT_FOLDER;
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Documents/" + tx::DEFAULT_FOLDER;
#endif
}
bool read_file(const std::string& path, std::string& out, size_t limit = 0) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) {
    out.append(buf, n);
    if (limit && out.size() >= limit) break;
  }
  std::fclose(f);
  return true;
}
bool write_file(const std::string& path, const std::string& data) {
  FILE* f = fl_fopen(path.c_str(), "wb");
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  return std::fclose(f) == 0 && ok;
}
// Un archivo que solo lee el usuario (el token va en él).
bool write_private(const std::string& path, const std::string& data) {
#ifdef _WIN32
  return write_file(path, data);   // %APPDATA% ya es solo del usuario
#else
  int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0600);
  if (fd < 0) return false;
  fchmod(fd, 0600);
  bool ok = ::write(fd, data.data(), data.size()) == (ssize_t)data.size();
  return close(fd) == 0 && ok;
#endif
}
long long file_size(const std::string& path) {
  struct stat st;
  if (fl_stat(path.c_str(), &st) != 0) return -1;
  return (long long)st.st_size;
}
bool exists(const std::string& path) { return file_size(path) >= 0; }

// ------------------------------------------------------------ curl
std::string curl_quote(const std::string& s) {
  std::string o = "\"";
  for (char c : s) {
    if (c == '\n' || c == '\r') continue;
    if (c == '"' || c == '\\') o += '\\';
    o += c;
  }
  return o + "\"";
}

struct Req {
  std::string base, token, method = "GET", path, data, out_file;
  int max_time = 60;
};
std::string curl_config(const Req& r) {
  std::string c = "url = " + curl_quote(r.base + r.path) + "\n";
  if (r.method != "GET") c += "request = " + curl_quote(r.method) + "\n";
  c += "header = " + curl_quote("Authorization: Bearer " + r.token) + "\n";
  c += "header = \"Accept: application/json\"\n";
  if (!r.data.empty() || r.method == "POST") c += "data = " + curl_quote(r.data) + "\n";
  c += "silent\nshow-error\nlocation\nconnect-timeout = 15\n";
  if (r.max_time > 0) c += "max-time = " + std::to_string(r.max_time) + "\n";
  else c += "speed-limit = 1\nspeed-time = 300\n";   // una descarga parada se corta
  c += "user-agent = \"DMarlonStudio-CommunityBackups/1.0\"\n";
  if (!r.out_file.empty()) c += "output = " + curl_quote(r.out_file) + "\n";
  c += "write-out = \"\\n%{http_code}\"\n";
  return c;
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

struct Resp {
  int code = 0;   // el código HTTP; 0 si no hubo respuesta; -1 sin curl
  std::string body, error;
};
// Lo que dijo curl: el cuerpo y, en la última línea, el código HTTP.
Resp parse_resp(const std::string& out, int exit_code) {
  Resp r;
  size_t nl = out.find_last_of('\n');
  std::string last = trim(nl == std::string::npos ? out : out.substr(nl + 1));
  r.body = nl == std::string::npos ? "" : out.substr(0, nl);
  if (!last.empty() && std::isdigit((unsigned char)last[0])) r.code = std::atoi(last.c_str());
  if (exit_code < 0) {
    r.code = -1;
    r.error = tx::E_NO_CURL;
  } else if (r.code == 0) {
    // «curl: (6) Could not resolve host: x» → «Could not resolve host: x»
    std::string e = trim(r.body);
    size_t k = e.find_last_of('\n');
    if (k != std::string::npos) e = trim(e.substr(k + 1));
    size_t p = e.find(") ");
    if (starts(e, "curl:") && p != std::string::npos) e = e.substr(p + 2);
    r.error = e.empty() ? tx::E_BAD_ANSWER : e;
  }
  return r;
}
std::atomic<int>& counter() {
  static std::atomic<int> c{0};
  return c;
}
Resp http(const Req& req) {
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = join(dir, "req-" + std::to_string(now_t()) + "-" + std::to_string(counter()++) + ".cfg");
  Resp r;
  if (!write_private(path, curl_config(req))) {
    r.error = fmt(tx::E_FOLDER, {dir});
    return r;
  }
  std::string out;
  int code = run_capture(path, out);
  fl_unlink(path.c_str());
  return parse_resp(out, code);
}
// El mensaje de error de una respuesta (con el detalle del panel si lo hay).
std::string http_error(const Resp& r, bool writing) {
  if (r.code == -1) return tx::E_NO_CURL;
  if (r.code == 0) return fmt(tx::E_CONNECT, {r.error});
  if (r.code == 401) return tx::E_TOKEN;
  if (r.code == 403) return writing ? tx::E_READONLY : tx::E_FORBIDDEN;
  if (r.code == 404) return tx::E_NOT_FOUND;
  if (r.code == 429) return tx::E_RATE;
  std::string detail;
  J j;
  if (parse_json(trim(r.body), j)) detail = clean(j["detail"].str());
  std::string e = fmt(tx::E_HTTP, {std::to_string(r.code)});
  return detail.empty() ? e : e + ": " + detail;
}

// ------------------------------------------------------------ el respaldo
// Lo que el hilo de los respaldos cuenta a la ventana.
enum EvKind { EV_STATE = 1, EV_CLOUD, EV_LOCAL, EV_DONE, EV_INSTANCES, EV_TEST };
struct Ev {
  int kind = 0, id = 0, state = 0, cloud_id = 0, src = 0;
  std::string error, file, date, part;
  long long size = 0, total = 0;
  bool fs = false;
  std::vector<Inst> list;
};
// Un servidor Linux con PostgreSQL al que se entra por SSH, con una clave
// (sin contraseña: la de ~/.ssh o un archivo) o con una contraseña.
struct Server {
  int id = 0;
  std::string name, host, user = "root", key;
  int port = 22;
  bool password = false;
  std::string secret;   // la contraseña, solo en memoria (se guarda en el Llavero)
};
std::string server_label(const Server& s) {
  return s.user + "@" + s.host + (s.port != 22 ? ":" + std::to_string(s.port) : "");
}
struct JobItem {
  int id = 0;
  std::string name;
  int src = 0;
};
struct Job {
  std::string base, token, folder;
  bool fresh = false, fs = false;
  std::vector<JobItem> items;
  std::vector<Server> servers;   // con su contraseña
};
using Post = std::function<void(const Ev&)>;

void sleep_s(int s, const std::atomic<bool>& cancel) {
  for (int k = 0; k < s * 10 && !cancel; k++) std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

// Una instancia: (un respaldo nuevo,) el último del panel y bajarlo.
void backup_one(const Job& job, int id, const std::string& name, const Post& post, const std::atomic<bool>& cancel) {
  auto state = [&](int st, const std::string& err) {
    Ev e;
    e.kind = EV_STATE;
    e.id = id;
    e.state = st;
    e.error = err;
    post(e);
  };
  if (job.token.empty()) { state(B_ERROR, tx::NEED_TOKEN); return; }
  Req base;
  base.base = job.base;
  base.token = job.token;
  if (job.fresh) {
    state(B_CREATING, "");
    Req q = base;
    q.method = "POST";
    q.path = "/api/instances/" + std::to_string(id) + "/backup/";
    q.data = std::string("include_filestore=") + (job.fs ? "true" : "false");
    Resp r = http(q);
    if (r.code < 200 || r.code > 299) { state(B_ERROR, http_error(r, true)); return; }
    J j;
    long long task = parse_json(trim(r.body), j) ? j["task_id"].num() : 0;
    if (task <= 0) { state(B_ERROR, tx::E_BAD_ANSWER); return; }
    long long until = now_t() + 4 * 3600;
    int fails = 0;
    sleep_s(3, cancel);
    while (!cancel) {
      Req t = base;
      t.path = "/api/tasks/" + std::to_string(task) + "/";
      Resp a = http(t);
      J tj;
      if (a.code == 200 && parse_json(trim(a.body), tj)) {
        fails = 0;
        std::string st = tj["status"].str();
        if (st == "done") break;
        if (st == "failed") { state(B_ERROR, fmt(tx::E_TASK_FAILED, {task_error(tj)})); return; }
      } else if (a.code == 401 || a.code == 403 || a.code == 404 || ++fails > 30) {
        state(B_ERROR, http_error(a, false));
        return;
      }
      if (now_t() > until) { state(B_ERROR, tx::E_TIMEOUT); return; }
      sleep_s(10, cancel);
    }
    if (cancel) return;
  }
  state(B_LISTING, "");
  Req l = base;
  l.path = "/api/backups/?instance=" + url_encode(name);
  Resp lr = http(l);
  J lj;
  if (lr.code != 200) { state(B_ERROR, http_error(lr, false)); return; }
  if (!parse_json(trim(lr.body), lj)) { state(B_ERROR, tx::E_BAD_ANSWER); return; }
  auto list = parse_backups(lj);
  int bi = newest(list);
  if (bi < 0) { state(B_ERROR, tx::E_NO_BACKUPS); return; }
  const Backup& b = list[(size_t)bi];
  Ev c;
  c.kind = EV_CLOUD;
  c.id = id;
  c.cloud_id = b.id;
  c.file = b.filename;
  c.date = b.created;
  c.size = b.size;
  c.fs = b.fs;
  post(c);
  std::string dir = join(job.folder, safe_name(name));
  fl_make_path(dir.c_str());
  if (!fl_filename_isdir(dir.c_str())) { state(B_ERROR, fmt(tx::E_FOLDER, {dir})); return; }
  std::string dest = join(dir, safe_name(b.filename));
  Ev done;
  done.kind = EV_LOCAL;
  done.id = id;
  done.file = dest;
  if (b.size > 0 && file_size(dest) == b.size) {   // ya estaba bajado
    done.state = B_SKIPPED;
    done.size = b.size;
    post(done);
    return;
  }
  std::string part = dest + ".part";
  fl_unlink(part.c_str());
  Ev d;
  d.kind = EV_STATE;
  d.id = id;
  d.state = B_DOWNLOADING;
  d.part = part;
  d.total = b.size;
  post(d);
  Req g = base;
  g.path = "/api/backups/" + std::to_string(b.id) + "/download/";
  g.out_file = part;
  g.max_time = 0;
  Resp gr = http(g);
  if (gr.code != 200) {
    if (gr.code > 0) read_file(part, gr.body, 4096);   // el error del panel quedó en el archivo
    fl_unlink(part.c_str());
    state(B_ERROR, http_error(gr, false));
    return;
  }
  long long got = file_size(part);
  if (got < 0 || (b.size > 0 && got != b.size)) {
    fl_unlink(part.c_str());
    state(B_ERROR, fmt(tx::E_SIZE, {human(got < 0 ? 0 : got), human(b.size)}));
    return;
  }
  fl_unlink(dest.c_str());
  if (fl_rename(part.c_str(), dest.c_str()) != 0) {
    fl_unlink(part.c_str());
    state(B_ERROR, fmt(tx::E_RENAME, {dest}));
    return;
  }
  done.state = B_OK;
  done.size = got;
  post(done);
}
void backup_ssh(const Job& job, const JobItem& it, const Post& post, const std::atomic<bool>& cancel);
void run_job(const Job& job, const Post& post, const std::atomic<bool>& cancel) {
  for (const auto& it : job.items) {
    if (cancel) break;
    if (it.src > 0) backup_ssh(job, it, post, cancel);
    else backup_one(job, it.id, it.name, post, cancel);
  }
  Ev e;
  e.kind = EV_DONE;
  post(e);
}
// Las instancias del panel (al conectar).
Ev fetch_instances(const std::string& base_url, const std::string& token) {
  Ev e;
  e.kind = EV_INSTANCES;
  Req q;
  q.base = base_url;
  q.token = token;
  q.path = "/api/instances/";
  Resp r = http(q);
  J j;
  if (r.code != 200) e.error = http_error(r, false);
  else if (!parse_json(trim(r.body), j)) e.error = tx::E_BAD_ANSWER;
  else e.list = parse_instances(j);
  return e;
}

// ------------------------------------------------------------ los bajados
// Lo que bajó la app (para conservar solo los N últimos de cada instancia:
// nunca se borra un archivo que no haya bajado ella).
struct Got {
  std::string inst, path;
  long long t = 0, size = 0;
};
std::string serialize_got(const std::vector<Got>& g) {
  std::string o;
  for (const auto& x : g) o += clean(x.inst) + "\t" + clean(x.path) + "\t" + std::to_string(x.t) + "\t" + std::to_string(x.size) + "\n";
  return o;
}
std::vector<Got> parse_got(const std::string& text) {
  std::vector<Got> out;
  for (const auto& line : split(text, '\n')) {
    auto f = split(line, '\t');
    if (f.size() < 4 || f[1].empty()) continue;
    out.push_back({f[0], f[1], to_ll(f[2]), to_ll(f[3])});
  }
  return out;
}
// Apunta un archivo bajado (el mismo archivo no cuenta dos veces).
void add_got(std::vector<Got>& g, const Got& x) {
  for (size_t i = 0; i < g.size();)
    if (g[i].path == x.path) g.erase(g.begin() + (long)i);
    else i++;
  g.push_back(x);
}
// Los bajados hace más de [days] días (0: nunca se borran), que se quitan de
// la lista. El más reciente de cada instancia se queda siempre, aunque sea
// antiguo: si el panel deja de contestar, no se queda sin ninguno.
std::vector<std::string> prune_got(std::vector<Got>& g, long long now, int days) {
  std::vector<std::string> drop;
  if (days <= 0) return drop;
  std::vector<Got> rest;
  for (size_t i = 0; i < g.size(); i++) {
    bool newest = true;
    for (size_t k = 0; k < g.size(); k++)
      if (k != i && g[k].inst == g[i].inst && (g[k].t > g[i].t || (g[k].t == g[i].t && k > i))) newest = false;
    if (!newest && now - g[i].t > (long long)days * 86400) drop.push_back(g[i].path);
    else rest.push_back(g[i]);
  }
  g = rest;
  return drop;
}

// ------------------------------------------------------------ los ajustes
struct Settings {
  std::string base = "https://communitysh.xyz", folder;
  int every = 24, hour = 3, wday = 0, days = 3;
  bool fresh = false, fs = false, login = false;
  long long next_run = 0, last_run = 0;
  std::vector<Server> servers;
};
std::string serialize(const Settings& s, const std::vector<Inst>& insts) {
  std::string o;
  o += "base\t" + clean(s.base) + "\n";
  o += "folder\t" + clean(s.folder) + "\n";
  o += "every\t" + std::to_string(s.every) + "\nhour\t" + std::to_string(s.hour) + "\nwday\t" + std::to_string(s.wday) + "\n";
  o += "days\t" + std::to_string(s.days) + "\n";
  o += std::string("fresh\t") + (s.fresh ? "1" : "0") + "\nfs\t" + (s.fs ? "1" : "0") + "\nlogin\t" + (s.login ? "1" : "0") + "\n";
  o += "next\t" + std::to_string(s.next_run) + "\nlast\t" + std::to_string(s.last_run) + "\n";
  for (const auto& v : s.servers)
    o += "server\t" + std::to_string(v.id) + "\t" + clean(v.name) + "\t" + clean(v.host) + "\t" + std::to_string(v.port) + "\t" +
         clean(v.user) + "\t" + (v.password ? "1" : "0") + "\t" + clean(v.key) + "\n";
  for (const auto& i : insts) {
    int st = (i.state == B_OK || i.state == B_SKIPPED || i.state == B_ERROR) ? i.state : B_IDLE;
    o += "inst\t" + std::to_string(i.id) + "\t" + clean(i.name) + "\t" + clean(i.version) + "\t" + clean(i.status) + "\t" +
         (i.on ? "1" : "0") + "\t" + std::to_string(st) + "\t" + clean(i.error) + "\t" + clean(i.local_file) + "\t" +
         std::to_string(i.local_t) + "\t" + std::to_string(i.local_size) + "\t" + clean(i.cloud_file) + "\t" +
         clean(i.cloud_date) + "\t" + std::to_string(i.cloud_size) + "\t" + (i.cloud_fs ? "1" : "0") + "\t" +
         std::to_string(i.src) + "\n";
  }
  return o;
}
void parse_settings(const std::string& text, Settings& s, std::vector<Inst>& insts) {
  insts.clear();
  s.servers.clear();
  for (const auto& line : split(text, '\n')) {
    auto f = split(line, '\t');
    if (f.size() < 2) continue;
    const std::string& k = f[0];
    if (k == "base") s.base = f[1];
    else if (k == "folder") s.folder = f[1];
    else if (k == "every") s.every = EVERY_H[every_index((int)to_ll(f[1]))];
    else if (k == "freq") {   // la 1.0.148: 0 cada 6 h, 1 cada 12 h, 2 cada día, 3 cada semana
      const int old[] = {6, 12, 24, WEEK_H};
      s.every = old[imin(imax((int)to_ll(f[1]), 0), 3)];
    }
    else if (k == "hour") s.hour = imin(imax((int)to_ll(f[1]), 0), 23);
    else if (k == "wday") s.wday = imin(imax((int)to_ll(f[1]), 0), 6);
    else if (k == "days") s.days = imax((int)to_ll(f[1]), 0);
    else if (k == "fresh") s.fresh = f[1] == "1";
    else if (k == "fs") s.fs = f[1] == "1";
    else if (k == "login") s.login = f[1] == "1";
    else if (k == "next") s.next_run = to_ll(f[1]);
    else if (k == "last") s.last_run = to_ll(f[1]);
    else if (k == "server" && f.size() >= 8) {
      Server v;
      v.id = (int)to_ll(f[1]);
      v.name = f[2];
      v.host = f[3];
      v.port = imin(imax((int)to_ll(f[4]), 1), 65535);
      v.user = f[5];
      v.password = f[6] == "1";
      v.key = f[7];
      if (v.id > 0 && !v.host.empty()) s.servers.push_back(v);
    }
    else if (k == "inst" && f.size() >= 15) {
      Inst i;
      i.id = (int)to_ll(f[1]);
      i.name = f[2];
      i.version = f[3];
      i.status = f[4];
      i.on = f[5] == "1";
      i.state = (int)to_ll(f[6]);
      i.error = f[7];
      i.local_file = f[8];
      i.local_t = to_ll(f[9]);
      i.local_size = to_ll(f[10]);
      i.cloud_file = f[11];
      i.cloud_date = f[12];
      i.cloud_size = to_ll(f[13]);
      i.cloud_fs = f[14] == "1";
      if (f.size() >= 16) i.src = (int)to_ll(f[15]);
      if (i.id != 0) insts.push_back(i);
    }
  }
}
// Las instancias que llegan del panel, con lo que ya se sabía de cada una
// (marcada o no, lo bajado). Las nuevas llegan marcadas.
std::vector<Inst> merge(const std::vector<Inst>& old, const std::vector<Inst>& fresh) {
  std::vector<Inst> out;
  for (const auto& f : fresh) {
    Inst n = f;
    for (const auto& o : old)
      if (o.id == f.id || o.name == f.name) {
        n = o;
        n.id = f.id;
        n.name = f.name;
        n.version = f.version;
        n.status = f.status;
        if (f.src > 0) n.cloud_size = f.cloud_size;   // el tamaño de la base en el servidor
        break;
      }
    out.push_back(n);
  }
  return out;
}
// Lo que llega de una fuente (0: el panel; si no, un servidor) sustituye lo
// de esa fuente, con lo que ya se sabía de cada una; lo demás no se toca. El
// panel va primero y cada servidor, junto.
std::vector<Inst> merge_src(const std::vector<Inst>& old, const std::vector<Inst>& fresh, int src) {
  std::vector<Inst> mine, out;
  for (const auto& o : old)
    if (o.src == src) mine.push_back(o);
  std::vector<Inst> merged = merge(mine, fresh);
  for (auto& m : merged) m.src = src;
  bool placed = false;
  for (const auto& o : old) {
    if (o.src == src) {
      if (!placed) out.insert(out.end(), merged.begin(), merged.end());
      placed = true;
      continue;
    }
    if (!placed && src == 0) {
      out.insert(out.end(), merged.begin(), merged.end());
      placed = true;
    }
    out.push_back(o);
  }
  if (!placed) out.insert(out.end(), merged.begin(), merged.end());
  return out;
}

// ------------------------------------------------------------ el token
// En el Llavero de macOS; en Windows y Linux, en un archivo de la carpeta de
// ajustes que solo lee el usuario.
std::string sh_quote(const std::string& s) {
  std::string q = "'";
  for (char c : s) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  return q + "'";
}
const char* const TOKEN_SERVICE = "community.sh token";
std::string server_service(int id) { return "community.sh ssh " + std::to_string(id); }
std::string secret_file(const std::string& service) {
  return join(config_dir(), service == TOKEN_SERVICE ? std::string("token.key") : safe_name(service) + ".key");
}
std::string secret_get(const std::string& service) {
#ifdef __APPLE__
  if (!testing()) {
    std::string cmd = "/usr/bin/security find-generic-password -a dmarlon-cshbackup -s " + sh_quote(service) + " -w 2>/dev/null";
    FILE* p = popen(cmd.c_str(), "r");
    if (!p) return "";
    char buf[512];
    std::string out;
    size_t n;
    while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
    pclose(p);
    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
  }
#endif
  std::string v;
  read_file(secret_file(service), v);
  if (!v.empty() && v.back() == '\n') v.pop_back();
  return v;
}
void secret_set(const std::string& service, const std::string& value) {
  fl_make_path(config_dir().c_str());
#ifdef __APPLE__
  if (!testing()) {
    std::string cmd = "/usr/bin/security add-generic-password -U -a dmarlon-cshbackup -s " + sh_quote(service) + " -w " +
                      sh_quote(value) + " >/dev/null 2>&1";
    int r = std::system(cmd.c_str());
    (void)r;
    return;
  }
#endif
  write_private(secret_file(service), value);
}
void secret_del(const std::string& service) {
#ifdef __APPLE__
  if (!testing()) {
    std::string cmd = "/usr/bin/security delete-generic-password -a dmarlon-cshbackup -s " + sh_quote(service) + " >/dev/null 2>&1";
    int r = std::system(cmd.c_str());
    (void)r;
    return;
  }
#endif
  fl_unlink(secret_file(service).c_str());
}
std::string token_get() { return trim(secret_get(TOKEN_SERVICE)); }
void token_set(const std::string& value) { secret_set(TOKEN_SERVICE, value); }

// ------------------------------------------------------------ el sistema
std::string exe_path() {
#ifdef _WIN32
  wchar_t w[MAX_PATH * 2];
  DWORD n = GetModuleFileNameW(nullptr, w, MAX_PATH * 2);
  char buf[MAX_PATH * 6];
  fl_utf8fromwc(buf, sizeof buf, w, n);
  return buf;
#elif defined(__APPLE__)
  char buf[4096];
  uint32_t n = sizeof buf;
  if (_NSGetExecutablePath(buf, &n) != 0) return "";
  char real[4096];
  return realpath(buf, real) ? real : buf;
#else
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
  return n > 0 ? std::string(buf, (size_t)n) : "";
#endif
}
std::string xml_escape(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '&') o += "&amp;";
    else if (c == '<') o += "&lt;";
    else if (c == '>') o += "&gt;";
    else if (c == '"') o += "&quot;";
    else o += c;
  }
  return o;
}
// Abrir al iniciar sesión, ya en la barra (-iconic): un LaunchAgent en
// macOS y la clave Run del registro en Windows.
std::string login_plist(const std::string& exe) {
  return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
         "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
         "<plist version=\"1.0\"><dict>\n"
         "  <key>Label</key><string>xyz.dmarlonstudio.cshbackup</string>\n"
         "  <key>ProgramArguments</key><array><string>" + xml_escape(exe) + "</string><string>-iconic</string></array>\n"
         "  <key>RunAtLoad</key><true/>\n"
         "</dict></plist>\n";
}
std::string login_file() {
  if (testing()) return join(config_dir(), "login-item.plist");
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/LaunchAgents/xyz.dmarlonstudio.cshbackup.plist";
}
bool login_set(bool on) {
#ifdef _WIN32
  if (!testing()) {
    HKEY k;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, KEY_SET_VALUE, &k) != ERROR_SUCCESS)
      return false;
    LONG r;
    if (on) {
      std::wstring cmd = L"\"" + wide(exe_path()) + L"\" -iconic";
      r = RegSetValueExW(k, L"DMarlon community.sh backups", 0, REG_SZ, (const BYTE*)cmd.c_str(), (DWORD)((cmd.size() + 1) * sizeof(wchar_t)));
    } else {
      r = RegDeleteValueW(k, L"DMarlon community.sh backups");
      if (r == ERROR_FILE_NOT_FOUND) r = ERROR_SUCCESS;
    }
    RegCloseKey(k);
    return r == ERROR_SUCCESS;
  }
#endif
  std::string f = login_file();
  if (!on) {
    fl_unlink(f.c_str());
    return !exists(f);
  }
  std::string dir = f.substr(0, f.find_last_of("/\\"));
  fl_make_path(dir.c_str());
  return write_file(f, login_plist(exe_path()));
}
// ¿La abrió el inicio de sesión (con -iconic)?
bool started_iconic() {
#ifdef _WIN32
  const wchar_t* c = GetCommandLineW();
  return c && wcsstr(c, L" -iconic") != nullptr;
#elif defined(__APPLE__)
  int n = *_NSGetArgc();
  char** v = *_NSGetArgv();
  for (int i = 1; i < n; i++)
    if (std::strcmp(v[i], "-iconic") == 0) return true;
  return false;
#else
  return false;
#endif
}
// Una sola copia de la app abierta (dos a la vez bajarían lo mismo).
bool single_instance() {
  if (testing()) return true;
#ifdef _WIN32
  HANDLE m = CreateMutexW(nullptr, TRUE, L"Local\\DMarlonStudio.CommunityBackups");
  return m && GetLastError() != ERROR_ALREADY_EXISTS;
#else
  fl_make_path(config_dir().c_str());
  int fd = open(join(config_dir(), "app.lock").c_str(), O_RDWR | O_CREAT, 0600);
  return fd < 0 || flock(fd, LOCK_EX | LOCK_NB) == 0;   // el descriptor queda abierto
#endif
}
// Abre una carpeta en el Finder o en el Explorador.
void open_folder(const std::string& path) {
  fl_make_path(path.c_str());
#ifdef _WIN32
  ShellExecuteW(nullptr, L"open", wide(path).c_str(), nullptr, nullptr, SW_SHOWNORMAL);
#else
#ifdef __APPLE__
  const char* tool = "/usr/bin/open";
#else
  const char* tool = "xdg-open";
#endif
  pid_t pid;
  std::string p = path;
  char* argv[] = {(char*)tool, (char*)p.c_str(), nullptr};
  if (posix_spawnp(&pid, tool, nullptr, nullptr, argv, environ) == 0) {
    std::thread([pid] { int st; waitpid(pid, &st, 0); }).detach();
  }
#endif
}
// Abre un archivo con su programa (el historial, con el editor de textos).
void open_file(const std::string& path) {
#ifdef _WIN32
  ShellExecuteW(nullptr, L"open", wide(path).c_str(), nullptr, nullptr, SW_SHOWNORMAL);
#else
#ifdef __APPLE__
  const char* tool = "/usr/bin/open";
#else
  const char* tool = "xdg-open";
#endif
  pid_t pid;
  std::string p = path;
  char* argv[] = {(char*)tool, (char*)p.c_str(), nullptr};
  if (posix_spawnp(&pid, tool, nullptr, nullptr, argv, environ) == 0) {
    std::thread([pid] { int st; waitpid(pid, &st, 0); }).detach();
  }
#endif
}
// Un aviso del sistema en macOS (en Windows, el globo del icono: bar::notify).
void notify_mac(const std::string& title, const std::string& text) {
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

// ------------------------------------------------------------ SSH
// En el servidor, PostgreSQL se usa como el usuario postgres: si ya se entra
// como postgres, directamente; si no (root o un usuario con permiso), con
// «sudo -n -u postgres», que no pide contraseña o falla.
const char* const PG_RUN =
    "R() { if [ \"$(id -un)\" = postgres ]; then \"$@\"; else sudo -n -u postgres \"$@\"; fi; }; cd /tmp && ";
std::string remote_list() {
  return std::string(PG_RUN) +
         "R psql -X -A -t -F '|' -c \"select datname, pg_database_size(datname) from pg_database "
         "where datallowconn and not datistemplate and datname <> 'postgres' order by 1\"";
}
std::string remote_dump(const std::string& db) { return std::string(PG_RUN) + "R pg_dump -Fc " + sh_quote(db); }

// Un id estable (negativo) para una base de un servidor.
int ssh_id(int src, const std::string& db) {
  unsigned h = 2166136261u;
  for (unsigned char c : db) h = (h ^ c) * 16777619u;
  return -(src * 1000000 + (int)(h % 999983u) + 1);
}
// «tienda|8130371» por línea → las bases del servidor.
std::vector<Inst> parse_db_list(const std::string& out, const Server& s) {
  std::vector<Inst> v;
  for (const auto& line : split(out, '\n')) {
    std::string l = trim(line);
    size_t bar = l.rfind('|');
    if (l.empty() || bar == std::string::npos || bar == 0) continue;
    Inst in;
    in.src = s.id;
    in.name = l.substr(0, bar);
    in.id = ssh_id(s.id, in.name);
    in.version = s.name;
    in.status = server_label(s);
    in.cloud_size = to_ll(l.substr(bar + 1));
    v.push_back(in);
  }
  return v;
}

std::string ssh_program() {
#ifdef _WIN32
  return "ssh.exe";
#else
  return access("/usr/bin/ssh", X_OK) == 0 ? "/usr/bin/ssh" : "ssh";
#endif
}
// Los argumentos de ssh (sin el programa) para entrar en [s] y ejecutar
// [remote]. La huella de cada servidor se guarda la primera vez en un
// known_hosts propio; si cambia, ssh no entra.
std::vector<std::string> ssh_args(const Server& s, const std::string& remote) {
  std::vector<std::string> a = {"-p", std::to_string(s.port), "-o", "ConnectTimeout=15", "-o", "ServerAliveInterval=30",
                                "-o", "ServerAliveCountMax=4", "-o", "StrictHostKeyChecking=accept-new",
                                "-o", "UserKnownHostsFile=\"" + join(config_dir(), "known_hosts") + "\"", "-o", "LogLevel=ERROR"};
  if (s.password) {
    for (const char* o : {"PreferredAuthentications=password,keyboard-interactive", "PubkeyAuthentication=no", "NumberOfPasswordPrompts=1"}) {
      a.push_back("-o");
      a.push_back(o);
    }
  } else {
    a.push_back("-o");
    a.push_back("BatchMode=yes");
    if (!trim(s.key).empty()) {
      a.push_back("-i");
      a.push_back(trim(s.key));
      a.push_back("-o");
      a.push_back("IdentitiesOnly=yes");
    }
  }
  a.push_back(s.user + "@" + s.host);
  a.push_back(remote);
  return a;
}
#ifdef _WIN32
// Un argumento de la línea de órdenes de Windows, entre comillas si hace falta.
std::wstring win_arg(const std::wstring& a) {
  if (!a.empty() && a.find_first_of(L" \t\"") == std::wstring::npos) return a;
  std::wstring o = L"\"";
  size_t bs = 0;
  for (wchar_t c : a) {
    if (c == L'\\') { bs++; continue; }
    if (c == L'"') {
      o.append(bs * 2 + 1, L'\\');
      o += c;
      bs = 0;
      continue;
    }
    o.append(bs, L'\\');
    bs = 0;
    o += c;
  }
  o.append(bs * 2, L'\\');
  return o + L"\"";
}
#endif
// La app como SSH_ASKPASS en Windows: ssh la abre y lee la contraseña de su
// salida (en macOS y Linux lo hace un guion de una línea).
int askpass(const std::string& file) {
  std::string pw;
  read_file(file, pw);
  if (pw.empty() || pw.back() != '\n') pw += "\n";
#ifdef _WIN32
  DWORD n = 0;
  WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), pw.data(), (DWORD)pw.size(), &n, nullptr);
#else
  std::fwrite(pw.data(), 1, pw.size(), stdout);
#endif
  return 0;
}

struct Run {
  int code = -1;   // el código de salida de ssh (-1: no se pudo abrir)
  std::string out, err;
};
// Ejecuta ssh: la salida va a [out_file] (si se da) o a Run::out. Con
// contraseña, ssh la pide al programa de SSH_ASKPASS, que la lee de un
// archivo que solo lee el usuario y que se borra al terminar.
Run run_ssh(const Server& s, const std::string& remote, const std::string& out_file) {
  Run r;
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string tag = std::to_string(now_t()) + "-" + std::to_string(counter()++);
  std::string errf = join(dir, "ssh-" + tag + ".err"), pwf, askf;
  if (s.password) {
    pwf = join(dir, "ssh-" + tag + ".pw");
    if (!write_private(pwf, s.secret + "\n")) {
      r.err = fmt(tx::E_FOLDER, {dir});
      return r;
    }
  }
  std::vector<std::string> args = ssh_args(s, remote);
#ifdef _WIN32
  std::wstring cmd = win_arg(wide(ssh_program()));
  for (const auto& a : args) cmd += L" " + win_arg(wide(a));
  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE out = INVALID_HANDLE_VALUE, rd = nullptr;
  if (!out_file.empty()) {
    out = CreateFileW(wide(out_file).c_str(), GENERIC_WRITE, FILE_SHARE_READ, &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  } else if (CreatePipe(&rd, &out, &sa, 0)) {
    SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0);
  }
  HANDLE err = CreateFileW(wide(errf).c_str(), GENERIC_WRITE, FILE_SHARE_READ, &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  HANDLE nul = CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa, OPEN_EXISTING, 0, nullptr);
  if (s.password) {
    SetEnvironmentVariableW(L"SSH_ASKPASS", wide(exe_path()).c_str());
    SetEnvironmentVariableW(L"SSH_ASKPASS_REQUIRE", L"force");
    SetEnvironmentVariableW(L"DISPLAY", L":0");
    SetEnvironmentVariableW(L"DMS_CSHBK_ASKPASS", wide(pwf).c_str());
  }
  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput = nul;
  si.hStdOutput = out;
  si.hStdError = err;
  PROCESS_INFORMATION pi{};
  BOOL ok = out != INVALID_HANDLE_VALUE && err != INVALID_HANDLE_VALUE &&
            CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
  if (s.password) {
    for (const wchar_t* v : {L"SSH_ASKPASS", L"SSH_ASKPASS_REQUIRE", L"DISPLAY", L"DMS_CSHBK_ASKPASS"}) SetEnvironmentVariableW(v, nullptr);
  }
  if (out != INVALID_HANDLE_VALUE) CloseHandle(out);
  if (err != INVALID_HANDLE_VALUE) CloseHandle(err);
  if (nul != INVALID_HANDLE_VALUE) CloseHandle(nul);
  if (ok) {
    if (rd) {
      char buf[8192];
      DWORD n = 0;
      while (ReadFile(rd, buf, sizeof buf, &n, nullptr) && n > 0) r.out.append(buf, n);
    }
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 255;
    GetExitCodeProcess(pi.hProcess, &code);
    r.code = (int)code;
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  }
  if (rd) CloseHandle(rd);
#else
  std::string cmd;
  if (s.password) {
    askf = join(dir, "ssh-" + tag + ".sh");
    write_private(askf, "#!/bin/sh\ncat " + sh_quote(pwf) + "\n");
    chmod(askf.c_str(), 0700);
    cmd = "SSH_ASKPASS=" + sh_quote(askf) + " SSH_ASKPASS_REQUIRE=force DISPLAY=:0 ";
  }
  cmd += sh_quote(ssh_program());
  for (const auto& a : args) cmd += " " + sh_quote(a);
  cmd += " </dev/null 2>" + sh_quote(errf);
  if (!out_file.empty()) cmd += " >" + sh_quote(out_file);
  FILE* p = popen(cmd.c_str(), "r");
  if (p) {
    char buf[8192];
    size_t n;
    while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) r.out.append(buf, n);
    int st = pclose(p);
    r.code = WIFEXITED(st) ? (WEXITSTATUS(st) == 127 ? -1 : WEXITSTATUS(st)) : -1;
  }
#endif
  read_file(errf, r.err, 65536);
  fl_unlink(errf.c_str());
  if (!pwf.empty()) fl_unlink(pwf.c_str());
  if (!askf.empty()) fl_unlink(askf.c_str());
  return r;
}
// Lo que salió mal, en palabras: entrar, sudo, PostgreSQL…
std::string ssh_error(const Run& r, const Server& s) {
  std::string e = lower(r.err);
  auto has = [&](const char* w) { return e.find(w) != std::string::npos; };
  if (r.code == -1 && trim(r.err).empty()) return tx::E_NO_SSH;
  if (has("remote host identification has changed") || has("host key verification failed")) return tx::E_SSH_HOSTKEY;
  if (has("permission denied (") || has("too many authentication failures")) return s.password ? tx::E_SSH_PASSWORD : tx::E_SSH_KEY;
  std::string last;
  for (const auto& l : split(r.err, '\n'))
    if (!trim(l).empty()) last = trim(l);
  if (has("could not resolve hostname") || has("connection refused") || has("timed out") || has("no route to host") ||
      has("network is unreachable") || has("connection closed by") || has("connection reset"))
    return fmt(tx::E_SSH_CONNECT, {starts(last, "ssh: ") ? last.substr(5) : last});
  if (has("sudo: a password is required") || has("sudo: a terminal is required") || has("not in the sudoers") ||
      has("is not allowed to execute") || has("may not run sudo") || has("sudo: command not found") || has("sudo: not found"))
    return fmt(tx::E_SSH_SUDO, {s.user});
  if ((has("psql") || has("pg_dump")) && (has("command not found") || has("not found")))
    return tx::E_SSH_NO_PG;
  if (!last.empty()) {
    for (const char* pre : {"pg_dump: error: ", "psql: error: ", "pg_dump: ", "psql: "})
      if (starts(last, pre)) last = last.substr(std::strlen(pre));
    return last.size() > 200 ? last.substr(0, 200) + "…" : last;
  }
  return fmt(tx::E_SSH_EXIT, {std::to_string(r.code)});
}
// Las bases de datos de un servidor (al conectar y al probarlo).
Ev fetch_dbs(const Server& s, int kind) {
  Ev e;
  e.kind = kind;
  e.src = s.id;
  if (s.password && s.secret.empty()) {
    e.error = s.name + ": " + tx::E_SSH_NO_PASSWORD;
    return e;
  }
  Run r = run_ssh(s, remote_list(), "");
  if (r.code != 0) e.error = s.name + ": " + ssh_error(r, s);
  else e.list = parse_db_list(r.out, s);
  return e;
}
// Una base de un servidor: pg_dump por SSH directamente a un archivo.
void backup_ssh(const Job& job, const JobItem& it, const Post& post, const std::atomic<bool>& cancel) {
  auto state = [&](int st, const std::string& err) {
    Ev e;
    e.kind = EV_STATE;
    e.id = it.id;
    e.state = st;
    e.error = err;
    post(e);
  };
  const Server* s = nullptr;
  for (const auto& v : job.servers)
    if (v.id == it.src) s = &v;
  if (!s) { state(B_ERROR, tx::E_SSH_GONE); return; }
  if (s->password && s->secret.empty()) { state(B_ERROR, tx::E_SSH_NO_PASSWORD); return; }
  std::string dir = join(join(job.folder, safe_name(s->name)), safe_name(it.name));
  fl_make_path(dir.c_str());
  if (!fl_filename_isdir(dir.c_str())) { state(B_ERROR, fmt(tx::E_FOLDER, {dir})); return; }
  struct tm v = local(now_t());
  char stamp[32];
  std::strftime(stamp, sizeof stamp, "%Y%m%d_%H%M%S", &v);
  std::string dest = join(dir, safe_name(it.name) + "_" + stamp + ".dump");
  std::string part = dest + ".part";
  Ev d;
  d.kind = EV_STATE;
  d.id = it.id;
  d.state = B_DOWNLOADING;
  d.part = part;
  post(d);
  Run r = run_ssh(*s, remote_dump(it.name), part);
  if (cancel) { fl_unlink(part.c_str()); return; }
  std::string head;
  read_file(part, head, 5);
  long long got = file_size(part);
  if (r.code != 0 || got < 5 || head.compare(0, 5, "PGDMP") != 0) {
    fl_unlink(part.c_str());
    state(B_ERROR, r.code == 0 ? std::string(tx::E_SSH_BAD_DUMP) : ssh_error(r, *s));
    return;
  }
  fl_unlink(dest.c_str());
  if (fl_rename(part.c_str(), dest.c_str()) != 0) {
    fl_unlink(part.c_str());
    state(B_ERROR, fmt(tx::E_RENAME, {dest}));
    return;
  }
  Ev done;
  done.kind = EV_LOCAL;
  done.id = it.id;
  done.state = B_OK;
  done.file = dest;
  done.size = got;
  post(done);
}

// ------------------------------------------------------------ el menú de la barra
// El menú del icono, como datos: lo construyen macOS y Windows, y la prueba
// lo mira.
struct MenuEntry {
  std::string title;
  int tag = 0;   // la acción (0: solo texto)
  bool enabled = true, sep = false;
  int dot = -1;  // el estado (un emoji en macOS)
  std::vector<MenuEntry> sub;
};
// Las acciones caben en un WORD de Windows: acción * 1000 + instancia.
enum Act { A_GET = 1, A_FOLDER_ONE = 2, A_RUN = 50, A_FOLDER = 51, A_WINDOW = 52, A_QUIT = 53, A_TO_BAR = 54 };
inline int tag(int act, int idx) { return act * 1000 + idx; }

MenuEntry text_entry(const std::string& t) {
  MenuEntry e;
  e.title = t;
  e.enabled = false;
  return e;
}
MenuEntry sep_entry() {
  MenuEntry e;
  e.sep = true;
  return e;
}
MenuEntry act_entry(const std::string& t, int tg) {
  MenuEntry e;
  e.title = t;
  e.tag = tg;
  return e;
}
const char* state_emoji(int st) {
  switch (st) {
    case B_OK: case B_SKIPPED: return "✅";
    case B_ERROR: return "⚠️";
    case B_QUEUED: case B_CREATING: case B_LISTING: case B_DOWNLOADING: return "⏳";
    default: return "⚪️";
  }
}
// Lo que está haciendo una instancia, en pocas palabras.
std::string short_state(const Inst& i, long long now) {
  switch (i.state) {
    case B_QUEUED: return tx::ST_QUEUED;
    case B_CREATING: return tx::ST_CREATING_SHORT;
    case B_LISTING: return tx::ST_LISTING_SHORT;
    case B_DOWNLOADING:
      return i.total > 0 ? std::to_string((int)(100.0 * (double)i.got / (double)i.total)) + " %" : human(i.got);
    case B_ERROR: return tx::ST_ERROR_SHORT;
    default: return i.local_t ? when(i.local_t, now) : tx::ST_NEVER_SHORT;
  }
}
int count_on(const std::vector<Inst>& v) {
  int n = 0;
  for (const auto& i : v) n += i.on ? 1 : 0;
  return n;
}
std::vector<MenuEntry> bar_menu(const std::vector<Inst>& insts, bool running, int done, int total, long long next_run,
                                long long last_run, long long now) {
  std::vector<MenuEntry> m;
  m.push_back(text_entry(fmt(tx::BAR_NEXT, {next_run > 0 ? when(next_run, now) : std::string(tx::NEVER)})));
  m.push_back(text_entry(fmt(tx::BAR_LAST, {when(last_run, now)})));
  m.push_back(sep_entry());
  int shown = 0;
  for (int i = 0; i < (int)insts.size() && shown < 25; i++) {
    const Inst& x = insts[(size_t)i];
    if (!x.on) continue;
    shown++;
    MenuEntry e;
    e.title = (x.src ? x.name + " (" + x.version + ")" : x.name) + "  ·  " + short_state(x, now);
    e.dot = x.state;
    e.sub.push_back(act_entry(tx::BAR_GET, tag(A_GET, i)));
    e.sub.push_back(act_entry(tx::BAR_OPEN_FOLDER, tag(A_FOLDER_ONE, i)));
    if (!x.error.empty() && x.state == B_ERROR) {
      e.sub.push_back(sep_entry());
      e.sub.push_back(text_entry(x.error.size() > 90 ? x.error.substr(0, 90) + "…" : x.error));
    }
    m.push_back(e);
  }
  if (shown) m.push_back(sep_entry());
  if (running) m.push_back(text_entry(fmt(tx::BAR_RUNNING, {std::to_string(done), std::to_string(total)})));
  else m.push_back(act_entry(tx::BAR_RUN, tag(A_RUN, 0)));
  m.push_back(act_entry(tx::BAR_FOLDER, tag(A_FOLDER, 0)));
  m.push_back(act_entry(tx::BAR_WINDOW, tag(A_WINDOW, 0)));
  m.push_back(sep_entry());
  m.push_back(act_entry(tx::BAR_QUIT, tag(A_QUIT, 0)));
  return m;
}
std::string menu_key(const std::vector<MenuEntry>& m) {
  std::string k;
  for (const auto& e : m) {
    k += e.title + "|" + std::to_string(e.tag) + "|" + std::to_string(e.dot) + "{" + menu_key(e.sub) + "}";
  }
  return k;
}

// ------------------------------------------------------------ la lista
inline Fl_Color rgb(unsigned c) { return fl_rgb_color((uchar)(c >> 16), (uchar)(c >> 8), (uchar)c); }
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(line);
  fl_rounded_rect(x, y, w, h, r);
}
// El texto recortado con «…» para que quepa en [w] píxeles.
std::string fit(const std::string& s, int w) {
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty() && (int)fl_width((t + "…").c_str()) > w) {
    t.pop_back();
    while (!t.empty() && ((unsigned char)t.back() & 0xC0) == 0x80) t.pop_back();   // sin partir una letra
  }
  return t + "…";
}
std::string base_name(const std::string& p) {
  size_t k = p.find_last_of("/\\");
  return k == std::string::npos ? p : p.substr(k + 1);
}

class ListView : public Fl_Widget {
public:
  struct Hit {
    int x, y, w, h, act, idx;
  };
  std::vector<Inst>* insts = nullptr;
  bool connected = false;
  int scroll = 0, content_h = 0;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;
  ListView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int hit_at(int X, int Y) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (X >= h.x && X < h.x + h.w && Y >= h.y && Y < h.y + h.h) return i;
    }
    return -1;
  }
  int handle(int e) override {
    if (e == FL_PUSH) {
      int i = hit_at(Fl::event_x(), Fl::event_y());
      if (i >= 0 && on_act) on_act(hits[(size_t)i].act, hits[(size_t)i].idx);
      return 1;
    }
    if (e == FL_MOUSEWHEEL) {
      scroll = imax(0, imin(scroll + Fl::event_dy() * 36, imax(0, content_h - h())));
      redraw();
      return 1;
    }
    if (e == FL_ENTER || e == FL_LEAVE || e == FL_MOVE) return 1;
    return Fl_Widget::handle(e);
  }
  void button(int bx, int by, int bw, int bh, const char* label, int act, int idx, bool primary) {
    round_box(bx, by, bw, bh, 8, primary ? rgb(0x2563eb) : rgb(0xffffff), primary ? rgb(0x2563eb) : rgb(0xcbd5e1));
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(primary ? FL_WHITE : rgb(0x1f2937));
    fl_draw(label, bx, by, bw, bh, FL_ALIGN_CENTER);
    hits.push_back({bx, by, bw, bh, act, idx});
  }
  void empty_card(const char* title, const char* help) {
    int cw = imin(w() - 80, 720), cx = x() + (w() - cw) / 2, cy = y() + 60;
    round_box(cx, cy, cw, 170, 14, rgb(0xffffff), rgb(0xe2e8f0));
    fl_font(FL_HELVETICA_BOLD, 20);
    fl_color(rgb(0x111827));
    fl_draw(title, cx + 30, cy + 26, cw - 60, 30, FL_ALIGN_LEFT);
    fl_font(FL_HELVETICA, 15);
    fl_color(rgb(0x4b5563));
    fl_draw(help, cx + 30, cy + 66, cw - 60, 90, (Fl_Align)(FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP));
  }
  void draw() override {
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0xf4f6f9));
    fl_rectf(x(), y(), w(), h());
    hits.clear();
    if (!insts || insts->empty()) {
      if (connected) empty_card(tx::EMPTY_NO_INST_TITLE, tx::EMPTY_NO_INST);
      else empty_card(tx::EMPTY_TITLE, tx::EMPTY_HELP);
      content_h = 0;
      fl_pop_clip();
      return;
    }
    long long now = now_t();
    int left = x() + 14, right = x() + w() - 14;
    int col_cloud = left + 290, col_local = left + imax(560, (w() - 28) / 2 + 60);
    int btn_w = 186;
    int yy = y() + 10 - scroll;
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_color(rgb(0x64748b));
    fl_draw(tx::COL_INSTANCE, left + 52, yy + 14);
    fl_draw(tx::COL_CLOUD, col_cloud, yy + 14);
    fl_draw(tx::COL_LOCAL, col_local, yy + 14);
    yy += 24;
    for (int i = 0; i < (int)insts->size(); i++) {
      const Inst& in = (*insts)[(size_t)i];
      const int ch = 78;
      if (yy + ch >= y() && yy <= y() + h()) {
        round_box(left, yy, right - left, ch, 12, in.on ? rgb(0xffffff) : rgb(0xf8fafc), rgb(0xe2e8f0));
        // la casilla
        int bx = left + 16, by = yy + ch / 2 - 11;
        round_box(bx, by, 22, 22, 6, in.on ? rgb(0x2563eb) : rgb(0xffffff), in.on ? rgb(0x2563eb) : rgb(0x94a3b8));
        if (in.on) {
          fl_color(FL_WHITE);
          fl_line_style(FL_SOLID, 3);
          fl_line(bx + 5, by + 11, bx + 9, by + 16, bx + 17, by + 6);
          fl_line_style(0);
        }
        hits.push_back({bx - 8, by - 8, 38, 38, 0, i});
        // el nombre
        fl_font(FL_HELVETICA_BOLD, 15);
        fl_color(in.on ? rgb(0x0f172a) : rgb(0x64748b));
        fl_draw(fit(in.name, col_cloud - left - 70).c_str(), left + 52, yy + 32);
        fl_font(FL_HELVETICA, 12);
        fl_color(rgb(0x64748b));
        std::string sub = in.src ? fmt(tx::SSH_SUB, {in.version, in.status})
                                 : in.version.empty() ? in.status : fmt(tx::STATE_SUB, {in.version, in.status});
        fl_draw(fit(sub, col_cloud - left - 70).c_str(), left + 52, yy + 54);
        // en el panel
        int cw = col_local - col_cloud - 20;
        if (in.src) {   // una base de un servidor: se vuelca al respaldar
          fl_font(FL_HELVETICA, 13);
          fl_color(rgb(0x1f2937));
          fl_draw(fit(tx::SSH_CLOUD, cw).c_str(), col_cloud, yy + 32);
          fl_font(FL_HELVETICA, 12);
          fl_color(rgb(0x64748b));
          fl_draw(fit(fmt(tx::SSH_CLOUD_SIZE, {human(in.cloud_size)}), cw).c_str(), col_cloud, yy + 54);
        } else if (in.cloud_file.empty()) {
          fl_font(FL_HELVETICA, 13);
          fl_color(rgb(0x94a3b8));
          fl_draw("—", col_cloud, yy + 32);
        } else {
          fl_font(FL_HELVETICA, 13);
          fl_color(rgb(0x1f2937));
          fl_draw(fit(in.cloud_file, cw).c_str(), col_cloud, yy + 32);
          fl_font(FL_HELVETICA, 12);
          fl_color(rgb(0x64748b));
          std::string line = iso_date(in.cloud_date) + " · " + human(in.cloud_size);
          if (in.cloud_fs) line += std::string(" · ") + tx::WITH_FILES;
          fl_draw(fit(line, cw).c_str(), col_cloud, yy + 54);
        }
        // en este equipo
        int lw = right - btn_w - 26 - col_local;
        if (in.state == B_DOWNLOADING) {
          double pct = in.total > 0 ? (double)in.got / (double)in.total : 0;
          if (pct > 1) pct = 1;
          round_box(col_local, yy + 22, lw, 10, 5, rgb(0xe2e8f0), rgb(0xe2e8f0));
          if (pct > 0) {
            fl_color(rgb(0x2563eb));
            fl_rounded_rectf(col_local, yy + 22, imax(10, (int)(lw * pct)), 10, 5);
          }
          fl_font(FL_HELVETICA, 12);
          fl_color(rgb(0x1e40af));
          std::string t = in.total > 0 ? fmt(tx::ST_DOWNLOADING, {std::to_string((int)(pct * 100)), human(in.got), human(in.total)})
                                       : fmt(tx::ST_DOWNLOADING_NOSIZE, {human(in.got)});
          fl_draw(fit(t, lw).c_str(), col_local, yy + 54);
        } else if (in.state == B_QUEUED || in.state == B_CREATING || in.state == B_LISTING) {
          fl_font(FL_HELVETICA, 13);
          fl_color(rgb(0x1e40af));
          const char* t = in.state == B_QUEUED ? tx::ST_QUEUED : in.state == B_CREATING ? tx::ST_CREATING : tx::ST_LISTING;
          fl_draw(fit(t, lw).c_str(), col_local, yy + 32);
          if (in.local_t) {
            fl_font(FL_HELVETICA, 12);
            fl_color(rgb(0x64748b));
            fl_draw(fit(fmt(tx::ST_OK, {cb::when(in.local_t, now), human(in.local_size)}), lw).c_str(), col_local, yy + 54);
          }
        } else if (in.state == B_ERROR) {
          fl_font(FL_HELVETICA_BOLD, 13);
          fl_color(rgb(0xb91c1c));
          fl_draw(tx::ST_ERROR_SHORT, col_local, yy + 30);
          fl_font(FL_HELVETICA, 12);
          fl_draw(in.error.c_str(), col_local, yy + 36, lw, 36, (Fl_Align)(FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP | FL_ALIGN_CLIP));
        } else if (in.local_t) {
          fl_font(FL_HELVETICA_BOLD, 13);
          fl_color(rgb(0x15803d));
          std::string t = "✓ " + fmt(in.state == B_SKIPPED ? tx::ST_SKIPPED : tx::ST_OK, {cb::when(in.local_t, now), human(in.local_size)});
          fl_draw(fit(t, lw).c_str(), col_local, yy + 32);
          fl_font(FL_HELVETICA, 12);
          fl_color(rgb(0x64748b));
          fl_draw(fit(base_name(in.local_file), lw).c_str(), col_local, yy + 54);
        } else {
          fl_font(FL_HELVETICA, 13);
          fl_color(rgb(0x94a3b8));
          fl_draw(fit(tx::ST_NEVER, lw).c_str(), col_local, yy + 32);
        }
        // botones
        button(right - btn_w - 12, yy + 22, 84, 34, tx::BTN_GET, 1, i, false);
        button(right - 98, yy + 22, 86, 34, tx::BTN_FOLDER, 2, i, false);
      }
      yy += ch + 10;
    }
    content_h = yy + scroll - y();
    if (scroll > imax(0, content_h - h())) scroll = imax(0, content_h - h());
    fl_pop_clip();
  }
};

// ------------------------------------------------------------ pruebas internas
std::vector<Inst> demo_insts(long long now) {
  std::vector<Inst> v;
  auto add = [&](int id, const char* name, const char* ver, int st, long long ago, long long size, const char* cloud, bool on) {
    Inst i;
    i.id = id;
    i.name = name;
    i.version = ver;
    i.status = "running";
    i.on = on;
    i.state = st;
    i.cloud_id = id * 10;
    i.cloud_file = cloud;
    i.cloud_date = "2026-11-23T03:0" + std::to_string(id % 10) + ":12+01:00";
    i.cloud_size = size;
    if (st == B_OK || st == B_SKIPPED) {
      i.local_t = now - ago;
      i.local_size = size;
      i.local_file = std::string("/Users/demo/Documents/") + tx::DEFAULT_FOLDER + "/" + name + "/" + cloud;
    }
    v.push_back(i);
  };
  add(12, "tienda-online", "19.0", B_OK, 3 * 3600, 812LL * 1024 * 1024, "tienda-online_20261123_030012.zip", true);
  add(14, "erp-empresa", "18.0", B_OK, 3 * 3600, 2LL * 1024 * 1024 * 1024 + 300LL * 1024 * 1024, "erp-empresa_20261123_030144.zip", true);
  add(17, "crm-ventas", "17.0", B_SKIPPED, 3 * 3600, 154LL * 1024 * 1024, "crm-ventas_20261123_030201.zip", true);
  add(21, "pruebas-v20", "20.0", B_IDLE, 0, 96LL * 1024 * 1024, "pruebas-v20_20261120_030005.zip", false);
  add(23, "academia", "18.0", B_OK, 27 * 3600, 431LL * 1024 * 1024, "academia_20261122_030320.zip", true);
  v[3].cloud_fs = false;
  v[1].cloud_fs = true;
  Server sv;
  sv.id = 1;
  sv.name = "ubuntu-oficina";
  sv.host = "192.0.2.10";
  sv.user = "root";
  for (const auto& d : parse_db_list("erp_produccion|1460000000\nnominas|212000000\n", sv)) {
    Inst i = d;
    i.state = B_OK;
    i.local_t = now - 3 * 3600;
    i.local_size = d.cloud_size / 4;
    i.local_file = std::string("/Users/demo/Documents/") + tx::DEFAULT_FOLDER + "/ubuntu-oficina/" + d.name + "/" + d.name + "_20261123_030512.dump";
    v.push_back(i);
  }
  return v;
}

int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) {
      std::printf("FAIL %s\n", what);
      f++;
    }
  };
  // JSON
  J j;
  chk(parse_json("{\"a\": [1, 2.5, \"x\\u00e9\\n\", true, null, {\"b\": -3}]}", j), "json");
  chk(j["a"].items.size() == 6 && j["a"].items[1].n == 2.5 && j["a"].items[2].s == "x\xc3\xa9\n" && j["a"].items[5]["b"].num() == -3, "json valores");
  chk(!parse_json("{\"a\": }", j) && !parse_json("[1,", j), "json mal");
  chk(parse_json("\"\\ud83d\\ude00\"", j) && j.s == "\xf0\x9f\x98\x80", "json emoji");
  // instancias y respaldos del panel
  std::string inst = "[{\"id\": 194, \"name\": \"bim17\", \"odoo_version\": \"17.0\", \"status\": \"running\", \"admin_password\": \"x\"},"
                     " {\"id\": 190, \"name\": \"canexel20\", \"odoo_version\": \"20.0\", \"status\": \"stopped\"}, {\"id\": 0}]";
  chk(parse_json(inst, j), "json instancias");
  auto in = parse_instances(j);
  chk(in.size() == 2 && in[0].id == 194 && in[0].name == "bim17" && in[1].version == "20.0" && in[1].status == "stopped", "instancias");
  chk(parse_json("{\"results\": " + inst + "}", j) && parse_instances(j).size() == 2, "instancias paginadas");
  std::string bk = "[{\"id\": 7, \"instance\": \"bim17\", \"filename\": \"bim17_a.zip\", \"file_size\": 1234, \"include_filestore\": false,"
                   " \"created_at\": \"2026-11-22T03:00:00+01:00\"}, {\"id\": 9, \"instance\": \"bim17\", \"filename\": \"bim17_b.zip\","
                   " \"file_size\": 99999999999, \"include_filestore\": true, \"created_at\": \"2026-11-23T03:00:00+01:00\"}]";
  chk(parse_json(bk, j), "json respaldos");
  auto bl = parse_backups(j);
  chk(bl.size() == 2 && newest(bl) == 1 && bl[1].size == 99999999999LL && bl[1].fs && !bl[0].fs, "respaldos y el más reciente");
  chk(newest({}) == -1, "sin respaldos");
  chk(parse_json("{\"status\": \"failed\", \"result\": {}, \"log\": \"start\\npg_dump: error: disk full\\n\\n\"}", j) &&
          task_error(j) == "pg_dump: error: disk full", "error de la tarea");
  // direcciones, nombres y curl
  chk(normalize_base("communitysh.xyz") == "https://communitysh.xyz", "dirección sin https");
  chk(normalize_base(" https://communitysh.xyz/api/ ") == "https://communitysh.xyz", "dirección con /api");
  chk(normalize_base("http://localhost:8000") == "http://localhost:8000", "localhost");
  chk(normalize_base("no vale") == "" && normalize_base("") == "" && normalize_base("intranet") == "", "direcciones malas");
  chk(url_encode("mi instancia/1") == "mi%20instancia%2F1", "url_encode");
  chk(safe_name("a/b:c*?.zip") == "a_b_c__.zip" && safe_name("..") == "_" && safe_name("bim17") == "bim17", "nombres seguros");
  Req q;
  q.base = "https://p.example";
  q.token = "csh_ab\"c";
  q.method = "POST";
  q.path = "/api/instances/3/backup/";
  q.data = "include_filestore=false";
  std::string cfg = curl_config(q);
  chk(cfg.find("url = \"https://p.example/api/instances/3/backup/\"") != std::string::npos, "curl url");
  chk(cfg.find("header = \"Authorization: Bearer csh_ab\\\"c\"") != std::string::npos, "curl token escapado");
  chk(cfg.find("request = \"POST\"") != std::string::npos && cfg.find("data = \"include_filestore=false\"") != std::string::npos, "curl POST");
  chk(cfg.find("max-time = 60") != std::string::npos && cfg.find("output") == std::string::npos, "curl API");
  q.method = "GET";
  q.data = "";
  q.out_file = "C:\\Users\\x\\a.zip.part";
  q.max_time = 0;
  cfg = curl_config(q);
  chk(cfg.find("output = \"C:\\\\Users\\\\x\\\\a.zip.part\"") != std::string::npos && cfg.find("max-time") == std::string::npos &&
          cfg.find("speed-time") != std::string::npos && cfg.find("data") == std::string::npos, "curl descarga");
  Resp r = parse_resp("[{\"id\": 1}]\n200", 0);
  chk(r.code == 200 && trim(r.body) == "[{\"id\": 1}]", "respuesta");
  r = parse_resp("curl: (6) Could not resolve host: nada.example\n000", 6);
  chk(r.code == 0 && r.error == "Could not resolve host: nada.example", "sin conexión");
  chk(http_error(parse_resp("{\"detail\": \"x\"}\n401", 0), false) == tx::E_TOKEN, "401");
  chk(http_error(parse_resp("{\"detail\": \"Read-only token\"}\n403", 0), true) == tx::E_READONLY, "403 solo lectura");
  chk(http_error(parse_resp("{\"detail\": \"Boom\"}\n500", 0), false) == fmt(tx::E_HTTP, {"500"}) + ": Boom", "500 con detalle");
  chk(parse_resp("", -1).code == -1, "sin curl");
  // tamaños y fechas
  chk(human(512) == "512 B" && human(1536) == std::string("1") + tx::DEC + "5 KB" && human(5LL * 1024 * 1024 * 1024) == std::string("5") + tx::DEC + "0 GB",
      "tamaños");
  chk(iso_date("2026-11-23T03:10:05.123+01:00") == "23/11/2026 03:10" && iso_date("x") == "x", "fecha ISO");
  // la secuencia
  struct tm base_tm {};
  base_tm.tm_year = 2026 - 1900;
  base_tm.tm_mon = 10;
  base_tm.tm_mday = 23;   // lunes 23/11/2026
  base_tm.tm_hour = 10;
  base_tm.tm_min = 30;
  base_tm.tm_isdst = -1;
  long long t0 = (long long)std::mktime(&base_tm);
  auto at = [](long long t) { struct tm v = local(t); return std::to_string(v.tm_mday) + " " + hhmm(v); };
  chk(at(next_slot(t0, 24, 3, 0)) == "24 03:00", "cada día a las 3");
  chk(at(next_slot(t0, 24, 23, 0)) == "23 23:00", "cada día a las 23");
  chk(at(next_slot(t0, 12, 3, 0)) == "23 15:00", "cada 12 h desde las 3");
  chk(at(next_slot(t0, 6, 3, 0)) == "23 15:00", "cada 6 h desde las 3");
  chk(at(next_slot(t0, 6, 11, 0)) == "23 11:00", "cada 6 h desde las 11");
  chk(at(next_slot(t0, 1, 3, 0)) == "23 11:00", "cada hora");
  chk(at(next_slot(next_slot(t0, 1, 3, 0), 1, 3, 0)) == "23 12:00", "cada hora, la siguiente");
  chk(at(next_slot(t0, 2, 3, 0)) == "23 11:00", "cada 2 h desde las 3");
  chk(at(next_slot(t0, 2, 4, 0)) == "23 12:00", "cada 2 h desde las 4");
  chk(at(next_slot(t0, 3, 3, 0)) == "23 12:00", "cada 3 h desde las 3");
  chk(at(next_slot(t0, 4, 3, 0)) == "23 11:00", "cada 4 h desde las 3");
  chk(at(next_slot(t0, WEEK_H, 3, 0)) == "30 03:00", "cada semana el lunes");
  chk(at(next_slot(t0, WEEK_H, 3, 2)) == "25 03:00", "cada semana el miércoles");
  chk(at(next_slot(t0, WEEK_H, 12, 0)) == "23 12:00", "cada semana, hoy más tarde");
  long long s1 = next_slot(t0, 24, 3, 0);
  chk(next_slot(s1, 24, 3, 0) - s1 >= 23 * 3600 && next_slot(s1, 24, 3, 0) - s1 <= 25 * 3600, "la siguiente, otro día");
  chk(every_index(1) == 0 && every_index(WEEK_H) == EVERY_N - 1 && every_index(5) == 6, "las frecuencias");
  chk(when(t0 + 3600, t0) == fmt(tx::TODAY, {"11:30"}) && when(s1, t0) == fmt(tx::TOMORROW, {"03:00"}) && when(0, t0) == tx::NEVER, "cuándo");
  // los bajados: solo se conservan los N últimos de cada instancia
  std::vector<Got> g;
  const long long D = 86400, now0 = 100 * D;
  add_got(g, {"a", "/r/a/1.zip", now0 - 5 * D, 1});
  add_got(g, {"a", "/r/a/2.zip", now0 - 4 * D, 1});
  add_got(g, {"a", "/r/a/3.zip", now0 - 2 * D, 1});
  add_got(g, {"b", "/r/b/1.zip", now0 - 9 * D, 1});   // el único de b: se queda
  add_got(g, {"a", "/r/a/3.zip", now0 - 1 * D, 1});   // otra vez el mismo
  chk(g.size() == 4, "el mismo archivo no cuenta dos veces");
  chk(parse_got(serialize_got(g)).size() == 4 && parse_got(serialize_got(g))[0].path == g[0].path, "guardar los bajados");
  std::vector<Got> g2 = g;
  chk(prune_got(g2, now0, 0).empty() && g2.size() == 4, "nunca se borran");
  g2 = g;
  auto drop = prune_got(g2, now0, 3);
  chk(drop.size() == 2 && drop[0] == "/r/a/1.zip" && drop[1] == "/r/a/2.zip" && g2.size() == 2, "se borran los de más de 3 días");
  g2 = g;
  drop = prune_got(g2, now0 + 30 * D, 1);
  chk(drop.size() == 2 && g2.size() == 2 && g2[0].path == "/r/b/1.zip" && g2[1].path == "/r/a/3.zip", "siempre queda el último de cada instancia");
  // los ajustes
  Settings st;
  st.folder = "/tmp/x y";
  st.every = WEEK_H;
  st.hour = 22;
  st.wday = 4;
  st.days = 14;
  st.fresh = true;
  st.next_run = 1234;
  auto insts = demo_insts(1000000);
  insts[3].on = false;
  insts[4].state = B_ERROR;
  insts[4].error = "malo\tcon tab";
  Settings s2;
  std::vector<Inst> i2;
  parse_settings(serialize(st, insts), s2, i2);
  chk(s2.folder == st.folder && s2.every == WEEK_H && s2.hour == 22 && s2.wday == 4 && s2.days == 14 && s2.fresh && !s2.fs &&
          s2.next_run == 1234, "ajustes");
  chk(i2.size() == insts.size() && !i2[3].on && i2[1].cloud_fs && i2[4].state == B_ERROR && i2[4].error == "malo con tab" &&
          i2[0].local_size == insts[0].local_size, "instancias guardadas");
  // al volver a conectar: se conserva lo marcado y llega la nueva, marcada
  std::vector<Inst> fresh = {insts[3], insts[0]};
  fresh[0].on = true;
  fresh[0].version = "20.1";
  Inst nw;
  nw.id = 99;
  nw.name = "nueva";
  fresh.push_back(nw);
  auto mg = merge(insts, fresh);
  chk(mg.size() == 3 && !mg[0].on && mg[0].version == "20.1" && mg[1].local_t == insts[0].local_t && mg[2].on, "juntar instancias");
  // el menú del icono
  auto m = bar_menu(insts, false, 0, 0, s1, t0, t0);
  int sites = 0, runs = 0;
  for (const auto& e : m) {
    if (e.dot >= 0) sites++;
    if (e.tag == tag(A_RUN, 0)) runs++;
  }
  chk(sites == 6 && runs == 1, "menú del icono");
  chk(tag(A_TO_BAR, 999) < 65536, "acciones de Windows");
  auto m2 = bar_menu(insts, true, 2, 4, s1, t0, t0);
  chk(menu_key(m) != menu_key(m2), "el menú cambia al respaldar");
  // SSH: los argumentos, las órdenes en el servidor y los errores
  Server sk;
  sk.id = 3;
  sk.name = "oficina";
  sk.host = "10.0.0.5";
  sk.port = 2222;
  sk.user = "keyuser";
  sk.key = "/Users/x/.ssh/id ed25519";
  auto ak = ssh_args(sk, "echo hola");
  auto has_arg = [&](const std::vector<std::string>& v, const std::string& a) {
    for (const auto& x : v)
      if (x == a) return true;
    return false;
  };
  chk(ak.size() > 6 && ak[0] == "-p" && ak[1] == "2222" && ak.back() == "echo hola" && ak[ak.size() - 2] == "keyuser@10.0.0.5", "ssh: puerto, usuario y orden");
  chk(has_arg(ak, "BatchMode=yes") && has_arg(ak, "/Users/x/.ssh/id ed25519") && has_arg(ak, "IdentitiesOnly=yes") &&
          has_arg(ak, "StrictHostKeyChecking=accept-new"), "ssh con clave");
  bool kh = false;
  for (const auto& x : ak) kh = kh || (starts(x, "UserKnownHostsFile=\"") && ends(x, "known_hosts\""));
  chk(kh, "known_hosts propio, entre comillas");
  Server sp = sk;
  sp.password = true;
  sp.key.clear();
  auto apw = ssh_args(sp, "x");
  chk(has_arg(apw, "PubkeyAuthentication=no") && !has_arg(apw, "BatchMode=yes") && !has_arg(apw, "-i"), "ssh con contraseña");
  chk(remote_dump("mi base's") == std::string(PG_RUN) + "R pg_dump -Fc 'mi base'\\''s'", "pg_dump con el nombre entre comillas");
  chk(remote_list().find("pg_database_size") != std::string::npos && remote_list().find("sudo -n -u postgres") != std::string::npos, "listar las bases");
  auto dbs = parse_db_list("tienda|8130371\nerp|7500000\n\nraro|x|12\n", sk);
  chk(dbs.size() == 3 && dbs[0].name == "tienda" && dbs[0].cloud_size == 8130371 && dbs[2].name == "raro|x" && dbs[0].src == 3 &&
          dbs[0].version == "oficina" && dbs[0].status == "keyuser@10.0.0.5:2222", "las bases del servidor");
  chk(dbs[0].id < 0 && dbs[0].id == ssh_id(3, "tienda") && ssh_id(3, "tienda") != ssh_id(4, "tienda") && ssh_id(3, "erp") != ssh_id(3, "tienda"), "ids de las bases");
  Run rr;
  rr.code = 255;
  rr.err = "keyuser@10.0.0.5: Permission denied (publickey,password).\n";
  chk(ssh_error(rr, sk) == tx::E_SSH_KEY && ssh_error(rr, sp) == tx::E_SSH_PASSWORD, "error: no entra");
  rr.err = "ssh: Could not resolve hostname nada.example: nodename nor servname provided, or not known\n";
  chk(ssh_error(rr, sk) == fmt(tx::E_SSH_CONNECT, {"Could not resolve hostname nada.example: nodename nor servname provided, or not known"}), "error: sin servidor");
  rr.code = 1;
  rr.err = "sudo: a password is required\n";
  chk(ssh_error(rr, sk) == fmt(tx::E_SSH_SUDO, {"keyuser"}), "error: sudo");
  rr.err = "bash: line 1: psql: command not found\n";
  chk(ssh_error(rr, sk) == tx::E_SSH_NO_PG, "error: sin PostgreSQL");
  rr.err = "pg_dump: error: connection to server failed: FATAL:  database \"x\" does not exist\n";
  chk(ssh_error(rr, sk) == "connection to server failed: FATAL:  database \"x\" does not exist", "error de pg_dump");
  rr.code = -1;
  rr.err.clear();
  chk(ssh_error(rr, sk) == tx::E_NO_SSH, "sin ssh");
  // los servidores en los ajustes y las bases junto a las instancias
  Settings ss;
  ss.servers = {sk, sp};
  ss.servers[1].id = 4;
  ss.servers[1].name = "con\tclave";
  Settings ss2;
  std::vector<Inst> si2;
  std::vector<Inst> all = demo_insts(1000000);
  parse_settings(serialize(ss, all), ss2, si2);
  chk(ss2.servers.size() == 2 && ss2.servers[0].port == 2222 && ss2.servers[0].key == sk.key && !ss2.servers[0].password &&
          ss2.servers[1].password && ss2.servers[1].name == "con clave" && ss2.servers[1].secret.empty(), "servidores guardados (sin la contraseña)");
  chk(si2.size() == all.size() && si2.back().src == 1 && si2.back().id == all.back().id, "bases guardadas");
  std::vector<Inst> panel = {all[0], all[1]};
  for (auto& x : panel) x.src = 0;
  std::vector<Inst> mixed = merge_src(panel, parse_db_list("a|1\nb|2\n", sk), 3);
  chk(mixed.size() == 4 && mixed[0].src == 0 && mixed[2].src == 3, "las bases, después del panel");
  mixed[2].on = false;
  mixed = merge_src(mixed, parse_db_list("a|5\nc|3\n", sk), 3);
  chk(mixed.size() == 4 && mixed[2].name == "a" && !mixed[2].on && mixed[2].cloud_size == 5 && mixed[3].name == "c", "al volver a listar el servidor");
  mixed = merge_src(mixed, {panel[1]}, 0);
  chk(mixed.size() == 3 && mixed[0].src == 0 && mixed[1].src == 3, "al volver a conectar el panel");
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

// De verdad, contra un panel: DMS_CSHBK_LIVE=https://panel DMS_CSHBK_TOKEN=csh_…
// [DMS_CSHBK_FRESH=1] [DMS_CSHBK_INSTANCE=nombre] DMS_CSHBK_OUT=carpeta.
int live_test(const std::string& base_raw) {
  const char* tok = fl_getenv("DMS_CSHBK_TOKEN");
  const char* out = fl_getenv("DMS_CSHBK_OUT");
  std::string base = normalize_base(base_raw);
  if (!tok || !out || base.empty()) {
    std::printf("FAIL faltan DMS_CSHBK_TOKEN o DMS_CSHBK_OUT\n");
    return 1;
  }
  Ev e = fetch_instances(base, tok);
  if (!e.error.empty()) {
    std::printf("FAIL instancias: %s\n", e.error.c_str());
    return 1;
  }
  std::printf("instancias: %d\n", (int)e.list.size());
  Job job;
  job.base = base;
  job.token = tok;
  job.folder = out;
  job.fresh = fl_getenv("DMS_CSHBK_FRESH") != nullptr;
  const char* only = fl_getenv("DMS_CSHBK_INSTANCE");
  for (const auto& i : e.list)
    if (!only || i.name == only) job.items.push_back({i.id, i.name, 0});
  int ok = 0, bad = 0;
  std::atomic<bool> cancel{false};
  run_job(job, [&](const Ev& x) {
    if (x.kind == EV_STATE && x.state == B_ERROR) { bad++; std::printf("error %d: %s\n", x.id, x.error.c_str()); }
    if (x.kind == EV_STATE && x.state != B_ERROR) std::printf("estado %d: %d\n", x.id, x.state);
    if (x.kind == EV_CLOUD) std::printf("en el panel %d: %s (%lld)\n", x.id, x.file.c_str(), x.size);
    if (x.kind == EV_LOCAL) { ok++; std::printf("bajado %d: %s (%lld) %s\n", x.id, x.file.c_str(), x.size, x.state == B_SKIPPED ? "ya estaba" : "nuevo"); }
  }, cancel);
  std::printf("live ok=%d errores=%d\n", ok, bad);
  return ok > 0 ? 0 : 1;
}

// De verdad, contra un servidor: DMS_CSHBK_SSH=usuario@host:puerto
// [DMS_CSHBK_SSH_KEY=archivo | DMS_CSHBK_SSH_PASS=contraseña] DMS_CSHBK_OUT=carpeta.
// Lista sus bases y las vuelca todas (o DMS_CSHBK_INSTANCE).
int live_ssh(const std::string& target) {
  const char* out = fl_getenv("DMS_CSHBK_OUT");
  size_t at = target.find('@'), colon = target.rfind(':');
  if (!out || at == std::string::npos) {
    std::printf("FAIL faltan DMS_CSHBK_SSH=usuario@host[:puerto] o DMS_CSHBK_OUT\n");
    return 1;
  }
  Server s;
  s.id = 7;
  s.user = target.substr(0, at);
  s.host = colon != std::string::npos && colon > at ? target.substr(at + 1, colon - at - 1) : target.substr(at + 1);
  if (colon != std::string::npos && colon > at) s.port = (int)to_ll(target.substr(colon + 1));
  s.name = "prueba " + s.host;
  if (const char* k = fl_getenv("DMS_CSHBK_SSH_KEY")) s.key = k;
  if (const char* pw = fl_getenv("DMS_CSHBK_SSH_PASS")) {
    s.password = true;
    s.secret = pw;
  }
  Ev e = fetch_dbs(s, EV_INSTANCES);
  if (!e.error.empty()) {
    std::printf("error al listar: %s\n", e.error.c_str());
    return 2;
  }
  std::printf("bases:");
  for (const auto& d : e.list) std::printf(" %s(%lld)", d.name.c_str(), d.cloud_size);
  std::printf("\n");
  Job job;
  job.folder = out;
  job.servers.push_back(s);
  const char* only = fl_getenv("DMS_CSHBK_INSTANCE");
  for (const auto& d : e.list)
    if (!only || d.name == only) job.items.push_back({d.id, d.name, s.id});
  if (only && job.items.empty()) job.items.push_back({ssh_id(s.id, only), only, s.id});
  int ok = 0, bad = 0;
  std::atomic<bool> cancel{false};
  run_job(job, [&](const Ev& x) {
    if (x.kind == EV_STATE && x.state == B_ERROR) { bad++; std::printf("error: %s\n", x.error.c_str()); }
    if (x.kind == EV_LOCAL) { ok++; std::printf("volcada: %s (%lld)\n", x.file.c_str(), x.size); }
  }, cancel);
  std::printf("live ssh ok=%d errores=%d\n", ok, bad);
  return bad ? 3 : 0;
}

}  // namespace cb

// ============================================================ la barra de menús / la bandeja
// macOS: un NSStatusItem hecho desde C++ con el runtime de Objective-C.
// Windows: un icono en el área de notificación (Shell_NotifyIcon) con su
// menú (TrackPopupMenu) y sus globos. Linux: la ventana se minimiza.
namespace bar {
inline std::function<void(int)>& handler() {
  static std::function<void(int)> h;
  return h;
}
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
void on_act(id, SEL, id sender) {
  long t = msg<long>(sender, "tag");
  if (handler()) handler()((int)t);
}
id target() {
  static id t = nullptr;
  if (!t) {
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsCommunityBackupsTarget", 0);
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
// El icono (un símbolo del sistema; si no lo hay, una nube de texto) y el texto.
void set(const char* symbol, const std::string& title, const std::string&) {
  if (!item()) return;
  Pool pool;
  id b = msg(item(), "button");
  if (!b) return;
  id img = nullptr;
  if (class_getClassMethod((Class)objc_getClass("NSImage"), sel_registerName("imageWithSystemSymbolName:accessibilityDescription:"))) {
    img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str(symbol), str(tx::APP));
    if (!img)
      img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str("externaldrive"), str(tx::APP));
  }
  if (img) {
    msg<void, BOOL>(img, "setTemplate:", YES);
    msg<void, id>(b, "setImage:", img);
    msg<void, long>(b, "setImagePosition:", 2);   // NSImageLeft
  }
  msg<void, id>(b, "setTitle:", str(img ? title : "☁︎" + title));
}
id build(const std::vector<cb::MenuEntry>& entries) {
  id m = msg(msg(cls("NSMenu"), "alloc"), "init");
  msg<void, BOOL>(m, "setAutoenablesItems:", NO);
  for (const auto& e : entries) {
    if (e.sep) {
      msg<void, id>(m, "addItem:", msg(cls("NSMenuItem"), "separatorItem"));
      continue;
    }
    std::string t = e.dot >= 0 ? std::string(cb::state_emoji(e.dot)) + "  " + e.title : e.title;
    SEL action = e.tag ? sel_registerName("dmsAct:") : (SEL) nullptr;
    id it = msg<id, id, SEL, id>(msg(cls("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", str(t), action, str(""));
    msg<void, id>(it, "setTarget:", target());
    msg<void, long>(it, "setTag:", (long)e.tag);
    msg<void, BOOL>(it, "setEnabled:", (e.enabled || !e.sub.empty()) ? YES : NO);
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
void menu(const std::vector<cb::MenuEntry>& entries) {
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
void notify(const std::string& title, const std::string& text) { cb::notify_mac(title, text); }
void remove() {
  if (!item()) return;
  Pool pool;
  msg<void, id>(msg(cls("NSStatusBar"), "systemStatusBar"), "removeStatusItem:", item());
  msg<void>(item(), "release");
  item() = nullptr;
}
#elif defined(_WIN32)
const UINT WM_TRAY = WM_APP + 17;
struct Tray {
  HWND hwnd = nullptr;
  NOTIFYICONDATAW nid{};
  std::vector<cb::MenuEntry> entries;
  UINT created_msg = 0;
  bool added = false;
};
Tray& tray() {
  static Tray t;
  return t;
}
void copy_w(wchar_t* dst, size_t n, const std::string& s) {
  std::wstring w = cb::wide(s);
  if (w.size() >= n) w = w.substr(0, n - 1);
  wcsncpy(dst, w.c_str(), n);
  dst[n - 1] = 0;
}
HMENU build(const std::vector<cb::MenuEntry>& entries) {
  HMENU m = CreatePopupMenu();
  for (const auto& e : entries) {
    if (e.sep) {
      AppendMenuW(m, MF_SEPARATOR, 0, nullptr);
      continue;
    }
    std::wstring t = cb::wide(e.title);
    std::wstring safe;
    for (wchar_t c : t) {   // «&» marca la tecla de acceso
      if (c == L'&') safe += L'&';
      safe += c;
    }
    if (!e.sub.empty()) AppendMenuW(m, MF_POPUP | MF_STRING, (UINT_PTR)build(e.sub), safe.c_str());
    else AppendMenuW(m, MF_STRING | (e.enabled && e.tag ? 0 : MF_GRAYED), (UINT_PTR)e.tag, safe.c_str());
  }
  return m;
}
void add_icon() {
  Tray& t = tray();
  t.added = Shell_NotifyIconW(NIM_ADD, &t.nid) != FALSE;
}
void popup() {
  Tray& t = tray();
  HMENU m = build(t.entries);
  POINT pt;
  GetCursorPos(&pt);
  SetForegroundWindow(t.hwnd);
  TrackPopupMenu(m, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN, pt.x, pt.y, 0, t.hwnd, nullptr);
  PostMessageW(t.hwnd, WM_NULL, 0, 0);
  DestroyMenu(m);   // también los submenús
}
LRESULT CALLBACK proc(HWND h, UINT m, WPARAM w, LPARAM l) {
  Tray& t = tray();
  if (m == WM_TRAY) {
    if (l == WM_LBUTTONUP || l == WM_RBUTTONUP || l == WM_CONTEXTMENU) popup();
    else if (l == WM_LBUTTONDBLCLK && handler()) handler()(cb::tag(cb::A_WINDOW, 0));
    return 0;
  }
  if (m == WM_COMMAND && HIWORD(w) == 0) {
    int tg = (int)LOWORD(w);
    if (tg && handler()) handler()(tg);
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
  wc.lpszClassName = L"DmsCommunityBackupsTray";
  RegisterClassW(&wc);
  t.hwnd = CreateWindowExW(WS_EX_TOOLWINDOW, wc.lpszClassName, L"", WS_POPUP, 0, 0, 0, 0, nullptr, nullptr, inst, nullptr);
  if (!t.hwnd) return false;
  t.created_msg = RegisterWindowMessageW(L"TaskbarCreated");
  t.nid.cbSize = sizeof(t.nid);
  t.nid.hWnd = t.hwnd;
  t.nid.uID = 1;
  t.nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  t.nid.uCallbackMessage = WM_TRAY;
  std::wstring exe = cb::wide(cb::exe_path());
  HICON icon = ExtractIconW(inst, exe.c_str(), 0);
  if ((UINT_PTR)icon <= 1) icon = LoadIconW(nullptr, MAKEINTRESOURCEW(32512));   // IDI_APPLICATION
  t.nid.hIcon = icon;
  copy_w(t.nid.szTip, 128, tx::APP);
  add_icon();
  return t.added;
}
// En Windows el «texto» va en la ayuda del icono (al pasar el ratón).
void set(const char*, const std::string&, const std::string& tip) {
  Tray& t = tray();
  if (!t.added) return;
  copy_w(t.nid.szTip, 128, tip);
  t.nid.uFlags = NIF_TIP;
  Shell_NotifyIconW(NIM_MODIFY, &t.nid);
  t.nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
}
void menu(const std::vector<cb::MenuEntry>& entries) { tray().entries = entries; }
void dock(bool) {}
void notify(const std::string& title, const std::string& text) {
  Tray& t = tray();
  if (!t.added) return;
  t.nid.uFlags = NIF_INFO;
  copy_w(t.nid.szInfoTitle, 64, title);
  copy_w(t.nid.szInfo, 256, text);
  t.nid.dwInfoFlags = NIIF_INFO;
  Shell_NotifyIconW(NIM_MODIFY, &t.nid);
  t.nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
}
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
void set(const char*, const std::string&, const std::string&) {}
void menu(const std::vector<cb::MenuEntry>&) {}
void dock(bool) {}
void notify(const std::string&, const std::string&) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  cb::Settings st;
  std::vector<cb::Inst> insts;
  std::vector<cb::Got> got;
  cb::ListView* view = nullptr;
  std::string token;
  bool connected = false, connecting = false, running = false;
  bool in_bar = false, quitting = false, live = true;
  int run_total = 0, run_done = 0, run_ok = 0, run_bad = 0, pending = 0;
  std::vector<int> run_ids;           // lo que se respalda ahora
  std::vector<std::string> log_mem;   // el historial en las pruebas
  std::shared_ptr<std::atomic<bool>> cancel = std::make_shared<std::atomic<bool>>(false);
  std::string message, bar_key;
  long long message_until = 0, last_prune = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    // ssh la abre como SSH_ASKPASS (en Windows) para leer una contraseña.
    if (const char* pw = fl_getenv("DMS_CSHBK_ASKPASS")) std::exit(cb::askpass(pw));
    if (const char* t = fl_getenv("DMS_CSHBK_SSH")) std::exit(cb::live_ssh(t));
    if (fl_getenv("DMS_CSHBK_SELFTEST")) std::exit(cb::selftest());
    if (const char* u = fl_getenv("DMS_CSHBK_LIVE")) std::exit(cb::live_test(u));
    if (fl_getenv("DMS_CSHBK_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_CSHBK_SHOT")) { set_fonts(); std::exit(shots(d)); }
    if (!cb::single_instance()) {
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
    Board->box(FL_FLAT_BOX);
    Top->box(FL_FLAT_BOX);
    Top->resizable(nullptr);
    resizable(Board);
    view = new cb::ListView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    view->insts = &insts;
    view->on_act = [](int act, int idx) { if (self()) self()->row_act(act, idx); };
    std::vector<std::string> hours;
    for (int h = 0; h < 24; h++) {
      char b[8];
      std::snprintf(b, sizeof b, "%02d:00", h);
      hours.push_back(b);
    }
    At->items(hours);
    std::vector<std::string> days;
    for (int d = 0; d < 7; d++) days.push_back(cb::day_name(d, false));
    Day->items(days);
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

  void form_create() override {
    set_fonts();
    Fl::lock();   // el hilo de los respaldos avisa a la ventana
    setup();
    load();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    else BtnBar->copy_label(tx::MINIMIZE);
    if ((!token.empty() && !st.base.empty()) || !st.servers.empty()) connect(false);
    refresh();
    if (cb::started_iconic() && bar::available())
      Fl::add_timeout(0.4, [](void*) { if (self()) self()->to_bar(); });
  }
  void form_close() override { save(); }

  // ---- guardar
  std::string settings_file() const { return cb::join(cb::config_dir(), "settings.tsv"); }
  std::string got_file() const { return cb::join(cb::config_dir(), "downloaded.tsv"); }
  void load() {
    std::string text;
    if (cb::read_file(settings_file(), text)) cb::parse_settings(text, st, insts);
    if (cb::read_file(got_file(), text)) got = cb::parse_got(text);
    if (st.folder.empty()) st.folder = cb::default_folder();
    token = cb::token_get();
    fix_rel();
    show_settings();
    // Un respaldo que tocaba con el equipo apagado: dentro de un minuto.
    long long now = cb::now_t();
    if (st.next_run <= 0) st.next_run = cb::next_slot(now, st.every, st.hour, st.wday);
    else if (st.next_run <= now) st.next_run = now + 60;
  }
  void show_settings() {
    PanelUrl->value(st.base.c_str());
    Token->value(token.c_str());
    Folder->value(st.folder.c_str());
    Every->index(cb::every_index(st.every));
    At->index(st.hour);
    Day->index(st.wday);
    int k = 2;   // 3 días
    for (int i = 0; i < cb::DAYS_N; i++)
      if (cb::DAYS[i] == st.days) k = i;
    Keep->index(k);
    Fresh->checked(st.fresh);
    Filestore->checked(st.fs);
    Filestore->enabled(st.fresh);
    Login->checked(st.login);
    schedule_widgets();
  }
  // «a las» no cuenta cada hora; «el» (el día) solo cada semana.
  void schedule_widgets() {
    At->enabled(st.every != 1);
    LblAt->enabled(st.every != 1);
    Day->enabled(st.every == cb::WEEK_H);
    LblDay->enabled(st.every == cb::WEEK_H);
  }
  void save() {
    if (!live) return;   // las capturas y las pruebas no guardan nada
    fl_make_path(cb::config_dir().c_str());
    cb::write_file(settings_file(), cb::serialize(st, insts));
    cb::write_file(got_file(), cb::serialize_got(got));
  }

  // ---- el panel
  bool read_fields() {
    std::string base = cb::normalize_base(PanelUrl->value());
    if (base.empty()) { say(tx::BAD_URL); return false; }
    st.base = base;
    PanelUrl->value(base.c_str());
    std::string t = cb::trim(Token->value());
    if (t.empty()) { say(tx::NEED_TOKEN); return false; }
    if (t != token) {
      token = t;
      if (live) cb::token_set(token);
    }
    return true;
  }
  // El panel (si hay token) y cada servidor SSH, cada uno en su hilo.
  void connect(bool from_button) {
    if (from_button) {
      std::string t = cb::trim(Token->value());
      if ((!t.empty() || st.servers.empty()) && !read_fields()) return;
    }
    bool panel = !token.empty() && !st.base.empty();
    if (!panel && st.servers.empty()) { say(tx::NEED_TOKEN); return; }
    if (pending > 0) return;
    pending = (panel ? 1 : 0) + (int)st.servers.size();
    connecting = true;
    say(tx::CONNECTING);
    if (!live) return;
    if (panel) {
      std::string b = st.base, t = token;
      std::thread([b, t] {
        auto* e = new cb::Ev(cb::fetch_instances(b, t));
        Fl::awake(on_event, e);
      }).detach();
    }
    for (const auto& v : st.servers) fetch_server(v, cb::EV_INSTANCES);
  }
  // Las bases de un servidor (la contraseña se lee del Llavero en el hilo).
  void fetch_server(cb::Server v, int kind) {
    std::thread([v, kind]() mutable {
      if (v.password && v.secret.empty()) v.secret = cb::secret_get(cb::server_service(v.id));
      auto* e = new cb::Ev(cb::fetch_dbs(v, kind));
      Fl::awake(on_event, e);
    }).detach();
  }
  std::string server_name(int src) const {
    for (const auto& v : st.servers)
      if (v.id == src) return v.name;
    return "";
  }
  // La carpeta de cada uno (y su clave en los bajados): la instancia del
  // panel, o «servidor/base». Las bases de un servidor quitado se van.
  void fix_rel() {
    std::vector<cb::Inst> keep;
    for (auto& in : insts) {
      if (in.src) {
        std::string n = server_name(in.src);
        if (n.empty()) continue;
        in.version = n;
        in.rel = cb::safe_name(n) + cb::SEP + cb::safe_name(in.name);
      } else {
        in.rel = cb::safe_name(in.name);
      }
      keep.push_back(in);
    }
    insts = keep;
  }
  static std::string display(const cb::Inst& in) { return in.src ? in.name + " (" + in.version + ")" : in.name; }

  // ---- respaldar
  int index_of(int id) const {
    for (int i = 0; i < (int)insts.size(); i++)
      if (insts[(size_t)i].id == id) return i;
    return -1;
  }
  bool ready() {
    if (token.empty() && st.servers.empty()) { say(tx::NEED_TOKEN); return false; }
    if (cb::trim(st.folder).empty()) { say(tx::NEED_FOLDER); return false; }
    return true;
  }
  // Respalda las marcadas (o solo [only]).
  void start_run(int only = -1) {
    if (running) { say(tx::ALREADY_RUNNING_JOB); return; }
    long long now = cb::now_t();
    if (only < 0) {
      st.next_run = cb::next_slot(now, st.every, st.hour, st.wday);
      st.last_run = now;
    }
    if (!ready()) { save(); refresh(); return; }
    cb::Job job;
    job.base = st.base;
    job.token = token;
    job.folder = st.folder;
    job.fresh = st.fresh;
    job.fs = st.fs;
    job.servers = st.servers;
    run_ids.clear();
    for (int i = 0; i < (int)insts.size(); i++) {
      cb::Inst& in = insts[(size_t)i];
      if (only >= 0 ? i != only : !in.on) continue;
      in.state = cb::B_QUEUED;
      in.error.clear();
      job.items.push_back({in.id, in.name, in.src});
      run_ids.push_back(in.id);
    }
    if (job.items.empty()) { say(tx::NONE_SELECTED); save(); refresh(); return; }
    running = true;
    run_total = (int)job.items.size();
    run_done = run_ok = run_bad = 0;
    cancel->store(false);
    log_line(cb::fmt(tx::LOG_START, {std::to_string(run_total)}));
    save();
    refresh();
    if (!live) return;
    auto flag = cancel;
    std::thread([job, flag]() mutable {
      for (auto& v : job.servers)
        if (v.password) v.secret = cb::secret_get(cb::server_service(v.id));
      cb::run_job(job, [](const cb::Ev& e) { Fl::awake(on_event, new cb::Ev(e)); }, *flag);
    }).detach();
  }
  static void on_event(void* p) {
    std::unique_ptr<cb::Ev> e(static_cast<cb::Ev*>(p));
    if (self()) self()->apply(*e);
  }
  void apply(const cb::Ev& e) {
    long long now = cb::now_t();
    int i = index_of(e.id);
    switch (e.kind) {
      case cb::EV_INSTANCES:
        if (pending > 0) pending--;
        connecting = pending > 0;
        if (!e.error.empty()) {
          say(e.error);
          log_line(cb::fmt(tx::LOG_CONNECT_ERR, {e.error}));
          break;
        }
        if (e.src == 0) connected = true;
        insts = cb::merge_src(insts, e.list, e.src);
        fix_rel();
        say(e.src == 0 ? cb::fmt(tx::CONNECTED, {std::to_string(e.list.size())})
                       : cb::fmt(tx::CONNECTED_SSH, {server_name(e.src), std::to_string(e.list.size())}));
        break;
      case cb::EV_TEST: {
        std::string m;
        if (!e.error.empty()) m = e.error;
        else if (e.list.empty()) m = tx::SV_TEST_NONE;
        else {
          std::string names;
          for (size_t k = 0; k < e.list.size() && k < 5; k++) names += (k ? ", " : "") + e.list[k].name;
          if (e.list.size() > 5) names += ", …";
          m = cb::fmt(tx::SV_TEST_OK, {std::to_string(e.list.size()), names});
        }
        if (sw.note) {
          sw.note->copy_label(m.c_str());
          sw.note->labelcolor(e.error.empty() ? cb::rgb(0x15803d) : cb::rgb(0xb91c1c));
          sw.note->redraw();
        }
        return;
      }
      case cb::EV_STATE:
        if (i < 0) break;
        insts[(size_t)i].state = e.state;
        insts[(size_t)i].error = e.error;
        if (e.state == cb::B_DOWNLOADING) {
          insts[(size_t)i].part = e.part;
          insts[(size_t)i].total = e.total;
          insts[(size_t)i].got = 0;
        }
        if (e.state == cb::B_ERROR) {
          run_done++;
          run_bad++;
          log_line(cb::fmt(tx::LOG_ERR, {display(insts[(size_t)i]), e.error}));
        }
        break;
      case cb::EV_CLOUD:
        if (i < 0) break;
        insts[(size_t)i].cloud_id = e.cloud_id;
        insts[(size_t)i].cloud_file = e.file;
        insts[(size_t)i].cloud_date = e.date;
        insts[(size_t)i].cloud_size = e.size;
        insts[(size_t)i].cloud_fs = e.fs;
        break;
      case cb::EV_LOCAL: {
        if (i < 0) break;
        cb::Inst& in = insts[(size_t)i];
        in.state = e.state;
        in.error.clear();
        in.local_file = e.file;
        in.local_size = e.size;
        in.local_t = now;
        run_done++;
        run_ok++;
        cb::add_got(got, {in.rel.empty() ? in.name : in.rel, e.file, now, e.size});
        log_line(cb::fmt(tx::LOG_OK, {display(in), cb::base_name(e.file), cb::human(e.size)}));
        prune();
        break;
      }
      case cb::EV_DONE: {
        running = false;
        // El resumen sale de cómo ha quedado cada uno, con el primero que falló.
        int ok = 0, bad = 0;
        std::string first;
        for (int id : run_ids) {
          int k = index_of(id);
          if (k < 0) continue;
          const cb::Inst& in = insts[(size_t)k];
          if (in.state == cb::B_OK || in.state == cb::B_SKIPPED) ok++;
          else if (in.state == cb::B_ERROR) {
            bad++;
            if (first.empty()) first = display(in) + ": " + in.error;
          }
        }
        if (!run_ids.empty()) {
          if (first.size() > 160) first = first.substr(0, 160) + "…";
          std::string text = bad ? cb::fmt(tx::NOTIFY_ERRORS_FIRST, {std::to_string(ok), std::to_string(bad), first})
                                 : cb::fmt(tx::NOTIFY_DONE, {std::to_string(ok)});
          bar::notify(tx::NOTIFY_TITLE, text);
          say(text);
          log_line(cb::fmt(tx::LOG_END, {std::to_string(ok), std::to_string(bad)}));
        }
        run_ids.clear();
        break;
      }
    }
    save();
    refresh();
  }

  // ---- lo que se ve
  void say(const std::string& m) {
    message = m;
    message_until = cb::now_t() + 6;
    refresh();
  }
  std::string status_text() const {
    long long now = cb::now_t();
    if (!message.empty() && now < message_until) return message;
    if (running) return cb::fmt(tx::RUNNING, {std::to_string(cb::imin(run_done + 1, run_total)), std::to_string(run_total)});
    if (token.empty() && st.servers.empty()) return tx::NO_CONFIG;
    std::string s = cb::fmt(tx::HEAD, {std::to_string(insts.size()), std::to_string(cb::count_on(insts))});
    s += "  ·  " + cb::fmt(tx::NEXT, {cb::when(st.next_run, now)});
    s += "  ·  " + cb::fmt(tx::LAST, {cb::when(st.last_run, now)});
    return s;
  }
  void refresh() {
    Status->text(" " + status_text());
    BtnRun->enabled(!running);
    if (view) {
      view->connected = connected;
      view->redraw();
    }
    if (bar::available()) {
      long long now = cb::now_t();
      bool err = false;
      int pct = -1;
      for (const auto& in : insts) {
        err = err || (in.on && in.state == cb::B_ERROR);
        if (in.state == cb::B_DOWNLOADING && in.total > 0) pct = (int)(100.0 * (double)in.got / (double)in.total);
      }
      std::string title = running ? (pct >= 0 ? " " + std::to_string(pct) + " %" : " …") : "";
      bar::set(running ? "arrow.down.circle" : err ? "exclamationmark.triangle" : "externaldrive.badge.icloud", title,
               std::string(tx::APP) + "\n" + status_text());
      auto m = cb::bar_menu(insts, running, cb::imin(run_done + 1, run_total), run_total, st.next_run, st.last_run, now);
      std::string key = cb::menu_key(m);
      if (key != bar_key) {   // el menú solo se rehace si cambia
        bar_key = key;
        bar::menu(m);
      }
    }
  }

  // ---- la barra
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
  void close_clicked() {
    if (bar::available()) to_bar();
    else quit();
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
    cancel->store(true);
    for (auto& in : insts)
      if (!in.part.empty() && in.state == cb::B_DOWNLOADING) fl_unlink(in.part.c_str());
    save();
    bar::remove();
    hide();
    std::exit(0);
  }
  void bar_act(int t) {
    int act = t / 1000, idx = t % 1000;
    switch (act) {
      case cb::A_GET: row_act(1, idx); break;
      case cb::A_FOLDER_ONE: row_act(2, idx); break;
      case cb::A_RUN: start_run(); break;
      case cb::A_FOLDER: cb::open_folder(st.folder); break;
      case cb::A_WINDOW: if (in_bar) from_bar(); else show(); break;
      case cb::A_TO_BAR: to_bar(); break;
      case cb::A_QUIT: quit(); break;
    }
  }
  void row_act(int act, int idx) {
    if (idx < 0 || idx >= (int)insts.size()) return;
    cb::Inst& in = insts[(size_t)idx];
    if (act == 0) in.on = !in.on;
    else if (act == 1) start_run(idx);
    else if (act == 2 && live) cb::open_folder(cb::join(st.folder, in.rel.empty() ? cb::safe_name(in.name) : in.rel));
    save();
    refresh();
  }

  // ---- el historial
  // Cada respaldo deja aquí lo que bajó y lo que falló (y por qué).
  std::string log_file() const { return cb::join(cb::config_dir(), "history.log"); }
  void log_line(const std::string& line) {
    if (!live) {
      log_mem.push_back(line);
      return;
    }
    struct tm v = cb::local(cb::now_t());
    char b[32];
    std::strftime(b, sizeof b, "%Y-%m-%d %H:%M:%S", &v);
    std::string path = log_file();
    fl_make_path(cb::config_dir().c_str());
    if (cb::file_size(path) > 512 * 1024) {   // se queda con la segunda mitad
      std::string old;
      cb::read_file(path, old);
      old = old.substr(old.size() / 2);
      size_t nl = old.find('\n');
      cb::write_file(path, nl == std::string::npos ? "" : old.substr(nl + 1));
    }
    if (FILE* f = fl_fopen(path.c_str(), "ab")) {
      std::fprintf(f, "%s  %s\n", b, line.c_str());
      std::fclose(f);
    }
  }
  void show_log() {
    if (!live) return;
    if (cb::file_size(log_file()) < 0) log_line(tx::LOG_EMPTY);
    cb::open_file(log_file());
  }

  // ---- los servidores SSH
  // Una ventana con la lista de servidores y sus datos: nombre, dirección,
  // puerto, usuario y cómo se entra (clave SSH o contraseña).
  struct ServersWin {
    Fl_Double_Window* win = nullptr;
    Fl_Hold_Browser* list = nullptr;
    Fl_Input *name = nullptr, *host = nullptr, *user = nullptr, *key = nullptr;
    Fl_Int_Input* port = nullptr;
    Fl_Choice* auth = nullptr;
    Fl_Secret_Input* pass = nullptr;
    Fl_Button *pick = nullptr, *del = nullptr;
    Fl_Box* note = nullptr;
    int sel = -1;   // el servidor que se edita (-1: uno nuevo)
  } sw;
  void sv_build() {
    if (sw.win) return;
    auto* w = new Fl_Double_Window(780, 470, tx::SV_TITLE);
    w->color(cb::rgb(0xf4f6f9));
    w->begin();
    auto* help = new Fl_Box(16, 10, 748, 46, tx::SV_HELP);
    help->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP);
    help->labelsize(12);
    help->labelcolor(cb::rgb(0x4b5563));
    sw.list = new Fl_Hold_Browser(16, 64, 250, 334);
    sw.list->callback([](Fl_Widget*, void*) { if (self()) self()->sv_load(self()->sw.list->value() - 1); });
    const int x = 410, wd = 354;
    sw.name = new Fl_Input(x, 64, wd, 28, tx::SV_NAME);
    sw.host = new Fl_Input(x, 98, wd, 28, tx::SV_HOST);
    sw.port = new Fl_Int_Input(x, 132, 90, 28, tx::SV_PORT);
    sw.user = new Fl_Input(x, 166, wd, 28, tx::SV_USER);
    sw.auth = new Fl_Choice(x, 200, wd, 28, tx::SV_AUTH);
    sw.auth->add(tx::SV_AUTH_KEY);
    sw.auth->add(tx::SV_AUTH_PW);
    sw.auth->callback([](Fl_Widget*, void*) { if (self()) self()->sv_auth_changed(); });
    sw.key = new Fl_Input(x, 234, wd - 100, 28, tx::SV_KEY);
    sw.key->tooltip(tx::SV_KEY_HINT);
    sw.pick = new Fl_Button(x + wd - 92, 234, 92, 28, tx::SV_PICK);
    sw.pick->callback([](Fl_Widget*, void*) { if (self()) self()->sv_pick(); });
    sw.pass = new Fl_Secret_Input(x, 234, wd, 28, tx::SV_PASS);
    sw.note = new Fl_Box(282, 274, 482, 120);
    sw.note->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_WRAP);
    sw.note->labelsize(13);
    auto* b_new = new Fl_Button(16, 418, 120, 32, tx::SV_NEW);
    b_new->callback([](Fl_Widget*, void*) { if (self()) self()->sv_load(-1); });
    sw.del = new Fl_Button(146, 418, 120, 32, tx::SV_DEL);
    sw.del->callback([](Fl_Widget*, void*) { if (self()) self()->sv_delete(); });
    auto* b_test = new Fl_Button(410, 418, 170, 32, tx::SV_TEST);
    b_test->callback([](Fl_Widget*, void*) { if (self()) self()->sv_test(); });
    auto* b_save = new Fl_Button(590, 418, 90, 32, tx::SV_SAVE);
    b_save->color(cb::rgb(0x2563eb));
    b_save->labelcolor(FL_WHITE);
    b_save->labelfont(FL_HELVETICA_BOLD);
    b_save->callback([](Fl_Widget*, void*) { if (self()) self()->sv_save(); });
    auto* b_close = new Fl_Button(690, 418, 74, 32, tx::SV_CLOSE);
    b_close->callback([](Fl_Widget*, void*) { if (self()) self()->sw.win->hide(); });
    w->end();
    w->set_modal();
    sw.win = w;
  }
  void sv_fill() {
    sw.list->clear();
    for (const auto& v : st.servers) sw.list->add((v.name + "  —  " + cb::server_label(v)).c_str());
    if (sw.sel >= 0 && sw.sel < (int)st.servers.size()) sw.list->value(sw.sel + 1);
  }
  void sv_load(int i) {
    sw.sel = (i >= 0 && i < (int)st.servers.size()) ? i : -1;
    cb::Server v;
    if (sw.sel >= 0) v = st.servers[(size_t)sw.sel];
    sw.name->value(v.name.c_str());
    sw.host->value(v.host.c_str());
    sw.port->value(std::to_string(v.port).c_str());
    sw.user->value(v.user.c_str());
    sw.key->value(v.key.c_str());
    sw.pass->value("");
    sw.auth->value(v.password ? 1 : 0);
    if (sw.sel >= 0) sw.del->activate();
    else sw.del->deactivate();
    if (sw.sel < 0) sw.list->deselect();
    sv_auth_changed();
    sw.note->labelcolor(cb::rgb(0x4b5563));
    sw.note->copy_label(sw.sel >= 0 && v.password ? tx::SV_PASS_KEEP : st.servers.empty() ? tx::SV_EMPTY : "");
  }
  void sv_auth_changed() {
    bool pw = sw.auth->value() == 1;
    if (pw) {
      sw.key->hide();
      sw.pick->hide();
      sw.pass->show();
    } else {
      sw.key->show();
      sw.pick->show();
      sw.pass->hide();
    }
    if (sw.win) sw.win->redraw();
  }
  void sv_pick() {
    Fl_Native_File_Chooser ch;
    ch.type(Fl_Native_File_Chooser::BROWSE_FILE);
    ch.title(tx::SV_KEY);
#ifdef _WIN32
    const char* h = fl_getenv("USERPROFILE");
#else
    const char* h = fl_getenv("HOME");
#endif
    std::string dir = cb::join(h ? h : ".", ".ssh");
    ch.directory(dir.c_str());
    if (ch.show() == 0 && ch.filename()) sw.key->value(ch.filename());
  }
  // Los datos de la ventana; "" si valen, o lo que falta.
  std::string sv_read(cb::Server& v) {
    v.host = cb::trim(sw.host->value());
    v.name = cb::clean(sw.name->value());
    if (v.name.empty()) v.name = v.host;
    v.user = cb::trim(sw.user->value());
    v.key = cb::trim(sw.key->value());
    v.password = sw.auth->value() == 1;
    int port = std::atoi(sw.port->value());
    if (v.host.empty() || v.host.find(' ') != std::string::npos) return tx::SV_ERR_HOST;
    if (port < 1 || port > 65535) return tx::SV_ERR_PORT;
    v.port = port;
    if (v.user.empty() || v.user.find(' ') != std::string::npos) return tx::SV_ERR_USER;
    v.secret = sw.pass->value();
    if (v.password && v.secret.empty()) {
      if (sw.sel >= 0 && st.servers[(size_t)sw.sel].password) v.secret = cb::secret_get(cb::server_service(st.servers[(size_t)sw.sel].id));
      if (v.secret.empty()) return tx::SV_ERR_PASS;
    }
    return "";
  }
  void sv_save() {
    cb::Server v;
    std::string err = sv_read(v);
    if (!err.empty()) {
      sw.note->labelcolor(cb::rgb(0xb91c1c));
      sw.note->copy_label(err.c_str());
      return;
    }
    bool typed = sw.pass->value()[0] != 0;
    if (sw.sel >= 0) {
      v.id = st.servers[(size_t)sw.sel].id;
      st.servers[(size_t)sw.sel] = v;
    } else {
      int id = 1;
      for (const auto& x : st.servers) id = cb::imax(id, x.id + 1);
      v.id = id;
      st.servers.push_back(v);
      sw.sel = (int)st.servers.size() - 1;
    }
    std::string svc = cb::server_service(v.id);
    if (live && v.password && typed) cb::secret_set(svc, v.secret);
    if (live && !v.password) cb::secret_del(svc);
    st.servers[(size_t)sw.sel].secret.clear();
    fix_rel();
    save();
    sv_fill();
    sw.pass->value("");
    sw.note->labelcolor(cb::rgb(0x15803d));
    sw.note->copy_label(cb::fmt(tx::SV_SAVED, {v.name}).c_str());
    if (live) {
      pending++;
      connecting = true;
      fetch_server(v, cb::EV_INSTANCES);
    }
    refresh();
  }
  void sv_delete() {
    if (sw.sel < 0) return;
    cb::Server v = st.servers[(size_t)sw.sel];
    if (live && fl_choice("%s", tx::BTN_NO, tx::BTN_YES, nullptr, cb::fmt(tx::SV_ASK_DEL, {v.name}).c_str()) != 1) return;
    st.servers.erase(st.servers.begin() + sw.sel);
    if (live) cb::secret_del(cb::server_service(v.id));
    fix_rel();   // sus bases se van de la lista (lo ya bajado se queda en la carpeta)
    save();
    sv_fill();
    sv_load(-1);
    refresh();
  }
  void sv_test() {
    cb::Server v;
    std::string err = sv_read(v);
    sw.note->labelcolor(cb::rgb(0x4b5563));
    if (!err.empty()) {
      sw.note->labelcolor(cb::rgb(0xb91c1c));
      sw.note->copy_label(err.c_str());
      return;
    }
    v.id = sw.sel >= 0 ? st.servers[(size_t)sw.sel].id : 999;
    sw.note->copy_label(cb::fmt(tx::SV_TESTING, {cb::server_label(v)}).c_str());
    if (live) fetch_server(v, cb::EV_TEST);
  }
  void servers_dialog() {
    sv_build();
    sv_fill();
    sv_load(sw.sel >= 0 ? sw.sel : st.servers.empty() ? -1 : 0);
    sw.win->show();
  }

  // ---- borrar los antiguos
  // Los bajados hace más de los días elegidos (solo los que bajó la app; el
  // último de cada instancia se queda). Al bajar uno, al cambiar los días y
  // cada hora.
  void prune() {
    last_prune = cb::now_t();
    auto drop = cb::prune_got(got, last_prune, st.days);
    if (!live) return;
    for (const auto& path : drop) fl_unlink(path.c_str());
    if (!drop.empty()) save();
  }

  // ---- la secuencia y las opciones
  void schedule_changed() {
    int k = Every->index();
    st.every = cb::EVERY_H[k >= 0 && k < cb::EVERY_N ? k : 6];
    st.hour = cb::imax(At->index(), 0);
    st.wday = cb::imax(Day->index(), 0);
    schedule_widgets();
    st.next_run = cb::next_slot(cb::now_t(), st.every, st.hour, st.wday);
    save();
    say(cb::fmt(tx::SCHEDULE_SET, {cb::when(st.next_run, cb::now_t())}));
  }
  void set_folder(const std::string& raw) {
    std::string f = cb::trim(raw);
    if (f.empty()) { say(tx::NEED_FOLDER); Folder->value(st.folder.c_str()); return; }
    while (f.size() > 1 && (f.back() == '/' || f.back() == '\\')) f.pop_back();
    st.folder = f;
    Folder->value(f.c_str());
    save();
    say(cb::fmt(tx::FOLDER_SET, {f}));
  }

  // ---- eventos del diseño
  void BtnConnect_click() override { connect(true); }
  void BtnServers_click() override { servers_dialog(); }
  void PanelUrl_enter() override { connect(true); }
  void Token_enter() override { connect(true); }
  void BtnFolder_click() override {
    Fl_Native_File_Chooser ch;
    ch.type(Fl_Native_File_Chooser::BROWSE_DIRECTORY);
    ch.title(tx::CHOOSE_FOLDER);
    fl_make_path(st.folder.c_str());
    ch.directory(st.folder.c_str());
    if (ch.show() == 0 && ch.filename()) set_folder(ch.filename());
  }
  void Folder_enter() override { set_folder(Folder->value()); }
  void BtnOpen_click() override {
    set_folder(Folder->value());
    if (live) cb::open_folder(st.folder);
  }
  void Every_select() override { schedule_changed(); }
  void At_select() override { schedule_changed(); }
  void Day_select() override { schedule_changed(); }
  void Keep_select() override {
    int k = Keep->index();
    if (k >= 0 && k < cb::DAYS_N) st.days = cb::DAYS[k];
    prune();
    save();
  }
  void Fresh_click() override {
    st.fresh = Fresh->checked();
    Filestore->enabled(st.fresh);
    save();
  }
  void Filestore_click() override {
    st.fs = Filestore->checked();
    save();
  }
  void Login_click() override {
    bool on = Login->checked();
    if (live && !cb::login_set(on)) {
      Login->checked(!on);
      say(tx::LOGIN_FAIL);
      return;
    }
    st.login = on;
    save();
    say(on ? tx::LOGIN_ON : tx::LOGIN_OFF);
  }
  void BtnRun_click() override {
    set_folder(Folder->value());
    start_run();
  }
  void BtnBar_click() override { to_bar(); }
  void Tick_timer() override {
    long long now = cb::now_t();
    if (!running && !token.empty() && st.next_run > 0 && now >= st.next_run) start_run();
    if (!running && now - last_prune >= 3600) prune();
    for (auto& in : insts)
      if (in.state == cb::B_DOWNLOADING && !in.part.empty()) {
        long long n = cb::file_size(in.part);
        in.got = n > 0 ? n : 0;
      }
    refresh();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_RUN) BtnRun_click();
    else if (item == tx::MP_FOLDER) BtnOpen_click();
    else if (item == tx::MP_SERVERS) servers_dialog();
    else if (item == tx::MP_LOG) show_log();
    else if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
  }

  // ---- capturas y pruebas de la interfaz, sin ventana
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
    long long now = cb::now_t();
    insts = cb::demo_insts(now);
    cb::Server sv;   // el de las bases de ejemplo
    sv.id = 1;
    sv.name = "ubuntu-oficina";
    sv.host = "192.0.2.10";
    st.servers = {sv};
    fix_rel();
    connected = true;
    token = "csh_demo_token_0000000000";
    st.base = "https://communitysh.xyz";
#ifdef _WIN32
    st.folder = std::string("C:\\Users\\demo\\Documents\\") + tx::DEFAULT_FOLDER;
#else
    st.folder = std::string("/Users/demo/Documents/") + tx::DEFAULT_FOLDER;
#endif
    st.every = 24;
    st.hour = 3;
    st.days = 3;
    st.fresh = true;
    st.last_run = now - 3 * 3600;
    st.next_run = cb::next_slot(now, st.every, st.hour, st.wday);
    show_settings();
    message.clear();
    refresh();
  }
  // El escritorio con la barra de menús y el menú del icono abierto (como
  // en macOS), dibujado con los mismos datos del menú.
  static int draw_menu(int x, int y, const std::vector<cb::MenuEntry>& m, int hi, int* hi_y) {
    const int rowh = 34, seph = 12;
    fl_font(FL_HELVETICA, 16);
    int w = 320, h = 12;
    for (const auto& e : m) {
      w = cb::imax(w, (int)fl_width(e.title.c_str()) + (e.dot >= 0 ? 70 : 40) + (e.sub.empty() ? 0 : 30));
      h += e.sep ? seph : rowh;
    }
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(40 - 4 * k), (uchar)(52 - 4 * k), (uchar)(80 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, w + 2 * k, h + 2 * k, 14 + k);
    }
    cb::round_box(x, y, w, h, 14, cb::rgb(0xf3f3f5), cb::rgb(0xc4c4ca));
    int yy = y + 6;
    for (int i = 0; i < (int)m.size(); i++) {
      const auto& e = m[(size_t)i];
      if (e.sep) {
        fl_color(cb::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + w - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      Fl_Color col = e.enabled || !e.sub.empty() ? cb::rgb(0x1d1d1f) : cb::rgb(0x8e8e93);
      if (i == hi) {
        fl_color(cb::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, w - 12, rowh, 8);
        col = FL_WHITE;
        if (hi_y) *hi_y = yy;
      }
      int tx0 = x + 22;
      if (e.dot >= 0) {
        Fl_Color dc = e.dot == cb::B_OK || e.dot == cb::B_SKIPPED ? cb::rgb(0x22c55e)
                      : e.dot == cb::B_ERROR                     ? cb::rgb(0xf59e0b)
                      : e.dot == cb::B_IDLE                      ? cb::rgb(0x9ca3af)
                                                                 : cb::rgb(0x3b82f6);
        fl_color(dc);
        fl_pie(x + 24, yy + rowh / 2 - 7, 14, 14, 0, 360);
        tx0 = x + 50;
      }
      fl_font(FL_HELVETICA, 16);
      fl_color(col);
      fl_draw(e.title.c_str(), tx0, yy + 23);
      if (!e.sub.empty()) {
        fl_font(FL_HELVETICA, 20);
        fl_draw("›", x + w - 24, yy + 24);
      }
      yy += rowh;
    }
    return x + w;
  }
  void desk(const std::string& file, int open_inst, int sub_hi) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(20 + 60 * t), (uchar)(60 + 70 * t), (uchar)(90 + 60 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(cb::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(cb::rgb(0x1d1d1f));
    fl_draw("03:12", W - 70, 26);
    // El icono: un disco con una nube.
    int ix = W - 640;
    fl_color(cb::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 8, 5, 40, BarH - 10, 8);
    fl_color(cb::rgb(0x1d1d1f));
    fl_line_style(FL_SOLID, 2);
    fl_rounded_rect(ix, 17, 24, 12, 3);
    fl_arc(ix + 6, 7, 12, 10, 0, 180);
    fl_line_style(0);
    long long now = cb::now_t();
    auto m = cb::bar_menu(insts, running, cb::imin(run_done + 1, run_total), run_total, st.next_run, st.last_run, now);
    int item = -1;
    for (int i = 0, k = 0; i < (int)m.size(); i++)
      if (m[(size_t)i].dot >= 0 && k++ == open_inst) item = i;
    int hy = 0;
    int right = draw_menu(ix - 12, BarH + 4, m, open_inst >= 0 ? item : -1, &hy);
    if (open_inst >= 0 && item >= 0) draw_menu(right + 2, hy - 6, m[(size_t)item].sub, sub_hi, nullptr);
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1600, 1000);
    render_to(dir + "/window.png");
    desk(dir + "/menu.png", -1, -1);
    // Respaldando: una creándose en el panel, otra bajándose y otra en cola.
    running = true;
    run_total = 4;
    run_done = 1;
    insts[1].state = cb::B_DOWNLOADING;
    insts[1].total = insts[1].cloud_size;
    insts[1].got = insts[1].cloud_size * 46 / 100;
    insts[2].state = cb::B_CREATING;
    insts[4].state = cb::B_QUEUED;
    refresh();
    render_to(dir + "/running.png");
    desk(dir + "/menu-running.png", 1, 0);
    // La secuencia: cada semana, el domingo a las 22:00.
    running = false;
    insts = cb::demo_insts(cb::now_t());
    insts[4].state = cb::B_ERROR;
    insts[4].error = tx::E_READONLY;
    Every->index(cb::EVERY_N - 1);
    At->index(22);
    Day->index(6);
    schedule_changed();
    message.clear();
    refresh();
    render_to(dir + "/schedule.png");
    // Los servidores SSH: el de la oficina, con la prueba de conexión.
    sv_build();
    sv_fill();
    sv_load(0);
    sw.note->labelcolor(cb::rgb(0x15803d));
    sw.note->copy_label(cb::fmt(tx::SV_TEST_OK, {"2", "erp_produccion, nominas"}).c_str());
    {
      Fl_Window* w = sw.win;
      Fl_Image_Surface surf(w->w(), w->h(), 0);
      Fl_Surface_Device::push_current(&surf);
      fl_color(w->color());
      fl_rectf(0, 0, w->w(), w->h());
      for (int i = 0; i < w->children(); i++) {
        Fl_Widget* c = w->child(i);
        if (c->visible()) surf.draw(c, c->x(), c->y());
      }
      Fl_RGB_Image* img = surf.image();
      Fl_Surface_Device::pop_current();
      fl_write_png((dir + "/servers.png").c_str(), img);
      delete img;
    }
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1100, 720);
    int f = 0;
    auto chk = [&](bool ok, const char* what) {
      if (!ok) {
        std::printf("FAIL %s\n", what);
        f++;
      }
    };
    // la secuencia
    Every->index(0);
    Every_select();
    chk(st.every == 1 && !At->active() && !Day->active(), "cada hora");
    struct tm nh = cb::local(st.next_run);
    chk(nh.tm_min == 0 && st.next_run > cb::now_t() && st.next_run <= cb::now_t() + 3600, "la próxima, dentro de una hora");
    Every->index(5);
    At->index(5);
    Every_select();
    chk(st.every == 12 && st.hour == 5 && At->active() && !Day->active(), "cada 12 horas");
    struct tm nx = cb::local(st.next_run);
    chk(nx.tm_min == 0 && (nx.tm_hour == 5 || nx.tm_hour == 17) && st.next_run > cb::now_t(), "la próxima, cada 12 horas");
    Every->index(cb::EVERY_N - 1);
    Every_select();
    Day->index(4);
    Day_select();
    nx = cb::local(st.next_run);
    chk(Day->active() && (nx.tm_wday + 6) % 7 == 4 && nx.tm_hour == 5, "cada semana el viernes");
    // la carpeta
    Folder->value("  /tmp/mis respaldos/  ");
    Folder_enter();
    chk(st.folder == "/tmp/mis respaldos", "carpeta");
    Folder->value("");
    Folder_enter();
    chk(st.folder == "/tmp/mis respaldos" && message == tx::NEED_FOLDER, "carpeta vacía");
    // conservar y opciones
    Keep->index(cb::DAYS_N - 1);
    Keep_select();
    chk(st.days == 0, "no borrar nunca");
    Fresh->checked(false);
    Fresh_click();
    chk(!st.fresh && !Filestore->active(), "sin respaldo nuevo, sin adjuntos");
    Fresh->checked(true);
    Fresh_click();
    chk(st.fresh && Filestore->active(), "con respaldo nuevo");
    Login->checked(true);
    Login_click();
    chk(st.login && message == tx::LOGIN_ON, "al iniciar sesión");
    // la dirección y el token
    PanelUrl->value("no vale");
    BtnConnect_click();
    chk(message == tx::BAD_URL, "dirección mala");
    PanelUrl->value("communitysh.xyz/");
    Token->value("");
    auto servers = st.servers;
    st.servers.clear();
    BtnConnect_click();
    chk(st.base == "https://communitysh.xyz" && message == tx::NEED_TOKEN, "falta el token (sin servidores)");
    st.servers = servers;
    token.clear();
    BtnConnect_click();
    chk(connecting && pending == 1 && message == tx::CONNECTING, "sin token, solo los servidores");
    pending = 0;
    connecting = false;
    Token->value("csh_nuevo");
    BtnConnect_click();
    chk(token == "csh_nuevo" && connecting && pending == 2 && message == tx::CONNECTING, "conectar el panel y los servidores");
    pending = 0;
    connecting = false;
    // marcar y respaldar
    render_to("");
    chk(view->hits.size() >= 15, "dibujado");
    bool on3 = insts[3].on;
    for (const auto& h : view->hits)
      if (h.act == 0 && h.idx == 3) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h / 2;
        view->handle(FL_PUSH);
        break;
      }
    chk(insts[3].on != on3, "marcar con el ratón");
    int i_get = view->hit_at(-1, -1);
    chk(i_get < 0, "fuera de todo");
    for (const auto& h : view->hits)
      if (h.act == 1 && h.idx == 1) {
        int k = view->hit_at(h.x + h.w / 2, h.y + h.h / 2);
        chk(k >= 0 && view->hits[(size_t)k].act == 1, "clic en Bajar");
      }
    for (auto& in : insts) in.on = false;
    BtnRun_click();
    chk(!running && message == tx::NONE_SELECTED, "ninguna marcada");
    insts[0].on = insts[2].on = true;
    long long before = st.next_run;
    st.next_run = 1;
    BtnRun_click();
    chk(running && run_total == 2 && insts[0].state == cb::B_QUEUED && insts[1].state != cb::B_QUEUED, "respaldar las marcadas");
    chk(st.next_run > cb::now_t() && before > 0, "la próxima, después de respaldar");
    BtnRun_click();
    chk(message == tx::ALREADY_RUNNING_JOB, "uno a la vez");
    // lo que cuenta el hilo
    cb::Ev e;
    e.kind = cb::EV_STATE;
    e.id = insts[0].id;
    e.state = cb::B_DOWNLOADING;
    e.part = "/nada/a.part";
    e.total = 100;
    apply(e);
    chk(insts[0].state == cb::B_DOWNLOADING && insts[0].total == 100, "bajando");
    render_to("");
    e = cb::Ev();
    e.kind = cb::EV_LOCAL;
    e.id = insts[0].id;
    e.state = cb::B_OK;
    e.file = "/nada/a.zip";
    e.size = 100;
    apply(e);
    e = cb::Ev();
    e.kind = cb::EV_STATE;
    e.id = insts[2].id;
    e.state = cb::B_ERROR;
    e.error = "x";
    apply(e);
    e = cb::Ev();
    e.kind = cb::EV_DONE;
    apply(e);
    chk(!running && run_ok == 1 && run_bad == 1 && insts[0].local_file == "/nada/a.zip" && got.size() == 1, "terminado");
    chk(message == cb::fmt(tx::NOTIFY_ERRORS_FIRST, {"1", "1", "crm-ventas: x"}), "el resumen, con el que falló");
    chk(log_mem.size() >= 4 && log_mem.back() == cb::fmt(tx::LOG_END, {"1", "1"}) && log_mem[log_mem.size() - 2] == cb::fmt(tx::LOG_ERR, {"crm-ventas", "x"}),
        "el historial");
    e = cb::Ev();
    e.kind = cb::EV_INSTANCES;
    e.list = {insts[2]};
    e.list[0].on = true;
    apply(e);
    chk(insts.size() == 3 && insts[0].on && insts[0].state == cb::B_ERROR && insts[1].src == 1 && insts[2].src == 1, "instancias nuevas del panel (las bases se quedan)");
    // el menú del icono, de la barra
    bar_act(cb::tag(cb::A_GET, 0));
    chk(running && run_total == 1, "bajar desde el menú");
    // lo guardado
    cb::Settings s2;
    std::vector<cb::Inst> i2;
    cb::parse_settings(cb::serialize(st, insts), s2, i2);
    chk(s2.folder == st.folder && s2.every == cb::WEEK_H && s2.wday == 4 && s2.days == 0 && s2.login && i2.size() == 3 && s2.servers.size() == 1, "guardado");
    // los servidores SSH: añadir, validar, probar y quitar
    running = false;
    sv_build();
    sv_load(-1);
    sw.host->value("");
    sv_save();
    chk(st.servers.size() == 1 && std::string(sw.note->label()) == tx::SV_ERR_HOST, "servidor sin dirección");
    sw.host->value("10.1.2.3");
    sw.port->value("70000");
    sv_save();
    chk(std::string(sw.note->label()) == tx::SV_ERR_PORT, "puerto malo");
    sw.port->value("2222");
    sw.user->value("deploy");
    sw.auth->value(1);
    sv_auth_changed();
    chk(sw.pass->visible() && !sw.key->visible(), "con contraseña, el campo de la contraseña");
    sv_save();
    chk(std::string(sw.note->label()) == tx::SV_ERR_PASS, "falta la contraseña");
    sw.pass->value("secreta");
    sw.name->value("");
    sv_save();
    chk(st.servers.size() == 2 && st.servers[1].name == "10.1.2.3" && st.servers[1].id == 2 && st.servers[1].password && st.servers[1].port == 2222 &&
            st.servers[1].secret.empty() && sw.list->size() == 2, "servidor guardado (la contraseña, aparte)");
    cb::Ev t;
    t.kind = cb::EV_TEST;
    t.list = cb::parse_db_list("ventas|10\ncompras|20\n", st.servers[1]);
    apply(t);
    chk(std::string(sw.note->label()) == cb::fmt(tx::SV_TEST_OK, {"2", "ventas, compras"}), "probar la conexión");
    cb::Ev l;
    l.kind = cb::EV_INSTANCES;
    l.src = 2;
    l.list = t.list;
    apply(l);
    chk(insts.size() == 5 && insts[3].src == 2 && insts[3].rel == std::string("10.1.2.3") + cb::SEP + "ventas" && insts[3].version == "10.1.2.3",
        "las bases del servidor nuevo");
    for (auto& in : insts) in.on = in.src == 2;
    BtnRun_click();
    chk(running && run_total == 2 && run_ids.size() == 2, "respaldar las bases del servidor");
    running = false;
    sv_load(1);
    sv_delete();
    chk(st.servers.size() == 1 && insts.size() == 3 && sw.list->size() == 1, "quitar el servidor (y sus bases)");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
