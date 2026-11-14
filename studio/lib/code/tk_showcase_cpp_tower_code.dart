part of 'tk_examples.dart';

// El código en C++ de la Torre de control (tk_showcase_cpp_tower.dart): va
// tal cual en Form1.cpp, después de los textos (namespace tx).
const _towerIncludes = r'''#include <algorithm>
#include <atomic>
#include <cctype>
#include <cerrno>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>
#include <sys/stat.h>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shellapi.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <signal.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _towerCode = r'''
// ============================================================ lo básico
// La torre de control de Claude Code: todas las sesiones abiertas en este
// equipo (en VS Code, en la terminal o en otros editores) con lo que hace
// cada una ahora mismo. Claude Code lo deja todo en su carpeta (~/.claude):
//  • sessions/<pid>.json: una por sesión abierta, con su carpeta y si está
//    ocupada («busy») o esperando («idle»).
//  • projects/<carpeta>/<sesión>.jsonl: la conversación, una línea por
//    mensaje (las órdenes, lo que dice, las herramientas, los tokens…).
//  • projects/<carpeta>/<sesión>/subagents/agent-<id>.jsonl: los subagentes.
// Además, los agentes pueden informar de su avance (hechas y pendientes) con
// un POST a un servidor local, como en la torre de control web.
namespace ct {

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
double now_t() {
  using namespace std::chrono;
  return duration<double>(system_clock::now().time_since_epoch()).count();
}
// En una línea, sin espacios de más y, si pasa de [max] bytes, cortado en
// un carácter entero con «…».
std::string one_line(const std::string& s, size_t max = 400) {
  std::string o;
  bool sp = false;
  for (char c : s) {
    if (c == '\n' || c == '\r' || c == '\t' || c == ' ') {
      sp = !o.empty();
      continue;
    }
    if (sp) o += ' ';
    sp = false;
    o += c;
    if (o.size() >= max) break;
  }
  if (o.size() >= max) {
    while (!o.empty() && ((unsigned char)o.back() & 0xc0) == 0x80) o.pop_back();
    if (!o.empty() && ((unsigned char)o.back() & 0x80)) o.pop_back();
    o += "…";
  }
  return o;
}
// Sin las marcas de Markdown más comunes (**negrita**, `código`, # títulos).
std::string plain(const std::string& s) {
  std::string o;
  bool line_start = true;
  for (size_t i = 0; i < s.size(); i++) {
    char c = s[i];
    if (line_start && (c == '#' || c == '>')) {
      while (i < s.size() && (s[i] == '#' || s[i] == '>' || s[i] == ' ')) i++;
      i--;
      line_start = false;
      continue;
    }
    line_start = c == '\n';
    if (c == '`') continue;
    if ((c == '*' || c == '_') && i + 1 < s.size() && s[i + 1] == c) {
      i++;
      continue;
    }
    o += c;
  }
  return o;
}
std::string base_name(std::string p) {
  while (p.size() > 1 && (p.back() == '/' || p.back() == '\\')) p.pop_back();
  size_t s = p.find_last_of("/\\");
  return s == std::string::npos ? p : p.substr(s + 1);
}
// Sin acentos ni mayúsculas, para buscar.
std::string fold(const std::string& s) {
  static const char* from[] = {"á", "é", "í", "ó", "ú", "ü", "ñ", "Á", "É", "Í", "Ó", "Ú", "Ü", "Ñ"};
  static const char* to = "aeiouunaeiouun";
  std::string o;
  for (size_t i = 0; i < s.size();) {
    bool hit = false;
    for (int k = 0; k < 14; k++) {
      size_t n = std::strlen(from[k]);
      if (s.compare(i, n, from[k]) == 0) {
        o += to[k];
        i += n;
        hit = true;
        break;
      }
    }
    if (!hit) o += (char)std::tolower((unsigned char)s[i++]);
  }
  return o;
}

// ------------------------------------------------------------ números
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, std::fabs(v));
  std::string s = b, ip = s, fr;
  size_t dot = s.find('.');
  if (dot != std::string::npos) { ip = s.substr(0, dot); fr = s.substr(dot + 1); }
  std::string out;
  if (v < 0 && s.find_first_of("123456789") != std::string::npos) out = "-";
  int n = (int)ip.size();
  for (int i = 0; i < n; i++) {
    out += ip[(size_t)i];
    int left = n - 1 - i;
    if (left > 0 && left % 3 == 0) out += tx::THOUSANDS;
  }
  if (!fr.empty()) out += std::string(tx::DEC) + fr;
  return out;
}
std::string money(double usd) { return fmt(tx::MONEY, {num(usd, std::fabs(usd) >= 1000 ? 0 : 2)}); }
std::string tokens(double n) {
  if (n < 1000) return num(n, 0);
  if (n < 1e6) return fmt(tx::TOK_K, {num(n / 1e3, n < 1e4 ? 1 : 0)});
  if (n < 1e9) return fmt(tx::TOK_M, {num(n / 1e6, n < 1e7 ? 1 : 0)});
  return fmt(tx::TOK_B, {num(n / 1e9, 1)});
}
// «4:21» o «1:02:03».
std::string dur(double secs) {
  long long s = (long long)std::max(0.0, secs);
  char b[32];
  if (s >= 3600) std::snprintf(b, sizeof b, "%lld:%02lld:%02lld", s / 3600, s / 60 % 60, s % 60);
  else std::snprintf(b, sizeof b, "%lld:%02lld", s / 60, s % 60);
  return b;
}
// «ahora», «hace 40 s», «hace 3 min», «hace 2 h», «hace 4 días».
std::string ago(double secs) {
  if (secs < 10) return tx::JUST_NOW;
  if (secs < 60) return fmt(tx::AGO_S, {num(secs, 0)});
  if (secs < 3600) return fmt(tx::AGO_M, {num(std::floor(secs / 60), 0)});
  if (secs < 86400 * 2) return fmt(tx::AGO_H, {num(std::floor(secs / 3600), 0)});
  return fmt(tx::AGO_D, {num(std::floor(secs / 86400), 0)});
}
// Corto, para la columna de la derecha: «40 s», «3 min», «2 h», «4 d».
std::string short_ago(double secs) {
  if (secs < 60) return fmt(tx::SHORT_S, {num(std::max(0.0, secs), 0)});
  if (secs < 3600) return fmt(tx::SHORT_M, {num(std::floor(secs / 60), 0)});
  if (secs < 86400 * 2) return fmt(tx::SHORT_H, {num(std::floor(secs / 3600), 0)});
  return fmt(tx::SHORT_D, {num(std::floor(secs / 86400), 0)});
}

