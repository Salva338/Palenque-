"use client";

import { createBrowserClient } from "@supabase/ssr";
import { supabasePublicEnv } from "./env";

/** Cliente de Supabase para el navegador. Usa la llave pública: los permisos los decide RLS. */
export function createClient() {
  const { url, publishableKey } = supabasePublicEnv();
  return createBrowserClient(url, publishableKey);
}
