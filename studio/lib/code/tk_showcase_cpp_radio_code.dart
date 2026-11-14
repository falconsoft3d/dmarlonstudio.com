part of 'tk_examples.dart';

// El código en C++ de la mesa de radio (tk_showcase_cpp_radio.dart): va tal
// cual en Form1.cpp, después de los textos (namespace tx).
const _radioIncludes = r'''#include <algorithm>
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
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <csignal>
#include <dlfcn.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _radioCode = r'''
// ============================================================ lo básico
// Una mesa de radio: seis canales, cada uno con una emisora de internet, su
// fader, su botón de sonar y el de silencio; los pads de colores buscan
// emisoras por género en Radio Browser (una base de datos abierta de radios)
// y la pantalla enseña lo que suena (los metadatos ICY de la emisora).
namespace rd {

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
std::string clean(std::string s) {
  for (auto& c : s)
    if (c == '\t' || c == '\n' || c == '\r') c = ' ';
  return trim(s);
}
long long now_t() { return (long long)std::time(nullptr); }
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
std::string hms(long long s) {
  if (s < 0) s = 0;
  char b[32];
  std::snprintf(b, sizeof b, "%02lld:%02lld:%02lld", s / 3600, (s / 60) % 60, s % 60);
  return b;
}
std::string clock_now() {
  std::time_t t = std::time(nullptr);
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &t);
#else
  localtime_r(&t, &v);
#endif
  char b[16];
  std::strftime(b, sizeof b, "%H:%M", &v);
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
  if (const char* o = fl_getenv("DMS_RADIO_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\radio";
#elif defined(__APPLE__)
  return home() + "/Library/Application Support/DMarlon Studio Demos/radio";
#else
  return home() + "/.config/DMarlon Studio Demos/radio";
#endif
}
// Donde se guardan las grabaciones: Música/<nombre de la app>.
std::string rec_dir() {
  if (const char* o = fl_getenv("DMS_RADIO_RECORDINGS")) return o;
#ifdef _WIN32
  return home() + "\\Music\\" + tx::REC_FOLDER;
#else
  return home() + "/Music/" + tx::REC_FOLDER;
#endif
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
// Un nombre de archivo sin caracteres raros.
std::string safe_name(const std::string& s) {
  std::string o;
  for (unsigned char c : s) {
    if (c < 32 || c == '/' || c == '\\' || c == ':' || c == '*' || c == '?' || c == '"' || c == '<' || c == '>' || c == '|') o += ' ';
    else o += (char)c;
  }
  o = trim(o);
  if (o.size() > 60) {
    o = o.substr(0, 60);
    while (!o.empty() && ((unsigned char)o.back() & 0xc0) == 0x80) o.pop_back();
    if (!o.empty() && ((unsigned char)o.back() & 0xc0) == 0xc0) o.pop_back();
  }
  return o.empty() ? std::string("radio") : o;
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

// ------------------------------------------------------------ las emisoras
struct Station {
  std::string uuid, name, url, country, codec, tags;
  int bitrate = 0;
  long long votes = 0;
  bool empty() const { return url.empty(); }
};
// La respuesta de Radio Browser (/json/stations/…) → emisoras con dirección.
std::vector<Station> parse_stations(const std::string& body) {
  std::vector<Station> out;
  Json j;
  if (!parse_json(body, j) || j.t != Json::ARR) return out;
  for (const auto& s : j.a) {
    Station st;
    st.uuid = s["stationuuid"].str();
    st.name = clean(s["name"].str());
    st.url = trim(s["url_resolved"].str());
    if (st.url.empty()) st.url = trim(s["url"].str());
    st.country = s["countrycode"].str();
    st.codec = s["codec"].str();
    st.tags = clean(s["tags"].str());
    st.bitrate = (int)s["bitrate"].num();
    st.votes = (long long)s["votes"].num();
    if (st.name.empty() || !(starts(lower(st.url), "http://") || starts(lower(st.url), "https://"))) continue;
    if (st.url.find_first_of(" \"'\\`<>") != std::string::npos) continue;
    out.push_back(st);
  }
  return out;
}
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
std::string api_base() {
  if (const char* b = fl_getenv("DMS_RADIO_API")) return b;
  return "https://de1.api.radio-browser.info";
}
// Buscar: por género ([tag]) o por nombre, en un país ("" = todos).
std::string search_url(const std::string& tag, const std::string& name, const std::string& country) {
  std::string u = api_base() + "/json/stations/search?order=votes&reverse=true&limit=60&hidebroken=true";
  if (!tag.empty()) u += "&tag=" + url_encode(tag);
  if (!name.empty()) u += "&name=" + url_encode(name);
  if (!country.empty()) u += "&countrycode=" + url_encode(country);
  return u;
}
// «Jazz FM · ES · MP3 128 kbps».
std::string station_line(const Station& s) {
  std::string o;
  if (!s.country.empty()) o += s.country;
  if (!s.codec.empty()) o += (o.empty() ? "" : " · ") + s.codec;
  if (s.bitrate > 0) o += (o.empty() ? "" : " ") + std::to_string(s.bitrate) + " kbps";
  return o;
}

// ------------------------------------------------------------ lo que suena (ICY)
// Las emisoras Shoutcast/Icecast mandan, si se les pide (Icy-MetaData: 1),
// cada «icy-metaint» bytes de audio un bloque «StreamTitle='Artista - Tema';».
struct Icy {
  std::string title, name;
  int metaint = 0;
  bool ok = false;
};
std::string header_value(const std::string& block, const std::string& key) {
  for (const auto& line : split(block, '\n')) {
    size_t c = line.find(':');
    if (c == std::string::npos) continue;
    if (lower(trim(line.substr(0, c))) == key) return trim(line.substr(c + 1));
  }
  return "";
}
Icy parse_icy(const std::string& data) {
  Icy r;
  size_t pos = 0;
  std::string block;
  // Las cabeceras (puede haber varias si hubo redirecciones): la última manda.
  while (pos < data.size() && (data.compare(pos, 5, "HTTP/") == 0 || data.compare(pos, 4, "ICY ") == 0)) {
    size_t e = data.find("\r\n\r\n", pos);
    if (e == std::string::npos) return r;
    block = data.substr(pos, e - pos);
    pos = e + 4;
  }
  if (block.empty()) return r;
  r.name = header_value(block, "icy-name");
  r.metaint = std::atoi(header_value(block, "icy-metaint").c_str());
  if (r.metaint <= 0 || pos + (size_t)r.metaint >= data.size()) return r;
  size_t m = pos + (size_t)r.metaint;
  size_t len = (unsigned char)data[m] * 16u;
  std::string meta = data.substr(m + 1, std::min(len, data.size() - m - 1));
  size_t a = meta.find("StreamTitle='");
  if (a != std::string::npos) {
    a += 13;
    size_t b = meta.find("';", a);
    r.title = trim(meta.substr(a, b == std::string::npos ? std::string::npos : b - a));
    r.ok = true;
  }
  return r;
}

// ------------------------------------------------------------ procesos (curl)
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
// curl con un archivo de configuración; lee como mucho [limit] bytes.
std::string run_curl(const std::string& config, size_t limit) {
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = dir + "/req-" + std::to_string((long long)(now_s() * 1000)) + "-" + std::to_string(counter++) + ".cfg";
  if (!write_file(path, config)) return "";
  std::string out;
#ifdef _WIN32
  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE rd = nullptr, wr = nullptr;
  if (CreatePipe(&rd, &wr, &sa, 0)) {
    SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0);
    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = wr;
    si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    PROCESS_INFORMATION pi{};
    std::wstring cmd = L"curl.exe -K \"" + wide(path) + L"\"";
    BOOL ok = CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
    CloseHandle(wr);
    if (ok) {
      char buf[16384];
      DWORD n = 0;
      while (out.size() < limit && ReadFile(rd, buf, sizeof buf, &n, nullptr) && n > 0) out.append(buf, n);
      TerminateProcess(pi.hProcess, 0);
      WaitForSingleObject(pi.hProcess, 3000);
      CloseHandle(pi.hProcess);
      CloseHandle(pi.hThread);
    }
    CloseHandle(rd);
  }
#else
  std::string q = "'";
  for (char c : path) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  q += "'";
  std::string exe = access("/usr/bin/curl", X_OK) == 0 ? "/usr/bin/curl" : "curl";
  FILE* p = popen((exe + " -K " + q + " 2>/dev/null").c_str(), "r");
  if (p) {
    char buf[16384];
    size_t n;
    while (out.size() < limit && (n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
    pclose(p);   // si quedaba radio por leer, curl se para al cerrarse la tubería
  }
#endif
  std::remove(path.c_str());
  return out;
}
const char* const UA = "user-agent = \"DMarlonStudio-Radio/1.0\"\n";
// GET de la API: el cuerpo y el código HTTP.
std::string http_get(const std::string& url, int& code) {
  std::string c = "url = " + curl_quote(url) + "\nsilent\nlocation\nmax-time = 20\nconnect-timeout = 10\n" + UA +
                  "write-out = \"\\n%{http_code}\"\n";
  std::string out = run_curl(c, 32u << 20);
  size_t nl = out.find_last_of('\n');
  code = std::atoi(nl == std::string::npos ? out.c_str() : out.c_str() + nl + 1);
  return nl == std::string::npos ? "" : out.substr(0, nl);
}
std::vector<Station> search(const std::string& tag, const std::string& name, const std::string& country, std::string& err) {
  int code = 0;
  std::string body = http_get(search_url(tag, name, country), code);
  err.clear();
  if (code != 200) {
    err = code == 0 ? tx::ERR_NO_NET : fmt(tx::ERR_HTTP, {std::to_string(code)});
    return {};
  }
  return parse_stations(body);
}
// Lo que suena ahora en una emisora (unos segundos de su audio).
Icy now_playing(const std::string& url) {
  std::string c = "url = " + curl_quote(url) + "\nsilent\nlocation\nmax-time = 8\nconnect-timeout = 6\n" + UA +
                  "header = \"Icy-MetaData: 1\"\ndump-header = \"-\"\n";
  return parse_icy(run_curl(c, 400000));
}

// Un proceso aparte que sigue solo (grabar con curl, sonar con ffplay).
struct Proc {
#ifdef _WIN32
  HANDLE h = nullptr;
#else
  pid_t pid = 0;
#endif
  bool running() const {
#ifdef _WIN32
    return h != nullptr;
#else
    return pid > 0;
#endif
  }
};
Proc spawn(const std::vector<std::string>& args) {
  Proc p;
  if (args.empty()) return p;
#ifdef _WIN32
  std::wstring cmd;
  for (const auto& a : args) cmd += (cmd.empty() ? L"" : L" ") + std::wstring(L"\"") + wide(a) + L"\"";
  STARTUPINFOW si{};
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi{};
  if (CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi)) {
    CloseHandle(pi.hThread);
    p.h = pi.hProcess;
  }
#else
  std::vector<char*> argv;
  for (const auto& a : args) argv.push_back(const_cast<char*>(a.c_str()));
  argv.push_back(nullptr);
  pid_t pid = 0;
  if (posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ) == 0) p.pid = pid;
#endif
  return p;
}
void stop(Proc& p) {
#ifdef _WIN32
  if (p.h) {
    TerminateProcess(p.h, 0);
    WaitForSingleObject(p.h, 2000);
    CloseHandle(p.h);
    p.h = nullptr;
  }
#else
  if (p.pid > 0) {
    kill(p.pid, SIGTERM);
    int st = 0;
    waitpid(p.pid, &st, 0);
    p.pid = 0;
  }
#endif
}
bool alive(Proc& p) {
#ifdef _WIN32
  if (!p.h) return false;
  if (WaitForSingleObject(p.h, 0) == WAIT_OBJECT_0) {
    CloseHandle(p.h);
    p.h = nullptr;
    return false;
  }
  return true;
#else
  if (p.pid <= 0) return false;
  int st = 0;
  if (waitpid(p.pid, &st, WNOHANG) == p.pid) {
    p.pid = 0;
    return false;
  }
  return true;
#endif
}
bool has_program(const char* name) {
#ifdef _WIN32
  wchar_t buf[MAX_PATH];
  return SearchPathW(nullptr, wide(std::string(name) + ".exe").c_str(), nullptr, MAX_PATH, buf, nullptr) > 0;
#else
  for (const auto& d : split(fl_getenv("PATH") ? fl_getenv("PATH") : "", ':'))
    if (!d.empty() && access((d + "/" + name).c_str(), X_OK) == 0) return true;
  for (const char* d : {"/opt/homebrew/bin/", "/usr/local/bin/", "/usr/bin/"})
    if (access((std::string(d) + name).c_str(), X_OK) == 0) return true;
  return false;
#endif
}

// ------------------------------------------------------------ el reproductor
// En macOS, un AVPlayer por canal (AVFoundation, cargado al vuelo y usado
// desde C++ con el runtime de Objective-C): cada uno con su volumen, así se
// pueden mezclar varias emisoras. En Windows y Linux, ffplay (de FFmpeg).
#ifdef __APPLE__
template <class R = id, class... A>
R msg(id o, const char* s, A... a) {
  return ((R(*)(id, SEL, A...))objc_msgSend)(o, sel_registerName(s), a...);
}
inline id cls(const char* n) { return (id)objc_getClass(n); }
inline id nsstr(const std::string& s) { return msg(cls("NSString"), "stringWithUTF8String:", s.c_str()); }
#endif
enum PlayState { PS_OFF = 0, PS_LOADING = 1, PS_PLAYING = 2, PS_PAUSED = 3, PS_FAILED = 4 };

bool av_ready() {
#ifdef __APPLE__
  static bool ok = dlopen("/System/Library/Frameworks/AVFoundation.framework/AVFoundation", RTLD_LAZY) != nullptr &&
                   objc_getClass("AVPlayer") != nullptr;
  return ok;
#else
  return false;
#endif
}
bool can_play() { return av_ready() || has_program("ffplay"); }

class Player {
public:
  Player() = default;
  Player(const Player&) = delete;
  Player& operator=(const Player&) = delete;
  ~Player() { close(); }
  void open(const std::string& url) {
    close();
    url_ = url;
#ifdef __APPLE__
    if (av_ready()) {
      id u = msg(cls("NSURL"), "URLWithString:", nsstr(url));
      if (u) p_ = msg(msg(cls("AVPlayer"), "alloc"), "initWithURL:", u);
      if (p_) {
        msg<void, float>(p_, "setVolume:", (float)vol_);
        msg<void>(p_, "play");
      }
      return;
    }
#endif
    restart();
  }
  void close() {
#ifdef __APPLE__
    if (p_) {
      msg<void>(p_, "pause");
      msg<void>(p_, "release");
      p_ = nullptr;
    }
#endif
    stop(proc_);
    url_.clear();
    paused_ = false;
  }
  void volume(double v) {
    v = std::max(0.0, std::min(1.0, v));
    if (std::fabs(v - vol_) < 0.004) return;
    vol_ = v;
#ifdef __APPLE__
    if (p_) {
      msg<void, float>(p_, "setVolume:", (float)v);
      return;
    }
#endif
    pending_ = now_s() + 0.4;   // ffplay: se vuelve a abrir con el volumen nuevo
  }
  void pause(bool on) {
    paused_ = on;
#ifdef __APPLE__
    if (p_) {
      if (on) msg<void>(p_, "pause");
      else msg<void>(p_, "play");
      return;
    }
#endif
    if (on) stop(proc_);
    else restart();
  }
  // Cada poco (desde el reloj): el volumen pendiente de ffplay.
  void tick() {
    if (pending_ > 0 && now_s() >= pending_) {
      pending_ = 0;
      if (!paused_ && !url_.empty()) restart();
    }
  }
  PlayState state() {
    if (url_.empty()) return PS_OFF;
    if (paused_) return PS_PAUSED;
#ifdef __APPLE__
    if (p_) {
      id it = msg(p_, "currentItem");
      if (it && msg<long>(it, "status") == 2) return PS_FAILED;
      long s = msg<long>(p_, "timeControlStatus");
      return s == 2 ? PS_PLAYING : s == 1 ? PS_LOADING : PS_PAUSED;
    }
#endif
    if (!alive(proc_)) return PS_FAILED;
    return PS_PLAYING;
  }
  // Por qué espera (macOS), para las pruebas.
  std::string why() {
#ifdef __APPLE__
    if (p_) {
      id r = msg(p_, "reasonForWaitingToPlay");
      if (r) return msg<const char*>(r, "UTF8String");
    }
#endif
    return "";
  }
  const std::string& url() const { return url_; }
  double vol() const { return vol_; }

private:
  void restart() {
    stop(proc_);
    if (url_.empty() || paused_) return;
    int v = (int)std::lround(vol_ * 100);
    if (v <= 0) return;   // a cero, sin proceso
    proc_ = spawn({"ffplay", "-nodisp", "-loglevel", "quiet", "-volume", std::to_string(v), url_});
  }
  std::string url_;
  double vol_ = 0.8, pending_ = 0;
  bool paused_ = false;
  Proc proc_;
#ifdef __APPLE__
  id p_ = nullptr;
#endif
};

// ------------------------------------------------------------ la mesa
const int CH_N = 6;
const unsigned CH_COLOR[CH_N] = {0xe85bd8, 0x5fd17a, 0x4ea7ff, 0xf5c35b, 0x6f7dff, 0xff6b6b};
// Los géneros de los pads: dos bancos de ocho.
struct Genre {
  const char* label;
  const char* tag;
  unsigned color;
};
const Genre* genres() {
  static const Genre g[16] = {
      {tx::G_NEWS, "news", 0xef6b6b},       {tx::G_POP, "pop", 0xf5a65b},
      {tx::G_ROCK, "rock", 0xf2d45c},       {tx::G_JAZZ, "jazz", 0x5fd17a},
      {tx::G_CLASSICAL, "classical", 0x5cc8e8}, {tx::G_ELECTRONIC, "electronic", 0x6b7cff},
      {tx::G_LATIN, "latin", 0xa36bff},     {tx::G_LOFI, "lofi", 0xff6fae},
      {tx::G_CHILL, "chillout", 0x5cc8e8},  {tx::G_REGGAE, "reggae", 0x5fd17a},
      {tx::G_HIPHOP, "hiphop", 0xf5a65b},   {tx::G_BLUES, "blues", 0x6b7cff},
      {tx::G_COUNTRY, "country", 0xf2d45c}, {tx::G_FLAMENCO, "flamenco", 0xef6b6b},
      {tx::G_SALSA, "salsa", 0xff6fae},     {tx::G_SOUNDTRACK, "soundtrack", 0xa36bff},
  };
  return g;
}

struct Channel {
  Station st;
  double vol = 0.75;
  bool muted = false, playing = false;
  std::string title;   // lo que suena (ICY)
  int state = PS_OFF;
};
struct Model {
  Channel ch[CH_N];
  int sel = 0, bank = 0, pad = -1, tab = 0;
  std::vector<Station> results;
  std::string results_title;
  int rsel = 0, rscroll = 0;
  bool searching = false;
  double master = 0.85;
  int fade = 2, sleep_min = 0;
  long long sleep_at = 0, on_air_since = 0, rec_since = 0;
  bool rec = false;
  int rec_ch = -1;
  // Lo que suena de verdad en cada canal (con el fundido), para los medidores.
  double gain[CH_N] = {0, 0, 0, 0, 0, 0};
  bool any_playing() const {
    for (const auto& c : ch)
      if (c.playing && !c.st.empty()) return true;
    return false;
  }
};
double target_gain(const Model& m, int i) {
  const Channel& c = m.ch[i];
  if (!c.playing || c.muted || c.st.empty()) return 0;
  return c.vol * m.master;
}

// Guardar la mesa: los canales, sus emisoras y los mandos.
std::string model_text(const Model& m) {
  std::string out = "RADIO 1\n";
  char b[160];
  std::snprintf(b, sizeof b, "M\t%.3f\t%d\t%d\t%d\t%d\n", m.master, m.fade, m.sleep_min, m.bank, m.sel);
  out += b;
  for (int i = 0; i < CH_N; i++) {
    const Channel& c = m.ch[i];
    std::snprintf(b, sizeof b, "C\t%d\t%.3f\t%d\t%d\t", i, c.vol, c.muted ? 1 : 0, c.playing ? 1 : 0);
    out += b + clean(c.st.name) + "\t" + clean(c.st.url) + "\t" + clean(c.st.uuid) + "\t" + clean(c.st.country) + "\t" +
           clean(c.st.codec) + "\t" + std::to_string(c.st.bitrate) + "\n";
  }
  return out;
}
bool parse_model(const std::string& text, Model& m) {
  auto lines = split(text, '\n');
  if (lines.empty() || trim(lines[0]) != "RADIO 1") return false;
  for (size_t k = 1; k < lines.size(); k++) {
    auto f = split(lines[k], '\t');
    if (f[0] == "M" && f.size() >= 6) {
      m.master = std::max(0.0, std::min(1.0, std::atof(f[1].c_str())));
      m.fade = std::max(0, std::min(10, std::atoi(f[2].c_str())));
      m.sleep_min = 0;   // el apagado no se recuerda: empieza siempre sin él
      m.bank = std::atoi(f[4].c_str()) == 1 ? 1 : 0;
      m.sel = std::max(0, std::min(CH_N - 1, std::atoi(f[5].c_str())));
    } else if (f[0] == "C" && f.size() >= 11) {
      int i = std::atoi(f[1].c_str());
      if (i < 0 || i >= CH_N) continue;
      Channel& c = m.ch[i];
      c.vol = std::max(0.0, std::min(1.0, std::atof(f[2].c_str())));
      c.muted = f[3] == "1";
      c.playing = false;   // al abrir, todo en silencio hasta que se pulse ▶
      c.st.name = f[5];
      c.st.url = f[6];
      c.st.uuid = f[7];
      c.st.country = f[8];
      c.st.codec = f[9];
      c.st.bitrate = std::atoi(f[10].c_str());
    }
  }
  return true;
}
// La extensión de una grabación según el formato de la emisora.
std::string rec_ext(const Station& s) {
  std::string c = lower(s.codec);
  if (c.find("aac") != std::string::npos) return ".aac";
  if (c.find("ogg") != std::string::npos || c.find("vorbis") != std::string::npos) return ".ogg";
  if (c.find("opus") != std::string::npos) return ".opus";
  if (c.find("flac") != std::string::npos) return ".flac";
  return ".mp3";
}
std::string rec_name(const Station& s, std::time_t t) {
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &t);
#else
  localtime_r(&t, &v);
#endif
  char b[32];
  std::strftime(b, sizeof b, "%Y-%m-%d %H.%M", &v);
  return safe_name(s.name) + " " + b + rec_ext(s);
}

// ------------------------------------------------------------ dibujar
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)((v >> 8) & 255), (uchar)(v & 255)); }
Fl_Color mixc(unsigned a, unsigned b, double t) {
  auto ch = [&](int s) { return (uchar)std::lround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t); };
  return fl_rgb_color(ch(16), ch(8), ch(0));
}
void rbox(int x, int y, int w, int h, int r, Fl_Color fill) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
}
void rframe(int x, int y, int w, int h, int r, Fl_Color c) {
  fl_color(c);
  fl_rounded_rect(x, y, w, h, r);
}
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
void text(const std::string& s, int x, int y, int size, Fl_Color c, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  fl_color(c);
  fl_draw(s.c_str(), x, y);
}
void text_c(const std::string& s, int cx, int y, int size, Fl_Color c, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  fl_color(c);
  fl_draw(s.c_str(), cx - (int)fl_width(s.c_str()) / 2, y);
}
void disc(int cx, int cy, int r, Fl_Color c) {
  fl_color(c);
  fl_pie(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
}

const double PI = 3.14159265358979323846;
enum Hit { H_REC = 1, H_TAB, H_ROW, H_RESULT, H_KNOB, H_DIAL, H_PAD, H_BANK, H_CHPAD, H_FADER, H_PLAY, H_MUTE };
const int KNOB_N = 3;
const unsigned KNOB_COLOR[KNOB_N] = {0xe5487a, 0x3ec46d, 0x3aa0ff};

// La mesa entera, dibujada: la pantalla, los mandos, los canales y los pads.
class Desk : public Fl_Widget {
public:
  struct HitBox {
    int x, y, w, h, act, arg;
  };
  Model* m = nullptr;
  std::vector<HitBox> hits;
  std::function<void(int, int)> on_act;
  std::function<void(int, int, double)> on_value;
  double blink = 0;
  int drag_act = 0, drag_arg = 0, drag_y = 0;
  double drag_v = 0;
  // Dónde está cada fader (para arrastrarlos).
  int fader_top = 0, fader_len = 1;

  Desk(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H, nullptr) {}

  int hit_at(int X, int Y) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const HitBox& h = hits[(size_t)i];
      if (X >= h.x && X < h.x + h.w && Y >= h.y && Y < h.y + h.h) return i;
    }
    return -1;
  }
  double knob_value(int k) const {
    if (k == 0) return m->master;
    if (k == 1) return m->fade / 10.0;
    return m->sleep_min / 120.0;
  }
  int handle(int e) override {
    if (!m) return Fl_Widget::handle(e);
    switch (e) {
      case FL_ENTER: return 1;
      case FL_PUSH: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i < 0) return 1;
        const HitBox h = hits[(size_t)i];
        if (h.act == H_FADER) {
          drag_act = H_FADER;
          drag_arg = h.arg;
          set_fader(h.arg, Fl::event_y());
          return 1;
        }
        if (h.act == H_KNOB || h.act == H_DIAL) {
          drag_act = h.act;
          drag_arg = h.arg;
          drag_y = Fl::event_y();
          drag_v = h.act == H_KNOB ? knob_value(h.arg) : (double)m->rsel;
          return 1;
        }
        if (on_act) on_act(h.act, h.arg);
        return 1;
      }
      case FL_DRAG:
        if (drag_act == H_FADER) set_fader(drag_arg, Fl::event_y());
        else if (drag_act == H_KNOB && on_value)
          on_value(H_KNOB, drag_arg, std::max(0.0, std::min(1.0, drag_v + (drag_y - Fl::event_y()) / 160.0)));
        else if (drag_act == H_DIAL && on_value)
          on_value(H_DIAL, 0, drag_v + (drag_y - Fl::event_y()) / 18.0);
        return 1;
      case FL_RELEASE:
        if (drag_act == H_DIAL && std::abs(Fl::event_y() - drag_y) < 4 && on_act) on_act(H_DIAL, 0);
        drag_act = 0;
        return 1;
      case FL_MOUSEWHEEL:
        if (m->tab == 1 && on_value) on_value(H_RESULT, 0, Fl::event_dy());
        return 1;
    }
    return Fl_Widget::handle(e);
  }
  void set_fader(int i, int y) {
    double v = 1.0 - (double)(y - fader_top) / fader_len;
    if (on_value) on_value(H_FADER, i, std::max(0.0, std::min(1.0, v)));
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0x15171b));
    fl_rectf(x(), y(), w(), h());
    if (!m) {
      fl_pop_clip();
      return;
    }
    int X = x(), Y = y();
    rbox(X + 12, Y + 10, w() - 24, h() - 20, 26, rgb(0x24272e));
    rframe(X + 12, Y + 10, w() - 24, h() - 20, 26, rgb(0x3a3d45));
    draw_rec(X, Y);
    draw_screen(X + 130, Y + 26, 560, 300);
    draw_knobs(X + 715, Y + 26);
    draw_strips(X + 26, Y + 340);
    draw_pads(X + 760, Y + 340, w() - 26 - 760, 360);
    fl_pop_clip();
  }

  void draw_rec(int X, int Y) {
    int cx = X + 70, cy = Y + 112;
    bool on = m->rec;
    disc(cx, cy, 40, rgb(0x15171b));
    disc(cx, cy, 36, on ? (std::fmod(blink, 1.0) < 0.5 ? rgb(0xff3b3b) : rgb(0xb81d1d)) : rgb(0x2c1416));
    fl_color(rgb(0xff4d4d));
    fl_line_style(FL_SOLID, 3);
    fl_arc(cx - 36, cy - 36, 72, 72, 0, 360);
    fl_line_style(0);
    text_c(tx::REC, cx, cy + 6, 17, on ? FL_WHITE : rgb(0xff6b6b), true);
    hits.push_back({cx - 40, cy - 40, 80, 80, H_REC, 0});
    if (on) text_c(hms(now_t() - m->rec_since), cx, cy + 62, 13, rgb(0xff8080), true);
    else text_c(tx::REC_HINT, cx, cy + 62, 11, rgb(0x8a8f99));
  }

  void draw_screen(int X, int Y, int W, int H) {
    rbox(X - 8, Y - 8, W + 16, H + 16, 18, rgb(0x0a0b0d));
    rbox(X, Y, W, H, 10, rgb(0x0f1722));
    // Arriba: en el aire, el tiempo, la hora y las pestañas.
    bool air = m->any_playing();
    disc(X + 20, Y + 20, 8, air ? rgb(0xff3b3b) : rgb(0x3b3f48));
    fl_color(air ? rgb(0xff6b6b) : rgb(0x6b7280));
    fl_line_style(FL_SOLID, 2);
    fl_arc(X + 10, Y + 10, 20, 20, 0, 360);
    fl_line_style(0);
    text(air ? hms(now_t() - m->on_air_since) : std::string("00:00:00"), X + 38, Y + 27, 20, FL_WHITE, true);
    text(clock_now(), X + 140, Y + 26, 14, rgb(0x9aa4b2));
    const char* tabs[2] = {tx::TAB_CHANNELS, tx::TAB_RESULTS};
    int tx0 = X + W - 12;
    for (int t = 1; t >= 0; t--) {
      fl_font(FL_HELVETICA_BOLD, 12);
      int tw = (int)fl_width(tabs[t]) + 20;
      tx0 -= tw;
      rbox(tx0, Y + 10, tw, 24, 6, m->tab == t ? rgb(0x2f6fea) : rgb(0x1b2533));
      text_c(tabs[t], tx0 + tw / 2, Y + 27, 12, m->tab == t ? FL_WHITE : rgb(0x9aa4b2), true);
      hits.push_back({tx0, Y + 10, tw, 24, H_TAB, t});
      tx0 -= 6;
    }
    fl_color(rgb(0x1e2a3a));
    fl_line(X + 10, Y + 44, X + W - 10, Y + 44);
    if (m->tab == 0) draw_channels(X, Y + 50, W, H - 56);
    else draw_results(X, Y + 50, W, H - 56);
  }

  void draw_channels(int X, int Y, int W, int H) {
    int rh = H / CH_N;
    for (int i = 0; i < CH_N; i++) {
      const Channel& c = m->ch[i];
      int ry = Y + i * rh;
      if (i == m->sel) rbox(X + 6, ry + 1, W - 12, rh - 2, 6, rgb(0x182234));
      rbox(X + 12, ry + 6, 6, rh - 12, 3, rgb(CH_COLOR[i]));
      text(std::to_string(i + 1), X + 28, ry + rh / 2 + 6, 15, rgb(CH_COLOR[i]), true);
      int nx = X + 50, lw = 120;
      fl_font(FL_HELVETICA_BOLD, 14);
      std::string name = c.st.empty() ? std::string(tx::EMPTY_CH) : c.st.name;
      text(fit(name, W - 60 - lw - 70), nx, ry + 19, 14, c.st.empty() ? rgb(0x5d6573) : FL_WHITE, true);
      std::string sub;
      if (!c.st.empty()) {
        if (c.state == PS_FAILED) sub = tx::ST_FAILED;
        else if (c.state == PS_LOADING) sub = tx::ST_LOADING;
        else if (!c.playing) sub = station_line(c.st);
        else if (!c.title.empty()) sub = "♪ " + c.title;
        else sub = station_line(c.st);
      }
      fl_font(FL_HELVETICA, 12);
      text(fit(sub, W - 60 - lw - 70), nx, ry + 36, 12, c.state == PS_FAILED ? rgb(0xff7a7a) : rgb(0x8fa3bd));
      // El medidor: lo que suena de verdad en el canal (fader × general).
      int mx = X + W - lw - 60, my = ry + rh / 2 - 4;
      int seg = 16;
      double g = m->gain[i];
      for (int k = 0; k < seg; k++) {
        bool lit = g > 0 && (k + 0.5) / seg <= g;
        unsigned col = k < 11 ? 0x3ecf6b : k < 14 ? 0xf2c84b : 0xff5b5b;
        fl_color(lit ? rgb(col) : rgb(0x1d2633));
        fl_rectf(mx + k * (lw / seg), my, lw / seg - 2, 8);
      }
      const char* st = c.st.empty() ? "" : c.muted ? "M" : !c.playing ? "❚❚" : c.state == PS_PLAYING ? "▶" : "…";
      text_c(st, X + W - 30, ry + rh / 2 + 6, 15, c.muted ? rgb(0xff6b6b) : rgb(0x3ecf6b), true);
      hits.push_back({X + 6, ry, W - 12, rh, H_ROW, i});
    }
  }

  void draw_results(int X, int Y, int W, int H) {
    std::string head = m->searching ? std::string(tx::SEARCHING) : m->results_title;
    text(fit(head, W - 30), X + 14, Y + 16, 13, rgb(0x9aa4b2), true);
    int rh = 30, top = Y + 26, rows = (H - 26) / rh;
    if (m->results.empty()) {
      text(m->searching ? "" : tx::NO_RESULTS, X + 14, top + 26, 13, rgb(0x5d6573));
      return;
    }
    m->rscroll = std::max(0, std::min(m->rscroll, (int)m->results.size() - rows));
    if (m->rsel < m->rscroll) m->rscroll = m->rsel;
    if (m->rsel >= m->rscroll + rows) m->rscroll = m->rsel - rows + 1;
    for (int r = 0; r < rows; r++) {
      int i = m->rscroll + r;
      if (i >= (int)m->results.size()) break;
      const Station& s = m->results[(size_t)i];
      int ry = top + r * rh;
      if (i == m->rsel) rbox(X + 6, ry, W - 12, rh - 2, 6, rgb(0x2f6fea));
      fl_font(FL_HELVETICA_BOLD, 13);
      std::string info = station_line(s);
      fl_font(FL_HELVETICA, 11);
      int iw = (int)fl_width(info.c_str());
      text(fit(s.name, W - 50 - iw), X + 16, ry + 19, 13, FL_WHITE, true);
      text(info, X + W - 18 - iw, ry + 19, 11, i == m->rsel ? rgb(0xdbe6ff) : rgb(0x8fa3bd));
      hits.push_back({X + 6, ry, W - 12, rh - 2, H_RESULT, i});
    }
    // La barrita de desplazamiento.
    if ((int)m->results.size() > rows) {
      int bh = H - 30, th = std::max(20, bh * rows / (int)m->results.size());
      int ty = Y + 28 + (bh - th) * m->rscroll / std::max(1, (int)m->results.size() - rows);
      rbox(X + W - 6, ty, 3, th, 2, rgb(0x3b4a60));
    }
  }

  void knob(int cx, int cy, int r, unsigned col, double v, const std::string& label, const std::string& value) {
    disc(cx, cy, r + 8, rgb(0x15171b));
    fl_color(rgb(0x30343c));
    fl_line_style(FL_SOLID, 6);
    fl_arc(cx - r, cy - r, 2 * r, 2 * r, -45, 225);
    fl_color(rgb(col));
    double a0 = 225, a1 = 225 - 270 * v;
    if (v > 0.001) fl_arc(cx - r, cy - r, 2 * r, 2 * r, a1, a0);
    fl_line_style(0);
    disc(cx, cy, r - 9, rgb(0x2b2f37));
    double ang = (225 - 270 * v) * PI / 180;
    fl_color(FL_WHITE);
    fl_line_style(FL_SOLID, 3);
    fl_line(cx + (int)std::lround(std::cos(ang) * (r - 22)), cy - (int)std::lround(std::sin(ang) * (r - 22)),
            cx + (int)std::lround(std::cos(ang) * (r - 11)), cy - (int)std::lround(std::sin(ang) * (r - 11)));
    fl_line_style(0);
    text_c(value, cx, cy + 5, 12, FL_WHITE, true);
    text_c(label, cx, cy + r + 24, 11, rgb(0x9aa4b2), true);
  }

  void draw_knobs(int X, int Y) {
    std::string vals[KNOB_N] = {std::to_string((int)std::lround(m->master * 100)) + "%",
                                m->fade == 0 ? std::string(tx::OFF) : fmt(tx::SECONDS, {std::to_string(m->fade)}),
                                m->sleep_min == 0 ? std::string(tx::OFF) : fmt(tx::MINUTES, {std::to_string(m->sleep_min)})};
    const char* labels[KNOB_N] = {tx::K_VOLUME, tx::K_FADE, tx::K_SLEEP};
    for (int k = 0; k < KNOB_N; k++) {
      int cx = X + 50 + k * 112, cy = Y + 70;
      knob(cx, cy, 38, KNOB_COLOR[k], knob_value(k), labels[k], vals[k]);
      hits.push_back({cx - 46, cy - 46, 92, 92, H_KNOB, k});
    }
    if (m->sleep_min > 0 && m->sleep_at > 0)
      text_c(fmt(tx::SLEEP_LEFT, {hms(m->sleep_at - now_t()).substr(3)}), X + 50 + 2 * 112, Y + 160, 11, rgb(0x6fb6ff), true);
    // La rueda grande: sintoniza la lista y, con un clic, carga la emisora.
    int cx = X + 50 + 3 * 112 + 30, cy = Y + 74;
    disc(cx, cy, 58, rgb(0x15171b));
    fl_color(rgb(0x3ee07a));
    fl_line_style(FL_SOLID, 5);
    fl_arc(cx - 52, cy - 52, 104, 104, 0, 360);
    fl_line_style(0);
    disc(cx, cy, 44, rgb(0x2b2f37));
    disc(cx, cy, 30, rgb(0x20232a));
    double a = (m->rsel % 24) * (2 * PI / 24);
    disc(cx + (int)std::lround(std::cos(a) * 37), cy - (int)std::lround(std::sin(a) * 37), 4, rgb(0x9aa4b2));
    text_c(tx::DIAL, cx, cy + 82, 11, rgb(0x9aa4b2), true);
    hits.push_back({cx - 58, cy - 58, 116, 116, H_DIAL, 0});
    // La marca de la mesa.
    text(tx::BRAND, X + 20, Y + 228, 22, FL_WHITE, true);
    fl_font(FL_HELVETICA_BOLD, 22);
    int bw = (int)fl_width(tx::BRAND);
    text(tx::BRAND_SUB, X + 28 + bw, Y + 228, 13, rgb(0xd97757), true);
    text(tx::BRAND_LINE, X + 20, Y + 250, 12, rgb(0x8a8f99));
  }

  void draw_strips(int X, int Y) {
    const int sw = 116, top = Y + 82, len = 208;
    fader_top = top;
    fader_len = len;
    for (int i = 0; i < CH_N; i++) {
      const Channel& c = m->ch[i];
      int sx = X + i * sw, cx = sx + sw / 2;
      // El pad de color: elige el canal.
      bool on = i == m->sel;
      if (on) rbox(cx - 28, Y + 8, 56, 56, 12, rgb(0xffffff));
      rbox(cx - 24, Y + 12, 48, 48, 10, mixc(CH_COLOR[i], 0x000000, c.playing ? 0.0 : 0.35));
      hits.push_back({cx - 28, Y + 8, 56, 56, H_CHPAD, i});
      // La ranura del fader, con sus marcas.
      rbox(cx - 4, top, 8, len, 4, rgb(0x0e0f12));
      for (int k = 0; k <= 10; k++) {
        int ty = top + len * k / 10;
        fl_color(rgb(0x5a5f69));
        fl_line(cx - 22, ty, cx - 12, ty);
        fl_line(cx + 12, ty, cx + 22, ty);
      }
      int ty = top + (int)std::lround((1 - c.vol) * len);
      rbox(cx - 24, ty - 13, 48, 26, 5, rgb(0xe9ebef));
      rbox(cx - 24, ty - 13, 48, 10, 5, rgb(0xffffff));
      fl_color(rgb(0x6b7280));
      fl_line(cx - 20, ty, cx + 20, ty);
      hits.push_back({cx - 30, top - 14, 60, len + 28, H_FADER, i});
      // El nombre corto de la emisora.
      fl_font(FL_HELVETICA_BOLD, 11);
      std::string name = c.st.empty() ? "—" : fit(c.st.name, sw - 12);
      text_c(name, cx, top + len + 30, 11, c.st.empty() ? rgb(0x5d6573) : rgb(0xd5d9e0), true);
      // ▶ y M.
      int by = top + len + 44;
      rbox(cx - 34, by, 30, 26, 6, c.playing ? rgb(0x2fbf5b) : rgb(0x1f4d2c));
      text_c(c.playing ? "❚❚" : "▶", cx - 19, by + 18, 13, FL_WHITE, true);
      hits.push_back({cx - 34, by, 30, 26, H_PLAY, i});
      rbox(cx + 4, by, 30, 26, 6, c.muted ? rgb(0xff4d4d) : rgb(0x5a2328));
      text_c("M", cx + 19, by + 18, 13, FL_WHITE, true);
      hits.push_back({cx + 4, by, 30, 26, H_MUTE, i});
    }
  }

  void draw_pads(int X, int Y, int W, int H) {
    fl_color(rgb(0x4a4e57));
    fl_rounded_rect(X, Y, W, H, 16);
    const int pw = (W - 28 - 14) / 2, ph = 62, gap = 12;
    const Genre* g = genres();
    for (int k = 0; k < 8; k++) {
      int idx = m->bank * 8 + k;
      int px = X + 14 + (k % 2) * (pw + 14), py = Y + 14 + (k / 2) * (ph + gap);
      bool on = m->pad == idx;
      if (on) rbox(px - 4, py - 4, pw + 8, ph + 8, 14, FL_WHITE);
      rbox(px, py, pw, ph, 11, mixc(g[idx].color, 0xffffff, 0.12));
      rbox(px + 4, py + 4, pw - 8, ph - 8, 9, rgb(g[idx].color));
      text_c(g[idx].label, px + pw / 2, py + ph / 2 + 6, 15, rgb(0x1b1d22), true);
      hits.push_back({px, py, pw, ph, H_PAD, idx});
    }
    int by = Y + H - 44, cx = X + W / 2;
    rbox(cx - 70, by, 44, 30, 6, rgb(0xeef0f3));
    text_c("‹", cx - 48, by + 22, 22, rgb(0x1b1d22), true);
    hits.push_back({cx - 70, by, 44, 30, H_BANK, -1});
    text_c(fmt(tx::BANK, {std::to_string(m->bank + 1)}), cx, by + 20, 12, rgb(0x9aa4b2), true);
    rbox(cx + 26, by, 44, 30, 6, rgb(0xeef0f3));
    text_c("›", cx + 48, by + 22, 22, rgb(0x1b1d22), true);
    hits.push_back({cx + 26, by, 44, 30, H_BANK, 1});
  }
};

