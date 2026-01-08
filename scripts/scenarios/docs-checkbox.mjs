export async function runDocsCheckboxScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="checkbox-basic"]') != null,
    { timeout: timeoutMs },
  );

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="checkbox-basic"] [role="checkbox"]') != null,
    { timeout: timeoutMs },
  );

  // Focus + toggle via Space/Enter.
  await page.locator('[data-doc-demo="checkbox-basic"] [role="checkbox"]').first().focus();
  await page.keyboard.press("Space");
  await page.waitForTimeout(50);
  const afterSpace = await page.evaluate(() =>
    document
      .querySelector('[data-doc-demo="checkbox-basic"] [role="checkbox"]')
      ?.getAttribute("aria-checked"),
  );

  await page.keyboard.press("Enter");
  await page.waitForTimeout(50);
  const afterEnter = await page.evaluate(() =>
    document
      .querySelector('[data-doc-demo="checkbox-basic"] [role="checkbox"]')
      ?.getAttribute("aria-checked"),
  );

  if (afterSpace !== "true" || afterEnter !== "false") {
    throw new Error(
      `Unexpected aria-checked toggling: afterSpace=${afterSpace}, afterEnter=${afterEnter}`,
    );
  }
}

