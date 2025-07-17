-- Oracle PL/SQL-Based Real-time Inventory Management System
-- Step 5: Comprehensive Reporting (Views, Stored Procedures, Functions)

-- 1. Regular Views for Simplified Data Access

-- View: V_CUSTOMER_SALES_SUMMARY
-- Provides a summary of each customer's sales orders.
CREATE OR REPLACE VIEW V_CUSTOMER_SALES_SUMMARY AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM
    Customers c
JOIN
    Sales_Orders o ON c.customer_id = o.customer_id
ORDER BY
    c.customer_id, o.order_date DESC;

-- View: V_PRODUCT_SALES_DETAILS
-- Shows details of each product sold in sales orders.
CREATE OR REPLACE VIEW V_PRODUCT_SALES_DETAILS AS
SELECT
    soi.order_item_id,
    soi.order_id,
    so.order_date,
    p.product_id,
    p.product_name,
    c.category_name,
    soi.quantity AS sold_quantity,
    soi.unit_price AS sales_price_per_unit,
    (soi.quantity * soi.unit_price) AS item_total_revenue,
    cust.first_name AS customer_first_name,
    cust.last_name AS customer_last_name
FROM
    Sales_Order_Items soi
JOIN
    Sales_Orders so ON soi.order_id = so.order_id
JOIN
    Products p ON soi.product_id = p.product_id
JOIN
    Categories c ON p.category_id = c.category_id
JOIN
    Customers cust ON so.customer_id = cust.customer_id
ORDER BY
    so.order_date DESC, p.product_name;

-- View: V_CURRENT_INVENTORY_SNAPSHOT
-- Provides a clear view of current stock levels across all warehouses.
CREATE OR REPLACE VIEW V_CURRENT_INVENTORY_SNAPSHOT AS
SELECT
    il.inventory_id,
    p.product_id,
    p.product_name,
    cat.category_name,
    w.warehouse_id,
    w.warehouse_name,
    il.quantity_on_hand,
    p.reorder_threshold,
    il.last_updated,
    CASE
        WHEN il.quantity_on_hand < p.reorder_threshold THEN 'Below Threshold'
        ELSE 'Sufficient'
    END AS stock_status
FROM
    Inventory_Levels il
JOIN
    Products p ON il.product_id = p.product_id
JOIN
    Categories cat ON p.category_id = cat.category_id
JOIN
    Warehouses w ON il.warehouse_id = w.warehouse_id
ORDER BY
    w.warehouse_name, p.product_name;


-- 2. Materialized Views for Performance Optimization

-- Materialized View: MV_MONTHLY_SALES_BY_CATEGORY
-- Aggregates total sales revenue per month per category.
-- This view will be refreshed on commit for real-time updates (suitable for smaller tables or less frequent updates)
CREATE MATERIALIZED VIEW MV_MONTHLY_SALES_BY_CATEGORY
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS
SELECT
    TO_CHAR(so.order_date, 'YYYY-MM') AS sales_month,
    c.category_name,
    SUM(soi.quantity * soi.unit_price) AS total_monthly_revenue,
    COUNT(DISTINCT so.order_id) AS number_of_orders
FROM
    Sales_Orders so
JOIN
    Sales_Order_Items soi ON so.order_id = soi.order_id
JOIN
    Products p ON soi.product_id = p.product_id
JOIN
    Categories c ON p.category_id = c.category_id
WHERE
    so.order_status IN ('Delivered', 'Shipped') -- Only count completed sales
GROUP BY
    TO_CHAR(so.order_date, 'YYYY-MM'),
    c.category_name
ORDER BY
    sales_month, category_name;

-- Materialized View: MV_PRODUCT_PERFORMANCE_SUMMARY
-- Summarizes total quantity sold and revenue for each product.
-- This view will be refreshed on demand (e.g., nightly via DBMS_SCHEDULER) for larger datasets
CREATE MATERIALIZED VIEW MV_PRODUCT_PERFORMANCE_SUMMARY
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    SUM(soi.quantity) AS total_quantity_sold,
    SUM(soi.quantity * soi.unit_price) AS total_product_revenue
FROM
    Sales_Order_Items soi
JOIN
    Products p ON soi.product_id = p.product_id
