# Several parameters; the last one has a default value.
def order_total(price, quantity, discount=0):
    total = price * quantity
    return total - total * discount / 100

print(order_total(4.0, 3))                     # no discount
print(order_total(4.0, 3, 25))                 # 25 % off
print(order_total(quantity=2, price=10.0, discount=10))  # by name

# return can give back several values at once (a tuple).
def summary(marks):
    average = sum(marks) / len(marks)
    return min(marks), max(marks), round(average, 1)

low, high, avg = summary([6, 9, 7, 10, 8])
print(f"Lowest {low}, highest {high}, average {avg}")

# return also ends the function straight away.
def grade(mark):
    if mark >= 9:
        return "Outstanding"
    if mark >= 5:
        return "Pass"
    return "Keep trying"

for mark in [9.5, 7.2, 5.0, 3.8]:
    print(mark, "->", grade(mark))

# A function without return gives back None.
def cheer(name):
    print("Well done,", name)

print(cheer("Lola"))
