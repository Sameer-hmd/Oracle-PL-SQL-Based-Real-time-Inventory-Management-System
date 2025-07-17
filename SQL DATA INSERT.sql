-- Oracle PL/SQL-Based Real-time Inventory Management System
-- Step 2: Populate Tables with Sample Data (Large Dataset)

-- Disable foreign key constraints temporarily for faster data loading
-- This is optional but can speed up large inserts. Remember to enable them later.
ALTER TABLE Products DISABLE CONSTRAINT fk_product_category;
ALTER TABLE Products DISABLE CONSTRAINT fk_product_supplier;
ALTER TABLE Inventory_Levels DISABLE CONSTRAINT fk_inventory_product;
ALTER TABLE Inventory_Levels DISABLE CONSTRAINT fk_inventory_warehouse;
ALTER TABLE Sales_Orders DISABLE CONSTRAINT fk_sales_order_customer;
ALTER TABLE Sales_Order_Items DISABLE CONSTRAINT fk_sales_item_order;
ALTER TABLE Sales_Order_Items DISABLE CONSTRAINT fk_sales_item_product;
ALTER TABLE Purchase_Orders DISABLE CONSTRAINT fk_purchase_order_supplier;
ALTER TABLE Purchase_Order_Items DISABLE CONSTRAINT fk_po_item_po;
ALTER TABLE Purchase_Order_Items DISABLE CONSTRAINT fk_po_item_product;


-- Reset sequences for clean data insertion (optional, if running multiple times)
-- This ensures IDs start from 1 again.
ALTER SEQUENCE category_seq RESTART START WITH 1;
ALTER SEQUENCE product_seq RESTART START WITH 1;
ALTER SEQUENCE warehouse_seq RESTART START WITH 1;
ALTER SEQUENCE supplier_seq RESTART START WITH 1;
ALTER SEQUENCE customer_seq RESTART START WITH 1;
ALTER SEQUENCE sales_order_seq RESTART START WITH 1;
ALTER SEQUENCE sales_order_item_seq RESTART START WITH 1;
ALTER SEQUENCE purchase_order_seq RESTART START WITH 1;
ALTER SEQUENCE purchase_order_item_seq RESTART START WITH 1;
ALTER SEQUENCE audit_log_seq RESTART START WITH 1;


-- 1. Insert data into Categories (7 records)
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Electronics', 'Gadgets, devices, and electronic accessories.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Books', 'Fiction, non-fiction, and educational books.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Home Goods', 'Furniture, decor, and kitchenware.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Apparel', 'Clothing, shoes, and accessories.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Sports & Outdoors', 'Equipment and gear for sports and outdoor activities.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Groceries', 'Food and beverage items.');
INSERT INTO Categories (category_id, category_name, description) VALUES (category_seq.NEXTVAL, 'Health & Beauty', 'Personal care and wellness products.');

-- 2. Insert data into Suppliers (7 records)
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Tech Solutions Inc.', 'John Doe', '111-222-3333', 'john.doe@techsol.com', '100 Tech Blvd, Silicon Valley, CA');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Bookworm Distributors', 'Jane Smith', '222-333-4444', 'jane.smith@bookworm.com', '200 Literary Lane, Booktown, NY');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Home Essentials Co.', 'Robert Johnson', '333-444-5555', 'robert.j@homeessentials.com', '300 Comfort St, Homely, TX');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Fashion Forward Ltd.', 'Emily White', '444-555-6666', 'emily.w@fashionfwd.com', '400 Style Ave, Chic City, FL');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Outdoor Gear Pro', 'Michael Green', '555-666-7777', 'michael.g@outdoorgear.com', '500 Adventure Rd, Wilderness, CO');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Fresh Foods Corp.', 'Sarah Brown', '666-777-8888', 'sarah.b@freshfoods.com', '600 Harvest Way, Farmland, GA');
INSERT INTO Suppliers (supplier_id, supplier_name, contact_person, phone_number, email, address) VALUES (supplier_seq.NEXTVAL, 'Wellness & Glow', 'David Lee', '777-888-9999', 'david.l@wellnessglow.com', '700 Serene Blvd, Healthville, AZ');

-- 3. Insert data into Warehouses (3 records)
INSERT INTO Warehouses (warehouse_id, warehouse_name, location) VALUES (warehouse_seq.NEXTVAL, 'Main Distribution Center', '123 Global Rd, Central City, CA');
INSERT INTO Warehouses (warehouse_id, warehouse_name, location) VALUES (warehouse_seq.NEXTVAL, 'East Coast Hub', '456 Eastern Ave, New York, NY');
INSERT INTO Warehouses (warehouse_id, warehouse_name, location) VALUES (warehouse_seq.NEXTVAL, 'West Coast Depot', '789 Pacific Blvd, Los Angeles, CA');

