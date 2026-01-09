export async function runDocsToastScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="toast-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="toast-basic"]');
  const btn = scope.locator("button").first();
  await btn.waitFor({ state: "visible", timeout: timeoutMs });

  await btn.click();
  const toast = page.locator('[role="status"]').first();
  await toast.waitFor({ state: "visible", timeout: timeoutMs });
}

