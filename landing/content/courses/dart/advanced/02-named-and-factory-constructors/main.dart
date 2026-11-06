class Currency {
  final String code;
  final int decimals;
  static final Map<String, Currency> _cache = {};

  // Private named constructor: the one that really builds objects.
  Currency._(this.code, this.decimals) { print('  (new Currency $code)'); }

  // Named constructor that redirects to another one.
  Currency.euro() : this._('EUR', 2);

  // A factory may return an existing object instead of a new one.
  factory Currency(String code) =>
      _cache.putIfAbsent(code, () => Currency._(code, code == 'JPY' ? 0 : 2));

  // A factory can also validate before building anything.
  factory Currency.parse(String text) {
    final code = text.trim().toUpperCase();
    if (code.length != 3) throw FormatException('Bad currency code "$text"');
    return Currency(code);
  }

  String format(int units) => decimals == 0
      ? '$units $code'
      : '${(units / 100).toStringAsFixed(decimals)} $code';
}

void main() {
  final dollar = Currency('USD');
  print('Same object: ${identical(dollar, Currency.parse(' usd '))}');
  print(Currency('JPY').format(1500));
  print(Currency.euro().format(1999));
  try { Currency.parse('euro'); } on FormatException catch (e) { print(e.message); }
}