-- 4. Insert data into Products (30 records)
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Laptop Pro X', 'High-performance laptop with 16GB RAM and 512GB SSD.', 1200.00, 10, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Smartphone Z1', 'Latest model smartphone with advanced camera.', 800.00, 15, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Smart LED TV 55"', '4K UHD Smart TV with HDR.', 750.00, 8, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Wireless Headphones', 'Noise-cancelling headphones with long battery life.', 150.00, 20, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Gaming Console X', 'Next-gen gaming console with stunning graphics.', 500.00, 7, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'The Great Adventure', 'A thrilling fantasy novel.', 25.50, 30, (SELECT category_id FROM Categories WHERE category_name = 'Books'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Bookworm Distributors'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'SQL for Dummies', 'Beginner-friendly guide to SQL.', 35.00, 25, (SELECT category_id FROM Categories WHERE category_name = 'Books'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Bookworm Distributors'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Cooking Masterclass', 'A cookbook with recipes from around the world.', 45.00, 15, (SELECT category_id FROM Categories WHERE category_name = 'Books'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Bookworm Distributors'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'History of the World', 'Comprehensive historical overview.', 50.00, 10, (SELECT category_id FROM Categories WHERE category_name = 'Books'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Bookworm Distributors'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Ergonomic Office Chair', 'Adjustable chair for comfortable long working hours.', 180.00, 10, (SELECT category_id FROM Categories WHERE category_name = 'Home Goods'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Home Essentials Co.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Smart Coffee Maker', 'Brew coffee with your smartphone.', 99.00, 12, (SELECT category_id FROM Categories WHERE category_name = 'Home Goods'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Home Essentials Co.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Robot Vacuum Cleaner', 'Automated cleaning for your home.', 250.00, 5, (SELECT category_id FROM Categories WHERE category_name = 'Home Goods'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Home Essentials Co.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Queen Size Bed Frame', 'Sturdy wooden bed frame.', 350.00, 3, (SELECT category_id FROM Categories WHERE category_name = 'Home Goods'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Home Essentials Co.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Running Shoes V2', 'Lightweight and durable running shoes.', 90.00, 20, (SELECT category_id FROM Categories WHERE category_name = 'Apparel'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fashion Forward Ltd.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Men''s Casual Shirt', '100% cotton, comfortable fit.', 40.00, 50, (SELECT category_id FROM Categories WHERE category_name = 'Apparel'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fashion Forward Ltd.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Women''s Denim Jeans', 'Classic fit, high-quality denim.', 65.00, 40, (SELECT category_id FROM Categories WHERE category_name = 'Apparel'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fashion Forward Ltd.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Leather Wallet', 'Genuine leather wallet with multiple card slots.', 30.00, 30, (SELECT category_id FROM Categories WHERE category_name = 'Apparel'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fashion Forward Ltd.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Yoga Mat Deluxe', 'Premium non-slip yoga mat with carrying strap.', 35.00, 25, (SELECT category_id FROM Categories WHERE category_name = 'Sports & Outdoors'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Outdoor Gear Pro'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Camping Tent 4-Person', 'Waterproof and easy to set up.', 120.00, 5, (SELECT category_id FROM Categories WHERE category_name = 'Sports & Outdoors'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Outdoor Gear Pro'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Hiking Backpack 60L', 'Large capacity backpack for multi-day hikes.', 85.00, 8, (SELECT category_id FROM Categories WHERE category_name = 'Sports & Outdoors'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Outdoor Gear Pro'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Protein Powder 2kg', 'Whey protein isolate, chocolate flavor.', 55.00, 20, (SELECT category_id FROM Categories WHERE category_name = 'Groceries'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fresh Foods Corp.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Organic Coffee Beans', 'Medium roast, 1lb bag.', 18.00, 30, (SELECT category_id FROM Categories WHERE category_name = 'Groceries'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fresh Foods Corp.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Olive Oil Extra Virgin', 'Cold-pressed, 1 liter.', 22.00, 25, (SELECT category_id FROM Categories WHERE category_name = 'Groceries'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Fresh Foods Corp.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Multivitamin Tablets', 'Daily essential vitamins and minerals.', 28.00, 15, (SELECT category_id FROM Categories WHERE category_name = 'Health & Beauty'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Wellness & Glow'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Anti-Aging Serum', 'Reduces wrinkles and fine lines.', 75.00, 10, (SELECT category_id FROM Categories WHERE category_name = 'Health & Beauty'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Wellness & Glow'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Sunscreen SPF 50', 'Broad-spectrum protection.', 20.00, 30, (SELECT category_id FROM Categories WHERE category_name = 'Health & Beauty'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Wellness & Glow'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Electric Toothbrush', 'Advanced cleaning technology.', 60.00, 12, (SELECT category_id FROM Categories WHERE category_name = 'Health & Beauty'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Wellness & Glow'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Bluetooth Speaker', 'Portable speaker with rich sound.', 70.00, 18, (SELECT category_id FROM Categories WHERE category_name = 'Electronics'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Tech Solutions Inc.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Desk Lamp with Wireless Charger', 'Modern lamp with integrated phone charger.', 55.00, 10, (SELECT category_id FROM Categories WHERE category_name = 'Home Goods'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Home Essentials Co.'));
INSERT INTO Products (product_id, product_name, description, price, reorder_threshold, category_id, supplier_id) VALUES (product_seq.NEXTVAL, 'Water Bottle Stainless Steel', 'Insulated bottle for hot and cold drinks.', 25.00, 40, (SELECT category_id FROM Categories WHERE category_name = 'Sports & Outdoors'), (SELECT supplier_id FROM Suppliers WHERE supplier_name = 'Outdoor Gear Pro'));


