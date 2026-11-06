// Pretend network calls: a Future is a value that arrives later.
Future<Map<String, Object>> fetchUser(int id) async {
  await Future.delayed(const Duration(milliseconds: 80));
  return {'id': id, 'name': 'Elena', 'plan': 'pro'};
}

Future<List<String>> fetchOrders(int userId) async {
  await Future.delayed(const Duration(milliseconds: 40));
  return ['#1001 headphones', '#1002 phone case'];
}

// An async function always returns a Future, even with a plain return.
Future<int> countOrders(int userId) async => (await fetchOrders(userId)).length;

Future<void> main() async {
  print('1. Asking for user 7');
  final pending = fetchUser(7); // starts now, does not block
  print('2. Main keeps going while the request is in flight');

  final user = await pending; // pause here until the value arrives
  print('3. Hello, ${user['name']} (${user['plan']} plan)');

  // await runs one call after the other, like normal code.
  final orders = await fetchOrders(user['id'] as int);
  for (final order in orders) {
    print('   $order');
  }

  // The older style: register a callback with then().
  await countOrders(7).then((n) => print('4. $n orders in total'));
  print('5. Done');
}
