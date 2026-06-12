import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Anima Scribe – Behandlungsdokumentation",
  description: "Chairside-Dokumentation in drei Klicks, PVS-unabhaengig.",
  manifest: "/manifest.json",
  icons: {
    icon: [
      { url: "/favicon-32x32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-16x16.png", sizes: "16x16", type: "image/png" },
    ],
    apple: "/apple-touch-icon.png",
    shortcut: "/favicon.ico",
  },
  appleWebApp: { capable: true, statusBarStyle: "black-translucent", title: "Anima Scribe" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
