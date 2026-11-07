-- How many reviews there are before deleting
SELECT count(*) AS reviews FROM reviews;

-- Delete the rows that match the WHERE
DELETE FROM reviews WHERE rating < 3;

-- A subquery picks what to delete: the reviews of Drinks products
DELETE FROM reviews
WHERE product_id IN (SELECT id FROM products WHERE category_id = 2);

SELECT id, product_id, rating, comment FROM reviews ORDER BY id;
