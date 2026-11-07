-- CASE turns values into labels
SELECT
  name,
  price,
  CASE
    WHEN price < 2 THEN 'cheap'
    WHEN price < 5 THEN 'regular'
    ELSE 'premium'
  END AS band,
  CASE stock WHEN 0 THEN 'sold out' ELSE stock END AS stock
FROM products
ORDER BY price
LIMIT 6;

-- Conditional aggregation: one column per status
SELECT
  substr(ordered, 1, 7) AS month,
  count(*) AS orders,
  sum(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) AS shipped,
  sum(status = 'paid') AS paid,
  sum(status = 'new') AS new,
  sum(CASE WHEN status = 'cancelled' THEN total ELSE 0 END) AS lost
FROM orders
GROUP BY month
ORDER BY month;
