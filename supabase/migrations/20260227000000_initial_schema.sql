-- =============================================================================
-- Initial schema: create all application tables.
-- Must run BEFORE the RLS / trigger migrations.
-- =============================================================================

-- ---- widget_themes (no FK dependencies) ----
CREATE TABLE IF NOT EXISTS widget_themes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text    NOT NULL,
  background_color text NOT NULL,
  text_color  text    NOT NULL,
  accent_color text   NOT NULL,
  font_family text    NOT NULL,
  is_premium  boolean NOT NULL DEFAULT false,
  preview_url text
);

-- ---- templates (no FK dependencies) ----
CREATE TABLE IF NOT EXISTS templates (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category   text    NOT NULL,
  content    text    NOT NULL,
  language   text    NOT NULL DEFAULT 'en',
  is_premium boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0
);

-- ---- users ----
CREATE TABLE IF NOT EXISTS users (
  id                uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name      text,
  avatar_url        text,
  selected_theme_id uuid REFERENCES widget_themes (id),
  fcm_token         text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ---- couples ----
CREATE TABLE IF NOT EXISTS couples (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code       text        NOT NULL UNIQUE,
  invite_expires_at timestamptz NOT NULL,
  status            text        NOT NULL DEFAULT 'pending',
  linked_at         timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ---- couple_members ----
CREATE TABLE IF NOT EXISTS couple_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid NOT NULL REFERENCES couples (id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES users   (id) ON DELETE CASCADE,
  role      text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (couple_id, user_id)
);

-- ---- messages ----
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
