import 'dart:io';

/// Ruta de un programa externo, o null si no está. En macOS lanzar uno que
/// no existe cierra la aplicación entera sin excepción ni informe de fallo,
/// así que se busca antes de lanzarlo. Una ruta se comprueba tal cual; un
/// nombre se busca en el PATH (con las extensiones de Windows) y, en
/// macOS, también en las carpetas de Homebrew: una aplicación abierta desde
/// el Finder recibe un PATH mínimo sin ellas.
String? findExecutable(String name) {
  if (name.contains('/') || name.contains(r'\')) {
    return File(name).existsSync() ? name : null;
  }
  final sep = Platform.isWindows ? ';' : ':';
  final dirs = [
    ...(Platform.environment['PATH'] ?? '').split(sep),
    if (Platform.isMacOS) ...['/opt/homebrew/bin', '/usr/local/bin'],
  ];
  final exts = Platform.isWindows
      ? [
          '',
          ...(Platform.environment['PATHEXT'] ?? '.EXE;.CMD;.BAT')
              .toLowerCase()
              .split(';'),
        ]
      : [''];
  for (final d in dirs) {
    if (d.isEmpty) continue;
    for (final e in exts) {
      final f = '$d${Platform.pathSeparator}$name$e';
      if (File(f).existsSync()) return f;
    }
  }
  return null;
}
