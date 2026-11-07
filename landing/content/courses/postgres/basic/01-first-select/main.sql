-- The four categories of the shop
SELECT * FROM categories ORDER BY id;

-- Every product: name, price and stock, cheapest first
SELECT name, price, stock
FROM products
ORDER BY price;
