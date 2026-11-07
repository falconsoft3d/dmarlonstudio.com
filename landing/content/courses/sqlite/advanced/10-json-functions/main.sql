-- tags is a JSON array stored as text
SELECT
  name,
  tags,
  json_array_length(tags) AS n,
  json_extract(tags, '$[0]') AS first_tag
FROM products
WHERE id IN (2, 7, 12)
ORDER BY id;

-- json_each turns the array into rows: one per tag
SELECT p.name, t.value AS tag
FROM products AS p, json_each(p.tags) AS t
WHERE t.value = 'sweet'
ORDER BY p.name;

-- Build JSON from rows: every tag with its products
SELECT
  t.value AS tag,
  count(*) AS products,
  json_group_array(p.name ORDER BY p.name) AS names
FROM products AS p, json_each(p.tags) AS t
GROUP BY t.value
ORDER BY products DESC, tag;
