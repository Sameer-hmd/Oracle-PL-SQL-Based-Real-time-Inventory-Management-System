-- Oracle PL/SQL-Based Real-time Inventory Management System
-- Step 4: Automated Reordering System (Scheduled Jobs/DBMS_SCHEDULER)

-- 1. Create PL/SQL Package Specification (PKG_INVENTORY_AUTOMATION)
-- This package will contain procedures for automated inventory tasks.
CREATE OR REPLACE PACKAGE PKG_INVENTORY_AUTOMATION AS

    -- Procedure to identify low stock products and create purchase orders
    PROCEDURE P_CREATE_REORDER_POS;

    -- Function to get the default warehouse ID
    FUNCTION F_GET_DEFAULT_WAREHOUSE_ID RETURN NUMBER;

END PKG_INVENTORY_AUTOMATION;
/

-- 2. Create PL/SQL Package Body (PKG_INVENTORY_AUTOMATION)
CREATE OR REPLACE PACKAGE BODY PKG_INVENTORY_AUTOMATION AS

    -- Function to get the default warehouse ID
    FUNCTION F_GET_DEFAULT_WAREHOUSE_ID RETURN NUMBER IS
        v_warehouse_id NUMBER;
    BEGIN
        SELECT warehouse_id INTO v_warehouse_id
        FROM Warehouses
        WHERE warehouse_name = 'Main Distribution Center';
        RETURN v_warehouse_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020, 'Default warehouse "Main Distribution Center" not found.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20021, 'Error getting default warehouse ID: ' || SQLERRM);
    END F_GET_DEFAULT_WAREHOUSE_ID;


    -- Procedure to identify low stock products and create purchase orders
    PROCEDURE P_CREATE_REORDER_POS IS
        CURSOR c_low_stock_products IS
            SELECT
                p.product_id,
                p.product_name,
                p.reorder_threshold,
                il.quantity_on_hand,
                p.supplier_id,
                p.price * 0.85 AS estimated_cost_price, -- Estimate cost price as 85% of selling price
                (p.reorder_threshold * 2) AS recommended_order_quantity -- Order double the threshold
            FROM
                Products p
            JOIN
                Inventory_Levels il ON p.product_id = il.product_id
            WHERE
                il.warehouse_id = F_GET_DEFAULT_WAREHOUSE_ID() -- Check only the default warehouse
                AND il.quantity_on_hand < p.reorder_threshold
                AND p.supplier_id IS NOT NULL; -- Ensure a supplier is assigned
        
        v_po_id NUMBER;
        v_default_warehouse_id NUMBER;
        v_po_total_amount DECIMAL(10,2);
        v_product_count NUMBER := 0;

    BEGIN
        DBMS_OUTPUT.PUT_LINE('Starting automated reorder process...');

        v_default_warehouse_id := F_GET_DEFAULT_WAREHOUSE_ID();

        FOR p_rec IN c_low_stock_products LOOP
            v_product_count := v_product_count + 1;
            DBMS_OUTPUT.PUT_LINE('  - Product: ' || p_rec.product_name || ' (ID: ' || p_rec.product_id || ') is below reorder threshold.');
            DBMS_OUTPUT.PUT_LINE('    Current Stock: ' || p_rec.quantity_on_hand || ', Threshold: ' || p_rec.reorder_threshold);

            -- Create a new Purchase Order for each product that needs reordering
            -- In a more complex system, you might group multiple products for the same supplier into one PO.
            INSERT INTO Purchase_Orders (po_id, supplier_id, order_date, expected_delivery_date, po_status)
            VALUES (purchase_order_seq.NEXTVAL, p_rec.supplier_id, SYSTIMESTAMP, SYSDATE + 14, 'Pending') -- Expected delivery in 14 days
            RETURNING po_id INTO v_po_id;

            -- Insert the item into the Purchase_Order_Items
            INSERT INTO Purchase_Order_Items (po_item_id, po_id, product_id, quantity, cost_price)
            VALUES (purchase_order_item_seq.NEXTVAL, v_po_id, p_rec.product_id, p_rec.recommended_order_quantity, p_rec.estimated_cost_price);

            -- Update the total amount for the newly created Purchase Order
            -- This is a simplified approach; in a real system, you might sum up all items for the PO
            v_po_total_amount := p_rec.recommended_order_quantity * p_rec.estimated_cost_price;
            UPDATE Purchase_Orders
            SET total_amount = v_po_total_amount
            WHERE po_id = v_po_id;

            DBMS_OUTPUT.PUT_LINE('    Created Purchase Order ' || v_po_id || ' for ' || p_rec.recommended_order_quantity || ' units at estimated cost ' || p_rec.estimated_cost_price);

            -- Log the reorder action in Audit_Logs
            INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
            VALUES (audit_log_seq.NEXTVAL, 'Purchase_Orders', v_po_id, 'INSERT', NULL,
                    'Automated reorder for Product ID: ' || p_rec.product_id || ', Quantity: ' || p_rec.recommended_order_quantity || ', PO Status: Pending', 'DBMS_SCHEDULER');

        END LOOP;

        IF v_product_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No products found below reorder threshold.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Automated reorder process completed. ' || v_product_count || ' new purchase orders created.');
        END IF;

        COMMIT; -- Commit the changes made by the procedure

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK; -- Rollback if any error occurs
            DBMS_OUTPUT.PUT_LINE('Error in automated reorder process: ' || SQLERRM);
            RAISE; -- Re-raise the exception
    END P_CREATE_REORDER_POS;

END PKG_INVENTORY_AUTOMATION;
/

-- 3. Schedule the Automated Reordering Job using DBMS_SCHEDULER
-- This job will run daily at 3:00 AM.
BEGIN
    -- Drop the job if it already exists to avoid errors when re-running
    DBMS_SCHEDULER.DROP_JOB (
        job_name => 'JOB_AUTO_REORDER_INVENTORY',
        defer    => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -27475 THEN -- ORA-27475: "JOB_AUTO_REORDER_INVENTORY" does not exist
            RAISE;
        END IF;
END;
/

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'JOB_AUTO_REORDER_INVENTORY',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_INVENTORY_AUTOMATION.P_CREATE_REORDER_POS; END;',
        start_date      => SYSTIMESTAMP, -- Start immediately
        repeat_interval => 'FREQ=DAILY; BYHOUR=3; BYMINUTE=0; BYSECOND=0;', -- Run daily at 3:00 AM
        end_date        => NULL, -- Never expire
        enabled         => TRUE,
        comments        => 'Automated job to check inventory levels and create purchase orders for low stock products.'
    );
END;
/

-- Optional: Verify the job status
-- SELECT job_name, state, last_start_date, next_run_date FROM user_scheduler_jobs WHERE job_name = 'JOB_AUTO_REORDER_INVENTORY';
-- SELECT log_date, job_name, status, error# FROM user_scheduler_job_log WHERE job_name = 'JOB_AUTO_REORDER_INVENTORY' ORDER BY log_date DESC;

-- Optional: To manually run the job for testing purposes:
-- BEGIN
--    DBMS_SCHEDULER.RUN_JOB('JOB_AUTO_REORDER_INVENTORY');
-- END;
-- /

-- Optional: To disable the job:
-- BEGIN
--    DBMS_SCHEDULER.DISABLE('JOB_AUTO_REORDER_INVENTORY');
-- END;
-- /

-- Optional: To enable the job:
-- BEGIN
--    DBMS_SCHEDULER.ENABLE('JOB_AUTO_REORDER_INVENTORY');
-- END;
-- /
