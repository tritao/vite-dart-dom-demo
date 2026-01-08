export async function runSolidDropdownmenuScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const trigger = page.locator("#menu-trigger");
    if (!(await trigger.count())) {
      interactionResults.push({
        name: "solid-dropdownmenu",
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
        name: "solid-dropdownmenu",
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
      name: "solid-dropdownmenu",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-dropdownmenu",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidDropdownmenuClickthroughScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const trigger = page.locator("#menu-trigger");
    const outside = page.locator("#menu-outside-action");
    if (!(await trigger.count()) || !(await outside.count())) {
      interactionResults.push({
        name: "solid-dropdownmenu-clickthrough",
        ok: false,
        details: { reason: "missing menu trigger/outside action" },
      });
    } else {
      const readOutsideClicks = async () =>
        await page.evaluate(() => {
          const text = document.querySelector("#menu-status")?.textContent ?? "";
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
        name: "solid-dropdownmenu-clickthrough",
        ok,
        details: { before, afterDismiss, afterClick },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-dropdownmenu-clickthrough",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-dropdownmenu-clickthrough",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidDropdownmenuSubmenuScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const trigger = page.locator("#menu-trigger");
    if (!(await trigger.count())) {
      interactionResults.push({
        name: "solid-dropdownmenu-submenu",
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

      // Hover open.
      step = "hover sub trigger";
      await page.locator("#menu-item-more").hover({ timeout: timeoutMs });
      step = "wait submenu open";
      await page.waitForFunction(
        () => document.querySelector("#menu-sub-content") != null,
        { timeout: timeoutMs },
      );

      // Move mouse into submenu and ensure it stays open.
      step = "move mouse into submenu";
      const rects = await page.evaluate(() => {
        const trigger = document.querySelector("#menu-item-more");
        const sub = document.querySelector("#menu-sub-content");
        if (!trigger || !sub) return null;
        const a = trigger.getBoundingClientRect();
        const b = sub.getBoundingClientRect();
        return {
          ax: a.left + a.width / 2,
          ay: a.top + a.height / 2,
          bx: b.left + 12,
          by: b.top + 12,
        };
      });
      if (rects) {
        await page.mouse.move(rects.ax, rects.ay);
        await page.mouse.move(rects.bx, rects.by);
      }
      const stillOpenAfterMove = await page.evaluate(
        () => document.querySelector("#menu-sub-content") != null,
      );

      // Checkbox in submenu should toggle without closing.
      step = "toggle submenu checkbox";
      const beforeChecked = await page.evaluate(
        () =>
          document
            .querySelector("#menu-sub-beta")
            ?.getAttribute("aria-checked") ?? null,
      );
      await page.locator("#menu-sub-beta").click({ timeout: timeoutMs });
      await page.waitForTimeout(50);
      const afterChecked = await page.evaluate(
        () =>
          document
            .querySelector("#menu-sub-beta")
            ?.getAttribute("aria-checked") ?? null,
      );
      const submenuStillOpenAfterToggle = await page.evaluate(
        () => document.querySelector("#menu-sub-content") != null,
      );

      // Focusing the trigger should not close the submenu (Kobalte behavior).
      step = "focus trigger while submenu open";
      await page.evaluate(() => {
        document.querySelector("#menu-item-more")?.focus?.();
      });
      await page.waitForTimeout(50);
      const submenuStillOpenAfterTriggerFocus = await page.evaluate(
        () => document.querySelector("#menu-sub-content") != null,
      );

      // Reset for keyboard-only open/close test.
      step = "close root (Escape)";
      await page.keyboard.press("Escape");
      await page.waitForFunction(
        () => document.querySelector("#menu-content") == null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      step = "reopen";
      await trigger.first().click({ timeout: timeoutMs });
      await page.waitForFunction(
        () => document.querySelector("#menu-content") != null,
        { timeout: timeoutMs },
      );

      // Keyboard open/close: ArrowRight opens, ArrowLeft closes and returns focus.
      step = "keyboard nav to sub trigger";
      // Ensure menu has focus for keyboard navigation.
      await page.locator("#menu-content").focus();
      for (let i = 0; i < 30; i++) {
        const id = await page.evaluate(() => document.activeElement?.id ?? "");
        if (id === "menu-item-more") break;
        await page.keyboard.press("ArrowDown");
      }

      const activeBeforeOpen = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "ArrowRight open submenu";
      await page.keyboard.press("ArrowRight");
      await page.waitForFunction(
        () => document.querySelector("#menu-sub-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const activeInSubmenu = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "ArrowLeft close submenu";
      await page.keyboard.press("ArrowLeft");
      await page.waitForFunction(
        () => document.querySelector("#menu-sub-content") == null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const activeAfterClose = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      const ok =
        stillOpenAfterMove === true &&
        submenuStillOpenAfterToggle === true &&
        submenuStillOpenAfterTriggerFocus === true &&
        beforeChecked !== afterChecked &&
        activeBeforeOpen === "menu-item-more" &&
        activeInSubmenu === "menu-sub-invite" &&
        activeAfterClose === "menu-item-more";

      interactionResults.push({
        name: "solid-dropdownmenu-submenu",
        ok,
        details: {
          stillOpenAfterMove,
          beforeChecked,
          afterChecked,
          submenuStillOpenAfterToggle,
          submenuStillOpenAfterTriggerFocus,
          activeBeforeOpen,
          activeInSubmenu,
          activeAfterClose,
        },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-dropdownmenu-submenu",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-dropdownmenu-submenu",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidMenubarScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const fileTrigger = page.locator("#menubar-file-trigger");
    const editTrigger = page.locator("#menubar-edit-trigger");
    const viewTrigger = page.locator("#menubar-view-trigger");
    const outside = page.locator("#menubar-outside-action");

    if (
      !(await fileTrigger.count()) ||
      !(await editTrigger.count()) ||
      !(await viewTrigger.count())
    ) {
      interactionResults.push({
        name: "solid-menubar",
        ok: false,
        details: { reason: "missing menubar triggers" },
      });
    } else {
      step = "tab into menubar";
      await page.keyboard.press("Tab");
      await page.waitForTimeout(50);

      step = "open File menu via Enter";
      await fileTrigger.first().focus();
      await page.keyboard.press("Enter");
      await page.waitForFunction(
        () => document.querySelector("#menubar-file-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const focusedAfterOpen = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "ArrowRight switches to Edit";
      await page.keyboard.press("ArrowRight");
      await page.waitForFunction(
        () => document.querySelector("#menubar-edit-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const focusedAfterEdit = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "ArrowRight switches to View";
      await page.keyboard.press("ArrowRight");
      await page.waitForFunction(
        () => document.querySelector("#menubar-view-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const focusedAfterView = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "Escape closes and restores trigger focus";
      await page.keyboard.press("Escape");
      await page.waitForFunction(
        () => document.querySelector("#menubar-view-content") == null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const focusAfterEscape = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      // Click-through prevention: the first click should dismiss without activating.
      step = "open File menu via click";
      await fileTrigger.first().click({ timeout: timeoutMs });
      await page.waitForFunction(
        () => document.querySelector("#menubar-file-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);

      step = "outside click dismiss without increment";
      await outside.first().click({ timeout: timeoutMs });
      await page.waitForFunction(
        () => document.querySelector("#menubar-file-content") == null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(80);
      const outsideAfterDismiss = await page.evaluate(
        () => document.querySelector("#menubar-status")?.textContent ?? "",
      );

      step = "second click increments";
      await outside.first().click({ timeout: timeoutMs });
      await page.waitForTimeout(80);
      const outsideAfterClick = await page.evaluate(
        () => document.querySelector("#menubar-status")?.textContent ?? "",
      );

      // Hover switching: when open, hovering another trigger should open it.
      step = "open File then hover Edit";
      await fileTrigger.first().click({ timeout: timeoutMs });
      await page.waitForFunction(
        () => document.querySelector("#menubar-file-content") != null,
        { timeout: timeoutMs },
      );
      await editTrigger.first().hover({ timeout: timeoutMs });
      await page.waitForFunction(
        () => document.querySelector("#menubar-edit-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);
      const focusedAfterHoverSwitch = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      // Cleanup.
      step = "close via Escape";
      await page.keyboard.press("Escape");
      await page.waitForFunction(
        () => document.querySelector("#menubar-edit-content") == null,
        { timeout: timeoutMs },
      );

      const ok =
        focusedAfterOpen === "menubar-file-new" &&
        focusedAfterEdit === "menubar-edit-cut" &&
        focusedAfterView === "menubar-view-theme-light" &&
        focusAfterEscape === "menubar-view-trigger" &&
        /Outside clicks: 0/.test(outsideAfterDismiss) &&
        /Outside clicks: 1/.test(outsideAfterClick) &&
        focusedAfterHoverSwitch === "menubar-edit-cut";

      interactionResults.push({
        name: "solid-menubar",
        ok,
        details: {
          focusedAfterOpen,
          focusedAfterEdit,
          focusedAfterView,
          focusAfterEscape,
          outsideAfterDismiss,
          outsideAfterClick,
          focusedAfterHoverSwitch,
        },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-menubar",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-menubar",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidTabsScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const account = page.locator("#tabs-account");
    const password = page.locator("#tabs-password");
    const billing = page.locator("#tabs-billing");

    const autoBtn = page.locator("#tabs-activation-automatic");
    const manualBtn = page.locator("#tabs-activation-manual");
    const horizBtn = page.locator("#tabs-orientation-horizontal");
    const vertBtn = page.locator("#tabs-orientation-vertical");

    if (
      !(await account.count()) ||
      !(await password.count()) ||
      !(await billing.count())
    ) {
      interactionResults.push({
        name: "solid-tabs",
        ok: false,
        details: { reason: "missing tab triggers" },
      });
    } else {
      const read = async () =>
        await page.evaluate(() => {
          const value = document.querySelector("#tabs-status")?.textContent ?? "";
          const selected = Array.from(document.querySelectorAll('[role="tab"]'))
            .filter((n) => n.getAttribute("aria-selected") === "true")
            .map((n) => n.id);
          const focused = document.activeElement?.id ?? "";
          const visiblePanels = Array.from(document.querySelectorAll('[role="tabpanel"]'))
            .filter((p) => !p.hasAttribute("hidden"))
            .map((p) => p.id);
          return { value, selected, focused, visiblePanels };
        });

      step = "ensure default automatic + account selected";
      const initial = await read();

      step = "focus account tab";
      await account.first().focus();
      await page.waitForTimeout(50);

      step = "automatic activation: ArrowRight selects password";
      await autoBtn.first().click({ timeout: timeoutMs });
      await account.first().focus();
      await page.waitForTimeout(30);
      await page.keyboard.press("ArrowRight");
      await page.waitForTimeout(80);
      const afterAutoRight = await read();

      step = "automatic activation: ArrowRight skips disabled + wraps to account";
      await page.keyboard.press("ArrowRight");
      await page.waitForTimeout(80);
      const afterAutoWrap = await read();

      step = "manual activation: ArrowRight moves focus only";
      await manualBtn.first().click({ timeout: timeoutMs });
      await account.first().focus();
      await page.waitForTimeout(50);
      await page.keyboard.press("ArrowRight");
      await page.waitForTimeout(80);
      const afterManualFocus = await read();

      step = "manual activation: Enter selects focused password";
      await page.keyboard.press("Enter");
      await page.waitForTimeout(80);
      const afterManualSelect = await read();

      step = "Tab moves into panel input";
      await page.keyboard.press("Tab");
      await page.waitForTimeout(80);
      const focusedAfterTab = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      step = "vertical orientation: ArrowDown navigates";
      await vertBtn.first().click({ timeout: timeoutMs });
      await account.first().focus();
      await page.waitForTimeout(50);
      await page.keyboard.press("ArrowDown");
      await page.waitForTimeout(80);
      const afterVertical = await read();

      // Restore horizontal to avoid coupling with later runs.
      await horizBtn.first().click({ timeout: timeoutMs });

      const ok =
        initial.selected.includes("tabs-account") &&
        afterAutoRight.selected.includes("tabs-password") &&
        afterAutoRight.visiblePanels.some((id) =>
          id.includes("tabs-panel-password"),
        ) &&
        afterAutoWrap.selected.includes("tabs-account") &&
        afterManualFocus.focused === "tabs-password" &&
        afterManualFocus.selected.includes("tabs-account") &&
        afterManualSelect.selected.includes("tabs-password") &&
        focusedAfterTab === "tabs-panel-password-input" &&
        afterVertical.focused === "tabs-password";

      interactionResults.push({
        name: "solid-tabs",
        ok,
        details: {
          initial,
          afterAutoRight,
          afterAutoWrap,
          afterManualFocus,
          afterManualSelect,
          focusedAfterTab,
          afterVertical,
        },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-tabs",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-tabs",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidAccordionScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const a = page.locator("#accordion-trigger-a");
    const b = page.locator("#accordion-trigger-b");
    const c = page.locator("#accordion-trigger-c");

    const single = page.locator("#accordion-mode-single");
    const multi = page.locator("#accordion-mode-multiple");

    if (!(await a.count()) || !(await b.count()) || !(await c.count())) {
      interactionResults.push({
        name: "solid-accordion",
        ok: false,
        details: { reason: "missing accordion triggers" },
      });
    } else {
      const read = async () =>
        await page.evaluate(() => {
          const expanded = Array.from(document.querySelectorAll(".accordionItem"))
            .filter((el) => el.getAttribute("data-state") === "open")
            .map((el) => el.querySelector("button")?.id ?? "");
          const focused = document.activeElement?.id ?? "";
          const status = document.querySelector("#accordion-status")?.textContent ?? "";
          const panelAHidden =
            document.querySelector("#accordion-panel-a")?.hasAttribute("hidden") ??
            null;
          const panelBHidden =
            document.querySelector("#accordion-panel-b")?.hasAttribute("hidden") ??
            null;
          return { expanded, focused, status, panelAHidden, panelBHidden };
        });

      step = "single mode default has A expanded";
      await single.first().click({ timeout: timeoutMs });
      await page.waitForTimeout(50);
      const initial = await read();

      step = "ArrowDown moves focus to B";
      await a.first().focus();
      await page.keyboard.press("ArrowDown");
      await page.waitForTimeout(80);
      const afterDown = await read();

      step = "Enter opens B and closes A (single)";
      await page.keyboard.press("Enter");
      await page.waitForTimeout(80);
      const afterEnter = await read();

      step = "ArrowDown skips disabled C and wraps to A";
      await page.keyboard.press("ArrowDown");
      await page.waitForTimeout(80);
      const afterSkip = await read();

      step = "multiple mode allows A and B expanded";
      await multi.first().click({ timeout: timeoutMs });
      await page.waitForTimeout(50);
      await a.first().focus();
      await page.keyboard.press("Enter"); // toggle A open
      await page.waitForTimeout(80);
      const afterMulti = await read();

      step = "Tab moves into open panel content";
      await page.keyboard.press("Tab");
      await page.waitForTimeout(80);
      const focusedAfterTab = await page.evaluate(
        () => document.activeElement?.id ?? "",
      );

      const ok =
        initial.panelAHidden === false &&
        afterDown.focused === "accordion-trigger-b" &&
        afterEnter.panelAHidden === true &&
        afterEnter.panelBHidden === false &&
        afterSkip.focused === "accordion-trigger-a" &&
        afterMulti.expanded.includes("accordion-trigger-a") &&
        afterMulti.expanded.includes("accordion-trigger-b") &&
        (focusedAfterTab === "accordion-panel-a-input" ||
          focusedAfterTab === "accordion-panel-b-input");

      interactionResults.push({
        name: "solid-accordion",
        ok,
        details: {
          initial,
          afterDown,
          afterEnter,
          afterSkip,
          afterMulti,
          focusedAfterTab,
        },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-accordion",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-accordion",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export async function runSolidContextmenuScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const target = page.locator("#contextmenu-target");
    if (!(await target.count())) {
      interactionResults.push({
        name: "solid-contextmenu",
        ok: false,
        details: { reason: "missing #contextmenu-target" },
      });
    } else {
      // Focus the target so we can assert focus restoration.
      step = "focus target";
      await target.first().focus();

      // Open via right click.
      step = "open via contextmenu";
      await target.first().click({
        button: "right",
        position: { x: 60, y: 50 },
        timeout: timeoutMs,
      });
      step = "wait open";
      await page.waitForFunction(
        () => document.querySelector("#contextmenu-content") != null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(50);

      // Click an item to close.
      step = "select";
      await page.locator("#contextmenu-item-copy").click({ timeout: timeoutMs });
      step = "wait closed";
      await page.waitForFunction(
        () => document.querySelector("#contextmenu-content") == null,
        { timeout: timeoutMs },
      );
      await page.waitForTimeout(80);

      const afterSelect = await page.evaluate(() => ({
        status: document.querySelector("#contextmenu-status")?.textContent ?? null,
        activeId: document.activeElement?.id ?? null,
      }));

      const ok =
        (afterSelect.status ?? "").includes("Copy") &&
        afterSelect.activeId === "contextmenu-target";

      interactionResults.push({
        name: "solid-contextmenu",
        ok,
        details: { afterSelect },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "solid-contextmenu",
      ok: false,
      details: { error: String(e), step },
    });
  }
  return (
    interactionResults[0] ?? {
      name: "solid-contextmenu",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export const solidMenuUiScenarios = {
  "solid-dropdownmenu": runSolidDropdownmenuScenario,
  "solid-dropdownmenu-clickthrough": runSolidDropdownmenuClickthroughScenario,
  "solid-dropdownmenu-submenu": runSolidDropdownmenuSubmenuScenario,
  "solid-menubar": runSolidMenubarScenario,
  "solid-tabs": runSolidTabsScenario,
  "solid-accordion": runSolidAccordionScenario,
  "solid-contextmenu": runSolidContextmenuScenario,
};

