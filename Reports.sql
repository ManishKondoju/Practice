-- Product Stock Status Report
DECLARE
    product_id INT;
    stock_quantity INT;
    reorder_threshold CONSTANT INT := 10; -- Define the reorder threshold
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Stock Quantity | Status');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    FOR product_record IN (
        SELECT p.product_id, p.product_name,
               (SELECT SUM(CASE WHEN i.transaction_type = 'Add' THEN i.quantity
                                WHEN i.transaction_type = 'Remove' THEN -i.quantity
                                ELSE 0 END)
                FROM inventorytransaction i
                WHERE i.product_id = p.product_id) AS stock_quantity
        FROM product p
    ) LOOP
        product_id := product_record.product_id;
        stock_quantity := product_record.stock_quantity;
        IF stock_quantity <= reorder_threshold THEN
            DBMS_OUTPUT.PUT_LINE(product_record.product_id || ' | ' || product_record.product_name || ' | ' || stock_quantity || ' | Low Stock');
        ELSE
            DBMS_OUTPUT.PUT_LINE(product_record.product_id || ' | ' || product_record.product_name || ' | ' || stock_quantity || ' | Sufficient Stock');
        END IF;
    END LOOP;
END;
/

-- Product Sales Summary Report
DECLARE
    product_id INT;
    total_sales INT;
    total_quantity_sold INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Total Quantity Sold | Total Sales');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    FOR product_record IN (
        SELECT p.product_id, p.product_name,
               (SELECT SUM(CASE WHEN i.transaction_type = 'Remove' THEN i.quantity ELSE 0 END)
                FROM inventorytransaction i
                WHERE i.product_id = p.product_id) AS total_quantity_sold,
               (SELECT SUM(CASE WHEN i.transaction_type = 'Remove' THEN i.quantity * p.price ELSE 0 END)
                FROM inventorytransaction i
                WHERE i.product_id = p.product_id) AS total_sales
        FROM product p
    ) LOOP
        product_id := product_record.product_id;
        total_quantity_sold := product_record.total_quantity_sold;
        total_sales := product_record.total_sales;
        DBMS_OUTPUT.PUT_LINE(product_record.product_id || ' | ' || product_record.product_name || ' | ' || total_quantity_sold || ' | ' || total_sales);
    END LOOP;
END;
/

-- Inventory Transaction History Report
DECLARE
    product_id INT;
    transaction_type VARCHAR2(10);
    transaction_date DATE;
    quantity INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Transaction Type | Quantity | Transaction Date');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    FOR transaction_record IN (
        SELECT i.product_id, i.transaction_type, i.quantity, i.transaction_date
        FROM inventorytransaction i
        ORDER BY i.transaction_date DESC
    ) LOOP
        product_id := transaction_record.product_id;
        transaction_type := transaction_record.transaction_type;
        quantity := transaction_record.quantity;
        transaction_date := transaction_record.transaction_date;
        DBMS_OUTPUT.PUT_LINE(product_id || ' | ' || transaction_type || ' | ' || quantity || ' | ' || transaction_date);
    END LOOP;
END;
/

-- Product Inventory Value Report
DECLARE
    product_id INT;
    stock_quantity INT;
    product_price DECIMAL(10, 2);
    inventory_value DECIMAL(10, 2);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Stock Quantity | Price | Inventory Value');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------');
    FOR product_record IN (
        SELECT p.product_id, p.product_name,
               (SELECT SUM(CASE WHEN i.transaction_type = 'Add' THEN i.quantity
                                WHEN i.transaction_type = 'Remove' THEN -i.quantity
                                ELSE 0 END)
                FROM inventorytransaction i
                WHERE i.product_id = p.product_id) AS stock_quantity,
               p.price
        FROM product p
    ) LOOP
        product_id := product_record.product_id;
        stock_quantity := product_record.stock_quantity;
        product_price := product_record.price;
        inventory_value := stock_quantity * product_price;
        DBMS_OUTPUT.PUT_LINE(product_record.product_id || ' | ' || product_record.product_name || ' | ' || stock_quantity || ' | ' || product_price || ' | ' || inventory_value);
    END LOOP;
END;
/

