-- ============================================================
-- 019d – Altersregel: IP-Prophylaxe (BEMA IP1-IP4) ist eine
-- Kassenleistung fuer 6- bis 17-Jaehrige. Die Vorlage traegt
-- die Regel jetzt selbst; das Cockpit blendet sie bei
-- Patienten ausserhalb des Alters aus.
-- ============================================================
UPDATE doku_vorlagen
SET struktur = struktur || '{"alter_min": 6, "alter_max": 17}'::jsonb,
    updated_at = NOW()
WHERE behandlungsart = 'multiband' AND termin_typ = 'ip';

-- Kontrolle (erwartet: 6 / 17):
SELECT behandlungsart, termin_typ,
       struktur->>'alter_min' AS alter_min,
       struktur->>'alter_max' AS alter_max
FROM doku_vorlagen
WHERE behandlungsart = 'multiband' AND termin_typ = 'ip';
