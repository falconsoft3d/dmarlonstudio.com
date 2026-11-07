-- Integer division vs numeric division
SELECT 7 / 2 AS int_div, 7 / 2.0 AS num_div, 7::numeric / 2 AS cast_div;

-- Text to number and date with ::
SELECT '42'::int + 1 AS answer, '2024-03-01'::date AS day, 9.90::int AS rounded;

-- Expressions with aliases: the value of the stock of each product
SELECT name,
       price,
       stock,
       price * stock AS stock_value,
       stock::text || ' units' AS label
FROM products
WHERE category_id = 2
ORDER BY stock_value DESC;
