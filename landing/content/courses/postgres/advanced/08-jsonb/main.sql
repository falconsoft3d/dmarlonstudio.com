-- -> returns jsonb, ->> returns text; arrays start at 0
SELECT name, tags, tags -> 0 AS first_json, tags ->> 0 AS first_text,
       jsonb_array_length(tags) AS n_tags
FROM products
WHERE category_id = 1
ORDER BY id;

-- @> asks "does it contain?": the sweet products
SELECT name, tags FROM products
WHERE tags @> '["sweet"]'
ORDER BY name;

-- Build JSON from rows
SELECT jsonb_build_object('id', id, 'name', name, 'price', price) AS product
FROM products WHERE id IN (4, 9) ORDER BY id;

-- Unnest the tag arrays and count the products per tag
SELECT tag, count(*) AS products, round(avg(price), 2) AS avg_price
FROM products, jsonb_array_elements_text(tags) AS tag
GROUP BY tag
ORDER BY products DESC, tag;