-- Customer Order Summary Report
DECLARE
    total_orders INT;
    total_order_value DECIMAL(10, 2);
    total_items_ordered INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Customer ID | Total Orders | Total Order Value | Total Items Ordered');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------');
    FOR customer_record IN (
        SELECT o.customer_id,
               COUNT(o.order_id) AS total_orders,
               SUM(o.total_amount) AS total_order_value,
               SUM(oi.quantity) AS total_items_ordered
        FROM Orders o
        JOIN OrderItems oi ON o.order_id = oi.order_id
        GROUP BY o.customer_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(customer_record.customer_id || ' | ' || customer_record.total_orders || ' | ' || customer_record.total_order_value || ' | ' || customer_record.total_items_ordered);
    END LOOP;
END;
/

-- Order delivery status report
DECLARE
    order_id INT;
    customer_id INT;
    order_status VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Order ID | Customer ID | Order Status');
    DBMS_OUTPUT.PUT_LINE('------------------------------------');
    FOR order_record IN (
        SELECT o.order_id, o.customer_id, o.status -- Update to correct column name
        FROM orders o
    ) LOOP
        order_id := order_record.order_id;
        customer_id := order_record.customer_id;
        order_status := order_record.status; -- Update to correct column name
        DBMS_OUTPUT.PUT_LINE(order_id || ' | ' || customer_id || ' | ' || order_status);
    END LOOP;
END;
/

-- Top selling products report
DECLARE
    product_id INT;
    total_quantity_sold INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Total Quantity Sold');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    FOR product_record IN (
        SELECT p.product_id, p.product_name,
               NVL((SELECT SUM(CASE WHEN i.transaction_type = 'Remove' THEN i.quantity ELSE 0 END)
                    FROM inventorytransaction i
                    WHERE i.product_id = p.product_id), 0) AS total_quantity_sold
        FROM product p
    ) LOOP
        product_id := product_record.product_id;
        total_quantity_sold := product_record.total_quantity_sold;
        DBMS_OUTPUT.PUT_LINE(product_record.product_id || ' | ' || product_record.product_name || ' | ' || total_quantity_sold);
    END LOOP;
END;
/

-- Products with recent transactions
DECLARE
    product_id INT;
    product_name VARCHAR2(100);
    total_added INT;
    total_removed INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Total Quantity Added | Total Quantity Removed');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------');
    FOR transaction_record IN (
        SELECT p.product_id, p.product_name,
               NVL(SUM(CASE WHEN UPPER(i.transaction_type) = 'ADD' THEN i.quantity ELSE 0 END), 0) AS total_added,
               NVL(SUM(CASE WHEN UPPER(i.transaction_type) = 'REMOVE' THEN i.quantity ELSE 0 END), 0) AS total_removed
        FROM product p
        LEFT JOIN inventorytransaction i
            ON p.product_id = i.product_id
        GROUP BY p.product_id, p.product_name
    ) LOOP
        product_id := transaction_record.product_id;
        product_name := transaction_record.product_name;
        total_added := transaction_record.total_added;
        total_removed := transaction_record.total_removed;
        DBMS_OUTPUT.PUT_LINE(product_id || ' | ' || product_name || ' | ' || total_added || ' | ' || total_removed);
    END LOOP;
END;
/

-- Customer order frequency report
DECLARE
    customer_id INT;
    total_orders INT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Customer ID | Total Orders');
    DBMS_OUTPUT.PUT_LINE('----------------------------');
    FOR order_record IN (
        SELECT o.customer_id, COUNT(o.order_id) AS total_orders
        FROM orders o
        GROUP BY o.customer_id
    ) LOOP
        customer_id := order_record.customer_id;
        total_orders := order_record.total_orders;
        DBMS_OUTPUT.PUT_LINE(customer_id || ' | ' || total_orders);
    END LOOP;
END;
/

-- Product sales performance
DECLARE
    product_id INT;
    product_name VARCHAR2(100);
    total_sales_value DECIMAL(10, 2);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Product ID | Product Name | Total Sales Value');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    
    -- Loop through each product and calculate total sales value
    FOR sales_record IN (
        SELECT p.product_id, p.product_name,
               -- Calculate the total sales value by multiplying quantity sold with price
               COALESCE(SUM(CASE WHEN i.transaction_type = 'Remove' THEN i.quantity * p.price ELSE 0 END), 0) AS total_sales_value
        FROM product p
        LEFT JOIN inventorytransaction i
            ON p.product_id = i.product_id
        GROUP BY p.product_id, p.product_name
    ) LOOP
        product_id := sales_record.product_id;
        product_name := sales_record.product_name;
        total_sales_value := sales_record.total_sales_value;
        
        -- Output the results
        DBMS_OUTPUT.PUT_LINE(product_id || ' | ' || product_name || ' | ' || total_sales_value);
    END LOOP;
END;
/