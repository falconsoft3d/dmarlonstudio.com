// throw raises an error when something is not allowed.
double withdraw(double balance, double amount) {
  if (amount <= 0) throw ArgumentError('the amount must be positive');
  if (amount > balance) throw StateError('not enough money');
  return balance - amount;
}

void main() {
  // int.parse fails with a FormatException on bad text.
  for (var text in ['42', 'forty']) {
    try {
      print('Read: ${int.parse(text)}');
    } on FormatException {
      print('"$text" is not a number');
    }
  }

  // on catches one type of error; catch (e) gives the error itself.
  double balance = 100;
  for (var amount in [30.0, -5.0, 500.0]) {
    try {
      balance = withdraw(balance, amount);
      print('Took out $amount, balance $balance');
    } on ArgumentError catch (e) {
      print('Refused: ${e.message}');
    } catch (e) {
      print('Error: $e');
    } finally {
      // finally always runs, with or without an error.
      print('  operation of $amount checked');
    }
  }
  print('Final balance: $balance');
}
