# Orders from an online shop: (customer, product, quantity, unit price)
orders = [
    ("Ana", "keyboard", 2, 25.0),
    ("Luis", "mouse", 1, 12.5),
    ("Ana", "monitor", 1, 180.0),
    ("Marta", "mouse", 3, 12.5),
    ("Luis", "cable", 4, 3.0),
]

# List comprehension: one total per order line
totals = [qty * price for _, _, qty, price in orders]
print("Line totals:", totals)

# With a condition: only the lines worth 30 or more
big = [f"{name}/{item}" for name, item, qty, price in orders if qty * price >= 30]
print("Big lines:", big)

# Set comprehension: each product only once (sorted to print it)
products = {item for _, item, _, _ in orders}
print("Products:", sorted(products))

# Dict comprehension: customer -> amount spent
customers = sorted({name for name, *_ in orders})
spent = {c: sum(q * p for n, _, q, p in orders if n == c) for c in customers}
print("Spent:", spent)

# Turn a dict around: price -> product, for the cheap items
prices = {"keyboard": 25.0, "mouse": 12.5, "cable": 3.0, "monitor": 180.0}
cheap = {price: item for item, price in prices.items() if price < 20}
print("Cheap:", cheap)
