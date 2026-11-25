/** Traduce los errores de inicio de sesión de Supabase a mensajes simples en castellano. */
export function loginErrorMessage(code: string | undefined, message: string | undefined): string {
  const texto = `${code ?? ""} ${message ?? ""}`.toLowerCase();
  if (texto.includes("invalid_credentials") || texto.includes("invalid login credentials")) {
    return "El email o la contraseña no coinciden.";
  }
  if (texto.includes("email_not_confirmed") || texto.includes("not confirmed")) {
    return "Ese email todavía no está confirmado.";
  }
  if (texto.includes("rate") || texto.includes("too many")) {
    return "Demasiados intentos seguidos. Esperá un minuto y probá de nuevo.";
  }
  return "No se pudo iniciar sesión. Probá de nuevo en un rato.";
}

export const ROLE_LABELS: Record<string, string> = {
  dueno: "Dueño",
  encargado: "Encargado",
  petisero: "Petisero",
  vet: "Veterinaria",
  herrero: "Herrero",
};
