-- WITH names a query and uses it like a table
WITH sales AS (
  SELECT i.product_id,
         SUM(i.qty) AS units,
         SUM(i.qty * i.price) AS revenue
  FROM order_items i
  JOIN orders o ON o.id = i.order_id
  WHERE o.status <> 'cancelled'
  GROUP BY i.product_id
),
top_sellers AS (
  SELECT product_id, units, revenue
  FROM sales
  WHERE revenue >= 5
)
SELECT p.name, c.name AS category, r.units, r.revenue
FROM top_sellers r
JOIN products p ON p.id = r.product_id
JOIN categories c ON c.id = p.category_id
ORDER BY r.revenue DESC;