-- 5. Insert data into Customers (70 records)
DECLARE
    v_first_name VARCHAR2(100);
    v_last_name VARCHAR2(100);
    v_email VARCHAR2(255);
    v_phone_number VARCHAR2(20);
    v_address VARCHAR2(4000);
    v_city VARCHAR2(100);
    v_state VARCHAR2(100);
    v_zip_code VARCHAR2(20);
    v_reg_date TIMESTAMP;
BEGIN
    FOR i IN 1..70 LOOP
        v_first_name := 'CustomerFN' || i;
        v_last_name := 'CustomerLN' || i;
        v_email := 'customer' || i || '@example.com';
        v_phone_number := '555-100-' || LPAD(i, 3, '0');
        v_address := i || ' Main St';
        v_city := CASE MOD(i, 5)
                      WHEN 0 THEN 'New York'
                      WHEN 1 THEN 'Los Angeles'
                      WHEN 2 THEN 'Chicago'
                      WHEN 3 THEN 'Houston'
                      ELSE 'Phoenix'
                  END;
        v_state := CASE MOD(i, 5)
                       WHEN 0 THEN 'NY'
                       WHEN 1 THEN 'CA'
                       WHEN 2 THEN 'IL'
                       WHEN 3 THEN 'TX'
                       ELSE 'AZ'
                   END;
        v_zip_code := LPAD(MOD(i, 99999) + 10000, 5, '0');
        v_reg_date := SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 365)), 'DAY');

        INSERT INTO Customers (customer_id, first_name, last_name, email, phone_number, address, city, state, zip_code, registration_date)
        VALUES (customer_seq.NEXTVAL, v_first_name, v_last_name, v_email, v_phone_number, v_address, v_city, v_state, v_zip_code, v_reg_date);
    END LOOP;
END;
/

-- 6. Insert data into Inventory_Levels (approx 60 records, 2 for each product across 2 warehouses)
DECLARE
    v_product_id NUMBER;
    v_warehouse_id NUMBER;
    v_quantity NUMBER;
BEGIN
    FOR p_rec IN (SELECT product_id FROM Products) LOOP
        FOR w_rec IN (SELECT warehouse_id FROM Warehouses WHERE warehouse_id IN (1, 2)) LOOP -- Distribute across Main and East Coast
            v_product_id := p_rec.product_id;
            v_warehouse_id := w_rec.warehouse_id;
            v_quantity := TRUNC(DBMS_RANDOM.VALUE(50, 200)); -- Random quantity between 50 and 200

            INSERT INTO Inventory_Levels (inventory_id, product_id, warehouse_id, quantity_on_hand)
            VALUES (inventory_seq.NEXTVAL, v_product_id, v_warehouse_id, v_quantity);
        END LOOP;
    END LOOP;
END;
/

-- 7. Insert data into Sales_Orders (70 orders) and Sales_Order_Items (100-150 items)
DECLARE
    v_customer_id NUMBER;
    v_order_date TIMESTAMP;
    v_total_amount DECIMAL(10, 2);
    v_order_status VARCHAR2(50);
    v_order_id NUMBER;
    v_product_id NUMBER;
    v_quantity NUMBER;
    v_unit_price DECIMAL(10, 2);
    v_num_items NUMBER;
