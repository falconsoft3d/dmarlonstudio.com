-- A scalar subquery returns one value: the average price
SELECT round(avg(price), 2) AS avg_price FROM products;

-- Products dearer than the average
SELECT name, price
FROM products
WHERE price > (SELECT avg(price) FROM products)
ORDER BY price DESC;

-- IN with a subquery: customers who have bought coffee (product 4)
SELECT name, city FROM customers
WHERE id IN (
  SELECT o.customer_id FROM orders AS o
  JOIN order_items AS i ON i.order_id = o.id
  WHERE i.product_id = 4
)
ORDER BY name;

-- A subquery in FROM is a temporary table: units sold per product
SELECT p.name, sold.units, sold.lines
FROM (
  SELECT product_id, sum(qty) AS units, count(*) AS lines
  FROM order_items
  GROUP BY product_id
) AS sold
JOIN products AS p ON p.id = sold.product_id
WHERE sold.units >= 4
ORDER BY sold.units DESC, p.name;
