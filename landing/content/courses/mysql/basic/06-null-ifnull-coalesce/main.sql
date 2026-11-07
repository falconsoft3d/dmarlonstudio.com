-- = NULL is never true: this finds nothing
SELECT name FROM customers WHERE email = NULL;

-- IS NULL is the way to ask
SELECT name, city FROM customers WHERE email IS NULL;

-- Replace the missing values when showing them
SELECT r.id,
       r.product_id,
       r.rating,
       r.comment,
       IFNULL(r.comment, '(no comment)') AS shown,
       COALESCE(r.comment, CONCAT(r.rating, ' stars')) AS summary
FROM reviews r
ORDER BY r.id;
