import 'dart:io';

void main() {
  // stdout.write prints without a new line, like a question.
  stdout.write('What is your name? ');
  // readLineSync() reads one line of text (or null if there is none).
  String name = stdin.readLineSync() ?? '';
  print('Hello, $name!');

  // What is typed is always text: int.parse turns it into a number.
  stdout.write('How old are you? ');
  int age = int.parse(stdin.readLineSync() ?? '0');
  print('In ten years you will be ${age + 10}.');

  // double.parse for numbers with decimals.
  stdout.write('Price of a coffee? ');
  double price = double.parse(stdin.readLineSync() ?? '0');
  stdout.write('Coffees a week? ');
  int cups = int.parse(stdin.readLineSync() ?? '0');

  double perYear = price * cups * 52;
  print('$name, you spend ${perYear.toStringAsFixed(2)} euros a year on coffee.');

  // tryParse gives null instead of failing on bad text.
  stdout.write('Favourite number? ');
  int? favourite = int.tryParse(stdin.readLineSync() ?? '');
  print(favourite == null ? 'That is not a number.' : 'Doubled: ${favourite * 2}');
}
