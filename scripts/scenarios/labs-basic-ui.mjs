export async function runLabsBasicUiScenario(page, { timeoutMs, scenario }) {
  const interactionResults = [];

    if (scenario === "docs-runtime-dom") {
      try {
        const mount = page.locator('[data-doc-demo="runtime-dom-basic"]');
        const list = mount.locator("ul.list");
        const add = mount.getByRole("button", { name: "Add item" });
        const clear = mount.getByRole("button", { name: "Clear" });
        const count = mount.locator("p.muted");

        await page.waitForFunction(() => {
          const mount = document.querySelector('[data-doc-demo="runtime-dom-basic"]');
          return !!mount;
        });

        await page.waitForFunction(() => {
          const items = document.querySelectorAll('[data-doc-demo="runtime-dom-basic"] ul.list li');
          return items.length === 2;
        });

        const initial = await list.locator("li").allTextContents();
        await add.click({ timeout: timeoutMs });
        await page.waitForFunction(() => {
          const items = document.querySelectorAll('[data-doc-demo="runtime-dom-basic"] ul.list li');
          return items.length === 3;
        });
        const afterAdd = await list.locator("li").allTextContents();

        await clear.click({ timeout: timeoutMs });
        await page.waitForFunction(() => {
          const items = document.querySelectorAll('[data-doc-demo="runtime-dom-basic"] ul.list li');
          return items.length === 0;
        });

        const countText = ((await count.first().textContent()) ?? "").trim();

        const ok =
          initial.join("|") === "Solid|React" &&
          afterAdd[2]?.includes("Item 3") &&
          /count=0\b/.test(countText);

        interactionResults.push({
          name: "docs-runtime-dom",
          ok,
          details: { initial, afterAdd, countText },
        });
      } catch (e) {
        interactionResults.push({
          name: "docs-runtime-dom",
          ok: false,
          details: { error: String(e) },
        });
      }
    }

    if (scenario === "labs-dom") {
      try {
        const inc = page.locator("#labs-inc");
        const count = page.locator("#labs-count");
        if (!(await inc.count()) || !(await count.count())) {
          interactionResults.push({
            name: "labs-dom",
            ok: false,
            details: { reason: "missing #labs-inc or #labs-count" },
          });
        } else {
          const incHandle = await inc.first().elementHandle();
          const readBindings = async () =>
            await page.evaluate(() => {
              const box = document.querySelector("#labs-box");
              const disabled = document.querySelector("#labs-disabled");
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
              const el = document.querySelector("#labs-count");
              const now = (el?.textContent ?? "").trim();
              return !!now && now !== prev;
            },
            { prev: before },
            { timeout: timeoutMs },
          );

          const after = (await count.first().textContent())?.trim() ?? "";

          const sameNode = incHandle
            ? await incHandle.evaluate(
                (el) => el === document.querySelector("#labs-inc"),
              )
            : false;

          const bindingsAfterInc = await readBindings();

          // Toggle Show and observe cleanup reflected in #labs-status.
          const status = page.locator("#labs-status");
          const toggle = page.locator("#labs-toggle");
          const initialStatus = (await status.first().textContent())?.trim() ?? "";
          const clicks = page.locator("#labs-doc-clicks");
          const clicksBefore = (await clicks.first().textContent())?.trim() ?? "";
          await toggle.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => (document.querySelector("#labs-extra") != null),
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => (document.querySelector("#labs-status")?.textContent ?? "").includes("yes"),
            { timeout: timeoutMs },
          );

          // Document click handler should be active while extra is mounted.
          await page.click("body");
          await page.waitForFunction(
            ({ before }) => {
              const t = document.querySelector("#labs-doc-clicks")?.textContent ?? "";
              return t.trim() !== before;
            },
            { before: clicksBefore },
            { timeout: timeoutMs },
          );
          const clicksDuring = (await clicks.first().textContent())?.trim() ?? "";

          await toggle.first().click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => (document.querySelector("#labs-extra") == null),
            { timeout: timeoutMs },
          );
          await page.waitForFunction(
            () => (document.querySelector("#labs-status")?.textContent ?? "").includes("no"),
            { timeout: timeoutMs },
          );
          const finalStatus = (await status.first().textContent())?.trim() ?? "";

          // After unmount, document click handler should be gone.
          const clicksAfterUnmountBefore = (await clicks.first().textContent())?.trim() ?? "";
          await page.click("body");
          await page.waitForTimeout(250);
          const clicksAfterUnmountAfter = (await clicks.first().textContent())?.trim() ?? "";

          // Keyed For: reverse list should preserve node identity for item 1.
          const item1 = page.locator("#labs-item-1");
          const item1Handle = await item1.first().elementHandle();
          const orderBefore = await page.evaluate(() => {
            const list = document.querySelector("#labs-list");
            const ids = [...(list?.querySelectorAll("[id^=labs-item-]") ?? [])].map(
              (e) => e.id,
            );
            return ids;
          });
          await page.locator("#labs-reorder").click({ timeout: timeoutMs });
          await page.waitForFunction(
            ({ before }) => {
              const list = document.querySelector("#labs-list");
              const ids = [...(list?.querySelectorAll("[id^=labs-item-]") ?? [])].map(
                (e) => e.id,
              );
              return ids.join(",") !== before.join(",");
            },
            { before: orderBefore },
            { timeout: timeoutMs },
          );
          const orderAfter = await page.evaluate(() => {
            const list = document.querySelector("#labs-list");
            const ids = [...(list?.querySelectorAll("[id^=labs-item-]") ?? [])].map(
              (e) => e.id,
            );
            return ids;
          });
          const item1Same = item1Handle
            ? await item1Handle.evaluate(
                (el) => el === document.querySelector("#labs-item-1"),
              )
            : false;

          // Portal: mount to body and clean up.
          await page.locator("#labs-portal-toggle").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#labs-portal") != null,
            { timeout: timeoutMs },
          );
          const portalInfo = await page.evaluate(() => {
            const portal = document.querySelector("#labs-portal");
            const root = document.querySelector("#labs-root");
            return {
              exists: !!portal,
              inRoot: root ? root.contains(portal) : null,
              inBody: document.body ? document.body.contains(portal) : null,
            };
          });
          await page.locator("#labs-portal-toggle").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#labs-portal") == null,
            { timeout: timeoutMs },
          );

          interactionResults.push({
            name: "labs-dom",
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
          name: "labs-dom",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "labs-for") {
      try {
        const item2 = page.locator("#labs-item-2");
        const disposed = page.locator("#labs-disposed");

        if (!(await item2.count()) || !(await disposed.count())) {
          interactionResults.push({
            name: "labs-for",
            ok: false,
            details: { reason: "missing #labs-item-2 or #labs-disposed" },
          });
        } else {
          const item2Handle = await item2.first().elementHandle();
          const disposedBefore = (await disposed.first().textContent())?.trim() ?? "";

          await page.locator("#labs-remove-2").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#labs-item-2") == null,
            { timeout: timeoutMs },
          );

          await page.waitForFunction(
            ({ before }) => {
              const t = document.querySelector("#labs-disposed")?.textContent ?? "";
              return t.trim() !== before;
            },
            { before: disposedBefore },
            { timeout: timeoutMs },
          );
          const disposedAfterRemove = (await disposed.first().textContent())?.trim() ?? "";

          await page.locator("#labs-add-2").click({ timeout: timeoutMs });
          await page.waitForFunction(
            () => document.querySelector("#labs-item-2") != null,
            { timeout: timeoutMs },
          );
          const item2NewSame = item2Handle
            ? await item2Handle.evaluate(
                (el) => el === document.querySelector("#labs-item-2"),
              )
            : false;

          const item1 = page.locator("#labs-item-1");
          const item1Handle = await item1.first().elementHandle();
          await page.locator("#labs-reorder").click({ timeout: timeoutMs });
          await page.waitForTimeout(250);
          const item1Same = item1Handle
            ? await item1Handle.evaluate(
                (el) => el === document.querySelector("#labs-item-1"),
              )
            : false;

          interactionResults.push({
            name: "labs-for",
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
          name: "labs-for",
          ok: false,
          details: { error: String(e) },
        });
      }
    } else if (scenario === "labs-overlay") {
      let step = "init";
      let hitBeforeOutside = null;
      try {
        const trigger = page.locator("#overlay-trigger");
        const under = page.locator("#overlay-under-button");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "labs-overlay",
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
            () => document.querySelector("#solidus-portal-root") != null,
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
              portalRootExists: document.querySelector("#solidus-portal-root") != null,
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
            name: "labs-overlay",
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
          name: "labs-overlay",
          ok: false,
          details: { error: String(e), step, hitBeforeOutside },
        });
      }
    } else if (scenario === "labs-dialog") {
      let step = "init";
      try {
        const trigger = page.locator("#dialog-trigger");
        if (!(await trigger.count())) {
          interactionResults.push({
            name: "labs-dialog",
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
            name: "labs-dialog",
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
          name: "labs-dialog",
          ok: false,
          details: { error: String(e), step },
        });
      }
    } else if (scenario === "labs-roving") {
      try {
        const toggle = page.locator("#roving-toggle");
        if (!(await toggle.count())) {
          interactionResults.push({
            name: "labs-roving",
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
            name: "labs-roving",
            ok,
            details: { before, afterRight, afterUnmount },
          });
        }
      } catch (e) {
        interactionResults.push({
          name: "labs-roving",
          ok: false,
          details: { error: String(e) },
        });
      }
    }

  return (
    interactionResults[0] ?? {
      name: scenario,
      ok: false,
      details: { reason: `unsupported scenario: ${scenario}` },
    }
  );
}

export const labsBasicUiScenarios = {
  "labs-dom": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "labs-dom" }),
  "labs-for": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "labs-for" }),
  "labs-overlay": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "labs-overlay" }),
  "labs-dialog": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "labs-dialog" }),
  "labs-roving": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "labs-roving" }),
  "docs-runtime-dom": (page, ctx) =>
    runLabsBasicUiScenario(page, { ...ctx, scenario: "docs-runtime-dom" }),
};
