-- JSON_TABLE turns every element of the array into a row
SELECT p.name, t.pos, t.tag
FROM products p,
     JSON_TABLE(p.tags, '$[*]' COLUMNS (
       pos FOR ORDINALITY,
       tag VARCHAR(20) PATH '$'
     )) AS t
WHERE p.category_id = 1
ORDER BY p.id, t.pos;

-- And then it can be grouped like any table
SELECT t.tag,
       COUNT(*) AS products,
       ROUND(AVG(p.price), 2) AS avg_price,
       GROUP_CONCAT(p.name ORDER BY p.name SEPARATOR ', ') AS names
FROM products p,
     JSON_TABLE(p.tags, '$[*]' COLUMNS (tag VARCHAR(20) PATH '$')) AS t
GROUP BY t.tag
ORDER BY products DESC, t.tag;
