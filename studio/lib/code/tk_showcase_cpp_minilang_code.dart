part of 'tk_examples.dart';

// El código en C++ de MiniLang (tk_showcase_cpp_minilang.dart): va tal cual
// en Form1.cpp, después de los textos (namespace tx).
const _miniLangIncludes = r'''#include <algorithm>
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
#include <random>
#include <string>
#include <thread>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifndef _WIN32
#include <csignal>
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

const _miniLangCode = r'''
// ============================================================ lo básico
// MiniLang: aprender idiomas con juegos cortos, desde la barra de menús.
// Los idiomas son paquetes (un .json por idioma en la carpeta «paquetes»):
// cada uno trae unidades por nivel (A1 a C1) y en cada unidad, frases con su
// traducción. Con ellas se arman los juegos: elegir la traducción, ordenar
// las palabras, unir parejas, escribir y escuchar.
namespace ml {

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}
double now_s() {
  using namespace std::chrono;
  return duration_cast<duration<double>>(steady_clock::now().time_since_epoch()).count();
}
long long wall_s() { return (long long)std::time(nullptr); }
// El día (en la hora local) de una fecha: los días desde 1970. La racha cuenta días, no horas.
long long days_from_civil(int y, unsigned m, unsigned d) {
  y -= m <= 2;
  const long long era = (y >= 0 ? y : y - 399) / 400;
  const unsigned yoe = (unsigned)(y - era * 400);
  const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
  const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + (long long)doe - 719468;
}
long long day_of(long long t) {
  std::time_t tt = (std::time_t)t;
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  return days_from_civil(v.tm_year + 1900, (unsigned)v.tm_mon + 1, (unsigned)v.tm_mday);
}
int weekday_of(long long day) { return (int)(((day % 7) + 7 + 3) % 7); }   // 0 = lunes (el 1/1/1970 fue jueves)
int hour_of(long long t) {
  std::time_t tt = (std::time_t)t;
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  return v.tm_hour;
}

// ---- archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_MINILANG_DIR")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\minilang";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/minilang";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/minilang";
#endif
}
std::string packs_dir() { return config_dir() + "/paquetes"; }
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
// Se escribe aparte y luego se cambia el nombre: un corte a medias no deja el archivo roto.
bool write_file(const std::string& path, const std::string& data) {
  std::string tmp = path + ".tmp";
  FILE* f = fl_fopen(tmp.c_str(), "wb");
  if (!f) return false;
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  ok = std::fclose(f) == 0 && ok;
  if (!ok) return false;
  std::remove(path.c_str());
  return std::rename(tmp.c_str(), path.c_str()) == 0;
}
bool file_exists(const std::string& path) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  std::fclose(f);
  return true;
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
  size_t a = s.find_first_not_of(" \t\r\n");
  if (a == std::string::npos) return "";
  size_t b = s.find_last_not_of(" \t\r\n");
  return s.substr(a, b - a + 1);
}

// ---- el texto: UTF-8 letra a letra, para comparar respuestas con calma
std::vector<uint32_t> cps(const std::string& s) {
  std::vector<uint32_t> out;
  for (size_t i = 0; i < s.size();) {
    unsigned char c = (unsigned char)s[i];
    uint32_t cp = c;
    int n = 1;
    if (c >= 0xF0 && i + 3 < s.size() + 0) {
      cp = ((c & 0x07u) << 18) | ((s[i + 1] & 0x3Fu) << 12) | ((s[i + 2] & 0x3Fu) << 6) | (s[i + 3] & 0x3Fu);
      n = 4;
    } else if (c >= 0xE0 && i + 2 < s.size()) {
      cp = ((c & 0x0Fu) << 12) | ((s[i + 1] & 0x3Fu) << 6) | (s[i + 2] & 0x3Fu);
      n = 3;
    } else if (c >= 0xC0 && i + 1 < s.size()) {
      cp = ((c & 0x1Fu) << 6) | (s[i + 1] & 0x3Fu);
      n = 2;
    }
    out.push_back(cp);
    i += (size_t)n;
  }
  return out;
}
std::string utf8(const std::vector<uint32_t>& v) {
  std::string o;
  for (uint32_t c : v) {
    if (c < 0x80) o += (char)c;
    else if (c < 0x800) {
      o += (char)(0xC0 | (c >> 6));
      o += (char)(0x80 | (c & 0x3F));
    } else if (c < 0x10000) {
      o += (char)(0xE0 | (c >> 12));
      o += (char)(0x80 | ((c >> 6) & 0x3F));
      o += (char)(0x80 | (c & 0x3F));
    } else {
      o += (char)(0xF0 | (c >> 18));
      o += (char)(0x80 | ((c >> 12) & 0x3F));
      o += (char)(0x80 | ((c >> 6) & 0x3F));
      o += (char)(0x80 | (c & 0x3F));
    }
  }
  return o;
}
uint32_t lower_cp(uint32_t c) {
  if (c >= 'A' && c <= 'Z') return c + 32;
  if (c >= 0xC0 && c <= 0xDE && c != 0xD7) return c + 32;   // Á É Ñ Ü…
  return c;
}
// Sin acentos: «mañana» y «manana» se parecen (se acepta, avisando).
uint32_t fold_cp(uint32_t c) {
  if (c >= 0xE0 && c <= 0xE5) return 'a';
  if (c == 0xE7) return 'c';
  if (c >= 0xE8 && c <= 0xEB) return 'e';
  if (c >= 0xEC && c <= 0xEF) return 'i';
  if (c == 0xF1) return 'n';
  if (c >= 0xF2 && c <= 0xF6) return 'o';
  if (c >= 0xF9 && c <= 0xFC) return 'u';
  if (c == 0xFD || c == 0xFF) return 'y';
  return c;
}
// Para comparar: minúsculas, sin signos (¿?¡!.,;:«»"…), con un espacio entre palabras.
std::string norm(const std::string& s, bool fold) {
  std::vector<uint32_t> out;
  bool space = false;
  for (uint32_t c : cps(s)) {
    c = lower_cp(c);
    if (c == 0x2019 || c == 0x2018) c = '\'';
    if (fold) c = fold_cp(c);
    bool letter = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '\'' || (c >= 0xC0 && c != 0xD7 && c != 0xF7 && c < 0x2000);
    if (!letter) {
      space = !out.empty();
      continue;
    }
    if (space) out.push_back(' ');
    space = false;
    out.push_back(c);
  }
  return utf8(out);
}
int levenshtein(const std::vector<uint32_t>& a, const std::vector<uint32_t>& b) {
  std::vector<int> prev(b.size() + 1), cur(b.size() + 1);
  for (size_t j = 0; j <= b.size(); j++) prev[j] = (int)j;
  for (size_t i = 1; i <= a.size(); i++) {
    cur[0] = (int)i;
    for (size_t j = 1; j <= b.size(); j++)
      cur[j] = std::min({prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)});
    std::swap(prev, cur);
  }
  return prev[b.size()];
}
// Las formas que valen: «Hello/Hi» → {Hello, Hi}; la primera es la que se enseña.
std::vector<std::string> alts(const std::string& s) {
  std::vector<std::string> out;
  for (auto& a : split(s, '/')) {
    a = trim(a);
    if (!a.empty()) out.push_back(a);
  }
  return out;
}

// ---- corregir: bien, casi (una letra o los acentos) o mal
enum Verdict { V_WRONG = 0, V_OK, V_TYPO, V_ACCENT };
struct Check {
  Verdict v = V_WRONG;
  std::string best;   // la forma correcta más parecida a lo escrito
};
Check check_text(const std::string& typed, const std::vector<std::string>& ok) {
  Check r;
  if (ok.empty()) return r;
  r.best = ok[0];
  std::string t = norm(typed, false), tf = norm(typed, true);
  if (t.empty()) return r;
  for (const auto& a : ok)
    if (norm(a, false) == t) return {V_OK, a};
  for (const auto& a : ok)
    if (norm(a, true) == tf) return {V_ACCENT, a};
  int best = 1 << 30;
  std::vector<uint32_t> T = cps(tf);
  for (const auto& a : ok) {
    int d = levenshtein(cps(norm(a, true)), T);
    if (d < best) {
      best = d;
      r.best = a;
    }
  }
  size_t len = cps(norm(r.best, true)).size();
  int allow = len >= 16 ? 2 : len >= 5 ? 1 : 0;
  r.v = best <= allow ? V_TYPO : V_WRONG;
  return r;
}
// Las fichas de «Ordena las palabras»: las palabras sin los signos de alrededor.
std::vector<std::string> words_of(const std::string& s) {
  std::vector<std::string> out;
  for (auto w : split(s, ' ')) {
    static const char* edge[] = {"¿", "¡", "«", "»", "\"", ".", ",", "!", "?", ";", ":", "…"};
    bool again = true;
    while (again && !w.empty()) {
      again = false;
      for (const char* e : edge) {
        size_t n = std::strlen(e);
        if (w.size() >= n && w.compare(0, n, e) == 0) {
          w.erase(0, n);
          again = true;
        }
        if (w.size() >= n && w.compare(w.size() - n, n, e) == 0) {
          w.erase(w.size() - n);
          again = true;
        }
      }
    }
    if (!w.empty()) out.push_back(w);
  }
  return out;
}

// ---- JSON (lo justo para los paquetes)
struct Json {
  enum T { NUL, BOOL, NUM, STR, ARR, OBJ } t = NUL;
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
};
struct JsonReader {
  const std::string& s;
  size_t i = 0;
  bool ok = true;
  explicit JsonReader(const std::string& src) : s(src) {}
  void ws() {
    while (i < s.size() && std::isspace((unsigned char)s[i])) i++;
  }
  std::string str() {
    std::string out;
    if (s[i] != '"') {
      ok = false;
      return out;
    }
    i++;
    while (i < s.size() && s[i] != '"') {
      char c = s[i++];
      if (c != '\\') {
        out += c;
        continue;
      }
      if (i >= s.size()) break;
      char e = s[i++];
      if (e == 'n') out += '\n';
      else if (e == 't') out += '\t';
      else if (e == 'r') out += '\r';
      else if (e == 'u' && i + 4 <= s.size()) {
        uint32_t cp = (uint32_t)std::strtoul(s.substr(i, 4).c_str(), nullptr, 16);
        i += 4;
        if (cp >= 0xD800 && cp < 0xDC00 && i + 6 <= s.size() && s[i] == '\\' && s[i + 1] == 'u') {
          uint32_t lo = (uint32_t)std::strtoul(s.substr(i + 2, 4).c_str(), nullptr, 16);
          i += 6;
          cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
        }
        out += utf8({cp});
      } else out += e;
    }
    if (i >= s.size()) ok = false;
    i++;
    return out;
  }
  Json val(int depth = 0) {
    Json j;
    ws();
    if (i >= s.size() || depth > 40) {
      ok = false;
      return j;
    }
    char c = s[i];
    if (c == '{') {
      j.t = Json::OBJ;
      i++;
      ws();
      if (i < s.size() && s[i] == '}') {
        i++;
        return j;
      }
      while (ok && i < s.size()) {
        ws();
        std::string k = str();
        ws();
        if (i >= s.size() || s[i] != ':') {
          ok = false;
          break;
        }
        i++;
        j.o.push_back({k, val(depth + 1)});
        ws();
        if (i < s.size() && s[i] == ',') {
          i++;
          continue;
        }
        if (i < s.size() && s[i] == '}') {
          i++;
          return j;
        }
        ok = false;
      }
    } else if (c == '[') {
      j.t = Json::ARR;
      i++;
      ws();
      if (i < s.size() && s[i] == ']') {
        i++;
        return j;
      }
      while (ok && i < s.size()) {
        j.a.push_back(val(depth + 1));
        ws();
        if (i < s.size() && s[i] == ',') {
          i++;
          continue;
        }
        if (i < s.size() && s[i] == ']') {
          i++;
          return j;
        }
        ok = false;
      }
    } else if (c == '"') {
      j.t = Json::STR;
      j.s = str();
    } else if (s.compare(i, 4, "true") == 0) {
      j.t = Json::BOOL;
      j.b = true;
      i += 4;
    } else if (s.compare(i, 5, "false") == 0) {
      j.t = Json::BOOL;
      i += 5;
    } else if (s.compare(i, 4, "null") == 0) {
      i += 4;
    } else {
      char* end = nullptr;
      j.n = std::strtod(s.c_str() + i, &end);
      if (end == s.c_str() + i) ok = false;
      j.t = Json::NUM;
      i = (size_t)(end - s.c_str());
    }
    return j;
  }
};
Json parse_json(const std::string& text, bool* ok) {
  JsonReader r(text);
  Json j = r.val();
  r.ws();
  if (ok) *ok = r.ok && r.i == text.size();
  return j;
}
std::string jstr(const std::string& s) {
  std::string o = "\"";
  for (char c : s) {
    if (c == '"') o += "\\\"";
    else if (c == '\\') o += "\\\\";
    else if (c == '\n') o += "\\n";
    else if ((unsigned char)c < 0x20) o += ' ';
    else o += c;
  }
  return o + "\"";
}

// ============================================================ el contenido
// Las frases vienen con varias formas que valen, separadas por «/» (la
// primera es la que se enseña). El curso de inglés (y, al revés, el de
// español para quien habla inglés) va de A1 a C1; los demás idiomas traen
// unos primeros pasos para instalar.
struct RawUnit {
  int section;          // 0 A1, 1 A2, 2 B1, 3 B2, 4 C1
  const char* title;    // «español|inglés»
  const char* icon;
  std::vector<const char*> items;
};
const char* const LANG_ORDER[] = {"es", "en", "fr", "it", "de", "pt"};
const int LANG_N = 6;
int lang_col(const std::string& code) {
  for (int i = 0; i < LANG_N; i++)
    if (code == LANG_ORDER[i]) return i;
  return -1;
}

