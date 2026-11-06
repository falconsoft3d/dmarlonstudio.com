# def creates a function: a named block of code you can reuse.
def welcome():
    print("Welcome to the Python Cafe!")
    print("-" * 27)

welcome()

# A function can receive a value (a parameter)...
def serve(drink):
    print(f"One {drink}, coming right up.")

serve("latte")
serve("hot chocolate")

# ...and give back a result with return.
def with_vat(price):
    return price * 1.21

print(f"A 2.50 tea costs {with_vat(2.50):.2f} with VAT.")

# The result can be stored and used like any other value.
total = with_vat(3.00) + with_vat(1.80)
print(f"Coffee and a croissant: {total:.2f}")

# A function can call other functions.
def receipt_line(drink, price):
    print(f"{drink:<14}{with_vat(price):>6.2f}")

receipt_line("Cappuccino", 2.80)
receipt_line("Orange juice", 3.20)
