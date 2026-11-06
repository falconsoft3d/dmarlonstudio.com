const prices = {'bread': 1.20, 'milk': 0.95, 'cheese': 4.50, 'apples': 2.30};

// Gives the cost of one "product,units" line, or throws an error.
double lineCost(String line) {
  var parts = line.split(',');
  double? price = prices[parts[0]];
  int? units = int.tryParse(parts[1]);
  if (price == null) throw ArgumentError('${parts[0]} is not sold here');
  if (units == null || units <= 0) throw ArgumentError('bad quantity in "$line"');
  return price * units;
}

String row(String label, double euros) =>
    label.padRight(14) + euros.toStringAsFixed(2).padLeft(7);

void main() {
  var cart = ['bread,2', 'cheese,1', 'milk,x', 'apples,3', 'ham,1', 'milk,4', 'bread,0'];
  var totals = <String, double>{};
  for (var line in cart) {
    var product = line.split(',')[0];
    try {
      totals[product] = (totals[product] ?? 0) + lineCost(line);
    } on ArgumentError catch (e) {
      print('Skipped: ${e.message}');
    }
  }
  totals.forEach((product, cost) => print(row(product, cost)));
  double subtotal = totals.values.fold(0, (a, b) => a + b);
  double rate = switch (subtotal) { >= 20 => 0.10, >= 10 => 0.05, _ => 0.0 };
  print('-' * 21);
  print(row('Subtotal', subtotal));
  print(row('Discount (${(rate * 100).round()}%)', -subtotal * rate));
  print(row('TOTAL', subtotal * (1 - rate)));
}
