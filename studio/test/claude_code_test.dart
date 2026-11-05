import 'dart:io';

import 'package:dmarlon_studio/code/claude_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `claude` falso: escribe eventos stream-json como la CLI y edita un archivo.
const _fake = r'''#!/bin/sh
case "$*" in *"--resume ses-1"*) resumed=1;; *) resumed=0;; esac
echo '{"type":"system","subtype":"init","session_id":"ses-1"}'
echo 'no es json'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Añado el botón."},{"type":"tool_use","name":"Edit","input":{"file_path":"'"$PWD"'/Form1.py"}}]},"session_id":"ses-1"}'
echo "# editado resumed=$resumed" >> Form1.py
echo '{"type":"result","subtype":"success","is_error":false,"result":"Hecho","total_cost_usd":0.0123,"session_id":"ses-1"}'
''';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('claude_code_test_');
    await File(p.join(dir.path, 'Form1.py')).writeAsString('class Form1:\n');
    final exe = File(p.join(dir.path, 'claude'));
    await exe.writeAsString(_fake);
    await Process.run('chmod', ['+x', exe.path]);
    ClaudeCode.exeOverride = exe.path;
  });

  tearDown(() async {
    ClaudeCode.exeOverride = null;
    await dir.delete(recursive: true);
  });

  test(
    'interpreta los pasos, detecta la edición y retoma la sesión',
    () async {
      final cc = ClaudeCode(dir.path);
      final seen = <String>[];
      final edited = await cc.send(
        'Añade un botón',
        formName: 'Form1',
        unit: 'Form1.py',
        onStep: (s) => seen.add(s.kind),
      );
      expect(edited, isTrue);
      expect(cc.sessionId, 'ses-1');
      expect(seen, ['user', 'text', 'tool', 'done']);
      expect(cc.steps[2].text, contains('Form1.py'));
      expect(cc.steps.last.text, contains('0.0123'));
      expect(cc.running, isFalse);

      await cc.send(
        'Otra',
        formName: 'Form1',
        unit: 'Form1.py',
        onStep: (_) {},
      );
      expect(
        await File(p.join(dir.path, 'Form1.py')).readAsString(),
        contains('resumed=1'),
      );

      cc.reset();
      expect(cc.sessionId, isNull);
      expect(cc.steps, isEmpty);
    },
    skip: Platform.isWindows,
  );
}
