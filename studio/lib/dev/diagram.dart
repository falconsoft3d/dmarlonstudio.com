import 'dart:convert';
import 'dart:math' as math;

import '../ai/assistant.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';
import 'dev_types.dart';

/// Columna de una tabla en un diagrama de base de datos.
class DColumn {
  DColumn(this.name, {this.type = 'TEXT', this.pk = false, this.fk = ''});
  String name, type;
  bool pk;

  /// Tabla.columna a la que apunta (clave ajena), o vacío.
  String fk;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    if (pk) 'pk': true,
    if (fk.isNotEmpty) 'fk': fk,
  };
  factory DColumn.fromJson(Map j) => DColumn(
    '${j['name'] ?? ''}',
    type: '${j['type'] ?? 'TEXT'}',
    pk: j['pk'] == true,
    fk: '${j['fk'] ?? ''}',
  );
}

/// Figura de un diagrama: de flujo (start, process, decision, io, note) o
/// tabla de base de datos (entity).
class DNode {
  DNode({
    required this.id,
    required this.type,
    this.text = '',
    this.x = 0,
    this.y = 0,
    this.color = 0,
    List<DColumn>? columns,
  }) : columns = columns ?? [];

  String id, type, text;
  double x, y;

  /// Índice de color de la paleta.
  int color;
  List<DColumn> columns;

  static const width = 180.0;

  double get w => type == 'entity' ? 220 : (type == 'decision' ? 170 : width);
  double get h => switch (type) {
    'entity' => 37.0 + 22.0 * math.max(1, columns.length),
    'decision' => 96,
    'note' => 80,
    _ => 64,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'text': text,
    'x': x.roundToDouble(),
    'y': y.roundToDouble(),
    if (color != 0) 'color': color,
    if (columns.isNotEmpty) 'columns': [for (final c in columns) c.toJson()],
  };
  factory DNode.fromJson(Map j) => DNode(
    id: '${j['id']}',
    type: '${j['type'] ?? 'process'}',
    text: '${j['text'] ?? ''}',
    x: (j['x'] as num?)?.toDouble() ?? 0,
    y: (j['y'] as num?)?.toDouble() ?? 0,
    color: (j['color'] as num?)?.toInt() ?? 0,
    columns: [
      for (final c in (j['columns'] is List ? j['columns'] as List : const []))
        DColumn.fromJson(c as Map),
    ],
  );
}

/// Conexión entre dos figuras (en las tablas, la relación 1:1, 1:N o N:M).
class DEdge {
  DEdge(this.from, this.to, {this.label = '', this.kind = ''});
  String from, to, label, kind;

  Map<String, Object?> toJson() => {
    'from': from,
    'to': to,
    if (label.isNotEmpty) 'label': label,
    if (kind.isNotEmpty) 'kind': kind,
  };
  factory DEdge.fromJson(Map j) => DEdge(
    '${j['from']}',
    '${j['to']}',
    label: '${j['label'] ?? ''}',
    kind: '${j['kind'] ?? ''}',
  );
}

/// Diagrama: figuras y conexiones.
class Diagram {
  Diagram({List<DNode>? nodes, List<DEdge>? edges})
    : nodes = nodes ?? [],
      edges = edges ?? [];
  final List<DNode> nodes;
  final List<DEdge> edges;

  String toJsonString() => jsonEncode({
    'nodes': [for (final n in nodes) n.toJson()],
    'edges': [for (final e in edges) e.toJson()],
  });

  factory Diagram.fromJson(Object? j) {
    if (j is String) {
      try {
        j = jsonDecode(j);
      } on FormatException {
        j = null;
      }
    }
    if (j is! Map) return Diagram();
    final nodes = [
      for (final n in (j['nodes'] is List ? j['nodes'] as List : const []))
        DNode.fromJson(n as Map),
    ];
    final ids = {for (final n in nodes) n.id};
    return Diagram(
      nodes: nodes,
      edges: [
        for (final e in (j['edges'] is List ? j['edges'] as List : const []))
          if (ids.contains((e as Map)['from']) && ids.contains(e['to']))
            DEdge.fromJson(e),
      ],
    );
  }

  DNode? node(String id) => nodes.where((n) => n.id == id).firstOrNull;

  String newId() {
    var i = nodes.length + 1;
    while (nodes.any((n) => n.id == 'n$i')) {
      i++;
    }
    return 'n$i';
  }

