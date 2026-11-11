// Una demo de DMarlon Studio en español y en inglés (scripts/build_demos.py).
//
// La demo se compila dos veces, una por idioma (-DDMS_LANG y -DDMS_OTHER), y
// los dos ejecutables van juntos. dms_lang_start() abre el del idioma
// elegido: el que se guardó en «DMarlon Studio Demos/lang» (el mismo para
// todas las demos) o, la primera vez, el del sistema; y añade el menú
// Idioma / Language a la barra de menú de la ventana. Al cambiar, las
// ventanas se cierran como siempre y dms_lang_finish() abre el otro.
#pragma once

#include <FL/Fl.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Window.H>
#include <FL/fl_ask.H>

#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#include <direct.h>
#else
#include <sys/stat.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#include <crt_externs.h>
#include <mach-o/dyld.h>
#endif

#ifndef DMS_LANG
#define DMS_LANG "es"
#endif
#ifndef DMS_OTHER
#define DMS_OTHER "app-en"
#endif

static std::string dms_lang_target;

static std::string dms_lang_dir() {
#ifdef _WIN32
  const char* a = std::getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos";
#elif defined(__APPLE__)
  const char* h = std::getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos";
#else
  const char* h = std::getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos";
#endif
}

static std::string dms_lang_file() {
#ifdef _WIN32
  return dms_lang_dir() + "\\lang";
#else
  return dms_lang_dir() + "/lang";
#endif
}

static std::string dms_lang_system() {
#ifdef __APPLE__
  std::string r = "en";
  CFArrayRef langs = CFLocaleCopyPreferredLanguages();
  if (langs) {
    if (CFArrayGetCount(langs) > 0) {
      char buf[64] = {0};
      CFStringRef s = (CFStringRef)CFArrayGetValueAtIndex(langs, 0);
      if (CFStringGetCString(s, buf, sizeof(buf), kCFStringEncodingUTF8) &&
          (buf[0] == 'e' || buf[0] == 'E') && (buf[1] == 's' || buf[1] == 'S'))
        r = "es";
    }
    CFRelease(langs);
  }
  return r;
#elif defined(_WIN32)
  return (GetUserDefaultUILanguage() & 0x3FF) == 0x0A ? "es" : "en";
#else
  const char* l = std::getenv("LANG");
  return l && l[0] == 'e' && l[1] == 's' ? "es" : "en";
#endif
}

static std::string dms_lang_wanted() {
  std::ifstream f(dms_lang_file());
  std::string v;
  if (f) std::getline(f, v);
  while (!v.empty() && (v.back() == '\r' || v.back() == '\n' || v.back() == ' ')) v.pop_back();
  return v == "es" || v == "en" ? v : dms_lang_system();
}

static std::string dms_lang_self() {
#ifdef _WIN32
  char buf[MAX_PATH];
  DWORD n = GetModuleFileNameA(nullptr, buf, MAX_PATH);
  return std::string(buf, n);
#elif defined(__APPLE__)
  char buf[4096];
  uint32_t size = sizeof(buf);
  return _NSGetExecutablePath(buf, &size) == 0 ? std::string(buf) : std::string();
#else
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
  return n > 0 ? std::string(buf, n) : std::string();
#endif
}

static std::string dms_lang_other() {
  std::string self = dms_lang_self();
  size_t slash = self.find_last_of("/\\");
  return (slash == std::string::npos ? std::string() : self.substr(0, slash + 1)) + DMS_OTHER;
}

static bool dms_lang_exists(const std::string& p) {
  std::ifstream f(p);
  return (bool)f;
}

