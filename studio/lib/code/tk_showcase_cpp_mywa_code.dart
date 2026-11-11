part of 'tk_examples.dart';

// El código en C++ de MyWhatsapp (tk_showcase_cpp_mywa.dart): va tal cual en
// Form1.cpp, después de los textos (namespace tx).
const _mywaIncludes = r'''#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
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
#include <thread>
#include <vector>
#include <FL/Fl_Box.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_BMP_Image.H>
#include <FL/Fl_JPEG_Image.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#include <cerrno>
#include <csignal>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _mywaCode = r'''
// ============================================================ los datos
namespace wa {

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
bool starts(const std::string& s, const std::string& p) { return s.size() >= p.size() && s.compare(0, p.size(), p) == 0; }
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
// Para medir intervalos (avisos, cada cuántos segundos): no es la fecha.
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
// La fecha y hora de verdad (segundos Unix): para comparar con los mensajes.
long long wall_s() { return (long long)std::time(nullptr); }
std::string clock_time(long long t) {
  if (t <= 0) return "";
  time_t tt = (time_t)t;
  struct tm v;
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  char b[32];
  std::strftime(b, sizeof b, "%H:%M", &v);
  return b;
}
std::string day_text(long long t) {
  if (t <= 0) return "";
  time_t tt = (time_t)t;
  struct tm v;
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  char b[32];
  std::strftime(b, sizeof b, "%d/%m/%y", &v);
  return b;
}

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_MYWA_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\mywhatsapp";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/mywhatsapp";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/mywhatsapp";
#endif
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  std::fclose(f);
  return true;
}
bool write_file(const std::string& path, const std::string& data) {
#ifndef _WIN32
  mode_t old = umask(077);   // solo el usuario puede leerlo
#endif
  FILE* f = fl_fopen(path.c_str(), "wb");
#ifndef _WIN32
  umask(old);
#endif
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  return std::fclose(f) == 0 && ok;
}

// ------------------------------------------------------------ JSON
// Lo justo para hablar con las API: un valor JSON, leerlo y escribir textos.
struct Json {
  enum Type { NUL, BOOL, NUM, STR, ARR, OBJ } type = NUL;
  bool b = false;
  double n = 0;
  std::string s;
  std::vector<Json> a;
  std::vector<std::pair<std::string, Json>> o;
  const Json& operator[](const std::string& k) const {
    static const Json none;
    for (const auto& kv : o)
      if (kv.first == k) return kv.second;
    return none;
  }
  const Json& operator[](size_t i) const {
    static const Json none;
    return i < a.size() ? a[i] : none;
  }
  std::string str() const { return type == STR ? s : ""; }
};
struct JsonParser {
  const std::string& t;
  size_t i = 0;
  bool ok = true;
  explicit JsonParser(const std::string& text) : t(text) {}
  void ws() {
    while (i < t.size() && (t[i] == ' ' || t[i] == '\n' || t[i] == '\r' || t[i] == '\t')) i++;
  }
  static void put_utf8(std::string& o, unsigned cp) {
    char b[8];
    int n = fl_utf8encode(cp, b);
    o.append(b, (size_t)n);
  }
  std::string string() {
    std::string o;
    i++;   // "
    while (i < t.size() && t[i] != '"') {
      char c = t[i++];
      if (c != '\\') { o += c; continue; }
      if (i >= t.size()) break;
      char e = t[i++];
      switch (e) {
        case 'n': o += '\n'; break;
        case 't': o += '\t'; break;
        case 'r': o += '\r'; break;
        case 'b': o += '\b'; break;
        case 'f': o += '\f'; break;
        case 'u': {
          unsigned cp = (unsigned)std::strtoul(t.substr(i, 4).c_str(), nullptr, 16);
          i += 4;
          if (cp >= 0xD800 && cp < 0xDC00 && i + 6 <= t.size() && t[i] == '\\' && t[i + 1] == 'u') {
            unsigned lo = (unsigned)std::strtoul(t.substr(i + 2, 4).c_str(), nullptr, 16);
            cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
            i += 6;
          }
          put_utf8(o, cp);
          break;
        }
        default: o += e;
      }
    }
    if (i < t.size()) i++;
    else ok = false;
    return o;
  }
  Json value() {
    ws();
    Json v;
    if (i >= t.size()) { ok = false; return v; }
    char c = t[i];
    if (c == '{') {
      v.type = Json::OBJ;
      i++;
      ws();
      if (i < t.size() && t[i] == '}') { i++; return v; }
      while (ok && i < t.size()) {
        ws();
        if (t[i] != '"') { ok = false; break; }
        std::string k = string();
        ws();
        if (i >= t.size() || t[i] != ':') { ok = false; break; }
        i++;
        v.o.push_back({k, value()});
        ws();
        if (i < t.size() && t[i] == ',') { i++; continue; }
        if (i < t.size() && t[i] == '}') { i++; break; }
        ok = false;
      }
    } else if (c == '[') {
      v.type = Json::ARR;
      i++;
      ws();
      if (i < t.size() && t[i] == ']') { i++; return v; }
      while (ok && i < t.size()) {
        v.a.push_back(value());
        ws();
        if (i < t.size() && t[i] == ',') { i++; continue; }
        if (i < t.size() && t[i] == ']') { i++; break; }
        ok = false;
      }
    } else if (c == '"') {
      v.type = Json::STR;
      v.s = string();
    } else if (starts(t.substr(i, 4), "true")) {
      v.type = Json::BOOL;
      v.b = true;
      i += 4;
    } else if (starts(t.substr(i, 5), "false")) {
      v.type = Json::BOOL;
      i += 5;
    } else if (starts(t.substr(i, 4), "null")) {
      i += 4;
    } else {
      v.type = Json::NUM;
      size_t a = i;
      while (i < t.size() && (std::isdigit((unsigned char)t[i]) || t[i] == '-' || t[i] == '+' || t[i] == '.' || t[i] == 'e' || t[i] == 'E')) i++;
      if (a == i) { ok = false; return v; }
      v.n = std::strtod(t.substr(a, i - a).c_str(), nullptr);
    }
    return v;
  }
};
Json parse_json(const std::string& text, bool* ok = nullptr) {
  JsonParser p(text);
  Json v = p.value();
  if (ok) *ok = p.ok;
  return v;
}
// Un texto como cadena JSON.
std::string jstr(const std::string& s) {
  std::string o = "\"";
  for (unsigned char c : s) {
    switch (c) {
      case '"': o += "\\\""; break;
      case '\\': o += "\\\\"; break;
      case '\n': o += "\\n"; break;
      case '\r': o += "\\r"; break;
      case '\t': o += "\\t"; break;
      default:
        if (c < 0x20) {
          char b[8];
          std::snprintf(b, sizeof b, "\\u%04x", c);
          o += b;
        } else {
          o += (char)c;
        }
    }
  }
  return o + "\"";
}

// ------------------------------------------------------------ los chats
// Los tipos de mensaje de WhatsApp que se enseñan (ZMESSAGETYPE).
enum Kind { K_TEXT = 0, K_IMAGE = 1, K_VIDEO = 2, K_AUDIO = 3, K_DOC = 8, K_GIF = 11, K_STICKER = 15 };
struct Msg {
  bool mine = false;
  std::string who, text;   // who: en los grupos, quién lo escribió
  long long t = 0;
  int kind = K_TEXT;
  std::string media, title;   // media: el archivo en este equipo ("" si no está)
  long long size = 0;
  std::string id;   // el de WhatsApp (los que llegan por el puente)
  std::string trans;   // traducido (lo recibido) o el original que escribí (lo enviado)
  std::string phone;   // en los grupos, el teléfono de quien escribe (si se sabe)
};
struct Chat {
  long long id = 0;
  std::string name, jid, last, pic;   // pic: la foto de perfil en este equipo
  long long last_t = 0;
  int unread = 0;
  bool group = false;
  bool live = false;   // llegó por el puente (no está en WhatsApp Desktop)
  bool archived = false;    // archivado en WhatsApp
  bool last_mine = false;   // el último mensaje lo escribí yo
  std::vector<Msg> msgs;   // los últimos, del más antiguo al más nuevo
};
// La fecha de WhatsApp (segundos desde el 1 de enero de 2001) → Unix.
long long apple_time(double v) { return v > 0 ? (long long)v + 978307200LL : 0; }
// «34600111222@s.whatsapp.net» → «34600111222» ("" en los grupos).
std::string phone_of(const std::string& jid) {
  size_t at = jid.find('@');
  if (at == std::string::npos || jid.find("@s.whatsapp.net") == std::string::npos) return "";
  std::string p = jid.substr(0, at);
  for (char c : p)
    if (!std::isdigit((unsigned char)c)) return "";
  return p;
}
// El país de un teléfono por su prefijo (el más largo que encaje): su código
// ISO (para la bandera) y su zona horaria.
struct Country {
  const char* prefix;
  const char* iso;
  const char* tz;
};
const Country* country_of(const std::string& phone) {
  static const Country list[] = {
      {"1809", "DO", "America/Santo_Domingo"}, {"1829", "DO", "America/Santo_Domingo"}, {"1849", "DO", "America/Santo_Domingo"},
      {"1787", "PR", "America/Puerto_Rico"}, {"1939", "PR", "America/Puerto_Rico"}, {"1", "US", "America/New_York"},
      {"7", "RU", "Europe/Moscow"}, {"20", "EG", "Africa/Cairo"}, {"27", "ZA", "Africa/Johannesburg"},
      {"30", "GR", "Europe/Athens"}, {"31", "NL", "Europe/Amsterdam"}, {"32", "BE", "Europe/Brussels"},
      {"33", "FR", "Europe/Paris"}, {"34", "ES", "Europe/Madrid"}, {"351", "PT", "Europe/Lisbon"},
      {"353", "IE", "Europe/Dublin"}, {"358", "FI", "Europe/Helsinki"}, {"380", "UA", "Europe/Kyiv"},
      {"39", "IT", "Europe/Rome"}, {"41", "CH", "Europe/Zurich"}, {"43", "AT", "Europe/Vienna"},
      {"44", "GB", "Europe/London"}, {"45", "DK", "Europe/Copenhagen"}, {"46", "SE", "Europe/Stockholm"},
      {"47", "NO", "Europe/Oslo"}, {"48", "PL", "Europe/Warsaw"}, {"49", "DE", "Europe/Berlin"},
      {"502", "GT", "America/Guatemala"}, {"503", "SV", "America/El_Salvador"}, {"504", "HN", "America/Tegucigalpa"},
      {"505", "NI", "America/Managua"}, {"506", "CR", "America/Costa_Rica"}, {"507", "PA", "America/Panama"},
      {"509", "HT", "America/Port-au-Prince"}, {"51", "PE", "America/Lima"}, {"52", "MX", "America/Mexico_City"},
      {"53", "CU", "America/Havana"}, {"54", "AR", "America/Argentina/Buenos_Aires"}, {"55", "BR", "America/Sao_Paulo"},
      {"56", "CL", "America/Santiago"}, {"57", "CO", "America/Bogota"}, {"58", "VE", "America/Caracas"},
      {"591", "BO", "America/La_Paz"}, {"593", "EC", "America/Guayaquil"}, {"595", "PY", "America/Asuncion"},
      {"598", "UY", "America/Montevideo"}, {"60", "MY", "Asia/Kuala_Lumpur"}, {"61", "AU", "Australia/Sydney"},
      {"62", "ID", "Asia/Jakarta"}, {"63", "PH", "Asia/Manila"}, {"64", "NZ", "Pacific/Auckland"},
      {"65", "SG", "Asia/Singapore"}, {"66", "TH", "Asia/Bangkok"}, {"81", "JP", "Asia/Tokyo"},
      {"82", "KR", "Asia/Seoul"}, {"84", "VN", "Asia/Ho_Chi_Minh"}, {"86", "CN", "Asia/Shanghai"},
      {"90", "TR", "Europe/Istanbul"}, {"91", "IN", "Asia/Kolkata"}, {"92", "PK", "Asia/Karachi"},
      {"212", "MA", "Africa/Casablanca"}, {"234", "NG", "Africa/Lagos"}, {"254", "KE", "Africa/Nairobi"},
      {"880", "BD", "Asia/Dhaka"}, {"966", "SA", "Asia/Riyadh"}, {"971", "AE", "Asia/Dubai"},
      {"972", "IL", "Asia/Jerusalem"}};
  const Country* best = nullptr;
  size_t len = 0;
  for (const auto& c : list) {
    size_t l = std::strlen(c.prefix);
    if (phone.size() > l + 4 && phone.compare(0, l, c.prefix) == 0 && l > len) {
      best = &c;
      len = l;
    }
  }
  return best;
}
// «AR» → 🇦🇷 (dos letras «indicador regional» en UTF-8).
std::string flag_of(const char* iso) {
  std::string out;
  for (int i = 0; i < 2 && iso[i]; i++) {
    unsigned cp = 0x1F1E6 + (unsigned)(iso[i] - 'A');
    out += (char)(0xF0 | (cp >> 18));
    out += (char)(0x80 | ((cp >> 12) & 0x3F));
    out += (char)(0x80 | ((cp >> 6) & 0x3F));
    out += (char)(0x80 | (cp & 0x3F));
  }
  return out;
}
// La hora (HH:MM) en una zona, con la base de zonas del sistema ("" si no la hay).
std::string time_in(const char* tz, long long t) {
#ifdef _WIN32
  (void)tz;
  (void)t;
  return "";
#else
  if (fl_access((std::string("/usr/share/zoneinfo/") + tz).c_str(), 0) != 0) return "";
  const char* old = getenv("TZ");
  std::string keep = old ? old : "";
  setenv("TZ", tz, 1);
  tzset();
  time_t tt = (time_t)t;
  struct tm v;
  localtime_r(&tt, &v);
  if (old) setenv("TZ", keep.c_str(), 1);
  else unsetenv("TZ");
  tzset();
  char b[8];
  std::strftime(b, sizeof b, "%H:%M", &v);
  return b;
#endif
}
// Los países de un chat: el del teléfono o, en un grupo, los de quienes escriben
// (hasta tres, de más a menos mensajes).
std::vector<const Country*> chat_countries(const Chat& c) {
  std::vector<const Country*> out;
  if (!c.group) {
    if (const Country* k = country_of(phone_of(c.jid))) out.push_back(k);
    return out;
  }
  std::map<const Country*, int> n;
  for (const auto& m : c.msgs)
    if (!m.mine && !m.phone.empty())
      if (const Country* k = country_of(m.phone)) n[k]++;
  std::vector<std::pair<int, const Country*>> v;
  for (const auto& kv : n) v.push_back({kv.second, kv.first});
  std::sort(v.begin(), v.end(), [](const std::pair<int, const Country*>& a, const std::pair<int, const Country*>& b) {
    return a.first != b.first ? a.first > b.first : std::strcmp(a.second->iso, b.second->iso) < 0;
  });
  for (size_t i = 0; i < v.size() && i < 3; i++) out.push_back(v[i].second);
  return out;
}
std::string url_encode(const std::string& s) {
  std::string o;
  for (unsigned char c : s) {
    if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') o += (char)c;
    else {
      char b[4];
      std::snprintf(b, sizeof b, "%%%02X", c);
      o += b;
    }
  }
  return o;
}

// ---- un chat exportado («Exportar chat», sin archivos): iPhone o Android
//   [11/11/26, 17:02:15] Laura: Hola      (iPhone)
//   11/11/26, 17:02 - Laura: Hola         (Android)
bool parse_export_line(const std::string& raw, std::string& who, std::string& text, long long& t) {
  std::string l = raw;
  // iPhone pone a veces una marca invisible al principio.
  if (starts(l, "\xE2\x80\x8E")) l = l.substr(3);
  size_t head_end = std::string::npos, name_at = 0;
  if (!l.empty() && l[0] == '[') {
    head_end = l.find("] ");
    if (head_end == std::string::npos) return false;
    name_at = head_end + 2;
  } else {
    head_end = l.find(" - ");
    if (head_end == std::string::npos || head_end > 24) return false;
    name_at = head_end + 3;
  }
  std::string head = l.substr(l[0] == '[' ? 1 : 0, l[0] == '[' ? head_end - 1 : head_end);
  // La fecha: d/m/aa (o d/m/aaaa), y la hora.
  int d = 0, m = 0, y = 0, hh = 0, mm = 0, ss = 0;
  char sep1 = 0;
  if (std::sscanf(head.c_str(), "%d/%d/%d%c %d:%d:%d", &d, &m, &y, &sep1, &hh, &mm, &ss) < 6) return false;
  if (y < 100) y += 2000;
  std::string rest = l.substr(name_at);
  size_t colon = rest.find(": ");
  if (colon == std::string::npos) return false;   // un aviso del sistema
  who = rest.substr(0, colon);
  text = rest.substr(colon + 2);
  struct tm v{};
  v.tm_year = y - 1900;
  v.tm_mon = m - 1;
  v.tm_mday = d;
  v.tm_hour = hh;
  v.tm_min = mm;
  v.tm_sec = ss;
  v.tm_isdst = -1;
  t = (long long)std::mktime(&v);
  return true;
}
// [me]: su nombre en el chat; si está vacío, quien no es [other].
Chat parse_export(const std::string& data, const std::string& name, std::string me) {
  Chat c;
  c.name = name;
  c.id = -1;
  std::map<std::string, int> count;
  for (const auto& line : split(data, '\n')) {
    std::string who, text;
    long long t = 0;
    std::string l = line;
    if (!l.empty() && l.back() == '\r') l.pop_back();
    if (parse_export_line(l, who, text, t)) {
      Msg m;
      m.who = who;
      m.text = text;
      m.t = t;
      c.msgs.push_back(m);
      count[who]++;
    } else if (!c.msgs.empty() && !trim(l).empty()) {
      c.msgs.back().text += "\n" + l;   // un mensaje de varias líneas
    }
  }
  if (me.empty())
    for (const auto& kv : count)
      if (kv.first != name) me = kv.first;
  c.group = count.size() > 2;
  for (auto& m : c.msgs) {
    m.mine = m.who == me;
    if (!c.group) m.who.clear();
  }
  if (!c.msgs.empty()) {
    c.last = c.msgs.back().text;
    c.last_t = c.msgs.back().t;
  }
  return c;
}
// «Chat de WhatsApp con Laura.txt» → «Laura».
std::string export_name(const std::string& path) {
  std::string f = path.substr(path.find_last_of("/\\") + 1);
  if (f.size() > 4 && lower(f.substr(f.size() - 4)) == ".txt") f = f.substr(0, f.size() - 4);
  for (const char* p : {"Chat de WhatsApp con ", "WhatsApp Chat with ", "WhatsApp Chat - "})
    if (starts(f, p)) return f.substr(std::strlen(p));
  return f;
}

// ------------------------------------------------------------ WhatsApp Desktop
// macOS: los chats que WhatsApp Desktop guarda en su base de datos SQLite,
// leídos sin cambiar nada. SQLite viene con el sistema y se abre con dlopen.
#ifndef _WIN32
struct Sqlite {
  void* lib = nullptr;
  int (*open_v2)(const char*, void**, int, const char*) = nullptr;
  int (*prepare_v2)(void*, const char*, int, void**, const char**) = nullptr;
  int (*step)(void*) = nullptr;
  const unsigned char* (*column_text)(void*, int) = nullptr;
  long long (*column_int64)(void*, int) = nullptr;
  double (*column_double)(void*, int) = nullptr;
  int (*bind_int64)(void*, int, long long) = nullptr;
  int (*finalize)(void*) = nullptr;
  int (*close)(void*) = nullptr;
  int (*exec)(void*, const char*, void*, void*, char**) = nullptr;
  bool load() {
    if (lib) return true;
    for (const char* n : {"/usr/lib/libsqlite3.dylib", "libsqlite3.dylib", "libsqlite3.so.0", "libsqlite3.so"}) {
      lib = dlopen(n, RTLD_NOW);
      if (lib) break;
    }
    if (!lib) return false;
    open_v2 = (decltype(open_v2))dlsym(lib, "sqlite3_open_v2");
    prepare_v2 = (decltype(prepare_v2))dlsym(lib, "sqlite3_prepare_v2");
    step = (decltype(step))dlsym(lib, "sqlite3_step");
    column_text = (decltype(column_text))dlsym(lib, "sqlite3_column_text");
    column_int64 = (decltype(column_int64))dlsym(lib, "sqlite3_column_int64");
    column_double = (decltype(column_double))dlsym(lib, "sqlite3_column_double");
    bind_int64 = (decltype(bind_int64))dlsym(lib, "sqlite3_bind_int64");
    finalize = (decltype(finalize))dlsym(lib, "sqlite3_finalize");
    close = (decltype(close))dlsym(lib, "sqlite3_close");
    exec = (decltype(exec))dlsym(lib, "sqlite3_exec");
    return open_v2 && prepare_v2 && step && column_text && column_int64 && column_double && bind_int64 && finalize && close && exec;
  }
};
Sqlite& sqlite() {
  static Sqlite s;
  return s;
}
const int SQLITE_ROW_ = 100;
const int OPEN_READONLY = 0x00000001, OPEN_READWRITE = 0x00000002, OPEN_CREATE = 0x00000004, OPEN_URI = 0x00000040;
std::string col(void* st, int i) {
  const unsigned char* p = sqlite().column_text(st, i);
  return p ? (const char*)p : "";
}
#endif

std::string db_path() {
  if (const char* o = fl_getenv("DMS_MYWA_DB")) return o;
#ifdef __APPLE__
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/ChatStorage.sqlite";
#else
  return "";
#endif
}
// La carpeta de WhatsApp (donde está la base de datos).
std::string base_dir(const std::string& db) {
  size_t p = db.find_last_of("/\\");
  return p == std::string::npos ? "." : db.substr(0, p);
}
bool file_exists(const std::string& p) { return !p.empty() && fl_access(p.c_str(), 0) == 0; }
bool db_exists() {
  std::string p = db_path();
  return !p.empty() && fl_access(p.c_str(), 0) == 0;
}

const char* kind_icon(int k);
std::string kind_name(int k);

// Los chats (sin los mensajes) y los mensajes de uno: solo lectura.
bool load_chats(const std::string& path, std::vector<Chat>& out, std::string& error) {
  out.clear();
#ifdef _WIN32
  (void)path;
  error = tx::ERR_NO_DB;
  return false;
#else
  Sqlite& q = sqlite();
  if (!q.load()) { error = tx::ERR_NO_SQLITE; return false; }
  void* db = nullptr;
  std::string uri = "file:" + path + "?mode=ro";
  if (q.open_v2(uri.c_str(), &db, OPEN_READONLY | OPEN_URI, nullptr) != 0) {
    error = tx::ERR_OPEN_DB;
    if (db) q.close(db);
    return false;
  }
  void* st = nullptr;
  const char* sql =
      // El resumen sale del último mensaje (ZLASTMESSAGETEXT ya no es texto en
      // las versiones nuevas de WhatsApp): su texto, su tipo y el adjunto.
      "SELECT s.Z_PK, s.ZPARTNERNAME, s.ZCONTACTJID, s.ZLASTMESSAGEDATE, "
      "IFNULL((SELECT m.ZTEXT FROM ZWAMESSAGE m WHERE m.ZCHATSESSION = s.Z_PK ORDER BY m.ZMESSAGEDATE DESC LIMIT 1), ''), "
      "s.ZUNREADCOUNT, "
      "IFNULL((SELECT p.ZPATH FROM ZWAPROFILEPICTUREITEM p WHERE p.ZJID = s.ZCONTACTJID AND p.ZPATH IS NOT NULL LIMIT 1), ''), "
      "IFNULL((SELECT m.ZMESSAGETYPE FROM ZWAMESSAGE m WHERE m.ZCHATSESSION = s.Z_PK ORDER BY m.ZMESSAGEDATE DESC LIMIT 1), 0), "
      "IFNULL((SELECT IFNULL(i.ZTITLE, '') FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK "
      "WHERE m.ZCHATSESSION = s.Z_PK ORDER BY m.ZMESSAGEDATE DESC LIMIT 1), ''), "
      "IFNULL(s.ZARCHIVED, 0), "
      "IFNULL((SELECT m.ZISFROMME FROM ZWAMESSAGE m WHERE m.ZCHATSESSION = s.Z_PK ORDER BY m.ZMESSAGEDATE DESC LIMIT 1), 0) "
      "FROM ZWACHATSESSION s WHERE IFNULL(s.ZREMOVED,0)=0 AND IFNULL(s.ZHIDDEN,0)=0 "
      "AND s.ZCONTACTJID NOT LIKE '%status%' AND s.ZLASTMESSAGEDATE IS NOT NULL "
      "ORDER BY s.ZLASTMESSAGEDATE DESC";
  if (q.prepare_v2(db, sql, -1, &st, nullptr) != 0) {
    // Sin permiso, macOS deja abrir el archivo pero no leerlo.
    error = tx::ERR_READ_DB;
    q.close(db);
    return false;
  }
  while (q.step(st) == SQLITE_ROW_) {
    Chat c;
    c.id = q.column_int64(st, 0);
    c.name = col(st, 1);
    c.jid = col(st, 2);
    c.last_t = apple_time(q.column_double(st, 3));
    c.last = col(st, 4);
    c.unread = (int)q.column_int64(st, 5);
    c.archived = q.column_int64(st, 9) != 0;
    c.last_mine = q.column_int64(st, 10) != 0;
    int last_kind = (int)q.column_int64(st, 7);
    std::string last_title = col(st, 8);
    if (last_kind == K_IMAGE || last_kind == K_VIDEO || last_kind == K_AUDIO || last_kind == K_DOC || last_kind == K_GIF ||
        last_kind == K_STICKER) {
      // «📷 Foto», «📄 contrato.pdf» (y su texto, si lleva).
      std::string label = std::string(kind_icon(last_kind)) + " " + (last_title.empty() ? kind_name(last_kind) : last_title);
      c.last = c.last.empty() ? label : label + " · " + c.last;
    }
    c.group = c.jid.find("@g.us") != std::string::npos;
    if (c.name.empty()) c.name = phone_of(c.jid).empty() ? c.jid : "+" + phone_of(c.jid);
    // La foto: «Media/Profile/…» + «.thumb» (96×96) o «.jpg».
    std::string pic = col(st, 6);
    if (!pic.empty()) {
      std::string b = base_dir(path) + "/" + pic;
      if (file_exists(b + ".thumb")) c.pic = b + ".thumb";
      else if (file_exists(b + ".jpg")) c.pic = b + ".jpg";
    }
    out.push_back(c);
  }
  q.finalize(st);
  q.close(db);
  return true;
#endif
}
// ¿Un texto codificado (lo que guarda ahora WhatsApp en ZPUSHNAME)?
bool looks_encoded(const std::string& s) {
  if (s.size() < 24 || s.find(' ') != std::string::npos) return false;
  for (unsigned char ch : s)
    if (!(std::isalnum(ch) || ch == '+' || ch == '/' || ch == '=')) return false;
  return true;
}
// Quién escribe en un grupo: el nombre de la agenda, el del grupo, el de su
// perfil («~ Ana», como WhatsApp) o su teléfono.
std::string sender_name(const std::string& book, const std::string& first, const std::string& push,
                        const std::string& member_jid, const std::string& raw_push) {
  if (!trim(book).empty()) return trim(book);
  if (!trim(first).empty()) return trim(first);
  if (!trim(push).empty()) return "~ " + trim(push);
  std::string ph = phone_of(member_jid);
  if (!ph.empty()) return "+" + ph;
  if (!raw_push.empty() && !looks_encoded(raw_push)) return raw_push;
  return "";
}
std::string sql_quote(const std::string& s) {
  std::string o = "'";
  for (char ch : s) o += ch == '\'' ? std::string("''") : std::string(1, ch);
  return o + "'";
}
bool load_messages(const std::string& path, Chat& c, int limit, std::string& error, int* rows = nullptr) {
#ifdef _WIN32
  (void)rows;
  (void)path;
  (void)c;
  (void)limit;
  error = tx::ERR_NO_DB;
  return false;
#else
  Sqlite& q = sqlite();
  if (!q.load()) { error = tx::ERR_NO_SQLITE; return false; }
  void* db = nullptr;
  std::string uri = "file:" + path + "?mode=ro";
  if (q.open_v2(uri.c_str(), &db, OPEN_READONLY | OPEN_URI, nullptr) != 0) {
    error = tx::ERR_OPEN_DB;
    if (db) q.close(db);
    return false;
  }
  void* st = nullptr;
  // La agenda (ContactsV2.sqlite, al lado) da los nombres de los miembros.
  bool book = false;
  std::string contacts = base_dir(path) + "/ContactsV2.sqlite";
  if (c.group && file_exists(contacts)) {
    std::string att = "ATTACH DATABASE " + sql_quote("file:" + contacts + "?mode=ro") + " AS ab";
    book = q.exec(db, att.c_str(), nullptr, nullptr, nullptr) == 0;
  }
  bool members = false;
  {
    void* t = nullptr;
    members = q.prepare_v2(db, "SELECT ZMEMBERJID, ZFIRSTNAME FROM ZWAGROUPMEMBER LIMIT 0", -1, &t, nullptr) == 0;
    if (t) q.finalize(t);
    void* t2 = nullptr;
    members = members && q.prepare_v2(db, "SELECT ZJID, ZPUSHNAME FROM ZWAPROFILEPUSHNAME LIMIT 0", -1, &t2, nullptr) == 0;
    if (t2) q.finalize(t2);
  }
  std::string sql =
      "SELECT m.ZISFROMME, IFNULL(m.ZTEXT, ''), m.ZMESSAGEDATE, IFNULL(m.ZPUSHNAME, ''), IFNULL(m.ZMESSAGETYPE, 0), "
      "IFNULL(i.ZMEDIALOCALPATH, ''), IFNULL(i.ZTITLE, ''), IFNULL(i.ZFILESIZE, 0), IFNULL(m.ZSTANZAID, ''), ";
  if (members) {
    sql += "IFNULL(g.ZMEMBERJID, ''), ";
    sql += book ? "IFNULL((SELECT a.ZFULLNAME FROM ab.ZWAADDRESSBOOKCONTACT a WHERE (a.ZWHATSAPPID = g.ZMEMBERJID OR a.ZLID = g.ZMEMBERJID) "
                  "AND IFNULL(a.ZFULLNAME, '') != '' LIMIT 1), ''), "
                : "'', ";
    sql += "IFNULL(g.ZFIRSTNAME, ''), "
           "IFNULL((SELECT p.ZPUSHNAME FROM ZWAPROFILEPUSHNAME p WHERE p.ZJID = g.ZMEMBERJID LIMIT 1), ''), ";
    // Su teléfono: el del miembro o, si es un «@lid», el de la agenda.
    sql += book ? "IFNULL((SELECT a.ZWHATSAPPID FROM ab.ZWAADDRESSBOOKCONTACT a WHERE a.ZWHATSAPPID = g.ZMEMBERJID "
                  "OR a.ZLID = g.ZMEMBERJID LIMIT 1), IFNULL(g.ZMEMBERJID, '')) "
                : "IFNULL(g.ZMEMBERJID, '') ";
    sql += "FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK LEFT JOIN ZWAGROUPMEMBER g ON g.Z_PK = m.ZGROUPMEMBER ";
  } else {
    sql += "'', '', '', '', '' FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK ";
  }
  sql += "WHERE m.ZCHATSESSION = ? AND ((m.ZTEXT IS NOT NULL AND m.ZTEXT != '') OR m.ZMESSAGETYPE IN (1, 2, 3, 8, 11, 15)) "
         "ORDER BY m.ZMESSAGEDATE DESC LIMIT ?";
  if (q.prepare_v2(db, sql.c_str(), -1, &st, nullptr) != 0) {
    error = tx::ERR_READ_DB;
    q.close(db);
    return false;
  }
  q.bind_int64(st, 1, c.id);
  q.bind_int64(st, 2, limit);
  std::vector<Msg> got;
  std::map<std::string, size_t> seen;
  int n_rows = 0;
  while (q.step(st) == SQLITE_ROW_) {
    n_rows++;
    Msg m;
    m.mine = q.column_int64(st, 0) != 0;
    m.text = col(st, 1);
    m.t = apple_time(q.column_double(st, 2));
    if (c.group && !m.mine) m.who = sender_name(col(st, 10), col(st, 11), col(st, 12), col(st, 9), col(st, 3));
    m.id = col(st, 8);   // el mismo id que trae el puente
    if (c.group && !m.mine) m.phone = phone_of(col(st, 13));
    m.kind = (int)q.column_int64(st, 4);
    if (m.kind != K_IMAGE && m.kind != K_VIDEO && m.kind != K_AUDIO && m.kind != K_DOC && m.kind != K_GIF && m.kind != K_STICKER)
      m.kind = K_TEXT;
    std::string local = col(st, 5);
    // Los adjuntos descargados están en «Message/Media/…».
    if (!local.empty() && file_exists(base_dir(path) + "/Message/" + local)) m.media = base_dir(path) + "/Message/" + local;
    m.title = col(st, 6);
    m.size = q.column_int64(st, 7);
    if (m.kind == K_TEXT && m.text.empty()) continue;
    // WhatsApp Desktop a veces guarda el mismo mensaje dos veces (el mismo id):
    // se queda uno, el que tiene el archivo descargado si lo hay.
    if (!m.id.empty()) {
      auto dup = seen.find(m.id);
      if (dup != seen.end()) {
        Msg& k = got[dup->second];
        if (k.media.empty() && !m.media.empty()) k.media = m.media;
        if (k.title.empty()) k.title = m.title;
        if (k.text.empty()) k.text = m.text;
        continue;
      }
      seen[m.id] = got.size();
    }
    got.push_back(m);
  }
  q.finalize(st);
  q.close(db);
  std::reverse(got.begin(), got.end());
  c.msgs = got;
  if (rows) *rows = n_rows;
  return true;
#endif
}

// ------------------------------------------------------------ la IA
// Claude (Anthropic) o ChatGPT (OpenAI), por su API HTTP con curl. La clave
// va en un archivo temporal que solo puede leer el usuario, no en la orden.
enum Provider { P_CLAUDE = 0, P_OPENAI = 1 };
struct AiSettings {
  std::string claude_key, openai_key, openai_model = "gpt-5", about;
  int provider = P_CLAUDE;
};
const char* const CLAUDE_MODEL = "claude-opus-5-5";

std::string tone_text(int tone) {
  switch (tone) {
    case 1: return tx::TONE_FORMAL;
    case 2: return tx::TONE_SHORT;
    case 3: return tx::TONE_WARM;
    case 4: return tx::TONE_BUSINESS;
    default: return tx::TONE_NATURAL;
  }
}
// Las instrucciones: tres respuestas distintas, en el idioma del chat, para
// enviarlas tal cual, separadas por una línea «---».
std::string system_prompt(int tone, const std::string& about) {
  std::string s = tx::PROMPT_SYSTEM;
  s = fmt(s, {tone_text(tone)});
  if (!trim(about).empty()) s += "\n\n" + fmt(tx::PROMPT_ABOUT, {trim(about)});
  return s;
}
// La conversación como texto: «Yo: …» y «Laura: …», los últimos [max] mensajes.
std::string transcript(const Chat& c, size_t max) {
  std::string o;
  size_t from = c.msgs.size() > max ? c.msgs.size() - max : 0;
  for (size_t i = from; i < c.msgs.size(); i++) {
    const Msg& m = c.msgs[i];
    std::string who = m.mine ? tx::ME : (m.who.empty() ? c.name : m.who);
    o += "[" + day_text(m.t) + " " + clock_time(m.t) + "] " + who + ": " + m.text + "\n";
  }
  return o;
}
std::string user_prompt(const Chat& c, const std::string& intent) {
  std::string s = fmt(tx::PROMPT_USER, {c.name, transcript(c, 40)});
  if (!trim(intent).empty()) s += "\n\n" + fmt(tx::PROMPT_INTENT, {trim(intent)});
  return s;
}

// El cuerpo de la petición a Claude: Opus 5.5 con esfuerzo bajo (respuestas
// de chat cortas y rápidas) y las respuestas de respaldo del servidor si el
// modelo declina («fallbacks»).
std::string claude_body(const std::string& system, const std::string& user) {
  return "{\"model\":" + jstr(CLAUDE_MODEL) +
         ",\"max_tokens\":4000,\"output_config\":{\"effort\":\"low\"},\"fallbacks\":\"default\",\"system\":" + jstr(system) +
         ",\"messages\":[{\"role\":\"user\",\"content\":" + jstr(user) + "}]}";
}
std::string openai_body(const std::string& model, const std::string& system, const std::string& user) {
  return "{\"model\":" + jstr(model) + ",\"messages\":[{\"role\":\"system\",\"content\":" + jstr(system) +
         "},{\"role\":\"user\",\"content\":" + jstr(user) + "}]}";
}

