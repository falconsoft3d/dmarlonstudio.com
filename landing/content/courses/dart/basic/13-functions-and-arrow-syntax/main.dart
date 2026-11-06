// A function: return type, name, parameters and a block.
double toFahrenheit(double celsius) {
  return celsius * 9 / 5 + 32;
}

// Arrow syntax (=>) for a function that is a single expression.
bool isFreezing(double celsius) => celsius <= 0;

String describe(double celsius) =>
    isFreezing(celsius) ? 'freezing' : (celsius > 30 ? 'hot' : 'mild');

// void: the function does something but returns nothing.
void report(String city, double celsius) {
  String f = toFahrenheit(celsius).toStringAsFixed(1);
  print('${city.padRight(8)}$celsius C = $f F, ${describe(celsius)}');
}

void main() {
  report('Oslo', -4);
  report('Madrid', 21);
  report('Seville', 36.5);

  // The result can be kept in a variable or used directly.
  double boiling = toFahrenheit(100);
  print('Water boils at $boiling F');
  print('Freezing at 0 C? ${isFreezing(0)}');

  // Functions are values too: they can go in a variable.
  var convert = toFahrenheit;
  var square = (int n) => n * n;
  print('Body: ${convert(37).toStringAsFixed(1)} F, 12 squared: ${square(12)}');
}
