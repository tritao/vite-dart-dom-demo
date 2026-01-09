export async function runDocsPopoverScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="popover-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="popover-basic"]');
  const open = scope.locator("button").first();
  await open.waitFor({ state: "visible", timeout: timeoutMs });

  await open.click();
  const popover = page.locator('#docs-popover-basic-portal [role="dialog"]').first();
  await popover.waitFor({ state: "visible", timeout: timeoutMs });

  // Close via the explicit close button.
  const close = page
    .locator('#docs-popover-basic-portal button:has-text("Close")')
    .first();
  await close.waitFor({ state: "visible", timeout: timeoutMs });
  await close.click();
  await popover.waitFor({ state: "hidden", timeout: timeoutMs });
}
