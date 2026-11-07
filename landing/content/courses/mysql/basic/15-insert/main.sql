-- One row: the id is left to AUTO_INCREMENT
INSERT INTO categories (name) VALUES ('Frozen');

-- The id MySQL has just given it
SELECT LAST_INSERT_ID() AS new_id;

-- Several rows in one statement
INSERT INTO products (name, category_id, price, stock, tags) VALUES
  ('Ice cream', LAST_INSERT_ID(), 4.20, 10, '["sweet"]'),
  ('Frozen peas', LAST_INSERT_ID(), 1.95, 24, '[]'),
  ('Pizza', LAST_INSERT_ID(), 3.60, 15, NULL);

-- The new rows (active took its DEFAULT)
SELECT p.id, p.name, c.name AS category, p.price, p.stock, p.active
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE c.name = 'Frozen'
ORDER BY p.id;
