export async function runDocsContextMenuScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="context-menu-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="context-menu-basic"]');
  const target = scope.locator(".card").first();
  await target.waitFor({ state: "visible", timeout: timeoutMs });

  await target.click({ button: "right" });
  const menu = page.locator('[role="menu"]').first();
  await menu.waitFor({ state: "visible", timeout: timeoutMs });

  await page.keyboard.press("Escape");
  await menu.waitFor({ state: "hidden", timeout: timeoutMs });
}
