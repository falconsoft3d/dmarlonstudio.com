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
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
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
};
struct Chat {
  long long id = 0;
  std::string name, jid, last, pic;   // pic: la foto de perfil en este equipo
  long long last_t = 0;
  int unread = 0;
  bool group = false;
  bool live = false;   // llegó por el puente (no está en WhatsApp Desktop)
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
      "WHERE m.ZCHATSESSION = s.Z_PK ORDER BY m.ZMESSAGEDATE DESC LIMIT 1), '') "
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
           "IFNULL((SELECT p.ZPUSHNAME FROM ZWAPROFILEPUSHNAME p WHERE p.ZJID = g.ZMEMBERJID LIMIT 1), '') "
           "FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK LEFT JOIN ZWAGROUPMEMBER g ON g.Z_PK = m.ZGROUPMEMBER ";
  } else {
    sql += "'', '', '', '' FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK ";
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
AiReply parse_claude(int http, const std::string& body) {
  AiReply r;
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
  std::string text;
  for (const auto& b : j["content"].a)
    if (b["type"].str() == "text") text += b["text"].str();
  r.options = split_options(text);
  if (r.options.empty()) r.error = tx::ERR_AI_ANSWER;
  return r;
}
AiReply parse_openai(int http, const std::string& body) {
  AiReply r;
  bool ok = false;
  Json j = parse_json(body, &ok);
  if (!ok) { r.error = tx::ERR_AI_ANSWER; return r; }
  if (http >= 400 || j["error"].type == Json::OBJ) {
    std::string m = j["error"]["message"].str();
    r.error = http == 401 ? tx::ERR_AI_KEY : (m.empty() ? tx::ERR_AI_ANSWER : m);
    return r;
  }
  r.options = split_options(j["choices"][0]["message"]["content"].str());
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
  for (const char* e : {".jpg", ".jpeg", ".png", ".gif", ".thumb", ".bmp"})
    if (l.size() > std::strlen(e) && l.compare(l.size() - std::strlen(e), std::string::npos, e) == 0) return true;
  return false;
}
// Una imagen de disco según sus primeros bytes (JPEG, PNG o BMP), sea cual
// sea la extensión (las fotos de perfil de WhatsApp acaban en «.thumb»).
Fl_RGB_Image* load_picture(const std::string& path) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return nullptr;
  unsigned char m[8] = {0};
  size_t n = std::fread(m, 1, sizeof m, f);
  std::fclose(f);
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
  const std::vector<Task>* tasks = nullptr;   // para la bolita de los chats con tareas
  long long now = 0;                          // 0: la hora de verdad
  ChatList(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  bool visible_chat(const Chat& c) const {
    return filter.empty() || lower(c.name).find(lower(filter)) != std::string::npos ||
           lower(c.last).find(lower(filter)) != std::string::npos;
  }
  void draw() override {
    hits.clear();
    const Theme& T = th();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(T.list));
    fl_rectf(x(), y(), w(), h());
    int Y = y() - scroll;
    // Arriba, la fila de las tareas (no sale al buscar).
    if (filter.empty()) {
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
    }
    if (chats)
      for (size_t i = 0; i < chats->size(); i++) {
        const Chat& c = (*chats)[i];
        if (!visible_chat(c)) continue;
        int k = (int)i, rh = 68;
        // Solo se dibujan las que se ven (puede haber cientos).
        if (Y + rh < y() || Y > y() + h()) {
          hits.push_back({x(), Y, w(), rh, 0, k});
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
            fl_color(rgb(task_age_color(since, now ? now : (long long)now_s())));
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
    content_h = Y + scroll - y();
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
            } else if (on_pick) on_pick(h.idx);
            break;
          }
        return 1;
      case FL_MOUSEWHEEL:
        scroll = std::max(0, std::min(scroll + Fl::event_dy() * 30, std::max(0, content_h - h())));
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
    std::vector<std::string> lines;
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
  ChatView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

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
      L.bw = std::max(bw + 24, 90);
      L.bh = (int)L.lines.size() * 19 + who_h + ah + 30;
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
          fl_color(rgb(task_age_color(t.created, now ? now : (long long)now_s())));
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
    if ((tasks_mode || !chat) && find_input && find_input->visible()) find_input->hide();
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
        boxes.push_back(box);
        ty += lh;
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
    // A la derecha: «+ Tarea» y buscar (el campo, cuántos hay, ▲ ▼ ✕).
    fl_font(FL_HELVETICA_BOLD, 12);
    int rx = x() + w() - 20 - ((int)fl_width(tx::ADD_TASK) + 20);
    button(rx, y() + 17, tx::ADD_TASK, 5, -1, rgb(T.text), rgb(T.card));
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
    }
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(T.text));
    fl_draw(fit(chat->name, rx - (x() + 68) - 12).c_str(), x() + 68, y() + 27);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(T.muted));
    std::string ph = phone_of(chat->jid);
    fl_draw(chat->group ? tx::GROUP : (ph.empty() ? "" : ("+" + ph).c_str()), x() + 68, y() + 46);
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
        if (right || tasks_mode || !chat) return 1;
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
      if (c.group && !x.mine) x.who = d.members[(size_t)(m.who - 1)];
      c.msgs.push_back(x);
    }
    c.last = c.msgs.back().text;
    c.last_t = c.msgs.back().t;
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
           "ZLASTMESSAGEDATE TIMESTAMP, ZLASTMESSAGETEXT VARCHAR, ZUNREADCOUNT INTEGER, ZREMOVED INTEGER, ZHIDDEN INTEGER);"
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
           "INSERT INTO ZWACHATSESSION VALUES (1,'Laura','34600111222@s.whatsapp.net',800000100,'Genial',2,0,0);"
           "INSERT INTO ZWACHATSESSION VALUES (2,'Familia','1203@g.us',800000200,'Hola',0,0,0);"
           "INSERT INTO ZWACHATSESSION VALUES (3,'','status@broadcast',800000300,'x',0,0,0);"
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
            chats[1].unread == 2 && chats[1].last_t == 800000100 + 978307200LL,
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