JOIN
    Categories c ON p.category_id = c.category_id
GROUP BY
    p.product_id, p.product_name, c.category_name
ORDER BY
    total_product_revenue DESC;

-- To manually refresh MV_PRODUCT_PERFORMANCE_SUMMARY:
-- EXEC DBMS_MVIEW.REFRESH('MV_PRODUCT_PERFORMANCE_SUMMARY', 'C');


-- 3. Stored Procedures and Functions for Advanced Reporting

-- Function: F_GET_PRODUCT_INVENTORY_TURNOVER
-- Calculates the inventory turnover ratio for a given product over a period.
-- Formula: Cost of Goods Sold / Average Inventory
-- (Simplified: Total Sales Quantity / Average Quantity on Hand)
CREATE OR REPLACE FUNCTION F_GET_PRODUCT_INVENTORY_TURNOVER (
    p_product_id IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN NUMBER IS
    v_total_sold_quantity NUMBER := 0;
    v_avg_quantity_on_hand NUMBER := 0;
    v_turnover_ratio NUMBER := 0;
BEGIN
    -- Calculate total quantity sold for the product in the period
    SELECT NVL(SUM(soi.quantity), 0)
    INTO v_total_sold_quantity
    FROM Sales_Order_Items soi
    JOIN Sales_Orders so ON soi.order_id = so.order_id
    WHERE soi.product_id = p_product_id
      AND so.order_date BETWEEN p_start_date AND p_end_date
      AND so.order_status IN ('Delivered', 'Shipped');

    -- Calculate average quantity on hand (simplified average from audit logs or current levels)
    -- A more accurate average would involve more complex snapshotting or daily averages.
    -- For this example, let's take the current quantity as a proxy for average.
    SELECT NVL(AVG(quantity_on_hand), 0)
    INTO v_avg_quantity_on_hand
    FROM Inventory_Levels
    WHERE product_id = p_product_id;

    IF v_avg_quantity_on_hand > 0 THEN
        v_turnover_ratio := v_total_sold_quantity / v_avg_quantity_on_hand;
    ELSE
        v_turnover_ratio := 0; -- Avoid division by zero
    END IF;

    RETURN v_turnover_ratio;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in F_GET_PRODUCT_INVENTORY_TURNOVER: ' || SQLERRM);
        RETURN NULL;
END F_GET_PRODUCT_INVENTORY_TURNOVER;
/

-- Procedure: P_GENERATE_STOCK_MOVEMENT_REPORT
-- Generates a report of all inventory movements (sales, purchases, adjustments) for a given period.
CREATE OR REPLACE PROCEDURE P_GENERATE_STOCK_MOVEMENT_REPORT (
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_warehouse_id IN NUMBER DEFAULT NULL -- Optional: Filter by warehouse
) IS
    CURSOR c_movements IS
        SELECT
            al.change_date,
            p.product_name,
            w.warehouse_name,
            al.action_type,
            al.old_value,
            al.new_value,
            al.changed_by,
            al.table_name
        FROM
            Audit_Logs al
        JOIN
            Inventory_Levels il ON al.record_id = il.inventory_id AND al.table_name = 'Inventory_Levels'
        JOIN
            Products p ON il.product_id = p.product_id
        JOIN
            Warehouses w ON il.warehouse_id = w.warehouse_id
        WHERE
            al.change_date BETWEEN p_start_date AND p_end_date
            AND (p_warehouse_id IS NULL OR il.warehouse_id = p_warehouse_id)
        ORDER BY
            al.change_date ASC;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Stock Movement Report (' || TO_CHAR(p_start_date, 'YYYY-MM-DD') || ' to ' || TO_CHAR(p_end_date, 'YYYY-MM-DD') || ') ---');
    IF p_warehouse_id IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('For Warehouse ID: ' || p_warehouse_id);
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('Date', 20) || RPAD('Product', 30) || RPAD('Warehouse', 20) || RPAD('Action', 10) || RPAD('Details', 60) || RPAD('By', 15));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 20, '-') || RPAD('-', 30, '-') || RPAD('-', 20, '-') || RPAD('-', 10, '-') || RPAD('-', 60, '-') || RPAD('-', 15, '-'));

    FOR rec IN c_movements LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(rec.change_date, 'YYYY-MM-DD HH24:MI'), 20) ||
            RPAD(rec.product_name, 30) ||
            RPAD(rec.warehouse_name, 20) ||
            RPAD(rec.action_type, 10) ||
            RPAD(SUBSTR(NVL(rec.old_value || ' -> ' || rec.new_value, 'N/A'), 1, 58), 60) || -- Concatenate old and new values
            RPAD(rec.changed_by, 15)
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------------------------------------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating stock movement report: ' || SQLERRM);
END P_GENERATE_STOCK_MOVEMENT_REPORT;
/

