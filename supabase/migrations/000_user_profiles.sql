-- ============================================================
-- 000 – Basis: user_profiles (Team-Konten fuer Anima Scribe Standalone)
-- Minimaltabelle, auf die sich Auth, Team-Verwaltung und Rechte stuetzen.
-- In der verbundenen Anima-Cura-Version existiert diese Tabelle bereits;
-- hier ist sie eigenstaendig, damit Scribe ohne Cura lauffaehig ist.
-- ============================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email        TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role         TEXT NOT NULL DEFAULT 'lesezugriff',
  kuerzel      TEXT,
  patient_id   UUID,
  permissions  JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- Rollen-Check (admin / verwaltung / lesezugriff)
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check
  CHECK (role IN ('admin', 'verwaltung', 'lesezugriff'));
