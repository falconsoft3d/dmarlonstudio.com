import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../code/tk_codegen.dart';
import '../code/tk_unit.dart';
import '../code/tk_model.dart';
import '../code/tk_run.dart';
import '../ui/tk_project.dart';
import '../version.dart';
import 'errors.dart';
import 'project_store.dart';
import 'settings.dart';

/// Servidor MCP de DMarlon Studio: Claude (Claude Code u otro cliente MCP)
/// trabaja con los proyectos del Diseñador mientras la app está abierta.
///
/// Transporte «Streamable HTTP» de MCP en `http://127.0.0.1:<puerto>/mcp`,
/// solo en este equipo y con un token (cabecera `Authorization: Bearer`).
/// Las respuestas van en JSON (sin SSE). Los cambios se guardan en el disco
/// y las pestañas abiertas sin cambios pendientes se recargan solas.
class McpServer {
  McpServer._();

  static const defaultPort = 8766;
  static const _protocol = '2025-06-18';
  static const _supported = {'2025-06-18', '2025-03-26', '2024-11-05'};

  static HttpServer? _server;
  static String _token = '';

  static bool get running => _server != null;
  static int? get port => _server?.port;
  static String get token => _token;
  static String get url => 'http://127.0.0.1:${port ?? defaultPort}/mcp';

  /// Orden para darlo de alta en Claude Code (para todos los proyectos).
  static String get claudeCommand =>
      'claude mcp add --transport http --scope user dmarlon-studio $url '
      '--header "Authorization: Bearer $_token"';

  /// Arranca con lo guardado en Ajustes, si está activado.
  static Future<void> startFromSettings() async {
    if (await Settings.get('mcp.enabled') != '1') return;
    try {
      await start();
    } on Object {
      // Sin el MCP la app funciona igual: Ajustes dice que está parado.
    }
  }

  static Future<String> ensureToken() async {
    var t = await Settings.get('mcp.token') ?? '';
    if (t.length < 32) {
      final r = Random.secure();
      t = List.generate(
        32,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await Settings.set('mcp.token', t);
    }
    return _token = t;
  }

  static Future<void> start({int? port}) async {
    await stop();
    await ensureToken();
    final p0 =
        port ??
        int.tryParse(await Settings.get('mcp.port') ?? '') ??
        defaultPort;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, p0);
    } on SocketException catch (e) {
      throw UserError('No se pudo abrir el puerto $p0: ${e.message}');
    }
    _server!.listen(_handle);
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> regenerateToken() async {
    await Settings.set('mcp.token', null);
    await ensureToken();
  }

