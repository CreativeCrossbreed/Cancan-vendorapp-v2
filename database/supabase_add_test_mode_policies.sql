-- =====================================================
-- Enable Test Mode for Vendors (No SMS Required)
-- =====================================================
-- Run this in your Supabase SQL Editor
-- This allows test OTP (000000) to work without phone auth
-- =====================================================

-- 1. Add test_mode column to vendors table
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS test_mode BOOLEAN DEFAULT false;

-- 2. Drop existing insert policy that requires auth.uid()
DROP POLICY IF EXISTS "Vendors can insert own profile" ON vendors;

-- 3. Create new policy that allows test mode vendors
CREATE POLICY "Vendors can insert own profile"
ON vendors
FOR INSERT
TO authenticated
WITH CHECK (
  -- Allow if user is authenticated and id matches
  auth.uid() = id
  OR
  -- Allow if test_mode is true (for development without phone auth)
  (data->>'test_mode')::boolean = true
);

-- 4. Update the view policy to allow test mode vendors to see their own profile
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendors;
CREATE POLICY "Vendors can view own profile"
ON vendors
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR test_mode = true
);

-- 5. Update the update policy to allow test mode vendors to update their profile
DROP POLICY IF EXISTS "Vendors can update own profile" ON vendors;
CREATE POLICY "Vendors can update own profile"
ON vendors
FOR UPDATE
TO authenticated
USING (
  auth.uid() = id OR test_mode = true
)
WITH CHECK (
  auth.uid() = id OR test_mode = true
);

-- 6. For testing, also allow public access to create test vendors
-- (Remove this in production!)
DROP POLICY IF EXISTS "Enable test mode vendor creation" ON vendors;
CREATE POLICY "Enable test mode vendor creation"
ON vendors
FOR INSERT
TO anon
WITH CHECK (
  (data->>'test_mode')::boolean = true
);

-- =====================================================
-- DONE! Test mode now works without phone auth
-- =====================================================
