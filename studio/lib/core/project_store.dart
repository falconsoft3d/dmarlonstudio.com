import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ai/assistant.dart';
import '../code/tk_chrome.dart';
import '../code/tk_codegen.dart';
import '../code/tk_cpp.dart';
import '../code/tk_electron.dart';
import '../code/tk_next.dart';
import '../code/tk_unit.dart';
import '../code/tk_examples.dart';
import '../code/tk_model.dart';
import '../code/tk_run_types.dart';
import '../db/dev_tools.dart';
import '../i18n/tr.dart';
import 'errors.dart';
import 'settings.dart';

/// Versión del estudio que se anota en cada proyecto.
const studioVersion = '0.1.0';

/// Proyecto del Diseñador de interfaz tal como está en el disco.
///
/// Un proyecto es una carpeta con:
/// - `project.dmsproj`: JSON con el nombre, la descripción, el destino
///   (escritorio o web), el diseño de la ventana y las fechas;
/// - `<Ventana>.py`: el código del usuario (la «unidad», como en Delphi);
/// - `build/<nombre>.py`: el archivo de Python generado al ejecutar o
///   exportar (se puede borrar: se rehace de los otros dos).
class StudioProject {
  StudioProject({
    required this.path,
    required this.name,
    this.description,
    required this.design,
    required this.code,
    this.seed,
    this.created = '',
    this.modified = '',
  });

  /// Carpeta del proyecto: es su identificador.
  final String path;
  final String name;
  final String? description;
  final TkDesign design;
  final String code;

  /// Ejemplo del que salió (null = creado por el usuario).
  final String? seed;
  final String created, modified;

  bool get isWeb => design.isWeb;
  bool get isElectron => design.isElectron;
  bool get isChrome => design.isChrome;
  bool get isNext => design.isNext;
  bool get isCpp => design.isCpp;
}

/// Proyectos en carpetas del disco: el área de trabajo, los recientes de
/// fuera de ella, la papelera y los ejemplos de la primera vez.
class ProjectStore {
  ProjectStore._();

  static const projectFile = 'project.dmsproj';
  static const buildDir = 'build';
  static const trashDir = '.papelera';
  static const _format = 'dmarlonstudio.project';

  static const _workspaceKey = 'workspace.dir';
  static const _recentKey = 'projects.recent';
  static const _seededKey = 'projects.seeded';
  static const _seedsKey = 'projects.seeds';

  /// Carpeta del área de trabajo en las pruebas.
  static String? workspaceOverride;

  // --------------------------------------------------------- área de trabajo
  /// Carpeta por defecto: `~/Documents/DMarlon Studio/Proyectos`.
  static Future<String> defaultWorkspace() async {
    String docs;
    try {
      docs = (await getApplicationDocumentsDirectory()).path;
    } on Object {
      docs = p.join(
        Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            Directory.systemTemp.path,
        'Documents',
      );
    }
    return p.join(docs, 'DMarlon Studio', 'Proyectos');
  }

  /// Carpeta del área de trabajo (se crea si no existe).
  static Future<String> workspaceDir() async {
    final dir =
        workspaceOverride ??
        await Settings.get(_workspaceKey) ??
        await defaultWorkspace();
    await Directory(dir).create(recursive: true);
    return dir;
  }

  /// Cambia el área de trabajo (null vuelve a la de serie). Los ejemplos se
  /// cargan también en la nueva la primera vez que se abra.
  static Future<void> setWorkspaceDir(String? dir) async {
    await Settings.set(_workspaceKey, dir?.trim().isEmpty ?? true ? null : dir);
  }

  static bool isProject(String dir) =>
      File(p.join(dir, projectFile)).existsSync();

