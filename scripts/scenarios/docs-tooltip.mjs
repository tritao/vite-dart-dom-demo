export async function runDocsTooltipScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="tooltip-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="tooltip-basic"]');
  const trigger = scope.locator("button").first();
  await trigger.waitFor({ state: "visible", timeout: timeoutMs });

  await trigger.hover();
  const tooltip = page.locator('[role="tooltip"]').first();
  await tooltip.waitFor({ state: "visible", timeout: timeoutMs });
}

