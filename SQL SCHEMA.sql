-- Oracle PL/SQL-Based Real-time Inventory Management System
-- Step 1: Advanced Data Model (SQL Schema)

-- Drop tables in reverse order to avoid foreign key constraint issues during recreation
-- Use CASCADE CONSTRAINTS to automatically drop dependent foreign key constraints
DROP TABLE Purchase_Order_Items CASCADE CONSTRAINTS;
DROP TABLE Purchase_Orders CASCADE CONSTRAINTS;
DROP TABLE Sales_Order_Items CASCADE CONSTRAINTS;
DROP TABLE Sales_Orders CASCADE CONSTRAINTS;
DROP TABLE Inventory_Levels CASCADE CONSTRAINTS;
DROP TABLE Products CASCADE CONSTRAINTS;
DROP TABLE Categories CASCADE CONSTRAINTS;
DROP TABLE Warehouses CASCADE CONSTRAINTS;
DROP TABLE Suppliers CASCADE CONSTRAINTS;
DROP TABLE Customers CASCADE CONSTRAINTS;
DROP TABLE Audit_Logs CASCADE CONSTRAINTS;

-- Sequence for primary keys
DROP SEQUENCE category_seq;
DROP SEQUENCE product_seq;
DROP SEQUENCE warehouse_seq;
DROP SEQUENCE supplier_seq;
DROP SEQUENCE customer_seq;
DROP SEQUENCE sales_order_seq;
DROP SEQUENCE sales_order_item_seq;
DROP SEQUENCE purchase_order_seq;
DROP SEQUENCE purchase_order_item_seq;
DROP SEQUENCE audit_log_seq;

CREATE SEQUENCE category_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE product_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE warehouse_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE supplier_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE customer_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE sales_order_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE sales_order_item_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE purchase_order_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE purchase_order_item_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE audit_log_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- Table: Categories
-- Stores different product categories.
CREATE TABLE Categories (
    category_id NUMBER(10) PRIMARY KEY,
    category_name VARCHAR2(100) NOT NULL UNIQUE,
    description VARCHAR2(4000)
);

-- Table: Suppliers
-- Stores details of product suppliers.
CREATE TABLE Suppliers (
    supplier_id NUMBER(10) PRIMARY KEY,
    supplier_name VARCHAR2(255) NOT NULL UNIQUE,
    contact_person VARCHAR2(100),
    phone_number VARCHAR2(20),
    email VARCHAR2(255) UNIQUE,
    address VARCHAR2(4000)
);

