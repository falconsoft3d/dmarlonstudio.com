import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../code/github.dart';
import '../../code/workspace.dart';
import '../../core/errors.dart';
import '../../core/project_store.dart';
import '../../i18n/i18n.dart';
import '../theme.dart';

/// Abre GitHub para el proyecto de la carpeta [dir]: publicarlo, o
/// confirmar y subir sus cambios. [beforeGit] guarda el proyecto antes de
/// tocar git (false si no se pudo).
Future<void> showProjectGitHub(
  BuildContext context, {
  required String dir,
  required String name,
  Future<bool> Function()? beforeGit,
}) => showDialog<void>(
  context: context,
  builder: (_) => _GitHubDialog(dir: dir, name: name, beforeGit: beforeGit),
);

class _GitHubDialog extends StatefulWidget {
  const _GitHubDialog({required this.dir, required this.name, this.beforeGit});
  final String dir, name;
  final Future<bool> Function()? beforeGit;

  @override
  State<_GitHubDialog> createState() => _GitHubDialogState();
}

class _GitHubDialogState extends State<_GitHubDialog> {
  late final _ws = CodeWorkspace(widget.dir);
  final _token = TextEditingController();
  late final _repoName = TextEditingController(
    text: ProjectStore.slug(widget.name).replaceAll('_', '-'),
  );
  final _desc = TextEditingController();
  late final _message = TextEditingController(
    text: tr('Cambios desde DMarlon Studio'),
  );

