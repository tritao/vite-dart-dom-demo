export async function runDocsFormFieldScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="form-field-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="form-field-basic"]');
  const input = scope.locator("input").first();
  await input.waitFor({ state: "visible", timeout: timeoutMs });

  const initial = await input.evaluate((el) => ({
    id: el.id,
    invalid: el.getAttribute("aria-invalid"),
    describedBy: el.getAttribute("aria-describedby"),
  }));

  if (!initial.id) throw new Error("Expected FormField to assign an id to the control.");
  if (initial.invalid !== "true") {
    throw new Error(`Expected aria-invalid=true initially, got ${initial.invalid}`);
  }

  const expectedDesc = "docs-form-field-basic-desc";
  const expectedMsg = "docs-form-field-basic-msg";
  if (!initial.describedBy?.includes(expectedDesc) || !initial.describedBy?.includes(expectedMsg)) {
    throw new Error(
      `Expected aria-describedby to include ${expectedDesc} and ${expectedMsg}, got ${initial.describedBy}`,
    );
  }

  const labelFor = await scope.locator("label").first().evaluate((el) => el.getAttribute("for"));
  if (labelFor !== initial.id) {
    throw new Error(`Expected label for=${initial.id}, got ${labelFor}`);
  }

  await input.fill("a@b.com");
  await page.waitForTimeout(50);

  const after = await input.evaluate((el) => ({
    invalid: el.getAttribute("aria-invalid"),
    describedBy: el.getAttribute("aria-describedby"),
  }));

  if (after.invalid != null) {
    throw new Error(`Expected aria-invalid removed after valid input, got ${after.invalid}`);
  }
  if (!after.describedBy?.includes(expectedDesc) || after.describedBy?.includes(expectedMsg)) {
    throw new Error(
      `Expected aria-describedby to keep ${expectedDesc} and drop ${expectedMsg}, got ${after.describedBy}`,
    );
  }
}

