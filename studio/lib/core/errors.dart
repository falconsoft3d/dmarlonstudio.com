/// Error que se muestra tal cual al usuario (sin traza técnica).
class UserError implements Exception {
  UserError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fecha y hora actuales como texto ISO (`2026-11-05 14:30:00`).
String nowStr() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}-${two(n.month)}-${two(n.day)} '
      '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
}
