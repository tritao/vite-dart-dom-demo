import { spawn, spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
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

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith("--")) {
      out[key] = next;
      i++;
    } else {
      out[key] = "1";
    }
  }
  return out;
}

function pickFreePort(preferred = 8080) {
  return new Promise((resolve) => {
    const s = net.createServer();
    s.once("error", () => {
      s.listen(0, "127.0.0.1");
    });
    s.listen(preferred, "127.0.0.1", () => {
      const { port } = s.address();
      s.close(() => resolve(port));
    });
  });
}

async function waitForHealthz(url, timeoutMs = 30_000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url, { method: "GET" });
      if (res.ok) return true;
    } catch {}
    await new Promise((r) => setTimeout(r, 200));
  }
  return false;
}

function resolveDart(root, env) {
  const provisioned = path.join(root, ".dart-sdk", "dart-sdk", "bin", "dart");
  if (env.DART) return env.DART;
  if (fs.existsSync(provisioned)) return provisioned;
  return "dart";
}

function ensureBackendPubGet({ dart, backendDir }) {
  const pkgCfg = path.join(backendDir, ".dart_tool", "package_config.json");
  if (fs.existsSync(pkgCfg)) return;
  console.log(`[dev:full] Missing ${pkgCfg}; running dart pub get (backend)`);
  const res = spawnSync(dart, ["pub", "get"], { cwd: backendDir, stdio: "inherit" });
  if ((res.status ?? 1) !== 0) process.exit(res.status ?? 1);
}

function ensureRootPubGet({ dart, root }) {
  const pkgCfg = path.join(root, ".dart_tool", "package_config.json");
  if (fs.existsSync(pkgCfg)) return;
  console.log(`[dev:full] Missing ${pkgCfg}; running dart pub get (root)`);
  const res = spawnSync(dart, ["pub", "get"], { cwd: root, stdio: "inherit" });
  if ((res.status ?? 1) !== 0) process.exit(res.status ?? 1);
}

function randomBase64Key32() {
  return crypto.randomBytes(32).toString("base64");
}

function isTruthyFlag(value) {
  if (value == null) return false;
  const v = String(value).trim().toLowerCase();
  return v === "1" || v === "true" || v === "yes" || v === "on";
}

function isFalsyFlag(value) {
  if (value == null) return false;
  const v = String(value).trim().toLowerCase();
  return v === "0" || v === "false" || v === "no" || v === "off";
}

function shouldIgnoreBackendWatchPath(p) {
  const s = p.split(path.sep).join("/");
  return (
    s.includes("/.dart_tool/") ||
    s.includes("/.cache/") ||
    s.includes("/build/") ||
    s.endsWith(".sqlite") ||
    s.endsWith(".sqlite-wal") ||
    s.endsWith(".sqlite-shm") ||
    s.endsWith(".sqlite-journal") ||
    s.endsWith(".db") ||
    s.endsWith(".db-wal") ||
    s.endsWith(".db-shm") ||
    s.endsWith(".db-journal")
  );
}

function watchBackendTree(backendDir, onChange) {
  // Minimal recursive watcher without extra deps.
  // We watch all subdirectories under the backend package, and debounce restarts.
  const watchedDirs = new Set();
  const watchers = [];

  const addDir = (dir) => {
    const resolved = path.resolve(dir);
    if (watchedDirs.has(resolved)) return;
    watchedDirs.add(resolved);
    try {
      const w = fs.watch(resolved, { persistent: true }, (eventType, filename) => {
        const name = filename ? filename.toString() : "";
        const fullPath = name ? path.join(resolved, name) : resolved;
        if (shouldIgnoreBackendWatchPath(fullPath)) return;
        onChange({ eventType, path: fullPath });
      });
      watchers.push(w);
    } catch {
      // ignore
    }
  };

  const walk = (dir) => {
    addDir(dir);
    let entries = [];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      if (entry.name.startsWith(".")) continue;
      const next = path.join(dir, entry.name);
      if (shouldIgnoreBackendWatchPath(next)) continue;
      walk(next);
    }
  };

  walk(backendDir);

  return () => {
    for (const w of watchers) {
      try {
        w.close();
      } catch {}
    }
  };
}

const root = process.cwd();
const envLocal = parseEnvFile(path.join(root, ".env.local"));
const env = { ...envLocal, ...process.env };
const args = parseArgs(process.argv.slice(2));

if (args.help || args.h) {
  console.log(`
Usage: npm run dev:full [--backend-port 8080] [--proxy http://127.0.0.1:8080] [--backend-watch 1]

Starts:
  - solidus_backend (packages/solidus_backend)
  - Vite dev server (with /api proxy to backend)

Options:
  --backend-watch 1|0     Restart backend on file changes (default: 1)

Env overrides:
  - SOLIDUS_BACKEND_PROXY (overrides the Vite proxy target)
  - SOLIDUS_AUTH_MASTER_KEY (backend crypto key; auto-generated if missing)
  - SOLIDUS_EMAIL_FROM / SOLIDUS_EMAIL_TRANSPORT
`);
  process.exit(0);
}

const dart = resolveDart(root, env);
const backendDir = path.join(root, "packages", "solidus_backend");

if (!fs.existsSync(backendDir)) {
  console.error(`[dev:full] Missing backend dir: ${backendDir}`);
  process.exit(2);
}

ensureRootPubGet({ dart, root });
ensureBackendPubGet({ dart, backendDir });

const backendPort =
  args["backend-port"] ? Number(args["backend-port"]) : await pickFreePort(8080);
