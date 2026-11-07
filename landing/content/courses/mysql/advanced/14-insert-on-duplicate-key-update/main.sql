-- One row per product: the PRIMARY KEY is product_id
CREATE TABLE stock_count (
  product_id INT PRIMARY KEY,
  counted INT NOT NULL,
  times INT NOT NULL DEFAULT 1
);

INSERT INTO stock_count (product_id, counted) VALUES (1, 40), (2, 25);

-- 2 already exists: update it; 3 does not: insert it
INSERT INTO stock_count (product_id, counted) VALUES (2, 23), (3, 12)
AS new
ON DUPLICATE KEY UPDATE counted = new.counted, times = times + 1;

-- INSERT IGNORE skips the duplicate key without an error
INSERT IGNORE INTO stock_count (product_id, counted) VALUES (1, 0);

-- REPLACE deletes the old row and inserts the new one
REPLACE INTO stock_count (product_id, counted) VALUES (3, 11);

SELECT s.product_id, p.name, s.counted, s.times
FROM stock_count s
JOIN products p ON p.id = s.product_id
ORDER BY s.product_id;
