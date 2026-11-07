-- The org chart: start at the top and go down one level each time
WITH RECURSIVE chart(id, name, role, level, path) AS (
  SELECT id, name, role, 0, name
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.name, e.role, chart.level + 1,
         chart.path || ' > ' || e.name
  FROM employees AS e
  JOIN chart ON e.manager_id = chart.id
)
SELECT
  substr('        ', 1, level * 4) || name AS employee,
  role,
  level,
  path
FROM chart
ORDER BY path;
