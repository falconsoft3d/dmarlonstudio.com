-- The three most expensive products
SELECT name, price FROM products ORDER BY price DESC LIMIT 3;

-- Several keys: category first, then the dearest inside each one
SELECT category_id, name, price
FROM products
ORDER BY category_id, price DESC
LIMIT 4 OFFSET 4;
