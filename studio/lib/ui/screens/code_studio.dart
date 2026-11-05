import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/less.dart';
import 'package:re_highlight/languages/makefile.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/properties.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart' show Mode;
import 'package:re_highlight/styles/vs.dart';
import 'package:re_highlight/styles/vs2015.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai/assistant.dart';
import '../../ai/claude_agent.dart';
import '../../ai/text_diff.dart';
import '../../code/github.dart';
import '../../code/tk_codegen.dart';
import '../../code/workspace.dart';
import '../../core/settings.dart';
import '../../core/errors.dart';
import '../../i18n/i18n.dart';
import '../tk_project.dart';
import '../widgets.dart';

part 'code_claude.dart';
part 'code_git.dart';

// Colores de VS Code (tema oscuro).
/// Modo del editor: lo fija la pantalla según el tema de la aplicación.
var _dark = true;
Color _t(int night, int day) => Color(_dark ? night : day);
Color get _bg => _t(0xFF1E1E1E, 0xFFFFFFFF);
Color get _side => _t(0xFF252526, 0xFFF3F3F3);
Color get _activity => _t(0xFF333333, 0xFFE8E8E8);
Color get _tabBar => _t(0xFF252526, 0xFFF3F3F3);
Color get _tabOff => _t(0xFF2D2D2D, 0xFFECECEC);
Color get _line => _t(0xFF3C3C3C, 0xFFD4D4D4);
Color get _text => _t(0xFFCCCCCC, 0xFF333333);
Color get _dim => _t(0xFF8C8C8C, 0xFF6E6E6E);
Color get _accent => _t(0xFF0E639C, 0xFF007ACC);
const _status = Color(0xFF007ACC);
const _mono = 'Menlo';
const _monoFallback = ['Consolas', 'Monaco', 'Courier New', 'monospace'];

final _modes = <String, Mode>{
  'python': langPython,
  'javascript': langJavascript,
  'typescript': langTypescript,
  'dart': langDart,
  'xml': langXml,
  'json': langJson,
  'css': langCss,
  'scss': langScss,
  'less': langLess,
  'yaml': langYaml,
  'bash': langBash,
  'sql': langSql,
  'markdown': langMarkdown,
  'java': langJava,
  'kotlin': langKotlin,
  'swift': langSwift,
  'go': langGo,
  'rust': langRust,
  'php': langPhp,
  'ruby': langRuby,
  'c': langC,
  'cpp': langCpp,
  'csharp': langCsharp,
  'ini': langIni,
  'properties': langProperties,
  'dockerfile': langDockerfile,
  'makefile': langMakefile,
  'plaintext': langPlaintext,
};

/// Archivo abierto en una pestaña.
class _Doc {
  _Doc(this.path, String text)
    : saved = text,
      project = null,
      readOnly = false,
      controller = CodeLineEditingController.fromText(text) {
    find = CodeFindController(controller);
  }

  /// Código del usuario de un proyecto del Diseñador. El texto es el del
  /// proyecto y cada cambio de la pestaña se escribe en él al momento; el
  /// controlador es aparte porque re_editor no admite dos editores montados
  /// sobre el mismo, y en la vista doble se ven los dos a la vez.
  _Doc.projectCode(TkProject this.project)
    : path = _codePath(project),
      saved = project.savedCode,
      readOnly = false,
      controller = CodeLineEditingController.fromText(project.code.text) {
    find = CodeFindController(controller);
  }

  /// Python generado desde el diseño: se rehace, no se edita.
  _Doc.projectGenerated(TkProject this.project)
    : path = _generatedPath(project),
      saved = '',
      readOnly = true,
      controller = CodeLineEditingController.fromText('') {
    find = CodeFindController(controller);
  }

  // Estos archivos no están en el disco: la ruta solo les da nombre y lenguaje.
  static String _codePath(TkProject p) => 'tk://${p.id}/code/${p.codeName}';
  static String _generatedPath(TkProject p) =>
      'tk://${p.id}/generated/${p.fileName}';

  String path;
  String saved;
  final TkProject? project;
  final bool readOnly;
  final CodeLineEditingController controller;
  late final CodeFindController find;
  bool dirty = false;

  /// Por qué no se puede generar el archivo (null si se puede).
  String? problem;
  String get language => CodeWorkspace.languageOf(path);
}

/// Estado del editor que sobrevive al cambiar de módulo dentro de
/// DMarlon Studio (como la «salida en caliente» de VS Code: no se pierde lo no
/// guardado).
class _Session {
  static CodeWorkspace? ws;
  static final docs = <_Doc>[];
  static int active = -1;
  static final expanded = <String>{};
  static String panel = 'explorer';
  static bool terminal = false;
  static final termLines = <String>[];
  static String? termCwd;
  static final history = <String>[];
  static final ai = <(String, String)>[];
  // Control de código: pestaña, historial de todas las ramas y repositorio
  // que se está clonando.
  static String gitTab = 'changes';
  static bool gitAll = false;
  static String? cloning;
}

/// Código: un editor al estilo de Visual Studio Code dentro de DMarlon Studio para
/// carpetas de este equipo (explorador, pestañas, búsqueda, git,
/// terminal y chat con la IA).
class CodeStudioScreen extends StatefulWidget {
  const CodeStudioScreen({super.key});
  @override
  State<CodeStudioScreen> createState() => _CodeStudioScreenState();
}

