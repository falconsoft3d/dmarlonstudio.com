-- A SQL function: one expression, marked IMMUTABLE (same input, same output)
CREATE FUNCTION with_vat(amount numeric, rate numeric DEFAULT 21)
RETURNS numeric LANGUAGE sql IMMUTABLE
AS $$ SELECT round(amount * (1 + rate / 100), 2) $$;

-- A PL/pgSQL function: variables, SELECT INTO and IF
CREATE FUNCTION customer_level(cid int) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
  spent numeric;
BEGIN
  SELECT coalesce(sum(total), 0) INTO spent
  FROM orders WHERE customer_id = cid AND status <> 'cancelled';
  IF spent >= 30 THEN
    RETURN 'gold';
  ELSIF spent >= 15 THEN
    RETURN 'silver';
  END IF;
  RETURN 'bronze';
END;
$$;

SELECT with_vat(10) AS vat_21, with_vat(10, 10) AS vat_10;

SELECT name, city, customer_level(id) AS level
FROM customers
ORDER BY id;
