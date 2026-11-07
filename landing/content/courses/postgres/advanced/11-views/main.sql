-- A view is a saved query: it is always up to date
CREATE VIEW customer_sales AS
SELECT c.id, c.name, c.city, count(o.id) AS orders, coalesce(sum(o.total), 0) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status <> 'cancelled'
GROUP BY c.id;

-- A materialized view stores the result: fast, but a snapshot
CREATE MATERIALIZED VIEW city_sales AS
SELECT city, sum(orders) AS orders, sum(spent) AS spent
FROM customer_sales
GROUP BY city;

-- A new order for Carlos (Bilbao)
INSERT INTO orders (customer_id, ordered, status, total)
VALUES (8, '2024-06-10', 'paid', 12.00);

-- The view sees it; the materialized view does not, until REFRESH
SELECT name, orders, spent FROM customer_sales WHERE id = 8;
SELECT city, orders, spent FROM city_sales WHERE city = 'Bilbao';

REFRESH MATERIALIZED VIEW city_sales;

SELECT city, orders, spent FROM city_sales ORDER BY spent DESC;
