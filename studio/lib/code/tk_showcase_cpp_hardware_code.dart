part of 'tk_examples.dart';

// El código en C++ del inspector del equipo (tk_showcase_cpp_hardware.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _hardwareCode = r'''
// ============================================================ los datos
// Lo que se sabe del equipo: en macOS, sysctl y system_profiler (en JSON);
// en Windows, la API de Win32 y PowerShell (Get-CimInstance, en JSON); en
// Linux, /proc. Las lecturas en directo (procesador, memoria, red, discos y
// batería) se toman cada segundo con las llamadas del sistema. Nada sale del
// equipo.
namespace hw {

inline int clampi(int v, int lo, int hi) { return v < lo ? lo : v > hi ? hi : v; }
inline int iround(double v) { return (int)std::lround(v); }

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
std::string upper(std::string s) {
  for (auto& c : s) c = (char)std::toupper((unsigned char)c);
  return s;
}
bool starts(const std::string& s, const std::string& p) { return s.size() >= p.size() && s.compare(0, p.size(), p) == 0; }
bool has(const std::string& s, const std::string& p) { return s.find(p) != std::string::npos; }
std::string join(const std::vector<std::string>& v, const std::string& sep) {
  std::string o;
  for (const auto& s : v) {
    if (s.empty()) continue;
    if (!o.empty()) o += sep;
    o += s;
  }
  return o;
}
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}

// ------------------------------------------------------------ números
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}
// Bytes legibles: los discos en múltiplos de 1000 (como el sistema) y la
// memoria en múltiplos de 1024 (16 GB son 16 × 2³⁰).
std::string bytes(double b, bool binary = false) {
  const double k = binary ? 1024.0 : 1000.0;
  const char* const u[] = {"B", "KB", "MB", "GB", "TB", "PB"};
  int i = 0;
  double v = b < 0 ? 0 : b;
  while (v >= k * 0.995 && i < 5) { v /= k; i++; }
  std::string s = num(v, i == 0 ? 0 : v < 10 ? 1 : 0);
  std::string z = std::string(1, tx::DEC[0]) + "0";
  if (s.size() > 2 && s.compare(s.size() - 2, 2, z) == 0) s.resize(s.size() - 2);   // «16,0» → «16»
  return s + " " + u[i];
}
std::string rate(double bps) { return bps < 0 ? std::string(tx::NONE) : bytes(bps) + "/s"; }
std::string pct(double p) { return fmt(tx::PCT, {num(p, 0)}); }
std::string duration(long long s) {
  if (s < 0) s = 0;
  long long d = s / 86400, h = s % 86400 / 3600, m = s % 3600 / 60;
  if (d) return fmt(tx::DUR_DH, {std::to_string(d), std::to_string(h)});
  if (h) return fmt(tx::DUR_HM, {std::to_string(h), std::to_string(m)});
  return fmt(tx::DUR_M, {std::to_string(m)});
}
std::string time_text(long long t, const char* f) {
  if (t <= 0) return "";
  time_t tt = (time_t)t;
  struct tm v;
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  char b[80];
  return std::strftime(b, sizeof b, f, &v) ? std::string(b) : std::string();
}
std::string date_time(long long t) { return time_text(t, tx::DATE_FMT); }
std::string clock_time(long long t) { return time_text(t, "%H:%M"); }

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
  std::string str(const std::string& def = "") const {
    if (t == STR) return s;
    if (t == BOOL) return b ? "true" : "false";
    if (t == NUM) {
      char buf[32];
      std::snprintf(buf, sizeof buf, "%.15g", n);
      return buf;
    }
    return def;
  }
  double num(double def = 0) const {
    if (t == NUM) return n;
    if (t == STR && !s.empty() && (std::isdigit((unsigned char)s[0]) || s[0] == '-')) return std::atof(s.c_str());
    if (t == BOOL) return b;
    return def;
  }
};

class JsonParser {
public:
  explicit JsonParser(const std::string& text) : s(text) {}
  bool parse(Json& out) {
    if (s.compare(0, 3, "\xEF\xBB\xBF") == 0) i = 3;   // el BOM de PowerShell
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
std::string jstr(const Json& j, const char* k) { return trim(j[k].str()); }

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_HW_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\hardware";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/hardware";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/hardware";
#endif
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  char buf[16384];
  size_t n;
  out.clear();
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

// ------------------------------------------------------------ órdenes del sistema
// Ejecuta una orden y devuelve lo que escribe (en Windows, sin abrir ventana).
#ifdef _WIN32
std::wstring wide(const std::string& s) {
  unsigned n = fl_utf8towc(s.c_str(), (unsigned)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  fl_utf8towc(s.c_str(), (unsigned)s.size(), &w[0], n + 1);
  return w;
}
#endif
bool run(const std::string& cmd, std::string& out) {
  out.clear();
#ifdef _WIN32
  SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
  HANDLE rd = nullptr, wr = nullptr;
  if (!CreatePipe(&rd, &wr, &sa, 0)) return false;
  SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0);
  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdOutput = wr;
  PROCESS_INFORMATION pi{};
  std::wstring c = wide(cmd);
  BOOL ok = CreateProcessW(nullptr, &c[0], nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
  CloseHandle(wr);
  if (!ok) { CloseHandle(rd); return false; }
  char buf[8192];
  DWORD n = 0;
  while (ReadFile(rd, buf, sizeof buf, &n, nullptr) && n > 0) out.append(buf, n);
  CloseHandle(rd);
  WaitForSingleObject(pi.hProcess, 60000);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
#else
  FILE* p = popen((cmd + " 2>/dev/null").c_str(), "r");
  if (!p) return false;
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
  pclose(p);
#endif
  return !out.empty();
}

// ------------------------------------------------------------ el informe
// El informe: once secciones, cada una con grupos de filas «dato: valor».
enum { S_SUMMARY, S_OS, S_CPU, S_MEMORY, S_BOARD, S_GRAPHICS, S_STORAGE, S_NETWORK, S_POWER, S_AUDIO, S_DEVICES, S_COUNT };
const char* section_title(int s) {
  static const char* const t[S_COUNT] = {tx::S_SUMMARY, tx::S_OS, tx::S_CPU, tx::S_MEMORY, tx::S_BOARD, tx::S_GRAPHICS,
                                         tx::S_STORAGE, tx::S_NETWORK, tx::S_POWER, tx::S_AUDIO, tx::S_DEVICES};
  return s >= 0 && s < S_COUNT ? t[s] : "";
}

struct Row {
  std::string key, value;
  bool secret = false;   // número de serie, UUID, MAC, usuario: oculto salvo que se pida
};
struct Group {
  std::string title;
  std::vector<Row> rows;
};
struct Report {
  std::vector<Group> sec[S_COUNT];
  // Lo que enseña el resumen.
  std::string computer, model, os, cpu, cpu_detail, gpu, gpu_detail, memory_kind, display, disk_name, disk_kind, net,
      battery_health, source;
  double mem_total = 0, disk_total = 0, disk_free = 0;
  int battery = -1, cycles = -1, health_max = -1, displays = 0, cores = 0, threads = 0, p_cores = 0, e_cores = 0;
  bool laptop = false, ready = false;
  long long when = 0, boot = 0;
  Group& group(int s, const std::string& title) {
    sec[s].push_back(Group{title, {}});
    return sec[s].back();
  }
};
void add(Group& g, const std::string& k, const std::string& v, bool secret = false) {
  std::string t = trim(v);
  if (!t.empty()) g.rows.push_back(Row{k, t, secret});
}
void set_row(Group& g, const std::string& k, const std::string& v) {
  for (auto& r : g.rows)
    if (r.key == k) { r.value = v; return; }
  add(g, k, v);
}
std::string shown(const Row& r, bool secrets) { return r.secret && !secrets ? std::string(tx::HIDDEN) : r.value; }

// Los valores de system_profiler en palabras: «spdisplays_yes» → «Sí»,
// «sppci_vendor_Apple» → «Apple», «coreaudio_device_type_hdmi» → «HDMI»…
std::string cap(std::string s) {
  if (!s.empty() && s[0] >= 'a' && s[0] <= 'z') s[0] = (char)(s[0] - 32);
  return s;
}
std::string nice(const std::string& raw) {
  std::string v = trim(raw), l = lower(v);
  if (v.empty()) return v;
  // Sí o No (concuerda con cualquier dato: «Duplicada: No», «Bloqueo: No»).
  static const char* const yes[] = {"yes", "true", "on", "spdisplays_yes", "spaudio_yes", "attrib_yes", "spusb_yes", "attrib_on",
                                    "spdisplays_on", "spdisplays_supported", "integrity_enabled", "secure_vm_enabled",
                                    "activation_lock_enabled"};
  static const char* const no[] = {"no", "false", "off", "spdisplays_no", "spaudio_no", "attrib_no", "spusb_no", "attrib_off",
                                   "spdisplays_off", "integrity_disabled", "secure_vm_disabled", "activation_lock_disabled"};
  for (const char* w : yes)
    if (l == w) return tx::YES;
  for (const char* w : no)
    if (l == w) return tx::NO;
  if (l == "good" || l == "healthy" || l == "normal") return l == "normal" ? v : std::string(tx::GOOD);
  if (l == "verified") return tx::VERIFIED;
  if (l == "service recommended" || l == "warning") return tx::SERVICE;
  if (l == "normal_boot") return tx::BOOT_NORMAL;
  if (l == "safe_boot") return tx::BOOT_SAFE;
  if (l == "ssd" || l == "hdd") return upper(v);
  if (l == "nvme") return "NVMe";
  if (l == "rotational") return "HDD";
  if (l == "airport") return "Wi-Fi";
  // Quitar el prefijo de system_profiler y nombrar lo que se conoce.
  static const char* const pre[] = {"coreaudio_device_type_", "spdisplays_", "sppci_vendor_", "sppci_", "spaudio_", "attrib_", "spusb_", "sppower_"};
  for (const char* p : pre)
    if (starts(l, p)) { v = v.substr(std::strlen(p)); l = lower(v); break; }
  if (l == "builtin" || l == "built-in" || l == "internal") return cap(tx::BUILTIN);
  if (l == "unknown") return tx::UNKNOWN;
  static const std::pair<const char*, const char*> known[] = {
      {"hdmi", "HDMI"}, {"usb", "USB"}, {"bluetooth", "Bluetooth"}, {"displayport", "DisplayPort"},
      {"thunderbolt", "Thunderbolt"}, {"airplay", "AirPlay"}, {"virtual", "Virtual"}, {"pcie", "PCIe"}, {"pci", "PCI"}};
  for (const auto& k : known)
    if (l == k.first) return k.second;
  if (starts(l, "metal")) return "Metal " + v.substr(5);
  // «built-in-liquid-retina-xdr» → «Liquid Retina XDR, integrada»
  bool builtin = false;
  if (starts(l, "built-in-")) { builtin = true; v = v.substr(9); }
  std::vector<std::string> words;
  for (auto w : split(v, '-'))
    for (auto x : split(w, '_')) {
      std::string lx = lower(x);
      if (lx == "xdr" || lx == "lcd" || lx == "led" || lx == "oled" || lx == "hd" || lx == "usb") x = upper(x);
      else x = cap(x);
      if (!x.empty()) words.push_back(x);
    }
  std::string out = join(words, " ");
  return builtin ? out + ", " + tx::BUILTIN : out;
}

std::string vendor_of(const std::string& cpu) {
  std::string l = lower(cpu);
  if (has(l, "apple")) return "Apple";
  if (has(l, "intel")) return "Intel";
  if (has(l, "amd")) return "AMD";
  if (has(l, "qualcomm") || has(l, "snapdragon")) return "Qualcomm";
  return "";
}

std::string cores_text(int cores, int threads, int p, int e) {
  if (p > 0 && e > 0) return fmt(tx::CORES_PE, {std::to_string(cores), std::to_string(p), std::to_string(e)});
  if (threads > cores && cores > 0) return fmt(tx::CORES_THREADS, {std::to_string(cores), std::to_string(threads)});
  return cores > 0 ? fmt(tx::CORES_N, {std::to_string(cores)}) : "";
}

// ------------------------------------------------------------ lo que da el sistema
// Lo básico, con las llamadas del sistema (rápido y sin programas externos).
struct Sys {
  std::string cpu, arch, host, os_name, os_version, os_build, kernel, virt;
  int cores = 0, threads = 0, p_cores = 0, e_cores = 0;
  double mem = 0, freq = 0, l1i = 0, l1d = 0, l2 = 0, l3 = 0, l1i_e = 0, l1d_e = 0, l2_e = 0, line = 0;
  long long boot = 0;
};

#ifdef __APPLE__
std::string sysctl_s(const char* name) {
  size_t len = 0;
  if (sysctlbyname(name, nullptr, &len, nullptr, 0) != 0 || len == 0) return "";
  std::string s(len, '\0');
  if (sysctlbyname(name, &s[0], &len, nullptr, 0) != 0) return "";
  s.resize(std::strlen(s.c_str()));
  return trim(s);
}
long long sysctl_i(const char* name) {
  int64_t v = 0;
  size_t len = sizeof v;
  if (sysctlbyname(name, &v, &len, nullptr, 0) != 0) return 0;
  return len == 4 ? (long long)(int32_t)v : (long long)v;
}
long long boot_time() {
  struct timeval tv{};
  size_t len = sizeof tv;
  return sysctlbyname("kern.boottime", &tv, &len, nullptr, 0) == 0 ? (long long)tv.tv_sec : 0;
}
#elif defined(_WIN32)
std::string reg_str(const char* path, const char* name) {
  HKEY k;
  if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, path, 0, KEY_READ, &k) != ERROR_SUCCESS) return "";
  char buf[512];
  DWORD len = sizeof buf - 1, type = 0;
  std::string out;
  if (RegQueryValueExA(k, name, nullptr, &type, (LPBYTE)buf, &len) == ERROR_SUCCESS && (type == REG_SZ || type == REG_EXPAND_SZ)) {
    buf[len < sizeof buf ? len : sizeof buf - 1] = 0;
    out = buf;
  }
  RegCloseKey(k);
  return trim(out);
}
DWORD reg_dword(const char* path, const char* name) {
  HKEY k;
  if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, path, 0, KEY_READ, &k) != ERROR_SUCCESS) return 0;
  DWORD v = 0, len = sizeof v, type = 0;
  if (RegQueryValueExA(k, name, nullptr, &type, (LPBYTE)&v, &len) != ERROR_SUCCESS || type != REG_DWORD) v = 0;
  RegCloseKey(k);
  return v;
}
long long boot_time() {
  typedef ULONGLONG(WINAPI * TickFn)();
  static TickFn tick = reinterpret_cast<TickFn>(GetProcAddress(GetModuleHandleA("kernel32.dll"), "GetTickCount64"));
  unsigned long long ms = tick ? tick() : GetTickCount();
  return (long long)std::time(nullptr) - (long long)(ms / 1000);
}
#else
std::string proc_value(const std::string& file, const std::string& key) {
  std::string text;
  if (!read_file(file, text)) return "";
  for (const auto& l : split(text, '\n')) {
    size_t c = l.find(key);
    if (c != 0) continue;
    size_t sep = l.find_first_of(":=", key.size());
    if (sep == std::string::npos) continue;
    std::string v = trim(l.substr(sep + 1));
    if (v.size() >= 2 && v.front() == '"' && v.back() == '"') v = v.substr(1, v.size() - 2);
    return v;
  }
  return "";
}
long long boot_time() {
  std::string up;
  if (!read_file("/proc/uptime", up)) return 0;
  return (long long)std::time(nullptr) - (long long)std::atof(up.c_str());
}
#endif

