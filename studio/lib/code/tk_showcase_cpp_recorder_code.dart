part of 'tk_examples.dart';

// El código en C++ del grabador de pantalla (tk_showcase_cpp_recorder.dart):
// va tal cual en Form1.cpp, después de los textos (namespace tx).
const _recorderIncludes = r'''#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <memory>
#include <string>
#include <thread>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <csignal>
#include <spawn.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif
#ifdef __APPLE__
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';

const _recorderCode = r'''
// ============================================================ los datos
// Las grabaciones: en macOS con screencapture (el grabador del sistema: la
// pantalla o una zona, el cursor, los clics y el micrófono); en Windows y
// Linux, con ffmpeg si está instalado. Cada grabación es un archivo de vídeo
// en la carpeta de grabaciones, listo para subir a YouTube.
namespace rec {

std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
std::string two(long long v) {
  char b[16];
  std::snprintf(b, sizeof b, "%02lld", v);
  return b;
}
// «1:05» o «1:02:03».
std::string clock_text(double secs) {
  long long s = (long long)std::floor(secs + 0.5);
  if (s < 0) s = 0;
  if (s >= 3600) return std::to_string(s / 3600) + ":" + two(s / 60 % 60) + ":" + two(s % 60);
  return std::to_string(s / 60) + ":" + two(s % 60);
}
std::string size_text(long long bytes) {
  char b[32];
  if (bytes >= 1000LL * 1000 * 1000) std::snprintf(b, sizeof b, "%.1f GB", bytes / 1e9);
  else if (bytes >= 1000LL * 1000) std::snprintf(b, sizeof b, "%.1f MB", bytes / 1e6);
  else std::snprintf(b, sizeof b, "%lld KB", bytes / 1000);
  std::string s = b;
  for (auto& c : s)
    if (c == '.') c = tx::DEC[0];
  return s;
}
double now_s() {
  using namespace std::chrono;
  return duration<double>(steady_clock::now().time_since_epoch()).count();
}

// ------------------------------------------------------------ la carpeta
std::string home() {
#ifdef _WIN32
  const char* h = fl_getenv("USERPROFILE");
#else
  const char* h = fl_getenv("HOME");
#endif
  return h ? h : ".";
}
std::string folder() {
  if (const char* o = fl_getenv("DMS_RECORDER_DIR")) return o;
#ifdef __APPLE__
  return home() + "/Movies/DMarlon Studio";
#elif defined(_WIN32)
  return home() + "\\Videos\\DMarlon Studio";
#else
  return home() + "/Videos/DMarlon Studio";
#endif
}
std::string cache_dir() { return folder() + "/.miniaturas"; }
// La carpeta para enseñarla: «~/Movies/DMarlon Studio».
std::string folder_shown() {
  std::string f = folder(), h = home();
  return f.compare(0, h.size(), h) == 0 ? "~" + f.substr(h.size()) : f;
}
// «Grabación 2026-11-11 a las 17.02.24.mov» (como las del sistema).
std::string new_name(time_t t, const char* ext) {
  struct tm v;
#ifdef _WIN32
  localtime_s(&v, &t);
#else
  localtime_r(&t, &v);
#endif
  char d[32], h[32];
  std::strftime(d, sizeof d, "%Y-%m-%d", &v);
  std::strftime(h, sizeof h, "%H.%M.%S", &v);
  return fmt(tx::FILE_NAME, {d, h}) + ext;
}

// ------------------------------------------------------------ el vídeo por dentro
// La duración (átomo mvhd) y el tamaño (tkhd de la pista de vídeo) de un
// .mov o .mp4, leídos del propio archivo.
struct VideoInfo {
  double seconds = 0;
  int width = 0, height = 0;
};
uint32_t be32(const unsigned char* p) { return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 | p[3]; }
uint64_t be64(const unsigned char* p) { return (uint64_t)be32(p) << 32 | be32(p + 4); }
VideoInfo parse_movie(const std::string& d) {
  VideoInfo v;
  const auto* b = (const unsigned char*)d.data();
  size_t n = d.size();
  size_t i = d.find("mvhd");
  if (i != std::string::npos && i + 32 <= n) {
    const unsigned char* p = b + i + 4;
    if (p[0] == 0) {
      uint32_t scale = be32(p + 12), dur = be32(p + 16);
      if (scale) v.seconds = dur / (double)scale;
    } else if (i + 40 <= n) {
      uint32_t scale = be32(p + 20);
      uint64_t dur = be64(p + 24);
      if (scale) v.seconds = (double)dur / scale;
    }
  }
  for (size_t k = d.find("tkhd"); k != std::string::npos; k = d.find("tkhd", k + 4)) {
    const unsigned char* p = b + k + 4;
    size_t off = p[0] == 0 ? 76 : 88;   // hasta el ancho (16.16)
    if (k + 4 + off + 8 > n) break;
    int w = (int)(be32(p + off) >> 16), h = (int)(be32(p + off + 4) >> 16);
    if (w > v.width) {
      v.width = w;
      v.height = h;
    }
  }
  return v;
}
// Solo el principio y el final del archivo: ahí están los átomos.
VideoInfo movie_info(const std::string& path) {
  VideoInfo v;
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return v;
  std::fseek(f, 0, SEEK_END);
  long size = std::ftell(f);
  std::string data;
  auto read_at = [&](long at, long len) {
    std::string s((size_t)len, '\0');
    std::fseek(f, at, SEEK_SET);
    size_t got = std::fread(&s[0], 1, (size_t)len, f);
    s.resize(got);
    return s;
  };
  const long chunk = 2 * 1024 * 1024;
  if (size <= 2 * chunk) data = read_at(0, size);
  else data = read_at(0, chunk) + read_at(size - chunk, chunk);
  std::fclose(f);
  return parse_movie(data);
}

// ------------------------------------------------------------ la zona
struct Area {
  int x = 0, y = 0, w = 0, h = 0;   // w == 0: la pantalla entera
};
enum AreaKind { AR_FULL, AR_1080, AR_720, AR_VERTICAL };
// Una zona de [aw]×[ah] centrada en la pantalla [sw]×[sh]; si no cabe, la
// más grande con la misma forma (los vídeos de YouTube son 16:9).
Area centered(int sw, int sh, int aw, int ah) {
  Area a;
  double k = std::min(1.0, std::min(sw / (double)aw, sh / (double)ah));
  a.w = (int)(aw * k) / 2 * 2;
  a.h = (int)(ah * k) / 2 * 2;
  a.x = (sw - a.w) / 2;
  a.y = (sh - a.h) / 2;
  return a;
}
Area area_for(int kind, int sw, int sh) {
  switch (kind) {
    case AR_1080: return centered(sw, sh, 1920, 1080);
    case AR_720: return centered(sw, sh, 1280, 720);
    case AR_VERTICAL: return centered(sw, sh, 1080, 1920);
    default: return Area();
  }
}

// ------------------------------------------------------------ la orden
struct Options {
  int area = AR_FULL;
  bool mic = true, clicks = true, cursor = true;
  int limit_s = 0;   // 0: sin límite
};
// Los argumentos de screencapture (macOS).
std::vector<std::string> screencapture_args(const Options& o, const Area& a, const std::string& file) {
  std::vector<std::string> v = {"/usr/sbin/screencapture", "-x", "-v"};
  if (o.cursor) v.push_back("-C");
  if (o.clicks) v.push_back("-k");
  if (o.mic) v.push_back("-g");
  if (a.w > 0) v.push_back("-R" + std::to_string(a.x) + "," + std::to_string(a.y) + "," + std::to_string(a.w) + "," + std::to_string(a.h));
  if (o.limit_s > 0) v.push_back("-V" + std::to_string(o.limit_s));
  v.push_back(file);
  return v;
}
// Los de ffmpeg (Windows y Linux): H.264 a 30 imágenes por segundo.
std::vector<std::string> ffmpeg_args(const Options& o, const Area& a, const std::string& file) {
  std::vector<std::string> v = {"ffmpeg", "-y", "-hide_banner", "-loglevel", "error"};
#ifdef _WIN32
  v.insert(v.end(), {"-f", "gdigrab", "-framerate", "30", "-draw_mouse", o.cursor ? "1" : "0"});
  if (a.w > 0) {
    v.insert(v.end(), {"-offset_x", std::to_string(a.x), "-offset_y", std::to_string(a.y), "-video_size",
                       std::to_string(a.w) + "x" + std::to_string(a.h)});
  }
  v.insert(v.end(), {"-i", "desktop"});
#else
  v.insert(v.end(), {"-f", "x11grab", "-framerate", "30", "-draw_mouse", o.cursor ? "1" : "0"});
  if (a.w > 0) v.insert(v.end(), {"-video_size", std::to_string(a.w) + "x" + std::to_string(a.h)});
  const char* disp = fl_getenv("DISPLAY");
  v.insert(v.end(), {"-i", std::string(disp ? disp : ":0") + "+" + std::to_string(a.x) + "," + std::to_string(a.y)});
#endif
  if (o.limit_s > 0) v.insert(v.end(), {"-t", std::to_string(o.limit_s)});
  v.insert(v.end(), {"-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", file});
  return v;
}
std::string quote(const std::string& s) {
#ifdef _WIN32
  return "\"" + s + "\"";
#else
  std::string q = "'";
  for (char c : s) q += c == '\'' ? std::string("'\\''") : std::string(1, c);
  return q + "'";
#endif
}
std::string command_line(const std::vector<std::string>& args) {
  std::string c;
  for (const auto& a : args) c += (c.empty() ? "" : " ") + quote(a);
  return c;
}
bool has_ffmpeg() {
#ifdef _WIN32
  return std::system("where ffmpeg >NUL 2>NUL") == 0;
#else
  return std::system("command -v ffmpeg >/dev/null 2>&1") == 0;
#endif
}

// ------------------------------------------------------------ grabar
// Una grabación en marcha: el proceso que graba y cómo pararlo.
class Recorder {
public:
  std::string file, error;
  double started = 0;
  bool running() const { return running_; }

