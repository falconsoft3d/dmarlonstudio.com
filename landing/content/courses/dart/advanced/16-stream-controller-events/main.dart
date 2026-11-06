import 'dart:async';

class Cart {
  final Map<String, int> _items = {};
  // broadcast: any number of listeners can subscribe.
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  void add(String item) {
    _items.update(item, (qty) => qty + 1, ifAbsent: () => 1);
    _events.add('added $item, total ${_items.values.fold(0, (a, b) => a + b)}');
  }

  void remove(String item) => _items.remove(item) == null
      ? _events.addError(StateError('$item is not in the cart'))
      : _events.add('removed $item');

  Future<void> close() => _events.close(); // sends "done" to every listener
}

Future<void> main() async {
  final cart = Cart();
  cart.events.listen((e) => print('log:   $e'),
      onError: (Object e) => print('log:   ERROR ${(e as StateError).message}'),
      onDone: () => print('log:   cart closed'));
  cart.events.where((e) => e.startsWith('added')).listen((e) => print('badge: $e'),
      onError: (_) {});
  cart..add('Coffee beans')..add('Milk')..remove('Sugar')..remove('Milk')
      ..add('Coffee beans');
  await cart.close();
}
