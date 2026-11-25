import Image from "next/image";
import { Suspense } from "react";
import { ROLE_LABELS } from "@/lib/auth/messages";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "../(auth)/login/actions";

// Con cacheComponents, lo que depende de la sesión (cookies) va dentro de <Suspense>.
export default function Home() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto min-h-screen max-w-[480px] bg-bg">
          <div className="h-[62px] bg-green" />
          <p className="p-4 text-muted">Cargando…</p>
        </div>
      }
    >
      <HomeContent />
    </Suspense>
  );
}

async function HomeContent() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // RLS: cada usuario solo ve sus propias membresías y organizaciones.
  const { data: membresias } = await supabase
    .from("memberships")
    .select("role, display_name, organizations(name)")
    .eq("user_id", user?.id ?? "");
  const m = membresias?.[0];
  const org = m?.organizations as { name: string } | { name: string }[] | null | undefined;
  const orgName = Array.isArray(org) ? org[0]?.name : org?.name;

  const { count: caballos } = await supabase.from("horses").select("id", { count: "exact", head: true });

  return (
    <div className="mx-auto flex min-h-screen max-w-[480px] flex-col bg-bg shadow-[0_0_40px_rgba(0,0,0,.08)]">
      <header className="flex items-center gap-2.5 bg-green px-4 py-3 text-bg">
        <Image src="/logo.png" alt="Logo de Palenque" width={43} height={38} priority />
        <div className="min-w-0 flex-1">
          <b className="block font-serif text-[21px]">Palenque</b>
          <small className="-mt-0.5 block truncate text-[11px] opacity-70">{orgName ?? "Sin organización"}</small>
        </div>
        {m ? (
          <span className="rounded-full border border-white/30 bg-white/10 px-2.5 py-1 text-xs">
            {ROLE_LABELS[m.role] ?? m.role}
          </span>
        ) : null}
      </header>

      <main className="flex-1 p-4">
        <h1 className="mt-1 text-[26px]">¡Hola{m ? `, ${m.display_name}` : ""}!</h1>
        <p className="mt-0.5 text-muted">{user?.email}</p>

        {m ? (
          <div className="mt-4 rounded-2xl border border-line bg-card p-3.5">
            <h3 className="mb-1 text-[17px]">{orgName}</h3>
            <p className="text-[14.5px]">
              Caballos cargados: <b>{caballos ?? 0}</b>
            </p>
          </div>
        ) : (
          <p className="mt-4 rounded-xl bg-[#f7ebcf] px-3 py-2 text-sm text-[#6b4a0d]">
            Tu usuario todavía no está asignado a ningún haras. Pedile al dueño que te agregue.
          </p>
        )}

        <form action={signOut} className="mt-6">
          <button type="submit" className="rounded-xl border border-line bg-card px-4 py-2.5 text-sm font-semibold">
            Cerrar sesión
          </button>
        </form>

        <span className="mt-6 inline-block rounded-full bg-brass px-3 py-1 text-xs font-semibold text-white">
          Fase 3 · base de datos y usuarios
        </span>
      </main>
    </div>
  );
}
