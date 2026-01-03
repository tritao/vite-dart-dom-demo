import fs from "node:fs";
import path from "node:path";
import { defineConfig, loadEnv } from "vite";
import Dart from "vite-plugin-dart";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const provisionedDart = path.join(
    process.cwd(),
    ".dart-sdk",
    "dart-sdk",
    "bin",
    "dart",
  );
  const dart =
    env.DART ??
    process.env.DART ??
    (fs.existsSync(provisionedDart) ? provisionedDart : "dart");

  return {
    plugins: [
      Dart({
        dart,
        stdio: true,
        verbosity: "all",
      }),
    ],
  };
});
