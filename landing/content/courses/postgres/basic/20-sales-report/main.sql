-- Sales per customer: orders, units, revenue and last order
-- (cancelled orders do not count)
SELECT c.name AS customer,
       c.city,
       count(DISTINCT o.id) AS orders,
       sum(i.qty) AS units,
       to_char(sum(i.qty * i.price), 'FM990.00') AS revenue,
       max(o.ordered) AS last_order
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items i ON i.order_id = o.id
WHERE o.status <> 'cancelled'
GROUP BY c.id, c.name, c.city
HAVING sum(i.qty * i.price) > 12
ORDER BY sum(i.qty * i.price) DESC;
