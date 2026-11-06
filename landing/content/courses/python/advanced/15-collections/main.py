from collections import Counter, defaultdict, deque, namedtuple

Sale = namedtuple("Sale", ["customer", "product", "amount"])
sales = [
    Sale("Ana", "coffee", 3.2), Sale("Luis", "tea", 2.5),
    Sale("Ana", "cake", 4.0), Sale("Marta", "coffee", 3.2),
    Sale("Luis", "coffee", 3.2), Sale("Ana", "coffee", 3.2),
]
first = sales[0]
print(first, "->", first.customer, first[2])      # by name or by index

# Counter: count anything, then ask for the most common
best = Counter(sale.product for sale in sales)
print("Top products:", best.most_common(2))
print("Cake sold:", best["cake"], "| juice sold:", best["juice"])

# defaultdict: a missing key starts with list() instead of failing
by_customer = defaultdict(list)
for sale in sales:
    by_customer[sale.customer].append(sale.product)
print("Ana bought:", by_customer["Ana"])

# deque: fast at both ends; maxlen keeps only the last N items
recent = deque(maxlen=3)
for sale in sales:
    recent.append(sale.customer)
print("Last 3 customers:", list(recent))
recent.appendleft("VIP")              # the oldest drops off the other end
print("After appendleft:", list(recent))

totals = Counter()
for sale in sales:
    totals[sale.customer] += sale.amount
print("Spent:", {name: round(total, 2) for name, total in totals.items()})
