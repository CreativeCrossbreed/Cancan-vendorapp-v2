-- ============================================
-- DEMO DATA FOR CAN CAN VENDOR APP
-- ============================================
-- This script creates a complete test environment with:
-- - Demo vendor (phone: 1111111111)
-- - Sample customers
-- - Sample orders with various statuses
-- - Sample products and inventory
-- - Sample payments and wallet data
--
-- RUN THIS IN SUPABASE SQL EDITOR
-- ============================================

-- ============================================
-- STEP 1: CREATE DEMO VENDOR (phone: 1111111111)
-- ============================================

-- First, create an auth user for the demo vendor
-- NOTE: This may need to be done via Supabase Auth UI or API
-- The user_id below will be used - replace with actual auth user ID after creating via Auth

-- For now, we'll use a fixed UUID for the demo vendor
-- This matches the dev mode phone 1111111111
DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Delete existing demo data first (clean slate)
    DELETE FROM orders WHERE vendor_id = demo_vendor_id;
    DELETE FROM vendor_products WHERE vendor_id = demo_vendor_id;
    DELETE FROM vendor_wallets WHERE vendor_id = demo_vendor_id;
    DELETE FROM vendors WHERE id = demo_vendor_id;

    -- Insert demo vendor
    INSERT INTO vendors (
        id,
        user_id,
        business_name,
        owner_name,
        phone,
        email,
        address,
        flat_number,
        floor,
        building_name,
        landmark,
        latitude,
        longitude,
        city,
        state,
        pincode,
        is_active,
        is_verified,
        verification_status,
        onboarding_status,
        rating,
        total_orders,
        completed_orders,
        commission_rate,
        service_radius_km,
        accepts_cod,
        accepts_online_payment
    ) VALUES (
        demo_vendor_id,
        demo_vendor_id, -- In production, this would be the actual auth.users.id
        'Can Can Water Supplies - Demo',
        'Demo Vendor',
        '1111111111',
        'demo@cancan.com',
        '123 Main Street, Koramangala',
        'A-101',
        '1st',
        'Royal Apartments',
        'Near Sony Signal',
        12.9352,
        77.6245,
        'Bangalore',
        'Karnataka',
        '560034',
        true,
        true,
        'verified',
        'completed',
        4.5,
        150,
        145,
        10.0,
        5,
        true,
        true
    ) ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Demo vendor created with phone: 1111111111';
END $$;

-- ============================================
-- STEP 2: CREATE SAMPLE PRODUCTS
-- ============================================

