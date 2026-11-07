-- Sales by category: only orders that are not cancelled
SELECT
  c.name AS category,
  count(DISTINCT i.order_id) AS orders,
  sum(i.qty) AS units,
  round(sum(i.qty * i.price), 2) AS revenue,
  round(100.0 * sum(i.qty * i.price) / (
    SELECT sum(total) FROM orders WHERE status <> 'cancelled'
  ), 1) AS pct
FROM order_items AS i
JOIN orders AS o ON o.id = i.order_id
JOIN products AS p ON p.id = i.product_id
JOIN categories AS c ON c.id = p.category_id
WHERE o.status <> 'cancelled'
GROUP BY c.id
ORDER BY revenue DESC;
