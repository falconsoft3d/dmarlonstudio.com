import 'dart:io';

import 'package:dmarlon_studio/i18n/po.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el catálogo inglés traduce todos los textos de la aplicación', () {
    final pot = parsePo(
      File('assets/i18n/dmarlonstudio.pot').readAsStringSync(),
    );
    final en = {
      for (final e in parsePo(File('assets/i18n/en.po').readAsStringSync()))
        e.key: e,
    };
    expect(pot, isNotEmpty);
    final missing = [
      for (final e in pot)
        if ((en[e.key]?.msgstr ?? '').isEmpty || en[e.key]!.fuzzy) e.msgid,
    ];
    expect(missing, isEmpty, reason: 'Sin traducir: $missing');
    // Los marcadores {0}, {1}… se conservan.
    final mark = RegExp(r'\{\d+\}');
    for (final e in pot) {
      final a = mark.allMatches(e.msgid).map((m) => m[0]).toSet();
      final b = mark.allMatches(en[e.key]!.msgstr).map((m) => m[0]).toSet();
      expect(b, a, reason: e.msgid);
    }
  });

  test('el .pot y el .po están al día con el código', () async {
    ProcessResult r;
    try {
      r = await Process.run('python3', ['tool/extract_i18n.py', '--check']);
    } on ProcessException {
      markTestSkipped('python3 no está instalado');
      return;
    }
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  });
}
