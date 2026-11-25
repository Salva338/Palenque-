"use client";

import { useActionState } from "react";
import { signIn, type LoginState } from "./actions";

export function LoginForm() {
  const [state, action, pending] = useActionState<LoginState, FormData>(signIn, {});

  return (
    <form action={action} className="space-y-3" noValidate>
      <label className="block">
        <span className="mb-1 block text-[12.5px] font-semibold uppercase tracking-wide text-muted">Email</span>
        <input
          name="email"
          type="email"
          inputMode="email"
          autoComplete="email"
          defaultValue={state.email}
          required
          className="w-full rounded-xl border border-line bg-card px-3 py-2.5 outline-none focus:border-green2"
        />
      </label>
      <label className="block">
        <span className="mb-1 block text-[12.5px] font-semibold uppercase tracking-wide text-muted">Contraseña</span>
        <input
          name="password"
          type="password"
          autoComplete="current-password"
          required
          className="w-full rounded-xl border border-line bg-card px-3 py-2.5 outline-none focus:border-green2"
        />
      </label>

      {state.error ? (
        <p role="alert" className="rounded-xl bg-[#f8e1db] px-3 py-2 text-sm text-[#7e2a1b]">
          {state.error}
        </p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-xl bg-green px-4 py-3.5 text-base font-semibold text-bg disabled:opacity-60"
      >
        {pending ? "Entrando…" : "Entrar"}
      </button>
    </form>
  );
}
