import { describe, expect, it } from "vitest";
import { loginErrorMessage, ROLE_LABELS } from "@/lib/auth/messages";

describe("mensajes de inicio de sesión", () => {
  it("credenciales incorrectas", () => {
    expect(loginErrorMessage("invalid_credentials", "Invalid login credentials")).toBe(
      "El email o la contraseña no coinciden.",
    );
  });
  it("demasiados intentos", () => {
    expect(loginErrorMessage("over_request_rate_limit", "Request rate limit reached")).toMatch(/Esperá un minuto/);
  });
  it("error desconocido no muestra detalles técnicos", () => {
    expect(loginErrorMessage(undefined, "socket hang up")).toBe("No se pudo iniciar sesión. Probá de nuevo en un rato.");
  });
  it("los cinco roles tienen nombre en castellano", () => {
    expect(Object.keys(ROLE_LABELS).sort()).toEqual(["dueno", "encargado", "herrero", "petisero", "vet"]);
  });
});
