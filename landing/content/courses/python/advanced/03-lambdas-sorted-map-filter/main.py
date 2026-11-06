products = [
    {"name": "Laptop", "price": 899.0, "stock": 4},
    {"name": "Mouse", "price": 15.5, "stock": 120},
    {"name": "Monitor", "price": 189.9, "stock": 0},
    {"name": "Webcam", "price": 45.0, "stock": 12},
    {"name": "Desk", "price": 189.9, "stock": 3},
]

# A lambda is a small function with no name: arguments : expression
vat = lambda price: round(price * 1.21, 2)
print("Laptop with VAT:", vat(899.0))

# sorted(key=...) decides what to compare
cheapest = sorted(products, key=lambda p: p["price"])
print("By price:", [p["name"] for p in cheapest])

# Tuples as keys: price high to low, then name A to Z
ranked = sorted(products, key=lambda p: (-p["price"], p["name"]))
print("Ranked:", [p["name"] for p in ranked])

# max and min also accept key=
print("Most stock:", max(products, key=lambda p: p["stock"])["name"])

# filter keeps the items for which the function returns True
in_stock = filter(lambda p: p["stock"] > 0, products)
print("In stock:", [p["name"] for p in in_stock])

# map applies a function to every item
names = map(str.upper, (p["name"] for p in products))
print("Labels:", list(names))
print("With VAT:", list(map(vat, [15.5, 45.0])))
