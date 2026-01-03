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
      try {
        const trigger = page.locator("#overlay-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-overlay",
            ok: false,
            details: { reason: "missing #overlay-trigger" },
          });
        } else {
          const triggerHandle = await trigger.first().elementHandle();

          const bodyOverflowBefore = await page.evaluate(
            () => document.body?.style?.overflow ?? null,
          );

          await trigger.first().click({ timeout: timeoutMs });

          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") != null,
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => document.querySelector("#solid-portal-root") != null,
            { timeout: timeoutMs },
          );
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
          await page.keyboard.press("Tab");
          await page.waitForTimeout(100);
          const activeAfterTab = await page.evaluate(
            () => document.activeElement?.id ?? null,
          );

          // Escape should dismiss.
          await page.keyboard.press("Escape");
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
          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") != null,
            { timeout: timeoutMs },
          );
          await page.click("#overlay-backdrop", { timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#overlay-dialog") == null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(80);
          const statusText = (await page.locator("#overlay-status").textContent())?.trim() ?? "";

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
            statusText.includes("outside");

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
            },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-overlay",
          ok: false,
          details: { error: String(e) },
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
          await page.click("#dialog-nested-backdrop", { timeout: timeoutMs });
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
          await page.click("#dialog-backdrop", { timeout: timeoutMs });
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
              // @ts-ignore
              const left = el.style.left ?? "";
              // @ts-ignore
              const top = el.style.top ?? "";
              // @ts-ignore
              const pos = el.style.position ?? "";
              return { left, top, pos };
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
            typeof before.left === "string" &&
            typeof before.top === "string" &&
            before.left.endsWith("px") &&
            before.top.endsWith("px") &&
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
              panelStyleTop: // @ts-ignore
                panel.style.top ?? "",
              panelStyleLeft: // @ts-ignore
                panel.style.left ?? "",
            };
          });

          const ok =
            metrics != null &&
            typeof metrics.panelStyleTop === "string" &&
            metrics.panelStyleTop.endsWith("px") &&
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
            return {
              describedBy: trigger?.getAttribute("aria-describedby") ?? null,
              tooltipId: panel?.id ?? null,
              left,
              top,
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
            typeof afterHoverOpen.left === "string" &&
            typeof afterHoverOpen.top === "string" &&
            afterHoverOpen.left.endsWith("px") &&
            afterHoverOpen.top.endsWith("px");
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
          await page.waitForTimeout(400);
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
    } else if (scenario === "solid-menu") {
      try {
        const trigger = page.locator("#menu-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "solid-menu",
            ok: false,
            details: { reason: "missing #menu-trigger" },
          });
        } else {
          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );
          await page.waitForTimeout(50);

          // Touch outside should defer dismissal to click.
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
          await page.waitForFunction(
            () => document.querySelector("#menu-content") == null,
            { timeout: timeoutMs },
          );

          // Reopen for keyboard tests.
          await trigger.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#menu-content") != null,
            { timeout: timeoutMs },
          );

          const initialFocus = await page.evaluate(() => document.activeElement?.id ?? "");
          await page.keyboard.press("ArrowDown");
          const afterDown = await page.evaluate(() => document.activeElement?.id ?? "");
          await page.keyboard.press("End");
          const afterEnd = await page.evaluate(() => document.activeElement?.id ?? "");

          await page.keyboard.press("Escape");
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
            afterEnd === "menu-item-logout" &&
            focusAfterClose === "menu-trigger";

          interactionResults.push({
            name: "solid-menu",
            ok,
            details: { touchDismiss, initialFocus, afterDown, afterEnd, focusAfterClose },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "solid-menu",
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
