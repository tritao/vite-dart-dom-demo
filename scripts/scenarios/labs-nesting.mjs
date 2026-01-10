export async function runLabsNestingScenario(page, { timeoutMs, jitter }) {
  const root = page.locator("#nesting-root");
  const openDialog = page.locator("#nesting-dialog-trigger");
  if (!(await root.count()) || !(await openDialog.count())) {
    return {
      name: "labs-nesting",
      ok: false,
      details: { reason: "missing nesting root/trigger" },
    };
  }

  async function expectOpen(selectors) {
    for (const sel of selectors) {
      await page.waitForFunction(
        (s) => document.querySelector(s) != null,
        sel,
        { timeout: timeoutMs },
      );
    }
  }

  async function expectClosed(selectors) {
    for (const sel of selectors) {
      await page.waitForFunction(
        (s) => document.querySelector(s) == null,
        sel,
        { timeout: timeoutMs },
      );
    }
  }

  // Open all layers.
  await openDialog.first().click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-dialog-panel"]);

  await page.locator("#nesting-popover-trigger").click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-popover-panel"]);

  await page.locator("#nesting-menu-trigger").click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-menu-content"]);

  // Escape should dismiss topmost only (menu → popover → dialog).
  await page.keyboard.press("Escape");
  await jitter?.();
  await expectClosed(["#nesting-menu-content"]);
  await expectOpen(["#nesting-popover-panel", "#nesting-dialog-panel"]);
  const afterEscapeMenu = await page.locator("#nesting-status").textContent();

  await page.keyboard.press("Escape");
  await jitter?.();
  await expectClosed(["#nesting-popover-panel"]);
  await expectOpen(["#nesting-dialog-panel"]);
  const afterEscapePopover = await page.locator("#nesting-status").textContent();

  await page.keyboard.press("Escape");
  await jitter?.();
  await expectClosed(["#nesting-dialog-panel"]);
  const afterEscapeDialog = await page.locator("#nesting-status").textContent();

  // Outside click: clicking inside popover but outside menu closes only menu.
  await openDialog.first().click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-dialog-panel"]);
  await page.locator("#nesting-popover-trigger").click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-popover-panel"]);
  await page.locator("#nesting-menu-trigger").click({ timeout: timeoutMs });
  await jitter?.();
  await expectOpen(["#nesting-menu-content"]);

  await page.click("#nesting-popover-panel", {
    timeout: timeoutMs,
    position: { x: 5, y: 5 },
  });
  await jitter?.();
  await expectClosed(["#nesting-menu-content"]);
  await expectOpen(["#nesting-popover-panel", "#nesting-dialog-panel"]);
  const afterOutsideMenu = await page.locator("#nesting-status").textContent();

  // Clicking inside dialog but outside popover closes only popover.
  await page.click("#nesting-dialog-panel", {
    timeout: timeoutMs,
    position: { x: 5, y: 5 },
  });
  await jitter?.();
  await expectClosed(["#nesting-popover-panel"]);
  await expectOpen(["#nesting-dialog-panel"]);
  const afterOutsidePopover = await page.locator("#nesting-status").textContent();

  // Clicking dialog backdrop closes dialog.
  await page.click("#nesting-dialog-backdrop", {
    timeout: timeoutMs,
    position: { x: 5, y: 5 },
  });
  await jitter?.();
  await expectClosed(["#nesting-dialog-panel"]);
  const afterOutsideDialog = await page.locator("#nesting-status").textContent();

  const isOutsideReason = (text, prefix) =>
    (text ?? "").includes(`${prefix}:outside`) ||
    (text ?? "").includes(`${prefix}:focus-outside`);

  const ok =
    (afterEscapeMenu ?? "").includes("menu:escape") &&
    (afterEscapePopover ?? "").includes("popover:escape") &&
    (afterEscapeDialog ?? "").includes("dialog:escape") &&
    isOutsideReason(afterOutsideMenu, "menu") &&
    isOutsideReason(afterOutsidePopover, "popover") &&
    (afterOutsideDialog ?? "").includes("dialog:outside");

  return {
    name: "labs-nesting",
    ok,
    details: {
      afterEscapeMenu,
      afterEscapePopover,
      afterEscapeDialog,
      afterOutsideMenu,
      afterOutsidePopover,
      afterOutsideDialog,
    },
  };
}
