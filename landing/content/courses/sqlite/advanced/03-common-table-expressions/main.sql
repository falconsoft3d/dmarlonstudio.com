-- WITH names intermediate results, read from top to bottom
WITH
valid AS (
  SELECT * FROM orders WHERE status <> 'cancelled'
),
per_customer AS (
  SELECT customer_id, count(*) AS orders, sum(total) AS spent
  FROM valid
  GROUP BY customer_id
),
overall AS (
  SELECT avg(spent) AS avg_spent FROM per_customer
)
SELECT
  c.name,
  pc.orders,
  round(pc.spent, 2) AS spent,
  round(pc.spent - o.avg_spent, 2) AS vs_avg
FROM per_customer AS pc
JOIN customers AS c ON c.id = pc.customer_id
CROSS JOIN overall AS o
ORDER BY pc.spent DESC;
