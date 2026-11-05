import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;

import '../i18n/tr.dart';
import 'errors.dart';
import 'settings.dart';
import 'studio_db.dart';

/// Tarifa de un modelo en US$ por millón de tokens.
typedef AiPrice = ({
  double input,
  double output,
  double cacheRead,
  double cacheWrite,
});

/// Presupuesto de IA de un proyecto.
class AiBudget {
  const AiBudget({this.limit, this.monthly = true, this.block = false});

  /// Tope en US$ (null = sin presupuesto).
  final double? limit;

  /// Por mes natural; si no, en total.
  final bool monthly;

  /// Al agotarse, no deja hacer más peticiones (si no, solo avisa).
  final bool block;

  Map<String, Object?> toJson() => {
    'limit': limit,
    'monthly': monthly,
    'block': block,
  };

  static AiBudget fromJson(Object? j) => j is Map
      ? AiBudget(
          limit: (j['limit'] as num?)?.toDouble(),
          monthly: j['monthly'] != false,
          block: j['block'] == true,
        )
      : const AiBudget();
}

/// Resumen del gasto de un proyecto.
class AiSpend {
  AiSpend({
    required this.total,
    required this.period,
    required this.calls,
    required this.byTool,
    required this.byModel,
    required this.byDay,
    required this.recent,
    required this.unpriced,
  });

  /// US$ desde siempre.
  final double total;

  /// US$ del periodo del presupuesto (este mes, o el total).
  final double period;
  final int calls;
  final Map<String, double> byTool, byModel;

  /// US$ por día (aaaa-mm-dd) de los últimos 30 días.
  final Map<String, double> byDay;
  final List<Map<String, Object?>> recent;

  /// Llamadas sin tarifa conocida (solo tokens).
  final int unpriced;
}

/// Gasto en IA por proyecto: cada llamada a Claude (Claude Code, Claude
/// implementa, Pedir a la IA, chats) queda apuntada con sus tokens y su
/// coste, y cada proyecto puede tener un presupuesto.
///
/// El proyecto y la herramienta de una llamada se dan con [track], que los
/// deja en la zona: así el cliente de IA no necesita saber de proyectos.
class AiUsage {
  AiUsage._();

  static const tools = {
    'claude_code': 'Claude Code',
    'claude_agent': 'Claude implementa',
    'designer_ai': 'Pedir a la IA',
    'editor_chat': 'Chat con la IA',
    'diagram_ai': 'Diagramas',
  };

  static const _projectKey = #aiUsageProject;
  static const _toolKey = #aiUsageTool;

  /// Cambia con cada llamada apuntada (para refrescar pantallas).
  static int version = 0;

  /// Ejecuta [body] apuntando sus llamadas a [project] y [tool].
  static Future<T> track<T>(
    String? project,
    String tool,
    Future<T> Function() body,
  ) => runZoned(
    body,
    zoneValues: {
      _projectKey: project == null ? null : p.normalize(project),
      _toolKey: tool,
    },
  );

  static String? get _project => Zone.current[_projectKey] as String?;
  static String? get _tool => Zone.current[_toolKey] as String?;

  /// Tarifas (US$ por millón de tokens) de la API de Anthropic. La escritura
  /// en caché (5 min) cuesta 1,25 veces la entrada.
  static AiPrice? priceOf(String model) {
    final m = model.toLowerCase();
    AiPrice price(double i, double o, double cr) =>
        (input: i, output: o, cacheRead: cr, cacheWrite: i * 1.25);
    if (m.contains('fable') || m.contains('mythos')) return price(10, 50, 0.25);
    if (m.contains('opus-5-5')) return price(4, 20, 0.2);
    if (m.contains('opus')) return price(5, 25, 0.5);
    if (m.contains('sonnet-5') || m.contains('sonnet-4-6')) {
      return m.contains('4-6') ? price(3, 15, 0.3) : price(2, 10, 0.2);
    }
    if (m.contains('haiku-5-5')) return price(0.1, 0.5, 0.01);
    if (m.contains('haiku')) return price(1, 5, 0.1);
    return null;
  }

  /// Coste en US$ de una respuesta con el `usage` de la API de Anthropic
  /// (null si el modelo no tiene tarifa conocida).
  static double? costOf(String model, Map usage) {
    final pr = priceOf(model);
    if (pr == null) return null;
    double n(String k) => ((usage[k] as num?) ?? 0).toDouble();
    return (n('input_tokens') * pr.input +
            n('output_tokens') * pr.output +
            n('cache_read_input_tokens') * pr.cacheRead +
            n('cache_creation_input_tokens') * pr.cacheWrite) /
        1e6;
  }

