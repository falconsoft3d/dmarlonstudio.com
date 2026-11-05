import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../code/claude_code.dart';
import '../../core/errors.dart';
import '../../i18n/i18n.dart';
import '../theme.dart';
import '../tk_project.dart';
import '../widgets.dart';

/// Chat con Claude Code a la derecha del Diseñador. Antes de cada mensaje se
/// guarda el proyecto (Claude Code trabaja sobre los archivos) y, si cambió
/// algo, se vuelve a cargar el diseño y el código como un paso que se puede
/// deshacer.
class TkClaudePanel extends StatefulWidget {
  const TkClaudePanel({
    super.key,
    required this.doc,
    required this.onSave,
    required this.onReload,
    required this.onClose,
  });

  final TkProject doc;

  /// Guarda el proyecto; false si no se pudo.
  final Future<bool> Function() onSave;

  /// Carga lo que Claude Code dejó en el disco.
  final Future<void> Function() onReload;
  final VoidCallback onClose;

  @override
  State<TkClaudePanel> createState() => _TkClaudePanelState();
}

class _TkClaudePanelState extends State<TkClaudePanel> {
  final _ask = TextEditingController();
  final _scroll = ScrollController();

  ClaudeCode get _cc => ClaudeCode.of(widget.doc.id);

  @override
  void dispose() {
    _ask.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _down() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  Future<void> _send() async {
    final q = _ask.text.trim();
    if (q.isEmpty || _cc.running) return;
    if (widget.doc.dirty && !await widget.onSave()) return;
    _ask.clear();
    setState(() {});
    var edited = false;
    try {
      final run = _cc.send(
        q,
        formName: widget.doc.design.name,
        unit: widget.doc.codeName,
        onStep: (_) {
          if (mounted) setState(() {});
          _down();
        },
      );
      setState(() {});
      edited = await run;
    } on UserError catch (e) {
      _cc.steps.add(ClaudeCodeStep('error', e.message));
    }
    if (edited) await widget.onReload();
    if (mounted) setState(() {});
    _down();
  }

  Widget _step(ThemeData t, ClaudeCodeStep s) {
    final dim = t.hintColor;
    final (icon, color) = switch (s.kind) {
      'user' => (LucideIcons.user, t.colorScheme.onSurface),
      'tool' => (LucideIcons.wrench, dim),
      'done' => (LucideIcons.check, AppColors.success),
      'error' => (LucideIcons.triangleAlert, AppColors.danger),
      _ => (LucideIcons.sparkles, t.colorScheme.onSurface),
    };
    final box = s.kind == 'user' || s.kind == 'text';
    return Container(
      margin: EdgeInsets.only(bottom: box ? 8 : 3),
      padding: box ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: box
          ? BoxDecoration(
              color: s.kind == 'user'
                  ? t.colorScheme.primary.withValues(alpha: .12)
                  : t.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              s.text,
              style: TextStyle(
                fontSize: box ? 12.5 : 11.5,
                height: 1.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cc = _cc;
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        border: Border(left: BorderSide(color: t.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.dividerColor)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bot, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Claude Code', style: t.textTheme.titleSmall),
                ),
                if (cc.running)
                  IconButton(
                    tooltip: tr('Detener'),
                    iconSize: 15,
                    color: AppColors.danger,
                    icon: const Icon(LucideIcons.square),
                    onPressed: () => setState(cc.stop),
                  ),
                IconButton(
                  tooltip: tr('Nueva conversación'),
                  iconSize: 15,
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: cc.running ? null : () => setState(cc.reset),
                ),
                IconButton(
                  tooltip: tr('Cerrar'),
                  iconSize: 15,
                  icon: const Icon(LucideIcons.panelRightClose),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: cc.steps.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr(
                        'Pida cambios en esta ventana: «añade un campo de correo debajo del nombre y valida que tenga @ al guardar». Claude Code edita el diseño y el código del proyecto; el resultado se carga aquí y se puede deshacer.',
                      ),
                      style: t.textTheme.bodySmall,
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(10),
                    children: [
                      for (final s in cc.steps) _step(t, s),
                      if (cc.running)
                        const LinearProgressIndicator(minHeight: 2),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CallbackShortcuts(
                    bindings: chatSendKeys(_ask, _send),
                    child: TextField(
                      controller: _ask,
                      minLines: 1,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: tr('Pida un cambio (Intro para enviar)'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr('Enviar'),
                  icon: const Icon(LucideIcons.send, size: 18),
                  onPressed: cc.running ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
