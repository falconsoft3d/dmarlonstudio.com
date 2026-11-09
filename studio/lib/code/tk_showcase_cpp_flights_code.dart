part of 'tk_examples.dart';

// El código en C++ del buscador de vuelos (tk_showcase_cpp_flights.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _flightsCode = r'''
// ============================================================ los datos
// Los precios vienen de la Data API de Travelpayouts (Aviasales): los
// billetes más baratos que encontraron los buscadores en las últimas horas,
// de todas las aerolíneas y agencias que vende Aviasales. Sin token, la app
// enseña datos de ejemplo (y lo dice).
namespace fx {

const double PI = 3.14159265358979323846;
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
std::string upper(std::string s) {
  for (auto& c : s) c = (char)std::toupper((unsigned char)c);
  return s;
}
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
// Un código de aerolínea: dos letras o cifras («IB», «2W»).
bool is_airline_code(const std::string& s) {
  return s.size() == 2 && std::isalnum((unsigned char)s[0]) && std::isalnum((unsigned char)s[1]);
}
bool is_iata(const std::string& s) {
  if (s.size() != 3) return false;
  for (char c : s)
    if (!std::isalpha((unsigned char)c)) return false;
  return true;
}

// El idioma de la app (los textos los pone el estudio): «es» o «en».
std::string lang() { return std::string(tx::LOCALE).substr(0, 2); }

// 1234.5 → «1.235» (es) o «1,235» (en); con decimales si se piden.
std::string money(double v, const std::string& cur, int dec = 0) {
  char b[64];
  // printf redondea al par (1234.5 → 1234): se redondea antes, hacia arriba.
  const double scale = std::pow(10.0, dec);
  std::snprintf(b, sizeof b, "%.*f", dec, std::floor(std::fabs(v) * scale + 0.5) / scale);
  std::string s = b, frac;
  size_t dot = s.find('.');
  if (dot != std::string::npos) { frac = s.substr(dot + 1); s = s.substr(0, dot); }
  const char thou = tx::DEC[0] == ',' ? '.' : ',';
  std::string g;
  for (size_t i = 0; i < s.size(); i++) {
    if (i && (s.size() - i) % 3 == 0) g += thou;
    g += s[i];
  }
  if (!frac.empty()) g += std::string(1, tx::DEC[0]) + frac;
  if (v < 0) g = "-" + g;
  std::string c = upper(cur);
  if (c == "EUR") return g + " €";
  if (c == "USD") return "$" + g;
  if (c == "GBP") return "£" + g;
  return g + " " + c;
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

// ------------------------------------------------------------ fechas
struct Date {
  int y = 0, m = 0, d = 0;   // d = 0: el mes entero
  bool ok() const { return y >= 2000 && m >= 1 && m <= 12 && d >= 0 && d <= 31; }
};
inline int days_in(int y, int m) {
  static const int n[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  return m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0) ? 29 : n[clampi(m, 1, 12) - 1];
}
// «2026-12» o «2026-12-20» (también 2026/12/20).
Date parse_date(const std::string& text) {
  Date r;
  std::string s = trim(text);
  for (auto& c : s)
    if (c == '/' || c == '.') c = '-';
  int y = 0, m = 0, d = 0;
  char tail = 0;
  if (std::sscanf(s.c_str(), "%4d-%2d-%2d%c", &y, &m, &d, &tail) == 3) r = {y, m, d};
  else if (std::sscanf(s.c_str(), "%4d-%2d%c", &y, &m, &tail) == 2) r = {y, m, 0};
  if (r.ok() && r.d > days_in(r.y, r.m)) r = {};
  return r;
}
std::string iso(const Date& d) {
  char b[16];
  if (d.d) std::snprintf(b, sizeof b, "%04d-%02d-%02d", d.y, d.m, d.d);
  else std::snprintf(b, sizeof b, "%04d-%02d", d.y, d.m);
  return b;
}
Date today() {
  std::time_t t = std::time(nullptr);
  std::tm tm{};
#ifdef _WIN32
  localtime_s(&tm, &t);
#else
  localtime_r(&t, &tm);
#endif
  return {tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday};
}
// Para comparar: año, mes, día (el mes entero cuenta como su último día).
inline long key(const Date& d) { return d.y * 10000L + d.m * 100L + (d.d ? d.d : days_in(d.y, d.m)); }

std::string month_name(int m, bool full) {
  auto names = split(full ? tx::MONTHS : tx::MONTHS_SHORT, '|');
  return m >= 1 && m <= (int)names.size() ? names[m - 1] : "";
}
// «2026-12-14T10:05:00+01:00» → «14 dic» (y la hora, «10:05», aparte).
std::string day_label(const std::string& at) {
  Date d = parse_date(at.substr(0, 10));
  if (!d.ok() || !d.d) return at.substr(0, 10);
  return std::to_string(d.d) + " " + month_name(d.m, false);
}
std::string time_label(const std::string& at) { return at.size() >= 16 ? at.substr(11, 5) : ""; }
std::string period_label(const Date& d) {
  if (!d.ok()) return "";
  if (d.d) return std::to_string(d.d) + " " + month_name(d.m, false) + " " + std::to_string(d.y);
  return fmt(tx::MONTH_YEAR, {month_name(d.m, true), std::to_string(d.y)});
}
std::string clock_label(long long t) {
  if (t <= 0) return "—";
  std::time_t tt = (std::time_t)t;
  std::tm tm{};
#ifdef _WIN32
  localtime_s(&tm, &tt);
#else
  localtime_r(&tt, &tm);
#endif
  char b[16];
  std::snprintf(b, sizeof b, "%02d:%02d", tm.tm_hour, tm.tm_min);
  return b;
}
std::string duration_label(int minutes) {
  if (minutes <= 0) return "—";
  return fmt(tx::DURATION, {std::to_string(minutes / 60), (minutes % 60 < 10 ? "0" : "") + std::to_string(minutes % 60)});
}
inline long long now_s() { return (long long)std::time(nullptr); }

// ------------------------------------------------------------ el modelo
struct Ticket {
  std::string origin, destination, airline, flight_number, depart_at, return_at, link;
  double price = 0;
  int transfers = 0, return_transfers = 0, duration = 0;
};

struct Snapshot {
  long long t = 0;
  double price = 0;
  std::string airline;
};

struct Route {
  int id = 0;
  std::string from_text, to_text;     // lo que escribió el usuario
  std::string from, to;               // los códigos IATA (al resolverlos)
  std::string from_name, to_name;
  std::string depart, ret;            // «2026-12», «2026-12-20» o vacío
  std::string currency = "EUR";
  bool direct = false;
  double target = 0;                  // avisar por debajo (0: no)
  std::vector<Snapshot> history;
  // El último análisis.
  std::vector<Ticket> tickets;
  std::vector<Ticket> days;           // el más barato de cada día
  long long last = 0;
  bool sample = false;
  std::string error;
  bool loading = false;
  std::string title() const {
    std::string a = from_name.empty() ? from_text : from_name, b = to_name.empty() ? to_text : to_name;
    return a + (from.empty() ? "" : " (" + from + ")") + " → " + b + (to.empty() ? "" : " (" + to + ")");
  }
  std::string short_title() const {
    return (from.empty() ? from_text : from) + " → " + (to.empty() ? to_text : to) + " · " + depart +
           (ret.empty() ? "" : " / " + ret);
  }
};

// Lo mejor de cada aerolínea.
struct Best {
  std::string airline;
  Ticket t;
  int offers = 0;
};

std::vector<Best> by_airline(const std::vector<Ticket>& ts) {
  std::vector<Best> out;
  for (const auto& t : ts) {
    if (t.price <= 0 || t.airline.empty()) continue;
    auto it = std::find_if(out.begin(), out.end(), [&](const Best& b) { return b.airline == t.airline; });
    if (it == out.end()) {
      out.push_back({t.airline, t, 1});
    } else {
      it->offers++;
      if (t.price < it->t.price || (t.price == it->t.price && t.transfers < it->t.transfers)) it->t = t;
    }
  }
  std::stable_sort(out.begin(), out.end(), [](const Best& a, const Best& b) { return a.t.price < b.t.price; });
  return out;
}

double median(std::vector<double> v) {
  if (v.empty()) return 0;
  std::sort(v.begin(), v.end());
  size_t n = v.size();
  return n % 2 ? v[n / 2] : (v[n / 2 - 1] + v[n / 2]) / 2;
}

const Ticket* cheapest(const std::vector<Ticket>& ts) {
  const Ticket* best = nullptr;
  for (const auto& t : ts)
    if (t.price > 0 && (!best || t.price < best->price)) best = &t;
  return best;
}

// ¿Qué hay que avisar tras un análisis? 1: bajó; 2: por debajo del objetivo.
int alert_of(const Route& r) {
  if (r.history.empty()) return 0;
  double now = r.history.back().price;
  int a = 0;
  if (r.history.size() >= 2 && now < r.history[r.history.size() - 2].price - 0.5) a |= 1;
  if (r.target > 0 && now <= r.target) {
    bool was_above = r.history.size() < 2 || r.history[r.history.size() - 2].price > r.target;
    if (was_above) a |= 2;
  }
  return a;
}

// ------------------------------------------------------------ enlaces para comprar
// El «link» de la API es una ruta de Aviasales («/search/MAD1412HAV1?t=…»):
// solo se aceptan rutas del propio sitio (nada que cambie de dominio).
const char* const BOOKING_HOST = "https://www.aviasales.com";

std::string url_encode(const std::string& s) {
  std::string o;
  char b[4];
  for (unsigned char c : s) {
    if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') o += (char)c;
    else { std::snprintf(b, sizeof b, "%%%02X", c); o += b; }
  }
  return o;
}

std::string booking_url(const std::string& link, const std::string& marker) {
  if (link.size() < 2 || link[0] != '/' || link[1] == '/' || link[1] == '\\') return "";
  for (char c : link)
    if ((unsigned char)c <= ' ' || c == '"' || c == '\\' || c == '@') return "";
  std::string u = std::string(BOOKING_HOST) + link;
  std::string m = trim(marker);
  bool digits = !m.empty() && std::all_of(m.begin(), m.end(), [](char c) { return std::isdigit((unsigned char)c); });
  if (digits) u += (link.find('?') == std::string::npos ? "?" : "&") + std::string("marker=") + m;
  return u;
}

// Sin «link» (o en los datos de ejemplo): la búsqueda de esa ruta y esas fechas.
std::string route_link(const std::string& from, const std::string& to, const std::string& depart_at,
                       const std::string& return_at) {
  if (!is_iata(from) || !is_iata(to)) return "";
  Date d = parse_date(depart_at.substr(0, 10));
  if (!d.ok() || !d.d) return "";
  char b[64];
  std::snprintf(b, sizeof b, "/search/%s%02d%02d%s", upper(from).c_str(), d.d, d.m, upper(to).c_str());
  std::string l = b;
  Date r = parse_date(return_at.substr(0, std::min<size_t>(10, return_at.size())));
  if (r.ok() && r.d) {
    std::snprintf(b, sizeof b, "%02d%02d", r.d, r.m);
    l += b;
  }
  return l + "1";
}

// ------------------------------------------------------------ las respuestas de la API
std::vector<Ticket> parse_tickets(const Json& data) {
  std::vector<Ticket> out;
  auto one = [&](const Json& j) {
    if (j.t != Json::OBJ) return;
    Ticket t;
    t.origin = j["origin"].str();
    t.destination = j["destination"].str();
    t.airline = j["airline"].str();
    t.flight_number = j["flight_number"].str();
    t.depart_at = j["departure_at"].str();
    t.return_at = j["return_at"].str();
    t.link = j["link"].str();
    t.price = j["price"].num();
    t.transfers = (int)j["transfers"].num();
    t.return_transfers = (int)j["return_transfers"].num();
    t.duration = (int)j["duration"].num();
    if (t.price > 0) out.push_back(t);
  };
  if (data.t == Json::ARR)
    for (const auto& j : data.a) one(j);
  else if (data.t == Json::OBJ)   // grouped_prices: {"2026-12-14": {...}, …}
    for (const auto& p : data.o) one(p.second);
  return out;
}

// La respuesta entera: {"success": true, "data": [...], "currency": "eur"}.
bool parse_response(const std::string& body, std::vector<Ticket>& out, std::string& err) {
  Json j;
  if (!parse_json(body, j)) { err = tx::ERR_BAD_ANSWER; return false; }
  if (j["success"].t == Json::BOOL && !j["success"].b) {
    err = j["error"].str(tx::ERR_BAD_ANSWER);
    return false;
  }
  out = parse_tickets(j["data"]);
  return true;
}

// El primer resultado de autocomplete.travelpayouts.com/places2.
bool parse_place(const std::string& body, std::string& code, std::string& name) {
  Json j;
  if (!parse_json(body, j) || j.t != Json::ARR || j.a.empty()) return false;
  for (const auto& p : j.a) {
    std::string c = p["code"].str();
    if (!is_iata(c)) continue;
    code = upper(c);
    name = p["name"].str(code);
    return true;
  }
  return false;
}

// ------------------------------------------------------------ ciudades y aerolíneas conocidas
// Para trabajar sin conexión y para los datos de ejemplo.
struct City {
  const char* code;
  const char* es;
  const char* en;
  double lat, lon;
};
const City CITIES[] = {
    {"MAD", "Madrid", "Madrid", 40.42, -3.70},           {"BCN", "Barcelona", "Barcelona", 41.39, 2.17},
    {"VLC", "Valencia", "Valencia", 39.47, -0.38},       {"SVQ", "Sevilla", "Seville", 37.39, -5.98},
    {"AGP", "Málaga", "Malaga", 36.72, -4.42},           {"BIO", "Bilbao", "Bilbao", 43.26, -2.93},
    {"PMI", "Palma de Mallorca", "Palma de Mallorca", 39.57, 2.65},
    {"LPA", "Gran Canaria", "Gran Canaria", 27.93, -15.39}, {"TCI", "Tenerife", "Tenerife", 28.29, -16.63},
    {"LIS", "Lisboa", "Lisbon", 38.72, -9.14},           {"PAR", "París", "Paris", 48.86, 2.35},
    {"LON", "Londres", "London", 51.51, -0.13},          {"ROM", "Roma", "Rome", 41.90, 12.50},
    {"MIL", "Milán", "Milan", 45.46, 9.19},              {"FRA", "Fráncfort", "Frankfurt", 50.11, 8.68},
    {"AMS", "Ámsterdam", "Amsterdam", 52.37, 4.90},      {"BER", "Berlín", "Berlin", 52.52, 13.40},
    {"IST", "Estambul", "Istanbul", 41.01, 28.98},       {"HAV", "La Habana", "Havana", 23.11, -82.37},
    {"MIA", "Miami", "Miami", 25.76, -80.19},            {"NYC", "Nueva York", "New York", 40.71, -74.01},
    {"MEX", "Ciudad de México", "Mexico City", 19.43, -99.13}, {"CUN", "Cancún", "Cancun", 21.16, -86.85},
    {"BOG", "Bogotá", "Bogota", 4.71, -74.07},           {"MDE", "Medellín", "Medellin", 6.24, -75.58},
    {"LIM", "Lima", "Lima", -12.05, -77.04},             {"SCL", "Santiago de Chile", "Santiago", -33.45, -70.67},
    {"BUE", "Buenos Aires", "Buenos Aires", -34.60, -58.38}, {"MVD", "Montevideo", "Montevideo", -34.90, -56.16},
    {"SDQ", "Santo Domingo", "Santo Domingo", 18.49, -69.93}, {"PUJ", "Punta Cana", "Punta Cana", 18.58, -68.40},
    {"SJU", "San Juan", "San Juan", 18.47, -66.11},      {"CCS", "Caracas", "Caracas", 10.48, -66.90},
    {"PTY", "Panamá", "Panama City", 8.98, -79.52},      {"SJO", "San José (Costa Rica)", "San Jose (Costa Rica)", 9.93, -84.08},
    {"LAX", "Los Ángeles", "Los Angeles", 34.05, -118.24}, {"ORL", "Orlando", "Orlando", 28.54, -81.38},
    {"SAO", "São Paulo", "Sao Paulo", -23.55, -46.63},   {"RIO", "Río de Janeiro", "Rio de Janeiro", -22.91, -43.17},
    {"TYO", "Tokio", "Tokyo", 35.68, 139.69},            {"DXB", "Dubái", "Dubai", 25.20, 55.27},
};

std::string fold(const std::string& s) {   // «Bogotá» → «bogota»
  static const char* const from[] = {"á", "é", "í", "ó", "ú", "ü", "ñ", "Á", "É", "Í", "Ó", "Ú", "Ñ", "ã", "ç"};
  static const char* const to[] = {"a", "e", "i", "o", "u", "u", "n", "a", "e", "i", "o", "u", "n", "a", "c"};
  std::string o = lower(trim(s));
  for (size_t k = 0; k < sizeof from / sizeof from[0]; k++)
    for (size_t p = o.find(from[k]); p != std::string::npos; p = o.find(from[k])) o.replace(p, std::strlen(from[k]), to[k]);
  return o;
}

const City* find_city(const std::string& text) {
  std::string f = fold(text);
  for (const auto& c : CITIES)
    if (f == lower(c.code) || f == fold(c.es) || f == fold(c.en)) return &c;
  return nullptr;
}
std::string city_name(const City& c) { return lang() == "es" ? c.es : c.en; }

double km_between(const City& a, const City& b) {
  double la1 = a.lat * PI / 180, la2 = b.lat * PI / 180, dl = (b.lon - a.lon) * PI / 180;
  double h = std::pow(std::sin((la2 - la1) / 2), 2) + std::cos(la1) * std::cos(la2) * std::pow(std::sin(dl / 2), 2);
  return 2 * 6371 * std::asin(std::sqrt(h));
}

struct AirlineInfo {
  const char* code;
  const char* name;
};
const AirlineInfo AIRLINES[] = {
    {"IB", "Iberia"}, {"UX", "Air Europa"}, {"2W", "World2fly"}, {"PU", "Plus Ultra"}, {"CU", "Cubana"},
    {"AF", "Air France"}, {"KL", "KLM"}, {"LH", "Lufthansa"}, {"TP", "TAP Air Portugal"}, {"TK", "Turkish Airlines"},
    {"BA", "British Airways"}, {"DL", "Delta"}, {"UA", "United"}, {"AA", "American Airlines"}, {"AM", "Aeroméxico"},
    {"CM", "Copa Airlines"}, {"AV", "Avianca"}, {"LA", "LATAM"}, {"VY", "Vueling"}, {"FR", "Ryanair"},
    {"U2", "easyJet"}, {"EK", "Emirates"}, {"AR", "Aerolíneas Argentinas"}, {"B6", "JetBlue"}, {"AZ", "ITA Airways"},
};
std::string known_airline(const std::string& code) {
  for (const auto& a : AIRLINES)
    if (code == a.code) return a.name;
  return "";
}

// ------------------------------------------------------------ datos de ejemplo
// Sin token: precios inventados pero creíbles (por la distancia), que cambian
// un poco cada media hora. Siempre se marcan como ejemplo.
inline uint32_t hash_str(const std::string& s, uint32_t h = 2166136261u) {
  for (unsigned char c : s) { h ^= c; h *= 16777619u; }
  return h;
}
inline double unit(uint32_t h) {
  h ^= h >> 15; h *= 2246822519u; h ^= h >> 13; h *= 3266489917u; h ^= h >> 16;
  return (h & 0xffffff) / 16777216.0;
}
double rate(const std::string& cur) {   // euros → moneda (aproximado, solo para el ejemplo)
  std::string c = upper(cur);
  if (c == "USD") return 1.08;
  if (c == "GBP") return 0.85;
  if (c == "MXN") return 19.5;
  if (c == "COP") return 4300;
  if (c == "ARS") return 1050;
  return 1;
}

void sample_analysis(Route& r, long long now) {
  const City* a = find_city(r.from.empty() ? r.from_text : r.from);
  const City* b = find_city(r.to.empty() ? r.to_text : r.to);
  double km = a && b ? km_between(*a, *b) : 2500 + 6000 * unit(hash_str(r.from + r.to));
  Date dep = parse_date(r.depart), ret = parse_date(r.ret);
  bool round = ret.ok();
  double base = (35 + km * 0.052) * (round ? 1.72 : 1) * rate(r.currency);
  uint32_t seed = hash_str(r.from + ">" + r.to + r.depart + r.ret + r.currency + (r.direct ? "d" : ""));
  long long slot = now / 1800;
  // Las aerolíneas que vuelan esa ruta (unas cuantas, siempre las mismas).
  std::vector<const AirlineInfo*> pool;
  for (const auto& al : AIRLINES) {
    // Las de bajo coste no cruzan el océano.
    const std::string c = al.code;
    if (km > 3000 && (c == "VY" || c == "FR" || c == "U2")) continue;
    if (unit(seed ^ hash_str(al.code)) < (km > 3000 ? 0.48 : 0.36)) pool.push_back(&al);
  }
  if (pool.size() < 5) pool.insert(pool.end(), {&AIRLINES[0], &AIRLINES[1], &AIRLINES[5], &AIRLINES[8], &AIRLINES[9]});
  if (pool.size() > 11) pool.resize(11);
  std::vector<int> days;
  if (dep.d) days.push_back(dep.d);
  else for (int d = 1; d <= days_in(dep.y, dep.m); d++) days.push_back(d);
  r.tickets.clear();
  r.days.clear();
  int stay = round ? std::max(3, (int)(key(ret) - key(dep)) % 100) : 0;
  for (size_t k = 0; k < pool.size(); k++) {
    const AirlineInfo& al = *pool[k];
    uint32_t h = seed ^ hash_str(al.code) * 2654435761u;
    double airline_factor = 0.82 + 0.5 * unit(h);
    int stops_min = r.direct ? 0 : (unit(h + 7) < 0.45 ? 0 : 1);
    int n = 3 + (int)(unit(h + 3) * 5);
    for (int i = 0; i < n; i++) {
      int day = days[(size_t)(unit(h + 100 + i) * days.size()) % days.size()];
      // Se mueve cada media hora: dos ondas lentas y un poco de ruido.
      double drift = 1 + 0.03 * std::sin(slot * 0.37 + k * 1.7 + i) + 0.02 * std::sin(slot * 0.113 + k * 0.9) +
                     0.025 * (unit(hash_str(std::to_string(slot), h + i)) - 0.5);
      double dayf = 0.9 + 0.25 * unit(seed + day * 31) + (day % 7 == 5 || day % 7 == 6 ? 0.08 : 0);
      Ticket t;
      t.origin = r.from;
      t.destination = r.to;
      t.airline = al.code;
      t.transfers = std::min(2, stops_min + (unit(h + 200 + i) < 0.3 ? 1 : 0));
      if (r.direct) t.transfers = 0;
      t.price = std::max(19.0, std::round(base * airline_factor * dayf * drift * (1 - 0.07 * t.transfers)));
      int hour = 6 + (int)(unit(h + 300 + i) * 16), minute = (int)(unit(h + 400 + i) * 12) * 5;
      char at[40];
      std::snprintf(at, sizeof at, "%04d-%02d-%02dT%02d:%02d:00", dep.y, dep.m, day, hour, minute);
      t.depart_at = at;
      if (round) {
        Date back = ret.d ? ret : Date{ret.y, ret.m, clampi(day + stay % 20, 1, days_in(ret.y, ret.m))};
        std::snprintf(at, sizeof at, "%04d-%02d-%02dT%02d:%02d:00", back.y, back.m, back.d, (hour + 7) % 24, minute);
        t.return_at = at;
        t.return_transfers = t.transfers;
      }
      t.duration = (int)(km / 820 * 60 + 40 + t.transfers * (95 + unit(h + i) * 120)) * (round ? 2 : 1);
      t.flight_number = std::to_string(100 + (int)(unit(h + 500 + i) * 8800));
      t.link = route_link(r.from, r.to, t.depart_at, t.return_at);
      r.tickets.push_back(t);
    }
  }
  std::sort(r.tickets.begin(), r.tickets.end(), [](const Ticket& x, const Ticket& y) { return x.price < y.price; });
  for (int d : days) {
    const Ticket* best = nullptr;
    for (const auto& t : r.tickets)
      if (parse_date(t.depart_at.substr(0, 10)).d == d && (!best || t.price < best->price)) best = &t;
    if (best) r.days.push_back(*best);
  }
  r.sample = true;
}

// ------------------------------------------------------------ guardar
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_FLIGHTS_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\flights";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/flights";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/flights";
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

struct Settings {
  std::string token, marker;
  bool autorun = true, notify = true;
};

// Una línea por ruta, campos separados por tabuladores; el historial va en
// «precio@hora@aerolínea» separados por comas.
std::string clean(const std::string& s) {
  std::string o = s;
  for (auto& c : o)
    if (c == '\t' || c == '\n' || c == '\r' || c == ',' || c == '@') c = ' ';
  return o;
}

std::string save_text(const std::vector<Route>& routes, const Settings& st) {
  std::string o = "# DMarlon Studio · flights 1\n";
  o += "token\t" + clean(st.token) + "\nmarker\t" + clean(st.marker) + "\n";
  o += std::string("auto\t") + (st.autorun ? "1" : "0") + "\nnotify\t" + (st.notify ? "1" : "0") + "\n";
  for (const auto& r : routes) {
    char tgt[32];
    std::snprintf(tgt, sizeof tgt, "%.2f", r.target);
    o += "route\t" + clean(r.from_text) + "\t" + clean(r.to_text) + "\t" + clean(r.from) + "\t" + clean(r.to) + "\t" +
         clean(r.from_name) + "\t" + clean(r.to_name) + "\t" + clean(r.depart) + "\t" + clean(r.ret) + "\t" +
         clean(r.currency) + "\t" + (r.direct ? "1" : "0") + "\t" + tgt + "\t" + std::to_string(r.last) + "\t";
    size_t from = r.history.size() > 400 ? r.history.size() - 400 : 0;
    for (size_t i = from; i < r.history.size(); i++) {
      const auto& h = r.history[i];
      char b[96];
      std::snprintf(b, sizeof b, "%s%.2f@%lld@%s", i > from ? "," : "", h.price, h.t, clean(h.airline).c_str());
      o += b;
    }
    o += "\n";
  }
  return o;
}

void load_text(const std::string& text, std::vector<Route>& routes, Settings& st) {
  routes.clear();
  int id = 1;
  for (const auto& line : split(text, '\n')) {
    auto f = split(line, '\t');
    if (f.size() == 2 && f[0] == "token") st.token = trim(f[1]);
    else if (f.size() == 2 && f[0] == "marker") st.marker = trim(f[1]);
    else if (f.size() == 2 && f[0] == "auto") st.autorun = f[1] == "1";
    else if (f.size() == 2 && f[0] == "notify") st.notify = f[1] == "1";
    else if (f.size() >= 13 && f[0] == "route") {
      Route r;
      r.id = id++;
      r.from_text = f[1]; r.to_text = f[2]; r.from = f[3]; r.to = f[4];
      r.from_name = f[5]; r.to_name = f[6]; r.depart = f[7]; r.ret = f[8];
      r.currency = f[9].empty() ? "EUR" : f[9];
      r.direct = f[10] == "1";
      r.target = std::atof(f[11].c_str());
      r.last = 0;   // al abrir se analiza otra vez
      if (f.size() >= 14 && !f[13].empty())
        for (const auto& h : split(f[13], ',')) {
          auto p = split(h, '@');
          if (p.size() < 2) continue;
          Snapshot s;
          s.price = std::atof(p[0].c_str());
          s.t = std::atoll(p[1].c_str());
          if (p.size() > 2) s.airline = p[2];
          if (s.price > 0 && s.t > 0) r.history.push_back(s);
        }
      routes.push_back(r);
    }
  }
}

// ------------------------------------------------------------ internet (con curl)
// Las peticiones van con el programa curl, que traen macOS y Windows 10 y
// posteriores: así la app no necesita más bibliotecas. Las opciones (y el
// token) van en un archivo temporal, no en la línea de órdenes.
struct HttpResult {
  int status = 0;
  std::string body, error;
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

std::string curl_config(const std::string& url, const std::vector<std::string>& headers) {
  std::string c = "url = " + curl_quote(url) + "\n";
  for (const auto& h : headers) c += "header = " + curl_quote(h) + "\n";
  c += "silent\nshow-error\nlocation\nmax-time = 30\nconnect-timeout = 12\n";
  c += "user-agent = \"DMarlonStudio-Flights/1.0\"\n";
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
  std::string cmd = "curl -K " + q + " 2>&1";
  FILE* p = popen(cmd.c_str(), "r");
  if (!p) return -1;
  char buf[8192];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, p)) > 0) out.append(buf, n);
  int st = pclose(p);
  return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
#endif
}

