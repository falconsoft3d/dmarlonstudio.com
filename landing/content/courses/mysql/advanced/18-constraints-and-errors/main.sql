-- CHECK constraints are enforced since MySQL 8.0.16
ALTER TABLE products
  ADD CONSTRAINT price_positive CHECK (price > 0),
  ADD CONSTRAINT stock_not_negative CHECK (stock >= 0);

ALTER TABLE reviews
  ADD CONSTRAINT rating_1_to_5 CHECK (rating BETWEEN 1 AND 5);

-- A valid row goes in
INSERT INTO reviews (product_id, rating, comment) VALUES (5, 4, 'Smooth');

SELECT constraint_name AS name, check_clause AS rule
FROM information_schema.check_constraints
WHERE constraint_schema = DATABASE()
ORDER BY constraint_name;

-- This one breaks a CHECK: MySQL refuses it
INSERT INTO reviews (product_id, rating, comment) VALUES (5, 9, 'Amazing');