if (!Number.isFinite(backendPort) || backendPort <= 0) {
  console.error(`[dev:full] Invalid backend port: ${args["backend-port"]}`);
  process.exit(2);
}

const backendUrl = `http://127.0.0.1:${backendPort}`;
const proxyTarget = env.SOLIDUS_BACKEND_PROXY || args.proxy?.trim() || backendUrl;

const backendEnv = {
  ...env,
  SOLIDUS_AUTH_MASTER_KEY: env.SOLIDUS_AUTH_MASTER_KEY || randomBase64Key32(),
  SOLIDUS_BACKEND_HOST: "127.0.0.1",
  SOLIDUS_BACKEND_PORT: String(backendPort),
  SOLIDUS_BACKEND_COOKIE_SECURE: env.SOLIDUS_BACKEND_COOKIE_SECURE ?? "0",
  SOLIDUS_EXPOSE_DEV_TOKENS: env.SOLIDUS_EXPOSE_DEV_TOKENS ?? "1",
  SOLIDUS_EXPOSE_INVITE_TOKENS: env.SOLIDUS_EXPOSE_INVITE_TOKENS ?? "1",
  SOLIDUS_EMAIL_TRANSPORT: env.SOLIDUS_EMAIL_TRANSPORT ?? "log",
  SOLIDUS_EMAIL_FROM: env.SOLIDUS_EMAIL_FROM ?? "Solidus <no-reply@localhost>",
  SOLIDUS_PUBLIC_BASE_URL: env.SOLIDUS_PUBLIC_BASE_URL ?? "http://localhost:5173",
  SOLIDUS_BACKEND_DB: env.SOLIDUS_BACKEND_DB || (() => {
    // Put the sqlite DB in the OS temp dir by default so Vite's file watcher
    // doesn't trigger full-reloads on each request.
    const dbPath = path.join(os.tmpdir(), "solidus_backend", "dev_full", "solidus.sqlite");
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
    return dbPath;
  })(),
};

console.log(`[dev:full] backend: ${backendUrl}`);
console.log(`[dev:full] vite /api proxy -> ${proxyTarget}`);
console.log(`[dev:full] open: http://localhost:5173/?backend=1`);

const backendWatch =
  isTruthyFlag(args["backend-watch"]) ||
  (!isFalsyFlag(args["backend-watch"]) && !isTruthyFlag(args["no-backend-watch"]));

let shuttingDown = false;
let backend = null;
let backendStop = null;

function spawnBackend() {
  return spawn(dart, ["run", "bin/server.dart"], {
    cwd: backendDir,
    stdio: "inherit",
    env: backendEnv,
  });
}

async function stopBackend(timeoutMs = 2500) {
  const child = backend;
  if (!child) return;
  if (child.exitCode != null) return;

  await new Promise((resolve) => {
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      resolve();
    };

    const timer = setTimeout(() => {
      try {
        child.kill("SIGKILL");
      } catch {}
      finish();
    }, timeoutMs);

    child.once("exit", () => {
      clearTimeout(timer);
      finish();
    });

    try {
      child.kill("SIGTERM");
    } catch {
      clearTimeout(timer);
      finish();
    }
  });
}

async function restartBackend(reason) {
  if (shuttingDown) return;
  console.log(`[dev:full] backend restart: ${reason}`);
  await stopBackend();
  backend = spawnBackend();
  const ok = await waitForHealthz(`${backendUrl}/healthz`, 15_000);
  if (!ok) {
    console.error("[dev:full] backend did not become healthy after restart");
  }
}

backend = spawnBackend();
backend.on("exit", (code) => {
  if (shuttingDown) return;
  if (code && code !== 0) {
    console.error(`[dev:full] backend exited with code ${code}`);
    process.exit(code ?? 0);
  }
  // If it exits cleanly while we're in dev:full, bring it back.
  restartBackend("backend exited");
});

const healthy = await waitForHealthz(`${backendUrl}/healthz`, 30_000);
if (!healthy) {
  console.error("[dev:full] backend did not become healthy; continuing anyway");
}

if (backendWatch) {
  console.log("[dev:full] backend watch: enabled");
  let timer = null;
  let lastChanged = null;
  backendStop = watchBackendTree(backendDir, ({ path: changedPath }) => {
    lastChanged = changedPath;
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      timer = null;
      const pretty = lastChanged
        ? path.relative(root, lastChanged).split(path.sep).join("/")
        : "(unknown)";
      restartBackend(`file changed: ${pretty}`);
    }, 200);
  });
} else {
  console.log("[dev:full] backend watch: disabled");
}

const viteEnv = {
  ...env,
  SOLIDUS_BACKEND_PROXY: proxyTarget,
};

const vite = spawn(
  process.platform === "win32" ? "npm.cmd" : "npm",
  ["run", "dev"],
  {
    cwd: root,
    stdio: "inherit",
    env: viteEnv,
  },
);

const killAll = () => {
  shuttingDown = true;
  try {
    vite.kill("SIGTERM");
  } catch {}
  try {
    backend.kill("SIGTERM");
  } catch {}
  try {
    backendStop?.();
  } catch {}
};

process.on("SIGINT", () => {
  killAll();
  process.exit(130);
});
process.on("SIGTERM", () => {
  killAll();
  process.exit(143);
});

vite.on("exit", (code) => {
  if (code && code !== 0) {
    console.error(`[dev:full] vite exited with code ${code}`);
  } else {
    console.log("[dev:full] vite exited");
  }
  try {
    backend.kill("SIGTERM");
  } catch {}
  process.exit(code ?? 0);
});
