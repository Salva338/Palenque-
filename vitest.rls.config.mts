import { fileURLToPath } from "node:url";
import { config as cargarEnv } from "dotenv";
import { defineConfig } from "vitest/config";

// En la compu se leen las llaves de .env.test.local. En GitHub Actions vienen como secretos.
cargarEnv({ path: ".env.test.local", quiet: true });

export default defineConfig({
  resolve: {
    alias: { "@": fileURLToPath(new URL("./", import.meta.url)) },
  },
  test: {
    include: ["tests/rls/**/*.test.ts"],
    environment: "node",
    testTimeout: 30_000,
    fileParallelism: false,
  },
});
