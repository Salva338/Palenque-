import "server-only";

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { supabasePublicEnv } from "./env";

/**
 * Cliente de Supabase para el servidor (componentes de servidor y acciones).
 * Actúa como el usuario que inició sesión: RLS aplica sus permisos.
 */
export async function createClient() {
  // cookies() primero: marca la página como dinámica (depende de quién entra) y no se prearma al compilar.
  const cookieStore = await cookies();
  const { url, publishableKey } = supabasePublicEnv();

  return createServerClient(url, publishableKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) cookieStore.set(name, value, options);
        } catch {
          // Desde un componente de servidor no se pueden escribir cookies; el proxy renueva la sesión.
        }
      },
    },
  });
}
