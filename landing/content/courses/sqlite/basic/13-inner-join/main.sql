-- Each order with the name of its customer
SELECT o.id, o.ordered, c.name AS customer, c.city, o.total
FROM orders AS o
JOIN customers AS c ON c.id = o.customer_id
ORDER BY o.id;
