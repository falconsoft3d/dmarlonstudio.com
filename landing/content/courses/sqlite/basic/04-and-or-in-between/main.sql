-- Both conditions must be true
SELECT name, price, stock
FROM products
WHERE price < 2 AND stock > 20
ORDER BY price;

-- A list of values: IN is shorter than several ORs
SELECT id, ordered, status
FROM orders
WHERE status IN ('paid', 'new')
ORDER BY id;

-- A range, both ends included; OR with parentheses
SELECT id, ordered, status, total
FROM orders
WHERE ordered BETWEEN '2024-04-01' AND '2024-05-31'
  AND (status = 'shipped' OR total > 20)
ORDER BY ordered;
