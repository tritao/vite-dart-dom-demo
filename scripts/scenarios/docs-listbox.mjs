export async function runDocsListboxScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  // Ensure the docs page + demo mount is hydrated.
  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="listbox-basic"]') != null,
    { timeout: timeoutMs },
  );
  await page.waitForFunction(
    () => document.querySelector("#docs-listbox-basic") != null,
    { timeout: timeoutMs },
  );

  // The listbox should be tabbable in docs (standalone virtual-focus listbox).
  const tabIndex = await page.evaluate(
    () => document.querySelector("#docs-listbox-basic")?.tabIndex ?? null,
  );
  if (tabIndex !== 0) {
    throw new Error(`Expected #docs-listbox-basic.tabIndex === 0, got ${tabIndex}`);
  }

  // Tab from the demo header link into the listbox.
  const openLab = page
    .locator('[data-doc-demo="listbox-basic"]')
    .locator("xpath=..")
    .locator('a[href*="?lab=listbox"]');
  await openLab.first().focus();
  await page.keyboard.press("Tab");

  await page.waitForFunction(
    () => document.activeElement?.id === "docs-listbox-basic",
    { timeout: timeoutMs },
  );

  // ArrowDown should set aria-activedescendant.
  await page.keyboard.press("ArrowDown");
  await page.waitForTimeout(40);
  const activeDescendant = await page.evaluate(
    () =>
      document
        .querySelector("#docs-listbox-basic")
        ?.getAttribute("aria-activedescendant") ?? null,
  );
  if (!activeDescendant) {
    throw new Error("Expected aria-activedescendant to be set after ArrowDown.");
  }
}
