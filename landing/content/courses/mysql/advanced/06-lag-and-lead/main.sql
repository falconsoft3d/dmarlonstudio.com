-- Each order next to the previous and the next one of the same customer
SELECT customer_id,
       id,
       ordered,
       LAG(ordered) OVER w AS previous,
       DATEDIFF(ordered, LAG(ordered) OVER w) AS days_between,
       LEAD(total, 1, 0) OVER w AS next_total
FROM orders
WHERE customer_id IN (1, 2)
WINDOW w AS (PARTITION BY customer_id ORDER BY ordered)
ORDER BY customer_id, ordered;