// ------------------------------------------------------------ fechas
// «2026-11-14T20:42:01.123Z» → segundos desde 1970 (UTC).
double iso_time(const std::string& s) {
  int Y = 0, M = 0, D = 0, h = 0, m = 0, sec = 0;
  if (std::sscanf(s.c_str(), "%d-%d-%dT%d:%d:%d", &Y, &M, &D, &h, &m, &sec) != 6) return 0;
  double frac = 0;
  size_t dot = s.find('.', 17);
  if (dot != std::string::npos && dot < 22) {
    double f = 0.1;
    for (size_t i = dot + 1; i < s.size() && std::isdigit((unsigned char)s[i]); i++, f /= 10) frac += (s[i] - '0') * f;
  }
  Y -= M <= 2;
  long long era = (Y >= 0 ? Y : Y - 399) / 400;
  unsigned yoe = (unsigned)(Y - era * 400);
  unsigned doy = (unsigned)((153 * (M + (M > 2 ? -3 : 9)) + 2) / 5 + D - 1);
  unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  long long days = era * 146097 + (long long)doe - 719468;
  return (double)days * 86400.0 + h * 3600 + m * 60 + sec + frac;
}
std::string clock_hm(double t) {
  time_t tt = (time_t)t;
  struct tm lt;
#ifdef _WIN32
  localtime_s(&lt, &tt);
#else
  localtime_r(&tt, &lt);
#endif
  char b[16];
  std::snprintf(b, sizeof b, "%02d:%02d", lt.tm_hour, lt.tm_min);
  return b;
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
  if (const char* o = fl_getenv("DMS_TOWER_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\tower";
#elif defined(__APPLE__)
  return home() + "/Library/Application Support/DMarlon Studio Demos/tower";
#else
  return home() + "/.config/DMarlon Studio Demos/tower";
#endif
}
// «/Users/ana/.claude» → «~/.claude».
std::string tilde(const std::string& p) {
  std::string h = home();
  return h.size() > 1 && starts(p, h) ? "~" + p.substr(h.size()) : p;
}
// La carpeta de Claude Code (CLAUDE_CONFIG_DIR, si la cambió).
std::string claude_dir() {
  if (const char* o = fl_getenv("DMS_TOWER_CLAUDE")) return o;
  if (const char* c = fl_getenv("CLAUDE_CONFIG_DIR")) {
    std::string first = trim(split(c, ',')[0]);
    if (!first.empty()) return first;
  }
  return home() + "/.claude";
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
bool write_file(const std::string& path, const std::string& data) {
  std::string tmp = path + ".tmp";
  FILE* f = fl_fopen(tmp.c_str(), "wb");
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  ok = std::fclose(f) == 0 && ok;
  if (ok) {
    std::remove(path.c_str());
    ok = std::rename(tmp.c_str(), path.c_str()) == 0;
  }
  return ok;
}
bool append_file(const std::string& path, const std::string& data) {
  FILE* f = fl_fopen(path.c_str(), "ab");
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  return std::fclose(f) == 0 && ok;
}
struct FileInfo {
  long long size = -1;
  double mtime = 0;
  bool dir = false;
};
FileInfo stat_of(const std::string& path) {
  FileInfo fi;
  struct stat st;
  if (fl_stat(path.c_str(), &st) != 0) return fi;
  fi.size = (long long)st.st_size;
  fi.mtime = (double)st.st_mtime;
  fi.dir = (st.st_mode & S_IFMT) == S_IFDIR;
  return fi;
}
std::vector<std::string> list_dir(const std::string& dir) {
  std::vector<std::string> out;
  dirent** list = nullptr;
  int n = fl_filename_list(dir.c_str(), &list, fl_alphasort);
  for (int i = 0; i < n; i++) {
    std::string nm = list[i]->d_name;
    if (!nm.empty() && (nm.back() == '/' || nm.back() == '\\')) nm.pop_back();
    if (nm != "." && nm != ".." && !nm.empty()) out.push_back(nm);
  }
  if (n > 0) fl_filename_free_list(&list, n);
  return out;
}
// El nombre de la carpeta de un proyecto en ~/.claude/projects: la ruta con
// todo lo que no es letra o número cambiado por «-».
std::string slug(const std::string& cwd) {
  std::string o;
  for (char c : cwd) o += std::isalnum((unsigned char)c) ? c : '-';
  return o;
}
bool pid_alive(int pid) {
  if (pid <= 0) return false;
#ifdef _WIN32
  HANDLE h = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION, FALSE, (DWORD)pid);
  if (!h) return false;
  DWORD r = WaitForSingleObject(h, 0);
  CloseHandle(h);
  return r == WAIT_TIMEOUT;
#else
  return kill(pid, 0) == 0 || errno == EPERM;
#endif
}
int my_pid() {
#ifdef _WIN32
  return (int)GetCurrentProcessId();
#else
  return (int)getpid();
#endif
}

// ------------------------------------------------------------ JSON
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
  bool has(const std::string& k) const {
    for (const auto& p : o)
      if (p.first == k) return true;
    return false;
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
      if (c >= '0' && c <= '9') v |= (uint32_t)(c - '0');
      else if (c >= 'a' && c <= 'f') v |= (uint32_t)(c - 'a' + 10);
      else if (c >= 'A' && c <= 'F') v |= (uint32_t)(c - 'A' + 10);
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
          utf8(o, c1 >= 0xd800 && c1 < 0xe000 ? 0xfffd : c1);
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
std::string jq(const std::string& s) {
  std::string o = "\"";
  for (unsigned char c : s) {
    if (c == '"') o += "\\\"";
    else if (c == '\\') o += "\\\\";
    else if (c == '\n') o += "\\n";
    else if (c == '\r') o += "\\r";
    else if (c == '\t') o += "\\t";
    else if (c < 0x20) {
      char b[8];
      std::snprintf(b, sizeof b, "\\u%04x", c);
      o += b;
    } else o += (char)c;
  }
  return o + "\"";
}

// ------------------------------------------------------------ precios
// Dólares por millón de tokens (entrada, escritura en la caché, lectura de
// la caché, salida), para estimar lo que costaría cada sesión con la API.
struct Price {
  double in, cw, cr, out;
};
Price price_of(const std::string& model) {
  std::string m = lower(model);
  if (has(m, "fable")) return {8, 10, 0.2, 40};
  if (has(m, "opus-5-5") || has(m, "opus-5.5")) return {4, 5, 0.2, 20};
  if (has(m, "opus")) return {5, 6.25, 0.5, 25};
  if (has(m, "sonnet-5")) return {2, 2.5, 0.1, 10};
  if (has(m, "sonnet")) return {3, 3.75, 0.3, 15};
  if (has(m, "haiku-5")) return {0.1, 0.125, 0.01, 0.5};
  if (has(m, "haiku")) return {1, 1.25, 0.1, 5};
  return {3, 3.75, 0.3, 15};
}
// «claude-opus-5-5» → «Opus 5.5».
std::string model_name(const std::string& id) {
  std::string m = lower(id);
  for (const char* fam : {"fable", "opus", "sonnet", "haiku"}) {
    size_t p = m.find(fam);
    if (p == std::string::npos) continue;
    std::string name = fam;
    name[0] = (char)std::toupper((unsigned char)name[0]);
    std::string rest = m.substr(p + std::strlen(fam));
    std::string ver;
    for (size_t i = 0; i < rest.size(); i++) {
      char c = rest[i];
      if (std::isdigit((unsigned char)c)) {
        // Un número de 8 cifras es una fecha, no la versión.
        size_t j = i;
        while (j < rest.size() && std::isdigit((unsigned char)rest[j])) j++;
        if (j - i >= 8) break;
        ver += rest.substr(i, j - i);
        i = j - 1;
      } else if ((c == '-' || c == '.') && !ver.empty() && i + 1 < rest.size() && std::isdigit((unsigned char)rest[i + 1])) {
        size_t j = i + 1;
        while (j < rest.size() && std::isdigit((unsigned char)rest[j])) j++;
        if (j - i - 1 >= 8) break;
        ver += ".";
      } else if (!ver.empty()) break;
    }
    return ver.empty() ? name : name + " " + ver;
  }
  return id;
}
// La ventana de contexto: 1 M si el modelo lo dice o si ya pasó de 200 k.
double context_window(const std::string& model, double used) {
  if (has(lower(model), "[1m]") || used > 200000) return 1000000;
  return 200000;
}

// ============================================================ las sesiones
enum State { ST_WORK, ST_ASK, ST_WAIT, ST_IDLE, ST_CLOSED, ST_ERROR, ST_DONE, ST_BLOCKED };
// Un paso: una herramienta que ha usado (Bash, Edit, Read…).
struct Step {
  std::string id, name, what;
  double t = 0, end = 0;
  int st = 0;   // 0 en marcha, 1 bien, 2 con error
  bool raw = false;   // [what] es la orden tal cual (sin la descripción)
};
struct Sub {
  std::string tool, id, desc, kind, now;
  double t = 0, last = 0;
  bool async = false, finished = false, running = false;
  int steps = 0;
};
struct Task {
  std::string id, text;
  int st = 0;   // 0 pendiente, 1 en marcha, 2 hecha
};
struct Session {
  std::string id, file, cwd, title, name, branch, model, entry, version, prompt, said, url, status, ask, error;
  int pid = 0;
  bool open = false, api_error = false;
  double first = 0, last = 0, turn = 0, ended = 0, status_t = 0, mtime = 0;
  int prompts = 0, calls = 0, errors = 0;
  double in = 0, out = 0, cr = 0, cw = 0, cost = 0, ctx = 0;
  std::vector<Step> steps;   // las últimas
  std::vector<std::pair<std::string, int>> files;   // los archivos que ha tocado
  std::vector<Sub> subs;
  std::vector<Task> tasks;
  std::vector<double> ticks;   // cuándo usó cada herramienta (la última hora)
  int state = ST_CLOSED;
  const Step* pending() const {
    for (auto it = steps.rbegin(); it != steps.rend(); ++it)
      if (it->st == 0 && it->name != "Agent" && it->name != "Task") return &*it;
    return nullptr;
  }
  int running_subs() const {
    int n = 0;
    for (const auto& s : subs) n += s.running;
    return n;
  }
};

// Lo que se describe de cada herramienta: «Compila la demo», «Form1.cpp»…
std::string describe(const std::string& name, const Json& in) {
  if (name == "Bash" || name == "PowerShell") {
    std::string d = in["description"].str();
    return one_line(d.empty() ? in["command"].str() : d, 160);
  }
  for (const char* k : {"file_path", "notebook_path", "path"})
    if (in.has(k) && name != "Grep" && name != "Glob") return base_name(in[k].str());
  if (name == "Grep" || name == "Glob") return one_line(in["pattern"].str(), 120);
  if (name == "WebFetch") return one_line(in["url"].str(), 160);
  if (name == "WebSearch") return one_line(in["query"].str(), 160);
  if (name == "Agent" || name == "Task") return one_line(in["description"].str(), 160);
  if (name == "Skill") return one_line(in["skill"].str(), 80);
  if (name == "AskUserQuestion") return one_line(in["questions"][0]["question"].str(), 200);
  if (name == "TodoWrite") return fmt(tx::N_TASKS, {num((double)in["todos"].a.size(), 0)});
  if (in.has("description")) return one_line(in["description"].str(), 160);
  return "";
}
// «Ejecuta: make», «Edita Form1.cpp», «Busca …». La descripción de una
// orden («Pasa las pruebas») ya dice lo que hace: va tal cual.
std::string doing(const std::string& name, const std::string& what, bool raw = true) {
  const char* f = tx::DO_OTHER;
  if ((name == "Bash" || name == "PowerShell") && !raw && !what.empty()) return what;
  if (name == "Bash" || name == "PowerShell") f = tx::DO_BASH;
  else if (name == "Read") f = tx::DO_READ;
  else if (name == "Edit" || name == "MultiEdit" || name == "NotebookEdit") f = tx::DO_EDIT;
  else if (name == "Write") f = tx::DO_WRITE;
  else if (name == "Grep" || name == "Glob") f = tx::DO_SEARCH;
  else if (name == "WebFetch") f = tx::DO_FETCH;
  else if (name == "WebSearch") f = tx::DO_WEB;
  else if (name == "Agent" || name == "Task") f = tx::DO_AGENT;
  else if (name == "AskUserQuestion") f = tx::DO_ASK;
  else if (name == "TodoWrite") f = tx::DO_TODO;
  if (f == tx::DO_OTHER) return what.empty() ? name : fmt(f, {what, name});
  return trim(fmt(f, {what}));
}
// Una dirección local en una orden (localhost:3000, --port 5173,
// --http-port=8069, PORT=3000…): dónde se prueba la app.
std::string local_url(const std::string& s) {
  size_t best = std::string::npos;
  std::string port;
  for (const char* key : {"localhost:", "127.0.0.1:", "0.0.0.0:", "--port ", "--port=", "--http-port ", "--http-port=", "PORT="}) {
    size_t k = std::strlen(key);
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + 1)) {
      size_t q = p + k, e = q;
      while (e < s.size() && std::isdigit((unsigned char)s[e])) e++;
      if (e == q || e - q > 5) continue;
      int n = std::atoi(s.substr(q, e - q).c_str());
      if (n < 80 || n > 65535) continue;
      if (best == std::string::npos || p > best) {
        best = p;
        port = s.substr(q, e - q);
      }
    }
  }
  return port.empty() ? "" : "http://localhost:" + port;
}

// La lectura de un .jsonl, poco a poco: se guarda hasta dónde se leyó.
struct Parse {
  long long off = 0;
  std::string rest;
  Session s;
  std::unordered_map<std::string, size_t> step_of;   // id de la herramienta → paso
  std::unordered_set<std::string> msgs;   // los mensajes ya contados (tokens)
  long long steps_total = 0;
  bool seen = false;
};
const size_t MAX_STEPS = 80;
void add_file(Session& s, const std::string& path) {
  if (path.empty()) return;
  for (size_t i = 0; i < s.files.size(); i++)
    if (s.files[i].first == path) {
      auto f = s.files[i];
      f.second++;
      s.files.erase(s.files.begin() + (long)i);
      s.files.push_back(f);
      return;
    }
  s.files.push_back({path, 1});
  if (s.files.size() > 40) s.files.erase(s.files.begin());
}
Sub* sub_by_tool(Session& s, const std::string& tool) {
  for (auto& x : s.subs)
    if (x.tool == tool) return &x;
  return nullptr;
}
// El texto de una orden del usuario (o "" si no es una orden: avisos,
// salidas de órdenes, resultados de herramientas…).
std::string prompt_text(const Json& content) {
  std::string t;
  if (content.t == Json::STR) t = content.s;
  else if (content.t == Json::ARR)
    for (const auto& b : content.a) {
      if (b["type"].str() == "text") t += (t.empty() ? "" : " ") + b["text"].str();
      else if (b["type"].str() == "tool_result") return "";
    }
  t = trim(t);
  if (t.empty() || t[0] == '<' || starts(t, "[Request interrupted") || starts(t, "Caveat:")) return "";
  return t;
}
void parse_line(const std::string& line, Parse& p) {
  Session& s = p.s;
  Json j;
  if (!parse_json(line, j) || j.t != Json::OBJ) return;
  std::string type = j["type"].str();
  double t = iso_time(j["timestamp"].str());
  if (t > 0) {
    if (s.first == 0 || t < s.first) s.first = t;
    s.last = std::max(s.last, t);
  }
  // La carpeta de la sesión es donde empezó (luego el shell puede moverse).
  if (s.cwd.empty() && j.has("cwd")) s.cwd = j["cwd"].str();
  if (j.has("gitBranch")) s.branch = j["gitBranch"].str();
  if (j.has("entrypoint")) s.entry = j["entrypoint"].str();
  if (j.has("version")) s.version = j["version"].str();
  if (type == "ai-title") { s.title = one_line(j["aiTitle"].str(), 160); return; }
  if (type == "custom-title" || j.has("customTitle")) { s.title = one_line(j["customTitle"].str(), 160); return; }
  if (type == "summary" && s.title.empty()) { s.title = one_line(j["summary"].str(), 160); return; }
  if (type == "last-prompt") { s.prompt = one_line(j["lastPrompt"].str(), 600); return; }
  if (type == "user") {
    if (j["isMeta"].truthy()) return;
    const Json& content = j["message"]["content"];
    std::string pt = prompt_text(content);
    if (!pt.empty()) {
      s.prompts++;
      s.turn = t;
      s.prompt = one_line(pt, 600);
      s.api_error = false;
      s.ask.clear();
    }
    std::string text = content.t == Json::STR ? content.s : "";
    if (content.t == Json::ARR)
      for (const auto& b : content.a) {
        std::string bt = b["type"].str();
        if (bt == "text") text += b["text"].str();
        if (bt != "tool_result") continue;
        std::string id = b["tool_use_id"].str();
        auto it = p.step_of.find(id);
        if (it == p.step_of.end() || it->second < (size_t)std::max(0LL, p.steps_total - (long long)s.steps.size())) continue;
        Step& st = s.steps[it->second - (size_t)(p.steps_total - (long long)s.steps.size())];
        st.end = t;
        st.st = b["is_error"].truthy() ? 2 : 1;
        if (st.st == 2) s.errors++;
        if (st.name == "AskUserQuestion" || st.name == "ExitPlanMode") s.ask.clear();
        if (Sub* sb = sub_by_tool(s, id)) {
          const Json& r = j["toolUseResult"];
          if (r.t == Json::OBJ && r["agentId"].t == Json::STR) sb->id = r["agentId"].str();
          if (r.t == Json::OBJ && has(r["status"].str(), "async")) sb->async = true;
          else sb->finished = true;
        }
      }
    const Json& r = j["toolUseResult"];
    if (r.t == Json::OBJ && r["newTodos"].t == Json::ARR) {
      s.tasks.clear();
      for (const auto& td : r["newTodos"].a) {
        std::string st = td["status"].str();
        s.tasks.push_back({"", one_line(td["content"].str(), 200), st == "completed" ? 2 : st == "in_progress" ? 1 : 0});
      }
    }
    // Un subagente en segundo plano que termina avisa con su id.
    if (starts(trim(text), "<task-notification>")) {
      size_t a = text.find("<tool-use-id>"), b = text.find("</tool-use-id>");
      if (a != std::string::npos && b != std::string::npos && b > a)
        if (Sub* sb = sub_by_tool(s, text.substr(a + 13, b - a - 13))) sb->finished = true;
    }
    if (has(text, "[Request interrupted")) {
      s.ended = t;
      for (auto& st : s.steps)
        if (st.st == 0) { st.st = 2; st.end = t; }
      s.ask.clear();
    }
    return;
  }
  if (type != "assistant") return;
  const Json& m = j["message"];
  std::string model = m["model"].str();
  if (!model.empty() && model != "<synthetic>") s.model = model;
  if (j["isApiErrorMessage"].truthy() || j.has("error") ) {
    s.api_error = true;
    for (const auto& b : m["content"].a)
      if (b["type"].str() == "text") s.error = one_line(b["text"].str(), 300);
  } else if (model != "<synthetic>") s.api_error = false;
  // Los tokens, una vez por mensaje (Claude Code escribe un registro por bloque).
  std::string mid = m["id"].str();
  const Json& u = m["usage"];
  if (u.t == Json::OBJ && (mid.empty() || p.msgs.insert(mid).second)) {
    double in = u["input_tokens"].num(), out = u["output_tokens"].num(), cr = u["cache_read_input_tokens"].num(),
           cw = u["cache_creation_input_tokens"].num();
    s.in += in;
    s.out += out;
    s.cr += cr;
    s.cw += cw;
    Price pr = price_of(model.empty() ? s.model : model);
    s.cost += (in * pr.in + cw * pr.cw + cr * pr.cr + out * pr.out) / 1e6;
    if (in + cr + cw > 0) s.ctx = in + cr + cw;
  }
  for (const auto& b : m["content"].a) {
    std::string bt = b["type"].str();
    if (bt == "text") {
      std::string tx0 = trim(b["text"].str());
      if (!tx0.empty()) s.said = one_line(plain(tx0), 600);
      continue;
    }
    if (bt != "tool_use") continue;
    std::string name = b["name"].str(), id = b["id"].str();
    const Json& in = b["input"];
    Step st;
    st.id = id;
    st.name = name;
    st.what = describe(name, in);
    st.raw = (name == "Bash" || name == "PowerShell") && in["description"].str().empty();
    st.t = t;
    s.steps.push_back(st);
    p.step_of[id] = (size_t)p.steps_total++;
    if (s.steps.size() > MAX_STEPS) s.steps.erase(s.steps.begin());
    s.calls++;
    if (t > 0) s.ticks.push_back(t);
    if (s.ticks.size() > 400) s.ticks.erase(s.ticks.begin(), s.ticks.begin() + 100);
    if (name == "Edit" || name == "Write" || name == "MultiEdit" || name == "NotebookEdit")
      add_file(s, in.has("file_path") ? in["file_path"].str() : in["notebook_path"].str());
    if (name == "Bash" || name == "PowerShell" || name == "WebFetch") {
      std::string u2 = local_url(in["command"].str() + " " + in["url"].str());
      if (!u2.empty()) s.url = u2;
    }
    if (name == "AskUserQuestion") s.ask = describe(name, in);
    if (name == "ExitPlanMode") s.ask = tx::PLAN_READY;
    if (name == "TodoWrite" && in["todos"].t == Json::ARR) {
      s.tasks.clear();
      for (const auto& td : in["todos"].a) {
        std::string ts = td["status"].str();
        s.tasks.push_back({"", one_line(td["content"].str(), 200), ts == "completed" ? 2 : ts == "in_progress" ? 1 : 0});
      }
    }
    if (name == "TaskCreate") {
      std::string text = in["subject"].str();
      if (text.empty()) text = in["description"].str();
      s.tasks.push_back({std::to_string(s.tasks.size() + 1), one_line(text, 200), 0});
    }
    if (name == "TaskUpdate") {
      std::string tid = in["taskId"].str(), ts = in["status"].str();
      for (auto& tk : s.tasks)
        if (tk.id == tid && !ts.empty()) tk.st = ts == "completed" ? 2 : ts == "in_progress" ? 1 : 0;
    }
    if (name == "Agent" || name == "Task") {
      Sub sb;
      sb.tool = id;
      sb.desc = one_line(in["description"].str(), 160);
      sb.kind = in["subagent_type"].str();
      sb.t = sb.last = t;
      s.subs.push_back(sb);
      if (s.subs.size() > 30) s.subs.erase(s.subs.begin());
    }
  }
  if (m["stop_reason"].str() == "end_turn") s.ended = t;
}
// Lee lo nuevo de [path]. Si el archivo se ha hecho más pequeño, desde el principio.
void read_new(const std::string& path, Parse& p) {
  FileInfo fi = stat_of(path);
  if (fi.size < 0) return;
  if (fi.size < p.off) {
    Parse fresh;
    fresh.s.id = p.s.id;
    p = std::move(fresh);
  }
  p.s.mtime = fi.mtime;
  if (fi.size == p.off) return;
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return;
#ifdef _WIN32
  _fseeki64(f, p.off, SEEK_SET);
#else
  fseeko(f, (off_t)p.off, SEEK_SET);
#endif
  std::vector<char> buf(1 << 20);
  size_t n;
  while ((n = std::fread(buf.data(), 1, buf.size(), f)) > 0) {
    p.off += (long long)n;
    size_t a = 0;
    for (size_t i = 0; i < n; i++) {
      if (buf[i] != '\n') continue;
      if (p.rest.empty()) {
        if (i - a < (8u << 20)) parse_line(std::string(buf.data() + a, i - a), p);
      } else {
        p.rest.append(buf.data() + a, i - a);
        if (p.rest.size() < (8u << 20)) parse_line(p.rest, p);
        p.rest.clear();
      }
      a = i + 1;
    }
    if (a < n && p.rest.size() < (16u << 20)) p.rest.append(buf.data() + a, n - a);
  }
  std::fclose(f);
}

// El estado de la sesión, con lo que se sabe.
void settle(Session& s, double now) {
  if (!s.open) {
    s.state = ST_CLOSED;
    return;
  }
  const Step* pend = s.pending();
  std::string st = lower(s.status);
  bool waiting_input = has(st, "wait") || has(st, "permission") || has(st, "input") || has(st, "block");
  if (!s.ask.empty() || waiting_input) s.state = ST_ASK;
  else if (s.api_error && st != "busy") s.state = ST_ERROR;
  else if (st == "busy" || (st.empty() && (pend || s.ended < s.turn) && now - s.mtime < 300)) s.state = ST_WORK;
  else if (now - std::max({s.ended, s.last, s.status_t}) > 30 * 60) s.state = ST_IDLE;
  else s.state = ST_WAIT;
  // Al esperar, nada está en marcha (si se interrumpió, quedan pasos sin cerrar).
  if (s.state == ST_WAIT || s.state == ST_IDLE)
    for (auto& x : s.steps)
      if (x.st == 0 && x.name != "Agent" && x.name != "Task") x.st = 1;
}

// Lo que se ve de una sesión y de un agente que informa: una tarjeta.
struct Report {
  std::string agent, role, state, task, url;
  std::vector<std::string> done, todo;
  int progress = -1;
  double t = 0, first = 0;
};

// ------------------------------------------------------------ el lector
// Mira ~/.claude cada pocos segundos (en otro hilo) y devuelve las sesiones.
struct Snapshot {
  std::vector<Session> sessions;
  bool no_claude = false, no_registry = false;
  double t = 0;
  int scanned = 0;
};
class Scanner {
public:
  std::string dir;
  explicit Scanner(std::string d) : dir(std::move(d)) {}
  std::map<std::string, std::unique_ptr<Parse>> files;
  std::map<std::string, std::string> where;   // sesión → archivo
  std::vector<std::string> recent;   // las cerradas de la ventana de tiempo
  double recent_t = 0, recent_window = -1;

  std::string projects() const { return dir + "/projects"; }
  std::string find_file(const std::string& id, const std::string& cwd) {
    auto w = where.find(id);
    if (w != where.end() && stat_of(w->second).size >= 0) return w->second;
    std::string f = projects() + "/" + slug(cwd) + "/" + id + ".jsonl";
    if (stat_of(f).size < 0) {
      f.clear();
      for (const auto& d : list_dir(projects())) {
        std::string g = projects() + "/" + d + "/" + id + ".jsonl";
        if (stat_of(g).size >= 0) { f = g; break; }
      }
    }
    if (!f.empty()) where[id] = f;
    return f;
  }
  Parse& parse_of(const std::string& path, const std::string& id) {
    auto& slot = files[path];
    if (!slot) {
      slot.reset(new Parse());
      slot->s.id = id;
    }
    slot->seen = true;
    read_new(path, *slot);
    return *slot;
  }
  // Los subagentes de la sesión: su último paso y si siguen.
  void subagents(Session& s, double now) {
    if (s.file.empty()) return;
    std::string base = s.file.substr(0, s.file.size() - 6) + "/subagents/";
    for (auto& sb : s.subs) {
      bool recent_file = false;
      if (!sb.id.empty()) {
        std::string f = base + "agent-" + sb.id + ".jsonl";
        FileInfo fi = stat_of(f);
        if (fi.size >= 0) {
          Parse& p = parse_of(f, sb.id);
          const Step* pend = p.s.pending();
          const Step* lastst = p.s.steps.empty() ? nullptr : &p.s.steps.back();
          if (pend) sb.now = doing(pend->name, pend->what, pend->raw);
          else if (lastst) sb.now = doing(lastst->name, lastst->what, lastst->raw);
          sb.steps = p.s.calls;
          sb.last = std::max(sb.last, p.s.last);
          recent_file = now - fi.mtime < 120;
        }
      }
      sb.running = !sb.finished && (!sb.async || recent_file || (now - sb.last < 600 && s.status == "busy"));
      if (!s.open) sb.running = false;
    }
  }
  Session fill(Parse& p, double now) {
    Session s = p.s;
    settle(s, now);
    while (!s.ticks.empty() && s.ticks.front() < now - 3600) s.ticks.erase(s.ticks.begin());
    return s;
  }
  // [window]: segundos hacia atrás para las cerradas (0: solo las abiertas).
  Snapshot scan(double window) {
    Snapshot snap;
    double now = now_t();
    snap.t = now;
    for (auto& f : files) f.second->seen = false;
    if (!stat_of(dir).dir) {
      snap.no_claude = true;
      files.clear();
      return snap;
    }
    std::set<std::string> open_ids;
    std::string reg = dir + "/sessions";
    bool registry = stat_of(reg).dir;
    snap.no_registry = !registry;
    if (registry) {
      for (const auto& name : list_dir(reg)) {
        if (!ends(name, ".json")) continue;
        std::string text;
        Json j;
        if (!read_file(reg + "/" + name, text) || !parse_json(text, j)) continue;
        int pid = (int)j["pid"].num();
        std::string id = j["sessionId"].str();
        if (id.empty() || !pid_alive(pid) || open_ids.count(id)) continue;
        open_ids.insert(id);
        std::string cwd = j["cwd"].str();
        std::string file = find_file(id, cwd);
        Session s;
        if (!file.empty()) {
          Parse& p = parse_of(file, id);
          p.s.open = true;
          p.s.file = file;
          p.s.pid = pid;
          p.s.status = j["status"].str();
          p.s.status_t = j["statusUpdatedAt"].num() / 1000.0;
          p.s.name = j["name"].str();
          if (!cwd.empty()) p.s.cwd = cwd;
          if (p.s.entry.empty()) p.s.entry = j["entrypoint"].str();
          if (p.s.first == 0) p.s.first = j["startedAt"].num() / 1000.0;
          subagents(p.s, now);
          s = fill(p, now);
        } else {
          // Recién abierta: aún no ha escrito nada.
          s.id = id;
          s.open = true;
          s.pid = pid;
          s.cwd = cwd;
          s.status = j["status"].str();
          s.name = j["name"].str();
          s.entry = j["entrypoint"].str();
          s.first = s.last = j["startedAt"].num() / 1000.0;
          settle(s, now);
        }
        snap.sessions.push_back(std::move(s));
      }
    }
    // Las cerradas (y, sin el registro de sesiones, las que se movieron hace poco).
    double win = registry ? window : std::max(window, 600.0);
    if (win > 0) {
      if (win != recent_window || now - recent_t > 10) {
        recent.clear();
        for (const auto& d : list_dir(projects())) {
          std::string pd = projects() + "/" + d;
          for (const auto& f : list_dir(pd)) {
            if (!ends(f, ".jsonl") || starts(f, "agent-")) continue;
            FileInfo fi = stat_of(pd + "/" + f);
            if (fi.size > 0 && !fi.dir && now - fi.mtime <= win) recent.push_back(pd + "/" + f);
          }
        }
        recent_t = now;
        recent_window = win;
      }
      for (const auto& f : recent) {
        std::string id = base_name(f);
        id = id.substr(0, id.size() - 6);
        if (open_ids.count(id)) continue;
        Parse& p = parse_of(f, id);
        p.s.file = f;
        p.s.open = !registry && now - p.s.mtime < 600;
        p.s.status.clear();
        if (!p.s.open && now - p.s.mtime > win) continue;
        if (p.s.prompts == 0 && p.s.calls == 0) continue;   // sin conversación
        subagents(p.s, now);
        snap.sessions.push_back(fill(p, now));
      }
    }
    // Lo que ya no se ve, fuera de la memoria (los subagentes, con su sesión).
    for (auto it = files.begin(); it != files.end();) {
      if (!it->second->seen && !has(it->first, "/subagents/")) it = files.erase(it);
      else ++it;
    }
    snap.scanned = (int)files.size();
    return snap;
  }
};

// ------------------------------------------------------------ los informes
// Un agente puede contar su avance con un POST (el mismo JSON que la torre
// de control web): agente, rol, estado, tarea, url o puerto, hechas,
// pendientes y progreso. Se aceptan también las claves en inglés.
int report_state(const std::string& s0) {
  std::string s = fold(s0);
  if (has(s, "trabaj") || has(s, "work") || has(s, "run") || has(s, "progres")) return ST_WORK;
  if (has(s, "esper") || has(s, "wait") || has(s, "idle")) return ST_WAIT;
  if (has(s, "bloque") || has(s, "block")) return ST_BLOCKED;
  if (has(s, "termin") || has(s, "hech") || has(s, "done") || has(s, "finish") || has(s, "complet")) return ST_DONE;
  if (has(s, "error") || has(s, "fall") || has(s, "fail")) return ST_ERROR;
  return ST_WORK;
}
std::vector<std::string> str_list(const Json& j) {
  std::vector<std::string> out;
  for (const auto& x : j.a) {
    std::string s = one_line(x.t == Json::OBJ ? x["texto"].str(x["text"].str()) : x.str(), 200);
    if (!s.empty()) out.push_back(s);
    if (out.size() >= 60) break;
  }
  return out;
}
// "" si va bien; si no, por qué no vale.
std::string parse_report(const std::string& body, Report& r, double now) {
  Json j;
  if (!parse_json(body, j) || j.t != Json::OBJ) return tx::R_BAD_JSON;
  auto pick = [&](const char* es, const char* en) -> const Json& { return j.has(es) ? j[es] : j[en]; };
  r.agent = one_line(pick("agente", "agent").str(), 60);
  if (r.agent.empty()) return tx::R_NO_AGENT;
  r.role = one_line(pick("rol", "role").str(), 160);
  r.state = pick("estado", "state").str(j["status"].str());
  r.task = one_line(pick("tarea", "task").str(), 300);
  r.url = one_line(j["url"].str(), 200);
  int port = (int)pick("puerto", "port").num();
  if (r.url.empty() && port > 0 && port < 65536) r.url = "http://localhost:" + std::to_string(port);
  r.done = str_list(pick("hechas", "done"));
  r.todo = str_list(pick("pendientes", "todo"));
  const Json& pg = pick("progreso", "progress");
  r.progress = pg.t == Json::NUM ? std::max(0, std::min(100, (int)std::lround(pg.n))) : -1;
  r.t = now;
  return "";
}
std::string reports_json(const std::vector<Report>& rs) {
  std::string o = "{\"agentes\":[";
  for (size_t i = 0; i < rs.size(); i++) {
    const Report& r = rs[i];
    if (i) o += ",";
    o += "{\"agente\":" + jq(r.agent) + ",\"rol\":" + jq(r.role) + ",\"estado\":" + jq(r.state) + ",\"tarea\":" + jq(r.task) +
         ",\"url\":" + jq(r.url) + ",\"hechas\":[";
    for (size_t k = 0; k < r.done.size(); k++) o += (k ? "," : "") + jq(r.done[k]);
    o += "],\"pendientes\":[";
    for (size_t k = 0; k < r.todo.size(); k++) o += (k ? "," : "") + jq(r.todo[k]);
    o += "]";
    if (r.progress >= 0) o += ",\"progreso\":" + std::to_string(r.progress);
    o += ",\"hora\":" + std::to_string((long long)r.t) + "}";
  }
  return o + "]}";
}
// Guarda el informe: sustituye al anterior del mismo agente.
void put_report(std::vector<Report>& rs, Report r) {
  for (auto& x : rs)
    if (fold(x.agent) == fold(r.agent)) {
      r.first = x.first;
      x = std::move(r);
      return;
    }
  r.first = r.t;
  rs.push_back(std::move(r));
}

#ifdef _WIN32
typedef SOCKET sock_t;
const sock_t BAD_SOCK = INVALID_SOCKET;
void sock_close(sock_t s) { closesocket(s); }
void net_init() {
  static bool done = false;
  if (!done) {
    WSADATA w;
    WSAStartup(MAKEWORD(2, 2), &w);
    done = true;
  }
}
#else
typedef int sock_t;
const sock_t BAD_SOCK = -1;
void sock_close(sock_t s) { close(s); }
void net_init() { signal(SIGPIPE, SIG_IGN); }
#endif

// El servidor de los informes: solo en 127.0.0.1 (no se ve desde la red).
class Server {
public:
  std::function<void(const Report&)> on_report;   // en el hilo del servidor
  std::function<void()> on_clear;
  std::mutex mu;
  std::vector<Report> reports;   // copia para contestar los GET
  int port = 0;
  std::atomic<bool> stop{false};
  std::string error;

  bool start(int p) {
    net_init();
    sock_t l = socket(AF_INET, SOCK_STREAM, 0);
    if (l == BAD_SOCK) { error = tx::SRV_NO_SOCKET; return false; }
    int yes = 1;
    setsockopt(l, SOL_SOCKET, SO_REUSEADDR, (const char*)&yes, sizeof yes);
    sockaddr_in a{};
    a.sin_family = AF_INET;
    a.sin_port = htons((unsigned short)p);
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(l, (sockaddr*)&a, sizeof a) != 0 || listen(l, 16) != 0) {
      sock_close(l);
      error = fmt(tx::SRV_BUSY, {std::to_string(p)});
      return false;
    }
    port = p;
    listener = l;
    th = std::thread([this] { loop(); });
    return true;
  }
  void shutdown() {
    stop = true;
    if (th.joinable()) th.join();
    if (listener != BAD_SOCK) sock_close(listener);
    listener = BAD_SOCK;
  }
  ~Server() { shutdown(); }

  // Una petición HTTP entera → la respuesta (también para las pruebas).
  std::string answer(const std::string& req) {
    size_t eol = req.find("\r\n");
    std::vector<std::string> first = split(req.substr(0, eol), ' ');
    std::string method = first.size() > 0 ? first[0] : "", path = first.size() > 1 ? first[1] : "/";
    size_t hb = req.find("\r\n\r\n");
    std::string body = hb == std::string::npos ? "" : req.substr(hb + 4);
    auto reply = [](int code, const std::string& text, const std::string& json) {
      return "HTTP/1.1 " + std::to_string(code) + " " + text +
             "\r\nContent-Type: application/json; charset=utf-8\r\nAccess-Control-Allow-Origin: *\r\n"
             "Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\n"
             "Connection: close\r\nContent-Length: " +
             std::to_string(json.size()) + "\r\n\r\n" + json;
    };
    if (method == "OPTIONS") return reply(204, "No Content", "");
    if (method == "GET") {
      std::lock_guard<std::mutex> g(mu);
      return reply(200, "OK", reports_json(reports));
    }
    if (method == "DELETE") {
      {
        std::lock_guard<std::mutex> g(mu);
        reports.clear();
      }
      if (on_clear) on_clear();
      return reply(200, "OK", "{\"ok\":true}");
    }
    if (method != "POST" && method != "PUT") return reply(405, "Method Not Allowed", "{\"ok\":false}");
    (void)path;
    Report r;
    std::string err = parse_report(body, r, now_t());
    if (!err.empty()) return reply(400, "Bad Request", "{\"ok\":false,\"error\":" + jq(err) + "}");
    {
      std::lock_guard<std::mutex> g(mu);
      put_report(reports, r);
    }
    if (on_report) on_report(r);
    return reply(200, "OK", "{\"ok\":true}");
  }

private:
  sock_t listener = BAD_SOCK;
  std::thread th;
  void loop() {
    while (!stop) {
      fd_set fds;
      FD_ZERO(&fds);
      FD_SET(listener, &fds);
      timeval tv{0, 300000};
      if (select((int)listener + 1, &fds, nullptr, nullptr, &tv) <= 0) continue;
      sock_t c = accept(listener, nullptr, nullptr);
      if (c == BAD_SOCK) continue;
      std::string req;
      char buf[16384];
      size_t need = std::string::npos;
      double t0 = now_t();
      while (req.size() < (2u << 20) && now_t() - t0 < 5) {
        fd_set rf;
        FD_ZERO(&rf);
        FD_SET(c, &rf);
        timeval rt{0, 500000};
        if (select((int)c + 1, &rf, nullptr, nullptr, &rt) <= 0) continue;
        int n = (int)recv(c, buf, sizeof buf, 0);
        if (n <= 0) break;
        req.append(buf, (size_t)n);
        size_t hb = req.find("\r\n\r\n");
        if (hb != std::string::npos && need == std::string::npos) {
          std::string head = lower(req.substr(0, hb));
          size_t cl = head.find("content-length:");
          need = hb + 4 + (cl == std::string::npos ? 0 : (size_t)std::atol(head.c_str() + cl + 15));
        }
        if (need != std::string::npos && req.size() >= need) break;
      }
      std::string out = answer(req);
      send(c, out.data(), (int)out.size(), 0);
      sock_close(c);
    }
  }
};

