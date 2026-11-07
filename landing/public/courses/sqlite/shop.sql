-- The sample shop of the DMarlon Studio courses.
-- La tienda de ejemplo de los cursos de DMarlon Studio.

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;


CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  category_id INTEGER REFERENCES categories(id),
  price REAL NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1,
  tags TEXT
);
CREATE TABLE customers (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  city TEXT,
  joined TEXT
);
CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  ordered TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  total REAL NOT NULL DEFAULT 0
);
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  product_id INTEGER REFERENCES products(id),
  qty INTEGER NOT NULL,
  price REAL NOT NULL
);
CREATE TABLE employees (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT,
  manager_id INTEGER REFERENCES employees(id),
  salary REAL
);
CREATE TABLE reviews (
  id INTEGER PRIMARY KEY,
  product_id INTEGER REFERENCES products(id),
  rating INTEGER NOT NULL,
  comment TEXT
);


INSERT INTO categories (id, name) VALUES
  (1, 'Bakery'),
  (2, 'Drinks'),
  (3, 'Dairy'),
  (4, 'Fruit');

INSERT INTO products (id, name, category_id, price, stock, active, tags) VALUES
  (1, 'Baguette', 1, 1.20, 40, 1, '["bread"]'),
  (2, 'Croissant', 1, 1.50, 25, 1, '["bread", "sweet"]'),
  (3, 'Rye bread', 1, 2.80, 12, 1, '["bread"]'),
  (4, 'Espresso beans', 2, 9.90, 18, 1, '["coffee"]'),
  (5, 'Green tea', 2, 4.50, 30, 1, '["tea"]'),
  (6, 'Orange juice', 2, 3.20, 0, 1, '["juice"]'),
  (7, 'Whole milk', 3, 1.10, 60, 1, '[]'),
  (8, 'Greek yogurt', 3, 2.40, 22, 1, '["sweet"]'),
  (9, 'Manchego cheese', 3, 7.75, 8, 1, '["cheese"]'),
  (10, 'Apples 1 kg', 4, 2.10, 35, 1, '["fresh"]'),
  (11, 'Bananas 1 kg', 4, 1.60, 0, 0, '["fresh"]'),
  (12, 'Strawberries', 4, 3.90, 14, 1, '["fresh", "sweet"]');

INSERT INTO customers (id, name, email, city, joined) VALUES
  (1, 'Ana García', 'ana@example.com', 'Madrid', '2023-01-15'),
  (2, 'Luis Pérez', 'luis@example.com', 'Seville', '2023-03-02'),
  (3, 'Marta López', 'marta@example.com', 'Madrid', '2023-06-20'),
  (4, 'John Smith', 'john@example.com', 'London', '2023-09-11'),
  (5, 'Sofía Ruiz', 'sofia@example.com', 'Valencia', '2024-01-08'),
  (6, 'Pedro Gómez', NULL, 'Seville', '2024-02-14'),
  (7, 'Emma Brown', 'emma@example.com', 'London', '2024-04-30'),
  (8, 'Carlos Díaz', 'carlos@example.com', 'Bilbao', '2024-05-05');

INSERT INTO orders (id, customer_id, ordered, status, total) VALUES
  (1, 1, '2024-03-01', 'shipped', 11.25),
  (2, 2, '2024-03-03', 'shipped', 15.90),
  (3, 1, '2024-03-15', 'paid', 12.90),
  (4, 3, '2024-04-02', 'shipped', 10.50),
  (5, 4, '2024-04-10', 'cancelled', 19.80),
  (6, 5, '2024-05-01', 'paid', 20.50),
  (7, 2, '2024-05-12', 'new', 9.00),
  (8, 7, '2024-05-20', 'shipped', 22.20),
  (9, 1, '2024-06-02', 'new', 10.80),
  (10, 6, '2024-06-05', 'paid', 13.80);

INSERT INTO order_items (id, order_id, product_id, qty, price) VALUES
  (1, 1, 1, 2, 1.20),
  (2, 1, 7, 1, 1.10),
  (3, 1, 9, 1, 7.75),
  (4, 2, 4, 1, 9.90),
  (5, 2, 2, 4, 1.50),
  (6, 3, 5, 2, 4.50),
  (7, 3, 12, 1, 3.90),
  (8, 4, 1, 3, 1.20),
  (9, 4, 8, 2, 2.40),
  (10, 4, 10, 1, 2.10),
  (11, 5, 4, 2, 9.90),
  (12, 6, 3, 1, 2.80),
  (13, 6, 9, 2, 7.75),
  (14, 6, 7, 2, 1.10),
  (15, 7, 2, 6, 1.50),
  (16, 8, 4, 1, 9.90),
  (17, 8, 5, 1, 4.50),
  (18, 8, 12, 2, 3.90),
  (19, 9, 1, 1, 1.20),
  (20, 9, 8, 4, 2.40),
  (21, 10, 10, 2, 2.10),
  (22, 10, 6, 3, 3.20);

INSERT INTO employees (id, name, role, manager_id, salary) VALUES
  (1, 'Laura Martín', 'CEO', NULL, 5200),
  (2, 'Javier Ortiz', 'Store manager', 1, 3400),
  (3, 'Elena Castro', 'Baker', 2, 2100),
  (4, 'Diego Vidal', 'Baker', 2, 2050),
  (5, 'Nuria Sanz', 'Cashier', 2, 1800),
  (6, 'Raúl Moreno', 'Accountant', 1, 2900);

INSERT INTO reviews (id, product_id, rating, comment) VALUES
  (1, 1, 5, 'Crispy and fresh'),
  (2, 1, 4, 'Good value'),
  (3, 2, 5, 'Best in town'),
  (4, 4, 3, 'A bit bitter'),
  (5, 4, 5, NULL),
  (6, 9, 4, 'Strong flavour'),
  (7, 12, 2, 'Not ripe'),
  (8, 12, 4, 'Sweet');