DO $$
BEGIN
    -- Insert sample water can products
    INSERT INTO products (id, name, description, category, sku, capacity_ml, is_active) VALUES
        ('10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 'Premium 20 liter Bisleri mineral water can', 'water_can', 'BISLERI-20L', 20000, true),
        ('10000000-0000-0000-0000-000000000002', '20L Aquafina Water Can', '20 liter Aquafina purified drinking water can', 'water_can', 'AQUAFINA-20L', 20000, true),
        ('10000000-0000-0000-0000-000000000003', '20L Kinley Water Can', '20 liter Kinley mineral water can', 'water_can', 'KINLEY-20L', 20000, true),
        ('10000000-0000-0000-0000-000000000004', '20L Local Mineral Water', '20 liter local mineral water can', 'water_can', 'LOCAL-20L', 20000, true)
    ON CONFLICT (sku) DO NOTHING;

    RAISE NOTICE 'Sample products created';
END $$;

-- ============================================
-- STEP 3: CREATE VENDOR PRODUCTS (INVENTORY)
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Clear existing vendor products
    DELETE FROM vendor_products WHERE vendor_id = demo_vendor_id;

    -- Insert vendor products with pricing and stock
    INSERT INTO vendor_products (vendor_id, product_id, selling_price, deposit_amount, current_stock, low_stock_threshold, is_available) VALUES
        (demo_vendor_id, '10000000-0000-0000-0000-000000000001', 50.00, 20.00, 150, 20, true), -- Bisleri
        (demo_vendor_id, '10000000-0000-0000-0000-000000000002', 45.00, 20.00, 200, 25, true), -- Aquafina
        (demo_vendor_id, '10000000-0000-0000-0000-000000000003', 40.00, 20.00, 180, 20, true), -- Kinley
        (demo_vendor_id, '10000000-0000-0000-0000-000000000004', 25.00, 15.00, 100, 15, true)  -- Local
    ON CONFLICT (vendor_id, product_id) DO NOTHING;

    RAISE NOTICE 'Vendor products/inventory created';
END $$;

-- ============================================
-- STEP 4: CREATE SAMPLE CUSTOMERS
-- ============================================

DO $$
BEGIN
    -- Clear existing demo customers
    DELETE FROM customers WHERE phone LIKE '99%';

    -- Insert sample customers
    INSERT INTO customers (id, phone, name, email, address, flat_number, floor, building_name, city, state, pincode, latitude, longitude, is_active, verification_status) VALUES
        ('20000000-0000-0000-0000-000000000001', '9988776651', 'Rahul Sharma', 'rahul@email.com', '45 Park Street, Indiranagar', 'B-202', '2nd', 'Park View Apartments', 'Bangalore', 'Karnataka', '560038', 12.9784, 77.6408, true, 'verified'),
        ('20000000-0000-0000-0000-000000000002', '9988776652', 'Priya Patel', 'priya@email.com', '78 MG Road', 'A-12', '3rd', 'MG Plaza', 'Bangalore', 'Karnataka', '560001', 12.9756, 77.6066, true, 'verified'),
        ('20000000-0000-0000-0000-000000000003', '9988776653', 'Amit Kumar', 'amit@email.com', '12 Commercial Street, Shivajinagar', 'C-101', '1st', 'Commercial Hub', 'Bangalore', 'Karnataka', '560042', 12.9814, 77.6039, true, 'verified'),
        ('20000000-0000-0000-0000-000000000004', '9988776654', 'Sneha Reddy', 'sneha@email.com', '56 Residency Road, Frazer Town', 'D-303', '3rd', 'Frazer Residency', 'Bangalore', 'Karnataka', '560005', 12.9943, 77.6097, true, 'verified'),
        ('20000000-0000-0000-0000-000000000005', '9988776655', 'Vikram Singh', 'vikram@email.com', '23 Brigade Road', 'E-501', '5th', 'Brigate Towers', 'Bangalore', 'Karnataka', '560025', 12.9736, 77.6125, true, 'verified'),
        ('20000000-0000-0000-0000-000000000006', '9988776656', 'Neha Gupta', 'neha@email.com', '89 Church Street', 'F-201', '2nd', 'Church Street Homes', 'Bangalore', 'Karnataka', '560001', 12.9773, 77.6053, true, 'verified'),
        ('20000000-0000-0000-0000-000000000007', '9988776657', 'Rajesh Kumar', 'rajesh@email.com', '34 Infantry Road', 'G-101', 'Ground', 'Infantry Apartments', 'Bangalore', 'Karnataka', '560001', 12.9831, 77.6014, true, 'verified'),
        ('20000000-0000-0000-0000-000000000008', '9988776658', 'Anita Desai', 'anita@email.com', '67 St. Marks Road', 'H-402', '4th', 'St. Marks Residency', 'Bangalore', 'Karnataka', '560001', 12.9761, 77.6028, true, 'verified')
    ON CONFLICT (phone) DO NOTHING;

    RAISE NOTICE 'Sample customers created';
END $$;

-- ============================================
-- STEP 5: CREATE SAMPLE ORDERS
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
    today_date DATE := CURRENT_DATE;
    yesterday_date DATE := CURRENT_DATE - INTERVAL '1 day';
    two_days_ago DATE := CURRENT_DATE - INTERVAL '2 days';
    three_days_ago DATE := CURRENT_DATE - INTERVAL '3 days';
    week_ago DATE := CURRENT_DATE - INTERVAL '7 days';
BEGIN
    -- Clear existing demo orders
    DELETE FROM orders WHERE vendor_id = demo_vendor_id;

    -- TODAY'S ORDERS (Mixed statuses)

    -- 1. Pending order - just received
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000001', 'ORD-2024-001',
        '20000000-0000-0000-0000-000000000001', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000001", "product_name": "20L Bisleri Water Can", "quantity": 2, "unit_price": 50.00, "subtotal": 100.00}]',
        '{"address": "45 Park Street, Indiranagar", "flat_number": "B-202", "floor": "2nd", "building_name": "Park View Apartments", "landmark": "Near Cafe Coffee Day"}',
        today_date, 'Morning (7AM - 10AM)',
        'pending', 'pending', 100.00, 0.00, 100.00,
        now() - INTERVAL '30 minutes'
    );

    -- 2. Confirmed order
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000002', 'ORD-2024-002',
        '20000000-0000-0000-0000-000000000002', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000002", "product_name": "20L Aquafina Water Can", "quantity": 3, "unit_price": 45.00, "subtotal": 135.00}]',
        '{"address": "78 MG Road", "flat_number": "A-12", "floor": "3rd", "building_name": "MG Plaza"}',
        today_date, 'Afternoon (12PM - 3PM)',
        'confirmed', 'paid', 135.00, 0.00, 135.00,
        now() - INTERVAL '2 hours', now() - INTERVAL '1 hour'
    );

    -- 3. Out for delivery
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, out_for_delivery_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000003', 'ORD-2024-003',
        '20000000-0000-0000-0000-000000000003', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000003", "product_name": "20L Kinley Water Can", "quantity": 1, "unit_price": 40.00, "subtotal": 40.00}]',
        '{"address": "12 Commercial Street, Shivajinagar", "flat_number": "C-101", "floor": "1st", "building_name": "Commercial Hub"}',
        today_date, 'Evening (5PM - 8PM)',
        'out_for_delivery', 'paid', 40.00, 0.00, 40.00,
        now() - INTERVAL '4 hours', now() - INTERVAL '3.5 hours', now() - INTERVAL '1 hour'
    );

    -- 4. Delivered order (today)
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, out_for_delivery_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000004', 'ORD-2024-004',
        '20000000-0000-0000-0000-000000000004', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000001", "product_name": "20L Bisleri Water Can", "quantity": 5, "unit_price": 50.00, "subtotal": 250.00}]',
        '{"address": "56 Residency Road, Frazer Town", "flat_number": "D-303", "floor": "3rd", "building_name": "Frazer Residency"}',
        today_date, 'Morning (7AM - 10AM)',
        'delivered', 'paid', 250.00, 0.00, 250.00,
        now() - INTERVAL '6 hours', now() - INTERVAL '5.5 hours', now() - INTERVAL '3 hours', now() - INTERVAL '2 hours'
    );

    -- 5. Another delivered order (today)
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000005', 'ORD-2024-005',
        '20000000-0000-0000-0000-000000000005', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000004", "product_name": "20L Local Mineral Water", "quantity": 4, "unit_price": 25.00, "subtotal": 100.00}]',
        '{"address": "23 Brigade Road", "flat_number": "E-501", "floor": "5th", "building_name": "Brigate Towers"}',
        today_date, 'Morning (7AM - 10AM)',
        'delivered', 'paid', 100.00, 0.00, 100.00,
        now() - INTERVAL '8 hours', now() - INTERVAL '7.5 hours', now() - INTERVAL '5 hours'
    );

    -- YESTERDAY'S ORDERS

    -- 6. Delivered yesterday
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000006', 'ORD-2024-006',
        '20000000-0000-0000-0000-000000000006', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000001", "product_name": "20L Bisleri Water Can", "quantity": 2, "unit_price": 50.00, "subtotal": 100.00}]',
        '{"address": "89 Church Street", "flat_number": "F-201", "floor": "2nd", "building_name": "Church Street Homes"}',
        yesterday_date, 'Evening (5PM - 8PM)',
        'delivered', 'paid', 100.00, 0.00, 100.00,
        yesterday_date + INTERVAL '9 hours', yesterday_date + INTERVAL '9.5 hours', yesterday_date + INTERVAL '13 hours'
    );

    -- 7. Delivered yesterday
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000007', 'ORD-2024-007',
        '20000000-0000-0000-0000-000000000007', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000002", "product_name": "20L Aquafina Water Can", "quantity": 6, "unit_price": 45.00, "subtotal": 270.00}]',
        '{"address": "34 Infantry Road", "flat_number": "G-101", "floor": "Ground", "building_name": "Infantry Apartments"}',
        yesterday_date, 'Afternoon (12PM - 3PM)',
        'delivered', 'paid', 270.00, 0.00, 270.00,
        yesterday_date + INTERVAL '11 hours', yesterday_date + INTERVAL '11.5 hours', yesterday_date + INTERVAL '14 hours'
    );

    -- 8. Cancelled yesterday
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, cancelled_at, cancellation_reason
    ) VALUES (
        '30000000-0000-0000-0000-000000000008', 'ORD-2024-008',
        '20000000-0000-0000-0000-000000000008', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000003", "product_name": "20L Kinley Water Can", "quantity": 2, "unit_price": 40.00, "subtotal": 80.00}]',
        '{"address": "67 St. Marks Road", "flat_number": "H-402", "floor": "4th", "building_name": "St. Marks Residency"}',
        yesterday_date, 'Evening (5PM - 8PM)',
        'cancelled', 'refunded', 80.00, 0.00, 80.00,
        yesterday_date + INTERVAL '14 hours', yesterday_date + INTERVAL '16 hours', 'Customer requested cancellation'
    );

    -- 2 DAYS AGO

    -- 9. Delivered 2 days ago
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000009', 'ORD-2024-009',
        '20000000-0000-0000-0000-000000000001', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000001", "product_name": "20L Bisleri Water Can", "quantity": 3, "unit_price": 50.00, "subtotal": 150.00}]',
        '{"address": "45 Park Street, Indiranagar", "flat_number": "B-202", "floor": "2nd", "building_name": "Park View Apartments"}',
        two_days_ago, 'Morning (7AM - 10AM)',
        'delivered', 'paid', 150.00, 0.00, 150.00,
        two_days_ago + INTERVAL '8 hours', two_days_ago + INTERVAL '8.5 hours', two_days_ago + INTERVAL '11 hours'
    );

    -- 10. Delivered 2 days ago
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000010', 'ORD-2024-010',
        '20000000-0000-0000-0000-000000000003', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000004", "product_name": "20L Local Mineral Water", "quantity": 10, "unit_price": 25.00, "subtotal": 250.00}]',
        '{"address": "12 Commercial Street, Shivajinagar", "flat_number": "C-101", "floor": "1st", "building_name": "Commercial Hub"}',
        two_days_ago, 'Evening (5PM - 8PM)',
        'delivered', 'paid', 250.00, 0.00, 250.00,
        two_days_ago + INTERVAL '14 hours', two_days_ago + INTERVAL '14.5 hours', two_days_ago + INTERVAL '17 hours'
    );

    -- 3 DAYS AGO

    -- 11. Delivered 3 days ago
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000011', 'ORD-2024-011',
        '20000000-0000-0000-0000-000000000004', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000002", "product_name": "20L Aquafina Water Can", "quantity": 2, "unit_price": 45.00, "subtotal": 90.00}]',
        '{"address": "56 Residency Road, Frazer Town", "flat_number": "D-303", "floor": "3rd", "building_name": "Frazer Residency"}',
        three_days_ago, 'Afternoon (12PM - 3PM)',
        'delivered', 'paid', 90.00, 0.00, 90.00,
        three_days_ago + INTERVAL '10 hours', three_days_ago + INTERVAL '10.5 hours', three_days_ago + INTERVAL '13 hours'
    );

    -- 1 WEEK AGO

    -- 12. Delivered 1 week ago
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000012', 'ORD-2024-012',
        '20000000-0000-0000-0000-000000000005', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000001", "product_name": "20L Bisleri Water Can", "quantity": 4, "unit_price": 50.00, "subtotal": 200.00}]',
        '{"address": "23 Brigade Road", "flat_number": "E-501", "floor": "5th", "building_name": "Brigate Towers"}',
        week_ago, 'Morning (7AM - 10AM)',
        'delivered', 'paid', 200.00, 0.00, 200.00,
        week_ago + INTERVAL '7 hours', week_ago + INTERVAL '7.5 hours', week_ago + INTERVAL '10 hours'
    );

    -- 13. Delivered 1 week ago
    INSERT INTO orders (
        id, order_number, customer_id, vendor_id,
        order_items, delivery_address, delivery_date, delivery_time_slot,
        status, payment_status, subtotal, delivery_fee, total_amount,
        created_at, confirmed_at, delivered_at
    ) VALUES (
        '30000000-0000-0000-0000-000000000013', 'ORD-2024-013',
        '20000000-0000-0000-0000-000000000006', demo_vendor_id,
        '[{"product_id": "10000000-0000-0000-0000-000000000003", "product_name": "20L Kinley Water Can", "quantity": 5, "unit_price": 40.00, "subtotal": 200.00}]',
        '{"address": "89 Church Street", "flat_number": "F-201", "floor": "2nd", "building_name": "Church Street Homes"}',
        week_ago, 'Evening (5PM - 8PM)',
        'delivered', 'paid', 200.00, 0.00, 200.00,
        week_ago + INTERVAL '15 hours', week_ago + INTERVAL '15.5 hours', week_ago + INTERVAL '18 hours'
    );

    RAISE NOTICE 'Sample orders created (13 orders total)';
