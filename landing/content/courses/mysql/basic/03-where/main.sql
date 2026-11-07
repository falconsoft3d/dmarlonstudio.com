-- Products over 3 euros
SELECT name, price FROM products
WHERE price > 3
ORDER BY price DESC;

-- Out of stock
SELECT name, stock FROM products
WHERE stock = 0;

-- Customers from London (text goes in quotes)
SELECT name, email, city FROM customers
WHERE city = 'London'
ORDER BY name;

-- Every order that has not been shipped yet
SELECT id, customer_id, ordered, status, total
FROM orders
WHERE status <> 'shipped'
ORDER BY id;
