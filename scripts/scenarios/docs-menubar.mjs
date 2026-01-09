export async function runDocsMenubarScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="menubar-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="menubar-basic"]');
  await scope.waitFor({ state: "visible", timeout: timeoutMs });

  // Basic sanity: menubar should render at least one menubaritem.
  const item = scope.locator('[role="menubar"] [role="menuitem"]').first();
  await item.waitFor({ state: "visible", timeout: timeoutMs });
}