Sys read_sys() {
  Sys s;
  s.boot = boot_time();
#ifdef __APPLE__
  s.cpu = sysctl_s("machdep.cpu.brand_string");
  s.threads = (int)sysctl_i("hw.logicalcpu");
  s.cores = (int)sysctl_i("hw.physicalcpu");
  if (sysctl_i("hw.nperflevels") >= 2) {
    s.p_cores = (int)sysctl_i("hw.perflevel0.physicalcpu");
    s.e_cores = (int)sysctl_i("hw.perflevel1.physicalcpu");
    s.l1i = (double)sysctl_i("hw.perflevel0.l1icachesize");
    s.l1d = (double)sysctl_i("hw.perflevel0.l1dcachesize");
    s.l2 = (double)sysctl_i("hw.perflevel0.l2cachesize");
    s.l1i_e = (double)sysctl_i("hw.perflevel1.l1icachesize");
    s.l1d_e = (double)sysctl_i("hw.perflevel1.l1dcachesize");
    s.l2_e = (double)sysctl_i("hw.perflevel1.l2cachesize");
  } else {
    s.l1i = (double)sysctl_i("hw.l1icachesize");
    s.l1d = (double)sysctl_i("hw.l1dcachesize");
    s.l2 = (double)sysctl_i("hw.l2cachesize");
    s.l3 = (double)sysctl_i("hw.l3cachesize");
  }
  s.line = (double)sysctl_i("hw.cachelinesize");
  s.freq = (double)sysctl_i("hw.cpufrequency_max");   // solo en los Mac con Intel
  s.mem = (double)sysctl_i("hw.memsize");
  s.virt = sysctl_i("kern.hv_support") ? tx::YES : tx::NO;
  s.os_name = "macOS";
  s.os_version = sysctl_s("kern.osproductversion");
  s.os_build = sysctl_s("kern.osversion");
  s.kernel = "Darwin " + sysctl_s("kern.osrelease");
  struct utsname u;
  if (uname(&u) == 0) s.arch = u.machine;
  char host[256] = "";
  if (gethostname(host, sizeof host - 1) == 0) s.host = host;
#elif defined(_WIN32)
  const char* cpu_key = "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0";
  s.cpu = reg_str(cpu_key, "ProcessorNameString");
  s.freq = reg_dword(cpu_key, "~MHz") * 1e6;
  SYSTEM_INFO si;
  GetNativeSystemInfo(&si);
  s.threads = (int)si.dwNumberOfProcessors;
  switch (si.wProcessorArchitecture) {
    case 9: s.arch = "x64"; break;
    case 12: s.arch = "ARM64"; break;
    case 5: s.arch = "ARM"; break;
    case 0: s.arch = "x86"; break;
  }
  DWORD len = 0;
  GetLogicalProcessorInformation(nullptr, &len);
  if (len) {
    std::vector<SYSTEM_LOGICAL_PROCESSOR_INFORMATION> v(len / sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION));
    if (GetLogicalProcessorInformation(v.data(), &len)) {
      for (const auto& p : v) {
        if (p.Relationship == RelationProcessorCore) s.cores++;
        if (p.Relationship != RelationCache) continue;
        const CACHE_DESCRIPTOR& c = p.Cache;
        if (c.Level == 1 && c.Type == CacheInstruction && !s.l1i) s.l1i = c.Size;
        if (c.Level == 1 && c.Type == CacheData && !s.l1d) s.l1d = c.Size;
        if (c.Level == 2) s.l2 += c.Size;
        if (c.Level == 3) s.l3 += c.Size;
        if (!s.line) s.line = c.LineSize;
      }
    }
  }
  MEMORYSTATUSEX m;
  m.dwLength = sizeof m;
  if (GlobalMemoryStatusEx(&m)) s.mem = (double)m.ullTotalPhys;
  const char* nt = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
  s.os_name = reg_str(nt, "ProductName");
  std::string build = reg_str(nt, "CurrentBuild");
  // Windows 11 sigue diciendo «Windows 10» en el registro.
  if (std::atoi(build.c_str()) >= 22000 && has(s.os_name, "Windows 10")) s.os_name.replace(s.os_name.find("Windows 10"), 10, "Windows 11");
  s.os_version = reg_str(nt, "DisplayVersion");
  DWORD ubr = reg_dword(nt, "UBR");
  s.os_build = build + (ubr ? "." + std::to_string(ubr) : "");
  s.kernel = "Windows NT " + std::to_string(reg_dword(nt, "CurrentMajorVersionNumber")) + "." +
             std::to_string(reg_dword(nt, "CurrentMinorVersionNumber"));
  char host[MAX_COMPUTERNAME_LENGTH + 1] = "";
  DWORD hl = sizeof host;
  if (GetComputerNameA(host, &hl)) s.host = host;
#else
  s.cpu = proc_value("/proc/cpuinfo", "model name");
  s.threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
  s.cores = std::atoi(proc_value("/proc/cpuinfo", "cpu cores").c_str());
  s.mem = std::atof(proc_value("/proc/meminfo", "MemTotal").c_str()) * 1024;
  s.os_name = proc_value("/etc/os-release", "PRETTY_NAME");
  struct utsname u;
  if (uname(&u) == 0) {
    s.kernel = std::string(u.sysname) + " " + u.release;
    s.arch = u.machine;
  }
  char host[256] = "";
  if (gethostname(host, sizeof host - 1) == 0) s.host = host;
#endif
  if (!s.cores) s.cores = s.threads;
  return s;
}

// ------------------------------------------------------------ las lecturas en directo
struct DiskUse {
  std::string name, mount, fs;
  double total = 0, free = 0;
};
struct Live {
  double cpu = -1;                 // % del total (hasta la segunda lectura, -1)
  std::vector<double> cores;       // % de cada núcleo
  std::deque<double> cpu_hist;     // el último minuto
  double mem_total = 0, mem_used = 0, mem_app = 0, mem_wired = 0, mem_compressed = 0, mem_cached = 0;
  double swap_used = 0, swap_total = 0;
  std::deque<double> mem_hist;
  double down = -1, up = -1;       // bytes por segundo
  std::deque<double> down_hist, up_hist;
  double load[3] = {-1, -1, -1};
  int battery = -1;
  bool charging = false, on_ac = true;
  std::vector<DiskUse> disks;
};
inline void push(std::deque<double>& d, double v) {
  d.push_back(v);
  while (d.size() > 60) d.pop_front();
}

class Sampler {
public:
  void sample(Live& L, double t) {
    cpu(L);
    memory(L);
    net(L, t);
    if (n % 10 == 0) disks(L);
    if (n % 15 == 0) power(L);
#ifndef _WIN32
    double la[3];
    if (getloadavg(la, 3) == 3)
      for (int i = 0; i < 3; i++) L.load[i] = la[i];
#endif
    n++;
  }

private:
  std::vector<uint64_t> pb, pt;   // ticks ocupados y totales: [0] el total, luego cada núcleo
  uint64_t pin = 0, pout = 0;
  double pt_net = -1;
  int n = 0;

  void cpu_feed(Live& L, const std::vector<uint64_t>& b, const std::vector<uint64_t>& t) {
    if (pb.size() == b.size() && !b.empty()) {
      auto use = [&](size_t i) {
        uint64_t db = b[i] >= pb[i] ? b[i] - pb[i] : 0, dt = t[i] >= pt[i] ? t[i] - pt[i] : 0;
        return dt ? std::min(100.0, 100.0 * (double)db / (double)dt) : 0.0;
      };
      L.cpu = use(0);
      push(L.cpu_hist, L.cpu);
      L.cores.clear();
      for (size_t i = 1; i < b.size(); i++) L.cores.push_back(use(i));
    }
    pb = b;
    pt = t;
  }
  void net_feed(Live& L, uint64_t in, uint64_t out, double t) {
    if (pt_net > 0 && t > pt_net && in >= pin && out >= pout) {
      double dt = t - pt_net;
      L.down = (double)(in - pin) / dt;
      L.up = (double)(out - pout) / dt;
      push(L.down_hist, L.down);
      push(L.up_hist, L.up);
    }
    pin = in;
    pout = out;
    pt_net = t;
  }
  void mem_done(Live& L) {
    if (L.mem_total > 0) push(L.mem_hist, 100 * L.mem_used / L.mem_total);
  }

#ifdef __APPLE__
  void cpu(Live& L) {
    static host_t host = mach_host_self();
    natural_t count = 0;
    processor_info_array_t info = nullptr;
    mach_msg_type_number_t n_info = 0;
    if (host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &count, &info, &n_info) != KERN_SUCCESS) return;
    std::vector<uint64_t> b(count + 1, 0), t(count + 1, 0);
    for (natural_t i = 0; i < count; i++) {
      const integer_t* c = info + i * CPU_STATE_MAX;
      uint64_t busy = (uint64_t)(uint32_t)c[CPU_STATE_USER] + (uint32_t)c[CPU_STATE_SYSTEM] + (uint32_t)c[CPU_STATE_NICE];
      uint64_t tot = busy + (uint32_t)c[CPU_STATE_IDLE];
      b[i + 1] = busy;
      t[i + 1] = tot;
      b[0] += busy;
      t[0] += tot;
    }
    vm_deallocate(mach_task_self(), (vm_address_t)info, n_info * sizeof(integer_t));
    cpu_feed(L, b, t);
  }
  void memory(Live& L) {
    static host_t host = mach_host_self();
    vm_statistics64_data_t vm;
    mach_msg_type_number_t c = HOST_VM_INFO64_COUNT;
    if (host_statistics64(host, HOST_VM_INFO64, (host_info64_t)&vm, &c) != KERN_SUCCESS) return;
    vm_size_t ps = 0;
    host_page_size(host, &ps);
    double p = (double)ps;
    L.mem_total = (double)sysctl_i("hw.memsize");
    // Como el Monitor de Actividad: en uso = apps + fija + comprimida.
    L.mem_app = (double)(vm.internal_page_count - vm.purgeable_count) * p;
    L.mem_wired = (double)vm.wire_count * p;
    L.mem_compressed = (double)vm.compressor_page_count * p;
    L.mem_cached = (double)(vm.external_page_count + vm.purgeable_count) * p;
    L.mem_used = L.mem_app + L.mem_wired + L.mem_compressed;
    struct xsw_usage sw{};
    size_t len = sizeof sw;
    if (sysctlbyname("vm.swapusage", &sw, &len, nullptr, 0) == 0) {
      L.swap_used = (double)sw.xsu_used;
      L.swap_total = (double)sw.xsu_total;
    }
    mem_done(L);
  }
  void net(Live& L, double t) {
    struct ifaddrs* list = nullptr;
    if (getifaddrs(&list) != 0) return;
    uint64_t in = 0, out = 0;
    for (auto* a = list; a; a = a->ifa_next) {
      if (!a->ifa_addr || a->ifa_addr->sa_family != AF_LINK || !a->ifa_data) continue;
      if (!(a->ifa_flags & IFF_UP) || (a->ifa_flags & IFF_LOOPBACK)) continue;
      std::string nm = a->ifa_name;
      // Wi-Fi, Ethernet y datos móviles; los túneles (VPN) contarían dos veces.
      if (!starts(nm, "en") && !starts(nm, "pdp_ip")) continue;
      const auto* d = static_cast<const struct if_data*>(a->ifa_data);
      in += d->ifi_ibytes;
      out += d->ifi_obytes;
    }
    freeifaddrs(list);
    net_feed(L, in, out, t);
  }
  void disks(Live& L) {
    L.disks.clear();
    struct statfs* m = nullptr;
    int count = getmntinfo(&m, MNT_NOWAIT);
    for (int i = 0; i < count; i++) {
      const struct statfs& f = m[i];
      std::string mount = f.f_mntonname;
      if (!(f.f_flags & MNT_LOCAL) || f.f_blocks == 0) continue;
      if (mount != "/" && !starts(mount, "/Volumes/")) continue;
      DiskUse d;
      d.mount = mount;
      d.fs = f.f_fstypename;
      d.total = (double)f.f_blocks * f.f_bsize;
      d.free = (double)f.f_bavail * f.f_bsize;
      d.name = mount == "/" ? std::string(tx::STARTUP_DISK) : mount.substr(9);
      L.disks.push_back(d);
    }
  }
  void power(Live& L) {
    std::string out;
    if (!run("/usr/bin/pmset -g batt", out)) return;
    L.on_ac = has(out, "AC Power");
    size_t p = out.find('%');
    if (p == std::string::npos || !has(out, "InternalBattery")) { L.battery = -1; return; }
    size_t a = p;
    while (a > 0 && std::isdigit((unsigned char)out[a - 1])) a--;
    L.battery = std::atoi(out.substr(a, p - a).c_str());
    L.charging = has(out, "; charging") || has(out, "; finishing charge");
  }
#elif defined(_WIN32)
  static uint64_t ft(const FILETIME& f) { return ((uint64_t)f.dwHighDateTime << 32) | f.dwLowDateTime; }
  void cpu(Live& L) {
    FILETIME i, k, u;
    if (!GetSystemTimes(&i, &k, &u)) return;
    uint64_t idle = ft(i), tot = ft(k) + ft(u);   // el tiempo del núcleo incluye el ocioso
    cpu_feed(L, {tot - idle}, {tot});
  }
  void memory(Live& L) {
    MEMORYSTATUSEX m;
    m.dwLength = sizeof m;
    if (!GlobalMemoryStatusEx(&m)) return;
    L.mem_total = (double)m.ullTotalPhys;
    L.mem_used = (double)(m.ullTotalPhys - m.ullAvailPhys);
    L.mem_app = L.mem_used;
    mem_done(L);
  }
  // La tabla de interfaces de iphlpapi.dll (se carga al usarla: así no hace
  // falta enlazar con otra biblioteca). Es la de MIB_IFROW.
  struct IfRow {
    WCHAR name[256];
    DWORD index, type, mtu, speed, phys_len;
    BYTE phys[8];
    DWORD admin, oper, last_change, in_octets, in_ucast, in_nucast, in_discards, in_errors, in_unknown, out_octets,
        out_ucast, out_nucast, out_discards, out_errors, out_qlen, descr_len;
    BYTE descr[256];
  };
  struct IfTable {
    DWORD n;
    IfRow rows[1];
  };
  void net(Live& L, double t) {
    typedef DWORD(WINAPI * GetIfTableFn)(IfTable*, PULONG, BOOL);
    static HMODULE lib = LoadLibraryA("iphlpapi.dll");
    static GetIfTableFn fn = lib ? reinterpret_cast<GetIfTableFn>(GetProcAddress(lib, "GetIfTable")) : nullptr;
    if (!fn) return;
    ULONG size = 0;
    fn(nullptr, &size, FALSE);
    if (!size) return;
    std::vector<char> buf(size + sizeof(IfRow));
    auto* tb = reinterpret_cast<IfTable*>(buf.data());
    if (fn(tb, &size, FALSE) != NO_ERROR) return;
    uint64_t in = 0, out = 0;
    for (DWORD i = 0; i < tb->n; i++) {
      const IfRow& r = tb->rows[i];
      if (r.type == 24) continue;   // el bucle local
      in += r.in_octets;
      out += r.out_octets;
    }
    net_feed(L, in, out, t);
  }
  void disks(Live& L) {
    L.disks.clear();
    char buf[512];
    DWORD len = GetLogicalDriveStringsA(sizeof buf - 1, buf);
    for (const char* p = buf; p < buf + len && *p; p += std::strlen(p) + 1) {
      UINT type = GetDriveTypeA(p);
      if (type != DRIVE_FIXED && type != DRIVE_REMOVABLE) continue;
      ULARGE_INTEGER avail, total, freeb;
      if (!GetDiskFreeSpaceExA(p, &avail, &total, &freeb)) continue;
      char vol[MAX_PATH + 1] = "", fs[MAX_PATH + 1] = "";
      GetVolumeInformationA(p, vol, sizeof vol, nullptr, nullptr, nullptr, fs, sizeof fs);
      DiskUse d;
      d.mount = p;
      if (!d.mount.empty() && d.mount.back() == '\\') d.mount.pop_back();
      d.name = vol[0] ? std::string(vol) : std::string(type == DRIVE_FIXED ? tx::LOCAL_DISK : tx::REMOVABLE_DISK);
      d.fs = fs;
      d.total = (double)total.QuadPart;
      d.free = (double)avail.QuadPart;
      L.disks.push_back(d);
    }
  }
  void power(Live& L) {
    SYSTEM_POWER_STATUS s;
    if (!GetSystemPowerStatus(&s)) return;
    L.on_ac = s.ACLineStatus == 1;
    L.battery = (s.BatteryFlag & 128) || s.BatteryLifePercent > 100 ? -1 : (int)s.BatteryLifePercent;
    L.charging = (s.BatteryFlag & 8) != 0;
  }
#else
  void cpu(Live& L) {
    std::string text;
    if (!read_file("/proc/stat", text)) return;
    std::vector<uint64_t> b, t;
    for (const auto& l : split(text, '\n')) {
      if (!starts(l, "cpu")) continue;
      unsigned long long v[8] = {0};
      std::sscanf(l.c_str(), "%*s %llu %llu %llu %llu %llu %llu %llu %llu", &v[0], &v[1], &v[2], &v[3], &v[4], &v[5], &v[6], &v[7]);
      uint64_t busy = v[0] + v[1] + v[2] + v[5] + v[6] + v[7];
      b.push_back(busy);
      t.push_back(busy + v[3] + v[4]);
    }
    cpu_feed(L, b, t);
  }
  void memory(Live& L) {
    double total = std::atof(proc_value("/proc/meminfo", "MemTotal").c_str()) * 1024;
    double avail = std::atof(proc_value("/proc/meminfo", "MemAvailable").c_str()) * 1024;
    double st = std::atof(proc_value("/proc/meminfo", "SwapTotal").c_str()) * 1024;
    double sf = std::atof(proc_value("/proc/meminfo", "SwapFree").c_str()) * 1024;
    L.mem_total = total;
    L.mem_used = L.mem_app = total - avail;
    L.swap_total = st;
    L.swap_used = st - sf;
    mem_done(L);
  }
  void net(Live& L, double t) {
    std::string text;
    if (!read_file("/proc/net/dev", text)) return;
    uint64_t in = 0, out = 0;
    for (const auto& l : split(text, '\n')) {
      size_t c = l.find(':');
      if (c == std::string::npos || trim(l.substr(0, c)) == "lo") continue;
      unsigned long long v[9] = {0};
      if (std::sscanf(l.c_str() + c + 1, "%llu %llu %llu %llu %llu %llu %llu %llu %llu", &v[0], &v[1], &v[2], &v[3], &v[4], &v[5], &v[6], &v[7], &v[8]) == 9) {
        in += v[0];
        out += v[8];
      }
    }
    net_feed(L, in, out, t);
  }
  void disks(Live& L) {
    L.disks.clear();
    struct statvfs f;
    if (statvfs("/", &f) == 0) {
      DiskUse d;
      d.name = tx::STARTUP_DISK;
      d.mount = "/";
      d.total = (double)f.f_blocks * f.f_frsize;
      d.free = (double)f.f_bavail * f.f_frsize;
      L.disks.push_back(d);
    }
  }
  void power(Live& L) {
    std::string cap, st;
    if (!read_file("/sys/class/power_supply/BAT0/capacity", cap)) { L.battery = -1; return; }
    L.battery = std::atoi(cap.c_str());
    read_file("/sys/class/power_supply/BAT0/status", st);
    L.charging = starts(st, "Charging");
  }
#endif
};