// En macOS y Linux, el otro ejecutable ocupa este proceso; en Windows, se
// abre y este termina. Los argumentos (p. ej. --console) pasan tal cual.
static void dms_lang_launch(const std::string& exe) {
#ifdef _WIN32
  // Lo que va detrás del nombre del programa en la línea de órdenes.
  std::string args;
  const char* cl = GetCommandLineA();
  if (cl) {
    const char* p = cl;
    if (*p == '"') {
      p++;
      while (*p && *p != '"') p++;
      if (*p) p++;
    } else {
      while (*p && *p != ' ' && *p != '\t') p++;
    }
    while (*p == ' ' || *p == '\t') p++;
    args = p;
  }
  ShellExecuteA(nullptr, "open", exe.c_str(), args.empty() ? nullptr : args.c_str(), nullptr, SW_SHOWNORMAL);
#elif defined(__APPLE__)
  char** argv = *_NSGetArgv();
  int argc = *_NSGetArgc();
  std::vector<char*> v;
  v.push_back(const_cast<char*>(exe.c_str()));
  for (int i = 1; i < argc; i++) v.push_back(argv[i]);
  v.push_back(nullptr);
  execv(exe.c_str(), v.data());
#else
  execl(exe.c_str(), exe.c_str(), (char*)nullptr);
#endif
}

static Fl_Menu_Bar* dms_lang_find_bar(Fl_Group* g) {
  for (int i = 0; i < g->children(); i++) {
    Fl_Widget* w = g->child(i);
    if (auto* b = dynamic_cast<Fl_Menu_Bar*>(w)) return b;
    if (auto* sub = w->as_group())
      if (Fl_Menu_Bar* b = dms_lang_find_bar(sub)) return b;
  }
  return nullptr;
}

static void dms_lang_pick(Fl_Widget*, void* data) {
  std::string code = (const char*)data;
  if (code == DMS_LANG) return;
  bool es = std::string(DMS_LANG) == "es";
  int ok = fl_choice("%s", es ? "Cancelar" : "Cancel", es ? "Aceptar" : "OK", nullptr,
                     es ? "La aplicación se volverá a abrir en English. Lo que no esté guardado se perderá."
                        : "The app will reopen in Español. Anything not saved will be lost.");
  if (ok != 1) return;
#ifdef _WIN32
  _mkdir(dms_lang_dir().c_str());
#else
  mkdir(dms_lang_dir().c_str(), 0755);
#endif
  std::ofstream(dms_lang_file()) << code;
  dms_lang_target = dms_lang_other();
  // Se cierran como con su botón (la demo guarda lo suyo) y Fl::run termina.
  for (int n = 0; n < 50 && Fl::first_window(); n++) {
    Fl_Window* w = Fl::first_window();
    w->do_callback();
    if (w->shown()) w->hide();
  }
}

static void dms_lang_add_menu(void*) {
  Fl_Window* w = Fl::first_window();
  if (!w) return;
  Fl_Menu_Bar* bar = dms_lang_find_bar(w);
  if (!bar) {
    // Sin barra de menú: una arriba, y la ventana crece para hacerle sitio.
    const int h = 26;
    w->size(w->w(), w->h() + h);
    for (int i = 0; i < w->children(); i++) {
      Fl_Widget* c = w->child(i);
      c->position(c->x(), c->y() + h);
    }
    w->begin();
    bar = new Fl_Menu_Bar(0, 0, w->w(), h);
    w->end();
  }
  bool es = std::string(DMS_LANG) == "es";
  std::string root = es ? "Idioma/" : "Language/";
  bar->add((root + "Español").c_str(), 0, dms_lang_pick, (void*)"es",
           FL_MENU_RADIO | (es ? FL_MENU_VALUE : 0));
  bar->add((root + "English").c_str(), 0, dms_lang_pick, (void*)"en",
           FL_MENU_RADIO | (es ? 0 : FL_MENU_VALUE));
  bar->redraw();
}

static void dms_lang_start() {
  if (dms_lang_wanted() != DMS_LANG) {
    std::string other = dms_lang_other();
    if (dms_lang_exists(other)) {
      dms_lang_launch(other);
#ifdef _WIN32
      std::exit(0);
#endif
    }
  }
  Fl::add_timeout(0.0, dms_lang_add_menu);
}

static int dms_lang_finish(int code) {
  if (!dms_lang_target.empty()) dms_lang_launch(dms_lang_target);
  return code;
}