BEGIN
    FOR i IN 1..70 LOOP
        SELECT customer_id INTO v_customer_id FROM Customers ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
        v_order_date := SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 180)), 'DAY'); -- Orders from last 6 months
        v_order_status := CASE TRUNC(DBMS_RANDOM.VALUE(1, 6))
                              WHEN 1 THEN 'Pending'
                              WHEN 2 THEN 'Processing'
                              WHEN 3 THEN 'Shipped'
                              WHEN 4 THEN 'Delivered'
                              WHEN 5 THEN 'Cancelled'
                              ELSE 'Refunded'
                          END;
        v_total_amount := 0; -- Will be calculated by items

        INSERT INTO Sales_Orders (order_id, customer_id, order_date, total_amount, order_status)
        VALUES (sales_order_seq.NEXTVAL, v_customer_id, v_order_date, v_total_amount, v_order_status)
        RETURNING order_id INTO v_order_id;

        v_num_items := TRUNC(DBMS_RANDOM.VALUE(1, 4)); -- 1 to 3 items per order
        FOR j IN 1..v_num_items LOOP
            SELECT product_id, price INTO v_product_id, v_unit_price FROM Products ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
            v_quantity := TRUNC(DBMS_RANDOM.VALUE(1, 5)); -- 1 to 4 units of each item

            INSERT INTO Sales_Order_Items (order_item_id, order_id, product_id, quantity, unit_price)
            VALUES (sales_order_item_seq.NEXTVAL, v_order_id, v_product_id, v_quantity, v_unit_price);

            v_total_amount := v_total_amount + (v_quantity * v_unit_price);
        END LOOP;

        -- Update total_amount in Sales_Orders after inserting items
        UPDATE Sales_Orders SET total_amount = v_total_amount WHERE order_id = v_order_id;
    END LOOP;
END;
/

-- 8. Insert data into Purchase_Orders (15 orders) and Purchase_Order_Items (approx 20-30 items)
DECLARE
    v_supplier_id NUMBER;
    v_order_date TIMESTAMP;
    v_expected_delivery_date DATE;
    v_po_status VARCHAR2(50);
    v_po_id NUMBER;
    v_product_id NUMBER;
    v_quantity NUMBER;
    v_cost_price DECIMAL(10, 2);
    v_total_amount DECIMAL(10, 2);
    v_num_items NUMBER;
BEGIN
    FOR i IN 1..15 LOOP
        SELECT supplier_id INTO v_supplier_id FROM Suppliers ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
        v_order_date := SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 90)), 'DAY'); -- POs from last 3 months
        v_expected_delivery_date := TRUNC(v_order_date) + TRUNC(DBMS_RANDOM.VALUE(7, 30)); -- Delivery within 1-4 weeks
        v_po_status := CASE TRUNC(DBMS_RANDOM.VALUE(1, 5))
                           WHEN 1 THEN 'Pending'
                           WHEN 2 THEN 'Ordered'
                           WHEN 3 THEN 'Shipped'
                           WHEN 4 THEN 'Received'
                           ELSE 'Cancelled'
                       END;
        v_total_amount := 0;

        INSERT INTO Purchase_Orders (po_id, supplier_id, order_date, expected_delivery_date, total_amount, po_status)
        VALUES (purchase_order_seq.NEXTVAL, v_supplier_id, v_order_date, v_expected_delivery_date, v_total_amount, v_po_status)
        RETURNING po_id INTO v_po_id;

        v_num_items := TRUNC(DBMS_RANDOM.VALUE(1, 3)); -- 1 to 2 items per PO
        FOR j IN 1..v_num_items LOOP
            SELECT product_id, price * (0.7 + DBMS_RANDOM.VALUE(0, 0.2)) INTO v_product_id, v_cost_price FROM Products ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY; -- Cost price is 70-90% of selling price
            v_quantity := TRUNC(DBMS_RANDOM.VALUE(10, 50)); -- Order 10 to 50 units

            INSERT INTO Purchase_Order_Items (po_item_id, po_id, product_id, quantity, cost_price)
            VALUES (purchase_order_item_seq.NEXTVAL, v_po_id, v_product_id, v_quantity, v_cost_price);

            v_total_amount := v_total_amount + (v_quantity * v_cost_price);
        END LOOP;

        -- Update total_amount in Purchase_Orders after inserting items
        UPDATE Purchase_Orders SET total_amount = v_total_amount WHERE po_id = v_po_id;
    END LOOP;
END;
/

-- Re-enable foreign key constraints
ALTER TABLE Products ENABLE CONSTRAINT fk_product_category;
ALTER TABLE Products ENABLE CONSTRAINT fk_product_supplier;
ALTER TABLE Inventory_Levels ENABLE CONSTRAINT fk_inventory_product;
ALTER TABLE Inventory_Levels ENABLE CONSTRAINT fk_inventory_warehouse;
ALTER TABLE Sales_Orders ENABLE CONSTRAINT fk_sales_order_customer;
ALTER TABLE Sales_Order_Items ENABLE CONSTRAINT fk_sales_item_order;
ALTER TABLE Sales_Order_Items ENABLE CONSTRAINT fk_sales_item_product;
ALTER TABLE Purchase_Orders ENABLE CONSTRAINT fk_purchase_order_supplier;
ALTER TABLE Purchase_Order_Items ENABLE CONSTRAINT fk_po_item_po;
ALTER TABLE Purchase_Order_Items ENABLE CONSTRAINT fk_po_item_product;

-- Commit the changes
COMMIT;

