-- =====================================================
-- Fix Test Mode SELECT RLS Policy
-- =====================================================
-- Run this in your Supabase SQL Editor
-- This allows test mode (OTP 000000) to READ vendors
-- =====================================================

-- Problem: Test mode can INSERT but cannot SELECT due to RLS policies
-- Solution: Add a SELECT policy for anon users with test_mode check

-- 1. Drop existing SELECT policy
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendors;

-- 2. Create policy for authenticated users (production mode)
CREATE POLICY "Vendors can view own profile"
ON vendors
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR test_mode = true
);

-- 3. Create policy for test mode (development mode)
-- Allows anon (unauthenticated) users to SELECT when test_mode = true
CREATE POLICY "Enable test mode vendor read"
ON vendors
FOR SELECT
TO anon
USING (
  test_mode = true  -- Allow SELECT if test_mode column is true
);

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
-- DONE! Test mode can now READ vendors with RLS enabled
-- =====================================================

-- How to test:
-- 1. Login with test OTP (000000) with phone 9999999999
-- 2. Should now detect existing vendor and go to dashboard
-- 3. NOT redirect to profile setup again!
