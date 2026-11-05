import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/styles/vs.dart';
import 'package:re_highlight/styles/vs2015.dart';

import '../../code/tk_ai.dart';
import '../../code/component_clipboard.dart';
import '../../code/tk_codegen.dart';
import '../../code/tk_model.dart';
import '../../code/tk_run.dart';
import '../../core/errors.dart';
import '../../core/ai_usage.dart';
import '../../core/project_store.dart';
import '../../i18n/i18n.dart';
import '../save_file.dart';
import '../tk_launch.dart';
import '../tk_project.dart';
import '../bottom_panel.dart';
import '../theme.dart';
import '../widgets.dart';
import 'budget_screen.dart';
import 'github_dialog.dart';
import 'tk_canvas.dart';
import 'tk_claude_panel.dart';
import 'tk_inspector.dart';

/// Diseñador de interfaz: un diseñador visual de formularios, al estilo de
/// Delphi, para aplicaciones de tkinter (y de Flask en la web). Cada ventana
/// se abre en su propia ventana del sistema: Tk no se puede incrustar en
/// Flutter.
///
/// Aviso de que este Tk no pintará la ventana como en el diseño.
String _oldTkWarning(TkPython py) => tr(
  'Tk {0} es antiguo y no respeta los colores del diseño. {1}',
  [py.tk, py.help],
);

/// Muestra [path] en el explorador de archivos del sistema.
Future<void> revealInFiles(String path) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  } on ProcessException {
    // Sin explorador no se hace nada.
  }
}

class TkDesignerScreen extends StatefulWidget {
  const TkDesignerScreen({super.key});
  @override
  State<TkDesignerScreen> createState() => _TkDesignerScreenState();
}

class _TkDesignerScreenState extends State<TkDesignerScreen> {
  List<StudioProject> _apps = const [];
  bool _loading = true;
  String _workspace = '';
  TkPython? _python;
  TkProject? _doc;

  @override
  void initState() {
    super.initState();
    _doc = TkProject.current;
    _load();
    TkRunner.detect().then((p) {
      if (mounted) setState(() => _python = p);
    });
  }

  Future<void> _load() async {
    final apps = await runAction(context, ProjectStore.list);
    final ws = await ProjectStore.workspaceDir();
    if (!mounted) return;
    setState(() {
      _apps = apps ?? const [];
      _workspace = ws;
      _loading = false;
    });
  }

  Future<void> _open(String id) async {
    final r = await runAction(context, () => ProjectStore.get(id));
    if (!mounted) return;
    if (r == null) return _load();
    setState(() => _doc = TkProject.open(r));
  }

  Future<void> _create() async {
    final app = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _NewAppDialog(),
    );
    if (app == null || !mounted) return;
    final (name, target) = app;
    final id = await runAction(
      context,
      () => ProjectStore.create(name, design: TkDesign(target: target)),
    );
    if (id != null) await _open(id);
  }

  Future<void> _openFolder() async {
    final dir = await getDirectoryPath(
      confirmButtonText: tr('Abrir proyecto'),
      initialDirectory: _workspace.isEmpty ? null : _workspace,
    );
    if (dir == null || !mounted) return;
    final x = await runAction(context, () => ProjectStore.openFolder(dir));
    if (x == null || !mounted) return;
    setState(() => _doc = TkProject.open(x));
  }

  Future<void> _changeWorkspace() async {
    final dir = await getDirectoryPath(
      confirmButtonText: tr('Usar esta carpeta'),
      initialDirectory: _workspace.isEmpty ? null : _workspace,
    );
    if (dir == null || !mounted) return;
    await runAction(context, () => ProjectStore.setWorkspaceDir(dir));
    if (!mounted) return;
    setState(() => _loading = true);
    await _load();
  }

  Future<void> _delete(StudioProject a) async {
    final ok = await confirmDialog(
      context,
      tr('Eliminar el proyecto'),
      TkProject.pendingInEditor(a.path)
          ? tr(
              '¿Llevar «{0}» a la papelera del área de trabajo? Se perderá su código sin guardar en el Editor.',
              [a.name],
            )
          : tr(
              '¿Llevar «{0}» a la papelera del área de trabajo (carpeta {1})?',
              [a.name, ProjectStore.trashDir],
            ),
      danger: true,
      ok: tr('Eliminar'),
    );
    if (!ok || !mounted) return;
    if (TkProject.current?.id == a.path) TkProject.close();
    await runAction(context, () => ProjectStore.delete(a.path));
    await _load();
  }

  Future<void> _duplicate(String id) async {
    await runAction(context, () => ProjectStore.duplicate(id));
    await _load();
  }

  Widget _status(ThemeData t) {
    final py = _python;
    final Widget text;
    final bool ok;
    if (!TkRunner.supported) {
      ok = false;
      text = Text(py?.help ?? '');
    } else if (py == null) {
      ok = true;
      text = Text(tr('Buscando Python…'));
    } else if (py.ok) {
      ok = !py.oldTk;
      text = Text(
        [
          tr('Python {0} con Tk {1} ({2})', [py.version, py.tk, py.command]),
          if (py.oldTk) _oldTkWarning(py),
        ].join(' '),
      );
    } else {
      ok = false;
      text = SelectableText(
        '${py.withoutTk == null ? tr('No se encontró Python.') : tr('Se encontró {0}, pero no trae tkinter.', [py.withoutTk])} ${py.help}',
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
          size: 16,
          color: ok ? t.colorScheme.primary : t.colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(child: text),
        if (TkRunner.supported && py != null)
          IconButton(
            tooltip: tr('Volver a buscar Python'),
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () async {
              setState(() => _python = null);
              final p = await TkRunner.detect(refresh: true);
              if (mounted) setState(() => _python = p);
            },
          ),
      ],
    );
  }

  Widget _card(ThemeData t, StudioProject a) {
    final id = a.path;
    final design = a.design;
    return SizedBox(
      width: 272,
      child: Card(
        key: ValueKey('tk-app-$id'),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: t.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(10),
                child: TkFormThumbnail(design),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.titleSmall,
                          ),
                        ),
                        if (design.isWeb)
                          Tooltip(
                            message: tr('Aplicación web con Flask'),
                            child: Icon(
                              LucideIcons.globe,
                              key: ValueKey('tk-web-$id'),
                              size: 14,
                              color: t.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 34,
                      child: Text(
                        a.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 4),
                  if (TkRunner.supported)
                    IconButton(
                      key: ValueKey('tk-run-$id'),
                      tooltip: tr('Ejecutar'),
                      icon: const Icon(
                        LucideIcons.play,
                        size: 18,
                        color: AppColors.success,
                      ),
                      onPressed: () => launchTkApp(context, id),
                    ),
                  IconButton(
                    tooltip: tr('Mostrar la carpeta'),
                    icon: const Icon(LucideIcons.folderOpen, size: 18),
                    onPressed: () => revealInFiles(id),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: tr('Más acciones'),
                    icon: const Icon(LucideIcons.ellipsis, size: 18),
                    onSelected: (v) => switch (v) {
                      'copy' => _duplicate(id),
                      'github' => showProjectGitHub(
                        context,
                        dir: id,
                        name: a.name,
                      ),
                      'budget' => showAiBudget(
                        context,
                        project: id,
                        name: a.name,
                      ),
                      _ => _delete(a),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'github',
                        child: Text(tr('GitHub…')),
                      ),
                      PopupMenuItem(
                        value: 'budget',
                        child: Text(tr('Presupuesto de IA')),
                      ),
                      PopupMenuItem(value: 'copy', child: Text(tr('Duplicar'))),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(tr('Eliminar')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gallery(ThemeData t) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(tr('Diseñador de interfaz'), style: t.textTheme.titleLarge),
          const SizedBox(width: 12),
          FilledButton.icon(
            key: const ValueKey('tk-new'),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(tr('Nuevo proyecto')),
            onPressed: _create,
          ),
          OutlinedButton.icon(
            key: const ValueKey('tk-open-folder'),
            icon: const Icon(LucideIcons.folderOpen, size: 16),
            label: Text(tr('Abrir carpeta…')),
            onPressed: _openFolder,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        tr(
          'Diseñe ventanas de escritorio con tkinter arrastrando componentes, como en Delphi. Cada una se abre en su propia ventana del sistema y se ejecuta en este equipo con los permisos de su usuario. En macOS, los botones tienen el aspecto del sistema y no toman el color de fondo.',
        ),
        style: t.textTheme.bodySmall,
      ),
      const SizedBox(height: 6),
      Text(
        tr(
          'Las aplicaciones web usan el mismo diseñador y el mismo Python, con Flask: el código corre en un servidor de este equipo y la página se abre en su navegador. Solo se llega a ellas desde este equipo.',
        ),
        style: t.textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      _status(t),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(LucideIcons.folder, size: 16, color: t.hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              tr('Área de trabajo: {0}', [_workspace]),
              style: t.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: _workspace.isEmpty
                ? null
                : () => revealInFiles(_workspace),
            child: Text(tr('Mostrar')),
          ),
          TextButton(
            key: const ValueKey('tk-workspace'),
            onPressed: _changeWorkspace,
            child: Text(tr('Cambiar…')),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_apps.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              tr('Aún no hay proyectos. Cree uno con «Nuevo proyecto».'),
              style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
            ),
          ),
        )
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final a in _apps) _card(t, a)],
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    if (doc != null) {
      return _TkEditor(
        key: ValueKey('tk-doc-${doc.id}'),
        doc: doc,
        python: _python,
        onClose: () async {
          TkProject.close();
          setState(() => _doc = null);
          await _load();
        },
      );
    }
    return _gallery(Theme.of(context));
  }
}

