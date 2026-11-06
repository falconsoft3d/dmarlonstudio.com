# A tuple is like a list that cannot change. It uses ( ).
point = (3, 7)
print("Point:", point)
print("x =", point[0], "| y =", point[1])

# Unpacking: give each value its own name in one line.
x, y = point
print(f"One step right: ({x + 1}, {y})")

# Tuples suit fixed records: name, altitude, population.
city = ("Madrid", 667, 3.3)
name, altitude, population = city
print(f"{name}: {altitude} m high, {population} million people")

# Swap two variables without a spare one.
left, right = "rock", "paper"
left, right = right, left
print("left =", left, "| right =", right)

# A list of tuples, unpacked right in the for loop.
podium = [("gold", "Ana"), ("silver", "Ben"), ("bronze", "Chloe")]
for medal, runner in podium:
    print(f"{medal:>6}: {runner}")

# A function such as divmod() can return a tuple.
minutes, seconds = divmod(200, 60)
print(f"200 seconds = {minutes} min {seconds} s")
