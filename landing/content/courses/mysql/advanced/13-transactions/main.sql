-- Move 5 units of Croissant into a new order, all or nothing
START TRANSACTION;
INSERT INTO orders (id, customer_id, ordered, status, total)
  VALUES (11, 8, '2024-06-10', 'new', 7.50);
INSERT INTO order_items (order_id, product_id, qty, price)
  VALUES (11, 2, 5, 1.50);
UPDATE products SET stock = stock - 5 WHERE id = 2;
-- Inside the transaction we see our own changes
SELECT stock FROM products WHERE id = 2;
-- Changed our mind: undo everything since START TRANSACTION
ROLLBACK;

SELECT stock, (SELECT COUNT(*) FROM orders) AS orders
FROM products WHERE id = 2;

-- This time for real
START TRANSACTION;
UPDATE products SET stock = stock - 5 WHERE id = 2;
UPDATE products SET stock = stock + 5 WHERE id = 1;
COMMIT;

SELECT id, name, stock FROM products WHERE id IN (1, 2) ORDER BY id;
