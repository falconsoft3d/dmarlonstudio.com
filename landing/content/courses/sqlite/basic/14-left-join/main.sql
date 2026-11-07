-- Customers who have never ordered: no matching row on the right
SELECT c.name, c.email
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- LEFT JOIN keeps every customer, with or without orders
SELECT c.name, c.city, count(o.id) AS orders,
       coalesce(round(sum(o.total), 2), 0) AS spent
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
GROUP BY c.id
ORDER BY spent DESC;
