-- ============================================================
-- 019 – TEXTE-MODUL: Doku-Vorlagen, Einträge, Versionen
-- Pastebar in den Supabase-SQL-Editor. Idempotent wo möglich.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Vorlagen: Termintypen je Behandlungsart, Bausteine + Positions-Mapping als JSONB
--    (Praxis kann Texte/Positionen anpassen, ohne dass deployed werden muss)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doku_vorlagen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  behandlungsart TEXT NOT NULL CHECK (behandlungsart IN ('aligner', 'removable', 'multiband')),
  termin_typ TEXT NOT NULL,                -- slug, z. B. 'kontrolle', 'notfall', 'entbaenderung'
  name TEXT NOT NULL,                      -- Anzeigename, z. B. 'Bogenkontrolle'
  sort_index INTEGER NOT NULL DEFAULT 0,
  aktiv BOOLEAN NOT NULL DEFAULT TRUE,
  -- Template-Struktur: Reihenfolge, Baustein-Gruppen (Pflicht/optional, single/multi),
  -- Bausteintexte mit Tokens ({zaehne}, {von}, {bis}, {bogen}), Variablen-Definitionen
  struktur JSONB NOT NULL,
  -- Abrechnungs-Mapping: Zeilen mit Code, Text, optionaler Bedingung (Gruppe+Option)
  -- und optionalem Zähler (z. B. je Zahn). Mit Sabine zu prüfen, deshalb editierbar.
  positionen JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (behandlungsart, termin_typ)
);

CREATE INDEX IF NOT EXISTS idx_doku_vorlagen_art ON doku_vorlagen (behandlungsart, aktiv, sort_index);

-- ------------------------------------------------------------
-- 2) Einträge: der bestätigte Karteieintrag (aktuelle Fassung)
--    Historie liegt vollständig in doku_eintrag_versionen.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doku_eintraege (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
  behandlungsfall_id UUID REFERENCES behandlungsfall(id) ON DELETE RESTRICT,
  vorlage_id UUID REFERENCES doku_vorlagen(id) ON DELETE SET NULL,
  termin_datum DATE NOT NULL DEFAULT CURRENT_DATE,
  behandlungsart TEXT CHECK (behandlungsart IN ('aligner', 'removable', 'multiband')),
  termin_typ TEXT,
  -- Final bestätigter Text (aktuelle Version), Auswahl-Zustand und Variablen
  text TEXT NOT NULL,
  zaehne TEXT[] NOT NULL DEFAULT '{}',     -- FDI, z. B. {'21','25'}
  variablen JSONB NOT NULL DEFAULT '{}',   -- z. B. {"schienen_von":9,"schienen_bis":11,"bogen":"16er NiTi"}
  auswahl JSONB NOT NULL DEFAULT '{}',     -- gewählte Bausteine je Gruppe (für Re-Edit + Lernschicht)
  positionen JSONB NOT NULL DEFAULT '[]',  -- ausgelöste Abrechnungszeilen (Snapshot bei Bestätigung)
  ausnahme_freitext TEXT,
  status TEXT NOT NULL CHECK (status IN ('entwurf', 'bestaetigt')) DEFAULT 'entwurf',
  version INTEGER NOT NULL DEFAULT 1,
  bestaetigt_von UUID,                     -- auth.users id
  bestaetigt_am TIMESTAMPTZ,
  -- ivoris-Push (append-only Kanal: POST /Documentation/v1/Entry)
  ivoris_push_status TEXT NOT NULL CHECK (ivoris_push_status IN ('nicht_geplant', 'ausstehend', 'gepusht', 'fehler')) DEFAULT 'ausstehend',
  ivoris_entry_id UUID,                    -- Rückgabe von AddEntry
  ivoris_gepusht_am TIMESTAMPTZ,
  ivoris_fehler TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_doku_eintraege_patient ON doku_eintraege (patient_id, termin_datum DESC);
CREATE INDEX IF NOT EXISTS idx_doku_eintraege_fall ON doku_eintraege (behandlungsfall_id);
CREATE INDEX IF NOT EXISTS idx_doku_eintraege_datum ON doku_eintraege (termin_datum DESC);
CREATE INDEX IF NOT EXISTS idx_doku_eintraege_status ON doku_eintraege (status);
CREATE INDEX IF NOT EXISTS idx_doku_eintraege_push ON doku_eintraege (ivoris_push_status) WHERE ivoris_push_status IN ('ausstehend', 'fehler');

-- ------------------------------------------------------------
-- 3) Versionen: append-only, revisionssicher (§ 630f BGB)
--    Jede Bestätigung und jede Änderung erzeugt eine neue Zeile.
--    UPDATE/DELETE sind per Trigger verboten.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doku_eintrag_versionen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  eintrag_id UUID NOT NULL REFERENCES doku_eintraege(id) ON DELETE RESTRICT,
  version INTEGER NOT NULL,
  text TEXT NOT NULL,
  zaehne TEXT[] NOT NULL DEFAULT '{}',
  variablen JSONB NOT NULL DEFAULT '{}',
  auswahl JSONB NOT NULL DEFAULT '{}',
  positionen JSONB NOT NULL DEFAULT '[]',
  ausnahme_freitext TEXT,
  aenderungsgrund TEXT,                    -- Pflicht ab Version 2 (App erzwingt das)
  erstellt_von UUID,                       -- auth.users id
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (eintrag_id, version)
);