// ------------------------------------------------------------ abrir cosas
std::string sh_quote(const std::string& s) {
  std::string q = "'";
  for (char c : s) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  return q + "'";
}
void run_detached(const std::string& cmd) {
  std::thread([cmd] { int r = std::system(cmd.c_str()); (void)r; }).detach();
}
// La carpeta en VS Code (si ya está abierta, va a su ventana).
void open_in_vscode(const std::string& dir) {
#ifdef __APPLE__
  run_detached("/usr/bin/open -b com.microsoft.VSCode " + sh_quote(dir) + " >/dev/null 2>&1 || /usr/bin/open -a 'Visual Studio Code' " +
               sh_quote(dir) + " >/dev/null 2>&1");
#elif defined(_WIN32)
  std::string arg = "\"" + dir + "\"";
  ShellExecuteA(nullptr, "open", "code", arg.c_str(), nullptr, SW_HIDE);
#else
  run_detached("code " + sh_quote(dir) + " >/dev/null 2>&1 &");
#endif
}
void open_path(const std::string& what) {
#ifdef __APPLE__
  run_detached("/usr/bin/open " + sh_quote(what) + " >/dev/null 2>&1");
#elif defined(_WIN32)
  ShellExecuteA(nullptr, "open", what.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
#else
  run_detached("xdg-open " + sh_quote(what) + " >/dev/null 2>&1 &");
#endif
}
// Un aviso del sistema (en macOS, con sonido).
void notify(const std::string& title, const std::string& text) {
#ifdef __APPLE__
  auto safe = [](std::string s) {
    std::string o;
    for (char c : s)
      if (c != '"' && c != '\\' && c != '\'' && c != '\n') o += c;
    return o;
  };
  run_detached("/usr/bin/osascript -e 'display notification \"" + safe(text) + "\" with title \"" + safe(title) +
               "\" sound name \"Glass\"' >/dev/null 2>&1");
#else
  (void)title;
  (void)text;
  fl_beep(FL_BEEP_NOTIFICATION);
#endif
}

// ------------------------------------------------------------ ajustes
struct Settings {
  int filter = 1, sort = 0, port = 47823;
  bool notify = true, server = true;
};
Settings parse_settings(const std::string& text) {
  Settings s;
  for (const auto& line : split(text, '\n')) {
    size_t eq = line.find('=');
    if (eq == std::string::npos) continue;
    std::string k = trim(line.substr(0, eq)), v = trim(line.substr(eq + 1));
    int n = std::atoi(v.c_str());
    if (k == "filter" && n >= 0 && n <= 2) s.filter = n;
    if (k == "sort" && n >= 0 && n <= 2) s.sort = n;
    if (k == "port" && n > 0 && n < 65536) s.port = n;
    if (k == "notify") s.notify = n != 0;
    if (k == "server") s.server = n != 0;
  }
  return s;
}
std::string settings_text(const Settings& s) {
  return "filter=" + std::to_string(s.filter) + "\nsort=" + std::to_string(s.sort) + "\nport=" + std::to_string(s.port) +
         "\nnotify=" + std::to_string(s.notify ? 1 : 0) + "\nserver=" + std::to_string(s.server ? 1 : 0) + "\n";
}
double window_of(int filter) { return filter == 0 ? 0 : filter == 1 ? 86400 : 7 * 86400; }

// ============================================================ las tarjetas
struct Card {
  std::string key, title, sub, meta, now_label, now, url, big, chip, facts, cwd, sid, said, prompt, ask;
  bool report = false, open = false;
  int state = ST_CLOSED, color = 0, progress = -1;
  double last = 0, since = 0;
  std::vector<Task> tasks;
  std::vector<Step> steps;
  std::vector<std::pair<std::string, int>> files;
  std::vector<Sub> subs;
  std::vector<double> ticks;
};
const unsigned ACCENT[] = {0x3fb950, 0xa371f7, 0x58a6ff, 0xf778ba, 0x39c5cf, 0xe3b341, 0xff7b72, 0x7ee787};
int color_of(const std::string& key) {
  uint32_t h = 2166136261u;
  for (unsigned char c : key) { h ^= c; h *= 16777619u; }
  return (int)(h % 8);
}
const char* state_label(int st) {
  switch (st) {
    case ST_WORK: return tx::ST_WORK;
    case ST_ASK: return tx::ST_ASK;
    case ST_WAIT: return tx::ST_WAIT;
    case ST_IDLE: return tx::ST_IDLE;
    case ST_ERROR: return tx::ST_ERROR;
    case ST_DONE: return tx::ST_DONE;
    case ST_BLOCKED: return tx::ST_BLOCKED;
    default: return tx::ST_CLOSED;
  }
}
unsigned state_color(int st) {
  switch (st) {
    case ST_WORK: return 0x3fb950;
    case ST_ASK: return 0xf0883e;
    case ST_WAIT: return 0xd29922;
    case ST_IDLE: return 0x8b949e;
    case ST_ERROR: return 0xf85149;
    case ST_DONE: return 0x58a6ff;
    case ST_BLOCKED: return 0xf85149;
    default: return 0x6e7681;
  }
}
std::string where_label(const std::string& entry) {
  std::string e = lower(entry);
  if (has(e, "vscode")) return tx::IN_VSCODE;
  if (has(e, "jetbrains") || has(e, "intellij")) return "JetBrains";
  if (has(e, "desktop")) return tx::IN_DESKTOP;
  if (has(e, "sdk")) return "SDK";
  if (has(e, "cli")) return tx::IN_TERMINAL;
  return entry;
}
Card card_of(const Session& s, double now) {
  Card c;
  c.key = "s:" + s.id;
  c.sid = s.id;
  c.cwd = s.cwd;
  c.open = s.open;
  c.state = s.state;
  c.color = color_of(s.cwd.empty() ? s.id : s.cwd);
  c.title = s.cwd.empty() ? s.name : base_name(s.cwd);
  if (c.title.empty()) c.title = s.id.substr(0, 8);
  c.sub = !s.title.empty() ? s.title : s.prompt;
  std::vector<std::string> meta;
  if (!s.branch.empty() && s.branch != "HEAD") meta.push_back(fmt(tx::BRANCH, {s.branch}));
  if (!s.model.empty()) meta.push_back(model_name(s.model));
  std::string w = where_label(s.entry);
  if (!w.empty()) meta.push_back(w);
  for (size_t i = 0; i < meta.size(); i++) c.meta += (i ? " · " : "") + meta[i];
  c.url = s.url;
  c.tasks = s.tasks;
  c.steps = s.steps;
  c.files = s.files;
  c.subs = s.subs;
  c.ticks = s.ticks;
  c.said = s.said;
  c.prompt = s.prompt;
  c.ask = s.ask;
  c.last = std::max({s.last, s.status_t, s.mtime});
  int done = 0;
  for (const auto& t : s.tasks) done += t.st == 2;
  if (!s.tasks.empty()) c.progress = (int)std::lround(100.0 * done / (double)s.tasks.size());
  // Lo que hace ahora.
  const Step* pend = s.pending();
  switch (s.state) {
    case ST_WORK:
      c.now_label = tx::L_NOW;
      if (pend) c.now = doing(pend->name, pend->what, pend->raw);
      else if (s.running_subs() > 0) c.now = fmt(s.running_subs() == 1 ? tx::SUBS_WAIT_ONE : tx::SUBS_WAIT_N, {num(s.running_subs(), 0)});
      else c.now = tx::THINKING;
      c.since = s.turn > 0 ? s.turn : s.last;
      break;
    case ST_ASK:
      c.now_label = tx::L_ASKS;
      c.now = s.ask.empty() ? std::string(tx::ASKS_PERMISSION) : s.ask;
      c.since = s.status_t > 0 ? s.status_t : s.last;
      break;
    case ST_ERROR:
      c.now_label = tx::L_ERROR;
      c.now = s.error.empty() ? std::string(tx::API_ERROR) : s.error;
      c.since = s.last;
      break;
    case ST_WAIT:
    case ST_IDLE:
      c.now_label = tx::L_FINISHED;
      c.now = s.said.empty() ? std::string(tx::WAITING_YOU) : s.said;
      c.since = std::max(s.ended, s.status_t);
      if (c.since <= 0) c.since = s.last;
      break;
    default:
      c.now_label = tx::L_LAST_PROMPT;
      c.now = s.prompt;
      c.since = std::max(s.last, s.mtime);
  }
  if (c.progress >= 0) c.big = num(c.progress, 0) + " %";
  else if (s.state == ST_WORK && c.since > 0) c.big = dur(now - c.since);
  else c.big = short_ago(now - c.since);
  c.chip = state_label(s.state);
  std::vector<std::string> f;
  if (s.prompts) f.push_back(fmt(s.prompts == 1 ? tx::F_PROMPTS_ONE : tx::F_PROMPTS_N, {num(s.prompts, 0)}));
  if (s.calls) f.push_back(fmt(tx::F_TOOLS, {num(s.calls, 0)}));
  if (s.errors) f.push_back(fmt(s.errors == 1 ? tx::F_ERRORS_ONE : tx::F_ERRORS_N, {num(s.errors, 0)}));
  double tot = s.in + s.out + s.cr + s.cw;
  if (tot > 0) f.push_back(fmt(tx::F_TOKENS, {tokens(tot)}));
  if (s.cost > 0) f.push_back(fmt(tx::F_COST, {money(s.cost)}));
  if (s.ctx > 0) f.push_back(fmt(tx::F_CONTEXT, {num(std::min(100.0, 100.0 * s.ctx / context_window(s.model, s.ctx)), 0)}));
  if (s.first > 0) f.push_back(fmt(tx::F_STARTED, {clock_hm(s.first)}));
  if (s.pid > 0) f.push_back(fmt(tx::F_PID, {std::to_string(s.pid)}));
  for (size_t i = 0; i < f.size(); i++) c.facts += (i ? " · " : "") + f[i];
  return c;
}
Card card_of(const Report& r, double now) {
  Card c;
  c.report = true;
  c.open = now - r.t < 3600;
  c.key = "r:" + fold(r.agent);
  c.title = r.agent;
  c.sub = r.role;
  c.meta = tx::REPORTED;
  c.state = report_state(r.state);
  if (now - r.t > 15 * 60 && c.state == ST_WORK) c.state = ST_IDLE;
  c.color = color_of(r.agent);
  c.url = r.url;
  c.now_label = tx::L_NOW;
  c.now = r.task;
  c.since = r.first;
  c.last = r.t;
  for (const auto& d : r.done) c.tasks.push_back({"", d, 2});
  for (size_t i = 0; i < r.todo.size(); i++) c.tasks.push_back({"", r.todo[i], 0});
  if (!r.todo.empty() && c.state == ST_WORK) {
    for (auto& t : c.tasks)
      if (t.st == 0) { t.st = 1; break; }
  }
  size_t total = r.done.size() + r.todo.size();
  if (total > 0) c.progress = (int)std::lround(100.0 * (double)r.done.size() / (double)total);
  else if (r.progress >= 0) c.progress = r.progress;
  if (c.state == ST_DONE) c.progress = 100;
  c.big = c.progress >= 0 ? num(c.progress, 0) + " %" : short_ago(now - r.t);
  c.chip = now - r.t > 15 * 60 ? std::string(tx::NO_SIGNAL) : std::string(state_label(c.state));
  c.facts = fmt(tx::F_REPORT, {clock_hm(r.t), ago(now - r.t)});
  return c;
}
// Las tarjetas que se ven: el filtro, la búsqueda y el orden.
std::vector<Card> cards_of(const std::vector<Session>& ss, const std::vector<Report>& rs, const Settings& set,
                           const std::string& search, double now) {
  std::vector<Card> out;
  double win = window_of(set.filter);
  for (const auto& s : ss) {
    if (!s.open && (set.filter == 0 || now - std::max(s.last, s.mtime) > win)) continue;
    out.push_back(card_of(s, now));
  }
  for (const auto& r : rs) {
    if (set.filter == 0 && now - r.t > 3600) continue;
    if (now - r.t > std::max(win, 3600.0)) continue;
    out.push_back(card_of(r, now));
  }
  std::string q = fold(trim(search));
  if (!q.empty()) {
    std::vector<Card> keep;
    for (auto& c : out)
      if (has(fold(c.title + " " + c.sub + " " + c.meta + " " + c.cwd + " " + c.now), q)) keep.push_back(std::move(c));
    out.swap(keep);
  }
  auto rank = [](const Card& c) {
    switch (c.state) {
      case ST_ASK: return 0;
      case ST_ERROR: case ST_BLOCKED: return 1;
      case ST_WORK: return 2;
      case ST_WAIT: return 3;
      case ST_DONE: return 4;
      case ST_IDLE: return 5;
      default: return 6;
    }
  };
  std::stable_sort(out.begin(), out.end(), [&](const Card& a, const Card& b) {
    if (a.open != b.open) return a.open;
    if (set.sort == 1 && rank(a) != rank(b)) return rank(a) < rank(b);
    if (set.sort == 2) {
      std::string x = fold(a.title), y = fold(b.title);
      if (x != y) return x < y;
    }
    return a.last > b.last;
  });
  return out;
}
struct Totals {
  int open = 0, work = 0, ask = 0, wait = 0, subs = 0, done = 0, tasks = 0, reports = 0;
  double tokens = 0, cost = 0;
};
Totals totals_of(const std::vector<Session>& ss, const std::vector<Report>& rs, double now) {
  Totals t;
  for (const auto& s : ss) {
    if (!s.open) continue;
    t.open++;
    t.work += s.state == ST_WORK;
    t.ask += s.state == ST_ASK || s.state == ST_ERROR;
    t.wait += s.state == ST_WAIT;
    t.subs += s.running_subs();
    for (const auto& k : s.tasks) { t.tasks++; t.done += k.st == 2; }
  }
  for (const auto& s : ss)
    if (now - s.last < 86400 || s.open) {
      t.tokens += s.in + s.out + s.cr + s.cw;
      t.cost += s.cost;
    }
  for (const auto& r : rs) {
    if (now - r.t > 3600) continue;
    t.reports++;
    t.tasks += (int)(r.done.size() + r.todo.size());
    t.done += (int)r.done.size();
  }
  return t;
}

// ------------------------------------------------------------ dibujo
inline Fl_Color rgb(unsigned c) { return fl_rgb_color((uchar)(c >> 16), (uchar)((c >> 8) & 255), (uchar)(c & 255)); }
inline Fl_Color mix(unsigned a, unsigned b, double t) {
  auto ch = [&](int s) { return (uchar)std::lround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t); };
  return fl_rgb_color(ch(16), ch(8), ch(0));
}
const unsigned BG = 0x18181b, CARD = 0x222226, LINE = 0x34343b, TEXT = 0xf4f4f5, MUTED = 0xa1a1aa, FAINT = 0x71717a;
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color border) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  if (border != fill) {
    fl_color(border);
    fl_rounded_rect(x, y, w, h, r);
  }
}
// [s] cortado con «…» para que quepa en [w] píxeles (con la letra puesta).
std::string fit(const std::string& s, int w) {
  if (w <= 0) return "";
  if (fl_width(s.c_str()) <= w) return s;
  int lo = 0, hi = (int)s.size();
  while (lo < hi) {
    int mid = (lo + hi + 1) / 2;
    int m = mid;
    while (m > 0 && ((unsigned char)s[(size_t)m] & 0xc0) == 0x80) m--;
    if (fl_width((s.substr(0, (size_t)m) + "…").c_str()) <= w) lo = mid;
    else hi = mid - 1;
  }
  int m = lo;
  while (m > 0 && m < (int)s.size() && ((unsigned char)s[(size_t)m] & 0xc0) == 0x80) m--;
  return s.substr(0, (size_t)m) + "…";
}
// Las líneas de [s] en [w] píxeles, como mucho [max] (la última con «…»).
std::vector<std::string> wrap(const std::string& s, int w, int max) {
  std::vector<std::string> out;
  std::string line;
  for (const auto& word : split(one_line(s, 2000), ' ')) {
    std::string t = line.empty() ? word : line + " " + word;
    if (fl_width(t.c_str()) <= w || line.empty()) {
      line = t;
      continue;
    }
    out.push_back(line);
    line = word;
    if ((int)out.size() == max) break;
  }
  if ((int)out.size() < max && !line.empty()) out.push_back(line);
  else if ((int)out.size() == max && !line.empty()) out.back() = fit(out.back() + " " + line, w);
  for (auto& l : out) l = fit(l, w);
  return out;
}
// El robot de cada fila: [cx] su centro, [by] la base; [phase] lo mueve.
void robot(int cx, int by, unsigned col, int state, double phase) {
  bool work = state == ST_WORK;
  int dy = work ? (int)std::lround(std::sin(phase * 2.4) * 2) : 0;
  int y = by + dy;
  Fl_Color c = state == ST_CLOSED || state == ST_IDLE ? mix(col, BG, 0.55) : rgb(col);
  fl_color(c);
  fl_line(cx, y - 25, cx, y - 21);
  fl_pie(cx - 2, y - 28, 5, 5, 0, 360);
  fl_rounded_rectf(cx - 11, y - 21, 22, 14, 4);
  fl_rectf(cx - 7, y - 6, 14, 5);
  fl_rectf(cx - 6, y - 1, 4, 3);
  fl_rectf(cx + 2, y - 1, 4, 3);
  // Los ojos: abiertos al trabajar, rayas al esperar, cruces con error.
  fl_color(state == ST_ERROR || state == ST_BLOCKED ? rgb(0xffd7d5) : work && std::fmod(phase, 3.2) < 3.0 ? rgb(0xffffff) : rgb(0x1f1f23));
  if (state == ST_ERROR || state == ST_BLOCKED) {
    fl_line(cx - 7, y - 17, cx - 3, y - 13);
    fl_line(cx - 3, y - 17, cx - 7, y - 13);
    fl_line(cx + 3, y - 17, cx + 7, y - 13);
    fl_line(cx + 7, y - 17, cx + 3, y - 13);
  } else if (work || state == ST_ASK || state == ST_DONE) {
    fl_rectf(cx - 7, y - 16, 4, 4);
    fl_rectf(cx + 3, y - 16, 4, 4);
  } else {
    fl_rectf(cx - 7, y - 14, 4, 2);
    fl_rectf(cx + 3, y - 14, 4, 2);
  }
  if (state == ST_ASK) {   // un bocadillo con «?»
    fl_color(rgb(0xf0883e));
    fl_rounded_rectf(cx + 10, y - 38, 16, 14, 4);
    fl_color(rgb(0x18181b));
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_draw("?", cx + 15, y - 27);
  }
}
void flag(int x, int y) {
  fl_color(rgb(MUTED));
  fl_line(x, y, x, y + 16);
  for (int r = 0; r < 3; r++)
    for (int k = 0; k < 4; k++) {
      fl_color((r + k) % 2 ? rgb(0x2a2a2f) : rgb(0xe4e4e7));
      fl_rectf(x + 1 + k * 4, y + r * 4, 4, 4);
    }
}
// Un enlace o botón dibujado que se puede pulsar.
struct Hit {
  int x, y, w, h;
  int act;
  std::string key, arg;
};
enum Act { A_TOGGLE = 1, A_VSCODE, A_FOLDER, A_RESUME, A_URL, A_REMOVE, A_COPY_ID };

