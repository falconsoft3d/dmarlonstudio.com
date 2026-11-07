DELIMITER //
-- A function returns one value and can be used inside any query
CREATE FUNCTION with_vat(amount DECIMAL(10,2), rate INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  RETURN ROUND(amount * (100 + rate) / 100, 2);
END //

CREATE FUNCTION stock_label(units INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
  IF units = 0 THEN RETURN 'sold out';
  ELSEIF units < 15 THEN RETURN 'low';
  END IF;
  RETURN 'ok';
END //
DELIMITER ;

SELECT name,
       price,
       with_vat(price, 10) AS vat_10,
       with_vat(price, 21) AS vat_21,
       stock_label(stock) AS stock
FROM products
WHERE category_id IN (2, 3)
ORDER BY price DESC;