  bool start(const Options& o, const Area& a, const std::string& path) {
    file = path;
    error.clear();
#ifdef __APPLE__
    auto args = screencapture_args(o, a, path);
    std::vector<char*> argv;
    for (auto& s : args) argv.push_back(&s[0]);
    argv.push_back(nullptr);
    if (posix_spawn(&pid_, argv[0], nullptr, nullptr, argv.data(), environ) != 0) {
      error = tx::ERR_START;
      return false;
    }
#else
    if (!has_ffmpeg()) {
      error = tx::ERR_NO_FFMPEG;
      return false;
    }
#ifdef _WIN32
    pipe_ = _popen(command_line(ffmpeg_args(o, a, path)).c_str(), "w");
#else
    pipe_ = popen(command_line(ffmpeg_args(o, a, path)).c_str(), "w");
#endif
    if (!pipe_) {
      error = tx::ERR_START;
      return false;
    }
#endif
    started = now_s();
    running_ = true;
    return true;
  }
  // Para la grabación y espera a que el archivo quede cerrado.
  void stop() {
    if (!running_) return;
#ifdef __APPLE__
    kill(pid_, SIGINT);   // como Ctrl+C: screencapture cierra el vídeo
    int st = 0;
    waitpid(pid_, &st, 0);
#else
    std::fputs("q", pipe_);   // ffmpeg termina con «q»
    std::fflush(pipe_);
#ifdef _WIN32
    _pclose(pipe_);
#else
    pclose(pipe_);
#endif
    pipe_ = nullptr;
#endif
    running_ = false;
  }
  // ¿Terminó solo (el límite de tiempo)?
  bool finished_by_itself() {
    if (!running_) return false;
#ifdef __APPLE__
    int st = 0;
    if (waitpid(pid_, &st, WNOHANG) == pid_) {
      running_ = false;
      return true;
    }
#endif
    return false;
  }

private:
  bool running_ = false;
#ifdef __APPLE__
  pid_t pid_ = 0;
#else
  FILE* pipe_ = nullptr;
#endif
};

// ------------------------------------------------------------ las grabaciones
struct Clip {
  std::string path, name;
  long long bytes = 0, mtime = 0;
  VideoInfo info;
  Fl_RGB_Image* thumb = nullptr;   // la miniatura (QuickLook), si la hay
};
bool is_video(const std::string& n) {
  std::string l = lower(n);
  auto ends = [&](const char* e) { return l.size() > std::strlen(e) && l.compare(l.size() - std::strlen(e), std::string::npos, e) == 0; };
  return ends(".mov") || ends(".mp4") || ends(".m4v");
}
std::vector<Clip> list_clips(const std::string& dir) {
  std::vector<Clip> out;
  dirent** names = nullptr;
  int n = fl_filename_list(dir.c_str(), &names, fl_casenumericsort);
  for (int i = 0; i < n; i++) {
    std::string nm = names[i]->d_name;
    if (!nm.empty() && nm.back() == '/') continue;
    if (nm.empty() || nm[0] == '.' || !is_video(nm)) continue;
    Clip c;
    c.path = dir + "/" + nm;
    c.name = nm;
    struct stat st;
    if (fl_stat(c.path.c_str(), &st) == 0) {
      c.bytes = (long long)st.st_size;
      c.mtime = (long long)st.st_mtime;
    }
    c.info = movie_info(c.path);
    out.push_back(c);
  }
  fl_filename_free_list(&names, n);
  std::sort(out.begin(), out.end(), [](const Clip& a, const Clip& b) { return a.mtime > b.mtime; });
  return out;
}
// La miniatura con QuickLook (macOS): <caché>/<nombre>.png.
std::string thumb_path(const std::string& name) { return cache_dir() + "/" + name + ".png"; }
void make_thumb(const std::string& path, const std::string& name) {
#ifdef __APPLE__
  fl_make_path(cache_dir().c_str());
  std::string cmd = "/usr/bin/qlmanage -t -s 480 -o " + quote(cache_dir()) + " " + quote(path) + " >/dev/null 2>&1";
  int r = std::system(cmd.c_str());
  (void)r;
  (void)name;
#else
  (void)path;
  (void)name;
#endif
}

// Abrir, enseñar en el Finder y mandar a la Papelera.
void open_file(const std::string& p) {
#ifdef __APPLE__
  std::string c = "/usr/bin/open " + quote(p);
#elif defined(_WIN32)
  std::string c = "start \"\" " + quote(p);
#else
  std::string c = "xdg-open " + quote(p) + " &";
#endif
  int r = std::system(c.c_str());
  (void)r;
}
void reveal(const std::string& p) {
#ifdef __APPLE__
  std::string c = "/usr/bin/open -R " + quote(p);
#elif defined(_WIN32)
  std::string c = "explorer /select," + quote(p);
#else
  std::string c = "xdg-open " + quote(folder()) + " &";
#endif
  int r = std::system(c.c_str());
  (void)r;
}
bool trash(const std::string& p) {
#ifdef __APPLE__
  std::string dest = home() + "/.Trash/" + p.substr(p.find_last_of('/') + 1);
  return std::rename(p.c_str(), dest.c_str()) == 0;
#else
  return std::remove(p.c_str()) == 0;
#endif
}

// ------------------------------------------------------------ dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
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

struct Hit {
  int x, y, w, h, act, idx;
};

// Las grabaciones en tarjetas: miniatura, nombre, duración, tamaño y botones.
class ClipsView : public Fl_Widget {
public:
  std::vector<Clip>* clips = nullptr;
  int hover = -1, scroll = 0, content_h = 0, selected = -1;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;

