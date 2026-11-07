-- Several sort keys: category first, then the most expensive
SELECT category_id, name, price
FROM products
ORDER BY category_id, price DESC
LIMIT 6;

-- The second page of three: OFFSET skips rows
SELECT name, price FROM products ORDER BY price LIMIT 3 OFFSET 3;

-- DESC puts NULL first; NULLS LAST sends it to the end
SELECT name, email FROM customers ORDER BY email DESC LIMIT 2;
SELECT name, email FROM customers ORDER BY email DESC NULLS LAST LIMIT 2;

-- FETCH FIRST ... WITH TIES keeps the rows that tie with the last one
SELECT name, stock
FROM products
ORDER BY stock
FETCH FIRST 1 ROWS WITH TIES;