HttpResult http_get(const std::string& url, const std::vector<std::string>& headers) {
  HttpResult r;
  static std::atomic<int> counter{0};
  std::string dir = config_dir();
  fl_make_path(dir.c_str());
  std::string path = dir + "/req-" + std::to_string((long long)now_s()) + "-" + std::to_string(counter++) + ".cfg";
#ifndef _WIN32
  mode_t old = umask(077);   // solo el usuario puede leerlo (lleva el token)
#endif
  bool wrote = write_file(path, curl_config(url, headers));
#ifndef _WIN32
  umask(old);
#endif
  if (!wrote) { r.error = tx::ERR_NETWORK; return r; }
  std::string out;
  int code = run_capture(path, out);
  std::remove(path.c_str());
  size_t nl = out.find_last_of('\n');
  if (code != 0 || nl == std::string::npos) {
    r.error = code < 0 ? tx::ERR_NO_CURL : tx::ERR_NETWORK;
    return r;
  }
  r.status = std::atoi(out.c_str() + nl + 1);
  r.body = out.substr(0, nl);
  return r;
}

// ------------------------------------------------------------ la API
const char* const API = "https://api.travelpayouts.com";

std::string market_of(const std::string& cur) {
  std::string c = upper(cur);
  if (c == "USD") return "us";
  if (c == "GBP") return "uk";
  if (c == "MXN") return "mx";
  if (c == "COP") return "co";
  if (c == "ARS") return "ar";
  return "es";
}

