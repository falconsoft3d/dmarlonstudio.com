class Money:
    def __init__(self, cents, currency="EUR"):
        self.cents = cents
        self.currency = currency

    def __repr__(self):               # how it prints, also inside lists
        return f"{self.cents / 100:.2f} {self.currency}"

    def __eq__(self, other):          # ==
        return (self.cents, self.currency) == (other.cents, other.currency)

    def __lt__(self, other):          # < (and so sorted, min, max)
        return self.cents < other.cents

    def __add__(self, other):         # +
        if self.currency != other.currency:
            raise ValueError("cannot add different currencies")
        return Money(self.cents + other.cents, self.currency)

class Cart:
    def __init__(self, *prices):
        self.prices = list(prices)
    def __len__(self):                # len(cart)
        return len(self.prices)

cart = Cart(Money(1999), Money(450), Money(12000))
print("Items:", len(cart), cart.prices)
print("Total:", sum(cart.prices, Money(0)))
print("Sorted:", sorted(cart.prices))
print("Equal:", Money(450) == Money(450), "| less:", Money(450) < Money(1999))
try:
    Money(100) + Money(100, "USD")
except ValueError as error:
    print("Error:", error)
