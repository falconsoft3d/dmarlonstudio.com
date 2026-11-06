// A record type with named fields, given a short name.
typedef Reading = ({String city, double celsius});

// Returning a positional record: three values, no helper class.
(double, double, double) summarize(List<double> values) {
  final sorted = [...values]..sort();
  final average = values.reduce((a, b) => a + b) / values.length;
  return (sorted.first, sorted.last, average);
}

void main() {
  final List<Reading> readings = [
    (city: 'Madrid', celsius: 31.5),
    (city: 'Bilbao', celsius: 22.0),
    (city: 'Seville', celsius: 36.2),
    (city: 'Vigo', celsius: 19.8),
  ];
  // Destructure the result into three variables at once.
  final (low, high, avg) = summarize([for (final r in readings) r.celsius]);
  print('Low $low, high $high, average ${avg.toStringAsFixed(1)}');

  // :city is short for city: city (take the field into a variable).
  for (final (:city, :celsius) in readings) {
    if (celsius > 30) print('Heat warning in $city ($celsius C)');
  }

  final first = readings.first;
  print('Fields: ${first.city}, positional: ${summarize([1, 2]).$2}');
  print('Equal by value: ${(city: 'Vigo', celsius: 19.8) == readings[3]}');

  var (a, b) = ('left', 'right');
  (a, b) = (b, a); // swap without a temporary variable
  print('Swapped: $a $b');
}