class _CodeStudioScreenState extends State<CodeStudioScreen>
    with _GitPanel, _ClaudePanel {
  @override
  CodeWorkspace? get _ws => _Session.ws;
  @override
  List<_Doc> get _docs => _Session.docs;
  _Doc? get _doc => _Session.active >= 0 && _Session.active < _docs.length
      ? _docs[_Session.active]
      : null;

  final _children = <String, List<FileSystemEntity>>{};
  List<String> _recent = [];
  // Búsqueda.
  final _query = TextEditingController();
  bool _case = false, _searching = false;
  List<CodeHit> _hits = [];
  // Terminal.
  final _cmd = TextEditingController();
  final _cmdFocus = FocusNode();
  final _termScroll = ScrollController();
  Process? _proc;
  int _historyAt = -1;
  // IA.
  final _ask = TextEditingController();
  bool _aiBusy = false;
  final _aiScroll = ScrollController();

  /// Proyecto abierto en el Diseñador, con la misma regla que el Diseñador.
  TkProject? get _project => TkProject.current;

  /// Hay algo que mostrar además de la bienvenida.
  bool get _working => _ws != null || _project != null || _docs.isNotEmpty;

  @override
  void initState() {
    super.initState();
    CodeWorkspace.recent().then((r) {
      if (mounted) setState(() => _recent = r);
    });
    TkProject.changes.addListener(_onProject);
    _syncProject();
    for (final d in _docs) {
      d.controller.addListener(_onEdit);
    }
    if (_ws != null) {
      _loadDir(_ws!.root);
      for (final e in _Session.expanded) {
        _loadDir(e);
      }
      _refreshGit();
    }
  }

  @override
  void dispose() {
    TkProject.changes.removeListener(_onProject);
    for (final d in _docs) {
      d.controller.removeListener(_onEdit);
    }
    _proc?.kill();
    _query.dispose();
    _cmd.dispose();
    _cmdFocus.dispose();
    _termScroll.dispose();
    _ask.dispose();
    _aiScroll.dispose();
    super.dispose();
  }

  void _onEdit() {
    final d = _doc;
    if (d == null || d.readOnly) return;
    final pr = d.project;
    if (pr != null) {
      final text = d.controller.text;
      if (text != pr.code.text) pr.code.text = text;
      return;
    }
    final dirty = d.controller.text != d.saved;
    if (dirty != d.dirty) setState(() => d.dirty = dirty);
  }

  // ------------------------------------------------- proyecto del Diseñador
  /// Lo último que se ha pintado del proyecto: con cada tecla no hace falta
  /// volver a pintar el Editor entero.
  String? _shownProject;

  String get _projectState => [
    _project?.id,
    _project?.name,
    _project?.dirty,
    _project?.design.isWeb,
    _Session.active,
    for (final d in _docs)
      if (d.project != null) ...[
        d.path,
        d.dirty,
        d.problem,
        d.project!.isOpen,
        d.project!.name,
      ],
  ].join('|');

  void _onProject() {
    if (!mounted) return;
    _syncProject();
    final now = _projectState;
    if (now != _shownProject) setState(() => _shownProject = now);
  }

  /// Pone las pestañas del proyecto al día. Un proyecto cerrado en el
  /// Diseñador solo deja su código, si hay algo sin guardar.
  void _syncProject() {
    for (var i = _docs.length - 1; i >= 0; i--) {
      final d = _docs[i];
      final pr = d.project;
      if (pr == null) continue;
      if (!d.readOnly) {
        final text = pr.code.text;
        if (text != d.controller.text) d.controller.text = text;
        d
          ..path = _Doc._codePath(pr)
          ..saved = pr.savedCode
          ..dirty = pr.codeDirty;
      } else {
        d.path = _Doc._generatedPath(pr);
      }
      if (!pr.isOpen && (d.readOnly || !d.dirty)) _dropDoc(i);
    }
    final d = _doc;
    if (d != null && d.readOnly) _regenerate(d);
  }

  void _regenerate(_Doc d) {
    final pr = d.project!;
    try {
      final text = TkCodegen.generate(pr.design, pr.code.text);
      d.problem = null;
      if (text != d.controller.text) d.controller.text = text;
    } on UserError catch (e) {
      d.problem = e.message;
    }
  }

  void _openProjectFile(TkProject pr, {required bool generated}) {
    var i = _docs.indexWhere(
      (d) => identical(d.project, pr) && d.readOnly == generated,
    );
    if (i < 0) {
      if (!generated) pr.inEditor = true;
      final d = generated ? _Doc.projectGenerated(pr) : _Doc.projectCode(pr);
      d.controller.addListener(_onEdit);
      _docs.add(d);
      i = _docs.length - 1;
    }
    setState(() {
      _Session.active = i;
      _syncProject();
    });
  }

  /// Quita la pestaña [i], sin preguntar.
  void _dropDoc(int i) {
    final d = _docs.removeAt(i);
    d.controller.removeListener(_onEdit);
    if (!d.readOnly) d.project?.inEditor = false;
    if (_Session.active > i) _Session.active--;
    if (_Session.active >= _docs.length) _Session.active = _docs.length - 1;
  }

  // ------------------------------------------------------------- carpeta
  @override
  Future<void> _openFolder([String? path]) async {
    final suggested = CodeWorkspace.defaultFolder;
    final dir =
        path ??
        await getDirectoryPath(
          confirmButtonText: tr('Abrir'),
          initialDirectory: Directory(suggested).existsSync() ? suggested : null,
        );
    if (dir == null || !mounted) return;
    if (_docs.any((d) => d.dirty && d.project == null)) {
      if (!await confirmDialog(
        context,
        tr('Cambios sin guardar'),
        tr(
          'Hay archivos con cambios sin guardar. ¿Cerrarlos y abrir otra carpeta?',
        ),
      )) {
        return;
      }
    }
    // Los archivos del proyecto del Diseñador no son de ninguna carpeta.
    for (final d in _docs.where((d) => d.project == null)) {
      d.controller.removeListener(_onEdit);
    }
    _docs.removeWhere((d) => d.project == null);
    _Session.active = _docs.length - 1;
    _Session.expanded.clear();
    _children.clear();
    _Session.ws = CodeWorkspace(dir);
    _Session.termCwd = dir;
    _hits = [];
    await CodeWorkspace.remember(dir);
    _recent = await CodeWorkspace.recent();
    await _loadDir(dir);
    await _refreshGit();
    if (mounted) setState(() {});
  }

  Future<void> _loadDir(String dir) async {
    final ws = _ws;
    if (ws == null) return;
    _children[dir] = await ws.list(dir);
    if (mounted) setState(() {});
  }

  Future<void> _refreshTree() async {
    final ws = _ws;
    if (ws == null) return;
    await _loadDir(ws.root);
    for (final e in [..._Session.expanded]) {
      if (await Directory(e).exists()) {
        await _loadDir(e);
      } else {
        _Session.expanded.remove(e);
      }
    }
  }

  // ------------------------------------------------------------ archivos
  @override
  Future<void> _open(String path, {int? line}) async {
    var i = _docs.indexWhere((d) => d.path == path);
    if (i < 0) {
      try {
        final text = await CodeWorkspace.read(path);
        final d = _Doc(path, text);
        d.controller.addListener(_onEdit);
        _docs.add(d);
        i = _docs.length - 1;
      } on UserError catch (e) {
        if (mounted) await showErrorDialog(context, e.message);
        return;
      } on FileSystemException catch (e) {
        if (mounted) await showErrorDialog(context, e.message);
        return;
      }
    }
    setState(() => _Session.active = i);
    if (line != null) {
      final c = _docs[i].controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (line < c.codeLines.length) {
          c.selectLine(line);
          c.makeCursorCenterIfInvisible();
        }
      });
    }
  }

  Future<void> _save([_Doc? doc]) async {
    final d = doc ?? _doc;
    if (d == null || d.readOnly) return;
    final pr = d.project;
    if (pr != null) {
      await runAction(context, pr.isOpen ? pr.save : pr.saveCode);
      return;
    }
    final text = d.controller.text;
    try {
      await CodeWorkspace.write(d.path, text);
      d.saved = text;
      setState(() => d.dirty = false);
      _refreshGit();
    } on FileSystemException catch (e) {
      if (mounted) await showErrorDialog(context, e.message);
    }
  }

  Future<void> _close(int i) async {
    final d = _docs[i];
    // Abierto en el Diseñador, lo que no se ha guardado sigue en el proyecto.
    if (d.dirty && !(d.project?.isOpen ?? false)) {
      final r = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            tr('¿Guardar los cambios de «{0}»?', [p.basename(d.path)]),
          ),
          content: Text(tr('Si no los guarda, se perderán.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(tr('Cancelar')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'discard'),
              child: Text(tr('No guardar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: Text(tr('Guardar')),
            ),
          ],
        ),
      );
      if (r == null) return;
      if (r == 'save') {
        await _save(d);
        if (d.dirty) return;
      }
    }
    // Al guardar, la pestaña de un proyecto cerrado ya se ha quitado.
    final at = _docs.indexOf(d);
    if (at >= 0 && mounted) setState(() => _dropDoc(at));
  }

  Future<void> _newEntry(String dir, {required bool folder}) async {
    final name = await promptText(
      context,
      folder ? tr('Nueva carpeta') : tr('Nuevo archivo'),
      '',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final path = await runAction(
      context,
      () => folder ? _ws!.createFolder(dir, name) : _ws!.createFile(dir, name),
    );
    if (path == null) return;
    _Session.expanded.add(dir);
    await _refreshTree();
    if (!folder) await _open(path);
  }

  Future<void> _rename(String path) async {
    final name = await promptText(context, tr('Renombrar'), p.basename(path));
    if (name == null || name.trim().isEmpty || name == p.basename(path)) {
      return;
    }
    if (!mounted) return;
    final target = await runAction(context, () => _ws!.rename(path, name));
    if (target == null) return;
    for (final d in _docs) {
      if (d.path == path) {
        d.path = target;
      } else if (p.isWithin(path, d.path)) {
        d.path = p.join(target, p.relative(d.path, from: path));
      }
    }
    await _refreshTree();
    _refreshGit();
  }

  Future<void> _delete(String path) async {
    if (!await confirmDialog(
      context,
      tr('Eliminar'),
      tr('¿Eliminar «{0}»? No se puede deshacer.', [p.basename(path)]),
      danger: true,
      ok: tr('Eliminar'),
    )) {
      return;
    }
    if (!mounted) return;
    final ok = await runAction(context, () async {
      await _ws!.delete(path);
      return true;
    });
    if (ok != true) return;
    for (var i = _docs.length - 1; i >= 0; i--) {
      if (_docs[i].path == path || p.isWithin(path, _docs[i].path)) {
        _docs[i].controller.removeListener(_onEdit);
        _docs.removeAt(i);
      }
    }
    if (_Session.active >= _docs.length) _Session.active = _docs.length - 1;
    await _refreshTree();
    _refreshGit();
  }

  /// Tras una orden de git que cambia archivos (cambiar de rama, ir a un
  /// commit, descartar…): se recargan el explorador y las pestañas sin
  /// cambios; las de archivos que ya no existen se cierran.
  @override
  Future<void> _reloadFromDisk() async {
    await _refreshTree();
    for (var i = _docs.length - 1; i >= 0; i--) {
      final d = _docs[i];
      if (d.dirty || d.project != null) continue;
      if (!await File(d.path).exists()) {
        d.controller.removeListener(_onEdit);
        _docs.removeAt(i);
        continue;
      }
      try {
        final text = await CodeWorkspace.read(d.path);
        if (text != d.saved) {
          d.saved = text;
          d.controller.text = text;
          d.dirty = false;
        }
      } on Object {
        // Binario o ilegible: se queda como estaba.
      }
    }
    if (_Session.active >= _docs.length) _Session.active = _docs.length - 1;
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------ terminal
  void _print(String line) {
    _Session.termLines.add(line);
    if (_Session.termLines.length > 5000) {
      _Session.termLines.removeRange(0, 1000);
    }
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_termScroll.hasClients) {
        _termScroll.jumpTo(_termScroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _runCommand(String raw) async {
    final ws = _ws;
    final cmd = raw.trim();
    if (ws == null || cmd.isEmpty || _proc != null) return;
    _cmd.clear();
    _Session.history.remove(cmd);
    _Session.history.add(cmd);
    _historyAt = -1;
    final cwd = _Session.termCwd ?? ws.root;
    _print('${p.basename(cwd)} \$ $cmd');
    if (cmd == 'clear' || cmd == 'cls') {
      setState(() => _Session.termLines.clear());
      return;
    }
    final cd = RegExp(r'^cd(?:\s+(.*))?$').firstMatch(cmd);
    if (cd != null) {
      final target = (cd[1] ?? '').trim();
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          ws.root;
      final dir = p.normalize(
        target.isEmpty || target == '~'
            ? home
            : target.startsWith('~/')
            ? p.join(home, target.substring(2))
            : p.isAbsolute(target)
            ? target
            : p.join(cwd, target),
      );
      if (await Directory(dir).exists()) {
        setState(() => _Session.termCwd = dir);
      } else {
        _print(tr('No existe la carpeta: {0}', [dir]));
      }
      return;
    }
    try {
      final proc = _proc = await ws.run(cmd, cwd: cwd);
      setState(() {});
      final done = [
        proc.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(_print)
            .asFuture<void>(),
        proc.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(_print)
            .asFuture<void>(),
      ];
      final code = await proc.exitCode;
      try {
        await Future.wait(done);
      } catch (_) {}
      if (code != 0) _print(tr('[terminó con el código {0}]', [code]));
    } on ProcessException catch (e) {
      _print(e.message);
    } finally {
      _proc = null;
      if (mounted) setState(() {});
      _refreshGit();
      _refreshTree();
    }
  }

  // ------------------------------------------------------------------ IA
  static String? _codeBlock(String text) =>
      RegExp(r'```[\w+-]*\n([\s\S]*?)```').firstMatch(text)?[1];

  Future<void> _sendAi() async {
    final q = _ask.text.trim();
    if (q.isEmpty || _aiBusy) return;
    _ask.clear();
    setState(() {
      _Session.ai.add(('user', q));
      _aiBusy = true;
    });
    final d = _doc;
    var file = d?.controller.text ?? '';
    if (file.length > 60000) file = '${file.substring(0, 60000)}\n…';
    final messages = <Map<String, Object?>>[
      {
        'role': 'system',
        'content':
            'You are a coding assistant inside the code editor of DMarlon Studio (like VS Code). '
            'Open folder: ${_ws?.root ?? '-'}. Answer in the language the user writes in, concisely, with Markdown. '
            'When you propose changes to the current file, give the COMPLETE new content of the file in a single fenced code block '
            'so the user can apply it with one click. Never invent files you have not seen.',
      },
      if (d != null)
        {
          'role': 'system',
          'content':
              'Current file: ${d.project != null ? p.basename(d.path) : p.relative(d.path, from: _ws!.root)} (${d.language}).\n```\n$file\n```',
        },
      for (final (r, t) in _Session.ai.reversed.take(12).toList().reversed)
        {'role': r, 'content': t},
    ];
    try {
      final answer = await Assistant(
        config: await AiConfig.load(),
      ).chat(messages);
      _Session.ai.add(('assistant', answer));
    } on UserError catch (e) {
      _Session.ai.add(('assistant', '⚠️ ${e.message}'));
    } finally {
      if (mounted) {
        setState(() => _aiBusy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_aiScroll.hasClients) {
            _aiScroll.jumpTo(_aiScroll.position.maxScrollExtent);
          }
        });
      }
    }
  }

  // ---------------------------------------------------------------- vista
  void _toggleTerminal() =>
      setState(() => _Session.terminal = !_Session.terminal);

  @override
  Widget build(BuildContext context) {
    _dark = Theme.of(context).brightness == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyJ, meta: true):
            _toggleTerminal,
        const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
            _toggleTerminal,
      },
      child: Focus(
        autofocus: true,
        child: DefaultTextStyle(
          style: TextStyle(color: _text, fontSize: 13),
          child: Material(
            color: _bg,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _activityBar(),
                      if (_working) SizedBox(width: 280, child: _sidePanel()),
                      if (_working) VerticalDivider(width: 1, color: _line),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _ws == null && _docs.isEmpty
                                  ? _welcome()
                                  : _editorArea(),
                            ),
                            if (_Session.terminal && _ws != null) _terminal(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activityBar() {
    Widget item(String key, IconData icon, String tip, {int badge = 0}) {
      final on =
          _Session.panel == key &&
          (_ws != null || key == 'explorer' && _working);
      return Tooltip(
        message: tip,
        child: InkWell(
          onTap: _ws == null
              ? null
              : () => setState(() => _Session.panel = key),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: on ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              backgroundColor: _accent,
              child: Icon(icon, color: on ? Colors.white : _dim, size: 22),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      color: _activity,
      child: Column(
        children: [
          item('explorer', LucideIcons.files, tr('Explorador')),
          item('search', LucideIcons.search, tr('Buscar')),
          item(
            'git',
            LucideIcons.gitBranch,
            tr('Control de código'),
            badge: _changes.length,
          ),
          item('claude', LucideIcons.wandSparkles, tr('Claude implementa')),
          item('ai', LucideIcons.sparkles, tr('Chat con la IA')),
          const Spacer(),
          IconButton(
            tooltip: tr('Terminal (⌘J)'),
            onPressed: _ws == null ? null : _toggleTerminal,
            icon: Icon(
              LucideIcons.squareTerminal,
              color: _Session.terminal ? Colors.white : _dim,
            ),
          ),
          IconButton(
            tooltip: tr('Abrir carpeta'),
            onPressed: _openFolder,
            icon: Icon(LucideIcons.folderOpen, color: _dim),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget _header(String title, [List<Widget> actions = const []]) => Container(
    height: 35,
    padding: const EdgeInsets.only(left: 16, right: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 11, letterSpacing: .6, color: _text),
          ),
        ),
        ...actions,
      ],
    ),
  );

  @override
  Widget _iconBtn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
    tooltip: tip,
    visualDensity: VisualDensity.compact,
    iconSize: 16,
    color: _text,
    disabledColor: _line,
    onPressed: onTap,
    icon: Icon(icon),
  );

  Widget _sidePanel() => Container(
    color: _side,
    child: switch (_Session.panel) {
      'search' => _searchPanel(),
      'git' => _gitPanel(),
      'ai' => _aiPanel(),
      'claude' => _claudePanel(),
      _ => _explorer(),
    },
  );

  // ----------------------------------------------------------- explorador
  Widget _explorer() {
    final ws = _ws;
    final changed = {
      if (ws != null)
        for (final c in _changes) p.join(ws.root, c.path),
    };
    final rows = <Widget>[];
    void add(String dir, int depth) {
      for (final e in _children[dir] ?? const <FileSystemEntity>[]) {
        final name = p.basename(e.path);
        final isDir = e is Directory;
        final open = _Session.expanded.contains(e.path);
        final active = _doc?.path == e.path;
        rows.add(
          GestureDetector(
            onSecondaryTapUp: (d) =>
                _entryMenu(e.path, isDir, d.globalPosition),
            child: InkWell(
              onTap: () async {
                if (isDir) {
                  setState(
                    () => open
                        ? _Session.expanded.remove(e.path)
                        : _Session.expanded.add(e.path),
                  );
                  if (!open) await _loadDir(e.path);
                } else {
                  await _open(e.path);
                }
              },
              child: Container(
                height: 22,
                color: active ? _t(0xFF37373D, 0xFFE4E6F1) : null,
                padding: EdgeInsets.only(left: 8.0 + depth * 12),
                child: Row(
                  children: [
                    Icon(
                      isDir
                          ? (open
                                ? LucideIcons.chevronDown
                                : LucideIcons.chevronRight)
                          : _fileIcon(name),
                      size: 14,
                      color: isDir ? _text : _fileColor(name),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: changed.contains(e.path)
                              ? const Color(0xFFE2C08D)
                              : _text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        if (isDir && open) add(e.path, depth + 1);
      }
    }

    if (ws != null) add(ws.root, 0);
    final project = _project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(tr('Explorador'), [
          if (ws != null) ...[
            _iconBtn(
              LucideIcons.filePlus,
              tr('Nuevo archivo'),
              () => _newEntry(ws.root, folder: false),
            ),
            _iconBtn(
              LucideIcons.folderPlus,
              tr('Nueva carpeta'),
              () => _newEntry(ws.root, folder: true),
            ),
            _iconBtn(LucideIcons.refreshCw, tr('Actualizar'), _refreshTree),
            _iconBtn(
              LucideIcons.listCollapse,
              tr('Contraer todo'),
              () => setState(_Session.expanded.clear),
            ),
          ],
        ]),
        if (project != null) _projectSection(project),
        if (ws != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Text(
              p.basename(ws.root).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: _text,
              ),
            ),
          ),
        Expanded(child: ListView(children: rows)),
      ],
    );
  }

  /// El proyecto abierto en el Diseñador, encima de la carpeta.
  Widget _projectSection(TkProject pr) {
    Widget row(String name, {required bool generated}) {
      final d = _doc;
      final active =
          d != null && identical(d.project, pr) && d.readOnly == generated;
      return InkWell(
        key: ValueKey(generated ? 'code-tk-generated' : 'code-tk-code'),
        onTap: () => _openProjectFile(pr, generated: generated),
        child: Container(
          height: 22,
          color: active ? _t(0xFF37373D, 0xFFE4E6F1) : null,
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Row(
            children: [
              Icon(_fileIcon(name), size: 14, color: _fileColor(name)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: _text),
                ),
              ),
              if (generated)
                Text(
                  tr('Solo lectura'),
                  style: TextStyle(fontSize: 11, color: _dim),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: tr('Proyecto abierto en el Diseñador de interfaz'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Icon(
                    pr.design.isWeb
                        ? LucideIcons.globe
                        : LucideIcons.appWindowMac,
                    size: 13,
                    color: _text,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${pr.name.toUpperCase()}${pr.dirty ? ' •' : ''}',
                      key: const ValueKey('code-tk-project'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          row(pr.codeName, generated: false),
          row(pr.fileName, generated: true),
        ],
      ),
    );
  }

  Future<void> _entryMenu(String path, bool isDir, Offset at) async {
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        if (isDir) ...[
          PopupMenuItem(value: 'file', child: Text(tr('Nuevo archivo'))),
          PopupMenuItem(value: 'folder', child: Text(tr('Nueva carpeta'))),
        ],
        PopupMenuItem(value: 'rename', child: Text(tr('Renombrar'))),
        PopupMenuItem(value: 'copy', child: Text(tr('Copiar la ruta'))),
        PopupMenuItem(
          value: 'terminal',
          child: Text(tr('Abrir en la terminal')),
        ),
        PopupMenuItem(value: 'delete', child: Text(tr('Eliminar'))),
      ],
    );
    switch (v) {
      case 'file':
        await _newEntry(path, folder: false);
      case 'folder':
        await _newEntry(path, folder: true);
      case 'rename':
        await _rename(path);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: path));
      case 'terminal':
        setState(() {
          _Session.termCwd = isDir ? path : p.dirname(path);
          _Session.terminal = true;
        });
      case 'delete':
        await _delete(path);
    }
  }

  static IconData _fileIcon(String name) =>
      switch (p.extension(name).toLowerCase()) {
        '.py' ||
        '.js' ||
        '.ts' ||
        '.dart' ||
        '.java' ||
        '.go' ||
        '.rs' ||
        '.php' => LucideIcons.fileCode,
        '.json' || '.yaml' || '.yml' || '.xml' => LucideIcons.fileJson,
        '.md' || '.txt' => LucideIcons.fileText,
        '.png' ||
        '.jpg' ||
        '.jpeg' ||
        '.gif' ||
        '.svg' ||
        '.webp' => LucideIcons.fileImage,
        '.xlsx' || '.xls' || '.csv' => LucideIcons.fileSpreadsheet,
        '.sh' => LucideIcons.squareTerminal,
        _ => LucideIcons.file,
      };

  static Color _fileColor(String name) =>
      switch (p.extension(name).toLowerCase()) {
        '.py' => const Color(0xFF4B8BBE),
        '.js' || '.mjs' => const Color(0xFFF1E05A),
        '.ts' || '.tsx' => const Color(0xFF3178C6),
        '.dart' => const Color(0xFF00B4AB),
        '.xml' || '.html' => const Color(0xFFE37933),
        '.json' => const Color(0xFFCBCB41),
        '.md' => const Color(0xFF519ABA),
        '.sh' => const Color(0xFF89E051),
        '.xlsx' || '.csv' => const Color(0xFF217346),
        _ => _dim,
      };

  // ------------------------------------------------------------- búsqueda
  Future<void> _search() async {
    final ws = _ws;
    if (ws == null || _query.text.isEmpty) return;
    setState(() => _searching = true);
    final hits = await ws.search(_query.text, caseSensitive: _case);
    if (mounted) setState(() => (_hits = hits, _searching = false));
  }

  Widget _searchPanel() {
    final byFile = <String, List<CodeHit>>{};
    for (final h in _hits) {
      (byFile[h.path] ??= []).add(h);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(tr('Buscar')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _darkField(
                  _query,
                  tr('Buscar en los archivos'),
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(
                tooltip: tr('Distinguir mayúsculas'),
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                color: _case ? Colors.white : _dim,
                onPressed: () => setState(() => _case = !_case),
                icon: const Icon(LucideIcons.caseSensitive),
              ),
            ],
          ),
        ),
        if (_searching) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Text(
            _hits.isEmpty
                ? ''
                : tr('{0} resultados en {1} archivos', [
                    _hits.length,
                    byFile.length,
                  ]),
            style: TextStyle(color: _dim, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final e in byFile.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 2),
                  child: Row(
                    children: [
                      Icon(
                        _fileIcon(e.key),
                        size: 14,
                        color: _fileColor(e.key),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.relative(e.key, from: _ws!.root),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value.length}',
                        style: TextStyle(color: _dim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                for (final h in e.value)
                  InkWell(
                    onTap: () => _open(h.path, line: h.line),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 2, 8, 2),
                      child: Text(
                        '${h.line + 1}: ${h.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: _mono,
                          fontFamilyFallback: _monoFallback,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget _darkField(
    TextEditingController c,
    String hint, {
    ValueChanged<String>? onSubmitted,
    int maxLines = 1,
  }) => TextField(
    controller: c,
    maxLines: maxLines,
    minLines: 1,
    onSubmitted: onSubmitted,
    style: TextStyle(color: _text, fontSize: 13),
    cursorColor: Colors.white,
    decoration: InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: _dim),
      filled: true,
      fillColor: _t(0xFF3C3C3C, 0xFFFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: _status),
      ),
    ),
  );

  // ------------------------------------------------------------------- IA
  Widget _aiPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(tr('Chat con la IA'), [
        _iconBtn(
          LucideIcons.trash2,
          tr('Nueva conversación'),
          () => setState(_Session.ai.clear),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          _doc == null
              ? tr('Abra un archivo para preguntar sobre él.')
              : tr('Contexto: {0}', [p.basename(_doc!.path)]),
          style: TextStyle(color: _dim, fontSize: 12),
        ),
      ),
      Expanded(
        child: ListView(
          controller: _aiScroll,
          padding: const EdgeInsets.all(12),
          children: [
            for (final (role, text) in _Session.ai)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: role == 'user'
                      ? _t(0xFF2B3A4A, 0xFFDCEBFA)
                      : _t(0xFF2D2D30, 0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: _text,
                      ),
                    ),
                    if (role == 'assistant' &&
                        _codeBlock(text) != null &&
                        _doc != null &&
                        !_doc!.readOnly)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            FilledButton.tonal(
                              onPressed: () {
                                _doc?.controller.text = _codeBlock(text)!;
                                _onEdit();
                              },
                              child: Text(tr('Aplicar al archivo')),
                            ),
                            TextButton(
                              onPressed: () => Clipboard.setData(
                                ClipboardData(text: _codeBlock(text)!),
                              ),
                              child: Text(tr('Copiar el código')),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (_aiBusy) const LinearProgressIndicator(minHeight: 2),
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
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                      _sendAi,
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    control: true,
                  ): _sendAi,
                },
                child: _darkField(
                  _ask,
                  tr('Pregunte o pida un cambio (⌘Intro)'),
                  maxLines: 5,
                ),
              ),
            ),
            _iconBtn(LucideIcons.send, tr('Enviar'), _aiBusy ? null : _sendAi),
          ],
        ),
      ),
    ],
  );

  // --------------------------------------------------------------- editor
  Widget _welcome() => Center(
    child: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.codeXml, size: 64, color: _dim),
          const SizedBox(height: 12),
          Text(
            tr('Código'),
            style: TextStyle(
              fontSize: 28,
              color: _text,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            tr(
              'Edite proyectos de este equipo con explorador, git, terminal e IA.',
            ),
            style: TextStyle(color: _dim),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
            ),
            onPressed: _openFolder,
            icon: const Icon(LucideIcons.folderOpen, size: 16),
            label: Text(tr('Abrir carpeta…')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: _text),
            onPressed: () async {
              final dir = CodeWorkspace.defaultFolder;
              await Directory(dir).create(recursive: true);
              await _openFolder(dir);
            },
            icon: const Icon(LucideIcons.folderHeart, size: 16),
            label: Text(
              tr('Abrir {0}', [p.basename(CodeWorkspace.defaultFolder)]),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: _text),
            onPressed: _Session.cloning != null ? null : _cloneRepo,
            icon: const Icon(LucideIcons.gitFork, size: 16),
            label: Text(
              _Session.cloning != null
                  ? tr('Clonando {0}…', [_Session.cloning!])
                  : tr('Clonar repositorio…'),
            ),
          ),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              tr('Recientes'),
              style: TextStyle(color: _text, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final r in _recent)
              InkWell(
                onTap: () => _openFolder(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: p.basename(r),
                          style: TextStyle(color: _t(0xFF3794FF, 0xFF0066BF)),
                        ),
                        TextSpan(
                          text: '   ${p.dirname(r)}',
                          style: TextStyle(color: _dim, fontSize: 12),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );

  Widget _tab(int i, _Doc doc) {
    final on = i == _Session.active;
    return GestureDetector(
      onTertiaryTapUp: (_) => _close(i),
      child: InkWell(
        onTap: () => setState(() {
          _Session.active = i;
          _syncProject();
        }),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: on ? _bg : _tabOff,
            border: Border(
              top: BorderSide(
                color: on ? _status : Colors.transparent,
                width: 1,
              ),
              right: BorderSide(color: _tabBar),
            ),
          ),
          child: Row(
            children: [
              Icon(_fileIcon(doc.path), size: 14, color: _fileColor(doc.path)),
              const SizedBox(width: 6),
              Text(
                p.basename(doc.path),
                style: TextStyle(
                  color: on ? _t(0xFFFFFFFF, 0xFF333333) : _dim,
                  fontSize: 13,
                ),
              ),
              SizedBox(
                width: 26,
                child: IconButton(
                  tooltip: tr('Cerrar'),
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  onPressed: () => _close(i),
                  icon: Icon(
                    doc.dirty ? Icons.circle : LucideIcons.x,
                    size: doc.dirty ? 10 : 14,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aviso bajo la ruta de un archivo del proyecto del Diseñador.
  Widget _notice(String text) => Container(
    width: double.infinity,
    color: _tabOff,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Text(text, style: TextStyle(color: _text, fontSize: 12)),
  );

  Widget _editorArea() {
    final d = _doc;
    final pr = d?.project;
    return Column(
      children: [
        Container(
          height: 35,
          color: _tabBar,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (final (i, doc) in _docs.indexed) _tab(i, doc)],
          ),
        ),
        if (d != null)
          Container(
            height: 22,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              [
                if (pr == null)
                  ...p.split(p.relative(d.path, from: _ws!.root))
                else ...[
                  pr.name,
                  p.basename(d.path),
                ],
              ].join('  ›  '),
              style: TextStyle(color: _dim, fontSize: 12),
            ),
          ),
        if (d != null && d.readOnly)
          _notice(tr('Se genera desde el diseño: aquí no se puede editar.')),
        if (d?.problem != null) _notice(d!.problem!),
        if (pr != null && !pr.isOpen)
          _notice(
            tr(
              '«{0}» ya no está abierto en el Diseñador. Al guardar, este código se escribe en el proyecto y la pestaña se cierra.',
              [pr.name],
            ),
          ),
        Expanded(
          child: d == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.codeXml,
                        size: 80,
                        color: _t(0xFF2E2E2E, 0xFFE5E5E5),
                      ),
                      const SizedBox(height: 16),
                      for (final (k, v) in [
                        (tr('Guardar'), '⌘S'),
                        (tr('Buscar en el archivo'), '⌘F'),
                        (tr('Mostrar u ocultar la terminal'), '⌘J'),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('$k   $v', style: TextStyle(color: _dim)),
                        ),
                    ],
                  ),
                )
              : CodeEditor(
                  key: ValueKey('code-${d.path}'),
                  controller: d.controller,
                  findController: d.find,
                  readOnly: d.readOnly,
                  wordWrap: false,
                  style: CodeEditorStyle(
                    fontSize: 13,
                    fontFamily: _mono,
                    fontFamilyFallback: _monoFallback,
                    fontHeight: 1.45,
                    textColor: _t(0xFFD4D4D4, 0xFF1F1F1F),
                    backgroundColor: _bg,
                    selectionColor: _t(0xFF264F78, 0xFFADD6FF),
                    cursorColor: _t(0xFFAEAFAD, 0xFF000000),
                    cursorLineColor: _t(0xFF282828, 0xFFF5F5F5),
                    chunkIndicatorColor: _dim,
                    codeTheme: CodeHighlightTheme(
                      languages: {
                        d.language: CodeHighlightThemeMode(
                          mode: _modes[d.language] ?? langPlaintext,
                        ),
                      },
                      theme: _dark ? vs2015Theme : vsTheme,
                    ),
                  ),
                  indicatorBuilder: (context, editing, chunk, notifier) => Row(
                    children: [
                      DefaultCodeLineNumber(
                        controller: editing,
                        notifier: notifier,
                        textStyle: TextStyle(
                          color: _t(0xFF6E7681, 0xFF8A8A8A),
                          fontSize: 12,
                          fontFamily: _mono,
                        ),
                        focusedTextStyle: TextStyle(
                          color: _t(0xFFC6C6C6, 0xFF333333),
                          fontSize: 12,
                          fontFamily: _mono,
                        ),
                      ),
                      DefaultCodeChunkIndicator(
                        width: 18,
                        controller: chunk,
                        notifier: notifier,
                      ),
                    ],
                  ),
                  findBuilder: (context, controller, readOnly) =>
                      _FindPanel(controller: controller),
                  shortcutOverrideActions: {
                    CodeShortcutSaveIntent:
                        CallbackAction<CodeShortcutSaveIntent>(
                          onInvoke: (_) {
                            _save();
                            return null;
                          },
                        ),
                  },
                ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- terminal
  void _historyUp() {
    final h = _Session.history;
    if (h.isEmpty) return;
    _historyAt = _historyAt < 0
        ? h.length - 1
        : (_historyAt - 1).clamp(0, h.length - 1);
    _cmd.text = h[_historyAt];
    _cmd.selection = TextSelection.collapsed(offset: _cmd.text.length);
  }

  void _historyDown() {
    final h = _Session.history;
    if (_historyAt < 0) return;
    _historyAt++;
    if (_historyAt >= h.length) {
      _historyAt = -1;
      _cmd.clear();
    } else {
      _cmd.text = h[_historyAt];
    }
  }

  Widget _terminal() => Container(
    height: 240,
    decoration: BoxDecoration(
      color: _bg,
      border: Border(top: BorderSide(color: _line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Text(
              tr('TERMINAL'),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: .6,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _Session.termCwd ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _dim, fontSize: 11.5),
              ),
            ),
            if (_proc != null)
              _iconBtn(LucideIcons.square, tr('Detener'), () => _proc?.kill()),
            _iconBtn(
              LucideIcons.trash2,
              tr('Limpiar'),
              () => setState(_Session.termLines.clear),
            ),
            _iconBtn(LucideIcons.x, tr('Cerrar'), _toggleTerminal),
          ],
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _cmdFocus.requestFocus(),
            child: ListView.builder(
              controller: _termScroll,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _Session.termLines.length,
              itemBuilder: (_, i) => SelectableText(
                _Session.termLines[i],
                style: TextStyle(
                  fontFamily: _mono,
                  fontFamilyFallback: _monoFallback,
                  fontSize: 12.5,
                  color: _t(0xFFCCCCCC, 0xFF333333),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Text(
                '${p.basename(_Session.termCwd ?? '')} \$ ',
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 12.5,
                  color: _t(0xFF73C991, 0xFF1B7F4B),
                ),
              ),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowUp):
                        _historyUp,
                    const SingleActivator(LogicalKeyboardKey.arrowDown):
                        _historyDown,
                  },
                  child: TextField(
                    controller: _cmd,
                    focusNode: _cmdFocus,
                    enabled: _proc == null,
                    autofocus: true,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontFamilyFallback: _monoFallback,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: _proc == null
                          ? tr('Escriba una orden, p. ej. git status')
                          : tr('Ejecutando…'),
                      hintStyle: TextStyle(color: _t(0xFF5A5A5A, 0xFF8A8A8A)),
                    ),
                    onSubmitted: (v) {
                      _runCommand(v);
                      _cmdFocus.requestFocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ------------------------------------------------------- barra estado
  Widget _statusBar() {
    final d = _doc;
    return Container(
      height: 22,
      color: _working ? _status : const Color(0xFF68217A),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Row(
          children: [
            if (_branch.isNotEmpty) ...[
              const Icon(LucideIcons.gitBranch, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text(_branch),
              const SizedBox(width: 12),
              if (_changes.isNotEmpty) Text('${_changes.length}✱'),
            ],
            const Spacer(),
            if (d != null)
              ValueListenableBuilder<CodeLineEditingValue>(
                valueListenable: d.controller,
                builder: (_, v, _) => Text(
                  tr('Ln {0}, Col {1}', [
                    v.selection.extentIndex + 1,
                    v.selection.extentOffset + 1,
                  ]),
                ),
              ),
            if (d != null) ...[
              const SizedBox(width: 16),
              const Text('UTF-8'),
              const SizedBox(width: 16),
              Text(d.language),
            ],
          ],
        ),
      ),
    );
  }
}

/// Buscar y reemplazar dentro del archivo (⌘F / ⌥⌘F).
class _FindPanel extends StatelessWidget implements PreferredSizeWidget {
  const _FindPanel({required this.controller});
  final CodeFindController controller;

  @override
  Size get preferredSize => Size.fromHeight(
    controller.value == null ? 0 : (controller.value!.replaceMode ? 76 : 40),
  );

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    if (v == null) return const SizedBox.shrink();
    final r = v.result;
    Widget field(TextEditingController c, FocusNode f, String hint) => SizedBox(
      width: 240,
      height: 28,
      child: TextField(
        controller: c,
        focusNode: f,
        style: TextStyle(color: _text, fontSize: 13),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: _dim),
          filled: true,
          fillColor: _t(0xFF3C3C3C, 0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _status),
          ),
        ),
      ),
    );
    Widget btn(IconData i, String tip, VoidCallback onTap, {bool on = false}) =>
        IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 15,
          color: on ? Colors.white : _text,
          style: on ? IconButton.styleFrom(backgroundColor: _accent) : null,
          onPressed: onTap,
          icon: Icon(i),
        );
    return Container(
      color: _side,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      alignment: Alignment.topRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(
                controller.findInputController,
                controller.findInputFocusNode,
                tr('Buscar'),
              ),
              btn(
                LucideIcons.caseSensitive,
                tr('Distinguir mayúsculas'),
                controller.toggleCaseSensitive,
                on: v.option.caseSensitive,
              ),
              btn(
                LucideIcons.regex,
                tr('Expresión regular'),
                controller.toggleRegex,
                on: v.option.regex,
              ),
              SizedBox(
                width: 80,
                child: Text(
                  r == null || r.matches.isEmpty
                      ? tr('Sin resultados')
                      : '${r.index + 1} / ${r.matches.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _text, fontSize: 12),
                ),
              ),
              btn(
                LucideIcons.arrowUp,
                tr('Anterior'),
                controller.previousMatch,
              ),
              btn(LucideIcons.arrowDown, tr('Siguiente'), controller.nextMatch),
              btn(
                LucideIcons.replace,
                tr('Reemplazar'),
                controller.toggleMode,
                on: v.replaceMode,
              ),
              btn(LucideIcons.x, tr('Cerrar'), controller.close),
            ],
          ),
          if (v.replaceMode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(
                    controller.replaceInputController,
                    controller.replaceInputFocusNode,
                    tr('Reemplazar'),
                  ),
                  btn(
                    LucideIcons.replace,
                    tr('Reemplazar'),
                    controller.replaceMatch,
                  ),
                  btn(
                    LucideIcons.replaceAll,
                    tr('Reemplazar todo'),
                    controller.replaceAllMatches,
                  ),
                  const SizedBox(width: 206),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
