export async function runDocsProgressScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const demoSel = '[data-doc-demo="progress-basic"]';

  await page.waitForFunction((sel) => document.querySelector(sel) != null, demoSel, {
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    (sel) => document.querySelectorAll(`${sel} [role="progressbar"]`).length >= 2,
    demoSel,
    { timeout: timeoutMs },
  );

  // Ensure determinate has aria-valuenow and indeterminate doesn't.
  const states = await page.evaluate((sel) => {
    const bars = [...document.querySelectorAll(`${sel} [role="progressbar"]`)];
    return bars.map((el) => ({
      state: el.getAttribute("data-state"),
      now: el.getAttribute("aria-valuenow"),
    }));
  }, demoSel);

  const determinate = states.find((s) => s.state === "determinate");
  const indeterminate = states.find((s) => s.state === "indeterminate");
  if (!determinate || determinate.now == null) {
    throw new Error(`Missing determinate aria-valuenow: ${JSON.stringify(states)}`);
  }
  if (!indeterminate || indeterminate.now != null) {
    throw new Error(`Indeterminate should omit aria-valuenow: ${JSON.stringify(states)}`);
  }

  // Toggle indeterminate and ensure the first bar flips.
  await page.locator(`${demoSel} button`, { hasText: "Toggle indeterminate" }).click();
  await page.waitForTimeout(50);

  const afterToggle = await page.evaluate((sel) => {
    const first = document.querySelector(`${sel} [role="progressbar"]`);
    return {
      state: first?.getAttribute("data-state") ?? null,
      now: first?.getAttribute("aria-valuenow"),
    };
  }, demoSel);

  if (afterToggle.state !== "indeterminate" || afterToggle.now != null) {
    throw new Error(`Toggle indeterminate failed: ${JSON.stringify(afterToggle)}`);
  }
}

