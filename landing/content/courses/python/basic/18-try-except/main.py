# int() fails with text that is not a number: try catches it.
answers = ["42", "seven", "3.5", "15"]
total = 0

for text in answers:
    try:
        number = int(text)
        total += number
        print(f"'{text}' -> {number}")
    except ValueError:
        print(f"'{text}' is not a whole number, skipped")
print("Total:", total)

# Different errors, different except blocks.
def slices_each(pizzas, people):
    try:
        slices = pizzas * 8 // people
    except ZeroDivisionError:
        print("Nobody to share with!")
    except TypeError:
        print("People must be a number.")
    else:  # runs only if there was no error
        print(f"{people} people get {slices} slices each")

slices_each(3, 4)
slices_each(3, 0)
slices_each(3, "four")

# as gives you the error itself, with its message.
prices = {"tea": 1.5, "coffee": 1.8}
try:
    print(prices["juice"])
except KeyError as error:
    print("No price for", error)
