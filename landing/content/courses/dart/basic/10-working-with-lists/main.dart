void main() {
  var queue = ['Ana', 'Ben', 'Carla'];

  // add puts one element at the end; addAll puts several.
  queue.add('Dani');
  queue.addAll(['Eva', 'Fran']);
  print('Queue: $queue');

  // insert puts it at a given position.
  queue.insert(0, 'Zoe');
  print('Zoe goes first: $queue');

  // remove by value, removeAt by position, removeLast the last one.
  queue.remove('Ben');
  String served = queue.removeAt(0);
  queue.removeLast();
  print('$served served, Ben left, Fran gave up: $queue');

  // sort orders the list itself, from lowest to highest.
  var scores = [72, 95, 58, 81, 64, 88];
  scores.sort();
  print('Sorted: $scores');

  // reversed gives the elements backwards; toList makes a list.
  var ranking = scores.reversed.toList();
  print('Ranking: $ranking');

  // sublist(start, end) copies a part; end is not included.
  print('Top 3: ${ranking.sublist(0, 3)}');
  print('From the 4th on: ${ranking.sublist(3)}');

  queue.clear(); // clear empties the list
  print('Queue after closing: $queue (${queue.length})');
}
