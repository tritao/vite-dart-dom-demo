export async function runDocsDropdownMenuScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="dropdown-menu-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="dropdown-menu-basic"]');
  const open = scope.locator("button").first();
  await open.waitFor({ state: "visible", timeout: timeoutMs });

  await open.click();
  const menu = page.locator('[role="menu"]').first();
  await menu.waitFor({ state: "visible", timeout: timeoutMs });

  await page.keyboard.press("Escape");
  await menu.waitFor({ state: "hidden", timeout: timeoutMs });
}

