-- BEGIN opens a transaction: nothing is final until COMMIT
BEGIN;

UPDATE products SET stock = stock - 2 WHERE id = 9;
INSERT INTO orders (customer_id, ordered, status, total)
VALUES (8, '2024-06-10', 'paid', 15.50);

-- A savepoint is a point you can go back to
SAVEPOINT before_discount;
UPDATE orders SET total = 0 WHERE id = 11;
SELECT id, total FROM orders WHERE id = 11;

-- Undo only what came after the savepoint
ROLLBACK TO SAVEPOINT before_discount;
COMMIT;

-- ROLLBACK throws away the whole transaction
BEGIN;
DELETE FROM reviews;
SELECT count(*) AS reviews_inside FROM reviews;
ROLLBACK;

SELECT (SELECT stock FROM products WHERE id = 9) AS cheese_stock,
       (SELECT total FROM orders WHERE id = 11) AS order_11,
       (SELECT count(*) FROM reviews) AS reviews;