struct AiReply {
  std::vector<std::string> options;
  std::string error;
};
// «una\n---\notra\n---\notra» → las respuestas (sin numeración ni comillas).
std::vector<std::string> split_options(const std::string& text) {
  std::vector<std::string> out;
  std::string cur;
  auto flush = [&] {
    std::string t = trim(cur);
    // Sin «1.» ni comillas alrededor.
    if (t.size() > 2 && std::isdigit((unsigned char)t[0]) && (t[1] == '.' || t[1] == ')')) t = trim(t.substr(2));
    if (t.size() >= 2 && ((t.front() == '"' && t.back() == '"'))) t = t.substr(1, t.size() - 2);
    if (!t.empty()) out.push_back(t);
    cur.clear();
  };
  for (const auto& l : split(text, '\n')) {
    if (trim(l) == "---") flush();
    else cur += l + "\n";
  }
  flush();
  if (out.size() > 3) out.resize(3);
  return out;
}
// La respuesta de Claude: los bloques de texto (los demás, como «fallback»,
// no cuentan); si declinó, «refusal».
// El texto que contesta la IA (o el error).
struct AiText {
  std::string text, error;
};
AiText claude_text(int http, const std::string& body) {
  AiText r;
  bool ok = false;
  Json j = parse_json(body, &ok);
  if (!ok) { r.error = tx::ERR_AI_ANSWER; return r; }
  if (http >= 400 || j["type"].str() == "error") {
    std::string m = j["error"]["message"].str();
    r.error = http == 401 ? tx::ERR_AI_KEY : (m.empty() ? tx::ERR_AI_ANSWER : m);
    return r;
  }
  if (j["stop_reason"].str() == "refusal") {
    r.error = tx::ERR_AI_REFUSAL;
    return r;
  }
  for (const auto& b : j["content"].a)
    if (b["type"].str() == "text") r.text += b["text"].str();
  if (trim(r.text).empty()) r.error = tx::ERR_AI_ANSWER;
  return r;
}
AiText openai_text(int http, const std::string& body) {
  AiText r;
  bool ok = false;
  Json j = parse_json(body, &ok);
  if (!ok) { r.error = tx::ERR_AI_ANSWER; return r; }
  if (http >= 400 || j["error"].type == Json::OBJ) {
    std::string m = j["error"]["message"].str();
    r.error = http == 401 ? tx::ERR_AI_KEY : (m.empty() ? tx::ERR_AI_ANSWER : m);
    return r;
  }
  r.text = j["choices"][0]["message"]["content"].str();
  if (trim(r.text).empty()) r.error = tx::ERR_AI_ANSWER;
  return r;
}
AiReply parse_claude(int http, const std::string& body) {
  AiText t = claude_text(http, body);
  AiReply r;
  r.error = t.error;
  if (!t.error.empty()) return r;
  r.options = split_options(t.text);
  if (r.options.empty()) r.error = tx::ERR_AI_ANSWER;
  return r;
}
AiReply parse_openai(int http, const std::string& body) {
  AiText t = openai_text(http, body);
  AiReply r;
  r.error = t.error;
  if (!t.error.empty()) return r;
  r.options = split_options(t.text);
  if (r.options.empty()) r.error = tx::ERR_AI_ANSWER;
  return r;
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
  std::string cmd = "/usr/bin/curl -K " + q + " 2>&1";
  if (access("/usr/bin/curl", X_OK) != 0) cmd = "curl -K " + q + " 2>&1";
  FILE* p = popen(cmd.c_str(), "r");
  if (!p) return -1;
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
  int st = pclose(p);
  return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
#endif
}
// Una petición POST con su cuerpo JSON: (código HTTP, respuesta).
std::pair<int, std::string> post_json(const std::string& url, const std::vector<std::string>& headers, const std::string& body,
                                      const char* net_error = nullptr) {
  if (!net_error) net_error = tx::ERR_AI_NETWORK;
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string stamp = std::to_string((long long)(now_s() * 1000)) + "-" + std::to_string(counter++);
  std::string cfg = dir + "/req-" + stamp + ".cfg", data = dir + "/req-" + stamp + ".json";
  std::string c = "url = " + curl_quote(url) + "\n";
  for (const auto& h : headers) c += "header = " + curl_quote(h) + "\n";
  c += "silent\nshow-error\nmax-time = 120\nconnect-timeout = 15\nrequest = \"POST\"\n";
  c += "data-binary = " + curl_quote("@" + data) + "\n";
  c += "write-out = \"\\n%{http_code}\"\n";
  if (!write_file(data, body) || !write_file(cfg, c)) return {0, net_error};
  std::string out;
  int code = run_capture(cfg, out);
  std::remove(cfg.c_str());
  std::remove(data.c_str());
  size_t nl = out.find_last_of('\n');
  if (code != 0 || nl == std::string::npos) return {0, code < 0 ? tx::ERR_NO_CURL : net_error};
  return {std::atoi(out.c_str() + nl + 1), out.substr(0, nl)};
}
std::string anthropic_url() {
  const char* o = fl_getenv("DMS_MYWA_ANTHROPIC_URL");
  return std::string(o ? o : "https://api.anthropic.com") + "/v1/messages";
}
std::string openai_url() {
  const char* o = fl_getenv("DMS_MYWA_OPENAI_URL");
  return std::string(o ? o : "https://api.openai.com") + "/v1/chat/completions";
}
// Pide tres respuestas para [c] (en el hilo que la llama).
AiReply suggest(const AiSettings& s, const Chat& c, int tone, const std::string& intent) {
  std::string sys = system_prompt(tone, s.about), usr = user_prompt(c, intent);
  if (s.provider == P_OPENAI) {
    if (s.openai_key.empty()) return AiReply{{}, tx::ERR_AI_NO_KEY};
    auto r = post_json(openai_url(), {"Content-Type: application/json", "Authorization: Bearer " + s.openai_key},
                       openai_body(s.openai_model, sys, usr));
    if (r.first == 0) return AiReply{{}, r.second};
    return parse_openai(r.first, r.second);
  }
  if (s.claude_key.empty()) return AiReply{{}, tx::ERR_AI_NO_KEY};
  auto r = post_json(anthropic_url(),
                     {"Content-Type: application/json", "x-api-key: " + s.claude_key, "anthropic-version: 2026-10-21",
                      "anthropic-beta: server-side-fallback-2026-07-01"},
                     claude_body(sys, usr));
  if (r.first == 0) return AiReply{{}, r.second};
  return parse_claude(r.first, r.second);
}

// Una pregunta cualquiera a la IA elegida (en el hilo que la llama).
AiText ai_ask(const AiSettings& s, const std::string& sys, const std::string& usr) {
  if (s.provider == P_OPENAI) {
    if (s.openai_key.empty()) return AiText{"", tx::ERR_AI_NO_KEY};
    auto r = post_json(openai_url(), {"Content-Type: application/json", "Authorization: Bearer " + s.openai_key},
                       openai_body(s.openai_model, sys, usr));
    if (r.first == 0) return AiText{"", r.second};
    return openai_text(r.first, r.second);
  }
  if (s.claude_key.empty()) return AiText{"", tx::ERR_AI_NO_KEY};
  auto r = post_json(anthropic_url(),
                     {"Content-Type: application/json", "x-api-key: " + s.claude_key, "anthropic-version: 2026-10-21",
                      "anthropic-beta: server-side-fallback-2026-07-01"},
                     claude_body(sys, usr));
  if (r.first == 0) return AiText{"", r.second};
  return claude_text(r.first, r.second);
}

// ---- traducir: lo recibido, a mi idioma; lo que escribo, al del otro.
// FNV-1a: la misma clave para el mismo texto en cada arranque.
std::string fnv(const std::string& s) {
  unsigned long long h = 1469598103934665603ULL;
  for (unsigned char c : s) h = (h ^ c) * 1099511628211ULL;
  char b[24];
  std::snprintf(b, sizeof b, "%016llx", h);
  return b;
}
// La clave de la traducción de un mensaje recibido, o del original de uno enviado.
std::string trans_key(const Msg& m) {
  if (m.mine) return "o:" + fnv(m.text);
  return m.id.empty() ? "t:" + fnv(m.text) : "i:" + m.id;
}
std::string translate_in_user(const std::vector<std::string>& texts) {
  std::string u = "[";
  for (size_t i = 0; i < texts.size(); i++) u += (i ? "," : "") + jstr(texts[i]);
  return u + "]";
}
// La respuesta: {"language": "...", "items": [...]} (aunque venga entre ```).
bool parse_translation(const std::string& text, size_t n, std::string& language, std::vector<std::string>& items) {
  size_t a = text.find('{'), b = text.rfind('}');
  if (a == std::string::npos || b == std::string::npos || b < a) return false;
  bool ok = false;
  Json j = parse_json(text.substr(a, b - a + 1), &ok);
  if (!ok || j["items"].a.size() != n) return false;
  language = trim(j["language"].str());
  items.clear();
  for (const auto& it : j["items"].a) items.push_back(it.str());
  return true;
}

// ---- las claves: en el Llavero de macOS (en Windows y Linux, en un
// archivo de la carpeta de ajustes que solo lee el usuario)
std::string sh_quote(const std::string& s) {
  std::string q = "'";
  for (char c : s) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  return q + "'";
}
std::string key_get(const std::string& name) {
#ifdef __APPLE__
  if (fl_getenv("DMS_MYWA_CONFIG")) {
    std::string v;
    read_file(config_dir() + "/" + name + ".key", v);
    return trim(v);
  }
  std::string cmd = "/usr/bin/security find-generic-password -a dmarlon-mywhatsapp -s " + sh_quote(name) + " -w 2>/dev/null";
  FILE* p = popen(cmd.c_str(), "r");
  if (!p) return "";
  char buf[512];
  std::string out;
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
  pclose(p);
  return trim(out);
#else
  std::string v;
  read_file(config_dir() + "/" + name + ".key", v);
  return trim(v);
#endif
}
void key_set(const std::string& name, const std::string& value) {
  fl_make_path(config_dir().c_str());
#ifdef __APPLE__
  if (fl_getenv("DMS_MYWA_CONFIG")) {
    write_file(config_dir() + "/" + name + ".key", value);
    return;
  }
  std::string cmd = "/usr/bin/security add-generic-password -U -a dmarlon-mywhatsapp -s " + sh_quote(name) + " -w " +
                    sh_quote(value) + " >/dev/null 2>&1";
  int r = std::system(cmd.c_str());
  (void)r;
#else
  write_file(config_dir() + "/" + name + ".key", value);
#endif
}

// ------------------------------------------------------------ enviar
// Dos maneras: la API oficial de WhatsApp Business (Cloud API, de Meta) o el
// puente «dispositivo vinculado» (wabridge: como WhatsApp Web, con un QR).
enum SendMode { S_NONE = 0, S_CLOUD = 1, S_LINKED = 2 };
struct CloudSettings {
  std::string phone_id, token;
};
std::string graph_url() {
  const char* o = fl_getenv("DMS_MYWA_GRAPH_URL");
  return std::string(o ? o : "https://graph.facebook.com") + "/v23.0/";
}
std::string file_base(const std::string& path) {
  size_t p = path.find_last_of("/\\");
  return p == std::string::npos ? path : path.substr(p + 1);
}
// El tipo de un archivo para WhatsApp: foto, vídeo, audio o documento.
int file_kind(const std::string& path) {
  std::string e = lower(path.substr(path.find_last_of('.') == std::string::npos ? path.size() : path.find_last_of('.')));
  if (e == ".jpg" || e == ".jpeg" || e == ".png") return K_IMAGE;
  if (e == ".mp4" || e == ".3gp") return K_VIDEO;
  if (e == ".mp3" || e == ".ogg" || e == ".opus" || e == ".m4a" || e == ".aac" || e == ".amr") return K_AUDIO;
  return K_DOC;
}
std::string mime_of(const std::string& path) {
  std::string e = lower(path.substr(path.find_last_of('.') == std::string::npos ? path.size() : path.find_last_of('.')));
  static const std::map<std::string, std::string> m = {
      {".jpg", "image/jpeg"}, {".jpeg", "image/jpeg"}, {".png", "image/png"}, {".mp4", "video/mp4"},
      {".3gp", "video/3gpp"}, {".mp3", "audio/mpeg"}, {".ogg", "audio/ogg"}, {".opus", "audio/ogg"},
      {".m4a", "audio/mp4"}, {".aac", "audio/aac"}, {".amr", "audio/amr"}, {".pdf", "application/pdf"},
      {".txt", "text/plain"}, {".doc", "application/msword"}, {".xls", "application/vnd.ms-excel"},
      {".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
      {".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
      {".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"}};
  auto it = m.find(e);
  return it == m.end() ? "application/octet-stream" : it->second;
}
std::string cloud_text_body(const std::string& to, const std::string& text) {
  return "{\"messaging_product\":\"whatsapp\",\"recipient_type\":\"individual\",\"to\":" + jstr(to) +
         ",\"type\":\"text\",\"text\":{\"preview_url\":true,\"body\":" + jstr(text) + "}}";
}
std::string cloud_media_body(const std::string& to, int kind, const std::string& media_id, const std::string& caption,
                             const std::string& filename) {
  std::string t = kind == K_IMAGE ? "image" : kind == K_VIDEO ? "video" : kind == K_AUDIO ? "audio" : "document";
  std::string inner = "{\"id\":" + jstr(media_id);
  if (kind != K_AUDIO && !caption.empty()) inner += ",\"caption\":" + jstr(caption);
  if (kind == K_DOC) inner += ",\"filename\":" + jstr(filename);
  return "{\"messaging_product\":\"whatsapp\",\"recipient_type\":\"individual\",\"to\":" + jstr(to) + ",\"type\":\"" + t +
         "\",\"" + t + "\":" + inner + "}}";
}
// La respuesta de la Graph API: "" si fue bien (y su id), o el error.
std::string parse_cloud(int http, const std::string& body, std::string* id = nullptr) {
  bool ok = false;
  Json j = parse_json(body, &ok);
  if (http >= 200 && http < 300 && ok) {
    std::string v = j["messages"][0]["id"].str();
    if (v.empty()) v = j["id"].str();
    if (id) *id = v;
    if (!v.empty()) return "";
  }
  if (http == 401 || j["error"]["code"].n == 190) return tx::ERR_CLOUD_TOKEN;
  std::string m = j["error"]["message"].str();
  return m.empty() ? std::string(tx::ERR_SEND) : fmt(tx::ERR_SEND_WHY, {m});
}
// Un formulario multipart (para subir el adjunto): (código HTTP, respuesta).
std::pair<int, std::string> post_form(const std::string& url, const std::vector<std::string>& headers,
                                      const std::vector<std::string>& fields) {
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string cfg = dir + "/form-" + std::to_string((long long)(now_s() * 1000)) + "-" + std::to_string(counter++) + ".cfg";
  std::string c = "url = " + curl_quote(url) + "\n";
  for (const auto& h : headers) c += "header = " + curl_quote(h) + "\n";
  for (const auto& f : fields) c += "form = " + curl_quote(f) + "\n";
  c += "silent\nshow-error\nmax-time = 300\nconnect-timeout = 15\nwrite-out = \"\\n%{http_code}\"\n";
  if (!write_file(cfg, c)) return {0, tx::ERR_SEND_NETWORK};
  std::string out;
  int code = run_capture(cfg, out);
  std::remove(cfg.c_str());
  size_t nl = out.find_last_of('\n');
  if (code != 0 || nl == std::string::npos) return {0, code < 0 ? tx::ERR_NO_CURL : tx::ERR_SEND_NETWORK};
  return {std::atoi(out.c_str() + nl + 1), out.substr(0, nl)};
}
// Envía un texto (o un archivo con [text] de pie) con la API oficial.
std::string cloud_send(const CloudSettings& s, const std::string& jid, const std::string& text, const std::string& file,
                       std::string* id) {
  std::string to = phone_of(jid);
  if (to.empty()) return tx::ERR_CLOUD_GROUP;
  if (s.phone_id.empty() || s.token.empty()) return tx::ERR_CLOUD_SETUP;
  std::vector<std::string> auth = {"Authorization: Bearer " + s.token};
  std::string body;
  if (file.empty()) body = cloud_text_body(to, text);
  else {
    std::string mime = mime_of(file), path;
    for (char ch : file)
      if (ch != '"') path += ch;
    auto up = post_form(graph_url() + s.phone_id + "/media", auth,
                        {"messaging_product=whatsapp", "type=" + mime, "file=@\"" + path + "\";type=" + mime});
    if (up.first == 0) return up.second;
    std::string media_id, e = parse_cloud(up.first, up.second, &media_id);
    if (!e.empty()) return e;
    body = cloud_media_body(to, file_kind(file), media_id, text, file_base(file));
  }
  auto h = auth;
  h.push_back("Content-Type: application/json");
  auto r = post_json(graph_url() + s.phone_id + "/messages", h, body, tx::ERR_SEND_NETWORK);
  if (r.first == 0) return r.second;
  return parse_cloud(r.first, r.second, id);
}

// ---- los mensajes que llegan por el puente (o que se envían): se guardan en
// mensajes.jsonl, una línea JSON por mensaje, y se juntan con los de Desktop.
std::string preview_of(const Msg& m) {
  if (m.kind == K_TEXT) return m.text;
  std::string s = std::string(kind_icon(m.kind)) + " " + (m.title.empty() ? kind_name(m.kind) : m.title);
  return m.text.empty() ? s : s + " · " + m.text;
}
std::string msg_line(const Msg& m, const std::string& jid) {
  return "{\"ev\":\"msg\",\"id\":" + jstr(m.id) + ",\"chat\":" + jstr(jid) + ",\"mine\":" + (m.mine ? "true" : "false") +
         ",\"text\":" + jstr(m.text) + ",\"t\":" + std::to_string(m.t) + ",\"kind\":" + std::to_string(m.kind) +
         ",\"media\":" + jstr(m.media) + ",\"title\":" + jstr(m.title) + ",\"size\":" + std::to_string(m.size) + "}";
}
bool append_line(const std::string& path, const std::string& line) {
#ifndef _WIN32
  mode_t old = umask(077);
#endif
  FILE* f = fl_fopen(path.c_str(), "ab");
#ifndef _WIN32
  umask(old);
#endif
  if (!f) return false;
  std::fputs((line + "\n").c_str(), f);
  return std::fclose(f) == 0;
}
struct LiveChat {
  std::string name;
  bool group = false;
  std::vector<Msg> msgs;   // del más antiguo al más nuevo
};
struct LiveStore {
  std::map<std::string, LiveChat> chats;
  std::map<std::string, bool> seen;   // los id ya guardados
  // Una línea del puente; devuelve el chat que cambió ("" si ninguno).
  std::string add_line(const std::string& line) {
    bool ok = false;
    Json j = parse_json(line, &ok);
    if (!ok) return "";
    std::string ev = j["ev"].str();
    if (ev == "chat") {
      std::string jid = j["jid"].str(), name = j["name"].str();
      if (!jid.empty() && !name.empty()) chats[jid].name = name;
      return "";
    }
    if (ev != "msg") return "";
    std::string jid = j["chat"].str(), id = j["id"].str();
    if (jid.empty()) return "";
    if (!id.empty()) {
      if (seen.count(id)) return "";
      seen[id] = true;
    }
    Msg m;
    m.id = id;
    m.mine = j["mine"].b;
    m.who = j["who"].str();
    m.text = j["text"].str();
    m.t = (long long)j["t"].n;
    m.kind = (int)j["kind"].n;
    m.media = j["media"].str();
    m.title = j["title"].str();
    m.size = (long long)j["size"].n;
    LiveChat& c = chats[jid];
    c.group = c.group || j["group"].b || jid.find("@g.us") != std::string::npos;
    if (c.name.empty() && !m.mine && !c.group) c.name = j["name"].str();
    auto at = std::upper_bound(c.msgs.begin(), c.msgs.end(), m.t, [](long long t, const Msg& x) { return t < x.t; });
    c.msgs.insert(at, m);
    if (c.msgs.size() > 400) c.msgs.erase(c.msgs.begin());
    return jid;
  }
  void load(const std::string& path) {
    std::string text;
    if (!read_file(path, text)) return;
    for (const auto& l : split(text, '\n'))
      if (!l.empty()) add_line(l);
  }
  bool empty() const { return chats.empty(); }
};
// Junta los mensajes del puente con los de WhatsApp Desktop, sin repetirlos.
void merge_msgs(std::vector<Msg>& base, const std::vector<Msg>& extra) {
  size_t n = base.size();
  for (const auto& m : extra) {
    bool dup = false;
    for (size_t i = 0; i < n && !dup; i++) {
      const Msg& b = base[i];
      if (!b.id.empty() && b.id == m.id) dup = true;   // el mismo mensaje (WhatsApp Desktop y el puente)
      else if (b.mine == m.mine && b.kind == m.kind && std::llabs(b.t - m.t) <= 5)
        dup = b.text == m.text || (m.kind != K_TEXT && m.size > 0 && b.size == m.size);
    }
    if (!dup) base.push_back(m);
  }
  std::stable_sort(base.begin(), base.end(), [](const Msg& a, const Msg& b) { return a.t < b.t; });
}
long long live_id(const std::string& jid) {
  return -1000000 - (long long)(std::hash<std::string>{}(jid) % 1000000000ULL);
}
Chat live_chat(const std::string& jid, const LiveChat& lc) {
  Chat c;
  c.id = live_id(jid);
  c.live = true;
  c.jid = jid;
  c.group = lc.group;
  std::string ph = phone_of(jid);
  c.name = !lc.name.empty() ? lc.name : ph.empty() ? jid : "+" + ph;
  c.msgs = lc.msgs;
  if (!c.msgs.empty()) {
    c.last = preview_of(c.msgs.back());
    c.last_t = c.msgs.back().t;
    c.last_mine = c.msgs.back().mine;
  }
  return c;
}

// ---- las tareas: cada una puede venir de un chat (y abrirlo luego);
// se guardan en tareas.jsonl, una línea JSON por tarea.
struct Task {
  long long id = 0, created = 0;
  std::string title, jid, chat;   // jid y chat: de dónde salió ("" si de ninguno)
  bool done = false;
};
std::string task_line(const Task& t) {
  return "{\"id\":" + std::to_string(t.id) + ",\"title\":" + jstr(t.title) + ",\"jid\":" + jstr(t.jid) +
         ",\"chat\":" + jstr(t.chat) + ",\"t\":" + std::to_string(t.created) + ",\"done\":" + (t.done ? "true" : "false") + "}";
}
std::vector<Task> tasks_parse(const std::string& text) {
  std::vector<Task> out;
  for (const auto& l : split(text, '\n')) {
    bool ok = false;
    Json j = parse_json(l, &ok);
    if (!ok || j["title"].str().empty()) continue;
    Task t;
    t.id = (long long)j["id"].n;
    t.title = j["title"].str();
    t.jid = j["jid"].str();
    t.chat = j["chat"].str();
    t.created = (long long)j["t"].n;
    t.done = j["done"].b;
    out.push_back(t);
  }
  return out;
}
std::string tasks_text(const std::vector<Task>& ts) {
  std::string out;
  for (const auto& t : ts) out += task_line(t) + "\n";
  return out;
}
int tasks_pending(const std::vector<Task>& ts) {
  int n = 0;
  for (const auto& t : ts) n += t.done ? 0 : 1;
  return n;
}
// La bolita de una tarea pendiente según su edad: verde (menos de 24 h),
// naranja (más de 24 h) o roja (más de 72 h).
unsigned task_age_color(long long created, long long now) {
  long long h = (now - created) / 3600;
  if (h >= 72) return 0xe5484d;
  if (h >= 24) return 0xf59e0b;
  return 0x25d366;
}
// La tarea pendiente más antigua de un chat (su fecha), o 0 si no tiene.
long long oldest_task(const std::vector<Task>& ts, const std::string& jid) {
  long long o = 0;
  if (jid.empty()) return 0;
  for (const auto& t : ts)
    if (!t.done && t.jid == jid && (o == 0 || t.created < o)) o = t.created;
  return o;
}
// El orden en pantalla: primero las pendientes (la más nueva arriba), luego las hechas.
std::vector<int> tasks_order(const std::vector<Task>& ts) {
  std::vector<int> o;
  for (int pass = 0; pass < 2; pass++)
    for (int i = (int)ts.size() - 1; i >= 0; i--)
      if (ts[(size_t)i].done == (pass == 1)) o.push_back(i);
  return o;
}
// El texto de partida de una tarea hecha con un mensaje.
std::string task_title_of(const Msg& m) {
  std::string t = m.kind == K_TEXT ? m.text : preview_of(m);
  for (auto& ch : t)
    if (ch == '\n' || ch == '\t') ch = ' ';
  t = trim(t);
  if (t.size() > 200) {
    size_t cut = 200;
    while (cut > 0 && ((unsigned char)t[cut] & 0xC0) == 0x80) cut--;
    t = t.substr(0, cut) + "…";
  }
  return t;
}

// ---- los modos ocupado: un nombre y el mensaje que se contesta solo.
struct BusyMode {
  std::string name, text;
  bool ai = false;   // true: contesta la IA según la conversación y [text] es su instrucción
};
std::string busy_text(const std::vector<BusyMode>& ms) {
  std::string out;
  for (const auto& m : ms)
    out += "{\"name\":" + jstr(m.name) + ",\"text\":" + jstr(m.text) + ",\"ai\":" + (m.ai ? "true" : "false") + "}\n";
  return out;
}
std::vector<BusyMode> busy_parse(const std::string& text) {
  std::vector<BusyMode> out;
  for (const auto& l : split(text, '\n')) {
    bool ok = false;
    Json j = parse_json(l, &ok);
    if (ok && !j["name"].str().empty()) out.push_back({j["name"].str(), j["text"].str(), j["ai"].b});
  }
  return out;
}
// A quién contestar: chats individuales (no grupos ni archivados) cuyo último
// mensaje es suyo, llegó después de [since] y aún no tuvieron respuesta automática.
std::vector<int> busy_targets(const std::vector<Chat>& chats, long long since, const std::map<std::string, bool>& done) {
  std::vector<int> out;
  for (int i = 0; i < (int)chats.size(); i++) {
    const Chat& c = chats[(size_t)i];
    if (c.group || c.archived || c.last_mine || c.jid.empty() || c.last_t <= since) continue;
    if (c.jid.find("@s.whatsapp.net") == std::string::npos) continue;
    if (done.count(c.jid)) continue;
    out.push_back(i);
  }
  return out;
}

// ---- la barra de menús: los chats por responder (me escribieron en los
// últimos 3 días y no contesté; sin los archivados), del más reciente al más antiguo.
std::vector<int> to_answer(const std::vector<Chat>& chats, long long now) {
  std::vector<int> out;
  for (int i = 0; i < (int)chats.size(); i++) {
    const Chat& c = chats[(size_t)i];
    if (!c.archived && !c.last_mine && c.last_t > 0 && c.last_t >= now - 3 * 86400) out.push_back(i);
  }
  std::stable_sort(out.begin(), out.end(), [&](int a, int b) { return chats[(size_t)a].last_t > chats[(size_t)b].last_t; });
  return out;
}
struct BarEntry {
  std::string title;
  int tag = 0;   // 0: no se pulsa
  bool sep = false;
};

// ---- el puente (wabridge): un proceso aparte que habla por stdin/stdout
std::string exe_dir() {
  std::string s;
#ifdef _WIN32
  wchar_t w[MAX_PATH];
  DWORD n = GetModuleFileNameW(nullptr, w, MAX_PATH);
  char u[MAX_PATH * 4];
  fl_utf8fromwc(u, sizeof u, w, n);
  s = u;
#elif defined(__APPLE__)
  char buf[4096];
  uint32_t size = sizeof buf;
  if (_NSGetExecutablePath(buf, &size) == 0) s = buf;
#else
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
  if (n > 0) s.assign(buf, (size_t)n);
#endif
  size_t p = s.find_last_of("/\\");
  return p == std::string::npos ? "." : s.substr(0, p);
}
std::string bridge_path() {
  if (const char* o = fl_getenv("DMS_MYWA_BRIDGE")) return o;
#ifdef _WIN32
  return exe_dir() + "\\wabridge.exe";
#else
  return exe_dir() + "/wabridge";
#endif
}
class Bridge {
public:
  std::function<void(const std::string&)> on_line;   // en el hilo de la ventana
  bool running() const { return alive; }
  bool start(const std::string& exe, const std::string& dir) {
    stop();
    current() = this;
    int g = ++gen;
#ifdef _WIN32
    SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
    HANDLE out_r = nullptr, out_w = nullptr, in_r = nullptr, in_w2 = nullptr;
    if (!CreatePipe(&out_r, &out_w, &sa, 0)) return false;
    if (!CreatePipe(&in_r, &in_w2, &sa, 0)) {
      CloseHandle(out_r);
      CloseHandle(out_w);
      return false;
    }
    SetHandleInformation(out_r, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(in_w2, HANDLE_FLAG_INHERIT, 0);
    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = in_r;
    si.hStdOutput = out_w;
    si.hStdError = out_w;
    PROCESS_INFORMATION pi{};
    std::wstring cmd = L"\"" + wide(exe) + L"\" -dir \"" + wide(dir) + L"\"";
    BOOL ok = CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
    CloseHandle(out_w);
    CloseHandle(in_r);
    if (!ok) {
      CloseHandle(out_r);
      CloseHandle(in_w2);
      return false;
    }
    CloseHandle(pi.hThread);
    in_w = in_w2;
    alive = true;
    HANDLE proc = pi.hProcess;
    std::thread([out_r, proc, g] {
      std::string buf;
      char tmp[65536];
      DWORD n = 0;
      while (ReadFile(out_r, tmp, sizeof tmp, &n, nullptr) && n > 0) lines(buf, tmp, n, g);
      CloseHandle(out_r);
      WaitForSingleObject(proc, INFINITE);
      CloseHandle(proc);
      Fl::awake(deliver, new Line{g, "{\"ev\":\"exit\"}"});
    }).detach();
#else
    int in[2], out[2];
    if (pipe(in) != 0) return false;
    if (pipe(out) != 0) {
      close(in[0]);
      close(in[1]);
      return false;
    }
    pid_t pid = fork();
    if (pid < 0) {
      for (int fd : {in[0], in[1], out[0], out[1]}) close(fd);
      return false;
    }
    if (pid == 0) {
      dup2(in[0], 0);
      dup2(out[1], 1);
      int nul = open("/dev/null", O_WRONLY);
      if (nul >= 0) dup2(nul, 2);
      for (int fd = 3; fd < 1024; fd++) close(fd);
      execl(exe.c_str(), exe.c_str(), "-dir", dir.c_str(), (char*)nullptr);
      _exit(127);
    }
    close(in[0]);
    close(out[1]);
    fcntl(in[1], F_SETFD, FD_CLOEXEC);
    fcntl(out[0], F_SETFD, FD_CLOEXEC);
    signal(SIGPIPE, SIG_IGN);
    in_w = in[1];
    alive = true;
    int rd = out[0];
    std::thread([rd, pid, g] {
      std::string buf;
      char tmp[65536];
      while (true) {
        ssize_t n = read(rd, tmp, sizeof tmp);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) break;
        lines(buf, tmp, (size_t)n, g);
      }
      close(rd);
      int st = 0;
      waitpid(pid, &st, 0);
      Fl::awake(deliver, new Line{g, "{\"ev\":\"exit\"}"});
    }).detach();
#endif
    return true;
  }
  bool send(const std::string& json) {
    if (!alive) return false;
    std::string l = json + "\n";
#ifdef _WIN32
    DWORD n = 0;
    return WriteFile(in_w, l.data(), (DWORD)l.size(), &n, nullptr) && n == l.size();
#else
    size_t done = 0;
    while (done < l.size()) {
      ssize_t n = write(in_w, l.data() + done, l.size() - done);
      if (n < 0 && errno == EINTR) continue;
      if (n <= 0) return false;
      done += (size_t)n;
    }
    return true;
#endif
  }
  // Al cerrar su entrada, el puente se desconecta y termina.
  void stop() {
    if (!alive) return;
    alive = false;
#ifdef _WIN32
    CloseHandle(in_w);
    in_w = nullptr;
#else
    close(in_w);
    in_w = -1;
#endif
  }

private:
  struct Line {
    int gen;
    std::string text;
  };
  bool alive = false;
  int gen = 0;
#ifdef _WIN32
  HANDLE in_w = nullptr;
#else
  int in_w = -1;
#endif
  static Bridge*& current() {
    static Bridge* b = nullptr;
    return b;
  }
  static void lines(std::string& buf, const char* data, size_t n, int g) {
    buf.append(data, n);
    size_t nl;
    while ((nl = buf.find('\n')) != std::string::npos) {
      std::string l = buf.substr(0, nl);
      buf.erase(0, nl + 1);
      if (!l.empty() && l.back() == '\r') l.pop_back();
      if (!l.empty()) Fl::awake(deliver, new Line{g, l});
    }
  }
  static void deliver(void* p) {
    std::unique_ptr<Line> l(static_cast<Line*>(p));
    Bridge* b = current();
    if (!b || l->gen != b->gen) return;   // de un puente anterior
    if (l->text == "{\"ev\":\"exit\"}") b->alive = false;
    if (b->on_line) b->on_line(l->text);
  }
};

// ------------------------------------------------------------ dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }

// Los colores de la app, en claro o en oscuro (los de WhatsApp).
struct Theme {
  bool dark = false;
  unsigned list = 0xffffff, sel = 0xe9edef, hover = 0xf5f6f6, text = 0x111b21, muted = 0x667781, line = 0xe9edef,
           chat = 0xefeae2, in = 0xffffff, in_line = 0xe2ddd5, out = 0xd9fdd3, out_line = 0xc5e8bd, panel = 0xf0f2f5,
           card = 0xffffff, card_line = 0xd1d7db, input = 0xffffff, accent = 0x1fa855;
};
Theme& th() {
  static Theme t;
  return t;
}
void set_dark(bool dark) {
  Theme t;
  if (dark) {
    t.dark = true;
    t.list = 0x111b21; t.sel = 0x2a3942; t.hover = 0x202c33; t.text = 0xe9edef; t.muted = 0x8696a0; t.line = 0x222d34;
    t.chat = 0x0b141a; t.in = 0x202c33; t.in_line = 0x202c33; t.out = 0x005c4b; t.out_line = 0x005c4b; t.panel = 0x202c33;
    t.card = 0x111b21; t.card_line = 0x2a3942; t.input = 0x2a3942; t.accent = 0x00a884;
  }
  th() = t;
}
// ¿Está macOS en modo oscuro?
bool system_dark() {
#ifdef __APPLE__
  FILE* p = popen("/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null", "r");
  if (!p) return false;
  char buf[32] = "";
  size_t n = std::fread(buf, 1, sizeof buf - 1, p);
  buf[n] = 0;
  pclose(p);
  return std::strncmp(buf, "Dark", 4) == 0;
#else
  return false;
#endif
}

// Las imágenes (fotos de perfil y adjuntos), cargadas una vez y a su tamaño.
std::map<std::string, Fl_RGB_Image*>& images() {
  static std::map<std::string, Fl_RGB_Image*> m;
  return m;
}
bool is_picture(const std::string& path) {
  std::string l = lower(path);
  for (const char* e : {".jpg", ".jpeg", ".png", ".gif", ".thumb", ".bmp", ".webp"})
    if (l.size() > std::strlen(e) && l.compare(l.size() - std::strlen(e), std::string::npos, e) == 0) return true;
  return false;
}
// Los stickers son WebP, que FLTK no lee: en macOS, sips los pasa a PNG en
// otro hilo (una vez; quedan en la carpeta «stickers») y luego se dibujan.
std::string webp_png(const std::string& path) { return config_dir() + "/stickers/" + fnv(path) + ".png"; }
std::map<std::string, bool>& webp_busy() {
  static std::map<std::string, bool> m;
  return m;
}
std::function<void()>& on_picture_ready() {   // la ventana se vuelve a dibujar
  static std::function<void()> f;
  return f;
}
// Convierte en el hilo que lo llama; true si quedó el PNG.
bool webp_convert(const std::string& path, const std::string& png) {
#ifdef __APPLE__
  fl_make_path((config_dir() + "/stickers").c_str());
  std::string tmp = png + ".tmp.png";
  std::string cmd = "/usr/bin/sips -s format png " + sh_quote(path) + " --out " + sh_quote(tmp) + " >/dev/null 2>&1";
  if (std::system(cmd.c_str()) != 0 || !file_exists(tmp)) {
    std::remove(tmp.c_str());
    return false;
  }
  return std::rename(tmp.c_str(), png.c_str()) == 0;
#else
  (void)path;
  (void)png;
  return false;
#endif
}
struct WebpDone {
  std::string path;
};
void webp_ready(void* p) {
  std::unique_ptr<WebpDone> d(static_cast<WebpDone*>(p));
  // Fuera de la caché lo que se guardó vacío: la próxima vez se carga el PNG.
  std::string pre = d->path + "@";
  for (auto it = images().begin(); it != images().end();)
    if (it->first.compare(0, pre.size(), pre) == 0 && !it->second) it = images().erase(it);
    else ++it;
  if (on_picture_ready()) on_picture_ready()();
}
// Una imagen de disco según sus primeros bytes (JPEG, PNG, BMP o WebP), sea
// cual sea la extensión (las fotos de perfil de WhatsApp acaban en «.thumb»).
Fl_RGB_Image* load_picture(const std::string& path) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return nullptr;
  unsigned char m[12] = {0};
  size_t n = std::fread(m, 1, sizeof m, f);
  std::fclose(f);
  if (n >= 12 && std::memcmp(m, "RIFF", 4) == 0 && std::memcmp(m + 8, "WEBP", 4) == 0) {
    std::string png = webp_png(path);
    if (file_exists(png)) return load_picture(png);
    if (!webp_busy().count(path)) {
      webp_busy()[path] = true;
      std::thread([path, png] {
        if (webp_convert(path, png)) Fl::awake(webp_ready, new WebpDone{path});
      }).detach();
    }
    return nullptr;
  }
  Fl_RGB_Image* img = nullptr;
  if (n >= 3 && m[0] == 0xFF && m[1] == 0xD8 && m[2] == 0xFF) img = new Fl_JPEG_Image(path.c_str());
  else if (n >= 8 && m[0] == 0x89 && m[1] == 'P' && m[2] == 'N' && m[3] == 'G') img = new Fl_PNG_Image(path.c_str());
  else if (n >= 2 && m[0] == 'B' && m[1] == 'M') img = new Fl_BMP_Image(path.c_str());
  if (img && (img->w() <= 0 || img->h() <= 0 || img->fail())) {
    delete img;
    img = nullptr;
  }
  return img;
}
// La imagen de [path] que cabe en [w]×[h] (sin deformar); nullptr si no se puede.
Fl_RGB_Image* image_fit(const std::string& path, int w, int h) {
  std::string key = path + "@" + std::to_string(w) + "x" + std::to_string(h);
  auto it = images().find(key);
  if (it != images().end()) return it->second;
  Fl_RGB_Image* out = nullptr;
  auto src = images().find(path);   // las de la demo, ya hechas
  Fl_RGB_Image* base = src != images().end() ? src->second : (is_picture(path) ? load_picture(path) : nullptr);
  if (base && base->w() > 0 && base->h() > 0) {
    double k = std::min(w / (double)base->w(), h / (double)base->h());
    int dw = std::max(1, (int)(base->w() * k)), dh = std::max(1, (int)(base->h() * k));
    out = static_cast<Fl_RGB_Image*>(base->copy(dw, dh));   // la copia de una Fl_RGB_Image es otra
  }
  if (base && src == images().end()) delete base;
  images()[key] = out;
  return out;
}
// La foto de un contacto en un círculo (o sus iniciales sobre un color).
void avatar(int x, int y, int size, const std::string& name, const std::string& pic, Fl_Color bg);
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(line);
  fl_rounded_rect(x, y, w, h, r);
}
std::string fit(const std::string& s, int w) {
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty() && (int)fl_width((t + "…").c_str()) > w) {
    t.pop_back();
    while (!t.empty() && ((unsigned char)t.back() & 0xC0) == 0x80) t.pop_back();
  }
  return t + "…";
}
// Un texto partido en líneas de [w] píxeles (con la fuente actual).
std::vector<std::string> wrap(const std::string& text, int w) {
  std::vector<std::string> lines;
  for (const auto& para : split(text, '\n')) {
    std::string line;
    for (const auto& word : split(para, ' ')) {
      std::string t = line.empty() ? word : line + " " + word;
      if (!line.empty() && (int)fl_width(t.c_str()) > w) {
        lines.push_back(line);
        line = word;
      } else {
        line = t;
      }
      while ((int)fl_width(line.c_str()) > w && line.size() > 1) {   // una palabra muy larga
        size_t cut = line.size() / 2;
        while (cut > 0 && ((unsigned char)line[cut] & 0xC0) == 0x80) cut--;
        lines.push_back(line.substr(0, cut));
        line = line.substr(cut);
      }
    }
    lines.push_back(line);
  }
  return lines;
}
// Como wrap, y además qué separa cada línea de la siguiente: 'n' un salto de
// línea, 's' un espacio y 'c' nada (una palabra cortada). Para copiar el texto.
std::vector<std::string> wrap_seps(const std::string& text, int w, std::string& seps) {
  std::vector<std::string> lines;
  seps.clear();
  auto paras = split(text, '\n');
  for (size_t p = 0; p < paras.size(); p++) {
    std::string line;
    for (const auto& word : split(paras[p], ' ')) {
      std::string t = line.empty() ? word : line + " " + word;
      if (!line.empty() && (int)fl_width(t.c_str()) > w) {
        lines.push_back(line);
        seps += 's';
        line = word;
      } else {
        line = t;
      }
      while ((int)fl_width(line.c_str()) > w && line.size() > 1) {
        size_t cut = line.size() / 2;
        while (cut > 0 && ((unsigned char)line[cut] & 0xC0) == 0x80) cut--;
        lines.push_back(line.substr(0, cut));
        seps += 'c';
        line = line.substr(cut);
      }
    }
    lines.push_back(line);
    seps += p + 1 < paras.size() ? 'n' : '.';
  }
  return lines;
}
// Dónde está [needle] en [hay] sin mirar mayúsculas (ASCII): las posiciones.
std::vector<size_t> find_all(const std::string& hay, const std::string& needle) {
  std::vector<size_t> out;
  if (needle.empty()) return out;
  std::string h = lower(hay), n = lower(needle);
  for (size_t p = h.find(n); p != std::string::npos; p = h.find(n, p + n.size())) out.push_back(p);
  return out;
}
Fl_Color avatar_color(const std::string& name) {
  static const unsigned colors[] = {0x25d366, 0x34b7f1, 0xf59e0b, 0xef4444, 0x8b5cf6, 0x14b8a6, 0xec4899};
  unsigned h = 0;
  for (unsigned char c : name) h = h * 31 + c;
  return rgb(colors[h % 7]);
}
std::string initials(const std::string& name) {
  std::string o;
  for (const auto& w : split(name, ' ')) {
    if (w.empty()) continue;
    unsigned char c = (unsigned char)w[0];
    if (std::isalpha(c)) o += (char)std::toupper(c);
    else if (c >= 0x80) {
      int n = 1;
      while (n < (int)w.size() && ((unsigned char)w[(size_t)n] & 0xC0) == 0x80) n++;
      o += w.substr(0, (size_t)n);
    }
    if (o.size() >= 2) break;
  }
  return o.empty() ? "#" : o;
}

