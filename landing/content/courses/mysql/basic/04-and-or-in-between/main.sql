-- Cheap AND in stock
SELECT name, price, stock FROM products
WHERE price < 2 AND stock > 0
ORDER BY price;

-- Customers from Madrid OR Seville, the same as IN
SELECT name, city FROM customers
WHERE city IN ('Madrid', 'Seville')
ORDER BY city, name;

-- Orders of spring 2024 that were paid or shipped
SELECT id, ordered, status, total
FROM orders
WHERE ordered BETWEEN '2024-04-01' AND '2024-05-31'
  AND (status = 'paid' OR status = 'shipped')
ORDER BY ordered;