  /// Nombre de archivo a partir de un nombre libre: `Mi ventana` → `mi_ventana`.
  static String slug(String name) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final lower = name.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    final s = b
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'proyecto' : s;
  }

  /// Carpeta libre dentro de [parent] para [name].
  static String _freeDir(String parent, String name) {
    final base = slug(name);
    var dir = p.join(parent, base);
    for (var i = 2; Directory(dir).existsSync(); i++) {
      dir = p.join(parent, '${base}_$i');
    }
    return dir;
  }

  // -------------------------------------------------------------- lectura
  static Future<Map<String, Object?>> _readMeta(String dir) async {
    final f = File(p.join(dir, projectFile));
    if (!f.existsSync()) {
      throw UserError(tr('«{0}» no es un proyecto de DMarlon Studio.', [dir]));
    }
    try {
      final j = jsonDecode(await f.readAsString());
      if (j is Map) return j.cast<String, Object?>();
    } on FormatException {
      // Abajo.
    }
    throw UserError(tr('El archivo {0} está dañado.', [f.path]));
  }

  /// Archivo del código del usuario de [design] en [dir].
  static String unitPath(String dir, TkDesign design) =>
      p.join(dir, unitName(design));

  /// Archivo del código: Form1.py (Python) o Form1.js (Electron).
  static String unitName(TkDesign design) =>
      '${design.name}.${design.isCpp
          ? 'cpp'
          : design.isJs
          ? 'js'
          : 'py'}';

  /// Lee el proyecto de la carpeta [dir] (null si ya no existe).
  static Future<StudioProject?> get(String dir) async {
    if (!isProject(dir)) return null;
    final j = await _readMeta(dir);
    final design = TkDesign.fromJson(
      ((j['design'] as Map?) ?? const {}).cast<String, Object?>(),
    );
    final unit = File(p.join(dir, '${j['unit'] ?? unitName(design)}'));
    final code = unit.existsSync() ? await unit.readAsString() : '';
    return StudioProject(
      path: dir,
      name: '${j['name'] ?? p.basename(dir)}',
      description: j['description'] as String?,
      design: design,
      code: code.replaceAll('\r\n', '\n'),
      seed: j['seed'] as String?,
      created: '${j['created'] ?? ''}',
      modified: '${j['modified'] ?? ''}',
    );
  }

  /// Los subproyectos de [dir]: sus carpetas que son proyectos (por
  /// ejemplo, «bd» y «front» de un proyecto «Odoo»), por nombre.
  static Future<List<StudioProject>> subprojects(String dir) async {
    final out = <StudioProject>[];
    final root = Directory(dir);
    if (!root.existsSync()) return out;
    await for (final e in root.list(followLinks: false)) {
      final name = p.basename(e.path);
      if (e is! Directory || name.startsWith('.') || name == buildDir) continue;
      if (!isProject(e.path)) continue;
      try {
        final x = await get(e.path);
        if (x != null) out.add(x);
      } on UserError {
        // Uno dañado no impide ver los demás.
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// El proyecto del que [dir] es un subproyecto (null: ninguno).
  static Future<StudioProject?> parentOf(String dir) async {
    final up = p.dirname(p.normalize(dir));
    return isProject(up) ? get(up) : null;
  }

  /// Proyectos del área de trabajo y los recientes de otras carpetas, del
  /// último cambiado al más antiguo.
  static Future<List<StudioProject>> list() async {
    await ensureSeed();
    final ws = await workspaceDir();
    final dirs = <String>{};
    await for (final e in Directory(ws).list(followLinks: false)) {
      if (e is Directory &&
          !p.basename(e.path).startsWith('.') &&
          isProject(e.path)) {
        dirs.add(p.normalize(e.path));
      }
    }
    for (final r in await recent()) {
      if (isProject(r)) dirs.add(p.normalize(r));
    }
    final out = <StudioProject>[];
    // Los subproyectos están dentro de su proyecto.
    dirs.removeWhere((d) => isProject(p.dirname(d)));
    for (final d in dirs) {
      try {
        final x = await get(d);
        if (x != null) out.add(x);
      } on UserError {
        // Un proyecto dañado no impide ver los demás.
      }
    }
    out.sort((a, b) {
      final c = b.modified.compareTo(a.modified);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  // ------------------------------------------------------------ escritura
  static Future<void> _writeAtomic(File f, String text) async {
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(f.path);
  }

  static Future<void> _writeMeta(
    String dir, {
    required String name,
    String? description,
    required TkDesign design,
    String? seed,
    String? created,
  }) async {
    final now = nowStr();
    final meta = <String, Object?>{
      'format': _format,
      'version': 1,
      'studio': studioVersion,
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'target': design.target,
      'seed': ?seed,
      'unit': unitName(design),
      'created': created ?? now,
      'modified': now,
      'design': design.toJson(),
    };
    await _writeAtomic(
      File(p.join(dir, projectFile)),
      '${const JsonEncoder.withIndent('  ').convert(meta)}\n',
    );
  }

  /// Crea un proyecto nuevo en el área de trabajo (o en [parent]) y devuelve
  /// su carpeta.
  static Future<String> create(
    String name, {
    String? description,
    TkDesign? design,
    String? code,
    String? seed,
    String? parent,
    bool sub = false,
  }) async {
    if (name.trim().isEmpty) throw UserError(tr('Indique un nombre.'));
    final d = design ?? TkDesign();
    if (d.props['title'] == null) d.setProp(tkFormTitle, name.trim());
    final dir = _freeDir(parent ?? await workspaceDir(), name.trim());
    await Directory(dir).create(recursive: true);
    await _writeAtomic(
      File(unitPath(dir, d)),
      code ??
          tkUnitOf(d).template(
            d.name,
            tkUnitComment(
              web: d.isWeb,
              electron: d.isElectron,
              chrome: d.isChrome,
              next: d.isNext,
              cpp: d.isCpp,
            ),
          ),
    );
    await _writeMeta(
      dir,
      name: name.trim(),
      description: description,
      design: d,
      seed: seed,
    );
    await _gitignore(dir);
    // Un subproyecto se ve dentro de su proyecto, no en la lista.
    if (parent != null && !sub) await addRecent(dir);
    return dir;
  }

  /// Lo generado no se versiona.
  static Future<void> _gitignore(String dir) async {
    final f = File(p.join(dir, '.gitignore'));
    if (!f.existsSync()) await f.writeAsString('$buildDir/\n__pycache__/\n');
  }

  /// Guarda el diseño y el código. Si la ventana cambió de nombre, su
  /// archivo .py cambia con ella.
  static Future<void> save(
    String dir, {
    String? name,
    String? description,
    required TkDesign design,
    required String code,
  }) async {
    if (name != null && name.trim().isEmpty) {
      throw UserError(tr('Indique un nombre.'));
    }
    final old = await _readMeta(dir);
    final oldUnit = '${old['unit'] ?? ''}';
    await _writeAtomic(File(unitPath(dir, design)), code);
    await _writeMeta(
      dir,
      name: name?.trim() ?? '${old['name'] ?? p.basename(dir)}',
      description: description ?? old['description'] as String?,
      design: design,
      seed: old['seed'] as String?,
      created: old['created'] as String?,
    );
    if (oldUnit.isNotEmpty && oldUnit != unitName(design)) {
      final f = File(p.join(dir, oldUnit));
      if (f.existsSync()) await f.delete();
    }
  }

  /// Guarda solo el código, sin tocar el diseño del disco.
  static Future<void> saveCode(String dir, String code) async {
    final j = await _readMeta(dir);
    final design = TkDesign.fromJson(
      ((j['design'] as Map?) ?? const {}).cast<String, Object?>(),
    );
    await _writeAtomic(
      File(p.join(dir, '${j['unit'] ?? unitName(design)}')),
      code,
    );
    j['modified'] = nowStr();
    await _writeAtomic(
      File(p.join(dir, projectFile)),
      '${const JsonEncoder.withIndent('  ').convert(j)}\n',
    );
  }

  /// Copia el proyecto junto al original y devuelve la carpeta nueva.
  static Future<String> duplicate(String dir) async {
    final x = await get(dir);
    if (x == null) throw UserError(tr('El proyecto ya no existe.'));
    return create(
      tr('{0} (copia)', [x.name]),
      description: x.description,
      design: x.design.clone(),
      code: x.code,
      parent: p.dirname(dir),
    );
  }

  /// Lleva el proyecto a la papelera del área de trabajo (no se borra).
  static Future<String> delete(String dir) async {
    if (!isProject(dir)) throw UserError(tr('El proyecto ya no existe.'));
    final trash = p.join(await workspaceDir(), trashDir);
    await Directory(trash).create(recursive: true);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    final to = p.join(trash, '${p.basename(dir)}_$stamp');
    try {
      await Directory(dir).rename(to);
    } on FileSystemException {
      // Otro disco: se copia y se borra.
      await _copyDir(Directory(dir), Directory(to));
      await Directory(dir).delete(recursive: true);
    }
    await removeRecent(dir);
    return to;
  }

  static Future<void> _copyDir(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final e in from.list(followLinks: false)) {
      final target = p.join(to.path, p.basename(e.path));
      if (e is Directory) {
        await _copyDir(e, Directory(target));
      } else if (e is File) {
        await e.copy(target);
      }
    }
  }

  // -------------------------------------------------------------- recientes
  /// Proyectos abiertos de fuera del área de trabajo.
  static Future<List<String>> recent() async {
    try {
      final j = jsonDecode(await Settings.get(_recentKey) ?? '[]');
      return j is List ? [for (final x in j) '$x'] : const [];
    } on FormatException {
      return const [];
    }
  }

  static Future<void> addRecent(String dir) async {
    final ws = p.normalize(await workspaceDir());
    final d = p.normalize(dir);
    if (p.dirname(d) == ws) return;
    final all = [d, ...(await recent()).where((x) => x != d)];
    await Settings.set(_recentKey, jsonEncode(all.take(20).toList()));
  }

  static Future<void> removeRecent(String dir) async {
    final d = p.normalize(dir);
    final all = (await recent()).where((x) => x != d).toList();
    await Settings.set(_recentKey, jsonEncode(all));
  }

  /// Abre una carpeta de cualquier sitio: tiene que ser un proyecto.
  static Future<StudioProject> openFolder(String dir) async {
    final x = await get(dir);
    if (x == null) {
      throw UserError(
        tr('La carpeta no es un proyecto de DMarlon Studio: falta {0}.', [
          projectFile,
        ]),
      );
    }
    await addRecent(dir);
    return x;
  }

  // -------------------------------------------------------------- ejemplos
  /// Ejemplos que ya existían antes de llevar la cuenta de cada uno: en un
  /// área de trabajo de entonces ya se crearon (o el usuario los borró).
  static const _legacySeeds = {
    'calculator',
    'tasks',
    'converter',
    'contacts',
    'web_calculator',
    'web_tasks',
  };

  /// Cada ejemplo se crea una sola vez por área de trabajo, la primera vez
  /// que se lista: los nuevos de una versión posterior también llegan, y uno
  /// borrado no vuelve.
  static Future<void> ensureSeed() async {
    final ws = await workspaceDir();
    final seeded = (await Settings.get(_seededKey) ?? '')
        .split('\n')
        .where((x) => x.isNotEmpty)
        .toSet();
    final done = (await Settings.get(_seedsKey) ?? '')
        .split('\n')
        .where((x) => x.isNotEmpty)
        .toSet();
    final legacy = seeded.contains(ws);
    var changed = false;
    for (final e in [
      ...tkExamples(tr),
      ...tkWebExamples(tr),
      ...tkElectronExamples(tr),
      ...tkChromeExamples(tr),
      ...tkNextExamples(tr),
      ...tkCppExamples(tr),
    ]) {
      final key = '$ws\t${e.seed}';
      if (done.contains(key) || legacy && _legacySeeds.contains(e.seed)) {
        continue;
      }
      done.add(key);
      changed = true;
      // Los que necesitan una conexión no guardada no se pueden ejecutar.
      if (e.design.connections.isNotEmpty) continue;
      await create(
        e.name,
        description: e.description,
        design: e.design,
        code: e.code,
        seed: e.seed,
      );
    }
    if (changed) await Settings.set(_seedsKey, done.join('\n'));
    if (!legacy) {
      seeded.add(ws);
      await Settings.set(_seededKey, seeded.join('\n'));
    }
  }

  // ------------------------------------------------------------ ejecución
  /// Carpeta de la aplicación de Electron generada.
  static String electronDir(String project) =>
      p.join(project, buildDir, 'electron');

  /// Escribe la aplicación de Electron en build/electron.
  static Future<TkPrepared> _prepareElectron(StudioProject x) async {
    final out = electronDir(x.path);
    final files = TkElectron.files(x.design, x.code, name: x.name);
    await Directory(out).create(recursive: true);
    for (final e in files.entries) {
      await _writeAtomic(File(p.join(out, e.key)), e.value);
    }
    await _gitignore(x.path);
    final unit = x.code.replaceAll('\r\n', '\n');
    return TkPrepared(
      id: x.path,
      name: x.name,
      source: unit,
      file: p.join(out, '${x.design.name}.js'),
      electron: true,
      unitLines: '\n'.allMatches(unit).length + 1,
    );
  }

  /// Carpetas de la extensión de Chrome y de su vista previa.
  static String chromeDir(String project) =>
      p.join(project, buildDir, 'extension');
  static String chromePreviewDir(String project) =>
      p.join(project, buildDir, 'extension-preview');

  /// Escribe la extensión de Chrome en build/extension (sin react.js, que
  /// sale del entorno al lanzarla o exportarla) y su vista previa.
  static Future<TkPrepared> _prepareChrome(StudioProject x) async {
    final out = chromeDir(x.path);
    final files = TkChrome.files(
      x.design,
      x.code,
      name: x.name,
      description: x.description ?? '',
    );
    await writeFiles(out, files);
    await copyImages(x.path, out);
    await writeFiles(
      chromePreviewDir(x.path),
      TkChrome.preview(x.design, x.name),
    );
    await _gitignore(x.path);
    final unit = x.code.replaceAll('\r\n', '\n');
    return TkPrepared(
      id: x.path,
      name: x.name,
      source: unit,
      file: p.join(out, '${x.design.name}.js'),
      electron: true,
      chrome: true,
      unitLines: '\n'.allMatches(unit).length + 1,
    );
  }

  /// Carpeta del proyecto de Next.js generado.
  static String nextDir(String project) => p.join(project, buildDir, 'nextjs');

  /// Escribe el proyecto de Next.js en build/nextjs (las imágenes, en
  /// public/images).
  static Future<TkPrepared> _prepareNext(StudioProject x) async {
    final out = nextDir(x.path);
    await writeFiles(out, TkNext.files(x.design, x.code, name: x.name));
    await copyImages(x.path, p.join(out, 'public'));
    // El icono de la aplicación: Next.js lo toma de app/icon.png.
    final icon = x.design.appIcon;
    if (icon != null && File(p.join(x.path, icon)).existsSync()) {
      await File(
        p.join(x.path, icon),
      ).copy(p.join(out, 'app', 'icon${p.extension(icon)}'));
    }
    await _gitignore(x.path);
    final unit = x.code.replaceAll('\r\n', '\n');
    return TkPrepared(
      id: x.path,
      name: x.name,
      source: unit,
      file: p.join(out, 'app', 'dms', '${x.design.name}.js'),
      next: true,
      unitLines: '\n'.allMatches(unit).length + 1,
    );
  }

  /// Carpeta de la aplicación de C++ generada.
  static String cppDir(String project) => p.join(project, buildDir, 'cpp');

  /// Escribe la aplicación de C++ en build/cpp.
  static Future<TkPrepared> _prepareCpp(StudioProject x) async {
    final out = cppDir(x.path);
    await writeFiles(out, TkCpp.files(x.design, x.code));
    await _gitignore(x.path);
    final unit = x.code.replaceAll('\r\n', '\n');
    return TkPrepared(
      id: x.path,
      name: x.name,
      source: unit,
      file: p.join(out, '${x.design.name}.cpp'),
      cpp: true,
      unitLines: '\n'.allMatches(unit).length + 1,
    );
  }

  /// Escribe [files] (nombre → contenido) en [dir].
  static Future<void> writeFiles(String dir, Map<String, String> files) async {
    await Directory(dir).create(recursive: true);
    for (final e in files.entries) {
      await _writeAtomic(File(p.join(dir, e.key)), e.value);
    }
  }

  /// Copia la carpeta images del proyecto a [dest]/images.
  static Future<void> copyImages(String project, String dest) async {
    final images = Directory(p.join(project, 'images'));
    if (!images.existsSync()) return;
    for (final f in images.listSync(recursive: true).whereType<File>()) {
      final to = File(p.join(dest, p.relative(f.path, from: project)));
      await to.parent.create(recursive: true);
      await f.copy(to.path);
    }
  }

  // ------------------------------------------------------------ Python
  /// Escribe el Python generado en `build/` y devuelve su ruta.
  static Future<String> writeBuild(StudioProject x, String source) async {
    final f = File(p.join(x.path, buildDir, '${slug(x.name)}.py'));
    await _writeAtomic(f, source);
    await _gitignore(x.path);
    return f.path;
  }

  /// Motores que una ventana puede usar.
  static const sqlKinds = {'sqlite', 'postgres', 'mysql'};

  /// Conexiones guardadas, para el inspector (solo el nombre).
  static Future<List<String>> savedConnections() async => [
    for (final r in await DevTools.connections())
      if (sqlKinds.contains(r['kind'])) '${r['name']}',
  ];

  /// Conexiones que necesita la ventana, leídas de las guardadas.
  static Future<List<TkDbLink>> _links(TkDesign d) async {
    final saved = await DevTools.connections();
    final out = <TkDbLink>[];
    for (final w in d.connections) {
      final name = w.text('connection');
      if (name.isEmpty) continue;
      final row = saved
          .where((r) => r['name'] == name && sqlKinds.contains(r['kind']))
          .firstOrNull;
      if (row == null) {
        throw UserError(
          tr('«{0}» usa la conexión «{1}», que no existe en Bases de datos.', [
            w.name,
            name,
          ]),
        );
      }
      out.add(TkDbLink(w.name, name, '${row['kind']}', DevTools.configOf(row)));
    }
    return out;
  }

  /// Lee el proyecto guardado, genera su Python en `build/` y lo deja listo
  /// para lanzarse.
  static Future<TkPrepared> prepareRun(String dir) async {
    final x = await get(dir);
    if (x == null) throw UserError(tr('El proyecto ya no existe.'));
    if (x.isElectron) return _prepareElectron(x);
    if (x.isChrome) return _prepareChrome(x);
    if (x.isNext) return _prepareNext(x);
    if (x.isCpp) return _prepareCpp(x);
    final source = TkCodegen.generate(x.design, x.code);
    final unit = x.code.replaceAll('\r\n', '\n').trimRight();
    final at = source.indexOf(unit);
    final links = await _links(x.design);
    final file = await writeBuild(x, source);
    // Solo las ventanas con una integración API reciben las variables.
    final api = x.design.widgets.any((w) => w.kind == 'RestClient');
    // Con un Asistente IA, la clave de Anthropic de Ajustes le llega por el
    // entorno (nunca al código ni al diseño).
    final ai = x.design.widgets.any((w) => w.kind == 'AiAssistant');
    final key = ai ? (await AiConfig.load()).keyOf(AiProvider.anthropic) : null;
    return TkPrepared(
      id: dir,
      name: x.name,
      source: source,
      file: file,
      links: links,
      web: x.isWeb,
      vars: api ? await DevTools.env() : const {},
      tray: !x.isWeb && x.design.widgets.any((w) => w.kind == 'TrayIcon'),
      ai: ai,
      anthropicKey: key == null || key.isEmpty ? null : key,
      unitStart: at < 0 ? 0 : '\n'.allMatches(source.substring(0, at)).length,
      unitLines: at < 0 ? 0 : '\n'.allMatches(unit).length + 1,
    );
  }
}
