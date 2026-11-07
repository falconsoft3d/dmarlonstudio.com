-- An enum: a type with a fixed list of values, in this order
CREATE TYPE order_status AS ENUM ('new', 'paid', 'shipped', 'cancelled');

ALTER TABLE orders
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE order_status USING status::order_status,
  ALTER COLUMN status SET DEFAULT 'new';

SELECT enum_range(NULL::order_status)::text[] AS statuses;

-- A domain: a type with a rule, reusable in any table
CREATE DOMAIN email_address AS text
  CHECK (VALUE ~ '^[^@\s]+@[^@\s]+\.[a-z]+$');

ALTER TABLE customers ALTER COLUMN email TYPE email_address;

SELECT 'ana@example.com'::email_address AS valid;

-- An enum sorts by its list, not alphabetically, and compares with < >
-- ::text shows the label; ORDER BY o.status keeps the enum order
SELECT o.status::text AS status, count(*) AS orders, sum(o.total) AS total,
       o.status < 'shipped' AS pending
FROM orders o
GROUP BY o.status
ORDER BY o.status;
