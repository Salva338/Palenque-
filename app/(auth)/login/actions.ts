"use server";

import { redirect } from "next/navigation";
import { z } from "zod";
import { loginErrorMessage } from "@/lib/auth/messages";
import { createClient } from "@/lib/supabase/server";

const LoginSchema = z.object({
  email: z.string().trim().toLowerCase().pipe(z.email({ error: "Revisá el email." })),
  password: z.string().min(1, { error: "Escribí la contraseña." }),
});

export type LoginState = { error?: string; email?: string };

export async function signIn(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const parsed = LoginSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });
  const email = String(formData.get("email") ?? "");
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? "Revisá los datos.", email };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) return { error: loginErrorMessage(error.code, error.message), email };

  redirect("/");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
