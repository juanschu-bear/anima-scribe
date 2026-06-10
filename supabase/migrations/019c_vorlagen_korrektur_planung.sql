-- ============================================================
-- 019c – Vorlagen-Korrektur: "Planung" bei Aligner-Anfangsdiagnostik
-- ist kombinierbar (multi statt entweder-oder).
-- Juans Feedback 10.06.: 3D-Simulation besprochen UND
-- Auswertung folgt koennen beide zutreffen.
-- ============================================================
UPDATE doku_vorlagen
SET struktur = jsonb_set(struktur, '{groups,simulation,type}', '"multi"'),
    updated_at = NOW()
WHERE behandlungsart = 'aligner' AND termin_typ = 'diagnostik';

-- Kontrolle (erwartet: multi):
SELECT behandlungsart, termin_typ,
       struktur->'groups'->'simulation'->>'type' AS planung_typ
FROM doku_vorlagen
WHERE behandlungsart = 'aligner' AND termin_typ = 'diagnostik';
