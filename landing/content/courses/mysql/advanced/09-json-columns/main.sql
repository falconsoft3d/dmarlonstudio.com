-- tags is a JSON array: -> gives JSON, ->> gives plain text
SELECT name,
       tags,
       tags -> '$[0]' AS first_json,
       tags ->> '$[0]' AS first_text,
       JSON_LENGTH(tags) AS n
FROM products
WHERE category_id IN (1, 4)
ORDER BY id;

-- JSON_CONTAINS: which products are tagged "sweet"?
SELECT name, price FROM products
WHERE JSON_CONTAINS(tags, '"sweet"')
ORDER BY name;

-- Change the JSON in place
UPDATE products SET tags = JSON_ARRAY_APPEND(tags, '$', 'offer')
WHERE JSON_CONTAINS(tags, '"sweet"');

SELECT name, tags, JSON_SEARCH(tags, 'one', 'offer') AS at
FROM products
WHERE JSON_CONTAINS(tags, '"offer"')
ORDER BY name;
