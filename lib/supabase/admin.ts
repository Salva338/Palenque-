import "server-only";

import { createClient } from "@supabase/supabase-js";
import { supabasePublicEnv } from "./env";

/**
 * Cliente con la llave secreta: SALTA RLS.
 * Solo para el servidor (webhook, tareas programadas, invitar usuarios).
 * Todo código que lo use tiene que aplicar la matriz de permisos a mano (sección 5.2).
 */
export function createAdminClient() {
  const { url } = supabasePublicEnv();
  const secret = process.env.SUPABASE_SECRET_KEY?.trim();
  if (!secret) throw new Error("Falta SUPABASE_SECRET_KEY (solo en el servidor).");
  return createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
}
