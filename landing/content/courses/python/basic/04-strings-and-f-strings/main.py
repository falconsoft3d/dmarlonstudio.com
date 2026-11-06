# Strings are text between quotes, single or double.
first = "Ada"
last = 'Lovelace'

# + joins strings and * repeats them.
full = first + " " + last
print(full)
print("=" * 20)

# len() counts the characters.
print("Characters in the name:", len(full))

# Each character has a position, starting at 0.
print("Initials:", first[0] + last[0])
print("Last letter:", last[-1])

# str() turns a number into text so it can be joined.
score = 92
print(first + " scored " + str(score) + " points.")

# An f-string puts values straight into the text with { }.
print(f"{first} scored {score} points.")
print(f"Next year she wants {score + 5}.")

# After a colon you can format: decimals, width, alignment.
average = 87.456
print(f"Class average: {average:.2f}")
print(f"[{first:>8}] [{last:<10}]")
