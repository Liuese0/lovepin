-- =============================================================================
-- Lovepin – Full Database Setup (clean install)
-- Supabase Dashboard > SQL Editor 에서 이 파일 전체를 복사하여 실행하세요.
-- 기존 테이블을 모두 삭제하고 새로 생성합니다.
-- =============================================================================

-- =========================================================
-- 0. 기존 트리거/테이블 완전 제거
-- =========================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS get_my_couple_ids() CASCADE;

DROP TABLE IF EXISTS messages       CASCADE;
DROP TABLE IF EXISTS couple_members  CASCADE;
DROP TABLE IF EXISTS couples         CASCADE;
DROP TABLE IF EXISTS users           CASCADE;
DROP TABLE IF EXISTS templates       CASCADE;
DROP TABLE IF EXISTS widget_themes   CASCADE;

-- =========================================================
-- 1. TABLES
-- =========================================================

CREATE TABLE widget_themes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text    NOT NULL,
  background_color text    NOT NULL,
  text_color       text    NOT NULL,
  accent_color     text    NOT NULL,
  font_family      text    NOT NULL,
  is_premium       boolean NOT NULL DEFAULT false,
  preview_url      text
);

CREATE TABLE templates (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category   text    NOT NULL,
  content    text    NOT NULL,
  language   text    NOT NULL DEFAULT 'en',
  is_premium boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE users (
  id                uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name      text,
  avatar_url        text,
  selected_theme_id uuid REFERENCES widget_themes (id),
  fcm_token         text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE couples (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code       text        NOT NULL UNIQUE,
  invite_expires_at timestamptz NOT NULL,
  status            text        NOT NULL DEFAULT 'pending',
  linked_at         timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE couple_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES couples (id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES users   (id) ON DELETE CASCADE,
  role      text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (couple_id, user_id)
);

CREATE TABLE messages (
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
ALTER TABLE messages       ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 3. FUNCTIONS & TRIGGER
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
-- 4. RLS 정책
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

-- messages
-- NOTE: ALTER TABLE messages ENABLE ROW LEVEL SECURITY is in section 2 above.
--
-- INSERT policy: only check sender_id = auth.uid().
-- The couple_id FK already guarantees referential integrity, and the SELECT
-- policy prevents cross-couple reads.  Removing the get_my_couple_ids() check
-- from INSERT eliminates a common failure point (empty couple_members, timing
-- issues after re-login, partial SQL migration, etc.).

CREATE POLICY "Couple members can read messages"
  ON messages FOR SELECT TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Couple members can insert messages"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Couple members can update messages"
  ON messages FOR UPDATE TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

-- =========================================================
-- 5. STORAGE BUCKETS & POLICIES
-- =========================================================

-- 5-a. 버킷 생성
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('message_images', 'message_images', true),
  ('message_thumbnails', 'message_thumbnails', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 5-b. 기존 정책 제거 (충돌 방지)
DROP POLICY IF EXISTS "Couple members can upload images"      ON storage.objects;
DROP POLICY IF EXISTS "Couple members can upload thumbnails"  ON storage.objects;
DROP POLICY IF EXISTS "Public read access for message images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;

-- 5-c. 인증된 사용자가 lovepin 버킷에 업로드 허용
CREATE POLICY "Authenticated users can upload images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('message_images', 'message_thumbnails'));

-- 5-d. 이미지 공개 읽기 (위젯/앱에서 접근)
CREATE POLICY "Public read access for message images"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id IN ('message_images', 'message_thumbnails'));

-- =========================================================
-- 6. REALTIME
-- =========================================================

ALTER TABLE messages REPLICA IDENTITY FULL;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END;
$$;