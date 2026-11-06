def make_discount(rate):
    """Returns a function that remembers rate."""
    def apply(price):
        return round(price * (1 - rate), 2)
    return apply


def make_ticket_dispenser(prefix):
    """Each call hands out the next ticket number."""
    number = 0

    def next_ticket():
        nonlocal number            # change the outer variable
        number += 1
        return f"{prefix}-{number:03d}"
    return next_ticket


sales = make_discount(0.20)
members = make_discount(0.35)
print("Sales price:", sales(50.0))
print("Members price:", members(50.0))

bakery = make_ticket_dispenser("B")
butcher = make_ticket_dispenser("M")
print(bakery(), bakery(), bakery())
print(butcher(), butcher())
print("Next bakery ticket:", bakery())

# The remembered values live in the closure cells
print("Captured rate:", sales.__closure__[0].cell_contents)
