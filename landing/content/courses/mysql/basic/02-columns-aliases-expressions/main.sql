-- Expressions are computed for every row
SELECT name,
       price,
       stock,
       price * stock AS stock_value,
       price * 1.21 AS price_with_vat,
       'EUR' AS currency
FROM products
ORDER BY stock_value DESC
LIMIT 8;
