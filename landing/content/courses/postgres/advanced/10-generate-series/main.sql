-- A series of numbers, and of dates with a step
SELECT n, n * n AS square FROM generate_series(1, 4) AS n;

SELECT d::date AS day
FROM generate_series(date '2024-03-01', date '2024-03-22', interval '1 week') AS d;

-- A calendar of months from January to July 2024 with their sales:
-- the months without orders appear with 0
SELECT to_char(m, 'YYYY-MM') AS month,
       count(o.id) AS orders,
       coalesce(sum(o.total), 0) AS revenue,
       repeat('#', count(o.id)::int) AS bar
FROM generate_series(date '2024-01-01', date '2024-07-01', interval '1 month') AS m
LEFT JOIN orders o
       ON o.ordered >= m AND o.ordered < m + interval '1 month'
      AND o.status <> 'cancelled'
GROUP BY m
ORDER BY m;
