class BankAccount {
  final String owner;
  // A leading _ makes a name private to this file (its library).
  int _balanceCents = 0;
  int _dailyLimit = 50000;
  final List<String> _history = [];

  BankAccount(this.owner);

  // Getters read like fields but are computed on demand.
  String get balance => '${(_balanceCents / 100).toStringAsFixed(2)} EUR';
  List<String> get history => List.unmodifiable(_history);
  int get dailyLimit => _dailyLimit;

  // A setter looks like an assignment, but can validate.
  set dailyLimit(int cents) {
    if (cents < 0) throw ArgumentError('limit cannot be negative');
    _dailyLimit = cents;
    _history.add('limit $cents');
  }

  void deposit(int cents) {
    _balanceCents += cents;
    _history.add('deposit $cents');
  }
}

void main() {
  final account = BankAccount('Lucia')..deposit(12000)..deposit(3550);
  account.dailyLimit = 20000; // calls the setter
  print('${account.owner}: ${account.balance}, limit ${account.dailyLimit}');
  try { account.dailyLimit = -1; } on ArgumentError catch (e) { print('Rejected: ${e.message}'); }
  try { account.history.add('fake'); } on UnsupportedError { print('Read-only: ${account.history}'); }
}
