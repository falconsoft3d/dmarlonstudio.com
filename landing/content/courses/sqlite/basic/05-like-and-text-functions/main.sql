-- % is any text, _ is exactly one character
SELECT name FROM products WHERE name LIKE 'b%' ORDER BY id;

-- Text functions and the || operator
SELECT
  name,
  upper(city) AS city,
  length(name) AS letters,
  substr(email, 1, instr(email, '@') - 1) AS user,
  name || ' (' || city || ')' AS label
FROM customers
WHERE email LIKE '%@example.com'
ORDER BY name;
