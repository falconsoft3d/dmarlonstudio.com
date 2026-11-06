void main() {
  var names = ['Ana', 'Ben', 'Carla'];
  var orders = [24.0, 8.5, 61.0, 15.25, 42.0, 5.0];

  // forEach runs a function with each element.
  names.forEach((name) => print('Welcome, $name'));

  // map turns each element into another; toList makes a list.
  var labels = orders.map((o) => '${o.toStringAsFixed(2)} EUR').toList();
  print('Labels: $labels');

  // where keeps only the elements that meet the condition.
  var big = orders.where((o) => o >= 20).toList();
  print('Orders of 20 or more: $big');

  // reduce combines the elements two by two into one.
  var total = orders.reduce((a, b) => a + b);
  var highest = orders.reduce((a, b) => a > b ? a : b);
  print('Total: $total, highest: $highest');

  // fold is like reduce, but starts from a value of any type.
  var small = orders.fold(0, (count, o) => o < 10 ? count + 1 : count);
  var initials = names.fold('', (text, name) => text + name[0]);
  print('Small orders: $small, initials: $initials');

  // They chain: filter, transform and add up in one go.
  var points = orders
      .where((o) => o > 10)
      .map((o) => o ~/ 10)
      .fold(0, (sum, p) => sum + p);
  print('Loyalty points: $points');
}
