-- INNER JOIN: each product with the name of its category
SELECT p.name, c.name AS category, p.price
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.price > 4
ORDER BY p.price DESC;

-- LEFT JOIN keeps the customers without orders (with NULL)
SELECT c.name, c.city, o.id AS order_id, o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- Orders per customer, zero included
SELECT c.name, count(o.id) AS orders, coalesce(sum(o.total), 0) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY spent DESC, c.name;
