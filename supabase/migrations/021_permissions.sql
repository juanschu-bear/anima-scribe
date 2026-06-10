-- ============================================================
-- 021 – Granulare Rechte pro Konto (Stufe 1: Scribe)
-- user_profiles.permissions: JSON-Schalter, die die Rollen-Defaults
-- pro Person uebersteuern. Stufe 1 kennt:
--   scribe_schreiben (true/false) – dokumentieren, Versionen,
--   ivoris-Push, Verwerfen in Anima Scribe.
-- Kein Eintrag = Rollen-Default (admin/verwaltung: ja, lesezugriff: nein).
-- Beispiel: Empfang (lesezugriff) bekommt {"scribe_schreiben": true}
-- und darf in Scribe arbeiten, ohne in Anima Cura mehr zu duerfen.
-- ============================================================
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS permissions JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Kontrolle:
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'user_profiles' AND column_name = 'permissions';
