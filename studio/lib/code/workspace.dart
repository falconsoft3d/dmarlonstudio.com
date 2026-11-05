import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/settings.dart';
import '../i18n/tr.dart';
import 'exe.dart';
import 'github.dart';

/// Resultado de una búsqueda en los archivos de la carpeta.
typedef CodeHit = ({String path, int line, int column, String text});

/// Cambio pendiente de git (`git status`).
typedef GitChange = ({String status, String path});

/// Commit del historial (`git log`).
typedef GitCommit = ({
  String hash,
  String short,
  String author,
  String email,
  DateTime date,
  List<String> parents,
  List<String> refs,
  String subject,
});

/// Rama local o remota (`git for-each-ref`).
typedef GitBranch = ({
  String name,
  bool remote,
  bool current,
  String upstream,
  String track,
  String hash,
  String subject,
});

/// Cambios guardados aparte (`git stash list`).
typedef GitStash = ({String ref, String message});

/// Remoto del repositorio (`git remote -v`).
typedef GitRemote = ({String name, String url});

/// Carpeta abierta en el editor de código: archivos, búsqueda, git y
/// órdenes de terminal (todo local, en este equipo).
class CodeWorkspace {
  CodeWorkspace(this.root);

  /// Carpeta abierta (ruta absoluta).
  final String root;

  /// Archivos más grandes no se abren en el editor.
  static const maxEditable = 5 * 1024 * 1024;

  /// La búsqueda no lee archivos mayores que esto.
  static const maxSearchable = 1024 * 1024;

  /// Carpetas que no se recorren al buscar.
  static const skipDirs = {
    '.git',
    'node_modules',
    '__pycache__',
    '.dart_tool',
    'build',
    '.venv',
    'venv',
    '.idea',
  };

  /// Lo que no se muestra en el explorador.
  static const hidden = {'.git', '.DS_Store'};

  // ------------------------------------------------------------ lenguajes
  /// Lenguaje para el resaltado según la extensión (o el nombre).
  static String languageOf(String path) {
    final name = p.basename(path).toLowerCase();
    if (name == 'dockerfile') return 'dockerfile';
    if (name == 'makefile') return 'makefile';
    return switch (p.extension(name)) {
      '.py' || '.pyw' => 'python',
      '.js' || '.mjs' || '.cjs' || '.jsx' => 'javascript',
      '.ts' || '.tsx' => 'typescript',
      '.dart' => 'dart',
      '.xml' || '.html' || '.htm' || '.svg' || '.xsd' || '.plist' => 'xml',
      '.json' || '.arb' => 'json',
      '.css' => 'css',
      '.scss' => 'scss',
      '.less' => 'less',
      '.yaml' || '.yml' => 'yaml',
      '.sh' || '.bash' || '.zsh' || '.command' => 'bash',
      '.sql' => 'sql',
      '.md' || '.markdown' => 'markdown',
      '.java' => 'java',
      '.kt' || '.kts' => 'kotlin',
      '.swift' => 'swift',
      '.go' => 'go',
      '.rs' => 'rust',
      '.php' => 'php',
      '.rb' => 'ruby',
      '.c' || '.h' => 'c',
      '.cpp' || '.cc' || '.hpp' || '.cxx' => 'cpp',
      '.cs' => 'csharp',
      '.ini' || '.cfg' || '.conf' || '.toml' => 'ini',
      '.properties' || '.env' => 'properties',
      _ => 'plaintext',
    };
  }

