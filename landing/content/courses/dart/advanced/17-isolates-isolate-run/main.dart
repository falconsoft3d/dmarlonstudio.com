import 'dart:isolate';

// CPU-heavy work: count the primes below [limit] with a sieve.
int countPrimes(int limit) {
  final composite = List<bool>.filled(limit, false);
  var count = 0;
  for (var n = 2; n < limit; n++) {
    if (composite[n]) continue;
    count++;
    for (var m = n * n; m < limit; m += n) composite[m] = true;
  }
  return count;
}

Future<void> main() async {
  // Isolate.run runs the function in another isolate (another core)
  // and returns its result as a Future: main stays free meanwhile.
  final primes = await Isolate.run(() => countPrimes(5000000));
  print('Primes below 5,000,000: $primes');

  // Several isolates at once; Future.wait keeps the order of the list.
  final limits = [1000, 100000, 1000000];
  final counts = await Future.wait([for (final n in limits) Isolate.run(() => countPrimes(n))]);
  for (var i = 0; i < limits.length; i++) {
    print('Below ${limits[i]}: ${counts[i]}');
  }

  // An exception inside the isolate comes back to the caller.
  try {
    await Isolate.run(() => countPrimes(-1));
  } on RangeError {
    print('The worker failed with a RangeError');
  }
}
