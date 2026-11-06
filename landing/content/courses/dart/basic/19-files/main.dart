import 'dart:io';

void main() {
  // A File is a path: here, a file in the current folder.
  var file = File('shopping.txt');

  // writeAsStringSync creates the file, or replaces what it had.
  file.writeAsStringSync('bread,2\nmilk,1\n');

  // With FileMode.append it adds at the end instead.
  file.writeAsStringSync('eggs,12\napples,6\n', mode: FileMode.append);
  print('Exists? ${file.existsSync()}. Size: ${file.lengthSync()} bytes');

  // readAsStringSync gives the whole text at once.
  print(file.readAsStringSync().trim());

  // readAsLinesSync gives a list with one string per line.
  var lines = file.readAsLinesSync();
  int units = 0;
  for (var line in lines) {
    units += int.parse(line.split(',')[1]);
  }
  print('${lines.length} products, $units units in total');

  // Reading a file that does not exist throws an exception.
  try {
    File('missing.txt').readAsStringSync();
  } on FileSystemException catch (e) {
    print('Could not open ${e.path}');
  }

  // existsSync lets us check before reading.
  print('Is there a missing.txt? ${File('missing.txt').existsSync()}');
}
