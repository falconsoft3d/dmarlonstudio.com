-- Without an index, MySQL reads the whole table
EXPLAIN SELECT name FROM customers WHERE city = 'Madrid';

CREATE INDEX idx_customers_city ON customers (city);
-- A composite index: status first, then date
CREATE INDEX idx_orders_status_date ON orders (status, ordered);

-- Now it can jump straight to the rows
EXPLAIN SELECT name FROM customers WHERE city = 'Madrid';

-- The indexes of a table (PRIMARY, UNIQUE and the new one)
SELECT table_name AS `table`, index_name AS `index`,
       seq_in_index AS seq, column_name AS `column`, non_unique AS dup
FROM information_schema.statistics
WHERE table_schema = DATABASE() AND table_name IN ('customers', 'orders')
ORDER BY table_name, index_name, seq_in_index;
