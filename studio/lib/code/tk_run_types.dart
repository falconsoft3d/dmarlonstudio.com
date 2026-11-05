import 'package:flutter/foundation.dart';

import 'tk_debug.dart';

/// Python encontrado en este equipo.
class TkPython {
  const TkPython({
    this.command,
    this.args = const [],
    this.version,
    this.tk,
    this.withoutTk,
    this.serverCommand,
    this.serverArgs = const [],
    required this.help,
  });

  /// Orden que lanza Python con tkinter (null = no se encontró).
  final String? command;
  final List<String> args;
  final String? version;

  /// Versión de Tk.
  final String? tk;

  /// Python encontrado que no trae tkinter.
  final String? withoutTk;

  /// Python para una aplicación web cuando ninguno trae tkinter: Flask no lo
  /// necesita.
  final String? serverCommand;
  final List<String> serverArgs;

  /// Qué instalar en este sistema.
  final String help;

  bool get ok => command != null;

  /// Tk anterior a 8.6, el que trae macOS: no respeta los colores del diseño.
  bool get oldTk => tk != null && tk!.startsWith('8.5');

  /// El Python con el que se lanzan las aplicaciones web.
  TkPython get web => serverCommand == null
      ? this
      : TkPython(command: serverCommand, args: serverArgs, help: help);
}

/// Paquete de Python que le falta a un proyecto para ejecutarse.
class TkNeed {
  const TkNeed({
    required this.title,
    required this.why,
    required this.packages,
    required this.command,
    this.optional = false,
    this.installer,
  });

  /// Cómo se instala si no es con pip (por ejemplo, Homebrew).
  final Future<void> Function()? installer;

  final String title;

  /// Para qué hace falta.
  final String why;

  /// Lo que se le pasa a pip.
  final List<String> packages;

  /// La orden para instalarlo a mano.
  final String command;

  /// Se puede ejecutar sin él (con menos funciones).
  final bool optional;
}

/// Conexión guardada que usa una ventana: los datos solo salen de aquí, al
/// lanzarla, hacia el entorno de su proceso (nunca al archivo generado).
class TkDbLink {
  const TkDbLink(this.component, this.name, this.kind, this.config);

  /// Componente «Conexión de datos» del diseño.
  final String component;

  /// Nombre de la conexión guardada en Bases de datos.
  final String name;

  /// sqlite, postgres o mysql.
  final String kind;
  final Map<String, Object?> config;
}

/// Ventana lista para lanzarse: el código exacto que se ejecutará y dónde
/// quedó escrito. La crea `ProjectStore.prepareRun`.
class TkPrepared {
  const TkPrepared({
    required this.id,
    required this.name,
    required this.source,
    required this.file,
    this.links = const [],
    this.web = false,
    this.vars = const {},
    this.tray = false,
    this.ai = false,
    this.anthropicKey,
    this.unitStart = 0,
    this.unitLines = 0,
    this.electron = false,
    this.chrome = false,
    this.next = false,
    this.cpp = false,
    this.pascal = false,
    this.console,
    this.flutter = false,
    this.desktop = false,
  });

  /// Flutter de escritorio: se abre en una ventana del sistema, no en el
  /// simulador.
  final bool desktop;

  /// App de Flutter: [file] es su lib/app.dart en build/flutter; se abre
  /// en el simulador del estudio.
  final bool flutter;

  /// Aplicación de consola: py, c, cpp o pas; [file] es su main en
  /// build/console.
  final String? console;

  /// Pascal con Lazarus: [file] es su Form1.pas en build/pascal.
  final bool pascal;

  /// C++ con FLTK: [file] es su Form1.cpp en build/cpp.
  final bool cpp;

  /// Web con Next.js: [file] es su app/dms/Form1.js en build/nextjs.
  final bool next;

  /// Extensión de Chrome: [file] es su Form1.js en build/extension y se
  /// abre la vista previa (con [electron] también verdadero).
  final bool chrome;

  /// Aplicación de Electron: [file] es su Form1.js en build/electron y
  /// [source], el código del usuario.
  final bool electron;

  /// Líneas del archivo generado antes del código del usuario, y cuántas
  /// tiene ese código: el depurador solo se detiene ahí.
  final int unitStart;
  final int unitLines;

  /// Carpeta del proyecto.
  final String id;
  final String name;
  final String source;

  /// El archivo generado en `build/`.
  final String file;

  /// Bases a las que se conecta.
  final List<TkDbLink> links;

  /// Aplicación web de Flask, no una ventana.
  final bool web;

  /// Variables del módulo API del estudio para las
  /// integraciones API: llegan al proceso como `DMSTUDIO_ENV_<NOMBRE>`.
  final Map<String, String> vars;

  /// Tiene un Asistente IA: necesita el SDK de Anthropic y su clave.
  final bool ai;

  /// Clave de Anthropic de Ajustes (null: la del entorno, si la hay).
  final String? anthropicKey;

  /// Lleva un icono de bandeja: necesita pystray y Pillow.
  final bool tray;
}

/// Ventana lanzada: su proceso y lo que escribe.
class TkRun extends ChangeNotifier {
  TkRun(this.appId, this.name, this._kill);

  /// Carpeta del proyecto.
  final String appId;
  final String name;
  final void Function() _kill;

  /// Aplicación web: la dirección con el secreto de esta ejecución (para el
  /// navegador; no se enseña ni va al registro).
  String? url;

  /// Aplicación web: la dirección sin el secreto.
  String? address;

  /// Lanzada con el depurador.
  TkDebugSession? debug;

  static const maxLines = 2000;
  final lines = <String>[];
  bool running = true;
  int? exitCode;

  /// La detuvo el usuario.
  bool stopped = false;

  void add(String line) {
    _partial = false;
    lines.add(line);
    _trim();
    notifyListeners();
  }

  void _trim() {
    if (lines.length > maxLines) lines.removeRange(0, lines.length - maxLines);
  }

  /// Consola: la última línea aún no terminó (una pregunta sin salto).
  bool _partial = false;

  /// Consola: escribe una línea en la entrada del programa (null: esta
  /// ejecución no la lee).
  void Function(String line)? input;

  /// Consola: texto tal como llega (con o sin salto de línea al final).
  void addText(String chunk) {
    final parts = chunk.replaceAll('\r\n', '\n').split('\n');
    for (final (i, part) in parts.indexed) {
      final last = i == parts.length - 1;
      if (last && part.isEmpty) {
        // Terminaba en salto de línea.
        _partial = false;
        break;
      }
      if (_partial && lines.isNotEmpty) {
        lines[lines.length - 1] += part;
      } else {
        lines.add(part);
      }
      _partial = last;
    }
    _trim();
    notifyListeners();
  }

  /// Consola: envía [line] al programa y la deja en la salida, detrás de
  /// la pregunta, como en un terminal.
  void send(String line) {
    final f = input;
    if (f == null || !running) return;
    if (_partial && lines.isNotEmpty) {
      lines[lines.length - 1] += line;
      _partial = false;
      notifyListeners();
    } else {
      add(line);
    }
    f(line);
  }

  void finish(int code) {
    running = false;
    exitCode = code;
    debug?.finished();
    notifyListeners();
  }

  void stop() {
    if (!running) return;
    stopped = true;
    _kill();
  }
}
