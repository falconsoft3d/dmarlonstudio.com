-- Before
SELECT name, price, stock FROM products WHERE category_id = 1 ORDER BY id;

-- 10% more for the whole bakery
UPDATE products
SET price = ROUND(price * 1.10, 2)
WHERE category_id = 1;

-- Restock what is sold out and switch it back on
UPDATE products
SET stock = stock + 20, active = TRUE
WHERE stock = 0;

-- After
SELECT name, price, stock, active FROM products
WHERE category_id = 1 OR name IN ('Orange juice', 'Bananas 1 kg')
ORDER BY id;
