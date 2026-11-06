// sync* returns a lazy Iterable: the body runs only as values are requested.
Iterable<String> invoiceNumbers(String prefix) sync* {
  for (var n = 1;; n++) {
    yield '$prefix-${n.toString().padLeft(4, '0')}'; // infinite, and that's fine
  }
}

Iterable<int> readPrices() sync* {
  for (final price in [120, 45, 990, 300, 1500]) {
    print('  reading $price');
    yield price;
  }
}

// yield* hands over every value of another iterable.
Iterable<List<T>> chunks<T>(List<T> items, int size) sync* {
  if (items.length <= size) {
    yield items;
    return;
  }
  yield items.sublist(0, size);
  yield* chunks(items.sublist(size), size);
}

void main() {
  print(invoiceNumbers('INV').skip(41).take(3).toList());
  final expensive = readPrices().where((p) => p > 500).map((p) => p * 121 ~/ 100);
  print('Query built, nothing read yet');
  print('First expensive with VAT: ${expensive.first}'); // stops at 990
  print('Pages: ${chunks(['ana', 'luis', 'eva', 'tom', 'iker'], 2).toList()}');
}