  ClipsView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}

  int hit_at(int mx, int my) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (mx >= h.x && mx < h.x + h.w && my >= h.y && my < h.y + h.h) return i;
    }
    return -1;
  }
  int button(int x, int y, const char* text, int act, int idx, Fl_Color fg) {
    fl_font(FL_HELVETICA_BOLD, 12);
    int w = (int)fl_width(text) + 20, h = 26;
    bool hot = (int)hits.size() == hover;
    hits.push_back({x, y, w, h, act, idx});
    round_box(x, y, w, h, 7, hot ? rgb(0xeef2f8) : FL_WHITE, rgb(0xd5dae2));
    fl_color(fg);
    fl_draw(text, x, y, w, h, FL_ALIGN_CENTER);
    return x + w;
  }
  // Sin miniatura: un degradado con el triángulo de reproducir.
  static void placeholder(int x, int y, int w, int h, int seed) {
    static const unsigned tops[] = {0x1e3a8a, 0x7c2d12, 0x065f46, 0x581c87, 0x0f172a};
    unsigned a = tops[seed % 5];
    for (int i = 0; i < h; i++) {
      double t = i / (double)h;
      fl_color(fl_rgb_color((uchar)(((a >> 16) & 255) * (1 - t * 0.5)), (uchar)(((a >> 8) & 255) * (1 - t * 0.5)),
                            (uchar)((a & 255) * (1 - t * 0.5) + 40 * t)));
      fl_xyline(x, y + i, x + w - 1);
    }
  }
  static void play(int cx, int cy) {
    fl_color(fl_rgb_color(255, 255, 255));
    fl_pie(cx - 18, cy - 18, 36, 36, 0, 360);
    fl_color(rgb(0x111827));
    fl_polygon(cx - 6, cy - 9, cx - 6, cy + 9, cx + 10, cy);
  }

  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    fl_color(rgb(0xf4f6f9));
    fl_rectf(x(), y(), w(), h());
    if (!clips || clips->empty()) {
      fl_font(FL_HELVETICA_BOLD, 17);
      fl_color(rgb(0x1f2937));
      fl_draw(tx::EMPTY_TITLE, x(), y() + 70, w(), 26, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(0x6b7280));
      fl_draw(tx::EMPTY_HELP, x() + 40, y() + 100, w() - 80, 40, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      content_h = 160;
      fl_pop_clip();
      return;
    }
    const int CW = 340, CH = 290, G = 16;
    int cols = std::max(1, (w() - G) / (CW + G));
    int x0 = x() + (w() - cols * (CW + G) + G) / 2;
    for (size_t n = 0; n < clips->size(); n++) {
      const Clip& c = (*clips)[n];
      int k = (int)n;
      int cx = x0 + (int)(n % (size_t)cols) * (CW + G), cy = y() + G - scroll + (int)(n / (size_t)cols) * (CH + G);
      round_box(cx, cy, CW, CH, 14, k == selected ? rgb(0xeef4ff) : FL_WHITE, k == selected ? rgb(0x93b4f5) : rgb(0xe3e7ee));
      hits.push_back({cx, cy, CW, CH, 0, k});
      // La miniatura (16:9) y su duración encima.
      int tx0 = cx + 10, ty0 = cy + 10, tw = CW - 20, th = tw * 9 / 16;
      fl_push_clip(tx0, ty0, tw, th);
      if (c.thumb) {
        double s = std::max(tw / (double)c.thumb->w(), th / (double)c.thumb->h());
        int dw = (int)(c.thumb->w() * s), dh = (int)(c.thumb->h() * s);
        c.thumb->scale(dw, dh, 0, 1);
        c.thumb->draw(tx0 + (tw - dw) / 2, ty0 + (th - dh) / 2);
      } else {
        placeholder(tx0, ty0, tw, th, k);
      }
      fl_pop_clip();
      play(tx0 + tw / 2, ty0 + th / 2);
      hits.push_back({tx0, ty0, tw, th, 1, k});
      std::string d = clock_text(c.info.seconds);
      fl_font(FL_HELVETICA_BOLD, 12);
      int dw = (int)fl_width(d.c_str()) + 12;
      fl_color(fl_rgb_color(0, 0, 0));
      fl_rounded_rectf(tx0 + tw - dw - 6, ty0 + th - 26, dw, 20, 5);
      fl_color(FL_WHITE);
      fl_draw(d.c_str(), tx0 + tw - dw - 6, ty0 + th - 26, dw, 20, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA_BOLD, 13);
      fl_color(rgb(0x1f2937));
      fl_draw(fit(c.name, CW - 24).c_str(), cx + 12, ty0 + th + 22);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(0x6b7280));
      std::string meta = size_text(c.bytes);
      if (c.info.width) meta = std::to_string(c.info.width) + "×" + std::to_string(c.info.height) + "  ·  " + meta;
      fl_draw(meta.c_str(), cx + 12, ty0 + th + 42);
      int bx = cx + 12, by = cy + CH - 38;
      bx = button(bx, by, tx::FINDER, 2, k, rgb(0x1f2937)) + 6;
      bx = button(bx, by, tx::YOUTUBE, 3, k, rgb(0xdc2626)) + 6;
      fl_font(FL_HELVETICA_BOLD, 12);
      button(cx + CW - 12 - ((int)fl_width(tx::DELETE) + 20), by, tx::DELETE, 4, k, rgb(0x6b7280));
    }
    int rows = ((int)clips->size() + cols - 1) / cols;
    content_h = G + rows * (CH + G);
    fl_pop_clip();
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
        if (i >= 0 && on_act) on_act(hits[(size_t)i].act, hits[(size_t)i].idx);
        return 1;
      }
      case FL_MOUSEWHEEL:
        scroll = std::max(0, std::min(scroll + Fl::event_dy() * 30, std::max(0, content_h - h())));
        redraw();
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ------------------------------------------------------------ las pruebas
// Un .mov mínimo: mvhd con la duración y tkhd con el tamaño.
std::string fake_movie(double secs, int w, int h, bool v1) {
  auto u32 = [](uint32_t v) { std::string s(4, '\0'); for (int i = 0; i < 4; i++) s[(size_t)i] = (char)(v >> (24 - 8 * i)); return s; };
  std::string mvhd = "mvhd";
  if (!v1) mvhd += u32(0) + u32(0) + u32(0) + u32(600) + u32((uint32_t)(secs * 600)) + std::string(80, '\0');
  else mvhd += u32(0x01000000) + u32(0) + u32(0) + u32(0) + u32(0) + u32(600) + u32(0) + u32((uint32_t)(secs * 600)) + std::string(80, '\0');
  std::string tkhd = "tkhd" + u32(v1 ? 0x01000000 : 0) + std::string(v1 ? 84 : 72, '\0') + u32((uint32_t)w << 16) + u32((uint32_t)h << 16);
  std::string audio = "tkhd" + u32(0) + std::string(72, '\0') + u32(0) + u32(0);
  return "....ftypqt  " + mvhd + audio + tkhd;
}

