import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Anima Scribe – Behandlungsdokumentation",
  description: "Chairside-Dokumentation in drei Klicks, PVS-unabhaengig.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
