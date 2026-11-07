-- A view is a saved query that you use like a table
CREATE VIEW order_summary AS
SELECT
  o.id,
  o.ordered,
  c.name AS customer,
  o.status,
  count(i.id) AS lines,
  o.total
FROM orders AS o
JOIN customers AS c ON c.id = o.customer_id
LEFT JOIN order_items AS i ON i.order_id = o.id
GROUP BY o.id;

-- The view always reads the current data
UPDATE orders SET status = 'shipped' WHERE id = 9;

SELECT customer, count(*) AS orders, sum(lines) AS lines
FROM order_summary
GROUP BY customer
HAVING orders > 1
ORDER BY customer;

SELECT * FROM order_summary
WHERE status = 'shipped'
ORDER BY ordered;
