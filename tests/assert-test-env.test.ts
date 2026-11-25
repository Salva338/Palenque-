import { describe, expect, it } from "vitest";
import { assertTestEnvironment } from "@/lib/test/assert-test-env";

const REF_TEST = "abcdefghijklmnopqrst";

describe("assertTestEnvironment()", () => {
  it("deja pasar el proyecto de pruebas", () => {
    expect(
      assertTestEnvironment({
        APP_ENV: "test",
        TEST_SUPABASE_PROJECT_REF: REF_TEST,
        NEXT_PUBLIC_SUPABASE_URL: `https://${REF_TEST}.supabase.co`,
      }).ref,
    ).toBe(REF_TEST);
  });

  it("aborta con una URL de 'producción'", () => {
    expect(() =>
      assertTestEnvironment({
        APP_ENV: "test",
        TEST_SUPABASE_PROJECT_REF: REF_TEST,
        NEXT_PUBLIC_SUPABASE_URL: "https://zzzzzzzzzzzzzzzzzzzz.supabase.co",
      }),
    ).toThrow(/no es la del proyecto de pruebas/);
  });

  it("aborta si la URL solo contiene el ref como trampa", () => {
    expect(() =>
      assertTestEnvironment({
        APP_ENV: "test",
        TEST_SUPABASE_PROJECT_REF: REF_TEST,
        NEXT_PUBLIC_SUPABASE_URL: `https://prod.supabase.co/?x=${REF_TEST}`,
      }),
    ).toThrow();
  });

  it("aborta si APP_ENV no es test", () => {
    expect(() =>
      assertTestEnvironment({
        APP_ENV: "production",
        TEST_SUPABASE_PROJECT_REF: REF_TEST,
        NEXT_PUBLIC_SUPABASE_URL: `https://${REF_TEST}.supabase.co`,
      }),
    ).toThrow(/APP_ENV/);
  });

  it("aborta si falta el ref de pruebas", () => {
    expect(() =>
      assertTestEnvironment({
        APP_ENV: "test",
        NEXT_PUBLIC_SUPABASE_URL: `https://${REF_TEST}.supabase.co`,
      }),
    ).toThrow(/TEST_SUPABASE_PROJECT_REF/);
  });
});