class Tower : public Fl_Widget {
public:
  std::vector<Card> cards;
  std::set<std::string> expanded;
  std::vector<Hit> hits;
  Totals tot;
  std::string host, empty_title, empty_text;
  double now = 0, phase = 0;
  int hover = -1;
  std::function<void(int, const std::string&, const std::string&)> on_act;
  Tower(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int card_height(const Card& c, int W) const {
    int h = 132;
    if (!c.subs.empty() && c.state != ST_CLOSED) h += 22;
    if (!c.url.empty()) h += 24;
    if (expanded.count(c.key)) h += expanded_height(c, W);
    return h;
  }
  int list_rows(const Card& c) const {
    if (!c.tasks.empty()) {
      int d = 0;
      for (const auto& t : c.tasks) d += t.st == 2;
      return std::min(12, std::max(d, (int)c.tasks.size() - d));
    }
    return std::min(10, std::max((int)c.steps.size(), (int)std::min<size_t>(c.files.size(), 10)));
  }
  int expanded_height(const Card& c, int W) const {
    (void)W;
    int h = 34 + list_rows(c) * 22 + 12;
    if (!c.subs.empty()) h += 30 + (int)std::min<size_t>(c.subs.size(), 8) * 22;
    if (!c.report) h += 26 + 26;   // la orden y lo que dijo
    h += 24 + 44;   // las cifras y los botones
    return h;
  }
  // El alto de todo (para el desplazamiento).
  static const int HEADER = 140;
  int content_height(int W) const {
    int h = HEADER + 28;
    if (cards.empty()) return h + 220;
    for (const auto& c : cards) h += card_height(c, W) + 16;
    return h + 24;
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(BG));
    fl_rectf(x(), y(), w(), h());
    int X = x() + 40, W = w() - 80, Y = y() + 28;
    draw_header(X, Y, W);
    Y += HEADER;
    if (cards.empty()) {
      fl_font(FL_HELVETICA_BOLD, 20);
      fl_color(rgb(TEXT));
      fl_draw(empty_title.c_str(), X, Y + 60);
      fl_font(FL_HELVETICA, 15);
      fl_color(rgb(MUTED));
      int yy = Y + 92;
      for (const auto& l : wrap(empty_text, W, 4)) {
        fl_draw(l.c_str(), X, yy);
        yy += 22;
      }
    }
    int section = -1;
    for (size_t i = 0; i < cards.size(); i++) {
      const Card& c = cards[i];
      int sec = c.open ? 0 : 1;
      if (sec != section && sec == 1) {
        fl_font(FL_HELVETICA_BOLD, 12);
        fl_color(rgb(FAINT));
        fl_draw(tx::CLOSED_HEADER, X, Y + 14);
        Y += 28;
      }
      section = sec;
      int ch = card_height(c, W);
      if (Y + ch >= y() - 10 && Y <= y() + h() + 10 && fl_not_clipped(X, Y, W, ch)) draw_card(c, X, Y, W, ch);
      else hits.push_back({X, Y, W, 124, A_TOGGLE, c.key, ""});
      Y += ch + 16;
    }
    fl_pop_clip();
  }
  void draw_header(int X, int Y, int W) {
    fl_color(rgb(tot.work ? 0x3fb950 : 0x8b949e));
    fl_pie(X, Y + 2, 9, 9, 0, 360);
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(rgb(MUTED));
    fl_draw(tx::TOWER_CAPS, X + 18, Y + 11);
    fl_font(FL_HELVETICA_BOLD, 44);
    fl_color(rgb(TEXT));
    fl_draw(fit(host, W - 220).c_str(), X - 2, Y + 62);
    std::vector<std::string> parts;
    parts.push_back(fmt(tot.open == 1 ? tx::H_OPEN_ONE : tx::H_OPEN_N, {num(tot.open, 0)}));
    if (tot.work) parts.push_back(fmt(tx::H_WORK, {num(tot.work, 0)}));
    if (tot.ask) parts.push_back(fmt(tot.ask == 1 ? tx::H_ASK_ONE : tx::H_ASK, {num(tot.ask, 0)}));
    if (tot.wait) parts.push_back(fmt(tot.wait == 1 ? tx::H_WAIT_ONE : tx::H_WAIT, {num(tot.wait, 0)}));
    if (tot.subs) parts.push_back(fmt(tot.subs == 1 ? tx::H_SUBS_ONE : tx::H_SUBS_N, {num(tot.subs, 0)}));
    if (tot.reports) parts.push_back(fmt(tot.reports == 1 ? tx::H_REPORTS_ONE : tx::H_REPORTS_N, {num(tot.reports, 0)}));
    if (tot.tasks) parts.push_back(fmt(tx::H_TASKS, {num(tot.done, 0), num(tot.tasks, 0)}));
    if (tot.tokens > 0) parts.push_back(fmt(tx::H_TOKENS, {tokens(tot.tokens), money(tot.cost)}));
    std::string line;
    for (size_t i = 0; i < parts.size(); i++) line += (i ? " · " : "") + parts[i];
    fl_font(FL_HELVETICA, 16);
    fl_color(rgb(MUTED));
    fl_draw(fit(line, W - 140).c_str(), X, Y + 94);
    // El anillo: las tareas hechas (o, sin tareas, las sesiones que trabajan).
    int R = 108, rx = X + W - R, ry = Y - 8;
    double frac = tot.tasks ? tot.done / (double)tot.tasks : tot.open ? tot.work / (double)tot.open : 0;
    std::string label = tot.tasks ? num(std::lround(frac * 100), 0) + " %" : num(tot.work, 0) + "/" + num(tot.open, 0);
    fl_line_style(FL_SOLID | FL_CAP_FLAT, 9);
    fl_color(rgb(0x2c2c32));
    fl_arc(rx + 6, ry + 6, R - 12, R - 12, 0, 360);
    if (frac > 0) {
      fl_color(rgb(tot.tasks ? 0x79c0ff : 0x3fb950));
      fl_arc(rx + 6, ry + 6, R - 12, R - 12, 90 - 360 * std::min(1.0, frac), 90);
    }
    fl_line_style(0);
    fl_font(FL_HELVETICA_BOLD, label.size() > 5 ? 22 : 28);
    fl_color(rgb(TEXT));
    int lw = (int)fl_width(label.c_str());
    fl_draw(label.c_str(), rx + R / 2 - lw / 2, ry + R / 2 + 8);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(FAINT));
    const char* cap = tot.tasks ? tx::RING_TASKS : tx::RING_WORKING;
    int cw = (int)fl_width(cap);
    fl_draw(cap, rx + R / 2 - cw / 2, ry + R + 16);
  }
  void button(int& bx, int by, const char* text, int act, const Card& c, const std::string& arg = "") {
    fl_font(FL_HELVETICA_BOLD, 13);
    int bw = (int)fl_width(text) + 28;
    round_box(bx, by, bw, 30, 15, rgb(0x2d2d33), rgb(0x3f3f46));
    fl_color(rgb(TEXT));
    fl_draw(text, bx + 14, by + 20);
    hits.push_back({bx, by, bw, 30, act, c.key, arg});
    bx += bw + 10;
  }
  void draw_card(const Card& c, int X, int Y, int W, int H) {
    unsigned col = ACCENT[c.color];
    round_box(X, Y, W, H, 14, rgb(CARD), rgb(LINE));
    fl_color(c.open ? rgb(col) : mix(col, CARD, 0.5));
    fl_rectf(X + 1, Y + 10, 4, H - 20);
    hits.push_back({X, Y, W, 124, A_TOGGLE, c.key, ""});
    const int L = 260, RW = 150;
    // La columna de la izquierda: el proyecto, de qué va y dónde.
    fl_font(FL_HELVETICA_BOLD, 19);
    fl_color(rgb(TEXT));
    fl_draw(fit(c.title, L - 30).c_str(), X + 28, Y + 34);
    fl_font(FL_HELVETICA, 14);
    fl_color(rgb(MUTED));
    int yy = Y + 56;
    for (const auto& l : wrap(c.sub, L - 34, 2)) {
      fl_draw(l.c_str(), X + 28, yy);
      yy += 19;
    }
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(FAINT));
    fl_draw(fit(c.meta, L - 34).c_str(), X + 28, Y + 112);
    // La pista: con tareas, el avance; sin ellas, la última hora de trabajo.
    int tx0 = X + L + 10, tw = W - L - RW - 40, ty = Y + 56;
    fl_color(rgb(0x2e2e34));
    fl_rounded_rectf(tx0, ty, tw, 8, 4);
    int rx;
    if (c.progress >= 0) {
      int fw = (int)(tw * c.progress / 100.0);
      fl_color(c.open ? rgb(col) : mix(col, CARD, 0.4));
      if (fw > 0) fl_rounded_rectf(tx0, ty, std::max(8, fw), 8, 4);
      rx = tx0 + std::max(12, std::min(tw - 12, fw));
      flag(tx0 + tw - 8, ty - 22);
    } else {
      double span = 3600;
      for (double t : c.ticks) {
        double f = 1 - (now - t) / span;
        if (f < 0 || f > 1) continue;
        int px = tx0 + (int)(f * tw);
        fl_color(mix(col, CARD, 0.25));
        fl_rectf(px, ty - 1, 2, 10);
      }
      double f = c.last > 0 ? 1 - (now - c.last) / span : 0;
      f = c.state == ST_WORK ? 1 : std::max(0.0, std::min(1.0, f));
      rx = tx0 + std::max(12, std::min(tw - 12, (int)(f * tw)));
      fl_font(FL_HELVETICA, 11);
      fl_color(rgb(FAINT));
      fl_draw(tx::HOUR_AGO, tx0, ty + 24);
      int nw = (int)fl_width(tx::NOW_CAPS);
      fl_draw(tx::NOW_CAPS, tx0 + tw - nw, ty + 24);
    }
    robot(rx, ty - 4, col, c.state, phase);
    // A la derecha: el avance o el tiempo y el estado.
    fl_font(FL_HELVETICA_BOLD, 28);
    fl_color(rgb(TEXT));
    int bw = (int)fl_width(c.big.c_str());
    fl_draw(c.big.c_str(), X + W - 24 - bw, Y + 44);
    fl_font(FL_HELVETICA_BOLD, 12);
    int cw = (int)fl_width(c.chip.c_str()) + 20;
    unsigned sc = state_color(c.state);
    round_box(X + W - 24 - cw, Y + 58, cw, 24, 12, mix(sc, CARD, 0.78), mix(sc, CARD, 0.55));
    fl_color(rgb(sc));
    fl_draw(c.chip.c_str(), X + W - 24 - cw + 10, Y + 75);
    // AHORA: lo que hace.
    yy = Y + 104;
    fl_font(FL_HELVETICA_BOLD, 12);
    fl_color(rgb(c.state == ST_ASK ? 0xf0883e : c.state == ST_ERROR ? 0xf85149 : col));
    fl_draw(c.now_label.c_str(), tx0, yy);
    int lw = (int)fl_width(c.now_label.c_str()) + 12;
    fl_font(FL_HELVETICA, 16);
    fl_color(rgb(TEXT));
    fl_draw(fit(c.now, W - L - 50 - lw - 0).c_str(), tx0 + lw, yy + 1);
    yy += 24;
    if (!c.subs.empty() && c.state != ST_CLOSED) {
      int run = 0;
      std::string names;
      for (const auto& s : c.subs)
        if (s.running) {
          run++;
          names += (names.empty() ? "" : " · ") + s.desc;
        }
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(rgb(FAINT));
      std::string lab = run ? fmt(run == 1 ? tx::SUBS_RUN_ONE : tx::SUBS_RUN_N, {num(run, 0)})
                            : fmt(c.subs.size() == 1 ? tx::SUBS_DONE_ONE : tx::SUBS_DONE_N, {num((double)c.subs.size(), 0)});
      fl_draw(lab.c_str(), tx0, yy);
      int sw = (int)fl_width(lab.c_str()) + 12;
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(MUTED));
      fl_draw(fit(names, W - L - 50 - sw).c_str(), tx0 + sw, yy);
      yy += 22;
    }
    if (!c.url.empty()) {
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(rgb(FAINT));
      fl_draw(tx::TESTING_ON, tx0, yy + 2);
      int pw = (int)fl_width(tx::TESTING_ON) + 12;
      fl_font(FL_COURIER, 16);
      fl_color(rgb(0x79c0ff));
      int uw = (int)fl_width(c.url.c_str());
      fl_draw(c.url.c_str(), tx0 + pw, yy + 3);
      hits.push_back({tx0 + pw, yy - 14, uw, 22, A_URL, c.key, c.url});
      size_t colon = c.url.rfind(':');
      if (colon != std::string::npos) {
        std::string port = fmt(tx::PORT_CHIP, {c.url.substr(colon + 1)});
        fl_font(FL_HELVETICA_BOLD, 12);
        int qw = (int)fl_width(port.c_str()) + 16;
        round_box(tx0 + pw + uw + 10, yy - 13, qw, 22, 6, rgb(0x2b3a4a), rgb(0x2b3a4a));
        fl_color(rgb(0xa5d6ff));
        fl_draw(port.c_str(), tx0 + pw + uw + 18, yy + 3);
      }
      yy += 24;
    }
    // Ver más / Ver menos.
    bool ex = expanded.count(c.key) > 0;
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(0x79c0ff));
    const char* more = ex ? tx::SEE_LESS : tx::SEE_MORE;
    int mw = (int)fl_width(more);
    fl_draw(more, X + W - 24 - mw, Y + 112);
    hits.push_back({X + W - 34 - mw, Y + 96, mw + 20, 24, A_TOGGLE, c.key, ""});
    if (!ex) return;
    // ---- el detalle
    int dx = tx0, dw = W - L - 50, colw = (dw - 30) / 2;
    yy += 10;
    fl_color(rgb(LINE));
    fl_line(X + 20, yy - 8, X + W - 20, yy - 8);
    std::vector<std::pair<std::string, int>> left, right;   // texto y marca
    std::string lt, rt;
    if (!c.tasks.empty()) {
      for (const auto& t : c.tasks) (t.st == 2 ? left : right).push_back({t.text, t.st});
      lt = fmt(tx::DONE_N, {num((double)left.size(), 0)});
      rt = fmt(tx::TODO_N, {num((double)right.size(), 0)});
    } else {
      for (auto it = c.steps.rbegin(); it != c.steps.rend() && left.size() < 10; ++it)
        left.push_back({clock_hm(it->t) + "  " + it->name + (it->what.empty() ? "" : " · " + it->what), it->st == 0 ? 1 : it->st == 2 ? 3 : 2});
      for (auto it = c.files.rbegin(); it != c.files.rend() && right.size() < 10; ++it)
        right.push_back({base_name(it->first) + (it->second > 1 ? "  ×" + std::to_string(it->second) : ""), 4});
      lt = tx::LAST_STEPS;
      rt = fmt(tx::FILES_N, {num((double)c.files.size(), 0)});
    }
    yy += 16;
    fl_font(FL_HELVETICA_BOLD, 12);
    fl_color(rgb(FAINT));
    fl_draw(lt.c_str(), dx, yy);
    fl_draw(rt.c_str(), dx + colw + 30, yy);
    yy += 8;
    int rows = list_rows(c);
    auto column = [&](const std::vector<std::pair<std::string, int>>& v, int cx0) {
      int y2 = yy;
      for (int i = 0; i < rows && i < (int)v.size(); i++) {
        y2 += 22;
        const auto& e = v[(size_t)i];
        const char* mark = "";
        Fl_Color mc = rgb(MUTED), tc = rgb(MUTED);
        switch (e.second) {
          case 0: mark = "○"; break;
          case 1: mark = "●"; mc = rgb(col); tc = rgb(TEXT); break;
          case 2: mark = "✓"; mc = rgb(0x3fb950); break;
          case 3: mark = "✗"; mc = rgb(0xf85149); break;
          default: mark = "•"; mc = rgb(FAINT);
        }
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(mc);
        fl_draw(mark, cx0, y2);
        fl_font(FL_HELVETICA, 14);
        fl_color(tc);
        fl_draw(fit(e.first, colw - 22).c_str(), cx0 + 20, y2);
      }
    };
    column(left, dx);
    column(right, dx + colw + 30);
    yy += rows * 22 + 12;
    if (!c.subs.empty()) {
      yy += 22;
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(rgb(FAINT));
      fl_draw(fmt(tx::SUBAGENTS_N, {num((double)c.subs.size(), 0)}).c_str(), dx, yy);
      yy += 8;
      int n = 0;
      for (auto it = c.subs.rbegin(); it != c.subs.rend() && n < 8; ++it, n++) {
        yy += 22;
        fl_color(it->running ? rgb(0x3fb950) : rgb(FAINT));
        fl_pie(dx + 1, yy - 10, 9, 9, 0, 360);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(TEXT));
        std::string d = it->desc.empty() ? it->kind : it->desc;
        fl_draw(fit(d, colw).c_str(), dx + 18, yy);
        fl_font(FL_HELVETICA, 14);
        fl_color(rgb(MUTED));
        std::string st = it->running ? (it->now.empty() ? std::string(tx::ST_WORK) : it->now) : std::string(tx::SUB_FINISHED);
        if (it->steps) st += " · " + fmt(tx::F_TOOLS, {num(it->steps, 0)});
        fl_draw(fit(st, colw).c_str(), dx + colw + 30, yy);
      }
      yy += 8;
    }
    auto labelled = [&](const char* label, const std::string& text) {
      yy += 26;
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(rgb(FAINT));
      fl_draw(label, dx, yy);
      int lw2 = (int)fl_width(label) + 12;
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(MUTED));
      fl_draw(fit(text, dw - lw2).c_str(), dx + lw2, yy);
    };
    if (!c.report) {
      labelled(tx::L_PROMPT, c.prompt.empty() ? "—" : c.prompt);
      labelled(tx::L_SAID, c.said.empty() ? "—" : c.said);
    }
    yy += 24;
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(FAINT));
    fl_draw(fit(c.facts, dw).c_str(), dx, yy);
    yy += 14;
    int bx = dx;
    if (!c.report) {
      if (!c.cwd.empty()) {
        button(bx, yy, tx::B_VSCODE, A_VSCODE, c, c.cwd);
        button(bx, yy, tx::B_FOLDER, A_FOLDER, c, c.cwd);
      }
      button(bx, yy, tx::B_RESUME, A_RESUME, c, c.sid);
    }
    if (!c.url.empty()) button(bx, yy, tx::B_URL, A_URL, c, c.url);
    if (c.report) button(bx, yy, tx::B_REMOVE, A_REMOVE, c, c.title);
  }
  int hit_at(int mx, int my) const {
    // Los botones y enlaces van después de su tarjeta: gana el último.
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (mx >= h.x && mx < h.x + h.w && my >= h.y && my < h.y + h.h) return i;
    }
    return -1;
  }
  int handle(int e) override {
    switch (e) {
      case FL_PUSH: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i < 0) return 1;
        Hit h = hits[(size_t)i];
        if (h.act == A_TOGGLE) {
          if (expanded.count(h.key)) expanded.erase(h.key);
          else expanded.insert(h.key);
        }
        if (on_act) on_act(h.act, h.key, h.arg);
        return 1;
      }
      case FL_ENTER:
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        int act = i >= 0 ? hits[(size_t)i].act : 0;
        if (window()) window()->cursor(act > A_TOGGLE ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
        hover = i;
        return 1;
      }
      case FL_LEAVE:
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        hover = -1;
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ------------------------------------------------------------ la barra
struct MenuEntry {
  std::string title;
  int tag = 0;
  bool sep = false, checked = false;
  int color = -1;   // un puntito del color del estado
};
enum BarAct { B_WINDOW = 1, B_NOTIFY, B_QUIT, B_REFRESH, B_SESSION = 100 };
std::string bar_title(const Totals& t) {
  if (t.ask) return fmt(tx::BAR_ASK, {num(t.work, 0), num(t.open, 0), num(t.ask, 0)});
  return fmt(tx::BAR_TITLE, {num(t.work, 0), num(t.open, 0)});
}
std::vector<MenuEntry> bar_menu(const std::vector<Card>& cards, const Totals& t, bool notify_on, bool window_shown) {
  std::vector<MenuEntry> m;
  std::vector<std::string> parts;
  parts.push_back(fmt(t.open == 1 ? tx::H_OPEN_ONE : tx::H_OPEN_N, {num(t.open, 0)}));
  if (t.work) parts.push_back(fmt(tx::H_WORK, {num(t.work, 0)}));
  if (t.ask) parts.push_back(fmt(t.ask == 1 ? tx::H_ASK_ONE : tx::H_ASK, {num(t.ask, 0)}));
  std::string head;
  for (size_t i = 0; i < parts.size(); i++) head += (i ? " · " : "") + parts[i];
  m.push_back({head});
  m.push_back({"", 0, true});
  int n = 0;
  for (size_t i = 0; i < cards.size() && n < 20; i++) {
    const Card& c = cards[i];
    if (!c.open || c.report) continue;
    MenuEntry e;
    e.title = c.title + " — " + c.chip + (c.now.empty() ? "" : ": " + one_line(c.now, 60));
    e.tag = B_SESSION + (int)i;
    e.color = c.state;
    m.push_back(e);
    n++;
  }
  if (!n) m.push_back({tx::NO_OPEN});
  m.push_back({"", 0, true});
  if (!window_shown) m.push_back({tx::OPEN_WINDOW, B_WINDOW});
  m.push_back({tx::REFRESH_NOW, B_REFRESH});
  MenuEntry nt{tx::NOTIFY_ME, B_NOTIFY};
  nt.checked = notify_on;
  m.push_back(nt);
  m.push_back({"", 0, true});
  m.push_back({tx::QUIT, B_QUIT});
  return m;
}

