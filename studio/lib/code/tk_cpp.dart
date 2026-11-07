import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_codegen.dart';
import 'tk_model.dart';
import 'tk_unit.dart';

/// Genera una aplicación de escritorio en C++ con FLTK: dms.h (los
/// componentes, subclases de FLTK con métodos al estilo de Delphi), design.h
/// (la clase FormDesign que crea la ventana) y main.cpp, que incluye el
/// código del usuario (Form1.cpp) tal cual: sus líneas son las de los
/// errores del compilador.
class TkCpp {
  TkCpp._();

  /// Alto de la barra de menús de FLTK.
  static const menuHeight = 25;

  static String _s(String v) => jsonEncode(v);

  static String? _color(Object? v) => TkCodegen.color(v);

  /// Los métodos (nombre → argumento) que el diseño llama.
  static Map<String, String> handlers(TkDesign d) {
    final out = <String, String>{};
    for (final MapEntry(key: k, value: m) in d.events.entries) {
      final e = tkFormEvents.where((e) => e.key == k).firstOrNull;
      out[m] = e?.param ?? '';
    }
    for (final w in d.widgets) {
      for (final MapEntry(key: k, value: m) in w.events.entries) {
        final e = w.component.events.where((e) => e.key == k).firstOrNull;
        out.putIfAbsent(m, () => e?.param ?? '');
      }
    }
    return out;
  }

  static String _class(String kind) => switch (kind) {
    'Label' => 'DmsLabel',
    'Button' => 'DmsButton',
    'Entry' => 'DmsEntry',
    'Password' => 'DmsPassword',
    'Image' => 'DmsImage',
    'Text' => 'DmsText',
    'Checkbutton' => 'DmsCheck',
    'Radiobutton' => 'DmsRadio',
    'Listbox' => 'DmsList',
    'Combobox' => 'DmsCombo',
    'Scale' => 'DmsScale',
    'Frame' => 'DmsFrame',
    'Progressbar' => 'DmsProgress',
    'PageControl' => 'DmsPages',
    'StatusBar' => 'DmsStatus',
    'Menu' => 'DmsMenu',
    'Timer' => 'DmsTimer',
    'OpenDialog' => 'DmsOpenDialog',
    'SaveDialog' => 'DmsSaveDialog',
    _ => 'DmsLabel',
  };

  static const _nonVisual = {'Timer', 'OpenDialog', 'SaveDialog', 'Menu'};

