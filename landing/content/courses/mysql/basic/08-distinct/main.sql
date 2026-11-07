-- Every city, once
SELECT DISTINCT city FROM customers ORDER BY city;

-- DISTINCT works on the whole row
SELECT DISTINCT category_id, active FROM products
ORDER BY category_id, active;

-- Count the different values
SELECT COUNT(*) AS orders,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(DISTINCT status) AS statuses,
       COUNT(DISTINCT MONTH(ordered)) AS months
FROM orders;