int selftest() {
  int f = 0;
  auto chk = [&](bool ok, const char* what) {
    if (!ok) { std::printf("FAIL %s\n", what); f++; }
  };
  chk(clock_text(65) == "1:05" && clock_text(3723) == "1:02:03" && clock_text(0) == "0:00", "duraciones");
  chk(size_text(1500) == "1 KB" && size_text(25300000) == "25" + std::string(1, tx::DEC[0]) + "3 MB", "tamaños");
  VideoInfo v = parse_movie(fake_movie(12.5, 1920, 1080, false));
  chk(std::fabs(v.seconds - 12.5) < 0.01 && v.width == 1920 && v.height == 1080, "mvhd y tkhd (versión 0)");
  v = parse_movie(fake_movie(3.0, 1280, 720, true));
  chk(std::fabs(v.seconds - 3.0) < 0.01 && v.width == 1280 && v.height == 720, "mvhd y tkhd (versión 1)");
  // Zonas: centradas, 16:9 y que caben.
  Area a = area_for(AR_1080, 2560, 1440);
  chk(a.w == 1920 && a.h == 1080 && a.x == 320 && a.y == 180, "1080p centrada");
  a = area_for(AR_1080, 1512, 982);
  chk(a.w <= 1512 && a.h <= 982 && std::abs(a.w * 9 - a.h * 16) < 32, "1080p en una pantalla pequeña (16:9)");
  a = area_for(AR_VERTICAL, 1512, 982);
  chk(a.h <= 982 && a.w < a.h, "vertical");
  chk(area_for(AR_FULL, 1512, 982).w == 0, "pantalla completa");
  // Las órdenes.
  Options o;
  o.limit_s = 60;
  auto sc = screencapture_args(o, area_for(AR_720, 1920, 1080), "/tmp/a b.mov");
  std::string joined;
  for (const auto& s : sc) joined += s + " ";
  chk(joined == "/usr/sbin/screencapture -x -v -C -k -g -R320,180,1280,720 -V60 /tmp/a b.mov ", "screencapture");
  o.mic = o.clicks = false;
  o.limit_s = 0;
  sc = screencapture_args(o, Area(), "x.mov");
  chk(sc.size() == 5 && sc[3] == "-C", "sin micrófono ni clics");
  auto ff = ffmpeg_args(o, area_for(AR_720, 1920, 1080), "x.mp4");
  chk(std::find(ff.begin(), ff.end(), "libx264") != ff.end() && ff.back() == "x.mp4", "ffmpeg");
  chk(command_line({"a", "b c"}).find("b c") != std::string::npos, "comillas");
  // Nombres y lista.
  std::string nm = new_name((time_t)1794365000, ".mov");
  chk(nm.size() > 10 && nm.substr(nm.size() - 4) == ".mov", "nombre de archivo");
  std::string dir = std::string(fl_getenv("DMS_RECORDER_DIR") ? fl_getenv("DMS_RECORDER_DIR") : "");
  if (!dir.empty()) {
    fl_make_path(dir.c_str());
    std::string m = fake_movie(42, 1920, 1080, false);
    FILE* fp = fl_fopen((dir + "/uno.mov").c_str(), "wb");
    if (fp) { std::fwrite(m.data(), 1, m.size(), fp); std::fclose(fp); }
    fp = fl_fopen((dir + "/notas.txt").c_str(), "wb");
    if (fp) std::fclose(fp);
    auto clips = list_clips(dir);
    chk(clips.size() == 1 && clips[0].name == "uno.mov" && std::fabs(clips[0].info.seconds - 42) < 0.01, "lista de grabaciones");
    std::remove((dir + "/uno.mov").c_str());
    std::remove((dir + "/notas.txt").c_str());
  }
  // De verdad (DMS_RECORDER_LIVE=1, en macOS): 2 segundos y se para con SIGINT.
  if (fl_getenv("DMS_RECORDER_LIVE") && !dir.empty()) {
    Recorder r;
    Options lo;
    lo.mic = false;
    std::string path = dir + "/" + new_name(std::time(nullptr), ".mov");
    bool ok = r.start(lo, area_for(AR_720, 1920, 1080), path);
    double t0 = now_s();
    while (now_s() - t0 < 2.5) Fl::wait(0.1);
    r.stop();
    VideoInfo li = movie_info(path);
    std::printf("live: %s %.2f s %dx%d\n", ok ? "ok" : r.error.c_str(), li.seconds, li.width, li.height);
    chk(ok && li.seconds > 1.5 && li.width > 0, "grabación de verdad");
    std::remove(path.c_str());   // contiene la pantalla: no se guarda
  }
  if (!f) std::printf("selftest ok\n");
  return f ? 1 : 0;
}

}  // namespace rec

