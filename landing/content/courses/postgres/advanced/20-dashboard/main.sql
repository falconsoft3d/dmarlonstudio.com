-- The shop dashboard: one row per month, built from several CTEs
WITH sales AS (
  SELECT date_trunc('month', o.ordered)::date AS month, o.id, o.total,
         i.product_id, i.qty * i.price AS amount
  FROM orders o
  JOIN order_items i ON i.order_id = o.id
  WHERE o.status <> 'cancelled'
), monthly AS (
  SELECT month, count(DISTINCT id) AS orders, sum(amount) AS revenue
  FROM sales
  GROUP BY month
), best AS (
  SELECT DISTINCT ON (month) month, p.name AS top_product
  FROM sales s JOIN products p ON p.id = s.product_id
  GROUP BY month, p.name
  ORDER BY month, sum(amount) DESC, p.name
)
SELECT to_char(m.month, 'Mon YYYY') AS month,
       m.orders,
       m.revenue,
       round(m.revenue / m.orders, 2) AS avg_ticket,
       coalesce(round(100 * (m.revenue / lag(m.revenue) OVER w - 1)) || '%', '-') AS growth,
       b.top_product
FROM monthly m
JOIN best b USING (month)
WINDOW w AS (ORDER BY m.month)
ORDER BY m.month;
