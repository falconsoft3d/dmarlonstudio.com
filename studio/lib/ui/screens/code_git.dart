part of 'code_studio.dart';

/// Control de código del editor: cambios, historial (ir a un commit,
/// revertirlo, volver la rama a él), ramas, cambios guardados aparte
/// (stash), remotos y GitHub (clonar, publicar, traer y subir).
mixin _GitPanel on State<CodeStudioScreen> {
  // Lo da la pantalla.
  CodeWorkspace? get _ws;
  // ignore: unused_element_parameter
  Future<void> _open(String path, {int? line});
  Future<void> _openFolder([String? path]);
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

  bool _repo = false, _gitBusy = false;
  String _branch = '', _head = '';
  ({int ahead, int behind})? _track;
  List<GitChange> _changes = [];
  List<GitCommit> _log = [];
  List<GitBranch> _branches = [];
  List<GitStash> _stashes = [];
  List<GitRemote> _remotes = [];
  final _message = TextEditingController();
  String? _gitOutput;

  static const _green = Color(0xFF73C991);
  static const _red = Color(0xFFC74E39);
  static const _yellow = Color(0xFFE2C08D);
  static const _blue = Color(0xFF3794FF);

  @override
  void initState() {
    super.initState();
    GitHubAuth.load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _refreshGit() async {
    final ws = _ws;
    if (ws == null) return;
    try {
      _repo = await ws.isRepo();
      if (_repo) {
        final r = await Future.wait([
          ws.branch(),
          ws.head(),
          ws.aheadBehind(),
          ws.status(),
          ws.log(all: _Session.gitAll),
          ws.branches(),
          ws.stashes(),
          ws.remotes(),
        ]);
        _branch = r[0] as String;
        _head = r[1] as String;
        _track = r[2] as ({int ahead, int behind})?;
        _changes = r[3] as List<GitChange>;
        _log = r[4] as List<GitCommit>;
        _branches = r[5] as List<GitBranch>;
        _stashes = r[6] as List<GitStash>;
        _remotes = r[7] as List<GitRemote>;
      } else {
        _branch = _head = '';
        _track = null;
        _changes = [];
        _log = [];
        _branches = [];
        _stashes = [];
        _remotes = [];
      }
    } on UserError {
      _repo = false;
    }
    if (mounted) setState(() {});
  }

  /// Ejecuta una orden de git mostrando su salida. [files]: puede cambiar
  /// los archivos (se recargan el explorador y las pestañas sin cambios).
  Future<bool> _git(Future<String> Function() f, {bool files = false}) async {
    setState(() => (_gitBusy = true, _gitOutput = null));
    var ok = false;
    try {
      final out = await f();
      _gitOutput = out.isEmpty ? tr('Hecho.') : out;
      ok = true;
    } on UserError catch (e) {
      _gitOutput = e.message;
    } finally {
      _gitBusy = false;
      if (files) await _reloadFromDisk();
      await _refreshGit();
    }
    return ok;
  }

  /// Hay cambios sin confirmar: se avisa antes de mover HEAD.
  Future<bool> _okWithChanges(String action) async =>
      _changes.isEmpty ||
      await confirmDialog(
        context,
        tr('Hay cambios sin confirmar'),
        tr(
          'Tiene {0} archivo(s) con cambios. Si chocan con «{1}», git no lo hará; puede guardarlos aparte (stash) antes. ¿Continuar?',
          [_changes.length, action],
        ),
      );

  // ------------------------------------------------------------- panel
  Widget _gitPanel() {
    if (!_repo) return _noRepo();
    final ws = _ws!;
    final busy = _gitBusy || _changes.isEmpty;
    final button = FilledButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(tr('Control de código'), [
          _iconBtn(LucideIcons.refreshCw, tr('Actualizar'), _refreshGit),
          _iconBtn(
            LucideIcons.cloudDownload,
            tr('Buscar cambios en el remoto (fetch)'),
            _gitBusy || _remotes.isEmpty ? null : () => _git(ws.fetch),
          ),
          _iconBtn(
            LucideIcons.arrowDownToLine,
            tr('Traer (pull)'),
            _gitBusy || _remotes.isEmpty
                ? null
                : () => _git(ws.pull, files: true),
          ),
          _iconBtn(
            LucideIcons.arrowUpFromLine,
            tr('Subir (push)'),
            _gitBusy ? null : () => _git(ws.push),
          ),
          _moreMenu(ws),
        ]),
        _branchBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _darkField(_message, tr('Mensaje del commit'), maxLines: 3),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: button,
                  onPressed: busy
                      ? null
                      : () async {
                          await _git(() => ws.commit(_message.text));
                          if (_changes.isEmpty) _message.clear();
                        },
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: Text(tr('Confirmar todo')),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: tr('Confirmar y subir'),
                child: FilledButton(
                  style: button,
                  onPressed: busy
                      ? null
                      : () => _git(() async {
                          final a = await ws.commit(_message.text);
                          final b = await ws.push();
                          _message.clear();
                          return '$a\n$b'.trim();
                        }),
                  child: const Icon(LucideIcons.cloudUpload, size: 16),
                ),
              ),
            ],
          ),
        ),
        if (_gitBusy) const LinearProgressIndicator(minHeight: 2),
        if (_gitOutput != null) _outputBox(),
        _tabs(),
        Expanded(
          child: switch (_Session.gitTab) {
            'history' => _historyTab(ws),
            'branches' => _branchesTab(ws),
            'stash' => _stashTab(ws),
            _ => _changesTab(ws),
          },
        ),
      ],
    );
  }

  Widget _noRepo() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(tr('Control de código')),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Esta carpeta no es un repositorio de git.'),
              style: TextStyle(color: _dim),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              onPressed: _gitBusy ? null : () => _git(_ws!.init),
              icon: const Icon(LucideIcons.gitBranchPlus, size: 16),
              label: Text(tr('Inicializar repositorio')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: _text),
              onPressed: _cloneRepo,
              icon: const Icon(LucideIcons.gitFork, size: 16),
              label: Text(tr('Clonar repositorio…')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: _text),
              onPressed: _githubAccount,
              icon: const Icon(LucideIcons.keyRound, size: 16),
              label: Text(tr('Cuenta de GitHub…')),
            ),
            if (_gitOutput != null) ...[
              const SizedBox(height: 8),
              _outputBox(),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _outputBox() => Container(
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    padding: const EdgeInsets.all(8),
    constraints: const BoxConstraints(maxHeight: 140),
    color: const Color(0xFF1B1B1C),
    child: Stack(
      children: [
        SingleChildScrollView(
          child: SelectableText(
            _gitOutput!,
            style: TextStyle(
              fontSize: 11.5,
              fontFamily: _mono,
              fontFamilyFallback: _monoFallback,
              color: _text,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () => setState(() => _gitOutput = null),
            child: Icon(LucideIcons.x, size: 13, color: _dim),
          ),
        ),
      ],
    ),
  );

  /// Rama actual (o el commit, con HEAD separado) y lo que falta por
  /// subir o traer; al pulsarla se ven las ramas.
  Widget _branchBar() {
    final detached = _branch.isEmpty;
    final t = _track;
    return InkWell(
      onTap: () => setState(() => _Session.gitTab = 'branches'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            Icon(
              detached
                  ? LucideIcons.gitCommitHorizontal
                  : LucideIcons.gitBranch,
              size: 14,
              color: detached ? _yellow : _text,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                detached
                    ? (_head.isEmpty
                          ? tr('Sin commits todavía')
                          : tr('HEAD separado en {0}', [_head]))
                    : _branch,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: detached ? _yellow : _text,
                ),
              ),
            ),
            if (t != null)
              Tooltip(
                message: tr('{0} por traer · {1} por subir', [
                  t.behind,
                  t.ahead,
                ]),
                child: Text(
                  '${t.behind}↓ ${t.ahead}↑',
                  style: TextStyle(fontSize: 12, color: _dim),
                ),
              )
            else if (!detached && _remotes.isNotEmpty)
              Tooltip(
                message: tr('La rama aún no está en el remoto'),
                child: Icon(LucideIcons.cloudUpload, size: 13, color: _dim),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    Widget tab(String key, String label, int n) {
      final on = _Session.gitTab == key;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _Session.gitTab = key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: on ? _status : _line,
                  width: on ? 2 : 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              n > 0 ? '$label $n' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : _dim,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          tab('changes', tr('Cambios'), _changes.length),
          tab('history', tr('Historial'), 0),
          tab('branches', tr('Ramas'), 0),
          tab('stash', tr('Stash'), _stashes.length),
        ],
      ),
    );
  }

  Widget _moreMenu(CodeWorkspace ws) => PopupMenuButton<String>(
    tooltip: tr('Más acciones de git'),
    icon: Icon(LucideIcons.ellipsis, size: 16, color: _text),
    padding: EdgeInsets.zero,
    enabled: !_gitBusy,
    onSelected: (v) => _moreAction(ws, v),
    itemBuilder: (_) => [
      PopupMenuItem(value: 'branch', child: Text(tr('Nueva rama…'))),
      PopupMenuItem(
        value: 'amend',
        enabled: _log.isNotEmpty,
        child: Text(tr('Corregir el último commit')),
      ),
      PopupMenuItem(
        value: 'undo',
        enabled: _log.length > 1,
        child: Text(tr('Deshacer el último commit')),
      ),
      PopupMenuItem(
        value: 'stash',
        enabled: _changes.isNotEmpty,
        child: Text(tr('Guardar los cambios aparte (stash)…')),
      ),
      PopupMenuItem(
        value: 'discard',
        enabled: _changes.isNotEmpty,
        child: Text(tr('Descartar todos los cambios…')),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(value: 'remotes', child: Text(tr('Remotos…'))),
      if (_remotes.isEmpty)
        PopupMenuItem(value: 'publish', child: Text(tr('Publicar en GitHub…'))),
      if (_remotes.any((r) => GitHubAuth.webUrl(r.url) != null))
        PopupMenuItem(value: 'web', child: Text(tr('Abrir en GitHub'))),
      PopupMenuItem(value: 'clone', child: Text(tr('Clonar repositorio…'))),
      PopupMenuItem(value: 'github', child: Text(tr('Cuenta de GitHub…'))),
    ],
  );

  Future<void> _moreAction(CodeWorkspace ws, String v) async {
    switch (v) {
      case 'branch':
        await _newBranch(ws);
      case 'amend':
        await _git(() => ws.amend(_message.text));
        _message.clear();
      case 'undo':
        if (await confirmDialog(
          context,
          tr('Deshacer el último commit'),
          tr(
            '«{0}» se quita del historial y sus cambios vuelven a quedar pendientes (no se pierde nada). Si ya lo subió, no lo haga.',
            [_log.first.subject],
          ),
        )) {
          await _git(ws.undoLastCommit, files: true);
        }
      case 'stash':
        await _stashChanges(ws);
      case 'discard':
        if (await confirmDialog(
          context,
          tr('Descartar todos los cambios'),
          tr(
            'Se pierden los cambios de {0} archivo(s) y se borran los archivos nuevos. No se puede deshacer.',
            [_changes.length],
          ),
          danger: true,
          ok: tr('Descartar'),
        )) {
          await _git(ws.discardAll, files: true);
        }
      case 'remotes':
        await _remotesDialog(ws);
      case 'publish':
        await _publish(ws);
      case 'web':
        final u = await ws.webUrl();
        if (u != null) await launchUrl(Uri.parse(u));
      case 'clone':
        await _cloneRepo();
      case 'github':
        await _githubAccount();
    }
  }

  // ----------------------------------------------------------- cambios
  Widget _changesTab(CodeWorkspace ws) {
    if (_changes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          tr('No hay cambios pendientes.'),
          style: TextStyle(color: _dim, fontSize: 12.5),
        ),
      );
    }
    return ListView(
      children: [
        for (final c in _changes)
          GestureDetector(
            onSecondaryTapUp: (d) => _changeMenu(ws, c, d.globalPosition),
            child: InkWell(
              onTap: () => _showChange(ws, c),
              onLongPress: () => _changeMenu(ws, c, null),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Row(
                  children: [
                    Icon(
                      _CodeStudioScreenState._fileIcon(c.path),
                      size: 14,
                      color: _CodeStudioScreenState._fileColor(c.path),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Tooltip(
                        message: c.path,
                        waitDuration: const Duration(milliseconds: 600),
                        child: Text(
                          p.basename(c.path),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                    _iconBtn(
                      LucideIcons.fileText,
                      tr('Abrir el archivo'),
                      c.status == 'D'
                          ? null
                          : () => _open(p.join(ws.root, c.path)),
                    ),
                    _iconBtn(
                      LucideIcons.undo2,
                      tr('Descartar los cambios'),
                      _gitBusy ? null : () => _discard(ws, c),
                    ),
                    SizedBox(
                      width: 20,
                      child: Text(
                        c.status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _statusColor(c.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Color _statusColor(String s) => switch (s) {
    'D' => _red,
    '??' || 'A' => _green,
    'R' => _blue,
    _ => _yellow,
  };

  Future<void> _changeMenu(CodeWorkspace ws, GitChange c, Offset? at) async {
    final box = context.findRenderObject() as RenderBox;
    final pos = at ?? box.localToGlobal(box.size.center(Offset.zero));
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        PopupMenuItem(value: 'diff', child: Text(tr('Ver los cambios'))),
        if (c.status != 'D')
          PopupMenuItem(value: 'open', child: Text(tr('Abrir el archivo'))),
        PopupMenuItem(
          value: 'discard',
          child: Text(tr('Descartar los cambios')),
        ),
      ],
    );
    switch (v) {
      case 'diff':
        await _showChange(ws, c);
      case 'open':
        await _open(p.join(ws.root, c.path));
      case 'discard':
        await _discard(ws, c);
    }
  }

  Future<void> _discard(CodeWorkspace ws, GitChange c) async {
    final isNew = c.status == '??' || c.status.contains('A');
    if (!await confirmDialog(
      context,
      tr('Descartar los cambios'),
      isNew
          ? tr('«{0}» es nuevo: se borrará. No se puede deshacer.', [c.path])
          : tr(
              '«{0}» vuelve a como estaba en el último commit. No se puede deshacer.',
              [c.path],
            ),
      danger: true,
      ok: tr('Descartar'),
    )) {
      return;
    }
    await _git(() async {
      await ws.discard(c);
      return tr('Descartados los cambios de {0}.', [c.path]);
    }, files: true);
  }

  Future<void> _showChange(CodeWorkspace ws, GitChange c) async {
    final diff = await runAction(context, () => ws.diff(c.path));
    if (diff == null || !mounted) return;
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.path),
        content: SizedBox(width: 900, height: 560, child: _DiffView(diff)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            icon: const Icon(LucideIcons.undo2, size: 16),
            label: Text(tr('Descartar los cambios')),
          ),
          if (c.status != 'D')
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx, 'open'),
              icon: const Icon(LucideIcons.fileText, size: 16),
              label: Text(tr('Abrir el archivo')),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Cerrar')),
          ),
        ],
      ),
    );
    if (v == 'discard') await _discard(ws, c);
    if (v == 'open') await _open(p.join(ws.root, c.path));
  }

  // --------------------------------------------------------- historial
  Widget _historyTab(CodeWorkspace ws) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(
              value: _Session.gitAll,
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: _dim),
              onChanged: (v) {
                _Session.gitAll = v ?? false;
                _refreshGit();
              },
            ),
            Text(
              tr('Todas las ramas'),
              style: TextStyle(fontSize: 12, color: _text),
            ),
          ],
        ),
        Expanded(
          child: _log.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    tr('Aún no hay commits.'),
                    style: TextStyle(color: _dim, fontSize: 12.5),
                  ),
                )
              : ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (_, i) {
                    final c = _log[i];
                    final here = c.short == _head;
                    return GestureDetector(
                      onSecondaryTapUp: (d) =>
                          _commitMenu(ws, c, d.globalPosition),
                      child: InkWell(
                        onTap: () => _showCommit(ws, c),
                        onLongPress: () => _commitMenu(ws, c, null),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Icon(
                                  here
                                      ? LucideIcons.circleDot
                                      : LucideIcons.circle,
                                  size: 11,
                                  color: here ? _blue : _dim,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.subject,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: here ? Colors.white : _text,
                                        fontWeight: here
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      '${c.short} · ${c.author} · ${_ago(c.date, now)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _dim,
                                      ),
                                    ),
                                    if (c.refs.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: [
                                            for (final r in c.refs) _refChip(r),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _refChip(String r) {
    final tag = r.startsWith('tag: ');
    final remote = !tag && r.contains('/');
    final color = tag
        ? _yellow
        : remote
        ? _dim
        : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: .6)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tag ? r.substring(5) : r,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  static String _ago(DateTime d, DateTime now) {
    final s = now.difference(d);
    if (s.inMinutes < 1) return tr('ahora');
    if (s.inHours < 1) return tr('hace {0} min', [s.inMinutes]);
    if (s.inDays < 1) return tr('hace {0} h', [s.inHours]);
    if (s.inDays < 30) return tr('hace {0} d', [s.inDays]);
    return DateFormat.yMMMd(I18n.lang.value).format(d.toLocal());
  }

  Future<void> _commitMenu(CodeWorkspace ws, GitCommit c, Offset? at) async {
    final box = context.findRenderObject() as RenderBox;
    final pos = at ?? box.localToGlobal(box.size.center(Offset.zero));
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        for (final (key, label) in _commitActions(c))
          PopupMenuItem(value: key, child: Text(label)),
      ],
    );
    if (v != null) await _commitAction(ws, c, v);
  }

  /// Acciones sobre un commit del historial.
  List<(String, String)> _commitActions(GitCommit c) => [
    ('details', tr('Ver el commit')),
    ('checkout', tr('Ir a este commit')),
    ('branch', tr('Crear una rama aquí…')),
    ('reset', tr('Volver la rama a este commit…')),
    ('revert', tr('Revertir este commit')),
    if (_branch.isNotEmpty && c.short != _head)
      ('cherry', tr('Aplicar en la rama actual (cherry-pick)')),
    ('tag', tr('Etiquetar…')),
    ('copy', tr('Copiar el hash')),
  ];

  Future<void> _showCommit(CodeWorkspace ws, GitCommit c) async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => _CommitDialog(ws, c, _commitActions(c).skip(1).toList()),
    );
    if (v != null) await _commitAction(ws, c, v);
  }

  Future<void> _commitAction(CodeWorkspace ws, GitCommit c, String v) async {
    switch (v) {
      case 'details':
        await _showCommit(ws, c);
      case 'checkout':
        if (!await confirmDialog(
          context,
          tr('Ir a este commit'),
          tr(
            'Verá los archivos como estaban en «{0}» ({1}). La rama no cambia: para volver, cambie a una rama en «Ramas». Si quiere trabajar desde aquí, cree una rama.',
            [c.subject, c.short],
          ),
          ok: tr('Ir'),
        )) {
          return;
        }
        if (!await _okWithChanges(tr('Ir a este commit'))) return;
        await _git(() => ws.checkoutCommit(c.hash), files: true);
      case 'branch':
        await _newBranch(
          ws,
          from: c.hash,
          title: tr('Rama desde {0}', [c.short]),
        );
      case 'reset':
        await _resetTo(ws, c);
      case 'revert':
        if (await confirmDialog(
          context,
          tr('Revertir este commit'),
          tr(
            'Se crea un commit nuevo que deshace los cambios de «{0}». El historial se conserva (es seguro aunque ya esté subido).',
            [c.subject],
          ),
          ok: tr('Revertir'),
        )) {
          await _git(() => ws.revert(c.hash), files: true);
        }
      case 'cherry':
        await _git(() => ws.cherryPick(c.hash), files: true);
      case 'tag':
        final name = await promptText(
          context,
          tr('Etiqueta para {0}', [c.short]),
          '',
          ok: tr('Etiquetar'),
        );
        if (name != null) await _git(() => ws.tag(name, c.hash));
      case 'copy':
        await Clipboard.setData(ClipboardData(text: c.hash));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('Copiado: {0}', [c.hash]))));
        }
    }
  }

  Future<void> _resetTo(CodeWorkspace ws, GitCommit c) async {
    if (_branch.isEmpty) {
      await showErrorDialog(
        context,
        tr(
          'Cambie primero a una rama: con HEAD separado no hay rama que mover.',
        ),
      );
      return;
    }
    var mode = 'mixed';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Widget option(String m, String title, String text) => RadioListTile(
            value: m,
            // ignore: deprecated_member_use
            groupValue: mode,
            // ignore: deprecated_member_use
            onChanged: (v) => set(() => mode = v!),
            title: Text(title),
            subtitle: Text(text),
          );
          final after = _log.indexWhere((x) => x.hash == c.hash);
          return AlertDialog(
            title: Text(tr('Volver «{0}» a {1}', [_branch, c.short])),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.subject),
                  if (after > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        tr('Los {0} commit(s) posteriores salen de la rama.', [
                          after,
                        ]),
                        style: TextStyle(color: Theme.of(ctx).hintColor),
                      ),
                    ),
                  const SizedBox(height: 8),
                  option(
                    'mixed',
                    tr('Conservar los cambios'),
                    tr('Los cambios de esos commits quedan pendientes.'),
                  ),
                  option(
                    'soft',
                    tr('Conservar los cambios preparados'),
                    tr('Como el anterior, listos para un nuevo commit.'),
                  ),
                  option(
                    'hard',
                    tr('Descartar todo'),
                    tr(
                      'Los archivos quedan exactamente como en ese commit: se pierden los commits posteriores y los cambios sin confirmar.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('Cancelar')),
              ),
              FilledButton(
                style: mode == 'hard'
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('Volver a este commit')),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      await _git(() => ws.resetTo(c.hash, mode), files: true);
    }
  }

  // ------------------------------------------------------------- ramas
  Widget _branchesTab(CodeWorkspace ws) {
    final local = _branches.where((b) => !b.remote).toList();
    final remote = _branches.where((b) => b.remote).toList();
    Widget title(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Text(
        t,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: _dim,
        ),
      ),
    );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: _text),
            onPressed: _gitBusy ? null : () => _newBranch(ws),
            icon: const Icon(LucideIcons.gitBranchPlus, size: 15),
            label: Text(tr('Nueva rama…')),
          ),
        ),
        title(tr('LOCALES')),
        for (final b in local) _branchRow(ws, b),
        if (remote.isNotEmpty) title(tr('REMOTAS')),
        for (final b in remote) _branchRow(ws, b),
      ],
    );
  }

  Widget _branchRow(CodeWorkspace ws, GitBranch b) => InkWell(
    onTap: b.current || _gitBusy ? null : () => _switchTo(ws, b),
    child: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Icon(
            b.current ? LucideIcons.check : LucideIcons.gitBranch,
            size: 13,
            color: b.current ? _green : _dim,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: '${b.hash} · ${b.subject}',
              waitDuration: const Duration(milliseconds: 600),
              child: Text(
                b.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: b.current ? Colors.white : _text,
                  fontWeight: b.current ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (b.track.isNotEmpty)
            Text(
              b.track
                  .replaceAll('ahead ', '↑')
                  .replaceAll('behind ', '↓')
                  .replaceAll('gone', tr('sin remoto')),
              style: TextStyle(fontSize: 11, color: _dim),
            ),
          PopupMenuButton<String>(
            tooltip: tr('Acciones de la rama'),
            icon: Icon(LucideIcons.ellipsisVertical, size: 14, color: _dim),
            padding: EdgeInsets.zero,
            enabled: !_gitBusy,
            onSelected: (v) => _branchAction(ws, b, v),
            itemBuilder: (_) => [
              if (!b.current)
                PopupMenuItem(
                  value: 'switch',
                  child: Text(tr('Cambiar a esta rama')),
                ),
              if (!b.current && _branch.isNotEmpty)
                PopupMenuItem(
                  value: 'merge',
                  child: Text(tr('Fusionar en «{0}»', [_branch])),
                ),
              PopupMenuItem(
                value: 'branch',
                child: Text(tr('Nueva rama desde aquí…')),
              ),
              if (!b.remote)
                PopupMenuItem(value: 'rename', child: Text(tr('Renombrar…'))),
              if (!b.current)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    b.remote ? tr('Eliminar del remoto…') : tr('Eliminar…'),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _switchTo(CodeWorkspace ws, GitBranch b) async {
    if (!await _okWithChanges(tr('Cambiar a {0}', [b.name]))) return;
    await _git(() => ws.switchBranch(b.name, remote: b.remote), files: true);
  }

  Future<void> _branchAction(CodeWorkspace ws, GitBranch b, String v) async {
    switch (v) {
      case 'switch':
        await _switchTo(ws, b);
      case 'merge':
        if (await confirmDialog(
          context,
          tr('Fusionar'),
          tr('¿Fusionar «{0}» en «{1}»?', [b.name, _branch]),
          ok: tr('Fusionar'),
        )) {
          await _git(() => ws.merge(b.name), files: true);
        }
      case 'branch':
        await _newBranch(
          ws,
          from: b.name,
          title: tr('Rama desde {0}', [b.name]),
        );
      case 'rename':
        final name = await promptText(
          context,
          tr('Renombrar la rama'),
          b.name,
          ok: tr('Renombrar'),
        );
        if (name != null && name.trim() != b.name) {
          await _git(() => ws.renameBranch(b.name, name));
        }
      case 'delete':
        if (b.remote) {
          if (await confirmDialog(
            context,
            tr('Eliminar del remoto'),
            tr('Se borra la rama «{0}» del servidor para todos. ¿Continuar?', [
              b.name,
            ]),
            danger: true,
            ok: tr('Eliminar'),
          )) {
            await _git(() => ws.deleteRemoteBranch(b.name));
          }
          return;
        }
        if (!await confirmDialog(
          context,
          tr('Eliminar la rama'),
          tr('¿Eliminar la rama «{0}»?', [b.name]),
          danger: true,
          ok: tr('Eliminar'),
        )) {
          return;
        }
        if (!await _git(() => ws.deleteBranch(b.name)) &&
            mounted &&
            await confirmDialog(
              context,
              tr('La rama no está fusionada'),
              tr(
                '«{0}» tiene commits que no están en otra rama y se perderían. ¿Eliminarla igualmente?',
                [b.name],
              ),
              danger: true,
              ok: tr('Eliminar'),
            )) {
          await _git(() => ws.deleteBranch(b.name, force: true));
        }
    }
  }

  Future<void> _newBranch(
    CodeWorkspace ws, {
    String? from,
    String? title,
  }) async {
    final name = await promptText(
      context,
      title ?? tr('Nueva rama'),
      '',
      ok: tr('Crear y cambiar'),
    );
    if (name == null || name.trim().isEmpty) return;
    await _git(() => ws.createBranch(name, from: from), files: from != null);
  }

  // ------------------------------------------------------------- stash
  Widget _stashTab(CodeWorkspace ws) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: _text),
          onPressed: _gitBusy || _changes.isEmpty
              ? null
              : () => _stashChanges(ws),
          icon: const Icon(LucideIcons.archive, size: 15),
          label: Text(tr('Guardar los cambios aparte…')),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
        child: Text(
          tr(
            'Aparta los cambios sin confirmar para cambiar de rama o traer cambios, y recupérelos después.',
          ),
          style: TextStyle(fontSize: 11.5, color: _dim),
        ),
      ),
      for (final s in _stashes)
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Icon(LucideIcons.archive, size: 13, color: _dim),
              const SizedBox(width: 6),
              Expanded(
                child: Tooltip(
                  message: s.ref,
                  child: Text(
                    s.message,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              _iconBtn(
                LucideIcons.archiveRestore,
                tr('Recuperar y quitar de la lista'),
                _gitBusy
                    ? null
                    : () => _git(
                        () => ws.stashApply(s.ref, drop: true),
                        files: true,
                      ),
              ),
              _iconBtn(
                LucideIcons.copy,
                tr('Recuperar y conservar'),
                _gitBusy
                    ? null
                    : () => _git(() => ws.stashApply(s.ref), files: true),
              ),
              _iconBtn(
                LucideIcons.trash2,
                tr('Eliminar'),
                _gitBusy
                    ? null
                    : () async {
                        if (await confirmDialog(
                          context,
                          tr('Eliminar'),
                          tr('¿Eliminar «{0}»? Sus cambios se pierden.', [
                            s.message,
                          ]),
                          danger: true,
                          ok: tr('Eliminar'),
                        )) {
                          await _git(() => ws.stashDrop(s.ref));
                        }
                      },
              ),
            ],
          ),
        ),
    ],
  );

  Future<void> _stashChanges(CodeWorkspace ws) async {
    final msg = await promptText(
      context,
      tr('Guardar los cambios aparte'),
      _message.text.trim(),
      ok: tr('Guardar'),
    );
    if (msg == null) return;
    if (await _git(() => ws.stash(msg), files: true)) {
      setState(() => _Session.gitTab = 'stash');
    }
  }

  // ------------------------------------------------- remotos y GitHub
  Future<void> _remotesDialog(CodeWorkspace ws) async {
    final name = TextEditingController(
      text: _remotes.any((r) => r.name == 'origin') ? '' : 'origin',
    );
    final url = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(tr('Remotos')),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_remotes.isEmpty)
                  Text(
                    tr('Sin remotos: añada uno para subir y traer cambios.'),
                    style: TextStyle(color: Theme.of(ctx).hintColor),
                  ),
                for (final r in _remotes)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.server, size: 18),
                    title: Text(r.name),
                    subtitle: SelectableText(r.url),
                    onTap: () => set(() {
                      name.text = r.name;
                      url.text = r.url;
                    }),
                    trailing: IconButton(
                      tooltip: tr('Quitar'),
                      icon: const Icon(LucideIcons.trash2, size: 16),
                      onPressed: () async {
                        await runAction(ctx, () => ws.removeRemote(r.name));
                        await _refreshGit();
                        set(() {});
                      },
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: name,
                        decoration: InputDecoration(labelText: tr('Nombre')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: url,
                        decoration: InputDecoration(
                          labelText: tr('Dirección (URL)'),
                          hintText: tr('https://github.com/usuario/repo.git'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Cerrar')),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await runAction(ctx, () async {
                  await ws.setRemote(name.text, url.text);
                  return true;
                });
                if (ok != true) return;
                await _refreshGit();
                set(() {
                  name.clear();
                  url.clear();
                });
              },
              child: Text(tr('Guardar el remoto')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _githubAccount() async {
    final token = TextEditingController(text: GitHubAuth.token ?? '');
    String? who;
    var checking = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(tr('Cuenta de GitHub')),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'Con un token personal, Código lista sus repositorios para clonarlos, publica repositorios nuevos y sube o trae cambios de github.com sin pedir la contraseña. Sin token, git usa las credenciales de este equipo.',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(GitHub.newTokenUrl)),
                  icon: const Icon(LucideIcons.externalLink, size: 15),
                  label: Text(tr('Crear un token en GitHub (permiso «repo»)')),
                ),
                TextField(
                  controller: token,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('Token'),
                    hintText: 'ghp_…',
                  ),
                ),
                const SizedBox(height: 8),
                if (checking) const LinearProgressIndicator(),
                if (who != null) Text(who!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                set(() => (checking = true, who = null));
                try {
                  final login = await GitHub.user(token: token.text.trim());
                  who = tr('Conectado como {0}.', [login]);
                } on UserError catch (e) {
                  who = e.message;
                }
                set(() => checking = false);
              },
              child: Text(tr('Comprobar')),
            ),
            if (GitHubAuth.token != null)
              TextButton(
                onPressed: () async {
                  await GitHubAuth.save(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(tr('Quitar el token')),
              ),
            FilledButton(
              onPressed: () async {
                await GitHubAuth.save(token.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(tr('Guardar')),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Crea el repositorio en GitHub, lo pone como «origin» y sube la rama.
  Future<void> _publish(CodeWorkspace ws) async {
    if (GitHubAuth.token == null) {
      await _githubAccount();
      if (GitHubAuth.token == null) return;
    }
    if (!mounted) return;
    final name = TextEditingController(text: p.basename(ws.root));
    final desc = TextEditingController();
    var private = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(tr('Publicar en GitHub')),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: tr('Nombre')),
                ),
                TextField(
                  controller: desc,
                  decoration: InputDecoration(labelText: tr('Descripción')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: private,
                  onChanged: (v) => set(() => private = v),
                  title: Text(tr('Privado')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Cancelar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Publicar')),
            ),
          ],
        ),
      ),
    );
    final n = name.text, d = desc.text;
    if (ok != true) return;
    await _git(() async {
      if (_head.isEmpty) {
        throw UserError(
          tr('Haga primero un commit para tener algo que subir.'),
        );
      }
      final repo = await GitHub.create(n, description: d, private: private);
      await ws.setRemote('origin', repo.cloneUrl);
      final out = await ws.push();
      return '${tr('Publicado en {0}', [repo.htmlUrl])}\n$out'.trim();
    });
  }

  /// Clona un repositorio (de GitHub o por su dirección) y lo abre.
  Future<void> _cloneRepo() async {
    await GitHubAuth.load();
    if (!mounted) return;
    final r = await showDialog<({String url, String parent, String name})>(
      context: context,
      builder: (_) => const _CloneDialog(),
    );
    if (r == null || !mounted) return;
    final dest = await runAction(context, () async {
      _Session.cloning = r.url;
      if (mounted) setState(() {});
      try {
        return await CodeWorkspace.clone(r.url, r.parent, name: r.name);
      } finally {
        _Session.cloning = null;
        if (mounted) setState(() {});
      }
    });
    if (dest != null && mounted) {
      await Settings.set(_CloneDialog.parentKey, r.parent);
      await _openFolder(dest);
    }
  }
}