END $$;

-- ============================================
-- STEP 6: CREATE ORDER ITEMS TABLE ENTRIES
-- ============================================

-- The order_items table is referenced in queries but not in the main schema
-- This creates the table and populates it for the app to work properly

DO $$
BEGIN
    -- Create order_items table if not exists
    CREATE TABLE IF NOT EXISTS order_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
        product_id UUID REFERENCES products(id) ON DELETE SET NULL,
        product_name VARCHAR(255),
        quantity INTEGER NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        subtotal DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

    -- Clear existing demo order items
    DELETE FROM order_items WHERE order_id LIKE '30000000-%';

    -- Populate order_items based on orders
    INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
        -- Order 001
        ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 2, 50.00, 100.00),
        -- Order 002
        ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '20L Aquafina Water Can', 3, 45.00, 135.00),
        -- Order 003
        ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', '20L Kinley Water Can', 1, 40.00, 40.00),
        -- Order 004
        ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 5, 50.00, 250.00),
        -- Order 005
        ('40000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000004', '20L Local Mineral Water', 4, 25.00, 100.00),
        -- Order 006
        ('40000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 2, 50.00, 100.00),
        -- Order 007
        ('40000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', '20L Aquafina Water Can', 6, 45.00, 270.00),
        -- Order 008
        ('40000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', '20L Kinley Water Can', 2, 40.00, 80.00),
        -- Order 009
        ('40000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 3, 50.00, 150.00),
        -- Order 010
        ('40000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000004', '20L Local Mineral Water', 10, 25.00, 250.00),
        -- Order 011
        ('40000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000002', '20L Aquafina Water Can', 2, 45.00, 90.00),
        -- Order 012
        ('40000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000001', '20L Bisleri Water Can', 4, 50.00, 200.00),
        -- Order 013
        ('40000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000003', '20L Kinley Water Can', 5, 40.00, 200.00)
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Order items created';
END $$;

-- ============================================
-- STEP 7: CREATE SAMPLE PAYMENTS
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Clear existing demo payments
    DELETE FROM payments WHERE vendor_id = demo_vendor_id;

    -- Insert payment records for paid orders
    INSERT INTO payments (id, order_id, vendor_id, payment_method, status, amount, commission_amount, vendor_amount, created_at, processed_at) VALUES
        ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', demo_vendor_id, 'online', 'completed', 135.00, 13.50, 121.50, now() - INTERVAL '2 hours', now() - INTERVAL '2 hours'),
        ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', demo_vendor_id, 'cod', 'completed', 40.00, 4.00, 36.00, now() - INTERVAL '4 hours', now() - INTERVAL '4 hours'),
        ('50000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000004', demo_vendor_id, 'online', 'completed', 250.00, 25.00, 225.00, now() - INTERVAL '6 hours', now() - INTERVAL '6 hours'),
        ('50000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000005', demo_vendor_id, 'cod', 'completed', 100.00, 10.00, 90.00, now() - INTERVAL '8 hours', now() - INTERVAL '8 hours'),
        ('50000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000006', demo_vendor_id, 'online', 'completed', 100.00, 10.00, 90.00, now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
        ('50000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000007', demo_vendor_id, 'online', 'completed', 270.00, 27.00, 243.00, now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
        ('50000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000009', demo_vendor_id, 'cod', 'completed', 150.00, 15.00, 135.00, now() - INTERVAL '2 days', now() - INTERVAL '2 days'),
        ('50000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000010', demo_vendor_id, 'online', 'completed', 250.00, 25.00, 225.00, now() - INTERVAL '2 days', now() - INTERVAL '2 days'),
        ('50000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000011', demo_vendor_id, 'cod', 'completed', 90.00, 9.00, 81.00, now() - INTERVAL '3 days', now() - INTERVAL '3 days'),
        ('50000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000012', demo_vendor_id, 'online', 'completed', 200.00, 20.00, 180.00, now() - INTERVAL '7 days', now() - INTERVAL '7 days'),
        ('50000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000013', demo_vendor_id, 'cod', 'completed', 200.00, 20.00, 180.00, now() - INTERVAL '7 days', now() - INTERVAL '7 days')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Sample payments created';
END $$;

-- ============================================
-- STEP 8: CREATE VENDOR WALLET
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Clear existing wallet
    DELETE FROM vendor_wallets WHERE vendor_id = demo_vendor_id;

    -- Create vendor wallet with balance
    -- Calculated as: total vendor_amount from completed payments = 1666.50
    INSERT INTO vendor_wallets (vendor_id, balance, pending_balance) VALUES
        (demo_vendor_id, 1666.50, 0.00)
    ON CONFLICT (vendor_id) DO UPDATE SET
        balance = EXCLUDED.balance,
        pending_balance = EXCLUDED.pending_balance;

    RAISE NOTICE 'Vendor wallet created with balance: ₹1,666.50';
END $$;

-- ============================================
-- STEP 9: CREATE WALLET TRANSACTIONS
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Clear existing transactions
    DELETE FROM wallet_transactions WHERE vendor_id = demo_vendor_id;

    -- Get wallet ID
    DECLARE wallet_id UUID;
    SELECT id INTO wallet_id FROM vendor_wallets WHERE vendor_id = demo_vendor_id;

    -- Insert wallet transactions
    INSERT INTO wallet_transactions (vendor_wallet_id, vendor_id, type, amount, balance_after, description, status, created_at, processed_at) VALUES
        (wallet_id, demo_vendor_id, 'credit', 121.50, 121.50, 'Payment received for order ORD-2024-002', 'completed', now() - INTERVAL '2 hours', now() - INTERVAL '2 hours'),
        (wallet_id, demo_vendor_id, 'credit', 36.00, 157.50, 'Payment received for order ORD-2024-003', 'completed', now() - INTERVAL '4 hours', now() - INTERVAL '4 hours'),
        (wallet_id, demo_vendor_id, 'credit', 225.00, 382.50, 'Payment received for order ORD-2024-004', 'completed', now() - INTERVAL '6 hours', now() - INTERVAL '6 hours'),
        (wallet_id, demo_vendor_id, 'credit', 90.00, 472.50, 'Payment received for order ORD-2024-005', 'completed', now() - INTERVAL '8 hours', now() - INTERVAL '8 hours'),
        (wallet_id, demo_vendor_id, 'credit', 90.00, 562.50, 'Payment received for order ORD-2024-006', 'completed', now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
        (wallet_id, demo_vendor_id, 'credit', 243.00, 805.50, 'Payment received for order ORD-2024-007', 'completed', now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
        (wallet_id, demo_vendor_id, 'credit', 135.00, 940.50, 'Payment received for order ORD-2024-009', 'completed', now() - INTERVAL '2 days', now() - INTERVAL '2 days'),
        (wallet_id, demo_vendor_id, 'credit', 225.00, 1165.50, 'Payment received for order ORD-2024-010', 'completed', now() - INTERVAL '2 days', now() - INTERVAL '2 days'),
        (wallet_id, demo_vendor_id, 'credit', 81.00, 1246.50, 'Payment received for order ORD-2024-011', 'completed', now() - INTERVAL '3 days', now() - INTERVAL '3 days'),
        (wallet_id, demo_vendor_id, 'credit', 180.00, 1426.50, 'Payment received for order ORD-2024-012', 'completed', now() - INTERVAL '7 days', now() - INTERVAL '7 days'),
        (wallet_id, demo_vendor_id, 'credit', 180.00, 1606.50, 'Payment received for order ORD-2024-013', 'completed', now() - INTERVAL '7 days', now() - INTERVAL '7 days')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Wallet transactions created';
END $$;

-- ============================================
-- STEP 10: UPDATE VENDOR STATISTICS
-- ============================================

DO $$
DECLARE
    demo_vendor_id UUID := '00000000-0000-0000-0000-000000000001';
    total_revenue DECIMAL;
BEGIN
    -- Calculate total revenue from completed orders
    SELECT COALESCE(SUM(total_amount), 0) INTO total_revenue
    FROM orders
    WHERE vendor_id = demo_vendor_id AND status = 'delivered';

    -- Update vendor stats
    UPDATE vendors SET
        total_orders = (SELECT COUNT(*) FROM orders WHERE vendor_id = demo_vendor_id),
        completed_orders = (SELECT COUNT(*) FROM orders WHERE vendor_id = demo_vendor_id AND status = 'delivered'),
        cancelled_orders = (SELECT COUNT(*) FROM orders WHERE vendor_id = demo_vendor_id AND status = 'cancelled'),
        total_revenue = total_revenue
    WHERE id = demo_vendor_id;

    RAISE NOTICE 'Vendor statistics updated';
END $$;

-- ============================================
-- SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'DEMO DATA SETUP COMPLETE!';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Demo Vendor Phone: 1111111111';
    RAISE NOTICE 'Demo Vendor ID: 00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '';
    RAISE NOTICE 'Data Created:';
    RAISE NOTICE '  - 1 Vendor (verified)';
    RAISE NOTICE '  - 4 Products';
    RAISE NOTICE '  - 4 Vendor Products (with inventory)';
    RAISE NOTICE '  - 8 Customers';
    RAISE NOTICE '  - 13 Orders (various statuses)';
    RAISE NOTICE '  - 13 Order Items';
    RAISE NOTICE '  - 11 Payments';
    RAISE NOTICE '  - 1 Wallet (balance: ₹1,666.50)';
    RAISE NOTICE '  - 11 Wallet Transactions';
    RAISE NOTICE '';
    RAISE NOTICE 'Order Status Breakdown:';
    RAISE NOTICE '  Today: 5 orders (1 pending, 1 confirmed, 1 out_for_delivery, 2 delivered)';
    RAISE NOTICE '  Yesterday: 3 orders (2 delivered, 1 cancelled)';
    RAISE NOTICE '  2 days ago: 2 delivered';
    RAISE NOTICE '  3 days ago: 1 delivered';
    RAISE NOTICE '  1 week ago: 2 delivered';
    RAISE NOTICE '===========================================';
END $$;
