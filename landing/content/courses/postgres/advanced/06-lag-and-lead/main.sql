-- LAG looks at the previous row, LEAD at the next one
SELECT id, ordered, total,
       lag(total) OVER w AS previous,
       total - lag(total) OVER w AS change,
       lead(ordered) OVER w AS next_order
FROM orders
WHERE customer_id IN (1, 2)
WINDOW w AS (PARTITION BY customer_id ORDER BY ordered)
ORDER BY customer_id, ordered;

-- Revenue per month compared with the month before
WITH monthly AS (
  SELECT date_trunc('month', ordered)::date AS month, sum(total) AS revenue
  FROM orders
  WHERE status <> 'cancelled'
  GROUP BY 1
)
SELECT month, revenue,
       lag(revenue) OVER (ORDER BY month) AS before,
       round(100 * (revenue / lag(revenue) OVER (ORDER BY month) - 1), 1) AS growth_pct,
       first_value(revenue) OVER (ORDER BY month) AS first_month
FROM monthly
ORDER BY month;