// El curso completo: «español|inglés».
const std::vector<RawUnit>& course() {
  static const std::vector<RawUnit> u = {
      {0, "Saludos|Greetings", "👋",
       {"Hola|Hello/Hi", "Buenos días|Good morning", "Buenas noches|Good night/Good evening", "Adiós|Goodbye/Bye",
        "¿Cómo estás?|How are you?", "Estoy bien, gracias|I am fine, thanks/I'm fine, thanks/I am fine, thank you/I'm fine, thank you",
        "Me llamo Ana|My name is Ana/I am Ana/I'm Ana", "Mucho gusto|Nice to meet you", "Por favor|Please",
        "Gracias|Thank you/Thanks", "Hasta mañana|See you tomorrow", "¿Y tú?|And you?/What about you?"}},
      {0, "Presentarse|About me", "🙋",
       {"Soy de España|I am from Spain/I'm from Spain", "Tengo veinte años|I am twenty years old/I'm twenty years old/I am twenty/I'm twenty",
        "Vivo en Madrid|I live in Madrid", "Soy estudiante|I am a student/I'm a student",
        "Hablo un poco de inglés|I speak a little English", "¿De dónde eres?|Where are you from?",
        "¿Cuántos años tienes?|How old are you?", "Ella es mi amiga|She is my friend/She's my friend",
        "Él es profesor|He is a teacher/He's a teacher", "Somos hermanos|We are brothers/We're brothers/We are siblings/We're siblings",
        "Trabajo en un hospital|I work in a hospital", "Me gusta la música|I like music"}},
      {0, "Comida|Food", "🍎",
       {"Tengo hambre|I am hungry/I'm hungry", "Quiero agua|I want water/I want some water", "Me gusta el café|I like coffee",
        "No me gusta el pescado|I do not like fish/I don't like fish", "La manzana es roja|The apple is red", "Comemos pan|We eat bread",
        "¿Quieres té?|Do you want tea?/Would you like tea?/Would you like some tea?/Do you want some tea?",
        "La cuenta, por favor|The bill, please/The check, please", "Una mesa para dos|A table for two",
        "La sopa está caliente|The soup is hot", "Ellos beben leche|They drink milk", "El desayuno está listo|Breakfast is ready"}},
      {0, "Familia y casa|Family and home", "🏠",
       {"Mi madre es médica|My mother is a doctor/My mum is a doctor/My mom is a doctor", "Tengo dos hermanas|I have two sisters",
        "Mi padre cocina|My father cooks/My dad cooks", "La casa es grande|The house is big/The house is large",
        "Mi hermano tiene un perro|My brother has a dog", "Nuestra cocina es pequeña|Our kitchen is small",
        "Los niños juegan en el jardín|The children play in the garden/The children are playing in the garden/The kids play in the garden",
        "Mi abuela vive con nosotros|My grandmother lives with us/My grandma lives with us",
        "El gato duerme en el sofá|The cat sleeps on the sofa/The cat is sleeping on the sofa/The cat sleeps on the couch",
        "¿Tienes hijos?|Do you have children?/Do you have kids?", "Mi hijo tiene cinco años|My son is five years old/My son is five",
        "La familia come junta los domingos|The family eats together on Sundays"}},
      {1, "La rutina|Daily routine", "⏰",
       {"Me levanto a las siete|I get up at seven/I wake up at seven",
        "Siempre desayuno en casa|I always have breakfast at home/I always eat breakfast at home",
        "Voy al trabajo en autobús|I go to work by bus", "Nunca veo la televisión|I never watch television/I never watch TV",
        "Normalmente ceno tarde|I usually have dinner late/I usually eat dinner late",
        "Los lunes voy al gimnasio|On Mondays I go to the gym/I go to the gym on Mondays",
        "Me ducho por la mañana|I take a shower in the morning/I shower in the morning/I have a shower in the morning",
        "¿A qué hora empiezas?|What time do you start?",
        "Ella lee antes de dormir|She reads before sleeping/She reads before going to sleep/She reads before bed",
        "Termino de trabajar a las cinco|I finish work at five/I finish working at five",
        "Los fines de semana descanso|I rest at the weekend/I rest on weekends/On weekends I rest/I rest at weekends",
        "Hoy estoy muy ocupado|Today I am very busy/I am very busy today/I'm very busy today/Today I'm very busy"}},
      {1, "De viaje|Travelling", "✈️",
       {"Ayer fui a la playa|Yesterday I went to the beach/I went to the beach yesterday", "El tren llegó tarde|The train arrived late/The train was late",
        "Perdí mi pasaporte|I lost my passport", "¿Dónde está la estación?|Where is the station?/Where's the station?",
        "Reservamos un hotel cerca del centro|We booked a hotel near the centre/We booked a hotel near the center/We booked a hotel near the city centre/We booked a hotel near the city center",
        "El vuelo sale a las diez|The flight leaves at ten/The flight departs at ten",
        "Compré un billete de ida y vuelta|I bought a return ticket/I bought a round-trip ticket",
        "¿Cuánto cuesta un taxi al aeropuerto?|How much is a taxi to the airport?/How much does a taxi to the airport cost?",
        "Visitamos el museo el sábado|We visited the museum on Saturday", "Hacía mucho calor|It was very hot",
        "Tuve que esperar una hora|I had to wait for an hour/I had to wait an hour/I had to wait one hour",
        "Nos perdimos en la ciudad|We got lost in the city"}},
      {1, "De compras|Shopping", "🛍️",
       {"¿Puedo probármelo?|Can I try it on?/May I try it on?", "¿Tiene una talla más grande?|Do you have a bigger size?/Do you have a larger size?",
        "Es demasiado caro|It is too expensive/It's too expensive", "Solo estoy mirando|I am just looking/I'm just looking",
        "¿Aceptan tarjeta?|Do you accept cards?/Do you take cards?/Do you accept card?/Do you take card?",
        "Me lo llevo|I will take it/I'll take it", "Está de oferta|It is on sale/It's on sale", "Necesito una bolsa|I need a bag",
        "¿Dónde están los probadores?|Where are the fitting rooms?/Where are the changing rooms?",
        "Quiero devolver esta camisa|I want to return this shirt/I would like to return this shirt/I'd like to return this shirt",
        "Estos zapatos son más cómodos|These shoes are more comfortable",
        "¿Cuánto es en total?|How much is it in total?/How much is that altogether?/How much is it altogether?"}},
      {2, "El trabajo|At work", "💼",
       {"He trabajado aquí durante tres años|I have worked here for three years/I've worked here for three years/I have been working here for three years/I've been working here for three years",
        "Todavía no he terminado el informe|I have not finished the report yet/I haven't finished the report yet",
        "Tenemos una reunión a las nueve|We have a meeting at nine", "Mi jefe está de vacaciones|My boss is on holiday/My boss is on vacation",
        "Estoy buscando un trabajo nuevo|I am looking for a new job/I'm looking for a new job", "¿Has enviado el correo?|Have you sent the email?/Have you sent the e-mail?",
        "Me han ofrecido un ascenso|I have been offered a promotion/I've been offered a promotion/They have offered me a promotion/They've offered me a promotion",
        "Trabajo desde casa dos días a la semana|I work from home two days a week",
        "La entrevista fue mejor de lo que esperaba|The interview went better than I expected/The interview was better than I expected",
        "Necesitamos contratar a más personas|We need to hire more people",
        "Ya he hablado con el cliente|I have already spoken to the client/I've already spoken to the client/I have already talked to the client/I've already talked to the client",
        "El plazo termina el viernes|The deadline is on Friday/The deadline is Friday"}},
      {2, "La salud|Health", "🩺",
       {"Me duele la cabeza|I have a headache/My head hurts/I've got a headache", "Deberías beber más agua|You should drink more water",
        "Tengo que ir al médico|I have to go to the doctor/I need to go to the doctor/I have to see a doctor/I need to see a doctor",
        "No he dormido bien esta semana|I have not slept well this week/I haven't slept well this week",
        "El médico me recetó unas pastillas|The doctor prescribed me some pills/The doctor gave me some pills/The doctor prescribed some pills",
        "Hago ejercicio tres veces por semana|I exercise three times a week/I do exercise three times a week",
        "Estoy resfriado|I have a cold/I've got a cold", "Deberías descansar un poco|You should rest a bit/You should rest a little/You should get some rest",
        "Soy alérgico a los frutos secos|I am allergic to nuts/I'm allergic to nuts",
        "¿Desde cuándo te sientes así?|How long have you been feeling like this?/How long have you felt like this?/Since when have you felt like this?",
        "No tienes que preocuparte|You do not have to worry/You don't have to worry/You don't need to worry/You do not need to worry",
        "Me siento mucho mejor hoy|I feel much better today/I'm feeling much better today"}},
      {2, "Planes|Plans", "🔮",
       {"Voy a estudiar inglés este verano|I am going to study English this summer/I'm going to study English this summer",
        "Si llueve, nos quedaremos en casa|If it rains, we will stay at home/If it rains, we'll stay at home/If it rains, we will stay home/If it rains, we'll stay home",
        "Te llamaré cuando llegue|I will call you when I arrive/I'll call you when I arrive/I will call you when I get there/I'll call you when I get there",
        "¿Qué vas a hacer este fin de semana?|What are you going to do this weekend?/What are you doing this weekend?",
        "Creo que mañana hará sol|I think it will be sunny tomorrow/I think it'll be sunny tomorrow",
        "Estamos pensando en mudarnos|We are thinking of moving/We're thinking of moving/We are thinking about moving/We're thinking about moving",
        "Si tengo tiempo, te ayudaré|If I have time, I will help you/If I have time, I'll help you", "Nos vemos el próximo mes|See you next month",
        "Quiero aprender a tocar la guitarra|I want to learn to play the guitar/I want to learn how to play the guitar",
        "Mi hermana se casa en junio|My sister is getting married in June",
        "Probablemente llegaremos tarde|We will probably arrive late/We'll probably arrive late/We will probably be late/We'll probably be late",
        "Ahorraré dinero para el viaje|I will save money for the trip/I'll save money for the trip"}},
      {3, "Opiniones|Opinions", "💬",
       {"En mi opinión, es una buena idea|In my opinion, it is a good idea/In my opinion, it's a good idea",
        "Estoy totalmente de acuerdo contigo|I totally agree with you/I completely agree with you/I fully agree with you",
        "No estoy seguro de que tengas razón|I am not sure you are right/I'm not sure you're right/I am not sure that you are right/I'm not sure that you're right",
        "Depende de la situación|It depends on the situation",
        "Por un lado es barato, pero por otro es lento|On the one hand it is cheap, but on the other it is slow/On the one hand it's cheap, but on the other it's slow/On the one hand it is cheap, but on the other hand it is slow/On the one hand it's cheap, but on the other hand it's slow",
        "Me parece que exageras|I think you are exaggerating/I think you're exaggerating/It seems to me that you are exaggerating",
        "Hay que tener en cuenta el coste|We have to take the cost into account/We need to take the cost into account/You have to take the cost into account",
        "Eso no tiene sentido|That does not make sense/That doesn't make sense/That makes no sense",
        "Lo que más me preocupa es el tiempo|What worries me most is the time/What worries me the most is the time",
        "Admito que me equivoqué|I admit I was wrong/I admit that I was wrong",
        "A pesar de todo, merece la pena|Despite everything, it is worth it/Despite everything, it's worth it/In spite of everything, it is worth it/In spite of everything, it's worth it",
        "Sería mejor esperar|It would be better to wait/It'd be better to wait"}},
      {3, "Tecnología|Technology", "💻",
       {"El programa fue creado en 2020|The program was created in 2020/The software was created in 2020",
        "La aplicación que descargué no funciona|The app I downloaded does not work/The app I downloaded doesn't work/The app that I downloaded doesn't work/The application I downloaded doesn't work",
        "Mis datos se guardan en la nube|My data is saved in the cloud/My data is stored in the cloud",
        "Hay que actualizar el sistema|The system needs to be updated/We need to update the system/You have to update the system",
        "Olvidé mi contraseña|I forgot my password/I've forgotten my password", "La batería dura todo el día|The battery lasts all day/The battery lasts the whole day",
        "El archivo se ha borrado por error|The file has been deleted by mistake/The file was deleted by mistake",
        "¿Podrías reiniciar el ordenador?|Could you restart the computer?/Could you reboot the computer?",
        "Cada vez más personas trabajan en línea|More and more people work online",
        "La inteligencia artificial está cambiando el mundo|Artificial intelligence is changing the world",
        "Este móvil se carga muy rápido|This phone charges very quickly/This phone charges very fast/This mobile charges very fast",
        "La red es más lenta de lo habitual|The network is slower than usual/The internet is slower than usual"}},
      {3, "El mundo de hoy|Today's world", "🌍",
       {"Si tuviera más tiempo, viajaría más|If I had more time, I would travel more/If I had more time, I'd travel more",
        "Ojalá hubiera menos contaminación|I wish there were less pollution/I wish there was less pollution",
        "Deberíamos reciclar más|We should recycle more", "El cambio climático afecta a todos|Climate change affects everyone/Climate change affects everybody",
        "Las ciudades necesitan más espacios verdes|Cities need more green spaces",
        "Si yo fuera tú, no lo haría|If I were you, I would not do it/If I were you, I wouldn't do it/If I were you, I wouldn't do that/If I were you, I would not do that",
        "Cada vez hay más coches eléctricos|There are more and more electric cars",
        "Se espera que la situación mejore|The situation is expected to improve/It is expected that the situation will improve",
        "Es importante ahorrar energía|It is important to save energy/It's important to save energy",
        "Mucha gente se ofrece como voluntaria|Many people volunteer/A lot of people volunteer/Lots of people volunteer",
        "Habría ido si me hubieras avisado|I would have gone if you had told me/I'd have gone if you'd told me/I would have gone if you had let me know/I would have gone if you'd told me",
        "El gobierno debería invertir en educación|The government should invest in education"}},
      {4, "Expresiones|Idioms", "🎭",
       {"Me estás tomando el pelo|You are pulling my leg/You're pulling my leg",
        "Llueve a cántaros|It is raining cats and dogs/It's raining cats and dogs/It's pouring/It is pouring",
        "Está chupado|It is a piece of cake/It's a piece of cake", "Más vale tarde que nunca|Better late than never",
        "No hay mal que por bien no venga|Every cloud has a silver lining", "Le costó un ojo de la cara|It cost him an arm and a leg/It cost her an arm and a leg",
        "Estoy hecho polvo|I am exhausted/I'm exhausted/I'm worn out/I am worn out", "Rompió el hielo con un chiste|He broke the ice with a joke/She broke the ice with a joke",
        "Matar dos pájaros de un tiro|To kill two birds with one stone/Kill two birds with one stone",
        "Tiene la sartén por el mango|He has the upper hand/She has the upper hand/He holds all the cards/She holds all the cards",
        "Lo dejamos para otro día|Let's take a rain check/We'll leave it for another day/Let's leave it for another day",
        "Me suena|It rings a bell/That rings a bell"}},
      {4, "Inglés formal|Formal English", "🏛️",
       {"Tenemos que posponer la reunión|We have to put off the meeting/We need to put off the meeting/We have to postpone the meeting/We need to postpone the meeting",
        "Me crié en un pueblo pequeño|I grew up in a small village/I grew up in a small town",
        "¿Puedes averiguar a qué hora abre?|Can you find out what time it opens?/Could you find out what time it opens?",
        "No soporto el ruido|I cannot put up with the noise/I can't put up with the noise/I can't stand the noise/I cannot stand the noise",
        "Nos hemos quedado sin leche|We have run out of milk/We've run out of milk/We ran out of milk",
        "Le agradecería que me respondiera pronto|I would appreciate it if you could reply soon/I'd appreciate it if you could reply soon/I would appreciate a prompt reply",
        "Adjunto el documento solicitado|Please find attached the requested document/I attach the requested document/I am attaching the requested document",
        "Lamento las molestias|I apologise for the inconvenience/I apologize for the inconvenience/Sorry for the inconvenience",
        "Hay que abordar este problema cuanto antes|This problem must be addressed as soon as possible/We need to address this problem as soon as possible",
        "Se negó a dar marcha atrás|He refused to back down/She refused to back down",
        "Llevamos a cabo un estudio exhaustivo|We carried out a thorough study/We carried out an exhaustive study/We conducted a thorough study",
        "No obstante, los resultados fueron positivos|Nevertheless, the results were positive/However, the results were positive"}},
  };
  return u;
}

// Los primeros pasos en seis idiomas: «español|inglés|francés|italiano|alemán|portugués».
const std::vector<RawUnit>& starter() {
  static const std::vector<RawUnit> u = {
      {0, "Primeros pasos|First steps", "👋",
       {"Hola|Hello/Hi|Bonjour/Salut|Ciao/Salve|Hallo|Olá/Oi", "Buenos días|Good morning|Bonjour|Buongiorno|Guten Morgen|Bom dia",
        "Gracias|Thank you/Thanks|Merci|Grazie|Danke|Obrigado/Obrigada", "Por favor|Please|S'il vous plaît/S'il te plaît|Per favore|Bitte|Por favor",
        "Adiós|Goodbye/Bye|Au revoir|Arrivederci/Ciao|Auf Wiedersehen/Tschüss|Tchau/Adeus",
        "¿Cómo estás?|How are you?|Comment ça va ?/Comment vas-tu ?|Come stai?|Wie geht es dir?/Wie geht's?|Como você está?/Tudo bem?",
        "Me llamo Ana|My name is Ana/I'm Ana|Je m'appelle Ana|Mi chiamo Ana|Ich heiße Ana|Meu nome é Ana/Eu me chamo Ana",
        "Sí|Yes|Oui|Sì|Ja|Sim", "No|No|Non|No|Nein|Não",
        "Lo siento|I am sorry/I'm sorry/Sorry|Je suis désolé/Désolé|Mi dispiace|Es tut mir leid|Desculpe/Sinto muito"}},
      {0, "Comida|Food", "🍎",
       {"Quiero agua|I want water|Je veux de l'eau|Voglio dell'acqua/Voglio acqua|Ich möchte Wasser/Ich will Wasser|Eu quero água/Quero água",
        "Me gusta el café|I like coffee|J'aime le café|Mi piace il caffè|Ich mag Kaffee|Eu gosto de café/Gosto de café",
        "Tengo hambre|I am hungry/I'm hungry|J'ai faim|Ho fame|Ich habe Hunger|Estou com fome/Eu estou com fome",
        "El pan|The bread|Le pain|Il pane|Das Brot|O pão", "La manzana|The apple|La pomme|La mela|Der Apfel|A maçã",
        "Una mesa para dos|A table for two|Une table pour deux|Un tavolo per due|Ein Tisch für zwei|Uma mesa para dois",
        "La cuenta, por favor|The bill, please/The check, please|L'addition, s'il vous plaît|Il conto, per favore|Die Rechnung, bitte|A conta, por favor",
        "El queso|The cheese|Le fromage|Il formaggio|Der Käse|O queijo", "Está delicioso|It is delicious/It's delicious|C'est délicieux|È delizioso|Es ist lecker/Es ist köstlich|Está delicioso/É delicioso",
        "No bebo leche|I do not drink milk/I don't drink milk|Je ne bois pas de lait|Non bevo latte|Ich trinke keine Milch|Eu não bebo leite/Não bebo leite"}},
      {0, "En la ciudad|In the city", "🏙️",
       {"¿Dónde está la estación?|Where is the station?|Où est la gare ?|Dov'è la stazione?|Wo ist der Bahnhof?|Onde fica a estação?/Onde é a estação?",
        "A la derecha|To the right/On the right|À droite|A destra|Rechts/Nach rechts|À direita",
        "A la izquierda|To the left/On the left|À gauche|A sinistra|Links/Nach links|À esquerda",
        "Todo recto|Straight ahead/Straight on|Tout droit|Sempre dritto/Dritto|Geradeaus|Em frente/Sempre em frente",
        "El hotel está cerca|The hotel is near/The hotel is close|L'hôtel est près/L'hôtel est proche|L'albergo è vicino/L'hotel è vicino|Das Hotel ist in der Nähe|O hotel fica perto/O hotel está perto",
        "¿Cuánto cuesta?|How much is it?/How much does it cost?|Combien ça coûte ?/C'est combien ?|Quanto costa?|Wie viel kostet das?/Was kostet das?|Quanto custa?",
        "Un billete, por favor|A ticket, please|Un billet, s'il vous plaît|Un biglietto, per favore|Eine Fahrkarte, bitte/Ein Ticket, bitte|Uma passagem, por favor/Um bilhete, por favor",
        "No entiendo|I do not understand/I don't understand|Je ne comprends pas|Non capisco|Ich verstehe nicht|Não entendo/Eu não entendo",
        "¿Habla inglés?|Do you speak English?|Parlez-vous anglais ?|Parla inglese?|Sprechen Sie Englisch?|Você fala inglês?",
        "Necesito ayuda|I need help|J'ai besoin d'aide|Ho bisogno di aiuto|Ich brauche Hilfe|Preciso de ajuda/Eu preciso de ajuda"}},
  };
  return u;
}

// ============================================================ los paquetes
struct Item {
  std::vector<std::string> src, tgt;   // [0] es la forma que se enseña; las demás también valen
};
struct Unit {
  int section = 0;
  std::string title, icon;
  std::vector<Item> items;
};
struct Pack {
  std::string id, target, source, name, flag;   // id: «en-es» (inglés para quien habla español)
  bool full = false;                            // el curso completo (A1–C1) o unos primeros pasos
  std::vector<Unit> units;
  int item_count() const {
    int n = 0;
    for (const auto& u : units) n += (int)u.items.size();
    return n;
  }
};
const char* lang_name(const std::string& code) {
  if (code == "en") return tx::L_EN;
  if (code == "es") return tx::L_ES;
  if (code == "fr") return tx::L_FR;
  if (code == "it") return tx::L_IT;
  if (code == "de") return tx::L_DE;
  if (code == "pt") return tx::L_PT;
  return "";
}
const char* lang_flag(const std::string& code) {
  if (code == "en") return "🇬🇧";
  if (code == "es") return "🇪🇸";
  if (code == "fr") return "🇫🇷";
  if (code == "it") return "🇮🇹";
  if (code == "de") return "🇩🇪";
  if (code == "pt") return "🇧🇷";
  return "🌐";
}
// El idioma de la interfaz (el del menú Idioma de la demo): el de las explicaciones.
std::string ui_lang() { return std::string(tx::L_ES) == "Español" ? "es" : "en"; }
bool is_full(const std::string& target, const std::string& source) {
  return (target == "en" && source == "es") || (target == "es" && source == "en");
}
bool in_catalog(const std::string& target, const std::string& source) {
  return target != source && lang_col(target) >= 0 && lang_col(source) >= 0 && (source == "es" || source == "en");
}
// Un paquete del catálogo, armado para quien habla «source».
Pack build_pack(const std::string& target, const std::string& source) {
  Pack p;
  p.target = target;
  p.source = source;
  p.id = target + "-" + source;
  p.full = is_full(target, source);
  p.name = lang_name(target);
  p.flag = lang_flag(target);
  const auto& raw = p.full ? course() : starter();
  int sc = p.full ? (source == "es" ? 0 : 1) : lang_col(source), tc = p.full ? (target == "es" ? 0 : 1) : lang_col(target);
  int title_col = source == "es" ? 0 : 1;
  for (const auto& r : raw) {
    Unit u;
    u.section = r.section;
    auto t = split(r.title, '|');
    u.title = t[(size_t)std::min(title_col, (int)t.size() - 1)];
    u.icon = r.icon;
    for (const char* line : r.items) {
      auto cols = split(line, '|');
      if ((int)cols.size() <= std::max(sc, tc)) continue;
      Item it;
      it.src = alts(cols[(size_t)sc]);
      it.tgt = alts(cols[(size_t)tc]);
      if (!it.src.empty() && !it.tgt.empty()) u.items.push_back(it);
    }
    if (!u.items.empty()) p.units.push_back(u);
  }
  return p;
}
std::string join_alts(const std::vector<std::string>& v) {
  std::string o;
  for (size_t i = 0; i < v.size(); i++) o += (i ? "/" : "") + v[i];
  return o;
}
// El paquete en su archivo: lo que se instala (y lo que otros pueden escribir e importar).
std::string pack_json(const Pack& p) {
  std::string o = "{\"minilang\":1,\"id\":" + jstr(p.id) + ",\"target\":" + jstr(p.target) + ",\"source\":" + jstr(p.source) +
                  ",\"name\":" + jstr(p.name) + ",\"flag\":" + jstr(p.flag) + ",\"full\":" + (p.full ? "true" : "false") + ",\"units\":[\n";
  for (size_t k = 0; k < p.units.size(); k++) {
    const Unit& u = p.units[k];
    o += std::string(k ? ",\n" : "") + " {\"section\":" + std::to_string(u.section) + ",\"title\":" + jstr(u.title) + ",\"icon\":" + jstr(u.icon) +
         ",\"items\":[";
    for (size_t i = 0; i < u.items.size(); i++)
      o += std::string(i ? "," : "") + "[" + jstr(join_alts(u.items[i].src)) + "," + jstr(join_alts(u.items[i].tgt)) + "]";
    o += "]}";
  }
  return o + "\n]}\n";
}
bool code_ok(const std::string& c) {
  if (c.empty() || c.size() > 8) return false;
  for (char ch : c)
    if (!std::islower((unsigned char)ch) && ch != '_') return false;
  return true;
}
// Leer un paquete (instalado o importado): si algo no cuadra, no se usa.
bool parse_pack(const std::string& text, Pack& p, std::string& error) {
  bool ok = false;
  Json j = parse_json(text, &ok);
  if (!ok || j.t != Json::OBJ || j["units"].t != Json::ARR) {
    error = tx::ERR_PACK_FORMAT;
    return false;
  }
  p = Pack();
  p.target = j["target"].s;
  p.source = j["source"].s;
  if (!code_ok(p.target) || !code_ok(p.source) || p.target == p.source) {
    error = tx::ERR_PACK_LANG;
    return false;
  }
  p.id = p.target + "-" + p.source;
  p.name = j["name"].s.empty() ? std::string(lang_name(p.target)) : j["name"].s;
  if (p.name.empty()) p.name = p.target;
  p.flag = j["flag"].s.empty() ? std::string(lang_flag(p.target)) : j["flag"].s;
  p.full = j["full"].b;
  for (const auto& ju : j["units"].a) {
    Unit u;
    u.section = std::max(0, std::min(4, (int)ju["section"].n));
    u.title = ju["title"].s;
    u.icon = ju["icon"].s.empty() ? "📘" : ju["icon"].s;
    for (const auto& ji : ju["items"].a) {
      if (ji.t != Json::ARR || ji.a.size() < 2) continue;
      Item it;
      it.src = alts(ji.a[0].s);
      it.tgt = alts(ji.a[1].s);
      if (!it.src.empty() && !it.tgt.empty()) u.items.push_back(it);
    }
    if (u.title.empty()) u.title = fmt(tx::UNIT_N, {std::to_string(p.units.size() + 1)});
    if (u.items.size() >= 3) p.units.push_back(u);
  }
  if (p.units.empty()) {
    error = tx::ERR_PACK_EMPTY;
    return false;
  }
  return true;
}

