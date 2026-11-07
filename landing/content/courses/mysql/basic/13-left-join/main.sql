-- Every customer, with or without orders
SELECT c.name, COUNT(o.id) AS orders, IFNULL(SUM(o.total), 0) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY spent DESC;

-- Products nobody has ever ordered
SELECT p.id, p.name
FROM products p
LEFT JOIN order_items i ON i.product_id = p.id
WHERE i.id IS NULL;

-- Products and their reviews (NULL when there are none)
SELECT p.name, COUNT(r.id) AS reviews, ROUND(AVG(r.rating), 1) AS stars
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
GROUP BY p.id, p.name
ORDER BY reviews DESC, p.name
LIMIT 8;
