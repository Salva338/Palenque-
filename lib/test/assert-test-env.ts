/**
 * Freno de seguridad de las pruebas (sección 14.4 de la especificación).
 * Aborta si no estamos en el entorno de pruebas o si la URL de Supabase
 * no es la del proyecto palenque-test. Así ninguna prueba toca datos reales.
 */
export function assertTestEnvironment(env: Record<string, string | undefined> = process.env): {
  url: string;
  ref: string;
} {
  const appEnv = env.APP_ENV;
  const url = env.NEXT_PUBLIC_SUPABASE_URL ?? "";
  const ref = env.TEST_SUPABASE_PROJECT_REF ?? "";

  if (appEnv !== "test") {
    throw new Error(`Freno de pruebas: APP_ENV es "${appEnv ?? ""}" y tiene que ser "test".`);
  }
  if (!ref || ref.length < 10) {
    throw new Error("Freno de pruebas: falta TEST_SUPABASE_PROJECT_REF.");
  }
  let host: string;
  try {
    host = new URL(url).hostname;
  } catch {
    throw new Error("Freno de pruebas: NEXT_PUBLIC_SUPABASE_URL no es una dirección válida.");
  }
  if (host !== `${ref}.supabase.co`) {
    throw new Error(
      "Freno de pruebas: la URL de Supabase no es la del proyecto de pruebas. No se corre nada.",
    );
  }
  return { url, ref };
}
