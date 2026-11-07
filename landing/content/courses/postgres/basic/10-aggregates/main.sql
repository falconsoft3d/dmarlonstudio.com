-- One row that sums up the whole table
SELECT count(*) AS orders,
       sum(total) AS revenue,
       round(avg(total), 2) AS average,
       min(total) AS smallest,
       max(total) AS largest
FROM orders;

-- count(column) skips NULL
SELECT count(*) AS customers, count(email) AS with_email
FROM customers;

-- Aggregates of the order lines, without the cancelled order
SELECT count(*) AS lines,
       sum(qty) AS units,
       sum(qty * price) AS amount,
       min(ordered) AS first_day,
       max(ordered) AS last_day
FROM order_items i
JOIN orders o ON o.id = i.order_id
WHERE o.status <> 'cancelled';
