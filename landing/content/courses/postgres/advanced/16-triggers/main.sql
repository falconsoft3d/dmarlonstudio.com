-- Where the changes of price will be written down
CREATE TABLE price_changes (
  product_id int, old_price numeric, new_price numeric, changed date
);

-- A trigger function returns trigger and sees OLD and NEW
CREATE FUNCTION log_price() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.price < 0 THEN
    NEW.price := 0;  -- a BEFORE trigger can fix the row
  END IF;
  IF NEW.price <> OLD.price THEN
    INSERT INTO price_changes
    VALUES (OLD.id, OLD.price, NEW.price, date '2024-07-01');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER products_price
BEFORE UPDATE OF price ON products
FOR EACH ROW EXECUTE FUNCTION log_price();

UPDATE products SET price = price + 0.10 WHERE category_id = 1;
UPDATE products SET price = -1 WHERE id = 11;
UPDATE products SET stock = 99 WHERE id = 7;

SELECT p.name, c.old_price, c.new_price, c.changed
FROM price_changes c JOIN products p ON p.id = c.product_id
ORDER BY c.product_id;
