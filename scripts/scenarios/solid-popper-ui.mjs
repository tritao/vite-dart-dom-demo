export async function runSolidPopperUiScenario(page, { timeoutMs, scenario }) {
  const interactionResults = [];

    if (scenario === "solid-popover") {
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
    }

  return (
    interactionResults[0] ?? {
      name: scenario,
      ok: false,
      details: { reason: `unsupported scenario: ${scenario}` },
    }
  );
}

export const solidPopperUiScenarios = {
  "solid-popover": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover" }),
  "solid-popover-clickthrough": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-clickthrough" }),
  "solid-popover-position": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-position" }),
  "solid-popover-flip": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-flip" }),
  "solid-popover-flip-horizontal": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-flip-horizontal" }),
  "solid-popover-shift": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-shift" }),
  "solid-popover-resize": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-resize" }),
  "solid-popover-slide-overlap": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-slide-overlap" }),
  "solid-popover-hide-detached": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-hide-detached" }),
  "solid-popover-arrow": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-popover-arrow" }),
  "solid-tooltip": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-tooltip" }),
  "solid-tooltip-edge": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-tooltip-edge" }),
  "solid-tooltip-arrow": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-tooltip-arrow" }),
  "solid-tooltip-slide-overlap": (page, ctx) => runSolidPopperUiScenario(page, { ...ctx, scenario: "solid-tooltip-slide-overlap" }),
};
