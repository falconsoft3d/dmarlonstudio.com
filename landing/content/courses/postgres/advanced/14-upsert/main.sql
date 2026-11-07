-- ON CONFLICT DO NOTHING: the category already exists, nothing happens
INSERT INTO categories (name) VALUES ('Dairy'), ('Frozen')
ON CONFLICT (name) DO NOTHING
RETURNING id, name;

-- A shopping cart: one row per customer and product
CREATE TABLE cart (
  customer_id int REFERENCES customers (id),
  product_id int REFERENCES products (id),
  qty int NOT NULL,
  PRIMARY KEY (customer_id, product_id)
);

INSERT INTO cart VALUES (1, 2, 2), (1, 5, 1);

-- ON CONFLICT DO UPDATE: add to the quantity if the row is there;
-- EXCLUDED is the row that could not be inserted
INSERT INTO cart (customer_id, product_id, qty)
VALUES (1, 2, 3), (1, 9, 1), (2, 2, 1)
ON CONFLICT (customer_id, product_id)
DO UPDATE SET qty = cart.qty + EXCLUDED.qty
RETURNING customer_id, product_id, qty, xmax = 0 AS inserted;