// ------------------------------------------------------------ ejemplo
// Emisoras de ejemplo (para las capturas y las pruebas, sin red).
std::vector<Station> demo_stations() {
  struct D {
    const char *name, *country, *codec;
    int kbps;
  };
  const D d[] = {{"Jazz Lounge FM", "US", "MP3", 128},    {"Radio Clásica Viva", "ES", "AAC", 96},
                 {"Lo-fi Beats 24/7", "DE", "MP3", 192}, {"Noticias al Minuto", "MX", "MP3", 64},
                 {"Rock Clásico Total", "AR", "MP3", 128}, {"Salsa y Son Cubano", "CU", "AAC", 64},
                 {"Electro Nights", "FR", "OGG", 160},    {"Smooth Jazz Café", "GB", "MP3", 128},
                 {"Bossa & Jazz Rio", "BR", "AAC", 96},    {"Swing Era Radio", "US", "MP3", 128}};
  std::vector<Station> out;
  int k = 0;
  for (const auto& x : d) {
    Station s;
    s.name = x.name;
    s.country = x.country;
    s.codec = x.codec;
    s.bitrate = x.kbps;
    s.url = "https://radio.example.com/stream" + std::to_string(k);
    s.uuid = "demo-" + std::to_string(k++);
    out.push_back(s);
  }
  return out;
}

