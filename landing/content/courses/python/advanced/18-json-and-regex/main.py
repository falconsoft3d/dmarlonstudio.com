import json
import re

# An order as it arrives from a web API
payload = """{"id": 1042, "customer": "ana@shop.es", "paid": false,
 "items": [{"sku": "KB-01", "qty": 2, "price": 25.0},
           {"sku": "MS-07", "qty": 1, "price": 12.5}]}"""

order = json.loads(payload)           # JSON text -> dicts and lists
total = sum(item["qty"] * item["price"] for item in order["items"])
print("Order", order["id"], "| paid:", order["paid"], "| total:", total)

skus = [item["sku"] for item in order["items"]]
summary = {"order": order["id"], "total": total, "skus": skus}
print(json.dumps(summary, sort_keys=True))    # Python -> JSON text

log = """10:05:12 ERROR payment failed for order 1042 (ana@shop.es)
10:06:40 INFO order 1043 shipped to luis.p@mail.com
10:09:03 WARN slow response: 2350 ms"""

# Named groups: (?P<name>...) captures a piece we can ask for by name
pattern = re.compile(r"(?P<time>\d\d:\d\d):\d\d (?P<level>[A-Z]+) (?P<msg>.+)")
for line in log.splitlines():
    match = pattern.match(line)
    print(f"{match['level']:<5} at {match['time']}: {match['msg']}")

print("Emails:", re.findall(r"[\w.]+@[\w.]+\.\w+", log))
print("Orders:", [int(n) for n in re.findall(r"order (\d+)", log)])
print("Masked:", re.sub(r"[\w.]+@", "***@", log.splitlines()[1]))
