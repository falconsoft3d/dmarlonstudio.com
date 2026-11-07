-- A subquery that returns one value
SELECT name, price FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

-- IN with a subquery: customers who have a cancelled order
SELECT name FROM customers
WHERE id IN (SELECT customer_id FROM orders WHERE status = 'cancelled');

-- EXISTS: is there at least one matching row?
SELECT c.name,
       c.city,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS orders
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.id AND o.status = 'shipped'
)
ORDER BY c.id;
