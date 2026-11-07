-- Rank inside each category without collapsing the rows
SELECT c.name AS category,
       p.name,
       p.price,
       ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS n,
       RANK() OVER (ORDER BY p.price DESC) AS overall,
       ROUND(AVG(p.price) OVER (PARTITION BY p.category_id), 2) AS cat_avg
FROM products p
JOIN categories c ON c.id = p.category_id
ORDER BY c.name, n;
