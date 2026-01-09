import net from "node:net";
import process from "node:process";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import { chromium } from "playwright";
import { setTimeout as delay } from "node:timers/promises";

import { runSolidWordprocScenario } from "./scenarios/solid-wordproc.mjs";
import { runSolidNestingScenario } from "./scenarios/solid-nesting.mjs";
import { runSolidToastModalScenario } from "./scenarios/solid-toast-modal.mjs";
import { runSolidOptionBuilderScenario } from "./scenarios/solid-optionbuilder.mjs";
import { solidBasicUiScenarios } from "./scenarios/solid-basic-ui.mjs";
import { solidPopperUiScenarios } from "./scenarios/solid-popper-ui.mjs";
import { solidSelectionUiScenarios } from "./scenarios/solid-selection-ui.mjs";
import { solidMenuUiScenarios } from "./scenarios/solid-menu-ui.mjs";
import { solidSwitchUiScenarios } from "./scenarios/solid-switch-ui.mjs";
import { runDocsNavScenario } from "./scenarios/docs-nav.mjs";
import { runDocsListboxScenario } from "./scenarios/docs-listbox.mjs";
import { runDocsCheckboxScenario } from "./scenarios/docs-checkbox.mjs";
import { runDocsRadioGroupScenario } from "./scenarios/docs-radio-group.mjs";
import { runDocsToggleGroupScenario } from "./scenarios/docs-toggle-group.mjs";
import { runDocsBadgeScenario } from "./scenarios/docs-badge.mjs";
import { runDocsSeparatorScenario } from "./scenarios/docs-separator.mjs";
import { runDocsProgressScenario } from "./scenarios/docs-progress.mjs";
import { runDocsSpinnerScenario } from "./scenarios/docs-spinner.mjs";

const solidScenarioRunners = {
  ...solidBasicUiScenarios,
  ...solidPopperUiScenarios,
  ...solidSelectionUiScenarios,
  ...solidMenuUiScenarios,
  ...solidSwitchUiScenarios,
  "solid-wordproc": (page, ctx) => runSolidWordprocScenario(page, ctx),
  "solid-nesting": (page, ctx) => runSolidNestingScenario(page, ctx),
  "solid-toast-modal": (page, ctx) => runSolidToastModalScenario(page, ctx),
  "solid-optionbuilder": (page, ctx) => runSolidOptionBuilderScenario(page, ctx),
  "docs-nav": (page, ctx) => runDocsNavScenario(page, ctx),
  "docs-listbox": (page, ctx) => runDocsListboxScenario(page, ctx),
  "docs-checkbox": (page, ctx) => runDocsCheckboxScenario(page, ctx),
  "docs-radio-group": (page, ctx) => runDocsRadioGroupScenario(page, ctx),
  "docs-toggle-group": (page, ctx) => runDocsToggleGroupScenario(page, ctx),
  "docs-badge": (page, ctx) => runDocsBadgeScenario(page, ctx),
  "docs-separator": (page, ctx) => runDocsSeparatorScenario(page, ctx),
  "docs-progress": (page, ctx) => runDocsProgressScenario(page, ctx),
  "docs-spinner": (page, ctx) => runDocsSpinnerScenario(page, ctx),
};

const HOST = "127.0.0.1";

function makeRng(seed) {
  let s = Number(seed) >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 2 ** 32;
  };
}

function parseArgs(argv) {
  const args = {
    url: null,
    path: "/",
    mode: "dev",
    timeoutMs: 120_000,
    expectH1: "Dart + Vite",
    expectSelector: "#app-root",
    interactions: true,
    scenario: "app",
    repeat: 1,
    jitterMs: 0,
    seed: null,
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--url") args.url = argv[++i] ?? null;
    else if (a === "--path") args.path = argv[++i] ?? args.path;
    else if (a === "--mode") args.mode = argv[++i] ?? "dev";
    else if (a === "--timeout-ms")
      args.timeoutMs = Number(argv[++i] ?? args.timeoutMs);
    else if (a === "--expect-h1") args.expectH1 = argv[++i] ?? args.expectH1;
    else if (a === "--expect-selector")
      args.expectSelector = argv[++i] ?? args.expectSelector;
    else if (a === "--no-interactions") args.interactions = false;
    else if (a === "--scenario") args.scenario = argv[++i] ?? args.scenario;
    else if (a === "--repeat") args.repeat = Number(argv[++i] ?? args.repeat);
    else if (a === "--jitter-ms")
      args.jitterMs = Number(argv[++i] ?? args.jitterMs);
    else if (a === "--seed") args.seed = Number(argv[++i] ?? args.seed);
  }
  return args;
}

