import 'dart:async';

Future<int> fetchStock(String sku, int ms) async {
  await Future.delayed(Duration(milliseconds: ms)); // simulated network
  if (sku.startsWith('X')) throw StateError('unknown product $sku');
  return sku.length * 7;
}

Future<void> main() async {
  // In parallel: results come back in list order, not in finishing order.
  final stocks = await Future.wait(
      [fetchStock('MUG-1', 60), fetchStock('TSHIRT-22', 10), fetchStock('CAP', 30)]);
  print('Stocks: $stocks');

  // If one fails, await throws and an ordinary try/catch handles it.
  try {
    await Future.wait([fetchStock('MUG-1', 10), fetchStock('X-404', 5)]);
  } on StateError catch (e) {
    print('Failed: ${e.message}');
  }

  // A record of futures of different types, awaited together.
  final (name, stock) = await (Future.value('Mug'), fetchStock('MUG-1', 20)).wait;
  print('$name: $stock in stock');

  // A timeout turns a call that is too slow into an error.
  try {
    await fetchStock('SLOW-API', 300).timeout(const Duration(milliseconds: 50));
  } on TimeoutException {
    print('Gave up after 50 ms');
  }
  // Or recover with a fallback value instead of an exception.
  print('Fallback: ${await fetchStock('X-1', 5).onError((e, _) => 0)}');
}