// ============================================================ el progreso
const int LESSONS = 3;                     // lecciones por unidad
const int HEARTS = 5;                      // vidas
const long long HEART_S = 30 * 60;         // una vida vuelve cada media hora
const int INTERVALS[] = {0, 1, 2, 4, 7, 15, 30};   // días hasta el próximo repaso, según lo bien que se sabe
const int GOALS[] = {10, 20, 30, 50};

// Lo de cada paquete: las lecciones hechas, lo que se sabe de cada frase y la experiencia.
struct Progress {
  std::vector<int> lessons;                                  // por unidad: 0..LESSONS
  std::map<std::string, std::pair<int, long long>> mem;      // «unidad:frase» → (fuerza 0..6, día del repaso)
  long long xp = 0;
  int done(int u) const { return u >= 0 && u < (int)lessons.size() ? lessons[(size_t)u] : 0; }
};
std::string mem_key(int u, int i) { return std::to_string(u) + ":" + std::to_string(i); }
std::string progress_text(const Progress& p) {
  std::string o = "xp=" + std::to_string(p.xp) + "\nlessons=";
  for (size_t i = 0; i < p.lessons.size(); i++) o += (i ? "," : "") + std::to_string(p.lessons[i]);
  o += "\n";
  for (const auto& kv : p.mem) o += "mem=" + kv.first + "," + std::to_string(kv.second.first) + "," + std::to_string(kv.second.second) + "\n";
  return o;
}
Progress progress_parse(const std::string& text, size_t units) {
  Progress p;
  p.lessons.assign(units, 0);
  for (const auto& l : split(text, '\n')) {
    if (l.rfind("xp=", 0) == 0) p.xp = std::atoll(l.c_str() + 3);
    else if (l.rfind("lessons=", 0) == 0) {
      auto v = split(l.substr(8), ',');
      for (size_t i = 0; i < v.size() && i < units; i++) p.lessons[i] = std::max(0, std::min(LESSONS, std::atoi(v[i].c_str())));
    } else if (l.rfind("mem=", 0) == 0) {
      auto v = split(l.substr(4), ',');
      if (v.size() == 3) p.mem[v[0]] = {std::max(0, std::min(6, std::atoi(v[1].c_str()))), std::atoll(v[2].c_str())};
    }
  }
  return p;
}
// Recordar una frase: bien, sube y se repasa más tarde; mal, baja y se repasa ya.
void remember(Progress& p, int u, int i, bool ok, long long today) {
  auto& m = p.mem[mem_key(u, i)];
  int s = ok ? std::min(6, m.first + 1) : std::max(0, m.first - 2);
  m = {s, today + (ok ? INTERVALS[s] : 0)};
}
int learned(const Progress& p) {
  int n = 0;
  for (const auto& kv : p.mem) n += kv.second.first >= 2 ? 1 : 0;
  return n;
}
int due_count(const Progress& p, long long today) {
  int n = 0;
  for (const auto& kv : p.mem) n += kv.second.second <= today ? 1 : 0;
  return n;
}
// La unidad por la que va: la primera sin terminar (las anteriores, hechas).
int current_unit(const Pack& pk, const Progress& p) {
  for (int u = 0; u < (int)pk.units.size(); u++)
    if (p.done(u) < LESSONS) return u;
  return (int)pk.units.size();
}
bool unlocked(const Progress& p, int u) { return u == 0 || p.done(u - 1) >= LESSONS; }

// Lo de la persona (en todos los idiomas): la racha, la meta del día y las vidas.
struct Stats {
  int streak = 0;
  long long last_day = -1000;    // el último día con una lección
  int xp_today = 0;
  long long xp_day = -1000;
  int goal = 20;
  int hearts = HEARTS;
  long long hearts_t = 0;        // desde cuándo se cuenta la próxima vida
  std::vector<long long> days;   // los días con práctica (los últimos 60)
  std::string pack;              // el que se estudia
  bool voice = true;
};
std::string stats_text(const Stats& s) {
  std::string days;
  for (size_t i = 0; i < s.days.size(); i++) days += (i ? "," : "") + std::to_string(s.days[i]);
  return "streak=" + std::to_string(s.streak) + "\nlast_day=" + std::to_string(s.last_day) + "\nxp_today=" + std::to_string(s.xp_today) +
         "\nxp_day=" + std::to_string(s.xp_day) + "\ngoal=" + std::to_string(s.goal) + "\nhearts=" + std::to_string(s.hearts) +
         "\nhearts_t=" + std::to_string(s.hearts_t) + "\ndays=" + days + "\npack=" + s.pack + "\nvoice=" + (s.voice ? "1" : "0") + "\n";
}
Stats stats_parse(const std::string& text) {
  Stats s;
  for (const auto& l : split(text, '\n')) {
    size_t eq = l.find('=');
    if (eq == std::string::npos) continue;
    std::string k = l.substr(0, eq), v = l.substr(eq + 1);
    long long n = std::atoll(v.c_str());
    if (k == "streak") s.streak = (int)n;
    else if (k == "last_day") s.last_day = n;
    else if (k == "xp_today") s.xp_today = (int)n;
    else if (k == "xp_day") s.xp_day = n;
    else if (k == "goal") s.goal = std::max(5, std::min(200, (int)n));
    else if (k == "hearts") s.hearts = std::max(0, std::min(HEARTS, (int)n));
    else if (k == "hearts_t") s.hearts_t = n;
    else if (k == "pack") s.pack = v;
    else if (k == "voice") s.voice = v != "0";
    else if (k == "days")
      for (const auto& d : split(v, ','))
        if (!d.empty()) s.days.push_back(std::atoll(d.c_str()));
  }
  return s;
}
// Sin practicar ayer ni hoy, la racha se pierde.
int streak_now(const Stats& s, long long today) { return s.last_day >= today - 1 ? s.streak : 0; }
int xp_today(const Stats& s, long long today) { return s.xp_day == today ? s.xp_today : 0; }
void add_xp(Stats& s, int xp, long long today) {
  if (s.xp_day != today) {
    s.xp_today = 0;
    s.xp_day = today;
  }
  s.xp_today += xp;
  if (s.last_day == today - 1) s.streak++;
  else if (s.last_day != today) s.streak = 1;
  s.last_day = today;
  if (std::find(s.days.begin(), s.days.end(), today) == s.days.end()) s.days.push_back(today);
  while (s.days.size() > 60) s.days.erase(s.days.begin());
}
bool practiced(const Stats& s, long long day) { return std::find(s.days.begin(), s.days.end(), day) != s.days.end(); }
// Las vidas vuelven solas: una cada media hora.
void refill(Stats& s, long long now) {
  if (s.hearts >= HEARTS) {
    s.hearts_t = now;
    return;
  }
  long long n = (now - s.hearts_t) / HEART_S;
  if (n > 0) {
    s.hearts = (int)std::min<long long>(HEARTS, s.hearts + n);
    s.hearts_t += n * HEART_S;
    if (s.hearts >= HEARTS) s.hearts_t = now;
  }
}
void lose_heart(Stats& s, long long now) {
  if (s.hearts >= HEARTS) s.hearts_t = now;
  s.hearts = std::max(0, s.hearts - 1);
}
long long next_heart_in(const Stats& s, long long now) { return s.hearts >= HEARTS ? 0 : std::max(0LL, s.hearts_t + HEART_S - now); }
// El nivel (A1…C1) por el que va: la sección de su unidad.
int level_of(const Pack& pk, const Progress& p) {
  int u = current_unit(pk, p);
  if (u >= (int)pk.units.size()) return pk.units.empty() ? 0 : pk.units.back().section;
  return pk.units[(size_t)u].section;
}

// ============================================================ los juegos
enum Kind { K_CHOOSE = 0, K_CHOOSE_REV, K_BUILD, K_MATCH, K_TYPE, K_LISTEN };
struct Exercise {
  Kind kind = K_CHOOSE;
  int unit = 0, item = 0;
  std::vector<std::string> options;   // elegir: las cuatro respuestas
  int answer = -1;
  std::vector<std::string> tiles;     // ordenar: las palabras barajadas (con alguna de más)
  std::vector<std::pair<int, int>> pairs;   // parejas: (unidad, frase)
  std::vector<int> right_order;             // el orden de la columna de la derecha
  bool retry = false;                       // vuelve al final de la lección tras un fallo
};
const Item& item_at(const Pack& p, int u, int i) { return p.units[(size_t)u].items[(size_t)i]; }
bool short_item(const Item& it) { return words_of(it.tgt[0]).size() <= 4 && words_of(it.src[0]).size() <= 5; }
// Otras frases para despistar: primero de la misma unidad.
std::vector<std::pair<int, int>> others(const Pack& p, int u, int i, std::mt19937& rng) {
  std::vector<std::pair<int, int>> same, rest;
  for (int k = 0; k < (int)p.units[(size_t)u].items.size(); k++)
    if (k != i) same.push_back({u, k});
  for (int v = 0; v < (int)p.units.size(); v++)
    if (v != u)
      for (int k = 0; k < (int)p.units[(size_t)v].items.size(); k++) rest.push_back({v, k});
  std::shuffle(same.begin(), same.end(), rng);
  std::shuffle(rest.begin(), rest.end(), rng);
  same.insert(same.end(), rest.begin(), rest.end());
  return same;
}
Exercise make_exercise(Kind k, const Pack& p, int u, int i, bool tts, std::mt19937& rng) {
  Exercise e;
  e.kind = k;
  e.unit = u;
  e.item = i;
  const Item& it = item_at(p, u, i);
  if (e.kind == K_LISTEN && !tts) e.kind = K_TYPE;
  if (e.kind == K_BUILD && words_of(it.tgt[0]).size() < 2) e.kind = K_CHOOSE;
  if (e.kind == K_CHOOSE || e.kind == K_CHOOSE_REV) {
    bool rev = e.kind == K_CHOOSE_REV;
    auto pick = [&](const Item& x) { return rev ? x.src[0] : x.tgt[0]; };
    std::string right = pick(it);
    e.options.push_back(right);
    for (const auto& o : others(p, u, i, rng)) {
      if (e.options.size() >= 4) break;
      std::string cand = pick(item_at(p, o.first, o.second));
      bool dup = false;
      for (const auto& x : e.options) dup = dup || norm(x, true) == norm(cand, true);
      if (!dup) e.options.push_back(cand);
    }
    std::shuffle(e.options.begin(), e.options.end(), rng);
    for (int k2 = 0; k2 < (int)e.options.size(); k2++)
      if (e.options[(size_t)k2] == right) e.answer = k2;
  } else if (e.kind == K_BUILD) {
    e.tiles = words_of(it.tgt[0]);
    std::vector<std::string> answer_words;
    for (const auto& a : it.tgt)
      for (const auto& w : words_of(a)) answer_words.push_back(norm(w, true));
    int extra = 0;
    for (const auto& o : others(p, u, i, rng)) {
      if (extra >= 3) break;
      auto ws = words_of(item_at(p, o.first, o.second).tgt[0]);
      if (ws.empty()) continue;
      std::string w = ws[rng() % ws.size()];
      bool dup = std::find(answer_words.begin(), answer_words.end(), norm(w, true)) != answer_words.end();
      for (const auto& t : e.tiles) dup = dup || norm(t, true) == norm(w, true);
      if (!dup) {
        e.tiles.push_back(w);
        extra++;
      }
    }
    std::shuffle(e.tiles.begin(), e.tiles.end(), rng);
  } else if (e.kind == K_MATCH) {
    std::vector<int> pool;
    for (int k2 = 0; k2 < (int)p.units[(size_t)u].items.size(); k2++)
      if (short_item(p.units[(size_t)u].items[(size_t)k2])) pool.push_back(k2);
    std::shuffle(pool.begin(), pool.end(), rng);
    // La frase de este ejercicio, la primera; luego otras cortas, sin dos iguales.
    std::vector<int> chosen;
    if (short_item(it)) chosen.push_back(i);
    for (int k2 : pool) {
      if (chosen.size() >= 5) break;
      if (std::find(chosen.begin(), chosen.end(), k2) != chosen.end()) continue;
      bool dup = false;
      for (int c : chosen)
        dup = dup || norm(item_at(p, u, c).tgt[0], true) == norm(item_at(p, u, k2).tgt[0], true) ||
              norm(item_at(p, u, c).src[0], true) == norm(item_at(p, u, k2).src[0], true);
      if (!dup) chosen.push_back(k2);
    }
    if (chosen.size() < 3) return make_exercise(K_CHOOSE_REV, p, u, i, tts, rng);
    for (int c : chosen) e.pairs.push_back({u, c});
    std::shuffle(e.pairs.begin(), e.pairs.end(), rng);
    for (int k2 = 0; k2 < (int)e.pairs.size(); k2++) e.right_order.push_back(k2);
    std::shuffle(e.right_order.begin(), e.right_order.end(), rng);
  }
  return e;
}
// Una lección: diez juegos con las frases nuevas de esa parte de la unidad y alguna de repaso.
std::vector<Exercise> make_lesson(const Pack& p, int u, int k, bool tts, unsigned seed) {
  std::mt19937 rng(seed);
  int n = (int)p.units[(size_t)u].items.size();
  int a = k * n / LESSONS, b = (k + 1) * n / LESSONS;
  std::vector<std::pair<int, int>> focus;
  for (int i = a; i < b; i++) focus.push_back({u, i});
  std::vector<std::pair<int, int>> review;
  for (int i = 0; i < a; i++) review.push_back({u, i});
  if (review.empty() && u > 0)
    for (int i = 0; i < (int)p.units[(size_t)u - 1].items.size(); i++) review.push_back({u - 1, i});
  std::shuffle(review.begin(), review.end(), rng);
  for (size_t i = 0; i < review.size() && i < 2; i++) focus.push_back(review[i]);
  static const Kind pattern[LESSONS][10] = {
      {K_CHOOSE, K_CHOOSE, K_BUILD, K_MATCH, K_CHOOSE_REV, K_BUILD, K_CHOOSE, K_BUILD, K_LISTEN, K_BUILD},
      {K_BUILD, K_CHOOSE, K_MATCH, K_BUILD, K_CHOOSE_REV, K_LISTEN, K_TYPE, K_BUILD, K_TYPE, K_BUILD},
      {K_BUILD, K_TYPE, K_MATCH, K_LISTEN, K_TYPE, K_BUILD, K_CHOOSE_REV, K_TYPE, K_LISTEN, K_TYPE}};
  std::vector<Exercise> out;
  size_t next = 0;
  for (Kind kind : pattern[std::max(0, std::min(LESSONS - 1, k))]) {
    auto f = focus[next++ % focus.size()];
    if (kind == K_MATCH) f = {u, a};
    out.push_back(make_exercise(kind, p, f.first, f.second, tts, rng));
  }
  return out;
}
// El repaso: las frases que tocan (o las que peor se saben), sin gastar vidas.
std::vector<Exercise> make_review(const Pack& p, const Progress& pr, long long today, bool tts, unsigned seed) {
  std::mt19937 rng(seed);
  struct C {
    int u, i, s;
    long long due;
  };
  std::vector<C> c;
  for (const auto& kv : pr.mem) {
    auto v = split(kv.first, ':');
    if (v.size() != 2) continue;
    int u = std::atoi(v[0].c_str()), i = std::atoi(v[1].c_str());
    if (u < 0 || u >= (int)p.units.size() || i < 0 || i >= (int)p.units[(size_t)u].items.size()) continue;
    c.push_back({u, i, kv.second.first, kv.second.second});
  }
  std::shuffle(c.begin(), c.end(), rng);
  std::stable_sort(c.begin(), c.end(), [&](const C& x, const C& y) {
    bool dx = x.due <= today, dy = y.due <= today;
    if (dx != dy) return dx;
    return x.s < y.s;
  });
  std::vector<Exercise> out;
  static const Kind pattern[] = {K_BUILD, K_TYPE, K_CHOOSE_REV, K_LISTEN, K_BUILD, K_CHOOSE, K_TYPE, K_BUILD};
  for (size_t k = 0; k < 8 && k < c.size(); k++) out.push_back(make_exercise(pattern[k], p, c[k].u, c[k].i, tts, rng));
  return out;
}
// La prueba de nivel: dos frases de cada unidad, de la más fácil a la más difícil.
std::vector<Exercise> make_test(const Pack& p, unsigned seed) {
  std::mt19937 rng(seed);
  std::vector<Exercise> out;
  for (int u = 0; u < (int)p.units.size(); u++) {
    int n = (int)p.units[(size_t)u].items.size();
    int a = (int)(rng() % (unsigned)n), b = (a + 1 + (int)(rng() % (unsigned)std::max(1, n - 1))) % n;
    out.push_back(make_exercise(K_BUILD, p, u, a, false, rng));
    out.push_back(make_exercise(K_TYPE, p, u, b, false, rng));
  }
  return out;
}
// Hasta dónde llega: las unidades seguidas con las dos bien.
int test_result(const std::vector<std::pair<int, bool>>& answers) {
  std::map<int, int> wrong, seen;
  for (const auto& a : answers) {
    seen[a.first]++;
    if (!a.second) wrong[a.first]++;
  }
  int u = 0;
  while (seen.count(u) && seen[u] >= 2 && !wrong[u]) u++;
  return u;
}

// ============================================================ la voz
// En macOS, «say» lee la frase con una voz del idioma (si hay una instalada).
#ifdef __APPLE__
std::string voice_for(const std::string& lang) {
  static std::vector<std::pair<std::string, std::string>> voices;   // (nombre, «en_US»)
  static bool loaded = false;
  if (!loaded) {
    loaded = true;
    if (FILE* p = popen("/usr/bin/say -v '?' 2>/dev/null", "r")) {
      char line[512];
      while (std::fgets(line, sizeof line, p)) {
        std::string l = line;
        size_t hash = l.find('#');
        std::string head = trim(l.substr(0, hash));
        size_t sp = head.find_last_of(' ');
        if (sp == std::string::npos) continue;
        std::string loc = head.substr(sp + 1), name = trim(head.substr(0, sp));
        if (loc.size() >= 5 && loc[2] == '_') voices.push_back({name, loc});
      }
      pclose(p);
    }
  }
  static const std::map<std::string, std::vector<std::string>> pref = {
      {"en", {"Samantha", "Daniel", "Karen", "Moira"}}, {"es", {"Mónica", "Paulina", "Jorge"}}, {"fr", {"Thomas", "Amélie"}},
      {"it", {"Alice", "Luca"}},                         {"de", {"Anna", "Markus"}},             {"pt", {"Luciana", "Joana"}}};
  auto it = pref.find(lang);
  if (it != pref.end())
    for (const auto& want : it->second)
      for (const auto& v : voices)
        if (v.first == want) return v.first;
  for (const auto& v : voices)
    if (v.second.compare(0, 3, lang + "_") == 0) return v.first;
  return "";
}
#endif
bool tts_available() {
#ifdef __APPLE__
  return file_exists("/usr/bin/say");
#else
  return false;
#endif
}
void speak(const std::string& text, const std::string& lang, bool slow) {
#ifdef __APPLE__
  static std::atomic<int> last{0};
  int prev = last.exchange(0);
  if (prev > 0) kill((pid_t)prev, SIGTERM);   // la anterior se calla
  std::vector<std::string> args = {"/usr/bin/say"};
  std::string v = voice_for(lang);
  if (!v.empty()) {
    args.push_back("-v");
    args.push_back(v);
  }
  if (slow) {
    args.push_back("-r");
    args.push_back("115");
  }
  args.push_back(text);
  std::vector<char*> argv;
  for (auto& a : args) argv.push_back(&a[0]);
  argv.push_back(nullptr);
  pid_t pid = 0;
  if (posix_spawn(&pid, "/usr/bin/say", nullptr, nullptr, argv.data(), environ) == 0) {
    last = (int)pid;
    std::thread([pid] {
      int st = 0;
      waitpid(pid, &st, 0);
      int expected = (int)pid;
      last.compare_exchange_strong(expected, 0);   // ya terminó: no se le manda nada más
    }).detach();
  }
#else
  (void)text;
  (void)lang;
  (void)slow;
#endif
}

