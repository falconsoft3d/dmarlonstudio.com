import 'dart:convert';
// Either a value or the reason it failed: a switch must handle both.
sealed class Result<T> {}
class Ok<T> extends Result<T> { final T value; Ok(this.value); }
class Err<T> extends Result<T> { final String reason; Err(this.reason); }

class Order {
  final String id;
  final List<(String sku, int qty, int cents)> lines;
  Order.fromJson(Map<String, dynamic> json) : id = json['id'],
        lines = [for (final [String sku, int qty, int cents] in json['lines']) (sku, qty, cents)];
  int get total => lines.fold(0, (sum, line) => sum + line.$2 * line.$3);
  Map<String, dynamic> toJson() => {'id': id, 'total': total};
}
const stock = {'MUG': 5, 'TEE': 0, 'CAP': 3};
Future<Result<Order>> process(Order order) async { // a simulated service
  await Future.delayed(Duration(milliseconds: 10 * order.lines.length));
  final missing = order.lines.where((line) => (stock[line.$1] ?? 0) < line.$2);
  if (missing.isNotEmpty) return Err('${order.id}: no stock of ${missing.first.$1}');
  return order.total > 10000 ? Err('${order.id}: payment declined') : Ok(order);
}
const incoming = '[{"id": "A-1", "lines": [["MUG", 2, 1250]]}, {"id": "A-2", "lines": [["CAP", 1, 1500], '
    '["TEE", 1, 1999]]}, {"id": "A-3", "lines": [["CAP", 3, 4000]]}, {"id": "A-4", "lines": [["MUG", 1, 1250]]}]';

Future<void> main() async {
  final orders = [for (final json in jsonDecode(incoming)) Order.fromJson(json)];
  final results = await Future.wait(orders.map(process)); // all in parallel
  for (final result in results) print(switch (result) {
        Ok(:final value) => 'OK    ${value.id}: ${value.total} cents',
        Err(:final reason) => 'ERROR $reason',
      });
  final accepted = [for (final r in results) if (r case Ok(:final value)) value];
  print(jsonEncode({'accepted': accepted, 'revenue': accepted.fold(0, (s, o) => s + o.total)}));
}