-- Procedure: P_GET_SLOW_MOVING_INVENTORY
-- Identifies products that have had low sales activity over a specified number of days.
CREATE OR REPLACE PROCEDURE P_GET_SLOW_MOVING_INVENTORY (
    p_days_threshold IN NUMBER DEFAULT 90 -- Products with no sales in last 90 days
) IS
    CURSOR c_slow_movers IS
        SELECT
            p.product_id,
            p.product_name,
            c.category_name,
            il.quantity_on_hand,
            NVL(MAX(so.order_date), TO_DATE('1900-01-01', 'YYYY-MM-DD')) AS last_sale_date
        FROM
            Products p
        JOIN
            Inventory_Levels il ON p.product_id = il.product_id
        JOIN
            Categories c ON p.category_id = c.category_id
        LEFT JOIN
            Sales_Order_Items soi ON p.product_id = soi.product_id
        LEFT JOIN
            Sales_Orders so ON soi.order_id = so.order_id AND so.order_status IN ('Delivered', 'Shipped')
        GROUP BY
            p.product_id, p.product_name, c.category_name, il.quantity_on_hand
        HAVING
            NVL(MAX(so.order_date), SYSDATE - p_days_threshold - 1) < SYSDATE - p_days_threshold
        ORDER BY
            last_sale_date ASC;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Slow-Moving Inventory Report (No sales in last ' || p_days_threshold || ' days) ---');
    DBMS_OUTPUT.PUT_LINE(RPAD('Product ID', 12) || RPAD('Product Name', 30) || RPAD('Category', 20) || RPAD('Qty on Hand', 15) || RPAD('Last Sale Date', 20));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 12, '-') || RPAD('-', 30, '-') || RPAD('-', 20, '-') || RPAD('-', 15, '-') || RPAD('-', 20, '-'));

    FOR rec IN c_slow_movers LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.product_id, 12) ||
            RPAD(rec.product_name, 30) ||
            RPAD(rec.category_name, 20) ||
            RPAD(rec.quantity_on_hand, 15) ||
            RPAD(TO_CHAR(rec.last_sale_date, 'YYYY-MM-DD'), 20)
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating slow-moving inventory report: ' || SQLERRM);
END P_GET_SLOW_MOVING_INVENTORY;
/

-- Example Usage:
-- To enable DBMS_OUTPUT in your SQL client (e.g., SQL Developer):
-- SET SERVEROUTPUT ON;

-- SELECT * FROM V_CUSTOMER_SALES_SUMMARY WHERE customer_id = 1;
-- SELECT * FROM V_PRODUCT_SALES_DETAILS WHERE order_id = 10;
-- SELECT * FROM V_CURRENT_INVENTORY_SNAPSHOT WHERE stock_status = 'Below Threshold';

-- SELECT * FROM MV_MONTHLY_SALES_BY_CATEGORY;
-- SELECT * FROM MV_PRODUCT_PERFORMANCE_SUMMARY;

-- SELECT F_GET_PRODUCT_INVENTORY_TURNOVER(p_product_id => 1, p_start_date => SYSDATE - 365, p_end_date => SYSDATE) FROM DUAL;
-- EXEC P_GENERATE_STOCK_MOVEMENT_REPORT(p_start_date => SYSDATE - 30, p_end_date => SYSDATE);
-- EXEC P_GENERATE_STOCK_MOVEMENT_REPORT(p_start_date => SYSDATE - 60, p_end_date => SYSDATE, p_warehouse_id => 1);
-- EXEC P_GET_SLOW_MOVING_INVENTORY(p_days_threshold => 120);