// ============================================================ el dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
// Los colores de MiniLang.
const unsigned C_BG = 0xf6f7fb, C_CARD = 0xffffff, C_LINE = 0xe3e6ee, C_TEXT = 0x1f2433, C_MUTED = 0x6b7285, C_ACCENT = 0x4f6bff,
               C_ACCENT_D = 0x3549c9, C_SOFT = 0xe8ecff, C_GOOD = 0x1e9e5a, C_GOOD_D = 0x157a44, C_GOOD_SOFT = 0xdcf5e7, C_BAD = 0xe5484d,
               C_BAD_SOFT = 0xfde4e5, C_GOLD = 0xf5a623, C_FIRE = 0xff7a1a, C_HEART = 0xef4466, C_LOCK = 0xe6e9f0;
const unsigned SECTION_COLORS[] = {0x22b07d, 0x2f9fe0, 0x7a5cff, 0xf08c2e, 0xe0457b};
const char* section_name(int s) {
  static const char* n[] = {tx::SEC_A1, tx::SEC_A2, tx::SEC_B1, tx::SEC_B2, tx::SEC_C1};
  return n[std::max(0, std::min(4, s))];
}
const char* section_code(int s) {
  static const char* n[] = {"A1", "A2", "B1", "B2", "C1"};
  return n[std::max(0, std::min(4, s))];
}
struct Hit {
  int x, y, w, h, act, idx;
};
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(line);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(fill);
  fl_rounded_rectf(x + 1, y + 1, w - 2, h - 2, std::max(0, r - 1));
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
// En líneas que caben en «w» (con la letra que esté puesta).
std::vector<std::string> wrap(const std::string& s, int w) {
  std::vector<std::string> out;
  for (const auto& para : split(s, '\n')) {
    std::string line;
    for (const auto& word : split(para, ' ')) {
      std::string t = line.empty() ? word : line + " " + word;
      if (!line.empty() && (int)fl_width(t.c_str()) > w) {
        out.push_back(line);
        line = word;
      } else line = t;
    }
    out.push_back(line);
  }
  return out;
}
std::string clock_text(double s) {
  int t = (int)s;
  char b[16];
  std::snprintf(b, sizeof b, "%d:%02d", t / 60, t % 60);
  return b;
}
// Mini, la mascota: una cabeza redonda con cascos (escucha y habla idiomas).
void mascot(int cx, int cy, int r, unsigned color, bool happy) {
  fl_color(rgb(0x2b2f3a));
  fl_line_style(FL_SOLID | FL_CAP_ROUND, std::max(2, r / 7));
  fl_arc(cx - r - r / 8, cy - r - r / 6, 2 * r + r / 4, 2 * r + r / 2, 20, 160);
  fl_line_style(0);
  fl_color(rgb(color));
  fl_pie(cx - r, cy - r, 2 * r, 2 * r, 0, 360);
  fl_color(rgb(0x2b2f3a));
  fl_rounded_rectf(cx - r - r / 4, cy - r / 4, r / 3, r / 2 + r / 6, r / 8);
  fl_rounded_rectf(cx + r - r / 12, cy - r / 4, r / 3, r / 2 + r / 6, r / 8);
  int ew = r / 2, eh = r / 2 + r / 8;
  fl_color(FL_WHITE);
  fl_pie(cx - r / 2 - ew / 2, cy - r / 3 - eh / 2, ew, eh, 0, 360);
  fl_pie(cx + r / 2 - ew / 2, cy - r / 3 - eh / 2, ew, eh, 0, 360);
  fl_color(rgb(0x1f2433));
  int pw = std::max(3, r / 5);
  fl_pie(cx - r / 2 - pw / 2 + 1, cy - r / 3 - pw / 2 + 1, pw, pw, 0, 360);
  fl_pie(cx + r / 2 - pw / 2 + 1, cy - r / 3 - pw / 2 + 1, pw, pw, 0, 360);
  fl_color(FL_WHITE);
  fl_line_style(FL_SOLID | FL_CAP_ROUND, std::max(2, r / 9));
  if (happy) fl_arc(cx - r / 3, cy - r / 4, 2 * r / 3, r / 2 + r / 8, 200, 340);
  else fl_line(cx - r / 5, cy + r / 3, cx + r / 5, cy + r / 3);
  fl_line_style(0);
  fl_color(rgb(0xffb4c8));
  fl_pie(cx - r + r / 5, cy + r / 12, r / 4, r / 6, 0, 360);
  fl_pie(cx + r - r / 5 - r / 4, cy + r / 12, r / 4, r / 6, 0, 360);
}

enum Mode { M_HOME = 0, M_LESSON, M_RESULT, M_PACKS };
enum SessionType { S_LESSON = 0, S_REVIEW, S_TEST };
// Una lección (o un repaso, o la prueba de nivel) en marcha.
struct Session {
  SessionType type = S_LESSON;
  int unit = 0, lesson = 0;
  std::vector<Exercise> queue;
  size_t pos = 0;
  int total = 0, mistakes = 0, answered = 0, right = 0;
  double started = 0;
  // El juego de ahora.
  int choice = -1;
  std::vector<int> placed;   // ordenar: las fichas puestas (su índice en tiles)
  int match_left = -1;       // parejas: la de la izquierda elegida
  std::vector<bool> matched;
  int wrong_left = -1, wrong_right = -1;
  bool match_error = false;
  bool checked = false, correct = false;
  Check result;
  std::vector<std::pair<int, bool>> test_answers;
  // Al terminar.
  int xp_gain = 0, passed_units = 0;
  double seconds = 0;
  bool goal_reached = false, out_of_hearts = false;
  bool active() const { return pos < queue.size(); }
  const Exercise& cur() const { return queue[pos]; }
  void reset_current() {
    choice = -1;
    placed.clear();
    match_left = -1;
    wrong_left = wrong_right = -1;
    match_error = false;
    matched.assign(active() ? cur().pairs.size() : 0, false);
    checked = correct = false;
    result = Check();
  }
};
// Una tarjeta de la pantalla de idiomas.
struct PackCard {
  std::string id, flag, name, info;
  int state = 0;   // 0 para instalar, 1 instalado, 2 el que se estudia
};

class LessonView : public Fl_Widget {
public:
  Mode mode = M_HOME;
  const Pack* pack = nullptr;
  const Progress* prog = nullptr;
  const Stats* stats = nullptr;
  Session* ses = nullptr;
  std::vector<PackCard> cards;
  long long today = 0, now = 0;
  bool tts = false;
  int scroll = 0, content_h = 0, hover = -1;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;
  std::function<bool(int)> on_key;
  // Dónde va el campo para escribir (lo coloca la ventana).
  int entry_x = 0, entry_y = 0, entry_w = 0;
  LessonView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  // Un botón con canto (como una tecla) y su zona para el clic.
  void button(int bx, int by, int bw, int bh, const std::string& label, int act, int idx, unsigned fill, unsigned fg, unsigned edge,
              int size = 15) {
    bool hot = (int)hits.size() == hover;
    fl_color(rgb(edge));
    fl_rounded_rectf(bx, by + 3, bw, bh, 12);
    fl_color(rgb(fill));
    fl_rounded_rectf(bx, by + (hot ? 1 : 0), bw, bh - (hot ? 1 : 0), 12);
    fl_font(FL_HELVETICA_BOLD, size);
    fl_color(rgb(fg));
    fl_draw(fit(label, bw - 12).c_str(), bx, by, bw, bh, FL_ALIGN_CENTER);
    hits.push_back({bx, by, bw, bh + 3, act, idx});
  }
  void chip(int& cx, int cy, const std::string& text, unsigned color, int act = 0) {
    fl_font(FL_HELVETICA_BOLD, 15);
    int cw = (int)fl_width(text.c_str()) + 22;
    cx -= cw;
    fl_color(rgb(act && (int)hits.size() == hover ? C_SOFT : C_BG));
    fl_rounded_rectf(cx, cy, cw, 34, 17);
    fl_color(rgb(color));
    fl_draw(text.c_str(), cx, cy, cw, 34, FL_ALIGN_CENTER);
    if (act) hits.push_back({cx, cy, cw, 34, act, -1});
    cx -= 8;
  }
  // Arriba: Mini, el idioma que se estudia y la racha, la meta y las vidas.
  void header(bool back) {
    fl_color(rgb(C_CARD));
    fl_rectf(x(), y(), w(), 64);
    fl_color(rgb(C_LINE));
    fl_line(x(), y() + 63, x() + w(), y() + 63);
    mascot(x() + 34, y() + 32, 18, C_ACCENT, true);
    fl_font(FL_HELVETICA_BOLD, 20);
    fl_color(rgb(C_TEXT));
    fl_draw("MiniLang", x() + 60, y() + 39);
    int px = x() + 172;
    if (back) {
      button(px, y() + 14, 120, 34, tx::BACK, 34, -1, C_BG, C_TEXT, C_LINE, 14);
    } else if (pack) {
      std::string t = pack->flag + "  " + pack->name + "  ▾";
      fl_font(FL_HELVETICA_BOLD, 15);
      int cw = (int)fl_width(t.c_str()) + 28;
      bool hot = (int)hits.size() == hover;
      fl_color(rgb(hot ? C_SOFT : C_BG));
      fl_rounded_rectf(px, y() + 14, cw, 36, 18);
      fl_color(rgb(C_TEXT));
      fl_draw(t.c_str(), px, y() + 14, cw, 36, FL_ALIGN_CENTER);
      hits.push_back({px, y() + 14, cw, 36, 4, -1});
    }
    if (!stats) return;
    int cx = x() + w() - 16;
    chip(cx, y() + 15, "❤️ " + std::to_string(stats->hearts), C_HEART);
    chip(cx, y() + 15, "⚡ " + std::to_string(xp_today(*stats, today)) + "/" + std::to_string(stats->goal) + " XP", C_GOLD);
    chip(cx, y() + 15, "🔥 " + std::to_string(streak_now(*stats, today)), C_FIRE);
  }

