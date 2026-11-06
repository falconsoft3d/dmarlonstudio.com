from dataclasses import dataclass

class OutOfStock(Exception): pass     # our own error for this program

@dataclass
class Product:
    sku: str
    price: float
    stock: int = 0

class Inventory:
    def __init__(self, *products):
        self.products = {p.sku: p for p in products}
    def sell(self, sku, qty):
        product = self.products[sku]          # KeyError if the SKU is unknown
        if qty > product.stock:
            raise OutOfStock(f"only {product.stock} x {sku} left")
        product.stock -= qty
        return qty * product.price

    def value(self):
        return sum(p.price * p.stock for p in self.products.values())

shop = Inventory(Product("CHAIR", 49.5, 10), Product("TABLE", 230.0, 2))
assert shop.value() == 955.0                  # a test: stops here if False
assert shop.sell("CHAIR", 4) == 198.0
assert shop.products["CHAIR"].stock == 6, "stock was not updated"
try:
    shop.sell("TABLE", 5)
    assert False, "OutOfStock expected"
except OutOfStock as error:
    print("Expected error:", error)
print(shop.products["CHAIR"], "| value:", shop.value())
print("All tests passed")
