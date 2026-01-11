import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
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

  const ensureDartPubGet = () => {
    const packageConfig = path.join(
      process.cwd(),
      ".dart_tool",
      "package_config.json",
    );
    if (fs.existsSync(packageConfig)) return;
    console.log(
      `[solidus] Missing .dart_tool/package_config.json; running "${dart} pub get"`,
    );
    const result = spawnSync(dart, ["pub", "get"], { stdio: "inherit" });
    const status = result.status ?? 1;
    if (status !== 0) {
      throw new Error(`[solidus] dart pub get failed (exit ${status})`);
    }
  };

  return {
    base,
    server: {
      watch: {
        // `tool/build_docs.dart` writes into `public/assets/docs/**`; we trigger
        // a targeted refresh ourselves to avoid feedback loops.
        ignored: ["**/public/assets/docs/**"],
      },
    },
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
      {
        name: "solidus:ensure-dart-pub-get",
        configResolved() {
          ensureDartPubGet();
        },
      },
      {
        name: "solidus:docs-hmr",
        apply: "serve",
        configureServer(server) {
          const watched = [
            "docs/pages/**/*.md",
            "src/docs/examples/**/*.dart",
            "docs/README.md",
            "tool/build_docs.dart",
            "tool/generate_props.dart",
          ];

          for (const pattern of watched) {
            server.watcher.add(pattern);
          }

          const isWatched = (file) => {
            const p = file.split(path.sep).join("/");
            return (
              p.startsWith("docs/pages/") ||
              p.startsWith("src/docs/examples/") ||
              p === "docs/README.md" ||
              p === "tool/build_docs.dart" ||
              p === "tool/generate_props.dart"
            );
          };

          let timer = null;
          let building = false;
          let queued = false;

          const scheduleBuild = () => {
            if (timer) clearTimeout(timer);
            timer = setTimeout(() => {
              if (building) {
                queued = true;
                return;
              }
              building = true;

              const child = spawn(dart, ["run", "tool/build_docs.dart"], {
                stdio: "inherit",
              });

              child.on("exit", (code) => {
                building = false;
                if (code === 0) {
                  server.ws.send({
                    type: "custom",
                    event: "solidus:docs-built",
                  });
                }
                if (queued) {
                  queued = false;
                  scheduleBuild();
                }
              });
            }, 120);
          };

          const onChange = (file) => {
            if (!isWatched(file)) return;
            scheduleBuild();
          };

          server.watcher.on("change", onChange);
          server.watcher.on("add", onChange);
          server.watcher.on("unlink", onChange);
        },
      },
      Dart({
        dart,
        stdio: true,
        verbosity: "all",
      }),
    ],
  };
});
