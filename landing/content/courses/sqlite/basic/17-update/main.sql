-- Change one row: always with a WHERE
UPDATE products SET stock = 50 WHERE name = 'Orange juice';

-- Several columns and an expression: 10% more on all Bakery items
UPDATE products
SET price = round(price * 1.10, 2), tags = '["bread", "promo"]'
WHERE category_id = 1;

-- Paid orders from before June are now shipped
UPDATE orders SET status = 'shipped'
WHERE status = 'paid' AND ordered < '2024-06-01';

SELECT id, name, price, stock, tags
FROM products
WHERE category_id = 1 OR id = 6
ORDER BY id;
