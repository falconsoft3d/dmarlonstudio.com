part of 'tk_examples.dart';

// El código en C++ de la wifi de casa (tk_showcase_cpp_wifi.dart): va tal
// cual en Form1.cpp, después de los textos (namespace tx).
const _wifiCode = r'''
// ============================================================ los datos
// La wifi de casa: la red a la que está conectado este equipo, las que se
// oyen alrededor (canal, banda, señal, seguridad y estándar) y el router
// (qué puertos abre y si anuncia UPnP). En macOS con system_profiler e
// ipconfig; en Windows con netsh wlan y PowerShell; en Linux con nmcli. La
// contraseña que se comprueba no se guarda ni sale del equipo.
namespace wf {

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


// ------------------------------------------------------------ números y horas
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
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
std::string clock_time(long long t) { return time_text(t, "%H:%M"); }
long long wall_now() { return (long long)std::time(nullptr); }


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
  if (const char* o = fl_getenv("DMS_WIFI_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\wifi";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/wifi";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/wifi";
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

// ------------------------------------------------------------ el modelo
// La seguridad de una red, de peor a mejor.
enum Sec { SEC_UNKNOWN, SEC_OPEN, SEC_WEP, SEC_WPA, SEC_WPA2_MIXED, SEC_WPA2, SEC_WPA3_TRANS, SEC_WPA3, SEC_ENTERPRISE };

struct Net {
  std::string ssid;          // vacío: el sistema no deja ver el nombre
  int channel = 0;
  int band = 0;              // 24, 5 o 6 (GHz)
  int width = 20;            // MHz
  int rssi = 0;              // dBm (0: no se sabe)
  int noise = 0;             // dBm (0: no se sabe)
  int sec = SEC_UNKNOWN;
  std::string sec_raw;
  std::string phy;           // «802.11ax», «802.11a/n/ac»…
  bool current = false;
};

struct Port {
  int port;
  const char* service;
  bool open = false;
};

struct Scan {
  bool ready = false, connected = false, names_hidden = false;
  long long when = 0;
  std::string os, iface, card, phys, country, ip, gateway, error;
  std::vector<std::string> dns;
  Net cur;
  int rate = 0, mcs = -1;    // Mbps de la conexión y su MCS
  std::vector<Net> nets;     // las demás que se oyen
  std::vector<Port> ports;
  bool upnp = false, router_checked = false;
  double ping_ms = -1, ping_loss = -1;
};

const char* sec_name(int s) {
  switch (s) {
    case SEC_OPEN: return tx::SEC_OPEN;
    case SEC_WEP: return "WEP";
    case SEC_WPA: return "WPA";
    case SEC_WPA2_MIXED: return tx::SEC_WPA2_MIXED;
    case SEC_WPA2: return "WPA2";
    case SEC_WPA3_TRANS: return "WPA2/WPA3";
    case SEC_WPA3: return "WPA3";
    case SEC_ENTERPRISE: return tx::SEC_ENTERPRISE;
  }
  return tx::UNKNOWN;
}

// «spairport_security_mode_wpa2_personal», «WPA2-Personal», «wpa2 wpa3»…
int sec_of(const std::string& raw) {
  std::string s = lower(raw);
  if (s.empty()) return SEC_UNKNOWN;
  if (has(s, "enterprise") || has(s, "802.1x") || has(s, "eap")) return SEC_ENTERPRISE;
  if (has(s, "wpa3_transition") || (has(s, "wpa2") && has(s, "wpa3"))) return SEC_WPA3_TRANS;
  if (has(s, "wpa3") || has(s, "sae") || has(s, "owe")) return SEC_WPA3;
  if (has(s, "mixed") || (has(s, "wpa2") && has(s, "tkip")) || (has(s, "wpa ") && has(s, "wpa2"))) return SEC_WPA2_MIXED;
  if (has(s, "wpa2") || has(s, "rsn")) return SEC_WPA2;
  if (has(s, "wpa")) return SEC_WPA;
  if (has(s, "wep")) return SEC_WEP;
  if (has(s, "none") || has(s, "open") || has(s, "abierta") || s == "--") return SEC_OPEN;
  return SEC_UNKNOWN;
}

int band_of_channel(int ch) { return ch >= 1 && ch <= 14 ? 24 : ch > 14 ? 5 : 0; }

// «36 (5GHz, 80MHz)» → canal, banda y ancho.
void parse_channel(const std::string& s, Net& n) {
  n.channel = std::atoi(s.c_str());
  n.band = has(s, "6GHz") ? 6 : has(s, "5GHz") ? 5 : has(s, "2GHz") ? 24 : band_of_channel(n.channel);
  size_t p = s.find("MHz");
  if (p != std::string::npos) {
    size_t a = s.rfind(' ', p);
    int w = std::atoi(s.substr(a == std::string::npos ? 0 : a + 1).c_str());
    if (w >= 20) n.width = w;
  }
}

// «-40 dBm / -89 dBm»
void parse_signal(const std::string& s, Net& n) {
  int a = 0, b = 0;
  if (std::sscanf(s.c_str(), "%d dBm / %d dBm", &a, &b) >= 1) {
    n.rssi = a;
    n.noise = b;
  }
}

// La calidad en % (Windows, Linux) a dBm, aproximada.
int pct_to_dbm(int pct) { return clampi(pct, 0, 100) / 2 - 100; }

// ------------------------------------------------------------ macOS
const char* const MAC_WIFI = "system_profiler SPAirPortDataType -json";

void from_mac(const Json& root, Scan& s) {
  const Json& ifs = root["SPAirPortDataType"][0]["spairport_airport_interfaces"];
  for (const auto& i : ifs.a) {
    if (!i["spairport_current_network_information"].o.size() && !i["spairport_airport_other_local_wireless_networks"].a.size() &&
        s.iface.size())
      continue;
    s.iface = jstr(i, "_name");
    s.card = jstr(i, "spairport_wireless_card_type");
    s.phys = jstr(i, "spairport_supported_phymodes");
    s.country = jstr(i, "spairport_wireless_country_code");
    const Json& c = i["spairport_current_network_information"];
    if (c.t == Json::OBJ && c.o.size()) {
      s.connected = true;
      Net& n = s.cur;
      n.current = true;
      n.ssid = jstr(c, "_name");
      parse_channel(jstr(c, "spairport_network_channel"), n);
      parse_signal(jstr(c, "spairport_signal_noise"), n);
      n.sec_raw = jstr(c, "spairport_security_mode");
      n.sec = sec_of(n.sec_raw);
      n.phy = jstr(c, "spairport_network_phymode");
      s.rate = (int)c["spairport_network_rate"].num();
      s.mcs = c["spairport_network_mcs"].t == Json::NUL ? -1 : (int)c["spairport_network_mcs"].num();
      if (s.country.empty()) s.country = jstr(c, "spairport_network_country_code");
    }
    for (const auto& o : i["spairport_airport_other_local_wireless_networks"].a) {
      Net n;
      n.ssid = jstr(o, "_name");
      parse_channel(jstr(o, "spairport_network_channel"), n);
      parse_signal(jstr(o, "spairport_signal_noise"), n);
      n.sec_raw = jstr(o, "spairport_security_mode");
      n.sec = sec_of(n.sec_raw);
      n.phy = jstr(o, "spairport_network_phymode");
      s.nets.push_back(n);
    }
    if (s.connected) break;
  }
  // Sin permiso de ubicación, macOS no da los nombres.
  auto hidden = [](std::string& n) {
    if (n == "<redacted>" || n.empty()) { n.clear(); return true; }
    return false;
  };
  bool any = hidden(s.cur.ssid) && s.connected;
  for (auto& n : s.nets) any = hidden(n.ssid) || any;
  s.names_hidden = any;
  if (s.card == "spairport_wireless_card_type_wifi" || starts(s.card, "spairport_")) s.card = "Wi-Fi";
  if (starts(s.card, "Wi-Fi (")) s.card = "Wi-Fi";
}

// ------------------------------------------------------------ Windows
// netsh habla el idioma del sistema: se buscan las claves en inglés y en
// español, y los valores (%, números) se reconocen por su forma.
std::string key_of(const std::string& line, std::string& value) {
  size_t p = line.find(" : ");
  if (p == std::string::npos) p = line.find(": ");
  if (p == std::string::npos) return "";
  value = trim(line.substr(p + (line[p] == ' ' ? 3 : 2)));
  return lower(trim(line.substr(0, p)));
}
bool key_is(const std::string& k, std::initializer_list<const char*> names) {
  for (const char* n : names)
    if (k == n) return true;
  return false;
}

void from_netsh(const std::string& ifaces, const std::string& nets, Scan& s) {
  for (const auto& raw : split(ifaces, '\n')) {
    std::string v, k = key_of(raw, v);
    if (k.empty()) continue;
    if (key_is(k, {"name", "nombre"}) && s.iface.empty()) s.iface = v;
    else if (key_is(k, {"description", "descripción"})) s.card = v;
    else if (key_is(k, {"state", "estado"})) s.connected = s.connected || has(lower(v), "connected") || has(lower(v), "conectado");
    else if (k == "ssid") { s.cur.ssid = v; s.cur.current = true; }
    else if (key_is(k, {"radio type", "tipo de radio"})) s.cur.phy = v;
    else if (key_is(k, {"authentication", "autenticación"})) s.cur.sec_raw = v + " " + s.cur.sec_raw;
    else if (key_is(k, {"cipher", "cifrado"})) s.cur.sec_raw += " " + v;
    else if (key_is(k, {"channel", "canal"})) { s.cur.channel = std::atoi(v.c_str()); s.cur.band = band_of_channel(s.cur.channel); }
    else if (key_is(k, {"band", "banda"})) s.cur.band = has(v, "6") && !has(v, "2.4") ? 6 : has(v, "5") ? 5 : 24;
    else if (key_is(k, {"receive rate (mbps)", "velocidad de recepción (mbps)"})) s.rate = std::atoi(v.c_str());
    else if (key_is(k, {"signal", "señal"})) s.cur.rssi = pct_to_dbm(std::atoi(v.c_str()));
    else if (k == "rssi") s.cur.rssi = std::atoi(v.c_str());
  }
  s.cur.sec = sec_of(s.cur.sec_raw);
  // Las redes: «SSID 1 : nombre» y debajo sus BSSID (cada uno, una radio).
  Net base, *last = nullptr;
  for (const auto& raw : split(nets, '\n')) {
    std::string line = trim(raw), v, k = key_of(line, v);
    if (starts(lower(line), "ssid ")) {
      base = Net();
      base.ssid = v;
      last = nullptr;
      continue;
    }
    if (k.empty()) continue;
    if (key_is(k, {"authentication", "autenticación"})) base.sec_raw = v;
    else if (key_is(k, {"encryption", "cifrado"})) base.sec_raw += " " + v;
    else if (starts(k, "bssid")) {
      Net n = base;
      n.sec = sec_of(n.sec_raw);
      s.nets.push_back(n);
      last = &s.nets.back();
    } else if (last) {
      if (key_is(k, {"signal", "señal"})) last->rssi = pct_to_dbm(std::atoi(v.c_str()));
      else if (key_is(k, {"radio type", "tipo de radio"})) last->phy = v;
      else if (key_is(k, {"channel", "canal"})) { last->channel = std::atoi(v.c_str()); last->band = band_of_channel(last->channel); }
      else if (key_is(k, {"band", "banda"})) last->band = has(v, "6") && !has(v, "2.4") ? 6 : has(v, "5") ? 5 : 24;
    }
  }
  // La red actual también sale en la lista: se quita (por nombre y canal).
  for (size_t i = 0; i < s.nets.size(); i++)
    if (s.connected && s.nets[i].ssid == s.cur.ssid && s.nets[i].channel == s.cur.channel) {
      s.nets.erase(s.nets.begin() + (long)i);
      break;
    }
}

const char* const PS_ROUTER =
    "powershell -NoProfile -NonInteractive -Command \"$c = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' "
    "-and $_.IPv4DefaultGateway -and ($_.InterfaceAlias -match 'Wi-?Fi|WLAN|Wireless|Inal') } | Select-Object -First 1; "
    "if ($c) { [pscustomobject]@{ ip = $c.IPv4Address.IPAddress; gateway = $c.IPv4DefaultGateway.NextHop; "
    "dns = @($c.DNSServer | Where-Object AddressFamily -eq 2 | ForEach-Object { $_.ServerAddresses }) } | ConvertTo-Json -Compress }\"";

// ------------------------------------------------------------ Linux
void from_nmcli(const std::string& out, Scan& s) {
  // IN-USE:SSID:CHAN:SIGNAL:SECURITY:RATE (los «:» del nombre van como «\:»).
  for (const auto& raw : split(out, '\n')) {
    std::vector<std::string> f;
    std::string cur;
    for (size_t i = 0; i < raw.size(); i++) {
      if (raw[i] == '\\' && i + 1 < raw.size()) { cur += raw[++i]; continue; }
      if (raw[i] == ':') { f.push_back(cur); cur.clear(); continue; }
      cur += raw[i];
    }
    f.push_back(cur);
    if (f.size() < 6) continue;
    Net n;
    n.current = trim(f[0]) == "*";
    n.ssid = f[1];
    n.channel = std::atoi(f[2].c_str());
    n.band = band_of_channel(n.channel);
    n.rssi = pct_to_dbm(std::atoi(f[3].c_str()));
    n.sec_raw = f[4].empty() ? "none" : f[4];
    n.sec = sec_of(n.sec_raw);
    if (n.current) {
      s.connected = true;
      s.cur = n;
      s.rate = std::atoi(f[5].c_str());
    } else {
      s.nets.push_back(n);
    }
  }
}

// ------------------------------------------------------------ el router
// ¿Responde el router en estos puertos? Se prueba la conexión (TCP) con un
// tiempo máximo: solo el router de esta red, el de casa.
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
void net_init() {}
#endif

bool valid_ipv4(const std::string& ip) {
  in_addr a;
  return inet_pton(AF_INET, ip.c_str(), &a) == 1;
}

bool tcp_open(const std::string& ip, int port, int ms) {
  net_init();
  sockaddr_in a{};
  a.sin_family = AF_INET;
  a.sin_port = htons((unsigned short)port);
  if (inet_pton(AF_INET, ip.c_str(), &a.sin_addr) != 1) return false;
  sock_t s = socket(AF_INET, SOCK_STREAM, 0);
  if (s == BAD_SOCK) return false;
#ifdef _WIN32
  u_long nb = 1;
  ioctlsocket(s, FIONBIO, &nb);
#else
  fcntl(s, F_SETFL, fcntl(s, F_GETFL, 0) | O_NONBLOCK);
#endif
  bool ok = false;
  int r = connect(s, (sockaddr*)&a, sizeof a);
  if (r == 0) ok = true;
  else {
    fd_set w;
    FD_ZERO(&w);
    FD_SET(s, &w);
    timeval tv{ms / 1000, (ms % 1000) * 1000};
    if (select((int)s + 1, nullptr, &w, nullptr, &tv) > 0) {
      int err = 0;
      socklen_t len = sizeof err;
      getsockopt(s, SOL_SOCKET, SO_ERROR, (char*)&err, &len);
      ok = err == 0;
    }
  }
  sock_close(s);
  return ok;
}

// UPnP: el router contesta a una búsqueda SSDP (UDP 239.255.255.250:1900).
bool upnp_answers(const std::string& gateway, int ms) {
  net_init();
  sock_t s = socket(AF_INET, SOCK_DGRAM, 0);
  if (s == BAD_SOCK) return false;
  sockaddr_in a{};
  a.sin_family = AF_INET;
  a.sin_port = htons(1900);
  inet_pton(AF_INET, "239.255.255.250", &a.sin_addr);
  const char* q =
      "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 1\r\n"
      "ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n\r\n";
  sendto(s, q, (int)std::strlen(q), 0, (sockaddr*)&a, sizeof a);
  bool found = false;
  double end = now_s() + ms / 1000.0;
  while (!found && now_s() < end) {
    fd_set r;
    FD_ZERO(&r);
    FD_SET(s, &r);
    int left = (int)((end - now_s()) * 1000);
    timeval tv{left / 1000, (left % 1000) * 1000};
    if (select((int)s + 1, &r, nullptr, nullptr, &tv) <= 0) break;
    char buf[2048];
    sockaddr_in from{};
    socklen_t fl = sizeof from;
    int n = (int)recvfrom(s, buf, sizeof buf - 1, 0, (sockaddr*)&from, &fl);
    if (n <= 0) continue;
    char ip[64];
    inet_ntop(AF_INET, &from.sin_addr, ip, sizeof ip);
    if (gateway.empty() || gateway == ip) found = true;
  }
  sock_close(s);
  return found;
}

const int PORTS[] = {21, 22, 23, 80, 443, 8080, 8443, 7547};
const char* port_service(int p) {
  switch (p) {
    case 21: return "FTP";
    case 22: return "SSH";
    case 23: return "Telnet";
    case 80: return "HTTP";
    case 443: return "HTTPS";
    case 8080: return "HTTP (8080)";
    case 8443: return "HTTPS (8443)";
    case 7547: return "TR-069";
  }
  return "?";
}

// La latencia hasta el router: «ping» del sistema (3 paquetes).
void ping_router(Scan& s) {
  if (!valid_ipv4(s.gateway)) return;
  std::string out;
#ifdef _WIN32
  run("ping -n 4 -w 1000 " + s.gateway, out);
  // «Media = 3ms» / «Average = 3ms» y «(0% perdidos)» / «(0% loss)»
  size_t p = out.rfind("= ");
  if (p != std::string::npos) s.ping_ms = std::atof(out.c_str() + p + 2);
  size_t l = out.find("% ");
  if (l != std::string::npos) {
    size_t a = out.rfind('(', l);
    if (a != std::string::npos) s.ping_loss = std::atof(out.c_str() + a + 1);
  }
#else
  run("ping -c 4 -i 0.3 -W 1000 -q " + s.gateway, out);
  // «round-trip min/avg/max/stddev = 2.1/3.4/5.0/1.0 ms»; «4 packets transmitted, 4 packets received, 0.0% packet loss»
  size_t p = out.find(" = ");
  if (p != std::string::npos) {
    double a, b;
    if (std::sscanf(out.c_str() + p + 3, "%lf/%lf", &a, &b) == 2) s.ping_ms = b;
  }
  size_t l = out.find("% packet loss");
  if (l != std::string::npos) {
    size_t a = out.rfind(' ', l);
    s.ping_loss = std::atof(out.c_str() + (a == std::string::npos ? 0 : a + 1));
  }
#endif
}

void check_router(Scan& s) {
  s.ports.clear();
  if (!valid_ipv4(s.gateway)) return;
  for (int p : PORTS) {
    Port x{p, port_service(p)};
    x.open = tcp_open(s.gateway, p, 600);
    s.ports.push_back(x);
  }
  s.upnp = upnp_answers(s.gateway, 1500);
  ping_router(s);
  s.router_checked = true;
}

// ------------------------------------------------------------ todo junto
Scan collect() {
  Scan s;
  s.when = wall_now();
  std::string out;
#ifdef __APPLE__
  s.os = "macOS";
  Json j;
  if (run(MAC_WIFI, out) && parse_json(out, j)) from_mac(j, s);
  else s.error = tx::ERR_SCAN;
  // El dispositivo de la wifi (en0, normalmente), su IP, su router y el DNS.
  std::string dev = "en0";
  if (run("networksetup -listallhardwareports", out)) {
    auto lines = split(out, '\n');
    for (size_t i = 0; i + 1 < lines.size(); i++)
      if (has(lines[i], "Wi-Fi") || has(lines[i], "AirPort")) {
        std::string v;
        key_of(lines[i + 1], v);
        if (!v.empty()) dev = v;
      }
  }
  if (run("ipconfig getifaddr " + dev, out)) s.ip = trim(out);
  if (run("ipconfig getoption " + dev + " router", out)) s.gateway = trim(out);
  if (run("ipconfig getoption " + dev + " domain_name_server", out)) s.dns.push_back(trim(out));
  if (s.iface.empty()) s.iface = dev;
#elif defined(_WIN32)
  s.os = "Windows";
  std::string nets;
  run("netsh wlan show interfaces", out);
  run("netsh wlan show networks mode=bssid", nets);
  if (out.empty()) s.error = tx::ERR_SCAN;
  from_netsh(out, nets, s);
  std::string r;
  Json j;
  if (run(PS_ROUTER, r) && parse_json(r, j)) {
    s.ip = jstr(j, "ip");
    s.gateway = jstr(j, "gateway");
    for (const auto& d : j["dns"].a) s.dns.push_back(d.str());
    if (j["dns"].t == Json::STR) s.dns.push_back(j["dns"].str());
  }
#else
  s.os = "Linux";
  if (run("nmcli -t -f IN-USE,SSID,CHAN,SIGNAL,SECURITY,RATE dev wifi list", out)) from_nmcli(out, s);
  else s.error = tx::ERR_SCAN;
  if (run("ip route show default", out)) {
    auto f = split(trim(out), ' ');
    for (size_t i = 0; i + 1 < f.size(); i++)
      if (f[i] == "via") s.gateway = f[i + 1];
  }
#endif
  if (s.connected) check_router(s);
  std::sort(s.nets.begin(), s.nets.end(), [](const Net& a, const Net& b) { return a.rssi > b.rssi; });
  s.ready = true;
  return s;
}

// ------------------------------------------------------------ la contraseña
// Se comprueba aquí mismo: no se guarda ni se envía. Lo que cuenta es cuánto
// tardaría alguien que ha capturado el «saludo» de la wifi (WPA2) en
// adivinarla probando contraseñas con tarjetas gráficas.
struct PassCheck {
  bool done = false;
  int length = 0, classes = 0, level = 0;   // level: 0 fuerte, 1 aceptable, 2 débil, 3 muy débil
  double bits = 0, seconds_gpu = 0, seconds_farm = 0;
  std::vector<std::string> notes;           // lo que se ha encontrado
};

// Las más usadas (y las de los routers de antes): se prueban las primeras.
const char* const COMMON[] = {
    "12345678", "123456789", "1234567890", "12345678910", "123123123", "11111111", "00000000", "88888888", "87654321",
    "12341234", "11223344", "12121212", "123456789a", "1234567a", "a1234567", "abcd1234", "a1b2c3d4", "qwerty123",
    "qwertyuiop", "asdfghjkl", "zxcvbnm1", "password", "password1", "password123", "passw0rd", "contraseña", "contrasena",
    "iloveyou", "teamo123", "internet", "wifi1234", "wifiwifi", "wireless", "admin123", "administrador", "changeme",
    "welcome1", "bienvenido", "micasa123", "casa1234", "familia1", "football", "baseball", "superman", "princess",
    "sunshine", "starwars", "dragon12", "monkey12", "letmein1", "trustno1", "barcelona", "realmadrid", "america1",
    "mexico123", "colombia", "argentina", "123qweasd", "1q2w3e4r", "1qaz2wsx", "q1w2e3r4", "zaq12wsx", "pokemon1",
    "minecraft", "spiderman", "batman123", "chocolate", "estrella", "corazon1", "mariposa", "tequiero", "fernando",
    "alejandro", "danielito", "jesus123", "angel123", "abc12345", "asdf1234", "1234qwer", "hola1234", "loveyou1"};

// Filas del teclado y abecedario, para encontrar secuencias.
const char* const ROWS[] = {"qwertyuiop", "asdfghjklñ", "zxcvbnm", "1234567890", "abcdefghijklmnopqrstuvwxyz"};

std::string fold(std::string s) {
  s = lower(s);
  const char* const from[] = {"á", "é", "í", "ó", "ú", "ü", "Á", "É", "Í", "Ó", "Ú"};
  const char* const to[] = {"a", "e", "i", "o", "u", "u", "a", "e", "i", "o", "u"};
  for (size_t k = 0; k < sizeof from / sizeof from[0]; k++)
    for (size_t p = s.find(from[k]); p != std::string::npos; p = s.find(from[k])) s.replace(p, std::strlen(from[k]), to[k]);
  return s;
}

// La duración en palabras («3 horas», «unos 400 años», «más que la edad del universo»).
std::string span(double s) {
  if (s < 1) return tx::T_INSTANT;
  struct U { double sec; const char* one; const char* many; };
  const U us[] = {{31557600e2, tx::T_CENTURY, tx::T_CENTURIES}, {31557600, tx::T_YEAR, tx::T_YEARS}, {86400 * 30.44, tx::T_MONTH, tx::T_MONTHS},
                  {86400, tx::T_DAY, tx::T_DAYS}, {3600, tx::T_HOUR, tx::T_HOURS}, {60, tx::T_MINUTE, tx::T_MINUTES}, {1, tx::T_SECOND, tx::T_SECONDS}};
  if (s > 4.3e17) return tx::T_UNIVERSE;
  for (const auto& u : us)
    if (s >= u.sec) {
      double v = s / u.sec;
      if (u.sec >= 31557600e2 && v >= 1000) return tx::T_MILLENNIA;
      long long n = (long long)std::llround(v);
      return fmt(n == 1 ? u.one : u.many, {std::to_string(n)});
    }
  return tx::T_INSTANT;
}

PassCheck check_password(const std::string& pw, const std::string& ssid) {
  PassCheck c;
  c.done = true;
  // Caracteres (no bytes): «ñ» cuenta uno.
  int chars = 0;
  for (unsigned char ch : pw) chars += (ch & 0xc0) != 0x80;
  c.length = chars;
  bool lo = false, up = false, dg = false, sy = false;
  for (unsigned char ch : pw) {
    if (std::islower(ch)) lo = true;
    else if (std::isupper(ch)) up = true;
    else if (std::isdigit(ch)) dg = true;
    else sy = true;
  }
  c.classes = lo + up + dg + sy;
  double pool = (lo ? 26 : 0) + (up ? 26 : 0) + (dg ? 10 : 0) + (sy ? 33 : 0);
  if (pool < 10) pool = 10;
  // Lo que se resta: cada trozo predecible cuenta casi nada.
  std::string f = fold(pw);
  double effective = chars;
  bool common = false;
  for (const char* w : COMMON)
    if (f == w) common = true;
  // Repeticiones («aaaa», «abab»).
  int rep = 0;
  for (size_t i = 1; i < f.size(); i++) rep += f[i] == f[i - 1];
  if (rep >= 3) { c.notes.push_back(tx::PW_REPEATS); effective -= rep * 0.7; }
  if (f.size() >= 4) {
    std::string half = f.substr(0, f.size() / 2);
    if (f.size() % 2 == 0 && f == half + half) { c.notes.push_back(tx::PW_DOUBLED); effective = effective / 2 + 1; }
  }
  // Secuencias del teclado o del abecedario (4 o más seguidas, en los dos sentidos).
  int seq = 0;
  for (const char* row : ROWS) {
    std::string r = row, rr(r.rbegin(), r.rend());
    for (size_t len = std::min<size_t>(f.size(), r.size()); len >= 4; len--) {
      bool hit = false;
      for (size_t i = 0; i + len <= f.size() && !hit; i++) {
        std::string piece = f.substr(i, len);
        hit = has(r, piece) || has(rr, piece);
      }
      if (hit) { seq = std::max(seq, (int)len); break; }
    }
  }
  if (seq >= 4) { c.notes.push_back(fmt(tx::PW_SEQUENCE, {std::to_string(seq)})); effective -= seq * 0.8; }
  // Un año (1950–2039) o una fecha.
  for (size_t i = 0; i + 4 <= f.size(); i++) {
    int y = std::atoi(f.substr(i, 4).c_str());
    bool digits = std::all_of(f.begin() + (long)i, f.begin() + (long)i + 4, [](char ch) { return std::isdigit((unsigned char)ch); });
    if (digits && y >= 1950 && y <= 2039) { c.notes.push_back(tx::PW_YEAR); effective -= 3; break; }
  }
  // El nombre de la red dentro.
  // (solo letras y números: «Casa_Garcia» está en «casagarcia2026»).
  auto alnum = [](const std::string& x) {
    std::string o;
    for (char ch : x)
      if (std::isalnum((unsigned char)ch)) o += ch;
    return o;
  };
  std::string n = alnum(fold(ssid)), fa = alnum(f);
  if (n.size() >= 3 && has(fa, n)) { c.notes.push_back(tx::PW_SSID); effective -= (double)n.size() * 0.9; }
  // Una palabra de la lista con números alrededor («casa1234!»).
  if (!common) {
    std::string letters;
    for (char ch : f)
      if (std::isalpha((unsigned char)ch)) letters += ch;
    for (const char* w : COMMON) {
      std::string ws = w, wl;
      for (char ch : ws)
        if (std::isalpha((unsigned char)ch)) wl += ch;
      if (wl.size() >= 5 && letters == wl) { c.notes.push_back(tx::PW_WORD); effective = std::min(effective, 4.0 + (f.size() - wl.size())); break; }
    }
  }
  if (!sy && !up && !lo && dg) c.notes.push_back(tx::PW_DIGITS);
  effective = std::max(1.0, effective);
  c.bits = common ? 10 : effective * std::log2(pool);
  if (common) c.notes.insert(c.notes.begin(), tx::PW_COMMON);
  // Una tarjeta gráfica prueba unos 2,5 millones por segundo contra WPA2; un
  // grupo de cien, 250 millones. De media, se acierta a la mitad.
  double guesses = std::pow(2.0, c.bits) / 2;
  c.seconds_gpu = guesses / 2.5e6;
  c.seconds_farm = guesses / 2.5e8;
  if (chars < 8) c.notes.insert(c.notes.begin(), tx::PW_TOO_SHORT);
  else if (chars < 12) c.notes.push_back(tx::PW_SHORT);
  if (c.classes <= 1 && !common) c.notes.push_back(tx::PW_ONE_KIND);
  c.level = common || chars < 8 || c.seconds_farm < 86400 ? 3
            : c.seconds_farm < 86400 * 365 ? 2
            : c.seconds_farm < 31557600.0 * 1000 || chars < 12 ? 1
            : 0;
  if (c.level == 0) c.notes.push_back(tx::PW_GOOD);
  return c;
}

// ------------------------------------------------------------ el diagnóstico
enum Level { L_OK, L_TIP, L_WARN, L_BAD };
enum Section { S_DIAG, S_MINE, S_NEARBY, S_CHANNELS, S_PASSWORD, S_ROUTER, S_COUNT };

const char* section_title(int s) {
  const char* const t[] = {tx::S_DIAG, tx::S_MINE, tx::S_NEARBY, tx::S_CHANNELS, tx::S_PASSWORD, tx::S_ROUTER};
  return s >= 0 && s < S_COUNT ? t[s] : "";
}

struct Finding {
  int level;
  std::string title, detail;
  int section;
};

// ¿Se pisan dos redes? En 2,4 GHz, los canales a menos de 5 de distancia; en
// 5 GHz, los que comparten parte del ancho.
bool overlaps(const Net& a, const Net& b) {
  if (a.band != b.band || !a.channel || !b.channel) return false;
  if (a.band == 24) return std::abs(a.channel - b.channel) < 5;
  // El canal primario y su bloque (80 MHz: 4 canales de 20).
  auto block = [](const Net& n) {
    int w = std::max(1, n.width / 20);
    int first = n.channel - (n.channel - 36) % (4 * w);
    return std::make_pair(first - 2, first + 4 * w - 2);
  };
  auto A = block(a), B = block(b);
  return A.first < B.second && B.first < A.second;
}

// Cuánto molestan las redes de alrededor en un canal: más cuanto más fuertes.
double crowd(const std::vector<Net>& nets, const Net& at) {
  double c = 0;
  for (const auto& n : nets) {
    if (!overlaps(at, n) || n.rssi == 0) continue;
    c += n.rssi > -60 ? 1.0 : n.rssi > -70 ? 0.6 : n.rssi > -80 ? 0.3 : 0.1;
  }
  return c;
}

// El mejor canal de la banda de la red: 1, 6 u 11 en 2,4 GHz; en 5 GHz, el
// primero de cada bloque.
int best_channel(const Scan& s) {
  const Net& c = s.cur;
  std::vector<int> cand = c.band == 24 ? std::vector<int>{1, 6, 11} : std::vector<int>{36, 52, 100, 116, 132, 149};
  int best = c.channel;
  double bc = 1e9;
  for (int ch : cand) {
    Net t = c;
    t.channel = ch;
    double v = crowd(s.nets, t) + (ch == c.channel ? -0.2 : 0);   // a igualdad, quedarse
    if (v < bc) { bc = v; best = ch; }
  }
  return best;
}

int generation(const std::string& phy) {
  std::string p = lower(phy);
  if (has(p, "be")) return 7;
  if (has(p, "ax")) return 6;
  if (has(p, "ac")) return 5;
  if (has(p, "n")) return 4;
  return p.empty() ? 0 : 3;
}

std::string net_name(const Net& n, int i) {
  if (!n.ssid.empty()) return n.ssid;
  return i < 0 ? std::string(tx::MY_NETWORK) : fmt(tx::NET_N, {std::to_string(i + 1)});
}

std::vector<Finding> diagnose(const Scan& s, const PassCheck& pw) {
  std::vector<Finding> f;
  auto add = [&](int l, const std::string& t, const std::string& d, int sec) { f.push_back({l, t, d, sec}); };
  if (!s.connected) {
    add(L_BAD, tx::F_NOT_CONNECTED, s.error.empty() ? tx::F_NOT_CONNECTED_D : s.error, S_MINE);
    return f;
  }
  const Net& c = s.cur;
  // ---- la seguridad de la red
  switch (c.sec) {
    case SEC_OPEN: add(L_BAD, tx::F_OPEN, tx::F_OPEN_D, S_MINE); break;
    case SEC_WEP: add(L_BAD, tx::F_WEP, tx::F_WEP_D, S_MINE); break;
    case SEC_WPA: add(L_BAD, tx::F_WPA, tx::F_WPA_D, S_MINE); break;
    case SEC_WPA2_MIXED: add(L_WARN, tx::F_MIXED, tx::F_MIXED_D, S_MINE); break;
    case SEC_WPA2: add(L_TIP, tx::F_WPA2, tx::F_WPA2_D, S_MINE); break;
    case SEC_WPA3_TRANS: add(L_OK, tx::F_WPA3T, tx::F_WPA3T_D, S_MINE); break;
    case SEC_WPA3: add(L_OK, tx::F_WPA3, tx::F_WPA3_D, S_MINE); break;
    case SEC_ENTERPRISE: add(L_OK, tx::F_ENT, tx::F_ENT_D, S_MINE); break;
    default: add(L_TIP, tx::F_SEC_UNKNOWN, tx::F_SEC_UNKNOWN_D, S_MINE);
  }
  // ---- la contraseña
  if (!pw.done) add(L_TIP, tx::F_PW_ASK, tx::F_PW_ASK_D, S_PASSWORD);
  else if (pw.level == 3) add(L_BAD, tx::F_PW_BAD, fmt(tx::F_PW_TIME, {span(pw.seconds_farm)}), S_PASSWORD);
  else if (pw.level == 2) add(L_WARN, tx::F_PW_WEAK, fmt(tx::F_PW_TIME, {span(pw.seconds_farm)}), S_PASSWORD);
  else if (pw.level == 1) add(L_TIP, tx::F_PW_OK, fmt(tx::F_PW_TIME, {span(pw.seconds_farm)}), S_PASSWORD);
  else add(L_OK, tx::F_PW_STRONG, fmt(tx::F_PW_TIME, {span(pw.seconds_farm)}), S_PASSWORD);
  // ---- la señal
  if (c.rssi) {
    std::string sig = std::to_string(c.rssi) + " dBm";
    if (c.rssi >= -60) add(L_OK, tx::F_SIGNAL_GOOD, fmt(tx::F_SIGNAL_GOOD_D, {sig}), S_MINE);
    else if (c.rssi >= -70) add(L_TIP, tx::F_SIGNAL_FAIR, fmt(tx::F_SIGNAL_FAIR_D, {sig}), S_MINE);
    else add(L_WARN, tx::F_SIGNAL_WEAK, fmt(tx::F_SIGNAL_WEAK_D, {sig}), S_MINE);
    if (c.noise) {
      int snr = c.rssi - c.noise;
      if (snr < 20) add(snr < 15 ? L_WARN : L_TIP, tx::F_NOISE, fmt(tx::F_NOISE_D, {std::to_string(snr)}), S_MINE);
    }
  }
  // ---- la banda, el ancho y el canal
  int gen = generation(c.phy), card = generation(s.phys);
  if (c.band == 24) {
    bool five = false;
    for (const auto& n : s.nets) five = five || n.band == 5;
    add(L_TIP, tx::F_BAND24, five || card >= 5 ? tx::F_BAND24_D : tx::F_BAND24_D2, S_MINE);
    if (c.width >= 40 && crowd(s.nets, c) >= 1) add(L_TIP, tx::F_WIDE24, tx::F_WIDE24_D, S_CHANNELS);
  } else if (c.band == 5 && c.width == 20) {
    add(L_TIP, tx::F_NARROW5, tx::F_NARROW5_D, S_CHANNELS);
  }
  double here = crowd(s.nets, c);
  int best = best_channel(s);
  if (here >= 1.5 && best != c.channel)
    add(here >= 3 ? L_WARN : L_TIP, fmt(tx::F_CROWDED, {std::to_string(c.channel)}),
        fmt(tx::F_CROWDED_D, {num(here, 1), std::to_string(best)}), S_CHANNELS);
  else
    add(L_OK, fmt(tx::F_CHANNEL_OK, {std::to_string(c.channel)}), tx::F_CHANNEL_OK_D, S_CHANNELS);
  if (gen && gen <= 4) add(gen <= 3 ? L_WARN : L_TIP, tx::F_OLD, fmt(tx::F_OLD_D, {c.phy}), S_MINE);
  if (s.rate > 0 && s.rate < 100) add(L_TIP, tx::F_SLOW_LINK, fmt(tx::F_SLOW_LINK_D, {std::to_string(s.rate)}), S_MINE);
  // ---- el router
  if (s.router_checked) {
    for (const auto& p : s.ports) {
      if (!p.open) continue;
      if (p.port == 23) add(L_BAD, tx::F_TELNET, tx::F_TELNET_D, S_ROUTER);
      else if (p.port == 21) add(L_WARN, tx::F_FTP, tx::F_FTP_D, S_ROUTER);
    }
    bool http = false, https = false;
    for (const auto& p : s.ports) {
      if (!p.open) continue;
      if (p.port == 80 || p.port == 8080) http = true;
      if (p.port == 443 || p.port == 8443) https = true;
    }
    if (http && !https) add(L_TIP, tx::F_HTTP, fmt(tx::F_HTTP_D, {s.gateway}), S_ROUTER);
    if (s.upnp) add(L_TIP, tx::F_UPNP, tx::F_UPNP_D, S_ROUTER);
    if (s.ping_loss > 0) add(s.ping_loss >= 10 ? L_WARN : L_TIP, tx::F_LOSS, fmt(tx::F_LOSS_D, {num(s.ping_loss, 0)}), S_ROUTER);
    else if (s.ping_ms > 30) add(L_TIP, tx::F_LATENCY, fmt(tx::F_LATENCY_D, {num(s.ping_ms, 0)}), S_ROUTER);
    bool any = false;
    for (const auto& p : s.ports) any = any || (p.open && (p.port == 23 || p.port == 21));
    if (!any && !s.upnp) add(L_OK, tx::F_ROUTER_OK, tx::F_ROUTER_OK_D, S_ROUTER);
  }
  // ---- alrededor
  int open = 0;
  for (const auto& n : s.nets) open += n.sec == SEC_OPEN || n.sec == SEC_WEP;
  if (open) add(L_TIP, fmt(tx::F_OPEN_NEAR, {std::to_string(open)}), tx::F_OPEN_NEAR_D, S_NEARBY);
  std::stable_sort(f.begin(), f.end(), [](const Finding& a, const Finding& b) { return a.level > b.level; });
  return f;
}

// 100 menos lo que resta cada cosa.
int score(const std::vector<Finding>& f) {
  int s = 100;
  for (const auto& x : f) s -= x.level == L_BAD ? 30 : x.level == L_WARN ? 12 : x.level == L_TIP ? 4 : 0;
  return clampi(s, 0, 100);
}
const char* verdict(int sc) { return sc >= 85 ? tx::V_GOOD : sc >= 65 ? tx::V_FAIR : sc >= 40 ? tx::V_POOR : tx::V_BAD; }

// ------------------------------------------------------------ el informe en texto
std::string level_name(int l) {
  const char* const n[] = {tx::LV_OK, tx::LV_TIP, tx::LV_WARN, tx::LV_BAD};
  return n[clampi(l, 0, 3)];
}

std::string report_text(const Scan& s, const PassCheck& pw) {
  auto f = diagnose(s, pw);
  int sc = score(f);
  std::string o = std::string(tx::APP) + " — " + time_text(s.when, tx::DATE_FMT) + "\n\n";
  o += fmt(tx::SCORE_LINE, {std::to_string(sc), verdict(sc)}) + "\n\n";
  for (const auto& x : f) o += "[" + level_name(x.level) + "] " + x.title + "\n    " + x.detail + "\n";
  if (s.connected) {
    const Net& c = s.cur;
    o += "\n" + std::string(tx::S_MINE) + "\n";
    o += "  " + std::string(tx::K_NAME) + ": " + net_name(c, -1) + "\n";
    o += "  " + std::string(tx::K_SECURITY) + ": " + sec_name(c.sec) + "\n";
    o += "  " + std::string(tx::K_CHANNEL) + ": " + std::to_string(c.channel) + " (" + (c.band == 24 ? "2,4" : std::to_string(c.band)) +
         " GHz, " + std::to_string(c.width) + " MHz)\n";
    if (c.rssi) o += "  " + std::string(tx::K_SIGNAL) + ": " + std::to_string(c.rssi) + " dBm\n";
    if (!c.phy.empty()) o += "  " + std::string(tx::K_STANDARD) + ": " + c.phy + "\n";
    if (s.rate) o += "  " + std::string(tx::K_RATE) + ": " + std::to_string(s.rate) + " Mbps\n";
    if (!s.gateway.empty()) o += "  " + std::string(tx::K_ROUTER) + ": " + s.gateway + "\n";
  }
  if (pw.done) {
    o += "\n" + std::string(tx::S_PASSWORD) + "\n";
    o += "  " + fmt(tx::PW_SUMMARY, {std::to_string(pw.length), num(pw.bits, 0), span(pw.seconds_gpu), span(pw.seconds_farm)}) + "\n";
    for (const auto& n : pw.notes) o += "  · " + n + "\n";
  }
  o += "\n" + fmt(tx::NEARBY_N, {std::to_string(s.nets.size())}) + "\n";
  for (size_t i = 0; i < s.nets.size(); i++) {
    const Net& n = s.nets[i];
    o += "  " + net_name(n, (int)i) + " · " + std::to_string(n.channel) + " · " + std::to_string(n.rssi) + " dBm · " + sec_name(n.sec) + "\n";
  }
  return o;
}

// ------------------------------------------------------------ ejemplo
// Una casa de ejemplo (para las pruebas y las capturas): los nombres son
// inventados.
Scan sample_scan() {
  Scan s;
  s.ready = s.connected = s.router_checked = true;
  s.when = 1794240000;
  s.os = "macOS";
  s.iface = "en0";
  s.card = "Wi-Fi";
  s.phys = "802.11 a/b/g/n/ac/ax";
  s.country = "ES";
  s.ip = "192.168.1.34";
  s.gateway = "192.168.1.1";
  s.dns = {"192.168.1.1"};
  s.rate = 585;
  s.mcs = 7;
  Net& c = s.cur;
  c.ssid = "Casa_Garcia";
  c.current = true;
  c.channel = 1;
  c.band = 24;
  c.width = 40;
  c.rssi = -67;
  c.noise = -86;
  c.sec = SEC_WPA2_MIXED;
  c.sec_raw = "spairport_security_mode_wpa2_personal_mixed";
  c.phy = "802.11n";
  auto net = [&](const char* name, int ch, int w, int rssi, int sec, const char* phy) {
    Net n;
    n.ssid = name;
    n.channel = ch;
    n.band = band_of_channel(ch);
    n.width = w;
    n.rssi = rssi;
    n.noise = n.band == 24 ? -86 : -92;
    n.sec = sec;
    n.phy = phy;
    s.nets.push_back(n);
  };
  net("Casa_Garcia_5G", 36, 80, -61, SEC_WPA2, "802.11a/n/ac");
  net("MOVISTAR_9C21", 1, 20, -58, SEC_WPA2, "802.11b/g/n");
  net("DIGIFIBRA-PLUS-7F", 1, 20, -70, SEC_WPA3_TRANS, "802.11b/g/n/ax");
  net("Vodafone-4E2B", 6, 20, -74, SEC_WPA2, "802.11b/g/n");
  net("Orange-A1B2", 1, 20, -76, SEC_WPA2_MIXED, "802.11b/g/n");
  net("Bar Plaza Libre", 11, 20, -78, SEC_OPEN, "802.11b/g/n");
  net("WLAN_A3F1", 3, 20, -82, SEC_WEP, "802.11b/g");
  net("MiFibra-22C8", 6, 20, -80, SEC_WPA2, "802.11b/g/n/ax");
  net("Lowi_2E7A", 1, 20, -84, SEC_WPA2, "802.11b/g/n");
  net("MOVISTAR_PLUS_9C21", 44, 80, -72, SEC_WPA3_TRANS, "802.11a/n/ac/ax");
  net("DIGIFIBRA-PLUS-7F-5G", 100, 80, -79, SEC_WPA3_TRANS, "802.11a/n/ac/ax");
  net("Impresora_HP", 6, 20, -66, SEC_WPA2, "802.11b/g/n");
  std::sort(s.nets.begin(), s.nets.end(), [](const Net& a, const Net& b) { return a.rssi > b.rssi; });
  s.ports = {{21, "FTP"}, {22, "SSH"}, {23, "Telnet"}, {80, "HTTP", true}, {443, "HTTPS"}, {8080, "HTTP (8080)"}, {8443, "HTTPS (8443)"}, {7547, "TR-069", true}};
  s.upnp = true;
  s.ping_ms = 3.4;
  s.ping_loss = 0;
  return s;
}

// ------------------------------------------------------------ pruebas internas
int fails = 0;
void check(bool ok, const char* what) {
  if (!ok) { std::printf("FAIL %s\n", what); fails++; }
}

int selftest() {
  // La seguridad, se escriba como se escriba.
  check(sec_of("spairport_security_mode_wpa2_personal") == SEC_WPA2, "sec wpa2");
  check(sec_of("pairport_security_mode_wpa3_transition") == SEC_WPA3_TRANS, "sec wpa3 transition");
  check(sec_of("spairport_security_mode_wpa2_personal_mixed") == SEC_WPA2_MIXED, "sec mixed");
  check(sec_of("spairport_security_mode_none") == SEC_OPEN, "sec none");
  check(sec_of("WPA2-Personal CCMP") == SEC_WPA2, "sec netsh");
  check(sec_of("WPA2-Personal TKIP") == SEC_WPA2_MIXED, "sec tkip");
  check(sec_of("WPA3-Personal") == SEC_WPA3, "sec wpa3");
  check(sec_of("WPA2-Enterprise") == SEC_ENTERPRISE, "sec enterprise");
  check(sec_of("Abierta Ninguno") == SEC_OPEN, "sec abierta");
  check(sec_of("WEP") == SEC_WEP, "sec wep");
  // Canales y señal de system_profiler.
  Net n;
  parse_channel("36 (5GHz, 80MHz)", n);
  check(n.channel == 36 && n.band == 5 && n.width == 80, "channel 5");
  parse_channel("6 (2GHz, 20MHz)", n);
  check(n.channel == 6 && n.band == 24 && n.width == 20, "channel 24");
  parse_signal("-62 dBm / -84 dBm", n);
  check(n.rssi == -62 && n.noise == -84, "signal");
  check(pct_to_dbm(100) == -50 && pct_to_dbm(40) == -80, "pct");
  // system_profiler entero (los nombres ocultos).
  Json j;
  check(parse_json(
            "{\"SPAirPortDataType\":[{\"spairport_airport_interfaces\":[{\"_name\":\"en0\",\"spairport_supported_phymodes\":\"802.11 "
            "a/b/g/n/ac/ax\",\"spairport_current_network_information\":{\"_name\":\"<redacted>\",\"spairport_network_channel\":\"36 "
            "(5GHz, 80MHz)\",\"spairport_network_phymode\":\"802.11ac\",\"spairport_network_rate\":866,\"spairport_security_mode\":"
            "\"spairport_security_mode_wpa2_personal\",\"spairport_signal_noise\":\"-40 dBm / -89 dBm\"},"
            "\"spairport_airport_other_local_wireless_networks\":[{\"_name\":\"<redacted>\",\"spairport_network_channel\":\"6 (2GHz, "
            "20MHz)\",\"spairport_security_mode\":\"spairport_security_mode_none\",\"spairport_signal_noise\":\"-62 dBm / -84 dBm\"}]}]}]}",
            j),
        "mac json");
  Scan m;
  from_mac(j, m);
  check(m.connected && m.cur.channel == 36 && m.cur.rssi == -40 && m.rate == 866 && m.cur.sec == SEC_WPA2, "mac current");
  check(m.nets.size() == 1 && m.nets[0].sec == SEC_OPEN && m.names_hidden && m.cur.ssid.empty(), "mac nearby");
  // netsh en español.
  Scan w;
  from_netsh(
      "    Nombre                 : Wi-Fi\n    Estado                 : conectado\n    SSID                   : CasaPepe\n"
      "    Tipo de radio          : 802.11ax\n    Autenticación          : WPA2-Personal\n    Cifrado                : CCMP\n"
      "    Banda                  : 5 GHz\n    Canal                  : 44\n    Velocidad de recepción (Mbps)  : 1201\n    Señal                  : 88%\n",
      "SSID 1 : CasaPepe\n    Autenticación           : WPA2-Personal\n    Cifrado                 : CCMP\n    BSSID 1                 : "
      "aa:bb:cc:dd:ee:ff\n         Señal             : 88%\n         Canal             : 44\n"
      "SSID 2 : Vecino\n    Autenticación           : Abierta\n    Cifrado                 : Ninguno\n    BSSID 1                 : "
      "11:22:33:44:55:66\n         Señal             : 40%\n         Tipo de radio     : 802.11n\n         Canal             : 6\n",
      w);
  check(w.connected && w.cur.ssid == "CasaPepe" && w.cur.channel == 44 && w.cur.band == 5 && w.rate == 1201 && w.cur.rssi == -56,
        "netsh current");
  check(w.cur.sec == SEC_WPA2 && w.nets.size() == 1 && w.nets[0].ssid == "Vecino" && w.nets[0].sec == SEC_OPEN && w.nets[0].channel == 6,
        "netsh nearby");
  // nmcli.
  Scan l;
  from_nmcli("*:Mi\\:Casa:11:70:WPA2:270 Mbit/s\n :Otra:1:30::54 Mbit/s\n", l);
  check(l.connected && l.cur.ssid == "Mi:Casa" && l.cur.channel == 11 && l.nets.size() == 1 && l.nets[0].sec == SEC_OPEN, "nmcli");
  // Canales que se pisan.
  Net a, b;
  a.band = b.band = 24;
  a.channel = 1;
  b.channel = 4;
  check(overlaps(a, b), "overlap 1-4");
  b.channel = 6;
  check(!overlaps(a, b), "no overlap 1-6");
  a.band = b.band = 5;
  a.channel = 36;
  b.channel = 44;
  a.width = b.width = 80;
  check(overlaps(a, b), "overlap 36-44 80MHz");
  a.width = b.width = 20;
  check(!overlaps(a, b), "no overlap 36-44 20MHz");
  // Contraseñas.
  check(check_password("12345678", "x").level == 3, "pw common");
  check(check_password("casa1234", "x").level == 3, "pw word");
  check(check_password("Abc12", "x").level == 3 && has(check_password("Abc12", "x").notes[0], tx::PW_TOO_SHORT), "pw short");
  check(check_password("CasaGarcia2026", "Casa_Garcia").level >= 2, "pw ssid");
  check(check_password("qwertyuiopasdf", "x").level >= 2, "pw keyboard");
  check(check_password("t7#Vq9!mR2&xLp4@", "x").level == 0, "pw strong");
  check(check_password("correcto-caballo-bateria-grapa", "x").level == 0, "pw passphrase");
  PassCheck u8 = check_password("añoñañoñañoñ", "x");
  check(u8.length == 12, "pw utf8 length");
  check(span(30) == fmt(tx::T_SECONDS, {"30"}) && span(7200) == fmt(tx::T_HOURS, {"2"}), "span");
  // El diagnóstico de la casa de ejemplo.
  Scan s = sample_scan();
  PassCheck none;
  auto f = diagnose(s, none);
  bool mixed = false, crowded = false, upnp = false, http = false, ask = false;
  for (const auto& x : f) {
    mixed = mixed || x.title == tx::F_MIXED;
    crowded = crowded || has(x.title, fmt(tx::F_CROWDED, {"1"}));
    upnp = upnp || x.title == tx::F_UPNP;
    http = http || x.title == tx::F_HTTP;
    ask = ask || x.title == tx::F_PW_ASK;
  }
  check(mixed && crowded && upnp && http && ask, "sample findings");
  check(best_channel(s) == 11, "best channel");
  int sc = score(f);
  check(sc > 20 && sc < 80, "sample score");
  auto f2 = diagnose(s, check_password("12345678", s.cur.ssid));
  check(score(f2) < sc && f2[0].level == L_BAD, "weak password lowers score");
  std::string t = report_text(s, check_password("t7#Vq9!mR2&xLp4@", ""));
  check(has(t, tx::S_PASSWORD) && !has(t, "t7#Vq9") && has(t, "Casa_Garcia"), "report text (no password)");
  Scan off;
  off.ready = true;
  check(diagnose(off, none).size() == 1 && score(diagnose(off, none)) == 70, "not connected");
  std::printf("selftest %s (%d)\n", fails ? "FAILED" : "ok", fails);
  return fails ? 1 : 0;
}

}  // namespace wf

// ============================================================ el panel
namespace wf {

inline Fl_Color rgb(uint32_t v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void col(uint32_t v) { fl_color(rgb(v)); }

const uint32_t C_BG = 0xffffff, C_TEXT = 0x1f2937, C_DIM = 0x6b7280, C_LINE = 0xe5e7eb, C_CARD = 0xf4f6fb, C_ACCENT = 0x2563eb,
               C_GOOD = 0x16a34a, C_TIP = 0x2563eb, C_WARN = 0xd97706, C_BAD = 0xdc2626;
uint32_t level_color(int l) { return l == L_BAD ? C_BAD : l == L_WARN ? C_WARN : l == L_TIP ? C_TIP : C_GOOD; }
uint32_t sec_color(int s) { return s <= SEC_WPA ? (s == SEC_UNKNOWN ? C_DIM : C_BAD) : s == SEC_WPA2_MIXED ? C_WARN : C_GOOD; }
uint32_t signal_color(int rssi) { return rssi >= -60 ? C_GOOD : rssi >= -70 ? 0x65a30d : rssi >= -78 ? C_WARN : C_BAD; }

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
// Un texto en varias líneas dentro de «w»: devuelve dónde acaba.
int para(const std::string& s, int x, int y, int w, uint32_t c, int size = 13, int lh = 18) {
  fl_font(FL_HELVETICA, size);
  col(c);
  std::string line;
  for (const auto& word : split(s, ' ')) {
    std::string t = line.empty() ? word : line + " " + word;
    if (!line.empty() && fl_width(t.c_str()) > w) {
      fl_draw(line.c_str(), x, y);
      y += lh;
      line = word;
    } else {
      line = t;
    }
  }
  if (!line.empty()) { fl_draw(line.c_str(), x, y); y += lh; }
  return y;
}
void rbox(Box b, uint32_t c) { fl_draw_box(FL_RFLAT_BOX, b.x, b.y, b.w, b.h, rgb(c)); }
uint32_t mix(uint32_t a, uint32_t b, double t) {
  auto ch = [&](int s) { return (uint32_t)iround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t) << s; };
  return ch(16) | ch(8) | ch(0);
}
void bar(Box b, double f, uint32_t c) {
  rbox(b, 0xe2e6ee);
  f = std::max(0.0, std::min(1.0, f));
  if (f > 0) rbox({b.x, b.y, std::max(b.h, (int)(b.w * f)), b.h}, c);
}
// Las rayitas de la señal (de 1 a 4).
void bars(int x, int y, int rssi) {
  int n = rssi >= -60 ? 4 : rssi >= -70 ? 3 : rssi >= -78 ? 2 : 1;
  for (int i = 0; i < 4; i++) {
    col(i < n ? signal_color(rssi) : 0xd1d5db);
    fl_rectf(x + i * 5, y - 4 - i * 3, 3, 4 + i * 3);
  }
}
double sig_frac(int rssi) { return rssi ? std::max(0.0, std::min(1.0, (rssi + 95) / 55.0)) : 0; }

// El panel de la derecha: cada sección se dibuja en código. Un clic en una
// tarjeta del diagnóstico lleva a su sección; el botón de la contraseña, a
// pedirla.
class WifiView : public Fl_Widget {
public:
  const Scan* scan = nullptr;
  const PassCheck* pw = nullptr;
  int section = 0, scroll = 0, content_h = 0;
  bool busy = false;
  std::vector<std::pair<Box, int>> navs;   // clic: va a la sección
  Box pw_button;                           // clic: pedir la contraseña
  std::function<void(int)> on_nav;
  std::function<void()> on_password;

  WifiView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void draw() override { render(x(), y(), w(), h()); }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOUSEWHEEL: {
        scroll = clampi(scroll + Fl::event_dy() * 30, 0, std::max(0, content_h - h()));
        redraw();
        return 1;
      }
      case FL_PUSH: click(Fl::event_x(), Fl::event_y()); return 1;
    }
    return Fl_Widget::handle(e);
  }
  void click(int px, int py) {
    if (pw_button.w && pw_button.has(px, py)) { if (on_password) on_password(); return; }
    for (const auto& n : navs)
      if (n.first.has(px, py)) { if (on_nav) on_nav(n.second); return; }
  }

  void render(int X, int Y, int W, int H) {
    navs.clear();
    pw_button = Box();
    col(C_BG);
    fl_rectf(X, Y, W, H);
    fl_push_clip(X, Y, W, H);
    int x0 = X + 28, w0 = W - 56, y = Y + 34 - scroll;
    text(section_title(section), x0, y, C_TEXT, 22, true);
    y += 14;
    if (!scan || !scan->ready) {
      text(busy ? tx::SCANNING : tx::WAITING, x0, y + 30, C_DIM, 14);
      content_h = 120;
    } else {
      int end = y;
      switch (section) {
        case S_DIAG: end = diag(x0, y + 16, w0); break;
        case S_MINE: end = mine(x0, y + 16, w0); break;
        case S_NEARBY: end = nearby(x0, y + 16, w0); break;
        case S_CHANNELS: end = channels(x0, y + 16, w0); break;
        case S_PASSWORD: end = password(x0, y + 16, w0); break;
        case S_ROUTER: end = router(x0, y + 16, w0); break;
      }
      content_h = end + scroll - Y + 30;
    }
    fl_pop_clip();
  }

  // Una fila «dato: valor».
  int row(int x, int y, int w, const std::string& k, const std::string& v, uint32_t vc = C_TEXT) {
    text(k, x, y + 15, C_DIM, 13);
    text(fit(v, w - 270, 13, true), x + 260, y + 15, vc, 13, true);
    col(C_LINE);
    fl_xyline(x, y + 24, x + w);
    return y + 28;
  }
  int heading(int x, int y, const std::string& t) {
    text(t, x, y + 18, C_TEXT, 15, true);
    return y + 30;
  }

  // ---- el diagnóstico: la nota y cada cosa encontrada
  int diag(int x, int y, int w) {
    auto f = diagnose(*scan, *pw);
    int sc = score(f);
    uint32_t c = sc >= 85 ? C_GOOD : sc >= 65 ? 0x65a30d : sc >= 40 ? C_WARN : C_BAD;
    // El anillo con la nota.
    int r = 58, cx = x + r + 4, cy = y + r + 4;
    col(0xe5e7eb);
    fl_line_style(FL_SOLID | FL_CAP_ROUND, 12);
    fl_arc(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
    col(c);
    if (sc > 0) fl_arc(cx - r, cy - r, 2 * r, 2 * r, 90 - 360.0 * sc / 100, 90);
    fl_line_style(0);
    std::string n = std::to_string(sc);
    text(n, cx - width(n, 34, true) / 2, cy + 12, C_TEXT, 34, true);
    text(verdict(sc), x + 2 * r + 34, y + 40, c, 24, true);
    int counts[4] = {0, 0, 0, 0};
    for (const auto& x2 : f) counts[x2.level]++;
    std::string sum = fmt(tx::COUNTS, {std::to_string(counts[L_BAD]), std::to_string(counts[L_WARN]), std::to_string(counts[L_TIP])});
    text(sum, x + 2 * r + 34, y + 68, C_DIM, 13);
    if (scan->connected)
      text(fmt(tx::CONNECTED_TO, {net_name(scan->cur, -1), sec_name(scan->cur.sec)}), x + 2 * r + 34, y + 92, C_TEXT, 13);
    if (scan->names_hidden) text(tx::NAMES_HIDDEN, x + 2 * r + 34, y + 112, C_DIM, 11);
    y += 2 * r + 30;
    for (const auto& it : f) {
      fl_font(FL_HELVETICA, 13);
      // Alto de la tarjeta según el texto.
      int lines = 1;
      {
        std::string line;
        for (const auto& word : split(it.detail, ' ')) {
          std::string t = line.empty() ? word : line + " " + word;
          if (!line.empty() && fl_width(t.c_str()) > w - 60) { lines++; line = word; }
          else line = t;
        }
      }
      int h = 40 + lines * 18;
      Box b{x, y, w, h};
      rbox(b, C_CARD);
      col(level_color(it.level));
      fl_rectf(x, y + 6, 4, h - 12);
      text(level_name(it.level), x + 18, y + 22, level_color(it.level), 11, true);
      text(fit(it.title, w - 130 - width(level_name(it.level), 11, true), 14, true), x + 26 + width(level_name(it.level), 11, true), y + 22,
           C_TEXT, 14, true);
      para(it.detail, x + 18, y + 42, w - 60, C_DIM, 13);
      text("›", x + w - 20, y + 24, C_DIM, 18, true);
      navs.push_back({b, it.section});
      y += h + 10;
    }
    return y;
  }

  // ---- mi red
  int mine(int x, int y, int w) {
    const Scan& s = *scan;
    if (!s.connected) return para(s.error.empty() ? tx::F_NOT_CONNECTED_D : s.error, x, y + 10, w, C_DIM, 14);
    const Net& c = s.cur;
    // La señal, grande.
    Box b{x, y, w, 86};
    rbox(b, C_CARD);
    text(net_name(c, -1), x + 18, y + 30, C_TEXT, 18, true);
    text(std::to_string(c.rssi) + " dBm", x + w - 150, y + 30, signal_color(c.rssi), 18, true);
    bar({x + 18, y + 48, w - 36, 10}, sig_frac(c.rssi), signal_color(c.rssi));
    text(c.rssi >= -60 ? tx::SIG_GOOD : c.rssi >= -70 ? tx::SIG_FAIR : tx::SIG_WEAK, x + 18, y + 76, C_DIM, 12);
    y += 104;
    y = row(x, y, w, tx::K_SECURITY, sec_name(c.sec), sec_color(c.sec));
    y = row(x, y, w, tx::K_BAND, c.band == 24 ? "2,4 GHz" : std::to_string(c.band) + " GHz");
    y = row(x, y, w, tx::K_CHANNEL, std::to_string(c.channel));
    y = row(x, y, w, tx::K_WIDTH, std::to_string(c.width) + " MHz");
    if (!c.phy.empty()) y = row(x, y, w, tx::K_STANDARD, c.phy + wifi_gen(c.phy));
    if (c.noise) y = row(x, y, w, tx::K_NOISE, std::to_string(c.noise) + " dBm · " + fmt(tx::SNR, {std::to_string(c.rssi - c.noise)}));
    if (s.rate) y = row(x, y, w, tx::K_RATE, std::to_string(s.rate) + " Mbps" + (s.mcs >= 0 ? " · MCS " + std::to_string(s.mcs) : ""));
    if (!s.country.empty()) y = row(x, y, w, tx::K_COUNTRY, s.country);
    if (!s.ip.empty()) y = row(x, y, w, tx::K_IP, s.ip);
    if (!s.gateway.empty()) y = row(x, y, w, tx::K_ROUTER, s.gateway);
    if (!s.dns.empty()) y = row(x, y, w, "DNS", join(s.dns, ", "));
    y = row(x, y, w, tx::K_ADAPTER, join({s.card, s.iface, s.phys}, " · "));
    return y;
  }
  static std::string wifi_gen(const std::string& phy) {
    int g = generation(phy);
    return g >= 4 ? " (Wi-Fi " + std::to_string(g) + ")" : "";
  }

  // ---- las redes de alrededor
  int nearby(int x, int y, int w) {
    const Scan& s = *scan;
    y = para(fmt(tx::NEARBY_INTRO, {std::to_string(s.nets.size())}), x, y + 6, w, C_DIM, 13) + 6;
    const int cols[] = {0, 300, 380, 470, 560, 720};
    const char* heads[] = {tx::K_NAME, tx::K_CHANNEL, tx::K_BAND, tx::K_WIDTH, tx::K_SIGNAL, tx::K_SECURITY};
    for (int i = 0; i < 6; i++) text(heads[i], x + cols[i], y + 14, C_DIM, 12, true);
    y += 24;
    auto line = [&](const Net& n, int i) {
      if (n.current) rbox({x - 8, y, w + 16, 30}, 0xeaf1ff);
      text(fit(net_name(n, i) + (n.current ? std::string(" · ") + tx::YOURS : ""), cols[1] - 16, 13, n.current), x, y + 20, C_TEXT, 13, n.current);
      text(std::to_string(n.channel), x + cols[1], y + 20, C_TEXT, 13);
      text(n.band == 24 ? "2,4 GHz" : std::to_string(n.band) + " GHz", x + cols[2], y + 20, C_TEXT, 13);
      text(std::to_string(n.width) + " MHz", x + cols[3], y + 20, C_TEXT, 13);
      bars(x + cols[4], y + 21, n.rssi);
      text(std::to_string(n.rssi) + " dBm", x + cols[4] + 26, y + 20, signal_color(n.rssi), 13);
      text(sec_name(n.sec), x + cols[5], y + 20, sec_color(n.sec), 13, true);
      col(C_LINE);
      fl_xyline(x, y + 30, x + w);
      y += 32;
    };
    if (s.connected) line(s.cur, -1);
    for (size_t i = 0; i < s.nets.size(); i++) line(s.nets[i], (int)i);
    return y;
  }

  // ---- los canales: cada red como una «montaña» del ancho de su canal
  int channels(int x, int y, int w) {
    const Scan& s = *scan;
    y = para(tx::CHANNELS_INTRO, x, y + 6, w, C_DIM, 13) + 8;
    int best = s.connected ? best_channel(s) : 0;
    y = spectrum(x, y, w, 24, best);
    y = spectrum(x, y + 18, w, 5, best);
    return y;
  }
  int spectrum(int x, int y, int w, int band, int best) {
    const Scan& s = *scan;
    text(band == 24 ? tx::BAND_24 : tx::BAND_5, x, y + 16, C_TEXT, 15, true);
    y += 26;
    Box b{x + 40, y, w - 50, 210};
    rbox({x, y - 4, w, b.h + 40}, C_CARD);
    // Eje: canales de la banda.
    double lo = band == 24 ? -1 : 30, hi = band == 24 ? 15 : 170;
    auto X = [&](double ch) { return b.x + (ch - lo) / (hi - lo) * b.w; };
    auto Y = [&](int rssi) { return b.y + b.h - sig_frac(rssi) * (b.h - 16); };
    col(C_LINE);
    for (int d = -90; d <= -40; d += 10) {
      fl_xyline(b.x, (int)Y(d), b.x + b.w);
      text(std::to_string(d), x + 6, (int)Y(d) + 4, C_DIM, 10);
    }
    std::vector<int> ticks = band == 24 ? std::vector<int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
                                        : std::vector<int>{36, 44, 52, 60, 100, 108, 116, 124, 132, 140, 149, 157, 165};
    for (int t : ticks) text(std::to_string(t), (int)X(t) - width(std::to_string(t), 10) / 2, b.y + b.h + 18, C_DIM, 10);
    if (best && s.connected && s.cur.band == band && best != s.cur.channel) {
      col(mix(C_GOOD, 0xffffff, 0.75));
      fl_rectf((int)X(best) - 6, b.y, 12, b.h);
      text(fmt(tx::BEST_HERE, {std::to_string(best)}), (int)X(best) + 8, b.y + 14, C_GOOD, 11, true);
    }
    // Cada red: la parábola de su ancho (en 2,4 GHz, 22 MHz son ±2 canales).
    fl_push_clip(b.x, b.y - 30, b.w, b.h + 30);
    std::vector<std::pair<const Net*, int>> all;
    for (size_t i = 0; i < s.nets.size(); i++) all.push_back({&s.nets[i], (int)i});
    if (s.connected) all.push_back({&s.cur, -1});
    int shown = 0;
    for (const auto& p : all) {
      const Net& n = *p.first;
      if (n.band != band || !n.rssi) continue;
      shown++;
      double half = band == 24 ? 2.0 * n.width / 20 : n.width / 10.0;
      double center = n.channel;
      // 40 MHz en 2,4 GHz: el canal y el que está 4 por encima (o por debajo).
      if (band == 24 && n.width >= 40) center = n.channel <= 7 ? n.channel + 2 : n.channel - 2;
      if (band == 5 && n.width > 20) {
        int blk = n.width / 20 * 4;
        int first = n.channel - (n.channel - 36) % blk;
        center = first + (blk - 4) / 2.0;
      }
      uint32_t c = n.current ? C_ACCENT : n.sec <= SEC_WEP ? C_BAD : 0x94a3b8;
      col(n.current ? mix(C_ACCENT, 0xffffff, 0.8) : mix(c, 0xffffff, 0.88));
      fl_begin_complex_polygon();
      for (int k = 0; k <= 24; k++) {
        double t = -1 + k / 12.0;
        fl_vertex(X(center + t * half), b.y + b.h - (1 - t * t) * (b.y + b.h - Y(n.rssi)));
      }
      fl_end_complex_polygon();
      col(c);
      fl_line_style(FL_SOLID, n.current ? 3 : 1);
      fl_begin_line();
      for (int k = 0; k <= 24; k++) {
        double t = -1 + k / 12.0;
        fl_vertex(X(center + t * half), b.y + b.h - (1 - t * t) * (b.y + b.h - Y(n.rssi)));
      }
      fl_end_line();
      fl_line_style(0);
      std::string lab = fit(net_name(n, p.second), 140, 10, n.current);
      text(lab, (int)X(center) - width(lab, 10, n.current) / 2, (int)Y(n.rssi) - 4, n.current ? C_ACCENT : C_DIM, 10, n.current);
    }
    fl_pop_clip();
    if (!shown) text(tx::NO_NETWORKS_BAND, b.x + 20, b.y + b.h / 2, C_DIM, 13);
    return y + b.h + 40;
  }

  // ---- la contraseña
  int password(int x, int y, int w) {
    y = para(tx::PW_INTRO, x, y + 6, w, C_DIM, 13) + 10;
    pw_button = {x, y, 260, 36};
    rbox(pw_button, C_ACCENT);
    std::string bl = pw->done ? tx::PW_AGAIN : tx::PW_CHECK;
    text(bl, x + (260 - width(bl, 14, true)) / 2, y + 23, 0xffffff, 14, true);
    y += 56;
    if (!pw->done) return y;
    const PassCheck& p = *pw;
    uint32_t c = p.level == 0 ? C_GOOD : p.level == 1 ? 0x65a30d : p.level == 2 ? C_WARN : C_BAD;
    const char* lv[] = {tx::PW_L0, tx::PW_L1, tx::PW_L2, tx::PW_L3};
    text(lv[p.level], x, y + 22, c, 22, true);
    bar({x, y + 36, w, 12}, std::min(1.0, p.bits / 90), c);
    y += 66;
    y = row(x, y, w, tx::PW_LENGTH, std::to_string(p.length));
    y = row(x, y, w, tx::PW_KINDS, fmt(tx::PW_KINDS_N, {std::to_string(p.classes)}));
    y = row(x, y, w, tx::PW_BITS, num(p.bits, 0) + " bits");
    y = row(x, y, w, tx::PW_GPU, span(p.seconds_gpu), c);
    y = row(x, y, w, tx::PW_FARM, span(p.seconds_farm), c);
    y += 10;
    for (const auto& n : p.notes) {
      text("•", x + 2, y + 15, c, 14, true);
      y = para(n, x + 18, y + 15, w - 20, C_TEXT, 13) + 4;
    }
    y += 6;
    return para(tx::PW_PRIVACY, x, y + 10, w, C_DIM, 12);
  }

  // ---- el router
  int router(int x, int y, int w) {
    const Scan& s = *scan;
    if (!s.router_checked) return para(tx::ROUTER_NONE, x, y + 10, w, C_DIM, 14);
    y = row(x, y, w, tx::K_ROUTER, s.gateway);
    y = row(x, y, w, tx::K_PING, s.ping_ms >= 0 ? num(s.ping_ms, 1) + " ms" : tx::NONE);
    y = row(x, y, w, tx::K_LOSS, s.ping_loss >= 0 ? num(s.ping_loss, 0) + " %" : tx::NONE, s.ping_loss > 0 ? C_WARN : C_TEXT);
    y = row(x, y, w, "UPnP", s.upnp ? tx::UPNP_ON : tx::UPNP_OFF, s.upnp ? C_WARN : C_GOOD);
    y = heading(x, y + 16, tx::PORTS_TITLE);
    for (const auto& p : s.ports) {
      uint32_t c = !p.open ? C_GOOD : p.port == 23 ? C_BAD : p.port == 21 ? C_WARN : C_TEXT;
      text(std::to_string(p.port), x, y + 15, C_TEXT, 13, true);
      text(p.service, x + 70, y + 15, C_TEXT, 13);
      text(p.open ? tx::PORT_OPEN : tx::PORT_CLOSED, x + 220, y + 15, c, 13, true);
      text(fit(port_note(p.port), w - 340), x + 340, y + 15, C_DIM, 12);
      col(C_LINE);
      fl_xyline(x, y + 24, x + w);
      y += 28;
    }
    return para(tx::ROUTER_HINT, x, y + 20, w, C_DIM, 12);
  }
  static const char* port_note(int p) {
    switch (p) {
      case 21: return tx::PN_FTP;
      case 22: return tx::PN_SSH;
      case 23: return tx::PN_TELNET;
      case 80: case 8080: return tx::PN_HTTP;
      case 443: case 8443: return tx::PN_HTTPS;
      case 7547: return tx::PN_TR069;
    }
    return "";
  }
};

}  // namespace wf

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  wf::Scan scan;
  wf::PassCheck pw;
  wf::WifiView* view = nullptr;
  bool busy = false, sync = false, auto_on = true;
  double next_scan = 0;
  std::string message;
  double message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_WIFI_SELFTEST")) std::exit(wf::selftest());
    if (fl_getenv("DMS_WIFI_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_WIFI_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    ResultsHint->hide();   // el aviso del Diseñador
    Results->box(FL_FLAT_BOX);
    Side->resizable(nullptr);
    resizable(Results);
    view = new wf::WifiView(Results->x(), Results->y(), Results->w(), Results->h());
    Results->add(view);
    Results->resizable(view);
    view->scan = &scan;
    view->pw = &pw;
    view->on_nav = [](int s) { if (self()) self()->select(s); };
    view->on_password = [] { if (self()) self()->ask_password(); };
    std::vector<std::string> names;
    for (int s = 0; s < wf::S_COUNT; s++) names.push_back(wf::section_title(s));
    Sections->items(names);
    Sections->textsize(14);
    mark(tx::MP_SCAN, 0, false, FL_COMMAND + 'r');
    mark(tx::MP_PASSWORD, 0, false, FL_COMMAND + 'k');
    mark(tx::MP_QUIT, 0, false, FL_COMMAND + 'q');
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // el análisis (en otro hilo) avisa a la ventana
    setup();
    load();
    sync_menu();
    select(0);
    refresh();
    size_range(980, 640);
    if (fl_getenv("DMS_WIFI_SMOKE")) Fl::add_timeout(8.0, smoke, this);
  }
  void form_close() override { save(); }

  // ---- el análisis (en otro hilo: system_profiler y los puertos tardan)
  void refresh() {
    if (busy) return;
    busy = true;
    view->busy = true;
    update_side();
    view->redraw();
    if (sync) {
      finish(new wf::Scan(wf::collect()));
      return;
    }
    std::thread([] {
      auto* s = new wf::Scan(wf::collect());
      Fl::awake(done, s);
    }).detach();
  }
  static void done(void* p) {
    auto* s = static_cast<wf::Scan*>(p);
    if (self()) self()->finish(s);
    else delete s;
  }
  void finish(wf::Scan* s) {
    scan = std::move(*s);
    delete s;
    busy = false;
    view->busy = false;
    next_scan = wf::now_s() + 60;
    update_side();
    view->redraw();
  }
  void update_side() {
    if (!scan.ready) {
      LblNet->text(tx::SCANNING);
      LblInfo->text("");
    } else if (!scan.connected) {
      LblNet->text(tx::NOT_CONNECTED);
      LblInfo->text("");
    } else {
      const wf::Net& c = scan.cur;
      auto f = wf::diagnose(scan, pw);
      int sc = wf::score(f);
      LblNet->text(wf::net_name(c, -1));
      LblInfo->text(wf::join({wf::fmt(tx::SIDE_INFO, {c.band == 24 ? "2,4" : std::to_string(c.band), std::to_string(c.channel),
                                                       std::to_string(c.rssi)}),
                              wf::fmt(tx::SIDE_SCORE, {std::to_string(sc), wf::verdict(sc)})},
                             "\n"));
    }
    update_status();
  }
  void update_status() {
    if (!message.empty() && wf::now_s() < message_until) { Status->text(" " + message); return; }
    message.clear();
    if (busy || !scan.ready) { Status->text(std::string(" ") + tx::SCANNING); return; }
    Status->text(" " + wf::fmt(tx::STATUS, {wf::clock_time(scan.when), auto_on ? tx::STATUS_AUTO : tx::STATUS_MANUAL}));
  }
  void set_message(const std::string& m) {
    message = m;
    message_until = wf::now_s() + 4;
    update_status();
  }

  // ---- cada segundo: el mensaje y, si toca, otro análisis
  void Tick_timer() override {
    if (auto_on && !busy && scan.ready && wf::now_s() >= next_scan) refresh();
    update_status();
  }

  void select(int s, bool list = true) {
    s = wf::clampi(s, 0, wf::S_COUNT - 1);
    if (list) Sections->index(s);
    view->section = s;
    view->scroll = 0;
    view->redraw();
  }
  void Sections_select() override {
    int i = Sections->index();
    if (i >= 0) select(i, false);
  }

  // ---- la contraseña: se pide, se comprueba y se olvida
  void check_password(const std::string& p) {
    pw = wf::check_password(p, scan.cur.ssid);
    update_side();
    select(wf::S_PASSWORD);
  }
  void ask_password() {
    fl_message_title(tx::APP);
    const char* v = fl_password("%s", "", tx::PW_ASK);
    if (!v || !*v) return;
    std::string p = v;
    check_password(p);
    std::fill(p.begin(), p.end(), '\0');
  }

  void BtnScan_click() override { refresh(); }
  void BtnPassword_click() override { ask_password(); }
  void BtnCopy_click() override { copy_report(); }

  // ---- el informe
  bool save_text_to(const std::string& path) { return wf::write_file(path, wf::report_text(scan, pw)); }
  void save_text() {
    if (!scan.ready) return;
    Fl_Native_File_Chooser fc;
    fc.title(tx::L_TXT);
    fc.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    fc.filter((std::string(tx::TXT_FILTER) + "\t*.txt").c_str());
    fc.preset_file((std::string(tx::REPORT_FILE) + " " + wf::time_text(scan.when, "%Y-%m-%d") + ".txt").c_str());
    fc.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM | Fl_Native_File_Chooser::USE_FILTER_EXT);
    if (fc.show() != 0 || !fc.filename()) return;
    std::string path = fc.filename();
    if (path.size() < 4 || wf::lower(path.substr(path.size() - 4)) != ".txt") path += ".txt";
    if (!save_text_to(path)) {
      fl_message_title(tx::APP);
      fl_alert("%s", wf::fmt(tx::ERR_SAVE, {path}).c_str());
      return;
    }
    set_message(wf::fmt(tx::SAVED_TXT, {fl_filename_name(path.c_str())}));
  }
  void copy_report() {
    if (!scan.ready) return;
    std::string t = wf::report_text(scan, pw);
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
    mark(tx::MP_AUTO, FL_MENU_TOGGLE, auto_on);
    Menu1->redraw();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_SCAN) refresh();
    else if (item == tx::MP_PASSWORD) ask_password();
    else if (item == tx::MP_TXT) save_text();
    else if (item == tx::MP_COPY) copy_report();
    else if (item == tx::MP_QUIT) {
      save();
      hide();
    } else if (item == tx::MP_AUTO) {
      auto_on = !auto_on;
      next_scan = wf::now_s() + 60;
      save();
    } else if (item == tx::MP_HOW) {
      fl_message_title(tx::L_HOW);
      fl_message("%s", tx::HOW_TEXT);
    } else if (item == tx::MP_ABOUT) {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", wf::fmt(tx::ABOUT_TEXT, {v}).c_str());
    } else {
      for (int s = 0; s < wf::S_COUNT; s++)
        if (item == std::string(tx::M_VIEW) + "/" + wf::section_title(s)) select(s);
    }
    sync_menu();
    update_status();
    view->redraw();
  }

  // ---- las preferencias (la contraseña nunca)
  std::string settings_file() const { return wf::config_dir() + "/settings.txt"; }
  void load() {
    std::string t;
    if (wf::read_file(settings_file(), t) && wf::has(t, "auto=0")) auto_on = false;
  }
  void save() {
    if (sync) return;
    fl_make_path(wf::config_dir().c_str());
    wf::write_file(settings_file(), std::string("auto=") + (auto_on ? "1" : "0") + "\n");
  }

  // ---- sin ventana: la interfaz dibujada en una imagen
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
  void demo_state(int W, int H) {
    sync = true;
    auto_on = false;
    setup();
    size(W, H);
    scan = wf::sample_scan();
    update_side();
    select(0);
  }
  int shots(const std::string& dir) {
    Fl::screen_count();
    int W = 1240, H = 820;
    if (const char* s = fl_getenv("DMS_WIFI_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
    demo_state(W, H);
    check_password("Garcia1985!");
    select(wf::S_DIAG);
    render_to(dir + "/diagnostico.png");
    select(wf::S_CHANNELS);
    render_to(dir + "/canales.png");
    select(wf::S_NEARBY);
    render_to(dir + "/redes.png");
    select(wf::S_PASSWORD);
    render_to(dir + "/contrasena.png");
    select(wf::S_ROUTER);
    render_to(dir + "/router.png");
    select(wf::S_MINE);
    render_to(dir + "/mi-red.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }

  // ---- la interfaz sin ventana: cada sección, la contraseña y el informe
  int ui_test() {
    Fl::screen_count();
    demo_state(1180, 760);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(scan.ready && LblNet->text() == "Casa_Garcia", "demo scan");
    chk(Sections->size() == wf::S_COUNT, "sections list");
    for (int s = 0; s < wf::S_COUNT; s++) {
      Sections->index(s);
      Sections_select();
      render_to("");
      chk(view->section == s && view->content_h > 100, "section drawn");
      view->scroll = 100000;
      render_to("");
    }
    // El diagnóstico: cada tarjeta lleva a su sección.
    select(wf::S_DIAG);
    render_to("");
    chk(view->navs.size() >= 6, "findings");
    if (!view->navs.empty()) {
      int target = view->navs[0].second;
      wf::Box b = view->navs[0].first;
      view->click(b.x + 10, b.y + 10);
      chk(view->section == target && Sections->index() == target, "finding navigation");
    }
    // La contraseña: débil, fuerte, y nunca en el informe.
    check_password("12345678");
    chk(pw.done && pw.level == 3 && view->section == wf::S_PASSWORD, "weak password");
    render_to("");
    chk(view->pw_button.w > 0, "password button");
    std::string weak = LblInfo->text();
    check_password("t7#Vq9!mR2&xLp4@");
    chk(pw.level == 0 && LblInfo->text() != weak, "strong password raises score");
    std::string dir = wf::config_dir();
    fl_make_path(dir.c_str());
    std::string txt = dir + "/informe.txt", data;
    chk(save_text_to(txt) && wf::read_file(txt, data) && wf::has(data, tx::S_PASSWORD) && !wf::has(data, "t7#Vq9"), "text file");
    chk(!wf::read_file(settings_file(), data) || !wf::has(data, "t7#Vq9"), "password never saved");
    Menu1_click(tx::MP_AUTO);
    chk(auto_on, "auto on");
    Menu1_click(tx::MP_AUTO);
    // El análisis de verdad de este equipo.
    sync = true;
    refresh();
    chk(scan.ready && !busy, "real scan");
    for (int s = 0; s < wf::S_COUNT; s++) { select(s); render_to(""); }
    std::printf("real: connected=%d nets=%d router=%d ports=%d\n", scan.connected ? 1 : 0, (int)scan.nets.size(), scan.router_checked ? 1 : 0,
                (int)scan.ports.size());
    std::printf("uitest %s\n", f ? "FAILED" : "ok");
    std::fflush(stdout);
    return f ? 1 : 0;
  }

  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok ready=%d\n", f->scan.ready ? 1 : 0);
    std::fflush(stdout);
    f->hide();
  }
};
''';
