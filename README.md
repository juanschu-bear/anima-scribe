# Anima Scribe (Standalone)

Chairside-Behandlungsdokumentation in drei Klicks: Termintyp und Patient wählen,
vorbereitete Vorlage bestätigen, in die Patientenakte des Praxisverwaltungssystems
(PVS) schreiben. Append-only, versioniert, mit Behandler-Kürzel, Demo-Modus und
rollenbasierter Team-Verwaltung.

Diese Standalone-Variante ist **unabhängig von Anima Cura** und **PVS-neutral**:
Das Zielsystem (ivoris oder ein anderes) steckt hinter einem austauschbaren Adapter.

## Was drin ist

- **Scribe-Cockpit** (`/scribe`): Patientensuche, altersgefilterte Vorlagen,
  klickbares Zahnschema (FDI, bukkal/palatinal/lingual), Variablen, Positionen,
  Bestätigen, Versionen, Verwerfen, Demo-Modus, Spickzettel, Hell/Dunkel.
- **PVS-Push** (`/api/doku/.../ivoris-push`): schreibt über den PVS-Adapter.
- **Team & Zugänge** (`/scribe/team`, nur Admin): Konten, Rollen, Kürzel,
  Passwörter, granulare Modulrechte. Eigenes Passwort ändern für alle.
- **Auth**: eine Benutzer-DB (Supabase), Rollen admin / verwaltung / lesezugriff.

## PVS-Adapter (der Kern der Wiederverwendbarkeit)

Scribe schreibt nie direkt an ein bestimmtes System, sondern an die neutrale
Schnittstelle in `src/lib/pvs/index.ts`. Mitgeliefert ist der **ivoris-Adapter**.

Eine Praxis mit anderem PVS bekommt einen neuen Adapter, der zwei Funktionen
erfüllt (`addKarteiEintrag`, optional `fetchKarteiEintraege`), und setzt
`PVS_ADAPTER` in der Umgebung. Der restliche Code bleibt unverändert.

```
src/lib/pvs/
  index.ts          <- Adapter-Auswahl + neutrale Schnittstelle (PvsAdapter)
  ivoris-adapter.ts <- Adapter 1: ivoris (computer konkret Relay)
  (hier kommen weitere Adapter dazu)
```

## Einrichtung

1. Neues, leeres GitHub-Repo anlegen, diesen Ordner hineinlegen, pushen.
2. Eigene Supabase-Instanz anlegen.
3. Migrationen aus `supabase/migrations/` im Supabase-SQL-Editor in Reihenfolge
   ausführen (000 zuerst, dann 019, 019b–019f, 020, 021).
4. `.env.example` nach `.env.local` kopieren und ausfüllen (Supabase, Mail-Domain,
   PVS_ADAPTER, ggf. ivoris-Zugänge der Praxis).
5. `npm install` und `npm run build`.
6. Erstes Admin-Konto anlegen (siehe unten).
7. Auf Vercel deployen, Umgebungsvariablen dort hinterlegen, eigene Domain mappen.

## Erstes Admin-Konto

Es gibt bewusst keine Selbstregistrierung. Das erste Admin-Konto wird einmalig
über das Supabase-Dashboard (Authentication → Add user, E-Mail bestätigt) plus
einen Eintrag in `user_profiles` mit `role = 'admin'` angelegt. Danach laufen
alle weiteren Konten über **Team & Zugänge** in der App.

## Grenzen / Hinweise

- Termine: Patient wird manuell gesucht. Eine Kalenderanbindung ist nicht Teil
  dieser Variante.
- Die verbundene Anima-Cura-Kopplung (Doku-Eintrag ↔ Zahlung) ist hier bewusst
  NICHT enthalten; dieses Standalone steht für sich.
- Vor Produktivbetrieb mit Patientendaten: AVV und TOMs der jeweiligen Praxis,
  und ein eigener PVS-Adapter, falls nicht ivoris.
