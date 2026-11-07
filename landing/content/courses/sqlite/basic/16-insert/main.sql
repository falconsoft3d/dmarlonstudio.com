-- One row, naming the columns (id is assigned automatically)
INSERT INTO customers (name, email, city, joined)
VALUES ('Lucía Romero', 'lucia@example.com', 'Granada', '2024-06-10');

-- Several rows at once; the columns left out take their DEFAULT
INSERT INTO products (name, category_id, price, tags) VALUES
  ('Butter', 3, 2.25, '[]'),
  ('Lemonade', 2, 1.95, '["juice"]');

-- INSERT ... SELECT copies rows from a query
INSERT INTO reviews (product_id, rating, comment)
SELECT id, 5, 'New in the shop' FROM products WHERE id > 12;

SELECT p.id, p.name, p.price, p.stock, p.active, r.comment
FROM products AS p
LEFT JOIN reviews AS r ON r.product_id = p.id
WHERE p.id >= 11
ORDER BY p.id;
