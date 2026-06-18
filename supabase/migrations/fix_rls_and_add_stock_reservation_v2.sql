-- Fix RLS policies and add stock reservation system
-- This migration fixes permission issues and adds reserved_stock functionality

-- Step 1: Enable RLS and fix policies for products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "products_select_policy" ON products;
DROP POLICY IF EXISTS "products_insert_policy" ON products;
DROP POLICY IF EXISTS "products_update_policy" ON products;

-- Create new policies for products
-- Allow authenticated users to select products
CREATE POLICY "products_select_policy" ON products
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert products
CREATE POLICY "products_insert_policy" ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update products
CREATE POLICY "products_update_policy" ON products
  FOR UPDATE
  TO authenticated
  WITH CHECK (true);

-- Step 2: Fix policies for vendor_products table
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "vendor_products_select_policy" ON vendor_products;
DROP POLICY IF EXISTS "vendor_products_insert_policy" ON vendor_products;
DROP POLICY IF EXISTS "vendor_products_update_policy" ON vendor_products;
DROP POLICY IF EXISTS "vendor_products_delete_policy" ON vendor_products;

-- Create new policies for vendor_products
-- Allow vendors to see their own products
CREATE POLICY "vendor_products_select_policy" ON vendor_products
  FOR SELECT
  TO authenticated
  USING (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

-- Allow vendors to insert their products
CREATE POLICY "vendor_products_insert_policy" ON vendor_products
  FOR INSERT
  TO authenticated
  WITH CHECK (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

-- Allow vendors to update their products
CREATE POLICY "vendor_products_update_policy" ON vendor_products
  FOR UPDATE
  TO authenticated
  USING (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1))
  WITH CHECK (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

-- Allow vendors to delete their products
CREATE POLICY "vendor_products_delete_policy" ON vendor_products
  FOR DELETE
  TO authenticated
  USING (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

-- Step 3: Add reserved_stock column to vendor_products
ALTER TABLE vendor_products ADD COLUMN IF NOT EXISTS reserved_stock INTEGER DEFAULT 0;
ALTER TABLE vendor_products ADD COLUMN IF NOT EXISTS last_stock_alert TIMESTAMP;

-- Step 4: Fix policies for orders table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders_select_policy" ON orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON orders;
DROP POLICY IF EXISTS "orders_update_policy" ON orders;

CREATE POLICY "orders_select_policy" ON orders
  FOR SELECT
  TO authenticated
  USING (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

CREATE POLICY "orders_insert_policy" ON orders
  FOR INSERT
  TO authenticated
  WITH CHECK (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

CREATE POLICY "orders_update_policy" ON orders
  FOR UPDATE
  TO authenticated
  USING (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1))
  WITH CHECK (vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1));

-- Step 5: Fix policies for order_items table
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "order_items_select_policy" ON order_items;
DROP POLICY IF EXISTS "order_items_insert_policy" ON order_items;

CREATE POLICY "order_items_select_policy" ON order_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.id = order_items.order_id
        AND o.vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1)
    )
  );

CREATE POLICY "order_items_insert_policy" ON order_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.id = order_items.order_id
        AND o.vendor_id = (SELECT id::text FROM vendors WHERE auth.uid() = id LIMIT 1)
    )
  );

-- Step 6: Create a function to calculate available stock
CREATE OR REPLACE FUNCTION get_available_stock(p_vendor_id TEXT, p_product_id TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COALESCE(current_stock, 0) - COALESCE(reserved_stock, 0)
    FROM vendor_products
    WHERE vendor_id = p_vendor_id AND product_id = p_product_id
  );
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create a function to reserve stock for an order
CREATE OR REPLACE FUNCTION reserve_stock_for_order(p_order_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_vendor_id TEXT;
  v_product_id TEXT;
  v_quantity INTEGER;
  v_available_stock INTEGER;
BEGIN
  -- Get order vendor and product info
  SELECT o.vendor_id, oi.product_id, oi.quantity
  INTO v_vendor_id, v_product_id, v_quantity
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  WHERE o.id = p_order_id
  LIMIT 1;

  -- Check available stock
  SELECT COALESCE(current_stock, 0) - COALESCE(reserved_stock, 0)
  INTO v_available_stock
  FROM vendor_products
  WHERE vendor_id = v_vendor_id AND product_id = v_product_id;

  -- Reserve stock if available
  IF v_available_stock >= v_quantity THEN
    UPDATE vendor_products
    SET reserved_stock = COALESCE(reserved_stock, 0) + v_quantity
    WHERE vendor_id = v_vendor_id AND product_id = v_product_id;
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Create a function to release reserved stock when order is cancelled
CREATE OR REPLACE FUNCTION release_reserved_stock(p_order_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE vendor_products vp
  SET reserved_stock = COALESCE(vp.reserved_stock, 0) - oi.quantity
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.id
  WHERE o.id = p_order_id
    AND vp.vendor_id = o.vendor_id
    AND vp.product_id = oi.product_id;
END;
$$ LANGUAGE plpgsql;

-- Step 9: Create a function to convert reserved stock to actual delivery
CREATE OR REPLACE FUNCTION convert_reserved_to_delivered(p_order_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE vendor_products vp
  SET current_stock = COALESCE(vp.current_stock, 0) - oi.quantity,
      reserved_stock = COALESCE(vp.reserved_stock, 0) - oi.quantity
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.id
  WHERE o.id = p_order_id
    AND vp.vendor_id = o.vendor_id
    AND vp.product_id = oi.product_id;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_stock TO authenticated;
GRANT EXECUTE ON FUNCTION reserve_stock_for_order TO authenticated;
GRANT EXECUTE ON FUNCTION release_reserved_stock TO authenticated;
GRANT EXECUTE ON FUNCTION convert_reserved_to_delivered TO authenticated;
