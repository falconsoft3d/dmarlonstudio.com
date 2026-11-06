# for repeats a block once for each item of a sequence.
for letter in "PYTHON":
    print(letter, end=" ")    # end=" " stays on the same line
print()

# range(1, 6) gives 1, 2, 3, 4, 5 (the end is not included).
number = 7
for i in range(1, 6):
    print(f"{number} x {i} = {number * i}")

# range(start, stop, step): the Summer Olympics, every 4 years.
for year in range(2024, 2036, 4):
    print("Olympic year:", year)

# Add up as you go.
total = 0
for n in range(1, 101):
    total += n
print("1 + 2 + ... + 100 =", total)

# break leaves the loop as soon as it finds what it wants.
for n in range(1, 100):
    if n % 6 == 0 and n % 8 == 0:
        print("First number divisible by 6 and 8:", n)
        break