std::string prices_url(const Route& r) {
  std::string u = std::string(API) + "/aviasales/v3/prices_for_dates?origin=" + r.from + "&destination=" + r.to +
                  "&departure_at=" + url_encode(r.depart) + "&currency=" + lower(r.currency) + "&market=" +
                  market_of(r.currency) + "&sorting=price&limit=1000&unique=false";
  if (!r.ret.empty()) u += "&return_at=" + url_encode(r.ret) + "&one_way=false";
  else u += "&one_way=true";
  if (r.direct) u += "&direct=true";
  return u;
}
std::string calendar_url(const Route& r) {
  std::string month = r.depart.substr(0, 7);
  std::string u = std::string(API) + "/aviasales/v3/grouped_prices?origin=" + r.from + "&destination=" + r.to +
                  "&group_by=departure_at&departure_at=" + url_encode(month) + "&currency=" + lower(r.currency) +
                  "&market=" + market_of(r.currency);
  if (!r.ret.empty()) u += "&return_at=" + url_encode(r.ret.substr(0, 7));
  if (r.direct) u += "&direct=true";
  return u;
}
std::string places_url(const std::string& term) {
  return "https://autocomplete.travelpayouts.com/places2?term=" + url_encode(term) + "&locale=" + lang() +
         "&types[]=city&types[]=airport";
}

// Las pruebas y las capturas no salen a internet.
inline bool g_offline = false;

// Origen y destino a códigos: los conocidos sin conexión, el resto preguntando.
bool resolve(const std::string& text, std::string& code, std::string& name, bool online) {
  if (const City* c = find_city(text)) {
    code = c->code;
    name = city_name(*c);
    return true;
  }
  if (online && !g_offline) {
    HttpResult h = http_get(places_url(text), {});
    if (h.status == 200 && parse_place(h.body, code, name)) return true;
  }
  if (is_iata(trim(text))) {
    code = upper(trim(text));
    name = code;
    return true;
  }
  return false;
}

std::string error_of(const HttpResult& h) {
  if (!h.error.empty()) return h.error;
  if (h.status == 401 || h.status == 403) return tx::ERR_TOKEN;
  if (h.status == 429) return tx::ERR_LIMIT;
  return fmt(tx::ERR_HTTP, {std::to_string(h.status)});
}

// Un análisis completo de la ruta (en otro hilo: no toca la interfaz).
void analyze(Route& r, const Settings& st, long long now) {
  r.error.clear();
  bool real = !trim(st.token).empty();
  if (r.from.empty() && !resolve(r.from_text, r.from, r.from_name, true)) {
    r.error = fmt(tx::ERR_PLACE, {r.from_text});
    return;
  }
  if (r.to.empty() && !resolve(r.to_text, r.to, r.to_name, true)) {
    r.error = fmt(tx::ERR_PLACE, {r.to_text});
    return;
  }
  if (!real) {
    sample_analysis(r, now);
  } else {
    std::vector<std::string> hdr = {"X-Access-Token: " + trim(st.token), "Accept: application/json"};
    HttpResult h = http_get(prices_url(r), hdr);
    std::vector<Ticket> ts;
    std::string err;
    if (h.status != 200) { r.error = error_of(h); return; }
    if (!parse_response(h.body, ts, err)) { r.error = err; return; }
    std::vector<Ticket> days;
    HttpResult c = http_get(calendar_url(r), hdr);
    if (c.status == 200) parse_response(c.body, days, err);
    std::sort(days.begin(), days.end(), [](const Ticket& a, const Ticket& b) { return a.depart_at < b.depart_at; });
    r.tickets = ts;
    r.days = days;
    r.sample = false;
  }
  r.last = now;
  if (const Ticket* t = cheapest(r.tickets)) r.history.push_back({now, t->price, t->airline});
}

