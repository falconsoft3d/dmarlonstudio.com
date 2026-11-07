-- Bakery products under 2 euros (AND: both must hold)
SELECT name, price FROM products
WHERE category_id = 1 AND price < 2
ORDER BY price;

-- Parentheses decide what OR joins
SELECT name, category_id, price FROM products
WHERE (category_id = 2 OR category_id = 4) AND price > 3
ORDER BY price;

-- IN for a list of values, BETWEEN for a range (both ends included)
SELECT id, ordered, status, total
FROM orders
WHERE status IN ('paid', 'new')
  AND ordered BETWEEN '2024-04-01' AND '2024-06-30'
ORDER BY ordered;
