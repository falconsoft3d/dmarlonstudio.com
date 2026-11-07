-- Low ratings go away
DELETE FROM reviews WHERE rating < 3;

-- A cancelled order: first its lines, then the order
DELETE FROM order_items WHERE order_id = 5;
DELETE FROM orders WHERE id = 5;

-- What is left
SELECT status, COUNT(*) AS orders, SUM(total) AS total
FROM orders
GROUP BY status
ORDER BY status;
