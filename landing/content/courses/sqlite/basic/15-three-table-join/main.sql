-- The lines of two orders: order, product and category
SELECT
  i.order_id AS "order",
  p.name AS product,
  c.name AS category,
  i.qty,
  i.price,
  round(i.qty * i.price, 2) AS subtotal
FROM order_items AS i
JOIN products AS p ON p.id = i.product_id
JOIN categories AS c ON c.id = p.category_id
WHERE i.order_id IN (1, 6)
ORDER BY i.order_id, subtotal DESC;
