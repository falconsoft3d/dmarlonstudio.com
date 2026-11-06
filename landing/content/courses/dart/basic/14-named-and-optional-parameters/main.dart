// Optional positional parameters go in [ ], with a default value.
String greet(String name, [String greeting = 'Hello']) => '$greeting, $name!';

// Named parameters go in { }; required makes one compulsory.
void book(String hotel, {required int nights, int guests = 2, bool breakfast = false}) {
  int cost = nights * guests * 45;
  if (breakfast) cost += nights * guests * 8;
  String extra = breakfast ? ' with breakfast' : '';
  print('$hotel: $nights nights, $guests guests$extra = $cost euros');
}

// Named parameters with defaults make long calls easy to read.
String button(String text, {String colour = 'blue', bool rounded = true}) =>
    '[$text] $colour${rounded ? ', rounded' : ''}';

void main() {
  print(greet('Marta'));
  print(greet('Marta', 'Good morning'));

  // Named arguments carry their name and can go in any order.
  book('Hotel Sol', nights: 3);
  book('Hotel Mar', guests: 3, nights: 2);
  book('Casa Rural', nights: 4, breakfast: true, guests: 4);
  // book('Hotel Sol');  // Error: nights is required.

  print(button('Buy'));
  print(button('Cancel', colour: 'grey', rounded: false));
}
