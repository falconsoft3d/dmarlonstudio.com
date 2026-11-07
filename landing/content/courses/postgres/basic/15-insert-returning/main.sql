-- A new category: the id comes from the identity column
INSERT INTO categories (name) VALUES ('Frozen')
RETURNING id, name;

-- Several rows in one INSERT; the defaults fill stock and active
INSERT INTO products (name, category_id, price, tags) VALUES
  ('Ice cream', 5, 4.20, '["sweet"]'),
  ('Frozen peas', 5, 1.90, '[]')
RETURNING id, name, price, stock, active;

-- INSERT ... SELECT copies rows from a query
INSERT INTO products (name, category_id, price, stock)
SELECT 'Mini ' || name, category_id, round(price / 2, 2), 10
FROM products
WHERE category_id = 1
RETURNING id, name, price, stock;