  /// design.h: la clase FormDesign.
  static String design(TkDesign d) {
    final problems = d.problems();
    if (problems.isNotEmpty) throw UserError(problems.join('\n'));
    final menu = d.menu;
    final top = menu == null ? 0 : menuHeight;
    final members = StringBuffer();
    final build = StringBuffer();
    final statics = StringBuffer();
    final handlerNames = handlers(d);

    void style(String n, TkWidget w) {
      final bg = _color(w.props['bg']);
      final fg = _color(w.props['fg']);
      if (bg != null) build.writeln('    $n->bg(${_s(bg)});');
      if (fg != null) build.writeln('    $n->fg(${_s(fg)});');
      final size = w.props['font_size'];
      if (size is int && size > 0) build.writeln('    $n->size($size);');
      if (w.props['font_bold'] == true) build.writeln('    $n->bold();');
    }

    String callback(TkWidget w, String key, String call) {
      final m = w.events[key];
      if (m == null) return '';
      final fn = 'dms_cb_${w.name}_$key';
      statics.writeln(
        '  static void $fn(Fl_Widget* widget, void* self) {\n'
        '    auto* f = static_cast<FormDesign*>(self);\n'
        '    (void)widget;\n'
        '    ${call.replaceAll('%M', 'f->$m')}\n'
        '  }',
      );
      return fn;
    }

    void create(TkWidget w, int ax, int ay) {
      final n = w.name;
      final cls = _class(w.kind);
      if (_nonVisual.contains(w.kind)) {
        if (w.kind == 'Menu') {
          members.writeln('  $cls* $n = nullptr;');
          build.writeln('    $n = new $cls(0, 0, ${d.width}, $menuHeight);');
          for (final path in _paths(tkMenuItems(w.text('items')))) {
            build.writeln('    $n->item(${_s(path)});');
          }
          final cb = callback(
            w,
            'command',
            '%M(static_cast<DmsMenu*>(widget)->chosen());',
          );
          if (cb.isNotEmpty) build.writeln('    $n->callback($cb, this);');
        } else if (w.kind == 'Timer') {
          members.writeln('  $cls $n;');
          final m = w.events['command'];
          build.writeln(
            '    $n.interval(${TkCodegen.interval(w) / 1000});'
            '${m == null ? '' : ' $n.on([this] { $m(); });'}',
          );
          if (w.props['enabled'] != false) {
            build.writeln('    dms_start_timers.push_back(&$n);');
          }
        } else {
          members.writeln('  $cls $n;');
          for (final k in ['title', 'filter', 'filename']) {
            final v = w.text(k);
            if (v.isNotEmpty) build.writeln('    $n.$k(${_s(v)});');
          }
          final m = w.events['select'];
          if (m != null) {
            build.writeln(
              '    $n.on([this](const std::string& path) { $m(path); });',
            );
          }
        }
        return;
      }
      final x = ax, y = ay;
      final (bw, bh) = w.kind == 'StatusBar'
          ? (d.width, w.height)
          : (w.width, w.height);
      final bx = w.kind == 'StatusBar' ? 0 : x;
      final by = w.kind == 'StatusBar' ? top + d.height - w.height : y;
      members.writeln('  $cls* $n = nullptr;');
      build.writeln('    $n = new $cls($bx, $by, $bw, $bh);');
      final text = w.props['text'];
      switch (w.kind) {
        case 'Label' ||
            'Button' ||
            'Checkbutton' ||
            'Radiobutton' ||
            'StatusBar':
          if (text is String && text.isNotEmpty) {
            build.writeln('    $n->text(${_s(text)});');
          }
        case 'Entry' || 'Text' || 'Combobox':
          if (text is String && text.isNotEmpty && w.kind != 'Combobox') {
            build.writeln('    $n->text(${_s(text)});');
          }
        case 'Password':
          break;
        case 'Image':
          final file = w.text('file');
          if (file.isNotEmpty) build.writeln('    $n->load(${_s(file)});');
        case 'Scale':
          final from = w.props['from'] ?? 0, to = w.props['to'] ?? 100;
          build.writeln(
            '    $n->range($from, $to); $n->step(${w.props['resolution'] ?? 1});'
            ' $n->value(${w.props['value'] ?? 0});',
          );
        case 'Progressbar':
          build.writeln(
            '    $n->maximum(${w.props['maximum'] ?? 100});'
            ' $n->value(${w.props['value'] ?? 0});',
          );
      }
      if (w.kind == 'Label') {
        final anchor = w.text('anchor');
        if (anchor == 'w') build.writeln('    $n->left();');
        if (anchor == 'e') build.writeln('    $n->right();');
      }
      if (w.kind == 'Checkbutton' || w.kind == 'Radiobutton') {
        if (w.props['checked'] == true) build.writeln('    $n->checked(true);');
      }
      if (w.kind == 'Listbox' || w.kind == 'Combobox') {
        final items = TkCodegen.items(w);
        if (items.isNotEmpty) {
          build.writeln('    $n->items({${items.map(_s).join(', ')}});');
        }
        if (w.kind == 'Combobox' && text is String && text.isNotEmpty) {
          build.writeln('    $n->text(${_s(text)});');
        }
      }
      if (w.props['state'] == 'disabled') {
        build.writeln('    $n->enabled(false);');
      }
      style(n, w);
      // Eventos.
      switch (w.kind) {
        case 'Button' || 'Checkbutton' || 'Radiobutton':
          final cb = callback(w, 'command', '%M();');
          if (cb.isNotEmpty) build.writeln('    $n->callback($cb, this);');
        case 'Entry' || 'Password':
          final cb = callback(w, 'enter_key', '%M();');
          if (cb.isNotEmpty) {
            build.writeln(
              '    $n->when(FL_WHEN_ENTER_KEY_ALWAYS); $n->callback($cb, this);',
            );
          }
        case 'Listbox':
          final sel = w.events['select'], dbl = w.events['double'];
          if (sel != null || dbl != null) {
            final cb = 'dms_cb_${n}_list';
            statics.writeln(
              '  static void $cb(Fl_Widget*, void* self) {\n'
              '    auto* f = static_cast<FormDesign*>(self);\n'
              '    ${dbl == null ? '' : 'if (Fl::event_clicks()) { f->$dbl(); return; }'}\n'
              '    ${sel == null ? '' : 'f->$sel();'}\n'
              '  }',
            );
            build.writeln('    $n->callback($cb, this);');
          }
        case 'Combobox':
          final cb = callback(w, 'select', '%M();');
          if (cb.isNotEmpty) build.writeln('    $n->callback($cb, this);');
        case 'Scale':
          final cb = callback(
            w,
            'command',
            '%M(static_cast<Fl_Valuator*>(widget)->value());',
          );
          if (cb.isNotEmpty) build.writeln('    $n->callback($cb, this);');
      }
      // Contenedores: sus componentes van dentro (FLTK usa coordenadas de
      // la ventana).
      if (w.kind == 'Frame') {
        build.writeln('    $n->begin();');
        for (final c in d.widgets.where((c) => c.parent == n)) {
          create(c, x + c.x, y + c.y);
        }
        build.writeln('    $n->end();');
      } else if (w.kind == 'PageControl') {
        final pages = tkPages(w);
        for (final (i, title) in pages.indexed) {
          build.writeln('    $n->page(${_s(title)});');
          for (final c in d.widgets.where(
            (c) => c.parent == n && (c.page ?? 0) == i,
          )) {
            create(c, x + c.x, y + c.y);
          }
          build.writeln('    $n->done();');
        }
        build.writeln('    $n->end();');
      }
    }

    for (final w in d.widgets.where((w) => w.parent == null)) {
      create(w, w.x, w.y + top);
    }
    final bg = _color(d.prop(tkFormBg)) ?? '#f0f0f0';
    final virtuals = [
      for (final MapEntry(key: m, value: param) in handlerNames.entries)
        if (m != 'form_create' && m != 'form_close')
          '  virtual void $m(${CppUnit.typed(param)}) {}',
    ];
    return '''// Generated by DMarlon Studio from the design. Do not edit.
#pragma once
#include "dms.h"

class FormDesign : public DmsForm {
public:
$members
  FormDesign() : DmsForm(${d.width}, ${d.height + top}, ${_s(d.title)}) {
    bg(${_s(bg)});
${d.appIcon == null ? '' : '    app_icon(${_s(d.appIcon!)});\n'}
${d.prop(tkFormResizable) == true ? '    resizable(this);\n' : ''}${d.prop(tkFormPosition) == 'manual' ? '    position(${TkPy.integer(d.prop(tkFormLeft))}, ${TkPy.integer(d.prop(tkFormTop))});\n' : ''}    begin();
$build    end();
${d.events['close'] == null ? '' : '    on_close([this] { ${d.events['close']}(); });\n'}${d.events['create'] == null ? '' : '    on_create([this] { ${d.events['create']}(); });\n'}  }

${virtuals.join('\n')}

private:
$statics};
''';
  }

