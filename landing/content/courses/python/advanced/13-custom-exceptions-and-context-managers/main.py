from contextlib import contextmanager, suppress

class StockError(Exception): pass     # our own kind of error

class Transaction:                    # a context manager written as a class
    def __init__(self, stock):
        self.stock = stock
    def __enter__(self):
        self.backup = dict(self.stock)
        return self.stock
    def __exit__(self, exc_type, exc, tb):
        if exc_type is not None:      # something failed: undo everything
            self.stock.update(self.backup)
            print(f"  rolled back: {exc}")
        return exc_type is StockError     # True = error handled here

@contextmanager                       # the same idea with a generator
def section(title):
    print(f"[{title}]")
    yield
    print(f"[/{title}]")

def take(stock, product, qty):
    if stock[product] < qty:
        raise StockError(f"{product}: wanted {qty}, only {stock[product]} left")
    stock[product] -= qty

stock = {"pen": 10, "ink": 2}
with section("order 1"), Transaction(stock) as s:
    take(s, "pen", 3)
    take(s, "ink", 5)                 # fails: the pens come back too
with suppress(KeyError):              # ignore one specific error
    take(stock, "paper", 1)
print("Stock:", stock)
