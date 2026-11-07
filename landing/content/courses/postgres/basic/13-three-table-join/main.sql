-- The lines of one order: orders -> order_items -> products
SELECT o.id AS order_id, p.name, i.qty, i.price, i.qty * i.price AS amount
FROM orders o
JOIN order_items i ON i.order_id = o.id
JOIN products p ON p.id = i.product_id
WHERE o.id = 6
ORDER BY amount DESC;

-- Units sold per category: four tables, one GROUP BY
SELECT c.name AS category,
       count(DISTINCT o.id) AS orders,
       sum(i.qty) AS units,
       sum(i.qty * i.price) AS revenue
FROM order_items i
JOIN orders o ON o.id = i.order_id
JOIN products p ON p.id = i.product_id
JOIN categories c ON c.id = p.category_id
WHERE o.status <> 'cancelled'
GROUP BY c.name
ORDER BY revenue DESC;
