-- Each order with the name of its customer
SELECT o.id,
       o.ordered,
       c.name AS customer,
       c.city,
       o.total
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'shipped'
ORDER BY o.id;

-- Products with their category name
SELECT p.name, cat.name AS category, p.price
FROM products p
INNER JOIN categories cat ON cat.id = p.category_id
WHERE p.price >= 3
ORDER BY category, p.price DESC;
