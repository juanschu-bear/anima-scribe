-- ============================================================
-- 019f – Status 'verworfen' fuer doku_eintraege
-- Verwerfen statt Loeschen: Eintrag verschwindet aus Tagesliste
-- und Kopplung, bleibt aber in der Historie (revisionssicher).
-- Nur fuer Eintraege moeglich, die NICHT in ivoris stehen
-- (erzwingt die API). VOR dem 14er-Deploy oder direkt danach
-- einspielen, sonst schlaegt der Verwerfen-Knopf fehl.
-- ============================================================
ALTER TABLE doku_eintraege DROP CONSTRAINT IF EXISTS doku_eintraege_status_check;
ALTER TABLE doku_eintraege ADD CONSTRAINT doku_eintraege_status_check
  CHECK (status IN ('entwurf', 'bestaetigt', 'verworfen'));

-- Kontrolle (erwartet: eine Zeile mit den drei Werten):
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'doku_eintraege'::regclass AND conname = 'doku_eintraege_status_check';
