-- All the columns of a small table
SELECT * FROM categories;

-- Only the columns you need, in the order you want
SELECT name, price, stock
FROM products
ORDER BY id;
