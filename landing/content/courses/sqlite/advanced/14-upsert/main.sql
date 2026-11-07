-- A basket: one row per customer and product
CREATE TABLE baskets (
  customer_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty INTEGER NOT NULL,
  PRIMARY KEY (customer_id, product_id)
);

INSERT INTO baskets VALUES (1, 2, 2), (1, 7, 1), (3, 9, 1);

-- Add to the basket: insert, or add to the quantity if it exists
INSERT INTO baskets (customer_id, product_id, qty) VALUES (1, 2, 3)
ON CONFLICT (customer_id, product_id)
DO UPDATE SET qty = qty + excluded.qty;

INSERT INTO baskets (customer_id, product_id, qty) VALUES (3, 5, 2)
ON CONFLICT (customer_id, product_id)
DO UPDATE SET qty = qty + excluded.qty;

-- Ignore the duplicate instead of failing
INSERT INTO baskets VALUES (3, 9, 10) ON CONFLICT DO NOTHING;

SELECT b.customer_id AS cust, p.name, b.qty,
       round(b.qty * p.price, 2) AS amount
FROM baskets AS b
JOIN products AS p ON p.id = b.product_id
ORDER BY cust, p.name;
