-- CASE inside an aggregate: counting by condition
SELECT SUM(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) AS shipped,
       SUM(status IN ('new', 'paid')) AS pending,
       SUM(IF(status = 'cancelled', total, 0)) AS lost
FROM orders;

-- CASE picks the first WHEN that is true; IF() is the short form
SELECT name,
       price,
       stock,
       CASE
         WHEN price < 2 THEN 'cheap'
         WHEN price < 5 THEN 'normal'
         ELSE 'premium'
       END AS band,
       IF(stock = 0, 'sold out', IF(stock < 15, 'low', 'ok')) AS stock_level
FROM products
ORDER BY price;
