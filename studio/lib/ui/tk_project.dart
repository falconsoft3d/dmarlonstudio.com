import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

import '../code/tk_model.dart';
import '../core/project_store.dart';

/// Proyecto abierto en el Diseñador de interfaz. Sobrevive al cambiar de
/// módulo dentro del estudio: lo que no se ha guardado no se pierde.
///
/// Es la única copia en memoria del diseño y del código: el Diseñador escribe
/// en [code] y la pestaña del Editor de Código también, con cada cambio, así
/// que no hay dos textos que se puedan pisar. Se guardan juntos porque cambian
/// juntos: renombrar la ventana toca el diseño y el código a la vez, y guardar
/// solo uno dejaría un proyecto que no se puede generar.
///
/// Su [id] es la carpeta del proyecto en el disco.
class TkProject {
  TkProject._(this.id, this.name, this.description, this.design, String text)
    : code = CodeLineEditingController.fromText(text) {
    savedCode = _seen = code.text;
    code.addListener(_onCode);
  }

  TkProject._from(StudioProject x)
    : this._(p.normalize(x.path), x.name, x.description, x.design, x.code);

  /// Aviso de cualquier cambio: abrir, cerrar, editar o guardar.
  static final changes = ValueNotifier(0);
  static void _notify() => changes.value++;

  /// Proyectos abiertos en el Diseñador, en el orden de sus pestañas.
  static final _opened = <TkProject>[];
  static TkProject? _active;

  /// Proyectos con su código en una pestaña del Editor.
  static final _inEditor = <TkProject>{};

  /// El proyecto de la pestaña activa del Diseñador (el que sigue el
  /// Editor).
  static TkProject? get current => _active;

  /// Los abiertos, en el orden de sus pestañas.
  static List<TkProject> get opened => List.unmodifiable(_opened);

  /// Abre el proyecto [x] en una pestaña, o activa la suya si ya estaba
  /// abierto (sin volver a leerlo: lo no guardado se conserva). Si el Editor
  /// conserva su código sin guardar de una vez anterior, sigue siendo esa
  /// copia, y no una segunda.
  static TkProject open(StudioProject x) {
    final id = p.normalize(x.path);
    final already = _opened.where((e) => e.id == id).firstOrNull;
    if (already != null) {
      activate(already);
      return already;
    }
    final left = _inEditor.where((e) => e.id == id).firstOrNull;
    final project = left?._reload(x) ?? TkProject._from(x);
    _opened.add(project);
    activate(project);
    return project;
  }

  /// Pasa a la pestaña de [project] (null = la lista de proyectos).
  static void activate(TkProject? project) {
    _active = project;
    _notify();
  }

  /// Cierra la pestaña de [project] (la activa, sin él). Lo pendiente en el
  /// Editor se queda en su pestaña.
  static void close([TkProject? project]) {
    final which = project ?? _active;
    if (which == null) return;
    final i = _opened.indexOf(which);
    _opened.remove(which);
    if (identical(_active, which)) {
      _active = _opened.isEmpty
          ? null
          : _opened[(i - 1).clamp(0, _opened.length - 1)];
    }
    _notify();
  }

  /// Otro programa (el MCP) cambió [x] en el disco: si está abierto y sin
  /// cambios pendientes, toma lo nuevo.
  static void reloadFromDisk(StudioProject x) {
    final id = p.normalize(x.path);
    for (final e in [..._opened, ..._inEditor]) {
      if (e.id == id && !e.dirty) e._reload(x);
    }
    _notify();
  }

  /// ¿Tiene [id] código sin guardar en una pestaña del Editor?
  static bool pendingInEditor(String id) =>
      _inEditor.any((e) => e.id == p.normalize(id) && e.pending);

  TkProject _reload(StudioProject x) {
    final text = x.code.replaceAll('\r\n', '\n');
    name = x.name;
    description = x.description;
    design = x.design;
    undo.clear();
    if (pending) {
      savedCode = text;
      _savedAt = -1;
    } else {
      setCode(text);
      savedCode = text;
      _savedAt = _version;
    }
    return this;
  }

  /// Carpeta del proyecto.
  final String id;
  String name;
  String? description;
  TkDesign design;

  /// El texto del código: lo que ven el Diseñador y el Editor.
  final CodeLineEditingController code;

  /// El código tal como está en el disco.
  late String savedCode;

  /// Pasos para deshacer: diseño y código de antes de cada cambio. El código
  /// es null si cambió a mano después y volver a ese paso lo perdería.
  final undo = <(String, String?)>[];

  late String _seen;
  int _version = 0;
  int _savedAt = 0;
  bool _tab = false;

  bool get isOpen => _opened.contains(this);

  /// Hay cambios sin guardar, de quien sea.
  bool get dirty => _version != _savedAt;

  /// El código ha cambiado desde la última vez que se guardó.
  bool get codeDirty => code.text != savedCode;

  /// Código sin guardar en una pestaña del Editor.
  bool get pending => _tab && codeDirty;

  /// La pestaña del Editor con el código está abierta.
  set inEditor(bool on) {
    _tab = on;
    if (on) {
      _inEditor.add(this);
    } else {
      _inEditor.remove(this);
    }
  }

  /// Archivo del código del usuario: la clase de la ventana.
  String get codeName => ProjectStore.unitName(design);

  /// Ruta completa del archivo del código del usuario.
  String get codePath => ProjectStore.unitPath(id, design);

  /// Archivo de Python generado: el nombre con el que se exporta.
  String get fileName => '${ProjectStore.slug(name)}.py';

  void _onCode() {
    final text = code.text;
    if (text == _seen) return;
    final old = _seen;
    _seen = text;
    // Lo escrito a mano no es de ningún paso: deshacer un paso que no tocó el
    // código lo conserva, y el que sí lo tocó ya no puede volver atrás.
    for (var i = undo.length - 1; i >= 0; i--) {
      final (shape, before) = undo[i];
      if (before == null) break;
      undo[i] = (shape, before == old ? text : null);
    }
    touch();
  }

  /// Hubo un cambio.
  void touch() {
    _version++;
    _notify();
  }

  /// Cambia el código desde el diseño, como un paso más que se puede deshacer.
  void setCode(String text) {
    final clean = text.replaceAll('\r\n', '\n');
    if (code.text == clean) return;
    _seen = clean;
    code.text = clean;
    touch();
  }

  /// Guarda el diseño y el código: el proyecto entero.
  Future<void> save() async {
    final text = code.text, version = _version;
    await ProjectStore.save(
      id,
      name: name,
      description: description,
      design: design,
      code: text,
    );
    savedCode = text;
    _savedAt = version;
    _notify();
  }

  /// Guarda solo el código: lo que quedó pendiente en el Editor al cerrar el
  /// proyecto en el Diseñador, cuyo diseño ya no se conserva.
  Future<void> saveCode() async {
    final text = code.text;
    await ProjectStore.saveCode(id, text);
    savedCode = text;
    _notify();
  }
}
