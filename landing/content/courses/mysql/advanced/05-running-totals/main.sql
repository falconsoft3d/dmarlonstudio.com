-- Revenue day by day and accumulated
SELECT id,
       ordered,
       total,
       SUM(total) OVER (ORDER BY ordered) AS running,
       ROUND(AVG(total) OVER (ORDER BY ordered
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS avg_last_3,
       ROUND(100 * total / SUM(total) OVER (), 1) AS pct
FROM orders
WHERE status <> 'cancelled'
ORDER BY ordered;
