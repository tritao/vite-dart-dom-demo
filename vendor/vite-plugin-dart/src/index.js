import { spawnSync } from "child_process";
import { readFileSync, mkdtempSync, rmSync } from "fs";
import { tmpdir } from "os";
import { join, parse } from "path";

const fileRegex = /\.(dart)$/;

/**
 * @typedef {Object} Config
 * @property {Number} [O] - Only numbers between <0,1,2,3,4> allowed.
 * @property {Boolean} [csp]
 * @property {String} [dart=dart] - Dart binary path.
 * @property {String[]} [define] - Array items in the "<name>=<value>" fromat each.
 * @property {Boolean} [enable-asserts]
 * @property {Boolean} [enable-diagnostic-colors]
 * @property {Boolean} [fatal-warnings]
 * @property {Boolean} [lax-runtime-type-to-string]
 * @property {Boolean} [minify]
 * @property {Boolean} [no-source-maps]
 * @property {Boolean} [omit-implicit-checks]
 * @property {Boolean} [omit-late-names]
 * @property {String} [packages]
 * @property {Boolean} [show-package-warnings]
 * @property {Boolean} [suppress-hints]
 * @property {Boolean} [suppress-warnings]
 * @property {Boolean} [terse]
 * @property {Boolean} [trust-primitives]
 * @property {Boolean} [verbose]
 * @property {String} [verbosity=warning] - Available: all, error, info, warning.
 * @property {Boolean} [stdio=true] - Whether or not to pass the dart stdio to parent.
 */
const defaultConfig = {
  dart: "dart",
  minify: false,
  "enable-asserts": false,
  verbose: false,
  define: [],
  packages: "",
  "suppress-warnings": false,
  "fatal-warnings": false,
  "suppress-hints": false,
  "enable-diagnostic-colors": false,
  terse: false,
  "show-package-warnings": false,
  csp: false,
  "no-source-maps": false,
  "omit-late-names": false,
  O: 1,
  "omit-implicit-checks": false,
  "trust-primitives": false,
  "lax-runtime-type-to-string": false,
  verbosity: "warning",
  stdio: true,
};

const nonFlagBool = ["stdio"];

function tailLines(text, maxLines = 200) {
  if (!text) return "";
  const lines = String(text).split(/\r?\n/);
  if (lines.length <= maxLines) return lines.join("\n");
  return lines.slice(lines.length - maxLines).join("\n");
}

/**
 * @param {Config} options
 */
export default function dartPlugin(options = defaultConfig) {
  options = {...defaultConfig, ...options}
  // Create the dart args
  const execArgs = [];

  if (options.dart.length === 0) options.dart = "dart";
  if (options.packages.length > 0)
    execArgs.push(`--packages=${options.packages}`);
  if (options.O >= 0 && options.O <= 4 && options.O % 1 === 0)
    execArgs.push(`-O${options.O}`);

  execArgs.push(
    `--verbosity=${
      ["info", "error", "warning", "all"].includes(
        options.verbosity.toLowerCase()
      )
        ? options.verbosity.toLowerCase()
        : "warning"
    }`
  );

  execArgs.push(
    ...Object.keys(options)
      .filter((x) => options[x] === true && !nonFlagBool.includes(x))
      .map((x) => `--${x}`)
  );

  if (options.define.length > 0)
    execArgs.push(
      ...options.define
        .filter((x) => x.includes("="))
        .map((x) => `--define=${x}`)
    );

  return {
    name: "vite-plugin-dart",

    /**
     * Dart compilation produces a single JS module that inlines imports, so Vite
     * doesn't naturally know which Dart files are dependencies of the entry.
     *
     * In dev, treat any Dart change as requiring a full page reload.
     */
    handleHotUpdate(ctx) {
      const file = ctx?.file ?? "";
      if (!fileRegex.test(file) && !file.endsWith("pubspec.yaml")) return;

      // Ensure the next request recompiles the entry.
      ctx.server.moduleGraph.invalidateAll?.();
      ctx.server.ws.send({ type: "full-reload" });
      try {
        // eslint-disable-next-line no-console
        console.log(`[vite-plugin-dart] full reload: ${file}`);
      } catch (_) {}

      return [];
    },

    transform(_, path) {
      if (!fileRegex.test(path)) return;
      // Create a tmp folder to hold the dart compile
      // output
      const tmpFolder = mkdtempSync(join(tmpdir(), "vite-plugin-dart-"));
      const parsedPath = parse(path);
      const compiledDartFilename = parsedPath.name + ".js";
      const compiledDartOutput = join(tmpFolder, compiledDartFilename);

      const dartArgs = [
        "compile",
        "js",
        ...execArgs,
        "-o",
        compiledDartOutput,
        path,
      ];

      const prettyCommand = `"${options.dart}" ${dartArgs
        .map((x) => (x.includes(" ") ? JSON.stringify(x) : x))
        .join(" ")}`;

      let compiledDart;
      let compiledDartMap = null;
      try {
        const result = spawnSync(options.dart, dartArgs, {
          encoding: "utf8",
          stdio: ["ignore", "pipe", "pipe"],
        });

        if (options.stdio === true) {
          if (result.stdout) process.stdout.write(result.stdout);
          if (result.stderr) process.stderr.write(result.stderr);
        }

        if (result.error) {
          const out = tailLines(result.stdout);
          const err = tailLines(result.stderr);
          const msg =
            `[vite-plugin-dart] Failed to run Dart compiler.\n` +
            `Command: ${prettyCommand}\n` +
            (result.error?.message ? `Error: ${result.error.message}\n` : "") +
            (out ? `\nstdout (tail):\n${out}\n` : "") +
            (err ? `\nstderr (tail):\n${err}\n` : "");
          this.error(new Error(msg));
        }

        if (result.status !== 0) {
          const out = tailLines(result.stdout);
          const err = tailLines(result.stderr);
          const msg =
            `[vite-plugin-dart] Dart compilation failed (exit code ${result.status}).\n` +
            `Entry: ${path}\n` +
            `Command: ${prettyCommand}\n` +
            (out ? `\nstdout (tail):\n${out}\n` : "") +
            (err ? `\nstderr (tail):\n${err}\n` : "");
          this.error(new Error(msg));
        }
        compiledDart = readFileSync(compiledDartOutput, "utf8");

        if (options["no-source-maps"] === false) {
          // Remove the included sourcemap (Vite handles it)
          compiledDart = compiledDart.replace(
            `//# sourceMappingURL=${encodeURIComponent(
              compiledDartFilename
            )}.map`,
            ""
          );
          // Patch the sourcemap so it points to the correct files
          compiledDartMap = JSON.parse(
            readFileSync(compiledDartOutput + ".map", "utf8")
          );
          compiledDartMap.sources = compiledDartMap.sources.map((x) => {
            if (!x.startsWith(".")) return x;
            x = x.replace(/^(?:\.\.(\/|\\))+/, "");
            x = "file://" + x;
            return x;
          });
          compiledDartMap = JSON.stringify(compiledDartMap);
        }
      } finally {
        // Delete the tmp folder even on failure.
        rmSync(tmpFolder, { recursive: true, force: true });
      }

      return {
        code: compiledDart,
        map: compiledDartMap,
      };
    },
  };
}
