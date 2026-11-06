# A variable is a name that points to a value.
product = "Coffee mug"
price = 7.5
stock = 12
on_sale = True

print("Product:", product)
print("Price:", price)
print("In stock:", stock)
print("On sale:", on_sale)

# type() tells you what kind of value a variable holds.
print(type(product))
print(type(price))
print(type(stock))
print(type(on_sale))

# A variable can change: just give it a new value.
stock = stock - 3
print("Stock after selling 3:", stock)
