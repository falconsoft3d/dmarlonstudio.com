-- A table of suppliers with identity, constraints and defaults
CREATE TABLE suppliers (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL UNIQUE,
  country text NOT NULL DEFAULT 'Spain',
  rating smallint CHECK (rating BETWEEN 1 AND 5),
  since date NOT NULL DEFAULT '2024-01-01',
  category_id integer REFERENCES categories (id)
);

INSERT INTO suppliers (name, rating, category_id)
VALUES ('Harinas del Sur', 5, 1), ('Lácteos Norte', 4, 3);

INSERT INTO suppliers (name, country, rating, since, category_id)
VALUES ('Café Andino', 'Colombia', 4, '2024-03-10', 2);

ALTER TABLE suppliers ADD COLUMN email text;

SELECT s.id, s.name, s.country, s.rating, s.since, c.name AS category
FROM suppliers s
JOIN categories c ON c.id = s.category_id
ORDER BY s.id;
