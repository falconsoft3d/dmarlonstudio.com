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
  });

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
  });

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
    lines.add(line);
    if (lines.length > maxLines) lines.removeRange(0, lines.length - maxLines);
    notifyListeners();
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
