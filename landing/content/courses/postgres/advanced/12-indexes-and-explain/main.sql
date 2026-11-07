-- A bigger table: 20,000 order lines made with generate_series
CREATE TABLE big_items AS
SELECT n AS id, n % 500 AS order_id, n % 12 + 1 AS product_id, n % 7 + 1 AS qty
FROM generate_series(1, 20000) AS n;

ANALYZE big_items;

-- Without an index PostgreSQL reads the whole table (Seq Scan)
EXPLAIN (COSTS OFF) SELECT * FROM big_items WHERE order_id = 42;

-- An index on the column of the WHERE
CREATE INDEX big_items_order_idx ON big_items (order_id);

-- Now it can jump straight to the rows
EXPLAIN (COSTS OFF) SELECT * FROM big_items WHERE order_id = 42;

-- A composite index helps WHERE and ORDER BY at the same time
CREATE INDEX big_items_prod_qty_idx ON big_items (product_id, qty DESC);

EXPLAIN (COSTS OFF)
SELECT id, qty FROM big_items WHERE product_id = 3 ORDER BY qty DESC LIMIT 5;
