-- LATERAL: a subquery that can use the columns of the rows before it.
-- The two best-selling products of each category (top-N per group)
SELECT c.name AS category, top.name, top.units, top.revenue
FROM categories c
CROSS JOIN LATERAL (
  SELECT p.name, sum(i.qty) AS units, sum(i.qty * i.price) AS revenue
  FROM products p
  JOIN order_items i ON i.product_id = p.id
  JOIN orders o ON o.id = i.order_id AND o.status <> 'cancelled'
  WHERE p.category_id = c.id
  GROUP BY p.id
  ORDER BY revenue DESC
  LIMIT 2
) AS top
ORDER BY c.name, top.revenue DESC;

-- LEFT JOIN LATERAL ... ON true keeps the rows without a match:
-- the last order of each customer
SELECT cu.name, last.id AS order_id, last.ordered, last.total
FROM customers cu
LEFT JOIN LATERAL (
  SELECT o.id, o.ordered, o.total
  FROM orders o
  WHERE o.customer_id = cu.id
  ORDER BY o.ordered DESC
  LIMIT 1
) AS last ON true
ORDER BY cu.id;
