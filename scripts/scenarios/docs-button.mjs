export async function runDocsButtonScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="button-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="button-basic"]');
  await scope.waitFor({ state: "visible", timeout: timeoutMs });

  const buttons = scope.locator("button");
  if ((await buttons.count()) < 1) {
    throw new Error("Expected at least one button in the demo");
  }
}

