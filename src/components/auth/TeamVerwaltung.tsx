"use client";

import { useEffect, useState } from "react";
import { useScribeUser } from "@/components/auth/ScribeUserContext";
import { MODULE, STUFEN, effektiveStufe, type Stufe } from "@/lib/permissions";

// Team & Zugaenge fuer das Standalone-Scribe (Scribe-Design, kein Tailwind).
// Nutzt die plattformweiten /api/team-Routen. Nur fuer Admins.

type Mitglied = {
  id: string;
  email: string;
  display_name: string;
  role: string;
  kuerzel: string | null;
  permissions?: { scribe_schreiben?: boolean; module?: Record<string, string> } | null;
};

const ROLLEN = [
  { wert: "admin", label: "Admin" },
  { wert: "verwaltung", label: "Verwaltung" },
  { wert: "lesezugriff", label: "Lesezugriff" },
];

function PwFeld({ wert, setzen, platzhalter, onEnter }: { wert: string; setzen: (v: string) => void; platzhalter: string; onEnter?: () => void }) {
  const [sichtbar, setSichtbar] = useState(false);
  return (
    <span className="pwfeld klein">
      <input type={sichtbar ? "text" : "password"} value={wert} placeholder={platzhalter} autoComplete="new-password"
        onChange={(e) => setzen(e.target.value)} onKeyDown={(e) => e.key === "Enter" && onEnter?.()} />
      <button type="button" className="pwauge" aria-label={sichtbar ? "Passwort verbergen" : "Passwort anzeigen"} onClick={() => setSichtbar((s) => !s)}>
        {sichtbar ? "\u{1F648}" : "\u{1F441}"}
      </button>
    </span>
  );
}