// Los nombres de las aerolíneas (api.travelpayouts.com/data/<idioma>/airlines.json).
std::map<std::string, std::string> parse_airlines(const std::string& body) {
  std::map<std::string, std::string> m;
  Json j;
  if (!parse_json(body, j) || j.t != Json::ARR) return m;
  for (const auto& a : j.a) {
    std::string code = a["code"].str();
    if (code.empty()) continue;
    std::string name = a["name"].str();
    if (name.empty()) name = a["name_translations"][lang()].str();
    if (name.empty()) name = a["name_translations"]["en"].str();
    if (!name.empty()) m[code] = name;
  }
  return m;
}

}  // namespace fx

// ============================================================ el análisis en pantalla
// El panel de la derecha se dibuja en código: el resumen, la tabla con lo más
// barato de cada aerolínea y su botón para comprar, el precio de cada día del
// mes y cómo ha ido cambiando el mejor precio en cada análisis.
namespace fx {

const uint32_t C_BG = 0xffffff, C_TEXT = 0x1f2937, C_DIM = 0x6b7280, C_LINE = 0xe5e7eb, C_CARD = 0xf4f6fb,
               C_ACCENT = 0x2563eb, C_GOOD = 0x15803d, C_BAD = 0xdc2626, C_WARN = 0xfff4d6, C_WARN_LINE = 0xf3c969;

inline Fl_Color rgb(uint32_t v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void col(uint32_t v) { fl_color(rgb(v)); }

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

class ResultsView : public Fl_Widget {
public:
  const Route* route = nullptr;
  std::string currency_hint;
  std::map<std::string, std::string>* airline_names = nullptr;
  std::map<std::string, std::unique_ptr<Fl_RGB_Image>>* logos = nullptr;
  std::string marker;
  bool loading = false;
  int scroll = 0, content_h = 0;
  int hover_x = -1, hover_y = -1;
  std::vector<std::pair<Box, std::string>> links;   // botones y barras: qué abren
  std::vector<std::pair<Box, std::string>> tips;    // lo que se ve al pasar por encima
  std::function<void(const std::string&)> on_open;
  bool shooting = false;

  ResultsView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  std::string airline_name(const std::string& code) const {
    if (airline_names) {
      auto it = airline_names->find(code);
      if (it != airline_names->end()) return it->second;
    }
    std::string k = known_airline(code);
    return k.empty() ? code : k;
  }

  void draw() override { render(x(), y(), w(), h()); }

  void render(int X, int Y, int W, int H) {
    links.clear();
    tips.clear();
    fl_push_clip(X, Y, W, H);
    col(C_BG);
    fl_rectf(X, Y, W, H);
    const int P = 24;
    int y = Y + 20 - scroll, x0 = X + P, w0 = W - 2 * P;
    if (!route) {
      empty_state(X, Y, W, H);
      fl_pop_clip();
      return;
    }
    const Route& r = *route;
    // ---- el título
    text(fit(r.title(), w0, 20, true), x0, y + 20, C_TEXT, 20, true);
    y += 30;
    Date dep = parse_date(r.depart), ret = parse_date(r.ret);
    std::string sub = fmt(tx::SUB_OUT, {period_label(dep)});
    sub += r.ret.empty() ? " · " + std::string(tx::ONE_WAY) : " · " + fmt(tx::SUB_BACK, {period_label(ret)});
    if (r.direct) sub += " · " + std::string(tx::DIRECT_ONLY);
    sub += " · " + upper(r.currency);
    text(fit(sub, w0, 13), x0, y + 14, C_DIM, 13);
    y += 26;
    if (r.sample) {
      Box b{x0, y, w0, 34};
      rbox(b, C_WARN);
      col(C_WARN_LINE);
      fl_rect(b.x, b.y, b.w, b.h);
      text(fit(tx::SAMPLE_BANNER, w0 - 24, 12, true), x0 + 12, y + 22, 0x7a5200, 12, true);
      y += 46;
    }
    if (!r.error.empty()) {
      Box b{x0, y, w0, 34};
      rbox(b, 0xfde8e8);
      text(fit(r.error, w0 - 24, 13, true), x0 + 12, y + 22, C_BAD, 13, true);
      y += 46;
    }
    if (r.tickets.empty()) {
      text(loading ? tx::ANALYZING : r.error.empty() ? tx::NO_PRICES : "", x0, y + 24, C_DIM, 15);
      content_h = y + 40 + scroll - Y;
      fl_pop_clip();
      return;
    }
    // ---- el resumen
    const Ticket* best = cheapest(r.tickets);
    std::vector<double> prices;
    for (const auto& t : r.tickets) prices.push_back(t.price);
    auto bests = by_airline(r.tickets);
    int cw = (w0 - 3 * 14) / 4, ch = 92;
    auto card = [&](int i, const std::string& title, const std::string& big, uint32_t big_c, const std::string& small) {
      Box b{x0 + i * (cw + 14), y, cw, ch};
      rbox(b, C_CARD);
      text(fit(title, cw - 24, 12), b.x + 14, b.y + 22, C_DIM, 12);
      text(fit(big, cw - 24, 24, true), b.x + 14, b.y + 54, big_c, 24, true);
      text(fit(small, cw - 24, 12), b.x + 14, b.y + 76, C_DIM, 12);
    };
    card(0, tx::CARD_BEST, money(best->price, r.currency), C_GOOD,
         airline_name(best->airline) + " · " + day_label(best->depart_at));
    card(1, tx::CARD_MEDIAN, money(median(prices), r.currency), C_TEXT,
         fmt(tx::OFFERS_AIRLINES, {std::to_string(prices.size()), std::to_string(bests.size())}));
    // El cambio desde el análisis anterior.
    std::string chg = "=";
    uint32_t chg_c = C_TEXT;
    std::string chg_s = tx::FIRST_ANALYSIS;
    if (r.history.size() >= 2) {
      double d = r.history.back().price - r.history[r.history.size() - 2].price;
      if (d < -0.5) { chg = "↓ " + money(-d, r.currency); chg_c = C_GOOD; }
      else if (d > 0.5) { chg = "↑ " + money(d, r.currency); chg_c = C_BAD; }
      else chg = tx::SAME;
      chg_s = fmt(tx::SINCE, {clock_label(r.history[r.history.size() - 2].t)});
    }
    card(2, tx::CARD_CHANGE, chg, chg_c, chg_s);
    if (r.target > 0) {
      bool hit = best->price <= r.target;
      card(3, fmt(tx::CARD_TARGET, {money(r.target, r.currency)}),
           hit ? std::string(tx::TARGET_HIT) : money(best->price - r.target, r.currency), hit ? C_GOOD : C_TEXT,
           hit ? std::string(tx::TARGET_HIT_SMALL) : std::string(tx::TARGET_LEFT));
    } else {
      double lo = 1e18, hi = 0;
      for (const auto& h : r.history) { lo = std::min(lo, h.price); hi = std::max(hi, h.price); }
      card(3, tx::CARD_RANGE, r.history.empty() ? "—" : money(lo, r.currency), C_TEXT,
           r.history.empty() ? "" : fmt(tx::RANGE_SMALL, {money(hi, r.currency), std::to_string(r.history.size())}));
    }
    y += ch + 26;
    // ---- por aerolínea
    text(tx::BY_AIRLINE, x0, y + 16, C_TEXT, 16, true);
    text(fit(tx::BY_AIRLINE_HINT, w0 - width(tx::BY_AIRLINE, 16, true) - 16, 12),
         x0 + width(tx::BY_AIRLINE, 16, true) + 14, y + 16, C_DIM, 12);
    y += 30;
    // Las columnas se reparten el ancho que deja el botón de comprar.
    const int avail = w0 - 124;
    const int cols[] = {0, 88, (int)(avail * 0.37), (int)(avail * 0.51), (int)(avail * 0.67), (int)(avail * 0.84)};
    auto head = [&](int c, const char* s) { text(s, x0 + cols[c], y + 14, C_DIM, 12, true); };
    head(1, tx::COL_AIRLINE);
    head(2, tx::COL_PRICE);
    head(3, tx::COL_OUT);
    head(4, r.ret.empty() ? tx::COL_STOPS : tx::COL_BACK);
    head(5, tx::COL_DURATION);
    y += 22;
    col(C_LINE);
    fl_xyline(x0, y, x0 + w0);
    const int RH = 48;
    for (size_t i = 0; i < bests.size(); i++) {
      const Best& b = bests[i];
      Box row{x0, y, w0, RH};
      bool hov = row.has(hover_x, hover_y);
      if (i == 0) rbox({row.x, row.y + 2, row.w, row.h - 4}, 0xeefaf1);
      else if (hov) rbox({row.x, row.y + 2, row.w, row.h - 4}, 0xf6f8fc);
      int cy = y + RH / 2;
      // El logo (si ya llegó) o el código.
      Fl_RGB_Image* logo = nullptr;
      if (logos) {
        auto it = logos->find(b.airline);
        if (it != logos->end()) logo = it->second.get();
      }
      if (logo) logo->draw(x0 + 4, cy - 12);
      else {
        rbox({x0 + 4, cy - 12, 72, 24}, 0xe8edf6);
        text(b.airline, x0 + 40 - width(b.airline, 12, true) / 2, cy + 5, C_ACCENT, 12, true);
      }
      text(fit(airline_name(b.airline), cols[2] - cols[1] - 12, 14, true), x0 + cols[1], cy - 2, C_TEXT, 14, true);
      text(fit(fmt(tx::N_OFFERS, {std::to_string(b.offers)}), cols[2] - cols[1] - 12, 11), x0 + cols[1], cy + 14, C_DIM, 11);
      text(money(b.t.price, r.currency), x0 + cols[2], cy + 6, i == 0 ? C_GOOD : C_TEXT, 17, true);
      text(day_label(b.t.depart_at), x0 + cols[3], cy - 2, C_TEXT, 13);
      text(time_label(b.t.depart_at) + " · " + stops(b.t.transfers), x0 + cols[3], cy + 14, C_DIM, 11);
      if (r.ret.empty()) {
        text(stops(b.t.transfers), x0 + cols[4], cy + 5, b.t.transfers ? C_TEXT : C_GOOD, 13);
      } else {
        text(day_label(b.t.return_at), x0 + cols[4], cy - 2, C_TEXT, 13);
        text(time_label(b.t.return_at) + " · " + stops(b.t.return_transfers), x0 + cols[4], cy + 14, C_DIM, 11);
      }
      text(duration_label(b.t.duration), x0 + cols[5], cy + 5, C_TEXT, 13);
      // Comprar.
      std::string url = booking_url(b.t.link, marker);
      if (url.empty()) url = booking_url(route_link(r.from, r.to, b.t.depart_at, b.t.return_at), marker);
      Box btn{x0 + w0 - 112, cy - 15, 112, 30};
      bool bh = btn.has(hover_x, hover_y);
      rbox(btn, url.empty() ? 0xcbd5e1 : bh ? 0x1d4ed8 : C_ACCENT);
      text(tx::BUY, btn.x + (btn.w - width(tx::BUY, 13, true)) / 2, btn.y + 20, 0xffffff, 13, true);
      if (!url.empty()) {
        links.push_back({btn, url});
        tips.push_back({btn, tx::BUY_TIP});
      }
      y += RH;
      col(C_LINE);
      fl_xyline(x0, y, x0 + w0);
    }
    y += 30;
    // ---- el precio de cada día
    if (!r.days.empty()) {
      text(tx::BY_DAY, x0, y + 16, C_TEXT, 16, true);
      text(fit(tx::BY_DAY_HINT, w0 - width(tx::BY_DAY, 16, true) - 16, 12),
           x0 + width(tx::BY_DAY, 16, true) + 14, y + 16, C_DIM, 12);
      y += 30;
      y = day_chart(r, x0, y, w0, 170) + 26;
    }
    // ---- la evolución
    if (r.history.size() >= 1) {
      text(tx::HISTORY, x0, y + 16, C_TEXT, 16, true);
      text(fit(tx::HISTORY_HINT, w0 - width(tx::HISTORY, 16, true) - 16, 12),
           x0 + width(tx::HISTORY, 16, true) + 14, y + 16, C_DIM, 12);
      y += 30;
      y = history_chart(r, x0, y, w0, 150) + 20;
    }
    text(fit(tx::SOURCE_NOTE, w0, 11), x0, y + 12, C_DIM, 11);
    y += 30;
    content_h = y + scroll - Y;
    // La barra de desplazamiento.
    if (content_h > H) {
      int bh = std::max(30, H * H / content_h);
      int by = Y + (H - bh) * scroll / std::max(1, content_h - H);
      rbox({X + W - 7, by, 4, bh}, 0xc7ccd6);
    }
    // El aviso al pasar por encima.
    for (const auto& t : tips)
      if (t.first.has(hover_x, hover_y)) tooltip_box(t.second, hover_x, hover_y, X, Y, W, H);
    fl_pop_clip();
  }

  static std::string stops(int n) {
    if (n <= 0) return tx::DIRECT;
    return n == 1 ? std::string(tx::ONE_STOP) : fmt(tx::N_STOPS, {std::to_string(n)});
  }

  void tooltip_box(const std::string& s, int mx, int my, int X, int Y, int W, int H) {
    auto lines = split(s, '\n');
    int w = 0;
    for (const auto& l : lines) w = std::max(w, width(l, 12));
    Box b{mx + 14, my + 16, w + 20, (int)lines.size() * 17 + 12};
    if (b.x + b.w > X + W - 4) b.x = mx - b.w - 10;
    if (b.y + b.h > Y + H - 4) b.y = my - b.h - 10;
    rbox(b, 0x111827);
    for (size_t i = 0; i < lines.size(); i++) text(lines[i], b.x + 10, b.y + 19 + (int)i * 17, 0xffffff, 12);
  }

  int day_chart(const Route& r, int x0, int y, int w0, int h) {
    Box area{x0, y, w0, h};
    rbox(area, C_CARD);
    double lo = 1e18, hi = 0;
    for (const auto& d : r.days) { lo = std::min(lo, d.price); hi = std::max(hi, d.price); }
    int n = (int)r.days.size();
    int pad = 14, top = y + 26, bottom = y + h - 26;
    // Barras de 64 px como mucho (una ruta de un solo día), centradas.
    double bw = std::min(64.0, (w0 - 2.0 * pad) / std::max(1, n));
    int off = (int)((w0 - 2.0 * pad - bw * n) / 2);
    for (int i = 0; i < n; i++) {
      const Ticket& t = r.days[i];
      double f = hi > lo ? (t.price - lo) / (hi - lo) : 0.5;
      int bh = std::max(6, (int)(18 + f * (bottom - top - 18)));
      int bx = x0 + pad + off + (int)(i * bw) + 2, bwi = std::max(3, (int)bw - 4);
      Box bar{bx, bottom - bh, bwi, bh};
      bool cheapest_day = t.price <= lo + 0.01;
      bool hov = Box{bx - 2, top, bwi + 4, bottom - top}.has(hover_x, hover_y);
      rbox(bar, cheapest_day ? C_GOOD : hov ? 0x1d4ed8 : 0x93b4f5);
      Date d = parse_date(t.depart_at.substr(0, 10));
      if (n <= 16 || d.d % 2 == 1 || cheapest_day) {
        std::string dl = std::to_string(d.d);
        text(dl, bx + bwi / 2 - width(dl, 10) / 2, y + h - 9, cheapest_day ? C_GOOD : C_DIM, 10, cheapest_day);
      }
      if (cheapest_day) {
        std::string p = money(t.price, r.currency);
        int pw = width(p, 12, true);
        text(p, std::clamp(bx + bwi / 2 - pw / 2, x0 + 4, x0 + w0 - pw - 4), bottom - bh - 6, C_GOOD, 12, true);
      }
      std::string url = booking_url(t.link, marker);
      if (url.empty()) url = booking_url(route_link(r.from, r.to, t.depart_at, t.return_at), marker);
      Box hit{bx - 2, top, bwi + 4, bottom - top};
      if (!url.empty()) links.push_back({hit, url});
      tips.push_back({hit, period_label(d) + "\n" + money(t.price, r.currency) + " · " + airline_name(t.airline) +
                               " · " + stops(t.transfers) + "\n" + tx::CLICK_TO_BUY});
    }
    text(fmt(tx::CHEAPEST_DAY, {money(lo, r.currency)}), x0 + pad, y + 18, C_DIM, 12);
    return y + h;
  }

  int history_chart(const Route& r, int x0, int y, int w0, int h) {
    rbox({x0, y, w0, h}, C_CARD);
    size_t from = r.history.size() > 96 ? r.history.size() - 96 : 0;   // las últimas 48 horas
    std::vector<Snapshot> hs(r.history.begin() + from, r.history.end());
    double lo = 1e18, hi = 0;
    for (const auto& s : hs) { lo = std::min(lo, s.price); hi = std::max(hi, s.price); }
    if (hi - lo < 1) { lo -= 5; hi += 5; }
    int pad = 16, left = x0 + 70, right = x0 + w0 - pad, top = y + 16, bottom = y + h - 26;
    for (int k = 0; k <= 2; k++) {
      double v = lo + (hi - lo) * k / 2;
      int yy = bottom - (int)((v - lo) / (hi - lo) * (bottom - top));
      col(0xdde3ee);
      fl_xyline(left, yy, right);
      std::string s = money(v, r.currency);
      text(s, left - 8 - width(s, 10), yy + 4, C_DIM, 10);
    }
    auto px = [&](size_t i) { return hs.size() <= 1 ? (left + right) / 2 : left + (int)((right - left) * i / (hs.size() - 1)); };
    auto py = [&](double v) { return bottom - (int)((v - lo) / (hi - lo) * (bottom - top)); };
    col(C_ACCENT);
    fl_line_style(FL_SOLID | FL_CAP_ROUND | FL_JOIN_ROUND, 2);
    for (size_t i = 1; i < hs.size(); i++) fl_line(px(i - 1), py(hs[i - 1].price), px(i), py(hs[i].price));
    fl_line_style(0);
    for (size_t i = 0; i < hs.size(); i++) {
      int cx = px(i), cy = py(hs[i].price);
      bool last = i + 1 == hs.size();
      col(last ? C_GOOD : C_ACCENT);
      fl_pie(cx - (last ? 5 : 3), cy - (last ? 5 : 3), last ? 10 : 6, last ? 10 : 6, 0, 360);
      tips.push_back({Box{cx - 6, top, 12, bottom - top},
                      clock_label(hs[i].t) + " · " + money(hs[i].price, r.currency) + "\n" + airline_name(hs[i].airline)});
    }
    if (!hs.empty()) {
      text(clock_label(hs.front().t), left, y + h - 8, C_DIM, 10);
      std::string l = clock_label(hs.back().t);
      text(l, right - width(l, 10), y + h - 8, C_DIM, 10);
    }
    return y + h;
  }

  void empty_state(int X, int Y, int W, int H) {
    int cx = X + W / 2, cy = Y + H / 2 - 40;
    // Un avión sencillo.
    col(0xc7d2fe);
    fl_line_style(FL_SOLID | FL_CAP_ROUND, 6);
    fl_line(cx - 40, cy, cx + 40, cy);
    fl_line(cx - 4, cy, cx - 22, cy - 30);
    fl_line(cx - 4, cy, cx - 22, cy + 30);
    fl_line(cx - 34, cy, cx - 42, cy - 12);
    fl_line(cx - 34, cy, cx - 42, cy + 12);
    fl_line_style(0);
    std::string a = tx::EMPTY_TITLE, b = tx::EMPTY_TEXT;
    text(a, cx - width(a, 18, true) / 2, cy + 70, C_TEXT, 18, true);
    text(b, cx - width(b, 13) / 2, cy + 96, C_DIM, 13);
  }

  int handle(int e) override {
    switch (e) {
      case FL_ENTER:
        return 1;
      case FL_MOVE:
      case FL_DRAG:
        hover_x = Fl::event_x();
        hover_y = Fl::event_y();
        set_cursor();
        redraw();
        return 1;
      case FL_LEAVE:
        hover_x = hover_y = -1;
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_PUSH:
        for (const auto& l : links)
          if (l.first.has(Fl::event_x(), Fl::event_y())) {
            if (on_open) on_open(l.second);
            return 1;
          }
        return 1;
      case FL_MOUSEWHEEL: {
        int maxs = std::max(0, content_h - h());
        scroll = clampi(scroll + Fl::event_dy() * 30, 0, maxs);
        redraw();
        return 1;
      }
    }
    return Fl_Widget::handle(e);
  }

  void set_cursor() {
    if (!window()) return;
    bool on = false;
    for (const auto& l : links)
      if (l.first.has(hover_x, hover_y)) on = true;
    window()->cursor(on ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
  }
};

}  // namespace fx

// ============================================================ pruebas
// Sin ventana ni conexión: DMS_FLIGHTS_SELFTEST=1.
namespace fx {

int fails = 0;
void check(bool ok, const char* what) {
  if (ok) return;
  std::printf("FAIL %s\n", what);
  fails++;
}

// Una respuesta como las de /aviasales/v3/prices_for_dates.
const char* const SAMPLE_BODY = R"({"success":true,"currency":"eur","data":[
 {"origin":"MAD","destination":"HAV","origin_airport":"MAD","destination_airport":"HAV","price":512,"airline":"UX",
  "flight_number":"51","departure_at":"2026-12-14T15:55:00+01:00","return_at":"","transfers":0,"return_transfers":0,
  "duration":625,"duration_to":625,"duration_back":0,"link":"/search/MAD1412HAV1?t=UX17657","expires_at":"x"},
 {"origin":"MAD","destination":"HAV","price":468,"airline":"IB","flight_number":"6621",
  "departure_at":"2026-12-03T12:10:00+01:00","transfers":0,"duration":610,"link":"/search/MAD0312HAV1?t=IB1"},
 {"origin":"MAD","destination":"HAV","price":455.5,"airline":"IB","flight_number":"6623",
  "departure_at":"2026-12-09T12:10:00+01:00","transfers":1,"duration":800,"link":"/search/MAD0912HAV1?t=IB2"},
 {"origin":"MAD","destination":"HAV","price":0,"airline":"XX"},
 {"origin":"MAD","destination":"HAV","price":530,"airline":"2W","departure_at":"2026-12-20T10:00:00+01:00",
  "transfers":0,"duration":600,"link":"/search/MAD2012HAV1","note":"café 😀 \"x\""}]})";

