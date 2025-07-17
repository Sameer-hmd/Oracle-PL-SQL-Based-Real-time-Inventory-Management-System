# Oracle-PL-SQL-Based-Real-time-Inventory-Management-System with Automated Reordering and Reporting 

# Objective: Design and implement a robust, highly optimized inventory management system using Oracle SQL and PL/SQL, focusing on real-time stock updates, automated reorder processes, and comprehensive reporting.

## Key Features & PL/SQL Focus Areas:

## Advanced Data Model:

Design a normalized schema (3NF/BCNF) for Products, Warehouses/Locations, Inventory_Levels, Suppliers, Purchase_Orders, Sales_Orders, Audit_Logs, etc.

Utilize advanced data types, constraints (CHECK, UNIQUE, FK), and indexing strategies.

## Real-time Inventory Updates (Triggers & Procedures):

### AFTER INSERT/UPDATE/DELETE Triggers: 

Implement triggers on Sales_Order_Items and Purchase_Order_Items tables to automatically adjust Inventory_Levels in real-time.

Error Handling: Use EXCEPTION blocks within triggers and procedures to handle insufficient stock, invalid product IDs, etc., ensuring data integrity.

## Concurrency Control: 

Demonstrate understanding of transaction management (COMMIT, ROLLBACK) and locking mechanisms to prevent race conditions in multi-user environments.

## Automated Reordering System (Scheduled Jobs/DBMS_SCHEDULER):

PL/SQL Package for Reordering Logic: Create a PL/SQL package (PKG_INVENTORY_AUTOMATION) containing procedures to:

Identify products below a predefined reorder point (e.g., reorder_threshold attribute in Products table).

Generate Purchase_Order records for these products.

Select appropriate Suppliers based on criteria (e.g., lowest price, fastest delivery).

DBMS_SCHEDULER: Schedule a job (e.g., daily or hourly) to execute the reordering procedure automatically.

## Comprehensive Reporting (Views, Stored Procedures, Functions):

### Materialized Views: 

Create materialized views for frequently accessed aggregate data (e.g., MV_MONTHLY_SALES_BY_PRODUCT, MV_CURRENT_STOCK_VALUE) to improve reporting performance. Implement refresh strategies (e.g., ON COMMIT or scheduled).

### Reporting Procedures/Functions:

A stored procedure to generate a "Stock Movement Report" for a given period, showing all ins and outs.

A function to calculate the "Inventory Turnover Ratio" for a product or category.

A procedure to list "Slow-Moving Inventory" (products with low sales over a period).

Cursor Management: Utilize explicit cursors for complex data retrieval and processing within reporting procedures.

## Audit Trail & Logging (Triggers & PL/SQL):

Implement triggers to log all changes (INSERT, UPDATE, DELETE) to critical tables like Inventory_Levels into an Audit_Logs table, capturing who, what, when, and where.

Use DBMS_OUTPUT for debugging and potentially a custom logging table for application-level messages.

## User Management & Security (Basic):

Create different user roles (e.g., INVENTORY_MANAGER, SALES_CLERK).

Grant appropriate privileges (SELECT, INSERT, UPDATE, DELETE, EXECUTE) on tables, views, and packages to these roles.

## Technologies to Highlight:

Oracle Database: Demonstrate proficiency in Oracle SQL.

PL/SQL: Extensive use of anonymous blocks, stored procedures, functions, packages, triggers, cursors, exception handling, and DBMS_SCHEDULER.

SQL Tuning: Discuss indexing, execution plans (using EXPLAIN PLAN), and query optimization techniques.

Why this project is high-end for a resume:

## Real-world applicability: 

Inventory management is a core business process.

Demonstrates advanced PL/SQL: Utilizes triggers, packages, scheduled jobs, materialized views, and robust error handling.

Focus on performance: Emphasizes SQL tuning and materialized views.

Shows understanding of business logic: Automated reordering, various reports.

Scalability considerations: Implied through efficient design and use of Oracle features.
