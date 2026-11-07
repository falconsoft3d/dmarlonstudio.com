-- SQLite only checks foreign keys when you turn them on
PRAGMA foreign_keys;

CREATE TABLE wishlist (
  customer_id INTEGER NOT NULL
    REFERENCES customers (id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products (id),
  PRIMARY KEY (customer_id, product_id)
);

-- Still off: product 99 does not exist, but the row goes in
INSERT INTO wishlist VALUES (8, 4), (8, 9), (5, 12), (5, 2), (5, 99);

-- foreign_key_check lists the rows that break a foreign key
PRAGMA foreign_key_check;

-- Clean up, then turn the checks on for this connection
DELETE FROM wishlist WHERE product_id NOT IN (SELECT id FROM products);
PRAGMA foreign_keys = ON;

-- Deleting a customer also deletes their wishlist (CASCADE)
DELETE FROM customers WHERE id = 8;

SELECT w.customer_id, c.name AS customer, p.name AS product
FROM wishlist AS w
JOIN customers AS c ON c.id = w.customer_id
JOIN products AS p ON p.id = w.product_id
ORDER BY p.name;
