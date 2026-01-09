export async function runDocsComboboxScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="combobox-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="combobox-basic"]');
  const input = scope.locator("#docs-combobox-basic-input");
  await input.waitFor({ state: "visible", timeout: timeoutMs });

  const describedBy = await input.evaluate((el) => el.getAttribute("aria-describedby"));
  const invalid = await input.evaluate((el) => el.getAttribute("aria-invalid"));

  if (invalid != null) {
    throw new Error(`Expected aria-invalid to be unset, got ${invalid}`);
  }

  const expectedDesc = "docs-combobox-basic-field-desc";
  const unexpectedMsg = "docs-combobox-basic-field-msg";

  if (!describedBy?.includes(expectedDesc) || describedBy?.includes(unexpectedMsg)) {
    throw new Error(
      `Expected aria-describedby to include ${expectedDesc} and not ${unexpectedMsg}, got ${describedBy}`,
    );
  }

  const labelFor = await scope.locator("label").first().evaluate((el) => el.getAttribute("for"));
  const inputId = await input.evaluate((el) => el.id);
  if (labelFor !== inputId) {
    throw new Error(`Expected label for=${inputId}, got ${labelFor}`);
  }

  // Basic behavior: open + select.
  await input.click();
  await page.keyboard.type("t");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(50);

  const status = await scope
    .locator(".muted")
    .filter({ hasText: "Value:" })
    .first()
    .innerText();
  if (!/Value:/.test(status)) {
    throw new Error(`Expected status to include Value:, got: ${status}`);
  }
}
