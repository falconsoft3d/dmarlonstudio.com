-- The cities of the customers, each one once
SELECT DISTINCT city FROM customers ORDER BY city;

-- How many different cities and statuses there are
SELECT count(DISTINCT city) AS cities,
       (SELECT count(DISTINCT status) FROM orders) AS statuses
FROM customers;

-- DISTINCT ON: one row per category, the first one of ORDER BY
-- (here, the cheapest product of each category)
SELECT DISTINCT ON (category_id)
       category_id, name, price
FROM products
ORDER BY category_id, price;
