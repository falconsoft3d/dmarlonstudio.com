CREATE TABLE suppliers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  email VARCHAR(80) UNIQUE,
  country CHAR(2) NOT NULL DEFAULT 'ES',
  kind ENUM('farm', 'factory', 'wholesale') NOT NULL,
  since DATE
);

INSERT INTO suppliers (name, email, kind, since) VALUES
  ('Huerta Sol', 'sol@example.com', 'farm', '2022-05-01'),
  ('Molinos Sur', 'molinos@example.com', 'factory', '2021-11-15');
INSERT INTO suppliers (name, country, kind)
  VALUES ('Dairy Co', 'FR', 'wholesale');

-- The columns of the new table
SHOW COLUMNS FROM suppliers;

SELECT * FROM suppliers ORDER BY id;
