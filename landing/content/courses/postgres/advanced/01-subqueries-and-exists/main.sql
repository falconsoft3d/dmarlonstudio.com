-- A scalar subquery: products above the average price
SELECT name, price, (SELECT round(avg(price), 2) FROM products) AS average
FROM products
WHERE price > (SELECT avg(price) FROM products)
ORDER BY price DESC;

-- IN with a subquery: who has bought espresso beans
SELECT name FROM customers
WHERE id IN (SELECT o.customer_id
             FROM orders o JOIN order_items i ON i.order_id = o.id
             WHERE i.product_id = 4)
ORDER BY name;

-- NOT EXISTS: active products nobody has reviewed yet
SELECT p.name, p.stock
FROM products p
WHERE p.active
  AND NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
ORDER BY p.name;

-- A correlated subquery in the SELECT list
SELECT c.name,
       (SELECT count(*) FROM orders o WHERE o.customer_id = c.id) AS orders,
       (SELECT max(o.total) FROM orders o WHERE o.customer_id = c.id) AS biggest
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.customer_id = c.id AND o.status = 'shipped')
ORDER BY c.name;
