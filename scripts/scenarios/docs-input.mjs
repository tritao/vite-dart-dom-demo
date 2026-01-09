export async function runDocsInputScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  await page.waitForFunction(
    () => document.querySelector('[data-doc-demo="input-basic"]') != null,
    { timeout: timeoutMs },
  );

  const scope = page.locator('[data-doc-demo="input-basic"]');
  const input = scope.locator("input").first();
  await input.waitFor({ state: "visible", timeout: timeoutMs });

  await input.fill("hello");
  await page.waitForTimeout(50);

  const status = await scope.locator(".muted").first().innerText();
  if (!status.includes('value="hello"')) {
    throw new Error(`Expected status to include value=\"hello\", got: ${status}`);
  }
}

