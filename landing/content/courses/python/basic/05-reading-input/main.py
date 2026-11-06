# input() shows a message and waits for a line from the keyboard.
name = input("What is your name? ")
print(f"Nice to meet you, {name}!")

# input() always returns text: convert it to do maths.
age = int(input("How old are you? "))
print(f"In 10 years you will be {age + 10}.")

# float() converts text with a decimal point.
height = float(input("How tall are you, in metres? "))
print(f"That is {height * 100:.0f} centimetres.")

# Two numbers for a quick bill.
price = float(input("Price of a cinema ticket? "))
tickets = int(input("How many tickets? "))
print(f"{tickets} tickets cost {price * tickets:.2f} euros.")
