DELIMITER //
CREATE PROCEDURE customer_stats(
  IN  p_city   VARCHAR(60),
  OUT p_orders INT,
  OUT p_total  DECIMAL(10,2)
)
BEGIN
  SELECT COUNT(*), COALESCE(SUM(o.total), 0)
    INTO p_orders, p_total
  FROM orders o
  JOIN customers c ON c.id = o.customer_id
  WHERE c.city = p_city AND o.status <> 'cancelled';
END //
DELIMITER ;

-- The results come back in session variables (@...)
CALL customer_stats('Madrid', @madrid_orders, @madrid_total);
CALL customer_stats('London', @london_orders, @london_total);

SELECT @madrid_orders AS madrid_orders, @madrid_total AS madrid_total,
       @london_orders AS london_orders, @london_total AS london_total;
