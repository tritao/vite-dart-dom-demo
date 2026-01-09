export async function runDocsNavigationMenuScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const demoSel = '[data-doc-demo="navigation-menu-basic"]';

  await page.waitForFunction((sel) => document.querySelector(sel) != null, demoSel, {
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    (sel) => document.querySelector(`${sel} [data-test="nav-menu"]`) != null,
    demoSel,
    { timeout: timeoutMs },
  );

  const clickTrigger = async (text) => {
    await page.locator(`${demoSel} .navigationMenuTrigger`, { hasText: text }).click();
  };

  const panelTitle = async () =>
    await page.evaluate(() => {
      const panel = document.querySelector(".navigationMenuContent");
      if (!panel) return null;
      return panel.querySelector("h3")?.textContent?.trim() ?? null;
    });

  await clickTrigger("Getting started");
  await page.waitForTimeout(50);
  const title1 = await panelTitle();
  if (title1 !== "Getting started") {
    throw new Error(`Expected Getting started panel, got: ${title1}`);
  }

  await clickTrigger("Components");
  await page.waitForTimeout(50);
  const title2 = await panelTitle();
  if (title2 !== "Components") {
    throw new Error(`Expected Components panel, got: ${title2}`);
  }

  // Click outside closes.
  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await page.waitForTimeout(50);
  const title3 = await panelTitle();
  if (title3 != null) {
    throw new Error(`Expected panel to close on outside click, got: ${title3}`);
  }
}

