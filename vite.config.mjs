import { defineConfig, loadEnv } from "vite";
import Dart from "vite-plugin-dart";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const dart = env.DART ?? process.env.DART ?? "dart";

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
