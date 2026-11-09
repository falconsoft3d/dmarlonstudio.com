part of 'tk_examples.dart';

// El código en C++ de la consola (tk_showcase_cpp_console.dart): va tal cual
// en Form1.cpp, después de los textos (namespace tx).
const _consoleCode = r'''
// ============================================================ la consola
// Cada pestaña es una shell (zsh, bash o fish; PowerShell en Windows) en su
// propio pseudoterminal. La salida pasa por un filtro que traduce los colores
// ANSI a los de la apariencia elegida y recoge las marcas que deja la shell al
// volver al prompt (el código de salida y la carpeta): así la cola sabe cuándo
// ha terminado una orden para mandar la siguiente.
namespace ct {

inline int clampi(int v, int lo, int hi) { return v < lo ? lo : v > hi ? hi : v; }

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
bool has(const std::string& s, const std::string& p) { return s.find(p) != std::string::npos; }
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}
std::string num(double v, int dec) {
  char b[64];
  std::snprintf(b, sizeof b, "%.*f", dec, v);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}
// «0,4 s», «12 s», «3 min 05 s»
std::string seconds(double s) {
  if (s < 10) return num(s, 1) + " s";
  if (s < 60) return std::to_string((int)s) + " s";
  char b[32];
  std::snprintf(b, sizeof b, "%d min %02d s", (int)s / 60, (int)s % 60);
  return b;
}
std::string base_name(const std::string& p) {
  std::string s = p;
  while (s.size() > 1 && (s.back() == '/' || s.back() == '\\')) s.pop_back();
  size_t k = s.find_last_of("/\\");
  return k == std::string::npos ? s : s.substr(k + 1);
}

// ------------------------------------------------------------ archivos
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_TERM_CONFIG")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\console";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/console";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/console";
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

// ------------------------------------------------------------ las apariencias
// Fondo, texto, cursor, selección y los 16 colores ANSI (los 8 normales y los
// 8 brillantes). El resto de la ventana (pestañas, panel) sale de mezclarlos.
struct Skin {
  const char* name;
  uint32_t bg, fg, cursor, sel;
  uint32_t ansi[16];
};

const Skin SKINS[] = {
    {tx::SK_CLASSIC, 0x000000, 0xc7c7c7, 0xc7c7c7, 0x3a4a6b,
     {0x000000, 0xc91b00, 0x00c200, 0xc7c400, 0x2f5fe0, 0xca30c7, 0x00c5c7, 0xc7c7c7,
      0x686868, 0xff6e67, 0x5ffa68, 0xfffc67, 0x6871ff, 0xff77ff, 0x60fdff, 0xffffff}},
    {tx::SK_SOLAR_DARK, 0x002b36, 0x93a1a1, 0x93a1a1, 0x0d4a5a,
     {0x073642, 0xdc322f, 0x859900, 0xb58900, 0x268bd2, 0xd33682, 0x2aa198, 0xeee8d5,
      0x586e75, 0xcb4b16, 0x9db300, 0xd9a300, 0x5aa9e6, 0x6c71c4, 0x93a1a1, 0xfdf6e3}},
    {tx::SK_SOLAR_LIGHT, 0xfdf6e3, 0x586e75, 0x586e75, 0xe6dfc8,
     {0x073642, 0xdc322f, 0x859900, 0xb58900, 0x268bd2, 0xd33682, 0x2aa198, 0x93a1a1,
      0x002b36, 0xcb4b16, 0x586e75, 0x657b83, 0x839496, 0x6c71c4, 0x93a1a1, 0xeee8d5}},
    {"Dracula", 0x282a36, 0xf8f8f2, 0xf8f8f2, 0x44475a,
     {0x21222c, 0xff5555, 0x50fa7b, 0xf1fa8c, 0xbd93f9, 0xff79c6, 0x8be9fd, 0xf8f8f2,
      0x6272a4, 0xff6e6e, 0x69ff94, 0xffffa5, 0xd6acff, 0xff92df, 0xa4ffff, 0xffffff}},
    {"Nord", 0x2e3440, 0xd8dee9, 0xd8dee9, 0x434c5e,
     {0x3b4252, 0xbf616a, 0xa3be8c, 0xebcb8b, 0x81a1c1, 0xb48ead, 0x88c0d0, 0xe5e9f0,
      0x4c566a, 0xd08770, 0xb5d19f, 0xf0d9a6, 0x9ab8d6, 0xc7a5c1, 0x8fbcbb, 0xeceff4}},
    {"Gruvbox", 0x282828, 0xebdbb2, 0xebdbb2, 0x504945,
     {0x282828, 0xcc241d, 0x98971a, 0xd79921, 0x458588, 0xb16286, 0x689d6a, 0xa89984,
      0x928374, 0xfb4934, 0xb8bb26, 0xfabd2f, 0x83a598, 0xd3869b, 0x8ec07c, 0xebdbb2}},
    {"Monokai", 0x272822, 0xf8f8f2, 0xf8f8f0, 0x49483e,
     {0x272822, 0xf92672, 0xa6e22e, 0xf4bf75, 0x66d9ef, 0xae81ff, 0xa1efe4, 0xf8f8f2,
      0x75715e, 0xff5995, 0xbbf06b, 0xffd28f, 0x8ce4f5, 0xc4a2ff, 0xbff5ec, 0xf9f8f5}},
    {tx::SK_PHOSPHOR, 0x07140a, 0x33ff66, 0x33ff66, 0x16502a,
     {0x07140a, 0x1f9e3f, 0x33ff66, 0x7dff9a, 0x26b34d, 0x4ddb73, 0x66ff99, 0x99ffaa,
      0x145a24, 0x33cc55, 0x66ff88, 0xaaffbb, 0x33ff66, 0x77ff99, 0x99ffbb, 0xccffdd}},
    {tx::SK_AMBER, 0x150d00, 0xffb000, 0xffb000, 0x4d3500,
     {0x150d00, 0xcc7a00, 0xffb000, 0xffc94d, 0xb37b00, 0xe69500, 0xffcc66, 0xffd98a,
      0x664400, 0xe68a00, 0xffbf33, 0xffd480, 0xd99a00, 0xffad33, 0xffdd99, 0xffecc7}},
    {tx::SK_PAPER, 0xffffff, 0x1f2328, 0x1f2328, 0xc8ddff,
     {0x24292e, 0xd73a49, 0x22863a, 0xb08800, 0x0366d6, 0x6f42c1, 0x1b7c83, 0x6a737d,
      0x959da5, 0xcb2431, 0x28a745, 0xdbab09, 0x2188ff, 0x8a63d2, 0x3192aa, 0xd1d5da}},
};
const int SKIN_COUNT = (int)(sizeof SKINS / sizeof SKINS[0]);

inline Fl_Color rgb(uint32_t v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
inline void col(uint32_t v) { fl_color(rgb(v)); }
uint32_t mix(uint32_t a, uint32_t b, double t) {
  auto ch = [&](int s) { return (uint32_t)std::lround(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t) << s; };
  return ch(16) | ch(8) | ch(0);
}
bool is_light(uint32_t c) { return ((c >> 16 & 255) * 299 + (c >> 8 & 255) * 587 + (c & 255) * 114) / 1000 > 140; }
// Los colores de la ventana a partir de los de la apariencia.
uint32_t ui_bar(const Skin& s) { return mix(s.bg, is_light(s.bg) ? 0x000000 : 0xffffff, 0.07); }
uint32_t ui_panel(const Skin& s) { return mix(s.bg, is_light(s.bg) ? 0x000000 : 0xffffff, 0.045); }
uint32_t ui_line(const Skin& s) { return mix(s.bg, s.fg, 0.18); }
uint32_t ui_dim(const Skin& s) { return mix(s.bg, s.fg, 0.55); }
uint32_t ui_accent(const Skin& s) { return s.ansi[4] == s.bg ? s.ansi[12] : (is_light(s.bg) ? s.ansi[4] : s.ansi[12]); }

// ------------------------------------------------------------ el filtro de la salida
// Lo que la shell avisa con una secuencia OSC: 7777 = vuelve al prompt (código
// de salida y carpeta); 7778 = empieza una orden; 0/2 = el título.
struct Mark {
  enum Kind { PROMPT, COMMAND, TITLE } kind;
  std::string a, b;
};

class AnsiFilter {
public:
  const Skin* skin = &SKINS[0];
  bool app_cursor = false;   // ESC[?1h: las flechas mandan ESC O A…

  // Lo que hay que pintar (los colores ya traducidos) y las marcas.
  std::string feed(const char* p, size_t n, std::vector<Mark>& marks) {
    std::string out;
    out.reserve(n + 16);
    for (size_t i = 0; i < n; i++) {
      char c = p[i];
      switch (st) {
        case NORMAL:
          if (c == '\033') { st = ESC; seq = "\033"; }
          else if (c == '\007') { /* campana: nada */ }
          else out += c;
          break;
        case ESC:
          if (c == '[') { st = CSI; seq += c; }
          else if (c == ']') { st = OSC; osc.clear(); }
          else if (c == '(' || c == ')' || c == '#') { st = SKIP1; }
          else if (c == '=' || c == '>') { st = NORMAL; }   // modos del teclado numérico
          else { out += seq; out += c; st = NORMAL; }
          break;
        case CSI:
          seq += c;
          if ((unsigned char)c >= 0x40 && (unsigned char)c <= 0x7e) {
            csi(out);
            st = NORMAL;
          } else if (seq.size() > 80) {
            st = NORMAL;   // roto: se descarta
          }
          break;
        case OSC:
          if (c == '\007') { osc_done(marks); st = NORMAL; }
          else if (c == '\033') st = OSC_ESC;
          else if (osc.size() < 8192) osc += c;
          break;
        case OSC_ESC:
          if (c == '\\') osc_done(marks);
          st = NORMAL;
          break;
        case SKIP1: st = NORMAL; break;
      }
    }
    return out;
  }

  // ESC [ … m con los colores de la apariencia (24 bits).
  std::string sgr(const std::string& params) const {
    std::vector<std::string> ps = split(params, ';');
    std::string out;
    auto add = [&](const std::string& s) { out += (out.empty() ? "" : ";") + s; };
    auto rgb3 = [](uint32_t c) {
      return std::to_string(c >> 16 & 255) + ";" + std::to_string(c >> 8 & 255) + ";" + std::to_string(c & 255);
    };
    for (size_t i = 0; i < ps.size(); i++) {
      int v = ps[i].empty() ? 0 : std::atoi(ps[i].c_str());
      if (v >= 30 && v <= 37) add("38;2;" + rgb3(skin->ansi[v - 30]));
      else if (v >= 90 && v <= 97) add("38;2;" + rgb3(skin->ansi[8 + v - 90]));
      else if (v >= 40 && v <= 47) add("48;2;" + rgb3(skin->ansi[v - 40]));
      else if (v >= 100 && v <= 107) add("48;2;" + rgb3(skin->ansi[8 + v - 100]));
      else if ((v == 38 || v == 48) && i + 2 < ps.size() && ps[i + 1] == "5") {
        int k = std::atoi(ps[i + 2].c_str());
        add(k < 16 ? std::to_string(v) + ";2;" + rgb3(skin->ansi[k]) : std::to_string(v) + ";5;" + ps[i + 2]);
        i += 2;
      } else if ((v == 38 || v == 48) && i + 4 < ps.size() && ps[i + 1] == "2") {
        add(ps[i] + ";2;" + ps[i + 2] + ";" + ps[i + 3] + ";" + ps[i + 4]);
        i += 4;
      } else {
        add(std::to_string(v));
      }
    }
    return "\033[" + out + "m";
  }

private:
  enum State { NORMAL, ESC, CSI, OSC, OSC_ESC, SKIP1 } st = NORMAL;
  std::string seq, osc;

  void csi(std::string& out) {
    char fin = seq.back();
    std::string body = seq.substr(2, seq.size() - 3);
    if (!body.empty() && (body[0] == '?' || body[0] == '>' || body[0] == '=')) {
      // Modos privados: solo interesa el de las flechas; el resto no se pinta.
      if (body == "?1" && fin == 'h') app_cursor = true;
      if (body == "?1" && fin == 'l') app_cursor = false;
      return;
    }
    if (fin == 'm') out += sgr(body);
    else if (fin == 't' || fin == 'q' || fin == 'n' || fin == 'c') return;   // informes y ventana: nada
    else out += seq;
  }
  void osc_done(std::vector<Mark>& marks) {
    size_t semi = osc.find(';');
    std::string code = osc.substr(0, semi), rest = semi == std::string::npos ? "" : osc.substr(semi + 1);
    if (code == "7777") {
      size_t s2 = rest.find(';');
      marks.push_back({Mark::PROMPT, rest.substr(0, s2), s2 == std::string::npos ? "" : rest.substr(s2 + 1)});
    } else if (code == "7778") {
      marks.push_back({Mark::COMMAND, rest, ""});
    } else if (code == "0" || code == "2") {
      marks.push_back({Mark::TITLE, rest, ""});
    }
  }
};

// ------------------------------------------------------------ el teclado
// Lo que manda una tecla a la shell (como un xterm).
std::string key_bytes(int key, int state, const std::string& text, bool app_cursor) {
  bool ctrl = state & FL_CTRL, shift = state & FL_SHIFT;
  const char* cur = app_cursor ? "\033O" : "\033[";
  switch (key) {
    case FL_Enter: case FL_KP_Enter: return "\r";
    case FL_BackSpace: return ctrl ? "\027" : "\177";
    case FL_Tab: return shift ? "\033[Z" : "\t";
    case FL_Escape: return "\033";
    case FL_Up: return std::string(cur) + "A";
    case FL_Down: return std::string(cur) + "B";
    case FL_Right: return std::string(cur) + "C";
    case FL_Left: return std::string(cur) + "D";
    case FL_Home: return "\033[H";
    case FL_End: return "\033[F";
    case FL_Delete: return "\033[3~";
    case FL_Insert: return "\033[2~";
    case FL_Page_Up: return "\033[5~";
    case FL_Page_Down: return "\033[6~";
  }
  if (key >= FL_F + 1 && key <= FL_F + 4) return std::string("\033O") + (char)('P' + key - FL_F - 1);
  if (key >= FL_F + 5 && key <= FL_F + 12) {
    const int codes[] = {15, 17, 18, 19, 20, 21, 23, 24};
    return "\033[" + std::to_string(codes[key - FL_F - 5]) + "~";
  }
  if (ctrl) {
    if (key >= 'a' && key <= 'z') return std::string(1, (char)(key - 'a' + 1));
    if (key == '[') return "\033";
    if (key == ' ' || key == '2') return std::string(1, '\0');
    if (key == '\\') return "\034";
    if (key == ']') return "\035";
  }
  return text;
}

// ------------------------------------------------------------ las órdenes guardadas
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
// Las guardadas que encajan con lo escrito: primero las que empiezan igual,
// después las que lo llevan dentro y al final las que tienen esas letras en
// orden («gp» → «git pull»). Sin nada escrito, todas (las usadas, antes).
std::vector<std::string> match_saved(const std::vector<std::string>& saved, const std::string& typed, size_t max = 12) {
  std::string q = lower(trim(typed));
  std::vector<std::pair<int, std::string>> found;
  for (const auto& c : saved) {
    std::string l = lower(c);
    int score = -1;
    if (q.empty() || starts(l, q)) score = 0;
    else if (has(l, q)) score = 1;
    else {
      size_t k = 0;
      for (char ch : l)
        if (k < q.size() && ch == q[k]) k++;
      if (k == q.size()) score = 2;
    }
    if (score >= 0) found.push_back({score, c});
  }
  std::stable_sort(found.begin(), found.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
  std::vector<std::string> out;
  for (const auto& f : found) {
    if (out.size() >= max) break;
    out.push_back(f.second);
  }
  return out;
}

// Lo que se ha escrito en la línea desde el último Intro (aproximado: la
// terminal no sabe lo que hace la shell con las flechas).
void track_line(std::string& line, int key, int state, const std::string& text) {
  bool ctrl = state & FL_CTRL;
  if (key == FL_Enter || key == FL_KP_Enter || (ctrl && (key == 'c' || key == 'u'))) line.clear();
  else if (key == FL_BackSpace) {
    while (!line.empty()) {
      unsigned char b = (unsigned char)line.back();
      line.pop_back();
      if ((b & 0xc0) != 0x80) break;
    }
  } else if (!ctrl && !text.empty() && (unsigned char)text[0] >= 0x20 && text[0] != 0x7f) {
    line += text;
  }
}

// ------------------------------------------------------------ los atajos
// Un nombre que ejecuta una orden (o varias, o a otros atajos): se convierte en
// una función de la shell, así que se escribe el nombre y se pulsa Intro. Lo
// que se escribe después del nombre llega como $1, $2… ($argv en fish).
struct Shortcut {
  std::string name, cmd;
};

bool valid_shortcut_name(const std::string& n) {
  if (n.empty() || n.size() > 40 || n[0] == '-' || std::isdigit((unsigned char)n[0])) return false;
  for (char c : n)
    if (!(std::isalnum((unsigned char)c) || c == '-' || c == '_' || c == '.')) return false;
  return true;
}

// Las órdenes de un atajo: una por línea (sin las vacías).
std::vector<std::string> shortcut_lines(const std::string& cmd) {
  std::vector<std::string> out;
  for (auto l : split(cmd, '\n')) {
    l = trim(l);
    if (!l.empty()) out.push_back(l);
  }
  return out;
}
// En una sola línea, para las listas: «a ; b».
std::string shortcut_summary(const std::string& cmd) {
  std::string o;
  for (const auto& l : shortcut_lines(cmd)) o += (o.empty() ? "" : " ; ") + l;
  return o;
}

// El archivo de funciones para cada shell («sh» vale para zsh y bash): cada
// orden del atajo en su línea, una detrás de otra.
std::string shortcuts_script(const std::string& kind, const std::vector<Shortcut>& list) {
  std::string o = "# DMarlon Console: los atajos (no lo edite: se rehace)\n";
  for (const auto& s : list) {
    auto lines = shortcut_lines(s.cmd);
    if (!valid_shortcut_name(s.name) || lines.empty()) continue;
    std::string body;
    for (const auto& l : lines) body += "  " + l + "\n";
    if (kind == "fish") o += "function " + s.name + "\n" + body + "end\n";
    else if (kind == "ps1") o += "function global:" + s.name + " {\n" + body + "}\n";
    else o += s.name + "() {\n" + body + "}\n";
  }
  return o;
}

// Una línea del historial de la shell: zsh la guarda como «: 1700000000:0;orden».
std::string history_line(const std::string& l) {
  if (starts(l, ": ")) {
    size_t semi = l.find(';');
    return semi == std::string::npos ? "" : trim(l.substr(semi + 1));
  }
  if (starts(l, "#")) return "";   // las marcas de tiempo de bash
  return trim(l);
}

// ------------------------------------------------------------ la shell
// Qué shell abrir y cómo: con un añadido que manda la marca 7777 (código de
// salida y carpeta) cada vez que vuelve al prompt y la 7778 al empezar una
// orden. Se carga la configuración del usuario (sus alias, su prompt) y
// después la marca.
struct ShellCmd {
  std::vector<std::string> argv, env;   // env: «CLAVE=valor»
  bool marks = false;                    // si avisa al terminar cada orden
  std::string name;
};

#ifndef _WIN32
std::string user_shell() {
  if (const char* s = fl_getenv("DMS_TERM_SHELL")) return s;
  if (const char* s = fl_getenv("SHELL"))
    if (*s) return s;
  if (struct passwd* pw = getpwuid(getuid()))
    if (pw->pw_shell && *pw->pw_shell) return pw->pw_shell;
#ifdef __APPLE__
  return "/bin/zsh";
#else
  return "/bin/bash";
#endif
}

const char* const ZSH_WRAP[][2] = {
    {".zshenv", "_dms_zd=$ZDOTDIR\nZDOTDIR=$HOME\n[ -f \"$HOME/.zshenv\" ] && . \"$HOME/.zshenv\"\nZDOTDIR=$_dms_zd\n"},
    {".zprofile", "_dms_zd=$ZDOTDIR\nZDOTDIR=$HOME\n[ -f \"$HOME/.zprofile\" ] && . \"$HOME/.zprofile\"\nZDOTDIR=$_dms_zd\n"},
    {".zshrc",
     "ZDOTDIR=$HOME\n[ -f \"$HOME/.zshrc\" ] && . \"$HOME/.zshrc\"\n"
     "_dms_precmd() { local s=$?; [ -f \"$DMS_SHORTCUTS\" ] && . \"$DMS_SHORTCUTS\"; printf '\\033]7777;%s;%s\\007' \"$s\" \"$PWD\"; return $s; }\n"
     "_dms_preexec() { printf '\\033]7778;%s\\007' \"$1\"; }\n"
     "precmd_functions=(_dms_precmd $precmd_functions)\n"
     "preexec_functions+=(_dms_preexec)\n"},
};
// Resaltar la orden mientras se escribe (como zsh-syntax-highlighting): la
// primera palabra en verde si existe (orden, alias, función, atajo) y en rojo si
// no. Si ya está zsh-syntax-highlighting, no se toca.
const char* const ZSH_HL = R"ZSH(
if [[ -z $ZSH_HIGHLIGHT_VERSION ]] && autoload -Uz add-zle-hook-widget 2>/dev/null; then
  _dms_hl() {
    # Las marcas de antes (zsh mueve sus posiciones al escribir): fuera por su forma.
    region_highlight=("${(@)region_highlight:#<-> <-> fg=(red|green)}")
    local -a words=(${(z)BUFFER})
    local w=$words[1] s=${#${BUFFER%%[^[:space:]]*}}
    [[ -z $w ]] && return
    local c=red
    if whence -- "$w" >/dev/null 2>&1 || [[ -x $w ]]; then c=green; fi
    region_highlight+=("$s $((s + ${#w})) fg=$c")
  }
  add-zle-hook-widget line-pre-redraw _dms_hl
fi
)ZSH";

const char* const BASH_RC =
    "[ -f /etc/profile ] && . /etc/profile\n"
    "for f in \"$HOME/.bash_profile\" \"$HOME/.bash_login\" \"$HOME/.profile\"; do [ -f \"$f\" ] && { . \"$f\"; break; }; done\n"
    "[ -f \"$HOME/.bashrc\" ] && . \"$HOME/.bashrc\"\n"
    "_dms_pc() { local s=$?; [ -f \"$DMS_SHORTCUTS\" ] && . \"$DMS_SHORTCUTS\"; printf '\\033]7777;%s;%s\\007' \"$s\" \"$PWD\"; return $s; }\n"
    "PROMPT_COMMAND=\"_dms_pc${PROMPT_COMMAND:+;$PROMPT_COMMAND}\"\n";
const char* const FISH_INIT =
    "function _dms_p --on-event fish_prompt; set -l s $status; test -f \"$DMS_SHORTCUTS_FISH\"; and source \"$DMS_SHORTCUTS_FISH\"; printf '\\e]7777;%s;%s\\a' $s $PWD; end; "
    "function _dms_x --on-event fish_preexec; printf '\\e]7778;%s\\a' \"$argv\"; end";

ShellCmd shell_command() {
  ShellCmd c;
  std::string sh = user_shell(), name = base_name(sh);
  c.name = name;
  std::string dir = config_dir() + "/shell";
  fl_make_path(dir.c_str());
  if (name == "zsh") {
    fl_make_path((dir + "/zsh").c_str());
    for (const auto& f : ZSH_WRAP)
      write_file(dir + "/zsh/" + f[0], std::string(f[1]) + (std::string(f[0]) == ".zshrc" ? ZSH_HL : ""));
    c.argv = {sh, "-l"};
    c.env.push_back("ZDOTDIR=" + dir + "/zsh");
    c.marks = true;
  } else if (name == "bash") {
    write_file(dir + "/bashrc", BASH_RC);
    c.argv = {sh, "--rcfile", dir + "/bashrc", "-i"};
    c.marks = true;
  } else if (name == "fish") {
    c.argv = {sh, "-l", "--init-command", FISH_INIT};
    c.marks = true;
  } else {
    c.argv = {sh, "-l"};
  }
  // Los atajos: las shells los vuelven a leer cada vez que vuelven al prompt.
  c.env.push_back("DMS_SHORTCUTS=" + dir + "/shortcuts.sh");
  c.env.push_back("DMS_SHORTCUTS_FISH=" + dir + "/shortcuts.fish");
  c.env.push_back("TERM=xterm-256color");
  c.env.push_back("COLORTERM=truecolor");
  c.env.push_back("TERM_PROGRAM=DMarlonConsole");
  // Abierta desde el Finder, la app no trae idioma: sin él, zsh pinta mal los acentos.
  const char* lang = fl_getenv("LANG");
  if (!lang || !*lang) c.env.push_back(std::string("LANG=") + tx::POSIX_LOCALE);
  return c;
}

// ------------------------------------------------------------ el pseudoterminal (macOS y Linux)
struct Pty {
  int fd = -1;
  pid_t pid = -1;

  bool start(const ShellCmd& c, int cols, int rows, const std::string& cwd) {
    int m = posix_openpt(O_RDWR | O_NOCTTY);
    if (m < 0) return false;
    if (grantpt(m) != 0 || unlockpt(m) != 0) { close(m); return false; }
    const char* sname = ptsname(m);
    if (!sname) { close(m); return false; }
    std::string slave = sname;
    // Todo lo que necesita el hijo, preparado antes de fork().
    std::vector<char*> argv;
    for (const auto& a : c.argv) argv.push_back(const_cast<char*>(a.c_str()));
    argv.push_back(nullptr);
    winsize ws{};
    ws.ws_col = (unsigned short)std::max(cols, 20);
    ws.ws_row = (unsigned short)std::max(rows, 5);
    pid_t p = fork();
    if (p < 0) { close(m); return false; }
    if (p == 0) {
      setsid();
      int s = open(slave.c_str(), O_RDWR);
      if (s < 0) _exit(127);
#ifdef TIOCSCTTY
      ioctl(s, TIOCSCTTY, 0);
#endif
      ioctl(s, TIOCSWINSZ, &ws);
      dup2(s, 0);
      dup2(s, 1);
      dup2(s, 2);
      if (s > 2) close(s);
      close(m);
      for (const auto& e : c.env) putenv(const_cast<char*>(e.c_str()));
      if (!cwd.empty() && chdir(cwd.c_str()) != 0) {
        if (const char* h = getenv("HOME")) (void)chdir(h);
      }
      execvp(argv[0], argv.data());
      _exit(127);
    }
    fd = m;
    pid = p;
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
    ioctl(fd, TIOCSWINSZ, &ws);
    return true;
  }
  // Lo que haya (sin esperar): >0 bytes, 0 nada, -1 se acabó.
  long read_some(char* buf, size_t n) {
    long r = (long)::read(fd, buf, n);
    if (r > 0) return r;
    if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)) return 0;
    return -1;
  }
  void write_all(const std::string& s) {
    size_t off = 0;
    double end = now_s() + 2;
    while (off < s.size() && now_s() < end) {
      long w = (long)::write(fd, s.data() + off, s.size() - off);
      if (w > 0) off += (size_t)w;
      else if (w < 0 && errno != EAGAIN && errno != EINTR) break;
    }
  }
  void resize(int cols, int rows) {
    if (fd < 0) return;
    winsize ws{};
    ws.ws_col = (unsigned short)std::max(cols, 20);
    ws.ws_row = (unsigned short)std::max(rows, 5);
    ioctl(fd, TIOCSWINSZ, &ws);
  }
  // Primero se cierra el pseudoterminal: en macOS, una shell que sale espera a
  // que alguien lea lo que le queda por escribir, y sin lector se quedaría
  // colgada (ni SIGKILL la saca). Después se espera un poco, sin bloquear.
  void stop() {
    if (fd >= 0) { close(fd); fd = -1; }
    if (pid <= 0) return;
    int st;
    auto gone = [&](int tries) {
      for (int i = 0; i < tries; i++) {
        if (waitpid(pid, &st, WNOHANG) != 0) return true;
        usleep(10000);
      }
      return false;
    };
    kill(pid, SIGHUP);
    if (!gone(50)) {
      kill(pid, SIGKILL);
      gone(50);
    }
    pid = -1;
  }
};
#else
// ------------------------------------------------------------ el pseudoterminal (Windows: ConPTY)
typedef HRESULT(WINAPI* CreatePC)(COORD, HANDLE, HANDLE, DWORD, void**);
typedef HRESULT(WINAPI* ResizePC)(void*, COORD);
typedef void(WINAPI* ClosePC)(void*);
#ifndef PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE
#define PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE 0x00020016
#endif

std::wstring wide(const std::string& s) {
  unsigned n = fl_utf8towc(s.c_str(), (unsigned)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  fl_utf8towc(s.c_str(), (unsigned)s.size(), &w[0], n + 1);
  return w;
}

ShellCmd shell_command() {
  ShellCmd c;
  c.name = "PowerShell";
  c.argv = {"powershell.exe", "-NoLogo", "-NoExit", "-Command",
            "function global:prompt { $c = if ($?) { 0 } elseif ($LASTEXITCODE) { $LASTEXITCODE } else { 1 }; "
            "$f = \"" + config_dir() + "\\shell\\shortcuts.ps1\"; if (Test-Path $f) { . $f }; "
            "\"$([char]27)]7777;$c;$($PWD.Path)$([char]7)PS $($PWD.Path)> \" }"};
  c.marks = true;
  return c;
}

struct Pty {
  HANDLE in_w = nullptr, out_r = nullptr, proc = nullptr;
  void* pc = nullptr;
  int fd = -1;   // sin uso en Windows (la lectura va en un hilo)
  std::function<void(std::string)> on_data;   // desde el hilo de lectura
  std::function<void()> on_end;

  bool start(const ShellCmd& c, int cols, int rows, const std::string& cwd) {
    HMODULE k = GetModuleHandleW(L"kernel32.dll");
    auto create = (CreatePC)GetProcAddress(k, "CreatePseudoConsole");
    if (!create) return false;   // Windows 10 1809 o posterior
    HANDLE in_r, out_w;
    if (!CreatePipe(&in_r, &in_w, nullptr, 0) || !CreatePipe(&out_r, &out_w, nullptr, 0)) return false;
    COORD size{(SHORT)std::max(cols, 20), (SHORT)std::max(rows, 5)};
    if (create(size, in_r, out_w, 0, &pc) != S_OK) return false;
    CloseHandle(in_r);
    CloseHandle(out_w);
    STARTUPINFOEXW si{};
    si.StartupInfo.cb = sizeof si;
    SIZE_T bytes = 0;
    InitializeProcThreadAttributeList(nullptr, 1, 0, &bytes);
    si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, bytes);
    InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &bytes);
    UpdateProcThreadAttribute(si.lpAttributeList, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, pc, sizeof(pc), nullptr, nullptr);
    std::string line;
    for (const auto& a : c.argv) {
      bool q = a.find(' ') != std::string::npos;
      std::string esc;
      for (char ch : a) esc += ch == '"' ? std::string("\\\"") : std::string(1, ch);
      line += (line.empty() ? "" : " ") + (q ? "\"" + esc + "\"" : esc);
    }
    std::wstring wl = wide(line), wd = wide(cwd);
    PROCESS_INFORMATION pi{};
    BOOL ok = CreateProcessW(nullptr, &wl[0], nullptr, nullptr, FALSE, EXTENDED_STARTUPINFO_PRESENT, nullptr,
                             cwd.empty() ? nullptr : wd.c_str(), &si.StartupInfo, &pi);
    DeleteProcThreadAttributeList(si.lpAttributeList);
    HeapFree(GetProcessHeap(), 0, si.lpAttributeList);
    if (!ok) return false;
    proc = pi.hProcess;
    CloseHandle(pi.hThread);
    HANDLE r = out_r;
    std::thread([this, r] {
      char buf[16384];
      DWORD n = 0;
      while (ReadFile(r, buf, sizeof buf, &n, nullptr) && n > 0)
        if (on_data) on_data(std::string(buf, n));
      if (on_end) on_end();
    }).detach();
    return true;
  }
  long read_some(char*, size_t) { return 0; }
  void write_all(const std::string& s) {
    DWORD w = 0;
    if (in_w) WriteFile(in_w, s.data(), (DWORD)s.size(), &w, nullptr);
  }
  void resize(int cols, int rows) {
    auto rs = (ResizePC)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "ResizePseudoConsole");
    if (rs && pc) rs(pc, COORD{(SHORT)std::max(cols, 20), (SHORT)std::max(rows, 5)});
  }
  void stop() {
    auto cl = (ClosePC)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "ClosePseudoConsole");
    if (proc) { TerminateProcess(proc, 0); CloseHandle(proc); proc = nullptr; }
    if (cl && pc) { cl(pc); pc = nullptr; }
    if (in_w) { CloseHandle(in_w); in_w = nullptr; }
  }
};
#endif

// ------------------------------------------------------------ la cola de órdenes
// Las órdenes esperan su turno: se manda una cuando la shell vuelve al prompt
// (la marca 7777) y se apunta su código de salida y lo que ha tardado.
struct Job {
  enum State { WAITING, RUNNING, OK, FAILED, SKIPPED } state = WAITING;
  std::string cmd;
  int code = 0;
  double start = 0, secs = 0;
};

class Queue {
public:
  std::vector<Job> jobs;
  bool running = false, stop_on_fail = true;
  int current = -1;
  std::function<void(const std::string&)> send;   // manda una línea a la shell
  std::function<void(const std::string&)> notice; // un aviso para la barra de estado

  void add(const std::string& cmd) {
    std::string c = trim(cmd);
    if (c.empty()) return;
    Job j;
    j.cmd = c;
    jobs.push_back(j);
  }
  int waiting() const {
    int n = 0;
    for (const auto& j : jobs) n += j.state == Job::WAITING;
    return n;
  }
  bool busy() const { return current >= 0; }
  // Empieza (o sigue): si la shell está libre, manda la primera que espera.
  void run(bool idle) {
    if (!waiting()) return;
    running = true;
    if (idle && current < 0) next();
  }
  // La shell ha vuelto al prompt con este código de salida.
  void prompt(int code) {
    if (current >= 0) {
      Job& j = jobs[(size_t)current];
      j.code = code;
      j.secs = now_s() - j.start;
      j.state = code == 0 ? Job::OK : Job::FAILED;
      current = -1;
      if (j.state == Job::FAILED && stop_on_fail) {
        running = false;
        if (notice) notice(fmt(tx::Q_STOPPED_FAIL, {j.cmd, std::to_string(code)}));
        return;
      }
    }
    if (running) next();
  }
  void stop() { running = false; }
  void clear() {
    std::vector<Job> keep;
    for (const auto& j : jobs)
      if (j.state == Job::RUNNING) keep.push_back(j);
    jobs = keep;
    current = jobs.empty() ? -1 : 0;
    if (jobs.empty()) running = false;
  }
  void remove(size_t i) {
    if (i >= jobs.size() || jobs[i].state == Job::RUNNING) return;
    jobs.erase(jobs.begin() + (long)i);
    if (current > (int)i) current--;
  }

private:
  void next() {
    for (size_t i = 0; i < jobs.size(); i++) {
      if (jobs[i].state != Job::WAITING) continue;
      jobs[i].state = Job::RUNNING;
      jobs[i].start = now_s();
      current = (int)i;
      if (send) send(jobs[i].cmd + "\r");
      return;
    }
    running = false;
    if (notice) notice(tx::Q_DONE);
  }
};

// ------------------------------------------------------------ una pestaña
class Session;

// La terminal de FLTK, con el teclado y el pegado hacia la shell.
class TermView : public Fl_Terminal {
public:
  Session* session = nullptr;
  std::string line;                        // lo escrito desde el último Intro
  std::function<void(TermView*)> on_complete;   // Ctrl+Espacio
  std::function<void(TermView*)> on_history;    // «history» + Intro
  std::function<void(TermView*)> on_help;       // «ayuda» (o «help») + Intro
  std::function<void(const std::string&)> on_enter;   // una línea escrita y enviada
  TermView(int X, int Y, int W, int H) : Fl_Terminal(X, Y, W, H) {
    output_translate(Fl_Terminal::OFF);
    history_lines(5000);
    box(FL_FLAT_BOX);
    scrollbar_size(10);
  }
  int handle(int e) override;
  void resize(int X, int Y, int W, int H) override;
  // Dónde está el cursor, en píxeles (para abrir la lista a su lado).
  void cursor_xy(int& X, int& Y, int& lh) {
    fl_font(textfont(), textsize());
    lh = fl_height();
    X = x() + margin_left() + Fl::box_dx(box()) + (int)(cursor_col() * fl_width("M"));
    Y = y() + margin_top() + Fl::box_dy(box()) + cursor_row() * lh;
  }
  // El texto seleccionado (vacío si no hay).
  std::string selected() const {
    const char* t = selection_text();
    std::string s = t ? t : "";
    if (t) free((void*)t);
    return s;
  }
};

class Session {
public:
  int id = 0;
  TermView* view = nullptr;
  Pty pty;
  AnsiFilter filter;
  Queue queue;
  ShellCmd shell;
  bool alive = false, idle = false, sample = false;
  std::string cwd, title, running_cmd;
  std::string raw;   // lo último que ha escrito la shell (para repintar con otra apariencia)
  int last_code = 0;
  std::function<void()> changed;   // el título, la cola o el estado han cambiado
  std::function<void(const std::string&)> on_command;   // la shell empieza una orden (para el historial)

  ~Session() { close(); }

  bool start(const std::string& dir) {
    shell = shell_command();
    queue.send = [this](const std::string& s) { write(s); };
    int cols = view->display_columns(), rows = view->display_rows();
#ifdef _WIN32
    pty.on_data = [this](std::string d) {
      auto* box = new std::pair<int, std::string>(id, std::move(d));
      Fl::awake(win_data, box);
    };
    pty.on_end = [this] { Fl::awake(win_end, new int(id)); };
#endif
    alive = pty.start(shell, cols, rows, dir);
    if (!alive) {
      view->append(fmt(tx::ERR_SHELL, {shell.argv.empty() ? "?" : shell.argv[0]}).c_str());
      return false;
    }
#ifndef _WIN32
    Fl::add_fd(pty.fd, FL_READ, fd_ready, this);
#endif
    cwd = dir;
    return true;
  }
  void close() {
#ifndef _WIN32
    if (pty.fd >= 0) Fl::remove_fd(pty.fd);
#endif
    pty.stop();
    alive = false;
  }
  void write(const std::string& s) {
    if (alive) pty.write_all(s);
  }
  // Lee lo que haya; devuelve false si la shell ha terminado.
  bool pump() {
    if (!alive) return false;
    char buf[65536];
    for (int k = 0; k < 64; k++) {
      long n = pty.read_some(buf, sizeof buf);
      if (n > 0) output(buf, (size_t)n);
      else if (n == 0) break;
      else { ended(); return false; }
    }
    return true;
  }
  // La salida de la shell: se pinta y se miran sus marcas.
  void output(const char* p, size_t n) {
    raw.append(p, n);
    if (raw.size() > 262144) {
      size_t cut = raw.find('\n', raw.size() - 196608);
      raw.erase(0, cut == std::string::npos ? raw.size() - 196608 : cut + 1);
    }
    std::vector<Mark> marks;
    std::string out = filter.feed(p, n, marks);
    if (!out.empty()) view->append(out.c_str(), (int)out.size());
    for (const auto& m : marks) {
      if (m.kind == Mark::PROMPT) {
        last_code = std::atoi(m.a.c_str());
        if (!m.b.empty()) cwd = m.b;
        running_cmd.clear();
        idle = true;
        queue.prompt(last_code);
        if (queue.busy()) { idle = false; running_cmd = queue.jobs[(size_t)queue.current].cmd; }
      } else if (m.kind == Mark::COMMAND) {
        idle = false;
        running_cmd = m.a;
        if (on_command) on_command(m.a);
      } else {
        title = m.a;
      }
    }
    if (!marks.empty() && changed) changed();
  }
  // Vuelve a pintar lo escrito con la apariencia de ahora (sin repetir las marcas).
  void repaint() {
    AnsiFilter f;
    f.skin = filter.skin;
    std::vector<Mark> ignored;
    std::string out = f.feed(raw.data(), raw.size(), ignored);
    if (!out.empty()) view->append(out.c_str(), (int)out.size());
  }
  void ended() {
#ifndef _WIN32
    if (pty.fd >= 0) Fl::remove_fd(pty.fd);
#endif
    alive = false;
    view->append((std::string("\r\n\033[2m") + tx::ENDED + "\033[0m\r\n").c_str());
    queue.stop();
    if (changed) changed();
  }
  void run_queue() {
    queue.run(idle);
    if (queue.busy()) { idle = false; running_cmd = queue.jobs[(size_t)queue.current].cmd; }
    if (changed) changed();
  }
  void stop_queue() {
    queue.stop();
    if (queue.busy()) write("\003");   // Ctrl+C a la que está en marcha
    if (changed) changed();
  }
  // El nombre de la pestaña: la orden en marcha, el título o la carpeta.
  std::string tab_title() const {
    if (!running_cmd.empty()) return running_cmd;
    if (!title.empty()) return title;
    if (cwd.empty()) return shell.name.empty() ? std::string(tx::APP) : shell.name;
    const char* h = fl_getenv("HOME");
    if (h && cwd == h) return "~";
    return base_name(cwd);
  }

#ifndef _WIN32
  static void fd_ready(FL_SOCKET, void* p) { static_cast<Session*>(p)->pump(); }
#else
  static std::vector<Session*>& all() {
    static std::vector<Session*> v;
    return v;
  }
  static Session* by_id(int id) {
    for (auto* s : all())
      if (s->id == id) return s;
    return nullptr;
  }
  static void win_data(void* p) {
    auto* box = static_cast<std::pair<int, std::string>*>(p);
    if (Session* s = by_id(box->first)) s->output(box->second.data(), box->second.size());
    delete box;
  }
  static void win_end(void* p) {
    int* id = static_cast<int*>(p);
    if (Session* s = by_id(*id)) s->ended();
    delete id;
  }
#endif
};

int TermView::handle(int e) {
  switch (e) {
    case FL_FOCUS:
    case FL_UNFOCUS: return 1;
    case FL_PUSH:
      take_focus();
      break;
    case FL_KEYBOARD: {
      int key = Fl::event_key(), st = Fl::event_state();
#ifdef __APPLE__
      if (st & FL_META) return 0;   // ⌘: para el menú
#else
      if ((st & FL_CTRL) && (st & FL_SHIFT)) return 0;   // Ctrl+Mayús: para el menú
#endif
      std::string text = Fl::event_text() ? Fl::event_text() : "";
      if ((st & FL_CTRL) && key == ' ') {   // las órdenes guardadas
        if (on_complete) on_complete(this);
        return 1;
      }
      // «ayuda» + Intro: la ayuda de la consola, en la propia terminal.
      std::string word = trim(line);
      if ((key == FL_Enter || key == FL_KP_Enter) && (word == "ayuda" || word == tx::HELP_WORD) && on_help && session) {
#ifdef _WIN32
        session->write("\033");
#else
        session->write("\025");
#endif
        line.clear();
        on_help(this);
        return 1;
      }
      // «history» + Intro: las últimas órdenes, para elegir una.
      if ((key == FL_Enter || key == FL_KP_Enter) && word == "history" && on_history && session) {
#ifdef _WIN32
        session->write("\033");
#else
        session->write("\025");
#endif
        line.clear();
        on_history(this);
        return 1;
      }
      std::string b = key_bytes(key, st, text, session && session->filter.app_cursor);
      if (b.empty() || !session) return 0;
      if ((key == FL_Enter || key == FL_KP_Enter) && on_enter && !trim(line).empty()) on_enter(trim(line));
      track_line(line, key, st, text);
      session->write(b);
      return 1;
    }
    case FL_PASTE:
      if (session && Fl::event_text()) session->write(std::string(Fl::event_text(), (size_t)Fl::event_length()));
      return 1;
  }
  return Fl_Terminal::handle(e);
}

void TermView::resize(int X, int Y, int W, int H) {
  Fl_Terminal::resize(X, Y, W, H);
  if (session) session->pty.resize(display_columns(), display_rows());
}

// ------------------------------------------------------------ la barra de pestañas
class TabBar : public Fl_Widget {
public:
  std::vector<Session*>* tabs = nullptr;
  int active = 0;
  const Skin* skin = &SKINS[0];
  std::vector<std::pair<int, int>> spans;   // x y ancho de cada pestaña
  std::function<void(int)> on_pick, on_close;
  std::function<void()> on_new;
  int plus_x = 0;

  TabBar(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void draw() override {
    const Skin& s = *skin;
    col(ui_bar(s));
    fl_rectf(x(), y(), w(), h());
    col(ui_line(s));
    fl_xyline(x(), y() + h() - 1, x() + w());
    spans.clear();
    int n = tabs ? (int)tabs->size() : 0;
    int tw = n ? std::min(220, std::max(110, (w() - 50) / std::max(n, 1))) : 0;
    int tx0 = x() + 8;
    for (int i = 0; i < n; i++) {
      Session* t = (*tabs)[(size_t)i];
      int X = tx0 + i * (tw + 4), Y = y() + 5, H = h() - 5;
      bool on = i == active;
      if (on) {
        fl_draw_box(FL_RFLAT_BOX, X, Y, tw, H + 6, rgb(s.bg));
        col(ui_accent(s));
        fl_rectf(X + 10, Y, tw - 20, 2);
      }
      fl_font(on ? FL_HELVETICA_BOLD : FL_HELVETICA, 12);
      col(on ? s.fg : ui_dim(s));
      std::string label = std::to_string(i + 1) + "  " + t->tab_title();
      // Recortar al ancho.
      while (label.size() > 3 && fl_width(label.c_str()) > tw - 40) {
        do label.pop_back(); while (!label.empty() && ((uint8_t)label.back() & 0xc0) == 0x80);
      }
      fl_draw(label.c_str(), X + 12, Y + H / 2 + 5);
      // Un punto mientras trabaja; × para cerrar.
      if (!t->idle && t->alive && !t->running_cmd.empty()) {
        col(ui_accent(s));
        fl_pie(X + tw - 34, Y + H / 2 - 3, 7, 7, 0, 360);
      }
      col(ui_dim(s));
      fl_font(FL_HELVETICA, 14);
      fl_draw("×", X + tw - 20, Y + H / 2 + 6);
      spans.push_back({X, tw});
    }
    plus_x = tx0 + n * (tw + 4) + 4;
    col(ui_dim(s));
    fl_font(FL_HELVETICA_BOLD, 18);
    fl_draw("+", plus_x + 6, y() + h() / 2 + 7);
  }
  int handle(int e) override {
    if (e != FL_PUSH) return e == FL_ENTER || e == FL_MOVE ? 1 : 0;
    int px = Fl::event_x();
    for (size_t i = 0; i < spans.size(); i++) {
      auto [X, W] = spans[i];
      if (px >= X && px < X + W) {
        bool close = px >= X + W - 26 || Fl::event_button() == FL_MIDDLE_MOUSE;
        if (close) { if (on_close) on_close((int)i); }
        else if (on_pick) on_pick((int)i);
        return 1;
      }
    }
    if (px >= plus_x && px < plus_x + 30 && on_new) on_new();
    return 1;
  }
};

// ------------------------------------------------------------ el panel de la cola
class QueueView : public Fl_Widget {
public:
  Queue* queue = nullptr;
  const Skin* skin = &SKINS[0];
  std::vector<std::pair<int, size_t>> removes;   // y de cada «×» y su orden
  std::function<void(size_t)> on_remove;
  int scroll = 0;

  QueueView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  void draw() override {
    const Skin& s = *skin;
    col(ui_panel(s));
    fl_rectf(x(), y(), w(), h());
    removes.clear();
    fl_push_clip(x(), y(), w(), h());
    if (!queue || queue->jobs.empty()) {
      fl_font(FL_HELVETICA, 12);
      col(ui_dim(s));
      int yy = y() + 22;
      for (const auto& line : split(tx::Q_EMPTY, '\n')) {
        fl_draw(line.c_str(), x() + 8, yy);
        yy += 17;
      }
      fl_pop_clip();
      return;
    }
    int yy = y() + 6 - scroll;
    for (size_t i = 0; i < queue->jobs.size(); i++) {
      const Job& j = queue->jobs[i];
      uint32_t c = j.state == Job::OK ? s.ansi[10] : j.state == Job::FAILED ? s.ansi[9] : j.state == Job::RUNNING ? ui_accent(s) : ui_dim(s);
      const char* icon = j.state == Job::OK ? "✓" : j.state == Job::FAILED ? "✗" : j.state == Job::RUNNING ? "▶" : j.state == Job::SKIPPED ? "–" : "•";
      if (j.state == Job::RUNNING) {
        col(mix(ui_panel(s), ui_accent(s), 0.18));
        fl_rectf(x(), yy - 2, w(), 42);
      }
      fl_font(FL_HELVETICA_BOLD, 14);
      col(c);
      fl_draw(icon, x() + 8, yy + 16);
      fl_font(FL_COURIER, 12);
      col(s.fg);
      std::string cmd = j.cmd;
      while (cmd.size() > 3 && fl_width(cmd.c_str()) > w() - 52) {
        do cmd.pop_back(); while (!cmd.empty() && ((uint8_t)cmd.back() & 0xc0) == 0x80);
      }
      fl_draw(cmd.c_str(), x() + 28, yy + 15);
      fl_font(FL_HELVETICA, 11);
      col(ui_dim(s));
      std::string sub = j.state == Job::WAITING ? tx::Q_WAITING
                        : j.state == Job::RUNNING ? fmt(tx::Q_RUNNING, {seconds(now_s() - j.start)})
                        : j.state == Job::OK ? fmt(tx::Q_OK, {seconds(j.secs)})
                        : j.state == Job::FAILED ? fmt(tx::Q_FAILED, {std::to_string(j.code), seconds(j.secs)})
                        : tx::Q_SKIPPED;
      fl_draw(sub.c_str(), x() + 28, yy + 31);
      if (j.state != Job::RUNNING) {
        fl_font(FL_HELVETICA, 14);
        fl_draw("×", x() + w() - 18, yy + 17);
        removes.push_back({yy, i});
      }
      yy += 44;
    }
    fl_pop_clip();
  }
  int handle(int e) override {
    if (e == FL_MOUSEWHEEL) {
      int total = queue ? (int)queue->jobs.size() * 44 : 0;
      scroll = clampi(scroll + Fl::event_dy() * 20, 0, std::max(0, total - h() + 10));
      redraw();
      return 1;
    }
    if (e != FL_PUSH) return e == FL_ENTER ? 1 : 0;
    int px = Fl::event_x(), py = Fl::event_y();
    if (px < x() + w() - 26) return 1;
    for (const auto& r : removes)
      if (py >= r.first && py < r.first + 24 && on_remove) { on_remove(r.second); return 1; }
    return 1;
  }
};

// ------------------------------------------------------------ la lista (órdenes guardadas, atajos e historial)
// Se abre junto al cursor: con Ctrl+Espacio, las órdenes guardadas y los atajos;
// al escribir «history», las últimas órdenes. Lo escrito la filtra, ↑ ↓ eligen,
// Intro escribe la orden en la línea (sin ejecutarla), Supr la quita y Esc
// cierra. Con las guardadas, si lo escrito no está, la última fila lo guarda.
struct Entry {
  enum Kind { SAVED, SHORTCUT, HISTORY } kind;
  std::string text, note;   // lo que se escribe y, en los atajos, su orden
};

class Completer : public Fl_Widget {
public:
  std::vector<Entry> all;
  const Skin* skin = &SKINS[0];
  std::string filter, title;
  std::vector<Entry> shown;
  bool can_save = true, offer_save = false;
  int sel = 0;
  std::function<void(const std::string&)> on_pick, on_save;
  std::function<void(const Entry&)> on_forget;
  std::function<void()> on_close;

  Completer() : Fl_Widget(0, 0, 460, 100) {}

  void open(const std::string& head, const std::vector<Entry>& entries, bool saving, const std::string& typed, int X, int Y, int maxW, int maxH) {
    title = head;
    all = entries;
    can_save = saving;
    filter = typed;
    sel = 0;
    refilter();
    int H = height();
    position(std::max(4, std::min(X, maxW - w() - 4)), Y + H < maxH ? Y : std::max(4, Y - H - 24));
    show();
    take_focus();
    redraw();
  }
  void refilter() {
    std::vector<std::string> keys;
    for (const auto& e : all) keys.push_back(e.text);
    shown.clear();
    for (const auto& k : match_saved(keys, filter, 12))
      for (const auto& e : all)
        if (e.text == k) { shown.push_back(e); break; }
    std::string t = trim(filter);
    offer_save = can_save && !t.empty() && std::find(keys.begin(), keys.end(), t) == keys.end();
    sel = clampi(sel, 0, std::max(0, rows() - 1));
    size(520, height());
    if (parent()) parent()->redraw();
  }
  int rows() const { return (int)shown.size() + (offer_save ? 1 : 0); }
  int height() const { return 58 + std::max(1, rows()) * 24; }
  void close() {
    hide();
    if (parent()) parent()->redraw();
    if (on_close) on_close();
  }
  void choose() {
    if (offer_save && sel == (int)shown.size()) {
      if (on_save) on_save(trim(filter));
      Entry e{Entry::SAVED, trim(filter), ""};
      all.insert(all.begin(), e);
      refilter();
      redraw();
      return;
    }
    if (sel >= 0 && sel < (int)shown.size()) {
      std::string c = shown[(size_t)sel].text;
      hide();
      if (parent()) parent()->redraw();
      if (on_pick) on_pick(c);
    }
  }
  void forget() {
    if (sel < 0 || sel >= (int)shown.size()) return;
    Entry e = shown[(size_t)sel];
    if (on_forget) on_forget(e);
    all.erase(std::remove_if(all.begin(), all.end(), [&](const Entry& x) { return x.kind == e.kind && x.text == e.text; }), all.end());
    refilter();
  }

  void draw() override {
    const Skin& s = *skin;
    uint32_t bg = mix(s.bg, is_light(s.bg) ? 0x000000 : 0xffffff, 0.09), line = ui_line(s);
    fl_draw_box(FL_RFLAT_BOX, x() + 3, y() + 4, w(), h(), rgb(mix(s.bg, 0x000000, 0.35)));
    fl_draw_box(FL_RFLAT_BOX, x(), y(), w(), h(), rgb(bg));
    col(line);
    fl_rect(x(), y(), w(), h());
    fl_font(FL_HELVETICA_BOLD, 12);
    col(s.fg);
    std::string head = title;
    if (!filter.empty()) head += "  ·  " + fmt(tx::C_FILTER, {filter});
    fl_draw(head.c_str(), x() + 12, y() + 19);
    int yy = y() + 30;
    if (rows() == 0) {
      fl_font(FL_HELVETICA, 12);
      col(ui_dim(s));
      fl_draw(can_save ? tx::C_EMPTY : tx::H_EMPTY, x() + 12, yy + 16);
    }
    auto cut = [&](std::string c, int maxw) {
      while (c.size() > 3 && fl_width(c.c_str()) > maxw) {
        do c.pop_back(); while (!c.empty() && ((uint8_t)c.back() & 0xc0) == 0x80);
      }
      return c;
    };
    for (int r = 0; r < rows(); r++) {
      if (r == sel) {
        col(mix(bg, ui_accent(s), 0.35));
        fl_rectf(x() + 4, yy, w() - 8, 24);
      }
      if (offer_save && r == (int)shown.size()) {
        fl_font(FL_HELVETICA_BOLD, 12);
        col(ui_accent(s));
        fl_draw(("+  " + fmt(tx::C_SAVE, {trim(filter)})).c_str(), x() + 12, yy + 16);
      } else {
        const Entry& e = shown[(size_t)r];
        fl_font(e.kind == Entry::SHORTCUT ? FL_COURIER_BOLD : FL_COURIER, 13);
        col(e.kind == Entry::SHORTCUT ? ui_accent(s) : s.fg);
        std::string t = cut(e.text, w() - 30);
        fl_draw(t.c_str(), x() + 14, yy + 16);
        if (e.kind == Entry::SHORTCUT) {
          int tw = (int)fl_width(t.c_str());
          fl_font(FL_COURIER, 12);
          col(ui_dim(s));
          std::string n = cut("→ " + shortcut_summary(e.note), w() - 50 - tw);
          fl_draw(n.c_str(), x() + 26 + tw, yy + 16);
        }
      }
      yy += 24;
    }
    fl_font(FL_HELVETICA, 11);
    col(ui_dim(s));
    fl_draw(tx::C_HINT, x() + 12, y() + h() - 9);
  }
  int handle(int e) override {
    switch (e) {
      case FL_FOCUS: return 1;
      case FL_UNFOCUS:
        if (visible()) close();
        return 1;
      case FL_PUSH: {
        int r = (Fl::event_y() - y() - 30) / 24;
        if (r >= 0 && r < rows()) { sel = r; choose(); }
        return 1;
      }
      case FL_KEYBOARD: {
        int k = Fl::event_key();
        std::string t = Fl::event_text() ? Fl::event_text() : "";
        if (k == FL_Escape) close();
        else if (k == FL_Up) sel = (sel + rows() - 1) % std::max(1, rows());
        else if (k == FL_Down || k == FL_Tab) sel = (sel + 1) % std::max(1, rows());
        else if (k == FL_Enter || k == FL_KP_Enter) choose();
        else if (k == FL_Delete) forget();
        else if (k == FL_BackSpace) {
          track_line(filter, k, 0, "");
          refilter();
        } else if (!t.empty() && (unsigned char)t[0] >= 0x20 && !(Fl::event_state() & (FL_CTRL | FL_META))) {
          filter += t;
          sel = 0;
          refilter();
        } else return 1;
        redraw();
        return 1;
      }
    }
    return Fl_Widget::handle(e);
  }
};

// ------------------------------------------------------------ ejemplo
// Lo que se ve en las capturas: una shell inventada (no la de este equipo).
const char* const SAMPLE_MAIN =
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~/proyectos/tienda\033[0m % \033[32mgit\033[0m status\r\n"
    "On branch \033[1;36mmain\033[0m\r\n"
    "Your branch is up to date with '\033[31morigin/main\033[0m'.\r\n\r\n"
    "Changes not staged for commit:\r\n"
    "  \033[31mmodified:   src/carrito.js\033[0m\r\n"
    "  \033[31mmodified:   src/pago.js\033[0m\r\n\r\n"
    "Untracked files:\r\n"
    "  \033[31mtests/envio.test.js\033[0m\r\n\r\n"
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~/proyectos/tienda\033[0m % \033[32mls\033[0m\r\n"
    "\033[1;34mnode_modules\033[0m  \033[1;34mpublic\033[0m  \033[1;34msrc\033[0m  \033[1;34mtests\033[0m  "
    "package.json  README.md  \033[32mdeploy.sh\033[0m  vite.config.js\r\n"
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~/proyectos/tienda\033[0m % \033[32mnpm\033[0m test\r\n\r\n"
    "> tienda@1.4.0 test\r\n> vitest run\r\n\r\n"
    " \033[32m✓\033[0m tests/carrito.test.js \033[2m(12 tests)\033[0m \033[33m38ms\033[0m\r\n"
    " \033[32m✓\033[0m tests/pago.test.js \033[2m(8 tests)\033[0m \033[33m21ms\033[0m\r\n"
    " \033[31m✗\033[0m tests/envio.test.js \033[2m>\033[0m calcula el envío gratis\r\n"
    "   \033[31mAssertionError: expected 4.95 to be 0\033[0m\r\n\r\n"
    " \033[2mTest Files\033[0m  \033[1;31m1 failed\033[0m | \033[1;32m2 passed\033[0m (3)\r\n"
    " \033[2m     Tests\033[0m  \033[1;31m1 failed\033[0m | \033[1;32m27 passed\033[0m (28)\r\n"
    " \033[2m  Duration\033[0m  2.41s\r\n\r\n"
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~/proyectos/tienda\033[0m % ";
const char* const SAMPLE_DEV =
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~/proyectos/tienda\033[0m % \033[32mnpm\033[0m run dev\r\n\r\n"
    "> tienda@1.4.0 dev\r\n> vite\r\n\r\n"
    "  \033[1;32mVITE v6.2.0\033[0m  ready in \033[1m312 ms\033[0m\r\n\r\n"
    "  \033[32m➜\033[0m  \033[1mLocal\033[0m:   \033[36mhttp://localhost:\033[1m5173\033[0;36m/\033[0m\r\n"
    "  \033[32m➜\033[0m  \033[2mNetwork: use --host to expose\033[0m\r\n\r\n"
    "\033[2m17:04:12\033[0m \033[1;36m[vite]\033[0m \033[32mhmr update\033[0m \033[2m/src/carrito.js\033[0m\r\n"
    "\033[2m17:04:31\033[0m \033[1;36m[vite]\033[0m \033[32mhmr update\033[0m \033[2m/src/pago.js\033[0m\r\n";
const char* const SAMPLE_HOME =
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~\033[0m % \033[32mping\033[0m -c 3 dmarlonstudio.com\r\n"
    "PING dmarlonstudio.com (76.76.21.21): 56 data bytes\r\n"
    "64 bytes from 76.76.21.21: icmp_seq=0 ttl=57 time=\033[1m14.2\033[0m ms\r\n"
    "64 bytes from 76.76.21.21: icmp_seq=1 ttl=57 time=\033[1m13.8\033[0m ms\r\n"
    "64 bytes from 76.76.21.21: icmp_seq=2 ttl=57 time=\033[1m15.1\033[0m ms\r\n\r\n"
    "--- dmarlonstudio.com ping statistics ---\r\n"
    "3 packets transmitted, 3 packets received, \033[32m0.0% packet loss\033[0m\r\n"
    "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~\033[0m % ";

// ------------------------------------------------------------ pruebas internas
int fails = 0;
void check(bool ok, const char* what) {
  if (!ok) { std::printf("FAIL %s\n", what); fails++; }
}

int selftest() {
  AnsiFilter f;
  f.skin = &SKINS[3];   // Dracula
  std::vector<Mark> m;
  // Los colores ANSI pasan a los de la apariencia.
  check(f.feed("\033[31mrojo\033[0m", 13, m) == "\033[38;2;255;85;85mrojo\033[0m", "sgr red");
  check(f.sgr("1;32") == "\033[1;38;2;80;250;123m", "sgr bold green");
  check(f.sgr("38;5;9") == "\033[38;2;255;110;110m", "sgr 256 low");
  check(f.sgr("38;5;200") == "\033[38;5;200m", "sgr 256 high");
  check(f.sgr("48;2;1;2;3") == "\033[48;2;1;2;3m", "sgr rgb kept");
  check(f.sgr("") == "\033[0m", "sgr reset");
  // Las marcas de la shell no se pintan y se recogen.
  std::string in = "hola\033]7777;0;/Users/ana\007\033]7778;npm test\007\033]0;mi título\033\\fin";
  std::string out = f.feed(in.data(), in.size(), m);
  check(out == "holafin", "osc stripped");
  check(m.size() == 3 && m[0].kind == Mark::PROMPT && m[0].a == "0" && m[0].b == "/Users/ana", "prompt mark");
  check(m[1].kind == Mark::COMMAND && m[1].a == "npm test" && m[2].kind == Mark::TITLE && m[2].a == "mi título", "command and title marks");
  // Las marcas partidas en dos lecturas.
  m.clear();
  std::string a = "x\033]7777;1;/tm", b = "p\007y";
  out = f.feed(a.data(), a.size(), m) + f.feed(b.data(), b.size(), m);
  check(out == "xy" && m.size() == 1 && m[0].a == "1" && m[0].b == "/tmp", "split mark");
  // Los modos privados no se pintan; el de las flechas se apunta.
  m.clear();
  std::string p = "\033[?2004h\033[?1h\033=ok\033[?25l";
  check(f.feed(p.data(), p.size(), m) == "ok" && f.app_cursor, "private modes");
  // El teclado.
  check(key_bytes(FL_Enter, 0, "\r", false) == "\r", "key enter");
  check(key_bytes(FL_Up, 0, "", false) == "\033[A" && key_bytes(FL_Up, 0, "", true) == "\033OA", "key up");
  check(key_bytes('c', FL_CTRL, "c", false) == "\003", "key ctrl+c");
  check(key_bytes(FL_BackSpace, 0, "", false) == "\177", "key backspace");
  check(key_bytes('a', 0, "á", false) == "á", "key text");
  check(key_bytes(FL_F + 5, 0, "", false) == "\033[15~", "key f5");
  // La cola: espera al prompt, sigue con la siguiente y para si una falla.
  Queue q;
  std::vector<std::string> sent;
  q.send = [&](const std::string& s) { sent.push_back(s); };
  q.add("echo uno");
  q.add("  ");
  q.add("false");
  q.add("echo tres");
  check(q.jobs.size() == 3 && q.waiting() == 3, "queue add");
  q.run(false);
  check(sent.empty() && q.running, "queue waits for the prompt");
  q.prompt(0);
  check(sent.size() == 1 && sent[0] == "echo uno\r" && q.jobs[0].state == Job::RUNNING, "queue first");
  q.prompt(0);
  check(q.jobs[0].state == Job::OK && sent.size() == 2 && sent[1] == "false\r", "queue second");
  q.prompt(1);
  check(q.jobs[1].state == Job::FAILED && q.jobs[1].code == 1 && !q.running && sent.size() == 2, "queue stops on failure");
  q.stop_on_fail = false;
  q.run(true);
  check(sent.size() == 3 && sent[2] == "echo tres\r", "queue resumes");
  q.prompt(0);
  check(q.jobs[2].state == Job::OK && !q.running && q.waiting() == 0, "queue done");
  q.remove(0);
  check(q.jobs.size() == 2, "queue remove");
  q.clear();
  check(q.jobs.empty(), "queue clear");
  // Las órdenes guardadas.
  std::vector<std::string> sv = {"npm run dev", "git status", "git pull --rebase", "docker ps", "grep -rn TODO ."};
  auto r1 = match_saved(sv, "git");
  check(r1.size() == 2 && r1[0] == "git status", "match prefix");
  auto r2 = match_saved(sv, "run");
  check(r2.size() == 1 && r2[0] == "npm run dev", "match inside");
  auto r3 = match_saved(sv, "gpr");
  check(!r3.empty() && r3[0] == "git pull --rebase", "match letters");
  check(match_saved(sv, "").size() == 5 && match_saved(sv, "zzz").empty(), "match all and none");
  std::string ln;
  track_line(ln, 'g', 0, "g");
  track_line(ln, 'i', 0, "i");
  track_line(ln, 0xf1, 0, "ñ");
  track_line(ln, FL_BackSpace, 0, "");
  check(ln == "gi", "track typing");
  track_line(ln, FL_Enter, 0, "\r");
  check(ln.empty(), "track enter");
  // Los atajos y el historial.
  check(valid_shortcut_name("conectar-servidor") && valid_shortcut_name("git.up") && !valid_shortcut_name("mal nombre") &&
            !valid_shortcut_name("-x") && !valid_shortcut_name("") && !valid_shortcut_name("a;b"),
        "shortcut names");
  std::vector<Shortcut> sc = {{"conectar-servidor", "ssh ana@10.0.0.2"}, {"mal nombre", "x"}, {"vacio", " "}};
  std::string sh = shortcuts_script("sh", sc), fi = shortcuts_script("fish", sc), ps = shortcuts_script("ps1", sc);
  check(has(sh, "conectar-servidor() {\n  ssh ana@10.0.0.2\n}") && !has(sh, "mal nombre") && !has(sh, "vacio"), "shortcut sh");
  check(has(fi, "function conectar-servidor\n  ssh ana@10.0.0.2\nend") && has(ps, "function global:conectar-servidor {\n  ssh ana@10.0.0.2\n}"),
        "shortcut fish and ps1");
  std::vector<Shortcut> multi = {{"publicar", "git pull\n\n  npm test \nnpm run build"}};
  check(shortcuts_script("sh", multi) == "# DMarlon Console: los atajos (no lo edite: se rehace)\npublicar() {\n  git pull\n  npm test\n  npm run build\n}\n",
        "shortcut lines");
  check(shortcut_summary(multi[0].cmd) == "git pull ; npm test ; npm run build", "shortcut summary");
  check(history_line(": 1700000000:0;git status") == "git status" && history_line("ls -la") == "ls -la" && history_line("#1700000") == "",
        "history lines");
  // Textos.
  check(seconds(0.42) == num(0.4, 1) + " s" && seconds(75) == "1 min 15 s", "seconds");
  check(base_name("/Users/ana/proyectos/") == "proyectos", "base name");
  check(SKIN_COUNT == 10, "skins");
  std::printf("selftest %s (%d)\n", fails ? "FAILED" : "ok", fails);
  return fails ? 1 : 0;
}

}  // namespace ct

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  std::vector<ct::Session*> tabs;
  int active = -1, skin = 0, font_size = 14, ids = 0;
  bool sync = false, sample = false, show_queue = false;   // el panel de la cola (Ver → Mostrar la cola)
  ct::TabBar* bar = nullptr;
  ct::QueueView* qview = nullptr;
  ct::Completer* comp = nullptr;
  std::vector<std::string> saved;   // las órdenes guardadas (las usadas, primero)
  std::vector<ct::Shortcut> shortcuts;   // los atajos: un nombre que ejecuta una orden
  std::vector<std::string> history;      // las últimas órdenes (la más reciente, primero)
  std::string message;
  double message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_TERM_SELFTEST")) std::exit(ct::selftest());
    if (fl_getenv("DMS_TERM_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_TERM_SHOT")) { set_fonts(); std::exit(shots(d)); }
  }
  ~Form1() {
    for (auto* s : tabs) delete s;
  }
  static void set_fonts() {
#ifdef _WIN32
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
    Fl::set_font(FL_COURIER, " Consolas");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
    Fl::set_font(FL_COURIER, "Menlo-Regular");
    Fl::set_font(FL_COURIER_BOLD, "Menlo-Bold");
#else
    Fl::set_font(FL_COURIER, " DejaVu Sans Mono");
#endif
  }

  // ---- montar la ventana
  void setup() {
    self() = this;
    TermHint->hide();   // el aviso del Diseñador
    Term->box(FL_FLAT_BOX);
    Side->resizable(QueueBox);
    Tabs->resizable(nullptr);
    resizable(Term);
    bar = new ct::TabBar(Tabs->x(), Tabs->y(), Tabs->w(), Tabs->h());
    Tabs->add(bar);
    Tabs->resizable(bar);
    bar->tabs = &tabs;
    bar->on_pick = [](int i) { if (self()) self()->select(i); };
    bar->on_close = [](int i) { if (self()) self()->close_tab(i); };
    bar->on_new = [] { if (self()) self()->new_tab(); };
    qview = new ct::QueueView(QueueBox->x(), QueueBox->y(), QueueBox->w(), QueueBox->h());
    QueueBox->add(qview);
    QueueBox->resizable(qview);
    qview->on_remove = [](size_t i) {
      if (auto* f = self(); f && f->cur()) { f->cur()->queue.remove(i); f->refresh(); }
    };
    comp = new ct::Completer();
    add(comp);
    comp->hide();
    comp->on_pick = [](const std::string& c) { if (self()) self()->type_command(c); };
    comp->on_save = [](const std::string& c) { if (self()) self()->save_command(c); };
    comp->on_forget = [](const ct::Entry& e) {
      if (!self()) return;
      if (e.kind == ct::Entry::SAVED) self()->forget_command(e.text);
      else if (e.kind == ct::Entry::SHORTCUT) self()->remove_shortcut(e.text);
      else self()->forget_history(e.text);
    };
    comp->on_close = [] { if (self() && self()->cur() && !self()->sync) self()->cur()->view->take_focus(); };
#ifdef __APPLE__
    const int K = FL_COMMAND;
#else
    const int K = FL_CTRL | FL_SHIFT;
#endif
    mark(tx::MP_NEW, 0, false, K + 't');
    mark(tx::MP_CLOSE, 0, false, K + 'w');
    mark(tx::MP_NEXT, 0, false, K + ']');
    mark(tx::MP_PREV, 0, false, K + '[');
    mark(tx::MP_CLEAR, 0, false, K + 'k');
    mark(tx::MP_COPY, 0, false, K + 'c');
    mark(tx::MP_PASTE, 0, false, K + 'v');
    mark(tx::MP_BIGGER, 0, false, K + '=');
    mark(tx::MP_SMALLER, 0, false, K + '-');
    mark(tx::MP_RUN, 0, false, K + FL_Enter);
    mark(tx::MP_ADD, 0, false, K + 'e');
    mark(tx::MP_QUIT, 0, false, K + 'q');
    mark(tx::MP_SAVE, 0, false, K + 's');
    mark(tx::MP_COMPLETE, 0, false, K + ';');
    mark(tx::MP_SHORTCUTS, 0, false, K + 'j');
    mark(tx::MP_HISTORY, 0, false, K + 'y');
    mark(tx::MP_QUEUE_PANEL, 0, false, K + 'b');
  }

  void form_create() override {
    set_fonts();
    Fl::lock();
    setup();
    load();
    layout_panels();
    new_tab();
    sync_menu();
    size_range(760, 420);
    if (fl_getenv("DMS_TERM_SMOKE")) Fl::add_timeout(4.0, smoke, this);
  }
  void form_close() override {
    save();
    for (auto* s : tabs) s->close();
  }

  ct::Session* cur() { return active >= 0 && active < (int)tabs.size() ? tabs[(size_t)active] : nullptr; }

  // ---- las pestañas
  ct::Session* new_tab(bool real = true) {
    auto* s = new ct::Session();
    s->id = ++ids;
    s->sample = !real;
    auto* v = new ct::TermView(Term->x(), Term->y(), Term->w(), Term->h());
    Term->add(v);
    v->session = s;
    v->on_complete = [](ct::TermView* tv) { if (self()) self()->open_completer(tv); };
    v->on_history = [](ct::TermView* tv) { if (self()) self()->open_history(tv); };
    v->on_help = [](ct::TermView* tv) { if (self()) self()->show_help(tv->session); };
    // El historial: zsh y fish avisan de cada orden; con las demás, lo escrito al pulsar Intro.
    s->on_command = [](const std::string& c) { if (self()) self()->record_history(c); };
    v->on_enter = [s](const std::string& c) {
      if (self() && s->shell.name != "zsh" && s->shell.name != "fish") self()->record_history(c);
    };
    s->view = v;
    s->queue.notice = [](const std::string& m) { if (self()) self()->set_message(m); };
    s->changed = [] { if (self()) self()->refresh(); };
    style(v);
    s->filter.skin = &ct::SKINS[skin];
    std::string dir = cur() && !cur()->cwd.empty() ? cur()->cwd : std::string();
    if (dir.empty())
      if (const char* h = fl_getenv("HOME")) dir = h;
    tabs.push_back(s);
#ifdef _WIN32
    ct::Session::all().push_back(s);
#endif
    if (real) s->start(dir);
    select((int)tabs.size() - 1);
    return s;
  }
  void close_tab(int i) {
    if (i < 0 || i >= (int)tabs.size()) return;
    ct::Session* s = tabs[(size_t)i];
    s->close();
    Term->remove(s->view);
    Fl::delete_widget(s->view);
#ifdef _WIN32
    auto& all = ct::Session::all();
    all.erase(std::remove(all.begin(), all.end(), s), all.end());
#endif
    delete s;
    tabs.erase(tabs.begin() + i);
    if (tabs.empty()) {
      if (!sync) { save(); hide(); }
      active = -1;
      return;
    }
    select(std::min(i, (int)tabs.size() - 1));
  }
  void select(int i) {
    if (tabs.empty()) return;
    active = ct::clampi(i, 0, (int)tabs.size() - 1);
    for (size_t k = 0; k < tabs.size(); k++) {
      if ((int)k == active) tabs[k]->view->show();
      else tabs[k]->view->hide();
    }
    qview->queue = &cur()->queue;
    qview->scroll = 0;
    ChkStop->value(cur()->queue.stop_on_fail);
    if (!sync) cur()->view->take_focus();
    refresh();
  }

  // ---- la apariencia y la letra
  void style(ct::TermView* v) {
    const ct::Skin& k = ct::SKINS[skin];
    v->textfont(FL_COURIER);
    v->textsize(font_size);
    v->color(ct::rgb(k.bg));
    v->textfgcolor_default(ct::rgb(k.fg));
    v->textbgcolor_default(ct::rgb(k.bg));
    v->textfgcolor(ct::rgb(k.fg));
    v->textbgcolor(ct::rgb(k.bg));
    v->cursorbgcolor(ct::rgb(k.cursor));
    v->cursorfgcolor(ct::rgb(k.bg));
    v->selectionbgcolor(ct::rgb(k.sel));
    v->selectionfgcolor(ct::rgb(k.fg));
    v->redraw();
  }
  void apply_skin() {
    const ct::Skin& k = ct::SKINS[skin];
    for (auto* s : tabs) {
      s->filter.skin = &k;
      // Primero la apariencia nueva y después borrar: así lo vacío también cambia.
      style(s->view);
      s->view->reset_terminal();
      s->view->clear_history();
      s->view->clear(ct::rgb(k.bg));
      style(s->view);
      s->repaint();
    }
    bar->skin = qview->skin = comp->skin = &k;
    uint32_t panel = ct::ui_panel(k), line = ct::ui_bar(k);
    Side->color(ct::rgb(panel));
    QueueBox->color(ct::rgb(panel));
    Tabs->color(ct::rgb(line));
    Term->color(ct::rgb(k.bg));
    color(ct::rgb(k.bg));
    for (Fl_Widget* l : {(Fl_Widget*)LblQueue, (Fl_Widget*)LblQueueHint, (Fl_Widget*)ChkStop}) {
      l->color(ct::rgb(panel));
      l->labelcolor(ct::rgb(l == LblQueue ? k.fg : ct::ui_dim(k)));
    }
    CmdEntry->color(ct::rgb(ct::mix(panel, k.bg, 0.6)));
    CmdEntry->textcolor(ct::rgb(k.fg));
    CmdEntry->cursor_color(ct::rgb(k.cursor));
    for (Fl_Widget* b : {(Fl_Widget*)BtnAdd, (Fl_Widget*)BtnStop, (Fl_Widget*)BtnClear}) {
      b->color(ct::rgb(line));
      b->labelcolor(ct::rgb(k.fg));
    }
    BtnRun->color(ct::rgb(ct::ui_accent(k)));
    BtnRun->labelcolor(ct::rgb(ct::is_light(ct::ui_accent(k)) ? 0x000000 : 0xffffff));
    Status->color(ct::rgb(line));
    Status->labelcolor(ct::rgb(ct::ui_dim(k)));
    sync_menu();
    redraw();
  }
  void set_font_size(int s) {
    font_size = ct::clampi(s, 9, 32);
    for (auto* t : tabs) {
      t->view->textsize(font_size);
      t->pty.resize(t->view->display_columns(), t->view->display_rows());
    }
    refresh();
  }

  // ---- el panel de la cola: oculto, la terminal ocupa todo el ancho
  void layout_panels() {
    int sw = show_queue ? Side->w() : 0, right = w() - sw;
    Tabs->resize(0, Tabs->y(), right, Tabs->h());
    Term->resize(0, Term->y(), right, Term->h());
    if (show_queue) {
      Side->resize(right, Side->y(), Side->w(), Side->h());
      Side->show();
    } else {
      Side->hide();
    }
    init_sizes();
    for (auto* t : tabs) t->pty.resize(t->view->display_columns(), t->view->display_rows());
    sync_menu();
    redraw();
  }
  void toggle_queue(bool on) {
    show_queue = on;
    layout_panels();
    save();
  }

  // ---- la pantalla
  void refresh() {
    if (bar) { bar->active = active; bar->redraw(); }
    if (qview) qview->redraw();
    update_status();
  }
  void update_status() {
    if (!message.empty() && ct::now_s() < message_until) { Status->text(" " + message); return; }
    message.clear();
    ct::Session* s = cur();
    if (!s) return;
    std::string q = s->queue.jobs.empty() ? "" : " · " + ct::fmt(tx::STATUS_QUEUE, {std::to_string(s->queue.waiting()), std::to_string(s->queue.jobs.size())});
    Status->text(" " + ct::fmt(tx::STATUS, {s->shell.name.empty() ? std::string("—") : s->shell.name, s->tab_title(),
                                            std::to_string(s->view->display_columns()), std::to_string(s->view->display_rows())}) +
                 q);
  }
  void set_message(const std::string& m) {
    message = m;
    message_until = ct::now_s() + 5;
    update_status();
  }
  void Tick_timer() override {
    ct::Session* s = cur();
    if (s && (s->queue.busy() || !message.empty())) refresh();
    else update_status();
  }

  // ---- la cola
  void add_command() {
    ct::Session* s = cur();
    if (!s) return;
    std::string c = CmdEntry->text();
    if (ct::trim(c).empty()) { CmdEntry->take_focus(); return; }
    s->queue.add(c);
    CmdEntry->text("");
    CmdEntry->take_focus();
    refresh();
  }
  void run_queue() {
    ct::Session* s = cur();
    if (!s) return;
    if (!s->shell.marks && !s->sample) { set_message(tx::Q_NO_MARKS); return; }
    if (!s->queue.waiting()) { set_message(tx::Q_NOTHING); return; }
    s->run_queue();
    s->view->take_focus();
  }
  void CmdEntry_return() override { add_command(); }
  void BtnAdd_click() override { add_command(); }
  void BtnRun_click() override { run_queue(); }
  void BtnStop_click() override { if (cur()) cur()->stop_queue(); }
  void BtnClear_click() override {
    if (cur()) { cur()->queue.clear(); refresh(); }
  }
  void ChkStop_click() override {
    if (cur()) cur()->queue.stop_on_fail = ChkStop->value();
    save();
  }

  // ---- las órdenes guardadas
  std::string saved_file() const { return ct::config_dir() + "/commands.txt"; }
  void load_saved() {
    std::string t;
    saved.clear();
    if (ct::read_file(saved_file(), t)) {
      for (const auto& l : ct::split(t, '\n'))
        if (!ct::trim(l).empty()) saved.push_back(ct::trim(l));
      return;
    }
    // La primera vez: unas cuantas para empezar.
    saved = {"git status", "git pull --rebase", "git log --oneline -15", "npm run dev", "npm test", "ls -la", "docker ps", "du -sh * | sort -h"};
  }
  void store_saved() {
    if (!persist()) return;
    fl_make_path(ct::config_dir().c_str());
    std::string t;
    for (const auto& c : saved) t += c + "\n";
    ct::write_file(saved_file(), t);
  }
  void save_command(const std::string& cmd) {
    std::string c = ct::trim(cmd);
    if (c.empty() || c.find('\n') != std::string::npos) return;
    saved.erase(std::remove(saved.begin(), saved.end(), c), saved.end());
    saved.insert(saved.begin(), c);
    if (saved.size() > 300) saved.resize(300);
    store_saved();
    set_message(ct::fmt(tx::SAVED_OK, {c}));
  }
  void forget_command(const std::string& c) {
    saved.erase(std::remove(saved.begin(), saved.end(), c), saved.end());
    store_saved();
    set_message(ct::fmt(tx::FORGOT, {c}));
  }
  // La orden elegida, escrita en la línea (se borra lo que hubiera) sin ejecutarla.
  void type_command(const std::string& c) {
    ct::Session* s = cur();
    if (!s) return;
#ifdef _WIN32
    s->write("\033" + c);   // Esc borra la línea en PowerShell
#else
    s->write("\025" + c);   // Ctrl+U borra la línea en zsh, bash y fish
#endif
    s->view->line = c;
    save_command(c);   // sube al principio: las usadas, antes
    if (!sync) s->view->take_focus();
  }
  bool persist() const { return !(sync && sample); }
  void open_completer(ct::TermView* v) {
    std::vector<ct::Entry> e;
    for (const auto& s : shortcuts) e.push_back({ct::Entry::SHORTCUT, s.name, s.cmd});
    for (const auto& c : saved) e.push_back({ct::Entry::SAVED, c, ""});
    int X, Y, lh;
    v->cursor_xy(X, Y, lh);
    comp->open(tx::C_TITLE, e, true, v->line, X, Y + lh + 4, w(), h() - Status->h());
  }
  // «history»: las 10 últimas, para elegir una.
  void open_history(ct::TermView* v) {
    std::vector<ct::Entry> e;
    for (const auto& c : history) {
      if (e.size() >= 10) break;
      e.push_back({ct::Entry::HISTORY, c, ""});
    }
    int X, Y, lh;
    v->cursor_xy(X, Y, lh);
    comp->open(tx::H_TITLE, e, false, "", X, Y + lh + 4, w(), h() - Status->h());
  }

  // ---- la ayuda, escrita en la terminal (con los colores de la apariencia)
  std::string help_text() const {
#ifdef __APPLE__
    const std::string k = "⌘";
#else
    const std::string k = std::string("Ctrl+") + tx::KEY_SHIFT + "+";
#endif
    auto row = [](const std::string& a, const std::string& b) {
      int chars = 0;   // caracteres, no bytes («⌘» son tres)
      for (unsigned char c : a) chars += (c & 0xc0) != 0x80;
      std::string pad((size_t)std::max(2, 22 - chars), ' ');
      return "  \033[1;36m" + a + "\033[0m" + pad + b + "\r\n";
    };
    auto head = [](const std::string& t) { return "\r\n\033[1;33m" + t + "\033[0m\r\n"; };
    std::string o = "\r\n\033[1m" + std::string(tx::HELP_TITLE) + "\033[0m\r\n";
    o += head(tx::HELP_BUILTIN);
    o += row(std::string("ayuda / ") + tx::HELP_WORD, tx::HD_HELP);
    o += row("history", tx::HD_HISTORY);
    o += head(tx::HELP_KEYS);
    o += row(tx::KEY_CTRL_SPACE, tx::HD_COMPLETE);
    o += row(k + "T  " + k + "W", tx::HD_TABS);
    o += row(k + "[  " + k + "]", tx::HD_NEXT);
    o += row(k + "K", tx::HD_CLEAR);
    o += row(k + "S", tx::HD_SAVE);
    o += row(k + "J", tx::HD_SHORTCUTS);
    o += row(k + "Y", tx::HD_HISTKEY);
    o += row(k + "↩", tx::HD_RUN);
    o += row(k + "+  " + k + "−", tx::HD_FONT);
    o += head(tx::HELP_QUEUE_T);
    o += "  " + std::string(tx::HELP_QUEUE) + "\r\n";
    o += head(tx::HELP_SHORTCUTS);
    if (shortcuts.empty()) o += "  \033[2m" + std::string(tx::HELP_NONE) + "\033[0m\r\n";
    for (const auto& sc : shortcuts) o += row(sc.name, "\033[2m→ " + ct::shortcut_summary(sc.cmd) + "\033[0m");
    return o;
  }
  void show_help(ct::Session* s) {
    if (!s) return;
    std::string t = help_text();
    s->output(t.data(), t.size());
    if (s->alive && s->idle) s->write("\r");   // y la shell vuelve a pintar el prompt
  }

  // ---- el historial
  std::string history_file() const { return ct::config_dir() + "/history.txt"; }
  void load_history() {
    history.clear();
    std::string t;
    if (ct::read_file(history_file(), t)) {
      for (const auto& l : ct::split(t, '\n'))
        if (!ct::trim(l).empty()) history.push_back(ct::trim(l));
      return;
    }
#ifndef _WIN32
    // La primera vez: el historial de la shell (lo más reciente, primero).
    const char* hf = fl_getenv("HISTFILE");
    const char* home = fl_getenv("HOME");
    std::vector<std::string> files;
    if (hf && *hf) files.push_back(hf);
    if (home) {
      files.push_back(std::string(home) + "/.zsh_history");
      files.push_back(std::string(home) + "/.bash_history");
    }
    for (const auto& f : files) {
      if (!ct::read_file(f, t)) continue;
      auto lines = ct::split(t, '\n');
      for (auto it = lines.rbegin(); it != lines.rend() && history.size() < 200; ++it) {
        std::string c = ct::history_line(*it);
        if (c.empty() || c == "history" || std::find(history.begin(), history.end(), c) != history.end()) continue;
        history.push_back(c);
      }
      break;
    }
#endif
  }
  void store_history() {
    if (!persist()) return;
    fl_make_path(ct::config_dir().c_str());
    std::string t;
    for (size_t i = 0; i < history.size() && i < 500; i++) t += history[i] + "\n";
    ct::write_file(history_file(), t);
  }
  void record_history(const std::string& cmd) {
    std::string c = ct::trim(cmd);
    if (c.empty() || c == "history" || c.find('\n') != std::string::npos) return;
    history.erase(std::remove(history.begin(), history.end(), c), history.end());
    history.insert(history.begin(), c);
    if (history.size() > 500) history.resize(500);
    store_history();
  }
  void forget_history(const std::string& c) {
    history.erase(std::remove(history.begin(), history.end(), c), history.end());
    store_history();
  }

  // ---- los atajos
  std::string shortcuts_file() const { return ct::config_dir() + "/shortcuts.txt"; }
  void load_shortcuts() {
    shortcuts.clear();
    std::string t;
    if (ct::read_file(shortcuts_file(), t))
      for (const auto& l : ct::split(t, '\n')) {
        size_t tab = l.find('\t');
        if (tab == std::string::npos) continue;
        std::string c = l.substr(tab + 1);
        for (auto& ch : c)
          if (ch == '\x1f') ch = '\n';   // varias órdenes: una por línea
        shortcuts.push_back({l.substr(0, tab), c});
      }
    write_shortcut_scripts();
  }
  // Los archivos que leen las shells (cada vez que vuelven al prompt).
  void write_shortcut_scripts() {
    if (!persist()) return;
    std::string dir = ct::config_dir() + "/shell";
    fl_make_path(dir.c_str());
    ct::write_file(dir + "/shortcuts.sh", ct::shortcuts_script("sh", shortcuts));
    ct::write_file(dir + "/shortcuts.fish", ct::shortcuts_script("fish", shortcuts));
    ct::write_file(dir + "/shortcuts.ps1", ct::shortcuts_script("ps1", shortcuts));
  }
  void store_shortcuts() {
    if (persist()) {
      fl_make_path(ct::config_dir().c_str());
      std::string t;
      for (const auto& s : shortcuts) {
        std::string c = s.cmd;
        for (auto& ch : c)
          if (ch == '\n') ch = '\x1f';
        t += s.name + "\t" + c + "\n";
      }
      ct::write_file(shortcuts_file(), t);
    }
    write_shortcut_scripts();
  }
  // Añade o cambia un atajo. Devuelve el error («» si va bien).
  std::string add_shortcut(const std::string& name, const std::string& cmd) {
    std::string n = ct::trim(name), c;
    // Varias órdenes: una por línea (sin las vacías).
    for (const auto& l : ct::shortcut_lines(cmd)) c += (c.empty() ? "" : "\n") + l;
    for (auto& ch : c)
      if (ch == '\r' || ch == '\t' || ch == '\x1f') ch = ' ';
    if (!ct::valid_shortcut_name(n)) return tx::S_BAD_NAME;
    if (c.empty()) return tx::S_NO_CMD;
    bool found = false;
    for (auto& s : shortcuts)
      if (s.name == n) { s.cmd = c; found = true; }
    if (!found) shortcuts.push_back({n, c});
    std::sort(shortcuts.begin(), shortcuts.end(), [](const ct::Shortcut& a, const ct::Shortcut& b) { return a.name < b.name; });
    store_shortcuts();
    set_message(ct::fmt(tx::S_SAVED, {n}));
    return "";
  }
  void remove_shortcut(const std::string& name) {
    shortcuts.erase(std::remove_if(shortcuts.begin(), shortcuts.end(), [&](const ct::Shortcut& s) { return s.name == name; }),
                    shortcuts.end());
    store_shortcuts();
    set_message(ct::fmt(tx::S_REMOVED, {name}));
  }
  // La ventana de los atajos: la lista, el nombre y la orden.
  void shortcuts_dialog() {
    Fl_Double_Window dlg(600, 520, tx::S_TITLE);
    dlg.set_modal();
    Fl_Box hint(16, 10, 568, 54, tx::S_HINT);
    hint.align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE | FL_ALIGN_WRAP);
    hint.labelsize(12);
    Fl_Hold_Browser list(16, 70, 568, 220);
    list.textfont(FL_COURIER);
    list.textsize(13);
    Fl_Input name(120, 304, 464, 28, tx::S_NAME);
    Fl_Multiline_Input cmd(120, 340, 464, 110, tx::S_CMD);   // una orden por línea
    cmd.textfont(FL_COURIER);
    Fl_Button save(120, 466, 160, 32, tx::S_SAVE), del(290, 466, 120, 32, tx::S_REMOVE), close(484, 466, 100, 32, tx::S_CLOSE);
    save.color(ct::rgb(0x2f5fe0));
    save.labelcolor(FL_WHITE);
    dlg.end();
    struct Ctx {
      Form1* f;
      Fl_Hold_Browser* list;
      Fl_Input* name;
      Fl_Multiline_Input* cmd;
      Fl_Window* dlg;
    } ctx{this, &list, &name, &cmd, &dlg};
    auto fill = [](Ctx* c) {
      c->list->clear();
      for (const auto& s : c->f->shortcuts) c->list->add((s.name + "   → " + ct::shortcut_summary(s.cmd)).c_str());
      if (c->f->shortcuts.empty()) c->list->add(tx::S_LIST_EMPTY);
    };
    fill(&ctx);
    list.callback([](Fl_Widget*, void* p) {
      auto* c = static_cast<Ctx*>(p);
      int i = c->list->value() - 1;
      if (i >= 0 && i < (int)c->f->shortcuts.size()) {
        c->name->value(c->f->shortcuts[(size_t)i].name.c_str());
        c->cmd->value(c->f->shortcuts[(size_t)i].cmd.c_str());
      }
    }, &ctx);
    save.callback([](Fl_Widget*, void* p) {
      auto* c = static_cast<Ctx*>(p);
      std::string err = c->f->add_shortcut(c->name->value(), c->cmd->value());
      if (!err.empty()) { fl_message_title(tx::S_TITLE); fl_alert("%s", err.c_str()); return; }
      c->list->clear();
      for (const auto& s : c->f->shortcuts) c->list->add((s.name + "   → " + ct::shortcut_summary(s.cmd)).c_str());
      c->name->value("");
      c->cmd->value("");
    }, &ctx);
    del.callback([](Fl_Widget*, void* p) {
      auto* c = static_cast<Ctx*>(p);
      if (*c->name->value()) c->f->remove_shortcut(c->name->value());
      c->list->clear();
      for (const auto& s : c->f->shortcuts) c->list->add((s.name + "   → " + ct::shortcut_summary(s.cmd)).c_str());
      c->name->value("");
      c->cmd->value("");
    }, &ctx);
    close.callback([](Fl_Widget*, void* p) { static_cast<Ctx*>(p)->dlg->hide(); }, &ctx);
    dlg.show();
    while (dlg.shown()) Fl::wait();
    if (cur()) cur()->view->take_focus();
  }

  // ---- el menú
  void mark(const char* path, int flags, bool on, int shortcut = 0) {
    int i = Menu1->find_index(path);
    if (i < 0) return;
    Menu1->mode(i, (Menu1->mode(i) & FL_MENU_DIVIDER) | flags | (on ? FL_MENU_VALUE : 0));
    if (shortcut) Menu1->shortcut(i, shortcut);
  }
  void sync_menu() {
    for (int k = 0; k < ct::SKIN_COUNT; k++)
      mark((std::string(tx::M_VIEW) + "/" + ct::SKINS[k].name).c_str(), FL_MENU_RADIO, k == skin);
    mark(tx::MP_STOP_FAIL, FL_MENU_TOGGLE, cur() ? cur()->queue.stop_on_fail : true);
    mark(tx::MP_QUEUE_PANEL, FL_MENU_TOGGLE, show_queue);
    Menu1->redraw();
  }
  void Menu1_click(const std::string& item) override {
    ct::Session* s = cur();
    if (item == tx::MP_NEW) new_tab();
    else if (item == tx::MP_CLOSE) close_tab(active);
    else if (item == tx::MP_NEXT) select((active + 1) % std::max(1, (int)tabs.size()));
    else if (item == tx::MP_PREV) select((active + (int)tabs.size() - 1) % std::max(1, (int)tabs.size()));
    else if (item == tx::MP_CLEAR && s) {
      s->view->clear_screen_home();
      s->view->clear_history();
      if (s->idle) s->write("\014");
    } else if (item == tx::MP_COPY && s) {
      std::string t = s->view->selected();
      if (!t.empty()) Fl::copy(t.c_str(), (int)t.size(), 1);
    } else if (item == tx::MP_PASTE && s) Fl::paste(*s->view, 1);
    else if (item == tx::MP_BIGGER) set_font_size(font_size + 1);
    else if (item == tx::MP_SMALLER) set_font_size(font_size - 1);
    else if (item == tx::MP_QUEUE_PANEL) toggle_queue(!show_queue);
    else if (item == tx::MP_ADD) {
      if (!show_queue) toggle_queue(true);
      CmdEntry->take_focus();
    }
    else if (item == tx::MP_SAVE) {
      std::string def = s && !s->view->line.empty() ? s->view->line : CmdEntry->text();
      fl_message_title(tx::APP);
      if (const char* v = fl_input("%s", def.c_str(), tx::SAVE_ASK)) save_command(v);
    } else if (item == tx::MP_COMPLETE && s) open_completer(s->view);
    else if (item == tx::MP_HISTORY && s) open_history(s->view);
    else if (item == tx::MP_SHORTCUTS) shortcuts_dialog();
    else if (item == tx::MP_HELPCMD && s) show_help(s);
    else if (item == tx::MP_RUN) {
      if (!show_queue) toggle_queue(true);
      run_queue();
    }
    else if (item == tx::MP_STOP && s) s->stop_queue();
    else if (item == tx::MP_EMPTY && s) { s->queue.clear(); refresh(); }
    else if (item == tx::MP_STOP_FAIL && s) {
      s->queue.stop_on_fail = !s->queue.stop_on_fail;
      ChkStop->value(s->queue.stop_on_fail);
    } else if (item == tx::MP_QUIT) {
      save();
      for (auto* t : tabs) t->close();
      hide();
    } else if (item == tx::MP_HOW) {
      fl_message_title(tx::L_HOW);
      fl_message("%s", tx::HOW_TEXT);
    } else if (item == tx::MP_ABOUT) {
      char v[32];
      std::snprintf(v, sizeof v, "%d.%d.%d", FL_MAJOR_VERSION, FL_MINOR_VERSION, FL_PATCH_VERSION);
      fl_message_title(tx::L_ABOUT);
      fl_message("%s", ct::fmt(tx::ABOUT_TEXT, {v}).c_str());
    } else {
      for (int k = 0; k < ct::SKIN_COUNT; k++)
        if (item == std::string(tx::M_VIEW) + "/" + ct::SKINS[k].name) {
          skin = k;
          apply_skin();
          save();
        }
    }
    sync_menu();
    refresh();
  }

  // ---- las preferencias
  std::string settings_file() const { return ct::config_dir() + "/settings.txt"; }
  void load() {
    std::string t;
    if (ct::read_file(settings_file(), t))
      for (const auto& l : ct::split(t, '\n')) {
        if (ct::starts(l, "skin=")) skin = ct::clampi(std::atoi(l.c_str() + 5), 0, ct::SKIN_COUNT - 1);
        if (ct::starts(l, "size=")) font_size = ct::clampi(std::atoi(l.c_str() + 5), 9, 32);
        if (l == "queue=1") show_queue = true;
      }
    load_saved();
    load_history();
    load_shortcuts();
    apply_skin();
  }
  void save() {
    if (sync) return;
    fl_make_path(ct::config_dir().c_str());
    ct::write_file(settings_file(), "skin=" + std::to_string(skin) + "\nsize=" + std::to_string(font_size) +
                                        "\nqueue=" + (show_queue ? "1" : "0") + "\n");
  }

  // ---- sin ventana: la interfaz dibujada en una imagen
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
  // Tres pestañas inventadas y una cola a medias.
  void demo_state(int W, int H) {
    sync = sample = true;
    setup();
    size(W, H);
    layout_panels();
    apply_skin();
    auto feed = [](ct::Session* s, const char* t) { s->output(t, std::strlen(t)); };
    ct::Session* a = new_tab(false);
    a->shell.name = "zsh";
    a->cwd = "/Users/ana/proyectos/tienda";
    a->idle = true;
    feed(a, ct::SAMPLE_MAIN);
    ct::Session* b = new_tab(false);
    b->shell.name = "zsh";
    b->running_cmd = "npm run dev";
    feed(b, ct::SAMPLE_DEV);
    ct::Session* c = new_tab(false);
    c->shell.name = "zsh";
    c->cwd = "/Users/ana";
    c->idle = true;
    feed(c, ct::SAMPLE_HOME);
    // La cola de la primera: dos hechas, una que falló y otra en espera.
    double t = ct::now_s();
    for (const char* cmd : {"npm install", "npm run build", "npm test", "git push origin main"}) a->queue.add(cmd);
    a->queue.jobs[0].state = ct::Job::OK;
    a->queue.jobs[0].secs = 12.4;
    a->queue.jobs[1].state = ct::Job::OK;
    a->queue.jobs[1].secs = 31.2;
    a->queue.jobs[2].state = ct::Job::FAILED;
    a->queue.jobs[2].code = 1;
    a->queue.jobs[2].secs = 2.4;
    (void)t;
    CmdEntry->text("npm test -- envio");
    saved = {"git status", "git pull --rebase", "git log --oneline -15", "git push origin main", "git commit -am \"\"",
             "npm run dev", "npm test", "docker compose up -d", "ls -la"};
    shortcuts = {{"actualizar", "git pull --rebase && npm install"},
                 {"conectar-servidor", "ssh ana@192.168.1.20"},
                 {"desplegar", "npm run build && ./deploy.sh"},
                 {"publicar", "actualizar\nnpm test\ndesplegar"}};
    history = {"npm test", "ls", "git status", "npm run dev", "git checkout -b envio-gratis", "code src/envio.js",
               "npm install vitest --save-dev", "conectar-servidor", "git log --oneline -15", "docker ps", "ping -c 3 dmarlonstudio.com"};
    select(0);
  }
  int shots(const std::string& dir) {
    Fl::screen_count();
    int W = 1240, H = 780;
    if (const char* s = fl_getenv("DMS_TERM_SHOT_SIZE")) std::sscanf(s, "%dx%d", &W, &H);
    demo_state(W, H);
    const int skins[] = {0, 3, 2, 7, 4, 9};
    const char* names[] = {"clasica", "dracula", "solarized-claro", "fosforo", "nord", "papel"};
    for (int k = 0; k < 6; k++) {
      skin = skins[k];
      apply_skin();
      select(k == 1 ? 1 : k == 3 ? 2 : 0);
      render_to(dir + "/" + names[k] + ".png");
    }
    // La lista de órdenes guardadas, abierta con Ctrl+Espacio tras escribir «git».
    skin = 3;
    apply_skin();
    select(0);
    std::string keep = tabs[0]->raw;
    {
      const char* typed = "\033[32mgit\033[0m";
      tabs[0]->output(typed, std::strlen(typed));
    }
    tabs[0]->view->line = "git";
    open_completer(tabs[0]->view);
    comp->sel = 0;
    render_to(dir + "/autocompletar.png");
    comp->hide();
    tabs[0]->raw = keep;   // sin «git» en la línea (se repinta al cambiar la apariencia)
    // Ctrl+Espacio sin nada escrito: los atajos y las guardadas.
    skin = 4;
    apply_skin();
    tabs[0]->view->line.clear();
    open_completer(tabs[0]->view);
    comp->sel = 1;
    render_to(dir + "/atajos.png");
    comp->hide();
    // «history»: las 10 últimas.
    skin = 0;
    apply_skin();
    open_history(tabs[0]->view);
    comp->sel = 2;
    render_to(dir + "/historial.png");
    comp->hide();
    // «ayuda» en la tercera pestaña, con Gruvbox.
    skin = 5;
    apply_skin();
    select(2);
    {
      const char* typed = "\033[32mayuda\033[0m";
      tabs[2]->output(typed, std::strlen(typed));
    }
    show_help(tabs[2]);
    const char* prompt = "\033[1;32mana@MacBook-Pro\033[0m \033[1;34m~\033[0m % ";
    tabs[2]->output(prompt, std::strlen(prompt));
    render_to(dir + "/ayuda.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }

  // ---- la interfaz sin ventana y una shell de verdad
  std::string screen_text(ct::Session* s) {
    const char* t = s->view->text();
    std::string r = t ? t : "";
    if (t) free((void*)t);
    return r;
  }
  bool wait_for(const std::function<bool()>& done, double secs) {
    double end = ct::now_s() + secs;
    while (ct::now_s() < end) {
      for (auto* s : tabs)
        if (!s->sample) s->pump();
      if (done()) return true;
      Fl::wait(0.05);
    }
    return done();
  }
  int ui_test() {
    Fl::screen_count();
    demo_state(1180, 740);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(tabs.size() == 3 && active == 0, "demo tabs");
    chk(tabs[0]->tab_title() == "tienda" && tabs[1]->tab_title() == "npm run dev" && tabs[2]->tab_title() == "ana", "tab titles");
    chk(ct::has(screen_text(tabs[0]), "27 passed"), "sample text");
    for (int k = 0; k < ct::SKIN_COUNT; k++) {
      skin = k;
      apply_skin();
      render_to("");
    }
    skin = 0;
    apply_skin();
    // Las pestañas con el ratón: elegir y cerrar.
    render_to("");
    chk(bar->spans.size() == 3, "tab spans");
    if (bar->spans.size() == 3) {
      bar->on_pick(2);
      chk(active == 2 && tabs[2]->view->visible() && !tabs[0]->view->visible(), "pick tab");
    }
    Menu1_click(tx::MP_NEXT);
    chk(active == 0, "next tab wraps");
    // El panel de la cola: oculto al empezar (la terminal, a todo el ancho) y con Ver → Mostrar la cola.
    chk(!Side->visible() && Term->w() == w(), "queue panel hidden");
    Menu1_click(tx::MP_QUEUE_PANEL);
    chk(show_queue && Side->visible() && Term->w() == w() - Side->w() && Side->x() == Term->w(), "queue panel shown");
    // La cola desde el panel.
    CmdEntry->text("echo hola");
    CmdEntry_return();
    chk(tabs[0]->queue.jobs.size() == 5 && CmdEntry->text().empty(), "add from entry");
    render_to("");
    chk(!qview->removes.empty(), "queue remove buttons");
    qview->on_remove(qview->removes.back().second);
    chk(tabs[0]->queue.jobs.size() == 4, "remove from panel");
    Menu1_click(tx::MP_QUEUE_PANEL);
    chk(!show_queue && !Side->visible() && Term->w() == w(), "queue panel hidden again");
    Menu1_click(tx::MP_BIGGER);
    chk(font_size == 15, "font bigger");
    Menu1_click(tx::MP_SMALLER);
    close_tab(1);
    chk(tabs.size() == 2, "close tab");
    // Las órdenes guardadas: abrir, filtrar, guardar y quitar.
    tabs[0]->view->line = "git";
    open_completer(tabs[0]->view);
    chk(comp->visible() && comp->shown.size() == 5 && comp->offer_save, "completer opens filtered");
    render_to("");
    comp->filter = "git stash";
    comp->refilter();
    chk(comp->offer_save && comp->shown.empty(), "completer offers save");
    comp->sel = 0;   // la única fila: guardar
    comp->choose();
    chk(!saved.empty() && saved[0] == "git stash" && !comp->offer_save, "saved from completer");
    comp->filter = "stash";
    comp->refilter();
    comp->sel = 0;
    chk(!comp->shown.empty() && comp->shown[0].text == "git stash", "saved shows up");
    comp->forget();   // Supr en la lista
    chk(comp->shown.empty() && std::find(saved.begin(), saved.end(), "git stash") == saved.end(), "forget");
    comp->close();
    chk(!comp->visible(), "completer closes");
    // Los atajos en la lista y el historial.
    tabs[0]->view->line = "desp";
    open_completer(tabs[0]->view);
    chk(!comp->shown.empty() && comp->shown[0].kind == ct::Entry::SHORTCUT && comp->shown[0].text == "desplegar", "shortcut in list");
    comp->close();
    open_history(tabs[0]->view);
    chk(comp->shown.size() == 10 && comp->shown[0].text == "npm test" && !comp->offer_save, "history list");
    comp->close();
    chk(!add_shortcut("mal nombre", "ls").empty() && !add_shortcut("vacio", " ").empty(), "shortcut errors");
    // La ayuda, en la terminal.
    show_help(tabs[0]);
    {
      std::string t = screen_text(tabs[0]);
      chk(ct::has(t, tx::HELP_TITLE) && ct::has(t, "history") && ct::has(t, "conectar-servidor") && ct::has(t, "ssh ana@192.168.1.20"),
          "help text");
    }
    // Una shell de verdad: la cola manda cada orden al volver al prompt.
    sample = false;
    ct::Session* s = new_tab(true);
    chk(s->alive, "shell started");
    bool prompt = wait_for([&] { return s->idle; }, 25);
    std::printf("shell: %s marks=%d prompt=%d\n", s->shell.name.c_str(), s->shell.marks ? 1 : 0, prompt ? 1 : 0);
    if (s->shell.marks && prompt) {
      s->queue.stop_on_fail = false;
      s->queue.add("echo uno-$((1+1))");
      s->queue.add("sleep 0.3; false");
      s->queue.add("echo tres-$((1+2))");
      run_queue();
      wait_for([&] { return !s->queue.running && !s->queue.busy(); }, 30);
      const auto& j = s->queue.jobs;
      chk(j.size() == 3 && j[0].state == ct::Job::OK && j[1].state == ct::Job::FAILED && j[1].code == 1 && j[2].state == ct::Job::OK,
          "real queue");
      chk(j.size() == 3 && j[1].secs >= 0.25, "real queue timing");
      std::string text = screen_text(s);
      chk(ct::has(text, "uno-2") && ct::has(text, "tres-3"), "real output");
      // Parar si una falla.
      s->queue.clear();
      s->queue.stop_on_fail = true;
      s->queue.add("false");
      s->queue.add("echo nunca-$((2+2))");
      run_queue();
      wait_for([&] { return !s->queue.running && !s->queue.busy(); }, 20);
      chk(s->queue.jobs[0].state == ct::Job::FAILED && s->queue.jobs[1].state == ct::Job::WAITING, "real stop on failure");
      chk(!ct::has(screen_text(s), "nunca-4"), "not run after failure");
      // La orden se resalta mientras se escribe (verde si existe, rojo si no).
      s->raw.clear();
      s->write("cd");
      chk(wait_for([&] { return ct::has(s->raw, "\033[32m"); }, 10), "real highlight green");
      s->write(" \025xq9zz");
      chk(wait_for([&] { return ct::has(s->raw, "\033[31m"); }, 10), "real highlight red");
      s->write("\025");
      // El tamaño llega a la shell.
      s->write("stty size\r");
      std::string want = std::to_string(s->view->display_rows()) + " " + std::to_string(s->view->display_columns());
      chk(wait_for([&] { return ct::has(screen_text(s), want); }, 10), "pty size");
      chk(!s->tab_title().empty(), "real title");
      // Una orden guardada, escrita con la lista y ejecutada con Intro.
      save_command("echo guardada-$((3*3))");
      s->view->line = "guard";
      open_completer(s->view);
      chk(comp->shown.size() == 1, "real completer");
      comp->sel = 0;
      comp->choose();
      s->write("\r");
      chk(wait_for([&] { return ct::has(screen_text(s), "guardada-9"); }, 10), "real saved command runs");
      // Un atajo que llama a otro: la shell los lee al volver al prompt.
      chk(add_shortcut("saluda-dms", "echo hola-$((5*5))").empty() && add_shortcut("doble-dms", "saluda-dms && saluda-dms").empty(),
          "real shortcuts saved");
      s->idle = false;
      s->write("\r");
      wait_for([&] { return s->idle; }, 10);
      s->write("doble-dms\r");
      auto count = [&] {
        std::string t = screen_text(s);
        int n = 0;
        for (size_t p = t.find("hola-25"); p != std::string::npos; p = t.find("hola-25", p + 1)) n++;
        return n;
      };
      chk(wait_for([&] { return count() >= 2; }, 10), "real shortcut calls another");
      // Un atajo con varias órdenes, una por línea.
      chk(add_shortcut("varias-dms", "echo uno-$((1+0))\n\necho dos-$((1+1))").empty(), "multi shortcut saved");
      s->idle = false;
      s->write("\r");
      wait_for([&] { return s->idle; }, 10);
      s->write("varias-dms\r");
      chk(wait_for([&] { std::string t = screen_text(s); return ct::has(t, "uno-1") && ct::has(t, "dos-2"); }, 10), "real multi shortcut");
      // El historial de verdad: zsh avisa de cada orden.
      chk(!history.empty() && history[0] == "varias-dms", "real history");
      open_history(s->view);
      chk(!comp->shown.empty() && comp->shown[0].text == "varias-dms", "real history list");
      comp->close();
    } else {
      chk(false, "shell prompt mark");
    }
    close_tab((int)tabs.size() - 1);
    std::printf("uitest %s\n", f ? "FAILED" : "ok");
    std::fflush(stdout);
    return f ? 1 : 0;
  }

  static void smoke(void* p) {
    auto* f = static_cast<Form1*>(p);
    std::printf("smoke ok tabs=%d\n", (int)f->tabs.size());
    std::fflush(stdout);
    f->form_close();
    f->hide();
  }
};
''';
