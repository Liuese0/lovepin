-- =============================================================================
-- Auto-create a public.users row when a new auth user signs up.
-- This ensures the FK constraint on couple_members.user_id is always satisfied,
-- even if the user hasn't completed profile setup yet.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, created_at)
  VALUES (NEW.id, now())
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Drop the trigger if it already exists, then create it.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- RLS policies for the users table
-- =============================================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can read partner profile" ON users;

-- Users can read their own profile.
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Users can insert their own profile.
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Users can update their own profile.
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- Users can read their partner's profile (for display name, avatar, etc).
CREATE POLICY "Users can read partner profile"
  ON users FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT cm.user_id FROM couple_members cm
      WHERE cm.couple_id IN (SELECT get_my_couple_ids())
    )
  );