  // ------------------------------------------------------------- archivos
  /// Contenido de una carpeta: primero las carpetas, por nombre.
  Future<List<FileSystemEntity>> list(String dir) async {
    final out = <FileSystemEntity>[];
    try {
      await for (final e in Directory(dir).list(followLinks: false)) {
        if (!hidden.contains(p.basename(e.path))) out.add(e);
      }
    } on FileSystemException {
      return out;
    }
    out.sort((a, b) {
      final da = a is Directory, db = b is Directory;
      if (da != db) return da ? -1 : 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
    return out;
  }

  /// ¿Parece binario? (un byte nulo al principio).
  static bool isBinary(List<int> head) => head.take(8000).contains(0);

  /// Texto de un archivo para editarlo. Error si es binario o enorme.
  static Future<String> read(String path) async {
    final f = File(path);
    final size = await f.length();
    if (size > maxEditable) {
      throw UserError(
        tr('El archivo es demasiado grande para editarlo ({0} MB).', [
          (size / 1024 / 1024).toStringAsFixed(1),
        ]),
      );
    }
    final bytes = await f.readAsBytes();
    if (isBinary(bytes)) {
      throw UserError(tr('Es un archivo binario: no se puede editar aquí.'));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static Future<void> write(String path, String text) =>
      File(path).writeAsString(text, flush: true);

  /// La ruta debe quedar dentro de la carpeta abierta.
  String inside(String dir, String name) {
    final n = name.trim();
    if (n.isEmpty ||
        n.contains('/') ||
        n.contains('\\') ||
        n == '.' ||
        n == '..') {
      throw UserError(tr('Nombre no válido.'));
    }
    final full = p.normalize(p.join(dir, n));
    if (!p.isWithin(root, full)) throw UserError(tr('Nombre no válido.'));
    return full;
  }

  Future<String> createFile(String dir, String name) async {
    final path = inside(dir, name);
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      throw UserError(tr('Ya existe «{0}».', [name]));
    }
    await File(path).create();
    return path;
  }

  Future<String> createFolder(String dir, String name) async {
    final path = inside(dir, name);
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      throw UserError(tr('Ya existe «{0}».', [name]));
    }
    await Directory(path).create();
    return path;
  }

  Future<String> rename(String path, String name) async {
    final target = inside(p.dirname(path), name);
    if (await FileSystemEntity.type(target) != FileSystemEntityType.notFound) {
      throw UserError(tr('Ya existe «{0}».', [name]));
    }
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).rename(target);
    } else {
      await File(path).rename(target);
    }
    return target;
  }

  Future<void> delete(String path) async {
    if (!p.isWithin(root, path)) throw UserError(tr('Nombre no válido.'));
    await (await FileSystemEntity.isDirectory(path)
            ? Directory(path)
            : File(path))
        .delete(recursive: true);
  }

  // ------------------------------------------------------------- búsqueda
  /// Busca [query] en los archivos de texto de la carpeta.
  Future<List<CodeHit>> search(
    String query, {
    bool caseSensitive = false,
    int maxResults = 500,
  }) async {
    final q = caseSensitive ? query : query.toLowerCase();
    if (q.isEmpty) return const [];
    final out = <CodeHit>[];
    Future<void> walk(Directory d) async {
      List<FileSystemEntity> items;
      try {
        items = await d.list(followLinks: false).toList();
      } on FileSystemException {
        return;
      }
      items.sort((a, b) => a.path.compareTo(b.path));
      for (final e in items) {
        if (out.length >= maxResults) return;
        final name = p.basename(e.path);
        if (e is Directory) {
          if (!skipDirs.contains(name)) await walk(e);
          continue;
        }
        if (e is! File || hidden.contains(name)) continue;
        try {
          if (await e.length() > maxSearchable) continue;
          final bytes = await e.readAsBytes();
          if (isBinary(bytes)) continue;
          final lines = const LineSplitter().convert(
            utf8.decode(bytes, allowMalformed: true),
          );
          for (var i = 0; i < lines.length && out.length < maxResults; i++) {
            final l = caseSensitive ? lines[i] : lines[i].toLowerCase();
            final c = l.indexOf(q);
            if (c >= 0) {
              final t = lines[i].trim();
              out.add((
                path: e.path,
                line: i,
                column: c,
                text: t.length > 200 ? '${t.substring(0, 200)}…' : t,
              ));
            }
          }
        } on FileSystemException {
          continue;
        }
      }
    }

    await walk(Directory(root));
    return out;
  }

  // ------------------------------------------------------------------ git
  /// Ejecuta git en la carpeta. [network]: habla con un remoto (más
  /// tiempo y, con un token de GitHub, se autentica con él).
  Future<ProcessResult> git(List<String> args, {bool network = false}) =>
      runGit(args, root, network: network);

