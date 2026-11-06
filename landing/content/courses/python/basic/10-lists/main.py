# A list keeps several values in order, between [ ].
fruits = ["apple", "banana", "cherry", "mango"]
prices = [0.40, 0.25, 0.10, 1.20]

print(fruits)
print("Items:", len(fruits))
print("First:", fruits[0])
print("Last:", fruits[-1])

# A list can change: give a position a new value.
prices[3] = 0.99
print("A mango now costs", prices[3])

# for goes through the list, one item at a time.
for fruit in fruits:
    print("-", fruit)

# in checks whether a value is in the list.
print("Do we sell kiwis?", "kiwi" in fruits)

# sum(), min() and max() work on lists of numbers.
print("One of each costs", round(sum(prices), 2))
print("Cheapest:", min(prices), "| Dearest:", max(prices))
