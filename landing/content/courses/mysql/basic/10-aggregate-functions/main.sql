-- One row that sums up the whole table
SELECT COUNT(*) AS products,
       SUM(stock) AS units,
       MIN(price) AS cheapest,
       MAX(price) AS dearest,
       ROUND(AVG(price), 2) AS avg_price
FROM products;

-- Aggregates also work on the filtered rows
SELECT COUNT(*) AS orders,
       SUM(total) AS revenue,
       ROUND(AVG(total), 2) AS avg_ticket,
       MIN(ordered) AS first,
       MAX(ordered) AS last
FROM orders
WHERE status <> 'cancelled';
