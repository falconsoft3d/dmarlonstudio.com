import 'dart:convert';
import 'dart:typed_data';

import '../i18n/tr.dart';

/// «1 fila afectada», «3 filas afectadas».
String affectedMessage(int n) =>
    n == 1 ? tr('1 fila afectada') : tr('{0} filas afectadas', [n]);

/// Resultado de una consulta del gestor de bases de datos.
class DevResult {
  DevResult({
    this.columns = const [],
    this.rows = const [],
    this.affected,
    this.message,
    this.elapsed = Duration.zero,
  });
  final List<String> columns;
  final List<List<Object?>> rows;
  final int? affected;
  final String? message;
  Duration elapsed;

  /// Filas como mapas (columna → valor).
  static DevResult fromMaps(List<Map<String, Object?>> maps, {int? affected}) {
    final cols = <String>[];
    for (final m in maps) {
      for (final k in m.keys) {
        if (!cols.contains(k)) cols.add(k);
      }
    }
    return DevResult(
      columns: cols,
      rows: [
        for (final m in maps) [for (final c in cols) cell(m[c])],
      ],
      affected: affected,
    );
  }

  /// Valor mostrable: los anidados (Mongo) como JSON y los binarios como
  /// «`<n bytes>`».
  static Object? cell(Object? v) => switch (v) {
    null || num() || String() || bool() => v,
    final Uint8List b => '<${b.length} bytes>',
    final List<int> b when b.length > 64 => '<${b.length} bytes>',
    final DateTime d => _date(d),
    final Map m => _json(m),
    final List l => _json(l),
    _ => '$v',
  };

  /// «2024-01-05» (una fecha sin hora) o «2024-01-05 10:30:00».
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final day =
        '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
    if (d.hour == 0 && d.minute == 0 && d.second == 0 && d.millisecond == 0) {
      return day;
    }
    final ms = d.millisecond == 0
        ? ''
        : '.${d.millisecond.toString().padLeft(3, '0')}';
    return '$day ${two(d.hour)}:${two(d.minute)}:${two(d.second)}$ms';
  }

  static String _json(Object v) {
    try {
      return jsonEncode(v, toEncodable: (o) => '$o');
    } catch (_) {
      return '$v';
    }
  }

  /// CSV (separado por «;», como lo abre Excel en español).
  String toCsv() {
    String q(Object? v) {
      final s = v == null ? '' : '$v';
      return s.contains(RegExp(r'[;"\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    return [
      columns.map(q).join(';'),
      for (final r in rows) r.map(q).join(';'),
    ].join('\n');
  }
}

/// Tabla, vista o colección con sus columnas (nombre, tipo).
class DevTable {
  DevTable(this.name, {this.type = 'table', this.columns = const []});
  final String name, type;
  final List<(String, String)> columns;
}

/// Conexión abierta con una base de datos.
abstract class DevDb {
  Future<List<DevTable>> schema();
  Future<DevResult> run(String query);
  Future<void> close();

  /// Lenguaje de la consulta de prueba de una tabla.
  String sampleQuery(DevTable t);
}

/// Archivo o carpeta de un servidor FTP.
class DevFtpEntry {
  DevFtpEntry(this.name, {this.dir = false, this.size, this.modified});
  final String name;
  final bool dir;
  final int? size;
  final DateTime? modified;
}

/// Sesión FTP abierta.
abstract class DevFtp {
  Future<String> pwd();
  Future<List<DevFtpEntry>> list();
  Future<void> cd(String dir);
  Future<void> upload(String localPath, {String? remoteName});
  Future<void> download(String remoteName, String localPath);
  Future<void> mkdir(String name);
  Future<void> delete(DevFtpEntry e);
  Future<void> rename(String from, String to);
  Future<void> close();
}