// ------------------------------------------------------------ pruebas
// DMS_TOWER_SELFTEST=1: sin ventana, con un ~/.claude de mentira.
void put_line(std::string& out, const std::string& json) { out += json + "\n"; }
std::string ts(double t) {
  time_t tt = (time_t)t;
  struct tm g;
#ifdef _WIN32
  gmtime_s(&g, &tt);
#else
  gmtime_r(&tt, &g);
#endif
  char b[40];
  std::snprintf(b, sizeof b, "%04d-%02d-%02dT%02d:%02d:%02d.000Z", g.tm_year + 1900, g.tm_mon + 1, g.tm_mday, g.tm_hour, g.tm_min, g.tm_sec);
  return b;
}
std::string user_line(double t, const std::string& cwd, const std::string& text) {
  return "{\"type\":\"user\",\"timestamp\":\"" + ts(t) + "\",\"cwd\":" + jq(cwd) +
         ",\"gitBranch\":\"main\",\"entrypoint\":\"claude-vscode\",\"message\":{\"role\":\"user\",\"content\":" + jq(text) + "}}";
}
std::string tool_line(double t, const std::string& id, const std::string& name, const std::string& input, const std::string& mid) {
  return "{\"type\":\"assistant\",\"timestamp\":\"" + ts(t) + "\",\"message\":{\"id\":\"" + mid +
         "\",\"model\":\"claude-opus-5-5\",\"content\":[{\"type\":\"tool_use\",\"id\":\"" + id + "\",\"name\":\"" + name +
         "\",\"input\":" + input + "}],\"stop_reason\":\"tool_use\",\"usage\":{\"input_tokens\":1000,\"output_tokens\":200,"
         "\"cache_read_input_tokens\":50000,\"cache_creation_input_tokens\":2000}}}";
}
std::string result_line(double t, const std::string& id, bool error, const std::string& extra = "") {
  return "{\"type\":\"user\",\"timestamp\":\"" + ts(t) + "\",\"message\":{\"role\":\"user\",\"content\":[{\"type\":\"tool_result\",\"tool_use_id\":\"" +
         id + "\",\"is_error\":" + (error ? "true" : "false") + ",\"content\":\"ok\"}]}" + extra + "}";
}
std::string text_line(double t, const std::string& text, const std::string& mid, bool end) {
  return "{\"type\":\"assistant\",\"timestamp\":\"" + ts(t) + "\",\"message\":{\"id\":\"" + mid +
         "\",\"model\":\"claude-opus-5-5\",\"content\":[{\"type\":\"text\",\"text\":" + jq(text) + "}],\"stop_reason\":" +
         (end ? "\"end_turn\"" : "null") + ",\"usage\":{\"input_tokens\":10,\"output_tokens\":300,\"cache_read_input_tokens\":60000,\"cache_creation_input_tokens\":0}}}";
}
int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  // Lo básico.
  chk(fmt("{0} y {1}", {"a", "b"}) == "a y b", "fmt");
  chk(slug("/Users/ana/Projects/dmarlonstudio.com") == "-Users-ana-Projects-dmarlonstudio-com", "slug");
  chk(std::fabs(iso_time("2026-11-14T20:42:01.500Z") - 1794688921.5) < 0.01, "iso_time");
  chk(model_name("claude-opus-5-5") == "Opus 5.5" && model_name("claude-sonnet-4-5-20250929") == "Sonnet 4.5" &&
          model_name("claude-haiku-5-5[1m]") == "Haiku 5.5",
      "model_name");
  chk(dur(261) == "4:21" && dur(3723) == "1:02:03", "dur");
  chk(local_url("npm run dev -- --port 5173 && curl localhost:5173/x") == "http://localhost:5173", "local_url");
  chk(local_url("echo hola").empty(), "sin url");
  chk(one_line("a\n\n b   c") == "a b c", "one_line");
  chk(plain("## Hecho\n**Listo**: `main` ok") == "Hecho\nListo: main ok", "plain");
  chk(fold("Árbol Ñandú") == "arbol nandu", "fold");
  chk(describe("Bash", [] { Json j; parse_json("{\"command\":\"make\",\"description\":\"Compila\"}", j); return j; }()) == "Compila", "describe Bash");
  chk(describe("Edit", [] { Json j; parse_json("{\"file_path\":\"/a/b/Form1.cpp\"}", j); return j; }()) == "Form1.cpp", "describe Edit");

  // Un ~/.claude de mentira: una sesión trabajando (este proceso), otra
  // esperando, una que pregunta, una cerrada y un registro de otro proceso
  // que ya no existe.
  std::string root = config_dir() + "/selftest-claude";
  std::string proj = "/tmp/dms tower/tienda.web";
  std::string pd = root + "/projects/" + slug(proj);
  fl_make_path((root + "/sessions").c_str());
  fl_make_path(pd.c_str());
  for (const auto& n : list_dir(root + "/sessions")) std::remove((root + "/sessions/" + n).c_str());
  double now = now_t();
  int me = my_pid();
  std::string a = "aaaaaaaa-1111-2222-3333-444444444444", b = "bbbbbbbb-1111-2222-3333-444444444444",
              c = "cccccccc-1111-2222-3333-444444444444", d = "dddddddd-1111-2222-3333-444444444444";
  auto reg = [&](int pid, const std::string& id, const std::string& status) {
    write_file(root + "/sessions/" + std::to_string(pid) + ".json",
               "{\"pid\":" + std::to_string(pid) + ",\"sessionId\":\"" + id + "\",\"cwd\":" + jq(proj) +
                   ",\"startedAt\":" + std::to_string((long long)((now - 900) * 1000)) + ",\"kind\":\"interactive\",\"entrypoint\":\"claude-vscode\",\"status\":\"" +
                   status + "\",\"statusUpdatedAt\":" + std::to_string((long long)((now - 30) * 1000)) + ",\"name\":\"tienda\"}");
  };
  reg(me, a, "busy");
  // Otros dos procesos vivos: el padre (quien lanzó la prueba) y el 1.