  // ---------------------------------------------------------------- HTTP
  static Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      // Solo páginas de este mismo equipo (contra el «DNS rebinding»).
      final origin = req.headers.value('origin');
      if (origin != null) {
        final host = Uri.tryParse(origin)?.host ?? '';
        if (host != 'localhost' && host != '127.0.0.1') {
          return _status(res, HttpStatus.forbidden);
        }
      }
      if (req.uri.path != '/mcp') return _status(res, HttpStatus.notFound);
      if (req.headers.value('authorization') != 'Bearer $_token') {
        return _status(res, HttpStatus.unauthorized);
      }
      if (req.method == 'DELETE') return _status(res, HttpStatus.ok);
      if (req.method != 'POST') {
        res.headers.set('allow', 'POST, DELETE');
        return _status(res, HttpStatus.methodNotAllowed);
      }
      final body = await utf8.decodeStream(req);
      final Object? msg;
      try {
        msg = jsonDecode(body);
      } on FormatException {
        return _json(res, _error(null, -32700, 'Parse error'));
      }
      if (msg is List) {
        final out = <Map<String, Object?>>[];
        for (final m in msg) {
          final r = await _message(m);
          if (r != null) out.add(r);
        }
        if (out.isEmpty) return _status(res, HttpStatus.accepted);
        return _json(res, out);
      }
      final out = await _message(msg);
      if (out == null) return _status(res, HttpStatus.accepted);
      return _json(res, out);
    } on Object catch (e) {
      try {
        _json(res, _error(null, -32603, '$e'));
      } on Object {
        // La conexión ya se cerró.
      }
    }
  }

  static void _status(HttpResponse res, int code) {
    res.statusCode = code;
    res.close();
  }

  static void _json(HttpResponse res, Object body) {
    res.statusCode = HttpStatus.ok;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    res.close();
  }

  static Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  /// Respuesta a un mensaje JSON-RPC (null para una notificación).
  static Future<Map<String, Object?>?> _message(Object? m) async {
    if (m is! Map) return _error(null, -32600, 'Invalid Request');
    final id = m['id'];
    final method = '${m['method'] ?? ''}';
    final params = m['params'] is Map
        ? (m['params'] as Map).cast<String, Object?>()
        : <String, Object?>{};
    // Sin id es una notificación: no lleva respuesta.
    if (!m.containsKey('id')) return null;
    Map<String, Object?> ok(Object result) => {
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    };
    switch (method) {
      case 'initialize':
        final asked = '${params['protocolVersion'] ?? ''}';
        return ok({
          'protocolVersion': _supported.contains(asked) ? asked : _protocol,
          'capabilities': {'tools': <String, Object?>{}},
          'serverInfo': {'name': 'dmarlon-studio', 'version': appVersion},
          'instructions': _instructions,
        });
      case 'ping':
        return ok(<String, Object?>{});
      case 'tools/list':
        return ok({'tools': _tools});
      case 'tools/call':
        final name = '${params['name'] ?? ''}';
        final args = params['arguments'] is Map
            ? (params['arguments'] as Map).cast<String, Object?>()
            : <String, Object?>{};
        try {
          final text = await _call(name, args);
          return ok({
            'content': [
              {'type': 'text', 'text': text},
            ],
            'isError': false,
          });
        } on Object catch (e) {
          return ok({
            'content': [
              {'type': 'text', 'text': e is UserError ? e.message : '$e'},
            ],
            'isError': true,
          });
        }
      default:
        return _error(id, -32601, 'Method not found: $method');
    }
  }

  // ---------------------------------------------------------- herramientas
  static const _instructions =
      'DMarlon Studio is a visual IDE that builds Python apps (tkinter desktop windows or Flask web apps) '
      'from a design (a window with positioned components) plus Python code (a class Form1(FormDesign) whose '
      'methods are the event handlers named in the design). Use list_components to learn the component '
      'kinds, their props and events. Prefer add_component/update_component for design changes and update_code '
      'for the code; every event in the design must have its method in the code. generate_python shows the '
      'final file and any problems; run_project starts it on this computer and get_output reads what it printed.';

  static Map<String, Object?> _schema(
    Map<String, Object?> props, [
    List<String> required = const [],
  ]) => {'type': 'object', 'properties': props, 'required': required};

  static const _project = {
    'type': 'string',
    'description': 'Project folder path, or its exact name.',
  };

  static final _tools = <Map<String, Object?>>[
    {
      'name': 'list_projects',
      'description':
          'Lists the DMarlon Studio projects (name, folder, target, components, modified).',
      'inputSchema': _schema({}),
    },
    {
      'name': 'get_project',
      'description':
          'Returns a project: its design (window props and components as JSON) and its Python code.',
      'inputSchema': _schema({'project': _project}, ['project']),
    },
    {
      'name': 'list_components',
      'description':
          'Catalog of the component kinds with their props (key, type, default, choices) and events (key, method suffix, parameter).',
      'inputSchema': _schema({}),
    },
    {
      'name': 'create_project',
      'description':
          'Creates a project in the workspace. target: "desktop" (tkinter, Python), "web" (Flask, Python), "electron" (Electron + React, JavaScript), "chrome" (Chrome extension popup, JavaScript), "nextjs" (Next.js page, JavaScript) or "cpp" (C++ with FLTK).',
      'inputSchema': _schema(
        {
          'name': {'type': 'string'},
          'target': {
            'type': 'string',
            'enum': [
              'desktop',
              'web',
              'electron',
              'chrome',
              'nextjs',
              'cpp',
              'pascal',
              'flutter',
              'console_py',
              'console_c',
              'console_cpp',
              'console_pas',
            ],
          },
          'description': {'type': 'string'},
        },
        ['name'],
      ),
    },
    {
      'name': 'add_component',
      'description':
          'Adds a component to the window. Coordinates in pixels; parent is the name of a Frame or PageControl (page = its page index). events maps an event key to a method name; missing methods are added to the code as stubs.',
      'inputSchema': _schema(
        {
          'project': _project,
          'kind': {'type': 'string'},
          'name': {
            'type': 'string',
            'description': 'Optional; a free name is chosen if empty.',
          },
          'x': {'type': 'integer'},
          'y': {'type': 'integer'},
          'width': {'type': 'integer'},
          'height': {'type': 'integer'},
          'props': {'type': 'object'},
          'events': {'type': 'object'},
          'parent': {'type': 'string'},
          'page': {'type': 'integer'},
        },
        ['project', 'kind'],
      ),
    },
    {
      'name': 'update_component',
      'description':
          'Changes a component: position/size, props (merged; null removes a prop) and events. name "" or "Form1" (the window name) changes the window props.',
      'inputSchema': _schema(
        {
          'project': _project,
          'name': {'type': 'string'},
          'x': {'type': 'integer'},
          'y': {'type': 'integer'},
          'width': {'type': 'integer'},
          'height': {'type': 'integer'},
          'props': {'type': 'object'},
          'events': {'type': 'object'},
        },
        ['project', 'name'],
      ),
    },
    {
      'name': 'remove_component',
      'description': 'Removes a component (and the components inside it).',
      'inputSchema': _schema(
        {
          'project': _project,
          'name': {'type': 'string'},
        },
        ['project', 'name'],
      ),
    },
    {
      'name': 'update_code',
      'description':
          'Replaces the whole Python code of the window (the class Form1(FormDesign) with the event handlers).',
      'inputSchema': _schema(
        {
          'project': _project,
          'code': {'type': 'string'},
        },
        ['project', 'code'],
      ),
    },
    {
      'name': 'generate_python',
      'description':
          'Generates the final Python file of the project and lists design problems, if any.',
      'inputSchema': _schema({'project': _project}, ['project']),
    },
    {
      'name': 'run_project',
      'description':
          'Runs the project on this computer (a tkinter window, or a Flask app opened in the browser).',
      'inputSchema': _schema({'project': _project}, ['project']),
    },
    {
      'name': 'get_output',
      'description':
          'Returns whether the project is running and the last lines it printed (errors included).',
      'inputSchema': _schema(
        {
          'project': _project,
          'lines': {'type': 'integer'},
        },
        ['project'],
      ),
    },
    {
      'name': 'stop_project',
      'description': 'Stops a running project.',
      'inputSchema': _schema({'project': _project}, ['project']),
    },
  ];

  static Future<StudioProject> _find(Object? ref) async {
    final r = '${ref ?? ''}'.trim();
    if (r.isEmpty) throw UserError('Missing "project".');
    if (r.contains('/') || r.contains(r'\')) {
      final x = await ProjectStore.get(r);
      if (x != null) return x;
    }
    final all = await ProjectStore.list();
    final hits = all
        .where(
          (x) =>
              x.name.toLowerCase() == r.toLowerCase() ||
              p.basename(x.path) == r,
        )
        .toList();
    if (hits.isEmpty) {
      throw UserError('No project named "$r". Use list_projects.');
    }
    return hits.first;
  }

  /// Un proyecto abierto en el Diseñador con cambios sin guardar no se toca.
  static void _checkNotDirty(StudioProject x) {
    final open = TkProject.opened
        .where((d) => d.id == p.normalize(x.path))
        .firstOrNull;
    if (open != null && open.dirty) {
      throw UserError(
        'The project "${x.name}" has unsaved changes in the DMarlon Studio Designer: save or discard them first.',
      );
    }
  }

  /// Guarda y, si está abierto en el Diseñador, lo recarga.
  static Future<void> _save(
    StudioProject x,
    TkDesign design,
    String code,
  ) async {
    await ProjectStore.save(x.path, design: design, code: code);
    final fresh = await ProjectStore.get(x.path);
    if (fresh != null) TkProject.reloadFromDisk(fresh);
  }

  static String _pretty(Object? v) =>
      const JsonEncoder.withIndent('  ').convert(v);

  static Future<String> _call(String name, Map<String, Object?> a) async {
    int? i(String k) =>
        a[k] is num ? (a[k] as num).toInt() : int.tryParse('${a[k] ?? ''}');
    switch (name) {
      case 'list_projects':
        final all = await ProjectStore.list();
        return _pretty([
          for (final x in all)
            {
              'name': x.name,
              'path': x.path,
              'target': x.design.target,
              'components': x.design.widgets.length,
              'modified': x.modified,
              if ((x.description ?? '').isNotEmpty)
                'description': x.description,
            },
        ]);

      case 'get_project':
        final x = await _find(a['project']);
        return _pretty({
          'name': x.name,
          'path': x.path,
          'target': x.design.target,
          'design': x.design.toJson(),
          'code': x.code,
        });

      case 'list_components':
        return _pretty([
          for (final c in tkComponents)
            {
              'kind': c.kind,
              'label': c.label,
              'default_size': [c.width, c.height],
              if (!c.visual) 'visual': false,
              if (c.container) 'container': true,
              'props': [
                for (final pr in c.props)
                  {
                    'key': pr.key,
                    'type': pr.type.name,
                    if (pr.def != null && '${pr.def}'.isNotEmpty)
                      'default': pr.def,
                    if (pr.choices.isNotEmpty) 'choices': pr.choices,
                  },
              ],
              'events': [
                for (final e in c.events)
                  {
                    'key': e.key,
                    'method': '<Name>_${e.suffix}',
                    if (e.param.isNotEmpty) 'param': e.param,
                  },
              ],
            },
        ]);

      case 'create_project':
        final target = switch (a['target']) {
          'web' => tkTargetWeb,
          'electron' => tkTargetElectron,
          'chrome' => tkTargetChrome,
          'nextjs' => tkTargetNext,
          'cpp' => tkTargetCpp,
          'pascal' => tkTargetPascal,
          'flutter' => tkTargetFlutter,
          final String t when tkConsoleTargets.contains(t) => t,
          _ => tkTargetDesktop,
        };
        final dir = await ProjectStore.create(
          '${a['name'] ?? ''}',
          description: a['description'] as String?,
          design: TkDesign(target: target),
        );
        return 'Created $target project at $dir';

      case 'add_component':
        final x = await _find(a['project']);
        _checkNotDirty(x);
        final d = x.design;
        final kind = '${a['kind'] ?? ''}';
        final c = tkComponent(kind);
        if (c == null) {
          throw UserError(
            'Unknown component kind "$kind". Use list_components.',
          );
        }
        var wName = '${a['name'] ?? ''}'.trim();
        if (wName.isEmpty) wName = d.freeName(kind);
        if (!d.validName(wName) || d.byName(wName) != null || wName == d.name) {
          throw UserError('Invalid or taken name "$wName".');
        }
        final w = TkWidget(
          kind: kind,
          name: wName,
          x: i('x') ?? 16,
          y: i('y') ?? 16,
          width: i('width') ?? c.width,
          height: i('height') ?? c.height,
          parent: (a['parent'] as String?)?.trim().isEmpty ?? true
              ? null
              : a['parent'] as String,
        );
        if (w.parent != null && d.byName(w.parent!) == null) {
          throw UserError('No parent named "${w.parent}".');
        }
        if (i('page') case final pg?) w.page = pg;
        if (a['props'] is Map) {
          (a['props'] as Map).forEach((k, v) => w.props['$k'] = v);
        }
        var code = x.code;
        if (a['events'] is Map) {
          (a['events'] as Map).forEach((k, v) {
            final e = c.events.where((e) => e.key == '$k').firstOrNull;
            if (e == null) throw UserError('Unknown event "$k" for $kind.');
            w.events['$k'] = '$v';
            code = tkUnitOf(d).ensureMethod(code, d.name, '$v', param: e.param);
          });
        }
        d.widgets.add(w);
        await _save(x, d, code);
        return 'Added $kind "$wName".';

      case 'update_component':
        final x = await _find(a['project']);
        _checkNotDirty(x);
        final d = x.design;
        final target = '${a['name'] ?? ''}'.trim();
        var code = x.code;
        if (target.isEmpty || target == d.name) {
          if (a['props'] is Map) {
            (a['props'] as Map).forEach((k, v) {
              v == null ? d.props.remove('$k') : d.props['$k'] = v;
            });
          }
          if (i('width') case final wv?) d.props['width'] = wv;
          if (i('height') case final hv?) d.props['height'] = hv;
          if (a['events'] is Map) {
            (a['events'] as Map).forEach((k, v) {
              final e = tkFormEvents.where((e) => e.key == '$k').firstOrNull;
              if (e == null) throw UserError('Unknown window event "$k".');
              d.events['$k'] = '$v';
              code = tkUnitOf(
                d,
              ).ensureMethod(code, d.name, '$v', param: e.param);
            });
          }
          await _save(x, d, code);
          return 'Updated the window.';
        }
        final w = d.byName(target);
        if (w == null) throw UserError('No component named "$target".');
        if (i('x') case final v?) w.x = v;
        if (i('y') case final v?) w.y = v;
        if (i('width') case final v?) w.width = v;
        if (i('height') case final v?) w.height = v;
        if (a['props'] is Map) {
          (a['props'] as Map).forEach((k, v) {
            v == null ? w.props.remove('$k') : w.props['$k'] = v;
          });
        }
        if (a['events'] is Map) {
          (a['events'] as Map).forEach((k, v) {
            final e = w.component.events
                .where((e) => e.key == '$k')
                .firstOrNull;
            if (e == null) throw UserError('Unknown event "$k" for ${w.kind}.');
            if (v == null || '$v'.isEmpty) {
              w.events.remove('$k');
            } else {
              w.events['$k'] = '$v';
              code = tkUnitOf(
                d,
              ).ensureMethod(code, d.name, '$v', param: e.param);
            }
          });
        }
        await _save(x, d, code);
        return 'Updated "$target".';

      case 'remove_component':
        final x = await _find(a['project']);
        _checkNotDirty(x);
        final d = x.design;
        final w = d.byName('${a['name'] ?? ''}');
        if (w == null) throw UserError('No component named "${a['name']}".');
        d.remove(w);
        await _save(x, d, x.code);
        return 'Removed "${w.name}".';

      case 'update_code':
        final x = await _find(a['project']);
        _checkNotDirty(x);
        await _save(x, x.design, '${a['code'] ?? ''}');
        return 'Code saved (${'${a['code'] ?? ''}'.split('\n').length} lines).';

      case 'generate_python':
        final x = await _find(a['project']);
        final problems = x.design.problems();
        final source = TkCodegen.generate(x.design, x.code);
        return [
          if (problems.isNotEmpty) 'Problems:\n- ${problems.join('\n- ')}\n',
          source,
        ].join('\n');

      case 'run_project':
        final x = await _find(a['project']);
        final prepared = await ProjectStore.prepareRun(x.path);
        final run = await TkRunner.start(prepared);
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        return [
          run.running ? 'Running.' : 'It ended with code ${run.exitCode}.',
          if (run.address != null) 'Address: ${run.url}',
          if (run.lines.isNotEmpty) 'Output:\n${run.lines.join('\n')}',
        ].join('\n');

      case 'get_output':
        final x = await _find(a['project']);
        final run = TkRunner.runOf(x.path);
        if (run == null) return 'It has not been run in this session.';
        final n = (i('lines') ?? 200).clamp(1, TkRun.maxLines);
        final lines = run.lines.length > n
            ? run.lines.sublist(run.lines.length - n)
            : run.lines;
        return [
          run.running ? 'Running.' : 'Ended with code ${run.exitCode}.',
          if (lines.isNotEmpty) lines.join('\n') else '(no output)',
        ].join('\n');

      case 'stop_project':
        final x = await _find(a['project']);
        final run = TkRunner.runOf(x.path);
        if (run == null || !run.running) return 'It is not running.';
        run.stop();
        return 'Stopped.';
    }
    throw UserError('Unknown tool "$name".');
  }
}
