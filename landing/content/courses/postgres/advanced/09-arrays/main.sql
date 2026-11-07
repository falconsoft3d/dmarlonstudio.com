-- array_agg collects values into an array; string_agg into text
SELECT c.name AS category,
       array_agg(p.id ORDER BY p.id) AS ids,
       string_agg(p.name, ', ' ORDER BY p.name) AS products
FROM categories c
JOIN products p ON p.category_id = c.id
GROUP BY c.name
ORDER BY c.name;

-- Array literals, indexes (from 1), length and membership
SELECT a, a[1] AS first, cardinality(a) AS n, 3 = ANY (a) AS has_3,
       a || 9 AS appended
FROM (SELECT ARRAY[3, 1, 2] AS a) t;

-- = ANY (array) works like IN with a list
SELECT name, price FROM products
WHERE id = ANY (ARRAY[2, 5, 9])
ORDER BY id;

-- The products of each order as an array, and a question about it
SELECT o.id, o.status,
       array_agg(i.product_id ORDER BY i.product_id) AS products,
       sum(i.qty) AS units,
       4 = ANY (array_agg(i.product_id)) AS has_coffee
FROM orders o
JOIN order_items i ON i.order_id = o.id
GROUP BY o.id
ORDER BY o.id;
