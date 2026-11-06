void main() {
  // A map links keys to values: {key: value}.
  Map<String, double> menu = {'coffee': 1.40, 'tea': 1.20, 'toast': 2.10};
  print('A coffee costs ${menu['coffee']} euros');

  // map[key] = value changes a value or adds a new key.
  menu['tea'] = 1.30;
  menu['juice'] = 2.50;
  print(menu);

  // A missing key gives null; ?? puts a default in its place.
  print('Cake: ${menu['cake']}, or rather ${menu['cake'] ?? 0.0}');

  // remove deletes a key with its value.
  menu.remove('toast');
  print('Toast? ${menu.containsKey('toast')}. Keys: ${menu.keys.toList()}');

  // entries gives each key together with its value.
  for (var item in menu.entries) {
    print('${item.key.padRight(8)}${item.value.toStringAsFixed(2)}');
  }

  // Counting with a map: one key per drink.
  var orders = ['coffee', 'tea', 'coffee', 'juice', 'coffee', 'tea'];
  var counts = <String, int>{};
  for (var drink in orders) {
    counts[drink] = (counts[drink] ?? 0) + 1;
  }
  print('Orders: $counts');
  print('Different drinks: ${counts.length}');
}
