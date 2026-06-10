import { redirect } from "next/navigation";
import { getAuthenticatedAppUser } from "@/lib/db/supabase-server";
import { ScribeUserProvider } from "@/components/auth/ScribeUserContext";
import TeamVerwaltung from "@/components/auth/TeamVerwaltung";
import Link from "next/link";

export const dynamic = "force-dynamic";

export default async function TeamPage() {
  const user = await getAuthenticatedAppUser();
  if (!user) redirect("/scribe/login");
  if (user.role !== "admin") redirect("/scribe");

  return (
    <ScribeUserProvider user={{ id: user.id, email: user.email, fullName: user.fullName, role: user.role }}>
      <div className="team-seite">
        <Link href="/scribe" className="team-zurueck">← Zurück zum Cockpit</Link>
        <TeamVerwaltung />
      </div>
    </ScribeUserProvider>
  );
}
