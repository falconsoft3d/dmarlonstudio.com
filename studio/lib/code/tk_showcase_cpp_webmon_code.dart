part of 'tk_examples.dart';

// El código en C++ del monitor de sitios web (tk_showcase_cpp_webmon.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _webmonIncludes = r'''#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
#include <cmath>
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
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _webmonCode = r'''
// ============================================================ los datos
// Los sitios que se vigilan, con el historial de sus comprobaciones. Cada
// comprobación es una petición GET con curl (la traen macOS y Windows 10 y
// posteriores): el código HTTP y lo que tardó en contestar.
namespace um {

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
bool has(const std::string& s, const std::string& p) { return s.find(p) != std::string::npos; }
long long now_t() { return (long long)std::time(nullptr); }
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
// Un número decimal sin depender del idioma del sistema («0.123» o «0,123»).
double parse_num(const std::string& s) {
  double v = 0, scale = 0;
  for (char c : s) {
    if (c >= '0' && c <= '9') {
      if (scale > 0) { v += (c - '0') * scale; scale /= 10; }
      else v = v * 10 + (c - '0');
    } else if ((c == '.' || c == ',') && scale == 0) scale = 0.1;
    else break;
  }
  return v;
}
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}
std::string clock_time(long long t) {
  if (t <= 0) return "—";
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
// «5 s», «12 min», «3 h», «2 d».
std::string span(long long s) {
  if (s < 0) s = 0;
  if (s < 60) return fmt(tx::SPAN_S, {std::to_string(s)});
  if (s < 3600) return fmt(tx::SPAN_MIN, {std::to_string(s / 60)});
  if (s < 86400) return fmt(tx::SPAN_H, {std::to_string(s / 3600)});
  return fmt(tx::SPAN_D, {std::to_string(s / 86400)});
}
std::string countdown(long long s) {
  if (s < 0) s = 0;
  char b[32];
  std::snprintf(b, sizeof b, "%lld:%02lld", s / 60, s % 60);
  return b;
}

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_WEBMON_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\webmon";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/webmon";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/webmon";
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

// ------------------------------------------------------------ direcciones
// Lo que escribe el usuario → una dirección que se puede comprobar
// («ejemplo.com» → «https://ejemplo.com»); "" si no vale.
std::string normalize_url(std::string s) {
  s = trim(s);
  if (s.empty() || s.size() > 2000) return "";
  for (char c : s)
    if ((unsigned char)c <= ' ' || c == '"' || c == '\\' || c == '\'' || c == '`' || c == '<' || c == '>') return "";
  std::string l = lower(s);
  if (!starts(l, "http://") && !starts(l, "https://")) {
    if (has(s, "://")) return "";
    s = "https://" + s;
  }
  size_t p = s.find("://") + 3;
  size_t e = s.find_first_of("/?#", p);
  std::string host = lower(s.substr(p, e == std::string::npos ? std::string::npos : e - p));
  size_t colon = host.rfind(':');
  if (colon != std::string::npos && host.find(']') == std::string::npos) host = host.substr(0, colon);
  if (host.empty()) return "";
  if (!has(host, ".") && host != "localhost" && !starts(host, "[")) return "";
  return s;
}
// El nombre por defecto: el servidor sin «www.».
std::string host_of(const std::string& url) {
  size_t p = url.find("://");
  std::string h = p == std::string::npos ? url : url.substr(p + 3);
  size_t e = h.find_first_of("/?#");
  if (e != std::string::npos) h = h.substr(0, e);
  if (starts(lower(h), "www.")) h = h.substr(4);
  return h;
}

// ------------------------------------------------------------ el escáner de puertos
// Los puertos habituales de un servidor: se prueba a abrir una conexión TCP
// a todos a la vez, con un tiempo máximo. Solo para servidores propios o con
// permiso. [risky]: no conviene tenerlo abierto a internet.
struct PortInfo {
  int port;
  const char* name;
  bool risky;
};
const PortInfo PORTS[] = {
    {21, "FTP", true},         {22, "SSH", false},           {23, "Telnet", true},
    {25, "SMTP", false},       {53, "DNS", false},           {80, "HTTP", false},
    {110, "POP3", false},      {143, "IMAP", false},         {443, "HTTPS", false},
    {445, "SMB", true},        {465, "SMTPS", false},        {587, "Submission", false},
    {993, "IMAPS", false},     {995, "POP3S", false},        {1433, "SQL Server", true},
    {1521, "Oracle", true},    {2049, "NFS", true},          {2375, "Docker", true},
    {3000, "HTTP 3000", false}, {3306, "MySQL", true},       {3389, "RDP", true},
    {5432, "PostgreSQL", true}, {5672, "RabbitMQ", true},    {5900, "VNC", true},
    {6379, "Redis", true},     {8000, "HTTP 8000", false},   {8069, "Odoo", false},
    {8072, "Odoo longpolling", false}, {8080, "HTTP 8080", false}, {8443, "HTTPS 8443", false},
    {9200, "Elasticsearch", true}, {11211, "Memcached", true}, {27017, "MongoDB", true},
};
const int PORT_N = (int)(sizeof PORTS / sizeof PORTS[0]);
const PortInfo* port_info(int port) {
  for (const auto& p : PORTS)
    if (p.port == port) return &p;
  return nullptr;
}

struct ScanResult {
  std::string host, ip, error;
  std::vector<int> open;   // los abiertos, en orden
  long long t = 0;
  int tried = 0;
};

// El servidor de una dirección: «https://www.x.com:8443/a» → «www.x.com».
std::string server_of(const std::string& url) {
  size_t p = url.find("://");
  std::string h = p == std::string::npos ? url : url.substr(p + 3);
  size_t e = h.find_first_of("/?#");
  if (e != std::string::npos) h = h.substr(0, e);
  size_t at = h.find('@');
  if (at != std::string::npos) h = h.substr(at + 1);
  if (!h.empty() && h[0] == '[') {
    size_t b = h.find(']');
    return b == std::string::npos ? h : h.substr(1, b - 1);
  }
  size_t c = h.rfind(':');
  return c == std::string::npos ? h : h.substr(0, c);
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
void set_nonblock(sock_t s) {
  u_long nb = 1;
  ioctlsocket(s, FIONBIO, &nb);
}
#else
typedef int sock_t;
const sock_t BAD_SOCK = -1;
void sock_close(sock_t s) { close(s); }
void net_init() {}
void set_nonblock(sock_t s) { fcntl(s, F_SETFL, fcntl(s, F_GETFL, 0) | O_NONBLOCK); }
#endif

// Prueba [ports] de [host] a la vez (en el hilo que la llama).
ScanResult scan_ports(const std::string& host, const std::vector<int>& ports, int timeout_ms) {
  ScanResult r;
  r.host = host;
  r.t = now_t();
  net_init();
  addrinfo hints{}, *res = nullptr;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  if (getaddrinfo(host.c_str(), nullptr, &hints, &res) != 0 || !res) {
    r.error = tx::ERR_NO_HOST;
    return r;
  }
  // Mejor IPv4 si lo hay.
  addrinfo* pick = res;
  for (addrinfo* a = res; a; a = a->ai_next)
    if (a->ai_family == AF_INET) { pick = a; break; }
  sockaddr_storage base{};
  std::memcpy(&base, pick->ai_addr, pick->ai_addrlen);
  socklen_t len = (socklen_t)pick->ai_addrlen;
  int family = pick->ai_family;
  char ipbuf[INET6_ADDRSTRLEN] = "";
  if (family == AF_INET) inet_ntop(AF_INET, &((sockaddr_in*)&base)->sin_addr, ipbuf, sizeof ipbuf);
  else inet_ntop(AF_INET6, &((sockaddr_in6*)&base)->sin6_addr, ipbuf, sizeof ipbuf);
  r.ip = ipbuf;
  freeaddrinfo(res);
  struct Try {
    int port;
    sock_t s;
  };
  std::vector<Try> pending;
  for (int port : ports) {
    sockaddr_storage a = base;
    if (family == AF_INET) ((sockaddr_in*)&a)->sin_port = htons((unsigned short)port);
    else ((sockaddr_in6*)&a)->sin6_port = htons((unsigned short)port);
    sock_t s = socket(family, SOCK_STREAM, 0);
    if (s == BAD_SOCK) continue;
    set_nonblock(s);
    r.tried++;
    if (connect(s, (sockaddr*)&a, len) == 0) {
      r.open.push_back(port);
      sock_close(s);
      continue;
    }
    pending.push_back({port, s});
  }
  double end = now_s() + timeout_ms / 1000.0;
  while (!pending.empty() && now_s() < end) {
    fd_set w, x;
    FD_ZERO(&w);
    FD_ZERO(&x);
    sock_t top = 0;
    for (const auto& p : pending) {
      FD_SET(p.s, &w);
      FD_SET(p.s, &x);
      if (p.s > top) top = p.s;
    }
    double left = end - now_s();
    timeval tv{(long)left, (int)((left - (long)left) * 1e6)};
    if (select((int)top + 1, nullptr, &w, &x, &tv) <= 0) break;
    std::vector<Try> still;
    for (const auto& p : pending) {
      if (FD_ISSET(p.s, &w) || FD_ISSET(p.s, &x)) {
        int err = 0;
        socklen_t el = sizeof err;
        getsockopt(p.s, SOL_SOCKET, SO_ERROR, (char*)&err, &el);
        if (err == 0 && FD_ISSET(p.s, &w)) r.open.push_back(p.port);
        sock_close(p.s);
      } else {
        still.push_back(p);
      }
    }
    pending.swap(still);
  }
  for (const auto& p : pending) sock_close(p.s);
  std::sort(r.open.begin(), r.open.end());
  return r;
}
std::vector<int> common_ports() {
  std::vector<int> v;
  for (const auto& p : PORTS) v.push_back(p.port);
  return v;
}
// «22, 80, 443» (o «ninguno»).
std::string open_list(const ScanResult& r) {
  if (r.open.empty()) return tx::NO_OPEN_PORTS;
  std::string o;
  for (int p : r.open) o += (o.empty() ? "" : ", ") + std::to_string(p);
  return o;
}
int risky_count(const ScanResult& r) {
  int n = 0;
  for (int p : r.open) {
    const PortInfo* i = port_info(p);
    if (i && i->risky) n++;
  }
  return n;
}

// ------------------------------------------------------------ los sitios
struct Check {
  long long t = 0;
  int code = 0;   // 0: no contestó
  int ms = 0;
};
inline bool is_up(int code) { return code >= 200 && code < 400; }
enum State { ST_UNKNOWN, ST_UP, ST_SLOW, ST_DOWN, ST_PAUSED };
const int SLOW_MS = 2000;
const size_t KEEP = 500;   // las últimas comprobaciones de cada sitio
const int EVERY[] = {1, 2, 5, 10, 15, 30};
const int EVERY_N = 6;

struct Site {
  std::string name, url, error;
  bool paused = false, checking = false;
  long long added = 0, changed = 0;   // desde cuándo está como está
  std::vector<Check> history;
  ScanResult scan;            // el último escaneo de puertos
  bool scanning = false, show_ports = false;

  const Check* last() const { return history.empty() ? nullptr : &history.back(); }
  State state() const {
    if (paused) return ST_PAUSED;
    const Check* c = last();
    if (!c) return ST_UNKNOWN;
    if (!is_up(c->code)) return ST_DOWN;
    return c->ms > SLOW_MS ? ST_SLOW : ST_UP;
  }
  double uptime() const {
    if (history.empty()) return -1;
    int u = 0;
    for (const auto& c : history)
      if (is_up(c.code)) u++;
    return 100.0 * u / (double)history.size();
  }
  // Añade una comprobación; devuelve true si cambió de en línea a caído o al revés.
  bool add(const Check& c) {
    bool first = history.empty();
    bool was = !first && is_up(history.back().code);
    bool now = is_up(c.code);
    if (first || was != now) changed = c.t;
    history.push_back(c);
    if (history.size() > KEEP) history.erase(history.begin(), history.begin() + (long)(history.size() - KEEP));
    return !first && was != now;
  }
};

std::string clean(std::string s) {
  for (auto& c : s)
    if (c == '\t' || c == '\n' || c == '\r') c = ' ';
  return trim(s);
}

// Una línea por sitio: nombre, dirección, pausado, alta, cambio y el
// historial («t:código:ms» separados por comas). La primera, el intervalo.
std::string serialize(const std::vector<Site>& sites, int every) {
  std::string o = "every\t" + std::to_string(every) + "\n";
  for (const auto& s : sites) {
    o += clean(s.name) + "\t" + s.url + "\t" + (s.paused ? "1" : "0") + "\t" + std::to_string(s.added) + "\t" +
         std::to_string(s.changed) + "\t";
    for (size_t i = 0; i < s.history.size(); i++) {
      if (i) o += ",";
      const Check& c = s.history[i];
      o += std::to_string(c.t) + ":" + std::to_string(c.code) + ":" + std::to_string(c.ms);
    }
    o += "\n";
  }
  return o;
}
std::vector<Site> parse(const std::string& text, int& every) {
  std::vector<Site> out;
  for (const auto& line : split(text, '\n')) {
    auto f = split(line, '\t');
    if (f.size() == 2 && f[0] == "every") {
      int v = std::atoi(f[1].c_str());
      for (int k = 0; k < EVERY_N; k++)
        if (EVERY[k] == v) every = v;
      continue;
    }
    if (f.size() < 6 || normalize_url(f[1]).empty()) continue;
    Site s;
    s.name = f[0];
    s.url = f[1];
    s.paused = f[2] == "1";
    s.added = std::atoll(f[3].c_str());
    s.changed = std::atoll(f[4].c_str());
    for (const auto& h : split(f[5], ',')) {
      auto p = split(h, ':');
      if (p.size() != 3) continue;
      Check c;
      c.t = std::atoll(p[0].c_str());
      c.code = std::atoi(p[1].c_str());
      c.ms = std::atoi(p[2].c_str());
      if (c.t > 0) s.history.push_back(c);
    }
    out.push_back(s);
  }
  return out;
}

// ------------------------------------------------------------ comprobar (curl)
struct Probe {
  int code = 0, ms = 0;
  std::string error;
};

std::string curl_quote(const std::string& s) {
  std::string o = "\"";
  for (char c : s) {
    if (c == '"' || c == '\\') o += '\\';
    if (c == '\n' || c == '\r') continue;
    o += c;
  }
  return o + "\"";
}
std::string curl_config(const std::string& url) {
  std::string c = "url = " + curl_quote(url) + "\n";
  c += "silent\nshow-error\nlocation\nmax-time = 20\nconnect-timeout = 10\n";
#ifdef _WIN32
  c += "output = \"NUL\"\n";
#else
  c += "output = \"/dev/null\"\n";
#endif
  c += "user-agent = \"DMarlonStudio-WebMonitor/1.0\"\n";
  c += "write-out = \"\\n%{http_code} %{time_total}\"\n";
  return c;
}

// Lo que dijo curl: sus errores y, en la última línea, «código segundos».
Probe parse_probe(const std::string& out, int exit_code) {
  Probe p;
  std::string o = trim(out);
  size_t nl = o.find_last_of('\n');
  std::string last = trim(nl == std::string::npos ? o : o.substr(nl + 1));
  std::string before = nl == std::string::npos ? "" : trim(o.substr(0, nl));
  auto parts = split(last, ' ');
  if (parts.size() >= 2 && !parts[0].empty() && std::isdigit((unsigned char)parts[0][0])) {
    p.code = std::atoi(parts[0].c_str());
    p.ms = (int)std::lround(parse_num(parts[1]) * 1000);
  }
  if (p.code == 0) {
    if (exit_code < 0) p.error = tx::ERR_NO_CURL;
    else if (before.empty()) p.error = tx::ERR_NO_ANSWER;
    else {
      // «curl: (6) Could not resolve host: x» → «Could not resolve host: x»
      std::string e = before.substr(before.find_last_of('\n') == std::string::npos ? 0 : before.find_last_of('\n') + 1);
      size_t k = e.find(") ");
      if (starts(e, "curl:") && k != std::string::npos) e = e.substr(k + 2);
      p.error = e;
    }
  }
  return p;
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

// Comprueba [url] (en el hilo que la llama).
Probe probe(const std::string& url) {
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = dir + "/check-" + std::to_string((long long)(now_s() * 1000)) + "-" + std::to_string(counter++) + ".cfg";
  Probe p;
  if (!write_file(path, curl_config(url))) {
    p.error = tx::ERR_NO_ANSWER;
    return p;
  }
  std::string out;
  int code = run_capture(path, out);
  std::remove(path.c_str());
  return parse_probe(out, code);
}

// Un aviso del sistema cuando un sitio se cae o vuelve (en macOS).
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

// ------------------------------------------------------------ el menú de la barra
// El menú del icono, como datos (el de macOS se hace con ellos y la prueba
// los mira): una opción por sitio con su submenú y las órdenes.
struct MenuEntry {
  std::string title;
  int tag = 0;           // la acción (0: solo texto)
  bool enabled = true, checked = false, sep = false;
  int dot = -1;          // el estado (el punto de color)
  std::vector<MenuEntry> sub;
};
enum Act { A_OPEN = 1, A_CHECK = 2, A_PAUSE = 3, A_SHOW = 4, A_SCAN = 5, A_CHECK_ALL = 100, A_WINDOW = 101, A_TO_BAR = 102,
           A_QUIT = 103, A_EVERY = 110 };
inline int tag(int act, int site) { return act * 1000 + site; }

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

int count_up(const std::vector<Site>& s) {
  int n = 0;
  for (const auto& x : s)
    if (x.state() == ST_UP || x.state() == ST_SLOW) n++;
  return n;
}
int count_down(const std::vector<Site>& s) {
  int n = 0;
  for (const auto& x : s)
    if (x.state() == ST_DOWN) n++;
  return n;
}

std::string answer_text(const Site& s) {
  if (s.paused) return tx::PAUSED;
  const Check* c = s.last();
  if (!c) return s.checking ? tx::CHECKING : tx::NOT_YET;
  if (c->code == 0) return s.error.empty() ? tx::ERR_NO_ANSWER : s.error;
  return std::to_string(c->code) + " · " + fmt(tx::MS, {std::to_string(c->ms)});
}

std::vector<MenuEntry> bar_menu(const std::vector<Site>& sites, int every, long long next_in, bool window_shown) {
  std::vector<MenuEntry> m;
  int up = count_up(sites), down = count_down(sites);
  if (sites.empty()) m.push_back(text_entry(tx::NO_SITES));
  else m.push_back(text_entry(fmt(down ? tx::HEAD_DOWN : tx::HEAD, {std::to_string(sites.size()), std::to_string(up), std::to_string(down)})));
  m.push_back(text_entry(fmt(tx::NEXT_CHECK, {countdown(next_in)})));
  if (!sites.empty()) m.push_back(sep_entry());
  for (size_t i = 0; i < sites.size(); i++) {
    const Site& s = sites[i];
    int k = (int)i;
    MenuEntry e;
    e.title = s.name + "   " + answer_text(s);
    e.dot = s.state();
    e.sub.push_back(act_entry(fmt(tx::OPEN, {s.url}), tag(A_OPEN, k)));
    e.sub.push_back(act_entry(tx::CHECK_NOW, tag(A_CHECK, k)));
    e.sub.push_back(act_entry(s.paused ? tx::RESUME : tx::PAUSE, tag(A_PAUSE, k)));
    e.sub.push_back(sep_entry());
    double u = s.uptime();
    e.sub.push_back(text_entry(fmt(tx::UPTIME, {u < 0 ? "—" : num(u, 1)})));
    if (s.last()) {
      bool on = is_up(s.last()->code);
      e.sub.push_back(text_entry(fmt(on ? tx::UP_SINCE : tx::DOWN_SINCE, {span(now_t() - s.changed)})));
      e.sub.push_back(text_entry(fmt(tx::LAST_CHECK, {clock_time(s.last()->t)})));
    }
    e.sub.push_back(sep_entry());
    e.sub.push_back(act_entry(s.scanning ? tx::SCANNING : tx::SCAN_PORTS, s.scanning ? 0 : tag(A_SCAN, k)));
    if (s.scan.t) e.sub.push_back(text_entry(fmt(tx::OPEN_PORTS, {open_list(s.scan)})));
    e.sub.push_back(act_entry(tx::SHOW_IN_WINDOW, tag(A_SHOW, k)));
    m.push_back(e);
  }
  m.push_back(sep_entry());
  m.push_back(act_entry(tx::CHECK_ALL, tag(A_CHECK_ALL, 0)));
  MenuEntry ev;
  ev.title = tx::EVERY_MENU;
  for (int k = 0; k < EVERY_N; k++) {
    MenuEntry x = act_entry(fmt(tx::EVERY_ITEM, {std::to_string(EVERY[k])}), tag(A_EVERY + k, 0));
    x.checked = EVERY[k] == every;
    ev.sub.push_back(x);
  }
  m.push_back(ev);
  m.push_back(sep_entry());
  m.push_back(window_shown ? act_entry(tx::TO_BAR, tag(A_TO_BAR, 0)) : act_entry(tx::OPEN_WINDOW, tag(A_WINDOW, 0)));
  m.push_back(act_entry(tx::QUIT, tag(A_QUIT, 0)));
  return m;
}

// ------------------------------------------------------------ colores y dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
Fl_Color state_color(int st) {
  switch (st) {
    case ST_UP: return rgb(0x16a34a);
    case ST_SLOW: return rgb(0xf59e0b);
    case ST_DOWN: return rgb(0xdc2626);
    default: return rgb(0x9ca3af);
  }
}
const char* state_emoji(int st) {
  switch (st) {
    case ST_UP: return "🟢";
    case ST_SLOW: return "🟡";
    case ST_DOWN: return "🔴";
    case ST_PAUSED: return "⏸";
    default: return "⚪";
  }
}
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(fill);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(line);
  fl_rounded_rect(x, y, w, h, r);
}
void dot(int cx, int cy, int r, Fl_Color c) {
  fl_color(c);
  fl_pie(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
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

// ------------------------------------------------------------ la lista
// Los sitios en tarjetas: estado, respuesta, disponibilidad, el historial
// en barras y los botones Abrir, Pausar y Quitar.
struct Hit {
  int x, y, w, h, act, site;
};

class SitesView : public Fl_Widget {
public:
  std::vector<Site>* sites = nullptr;
  int scroll = 0, hover = -1, content_h = 0, selected = -1;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;

  SitesView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int hit_at(int mx, int my) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (mx >= h.x && mx < h.x + h.w && my >= h.y && my < h.y + h.h) return i;
    }
    return -1;
  }

  int button(int right, int cy, const char* text, int act, int site, Fl_Color fg) {
    fl_font(FL_HELVETICA_BOLD, 12);
    int w = (int)fl_width(text) + 22, h = 26;
    int x = right - w, y = cy - h / 2;
    bool hot = (int)hits.size() == hover;
    hits.push_back({x, y, w, h, act, site});
    round_box(x, y, w, h, 7, hot ? rgb(0xeef2f8) : FL_WHITE, rgb(0xd5dae2));
    fl_color(fg);
    fl_draw(text, x + 11, cy + 4);
    return x;
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0xf4f6f9));
    fl_rectf(x(), y(), w(), h());
    int X = x() + 16, W = w() - 32, Y = y() + 12 - scroll;
    if (!sites || sites->empty()) {
      fl_font(FL_HELVETICA_BOLD, 17);
      fl_color(rgb(0x1f2937));
      fl_draw(tx::EMPTY_TITLE, X, Y + 50, W, 24, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(0x6b7280));
      fl_draw(tx::EMPTY_HELP, X, Y + 78, W, 40, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      content_h = 140;
      fl_pop_clip();
      return;
    }
    // Las columnas.
    int cName = X + 44, cAns = X + (int)(W * 0.36), cUp = X + (int)(W * 0.52), cHist = X + (int)(W * 0.64);
    int hw = std::max(60, (int)(W * 0.16));
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_color(rgb(0x6b7280));
    fl_draw(tx::COL_SITE, cName, Y + 12);
    fl_draw(tx::COL_ANSWER, cAns, Y + 12);
    fl_draw(tx::COL_UPTIME, cUp, Y + 12);
    fl_draw(tx::COL_HISTORY, cHist, Y + 12);
    Y += 24;
    long long now = now_t();
    for (size_t i = 0; i < sites->size(); i++) {
      const Site& s = (*sites)[i];
      int k = (int)i, rh = 66, cy = Y + rh / 2, ph = s.show_ports ? 104 : 0;
      round_box(X, Y, W, rh + ph, 12, k == selected ? rgb(0xeef4ff) : FL_WHITE, k == selected ? rgb(0x93b4f5) : rgb(0xe3e7ee));
      // La tarjeta va primero: los botones, encima, ganan el clic (hit_at
      // busca de la última zona a la primera).
      hits.push_back({X, Y, W, rh + ph, 0, k});
      dot(X + 22, cy, 7, state_color(s.state()));
      if (s.checking) {
        fl_color(FL_WHITE);
        fl_pie(X + 19, cy - 3, 6, 6, 0, 360);
      }
      // A la derecha, los botones (y lo demás se ajusta a lo que queda).
      int right = X + W - 12;
      right = button(right, cy, tx::REMOVE, 3, k, rgb(0xdc2626)) - 6;
      right = button(right, cy, s.paused ? tx::RESUME : tx::PAUSE, 2, k, rgb(0x1f2937)) - 6;
      right = button(right, cy, tx::PORTS, 4, k, s.show_ports ? rgb(0x7c3aed) : rgb(0x1f2937)) - 6;
      right = button(right, cy, tx::OPEN_SHORT, 1, k, rgb(0x1d4ed8)) - 12;
      fl_font(FL_HELVETICA_BOLD, 15);
      fl_color(rgb(0x1f2937));
      fl_draw(fit(s.name, cAns - cName - 12).c_str(), cName, Y + 26);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(0x6b7280));
      fl_draw(fit(s.url, cAns - cName - 12).c_str(), cName, Y + 46);
      // La respuesta.
      const Check* c = s.last();
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(s.state() == ST_DOWN ? rgb(0xdc2626) : rgb(0x1f2937));
      std::string a = c && c->code ? std::to_string(c->code) : answer_text(s);
      fl_draw(fit(a, cUp - cAns - 10).c_str(), cAns, Y + 26);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(0x6b7280));
      if (c && c->code) fl_draw(fmt(tx::MS, {std::to_string(c->ms)}).c_str(), cAns, Y + 46);
      else if (c) fl_draw(fit(s.error.empty() ? tx::ERR_NO_ANSWER : s.error, cUp - cAns - 10).c_str(), cAns, Y + 46);
      // La disponibilidad y desde cuándo.
      double u = s.uptime();
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(rgb(0x1f2937));
      fl_draw(u < 0 ? "—" : (num(u, 1) + " %").c_str(), cUp, Y + 26);
      if (c) {
        fl_font(FL_HELVETICA, 12);
        fl_color(rgb(0x6b7280));
        std::string since = fmt(is_up(c->code) ? tx::UP_SINCE_SHORT : tx::DOWN_SINCE_SHORT, {span(now - s.changed)});
        fl_draw(fit(since, cHist - cUp - 10).c_str(), cUp, Y + 46);
      }
      // El historial: una barra por comprobación (alta = lenta).
      int bw = 4, n = std::min((int)s.history.size(), std::max(1, std::min(hw, right - cHist) / (bw + 1)));
      int bx = cHist, base = Y + rh - 14, top = Y + 14;
      for (int j = (int)s.history.size() - n; j < (int)s.history.size(); j++) {
        const Check& h = s.history[(size_t)j];
        int st = !is_up(h.code) ? ST_DOWN : h.ms > SLOW_MS ? ST_SLOW : ST_UP;
        int bh = !is_up(h.code) ? base - top : std::max(4, (int)((base - top) * std::min(1.0, h.ms / 3000.0)));
        fl_color(state_color(st));
        fl_rectf(bx, base - bh, bw, bh);
        bx += bw + 1;
      }
      if (s.history.empty()) {
        fl_font(FL_HELVETICA, 12);
        fl_color(rgb(0x9ca3af));
        fl_draw(s.paused ? tx::PAUSED : tx::NOT_YET, cHist, Y + 37);
      }
      if (s.show_ports) draw_ports(s, k, X + 16, Y + rh, W - 32);
      Y += rh + ph + 8;
    }
    content_h = Y + scroll - y() + 8;
    fl_pop_clip();
  }

  // Los puertos de un sitio, bajo su fila: los abiertos en etiquetas (en
  // ámbar los que no conviene abrir a internet) y volver a escanear.
  void draw_ports(const Site& s, int k, int X, int Y, int W) {
    fl_color(rgb(0xe3e7ee));
    fl_line(X, Y, X + W, Y);
    fl_font(FL_HELVETICA_BOLD, 12);
    fl_color(rgb(0x1f2937));
    std::string head;
    if (s.scanning) head = fmt(tx::SCANNING_HOST, {std::to_string(PORT_N), server_of(s.url)});
    else if (!s.scan.error.empty()) head = s.scan.host + " · " + s.scan.error;
    else if (s.scan.t)
      head = fmt(tx::SCAN_HEAD, {s.scan.host, s.scan.ip, std::to_string(s.scan.open.size()), std::to_string(s.scan.tried),
                                  clock_time(s.scan.t)});
    fl_draw(fit(head, W - 160).c_str(), X, Y + 22);
    if (!s.scanning) button(X + W, Y + 16, tx::RESCAN_PORTS, 5, k, rgb(0x1d4ed8));
    int x = X, y = Y + 36;
    if (!s.scanning && s.scan.t && s.scan.error.empty()) {
      if (s.scan.open.empty()) {
        fl_font(FL_HELVETICA, 12);
        fl_color(rgb(0x6b7280));
        fl_draw(tx::NO_OPEN_PORTS, x, y + 18);
      }
      for (int p : s.scan.open) {
        const PortInfo* pi = port_info(p);
        std::string t = std::to_string(p) + "  " + (pi ? pi->name : "");
        fl_font(FL_HELVETICA_BOLD, 12);
        int w = (int)fl_width(t.c_str()) + 20;
        if (x + w > X + W) break;
        bool risky = pi && pi->risky;
        round_box(x, y, w, 26, 13, risky ? rgb(0xfff4e0) : rgb(0xe8f7ee), risky ? rgb(0xf5b84a) : rgb(0x8fd4a8));
        fl_color(risky ? rgb(0x9a5b00) : rgb(0x166534));
        fl_draw(t.c_str(), x, y, w, 26, FL_ALIGN_CENTER);
        x += w + 8;
      }
    }
    fl_font(FL_HELVETICA, 11);
    fl_color(rgb(0x6b7280));
    std::string note = risky_count(s.scan) ? fmt(tx::RISKY_NOTE, {std::to_string(risky_count(s.scan))}) : tx::SCAN_NOTE;
    fl_draw(fit(note, W).c_str(), X, Y + 88);
  }

  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i >= 0 && hits[(size_t)i].act == 0) i = -1;
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
        if (i >= 0 && on_act) on_act(hits[(size_t)i].act, hits[(size_t)i].site);
        return 1;
      }
      case FL_MOUSEWHEEL:
        scroll = std::max(0, std::min(scroll + Fl::event_dy() * 30, std::max(0, content_h - h())));
        hover = -1;
        redraw();
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ------------------------------------------------------------ las pruebas
std::vector<Site> demo_sites(long long now) {
  struct D {
    const char* name;
    const char* url;
    int code, ms, flaky;
    bool paused;
  };
  const D ds[] = {
      {tx::DEMO_SHOP, "https://tienda.example.com", 200, 180, 0, false},
      {tx::DEMO_API, "https://api.example.com/health", 200, 95, 1, false},
      {tx::DEMO_CLIENTS, "https://clientes.example.com", 503, 0, 3, false},
      {tx::DEMO_BLOG, "https://blog.example.com", 200, 2600, 0, false},
      {"Odoo", "https://erp.example.com/web/login", 200, 420, 2, false},
      {tx::DEMO_DOCS, "https://docs.example.com", 200, 140, 0, true},
  };
  std::vector<Site> out;
  unsigned seed = 7;
  for (const auto& d : ds) {
    Site s;
    s.name = d.name;
    s.url = d.url;
    s.added = now - 86400;
    for (int i = 60; i >= 1; i--) {
      seed = seed * 1103515245u + 12345u;
      Check c;
      c.t = now - i * 120;
      bool fail = d.flaky > 0 && (seed >> 16) % 23 < (unsigned)d.flaky;
      if (d.code >= 500 && i <= 3) fail = true;
      c.code = fail ? (d.code >= 500 ? 503 : 0) : 200;
      c.ms = fail ? (d.code >= 500 ? 80 + (int)((seed >> 8) % 40) : 0) : std::max(30, d.ms + (int)((seed >> 8) % 120) - 60);
      s.add(c);
    }
    s.paused = d.paused;
    if (s.state() == ST_DOWN) s.error = "";
    out.push_back(s);
  }
  return out;
}

int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  chk(normalize_url("ejemplo.com") == "https://ejemplo.com", "url sin esquema");
  chk(normalize_url(" http://a.b/c?d=1 ") == "http://a.b/c?d=1", "url con ruta");
  chk(normalize_url("localhost:8080") == "https://localhost:8080", "localhost");
  chk(normalize_url("http://localhost:8765/") == "http://localhost:8765/", "localhost con puerto");
  chk(normalize_url("ftp://x.com").empty(), "otro esquema");
  chk(normalize_url("https://a b.com").empty(), "espacios");
  chk(normalize_url("https://x.com/'$(rm)").empty(), "comillas");
  chk(normalize_url("sinpunto").empty(), "sin dominio");
  chk(host_of("https://www.ejemplo.com/a") == "ejemplo.com", "nombre por defecto");
  // curl
  Probe p = parse_probe("\n200 0.123456", 0);
  chk(p.code == 200 && p.ms == 123 && p.error.empty(), "curl ok");
  p = parse_probe("curl: (6) Could not resolve host: nada.example\n000 0.002", 6);
  chk(p.code == 0 && p.error == "Could not resolve host: nada.example", "curl sin respuesta");
  p = parse_probe("", -1);
  chk(p.code == 0 && p.error == tx::ERR_NO_CURL, "sin curl");
  p = parse_probe("\n503 1,5", 0);
  chk(p.code == 503 && p.ms == 1500, "503 con coma");
  chk(curl_config("https://x.com/\"a").find("url = \"https://x.com/\\\"a\"") != std::string::npos, "comillas en curl");
  // Estados y cambios.
  Site s;
  s.url = "https://x.com";
  chk(s.state() == ST_UNKNOWN, "sin comprobar");
  chk(!s.add({1000, 200, 120}) && s.state() == ST_UP && s.changed == 1000, "en línea");
  chk(!s.add({1120, 200, 2500}) && s.state() == ST_SLOW, "lento");
  chk(s.add({1240, 0, 0}) && s.state() == ST_DOWN && s.changed == 1240, "caído (cambio)");
  chk(s.add({1360, 301, 50}) && s.state() == ST_UP, "vuelve (redirección)");
  chk(std::fabs(s.uptime() - 75.0) < 0.01, "disponibilidad");
  s.paused = true;
  chk(s.state() == ST_PAUSED, "pausado");
  for (int i = 0; i < 600; i++) s.add({2000 + i, 200, 10});
  chk(s.history.size() == KEEP, "historial limitado");
  // Guardar y leer.
  std::vector<Site> v = demo_sites(100000);
  int every = 2;
  std::string text = serialize(v, 5);
  std::vector<Site> w = parse(text, every);
  chk(every == 5 && w.size() == v.size(), "leer lo guardado");
  chk(w[2].history.size() == v[2].history.size() && w[2].state() == ST_DOWN && w[5].paused, "historial guardado");
  chk(serialize(w, 5) == text, "ida y vuelta");
  // El menú de la barra.
  auto m = bar_menu(v, 2, 75, true);
  chk(m[0].title == fmt(tx::HEAD_DOWN, {"6", "4", "1"}), "cabecera del menú");
  chk(m[1].title == fmt(tx::NEXT_CHECK, {"1:15"}), "próxima comprobación");
  bool found = false, every_ok = false;
  for (const auto& e : m) {
    if (e.dot == ST_DOWN && !e.sub.empty() && e.sub[0].tag == tag(A_OPEN, 2)) found = true;
    for (const auto& x : e.sub)
      if (x.checked && x.tag == tag(A_EVERY + 1, 0)) every_ok = true;
  }
  chk(found, "el sitio caído con su submenú");
  chk(every_ok, "el intervalo marcado");
  chk(bar_menu(v, 2, 0, false)[bar_menu(v, 2, 0, false).size() - 2].tag == tag(A_WINDOW, 0), "abrir la ventana");
  // El escáner: un puerto que escucha en este equipo y otro que no.
  chk(server_of("https://www.x.com:8443/a") == "www.x.com" && server_of("http://[::1]:80/") == "::1", "servidor");
  chk(port_info(8069) && std::string(port_info(8069)->name) == "Odoo" && port_info(3306)->risky, "puertos conocidos");
  {
    net_init();
    sock_t l = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in a{};
    a.sin_family = AF_INET;
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    a.sin_port = 0;
    bool ok = l != BAD_SOCK && bind(l, (sockaddr*)&a, sizeof a) == 0 && listen(l, 4) == 0;
    socklen_t al = sizeof a;
    getsockname(l, (sockaddr*)&a, &al);
    int open_port = ntohs(a.sin_port);
    // Uno cerrado: otro que se abre y se cierra en el momento.
    sock_t c = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in b{};
    b.sin_family = AF_INET;
    b.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    bind(c, (sockaddr*)&b, sizeof b);
    socklen_t bl = sizeof b;
    getsockname(c, (sockaddr*)&b, &bl);
    int closed_port = ntohs(b.sin_port);
    sock_close(c);
    ScanResult r = scan_ports("127.0.0.1", {open_port, closed_port}, 1500);
    chk(ok && r.error.empty() && r.ip == "127.0.0.1" && r.tried == 2, "escaneo de este equipo");
    chk(r.open.size() == 1 && r.open[0] == open_port, "el abierto sí y el cerrado no");
    sock_close(l);
    ScanResult bad = scan_ports("nada.invalid", {80}, 500);
    chk(!bad.error.empty() && bad.open.empty(), "servidor que no existe");
  }
  // De verdad: DMS_WEBMON_SCAN=servidor (los puertos habituales).
  if (const char* h = fl_getenv("DMS_WEBMON_SCAN")) {
    double t0 = now_s();
    ScanResult r = scan_ports(h, common_ports(), 2500);
    std::printf("scan %s (%s): %s · %d probados en %.1f s %s\n", h, r.ip.c_str(), open_list(r).c_str(), r.tried,
                now_s() - t0, r.error.c_str());
  }
  // De verdad: DMS_WEBMON_LIVE=url (debe contestar) y DMS_WEBMON_DEAD=url (no).
  if (const char* u = fl_getenv("DMS_WEBMON_LIVE")) {
    Probe q = probe(u);
    std::printf("live %s: %d %d ms %s\n", u, q.code, q.ms, q.error.c_str());
    chk(is_up(q.code), "live: en línea");
  }
  if (const char* u = fl_getenv("DMS_WEBMON_DEAD")) {
    Probe q = probe(u);
    std::printf("dead %s: %d %s\n", u, q.code, q.error.c_str());
    chk(q.code == 0 && !q.error.empty(), "dead: sin respuesta");
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace um

// ============================================================ la barra de menús
// En macOS, un NSStatusItem hecho desde C++ con el runtime de Objective-C
// (objc_msgSend): el icono «globe» del sistema, cuántos sitios están en
// línea y el menú con cada sitio. En Windows y Linux, la ventana se minimiza.
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsWebMonitorTarget", 0);
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
id build(const std::vector<um::MenuEntry>& entries) {
  id m = msg(msg(cls("NSMenu"), "alloc"), "init");
  msg<void, BOOL>(m, "setAutoenablesItems:", NO);
  for (const auto& e : entries) {
    if (e.sep) {
      msg<void, id>(m, "addItem:", msg(cls("NSMenuItem"), "separatorItem"));
      continue;
    }
    std::string t = e.dot >= 0 ? std::string(um::state_emoji(e.dot)) + "  " + e.title : e.title;
    SEL action = e.tag ? sel_registerName("dmsAct:") : (SEL) nullptr;
    id it = msg<id, id, SEL, id>(msg(cls("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", str(t), action, str(""));
    msg<void, id>(it, "setTarget:", target());
    msg<void, long>(it, "setTag:", (long)e.tag);
    msg<void, BOOL>(it, "setEnabled:", (e.enabled || !e.sub.empty()) ? YES : NO);
    if (e.checked) msg<void, long>(it, "setState:", 1L);
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
void menu(const std::vector<um::MenuEntry>& entries) {
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
void menu(const std::vector<um::MenuEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
struct ScanDone {
  std::string url;
  um::ScanResult result;
};

struct ProbeDone {
  std::string url;
  um::Probe probe;
  long long t;
};

class Form1 : public FormDesign {
public:
  std::vector<um::Site> sites;
  um::SitesView* view = nullptr;
  int every = 2;
  long long next_round = 0;
  bool in_bar = false, quitting = false, live = true;
  std::string message;
  double message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_WEBMON_SELFTEST")) std::exit(um::selftest());
    if (fl_getenv("DMS_WEBMON_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_WEBMON_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    view = new um::SitesView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    view->sites = &sites;
    view->on_act = [](int act, int site) { if (self()) self()->row_act(act, site); };
    std::vector<std::string> items;
    for (int k = 0; k < um::EVERY_N; k++) items.push_back(um::fmt(tx::EVERY_ITEM, {std::to_string(um::EVERY[k])}));
    Every->items(items);
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
    Fl::lock();   // las comprobaciones (en otros hilos) avisan a la ventana
    setup();
    load();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    else BtnBar->copy_label(tx::MINIMIZE);
    check_all();
    refresh();
  }
  void form_close() override { save(); }

  // ---- guardar
  std::string data_file() const { return um::config_dir() + "/sites.tsv"; }
  void load() {
    std::string text;
    if (um::read_file(data_file(), text)) sites = um::parse(text, every);
    for (int k = 0; k < um::EVERY_N; k++)
      if (um::EVERY[k] == every) Every->index(k);
  }
  void save() {
    if (!live) return;   // las capturas y las pruebas no guardan nada
    fl_make_path(um::config_dir().c_str());
    um::write_file(data_file(), um::serialize(sites, every));
  }

  // ---- comprobar
  void check(int i) {
    if (i < 0 || i >= (int)sites.size() || sites[(size_t)i].checking) return;
    sites[(size_t)i].checking = true;
    std::string url = sites[(size_t)i].url;
    if (!live) return;
    std::thread([url] {
      auto* d = new ProbeDone{url, um::probe(url), um::now_t()};
      Fl::awake(done, d);
    }).detach();
  }
  // Escanea los puertos del servidor de un sitio (en otro hilo).
  void scan(int i, bool notify_when_done) {
    if (i < 0 || i >= (int)sites.size() || sites[(size_t)i].scanning) return;
    um::Site& s = sites[(size_t)i];
    s.scanning = true;
    s.show_ports = true;
    refresh();
    if (!live) return;
    std::string url = s.url;
    std::thread([url, notify_when_done] {
      auto* d = new ScanDone{url, um::scan_ports(um::server_of(url), um::common_ports(), 2500)};
      if (notify_when_done) um::notify(tx::SCAN_DONE, d->result.host + ": " + um::open_list(d->result));
      Fl::awake(scanned, d);
    }).detach();
  }
  static void scanned(void* p) {
    std::unique_ptr<ScanDone> d(static_cast<ScanDone*>(p));
    if (!self()) return;
    for (auto& s : self()->sites)
      if (s.url == d->url) {
        s.scanning = false;
        s.scan = d->result;
      }
    self()->refresh();
  }

  void check_all() {
    for (int i = 0; i < (int)sites.size(); i++)
      if (!sites[(size_t)i].paused) check(i);
    next_round = um::now_t() + every * 60;
    refresh();
  }
  static void done(void* p) {
    std::unique_ptr<ProbeDone> d(static_cast<ProbeDone*>(p));
    if (self()) self()->finished(*d);
  }
  void finished(const ProbeDone& d) {
    for (auto& s : sites) {
      if (s.url != d.url || !s.checking) continue;
      s.checking = false;
      s.error = d.probe.error;
      bool changed = s.add({d.t, d.probe.code, d.probe.ms});
      if (changed) {
        bool up = um::is_up(d.probe.code);
        um::notify(up ? tx::NOTIFY_UP : tx::NOTIFY_DOWN, s.name + " · " + um::answer_text(s));
      }
      break;
    }
    save();
    refresh();
  }

  // ---- lo que se ve
  void say(const std::string& m) {
    message = m;
    message_until = um::now_s() + 4;
    refresh();
  }
  void refresh() {
    long long left = next_round - um::now_t();
    int up = um::count_up(sites), down = um::count_down(sites);
    if (!message.empty() && um::now_s() < message_until) Status->text(" " + message);
    else if (sites.empty()) Status->text(std::string(" ") + tx::NO_SITES);
    else
      Status->text(" " + um::fmt(down ? tx::HEAD_DOWN : tx::HEAD, {std::to_string(sites.size()), std::to_string(up), std::to_string(down)}) +
                   "  ·  " + um::fmt(tx::NEXT_CHECK, {um::countdown(left)}));
    if (view) view->redraw();
    if (bar::available()) {
      bar::set(down ? "exclamationmark.triangle" : "globe", " " + std::to_string(up) + "/" + std::to_string(sites.size()));
      bar::menu(um::bar_menu(sites, every, left, shown() && !in_bar));
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
    save();
    bar::remove();
    hide();
    std::exit(0);
  }

  void bar_act(int t) {
    int act = t / 1000, site = t % 1000;
    if (act >= um::A_EVERY && act < um::A_EVERY + um::EVERY_N) {
      set_every(act - um::A_EVERY);
      return;
    }
    switch (act) {
      case um::A_OPEN: if (site < (int)sites.size()) fl_open_uri(sites[(size_t)site].url.c_str()); break;
      case um::A_CHECK: check(site); refresh(); break;
      case um::A_PAUSE: row_act(2, site); break;
      case um::A_SCAN: scan(site, true); break;
      case um::A_SHOW:
        view->selected = site;
        from_bar();
        break;
      case um::A_CHECK_ALL: check_all(); break;
      case um::A_WINDOW: from_bar(); break;
      case um::A_TO_BAR: to_bar(); break;
      case um::A_QUIT: quit(); break;
    }
  }
  void row_act(int act, int site) {
    if (site < 0 || site >= (int)sites.size()) return;
    um::Site& s = sites[(size_t)site];
    if (act == 0) view->selected = site;
    else if (act == 1) fl_open_uri(s.url.c_str());
    else if (act == 2) {
      s.paused = !s.paused;
      if (!s.paused) check(site);
    } else if (act == 4) {
      if (s.show_ports && !s.scanning) s.show_ports = false;
      else if (!s.scan.t || um::now_t() - s.scan.t > 600) scan(site, false);
      else s.show_ports = true;
    } else if (act == 5) {
      scan(site, false);
    } else if (act == 3) {
      if (!fl_choice("%s", tx::BTN_NO, tx::BTN_YES, nullptr, um::fmt(tx::ASK_REMOVE, {s.name}).c_str())) return;
      sites.erase(sites.begin() + site);
      view->selected = -1;
    }
    save();
    refresh();
  }
  void set_every(int k) {
    if (k < 0 || k >= um::EVERY_N) return;
    every = um::EVERY[k];
    Every->index(k);
    next_round = um::now_t() + every * 60;
    save();
    say(um::fmt(tx::EVERY_SET, {std::to_string(every)}));
  }

  // ---- añadir
  bool add_site(const std::string& raw_url, const std::string& raw_name) {
    std::string url = um::normalize_url(raw_url);
    if (url.empty()) { say(tx::BAD_URL); return false; }
    for (const auto& s : sites)
      if (s.url == url) { say(tx::ALREADY); return false; }
    um::Site s;
    s.url = url;
    s.name = um::clean(raw_name).empty() ? um::host_of(url) : um::clean(raw_name);
    s.added = um::now_t();
    sites.push_back(s);
    Url->value("");
    SiteName->value("");
    save();
    check((int)sites.size() - 1);
    say(um::fmt(tx::ADDED, {s.name}));
    return true;
  }

  // ---- eventos del diseño
  void BtnAdd_click() override { add_site(Url->value(), SiteName->value()); Url->take_focus(); }
  void Url_enter() override { BtnAdd_click(); }
  void BtnCheck_click() override { check_all(); say(tx::CHECKING_ALL); }
  void BtnBar_click() override { to_bar(); }
  void Every_select() override { set_every(Every->index()); }
  void Tick_timer() override {
    if (next_round > 0 && um::now_t() >= next_round) check_all();
    refresh();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_ADD) Url->take_focus();
    else if (item == tx::MP_CHECK) BtnCheck_click();
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
    long long now = um::now_t();
    sites = um::demo_sites(now);
    um::ScanResult r;
    r.host = "tienda.example.com";
    r.ip = "203.0.113.24";
    r.open = {22, 80, 443, 3306, 8069};
    r.tried = um::PORT_N;
    r.t = now - 40;
    sites[0].scan = r;
    sites[0].show_ports = true;
    every = 2;
    Every->index(1);
    next_round = now + 75;
    view->selected = -1;
    refresh();
  }
  // El escritorio con la barra de menús y el menú del icono abierto (como
  // en macOS), dibujado con los mismos datos del menú.
  static int draw_menu(int x, int y, const std::vector<um::MenuEntry>& m, int hi, int* hi_y) {
    const int rowh = 34, seph = 12;
    fl_font(FL_HELVETICA, 16);
    int w = 300, h = 12;
    for (const auto& e : m) {
      w = std::max(w, (int)fl_width(e.title.c_str()) + (e.dot >= 0 ? 64 : 40) + (e.sub.empty() ? 0 : 30));
      h += e.sep ? seph : rowh;
    }
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(40 - 4 * k), (uchar)(52 - 4 * k), (uchar)(80 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, w + 2 * k, h + 2 * k, 14 + k);
    }
    um::round_box(x, y, w, h, 14, um::rgb(0xf3f3f5), um::rgb(0xc4c4ca));
    int yy = y + 6;
    for (int i = 0; i < (int)m.size(); i++) {
      const auto& e = m[(size_t)i];
      if (e.sep) {
        fl_color(um::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + w - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      Fl_Color col = e.enabled || !e.sub.empty() ? um::rgb(0x1d1d1f) : um::rgb(0x8e8e93);
      if (i == hi) {
        fl_color(um::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, w - 12, rowh, 8);
        col = FL_WHITE;
        if (hi_y) *hi_y = yy;
      }
      int tx0 = x + 28;
      if (e.checked) {
        fl_color(col);
        fl_font(FL_HELVETICA_BOLD, 15);
        fl_draw("✓", x + 10, yy + 23);
      }
      if (e.dot >= 0) {
        um::dot(x + 34, yy + rowh / 2, 7, e.dot == um::ST_PAUSED ? um::rgb(0x9ca3af) : um::state_color(e.dot));
        tx0 = x + 52;
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
  void desk(const std::string& file, int open_site, int sub_hi) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(24 + 120 * t), (uchar)(48 + 60 * t), (uchar)(96 + 40 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(um::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(um::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    // El icono: un globo y cuántos están en línea.
    int ix = W - 700, up = um::count_up(sites);
    std::string title = std::to_string(up) + "/" + std::to_string(sites.size());
    fl_font(FL_HELVETICA, 16);
    int iw = 30 + (int)fl_width(title.c_str()) + 12;
    fl_color(um::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 8, 5, iw + 8, BarH - 10, 8);
    fl_color(um::rgb(0x1d1d1f));
    fl_line_style(FL_SOLID, 2);
    fl_arc(ix, 11, 18, 18, 0, 360);
    fl_arc(ix + 5, 11, 8, 18, 0, 360);
    fl_line(ix + 1, 20, ix + 17, 20);
    fl_line_style(0);
    fl_draw(title.c_str(), ix + 26, 26);
    auto m = um::bar_menu(sites, every, 75, false);
    int item = -1;
    for (int i = 0, k = 0; i < (int)m.size(); i++)
      if (m[(size_t)i].dot >= 0 && k++ == open_site) item = i;
    int hy = 0;
    int right = draw_menu(ix - 12, BarH + 4, m, open_site >= 0 ? item : -1, &hy);
    if (open_site >= 0 && item >= 0) draw_menu(right + 2, hy - 6, m[(size_t)item].sub, sub_hi, nullptr);
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
    desk(dir + "/menu-site.png", 2, 0);
    Url->value("www.example.org");
    SiteName->value(tx::DEMO_NEW);
    view->selected = 0;
    render_to(dir + "/add.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1100, 700);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    size_t n = sites.size();
    Url->value("ejemplo.org");
    SiteName->value("");
    BtnAdd_click();
    chk(sites.size() == n + 1 && sites.back().url == "https://ejemplo.org" && sites.back().name == "ejemplo.org", "añadir");
    chk(sites.back().checking, "se comprueba al añadirlo");
    Url->value("ejemplo.org");
    BtnAdd_click();
    chk(sites.size() == n + 1 && message == tx::ALREADY, "repetido");
    Url->value("no vale");
    BtnAdd_click();
    chk(sites.size() == n + 1 && message == tx::BAD_URL, "dirección mala");
    Every->index(3);
    Every_select();
    chk(every == 10, "intervalo");
    row_act(2, 0);
    chk(sites[0].paused, "pausar");
    render_to("");
    chk(view->content_h > 300 && view->hits.size() >= sites.size() * 4, "dibujado");
    // Un clic en el centro de cada botón da su botón, no la tarjeta.
    for (int act = 1; act <= 3; act++) {
      bool ok = false;
      for (const auto& h : view->hits)
        if (h.act == act && h.site == 1) {
          int i = view->hit_at(h.x + h.w / 2, h.y + h.h / 2);
          ok = i >= 0 && view->hits[(size_t)i].act == act && view->hits[(size_t)i].site == 1;
        }
      chk(ok, act == 1 ? "clic en Abrir" : act == 2 ? "clic en Pausar" : "clic en Quitar");
    }
    // Y fuera de los botones, la tarjeta (seleccionar).
    for (const auto& h : view->hits)
      if (h.act == 0 && h.site == 1) {
        int i = view->hit_at(h.x + 60, h.y + 10);
        chk(i >= 0 && view->hits[(size_t)i].act == 0, "clic en la tarjeta");
      }
    // Puertos: el botón abre la zona (con el escaneo de ejemplo de la tienda).
    chk(sites[0].show_ports && sites[0].scan.open.size() == 5, "puertos de ejemplo");
    row_act(4, 0);
    chk(!sites[0].show_ports, "ocultar los puertos");
    row_act(4, 0);
    chk(sites[0].show_ports && !sites[0].scanning, "volver a enseñarlos (escaneo reciente)");
    render_to("");
    bool rescan = false;
    for (const auto& h : view->hits)
      if (h.act == 5 && h.site == 0) rescan = true;
    chk(rescan, "botón de volver a escanear");
    // El clic en Pausar, de verdad (el evento FL_PUSH de la lista).
    bool paused1 = sites[1].paused;
    for (const auto& h : view->hits)
      if (h.act == 2 && h.site == 1) {
        Fl::e_x = h.x + h.w / 2;
        Fl::e_y = h.y + h.h / 2;
        view->handle(FL_PUSH);
        break;
      }
    chk(sites[1].paused != paused1, "Pausar con el ratón");
    std::string text = um::serialize(sites, every);
    int ev = 0;
    chk(um::parse(text, ev).size() == sites.size() && ev == 10, "guardado");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
