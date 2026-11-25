import Image from "next/image";

export default function Home() {
  return (
    <div className="mx-auto flex min-h-screen max-w-[480px] flex-col bg-bg shadow-[0_0_40px_rgba(0,0,0,.08)]">
      <header className="flex items-center gap-2.5 bg-green px-4 py-3 text-bg">
        <Image src="/logo.png" alt="Logo de Palenque" width={43} height={38} priority />
        <div>
          <b className="block font-serif text-[21px]">Palenque</b>
          <small className="-mt-0.5 block text-[11px] opacity-70">Gestión de caballerizas</small>
        </div>
      </header>

      <main className="flex-1 p-4">
        <h1 className="mt-1 text-[26px]">¡Hola!</h1>
        <p className="mt-0.5 text-muted">
          Palenque está en construcción. Esta es la primera versión publicada.
        </p>

        <div className="mt-4 rounded-2xl border border-line bg-card p-3.5">
          <h3 className="mb-2 text-[17px]">Qué viene</h3>
          <ul className="list-disc space-y-1 pl-5 text-[14.5px]">
            <li>Ficha de cada caballo con su historial</li>
            <li>Agenda y alertas automáticas</li>
            <li>Carga de novedades por WhatsApp</li>
          </ul>
        </div>

        <span className="mt-4 inline-block rounded-full bg-brass px-3 py-1 text-xs font-semibold text-white">
          Fase 2 · proyecto base
        </span>
      </main>
    </div>
  );
}
