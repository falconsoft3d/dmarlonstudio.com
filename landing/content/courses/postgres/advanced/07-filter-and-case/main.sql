-- CASE turns values into labels
SELECT name, price,
       CASE
         WHEN price < 2 THEN 'cheap'
         WHEN price < 5 THEN 'normal'
         ELSE 'premium'
       END AS band
FROM products
WHERE category_id IN (1, 2)
ORDER BY price;

-- FILTER: several conditional aggregates in one pass
SELECT count(*) AS orders,
       count(*) FILTER (WHERE status = 'shipped') AS shipped,
       count(*) FILTER (WHERE status IN ('new', 'paid')) AS pending,
       sum(total) FILTER (WHERE status <> 'cancelled') AS revenue
FROM orders;

-- A pivot: one row per month, one column per status
SELECT to_char(ordered, 'YYYY-MM') AS month,
       count(*) FILTER (WHERE status = 'new') AS new,
       count(*) FILTER (WHERE status = 'paid') AS paid,
       count(*) FILTER (WHERE status = 'shipped') AS shipped,
       sum(CASE WHEN status = 'cancelled' THEN 0 ELSE total END) AS revenue
FROM orders
GROUP BY 1
ORDER BY 1;
