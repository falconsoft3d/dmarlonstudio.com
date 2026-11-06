void main() {
  // A set keeps each value only once, between { }.
  var tags = {'dart', 'flutter', 'mobile'};
  tags.add('dart'); // already there: nothing changes
  tags.add('desktop');
  print('Tags: $tags (${tags.length})');

  // toSet() removes the repeated values of a list.
  var visits = ['Rome', 'Paris', 'Rome', 'Lisbon', 'Paris', 'Rome'];
  var cities = visits.toSet();
  print('${visits.length} visits, ${cities.length} cities: $cities');

  // contains is very quick in a set, even a big one.
  print('Been to Lisbon? ${cities.contains('Lisbon')}');

  // Operations between two sets.
  var ana = {'chess', 'tennis', 'piano', 'cooking'};
  var ben = {'tennis', 'football', 'cooking'};
  print('Both like: ${ana.intersection(ben)}');
  print('Either likes: ${ana.union(ben)}');
  print('Only Ana: ${ana.difference(ben)}');

  // remove takes a value out.
  ana.remove('piano');
  print('Ana now: $ana');

  // {} alone is an empty map: an empty set needs its type.
  var empty = <String>{};
  print('Empty set: $empty, is empty? ${empty.isEmpty}');
}