function log(line) {
  process.stdout.write(`${line}\n`);
}

function startProcess(cmd, args, { name, detached = false, env = process.env }) {
  const child = spawn(cmd, args, {
    stdio: ["ignore", "pipe", "pipe"],
    env,
    detached,
  });
  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");

  let output = "";
  const onData = (chunk) => {
    output += chunk;
    if (output.length > 400_000) output = output.slice(-400_000);
    process.stdout.write(chunk);
  };
  child.stdout.on("data", onData);
  child.stderr.on("data", onData);

  const waitFor = (predicate, timeoutMs) =>
    new Promise((resolve, reject) => {
      const start = Date.now();
      const tick = () => {
        if (predicate(output)) return resolve();
        if (child.exitCode != null)
          return reject(
            new Error(`${name} exited early with code ${child.exitCode}`),
          );
        if (Date.now() - start > timeoutMs)
          return reject(
            new Error(
              `Timed out waiting for ${name}. Last output:\n\n${output}`,
            ),
          );
        setTimeout(tick, 200);
      };
      tick();
    });

  return { child, waitFor, getOutput: () => output };
}

async function findFreePort() {
  return await new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.on("error", reject);
    server.listen(0, HOST, () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
  });
}

async function launchBrowser() {
  try {
    return await chromium.launch({ channel: "chrome", headless: true });
  } catch {
    return await chromium.launch({ headless: true });
  }
}

function isIgnorable404(url) {
  try {
    const u = new URL(url);
    return u.pathname === "/favicon.ico";
  } catch {
    return false;
  }
}

function isIgnorableConsoleError(text) {
  return (
    /Failed to load resource/i.test(text) && /favicon\.ico/i.test(text)
  );
}