  /// Coloca las figuras: los flujos de arriba abajo por niveles; las
  /// tablas en una rejilla.
  void layout({required bool er}) {
    if (er) {
      final cols = math.max(1, math.sqrt(nodes.length).ceil());
      var y = 40.0;
      for (var r = 0; r * cols < nodes.length; r++) {
        final row = nodes.skip(r * cols).take(cols).toList();
        for (var c = 0; c < row.length; c++) {
          row[c]
            ..x = 40 + c * 300.0
            ..y = y;
        }
        y += row.map((n) => n.h).fold(0.0, math.max) + 60;
      }
      return;
    }
    final level = <String, int>{};
    final incoming = {
      for (final n in nodes) n.id: edges.where((e) => e.to == n.id).length,
    };
    final queue = [
      for (final n in nodes)
        if (incoming[n.id] == 0) n.id,
    ];
    if (queue.isEmpty && nodes.isNotEmpty) queue.add(nodes.first.id);
    for (final id in queue) {
      level[id] = 0;
    }
    for (var i = 0; i < queue.length; i++) {
      for (final e in edges.where((e) => e.from == queue[i])) {
        if (!level.containsKey(e.to)) {
          level[e.to] = level[queue[i]]! + 1;
          queue.add(e.to);
        }
      }
    }
    for (final n in nodes) {
      level.putIfAbsent(n.id, () => level.values.fold(0, math.max) + 1);
    }
    final perLevel = <int, int>{};
    for (final n in nodes) {
      final l = level[n.id]!;
      final i = perLevel[l] = (perLevel[l] ?? -1) + 1;
      n
        ..x = 60 + i * 240.0
        ..y = 40 + l * 140.0;
    }
  }

  /// Diagrama de base de datos a partir del esquema de una conexión. Las
  /// claves ajenas se deducen de las columnas «xxx_id».
  static Diagram fromSchema(List<DevTable> tables) {
    final d = Diagram();
    final names = {for (final t in tables) t.name};
    for (final t in tables) {
      d.nodes.add(
        DNode(
          id: t.name,
          type: 'entity',
          text: t.name,
          columns: [
            for (final (c, type) in t.columns)
              DColumn(
                c,
                type: type.isEmpty ? '' : type.toUpperCase(),
                pk: c == 'id' || c == '_id',
              ),
          ],
        ),
      );
    }
    for (final n in d.nodes) {
      for (final c in n.columns.where((c) => c.name.endsWith('_id'))) {
        final base = c.name.substring(0, c.name.length - 3);
        final target =
            [
              base,
              '${base}s',
              'res_$base',
              base.replaceAll('_', '.'),
            ].where(names.contains).firstOrNull ??
            names.where((t) => t.endsWith('_$base')).firstOrNull;
        if (target != null && target != n.id) {
          c.fk = '$target.id';
          d.edges.add(DEdge(target, n.id, kind: '1:N', label: c.name));
        }
      }
    }
    d.layout(er: true);
    return d;
  }

  /// CREATE TABLE de un diagrama de base de datos.
  String toSql() {
    final out = <String>[];
    for (final n in nodes.where((n) => n.type == 'entity')) {
      final cols = [
        for (final c in n.columns)
          '  ${c.name} ${c.type.isEmpty ? 'TEXT' : c.type}${c.pk ? ' PRIMARY KEY' : ''}'
              '${c.fk.contains('.') ? ' REFERENCES ${c.fk.split('.').first}(${c.fk.split('.').last})' : ''}',
      ];
      out.add(
        'CREATE TABLE ${n.text.isEmpty ? n.id : n.text} (\n${cols.join(',\n')}\n);',
      );
    }
    return out.join('\n\n');
  }

  /// Diseño de un diagrama con la IA (de flujo o de base de datos).
  static Future<Diagram> design(
    String request, {
    required bool er,
    Diagram? current,
  }) async {
    final assistant = Assistant(config: await AiConfig.load());
    final content = await assistant.chat([
      {
        'role': 'system',
        'content': er
            ? 'You design database ER diagrams. Answer ONLY with JSON: {"nodes": [{"id": table_name, "type": "entity", "text": table_name, '
                  '"columns": [{"name", "type" (SQL type), "pk": bool, "fk": "other_table.id" or ""}]}], '
                  '"edges": [{"from": parent_table, "to": child_table, "kind": "1:1"|"1:N"|"N:M", "label": fk column}]}. '
                  'Use snake_case names, an "id" primary key in every table and foreign keys "<table>_id".'
            : 'You design programming flowcharts. Answer ONLY with JSON: {"nodes": [{"id": "n1", "type": "start"|"process"|"decision"|"io"|"note", "text": short text}], '
                  '"edges": [{"from", "to", "label": e.g. "Sí"/"No" after a decision}]}. Start and end nodes use type "start". Texts in the user language.',
      },
      {
        'role': 'user',
        'content':
            '${current == null || current.nodes.isEmpty ? '' : 'Current diagram: ${current.toJsonString()}\n'}$request',
      },
    ]);
    final t = content.trim().replaceAll(RegExp(r'^```\w*|```$'), '').trim();
    final a = t.indexOf('{'), b = t.lastIndexOf('}');
    final d = a >= 0 && b > a
        ? Diagram.fromJson(t.substring(a, b + 1))
        : Diagram();
    if (d.nodes.isEmpty) {
      throw UserError(tr('La IA no devolvió un diseño válido.'));
    }
    d.layout(er: er);
    return d;
  }
}
