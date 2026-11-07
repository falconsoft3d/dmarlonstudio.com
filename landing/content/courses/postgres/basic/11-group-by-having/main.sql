-- Orders and revenue per status
SELECT status, count(*) AS orders, sum(total) AS revenue
FROM orders
GROUP BY status
ORDER BY revenue DESC, status;

-- Products and average price per category
SELECT category_id,
       count(*) AS products,
       round(avg(price), 2) AS avg_price,
       sum(stock) AS stock
FROM products
GROUP BY category_id
ORDER BY category_id;

-- HAVING filters groups: customers with more than one order
SELECT customer_id, count(*) AS orders, sum(total) AS spent
FROM orders
GROUP BY customer_id
HAVING count(*) > 1
ORDER BY spent DESC;
