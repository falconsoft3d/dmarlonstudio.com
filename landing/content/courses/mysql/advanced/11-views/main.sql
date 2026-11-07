-- A view is a saved query that reads like a table
CREATE VIEW product_sales AS
SELECT p.id,
       p.name,
       c.name AS category,
       COALESCE(SUM(i.qty), 0) AS units,
       COALESCE(SUM(i.qty * i.price), 0) AS revenue
FROM products p
JOIN categories c ON c.id = p.category_id
LEFT JOIN order_items i ON i.product_id = p.id
GROUP BY p.id, p.name, c.name;

-- It always shows the current data
UPDATE order_items SET qty = qty + 10 WHERE product_id = 5;

SELECT category, name, units, revenue
FROM product_sales
WHERE revenue > 10
ORDER BY revenue DESC;
