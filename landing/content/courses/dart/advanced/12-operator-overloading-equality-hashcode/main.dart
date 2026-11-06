class Money implements Comparable<Money> {
  final int cents;
  final String currency;
  const Money(this.cents, [this.currency = 'EUR']);

  Money operator +(Money other) {
    if (other.currency != currency) throw ArgumentError('$currency + ${other.currency}');
    return Money(cents + other.cents, currency);
  }
  Money operator *(int times) => Money(cents * times, currency);
  bool operator <(Money other) => cents < other.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents); // for sort()

  // Equal by value: same amount and currency. hashCode must agree with ==.
  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;
  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => '${(cents / 100).toStringAsFixed(2)} $currency';
}

void main() {
  final coffee = Money(150), croissant = Money(195);
  print('Order: ${coffee * 2 + croissant}, cheaper: ${coffee < croissant}');
  print('== ${Money(150) == coffee}, identical ${identical(Money(150), coffee)}');
  print('Distinct prices: ${{coffee, Money(150), croissant}}'); // a Set
  print('Sorted: ${[Money(999), coffee, croissant]..sort()}');
  try { coffee + Money(150, 'USD'); } on ArgumentError catch (e) { print('Cannot add ${e.message}'); }
}