// ------------------------------------------------------------ el informe a partir de los datos
void base(Report& r, const Sys& s) {
  r.computer = s.host;
  r.cpu = s.cpu;
  r.cores = s.cores;
  r.threads = s.threads;
  r.p_cores = s.p_cores;
  r.e_cores = s.e_cores;
  r.mem_total = s.mem;
  r.boot = s.boot;
  r.os = trim(s.os_name + " " + s.os_version);
  r.cpu_detail = cores_text(s.cores, s.threads, s.p_cores, s.e_cores);
  {
    Group& g = r.group(S_OS, tx::G_SYSTEM);
    add(g, tx::K_OS, r.os);
    add(g, tx::K_BUILD, s.os_build);
    add(g, tx::K_KERNEL, s.kernel);
    add(g, tx::K_ARCH, s.arch);
    add(g, tx::K_COMPUTER, s.host);
    if (s.boot > 0) {
      add(g, tx::K_BOOTED, date_time(s.boot));
      add(g, tx::K_UPTIME, duration(r.when - s.boot));
    }
  }
  {
    Group& g = r.group(S_CPU, tx::G_PROCESSOR);
    add(g, tx::K_MODEL, s.cpu);
    add(g, tx::K_VENDOR, vendor_of(s.cpu));
    add(g, tx::K_ARCH, s.arch);
    add(g, tx::K_CORES, r.cpu_detail);
    if (s.threads) add(g, tx::K_THREADS, std::to_string(s.threads));
    if (s.freq > 0) add(g, tx::K_FREQ, num(s.freq / 1e9, 2) + " GHz");
    add(g, tx::K_VIRT, s.virt);
  }
  {
    Group& g = r.group(S_CPU, tx::G_CACHES);
    auto per = [](double v) { return v > 0 ? fmt(tx::PER_CORE, {bytes(v, true)}) : std::string(); };
    add(g, tx::K_L1I, per(s.l1i));
    add(g, tx::K_L1D, per(s.l1d));
    if (s.e_cores > 0) {
      if (s.l2 > 0) add(g, tx::K_L2_P, bytes(s.l2, true));
      if (s.l2_e > 0) add(g, tx::K_L2_E, bytes(s.l2_e, true));
    } else if (s.l2 > 0) add(g, tx::K_L2, bytes(s.l2, true));
    if (s.l3 > 0) add(g, tx::K_L3, bytes(s.l3, true));
    if (s.line > 0) add(g, tx::K_LINE, bytes(s.line, true));
  }
  {
    Group& g = r.group(S_MEMORY, tx::G_MEMORY);
    if (s.mem > 0) add(g, tx::K_TOTAL, bytes(s.mem, true));
  }
}

// Los dispositivos USB en árbol: la sangría dice de qué concentrador cuelgan.
void usb_walk(const Json& items, Group& g, int depth) {
  for (const auto& d : items.a) {
    std::string name = jstr(d, "_name");
    std::string vendor = jstr(d, "USBDeviceKeyVendorName");
    if (vendor.empty()) vendor = jstr(d, "manufacturer");
    std::string speed = jstr(d, "USBDeviceKeyLinkSpeed");
    if (speed.empty()) speed = nice(jstr(d, "device_speed"));
    if (!name.empty()) g.rows.push_back(Row{std::string(depth * 4, ' ') + name, join({vendor, speed}, " · ")});
    usb_walk(d["_items"], g, depth + 1);
  }
  for (auto& r : g.rows)
    if (r.value.empty()) r.value = tx::NONE;
}

// macOS: la salida de «system_profiler -json».
void from_mac(Report& r, const Json& j) {
  // ---- el modelo y el firmware
  const Json& h = j["SPHardwareDataType"][0];
  if (h.t == Json::OBJ) {
    std::string name = jstr(h, "machine_name"), chip = jstr(h, "chip_type");
    if (!name.empty()) r.model = name;
    r.laptop = has(lower(name), "book");
    Group& g = r.group(S_BOARD, tx::G_MODEL);
    add(g, tx::K_MODEL_NAME, name);
    add(g, tx::K_MODEL_ID, jstr(h, "machine_model"));
    add(g, tx::K_MODEL_NUMBER, jstr(h, "model_number"));
    add(g, tx::K_CHIP, chip.empty() ? jstr(h, "cpu_type") : chip);
    add(g, tx::K_FIRMWARE, jstr(h, "boot_rom_version"));
    add(g, tx::K_LOADER, jstr(h, "os_loader_version"));
    add(g, tx::K_SERIAL, jstr(h, "serial_number"), true);
    add(g, tx::K_HW_UUID, jstr(h, "platform_UUID"), true);
    add(g, tx::K_ACTIVATION_LOCK, nice(jstr(h, "activation_lock_status")));
    if (r.cpu.empty()) r.cpu = chip;
  }
  // ---- el sistema
  const Json& sw = j["SPSoftwareDataType"][0];
  if (sw.t == Json::OBJ && !r.sec[S_OS].empty()) {
    Group& g = r.sec[S_OS][0];
    std::string osv = jstr(sw, "os_version");   // «macOS 26.1 (25B78)»
    if (!osv.empty()) {
      size_t p = osv.find(" (");
      r.os = p == std::string::npos ? osv : osv.substr(0, p);
      set_row(g, tx::K_OS, r.os);
    }
    std::string host = jstr(sw, "local_host_name");
    if (!host.empty()) {
      r.computer = host;
      set_row(g, tx::K_COMPUTER, host);
    }
    add(g, tx::K_BOOT_VOLUME, jstr(sw, "boot_volume"));
    add(g, tx::K_BOOT_MODE, nice(jstr(sw, "boot_mode")));
    add(g, tx::K_USER, jstr(sw, "user_name"), true);
    add(g, tx::K_SIP, nice(jstr(sw, "system_integrity")));
    add(g, tx::K_SECURE_VM, nice(jstr(sw, "secure_vm")));
  }
  // ---- la memoria: unificada (Apple) o un módulo por ranura (Intel)
  for (const auto& m : j["SPMemoryDataType"].a) {
    if (m["_items"].t != Json::ARR) {
      r.memory_kind = jstr(m, "dimm_type");
      Group& g = r.group(S_MEMORY, tx::G_MODULES);
      add(g, tx::K_SIZE, jstr(m, "SPMemoryDataType"));
      add(g, tx::K_MEM_TYPE, r.memory_kind);
      add(g, tx::K_MAKER, jstr(m, "dimm_manufacturer"));
    }
    for (const auto& b : m["_items"].a) {
      std::string size = jstr(b, "dimm_size");
      if (size.empty() || lower(size) == "empty") continue;
      Group& g = r.group(S_MEMORY, jstr(b, "_name"));
      add(g, tx::K_SIZE, size);
      add(g, tx::K_MEM_TYPE, jstr(b, "dimm_type"));
      add(g, tx::K_SPEED, jstr(b, "dimm_speed"));
      add(g, tx::K_MAKER, jstr(b, "dimm_manufacturer"));
      add(g, tx::K_PART, jstr(b, "dimm_part_number"));
      if (r.memory_kind.empty()) r.memory_kind = jstr(b, "dimm_type");
    }
  }
  // ---- los gráficos y las pantallas
  int gi = 0;
  std::string main_display;
  for (const auto& gpu : j["SPDisplaysDataType"].a) {
    std::string name = jstr(gpu, "sppci_model");
    if (name.empty()) name = jstr(gpu, "_name");
    std::string cores = jstr(gpu, "sppci_cores");
    {
      Group& g = r.group(S_GRAPHICS, name);
      add(g, tx::K_VENDOR, nice(jstr(gpu, "spdisplays_vendor")));
      add(g, tx::K_GPU_CORES, cores);
      std::string vram = jstr(gpu, "spdisplays_vram");
      add(g, tx::K_VRAM, vram.empty() ? jstr(gpu, "_spdisplays_vram") : vram);
      add(g, tx::K_METAL, nice(jstr(gpu, "spdisplays_mtlgpufamilysupport")));
      add(g, tx::K_BUS, nice(jstr(gpu, "sppci_bus")));
    }
    if (gi++ == 0) {
      r.gpu = name;
      if (!cores.empty()) r.gpu_detail = fmt(tx::GPU_CORES_N, {cores});
    }
    for (const auto& d : gpu["spdisplays_ndrvs"].a) {
      std::string dn = jstr(d, "_name"), px = jstr(d, "_spdisplays_pixels");
      std::string looks = jstr(d, "_spdisplays_resolution");
      if (looks.empty()) looks = jstr(d, "spdisplays_resolution");
      Group& g = r.group(S_GRAPHICS, fmt(tx::G_DISPLAY, {dn}));
      add(g, tx::K_RESOLUTION, px);
      add(g, tx::K_LOOKS_LIKE, looks);
      add(g, tx::K_DISPLAY_TYPE, nice(jstr(d, "spdisplays_display_type")));
      add(g, tx::K_CONNECTION, nice(jstr(d, "spdisplays_connection_type")));
      add(g, tx::K_MAIN, nice(jstr(d, "spdisplays_main")));
      add(g, tx::K_MIRROR, nice(jstr(d, "spdisplays_mirror")));
      add(g, tx::K_ROTATION, nice(jstr(d, "spdisplays_rotation")));
      int year = (int)d["_spdisplays_display-year"].num(), week = (int)d["_spdisplays_display-week"].num();
      if (year > 1990) add(g, tx::K_MADE, week > 0 ? fmt(tx::WEEK_YEAR, {std::to_string(week), std::to_string(year)}) : std::to_string(year));
      std::string line = px.empty() ? dn : dn + " · " + px;
      if (r.displays++ == 0 || lower(jstr(d, "spdisplays_main")) == "spdisplays_yes") main_display = line;
    }
  }
  r.display = main_display;
  if (r.displays > 1) r.display += " " + fmt(tx::PLUS_N, {std::to_string(r.displays - 1)});
  // ---- el almacenamiento: el disco de arranque y los de /Volumes
  bool root = false;
  for (const auto& v : j["SPStorageDataType"].a) root = root || jstr(v, "mount_point") == "/";
  for (const auto& v : j["SPStorageDataType"].a) {
    std::string mount = jstr(v, "mount_point");
    bool is_root = mount == "/" || (!root && mount == "/System/Volumes/Data");
    if (!is_root && !starts(mount, "/Volumes/")) continue;
    const Json& pd = v["physical_drive"];
    double size = v["size_in_bytes"].num(), fr = v["free_space_in_bytes"].num();
    std::string name = jstr(v, "_name"), medium = nice(jstr(pd, "medium_type"));
    Group& g = r.group(S_STORAGE, name);
    add(g, tx::K_MOUNT, mount);
    add(g, tx::K_FS, jstr(v, "file_system"));
    if (size > 0) {
      add(g, tx::K_CAPACITY, bytes(size));
      add(g, tx::K_FREE, bytes(fr) + " (" + pct(100 * fr / size) + ")");
    }
    add(g, tx::K_DRIVE, jstr(pd, "device_name"));
    add(g, tx::K_MEDIUM, medium);
    add(g, tx::K_PROTOCOL, jstr(pd, "protocol"));
    add(g, tx::K_INTERNAL, nice(jstr(pd, "is_internal_disk")));
    add(g, tx::K_SMART, nice(jstr(pd, "smart_status")));
    if (is_root) {
      r.disk_name = name;
      r.disk_kind = medium;
      r.disk_total = size;
      r.disk_free = fr;
    }
  }
  // ---- la batería y la energía
  for (const auto& p : j["SPPowerDataType"].a) {
    std::string n = jstr(p, "_name");
    if (n == "spbattery_information") {
      const Json& ch = p["sppower_battery_charge_info"];
      const Json& he = p["sppower_battery_health_info"];
      const Json& mo = p["sppower_battery_model_info"];
      Group& g = r.group(S_POWER, tx::G_BATTERY);
      r.laptop = true;
      int soc = (int)ch["sppower_battery_state_of_charge"].num(-1);
      if (soc >= 0) {
        r.battery = soc;
        add(g, tx::K_CHARGE, pct(soc));
      }
      bool charging = nice(jstr(ch, "sppower_battery_is_charging")) == tx::YES;
      bool full = nice(jstr(ch, "sppower_battery_fully_charged")) == tx::YES;
      add(g, tx::K_STATE, charging ? tx::CHARGING : full ? tx::CHARGED : "");
      int cyc = (int)he["sppower_battery_cycle_count"].num(-1);
      if (cyc >= 0) {
        r.cycles = cyc;
        add(g, tx::K_CYCLES, std::to_string(cyc));
      }
      std::string health = jstr(he, "sppower_battery_health");
      if (!health.empty()) add(g, tx::K_HEALTH, r.battery_health = nice(health));
      std::string mx = jstr(he, "sppower_battery_health_maximum_capacity");
      if (!mx.empty()) {
        r.health_max = std::atoi(mx.c_str());
        add(g, tx::K_MAX_CAPACITY, pct(r.health_max));
      }
      add(g, tx::K_BATTERY_MODEL, jstr(mo, "sppower_battery_device_name"));
      add(g, tx::K_FIRMWARE, jstr(mo, "sppower_battery_firmware_version"));
    } else if (n == "sppower_information") {
      Group& g = r.group(S_POWER, tx::G_POWER);
      const Json& ac = p["AC Power"];
      const Json& bat = p["Battery Power"];
      bool on_bat = lower(jstr(bat, "Current Power Source")) == "true";
      bool on_ac = lower(jstr(ac, "Current Power Source")) == "true";
      add(g, tx::K_SOURCE, on_ac ? tx::SRC_AC : on_bat ? tx::SRC_BATTERY : "");
      const Json& cur = on_bat ? bat : ac;
      add(g, tx::K_LOW_POWER, nice(jstr(cur, "LowPowerMode")));
      auto minutes = [](const Json& x) {
        int m = (int)x.num(-1);
        return m < 0 ? std::string() : m == 0 ? std::string(tx::NEVER) : fmt(tx::DUR_M, {std::to_string(m)});
      };
      add(g, tx::K_DISPLAY_SLEEP, minutes(cur["Display Sleep Timer"]));
      add(g, tx::K_SYSTEM_SLEEP, minutes(cur["System Sleep Timer"]));
    } else if (n == "sppower_ac_charger_information") {
      Group& g = r.group(S_POWER, tx::G_CHARGER);
      add(g, tx::K_CONNECTED, nice(jstr(p, "sppower_battery_charger_connected")));
      std::string w = jstr(p, "sppower_ac_charger_watts");
      add(g, tx::K_WATTS, w.empty() ? "" : w + " W");
      add(g, tx::K_NAME, jstr(p, "sppower_ac_charger_name"));
    }
  }
  // ---- el audio
  for (const auto& a : j["SPAudioDataType"].a)
    for (const auto& d : a["_items"].a) {
      Group& g = r.group(S_AUDIO, jstr(d, "_name"));
      std::string mk = jstr(d, "coreaudio_device_manufacturer");
      if (lower(mk) != "unknown manufacturer") add(g, tx::K_MAKER, mk);
      int out = (int)d["coreaudio_device_output"].num(0), in = (int)d["coreaudio_device_input"].num(0);
      if (out) add(g, tx::K_OUTPUT, fmt(tx::CHANNELS_N, {std::to_string(out)}));
      if (in) add(g, tx::K_INPUT, fmt(tx::CHANNELS_N, {std::to_string(in)}));
      double sr = d["coreaudio_device_srate"].num(0);
      if (sr > 0) add(g, tx::K_SAMPLE_RATE, num(sr / 1000, std::fmod(sr, 1000) == 0 ? 0 : 1) + " kHz");
      add(g, tx::K_CONNECTION, nice(jstr(d, "coreaudio_device_transport")));
      if (nice(jstr(d, "coreaudio_default_audio_output_device")) == tx::YES) add(g, tx::K_DEFAULT_OUT, tx::YES);
      if (nice(jstr(d, "coreaudio_default_audio_input_device")) == tx::YES) add(g, tx::K_DEFAULT_IN, tx::YES);
    }
  // ---- la red: las interfaces con dirección y, aparte, las demás
  std::vector<Row> idle;
  for (const auto& s : j["SPNetworkDataType"].a) {
    std::string name = jstr(s, "_name"), iface = jstr(s, "interface");
    std::vector<std::string> ips;
    for (const auto& x : s["ip_address"].a) ips.push_back(x.str());
    if (ips.empty()) {
      if (!iface.empty()) idle.push_back(Row{name, iface});
      continue;
    }
    Group& g = r.group(S_NETWORK, name);
    add(g, tx::K_INTERFACE, iface);
    add(g, tx::K_KIND, nice(jstr(s, "hardware")));
    add(g, tx::K_IPV4, join(ips, ", "));
    add(g, tx::K_SUBNET, s["IPv4"]["SubnetMasks"][0].str());
    add(g, tx::K_ROUTER, jstr(s["IPv4"], "Router"));
    std::vector<std::string> dns;
    for (const auto& x : s["DNS"]["ServerAddresses"].a) dns.push_back(x.str());
    add(g, tx::K_DNS, join(dns, ", "));
    add(g, tx::K_CONFIG, jstr(s["IPv4"], "ConfigMethod"));
    add(g, tx::K_MAC, jstr(s["Ethernet"], "MAC Address"), true);
    if (r.net.empty()) r.net = name + " · " + ips[0];
  }
  if (!idle.empty()) r.group(S_NETWORK, tx::G_INACTIVE).rows = idle;
  // ---- los periféricos: USB (por bus) y Bluetooth
  const Json& usb = j["SPUSBHostDataType"].a.empty() ? j["SPUSBDataType"] : j["SPUSBHostDataType"];
  for (const auto& bus : usb.a) {
    Group g{jstr(bus, "_name"), {}};
    usb_walk(bus["_items"], g, 0);
    if (!g.rows.empty()) r.sec[S_DEVICES].push_back(g);
  }
  const Json& bt = j["SPBluetoothDataType"][0];
  if (bt.t == Json::OBJ) {
    const Json& c = bt["controller_properties"];
    {
      Group& g = r.group(S_DEVICES, tx::G_BLUETOOTH);
      add(g, tx::K_BT_ON, nice(jstr(c, "controller_state")));
      add(g, tx::K_CHIPSET, jstr(c, "controller_chipset"));
      add(g, tx::K_FIRMWARE, jstr(c, "controller_firmwareVersion"));
      add(g, tx::K_TRANSPORT, jstr(c, "controller_transport"));
      add(g, tx::K_MAC, jstr(c, "controller_address"), true);
    }
    auto devices = [&](const char* key, const char* title) {
      Group g{title, {}};
      for (const auto& item : bt[key].a)
        for (const auto& kv : item.o) {
          std::string v = join({nice(jstr(kv.second, "device_minorType")), jstr(kv.second, "device_batteryLevelMain")}, " · ");
          g.rows.push_back(Row{kv.first, v.empty() ? std::string(tx::NONE) : v});
        }
      if (!g.rows.empty()) r.sec[S_DEVICES].push_back(g);
    };
    devices("device_connected", tx::G_BT_CONNECTED);
    devices("device_not_connected", tx::G_BT_PAIRED);
  }
}

