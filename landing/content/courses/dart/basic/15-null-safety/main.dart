// A ? after the type means it may hold null: "no value".
String? findEmail(Map<String, String> book, String name) => book[name];

void main() {
  var emails = {'Ana': 'ana@mail.com', 'Luis': 'luis@work.org'};

  // String can never be null; String? can, and starts as null.
  String owner = 'Ana';
  String? nickname;
  print('Owner: $owner, nickname: $nickname');

  // ?? gives a default value when the left side is null.
  print('Nickname: ${nickname ?? 'none'}');

  // ?. calls the method only if the value is not null.
  String? marta = findEmail(emails, 'Marta');
  print('Marta: ${marta?.toUpperCase()}');
  print('Marta: ${marta?.length ?? 0} characters');

  // After checking != null, Dart treats it as a plain String.
  String? ana = findEmail(emails, 'Ana');
  if (ana != null) {
    print('Ana writes from ${ana.split('@')[1]}');
  }

  // ! means "I am sure it is not null" (and fails if it is).
  String luis = emails['Luis']!;
  print('Luis: ${luis.length} characters');

  // ??= gives a value only if the variable is still null.
  nickname ??= 'Nana';
  nickname ??= 'Other';
  print('Nickname now: $nickname');
}
