export async function runDocsBreadcrumbsScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const demoSel = '[data-doc-demo="breadcrumbs-basic"]';

  await page.waitForFunction((sel) => document.querySelector(sel) != null, demoSel, {
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    (sel) => document.querySelector(`${sel} [role="navigation"][aria-label="breadcrumb"]`) != null,
    demoSel,
    { timeout: timeoutMs },
  );

  const info = await page.evaluate((sel) => {
    const nav = document.querySelector(`${sel} [role="navigation"][aria-label="breadcrumb"]`);
    const current = nav?.querySelector('[aria-current="page"]')?.textContent?.trim() ?? null;
    const seps = nav ? nav.querySelectorAll(".breadcrumbSeparator").length : 0;
    return { current, seps };
  }, demoSel);

  if (info.current !== "Breadcrumbs" || info.seps < 2) {
    throw new Error(`Unexpected breadcrumbs: ${JSON.stringify(info)}`);
  }
}

