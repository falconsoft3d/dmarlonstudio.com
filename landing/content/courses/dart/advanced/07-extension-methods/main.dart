// Extensions add methods to types you do not own, like int or String.
extension MoneyFormat on int {
  String get eur => '${(this / 100).toStringAsFixed(2)} EUR';
}

extension TextTools on String {
  String get capitalized =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();

  String toSlug() => trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

extension Stats on Iterable<int> {
  int get total => fold(0, (sum, n) => sum + n);
  double get average => isEmpty ? 0 : total / length;
}

// Generic extension: works on a List of any type.
extension SafeIndex<T> on List<T> {
  T? at(int index) => index >= 0 && index < length ? this[index] : null;
}

void main() {
  print(1999.eur);
  print('mADRID'.capitalized);
  print('  Advanced Dart: Records & Patterns! '.toSlug());
  final basket = [1250, 899, 4500];
  print('Total ${basket.total.eur}, average ${basket.average.round().eur}');
  print('Item 1: ${basket.at(1)}, item 7: ${basket.at(7)}');
}
