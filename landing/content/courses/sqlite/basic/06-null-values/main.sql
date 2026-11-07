-- NULL means "no value": compare it with IS, not with =
SELECT name, city FROM customers WHERE email IS NULL;

SELECT count(*) AS with_equals FROM customers WHERE email = NULL;

-- coalesce() returns its first argument that is not NULL
SELECT
  r.id,
  r.product_id,
  r.rating,
  coalesce(r.comment, '(no comment)') AS comment
FROM reviews AS r
ORDER BY r.id;
