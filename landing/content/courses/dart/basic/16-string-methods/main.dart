void main() {
  String raw = '   Dart is fun and Dart is fast   ';

  // trim removes the spaces at both ends.
  String text = raw.trim();
  print('[$text]');

  // Changing case and looking for text.
  print(text.toUpperCase());
  print('Has "fast"? ${text.contains('fast')}');
  print('Starts with "Dart"? ${text.startsWith('Dart')}');
  print('"is" first at ${text.indexOf('is')}, last at ${text.lastIndexOf('is')}');

  // replaceAll swaps text; substring(start, end) cuts a piece.
  print(text.replaceAll('Dart', 'Flutter'));
  print('Characters 0 to 4: ${text.substring(0, 4)}');

  // split cuts the text into a list; join glues it back.
  var words = text.split(' ');
  print('${words.length} words: $words');
  print(words.join('_'));

  // padRight and padLeft fill with characters to line up columns.
  var items = ['tea', 'croissant', 'juice'];
  var prices = ['1.30', '2.25', '12.50'];
  for (int i = 0; i < items.length; i++) {
    print('${items[i].padRight(12, '.')}${prices[i].padLeft(6)}');
  }

  // Strings never change: each method returns a new one.
  print('raw still has ${raw.length} characters');
}
