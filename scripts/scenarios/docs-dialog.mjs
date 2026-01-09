export async function runDocsDialogScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="dialog-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="dialog-basic"]');
  const open = scope.locator("button").first();
  await open.waitFor({ state: "visible", timeout: timeoutMs });

  await open.click();
  // Dialog content should appear in the portal.
  const dialog = page.locator('[role="dialog"]').first();
  await dialog.waitFor({ state: "visible", timeout: timeoutMs });

  await page.keyboard.press("Escape");
  await dialog.waitFor({ state: "hidden", timeout: timeoutMs });
}