  /// Ejecuta git en [dir] sin preguntar nunca por la terminal.
  static Future<ProcessResult> runGit(
    List<String> args,
    String dir, {
    bool network = false,
  }) async {
    final exe = findExecutable('git');
    if (exe == null) throw UserError(tr('No se encontró git en este equipo.'));
    try {
      return await Process.run(
        exe,
        [
          '-c',
          'core.quotePath=false',
          if (network) ...GitHubAuth.args(),
          ...args,
        ],
        workingDirectory: dir,
        runInShell: Platform.isWindows,
        environment: const {'GIT_TERMINAL_PROMPT': '0'},
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(Duration(minutes: network ? 15 : 2));
    } on ProcessException {
      throw UserError(tr('No se encontró git en este equipo.'));
    } on TimeoutException {
      throw UserError(tr('git no respondió a tiempo.'));
    }
  }

  /// ¿Es un repositorio de git?
  Future<bool> isRepo() async {
    try {
      return (await git(['rev-parse', '--is-inside-work-tree'])).exitCode == 0;
    } on UserError {
      return false;
    }
  }

  /// Rama actual ('' con HEAD separado o sin git).
  Future<String> branch() async =>
      '${(await git(['branch', '--show-current'])).stdout}'.trim();

  /// Commit actual abreviado ('' si aún no hay commits).
  Future<String> head() async {
    final r = await git(['rev-parse', '--short', 'HEAD']);
    return r.exitCode == 0 ? '${r.stdout}'.trim() : '';
  }

  /// Commits por subir y por traer respecto de la rama remota (null si la
  /// rama no sigue a ninguna).
  Future<({int ahead, int behind})?> aheadBehind() async {
    final r = await git([
      'rev-list',
      '--left-right',
      '--count',
      'HEAD...@{upstream}',
    ]);
    if (r.exitCode != 0) return null;
    final n = '${r.stdout}'.trim().split(RegExp(r'\s+'));
    if (n.length != 2) return null;
    return (ahead: int.tryParse(n[0]) ?? 0, behind: int.tryParse(n[1]) ?? 0);
  }

  /// Cambios pendientes (`git status --porcelain`).
  Future<List<GitChange>> status() async {
    final r = await git(['status', '--porcelain', '-uall']);
    if (r.exitCode != 0) throw UserError('${r.stderr}'.trim());
    return [
      for (final l in const LineSplitter().convert('${r.stdout}'))
        if (l.length > 3)
          (
            status: l.substring(0, 2).trim(),
            path: l.substring(3).replaceAll('"', '').split(' -> ').last,
          ),
    ];
  }

  String _out(ProcessResult r) {
    final s = [
      '${r.stdout}'.trim(),
      '${r.stderr}'.trim(),
    ].where((x) => x.isNotEmpty).join('\n');
    if (r.exitCode != 0) {
      throw UserError(
        s.isEmpty ? tr('git terminó con error ({0}).', [r.exitCode]) : s,
      );
    }
    return s;
  }

  Future<String> _run(List<String> args, {bool network = false}) async =>
      _out(await git(args, network: network));

  /// Crea el repositorio (rama «main»).
  Future<String> init() async {
    final r = await git(['init', '-b', 'main']);
    return r.exitCode == 0 ? _out(r) : _run(['init']);
  }

  /// Añade todo y confirma con [message].
  Future<String> commit(String message) async {
    if (message.trim().isEmpty) {
      throw UserError(tr('Escriba el mensaje del commit.'));
    }
    _out(await git(['add', '-A']));
    return _out(await git(['commit', '-m', message.trim()]));
  }

  /// Añade lo pendiente al último commit (y cambia su mensaje si hay uno).
  Future<String> amend(String message) async {
    await _run(['add', '-A']);
    return _run([
      'commit',
      '--amend',
      if (message.trim().isEmpty) '--no-edit' else ...['-m', message.trim()],
    ]);
  }

  /// Deshace el último commit: sus cambios vuelven a quedar pendientes.
  Future<String> undoLastCommit() => _run(['reset', '--soft', 'HEAD~1']);

  /// Sube la rama; la primera vez la publica en el remoto («origin» o el
  /// primero que haya) y la deja siguiéndolo.
  Future<String> push() async {
    final up = await git(['rev-parse', '--abbrev-ref', '@{upstream}']);
    if (up.exitCode == 0) {
      return _run(['push', '--follow-tags'], network: true);
    }
    final name = await branch();
    if (name.isEmpty) {
      throw UserError(tr('Cambie a una rama para subir (HEAD separado).'));
    }
    final rs = await remotes();
    if (rs.isEmpty) {
      throw UserError(
        tr('El repositorio no tiene remoto: publíquelo en GitHub o añada uno.'),
      );
    }
    final remote = rs.any((r) => r.name == 'origin') ? 'origin' : rs.first.name;
    return _run(['push', '--follow-tags', '-u', remote, name], network: true);
  }

  Future<String> pull() =>
      _run(['pull', '--ff-only', '--no-rebase'], network: true);

  /// Trae los cambios de todos los remotos (sin tocar los archivos).
  Future<String> fetch() => _run(['fetch', '--all', '--prune'], network: true);

  /// Diferencias de [path] con el último commit (y las de un archivo nuevo).
  Future<String> diff(String path) async {
    var r = await git(['diff', '--no-color', 'HEAD', '--', path]);
    if (r.exitCode != 0) r = await git(['diff', '--no-color', '--', path]);
    var out = '${r.stdout}';
    if (out.trim().isEmpty) {
      final tracked = await git(['ls-files', '--error-unmatch', '--', path]);
      if (tracked.exitCode != 0 && File(p.join(root, path)).existsSync()) {
        out =
            '${(await git(['diff', '--no-color', '--no-index', '--', Platform.isWindows ? 'NUL' : '/dev/null', path])).stdout}';
      }
    }
    return _cap(out);
  }

  /// Los diffs muy grandes se cortan (el editor no los necesita enteros).
  static String _cap(String s, [int max = 400000]) => s.length <= max
      ? s
      : '${s.substring(0, max)}\n… ${tr('(diferencias recortadas)')}';

  /// Descarta los cambios de [change] (un archivo nuevo se borra).
  Future<void> discard(GitChange change) async {
    if (change.status == '??' || change.status.contains('A')) {
      await git([
        'rm',
        '-q',
        '--cached',
        '--ignore-unmatch',
        '--',
        change.path,
      ]);
      final f = File(p.join(root, change.path));
      if (await f.exists()) await f.delete();
      return;
    }
    await _run(['checkout', 'HEAD', '--', change.path]);
  }

  /// Descarta todos los cambios pendientes y borra los archivos nuevos.
  Future<String> discardAll() async {
    final a = await _run(['reset', '--hard', 'HEAD']);
    final b = await _run(['clean', '-fd']);
    return '$a\n$b'.trim();
  }

  /// Historial (los últimos [limit]; [all]: de todas las ramas).
  Future<List<GitCommit>> log({int limit = 300, bool all = false}) async {
    final r = await git([
      'log',
      '--no-color',
      '--format=%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%P%x1f%D%x1f%s%x1e',
      '-n',
      '$limit',
      if (all) '--all',
    ]);
    if (r.exitCode != 0) return [];
    return [
      for (final rec in '${r.stdout}'.split('\x1e'))
        if (rec.trim().split('\x1f') case final f when f.length >= 8)
          (
            hash: f[0].trim(),
            short: f[1],
            author: f[2],
            email: f[3],
            date: DateTime.tryParse(f[4]) ?? DateTime(1970),
            parents: f[5].split(' ').where((x) => x.isNotEmpty).toList(),
            refs: f[6]
                .split(', ')
                .where((x) => x.isNotEmpty)
                .map((x) => x.replaceFirst('HEAD -> ', ''))
                .toList(),
            subject: f.sublist(7).join('\x1f'),
          ),
    ];
  }

  /// Archivos que cambió el commit [hash].
  Future<List<GitChange>> commitFiles(String hash) async {
    final r = await git([
      'show',
      '--no-color',
      '--format=',
      '--name-status',
      '-M',
      hash,
    ]);
    if (r.exitCode != 0) throw UserError('${r.stderr}'.trim());
    return [
      for (final l in const LineSplitter().convert('${r.stdout}'))
        if (l.split('\t') case final f when f.length >= 2)
          (status: f[0].substring(0, 1), path: f.last),
    ];
  }

  /// Mensaje completo y diferencias del commit [hash] (o solo de [path]).
  Future<String> commitDiff(String hash, {String? path}) async => _cap(
    await _run([
      'show',
      '--no-color',
      '-M',
      '--format=commit %H%nAuthor: %an <%ae>%nDate:   %aI%n%n%B',
      hash,
      if (path != null) ...['--', path],
    ]),
  );

  /// Va al commit [hash] (HEAD separado: para mirar o probar una versión).
  Future<String> checkoutCommit(String hash) =>
      _run(['checkout', '--detach', hash]);

  /// Lleva la rama actual al commit [hash]. [mode]: `soft` (los cambios
  /// quedan preparados), `mixed` (quedan pendientes) o `hard` (se pierden).
  Future<String> resetTo(String hash, String mode) {
    if (!const {'soft', 'mixed', 'hard'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode');
    }
    return _run(['reset', '--$mode', hash]);
  }

  /// Crea un commit que deshace el commit [hash].
  Future<String> revert(String hash) => _run(['revert', '--no-edit', hash]);

  /// Aplica el commit [hash] (de otra rama) sobre la actual.
  Future<String> cherryPick(String hash) => _run(['cherry-pick', hash]);

  /// Ramas locales y remotas.
  Future<List<GitBranch>> branches() async {
    final r = await git([
      'for-each-ref',
      '--format=%(refname)%1f%(HEAD)%1f%(upstream:short)%1f%(upstream:track)%1f%(objectname:short)%1f%(contents:subject)',
      '--sort=-committerdate',
      'refs/heads',
      'refs/remotes',
    ]);
    if (r.exitCode != 0) return [];
    return [
      for (final l in const LineSplitter().convert('${r.stdout}'))
        if (l.split('\x1f') case final f when f.length >= 6)
          if (!f[0].endsWith('/HEAD'))
            (
              name: f[0].startsWith('refs/heads/')
                  ? f[0].substring(11)
                  : f[0].substring(13),
              remote: f[0].startsWith('refs/remotes/'),
              current: f[1] == '*',
              upstream: f[2],
              track: f[3].replaceAll(RegExp(r'[\[\]]'), ''),
              hash: f[4],
              subject: f.sublist(5).join('\x1f'),
            ),
    ];
  }

  /// Comprueba que [name] sirve como nombre de rama o etiqueta.
  Future<String> _refName(String name) async {
    final n = name.trim();
    if (n.isEmpty ||
        (await git(['check-ref-format', '--branch', n])).exitCode != 0) {
      throw UserError(tr('«{0}» no es un nombre válido.', [n]));
    }
    return n;
  }

  /// Crea la rama [name] (desde [from] o el commit actual) y cambia a ella.
  Future<String> createBranch(
    String name, {
    String? from,
    bool checkout = true,
  }) async {
    final n = await _refName(name);
    return _run([
      if (checkout) ...['checkout', '-b'] else 'branch',
      n,
      ?from,
    ]);
  }

  /// Cambia a la rama [name]; una remota («origin/x») crea la local que la
  /// sigue (o cambia a ella si ya existe).
  Future<String> switchBranch(String name, {bool remote = false}) async {
    if (!remote) return _run(['checkout', name]);
    final local = name.substring(name.indexOf('/') + 1);
    final exists =
        (await git([
          'rev-parse',
          '--verify',
          '--quiet',
          'refs/heads/$local',
        ])).exitCode ==
        0;
    return exists
        ? _run(['checkout', local])
        : _run(['checkout', '--track', name]);
  }

  Future<String> renameBranch(String from, String to) async =>
      _run(['branch', '-m', from, await _refName(to)]);

  /// Borra la rama local [name] ([force]: aunque no esté fusionada).
  Future<String> deleteBranch(String name, {bool force = false}) =>
      _run(['branch', force ? '-D' : '-d', name]);

  /// Borra la rama remota [name] («origin/x») del servidor.
  Future<String> deleteRemoteBranch(String name) {
    final i = name.indexOf('/');
    return _run([
      'push',
      name.substring(0, i),
      '--delete',
      name.substring(i + 1),
    ], network: true);
  }

  /// Fusiona la rama [name] en la actual.
  Future<String> merge(String name) => _run(['merge', '--no-edit', name]);

  /// Crea la etiqueta [name] en [hash] (se sube con el siguiente push).
  Future<String> tag(String name, String hash) async =>
      _run(['tag', await _refName(name), hash]);

  /// Guarda aparte los cambios pendientes (también los archivos nuevos).
  Future<String> stash(String message) => _run([
    'stash',
    'push',
    '--include-untracked',
    if (message.trim().isNotEmpty) ...['-m', message.trim()],
  ]);

  Future<List<GitStash>> stashes() async {
    final r = await git(['stash', 'list', '--format=%gd%x1f%s']);
    if (r.exitCode != 0) return [];
    return [
      for (final l in const LineSplitter().convert('${r.stdout}'))
        if (l.split('\x1f') case final f when f.length >= 2)
          (ref: f[0], message: f.sublist(1).join(' ')),
    ];
  }

  /// Recupera los cambios guardados [ref] ([drop]: y los quita de la lista).
  Future<String> stashApply(String ref, {bool drop = false}) =>
      _run(['stash', drop ? 'pop' : 'apply', ref]);

  Future<String> stashDrop(String ref) => _run(['stash', 'drop', ref]);

  Future<List<GitRemote>> remotes() async {
    final r = await git(['remote', '-v']);
    if (r.exitCode != 0) return [];
    final out = <GitRemote>[];
    for (final l in const LineSplitter().convert('${r.stdout}')) {
      final f = l.split(RegExp(r'\s+'));
      if (f.length >= 2 && !out.any((x) => x.name == f[0])) {
        out.add((name: f[0], url: f[1]));
      }
    }
    return out;
  }

  /// Añade el remoto [name] o cambia su dirección.
  Future<void> setRemote(String name, String url) async {
    final n = name.trim(), u = url.trim();
    if (n.isEmpty || u.isEmpty) {
      throw UserError(tr('Indique el nombre y la dirección del remoto.'));
    }
    final has = (await remotes()).any((r) => r.name == n);
    await _run(['remote', has ? 'set-url' : 'add', n, u]);
  }

  Future<void> removeRemote(String name) => _run(['remote', 'remove', name]);

  /// Página del repositorio en GitHub (del remoto «origin» o el primero).
  Future<String?> webUrl() async {
    final rs = await remotes();
    if (rs.isEmpty) return null;
    final r = rs.firstWhere((x) => x.name == 'origin', orElse: () => rs.first);
    return GitHubAuth.webUrl(r.url);
  }

  /// Clona [url] dentro de [parent] (en la carpeta [name] o la del
  /// repositorio) y devuelve la ruta creada.
  static Future<String> clone(String url, String parent, {String? name}) async {
    final u = url.trim();
    if (u.isEmpty) throw UserError(tr('Indique la dirección del repositorio.'));
    final folder = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : p.basenameWithoutExtension(
            u.replaceAll(RegExp(r'[/\\]+$'), '').split(RegExp('[/:]')).last,
          );
    final dest = p.join(parent, folder);
    if (await Directory(dest).exists() &&
        await Directory(dest).list().isEmpty == false) {
      throw UserError(tr('La carpeta {0} ya existe y no está vacía.', [dest]));
    }
    final r = await runGit(['clone', u, dest], parent, network: true);
    if (r.exitCode != 0) {
      throw UserError(
        '${r.stderr}'.trim().isEmpty
            ? tr('git terminó con error ({0}).', [r.exitCode])
            : '${r.stderr}'.trim(),
      );
    }
    return dest;
  }

  // ------------------------------------------------------------- terminal
  /// Ejecuta una orden en la carpeta (con el intérprete del sistema). La
  /// terminal no tiene teclado para el programa: su entrada se cierra, y lo
  /// que espera una respuesta (`input()`, `git commit` sin `-m`, la
  /// contraseña de git) termina enseguida en lugar de quedarse esperando.
  Future<Process> run(String command, {String? cwd}) async {
    final dir = cwd ?? root;
    const env = {'GIT_TERMINAL_PROMPT': '0'};
    final Process p;
    if (Platform.isWindows) {
      p = await Process.start(
        'cmd',
        ['/c', command],
        workingDirectory: dir,
        environment: env,
      );
    } else {
      final shell = [
        Platform.environment['SHELL'],
        '/bin/zsh',
        '/bin/bash',
        '/bin/sh',
      ].whereType<String>().firstWhere((s) => findExecutable(s) != null);
      p = await Process.start(
        shell,
        ['-lc', command],
        workingDirectory: dir,
        environment: env,
      );
    }
    await p.stdin.close();
    return p;
  }

  /// Carpeta de trabajo de serie: `~/Documents/DMarlon Studio`.
  static String get defaultFolder {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, 'Documents', 'DMarlon Studio');
  }

  // -------------------------------------------------- carpetas recientes
  static String get _key => 'code.recent';

  static Future<List<String>> recent() async {
    try {
      final v = jsonDecode(await Settings.get(_key) ?? '[]');
      return [
        for (final x in v as List)
          if (Directory('$x').existsSync()) '$x',
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> remember(String folder) async {
    final list = [
      folder,
      ...(await recent()).where((x) => x != folder),
    ].take(10).toList();
    await Settings.set(_key, jsonEncode(list));
  }
}
