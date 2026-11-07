-- A running total: the sum of this row and all the previous ones
SELECT
  id,
  ordered,
  total,
  round(sum(total) OVER (ORDER BY ordered, id), 2) AS running,
  round(avg(total) OVER (
    ORDER BY ordered, id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS avg_last_3,
  round(100 * total / sum(total) OVER (), 1) AS pct
FROM orders
WHERE status <> 'cancelled'
ORDER BY ordered, id;