// Windows: la salida de PowerShell (ps_script), un objeto con una lista por clase.
std::vector<const Json*> items(const Json& j) {
  std::vector<const Json*> v;
  if (j.t == Json::ARR) {
    for (const auto& x : j.a)
      if (x.t == Json::OBJ) v.push_back(&x);
  } else if (j.t == Json::OBJ) v.push_back(&j);
  return v;
}
std::string smbios_memory(int code) {
  switch (code) {
    case 20: return "DDR";
    case 21: return "DDR2";
    case 24: return "DDR3";
    case 26: return "DDR4";
    case 29: return "LPDDR3";
    case 30: return "LPDDR4";
    case 34: return "DDR5";
    case 35: return "LPDDR5";
  }
  return "";
}
std::string link_speed(double bits) {
  if (bits <= 0) return "";
  if (bits >= 1e9) return num(bits / 1e9, std::fmod(bits, 1e9) == 0 ? 0 : 1) + " Gb/s";
  return num(bits / 1e6, 0) + " Mb/s";
}

void from_windows(Report& r, const Json& j) {
  for (const Json* c : items(j["cs"])) {
    std::string mk = jstr(*c, "Manufacturer"), md = jstr(*c, "Model");
    if (has(lower(mk), "o.e.m") || lower(mk) == "system manufacturer") mk.clear();
    r.model = trim(mk + " " + md);
    Group& g = r.group(S_BOARD, tx::G_MODEL);
    add(g, tx::K_MAKER, mk);
    add(g, tx::K_MODEL_NAME, md);
    add(g, tx::K_SYSTEM_TYPE, jstr(*c, "SystemType"));
  }
  for (const Json* o : items(j["os"])) {
    std::string cap = jstr(*o, "Caption");
    if (starts(cap, "Microsoft ")) cap = cap.substr(10);
    if (r.os.empty()) r.os = cap;
    if (r.sec[S_OS].empty()) continue;
    Group& g = r.sec[S_OS][0];
    add(g, tx::K_INSTALLED, jstr(*o, "InstallDate"));
    add(g, tx::K_OWNER, jstr(*o, "RegisteredUser"), true);
  }
  for (const Json* c : items(j["cpu"])) {
    if (r.sec[S_CPU].empty()) break;
    Group& g = r.sec[S_CPU][0];
    if (r.cpu.empty()) set_row(g, tx::K_MODEL, r.cpu = jstr(*c, "Name"));
    double mhz = (*c)["MaxClockSpeed"].num(0);
    if (mhz > 0) add(g, tx::K_MAX_FREQ, num(mhz / 1000, 2) + " GHz");
    add(g, tx::K_SOCKET, jstr(*c, "SocketDesignation"));
    std::string v = jstr(*c, "VirtualizationFirmwareEnabled");
    if (!v.empty()) set_row(g, tx::K_VIRT, nice(v));
    break;
  }
  for (const Json* b : items(j["board"])) {
    Group& g = r.group(S_BOARD, tx::G_BOARD);
    add(g, tx::K_MAKER, jstr(*b, "Manufacturer"));
    add(g, tx::K_PRODUCT, jstr(*b, "Product"));
    add(g, tx::K_VERSION, jstr(*b, "Version"));
    add(g, tx::K_SERIAL, jstr(*b, "SerialNumber"), true);
  }
  for (const Json* b : items(j["bios"])) {
    Group& g = r.group(S_BOARD, tx::G_FIRMWARE);
    add(g, tx::K_MAKER, jstr(*b, "Manufacturer"));
    add(g, tx::K_VERSION, jstr(*b, "SMBIOSBIOSVersion"));
    add(g, tx::K_DATE, jstr(*b, "Date"));
    add(g, tx::K_SERIAL, jstr(*b, "SerialNumber"), true);
  }
  for (const Json* m : items(j["ram"])) {
    std::string type = smbios_memory((int)(*m)["SMBIOSMemoryType"].num(0));
    Group& g = r.group(S_MEMORY, jstr(*m, "DeviceLocator").empty() ? std::string(tx::G_MODULES) : jstr(*m, "DeviceLocator"));
    double cap = (*m)["Capacity"].num(0);
    if (cap > 0) add(g, tx::K_SIZE, bytes(cap, true));
    add(g, tx::K_MEM_TYPE, type);
    double sp = (*m)["Speed"].num(0);
    if (sp > 0) add(g, tx::K_SPEED, num(sp, 0) + " MT/s");
    add(g, tx::K_MAKER, jstr(*m, "Manufacturer"));
    add(g, tx::K_PART, jstr(*m, "PartNumber"));
    if (r.memory_kind.empty()) r.memory_kind = type;
  }
  for (const Json* v : items(j["gpu"])) {
    std::string name = jstr(*v, "Name");
    Group& g = r.group(S_GRAPHICS, name);
    double ram = (*v)["AdapterRAM"].num(0);
    if (ram > 0) add(g, tx::K_VRAM, bytes(ram, true));
    add(g, tx::K_CHIP, jstr(*v, "VideoProcessor"));
    add(g, tx::K_DRIVER, jstr(*v, "DriverVersion"));
    int w = (int)(*v)["CurrentHorizontalResolution"].num(0), h = (int)(*v)["CurrentVerticalResolution"].num(0);
    int hz = (int)(*v)["CurrentRefreshRate"].num(0);
    std::string res = w > 0 ? std::to_string(w) + " x " + std::to_string(h) + (hz > 0 ? " @ " + std::to_string(hz) + " Hz" : "") : "";
    add(g, tx::K_RESOLUTION, res);
    if (r.gpu.empty()) r.gpu = name;
    if (!res.empty()) {
      if (r.display.empty()) r.display = res;
      r.displays++;
    }
  }
  bool physical = false;
  for (const Json* d : items(j["pdisk"])) {
    physical = true;
    Group& g = r.group(S_STORAGE, jstr(*d, "FriendlyName"));
    double size = (*d)["Size"].num(0);
    if (size > 0) add(g, tx::K_CAPACITY, bytes(size));
    std::string media = jstr(*d, "Media");
    add(g, tx::K_MEDIUM, media == "Unspecified" || media == "0" ? "" : nice(media));
    add(g, tx::K_PROTOCOL, jstr(*d, "Bus"));
    add(g, tx::K_HEALTH, nice(jstr(*d, "HealthStatus")));
    if (r.disk_kind.empty()) r.disk_kind = nice(media);
  }
  if (!physical)
    for (const Json* d : items(j["disk"])) {
      Group& g = r.group(S_STORAGE, jstr(*d, "Model"));
      double size = (*d)["Size"].num(0);
      if (size > 0) add(g, tx::K_CAPACITY, bytes(size));
      add(g, tx::K_PROTOCOL, jstr(*d, "InterfaceType"));
    }
  std::map<std::string, double> speeds;
  for (const Json* n : items(j["nic"])) speeds[jstr(*n, "Name")] = (*n)["Speed"].num(0);
  for (const Json* n : items(j["net"])) {
    std::string name = jstr(*n, "Description");
    std::vector<std::string> v4, gw, dns;
    for (const auto& x : (*n)["IPAddress"].a)
      if (has(x.str(), ".")) v4.push_back(x.str());
    for (const auto& x : (*n)["DefaultIPGateway"].a) gw.push_back(x.str());
    for (const auto& x : (*n)["DNSServerSearchOrder"].a) dns.push_back(x.str());
    Group& g = r.group(S_NETWORK, name);
    add(g, tx::K_IPV4, join(v4, ", "));
    add(g, tx::K_ROUTER, join(gw, ", "));
    add(g, tx::K_DNS, join(dns, ", "));
    add(g, tx::K_CONFIG, (*n)["DHCPEnabled"].b ? tx::DHCP : tx::MANUAL);
    add(g, tx::K_LINK_SPEED, link_speed(speeds[name]));
    add(g, tx::K_MAC, jstr(*n, "MACAddress"), true);
    if (r.net.empty() && !v4.empty()) r.net = name + " · " + v4[0];
  }
  for (const Json* b : items(j["bat"])) {
    Group& g = r.group(S_POWER, tx::G_BATTERY);
    r.laptop = true;
    int c = (int)(*b)["EstimatedChargeRemaining"].num(-1);
    if (c >= 0) {
      r.battery = c;
      add(g, tx::K_CHARGE, pct(c));
    }
    int st = (int)(*b)["BatteryStatus"].num(0);
    add(g, tx::K_STATE, st == 1 ? tx::DISCHARGING : st == 2 ? tx::SRC_AC : st == 3 ? tx::CHARGED : st >= 6 && st <= 9 ? tx::CHARGING : "");
    add(g, tx::K_NAME, jstr(*b, "Name"));
  }
  {
    Group g{tx::G_AUDIO_DEVICES, {}};
    for (const Json* s : items(j["snd"])) add(g, jstr(*s, "Name"), jstr(*s, "Manufacturer").empty() ? std::string(tx::NONE) : jstr(*s, "Manufacturer"));
    if (!g.rows.empty()) r.sec[S_AUDIO].push_back(g);
  }
  {
    Group g{tx::G_INPUT, {}};
    for (const Json* p : items(j["pnp"])) add(g, jstr(*p, "Name"), join({jstr(*p, "PNPClass"), jstr(*p, "Manufacturer")}, " · "));
    if (!g.rows.empty()) r.sec[S_DEVICES].push_back(g);
  }
}

// Los volúmenes de las lecturas en directo (Windows y Linux; macOS ya los da).
void add_volumes(Report& r, const std::vector<DiskUse>& disks) {
  for (const auto& d : disks) {
    Group& g = r.group(S_STORAGE, d.name + " (" + d.mount + ")");
    add(g, tx::K_FS, d.fs);
    add(g, tx::K_CAPACITY, bytes(d.total));
    if (d.total > 0) add(g, tx::K_FREE, bytes(d.free) + " (" + pct(100 * d.free / d.total) + ")");
    if (r.disk_total <= 0) {
      r.disk_name = d.name;
      r.disk_total = d.total;
      r.disk_free = d.free;
    }
  }
}

// El resumen y la limpieza: sin grupos vacíos.
void finish(Report& r) {
  Group g{tx::G_OVERVIEW, {}};
  add(g, tx::K_COMPUTER, r.computer);
  add(g, tx::K_MODEL, r.model);
  add(g, tx::K_OS, r.os);
  add(g, tx::K_CPU, join({r.cpu, r.cpu_detail}, " · "));
  if (r.mem_total > 0) add(g, tx::K_MEMORY, join({bytes(r.mem_total, true), r.memory_kind}, " "));
  add(g, tx::K_GPU, join({r.gpu, r.gpu_detail}, " · "));
  add(g, tx::K_DISPLAYS, r.display);
  if (r.disk_total > 0)
    add(g, tx::K_STORAGE, fmt(tx::DISK_SUMMARY, {join({r.disk_name, r.disk_kind}, " · "), bytes(r.disk_total), bytes(r.disk_free)}));
  add(g, tx::K_NETWORK, r.net);
  if (r.battery >= 0)
    add(g, tx::K_BATTERY, r.cycles >= 0 && r.health_max > 0
                              ? fmt(tx::BATTERY_SUMMARY, {pct(r.battery), std::to_string(r.cycles), pct(r.health_max)})
                              : pct(r.battery));
  r.sec[S_SUMMARY].assign(1, g);
  for (auto& s : r.sec) s.erase(std::remove_if(s.begin(), s.end(), [](const Group& x) { return x.rows.empty(); }), s.end());
  r.ready = true;
}

// Windows: lo que no da la API de Win32, con Get-CimInstance (en JSON). El
// guion va entre comillas dobles, así que dentro solo hay comillas simples.
const char* const PS_SCRIPT =
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;$ErrorActionPreference='SilentlyContinue';$o=[ordered]@{};"
    "$o.cs=Get-CimInstance Win32_ComputerSystem|Select-Object Manufacturer,Model,SystemType;"
    "$o.os=Get-CimInstance Win32_OperatingSystem|Select-Object Caption,RegisteredUser,@{n='InstallDate';e={$_.InstallDate.ToString('yyyy-MM-dd')}};"
    "$o.cpu=@(Get-CimInstance Win32_Processor|Select-Object Name,MaxClockSpeed,SocketDesignation,VirtualizationFirmwareEnabled);"
    "$o.board=Get-CimInstance Win32_BaseBoard|Select-Object Manufacturer,Product,Version,SerialNumber;"
    "$o.bios=Get-CimInstance Win32_BIOS|Select-Object Manufacturer,SMBIOSBIOSVersion,SerialNumber,@{n='Date';e={$_.ReleaseDate.ToString('yyyy-MM-dd')}};"
    "$o.ram=@(Get-CimInstance Win32_PhysicalMemory|Select-Object Capacity,Speed,Manufacturer,PartNumber,DeviceLocator,SMBIOSMemoryType);"
    "$o.gpu=@(Get-CimInstance Win32_VideoController|Select-Object Name,AdapterRAM,DriverVersion,VideoProcessor,CurrentHorizontalResolution,CurrentVerticalResolution,CurrentRefreshRate);"
    "$o.pdisk=@(Get-PhysicalDisk|Select-Object FriendlyName,Size,HealthStatus,@{n='Media';e={[string]$_.MediaType}},@{n='Bus';e={[string]$_.BusType}});"
    "$o.disk=@(Get-CimInstance Win32_DiskDrive|Select-Object Model,Size,InterfaceType);"
    "$o.net=@(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True'|Select-Object Description,MACAddress,IPAddress,DefaultIPGateway,DNSServerSearchOrder,DHCPEnabled);"
    "$o.nic=@(Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True'|Select-Object Name,Speed);"
    "$o.bat=@(Get-CimInstance Win32_Battery|Select-Object Name,EstimatedChargeRemaining,BatteryStatus);"
    "$o.snd=@(Get-CimInstance Win32_SoundDevice|Select-Object Name,Manufacturer);"
    "$o.pnp=@(Get-CimInstance Win32_PnPEntity|Where-Object{$_.Status -eq 'OK' -and $_.PNPClass -in 'Keyboard','Mouse','Camera','Image','Printer','Biometric','WPD'}|Select-Object Name,PNPClass,Manufacturer);"
    "$o|ConvertTo-Json -Depth 4 -Compress";

const char* const MAC_TYPES =
    "SPHardwareDataType SPSoftwareDataType SPDisplaysDataType SPMemoryDataType SPStorageDataType SPPowerDataType "
    "SPAudioDataType SPUSBHostDataType SPUSBDataType SPNetworkDataType SPBluetoothDataType";

