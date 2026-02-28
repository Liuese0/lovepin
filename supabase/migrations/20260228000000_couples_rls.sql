-- Enable RLS on couples and couple_members tables
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- Drop existing policies (safe to run if they don't exist)
-- =============================================================================
DROP POLICY IF EXISTS "Authenticated users can create couples" ON couples;
DROP POLICY IF EXISTS "Users can read own couple" ON couples;
DROP POLICY IF EXISTS "Users can update own couple" ON couples;
DROP POLICY IF EXISTS "Anyone can read pending couples by invite code" ON couples;
DROP POLICY IF EXISTS "Users can insert own membership" ON couple_members;
DROP POLICY IF EXISTS "Users can read own membership" ON couple_members;
DROP POLICY IF EXISTS "Users can read fellow members" ON couple_members;

-- =============================================================================
-- couples table policies
-- =============================================================================

-- INSERT: Any authenticated user can create a couple.
CREATE POLICY "Authenticated users can create couples"
  ON couples FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- SELECT: Users can only read couples they belong to.
CREATE POLICY "Users can read own couple"
  ON couples FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT couple_id FROM couple_members WHERE user_id = auth.uid()
    )
  );

-- UPDATE: Users can only update couples they belong to.
CREATE POLICY "Users can update own couple"
  ON couples FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT couple_id FROM couple_members WHERE user_id = auth.uid()
    )
  );

-- SELECT for join: Allow reading pending couples by invite code
-- (needed so a joiner can look up the couple before becoming a member).
CREATE POLICY "Anyone can read pending couples by invite code"
  ON couples FOR SELECT
  TO authenticated
  USING (status = 'pending');

-- =============================================================================
-- couple_members table policies
-- =============================================================================

-- INSERT: Users can only insert membership rows for themselves.
CREATE POLICY "Users can insert own membership"
  ON couple_members FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- SELECT: Users can only read their own membership rows.
CREATE POLICY "Users can read own membership"
  ON couple_members FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- SELECT: Users can see other members of couples they belong to.
CREATE POLICY "Users can read fellow members"
  ON couple_members FOR SELECT
  TO authenticated
  USING (
    couple_id IN (
      SELECT couple_id FROM couple_members WHERE user_id = auth.uid()
    )
  );
