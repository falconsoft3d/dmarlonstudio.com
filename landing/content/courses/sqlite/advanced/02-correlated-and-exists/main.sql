-- Correlated: the subquery runs again for every outer row (p)
SELECT p.name, p.category_id, p.price
FROM products AS p
WHERE p.price > (
  SELECT avg(x.price) FROM products AS x
  WHERE x.category_id = p.category_id
)
ORDER BY p.category_id;

-- EXISTS: is there at least one matching row?
SELECT c.name, c.city
FROM customers AS c
WHERE EXISTS (
  SELECT 1 FROM orders AS o
  WHERE o.customer_id = c.id AND o.total > 15
)
ORDER BY c.name;

-- NOT EXISTS: products without a single review
SELECT p.id, p.name
FROM products AS p
WHERE NOT EXISTS (SELECT 1 FROM reviews AS r WHERE r.product_id = p.id)
ORDER BY p.id;
