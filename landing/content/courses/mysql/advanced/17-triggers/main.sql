-- Every price change leaves a line in this log
CREATE TABLE price_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT,
  old_price DECIMAL(8,2),
  new_price DECIMAL(8,2)
);

DELIMITER //
CREATE TRIGGER products_price_log
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  IF NEW.price <> OLD.price THEN
    INSERT INTO price_log (product_id, old_price, new_price)
    VALUES (OLD.id, OLD.price, NEW.price);
  END IF;
END //
DELIMITER ;

UPDATE products SET price = price + 0.20 WHERE category_id = 1;
UPDATE products SET stock = stock + 1 WHERE category_id = 1;  -- no log
UPDATE products SET price = 9.50 WHERE id = 4;

SELECT l.id, p.name, l.old_price, l.new_price
FROM price_log l
JOIN products p ON p.id = l.product_id
ORDER BY l.id;
