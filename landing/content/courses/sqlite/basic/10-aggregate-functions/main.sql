-- Aggregates turn many rows into one
SELECT
  count(*) AS orders,
  round(sum(total), 2) AS revenue,
  round(avg(total), 2) AS average,
  min(total) AS smallest,
  max(total) AS largest
FROM orders
WHERE status <> 'cancelled';

-- count(column) skips the NULLs
SELECT count(*) AS reviews, count(comment) AS with_comment,
       avg(rating) AS avg_rating
FROM reviews;
