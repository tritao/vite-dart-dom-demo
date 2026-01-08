import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

function parseEnvFile(filePath) {
  try {
    const contents = fs.readFileSync(filePath, "utf8");
    const env = {};
    for (const rawLine of contents.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) continue;
      const eq = line.indexOf("=");
      if (eq === -1) continue;
      const key = line.slice(0, eq).trim();
      let value = line.slice(eq + 1).trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      env[key] = value;
    }
    return env;
  } catch {
    return {};
  }
}

const root = process.cwd();
const envLocal = parseEnvFile(path.join(root, ".env.local"));
const env = { ...envLocal, ...process.env };

const provisionedDart = path.join(root, ".dart-sdk", "dart-sdk", "bin", "dart");
const dart =
  env.DART || (fs.existsSync(provisionedDart) ? provisionedDart : "dart");

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("Usage: node scripts/dart-run.mjs <dart args...>");
  process.exit(2);
}

const result = spawnSync(dart, args, { stdio: "inherit" });
process.exit(result.status ?? 1);

