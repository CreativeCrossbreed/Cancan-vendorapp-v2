-- =====================================================
-- Fix Test Mode RLS Policies
-- =====================================================
-- Run this in your Supabase SQL Editor
-- This allows test mode (OTP 000000) to work with RLS enabled
-- =====================================================

-- 1. Add test_mode column if it doesn't exist
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS test_mode BOOLEAN DEFAULT false;

-- 2. Drop existing INSERT policies
DROP POLICY IF EXISTS "Vendors can insert own profile" ON vendors;
DROP POLICY IF EXISTS "Enable test mode vendor creation" ON vendors;

-- 3. Create policy for authenticated users (production mode)
CREATE POLICY "Vendors can insert own profile"
ON vendors
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id  -- Authenticated users can insert their own profile
);

-- 4. Create policy for test mode (development mode)
-- Allows anon (unauthenticated) users to insert when test_mode = true
CREATE POLICY "Enable test mode vendor creation"
ON vendors
FOR INSERT
TO anon
WITH CHECK (
  test_mode = true  -- Allow insert if test_mode column is true
);

-- 5. Update SELECT policy to include test mode vendors
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendors;

CREATE POLICY "Vendors can view own profile"
ON vendors
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR test_mode = true  -- Can view own profile OR test mode vendors
);

-- 6. Update UPDATE policy to include test mode
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

-- 7. Keep DELETE policy (no one can delete)
DROP POLICY IF EXISTS "Vendors cannot delete profiles" ON vendors;

CREATE POLICY "Vendors cannot delete profiles"
ON vendors
FOR DELETE
TO authenticated
USING (false);

-- =====================================================
-- Verification Queries
-- =====================================================

-- Check active RLS policies
SELECT
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'vendors';

-- =====================================================
-- DONE! Test mode now works with RLS enabled
-- =====================================================

-- How to test:
-- 1. Login with test OTP (000000)
-- 2. Create vendor profile
-- 3. Should work now!