void avatar(int x, int y, int size, const std::string& name, const std::string& pic, Fl_Color bg) {
  Fl_RGB_Image* img = pic.empty() ? nullptr : image_fit(pic, size * 2, size * 2);
  if (img) {
    // Rellena el cuadrado y recorta el círculo con un aro del color del fondo.
    double k = std::max(size / (double)img->w(), size / (double)img->h());
    int dw = (int)(img->w() * k + 0.5), dh = (int)(img->h() * k + 0.5);
    img->scale(dw, dh, 0, 1);
    fl_push_clip(x, y, size, size);
    img->draw(x + (size - dw) / 2, y + (size - dh) / 2);
    fl_pop_clip();
    fl_color(bg);
    fl_line_style(FL_SOLID, size / 3);
    int r = size / 2 + size / 6;
    fl_arc(x + size / 2 - r, y + size / 2 - r, 2 * r, 2 * r, 0, 360);
    fl_line_style(0);
    return;
  }
  fl_color(avatar_color(name));
  fl_pie(x, y, size, size, 0, 360);
  fl_font(FL_HELVETICA_BOLD, size / 3);
  fl_color(FL_WHITE);
  fl_draw(initials(name).c_str(), x, y, size, size, FL_ALIGN_CENTER);
}
std::string size_text(long long b) {
  char t[32];
  if (b >= 1000000) std::snprintf(t, sizeof t, "%.1f MB", b / 1e6);
  else std::snprintf(t, sizeof t, "%lld KB", std::max(1LL, b / 1000));
  return t;
}
const char* kind_icon(int k) {
  switch (k) {
    case K_IMAGE: case K_STICKER: return "📷";
    case K_VIDEO: case K_GIF: return "🎬";
    case K_AUDIO: return "🎤";
    default: return "📄";
  }
}
std::string kind_name(int k) {
  switch (k) {
    case K_IMAGE: return tx::K_PHOTO;
    case K_STICKER: return tx::K_STICKER;
    case K_VIDEO: case K_GIF: return tx::K_VIDEO;
    case K_AUDIO: return tx::K_AUDIO;
    default: return tx::K_DOC;
  }
}

// ---- los estados: un diseño (plantilla, textos, emoji y foto) que se dibuja
// a cualquier tamaño (1080×1920 para publicarlo) y se guarda en estados.jsonl.
struct StatusDesign {
  long long id = 0;
  int tpl = 0;
  std::string title, body, footer, emoji, photo;
};
struct StatusTpl {
  unsigned top, bottom, title, body, footer_bg, footer_fg, deco;
  int style;   // los adornos: 0 ondas, 1 círculos, 2 puntos, 3 estrellas, 4 marco
};
const int STATUS_TPLS = 7;
const StatusTpl& status_tpl(int i) {
  static const StatusTpl t[STATUS_TPLS] = {
      {0x6cc3f7, 0x3a9be8, 0x0b3d91, 0xffffff, 0x0b3d91, 0xffffff, 0x1f6fd1, 0},   // cielo
      {0xffa36c, 0xff5e8a, 0xffffff, 0xfff3e0, 0xffffff, 0xd9465f, 0xffc4a3, 1},   // atardecer
      {0xdff7ee, 0xa8e6cf, 0x0f5132, 0x1d6b4a, 0x0f5132, 0xffffff, 0x7dd3b0, 2},   // menta
      {0x1a1a2e, 0x16213e, 0x00e5ff, 0xe0e0e0, 0x00e5ff, 0x1a1a2e, 0xffffff, 3},   // noche
      {0xfaf6ee, 0xf1e9da, 0x222222, 0x444444, 0x222222, 0xffffff, 0xc9b99a, 4},   // papel
      {0xffd60a, 0xffb703, 0xd00000, 0x1d1d1d, 0xd00000, 0xffffff, 0xfff3b0, 1},   // oferta
      {0x25d366, 0x128c7e, 0xffffff, 0xffffff, 0xffffff, 0x128c7e, 0x5fe39a, 2}};  // whatsapp
  return t[(i % STATUS_TPLS + STATUS_TPLS) % STATUS_TPLS];
}
std::string status_line(const StatusDesign& d) {
  return "{\"id\":" + std::to_string(d.id) + ",\"tpl\":" + std::to_string(d.tpl) + ",\"title\":" + jstr(d.title) +
         ",\"body\":" + jstr(d.body) + ",\"footer\":" + jstr(d.footer) + ",\"emoji\":" + jstr(d.emoji) +
         ",\"photo\":" + jstr(d.photo) + "}";
}
std::vector<StatusDesign> status_parse(const std::string& text) {
  std::vector<StatusDesign> out;
  for (const auto& l : split(text, '\n')) {
    bool ok = false;
    Json j = parse_json(l, &ok);
    if (!ok || j["id"].type != Json::NUM) continue;
    StatusDesign d;
    d.id = (long long)j["id"].n;
    d.tpl = (int)j["tpl"].n;
    d.title = j["title"].str();
    d.body = j["body"].str();
    d.footer = j["footer"].str();
    d.emoji = j["emoji"].str();
    d.photo = j["photo"].str();
    out.push_back(d);
  }
  return out;
}
// Lo que propone la IA: {"title","body","footer","emoji","template"} (aunque venga entre ```).
bool parse_status_ai(const std::string& text, StatusDesign& d) {
  size_t a = text.find('{'), b = text.rfind('}');
  if (a == std::string::npos || b == std::string::npos || b < a) return false;
  bool ok = false;
  Json j = parse_json(text.substr(a, b - a + 1), &ok);
  if (!ok || trim(j["title"].str()).empty()) return false;
  d.title = trim(j["title"].str());
  d.body = trim(j["body"].str());
  d.footer = trim(j["footer"].str());
  d.emoji = trim(j["emoji"].str());
  int t = (int)j["template"].n;
  if (t >= 1 && t <= STATUS_TPLS) d.tpl = t - 1;
  return true;
}
// Dibuja el estado en (X, Y, W, H): las medidas son las de 1080×1920, a escala.
void draw_status(const StatusDesign& d, int X, int Y, int W, int H) {
  const StatusTpl& t = status_tpl(d.tpl);
  double k = W / 1080.0;
  auto S = [k](double v) { return std::max(1, (int)std::lround(v * k)); };
  fl_push_clip(X, Y, W, H);
  for (int yy = 0; yy < H; yy++) {
    double f = yy / (double)std::max(1, H - 1);
    auto mix = [&](int sh) { return (uchar)(((t.top >> sh) & 255) * (1 - f) + ((t.bottom >> sh) & 255) * f); };
    fl_color(fl_rgb_color(mix(16), mix(8), mix(0)));
    fl_xyline(X, Y + yy, X + W - 1);
  }
  Fl_Color deco = fl_rgb_color((uchar)(t.deco >> 16), (uchar)(t.deco >> 8), (uchar)t.deco);
  fl_color(deco);
  if (t.style == 0) {   // ondas en dos esquinas
    for (int r = 0; r < 3; r++) {
      fl_color(r % 2 ? fl_rgb_color((uchar)(t.top >> 16), (uchar)(t.top >> 8), (uchar)t.top) : deco);
      fl_pie(X - S(420 - r * 70), Y - S(420 - r * 70), S(840 - r * 140), S(840 - r * 140), 0, 360);
      fl_pie(X + W - S(420 - r * 70), Y + H - S(420 - r * 70), S(840 - r * 140), S(840 - r * 140), 0, 360);
    }
  } else if (t.style == 1) {   // círculos grandes, suaves
    fl_pie(X + W - S(330), Y - S(170), S(520), S(520), 0, 360);
    fl_pie(X - S(200), Y + H - S(420), S(480), S(480), 0, 360);
    fl_pie(X + S(80), Y + S(140), S(90), S(90), 0, 360);
  } else if (t.style == 2) {   // puntos en dos esquinas
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 5; c++) {
        fl_pie(X + W - S(330) + c * S(60), Y + S(90) + r * S(60), S(16), S(16), 0, 360);
        fl_pie(X + S(90) + c * S(60), Y + H - S(330) + r * S(60), S(16), S(16), 0, 360);
      }
  } else if (t.style == 3) {   // estrellas (siempre las mismas)
    unsigned s = 12345;
    for (int i = 0; i < 70; i++) {
      s = s * 1103515245u + 12345u;
      int sx = (int)((s >> 8) % 1080);
      s = s * 1103515245u + 12345u;
      int sy = (int)((s >> 8) % 1920);
      int r = 3 + (int)((s >> 4) % 6);
      fl_pie(X + S(sx), Y + S(sy), S(r), S(r), 0, 360);
    }
  } else {   // un marco fino
    fl_line_style(FL_SOLID, S(6));
    fl_rect(X + S(60), Y + S(60), W - 2 * S(60), H - 2 * S(60));
    fl_line_style(0);
  }
  // El bloque del centro: emoji, título, raya, texto y foto.
  auto rgbc = [](unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); };
  fl_font(FL_HELVETICA_BOLD, S(104));
  std::vector<std::string> tl = d.title.empty() ? std::vector<std::string>() : wrap(d.title, S(900));
  fl_font(FL_HELVETICA, S(58));
  std::vector<std::string> bl = d.body.empty() ? std::vector<std::string>() : wrap(d.body, S(900));
  Fl_RGB_Image* img = d.photo.empty() ? nullptr : image_fit(d.photo, S(760), S(620));
  int eh = d.emoji.empty() ? 0 : S(260), th = (int)tl.size() * S(122), bh = (int)bl.size() * S(76);
  int total = eh + th + (th && bh ? S(110) : 0) + bh + (img ? S(60) + img->h() : 0);
  int y = Y + std::max(S(150), (H - S(260) - total) / 2);
  if (eh) {
    fl_font(FL_HELVETICA, S(200));
    fl_color(rgbc(t.title));
    fl_draw(d.emoji.c_str(), X, y, W, eh, FL_ALIGN_CENTER);
    y += eh;
  }
  fl_font(FL_HELVETICA_BOLD, S(104));
  fl_color(rgbc(t.title));
  for (const auto& l : tl) {
    fl_draw(l.c_str(), X + S(90), y, W - 2 * S(90), S(122), FL_ALIGN_CENTER);
    y += S(122);
  }
  if (th && bh) {   // la raya de puntos
    y += S(40);
    for (int i = 0; i < 26; i++) fl_pie(X + W / 2 - S(26 * 18 / 2) + i * S(18), y, S(8), S(8), 0, 360);
    y += S(70);
  }
  fl_font(FL_HELVETICA, S(58));
  fl_color(rgbc(t.body));
  for (const auto& l : bl) {
    fl_draw(l.c_str(), X + S(90), y, W - 2 * S(90), S(76), FL_ALIGN_CENTER);
    y += S(76);
  }
  if (img) {
    y += S(60);
    int ix = X + (W - img->w()) / 2;
    fl_color(rgbc(t.footer_bg));
    fl_rectf(ix - S(10), y - S(10), img->w() + 2 * S(10), img->h() + 2 * S(10));
    img->draw(ix, y);
  }
  // Abajo, el pie en una franja.
  if (!d.footer.empty()) {
    fl_font(FL_HELVETICA_BOLD, S(46));
    int fw = std::min(W - 2 * S(80), (int)fl_width(d.footer.c_str()) + S(120)), fh = S(96);
    int fx = X + (W - fw) / 2, fy = Y + H - S(250);
    fl_color(rgbc(t.footer_bg));
    fl_rounded_rectf(fx, fy, fw, fh, S(16));
    fl_color(rgbc(t.footer_fg));
    fl_draw(d.footer.c_str(), fx, fy, fw, fh, FL_ALIGN_CENTER | FL_ALIGN_CLIP);
  }
  fl_pop_clip();
}
// El estado como imagen (nueva: la borra quien la pide).
Fl_RGB_Image* status_image(const StatusDesign& d, int W, int H) {
  Fl_Image_Surface surf(W, H, 0);
  Fl_Surface_Device::push_current(&surf);
  draw_status(d, 0, 0, W, H);
  Fl_RGB_Image* img = surf.image();
  Fl_Surface_Device::pop_current();
  return img;
}
// La vista previa (en la caché: solo se rehace si cambia el diseño).
Fl_RGB_Image* status_preview(const StatusDesign& d, int W, int H) {
  std::string key = "status:" + fnv(status_line(d)) + "@" + std::to_string(W) + "x" + std::to_string(H);
  auto it = images().find(key);
  if (it != images().end()) return it->second;
  return images()[key] = status_image(d, W, H);
}

struct Hit {
  int x, y, w, h, act, idx;
};

