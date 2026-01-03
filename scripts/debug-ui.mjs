import net from "node:net";
import process from "node:process";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import { chromium } from "playwright";
import { setTimeout as delay } from "node:timers/promises";

const HOST = "127.0.0.1";

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
  }
  return args;
}

function log(line) {
  process.stdout.write(`${line}\n`);
}

function startProcess(cmd, args, { name, detached = false }) {
  const child = spawn(cmd, args, {
    stdio: ["ignore", "pipe", "pipe"],
    env: process.env,
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
  { timeoutMs, expectSelector, expectH1, interactions, scenario },
) {
  const browser = await launchBrowser();
  const page = await browser.newPage();

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
  page.on("pageerror", (err) => pageErrors.push(String(err)));
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
    if (scenario === "solid-dom") {
      try {
        const inc = page.locator("#solid-inc");
        const count = page.locator("#solid-count");
        if (!(await inc.count()) || !(await count.count())) {
          interactionResults.push({
            name: "solid-dom",
            ok: false,
            details: { reason: "missing #solid-inc or #solid-count" },
          });
        } else {
          const incHandle = await inc.first().elementHandle();
          const readBindings = async () =>
            await page.evaluate(() => {
              const box = document.querySelector("#solid-box");
              const disabled = document.querySelector("#solid-disabled");
              const opacity =
                // @ts-ignore
                box?.style?.getPropertyValue?.("opacity") ?? null;
              const outline =
                // @ts-ignore
                box?.style?.getPropertyValue?.("outline") ?? null;
              return {
                dataCount: box?.getAttribute("data-count") ?? null,
                hasActive: box?.classList?.contains("active") ?? null,
                opacity,
                outline,
                disabled: disabled ? disabled.disabled : null,
              };
            });

          const bindingsBeforeInc = await readBindings();
          const before = (await count.first().textContent())?.trim() ?? "";

          await inc.first().click({ timeout: timeoutMs });

          await page.waitForFunction(
            ({ prev }) => {
              const el = document.querySelector("#solid-count");
              const now = (el?.textContent ?? "").trim();
              return !!now && now !== prev;
            },
            { prev: before },
            { timeout: timeoutMs },
          );

          const after = (await count.first().textContent())?.trim() ?? "";

          const sameNode = incHandle
            ? await incHandle.evaluate(
                (el) => el === document.querySelector("#solid-inc"),
              )
            : false;

          const bindingsAfterInc = await readBindings();

          // Toggle Show and observe cleanup reflected in #solid-status.
          const status = page.locator("#solid-status");
          const toggle = page.locator("#solid-toggle");
          const initialStatus = (await status.first().textContent())?.trim() ?? "";
          const clicks = page.locator("#solid-doc-clicks");
          const clicksBefore = (await clicks.first().textContent())?.trim() ?? "";
          await toggle.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => (document.querySelector("#solid-extra") != null),
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => (document.querySelector("#solid-status")?.textContent ?? "").includes("yes"),
            { timeout: timeoutMs },
          );

          // Document click handler should be active while extra is mounted.
          await page.click("body");
          await page.waitForFunction(
            ({ before }) => {
              const t = document.querySelector("#solid-doc-clicks")?.textContent ?? "";
              return t.trim() !== before;
            },
            { before: clicksBefore },
            { timeout: timeoutMs },
          );
          const clicksDuring = (await clicks.first().textContent())?.trim() ?? "";

          await toggle.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => (document.querySelector("#solid-extra") == null),
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => (document.querySelector("#solid-status")?.textContent ?? "").includes("no"),
            { timeout: timeoutMs },
          );
          const finalStatus = (await status.first().textContent())?.trim() ?? "";

          // After unmount, document click handler should be gone.
          const clicksAfterUnmountBefore = (await clicks.first().textContent())?.trim() ?? "";
          await page.click("body");
          await page.waitForTimeout(250);
          const clicksAfterUnmountAfter = (await clicks.first().textContent())?.trim() ?? "";

          // Keyed For: reverse list should preserve node identity for item 1.
          const item1 = page.locator("#solid-item-1");
          const item1Handle = await item1.first().elementHandle();
          const orderBefore = await page.evaluate(() => {
            const list = document.querySelector("#solid-list");
            const ids = [...(list?.querySelectorAll("[id^=solid-item-]") ?? [])].map(
              (e) => e.id,
            );
            return ids;
          });
          await page.locator("#solid-reorder").click({ timeout: timeoutMs });
          await page.waitForFunction(
            ({ before }) => {
              const list = document.querySelector("#solid-list");
              const ids = [...(list?.querySelectorAll("[id^=solid-item-]") ?? [])].map(
                (e) => e.id,
              );
              return ids.join(",") !== before.join(",");
            },
            { before: orderBefore },
            { timeout: timeoutMs },
          );
          const orderAfter = await page.evaluate(() => {
            const list = document.querySelector("#solid-list");
            const ids = [...(list?.querySelectorAll("[id^=solid-item-]") ?? [])].map(
              (e) => e.id,
            );
            return ids;
          });
          const item1Same = item1Handle
            ? await item1Handle.evaluate(
                (el) => el === document.querySelector("#solid-item-1"),
              )
            : false;

          // Portal: mount to body and clean up.
          await page.locator("#solid-portal-toggle").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#solid-portal") != null,
            { timeout: timeoutMs },
          );
          const portalInfo = await page.evaluate(() => {
            const portal = document.querySelector("#solid-portal");
            const root = document.querySelector("#solid-root");
            return {
              exists: !!portal,
              inRoot: root ? root.contains(portal) : null,
              inBody: document.body ? document.body.contains(portal) : null,
            };
          });
          await page.locator("#solid-portal-toggle").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#solid-portal") == null,
            { timeout: timeoutMs },
          );

          interactionResults.push({
            name: "solid-dom",
            ok:
              sameNode &&
              portalInfo?.exists === true &&
              portalInfo?.inBody === true &&
              portalInfo?.inRoot === false &&
              item1Same === true &&
              clicksAfterUnmountBefore === clicksAfterUnmountAfter &&
              (bindingsBeforeInc.outline ?? "") !== "" &&
              (bindingsAfterInc.outline ?? "") === "",
            details: {
              before,
              after,
              sameNode,
              bindingsBeforeInc,
              bindingsAfterInc,
              initialStatus,
              clicksBefore,
              clicksDuring,
              clicksAfterUnmountBefore,
              clicksAfterUnmountAfter,
              finalStatus,
              orderBefore,
              orderAfter,
              item1Same,
              portalInfo,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-dom",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-for") {
      try {
        const item2 = page.locator("#solid-item-2");
        const disposed = page.locator("#solid-disposed");

        if (!(await item2.count()) || !(await disposed.count())) {
          interactionResults.push({
            name: "solid-for",
            ok: false,
            details: { reason: "missing #solid-item-2 or #solid-disposed" },
          });
        } else {
          const item2Handle = await item2.first().elementHandle();
          const disposedBefore = (await disposed.first().textContent())?.trim() ?? "";

          await page.locator("#solid-remove-2").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#solid-item-2") == null,
            { timeout: timeoutMs },
          );

          await page.waitForFunction(
            ({ before }) => {
              const t = document.querySelector("#solid-disposed")?.textContent ?? "";
              return t.trim() !== before;
            },
            { before: disposedBefore },
            { timeout: timeoutMs },
          );
          const disposedAfterRemove = (await disposed.first().textContent())?.trim() ?? "";

          await page.locator("#solid-add-2").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#solid-item-2") != null,
            { timeout: timeoutMs },
          );
          const item2NewSame = item2Handle
            ? await item2Handle.evaluate(
                (el) => el === document.querySelector("#solid-item-2"),
              )
            : false;

          const item1 = page.locator("#solid-item-1");
          const item1Handle = await item1.first().elementHandle();
          await page.locator("#solid-reorder").click({ timeout: timeoutMs });
          await page.waitForTimeout(250);
          const item1Same = item1Handle
            ? await item1Handle.evaluate(
                (el) => el === document.querySelector("#solid-item-1"),
              )
            : false;

          interactionResults.push({
            name: "solid-for",
            ok: item2NewSame === false && item1Same === true,
            details: {
              disposedBefore,
              disposedAfterRemove,
              item2NewSame,
              item1Same,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-for",
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

  await page.screenshot({ path: ".cache/debug-ui.png", fullPage: true });

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

    log(`\n==> playwright inspect ${url}`);
    const report = await inspectUrl(url, {
      timeoutMs: args.timeoutMs,
      expectSelector: args.expectSelector,
      expectH1: args.expectH1,
      interactions: args.interactions,
      scenario: args.scenario,
    });

    const reportPath = ".cache/debug-ui-report.json";
    await fs.promises.writeFile(reportPath, JSON.stringify(report, null, 2));

    const failures = [];
    if (report.pageErrors.length) failures.push("pageErrors");
    if (report.consoleErrors.length) failures.push("consoleErrors");
    if (report.failedRequests.length) failures.push("failedRequests");
    if (report.badResponses.length) failures.push("badResponses");
    if (!report.appInfo.mountExists) failures.push("#app missing");
    if (report.appInfo.mountChildCount === 0) failures.push("#app empty");
    if (args.interactions) {
      const interactionFailures = report.interactionResults.filter((r) => !r.ok);
      if (interactionFailures.length)
        failures.push(
          `interactions:${interactionFailures.map((r) => r.name).join(",")}`,
        );
    }

    log(`\n==> artifacts`);
    log(`- .cache/debug-ui.png`);
    log(`- ${reportPath}`);

    if (failures.length) {
      log(`\n==> FAIL (${failures.join(", ")})`);
      process.exitCode = 1;
    } else {
      log(`\n==> OK (#app has ${report.appInfo.mountChildCount} child nodes)`);
    }
  } finally {
    await shutdownAsync();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
