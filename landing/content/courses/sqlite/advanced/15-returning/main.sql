-- RETURNING gives back the rows a statement has changed.
-- The CTE picks the rows; the grid shows what RETURNING returns.

-- Dairy is 5% dearer: which prices are now in the table?
WITH dairy AS (SELECT id FROM categories WHERE name = 'Dairy')
UPDATE products
SET price = round(price * 1.05, 2)
WHERE category_id IN (SELECT id FROM dairy)
RETURNING id, name, price;

-- Remove the reviews of a product and see what was deleted
WITH target AS (SELECT id FROM products WHERE name = 'Strawberries')
DELETE FROM reviews
WHERE product_id IN (SELECT id FROM target)
RETURNING id, rating, comment;

-- A new order: the id and the defaults come back
WITH buyer AS (SELECT id FROM customers WHERE email = 'carlos@example.com')
INSERT INTO orders (customer_id, ordered)
SELECT id, '2024-06-20' FROM buyer
RETURNING id, customer_id, ordered, status, total;
