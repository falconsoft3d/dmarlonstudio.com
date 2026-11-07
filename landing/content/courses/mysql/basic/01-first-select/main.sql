-- The four categories of the shop
SELECT * FROM categories
ORDER BY id;

-- Every product: only the columns we need, in id order
SELECT id, name, price, stock
FROM products
ORDER BY id;
