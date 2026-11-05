import 'dart:io';

import 'package:dmarlon_studio/core/ai_usage.dart';
import 'package:dmarlon_studio/core/errors.dart';
import 'package:dmarlon_studio/core/studio_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ai_usage_test_');
    StudioDb.dirOverride = dir.path;
    await StudioDb.open();
  });

  tearDown(() async {
    await StudioDb.close();
    StudioDb.dirOverride = null;
    await dir.delete(recursive: true);
  });

  test('tarifas de Claude', () {
    // Opus 5.5: 4 US$ entrada, 20 salida, 0,20 lectura de caché por MTok.
    final c = AiUsage.costOf('claude-opus-5-5', {
      'input_tokens': 1000000,
      'output_tokens': 100000,
      'cache_read_input_tokens': 1000000,
      'cache_creation_input_tokens': 0,
    })!;
    expect(c, closeTo(4 + 2 + 0.2, 1e-9));
    expect(AiUsage.costOf('gpt-4.1-mini', {'input_tokens': 10}), isNull);
  });

  test('apunta por proyecto y herramienta y resume', () async {
    await AiUsage.track('/p/uno', 'designer_ai', () async {
      await AiUsage.recordAnthropic({
        'model': 'claude-sonnet-5-5',
        'usage': {'input_tokens': 500000, 'output_tokens': 100000},
      });
    });
    await AiUsage.record(
      project: '/p/uno',
      tool: 'claude_code',
      model: 'claude-opus-5-5',
      cost: 0.5,
    );
    await AiUsage.record(project: '/p/otro', tool: 'claude_code', model: 'x');
    final s = await AiUsage.summary('/p/uno');
    expect(s.calls, 2);
    expect(s.total, closeTo(1 + 1 + 0.5, 1e-9));
    expect(s.byTool.keys, containsAll(['designer_ai', 'claude_code']));
    expect(s.byModel['claude-sonnet-5-5'], closeTo(2, 1e-9));
    expect(s.byDay.values.single, closeTo(2.5, 1e-9));
    expect(s.recent, hasLength(2));
  });

  test(
    'un presupuesto que bloquea impide nuevas llamadas al agotarse',
    () async {
      await AiUsage.setBudget('/p/uno', const AiBudget(limit: 1, block: true));
      await AiUsage.check(project: '/p/uno');
      await AiUsage.record(
        project: '/p/uno',
        tool: 'claude_code',
        model: 'm',
        cost: 1.2,
      );
      expect(() => AiUsage.check(project: '/p/uno'), throwsA(isA<UserError>()));
      // Otro proyecto no se ve afectado.
      await AiUsage.check(project: '/p/otro');
      // Solo avisar: no bloquea.
      await AiUsage.setBudget('/p/uno', const AiBudget(limit: 1));
      await AiUsage.check(project: '/p/uno');
      // Sin tope, el presupuesto se borra.
      await AiUsage.setBudget('/p/uno', const AiBudget());
      expect((await AiUsage.budgetOf('/p/uno')).limit, isNull);
    },
  );
}
