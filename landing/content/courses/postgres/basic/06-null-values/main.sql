-- NULL is not equal to anything, not even NULL
SELECT NULL = NULL AS equal, NULL IS NULL AS is_null, 1 + NULL AS plus;

-- The customer without email: = NULL finds nothing, IS NULL does
SELECT name FROM customers WHERE email = NULL;
SELECT name, city FROM customers WHERE email IS NULL;

-- coalesce gives a fallback, nullif turns a value into NULL
SELECT r.id,
       r.rating,
       coalesce(r.comment, '(no comment)') AS comment,
       nullif(r.rating, 5) AS not_five
FROM reviews r
ORDER BY r.id;
