export async function runLabsSwitchScenario(page, { timeoutMs }) {
  const interactionResults = [];
  let step = "init";
  try {
    const sw = page.locator("#switch-control");
    const toggleDisabled = page.locator("#switch-disable-toggle");
    if (!(await sw.count()) || !(await toggleDisabled.count())) {
      interactionResults.push({
        name: "labs-switch",
        ok: false,
        details: { reason: "missing switch control or disable toggle" },
      });
    } else {
      const read = async () =>
        await page.evaluate(() => {
          const el = document.querySelector("#switch-control");
          const status = document.querySelector("#switch-status")?.textContent ?? "";
          return {
            status,
            ariaChecked: el?.getAttribute("aria-checked") ?? null,
            disabled: el?.hasAttribute("disabled") ?? null,
            dataState: el?.getAttribute("data-state") ?? null,
          };
        });

      const initial = await read();

      step = "click toggles on";
      await sw.first().click({ timeout: timeoutMs });
      await page.waitForTimeout(80);
      const afterClick = await read();

      step = "keyboard toggles off";
      await sw.first().focus();
      await page.keyboard.press("Space");
      await page.waitForTimeout(80);
      const afterSpace = await read();

      step = "disable";
      await toggleDisabled.first().click({ timeout: timeoutMs });
      await page.waitForTimeout(80);
      const afterDisable = await read();

      step = "click does not toggle when disabled";
      await page.evaluate(() => {
        document.querySelector("#switch-control")?.click?.();
      });
      await page.waitForTimeout(80);
      const afterDisabledClick = await read();

      step = "keyboard does not toggle when disabled";
      await page.evaluate(() => {
        document.querySelector("#switch-control")?.focus?.();
      });
      await page.keyboard.press("Enter");
      await page.waitForTimeout(80);
      const afterDisabledEnter = await read();

      const ok =
        initial.ariaChecked === "false" &&
        afterClick.ariaChecked === "true" &&
        afterSpace.ariaChecked === "false" &&
        afterDisable.disabled === true &&
        afterDisabledClick.ariaChecked === "false" &&
        afterDisabledEnter.ariaChecked === "false";

      interactionResults.push({
        name: "labs-switch",
        ok,
        details: {
          initial,
          afterClick,
          afterSpace,
          afterDisable,
          afterDisabledClick,
          afterDisabledEnter,
        },
      });
    }
  } catch (e) {
    interactionResults.push({
      name: "labs-switch",
      ok: false,
      details: { error: String(e), step },
    });
  }

  return (
    interactionResults[0] ?? {
      name: "labs-switch",
      ok: false,
      details: { reason: "no result" },
    }
  );
}

export const labsSwitchUiScenarios = {
  "labs-switch": runLabsSwitchScenario,
};
