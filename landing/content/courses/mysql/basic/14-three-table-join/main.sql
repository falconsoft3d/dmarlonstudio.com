-- order_items -> products -> categories
SELECT cat.name AS category,
       COUNT(DISTINCT i.order_id) AS orders,
       SUM(i.qty) AS units,
       SUM(i.qty * i.price) AS revenue
FROM order_items i
JOIN products p ON p.id = i.product_id
JOIN categories cat ON cat.id = p.category_id
JOIN orders o ON o.id = i.order_id
WHERE o.status <> 'cancelled'
GROUP BY cat.name
ORDER BY revenue DESC;