// El análisis entero (tarda un par de segundos: se hace en otro hilo).
Report collect(const std::vector<DiskUse>& disks) {
  Report r;
  r.when = (long long)std::time(nullptr);
  Sys s = read_sys();
  base(r, s);
  std::string out;
  Json j;
#ifdef __APPLE__
  if (run(std::string("/usr/sbin/system_profiler -json ") + MAC_TYPES, out) && parse_json(out, j)) from_mac(r, j);
  r.source = "sysctl · system_profiler";
#elif defined(_WIN32)
  if (run(std::string("powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"") + PS_SCRIPT + "\"", out) &&
      parse_json(trim(out), j))
    from_windows(r, j);
  add_volumes(r, disks);
  r.source = "Win32 · PowerShell (CIM)";
#else
  (void)j;
  add_volumes(r, disks);
  r.source = "/proc";
#endif
  finish(r);
  return r;
}

// Lo que se mide ahora (va al final del resumen del informe).
Group live_group(const Report& r, const Live& L) {
  Group g{tx::G_NOW, {}};
  if (L.cpu >= 0) add(g, tx::K_CPU_USE, pct(L.cpu));
  if (L.mem_total > 0)
    add(g, tx::K_MEM_USE, fmt(tx::OF_TOTAL, {bytes(L.mem_used, true), bytes(L.mem_total, true)}) + " (" + pct(100 * L.mem_used / L.mem_total) + ")");
  if (r.boot > 0) add(g, tx::K_UPTIME, duration(r.when - r.boot));
  if (L.load[0] >= 0) add(g, tx::K_LOAD, num(L.load[0], 2) + " · " + num(L.load[1], 2) + " · " + num(L.load[2], 2));
  return g;
}

// ------------------------------------------------------------ el informe en texto
std::string report_text(const Report& r, const Live& L, bool secrets) {
  std::string o = std::string(tx::REPORT_TITLE) + "\n";
  o += std::string(40, '=') + "\n";
  o += join({r.computer, r.model, r.os}, " · ") + "\n";
  o += fmt(tx::GENERATED, {date_time(r.when)}) + "\n";
  for (int s = 0; s < S_COUNT; s++) {
    std::vector<Group> gs = r.sec[s];
    if (s == S_SUMMARY) gs.push_back(live_group(r, L));
    if (gs.empty()) continue;
    std::string t = section_title(s);
    o += "\n" + t + "\n" + std::string(t.size() > 40 ? 40 : t.size(), '-') + "\n";
    for (const auto& g : gs) {
      if (g.rows.empty()) continue;
      o += "\n  " + g.title + "\n";
      for (const auto& row : g.rows) o += "    " + trim(row.key) + ": " + shown(row, secrets) + "\n";
    }
  }
  return o;
}

// ------------------------------------------------------------ el informe en páginas
// Dibuja el informe en un PDF, en la impresora o en la pantalla (la vista de
// las capturas, con las hojas una al lado de otra). Sin nada donde dibujar,
// solo cuenta las páginas. Las medidas van en puntos (1/72 de pulgada).
const uint32_t P_TEXT = 0x1f2937, P_DIM = 0x6b7280, P_LINE = 0xe5e7eb, P_ZEBRA = 0xf3f4f6, P_ACCENT = 0x1d4ed8;
inline Fl_Color rgb(uint32_t v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void col(uint32_t v) { fl_color(rgb(v)); }

class Painter {
public:
  Fl_Paged_Device* dev = nullptr;   // el PDF o la impresora
  bool preview = false;             // en la pantalla: hojas una al lado de otra
  double k = 1;                     // escala de la vista
  int ox = 0, oy = 0, gap = 28, max_pages = 1000;
  int W = 523, H = 770, y = 0, page = 0;   // el área imprimible de un A4 con márgenes
  std::string head, foot;

  bool drawing() const { return (dev || preview) && page <= max_pages; }
  int X(double v) const { return ox + (preview ? (page - 1) * (iround((W + 72) * k) + gap) : 0) + iround(v * k); }
  int Y(double v) const { return oy + iround(v * k); }
  int S(double v) const { return std::max(1, iround(v * k)); }

  void begin_page() {
    page++;
    if (dev) {
      dev->begin_page();
      int w = 0, h = 0;
      if (dev->printable_rect(&w, &h) == 0 && w > 200 && h > 200) { W = w; H = h; }
    }
    if (preview && drawing()) {   // la hoja, con su sombra
      col(0xc4c9d2);
      fl_rectf(X(-36) + 3, Y(-36) + 5, S(W + 72), S(H + 72));
      col(0xffffff);
      fl_rectf(X(-36), Y(-36), S(W + 72), S(H + 72));
    }
    y = 0;
  }
  void end_page() {
    if (drawing()) {
      line(0, H - 20, W, P_LINE);
      text(foot, 0, H - 6, P_DIM, 8);
      std::string p = fmt(tx::PAGE_N, {std::to_string(page)});
      text(p, W - width(p, 8), H - 6, P_DIM, 8);
    }
    if (dev) dev->end_page();
  }
  // Si no cabe lo que viene, a la página siguiente (con su cabecera).
  void need(int h) {
    if (y + h <= H - 30) return;
    end_page();
    begin_page();
    text(head, 0, 9, P_DIM, 8);
    line(0, 15, W, P_LINE);
    y = 26;
  }
  void rect(double x, double yy, double w, double h, uint32_t c) {
    if (!drawing()) return;
    col(c);
    fl_rectf(X(x), Y(yy), S(w), S(h));
  }
  void line(double x, double yy, double w, uint32_t c) {
    if (!drawing()) return;
    col(c);
    fl_xyline(X(x), Y(yy), X(x + w));
  }
  void text(const std::string& s, double x, double yy, uint32_t c, int size, bool bold = false) {
    if (!drawing()) return;
    fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, S(size));
    col(c);
    fl_draw(s.c_str(), X(x), Y(yy));
  }
  double width(const std::string& s, int size, bool bold = false) {
    if (!drawing()) return 0;
    fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, S(size));
    return fl_width(s.c_str()) / k;
  }
  std::string fit(const std::string& s, double w, int size, bool bold = false) {
    if (!drawing() || width(s, size, bold) <= w) return s;
    std::string t = s;
    while (!t.empty()) {
      do t.pop_back(); while (!t.empty() && ((uint8_t)t.back() & 0xc0) == 0x80);
      if (width(t + "…", size, bold) <= w) return t + "…";
    }
    return "…";
  }
};

// El informe entero; devuelve las páginas.
int paint_report(Painter& p, const Report& r, const Live& L, bool secrets) {
  p.head = std::string(tx::REPORT_TITLE) + " · " + join({r.computer, r.model}, " · ");
  p.foot = std::string(tx::APP) + " · DMarlon Studio";
  p.begin_page();
  // La cabecera: el título, la fecha y el equipo.
  p.rect(0, 0, p.W, 62, P_ACCENT);
  p.text(tx::REPORT_TITLE, 16, 28, 0xffffff, 19, true);
  p.text(fmt(tx::GENERATED, {date_time(r.when)}), 16, 47, 0xdbeafe, 9);
  p.y = 86;
  p.text(p.fit(join({r.computer, r.model}, " · "), p.W, 14, true), 0, p.y, P_TEXT, 14, true);
  p.y += 16;
  p.text(p.fit(join({r.os, r.cpu}, " · "), p.W, 10), 0, p.y, P_DIM, 10);
  p.y += 22;
  const double KW = 170;   // el ancho de la columna de los datos
  for (int s = 0; s < S_COUNT; s++) {
    std::vector<Group> gs = r.sec[s];
    if (s == S_SUMMARY) gs.push_back(live_group(r, L));
    gs.erase(std::remove_if(gs.begin(), gs.end(), [](const Group& g) { return g.rows.empty(); }), gs.end());
    if (gs.empty()) continue;
    p.need(64);
    p.text(section_title(s), 0, p.y + 14, P_ACCENT, 13, true);
    p.line(0, p.y + 20, p.W, P_ACCENT);
    p.y += 30;
    for (const auto& g : gs) {
      p.need(18 + 13 * (int)std::min<size_t>(3, g.rows.size()));
      p.text(p.fit(g.title, p.W, 10, true), 0, p.y + 10, P_TEXT, 10, true);
      p.y += 16;
      for (size_t i = 0; i < g.rows.size(); i++) {
        const Row& row = g.rows[i];
        p.need(13);
        if (i % 2 == 0) p.rect(0, p.y, p.W, 13, P_ZEBRA);
        std::string key = row.key;
        size_t ind = key.find_first_not_of(' ');
        double dx = ind == std::string::npos ? 0 : ind * 2.0;   // la sangría del árbol USB
        p.text(p.fit(trim(key), KW - 10 - dx, 9), 6 + dx, p.y + 10, P_DIM, 9);
        p.text(p.fit(shown(row, secrets), p.W - KW - 12, 9), KW, p.y + 10, row.secret && !secrets ? P_DIM : P_TEXT, 9);
        p.y += 13;
      }
      p.y += 9;
    }
    p.y += 6;
  }
  p.end_page();
  return p.page;
}

// ------------------------------------------------------------ datos de ejemplo
// Un Mac y un PC inventados (con la forma exacta de system_profiler y de
// PowerShell): para las pruebas y para las capturas, que así no enseñan el
// equipo de quien las hace.
const char* const SAMPLE_MAC = R"JSON({
"SPHardwareDataType":[{"_name":"hardware_overview","activation_lock_status":"activation_lock_disabled","boot_rom_version":"13822.41.1","chip_type":"Apple M3 Pro","machine_model":"Mac15,6","machine_name":"MacBook Pro","model_number":"Z1AF0012KE/A","number_processors":"proc 12:6:6","os_loader_version":"13822.41.1","physical_memory":"18 GB","platform_UUID":"8E1F2A44-0B7C-5D21-9A3E-6C4B2F1D0E77","serial_number":"K7QX42LM9F"}],
"SPSoftwareDataType":[{"_name":"os_overview","boot_mode":"normal_boot","boot_volume":"Macintosh HD","kernel_version":"Darwin 25.1.0","local_host_name":"MacBook-Pro-de-Ana","os_version":"macOS 26.1 (25B78)","secure_vm":"secure_vm_enabled","system_integrity":"integrity_enabled","uptime":"up 3:04:12:09","user_name":"Ana García (ana)"}],
"SPMemoryDataType":[{"SPMemoryDataType":"18 GB","dimm_manufacturer":"Micron","dimm_type":"LPDDR5"}],
"SPDisplaysDataType":[{"_name":"Apple M3 Pro","spdisplays_mtlgpufamilysupport":"spdisplays_metal4","spdisplays_vendor":"sppci_vendor_Apple","sppci_bus":"spdisplays_builtin","sppci_cores":"18","sppci_model":"Apple M3 Pro","spdisplays_ndrvs":[
 {"_name":"Color LCD","_spdisplays_pixels":"3024 x 1964","_spdisplays_resolution":"1512 x 982 @ 120.00Hz","spdisplays_connection_type":"spdisplays_internal","spdisplays_display_type":"spdisplays_built-in-liquid-retina-xdr","spdisplays_mirror":"spdisplays_off","spdisplays_online":"spdisplays_yes"},
 {"_name":"DELL U2723QE","_spdisplays_display-week":21,"_spdisplays_display-year":2024,"_spdisplays_pixels":"3840 x 2160","_spdisplays_resolution":"1920 x 1080 @ 60.00Hz","spdisplays_main":"spdisplays_yes","spdisplays_mirror":"spdisplays_off","spdisplays_rotation":"spdisplays_supported"}]}],
"SPStorageDataType":[
 {"_name":"Macintosh HD","bsd_name":"disk3s1s1","file_system":"APFS","free_space_in_bytes":412785623040,"mount_point":"/","size_in_bytes":994662584320,"writable":"no","physical_drive":{"device_name":"APPLE SSD AP1024Z","is_internal_disk":"yes","medium_type":"ssd","protocol":"Apple Fabric","smart_status":"Verified"}},
 {"_name":"Data","file_system":"APFS","free_space_in_bytes":412785623040,"mount_point":"/System/Volumes/Data","size_in_bytes":994662584320},
 {"_name":"Fotos","file_system":"ExFAT","free_space_in_bytes":731406254080,"mount_point":"/Volumes/Fotos","size_in_bytes":2000189177856,"writable":"yes","physical_drive":{"device_name":"Extreme Pro 55AF","is_internal_disk":"no","medium_type":"ssd","protocol":"USB"}}],
"SPPowerDataType":[
 {"_name":"spbattery_information","sppower_battery_charge_info":{"sppower_battery_fully_charged":"FALSE","sppower_battery_is_charging":"TRUE","sppower_battery_state_of_charge":87},"sppower_battery_health_info":{"sppower_battery_cycle_count":142,"sppower_battery_health":"Good","sppower_battery_health_maximum_capacity":"96 %"},"sppower_battery_model_info":{"sppower_battery_device_name":"bq40z651","sppower_battery_firmware_version":"0b00"}},
 {"_name":"sppower_information","AC Power":{"Current Power Source":"TRUE","Display Sleep Timer":10,"LowPowerMode":"No","System Sleep Timer":0},"Battery Power":{"Display Sleep Timer":2,"LowPowerMode":"No","System Sleep Timer":1}},
 {"_name":"sppower_ac_charger_information","sppower_ac_charger_name":"96W USB-C Power Adapter","sppower_ac_charger_watts":"96","sppower_battery_charger_connected":"TRUE","sppower_battery_is_charging":"TRUE"}],
"SPAudioDataType":[{"_name":"coreaudio_device","_items":[
 {"_name":"Altavoces del MacBook Pro","coreaudio_default_audio_output_device":"spaudio_yes","coreaudio_device_manufacturer":"Apple Inc.","coreaudio_device_output":2,"coreaudio_device_srate":48000,"coreaudio_device_transport":"coreaudio_device_type_builtin"},
 {"_name":"Micrófono del MacBook Pro","coreaudio_default_audio_input_device":"spaudio_yes","coreaudio_device_input":1,"coreaudio_device_manufacturer":"Apple Inc.","coreaudio_device_srate":48000,"coreaudio_device_transport":"coreaudio_device_type_builtin"},
 {"_name":"DELL U2723QE","coreaudio_device_manufacturer":"DEL","coreaudio_device_output":2,"coreaudio_device_srate":48000,"coreaudio_device_transport":"coreaudio_device_type_displayport"}]}],
"SPNetworkDataType":[
 {"_name":"Wi-Fi","hardware":"AirPort","interface":"en0","ip_address":["192.168.1.34"],"DNS":{"ServerAddresses":["192.168.1.1","1.1.1.1"]},"Ethernet":{"MAC Address":"a4:83:e7:1c:52:9b"},"IPv4":{"ConfigMethod":"DHCP","Router":"192.168.1.1","SubnetMasks":["255.255.255.0"]},"type":"AirPort"},
 {"_name":"Thunderbolt Bridge","hardware":"Ethernet","interface":"bridge0","type":"Ethernet"},
 {"_name":"Ethernet USB","hardware":"Ethernet","interface":"en6","type":"Ethernet"}],
"SPUSBHostDataType":[{"_name":"USB 3.1 Bus","_items":[{"_name":"USB3.0 Hub","USBDeviceKeyLinkSpeed":"5 Gb/s","USBDeviceKeyVendorName":"VIA Labs, Inc.","_items":[
 {"_name":"Extreme Pro 55AF","USBDeviceKeyLinkSpeed":"5 Gb/s","USBDeviceKeyVendorName":"SanDisk"},
 {"_name":"Logitech BRIO","USBDeviceKeyLinkSpeed":"5 Gb/s","USBDeviceKeyVendorName":"Logitech"}]},
 {"_name":"Magic Keyboard","USBDeviceKeyLinkSpeed":"12 Mb/s","USBDeviceKeyVendorName":"Apple Inc."}]}],
"SPBluetoothDataType":[{"controller_properties":{"controller_chipset":"BCM_4388","controller_firmwareVersion":"22.1.534.4380","controller_state":"attrib_on","controller_transport":"PCIe","controller_address":"A4:83:E7:1C:52:9C"},
 "device_connected":[{"AirPods Pro":{"device_minorType":"Headphones","device_batteryLevelMain":"80%"}},{"MX Master 3S":{"device_minorType":"Mouse"}}],
 "device_not_connected":[{"Magic Trackpad":{"device_minorType":"Trackpad"}}]}]
})JSON";

const char* const SAMPLE_WIN = R"JSON({"cs":{"Manufacturer":"Dell Inc.","Model":"XPS 15 9530","SystemType":"x64-based PC"},
"os":{"Caption":"Microsoft Windows 11 Pro","RegisteredUser":"Ana","InstallDate":"2025-02-14"},
"cpu":[{"Name":"13th Gen Intel(R) Core(TM) i7-13700H","MaxClockSpeed":2400,"SocketDesignation":"U3E1","VirtualizationFirmwareEnabled":true}],
"board":{"Manufacturer":"Dell Inc.","Product":"0RPPY7","Version":"A00","SerialNumber":"/8KQ4LM3/CNWS20036H0123/"},
"bios":{"Manufacturer":"Dell Inc.","SMBIOSBIOSVersion":"1.14.0","SerialNumber":"8KQ4LM3","Date":"2025-06-10"},
"ram":[{"Capacity":17179869184,"Speed":4800,"Manufacturer":"SK Hynix","PartNumber":"HMCG78AGBSA095N  ","DeviceLocator":"DIMM A","SMBIOSMemoryType":34},
       {"Capacity":17179869184,"Speed":4800,"Manufacturer":"SK Hynix","PartNumber":"HMCG78AGBSA095N","DeviceLocator":"DIMM B","SMBIOSMemoryType":34}],
"gpu":[{"Name":"NVIDIA GeForce RTX 4060 Laptop GPU","AdapterRAM":4293918720,"DriverVersion":"32.0.15.6094","VideoProcessor":"NVIDIA GeForce RTX 4060 Laptop GPU","CurrentHorizontalResolution":null,"CurrentVerticalResolution":null},
       {"Name":"Intel(R) Iris(R) Xe Graphics","AdapterRAM":1073741824,"DriverVersion":"31.0.101.4502","CurrentHorizontalResolution":3456,"CurrentVerticalResolution":2160,"CurrentRefreshRate":60}],
"pdisk":[{"FriendlyName":"KIOXIA KXG80ZNV1T02","Size":1024209543168,"HealthStatus":"Healthy","Media":"SSD","Bus":"NVMe"}],
"disk":[{"Model":"KIOXIA KXG80ZNV1T02","Size":1024203640320,"InterfaceType":"SCSI"}],
"net":[{"Description":"Intel(R) Wi-Fi 6E AX211 160MHz","MACAddress":"8C:17:59:3A:4B:21","IPAddress":["192.168.1.50","fe80::1c2d:3e4f:5a6b:7c8d"],"DefaultIPGateway":["192.168.1.1"],"DNSServerSearchOrder":["192.168.1.1"],"DHCPEnabled":true}],
"nic":[{"Name":"Intel(R) Wi-Fi 6E AX211 160MHz","Speed":1201000000}],
"bat":[{"Name":"DELL M59JH35","EstimatedChargeRemaining":64,"BatteryStatus":2}],
"snd":[{"Name":"Realtek Audio","Manufacturer":"Realtek"},{"Name":"NVIDIA High Definition Audio","Manufacturer":"NVIDIA"}],
"pnp":[{"Name":"HID Keyboard Device","PNPClass":"Keyboard","Manufacturer":"(Standard keyboards)"},{"Name":"Integrated Webcam","PNPClass":"Camera","Manufacturer":"Microsoft"}]})JSON";