  static List<String> _paths(List<TkMenuItem> items, [String prefix = '']) => [
    for (final i in items)
      if (i.separator)
        '$prefix-'
      else if (i.items.isEmpty)
        i.path
      else
        ..._paths(i.items, '${i.path}/'),
  ];

  /// main.cpp: incluye el código del usuario y abre la ventana.
  static String main(String form) =>
      '// Generated by DMarlon Studio. Do not edit.\n'
      '#include "design.h"\n'
      '#include "$form.cpp"\n\n'
      'int main(int argc, char** argv) {\n'
      '  return dms_run<$form>(argc, argv);\n'
      '}\n';

  /// Todos los archivos (nombre → contenido).
  static Map<String, String> files(TkDesign d, String code) {
    final unit = code.replaceAll('\r\n', '\n');
    if (!const CppUnit().hasClass(unit, d.name)) {
      throw UserError(
        tr('El código debe definir «class {0} : public FormDesign».', [d.name]),
      );
    }
    return {
      'dms.h': tkCppRuntime,
      'design.h': design(d),
      '${d.name}.cpp': unit,
      'main.cpp': main(d.name),
      'Makefile':
          '# Generated by DMarlon Studio.\n'
          'APP = app\n'
          'CXXFLAGS = -std=c++17 -O2 \$(shell fltk-config --use-images --cxxflags)\n'
          'LDFLAGS = \$(shell fltk-config --use-images --ldflags)\n\n'
          '\$(APP): main.cpp design.h dms.h ${d.name}.cpp\n'
          '\t\$(CXX) \$(CXXFLAGS) main.cpp -o \$(APP) \$(LDFLAGS)\n\n'
          'run: \$(APP)\n'
          '\t./\$(APP)\n',
    };
  }

