// async* returns a Stream: each yield sends one event, over time.
Stream<int> download(int totalKb, int chunkKb) async* {
  var received = 0;
  while (received < totalKb) {
    await Future.delayed(const Duration(milliseconds: 20)); // a network chunk
    received += chunkKb;
    if (received > totalKb) received = totalKb;
    yield received * 100 ~/ totalKb;
  }
}

Future<void> main() async {
  // await for waits for each event until the stream closes.
  await for (final percent in download(600, 160)) {
    print('Downloaded $percent%');
  }

  // Streams have where, map, fold... like lists, but asynchronous.
  final readings = Stream.fromIterable([18.5, 21.0, 25.4, 30.1, 27.9]);
  final hot = await readings.where((t) => t > 24).map((t) => '$t C').toList();
  print('Hot readings: $hot');

  // A stream that never ends: break cancels the subscription.
  final ticks = Stream.periodic(const Duration(milliseconds: 10), (i) => i + 1);
  await for (final tick in ticks) {
    if (tick > 3) break;
    print('Tick $tick');
  }
  print('Stopped listening');
}
