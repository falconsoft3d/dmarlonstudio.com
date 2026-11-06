// An enhanced enum: each value carries data and the enum has methods.
enum OrderStatus {
  pending('Pending', canCancel: true),
  paid('Paid', canCancel: true),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label, {this.canCancel = false});

  final String label;
  final bool canCancel;

  OrderStatus? get next => switch (this) {
        pending => paid,
        paid => shipped,
        shipped => delivered,
        delivered || cancelled => null,
      };

  bool get isFinal => next == null;
}

void main() {
  OrderStatus? status = OrderStatus.pending;
  while (status != null) {
    final flags = '${status.canCancel ? 'can cancel' : 'locked'}, final: ${status.isFinal}';
    print('${status.label.padRight(9)} -> $flags');
    status = status.next;
  }
  print(OrderStatus.values.map((s) => s.name).join(' | '));
  final shipped = OrderStatus.values.byName('shipped');
  print('${shipped.label} is value number ${shipped.index}');
}
