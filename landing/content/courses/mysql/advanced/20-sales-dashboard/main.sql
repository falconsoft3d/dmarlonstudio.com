-- The shop dashboard: one row per category
WITH sold AS (
  SELECT p.category_id, o.customer_id, o.id AS order_id,
         i.qty, i.qty * i.price AS amount
  FROM order_items i
  JOIN orders o ON o.id = i.order_id
  JOIN products p ON p.id = i.product_id
  WHERE o.status <> 'cancelled'
),
stars AS (
  SELECT p.category_id, AVG(r.rating) AS rating
  FROM reviews r JOIN products p ON p.id = r.product_id
  GROUP BY p.category_id
)
SELECT c.name AS category,
       COUNT(DISTINCT l.order_id) AS orders,
       COUNT(DISTINCT l.customer_id) AS customers,
       SUM(l.amount) AS revenue,
       CONCAT(ROUND(100 * SUM(l.amount) / SUM(SUM(l.amount)) OVER (), 1), '%') AS share,
       IFNULL(ROUND(s.rating, 1), '-') AS stars
FROM categories c
JOIN sold l ON l.category_id = c.id
LEFT JOIN stars s ON s.category_id = c.id
GROUP BY c.id, c.name, s.rating
ORDER BY revenue DESC;