// El Mac de ejemplo, como si lo diera sysctl.
Sys sample_sys() {
  Sys s;
  s.cpu = "Apple M3 Pro";
  s.arch = "arm64";
  s.host = "MacBook-Pro-de-Ana";
  s.os_name = "macOS";
  s.os_version = "26.1";
  s.os_build = "25B78";
  s.kernel = "Darwin 25.1.0";
  s.virt = tx::YES;
  s.cores = s.threads = 12;
  s.p_cores = s.e_cores = 6;
  s.mem = 18.0 * 1024 * 1024 * 1024;
  s.l1i = 192 * 1024;
  s.l1d = 128 * 1024;
  s.l2 = 16 * 1024 * 1024;
  s.l2_e = 4 * 1024 * 1024;
  s.line = 128;
  s.boot = (long long)std::time(nullptr) - (3 * 86400 + 4 * 3600 + 12 * 60);
  return s;
}
Report sample_report() {
  Report r;
  r.when = (long long)std::time(nullptr);
  base(r, sample_sys());
  Json j;
  if (parse_json(SAMPLE_MAC, j)) from_mac(r, j);
  r.source = "sysctl · system_profiler";
  finish(r);
  return r;
}
// Un minuto de lecturas creíbles (para las capturas).
Live sample_live() {
  Live L;
  for (int i = 0; i < 60; i++) {
    double t = i / 59.0;
    push(L.cpu_hist, 18 + 14 * std::sin(i * 0.31) + 9 * std::sin(i * 0.11 + 1) + (i > 38 && i < 47 ? 30 * std::sin((i - 38) / 9.0 * 3.14159) : 0));
    push(L.mem_hist, 61 + 4 * t + 1.5 * std::sin(i * 0.2));
    push(L.down_hist, 1.8e6 + 1.4e6 * std::sin(i * 0.23) + (i > 20 && i < 30 ? 6e6 : 0));
    push(L.up_hist, 2.4e5 + 1.6e5 * std::sin(i * 0.37 + 2));
  }
  for (auto* d : {&L.cpu_hist, &L.down_hist, &L.up_hist})
    for (auto& v : *d) v = std::max(1.0, v);
  L.cpu = L.cpu_hist.back();
  const double cores[12] = {12, 9, 15, 7, 11, 8, 46, 33, 21, 58, 14, 27};
  L.cores.assign(cores, cores + 12);
  L.mem_total = 18.0 * 1024 * 1024 * 1024;
  L.mem_app = 7.6 * 1024 * 1024 * 1024;
  L.mem_wired = 2.3 * 1024 * 1024 * 1024;
  L.mem_compressed = 1.9 * 1024 * 1024 * 1024;
  L.mem_cached = 4.1 * 1024 * 1024 * 1024;
  L.mem_used = L.mem_app + L.mem_wired + L.mem_compressed;
  L.swap_used = 0.6 * 1024 * 1024 * 1024;
  L.swap_total = 2.0 * 1024 * 1024 * 1024;
  L.down = L.down_hist.back();
  L.up = L.up_hist.back();
  L.load[0] = 2.84;
  L.load[1] = 3.12;
  L.load[2] = 2.97;
  L.battery = 87;
  L.charging = true;
  L.disks = {{tx::STARTUP_DISK, "/", "apfs", 994662584320.0, 412785623040.0},
             {"Fotos", "/Volumes/Fotos", "exfat", 2000189177856.0, 731406254080.0}};
  return L;
}

// ------------------------------------------------------------ las pruebas internas
int selftest() {
  int f = 0;
  auto check = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  const std::string D(1, tx::DEC[0]);
  // 1. Los números.
  check(bytes(18.0 * 1024 * 1024 * 1024, true) == "18 GB" && bytes(512) == "512 B" && bytes(1.5e9) == "1" + D + "5 GB" &&
            bytes(994662584320.0) == "995 GB" && bytes(2000189177856.0) == "2 TB",
        "bytes");
  check(duration(90061) == fmt(tx::DUR_DH, {"1", "1"}) && duration(3720) == fmt(tx::DUR_HM, {"1", "2"}) && duration(59) == fmt(tx::DUR_M, {"0"}),
        "duration");
  check(nice("spdisplays_yes") == tx::YES && nice("attrib_off") == tx::NO && nice("spdisplays_supported") == tx::YES && nice("sppci_vendor_Apple") == "Apple" &&
            nice("spdisplays_metal4") == "Metal 4" && nice("coreaudio_device_type_hdmi") == "HDMI" && nice("ssd") == "SSD" &&
            nice("AirPort") == "Wi-Fi" && nice("Good") == tx::GOOD && nice("spdisplays_built-in-liquid-retina-xdr") == std::string("Liquid Retina XDR, ") + tx::BUILTIN,
        "nice");
  check(cores_text(12, 12, 6, 6) == fmt(tx::CORES_PE, {"12", "6", "6"}) && cores_text(8, 16, 0, 0) == fmt(tx::CORES_THREADS, {"8", "16"}),
        "cores");
  // 2. El Mac de ejemplo (system_profiler).
  Report m = sample_report();
  auto find = [](const Report& r, int s, const std::string& key) {
    for (const auto& g : r.sec[s])
      for (const auto& row : g.rows)
        if (row.key == key) return row;
    return Row{};
  };
  check(m.ready && m.model == "MacBook Pro" && m.computer == "MacBook-Pro-de-Ana" && m.os == "macOS 26.1", "mac model");
  check(m.gpu == "Apple M3 Pro" && m.gpu_detail == fmt(tx::GPU_CORES_N, {"18"}) && m.displays == 2 && has(m.display, "DELL U2723QE"), "mac displays");
  check(m.battery == 87 && m.cycles == 142 && m.health_max == 96 && m.battery_health == tx::GOOD && m.laptop, "mac battery");
  check(m.disk_name == "Macintosh HD" && m.disk_total > 9e11 && m.sec[S_STORAGE].size() == 2, "mac storage");
  check(m.memory_kind == "LPDDR5" && find(m, S_MEMORY, tx::K_MAKER).value == "Micron", "mac memory");
  check(has(m.net, "192.168.1.34") && find(m, S_NETWORK, tx::K_ROUTER).value == "192.168.1.1", "mac network");
  check(find(m, S_BOARD, tx::K_SERIAL).secret && find(m, S_NETWORK, tx::K_MAC).secret && find(m, S_OS, tx::K_USER).secret, "secrets");
  check(find(m, S_AUDIO, tx::K_SAMPLE_RATE).value == "48 kHz" && find(m, S_AUDIO, tx::K_CONNECTION).value == cap(tx::BUILTIN), "mac audio");
  check(m.sec[S_DEVICES].size() == 4 && find(m, S_DEVICES, "    Logitech BRIO").value == "Logitech · 5 Gb/s", "mac devices");
  check(find(m, S_CPU, tx::K_L2_E).value == "4 MB" && find(m, S_CPU, tx::K_L1I).value == fmt(tx::PER_CORE, {"192 KB"}), "mac caches");
  check(m.sec[S_SUMMARY].size() == 1 && m.sec[S_SUMMARY][0].rows.size() >= 9, "summary");
  // 3. El PC de ejemplo (PowerShell): objetos sueltos y listas.
  Report w;
  w.when = (long long)std::time(nullptr);
  Sys ws;
  ws.cpu = "13th Gen Intel(R) Core(TM) i7-13700H";
  ws.cores = 14;
  ws.threads = 20;
  ws.os_name = "Windows 11 Pro";
  ws.os_version = "24H2";
  ws.mem = 32.0 * 1024 * 1024 * 1024;
  base(w, ws);
  Json wj;
  check(parse_json(std::string("\xEF\xBB\xBF") + SAMPLE_WIN, wj), "win json");
  from_windows(w, wj);
  add_volumes(w, {{tx::LOCAL_DISK, "C:", "NTFS", 1.02e12, 3.1e11}});
  finish(w);
  check(w.model == "Dell Inc. XPS 15 9530" && w.os == "Windows 11 Pro 24H2", "win model");
  check(w.memory_kind == "DDR5" && w.sec[S_MEMORY].size() == 3 && find(w, S_MEMORY, tx::K_PART).value == "HMCG78AGBSA095N", "win memory");
  check(w.gpu == "NVIDIA GeForce RTX 4060 Laptop GPU" && w.display == "3456 x 2160 @ 60 Hz", "win gpu");
  check(w.battery == 64 && find(w, S_POWER, tx::K_STATE).value == tx::SRC_AC, "win battery");
  check(find(w, S_NETWORK, tx::K_IPV4).value == "192.168.1.50" && find(w, S_NETWORK, tx::K_LINK_SPEED).value == "1" + D + "2 Gb/s", "win network");
  check(w.disk_kind == "SSD" && w.disk_name == tx::LOCAL_DISK && find(w, S_BOARD, tx::K_SERIAL).secret, "win storage");
  check(find(w, S_CPU, tx::K_VIRT).value == tx::YES && find(w, S_DEVICES, "Integrated Webcam").value == "Camera · Microsoft", "win extra");
  // 4. El informe en texto: los números de serie, ocultos salvo que se pidan.
  Live L = sample_live();
  std::string t = report_text(m, L, false), ts = report_text(m, L, true);
  check(has(t, tx::S_GRAPHICS) && has(t, "Apple M3 Pro") && !has(t, "K7QX42LM9F") && has(t, tx::HIDDEN), "text hidden");
  check(has(ts, "K7QX42LM9F") && has(ts, "a4:83:e7:1c:52:9b"), "text shown");
  // 5. Las páginas (solo contarlas).
  Painter p;
  check(paint_report(p, m, L, false) >= 3, "pages");
  // 6. Las lecturas en directo de este equipo.
  Sampler sm;
  Live live;
  sm.sample(live, now_s());
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
  sm.sample(live, now_s());
  check(live.cpu >= 0 && live.cpu <= 100 && live.cpu_hist.size() == 1, "live cpu");
  check(live.mem_total > 0 && live.mem_used > 0 && live.mem_used <= live.mem_total * 1.05, "live memory");
  check(!live.disks.empty() && live.disks[0].total > 0 && live.down >= 0, "live disks and network");
  // 7. El análisis de verdad de este equipo.
  Report real = collect(live.disks);
  check(real.ready && !real.os.empty() && !real.cpu.empty() && real.mem_total > 0 && !real.sec[S_CPU].empty(), "real analysis");
  std::printf("selftest %s fails=%d\n", f ? "FAILED" : "ok", f);
  std::fflush(stdout);
  return f ? 1 : 0;
}

}  // namespace hw

// ============================================================ el panel
// Se dibuja en código: el resumen con sus tarjetas, las gráficas en directo
// y las tablas de cada sección. Un clic en un dato lo copia.
namespace hw {

const uint32_t C_BG = 0xffffff, C_TEXT = 0x1f2937, C_DIM = 0x6b7280, C_LINE = 0xe5e7eb, C_CARD = 0xf4f6fb,
               C_ACCENT = 0x2563eb, C_DARK = 0x1e3a8a, C_GOOD = 0x16a34a, C_WARN = 0xd97706, C_BAD = 0xdc2626,
               C_PURPLE = 0x8b5cf6, C_ORANGE = 0xf59e0b, C_SKY = 0x93c5fd;

struct Box {
  int x = 0, y = 0, w = 0, h = 0;
  bool has(int px, int py) const { return px >= x && py >= y && px < x + w && py < y + h; }
};

void text(const std::string& s, int x, int y, uint32_t c, int size = 13, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  col(c);
  fl_draw(s.c_str(), x, y);
}
int width(const std::string& s, int size = 13, bool bold = false) {
  fl_font(bold ? FL_HELVETICA_BOLD : FL_HELVETICA, size);
  return (int)fl_width(s.c_str());
}
std::string fit(const std::string& s, int w, int size = 13, bool bold = false) {
  if (width(s, size, bold) <= w) return s;
  std::string t = s;
  while (!t.empty()) {
    do t.pop_back(); while (!t.empty() && ((uint8_t)t.back() & 0xc0) == 0x80);
    if (width(t + "…", size, bold) <= w) return t + "…";
  }
  return "…";
}
void rbox(Box b, uint32_t c) { fl_draw_box(FL_RFLAT_BOX, b.x, b.y, b.w, b.h, rgb(c)); }
uint32_t mix(uint32_t a, uint32_t b, double t) {
  auto ch = [&](int s) { return (uint32_t)iround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t) << s; };
  return ch(16) | ch(8) | ch(0);
}
uint32_t level(double f) { return f > 0.9 ? C_BAD : f > 0.75 ? C_WARN : C_ACCENT; }
void bar(Box b, double f, uint32_t c) {
  rbox(b, 0xe2e6ee);
  f = std::max(0.0, std::min(1.0, f));
  if (f > 0) rbox({b.x, b.y, std::max(b.h, (int)(b.w * f)), b.h}, c);
}
// Una gráfica de un minuto: área y línea, con el valor más reciente a la derecha.
void chart(Box b, const std::deque<double>& v, double top, uint32_t c, bool area = true) {
  if (v.size() < 2 || top <= 0) return;
  const int slots = 60;
  double dx = (double)b.w / (slots - 1);
  int start = slots - (int)v.size();
  auto px = [&](int i) { return b.x + (start + i) * dx; };
  auto py = [&](double x) { return b.y + b.h - std::min(1.0, std::max(0.0, x / top)) * b.h; };
  if (area) {
    col(mix(c, 0xffffff, 0.82));
    fl_begin_complex_polygon();
    fl_vertex(px(0), b.y + b.h);
    for (size_t i = 0; i < v.size(); i++) fl_vertex(px((int)i), py(v[i]));
    fl_vertex(px((int)v.size() - 1), b.y + b.h);
    fl_end_complex_polygon();
  }
  col(c);
  fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, 2);
  fl_begin_line();
  for (size_t i = 0; i < v.size(); i++) fl_vertex(px((int)i), py(v[i]));
  fl_end_line();
  fl_line_style(0);
}
void grid(Box b, int lines) {
  col(C_LINE);
  for (int i = 0; i <= lines; i++) fl_xyline(b.x, b.y + b.h * i / lines, b.x + b.w);
}
double top_of(const std::deque<double>& a, const std::deque<double>& b) {
  double m = 1;
  for (double x : a) m = std::max(m, x);
  for (double x : b) m = std::max(m, x);
  return m * 1.15;
}

class ReportView : public Fl_Widget {
public:
  const Report* rep = nullptr;
  const Live* live = nullptr;
  int section = 0, dots = 0;
  bool secrets = false;
  int scroll = 0, content_h = 0, hover_x = -1, hover_y = -1;
  std::vector<std::pair<Box, std::string>> copies;   // clic: copia el valor
  std::vector<std::pair<Box, int>> navs;             // clic: va a la sección
  std::vector<std::pair<Box, std::string>> tips;     // al pasar por encima
  std::function<void(const std::string&)> on_copy;
  std::function<void(int)> on_nav;

