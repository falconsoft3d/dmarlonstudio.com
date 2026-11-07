-- Window functions add a value to each row without grouping them
SELECT
  name,
  category_id AS cat,
  price,
  row_number() OVER (ORDER BY price DESC) AS overall,
  row_number() OVER (PARTITION BY category_id ORDER BY price DESC) AS in_cat
FROM products
ORDER BY cat, in_cat;

-- RANK leaves gaps after ties; DENSE_RANK does not
SELECT
  product_id,
  avg(rating) AS avg_rating,
  rank() OVER (ORDER BY avg(rating) DESC) AS rnk,
  dense_rank() OVER (ORDER BY avg(rating) DESC) AS dense
FROM reviews
GROUP BY product_id
ORDER BY rnk, product_id;
