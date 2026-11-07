-- An ordinary table accepts any value in any column
CREATE TABLE loose (n INTEGER, price REAL);
INSERT INTO loose VALUES (1, 2.5), ('42', '3'), ('abc', 'cheap');
SELECT n, typeof(n) AS n_type, price, typeof(price) AS price_type
FROM loose
ORDER BY rowid;

-- A STRICT table checks the type of every value
CREATE TABLE strict_prices (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  price REAL NOT NULL CHECK (price > 0),
  extra ANY
) STRICT;

-- Values that convert without loss are accepted
INSERT INTO strict_prices (name, price, extra) VALUES
  ('Muffin', '1.80', 'abc'),
  ('Scone', 2, 42),
  ('Bagel', 1.35, NULL);

-- This one would fail: cannot store TEXT value in REAL column
-- INSERT INTO strict_prices (name, price) VALUES ('Tart', 'cheap');

SELECT name, price, typeof(price) AS price_type,
       extra, typeof(extra) AS extra_type
FROM strict_prices
ORDER BY id;
