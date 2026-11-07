-- Expressions are calculated for every row
SELECT
  name,
  price,
  price * 1.21 AS price_with_vat,
  round(stock * price, 2) AS stock_value,
  'EUR' AS currency
FROM products
ORDER BY id
LIMIT 6;
