abstract class Product { String get name; int get price; } // price in cents

// A mixin adds fields and methods to any class that uses it.
// "on Product" means it can only be mixed into products.
mixin Discountable on Product {
  int percentOff = 0;
  int get finalPrice => price - price * percentOff ~/ 100;
}

mixin Shippable {
  double get weightKg; // the class must provide this
  int get shippingCost => weightKg <= 1 ? 399 : 699;
}

class Book extends Product with Discountable, Shippable {
  @override final String name = 'Clean Code';
  @override final int price = 3500;
  @override final double weightKg = 0.8;
}

class Ebook extends Product with Discountable {
  @override final String name = 'Dart in Action (PDF)';
  @override final int price = 1800;
}

void main() {
  final book = Book()..percentOff = 20;
  final ebook = Ebook()..percentOff = 50;
  print('${book.name}: ${book.finalPrice} + shipping ${book.shippingCost}');
  print('${ebook.name}: ${ebook.finalPrice}, ships: ${ebook is Shippable}');
  print('A Book is Discountable: ${book is Discountable}, is Product: ${book is Product}');
}
