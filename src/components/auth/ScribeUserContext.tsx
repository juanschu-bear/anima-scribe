"use client";

import { createContext, useContext } from "react";
import type { AppRole } from "@/lib/auth";

// Schlanker Nutzer-Kontext fuer das Standalone-Scribe.
// Stellt den angemeldeten Benutzer (Rolle, Name) den Komponenten bereit,
// ohne das groessere App-Store-Konstrukt von Anima Cura.

export type ScribeUser = {
  id: string;
  email: string;
  fullName: string;
  role: AppRole;
} | null;

const ScribeUserContext = createContext<ScribeUser>(null);

export function ScribeUserProvider({
  user,
  children,
}: {
  user: ScribeUser;
  children: React.ReactNode;
}) {
  return <ScribeUserContext.Provider value={user}>{children}</ScribeUserContext.Provider>;
}

export function useScribeUser(): ScribeUser {
  return useContext(ScribeUserContext);
}
