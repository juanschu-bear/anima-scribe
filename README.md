# Anima Scribe

**Die Doku schreibt sich, während du behandelst. Nicht abends. Nicht am Wochenende.**

Anima Scribe verwandelt einen Termin in drei Klicks in einen fertigen,
revisionssicheren Karteieintrag, direkt in der Akte des Praxisverwaltungssystems.
Kein Abtippen, kein Nachtragen, keine halben Sätze um 19 Uhr. Die Person wählt
Termintyp und Patient, bestätigt eine bereits passende Vorlage, fertig.

Gebaut, weil gute Dokumentation überall am selben scheitert: Die Arbeit passiert
am Stuhl, die Doku passiert später und ungern. Scribe holt sie zurück an den Ort,
an dem sie entsteht.

---

## Was es kann

- **Vorschlagen statt Suchen.** Aus Termintyp und Patientenalter erscheint die
  richtige Vorlage von selbst. Niemand muss wissen, welches Kürzel wann passt.
- **Strukturiert statt Freitext.** Klickbares Schema, Auswahl-Chips, Variablen.
  Zwei Behandler, dieselbe saubere Struktur, jedes Mal.
- **Revisionssicher von Haus aus.** Append-only auf Datenbank-Ebene, Versionen
  statt Überschreiben, Behandler-Kürzel am Eintrag. §630f-konform gedacht.
- **Chairside.** Für das Tablet am Behandlungsplatz, nicht für den Schreibtisch.
- **Demo-Modus.** Gefahrloses Üben, es wird nichts gespeichert. Ideal für
  Schulung und skeptische Prüfblicke.
- **Team & Rechte.** Konten, Rollen, Kürzel, Passwörter, granulare Modulrechte,
  alles über die Oberfläche, ohne Kommandozeile.

## PVS-unabhängig: ein Adapter, jedes Zielsystem

Scribe schreibt nie fest an ein einzelnes System, sondern an eine neutrale
Schnittstelle (`src/lib/pvs/index.ts`). Mitgeliefert: der **ivoris-Adapter**.
Eine Praxis mit anderer Software bekommt einen eigenen Adapter (zwei Funktionen),
setzt `PVS_ADAPTER` um, und der gesamte übrige Code bleibt unangetastet.

```
src/lib/pvs/
  index.ts          Adapter-Auswahl + neutrale Schnittstelle (PvsAdapter)
  ivoris-adapter.ts Adapter 1: ivoris (computer konkret Relay)
  ...               weitere Adapter kommen hier dazu
```

> **Über KFO hinaus.** Der Kern von Scribe ist nicht kieferorthopädisch: Kontext
> erkennen, Vorlage vorschlagen, strukturiert erfassen, revisionssicher ins
> Fremdsystem schreiben. Das einzige fachspezifische Teil ist das Zahnschema,
> ein austauschbares Eingabe-Widget. Tausche es gegen einen Körperbereich, eine
> Mängelliste, eine Objektskizze, und dieselbe Engine dokumentiert Physiotherapie,
> Dermatologie, Pflege, Gutachten oder Handwerk. Die Architektur lässt das offen.

## Einrichtung

1. Neues, leeres Repo anlegen, diesen Ordner hineinlegen, pushen.
2. Eigene Supabase-Instanz anlegen.
3. Migrationen aus `supabase/migrations/` in Reihenfolge im SQL-Editor ausführen
   (000 zuerst, dann 019, 019b–019f, 020, 021).
4. `.env.example` nach `.env.local` kopieren und ausfüllen.
5. `npm install`, dann `npm run build`.
6. Erstes Admin-Konto anlegen (siehe unten), danach läuft alles über die App.
7. Auf Vercel deployen, Variablen dort hinterlegen, eigene Domain mappen.

### Erstes Admin-Konto

Bewusst keine Selbstregistrierung. Das erste Admin-Konto einmalig über das
Supabase-Dashboard anlegen (Authentication → Add user, E-Mail bestätigt) und in
`user_profiles` mit `role = 'admin'` eintragen. Alle weiteren Konten danach über
**Team & Zugänge** in der App.

## Bewusste Grenzen

- Termine: Patient wird manuell gesucht, keine Kalenderanbindung in dieser Variante.
- Die Kopplung an Anima Cura (Doku-Eintrag ↔ Zahlung) ist hier nicht enthalten.
  Dieses Standalone steht für sich.
- Vor Produktivbetrieb mit personenbezogenen Daten: AVV und TOMs der Praxis, und
  ein passender PVS-Adapter, falls nicht ivoris.

---

*Teil der Anima-Produktreihe.* - ONIOKO - EXIDEUS LLX
