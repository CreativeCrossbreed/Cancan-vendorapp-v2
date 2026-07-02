-- admin_users had a self-referencing RLS policy: "Super admins can view all
-- admins" subqueries admin_users itself to check the caller's role. Postgres
-- applies RLS to that inner subquery too, which re-evaluates the same
-- policy — infinite recursion (error 42P17). This wasn't introduced by any
-- of this session's work; it surfaces whenever anything queries admin_users,
-- including indirectly via vendors' "Admins can view all vendors" policy
-- (EXISTS (SELECT 1 FROM admin_users WHERE admin_users.id = auth.uid())).
--
-- Fix: a SECURITY DEFINER function bypasses RLS on the tables it queries
-- internally (it runs as the function owner, not the calling role), so the
-- recursion never starts.

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_users
    WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

GRANT EXECUTE ON FUNCTION is_super_admin TO authenticated, anon;

DROP POLICY IF EXISTS "Super admins can view all admins" ON admin_users;
CREATE POLICY "Super admins can view all admins" ON admin_users
  FOR SELECT TO public USING (is_super_admin());

DROP POLICY IF EXISTS "Super admins can update admins" ON admin_users;
CREATE POLICY "Super admins can update admins" ON admin_users
  FOR UPDATE TO public USING (is_super_admin());

DROP POLICY IF EXISTS "Super admins can insert admins" ON admin_users;
CREATE POLICY "Super admins can insert admins" ON admin_users
  FOR INSERT TO public WITH CHECK (is_super_admin());
