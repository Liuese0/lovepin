-- =============================================================================
-- Lovepin – Storage RLS 및 Realtime 패치
-- 기존 DB에 이 파일만 실행하면 사진 업로드 + 실시간 위젯 업데이트가 작동합니다.
-- Supabase Dashboard > SQL Editor 에서 실행하세요.
-- =============================================================================

-- =========================================================
-- 1. Storage 버킷 생성 (이미 있으면 무시)
-- =========================================================

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('message_images', 'message_images', true),
  ('message_thumbnails', 'message_thumbnails', true)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 2. Storage RLS 정책
-- =========================================================

-- 기존 충돌 방지를 위해 DROP 후 생성
DROP POLICY IF EXISTS "Couple members can upload images"      ON storage.objects;
DROP POLICY IF EXISTS "Couple members can upload thumbnails"  ON storage.objects;
DROP POLICY IF EXISTS "Public read access for message images" ON storage.objects;

-- 커플 멤버만 자기 커플 폴더에 이미지 업로드 가능
CREATE POLICY "Couple members can upload images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'message_images'
    AND (storage.foldername(name))[1] IN (
      SELECT couple_id::text FROM couple_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Couple members can upload thumbnails"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'message_thumbnails'
    AND (storage.foldername(name))[1] IN (
      SELECT couple_id::text FROM couple_members WHERE user_id = auth.uid()
    )
  );

-- 이미지는 공개 읽기 (위젯에서도 접근 필요)
CREATE POLICY "Public read access for message images"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id IN ('message_images', 'message_thumbnails'));

-- =========================================================
-- 3. messages 테이블 RLS (아직 없는 경우)
-- =========================================================

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Couple members can read messages"   ON messages;
DROP POLICY IF EXISTS "Couple members can insert messages" ON messages;
DROP POLICY IF EXISTS "Couple members can update messages" ON messages;

CREATE POLICY "Couple members can read messages"
  ON messages FOR SELECT TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

CREATE POLICY "Couple members can insert messages"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND couple_id IN (SELECT get_my_couple_ids())
  );

CREATE POLICY "Couple members can update messages"
  ON messages FOR UPDATE TO authenticated
  USING (couple_id IN (SELECT get_my_couple_ids()));

-- =========================================================
-- 4. Realtime 활성화 (실시간 위젯 업데이트용)
-- =========================================================

ALTER TABLE messages REPLICA IDENTITY FULL;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END;
$$;