  // ---- el inicio: las unidades por nivel y, a la derecha, la meta, la racha y el repaso
  void draw_home() {
    header(false);
    if (!pack || !prog) return;
    int right_w = 316, gap = 16;
    int lw = w() - right_w - 3 * gap;
    int lx = x() + gap;
    fl_push_clip(x(), y() + 64, lw + gap, h() - 64);
    int Y = y() + 64 + 12 - scroll;
    int cur = current_unit(*pack, *prog);
    int last_section = -1;
    for (int u = 0; u < (int)pack->units.size(); u++) {
      const Unit& un = pack->units[(size_t)u];
      if (un.section != last_section) {
        last_section = un.section;
        int first = u, last = u;
        while (last + 1 < (int)pack->units.size() && pack->units[(size_t)last + 1].section == un.section) last++;
        Y += 6;
        fl_color(rgb(SECTION_COLORS[un.section]));
        fl_rounded_rectf(lx, Y + 10, 44, 28, 8);
        fl_font(FL_HELVETICA_BOLD, 15);
        fl_color(FL_WHITE);
        fl_draw(section_code(un.section), lx, Y + 10, 44, 28, FL_ALIGN_CENTER);
        fl_font(FL_HELVETICA_BOLD, 19);
        fl_color(rgb(C_TEXT));
        fl_draw(section_name(un.section), lx + 56, Y + 31);
        fl_font(FL_HELVETICA, 13);
        fl_color(rgb(C_MUTED));
        std::string range = fmt(tx::UNITS_RANGE, {std::to_string(first + 1), std::to_string(last + 1)});
        fl_draw(range.c_str(), lx + lw - (int)fl_width(range.c_str()), Y + 30);
        Y += 48;
      }
      int done = prog->done(u);
      bool open = unlocked(*prog, u), complete = done >= LESSONS, now_u = u == cur;
      round_box(lx, Y, lw, 92, 16, rgb(now_u ? 0xfbfcff : C_CARD), rgb(now_u ? C_ACCENT : C_LINE));
      unsigned circle = complete ? SECTION_COLORS[un.section] : now_u ? C_ACCENT : C_LOCK;
      fl_color(rgb(complete || now_u ? circle : 0xd5dae4));
      fl_pie(lx + 18, Y + 18, 60, 60, 0, 360);
      fl_color(rgb(circle));
      fl_pie(lx + 18, Y + 14, 60, 60, 0, 360);
      fl_font(FL_HELVETICA, 26);
      fl_draw(open ? un.icon.c_str() : "🔒", lx + 18, Y + 14, 60, 60, FL_ALIGN_CENTER);
      if (complete) {
        fl_color(rgb(C_GOLD));
        fl_pie(lx + 60, Y + 8, 22, 22, 0, 360);
        fl_font(FL_HELVETICA_BOLD, 13);
        fl_color(FL_WHITE);
        fl_draw("✓", lx + 60, Y + 8, 22, 22, FL_ALIGN_CENTER);
      }
      fl_font(FL_HELVETICA_BOLD, 17);
      fl_color(rgb(open ? C_TEXT : C_MUTED));
      fl_draw(fit(fmt(tx::UNIT_TITLE, {std::to_string(u + 1), un.title}), lw - 290).c_str(), lx + 96, Y + 36);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(C_MUTED));
      std::string sub = complete ? fmt(tx::UNIT_DONE, {std::to_string(un.items.size())})
                        : open   ? fmt(tx::UNIT_LESSON, {std::to_string(done + 1), std::to_string(LESSONS)})
                                 : std::string(tx::UNIT_LOCKED);
      fl_draw(sub.c_str(), lx + 96, Y + 58);
      for (int k = 0; k < LESSONS; k++) {
        fl_color(rgb(k < done ? SECTION_COLORS[un.section] : C_LOCK));
        fl_rounded_rectf(lx + 96 + k * 34, Y + 68, 28, 8, 4);
      }
      int bx = lx + lw - 168;
      if (now_u && open) button(bx, Y + 24, 150, 42, done ? tx::CONTINUE_UNIT : tx::START, 1, u, C_ACCENT, 0xffffff, C_ACCENT_D);
      else if (complete) button(bx, Y + 24, 150, 42, tx::PRACTICE, 1, u, C_CARD, C_ACCENT, C_LINE);
      Y += 104;
    }
    content_h = Y + scroll - (y() + 64);
    fl_pop_clip();
    // La barra de desplazamiento.
    int view_h = h() - 64;
    if (content_h > view_h) {
      int th = std::max(40, view_h * view_h / content_h);
      int ty = y() + 64 + (view_h - th) * scroll / std::max(1, content_h - view_h);
      fl_color(rgb(0xc9cedb));
      fl_rounded_rectf(lx + lw + 5, ty + 4, 6, th - 8, 3);
    }
    draw_side(x() + w() - right_w - gap, right_w);
  }
  void card_title(int cx, int cy, const char* t) {
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(C_TEXT));
    fl_draw(t, cx + 18, cy + 28);
  }
  void draw_side(int sx, int sw) {
    int Y = y() + 64 + 16;
    // La meta del día: un anillo.
    int xt = xp_today(*stats, today), goal = std::max(1, stats->goal);
    round_box(sx, Y, sw, 128, 16, rgb(C_CARD), rgb(C_LINE));
    card_title(sx, Y, tx::DAILY_GOAL);
    int r = 40, rcx = sx + 64, rcy = Y + 78;
    fl_color(rgb(C_LOCK));
    fl_pie(rcx - r, rcy - r, 2 * r, 2 * r, 0, 360);
    double frac = std::min(1.0, xt / (double)goal);
    fl_color(rgb(frac >= 1 ? C_GOOD : C_GOLD));
    if (frac > 0) fl_pie(rcx - r, rcy - r, 2 * r, 2 * r, 90 - 360 * frac, 90);
    fl_color(rgb(C_CARD));
    fl_pie(rcx - r + 9, rcy - r + 9, 2 * r - 18, 2 * r - 18, 0, 360);
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(rgb(C_TEXT));
    fl_draw((std::to_string(xt) + "/" + std::to_string(goal)).c_str(), rcx - r, rcy - r, 2 * r, 2 * r, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_MUTED));
    auto lines = wrap(frac >= 1 ? tx::GOAL_DONE : fmt(tx::GOAL_LEFT, {std::to_string(goal - xt)}), sw - 140);
    for (size_t i = 0; i < lines.size() && i < 3; i++) fl_draw(lines[i].c_str(), sx + 124, Y + 66 + (int)i * 18);
    Y += 140;
    // La racha: los días de esta semana.
    round_box(sx, Y, sw, 104, 16, rgb(C_CARD), rgb(C_LINE));
    int st = streak_now(*stats, today);
    card_title(sx, Y, fmt(st == 1 ? tx::STREAK_ONE : tx::STREAK_N, {std::to_string(st)}).c_str());
    const char* wd[] = {tx::WD_1, tx::WD_2, tx::WD_3, tx::WD_4, tx::WD_5, tx::WD_6, tx::WD_7};
    long long monday = today - weekday_of(today);
    int dw = (sw - 36) / 7;
    for (int d = 0; d < 7; d++) {
      long long day = monday + d;
      int dx = sx + 18 + d * dw;
      bool did = practiced(*stats, day);
      fl_color(rgb(did ? C_FIRE : day > today ? 0xf1f3f7 : C_LOCK));
      fl_pie(dx + dw / 2 - 14, Y + 44, 28, 28, 0, 360);
      if (day == today) {
        fl_color(rgb(C_TEXT));
        fl_arc(dx + dw / 2 - 16, Y + 42, 32, 32, 0, 360);
      }
      fl_font(FL_HELVETICA_BOLD, 12);
      fl_color(did ? FL_WHITE : rgb(C_MUTED));
      if (did) fl_draw("🔥", dx + dw / 2 - 14, Y + 44, 28, 28, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA, 11);
      fl_color(rgb(C_MUTED));
      fl_draw(wd[d], dx, Y + 76, dw, 16, FL_ALIGN_CENTER);
    }
    Y += 116;
    // El repaso.
    round_box(sx, Y, sw, 100, 16, rgb(C_CARD), rgb(C_LINE));
    card_title(sx, Y, tx::REVIEW_TITLE);
    int due = due_count(*prog, today);
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_MUTED));
    std::string rv = prog->mem.empty() ? tx::REVIEW_NONE : due ? fmt(tx::REVIEW_DUE, {std::to_string(due)}) : tx::REVIEW_OK;
    fl_draw(fit(rv, sw - 36).c_str(), sx + 18, Y + 50);
    if (!prog->mem.empty()) button(sx + 18, Y + 58, sw - 36, 32, tx::REVIEW_BTN, 2, -1, due ? C_GOLD : C_CARD, due ? 0xffffff : C_TEXT,
                                   due ? 0xd48a12 : C_LINE, 14);
    Y += 112;
    // El nivel: A1…C1 y la prueba para saltar.
    round_box(sx, Y, sw, 128, 16, rgb(C_CARD), rgb(C_LINE));
    card_title(sx, Y, tx::YOUR_LEVEL);
    int lv = level_of(*pack, *prog);
    bool full = pack->full;
    fl_color(rgb(SECTION_COLORS[lv]));
    fl_rounded_rectf(sx + 18, Y + 40, 46, 30, 8);
    fl_font(FL_HELVETICA_BOLD, 15);
    fl_color(FL_WHITE);
    fl_draw(section_code(lv), sx + 18, Y + 40, 46, 30, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA_BOLD, 14);
    fl_color(rgb(C_TEXT));
    fl_draw(fit(section_name(lv), sw - 100).c_str(), sx + 74, Y + 61);
    int segs = full ? 5 : 1;
    int sgw = (sw - 36 - (segs - 1) * 4) / segs;
    for (int k = 0; k < segs; k++) {
      fl_color(rgb(k <= lv ? SECTION_COLORS[k] : C_LOCK));
      fl_rounded_rectf(sx + 18 + k * (sgw + 4), Y + 78, sgw, 6, 3);
    }
    button(sx + 18, Y + 90, sw - 36, 30, tx::TEST_BTN, 3, -1, C_CARD, C_ACCENT, C_LINE, 13);
    Y += 140;
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_MUTED));
    fl_draw(fit(fmt(tx::TOTALS, {std::to_string(prog->xp), std::to_string(learned(*prog))}), sw).c_str(), sx + 4, Y + 10);
  }

  // ---- una lección
  int lesson_x() const { return x() + std::max(24, (w() - 780) / 2); }
  int lesson_w() const { return std::min(780, w() - 48); }
  const char* instruction(const Exercise& e) const {
    switch (e.kind) {
      case K_CHOOSE: return tx::I_CHOOSE;
      case K_CHOOSE_REV: return tx::I_CHOOSE_REV;
      case K_BUILD: return tx::I_BUILD;
      case K_MATCH: return tx::I_MATCH;
      case K_TYPE: return tx::I_TYPE;
      case K_LISTEN: return tx::I_LISTEN;
    }
    return "";
  }
  void draw_lesson() {
    if (!ses || !ses->active() || !pack) return;
    const Exercise& e = ses->cur();
    const Item& it = item_at(*pack, e.unit, e.item);
    int X = lesson_x(), W = lesson_w();
    // Arriba: cerrar, la barra de avance y las vidas.
    fl_color(rgb(C_CARD));
    fl_rectf(x(), y(), w(), h());
    bool hot = (int)hits.size() == hover;
    fl_font(FL_HELVETICA_BOLD, 22);
    fl_color(rgb(hot ? C_TEXT : C_MUTED));
    fl_draw("✕", X, y() + 18, 36, 36, FL_ALIGN_CENTER);
    hits.push_back({X, y() + 18, 36, 36, 10, -1});
    int bx = X + 52, bw = W - 52 - 110;
    fl_color(rgb(C_LOCK));
    fl_rounded_rectf(bx, y() + 28, bw, 16, 8);
    double frac = ses->total ? std::min(1.0, ses->answered / (double)ses->total) : 0;
    if (frac > 0) {
      fl_color(rgb(C_GOOD));
      fl_rounded_rectf(bx, y() + 28, std::max(16, (int)(bw * frac)), 16, 8);
      fl_color(rgb(0x6fd39c));
      fl_rounded_rectf(bx + 8, y() + 31, std::max(0, (int)(bw * frac) - 16), 4, 2);
    }
    fl_font(FL_HELVETICA_BOLD, 16);
    std::string right = ses->type == S_LESSON ? "❤️ " + std::to_string(stats ? stats->hearts : 0)
                        : ses->type == S_REVIEW ? std::string(tx::TAG_REVIEW)
                                                : std::string(tx::TAG_TEST);
    fl_color(rgb(ses->type == S_LESSON ? C_HEART : C_ACCENT));
    fl_draw(right.c_str(), X + W - 100, y() + 20, 100, 30, FL_ALIGN_RIGHT);
    if (e.retry) {
      fl_font(FL_HELVETICA_BOLD, 13);
      fl_color(rgb(C_FIRE));
      fl_draw(tx::RETRY_TAG, X, y() + 78);
    }
    // Qué hay que hacer y, con Mini, la frase.
    fl_font(FL_HELVETICA_BOLD, 24);
    fl_color(rgb(C_TEXT));
    fl_draw(instruction(e), X, y() + 108);
    int py = y() + 128;
    bool target_prompt = e.kind == K_CHOOSE_REV || e.kind == K_LISTEN;
    if (e.kind != K_MATCH) mascot(X + 40, py + 44, 34, C_ACCENT, !ses->checked || ses->correct);
    int qx = X + 96, qw = W - 96;
    if (e.kind == K_MATCH) {
      // Parejas: sin frase arriba.
    } else if (e.kind == K_LISTEN) {
      button(qx + 4, py + 16, 160, 56, tx::LISTEN_BTN, 16, -1, C_ACCENT, 0xffffff, C_ACCENT_D, 17);
      button(qx + 180, py + 22, 150, 44, tx::SLOW_BTN, 17, -1, C_CARD, C_ACCENT, C_LINE, 15);
    } else {
      const std::string& q = target_prompt ? it.tgt[0] : it.src[0];
      fl_font(FL_HELVETICA, 20);
      int maxw = qw - 40 - (target_prompt && tts ? 56 : 0);
      auto lines = wrap(q, maxw);
      int tw = 0;
      for (const auto& l : lines) tw = std::max(tw, (int)fl_width(l.c_str()));
      int bh = 28 + (int)lines.size() * 28;
      int bubble_w = tw + 36 + (target_prompt && tts ? 52 : 0);
      round_box(qx, py + 44 - bh / 2, bubble_w, bh, 14, rgb(C_CARD), rgb(C_LINE));
      fl_color(rgb(C_LINE));
      fl_polygon(qx - 10, py + 44, qx + 1, py + 36, qx + 1, py + 52);
      fl_color(rgb(C_CARD));
      fl_polygon(qx - 8, py + 44, qx + 2, py + 37, qx + 2, py + 51);
      fl_color(rgb(C_TEXT));
      for (size_t i = 0; i < lines.size(); i++) fl_draw(lines[i].c_str(), qx + 18, py + 44 - bh / 2 + 34 + (int)i * 28);
      if (target_prompt && tts) {
        int sx = qx + bubble_w - 48;
        fl_font(FL_HELVETICA, 20);
        fl_draw("🔊", sx, py + 44 - 18, 36, 36, FL_ALIGN_CENTER);
        hits.push_back({sx, py + 44 - 18, 36, 36, 16, -1});
      }
    }
    int ay = y() + 250;
    if (e.kind == K_CHOOSE || e.kind == K_CHOOSE_REV) draw_choose(e, X, W, ay);
    else if (e.kind == K_BUILD) draw_build(e, X, W, ay);
    else if (e.kind == K_MATCH) draw_match(e, X, W, y() + 140);
    else {
      entry_x = X;
      entry_y = ay + 10;
      entry_w = W;
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(C_MUTED));
      fl_draw(fmt(tx::TYPE_HINT, {pack->flag + " " + pack->name}).c_str(), X, ay + 84);
    }
    draw_feedback(e, it);
  }
  void option_card(int ox, int oy, int ow, int oh, const std::string& text, int n, int act, bool selected, unsigned state) {
    bool hot = (int)hits.size() == hover && !ses->checked;
    unsigned border = state ? state : selected ? C_ACCENT : C_LINE;
    unsigned fill = state == C_GOOD ? C_GOOD_SOFT : state == C_BAD ? C_BAD_SOFT : selected ? C_SOFT : hot ? 0xf7f8fc : C_CARD;
    fl_color(rgb(border));
    fl_rounded_rectf(ox, oy + 3, ow, oh, 14);
    round_box(ox, oy, ow, oh, 14, rgb(fill), rgb(border));
    if (n > 0) {
      round_box(ox + 14, oy + oh / 2 - 13, 26, 26, 7, rgb(C_CARD), rgb(border));
      fl_font(FL_HELVETICA_BOLD, 13);
      fl_color(rgb(selected ? C_ACCENT : C_MUTED));
      fl_draw(std::to_string(n).c_str(), ox + 14, oy + oh / 2 - 13, 26, 26, FL_ALIGN_CENTER);
    }
    fl_font(FL_HELVETICA, 17);
    fl_color(rgb(C_TEXT));
    int tx0 = ox + (n > 0 ? 52 : 16);
    auto lines = wrap(text, ow - (tx0 - ox) - 12);
    int lh = 22, top = oy + oh / 2 - (int)lines.size() * lh / 2;
    for (size_t i = 0; i < lines.size() && i < 3; i++) fl_draw(lines[i].c_str(), tx0, top + 17 + (int)i * lh);
    hits.push_back({ox, oy, ow, oh + 3, act, n - 1});
  }
  void draw_choose(const Exercise& e, int X, int W, int ay) {
    int cw = (W - 16) / 2, ch = 72;
    for (int i = 0; i < (int)e.options.size(); i++) {
      int ox = X + (i % 2) * (cw + 16), oy = ay + (i / 2) * (ch + 18);
      unsigned state = 0;
      if (ses->checked) {
        if (i == e.answer) state = C_GOOD;
        else if (i == ses->choice) state = C_BAD;
      }
      option_card(ox, oy, cw, ch, e.options[(size_t)i], i + 1, 11, i == ses->choice, state);
    }
  }
  // Una ficha de palabra (si «empty», el hueco que deja al ponerla arriba).
  int tile(int tx0, int ty, const std::string& word, int act, int idx, bool empty) {
    fl_font(FL_HELVETICA, 18);
    int tw = (int)fl_width(word.c_str()) + 30;
    if (empty) {
      fl_color(rgb(C_LOCK));
      fl_rounded_rectf(tx0, ty, tw, 46, 12);
      return tw;
    }
    bool hot = (int)hits.size() == hover && !ses->checked;
    fl_color(rgb(C_LINE));
    fl_rounded_rectf(tx0, ty + 3, tw, 46, 12);
    round_box(tx0, ty, tw, 46, 12, rgb(hot ? 0xf3f5ff : C_CARD), rgb(C_LINE));
    fl_color(rgb(C_TEXT));
    fl_draw(word.c_str(), tx0, ty, tw, 46, FL_ALIGN_CENTER);
    hits.push_back({tx0, ty, tw, 49, act, idx});
    return tw;
  }
  void draw_build(const Exercise& e, int X, int W, int ay) {
    // Las dos líneas de la respuesta.
    fl_color(rgb(C_LINE));
    fl_line_style(FL_SOLID, 2);
    fl_line(X, ay + 56, X + W, ay + 56);
    fl_line(X, ay + 116, X + W, ay + 116);
    fl_line_style(0);
    int tx0 = X, ty = ay + 6;
    for (int k = 0; k < (int)ses->placed.size(); k++) {
      const std::string& wd = e.tiles[(size_t)ses->placed[(size_t)k]];
      fl_font(FL_HELVETICA, 18);
      int tw = (int)fl_width(wd.c_str()) + 30;
      if (tx0 + tw > X + W) {
        tx0 = X;
        ty += 60;
      }
      tx0 += tile(tx0, ty, wd, 13, k, false) + 8;
    }
    // Las fichas de abajo, centradas en filas.
    std::vector<std::vector<int>> rows(1);
    int rw = 0;
    fl_font(FL_HELVETICA, 18);
    for (int i = 0; i < (int)e.tiles.size(); i++) {
      int tw = (int)fl_width(e.tiles[(size_t)i].c_str()) + 30 + 10;
      if (rw + tw > W && !rows.back().empty()) {
        rows.push_back({});
        rw = 0;
      }
      rows.back().push_back(i);
      rw += tw;
    }
    int by = ay + 150;
    for (const auto& row : rows) {
      int total = 0;
      for (int i : row) total += (int)fl_width(e.tiles[(size_t)i].c_str()) + 40;
      int bx = X + (W - total) / 2;
      for (int i : row) {
        bool used = std::find(ses->placed.begin(), ses->placed.end(), i) != ses->placed.end();
        bx += tile(bx, by, e.tiles[(size_t)i], 12, i, used) + 10;
      }
      by += 58;
    }
  }
  void draw_match(const Exercise& e, int X, int W, int ay) {
    int cw = (W - 24) / 2, ch = 58;
    for (int k = 0; k < (int)e.pairs.size(); k++) {
      const Item& li = item_at(*pack, e.pairs[(size_t)k].first, e.pairs[(size_t)k].second);
      bool done = k < (int)ses->matched.size() && ses->matched[(size_t)k];
      unsigned state = done ? C_GOOD : k == ses->wrong_left ? C_BAD : 0;
      option_card(X, ay + k * (ch + 14), cw, ch, li.src[0], 0, done ? 0 : 14, k == ses->match_left, state);
      if (done) hits.back().act = 0;
      hits.back().idx = k;
      int r = e.right_order[(size_t)k];
      const Item& ri = item_at(*pack, e.pairs[(size_t)r].first, e.pairs[(size_t)r].second);
      bool rdone = r < (int)ses->matched.size() && ses->matched[(size_t)r];
      unsigned rstate = rdone ? C_GOOD : r == ses->wrong_right ? C_BAD : 0;
      option_card(X + cw + 24, ay + k * (ch + 14), cw, ch, ri.tgt[0], 0, rdone ? 0 : 15, false, rstate);
      hits.back().idx = r;
    }
  }
  // Abajo, al comprobar: bien (verde) o la solución (rojo).
  void draw_feedback(const Exercise& e, const Item& it) {
    int fy = y() + h() - 108;
    if (!ses->checked) {
      fl_color(rgb(C_LINE));
      fl_line(x(), fy, x() + w(), fy);
      return;
    }
    bool ok = ses->correct;
    fl_color(rgb(ok ? C_GOOD_SOFT : C_BAD_SOFT));
    fl_rectf(x(), fy, w(), h() - (fy - y()));
    int X = lesson_x();
    fl_font(FL_HELVETICA_BOLD, 22);
    fl_color(rgb(ok ? C_GOOD_D : C_BAD));
    std::string title, body;
    std::string sol = e.kind == K_CHOOSE_REV ? it.src[0] : it.tgt[0];
    if (e.kind == K_MATCH) title = ses->match_error ? tx::FB_MATCH_ERR : tx::FB_GOOD;
    else if (!ok) {
      title = tx::FB_WRONG;
      body = e.kind == K_CHOOSE || e.kind == K_CHOOSE_REV ? sol : ses->result.best.empty() ? sol : ses->result.best;
    } else if (ses->result.v == V_TYPO) {
      title = tx::FB_TYPO;
      body = ses->result.best;
    } else if (ses->result.v == V_ACCENT) {
      title = tx::FB_ACCENT;
      body = ses->result.best;
    } else {
      title = tx::FB_GOOD;
      if ((e.kind == K_TYPE || e.kind == K_LISTEN || e.kind == K_BUILD) && !ses->result.best.empty() &&
          norm(ses->result.best, true) != norm(it.tgt[0], true))
        body = fmt(tx::FB_OTHER, {it.tgt[0]});
    }
    fl_draw(((ok ? "✓  " : "✕  ") + title).c_str(), X, fy + 40);
    if (!body.empty()) {
      fl_font(FL_HELVETICA, 17);
      fl_color(rgb(ok ? C_GOOD_D : C_BAD));
      auto lines = wrap(body, lesson_w() - 240);
      for (size_t i = 0; i < lines.size() && i < 2; i++) fl_draw(lines[i].c_str(), X, fy + 68 + (int)i * 22);
    }
  }

  // ---- al terminar
  void stat_box(int bx, int by, int bw, const char* label, const std::string& value, unsigned color) {
    fl_color(rgb(color));
    fl_rounded_rectf(bx, by, bw, 96, 16);
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(FL_WHITE);
    fl_draw(label, bx, by, bw, 30, FL_ALIGN_CENTER);
    round_box(bx + 3, by + 30, bw - 6, 63, 13, rgb(C_CARD), rgb(C_CARD));
    fl_font(FL_HELVETICA_BOLD, 24);
    fl_color(rgb(color));
    fl_draw(value.c_str(), bx, by + 30, bw, 63, FL_ALIGN_CENTER);
  }
  void draw_result() {
    fl_color(rgb(C_CARD));
    fl_rectf(x(), y(), w(), h());
    if (!ses) return;
    int cx = x() + w() / 2;
    mascot(cx, y() + 110, 58, ses->out_of_hearts ? 0x9aa3b5 : C_ACCENT, !ses->out_of_hearts);
    std::string title, sub;
    if (ses->out_of_hearts) {
      title = tx::R_NO_HEARTS;
      sub = fmt(tx::R_NO_HEARTS_SUB, {std::to_string((next_heart_in(*stats, now) + 59) / 60)});
    } else if (ses->type == S_TEST) {
      title = tx::R_TEST;
      sub = ses->passed_units >= (int)pack->units.size()
                ? std::string(tx::R_TEST_ALL)
                : fmt(tx::R_TEST_SUB, {std::to_string(ses->passed_units + 1), pack->units[(size_t)ses->passed_units].title,
                                       section_code(pack->units[(size_t)ses->passed_units].section)});
    } else if (ses->type == S_REVIEW) {
      title = tx::R_REVIEW;
      sub = tx::R_REVIEW_SUB;
    } else {
      title = tx::R_LESSON;
      sub = fmt(tx::R_LESSON_SUB, {pack->units[(size_t)ses->unit].title, std::to_string(ses->lesson + 1), std::to_string(LESSONS)});
    }
    fl_font(FL_HELVETICA_BOLD, 30);
    fl_color(rgb(C_TEXT));
    fl_draw(title.c_str(), x(), y() + 190, w(), 40, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA, 16);
    fl_color(rgb(C_MUTED));
    fl_draw(sub.c_str(), x(), y() + 232, w(), 26, FL_ALIGN_CENTER);
    int bw = 170, gap = 18, bx = cx - (3 * bw + 2 * gap) / 2, by = y() + 280;
    int acc = ses->answered ? (int)std::lround(100.0 * ses->right / ses->answered) : 0;
    stat_box(bx, by, bw, tx::R_XP, "+" + std::to_string(ses->xp_gain), C_GOLD);
    stat_box(bx + bw + gap, by, bw, tx::R_ACCURACY, std::to_string(acc) + "%", C_GOOD);
    stat_box(bx + 2 * (bw + gap), by, bw, tx::R_TIME, clock_text(ses->seconds), C_ACCENT);
    fl_font(FL_HELVETICA_BOLD, 17);
    fl_color(rgb(C_FIRE));
    int st = streak_now(*stats, today);
    if (st > 0) fl_draw(fmt(st == 1 ? tx::STREAK_ONE : tx::STREAK_N, {std::to_string(st)}).c_str(), x(), y() + 400, w(), 30, FL_ALIGN_CENTER);
    if (ses->goal_reached) {
      fl_color(rgb(C_GOOD));
      fl_draw(tx::R_GOAL, x(), y() + 430, w(), 30, FL_ALIGN_CENTER);
    }
  }

  // ---- los idiomas (paquetes)
  void draw_packs() {
    header(true);
    int X = x() + 32, W = w() - 64;
    int Y = y() + 64 + 24 - scroll;
    fl_push_clip(x(), y() + 64, w(), h() - 64);
    fl_font(FL_HELVETICA_BOLD, 26);
    fl_color(rgb(C_TEXT));
    fl_draw(tx::PACKS_TITLE, X, Y + 28);
    fl_font(FL_HELVETICA, 14);
    fl_color(rgb(C_MUTED));
    fl_draw(fit(tx::PACKS_HELP, W - 230).c_str(), X, Y + 54);
    button(X + W - 210, Y + 8, 210, 40, tx::IMPORT_BTN, 33, -1, C_CARD, C_ACCENT, C_LINE, 14);
    Y += 80;
    int cols = std::max(1, (W + 20) / 320), cw = (W - (cols - 1) * 20) / cols, ch = 180;
    for (int i = 0; i < (int)cards.size(); i++) {
      const PackCard& c = cards[(size_t)i];
      int cx = X + (i % cols) * (cw + 20), cy = Y + (i / cols) * (ch + 20);
      round_box(cx, cy, cw, ch, 18, rgb(c.state == 2 ? 0xfbfcff : C_CARD), rgb(c.state == 2 ? C_ACCENT : C_LINE));
      fl_font(FL_HELVETICA, 40);
      fl_draw(c.flag.c_str(), cx + 18, cy + 16, 56, 56, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA_BOLD, 20);
      fl_color(rgb(C_TEXT));
      fl_draw(fit(c.name, cw - 110).c_str(), cx + 88, cy + 42);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(C_MUTED));
      auto lines = wrap(c.info, cw - 106);
      for (size_t k = 0; k < lines.size() && k < 2; k++) fl_draw(lines[k].c_str(), cx + 88, cy + 64 + (int)k * 18);
      int by = cy + ch - 58;
      if (c.state == 2) {
        fl_color(rgb(C_SOFT));
        fl_rounded_rectf(cx + 18, by, 150, 40, 12);
        fl_font(FL_HELVETICA_BOLD, 14);
        fl_color(rgb(C_ACCENT));
        fl_draw(tx::STUDYING, cx + 18, by, 150, 40, FL_ALIGN_CENTER);
      } else if (c.state == 1) {
        button(cx + 18, by, 140, 40, tx::STUDY_BTN, 31, i, C_ACCENT, 0xffffff, C_ACCENT_D, 14);
        button(cx + 170, by, 110, 40, tx::REMOVE_BTN, 32, i, C_CARD, C_MUTED, C_LINE, 14);
      } else {
        button(cx + 18, by, 160, 40, tx::INSTALL_BTN, 30, i, C_GOOD, 0xffffff, C_GOOD_D, 14);
      }
    }
    int rows = ((int)cards.size() + cols - 1) / cols;
    content_h = 104 + rows * (ch + 20);
    fl_pop_clip();
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(C_BG));
    fl_rectf(x(), y(), w(), h());
    entry_w = 0;
    if (mode == M_HOME) draw_home();
    else if (mode == M_LESSON) draw_lesson();
    else if (mode == M_RESULT) draw_result();
    else draw_packs();
    fl_pop_clip();
  }
  int hit_at(int ex, int ey) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (h.act && ex >= h.x && ex < h.x + h.w && ey >= h.y && ey < h.y + h.h) return i;
    }
    return -1;
  }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i != hover) {
          hover = i;
          redraw();
        }
        if (window()) window()->cursor(i >= 0 ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        redraw();
        return 1;
      case FL_PUSH: {
        if (Fl::visible_focus()) Fl::focus(this);
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i >= 0 && on_act) on_act(hits[(size_t)i].act, hits[(size_t)i].idx);
        return 1;
      }
      case FL_FOCUS:
      case FL_UNFOCUS:
        return 1;
      case FL_KEYBOARD:
        return on_key && on_key(Fl::event_key()) ? 1 : 0;
      case FL_MOUSEWHEEL:
        if (mode == M_HOME || mode == M_PACKS) {
          scroll = std::max(0, std::min(scroll + Fl::event_dy() * 40, std::max(0, content_h - (h() - 64))));
          redraw();
        }
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// La barra de menús: la racha y lo que falta para la meta («🔥 4  12/20»).
std::string bar_title(const Stats& s, long long today) {
  int xt = xp_today(s, today);
  return "🔥" + std::to_string(streak_now(s, today)) + (xt >= s.goal ? "  ✓" : "  " + std::to_string(xt) + "/" + std::to_string(s.goal));
}
struct MenuEntry {
  std::string title;
  int tag = 0;
  bool enabled = true, sep = false, checked = false;
};

