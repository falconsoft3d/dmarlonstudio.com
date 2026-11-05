/// Línea de un diff: ' ' igual, '-' quitada, '+' añadida.
typedef DiffLine = ({String op, String text});

/// Diff por líneas (LCS) de [a] a [b], con [context] líneas de contexto
/// alrededor de cada cambio; los tramos iguales largos se resumen en una
/// línea `…`. Para archivos muy grandes compara solo el principio y el
/// final comunes y marca el resto como sustituido.
List<DiffLine> lineDiff(String? a, String? b, {int context = 3}) {
  final x = a == null || a.isEmpty ? <String>[] : a.split('\n');
  final y = b == null || b.isEmpty ? <String>[] : b.split('\n');
  // Principio y final comunes, fuera de la tabla.
  var start = 0;
  while (start < x.length && start < y.length && x[start] == y[start]) {
    start++;
  }
  var ex = x.length, ey = y.length;
  while (ex > start && ey > start && x[ex - 1] == y[ey - 1]) {
    ex--;
    ey--;
  }
  final mx = x.sublist(start, ex), my = y.sublist(start, ey);
  final ops = <DiffLine>[
    for (final l in x.sublist(0, start)) (op: ' ', text: l),
  ];
  if (mx.length * my.length > 4000000) {
    ops.addAll([for (final l in mx) (op: '-', text: l)]);
    ops.addAll([for (final l in my) (op: '+', text: l)]);
  } else {
    // Tabla de la subsecuencia común más larga.
    final n = mx.length, m = my.length;
    final t = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        t[i][j] = mx[i] == my[j]
            ? t[i + 1][j + 1] + 1
            : (t[i + 1][j] >= t[i][j + 1] ? t[i + 1][j] : t[i][j + 1]);
      }
    }
    var i = 0, j = 0;
    while (i < n && j < m) {
      if (mx[i] == my[j]) {
        ops.add((op: ' ', text: mx[i]));
        i++;
        j++;
      } else if (t[i + 1][j] >= t[i][j + 1]) {
        ops.add((op: '-', text: mx[i++]));
      } else {
        ops.add((op: '+', text: my[j++]));
      }
    }
    while (i < n) {
      ops.add((op: '-', text: mx[i++]));
    }
    while (j < m) {
      ops.add((op: '+', text: my[j++]));
    }
  }
  ops.addAll([for (final l in x.sublist(ex)) (op: ' ', text: l)]);

  // Solo el contexto alrededor de los cambios.
  final keep = List<bool>.filled(ops.length, false);
  for (var k = 0; k < ops.length; k++) {
    if (ops[k].op == ' ') continue;
    for (var c = k - context; c <= k + context; c++) {
      if (c >= 0 && c < ops.length) keep[c] = true;
    }
  }
  final out = <DiffLine>[];
  var skipped = false;
  for (var k = 0; k < ops.length; k++) {
    if (keep[k]) {
      out.add(ops[k]);
      skipped = false;
    } else if (!skipped) {
      out.add((op: '…', text: ''));
      skipped = true;
    }
  }
  return out;
}

/// Líneas añadidas y quitadas.
(int, int) diffStats(List<DiffLine> d) =>
    (d.where((l) => l.op == '+').length, d.where((l) => l.op == '-').length);
