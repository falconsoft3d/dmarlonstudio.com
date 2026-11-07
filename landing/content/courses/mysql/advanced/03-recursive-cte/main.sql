-- Walk the employee tree from the CEO down
WITH RECURSIVE chart AS (
  -- Anchor: whoever has no manager
  SELECT id, name, role, manager_id, 0 AS level,
         CAST(name AS CHAR(200)) AS path
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  -- Step: the people who report to someone already in the chart
  SELECT e.id, e.name, e.role, e.manager_id, c.level + 1,
         CONCAT(c.path, ' > ', e.name)
  FROM employees e
  JOIN chart c ON e.manager_id = c.id
)
SELECT CONCAT(REPEAT('    ', level), name) AS employee,
       role,
       level,
       path
FROM chart
ORDER BY path;
