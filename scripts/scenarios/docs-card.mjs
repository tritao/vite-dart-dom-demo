export async function runDocsCardScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="card-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="card-basic"]');
  await scope.waitFor({ state: "visible", timeout: timeoutMs });

  const card = scope.locator(".card").first();
  await card.waitFor({ state: "visible", timeout: timeoutMs });
}

