-- WITH names each step; the last SELECT reads them like tables
WITH sales AS (
  SELECT i.product_id, sum(i.qty) AS units, sum(i.qty * i.price) AS revenue
  FROM order_items i
  JOIN orders o ON o.id = i.order_id
  WHERE o.status <> 'cancelled'
  GROUP BY i.product_id
), ratings AS (
  SELECT product_id, round(avg(rating), 1) AS stars, count(*) AS reviews
  FROM reviews
  GROUP BY product_id
)
SELECT p.name, s.units, s.revenue, r.stars, r.reviews
FROM sales s
JOIN products p ON p.id = s.product_id
LEFT JOIN ratings r ON r.product_id = s.product_id
ORDER BY s.revenue DESC
LIMIT 5;

-- A data-modifying CTE: lower the prices and log them in one statement
CREATE TABLE price_log (product_id int, old_price numeric, new_price numeric);

WITH old AS (
  SELECT id, price FROM products WHERE stock >= 30
), changed AS (
  UPDATE products p SET price = round(p.price * 0.9, 2)
  FROM old WHERE p.id = old.id
  RETURNING p.id, old.price AS old_price, p.price AS new_price
)
INSERT INTO price_log SELECT * FROM changed
RETURNING product_id, old_price, new_price;
