-- The order lines reference the orders: delete the lines first
DELETE FROM order_items
WHERE order_id IN (SELECT id FROM orders WHERE status = 'cancelled')
RETURNING id, order_id, product_id, qty;

DELETE FROM orders WHERE status = 'cancelled'
RETURNING id, status, total;

-- DELETE ... USING: the reviews of products that cost under 2 euros
DELETE FROM reviews r
USING products p
WHERE p.id = r.product_id AND p.price < 2
RETURNING r.id, p.name, r.rating;

-- What is left
SELECT (SELECT count(*) FROM orders) AS orders,
       (SELECT count(*) FROM order_items) AS lines,
       (SELECT count(*) FROM reviews) AS reviews;
