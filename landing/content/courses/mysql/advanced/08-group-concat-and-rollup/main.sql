-- GROUP_CONCAT joins the values of a group in one text
SELECT c.name AS category,
       GROUP_CONCAT(p.name ORDER BY p.name SEPARATOR ', ') AS products
FROM products p
JOIN categories c ON c.id = p.category_id
GROUP BY c.name
ORDER BY c.name;

-- WITH ROLLUP adds subtotals and a grand total (NULL rows)
SELECT IF(GROUPING(c.city), 'ALL', c.city) AS city,
       IF(GROUPING(o.status), 'all', o.status) AS status,
       COUNT(*) AS orders,
       SUM(o.total) AS total
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE c.city IN ('Madrid', 'Seville')
GROUP BY c.city, o.status WITH ROLLUP;
