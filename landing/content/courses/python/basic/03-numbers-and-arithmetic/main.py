# Pizza night with friends: let Python do the maths.
slices = 3 * 8        # three pizzas, eight slices each
friends = 5

print("Total slices:", slices)
print("Each one (exact):", slices / friends)
print("Each one (whole):", slices // friends)
print("Slices left over:", slices % friends)

# Numbers with a decimal point are floats.
pizza_price = 12.99
bill = pizza_price * 3
print("Bill:", bill)
print("Rounded to euros:", round(bill))
print("Per person:", round(bill / friends, 2))

# ** raises to a power: area of a 30 cm and a 40 cm pizza.
medium = 3.1416 * 15 ** 2
large = 3.1416 * 20 ** 2
print("Medium area:", round(medium), "cm2")
print("Large area:", round(large), "cm2")

# Parentheses decide what is worked out first.
print(2 + 3 * 4, (2 + 3) * 4)