-- Table: Products
-- Stores information about individual products.
CREATE TABLE Products (
    product_id NUMBER(10) PRIMARY KEY,
    product_name VARCHAR2(255) NOT NULL,
    description VARCHAR2(4000),
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    reorder_threshold NUMBER(10) DEFAULT 10 NOT NULL CHECK (reorder_threshold >= 0), -- Minimum stock level before reordering
    category_id NUMBER(10),
    supplier_id NUMBER(10), -- Primary supplier for reordering
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT fk_product_supplier FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

-- Table: Warehouses
-- Stores information about inventory storage locations.
CREATE TABLE Warehouses (
    warehouse_id NUMBER(10) PRIMARY KEY,
    warehouse_name VARCHAR2(255) NOT NULL UNIQUE,
    location VARCHAR2(4000)
);

-- Table: Inventory_Levels
-- Stores current stock levels for each product in each warehouse.
CREATE TABLE Inventory_Levels (
    inventory_id NUMBER(10) PRIMARY KEY,
    product_id NUMBER(10) NOT NULL,
    warehouse_id NUMBER(10) NOT NULL,
    quantity_on_hand NUMBER(10) NOT NULL CHECK (quantity_on_hand >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_inventory_product_warehouse UNIQUE (product_id, warehouse_id), -- A product can only have one entry per warehouse
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

-- Table: Customers
-- Stores customer details.
CREATE TABLE Customers (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(100) NOT NULL,
    last_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(255) NOT NULL UNIQUE,
    phone_number VARCHAR2(20),
    address VARCHAR2(4000),
    city VARCHAR2(100),
    state VARCHAR2(100),
    zip_code VARCHAR2(20),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Sales_Orders
-- Stores details of customer sales orders.
CREATE TABLE Sales_Orders (
    order_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    order_status VARCHAR2(50) NOT NULL DEFAULT 'Pending' CHECK (order_status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded')),
    CONSTRAINT fk_sales_order_customer FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Table: Sales_Order_Items
-- Stores individual products within a sales order.
CREATE TABLE Sales_Order_Items (
    order_item_id NUMBER(10) PRIMARY KEY,
    order_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity NUMBER(10) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0), -- Price at the time of order
    CONSTRAINT fk_sales_item_order FOREIGN KEY (order_id) REFERENCES Sales_Orders(order_id),
    CONSTRAINT fk_sales_item_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT uk_sales_item UNIQUE (order_id, product_id) -- Ensures a product appears only once per sales order
);

-- Table: Purchase_Orders
-- Stores details of orders placed with suppliers to replenish stock.
CREATE TABLE Purchase_Orders (
    po_id NUMBER(10) PRIMARY KEY,
    supplier_id NUMBER(10) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE,
    total_amount DECIMAL(10, 2) CHECK (total_amount >= 0), -- Can be null initially, updated later
    po_status VARCHAR2(50) NOT NULL DEFAULT 'Pending' CHECK (po_status IN ('Pending', 'Ordered', 'Shipped', 'Received', 'Cancelled')),
    CONSTRAINT fk_purchase_order_supplier FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

-- Table: Purchase_Order_Items
-- Stores individual products within a purchase order.
CREATE TABLE Purchase_Order_Items (
    po_item_id NUMBER(10) PRIMARY KEY,
    po_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity NUMBER(10) NOT NULL CHECK (quantity > 0),
    cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0), -- Cost at the time of purchase order
    CONSTRAINT fk_po_item_po FOREIGN KEY (po_id) REFERENCES Purchase_Orders(po_id),
    CONSTRAINT fk_po_item_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT uk_po_item UNIQUE (po_id, product_id) -- Ensures a product appears only once per purchase order
);

-- Table: Audit_Logs
-- Stores a log of significant changes, especially to inventory levels.
CREATE TABLE Audit_Logs (
    log_id NUMBER(10) PRIMARY KEY,
    table_name VARCHAR2(100) NOT NULL,
    record_id NUMBER(10), -- PK of the record that was changed
    action_type VARCHAR2(10) NOT NULL CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value VARCHAR2(4000),
    new_value VARCHAR2(4000),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR2(100) DEFAULT USER -- Oracle built-in function for current user
);

-- Indexes for performance
CREATE INDEX idx_products_category_id ON Products (category_id);
CREATE INDEX idx_products_supplier_id ON Products (supplier_id);
CREATE INDEX idx_inventory_product_id ON Inventory_Levels (product_id);
CREATE INDEX idx_inventory_warehouse_id ON Inventory_Levels (warehouse_id);
CREATE INDEX idx_customers_email ON Customers (email);
CREATE INDEX idx_sales_orders_customer_id ON Sales_Orders (customer_id);
CREATE INDEX idx_sales_order_items_order_id ON Sales_Order_Items (order_id);
CREATE INDEX idx_sales_order_items_product_id ON Sales_Order_Items (product_id);
CREATE INDEX idx_purchase_orders_supplier_id ON Purchase_Orders (supplier_id);
CREATE INDEX idx_purchase_order_items_po_id ON Purchase_Order_Items (po_id);
CREATE INDEX idx_purchase_order_items_product_id ON Purchase_Order_Items (product_id);
CREATE INDEX idx_audit_logs_table_record ON Audit_Logs (table_name, record_id);
CREATE INDEX idx_audit_logs_change_date ON Audit_Logs (change_date);

