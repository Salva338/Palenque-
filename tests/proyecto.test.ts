import { existsSync, readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { norm } from "@/lib/rules/norm";

describe("configuración del proyecto", () => {
  it("existe .env.example con las variables de Supabase", () => {
    expect(existsSync(".env.example")).toBe(true);
    const contenido = readFileSync(".env.example", "utf8");
    for (const nombre of [
      "NEXT_PUBLIC_SUPABASE_URL",
      "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
      "SUPABASE_SECRET_KEY",
    ]) {
      expect(contenido).toMatch(new RegExp(`^${nombre}=$`, "m"));
    }
  });

  it(".env.example no trae valores cargados", () => {
    const lineas = readFileSync(".env.example", "utf8")
      .split("\n")
      .filter((l) => /^[A-Z_]+=/.test(l) && !l.startsWith("APP_ENV="));
    for (const linea of lineas) expect(linea).toMatch(/=$/);
  });

  it(".gitignore excluye los .env reales", () => {
    const gi = readFileSync(".gitignore", "utf8");
    expect(gi).toMatch(/^\.env\*$/m);
  });
});

describe("norm()", () => {
  it("saca tildes, mayúsculas y espacios sobrantes", () => {
    expect(norm("  Picardía  Rengo ")).toBe("picardia rengo");
    expect(norm(null)).toBe("");
  });
});
