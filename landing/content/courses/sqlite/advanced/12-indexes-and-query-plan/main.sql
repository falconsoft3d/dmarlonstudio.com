-- Without an index, SQLite reads the whole table (SCAN)
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE customer_id = 1;

-- An index on the column used to search
CREATE INDEX idx_orders_customer ON orders (customer_id);

-- A UNIQUE index also stops duplicates
CREATE UNIQUE INDEX idx_products_name ON products (name);

-- Now it jumps straight to the matching rows (SEARCH)
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE customer_id = 1;

-- A join that can use the index on the inner table
EXPLAIN QUERY PLAN
SELECT c.name, o.total
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.id
WHERE c.city = 'Madrid';

-- The indexes of the database (the automatic ones start with sqlite_)
SELECT name, tbl_name AS "table", sql IS NULL AS automatic
FROM sqlite_master
WHERE type = 'index'
ORDER BY name;
