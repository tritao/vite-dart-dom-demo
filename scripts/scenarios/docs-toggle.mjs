export async function runDocsToggleScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="toggle-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="toggle-basic"]');
  const btn = scope.locator("button").first();
  await btn.waitFor({ state: "visible", timeout: timeoutMs });

  const before = await btn.getAttribute("data-state");
  await btn.click();
  await page.waitForTimeout(50);
  const after = await btn.getAttribute("data-state");
  if (before === after) {
    throw new Error(`Expected toggle state to change (before=${before}, after=${after})`);
  }
}