  bool _loading = true, _busy = false, _private = true;
  String? _login;
  bool _repo = false;
  String? _remote;
  List<GitChange> _changes = const [];
  ({int ahead, int behind})? _track;
  String _log = '';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _token.dispose();
    _repoName.dispose();
    _desc.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await GitHubAuth.load();
      String? login;
      if (token != null) {
        try {
          login = await GitHub.user();
        } on Object {
          login = null;
        }
      }
      final repo = await _ws.isRepo();
      final remotes = repo ? await _ws.remotes() : const <GitRemote>[];
      final origin =
          remotes.where((r) => r.name == 'origin').firstOrNull ??
          remotes.firstOrNull;
      _login = login;
      _repo = repo;
      _remote = origin?.url;
      _changes = repo ? await _ws.status() : const [];
      _track = repo && origin != null ? await _ws.aheadBehind() : null;
    } on UserError catch (e) {
      _say(e.message, error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _say(String text, {bool error = false}) {
    _log = text.trim();
    _error = error;
  }

  /// Ejecuta [op] con el proyecto guardado, mostrando su salida.
  Future<void> _run(Future<String> Function() op) async {
    if (widget.beforeGit != null && !await widget.beforeGit!()) return;
    setState(() => _busy = true);
    try {
      _say(await op());
    } on UserError catch (e) {
      _say(e.message, error: true);
    } on Object catch (e) {
      _say('$e', error: true);
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _saveToken() async {
    final t = _token.text.trim();
    if (t.isEmpty) return;
    setState(() => _busy = true);
    try {
      final login = await GitHub.user(token: t);
      await GitHubAuth.save(t);
      _token.clear();
      _say(tr('Conectado como @{0}.', [login]));
    } on UserError catch (e) {
      _say(e.message, error: true);
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  /// Primera vez: repositorio local, primer commit, repositorio en GitHub
  /// y subida.
  Future<void> _publish() => _run(() async {
    final out = <String>[];
    if (!_repo) out.add(await _ws.init());
    if ((await _ws.status()).isNotEmpty) {
      out.add(await _ws.commit(tr('Primera versión')));
    }
    if ((await _ws.head()).isEmpty) {
      throw UserError(tr('El proyecto no tiene archivos que subir.'));
    }
    final repo = await GitHub.create(
      _repoName.text,
      description: _desc.text,
      private: _private,
    );
    await _ws.setRemote('origin', repo.cloneUrl);
    out.add(await _ws.push());
    out.insert(0, tr('Publicado en {0}', [repo.htmlUrl]));
    return out.join('\n');
  });

  Future<void> _commitAndPush() => _run(() async {
    final out = <String>[];
    if ((await _ws.status()).isNotEmpty) {
      out.add(await _ws.commit(_message.text));
    }
    out.add(await _ws.push());
    return '${tr('Subido.')}\n${out.join('\n')}';
  });

  Future<void> _pull() => _run(_ws.pull);

  Widget _account(ThemeData t) {
    if (_login != null) {
      return Row(
        children: [
          const Icon(
            LucideIcons.circleCheck,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('Conectado como @{0}', [_login]))),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await GitHubAuth.save(null);
                    await _load();
                  },
            child: Text(tr('Desconectar')),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            'Conecte su cuenta con un token de GitHub (permiso «repo») para crear repositorios y subir sin contraseña. Se guarda solo en este equipo.',
          ),
          style: t.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _token,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('Token de GitHub'),
                  isDense: true,
                ),
                onSubmitted: (_) => _saveToken(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _saveToken,
              child: Text(tr('Conectar')),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(GitHub.newTokenUrl)),
          icon: const Icon(LucideIcons.externalLink, size: 14),
          label: Text(tr('Crear un token en GitHub')),
        ),
      ],
    );
  }

  Widget _publishForm(ThemeData t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _repo
            ? tr('El proyecto tiene git pero no está en GitHub.')
            : tr('El proyecto aún no está en GitHub.'),
        style: t.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _repoName,
        decoration: InputDecoration(
          labelText: tr('Nombre del repositorio'),
          isDense: true,
        ),
      ),
      TextField(
        controller: _desc,
        decoration: InputDecoration(
          labelText: tr('Descripción'),
          isDense: true,
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _private,
        onChanged: (v) => setState(() => _private = v),
        title: Text(tr('Privado')),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _busy || _login == null ? null : _publish,
          icon: const Icon(LucideIcons.cloudUpload, size: 16),
          label: Text(tr('Publicar en GitHub')),
        ),
      ),
    ],
  );

  Widget _syncForm(ThemeData t) {
    final web = _remote == null ? null : GitHubAuth.webUrl(_remote!);
    final ahead = _track?.ahead ?? 0, behind = _track?.behind ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.gitBranch, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                web ?? _remote ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (web != null)
              IconButton(
                tooltip: tr('Abrir en GitHub'),
                icon: const Icon(LucideIcons.externalLink, size: 16),
                onPressed: () => launchUrl(Uri.parse(web)),
              ),
          ],
        ),
        Text(
          [
            _changes.isEmpty
                ? tr('Sin cambios pendientes.')
                : tr('{0} archivos con cambios.', [_changes.length]),
            if (ahead > 0) tr('{0} commits por subir.', [ahead]),
            if (behind > 0) tr('{0} commits por traer.', [behind]),
          ].join(' '),
          style: t.textTheme.bodySmall,
        ),
        if (_changes.isNotEmpty) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in _changes)
                  Text(
                    '${c.status.padRight(2)}  ${c.path}',
                    style: const TextStyle(
                      fontFamily: 'DejaVuSansMono',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            decoration: InputDecoration(
              labelText: tr('Mensaje del commit'),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pull,
              icon: const Icon(LucideIcons.cloudDownload, size: 16),
              label: Text(tr('Traer cambios')),
            ),
            FilledButton.icon(
              onPressed: _busy || (_changes.isEmpty && ahead == 0)
                  ? null
                  : _commitAndPush,
              icon: const Icon(LucideIcons.cloudUpload, size: 16),
              label: Text(
                _changes.isEmpty ? tr('Subir') : tr('Confirmar y subir'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.gitFork, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('GitHub · {0}', [widget.name]))),
          if (_busy || _loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _account(t),
              const Divider(height: 24),
              if (!_loading) _remote == null ? _publishForm(t) : _syncForm(t),
              if (_log.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    _log,
                    style: TextStyle(
                      fontFamily: 'DejaVuSansMono',
                      fontSize: 11.5,
                      color: _error ? AppColors.danger : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cerrar')),
        ),
      ],
    );
  }
}
