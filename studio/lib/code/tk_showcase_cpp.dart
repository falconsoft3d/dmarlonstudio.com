part of 'tk_examples.dart';

// Ejemplos de C++ con FLTK: el mismo diseño, con el código en C++.

/// Los ejemplos de C++.
List<TkExample> tkCppExamples(String Function(String) t) => [
  _cppCalculator(t),
  tkCppExplorer(t),
  tkCppRacing(t),
  tkCppImageEditor(t),
  tkCppFlights(t),
  tkCppHardware(t),
  tkCppWifi(t),
  tkCppConsole(t),
  tkCppWebmon(t),
  tkCppClocks(t),
  tkCppRecorder(t),
  tkCppMywa(t),
];

TkExample _cppCalculator(String Function(String) t) {
  final base = _calculator(t);
  final digits = StringBuffer();
  for (var i = 0; i < 10; i++) {
    digits.write('  void Btn${i}_click() override { digit("$i"); }\n');
  }
  final code =
      '''// ${t(markTr('Calculadora en C++ con FLTK: cada botón llama a su método.'))}
#include <cmath>

class Form1 : public FormDesign {
public:
  // Estado: lo que se ve, el primer número y la operación pendiente.
  std::string shown = "0";
  double first = 0;
  char op = 0;
  bool typing = false;

  void form_create() override { clear(); }

  void clear() {
    shown = "0";
    first = 0;
    op = 0;
    typing = false;
    refresh();
  }

  void refresh() { Display->text(shown); }

  void digit(const std::string& d) {
    if (shown == "Error") clear();
    if (!typing || shown == "0") {
      shown = d;
      typing = true;
    } else if (shown.size() < 15) {
      shown += d;
    }
    refresh();
  }

  void dot() {
    if (shown == "Error") clear();
    if (!typing) {
      shown = "0";
      typing = true;
    }
    if (shown.find('.') == std::string::npos) shown += ".";
    refresh();
  }

  void compute() {
    if (!op || shown == "Error") return;
    double b = std::stod(shown), r = 0;
    switch (op) {
      case '+': r = first + b; break;
      case '-': r = first - b; break;
      case '*': r = first * b; break;
      default: r = first / b;
    }
    op = 0;
    typing = false;
    shown = std::isfinite(r) ? str(r) : "Error";
    refresh();
  }

  void operate(char o) {
    if (shown == "Error") return;
    if (typing && op) compute();
    first = std::stod(shown);
    op = o;
    typing = false;
  }

$digits
  void BtnDot_click() override { dot(); }
  void BtnClear_click() override { clear(); }

  void BtnSign_click() override {
    if (shown == "Error" || shown == "0") return;
    shown = shown[0] == '-' ? shown.substr(1) : "-" + shown;
    refresh();
  }

  void BtnPercent_click() override {
    if (shown == "Error") return;
    shown = str(std::stod(shown) / 100);
    typing = false;
    refresh();
  }

  void BtnAdd_click() override { operate('+'); }
  void BtnSub_click() override { operate('-'); }
  void BtnMul_click() override { operate('*'); }
  void BtnDiv_click() override { operate('/'); }
  void BtnEquals_click() override { compute(); }
};
''';
  final design = TkDesign.fromJson({
    ...base.design.toJson(),
    'target': tkTargetCpp,
  })..events.remove('key');
  return TkExample(
    'cpp_calculator',
    t(markTr('Calculadora (C++)')),
    t(
      markTr(
        'La calculadora como aplicación nativa en C++ con FLTK: el mismo diseño, con el código en C++.',
      ),
    ),
    design,
    code,
  );
}
