from itertools import accumulate, chain, combinations, groupby, islice, count
from functools import lru_cache, partial, reduce

daily_sales = [120, 80, 150, 95, 200]
print("Running total:", list(accumulate(daily_sales)))

menu = ["soup", "salad", "pasta", "steak"]
pairs = list(combinations(menu, 2))   # every pair, no repeats
print(len(pairs), "combos, e.g.", pairs[:3])

print("All orders:", list(chain(["#101", "#102"], ["#103"])))
tickets = (f"T{n}" for n in count(500, 5))          # endless counter
print("Next tickets:", list(islice(tickets, 4)))    # take only 4

log = ["ERROR", "ERROR", "INFO", "WARN", "WARN", "WARN", "INFO"]
runs = [(level, len(list(group))) for level, group in groupby(log)]
print("Runs:", runs)                  # groupby joins neighbours only

discounts = [0.9, 0.95, 0.8]          # 10%, then 5%, then 20% off
print("Combined factor:", round(reduce(lambda a, b: a * b, discounts), 3))

def price_with_tax(price, rate):
    return round(price * (1 + rate), 2)

spain = partial(price_with_tax, rate=0.21)      # fix one argument
print("With Spanish VAT:", [spain(p) for p in [19.99, 5.5, 30.0]])

@lru_cache(maxsize=None)
def shipping_quote(zone):
    print(f"  (calculating {zone})")  # only runs the first time
    return {"EU": 5.0, "US": 12.0}[zone]

print("Quotes:", shipping_quote("EU"), shipping_quote("EU"), shipping_quote("US"))
print("Cache:", shipping_quote.cache_info())
