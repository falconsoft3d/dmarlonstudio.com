// Abstract: cannot be instantiated, may leave methods without a body.
abstract class PaymentMethod {
  String get name;
  int fee(int amount); // abstract: each subclass decides
  // Concrete method that every subclass inherits.
  String charge(int amount) => '$name: ${amount + fee(amount)} (fee ${fee(amount)})';
}

// A pure contract: whoever implements it must write every member.
abstract interface class Refundable { String refund(int amount); }

class Card extends PaymentMethod implements Refundable {
  @override String get name => 'Card';
  @override int fee(int amount) => amount * 15 ~/ 1000 + 25; // 1.5 % + 25
  @override String refund(int amount) => 'refunds $amount to the card';
}
class BankTransfer extends PaymentMethod {
  @override final String name = 'Transfer';
  @override int fee(int amount) => 0;
}
// implements takes only the contract: nothing is inherited.
class GiftCard implements PaymentMethod, Refundable {
  @override String get name => 'Gift card';
  @override int fee(int amount) => 0;
  @override String charge(int amount) => '$name: $amount from the balance';
  @override String refund(int amount) => 'adds $amount back to the gift card';
}

void main() {
  for (final PaymentMethod method in [Card(), BankTransfer(), GiftCard()]) {
    print(method.charge(4000));
    if (method is Refundable) print('  ${(method as Refundable).refund(4000)}');
  }
}
