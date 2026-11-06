// A product in a shop catalogue.
class Product {
  final String name;
  final int priceCents;
  final int stock;

  // this.name copies the argument straight into the field.
  Product(this.name, this.priceCents, {this.stock = 0});

  String get label => '$name - ${(priceCents / 100).toStringAsFixed(2)} EUR';
}

class Invoice {
  final String number;
  final String customer;
  final int totalCents;

  // The initializer list (after the colon) sets final fields
  // before the constructor body runs.
  Invoice(this.number, String customer, List<Product> lines)
      : customer = customer.trim().toUpperCase(),
        totalCents = lines.fold(0, (sum, p) => sum + p.priceCents) {
    print('Invoice $number ready for ${this.customer}');
  }
}

void main() {
  final mouse = Product('Wireless mouse', 1999, stock: 25);
  final cable = Product('USB-C cable', 899);
  print(mouse.label);
  print('${cable.name}: ${cable.stock} in stock');
  final invoice = Invoice('INV-0042', '  Garcia Ltd ', [mouse, cable]);
  print('Total: ${invoice.totalCents} cents');
}