/// Colores de Código (tema oscuro de VS Code).
const _editorBg = Color(0xFF1E1E1E);
const _editorDim = Color(0xFF8C8C8C);
const _mono = 'Menlo';
const _monoFallback = ['Consolas', 'Monaco', 'Courier New', 'monospace'];

/// El mismo editor que la aplicación Código, para Python.
class _PythonEditor extends StatelessWidget {
  const _PythonEditor({
    this.editorKey,
    required this.controller,
    this.readOnly = false,
    this.focusNode,
  });
  final Key? editorKey;
  final CodeLineEditingController controller;
  final bool readOnly;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CodeEditor(
      key: editorKey,
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      autofocus: false,
      wordWrap: false,
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: _mono,
        fontFamilyFallback: _monoFallback,
        fontHeight: 1.45,
        textColor: dark ? const Color(0xFFD4D4D4) : const Color(0xFF1F1F1F),
        backgroundColor: dark ? _editorBg : Colors.white,
        selectionColor: dark
            ? const Color(0xFF264F78)
            : const Color(0xFFADD6FF),
        cursorColor: dark ? const Color(0xFFAEAFAD) : Colors.black,
        cursorLineColor: dark
            ? const Color(0xFF282828)
            : const Color(0xFFF5F5F5),
        chunkIndicatorColor: _editorDim,
        codeTheme: CodeHighlightTheme(
          languages: {'python': CodeHighlightThemeMode(mode: langPython)},
          theme: dark ? vs2015Theme : vsTheme,
        ),
      ),
      indicatorBuilder: (context, editing, chunk, notifier) => Row(
        children: [
          DefaultCodeLineNumber(
            controller: editing,
            notifier: notifier,
            textStyle: const TextStyle(
              color: Color(0xFF6E7681),
              fontSize: 12,
              fontFamily: _mono,
            ),
            focusedTextStyle: TextStyle(
              color: dark ? const Color(0xFFC6C6C6) : const Color(0xFF333333),
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
    );
  }
}

/// Diseñador de una ventana: paleta arriba, árbol e inspector a la izquierda,
/// y el formulario, su código o el Python generado en el centro.
class _TkEditor extends StatefulWidget {
  const _TkEditor({
    super.key,
    required this.doc,
    required this.python,
    required this.onClose,
  });
  final TkProject doc;
  final TkPython? python;
  final Future<void> Function() onClose;

  @override
  State<_TkEditor> createState() => _TkEditorState();
}

class _TkEditorState extends State<_TkEditor> {
  TkProject get doc => widget.doc;
  TkDesign get d => doc.design;
  CodeLineEditingController get _code => doc.code;

  Set<String> _selection = {};
  bool _snap = true;
  int _tab = 0;
  bool _output = false;

  /// Panel de Claude Code a la derecha.
  static bool _claude = false;
  bool _aiBusy = false;
  List<String> _connections = const [];
  String? _lastEdit;
  String? _generated;
  String? _genError;
  TkRun? _run;

  final _generatedCode = CodeLineEditingController.fromText('');
  final _codeFocus = FocusNode(debugLabel: 'tk-code');
  final _outScroll = ScrollController();

  /// Componentes copiados (JSON): se pueden pegar en otra ventana.
  static ComponentClip? _clip;

  @override
  void initState() {
    super.initState();
    _shownDirty = doc.dirty;
    TkProject.changes.addListener(_onProject);
    _attach(TkRunner.runOf(doc.id));
    ProjectStore.savedConnections().then((c) {
      if (mounted) setState(() => _connections = c);
    });
  }

  @override
  void dispose() {
    TkProject.changes.removeListener(_onProject);
    _run?.removeListener(_onRun);
    _generatedCode.dispose();
    _codeFocus.dispose();
    _outScroll.dispose();
    super.dispose();
  }

  /// Lo último que muestra la barra: el código también cambia desde el Editor.
  bool _shownDirty = false;

  void _onProject() {
    if (!mounted || (_tab != 2 && doc.dirty == _shownDirty)) return;
    setState(() {
      _shownDirty = doc.dirty;
      if (_tab == 2) _regenerate();
    });
  }

  void _attach(TkRun? run) {
    _run?.removeListener(_onRun);
    _run = run;
    run?.addListener(_onRun);
  }

  void _onRun() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_outScroll.hasClients) {
        _outScroll.jumpTo(_outScroll.position.maxScrollExtent);
      }
    });
  }

  // ------------------------------------------------------------- deshacer
  void _begin([String? key]) {
    if (key != null && key == _lastEdit) return;
    _lastEdit = key;
    doc.undo.add((d.toJsonString(), _code.text));
    if (doc.undo.length > 100) doc.undo.removeAt(0);
  }

  void _changed() {
    doc.touch();
    setState(() {});
  }

  void _undoStep() {
    if (doc.undo.isEmpty) return;
    final (design, code) = doc.undo.removeLast();
    _lastEdit = null;
    setState(() {
      doc.design = TkDesign.parse(design);
      if (code != null) doc.setCode(code);
      doc.touch();
      _selection = _selection.where((n) => d.byName(n) != null).toSet();
    });
    if (code != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const ValueKey('tk-undo-note'),
        content: Text(
          tr(
            'Se ha restaurado el diseño, pero no el código: cambió a mano después de ese paso.',
          ),
        ),
      ),
    );
  }

  void _setCode(String text) => doc.setCode(text);

  // -------------------------------------------------------- componentes
  /// Marco más profundo bajo el punto (x, y) de la ventana.
  TkWidget? _frameAt(int x, int y) {
    for (final w in d.widgets.reversed) {
      if (!w.component.container || !d.shown(w)) continue;
      final (ax, ay) = d.absolute(w);
      if (x >= ax && y >= ay && x < ax + w.width && y < ay + w.height) return w;
    }
    return null;
  }

  void _add(String kind, int x, int y) {
    final c = tkComponent(kind);
    if (c == null) return;
    _begin();
    final name = d.freeName(kind);
    // El menú, la barra de estado y los no visuales van en la ventana.
    final frame = c.nestable ? _frameAt(x, y) : null;
    final (px, py) = frame == null ? (0, 0) : d.absolute(frame);
    final w = TkWidget(
      kind: kind,
      name: name,
      x: x - px,
      y: y - py,
      width: c.width,
      height: c.height,
      parent: frame?.name,
      // En un control de páginas, en la página que se ve.
      page: frame?.kind == 'PageControl' ? d.activePage(frame!) : null,
    );
    if (const {
      'Label',
      'Button',
      'Checkbutton',
      'Radiobutton',
    }.contains(kind)) {
      w.props['text'] = name;
    }
    // Una tabla nueva lee de la conexión que ya haya.
    if (kind == 'Treeview' && d.connections.isNotEmpty) {
      w.props['source'] = d.connections.first.name;
    }
    d.widgets.add(w);
    if (frame != null) {
      // Con sus hermanos, dentro del marco.
      d.widgets.remove(w);
      final after = d.widgets.lastIndexWhere(
        (o) => o == frame || d.isInside(o, frame.name),
      );
      d.widgets.insert(after + 1, w);
    }
    _lastEdit = null;
    _selection = {name};
    _changed();
  }

  void _addAtFreeSpot(String kind) {
    final n = d.widgets.length % 12;
    _add(kind, tkGrid * (2 + n * 3), tkGrid * (2 + n * 3));
  }

  List<TkWidget> get _selected => [
    for (final w in d.widgets)
      if (_selection.contains(w.name)) w,
  ];

  void _delete() {
    if (_selection.isEmpty) return;
    _begin();
    _lastEdit = null;
    for (final w in _selected) {
      if (d.byName(w.name) != null) d.remove(w);
    }
    _selection = {};
    _changed();
  }

  void _copy() {
    final s = _selected;
    if (s.isEmpty) return;
    final names = s.map((w) => w.name).toSet();
    final widgets = [
      for (final w in d.widgets)
        if (names.contains(w.name) || names.any((n) => d.isInside(w, n))) w,
    ];
    // Con el código de sus eventos: se pegan en otro proyecto tal cual.
    final methods = <String, CopiedMethod>{
      for (final w in widgets)
        for (final m in w.events.values)
          m: ?ComponentClip.methodOf(_code.text, m),
    };
    final clip = ComponentClip([for (final w in widgets) w.toJson()], methods);
    _clip = clip;
    Clipboard.setData(ClipboardData(text: clip.encode()));
  }

  /// Pega lo copiado aquí, en otro proyecto o en otra ventana del estudio:
  /// los componentes con nombres libres y el código de sus eventos.
  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    final clip = ComponentClip.decode(text) ?? _clip;
    if (clip == null || clip.widgets.isEmpty || !mounted) return;
    _begin();
    _lastEdit = null;
    final copies = [for (final j in clip.widgets) TkWidget.fromJson(j)];
    final renamed = <String, String>{};
    final taken = <String>{};
    for (final w in copies) {
      final n = d.freeName(w.kind, taken);
      taken.add(n);
      renamed[w.name] = n;
    }
    // Métodos: siguen al componente si llevan su nombre y nunca pisan uno
    // que ya exista en este proyecto.
    var code = _code.text;
    final methodNames = <String, String>{};
    String freeMethod(String base) {
      var name = base;
      for (
        var i = 2;
        TkUnit.lineOf(code, name) != null || methodNames.containsValue(name);
        i++
      ) {
        name = '${base}_$i';
      }
      return name;
    }

    for (final w in copies) {
      for (final e in w.events.entries.toList()) {
        final old = e.value;
        final m = methodNames[old] ??= freeMethod(
          old.startsWith('${w.name}_')
              ? '${renamed[w.name]}${old.substring(w.name.length)}'
              : old,
        );
        w.events[e.key] = m;
      }
    }
    for (final MapEntry(key: old, value: name) in methodNames.entries) {
      final m = clip.methods[old];
      if (m == null) {
        code = TkUnit.ensureMethod(code, d.name, name);
        continue;
      }
      var body = m.body;
      for (final r in renamed.entries) {
        body = TkUnit.renameWidget(body, r.key, r.value);
      }
      for (final r in methodNames.entries) {
        body = TkUnit.renameMethod(body, r.key, r.value);
      }
      code = ComponentClip.addMethod(code, d.name, old, name, (
        def: m.def,
        body: body,
      ));
    }
    final fresh = <String>{};
    for (final w in copies) {
      final parent = renamed[w.parent];
      final top = parent == null;
      fresh.add(renamed[w.name]!);
      w
        ..name = renamed[w.name]!
        // Fuera de lo copiado, su marco puede no existir aquí.
        ..parent = top && d.byName(w.parent ?? '') != null ? w.parent : parent;
      if (top) {
        w
          ..x += tkGrid * 2
          ..y += tkGrid * 2;
      }
    }
    d.widgets.addAll(copies);
    _setCode(code);
    _selection = {
      for (final w in copies)
        if (w.parent == null || !fresh.contains(w.parent)) w.name,
    };
    _changed();
  }

  void _cut() {
    _copy();
    _delete();
  }

  /// Alinea con el primero de la selección.
  /// Centra lo seleccionado en la ventana (o en su marco), como un bloque
  /// si comparten contenedor.
  void _centerInParent({required bool horizontal}) {
    final s = _selected;
    if (s.isEmpty) return;
    _begin();
    _lastEdit = null;
    final groups = <String?, List<TkWidget>>{};
    for (final w in s) {
      (groups[w.parent] ??= []).add(w);
    }
    for (final MapEntry(key: parent, value: ws) in groups.entries) {
      final box = parent == null ? null : d.byName(parent);
      final (cw, ch) = box == null
          ? (d.width, d.height)
          : (box.width, box.height);
      final left = ws.map((w) => w.x).reduce((a, b) => a < b ? a : b);
      final top = ws.map((w) => w.y).reduce((a, b) => a < b ? a : b);
      final right = ws
          .map((w) => w.x + w.width)
          .reduce((a, b) => a > b ? a : b);
      final bottom = ws
          .map((w) => w.y + w.height)
          .reduce((a, b) => a > b ? a : b);
      final dx = horizontal ? (cw - (right - left)) ~/ 2 - left : 0;
      final dy = horizontal ? 0 : (ch - (bottom - top)) ~/ 2 - top;
      for (final w in ws) {
        w
          ..x += dx
          ..y += dy;
      }
    }
    _changed();
  }

  void _align(String mode) {
    final s = _selected;
    if (s.length < 2) return;
    _begin();
    _lastEdit = null;
    final first = s.first;
    final (fx, fy) = d.absolute(first);
    for (final w in s.skip(1)) {
      final (ax, ay) = d.absolute(w);
      switch (mode) {
        case 'left':
          w.x += fx - ax;
        case 'right':
          w.x += fx + first.width - ax - w.width;
        case 'center':
          w.x += fx + (first.width - w.width) ~/ 2 - ax;
        case 'top':
          w.y += fy - ay;
        case 'bottom':
          w.y += fy + first.height - ay - w.height;
        case 'middle':
          w.y += fy + (first.height - w.height) ~/ 2 - ay;
        case 'width':
          w.width = first.width;
        case 'height':
          w.height = first.height;
      }
    }
    _changed();
  }

  void _order({required bool front}) {
    final s = _selected;
    if (s.isEmpty) return;
    _begin();
    _lastEdit = null;
    for (final w in front ? s : s.reversed) {
      d.reorder(w, front: front);
    }
    _changed();
  }

  void _nudge(int dx, int dy, {required bool resize}) {
    final s = _selected;
    if (s.isEmpty) return;
    _begin('nudge');
    for (final w in s) {
      if (resize) {
        w
          ..width = (w.width + dx).clamp(tkGrid, 4000)
          ..height = (w.height + dy).clamp(tkGrid, 4000);
      } else {
        w
          ..x += dx
          ..y += dy;
      }
    }
    _changed();
  }

  KeyEventResult _key(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final kb = HardwareKeyboard.instance;
    final cmd = kb.isControlPressed || kb.isMetaPressed;
    final k = e.logicalKey;
    final step = kb.isAltPressed ? 1 : tkGrid;
    void Function()? run;
    if (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) {
      run = _delete;
    } else if (cmd && k == LogicalKeyboardKey.keyC) {
      run = _copy;
    } else if (cmd && k == LogicalKeyboardKey.keyX) {
      run = _cut;
    } else if (cmd && k == LogicalKeyboardKey.keyV) {
      run = _paste;
    } else if (cmd && k == LogicalKeyboardKey.keyZ) {
      run = _undoStep;
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      run = () => _nudge(-step, 0, resize: kb.isShiftPressed);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      run = () => _nudge(step, 0, resize: kb.isShiftPressed);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      run = () => _nudge(0, -step, resize: kb.isShiftPressed);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      run = () => _nudge(0, step, resize: kb.isShiftPressed);
    }
    if (run == null) return KeyEventResult.ignored;
    run();
    return KeyEventResult.handled;
  }

  Future<void> _menu(Offset at) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        at & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: 'cut', child: Text(tr('Cortar'))),
        PopupMenuItem(value: 'copy', child: Text(tr('Copiar'))),
        PopupMenuItem(value: 'paste', child: Text(tr('Pegar'))),
        PopupMenuItem(value: 'delete', child: Text(tr('Eliminar'))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'front', child: Text(tr('Traer al frente'))),
        PopupMenuItem(value: 'back', child: Text(tr('Enviar al fondo'))),
      ],
    );
    switch (v) {
      case 'cut':
        _cut();
      case 'copy':
        _copy();
      case 'paste':
        _paste();
      case 'delete':
        _delete();
      case 'front':
        _order(front: true);
      case 'back':
        _order(front: false);
    }
  }

  // ------------------------------------------------------ nombres y código
  String? _rename(TkWidget? w, String name) {
    if (!d.validName(name)) return tr('Nombre no válido.');
    if (w == null) {
      if (d.byName(name) != null) return tr('Ese nombre ya existe.');
      _begin();
      _lastEdit = null;
      _setCode(TkUnit.renameForm(_code.text, d.name, name));
      d.name = name;
      _changed();
      return null;
    }
    if (d.byName(name) != null || name == d.name) {
      return tr('Ese nombre ya existe.');
    }
    _begin();
    _lastEdit = null;
    final old = w.name;
    var code = TkUnit.renameWidget(_code.text, old, name);
    // Los métodos con el nombre de serie siguen al componente.
    for (final e in w.events.entries.toList()) {
      if (e.value.startsWith('${old}_')) {
        final m = '$name${e.value.substring(old.length)}';
        code = TkUnit.renameMethod(code, e.value, m);
        w.events[e.key] = m;
      }
    }
    for (final o in d.widgets) {
      if (o.parent == old) o.parent = name;
    }
    d.renameReferences(old, name);
    if (w.props['text'] == old) w.props['text'] = name;
    w.name = name;
    _setCode(code);
    if (_selection.remove(old)) _selection.add(name);
    _changed();
    return null;
  }

  String? _setHandler(TkWidget? w, TkEvent e, String method) {
    final events = w?.events ?? d.events;
    if (method.isEmpty) {
      _begin();
      _lastEdit = null;
      events.remove(e.key);
      _changed();
      return null;
    }
    if (!d.validName(method)) return tr('Nombre no válido.');
    _begin();
    _lastEdit = null;
    events[e.key] = method;
    _ensure(method, e);
    _changed();
    return null;
  }

  void _ensure(String method, TkEvent e) => _setCode(
    TkUnit.ensureMethod(
      _code.text,
      d.name,
      method,
      param: e.param,
      body: tkFormEvents.contains(e) && e.key == 'close' && !d.isWeb
          ? 'self.root.destroy()'
          : 'pass',
    ),
  );

  void _openHandler(TkWidget? w, TkEvent e) {
    final events = w?.events ?? d.events;
    var method = events[e.key];
    if (method == null) {
      _begin();
      _lastEdit = null;
      method = '${w?.name ?? 'form'}_${e.suffix}';
      events[e.key] = method;
      doc.touch();
    }
    _ensure(method, e);
    _showCode(method);
  }

  /// Doble clic: el evento principal del componente.
  void _openDefault(TkWidget? w) {
    if (w != null) _selection = {w.name};
    final events = w?.component.events ?? tkFormEvents;
    if (events.isEmpty) return setState(() {});
    _openHandler(w, events.first);
  }

  void _showCode(String method) {
    setState(() => _tab = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final line = TkUnit.lineOf(_code.text, method);
      if (line == null) return;
      final next = line + 1 < _code.lineCount ? line + 1 : line;
      _code.selection = CodeLineSelection.collapsed(
        index: next,
        offset: _code.codeLines[next].text.length,
      );
      _codeFocus.requestFocus();
      _code.makeCursorCenterIfInvisible();
    });
  }

  void _setTab(int i) {
    if (i == 2) _regenerate();
    setState(() => _tab = i);
  }

  void _regenerate() {
    try {
      _generated = TkCodegen.generate(d, _code.text);
      _genError = null;
      _generatedCode.text = _generated!;
    } on UserError catch (e) {
      _genError = e.message;
    }
  }

  // ------------------------------------------------------------------- IA
  Future<void> _askAi() async {
    final missing = await TkAi.missing();
    if (!mounted) return;
    final one = _selection.length == 1 ? d.byName(_selection.first) : null;
    final target = one != null && one.component.events.isNotEmpty ? one : null;
    final req = await showDialog<_AiRequest>(
      context: context,
      builder: (_) => _AiDialog(missing: missing, target: target?.name),
    );
    if (req == null || !mounted) return;
    setState(() => _aiBusy = true);
    final before = _code.text;
    final change = await runAction(
      context,
      () => AiUsage.track(doc.id, 'designer_ai', () {
        if (req.mode != 'code') {
          return TkAi.change(
            req.prompt,
            current: d,
            code: _code.text,
            fresh: req.mode == 'new',
            connections: _connections,
            imageUrl: req.imageUrl,
          );
        }
        // El método del evento principal, enlazado en la propuesta.
        final e = target!.component.events.first;
        final method = target.events[e.key] ?? '${target.name}_${e.suffix}';
        final draft = d.clone();
        draft.byName(target.name)!.events[e.key] = method;
        return TkAi.handler(
          req.prompt,
          current: draft,
          code: _code.text,
          method: method,
          param: e.param,
          event: '${tr(e.label)} (${target.name})',
          connections: _connections,
        );
      }),
    );
    if (!mounted) return;
    setState(() => _aiBusy = false);
    if (change == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AiPreview(before: d, after: change),
    );
    if (ok != true || !mounted) return;
    // Mientras la IA trabajaba se pudo escribir aquí o en el Editor.
    if (_code.text != before &&
        change.code != before &&
        !await confirmDialog(
          context,
          tr('El código ha cambiado'),
          tr(
            'El código ha cambiado mientras la IA trabajaba. ¿Reemplazarlo por la propuesta?',
          ),
        )) {
      return;
    }
    if (!mounted) return;
    // Un solo paso de deshacer para todo lo que trae la propuesta.
    _begin();
    _lastEdit = null;
    setState(() {
      doc
        ..design = change.design
        ..touch();
      _setCode(change.code);
      _selection = _selection.where((n) => d.byName(n) != null).toSet();
    });
  }

  // ------------------------------------------------------------- acciones
  /// Carga el diseño y el código que Claude Code dejó en el disco, como un
  /// paso que se puede deshacer.
  Future<void> _reloadFromClaude() async {
    final x = await ProjectStore.get(doc.id);
    if (x == null || !mounted) return;
    _begin();
    _lastEdit = null;
    setState(() {
      doc
        ..design = x.design
        ..touch();
      _setCode(x.code);
      _selection = _selection.where((n) => d.byName(n) != null).toSet();
      if (_tab == 2) _regenerate();
    });
    // El disco ya tiene esto: queda guardado.
    await _save();
  }

  Future<bool> _save() async {
    final done = await runAction(context, () async {
      await doc.save();
      return true;
    });
    if (done != true) return false;
    if (mounted) setState(() {});
    return true;
  }

  Future<void> _runApp() async {
    if (doc.dirty && !await _save()) return;
    if (!mounted) return;
    final run = await launchTkApp(context, doc.id);
    if (run == null || !mounted) return;
    _attach(run);
    setState(() => _output = true);
  }

  Future<void> _export() => runAction(context, () async {
    final src = TkCodegen.generate(d, _code.text);
    await saveBytes(
      utf8.encode(src),
      suggestedName: doc.fileName,
      typeLabel: 'Python',
      extension: 'py',
    );
    if (d.isWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('tk-export-note'),
          content: Text(
            d.connections.isEmpty
                ? tr('Exportada. Necesita Flask (pip install flask).')
                : tr(
                    'Exportada. Necesita Flask, y sus conexiones de datos leen las variables DMSTUDIO_DB_… del entorno.',
                  ),
          ),
        ),
      );
    }
  });

  Future<void> _renameApp() async {
    final v = await promptText(
      context,
      tr('Nombre de la aplicación'),
      doc.name,
    );
    if (v == null || v.trim().isEmpty || !mounted) return;
    setState(() {
      doc
        ..name = v.trim()
        ..touch();
    });
  }

  Future<void> _close() async {
    if (doc.dirty) {
      final v = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Cambios sin guardar')),
          content: Text(
            doc.pending
                ? tr(
                    '¿Guardar los cambios antes de cerrar? Si los descarta, se pierden los del diseño; el código sin guardar sigue en su pestaña del Editor.',
                  )
                : tr('¿Guardar los cambios antes de cerrar?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(tr('Cancelar')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'discard'),
              child: Text(tr('Descartar')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: Text(tr('Guardar')),
            ),
          ],
        ),
      );
      if (v == null || !mounted) return;
      if (v == 'save' && !await _save()) return;
    }
    await widget.onClose();
  }

  // ------------------------------------------------------------- pantalla
  Widget _tool(
    IconData icon,
    String tip,
    VoidCallback? onTap, {
    Key? key,
    bool on = false,
    Color? color,
  }) => IconButton(
    key: key,
    tooltip: tip,
    iconSize: 17,
    visualDensity: VisualDensity.compact,
    isSelected: on,
    // Con color propio (ejecutar en verde, detener en rojo), atenuado si no
    // se puede usar ahora.
    color: color,
    disabledColor: color?.withValues(alpha: .35),
    icon: Icon(icon),
    onPressed: onTap,
  );

  Widget _toolbar(ThemeData t) {
    final running = _run?.running ?? false;
    final two = _selection.length > 1;
    void Function()? al(String m) => two ? () => _align(m) : null;
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      color: t.colorScheme.surfaceContainerHigh,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _tool(LucideIcons.arrowLeft, tr('Volver a los proyectos'), _close),
            TextButton(
              onPressed: _renameApp,
              child: Text('${doc.name}${doc.dirty ? ' •' : ''}'),
            ),
            _tool(
              LucideIcons.save,
              tr('Guardar'),
              _save,
              key: const ValueKey('tk-save'),
            ),
            _tool(
              LucideIcons.undo2,
              tr('Deshacer'),
              doc.undo.isEmpty ? null : _undoStep,
            ),
            if (TkRunner.supported) ...[
              const VerticalDivider(width: 12),
              _tool(
                LucideIcons.play,
                tr('Ejecutar (F9)'),
                running ? null : _runApp,
                key: const ValueKey('tk-run'),
                color: AppColors.success,
              ),
              _tool(
                LucideIcons.square,
                tr('Detener'),
                running ? () => _run?.stop() : null,
                key: const ValueKey('tk-stop'),
                color: AppColors.danger,
              ),
              if (d.isWeb)
                _tool(
                  LucideIcons.externalLink,
                  tr('Abrir en el navegador'),
                  running && _run?.url != null
                      ? () => openTkWebApp(context, _run!)
                      : null,
                  key: const ValueKey('tk-open'),
                ),
            ],
            _tool(LucideIcons.fileDown, tr('Exportar el archivo .py'), _export),
            _tool(
              LucideIcons.folderOpen,
              tr('Mostrar la carpeta del proyecto'),
              () => revealInFiles(doc.id),
            ),
            _tool(
              LucideIcons.sparkles,
              tr('Pedir a la IA'),
              _aiBusy ? null : _askAi,
              key: const ValueKey('tk-ai'),
            ),
            _tool(
              LucideIcons.gitFork,
              tr('GitHub: publicar o subir los cambios'),
              () => showProjectGitHub(
                context,
                dir: doc.id,
                name: doc.name,
                beforeGit: () async => !doc.dirty || await _save(),
              ),
              key: const ValueKey('tk-github'),
            ),
            _tool(
              LucideIcons.wallet,
              tr('Presupuesto de IA'),
              () => showAiBudget(context, project: doc.id, name: doc.name),
              key: const ValueKey('tk-budget'),
            ),
            _tool(
              LucideIcons.bot,
              tr('Chat con Claude Code'),
              () => setState(() => _claude = !_claude),
              key: const ValueKey('tk-claude'),
              on: _claude,
            ),
            if (_aiBusy)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const VerticalDivider(width: 12),
            _tool(
              LucideIcons.alignStartVertical,
              tr('Alinear a la izquierda'),
              al('left'),
            ),
            _tool(
              LucideIcons.alignCenterVertical,
              tr('Centrar en horizontal'),
              al('center'),
            ),
            _tool(
              LucideIcons.alignEndVertical,
              tr('Alinear a la derecha'),
              al('right'),
            ),
            _tool(
              LucideIcons.alignStartHorizontal,
              tr('Alinear arriba'),
              al('top'),
            ),
            _tool(
              LucideIcons.alignCenterHorizontal,
              tr('Centrar en vertical'),
              al('middle'),
            ),
            _tool(
              LucideIcons.alignEndHorizontal,
              tr('Alinear abajo'),
              al('bottom'),
            ),
            _tool(
              LucideIcons.stretchHorizontal,
              tr('Igualar el ancho'),
              al('width'),
            ),
            _tool(
              LucideIcons.stretchVertical,
              tr('Igualar el alto'),
              al('height'),
            ),
            _tool(
              LucideIcons.alignHorizontalJustifyCenter,
              tr('Centrar en la ventana (horizontal)'),
              _selection.isEmpty
                  ? null
                  : () => _centerInParent(horizontal: true),
            ),
            _tool(
              LucideIcons.alignVerticalJustifyCenter,
              tr('Centrar en la ventana (vertical)'),
              _selection.isEmpty
                  ? null
                  : () => _centerInParent(horizontal: false),
            ),
            const VerticalDivider(width: 12),
            _tool(
              LucideIcons.grid3x3,
              tr('Ajustar a la rejilla'),
              () => setState(() => _snap = !_snap),
              on: _snap,
            ),
            if (TkRunner.supported)
              _tool(
                LucideIcons.panelBottom,
                tr('Ver la salida'),
                () => setState(() => _output = !_output),
                on: _output,
              ),
          ],
        ),
      ),
    );
  }

  /// Paleta de componentes: una barra de iconos juntos, como la de un IDE
  /// visual. El nombre sale al pasar el ratón; se arrastran a la ventana o
  /// se añaden con doble clic.
  Widget _palette(ThemeData t) => Container(
    height: 34,
    decoration: BoxDecoration(
      color: t.colorScheme.surfaceContainerLow,
      border: Border(bottom: BorderSide(color: t.dividerColor)),
    ),
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      children: [
        for (final c in tkComponents)
          Draggable<String>(
            key: ValueKey('tk-palette-${c.kind}'),
            data: c.kind,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Material(
              elevation: 4,
              color: t.colorScheme.primaryContainer,
              child: SizedBox(
                width: c.width.toDouble(),
                height: c.height.toDouble(),
                child: Center(child: Text(tr(c.label))),
              ),
            ),
            child: Tooltip(
              richMessage: TextSpan(
                children: [
                  TextSpan(
                    text: tr(c.label),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        '\n${d.isWeb && tkWebGap(c.kind) != null ? tkWebGap(c.kind)! : tr('Arrástrelo a la ventana ({0})', [c.kind])}',
                  ),
                ],
              ),
              child: _PaletteButton(
                icon: tkIcon(c.kind),
                onDoubleTap: () => _addAtFreeSpot(c.kind),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _treeRow(
    ThemeData t,
    String? name,
    String label,
    IconData icon,
    int depth,
  ) {
    final on = name == null ? _selection.isEmpty : _selection.contains(name);
    return InkWell(
      key: ValueKey('tk-tree-${name ?? '#form'}'),
      onTap: () => setState(() => _selection = name == null ? {} : {name}),
      child: Container(
        color: on ? t.colorScheme.primary.withValues(alpha: .14) : null,
        padding: EdgeInsets.only(left: 8.0 + depth * 14, top: 3, bottom: 3),
        child: Row(
          children: [
            Icon(icon, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _depth(TkWidget w) {
    var n = 0;
    var p = w.parent;
    while (p != null && n < d.widgets.length) {
      n++;
      p = d.byName(p)?.parent;
    }
    return n;
  }

  Widget _leftPanel(ThemeData t) => Container(
    width: 288,
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: t.dividerColor)),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 160,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              _treeRow(t, null, d.name, LucideIcons.appWindowMac, 0),
              for (final w in d.widgets)
                _treeRow(t, w.name, w.name, tkIcon(w.kind), 1 + _depth(w)),
            ],
          ),
        ),
        Divider(height: 1, color: t.dividerColor),
        Expanded(
          child: TkInspector(
            design: d,
            widgetName: _selection.length == 1 ? _selection.first : null,
            count: _selection.length,
            connections: _connections,
            onBegin: _begin,
            onChanged: _changed,
            onRename: _rename,
            onSetHandler: _setHandler,
            onOpenHandler: _openHandler,
          ),
        ),
      ],
    ),
  );

  Widget _center(ThemeData t) => Column(
    children: [
      Container(
        height: 34,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.dividerColor)),
        ),
        child: Row(
          children: [
            for (final (i, label) in [
              tr('Diseño'),
              tr('Código'),
              tr('Python generado'),
            ].indexed)
              InkWell(
                key: ValueKey('tk-tab-$i'),
                onTap: () => _setTab(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: _tab == i
                            ? t.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                _tab == 0 ? tr('F12: código') : tr('F12: diseño'),
                style: TextStyle(fontSize: 11, color: t.hintColor),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _tab,
          children: [
            _designSurface(t),
            _PythonEditor(
              editorKey: const ValueKey('tk-code'),
              controller: _code,
              focusNode: _codeFocus,
            ),
            _genError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_genError!),
                    ),
                  )
                : _PythonEditor(
                    editorKey: const ValueKey('tk-generated'),
                    controller: _generatedCode,
                    readOnly: true,
                  ),
          ],
        ),
      ),
    ],
  );

  Widget _designSurface(ThemeData t) => ColoredBox(
    color: t.colorScheme.surfaceContainerLow,
    child: ScrollConfiguration(
      // Arrastrar mueve componentes; se desplaza con la rueda y las barras.
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: const {}),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TkFormCanvas(
              design: d,
              selection: _selection,
              snap: _snap,
              onSelect: (s) => setState(() {
                _selection = s;
                _lastEdit = null;
              }),
              onBegin: _begin,
              onChanged: ({required done}) => _changed(),
              onDrop: _add,
              onOpen: _openDefault,
              onMenu: _menu,
              onKey: _key,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _outputPanel(ThemeData t) {
    final run = _run;
    final py = widget.python;
    final state = run == null
        ? tr('Aún no se ha ejecutado.')
        : !run.running
        ? tr('Terminó con el código {0}.', [run.exitCode])
        : run.address != null
        ? tr('En marcha en {0}: solo en este equipo, sin publicar.', [
            run.address,
          ])
        : tr('En ejecución en su propia ventana.');
    return BottomPanel(
      id: 'tk-output',
      background: _editorBg,
      iconColor: _editorDim,
      initialHeight: 160,
      title: Text(
        [
          state,
          if (py != null && py.ok)
            'Python ${py.version} · Tk ${py.tk} · ${py.command}',
          if (py != null && py.oldTk) _oldTkWarning(py),
        ].join('   ·   '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _editorDim, fontSize: 11.5),
      ),
      actions: [
        IconButton(
          key: const ValueKey('tk-output-copy'),
          tooltip: tr('Copiar la salida'),
          iconSize: 15,
          visualDensity: VisualDensity.compact,
          color: _editorDim,
          disabledColor: _editorDim.withValues(alpha: .35),
          icon: const Icon(LucideIcons.copy),
          onPressed: (run?.lines.isEmpty ?? true)
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: run!.lines.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Salida copiada.'))),
                  );
                },
        ),
      ],
      child: ListView.builder(
        key: const ValueKey('tk-output'),
        controller: _outScroll,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: run?.lines.length ?? 0,
        itemBuilder: (_, i) => SelectableText(
          run!.lines[i],
          style: const TextStyle(
            color: Color(0xFFD4D4D4),
            fontFamily: _mono,
            fontFamilyFallback: _monoFallback,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f9): () {
          if (TkRunner.supported && !(_run?.running ?? false)) _runApp();
        },
        const SingleActivator(LogicalKeyboardKey.f12): () =>
            _setTab(_tab == 0 ? 1 : 0),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            _toolbar(t),
            _palette(t),
            Expanded(
              child: Row(
                children: [
                  _leftPanel(t),
                  Expanded(child: _center(t)),
                  if (_claude)
                    TkClaudePanel(
                      key: ValueKey('tk-claude-${doc.id}'),
                      doc: doc,
                      onSave: _save,
                      onReload: _reloadFromClaude,
                      onClose: () => setState(() => _claude = false),
                    ),
                ],
              ),
            ),
            if (_output) _outputPanel(t),
          ],
        ),
      ),
    );
  }
}

