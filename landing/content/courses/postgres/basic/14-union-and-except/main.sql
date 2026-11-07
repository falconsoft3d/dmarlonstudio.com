-- INTERSECT: products that were sold AND have a review
SELECT product_id FROM order_items
INTERSECT
SELECT product_id FROM reviews
ORDER BY product_id;

-- EXCEPT: products that have never been sold
SELECT id, name FROM products
EXCEPT
SELECT p.id, p.name
FROM products p JOIN order_items i ON i.product_id = p.id;

-- UNION removes duplicates, UNION ALL keeps every row
SELECT (SELECT count(*) FROM (SELECT city FROM customers
          UNION SELECT city FROM customers) u) AS union_rows,
       (SELECT count(*) FROM (SELECT city FROM customers
          UNION ALL SELECT city FROM customers) a) AS union_all_rows;

-- One list of people from two tables (same number and type of columns)
SELECT name, 'customer' AS kind, city AS detail FROM customers
WHERE city IN ('Madrid', 'Seville')
UNION ALL
SELECT name, 'employee', role FROM employees
WHERE manager_id = 2
ORDER BY kind, name;
