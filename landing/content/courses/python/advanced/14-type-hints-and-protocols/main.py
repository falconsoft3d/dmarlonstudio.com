from typing import Protocol, runtime_checkable

type Euros = float                    # a type alias (Python 3.12)

@runtime_checkable
class Priced(Protocol):               # any class with price() fits
    def price(self) -> Euros: ...

class Book:                           # no inheritance from Priced needed
    def __init__(self, title: str, cost: Euros) -> None:
        self.title = title
        self.cost = cost

    def price(self) -> Euros:
        return self.cost

class Subscription:
    def __init__(self, months: int) -> None:
        self.months = months

    def price(self) -> Euros:
        return self.months * 7.99

def basket_total(items: list[Priced], vat: float = 0.04) -> Euros:
    return round(sum(item.price() for item in items) * (1 + vat), 2)

def first[T](items: list[T], default: T) -> T:    # a generic function
    return items[0] if items else default

basket: list[Priced] = [Book("Dune", 11.5), Subscription(3)]
print("Total:", basket_total(basket))
print("Is Priced:", isinstance(basket[1], Priced), isinstance("Dune", Priced))
print("First:", first(["INV-1", "INV-2"], "none"), "|", first([], 0))
print("Not enforced:", repr(Subscription("3").months))   # runs anyway