// ============================================================ la barra de menús
// Mientras graba, la ventana se esconde (no sale en el vídeo) y la barra de
// menús de macOS enseña el tiempo («🔴 0:42») con «Detener y guardar».
namespace bar {
struct Entry {
  std::string title;
  int tag = 0;
  bool enabled = true, sep = false;
};
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
    Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsRecorderTarget", 0);
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
bool available() {
  static int ok = -1;
  if (ok < 0) ok = objc_getClass("NSStatusBar") != nullptr;
  return ok == 1;
}
void show(const std::string& title, const std::vector<Entry>& entries) {
  Pool pool;
  if (!item()) {
    id it = msg<id, double>(msg(cls("NSStatusBar"), "systemStatusBar"), "statusItemWithLength:", -1.0);
    if (!it) return;
    msg(it, "retain");
    item() = it;
  }
  msg<void, id>(msg(item(), "button"), "setTitle:", str(title));
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
    msg<void, id>(m, "addItem:", it);
    msg<void>(it, "release");
  }
  msg<void, id>(item(), "setMenu:", m);
  msg<void>(m, "release");
}
void title(const std::string& t) {
  if (!item()) return;
  Pool pool;
  msg<void, id>(msg(item(), "button"), "setTitle:", str(t));
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
void show(const std::string&, const std::vector<Entry>&) {}
void title(const std::string&) {}
void dock(bool) {}
void remove() {}
#endif
}  // namespace bar

