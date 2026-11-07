-- Products under 2 euros
SELECT name, price FROM products WHERE price < 2 ORDER BY price;

-- Out of stock
SELECT name, stock FROM products WHERE stock = 0 ORDER BY name;

-- A boolean column works as a condition on its own
SELECT name, active FROM products WHERE NOT active;

-- Orders that are not shipped yet
SELECT id, customer_id, ordered, status, total
FROM orders
WHERE status <> 'shipped'
ORDER BY ordered;