  /// Lo que se ve en la pestaña «C++ generado».
  static String preview(TkDesign d, String code) =>
      '${design(d)}\n// ---- ${d.name}.cpp\n\n${code.trimRight()}\n';
}

/// dms.h: los componentes de DMarlon Studio sobre FLTK. Cada uno es la
/// clase de FLTK de siempre con métodos al estilo de Delphi (text, value,
/// checked, enabled, visible, items, index…).
const tkCppRuntime =
    r'''// DMarlon Studio runtime for FLTK. Generated: do not edit.
#pragma once
#include <FL/Fl.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Input_Choice.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/Fl_Progress.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/Fl_Image.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <initializer_list>
#include <sstream>
#include <string>
#include <vector>

/// Un color #rrggbb de FLTK.
inline Fl_Color dms_color(const std::string& hex) {
  unsigned r = 0, g = 0, b = 0;
  if (hex.size() == 7 && hex[0] == '#') std::sscanf(hex.c_str() + 1, "%02x%02x%02x", &r, &g, &b);
  return fl_rgb_color((uchar)r, (uchar)g, (uchar)b);
}

/// Lo común: enabled, visible, bg, fg, size, bold.
template <class W>
class Dms : public W {
public:
  Dms(int x, int y, int w, int h) : W(x, y, w, h) {}
  bool enabled() const { return this->active(); }
  void enabled(bool on) { if (on) this->activate(); else this->deactivate(); }
  bool visible() const { return W::visible(); }
  void visible(bool on) { if (on) this->show(); else this->hide(); }
  void bg(const std::string& c) {
    if (this->box() == FL_NO_BOX) this->box(FL_FLAT_BOX);
    this->color(dms_color(c));
    this->redraw();
  }
  void fg(const std::string& c) { this->labelcolor(dms_color(c)); this->redraw(); }
  void size(int s) { this->labelsize(s); this->redraw(); }
  void bold() { this->labelfont(FL_HELVETICA_BOLD); }
  using W::size;
};

/// Texto de una etiqueta o un botón (lo copia FLTK).
template <class W>
class DmsLabelled : public Dms<W> {
public:
  DmsLabelled(int x, int y, int w, int h) : Dms<W>(x, y, w, h) {}
  std::string text() const { return this->label() ? this->label() : ""; }
  void text(const std::string& s) { this->copy_label(s.c_str()); this->redraw(); }
};

class DmsLabel : public DmsLabelled<Fl_Box> {
public:
  DmsLabel(int x, int y, int w, int h) : DmsLabelled<Fl_Box>(x, y, w, h) {
    align(FL_ALIGN_INSIDE | FL_ALIGN_CENTER | FL_ALIGN_WRAP);
  }
  void left() { align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT | FL_ALIGN_WRAP); }
  void right() { align(FL_ALIGN_INSIDE | FL_ALIGN_RIGHT | FL_ALIGN_WRAP); }
};

class DmsButton : public DmsLabelled<Fl_Button> {
public:
  DmsButton(int x, int y, int w, int h) : DmsLabelled<Fl_Button>(x, y, w, h) {}
};

class DmsStatus : public DmsLabelled<Fl_Box> {
public:
  DmsStatus(int x, int y, int w, int h) : DmsLabelled<Fl_Box>(x, y, w, h) {
    box(FL_THIN_UP_BOX);
    align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
  }
  void set(const std::string& s) { text(s); }
};

/// Casilla y opción: checked().
template <class W>
class DmsChoiceButton : public DmsLabelled<W> {
public:
  DmsChoiceButton(int x, int y, int w, int h) : DmsLabelled<W>(x, y, w, h) {}
  bool checked() const { return this->value() != 0; }
  void checked(bool on) { if (on) this->setonly(); else this->value(0); }
};

class DmsCheck : public DmsChoiceButton<Fl_Check_Button> {
public:
  DmsCheck(int x, int y, int w, int h) : DmsChoiceButton<Fl_Check_Button>(x, y, w, h) {}
  void checked(bool on) { value(on ? 1 : 0); }
  bool checked() const { return value() != 0; }
};

class DmsRadio : public DmsChoiceButton<Fl_Round_Button> {
public:
  DmsRadio(int x, int y, int w, int h) : DmsChoiceButton<Fl_Round_Button>(x, y, w, h) {
    type(FL_RADIO_BUTTON);
  }
};

/// Campos de texto: text() es su contenido.
template <class W>
class DmsField : public Dms<W> {
public:
  DmsField(int x, int y, int w, int h) : Dms<W>(x, y, w, h) {}
  std::string text() const { return this->value() ? this->value() : ""; }
  void text(const std::string& s) { this->value(s.c_str()); }
  void fg(const std::string& c) { this->textcolor(dms_color(c)); this->redraw(); }
  void size(int s) { this->textsize(s); this->redraw(); }
};

class DmsEntry : public DmsField<Fl_Input> {
public:
  DmsEntry(int x, int y, int w, int h) : DmsField<Fl_Input>(x, y, w, h) {}
};

class DmsPassword : public DmsField<Fl_Secret_Input> {
public:
  DmsPassword(int x, int y, int w, int h) : DmsField<Fl_Secret_Input>(x, y, w, h) {}
};

class DmsText : public DmsField<Fl_Multiline_Input> {
public:
  DmsText(int x, int y, int w, int h) : DmsField<Fl_Multiline_Input>(x, y, w, h) {
    wrap(1);
  }
};

/// Lista: items, index (-1: ninguno) y selected.
class DmsList : public Dms<Fl_Hold_Browser> {
public:
  DmsList(int x, int y, int w, int h) : Dms<Fl_Hold_Browser>(x, y, w, h) {}
  void items(std::initializer_list<std::string> list) { items(std::vector<std::string>(list)); }
  void items(const std::vector<std::string>& list) {
    clear();
    for (const auto& s : list) add(s.c_str());
  }
  void add(const std::string& s) { Fl_Hold_Browser::add(s.c_str()); }
  std::vector<std::string> items() const {
    std::vector<std::string> out;
    for (int i = 1; i <= size(); i++) out.push_back(Fl_Hold_Browser::text(i));
    return out;
  }
  int index() const { return value() - 1; }
  void index(int i) { value(i + 1); }
  std::string selected() const { return value() > 0 ? Fl_Hold_Browser::text(value()) : ""; }
  using Fl_Hold_Browser::add;
};

/// Combo: de solo lectura (Fl_Choice) en todos los casos; text() es la
/// opción elegida.
class DmsCombo : public Dms<Fl_Choice> {
public:
  DmsCombo(int x, int y, int w, int h) : Dms<Fl_Choice>(x, y, w, h) {}
  void items(std::initializer_list<std::string> list) { items(std::vector<std::string>(list)); }
  void items(const std::vector<std::string>& list) {
    clear();
    for (const auto& s : list) {
      std::string safe;
      for (char c : s) {
        if (c == '/' || c == '\\' || c == '&' || c == '_') safe += '\\';
        safe += c;
      }
      Fl_Choice::add(safe.c_str());
    }
    value(-1);
  }
  int index() const { return value(); }
  void index(int i) { value(i); }
  std::string text() const { return value() >= 0 && mvalue() ? mvalue()->label() : ""; }
  void text(const std::string& s) {
    for (int i = 0; i < size(); i++) {
      const Fl_Menu_Item* it = &menu()[i];
      if (it->label() && s == it->label()) { value(i); return; }
    }
  }
  std::string selected() const { return text(); }
};

class DmsScale : public Dms<Fl_Value_Slider> {
public:
  DmsScale(int x, int y, int w, int h) : Dms<Fl_Value_Slider>(x, y, w, h) {
    type(w >= h ? FL_HOR_NICE_SLIDER : FL_VERT_NICE_SLIDER);
  }
};

class DmsProgress : public Dms<Fl_Progress> {
public:
  DmsProgress(int x, int y, int w, int h) : Dms<Fl_Progress>(x, y, w, h) {
    selection_color(dms_color("#2b5797"));
  }
  void value(double v) { Fl_Progress::value((float)v); redraw(); }
  double value() const { return Fl_Progress::value(); }
  void maximum(double v) { Fl_Progress::maximum((float)v); }
};

class DmsFrame : public Dms<Fl_Group> {
public:
  DmsFrame(int x, int y, int w, int h) : Dms<Fl_Group>(x, y, w, h) {
    box(FL_ENGRAVED_BOX);
    end();
  }
};

/// Control de páginas: page() es la activa.
class DmsPages : public Dms<Fl_Tabs> {
public:
  DmsPages(int x, int y, int w, int h) : Dms<Fl_Tabs>(x, y, w, h) {}
  void page(const std::string& title) {
    begin();
    current_ = new Fl_Group(x(), y() + 24, w(), h() - 24);
    current_->copy_label(title.c_str());
    current_->begin();
  }
  void done() {
    if (current_) current_->end();
    current_ = nullptr;
    begin();
  }
  int page() { return find(value()); }
  void page(int i) { if (i >= 0 && i < children()) value(child(i)); }
  using Fl_Tabs::value;

private:
  Fl_Group* current_ = nullptr;
};

class DmsImage : public Dms<Fl_Box> {
public:
  DmsImage(int x, int y, int w, int h) : Dms<Fl_Box>(x, y, w, h) {}
  void load(const std::string& path) {
    Fl_Shared_Image* img = Fl_Shared_Image::get(path.c_str());
    if (!img) return;
    Fl_Image* fit = img->copy(w(), h());
    img->release();
    image(fit);
    redraw();
  }
};

/// Menú: chosen() es la opción pulsada («Archivo/Abrir…»).
class DmsMenu : public Fl_Menu_Bar {
public:
  DmsMenu(int x, int y, int w, int h) : Fl_Menu_Bar(x, y, w, h) {}
  void item(const std::string& path) {
    if (!path.empty() && path.back() == '-') {
      // Un separador: una raya bajo la opción anterior de su mismo menú.
      std::string prefix = path.substr(0, path.size() - 1);
      for (auto it = added_.rbegin(); it != added_.rend(); ++it) {
        if (it->compare(0, prefix.size(), prefix) != 0) continue;
        std::string rest = it->substr(prefix.size());
        int i = find_index((prefix + rest.substr(0, rest.find('/'))).c_str());
        if (i >= 0) mode(i, mode(i) | FL_MENU_DIVIDER);
        break;
      }
      return;
    }
    add(path.c_str());
    added_.push_back(path);
  }
  std::string chosen() {
    char buf[512];
    return item_pathname(buf, sizeof(buf)) == 0 ? std::string(buf) : std::string();
  }

private:
  std::vector<std::string> added_;
};

/// Temporizador: interval en segundos, start() y stop().
class DmsTimer {
public:
  void interval(double s) { seconds_ = s > 0 ? s : 1; }
  double interval() const { return seconds_; }
  void on(std::function<void()> fn) { fn_ = std::move(fn); }
  void start() { if (!running_) { running_ = true; Fl::add_timeout(seconds_, tick, this); } }
  void stop() { running_ = false; Fl::remove_timeout(tick, this); }
  bool enabled() const { return running_; }

private:
  static void tick(void* p) {
    auto* t = static_cast<DmsTimer*>(p);
    if (!t->running_) return;
    Fl::repeat_timeout(t->seconds_, tick, p);
    if (t->fn_) t->fn_();
  }
  double seconds_ = 1;
  bool running_ = false;
  std::function<void()> fn_;
};

/// Diálogos Abrir y Guardar del sistema: execute() da la ruta ("" si se
/// cancela).
class DmsFileDialog {
public:
  explicit DmsFileDialog(bool save) : save_(save) {}
  void title(const std::string& s) { title_ = s; }
  void filter(const std::string& s) {
    // «Texto|*.txt» → «Texto\t*.txt»
    filter_.clear();
    std::istringstream in(s);
    std::string line;
    while (std::getline(in, line)) {
      auto bar = line.find('|');
      if (bar == std::string::npos) continue;
      if (!filter_.empty()) filter_ += "\n";
      std::string pats = line.substr(bar + 1);
      for (auto& c : pats) if (c == ';' || c == ',') c = ' ';
      filter_ += line.substr(0, bar) + "\t" + pats;
    }
  }
  void filename(const std::string& s) { filename_ = s; }
  void on(std::function<void(const std::string&)> fn) { fn_ = std::move(fn); }
  std::string execute() {
    Fl_Native_File_Chooser chooser;
    chooser.type(save_ ? Fl_Native_File_Chooser::BROWSE_SAVE_FILE : Fl_Native_File_Chooser::BROWSE_FILE);
    if (!title_.empty()) chooser.title(title_.c_str());
    if (!filter_.empty()) chooser.filter(filter_.c_str());
    if (!filename_.empty()) chooser.preset_file(filename_.c_str());
    if (save_) chooser.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM);
    if (chooser.show() != 0) return "";
    std::string path = chooser.filename();
    if (fn_) fn_(path);
    return path;
  }

private:
  bool save_;
  std::string title_, filter_, filename_;
  std::function<void(const std::string&)> fn_;
};

class DmsOpenDialog : public DmsFileDialog {
public:
  DmsOpenDialog() : DmsFileDialog(false) {}
};

class DmsSaveDialog : public DmsFileDialog {
public:
  DmsSaveDialog() : DmsFileDialog(true) {}
};

/// Leer y escribir archivos de texto.
inline std::string readText(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  std::ostringstream s;
  s << in.rdbuf();
  return s.str();
}

inline bool writeText(const std::string& path, const std::string& text) {
  std::ofstream out(path, std::ios::binary);
  out << text;
  return bool(out);
}

/// Un número como texto, sin ceros de más.
inline std::string str(double v) {
  char buf[64];
  std::snprintf(buf, sizeof(buf), "%.15g", v);
  return buf;
}

inline std::string str(int v) { return std::to_string(v); }

inline std::vector<DmsTimer*> dms_start_timers;

/// La ventana: title, message, ask, close.
class DmsForm : public Fl_Double_Window {
public:
  DmsForm(int w, int h, const char* title) : Fl_Double_Window(w, h) {
    copy_label(title);
    callback(on_window_close, this);
  }
  std::string title() const { return label() ? label() : ""; }
  void title(const std::string& s) { copy_label(s.c_str()); }
  void bg(const std::string& c) { color(dms_color(c)); redraw(); }
  /// El icono de la ventana (un PNG o JPEG del proyecto).
  void app_icon(const char* path) {
    fl_register_images();
    Fl_Shared_Image* img = Fl_Shared_Image::get(path);
    if (!img) return;
    if (auto* rgb = dynamic_cast<const Fl_RGB_Image*>(img->image())) icon(rgb);
  }
  void message(const std::string& text) { fl_message("%s", text.c_str()); }
  bool ask(const std::string& question) { return fl_choice("%s", "No", "Sí", nullptr, question.c_str()) == 1; }
  void close() { hide(); }
  void on_close(std::function<void()> fn) { close_ = std::move(fn); }
  void on_create(std::function<void()> fn) { create_ = std::move(fn); }
  /// Al abrir y al cerrar la ventana (si el diseño no nombra otros).
  virtual void form_create() {}
  virtual void form_close() {}
  void created() {
    for (auto* t : dms_start_timers) t->start();
    if (create_) create_(); else form_create();
  }

private:
  static void on_window_close(Fl_Widget* w, void* self) {
    auto* f = static_cast<DmsForm*>(self);
    if (f->close_) f->close_(); else f->form_close();
    w->hide();
  }
  std::function<void()> close_, create_;
};

/// Crea la ventana de la clase F y la abre.
template <class F>
int dms_run(int argc, char** argv) {
  fl_register_images();
  Fl::scheme("gtk+");
  F* form = new F();
  // (El show de FLTK, aunque la clase tenga un método show propio.)
  static_cast<Fl_Window*>(form)->show(argc, argv);
  form->created();
  return Fl::run();
}
''';
