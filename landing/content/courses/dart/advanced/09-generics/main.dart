abstract class Entity { int get id; }

class Customer implements Entity {
  @override final int id;
  final String name, city;
  Customer(this.id, this.name, this.city);
  @override String toString() => name;
}

// One generic class, valid for any type that is an Entity.
class Repository<T extends Entity> {
  final Map<int, T> _items = {};
  void save(T item) => _items[item.id] = item;
  T? findById(int id) => _items[id];
  List<T> get all => _items.values.toList();
}

// A generic function: K and V are inferred from the arguments.
Map<K, List<V>> groupBy<K, V>(Iterable<V> items, K Function(V) keyOf) {
  final groups = <K, List<V>>{};
  for (final item in items) (groups[keyOf(item)] ??= []).add(item);
  return groups;
}

void main() {
  final customers = Repository<Customer>()
    ..save(Customer(1, 'Elena', 'Madrid'))
    ..save(Customer(2, 'Jorge', 'Malaga'))
    ..save(Customer(3, 'Nuria', 'Madrid'));
  print('Found: ${customers.findById(2)}, missing: ${customers.findById(9)}');
  print(groupBy(customers.all, (c) => c.city));
  print(groupBy(['kiwi', 'fig', 'pear', 'plum'], (s) => s.length));
  print('Type kept at runtime: ${customers.runtimeType}');
}
