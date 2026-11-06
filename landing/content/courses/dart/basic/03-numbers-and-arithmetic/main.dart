void main() {
  int eggs = 34;
  int perBox = 6;

  // ${...} puts the result of an expression in the text.
  print('34 + 10 = ${eggs + 10}');
  print('34 * 2 = ${eggs * 2}');

  // / always gives a double, even with two ints.
  print('34 / 6 = ${eggs / perBox}');

  // ~/ keeps only the whole part; % gives the remainder.
  int boxes = eggs ~/ perBox;
  int left = eggs % perBox;
  print('$boxes full boxes and $left eggs left over');

  // The same idea turns minutes into hours and minutes.
  int minutes = 135;
  print('$minutes min = ${minutes ~/ 60} h ${minutes % 60} min');

  // * goes before +; brackets change the order.
  print('2 + 3 * 4 = ${2 + 3 * 4}, (2 + 3) * 4 = ${(2 + 3) * 4}');

  // Doubles and their rounding methods.
  double total = 3.75 * 3;
  print('Total: $total = ${total.toStringAsFixed(2)} euros');
  print('round: ${total.round()}, floor: ${total.floor()}, ceil: ${total.ceil()}');

  // += and ++ update a variable.
  int score = 10;
  score += 5;
  score++;
  print('Score: $score');
}