CREATE INDEX IF NOT EXISTS idx_doku_versionen_eintrag ON doku_eintrag_versionen (eintrag_id, version);

-- Revisionssicherheit: Versionen sind unveränderlich
CREATE OR REPLACE FUNCTION doku_versionen_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'doku_eintrag_versionen ist append-only (§ 630f BGB): % nicht erlaubt', TG_OP;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS doku_versionen_no_update ON doku_eintrag_versionen;
CREATE TRIGGER doku_versionen_no_update
  BEFORE UPDATE OR DELETE ON doku_eintrag_versionen
  FOR EACH ROW EXECUTE FUNCTION doku_versionen_immutable();

-- ------------------------------------------------------------
-- 4) updated_at-Trigger (nutzt vorhandene Funktion update_updated_at aus 001)
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS doku_vorlagen_updated_at ON doku_vorlagen;
CREATE TRIGGER doku_vorlagen_updated_at BEFORE UPDATE ON doku_vorlagen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS doku_eintraege_updated_at ON doku_eintraege;
CREATE TRIGGER doku_eintraege_updated_at BEFORE UPDATE ON doku_eintraege
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- 5) Schutz: bestätigte Einträge nur mit Versionssprung änderbar
--    (Text/Positionen/Zähne ändern => version muss hochzählen;
--     die App legt parallel die neue Zeile in doku_eintrag_versionen an)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION doku_eintraege_guard()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'bestaetigt'
     AND (NEW.text IS DISTINCT FROM OLD.text
          OR NEW.positionen IS DISTINCT FROM OLD.positionen
          OR NEW.zaehne IS DISTINCT FROM OLD.zaehne
          OR NEW.variablen IS DISTINCT FROM OLD.variablen
          OR NEW.auswahl IS DISTINCT FROM OLD.auswahl)
     AND NEW.version <= OLD.version THEN
    RAISE EXCEPTION 'Bestätigter Eintrag: inhaltliche Änderung erfordert neue Version (alt %, neu %)', OLD.version, NEW.version;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS doku_eintraege_version_guard ON doku_eintraege;
CREATE TRIGGER doku_eintraege_version_guard
  BEFORE UPDATE ON doku_eintraege
  FOR EACH ROW EXECUTE FUNCTION doku_eintraege_guard();

-- DELETE auf Einträge verbieten (Akte wird nicht gelöscht, nur versioniert)
CREATE OR REPLACE FUNCTION doku_eintraege_no_delete()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'doku_eintraege dürfen nicht gelöscht werden (Aufbewahrungspflicht)';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS doku_eintraege_delete_guard ON doku_eintraege;
CREATE TRIGGER doku_eintraege_delete_guard
  BEFORE DELETE ON doku_eintraege
  FOR EACH ROW EXECUTE FUNCTION doku_eintraege_no_delete();

-- ------------------------------------------------------------
-- 6) Row Level Security (gleiches Muster wie Bestand)
-- ------------------------------------------------------------
ALTER TABLE doku_vorlagen ENABLE ROW LEVEL SECURITY;
ALTER TABLE doku_eintraege ENABLE ROW LEVEL SECURITY;
ALTER TABLE doku_eintrag_versionen ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users full access" ON doku_vorlagen;
CREATE POLICY "Authenticated users full access" ON doku_vorlagen
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users full access" ON doku_eintraege;
CREATE POLICY "Authenticated users full access" ON doku_eintraege
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Versionen: lesen + anlegen ja, ändern/löschen blockt zusätzlich der Trigger
DROP POLICY IF EXISTS "Authenticated read versions" ON doku_eintrag_versionen;
CREATE POLICY "Authenticated read versions" ON doku_eintrag_versionen
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated insert versions" ON doku_eintrag_versionen;
CREATE POLICY "Authenticated insert versions" ON doku_eintrag_versionen
  FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================================
-- Ende 019. Vorlagen-Seeding folgt separat (Inhalte erst mit
-- echten Praxistexten, Platzhalter-Katalog per Seed-Script).
-- ============================================================
