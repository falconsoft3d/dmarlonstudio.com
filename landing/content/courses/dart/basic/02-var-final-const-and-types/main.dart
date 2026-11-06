void main() {
  // The type goes before the name: String, int, double, bool.
  String city = 'Valencia';
  int population = 800000;
  double temperature = 22.5;
  bool byTheSea = true;

  // $name puts a variable inside the text.
  print('$city has $population people');
  print('Today: $temperature degrees. By the sea? $byTheSea');

  // var lets Dart work out the type from the first value.
  var visitors = 1200;
  visitors = visitors + 300;
  print('Visitors: $visitors');
  // visitors = 'many';  // Error: visitors is an int.

  // final: given a value once, it can never change.
  final mayor = 'Elena Ruiz';
  // const: a fixed value, known before the program runs.
  const speedLimit = 50;
  // speedLimit = 60;  // Error: a const cannot change.
  print('Mayor: $mayor. Speed limit: $speedLimit km/h');

  // runtimeType tells the type of a value.
  print(city.runtimeType);
  print(visitors.runtimeType);
  print(temperature.runtimeType);
  print(byTheSea.runtimeType);
}