// La lista de chats (a la izquierda).
class ChatList : public Fl_Widget {
public:
  std::vector<Chat>* chats = nullptr;
  std::string filter;
  int selected = -1, scroll = 0, content_h = 0, hover = -1;
  std::vector<Hit> hits;
  std::function<void(int)> on_pick;
  std::function<void()> on_tasks;
  int tasks_pending = 0;
  bool tasks_selected = false;
  bool status_selected = false;
  std::function<void()> on_status;   // la fila «🎨 Estados»
  const std::vector<Task>* tasks = nullptr;   // para la bolita de los chats con tareas
  long long now = 0;                          // 0: la hora de verdad
  // Los filtros de arriba y los archivados (aparte, como en WhatsApp).
  enum { F_ALL, F_TASKS, F_TODO, F_WAITING, F_ARCHIVED };
  int mode = F_ALL;
  static const int chips_h = 70;
  std::function<void()> on_mode;
  std::function<void()> on_busy;   // el botón «🔕 Ocupado»
  std::string busy;                // el modo activo ("" si ninguno)
  bool passes(const Chat& c, int m) const {
    if (m == F_ARCHIVED) return c.archived;
    if (c.archived) return false;
    long long t = now ? now : wall_s();
    if (m == F_TASKS) return tasks && oldest_task(*tasks, c.jid) != 0;
    if (m == F_TODO) return !c.last_mine && c.last_t >= t - 3 * 86400;   // me escribieron (3 días) y no contesté
    if (m == F_WAITING) return c.last_mine;                                // escribí yo y no contestaron
    return true;
  }
  int count(int m) const {
    int n = 0;
    if (chats)
      for (const auto& c : *chats) n += passes(c, m) ? 1 : 0;
    return n;
  }
  ChatList(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  bool visible_chat(const Chat& c) const {
    if (!passes(c, mode)) return false;
    return filter.empty() || lower(c.name).find(lower(filter)) != std::string::npos ||
           lower(c.last).find(lower(filter)) != std::string::npos;
  }
  void draw() override {
    hits.clear();
    const Theme& T = th();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(T.list));
    fl_rectf(x(), y(), w(), h());
    // Arriba, fijos: los filtros (dos filas), con cuántos chats hay en cada uno.
    {
      fl_color(rgb(T.list));
      fl_rectf(x(), y(), w(), chips_h);
      struct Chip {
        int mode;
        const char* text;
      };
      const Chip rows[2][3] = {{{F_ALL, tx::F_ALL}, {F_TASKS, tx::F_TASKS}, {-1, nullptr}},
                               {{F_TODO, tx::F_TODO}, {F_WAITING, tx::F_WAITING}, {-1, nullptr}}};
      for (int r = 0; r < 2; r++) {
        int cx = x() + 12, cy = y() + 4 + r * 32;
        for (int k = 0; k < 3 && rows[r][k].text; k++) {
          const Chip& ch = rows[r][k];
          std::string label = ch.text;
          if (ch.mode != F_ALL) label += "  " + std::to_string(count(ch.mode));
          fl_font(FL_HELVETICA_BOLD, 12);
          int cw = (int)fl_width(label.c_str()) + 24;
          bool on = mode == ch.mode;
          bool hot = (int)hits.size() == hover;
          fl_color(on ? rgb(T.dark ? 0x0a332c : 0xd9fdd3) : hot ? rgb(T.hover) : rgb(T.dark ? 0x202c33 : 0xf0f2f5));
          fl_rounded_rectf(cx, cy, cw, 26, 13);
          fl_color(on ? rgb(T.accent) : rgb(T.muted));
          fl_draw(label.c_str(), cx, cy, cw, 26, FL_ALIGN_CENTER);
          hits.push_back({cx, cy, cw, 26, 2, ch.mode});
          cx += cw + 8;
        }
        // Arriba a la derecha: el modo ocupado, siempre a mano (naranja si está activo).
        if (r == 0) {
          std::string label = busy.empty() ? std::string(tx::BUSY_CHIP) : "🔕 " + busy;
          fl_font(FL_HELVETICA_BOLD, 12);
          int cw = std::min((int)fl_width(label.c_str()) + 24, x() + w() - 12 - cx);
          int bx = x() + w() - 12 - cw;
          bool hot = (int)hits.size() == hover;
          fl_color(!busy.empty() ? rgb(0xf59e0b) : hot ? rgb(T.hover) : rgb(T.dark ? 0x202c33 : 0xf0f2f5));
          fl_rounded_rectf(bx, cy, cw, 26, 13);
          fl_color(!busy.empty() ? rgb(0x111b21) : rgb(T.muted));
          fl_draw(fit(label, cw - 16).c_str(), bx, cy, cw, 26, FL_ALIGN_CENTER);
          hits.push_back({bx, cy, cw, 26, 5, -1});
        }
      }
      fl_color(rgb(T.line));
      fl_line(x(), y() + chips_h - 1, x() + w(), y() + chips_h - 1);
    }
    fl_push_clip(x(), y() + chips_h, w(), h() - chips_h);
    int Y = y() + chips_h - scroll;
    // En los archivados: la fila para volver.
    if (mode == F_ARCHIVED) {
      const int rh = 48;
      unsigned row = (int)hits.size() == hover ? T.hover : T.list;
      fl_color(rgb(row));
      fl_rectf(x(), Y, w(), rh);
      hits.push_back({x(), Y, w(), rh, 4, -1});
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(rgb(T.accent));
      fl_draw((std::string("←  ") + tx::ARCHIVED).c_str(), x() + 20, Y + 30);
      fl_color(rgb(T.line));
      fl_line(x(), Y + rh - 1, x() + w(), Y + rh - 1);
      Y += rh;
    }
    // Arriba, la fila de las tareas (no sale al buscar).
    if (filter.empty() && mode != F_ARCHIVED) {
      const int rh = 56;
      unsigned row = tasks_selected ? T.sel : (int)hits.size() == hover ? T.hover : T.list;
      fl_color(rgb(row));
      fl_rectf(x(), Y, w(), rh);
      hits.push_back({x(), Y, w(), rh, 1, -1});
      fl_color(rgb(T.accent));
      fl_pie(x() + 18, Y + 12, 32, 32, 0, 360);
      fl_color(T.dark ? rgb(0x111b21) : FL_WHITE);
      fl_font(FL_HELVETICA_BOLD, 17);
      fl_draw("✓", x() + 18, Y + 12, 32, 32, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(rgb(T.text));
      fl_draw(tx::TASKS_TITLE, x() + 68, Y + 24);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(T.muted));
      fl_draw(fmt(tx::TASKS_PENDING, {std::to_string(tasks_pending)}).c_str(), x() + 68, Y + 43);
      fl_color(rgb(T.line));
      fl_line(x(), Y + rh - 1, x() + w(), Y + rh - 1);
      Y += rh;
      // La de los estados (el diseñador).
      {
        const int sh = 46;
        unsigned r3 = status_selected ? T.sel : (int)hits.size() == hover ? T.hover : T.list;
        fl_color(rgb(r3));
        fl_rectf(x(), Y, w(), sh);
        hits.push_back({x(), Y, w(), sh, 7, -1});
        fl_font(FL_HELVETICA, 18);
        fl_color(rgb(T.muted));
        fl_draw("🎨", x() + 24, Y + 30);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(T.text));
        fl_draw(tx::STATUS_TITLE, x() + 68, Y + 28);
        fl_color(rgb(T.line));
        fl_line(x(), Y + sh - 1, x() + w(), Y + sh - 1);
        Y += sh;
      }
      // Y la de los archivados, si hay.
      int archived = count(F_ARCHIVED);
      if (archived > 0 && mode == F_ALL) {
        const int ah = 46;
        unsigned r2 = (int)hits.size() == hover ? T.hover : T.list;
        fl_color(rgb(r2));
        fl_rectf(x(), Y, w(), ah);
        hits.push_back({x(), Y, w(), ah, 3, -1});
        fl_font(FL_HELVETICA, 18);
        fl_color(rgb(T.muted));
        fl_draw("📦", x() + 24, Y + 30);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(T.text));
        fl_draw(tx::ARCHIVED, x() + 68, Y + 28);
        fl_font(FL_HELVETICA, 12);
        fl_color(rgb(T.accent));
        std::string n = std::to_string(archived);
        fl_draw(n.c_str(), x() + w() - 14 - (int)fl_width(n.c_str()), Y + 28);
        fl_color(rgb(T.line));
        fl_line(x(), Y + ah - 1, x() + w(), Y + ah - 1);
        Y += ah;
      }
    }
    if (chats)
      for (size_t i = 0; i < chats->size(); i++) {
        const Chat& c = (*chats)[i];
        if (!visible_chat(c)) continue;
        int k = (int)i, rh = 68;
        // Solo se dibujan las que se ven (puede haber cientos).
        if (Y + rh < y() + chips_h || Y > y() + h()) {
          Y += rh;
          continue;
        }
        unsigned row = T.list;
        if (k == selected) row = T.sel;
        else if ((int)hits.size() == hover) row = T.hover;
        fl_color(rgb(row));
        fl_rectf(x(), Y, w(), rh);
        hits.push_back({x(), Y, w(), rh, 0, k});
        avatar(x() + 12, Y + 12, 44, c.name, c.pic, rgb(row));
        fl_font(FL_HELVETICA, 11);
        std::string t = clock_time(c.last_t);
        int tw = (int)fl_width(t.c_str());
        fl_color(c.unread ? rgb(T.accent) : rgb(T.muted));
        fl_draw(t.c_str(), x() + w() - 12 - tw, Y + 24);
        // Si tiene tareas pendientes, la bolita de la más antigua.
        int dot = 0;
        if (tasks)
          if (long long since = oldest_task(*tasks, c.jid)) {
            fl_color(rgb(task_age_color(since, now ? now : wall_s())));
            fl_pie(x() + w() - 12 - tw - 16, Y + 15, 10, 10, 0, 360);
            dot = 16;
          }
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(T.text));
        fl_draw(fit(c.name, w() - 90 - tw - dot).c_str(), x() + 68, Y + 26);
        fl_font(FL_HELVETICA, 13);
        fl_color(rgb(T.muted));
        std::string last = c.last;
        for (auto& ch : last)
          if (ch == '\n') ch = ' ';
        fl_draw(fit(last, w() - 112).c_str(), x() + 68, Y + 48);
        if (c.unread > 0) {
          std::string u = std::to_string(c.unread);
          fl_font(FL_HELVETICA_BOLD, 11);
          int uw = std::max(20, (int)fl_width(u.c_str()) + 10);
          fl_color(rgb(T.accent));
          fl_rounded_rectf(x() + w() - 12 - uw, Y + 34, uw, 20, 10);
          fl_color(T.dark ? rgb(0x111b21) : FL_WHITE);
          fl_draw(u.c_str(), x() + w() - 12 - uw, Y + 34, uw, 20, FL_ALIGN_CENTER);
        }
        fl_color(rgb(T.line));
        fl_line(x() + 68, Y + rh - 1, x() + w(), Y + rh - 1);
        Y += rh;
      }
    content_h = Y + scroll - (y() + chips_h);
    fl_pop_clip();
    fl_pop_clip();
  }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = -1;
        for (int k = 0; k < (int)hits.size(); k++)
          if (Fl::event_inside(hits[(size_t)k].x, hits[(size_t)k].y, hits[(size_t)k].w, hits[(size_t)k].h)) i = k;
        if (i != hover) { hover = i; redraw(); }
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        redraw();
        return 1;
      case FL_PUSH:
        for (const auto& h : hits)
          if (Fl::event_inside(h.x, h.y, h.w, h.h)) {
            if (h.act == 1) {
              if (on_tasks) on_tasks();
            } else if (h.act == 5) {
              if (on_busy) on_busy();
            } else if (h.act == 7) {
              if (on_status) on_status();
            } else if (h.act == 2 || h.act == 3 || h.act == 4) {
              // Un filtro, los archivados o volver de ellos.
              mode = h.act == 2 ? h.idx : h.act == 3 ? F_ARCHIVED : F_ALL;
              scroll = 0;
              if (on_mode) on_mode();
              redraw();
            } else if (on_pick) on_pick(h.idx);
            break;
          }
        return 1;
      case FL_MOUSEWHEEL:
        scroll = std::max(0, std::min(scroll + Fl::event_dy() * 30, std::max(0, content_h - (h() - chips_h))));
        redraw();
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// La conversación (bocadillos) y, debajo, las respuestas que propone la IA.
class ChatView : public Fl_Widget {
public:
  Chat* chat = nullptr;
  std::vector<std::string>* options = nullptr;
  std::string busy, notice;   // «Pensando…» / avisos
  int hover = -1;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;
  // La vista de las tareas (en vez del chat).
  std::vector<Task>* tasks = nullptr;
  bool tasks_mode = false;
  int task_scroll = 0, task_content = 0;
  long long now = 0;   // la hora para la edad de las tareas (0: la de verdad)
  // Desplazarse por la conversación (desde abajo, en píxeles).
  int msg_scroll = 0, max_scroll = 0, scroll_to = -1;
  bool more = false, asked_more = false;   // hay mensajes más antiguos por cargar
  // Cada mensaje, ya partido en líneas (se calcula solo si cambia algo).
  struct Lay {
    std::vector<std::string> lines, trans;   // trans: la traducción (o el original), debajo
    std::string seps;
    int bw = 0, bh = 0;
  };
  std::vector<Lay> lays;
  long long lay_id = 0, lay_first = 0, lay_last = 0;
  size_t lay_n = 0;
  int lay_w = 0;
  bool lay_dirty = true;
  // Seleccionar texto: de [sel_a] a [sel_b] (mensaje, línea, byte).
  struct Pos {
    int msg = -1, line = 0, ch = 0;
  };
  Pos sel_a, sel_b;
  bool selecting = false;
  struct LineBox {
    int msg, line, x, y;
    std::vector<int> xs;   // dónde empieza cada letra (y el final)
    std::vector<int> at;   // su byte en la línea
  };
  std::vector<LineBox> boxes;
  // Buscar en el chat.
  bool find_open = false;
  std::string find;
  std::vector<int> matches;   // los mensajes que lo tienen, del más antiguo al más nuevo
  int match = -1;
  Fl_Input* find_input = nullptr;
  std::string translate_label;   // el idioma del chat abierto si se traduce ("" si no)
  // El diseñador de estados (en vez del chat).
  std::vector<StatusDesign>* designs = nullptr;
  int design = -1;
  bool status_mode = false;
  // Acciones: 40 plantilla, 41 título, 42 texto, 43 pie, 44 emoji, 45 foto, 46 quitar
  // la foto, 47 nuevo, 48 con IA, 49 guardar la imagen, 50 publicar, 51 abrir uno, 52 borrarlo.
  void draw_status_view() {
    const Theme& T = th();
    const int head = 60;
    Fl_Color on_accent = T.dark ? rgb(0x111b21) : FL_WHITE;
    // La cabecera.
    fl_color(rgb(T.panel));
    fl_rectf(x(), y(), w(), head);
    fl_color(rgb(T.card_line));
    fl_line(x(), y() + head - 1, x() + w(), y() + head - 1);
    fl_font(FL_HELVETICA_BOLD, 18);
    fl_color(rgb(T.text));
    fl_draw(tx::STATUS_TITLE, x() + 20, y() + 28);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(T.muted));
    fl_draw(tx::STATUS_HELP, x() + 20, y() + 48);
    fl_font(FL_HELVETICA_BOLD, 12);
    int bx = x() + w() - 16 - ((int)fl_width(tx::STATUS_PUBLISH) + 20);
    bool has = designs && design >= 0 && design < (int)designs->size();
    if (has) button(bx, y() + 17, tx::STATUS_PUBLISH, 50, -1, on_accent, rgb(T.accent));
    bx -= 8 + (int)fl_width(tx::STATUS_SAVE_IMAGE) + 20;
    if (has) button(bx, y() + 17, tx::STATUS_SAVE_IMAGE, 49, -1, rgb(T.text), rgb(T.card));
    bx -= 8 + (int)fl_width(tx::STATUS_AI) + 20;
    button(bx, y() + 17, tx::STATUS_AI, 48, -1, rgb(T.text), rgb(T.card));
    bx -= 8 + (int)fl_width(tx::STATUS_NEW) + 20;
    button(bx, y() + 17, tx::STATUS_NEW, 47, -1, rgb(T.text), rgb(T.card));
    // A la izquierda, los guardados (en miniatura; el último arriba).
    int ty = y() + head + 14;
    if (designs)
      for (int i = (int)designs->size() - 1; i >= 0 && ty + 160 < y() + h(); i--) {
        int tx0 = x() + 16;
        if (i == design) {
          fl_color(rgb(T.accent));
          fl_rectf(tx0 - 4, ty - 4, 98, 168);
        }
        if (Fl_RGB_Image* th_img = status_preview((*designs)[(size_t)i], 90, 160)) th_img->draw(tx0, ty);
        hits.push_back({tx0, ty, 90, 160, 51, i});
        fl_color(rgb(0x111b21));
        fl_pie(tx0 + 68, ty + 4, 18, 18, 0, 360);
        fl_color(FL_WHITE);
        fl_font(FL_HELVETICA_BOLD, 10);
        fl_draw("✕", tx0 + 68, ty + 4, 18, 18, FL_ALIGN_CENTER);
        hits.insert(hits.end() - 1, {tx0 + 66, ty + 2, 22, 22, 52, i});   // antes que la miniatura
        ty += 178;
      }
    if (!has) {
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(T.muted));
      fl_draw(tx::STATUS_EMPTY, x() + 140, y() + head, w() - 180, h() - head, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      return;
    }
    const StatusDesign& d = (*designs)[(size_t)design];
    // En el centro, la vista previa (9:16).
    int ph = h() - head - 32, pw = ph * 9 / 16;
    int px = x() + 136, py = y() + head + 16;
    if (Fl_RGB_Image* prev = status_preview(d, pw, ph)) prev->draw(px, py);
    fl_color(rgb(T.card_line));
    fl_rect(px - 1, py - 1, pw + 2, ph + 2);
    // A la derecha, lo que se cambia.
    int cx = px + pw + 28, cy = py + 4, cw = x() + w() - 20 - cx;
    fl_font(FL_HELVETICA_BOLD, 12);
    fl_color(rgb(T.muted));
    fl_draw(tx::STATUS_TEMPLATE, cx, cy + 12);
    cy += 22;
    for (int k = 0; k < STATUS_TPLS; k++) {
      const StatusTpl& t = status_tpl(k);
      int sx = cx + k * 40;
      if (k == d.tpl) {
        fl_color(rgb(T.text));
        fl_pie(sx - 3, cy - 3, 40, 40, 0, 360);
        fl_color(rgb(T.chat));
        fl_pie(sx - 1, cy - 1, 36, 36, 0, 360);
      }
      fl_color(rgb(t.top));
      fl_pie(sx + 1, cy + 1, 32, 32, 0, 360);
      fl_color(rgb(t.bottom));
      fl_pie(sx + 9, cy + 9, 16, 16, 0, 360);
      hits.push_back({sx, cy, 34, 34, 40, k});
    }
    cy += 52;
    struct Field {
      const char* label;
      const std::string* value;
      int act;
    };
    const Field fields[] = {{tx::STATUS_F_TITLE, &d.title, 41}, {tx::STATUS_F_BODY, &d.body, 42},
                            {tx::STATUS_F_FOOTER, &d.footer, 43}, {tx::STATUS_F_EMOJI, &d.emoji, 44}};
    for (const auto& f : fields) {
      int nb = button(cx, cy, f.label, f.act, -1, rgb(T.text), rgb(T.card));
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(T.muted));
      std::string v = f.value->empty() ? "—" : *f.value;
      for (auto& ch : v)
        if (ch == '\n') ch = ' ';
      fl_draw(fit(v, std::max(40, cx + cw - nb - 10)).c_str(), nb + 10, cy + 18);
      cy += 38;
    }
    int nb = button(cx, cy, tx::STATUS_F_PHOTO, 45, -1, rgb(T.text), rgb(T.card));
    if (!d.photo.empty()) {
      nb = button(nb + 6, cy, tx::STATUS_F_NO_PHOTO, 46, -1, rgb(T.text), rgb(T.card));
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(T.muted));
      std::string pn = starts(d.photo, "demo:") ? std::string(tx::K_PHOTO) : file_base(d.photo);
      fl_draw(fit(pn, std::max(40, cx + cw - nb - 10)).c_str(), nb + 10, cy + 18);
    }
  }
  // El visor: una foto en grande, encima de todo ("" si está cerrado).
  std::string viewer, viewer_title;
  ChatView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  // Acciones: 30 descargar, 31 abrir con su programa, 32 cerrar.
  void draw_viewer() {
    const Theme& T = th();
    fl_color(rgb(0x0b141a));
    fl_rectf(x(), y(), w(), h());
    const int bar = 56;
    fl_color(rgb(0x202c33));
    fl_rectf(x(), y(), w(), bar);
    // Los botones, de derecha a izquierda.
    fl_font(FL_HELVETICA_BOLD, 12);
    int bx = x() + w() - 16 - ((int)fl_width("✕") + 20);
    button(bx, y() + 15, "✕", 32, -1, rgb(0xe9edef), rgb(0x2a3942));
    bx -= 8 + (int)fl_width(tx::OPEN_EXTERNAL) + 20;
    if (!starts(viewer, "demo:")) button(bx, y() + 15, tx::OPEN_EXTERNAL, 31, -1, rgb(0xe9edef), rgb(0x2a3942));
    bx -= 8 + (int)fl_width(tx::DOWNLOAD) + 20;
    button(bx, y() + 15, tx::DOWNLOAD, 30, -1, rgb(0x111b21), rgb(T.dark ? 0x00a884 : 0x25d366));
    fl_font(FL_HELVETICA_BOLD, 14);
    fl_color(rgb(0xe9edef));
    fl_draw(fit(viewer_title, bx - x() - 40).c_str(), x() + 20, y() + 34);
    // La foto, lo más grande que quepa.
    Fl_RGB_Image* img = image_fit(viewer, w() - 60, h() - bar - 40);
    if (img) img->draw(x() + (w() - img->w()) / 2, y() + bar + (h() - bar - img->h()) / 2);
    else {
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(0x8696a0));
      fl_draw(tx::NO_PREVIEW, x(), y() + bar, w(), h() - bar, FL_ALIGN_CENTER);
    }
  }

  static bool before(const Pos& a, const Pos& b) {
    if (a.msg != b.msg) return a.msg < b.msg;
    if (a.line != b.line) return a.line < b.line;
    return a.ch < b.ch;
  }
  bool has_selection() const {
    return sel_a.msg >= 0 && (sel_a.msg != sel_b.msg || sel_a.line != sel_b.line || sel_a.ch != sel_b.ch);
  }
  void clear_selection() {
    sel_a = sel_b = Pos();
    selecting = false;
  }
  // El texto seleccionado, con sus saltos de línea.
  std::string selected_text() const {
    if (!has_selection() || !chat) return "";
    Pos lo = before(sel_a, sel_b) ? sel_a : sel_b, hi = before(sel_a, sel_b) ? sel_b : sel_a;
    std::string out;
    for (int m = lo.msg; m <= hi.msg && m < (int)lays.size(); m++) {
      const Lay& L = lays[(size_t)m];
      if (m > lo.msg && !out.empty()) out += "\n";
      for (int li = 0; li < (int)L.lines.size(); li++) {
        if (m == lo.msg && li < lo.line) continue;
        if (m == hi.msg && li > hi.line) break;
        const std::string& l = L.lines[(size_t)li];
        size_t a = (m == lo.msg && li == lo.line) ? (size_t)lo.ch : 0;
        size_t b = (m == hi.msg && li == hi.line) ? (size_t)hi.ch : l.size();
        if (a < b && b <= l.size()) out += l.substr(a, b - a);
        bool last = (m == hi.msg && li == hi.line) || li + 1 == (int)L.lines.size();
        if (!last) out += L.seps[(size_t)li] == 'n' ? "\n" : L.seps[(size_t)li] == 's' ? " " : "";
      }
    }
    return out;
  }
  void select_message(int m) {
    if (m < 0 || m >= (int)lays.size() || lays[(size_t)m].lines.empty()) return;
    sel_a = {m, 0, 0};
    sel_b = {m, (int)lays[(size_t)m].lines.size() - 1, (int)lays[(size_t)m].lines.back().size()};
  }
  // La letra bajo el ratón; [strict]: solo si está encima de una línea.
  bool pos_at(int mx, int my, bool strict, Pos& out) const {
    const LineBox* best = nullptr;
    int dist = 1 << 30;
    for (const auto& b : boxes) {
      bool in_y = my >= b.y && my < b.y + 19;
      if (strict && !(in_y && mx >= b.x - 4 && mx <= b.xs.back() + 6)) continue;
      int d = in_y ? 0 : std::min(std::abs(my - b.y), std::abs(my - (b.y + 19)));
      if (d < dist || (d == dist && best && std::abs(mx - b.x) < std::abs(mx - best->x))) {
        dist = d;
        best = &b;
      }
    }
    if (!best) return false;
    out.msg = best->msg;
    out.line = best->line;
    out.ch = best->at.back();
    for (size_t k = 0; k + 1 < best->xs.size(); k++)
      if (mx < (best->xs[k] + best->xs[k + 1]) / 2) {
        out.ch = best->at[k];
        break;
      }
    return true;
  }
  void ensure_layout(int maxw) {
    long long first = chat->msgs.empty() ? 0 : chat->msgs.front().t, last = chat->msgs.empty() ? 0 : chat->msgs.back().t;
    if (!lay_dirty && lay_id == chat->id && lay_n == chat->msgs.size() && lay_w == maxw && lay_first == first &&
        lay_last == last)
      return;
    if (lay_id != chat->id || lay_n != chat->msgs.size()) clear_selection();
    lay_dirty = false;
    lay_id = chat->id;
    lay_n = chat->msgs.size();
    lay_w = maxw;
    lay_first = first;
    lay_last = last;
    lays.assign(chat->msgs.size(), Lay());
    for (size_t i = 0; i < chat->msgs.size(); i++) {
      const Msg& m = chat->msgs[i];
      Lay& L = lays[i];
      fl_font(FL_HELVETICA, 14);
      if (!m.text.empty()) L.lines = wrap_seps(m.text, maxw - 24, L.seps);
      int who_h = m.who.empty() ? 0 : 18, ah = attach_h(m);
      Fl_RGB_Image* img = attach_image(m);
      int bw = 0;
      for (const auto& l : L.lines) bw = std::max(bw, (int)fl_width(l.c_str()));
      fl_font(FL_HELVETICA_BOLD, 12);
      if (!m.who.empty()) bw = std::max(bw, (int)fl_width(m.who.c_str()));
      if (img) bw = std::max(bw, img->w());
      else if (ah) bw = std::max(bw, 260);
      if (!m.trans.empty()) {
        fl_font(FL_HELVETICA_ITALIC, 13);
        std::string head = m.mine ? std::string(tx::TRANS_ORIGINAL) + " " : "🌐 ";
        L.trans = wrap(head + m.trans, maxw - 24);
        for (const auto& l : L.trans) bw = std::max(bw, (int)fl_width(l.c_str()));
      }
      L.bw = std::max(bw + 24, 90);
      L.bh = (int)L.lines.size() * 19 + who_h + ah + 30 + (L.trans.empty() ? 0 : 9 + (int)L.trans.size() * 17);
    }
  }

  int button(int x, int y, const char* text, int act, int idx, Fl_Color fg, Fl_Color fill) {
    fl_font(FL_HELVETICA_BOLD, 12);
    int w = (int)fl_width(text) + 20, h = 26;
    bool hot = (int)hits.size() == hover;
    hits.push_back({x, y, w, h, act, idx});
    round_box(x, y, w, h, 13, hot ? rgb(th().dark ? 0x005c4b : 0xd9fdd3) : fill, rgb(th().card_line));
    fl_color(fg);
    fl_draw(text, x, y, w, h, FL_ALIGN_CENTER);
    return x + w;
  }
  // El adjunto de un mensaje: su alto dentro del bocadillo y cómo se dibuja.
  static Fl_RGB_Image* attach_image(const Msg& m) {
    if ((m.kind != K_IMAGE && m.kind != K_STICKER) || m.media.empty()) return nullptr;
    if (m.kind == K_STICKER) return image_fit(m.media, 160, 160);   // como en WhatsApp, más pequeños
    return image_fit(m.media, 260, 200);
  }
  static int attach_h(const Msg& m) {
    if (m.kind == K_TEXT) return 0;
    if (Fl_RGB_Image* img = attach_image(m)) return img->h() + 8;
    return 46;
  }
  // Acciones: 10 hecha/pendiente, 11 abrir su chat, 12 borrar, 13 nueva.
  void draw_tasks() {
    const Theme& T = th();
    const int head = 60;
    Fl_Color on_accent = T.dark ? rgb(0x111b21) : FL_WHITE;
    std::vector<int> order = tasks ? tasks_order(*tasks) : std::vector<int>();
    int Y = y() + head + 12 - task_scroll;
    fl_push_clip(x(), y() + head, w(), h() - head);
    if (order.empty()) {
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(T.muted));
      fl_draw(tx::TASKS_EMPTY, x() + 80, y() + h() / 2 - 40, w() - 160, 80, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
    }
    for (int k : order) {
      const Task& t = (*tasks)[(size_t)k];
      const int rh = 66;
      if (Y + rh > y() + head - 80 && Y < y() + h()) {
        round_box(x() + 16, Y, w() - 32, rh - 8, 10, rgb(T.card), rgb(T.card_line));
        int cx = x() + 30, cy = Y + (rh - 8) / 2 - 11;
        hits.push_back({cx - 4, cy - 4, 30, 30, 10, k});
        if (t.done) {
          fl_color(rgb(T.accent));
          fl_pie(cx, cy, 22, 22, 0, 360);
          fl_color(on_accent);
          fl_font(FL_HELVETICA_BOLD, 14);
          fl_draw("✓", cx, cy, 22, 22, FL_ALIGN_CENTER);
        } else {
          fl_color(rgb(T.muted));
          fl_line_style(FL_SOLID, 2);
          fl_arc(cx, cy, 22, 22, 0, 360);
          fl_line_style(0);
        }
        // Los botones, de derecha a izquierda.
        fl_font(FL_HELVETICA_BOLD, 12);
        int bx = x() + w() - 32 - ((int)fl_width(tx::DELETE) + 20);
        if (!t.jid.empty()) bx -= (int)fl_width(tx::OPEN_CHAT) + 20 + 6;
        int text_w = bx - (x() + 66) - 12;
        int b2 = bx;
        if (!t.jid.empty()) b2 = button(b2, Y + 16, tx::OPEN_CHAT, 11, k, rgb(T.text), rgb(T.card)) + 6;
        button(b2, Y + 16, tx::DELETE, 12, k, rgb(T.text), rgb(T.card));
        fl_font(FL_HELVETICA, 14);
        fl_color(t.done ? rgb(T.muted) : rgb(T.text));
        std::string title = fit(t.title, text_w);
        fl_draw(title.c_str(), x() + 66, Y + 25);
        if (t.done) fl_line(x() + 66, Y + 20, x() + 66 + (int)fl_width(title.c_str()), Y + 20);
        int sx = x() + 66;
        if (!t.done) {
          // La bolita: cuánto lleva esperando.
          fl_color(rgb(task_age_color(t.created, now ? now : wall_s())));
          fl_pie(sx, Y + 35, 10, 10, 0, 360);
          sx += 16;
        }
        fl_font(FL_HELVETICA, 11);
        fl_color(rgb(T.muted));
        std::string when = day_text(t.created) + " " + clock_time(t.created);
        std::string sub = t.chat.empty() ? when : fmt(tx::TASK_FROM, {t.chat, when});
        fl_draw(fit(sub, text_w - (sx - (x() + 66))).c_str(), sx, Y + 44);
      }
      Y += rh;
    }
    task_content = Y + task_scroll - (y() + head);
    fl_pop_clip();
    // La cabecera.
    fl_color(rgb(T.panel));
    fl_rectf(x(), y(), w(), head);
    fl_color(rgb(T.card_line));
    fl_line(x(), y() + head - 1, x() + w(), y() + head - 1);
    fl_font(FL_HELVETICA_BOLD, 18);
    fl_color(rgb(T.text));
    fl_draw(tx::TASKS_TITLE, x() + 20, y() + 28);
    int pend = tasks ? tasks_pending(*tasks) : 0, total = tasks ? (int)tasks->size() : 0;
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(T.muted));
    fl_draw((fmt(tx::TASKS_PENDING, {std::to_string(pend)}) + " · " + fmt(tx::TASKS_DONE_N, {std::to_string(total - pend)})).c_str(),
            x() + 20, y() + 48);
    fl_font(FL_HELVETICA_BOLD, 12);
    button(x() + w() - 20 - ((int)fl_width(tx::NEW_TASK) + 20), y() + 17, tx::NEW_TASK, 13, -1, on_accent, rgb(T.accent));
  }
  void draw() override {
    hits.clear();
    const Theme& T = th();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(T.chat));
    fl_rectf(x(), y(), w(), h());
    if ((tasks_mode || status_mode || !chat || !viewer.empty()) && find_input && find_input->visible()) find_input->hide();
    if (!viewer.empty()) {
      draw_viewer();
      fl_pop_clip();
      return;
    }
    if (status_mode) {
      draw_status_view();
      fl_pop_clip();
      return;
    }
    if (tasks_mode) {
      draw_tasks();
      fl_pop_clip();
      return;
    }
    if (!chat) {
      fl_font(FL_HELVETICA_BOLD, 18);
      fl_color(rgb(T.text));
      fl_draw(tx::PICK_CHAT, x(), y() + h() / 2 - 30, w(), 30, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(T.muted));
      fl_draw(notice.empty() ? tx::PICK_CHAT_HELP : notice.c_str(), x() + 60, y() + h() / 2 + 4, w() - 120, 60,
              FL_ALIGN_CENTER | FL_ALIGN_WRAP | FL_ALIGN_TOP);
      fl_pop_clip();
      return;
    }
    // La zona de las sugerencias (abajo) y los mensajes encima, del final hacia arriba.
    const int head = 60;
    int sugg_h = 0;
    if (!busy.empty()) sugg_h = 56;
    else if (options && !options->empty()) sugg_h = 40 + (int)options->size() * 72;
    int bottom = y() + h() - sugg_h - 8;
    int maxw = std::min(560, (int)(w() * 0.68));
    ensure_layout(maxw);
    int total = 8;
    for (const auto& L : lays) total += L.bh + 6;
    int view_h = bottom - (y() + head);
    max_scroll = std::max(0, total - view_h);
    if (scroll_to >= 0 && scroll_to < (int)lays.size()) {
      // Que ese mensaje quede en medio.
      int off = 0;
      for (int j = (int)lays.size() - 1; j > scroll_to; j--) off += lays[(size_t)j].bh + 6;
      msg_scroll = off + lays[(size_t)scroll_to].bh / 2 - view_h / 2;
      scroll_to = -1;
    }
    msg_scroll = std::max(0, std::min(msg_scroll, max_scroll));
    boxes.clear();
    Pos lo = before(sel_a, sel_b) ? sel_a : sel_b, hi = before(sel_a, sel_b) ? sel_b : sel_a;
    bool sel = has_selection();
    int current_match = match >= 0 && match < (int)matches.size() ? matches[(size_t)match] : -1;
    int Y = bottom + msg_scroll;
    fl_push_clip(x(), y() + head, w(), bottom - (y() + head) + 8);
    for (int i = (int)chat->msgs.size() - 1; i >= 0 && Y > y() + head; i--) {
      const Msg& m = chat->msgs[(size_t)i];
      const Lay& L = lays[(size_t)i];
      int bw = L.bw, bh = L.bh, who_h = m.who.empty() ? 0 : 18, ah = attach_h(m), lh = 19;
      Y -= bh + 6;
      if (Y > bottom) continue;   // todavía por debajo de lo que se ve
      Fl_RGB_Image* img = attach_image(m);
      int bx = m.mine ? x() + w() - 20 - bw : x() + 20;
      round_box(bx, Y, bw, bh, 9, rgb(m.mine ? T.out : T.in), rgb(m.mine ? T.out_line : T.in_line));
      int ty = Y + 22;
      if (!m.who.empty()) {
        fl_font(FL_HELVETICA_BOLD, 12);
        fl_color(avatar_color(m.who));
        fl_draw(m.who.c_str(), bx + 12, ty);
        ty += who_h;
      }
      if (ah) {
        int ay = ty - 14;
        if (img) {
          img->draw(bx + 12, ay);
          hits.push_back({bx + 12, ay, img->w(), img->h(), 4, i});
        } else {
          // Un archivo: icono, nombre y tamaño (o «sin descargar»).
          round_box(bx + 10, ay, bw - 20, 40, 7, rgb(T.dark ? 0x111b21 : 0xf5f6f6), rgb(T.card_line));
          fl_font(FL_HELVETICA, 20);
          fl_color(rgb(T.text));
          fl_draw(kind_icon(m.kind), bx + 18, ay + 28);
          std::string name = m.title.empty() ? kind_name(m.kind) : m.title;
          fl_font(FL_HELVETICA_BOLD, 13);
          fl_draw(fit(name, bw - 76).c_str(), bx + 50, ay + 17);
          fl_font(FL_HELVETICA, 11);
          fl_color(rgb(T.muted));
          std::string sub = m.media.empty() ? std::string(tx::NOT_DOWNLOADED) : kind_name(m.kind);
          if (m.size > 0) sub += " · " + size_text(m.size);
          fl_draw(fit(sub, bw - 76).c_str(), bx + 50, ay + 33);
          if (!m.media.empty()) hits.push_back({bx + 10, ay, bw - 20, 40, 4, i});
        }
        ty += ah;
      }
      fl_font(FL_HELVETICA, 14);
      for (int li = 0; li < (int)L.lines.size(); li++) {
        const std::string& l = L.lines[(size_t)li];
        int lx = bx + 12;
        LineBox box{i, li, lx, ty - 15, {}, {}};
        for (size_t k = 0; k < l.size();) {
          box.xs.push_back(lx + (int)fl_width(l.c_str(), (int)k));
          box.at.push_back((int)k);
          size_t j = k + 1;
          while (j < l.size() && ((unsigned char)l[j] & 0xC0) == 0x80) j++;
          k = j;
        }
        box.xs.push_back(lx + (int)fl_width(l.c_str()));
        box.at.push_back((int)l.size());
        // Lo seleccionado, de fondo.
        if (sel && (i > lo.msg || (i == lo.msg && li >= lo.line)) && (i < hi.msg || (i == hi.msg && li <= hi.line))) {
          int a = (i == lo.msg && li == lo.line) ? lo.ch : 0;
          int b = (i == hi.msg && li == hi.line) ? hi.ch : (int)l.size();
          if (b > a) {
            int xa = lx + (int)fl_width(l.c_str(), a), xb = lx + (int)fl_width(l.c_str(), b);
            fl_color(rgb(T.dark ? 0x2b5278 : 0xb3d7ff));
            fl_rectf(xa, ty - 15, xb - xa, lh);
          }
        }
        // Lo que se busca, resaltado (más fuerte en el mensaje actual).
        std::vector<std::pair<int, int>> marks;
        if (!find.empty())
          for (size_t p : find_all(l, find)) {
            int xa = lx + (int)fl_width(l.c_str(), (int)p), xb = lx + (int)fl_width(l.c_str(), (int)(p + find.size()));
            fl_color(rgb(i == current_match ? 0xff9632 : 0xffe066));
            fl_rectf(xa, ty - 15, xb - xa, lh);
            marks.push_back({(int)p, (int)find.size()});
          }
        fl_color(rgb(T.text));
        fl_draw(l.c_str(), lx, ty);
        for (const auto& mk : marks) {
          fl_color(rgb(0x111b21));
          fl_draw(l.c_str() + mk.first, mk.second, lx + (int)fl_width(l.c_str(), mk.first), ty);
        }
        if (ty - 15 >= y() + head) boxes.push_back(box);   // las que tapa la cabecera no se seleccionan
        ty += lh;
      }
      // La traducción (o lo que escribí), debajo de una raya.
      if (!L.trans.empty()) {
        fl_color(rgb(m.mine ? T.out_line : T.in_line));
        fl_line(bx + 12, ty - 10, bx + bw - 12, ty - 10);
        fl_font(FL_HELVETICA_ITALIC, 13);
        fl_color(rgb(T.muted));
        ty += 4;
        for (const auto& l : L.trans) {
          fl_draw(l.c_str(), bx + 12, ty);
          ty += 17;
        }
      }
      fl_font(FL_HELVETICA, 10);
      fl_color(rgb(T.muted));
      std::string t = clock_time(m.t);
      fl_draw(t.c_str(), bx + bw - 10 - (int)fl_width(t.c_str()), Y + bh - 8);
      // Clic derecho sobre el bocadillo: su menú.
      int top = std::max(Y, y() + head);
      if (Y + bh > top) hits.push_back({bx, top, bw, std::min(Y + bh, bottom + 8) - top, 6, i});
    }
    // Volver abajo, si se ha subido.
    if (msg_scroll > 40) {
      int cx = x() + w() - 62, cy = bottom - 46;
      fl_color(rgb(T.card_line));
      fl_pie(cx - 1, cy - 1, 42, 42, 0, 360);
      fl_color(rgb(T.card));
      fl_pie(cx, cy, 40, 40, 0, 360);
      fl_color(rgb(T.text));
      fl_font(FL_HELVETICA_BOLD, 18);
      fl_draw("↓", cx, cy, 40, 40, FL_ALIGN_CENTER);
      hits.insert(hits.begin(), {cx, cy, 40, 40, 21, -1});
    }
    fl_pop_clip();
    // La cabecera: la foto, el nombre y el teléfono (o «grupo»).
    fl_color(rgb(T.panel));
    fl_rectf(x(), y(), w(), head);
    fl_color(rgb(T.card_line));
    fl_line(x(), y() + head - 1, x() + w(), y() + head - 1);
    avatar(x() + 16, y() + 10, 40, chat->name, chat->pic, rgb(T.panel));
    if (!chat->pic.empty()) hits.push_back({x() + 16, y() + 10, 40, 40, 33, -1});   // la foto, en grande
    // A la derecha: «+ Tarea» y buscar (el campo, cuántos hay, ▲ ▼ ✕).
    fl_font(FL_HELVETICA_BOLD, 12);
    int rx = x() + w() - 20 - ((int)fl_width(tx::ADD_TASK) + 20);
    button(rx, y() + 17, tx::ADD_TASK, 5, -1, rgb(T.text), rgb(T.card));
    rx -= 8;
    // Traducir: «🌐 Traducir» o el idioma elegido, en verde.
    std::string tl = translate_label.empty() ? std::string(tx::TRANSLATE) : "🌐 " + translate_label;
    rx -= (int)fl_width(tl.c_str()) + 20;
    if (translate_label.empty()) button(rx, y() + 17, tl.c_str(), 27, -1, rgb(T.text), rgb(T.card));
    else button(rx, y() + 17, tl.c_str(), 27, -1, T.dark ? rgb(0x111b21) : FL_WHITE, rgb(T.accent));
    rx -= 8;
    if (!find_open) {
      rx -= (int)fl_width(tx::FIND) + 20;
      button(rx, y() + 17, tx::FIND, 22, -1, rgb(T.text), rgb(T.card));
      if (find_input && find_input->visible()) find_input->hide();
    } else {
      const int fw = 220, cw = 78, sw = 34;
      rx -= fw + 8 + cw + 3 * sw;
      if (find_input) {
        if (find_input->x() != rx || find_input->y() != y() + 16) find_input->resize(rx, y() + 16, fw, 28);
        if (!find_input->visible()) find_input->show();
      }
      std::string count = find.empty() ? "" : matches.empty() ? std::string(tx::FIND_NONE)
                                                               : fmt(tx::FIND_COUNT, {std::to_string(match + 1), std::to_string(matches.size())});
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(T.muted));
      fl_draw(count.c_str(), rx + fw + 8, y() + 16, cw, 28, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
      int bx2 = rx + fw + 8 + cw;
      bx2 = button(bx2, y() + 17, "▲", 23, -1, rgb(T.text), rgb(T.card)) + 2;
      bx2 = button(bx2, y() + 17, "▼", 24, -1, rgb(T.text), rgb(T.card)) + 2;
      button(bx2, y() + 17, "✕", 25, -1, rgb(T.text), rgb(T.card));
      // El campo va encima de la cabecera: que se dibuje después de ella, siempre.
      if (find_input && find_input->visible()) find_input->damage(FL_DAMAGE_ALL);
    }
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(T.text));
    fl_draw(fit(chat->name, rx - (x() + 68) - 12).c_str(), x() + 68, y() + 27);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(T.muted));
    std::string ph = phone_of(chat->jid);
    // Debajo: el teléfono (o «Grupo») y la bandera y la hora de cada país.
    std::string sub = chat->group ? std::string(tx::GROUP) : (ph.empty() ? "" : "+" + ph);
    long long t_now = now ? now : wall_s();
    for (const Country* k : chat_countries(*chat)) {
      std::string tm = time_in(k->tz, t_now);
      sub += (sub.empty() ? "" : "   ·   ") + flag_of(k->iso) + (tm.empty() ? "" : " " + fmt(tx::LOCAL_TIME, {tm}));
    }
    fl_draw(fit(sub, rx - (x() + 68) - 12).c_str(), x() + 68, y() + 46);
    // Las sugerencias.
    int sy = y() + h() - sugg_h;
    if (sugg_h) {
      fl_color(rgb(T.panel));
      fl_rectf(x(), sy, w(), sugg_h);
      fl_color(rgb(T.card_line));
      fl_line(x(), sy, x() + w(), sy);
    }
    if (!busy.empty()) {
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(rgb(T.text));
      fl_draw(busy.c_str(), x(), sy, w(), sugg_h, FL_ALIGN_CENTER);
    } else if (options && !options->empty()) {
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(rgb(T.muted));
      fl_draw(tx::SUGGESTIONS, x() + 20, sy + 24);
      int cy = sy + 36;
      for (size_t k = 0; k < options->size(); k++) {
        const std::string& o = (*options)[k];
        round_box(x() + 16, cy, w() - 32, 64, 10, rgb(T.card), rgb(T.card_line));
        fl_font(FL_HELVETICA, 13);
        fl_color(rgb(T.text));
        auto lines = wrap(o, w() - 32 - 260);
        int ly = cy + 22;
        for (size_t li = 0; li < lines.size() && li < 2; li++) {
          std::string l = li == 1 && lines.size() > 2 ? fit(lines[li] + "…", w() - 300) : lines[li];
          fl_draw(l.c_str(), x() + 30, ly);
          ly += 19;
        }
        int bx = x() + w() - 32 - 220;
        bx = button(bx, cy + 19, tx::SEND, 3, (int)k, T.dark ? rgb(0x111b21) : FL_WHITE, rgb(T.accent)) + 6;
        bx = button(bx, cy + 19, tx::USE, 1, (int)k, rgb(T.text), rgb(T.card)) + 6;
        button(bx, cy + 19, tx::COPY, 2, (int)k, rgb(T.text), rgb(T.card));
        cy += 72;
      }
    }
    fl_pop_clip();
  }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = -1;
        for (int k = 0; k < (int)hits.size(); k++)
          if (Fl::event_inside(hits[(size_t)k].x, hits[(size_t)k].y, hits[(size_t)k].w, hits[(size_t)k].h)) i = k;
        if (i >= 0 && hits[(size_t)i].act == 6) i = -1;   // los bocadillos no son botones
        if (i != hover) { hover = i; redraw(); }
        Pos p;
        Fl_Cursor cur = i >= 0 ? FL_CURSOR_HAND : pos_at(Fl::event_x(), Fl::event_y(), true, p) ? FL_CURSOR_INSERT : FL_CURSOR_DEFAULT;
        if (window()) window()->cursor(cur);
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_FOCUS:
      case FL_UNFOCUS:
        return 1;
      case FL_PUSH: {
        bool right = Fl::event_button() == FL_RIGHT_MOUSE;
        for (const auto& h : hits)
          if (Fl::event_inside(h.x, h.y, h.w, h.h) && on_act && (h.act == 6) == right) {
            on_act(h.act, h.idx);
            return 1;
          }
        if (right || tasks_mode || status_mode || !chat || !viewer.empty()) return 1;
        // Seleccionar texto: se empieza sobre una línea; doble clic, el mensaje entero.
        Fl::focus(this);
        Pos p;
        if (pos_at(Fl::event_x(), Fl::event_y(), true, p)) {
          if (Fl::event_clicks() > 0) {
            select_message(p.msg);
          } else {
            sel_a = sel_b = p;
            selecting = true;
          }
        } else {
          clear_selection();
        }
        redraw();
        return 1;
      }
      case FL_DRAG: {
        if (!selecting) return 1;
        Pos p;
        if (pos_at(Fl::event_x(), Fl::event_y(), false, p)) {
          sel_b = p;
          redraw();
        }
        return 1;
      }
      case FL_RELEASE:
        selecting = false;
        return 1;
      case FL_KEYBOARD:
      case FL_SHORTCUT:
        if (!viewer.empty() && Fl::event_key() == FL_Escape) {
          if (on_act) on_act(32, -1);
          return 1;
        }
        if ((Fl::event_state() & FL_COMMAND) && Fl::event_key() == 'c' && has_selection()) {
          std::string t = selected_text();
          Fl::copy(t.c_str(), (int)t.size(), 1);
          Fl::copy(t.c_str(), (int)t.size(), 0);
          if (on_act) on_act(26, -1);
          return 1;
        }
        return 0;
      case FL_MOUSEWHEEL:
        if (tasks_mode) {
          task_scroll = std::max(0, std::min(task_scroll + Fl::event_dy() * 30, std::max(0, task_content - (h() - 72))));
          redraw();
          return 1;
        }
        if (!chat) break;
        // La rueda hacia arriba sube a los mensajes antiguos; arriba del todo, se cargan más.
        msg_scroll = std::max(0, std::min(msg_scroll - Fl::event_dy() * 40, max_scroll));
        if (msg_scroll >= max_scroll && more && !asked_more && on_act) {
          asked_more = true;
          on_act(20, -1);
        }
        redraw();
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ------------------------------------------------------------ las pruebas
// Una imagen dibujada en código (las capturas no usan nada de verdad).
Fl_RGB_Image* demo_picture(int w, int h, unsigned top, unsigned bottom, int kind) {
  Fl_Image_Surface surf(w, h, 0);
  Fl_Surface_Device::push_current(&surf);
  for (int yy = 0; yy < h; yy++) {
    double t = yy / (double)h;
    auto mix = [&](int sh) { return (uchar)(((top >> sh) & 255) * (1 - t) + ((bottom >> sh) & 255) * t); };
    fl_color(fl_rgb_color(mix(16), mix(8), mix(0)));
    fl_xyline(0, yy, w);
  }
  if (kind == 0) {
    // Una silueta (retrato).
    fl_color(fl_rgb_color(255, 255, 255));
    fl_pie(w / 2 - w / 6, h / 4, w / 3, w / 3, 0, 360);
    fl_pie(w / 2 - w / 3, h * 2 / 3, w * 2 / 3, h * 2 / 3, 0, 180);
  } else {
    // Una mesa de roble.
    fl_color(fl_rgb_color(140, 90, 50));
    fl_rectf(w / 6, h / 2, w * 2 / 3, h / 12);
    fl_rectf(w / 6 + 10, h / 2, 12, h / 3);
    fl_rectf(w * 5 / 6 - 22, h / 2, 12, h / 3);
    fl_color(fl_rgb_color(100, 160, 90));
    fl_pie(w / 2 - 20, h / 2 - 34, 40, 34, 0, 360);
  }
  Fl_RGB_Image* img = surf.image();
  Fl_Surface_Device::pop_current();
  return img;
}

