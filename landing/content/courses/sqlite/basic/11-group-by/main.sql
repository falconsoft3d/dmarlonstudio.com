-- One row per status
SELECT status, count(*) AS orders, round(sum(total), 2) AS revenue
FROM orders
GROUP BY status
ORDER BY revenue DESC;

-- One row per category
SELECT
  category_id,
  count(*) AS products,
  sum(stock) AS units,
  min(price) AS cheapest,
  round(avg(price), 2) AS avg_price
FROM products
GROUP BY category_id
ORDER BY category_id;
