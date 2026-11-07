-- Pieces of a date
SELECT id,
       ordered,
       DATE_FORMAT(ordered, '%d/%m/%Y') AS es_date,
       DAYNAME(ordered) AS weekday,
       DATEDIFF('2024-06-30', ordered) AS days_ago,
       DATE_ADD(ordered, INTERVAL 3 DAY) AS deliver_by
FROM orders
WHERE customer_id IN (1, 2)
ORDER BY ordered;

-- Orders per month
SELECT MONTH(ordered) AS month,
       DATE_FORMAT(ordered, '%M %Y') AS name,
       COUNT(*) AS orders,
       SUM(total) AS total
FROM orders
GROUP BY month, name
ORDER BY month;
