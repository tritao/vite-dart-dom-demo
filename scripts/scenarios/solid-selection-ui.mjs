export async function runSolidSelectionUiScenario(page, { timeoutMs, scenario }) {
  const interactionResults = [];

    if (scenario === "solid-select") {
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
            // sameWidth uses minWidth: listbox can be wider, but never narrower.
            afterOpen.listboxWidth + 0.5 >= afterOpen.triggerWidth &&
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
            (afterClickSelected.status ?? "").includes("Value: React") &&
            (afterClickSelected.triggerText ?? "").includes("React") &&
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
    }

  return (
    interactionResults[0] ?? {
      name: scenario,
      ok: false,
      details: { reason: `unsupported scenario: ${scenario}` },
    }
  );
}

export const solidSelectionUiScenarios = {
  "solid-select": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select" }),
  "solid-select-fitviewport": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select-fitviewport" }),
  "solid-select-flip": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select-flip" }),
  "solid-select-flip-horizontal": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select-flip-horizontal" }),
  "solid-select-slide-overlap": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select-slide-overlap" }),
  "solid-select-clickthrough": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-select-clickthrough" }),
  "solid-listbox": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-listbox" }),
  "solid-selection": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-selection" }),
  "solid-toast": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-toast" }),
  "solid-combobox": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-combobox" }),
  "solid-combobox-arrow-integration": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-combobox-arrow-integration" }),
  "solid-combobox-fitviewport": (page, ctx) => runSolidSelectionUiScenario(page, { ...ctx, scenario: "solid-combobox-fitviewport" }),
};
