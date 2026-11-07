-- Raise the drinks by 10% and see the new prices at once
UPDATE products
SET price = round(price * 1.10, 2)
WHERE category_id = 2
RETURNING id, name, price;

-- Several columns, and a value computed from the old one
UPDATE products
SET stock = stock + 20, active = true
WHERE stock = 0
RETURNING id, name, stock, active;

-- UPDATE ... FROM: mark as shipped the paid orders of Madrid
UPDATE orders o
SET status = 'shipped'
FROM customers c
WHERE c.id = o.customer_id AND c.city = 'Madrid' AND o.status = 'paid'
RETURNING o.id, c.name, o.status;

SELECT status, count(*) AS orders FROM orders GROUP BY status ORDER BY status;
