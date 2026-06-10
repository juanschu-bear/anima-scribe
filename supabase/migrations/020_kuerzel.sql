-- ============================================================
-- 020 – Behandler-Kuerzel (Signum-Konvention der Praxis)
-- user_profiles.kuerzel: z. B. 'ms' (Dr. Maria Schubert), 'sr' (Sabine Rueger)
-- doku_eintraege.bestaetigt_kuerzel: wird beim Bestaetigen aus dem
-- Profil uebernommen und beim ivoris-Push ans Textende gehaengt,
-- exakt wie die Praxis es handschriftlich macht ("... instruiert. ms").
-- Werte setzt das Konten-Script (scripts/praxis-accounts.mjs).
-- ============================================================
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS kuerzel TEXT;
ALTER TABLE doku_eintraege ADD COLUMN IF NOT EXISTS bestaetigt_kuerzel TEXT;

-- Kontrolle (erwartet: beide Spalten gelistet):
SELECT table_name, column_name
FROM information_schema.columns
WHERE (table_name = 'user_profiles' AND column_name = 'kuerzel')
   OR (table_name = 'doku_eintraege' AND column_name = 'bestaetigt_kuerzel');