#ifndef _WIN32
  int parent = (int)getppid();
#else
  int parent = me;
#endif
  reg(parent, b, "idle");
  if (parent != 1) reg(1, c, "idle");
  reg(999999, d, "busy");   // muerto: no cuenta
  // A: trabajando, con tareas, un Bash en marcha y un subagente.
  std::string la;
  put_line(la, "{\"type\":\"ai-title\",\"aiTitle\":\"Arreglar el pago con PayPal\",\"sessionId\":\"" + a + "\"}");
  put_line(la, user_line(now - 600, proj, "Arregla el checkout y prueba el pago"));
  put_line(la, tool_line(now - 590, "t1", "TodoWrite",
                         "{\"todos\":[{\"content\":\"Localizar el checkout\",\"status\":\"completed\"},{\"content\":\"Revisar PayPal\",\"status\":\"in_progress\"},"
                         "{\"content\":\"Escribir las pruebas\",\"status\":\"pending\"},{\"content\":\"Subir\",\"status\":\"pending\"}]}",
                         "m1"));
  put_line(la, result_line(now - 589, "t1", false));
  put_line(la, tool_line(now - 500, "t2", "Edit", "{\"file_path\":\"/x/src/pay.ts\",\"old_string\":\"a\",\"new_string\":\"b\"}", "m2"));
  put_line(la, result_line(now - 499, "t2", false));
  put_line(la, tool_line(now - 400, "t3", "Agent", "{\"description\":\"Revisar las pruebas\",\"subagent_type\":\"general-purpose\",\"prompt\":\"…\"}", "m3"));
  put_line(la, result_line(now - 399, "t3", false, ",\"toolUseResult\":{\"status\":\"async_launched\",\"agentId\":\"abc123\"}"));
  put_line(la, tool_line(now - 300, "t4", "Bash", "{\"command\":\"npm run dev -- --port 3000\",\"description\":\"Arranca el servidor\"}", "m4"));
  put_line(la, result_line(now - 299, "t4", true));
  put_line(la, tool_line(now - 60, "t5", "Bash", "{\"command\":\"npm test\",\"description\":\"Pasa las pruebas\"}", "m5"));
  put_line(la, tool_line(now - 60, "t5b", "Read", "{\"file_path\":\"/x/a.ts\"}", "m5"));   // el mismo mensaje: los tokens, una vez
  put_line(la, result_line(now - 59, "t5b", false));
  write_file(pd + "/" + a + ".jsonl", la);
  fl_make_path((pd + "/" + a + "/subagents").c_str());
  std::string ls;
  put_line(ls, user_line(now - 398, proj, "Revisa las pruebas"));
  put_line(ls, tool_line(now - 20, "s1", "Grep", "{\"pattern\":\"describe\\\\(\"}", "sm1"));
  write_file(pd + "/" + a + "/subagents/agent-abc123.jsonl", ls);
  // B: esperando: terminó su turno.
  std::string lb;
  put_line(lb, user_line(now - 300, proj, "Sube la versión"));
  put_line(lb, tool_line(now - 290, "u1", "Bash", "{\"command\":\"git push\"}", "n1"));
  put_line(lb, result_line(now - 280, "u1", false));
  put_line(lb, text_line(now - 120, "Listo: subida la 1.2.0 a main.", "n2", true));
  write_file(pd + "/" + b + ".jsonl", lb);
  // C: pregunta algo (AskUserQuestion sin contestar).
  std::string lc;
  put_line(lc, user_line(now - 200, proj, "Elige la base de datos"));
  put_line(lc, tool_line(now - 100, "v1", "AskUserQuestion", "{\"questions\":[{\"question\":\"¿PostgreSQL o SQLite?\"}]}", "o1"));
  write_file(pd + "/" + c + ".jsonl", lc);
  // D: cerrada (su proceso ya no existe), de hace una hora.
  std::string ld;
  put_line(ld, user_line(now - 4000, proj, "Haz la portada"));
  put_line(ld, text_line(now - 3600, "Hecha.", "p1", true));
  write_file(pd + "/" + d + ".jsonl", ld);

  Scanner sc(root);
  Snapshot snap = sc.scan(86400);
  auto find = [&](const std::string& id) -> const Session* {
    for (const auto& s : snap.sessions)
      if (s.id == id) return &s;
    return nullptr;
  };
  const Session* A = find(a);
  chk(A && A->open && A->state == ST_WORK, "A trabaja");
  chk(A && A->title == "Arreglar el pago con PayPal", "A título");
  chk(A && A->prompts == 1 && A->prompt == "Arregla el checkout y prueba el pago", "A orden");
  chk(A && A->pending() && A->pending()->name == "Bash" && A->pending()->what == "Pasa las pruebas", "A Bash en marcha");
  chk(A && A->tasks.size() == 4 && A->tasks[0].st == 2 && A->tasks[1].st == 1, "A tareas");
  chk(A && A->url == "http://localhost:3000", "A url");
  chk(A && A->errors == 1, "A un error");
  chk(A && A->calls == 6, "A herramientas");
  chk(A && std::fabs(A->in - 5000) < 1 && std::fabs(A->cr - 250000) < 1, "A tokens una vez por mensaje");
  chk(A && A->subs.size() == 1 && A->subs[0].id == "abc123" && A->subs[0].running && A->subs[0].async, "A subagente");
  chk(A && A->subs.size() == 1 && has(A->subs[0].now, "describe"), "A subagente: su paso");
  chk(A && A->files.size() == 1 && A->files[0].first == "/x/src/pay.ts", "A archivos");
  chk(A && A->branch == "main" && A->entry == "claude-vscode", "A rama");
  chk(A && A->cost > 0, "A coste");
  const Session* B = find(b);
  chk(B && B->open && B->state == ST_WAIT && B->said == "Listo: subida la 1.2.0 a main.", "B espera");
  chk(B && !B->pending(), "B sin pasos en marcha");
  const Session* C = find(c);
  if (parent != 1) chk(C && C->open && C->state == ST_ASK && C->ask == "¿PostgreSQL o SQLite?", "C pregunta");
  const Session* D = find(d);
  chk(D && !D->open && D->state == ST_CLOSED, "D cerrada");
  // Solo las abiertas.
  Snapshot only = sc.scan(0);
  bool d_in = false;
  for (const auto& s : only.sessions) d_in |= s.id == d;
  chk(!d_in, "sin las cerradas");
  // Lo nuevo se lee (y lo viejo no se cuenta dos veces).
  append_file(pd + "/" + a + ".jsonl", result_line(now - 5, "t5", false) + "\n" + text_line(now - 2, "Pruebas en verde.", "m6", true) + "\n");
  write_file(root + "/sessions/" + std::to_string(me) + ".json",
             "{\"pid\":" + std::to_string(me) + ",\"sessionId\":\"" + a + "\",\"cwd\":" + jq(proj) + ",\"status\":\"idle\",\"statusUpdatedAt\":" +
                 std::to_string((long long)(now * 1000)) + "}");
  snap = sc.scan(86400);
  A = find(a);
  chk(A && A->state == ST_WAIT && !A->pending() && A->said == "Pruebas en verde.", "A termina");
  chk(A && A->calls == 6 && A->prompts == 1, "sin contar dos veces");
  // Las tarjetas.
  Settings set;
  std::vector<Report> reps;
  auto cards = cards_of(snap.sessions, reps, set, "", now);
  chk(!cards.empty() && cards.back().sid == d, "las cerradas, al final");
  auto found = cards_of(snap.sessions, reps, set, "paypal", now);
  chk(found.size() == 1 && found[0].sid == a, "buscar");
  Card ca = card_of(*A, now);
  chk(ca.progress == 25 && ca.big == "25 %", "avance de las tareas");
  // Los informes de los agentes.
  Report r;
  chk(parse_report("{\"agente\":\"Checkout\",\"rol\":\"Arregla el pago\",\"estado\":\"trabajando\",\"tarea\":\"Revisando PayPal\","
                   "\"puerto\":3000,\"hechas\":[\"Localizar\"],\"pendientes\":[\"PayPal\",\"Pruebas\"]}",
                   r, now)
              .empty(),
      "informe");
  chk(r.url == "http://localhost:3000" && r.done.size() == 1 && r.todo.size() == 2, "informe: url y listas");
  Card cr = card_of(r, now);
  chk(cr.progress == 33 && cr.state == ST_WORK && cr.tasks.size() == 3 && cr.tasks[1].st == 1, "informe: tarjeta");
  Report en;
  chk(parse_report("{\"agent\":\"API\",\"state\":\"done\",\"progress\":80}", en, now).empty() && card_of(en, now).progress == 100, "informe en inglés");
  chk(parse_report("{\"rol\":\"x\"}", en, now) == tx::R_NO_AGENT, "informe sin agente");
  chk(parse_report("no es json", en, now) == tx::R_BAD_JSON, "informe roto");
  put_report(reps, r);
  r.task = "Escribiendo las pruebas";
  put_report(reps, r);
  chk(reps.size() == 1 && reps[0].task == "Escribiendo las pruebas", "el informe sustituye al anterior");
  // El servidor, de verdad, en un puerto libre.
  Server srv;
  std::atomic<int> got{0};
  srv.on_report = [&](const Report&) { got++; };
  bool up = false;
  int port = 0;
  for (int p = 47900; p < 47950 && !up; p++)
    if (srv.start(p)) { up = true; port = p; }
  chk(up, "el servidor arranca");
  if (up) {
    net_init();
    std::string body = "{\"agente\":\"Pruebas\",\"estado\":\"trabajando\",\"hechas\":[\"a\"],\"pendientes\":[\"b\"]}";
    std::string req = "POST /agentes HTTP/1.1\r\nHost: x\r\nContent-Type: application/json\r\nContent-Length: " + std::to_string(body.size()) + "\r\n\r\n" + body;
    sock_t s = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    std::string resp;
    if (connect(s, (sockaddr*)&addr, sizeof addr) == 0) {
      send(s, req.data(), (int)req.size(), 0);
      char buf[4096];
      int n;
      while ((n = (int)recv(s, buf, sizeof buf, 0)) > 0) resp.append(buf, (size_t)n);
    }
    sock_close(s);
    chk(starts(resp, "HTTP/1.1 200") && has(resp, "\"ok\":true") && got == 1, "POST al servidor");
    std::string g = srv.answer("GET /agentes HTTP/1.1\r\n\r\n");
    chk(has(g, "\"agente\":\"Pruebas\""), "GET del servidor");
    chk(has(srv.answer("POST / HTTP/1.1\r\n\r\n{}"), "400"), "POST sin agente");
    srv.shutdown();
  }
  // Ajustes.
  Settings s2 = parse_settings(settings_text(Settings{2, 1, 50000, false, true}));
  chk(s2.filter == 2 && s2.sort == 1 && s2.port == 50000 && !s2.notify, "ajustes");
  // De verdad: DMS_TOWER_REAL=1 enseña las sesiones de este equipo.
  if (fl_getenv("DMS_TOWER_REAL")) {
    Scanner real(claude_dir());
    double t0 = now_t();
    Snapshot rs = real.scan(86400);
    double t1 = now_t();
    Snapshot again = real.scan(86400);
    std::printf("real: %d sesiones en %.2f s (otra vez, %.3f s)\n", (int)rs.sessions.size(), t1 - t0, now_t() - t1);
    for (const auto& c2 : cards_of(again.sessions, {}, Settings(), "", now_t()))
      std::printf("  [%s] %s | %s | %s: %s | %s | %s\n", c2.chip.c_str(), c2.title.c_str(), one_line(c2.sub, 50).c_str(), c2.now_label.c_str(),
                  one_line(c2.now, 70).c_str(), c2.big.c_str(), c2.facts.c_str());
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

// Datos de ejemplo para las capturas y la prueba de la interfaz.
std::vector<Session> demo_sessions(double now) {
  std::vector<Session> out;
  auto steps = [&](Session& s, std::initializer_list<std::tuple<int, const char*, const char*, int>> v) {
    for (const auto& x : v) {
      Step st;
      st.t = now - std::get<0>(x);
      st.name = std::get<1>(x);
      st.what = std::get<2>(x);
      st.st = std::get<3>(x);
      s.steps.push_back(st);
      s.ticks.push_back(st.t);
    }
  };
  auto ticks = [&](Session& s, int n, int every, int from) {
    for (int i = 0; i < n; i++) s.ticks.push_back(now - from - i * every - (i * 37) % 23);
  };
  Session a;
  a.id = "6f2c1d7e-demo-0001";
  a.cwd = "/Users/ana/Projects/tienda-online";
  a.title = tx::DEMO_A_TITLE;
  a.prompt = tx::DEMO_A_PROMPT;
  a.branch = "fix/checkout";
  a.model = "claude-opus-5-5";
  a.entry = "claude-vscode";
  a.open = true;
  a.status = "busy";
  a.pid = 48213;
  a.first = now - 2900;
  a.turn = now - 261;
  a.last = now - 3;
  a.prompts = 6;
  a.calls = 148;
  a.errors = 2;
  a.in = 52e3;
  a.out = 310e3;
  a.cr = 9.2e6;
  a.cw = 420e3;
  a.cost = 12.84;
  a.ctx = 96e3;
  a.url = "http://localhost:3000";
  a.tasks = {{"", tx::DEMO_T1, 2}, {"", tx::DEMO_T2, 2}, {"", tx::DEMO_T3, 2}, {"", tx::DEMO_T4, 1}, {"", tx::DEMO_T5, 0}, {"", tx::DEMO_T6, 0}};
  ticks(a, 60, 55, 10);
  steps(a, {{240, "Read", "checkout.tsx", 1}, {200, "Edit", "paypal.ts", 1}, {150, "Bash", tx::DEMO_S1, 2}, {90, "Edit", "paypal.ts", 1}, {12, "Bash", tx::DEMO_S2, 0}});
  a.files = {{"/x/src/paypal.ts", 3}, {"/x/src/checkout.tsx", 1}, {"/x/tests/pay.test.ts", 2}};
  a.said = tx::DEMO_A_SAID;
  out.push_back(a);

  Session b;
  b.id = "1a9b8c7d-demo-0002";
  b.cwd = "/Users/ana/Projects/odoo-migracion";
  b.title = tx::DEMO_B_TITLE;
  b.prompt = tx::DEMO_B_PROMPT;
  b.branch = "20.0";
  b.model = "claude-opus-5-5";
  b.entry = "claude-vscode";
  b.open = true;
  b.status = "busy";
  b.pid = 51877;
  b.first = now - 5400;
  b.turn = now - 1830;
  b.last = now - 8;
  b.prompts = 3;
  b.calls = 412;
  b.in = 120e3;
  b.out = 640e3;
  b.cr = 31e6;
  b.cw = 1.1e6;
  b.cost = 41.2;
  b.ctx = 410e3;
  b.url = "http://localhost:18105";
  ticks(b, 90, 38, 20);
  steps(b, {{1800, "Bash", tx::DEMO_S3, 1}, {1700, "Agent", tx::DEMO_SUB1, 1}, {1690, "Agent", tx::DEMO_SUB2, 1}, {1680, "Agent", tx::DEMO_SUB3, 1}});
  Sub s1;
  s1.desc = tx::DEMO_SUB1;
  s1.running = true;
  s1.now = doing("Edit", "base_bim_2/models/project.py");
  s1.steps = 86;
  Sub s2 = s1;
  s2.desc = tx::DEMO_SUB2;
  s2.now = doing("Bash", tx::DEMO_S4, false);
  s2.steps = 54;
  Sub s3 = s1;
  s3.desc = tx::DEMO_SUB3;
  s3.running = false;
  s3.steps = 121;
  b.subs = {s1, s2, s3};
  b.files = {{"/x/canexel_studio/views/sale.xml", 4}, {"/x/base_bim_2/__manifest__.py", 1}};
  b.said = tx::DEMO_B_SAID;
  out.push_back(b);

  Session c;
  c.id = "9e8d7c6b-demo-0003";
  c.cwd = "/Users/ana/Projects/landing";
  c.title = tx::DEMO_C_TITLE;
  c.prompt = tx::DEMO_C_PROMPT;
  c.branch = "main";
  c.model = "claude-sonnet-5-5";
  c.entry = "claude-vscode";
  c.open = true;
  c.status = "idle";
  c.pid = 50112;
  c.first = now - 1500;
  c.turn = now - 400;
  c.last = now - 95;
  c.status_t = now - 95;
  c.prompts = 4;
  c.calls = 37;
  c.in = 20e3;
  c.out = 80e3;
  c.cr = 1.9e6;
  c.cw = 140e3;
  c.cost = 0.92;
  c.ctx = 61e3;
  c.ask = tx::DEMO_C_ASK;
  ticks(c, 30, 40, 100);
  steps(c, {{300, "Read", "page.tsx", 1}, {250, "Grep", "hero", 1}, {96, "AskUserQuestion", tx::DEMO_C_ASK, 0}});
  out.push_back(c);

  Session d;
  d.id = "3c4d5e6f-demo-0004";
  d.cwd = "/Users/ana/Projects/api-pagos";
  d.title = tx::DEMO_D_TITLE;
  d.prompt = tx::DEMO_D_PROMPT;
  d.branch = "main";
  d.model = "claude-opus-5-5";
  d.entry = "cli";
  d.open = true;
  d.status = "idle";
  d.pid = 47002;
  d.first = now - 7000;
  d.turn = now - 900;
  d.ended = now - 420;
  d.last = now - 420;
  d.prompts = 9;
  d.calls = 96;
  d.in = 40e3;
  d.out = 200e3;
  d.cr = 6e6;
  d.cw = 300e3;
  d.cost = 6.1;
  d.ctx = 132e3;
  d.said = tx::DEMO_D_SAID;
  ticks(d, 40, 30, 430);
  steps(d, {{700, "Bash", tx::DEMO_S5, 1}, {600, "Bash", "git push", 1}});
  out.push_back(d);

  Session e;
  e.id = "7a6b5c4d-demo-0005";
  e.cwd = "/Users/ana/Projects/app-movil";
  e.title = tx::DEMO_E_TITLE;
  e.prompt = tx::DEMO_E_PROMPT;
  e.branch = "develop";
  e.model = "claude-sonnet-5-5";
  e.entry = "claude-vscode";
  e.open = false;
  e.first = now - 30000;
  e.last = e.mtime = now - 3 * 3600;
  e.prompts = 12;
  e.calls = 210;
  e.cost = 3.4;
  e.in = 60e3;
  e.out = 180e3;
  e.cr = 4e6;
  out.push_back(e);
  for (auto& s : out) settle(s, now);
  return out;
}
std::vector<Report> demo_reports(double now) {
  Report r;
  parse_report(std::string("{\"agente\":") + jq(tx::DEMO_R_AGENT) + ",\"rol\":" + jq(tx::DEMO_R_ROLE) +
                   ",\"estado\":\"trabajando\",\"tarea\":" + jq(tx::DEMO_R_TASK) + ",\"puerto\":8069,\"hechas\":[" + jq(tx::DEMO_R_D1) + "," +
                   jq(tx::DEMO_R_D2) + "],\"pendientes\":[" + jq(tx::DEMO_R_P1) + "," + jq(tx::DEMO_R_P2) + "," + jq(tx::DEMO_R_P3) + "]}",
               r, now - 40);
  r.first = now - 1250;
  return {r};
}

}  // namespace ct

