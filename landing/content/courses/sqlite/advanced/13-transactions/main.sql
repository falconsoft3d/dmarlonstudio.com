-- Move 5 croissants from the shop to an order, all or nothing
BEGIN;
UPDATE products SET stock = stock - 5 WHERE id = 2;
INSERT INTO order_items (order_id, product_id, qty, price)
VALUES (7, 2, 5, 1.50);
UPDATE orders SET total = total + 7.50 WHERE id = 7;
COMMIT;

-- Something goes wrong: undo everything since BEGIN
BEGIN;
DELETE FROM order_items;
SELECT count(*) AS lines_inside FROM order_items;
ROLLBACK;

-- A savepoint undoes only part of a transaction
BEGIN;
UPDATE products SET price = 0 WHERE id = 1;
SAVEPOINT before_milk;
UPDATE products SET price = 0 WHERE id = 7;
ROLLBACK TO before_milk;
UPDATE products SET price = 1.25 WHERE id = 1;
COMMIT;

SELECT p.id, p.name, p.price, p.stock,
       (SELECT count(*) FROM order_items) AS lines,
       (SELECT total FROM orders WHERE id = 7) AS order_7
FROM products AS p
WHERE p.id IN (1, 2, 7)
ORDER BY p.id;
