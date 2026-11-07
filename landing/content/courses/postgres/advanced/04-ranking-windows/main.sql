-- A window function adds a value to each row without grouping them
SELECT name, price,
       round(avg(price) OVER (), 2) AS avg_all,
       count(*) OVER () AS products
FROM products
WHERE category_id = 1
ORDER BY price;

-- ROW_NUMBER, RANK and DENSE_RANK differ only on ties
SELECT name, stock,
       row_number() OVER (ORDER BY stock DESC) AS row_number,
       rank()       OVER (ORDER BY stock DESC) AS rank,
       dense_rank() OVER (ORDER BY stock DESC) AS dense_rank
FROM (VALUES ('A', 30), ('B', 25), ('C', 25), ('D', 20)) AS t (name, stock)
ORDER BY stock DESC, name;

-- PARTITION BY restarts the count in each category
SELECT c.name AS category, p.name, p.price,
       rank() OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS pos
FROM products p
JOIN categories c ON c.id = p.category_id
ORDER BY c.name, pos;
