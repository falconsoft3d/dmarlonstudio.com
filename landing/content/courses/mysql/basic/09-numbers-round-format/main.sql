-- Division, integer division and remainder; exact decimals
SELECT 7 / 2 AS division, 7 DIV 2 AS whole, 7 MOD 2 AS remainder,
       ROUND(2.675, 2) AS rounded, TRUNCATE(2.675, 1) AS cut;

-- FORMAT returns text with thousands separators
SELECT FORMAT(1234567.891, 2) AS english,
       FORMAT(1234567.891, 2, 'es_ES') AS spanish;

-- Prices with 21% VAT, rounded down and up
SELECT name,
       price,
       ROUND(price * 1.21, 2) AS with_vat,
       FLOOR(price) AS floor,
       CEIL(price) AS ceil,
       price * stock AS stock_value
FROM products
WHERE category_id = 2
ORDER BY price DESC;
