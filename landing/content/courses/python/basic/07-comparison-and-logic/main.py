# Comparisons give True or False.
age = 16
height = 1.42
has_ticket = True

print("age == 16:", age == 16)
print("age != 18:", age != 18)
print("age >= 18:", age >= 18)
print("height < 1.40:", height < 1.40)

# and: both must be true. or: at least one. not: the opposite.
can_ride = height >= 1.40 and has_ticket
print("Can ride the roller coaster:", can_ride)

weekend = False
holiday = True
print("Park is open:", weekend or holiday)
print("Park is closed:", not (weekend or holiday))

# Python lets you chain comparisons.
print("Teenager:", 13 <= age <= 19)

# Text can be compared too (letter by letter).
print("Same name:", "Ana" == "ana")

if age < 18 and not has_ticket:
    print("Ask an adult to buy you a ticket.")
elif age < 18:
    print("Enjoy the park, and stay with your group!")
else:
    print("Enjoy the park!")
