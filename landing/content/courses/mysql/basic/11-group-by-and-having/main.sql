-- One row per category
SELECT category_id,
       COUNT(*) AS products,
       SUM(stock) AS units,
       ROUND(AVG(price), 2) AS avg_price
FROM products
GROUP BY category_id
ORDER BY category_id;

-- HAVING filters the groups (WHERE filters the rows)
SELECT customer_id,
       COUNT(*) AS orders,
       SUM(total) AS spent
FROM orders
WHERE status <> 'cancelled'
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY spent DESC;
