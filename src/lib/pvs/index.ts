// ============================================================
// PVS-Adapter (Praxisverwaltungssystem)
//
// Anima Scribe schreibt Dokumentation NICHT direkt an ein bestimmtes
// System, sondern an diese neutrale Schnittstelle. Dahinter steckt ein
// austauschbarer Adapter: ivoris (mitgeliefert), ein anderes PVS, oder
// als Minimal-Fallback ein reiner Export.
//
// Eine neue Praxis ohne ivoris (z. B. mit anderer Software) bekommt
// einen eigenen Adapter, der genau diese zwei Funktionen erfuellt.
// Der restliche Scribe-Code bleibt unveraendert.
//
// Auswahl per Umgebungsvariable PVS_ADAPTER (default "ivoris").
// ============================================================

import {
  addIvorisKarteiEintrag,
  fetchIvorisKarteiEintraege,
} from "./ivoris-adapter";

export type PvsKarteiEintragInput = {
  patientPvsId: string;
  /** ISO-Datum YYYY-MM-DD */
  date: string;
  text: string;
  /** Nur setzen, wenn genau ein Zahn betroffen ist (FDI, z. B. "21") */
  tooth?: string;
  type?: "Text" | "Note";
};

export type PvsKarteiEintragResult = {
  entryId: string;
};

export interface PvsAdapter {
  /** Name des Zielsystems, fuer Logs und UI. */
  readonly name: string;
  /** Schreibt einen Karteieintrag ins PVS, liefert dessen Id zurueck. */
  addKarteiEintrag(input: PvsKarteiEintragInput): Promise<PvsKarteiEintragResult>;
  /** Liest vorhandene Karteieintraege eines Patienten (optional). */
  fetchKarteiEintraege?(patientPvsId: string): Promise<unknown[]>;
}

// ---- Adapter 1: ivoris (computer konkret Relay) ----
const ivorisAdapter: PvsAdapter = {
  name: "ivoris",
  async addKarteiEintrag(input) {
    const r = await addIvorisKarteiEintrag({
      patientIvorisId: input.patientPvsId,
      date: input.date,
      text: input.text,
      tooth: input.tooth,
      type: input.type,
    });
    return { entryId: r.entryId };
  },
  fetchKarteiEintraege: (patientPvsId) => fetchIvorisKarteiEintraege(patientPvsId),
};

// ---- Platzhalter fuer kuenftige Adapter ----
// Beispiel: ein anderes PVS oder ein Export-only-Adapter.
// const anderesPvsAdapter: PvsAdapter = { name: "anderes-pvs", async addKarteiEintrag(input) { ... } };

const ADAPTER: Record<string, PvsAdapter> = {
  ivoris: ivorisAdapter,
  // "anderes-pvs": anderesPvsAdapter,
};

export function getPvsAdapter(): PvsAdapter {
  const gewuenscht = (process.env.PVS_ADAPTER ?? "ivoris").toLowerCase();
  const adapter = ADAPTER[gewuenscht];
  if (!adapter) {
    throw new Error(
      `Unbekannter PVS_ADAPTER "${gewuenscht}". Verfuegbar: ${Object.keys(ADAPTER).join(", ")}.`
    );
  }
  return adapter;
}