// ============================================================ las pruebas internas
int selftest() {
  int fails = 0;
  auto chk = [&](bool ok, const char* what) {
    if (fl_getenv("DMS_MINILANG_TRACE")) std::printf("ok? %d %s\n", ok ? 1 : 0, what);
    if (!ok) {
      std::printf("FAIL %s\n", what);
      fails++;
    }
  };
  // Comparar respuestas.
  chk(norm("¿Cómo estás?", false) == "cómo estás" && norm("¿Cómo ESTÁS?", true) == "como estas", "normalizar: signos, mayúsculas y acentos");
  chk(norm("I’m  fine,thanks!", false) == "i'm fine thanks", "normalizar: el apóstrofo y los espacios");
  auto ok1 = alts("I am fine, thanks/I'm fine, thanks");
  chk(ok1.size() == 2 && ok1[1] == "I'm fine, thanks", "las formas que valen");
  chk(check_text("i'm fine thanks", ok1).v == V_OK && check_text("I am fine thanks!", ok1).v == V_OK, "bien, sin signos ni mayúsculas");
  chk(check_text("Helo", alts("Hello/Hi")).v == V_TYPO && check_text("Helo", alts("Hello/Hi")).best == "Hello", "una letra: casi (con la buena)");
  chk(check_text("manana", alts("mañana")).v == V_ACCENT && check_text("Hasta manana", alts("Hasta mañana")).v == V_ACCENT, "sin acentos: casi");
  chk(check_text("Goodbye", alts("Good morning")).v == V_WRONG && check_text("", alts("Hi")).v == V_WRONG, "mal (y vacío)");
  chk(check_text("No", alts("Na")).v == V_WRONG, "palabras cortas: sin margen");
  chk(check_text("I have not finished the report yet", alts("I have not finished the report yet/I haven't finished the report yet")).v == V_OK &&
          check_text("I haven't finished the reprot yet", alts("I have not finished the report yet/I haven't finished the report yet")).v == V_TYPO,
      "frases largas: dos letras de margen");
  auto w = words_of("¿Dónde está la estación?");
  chk(w.size() == 4 && w[0] == "Dónde" && w[3] == "estación", "las fichas: sin signos");
  // Los paquetes.
  Pack en = build_pack("en", "es");
  chk(en.full && en.units.size() == 15 && en.item_count() == 180 && en.units[0].items[0].src[0] == "Hola" &&
          en.units[0].items[0].tgt.size() == 2 && en.units[14].section == 4,
      "el curso de inglés: 15 unidades, 180 frases, de A1 a C1");
  int sections[5] = {0, 0, 0, 0, 0};
  for (const auto& u : en.units) sections[u.section]++;
  chk(sections[0] == 4 && sections[1] == 3 && sections[2] == 3 && sections[3] == 3 && sections[4] == 2, "las unidades de cada nivel");
  Pack es = build_pack("es", "en");
  chk(es.full && es.units.size() == 15 && es.units[0].items[0].src[0] == "Hello" && es.units[0].items[0].tgt[0] == "Hola" &&
          es.units[0].title == "Greetings",
      "al revés: español para quien habla inglés");
  Pack fr = build_pack("fr", "es");
  chk(!fr.full && fr.units.size() == 3 && fr.item_count() == 30 && fr.units[0].items[0].tgt[0] == "Bonjour" && fr.units[0].items[0].src[0] == "Hola",
      "francés: los primeros pasos");
  Pack de = build_pack("de", "en");
  chk(de.units.size() == 3 && de.units[1].items[0].src[0] == "I want water" && de.units[1].items[0].tgt[0] == "Ich möchte Wasser", "alemán desde el inglés");
  chk(in_catalog("it", "es") && in_catalog("pt", "en") && !in_catalog("en", "en") && !in_catalog("es", "fr") && !in_catalog("ja", "es"),
      "el catálogo");
  for (const char* t : {"en", "fr", "it", "de", "pt"}) {
    Pack p = build_pack(t, "es");
    bool fine = !p.units.empty();
    for (const auto& u : p.units)
      for (const auto& it : u.items) fine = fine && !it.src.empty() && !it.tgt.empty();
    chk(fine, "cada idioma: todas las frases con su traducción");
  }
  Pack back;
  std::string error;
  chk(parse_pack(pack_json(en), back, error) && back.id == "en-es" && back.units.size() == 15 && back.item_count() == 180 &&
          back.units[0].items[1].tgt[0] == "Good morning" && back.units[2].icon == en.units[2].icon && back.full,
      "un paquete: a su archivo y de vuelta");
  chk(!parse_pack("{nada", back, error) && error == tx::ERR_PACK_FORMAT, "un archivo roto no se usa");
  chk(!parse_pack("{\"target\":\"es\",\"source\":\"es\",\"units\":[]}", back, error) && error == tx::ERR_PACK_LANG, "el mismo idioma: no");
  chk(!parse_pack("{\"target\":\"ja\",\"source\":\"es\",\"units\":[{\"title\":\"x\",\"items\":[[\"a\",\"b\"]]}]}", back, error) &&
          error == tx::ERR_PACK_EMPTY,
      "unidades con menos de tres frases: no");
  std::string ja = "{\"target\":\"ja\",\"source\":\"es\",\"name\":\"Japonés\",\"flag\":\"🇯🇵\",\"units\":[{\"section\":0,\"title\":\"Saludos\",\"items\":"
                   "[[\"Hola\",\"Konnichiwa\"],[\"Gracias\",\"Arigatou\"],[\"Adiós\",\"Sayounara\"],[\"S\\u00ed\",\"Hai\"]]}]}";
  chk(parse_pack(ja, back, error) && back.id == "ja-es" && back.name == "Japonés" && back.units[0].items[3].src[0] == "Sí" && back.units[0].icon == "📘",
      "un paquete de otro (con \\u y sin icono)");
  // Los juegos.
  bool lessons_ok = true, choose_ok = true, build_ok = true, match_ok = true;
  for (const Pack* p : {&en, &es, &fr}) {
    for (int u = 0; u < (int)p->units.size(); u++)
      for (int k = 0; k < LESSONS; k++) {
        auto ex = make_lesson(*p, u, k, true, (unsigned)(u * 7 + k));
        lessons_ok = lessons_ok && ex.size() == 10;
        for (const auto& e : ex) {
          if (e.kind == K_CHOOSE || e.kind == K_CHOOSE_REV) {
            choose_ok = choose_ok && e.options.size() == 4 && e.answer >= 0 &&
                        e.options[(size_t)e.answer] == (e.kind == K_CHOOSE ? item_at(*p, e.unit, e.item).tgt[0] : item_at(*p, e.unit, e.item).src[0]);
          } else if (e.kind == K_BUILD) {
            auto need = words_of(item_at(*p, e.unit, e.item).tgt[0]);
            auto have = e.tiles;
            for (const auto& n : need) {
              auto f = std::find(have.begin(), have.end(), n);
              build_ok = build_ok && f != have.end();
              if (f != have.end()) have.erase(f);
            }
            build_ok = build_ok && e.tiles.size() > need.size();
          } else if (e.kind == K_MATCH) {
            match_ok = match_ok && e.pairs.size() >= 3 && e.right_order.size() == e.pairs.size();
          }
        }
      }
  }
  chk(lessons_ok, "cada lección: diez juegos");
  chk(choose_ok, "elegir: cuatro respuestas, una buena");
  chk(build_ok, "ordenar: todas las palabras y alguna de más");
  chk(match_ok, "parejas: de tres a cinco");
  auto no_voice = make_lesson(en, 0, 0, false, 3);
  bool no_listen = true;
  for (const auto& e : no_voice) no_listen = no_listen && e.kind != K_LISTEN;
  chk(no_listen, "sin voz, «escucha» pasa a «escribe»");
  // El progreso.
  Progress pr;
  pr.lessons.assign(en.units.size(), 0);
  long long today = days_from_civil(2026, 11, 11);
  chk(today == 20768 && weekday_of(today) == 2, "los días (y el miércoles)");
  remember(pr, 0, 1, true, today);
  remember(pr, 0, 1, true, today);
  chk(pr.mem[mem_key(0, 1)] == std::make_pair(2, today + 2), "recordar: bien, más tarde");
  remember(pr, 0, 1, false, today);
  chk(pr.mem[mem_key(0, 1)] == std::make_pair(0, today), "recordar: mal, hoy otra vez");
  remember(pr, 1, 2, true, today);
  pr.lessons[0] = 3;
  pr.lessons[1] = 1;
  pr.xp = 75;
  Progress pr2 = progress_parse(progress_text(pr), en.units.size());
  chk(pr2.xp == 75 && pr2.lessons[0] == 3 && pr2.lessons[1] == 1 && pr2.mem.size() == 2 && pr2.mem[mem_key(1, 2)].first == 1, "el progreso: guardar y leer");
  chk(current_unit(en, pr2) == 1 && unlocked(pr2, 1) && !unlocked(pr2, 2) && level_of(en, pr2) == 0, "la unidad por la que va (y las cerradas)");
  chk(due_count(pr2, today) == 1 && due_count(pr2, today + 1) == 2, "lo que toca repasar");
  auto rv = make_review(en, pr2, today, false, 5);
  chk(rv.size() == 2 && rv[0].unit == 0 && rv[0].item == 1, "el repaso: primero lo que toca");
  auto test = make_test(en, 9);
  chk(test.size() == 30 && test[0].unit == 0 && test[29].unit == 14, "la prueba de nivel: dos por unidad");
  chk(test_result({{0, true}, {0, true}, {1, true}, {1, true}, {2, true}, {2, false}}) == 2 && test_result({{0, false}}) == 0, "la prueba: hasta el primer fallo");
  // La racha, la meta y las vidas.
  Stats s;
  add_xp(s, 10, today);
  add_xp(s, 5, today);
  chk(s.streak == 1 && xp_today(s, today) == 15 && xp_today(s, today + 1) == 0, "la meta del día");
  add_xp(s, 10, today + 1);
  chk(s.streak == 2 && streak_now(s, today + 2) == 2 && streak_now(s, today + 3) == 0, "la racha (y se pierde sin practicar)");
  add_xp(s, 10, today + 4);
  chk(s.streak == 1 && practiced(s, today) && !practiced(s, today + 2) && s.days.size() == 3, "la racha vuelve a empezar");
  long long t0 = 1794365000;
  s.hearts = HEARTS;
  lose_heart(s, t0);
  lose_heart(s, t0 + 60);
  lose_heart(s, t0 + 120);
  chk(s.hearts == 2 && next_heart_in(s, t0 + 600) == HEART_S - 600, "las vidas: se pierden");
  refill(s, t0 + HEART_S * 2 + 30);
  chk(s.hearts == 4 && next_heart_in(s, t0 + HEART_S * 2 + 30) == HEART_S - 30, "las vidas: vuelven solas");
  refill(s, t0 + HEART_S * 10);
  chk(s.hearts == HEARTS, "las vidas: como mucho cinco");
  s.goal = 30;
  s.pack = "en-es";
  s.voice = false;
  Stats s2 = stats_parse(stats_text(s));
  chk(s2.streak == s.streak && s2.last_day == s.last_day && s2.goal == 30 && s2.pack == "en-es" && !s2.voice && s2.days == s.days && s2.hearts == HEARTS,
      "los ajustes: guardar y leer");
  Stats b;
  b.goal = 20;
  add_xp(b, 12, today);
  b.streak = 4;
  chk(bar_title(b, today) == "🔥4  12/20", "la barra de menús: la racha y la meta");
  add_xp(b, 10, today);
  chk(bar_title(b, today) == "🔥4  ✓", "la barra de menús: meta cumplida");
  bool ok = false;
  Json j = parse_json("{\"a\":[1,true,\"x\\n\\u00e9\"],\"b\":{}}", &ok);
  chk(ok && j["a"].a.size() == 3 && j["a"].a[2].s == "x\né" && j["b"].t == Json::OBJ, "JSON");
  if (!fails) std::printf("selftest ok\n");
  return fails ? 1 : 0;
}

}  // namespace ml

