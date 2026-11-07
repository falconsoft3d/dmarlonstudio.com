-- A log of price changes
CREATE TABLE price_log (
  product_id INTEGER,
  old_price REAL,
  new_price REAL
);

-- Runs by itself after every price change
CREATE TRIGGER log_price AFTER UPDATE OF price ON products
WHEN OLD.price <> NEW.price
BEGIN
  INSERT INTO price_log VALUES (OLD.id, OLD.price, NEW.price);
END;

-- Selling a line takes it out of stock and adds it to the order
CREATE TRIGGER sell AFTER INSERT ON order_items
BEGIN
  UPDATE products SET stock = stock - NEW.qty WHERE id = NEW.product_id;
  UPDATE orders SET total = round(total + NEW.qty * NEW.price, 2)
  WHERE id = NEW.order_id;
END;

UPDATE products SET price = round(price * 1.10, 2) WHERE category_id = 3;
INSERT INTO order_items (order_id, product_id, qty, price)
VALUES (9, 9, 1, 8.53);

SELECT p.name, l.old_price, l.new_price, p.stock,
       (SELECT total FROM orders WHERE id = 9) AS order_9
FROM price_log AS l
JOIN products AS p ON p.id = l.product_id
ORDER BY p.id;
