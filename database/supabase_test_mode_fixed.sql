-- =====================================================
-- Enable Test Mode for Vendors (Fixed Version)
-- =====================================================
-- Run this in your Supabase SQL Editor
-- This allows test OTP (000000) to work without phone auth
-- =====================================================

-- 1. Add test_mode column to vendors table
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS test_mode BOOLEAN DEFAULT false;

-- 2. Drop all existing vendor policies first
DROP POLICY IF EXISTS "Vendors can insert own profile" ON vendors;
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendors;
DROP POLICY IF EXISTS "Vendors can update own profile" ON vendors;
DROP POLICY IF EXISTS "Vendors cannot delete profiles" ON vendors;
DROP POLICY IF EXISTS "Enable test mode vendor creation" ON vendors;

-- 3. Create simplified insert policy (allows authenticated users OR test mode)
CREATE POLICY "Vendors can insert own profile"
ON vendors
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id  -- Authenticated users can insert their own profile
);

-- 4. Create policy for anon (unauthenticated) users - allows test mode
CREATE POLICY "Enable test mode vendor creation"
ON vendors
FOR INSERT
TO anon
WITH CHECK (
  test_mode = true  -- Allow insert if test_mode column is true
);

-- 5. View policy - allow vendors to see their own profile OR test mode vendors
CREATE POLICY "Vendors can view own profile"
ON vendors
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR test_mode = true
);

-- 6. Update policy
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

-- 7. Delete policy
CREATE POLICY "Vendors cannot delete profiles"
ON vendors
FOR DELETE
TO authenticated
USING (false);

-- =====================================================
-- DONE! Test mode now works without phone auth
-- =====================================================
