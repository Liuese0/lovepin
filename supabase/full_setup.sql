-- =============================================================================
-- Lovepin – Full Database Setup (idempotent)
-- Supabase Dashboard > SQL Editor 에서 이 파일 전체를 복사하여 실행하세요.
-- =============================================================================

-- =========================================================
-- 1. TABLES
-- =========================================================

CREATE TABLE IF NOT EXISTS widget_themes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text    NOT NULL,
  background_color text    NOT NULL,
  text_color       text    NOT NULL,
  accent_color     text    NOT NULL,
  font_family      text    NOT NULL,
  is_premium       boolean NOT NULL DEFAULT false,
  preview_url      text
);

CREATE TABLE IF NOT EXISTS templates (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category   text    NOT NULL,
  content    text    NOT NULL,
  language   text    NOT NULL DEFAULT 'en',
  is_premium boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS users (
  id                uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name      text,
  avatar_url        text,
  selected_theme_id uuid REFERENCES widget_themes (id),
  fcm_token         text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS couples (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code       text        NOT NULL UNIQUE,
  invite_expires_at timestamptz NOT NULL,
  status            text        NOT NULL DEFAULT 'pending',
  linked_at         timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS couple_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES couples (id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES users   (id) ON DELETE CASCADE,
  role      text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (couple_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id           uuid    NOT NULL REFERENCES couples   (id) ON DELETE CASCADE,
  sender_id           uuid    NOT NULL REFERENCES users     (id),
  content             text    NOT NULL,
  image_url           text,
  image_thumbnail_url text,
  template_id         uuid    REFERENCES templates (id),
  is_read             boolean NOT NULL DEFAULT false,
  read_at             timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =========================================================
-- 2. RLS 활성화
-- =========================================================

ALTER TABLE users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples        ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 3. 기존 정책 전부 제거 (이전 실행 잔재 정리)
-- =========================================================

-- users
DROP POLICY IF EXISTS "Users can read own profile"    ON users;
DROP POLICY IF EXISTS "Users can insert own profile"   ON users;
DROP POLICY IF EXISTS "Users can update own profile"   ON users;
DROP POLICY IF EXISTS "Users can read partner profile"  ON users;

-- couples
DROP POLICY IF EXISTS "Authenticated users can create couples"         ON couples;
DROP POLICY IF EXISTS "Users can read own couple"                      ON couples;
DROP POLICY IF EXISTS "Users can update own couple"                    ON couples;
DROP POLICY IF EXISTS "Anyone can read pending couples by invite code" ON couples;

-- couple_members
DROP POLICY IF EXISTS "Users can insert own membership"       ON couple_members;
DROP POLICY IF EXISTS "Users can read own membership"         ON couple_members;
DROP POLICY IF EXISTS "Users can read fellow members"         ON couple_members;
DROP POLICY IF EXISTS "Users can read own and fellow members" ON couple_members;

-- =========================================================
-- 4. FUNCTIONS
-- =========================================================

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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION get_my_couple_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT couple_id FROM couple_members WHERE user_id = auth.uid();
$$;

-- =========================================================
-- 5. RLS 정책 생성
-- =========================================================

-- users
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can read partner profile"
  ON users FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT cm.user_id FROM couple_members cm
      WHERE cm.couple_id IN (SELECT get_my_couple_ids())
    )
  );

-- couples
CREATE POLICY "Authenticated users can create couples"
  ON couples FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can read own couple"
  ON couples FOR SELECT TO authenticated
  USING (id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Users can update own couple"
  ON couples FOR UPDATE TO authenticated
  USING (id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Anyone can read pending couples by invite code"
  ON couples FOR SELECT TO authenticated
  USING (status = 'pending');

-- couple_members
CREATE POLICY "Users can insert own membership"
  ON couple_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read own and fellow members"
  ON couple_members FOR SELECT TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));