  /// Apunta una llamada. Fuera de [track] (sin proyecto) también se apunta,
  /// para el total del estudio.
  static Future<void> record({
    String? project,
    String? tool,
    required String model,
    int input = 0,
    int output = 0,
    int cacheRead = 0,
    int cacheWrite = 0,
    double? cost,
  }) async {
    try {
      await StudioDb.db.insert('ai_usage', {
        'project': project ?? _project ?? '',
        'tool': tool ?? _tool ?? 'other',
        'model': model,
        'input_tokens': input,
        'output_tokens': output,
        'cache_read_tokens': cacheRead,
        'cache_write_tokens': cacheWrite,
        'cost_usd': cost,
        'date': nowStr(),
      });
      version++;
    } on Object {
      // Apuntar el gasto nunca impide usar la IA.
    }
  }

  /// Apunta una respuesta de la API de Anthropic (`model` y `usage`).
  static Future<void> recordAnthropic(
    Map body, {
    String? fallbackModel,
    String? project,
    String? tool,
  }) {
    final usage = (body['usage'] as Map?) ?? const {};
    final model = '${body['model'] ?? fallbackModel ?? ''}';
    int n(String k) => (usage[k] as num?)?.toInt() ?? 0;
    return record(
      project: project,
      tool: tool,
      model: model,
      input: n('input_tokens'),
      output: n('output_tokens'),
      cacheRead: n('cache_read_input_tokens'),
      cacheWrite: n('cache_creation_input_tokens'),
      cost: costOf(model, usage),
    );
  }

  /// Apunta una respuesta con `usage` de formato OpenAI (sin tarifa).
  static Future<void> recordOpenAi(String model, Map usage) {
    int n(String k) => (usage[k] as num?)?.toInt() ?? 0;
    return record(
      model: model,
      input: n('prompt_tokens') + n('input_tokens'),
      output: n('completion_tokens') + n('output_tokens'),
      cost: costOf(model, {
        'input_tokens': n('prompt_tokens') + n('input_tokens'),
        'output_tokens': n('completion_tokens') + n('output_tokens'),
      }),
    );
  }

  // ------------------------------------------------------------ presupuesto
  static String _key(String project) => 'budget.${p.normalize(project)}';

  static Future<AiBudget> budgetOf(String project) async {
    try {
      return AiBudget.fromJson(
        jsonDecode(await Settings.get(_key(project)) ?? 'null'),
      );
    } on FormatException {
      return const AiBudget();
    }
  }

  static Future<void> setBudget(String project, AiBudget b) =>
      Settings.set(_key(project), b.limit == null ? null : jsonEncode(b));

  static String _monthStart() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-01';
  }

  /// Lo gastado en el periodo del presupuesto.
  static Future<double> spentInPeriod(String project, AiBudget b) async {
    final r = await StudioDb.db.rawQuery(
      'SELECT COALESCE(SUM(cost_usd), 0) AS s FROM ai_usage '
      'WHERE project = ?${b.monthly ? ' AND date >= ?' : ''}',
      [p.normalize(project), if (b.monthly) _monthStart()],
    );
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }

  /// Antes de una llamada de IA: si el proyecto de la zona agotó un
  /// presupuesto que bloquea, la llamada no se hace.
  static Future<void> check({String? project}) async {
    project ??= _project;
    if (!StudioDb.isOpen) return;
    if (project == null || project.isEmpty) return;
    final b = await budgetOf(project);
    final limit = b.limit;
    if (limit == null || !b.block) return;
    final spent = await spentInPeriod(project, b);
    if (spent >= limit) {
      throw UserError(
        tr(
          'El presupuesto de IA de este proyecto está agotado ({0} de {1} US\$). Súbalo en Presupuesto de IA.',
          [spent.toStringAsFixed(2), limit.toStringAsFixed(2)],
        ),
      );
    }
  }

  /// Resumen del gasto de [project].
  static Future<AiSpend> summary(String project) async {
    final db = StudioDb.db;
    final pr = p.normalize(project);
    final b = await budgetOf(pr);
    final all = await db.rawQuery(
      'SELECT COALESCE(SUM(cost_usd), 0) AS s, COUNT(*) AS n, '
      'SUM(CASE WHEN cost_usd IS NULL THEN 1 ELSE 0 END) AS u '
      'FROM ai_usage WHERE project = ?',
      [pr],
    );
    Future<Map<String, double>> group(String col, [String extra = '']) async =>
        {
          for (final r in await db.rawQuery(
            'SELECT $col AS k, COALESCE(SUM(cost_usd), 0) AS s FROM ai_usage '
            'WHERE project = ? $extra GROUP BY $col ORDER BY s DESC',
            [pr],
          ))
            '${r['k']}': (r['s'] as num).toDouble(),
        };
    final since = DateTime.now().subtract(const Duration(days: 29));
    final from =
        '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';
    return AiSpend(
      total: (all.first['s'] as num).toDouble(),
      period: await spentInPeriod(pr, b),
      calls: (all.first['n'] as num).toInt(),
      unpriced: ((all.first['u'] as num?) ?? 0).toInt(),
      byTool: await group('tool'),
      byModel: await group('model'),
      byDay: await group("substr(date, 1, 10)", "AND date >= '$from'"),
      recent: await db.query(
        'ai_usage',
        where: 'project = ?',
        whereArgs: [pr],
        orderBy: 'id DESC',
        limit: 50,
      ),
    );
  }
}
