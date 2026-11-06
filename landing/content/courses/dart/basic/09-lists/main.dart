void main() {
  // A list keeps values in order, between [ ].
  List<String> planets = ['Mercury', 'Venus', 'Earth', 'Mars'];
  print(planets);
  print('The list has ${planets.length} planets');

  // Positions start at 0, so the last one is length - 1.
  print('First: ${planets[0]}, last: ${planets[planets.length - 1]}');
  print('Also: ${planets.first} and ${planets.last}');

  // A position can be given a new value.
  planets[3] = 'Mars (the red one)';

  // for-in goes through every element.
  for (var planet in planets) {
    print('- $planet');
  }

  // var works out the type: here, List<int>.
  var moons = [0, 0, 1, 2];
  int total = 0;
  for (int i = 0; i < moons.length; i++) {
    total += moons[i];
  }
  print('Moons in total: $total');

  // contains, indexOf and isEmpty answer questions.
  print('Has Venus? ${planets.contains('Venus')}');
  print('Earth is at position ${planets.indexOf('Earth')}');
  print('Pluto is at ${planets.indexOf('Pluto')}. Empty? ${planets.isEmpty}');
}