/// Diferencias de git con colores (añadido, quitado, cabeceras).
class _DiffView extends StatelessWidget {
  const _DiffView(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) {
      return Center(child: Text(tr('Sin diferencias de texto.')));
    }
    return Container(
      color: _bg,
      child: SelectionArea(
        child: ListView.builder(
          itemCount: lines.length,
          itemExtent: 18,
          itemBuilder: (_, i) {
            final l = lines[i];
            final (
              Color? bg,
              Color fg,
            ) = l.startsWith('+++') || l.startsWith('---')
                ? (null, Colors.white)
                : l.startsWith('+')
                ? (const Color(0xFF203A26), const Color(0xFF9CDCAA))
                : l.startsWith('-')
                ? (const Color(0xFF4B1F1F), const Color(0xFFF1A1A1))
                : l.startsWith('@@')
                ? (const Color(0xFF1D2B3A), const Color(0xFF79B8FF))
                : l.startsWith('diff ') ||
                      l.startsWith('index ') ||
                      l.startsWith('commit ')
                ? (const Color(0xFF2A2A2A), _dim)
                : (null, _text);
            return Container(
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                l,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: _mono,
                  fontFamilyFallback: _monoFallback,
                  color: fg,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Detalle de un commit: archivos cambiados, diferencias y acciones.
class _CommitDialog extends StatefulWidget {
  const _CommitDialog(this.ws, this.commit, this.actions);
  final CodeWorkspace ws;
  final GitCommit commit;
  final List<(String, String)> actions;

  @override
  State<_CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends State<_CommitDialog> {
  List<GitChange> _files = [];
  String? _path;
  String _diff = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final files = await widget.ws.commitFiles(widget.commit.hash);
      final diff = await widget.ws.commitDiff(widget.commit.hash, path: _path);
      if (mounted) setState(() => (_files = files, _diff = diff));
    } on UserError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commit;
    final hint = Theme.of(context).hintColor;
    return AlertDialog(
      title: Text(c.subject),
      content: SizedBox(
        width: 1000,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              '${c.hash}\n${c.author} <${c.email}> · ${DateFormat.yMMMd(I18n.lang.value).add_Hm().format(c.date.toLocal())}'
              '${c.refs.isEmpty ? '' : '\n${c.refs.join(', ')}'}',
              style: TextStyle(color: hint, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error != null
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: _ErrorLine(_error!),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 260,
                          child: ListView(
                            children: [
                              ListTile(
                                dense: true,
                                selected: _path == null,
                                leading: const Icon(
                                  LucideIcons.files,
                                  size: 16,
                                ),
                                title: Text(
                                  tr('Todos los archivos ({0})', [
                                    _files.length,
                                  ]),
                                ),
                                onTap: () {
                                  _path = null;
                                  _load();
                                },
                              ),
                              for (final f in _files)
                                ListTile(
                                  dense: true,
                                  selected: _path == f.path,
                                  leading: Text(
                                    f.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _GitPanel._statusColor(f.status),
                                    ),
                                  ),
                                  minLeadingWidth: 14,
                                  title: Tooltip(
                                    message: f.path,
                                    child: Text(
                                      p.basename(f.path),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.dirname(f.path) == '.'
                                        ? ''
                                        : p.dirname(f.path),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () {
                                    _path = f.path;
                                    _load();
                                  },
                                ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 12),
                        Expanded(child: _DiffView(_diff)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            for (final (key, label) in widget.actions)
              TextButton(
                onPressed: () => Navigator.pop(context, key),
                child: Text(label),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Cerrar')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Elegir el repositorio a clonar (de GitHub o por dirección) y dónde.
class _CloneDialog extends StatefulWidget {
  const _CloneDialog();

  /// Última carpeta donde se clonó.
  static String get parentKey => 'code.clone_parent';

  @override
  State<_CloneDialog> createState() => _CloneDialogState();
}

class _CloneDialogState extends State<_CloneDialog> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _find = TextEditingController();
  String _parent =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  List<GitHubRepo>? _repos;
  String? _error;

  @override
  void initState() {
    super.initState();
    Settings.get(_CloneDialog.parentKey).then((v) {
      if (v != null && Directory(v).existsSync() && mounted) {
        setState(() => _parent = v);
      }
    });
    if (GitHubAuth.token != null) {
      GitHub.repos().then(
        (r) {
          if (mounted) setState(() => _repos = r);
        },
        onError: (Object e) {
          if (mounted) {
            setState(() => _error = e is UserError ? e.message : '$e');
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    _find.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _find.text.trim().toLowerCase();
    final repos = [
      for (final r in _repos ?? <GitHubRepo>[])
        if (q.isEmpty ||
            r.fullName.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q))
          r,
    ];
    final hint = Theme.of(context).hintColor;
    return AlertDialog(
      title: Text(tr('Clonar repositorio')),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (GitHubAuth.token == null)
              Text(
                tr(
                  'Configure su token de GitHub (Control de código → Cuenta de GitHub) para elegir entre sus repositorios; o pegue la dirección.',
                ),
                style: TextStyle(color: hint),
              )
            else ...[
              TextField(
                controller: _find,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  hintText: tr('Buscar en mis repositorios de GitHub'),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 260,
                child: _error != null
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: _ErrorLine(_error!),
                      )
                    : _repos == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          for (final r in repos)
                            ListTile(
                              dense: true,
                              selected: _url.text == r.cloneUrl,
                              leading: Icon(
                                r.private
                                    ? LucideIcons.lock
                                    : LucideIcons.bookOpen,
                                size: 16,
                              ),
                              title: Text(r.fullName),
                              subtitle: r.description.isEmpty
                                  ? null
                                  : Text(
                                      r.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () => setState(() {
                                _url.text = r.cloneUrl;
                                _name.text = r.name;
                              }),
                            ),
                        ],
                      ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _url,
              decoration: InputDecoration(
                labelText: tr('Dirección del repositorio'),
                hintText: tr('https://github.com/usuario/repo.git'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Dentro de: {0}', [_parent]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final d = await getDirectoryPath(
                      initialDirectory: _parent,
                      confirmButtonText: tr('Elegir'),
                    );
                    if (d != null) setState(() => _parent = d);
                  },
                  icon: const Icon(LucideIcons.folderOpen, size: 16),
                  label: Text(tr('Elegir…')),
                ),
              ],
            ),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: tr('Carpeta nueva (opcional)'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancelar')),
        ),
        FilledButton.icon(
          onPressed: _url.text.trim().isEmpty || _parent.isEmpty
              ? null
              : () => Navigator.pop(context, (
                  url: _url.text.trim(),
                  parent: _parent,
                  name: _name.text.trim(),
                )),
          icon: const Icon(LucideIcons.gitFork, size: 16),
          label: Text(tr('Clonar y abrir')),
        ),
      ],
    );
  }
}

/// Mensaje de error en una línea, en rojo.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}
