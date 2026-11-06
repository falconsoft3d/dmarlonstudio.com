# A dictionary links keys to values: {key: value}.
stock = {"apples": 12, "pears": 5, "plums": 0}
print("Apples in stock:", stock["apples"])

# Change a value, or add a new key, in the same way.
stock["pears"] = 8
stock["kiwis"] = 20
print(stock)

# get() gives a default value when the key does not exist.
print("Bananas:", stock.get("bananas", 0))

# del removes a key and its value.
del stock["plums"]

# items() gives each key together with its value.
for fruit, amount in stock.items():
    print(f"{fruit:<8}{amount:>4}")

print("Fruits:", list(stock.keys()))
print("Total pieces:", sum(stock.values()))
print("Do we sell kiwis?", "kiwis" in stock)
