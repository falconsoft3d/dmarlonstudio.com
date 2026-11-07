-- WHERE filters rows before grouping; HAVING filters the groups
SELECT
  customer_id,
  count(*) AS orders,
  round(sum(total), 2) AS spent
FROM orders
WHERE status <> 'cancelled'
GROUP BY customer_id
HAVING count(*) >= 2
ORDER BY spent DESC;

-- Products with an average rating of 4 or more
SELECT product_id, count(*) AS reviews, avg(rating) AS avg_rating
FROM reviews
GROUP BY product_id
HAVING avg(rating) >= 4
ORDER BY avg_rating DESC, product_id;
