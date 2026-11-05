import 'package:dmarlon_studio/code/tk_help.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la ayuda: por lenguaje, la exacta primero', () {
    expect(tkHelpLang(js: false, cpp: false), 'py');
    expect(tkHelpLang(js: true, cpp: false), 'js');
    expect(tkHelpLang(js: false, cpp: true), 'cpp');
    expect(tkHelpFind('py', 'print').first.word, 'print');
    expect(tkHelpFind('js', 'text').first.word, 'text');
    expect(tkHelpFind('cpp', 'std::cout').first.word, 'std::cout');
    expect(tkHelpFind('py', 'nada-de-esto'), isEmpty);
    for (final lang in ['py', 'js', 'cpp']) {
      final all = tkHelpFind(lang, '');
      expect(all.length, greaterThan(10), reason: lang);
      expect(all.any((e) => e.studio), isTrue, reason: lang);
      for (final e in all) {
        expect(e.es.isNotEmpty && e.en.isNotEmpty && e.example.isNotEmpty, isTrue, reason: e.word);
      }
    }
  });
}