// ============================================================ la barra de menús
// En macOS, un NSStatusItem hecho desde C++ con el runtime de Objective-C
// (objc_msgSend): las sesiones que trabajan y el menú con cada una. En
// Windows y Linux, la ventana se minimiza.
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsTowerTarget", 0);
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
    msg<void, long>(b, "setImagePosition:", 2);
  }
  msg<void, id>(b, "setTitle:", str(title));
}
struct Size2 {
  double w, h;
};
struct Rect4 {
  double x, y, w, h;
};
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
void menu(const std::vector<ct::MenuEntry>& entries) {
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
    id it = msg<id, id, SEL, id>(msg(cls("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", str(e.title), action, str(""));
    msg<void, id>(it, "setTarget:", target());
    msg<void, long>(it, "setTag:", (long)e.tag);
    msg<void, BOOL>(it, "setEnabled:", e.tag ? YES : NO);
    if (e.checked) msg<void, long>(it, "setState:", 1L);
    if (e.color >= 0) {
      id img = dot_image(ct::state_color(e.color));
      msg<void, id>(it, "setImage:", img);
      msg<void>(img, "release");
    }
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
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
void set(const char*, const std::string&) {}
void menu(const std::vector<ct::MenuEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
// Lo que manda el hilo que lee a la ventana (con Fl::awake).
struct ScanMsg {
  ct::Snapshot snap;
};
struct AgentsUI {
  Fl_Double_Window* win = nullptr;
  Fl_Text_Buffer* buf = nullptr;
  ~AgentsUI() {
    delete win;
    delete buf;
  }
};

class Form1 : public FormDesign {
public:
  ct::Settings set;
  std::vector<ct::Session> sessions;
  std::vector<ct::Report> reports;
  std::vector<ct::Card> cards;
  ct::Totals tot;
  ct::Tower* tower = nullptr;
  Fl_Scroll* scroll = nullptr;
  std::unique_ptr<ct::Server> server;
  std::thread reader;
  std::atomic<bool> cancel{false}, wake{false};
  std::atomic<double> want_window{86400};
  std::mutex mu;
  std::map<std::string, int> last_state;   // para avisar al terminar
  bool in_bar = false, quitting = false, live = true, first_scan = true, no_claude = false;
  double updated = 0, message_until = 0;
  std::string message, server_error;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }
  Form1() {
    if (fl_getenv("DMS_TOWER_SELFTEST")) std::exit(ct::selftest());
    if (fl_getenv("DMS_TOWER_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_TOWER_SHOT")) { set_fonts(); std::exit(shots(d)); }
  }
  ~Form1() override { stop_threads(); }
  static void set_fonts() {
#ifdef _WIN32
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
    Fl::set_font(FL_COURIER, " Consolas");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
    Fl::set_font(FL_COURIER, "Menlo-Regular");
#endif
  }
  static std::string host_name() {
    char b[256] = {0};
#ifdef _WIN32
    DWORD n = sizeof b;
    if (!GetComputerNameA(b, &n)) return "";
#else
    if (gethostname(b, sizeof b - 1) != 0) return "";
#endif
    std::string h = b;
    if (ct::ends(h, ".local")) h = h.substr(0, h.size() - 6);
    return h;
  }

  void setup() {
    self() = this;
    BoardHint->hide();   // el aviso del Diseñador
    Board->box(FL_FLAT_BOX);
    Board->color(ct::rgb(ct::BG));
    Top->resizable(nullptr);
    Top->box(FL_FLAT_BOX);
    resizable(Board);
    size_range(980, 600);
    // Todo oscuro, como la torre de control web.
    Menu1->box(FL_FLAT_BOX);
    Menu1->color(ct::rgb(0x111114));
    Menu1->textcolor(ct::rgb(0xd4d4d8));
    Menu1->selection_color(ct::rgb(0x2f6fea));
    Status->box(FL_FLAT_BOX);
    Status->color(ct::rgb(0x111114));
    Status->labelcolor(ct::rgb(ct::MUTED));
    Status->labelsize(13);
    scroll = new Fl_Scroll(Board->x(), Board->y(), Board->w(), Board->h());
    scroll->type(Fl_Scroll::VERTICAL);
    scroll->box(FL_FLAT_BOX);
    scroll->color(ct::rgb(ct::BG));
    scroll->scrollbar_size(12);
    scroll->scrollbar.color(ct::rgb(0x26262b));
    scroll->scrollbar.selection_color(ct::rgb(0x4a4a52));
    tower = new ct::Tower(Board->x(), Board->y(), Board->w() - 12, Board->h());
    scroll->end();
    Board->add(scroll);
    Board->resizable(scroll);
    tower->host = host_name();
    if (tower->host.empty()) tower->host = tx::THIS_COMPUTER;
    tower->on_act = [](int act, const std::string& key, const std::string& arg) {
      if (self()) self()->card_act(act, key, arg);
    };
    Filter->items({tx::F_OPEN, tx::F_DAY, tx::F_WEEK});
    Sort->items({tx::S_ACTIVITY, tx::S_STATE, tx::S_PROJECT});
    Search->when(FL_WHEN_CHANGED | FL_WHEN_ENTER_KEY_ALWAYS);   // busca al escribir
    // El botón de cerrar esconde la ventana en la barra (si la hay); Esc no
    // hace nada. Un cierre desde el código (el menú Idioma de las demos)
    // cierra de verdad.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE) self()->close_clicked();
      else self()->close_for_good();
    });
  }
  void show_settings_in_ui() {
    Filter->index(set.filter);
    Sort->index(set.sort);
    Notify->checked(set.notify);
  }
  void form_create() override {
    set_fonts();
    Fl::lock();
    setup();
    load();
    show_settings_in_ui();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    else BtnBar->copy_label(tx::MINIMIZE);
    start_server();
    start_reader();
    refresh();
    Fl::add_timeout(0.12, animate, this);
  }
  void form_close() override { save_settings(); }

  // ---- guardar
  std::string settings_file() const { return ct::config_dir() + "/settings.txt"; }
  void load() {
    std::string text;
    if (ct::read_file(settings_file(), text)) set = ct::parse_settings(text);
    if (const char* p = fl_getenv("DMS_TOWER_PORT")) set.port = std::atoi(p);
  }
  void save_settings() {
    if (!live) return;
    fl_make_path(ct::config_dir().c_str());
    ct::write_file(settings_file(), ct::settings_text(set));
  }

  // ---- el hilo que lee y el servidor
  void start_reader() {
    want_window = ct::window_of(set.filter);
    reader = std::thread([this] {
      ct::Scanner sc(ct::claude_dir());
      double last = 0;
      while (!cancel) {
        double now = ct::now_t();
        if (wake.exchange(false) || now - last >= 2) {
          last = now;
          auto* m = new ScanMsg();
          m->snap = sc.scan(want_window.load());
          Fl::awake(on_scan, m);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
      }
    });
  }
  static void on_scan(void* p) {
    std::unique_ptr<ScanMsg> m(static_cast<ScanMsg*>(p));
    if (!self() || self()->cancel) return;
    self()->got_scan(m->snap);
  }
  void got_scan(ct::Snapshot& snap) {
    no_claude = snap.no_claude;
    sessions = std::move(snap.sessions);
    updated = snap.t;
    check_finished();
    first_scan = false;
    refresh();
  }
  void start_server() {
    if (!live || !set.server) return;
    server.reset(new ct::Server());
    server->on_report = [](const ct::Report& r) {
      Fl::awake(on_report, new ct::Report(r));
    };
    server->on_clear = [] { Fl::awake(on_clear, nullptr); };
    if (!server->start(set.port)) {
      server_error = server->error;
      server.reset();
    }
  }
  static void on_report(void* p) {
    std::unique_ptr<ct::Report> r(static_cast<ct::Report*>(p));
    if (!self()) return;
    ct::put_report(self()->reports, *r);
    self()->refresh();
  }
  static void on_clear(void*) {
    if (!self()) return;
    self()->reports.clear();
    self()->refresh();
  }
  void stop_threads() {
    cancel = true;
    if (reader.joinable()) reader.join();
    if (server) server->shutdown();
  }
  std::string agents_url() const { return "http://127.0.0.1:" + std::to_string(set.port) + "/agentes"; }

  // ---- avisos: una sesión que trabajaba y ahora espera o pregunta
  void check_finished() {
    std::map<std::string, int> now_state;
    for (const auto& s : sessions) {
      if (!s.open) continue;
      now_state[s.id] = s.state;
      auto it = last_state.find(s.id);
      if (first_scan || !set.notify || !live || it == last_state.end()) continue;
      if (it->second == ct::ST_WORK && (s.state == ct::ST_WAIT || s.state == ct::ST_ASK || s.state == ct::ST_ERROR)) {
        std::string name = s.cwd.empty() ? s.name : ct::base_name(s.cwd);
        std::string text = s.state == ct::ST_ASK ? ct::fmt(tx::N_ASKS, {name, s.ask.empty() ? std::string(tx::ASKS_PERMISSION) : s.ask})
                                                 : ct::fmt(tx::N_DONE, {name, ct::one_line(s.said, 120)});
        ct::notify(tx::APP, text);
      }
    }
    last_state.swap(now_state);
  }

  // ---- pintar
  void refresh() {
    double now = ct::now_t();
    cards = ct::cards_of(sessions, reports, set, Search->text(), now);
    tot = ct::totals_of(sessions, reports, now);
    tower->cards = cards;
    tower->tot = tot;
    tower->now = now;
    if (no_claude) {
      tower->empty_title = tx::EMPTY_NO_CLAUDE_T;
      tower->empty_text = ct::fmt(tx::EMPTY_NO_CLAUDE_H, {ct::claude_dir()});
    } else if (first_scan && live) {
      tower->empty_title = tx::READING;
      tower->empty_text = tx::READING_HELP;
    } else if (!Search->text().empty() && Search->text()[0]) {
      tower->empty_title = tx::EMPTY_SEARCH_T;
      tower->empty_text = tx::EMPTY_SEARCH_H;
    } else {
      tower->empty_title = tx::EMPTY_T;
      tower->empty_text = tx::EMPTY_H;
    }
    layout();
    update_status();
    if (bar::available()) {
      bar::set(tot.work ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right", " " + ct::bar_title(tot));
      bar::menu(ct::bar_menu(cards, tot, set.notify, shown() && !in_bar));
    }
  }
  void layout() {
    int W = scroll->w() - scroll->scrollbar_size();
    int H = std::max(scroll->h(), tower->content_height(W - 80));
    int yp = scroll->yposition();
    tower->resize(scroll->x(), scroll->y() - yp, W, H);
    scroll->init_sizes();
    if (yp > H - scroll->h()) scroll->scroll_to(0, std::max(0, H - scroll->h()));
    scroll->redraw();
  }
  void resize(int X, int Y, int W, int H) override {
    FormDesign::resize(X, Y, W, H);
    if (tower) layout();
  }
  void say(const std::string& m) {
    message = m;
    message_until = ct::now_t() + 6;
    update_status();
  }
  void update_status() {
    std::string st;
    if (!message.empty() && ct::now_t() < message_until) st = message;
    else {
      std::string up = updated > 0 ? ct::clock_hm(updated) : "—";
      std::string srv = server || !live ? ct::fmt(tx::STATUS_SERVER, {agents_url()}) : server_error.empty() ? std::string(tx::STATUS_NO_SERVER) : server_error;
      st = ct::fmt(tx::STATUS_LINE, {ct::tilde(ct::claude_dir()), up, srv});
    }
    Status->text("  " + st);
  }
  static void animate(void* p) {
    auto* f = static_cast<Form1*>(p);
    if (f->cancel) return;
    bool moving = false;
    for (const auto& c : f->cards) moving |= c.state == ct::ST_WORK || c.state == ct::ST_ASK;
    if (moving && f->shown() && f->visible_r()) {
      f->tower->phase += 0.12;
      f->tower->redraw();
    }
    Fl::repeat_timeout(0.12, animate, p);
  }

  // ---- las tarjetas
  ct::Card* card_by_key(const std::string& key) {
    for (auto& c : cards)
      if (c.key == key) return &c;
    return nullptr;
  }
  void card_act(int act, const std::string& key, const std::string& arg) {
    switch (act) {
      case ct::A_TOGGLE: layout(); break;
      case ct::A_VSCODE:
        if (live) ct::open_in_vscode(arg);
        say(ct::fmt(tx::OPENING_VSCODE, {ct::base_name(arg)}));
        break;
      case ct::A_FOLDER:
        if (live) ct::open_path(arg);
        break;
      case ct::A_URL:
        if (live) ct::open_path(arg);
        break;
      case ct::A_RESUME: {
        ct::Card* c = card_by_key(key);
        std::string cmd = "claude --resume " + arg;
        if (c && !c->cwd.empty()) cmd = "cd " + ct::sh_quote(c->cwd) + " && " + cmd;
        if (live) Fl::copy(cmd.c_str(), (int)cmd.size(), 1);
        say(ct::fmt(tx::COPIED, {cmd}));
        break;
      }
      case ct::A_REMOVE:
        for (size_t i = 0; i < reports.size(); i++)
          if (ct::fold(reports[i].agent) == ct::fold(arg)) {
            reports.erase(reports.begin() + (long)i);
            break;
          }
        if (server) {
          std::lock_guard<std::mutex> g(server->mu);
          server->reports = reports;
        }
        refresh();
        break;
    }
    tower->redraw();
  }

  // ---- los agentes: instrucciones para Claude
  std::string agents_text() const { return ct::fmt(tx::AGENTS_TEXT, {agents_url()}); }
  void make_agents(AgentsUI& ui) {
    ui.win = new Fl_Double_Window(820, 560, tx::AGENTS_TITLE);
    ui.win->color(ct::rgb(ct::BG));
    auto* head = new Fl_Box(24, 16, 772, 30, tx::AGENTS_HEAD);
    head->labelfont(FL_HELVETICA_BOLD);
    head->labelsize(18);
    head->labelcolor(ct::rgb(ct::TEXT));
    head->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
    auto* note = new Fl_Box(24, 48, 772, 44, tx::AGENTS_NOTE);
    note->labelsize(14);
    note->labelcolor(ct::rgb(ct::MUTED));
    note->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_WRAP);
    ui.buf = new Fl_Text_Buffer();
    ui.buf->text(agents_text().c_str());
    auto* td = new Fl_Text_Display(24, 100, 772, 390);
    td->buffer(ui.buf);
    td->textfont(FL_COURIER);
    td->textsize(13);
    td->color(ct::rgb(0x111114));
    td->textcolor(ct::rgb(0xe4e4e7));
    td->box(FL_FLAT_BOX);
    td->wrap_mode(Fl_Text_Display::WRAP_AT_BOUNDS, 0);
    auto* copy = new Fl_Button(24, 508, 300, 36, tx::COPY_AGENTS);
    copy->color(ct::rgb(0x9cc9ec));
    copy->labelcolor(ct::rgb(0x0b2236));
    copy->labelfont(FL_HELVETICA_BOLD);
    copy->callback([](Fl_Widget* w, void*) {
      if (!self()) return;
      std::string t = self()->agents_text();
      if (self()->live) Fl::copy(t.c_str(), (int)t.size(), 1);
      w->copy_label(tx::COPIED_AGENTS);
    });
    auto* close = new Fl_Button(676, 508, 120, 36, tx::CLOSE);
    close->callback([](Fl_Widget* w, void*) { w->window()->hide(); });
    ui.win->end();
    ui.win->set_modal();
  }
  void agents_dialog() {
    AgentsUI ui;
    make_agents(ui);
    ui.win->show();
    while (ui.win->shown()) Fl::wait();
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
    stop_threads();
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
    stop_threads();
    bar::remove();
    hide();
    std::exit(0);
  }
  void bar_act(int t) {
    if (t >= ct::B_SESSION) {
      size_t i = (size_t)(t - ct::B_SESSION);
      if (i < cards.size() && !cards[i].cwd.empty()) {
        if (live) ct::open_in_vscode(cards[i].cwd);
        tower->expanded.insert(cards[i].key);
      }
      return;
    }
    switch (t) {
      case ct::B_WINDOW: from_bar(); break;
      case ct::B_REFRESH: wake = true; break;
      case ct::B_NOTIFY:
        set.notify = !set.notify;
        Notify->checked(set.notify);
        save_settings();
        refresh();
        break;
      case ct::B_QUIT: quit(); break;
    }
  }

  // ---- eventos del diseño
  void set_filter(int i) {
    if (i < 0 || i > 2) return;
    set.filter = i;
    want_window = ct::window_of(i);
    wake = true;
    save_settings();
    refresh();
  }
  void Filter_select() override { set_filter(Filter->index()); }
  void Sort_select() override {
    set.sort = std::max(0, Sort->index());
    save_settings();
    refresh();
  }
  void Search_enter() override { refresh(); }
  void Notify_click() override {
    set.notify = Notify->checked();
    save_settings();
    refresh();
  }
  void BtnAgents_click() override { agents_dialog(); }
  void BtnBar_click() override { to_bar(); }
  void Tick_timer() override {
    // Cada segundo: los relojes de las tarjetas.
    if (in_bar || !shown()) {
      refresh();
      return;
    }
    double now = ct::now_t();
    cards = ct::cards_of(sessions, reports, set, Search->text(), now);
    tower->cards = cards;
    tower->now = now;
    update_status();
    tower->redraw();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_REFRESH) { wake = true; say(tx::REFRESHING); }
    else if (item == tx::MP_AGENTS) agents_dialog();
    else if (item == tx::MP_EXPAND) {
      for (const auto& c : cards) tower->expanded.insert(c.key);
      layout();
    } else if (item == tx::MP_COLLAPSE) {
      tower->expanded.clear();
      layout();
    } else if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_OPEN) set_filter(0);
    else if (item == tx::MP_DAY) set_filter(1);
    else if (item == tx::MP_WEEK) set_filter(2);
    else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
    show_settings_in_ui();
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
    double now = ct::now_t();
    set = ct::Settings();
    show_settings_in_ui();
    sessions = ct::demo_sessions(now);
    reports = ct::demo_reports(now);
    updated = now - 1;
    first_scan = false;
    tower->host = tx::DEMO_HOST;
    tower->phase = 1.0;
    server_error.clear();
    refresh();
  }
  // El escritorio con la barra de menús y el menú del icono abierto.
  void desk(const std::string& file) {
    const int W = 1500, H = 900, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(28 + 60 * t), (uchar)(34 + 40 * t), (uchar)(60 + 50 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(ct::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(ct::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    std::string title = ct::bar_title(tot);
    int ix = W - 620;
    fl_font(FL_HELVETICA, 16);
    int iw = 30 + (int)fl_width(title.c_str()) + 12;
    fl_color(ct::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 8, 5, iw + 8, BarH - 10, 8);
    fl_color(ct::rgb(0x1d1d1f));
    fl_pie(ix + 6, 17, 7, 7, 0, 360);
    fl_line_style(FL_SOLID | FL_CAP_ROUND, 2);
    fl_arc(ix + 1, 12, 17, 17, 35, 145);
    fl_arc(ix - 3, 8, 25, 25, 40, 140);
    fl_line_style(0);
    fl_draw(title.c_str(), ix + 26, 26);
    auto m = ct::bar_menu(cards, tot, set.notify, false);
    const int rowh = 32, seph = 12;
    fl_font(FL_HELVETICA, 15);
    int mw = 300, mh = 12;
    for (const auto& e : m) {
      mw = std::max(mw, std::min(640, (int)fl_width(e.title.c_str()) + 60));
      mh += e.sep ? seph : rowh;
    }
    int x = std::min(ix - 12, W - 12 - mw), y = BarH + 4;
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(30 - 3 * k), (uchar)(36 - 3 * k), (uchar)(60 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, mw + 2 * k, mh + 2 * k, 14 + k);
    }
    ct::round_box(x, y, mw, mh, 14, ct::rgb(0xf3f3f5), ct::rgb(0xc4c4ca));
    int yy = y + 6;
    for (size_t i = 0; i < m.size(); i++) {
      const auto& e = m[i];
      if (e.sep) {
        fl_color(ct::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + mw - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      Fl_Color col = e.tag ? ct::rgb(0x1d1d1f) : ct::rgb(0x6e6e73);
      if (i == 2) {
        fl_color(ct::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, mw - 12, rowh, 8);
        col = FL_WHITE;
      }
      int tx0 = x + 28;
      if (e.checked) {
        fl_color(col);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_draw("✓", x + 10, yy + 22);
      }
      if (e.color >= 0) {
        fl_color(ct::rgb(ct::state_color(e.color)));
        fl_pie(x + 28, yy + rowh / 2 - 5, 10, 10, 0, 360);
        tx0 = x + 46;
      }
      fl_font(FL_HELVETICA, 15);
      fl_color(col);
      fl_draw(ct::fit(e.title, mw - (tx0 - x) - 16).c_str(), tx0, yy + 22);
      yy += rowh;
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1280, 860);
    render_to(dir + "/window.png");
    // Con el detalle de la primera y de la de los subagentes.
    tower->expanded.insert(cards[0].key);
    for (const auto& c : cards)
      if (!c.subs.empty()) tower->expanded.insert(c.key);
    layout();
    render_to(dir + "/expanded.png");
    tower->expanded.clear();
    // Un agente que informa, con su detalle.
    for (const auto& c : cards)
      if (c.report) tower->expanded.insert(c.key);
    layout();
    int ry = 0, yy = 28 + ct::Tower::HEADER;
    for (const auto& c : cards) {
      if (c.report) { ry = yy; break; }
      yy += tower->card_height(c, tower->w() - 80) + 16;
    }
    scroll->scroll_to(0, std::max(0, ry - 160));
    render_to(dir + "/agents.png");
    scroll->scroll_to(0, 0);
    tower->expanded.clear();
    layout();
    desk(dir + "/menu.png");
    AgentsUI ui;
    make_agents(ui);
    render_group(ui.win, dir + "/instructions.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1280, 860);
    int f = 0;
    auto chk = [&](bool ok, const char* what) {
      if (!ok) { std::printf("FAIL %s\n", what); f++; }
    };
    render_to("");
    chk(cards.size() == 6, "seis tarjetas (cinco sesiones y un agente)");
    chk(tot.open == 4 && tot.work == 2 && tot.ask == 1 && tot.wait == 1, "las cuentas de arriba");
    chk(cards[0].state == ct::ST_WORK && cards.back().state == ct::ST_CLOSED, "abiertas primero, cerradas al final");
    // Un clic en una tarjeta la abre y enseña el detalle.
    int h0 = tower->content_height(tower->w() - 80);
    const ct::Hit* first = nullptr;
    for (const auto& h : tower->hits)
      if (h.act == ct::A_TOGGLE && h.key == cards[0].key) { first = &h; break; }
    chk(first != nullptr, "la tarjeta se puede pulsar");
    if (first) {
      Fl::e_x = first->x + 40;
      Fl::e_y = first->y + 30;
      tower->handle(FL_PUSH);
    }
    chk(tower->expanded.count(cards[0].key) == 1, "clic: ver más");
    chk(tower->content_height(tower->w() - 80) > h0, "el detalle ocupa sitio");
    render_to("");
    bool vs = false, res = false;
    for (const auto& h : tower->hits) {
      vs |= h.act == ct::A_VSCODE && h.arg == cards[0].cwd;
      res |= h.act == ct::A_RESUME;
    }
    chk(vs && res, "botones del detalle");
    // Copiar «claude --resume» (sin tocar el portapapeles en la prueba).
    card_act(ct::A_RESUME, cards[0].key, cards[0].sid);
    chk(ct::has(message, "claude --resume " + cards[0].sid), "copiar la orden");
    // Buscar.
    Search->value("odoo");
    Search_enter();
    chk(cards.size() == 1 && ct::has(cards[0].cwd, "odoo"), "buscar");
    Search->value("nada-que-se-parezca");
    Search_enter();
    chk(cards.empty() && tower->empty_title == tx::EMPTY_SEARCH_T, "buscar sin resultados");
    Search->value("");
    Search_enter();
    // Solo las abiertas.
    Filter->index(0);
    Filter_select();
    bool closed = false;
    for (const auto& c : cards) closed |= !c.open;
    chk(!closed && set.filter == 0, "solo las abiertas");
    Filter->index(1);
    Filter_select();
    // Por estado: la que pregunta, primero.
    Sort->index(1);
    Sort_select();
    chk(cards[0].state == ct::ST_ASK, "por estado");
    Sort->index(2);
    Sort_select();
    chk(ct::fold(cards[0].title) <= ct::fold(cards[1].title), "por proyecto");
    // El menú de la barra: una entrada por sesión abierta.
    auto m = ct::bar_menu(cards, tot, true, true);
    int sess = 0;
    for (const auto& e : m) sess += e.tag >= ct::B_SESSION;
    chk(sess == 4, "el menú de la barra");
    chk(ct::bar_title(tot) == ct::fmt(tx::BAR_ASK, {"2", "4", "1"}), "el título de la barra");
    bar_act(ct::B_NOTIFY);
    chk(!set.notify && !Notify->checked(), "avisos desde la barra");
    // Quitar un agente.
    std::string agent;
    for (const auto& c : cards)
      if (c.report) agent = c.title;
    card_act(ct::A_REMOVE, "", agent);
    chk(reports.empty(), "quitar un agente");
    // Avisar al terminar: de trabajar a esperar.
    set.notify = true;
    last_state.clear();
    first_scan = false;
    for (const auto& s : sessions) last_state[s.id] = ct::ST_WORK;
    check_finished();
    chk(last_state.size() == 4, "estado guardado para avisar");
    AgentsUI ui;
    make_agents(ui);
    chk(ct::has(agents_text(), agents_url()) && ct::has(agents_text(), "curl"), "instrucciones para los agentes");
    render_to("");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
