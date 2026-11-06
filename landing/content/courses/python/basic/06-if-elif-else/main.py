# The program decides what to wear from the temperature.
temperature = 12

if temperature >= 25:
    print("It is hot: wear a T-shirt.")
elif temperature >= 15:
    print("It is mild: a light jacket will do.")
elif temperature >= 5:
    print("It is cool: take a coat.")
else:
    print("It is freezing: coat, scarf and gloves!")

# Without elif or else: the block runs only if it is true.
raining = True
if raining:
    print("And take an umbrella.")

# if ... else chooses between exactly two paths.
basket = 42.80
if basket >= 50:
    print("Free delivery!")
else:
    print(f"Add {50 - basket:.2f} euros more for free delivery.")

print("Have a nice day.")  # not indented: it always runs