/// Nombre y destino de una aplicación nueva.
class _NewAppDialog extends StatefulWidget {
  const _NewAppDialog();

  @override
  State<_NewAppDialog> createState() => _NewAppDialogState();
}

class _NewAppDialogState extends State<_NewAppDialog> {
  late final _name = TextEditingController(text: tr('Mi aplicación'));
  String _target = tkTargetDesktop;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() => Navigator.pop(context, (_name.text, _target));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('tk-new-dialog'),
      title: Text(tr('Nuevo proyecto')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('tk-new-name'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('Nombre')),
              onSubmitted: (_) => _ok(),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              key: const ValueKey('tk-new-target'),
              segments: [
                ButtonSegment(
                  value: tkTargetDesktop,
                  label: Text(tr('Escritorio (Python)')),
                  icon: const Icon(LucideIcons.appWindowMac, size: 16),
                ),
                ButtonSegment(
                  value: tkTargetWeb,
                  label: Text(tr('Web (Flask)')),
                  icon: const Icon(LucideIcons.globe, size: 16),
                ),
              ],
              selected: {_target},
              onSelectionChanged: (v) => setState(() => _target = v.first),
            ),
            const SizedBox(height: 10),
            Text(
              _target == tkTargetWeb
                  ? tr(
                      'El mismo diseñador y el mismo Python: la página se abre en su navegador y el código corre en un servidor de este equipo. Necesita Flask. El destino no se puede cambiar después.',
                    )
                  : tr(
                      'Una ventana del sistema con tkinter. El destino no se puede cambiar después.',
                    ),
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          key: const ValueKey('tk-new-ok'),
          onPressed: _ok,
          child: Text(tr('Crear')),
        ),
      ],
    );
  }
}

