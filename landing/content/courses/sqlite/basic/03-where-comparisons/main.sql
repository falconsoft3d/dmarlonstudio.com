-- One customer, by its key
SELECT * FROM customers WHERE id = 4;

-- Everything except one city
SELECT name, city FROM customers WHERE city <> 'Madrid' ORDER BY id;

-- Products that cost 3 euros or more
SELECT name, price
FROM products
WHERE price >= 3
ORDER BY price DESC;
