void main() {
  String name = 'Lucia';
  String city = "Seville";

  // + joins strings; $name puts a variable inside the text.
  print('Hello, ' + name + '!');
  print('Hello, $name from $city!');

  // ${...} takes any expression, not only a name.
  int age = 29;
  print('Next year $name will be ${age + 1}.');
  print('$name has ${name.length} letters.');
  print('Shouting: ${city.toUpperCase()}');

  // [index] gives one character; the first one is at 0.
  print('First letter: ${name[0]}, last: ${name[name.length - 1]}');

  // A backslash writes quotes and dollars as they are.
  print('It\'s \$12 for the ticket.');
  print("She said: \"See you in $city\"");

  // Three quotes allow text on several lines.
  String ticket = '''
Passenger: $name
Age: $age
To: $city''';
  print(ticket);

  // * repeats a string.
  print('=' * 20);
}