async function inspectUrl(
  url,
  {
    timeoutMs,
    expectSelector,
    expectH1,
    interactions,
    scenario,
    jitterMs = 0,
    seed = null,
    runIndex = 1,
    screenshotPath = ".cache/debug-ui.png",
  },
) {
  const browser = await launchBrowser();
  const page = await browser.newPage();

  const baseSeed = seed == null ? (jitterMs > 0 ? 1 : 0) : Number(seed) >>> 0;
  const rng = makeRng((baseSeed + (runIndex - 1)) >>> 0);
  const jitter = async () => {
    if (!jitterMs || jitterMs <= 0) return;
    const ms = Math.floor(rng() * jitterMs);
    if (ms > 0) await page.waitForTimeout(ms);
  };

  const consoleLines = [];
  const consoleErrors = [];
  const failedRequests = [];
  const badResponses = [];
  const pageErrors = [];

  page.on("console", (msg) => {
    const line = `[console.${msg.type()}] ${msg.text()}`;
    consoleLines.push(line);
    if (msg.type() === "error" && !isIgnorableConsoleError(msg.text()))
      consoleErrors.push(line);
  });
  page.on("pageerror", (err) =>
    pageErrors.push(err?.stack ? String(err.stack) : String(err)),
  );
  page.on("requestfailed", (req) => {
    const record = {
      url: req.url(),
      method: req.method(),
      failure: req.failure()?.errorText,
    };
    if (!isIgnorable404(record.url)) failedRequests.push(record);
  });
  page.on("response", (resp) => {
    const status = resp.status();
    if (status < 400) return;
    const req = resp.request();
    const resourceType = req.resourceType();
    const responseUrl = resp.url();
    if (isIgnorable404(responseUrl)) return;
    try {
      const originA = new URL(url).origin;
      const originB = new URL(responseUrl).origin;
      if (originA !== originB) return;
    } catch {
      return;
    }
    if (!["document", "script", "stylesheet"].includes(resourceType)) return;
    badResponses.push({ url: responseUrl, status, resourceType });
  });

  const response = await page.goto(url, {
    waitUntil: "load",
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    ({ sel, h1Text }) => {
      const mount = document.querySelector("#app");
      if (!mount || mount.childNodes.length === 0) return false;
      const expected = document.querySelector(sel);
      if (!expected) return false;
      const h1 = document.querySelector("h1");
      if (!h1) return false;
      return (h1.textContent ?? "").includes(h1Text);
    },
    { sel: expectSelector, h1Text: expectH1 },
    { timeout: timeoutMs },
  );
  await page.waitForTimeout(250);

  const interactionResults = [];
  if (interactions) {
    const runner = solidScenarioRunners[scenario];
    if (runner) {
      try {
        const result = await runner(page, { timeoutMs, jitter });
        if (result) interactionResults.push(result);
      } catch (e) {
        interactionResults.push({
          name: scenario,
          ok: false,
          details: { error: String(e) },
        });
      }
    } else {
      // Default scenario: existing app.
      try {
        const inc = page.locator('[data-action="counter-inc"]');
        if (await inc.count()) {
          const before = await page.evaluate(() => {
            const counterRoot = document.querySelector("#counter-root");
            const big = counterRoot?.querySelector(".big");
            return (big?.textContent ?? "").trim();
          });
          await inc.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            (prev) => {
              const counterRoot = document.querySelector("#counter-root");
              const big = counterRoot?.querySelector(".big");
              const now = (big?.textContent ?? "").trim();
              return !!now && now !== prev;
            },
            before,
            { timeout: timeoutMs },
          );
          const after = await page.evaluate(() => {
            const counterRoot = document.querySelector("#counter-root");
            const big = counterRoot?.querySelector(".big");
            return (big?.textContent ?? "").trim();
          });
          interactionResults.push({
            name: "counter-inc",
            ok: true,
            details: { before, after },
          });
        } else {
          interactionResults.push({
            name: "counter-inc",
            ok: false,
            details: { reason: "missing [data-action=counter-inc]" },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "counter-inc",
          ok: false,
          details: { error: String(e) },
        });
      }
    }
  }

  const appInfo = await page.evaluate(() => {
    const mount = document.querySelector("#app");
    const h1 = document.querySelector("h1");
    return {
      location: location.href,
      readyState: document.readyState,
      mountExists: !!mount,
      mountChildCount: mount?.childNodes?.length ?? 0,
      mountInnerTextPreview: (mount?.innerText ?? "").slice(0, 500),
      h1Text: h1?.textContent ?? null,
    };
  });

  await page.screenshot({ path: screenshotPath, fullPage: true });

  await browser.close();

  return {
    url,
    status: response?.status() ?? null,
    expectations: { expectSelector, expectH1 },
    scenario,
    appInfo,
    pageErrors,
    failedRequests,
    badResponses,
    consoleLines,
    consoleErrors,
    interactionResults,
  };
}

async function main() {
  const args = parseArgs(process.argv);
  const started = [];
  const root = process.cwd();
  const viteBin = path.join(root, "node_modules", ".bin", "vite");
  await fs.promises.mkdir(path.join(root, ".cache"), { recursive: true });

  // GitHub Actions sets a non-root base for Pages builds (e.g. "/repo/"). When
  // running smoke tests against `vite preview`, serve from "/" so assets resolve
  // correctly on the local preview server.
  const viteChildEnv =
    args.mode === "preview" && !args.url
      ? { ...process.env, BASE: "/", VITE_BASE: "/" }
      : process.env;

  const terminateChild = async (child) => {
    if (child.exitCode != null) return;
    const pid = child.pid;
    try {
      if (pid) process.kill(-pid, "SIGTERM");
      else child.kill("SIGTERM");
    } catch {
      try {
        child.kill("SIGTERM");
      } catch {
        // ignore
      }
    }
    for (let i = 0; i < 50; i++) {
      if (child.exitCode != null) return;
      await delay(100);
    }
    try {
      if (pid) process.kill(-pid, "SIGKILL");
      else child.kill("SIGKILL");
    } catch {
      try {
        child.kill("SIGKILL");
      } catch {
        // ignore
      }
    }
  };

  const shutdownAsync = async () => {
    await Promise.all(started.map((child) => terminateChild(child)));
  };

  process.on("SIGINT", () => void shutdownAsync());
  process.on("SIGTERM", () => void shutdownAsync());
  process.on("exit", () => {
    for (const child of started) {
      if (child.exitCode == null) child.kill("SIGTERM");
    }
  });

  try {
    let url = args.url;
    let port = null;

    if (!url) {
      port = await findFreePort();
      const pathPart = args.path?.startsWith("/") || args.path?.startsWith("?")
        ? args.path
        : `/${args.path}`;
      url = `http://${HOST}:${port}${pathPart ?? "/"}`;

      if (args.mode === "preview") {
        log(`\n==> build`);
        const build = startProcess(viteBin, ["build"], {
          name: "build",
          detached: true,
          env: viteChildEnv,
        });
        started.push(build.child);
        await new Promise((resolve, reject) =>
          build.child.on("exit", (code) =>
            code === 0 ? resolve() : reject(new Error(`build failed: ${code}`)),
          ),
        );
      }

      if (args.mode === "dev") {
        const packageConfig = path.join(root, ".dart_tool", "package_config.json");
        if (!fs.existsSync(packageConfig)) {
          log(`\n==> dart pub get (missing .dart_tool/package_config.json)`);
          const pubGet = startProcess("node", ["scripts/dart-pub-get.mjs"], {
            name: "dart pub get",
            detached: true,
          });
          started.push(pubGet.child);
          await new Promise((resolve, reject) =>
            pubGet.child.on("exit", (code) =>
              code === 0 ? resolve() : reject(new Error(`pub get failed: ${code}`)),
            ),
          );
        }
      }

      log(`\n==> start ${args.mode} server on ${url}`);
      const serverArgs =
        args.mode === "preview"
          ? [
              "preview",
              "--host",
              HOST,
              "--port",
              String(port),
              "--strictPort",
            ]
          : [
              "--host",
              HOST,
              "--port",
              String(port),
              "--strictPort",
            ];
      const server = startProcess(viteBin, serverArgs, {
        name: args.mode,
        detached: true,
        env: viteChildEnv,
      });
      started.push(server.child);

      await server.waitFor(
        (out) =>
          out.includes(url) ||
          out.includes(`http://${HOST}:${port}`) ||
          out.includes("Local:"),
        args.timeoutMs,
      );
    }

    const repeat = Number(args.repeat ?? 1);
    const reports = [];
    const failures = [];

    log(`\n==> playwright inspect ${url}`);
    if (args.jitterMs > 0) {
      const seedShown = args.seed == null ? 1 : args.seed;
      log(`\n==> jitter enabled (max ${args.jitterMs}ms, seed ${seedShown})`);
    }

    for (let i = 0; i < repeat; i++) {
      if (repeat > 1) {
        log(`\n==> run ${i + 1}/${repeat}`);
      }
      const screenshotPath =
        repeat > 1 ? `.cache/debug-ui-run-${i + 1}.png` : ".cache/debug-ui.png";
      const report = await inspectUrl(url, {
        timeoutMs: args.timeoutMs,
        expectSelector: args.expectSelector,
        expectH1: args.expectH1,
        interactions: args.interactions,
        scenario: args.scenario,
        jitterMs: args.jitterMs,
        seed: args.seed,
        runIndex: i + 1,
        screenshotPath,
      });
      reports.push(report);

      const runFailures = [];
      if (report.pageErrors.length) runFailures.push("pageErrors");
      if (report.consoleErrors.length) runFailures.push("consoleErrors");
      if (report.failedRequests.length) runFailures.push("failedRequests");
      if (report.badResponses.length) runFailures.push("badResponses");
      if (!report.appInfo.mountExists) runFailures.push("#app missing");
      if (report.appInfo.mountChildCount === 0) runFailures.push("#app empty");
      if (args.interactions) {
        const interactionFailures = report.interactionResults.filter((r) => !r.ok);
        if (interactionFailures.length)
          runFailures.push(
            `interactions:${interactionFailures.map((r) => r.name).join(",")}`,
          );
      }
      if (runFailures.length) failures.push({ run: i + 1, failures: runFailures });
    }

    const reportPath = ".cache/debug-ui-report.json";
    const combinedReport =
      repeat <= 1
        ? reports[0]
        : {
            repeat,
            jitterMs: args.jitterMs,
            seed: args.seed == null ? (args.jitterMs > 0 ? 1 : null) : args.seed,
            runs: reports,
          };
    await fs.promises.writeFile(reportPath, JSON.stringify(combinedReport, null, 2));

    log(`\n==> artifacts`);
    if (repeat > 1) {
      log(`- .cache/debug-ui-run-*.png`);
    } else {
      log(`- .cache/debug-ui.png`);
    }
    log(`- ${reportPath}`);

    if (failures.length) {
      const formatted = failures
        .map((f) => `run ${f.run}: ${f.failures.join(", ")}`)
        .join(" | ");
      log(`\n==> FAIL (${formatted})`);
      process.exitCode = 1;
    } else {
      log(`\n==> OK (${repeat} run${repeat === 1 ? "" : "s"})`);
    }
  } finally {
    await shutdownAsync();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