export default function TeamVerwaltung() {
  const authUser = useScribeUser();
  const istAdmin = authUser?.role === "admin";

  const [mitglieder, setMitglieder] = useState<Mitglied[]>([]);
  const [mailDomain, setMailDomain] = useState("praxis.example");
  const [hinweis, setHinweis] = useState<{ ok: boolean; text: string } | null>(null);
  const [laeuft, setLaeuft] = useState(false);
  const [neu, setNeu] = useState({ name: "", lokal: "", rolle: "verwaltung", kuerzel: "", passwort: "" });
  const [editId, setEditId] = useState<string | null>(null);
  const [editRolle, setEditRolle] = useState("verwaltung");
  const [editKuerzel, setEditKuerzel] = useState("");
  const [editScribe, setEditScribe] = useState(false);
  const [editModule, setEditModule] = useState<Record<string, Stufe>>({});
  const [resetId, setResetId] = useState<string | null>(null);
  const [resetPw, setResetPw] = useState("");

  async function laden() {
    setHinweis(null);
    const res = await fetch("/api/team");
    const json = await res.json().catch(() => ({}));
    if (!res.ok) { setHinweis({ ok: false, text: json.error ?? "Team konnte nicht geladen werden." }); return; }
    setMitglieder(json.mitglieder ?? []);
    if (json.mail_domain) setMailDomain(json.mail_domain);
  }
  useEffect(() => { if (istAdmin) laden(); }, [istAdmin]);

  async function anlegen() {
    setHinweis(null); setLaeuft(true);
    const res = await fetch("/api/team", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(neu) });
    const json = await res.json().catch(() => ({})); setLaeuft(false);
    if (!res.ok) { setHinweis({ ok: false, text: json.error ?? "Anlegen fehlgeschlagen." }); return; }
    setNeu({ name: "", lokal: "", rolle: "verwaltung", kuerzel: "", passwort: "" });
    setHinweis({ ok: true, text: `${json.mitglied.email} angelegt.` }); laden();
  }
  function bearbeitenStarten(m: Mitglied) {
    setEditId(m.id); setEditRolle(m.role); setEditKuerzel(m.kuerzel ?? "");
    setEditScribe(m.permissions?.scribe_schreiben ?? ["admin", "verwaltung"].includes(m.role));
    const stufen: Record<string, Stufe> = {};
    for (const mod of MODULE) stufen[mod.schluessel] = effektiveStufe(m.role as never, m.permissions ?? null, mod.schluessel);
    setEditModule(stufen); setResetId(null);
  }
  async function speichern(id: string) {
    setHinweis(null); setLaeuft(true);
    const res = await fetch(`/api/team/${id}`, { method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ rolle: editRolle, kuerzel: editKuerzel, scribe_schreiben: editScribe, module_stufen: editModule }) });
    const json = await res.json().catch(() => ({})); setLaeuft(false);
    if (!res.ok) { setHinweis({ ok: false, text: json.error ?? "Speichern fehlgeschlagen." }); return; }
    setEditId(null); laden();
  }
  async function passwortSetzen(id: string) {
    setHinweis(null);
    if (resetPw.length < 8) { setHinweis({ ok: false, text: "Passwort: mindestens 8 Zeichen." }); return; }
    setLaeuft(true);
    const res = await fetch(`/api/team/${id}/passwort`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ passwort: resetPw }) });
    const json = await res.json().catch(() => ({})); setLaeuft(false);
    if (!res.ok) { setHinweis({ ok: false, text: json.error ?? "Passwort-Reset fehlgeschlagen." }); return; }
    setResetId(null); setResetPw(""); setHinweis({ ok: true, text: "Passwort gesetzt." });
  }

  if (!istAdmin) {
    return <div className="detailkarte"><div className="ohead spalte"><span className="otitel gross">Team &amp; Zugänge</span></div>
      <p className="detailmeta">Die Benutzerverwaltung ist Administratoren vorbehalten.</p></div>;
  }

  return (
    <div className="detailkarte" style={{ maxWidth: 860 }}>
      <div className="ohead spalte">
        <span className="otitel gross">Team &amp; Zugänge</span>
        <span className="o-unter">Konten · Rollen · Kürzel · Passwörter · Modulrechte</span>
      </div>
      {hinweis && <p className={hinweis.ok ? "hinweis-ok" : "hinweis-fehlt"} style={{ marginTop: 8 }}>{hinweis.text}</p>}

      <div className="team-kopfzeile"><span>Konto</span><span>Kürzel</span><span>Rolle</span><span>Passwort &amp; Rechte</span></div>
      {mitglieder.map((m) => (
        <div className="team-zeile" key={m.id}>
          <div className="team-info"><div className="team-name">{m.display_name}</div><div className="team-mail">{m.email}</div></div>
          <span className="team-kuerzelzelle">{m.kuerzel ?? "—"}</span>
          <span className="team-rolle">
            <span className={`pille rollen-${m.role}`} style={{ position: "static" }}>{m.role}</span>
            {m.permissions?.scribe_schreiben === true && m.role === "lesezugriff" && <span className="perm-tag plus">+ Scribe</span>}
          </span>
          {resetId === m.id ? (
            <span className="team-edit">
              <PwFeld wert={resetPw} setzen={setResetPw} platzhalter="Neues Passwort" onEnter={() => passwortSetzen(m.id)} />
              <button className="neben klein" disabled={laeuft} onClick={() => passwortSetzen(m.id)}>OK</button>
              <button className="neben klein" onClick={() => { setResetId(null); setResetPw(""); }}>Abbruch</button>
            </span>
          ) : (
            <span className="team-edit">
              <button className="neben klein" onClick={() => bearbeitenStarten(m)}>Bearbeiten</button>
              <button className="neben klein" onClick={() => { setResetId(m.id); setResetPw(""); setEditId(null); }}>Passwort</button>
            </span>
          )}
        </div>
      ))}

      {editId && (
        <div className="team-matrix">
          <p className="team-matrix-titel">Bearbeiten: {mitglieder.find((m) => m.id === editId)?.display_name ?? "Konto"}</p>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 12, alignItems: "flex-end", marginBottom: 14 }}>
            <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              <span className="team-matrix-hinweis" style={{ margin: 0 }}>Rolle</span>
              <select value={editRolle} onChange={(e) => setEditRolle(e.target.value)}>{ROLLEN.map((r) => <option key={r.wert} value={r.wert}>{r.label}</option>)}</select>
            </label>
            <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              <span className="team-matrix-hinweis" style={{ margin: 0 }}>Kürzel</span>
              <input value={editKuerzel} onChange={(e) => setEditKuerzel(e.target.value)} placeholder="z. B. ms" style={{ width: 90 }} />
            </label>
            <label className="perm-schalter" style={{ paddingBottom: 6 }}>
              <input type="checkbox" checked={editScribe} onChange={(e) => setEditScribe(e.target.checked)} /> Scribe: dokumentieren &amp; ivoris
            </label>
          </div>
          <p className="team-matrix-titel">Modulrechte</p>
          <p className="team-matrix-hinweis">Stufe pro Modul, übersteuert die Rolle. Gilt, sobald weitere Module hinzukommen.</p>
          <div className="team-matrix-raster">
            {MODULE.map((mod) => (
              <label className="team-matrix-zelle" key={mod.schluessel}>
                <span>{mod.label}</span>
                <select value={editModule[mod.schluessel] ?? "keine"} onChange={(e) => setEditModule({ ...editModule, [mod.schluessel]: e.target.value as Stufe })}>
                  {STUFEN.map((s) => <option key={s} value={s}>{s}</option>)}
                </select>
              </label>
            ))}
          </div>
          <div className="aktionen" style={{ marginTop: 14 }}>
            <button className="haupt" disabled={laeuft} onClick={() => speichern(editId)}>Speichern</button>
            <button className="neben" onClick={() => setEditId(null)}>Abbrechen</button>
          </div>
        </div>
      )}

      <p className="spick-bereich" style={{ marginTop: 24 }}>Neues Teammitglied</p>
      <div className="team-form">
        <input value={neu.name} onChange={(e) => setNeu({ ...neu, name: e.target.value })} placeholder="Name, z. B. Dr. Maria Schubert" />
        <span className="mail-feld">
          <input value={neu.lokal} onChange={(e) => setNeu({ ...neu, lokal: e.target.value })} placeholder="vorname" />
          <span className="mail-suffix">@{mailDomain}</span>
        </span>
        <select value={neu.rolle} onChange={(e) => setNeu({ ...neu, rolle: e.target.value })}>{ROLLEN.map((r) => <option key={r.wert} value={r.wert}>{r.label}</option>)}</select>
        <input value={neu.kuerzel} onChange={(e) => setNeu({ ...neu, kuerzel: e.target.value })} placeholder="Kürzel, z. B. ms" />
        <PwFeld wert={neu.passwort} setzen={(v) => setNeu({ ...neu, passwort: v })} platzhalter="Startpasswort (mind. 8 Zeichen)" />
      </div>
      <div className="aktionen" style={{ marginTop: 12 }}>
        <button className="haupt" disabled={laeuft} onClick={anlegen}>{laeuft ? "Arbeitet …" : "Anlegen"}</button>
      </div>
    </div>
  );
}
