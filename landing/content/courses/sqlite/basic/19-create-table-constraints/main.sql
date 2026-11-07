-- A new table with its rules
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  country TEXT NOT NULL DEFAULT 'Spain',
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  since TEXT
);

INSERT INTO suppliers (name, rating, since) VALUES
  ('Harinas del Sur', 5, '2022-02-01'),
  ('Lácteos Norte', 4, '2023-05-15');
INSERT INTO suppliers (name, country, rating) VALUES ('Fresh Fruit Ltd', 'UK', 3);

-- The table appears in the list on the left; PRAGMA describes it
SELECT name, type, "notnull", dflt_value, pk
FROM pragma_table_info('suppliers');

SELECT * FROM suppliers ORDER BY id;
