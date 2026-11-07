-- Running total: sum() OVER with ORDER BY adds row after row
SELECT id, ordered, total,
       sum(total) OVER (ORDER BY ordered) AS running,
       round(100 * total / sum(total) OVER (), 1) AS pct
FROM orders
WHERE status <> 'cancelled'
ORDER BY ordered
LIMIT 4;

-- A moving average of the last three orders, and a total per customer
SELECT id, customer_id AS customer, total,
       round(avg(total) OVER (ORDER BY ordered
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS avg_3,
       sum(total) OVER (PARTITION BY customer_id ORDER BY ordered) AS cust_running
FROM orders
WHERE status <> 'cancelled'
ORDER BY ordered;
