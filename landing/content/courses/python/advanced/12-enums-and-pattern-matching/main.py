from enum import Enum

class Status(Enum):
    PENDING = "pending"
    PAID = "paid"
    SHIPPED = "shipped"

def next_step(status):
    match status:
        case Status.PENDING:
            return "wait for payment"
        case Status.PAID:
            return "pack and ship"
        case _:                       # anything else
            return "nothing to do"

def handle(event):
    match event:                      # match by shape and capture values
        case {"type": "order", "id": oid, "total": total} if total >= 100:
            return f"order {oid}: big order, check stock"
        case {"type": "order", "id": oid}:
            return f"order {oid}: accepted"
        case ("refund", oid, amount):
            return f"refund {amount} EUR for order {oid}"
        case ["cancel", *ids]:
            return f"cancel {len(ids)} orders: {ids}"
        case _:
            return f"unknown event: {event!r}"

for status in Status:
    print(f"{status!s:<15} {status.value!r:<10} -> {next_step(status)}")
for event in [{"type": "order", "id": 7, "total": 250}, {"type": "order", "id": 8},
              ("refund", 7, 40), ["cancel", 3, 4], "ping"]:
    print(handle(event))