std::vector<Chat> demo_chats(long long now) {
  struct M {
    int who;   // 0: yo; 1..: el otro (o miembros del grupo)
    const char* text;
    int ago;   // minutos
  };
  struct D {
    const char* name;
    const char* jid;
    int unread;
    std::vector<const char*> members;
    std::vector<M> msgs;
  };
  std::vector<D> ds = {
      {tx::DEMO_LAURA, "34600111222@s.whatsapp.net", 2, {}, {
           {1, tx::DEMO_L1, 95}, {0, tx::DEMO_L2, 90}, {1, tx::DEMO_L3, 12}, {1, tx::DEMO_L4, 11}}},
      {tx::DEMO_GROUP, "120363000000000000@g.us", 5, {tx::DEMO_ANA, tx::DEMO_PEDRO}, {
           {1, tx::DEMO_G1, 300}, {2, tx::DEMO_G2, 280}, {0, tx::DEMO_G3, 250}, {1, tx::DEMO_G4, 40}}},
      {tx::DEMO_CLIENT, "34611222333@s.whatsapp.net", 1, {}, {
           {1, tx::DEMO_C1, 180}, {0, tx::DEMO_C2, 170}, {1, tx::DEMO_C3, 65}}},
      {tx::DEMO_MOM, "34622333444@s.whatsapp.net", 0, {}, {
           {1, tx::DEMO_M1, 1500}, {0, tx::DEMO_M2, 1490}}},
      {tx::DEMO_JAVI, "34633444555@s.whatsapp.net", 0, {}, {
           {0, tx::DEMO_J1, 3000}, {1, tx::DEMO_J2, 2980}}},
  };
  std::vector<Chat> out;
  long long id = 1;
  for (const auto& d : ds) {
    Chat c;
    c.id = id++;
    c.name = d.name;
    c.jid = d.jid;
    c.unread = d.unread;
    c.group = !d.members.empty();
    for (const auto& m : d.msgs) {
      Msg x;
      x.mine = m.who == 0;
      x.text = m.text;
      x.t = now - m.ago * 60LL;
      if (c.group && !x.mine) {
        x.who = d.members[(size_t)(m.who - 1)];
        x.phone = m.who == 1 ? "34611222000" : "5491155550000";   // Ana en España, Pedro en Argentina
      }
      c.msgs.push_back(x);
    }
    c.last = c.msgs.back().text;
    c.last_t = c.msgs.back().t;
    c.last_mine = c.msgs.back().mine;
    c.archived = std::string(d.name) == tx::DEMO_JAVI;   // uno archivado, para la demo
    out.push_back(c);
  }
  // Retratos dibujados para tres contactos, una foto en el chat de Laura y
  // un documento en el de Carlos.
  const unsigned tops[] = {0xf4a261, 0x2a9d8f, 0xe76f51};
  const unsigned bottoms[] = {0xe76f51, 0x264653, 0xf4a261};
  const int who[] = {0, 2, 3};
  for (int k = 0; k < 3; k++) {
    std::string key = "demo:avatar" + std::to_string(k);
    if (!images().count(key)) images()[key] = demo_picture(96, 96, tops[k], bottoms[k], 0);
    out[(size_t)who[k]].pic = key;
  }
  if (!images().count("demo:mesa")) images()["demo:mesa"] = demo_picture(520, 360, 0xe9e2d0, 0xc8b89a, 1);
  Msg photo;
  photo.kind = K_IMAGE;
  photo.media = "demo:mesa";
  photo.text = tx::DEMO_PHOTO_CAPTION;
  photo.t = out[0].msgs[0].t + 30;
  out[0].msgs.insert(out[0].msgs.begin() + 1, photo);
  Msg doc;
  doc.kind = K_DOC;
  doc.mine = true;
  doc.media = "demo:doc";
  doc.title = tx::DEMO_DOC;
  doc.size = 245000;
  doc.t = out[2].msgs[1].t + 60;
  out[2].msgs.insert(out[2].msgs.begin() + 2, doc);
  // Una clienta que escribe en italiano (para «🌐 Traducir»): sus mensajes no
  // se traducen con la interfaz; las traducciones las pone demo_state.
  Chat g;
  g.id = id++;
  g.name = "Giulia (Roma)";
  g.jid = "393401234567@s.whatsapp.net";
  const char* it[] = {"Ciao! Ho visto il vostro tavolo di rovere sul sito. È ancora disponibile?",
                      "Sì, è disponibile! Possiamo spedirlo a Roma in una settimana.",
                      "Perfetto. Quanto costa la spedizione? 🙂"};
  for (int k = 0; k < 3; k++) {
    Msg m;
    m.mine = k == 1;
    m.text = it[k];
    m.id = "DEMO-IT-" + std::to_string(k);
    m.t = now - (40 - k * 15) * 60LL;
    g.msgs.push_back(m);
  }
  g.last = g.msgs.back().text;
  g.last_t = g.msgs.back().t;
  g.unread = 1;
  out.push_back(g);
  return out;
}

int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  // JSON.
  bool ok = false;
  Json j = parse_json("{\"a\":[1,2,{\"b\":\"x\\\"y\\u00e9\\ud83d\\ude00\"}],\"c\":true,\"d\":null}", &ok);
  chk(ok && j["a"][2]["b"].str() == "x\"y\xC3\xA9\xF0\x9F\x98\x80" && j["c"].b, "leer JSON");
  chk(jstr("a\"b\n\x01") == "\"a\\\"b\\n\\u0001\"", "escribir JSON");
  parse_json("{\"a\":", &ok);
  chk(!ok, "JSON roto");
  // La petición a Claude.
  std::string body = claude_body("S", "U \"x\"");
  Json b = parse_json(body, &ok);
  chk(ok && b["model"].str() == "claude-opus-5-5" && b["output_config"]["effort"].str() == "low" &&
          b["fallbacks"].str() == "default" && b["messages"][0]["content"].str() == "U \"x\"",
      "cuerpo de Claude");
  chk(parse_json(openai_body("gpt-5", "S", "U"), &ok)["messages"][1]["role"].str() == "user" && ok, "cuerpo de OpenAI");
  // Las respuestas.
  AiReply r = parse_claude(200,
      "{\"content\":[{\"type\":\"fallback\"},{\"type\":\"text\",\"text\":\"1. Hola\\n---\\n\\\"Vale\\\"\\n---\\nPerfecto\"}],\"stop_reason\":\"end_turn\"}");
  chk(r.error.empty() && r.options.size() == 3 && r.options[0] == "Hola" && r.options[1] == "Vale", "respuesta de Claude");
  r = parse_claude(200, "{\"content\":[],\"stop_reason\":\"refusal\"}");
  chk(r.error == tx::ERR_AI_REFUSAL, "Claude declina");
  r = parse_claude(401, "{\"type\":\"error\",\"error\":{\"type\":\"authentication_error\",\"message\":\"invalid x-api-key\"}}");
  chk(r.error == tx::ERR_AI_KEY, "clave mala");
  r = parse_openai(200, "{\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"A\\n---\\nB\"}}]}");
  chk(r.options.size() == 2 && r.options[1] == "B", "respuesta de OpenAI");
  // Chats exportados (iPhone y Android).
  std::string ios =
      "[11/11/26, 17:02:15] Laura: Hola, ¿mañana a las 10?\n"
      "[11/11/26, 17:03:01] Marlon: Sí, perfecto\n"
      "seguimos\n"
      "[11/11/26, 17:05:00] Laura: Genial\n";
  Chat c = parse_export(ios, "Laura", "");
  chk(c.msgs.size() == 3 && !c.msgs[0].mine && c.msgs[1].mine && c.msgs[1].text == "Sí, perfecto\nseguimos", "chat del iPhone");
  std::string android = "11/11/2026, 17:02 - Pedro: Buenas\n11/11/2026, 17:03 - Los mensajes están cifrados\n11/11/2026, 17:04 - Yo: Hola\n";
  c = parse_export(android, "Pedro", "Yo");
  chk(c.msgs.size() == 2 && c.msgs[1].mine && c.last == "Hola", "chat de Android");
  chk(export_name("/x/Chat de WhatsApp con Laura.txt") == "Laura" && export_name("WhatsApp Chat with Bob.txt") == "Bob", "nombre del chat");
  // Enlaces.
  chk(phone_of("34600111222@s.whatsapp.net") == "34600111222" && phone_of("1203@g.us").empty(), "teléfono");
  chk(apple_time(0) == 0 && apple_time(800000000) == 1778307200LL, "fecha de Apple");
  // El texto que se manda a la IA: los últimos mensajes, con quién habla.
  auto demo = demo_chats(1794365000);
  std::string tr = transcript(demo[1], 40);
  chk(tr.find(std::string(tx::DEMO_ANA) + ": ") != std::string::npos && tr.find(std::string(tx::ME) + ": ") != std::string::npos, "conversación para la IA");
  chk(user_prompt(demo[0], "decir que sí").find("decir que sí") != std::string::npos, "lo que quiere decir");
#ifndef _WIN32
  // Una base de datos con la forma de la de WhatsApp Desktop (inventada).
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = dir + "/prueba-ChatStorage.sqlite";
  std::remove(path.c_str());
  Sqlite& q = sqlite();
  chk(q.load(), "SQLite del sistema");
  if (q.load()) {
    void* db = nullptr;
    q.open_v2(path.c_str(), &db, OPEN_READWRITE | OPEN_CREATE, nullptr);
    char* err = nullptr;
    q.exec(db,
           "CREATE TABLE ZWACHATSESSION (Z_PK INTEGER PRIMARY KEY, ZPARTNERNAME VARCHAR, ZCONTACTJID VARCHAR, "
           "ZLASTMESSAGEDATE TIMESTAMP, ZLASTMESSAGETEXT VARCHAR, ZUNREADCOUNT INTEGER, ZREMOVED INTEGER, ZHIDDEN INTEGER, ZARCHIVED INTEGER);"
           "CREATE TABLE ZWAMESSAGE (Z_PK INTEGER PRIMARY KEY, ZCHATSESSION INTEGER, ZISFROMME INTEGER, ZTEXT VARCHAR, "
           "ZMESSAGEDATE TIMESTAMP, ZPUSHNAME VARCHAR, ZMESSAGETYPE INTEGER, ZGROUPMEMBER INTEGER, ZSTANZAID VARCHAR);"
           "CREATE TABLE ZWAGROUPMEMBER (Z_PK INTEGER PRIMARY KEY, ZMEMBERJID VARCHAR, ZFIRSTNAME VARCHAR);"
           "CREATE TABLE ZWAPROFILEPUSHNAME (Z_PK INTEGER PRIMARY KEY, ZJID VARCHAR, ZPUSHNAME VARCHAR);"
           "INSERT INTO ZWAGROUPMEMBER VALUES (1,'34611@s.whatsapp.net',NULL),(2,'99887@lid',NULL),(3,'34622@s.whatsapp.net',NULL),(4,'34633@s.whatsapp.net','Pepe');"
           "INSERT INTO ZWAPROFILEPUSHNAME VALUES (1,'99887@lid','Lola');"
           "CREATE TABLE ZWAMEDIAITEM (Z_PK INTEGER PRIMARY KEY, ZMESSAGE INTEGER, ZMEDIALOCALPATH VARCHAR, ZTITLE VARCHAR, ZFILESIZE INTEGER);"
           "CREATE TABLE ZWAPROFILEPICTUREITEM (Z_PK INTEGER PRIMARY KEY, ZJID VARCHAR, ZPATH VARCHAR);"
           "INSERT INTO ZWAPROFILEPICTUREITEM VALUES (1,'34600111222@s.whatsapp.net','Media/Profile/laura');"
           "INSERT INTO ZWAMESSAGE VALUES (6,1,0,NULL,800000120,NULL,8,NULL,NULL);"
           "INSERT INTO ZWAMEDIAITEM VALUES (1,6,'Media/x/factura.pdf','factura.pdf',123456);"
           "INSERT INTO ZWAMESSAGE VALUES (7,1,0,NULL,800000130,NULL,1,NULL,NULL);"
           "INSERT INTO ZWACHATSESSION VALUES (1,'Laura','34600111222@s.whatsapp.net',800000100,'Genial',2,0,0,0);"
           "INSERT INTO ZWACHATSESSION VALUES (2,'Familia','1203@g.us',800000200,'Hola',0,0,0,1);"
           "INSERT INTO ZWACHATSESSION VALUES (3,'','status@broadcast',800000300,'x',0,0,0,0);"
           "INSERT INTO ZWAMESSAGE VALUES (1,1,0,'¿Mañana?',800000000,NULL,0,NULL,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (2,1,1,'Sí',800000050,NULL,0,NULL,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (3,1,0,'Genial',800000100,NULL,0,NULL,'S3');"
           "INSERT INTO ZWAMESSAGE VALUES (12,1,0,'Genial',800000100,NULL,0,NULL,'S3');"
           "INSERT INTO ZWAMESSAGE VALUES (4,1,0,NULL,800000110,NULL,0,NULL,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (5,2,0,'Hola',800000150,'COuXztcGIABIAJABAPABAtgC2tjzzav+lwM=',0,1,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (8,2,0,'Uno',800000160,'COuXztcGIABIAJABAPABAtgC2tjzzav+lwM=',0,2,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (9,2,0,'Dos',800000170,'CIqYztcGIABIAJABAPABAtgCidDa3Kv+lwM=',0,3,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (10,2,0,'Tres',800000180,NULL,0,4,NULL);"
           "INSERT INTO ZWAMESSAGE VALUES (11,2,0,'Cuatro',800000190,'Ana',0,NULL,NULL);",
           nullptr, nullptr, &err);
    q.close(db);
    // La foto de Laura (un .thumb) y un adjunto descargado.
    fl_make_path((dir + "/Media/Profile").c_str());
    fl_make_path((dir + "/Message/Media/x").c_str());
    {
      FILE* fp = fl_fopen((dir + "/Media/Profile/laura.thumb").c_str(), "wb");
      if (fp) std::fclose(fp);
      fp = fl_fopen((dir + "/Message/Media/x/factura.pdf").c_str(), "wb");
      if (fp) std::fclose(fp);
    }
    std::vector<Chat> chats;
    std::string error;
    chk(load_chats(path, chats, error) && chats.size() == 2 && chats[0].name == "Familia" && chats[0].group &&
            chats[1].unread == 2 && chats[1].last_t == 800000100 + 978307200LL && chats[0].archived && !chats[1].archived &&
            !chats[1].last_mine,
        "chats de la base de datos");
    Chat& l = chats[1];
    l.group = false;
    chk(chats[1].pic == dir + "/Media/Profile/laura.thumb" && chats[0].pic.empty(), "foto de perfil");
    chk(chats[1].last == std::string("📷 ") + tx::K_PHOTO && chats[0].last == "Cuatro", "resumen del último mensaje");
    chk(load_messages(path, l, 50, error) && l.msgs.size() == 5 && l.msgs[0].text == "¿Mañana?" && l.msgs[1].mine, "mensajes de la base de datos");
    chk(l.msgs[2].id == "S3" && l.msgs[0].id.empty(), "el id de cada mensaje (ZSTANZAID)");
    chk(l.msgs[3].kind == K_DOC && l.msgs[3].title == "factura.pdf" && l.msgs[3].size == 123456 &&
            l.msgs[3].media == dir + "/Message/Media/x/factura.pdf",
        "documento adjunto");
    chk(l.msgs[4].kind == K_IMAGE && l.msgs[4].media.empty(), "foto sin descargar");
    std::remove((dir + "/Media/Profile/laura.thumb").c_str());
    std::remove((dir + "/Message/Media/x/factura.pdf").c_str());
    // La agenda (ContactsV2.sqlite) al lado: el miembro 1 está en ella.
    {
      std::string cpath = dir + "/ContactsV2.sqlite";
      std::remove(cpath.c_str());
      void* cdb = nullptr;
      q.open_v2(cpath.c_str(), &cdb, OPEN_READWRITE | OPEN_CREATE, nullptr);
      q.exec(cdb,
             "CREATE TABLE ZWAADDRESSBOOKCONTACT (Z_PK INTEGER PRIMARY KEY, ZFULLNAME VARCHAR, ZWHATSAPPID VARCHAR, ZLID VARCHAR);"
             "INSERT INTO ZWAADDRESSBOOKCONTACT VALUES (1,'Ana García','34611@s.whatsapp.net','11111@lid');",
             nullptr, nullptr, &err);
      q.close(cdb);
      chk(load_messages(path, chats[0], 50, error) && chats[0].msgs.size() == 5, "mensajes del grupo");
      const auto& gm = chats[0].msgs;
      if (gm.size() == 5)
        chk(gm[0].who == "Ana García" && gm[1].who == "~ Lola" && gm[2].who == "+34622" && gm[3].who == "Pepe" && gm[4].who == "Ana",
            "quién escribe en el grupo (agenda, perfil, teléfono, nombre)");
      if (gm.size() == 5) chk(gm[0].phone == "34611" && gm[2].phone == "34622" && gm[1].phone.empty(), "el teléfono de quien escribe");
      std::remove(cpath.c_str());
      chk(load_messages(path, chats[0], 50, error) && chats[0].msgs[0].who == "+34611", "sin agenda: el teléfono");
      chk(looks_encoded("COuXztcGIABIAJABAPABAtgC2tjzzav+lwM=") && !looks_encoded("Ana María") && !looks_encoded("Ana"),
          "nombres codificados");
    }
    std::remove(path.c_str());
  }
#endif
  {
    // Fotos de verdad en disco (PNG, también con la extensión de otra cosa).
    std::string d = config_dir();
    fl_make_path(d.c_str());
    unsigned char px[16 * 16 * 3];
    for (int i = 0; i < 16 * 16 * 3; i++) px[i] = (unsigned char)(i * 7);
    Fl_RGB_Image src(px, 16, 16, 3);
    std::string a = d + "/prueba-foto.png", b = d + "/prueba-foto.jpg", c = d + "/prueba-foto.thumb";
    fl_write_png(a.c_str(), &src);
    fl_write_png(b.c_str(), &src);
    fl_write_png(c.c_str(), &src);
    bool ok_img = true;
    for (int round = 0; round < 3; round++)
      for (const auto& p : {a, b, c}) {
        Fl_RGB_Image* i1 = image_fit(p, 88 + round, 88);
        Fl_RGB_Image* i2 = image_fit(p, 260, 200);
        ok_img = ok_img && i1 && i2 && i1->w() > 0 && i2->w() > 0;
      }
    chk(ok_img, "fotos de disco (png, jpg y thumb)");
    chk(!image_fit(d + "/no-existe.jpg", 40, 40), "foto que no existe");
    std::remove(a.c_str());
    std::remove(b.c_str());
    std::remove(c.c_str());
  }
  // DMS_MYWA_PICS=carpeta: carga cada foto de esa carpeta (solo cuenta).
  if (const char* pics = fl_getenv("DMS_MYWA_PICS")) {
    dirent** names = nullptr;
    int n = fl_filename_list(pics, &names, fl_casenumericsort), ok_n = 0, tried = 0;
    for (int i = 0; i < n; i++) {
      std::string nm = names[i]->d_name;
      if (nm.empty() || nm[0] == '.' || nm.back() == '/') continue;
      tried++;
      if (image_fit(std::string(pics) + "/" + nm, 88, 88)) ok_n++;
    }
    fl_filename_free_list(&names, n);
    std::printf("fotos: %d de %d se cargan\n", ok_n, tried);
  }
  set_dark(true);
  chk(th().dark && th().chat == 0x0b141a, "tema oscuro");
  set_dark(false);
  chk(!th().dark && th().chat == 0xefeae2, "tema claro");
  // De verdad con un servidor de prueba: DMS_MYWA_ANTHROPIC_URL (o _OPENAI_URL).
  if (fl_getenv("DMS_MYWA_ANTHROPIC_URL") || fl_getenv("DMS_MYWA_OPENAI_URL")) {
    AiSettings s;
    s.claude_key = "sk-ant-prueba";
    s.openai_key = "sk-prueba";
    s.provider = fl_getenv("DMS_MYWA_OPENAI_URL") ? P_OPENAI : P_CLAUDE;
    AiReply live = suggest(s, demo[0], 0, "");
    std::printf("live: %d respuestas %s\n", (int)live.options.size(), live.error.c_str());
    chk(live.error.empty() && live.options.size() == 3, "petición de verdad (servidor de prueba)");
    // Y una traducción de verdad, con el mismo servidor.
    AiText tr = ai_ask(s, fmt(tx::PROMPT_TRANSLATE, {tx::MY_LANGUAGE}), translate_in_user({"Ciao", "Grazie mille"}));
    std::string lang;
    std::vector<std::string> items;
    bool ok_tr = tr.error.empty() && parse_translation(tr.text, 2, lang, items);
    std::printf("traducción: %s %s\n", ok_tr ? lang.c_str() : "", tr.error.c_str());
    chk(ok_tr && items.size() == 2, "traducción de verdad (servidor de prueba)");
    AiText auto_reply = ai_ask(s, fmt(tx::PROMPT_BUSY_AI, {"En una reunión"}), user_prompt(demo[0], ""));
    std::printf("respuesta automática: %d letras %s\n", (int)auto_reply.text.size(), auto_reply.error.c_str());
    chk(auto_reply.error.empty() && !auto_reply.text.empty(), "respuesta automática con IA (servidor de prueba)");
    AiText st = ai_ask(s, fmt(tx::PROMPT_STATUS, {tx::MY_LANGUAGE, tx::STATUS_TPL_LIST}), "rebajas en mesas");
    StatusDesign sd;
    bool ok_st = st.error.empty() && parse_status_ai(st.text, sd);
    std::printf("estado con IA: %s\n", ok_st ? sd.title.c_str() : st.error.c_str());
    chk(ok_st, "estado con IA (servidor de prueba)");
  }
  // Enviar con la API oficial: los cuerpos y las respuestas.
  b = parse_json(cloud_text_body("34600111222", "Hola \"tú\""), &ok);
  chk(ok && b["messaging_product"].str() == "whatsapp" && b["to"].str() == "34600111222" && b["type"].str() == "text" &&
          b["text"]["body"].str() == "Hola \"tú\"",
      "cuerpo de un texto (API oficial)");
  b = parse_json(cloud_media_body("346", K_DOC, "M1", "Aquí va", "factura.pdf"), &ok);
  chk(ok && b["type"].str() == "document" && b["document"]["id"].str() == "M1" && b["document"]["filename"].str() == "factura.pdf" &&
          b["document"]["caption"].str() == "Aquí va",
      "cuerpo de un documento (API oficial)");
  b = parse_json(cloud_media_body("346", K_AUDIO, "M2", "x", "a.ogg"), &ok);
  chk(ok && b["audio"]["id"].str() == "M2" && b["audio"]["caption"].str().empty(), "cuerpo de un audio (sin pie)");
  std::string sid;
  chk(parse_cloud(200, "{\"messaging_product\":\"whatsapp\",\"messages\":[{\"id\":\"wamid.X\"}]}", &sid).empty() && sid == "wamid.X",
      "API oficial: enviado");
  chk(parse_cloud(401, "{\"error\":{\"message\":\"bad\",\"code\":190}}") == tx::ERR_CLOUD_TOKEN, "API oficial: token malo");
  chk(parse_cloud(400, "{\"error\":{\"message\":\"Recipient not in allowed list\",\"code\":131030}}").find("allowed list") !=
          std::string::npos,
      "API oficial: el error de Meta");
  chk(cloud_send(CloudSettings{"1", "t"}, "1203@g.us", "x", "", nullptr) == tx::ERR_CLOUD_GROUP, "API oficial: grupos no");
  chk(cloud_send(CloudSettings{"", ""}, "346@s.whatsapp.net", "x", "", nullptr) == tx::ERR_CLOUD_SETUP, "API oficial: sin configurar");
  chk(file_kind("/a/Foto.JPG") == K_IMAGE && file_kind("v.mp4") == K_VIDEO && file_kind("n.opus") == K_AUDIO &&
          file_kind("x.pdf") == K_DOC && file_kind("sin-extension") == K_DOC && mime_of("x.pdf") == "application/pdf",
      "tipo de archivo");
  // Lo que llega por el puente: sin repetir, en orden, con el nombre del chat.
  {
    LiveStore st;
    chk(st.add_line("{\"ev\":\"msg\",\"id\":\"A2\",\"chat\":\"346@s.whatsapp.net\",\"name\":\"Laura\",\"text\":\"Dos\",\"t\":20}") ==
            "346@s.whatsapp.net",
        "puente: un mensaje");
    st.add_line("{\"ev\":\"msg\",\"id\":\"A1\",\"chat\":\"346@s.whatsapp.net\",\"mine\":true,\"text\":\"Uno\",\"t\":10}");
    chk(st.add_line("{\"ev\":\"msg\",\"id\":\"A1\",\"chat\":\"346@s.whatsapp.net\",\"text\":\"Uno\",\"t\":10}").empty(),
        "puente: sin repetir");
    st.add_line("{\"ev\":\"msg\",\"id\":\"G1\",\"chat\":\"1203@g.us\",\"who\":\"Ana\",\"kind\":8,\"title\":\"a.pdf\",\"t\":30}");
    st.add_line("{\"ev\":\"chat\",\"jid\":\"1203@g.us\",\"name\":\"Familia\"}");
    st.add_line("roto {");
    const LiveChat& l = st.chats["346@s.whatsapp.net"];
    chk(l.msgs.size() == 2 && l.msgs[0].text == "Uno" && l.msgs[0].mine && l.name == "Laura", "puente: en orden y con nombre");
    Chat g = live_chat("1203@g.us", st.chats["1203@g.us"]);
    chk(g.live && g.group && g.name == "Familia" && g.msgs[0].who == "Ana" && g.last == std::string("📄 a.pdf") && g.last_t == 30 &&
            g.id < -1000000 && g.id == live_id("1203@g.us"),
        "puente: un grupo");
    Chat n = live_chat("34999@s.whatsapp.net", LiveChat{});
    chk(n.name == "+34999", "puente: sin nombre, el teléfono");
    std::vector<Msg> base = {l.msgs[0]};
    base[0].t = 12;   // el mismo mensaje en WhatsApp Desktop, con otra hora
    merge_msgs(base, l.msgs);
    chk(base.size() == 2 && base[1].text == "Dos", "juntar con Desktop sin repetir");
    // El mismo documento: en Desktop con su pie y en el puente con su nombre; el mismo id.
    std::vector<Msg> d1(1), d2(1);
    d1[0].kind = d2[0].kind = K_DOC;
    d1[0].mine = d2[0].mine = true;
    d1[0].text = "manual-crm";
    d2[0].title = "manual-crm.pdf";
    d1[0].t = 100;
    d2[0].t = 101;
    d1[0].size = d2[0].size = 15100000;
    merge_msgs(d1, d2);
    chk(d1.size() == 1, "un adjunto de Desktop y del puente es uno solo");
    std::vector<Msg> e1(1), e2(1);
    e1[0].id = e2[0].id = "3EB0X";
    e1[0].text = "Hola";
    e2[0].text = "Hola (editado)";
    e2[0].t = 500;
    merge_msgs(e1, e2);
    chk(e1.size() == 1, "el mismo id es el mismo mensaje");
    std::string path = config_dir() + "/prueba-mensajes.jsonl";
    std::remove(path.c_str());
    Msg sent;
    sent.id = "S1";
    sent.mine = true;
    sent.text = "Línea \"1\"\nLínea 2";
    sent.t = 40;
    append_line(path, msg_line(sent, "346@s.whatsapp.net"));
    LiveStore again;
    again.load(path);
    chk(again.chats["346@s.whatsapp.net"].msgs.size() == 1 && again.chats["346@s.whatsapp.net"].msgs[0].text == sent.text,
        "guardar y leer mensajes.jsonl");
    std::remove(path.c_str());
  }
#ifndef _WIN32
  // DMS_MYWA_REALDB=1: en los grupos de WhatsApp Desktop, cuántos remitentes
  // tienen nombre (solo cuenta; no enseña nada de los mensajes).
  if (fl_getenv("DMS_MYWA_REALDB") && db_exists()) {
    std::vector<Chat> all;
    std::string e;
    int groups = 0, named = 0, empty = 0, coded = 0;
    if (load_chats(db_path(), all, e))
      for (auto& c : all) {
        if (!c.group || groups >= 60) continue;
        groups++;
        if (!load_messages(db_path(), c, 60, e)) continue;
        for (const auto& m : c.msgs) {
          if (m.mine) continue;
          if (m.who.empty()) empty++;
          else if (looks_encoded(m.who)) coded++;
          else named++;
        }
      }
    std::printf("grupos: %d · con nombre: %d · sin nombre: %d · codificados: %d\n", groups, named, empty, coded);
    {
      std::vector<Chat> fresh;
      load_chats(db_path(), fresh, e);
      ChatList l(0, 0, 10, 10);
      l.chats = &fresh;
      std::printf("por responder (icono): %d · filtro: %d · sin respuesta: %d · archivados: %d\n",
                  (int)to_answer(fresh, wall_s()).size(), l.count(ChatList::F_TODO), l.count(ChatList::F_WAITING),
                  l.count(ChatList::F_ARCHIVED));
    }
    // Y lo que trajo el puente (DMS_MYWA_REALSTORE=mensajes.jsonl): cuántos se juntan sin repetirse.
    if (const char* sp = fl_getenv("DMS_MYWA_REALSTORE")) {
      LiveStore st;
      st.load(sp);
      int chats_both = 0, from_db = 0, from_bridge = 0, merged = 0, by_id = 0, suspicious = 0;
      for (auto& c : all) {
        auto it = st.chats.find(c.jid);
        if (it == st.chats.end() || chats_both >= 80) continue;
        chats_both++;
        if (!load_messages(db_path(), c, 200, e)) continue;
        from_db += (int)c.msgs.size();
        from_bridge += (int)it->second.msgs.size();
        for (const auto& m : it->second.msgs)
          for (const auto& d : c.msgs)
            if (!m.id.empty() && m.id == d.id) { by_id++; break; }
        merge_msgs(c.msgs, it->second.msgs);
        merged += (int)c.msgs.size();
        // Parejas que aún parecen el mismo mensaje (mismo tipo y tamaño, o mismo texto, a menos de 5 s).
        for (size_t i = 1; i < c.msgs.size(); i++) {
          const Msg& a = c.msgs[i - 1];
          const Msg& b = c.msgs[i];
          if (a.mine == b.mine && a.kind == b.kind && std::llabs(a.t - b.t) <= 5 &&
              ((a.kind != K_TEXT && a.size > 0 && a.size == b.size) || (a.kind == K_TEXT && a.text == b.text)))
            suspicious++;
        }
      }
      std::printf("chats en los dos: %d · Desktop: %d · puente: %d · juntos: %d · iguales por id: %d · posibles repetidos: %d\n",
                  chats_both, from_db, from_bridge, merged, by_id, suspicious);
    }
  }
#endif
#ifdef __APPLE__
  // Un sticker WebP: se convierte a PNG con sips y luego se ve.
  {
    std::string d = config_dir();
    fl_make_path(d.c_str());
    std::string w = d + "/prueba-sticker.webp";
    const unsigned char webp[] = {0x52,0x49,0x46,0x46,0x1c,0x00,0x00,0x00,0x57,0x45,0x42,0x50,0x56,0x50,0x38,0x4c,0x0f,0x00,
                                  0x00,0x00,0x2f,0x07,0xc0,0x01,0x00,0x07,0x10,0xfd,0x8f,0xfe,0x07,0x22,0xa2,0xff,0x01,0x00};
    write_file(w, std::string((const char*)webp, sizeof webp));
    std::remove(webp_png(w).c_str());
    chk(!load_picture(w), "un WebP la primera vez: se convierte aparte");
    chk(webp_convert(w, webp_png(w)), "sips pasa el WebP a PNG");
    Fl_RGB_Image* img = load_picture(w);
    chk(img && img->w() == 8 && img->h() == 8, "el sticker, ya como imagen");
    delete img;
    std::remove(webp_png(w).c_str());
    std::remove(w.c_str());
  }
