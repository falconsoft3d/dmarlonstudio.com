-- % is any text, _ is exactly one character
SELECT name FROM products
WHERE name LIKE '%bread%' OR name LIKE 'B_g%'
ORDER BY name;

-- Text functions
SELECT UPPER(city) AS city,
       LEFT(name, 3) AS code,
       CHAR_LENGTH(name) AS chars,
       LENGTH(name) AS bytes,
       CONCAT(name, ' <', IFNULL(email, '-'), '>') AS contact
FROM customers
WHERE name LIKE '%a%'
ORDER BY id;
