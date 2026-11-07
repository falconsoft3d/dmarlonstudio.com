-- Integer division drops the decimals
SELECT 7 / 2 AS int_div, 7 / 2.0 AS real_div, 7 % 2 AS remainder;

-- Line totals, rounded to cents
SELECT
  order_id,
  product_id,
  qty,
  price,
  round(qty * price, 2) AS line_total,
  round(qty * price * 0.9, 2) AS with_10_off
FROM order_items
WHERE order_id IN (4, 6)
ORDER BY id;