#endif
  // El país y la hora de un teléfono.
  {
    const Country* ar = country_of("5491125454205");
    const Country* dom = country_of("18095551234");
    const Country* us = country_of("12125551234");
    chk(ar && std::string(ar->iso) == "AR" && dom && std::string(dom->iso) == "DO" && us && std::string(us->iso) == "US" &&
            country_of("34600111222") && std::string(country_of("34600111222")->iso) == "ES" && !country_of("") &&
            !country_of("999"),
        "el país de un teléfono");
    chk(flag_of("AR") == "\xF0\x9F\x87\xA6\xF0\x9F\x87\xB7", "la bandera");
#ifndef _WIN32
    chk(time_in("Europe/Madrid", 1794365000) == "03:43" && time_in("America/Argentina/Buenos_Aires", 1794365000) == "23:43" &&
            time_in("America/Havana", 1794365000) == "22:43" && time_in("No/Existe", 1794365000).empty(),
        "la hora local de cada país");
#endif
    Chat g;
    g.group = true;
    for (const char* ph : {"5491100000000", "5491100000001", "34600000000", ""}) {
      Msg m;
      m.phone = ph;
      g.msgs.push_back(m);
    }
    auto ks = chat_countries(g);
    chk(ks.size() == 2 && std::string(ks[0]->iso) == "AR" && std::string(ks[1]->iso) == "ES", "los países de un grupo");
  }
  // La fecha de verdad (no la hora desde el arranque): lo que compara con los mensajes.
  chk(wall_s() > 1700000000LL, "la fecha de verdad");
  {
    std::vector<Chat> cs(2);
    cs[0].last_t = wall_s() - 10 * 86400;   // hace 10 días: no está por responder
    cs[1].last_t = wall_s() - 3600;         // hace una hora: sí
    auto ta = to_answer(cs, wall_s());
    chk(ta.size() == 1 && ta[0] == 1, "por responder: con la fecha de verdad");
    ChatList l(0, 0, 10, 10);
    l.chats = &cs;
    l.now = 0;   // como en la app: la hora de verdad
    chk(l.count(ChatList::F_TODO) == 1, "el filtro «por responder» con la hora de verdad");
    chk(time_in("Europe/Madrid", wall_s()).size() == 5, "la hora local, de ahora");
  }
  // Los estados: guardar y leer, lo que propone la IA y dibujarlo a 1080×1920.
  {
    StatusDesign d;
    d.id = 7;
    d.tpl = 2;
    d.title = "Hola \"mundo\"";
    d.body = "Línea\notra";
    d.footer = "#Prueba";
    d.emoji = "🎉";
    auto back = status_parse(status_line(d) + "\nroto\n");
    chk(back.size() == 1 && back[0].title == d.title && back[0].body == d.body && back[0].tpl == 2 && back[0].emoji == "🎉",
        "estados: guardar y leer");
    StatusDesign e;
    chk(parse_status_ai("```json\n{\"title\":\"Oferta\",\"body\":\"2x1\",\"footer\":\"#Ya\",\"emoji\":\"🔥\",\"template\":6}\n```", e) &&
            e.title == "Oferta" && e.tpl == 5 && e.emoji == "🔥",
        "estados: lo que propone la IA");
    chk(!parse_status_ai("nada", e) && !parse_status_ai("{\"body\":\"x\"}", e), "estados: una propuesta que no sirve");
    Fl_RGB_Image* img = status_image(d, 1080, 1920);
    chk(img && img->w() == 1080 && img->h() == 1920, "estados: la imagen de 1080×1920");
    delete img;
  }
  // La barra: los chats por responder, del más reciente al más antiguo.
  {
    std::vector<Chat> cs(4);
    cs[0].last_t = 900;                       // sí
    cs[1].last_t = 950;                       // sí, y antes en la lista
    cs[2].last_t = 950;
    cs[2].last_mine = true;                   // contesté: no
    cs[3].last_t = 990;
    cs[3].archived = true;                    // archivado: no
    auto ta = to_answer(cs, 1000);
    chk(ta.size() == 2 && ta[0] == 1 && ta[1] == 0, "la barra: los chats por responder");
    chk(to_answer(cs, 1000 + 4 * 86400).empty(), "la barra: solo los de los últimos 3 días");
  }
  // Los modos ocupado: guardar y leer, y a quién contestar.
  {
    std::vector<BusyMode> ms = {{"Reunión", "Estoy en una \"reunión\"", false}, {"Coche", "Conduciendo", true}};
    auto back = busy_parse(busy_text(ms) + "roto\n");
    chk(back.size() == 2 && back[0].text == ms[0].text && back[1].name == "Coche" && !back[0].ai && back[1].ai,
        "modos ocupado: guardar y leer (también si contesta la IA)");
    chk(fmt(tx::PROMPT_BUSY_AI, {"Hasta las 18:00"}).find("Hasta las 18:00") != std::string::npos, "la instrucción del modo, en el mensaje a la IA");
    std::vector<Chat> cs(5);
    cs[0].jid = "1@s.whatsapp.net";
    cs[0].last_t = 200;   // me escribió después: sí
    cs[1].jid = "2@s.whatsapp.net";
    cs[1].last_t = 50;    // antes de activarlo: no
    cs[2].jid = "3@g.us";
    cs[2].group = true;
    cs[2].last_t = 200;   // grupo: no
    cs[3].jid = "4@s.whatsapp.net";
    cs[3].last_t = 200;
    cs[3].last_mine = true;   // lo último es mío: no
    cs[4].jid = "5@s.whatsapp.net";
    cs[4].last_t = 200;
    std::map<std::string, bool> done = {{"5@s.whatsapp.net", true}};   // ya contestado: no
    auto t = busy_targets(cs, 100, done);
    chk(t.size() == 1 && t[0] == 0, "modo ocupado: a quién se contesta");
  }
  // Traducir: las claves y la respuesta de la IA.
  {
    chk(fnv("hola") == fnv("hola") && fnv("hola") != fnv("Hola") && fnv("").size() == 16, "clave de un texto");
    Msg a;
    a.text = "Ciao";
    a.id = "X1";
    Msg b = a;
    b.mine = true;
    chk(trans_key(a) == "i:X1" && trans_key(b) == "o:" + fnv("Ciao"), "claves de las traducciones");
    std::string lang;
    std::vector<std::string> items;
    chk(parse_translation("```json\n{\"language\": \"italiano\", \"items\": [\"Hola\", \"¿Qué tal?\"]}\n```", 2, lang, items) &&
            lang == "italiano" && items.size() == 2 && items[1] == "¿Qué tal?",
        "leer la traducción");
    chk(!parse_translation("{\"language\":\"x\",\"items\":[\"uno\"]}", 2, lang, items) && !parse_translation("nada", 1, lang, items),
        "una traducción que no cuadra");
    chk(translate_in_user({"a\"b", "c"}) == "[\"a\\\"b\",\"c\"]", "los mensajes para traducir");
    AiText t = claude_text(200, "{\"content\":[{\"type\":\"text\",\"text\":\"Ciao!\"}],\"stop_reason\":\"end_turn\"}");
    chk(t.error.empty() && t.text == "Ciao!", "texto de Claude");
    t = openai_text(401, "{\"error\":{\"message\":\"x\"}}");
    chk(t.error == tx::ERR_AI_KEY, "clave mala (texto)");
  }
  // Las tareas: guardar y leer, el orden y el texto de un mensaje.
  {
    std::vector<Task> ts(3);
    ts[0].id = 1;
    ts[0].title = "Llamar a \"Laura\"\tya";
    ts[0].jid = "346@s.whatsapp.net";
    ts[0].chat = "Laura";
    ts[0].created = 100;
    ts[1].id = 2;
    ts[1].title = "Hecha";
    ts[1].done = true;
    ts[2].id = 3;
    ts[2].title = "Otra";
    auto back = tasks_parse(tasks_text(ts) + "roto\n{\"title\":\"\"}\n");
    chk(back.size() == 3 && back[0].title == ts[0].title && back[0].jid == ts[0].jid && back[0].chat == "Laura" &&
            back[0].created == 100 && back[1].done && !back[0].done,
        "tareas: guardar y leer");
    chk(tasks_pending(back) == 2, "tareas pendientes");
    chk(task_age_color(0, 23 * 3600) == 0x25d366 && task_age_color(0, 24 * 3600) == 0xf59e0b &&
            task_age_color(0, 71 * 3600) == 0xf59e0b && task_age_color(0, 72 * 3600) == 0xe5484d,
        "la bolita de las tareas: verde, naranja y roja");
    chk(oldest_task(back, "346@s.whatsapp.net") == 100 && oldest_task(back, "otro") == 0 && oldest_task(back, "") == 0,
        "la tarea más antigua de un chat");
    auto o = tasks_order(back);
    chk(o.size() == 3 && o[0] == 2 && o[1] == 0 && o[2] == 1, "tareas: pendientes primero, la más nueva arriba");
    Msg m;
    m.text = "  Línea uno\nlínea dos ";
    chk(task_title_of(m) == "Línea uno línea dos", "tarea de un mensaje");
    m.kind = K_DOC;
    m.title = "factura.pdf";
    m.text = "";
    chk(task_title_of(m) == "📄 factura.pdf", "tarea de un documento");
    m.kind = K_TEXT;
    m.text = std::string(150, 'a') + std::string(100, 'b');
    chk(task_title_of(m).size() < 210, "tarea de un mensaje largo");
  }
  // DMS_MYWA_QR=archivo: el código QR que escribe el puente se puede leer.
  if (const char* q = fl_getenv("DMS_MYWA_QR")) {
    Fl_PNG_Image img(q);
    Fl_Image* big = img.w() > 0 ? img.copy(360, 360) : nullptr;
    chk(big && big->w() == 360 && big->d() > 0, "el código QR del puente");
    delete big;
  }
  // De verdad con un servidor de prueba: DMS_MYWA_GRAPH_URL.
  if (fl_getenv("DMS_MYWA_GRAPH_URL")) {
    std::string id, e = cloud_send(CloudSettings{"123", "tok"}, "34600111222@s.whatsapp.net", "Hola", "", &id);
    std::printf("graph texto: %s %s\n", id.c_str(), e.c_str());
    chk(e.empty() && !id.empty(), "API oficial de verdad: texto (servidor de prueba)");
    std::string file = config_dir() + "/prueba-adjunto.pdf";
    write_file(file, "%PDF-1.4 prueba");
    e = cloud_send(CloudSettings{"123", "tok"}, "34600111222@s.whatsapp.net", "La factura", file, &id);
    std::printf("graph archivo: %s %s\n", id.c_str(), e.c_str());
    chk(e.empty() && !id.empty(), "API oficial de verdad: adjunto (servidor de prueba)");
    std::remove(file.c_str());
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace wa

// ============================================================ la barra de menús
// En macOS, un NSStatusItem hecho desde C++ con el runtime de Objective-C
// (objc_msgSend): el icono de los mensajes, cuántos chats esperan respuesta
// y un menú con ellos. En Windows y Linux, la ventana se comporta como siempre.
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsMyWhatsappTarget", 0);
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
// El icono (un símbolo del sistema, del color de la barra) y el número.
void set(const char* symbol, const std::string& title) {
  if (!item()) return;
  Pool pool;
  id b = msg(item(), "button");
  if (!b) return;
  id img = nullptr;
  if (class_getClassMethod((Class)objc_getClass("NSImage"), sel_registerName("imageWithSystemSymbolName:accessibilityDescription:")))
    img = msg<id, id, id>(cls("NSImage"), "imageWithSystemSymbolName:accessibilityDescription:", str(symbol), str("MyWhatsapp"));
  if (img) {
    msg<void, BOOL>(img, "setTemplate:", YES);
    msg<void, id>(b, "setImage:", img);
    msg<void, long>(b, "setImagePosition:", 2);   // NSImageLeft
  }
  msg<void, id>(b, "setTitle:", str(title));
}
void menu(const std::vector<wa::BarEntry>& entries) {
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
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
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
void menu(const std::vector<wa::BarEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
struct AiDone {
  long long chat_id;
  wa::AiReply reply;
};

struct SendDone {
  std::string rid, error, id, jid, text, file;
};
struct TransDone {   // lo recibido, traducido
  std::string jid, language, error;
  std::vector<std::string> keys, items;
};
struct StatusAiDone {   // el estado que propone la IA
  long long id;
  std::string text, error;
};
struct DraftDone {   // lo que escribo, mejorado o corregido por la IA
  bool fix;
  std::string original, text, error;
};
struct BusyDone {   // la respuesta automática que escribió la IA
  std::string jid, text, fallback, error;
};
struct OutDone {   // lo que escribí, traducido para enviarlo
  std::string jid, original, translated, file, error;
};

class Form1 : public FormDesign {
public:
  std::vector<wa::Chat> chats;
  std::vector<std::string> options;
  wa::ChatList* list = nullptr;
  wa::ChatView* view = nullptr;
  wa::AiSettings ai;
  int current = -1;
  bool from_db = false, demo = false, warned = false, thinking = false;
  std::string theme = "system";   // claro, oscuro o como el sistema
  bool shown_dark = false;
  std::string message;
  double message_until = 0;
  // Enviar: el modo, la API oficial, el puente y lo que llega por él.
  int send_mode = wa::S_NONE;
  wa::CloudSettings cloud;
  wa::Bridge bridge;
  bool linked = false, store_dirty = false;
  wa::LiveStore store;
  std::map<std::string, std::string> pending;   // id del envío → texto (por si falla)
  int requests = 0;
  Fl_Double_Window* qr_win = nullptr;
  Fl_Box* qr_box = nullptr;
  Fl_RGB_Image* qr_img = nullptr;
  // Cuántos mensajes se cargan del chat abierto (crece al subir o al buscar).
  int msg_limit = 60;
  // Traducir: por chat, el modo ("" no, "auto" o un idioma) y el idioma detectado;
  // las traducciones hechas (clave → texto) y las ya pedidas (no se repiten).
  std::map<std::string, std::pair<std::string, std::string>> langs;
  std::map<std::string, std::string> translations;
  std::map<std::string, bool> trans_asked;
  bool translating = false;
  // Los modos ocupado: los que hay, el activo ("" si ninguno), desde cuándo y a quién se contestó ya.
  std::vector<wa::BusyMode> busy_modes;
  std::string busy;
  long long busy_since = 0;
  std::map<std::string, bool> busy_done;
  // Los estados: los diseños guardados y las publicaciones en curso (por su id de envío).
  std::vector<wa::StatusDesign> designs;
  std::map<std::string, bool> status_rids;
  // Preguntar antes de algo que se ve fuera (las pruebas lo cambian).
  std::function<bool(const std::string&)> confirm = [](const std::string& q) {
    return fl_choice("%s", tx::BTN_CANCEL, tx::BTN_OK, nullptr, q.c_str()) == 1;
  };
  // Elegir una foto (las pruebas lo cambian): "" si se cancela.
  std::function<std::string()> choose_photo = [] {
    Fl_Native_File_Chooser ch;
    ch.title(tx::STATUS_F_PHOTO);
    ch.filter("Fotos\t*.{jpg,jpeg,png}");
    if (ch.show() != 0 || !ch.filename()) return std::string();
    return std::string(ch.filename());
  };
  // La barra de menús: si la ventana está escondida en ella, y lo último que se puso.
  bool in_bar = false, quitting = false;
  std::string bar_sig;
  std::vector<std::string> bar_jids;   // los chats del menú (por su etiqueta)
  Fl_Input* find_input = nullptr;
  // El menú del clic derecho (las pruebas lo cambian): el índice elegido o -1.
  std::function<int(const std::vector<std::string>&)> choose = [](const std::vector<std::string>& items) {
    std::vector<Fl_Menu_Item> menu(items.size() + 1);
    for (auto& it : menu) std::memset((void*)&it, 0, sizeof it);
    for (size_t k = 0; k < items.size(); k++) menu[k].text = items[k].c_str();
    const Fl_Menu_Item* got = menu[0].popup(Fl::event_x(), Fl::event_y());
    return got ? (int)(got - &menu[0]) : -1;
  };
  // Las tareas, y cómo se pide un texto (las pruebas lo cambian).
  std::vector<wa::Task> tasks;
  std::function<bool(const char*, std::string&)> ask_text = [](const char* q, std::string& io) {
    const char* r = fl_input("%s", io.c_str(), q);
    if (!r) return false;
    io = r;
    return true;
  };

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_MYWA_SELFTEST")) std::exit(wa::selftest());
    if (fl_getenv("DMS_MYWA_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_MYWA_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    ListHint->hide();
    ChatHint->hide();
    Side->box(FL_FLAT_BOX);
    ChatArea->box(FL_FLAT_BOX);
    Side->resizable(nullptr);
    resizable(ChatArea);
    list = new wa::ChatList(Side->x(), Side->y() + 52, Side->w(), Side->h() - 52);
    Side->add(list);
    Side->resizable(list);
    list->chats = &chats;
    list->on_pick = [](int i) { if (self()) self()->pick(i); };
    view = new wa::ChatView(ChatArea->x(), ChatArea->y(), ChatArea->w(), ChatArea->h());
    ChatArea->add(view);
    ChatArea->resizable(view);
    view->options = &options;
    view->on_act = [](int act, int k) { if (self()) self()->option_act(act, k); };
    view->tasks = &tasks;
    list->tasks = &tasks;
    wa::on_picture_ready() = [] {
      if (self()) {
        self()->view->lay_dirty = true;   // el bocadillo del sticker cambia de tamaño
        self()->view->redraw();
      }
    };
    list->on_tasks = [] { if (self()) self()->open_tasks(); };
    list->on_mode = [] { if (self()) self()->refresh(); };
    list->on_busy = [] { if (self()) self()->busy_menu(); };
    list->on_status = [] { if (self()) self()->open_status(); };
    view->designs = &designs;
    // Buscar en el chat: el campo va en la cabecera (lo coloca la vista).
    find_input = new Fl_Input(ChatArea->x() + 300, ChatArea->y() + 16, 220, 28);
    find_input->textsize(13);
    find_input->when(FL_WHEN_CHANGED);
    find_input->callback([](Fl_Widget*, void*) { if (self()) self()->find_changed(); });
    find_input->hide();
    ChatArea->add(find_input);
    view->find_input = find_input;
    Provider->items({tx::P_CLAUDE, tx::P_OPENAI});
    Tone->items({tx::TONE_NATURAL, tx::TONE_FORMAL, tx::TONE_SHORT, tx::TONE_WARM, tx::TONE_BUSINESS});
    Tone->index(0);
    Search->callback([](Fl_Widget* w, void*) {
      if (self()) {
        self()->list->filter = static_cast<Fl_Input*>(w)->value();
        self()->list->redraw();
      }
    });
    Search->when(FL_WHEN_CHANGED);
    // El botón de cerrar esconde la ventana en la barra de menús (si la hay);
    // un cierre desde el código (el menú Idioma de las demos) cierra de verdad.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE) self()->close_clicked();
      else self()->close_for_good();
    });
    // Enter en el borrador envía; Mayúsculas+Enter, otra línea.
    Fl::event_dispatch(dispatch);
    bridge.on_line = [](const std::string& l) { if (self()) self()->on_bridge(l); };
  }
  static int dispatch(int e, Fl_Window* w) {
    Form1* f = self();
    if (f && e == FL_KEYBOARD && (Fl::event_state() & FL_COMMAND) && Fl::event_key() == 'f') {
      f->open_find();
      return 1;
    }
    // Cmd+Z justo después de «Corregir»: vuelve lo que había escrito.
    if (f && e == FL_KEYBOARD && (Fl::event_state() & FL_COMMAND) && Fl::event_key() == 'z' && Fl::focus() == f->Draft &&
        !f->undo_draft.empty() && f->fixed_draft == f->Draft->value()) {
      f->Draft->value(f->undo_draft.c_str());
      f->undo_draft.clear();
      f->fixed_draft.clear();
      return 1;
    }
    if (f && e == FL_KEYBOARD && Fl::event_key() == FL_Escape && !f->view->viewer.empty()) {
      f->viewer_act(32);
      return 1;
    }
    if (f && e == FL_KEYBOARD && Fl::focus() == f->find_input) {
      if (Fl::event_key() == FL_Enter || Fl::event_key() == FL_KP_Enter) {
        f->move_match(Fl::event_state() & FL_SHIFT ? 1 : -1);
        return 1;
      }
      if (Fl::event_key() == FL_Escape) {
        f->close_find();
        return 1;
      }
    }
    if (f && e == FL_KEYBOARD && Fl::focus() == f->Draft &&
        (Fl::event_key() == FL_Enter || Fl::event_key() == FL_KP_Enter) &&
        !(Fl::event_state() & (FL_SHIFT | FL_CTRL | FL_ALT | FL_META))) {
      f->send_draft("");
      return 1;
    }
    return Fl::handle_(e, w);
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // la IA contesta desde otro hilo
    setup();
    load_settings();
    apply_theme();
    store.load(store_file());
    load_tasks();
    load_translations();
    load_busy();
    load_designs();
    reload();
    // Vinculado antes: el puente vuelve a conectar con la sesión guardada.
    if (send_mode == wa::S_LINKED) start_bridge();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    refresh();
    update_bar();
  }

  // ---- el tema: los colores de los dibujos y de los controles del diseño
  void apply_theme() {
    bool dark = theme == "dark" || (theme == "system" && wa::system_dark());
    shown_dark = dark;
    wa::set_dark(dark);
    const wa::Theme& T = wa::th();
    Fl_Color panel = wa::rgb(T.panel), text = wa::rgb(T.text), muted = wa::rgb(T.muted), input = wa::rgb(T.input);
    Fl::background((uchar)(T.panel >> 16), (uchar)(T.panel >> 8), (uchar)T.panel);
    Fl::background2((uchar)(T.input >> 16), (uchar)(T.input >> 8), (uchar)T.input);
    Fl::foreground((uchar)(T.text >> 16), (uchar)(T.text >> 8), (uchar)T.text);
    color(panel);
    Side->color(wa::rgb(T.list));
    ChatArea->color(wa::rgb(T.chat));
    AiBar->color(panel);
    for (Fl_Widget* w : {(Fl_Widget*)LblProvider, (Fl_Widget*)LblTone, (Fl_Widget*)LblIntent}) {
      w->color(panel);
      w->labelcolor(muted);
    }
    for (Fl_Input_* in : {(Fl_Input_*)Search, (Fl_Input_*)Intent, (Fl_Input_*)Draft, (Fl_Input_*)find_input}) {
      in->color(input);
      in->textcolor(text);
      in->cursor_color(text);
      in->selection_color(wa::rgb(dark ? 0x005c4b : 0xb3d7ff));
    }
    for (Fl_Choice* c : {(Fl_Choice*)Provider, (Fl_Choice*)Tone}) {
      c->color(input);
      c->textcolor(text);
    }
    Menu1->color(panel);
    Menu1->textcolor(text);
    BtnSuggest->color(wa::rgb(dark ? 0x00a884 : 0x25d366));
    BtnSend->color(wa::rgb(dark ? 0x00a884 : 0x25d366));
    for (Fl_Widget* b : {(Fl_Widget*)BtnAttach, (Fl_Widget*)BtnImprove, (Fl_Widget*)BtnFix}) {
      b->color(input);
      b->labelcolor(text);
    }
    Status->color(panel);
    Status->labelcolor(muted);
    redraw();
  }
  void set_theme(const std::string& t) {
    theme = t;
    save_settings();
    apply_theme();
    refresh();
  }
  void form_close() override {
    save_settings();
    bridge.stop();
  }

  // ---- ajustes (las claves van en el Llavero)
  std::string settings_file() const { return wa::config_dir() + "/ajustes.txt"; }
  void load_settings() {
    std::string text;
    if (wa::read_file(settings_file(), text))
      for (const auto& l : wa::split(text, '\n')) {
        if (wa::starts(l, "provider=")) ai.provider = std::atoi(l.c_str() + 9) == 1 ? 1 : 0;
        else if (wa::starts(l, "model=")) ai.openai_model = l.substr(6);
        else if (wa::starts(l, "about=")) ai.about = l.substr(6);
        else if (l == "warned=1") warned = true;
        else if (wa::starts(l, "theme=")) theme = l.substr(6);
        else if (wa::starts(l, "busy=")) busy = l.substr(5);
        else if (wa::starts(l, "busy_since=")) busy_since = std::atoll(l.c_str() + 11);
        else if (wa::starts(l, "busy_done=")) {
          for (const auto& j : wa::split(l.substr(10), ','))
            if (!j.empty()) busy_done[j] = true;
        }
        else if (wa::starts(l, "send=")) send_mode = std::atoi(l.c_str() + 5);
        else if (wa::starts(l, "cloud_phone=")) cloud.phone_id = l.substr(12);
      }
    if (send_mode < wa::S_NONE || send_mode > wa::S_LINKED) send_mode = wa::S_NONE;
    cloud.token = wa::key_get("whatsapp-cloud");
    if (ai.openai_model.empty()) ai.openai_model = "gpt-5";
    ai.claude_key = wa::key_get("anthropic");
    ai.openai_key = wa::key_get("openai");
    if (ai.claude_key.empty() && fl_getenv("ANTHROPIC_API_KEY")) ai.claude_key = fl_getenv("ANTHROPIC_API_KEY");
    if (ai.openai_key.empty() && fl_getenv("OPENAI_API_KEY")) ai.openai_key = fl_getenv("OPENAI_API_KEY");
    Provider->index(ai.provider);
  }
  void save_settings() {
    if (demo) return;
    fl_make_path(wa::config_dir().c_str());
    std::string about = ai.about;
    for (auto& c : about)
      if (c == '\n') c = ' ';
    wa::write_file(settings_file(), "provider=" + std::to_string(ai.provider) + "\nmodel=" + ai.openai_model + "\nabout=" + about +
                                        "\ntheme=" + theme + "\nsend=" + std::to_string(send_mode) +
                                        "\ncloud_phone=" + cloud.phone_id + "\nbusy=" + busy +
                                        "\nbusy_since=" + std::to_string(busy_since) + "\nbusy_done=" + busy_done_text() +
                                        (warned ? "\nwarned=1" : "") + "\n");
  }

  // ---- los chats
  std::string store_file() const { return wa::config_dir() + "/mensajes.jsonl"; }
  void reload() {
    bool had = current >= 0 && current < (int)chats.size();
    long long keep = had ? chats[(size_t)current].id : 0;
    std::string keep_jid = had ? chats[(size_t)current].jid : "";
    std::string error;
    std::vector<wa::Chat> fresh;
    if (demo) {
      // Las capturas y las pruebas: los chats de ejemplo, nunca los de verdad.
      for (const auto& c : chats)
        if (!c.live) fresh.push_back(c);
    } else if (wa::db_exists() && wa::load_chats(wa::db_path(), fresh, error)) {
      from_db = true;
      view->notice.clear();
    } else {
      from_db = false;
      view->notice = wa::db_exists() ? std::string(error) + "\n\n" + tx::PERMISSION_HELP : tx::NO_DESKTOP_HELP;
    }
    // Los exportados que ya estaban siguen en la lista.
    if (!demo)
      for (const auto& c : chats)
        if (c.id < 0 && !c.live) fresh.push_back(c);
    // Los del puente: si el chat ya está, solo su último mensaje; si no, el chat entero.
    for (const auto& kv : store.chats) {
      if (kv.second.msgs.empty()) continue;
      const wa::Msg& last = kv.second.msgs.back();
      bool found = false;
      for (auto& c : fresh)
        if (c.jid == kv.first) {
          found = true;
          if (last.t > c.last_t) {
            c.last = wa::preview_of(last);
            c.last_t = last.t;
            c.last_mine = last.mine;
          }
        }
      if (!found) fresh.push_back(wa::live_chat(kv.first, kv.second));
    }
    std::stable_sort(fresh.begin(), fresh.end(), [](const wa::Chat& a, const wa::Chat& b) { return a.last_t > b.last_t; });
    chats = fresh;
    current = -1;
    view->chat = nullptr;
    for (int i = 0; i < (int)chats.size() && current < 0; i++)
      if (keep && chats[(size_t)i].id == keep) current = i;
    for (int i = 0; i < (int)chats.size() && current < 0; i++)
      if (!keep_jid.empty() && chats[(size_t)i].jid == keep_jid) current = i;
    if (current >= 0) open_messages(current);
    list->selected = current;
    list->redraw();
    view->redraw();
  }
  void open_messages(int i) {
    wa::Chat& c = chats[(size_t)i];
    // Las capturas y las pruebas nunca leen la base de datos de verdad.
    view->more = false;
    if (c.id > 0 && from_db && !demo) {
      std::string error;
      int rows = 0;
      if (!wa::load_messages(wa::db_path(), c, msg_limit, error, &rows)) say(error);
      view->more = rows >= msg_limit;
    }
    // Y lo que llegó (o se envió) por el puente.
    auto it = store.chats.find(c.jid);
    if (it != store.chats.end()) {
      if (c.live) c.msgs = it->second.msgs;
      else wa::merge_msgs(c.msgs, it->second.msgs);
    }
    view->chat = &c;
    apply_translations(c);
    request_translations();
  }
  void pick(int i) {
    if (i < 0 || i >= (int)chats.size()) return;
    current = i;
    list->selected = i;
    list->tasks_selected = false;
    list->status_selected = false;
    view->tasks_mode = false;
    view->status_mode = false;
    view->msg_scroll = 0;
    view->asked_more = false;
    view->clear_selection();
    view->viewer.clear();
    msg_limit = 60;
    close_find();
    options.clear();
    open_messages(i);
    Intent->value("");
    Draft->value("");
    refresh();
  }

  void say(const std::string& m) {
    message = m;
    message_until = wa::now_s() + 6;
    refresh();
  }
  void refresh() {
    list->tasks_pending = wa::tasks_pending(tasks);
    list->busy = busy;
    std::string where = from_db ? tx::SOURCE_DESKTOP : !store.empty() ? tx::SOURCE_LINKED : tx::SOURCE_EXPORT;
    std::string mode = send_mode == wa::S_CLOUD ? tx::MODE_CLOUD
                       : send_mode == wa::S_LINKED ? (linked ? tx::MODE_LINKED : tx::MODE_LINKING)
                                                   : tx::MODE_NONE;
    std::string busy_s = busy.empty() ? "" : "   ·   🔕 " + wa::fmt(tx::BUSY_ON, {busy});
    if (!message.empty() && wa::now_s() < message_until) Status->text(" " + message);
    else
      Status->text(" " + wa::fmt(tx::STATUS, {std::to_string(chats.size()), where,
                                               ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE, mode}) + busy_s);
    list->redraw();
    view->redraw();
  }

  // ---- la IA
  void ask_ai() {
    if (current < 0 || thinking) {
      if (current < 0) say(tx::PICK_CHAT);
      return;
    }
    ai.provider = Provider->index() == 1 ? 1 : 0;
    std::string& key = ai.provider == wa::P_OPENAI ? ai.openai_key : ai.claude_key;
    if (key.empty() && !demo) {
      settings_dialog();
      if (key.empty()) return;
    }
    // La primera vez: qué se manda y a quién.
    if (!warned && !demo) {
      std::string who = ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE;
      if (!fl_choice("%s", tx::BTN_CANCEL, tx::BTN_OK, nullptr, wa::fmt(tx::PRIVACY, {who}).c_str())) return;
      warned = true;
      save_settings();
    }
    thinking = true;
    options.clear();
    view->busy = wa::fmt(tx::THINKING, {ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE});
    refresh();
    if (demo) return;
    wa::AiSettings s = ai;
    wa::Chat c = chats[(size_t)current];
    int tone = Tone->index() < 0 ? 0 : Tone->index();
    std::string intent = Intent->value();
    std::thread([s, c, tone, intent] {
      auto* d = new AiDone{c.id, wa::suggest(s, c, tone, intent)};
      Fl::awake(answered, d);
    }).detach();
  }
  static void answered(void* p) {
    std::unique_ptr<AiDone> d(static_cast<AiDone*>(p));
    if (!self()) return;
    Form1* f = self();
    f->thinking = false;
    f->view->busy.clear();
    if (f->current < 0 || f->chats[(size_t)f->current].id != d->chat_id) { f->refresh(); return; }
    if (!d->reply.error.empty()) f->say(d->reply.error);
    else f->options = d->reply.options;
    f->refresh();
  }
  // Un adjunto descargado: se abre con su programa (Vista Previa, QuickTime…).
  // Dónde guardar una copia (las pruebas lo cambian): "" si se cancela.
  std::function<std::string(const std::string&)> save_as = [](const std::string& name) {
    Fl_Native_File_Chooser ch;
    ch.title(tx::DOWNLOAD_TITLE);
    ch.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    ch.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM);
    ch.preset_file(name.c_str());
    if (const char* h = fl_getenv("HOME")) ch.directory((std::string(h) + "/Downloads").c_str());
    if (ch.show() != 0 || !ch.filename()) return std::string();
    return std::string(ch.filename());
  };
  void open_attachment(int i) {
    if (current < 0 || i < 0 || i >= (int)chats[(size_t)current].msgs.size()) return;
    const wa::Msg& m = chats[(size_t)current].msgs[(size_t)i];
    const std::string& path = m.media;
    // Las fotos y los stickers: primero en grande, en el visor.
    if ((m.kind == wa::K_IMAGE || m.kind == wa::K_STICKER) && !path.empty()) {
      view->viewer = path;
      view->viewer_title = m.title.empty() ? (m.text.empty() ? wa::kind_name(m.kind) : m.text) : m.title;
      Fl::focus(view);
      refresh();
      return;
    }
    if (path.empty() || wa::starts(path, "demo:")) return;
    std::string url = "file://";
    for (char c : path) url += c == '/' ? std::string("/") : wa::url_encode(std::string(1, c));
    fl_open_uri(url.c_str());
  }
  // ---- las tareas
  std::string tasks_file() const { return wa::config_dir() + "/tareas.jsonl"; }
  void load_tasks() {
    std::string text;
    if (wa::read_file(tasks_file(), text)) tasks = wa::tasks_parse(text);
    // Las de la 1.0.102 a la 1.0.110 se guardaron con la hora desde el arranque del
    // equipo (no la fecha): se les pone la de ahora.
    bool fixed = false;
    for (auto& t : tasks)
      if (t.created > 0 && t.created < 1000000000LL) {
        t.created = wa::wall_s();
        fixed = true;
      }
    if (fixed) save_tasks();
  }
  void save_tasks() {
    list->tasks_pending = wa::tasks_pending(tasks);
    if (demo) return;
    fl_make_path(wa::config_dir().c_str());
    wa::write_file(tasks_file(), wa::tasks_text(tasks));
  }
  void open_tasks() {
    current = -1;
    list->selected = -1;
    list->tasks_selected = true;
    list->status_selected = false;
    view->status_mode = false;
    view->chat = nullptr;
    view->tasks_mode = true;
    view->task_scroll = 0;
    options.clear();
    refresh();
  }
  // Una tarea nueva; [from] es el chat de donde sale (o -1).
  bool add_task(std::string title, int from) {
    if (!ask_text(tx::ASK_TASK, title)) return false;
    title = wa::trim(title);
    if (title.empty()) return false;
    wa::Task t;
    long long top = 0;
    for (const auto& x : tasks) top = std::max(top, x.id);
    t.id = top + 1;
    t.title = title;
    t.created = wa::wall_s();
    if (from >= 0 && from < (int)chats.size()) {
      t.jid = chats[(size_t)from].jid;
      t.chat = chats[(size_t)from].name;
    }
    tasks.push_back(t);
    save_tasks();
    say(wa::fmt(tx::TASK_ADDED, {wa::fit(title, 400)}));
    return true;
  }
  // Desde el chat: el último mensaje que le escribieron, o el que eligió.
  void task_from_chat(int msg) {
    if (current < 0) return;
    const wa::Chat& c = chats[(size_t)current];
    std::string title;
    if (msg >= 0 && msg < (int)c.msgs.size()) title = wa::task_title_of(c.msgs[(size_t)msg]);
    else
      for (int i = (int)c.msgs.size() - 1; i >= 0 && title.empty(); i--)
        if (!c.msgs[(size_t)i].mine) title = wa::task_title_of(c.msgs[(size_t)i]);
    add_task(title, current);
  }
  // ---- la barra de menús: cuántos esperan respuesta y el menú con ellos
  // Etiquetas: 1 abrir la ventana, 2 salir, 100 + n: el chat n del menú.
  std::vector<wa::BarEntry> bar_entries(int& waiting) {
    long long t = view->now ? view->now : wa::wall_s();
    std::vector<int> ids = wa::to_answer(chats, t);
    waiting = (int)ids.size();
    std::vector<wa::BarEntry> out;
    out.push_back({tx::BAR_OPEN, 1, false});
    out.push_back({"", 0, true});
    out.push_back({waiting ? wa::fmt(tx::BAR_WAITING, {std::to_string(waiting)}) : std::string(tx::BAR_NONE), 0, false});
    bar_jids.clear();
    for (size_t k = 0; k < ids.size() && k < 15; k++) {
      const wa::Chat& c = chats[(size_t)ids[k]];
      std::string last = c.last;
      for (auto& ch : last)
        if (ch == '\n') ch = ' ';
      if (last.size() > 60) {
        size_t cut = 60;
        while (cut > 0 && ((unsigned char)last[cut] & 0xC0) == 0x80) cut--;
        last = last.substr(0, cut) + "…";
      }
      out.push_back({"   " + c.name + "  —  " + last + "  · " + wa::clock_time(c.last_t), 100 + (int)k, false});
      bar_jids.push_back(c.jid);
    }
    // El modo ocupado, a mano desde la barra.
    out.push_back({"", 0, true});
    out.push_back({busy.empty() ? std::string(tx::BAR_BUSY) : wa::fmt(tx::BUSY_ON, {busy}), 0, false});
    for (size_t k = 0; k < busy_modes.size(); k++)
      out.push_back({(busy_modes[k].name == busy ? "   ✓ " : "      ") + busy_modes[k].name + (busy_modes[k].ai ? "  ✨" : ""),
                     200 + (int)k, false});
    if (!busy.empty()) out.push_back({std::string("      ") + tx::BUSY_OFF, 3, false});
    out.push_back({"", 0, true});
    out.push_back({tx::BAR_QUIT, 2, false});
    return out;
  }
  void update_bar() {
    if (!bar::available()) return;
    int waiting = 0;
    auto entries = bar_entries(waiting);
    std::string sig = std::to_string(waiting) + "|" + busy;
    for (const auto& e : entries) sig += "|" + e.title;
    if (sig == bar_sig) return;   // nada nuevo: no se rehace el menú
    bar_sig = sig;
    const char* icon = !busy.empty() ? "moon.fill" : waiting ? "bubble.left.and.text.bubble.right.fill" : "bubble.left.and.bubble.right";
    bar::set(icon, waiting ? " " + std::to_string(waiting) : "");
    bar::menu(entries);
  }
  void bar_act(int t) {
    if (t == 2) {
      quit();
      return;
    }
    // El modo ocupado desde la barra: sin abrir la ventana.
    if (t == 3 || (t >= 200 && t - 200 < (int)busy_modes.size())) {
      std::string name = t == 3 ? "" : busy_modes[(size_t)(t - 200)].name;
      set_busy(name == busy ? "" : name);
      refresh();
      update_bar();
      return;
    }
    if (in_bar) from_bar();
    else bar::dock(true);
    if (t >= 100 && t - 100 < (int)bar_jids.size()) {
      std::string jid = bar_jids[(size_t)(t - 100)];
      list->mode = wa::ChatList::F_ALL;
      for (int i = 0; i < (int)chats.size(); i++)
        if (chats[(size_t)i].jid == jid) {
          pick(i);
          break;
        }
    }
  }
  void to_bar() {
    if (!bar::available()) {
      iconize();
      return;
    }
    if (in_bar) return;
    save_settings();
    in_bar = true;
    hide();
    bar::dock(false);
    // Sin ventanas, Fl::run terminaría: aquí sigue la app (y el puente, y el modo ocupado).
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
    save_settings();
    bridge.stop();
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
    bridge.stop();
    bar::remove();
    hide();
    std::exit(0);
  }

  // ---- los modos ocupado
  std::string busy_file() const { return wa::config_dir() + "/modos.jsonl"; }
  void load_busy() {
    std::string text;
    busy_modes.clear();
    if (!demo && wa::read_file(busy_file(), text)) busy_modes = wa::busy_parse(text);
    if (busy_modes.empty())
      busy_modes = {{tx::BUSY_MEETING, tx::BUSY_MEETING_TEXT}, {tx::BUSY_DRIVING, tx::BUSY_DRIVING_TEXT},
                    {tx::BUSY_HOLIDAY, tx::BUSY_HOLIDAY_TEXT}};
    bool found = false;
    for (const auto& m : busy_modes) found = found || m.name == busy;
    if (!found) busy.clear();
    if (busy_since > 0 && busy_since < 1000000000LL) busy_since = wa::wall_s();   // la misma hora mal guardada
  }
  void save_busy() {
    if (demo) return;
    fl_make_path(wa::config_dir().c_str());
    wa::write_file(busy_file(), wa::busy_text(busy_modes));
    save_settings();
  }
  std::string busy_done_text() const {
    std::string out;
    for (const auto& kv : busy_done) out += (out.empty() ? "" : ",") + kv.first;
    return out;
  }
  const wa::BusyMode* busy_mode() const {
    for (const auto& m : busy_modes)
      if (m.name == busy) return &m;
    return nullptr;
  }
  void set_busy(const std::string& name) {
    busy = name;
    busy_since = name.empty() ? 0 : wa::wall_s();
    busy_done.clear();
    save_busy();
    if (!name.empty() && send_mode == wa::S_NONE && !demo) say(tx::BUSY_NEEDS_SEND);
    else say(name.empty() ? std::string(tx::BUSY_OFF_DONE) : wa::fmt(tx::BUSY_ON, {name}));
  }
  // El menú: activar un modo, crear, editar o borrar uno, o desactivarlo.
  void busy_menu() {
    std::vector<std::string> items;
    for (const auto& m : busy_modes) items.push_back((m.name == busy ? "✓ " : "    ") + m.name + (m.ai ? "  ✨" : ""));
    size_t n = busy_modes.size();
    items.push_back(tx::BUSY_NEW);
    items.push_back(tx::BUSY_EDIT);
    items.push_back(tx::BUSY_DELETE);
    items.push_back(tx::BUSY_OFF);
    int r = choose(items);
    if (r < 0) return;
    if (r < (int)n) {
      set_busy(busy_modes[(size_t)r].name);
    } else if (r == (int)n) {   // nuevo
      std::string name, text;
      if (!ask_text(tx::BUSY_ASK_NAME, name) || wa::trim(name).empty()) return;
      if (!ask_text(tx::BUSY_ASK_TEXT, text) || wa::trim(text).empty()) return;
      int kind = choose({tx::BUSY_KIND_FIXED, tx::BUSY_KIND_AI});
      if (kind < 0) return;
      if (kind == 1 && !ai_allowed()) return;
      busy_modes.push_back({wa::trim(name), wa::trim(text), kind == 1});
      set_busy(wa::trim(name));
    } else if (r == (int)n + 1 || r == (int)n + 2) {   // editar o borrar: cuál
      std::vector<std::string> names;
      for (const auto& m : busy_modes) names.push_back(m.name);
      int k = choose(names);
      if (k < 0 || k >= (int)busy_modes.size()) return;
      if (r == (int)n + 1) {
        std::string text = busy_modes[(size_t)k].text;
        if (!ask_text(tx::BUSY_ASK_TEXT, text) || wa::trim(text).empty()) return;
        int kind = choose({tx::BUSY_KIND_FIXED, tx::BUSY_KIND_AI});
        if (kind < 0) return;
        if (kind == 1 && !busy_modes[(size_t)k].ai && !ai_allowed()) return;
        busy_modes[(size_t)k].text = wa::trim(text);
        busy_modes[(size_t)k].ai = kind == 1;
        save_busy();
      } else {
        if (busy_modes[(size_t)k].name == busy) busy.clear();
        busy_modes.erase(busy_modes.begin() + k);
        save_busy();
      }
    } else {
      set_busy("");
    }
    refresh();
  }
  // Con un modo activo: a quien escribió (en privado) desde entonces, su mensaje, una vez.
  void busy_reply() {
    const wa::BusyMode* m = busy_mode();
    if (!m || send_mode == wa::S_NONE) return;
    if (send_mode == wa::S_LINKED && !linked) return;
    bool any = false;
    for (int i : wa::busy_targets(chats, busy_since, busy_done)) {
      wa::Chat c = chats[(size_t)i];
      busy_done[c.jid] = true;   // y se guarda: al volver a abrir la app no se repite
      any = true;
      std::string& key = ai.provider == wa::P_OPENAI ? ai.openai_key : ai.claude_key;
      if (!m->ai || key.empty()) {
        deliver(c.jid, m->text, "", "");
        continue;
      }
      // Con IA: lee los últimos mensajes de ese chat y escribe la respuesta en otro hilo.
      if (c.id > 0 && from_db && !demo) {
        std::string error;
        wa::load_messages(wa::db_path(), c, 30, error);
      }
      auto it = store.chats.find(c.jid);
      if (it != store.chats.end()) wa::merge_msgs(c.msgs, it->second.msgs);
      wa::AiSettings s = ai;
      std::string sys = busy_ai_system(m->text), usr = wa::user_prompt(c, ""), fallback = m->text, jid = c.jid;
      std::thread([s, sys, usr, fallback, jid] {
        wa::AiText r = wa::ai_ask(s, sys, usr);
        Fl::awake(busy_ai_done, new BusyDone{jid, wa::trim(r.text), fallback, r.error});
      }).detach();
    }
    if (any) save_settings();
  }
  std::string busy_ai_system(const std::string& instruction) const {
    std::string sys = wa::fmt(tx::PROMPT_BUSY_AI, {instruction});
    if (!wa::trim(ai.about).empty()) sys += "\n\n" + wa::fmt(tx::PROMPT_ABOUT, {wa::trim(ai.about)});
    return sys;
  }
  // Si la IA falla, se envía el texto del modo tal cual (que nadie se quede sin respuesta).
  static void busy_ai_done(void* p) {
    std::unique_ptr<BusyDone> d(static_cast<BusyDone*>(p));
    Form1* f = self();
    if (!f) return;
    std::string text = d->error.empty() && !d->text.empty() ? d->text : d->fallback;
    if (text.size() >= 2 && text.front() == '"' && text.back() == '"') text = text.substr(1, text.size() - 2);
    f->deliver(d->jid, text, "", "");
  }
  // La primera vez que se manda algo a la IA: la clave y el aviso.
  bool ai_allowed() {
    if (demo) return true;
    std::string& key = ai.provider == wa::P_OPENAI ? ai.openai_key : ai.claude_key;
    if (key.empty()) {
      settings_dialog();
      if (key.empty()) return false;
    }
    std::string who = ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE;
    return fl_choice("%s", tx::BTN_CANCEL, tx::BTN_OK, nullptr, wa::fmt(tx::PRIVACY_BUSY_AI, {who}).c_str()) == 1;
  }

  // ---- traducir
  std::string langs_file() const { return wa::config_dir() + "/idiomas.txt"; }
  std::string trans_file() const { return wa::config_dir() + "/traducciones.jsonl"; }
  void load_translations() {
    std::string text;
    if (wa::read_file(langs_file(), text))
      for (const auto& l : wa::split(text, '\n')) {
        auto f = wa::split(l, '\t');
        if (f.size() >= 2 && !f[0].empty()) langs[f[0]] = {f[1], f.size() > 2 ? f[2] : ""};
      }
    if (wa::read_file(trans_file(), text))
      for (const auto& l : wa::split(text, '\n')) {
        bool ok = false;
        wa::Json j = wa::parse_json(l, &ok);
        if (ok && !j["k"].str().empty()) translations[j["k"].str()] = j["v"].str();
      }
  }
  void save_langs() {
    if (demo) return;
    std::string out;
    for (const auto& kv : langs)
      if (!kv.second.first.empty() || !kv.second.second.empty())
        out += kv.first + "\t" + kv.second.first + "\t" + kv.second.second + "\n";
    fl_make_path(wa::config_dir().c_str());
    wa::write_file(langs_file(), out);
  }
  void remember_translation(const std::string& key, const std::string& text) {
    translations[key] = text;
    if (!demo) wa::append_line(trans_file(), "{\"k\":" + wa::jstr(key) + ",\"v\":" + wa::jstr(text) + "}");
  }
  std::string lang_mode(const std::string& jid) const {
    auto it = langs.find(jid);
    return it == langs.end() ? "" : it->second.first;
  }
  // El idioma al que se traduce lo que escribo: el elegido o el detectado.
  std::string target_lang(const std::string& jid) const {
    auto it = langs.find(jid);
    if (it == langs.end() || it->second.first.empty()) return "";
    return it->second.first == "auto" ? it->second.second : it->second.first;
  }
  void apply_translations(wa::Chat& c) {
    std::string mode = lang_mode(c.jid);
    for (auto& m : c.msgs) {
      m.trans.clear();
      if (mode.empty() || m.text.empty()) continue;
      auto it = translations.find(wa::trans_key(m));
      if (it != translations.end() && it->second != m.text) m.trans = it->second;
    }
    std::string label;
    if (mode == "auto") {
      std::string det = langs[c.jid].second;
      label = det.empty() ? std::string(tx::LANG_DETECTING) : wa::fmt(tx::LANG_DETECTED, {det});
    } else {
      label = mode;
    }
    view->translate_label = label;
    view->lay_dirty = true;
  }
  // Pide a la IA lo recibido que falta por traducir (de los últimos 40).
  void request_translations() {
    if (current < 0 || demo || translating) return;
    const wa::Chat& c = chats[(size_t)current];
    if (lang_mode(c.jid).empty()) return;
    std::vector<std::string> keys, texts;
    int from = std::max(0, (int)c.msgs.size() - 40);
    for (int i = from; i < (int)c.msgs.size(); i++) {
      const wa::Msg& m = c.msgs[(size_t)i];
      if (m.mine || m.text.empty() || !m.trans.empty()) continue;
      std::string k = wa::trans_key(m);
      if (translations.count(k) || trans_asked.count(k)) continue;
      keys.push_back(k);
      texts.push_back(m.text);
    }
    if (keys.empty()) return;
    for (const auto& k : keys) trans_asked[k] = true;
    translating = true;
    wa::AiSettings s = ai;
    std::string jid = c.jid, sys = wa::fmt(tx::PROMPT_TRANSLATE, {tx::MY_LANGUAGE}), usr = wa::translate_in_user(texts);
    size_t n = texts.size();
    std::thread([s, jid, sys, usr, keys, n] {
      wa::AiText r = wa::ai_ask(s, sys, usr);
      auto* d = new TransDone{jid, "", r.error, keys, {}};
      if (d->error.empty() && !wa::parse_translation(r.text, n, d->language, d->items)) d->error = tx::ERR_AI_ANSWER;
      Fl::awake(trans_done, d);
    }).detach();
    say(tx::TRANSLATING);
  }
  static void trans_done(void* p) {
    std::unique_ptr<TransDone> d(static_cast<TransDone*>(p));
    Form1* f = self();
    if (!f) return;
    f->translating = false;
    if (!d->error.empty()) {
      f->say(d->error);
      return;
    }
    for (size_t k = 0; k < d->keys.size(); k++) f->remember_translation(d->keys[k], d->items[k]);
    auto& lang = f->langs[d->jid];
    if (lang.first == "auto" && !d->language.empty() && lang.second != d->language) {
      lang.second = d->language;
      f->save_langs();
    }
    f->message.clear();
    if (f->current >= 0) f->open_messages(f->current);
    f->refresh();
  }
  // El menú de «🌐 Traducir»: no traducir, detectar o un idioma.
  void translate_menu() {
    if (current < 0) return;
    std::string jid = chats[(size_t)current].jid, mode = lang_mode(jid);
    std::vector<std::string> names = {tx::TRANS_OFF, tx::TRANS_AUTO, tx::LANG_EN, tx::LANG_ES, tx::LANG_PT, tx::LANG_FR,
                                      tx::LANG_IT, tx::LANG_DE, tx::LANG_ZH, tx::LANG_AR, tx::LANG_RU};
    std::vector<std::string> items;
    for (size_t k = 0; k < names.size(); k++) {
      bool on = (k == 0 && mode.empty()) || (k == 1 && mode == "auto") || (k > 1 && mode == names[k]);
      items.push_back((on ? "✓ " : "    ") + names[k]);
    }
    int r = choose(items);
    if (r < 0) return;
    std::string now = r == 0 ? "" : r == 1 ? "auto" : names[(size_t)r];
    if (!now.empty() && !demo) {
      std::string& key = ai.provider == wa::P_OPENAI ? ai.openai_key : ai.claude_key;
      if (key.empty()) {
        settings_dialog();
        if (key.empty()) return;
      }
      if (mode.empty()) {
        std::string who = ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE;
        if (!fl_choice("%s", tx::BTN_CANCEL, tx::BTN_OK, nullptr, wa::fmt(tx::PRIVACY_TRANSLATE, {who}).c_str())) return;
      }
    }
    langs[jid].first = now;
    save_langs();
    open_messages(current);
    refresh();
  }

  // ---- los estados: diseñarlos, guardarlos y publicarlos
  std::string designs_file() const { return wa::config_dir() + "/estados.jsonl"; }
  void load_designs() {
    std::string text;
    designs.clear();
    if (!demo && wa::read_file(designs_file(), text)) designs = wa::status_parse(text);
    view->design = designs.empty() ? -1 : (int)designs.size() - 1;
  }
  void save_designs() {
    if (demo) return;
    fl_make_path(wa::config_dir().c_str());
    std::string out;
    for (const auto& d : designs) out += wa::status_line(d) + "\n";
    wa::write_file(designs_file(), out);
  }
  void open_status() {
    current = -1;
    list->selected = -1;
    list->tasks_selected = false;
    list->status_selected = true;
    view->chat = nullptr;
    view->tasks_mode = false;
    view->status_mode = true;
    options.clear();
    refresh();
  }
  wa::StatusDesign* design() {
    int i = view->design;
    return i >= 0 && i < (int)designs.size() ? &designs[(size_t)i] : nullptr;
  }
  void new_design() {
    wa::StatusDesign d;
    long long top = 0;
    for (const auto& x : designs) top = std::max(top, x.id);
    d.id = top + 1;
    d.title = tx::STATUS_NEW_TITLE;
    d.body = tx::STATUS_NEW_BODY;
    d.emoji = "✨";
    designs.push_back(d);
    view->design = (int)designs.size() - 1;
  }
  // El PNG de 1080×1920 del diseño abierto en [path].
  bool render_design(const std::string& path) {
    wa::StatusDesign* d = design();
    if (!d) return false;
    Fl_RGB_Image* img = wa::status_image(*d, 1080, 1920);
    bool ok = img && fl_write_png(path.c_str(), img) == 0;
    delete img;
    return ok;
  }
  void status_act(int act, int k) {
    wa::StatusDesign* d = design();
    if (act == 47) {
      new_design();
    } else if (act == 48) {
      status_ai();
      return;
    } else if (act == 51) {
      if (k >= 0 && k < (int)designs.size()) view->design = k;
    } else if (act == 52) {
      if (k >= 0 && k < (int)designs.size()) {
        designs.erase(designs.begin() + k);
        if (view->design >= (int)designs.size()) view->design = (int)designs.size() - 1;
      }
    } else if (!d) {
      return;
    } else if (act == 40) {
      d->tpl = k;
    } else if (act >= 41 && act <= 44) {
      std::string* f = act == 41 ? &d->title : act == 42 ? &d->body : act == 43 ? &d->footer : &d->emoji;
      const char* q = act == 41 ? tx::STATUS_ASK_TITLE : act == 42 ? tx::STATUS_ASK_BODY : act == 43 ? tx::STATUS_ASK_FOOTER : tx::STATUS_ASK_EMOJI;
      std::string v = *f;
      if (!ask_text(q, v)) return;
      *f = wa::trim(v);
    } else if (act == 45) {
      std::string p = choose_photo();
      if (p.empty()) return;
      d->photo = p;
    } else if (act == 46) {
      d->photo.clear();
    } else if (act == 49) {
      std::string dest = save_as(tx::STATUS_FILE);
      if (dest.empty()) return;
      say(render_design(dest) ? wa::fmt(tx::DOWNLOADED, {wa::file_base(dest)}) : std::string(tx::DOWNLOAD_FAILED));
      return;
    } else if (act == 50) {
      publish_status();
      return;
    }
    save_designs();
    refresh();
  }
  // Con IA: de qué va el estado → título, texto, pie, emoji y plantilla.
  void status_ai() {
    std::string idea;
    if (!ask_text(tx::STATUS_ASK_IDEA, idea) || wa::trim(idea).empty()) return;
    if (!demo && !ai_ready()) return;
    if (!design()) new_design();
    wa::AiSettings s = ai;
    long long id = design()->id;
    std::string sys = wa::fmt(tx::PROMPT_STATUS, {tx::MY_LANGUAGE, tx::STATUS_TPL_LIST});
    if (!wa::trim(ai.about).empty()) sys += "\n\n" + wa::fmt(tx::PROMPT_ABOUT, {wa::trim(ai.about)});
    say(tx::STATUS_AI_WORKING);
    if (demo) return;
    std::thread([s, sys, idea, id] {
      wa::AiText r = wa::ai_ask(s, sys, idea);
      Fl::awake(status_ai_done, new StatusAiDone{id, r.text, r.error});
    }).detach();
  }
  static void status_ai_done(void* p) {
    std::unique_ptr<StatusAiDone> d(static_cast<StatusAiDone*>(p));
    Form1* f = self();
    if (!f) return;
    for (auto& x : f->designs)
      if (x.id == d->id) {
        if (!d->error.empty() || !wa::parse_status_ai(d->text, x)) {
          f->say(d->error.empty() ? std::string(tx::ERR_AI_ANSWER) : d->error);
          return;
        }
        f->save_designs();
        f->say(tx::STATUS_AI_DONE);
        f->refresh();
        return;
      }
  }
  // Publicar: solo con WhatsApp vinculado por QR (la API oficial no publica estados).
  void publish_status() {
    if (!design()) return;
    if (send_mode != wa::S_LINKED || !linked) {
      say(tx::STATUS_NEEDS_QR);
      return;
    }
    if (!confirm(tx::STATUS_CONFIRM)) return;
    std::string dir = wa::config_dir() + "/estados";
    fl_make_path(dir.c_str());
    std::string png = dir + "/estado-" + std::to_string(design()->id) + "-" + std::to_string(wa::wall_s()) + ".png";
    if (!render_design(png)) {
      say(tx::DOWNLOAD_FAILED);
      return;
    }
    std::string rid = "r" + std::to_string(++requests);
    if (!bridge.send("{\"cmd\":\"status\",\"id\":" + wa::jstr(rid) + ",\"path\":" + wa::jstr(png) + "}")) {
      say(tx::ERR_SEND);
      return;
    }
    status_rids[rid] = true;
    say(tx::STATUS_PUBLISHING);
  }

  // ---- la conversación: subir, volver abajo, buscar, copiar
  void chat_act(int act) {
    if (act == 20) load_more();
    else if (act == 21) view->msg_scroll = 0;
    else if (act == 22) open_find();
    else if (act == 23) move_match(-1);
    else if (act == 24) move_match(1);
    else if (act == 25) close_find();
    else if (act == 26) say(tx::COPIED);
    refresh();
  }
  // Más mensajes antiguos: se mantiene lo que se estaba viendo (se cuenta desde abajo).
  void load_more() {
    if (current < 0 || !view->more) return;
    msg_limit += 200;
    open_messages(current);
    view->asked_more = false;
  }
  void open_find() {
    if (current < 0 || view->tasks_mode) return;
    view->find_open = true;
    find_input->show();
    // Sin ventana (las pruebas), dar el foco de verdad falla en macOS.
    if (shown()) {
      find_input->take_focus();
      find_input->insert_position(0, find_input->size());
    } else {
      Fl::focus(find_input);
    }
    refresh();
  }
  void close_find() {
    view->find_open = false;
    view->find.clear();
    view->matches.clear();
    view->match = -1;
    if (find_input) {
      find_input->value("");
      find_input->hide();
    }
  }
  // Busca en todo el chat (de WhatsApp Desktop se cargan hasta 5000 mensajes).
  void find_changed() {
    if (current < 0) return;
    std::string q = find_input->value();
    view->find = q;
    view->matches.clear();
    view->match = -1;
    if (!q.empty()) {
      if (view->more && msg_limit < 5000) {
        msg_limit = 5000;
        open_messages(current);
      }
      const wa::Chat& c = chats[(size_t)current];
      for (int i = 0; i < (int)c.msgs.size(); i++)
        if (!wa::find_all(c.msgs[(size_t)i].text, q).empty() || !wa::find_all(c.msgs[(size_t)i].title, q).empty())
          view->matches.push_back(i);
      if (!view->matches.empty()) {
        view->match = (int)view->matches.size() - 1;   // el más reciente
        view->scroll_to = view->matches.back();
      }
    }
    refresh();
  }
  // -1: el anterior (más antiguo); 1: el siguiente.
  void move_match(int d) {
    if (view->matches.empty()) return;
    int n = (int)view->matches.size();
    view->match = ((view->match + d) % n + n) % n;
    view->scroll_to = view->matches[(size_t)view->match];
    refresh();
  }
  // El clic derecho sobre un mensaje.
  void bubble_menu(int i) {
    if (current < 0 || i < 0 || i >= (int)chats[(size_t)current].msgs.size()) return;
    const wa::Msg& m = chats[(size_t)current].msgs[(size_t)i];
    std::vector<std::string> items;
    bool sel = view->has_selection();
    if (sel) items.push_back(tx::COPY_SELECTION);
    items.push_back(tx::COPY_MESSAGE);
    items.push_back(tx::MAKE_TASK);
    int r = choose(items);
    if (r < 0) return;
    if (!sel) r++;
    if (r == 0 || r == 1) {
      std::string t = r == 0 ? view->selected_text() : (m.text.empty() ? m.title : m.text);
      Fl::copy(t.c_str(), (int)t.size(), 1);
      Fl::copy(t.c_str(), (int)t.size(), 0);
      say(tx::COPIED);
    } else {
      task_from_chat(i);
    }
  }
  void task_act(int act, int k) {
    if (act == 13) {
      add_task("", -1);
      return;
    }
    if (k < 0 || k >= (int)tasks.size()) return;
    if (act == 10) {
      tasks[(size_t)k].done = !tasks[(size_t)k].done;
      save_tasks();
    } else if (act == 11) {
      std::string jid = tasks[(size_t)k].jid;
      for (int i = 0; i < (int)chats.size(); i++)
        if (chats[(size_t)i].jid == jid) {
          pick(i);
          return;
        }
      say(tx::TASK_NO_CHAT);
    } else if (act == 12) {
      tasks.erase(tasks.begin() + k);
      save_tasks();
    }
    refresh();
  }
  // El visor: descargar una copia, abrirla con su programa o cerrarlo.
  void viewer_act(int act) {
    std::string path = view->viewer;
    if (act == 32) {
      view->viewer.clear();
    } else if (act == 31 && !wa::starts(path, "demo:")) {
      std::string url = "file://";
      for (char c : path) url += c == '/' ? std::string("/") : wa::url_encode(std::string(1, c));
      fl_open_uri(url.c_str());
    } else if (act == 30) {
      std::string base = wa::file_base(path);
      if (wa::starts(path, "demo:")) base = path.substr(5) + ".png";
      // Los stickers se guardan como PNG (el WebP casi nada lo abre).
      if (wa::lower(base).size() > 5 && wa::lower(base).compare(base.size() - 5, 5, ".webp") == 0)
        base = base.substr(0, base.size() - 5) + ".png";
      if (base.find('.') == std::string::npos) base += ".jpg";
      std::string dest = save_as(base);
      if (dest.empty()) return;
      bool ok = false;
      if (wa::starts(path, "demo:")) {
        auto it = wa::images().find(path);
        ok = it != wa::images().end() && it->second && fl_write_png(dest.c_str(), it->second) == 0;
      } else {
        std::string src = path, data;
        if (wa::file_exists(wa::webp_png(path)) && wa::lower(dest).find(".png") != std::string::npos) src = wa::webp_png(path);
        if (wa::read_file(src, data)) {
          FILE* f = fl_fopen(dest.c_str(), "wb");
          if (f) {
            ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
            ok = std::fclose(f) == 0 && ok;
          }
        }
      }
      say(ok ? wa::fmt(tx::DOWNLOADED, {wa::file_base(dest)}) : std::string(tx::DOWNLOAD_FAILED));
    }
    refresh();
  }
  void option_act(int act, int k) {
    if (act == 4) {
      open_attachment(k);
      return;
    }
    if (act >= 30 && act <= 32) {
      viewer_act(act);
      return;
    }
    if (act == 33 && current >= 0 && !chats[(size_t)current].pic.empty()) {
      view->viewer = chats[(size_t)current].pic;
      view->viewer_title = chats[(size_t)current].name;
      Fl::focus(view);
      refresh();
      return;
    }
    if (act == 5) {
      task_from_chat(-1);
      return;
    }
    if (act == 6) {
      bubble_menu(k);
      return;
    }
    if (act >= 20 && act <= 26) {
      chat_act(act);
      return;
    }
    if (act == 27) {
      translate_menu();
      return;
    }
    if (act >= 40 && act <= 52) {
      status_act(act, k);
      return;
    }
    if (act >= 10 && act <= 13) {
      task_act(act, k);
      return;
    }
    if (k < 0 || k >= (int)options.size()) return;
    const std::string o = options[(size_t)k];
    if (act == 3) {
      Draft->value(o.c_str());
      send_draft("");
    } else if (act == 1) Draft->value(o.c_str());
    else if (act == 2) {
      Fl::copy(o.c_str(), (int)o.size(), 1);
      say(tx::COPIED);
    }
  }
  void settings_dialog() {
    const char* k = fl_password("%s", "", tx::ASK_CLAUDE_KEY);
    if (k && *k) {
      ai.claude_key = wa::trim(k);
      wa::key_set("anthropic", ai.claude_key);
    }
    const char* o = fl_password("%s", "", tx::ASK_OPENAI_KEY);
    if (o && *o) {
      ai.openai_key = wa::trim(o);
      wa::key_set("openai", ai.openai_key);
    }
    const char* m = fl_input("%s", ai.openai_model.c_str(), tx::ASK_OPENAI_MODEL);
    if (m && *m) ai.openai_model = wa::trim(m);
    const char* a = fl_input("%s", ai.about.c_str(), tx::ASK_ABOUT);
    if (a) ai.about = a;
    save_settings();
    refresh();
  }
  void import_export() {
    Fl_Native_File_Chooser ch;
    ch.title(tx::IMPORT_TITLE);
    ch.filter("WhatsApp\t*.txt");
    if (ch.show() != 0) return;
    std::string path = ch.filename(), data;
    if (!wa::read_file(path, data)) return;
    std::string name = wa::export_name(path);
    wa::Chat c = wa::parse_export(data, name, "");
    if (c.msgs.empty()) { say(tx::IMPORT_EMPTY); return; }
    c.id = -(long long)(chats.size() + 1);
    chats.insert(chats.begin(), c);
    pick(0);
    say(wa::fmt(tx::IMPORTED, {name, std::to_string(c.msgs.size())}));
  }

  // ---- enviar
  void send_draft(const std::string& file) {
    if (current < 0) {
      say(tx::PICK_CHAT);
      return;
    }
    std::string text = wa::trim(Draft->value());
    if (text.empty() && file.empty()) {
      say(tx::EMPTY_DRAFT);
      Draft->take_focus();
      return;
    }
    wa::Chat& c = chats[(size_t)current];
    if (c.jid.empty()) {
      say(tx::ERR_NO_JID);
      return;
    }
    if (demo && send_mode == wa::S_NONE) {
      // Las capturas: se ve enviado, sin red.
      wa::Msg m;
      m.mine = true;
      m.text = text;
      m.t = c.msgs.empty() ? 0 : c.msgs.back().t + 60;
      c.msgs.push_back(m);
      c.last = text;
      Draft->value("");
      options.clear();
      say(tx::SENT);
      return;
    }
    if (send_mode == wa::S_NONE) {
      connect_dialog();
      if (send_mode == wa::S_NONE) return;
    }
    // Con «🌐 Traducir»: primero se traduce y se envía lo traducido.
    if (!lang_mode(c.jid).empty() && !text.empty()) {
      std::string target = target_lang(c.jid);
      if (target.empty()) {
        say(tx::ERR_NO_LANG);
        return;
      }
      wa::AiSettings s = ai;
      std::string jid = c.jid;
      std::string sys = wa::fmt(tx::PROMPT_TRANSLATE_OUT, {target});
      std::thread([s, jid, sys, text, file] {
        wa::AiText r = wa::ai_ask(s, sys, text);
        Fl::awake(out_done, new OutDone{jid, text, wa::trim(r.text), file, r.error});
      }).detach();
      Draft->value("");
      options.clear();
      say(tx::TRANSLATING);
      return;
    }
    deliver(c.jid, text, file, text);
  }
  static void out_done(void* p) {
    std::unique_ptr<OutDone> d(static_cast<OutDone*>(p));
    Form1* f = self();
    if (!f) return;
    if (!d->error.empty() || d->translated.empty()) {
      if (!*f->Draft->value()) f->Draft->value(d->original.c_str());
      f->say(d->error.empty() ? std::string(tx::ERR_AI_ANSWER) : d->error);
      return;
    }
    // Lo que escribí queda guardado junto a lo enviado.
    wa::Msg sent;
    sent.mine = true;
    sent.text = d->translated;
    f->remember_translation(wa::trans_key(sent), d->original);
    f->deliver(d->jid, d->translated, d->file, d->original);
  }
  // Envía de verdad por el puente o la API oficial; [restore] vuelve al borrador si falla.
  void deliver(const std::string& jid, const std::string& text, const std::string& file, const std::string& restore) {
    std::string rid = "r" + std::to_string(++requests);
    if (send_mode == wa::S_LINKED) {
      if (!bridge.running()) start_bridge();
      if (!linked) {
        say(tx::NOT_LINKED);
        return;
      }
      std::string cmd = file.empty()
                            ? "{\"cmd\":\"send\",\"id\":" + wa::jstr(rid) + ",\"to\":" + wa::jstr(jid) + ",\"text\":" + wa::jstr(text) + "}"
                            : "{\"cmd\":\"send_file\",\"id\":" + wa::jstr(rid) + ",\"to\":" + wa::jstr(jid) + ",\"path\":" +
                                  wa::jstr(file) + ",\"caption\":" + wa::jstr(text) + "}";
      if (!bridge.send(cmd)) {
        say(tx::ERR_SEND);
        return;
      }
    } else {
      wa::CloudSettings s = cloud;
      std::thread([s, jid, text, file, rid] {
        std::string id, err = wa::cloud_send(s, jid, text, file, &id);
        Fl::awake(cloud_done, new SendDone{rid, err, id, jid, text, file});
      }).detach();
    }
    pending[rid] = restore;
    if (restore.empty()) return;   // las respuestas automáticas no tocan el borrador
    Draft->value("");
    options.clear();
    say(tx::SENDING);
  }
  // Si no se pudo enviar, el texto vuelve al borrador.
  void send_result(const std::string& rid, const std::string& error) {
    std::string text = pending.count(rid) ? pending[rid] : "";
    pending.erase(rid);
    if (error.empty()) {
      say(tx::SENT);
      return;
    }
    if (!text.empty() && !*Draft->value()) Draft->value(text.c_str());
    say(error);
  }
  static void cloud_done(void* p) {
    std::unique_ptr<SendDone> d(static_cast<SendDone*>(p));
    Form1* f = self();
    if (!f) return;
    if (d->error.empty()) {
      wa::Msg m;
      m.id = d->id;
      m.mine = true;
      m.text = d->text;
      m.t = wa::wall_s();
      if (!d->file.empty()) {
        m.kind = wa::file_kind(d->file);
        m.media = d->file;
        m.title = wa::file_base(d->file);
      }
      std::string line = wa::msg_line(m, d->jid);
      f->store.add_line(line);
      if (!f->demo) wa::append_line(f->store_file(), line);
      f->reload();
    }
    f->send_result(d->rid, d->error);
  }
  void attach_file() {
    if (current < 0) {
      say(tx::PICK_CHAT);
      return;
    }
    Fl_Native_File_Chooser ch;
    ch.title(tx::ATTACH_TITLE);
    if (ch.show() != 0 || !ch.filename()) return;
    send_draft(ch.filename());
  }
  void connect_dialog() {
    int r = fl_choice("%s", tx::BTN_CANCEL, tx::CONNECT_CLOUD, tx::CONNECT_QR, tx::CONNECT_ASK);
    if (r == 1) {
      const char* id = fl_input("%s", cloud.phone_id.c_str(), tx::ASK_CLOUD_PHONE);
      if (!id) return;
      cloud.phone_id = wa::trim(id);
      const char* tk = fl_password("%s", "", tx::ASK_CLOUD_TOKEN);
      if (tk && *tk) {
        cloud.token = wa::trim(tk);
        wa::key_set("whatsapp-cloud", cloud.token);
      }
      if (cloud.phone_id.empty() || cloud.token.empty()) {
        say(tx::ERR_CLOUD_SETUP);
        return;
      }
      bridge.stop();
      linked = false;
      send_mode = wa::S_CLOUD;
      save_settings();
      say(tx::CLOUD_READY);
    } else if (r == 2) {
      if (!fl_choice("%s", tx::BTN_CANCEL, tx::QR_ACCEPT, nullptr, tx::QR_RISK)) return;
      send_mode = wa::S_LINKED;
      save_settings();
      start_bridge();
    }
  }
  void disconnect() {
    if (send_mode == wa::S_NONE) return;
    if (!fl_choice("%s", tx::BTN_CANCEL, tx::BTN_DISCONNECT, nullptr, tx::DISCONNECT_ASK)) return;
    if (send_mode == wa::S_LINKED && bridge.running()) bridge.send("{\"cmd\":\"logout\"}");
    if (send_mode == wa::S_CLOUD) {
      cloud.token.clear();
      wa::key_set("whatsapp-cloud", "");
    }
    send_mode = wa::S_NONE;
    linked = false;
    save_settings();
    say(tx::LOGGED_OUT);
  }
  void start_bridge() {
    if (bridge.running()) return;
    std::string exe = wa::bridge_path();
    if (!wa::file_exists(exe)) {
      say(tx::ERR_NO_BRIDGE);
      return;
    }
    fl_make_path(wa::config_dir().c_str());
    if (!bridge.start(exe, wa::config_dir())) {
      say(tx::ERR_NO_BRIDGE);
      return;
    }
    say(tx::CONNECTING);
  }
  // El código QR para vincular, en una ventanita aparte.
  void show_qr(const std::string& png) {
    if (!qr_win) {
      Fl_Group::current(nullptr);
      qr_win = new Fl_Double_Window(400, 500, tx::QR_TITLE);
      qr_box = new Fl_Box(20, 20, 360, 360);
      Fl_Box* help = new Fl_Box(20, 390, 360, 96, tx::QR_HELP);
      help->align(FL_ALIGN_INSIDE | FL_ALIGN_WRAP | FL_ALIGN_TOP);
      help->labelsize(14);
      qr_win->end();
    }
    Fl_PNG_Image img(png.c_str());
    if (img.w() <= 0) return;
    Fl_RGB_Image* fit = static_cast<Fl_RGB_Image*>(img.copy(360, 360));
    qr_box->image(fit);
    delete qr_img;
    qr_img = fit;
    qr_win->show();
    qr_box->redraw();
  }
  // Una línea del puente.
  void on_bridge(const std::string& line) {
    bool ok = false;
    wa::Json j = wa::parse_json(line, &ok);
    if (!ok) return;
    std::string ev = j["ev"].str();
    if (ev == "msg" || ev == "chat") {
      if (!store.add_line(line).empty() || ev == "chat") store_dirty = true;
    } else if (ev == "qr") {
      show_qr(j["png"].str());
    } else if (ev == "ready") {
      linked = true;
      if (qr_win) qr_win->hide();
      say(tx::LINKED);
    } else if (ev == "sent" && status_rids.count(j["id"].str())) {
      status_rids.erase(j["id"].str());
      std::string why = j["error"].str();
      say(j["ok"].b ? std::string(tx::STATUS_PUBLISHED) : wa::fmt(tx::ERR_SEND_WHY, {why.empty() ? std::string(tx::ERR_SEND) : why}));
    } else if (ev == "sent") {
      std::string why = j["error"].str();
      send_result(j["id"].str(), j["ok"].b ? "" : why.empty() ? std::string(tx::ERR_SEND) : wa::fmt(tx::ERR_SEND_WHY, {why}));
    } else if (ev == "logged_out") {
      linked = false;
      say(tx::LOGGED_OUT);
    } else if (ev == "error") {
      say(wa::fmt(tx::ERR_SEND_WHY, {j["text"].str()}));
    } else if (ev == "exit") {
      linked = false;
      if (send_mode == wa::S_LINKED) say(tx::BRIDGE_STOPPED);
    }
    refresh();
  }

  // ---- la IA con lo que escribo: mejorarlo (una propuesta) o corregirlo (en el borrador)
  std::string undo_draft, fixed_draft;   // para Cmd+Z tras corregir
  void draft_ai(bool fix) {
    std::string text = wa::trim(Draft->value());
    if (text.empty()) {
      say(tx::EMPTY_DRAFT);
      return;
    }
    if (thinking) return;
    if (!demo && !ai_ready()) return;
    std::string sys = fix ? tx::PROMPT_FIX : tx::PROMPT_IMPROVE;
    std::string usr = wa::fmt(tx::PROMPT_MY_DRAFT, {text});
    if (!fix && current >= 0) usr = wa::user_prompt(chats[(size_t)current], "") + "\n\n" + usr;
    if (!fix && !wa::trim(ai.about).empty()) sys += "\n\n" + wa::fmt(tx::PROMPT_ABOUT, {wa::trim(ai.about)});
    thinking = true;
    options.clear();
    view->busy = fix ? std::string(tx::FIXING)
                     : wa::fmt(tx::IMPROVING, {ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE});
    refresh();
    if (demo) return;
    wa::AiSettings s = ai;
    std::thread([s, sys, usr, text, fix] {
      wa::AiText r = wa::ai_ask(s, sys, usr);
      Fl::awake(draft_done, new DraftDone{fix, text, wa::trim(r.text), r.error});
    }).detach();
  }
  static void draft_done(void* p) {
    std::unique_ptr<DraftDone> d(static_cast<DraftDone*>(p));
    Form1* f = self();
    if (!f) return;
    f->thinking = false;
    f->view->busy.clear();
    std::string t = d->text;
    if (t.size() >= 2 && t.front() == '"' && t.back() == '"') t = t.substr(1, t.size() - 2);
    if (!d->error.empty() || t.empty()) {
      f->say(d->error.empty() ? std::string(tx::ERR_AI_ANSWER) : d->error);
    } else if (d->fix) {
      if (t == d->original) f->say(tx::FIX_SAME);
      else {
        f->undo_draft = d->original;
        f->fixed_draft = t;
        f->Draft->value(t.c_str());
        f->say(tx::FIXED);
      }
    } else {
      f->options = {t};   // como una respuesta propuesta: «Enviar», «Usar» o «Copiar»
      f->say(tx::IMPROVED);
    }
    f->refresh();
  }
  // La clave y, la primera vez, el aviso de qué se manda a la IA.
  bool ai_ready() {
    std::string& key = ai.provider == wa::P_OPENAI ? ai.openai_key : ai.claude_key;
    if (key.empty()) {
      settings_dialog();
      if (key.empty()) return false;
    }
    if (!warned) {
      std::string who = ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE;
      if (!fl_choice("%s", tx::BTN_CANCEL, tx::BTN_OK, nullptr, wa::fmt(tx::PRIVACY, {who}).c_str())) return false;
      warned = true;
      save_settings();
    }
    return true;
  }

  // ---- eventos del diseño
  void BtnImprove_click() override { draft_ai(false); }
  void BtnFix_click() override { draft_ai(true); }
  void BtnSend_click() override { send_draft(""); }
  void BtnAttach_click() override { attach_file(); }
  void BtnSuggest_click() override { ask_ai(); }
  void Intent_enter() override { ask_ai(); }
  void Provider_select() override {
    ai.provider = Provider->index() == 1 ? 1 : 0;
    save_settings();
    refresh();
  }
  void Tick_timer() override {
    // «Como el sistema»: si macOS cambia de claro a oscuro, la app también.
    static double last_theme = 0;
    if (theme == "system" && !demo && wa::now_s() - last_theme > 5) {
      last_theme = wa::now_s();
      if (wa::system_dark() != shown_dark) apply_theme();
    }
    // Lo que llegó por el puente.
    if (store_dirty) {
      store_dirty = false;
      reload();
    }
    // Cada pocos segundos, los mensajes nuevos de WhatsApp Desktop.
    static double last = 0;
    if (from_db && !demo && wa::now_s() - last > 5) {
      last = wa::now_s();
      size_t before = current >= 0 ? chats[(size_t)current].msgs.size() : 0;
      reload();
      if (current >= 0 && chats[(size_t)current].msgs.size() != before) options.clear();
    }
    busy_reply();
    refresh();
    update_bar();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_RELOAD) reload();
    else if (item == tx::MP_IMPORT) import_export();
    else if (item == tx::MP_AI) settings_dialog();
    else if (item == tx::MP_CONNECT) connect_dialog();
    else if (item == tx::MP_TASKS) open_tasks();
    else if (item == tx::MP_BUSY) busy_menu();
    else if (item == tx::MP_DISCONNECT) disconnect();
    else if (item == tx::MP_LIGHT) set_theme("light");
    else if (item == tx::MP_DARK) set_theme("dark");
    else if (item == tx::MP_SYSTEM) set_theme("system");
    else if (item == tx::MP_BAR) close_clicked();
    else if (item == tx::MP_QUIT) {
      quit();
    } else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
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
    theme = "light";
    apply_theme();
    long long now = 1794365000;   // una hora fija para las capturas
    chats = wa::demo_chats(now);
    from_db = true;
    ai.provider = wa::P_CLAUDE;
    Provider->index(0);
    load_busy();
    // Dos estados de ejemplo.
    designs.clear();
    {
      wa::StatusDesign a;
      a.id = 1;
      a.tpl = 0;
      a.title = tx::DEMO_ST1_TITLE;
      a.body = tx::DEMO_ST1_BODY;
      a.footer = "#MueblesSol";
      a.emoji = "🪑";
      wa::StatusDesign b;
      b.id = 2;
      b.tpl = 1;
      b.title = tx::DEMO_ST2_TITLE;
      b.body = tx::DEMO_ST2_BODY;
      b.footer = "mueblessol.example";
      b.photo = "demo:mesa";
      designs = {a, b};
      view->design = 1;
    }
    tasks.clear();
    view->now = now;
    list->now = now;
    // Giulia escribe en italiano: «🌐 Traducir» detectó el idioma.
    {
      const wa::Chat& g = chats.back();
      langs[g.jid] = {"auto", tx::LANG_IT};
      const char* tr[] = {tx::DEMO_I1, tx::DEMO_I2, tx::DEMO_I3};
      for (int k = 0; k < 3; k++) translations[wa::trans_key(g.msgs[(size_t)k])] = tr[k];
    }
    // Una roja (80 h), una hecha, una naranja (30 h) y una verde (1 h).
    const char* titles[] = {tx::DEMO_T3, tx::DEMO_T2, tx::DEMO_T1, tx::DEMO_T4};
    const int from[] = {1, 2, 0, 4};
    const int hours[] = {80, 50, 30, 1};
    for (int k = 0; k < 4; k++) {
      wa::Task t;
      t.id = k + 1;
      t.title = titles[k];
      t.jid = chats[(size_t)from[k]].jid;
      t.chat = chats[(size_t)from[k]].name;
      t.created = now - hours[k] * 3600LL;
      t.done = k == 1;
      tasks.push_back(t);
    }
    pick(0);
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1600, 1000);
    render_to(dir + "/chat.png");
    Intent->value(tx::DEMO_INTENT);
    Tone->index(0);
    options = {tx::DEMO_S1, tx::DEMO_S2, tx::DEMO_S3};
    render_to(dir + "/suggestions.png");
    Draft->value(tx::DEMO_S1);
    view->hover = -1;
    render_to(dir + "/draft.png");
    // En oscuro, con el documento del chat de Carlos.
    theme = "dark";
    apply_theme();
    pick(2);
    render_to(dir + "/dark.png");
    theme = "light";
    apply_theme();
    pick(1);
    options.clear();
    ask_ai();
    render_to(dir + "/thinking.png");
    thinking = false;
    view->busy.clear();
    open_tasks();
    render_to(dir + "/tasks.png");
    pick(5);
    render_to(dir + "/translate.png");
    open_status();
    render_to(dir + "/status.png");
    pick(0);
    view->viewer = "demo:mesa";
    view->viewer_title = tx::DEMO_PHOTO_CAPTION;
    render_to(dir + "/viewer.png");
    view->viewer.clear();
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1200, 760);
    int f = 0;
    static bool trace = fl_getenv("DMS_MYWA_TRACE") != nullptr;   // cada paso, para encontrar un fallo
    auto chk = [&](bool ok, const char* what) {
      if (trace) std::fprintf(stderr, "ok? %d %s\n", ok ? 1 : 0, what);
      if (!ok) { std::printf("FAIL %s\n", what); f++; }
    };
    // La foto del chat de Laura y su foto adjunta, dibujadas.
    render_to("");
    bool photo = false;
    for (const auto& h : view->hits)
      if (h.act == 4) photo = true;
    chk(photo && !chats[0].pic.empty(), "foto de perfil y foto adjunta");
    // Los temas.
    Menu1_click(tx::MP_DARK);
    chk(wa::th().dark && theme == "dark", "tema oscuro");
    render_to("");
    Menu1_click(tx::MP_LIGHT);
    chk(!wa::th().dark && theme == "light", "tema claro");
    chk(chats.size() == 6 && current == 0 && view->chat == &chats[0], "chats de ejemplo");
    render_to("");
    // Clic de verdad en el tercer chat.
    for (const auto& h : list->hits)
      if (h.act == 0 && h.idx == 2) {
        Fl::e_x = h.x + 20;
        Fl::e_y = h.y + 20;
        list->handle(FL_PUSH);
        break;
      }
    chk(current == 2 && view->chat == &chats[2], "elegir un chat");
    // Buscar.
    list->filter = "fam";
    render_to("");
    int found = 0;
    for (const auto& h : list->hits) found += h.act == 0 ? 1 : 0;
    chk(found == 1, "buscar chats");
    list->filter.clear();
    // Los filtros y los archivados (Javi está archivado en la demo).
    {
      render_to("");
      auto click_chip = [&](int act, int idx) {
        for (const auto& h : list->hits)
          if (h.act == act && h.idx == idx) {
            Fl::e_x = h.x + 4;
            Fl::e_y = h.y + 4;
            Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
            list->handle(FL_PUSH);
            render_to("");
            return true;
          }
        return false;
      };
      auto shown = [&] {
        std::vector<std::string> v;
        for (const auto& h : list->hits)
          if (h.act == 0) v.push_back(chats[(size_t)h.idx].name);
        return v;
      };
      chk(list->count(wa::ChatList::F_ARCHIVED) == 1 && shown().size() == 5, "los archivados, fuera de la lista");
      chk(click_chip(3, -1) && list->mode == wa::ChatList::F_ARCHIVED && shown().size() == 1 && shown()[0] == tx::DEMO_JAVI,
          "abrir los archivados");
      chk(click_chip(4, -1) && list->mode == wa::ChatList::F_ALL, "volver de los archivados");
      chk(click_chip(2, wa::ChatList::F_TASKS) && shown().size() == 2, "filtro: con tareas");
      chk(click_chip(2, wa::ChatList::F_TODO) && shown().size() == 4, "filtro: por responder (3 días)");
      chk(click_chip(2, wa::ChatList::F_WAITING) && shown().size() == 1 && shown()[0] == tx::DEMO_MOM, "filtro: sin respuesta");
      chk(click_chip(2, wa::ChatList::F_ALL) && shown().size() == 5, "filtro: todos");
    }
    // Las sugerencias: «Usar» las pasa al borrador.
    options = {"Uno", "Dos", "Tres"};
    render_to("");
    for (const auto& h : view->hits)
      if (h.act == 1 && h.idx == 1) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h / 2;
        view->handle(FL_PUSH);
        break;
      }
    chk(std::string(Draft->value()) == "Dos", "usar una sugerencia");
    ask_ai();
    chk(thinking && !view->busy.empty(), "pidiendo a la IA");
    AiDone* d = new AiDone{chats[(size_t)current].id, wa::AiReply{{"A", "B", "C"}, ""}};
    answered(d);
    chk(!thinking && options.size() == 3 && options[0] == "A", "respuesta de la IA");
    // Las tareas: la fila de la lista, la vista y crearlas desde un chat.
    {
      ask_text = [](const char*, std::string& io) {
        io = io.empty() ? "Tarea nueva" : io;
        return true;
      };
      render_to("");
      chk(list->tasks_pending == 3, "tareas pendientes en la lista");
      for (const auto& h : list->hits)
        if (h.act == 1) {
          Fl::e_x = h.x + 20;
          Fl::e_y = h.y + 10;
          list->handle(FL_PUSH);
          break;
        }
      chk(view->tasks_mode && list->tasks_selected && current < 0, "abrir las tareas");
      render_to("");
      int boxes = 0, open = 0;
      for (const auto& h : view->hits) {
        if (h.act == 10) boxes++;
        if (h.act == 11) open++;
      }
      chk(boxes == 4 && open == 4, "las tareas dibujadas");
      int first = wa::tasks_order(tasks)[0];
      for (const auto& h : view->hits)
        if (h.act == 10 && h.idx == first) {
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
          view->handle(FL_PUSH);
          break;
        }
      chk(tasks[(size_t)first].done && wa::tasks_pending(tasks) == 2, "marcar una tarea como hecha");
      render_to("");
      for (const auto& h : view->hits)
        if (h.act == 11 && h.idx == 2) {
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          view->handle(FL_PUSH);
          break;
        }
      chk(!view->tasks_mode && current >= 0 && chats[(size_t)current].jid == tasks[2].jid, "abrir el chat de una tarea");
      // «+ Tarea» en la cabecera: el último mensaje que le escribieron.
      size_t n = tasks.size();
      render_to("");
      for (const auto& h : view->hits)
        if (h.act == 5) {
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          view->handle(FL_PUSH);
          break;
        }
      const wa::Chat& c = chats[(size_t)current];
      std::string last_in;
      for (const auto& m : c.msgs)
        if (!m.mine) last_in = wa::task_title_of(m);
      chk(tasks.size() == n + 1 && tasks.back().title == last_in && tasks.back().jid == c.jid, "«+ Tarea» desde el chat");
      // Clic derecho sobre un mensaje: esa es la tarea; el izquierdo no hace nada.
      render_to("");
      wa::Hit bubble{0, 0, 0, 0, 0, -1};
      for (const auto& h : view->hits)
        if (h.act == 6) bubble = h;
      chk(bubble.idx >= 0, "los mensajes se pueden señalar");
      Fl::e_x = bubble.x + 4;
      Fl::e_y = bubble.y + 4;
      Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
      view->handle(FL_PUSH);
      chk(tasks.size() == n + 1, "clic izquierdo en un mensaje no crea tareas");
      choose = [](const std::vector<std::string>& items) { return (int)items.size() - 1; };   // «Convertir en tarea»
      Fl::e_keysym = FL_Button + FL_RIGHT_MOUSE;
      view->handle(FL_PUSH);
      Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
      view->clear_selection();
      chk(tasks.size() == n + 2 && tasks.back().title == wa::task_title_of(c.msgs[(size_t)bubble.idx]), "clic derecho › Convertir en tarea");
      // Borrar y «+ Nueva tarea».
      open_tasks();
      render_to("");
      for (const auto& h : view->hits)
        if (h.act == 12 && h.idx == (int)tasks.size() - 1) {
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          view->handle(FL_PUSH);
          break;
        }
      chk(tasks.size() == n + 1, "borrar una tarea");
      render_to("");
      for (const auto& h : view->hits)
        if (h.act == 13) {
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          view->handle(FL_PUSH);
          break;
        }
      chk(tasks.size() == n + 2 && tasks.back().title == "Tarea nueva" && tasks.back().jid.empty(), "una tarea sin chat");
      pick(0);
      options = {"A", "B", "C"};
    }
    // Sin conectar (capturas): «Enviar» en una sugerencia la deja en el chat.
    render_to("");
    size_t before = chats[(size_t)current].msgs.size();
    for (const auto& h : view->hits)
      if (h.act == 3 && h.idx == 1) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h / 2;
        view->handle(FL_PUSH);
        break;
      }
    chk(chats[(size_t)current].msgs.size() == before + 1 && chats[(size_t)current].msgs.back().text == "B" &&
            chats[(size_t)current].msgs.back().mine && !*Draft->value(),
        "enviar una sugerencia");
    Draft->value("");
    BtnSend_click();
    chk(message == tx::EMPTY_DRAFT, "enviar sin texto avisa");
    // La barra de menús: el número y el menú con los chats por responder.
    {
      int waiting = 0;
      auto entries = bar_entries(waiting);
      chk(waiting == 4 && entries[3].tag == 100 && entries.back().tag == 2, "la barra: cuántos y el menú");
      chk(entries.size() > 9, "la barra: también los modos ocupado");
      bar_act(200);   // el primer modo, desde la barra
      chk(busy == busy_modes[0].name, "la barra: activar un modo ocupado");
      render_to("");
      bool chip = false;
      for (const auto& h : list->hits) chip = chip || h.act == 5;
      chk(chip && list->busy == busy, "el botón del modo ocupado, en la lista");
      bar_act(3);
      chk(busy.empty(), "la barra: desactivarlo");
      std::string first = bar_jids[0];
      bar_act(100);
      chk(current >= 0 && chats[(size_t)current].jid == first, "la barra: abrir un chat");
      pick(0);
    }
    // Los modos ocupado: activar, crear uno, editarlo, borrarlo y desactivar.
    {
      size_t n = busy_modes.size();
      chk(n == 3, "tres modos ocupado de partida");
      choose = [](const std::vector<std::string>&) { return 1; };   // «Conduciendo»
      busy_menu();
      chk(busy == tx::BUSY_DRIVING && busy_mode() != nullptr && busy_since > 0, "activar un modo");
      std::vector<std::string> answers = {"Gimnasio", "Entrenando, luego te escribo 💪"};
      size_t ai_n = 0;
      ask_text = [&answers, &ai_n](const char*, std::string& io) {
        io = answers[ai_n++ % answers.size()];
        return true;
      };
      int pickn = 0;
      choose = [&pickn, n](const std::vector<std::string>&) { return pickn++ == 0 ? (int)n : 0; };   // «+ Nuevo modo…» → texto fijo
      busy_menu();
      chk(busy_modes.size() == n + 1 && busy == "Gimnasio" && busy_modes.back().text == answers[1] && !busy_modes.back().ai,
          "crear un modo y activarlo");
      int step = 0;
      choose = [&step, n](const std::vector<std::string>&) {
        int k = step++;
        return k == 0 ? (int)n + 2 : k == 1 ? (int)n : 1;   // «Editar…» → el nuevo → «✨ Que conteste la IA»
      };
      answers = {"Entrenando ahora"};
      ai_n = 0;
      busy_menu();
      chk(busy_modes.back().text == "Entrenando ahora" && busy_modes.back().ai, "editar un modo (y que conteste la IA)");
      step = 0;
      choose = [&step, n](const std::vector<std::string>&) { return step++ == 0 ? (int)n + 3 : (int)n; };   // «Borrar…» → el nuevo
      busy_menu();
      chk(busy_modes.size() == n && busy.empty(), "borrar el modo activo lo desactiva");
      choose = [](const std::vector<std::string>&) { return 0; };
      busy_menu();
      choose = [](const std::vector<std::string>& items) { return (int)items.size() - 1; };   // «Desactivar»
      busy_menu();
      chk(busy.empty() && busy_since == 0, "desactivar");
      choose = [](const std::vector<std::string>&) { return -1; };
      ask_text = [](const char*, std::string& io) {
        io = io.empty() ? "Tarea nueva" : io;
        return true;
      };
    }
    // La IA con lo que escribo: mejorar (una propuesta) y corregir (con Cmd+Z).
    {
      pick(0);
      Draft->value("");
      BtnImprove_click();
      chk(message == tx::EMPTY_DRAFT && !thinking, "mejorar sin texto avisa");
      Draft->value("ola, mañana bamos");
      BtnImprove_click();
      chk(thinking && view->busy.find("✨") != std::string::npos, "mejorando");
      draft_done(new DraftDone{false, "ola, mañana bamos", "¡Hola! Mañana vamos.", ""});
      chk(!thinking && options.size() == 1 && options[0] == "¡Hola! Mañana vamos." && std::string(Draft->value()) == "ola, mañana bamos",
          "mejorar: una propuesta, sin tocar el borrador");
      options.clear();
      BtnFix_click();
      draft_done(new DraftDone{true, "ola, mañana bamos", "Hola, mañana vamos", ""});
      chk(std::string(Draft->value()) == "Hola, mañana vamos" && message == tx::FIXED, "corregir en el borrador");
      Fl::focus(Draft);
      Fl::e_state = FL_COMMAND;
      Fl::e_keysym = 'z';
      dispatch(FL_KEYBOARD, this);
      Fl::e_state = 0;
      chk(std::string(Draft->value()) == "ola, mañana bamos", "Cmd+Z deshace la corrección");
      draft_done(new DraftDone{true, "x", "x", ""});
      chk(message == tx::FIX_SAME, "nada que corregir");
      Draft->value("");
    }
    // Los estados: abrir el diseñador, cambiar la plantilla y el título, nuevo, guardar la imagen.
    {
      render_to("");
      for (const auto& h : list->hits)
        if (h.act == 7) {
          Fl::e_x = h.x + 10;
          Fl::e_y = h.y + 10;
          Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
          list->handle(FL_PUSH);
          break;
        }
      chk(view->status_mode && list->status_selected && view->design == 1, "abrir los estados");
      render_to("");
      int swatches = 0, thumbs = 0;
      for (const auto& h : view->hits) {
        swatches += h.act == 40 ? 1 : 0;
        thumbs += h.act == 51 ? 1 : 0;
      }
      chk(swatches == wa::STATUS_TPLS && thumbs == 2, "las plantillas y los guardados");
      for (const auto& h : view->hits)
        if (h.act == 40 && h.idx == 3) {
          Fl::e_x = h.x + 10;
          Fl::e_y = h.y + 10;
          view->handle(FL_PUSH);
          break;
        }
      chk(designs[1].tpl == 3, "elegir la plantilla «Noche»");
      ask_text = [](const char*, std::string& io) {
        io = "¡Nueva colección!";
        return true;
      };
      option_act(41, -1);
      chk(designs[1].title == "¡Nueva colección!", "cambiar el título");
      choose_photo = [] { return std::string(); };
      option_act(46, -1);
      chk(designs[1].photo.empty(), "quitar la foto");
      option_act(47, -1);
      chk(designs.size() == 3 && view->design == 2, "un estado nuevo");
      option_act(52, 2);
      chk(designs.size() == 2 && view->design == 1, "borrar un estado");
      fl_make_path(wa::config_dir().c_str());
      std::string dest = wa::config_dir() + "/prueba-estado.png";
      save_as = [&](const std::string&) { return dest; };
      option_act(49, -1);
      Fl_RGB_Image* png = wa::load_picture(dest);
      chk(png && png->w() == 1080 && png->h() == 1920, "guardar el estado como imagen de 1080×1920");
      delete png;
      std::remove(dest.c_str());
      save_as = [](const std::string&) { return std::string(); };
      message.clear();
      option_act(50, -1);
      chk(message == tx::STATUS_NEEDS_QR, "publicar sin WhatsApp vinculado avisa");
      ask_text = [](const char*, std::string& io) {
        io = io.empty() ? "Tarea nueva" : io;
        return true;
      };
      pick(0);
    }
    // El visor: la foto en grande, descargarla y cerrarlo.
    {
      pick(0);
      render_to("");
      for (const auto& h : view->hits)
        if (h.act == 4) {
          Fl::e_x = h.x + 10;
          Fl::e_y = h.y + 10;
          Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
          view->handle(FL_PUSH);
          break;
        }
      chk(view->viewer == "demo:mesa", "tocar una foto la abre en el visor");
      render_to("");
      bool down = false, close = false;
      for (const auto& h : view->hits) {
        down = down || h.act == 30;
        close = close || h.act == 32;
      }
      chk(down && close && view->hits.size() == 2, "el visor: descargar y cerrar (y nada del chat debajo)");
      fl_make_path(wa::config_dir().c_str());
      std::string dest = wa::config_dir() + "/prueba-descarga.png", asked;
      save_as = [&](const std::string& name) {
        asked = name;
        return dest;
      };
      std::remove(dest.c_str());
      viewer_act(30);
      Fl_RGB_Image* got = wa::load_picture(dest);
      chk(asked == "mesa.png" && got && got->w() == 520, "descargar la foto");
      delete got;
      std::remove(dest.c_str());
      save_as = [](const std::string&) { return std::string(); };
      Fl::e_keysym = FL_Escape;
      dispatch(FL_KEYBOARD, this);
      chk(view->viewer.empty(), "Esc cierra el visor");
      // La foto del contacto, en la cabecera, también se abre en grande.
      render_to("");
      bool face = false;
      for (const auto& h : view->hits)
        if (h.act == 33) {
          face = true;
          Fl::e_x = h.x + 5;
          Fl::e_y = h.y + 5;
          view->handle(FL_PUSH);
          break;
        }
      chk(face && view->viewer == chats[0].pic && view->viewer_title == chats[0].name, "la foto del contacto, en grande");
      viewer_act(32);
    }
    // Traducir: el chat de Giulia, en italiano, con su traducción debajo.
    {
      pick(5);
      render_to("");
      const wa::Chat& g = chats[5];
      chk(view->translate_label == wa::fmt(tx::LANG_DETECTED, {tx::LANG_IT}), "el idioma detectado, en la cabecera");
      chk(g.msgs[0].trans == tx::DEMO_I1 && g.msgs[1].trans == tx::DEMO_I2 && view->lays[0].trans.size() > 0,
          "lo recibido traducido y lo enviado con su original");
      chk(target_lang(g.jid) == tx::LANG_IT, "se envía en italiano");
      auto ks = wa::chat_countries(g);
      chk(ks.size() == 1 && std::string(ks[0]->iso) == "IT", "Giulia, en Italia");
      auto gs = wa::chat_countries(chats[1]);
      chk(gs.size() == 2, "el grupo de ejemplo, en dos países");
      int with = view->lays[0].bh;
      choose = [](const std::vector<std::string>&) { return 0; };   // «No traducir»
      translate_menu();
      render_to("");
      chk(lang_mode(g.jid).empty() && g.msgs[0].trans.empty() && view->lays[0].bh < with && view->translate_label.empty(),
          "dejar de traducir");
      choose = [](const std::vector<std::string>& items) {
        for (size_t k = 0; k < items.size(); k++)
          if (items[k].find(tx::LANG_FR) != std::string::npos) return (int)k;
        return -1;
      };
      translate_menu();
      chk(lang_mode(g.jid) == tx::LANG_FR && target_lang(g.jid) == tx::LANG_FR, "elegir el idioma");
      langs[g.jid] = {"auto", tx::LANG_IT};
      open_messages(current);
      choose = [](const std::vector<std::string>&) { return -1; };
      pick(0);
    }
    // La conversación: seleccionar, copiar, el menú, buscar y subir.
    {
      pick(0);
      render_to("");
      const wa::ChatView::LineBox* lb = nullptr;
      for (const auto& b : view->boxes)
        if (b.xs.size() > 8 && b.y > view->y() + 70) lb = &b;
      chk(lb != nullptr, "las líneas del chat");
      if (lb) {
        wa::ChatView::LineBox box = *lb;
        const std::string& line = view->lays[(size_t)box.msg].lines[(size_t)box.line];
        Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
        Fl::e_clicks = 0;
        Fl::e_x = box.xs[0] + 1;
        Fl::e_y = box.y + 6;
        view->handle(FL_PUSH);
        Fl::e_x = box.xs[5];
        view->handle(FL_DRAG);
        view->handle(FL_RELEASE);
        chk(view->selected_text() == line.substr(0, (size_t)box.at[5]), "seleccionar arrastrando");
        Fl::e_state = FL_COMMAND;
        Fl::e_keysym = 'c';
        chk(view->handle(FL_KEYBOARD) == 1 && message == tx::COPIED, "Cmd+C copia la selección");
        Fl::e_state = 0;
        Fl::e_keysym = FL_Button + FL_LEFT_MOUSE;
        Fl::e_clicks = 1;
        Fl::e_x = box.xs[2];
        view->handle(FL_PUSH);
        view->handle(FL_RELEASE);
        Fl::e_clicks = 0;
        chk(view->selected_text() == chats[(size_t)current].msgs[(size_t)box.msg].text, "doble clic: el mensaje entero");
        // Clic derecho: con selección, «Copiar la selección» es el primero.
        std::vector<std::string> seen;
        choose = [&seen](const std::vector<std::string>& items) {
          seen = items;
          return 0;
        };
        message.clear();
        bubble_menu(box.msg);
        chk(seen.size() == 3 && seen[0] == tx::COPY_SELECTION && message == tx::COPIED, "menú del mensaje: copiar");
        view->clear_selection();
        size_t before_tasks = tasks.size();
        choose = [&seen](const std::vector<std::string>& items) {
          seen = items;
          return (int)items.size() - 1;
        };
        bubble_menu(box.msg);
        chk(seen.size() == 2 && tasks.size() == before_tasks + 1 &&
                tasks.back().title == wa::task_title_of(chats[(size_t)current].msgs[(size_t)box.msg]),
            "menú del mensaje: convertir en tarea");
        choose = [](const std::vector<std::string>&) { return -1; };
      }
      // Buscar.
      std::string q = std::string(tx::DEMO_L3).substr(0, 9);
      open_find();
      find_input->value(q.c_str());
      find_changed();
      render_to("");
      chk(view->find_open && find_input->visible() && !view->matches.empty() &&
              view->match == (int)view->matches.size() - 1,
          "buscar en el chat");
      Fl::focus(find_input);
      Fl::e_keysym = FL_Escape;
      dispatch(FL_KEYBOARD, this);
      render_to("");
      chk(!view->find_open && !find_input->visible() && view->find.empty(), "Esc cierra la búsqueda");
      Fl::e_state = FL_COMMAND;
      Fl::e_keysym = 'f';
      dispatch(FL_KEYBOARD, this);
      Fl::e_state = 0;
      chk(view->find_open, "Cmd+F abre la búsqueda");
      close_find();
      // Subir con la rueda (con más mensajes de los que caben) y volver abajo.
      wa::Chat& c = chats[(size_t)current];
      for (int k = 0; k < 30; k++) {
        wa::Msg m;
        m.text = "Mensaje antiguo " + std::to_string(k);
        m.t = c.msgs.front().t - 60;
        c.msgs.insert(c.msgs.begin(), m);
      }
      render_to("");
      chk(view->max_scroll > 0 && view->msg_scroll == 0, "la conversación no cabe");
      Fl::e_dy = -10;
      view->handle(FL_MOUSEWHEEL);
      render_to("");
      bool down = false;
      for (const auto& h : view->hits)
        if (h.act == 21) down = true;
      chk(view->msg_scroll > 0 && down, "subir con la rueda");
      option_act(21, -1);
      chk(view->msg_scroll == 0, "volver abajo");
      Fl::e_dy = 0;
      c.msgs.erase(c.msgs.begin(), c.msgs.begin() + 30);
      view->lay_dirty = true;
    }
