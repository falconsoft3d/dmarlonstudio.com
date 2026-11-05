import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/ai_usage.dart';
import '../../i18n/i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Abre el control de presupuesto de IA de [project] (la carpeta).
Future<void> showAiBudget(
  BuildContext context, {
  required String project,
  required String name,
}) => showDialog<void>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
      child: AiBudgetScreen(project: project, name: name),
    ),
  ),
);

String _usd(double v) =>
    v >= 100 ? '${v.toStringAsFixed(0)} US\$' : '${v.toStringAsFixed(2)} US\$';

/// Control de presupuesto de IA de un proyecto: cuánto se ha gastado en
/// Claude (Claude Code, Claude implementa, Pedir a la IA, chats), con el
/// presupuesto, el desglose por herramienta, modelo y día, y las últimas
/// llamadas.
class AiBudgetScreen extends StatefulWidget {
  const AiBudgetScreen({super.key, required this.project, required this.name});
  final String project;
  final String name;

  @override
  State<AiBudgetScreen> createState() => _AiBudgetScreenState();
}

class _AiBudgetScreenState extends State<AiBudgetScreen> {
  AiSpend? _spend;
  AiBudget _budget = const AiBudget();
  final _limit = TextEditingController();
  bool _monthly = true, _block = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await AiUsage.budgetOf(widget.project);
    final s = await AiUsage.summary(widget.project);
    if (!mounted) return;
    setState(() {
      _budget = b;
      _spend = s;
      _limit.text = b.limit == null ? '' : b.limit!.toStringAsFixed(2);
      _monthly = b.monthly;
      _block = b.block;
    });
  }

  Future<void> _save() async {
    final text = _limit.text.trim().replaceAll(',', '.');
    final v = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && (v == null || v <= 0)) {
      await showErrorDialog(context, tr('Escriba un importe mayor que cero.'));
      return;
    }
    final b = AiBudget(limit: v, monthly: _monthly, block: _block);
    await runAction(
      context,
      () => AiUsage.setBudget(widget.project, b),
      success: tr('Presupuesto guardado.'),
    );
    await _load();
  }

  // --------------------------------------------------------------- piezas
  Widget _kpi(ThemeData t, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: t.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  /// Barra del presupuesto con su estado (color, icono y texto).
  Widget _gauge(ThemeData t, AiSpend s) {
    final limit = _budget.limit;
    if (limit == null) {
      return Text(
        tr(
          'Sin presupuesto: escriba un tope para recibir avisos al 80 % y, si quiere, bloquear la IA al agotarlo.',
        ),
        style: t.textTheme.bodySmall,
      );
    }
    final ratio = limit <= 0 ? 1.0 : s.period / limit;
    final (color, icon, label) = ratio >= 1
        ? (
            AppColors.danger,
            LucideIcons.octagonX,
            _budget.block
                ? tr('Agotado: la IA está bloqueada en este proyecto.')
                : tr('Agotado: se ha pasado del presupuesto.'),
          )
        : ratio >= .8
        ? (
            AppColors.warning,
            LucideIcons.triangleAlert,
            tr('Cerca del límite ({0} %).', [(ratio * 100).round()]),
          )
        : (
            AppColors.success,
            LucideIcons.circleCheck,
            tr('Dentro del presupuesto ({0} %).', [(ratio * 100).round()]),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1).toDouble(),
            minHeight: 10,
            color: color,
            backgroundColor: t.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: t.textTheme.bodySmall)),
          ],
        ),
      ],
    );
  }

  /// Lista de barras horizontales (una sola serie, un solo tono).
  Widget _bars(ThemeData t, String title, Map<String, double> data) {
    final max = data.values.fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (data.isEmpty)
          Text(tr('Sin datos todavía.'), style: t.textTheme.bodySmall),
        for (final e in data.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    tr(AiUsage.tools[e.key] ?? e.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 10,
                        width: max <= 0
                            ? 2
                            : (c.maxWidth * e.value / max).clamp(2, c.maxWidth),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Text(
                    _usd(e.value),
                    textAlign: TextAlign.right,
                    style: t.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Gasto de los últimos 30 días: barras verticales con tooltip.
  Widget _days(ThemeData t, Map<String, double> byDay) {
    final today = DateTime.now();
    final days = [
      for (var i = 29; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final max = byDay.values.fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Últimos 30 días'), style: t.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message: '${d.day}/${d.month}: ${_usd(byDay[key(d)] ?? 0)}',
                    child: Container(
                      // Zona de hover más grande que la barra.
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: max <= 0
                            ? 1
                            : (88 * (byDay[key(d)] ?? 0) / max).clamp(1, 88),
                        decoration: BoxDecoration(
                          color: (byDay[key(d)] ?? 0) > 0
                              ? AppColors.brand
                              : t.dividerColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: t.dividerColor),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${days.first.day}/${days.first.month}',
              style: t.textTheme.bodySmall,
            ),
            Text(tr('Hoy'), style: t.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _recent(ThemeData t, List<Map<String, Object?>> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('Últimas llamadas'), style: t.textTheme.titleSmall),
      const SizedBox(height: 6),
      if (rows.isEmpty)
        Text(tr('Sin datos todavía.'), style: t.textTheme.bodySmall),
      if (rows.isNotEmpty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 32,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 32,
            columnSpacing: 18,
            columns: [
              DataColumn(label: Text(tr('Fecha'))),
              DataColumn(label: Text(tr('Herramienta'))),
              DataColumn(label: Text(tr('Modelo'))),
              DataColumn(label: Text(tr('Entrada')), numeric: true),
              DataColumn(label: Text(tr('Salida')), numeric: true),
              DataColumn(label: Text(tr('Coste')), numeric: true),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(Text(Fmt.dateTime(r['date']))),
                    DataCell(
                      Text(tr(AiUsage.tools['${r['tool']}'] ?? '${r['tool']}')),
                    ),
                    DataCell(Text('${r['model']}')),
                    DataCell(
                      Text(
                        '${((r['input_tokens'] as num?) ?? 0) + ((r['cache_read_tokens'] as num?) ?? 0) + ((r['cache_write_tokens'] as num?) ?? 0)}',
                      ),
                    ),
                    DataCell(Text('${r['output_tokens']}')),
                    DataCell(
                      Text(
                        r['cost_usd'] == null
                            ? '—'
                            : _usd((r['cost_usd'] as num).toDouble()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = _spend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              const Icon(LucideIcons.wallet, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Presupuesto de IA · {0}', [widget.name]),
                  style: t.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: tr('Actualizar'),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _load,
              ),
              IconButton(
                tooltip: tr('Cerrar'),
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: s == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        _kpi(
                          t,
                          _monthly ? tr('Gastado este mes') : tr('Gastado'),
                          _usd(s.period),
                        ),
                        const SizedBox(width: 10),
                        _kpi(
                          t,
                          tr('Presupuesto'),
                          _budget.limit == null ? '—' : _usd(_budget.limit!),
                        ),
                        const SizedBox(width: 10),
                        _kpi(
                          t,
                          tr('Restante'),
                          _budget.limit == null
                              ? '—'
                              : _usd(
                                  (_budget.limit! - s.period).clamp(0, 1e12),
                                ),
                        ),
                        const SizedBox(width: 10),
                        _kpi(t, tr('Llamadas'), '${s.calls}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _gauge(t, s),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _limit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: tr('Tope (US\$)'),
                              hintText: tr('sin tope'),
                              isDense: true,
                            ),
                          ),
                        ),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text(tr('Mensual')),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text(tr('Total')),
                            ),
                          ],
                          selected: {_monthly},
                          onSelectionChanged: (v) =>
                              setState(() => _monthly = v.first),
                        ),
                        FilterChip(
                          label: Text(tr('Bloquear al agotarse')),
                          selected: _block,
                          onSelected: (v) => setState(() => _block = v),
                        ),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(LucideIcons.save, size: 16),
                          label: Text(tr('Guardar')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _days(t, s.byDay),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _bars(t, tr('Por herramienta'), s.byTool),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: _bars(t, tr('Por modelo'), s.byModel)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _recent(t, s.recent),
                    const SizedBox(height: 12),
                    Text(
                      [
                        tr(
                          'Costes calculados con la tarifa de la API de Anthropic. Con una suscripción de Claude, el coste de Claude Code es su equivalente en API, no lo que se cobra.',
                        ),
                        if (s.unpriced > 0)
                          tr(
                            '{0} llamadas de otros proveedores sin tarifa conocida: solo se cuentan sus tokens.',
                            [s.unpriced],
                          ),
                      ].join(' '),
                      style: t.textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
