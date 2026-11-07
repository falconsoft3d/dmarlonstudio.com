-- Dates are text (YYYY-MM-DD); the date functions understand it
SELECT
  date('2024-03-01', '+1 month') AS next_month,
  date('2024-03-01', 'start of month', '+1 month', '-1 day') AS end_of_march,
  strftime('%w', '2024-03-01') AS weekday,
  julianday('2024-06-05') - julianday('2024-03-01') AS days;

-- How long each customer had been with the shop on 1 July 2024
SELECT
  name,
  joined,
  strftime('%Y', joined) AS year,
  CAST(julianday('2024-07-01') - julianday(joined) AS INTEGER) AS days,
  joined <= date('2024-07-01', '-1 year') AS over_a_year
FROM customers
ORDER BY joined;

-- Orders per week day
SELECT
  CASE strftime('%w', ordered)
    WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue'
    WHEN '3' THEN 'Wed' WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri'
    ELSE 'Sat'
  END AS weekday,
  count(*) AS orders
FROM orders
GROUP BY strftime('%w', ordered)
ORDER BY strftime('%w', ordered);
