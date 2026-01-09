export async function runDocsSpinnerScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const demoSel = '[data-doc-demo="spinner-basic"]';

  await page.waitForFunction((sel) => document.querySelector(sel) != null, demoSel, {
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    (sel) => document.querySelector(`${sel} .spinner[role="status"]`) != null,
    demoSel,
    { timeout: timeoutMs },
  );

  const info = await page.evaluate((sel) => {
    const el = document.querySelector(`${sel} .spinner[role="status"]`);
    return {
      role: el?.getAttribute("role") ?? null,
      live: el?.getAttribute("aria-live") ?? null,
      label: el?.getAttribute("aria-label") ?? null,
    };
  }, demoSel);

  if (info.role !== "status" || info.live !== "polite" || !info.label) {
    throw new Error(`Unexpected spinner semantics: ${JSON.stringify(info)}`);
  }
}

