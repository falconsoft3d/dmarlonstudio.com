part of 'tk_examples.dart';

// El código en C++ de MyWhatsapp (tk_showcase_cpp_mywa.dart): va tal cual en
// Form1.cpp, después de los textos (namespace tx).
const _mywaIncludes = r'''#include <algorithm>
#include <atomic>
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
#include <thread>
#include <vector>
#include <FL/Fl_Image_Surface.H>
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
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
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
};
struct Chat {
  long long id = 0;
  std::string name, jid, last, pic;   // pic: la foto de perfil en este equipo
  long long last_t = 0;
  int unread = 0;
  bool group = false;
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
      "SELECT s.Z_PK, s.ZPARTNERNAME, s.ZCONTACTJID, s.ZLASTMESSAGEDATE, s.ZLASTMESSAGETEXT, s.ZUNREADCOUNT, "
      "IFNULL((SELECT p.ZPATH FROM ZWAPROFILEPICTUREITEM p WHERE p.ZJID = s.ZCONTACTJID AND p.ZPATH IS NOT NULL LIMIT 1), '') "
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
bool load_messages(const std::string& path, Chat& c, int limit, std::string& error) {
#ifdef _WIN32
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
  const char* sql =
      "SELECT m.ZISFROMME, IFNULL(m.ZTEXT, ''), m.ZMESSAGEDATE, IFNULL(m.ZPUSHNAME, ''), IFNULL(m.ZMESSAGETYPE, 0), "
      "IFNULL(i.ZMEDIALOCALPATH, ''), IFNULL(i.ZTITLE, ''), IFNULL(i.ZFILESIZE, 0) "
      "FROM ZWAMESSAGE m LEFT JOIN ZWAMEDIAITEM i ON i.ZMESSAGE = m.Z_PK "
      "WHERE m.ZCHATSESSION = ? AND ((m.ZTEXT IS NOT NULL AND m.ZTEXT != '') OR m.ZMESSAGETYPE IN (1, 2, 3, 8, 11, 15)) "
      "ORDER BY m.ZMESSAGEDATE DESC LIMIT ?";
  if (q.prepare_v2(db, sql, -1, &st, nullptr) != 0) {
    error = tx::ERR_READ_DB;
    q.close(db);
    return false;
  }
  q.bind_int64(st, 1, c.id);
  q.bind_int64(st, 2, limit);
  std::vector<Msg> got;
  while (q.step(st) == SQLITE_ROW_) {
    Msg m;
    m.mine = q.column_int64(st, 0) != 0;
    m.text = col(st, 1);
    m.t = apple_time(q.column_double(st, 2));
    if (c.group && !m.mine) m.who = col(st, 3);
    m.kind = (int)q.column_int64(st, 4);
    if (m.kind != K_IMAGE && m.kind != K_VIDEO && m.kind != K_AUDIO && m.kind != K_DOC && m.kind != K_GIF && m.kind != K_STICKER)
      m.kind = K_TEXT;
    std::string local = col(st, 5);
    // Los adjuntos descargados están en «Message/Media/…».
    if (!local.empty() && file_exists(base_dir(path) + "/Message/" + local)) m.media = base_dir(path) + "/Message/" + local;
    m.title = col(st, 6);
    m.size = q.column_int64(st, 7);
    if (m.kind == K_TEXT && m.text.empty()) continue;
    got.push_back(m);
  }
  q.finalize(st);
  q.close(db);
  std::reverse(got.begin(), got.end());
  c.msgs = got;
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
std::pair<int, std::string> post_json(const std::string& url, const std::vector<std::string>& headers, const std::string& body) {
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
  if (!write_file(data, body) || !write_file(cfg, c)) return {0, tx::ERR_AI_NETWORK};
  std::string out;
  int code = run_capture(cfg, out);
  std::remove(cfg.c_str());
  std::remove(data.c_str());
  size_t nl = out.find_last_of('\n');
  if (code != 0 || nl == std::string::npos) return {0, code < 0 ? tx::ERR_NO_CURL : tx::ERR_AI_NETWORK};
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
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(T.text));
        fl_draw(fit(c.name, w() - 90 - tw).c_str(), x() + 68, Y + 26);
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
          if (Fl::event_inside(h.x, h.y, h.w, h.h) && on_pick) { on_pick(h.idx); break; }
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
  ChatView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

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
  void draw() override {
    hits.clear();
    const Theme& T = th();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(T.chat));
    fl_rectf(x(), y(), w(), h());
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
    int Y = bottom;
    fl_push_clip(x(), y() + head, w(), h() - head);
    for (int i = (int)chat->msgs.size() - 1; i >= 0 && Y > y() + head; i--) {
      const Msg& m = chat->msgs[(size_t)i];
      fl_font(FL_HELVETICA, 14);
      auto lines = m.text.empty() ? std::vector<std::string>() : wrap(m.text, maxw - 24);
      int lh = 19, who_h = m.who.empty() ? 0 : 18, ah = attach_h(m);
      Fl_RGB_Image* img = attach_image(m);
      int bw = 0;
      for (const auto& l : lines) bw = std::max(bw, (int)fl_width(l.c_str()));
      fl_font(FL_HELVETICA_BOLD, 12);
      if (!m.who.empty()) bw = std::max(bw, (int)fl_width(m.who.c_str()));
      if (img) bw = std::max(bw, img->w());
      else if (ah) bw = std::max(bw, 260);
      bw = std::max(bw + 24, 90);
      int bh = (int)lines.size() * lh + who_h + ah + 30;
      Y -= bh + 6;
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
      fl_color(rgb(T.text));
      for (const auto& l : lines) {
        fl_draw(l.c_str(), bx + 12, ty);
        ty += lh;
      }
      fl_font(FL_HELVETICA, 10);
      fl_color(rgb(T.muted));
      std::string t = clock_time(m.t);
      fl_draw(t.c_str(), bx + bw - 10 - (int)fl_width(t.c_str()), Y + bh - 8);
    }
    fl_pop_clip();
    // La cabecera: la foto, el nombre y el teléfono (o «grupo»).
    fl_color(rgb(T.panel));
    fl_rectf(x(), y(), w(), head);
    fl_color(rgb(T.card_line));
    fl_line(x(), y() + head - 1, x() + w(), y() + head - 1);
    avatar(x() + 16, y() + 10, 40, chat->name, chat->pic, rgb(T.panel));
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(T.text));
    fl_draw(fit(chat->name, w() - 100).c_str(), x() + 68, y() + 27);
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
        auto lines = wrap(o, w() - 32 - 180);
        int ly = cy + 22;
        for (size_t li = 0; li < lines.size() && li < 2; li++) {
          std::string l = li == 1 && lines.size() > 2 ? fit(lines[li] + "…", w() - 220) : lines[li];
          fl_draw(l.c_str(), x() + 30, ly);
          ly += 19;
        }
        int bx = x() + w() - 32 - 140;
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
        if (i != hover) { hover = i; redraw(); }
        window()->cursor(i >= 0 ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        window()->cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_PUSH:
        for (const auto& h : hits)
          if (Fl::event_inside(h.x, h.y, h.w, h.h) && on_act) { on_act(h.act, h.idx); break; }
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
           "ZMESSAGEDATE TIMESTAMP, ZPUSHNAME VARCHAR, ZMESSAGETYPE INTEGER);"
           "CREATE TABLE ZWAMEDIAITEM (Z_PK INTEGER PRIMARY KEY, ZMESSAGE INTEGER, ZMEDIALOCALPATH VARCHAR, ZTITLE VARCHAR, ZFILESIZE INTEGER);"
           "CREATE TABLE ZWAPROFILEPICTUREITEM (Z_PK INTEGER PRIMARY KEY, ZJID VARCHAR, ZPATH VARCHAR);"
           "INSERT INTO ZWAPROFILEPICTUREITEM VALUES (1,'34600111222@s.whatsapp.net','Media/Profile/laura');"
           "INSERT INTO ZWAMESSAGE VALUES (6,1,0,NULL,800000120,NULL,8);"
           "INSERT INTO ZWAMEDIAITEM VALUES (1,6,'Media/x/factura.pdf','factura.pdf',123456);"
           "INSERT INTO ZWAMESSAGE VALUES (7,1,0,NULL,800000130,NULL,1);"
           "INSERT INTO ZWACHATSESSION VALUES (1,'Laura','34600111222@s.whatsapp.net',800000100,'Genial',2,0,0);"
           "INSERT INTO ZWACHATSESSION VALUES (2,'Familia','1203@g.us',800000200,'Hola',0,0,0);"
           "INSERT INTO ZWACHATSESSION VALUES (3,'','status@broadcast',800000300,'x',0,0,0);"
           "INSERT INTO ZWAMESSAGE VALUES (1,1,0,'¿Mañana?',800000000,NULL,0);"
           "INSERT INTO ZWAMESSAGE VALUES (2,1,1,'Sí',800000050,NULL,0);"
           "INSERT INTO ZWAMESSAGE VALUES (3,1,0,'Genial',800000100,NULL,0);"
           "INSERT INTO ZWAMESSAGE VALUES (4,1,0,NULL,800000110,NULL,0);"
           "INSERT INTO ZWAMESSAGE VALUES (5,2,0,'Hola',800000200,'Ana',0);",
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
    chk(load_messages(path, l, 50, error) && l.msgs.size() == 5 && l.msgs[0].text == "¿Mañana?" && l.msgs[1].mine, "mensajes de la base de datos");
    chk(l.msgs[3].kind == K_DOC && l.msgs[3].title == "factura.pdf" && l.msgs[3].size == 123456 &&
            l.msgs[3].media == dir + "/Message/Media/x/factura.pdf",
        "documento adjunto");
    chk(l.msgs[4].kind == K_IMAGE && l.msgs[4].media.empty(), "foto sin descargar");
    std::remove((dir + "/Media/Profile/laura.thumb").c_str());
    std::remove((dir + "/Message/Media/x/factura.pdf").c_str());
    chk(load_messages(path, chats[0], 50, error) && chats[0].msgs[0].who == "Ana", "quién escribe en el grupo");
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
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace wa

// ============================================================ la ventana
struct AiDone {
  long long chat_id;
  wa::AiReply reply;
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
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // la IA contesta desde otro hilo
    setup();
    load_settings();
    apply_theme();
    reload();
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
    for (Fl_Input_* in : {(Fl_Input_*)Search, (Fl_Input_*)Intent, (Fl_Input_*)Draft}) {
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
  void form_close() override { save_settings(); }

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
      }
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
                                        "\ntheme=" + theme +
                                        (warned ? "\nwarned=1" : "") + "\n");
  }

  // ---- los chats
  void reload() {
    long long keep = current >= 0 && current < (int)chats.size() ? chats[(size_t)current].id : 0;
    std::string error;
    std::vector<wa::Chat> fresh;
    if (wa::db_exists() && wa::load_chats(wa::db_path(), fresh, error)) {
      from_db = true;
      // Los exportados que ya estaban siguen en la lista.
      for (const auto& c : chats)
        if (c.id < 0) fresh.push_back(c);
      chats = fresh;
      view->notice.clear();
    } else {
      from_db = false;
      view->notice = wa::db_exists() ? std::string(error) + "\n\n" + tx::PERMISSION_HELP : tx::NO_DESKTOP_HELP;
    }
    current = -1;
    for (int i = 0; i < (int)chats.size(); i++)
      if (keep && chats[(size_t)i].id == keep) current = i;
    if (current >= 0) open_messages(current);
    list->selected = current;
    list->redraw();
    view->redraw();
  }
  void open_messages(int i) {
    wa::Chat& c = chats[(size_t)i];
    // Las capturas y las pruebas nunca leen la base de datos de verdad.
    if (c.id > 0 && from_db && !demo) {
      std::string error;
      if (!wa::load_messages(wa::db_path(), c, 60, error)) say(error);
    }
    view->chat = &c;
  }
  void pick(int i) {
    if (i < 0 || i >= (int)chats.size()) return;
    current = i;
    list->selected = i;
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
    std::string where = from_db ? tx::SOURCE_DESKTOP : tx::SOURCE_EXPORT;
    if (!message.empty() && wa::now_s() < message_until) Status->text(" " + message);
    else
      Status->text(" " + wa::fmt(tx::STATUS, {std::to_string(chats.size()), where,
                                               ai.provider == wa::P_OPENAI ? tx::P_OPENAI : tx::P_CLAUDE}));
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
  void option_act(int act, int k) {
    if (act == 4) {
      open_attachment(k);
      return;
    }
    if (k < 0 || k >= (int)options.size()) return;
    const std::string& o = options[(size_t)k];
    if (act == 1) Draft->value(o.c_str());
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

  // ---- eventos del diseño
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
    else if (item == tx::MP_LIGHT) set_theme("light");
    else if (item == tx::MP_DARK) set_theme("dark");
    else if (item == tx::MP_SYSTEM) set_theme("system");
    else if (item == tx::MP_QUIT) {
      save_settings();
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
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1200, 760);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
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
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
