-- Most expensive first; ties broken by name
SELECT name, category_id, price FROM products
ORDER BY price DESC, name
LIMIT 3;

-- Sort by two columns: category, then cheapest inside each
SELECT category_id, name, price FROM products
ORDER BY category_id, price;

-- Page 2 of 4 products per page: skip 4, take 4
SELECT id, name, price FROM products
ORDER BY id
LIMIT 4 OFFSET 4;
