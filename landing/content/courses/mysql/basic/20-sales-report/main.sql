-- Sales by customer: who buys, how much and what
SELECT c.name AS customer,
       c.city,
       COUNT(DISTINCT o.id) AS orders,
       SUM(i.qty) AS units,
       SUM(i.qty * i.price) AS spent,
       MAX(o.ordered) AS last_order
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items i ON i.order_id = o.id
WHERE o.status <> 'cancelled'
GROUP BY c.id, c.name, c.city
HAVING spent > 10
ORDER BY spent DESC;
