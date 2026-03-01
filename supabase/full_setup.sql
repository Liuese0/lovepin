-- =============================================================================
-- Lovepin – Full Database Setup (clean install)
-- Supabase Dashboard > SQL Editor 에서 이 파일 전체를 복사하여 실행하세요.
-- 기존 테이블을 모두 삭제하고 새로 생성합니다.
-- =============================================================================

-- =========================================================
-- 0. 기존 트리거/함수/테이블 완전 제거
-- =========================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.get_my_couple_ids() CASCADE;

DROP TABLE IF EXISTS messages       CASCADE;
DROP TABLE IF EXISTS couple_members  CASCADE;
DROP TABLE IF EXISTS couples         CASCADE;
DROP TABLE IF EXISTS users           CASCADE;
DROP TABLE IF EXISTS templates       CASCADE;
DROP TABLE IF EXISTS widget_themes   CASCADE;

-- =========================================================
-- 1. TABLES
-- =========================================================

-- 위젯 테마 (레퍼런스 데이터)
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

-- 메시지 템플릿 (레퍼런스 데이터)
CREATE TABLE templates (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category   text    NOT NULL,
  content    text    NOT NULL,
  language   text    NOT NULL DEFAULT 'en',
  is_premium boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0
);

-- 유저 프로필 (auth.users 와 1:1)
CREATE TABLE users (
  id                uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name      text,
  avatar_url        text,
  selected_theme_id uuid REFERENCES widget_themes (id),
  fcm_token         text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- 커플
CREATE TABLE couples (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code       text        NOT NULL UNIQUE,
  invite_expires_at timestamptz NOT NULL,
  status            text        NOT NULL DEFAULT 'pending',
  linked_at         timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- 커플 ↔ 유저 연결 테이블
CREATE TABLE couple_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES couples (id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES users   (id) ON DELETE CASCADE,
  role      text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (couple_id, user_id)
);

-- 메시지
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
-- 2. INDEXES (성능 최적화)
-- =========================================================

CREATE INDEX idx_couple_members_user_id   ON couple_members (user_id);
CREATE INDEX idx_couple_members_couple_id ON couple_members (couple_id);
CREATE INDEX idx_couples_invite_code      ON couples (invite_code);
CREATE INDEX idx_couples_status           ON couples (status);
CREATE INDEX idx_messages_couple_id       ON messages (couple_id, created_at DESC);
CREATE INDEX idx_messages_sender_id       ON messages (sender_id);

-- =========================================================
-- 3. RLS 활성화
-- =========================================================

ALTER TABLE users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples        ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages       ENABLE ROW LEVEL SECURITY;
ALTER TABLE widget_themes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates      ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 4. FUNCTIONS & TRIGGER
-- =========================================================

-- 회원가입 시 자동으로 public.users 행 생성
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

-- 현재 유저가 속한 couple_id 목록 반환 (RLS 정책에서 사용)
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
-- 5. RLS 정책
-- =========================================================

-- -------------------------------------------------------
-- widget_themes (레퍼런스 데이터 – 인증된 유저 읽기 전용)
-- -------------------------------------------------------
CREATE POLICY "Authenticated users can read themes"
  ON widget_themes FOR SELECT TO authenticated
  USING (true);

-- -------------------------------------------------------
-- templates (레퍼런스 데이터 – 인증된 유저 읽기 전용)
-- -------------------------------------------------------
CREATE POLICY "Authenticated users can read templates"
  ON templates FOR SELECT TO authenticated
  USING (true);

-- -------------------------------------------------------
-- users
-- -------------------------------------------------------
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can read partner profile"
  ON users FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT cm.user_id FROM couple_members cm
      WHERE cm.couple_id IN (SELECT get_my_couple_ids())
    )
  );

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE TO authenticated
  USING (id = auth.uid());

-- -------------------------------------------------------
-- couples
-- -------------------------------------------------------
CREATE POLICY "Authenticated users can create couples"
  ON couples FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can read own couple"
  ON couples FOR SELECT TO authenticated
  USING (id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Anyone can read pending couples by invite code"
  ON couples FOR SELECT TO authenticated
  USING (status = 'pending');

CREATE POLICY "Users can update own couple"
  ON couples FOR UPDATE TO authenticated
  USING (id IN (SELECT get_my_couple_ids()));

-- -------------------------------------------------------
-- couple_members
-- -------------------------------------------------------
CREATE POLICY "Users can insert own membership"
  ON couple_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read own and fellow members"
  ON couple_members FOR SELECT TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

-- -------------------------------------------------------
-- messages
-- -------------------------------------------------------
CREATE POLICY "Users can insert messages to own couple"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND couple_id IN (SELECT get_my_couple_ids())
  );

CREATE POLICY "Users can read messages from own couple"
  ON messages FOR SELECT TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Users can update messages in own couple"
  ON messages FOR UPDATE TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

-- =========================================================
-- 6. STORAGE BUCKETS (Supabase Dashboard 에서 수동 생성)
-- =========================================================
-- 아래 버킷은 SQL로 생성할 수 없습니다.
-- Supabase Dashboard > Storage 에서 직접 생성하세요.
--
--   1. message_images      (Public)  – 메시지 원본 이미지
--   2. message_thumbnails   (Public)  – 메시지 썸네일 이미지
--
-- 각 버킷에 아래 정책을 추가하세요:
--   - INSERT: authenticated 유저 허용
--   - SELECT: public (또는 authenticated) 읽기 허용
