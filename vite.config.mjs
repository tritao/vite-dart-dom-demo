import fs from "node:fs";
import path from "node:path";
import { defineConfig, loadEnv } from "vite";
import Dart from "vite-plugin-dart";

export default defineConfig(({ mode, command }) => {
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

  // GitHub Pages serves the app at /<repo>/, so the build must use that base.
  const githubRepo = process.env.GITHUB_REPOSITORY?.split("/")[1];
  const explicitBase =
    env.BASE ??
    env.VITE_BASE ??
    process.env.BASE ??
    process.env.VITE_BASE ??
    null;
  const base = explicitBase
    ? explicitBase
    : process.env.GITHUB_ACTIONS && githubRepo
      ? `/${githubRepo}/`
      : command === "build"
        ? "./"
        : "/";

  const buildWordproc =
    env.BUILD_WORDPROC === "1" ||
    env.VITE_BUILD_WORDPROC === "1" ||
    process.env.BUILD_WORDPROC === "1" ||
    process.env.VITE_BUILD_WORDPROC === "1";

  return {
    base,
    build: {
      rollupOptions: {
        input: {
          index: path.resolve(process.cwd(), "index.html"),
          docs: path.resolve(process.cwd(), "docs.html"),
          labs: path.resolve(process.cwd(), "labs.html"),
          ...(buildWordproc
            ? { wordproc: path.resolve(process.cwd(), "wordproc.html") }
            : {}),
        },
      },
    },
    plugins: [
      Dart({
        dart,
        stdio: true,
        verbosity: "all",
      }),
    ],
  };
});
