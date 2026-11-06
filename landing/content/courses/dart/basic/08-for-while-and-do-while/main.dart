void main() {
  // for: a start, a condition and a step.
  for (int i = 1; i <= 5; i++) {
    print('7 x $i = ${7 * i}');
  }

  // while repeats as long as the condition is true.
  double savings = 100;
  int years = 0;
  while (savings < 150) {
    savings *= 1.10; // 10% interest each year
    years++;
  }
  print('$years years to reach ${savings.toStringAsFixed(2)} euros');

  // do-while checks at the end, so it runs at least once.
  int countdown = 3;
  do {
    print('Countdown: $countdown');
    countdown--;
  } while (countdown > 0);

  // continue jumps to the next turn; break leaves the loop.
  String odds = '';
  for (int n = 1; n <= 20; n++) {
    if (n % 2 == 0) continue;
    if (n > 11) break;
    odds += '$n ';
  }
  print('Odd numbers up to 11: $odds');
}
