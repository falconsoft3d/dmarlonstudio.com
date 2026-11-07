-- Every city, once
SELECT DISTINCT city FROM customers ORDER BY city;

-- How many different products have ever been sold
SELECT count(*) AS lines, count(DISTINCT product_id) AS products
FROM order_items;

-- DISTINCT works on the whole row: each (city, year) pair once
SELECT DISTINCT city, substr(joined, 1, 4) AS year
FROM customers
ORDER BY city, year;
