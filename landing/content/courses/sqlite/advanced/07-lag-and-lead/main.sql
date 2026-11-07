-- LAG looks at the previous row, LEAD at the next one
SELECT
  customer_id AS cust,
  id,
  ordered,
  total,
  lag(total) OVER w AS prev_total,
  round(total - lag(total) OVER w, 2) AS change
FROM orders
WHERE customer_id IN (1, 2)
WINDOW w AS (PARTITION BY customer_id ORDER BY ordered)
ORDER BY cust, ordered;

-- Days until the next order of the shop
SELECT
  id,
  ordered,
  lead(ordered) OVER (ORDER BY ordered) AS next_order,
  julianday(lead(ordered) OVER (ORDER BY ordered)) - julianday(ordered) AS days
FROM orders
ORDER BY ordered;