/// Lo que se le pide a la IA.
class _AiRequest {
  const _AiRequest(this.mode, this.prompt, this.imageUrl);

  /// `change`, `new` o `code`.
  final String mode;
  final String prompt;
  final String? imageUrl;
}

/// Caja para pedirle la ventana a la IA.
class _AiDialog extends StatefulWidget {
  const _AiDialog({required this.missing, required this.target});

  /// Qué falta para poder usarla (null: nada).
  final String? missing;

  /// Componente seleccionado, para pedir el código de su evento.
  final String? target;

  @override
  State<_AiDialog> createState() => _AiDialogState();
}

class _AiDialogState extends State<_AiDialog> {
  final _c = TextEditingController();
  late String _mode = widget.target == null ? 'change' : 'code';
  String? _image, _imageName;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: tr('Imagen'),
          extensions: const ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    final name = f.name.toLowerCase();
    final mime = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    if (!mounted) return;
    setState(() {
      _image = 'data:$mime;base64,${base64Encode(bytes)}';
      _imageName = f.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final missing = widget.missing;
    return AlertDialog(
      key: const ValueKey('tk-ai-dialog'),
      title: Text(tr('Pedir a la IA')),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (missing != null) ...[
              Container(
                key: const ValueKey('tk-ai-missing'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  missing,
                  style: TextStyle(color: t.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'change', label: Text(tr('Cambiar'))),
                ButtonSegment(value: 'new', label: Text(tr('Ventana nueva'))),
                if (widget.target != null)
                  ButtonSegment(
                    value: 'code',
                    label: Text(tr('Código de {0}', [widget.target])),
                  ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('tk-ai-prompt'),
              controller: _c,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: switch (_mode) {
                  'new' => tr(
                    'Una ventana de facturas con cliente, fecha, tabla de líneas y botón guardar',
                  ),
                  'code' => tr('Escribe el código de este botón: …'),
                  _ => tr('Añade un campo de teléfono y alinea los botones'),
                },
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_mode != 'code') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(LucideIcons.imagePlus, size: 16),
                    label: Text(tr('Adjuntar un boceto')),
                    onPressed: _pick,
                  ),
                  if (_imageName != null)
                    Expanded(
                      child: Text(
                        _imageName!,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              tr(
                'Se envían el diseño y su código al proveedor de IA elegido, nunca contraseñas ni claves. Verá la propuesta antes de aplicarla.',
              ),
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          key: const ValueKey('tk-ai-send'),
          onPressed: missing != null || _c.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _AiRequest(
                    _mode,
                    _c.text.trim(),
                    _mode == 'code' ? null : _image,
                  ),
                ),
          child: Text(tr('Pedir')),
        ),
      ],
    );
  }
}

/// Propuesta de la IA: nada se aplica sin que el usuario la acepte.
class _AiPreview extends StatelessWidget {
  const _AiPreview({required this.before, required this.after});
  final TkDesign before;
  final TkAiChange after;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget pane(String title, TkDesign d) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.labelMedium),
          const SizedBox(height: 4),
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: t.colorScheme.surfaceContainerHighest,
            child: TkFormThumbnail(d),
          ),
        ],
      ),
    );
    return AlertDialog(
      key: const ValueKey('tk-ai-preview'),
      title: Text(tr('Propuesta de la IA')),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (after.summary.isNotEmpty) ...[
                Text(after.summary),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  pane(tr('Ahora'), before),
                  const SizedBox(width: 12),
                  pane(tr('Propuesta'), after.design),
                ],
              ),
              const SizedBox(height: 10),
              if (after.methods.isNotEmpty)
                Text(tr('Métodos: {0}', [after.methods.join(', ')])),
              for (final n in after.notes)
                Text(n, style: t.textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                tr(
                  'El código de la IA no se ejecuta solo: al ejecutar la ventana, pasa por la misma aprobación que cualquier otro.',
                ),
                style: t.textTheme.bodySmall,
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(tr('Ver el código')),
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    color: _editorBg,
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        after.code,
                        style: const TextStyle(
                          fontFamily: _mono,
                          fontFamilyFallback: _monoFallback,
                          fontSize: 12,
                          color: Color(0xFFD4D4D4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('tk-ai-discard'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('Descartar')),
        ),
        FilledButton(
          key: const ValueKey('tk-ai-apply'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr('Aplicar')),
        ),
      ],
    );
  }
}

/// Botón de la paleta: solo el icono, resaltado al pasar el ratón.
class _PaletteButton extends StatefulWidget {
  const _PaletteButton({required this.icon, required this.onDoubleTap});
  final IconData icon;
  final VoidCallback onDoubleTap;

  @override
  State<_PaletteButton> createState() => _PaletteButtonState();
}

class _PaletteButtonState extends State<_PaletteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? t.colorScheme.primary.withValues(alpha: .14) : null,
            border: Border.all(
              color: _hover
                  ? t.colorScheme.primary.withValues(alpha: .5)
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hover ? t.colorScheme.primary : t.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
