export async function runDocsTableScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="table-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="table-basic"]');
  await scope.waitFor({ state: "visible", timeout: timeoutMs });

  const table = scope.locator("table").first();
  await table.waitFor({ state: "visible", timeout: timeoutMs });
}