// ============================================================ la ventana
enum BarAct { B_STOP = 1, B_CANCEL = 2 };
const int COUNTDOWNS[] = {0, 3, 5, 10};
const int LIMITS[] = {0, 60, 5 * 60, 10 * 60, 15 * 60};

class Form1 : public FormDesign {
public:
  std::vector<rec::Clip> clips;
  rec::ClipsView* view = nullptr;
  rec::Recorder recorder;
  double countdown_until = 0;   // > 0: contando antes de grabar
  bool waiting = false, demo = false, cancel = false, smoke = false;
  std::string message;
  double message_until = 0;

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }

  Form1() {
    if (fl_getenv("DMS_RECORDER_SELFTEST")) std::exit(rec::selftest());
    if (fl_getenv("DMS_RECORDER_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_RECORDER_SHOT")) { set_fonts(); std::exit(shots(d)); }
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
    Top->resizable(nullptr);
    resizable(Board);
    view = new rec::ClipsView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    view->clips = &clips;
    view->on_act = [](int act, int n) { if (self()) self()->clip_act(act, n); };
    AreaKind->items({tx::AREA_FULL, tx::AREA_1080, tx::AREA_720, tx::AREA_VERTICAL});
    AreaKind->index(rec::AR_FULL);
    Countdown->items({tx::CD_NONE, tx::CD_3, tx::CD_5, tx::CD_10});
    Countdown->index(1);
    Limit->items({tx::LIMIT_NONE, tx::LIMIT_1, tx::LIMIT_5, tx::LIMIT_10, tx::LIMIT_15});
    Limit->index(0);
    Mic->checked(true);
    Clicks->checked(true);
    Cursor->checked(true);
  }

  void form_create() override {
    set_fonts();
    setup();
    bar::handler() = [](int t) { if (self()) self()->bar_act(t); };
    reload();
    refresh();
    // DMS_RECORDER_SMOKE=1: graba 2 s sola (sin cuenta atrás) y comprueba que
    // la ventana vuelve con la grabación en la lista (con DMS_RECORDER_DIR).
    if (fl_getenv("DMS_RECORDER_SMOKE")) {
      smoke = true;
      Countdown->index(0);
      Mic->checked(false);
      Fl::add_timeout(0.5, [](void*) {
        if (!self()) return;
        size_t before = self()->clips.size();
        self()->start();
        bool ok = self()->shown() && self()->clips.size() == before + 1 && self()->clips[0].info.seconds > 1;
        std::printf("smoke %s: %s %.2f s\n", ok ? "ok" : "FAIL", self()->recorder.file.c_str(),
                    self()->clips.empty() ? 0.0 : self()->clips[0].info.seconds);
        std::fflush(stdout);
        std::exit(ok ? 0 : 1);
      });
    }
  }
  void form_close() override {
    if (recorder.running()) recorder.stop();
    bar::remove();
  }

  // ---- la lista y las miniaturas
  void reload() {
    for (auto& c : clips) delete c.thumb;
    clips = rec::list_clips(rec::folder());
    for (auto& c : clips) {
      Fl_PNG_Image png(rec::thumb_path(c.name).c_str());
      if (png.w() > 0) c.thumb = (Fl_RGB_Image*)png.copy();
    }
    view->redraw();
    // Las que faltan, en otro hilo (QuickLook tarda un poco).
    std::vector<std::pair<std::string, std::string>> missing;
    for (const auto& c : clips)
      if (!c.thumb) missing.push_back({c.path, c.name});
    if (!missing.empty() && !demo) {
      std::thread([missing] {
        for (const auto& m : missing) rec::make_thumb(m.first, m.second);
        Fl::awake([](void*) { if (self()) self()->load_thumbs(); }, nullptr);
      }).detach();
    }
  }
  void load_thumbs() {
    for (auto& c : clips) {
      if (c.thumb) continue;
      Fl_PNG_Image png(rec::thumb_path(c.name).c_str());
      if (png.w() > 0) c.thumb = (Fl_RGB_Image*)png.copy();
    }
    view->redraw();
  }

  void say(const std::string& m) {
    message = m;
    message_until = rec::now_s() + 5;
    refresh();
  }
  void refresh() {
    if (!message.empty() && rec::now_s() < message_until) Status->text(" " + message);
    else Status->text(" " + rec::fmt(tx::STATUS, {std::to_string(clips.size()), rec::folder_shown()}));
    view->redraw();
  }

  // ---- grabar
  rec::Options options() const {
    rec::Options o;
    o.area = AreaKind->index() < 0 ? 0 : AreaKind->index();
    o.mic = Mic->checked();
    o.clicks = Clicks->checked();
    o.cursor = Cursor->checked();
    o.limit_s = LIMITS[std::max(0, Limit->index())];
    if (smoke) o.limit_s = 2;
    return o;
  }
  void start() {
    if (recorder.running() || waiting) return;
    fl_make_path(rec::folder().c_str());
    int cd = COUNTDOWNS[std::max(0, Countdown->index())];
    cancel = false;
    waiting = true;
    countdown_until = rec::now_s() + cd;
    // La ventana se esconde para no salir en el vídeo.
    hide();
    bar::dock(false);
    bar::show(cd ? rec::fmt(tx::BAR_COUNTDOWN, {std::to_string(cd)}) : "🔴",
              {{tx::BAR_STOP, B_STOP, true, false}, {"", 0, true, true}, {tx::BAR_CANCEL, B_CANCEL, true, false}});
    // Sin ventanas, Fl::run terminaría: aquí sigue la app hasta que se para.
    while (waiting || recorder.running()) {
      tick_recording();
      Fl::wait(0.25);
    }
    finish();
  }
  // Cada cuarto de segundo: la cuenta atrás, el tiempo y el límite.
  void tick_recording() {
    double now = rec::now_s();
    if (waiting) {
      if (cancel) { waiting = false; return; }
      if (now < countdown_until) {
        bar::title(rec::fmt(tx::BAR_COUNTDOWN, {std::to_string((int)std::ceil(countdown_until - now))}));
        return;
      }
      waiting = false;
      rec::Area a = rec::area_for(options().area, Fl::w(), Fl::h());
      std::string path = rec::folder() + "/" + rec::new_name(std::time(nullptr), ".mov");
#ifndef __APPLE__
      path = path.substr(0, path.size() - 4) + ".mp4";
#endif
      if (!recorder.start(options(), a, path)) return;
    }
    if (recorder.running()) {
      if (cancel) {
        recorder.stop();
        std::remove(recorder.file.c_str());
        return;
      }
      if (recorder.finished_by_itself()) return;
      bar::title("🔴 " + rec::clock_text(now - recorder.started));
    }
  }
  void finish() {
    bar::remove();
    bar::dock(true);
    show();
    reload();
    if (!recorder.error.empty()) say(recorder.error);
    else if (cancel) say(tx::CANCELLED);
    else {
      view->selected = 0;
      say(rec::fmt(tx::SAVED, {recorder.file.substr(recorder.file.find_last_of("/\\") + 1)}));
    }
  }
  void bar_act(int t) {
    if (t == B_CANCEL) cancel = true;
    if (t == B_STOP) {
      if (waiting) cancel = true;
      else recorder.stop();
    }
  }

  void clip_act(int act, int n) {
    if (n < 0 || n >= (int)clips.size()) return;
    const rec::Clip& c = clips[(size_t)n];
    view->selected = n;
    if (act == 1) rec::open_file(c.path);
    else if (act == 2) rec::reveal(c.path);
    else if (act == 3) {
      // YouTube: la página de subida y el vídeo en el Finder, para arrastrarlo.
      fl_open_uri("https://www.youtube.com/upload");
      rec::reveal(c.path);
      say(tx::YOUTUBE_HINT);
      return;
    } else if (act == 4) {
      if (!fl_choice("%s", tx::BTN_NO, tx::BTN_YES, nullptr, rec::fmt(tx::ASK_DELETE, {c.name}).c_str())) return;
      std::string name = c.name;
      if (rec::trash(c.path)) {
        std::remove(rec::thumb_path(name).c_str());
        view->selected = -1;
        reload();
        say(tx::DELETED);
      }
      return;
    }
    refresh();
  }

  // ---- eventos del diseño
  void BtnRecord_click() override { start(); }
  void BtnFolder_click() override {
    fl_make_path(rec::folder().c_str());
    rec::open_file(rec::folder());
  }
  void Tick_timer() override {
    // Si alguien deja o borra vídeos en la carpeta, la lista se pone al día.
    static double last = 0;
    if (rec::now_s() - last > 5 && !recorder.running() && !demo) {
      last = rec::now_s();
      auto now = rec::list_clips(rec::folder());
      bool same = now.size() == clips.size();
      for (size_t i = 0; same && i < now.size(); i++) same = now[i].path == clips[i].path && now[i].bytes == clips[i].bytes;
      if (!same) reload();
    }
    refresh();
  }
  void Menu1_click(const std::string& item) override {
    if (item == tx::MP_RECORD) start();
    else if (item == tx::MP_FOLDER) BtnFolder_click();
    else if (item == tx::MP_QUIT) {
      form_close();
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
    clips.clear();
    const char* names[] = {tx::DEMO_1, tx::DEMO_2, tx::DEMO_3, tx::DEMO_4, tx::DEMO_5};
    const double secs[] = {754, 412, 58, 1290, 186};
    const int ws[] = {1920, 1920, 1080, 2560, 1280};
    const int hs[] = {1080, 1080, 1920, 1440, 720};
    for (int i = 0; i < 5; i++) {
      rec::Clip c;
      c.name = names[i];
      c.path = rec::folder() + "/" + c.name;
      c.info.seconds = secs[i];
      c.info.width = ws[i];
      c.info.height = hs[i];
      c.bytes = (long long)(secs[i] * 1.9e6);
      clips.push_back(c);
    }
    AreaKind->index(rec::AR_1080);
    Countdown->index(1);
    view->selected = 0;
    refresh();
  }
  static int draw_menu(int x, int y, const std::vector<bar::Entry>& m) {
    const int rowh = 34, seph = 12;
    fl_font(FL_HELVETICA, 16);
    int w = 260, h = 12;
    for (const auto& e : m) {
      w = std::max(w, (int)fl_width(e.title.c_str()) + 50);
      h += e.sep ? seph : rowh;
    }
    for (int k = 6; k >= 1; k--) {
      fl_color(fl_rgb_color((uchar)(40 - 4 * k), (uchar)(52 - 4 * k), (uchar)(80 - 4 * k)));
      fl_rounded_rectf(x - k, y - k + 4, w + 2 * k, h + 2 * k, 14 + k);
    }
    rec::round_box(x, y, w, h, 14, rec::rgb(0xf3f3f5), rec::rgb(0xc4c4ca));
    int yy = y + 6;
    for (size_t i = 0; i < m.size(); i++) {
      if (m[i].sep) {
        fl_color(rec::rgb(0xd8d8dc));
        fl_line(x + 16, yy + seph / 2, x + w - 16, yy + seph / 2);
        yy += seph;
        continue;
      }
      if (i == 0) {
        fl_color(rec::rgb(0x2f6fea));
        fl_rounded_rectf(x + 6, yy, w - 12, rowh, 8);
      }
      fl_color(i == 0 ? FL_WHITE : rec::rgb(0x1d1d1f));
      fl_draw(m[i].title.c_str(), x + 22, yy + 23);
      yy += rowh;
    }
    return x + w;
  }
  // El escritorio mientras graba: la zona de 16:9 marcada y el menú.
  void desk(const std::string& file, bool menu_open) {
    const int W = 1600, H = 1000, BarH = 40;
    Fl_Image_Surface surf(W, H, 0);
    Fl_Surface_Device::push_current(&surf);
    for (int yy = 0; yy < H; yy++) {
      double t = yy / (double)H;
      fl_color(fl_rgb_color((uchar)(40 + 30 * t), (uchar)(30 + 50 * t), (uchar)(70 + 90 * t)));
      fl_line(0, yy, W, yy);
    }
    // La zona que se graba (como en el centro de la pantalla).
    rec::Area a = rec::area_for(rec::AR_1080, W, H - BarH);
    a.y += BarH;
    fl_color(fl_rgb_color(255, 255, 255));
    fl_line_style(FL_DASH, 3);
    fl_rect(a.x + 60, a.y + 40, a.w - 120, a.h - 80);
    fl_line_style(0);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_draw(tx::DESK_AREA, a.x + 60, a.y + 26);
    fl_color(rec::rgb(0xdedfe6));
    fl_rectf(0, 0, W, BarH);
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(rec::rgb(0x1d1d1f));
    fl_draw("17:02", W - 70, 26);
    std::string t = "🔴 4:12";
    fl_font(FL_HELVETICA, 16);
    int iw = (int)fl_width(t.c_str()) + 20, ix = W - 700;
    fl_color(rec::rgb(0xc4c6d0));
    fl_rounded_rectf(ix - 10, 5, iw, BarH - 10, 8);
    fl_color(rec::rgb(0x1d1d1f));
    fl_draw(t.c_str(), ix, 26);
    if (menu_open)
      draw_menu(ix - 10, BarH + 4,
                {{tx::BAR_STOP, B_STOP, true, false}, {"", 0, true, true}, {tx::BAR_CANCEL, B_CANCEL, true, false}});
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    fl_write_png(file.c_str(), img);
    delete img;
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1600, 1000);
    render_to(dir + "/window.png");
    desk(dir + "/recording.png", true);
    view->selected = 2;
    say(rec::fmt(tx::SAVED, {tx::DEMO_3}));
    render_to(dir + "/saved.png");
    clips.clear();
    message.clear();
    refresh();
    render_to(dir + "/empty.png");
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1100, 720);
    int f = 0;
    auto chk = [&](bool ok, const char* what) { if (!ok) { std::printf("FAIL %s\n", what); f++; } };
    chk(clips.size() == 5 && AreaKind->size() >= 4 && Countdown->size() >= 4 && Limit->size() >= 5, "listas");
    Limit->index(1);
    Mic->checked(false);
    rec::Options o = options();
    chk(o.limit_s == 60 && !o.mic && o.clicks && o.area == rec::AR_1080, "opciones");
    render_to("");
    chk(view->hits.size() >= clips.size() * 5, "tarjetas dibujadas");
    // Clic de verdad en una tarjeta (fuera de los botones): la elige.
    for (const auto& h : view->hits)
      if (h.act == 0 && h.idx == 3) {
        Fl::e_x = h.x + h.w - 20;
        Fl::e_y = h.y + h.h - 60;
        view->handle(FL_PUSH);
        break;
      }
    chk(view->selected == 3, "clic en una tarjeta");
    // Los botones ganan a la tarjeta.
    bool ok = true;
    for (const auto& h : view->hits)
      if (h.act >= 1) {
        int i = view->hit_at(h.x + h.w / 2, h.y + h.h / 2);
        ok = ok && i >= 0 && view->hits[(size_t)i].act == h.act;
      }
    chk(ok, "los botones ganan el clic");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
