-- float is binary and approximate, numeric is exact
SELECT 0.1::float8 + 0.2::float8 = 0.3 AS float_ok,
       0.1::numeric + 0.2 = 0.3 AS numeric_ok;

-- round, ceil, floor and trunc
SELECT round(7.756, 2) AS round, ceil(7.2) AS ceil,
       floor(7.8) AS floor, trunc(-7.8) AS trunc;

-- Prices with 21% VAT, as money text with to_char
SELECT name,
       price,
       round(price * 1.21, 2) AS with_vat,
       to_char(price * 1.21, 'FM990.00') || ' €' AS label,
       to_char(price * stock, 'FM9,990.00') AS stock_value
FROM products
WHERE category_id IN (2, 3)
ORDER BY price DESC;
