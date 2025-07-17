-- Oracle PL/SQL-Based Real-time Inventory Management System
-- Step 3: Real-time Inventory Updates (Triggers & Procedures)

-- Trigger 1: TRG_SALES_ITEM_AFTER_INSERT
-- Decreases inventory quantity when a new item is added to a sales order.
CREATE OR REPLACE TRIGGER TRG_SALES_ITEM_AFTER_INSERT
AFTER INSERT ON Sales_Order_Items
FOR EACH ROW
DECLARE
    v_current_stock NUMBER;
    v_warehouse_id NUMBER; -- Assuming a default warehouse for sales deductions for simplicity
    v_product_name VARCHAR2(255);
BEGIN
    -- For simplicity, let's assume sales deductions are always from Warehouse 1 (Main Distribution Center)
    -- In a real-world scenario, you might have logic to determine the warehouse (e.g., nearest, highest stock).
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    -- Get current stock for the product in the specified warehouse
    SELECT quantity_on_hand INTO v_current_stock
    FROM Inventory_Levels
    WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id
    FOR UPDATE OF quantity_on_hand; -- Lock the row to prevent race conditions during update

    -- Check for insufficient stock
    IF v_current_stock < :NEW.quantity THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock for product "' || v_product_name || '" (ID: ' || :NEW.product_id || '). Available: ' || v_current_stock || ', Requested: ' || :NEW.quantity);
    END IF;

    -- Update inventory level
    UPDATE Inventory_Levels
    SET
        quantity_on_hand = quantity_on_hand - :NEW.quantity,
        last_updated = SYSTIMESTAMP
    WHERE
        product_id = :NEW.product_id AND warehouse_id = v_warehouse_id;

    -- Log the change in Audit_Logs
    INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
    VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id),
            'UPDATE', 'Quantity reduced by ' || :NEW.quantity || ' (Sales Order ' || :NEW.order_id || ')',
            'New quantity: ' || (v_current_stock - :NEW.quantity), USER);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
        RAISE_APPLICATION_ERROR(-20002, 'Product "' || v_product_name || '" (ID: ' || :NEW.product_id || ') not found in Main Distribution Center inventory.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'An error occurred during sales item insert: ' || SQLERRM);
END;
/

-- Trigger 2: TRG_SALES_ITEM_AFTER_UPDATE
-- Adjusts inventory when a sales order item's quantity is updated.
CREATE OR REPLACE TRIGGER TRG_SALES_ITEM_AFTER_UPDATE
AFTER UPDATE OF quantity ON Sales_Order_Items
FOR EACH ROW
DECLARE
    v_current_stock NUMBER;
    v_quantity_change NUMBER;
    v_warehouse_id NUMBER;
    v_product_name VARCHAR2(255);
BEGIN
    -- For simplicity, assume updates affect Warehouse 1
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    -- Calculate the change in quantity
    v_quantity_change := :NEW.quantity - :OLD.quantity;

    -- Get current stock for the product in the specified warehouse
    SELECT quantity_on_hand INTO v_current_stock
    FROM Inventory_Levels
    WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id
    FOR UPDATE OF quantity_on_hand;

    IF v_quantity_change > 0 THEN -- Quantity increased (more stock needed)
        IF v_current_stock < v_quantity_change THEN
            SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
            RAISE_APPLICATION_ERROR(-20004, 'Insufficient stock for product "' || v_product_name || '" (ID: ' || :NEW.product_id || ') to increase quantity. Available: ' || v_current_stock || ', Needed: ' || v_quantity_change);
        END IF;
    END IF;

    -- Update inventory level
    UPDATE Inventory_Levels
    SET
        quantity_on_hand = quantity_on_hand - v_quantity_change,
        last_updated = SYSTIMESTAMP
    WHERE
        product_id = :NEW.product_id AND warehouse_id = v_warehouse_id;

    -- Log the change in Audit_Logs
    INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
    VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id),
            'UPDATE', 'Quantity changed from ' || :OLD.quantity || ' to ' || :NEW.quantity || ' (Sales Order ' || :NEW.order_id || ')',
            'New quantity: ' || (v_current_stock - v_quantity_change), USER);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
        RAISE_APPLICATION_ERROR(-20005, 'Product "' || v_product_name || '" (ID: ' || :NEW.product_id || ') not found in Main Distribution Center inventory for update.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'An error occurred during sales item update: ' || SQLERRM);
END;
/

-- Trigger 3: TRG_SALES_ITEM_AFTER_DELETE
-- Increases inventory quantity when a sales order item is deleted (e.g., order cancelled).
CREATE OR REPLACE TRIGGER TRG_SALES_ITEM_AFTER_DELETE
AFTER DELETE ON Sales_Order_Items
FOR EACH ROW
DECLARE
    v_current_stock NUMBER;
    v_warehouse_id NUMBER;
    v_product_name VARCHAR2(255);
BEGIN
    -- For simplicity, assume returns go back to Warehouse 1
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    -- Get current stock
    SELECT quantity_on_hand INTO v_current_stock
    FROM Inventory_Levels
    WHERE product_id = :OLD.product_id AND warehouse_id = v_warehouse_id
    FOR UPDATE OF quantity_on_hand;

    -- Update inventory level (add back deleted quantity)
    UPDATE Inventory_Levels
    SET
        quantity_on_hand = quantity_on_hand + :OLD.quantity,
        last_updated = SYSTIMESTAMP
    WHERE
        product_id = :OLD.product_id AND warehouse_id = v_warehouse_id;

    -- Log the change in Audit_Logs
    INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
    VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :OLD.product_id AND warehouse_id = v_warehouse_id),
            'UPDATE', 'Quantity restored by ' || :OLD.quantity || ' (Sales Order Item Deleted from Order ' || :OLD.order_id || ')',
            'New quantity: ' || (v_current_stock + :OLD.quantity), USER);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :OLD.product_id;
        RAISE_APPLICATION_ERROR(-20007, 'Product "' || v_product_name || '" (ID: ' || :OLD.product_id || ') not found in Main Distribution Center inventory for delete reversal.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'An error occurred during sales item delete: ' || SQLERRM);
END;
/

-- Trigger 4: TRG_PURCHASE_ITEM_AFTER_INSERT
-- Increases inventory quantity when a new item is added to a purchase order (and PO status is 'Received').
CREATE OR REPLACE TRIGGER TRG_PURCHASE_ITEM_AFTER_INSERT
AFTER INSERT ON Purchase_Order_Items
FOR EACH ROW
DECLARE
    v_po_status VARCHAR2(50);
    v_warehouse_id NUMBER; -- Assuming a default warehouse for purchase receipts
    v_product_name VARCHAR2(255);
BEGIN
    -- For simplicity, let's assume purchase receipts are always to Warehouse 1
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    -- Check the status of the parent Purchase Order
    SELECT po_status INTO v_po_status
    FROM Purchase_Orders
    WHERE po_id = :NEW.po_id;

    -- Only update inventory if the PO is already 'Received'
    -- (More robust logic might involve a separate "receive goods" process,
    -- but for real-time update, we'll link it to PO item insertion/update)
    IF v_po_status = 'Received' THEN
        -- Check if inventory entry exists, if not, create it
        MERGE INTO Inventory_Levels il
        USING (SELECT :NEW.product_id AS p_id, v_warehouse_id AS w_id, :NEW.quantity AS qty FROM DUAL) src
        ON (il.product_id = src.p_id AND il.warehouse_id = src.w_id)
        WHEN MATCHED THEN
            UPDATE SET il.quantity_on_hand = il.quantity_on_hand + src.qty, il.last_updated = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (inventory_id, product_id, warehouse_id, quantity_on_hand, last_updated)
            VALUES (inventory_seq.NEXTVAL, src.p_id, src.w_id, src.qty, SYSTIMESTAMP);

        -- Log the change in Audit_Logs
        INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
        VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id),
                'UPDATE', 'Quantity increased by ' || :NEW.quantity || ' (Purchase Order ' || :NEW.po_id || ')',
                'New quantity updated due to PO receipt', USER);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
        RAISE_APPLICATION_ERROR(-20009, 'Product "' || v_product_name || '" (ID: ' || :NEW.product_id || ') or Warehouse not found for purchase item insert.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'An error occurred during purchase item insert: ' || SQLERRM);
END;
/

-- Trigger 5: TRG_PURCHASE_ITEM_AFTER_UPDATE
-- Adjusts inventory when a purchase order item's quantity is updated (and PO status is 'Received').
CREATE OR REPLACE TRIGGER TRG_PURCHASE_ITEM_AFTER_UPDATE
AFTER UPDATE OF quantity ON Purchase_Order_Items
FOR EACH ROW
DECLARE
    v_po_status VARCHAR2(50);
    v_quantity_change NUMBER;
    v_warehouse_id NUMBER;
    v_product_name VARCHAR2(255);
BEGIN
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    SELECT po_status INTO v_po_status
    FROM Purchase_Orders
    WHERE po_id = :NEW.po_id;

    IF v_po_status = 'Received' THEN
        v_quantity_change := :NEW.quantity - :OLD.quantity;

        -- Update inventory level
        UPDATE Inventory_Levels
        SET
            quantity_on_hand = quantity_on_hand + v_quantity_change,
            last_updated = SYSTIMESTAMP
        WHERE
            product_id = :NEW.product_id AND warehouse_id = v_warehouse_id;

        -- Log the change in Audit_Logs
        INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
        VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :NEW.product_id AND warehouse_id = v_warehouse_id),
                'UPDATE', 'Quantity changed from ' || :OLD.quantity || ' to ' || :NEW.quantity || ' (Purchase Order ' || :NEW.po_id || ')',
                'New quantity updated due to PO item update', USER);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :NEW.product_id;
        RAISE_APPLICATION_ERROR(-20011, 'Product "' || v_product_name || '" (ID: ' || :NEW.product_id || ') not found in Main Distribution Center inventory for purchase item update.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'An error occurred during purchase item update: ' || SQLERRM);
END;
/

-- Trigger 6: TRG_PURCHASE_ITEM_AFTER_DELETE
-- Decreases inventory quantity if a purchase order item is deleted AND the PO was 'Received'.
CREATE OR REPLACE TRIGGER TRG_PURCHASE_ITEM_AFTER_DELETE
AFTER DELETE ON Purchase_Order_Items
FOR EACH ROW
DECLARE
    v_po_status VARCHAR2(50);
    v_current_stock NUMBER;
    v_warehouse_id NUMBER;
    v_product_name VARCHAR2(255);
BEGIN
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    SELECT po_status INTO v_po_status
    FROM Purchase_Orders
    WHERE po_id = :OLD.po_id;

    IF v_po_status = 'Received' THEN
        SELECT quantity_on_hand INTO v_current_stock
        FROM Inventory_Levels
        WHERE product_id = :OLD.product_id AND warehouse_id = v_warehouse_id
        FOR UPDATE OF quantity_on_hand;

        IF v_current_stock < :OLD.quantity THEN
            SELECT product_name INTO v_product_name FROM Products WHERE product_id = :OLD.product_id;
            RAISE_APPLICATION_ERROR(-20013, 'Cannot reverse stock for product "' || v_product_name || '" (ID: ' || :OLD.product_id || ') due to insufficient current stock after purchase item deletion. Available: ' || v_current_stock || ', To remove: ' || :OLD.quantity);
        END IF;

        -- Update inventory level (remove previously added quantity)
        UPDATE Inventory_Levels
        SET
            quantity_on_hand = quantity_on_hand - :OLD.quantity,
            last_updated = SYSTIMESTAMP
        WHERE
            product_id = :OLD.product_id AND warehouse_id = v_warehouse_id;

        -- Log the change in Audit_Logs
        INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
        VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = :OLD.product_id AND warehouse_id = v_warehouse_id),
                'UPDATE', 'Quantity reduced by ' || :OLD.quantity || ' (Purchase Order Item Deleted from PO ' || :OLD.po_id || ')',
                'New quantity: ' || (v_current_stock - :OLD.quantity), USER);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT product_name INTO v_product_name FROM Products WHERE product_id = :OLD.product_id;
        RAISE_APPLICATION_ERROR(-20014, 'Product "' || v_product_name || '" (ID: ' || :OLD.product_id || ') not found in Main Distribution Center inventory for purchase item delete reversal.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'An error occurred during purchase item delete: ' || SQLERRM);
END;
/

-- Trigger 7: TRG_PURCHASE_ORDER_STATUS_UPDATE
-- Adjusts inventory when a Purchase Order status changes to 'Received' or from 'Received'.
CREATE OR REPLACE TRIGGER TRG_PURCHASE_ORDER_STATUS_UPDATE
AFTER UPDATE OF po_status ON Purchase_Orders
FOR EACH ROW
DECLARE
    CURSOR c_po_items IS
        SELECT product_id, quantity
        FROM Purchase_Order_Items
        WHERE po_id = :NEW.po_id;
    v_current_stock NUMBER;
    v_warehouse_id NUMBER;
    v_product_name VARCHAR2(255);
BEGIN
    SELECT warehouse_id INTO v_warehouse_id FROM Warehouses WHERE warehouse_name = 'Main Distribution Center';

    -- Scenario 1: PO status changes TO 'Received'
    IF :OLD.po_status != 'Received' AND :NEW.po_status = 'Received' THEN
        FOR item_rec IN c_po_items LOOP
            -- Add stock for each item in the PO
            MERGE INTO Inventory_Levels il
            USING (SELECT item_rec.product_id AS p_id, v_warehouse_id AS w_id, item_rec.quantity AS qty FROM DUAL) src
            ON (il.product_id = src.p_id AND il.warehouse_id = src.w_id)
            WHEN MATCHED THEN
                UPDATE SET il.quantity_on_hand = il.quantity_on_hand + src.qty, il.last_updated = SYSTIMESTAMP
            WHEN NOT MATCHED THEN
                INSERT (inventory_id, product_id, warehouse_id, quantity_on_hand, last_updated)
                VALUES (inventory_seq.NEXTVAL, src.p_id, src.w_id, src.qty, SYSTIMESTAMP);

            -- Log the change
            INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
            VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = item_rec.product_id AND warehouse_id = v_warehouse_id),
                    'UPDATE', 'Quantity increased by ' || item_rec.quantity || ' due to PO ' || :NEW.po_id || ' status change to Received',
                    'New quantity updated', USER);
        END LOOP;

    -- Scenario 2: PO status changes FROM 'Received' to something else (e.g., 'Cancelled' after being received)
    ELSIF :OLD.po_status = 'Received' AND :NEW.po_status != 'Received' THEN
        FOR item_rec IN c_po_items LOOP
            -- Deduct stock for each item in the PO
            SELECT quantity_on_hand INTO v_current_stock
            FROM Inventory_Levels
            WHERE product_id = item_rec.product_id AND warehouse_id = v_warehouse_id
            FOR UPDATE OF quantity_on_hand;

            IF v_current_stock < item_rec.quantity THEN
                SELECT product_name INTO v_product_name FROM Products WHERE product_id = item_rec.product_id;
                RAISE_APPLICATION_ERROR(-20016, 'Cannot reverse stock for product "' || v_product_name || '" (ID: ' || item_rec.product_id || ') due to insufficient current stock when PO ' || :NEW.po_id || ' status changed from Received. Available: ' || v_current_stock || ', To remove: ' || item_rec.quantity);
            END IF;

            UPDATE Inventory_Levels
            SET
                quantity_on_hand = quantity_on_hand - item_rec.quantity,
                last_updated = SYSTIMESTAMP
            WHERE
                product_id = item_rec.product_id AND warehouse_id = v_warehouse_id;

            -- Log the change
            INSERT INTO Audit_Logs (log_id, table_name, record_id, action_type, old_value, new_value, changed_by)
            VALUES (audit_log_seq.NEXTVAL, 'Inventory_Levels', (SELECT inventory_id FROM Inventory_Levels WHERE product_id = item_rec.product_id AND warehouse_id = v_warehouse_id),
                    'UPDATE', 'Quantity reduced by ' || item_rec.quantity || ' due to PO ' || :NEW.po_id || ' status change from Received',
                    'New quantity updated', USER);
        END LOOP;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20017, 'Warehouse not found for PO status update trigger.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20018, 'An error occurred during purchase order status update: ' || SQLERRM);
END;
/
