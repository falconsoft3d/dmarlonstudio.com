-- One row per month: orders, customers, revenue and the best product
WITH valid AS (
  SELECT o.*, substr(o.ordered, 1, 7) AS month
  FROM orders AS o
  WHERE o.status <> 'cancelled'
),
monthly AS (
  SELECT month, count(*) AS orders,
         count(DISTINCT customer_id) AS customers, sum(total) AS revenue
  FROM valid
  GROUP BY month
),
best AS (
  SELECT v.month, p.name,
         row_number() OVER (PARTITION BY v.month
           ORDER BY round(sum(i.qty * i.price), 2) DESC, p.name) AS pos
  FROM valid AS v
  JOIN order_items AS i ON i.order_id = v.id
  JOIN products AS p ON p.id = i.product_id
  GROUP BY v.month, p.id
)
SELECT
  m.month,
  m.orders,
  m.customers,
  round(m.revenue, 2) AS revenue,
  round(100.0 * (m.revenue - lag(m.revenue) OVER (ORDER BY m.month))
        / lag(m.revenue) OVER (ORDER BY m.month), 1) AS growth,
  b.name AS best_product
FROM monthly AS m
JOIN best AS b ON b.month = m.month AND b.pos = 1
ORDER BY m.month;