// ============================================================ la barra de menús
// MiniLang vive en la barra de menús de macOS: la racha, la meta y, en su
// menú, la lección siguiente y el repaso.
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsMiniLangTarget", 0);
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
void set(const std::string& title) {
  if (!item()) return;
  Pool pool;
  id b = msg(item(), "button");
  if (b) msg<void, id>(b, "setTitle:", str(title));
}
void menu(const std::vector<ml::MenuEntry>& entries) {
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
    msg<void, BOOL>(it, "setEnabled:", e.enabled ? YES : NO);
    if (e.checked) msg<void, long>(it, "setState:", 1L);
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
void set(const std::string&) {}
void menu(const std::vector<ml::MenuEntry>&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
enum BarAct { B_LESSON = 1, B_REVIEW = 2, B_OPEN = 3, B_QUIT = 9 };

class Form1 : public FormDesign {
public:
  ml::LessonView* view = nullptr;
  ml::Stats stats;
  std::vector<ml::Pack> packs;                     // los instalados
  std::map<std::string, ml::Progress> progs;       // el progreso de cada uno
  int active = -1;
  ml::Session ses;
  bool demo = false, demo_voice = false, in_bar = false, quitting = false;
  long long fixed_now = 0;                         // en la demo, una hora fija
  unsigned seeds = 0;
  std::string message, last_title, last_menu;
  double message_until = 0;
  std::vector<std::string> card_ids;               // las tarjetas de la pantalla de idiomas
  // Para las pruebas: preguntar y elegir un archivo sin ventanas.
  std::function<bool(const std::string&)> confirm = [](const std::string& q) {
    return fl_choice("%s", tx::BTN_NO, tx::BTN_YES, nullptr, q.c_str()) == 1;
  };
  std::function<std::string()> pick_file = [] {
    Fl_Native_File_Chooser ch;
    ch.title(tx::IMPORT_TITLE);
    ch.filter("MiniLang (*.json)\t*.json");
    ch.type(Fl_Native_File_Chooser::BROWSE_FILE);
    if (ch.show() != 0 || !ch.filename()) return std::string();
    return std::string(ch.filename());
  };

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }
  Form1() {
    if (fl_getenv("DMS_MINILANG_SELFTEST")) std::exit(ml::selftest());
    if (fl_getenv("DMS_MINILANG_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_MINILANG_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    Board->color(ml::rgb(ml::C_BG));
    resizable(Board);
    view = new ml::LessonView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    // El campo y el botón, encima del dibujo (los coloca layout()).
    Board->add(Answer);
    Board->add(BtnCheck);
    Answer->textsize(20);
    Answer->box(FL_BORDER_BOX);
    Answer->hide();
    BtnCheck->box(FL_RFLAT_BOX);
    BtnCheck->hide();
    view->on_act = [](int a, int i) { if (self()) self()->act(a, i); };
    view->on_key = [](int k) { return self() && self()->key(k); };
    // Cerrar la ventana la deja en la barra de menús; un cierre desde el código
    // (el menú Idioma de las demos) cierra de verdad.
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (!self()) return;
      if (Fl::event() == FL_CLOSE && bar::available()) self()->to_bar();
      else self()->close_for_good();
    });
  }
  void form_create() override {
    set_fonts();
    setup();
    load();
    if (bar::create()) bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    refresh();
  }
  void form_close() override { save(); }

  // ---- la hora, el paquete y el progreso
  long long now() const { return fixed_now ? fixed_now : ml::wall_s(); }
  long long today() const { return ml::day_of(now()); }
  ml::Pack* pack() { return active >= 0 && active < (int)packs.size() ? &packs[(size_t)active] : nullptr; }
  ml::Progress& prog() {
    static ml::Progress none;
    ml::Pack* p = pack();
    if (!p) return none;
    auto it = progs.find(p->id);
    if (it == progs.end()) {
      std::string text;
      if (!demo) ml::read_file(progress_file(p->id), text);
      it = progs.insert({p->id, ml::progress_parse(text, p->units.size())}).first;
    }
    return it->second;
  }
  bool voice_on() const { return demo ? demo_voice : stats.voice && ml::tts_available(); }
  unsigned seed() { return demo ? 7u + 13u * seeds++ : (unsigned)now() ^ (2654435761u * ++seeds); }
  std::string settings_file() const { return ml::config_dir() + "/minilang.txt"; }
  std::string progress_file(const std::string& id) const { return ml::config_dir() + "/progreso-" + id + ".txt"; }
  void load() {
    std::string text;
    if (!demo && ml::read_file(settings_file(), text)) stats = ml::stats_parse(text);
    load_packs();
    // La primera vez: el idioma del curso completo (inglés, o español si la app está en inglés).
    if (packs.empty()) install(ml::ui_lang() == "es" ? "en" : "es");
    int pick = 0;
    for (int i = 0; i < (int)packs.size(); i++)
      if (packs[(size_t)i].id == stats.pack) pick = i;
    use_pack(pick);
  }
  void load_packs() {
    packs.clear();
    if (demo) return;
    dirent** list = nullptr;
    int n = fl_filename_list(ml::packs_dir().c_str(), &list);
    for (int i = 0; i < n; i++) {
      std::string name = list[i]->d_name;
      if (name.size() < 6 || name.compare(name.size() - 5, 5, ".json") != 0) continue;
      std::string text, error;
      ml::Pack p;
      if (ml::read_file(ml::packs_dir() + "/" + name, text) && ml::parse_pack(text, p, error)) packs.push_back(p);
    }
    if (list) fl_filename_free_list(&list, n);
  }
  void save() {
    if (demo) return;
    fl_make_path(ml::config_dir().c_str());
    ml::write_file(settings_file(), ml::stats_text(stats));
    for (const auto& kv : progs) ml::write_file(progress_file(kv.first), ml::progress_text(kv.second));
  }
  // Instalar un idioma del catálogo: su paquete queda en la carpeta «paquetes».
  bool install(const std::string& target) {
    std::string src = ml::ui_lang();
    if (!ml::in_catalog(target, src)) return false;
    ml::Pack p = ml::build_pack(target, src);
    for (const auto& q : packs)
      if (q.id == p.id) return true;
    if (!demo) {
      fl_make_path(ml::packs_dir().c_str());
      if (!ml::write_file(ml::packs_dir() + "/" + p.id + ".json", ml::pack_json(p))) return false;
    }
    packs.push_back(p);
    return true;
  }
  void use_pack(int i) {
    if (i < 0 || i >= (int)packs.size()) return;
    save();
    active = i;
    stats.pack = packs[(size_t)i].id;
    prog();
    view->scroll = 0;
    save();
  }

  // ---- lo que se ve
  void say(const std::string& m) {
    message = m;
    message_until = ml::now_s() + 5;
    refresh();
  }
  void refresh() {
    ml::refill(stats, now());
    view->pack = pack();
    view->prog = &prog();
    view->stats = &stats;
    view->ses = &ses;
    view->today = today();
    view->now = now();
    view->tts = voice_on();
    if (!message.empty() && ml::now_s() < message_until) Status->text(" " + message);
    else if (ml::Pack* p = pack()) {
      int u = ml::current_unit(*p, prog());
      std::string where = u < (int)p->units.size() ? ml::fmt(tx::STATUS_UNIT, {std::to_string(u + 1), std::to_string(p->units.size()), p->units[(size_t)u].title})
                                                    : std::string(tx::STATUS_DONE);
      Status->text(" " + p->flag + " " + p->name + " · " + where + " · " + ml::bar_title(stats, today()));
    }
    layout();
    view->redraw();
    update_bar();
  }
  // El campo para escribir y el botón de comprobar, donde toca.
  void layout() {
    bool lesson = view->mode == ml::M_LESSON && ses.active();
    bool typing = lesson && (ses.cur().kind == ml::K_TYPE || ses.cur().kind == ml::K_LISTEN);
    if (typing) {
      Answer->resize(view->lesson_x(), view->y() + 260, view->lesson_w(), 60);
      Answer->show();
      if (ses.checked) Answer->deactivate();
      else Answer->activate();
    } else Answer->hide();
    bool button = (lesson && (ses.cur().kind != ml::K_MATCH || ses.checked)) || view->mode == ml::M_RESULT;
    if (button) {
      int bw = 200, bh = 54;
      BtnCheck->resize(view->x() + view->w() - std::max(24, (view->w() - 780) / 2) - bw, view->y() + view->h() - 82, bw, bh);
      bool done = view->mode == ml::M_RESULT || ses.checked;
      BtnCheck->copy_label(done ? tx::CONTINUE : tx::CHECK);
      unsigned c = view->mode == ml::M_RESULT ? ml::C_ACCENT : !ses.checked ? ml::C_ACCENT : ses.correct ? ml::C_GOOD : ml::C_BAD;
      BtnCheck->color(ml::rgb(c));
      BtnCheck->labelcolor(FL_WHITE);
      BtnCheck->labelfont(FL_HELVETICA_BOLD);
      BtnCheck->labelsize(17);
      BtnCheck->show();
    } else BtnCheck->hide();
  }

  // ---- empezar
  void start_lesson(int u) {
    ml::Pack* p = pack();
    if (!p || u < 0 || u >= (int)p->units.size() || !ml::unlocked(prog(), u)) return;
    ml::refill(stats, now());
    if (stats.hearts <= 0) {
      say(ml::fmt(tx::NO_HEARTS, {std::to_string((ml::next_heart_in(stats, now()) + 59) / 60)}));
      return;
    }
    int done = prog().done(u);
    int k = done >= ml::LESSONS ? (int)(seed() % ml::LESSONS) : done;   // una unidad hecha: practicar una cualquiera
    begin(ml::S_LESSON, u, k, ml::make_lesson(*p, u, k, voice_on(), seed()));
  }
  void start_review() {
    ml::Pack* p = pack();
    if (!p) return;
    auto ex = ml::make_review(*p, prog(), today(), voice_on(), seed());
    if (ex.empty()) {
      say(tx::REVIEW_NONE);
      return;
    }
    begin(ml::S_REVIEW, 0, 0, ex);
  }
  void start_test() {
    ml::Pack* p = pack();
    if (!p || !confirm(tx::TEST_Q)) return;
    begin(ml::S_TEST, 0, 0, ml::make_test(*p, seed()));
  }
  void begin(ml::SessionType type, int u, int k, const std::vector<ml::Exercise>& ex) {
    ses = ml::Session();
    ses.type = type;
    ses.unit = u;
    ses.lesson = k;
    ses.queue = ex;
    ses.total = (int)ex.size();
    ses.started = ml::now_s();
    ses.reset_current();
    view->mode = ml::M_LESSON;
    Answer->value("");
    refresh();
    prepare();
  }
  // Al llegar a un juego: la voz (si es de escuchar) y el foco.
  void prepare() {
    if (!ses.active()) return;
    const auto& e = ses.cur();
    if (e.kind == ml::K_LISTEN) speak_current(false);
    if ((e.kind == ml::K_TYPE || e.kind == ml::K_LISTEN) && shown()) Answer->take_focus();
    else if (shown()) Fl::focus(view);
  }
  void speak_current(bool slow) {
    if (!ses.active() || !voice_on() || demo) return;
    ml::Pack* p = pack();
    const auto& it = ml::item_at(*p, ses.cur().unit, ses.cur().item);
    ml::speak(it.tgt[0], p->target, slow);
  }

  // ---- jugar
  void act(int a, int i) {
    switch (a) {
      case 1: start_lesson(i); break;
      case 2: start_review(); break;
      case 3: start_test(); break;
      case 4: open_packs(); break;
      case 10: quit_lesson(); break;
      case 11:
        if (!ses.checked) {
          ses.choice = i;
          refresh();
        }
        break;
      case 12:   // ordenar: una ficha, arriba
        if (!ses.checked && std::find(ses.placed.begin(), ses.placed.end(), i) == ses.placed.end()) {
          ses.placed.push_back(i);
          refresh();
        }
        break;
      case 13:   // y de vuelta abajo
        if (!ses.checked && i >= 0 && i < (int)ses.placed.size()) {
          ses.placed.erase(ses.placed.begin() + i);
          refresh();
        }
        break;
      case 14: match(true, i); break;
      case 15: match(false, i); break;
      case 16: speak_current(false); break;
      case 17: speak_current(true); break;
      case 30: card_install(i); break;
      case 31: card_use(i); break;
      case 32: card_remove(i); break;
      case 33: import_pack(); break;
      case 34:
        view->mode = ml::M_HOME;
        view->scroll = 0;
        refresh();
        break;
    }
  }
  bool key(int k) {
    if (view->mode == ml::M_LESSON && ses.active()) {
      const auto& e = ses.cur();
      if (k == FL_Enter || k == FL_KP_Enter) {
        BtnCheck_click();
        return true;
      }
      if (k == FL_Escape) {
        quit_lesson();
        return true;
      }
      if (!ses.checked && (e.kind == ml::K_CHOOSE || e.kind == ml::K_CHOOSE_REV) && k >= '1' && k < '1' + (int)e.options.size()) {
        ses.choice = k - '1';
        refresh();
        return true;
      }
      if (!ses.checked && e.kind == ml::K_BUILD && k == FL_BackSpace && !ses.placed.empty()) {
        ses.placed.pop_back();
        refresh();
        return true;
      }
    }
    if (view->mode == ml::M_RESULT && (k == FL_Enter || k == FL_KP_Enter)) {
      BtnCheck_click();
      return true;
    }
    return false;
  }
  // Parejas: una de la izquierda y luego la suya de la derecha.
  void match(bool left, int k) {
    if (ses.checked || !ses.active() || k < 0 || k >= (int)ses.matched.size()) return;
    if (left) {
      ses.match_left = k;
      ses.wrong_left = ses.wrong_right = -1;
    } else if (ses.match_left >= 0) {
      if (k == ses.match_left) {
        ses.matched[(size_t)k] = true;
        ses.wrong_left = ses.wrong_right = -1;
        if (voice_on() && !demo) {
          const auto& pr = ses.cur().pairs[(size_t)k];
          ml::speak(ml::item_at(*pack(), pr.first, pr.second).tgt[0], pack()->target, false);
        }
      } else {
        ses.match_error = true;
        ses.wrong_left = ses.match_left;
        ses.wrong_right = k;
      }
      ses.match_left = -1;
      if (std::all_of(ses.matched.begin(), ses.matched.end(), [](bool b) { return b; })) {
        ml::Check c;
        c.v = ml::V_OK;
        answered(true, c);
        return;
      }
    }
    refresh();
  }
  void check() {
    if (!ses.active()) return;
    if (ses.checked) {
      next();
      return;
    }
    const auto& e = ses.cur();
    const auto& it = ml::item_at(*pack(), e.unit, e.item);
    ml::Check c;
    bool ok = false;
    if (e.kind == ml::K_CHOOSE || e.kind == ml::K_CHOOSE_REV) {
      if (ses.choice < 0) {
        say(tx::PICK_ONE);
        return;
      }
      ok = ses.choice == e.answer;
      c.v = ok ? ml::V_OK : ml::V_WRONG;
    } else if (e.kind == ml::K_BUILD) {
      if (ses.placed.empty()) {
        say(tx::PICK_WORDS);
        return;
      }
      std::string s;
      for (int k : ses.placed) s += (s.empty() ? "" : " ") + e.tiles[(size_t)k];
      c = ml::check_text(s, it.tgt);
      ok = c.v == ml::V_OK || c.v == ml::V_ACCENT;   // con fichas no hay erratas: el orden cuenta
      if (!ok) c.v = ml::V_WRONG;
    } else if (e.kind == ml::K_TYPE || e.kind == ml::K_LISTEN) {
      if (ml::trim(Answer->value()).empty()) {
        say(tx::TYPE_SOMETHING);
        return;
      }
      c = ml::check_text(Answer->value(), it.tgt);
      ok = c.v != ml::V_WRONG;
    } else return;
    answered(ok, c);
  }
  void answered(bool ok, const ml::Check& c) {
    ml::Exercise& e = ses.queue[ses.pos];
    ses.checked = true;
    ses.correct = ok;
    ses.result = c;
    if (!e.retry) {
      ses.answered++;
      if (ok) ses.right++;
    }
    ml::remember(prog(), e.unit, e.item, ok, today());
    if (!ok) {
      ses.mistakes++;
      if (ses.type == ml::S_LESSON) ml::lose_heart(stats, now());
      // Lo fallado vuelve al final (una vez).
      if (ses.type != ml::S_TEST && !e.retry) {
        ml::Exercise again = e;
        again.retry = true;
        ses.queue.push_back(again);
      }
    }
    if (ses.type == ml::S_TEST) ses.test_answers.push_back({e.unit, ok});
    // Al acertar, la frase se oye (para ir cogiendo la pronunciación).
    if (ok && voice_on() && !demo && e.kind != ml::K_LISTEN && e.kind != ml::K_MATCH) ml::speak(ml::item_at(*pack(), e.unit, e.item).tgt[0], pack()->target, false);
    refresh();
  }
  void next() {
    ses.pos++;
    if (ses.type == ml::S_TEST && !ses.test_answers.empty() && !ses.test_answers.back().second) {
      finish();   // la prueba de nivel acaba en el primer fallo
      return;
    }
    if (ses.type == ml::S_LESSON && stats.hearts <= 0) {
      ses.out_of_hearts = true;
      finish();
      return;
    }
    if (!ses.active()) {
      finish();
      return;
    }
    ses.reset_current();
    Answer->value("");
    refresh();
    prepare();
  }
  void finish() {
    ml::Pack* p = pack();
    ses.seconds = ml::now_s() - ses.started;
    int before = ml::xp_today(stats, today());
    int xp = 0;
    if (ses.out_of_hearts) xp = 0;
    else if (ses.type == ml::S_LESSON) {
      xp = 10 + (ses.mistakes == 0 ? 5 : 0);
      if (prog().done(ses.unit) == ses.lesson) prog().lessons[(size_t)ses.unit] = ses.lesson + 1;
    } else if (ses.type == ml::S_REVIEW) {
      xp = 5 + (ses.mistakes == 0 ? 3 : 0);
      stats.hearts = std::min(ml::HEARTS, stats.hearts + 1);   // repasar devuelve una vida
    } else {
      int passed = std::min((int)p->units.size(), ml::test_result(ses.test_answers));
      for (int u = 0; u < passed; u++) prog().lessons[(size_t)u] = ml::LESSONS;
      ses.passed_units = passed;
      xp = 5;
    }
    if (xp > 0) {
      ml::add_xp(stats, xp, today());
      prog().xp += xp;
    }
    ses.xp_gain = xp;
    ses.goal_reached = before < stats.goal && ml::xp_today(stats, today()) >= stats.goal;
    view->mode = ml::M_RESULT;
    save();
    refresh();
  }
  void quit_lesson() {
    if (view->mode != ml::M_LESSON) return;
    if (ses.answered > 0 && !confirm(tx::QUIT_Q)) return;
    view->mode = ml::M_HOME;
    save();
    refresh();
  }

  // ---- los idiomas
  void open_packs() {
    build_cards();
    view->mode = ml::M_PACKS;
    view->scroll = 0;
    refresh();
  }
  int pack_index(const std::string& id) const {
    for (int i = 0; i < (int)packs.size(); i++)
      if (packs[(size_t)i].id == id) return i;
    return -1;
  }
  std::string pack_info(const ml::Pack& p, bool catalog) const {
    std::string n = std::to_string(p.units.size()), f = std::to_string(p.item_count());
    if (!catalog) return ml::fmt(tx::PACK_IMPORTED, {n, f});
    return ml::fmt(p.full ? tx::PACK_FULL : tx::PACK_STARTER, {n, f});
  }
  void build_cards() {
    view->cards.clear();
    card_ids.clear();
    std::string src = ml::ui_lang();
    for (const char* code : ml::LANG_ORDER) {
      if (!ml::in_catalog(code, src)) continue;
      ml::Pack p = ml::build_pack(code, src);
      int i = pack_index(p.id);
      view->cards.push_back({p.id, p.flag, p.name, pack_info(p, true), i < 0 ? 0 : i == active ? 2 : 1});
      card_ids.push_back(code);
    }
    for (int i = 0; i < (int)packs.size(); i++) {
      const ml::Pack& p = packs[(size_t)i];
      if (ml::in_catalog(p.target, p.source) && p.source == src) continue;
      view->cards.push_back({p.id, p.flag, p.name, pack_info(p, false), i == active ? 2 : 1});
      card_ids.push_back(p.id);
    }
  }
  std::string card_pack_id(int i) const {
    if (i < 0 || i >= (int)view->cards.size()) return "";
    return view->cards[(size_t)i].id;
  }
  void card_install(int i) {
    if (i < 0 || i >= (int)card_ids.size()) return;
    if (install(card_ids[(size_t)i])) {
      save();
      say(ml::fmt(tx::INSTALLED, {view->cards[(size_t)i].name}));
    }
    build_cards();
    refresh();
  }
  void card_use(int i) {
    int k = pack_index(card_pack_id(i));
    if (k < 0) return;
    use_pack(k);
    view->mode = ml::M_HOME;
    say(ml::fmt(tx::NOW_STUDYING, {packs[(size_t)k].name}));
  }
  void card_remove(int i) {
    int k = pack_index(card_pack_id(i));
    if (k < 0 || packs.size() <= 1) {
      say(tx::KEEP_ONE);
      return;
    }
    if (!confirm(ml::fmt(tx::REMOVE_Q, {packs[(size_t)k].name}))) return;
    if (!demo) std::remove((ml::packs_dir() + "/" + packs[(size_t)k].id + ".json").c_str());
    std::string id = packs[(size_t)k].id;
    bool was = k == active;
    packs.erase(packs.begin() + k);
    if (was) {
      active = -1;
      use_pack(0);
    } else if (active > k) active--;
    build_cards();
    say(tx::REMOVED);
  }
  // Un paquete hecho por otros: un .json con el mismo formato.
  void import_pack() {
    std::string path = pick_file();
    if (path.empty()) return;
    std::string text, error;
    ml::Pack p;
    if (!ml::read_file(path, text) || !ml::parse_pack(text, p, error)) {
      say(ml::fmt(tx::IMPORT_ERR, {error.empty() ? tx::ERR_PACK_FORMAT : error}));
      return;
    }
    int k = pack_index(p.id);
    if (k >= 0 && !confirm(ml::fmt(tx::REPLACE_Q, {p.name}))) return;
    if (!demo) {
      fl_make_path(ml::packs_dir().c_str());
      ml::write_file(ml::packs_dir() + "/" + p.id + ".json", ml::pack_json(p));
    }
    if (k >= 0) packs[(size_t)k] = p;
    else packs.push_back(p);
    progs.erase(p.id);
    build_cards();
    say(ml::fmt(tx::IMPORTED, {p.name, std::to_string(p.item_count())}));
  }

  // ---- la barra de menús
  std::vector<ml::MenuEntry> bar_menu() {
    std::vector<ml::MenuEntry> m;
    ml::Pack* p = pack();
    int u = p ? ml::current_unit(*p, prog()) : 0;
    bool more = p && u < (int)p->units.size();
    m.push_back({more ? ml::fmt(tx::BAR_CONTINUE, {p->units[(size_t)u].title}) : std::string(tx::BAR_ALL_DONE), B_LESSON, more});
    int due = ml::due_count(prog(), today());
    m.push_back({due ? ml::fmt(tx::BAR_REVIEW_N, {std::to_string(due)}) : std::string(tx::BAR_REVIEW), B_REVIEW, !prog().mem.empty()});
    m.push_back({"", 0, true, true});
    int st = ml::streak_now(stats, today());
    m.push_back({ml::fmt(tx::BAR_STATUS, {std::to_string(st), std::to_string(ml::xp_today(stats, today())), std::to_string(stats.goal)}), 0, false});
    m.push_back({ml::fmt(tx::BAR_HEARTS, {std::to_string(stats.hearts)}), 0, false});
    m.push_back({"", 0, true, true});
    m.push_back({tx::BAR_OPEN, B_OPEN});
    m.push_back({tx::BAR_QUIT, B_QUIT});
    return m;
  }
  void update_bar() {
    if (!bar::available()) return;
    std::string t = ml::bar_title(stats, today());
    if (t != last_title) {
      last_title = t;
      bar::set(t);
    }
    auto m = bar_menu();
    std::string sig;
    for (const auto& e : m) sig += e.title + (e.enabled ? "1" : "0") + "\n";
    if (sig != last_menu) {
      last_menu = sig;
      bar::menu(m);
    }
  }
  void bar_act(int t) {
    if (t == B_QUIT) {
      quit();
      return;
    }
    if (in_bar) from_bar();
    if (t == B_LESSON && pack()) start_lesson(ml::current_unit(*pack(), prog()));
    else if (t == B_REVIEW) start_review();
  }
  void to_bar() {
    if (!bar::available()) {
      iconize();
      return;
    }
    if (in_bar) return;
    save();
    in_bar = true;
    hide();
    bar::dock(false);
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

  // ---- eventos del diseño
  void BtnCheck_click() override {
    if (view->mode == ml::M_RESULT) {
      view->mode = ml::M_HOME;
      refresh();
      return;
    }
    check();
  }
  void Answer_enter() override { check(); }
  void Tick_timer() override {
    // Las vidas vuelven y la barra de menús se pone al día (cada medio minuto).
    static double last = 0;
    if (ml::now_s() - last > 30 && view->mode != ml::M_LESSON) {
      last = ml::now_s();
      refresh();
    } else if (!message.empty() && ml::now_s() > message_until) {
      message.clear();
      refresh();
    }
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_LESSON) {
      if (pack()) start_lesson(ml::current_unit(*pack(), prog()));
    } else if (item == tx::MP_REVIEW) start_review();
    else if (item == tx::MP_TEST) start_test();
    else if (item == tx::MP_PACKS) open_packs();
    else if (item == tx::MP_IMPORT) {
      open_packs();
      import_pack();
    } else if (item == tx::MP_BAR) to_bar();
    else if (item == tx::MP_QUIT) quit();
    else if (item == tx::MP_GOAL_10 || item == tx::MP_GOAL_20 || item == tx::MP_GOAL_30 || item == tx::MP_GOAL_50) {
      stats.goal = item == tx::MP_GOAL_10 ? 10 : item == tx::MP_GOAL_20 ? 20 : item == tx::MP_GOAL_30 ? 30 : 50;
      save();
      say(ml::fmt(tx::GOAL_SET, {std::to_string(stats.goal)}));
    } else if (item == tx::MP_VOICE) {
      stats.voice = !stats.voice;
      save();
      say(!ml::tts_available() ? tx::VOICE_NONE : stats.voice ? tx::VOICE_ON : tx::VOICE_OFF);
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
  void demo_state(int W, int H, bool progress) {
    Fl::screen_count();
    demo = true;
    fixed_now = 1794380400;   // un miércoles por la tarde
    setup();
    size(W, H);
    stats = ml::Stats();
    stats.hearts_t = fixed_now;
    load();
    if (progress) {
      // Ya va por la unidad 5 (A2), con racha de seis días y algo de repaso.
      ml::Progress& p = prog();
      for (int u = 0; u < 4; u++) p.lessons[(size_t)u] = ml::LESSONS;
      p.lessons[4] = 1;
      p.xp = 420;
      for (int u = 0; u < 4; u++)
        for (int i = 0; i < 12; i++) p.mem[ml::mem_key(u, i)] = {i % 4 == 0 ? 1 : 3, today() + (i % 5 == 0 ? 0 : 3)};
      for (int d = 5; d >= 1; d--) ml::add_xp(stats, 20, today() - d);
      ml::add_xp(stats, 15, today());
      stats.hearts = 4;
      stats.hearts_t = fixed_now - 600;
    }
    view->mode = ml::M_HOME;
    refresh();
  }
  // El escritorio con la barra de menús y su menú abierto.
  void desk(const std::string& file) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(70 + 40 * t), (uchar)(90 + 40 * t), (uchar)(170 + 50 * t)));
      fl_line(0, yy, W, yy);
    }
    fl_color(ml::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(ml::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    std::string t = ml::bar_title(stats, today());
    fl_font(FL_HELVETICA, 16);
    int iw = (int)fl_width(t.c_str()) + 24, ix = W - 520;
    fl_color(ml::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 12, 5, iw, BarH - 10, 8);
    fl_color(ml::rgb(0x1d1d1f));
    fl_draw(t.c_str(), ix, 26);
    auto m = bar_menu();
    const int rowh = 34, seph = 12;
    int mw = 300, mh = 12;
    for (const auto& e : m) {
      mw = std::max(mw, (int)fl_width(e.title.c_str()) + 50);
      mh += e.sep ? seph : rowh;
    }
    int mx = ix - 12, my = BarH + 4;
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(50 - 4 * k), (uchar)(60 - 4 * k), (uchar)(100 - 4 * k)));
      fl_rounded_rectf(mx - k, my - k + 4, mw + 2 * k, mh + 2 * k, 14 + k);
    }
    ml::round_box(mx, my, mw, mh, 14, ml::rgb(0xf3f3f5), ml::rgb(0xc4c4ca));
    int yy = my + 6;
    for (size_t i = 0; i < m.size(); i++) {
      if (m[i].sep) {
        fl_color(ml::rgb(0xd8d8dc));
        fl_line(mx + 16, yy + seph / 2, mx + mw - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      if (i == 0) {
        fl_color(ml::rgb(0x2f6fea));
        fl_rounded_rectf(mx + 6, yy, mw - 12, rowh, 8);
      }
      fl_color(i == 0 ? FL_WHITE : m[i].enabled ? ml::rgb(0x1d1d1f) : ml::rgb(0x8a8a90));
      fl_draw(m[i].title.c_str(), mx + 22, yy + 23);
      yy += rowh;
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  // Ir hasta el primer juego de un tipo (en la lección de la unidad «u»).
  bool goto_kind(ml::Kind k) {
    while (ses.active() && ses.cur().kind != k) {
      ses.pos++;
      ses.reset_current();
    }
    ses.answered = (int)ses.pos;
    ses.right = (int)ses.pos;
    refresh();
    return ses.active();
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1100, 720, true);
    demo_voice = true;
    refresh();
    render_to(dir + "/home.png");
    start_lesson(4);
    goto_kind(ml::K_CHOOSE);
    ses.choice = ses.cur().answer == 0 ? 1 : 0;
    refresh();
    render_to(dir + "/choose.png");
    begin(ml::S_LESSON, 4, 1, ml::make_lesson(*pack(), 4, 1, true, 11));
    goto_kind(ml::K_BUILD);
    {
      // Las fichas buenas, en orden: comprobada y bien.
      auto need = ml::words_of(ml::item_at(*pack(), ses.cur().unit, ses.cur().item).tgt[0]);
      std::vector<bool> used(ses.cur().tiles.size(), false);
      for (const auto& n : need)
        for (size_t t = 0; t < ses.cur().tiles.size(); t++)
          if (!used[t] && ses.cur().tiles[t] == n) {
            used[t] = true;
            ses.placed.push_back((int)t);
            break;
          }
      check();
    }
    render_to(dir + "/build.png");
    // Las parejas salen en las unidades de frases cortas (aquí, la comida).
    begin(ml::S_LESSON, 2, 1, ml::make_lesson(*pack(), 2, 1, true, 11));
    if (goto_kind(ml::K_MATCH) && ses.matched.size() >= 3) {
      ses.matched[0] = ses.matched[2] = true;
      ses.match_left = 1;
      refresh();
      render_to(dir + "/match.png");
    }
    begin(ml::S_LESSON, 4, 2, ml::make_lesson(*pack(), 4, 2, true, 5));
    if (goto_kind(ml::K_LISTEN)) {
      std::string a = ml::item_at(*pack(), ses.cur().unit, ses.cur().item).tgt[0];
      while (!a.empty() && ((unsigned char)a.back() & 0xC0) == 0x80) a.pop_back();
      if (!a.empty()) a.pop_back();
      Answer->value(a.c_str());
      check();
    }
    render_to(dir + "/listen.png");
    ses = ml::Session();
    ses.type = ml::S_LESSON;
    ses.unit = 4;
    ses.lesson = 1;
    ses.answered = 10;
    ses.right = 9;
    ses.xp_gain = 10;
    ses.seconds = 151;
    ses.goal_reached = true;
    view->mode = ml::M_RESULT;
    refresh();
    render_to(dir + "/result.png");
    install("fr");
    view->mode = ml::M_HOME;
    open_packs();
    render_to(dir + "/packs.png");
    view->mode = ml::M_HOME;
    desk(dir + "/bar.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  // Contestar el juego de ahora, bien o mal, como lo haría alguien.
  void answer_now(bool right) {
    const auto& e = ses.cur();
    const auto& it = ml::item_at(*pack(), e.unit, e.item);
    if (e.kind == ml::K_CHOOSE || e.kind == ml::K_CHOOSE_REV) {
      ses.choice = right ? e.answer : (e.answer + 1) % (int)e.options.size();
    } else if (e.kind == ml::K_BUILD) {
      ses.placed.clear();
      auto need = ml::words_of(it.tgt[0]);
      std::vector<bool> used(e.tiles.size(), false);
      for (const auto& n : need)
        for (size_t t = 0; t < e.tiles.size(); t++)
          if (!used[t] && e.tiles[t] == n) {
            used[t] = true;
            ses.placed.push_back((int)t);
            break;
          }
      if (!right) std::reverse(ses.placed.begin(), ses.placed.end());
      if (!right && ses.placed.size() < 2) ses.placed.clear(), ses.placed.push_back(0);
    } else if (e.kind == ml::K_TYPE || e.kind == ml::K_LISTEN) {
      Answer->value(right ? it.tgt[0].c_str() : "zzz qqq");
    } else if (e.kind == ml::K_MATCH) {
      for (int k = 0; k < (int)e.pairs.size(); k++) {
        match(true, k);
        if (ses.checked) break;
        match(false, k);
      }
      return;
    }
    check();
  }
  int ui_test() {
    demo_state(1100, 720, false);
    int f = 0;
    auto chk = [&](bool ok, const char* what) {
      if (fl_getenv("DMS_MINILANG_TRACE")) std::printf("ok? %d %s\n", ok ? 1 : 0, what);
      if (!ok) {
        std::printf("FAIL %s\n", what);
        f++;
      }
    };
    std::string src = ml::ui_lang(), main_target = src == "es" ? "en" : "es";
    chk(packs.size() == 1 && pack()->id == main_target + "-" + src && pack()->units.size() == 15, "el curso completo, instalado de partida");
    render_to("");
    int starts = 0;
    for (const auto& h : view->hits) starts += h.act == 1 ? 1 : 0;
    chk(starts == 1, "el inicio: solo la primera unidad, abierta");
    // Empezar con un clic de verdad.
    for (const auto& h : view->hits)
      if (h.act == 1) {
        Fl::e_x = h.x + 5;
        Fl::e_y = h.y + 5;
        view->handle(FL_PUSH);
        break;
      }
    chk(view->mode == ml::M_LESSON && ses.total == 10 && ses.cur().kind == ml::K_CHOOSE && BtnCheck->visible(), "empezar la lección 1");
    // Mal: una vida menos y el juego vuelve al final.
    Fl::e_keysym = '0' + 1 + (ses.cur().answer + 1) % 4;
    key(Fl::e_keysym);
    int wrong_choice = ses.choice;
    BtnCheck_click();
    render_to("");
    chk(wrong_choice != ses.cur().answer && ses.checked && !ses.correct && stats.hearts == ml::HEARTS - 1 && ses.queue.size() == 11 &&
            std::string(BtnCheck->label()) == tx::CONTINUE,
        "mal: una vida menos, la solución y vuelve al final");
    BtnCheck_click();
    chk(!ses.checked && ses.pos == 1, "continuar");
    // Bien, con un clic en la respuesta.
    render_to("");
    for (const auto& h : view->hits)
      if (h.act == 11 && h.idx == ses.cur().answer) {
        Fl::e_x = h.x + 10;
        Fl::e_y = h.y + 10;
        view->handle(FL_PUSH);
        break;
      }
    BtnCheck_click();
    chk(ses.correct && ses.right == 1, "bien: con un clic");
    BtnCheck_click();
    // Ordenar: poner y quitar fichas con clics.
    chk(ses.cur().kind == ml::K_BUILD, "el tercero: ordenar");
    render_to("");
    int bank = 0;
    for (const auto& h : view->hits) bank += h.act == 12 ? 1 : 0;
    for (const auto& h : view->hits)
      if (h.act == 12) {
        Fl::e_x = h.x + 5;
        Fl::e_y = h.y + 5;
        view->handle(FL_PUSH);
        break;
      }
    render_to("");
    bool placed_one = ses.placed.size() == 1;
    for (const auto& h : view->hits)
      if (h.act == 13) {
        Fl::e_x = h.x + 5;
        Fl::e_y = h.y + 5;
        view->handle(FL_PUSH);
        break;
      }
    chk(bank == (int)ses.cur().tiles.size() && placed_one && ses.placed.empty(), "ordenar: poner y quitar una ficha");
    answer_now(true);
    chk(ses.correct, "ordenar: bien");
    BtnCheck_click();
    // Parejas: se comprueban solas al terminar.
    chk(ses.cur().kind == ml::K_MATCH && !BtnCheck->visible(), "parejas: sin botón de comprobar");
    match(true, 0);
    match(false, 1 % (int)ses.matched.size());
    bool flagged = ses.match_error && ses.wrong_left == 0;
    answer_now(true);
    chk(flagged && ses.checked && ses.correct && BtnCheck->visible(), "parejas: un fallo marcado y terminadas");
    BtnCheck_click();
    // El resto, bien (y el que volvió al final, también).
    while (ses.active() && view->mode == ml::M_LESSON) {
      bool typing = ses.cur().kind == ml::K_TYPE;
      if (typing) {
        // Escribir con una errata: vale, avisando.
        std::string a = ml::item_at(*pack(), ses.cur().unit, ses.cur().item).tgt[0];
        std::string typo = a;
        if (ml::norm(a, true).size() >= 6 && (unsigned char)a.back() < 0x80 && std::isalpha((unsigned char)a.back())) typo = a.substr(0, a.size() - 1);
        Answer->value(typo.c_str());
        Answer_enter();
        if (!ses.correct) std::printf("typo rejected: %s\n", typo.c_str());
      } else answer_now(true);
      if (!ses.correct) break;
      BtnCheck_click();
    }
    chk(view->mode == ml::M_RESULT && ses.xp_gain == 10 && prog().done(0) == 1 && ml::xp_today(stats, today()) == 10 &&
            ml::streak_now(stats, today()) == 1 && ses.answered == 10 && ses.right == 9,
        "lección terminada: 10 XP, la racha y la siguiente lección");
    render_to("");
    BtnCheck_click();
    chk(view->mode == ml::M_HOME, "continuar: al inicio");
    // Sin vidas no se empieza; vuelven solas.
    stats.hearts = 1;
    stats.hearts_t = now();
    start_lesson(0);
    answer_now(false);
    BtnCheck_click();
    chk(view->mode == ml::M_RESULT && ses.out_of_hearts && ses.xp_gain == 0, "sin vidas: la lección se acaba");
    BtnCheck_click();
    start_lesson(0);
    chk(view->mode == ml::M_HOME && message.find("30") != std::string::npos, "sin vidas no se empieza (y dice cuándo vuelve una)");
    fixed_now += ml::HEART_S + 5;
    refresh();
    chk(stats.hearts == 1, "una vida vuelve a la media hora");
    // El repaso: sin gastar vidas, y devuelve una.
    start_review();
    chk(view->mode == ml::M_LESSON && ses.type == ml::S_REVIEW && ses.total > 0 && ses.total <= 8, "el repaso");
    answer_now(false);
    chk(stats.hearts == 1 && ses.queue.size() == (size_t)ses.total + 1, "en el repaso, fallar no quita vidas");
    BtnCheck_click();
    while (ses.active() && view->mode == ml::M_LESSON) {
      answer_now(true);
      BtnCheck_click();
    }
    chk(view->mode == ml::M_RESULT && stats.hearts == 2 && ses.xp_gain == 5, "repaso hecho: 5 XP y una vida");
    BtnCheck_click();
    // La prueba de nivel: tres unidades bien y luego un fallo.
    bool asked = false;
    confirm = [&asked](const std::string&) {
      asked = true;
      return true;
    };
    start_test();
    int n = 0;
    while (ses.active() && view->mode == ml::M_LESSON) {
      answer_now(n < 6);
      n++;
      BtnCheck_click();
    }
    chk(asked && view->mode == ml::M_RESULT && ses.passed_units == 3 && prog().done(2) == ml::LESSONS && ml::current_unit(*pack(), prog()) == 3,
        "la prueba de nivel: salta a la unidad 4");
    render_to("");
    BtnCheck_click();
    // Salir a medias pregunta.
    start_lesson(3);
    answer_now(true);
    BtnCheck_click();
    confirm = [](const std::string&) { return false; };
    key(FL_Escape);
    bool stayed = view->mode == ml::M_LESSON;
    confirm = [](const std::string&) { return true; };
    key(FL_Escape);
    chk(stayed && view->mode == ml::M_HOME, "salir a medias: pregunta");
    // Los idiomas: instalar, estudiar, volver y quitar.
    open_packs();
    render_to("");
    int fr = -1;
    for (int i = 0; i < (int)view->cards.size(); i++)
      if (view->cards[(size_t)i].id == "fr-" + src) fr = i;
    chk(view->cards.size() == 5 && fr >= 0 && view->cards[(size_t)fr].state == 0, "los idiomas: el catálogo (cinco)");
    act(30, fr);
    chk(packs.size() == 2 && view->cards[(size_t)fr].state == 1, "instalar el francés");
    act(31, fr);
    chk(pack()->id == "fr-" + src && pack()->units.size() == 3 && prog().done(0) == 0 && view->mode == ml::M_HOME, "estudiar francés: su progreso aparte");
    open_packs();
    for (int i = 0; i < (int)view->cards.size(); i++)
      if (view->cards[(size_t)i].id == main_target + "-" + src) act(31, i);
    chk(pack()->id == main_target + "-" + src && ml::current_unit(*pack(), prog()) == 3, "volver: su progreso sigue");
    open_packs();
    act(32, fr);
    chk(packs.size() == 1, "quitar el francés");
    // Importar un paquete (y uno roto).
    fl_make_path(ml::config_dir().c_str());
    std::string good = ml::config_dir() + "/japones.json", bad = ml::config_dir() + "/roto.json";
    ml::write_file(good, "{\"target\":\"ja\",\"source\":\"" + src +
                             "\",\"name\":\"Japonés\",\"flag\":\"🇯🇵\",\"units\":[{\"title\":\"Saludos\",\"items\":[[\"Hola\",\"Konnichiwa\"],[\"Gracias\","
                             "\"Arigatou\"],[\"Adiós\",\"Sayounara\"]]}]}");
    ml::write_file(bad, "{\"target\":");
    pick_file = [bad] { return bad; };
    import_pack();
    bool rejected = packs.size() == 1 && message.find(tx::ERR_PACK_FORMAT) != std::string::npos;
    pick_file = [good] { return good; };
    import_pack();
    chk(rejected && packs.size() == 2 && packs[1].id == "ja-" + src && view->cards.back().name == "Japonés", "importar un paquete (y uno roto no)");
    // La meta del día y la barra de menús.
    Menu1_click(tx::MP_GOAL_30);
    auto m = bar_menu();
    chk(stats.goal == 30 && m.size() == 8 && m[0].tag == B_LESSON && m[0].enabled && m[1].tag == B_REVIEW && !m[3].enabled,
        "la meta y el menú de la barra");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
