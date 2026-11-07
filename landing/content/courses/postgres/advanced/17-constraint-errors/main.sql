-- One more rule for the products: the price must be positive
ALTER TABLE products ADD CONSTRAINT price_positive CHECK (price > 0);

-- try() runs a statement and returns the error instead of stopping
CREATE FUNCTION try(stmt text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE c text; col text;
BEGIN
  EXECUTE stmt;
  RETURN 'ok';
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS c = CONSTRAINT_NAME, col = COLUMN_NAME;
  RETURN SQLSTATE || ' ' || coalesce(nullif(c, ''), 'column ' || col);
END;
$$;

SELECT t.what, try(t.stmt) AS result
FROM (VALUES
  ('good row',    'INSERT INTO products (name, price) VALUES (''Honey'', 5)'),
  ('price -1',    'INSERT INTO products (name, price) VALUES (''X'', -1)'),
  ('no name',     'INSERT INTO products (price) VALUES (2)'),
  ('same email',  'UPDATE customers SET email = ''ana@example.com'' WHERE id = 2'),
  ('category 99', 'UPDATE products SET category_id = 99 WHERE id = 1'),
  ('in use',      'DELETE FROM categories WHERE id = 1')
) AS t (what, stmt);

-- Without try(), the error stops the script
INSERT INTO orders (customer_id, ordered) VALUES (99, '2024-07-01');