  ReportView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void draw() override { render(x(), y(), w(), h()); }

  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE:
        hover_x = Fl::event_x();
        hover_y = Fl::event_y();
        redraw();
        return 1;
      case FL_LEAVE:
        hover_x = hover_y = -1;
        redraw();
        return 1;
      case FL_MOUSEWHEEL: {
        int maxs = std::max(0, content_h - h());
        scroll = clampi(scroll + Fl::event_dy() * 30, 0, maxs);
        redraw();
        return 1;
      }
      case FL_PUSH: click(Fl::event_x(), Fl::event_y()); return 1;
    }
    return Fl_Widget::handle(e);
  }
  void click(int px, int py) {
    for (const auto& n : navs)
      if (n.first.has(px, py)) { if (on_nav) on_nav(n.second); return; }
    for (const auto& c : copies)
      if (c.first.has(px, py)) { if (on_copy) on_copy(c.second); return; }
  }

  void render(int X, int Y, int W, int H) {
    copies.clear();
    navs.clear();
    tips.clear();
    fl_push_clip(X, Y, W, H);
    col(C_BG);
    fl_rectf(X, Y, W, H);
    const int P = 24;
    int x0 = X + P, w0 = W - 2 * P, y = Y + 18 - scroll;
    if (!rep || !rep->ready) {
      std::string s = std::string(tx::ANALYZING).substr(0, std::string(tx::ANALYZING).size() - std::strlen("…")) + std::string(dots % 4, '.');
      text(s, X + W / 2 - width(tx::ANALYZING, 16) / 2, Y + H / 2, C_DIM, 16);
      content_h = 0;
      fl_pop_clip();
      return;
    }
    text(section_title(section), x0, y + 24, C_TEXT, 22, true);
    y += 34;
    std::string sub = section == S_SUMMARY ? fmt(tx::ANALYZED_AT, {clock_time(rep->when), rep->source}) : join({rep->computer, rep->model}, " · ");
    text(fit(sub, w0, 13), x0, y + 14, C_DIM, 13);
    y += 30;
    const Live& L = *live;
    switch (section) {
      case S_SUMMARY: y = summary(x0, y, w0, L); break;
      case S_OS: y = uptime_card(x0, y, w0); break;
      case S_CPU: y = cpu_card(x0, y, w0, L); break;
      case S_MEMORY: y = memory_card(x0, y, w0, L); break;
      case S_STORAGE: y = disks_card(x0, y, w0, L); break;
      case S_NETWORK: y = net_card(x0, y, w0, L); break;
      case S_POWER: y = battery_card(x0, y, w0, L); break;
    }
    if (section != S_SUMMARY) {
      if (rep->sec[section].empty() && section != S_POWER) {
        text(tx::NOTHING_HERE, x0, y + 20, C_DIM, 14);
        y += 40;
      }
      y = groups(x0, y, w0, rep->sec[section]);
    }
    content_h = y + scroll - Y + 12;
    if (content_h > H) {   // la barra de desplazamiento
      int bh = std::max(30, H * H / content_h);
      int by = Y + (H - bh) * scroll / std::max(1, content_h - H);
      rbox({X + W - 7, by, 4, bh}, 0xc7ccd6);
    }
    for (const auto& t : tips)
      if (t.first.has(hover_x, hover_y)) tooltip(t.second, X, Y, W, H);
    fl_pop_clip();
  }

  void tooltip(const std::string& s, int X, int Y, int W, int H) {
    auto lines = split(s, '\n');
    int w = 0;
    for (const auto& l : lines) w = std::max(w, width(l, 12));
    Box b{hover_x + 14, hover_y + 16, w + 20, (int)lines.size() * 17 + 12};
    if (b.x + b.w > X + W - 4) b.x = hover_x - b.w - 10;
    if (b.y + b.h > Y + H - 4) b.y = hover_y - b.h - 10;
    rbox(b, 0x111827);
    for (size_t i = 0; i < lines.size(); i++) text(lines[i], b.x + 10, b.y + 19 + (int)i * 17, 0xffffff, 12);
  }

  // ---- las tablas: un grupo por tarjeta
  int groups(int x0, int y, int w0, const std::vector<Group>& gs) {
    const int RH = 26;
    int kw = std::min(280, w0 * 2 / 5);
    for (const auto& g : gs) {
      int h = 44 + (int)g.rows.size() * RH + 8;
      rbox({x0, y, w0, h}, C_CARD);
      text(fit(g.title, w0 - 32, 15, true), x0 + 16, y + 27, C_TEXT, 15, true);
      int ry = y + 42;
      for (const auto& r : g.rows) {
        Box rb{x0 + 8, ry, w0 - 16, RH};
        bool hidden = r.secret && !secrets;
        if (rb.has(hover_x, hover_y) && !hidden) rbox(rb, 0xe3eafb);
        size_t ind = r.key.find_first_not_of(' ');
        int dx = ind == std::string::npos ? 0 : (int)ind * 4;   // la sangría del árbol USB
        text(fit(trim(r.key), kw - 20 - dx, 13), x0 + 16 + dx, ry + 18, C_DIM, 13);
        std::string v = shown(r, secrets), fv = fit(v, w0 - kw - 40, 13);
        text(fv, x0 + kw, ry + 18, hidden ? C_DIM : C_TEXT, 13);
        if (hidden) tips.push_back({rb, tx::SECRET_HINT});
        else {
          copies.push_back({rb, r.value});
          tips.push_back({rb, fv != v ? v + "\n" + tx::CLICK_TO_COPY : std::string(tx::CLICK_TO_COPY)});
        }
        ry += RH;
      }
      y += h + 14;
    }
    return y;
  }

  // ---- el resumen
  void device_icon(int x, int y, bool laptop) {
    fl_line_style(FL_SOLID | FL_JOIN_ROUND, 3);
    col(0xffffff);
    if (laptop) {
      fl_rect(x + 8, y + 4, 56, 36);
      fl_line_style(FL_SOLID | FL_CAP_ROUND, 4);
      fl_line(x, y + 46, x + 72, y + 46);
    } else {
      fl_rect(x + 4, y, 64, 42);
      fl_line(x + 36, y + 42, x + 36, y + 50);
      fl_line(x + 22, y + 52, x + 50, y + 52);
    }
    fl_line_style(0);
  }
  Box card(int x, int y, int w, int h, const char* title, int target) {
    Box b{x, y, w, h};
    bool hov = b.has(hover_x, hover_y);
    rbox(b, hov ? 0xe9eefb : C_CARD);
    text(title, x + 16, y + 24, C_DIM, 12, true);
    navs.push_back({b, target});
    return b;
  }
  int summary(int x0, int y, int w0, const Live& L) {
    const Report& r = *rep;
    // El equipo.
    Box hero{x0, y, w0, 108};
    rbox(hero, C_DARK);
    device_icon(hero.x + 26, hero.y + 26, r.laptop);
    int tx0 = hero.x + 124, tw = w0 - 124 - 250;
    text(fit(r.computer, tw, 22, true), tx0, hero.y + 40, 0xffffff, 22, true);
    text(fit(r.model, tw, 14), tx0, hero.y + 64, 0xdbeafe, 14);
    text(fit(r.os, tw, 13), tx0, hero.y + 86, 0xbfdbfe, 13);
    if (r.boot > 0) {
      long long up = (long long)std::time(nullptr) - r.boot;
      std::string a = fmt(tx::UP_FOR, {duration(up)}), b = fmt(tx::SINCE_BOOT, {date_time(r.boot)});
      text(a, hero.x + w0 - 24 - width(a, 14, true), hero.y + 44, 0xffffff, 14, true);
      text(b, hero.x + w0 - 24 - width(b, 12), hero.y + 66, 0xbfdbfe, 12);
    }
    y += hero.h + 16;
    // Seis tarjetas: lo principal y cómo va ahora.
    const int G = 14, cw = (w0 - 2 * G) / 3, ch = 136;
    auto at = [&](int i) { return std::make_pair(x0 + (i % 3) * (cw + G), y + (i / 3) * (ch + G)); };
    {
      auto p = at(0);
      Box b = card(p.first, p.second, cw, ch, section_title(S_CPU), S_CPU);
      text(L.cpu >= 0 ? pct(L.cpu) : std::string(tx::WAITING), b.x + 16, b.y + 58, C_TEXT, 26, true);
      text(fit(r.cpu, cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
      text(fit(r.cpu_detail, cw - 32, 11), b.x + 16, b.y + 97, C_DIM, 11);
      chart({b.x + 16, b.y + 104, cw - 32, 24}, L.cpu_hist, 100, C_ACCENT);
    }
    {
      auto p = at(1);
      Box b = card(p.first, p.second, cw, ch, section_title(S_MEMORY), S_MEMORY);
      double f = L.mem_total > 0 ? L.mem_used / L.mem_total : 0;
      text(L.mem_total > 0 ? pct(100 * f) : std::string(tx::WAITING), b.x + 16, b.y + 58, C_TEXT, 26, true);
      text(fit(fmt(tx::OF_TOTAL, {bytes(L.mem_used, true), bytes(r.mem_total, true)}), cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
      text(fit(r.memory_kind, cw - 32, 11), b.x + 16, b.y + 97, C_DIM, 11);
      bar({b.x + 16, b.y + 110, cw - 32, 10}, f, level(f));
    }
    {
      auto p = at(2);
      Box b = card(p.first, p.second, cw, ch, section_title(S_GRAPHICS), S_GRAPHICS);
      text(fit(r.gpu.empty() ? std::string(tx::NONE) : r.gpu, cw - 32, 18, true), b.x + 16, b.y + 56, C_TEXT, 18, true);
      text(fit(r.gpu_detail, cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
      text(fit(r.display, cw - 32, 11), b.x + 16, b.y + 99, C_DIM, 11);
    }
    {
      auto p = at(3);
      Box b = card(p.first, p.second, cw, ch, section_title(S_STORAGE), S_STORAGE);
      double total = r.disk_total, fr = r.disk_free;
      for (const auto& d : L.disks)
        if (d.mount == "/" || d.mount == "C:") { total = d.total; fr = d.free; }
      double f = total > 0 ? 1 - fr / total : 0;
      text(total > 0 ? fmt(tx::FREE_N, {bytes(fr)}) : std::string(tx::NONE), b.x + 16, b.y + 58, C_TEXT, 24, true);
      text(fit(join({r.disk_name, r.disk_kind, total > 0 ? bytes(total) : ""}, " · "), cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
      bar({b.x + 16, b.y + 104, cw - 32, 10}, f, level(f));
    }
    {
      auto p = at(4);
      Box b = card(p.first, p.second, cw, ch, section_title(S_POWER), S_POWER);
      int bat = L.battery >= 0 ? L.battery : r.battery;
      if (bat >= 0) {
        text(pct(bat), b.x + 16, b.y + 58, C_TEXT, 26, true);
        std::string st = L.charging ? tx::CHARGING : L.on_ac ? tx::SRC_AC : tx::DISCHARGING;
        text(fit(st, cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
        if (r.cycles >= 0)
          text(fit(join({r.battery_health, fmt(tx::CYCLES_N, {std::to_string(r.cycles)})}, " · "), cw - 32, 11), b.x + 16, b.y + 97, C_DIM, 11);
        bar({b.x + 16, b.y + 110, cw - 32, 10}, bat / 100.0, bat < 20 ? C_BAD : C_GOOD);
      } else {
        text(tx::NONE, b.x + 16, b.y + 58, C_TEXT, 26, true);
        text(fit(tx::NO_BATTERY, cw - 32, 13), b.x + 16, b.y + 80, C_DIM, 13);
      }
    }
    {
      auto p = at(5);
      Box b = card(p.first, p.second, cw, ch, section_title(S_NETWORK), S_NETWORK);
      std::string down = "↓ " + rate(L.down), up = "↑ " + rate(L.up);
      text(down, b.x + 16, b.y + 56, C_ACCENT, 20, true);
      text(up, b.x + 16 + std::max(width(down, 20, true) + 18, (cw - 32) / 2), b.y + 56, C_GOOD, 20, true);
      text(fit(r.net, cw - 32, 13), b.x + 16, b.y + 80, C_TEXT, 13);
      double top = top_of(L.down_hist, L.up_hist);
      chart({b.x + 16, b.y + 96, cw - 32, 30}, L.down_hist, top, C_ACCENT);
      chart({b.x + 16, b.y + 96, cw - 32, 30}, L.up_hist, top, C_GOOD, false);
    }
    y += 2 * ch + G + 18;
    // El procesador en el último minuto.
    Box c{x0, y, w0, 190};
    rbox(c, C_CARD);
    text(tx::CPU_LAST_MIN, c.x + 16, c.y + 26, C_TEXT, 15, true);
    std::string now = L.cpu >= 0 ? pct(L.cpu) : std::string(tx::WAITING);
    text(now, c.x + c.w - 16 - width(now, 15, true), c.y + 26, C_ACCENT, 15, true);
    Box in{c.x + 52, c.y + 44, c.w - 68, c.h - 62};
    grid(in, 4);
    for (int i = 0; i <= 4; i++) {
      std::string l = pct(100 - i * 25);
      text(l, in.x - 8 - width(l, 10), in.y + in.h * i / 4 + 4, C_DIM, 10);
    }
    chart(in, L.cpu_hist, 100, C_ACCENT);
    return y + c.h + 14;
  }

  // ---- lo que se mide en directo en cada sección
  int uptime_card(int x0, int y, int w0) {
    if (rep->boot <= 0) return y;
    Box c{x0, y, w0, 84};
    rbox(c, C_CARD);
    text(fmt(tx::UP_FOR, {duration((long long)std::time(nullptr) - rep->boot)}), c.x + 16, c.y + 38, C_TEXT, 22, true);
    text(fmt(tx::SINCE_BOOT, {date_time(rep->boot)}), c.x + 16, c.y + 62, C_DIM, 13);
    return y + c.h + 14;
  }
  int cpu_card(int x0, int y, int w0, const Live& L) {
    Box c{x0, y, w0, 200};
    rbox(c, C_CARD);
    text(tx::CPU_NOW, c.x + 16, c.y + 26, C_DIM, 12, true);
    text(L.cpu >= 0 ? pct(L.cpu) : std::string(tx::WAITING), c.x + 16, c.y + 64, C_TEXT, 34, true);
    if (L.load[0] >= 0) {
      text(fit(tx::K_LOAD, 190, 11), c.x + 16, c.y + 92, C_DIM, 11);
      text(num(L.load[0], 2) + " · " + num(L.load[1], 2) + " · " + num(L.load[2], 2), c.x + 16, c.y + 110, C_TEXT, 13);
    }
    Box in{c.x + 220, c.y + 20, c.w - 236, c.h - 40};
    grid(in, 4);
    chart(in, L.cpu_hist, 100, C_ACCENT);
    y += c.h + 14;
    if (L.cores.empty()) return y;
    // Cada núcleo (en los chips de Apple, primero los de eficiencia).
    int n = (int)L.cores.size();
    Box k{x0, y, w0, 170};
    rbox(k, C_CARD);
    text(tx::CPU_CORES, k.x + 16, k.y + 26, C_TEXT, 15, true);
    int gap = 8, bw = std::min(44, (k.w - 32 - gap * (n - 1)) / std::max(1, n));
    int bx = k.x + 16, by = k.y + 44, bh = 90;
    for (int i = 0; i < n; i++) {
      double f = L.cores[i] / 100;
      Box b{bx + i * (bw + gap), by, bw, bh};
      rbox(b, 0xe2e6ee);
      int fh = std::max(4, (int)(bh * f));
      bool e = rep->e_cores > 0 && i < rep->e_cores;
      rbox({b.x, b.y + bh - fh, bw, fh}, e ? C_PURPLE : level(f));
      std::string lab = rep->e_cores > 0 ? (e ? "E" + std::to_string(i + 1) : "P" + std::to_string(i + 1 - rep->e_cores)) : std::to_string(i + 1);
      text(lab, b.x + bw / 2 - width(lab, 11) / 2, by + bh + 16, C_DIM, 11);
      std::string v = num(L.cores[i], 0);
      text(v, b.x + bw / 2 - width(v, 10) / 2, by + bh + 30, C_TEXT, 10);
      tips.push_back({b, lab + ": " + pct(L.cores[i])});
    }
    return y + k.h + 14;
  }
  int memory_card(int x0, int y, int w0, const Live& L) {
    if (L.mem_total <= 0) return y;
    Box c{x0, y, w0, 230};
    rbox(c, C_CARD);
    text(tx::MEM_NOW, c.x + 16, c.y + 26, C_DIM, 12, true);
    text(fmt(tx::OF_TOTAL, {bytes(L.mem_used, true), bytes(L.mem_total, true)}), c.x + 16, c.y + 60, C_TEXT, 26, true);
    // La barra por partes: apps, fija, comprimida, caché y libre.
    Box b{c.x + 16, c.y + 76, c.w - 32, 18};
    rbox(b, 0xe2e6ee);
    struct Part { double v; uint32_t c; const char* name; };
    std::vector<Part> parts;
    if (L.mem_wired > 0 || L.mem_compressed > 0)
      parts = {{L.mem_app, C_ACCENT, tx::MEM_APP}, {L.mem_wired, C_ORANGE, tx::MEM_WIRED}, {L.mem_compressed, C_PURPLE, tx::MEM_COMPRESSED}, {L.mem_cached, C_SKY, tx::MEM_CACHED}};
    else
      parts = {{L.mem_used, C_ACCENT, tx::K_MEM_USE}};
    double x = b.x, used = 0;
    for (const auto& p : parts) {
      int w = (int)(b.w * p.v / L.mem_total);
      if (w > 0) { col(p.c); fl_rectf((int)x, b.y, w, b.h); }
      x += w;
      used += p.v;
    }
    int lx = c.x + 16, ly = c.y + 118;
    parts.push_back({std::max(0.0, L.mem_total - used), 0xe2e6ee, tx::MEM_FREE});
    for (const auto& p : parts) {
      rbox({lx, ly - 10, 12, 12}, p.c);
      std::string s = std::string(p.name) + " " + bytes(p.v, true);
      text(s, lx + 18, ly, C_TEXT, 12);
      lx += width(s, 12) + 34;
    }
    if (L.swap_total > 0) text(fmt(tx::MEM_SWAP, {bytes(L.swap_used, true), bytes(L.swap_total, true)}), c.x + 16, ly + 24, C_DIM, 12);
    Box in{c.x + 16, c.y + 152, c.w - 32, 62};
    grid(in, 2);
    chart(in, L.mem_hist, 100, C_ACCENT);
    return y + c.h + 14;
  }
  int disks_card(int x0, int y, int w0, const Live& L) {
    if (L.disks.empty()) return y;
    int h = 40 + (int)L.disks.size() * 54;
    Box c{x0, y, w0, h};
    rbox(c, C_CARD);
    text(tx::DISKS_NOW, c.x + 16, c.y + 26, C_TEXT, 15, true);
    int dy = c.y + 44;
    for (const auto& d : L.disks) {
      double f = d.total > 0 ? 1 - d.free / d.total : 0;
      text(fit(d.name + "  (" + d.mount + ")", w0 / 2, 13, true), c.x + 16, dy + 14, C_TEXT, 13, true);
      std::string s = fmt(tx::FREE_N, {bytes(d.free)}) + " · " + fmt(tx::OF_TOTAL, {bytes(d.total - d.free), bytes(d.total)});
      text(s, c.x + c.w - 16 - width(s, 12), dy + 14, C_DIM, 12);
      bar({c.x + 16, dy + 22, c.w - 32, 12}, f, level(f));
      dy += 54;
    }
    return y + h + 14;
  }
  int net_card(int x0, int y, int w0, const Live& L) {
    Box c{x0, y, w0, 190};
    rbox(c, C_CARD);
    text(tx::NET_NOW, c.x + 16, c.y + 26, C_DIM, 12, true);
    text(tx::NET_DOWN, c.x + 16, c.y + 54, C_DIM, 12);
    text(rate(L.down), c.x + 16, c.y + 80, C_ACCENT, 24, true);
    text(tx::NET_UP, c.x + 16, c.y + 112, C_DIM, 12);
    text(rate(L.up), c.x + 16, c.y + 138, C_GOOD, 24, true);
    Box in{c.x + 220, c.y + 20, c.w - 236, c.h - 40};
    grid(in, 4);
    double top = top_of(L.down_hist, L.up_hist);
    chart(in, L.down_hist, top, C_ACCENT);
    chart(in, L.up_hist, top, C_GOOD, false);
    return y + c.h + 14;
  }
  int battery_card(int x0, int y, int w0, const Live& L) {
    int bat = L.battery >= 0 ? L.battery : rep->battery;
    Box c{x0, y, w0, 110};
    rbox(c, C_CARD);
    text(tx::BATTERY_NOW, c.x + 16, c.y + 26, C_DIM, 12, true);
    if (bat < 0) {
      text(tx::NO_BATTERY, c.x + 16, c.y + 64, C_TEXT, 18, true);
      return y + c.h + 14;
    }
    // Una pila: el cuerpo, el borne y la carga.
    Box body{c.x + 16, c.y + 42, 120, 50};
    fl_line_style(FL_SOLID, 3);
    col(C_TEXT);
    fl_rect(body.x, body.y, body.w, body.h);
    fl_line_style(0);
    fl_rectf(body.x + body.w + 1, body.y + 16, 6, 18);
    int fw = (int)((body.w - 10) * bat / 100.0);
    col(bat < 20 ? C_BAD : C_GOOD);
    fl_rectf(body.x + 5, body.y + 5, std::max(2, fw), body.h - 10);
    text(pct(bat), c.x + 160, c.y + 76, C_TEXT, 30, true);
    std::string st = L.charging ? tx::CHARGING : L.on_ac ? tx::SRC_AC : tx::DISCHARGING;
    text(st, c.x + 280, c.y + 72, C_DIM, 14);
    return y + c.h + 14;
  }
};

}  // namespace hw

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  hw::Report report;
  hw::Live live;
  hw::Sampler sampler;
  hw::ReportView* view = nullptr;
  bool secrets = false, live_on = true, sync = false, busy = false;
  std::string message;
  double message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_HW_SELFTEST")) std::exit(hw::selftest());
    if (fl_getenv("DMS_HW_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_HW_SHOT")) { set_fonts(); std::exit(shots(d)); }
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

  // ---- montar la ventana (también para las pruebas y las capturas)
  void setup() {
    self() = this;
    ResultsHint->hide();   // el aviso del Diseñador
    Results->box(FL_FLAT_BOX);
    Side->resizable(nullptr);
    resizable(Results);
    view = new hw::ReportView(Results->x(), Results->y(), Results->w(), Results->h());
    Results->add(view);
    Results->resizable(view);
    view->rep = &report;
    view->live = &live;
    view->on_copy = [](const std::string& v) { if (self()) self()->copy_value(v); };
    view->on_nav = [](int s) { if (self()) self()->select(s); };
    std::vector<std::string> names;
    for (int s = 0; s < hw::S_COUNT; s++) names.push_back(hw::section_title(s));
    Sections->items(names);
    Sections->textsize(14);
    mark(tx::MP_REFRESH, 0, false, FL_COMMAND + 'r');
    mark(tx::MP_PDF, 0, false, FL_COMMAND + 's');
    mark(tx::MP_PRINT, 0, false, FL_COMMAND + 'p');
    mark(tx::MP_QUIT, 0, false, FL_COMMAND + 'q');
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // para que el análisis (en otro hilo) avise a la ventana
#ifdef _WIN32
    SetErrorMode(SEM_FAILCRITICALERRORS);   // sin avisos de «no hay disco» en las unidades vacías
#endif
    setup();
    load();
    sync_menu();
    sampler.sample(live, hw::now_s());
    select(0);
    refresh();
    size_range(980, 640);
    if (fl_getenv("DMS_HW_SMOKE")) Fl::add_timeout(4.0, smoke, this);
  }
  void form_close() override { save(); }

  // ---- el análisis (en otro hilo: system_profiler y PowerShell tardan)
  void refresh() {
    if (busy) return;
    busy = true;
    report.ready = false;
    update_side();
    view->redraw();
    if (sync) {
      finish(new hw::Report(hw::collect(live.disks)));
      return;
    }
    std::vector<hw::DiskUse> disks = live.disks;
    std::thread([disks] {
      auto* r = new hw::Report(hw::collect(disks));
      Fl::awake(done, r);
    }).detach();
  }
  static void done(void* p) {
    auto* r = static_cast<hw::Report*>(p);
    if (self()) self()->finish(r);
    else delete r;
  }
  void finish(hw::Report* r) {
    report = std::move(*r);
    delete r;
    busy = false;
    update_side();
    view->redraw();
  }
  void update_side() {
    LblComputer->text(report.ready ? report.computer : std::string(tx::ANALYZING));
    LblModel->text(report.ready ? hw::join({report.model, report.os}, "\n") : std::string());
    update_status();
  }
  void update_status() {
    if (!message.empty() && hw::now_s() < message_until) { Status->text(" " + message); return; }
    message.clear();
    if (!report.ready) { Status->text(std::string(" ") + tx::ANALYZING); return; }
    Status->text(" " + hw::fmt(tx::STATUS, {live_on ? tx::STATUS_LIVE : tx::STATUS_PAUSED, hw::clock_time(report.when)}));
  }
  void set_message(const std::string& m) {
    message = m;
    message_until = hw::now_s() + 4;
    update_status();
  }

  // ---- cada segundo: las lecturas en directo
  void Tick_timer() override {
    if (live_on) sampler.sample(live, hw::now_s());
    view->dots++;
    update_status();
    view->redraw();
  }

  void select(int s, bool list = true) {
    s = hw::clampi(s, 0, hw::S_COUNT - 1);
    if (list) Sections->index(s);
    view->section = s;
    view->scroll = 0;
    view->redraw();
  }
  void Sections_select() override {
    int i = Sections->index();
    if (i >= 0) select(i, false);
  }
  void copy_value(const std::string& v) {
    Fl::copy(v.c_str(), (int)v.size(), 1);
    set_message(hw::fmt(tx::COPIED, {v}));
  }

  void BtnRefresh_click() override { refresh(); }
  void BtnPdf_click() override { save_pdf(); }
  void BtnPrint_click() override { print(); }

  // ---- el informe: PDF, impresora, texto y portapapeles
  std::string file_name(const char* ext) const {
    std::string n = std::string(tx::REPORT_FILE) + " - " + (report.computer.empty() ? std::string("PC") : report.computer) + " - " +
                    hw::time_text(report.when, "%Y-%m-%d") + ext;
    for (auto& c : n)
      if (c == '/' || c == '\\' || c == ':') c = '-';
    return n;
  }
  std::string ask_path(const char* title, const char* filter, const char* ext) {
    Fl_Native_File_Chooser fc;
    fc.title(title);
    fc.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    fc.filter(filter);
    fc.preset_file(file_name(ext).c_str());
    fc.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM | Fl_Native_File_Chooser::USE_FILTER_EXT);
    if (fc.show() != 0 || !fc.filename()) return "";
    std::string p = fc.filename();
    if (p.size() < 4 || hw::lower(p.substr(p.size() - 4)) != ext) p += ext;
    return p;
  }
  bool export_pdf(const std::string& path, std::string& err) {
    Fl_PDF_File_Surface pdf;
    char* e = nullptr;
    auto paper = std::string(tx::LOCALE) == "en-US" ? Fl_Paged_Device::LETTER : Fl_Paged_Device::A4;
    if (pdf.begin_document(path.c_str(), paper, Fl_Paged_Device::PORTRAIT, &e) != 0) {
      err = e ? e : "?";
      delete[] e;
      return false;
    }
    hw::Painter p;
    p.dev = &pdf;
    hw::paint_report(p, report, live, secrets);
    pdf.end_job();
    return true;
  }
  void save_pdf() {
    if (!report.ready) return;
    std::string path = ask_path(tx::L_PDF, (std::string(tx::PDF_FILTER) + "\t*.pdf").c_str(), ".pdf");
    if (path.empty()) return;
    std::string err;
    if (!export_pdf(path, err)) {
      fl_message_title(tx::APP);
      fl_alert("%s", hw::fmt(tx::ERR_PDF, {err}).c_str());
      return;
    }
    set_message(hw::fmt(tx::SAVED_PDF, {fl_filename_name(path.c_str())}));
    fl_message_title(tx::APP);
    if (fl_choice("%s", tx::CLOSE, tx::OPEN, nullptr, tx::OPEN_PDF) == 1) fl_open_uri(("file://" + path).c_str());
  }
  void print() {
    if (!report.ready) return;
    Fl_Printer printer;
    int from = 1, to = 1;
    char* e = nullptr;
    int r = printer.begin_job(0, &from, &to, &e);
    if (r == 1) return;   // cancelado
    if (r != 0) {
      fl_message_title(tx::APP);
      fl_alert("%s", hw::fmt(tx::ERR_PRINT, {e ? e : "?"}).c_str());
      delete[] e;
      return;
    }
    hw::Painter p;
    p.dev = &printer;
    hw::paint_report(p, report, live, secrets);
    printer.end_job();
  }
  bool save_text_to(const std::string& path) { return hw::write_file(path, hw::report_text(report, live, secrets)); }
  void save_text() {
    if (!report.ready) return;
    std::string path = ask_path(tx::L_TXT, (std::string(tx::TXT_FILTER) + "\t*.txt").c_str(), ".txt");
    if (path.empty()) return;
    if (!save_text_to(path)) {
      fl_message_title(tx::APP);
      fl_alert("%s", hw::fmt(tx::ERR_SAVE, {path}).c_str());
      return;
    }
    set_message(hw::fmt(tx::SAVED_TXT, {fl_filename_name(path.c_str())}));
  }
  void copy_report() {
    if (!report.ready) return;
    std::string t = hw::report_text(report, live, secrets);
    Fl::copy(t.c_str(), (int)t.size(), 1);
    set_message(tx::COPIED_REPORT);
  }

  // ---- el menú
  void mark(const char* path, int flags, bool on, int shortcut = 0) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    Menu1->mode(i, (Menu1->mode(i) & FL_MENU_DIVIDER) | flags | (on ? FL_MENU_VALUE : 0));
    if (shortcut) Menu1->shortcut(i, shortcut);
  }
  void sync_menu() {
    mark(tx::MP_SERIALS, FL_MENU_TOGGLE, secrets);
    mark(tx::MP_LIVE, FL_MENU_TOGGLE, live_on);
    view->secrets = secrets;
    Menu1->redraw();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_REFRESH) refresh();
    else if (item == tx::MP_PDF) save_pdf();
    else if (item == tx::MP_PRINT) print();
    else if (item == tx::MP_TXT) save_text();
    else if (item == tx::MP_COPY) copy_report();
    else if (item == tx::MP_QUIT) {
      save();
      hide();
    } else if (item == tx::MP_SERIALS) secrets = !secrets;
    else if (item == tx::MP_LIVE) live_on = !live_on;
    else if (item == tx::MP_HOW) {
      fl_message_title(tx::L_HOW);
      fl_message("%s", tx::HOW_TEXT);
    } else if (item == tx::MP_ABOUT) {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", hw::fmt(tx::ABOUT_TEXT, {v}).c_str());
    }
    sync_menu();
    update_status();
    view->redraw();
    if (item == tx::MP_SERIALS || item == tx::MP_LIVE) save();
  }

  // ---- guardar las preferencias
  std::string settings_file() const { return hw::config_dir() + "/settings.txt"; }
  void load() {
    std::string t;
    if (!hw::read_file(settings_file(), t)) return;
    for (const auto& l : hw::split(t, '\n')) {
      if (l == "secrets=1") secrets = true;
      if (l == "live=0") live_on = false;
    }
  }
  void save() {
    if (sync) return;
    fl_make_path(hw::config_dir().c_str());
    hw::write_file(settings_file(), std::string("secrets=") + (secrets ? "1" : "0") + "\nlive=" + (live_on ? "1" : "0") + "\n");
  }

  // ---- sin ventana: la interfaz entera dibujada en una imagen
  void render_to(const std::string& file) {
    Fl_Image_Surface surf(w(), h(), 0);
    Fl_Surface_Device::push_current(&surf);
    fl_color(color());
    fl_rectf(0, 0, w(), h());
    // Una ventana sin mostrar no se dibuja: se dibuja cada hijo en su sitio.
    for (int i = 0; i < children(); i++) {
      Fl_Widget* c = child(i);
      if (c->visible()) surf.draw(c, c->x(), c->y());
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    if (!file.empty()) fl_write_png(file.c_str(), img);
    delete img;
  }
  // El Mac de ejemplo, con un minuto de lecturas.
  void demo_state(int W, int H) {
    sync = true;
    setup();
    size(W, H);
    report = hw::sample_report();
    live = hw::sample_live();
    update_side();
    select(0);
  }
  int shots(const std::string& dir) {
    Fl::screen_count();
    int W = 1240, H = 820;
    if (const char* s = fl_getenv("DMS_HW_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
    demo_state(W, H);
    view->hover_x = view->hover_y = -1;
    render_to(dir + "/resumen.png");
    select(hw::S_CPU);
    render_to(dir + "/procesador.png");
    select(hw::S_MEMORY);
    render_to(dir + "/memoria.png");
    select(hw::S_GRAPHICS);
    render_to(dir + "/graficos.png");
    select(hw::S_STORAGE);
    render_to(dir + "/almacenamiento.png");
    // Las dos primeras hojas del informe, como en el PDF.
    {
      Fl_Image_Surface surf(W, H, 0);
      Fl_Surface_Device::push_current(&surf);
      hw::col(0xdfe3ea);
      fl_rectf(0, 0, W, H);
      hw::Painter p;
      p.preview = true;
      p.max_pages = 2;
      p.k = std::min((W - 3.0 * p.gap) / (2 * (p.W + 72.0)), (H - 40.0) / (p.H + 72.0));
      p.ox = (int)((W - 2 * (p.W + 72) * p.k - p.gap) / 2 + 36 * p.k);
      p.oy = (int)((H - (p.H + 72) * p.k) / 2 + 36 * p.k);
      hw::paint_report(p, report, live, false);
      Fl_RGB_Image* img = surf.image();
      Fl_Surface_Device::pop_current();
      fl_write_png((dir + "/informe.png").c_str(), img);
      delete img;
    }
    std::string err;
    export_pdf(dir + "/informe.pdf", err);
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }

  // ---- la interfaz sin ventana: cada sección, copiar, el PDF y el texto
  int ui_test() {
    Fl::screen_count();
    demo_state(1180, 760);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(report.ready && report.model == "MacBook Pro" && LblComputer->text() == "MacBook-Pro-de-Ana", "demo report");
    chk(Sections->size() == hw::S_COUNT, "sections list");
    for (int s = 0; s < hw::S_COUNT; s++) {
      Sections->index(s);
      Sections_select();
      render_to("");
      chk(view->section == s && view->content_h > 100, "section drawn");
      chk(s == hw::S_SUMMARY || !report.sec[s].empty(), "section data");
      view->scroll = 100000;
      render_to("");
    }
    // El resumen: cada tarjeta lleva a su sección.
    select(hw::S_SUMMARY);
    render_to("");
    chk(view->navs.size() == 6, "summary cards");
    if (view->navs.size() == 6) {
      hw::Box b = view->navs[1].first;
      view->click(b.x + 5, b.y + 5);
      chk(view->section == hw::S_MEMORY && Sections->index() == hw::S_MEMORY, "card navigation");
    }
    // Un clic en un dato lo copia; los números de serie, ocultos, no.
    select(hw::S_BOARD);
    render_to("");
    chk(!view->copies.empty(), "copy targets");
    for (const auto& c : view->copies) chk(c.second != "K7QX42LM9F", "serial not copyable");
    if (!view->copies.empty()) {
      view->click(view->copies[0].first.x + 4, view->copies[0].first.y + 4);
      chk(hw::starts(message, hw::fmt(tx::COPIED, {""})), "copied");
    }
    Menu1_click(tx::MP_SERIALS);
    render_to("");
    bool serial = false;
    for (const auto& c : view->copies) serial = serial || c.second == "K7QX42LM9F";
    chk(secrets && serial, "serial shown");
    Menu1_click(tx::MP_SERIALS);
    chk(!secrets, "serial hidden again");
    Menu1_click(tx::MP_LIVE);
    chk(!live_on, "live off");
    Menu1_click(tx::MP_LIVE);
    // El PDF y el texto.
    std::string dir = hw::config_dir();
    fl_make_path(dir.c_str());
    std::string pdf = dir + "/informe.pdf", err, data;
    chk(export_pdf(pdf, err) && hw::read_file(pdf, data), "pdf written");
    chk(hw::starts(data, "%PDF") && data.size() > 4000, "pdf content");
    size_t pages = 0;
    for (size_t p = data.find("/Type /Page"); p != std::string::npos; p = data.find("/Type /Page", p + 1))
      if (data.compare(p, 12, "/Type /Pages") != 0) pages++;
    chk(pages >= 3, "pdf pages");
    std::string txt = dir + "/informe.txt";
    chk(save_text_to(txt) && hw::read_file(txt, data) && hw::has(data, tx::S_GRAPHICS) && !hw::has(data, "K7QX42LM9F"), "text file");
    // El análisis de verdad de este equipo, y sus lecturas.
    sampler.sample(live, hw::now_s());
    refresh();
    chk(report.ready && !busy && !report.os.empty() && !report.sec[hw::S_CPU].empty(), "real analysis");
    for (int s = 0; s < hw::S_COUNT; s++) { select(s); render_to(""); }
    std::printf("uitest %s\n", f ? "FAILED" : "ok");
    std::fflush(stdout);
    return f ? 1 : 0;
  }

  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok ready=%d\n", f->report.ready ? 1 : 0);
    std::fflush(stdout);
    f->hide();
  }
};
''';
