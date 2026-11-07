-- LIKE is case-sensitive, ILIKE is not
SELECT name FROM products WHERE name LIKE 'g%';
SELECT name FROM products WHERE name ILIKE 'g%' ORDER BY name;

-- Text functions on the customers
SELECT name,
       upper(city) AS city,
       length(name) AS letters,
       split_part(email, '@', 1) AS username,
       initcap(split_part(email, '@', 1)) || ' from ' || city AS greeting
FROM customers
WHERE email LIKE '%@example.com'
ORDER BY id
LIMIT 6;
