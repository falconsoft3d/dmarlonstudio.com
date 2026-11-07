-- A generated column is computed from the others
ALTER TABLE order_items
  ADD COLUMN line_total DECIMAL(10,2)
    AS (qty * price) STORED;

ALTER TABLE products
  ADD COLUMN price_vat DECIMAL(8,2) AS (ROUND(price * 1.21, 2)) VIRTUAL,
  ADD COLUMN first_tag VARCHAR(20) AS (tags ->> '$[0]') VIRTUAL,
  ADD INDEX idx_first_tag (first_tag);

-- Change qty: line_total follows on its own
UPDATE order_items SET qty = 3 WHERE id = 1;

SELECT i.id, p.name, i.qty, i.price, i.line_total, p.first_tag
FROM order_items i
JOIN products p ON p.id = i.product_id
WHERE i.order_id IN (1, 2)
ORDER BY i.id;
