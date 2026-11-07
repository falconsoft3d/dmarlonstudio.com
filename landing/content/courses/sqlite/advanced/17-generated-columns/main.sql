-- Columns calculated from other columns of the same row
ALTER TABLE products
ADD COLUMN price_vat REAL AS (round(price * 1.21, 2));
ALTER TABLE products
ADD COLUMN first_tag TEXT AS (json_extract(tags, '$[0]'));

-- In a new table they can also be STORED on disk
CREATE TABLE invoice_lines (
  id INTEGER PRIMARY KEY,
  qty INTEGER NOT NULL,
  price REAL NOT NULL,
  net REAL AS (round(qty * price, 2)) STORED,
  vat REAL AS (round(net * 0.21, 2)) STORED
);
INSERT INTO invoice_lines (qty, price) VALUES (4, 2.40), (3, 1.20);

SELECT * FROM invoice_lines ORDER BY id;

-- They follow the data and can be indexed
UPDATE products SET price = 10.50 WHERE id = 4;
CREATE INDEX idx_products_first_tag ON products (first_tag);

SELECT name, price, price_vat, first_tag
FROM products
WHERE first_tag IN ('bread', 'coffee', 'fresh')
ORDER BY first_tag, name;