int selftest() {
  // 1. JSON.
  {
    Json j;
    check(parse_json(R"({"a":[1,2.5,-3e2],"b":{"c":"dñ"},"t":true,"n":null})", j), "json parse");
    check(j["a"][1].num() == 2.5 && j["a"][2].num() == -300 && j["b"]["c"].str() == "dñ" && j["t"].truthy(), "json values");
    check(j["zz"]["y"][3].str("def") == "def", "json missing");
    Json k;
    check(!parse_json("{\"a\":1,}", k) && !parse_json("[1 2]", k) && !parse_json("", k) && !parse_json("{\"a\":\"x", k),
          "json errors");
    std::string deep(200, '[');
    check(!parse_json(deep, k), "json depth");
  }
  // 2. La respuesta de precios.
  std::vector<Ticket> ts;
  std::string err;
  check(parse_response(SAMPLE_BODY, ts, err), "prices parse");
  check(ts.size() == 4, "prices count (sin los de precio 0)");
  check(!parse_response(R"({"success":false,"error":"Unauthorized","data":null})", ts, err) && err == "Unauthorized",
        "prices error");
  parse_response(SAMPLE_BODY, ts, err);
  {
    auto b = by_airline(ts);
    check(b.size() == 3 && b[0].airline == "IB" && b[0].t.price == 455.5 && b[0].offers == 2, "by airline");
    check(b[1].airline == "UX" && b[2].airline == "2W", "by airline order");
    check(cheapest(ts)->price == 455.5, "cheapest");
    check(median({4, 1, 3, 2}) == 2.5 && median({5, 1, 3}) == 3 && median({}) == 0, "median");
    Json g;
    parse_json(R"({"success":true,"data":{"2026-12-03":{"price":468,"airline":"IB","departure_at":"2026-12-03T12:10:00"},
      "2026-12-04":{"price":499,"airline":"UX","departure_at":"2026-12-04T12:10:00"}}})", g);
    check(parse_tickets(g["data"]).size() == 2, "grouped prices");
  }
  // 3. Enlaces para comprar: solo rutas de Aviasales.
  {
    check(booking_url("/search/MAD1412HAV1?t=UX1", "") == "https://www.aviasales.com/search/MAD1412HAV1?t=UX1", "link");
    check(booking_url("/search/MAD1412HAV1", "12345") == "https://www.aviasales.com/search/MAD1412HAV1?marker=12345",
          "link marker");
    check(booking_url("/search/X?t=1", "123") == "https://www.aviasales.com/search/X?t=1&marker=123", "link marker &");
    check(booking_url("/search/X", "12a") == "https://www.aviasales.com/search/X", "marker digits only");
    for (const char* bad : {"//evil.com/x", "@evil.com", "https://evil.com", "/\\evil", "/a b", "", "/x\"y", "/a@b"})
      check(booking_url(bad, "") == "", bad);
    check(route_link("mad", "hav", "2026-12-14T10:00:00", "") == "/search/MAD1412HAV1", "route link");
    check(route_link("MAD", "HAV", "2026-12-14", "2027-01-05T09:00") == "/search/MAD1412HAV05011", "route link back");
    check(route_link("MAD", "HAV", "2026-12", "") == "" && route_link("MADR", "HAV", "2026-12-14", "") == "",
          "route link invalid");
  }
  // 4. Fechas y dinero.
  {
    Date a = parse_date("2026-12"), b = parse_date("2026-12-20"), c = parse_date("2026/02/30"), d = parse_date("hola");
    check(a.ok() && a.d == 0 && b.d == 20 && !c.ok() && !d.ok(), "dates");
    check(parse_date("2028-02-29").ok() && !parse_date("2027-02-29").ok(), "leap year");
    check(key(a) == 20261231 && key(b) == 20261220, "date key");
    check(iso(a) == "2026-12" && iso(b) == "2026-12-20", "iso");
    check(day_label("2026-12-14T10:05:00+01:00") == "14 " + month_name(12, false) && time_label("2026-12-14T10:05:00") == "10:05",
          "labels");
    check(duration_label(625) == fmt(tx::DURATION, {"10", "25"}) && duration_label(0) == "—", "duration");
    std::string t = std::string(1, tx::DEC[0] == ',' ? '.' : ',');
    check(money(1234.5, "EUR") == "1" + t + "235 €" && money(80, "USD") == "$80" && money(1500000, "COP") == "1" + t + "500" + t + "000 COP",
          "money");
  }
  // 5. Avisos: bajó, o por debajo del objetivo (una sola vez al cruzarlo).
  {
    Route r;
    r.history = {{1, 500, "IB"}};
    check(alert_of(r) == 0, "alert first");
    r.history.push_back({2, 480, "IB"});
    check(alert_of(r) == 1, "alert down");
    r.target = 470;
    r.history.push_back({3, 465, "UX"});
    check(alert_of(r) == 3, "alert target");
    r.history.push_back({4, 466, "UX"});
    check(alert_of(r) == 0, "alert no repeat");
    r.history.push_back({5, 465, "UX"});
    check(alert_of(r) == 1, "alert down again");
  }
  // 6. Ciudades, peticiones y la configuración de curl.
  {
    check(find_city("bogota") && std::string(find_city("Bogotá")->code) == "BOG" && find_city("HAV"), "cities");
    check(find_city("La Habana") && find_city("havana") && !find_city("Atlantis"), "city names");
    const City* m = find_city("MAD");
    const City* h = find_city("HAV");
    double km = km_between(*m, *h);
    check(km > 7300 && km < 7600, "distance");
    std::string code, name;
    check(parse_place(R"([{"type":"city","code":"HAV","name":"La Habana"}])", code, name) && code == "HAV" && name == "La Habana",
          "places");
    check(!parse_place("[]", code, name), "places empty");
    Route r;
    r.from = "MAD"; r.to = "HAV"; r.depart = "2026-12"; r.currency = "EUR";
    std::string u = prices_url(r);
    check(u.find("origin=MAD&destination=HAV&departure_at=2026-12&currency=eur&market=es") != std::string::npos &&
              u.find("one_way=true") != std::string::npos && u.find("direct") == std::string::npos, "prices url");
    r.ret = "2027-01-05"; r.direct = true; r.currency = "USD";
    u = prices_url(r);
    check(u.find("return_at=2027-01-05&one_way=false") != std::string::npos && u.find("direct=true") != std::string::npos &&
              u.find("market=us") != std::string::npos, "prices url round");
    check(calendar_url(r).find("group_by=departure_at&departure_at=2026-12") != std::string::npos, "calendar url");
    check(curl_quote("a\"b\\c\nd") == "\"a\\\"b\\\\cd\"", "curl quote");
    std::string c = curl_config("https://x/y?a=1", {"X-Access-Token: abc"});
    check(c.find("url = \"https://x/y?a=1\"") != std::string::npos && c.find("header = \"X-Access-Token: abc\"") != std::string::npos,
          "curl config");
    check(url_encode("Ciudad de México") == "Ciudad%20de%20M%C3%A9xico", "url encode");
    auto al = parse_airlines(R"([{"code":"IB","name":null,"name_translations":{"en":"Iberia"}},{"code":"CU","name":"Cubana"}])");
    check(al["IB"] == "Iberia" && al["CU"] == "Cubana", "airlines");
  }
  // 7. Datos de ejemplo: creíbles, siempre los mismos y cambian cada media hora.
  {
    Route r;
    r.from = "MAD"; r.to = "HAV"; r.depart = "2026-12"; r.currency = "EUR";
    sample_analysis(r, 1800 * 1000);
    auto a = r.tickets;
    check(r.sample && a.size() >= 15 && r.days.size() >= 20, "sample size");
    const Ticket* b = cheapest(a);
    check(b && b->price > 250 && b->price < 900, "sample price range");
    check(by_airline(a).size() >= 5, "sample airlines");
    for (const auto& t : a) check(!booking_url(t.link, "").empty(), "sample links");
    Route r2 = r;
    sample_analysis(r2, 1800 * 1000 + 60);
    check(r2.tickets.size() == a.size() && r2.tickets[0].price == a[0].price, "sample same slot");
    sample_analysis(r2, 1800 * 1001);
    check(r2.tickets[0].price != a[0].price || r2.tickets[1].price != a[1].price, "sample next slot");
    r.direct = true;
    sample_analysis(r, 1800 * 1000);
    bool direct = true;
    for (const auto& t : r.tickets) direct = direct && t.transfers == 0;
    check(direct, "sample direct");
    Route rt = r;
    rt.ret = "2027-01-05";
    sample_analysis(rt, 1800 * 1000);
    check(!rt.tickets.empty() && rt.tickets[0].return_at.compare(0, 10, "2027-01-05") == 0, "sample return");
  }
  // 8. Guardar y volver a leer.
  {
    std::vector<Route> rs(2);
    rs[0].from_text = "Madrid"; rs[0].to_text = "La Habana"; rs[0].from = "MAD"; rs[0].to = "HAV";
    rs[0].from_name = "Madrid"; rs[0].to_name = "La Habana"; rs[0].depart = "2026-12"; rs[0].target = 450;
    rs[0].history = {{100, 512.5, "UX"}, {1900, 498, "IB"}};
    rs[1].from_text = "Barcelona\tx"; rs[1].to_text = "Nueva York"; rs[1].depart = "2027-02-10"; rs[1].ret = "2027-02-20";
    rs[1].currency = "USD"; rs[1].direct = true;
    Settings st;
    st.token = "abc123"; st.marker = "999"; st.autorun = false;
    std::vector<Route> back;
    Settings sb;
    load_text(save_text(rs, st), back, sb);
    check(back.size() == 2 && sb.token == "abc123" && sb.marker == "999" && !sb.autorun && sb.notify, "load settings");
    check(back[0].to_name == "La Habana" && back[0].target == 450 && back[0].history.size() == 2 &&
              back[0].history[1].price == 498 && back[0].history[1].airline == "IB", "load route");
    check(back[1].from_text == "Barcelona x" && back[1].ret == "2027-02-20" && back[1].currency == "USD" && back[1].direct,
          "load route 2");
    check(back[0].id != back[1].id, "ids");
  }
  std::printf("selftest %s fails=%d\n", fails ? "FAILED" : "ok", fails);
  std::fflush(stdout);
  return fails ? 1 : 0;
}

}  // namespace fx

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  std::vector<fx::Route> routes;
  fx::Settings st;
  fx::ResultsView* view = nullptr;
  std::map<std::string, std::string> airline_names;
  std::map<std::string, std::unique_ptr<Fl_RGB_Image>> logos;
  std::set<std::string> logo_asked;
  std::deque<int> queue;
  bool busy = false, sync = false, offline = false;
  int next_id = 1, selected = -1;
  std::string message;
  long long message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_FLIGHTS_SELFTEST")) std::exit(fx::selftest());
    if (fl_getenv("DMS_FLIGHTS_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_FLIGHTS_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    view = new fx::ResultsView(Results->x(), Results->y(), Results->w(), Results->h());
    Results->add(view);
    Results->resizable(view);
    view->airline_names = &airline_names;
    view->logos = &logos;
    view->on_open = [](const std::string& url) {
      char msg[256] = "";
      if (!fl_open_uri(url.c_str(), msg, sizeof msg)) fl_alert("%s", msg);
    };
    RouteList->textsize(13);
    mark(tx::MP_NOW, 0, false, FL_COMMAND + 'r');
    mark(tx::MP_QUIT, 0, false, FL_COMMAND + 'q');
  }

  void form_create() override {
    set_fonts();
    Fl::lock();   // para que los análisis (en otro hilo) avisen a la ventana
    setup();
    load();
    if (routes.empty()) add_example_routes();
    load_airline_names();
    refresh_list();
    select(0);
    sync_menu();
    size_range(980, 640);
    if (fl_getenv("DMS_FLIGHTS_SMOKE")) Fl::add_timeout(3.0, smoke, this);
  }

  void form_close() override { save(); }

  // ---- las rutas
  fx::Route* find(int id) {
    for (auto& r : routes)
      if (r.id == id) return &r;
    return nullptr;
  }
  fx::Route* current() { return selected >= 0 && selected < (int)routes.size() ? &routes[selected] : nullptr; }

  // Las rutas de la primera vez (se pueden quitar): dentro de uno y dos meses.
  void add_example_routes() {
    fx::Date t = fx::today();
    auto plus = [&](int m) {
      int mm = t.m + m, yy = t.y + (mm - 1) / 12;
      mm = (mm - 1) % 12 + 1;
      return fx::Date{yy, mm, 0};
    };
    fx::Date a = plus(1), b = plus(2);
    add_route(lang_city("Madrid", "Madrid"), lang_city("La Habana", "Havana"), fx::iso(a), "", "EUR", false, 0);
    fx::Date bd{b.y, b.m, 10}, br{b.y, b.m, 24};
    add_route(lang_city("Barcelona", "Barcelona"), lang_city("Nueva York", "New York"), fx::iso(bd), fx::iso(br), "EUR",
              false, 0);
  }
  static std::string lang_city(const char* es, const char* en) { return fx::lang() == "es" ? es : en; }

  fx::Route& add_route(const std::string& from, const std::string& to, const std::string& dep, const std::string& ret,
                       const std::string& cur, bool direct, double target) {
    fx::Route r;
    r.id = next_id++;
    r.from_text = fx::trim(from);
    r.to_text = fx::trim(to);
    r.depart = dep;
    r.ret = ret;
    r.currency = cur;
    r.direct = direct;
    r.target = target;
    // Las ciudades conocidas se resuelven ya (sin esperar a internet).
    if (const fx::City* c = fx::find_city(r.from_text)) { r.from = c->code; r.from_name = fx::city_name(*c); }
    if (const fx::City* c = fx::find_city(r.to_text)) { r.to = c->code; r.to_name = fx::city_name(*c); }
    routes.push_back(r);
    return routes.back();
  }

  void refresh_list() {
    RouteList->clear();
    for (const auto& r : routes) {
      std::string price = r.history.empty() ? "" : "   " + fx::money(r.history.back().price, r.currency);
      // «@.»: sin formatos de Fl_Browser en el resto de la línea.
      RouteList->add("@." + r.short_title() + price);
    }
    if (selected >= 0 && selected < (int)routes.size()) RouteList->index(selected);
  }

  void select(int i) {
    selected = routes.empty() ? -1 : fx::clampi(i, 0, (int)routes.size() - 1);
    if (selected >= 0) RouteList->index(selected);
    show_current();
  }

  void show_current() {
    fx::Route* r = current();
    view->route = r;
    view->loading = r && r->loading;
    view->marker = st.marker;
    view->scroll = 0;
    view->redraw();
    update_labels();
  }

  // ---- analizar: una cola, de una en una, en otro hilo
  struct Job {
    int id;
    fx::Route r;
    fx::Settings st;
  };

  void enqueue(int id, bool first = false) {
    if (std::find(queue.begin(), queue.end(), id) != queue.end()) return;
    fx::Route* r = find(id);
    if (!r || r->loading) return;
    if (first) queue.push_front(id);
    else queue.push_back(id);
    start_next();
  }

  void start_next() {
    if (busy) return;
    while (!queue.empty()) {
      int id = queue.front();
      queue.pop_front();
      fx::Route* r = find(id);
      if (!r) continue;
      r->loading = true;
      busy = true;
      auto* job = new Job{id, *r, st};
      if (offline) job->st.token.clear();
      update_labels();
      if (view->route == r) { view->loading = true; view->redraw(); }
      if (sync) {
        fx::analyze(job->r, job->st, fx::now_s());
        finish(job);
      } else {
        std::thread([job] {
          fx::analyze(job->r, job->st, fx::now_s());
          Fl::awake(done_cb, job);
        }).detach();
      }
      return;
    }
  }

  static void done_cb(void* p) {
    if (self()) self()->finish(static_cast<Job*>(p));
    else delete static_cast<Job*>(p);
  }

  std::map<int, long long> retry;   // tras un error, se reintenta a los 5 minutos

  void finish(Job* job) {
    std::unique_ptr<Job> keep(job);
    busy = false;
    fx::Route* r = find(job->id);
    if (r) {
      fx::Route& n = job->r;
      r->from = n.from; r->to = n.to; r->from_name = n.from_name; r->to_name = n.to_name;
      r->loading = false;
      r->error = n.error;
      if (n.error.empty()) {
        r->tickets = n.tickets;
        r->days = n.days;
        r->last = n.last;
        r->sample = n.sample;
        r->history = n.history;
        retry.erase(r->id);
        int a = fx::alert_of(*r);
        if (a && st.notify) notify(*r, a);
        ask_logos(*r);
      } else {
        retry[r->id] = fx::now_s() + 300;
      }
      save();
      refresh_list();
      if (view->route == r) { view->loading = false; view->redraw(); }
    }
    update_labels();
    start_next();
  }

  // ---- avisos
  void notify(const fx::Route& r, int a) {
    const fx::Snapshot& s = r.history.back();
    std::string what = r.short_title() + ": " + fx::money(s.price, r.currency) + " (" + view->airline_name(s.airline) + ")";
    std::string head = (a & 2) ? fx::fmt(tx::ALERT_TARGET, {fx::money(r.target, r.currency)}) : std::string(tx::ALERT_DOWN);
    set_message(head + " " + what);
    if (sync) return;
    fl_beep(FL_BEEP_NOTIFICATION);
#ifdef __APPLE__
    // Un aviso del sistema (osascript), en otro hilo para no esperar.
    std::string title = tx::APP, body = head + " " + what;
    std::thread([title, body] {
      auto q = [](const std::string& s) {
        std::string o = "\"";
        for (char c : s) { if (c == '"' || c == '\\') o += '\\'; o += c; }
        return o + "\"";
      };
      std::string script = "display notification " + q(body) + " with title " + q(title) + " sound name \"Glass\"";
      std::string sh = "'";
      for (char c : script) sh += c == '\'' ? std::string("'\\''") : std::string(1, c);
      sh += "'";
      std::string cmd = "osascript -e " + sh + " >/dev/null 2>&1";
      if (FILE* p = popen(cmd.c_str(), "r")) pclose(p);
    }).detach();
#endif
  }

  void set_message(const std::string& s) {
    message = s;
    message_until = fx::now_s() + 20;
    update_labels();
  }

  // ---- logos y nombres de las aerolíneas (para que se vea mejor; no hacen falta)
  void ask_logos(const fx::Route& r) {
    if (sync) return;
    std::string dir = fx::config_dir() + "/logos";
    for (const auto& b : fx::by_airline(r.tickets)) {
      std::string code = b.airline;
      if (logo_asked.count(code) || !fx::is_airline_code(code)) continue;
      logo_asked.insert(code);
      std::string file = dir + "/" + code + ".png";
      std::string data;
      if (fx::read_file(file, data) && set_logo(code, data)) continue;
      std::thread([code, file, dir] {
        fx::HttpResult h = fx::http_get("https://pics.avs.io/192/64/" + code + ".png", {});
        if (h.status == 200 && h.body.size() > 100) {
          fl_make_path(dir.c_str());
          fx::write_file(file, h.body);
          auto* job = new std::pair<std::string, std::string>(code, h.body);
          Fl::awake(logo_cb, job);
        }
      }).detach();
    }
  }
  static void logo_cb(void* p) {
    std::unique_ptr<std::pair<std::string, std::string>> job(static_cast<std::pair<std::string, std::string>*>(p));
    if (self() && self()->set_logo(job->first, job->second)) self()->view->redraw();
  }
  bool set_logo(const std::string& code, const std::string& png) {
    auto img = std::make_unique<Fl_PNG_Image>(nullptr, (const unsigned char*)png.data(), (int)png.size());
    if (img->fail() || img->w() <= 0) return false;
    img->scale(72, 24, 1, 1);
    logos[code] = std::move(img);
    return true;
  }

  void load_airline_names() {
    std::string file = fx::config_dir() + "/airlines-" + fx::lang() + ".json", data;
    if (fx::read_file(file, data)) airline_names = fx::parse_airlines(data);
    if (!airline_names.empty() || sync) return;
    std::string url = "https://api.travelpayouts.com/data/" + fx::lang() + "/airlines.json";
    std::thread([url, file] {
      fx::HttpResult h = fx::http_get(url, {});
      if (h.status != 200 || h.body.size() < 1000) return;
      fx::write_file(file, h.body);
      Fl::awake(names_cb, new std::string(h.body));
    }).detach();
  }
  static void names_cb(void* p) {
    std::unique_ptr<std::string> body(static_cast<std::string*>(p));
    if (!self()) return;
    self()->airline_names = fx::parse_airlines(*body);
    self()->view->redraw();
  }

  // ---- el reloj (cada segundo): la cuenta atrás y lo que toca analizar
  void Tick_timer() override {
    long long now = fx::now_s();
    for (auto& r : routes) {
      if (r.loading) continue;
      bool due = r.last == 0 ? true : st.autorun && now - r.last >= 1800;
      auto it = retry.find(r.id);
      if (it != retry.end()) due = now >= it->second;
      if (due) enqueue(r.id);
    }
    if (!message.empty() && now > message_until) message.clear();
    update_labels();
  }

  void update_labels() {
    long long now = fx::now_s(), next = 0;
    for (const auto& r : routes) {
      long long t = r.last ? r.last + 1800 : now;
      if (!next || t < next) next = t;
    }
    std::string s;
    if (busy) {
      for (const auto& r : routes)
        if (r.loading) s = fx::fmt(tx::ANALYZING_ROUTE, {r.short_title()});
    } else if (!st.autorun) {
      s = tx::AUTO_OFF;
    } else if (!routes.empty()) {
      long long left = std::max(0LL, next - now);
      char b[16];
      std::snprintf(b, sizeof b, "%02lld:%02lld", left / 60, left % 60);
      s = fx::fmt(tx::NEXT_IN, {b});
    }
    if (LblNext->text() != s) LblNext->text(s);
    std::string status = !message.empty() ? message
                                           : fx::fmt(tx::STATUS, {std::to_string(routes.size()),
                                                                  st.token.empty() ? tx::MODE_SAMPLE : tx::MODE_REAL});
    if (Status->text() != status) Status->text(status);
  }

  // ---- los botones
  void BtnAdd_click() override {
    std::string from = fx::trim(Origin->text()), to = fx::trim(Destination->text());
    std::string dep = fx::trim(DepartDate->text()), ret = fx::trim(ReturnDate->text());
    std::string err;
    fx::Date d = fx::parse_date(dep), r = fx::parse_date(ret), t = fx::today();
    if (from.empty() || to.empty()) err = tx::ERR_NO_PLACES;
    else if (fx::fold(from) == fx::fold(to)) err = tx::ERR_SAME;
    else if (!d.ok()) err = tx::ERR_DEPART;
    else if (fx::key(d) < fx::key(t)) err = tx::ERR_PAST;
    else if (!ret.empty() && !r.ok()) err = tx::ERR_RETURN;
    else if (!ret.empty() && fx::key(r) < fx::key(d) && !(r.d == 0 && r.y == d.y && r.m == d.m)) err = tx::ERR_RETURN_BEFORE;
    double target = 0;
    std::string tg = fx::trim(Target->text());
    if (err.empty() && !tg.empty()) {
      // «1.000» son mil en español y «1,000» en inglés: el separador de miles
      // del idioma se salta y solo el decimal cuenta.
      std::string norm;
      for (char c : tg)
        if (std::isdigit((unsigned char)c)) norm += c;
        else if (c == tx::DEC[0]) norm += '.';
      target = std::atof(norm.c_str());
      if (target <= 0) err = tx::ERR_TARGET;
    }
    if (!err.empty()) {
      set_message(err);
      if (!sync) {
        fl_message_title(tx::APP);
        fl_alert("%s", err.c_str());
      }
      return;
    }
    std::string cur = Currency->text().empty() ? "EUR" : Currency->text();
    fx::Route& nr = add_route(from, to, fx::iso(d), ret.empty() ? "" : fx::iso(r), cur, Direct->checked(), target);
    int id = nr.id;
    save();
    refresh_list();
    select((int)routes.size() - 1);
    enqueue(id, true);
  }

  void BtnRemove_click() override {
    fx::Route* r = current();
    if (!r) return;
    if (!sync) {
      fl_message_title(tx::APP);
      std::string ask = fx::fmt(tx::ASK_REMOVE, {r->short_title()});
      if (fl_choice("%s", tx::CANCEL, tx::REMOVE, nullptr, ask.c_str()) != 1) return;
    }
    int id = r->id;
    queue.erase(std::remove(queue.begin(), queue.end(), id), queue.end());
    routes.erase(routes.begin() + selected);
    save();
    refresh_list();
    select(std::min(selected, (int)routes.size() - 1));
  }

  void BtnNow_click() override {
    if (fx::Route* r = current()) enqueue(r->id, true);
  }

  void RouteList_select() override {
    int i = RouteList->index();
    if (i >= 0 && i != selected) select(i);
  }

  // ---- el menú
  void mark(const char* path, int flags, bool on, int shortcut = 0) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    Menu1->mode(i, (Menu1->mode(i) & FL_MENU_DIVIDER) | flags | (on ? FL_MENU_VALUE : 0));
    if (shortcut) Menu1->shortcut(i, shortcut);
  }
  void sync_menu() {
    mark(tx::MP_AUTO, FL_MENU_TOGGLE, st.autorun);
    mark(tx::MP_NOTIFY, FL_MENU_TOGGLE, st.notify);
    Menu1->redraw();
  }

  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_NOW) BtnNow_click();
    else if (item == tx::MP_ALL) {
      for (const auto& r : routes) enqueue(r.id);
    } else if (item == tx::MP_QUIT) {
      save();
      hide();
    } else if (item == tx::MP_TOKEN) {
      fl_message_title(tx::L_TOKEN);
      const char* v = fl_password("%s", st.token.c_str(), tx::TOKEN_ASK);
      if (v) {
        st.token = fx::trim(v);
        for (auto& r : routes) { r.last = 0; r.history.clear(); }   // los datos de ejemplo no cuentan
        save();
        refresh_list();
        show_current();
      }
    } else if (item == tx::MP_MARKER) {
      fl_message_title(tx::L_MARKER);
      const char* v = fl_input("%s", st.marker.c_str(), tx::MARKER_ASK);
      if (v) {
        st.marker = fx::trim(v);
        save();
        show_current();
      }
    } else if (item == tx::MP_AUTO) {
      st.autorun = !st.autorun;
      save();
    } else if (item == tx::MP_NOTIFY) {
      st.notify = !st.notify;
      save();
    } else if (item == tx::MP_GET_TOKEN) {
      fl_open_uri("https://www.travelpayouts.com/");
    } else if (item == tx::MP_HOW) {
      fl_message_title(tx::L_HOW);
      fl_message("%s", tx::HOW_TEXT);
    } else if (item == tx::MP_ABOUT) {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", fx::fmt(tx::ABOUT_TEXT, {v}).c_str());
    }
    sync_menu();
    update_labels();
  }

  // ---- guardar
  std::string data_file() const { return fx::config_dir() + "/routes.txt"; }
  void load() {
    std::string text;
    if (!fx::read_file(data_file(), text)) return;
    fx::load_text(text, routes, st);
    next_id = 1;
    for (auto& r : routes) next_id = std::max(next_id, r.id + 1);
  }
  void save() {
    if (sync) return;
    fl_make_path(fx::config_dir().c_str());
#ifndef _WIN32
    mode_t old = umask(077);   // lleva el token
#endif
    fx::write_file(data_file(), fx::save_text(routes, st));
#ifndef _WIN32
    umask(old);
#endif
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

  // Las rutas de las capturas: con su historia de un día (cada media hora).
  void demo_state(int W, int H) {
    sync = true;
    offline = true;
    fx::g_offline = true;
    setup();
    size(W, H);
    routes.clear();
    next_id = 1;
    long long now = fx::now_s();
    fx::Date t = fx::today();
    auto month = [&](int m) {
      int mm = t.m + m, yy = t.y + (mm - 1) / 12;
      return fx::Date{yy, (mm - 1) % 12 + 1, 0};
    };
    fx::Date a = month(1), b = month(2), c = month(3);
    add_route(lang_city("Madrid", "Madrid"), lang_city("La Habana", "Havana"), fx::iso(a), "", "EUR", false, 430);
    add_route(lang_city("Barcelona", "Barcelona"), lang_city("Nueva York", "New York"), fx::iso(fx::Date{b.y, b.m, 10}),
              fx::iso(fx::Date{b.y, b.m, 24}), "EUR", false, 0);
    add_route(lang_city("Madrid", "Madrid"), lang_city("Ciudad de México", "Mexico City"), fx::iso(c), "", "EUR", true, 0);
    for (auto& r : routes) {
      for (int k = 40; k >= 1; k--) {
        fx::Route tmp = r;
        fx::sample_analysis(tmp, now - k * 1800);
        if (const fx::Ticket* best = fx::cheapest(tmp.tickets)) r.history.push_back({now - k * 1800, best->price, best->airline});
      }
      fx::analyze(r, st, now);
    }
    refresh_list();
    select(0);
    Origin->text(lang_city("Valencia", "Valencia"));
    Destination->text(lang_city("Cancún", "Cancun"));
    DepartDate->text(fx::iso(fx::Date{b.y, b.m, 0}));
  }

  int shots(const std::string& dir) {
    Fl::screen_count();
    fl_make_path(dir.c_str());
    int W = 1240, H = 820;
    if (const char* s = fl_getenv("DMS_FLIGHTS_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
    demo_state(W, H);
    view->shooting = true;
    // 1. La ruta con su análisis, el ratón sobre el día más barato.
    view->hover_x = -1;
    render_to(dir + "/vuelos.png");
    // 2. La tabla de aerolíneas, más abajo, con el ratón sobre Comprar.
    select(1);
    view->scroll = 0;
    render_to("");   // para saber dónde quedan los botones
    if (!view->links.empty()) {
      view->hover_x = view->links[0].first.x + 20;
      view->hover_y = view->links[0].first.y + 10;
    }
    render_to(dir + "/aerolineas.png");
    // 3. El precio de cada día y la evolución.
    select(2);
    view->scroll = 330;
    render_to("");
    view->scroll = std::min(view->scroll, std::max(0, view->content_h - view->h()));
    render_to("");
    for (const auto& t : view->tips)
      if (t.first.h > 60) { view->hover_x = t.first.x + 2; view->hover_y = t.first.y + t.first.h - 20; break; }
    render_to(dir + "/dias.png");
    // 4. La evolución del precio con su objetivo.
    select(0);
    view->scroll = 100000;
    render_to("");
    view->scroll = std::max(0, view->content_h - view->h());   // hasta el final, sin pasarse
    view->hover_x = view->hover_y = -1;
    render_to(dir + "/evolucion.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }

  // ---- la interfaz sin ventana: añadir, avisar, quitar y cada análisis
  int ui_test() {
    Fl::screen_count();
    demo_state(1180, 780);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(routes.size() == 3 && routes[0].tickets.size() > 10 && routes[0].sample, "demo routes");
    render_to("");
    chk(!view->links.empty(), "buy buttons");
    for (const auto& l : view->links) chk(l.second.rfind("https://www.aviasales.com/search/", 0) == 0, "buy url");
    // Añadir: errores y una ruta buena.
    Origin->text(""); BtnAdd_click(); chk(routes.size() == 3 && message == tx::ERR_NO_PLACES, "add empty");
    Origin->text("Madrid"); Destination->text("madrid"); BtnAdd_click(); chk(message == tx::ERR_SAME, "add same");
    Destination->text("Lima"); DepartDate->text("2020-01"); BtnAdd_click(); chk(message == tx::ERR_PAST, "add past");
    fx::Date t = fx::today();
    std::string dep = fx::iso(fx::Date{t.y + 1, t.m, 0});
    DepartDate->text(dep); ReturnDate->text("x"); BtnAdd_click(); chk(message == tx::ERR_RETURN, "add bad return");
    ReturnDate->text(fx::iso(fx::Date{t.y, t.m, 0})); BtnAdd_click(); chk(message == tx::ERR_RETURN_BEFORE, "add return before");
    ReturnDate->text(""); Target->text("abc"); BtnAdd_click(); chk(message == tx::ERR_TARGET, "add bad target");
    Target->text("1.000"); Direct->checked(true); BtnAdd_click();
    chk(routes.size() == 4 && selected == 3 && routes[3].to == "LIM" && routes[3].direct && routes[3].target == 1000 &&
            !routes[3].tickets.empty() && routes[3].history.size() == 1, "add good");
    render_to("");
    // Analizar otra vez: el historial crece; avisos si baja.
    for (int k = 0; k < 3; k++) { routes[3].last = 0; BtnNow_click(); }
    chk(routes[3].history.size() == 4 && !busy && queue.empty(), "analyze again");
    routes[3].history.push_back({fx::now_s(), 1, "IB"});
    message.clear();
    if (fx::alert_of(routes[3])) notify(routes[3], fx::alert_of(routes[3]));
    chk(!message.empty(), "alert message");
    // El reloj: lo que toca se analiza.
    routes[1].last = fx::now_s() - 1801;
    Tick_timer();
    chk(routes[1].last >= fx::now_s() - 2, "timer analysis");
    st.autorun = false;
    routes[1].last = fx::now_s() - 1801;
    long long before = routes[1].last;
    Tick_timer();
    chk(routes[1].last == before && LblNext->text() == tx::AUTO_OFF, "autorun off");
    st.autorun = true;
    // Cambiar de ruta, desplazar y quitar.
    for (int i = 0; i < (int)routes.size(); i++) { RouteList->index(i); RouteList_select(); render_to(""); }
    view->scroll = 5000;
    render_to("");
    select(1);
    BtnRemove_click();
    chk(routes.size() == 3 && selected == 1, "remove");
    while (!routes.empty()) { select(0); BtnRemove_click(); }
    render_to("");
    chk(routes.empty() && view->route == nullptr, "remove all");
    // Un error de la API se ve y se reintenta.
    fx::Route& er = add_route("Madrid", "Atlantis", fx::iso(fx::Date{t.y + 1, 1, 0}), "", "EUR", false, 0);
    (void)er;
    refresh_list();
    select(0);
    offline = true;
    // Atlantis no es una ciudad conocida: sin internet no se resuelve.
    routes[0].to_text = "Atlantis";
    chk(routes[0].to.empty(), "unknown city");
    render_to("");
    std::printf("uitest %s\n", f ? "FAILED" : "ok");
    std::fflush(stdout);
    return f ? 1 : 0;
  }

  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok routes=%d\n", (int)f->routes.size());
    std::fflush(stdout);
    f->hide();
  }
};
''';