// ------------------------------------------------------------ pruebas
int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  // Radio Browser.
  std::string body = R"([{"stationuuid":"a1","name":"  Jazz FM ","url":"http://x.example/old","url_resolved":"https://x.example/live","countrycode":"US","codec":"MP3","bitrate":128,"tags":"jazz,smooth","votes":99},
                         {"stationuuid":"a2","name":"Sin URL","url":"","url_resolved":""},
                         {"stationuuid":"a3","name":"Rara","url_resolved":"ftp://x"},
                         {"stationuuid":"a4","name":"Comillas","url_resolved":"https://x.example/a'b"},
                         {"stationuuid":"a5","name":"Solo url","url":"https://y.example/s","url_resolved":""}])";
  auto st = parse_stations(body);
  chk(st.size() == 2, "emisoras válidas");
  chk(st.size() == 2 && st[0].name == "Jazz FM" && st[0].url == "https://x.example/live" && st[0].bitrate == 128, "emisora leída");
  chk(st.size() == 2 && st[1].url == "https://y.example/s", "url sin resolver");
  chk(station_line(st[0]) == "US · MP3 128 kbps", "línea de la emisora");
  std::string u = search_url("lo fi", "", "ES");
  chk(u.find("tag=lo%20fi") != std::string::npos && u.find("countrycode=ES") != std::string::npos &&
          u.find("hidebroken=true") != std::string::npos,
      "url de búsqueda");
  // ICY: cabeceras, el audio hasta icy-metaint y el bloque de metadatos.
  std::string meta = "StreamTitle='Miles Davis - So What';StreamUrl='';";
  std::string blk = meta;
  while (blk.size() % 16) blk += '\0';
  std::string data = "HTTP/1.1 302 Found\r\nLocation: x\r\n\r\nHTTP/1.0 200 OK\r\nicy-name: Jazz FM\r\nicy-metaint: 32\r\n\r\n" +
                     std::string(32, 'A') + std::string(1, (char)(blk.size() / 16)) + blk + std::string(100, 'B');
  Icy icy = parse_icy(data);
  chk(icy.ok && icy.metaint == 32 && icy.title == "Miles Davis - So What" && icy.name == "Jazz FM", "metadatos ICY");
  chk(!parse_icy("HTTP/1.0 200 OK\r\n\r\nxxxx").ok, "sin metadatos");
  chk(!parse_icy("").ok, "vacío");
  // Guardar y abrir la mesa.
  Model m;
  m.master = 0.6;
  m.fade = 4;
  m.bank = 1;
  m.sel = 3;
  m.ch[2].st = st[0];
  m.ch[2].vol = 0.42;
  m.ch[2].muted = true;
  m.ch[2].playing = true;
  Model b;
  chk(parse_model(model_text(m), b), "mesa guardada");
  chk(std::fabs(b.master - 0.6) < 1e-6 && b.fade == 4 && b.bank == 1 && b.sel == 3, "mandos guardados");
  chk(b.ch[2].st.url == st[0].url && std::fabs(b.ch[2].vol - 0.42) < 1e-6 && b.ch[2].muted && !b.ch[2].playing, "canal guardado");
  chk(b.ch[0].st.empty(), "canal vacío");
  // Lo que suena: fader × general, a cero si está en silencio o parado.
  m.ch[2].muted = false;
  chk(std::fabs(target_gain(m, 2) - 0.42 * 0.6) < 1e-9, "ganancia");
  m.ch[2].muted = true;
  chk(target_gain(m, 2) == 0 && target_gain(m, 0) == 0, "silencio y vacío");
  // Grabaciones.
  Station rs;
  rs.name = "Radio: \"Jazz\"/24h";
  rs.codec = "AAC+";
  std::string rn = rec_name(rs, (std::time_t)1763100000);
  chk(rn.find('/') == std::string::npos && rn.find('"') == std::string::npos && rn.size() > 10 &&
          rn.compare(rn.size() - 4, 4, ".aac") == 0,
      "nombre de la grabación");
  chk(safe_name(std::string(80, 'x')).size() == 60, "nombre largo");
  chk(hms(3725) == "01:02:05", "tiempo");
  chk(genres()[3].tag == std::string("jazz"), "pads");
  // De verdad: DMS_RADIO_LIVE=1 busca jazz, lee lo que suena y (en macOS) lo
  // pone a sonar sin volumen unos segundos.
  if (fl_getenv("DMS_RADIO_LIVE")) {
    std::string err;
    auto live = search("jazz", "", "", err);
    std::printf("live: %zu emisoras de jazz %s\n", live.size(), err.c_str());
    chk(live.size() >= 10, "buscar en Radio Browser");
    int titles = 0;
    for (size_t i = 0; i < live.size() && i < 6; i++) {
      Icy y = now_playing(live[i].url);
      if (y.ok && !y.title.empty()) titles++;
      std::printf("  %s: %s\n", live[i].name.c_str(), y.title.c_str());
    }
    chk(titles >= 1, "lo que suena (ICY)");
    if (av_ready() && !live.empty()) {
      Fl::screen_count();   // abre la conexión con el sistema: AVPlayer necesita su bucle
      Player p;
      p.volume(0);
      p.open(live[0].url);
      double t0 = now_s();
      while (now_s() - t0 < 15 && p.state() != PS_PLAYING) Fl::wait(0.2);
      std::printf("  AVPlayer: %d en %.1f s %s\n", (int)p.state(), now_s() - t0, p.why().c_str());
      chk(p.state() == PS_PLAYING, "AVPlayer suena");
      p.close();
    }
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace rd

// ============================================================ la ventana
struct SearchDone {
  std::vector<rd::Station> list;
  std::string err, title;
  int pad;
};
struct IcyDone {
  std::string url, title;
};

class Form1 : public FormDesign {
public:
  rd::Model m;
  rd::Desk* desk = nullptr;
  std::unique_ptr<rd::Player> players[rd::CH_N];
  // Las que se van (con fundido) cuando un canal cambia de emisora.
  std::vector<std::pair<std::unique_ptr<rd::Player>, double>> dying;
  rd::Proc rec_proc;
  std::string rec_file, message;
  double message_until = 0, last_tick = 0, next_icy = 0;
  bool live = true;
  int icy_busy = 0;
  const char* country_codes[11] = {"", "ES", "MX", "AR", "CO", "CU", "US", "GB", "FR", "DE", "IT"};

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    for (auto& p : players) p = std::make_unique<rd::Player>();
    if (fl_getenv("DMS_RADIO_SELFTEST")) std::exit(rd::selftest());
    if (fl_getenv("DMS_RADIO_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_RADIO_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    BoardHint->hide();
    Board->box(FL_FLAT_BOX);
    desk = new rd::Desk(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(desk);
    desk->m = &m;
    desk->on_act = [](int a, int b) { if (self()) self()->act(a, b); };
    desk->on_value = [](int a, int b, double v) { if (self()) self()->value(a, b, v); };
    Country->items({tx::C_ALL, tx::C_ES, tx::C_MX, tx::C_AR, tx::C_CO, tx::C_CU, tx::C_US, tx::C_GB, tx::C_FR, tx::C_DE, tx::C_IT});
    Country->index(0);
  }
  void form_create() override {
    set_fonts();
    Fl::lock();   // las búsquedas y los metadatos llegan de otros hilos
    setup();
    load();
    if (!rd::can_play()) say(tx::NO_PLAYER, 12);
    else say(tx::HELLO, 8);
    refresh();
  }
  void form_close() override {
    save();
    stop_rec();
    for (auto& p : players) p->close();
  }

  // ---- guardar
  std::string data_file() const { return rd::config_dir() + "/mesa.tsv"; }
  void load() {
    std::string t;
    if (rd::read_file(data_file(), t)) rd::parse_model(t, m);
  }
  void save() {
    if (!live) return;
    fl_make_path(rd::config_dir().c_str());
    rd::write_file(data_file(), rd::model_text(m));
  }

  // ---- lo que se ve
  void say(const std::string& t, double secs = 5) {
    message = t;
    message_until = rd::now_s() + secs;
    update_status();
  }
  void update_status() {
    if (!message.empty() && rd::now_s() < message_until) {
      Status->text(" " + message);
      return;
    }
    const rd::Channel& c = m.ch[m.sel];
    std::string s = rd::fmt(tx::ST_CHANNEL, {std::to_string(m.sel + 1)});
    if (c.st.empty()) s += " · " + std::string(tx::EMPTY_HINT);
    else {
      s += " · " + c.st.name;
      if (!c.title.empty()) s += " · ♪ " + c.title;
    }
    if (m.rec) s += "  ·  " + rd::fmt(tx::RECORDING_TO, {rec_file});
    Status->text(" " + s);
  }
  void refresh() {
    if (desk) desk->redraw();
    update_status();
  }

  // ---- los canales
  void start(int i) {
    rd::Channel& c = m.ch[i];
    if (c.st.empty()) {
      say(tx::EMPTY_HINT);
      return;
    }
    if (!m.any_playing()) m.on_air_since = rd::now_t();
    c.playing = true;
    c.state = rd::PS_LOADING;
    if (live) {
      if (players[i]->url() != c.st.url) {
        m.gain[i] = 0;
        players[i]->volume(0);
        players[i]->open(c.st.url);
      } else {
        players[i]->pause(false);
      }
    }
    next_icy = 0;
  }
  void toggle_play(int i) {
    rd::Channel& c = m.ch[i];
    if (c.playing) {
      c.playing = false;
      if (live) players[i]->pause(true);
    } else {
      start(i);
    }
    save();
    refresh();
  }
  // Una emisora al canal: la anterior se va con un fundido.
  void load_station(int i, const rd::Station& s) {
    rd::Channel& c = m.ch[i];
    if (live && !players[i]->url().empty() && m.gain[i] > 0.01) {
      dying.emplace_back(std::move(players[i]), m.gain[i]);
      players[i] = std::make_unique<rd::Player>();
    } else if (live) {
      players[i]->close();
    }
    c.st = s;
    c.title.clear();
    c.playing = false;
    m.gain[i] = 0;
    start(i);
    m.sel = i;
    m.tab = 0;
    save();
    say(rd::fmt(tx::LOADED, {s.name, std::to_string(i + 1)}));
    refresh();
  }
  void clear_channel(int i) {
    if (live) players[i]->close();
    m.ch[i] = rd::Channel();
    m.gain[i] = 0;
    save();
    refresh();
  }
  void stop_all() {
    for (int i = 0; i < rd::CH_N; i++) {
      m.ch[i].playing = false;
      if (live) players[i]->pause(true);
    }
    refresh();
  }

  // ---- buscar
  void search(const std::string& tag, const std::string& name, int pad) {
    std::string country = country_codes[std::max(0, std::min(10, Country->index()))];
    m.tab = 1;
    m.searching = true;
    m.pad = pad;
    m.results.clear();
    std::string title = pad >= 0 ? rd::genres()[pad].label : name;
    if (!live) {
      done_search(SearchDone{rd::demo_stations(), "", title, pad});
      return;
    }
    refresh();
    std::thread([tag, name, country, title, pad] {
      auto* d = new SearchDone;
      d->list = rd::search(tag, name, country, d->err);
      d->title = title;
      d->pad = pad;
      Fl::awake(searched, d);
    }).detach();
  }
  static void searched(void* p) {
    std::unique_ptr<SearchDone> d(static_cast<SearchDone*>(p));
    if (self()) self()->done_search(*d);
  }
  void done_search(const SearchDone& d) {
    m.searching = false;
    m.results = d.list;
    m.rsel = 0;
    m.rscroll = 0;
    m.results_title = d.err.empty() ? rd::fmt(tx::RESULTS_TITLE, {d.title, std::to_string(d.list.size()), std::to_string(m.sel + 1)})
                                    : d.err;
    if (!d.err.empty()) say(d.err);
    refresh();
  }

  // ---- grabar la emisora del canal elegido (curl la guarda tal cual llega)
  void toggle_rec() {
    if (m.rec) {
      stop_rec();
      say(rd::fmt(tx::REC_SAVED, {rec_file}), 8);
      refresh();
      return;
    }
    const rd::Channel& c = m.ch[m.sel];
    if (c.st.empty()) {
      say(tx::EMPTY_HINT);
      return;
    }
    std::string dir = rd::rec_dir();
    rec_file = dir + "/" + rd::rec_name(c.st, std::time(nullptr));
    if (live) {
      fl_make_path(dir.c_str());
      rec_proc = rd::spawn({"curl", "-s", "-L", "-A", "DMarlonStudio-Radio/1.0", "-o", rec_file, c.st.url});
      if (!rec_proc.running()) {
        say(tx::REC_FAILED);
        return;
      }
    }
    m.rec = true;
    m.rec_ch = m.sel;
    m.rec_since = rd::now_t();
    refresh();
  }
  void stop_rec() {
    if (m.rec && live) rd::stop(rec_proc);
    m.rec = false;
  }

  // ---- lo que pasa en la mesa
  void act(int a, int b) {
    switch (a) {
      case rd::H_REC: toggle_rec(); break;
      case rd::H_TAB: m.tab = b; refresh(); break;
      case rd::H_ROW:
      case rd::H_CHPAD: m.sel = b; refresh(); break;
      case rd::H_RESULT:
        if (b == m.rsel && b >= 0 && b < (int)m.results.size()) load_station(m.sel, m.results[(size_t)b]);
        else { m.rsel = b; refresh(); }
        break;
      case rd::H_DIAL:
        if (m.tab == 1 && m.rsel >= 0 && m.rsel < (int)m.results.size()) load_station(m.sel, m.results[(size_t)m.rsel]);
        else { m.tab = 1; refresh(); }
        break;
      case rd::H_PAD: search(rd::genres()[b].tag, "", b); break;
      case rd::H_BANK: m.bank = m.bank == 0 ? 1 : 0; save(); refresh(); break;
      case rd::H_PLAY: m.sel = b; toggle_play(b); break;
      case rd::H_MUTE: m.ch[b].muted = !m.ch[b].muted; save(); refresh(); break;
    }
  }
  void value(int a, int b, double v) {
    if (a == rd::H_FADER) {
      m.ch[b].vol = v;
      m.sel = b;
    } else if (a == rd::H_KNOB) {
      if (b == 0) m.master = v;
      else if (b == 1) m.fade = (int)std::lround(v * 10);
      else {
        int mins = (int)std::lround(v * 24) * 5;
        if (mins != m.sleep_min) {
          m.sleep_min = mins;
          m.sleep_at = mins > 0 ? rd::now_t() + mins * 60 : 0;
        }
      }
    } else if (a == rd::H_DIAL) {
      if (m.results.empty()) return;
      m.tab = 1;
      m.rsel = std::max(0, std::min((int)m.results.size() - 1, (int)std::lround(v)));
    } else if (a == rd::H_RESULT) {
      m.rscroll = std::max(0, m.rscroll + (int)v);
    }
    refresh();
  }

  // ---- el reloj (cada 100 ms): los fundidos, los estados y lo que suena
  void step(double dt) {
    double rate = m.fade > 0 ? dt / m.fade : 1.0;
    for (int i = 0; i < rd::CH_N; i++) {
      double t = rd::target_gain(m, i);
      double& g = m.gain[i];
      g = g < t ? std::min(t, g + rate) : std::max(t, g - rate);
      if (live) {
        players[i]->volume(g);
        players[i]->tick();
      }
    }
    for (auto it = dying.begin(); it != dying.end();) {
      it->second -= rate;
      if (it->second <= 0) {
        it->first->close();
        it = dying.erase(it);
      } else {
        it->first->volume(it->second);
        ++it;
      }
    }
  }
  void Tick_timer() override {
    double now = rd::now_s();
    step(last_tick > 0 ? std::min(0.5, now - last_tick) : 0.1);
    last_tick = now;
    desk->blink = now;
    for (int i = 0; i < rd::CH_N; i++)
      m.ch[i].state = m.ch[i].playing ? (live ? players[i]->state() : rd::PS_PLAYING) : rd::PS_OFF;
    // El apagado automático.
    if (m.sleep_min > 0 && m.sleep_at > 0 && rd::now_t() >= m.sleep_at) {
      m.sleep_min = 0;
      m.sleep_at = 0;
      stop_all();
      say(tx::SLEPT, 10);
    }
    // La grabación, si curl ha terminado sola.
    if (m.rec && live && !rd::alive(rec_proc)) {
      m.rec = false;
      say(rd::fmt(tx::REC_STOPPED, {rec_file}), 8);
    }
    if (live && now >= next_icy) {
      next_icy = now + 20;
      for (int i = 0; i < rd::CH_N; i++)
        if (m.ch[i].playing && !m.ch[i].st.empty() && icy_busy < 3) {
          icy_busy++;
          std::string url = m.ch[i].st.url;
          std::thread([url] {
            auto* d = new IcyDone{url, rd::now_playing(url).title};
            Fl::awake(icy_done, d);
          }).detach();
        }
    }
    refresh();
  }
  static void icy_done(void* p) {
    std::unique_ptr<IcyDone> d(static_cast<IcyDone*>(p));
    if (!self()) return;
    self()->icy_busy = std::max(0, self()->icy_busy - 1);
    for (auto& c : self()->m.ch)
      if (c.st.url == d->url && !d->title.empty()) c.title = d->title;
  }

  // ---- eventos del diseño
  void BtnSearch_click() override {
    std::string q = rd::trim(Search->value());
    if (q.empty()) {
      say(tx::TYPE_SOMETHING);
      return;
    }
    search("", q, -1);
  }
  void Search_enter() override { BtnSearch_click(); }
  void Country_select() override {
    if (m.pad >= 0) search(rd::genres()[m.pad].tag, "", m.pad);
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_REC) toggle_rec();
    else if (item == tx::MP_REC_DIR) {
      fl_make_path(rd::rec_dir().c_str());
      fl_open_uri(("file://" + rd::rec_dir()).c_str());
    } else if (item == tx::MP_PLAY) toggle_play(m.sel);
    else if (item == tx::MP_MUTE) act(rd::H_MUTE, m.sel);
    else if (item == tx::MP_CLEAR) clear_channel(m.sel);
    else if (item == tx::MP_STOP_ALL) stop_all();
    else if (item == tx::MP_QUIT) { form_close(); std::exit(0); }
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
  void demo_state() {
    Fl::screen_count();
    live = false;
    setup();
    auto st = rd::demo_stations();
    const char* titles[] = {"Miles Davis - So What", "Bach - Suite para violonchelo n.º 1", "Nujabes - Aruarian Dance", "",
                            "Queen - Bohemian Rhapsody", "Buena Vista Social Club - Chan Chan"};
    double vols[] = {0.82, 0.55, 0.68, 0.4, 0.74, 0.6};
    for (int i = 0; i < rd::CH_N; i++) {
      m.ch[i].st = st[(size_t)i];
      m.ch[i].vol = vols[i];
      m.ch[i].title = titles[i];
      m.ch[i].playing = i != 3;
      m.ch[i].state = m.ch[i].playing ? rd::PS_PLAYING : rd::PS_OFF;
      m.gain[i] = rd::target_gain(m, i);
    }
    m.ch[4].muted = true;
    m.gain[4] = 0;
    m.master = 0.85;
    m.fade = 2;
    m.sleep_min = 45;
    m.sleep_at = rd::now_t() + 45 * 60 - 17;
    m.on_air_since = rd::now_t() - (15 * 60 + 3);
    m.sel = 0;
    m.pad = 3;
    Search->value("");
    for (int i = 0; i < rd::CH_N; i++) m.gain[i] = rd::target_gain(m, i);
    message.clear();
    update_status();
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state();
    render_to(dir + "/window.png");
    // Un pad de género: la lista de emisoras en la pantalla.
    act(rd::H_PAD, 3);
    m.rsel = 2;
    render_to(dir + "/results.png");
    // Grabando el canal 1, con otro banco de pads.
    m.tab = 0;
    m.bank = 1;
    m.pad = 13;
    m.rec = true;
    m.rec_ch = 0;
    m.rec_since = rd::now_t() - 83;
    m.sel = 2;
    render_to(dir + "/rec.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state();
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    render_to("");
    auto click = [&](int act, int arg) {
      for (const auto& h : desk->hits)
        if (h.act == act && h.arg == arg) {
          Fl::e_x = h.x + h.w / 2;
          Fl::e_y = h.y + h.h / 2;
          desk->handle(FL_PUSH);
          desk->handle(FL_RELEASE);
          render_to("");
          return true;
        }
      return false;
    };
    chk(click(rd::H_PAD, 3) && m.tab == 1 && m.results.size() == 10 && m.pad == 3, "pad de jazz");
    chk(click(rd::H_RESULT, 2) && m.rsel == 2, "elegir una emisora");
    chk(click(rd::H_RESULT, 2) && m.ch[0].st.name == rd::demo_stations()[2].name && m.ch[0].playing && m.tab == 0,
        "cargarla en el canal");
    chk(click(rd::H_CHPAD, 3) && m.sel == 3, "elegir el canal 4");
    chk(click(rd::H_PLAY, 3) && m.ch[3].playing, "sonar el canal 4");
    chk(click(rd::H_MUTE, 3) && m.ch[3].muted && rd::target_gain(m, 3) == 0, "silenciar");
    chk(click(rd::H_BANK, 1) && m.bank == 1, "otro banco de pads");
    chk(click(rd::H_TAB, 1) && m.tab == 1, "pestaña de resultados");
    // El fader del canal 2, arrastrado hasta arriba.
    for (const auto& h : desk->hits)
      if (h.act == rd::H_FADER && h.arg == 1) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = desk->fader_top + desk->fader_len / 2;
        desk->handle(FL_PUSH);
        chk(std::fabs(m.ch[1].vol - 0.5) < 0.02, "fader a la mitad");
        Fl::e_y = desk->fader_top - 5;
        desk->handle(FL_DRAG);
        desk->handle(FL_RELEASE);
        chk(m.ch[1].vol == 1.0, "fader arriba del todo");
        break;
      }
    // El mando del volumen general, hacia abajo.
    render_to("");
    for (const auto& h : desk->hits)
      if (h.act == rd::H_KNOB && h.arg == 0) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h / 2;
        desk->handle(FL_PUSH);
        Fl::e_y += 400;
        desk->handle(FL_DRAG);
        desk->handle(FL_RELEASE);
        chk(m.master == 0, "volumen general a cero");
        break;
      }
    // El fundido: con 2 s, medio segundo sube un cuarto.
    m.master = 1;
    m.fade = 2;
    m.ch[5].vol = 1;
    m.ch[5].muted = false;
    m.ch[5].playing = true;
    m.gain[5] = 0;
    step(0.5);
    chk(std::fabs(m.gain[5] - 0.25) < 1e-9, "fundido de entrada");
    m.fade = 0;
    step(0.1);
    chk(m.gain[5] == 1, "sin fundido");
    // Apagado automático.
    m.sleep_min = 5;
    m.sleep_at = rd::now_t() - 1;
    Tick_timer();
    chk(!m.any_playing() && m.sleep_min == 0, "apagado automático");
    // Grabar sin red (no se lanza curl): el nombre del archivo.
    m.sel = 0;
    toggle_rec();
    chk(m.rec && rec_file.find(rd::safe_name(m.ch[0].st.name)) != std::string::npos, "grabar");
    toggle_rec();
    chk(!m.rec, "parar la grabación");
    std::string t = rd::model_text(m);
    rd::Model b;
    chk(rd::parse_model(t, b) && b.ch[0].st.name == m.ch[0].st.name, "guardado");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
