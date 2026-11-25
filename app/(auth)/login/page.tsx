import Image from "next/image";
import { supabaseConfigured } from "@/lib/supabase/env";
import { LoginForm } from "./login-form";

export const metadata = { title: "Entrar · Palenque" };

export default function LoginPage() {
  const configurado = supabaseConfigured();

  return (
    <div className="mx-auto flex min-h-screen max-w-[480px] flex-col bg-bg shadow-[0_0_40px_rgba(0,0,0,.08)]">
      <header className="flex flex-col items-center gap-3 bg-green px-6 pb-8 pt-12 text-bg">
        <Image src="/logo.png" alt="Logo de Palenque" width={72} height={64} priority />
        <h1 className="text-[30px]">Palenque</h1>
        <p className="-mt-2 text-sm opacity-75">Gestión de caballerizas</p>
      </header>

      <main className="flex-1 p-5">
        <h2 className="mb-1 text-[22px]">Entrar</h2>
        <p className="mb-5 text-muted">Usá el email y la contraseña que te dio el dueño del haras.</p>

        {configurado ? (
          <LoginForm />
        ) : (
          <p role="alert" className="rounded-xl bg-[#f7ebcf] px-3 py-2 text-sm text-[#6b4a0d]">
            Todavía no está conectada la base de datos. Faltan las variables de Supabase en Vercel.
          </p>
        )}
      </main>
    </div>
  );
}
