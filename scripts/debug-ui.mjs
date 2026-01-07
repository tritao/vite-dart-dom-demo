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
    } else if (scenario === "solid-overlay") {
      let step = "init";
      let hitBeforeOutside = null;
      try {
        const trigger = page.locator("#overlay-trigger");
        const under = page.locator("#overlay-under-button");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-overlay",
            ok: false,
            details: { reason: "missing #overlay-trigger" },
          });
        } else {
          const triggerHandle = await trigger.first().elementHandle();
          const underBox = (await under.count())
            ? await under.first().boundingBox()
            : null;

          const bodyOverflowBefore = await page.evaluate(
            () => document.body?.style?.overflow ?? null,
          );

          step = "open (escape path)";
          await trigger.first().click({ timeout: timeoutMs });

          step = "wait dialog open";
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") != null,
            { timeout: timeoutMs },
          );
          step = "wait portal root";
          await page.waitForFunction(
            () => document.querySelector("#solid-portal-root") != null,
            { timeout: timeoutMs },
          );
          step = "wait focus close";
          await page.waitForFunction(
            () => document.activeElement?.id === "overlay-close",
            { timeout: timeoutMs },
          );

          const afterOpen = await page.evaluate(() => {
            const dialog = document.querySelector("#overlay-dialog");
            const app = document.querySelector("#app");
            return {
              dialogExists: !!dialog,
              dialogInBody: document.body?.contains(dialog) ?? null,
              appAriaHidden: app?.getAttribute("aria-hidden") ?? null,
              bodyOverflow: document.body?.style?.overflow ?? null,
              activeId: document.activeElement?.id ?? null,
            };
          });

          // Tab should stay inside the dialog (focus trap).
          step = "tab stays within";
          await page.keyboard.press("Tab");
          await page.waitForTimeout(100);
          const activeAfterTab = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          // Escape should dismiss.
          step = "escape dismiss";
          await page.keyboard.press("Escape");
          step = "wait closed after escape";
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") == null,
            { timeout: timeoutMs },
          );
          // Presence exit delay: portal should still exist briefly, then go away.
          await page.waitForTimeout(80);

          const afterClose = await page.evaluate(() => {
            const dialog = document.querySelector("#overlay-dialog");
            const app = document.querySelector("#app");
            return {
              dialogExists: !!dialog,
              portalRootExists: document.querySelector("#solid-portal-root") != null,
              appAriaHidden: app?.getAttribute("aria-hidden") ?? null,
              bodyOverflow: document.body?.style?.overflow ?? null,
              activeId: document.activeElement?.id ?? null,
            };
          });

          const focusRestored = triggerHandle
            ? await triggerHandle.evaluate(
                (el) => el === document.activeElement,
              )
            : false;

          // Outside click dismissal path.
          step = "open (outside path)";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait open (outside path)";
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") != null,
            { timeout: timeoutMs },
          );
          // Click where the underlying button is. With pointer blocking, this
          // should dismiss the overlay without incrementing the underlying counter.
          step = "outside click over underlying button";
          hitBeforeOutside = underBox
            ? await page.evaluate(({ x, y }) => {
                const el = document.elementFromPoint(x, y);
                return {
                  id: el?.id ?? null,
                  tag: el?.tagName ?? null,
                  dataBackdrop:
                    el?.closest?.("#overlay-backdrop") != null ? true : false,
                  dataDialog: el?.closest?.("#overlay-dialog") != null ? true : false,
                  pointerEvents: el ? getComputedStyle(el).pointerEvents : null,
                };
              }, { x: underBox.x + underBox.width / 2, y: underBox.y + underBox.height / 2 })
            : null;
          if (underBox) {
            const backdrop = page.locator("#overlay-backdrop");
            const bb = await backdrop.first().boundingBox();
            if (!bb) throw new Error("missing #overlay-backdrop bounding box");
            const cx = underBox.x + underBox.width / 2;
            const cy = underBox.y + underBox.height / 2;
            await page.click("#overlay-backdrop", {
              timeout: timeoutMs,
              position: { x: cx - bb.x, y: cy - bb.y },
            });
          } else {
            await page.click("#overlay-backdrop", { timeout: timeoutMs });
          }
          step = "wait closed after outside click";
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          step = "read status";
          const statusText = (await page.locator("#overlay-status").textContent())?.trim() ?? "";
          const afterOutsideCount = await page.evaluate(() => {
            const text = document.querySelector("#overlay-status")?.textContent ?? "";
            const m = text.match(/Outside clicks:\s*(\d+)/);
            return m ? Number(m[1]) : null;
          });

          // Now the underlying button should be clickable.
          if (await under.count()) {
            step = "second click increments";
            await under.first().click({ timeout: timeoutMs });
          }
          await page.waitForTimeout(50);
          const afterSecondCount = await page.evaluate(() => {
            const text = document.querySelector("#overlay-status")?.textContent ?? "";
            const m = text.match(/Outside clicks:\s*(\d+)/);
            return m ? Number(m[1]) : null;
          });

          const ok =
            afterOpen.dialogExists === true &&
            afterOpen.dialogInBody === true &&
            afterOpen.bodyOverflow === "hidden" &&
            afterOpen.appAriaHidden === "true" &&
            afterOpen.activeId === "overlay-close" &&
            activeAfterTab != null &&
            activeAfterTab.startsWith("overlay-") &&
            afterClose.dialogExists === false &&
            afterClose.bodyOverflow === bodyOverflowBefore &&
            afterClose.appAriaHidden == null &&
            focusRestored === true &&
            statusText.includes("outside") &&
            (afterOutsideCount ?? 0) === 0 &&
            (afterSecondCount ?? 0) === 1;

          interactionResults.push({
            name: "solid-overlay",
            ok,
            details: {
              bodyOverflowBefore,
              afterOpen,
              activeAfterTab,
              afterClose,
              focusRestored,
              statusText,
              afterOutsideCount,
              afterSecondCount,
              hitBeforeOutside,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-overlay",
          ok: false,
          details: { error: String(e), step, hitBeforeOutside },
        });
      }
    } else if (scenario === "solid-dialog") {
      let step = "init";
      try {
        const trigger = page.locator("#dialog-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-dialog",
            ok: false,
            details: { reason: "missing #dialog-trigger" },
          });
        } else {
          const triggerHandle = await trigger.first().elementHandle();

          const bodyOverflowBefore = await page.evaluate(
            () => document.body?.style?.overflow ?? null,
          );

          await trigger.first().click({ timeout: timeoutMs });
          step = "wait dialog open";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") != null,
            { timeout: timeoutMs },
          );
          step = "wait focus close";
          await page.waitForFunction(
            () => document.activeElement?.id === "dialog-close",
            { timeout: timeoutMs },
          );

          const afterOpen = await page.evaluate(() => {
            const dialog = document.querySelector("#dialog-panel");
            const app = document.querySelector("#app");
            return {
              role: dialog?.getAttribute("role") ?? null,
              ariaModal: dialog?.getAttribute("aria-modal") ?? null,
              appAriaHidden: app?.getAttribute("aria-hidden") ?? null,
              appInert: app?.hasAttribute("inert") ?? null,
              bodyOverflow: document.body?.style?.overflow ?? null,
              activeId: document.activeElement?.id ?? null,
            };
          });

          // Loop focus with tab/shift+tab and prevent programmatic escape.
          await page.keyboard.press("Shift+Tab");
          await page.waitForTimeout(50);
          const activeAfterShiftTab = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );
          await page.keyboard.press("Tab");
          await page.waitForTimeout(30);
          const activeAfterTabFromLast = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );
          await page.keyboard.press("Tab");
          await page.waitForTimeout(30);
          const activeAfterSecondTab = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          // Programmatic focus outside should not dismiss; focus should be brought back.
          await page.evaluate(() => {
            const t = document.querySelector("#dialog-trigger");
            // @ts-ignore
            t?.focus?.();
          });
          await page.waitForTimeout(50);
          const afterProgrammaticOutside = await page.evaluate(() => ({
            dialogOpen: document.querySelector("#dialog-panel") != null,
            activeId: document.activeElement?.id ?? null,
          }));

          await page.keyboard.press("Tab");
          await page.waitForTimeout(100);
          const activeAfterTab = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          // Open nested dialog.
          await page.click("#dialog-nested-trigger", { timeout: timeoutMs });
          step = "wait nested open";
          await page.waitForFunction(
            () => document.querySelector("#dialog-nested-panel") != null,
            { timeout: timeoutMs },
          );
          step = "wait nested focus";
          await page.waitForFunction(
            () => document.activeElement?.id === "dialog-nested-close",
            { timeout: timeoutMs },
          );

          const overflowWithNested = await page.evaluate(
            () => document.body?.style?.overflow ?? null,
          );

          // Clicking outside nested (on its backdrop) should close nested only.
          // Click away from the centered panel so the panel doesn't intercept.
          await page.click("#dialog-nested-backdrop", {
            timeout: timeoutMs,
            position: { x: 5, y: 5 },
          });
          step = "wait nested closed by backdrop";
          await page.waitForFunction(
            () => document.querySelector("#dialog-nested-panel") == null,
            { timeout: timeoutMs },
          );
          step = "wait parent still open after nested close";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") != null,
            { timeout: timeoutMs },
          );

          // Escape closes nested only.
          await page.click("#dialog-nested-trigger", { timeout: timeoutMs });
          step = "wait nested reopen";
          await page.waitForFunction(
            () => document.querySelector("#dialog-nested-panel") != null,
            { timeout: timeoutMs },
          );
          await page.keyboard.press("Escape");
          step = "wait nested closed by escape";
          await page.waitForFunction(
            () => document.querySelector("#dialog-nested-panel") == null,
            { timeout: timeoutMs },
          );
          step = "wait parent still open after nested escape";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") != null,
            { timeout: timeoutMs },
          );

          const overflowAfterNestedClose = await page.evaluate(
            () => document.body?.style?.overflow ?? null,
          );

          // Escape closes parent.
          await page.keyboard.press("Escape");
          step = "wait parent closed by escape";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const afterClose = await page.evaluate(() => {
            const app = document.querySelector("#app");
            return {
              appAriaHidden: app?.getAttribute("aria-hidden") ?? null,
              appInert: app?.hasAttribute("inert") ?? null,
              bodyOverflow: document.body?.style?.overflow ?? null,
              activeId: document.activeElement?.id ?? null,
            };
          });

          const focusRestored = triggerHandle
            ? await triggerHandle.evaluate(
                (el) => el === document.activeElement,
              )
            : false;

          // Outside click closes.
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait dialog reopen for outside click";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") != null,
            { timeout: timeoutMs },
          );

          // Pointer-blocking: clicking an outside button should close the dialog
          // but not activate the button (requires a second click after close).
          await page.waitForTimeout(60);
          const statusTextBefore =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const outsideBeforeMatch = statusTextBefore.match(/Outside clicks:\s*(\d+)/);
          const outsideBefore = outsideBeforeMatch
            ? Number(outsideBeforeMatch[1])
            : null;
          const outsideRect = await page.evaluate(() => {
            const el = document.querySelector("#dialog-outside-action");
            if (!el) return null;
            const r = el.getBoundingClientRect();
            return { x: r.left + 6, y: r.top + 6 };
          });
          if (outsideRect) {
            await page.mouse.click(outsideRect.x, outsideRect.y);
          }
          step = "wait closed after outside click";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") == null,
            { timeout: timeoutMs },
          );
          const statusTextAfterFirst =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const outsideAfterFirstMatch = statusTextAfterFirst.match(
            /Outside clicks:\s*(\d+)/,
          );
          const outsideAfterFirst = outsideAfterFirstMatch
            ? Number(outsideAfterFirstMatch[1])
            : null;
          await page.click("#dialog-outside-action", { timeout: timeoutMs });
          const statusTextAfterSecond =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const outsideAfterSecondMatch = statusTextAfterSecond.match(
            /Outside clicks:\s*(\d+)/,
          );
          const outsideAfterSecond = outsideAfterSecondMatch
            ? Number(outsideAfterSecondMatch[1])
            : null;

          // Re-open to validate outside dismiss still works.
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait dialog reopen for body click";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") != null,
            { timeout: timeoutMs },
          );
          // Click away from the centered panel so the panel doesn't intercept.
          await page.click("#dialog-backdrop", {
            timeout: timeoutMs,
            position: { x: 5, y: 5 },
          });
          step = "wait dialog closed by backdrop click";
          await page.waitForFunction(
            () => document.querySelector("#dialog-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const statusText =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";

          // No-backdrop modal should still pointer-block and dismiss on outside click.
          step = "open no-backdrop dialog";
          await page.click("#dialog-trigger-nobackdrop", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#dialog-nobackdrop-panel") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => document.activeElement?.id === "dialog-nobackdrop-close",
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);

          const statusTextNoBackdropBefore =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const noBackdropOutsideBeforeMatch = statusTextNoBackdropBefore.match(
            /Outside clicks:\s*(\d+)/,
          );
          const noBackdropOutsideBefore = noBackdropOutsideBeforeMatch
            ? Number(noBackdropOutsideBeforeMatch[1])
            : null;
          const noBackdropOutsideRect = await page.evaluate(() => {
            const el = document.querySelector("#dialog-outside-action");
            if (!el) return null;
            const r = el.getBoundingClientRect();
            return { x: r.left + 6, y: r.top + 6 };
          });
          if (noBackdropOutsideRect) {
            await page.mouse.click(noBackdropOutsideRect.x, noBackdropOutsideRect.y);
          }
          step = "wait no-backdrop dialog closed by outside click";
          await page.waitForFunction(
            () => document.querySelector("#dialog-nobackdrop-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const statusTextNoBackdropAfterFirst =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const noBackdropOutsideAfterFirstMatch =
            statusTextNoBackdropAfterFirst.match(/Outside clicks:\s*(\d+)/);
          const noBackdropOutsideAfterFirst = noBackdropOutsideAfterFirstMatch
            ? Number(noBackdropOutsideAfterFirstMatch[1])
            : null;
          const noBackdropFocusRestored = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          await page.click("#dialog-outside-action", { timeout: timeoutMs });
          await page.waitForTimeout(30);
          const statusTextNoBackdropAfterSecond =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";
          const noBackdropOutsideAfterSecondMatch =
            statusTextNoBackdropAfterSecond.match(/Outside clicks:\s*(\d+)/);
          const noBackdropOutsideAfterSecond = noBackdropOutsideAfterSecondMatch
            ? Number(noBackdropOutsideAfterSecondMatch[1])
            : null;

          // Auto focus hooks should be preventable/overrideable.
          step = "open hooks dialog";
          await page.click("#dialog-hooks-trigger", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#dialog-hooks-panel") != null,
            { timeout: timeoutMs },
          );
          step = "wait hooks autofocus";
          await page.waitForFunction(
            () => document.activeElement?.id === "dialog-hooks-secondary",
            { timeout: timeoutMs },
          );
          await page.keyboard.press("Escape");
          step = "wait hooks closed";
          await page.waitForFunction(
            () => document.querySelector("#dialog-hooks-panel") == null,
            { timeout: timeoutMs },
          );
          step = "wait hooks close autofocus";
          await page.waitForFunction(
            () => document.activeElement?.id === "dialog-outside-action",
            { timeout: timeoutMs },
          );
          const statusTextHooks =
            (await page.locator("#dialog-status").textContent())?.trim() ?? "";

          const ok =
            afterOpen.role === "dialog" &&
            afterOpen.ariaModal === "true" &&
            afterOpen.appAriaHidden === "true" &&
            afterOpen.appInert === true &&
            afterOpen.bodyOverflow === "hidden" &&
            afterOpen.activeId === "dialog-close" &&
            activeAfterShiftTab === "dialog-nested-trigger" &&
            activeAfterTabFromLast === "dialog-close" &&
            activeAfterSecondTab === "dialog-nested-trigger" &&
            afterProgrammaticOutside.dialogOpen === true &&
            typeof afterProgrammaticOutside.activeId === "string" &&
            afterProgrammaticOutside.activeId.startsWith("dialog-") &&
            activeAfterTab != null &&
            activeAfterTab.startsWith("dialog-") &&
            overflowWithNested === "hidden" &&
            overflowAfterNestedClose === "hidden" &&
            afterClose.bodyOverflow === bodyOverflowBefore &&
            afterClose.appAriaHidden == null &&
            afterClose.appInert === false &&
            focusRestored === true &&
            outsideBefore != null &&
            outsideAfterFirst === outsideBefore &&
            outsideAfterSecond === outsideBefore + 1 &&
            statusText.includes("outside") &&
            noBackdropOutsideBefore != null &&
            noBackdropOutsideAfterFirst === noBackdropOutsideBefore &&
            noBackdropOutsideAfterSecond === noBackdropOutsideBefore + 1 &&
            noBackdropFocusRestored === "dialog-trigger-nobackdrop" &&
            statusTextHooks.includes("hooks:escape");

          interactionResults.push({
            name: "solid-dialog",
            ok,
            details: {
              bodyOverflowBefore,
              activeAfterShiftTab,
              activeAfterTabFromLast,
              activeAfterSecondTab,
              afterProgrammaticOutside,
              afterOpen,
              activeAfterTab,
              overflowWithNested,
              overflowAfterNestedClose,
              afterClose,
              focusRestored,
              outsideBefore,
              outsideAfterFirst,
              outsideAfterSecond,
              statusText,
              noBackdropOutsideBefore,
              noBackdropOutsideAfterFirst,
              noBackdropOutsideAfterSecond,
              noBackdropFocusRestored,
              statusTextHooks,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-dialog",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-roving") {
      try {
        const toggle = page.locator("#roving-toggle");
        if (!(await toggle.count())) {
          interactionResults.push({
            name: "solid-roving",
            ok: false,
            details: { reason: "missing #roving-toggle" },
          });
        } else {
          await page.waitForFunction(
            () => document.querySelector("#roving-group") != null,
            { timeout: timeoutMs },
          );

          const before = await page.evaluate(() => {
            const a = document.querySelector("#roving-a");
            const b = document.querySelector("#roving-b");
            const c = document.querySelector("#roving-c");
            return {
              activeId: document.activeElement?.id ?? null,
              tabA: a?.getAttribute("tabindex") ?? null,
              tabB: b?.getAttribute("tabindex") ?? null,
              tabC: c?.getAttribute("tabindex") ?? null,
              cleanup: document.querySelector("#roving-status")?.textContent ?? null,
            };
          });

          await page.click("#roving-a", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.activeElement?.id === "roving-a",
            { timeout: timeoutMs },
          );

          await page.keyboard.press("ArrowRight");
          await page.waitForFunction(
            () => document.activeElement?.id === "roving-b",
            { timeout: timeoutMs },
          );
          const afterRight = await page.evaluate(() => {
            const a = document.querySelector("#roving-a");
            const b = document.querySelector("#roving-b");
            const c = document.querySelector("#roving-c");
            return {
              activeId: document.activeElement?.id ?? null,
              tabA: a?.getAttribute("tabindex") ?? null,
              tabB: b?.getAttribute("tabindex") ?? null,
              tabC: c?.getAttribute("tabindex") ?? null,
            };
          });

          await page.keyboard.press("ArrowLeft");
          await page.waitForFunction(
            () => document.activeElement?.id === "roving-a",
            { timeout: timeoutMs },
          );

          await toggle.click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#roving-group") == null,
            { timeout: timeoutMs },
          );
          const afterUnmount = await page.evaluate(() => ({
            empty: document.querySelector("#roving-empty") != null,
            cleanup: document.querySelector("#roving-status")?.textContent ?? null,
          }));

          await toggle.click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#roving-group") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => document.activeElement?.id?.startsWith("roving-") ?? false,
            { timeout: timeoutMs },
          );

          const ok =
            before.activeId === "roving-a" &&
            before.tabA === "0" &&
            before.tabB === "-1" &&
            before.tabC === "-1" &&
            afterRight.activeId === "roving-b" &&
            afterRight.tabA === "-1" &&
            afterRight.tabB === "0" &&
            afterRight.tabC === "-1" &&
            afterUnmount.empty === true &&
            /Cleanup:\s+1/.test(afterUnmount.cleanup ?? "");

          interactionResults.push({
            name: "solid-roving",
            ok,
            details: { before, afterRight, afterUnmount },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-roving",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-popover") {
      try {
        const trigger = page.locator("#popover-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover",
            ok: false,
            details: { reason: "missing #popover-trigger" },
          });
        } else {
          const triggerHandle = await trigger.first().elementHandle();
          const appBefore = await page.evaluate(() => {
            const app = document.querySelector("#app");
            return {
              ariaHidden: app?.getAttribute("aria-hidden") ?? null,
              inert: app?.hasAttribute("inert") ?? null,
            };
          });

          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") != null,
            { timeout: timeoutMs },
          );

          const afterOpen = await page.evaluate(() => ({
            panelExists: document.querySelector("#popover-panel") != null,
            activeId: document.activeElement?.id ?? null,
            appAriaHidden: document.querySelector("#app")?.getAttribute("aria-hidden") ?? null,
            appInert: document.querySelector("#app")?.hasAttribute("inert") ?? null,
          }));

          // Escape should dismiss.
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterEscape = await page.evaluate(() => ({
            activeId: document.activeElement?.id ?? null,
            status: document.querySelector("#popover-status")?.textContent ?? null,
          }));

          const focusRestoredEscape = triggerHandle
            ? await triggerHandle.evaluate((el) => el === document.activeElement)
            : false;

          // Outside click should dismiss too.
          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") != null,
            { timeout: timeoutMs },
          );
          await page.click("body", { position: { x: 5, y: 5 } });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterOutside = await page.evaluate(() => ({
            status: document.querySelector("#popover-status")?.textContent ?? null,
            appAriaHidden: document.querySelector("#app")?.getAttribute("aria-hidden") ?? null,
            appInert: document.querySelector("#app")?.hasAttribute("inert") ?? null,
          }));

          const ok =
            appBefore.ariaHidden == null &&
            appBefore.inert === false &&
            afterOpen.panelExists === true &&
            afterOpen.appAriaHidden == null &&
            afterOpen.appInert === false &&
            afterOpen.activeId === "popover-trigger" &&
            focusRestoredEscape === true &&
            (afterEscape.status ?? "").includes("escape") &&
            (afterOutside.status ?? "").includes("outside") &&
            afterOutside.appAriaHidden == null &&
            afterOutside.appInert === false;

          interactionResults.push({
            name: "solid-popover",
            ok,
            details: {
              appBefore,
              afterOpen,
              afterEscape,
              focusRestoredEscape,
              afterOutside,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-popover-clickthrough") {
      let step = "init";
      try {
        const trigger = page.locator("#popover-trigger");
        const outside = page.locator("#popover-outside-action");
        if (!(await trigger.count()) || !(await outside.count())) {
          interactionResults.push({
            name: "solid-popover-clickthrough",
            ok: false,
            details: { reason: "missing popover trigger/outside action" },
          });
        } else {
          const readOutsideClicks = async () =>
            await page.evaluate(() => {
              const text =
                document.querySelector("#popover-status")?.textContent ?? "";
              const m = text.match(/Outside clicks:\s*(\d+)/);
              return { text, count: m ? Number(m[1]) : null };
            });

          const before = await readOutsideClicks();
          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait panel";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") != null,
            { timeout: timeoutMs },
          );

          step = "click outside action (dismiss)";
          await outside.first().click({ timeout: timeoutMs });
          step = "wait closed";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterDismiss = await readOutsideClicks();

          step = "click outside action again";
          await outside.first().click({ timeout: timeoutMs });
          await page.waitForTimeout(80);
          const afterClick = await readOutsideClicks();

          const ok =
            before.count != null &&
            afterDismiss.count === before.count &&
            afterClick.count === before.count + 1;

          interactionResults.push({
            name: "solid-popover-clickthrough",
            ok,
            details: { before, afterDismiss, afterClick },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-clickthrough",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-popover-position") {
      try {
        const trigger = page.locator("#popover-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-position",
            ok: false,
            details: { reason: "missing #popover-trigger" },
          });
        } else {
          await page.evaluate(() => {
            document.body.style.height = "3000px";
            document.documentElement.style.height = "3000px";
            window.scrollTo(0, 0);
          });

          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel") != null,
            { timeout: timeoutMs },
          );

          const readPos = async () =>
            await page.evaluate(() => {
              const el = document.querySelector("#popover-panel");
              if (!el) return null;
              const cs = getComputedStyle(el);
              const r = el.getBoundingClientRect();
              // @ts-ignore
              const pos = cs.position ?? "";
              return {
                pos,
                transform: cs.transform,
                left: r.left,
                top: r.top,
              };
            });

          const before = await readPos();

          await page.evaluate(() => window.scrollTo(0, 200));
          await page.waitForFunction(() => window.scrollY >= 150, {
            timeout: timeoutMs,
          });
          await page.waitForTimeout(150);

          const after = await readPos();

          const ok =
            before != null &&
            before.pos === "fixed" &&
            typeof before.transform === "string" &&
            before.transform !== "" &&
            before.transform !== "none" &&
            after != null &&
            (after.top !== before.top || after.left !== before.left);

          interactionResults.push({
            name: "solid-popover-position",
            ok,
            details: { before, after, scrollY: await page.evaluate(() => window.scrollY) },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-position",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-popover-flip") {
      try {
        const trigger = page.locator("#popover-trigger-bottom");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-flip",
            ok: false,
            details: { reason: "missing #popover-trigger-bottom" },
          });
        } else {
          await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
          await page.waitForTimeout(150);

          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-bottom") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () =>
              document
                .querySelector("#popover-panel-bottom")
                ?.getAttribute("data-solid-placement") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const anchor = document.querySelector("#popover-trigger-bottom");
            const panel = document.querySelector("#popover-panel-bottom");
            if (!anchor || !panel) return null;
            const a = anchor.getBoundingClientRect();
            const p = panel.getBoundingClientRect();
            return {
              anchorTop: a.top,
              anchorBottom: a.bottom,
              panelTop: p.top,
              panelBottom: p.bottom,
              placement: panel.getAttribute("data-solid-placement"),
            };
          });

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.startsWith("top") &&
            // If flipped/clamped, panel should be above the anchor.
            metrics.panelTop < metrics.anchorTop;

          interactionResults.push({
            name: "solid-popover-flip",
            ok,
            details: { metrics, scrollY: await page.evaluate(() => window.scrollY) },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-flip",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-popover-flip-horizontal") {
      let step = "init";
      try {
        const trigger = page.locator("#popover-trigger-flip-h");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-flip-horizontal",
            ok: false,
            details: { reason: "missing #popover-trigger-flip-h" },
          });
        } else {
          await page.setViewportSize({ width: 320, height: 520 });
          await page.waitForTimeout(80);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait panel";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-flip-h") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-flip-h");
            const anchor = document.querySelector("#popover-trigger-flip-h");
            if (!panel || !anchor) return null;
            const pr = panel.getBoundingClientRect();
            const ar = anchor.getBoundingClientRect();
            return {
              vw: window.innerWidth,
              panel: {
                left: pr.left,
                right: pr.right,
                top: pr.top,
                bottom: pr.bottom,
              },
              anchor: {
                left: ar.left,
                right: ar.right,
              },
              placement: panel.getAttribute("data-solid-placement"),
            };
          });

          const ok =
            metrics != null &&
            metrics.panel.left >= 0 &&
            metrics.panel.right <= metrics.vw &&
            typeof metrics.placement === "string" &&
            metrics.placement.startsWith("left");

          interactionResults.push({
            name: "solid-popover-flip-horizontal",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-flip-horizontal",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-popover-shift") {
      let step = "init";
      try {
        const trigger = page.locator("#popover-trigger-shift");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-shift",
            ok: false,
            details: { reason: "missing #popover-trigger-shift" },
          });
        } else {
          step = "set viewport";
          await page.setViewportSize({ width: 900, height: 520 });
          await page.waitForTimeout(40);

          step = "open shift popover";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait panel open";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-shift") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const t = document.querySelector("#popover-trigger-shift");
            const p = document.querySelector("#popover-panel-shift");
            if (!t || !p) return null;
            const a = t.getBoundingClientRect();
            const r = p.getBoundingClientRect();
            const dx = Math.round(r.left - a.left);
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              anchorLeft: Math.round(a.left),
              panelLeft: Math.round(r.left),
              dx,
              panel: {
                left: Math.round(r.left),
                right: Math.round(r.right),
                top: Math.round(r.top),
                bottom: Math.round(r.bottom),
              },
            };
          });

          const ok =
            metrics != null &&
            metrics.dx >= 35 &&
            metrics.dx <= 45 &&
            metrics.panel.left >= 6 &&
            metrics.panel.right <= metrics.vw - 6;

          interactionResults.push({
            name: "solid-popover-shift",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-shift",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-popover-resize") {
      try {
        const trigger = page.locator("#popover-trigger-edge");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-resize",
            ok: false,
            details: { reason: "missing #popover-trigger-edge" },
          });
        } else {
          await page.setViewportSize({ width: 860, height: 600 });
          await page.waitForTimeout(80);

          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-edge") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const before = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-edge");
            if (!panel) return null;
            const r = panel.getBoundingClientRect();
            const cs = getComputedStyle(panel);
            return {
              left: r.left,
              right: r.right,
              top: r.top,
              bottom: r.bottom,
              vw: window.innerWidth,
              vh: window.innerHeight,
              scrollX: window.scrollX,
              scrollY: window.scrollY,
              styleLeft: cs.left,
              styleTop: cs.top,
              placement: panel.getAttribute("data-solid-placement"),
            };
          });

          await page.setViewportSize({ width: 420, height: 600 });
          await page.waitForTimeout(120);

          const after = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-edge");
            if (!panel) return null;
            const r = panel.getBoundingClientRect();
            const cs = getComputedStyle(panel);
            return {
              left: r.left,
              right: r.right,
              top: r.top,
              bottom: r.bottom,
              vw: window.innerWidth,
              vh: window.innerHeight,
              scrollX: window.scrollX,
              scrollY: window.scrollY,
              styleLeft: cs.left,
              styleTop: cs.top,
              placement: panel.getAttribute("data-solid-placement"),
            };
          });

          const padding = 8;
          const inViewport =
            (m) =>
              m &&
              m.left >= padding - 0.5 &&
              m.top >= padding - 0.5 &&
              m.right <= m.vw - padding + 0.5 &&
              m.bottom <= m.vh - padding + 0.5;

          const ok =
            before != null &&
            after != null &&
            inViewport(before) &&
            inViewport(after) &&
            (before.left !== after.left || before.top !== after.top) &&
            typeof before.placement === "string" &&
            typeof after.placement === "string";

          interactionResults.push({
            name: "solid-popover-resize",
            ok,
            details: { before, after },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-resize",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-popover-slide-overlap") {
      let step = "init";
      try {
        const padding = 8;
        await page.setViewportSize({ width: 420, height: 320 });
        await page.waitForTimeout(80);

        const openAndRead = async (triggerSel, panelSel) => {
          const trigger = page.locator(triggerSel);
          step = `open ${triggerSel}`;
          await trigger.first().click({ timeout: timeoutMs });
          step = `wait ${panelSel}`;
          await page.waitForFunction(
            (sel) => document.querySelector(sel) != null,
            panelSel,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const m = await page.evaluate(
            ({ panelSel }) => {
              const panel = document.querySelector(panelSel);
              if (!panel) return null;
              const r = panel.getBoundingClientRect();
              const cs = getComputedStyle(panel);
              const style = panel.style;
              return {
                vw: window.innerWidth,
                vh: window.innerHeight,
                left: r.left,
                right: r.right,
                top: r.top,
                bottom: r.bottom,
                placement: panel.getAttribute("data-solid-placement"),
                transform: cs.transform,
                availableWidth: style.getPropertyValue("--solid-popper-content-available-width") || null,
                availableHeight: style.getPropertyValue("--solid-popper-content-available-height") || null,
              };
            },
            { panelSel },
          );
          // close (trigger can be covered by the panel, so prefer Escape/outside).
          step = `close ${panelSel}`;
          let closed = false;
          try {
            await page.keyboard.press("Escape");
            await page.waitForFunction(
              (sel) => document.querySelector(sel) == null,
              panelSel,
              { timeout: 1500 },
            );
            closed = true;
          } catch {}
          if (!closed) {
            try {
              await page.click("body", { position: { x: 2, y: 2 } });
              await page.waitForFunction(
                (sel) => document.querySelector(sel) == null,
                panelSel,
                { timeout: 1500 },
              );
              closed = true;
            } catch {}
          }
          if (!closed) throw new Error(`failed to close ${panelSel}`);
          return m;
        };

        const slideOff = await openAndRead(
          "#popover-trigger-slide-off",
          "#popover-panel-slide-off",
        );
        const slideOn = await openAndRead(
          "#popover-trigger-slide-on",
          "#popover-panel-slide-on",
        );
        const overlapOff = await openAndRead(
          "#popover-trigger-overlap-off",
          "#popover-panel-overlap-off",
        );
        const overlapOn = await openAndRead(
          "#popover-trigger-overlap-on",
          "#popover-panel-overlap-on",
        );

        const overflowsRight = (m) => m && m.right > m.vw - padding + 0.5;
        const overflowsBottom = (m) => m && m.bottom > m.vh - padding + 0.5;
        const inViewport = (m) =>
          m &&
          m.left >= padding - 0.5 &&
          m.top >= padding - 0.5 &&
          m.right <= m.vw - padding + 0.5 &&
          m.bottom <= m.vh - padding + 0.5;

        const ok =
          // slide=false: allow vertical overflow for right-start.
          slideOff != null &&
          overflowsBottom(slideOff) &&
          slideOff.placement?.startsWith("right") === true &&
          slideOff.transform !== "none" &&
          // slide=true: main-axis shift keeps it in viewport vertically.
          slideOn != null &&
          inViewport(slideOn) &&
          slideOn.placement?.startsWith("right") === true &&
          slideOn.transform !== "none" &&
          // overlap=false: allow horizontal overflow for right-start.
          overlapOff != null &&
          overflowsRight(overlapOff) &&
          overlapOff.placement?.startsWith("right") === true &&
          overlapOff.transform !== "none" &&
          // overlap=true: cross-axis shift keeps it in viewport horizontally.
          overlapOn != null &&
          inViewport(overlapOn) &&
          overlapOn.placement?.startsWith("right") === true &&
          overlapOn.transform !== "none";

        interactionResults.push({
          name: "solid-popover-slide-overlap",
          ok,
          details: { slideOff, slideOn, overlapOff, overlapOn },
        });
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-slide-overlap",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-popover-hide-detached") {
      let step = "init";
      try {
        const trigger = page.locator("#popover-trigger-hide");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-hide-detached",
            ok: false,
            details: { reason: "missing #popover-trigger-hide" },
          });
        } else {
          await page.setViewportSize({ width: 720, height: 520 });
          await page.waitForTimeout(60);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait panel";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-hide") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const visibleBefore = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-hide");
            if (!panel) return null;
            return getComputedStyle(panel).visibility;
          });

          step = "hide anchor";
          await page.evaluate(() => {
            const t = document.querySelector("#popover-trigger-hide");
            if (t) t.style.display = "none";
          });
          await page.waitForTimeout(150);

          const hiddenAfter = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-hide");
            if (!panel) return null;
            return getComputedStyle(panel).visibility;
          });

          step = "restore anchor";
          await page.evaluate(() => {
            const t = document.querySelector("#popover-trigger-hide");
            if (t) t.style.display = "";
          });
          await page.waitForTimeout(150);

          const visibleAgain = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-hide");
            if (!panel) return null;
            return getComputedStyle(panel).visibility;
          });

          // close
          step = "close";
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-hide") == null,
            { timeout: timeoutMs },
          );

          const ok =
            visibleBefore === "visible" &&
            hiddenAfter === "hidden" &&
            visibleAgain === "visible";

          interactionResults.push({
            name: "solid-popover-hide-detached",
            ok,
            details: { visibleBefore, hiddenAfter, visibleAgain },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-hide-detached",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-popover-arrow") {
      let step = "init";
      try {
        const trigger = page.locator("#popover-trigger-arrow");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-popover-arrow",
            ok: false,
            details: { reason: "missing #popover-trigger-arrow" },
          });
        } else {
          await page.setViewportSize({ width: 720, height: 520 });
          await page.waitForTimeout(60);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait panel";
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-arrow") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const panel = document.querySelector("#popover-panel-arrow");
            const arrow = panel?.querySelector("[data-solid-popper-arrow]");
            if (!panel || !arrow) return null;
            const pr = panel.getBoundingClientRect();
            const ar = arrow.getBoundingClientRect();
            const placement = panel.getAttribute("data-solid-placement") ?? "";
            const base = placement.split("-")[0] || "";
            // @ts-ignore
            const baseSide = arrow.style?.[base] ?? "";
            return {
              placement,
              base,
              baseSide,
              panel: { left: pr.left, right: pr.right, top: pr.top, bottom: pr.bottom },
              arrow: { left: ar.left, right: ar.right, top: ar.top, bottom: ar.bottom },
            };
          });

          step = "close";
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            () => document.querySelector("#popover-panel-arrow") == null,
            { timeout: timeoutMs },
          );

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.length > 0 &&
            metrics.baseSide === "100%" &&
            // Arrow should sit horizontally within the panel bounds.
            metrics.arrow.left >= metrics.panel.left - 1 &&
            metrics.arrow.right <= metrics.panel.right + 1;

          interactionResults.push({
            name: "solid-popover-arrow",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-popover-arrow",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-tooltip") {
      try {
        const trigger = page.locator("#tooltip-trigger");
        const focusTrigger = page.locator("#tooltip-focus-trigger");
        if (!(await trigger.count()) || !(await focusTrigger.count())) {
          interactionResults.push({
            name: "solid-tooltip",
            ok: false,
            details: { reason: "missing tooltip triggers" },
          });
        } else {
          // Hover opens after delay.
          await page.hover("#tooltip-trigger");
          await page.waitForFunction(
            () => document.querySelector("#tooltip-panel") != null,
            { timeout: timeoutMs },
          );

          const afterHoverOpen = await page.evaluate(() => {
            const trigger = document.querySelector("#tooltip-trigger");
            const panel = document.querySelector("#tooltip-panel");
            // @ts-ignore
            const left = panel?.style?.left ?? "";
            // @ts-ignore
            const top = panel?.style?.top ?? "";
            const transform = panel ? getComputedStyle(panel).transform : "";
            return {
              describedBy: trigger?.getAttribute("aria-describedby") ?? null,
              tooltipId: panel?.id ?? null,
              left,
              top,
              transform,
            };
          });

          // Leaving closes after delay.
          await page.mouse.move(5, 5);
          await page.waitForFunction(
            () => document.querySelector("#tooltip-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(50);
          const afterHoverClose = await page.evaluate(() => ({
            describedBy: document
              .querySelector("#tooltip-trigger")
              ?.getAttribute("aria-describedby") ?? null,
          }));

          // Focus opens, Escape closes.
          await page.focus("#tooltip-focus-trigger");
          await page.waitForFunction(
            () => document.querySelector("#tooltip-focus-panel") != null,
            { timeout: timeoutMs },
          );
          const afterFocusOpen = await page.evaluate(() => ({
            activeId: document.activeElement?.id ?? null,
            describedBy: document
              .querySelector("#tooltip-focus-trigger")
              ?.getAttribute("aria-describedby") ?? null,
            tooltipId: document.querySelector("#tooltip-focus-panel")?.id ?? null,
          }));
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            () => document.querySelector("#tooltip-focus-panel") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(50);
          const afterEscapeClose = await page.evaluate(() => ({
            describedBy: document
              .querySelector("#tooltip-focus-trigger")
              ?.getAttribute("aria-describedby") ?? null,
            status: document.querySelector("#tooltip-status")?.textContent ?? null,
          }));

          const hoverDescribedOk =
            afterHoverOpen.tooltipId != null &&
            typeof afterHoverOpen.describedBy === "string" &&
            afterHoverOpen.describedBy.includes(afterHoverOpen.tooltipId);
          const hasPos =
            (typeof afterHoverOpen.left === "string" &&
              typeof afterHoverOpen.top === "string" &&
              afterHoverOpen.left.endsWith("px") &&
              afterHoverOpen.top.endsWith("px")) ||
            (typeof afterHoverOpen.transform === "string" &&
              afterHoverOpen.transform !== "" &&
              afterHoverOpen.transform !== "none");
          const describedRemoved = afterHoverClose.describedBy == null;

          const focusActiveOk = afterFocusOpen.activeId === "tooltip-focus-trigger";
          const focusDescribedOk =
            typeof afterFocusOpen.describedBy === "string" &&
            afterFocusOpen.describedBy.includes(afterFocusOpen.tooltipId ?? "");
          const focusRemoved = afterEscapeClose.describedBy == null;
          const statusOk = (afterEscapeClose.status ?? "").includes("escape");

          interactionResults.push({
            name: "solid-tooltip",
            ok:
              hoverDescribedOk &&
              hasPos &&
              describedRemoved &&
              focusActiveOk &&
              focusDescribedOk &&
              focusRemoved &&
              statusOk,
            details: {
              afterHoverOpen,
              afterHoverClose,
              afterFocusOpen,
              afterEscapeClose,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-tooltip",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-tooltip-edge") {
      let step = "init";
      try {
        const trigger = page.locator("#tooltip-edge-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-tooltip-edge",
            ok: false,
            details: { reason: "missing #tooltip-edge-trigger" },
          });
        } else {
          step = "set small viewport";
          await page.setViewportSize({ width: 320, height: 240 });
          await page.waitForTimeout(50);

          step = "hover edge trigger";
          await trigger.first().hover({ timeout: timeoutMs });
          step = "wait tooltip open";
          await page.waitForFunction(
            () => document.querySelector("#tooltip-edge-panel") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const t = document.querySelector("#tooltip-edge-trigger");
            const p = document.querySelector("#tooltip-edge-panel");
            if (!t || !p) return null;
            const a = t.getBoundingClientRect();
            const r = p.getBoundingClientRect();
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              anchor: {
                left: Math.round(a.left),
                right: Math.round(a.right),
                top: Math.round(a.top),
                bottom: Math.round(a.bottom),
              },
              panel: {
                left: Math.round(r.left),
                right: Math.round(r.right),
                top: Math.round(r.top),
                bottom: Math.round(r.bottom),
              },
              placement: p.getAttribute("data-solid-placement"),
            };
          });

          step = "move away to close";
          await page.mouse.move(2, 2);
          await page.waitForFunction(
            () => document.querySelector("#tooltip-edge-panel") == null,
            { timeout: timeoutMs },
          );

          const ok =
            metrics != null &&
            metrics.panel.left >= 0 &&
            metrics.panel.right <= metrics.vw &&
            metrics.panel.top >= 0 &&
            metrics.panel.bottom <= metrics.vh &&
            typeof metrics.placement === "string" &&
            metrics.placement.startsWith("left");

          interactionResults.push({
            name: "solid-tooltip-edge",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-tooltip-edge",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-tooltip-arrow") {
      let step = "init";
      try {
        const trigger = page.locator("#tooltip-arrow-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-tooltip-arrow",
            ok: false,
            details: { reason: "missing #tooltip-arrow-trigger" },
          });
        } else {
          await page.setViewportSize({ width: 720, height: 320 });
          await page.waitForTimeout(60);

          step = "hover";
          await trigger.first().hover({ timeout: timeoutMs });
          step = "wait tooltip open";
          await page.waitForFunction(
            () => document.querySelector("#tooltip-arrow-panel") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const panel = document.querySelector("#tooltip-arrow-panel");
            const arrow = panel?.querySelector("[data-solid-popper-arrow]");
            if (!panel || !arrow) return null;
            const placement = panel.getAttribute("data-solid-placement") ?? "";
            const base = placement.split("-")[0] || "";
            // @ts-ignore
            const baseSide = arrow.style?.[base] ?? "";
            const pr = panel.getBoundingClientRect();
            const ar = arrow.getBoundingClientRect();
            return {
              placement,
              base,
              baseSide,
              panel: { left: pr.left, right: pr.right, top: pr.top, bottom: pr.bottom },
              arrow: { left: ar.left, right: ar.right, top: ar.top, bottom: ar.bottom },
            };
          });

          step = "move away to close";
          await page.mouse.move(2, 2);
          await page.waitForFunction(
            () => document.querySelector("#tooltip-arrow-panel") == null,
            { timeout: timeoutMs },
          );

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.length > 0 &&
            metrics.baseSide === "100%";

          interactionResults.push({
            name: "solid-tooltip-arrow",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-tooltip-arrow",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-tooltip-slide-overlap") {
      let step = "init";
      try {
        const padding = 8;
        await page.setViewportSize({ width: 420, height: 320 });
        await page.waitForTimeout(80);

        const hoverAndRead = async (triggerSel, panelSel) => {
          step = `hover ${triggerSel}`;
          await page.hover(triggerSel);
          step = `wait ${panelSel}`;
          await page.waitForFunction(
            (sel) => document.querySelector(sel) != null,
            panelSel,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const m = await page.evaluate(
            ({ panelSel }) => {
              const panel = document.querySelector(panelSel);
              if (!panel) return null;
              const r = panel.getBoundingClientRect();
              const cs = getComputedStyle(panel);
              return {
                vw: window.innerWidth,
                vh: window.innerHeight,
                left: r.left,
                right: r.right,
                top: r.top,
                bottom: r.bottom,
                placement: panel.getAttribute("data-solid-placement"),
                transform: cs.transform,
              };
            },
            { panelSel },
          );
          step = `close ${panelSel}`;
          await page.mouse.move(2, 2);
          await page.waitForFunction(
            (sel) => document.querySelector(sel) == null,
            panelSel,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          return m;
        };

        const slideOff = await hoverAndRead(
          "#tooltip-trigger-slide-off",
          "#tooltip-panel-slide-off",
        );
        const slideOn = await hoverAndRead(
          "#tooltip-trigger-slide-on",
          "#tooltip-panel-slide-on",
        );
        const overlapOff = await hoverAndRead(
          "#tooltip-trigger-overlap-off",
          "#tooltip-panel-overlap-off",
        );
        const overlapOn = await hoverAndRead(
          "#tooltip-trigger-overlap-on",
          "#tooltip-panel-overlap-on",
        );

        const overflowsRight = (m) => m && m.right > m.vw - padding + 0.5;
        const overflowsBottom = (m) => m && m.bottom > m.vh - padding + 0.5;
        const inViewport = (m) =>
          m &&
          m.left >= padding - 0.5 &&
          m.top >= padding - 0.5 &&
          m.right <= m.vw - padding + 0.5 &&
          m.bottom <= m.vh - padding + 0.5;

        const ok =
          slideOff != null &&
          overflowsBottom(slideOff) &&
          slideOff.placement?.startsWith("right") === true &&
          slideOff.transform !== "none" &&
          slideOn != null &&
          inViewport(slideOn) &&
          slideOn.placement?.startsWith("right") === true &&
          slideOn.transform !== "none" &&
          overlapOff != null &&
          overflowsRight(overlapOff) &&
          overlapOff.placement?.startsWith("right") === true &&
          overlapOff.transform !== "none" &&
          overlapOn != null &&
          inViewport(overlapOn) &&
          overlapOn.placement?.startsWith("right") === true &&
          overlapOn.transform !== "none";

        interactionResults.push({
          name: "solid-tooltip-slide-overlap",
          ok,
          details: { slideOff, slideOn, overlapOff, overlapOn },
        });
      } catch (e) {
        interactionResults.push({
          name: "solid-tooltip-slide-overlap",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select") {
      let step = "init";
      try {
        const trigger = page.locator("#select-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-select",
            ok: false,
            details: { reason: "missing #select-trigger" },
          });
        } else {
          let aborted = false;
          const afterButton = page.locator("#select-after");

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const afterOpen = await page.evaluate(() => ({
            expanded: document
              .querySelector("#select-trigger")
              ?.getAttribute("aria-expanded") ?? null,
            activeId: document.activeElement?.id ?? null,
            activeDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
            triggerWidth:
              document.querySelector("#select-trigger")?.getBoundingClientRect()
                ?.width ?? null,
            listboxWidth:
              document.querySelector("#select-listbox")?.getBoundingClientRect()
                ?.width ?? null,
          }));

          // Arrow navigation + skip disabled (Vue).
          step = "keydown down 1";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(30);
          const afterDown1 = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));
          step = "keydown down 2";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(30);
          const afterDown2 = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));
          step = "keydown down 3";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(30);
          const afterDown3 = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));

          // Hover should move focus quickly (Kobalte/native-like).
          step = "hover option 4";
          await page.locator("#select-listbox-opt-4").hover({ timeout: timeoutMs });
          await page.waitForFunction(
            () =>
              document.querySelector("#select-listbox [data-active=true]")?.id ===
              "select-listbox-opt-4",
            { timeout: timeoutMs },
          );
          const afterHover = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));

          step = "select enter";
          await page.keyboard.press("Enter");
          step = "wait listbox closed after select";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterSelect = await page.evaluate(() => ({
            status: document.querySelector("#select-status")?.textContent ?? null,
            triggerText: document.querySelector("#select-trigger")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Re-open and select again via keyboard (regression: Enter should work every time).
          step = "open for second select";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open for second select";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(20);
          const afterOpen2 = await page.evaluate(() => ({
            expanded: document
              .querySelector("#select-trigger")
              ?.getAttribute("aria-expanded") ?? null,
            activeId: document.activeElement?.id ?? null,
            listboxActiveDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            listboxActiveElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));
          step = "keydown down for second select";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(20);
          const afterDown2_1 = await page.evaluate(() => ({
            activeId: document.activeElement?.id ?? null,
            listboxActiveDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            listboxActiveElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));
          step = "keydown down 2 for second select";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(20);
          const afterDown2_2 = await page.evaluate(() => ({
            activeId: document.activeElement?.id ?? null,
            listboxActiveDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            listboxActiveElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
          }));
          step = "select enter 2";
          await page.keyboard.press("Enter");
          step = "wait listbox closed after select 2";
          let closed2 = true;
          try {
            await page.waitForFunction(
              () => document.querySelector("#select-listbox") == null,
              { timeout: 2500 },
            );
          } catch {
            closed2 = false;
          }
          await page.waitForTimeout(60);
          const afterSelect2 = await page.evaluate(() => ({
            closed: document.querySelector("#select-listbox") == null,
            expanded: document
              .querySelector("#select-trigger")
              ?.getAttribute("aria-expanded") ?? null,
            status: document.querySelector("#select-status")?.textContent ?? null,
            triggerText: document.querySelector("#select-trigger")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
            listboxActiveDescendant: document
              .querySelector("#select-listbox")
              ?.getAttribute("aria-activedescendant") ?? null,
            listboxActiveElId:
              document.querySelector("#select-listbox [data-active=true]")?.id ??
              null,
            listboxSelectedElId:
              document.querySelector("#select-listbox [aria-selected=true]")?.id ??
              null,
          }));
          if (!closed2) {
            interactionResults.push({
              name: "solid-select",
              ok: false,
              details: {
                reason: "select-2-did-not-close",
                afterOpen,
                afterDown1,
                afterDown2,
                afterDown3,
                afterHover,
                afterSelect,
                afterOpen2,
                afterDown2_1,
                afterDown2_2,
                afterSelect2,
              },
            });
            aborted = true;
            // Best-effort cleanup so later scenarios aren't affected.
            try {
              await page.keyboard.press("Escape");
              await page.waitForFunction(
                () => document.querySelector("#select-listbox") == null,
                { timeout: 1500 },
              );
            } catch {}
          }

          if (!aborted) {

          // Re-open and click the currently selected option (mouse should still close).
          step = "open for click selected";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open for click selected";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          step = "click selected option";
          await page.locator("#select-listbox [aria-selected=true]").first().click({
            timeout: timeoutMs,
          });
          step = "wait listbox closed after click selected";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterClickSelected = await page.evaluate(() => ({
            status: document.querySelector("#select-status")?.textContent ?? null,
            triggerText: document.querySelector("#select-trigger")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
            expanded:
              document.querySelector("#select-trigger")?.getAttribute("aria-expanded") ??
              null,
            listboxExists: document.querySelector("#select-listbox") != null,
          }));
          if (afterClickSelected.listboxExists) aborted = true;

          // Escape closes.
          step = "open for escape";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open for escape";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          step = "press escape";
          await page.keyboard.press("Escape");
          step = "wait listbox closed by escape";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterEscape = await page.evaluate(() => ({
            status: document.querySelector("#select-status")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Tab closes and allows focus to move to next element.
          step = "open for tab";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open for tab";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          step = "press tab";
          await page.keyboard.press("Tab");
          step = "wait listbox closed by tab";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          step = "wait focus after tab";
          await page.waitForFunction(
            () => document.activeElement?.id === "select-after",
            { timeout: timeoutMs },
          );
          const afterTab = await page.evaluate(() => ({
            status: document.querySelector("#select-status")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Outside click dismiss.
          step = "open for outside";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open for outside";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );
          step = "click body outside";
          await page.click("body", { position: { x: 5, y: 5 } });
          step = "wait listbox closed by outside";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterOutside = await page.evaluate(() => ({
            status: document.querySelector("#select-status")?.textContent ?? null,
            expanded: document
              .querySelector("#select-trigger")
              ?.getAttribute("aria-expanded") ?? null,
          }));

          const ok =
            afterOpen.expanded === "true" &&
            afterOpen.activeId === "select-listbox" &&
            afterOpen.activeDescendant === afterOpen.activeElId &&
            afterOpen.activeElId === "select-listbox-opt-0" &&
            typeof afterOpen.triggerWidth === "number" &&
            typeof afterOpen.listboxWidth === "number" &&
            Math.abs(afterOpen.triggerWidth - afterOpen.listboxWidth) <= 2.5 &&
            afterDown1.activeDescendant === afterDown1.activeElId &&
            afterDown1.activeElId === "select-listbox-opt-1" &&
            afterDown2.activeDescendant === afterDown2.activeElId &&
            afterDown2.activeElId === "select-listbox-opt-2" &&
            afterDown3.activeDescendant === afterDown3.activeElId &&
            afterDown3.activeElId === "select-listbox-opt-4" &&
            afterHover.activeDescendant === afterHover.activeElId &&
            afterHover.activeElId === "select-listbox-opt-4" &&
            (afterSelect.status ?? "").includes("Last: select") &&
            (afterSelect.triggerText ?? "").includes("Dart") &&
            afterSelect.activeId === "select-trigger" &&
            (afterSelect2.status ?? "").includes("Last: select") &&
            (afterSelect2.triggerText ?? "").includes("React") &&
            afterSelect2.activeId === "select-trigger" &&
            afterClickSelected.activeId === "select-trigger" &&
            (afterClickSelected.status ?? "").includes("Value: none") &&
            (afterClickSelected.triggerText ?? "").includes("Choose") &&
            (afterEscape.status ?? "").includes("Last: escape") &&
            afterEscape.activeId === "select-trigger" &&
            ((afterTab.status ?? "").includes("Last: tab") ||
              (afterTab.status ?? "").includes("Last: focus-outside")) &&
            afterTab.activeId === "select-after" &&
            (afterOutside.status ?? "").includes("Last: outside") &&
            afterOutside.expanded === "false";

          interactionResults.push({
            name: "solid-select",
            ok,
            details: {
              afterOpen,
              afterDown1,
              afterDown2,
              afterDown3,
              afterHover,
              afterSelect,
              afterSelect2,
              afterClickSelected,
              afterEscape,
              afterTab,
              afterOutside,
            },
          });
          }
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-select",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select-fitviewport") {
      let step = "init";
      try {
        const trigger = page.locator("#select-trigger-long");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-select-fitviewport",
            ok: false,
            details: { reason: "missing #select-trigger-long" },
          });
        } else {
          step = "set small viewport";
          await page.setViewportSize({ width: 520, height: 240 });
          await page.waitForTimeout(50);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox-long") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(() => {
            const el = document.querySelector("#select-listbox-long");
            if (!el) return false;
            const mh = getComputedStyle(el).maxHeight;
            return mh && mh !== "none";
          });
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const el = document.querySelector("#select-listbox-long");
            if (!el) return null;
            const rect = el.getBoundingClientRect();
            const cs = getComputedStyle(el);
            const maxHeight = cs.maxHeight;
            const maxHeightPx = Number.parseFloat(maxHeight || "0") || 0;
            const beforeScrollTop = el.scrollTop;
            el.scrollTop = 9999;
            const afterScrollTop = el.scrollTop;
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              rect: {
                left: Math.round(rect.left),
                right: Math.round(rect.right),
                top: Math.round(rect.top),
                bottom: Math.round(rect.bottom),
                width: Math.round(rect.width),
                height: Math.round(rect.height),
              },
              clientHeight: el.clientHeight,
              scrollHeight: el.scrollHeight,
              overflowY: cs.overflowY,
              maxHeight,
              maxHeightPx,
              beforeScrollTop,
              afterScrollTop,
            };
          });

          const ok =
            metrics != null &&
            metrics.maxHeightPx > 0 &&
            metrics.overflowY !== "visible" &&
            metrics.rect.top >= 6 &&
            metrics.rect.bottom <= metrics.vh - 6 &&
            metrics.scrollHeight > metrics.clientHeight &&
            metrics.afterScrollTop > metrics.beforeScrollTop;

          interactionResults.push({
            name: "solid-select-fitviewport",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-select-fitviewport",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select-flip") {
      let step = "init";
      try {
        const trigger = page.locator("#select-trigger-flip");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-select-flip",
            ok: false,
            details: { reason: "missing #select-trigger-flip" },
          });
        } else {
          step = "set small viewport";
          await page.setViewportSize({ width: 420, height: 240 });
          await page.waitForTimeout(50);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox-flip") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () =>
              document
                .querySelector("#select-listbox-flip")
                ?.getAttribute("data-solid-placement") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const lb = document.querySelector("#select-listbox-flip");
            if (!lb) return null;
            const r = lb.getBoundingClientRect();
            const cs = getComputedStyle(lb);
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              placement: lb.getAttribute("data-solid-placement"),
              transform: cs.transform,
              rect: {
                left: Math.round(r.left),
                right: Math.round(r.right),
                top: Math.round(r.top),
                bottom: Math.round(r.bottom),
              },
            };
          });

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.startsWith("top") &&
            typeof metrics.transform === "string" &&
            metrics.transform !== "" &&
            metrics.transform !== "none" &&
            metrics.rect.left >= 0 &&
            metrics.rect.right <= metrics.vw &&
            metrics.rect.top >= 0 &&
            metrics.rect.bottom <= metrics.vh;

          interactionResults.push({
            name: "solid-select-flip",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-select-flip",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select-flip-horizontal") {
      let step = "init";
      try {
        const trigger = page.locator("#select-trigger-flip-h");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-select-flip-horizontal",
            ok: false,
            details: { reason: "missing #select-trigger-flip-h" },
          });
        } else {
          step = "set viewport";
          await page.setViewportSize({ width: 360, height: 320 });
          await page.waitForTimeout(50);

          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox-flip-h") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () =>
              document
                .querySelector("#select-listbox-flip-h")
                ?.getAttribute("data-solid-placement") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const lb = document.querySelector("#select-listbox-flip-h");
            if (!lb) return null;
            const r = lb.getBoundingClientRect();
            const cs = getComputedStyle(lb);
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              placement: lb.getAttribute("data-solid-placement"),
              transform: cs.transform,
              rect: {
                left: Math.round(r.left),
                right: Math.round(r.right),
                top: Math.round(r.top),
                bottom: Math.round(r.bottom),
              },
            };
          });

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.startsWith("left") &&
            typeof metrics.transform === "string" &&
            metrics.transform !== "" &&
            metrics.transform !== "none" &&
            metrics.rect.left >= 0 &&
            metrics.rect.right <= metrics.vw &&
            metrics.rect.top >= 0 &&
            metrics.rect.bottom <= metrics.vh;

          interactionResults.push({
            name: "solid-select-flip-horizontal",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-select-flip-horizontal",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select-slide-overlap") {
      let step = "init";
      try {
        const padding = 8;
        await page.setViewportSize({ width: 420, height: 320 });
        await page.waitForTimeout(80);

        const openAndRead = async (triggerSel, listboxSel) => {
          step = `open ${triggerSel}`;
          await page.click(triggerSel, { timeout: timeoutMs });
          step = `wait ${listboxSel}`;
          await page.waitForFunction(
            (sel) => document.querySelector(sel) != null,
            listboxSel,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            (sel) =>
              document.querySelector(sel)?.getAttribute("data-solid-placement") !=
              null,
            listboxSel,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const m = await page.evaluate(
            ({ listboxSel }) => {
              const lb = document.querySelector(listboxSel);
              if (!lb) return null;
              const r = lb.getBoundingClientRect();
              const cs = getComputedStyle(lb);
              return {
                vw: window.innerWidth,
                vh: window.innerHeight,
                left: r.left,
                right: r.right,
                top: r.top,
                bottom: r.bottom,
                placement: lb.getAttribute("data-solid-placement"),
                transform: cs.transform,
              };
            },
            { listboxSel },
          );
          step = `close ${listboxSel}`;
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            (sel) => document.querySelector(sel) == null,
            listboxSel,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          return m;
        };

        const slideOff = await openAndRead(
          "#select-trigger-slide-off",
          "#select-listbox-slide-off",
        );
        const slideOn = await openAndRead(
          "#select-trigger-slide-on",
          "#select-listbox-slide-on",
        );
        const overlapOff = await openAndRead(
          "#select-trigger-overlap-off",
          "#select-listbox-overlap-off",
        );
        const overlapOn = await openAndRead(
          "#select-trigger-overlap-on",
          "#select-listbox-overlap-on",
        );

        const ok =
          slideOff != null &&
          slideOff.placement?.startsWith("right") === true &&
          slideOff.transform !== "none" &&
          slideOn != null &&
          slideOn.placement?.startsWith("right") === true &&
          slideOn.transform !== "none" &&
          overlapOff != null &&
          overlapOff.placement?.startsWith("bottom") === true &&
          overlapOff.transform !== "none" &&
          overlapOn != null &&
          overlapOn.placement?.startsWith("bottom") === true &&
          overlapOn.transform !== "none";

        interactionResults.push({
          name: "solid-select-slide-overlap",
          ok,
          details: { slideOff, slideOn, overlapOff, overlapOn },
        });
      } catch (e) {
        interactionResults.push({
          name: "solid-select-slide-overlap",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-select-clickthrough") {
      let step = "init";
      try {
        const trigger = page.locator("#select-trigger");
        const outside = page.locator("#select-outside-action");
        if (!(await trigger.count()) || !(await outside.count())) {
          interactionResults.push({
            name: "solid-select-clickthrough",
            ok: false,
            details: { reason: "missing select trigger/outside action" },
          });
        } else {
          const readOutsideClicks = async () =>
            await page.evaluate(() => {
              const text =
                document.querySelector("#select-status")?.textContent ?? "";
              const m = text.match(/Outside clicks:\s*(\d+)/);
              return { text, count: m ? Number(m[1]) : null };
            });

          const before = await readOutsideClicks();
          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait listbox";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") != null,
            { timeout: timeoutMs },
          );

          step = "click outside action (dismiss)";
          await outside.first().click({ timeout: timeoutMs });
          step = "wait closed";
          await page.waitForFunction(
            () => document.querySelector("#select-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterDismiss = await readOutsideClicks();

          step = "click outside action again";
          await outside.first().click({ timeout: timeoutMs });
          await page.waitForTimeout(80);
          const afterClick = await readOutsideClicks();

          const ok =
            before.count != null &&
            afterDismiss.count === before.count &&
            afterClick.count === before.count + 1;

          interactionResults.push({
            name: "solid-select-clickthrough",
            ok,
            details: { before, afterDismiss, afterClick },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-select-clickthrough",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-listbox") {
      let step = "init";
      try {
        const listbox = page.locator("#listbox-sections");
        const vfInput = page.locator("#listbox-virtual-input");
        if (!(await listbox.count()) || !(await vfInput.count())) {
          interactionResults.push({
            name: "solid-listbox",
            ok: false,
            details: { reason: "missing listbox elements" },
          });
        } else {
          step = "count groups";
          const groupCount = await page.evaluate(
            () => document.querySelectorAll("#listbox-sections [role=group]").length,
          );

          step = "focus first option";
          await page
            .locator("#listbox-sections [role=option]")
            .first()
            .click({ timeout: timeoutMs });
          await page.waitForTimeout(60);

          const before = await page.evaluate(() => {
            const el = document.querySelector("#listbox-sections");
            return {
              activeId: document.activeElement?.id ?? null,
              scrollTop: el ? el.scrollTop : null,
            };
          });

          // Mouse selection should update the status text.
          step = "click Flutter";
          await page
            .locator("#listbox-sections [role=option]")
            .filter({ hasText: "Flutter" })
            .first()
            .click({ timeout: timeoutMs });
          await page.waitForTimeout(60);
          const afterFlutter = await page.evaluate(() => ({
            status: document.querySelector("#listbox-status")?.textContent ?? null,
            selectedId:
              document.querySelector("#listbox-sections [aria-selected=true]")?.id ??
              null,
          }));

          step = "click Solid";
          await page
            .locator("#listbox-sections [role=option]")
            .filter({ hasText: "Solid" })
            .first()
            .click({ timeout: timeoutMs });
          await page.waitForTimeout(60);
          const afterSolid = await page.evaluate(() => ({
            status: document.querySelector("#listbox-status")?.textContent ?? null,
            selectedId:
              document.querySelector("#listbox-sections [aria-selected=true]")?.id ??
              null,
          }));

          step = "PageDown moves active and scrolls container";
          await page.keyboard.press("PageDown");
          await page.waitForTimeout(80);
          const afterPageDown = await page.evaluate(() => {
            const el = document.querySelector("#listbox-sections");
            return {
              activeId: document.activeElement?.id ?? null,
              scrollTop: el ? el.scrollTop : null,
            };
          });

          step = "End then Home";
          await page.keyboard.press("End");
          await page.waitForTimeout(60);
          const afterEnd = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );
          await page.keyboard.press("Home");
          await page.waitForTimeout(60);
          const afterHome = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          step = "virtual focus updates aria-activedescendant";
          await vfInput.first().click({ timeout: timeoutMs });
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(60);
          const afterVirtual = await page.evaluate(() => ({
            activeId: document.activeElement?.id ?? null,
            activeDescendant:
              document
                .querySelector("#listbox-virtual-input")
                ?.getAttribute("aria-activedescendant") ?? null,
            activeOptionId:
              document.querySelector("#listbox-virtual [data-active=true]")?.id ??
              null,
          }));

          const ok =
            groupCount >= 2 &&
            typeof before.activeId === "string" &&
            typeof afterPageDown.activeId === "string" &&
            before.activeId !== afterPageDown.activeId &&
            typeof before.scrollTop === "number" &&
            typeof afterPageDown.scrollTop === "number" &&
            afterPageDown.scrollTop > before.scrollTop &&
            typeof afterEnd === "string" &&
            typeof afterHome === "string" &&
            afterEnd !== afterHome &&
            (afterFlutter.status ?? "").includes("Flutter") &&
            (afterSolid.status ?? "").includes("Solid") &&
            afterVirtual.activeId === "listbox-virtual-input" &&
            typeof afterVirtual.activeDescendant === "string" &&
            afterVirtual.activeDescendant === afterVirtual.activeOptionId;

          interactionResults.push({
            name: "solid-listbox",
            ok,
            details: {
              groupCount,
              before,
              afterFlutter,
              afterSolid,
              afterPageDown,
              afterEnd,
              afterHome,
              afterVirtual,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-listbox",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-selection") {
      let step = "init";
      try {
        const list = page.locator("#selection-list");
        const status = page.locator("#selection-status");
        const first = page.locator("#selection-item-solid");
        const beforeBtn = page.locator("#selection-before");
        const afterBtn = page.locator("#selection-after");
        const resetFocus = page.locator("#selection-reset-focus");
        const disallowEmpty = page.locator("#selection-disallow-empty");
        const modeSingle = page.locator("#selection-mode-single");
        if (!(await list.count()) || !(await status.count()) || !(await first.count())) {
          interactionResults.push({
            name: "solid-selection",
            ok: false,
            details: { reason: "missing selection elements" },
          });
        } else {
          let single = null;
          let singleOk = true;

          step = "Tab into list focuses first enabled";
          if (await beforeBtn.count()) {
            await beforeBtn.first().click({ timeout: timeoutMs });
            await page.keyboard.press("Tab");
            await page.waitForFunction(
              () => document.activeElement?.id === "selection-item-solid",
              { timeout: timeoutMs },
            );
          }

          step = "Shift+Tab into list focuses last enabled";
          if ((await afterBtn.count()) && (await resetFocus.count())) {
            await resetFocus.first().click({ timeout: timeoutMs });
            await afterBtn.first().click({ timeout: timeoutMs });
            await page.keyboard.press("Shift+Tab");
            await page.waitForFunction(
              () => document.activeElement?.id === "selection-item-dart",
              { timeout: timeoutMs },
            );
          }

          step = "focus first item";
          await first.first().click({ timeout: timeoutMs });
          await page.waitForTimeout(60);

          step = "space selects focused item";
          await page.keyboard.press(" ");
          await page.waitForTimeout(60);
          const afterSpace = (await status.first().textContent())?.trim() ?? "";

          step = "shift+arrowdown extends selection";
          await page.keyboard.press("Shift+ArrowDown");
          await page.waitForTimeout(60);
          const afterExtend = (await status.first().textContent())?.trim() ?? "";

          step = "ctrl+a selects all (except disabled)";
          await page.keyboard.press("Control+a");
          await page.waitForTimeout(60);
          const afterSelectAll = (await status.first().textContent())?.trim() ?? "";

          step = "single selection toggles off when empty allowed";
          if ((await modeSingle.count()) && (await disallowEmpty.count())) {
            await modeSingle.first().click({ timeout: timeoutMs });
            await disallowEmpty.uncheck();
            await first.first().click({ timeout: timeoutMs });
            await page.keyboard.press(" ");
            await page.waitForTimeout(60);
            const singleSelected = (await status.first().textContent())?.trim() ?? "";
            await page.keyboard.press(" ");
            await page.waitForTimeout(60);
            const singleDeselected = (await status.first().textContent())?.trim() ?? "";

            await disallowEmpty.check();
            await page.waitForTimeout(60);
            const afterDisallow = (await status.first().textContent())?.trim() ?? "";
            await page.keyboard.press(" ");
            await page.waitForTimeout(60);
            const afterDisallowPress = (await status.first().textContent())?.trim() ?? "";

            const selectedPart = (s) => {
              const idx = (s ?? "").indexOf("Selected:");
              if (idx === -1) return "";
              return (s ?? "").slice(idx).trim();
            };

            singleOk =
              selectedPart(singleSelected).includes("solid") &&
              selectedPart(singleDeselected) === "Selected:" &&
              selectedPart(afterDisallow).includes("solid") &&
              selectedPart(afterDisallowPress).includes("solid");

            single = {
              ok: singleOk,
              singleSelected,
              singleDeselected,
              afterDisallow,
              afterDisallowPress,
            };
          }

          step = "pressUp selection happens on pointerup";
          await page.locator("#selection-pressup").check();
          await page.locator("#selection-pressorigin").check();
          await page.waitForTimeout(50);

          const pressTarget = page.locator("#selection-item-dart");
          const box = await pressTarget.boundingBox();
          if (!box) throw new Error("missing bounding box for selection item");

          const beforePressUp = (await status.first().textContent())?.trim() ?? "";
          await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
          await page.mouse.down();
          await page.waitForTimeout(40);
          const afterDown = (await status.first().textContent())?.trim() ?? "";
          await page.mouse.up();
          await page.waitForTimeout(60);
          const afterUp = (await status.first().textContent())?.trim() ?? "";

          const pressUp = { ok: true, before: beforePressUp, afterDown, afterUp };

          const selectedPart = (s) => {
            const idx = (s ?? "").indexOf("Selected:");
            if (idx === -1) return "";
            return (s ?? "").slice(idx).trim();
          };

          const ok =
            afterSpace.includes("Selected: solid") &&
            afterExtend.includes("solid") &&
            afterExtend.includes("react") &&
            afterSelectAll.includes("dart") &&
            !afterSelectAll.includes("vue") &&
            singleOk === true &&
            pressUp.ok === true &&
            selectedPart(pressUp.before) === selectedPart(pressUp.afterDown) &&
            selectedPart(pressUp.afterUp) !== selectedPart(pressUp.afterDown) &&
            pressUp.afterUp.includes("Selected: dart");

          interactionResults.push({
            name: "solid-selection",
            ok,
            details: { afterSpace, afterExtend, afterSelectAll, single, pressUp },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-selection",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-toast") {
      try {
        const trigger = page.locator("#toast-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-toast",
            ok: false,
            details: { reason: "missing #toast-trigger" },
          });
        } else {
          await trigger.first().click({ timeout: timeoutMs });
          await trigger.first().click({ timeout: timeoutMs });

          await page.waitForFunction(
            () => document.querySelector("#toast-viewport") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => document.querySelectorAll('[id^=\"toast-\"]').length >= 2,
            { timeout: timeoutMs },
          );

          const afterTwo = await page.evaluate(() => {
            const viewport = document.querySelector("#toast-viewport");
            const ids = Array.from(viewport?.querySelectorAll('[id^=\"toast-\"]') ?? []).map(
              (n) => n.id,
            );
            return { count: ids.length, ids };
          });

          // Dismiss first toast by button.
          await page.locator("#toast-1 button").click({ timeout: timeoutMs });
          await page.waitForTimeout(120);
          const afterButton = await page.evaluate(() => {
            const viewport = document.querySelector("#toast-viewport");
            const ids = Array.from(viewport?.querySelectorAll('[id^=\"toast-\"]') ?? []).map(
              (n) => n.id,
            );
            return { count: ids.length, ids };
          });

          // Auto-dismiss should remove the remaining toast shortly after TTL+exit.
          await page.waitForFunction(
            () =>
              document.querySelectorAll('#toast-viewport [id^="toast-"]').length ===
              0,
            { timeout: timeoutMs },
          );
          const afterAuto = await page.evaluate(() => {
            const viewport = document.querySelector("#toast-viewport");
            const ids = Array.from(viewport?.querySelectorAll('[id^=\"toast-\"]') ?? []).map(
              (n) => n.id,
            );
            return { count: ids.length, ids };
          });

          const ok =
            afterTwo.count >= 2 &&
            afterTwo.ids[0] === "toast-1" &&
            afterTwo.ids[1] === "toast-2" &&
            afterButton.ids.includes("toast-1") === false &&
            afterAuto.count === 0;

          interactionResults.push({
            name: "solid-toast",
            ok,
            details: { afterTwo, afterButton, afterAuto },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-toast",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-combobox") {
      let step = "init";
      try {
        const input = page.locator("#combobox-input");
        const after = page.locator("#combobox-after");
        if (!(await input.count()) || !(await after.count())) {
          interactionResults.push({
            name: "solid-combobox",
            ok: false,
            details: { reason: "missing combobox input/after" },
          });
        } else {
          step = "type 't'";
          await input.fill("t", { timeout: timeoutMs });
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);

          const afterType = await page.evaluate(() => ({
            expanded: document
              .querySelector("#combobox-input")
              ?.getAttribute("aria-expanded") ?? null,
            activeDescendant: document
              .querySelector("#combobox-input")
              ?.getAttribute("aria-activedescendant") ?? null,
            optionsCount: document.querySelectorAll(
              "#combobox-listbox [role=option]",
            ).length,
            activeElId:
              document.querySelector("#combobox-listbox [data-active=true]")?.id ??
              null,
            anchorWidth:
              document.querySelector("#combobox-control")?.getBoundingClientRect()
                ?.width ?? null,
            listboxWidth:
              document.querySelector("#combobox-listbox")?.getBoundingClientRect()
                ?.width ?? null,
          }));

          step = "ArrowDown once";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(40);
          const afterDown1 = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#combobox-input")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#combobox-listbox [data-active=true]")?.id ??
              null,
          }));

          step = "ArrowDown twice";
          await page.keyboard.press("ArrowDown");
          await page.waitForTimeout(40);
          const afterDown2 = await page.evaluate(() => ({
            activeDescendant: document
              .querySelector("#combobox-input")
              ?.getAttribute("aria-activedescendant") ?? null,
            activeElId:
              document.querySelector("#combobox-listbox [data-active=true]")?.id ??
              null,
          }));

          step = "Enter to select";
          await page.keyboard.press("Enter");
          step = "wait closed after select";
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterSelect = await page.evaluate(() => ({
            status: document.querySelector("#combobox-status")?.textContent ?? null,
            inputValue: document.querySelector("#combobox-input")?.value ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Escape while closed clears input.
          step = "Escape clears when closed";
          await page.keyboard.press("Escape");
          await page.waitForTimeout(30);
          const afterEscapeClosed = await page.evaluate(() => ({
            inputValue: document.querySelector("#combobox-input")?.value ?? null,
          }));

          // If the list is open and filtering results in an empty collection,
          // the default combobox closes and resets the input back to selection.
          step = "open then empty closes and resets";
          await input.fill("t", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") != null,
            { timeout: timeoutMs },
          );
          await input.fill("zzz", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterEmptyQuery = await page.evaluate(() => ({
            listboxOpen: document.querySelector("#combobox-listbox") != null,
            inputValue: document.querySelector("#combobox-input")?.value ?? null,
            status: document.querySelector("#combobox-status")?.textContent ?? null,
          }));

          // Tab while open closes and allows navigation to next element.
          step = "open and tab";
          await input.fill("t", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") != null,
            { timeout: timeoutMs },
          );
          await page.keyboard.press("Tab");
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") == null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => document.activeElement?.id === "combobox-after",
            { timeout: timeoutMs },
          );
          const afterTab = await page.evaluate(() => ({
            status: document.querySelector("#combobox-status")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Keep-open-on-empty combobox should stay open and show an empty state.
          step = "empty-state combobox opens";
          const emptyInput = page.locator("#combobox-input-empty");
          await emptyInput.fill("zzz", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox-empty") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const emptyStateOpen = await page.evaluate(() => ({
            emptyText:
              document.querySelector("#combobox-listbox-empty [data-empty]")?.textContent ??
              null,
            expanded: document
              .querySelector("#combobox-input-empty")
              ?.getAttribute("aria-expanded") ?? null,
            optionsCount: document.querySelectorAll(
              "#combobox-listbox-empty [role=option]",
            ).length,
            anchorWidth:
              document.querySelector("#combobox-control-empty")?.getBoundingClientRect()
                ?.width ?? null,
            listboxWidth:
              document.querySelector("#combobox-listbox-empty")?.getBoundingClientRect()
                ?.width ?? null,
          }));

          // Programmatic blur should close and reset.
          step = "empty-state blur closes";
          await page.evaluate(() => {
            const btn = document.querySelector("#combobox-after");
            // @ts-ignore
            btn?.focus?.();
          });
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox-empty") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const emptyStateAfterBlur = await page.evaluate(() => ({
            status:
              document.querySelector("#combobox-status-empty")?.textContent ?? null,
            inputValue: document.querySelector("#combobox-input-empty")?.value ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          const ok =
            afterType.expanded === "true" &&
            afterType.optionsCount >= 1 &&
            typeof afterType.activeDescendant === "string" &&
            afterType.activeDescendant === afterType.activeElId &&
            typeof afterType.anchorWidth === "number" &&
            typeof afterType.listboxWidth === "number" &&
            Math.abs(afterType.anchorWidth - afterType.listboxWidth) <= 2.5 &&
            typeof afterDown1.activeDescendant === "string" &&
            afterDown1.activeDescendant === afterDown1.activeElId &&
            afterDown1.activeDescendant !== afterType.activeDescendant &&
            typeof afterDown2.activeDescendant === "string" &&
            afterDown2.activeDescendant === afterDown2.activeElId &&
            afterDown2.activeDescendant !== afterDown1.activeDescendant &&
            (afterSelect.status ?? "").includes("Last: select") &&
            (afterSelect.inputValue ?? "").length > 0 &&
            afterSelect.activeId === "combobox-input" &&
            afterEscapeClosed.inputValue === "" &&
            afterEmptyQuery.listboxOpen === false &&
            (afterEmptyQuery.inputValue ?? "").includes("Dart") &&
            (afterEmptyQuery.status ?? "").includes("Last: empty") &&
            (afterTab.status ?? "").includes("Last: tab") &&
            afterTab.activeId === "combobox-after" &&
            emptyStateOpen.expanded === "true" &&
            emptyStateOpen.optionsCount === 0 &&
            (emptyStateOpen.emptyText ?? "").includes("No matches.") &&
            typeof emptyStateOpen.anchorWidth === "number" &&
            typeof emptyStateOpen.listboxWidth === "number" &&
            Math.abs(emptyStateOpen.anchorWidth - emptyStateOpen.listboxWidth) <= 2.5 &&
            ((emptyStateAfterBlur.status ?? "").includes("Last: blur") ||
              (emptyStateAfterBlur.status ?? "").includes("Last: focus-outside")) &&
            emptyStateAfterBlur.inputValue === "" &&
            emptyStateAfterBlur.activeId === "combobox-after";

          interactionResults.push({
            name: "solid-combobox",
            ok,
            details: {
              afterType,
              afterDown1,
              afterDown2,
              afterSelect,
              afterEscapeClosed,
              afterEmptyQuery,
              afterTab,
              emptyStateOpen,
              emptyStateAfterBlur,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-combobox",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-combobox-arrow-integration") {
      let step = "init";
      try {
        const input = page.locator("#combobox-input-arrow");
        if (!(await input.count())) {
          interactionResults.push({
            name: "solid-combobox-arrow-integration",
            ok: false,
            details: { reason: "missing #combobox-input-arrow" },
          });
        } else {
          step = "type 'e'";
          await input.fill("e", { timeout: timeoutMs });

          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox-arrow") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () =>
              document
                .querySelector("#combobox-listbox-arrow")
                ?.getAttribute("data-solid-placement") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const lb = document.querySelector("#combobox-listbox-arrow");
            if (!lb) return null;
            const arrow = lb.querySelector("[data-solid-popper-arrow]");
            const placement = lb.getAttribute("data-solid-placement") ?? "";
            const base = String(placement).split("-")[0] ?? "";
            return {
              placement,
              base,
              transform: getComputedStyle(lb).transform,
              arrow: arrow
                ? {
                    exists: true,
                    baseValue:
                      // @ts-ignore
                      typeof arrow.style?.[base] === "string"
                        ? // @ts-ignore
                          arrow.style[base]
                        : null,
                  }
                : { exists: false, baseValue: null },
            };
          });

          const ok =
            metrics != null &&
            typeof metrics.placement === "string" &&
            metrics.placement.length > 0 &&
            typeof metrics.base === "string" &&
            metrics.base.length > 0 &&
            typeof metrics.transform === "string" &&
            metrics.transform !== "" &&
            metrics.transform !== "none" &&
            metrics.arrow?.exists === true &&
            metrics.arrow?.baseValue === "100%";

          step = "escape closes";
          await page.keyboard.press("Escape");
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox-arrow") == null,
            { timeout: timeoutMs },
          );

          interactionResults.push({
            name: "solid-combobox-arrow-integration",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-combobox-arrow-integration",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-combobox-fitviewport") {
      let step = "init";
      try {
        const input = page.locator("#combobox-input");
        if (!(await input.count())) {
          interactionResults.push({
            name: "solid-combobox-fitviewport",
            ok: false,
            details: { reason: "missing #combobox-input" },
          });
        } else {
          step = "set small viewport";
          await page.setViewportSize({ width: 560, height: 240 });
          await page.waitForTimeout(50);

          step = "open list";
          await input.focus({ timeout: timeoutMs });
          await page.keyboard.press("Alt+ArrowDown");
          step = "wait listbox open";
          await page.waitForFunction(
            () => document.querySelector("#combobox-listbox") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(() => {
            const el = document.querySelector("#combobox-listbox");
            if (!el) return false;
            const mh = getComputedStyle(el).maxHeight;
            return mh && mh !== "none";
          });
          await page.waitForTimeout(80);

          const metrics = await page.evaluate(() => {
            const el = document.querySelector("#combobox-listbox");
            if (!el) return null;
            const rect = el.getBoundingClientRect();
            const cs = getComputedStyle(el);
            const maxHeight = cs.maxHeight;
            const maxHeightPx = Number.parseFloat(maxHeight || "0") || 0;
            const beforeScrollTop = el.scrollTop;
            el.scrollTop = 9999;
            const afterScrollTop = el.scrollTop;
            return {
              vw: window.innerWidth,
              vh: window.innerHeight,
              rect: {
                left: Math.round(rect.left),
                right: Math.round(rect.right),
                top: Math.round(rect.top),
                bottom: Math.round(rect.bottom),
                width: Math.round(rect.width),
                height: Math.round(rect.height),
              },
              clientHeight: el.clientHeight,
              scrollHeight: el.scrollHeight,
              overflowY: cs.overflowY,
              maxHeight,
              maxHeightPx,
              beforeScrollTop,
              afterScrollTop,
            };
          });

          const ok =
            metrics != null &&
            metrics.maxHeightPx > 0 &&
            metrics.overflowY !== "visible" &&
            metrics.rect.top >= 6 &&
            metrics.rect.bottom <= metrics.vh - 6 &&
            metrics.scrollHeight > metrics.clientHeight &&
            metrics.afterScrollTop > metrics.beforeScrollTop;

          interactionResults.push({
            name: "solid-combobox-fitviewport",
            ok,
            details: { metrics },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-combobox-fitviewport",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-menu") {
      let step = "init";
      try {
        const trigger = page.locator("#menu-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-menu",
            ok: false,
            details: { reason: "missing #menu-trigger" },
          });
        } else {
          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait open";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(50);

          // Touch outside should defer dismissal to click.
          step = "touch dismiss (evaluate)";
          const touchDismiss = await page.evaluate(() => {
            const menu = document.querySelector("#menu-content");
            if (!menu) return { ok: false, reason: "menu missing" };
            const down = new PointerEvent("pointerdown", {
              bubbles: true,
              cancelable: true,
              pointerType: "touch",
              pointerId: 1,
              isPrimary: true,
              clientX: 2,
              clientY: 2,
            });
            document.body.dispatchEvent(down);
            const stillOpenAfterDown = document.querySelector("#menu-content") != null;

            const click = new MouseEvent("click", { bubbles: true, cancelable: true });
            document.body.dispatchEvent(click);
            return { ok: true, stillOpenAfterDown };
          });
          step = "wait closed after touch click";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") == null,
            { timeout: timeoutMs },
          );

          // Reopen for keyboard tests.
          step = "reopen";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait reopen";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );

          step = "ArrowDown";
          const initialFocus = await page.evaluate(() => document.activeElement?.id ?? "");
          await page.keyboard.press("ArrowDown");
          const afterDown = await page.evaluate(() => document.activeElement?.id ?? "");
          // Skip disabled item on navigation.
          step = "ArrowDown (skip disabled)";
          await page.keyboard.press("ArrowDown");
          const afterDown2 = await page.evaluate(() => document.activeElement?.id ?? "");
          step = "End";
          await page.keyboard.press("End");
          const afterEnd = await page.evaluate(() => document.activeElement?.id ?? "");

          // Enter should activate the focused item (button click).
          step = "Enter";
          await page.keyboard.press("Enter");
          step = "wait closed after Enter";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(60);
          const afterEnter = await page.evaluate(() => ({
            status: document.querySelector("#menu-status")?.textContent ?? null,
            activeId: document.activeElement?.id ?? null,
          }));

          // Reopen and close via Escape to ensure dismiss path still works.
          step = "reopen for Escape";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait reopen for Escape";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );
          step = "Escape";
          await page.keyboard.press("Escape");
          step = "wait closed after Escape";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") == null,
            { timeout: timeoutMs },
          );
          const focusAfterClose = await page.evaluate(() => document.activeElement?.id ?? "");

          const ok =
            touchDismiss.ok === true &&
            touchDismiss.stillOpenAfterDown === true &&
            initialFocus === "menu-item-profile" &&
            afterDown === "menu-item-billing" &&
            afterDown2 === "menu-item-settings" &&
            afterEnd === "menu-item-logout" &&
            (afterEnter.status ?? "").includes("Action: Log out") &&
            (afterEnter.status ?? "").includes("Close: select") &&
            afterEnter.activeId === "menu-trigger" &&
            focusAfterClose === "menu-trigger";

          interactionResults.push({
            name: "solid-menu",
            ok,
            details: {
              touchDismiss,
              initialFocus,
              afterDown,
              afterDown2,
              afterEnd,
              afterEnter,
              focusAfterClose,
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-menu",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-menu-clickthrough") {
      let step = "init";
      try {
        const trigger = page.locator("#menu-trigger");
        const outside = page.locator("#menu-outside-action");
        if (!(await trigger.count()) || !(await outside.count())) {
          interactionResults.push({
            name: "solid-menu-clickthrough",
            ok: false,
            details: { reason: "missing menu trigger/outside action" },
          });
        } else {
          const readOutsideClicks = async () =>
            await page.evaluate(() => {
              const text =
                document.querySelector("#menu-status")?.textContent ?? "";
              const m = text.match(/Outside clicks:\s*(\d+)/);
              return { text, count: m ? Number(m[1]) : null };
            });

          const before = await readOutsideClicks();
          step = "open";
          await trigger.first().click({ timeout: timeoutMs });
          step = "wait menu";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );

          step = "click outside action (dismiss)";
          await outside.first().click({ timeout: timeoutMs });
          step = "wait closed";
          await page.waitForFunction(
            () => document.querySelector("#menu-content") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const afterDismiss = await readOutsideClicks();

          step = "click outside action again";
          await outside.first().click({ timeout: timeoutMs });
          await page.waitForTimeout(80);
          const afterClick = await readOutsideClicks();

          const ok =
            before.count != null &&
            afterDismiss.count === before.count &&
            afterClick.count === before.count + 1;

          interactionResults.push({
            name: "solid-menu-clickthrough",
            ok,
            details: { before, afterDismiss, afterClick },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-menu-clickthrough",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "solid-wordproc") {
      try {
        const result = await runSolidWordprocScenario(page, { timeoutMs, jitter });
        interactionResults.push(result);
      } catch (e) {
        interactionResults.push({
          name: "solid-wordproc",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-nesting") {
      try {
        const result = await runSolidNestingScenario(page, { timeoutMs, jitter });
        interactionResults.push(result);
      } catch (e) {
        interactionResults.push({
          name: "solid-nesting",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-toast-modal") {
      try {
        const result = await runSolidToastModalScenario(page, { timeoutMs, jitter });
        interactionResults.push(result);
      } catch (e) {
        interactionResults.push({
          name: "solid-toast-modal",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "solid-optionbuilder") {
      try {
        const result = await runSolidOptionBuilderScenario(page, { timeoutMs, jitter });
        interactionResults.push(result);
      } catch (e) {
        interactionResults.push({
          name: "solid-optionbuilder",
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
