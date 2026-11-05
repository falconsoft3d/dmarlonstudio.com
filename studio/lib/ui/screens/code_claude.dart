part of 'code_studio.dart';

/// Lo de Claude que sobrevive al cambiar de módulo: la conversación, sus
/// pasos y los cambios propuestos.
class _ClaudeSession {
  static ClaudeAgent? agent;
  static String? root;
  static final steps = <ClaudeStep>[];
  static bool busy = false;
}

/// Panel «Claude implementa»: Claude explora la carpeta abierta y propone
/// cambios en varios archivos, que se revisan con su diff y se aplican.
mixin _ClaudePanel on State<CodeStudioScreen> {
  // Lo da la pantalla.
  CodeWorkspace? get _ws;
  List<_Doc> get _docs;
  Future<void> _reloadFromDisk();
  Widget _header(String title, [List<Widget> actions = const []]);
  Widget _iconBtn(IconData icon, String tip, VoidCallback? onTap);
  Widget _darkField(
    TextEditingController c,
    String hint, {
    // ignore: unused_element_parameter
    ValueChanged<String>? onSubmitted,
    int maxLines = 1,
  });

  final _claudeAsk = TextEditingController();
  final _claudeScroll = ScrollController();

  @override
  void dispose() {
    _claudeAsk.dispose();
    _claudeScroll.dispose();
    super.dispose();
  }

  ClaudeAgent? get _agent {
    final a = _ClaudeSession.agent;
    // Otra carpeta: otra conversación.
    return a != null && _ClaudeSession.root == _ws?.root ? a : null;
  }

  void _claudeScrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_claudeScroll.hasClients) {
      _claudeScroll.jumpTo(_claudeScroll.position.maxScrollExtent);
    }
  });

  void _claudeStep(ClaudeStep s) {
    if (s.text.isEmpty) return;
    _ClaudeSession.steps.add(s);
    if (mounted) setState(() {});
    _claudeScrollDown();
  }

  Future<void> _claudeSend() async {
    final q = _claudeAsk.text.trim();
    final ws = _ws;
    if (q.isEmpty || _ClaudeSession.busy || ws == null) return;
    var agent = _agent;
    if (agent == null) {
      try {
        agent = await ClaudeAgent.fromSettings(
          root: ws.root,
          onStep: _claudeStep,
        );
      } on UserError catch (e) {
        _claudeStep(ClaudeStep('error', e.message));
        return;
      }
      _ClaudeSession.agent = agent;
      _ClaudeSession.root = ws.root;
      _ClaudeSession.steps.clear();
    }
    _claudeAsk.clear();
    _ClaudeSession.steps.add(ClaudeStep('user', q));
    setState(() => _ClaudeSession.busy = true);
    _claudeScrollDown();
    try {
      await agent.run(q);
    } on UserError catch (e) {
      _claudeStep(ClaudeStep('error', e.message));
    } on Object catch (e) {
      _claudeStep(ClaudeStep('error', '$e'));
    } finally {
      _ClaudeSession.busy = false;
      if (mounted) setState(() {});
      _claudeScrollDown();
    }
  }

  void _claudeReset() {
    _ClaudeSession.agent?.cancel();
    setState(() {
      _ClaudeSession.agent = null;
      _ClaudeSession.root = null;
      _ClaudeSession.steps.clear();
      _ClaudeSession.busy = false;
    });
  }

  /// Aplica [paths] (todos, sin ellos). Un archivo abierto con cambios sin
  /// guardar no se pisa: hay que guardarlo o descartarlo antes.
  Future<void> _claudeApply([List<String>? paths]) async {
    final agent = _agent, ws = _ws;
    if (agent == null || ws == null) return;
    final chosen = paths ?? agent.changes.keys.toList();
    final open = [
      for (final d in _docs)
        if (d.dirty &&
            d.project == null &&
            chosen.contains(p.relative(d.path, from: ws.root)))
          p.relative(d.path, from: ws.root),
    ];
    if (open.isNotEmpty) {
      await showErrorDialog(
        context,
        tr('Guarde o descarte primero los cambios sin guardar de: {0}', [
          open.join(', '),
        ]),
      );
      return;
    }
    final done = await runAction(context, () => agent.apply(chosen));
    if (done == null) return;
    await _reloadFromDisk();
    _claudeStep(ClaudeStep('applied', tr('Aplicado: {0}', [done.join(', ')])));
  }

  void _claudeDiscard([List<String>? paths]) {
    _agent?.discard(paths);
    setState(() {});
  }

  Future<void> _claudeShowDiff(ClaudeChange c) => showDialog<void>(
    context: context,
    builder: (ctx) => _ClaudeDiffDialog(
      change: c,
      onApply: () {
        Navigator.pop(ctx);
        _claudeApply([c.path]);
      },
      onDiscard: () {
        Navigator.pop(ctx);
        _claudeDiscard([c.path]);
      },
    ),
  );

  // ------------------------------------------------------------- vista
  Widget _claudeStepView(ClaudeStep s) {
    final (icon, color, italic) = switch (s.kind) {
      'user' => (LucideIcons.user, _text, false),
      'thinking' => (LucideIcons.brain, _dim, true),
      'tool' => (LucideIcons.wrench, _dim, false),
      'error' => (LucideIcons.triangleAlert, const Color(0xFFF14C4C), false),
      'applied' => (LucideIcons.check, const Color(0xFF4EC9B0), false),
      _ => (LucideIcons.sparkles, _text, false),
    };
    final box = s.kind == 'user' || s.kind == 'text';
    return Container(
      margin: EdgeInsets.only(bottom: box ? 10 : 4),
      padding: box ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: box
          ? BoxDecoration(
              color: s.kind == 'user'
                  ? _t(0xFF2B3A4A, 0xFFDCEBFA)
                  : _t(0xFF2D2D30, 0xFFF3F3F3),
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
              s.kind == 'thinking' && s.text.length > 600
                  ? '${s.text.substring(0, 600)}…'
                  : s.text,
              style: TextStyle(
                fontSize: s.kind == 'tool' || s.kind == 'thinking'
                    ? 11.5
                    : 12.5,
                height: 1.4,
                color: color,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _claudeChanges(ClaudeAgent agent) {
    final list = agent.changes.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Cambios propuestos ({0})', [list.length]),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .4,
                      color: _text,
                    ),
                  ),
                ),
                _iconBtn(
                  LucideIcons.x,
                  tr('Descartar todo'),
                  _ClaudeSession.busy ? null : () => _claudeDiscard(),
                ),
                _iconBtn(
                  LucideIcons.checkCheck,
                  tr('Aplicar todo'),
                  _ClaudeSession.busy ? null : () => _claudeApply(),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              children: [
                for (final c in list)
                  InkWell(
                    key: ValueKey('claude-change-${c.path}'),
                    onTap: () => _claudeShowDiff(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            c.created ? 'A' : (c.deleted ? 'D' : 'M'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c.created
                                  ? const Color(0xFF73C991)
                                  : c.deleted
                                  ? const Color(0xFFF14C4C)
                                  : const Color(0xFFE2C08D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: _text),
                            ),
                          ),
                          Builder(
                            builder: (_) {
                              final (add, del) = diffStats(
                                lineDiff(c.before, c.after, context: 0),
                              );
                              return Text(
                                '+$add −$del',
                                style: TextStyle(fontSize: 10.5, color: _dim),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _claudePanel() {
    final agent = _agent;
    final steps = agent == null && _ClaudeSession.root != _ws?.root
        ? const <ClaudeStep>[]
        : _ClaudeSession.steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(tr('Claude implementa'), [
          if (_ws != null)
            _iconBtn(
              LucideIcons.wallet,
              tr('Presupuesto de IA'),
              () => showAiBudget(
                context,
                project: _ws!.root,
                name: p.basename(_ws!.root),
              ),
            ),
          if (_ClaudeSession.busy)
            _iconBtn(LucideIcons.square, tr('Detener'), () {
              _agent?.cancel();
            }),
          _iconBtn(
            LucideIcons.trash2,
            tr('Nueva conversación'),
            _ClaudeSession.busy ? null : _claudeReset,
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _ws == null
                ? tr('Abra una carpeta para que Claude trabaje en ella.')
                : tr(
                    'Claude lee la carpeta abierta y propone cambios. Nada se escribe hasta que los aplique.',
                  ),
            style: TextStyle(color: _dim, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _claudeScroll,
            padding: const EdgeInsets.all(12),
            children: [
              for (final s in steps) _claudeStepView(s),
              if (_ClaudeSession.busy)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
        if (agent != null && agent.changes.isNotEmpty) _claudeChanges(agent),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CallbackShortcuts(
                  bindings: chatSendKeys(_claudeAsk, _claudeSend),
                  child: _darkField(
                    _claudeAsk,
                    tr('Describa el cambio (Intro para enviar)'),
                    maxLines: 6,
                  ),
                ),
              ),
              _iconBtn(
                LucideIcons.send,
                tr('Enviar'),
                _ClaudeSession.busy || _ws == null ? null : _claudeSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Diff de un cambio propuesto, con aplicar y descartar.
class _ClaudeDiffDialog extends StatelessWidget {
  const _ClaudeDiffDialog({
    required this.change,
    required this.onApply,
    required this.onDiscard,
  });
  final ClaudeChange change;
  final VoidCallback onApply, onDiscard;

  @override
  Widget build(BuildContext context) {
    final lines = lineDiff(change.before, change.after);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color bg(String op) => switch (op) {
      '+' => dark ? const Color(0xFF1F3A26) : const Color(0xFFE6FFEC),
      '-' => dark ? const Color(0xFF4B1F22) : const Color(0xFFFFEBE9),
      _ => Colors.transparent,
    };
    return AlertDialog(
      title: Text(
        change.created
            ? tr('Nuevo: {0}', [change.path])
            : change.deleted
            ? tr('Borrar: {0}', [change.path])
            : change.path,
        style: const TextStyle(fontSize: 16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 900,
        height: 560,
        child: ListView.builder(
          itemCount: lines.length,
          itemBuilder: (_, i) {
            final l = lines[i];
            return Container(
              color: bg(l.op),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l.op == '…' ? '   ⋯' : '${l.op} ${l.text}',
                style: TextStyle(
                  fontFamily: 'DejaVuSansMono',
                  fontSize: 12,
                  height: 1.45,
                  color: l.op == '…' ? Theme.of(context).hintColor : null,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cerrar')),
        ),
        TextButton(onPressed: onDiscard, child: Text(tr('Descartar'))),
        FilledButton(onPressed: onApply, child: Text(tr('Aplicar'))),
      ],
    );
  }
}
