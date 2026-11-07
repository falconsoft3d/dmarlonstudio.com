-- Without tables: the numbers 1 to 5 and their factorial
WITH RECURSIVE n (i, factorial) AS (
  SELECT 1, 1::bigint
  UNION ALL
  SELECT i + 1, factorial * (i + 1) FROM n WHERE i < 5
)
SELECT i, factorial FROM n;

-- Walk the org chart from the CEO down, level by level
WITH RECURSIVE chart AS (
  -- Anchor: the employee without a manager
  SELECT id, name, role, 1 AS level, ARRAY[id] AS path
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  -- Recursive part: whoever reports to someone already found
  SELECT e.id, e.name, e.role, c.level + 1, c.path || e.id
  FROM employees e
  JOIN chart c ON e.manager_id = c.id
)
SELECT repeat('· ', level - 1) || name AS employee, role, level, path
FROM chart
ORDER BY path;
