import 'dart:convert';

class Customer {
  final int id;
  final String name;
  final String? email;
  final List<String> tags;

  Customer({required this.id, required this.name, this.email, this.tags = const []});

  // JSON arrives as Map<String, dynamic>: read each key with its type.
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        tags: List<String>.from(json['tags'] ?? const []),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'tags': tags};
}

const body = '[{"id": 17, "name": "Carmen Ruiz", "email": "carmen@example.com",'
    ' "tags": ["vip"]}, {"id": 18, "name": "Pablo Gil", "email": null}]';

void main() {
  final list = jsonDecode(body) as List; // text -> Dart lists and maps
  final customers = [for (final item in list) Customer.fromJson(item)];
  for (final c in customers) {
    print('#${c.id} ${c.name} <${c.email ?? 'no email'}> ${c.tags}');
  }
  print(jsonEncode(customers.first)); // jsonEncode calls toJson() for you
  try { jsonDecode('{"id": 19,}'); } on FormatException catch (e) { print('Bad JSON: ${e.message}'); }
}