// ============================================================ la ventana
struct AiDone {
  long long chat_id;
  wa::AiReply reply;
};

struct SendDone {
  std::string rid, error, id, jid, text, file;
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
    list->on_tasks = [] { if (self()) self()->open_tasks(); };
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
    reload();
    // Vinculado antes: el puente vuelve a conectar con la sesión guardada.
    if (send_mode == wa::S_LINKED) start_bridge();
    refresh();
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
    BtnAttach->color(input);
    BtnAttach->labelcolor(text);
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
                                        "\ncloud_phone=" + cloud.phone_id +
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
  }
  void pick(int i) {
    if (i < 0 || i >= (int)chats.size()) return;
    current = i;
    list->selected = i;
    list->tasks_selected = false;
    view->tasks_mode = false;
    view->msg_scroll = 0;
    view->asked_more = false;
    view->clear_selection();
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
    std::string where = from_db ? tx::SOURCE_DESKTOP : !store.empty() ? tx::SOURCE_LINKED : tx::SOURCE_EXPORT;
    std::string mode = send_mode == wa::S_CLOUD ? tx::MODE_CLOUD
                       : send_mode == wa::S_LINKED ? (linked ? tx::MODE_LINKED : tx::MODE_LINKING)
                                                   : tx::MODE_NONE;
    if (!message.empty() && wa::now_s() < message_until) Status->text(" " + message);
    else
      Status->text(" " + wa::fmt(tx::STATUS, {std::to_string(chats.size()), where,
                                               ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE, mode}));
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
  void open_attachment(int i) {
    if (current < 0 || i < 0 || i >= (int)chats[(size_t)current].msgs.size()) return;
    const std::string& path = chats[(size_t)current].msgs[(size_t)i].media;
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
    t.created = (long long)wa::now_s();
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
  void option_act(int act, int k) {
    if (act == 4) {
      open_attachment(k);
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
    std::string rid = "r" + std::to_string(++requests);
    if (send_mode == wa::S_LINKED) {
      if (!bridge.running()) start_bridge();
      if (!linked) {
        say(tx::NOT_LINKED);
        return;
      }
      std::string cmd = file.empty()
                            ? "{\"cmd\":\"send\",\"id\":" + wa::jstr(rid) + ",\"to\":" + wa::jstr(c.jid) + ",\"text\":" + wa::jstr(text) + "}"
                            : "{\"cmd\":\"send_file\",\"id\":" + wa::jstr(rid) + ",\"to\":" + wa::jstr(c.jid) + ",\"path\":" +
                                  wa::jstr(file) + ",\"caption\":" + wa::jstr(text) + "}";
      if (!bridge.send(cmd)) {
        say(tx::ERR_SEND);
        return;
      }
    } else {
      wa::CloudSettings s = cloud;
      std::string jid = c.jid;
      std::thread([s, jid, text, file, rid] {
        std::string id, err = wa::cloud_send(s, jid, text, file, &id);
        Fl::awake(cloud_done, new SendDone{rid, err, id, jid, text, file});
      }).detach();
    }
    pending[rid] = text;
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
      m.t = (long long)wa::now_s();
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

  // ---- eventos del diseño
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
    refresh();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_RELOAD) reload();
    else if (item == tx::MP_IMPORT) import_export();
    else if (item == tx::MP_AI) settings_dialog();
    else if (item == tx::MP_CONNECT) connect_dialog();
    else if (item == tx::MP_TASKS) open_tasks();
    else if (item == tx::MP_DISCONNECT) disconnect();
    else if (item == tx::MP_LIGHT) set_theme("light");
    else if (item == tx::MP_DARK) set_theme("dark");
    else if (item == tx::MP_SYSTEM) set_theme("system");
    else if (item == tx::MP_QUIT) {
      save_settings();
      bridge.stop();
      hide();
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
    tasks.clear();
    view->now = now;
    list->now = now;
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
    chk(chats.size() == 5 && current == 0 && view->chat == &chats[0], "chats de ejemplo");
    render_to("");
    // Clic de verdad en el tercer chat.
    for (const auto& h : list->hits)
      if (h.idx == 2) {
        Fl::e_x = h.x + 20;
        Fl::e_y = h.y + 20;
        list->handle(FL_PUSH);
        break;
      }
    chk(current == 2 && view->chat == &chats[2], "elegir un chat");
    // Buscar.
    list->filter = "fam";
    render_to("");
    chk(list->hits.size() == 1, "buscar chats");
    list->filter.clear();
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
    // La conversación: seleccionar, copiar, el menú, buscar y subir.
    {
      pick(0);
      render_to("");
      const wa::ChatView::LineBox* lb = nullptr;
      for (const auto& b : view->boxes)
        if (b.xs.size() > 8) lb = &b;
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
