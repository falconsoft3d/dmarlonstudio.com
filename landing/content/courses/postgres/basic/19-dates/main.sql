-- Date arithmetic: a date plus days is a date; a date minus a date, days
SELECT date '2024-03-01' + 30 AS plus_30,
       date '2024-06-05' - date '2024-03-01' AS days_between,
       (date '2024-03-31' + interval '1 month')::date AS next_month;

-- extract and to_char take a date apart
SELECT id, ordered,
       extract(dow FROM ordered) AS weekday,
       to_char(ordered, 'Dy DD Mon') AS label
FROM orders ORDER BY id LIMIT 3;

-- Orders per month with date_trunc
SELECT date_trunc('month', ordered)::date AS month,
       count(*) AS orders,
       sum(total) AS revenue,
       max(ordered) - min(ordered) AS span_days
FROM orders
GROUP BY 1
ORDER BY 1;