#ifndef _WIN32
    // Enviar de verdad por un puente de prueba, con Enter en el borrador.
    {
      Fl::lock();
      std::string dir = wa::config_dir();
      fl_make_path(dir.c_str());
      std::string sh = dir + "/puente-prueba.sh";
      wa::write_file(sh,
                     "#!/bin/sh\n"
                     "echo '{\"ev\":\"ready\",\"me\":\"34999@s.whatsapp.net\"}'\n"
                     "while IFS= read -r l; do\n"
                     "  case \"$l\" in\n"
                     "    *'\"cmd\":\"send\"'*)\n"
                     "      echo '{\"ev\":\"msg\",\"id\":\"B1\",\"chat\":\"34600111222@s.whatsapp.net\",\"mine\":true,\"text\":\"Hola desde la prueba\",\"t\":1794365100}'\n"
                     "      echo '{\"ev\":\"sent\",\"id\":\"r1\",\"ok\":true}'\n"
                     "      echo '{\"ev\":\"msg\",\"id\":\"B2\",\"chat\":\"34677000000@s.whatsapp.net\",\"name\":\"Nuevo\",\"text\":\"¿Qué tal?\",\"t\":1794365200}'\n"
                     "      ;;\n"
                     "    *'\"cmd\":\"status\"'*)\n"
                     "      id=$(printf '%s' \"$l\" | sed 's/.*\"id\":\"\\([^\"]*\\)\".*/\\1/')\n"
                     "      echo \"{\\\"ev\\\":\\\"sent\\\",\\\"id\\\":\\\"$id\\\",\\\"ok\\\":true}\"\n"
                     "      ;;\n"
                     "  esac\n"
                     "done\n");
      chmod(sh.c_str(), 0700);
      pick(0);
      send_mode = wa::S_LINKED;
      chk(bridge.start(sh, dir), "arrancar el puente");
      for (int i = 0; i < 100 && !linked; i++) Fl::wait(0.05);
      chk(linked, "puente vinculado");
      Draft->value("Hola desde la prueba");
      Fl::focus(Draft);
      Fl::e_keysym = FL_Enter;
      Fl::e_state = 0;
      dispatch(FL_KEYBOARD, this);
      chk(!*Draft->value() && pending.size() == 1, "Enter envía el borrador");
      for (int i = 0; i < 100 && !pending.empty(); i++) Fl::wait(0.05);
      for (int i = 0; i < 10; i++) Fl::wait(0.02);
      Tick_timer();
      chk(pending.empty(), "enviado por el puente");
      const wa::Chat& c = chats[(size_t)current];
      chk(c.jid == "34600111222@s.whatsapp.net" && c.msgs.back().mine && c.msgs.back().text == "Hola desde la prueba",
          "el mensaje enviado, en su chat");
      bool fresh = false;
      for (const auto& x : chats)
        if (x.live && x.name == "Nuevo" && x.last == "¿Qué tal?") fresh = true;
      chk(fresh, "un chat nuevo que llega por el puente");
      // Con «En una reunión» activo, a quien escribió después se le contesta solo (una vez).
      busy = tx::BUSY_MEETING;
      busy_since = 1794365150;
      busy_done.clear();
      size_t sent_before = pending.size();
      busy_reply();
      busy_reply();
      chk(busy_done.count("34677000000@s.whatsapp.net") && pending.size() == sent_before + 1,
          "modo ocupado: contesta solo, una vez, por el puente");
      // Un modo con IA, sin clave: se envía su texto tal cual.
      busy_modes.push_back({"IA", "En una reunión hasta las 18:00", true});
      busy = "IA";
      busy_done.clear();
      std::string keep_key = ai.claude_key;
      ai.claude_key.clear();
      busy_reply();
      chk(pending.size() == sent_before + 2, "modo con IA sin clave: el texto del modo");
      ai.claude_key = keep_key;
      busy_modes.pop_back();
      busy.clear();
      busy_since = 0;
      // Publicar un estado por el puente (con la confirmación).
      open_status();
      confirm = [](const std::string&) { return true; };
      message.clear();
      publish_status();
      chk(message == tx::STATUS_PUBLISHING && status_rids.size() == 1, "publicar un estado");
      for (int i = 0; i < 100 && !status_rids.empty(); i++) Fl::wait(0.05);
      chk(status_rids.empty() && message == tx::STATUS_PUBLISHED, "el estado, publicado por el puente");
      pick(0);
      Fl::e_state = FL_SHIFT;
      Draft->value("otra");
      chk(dispatch(FL_KEYBOARD, this) == 0 || std::string(Draft->value()) != "", "Mayúsculas+Enter no envía");
      bridge.stop();
      for (int i = 0; i < 40 && bridge.running(); i++) Fl::wait(0.05);
      send_mode = wa::S_NONE;
      std::remove(sh.c_str());
    }
    // DMS_MYWA_REALBRIDGE=1: el puente de verdad (junto a la app) da un QR.
    if (fl_getenv("DMS_MYWA_REALBRIDGE")) {
      static std::string got;
      auto keep = bridge.on_line;
      bridge.on_line = [](const std::string& l) {
        if (got.empty() && l.find("\"ev\":\"qr\"") != std::string::npos) got = l;
      };
      std::string dir = wa::config_dir() + "/puente-real";
      fl_make_path(dir.c_str());
      chk(bridge.start(wa::bridge_path(), dir), "arrancar el puente de verdad");
      for (int i = 0; i < 300 && got.empty(); i++) Fl::wait(0.1);
      std::printf("puente: %s\n", got.empty() ? "sin QR" : "QR recibido");
      chk(!got.empty(), "el puente de verdad da un código QR");
      bridge.stop();
      for (int i = 0; i < 40 && bridge.running(); i++) Fl::wait(0.05);
      bridge.on_line = keep;
    }
#endif
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
