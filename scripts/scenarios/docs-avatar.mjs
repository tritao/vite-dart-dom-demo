export async function runDocsAvatarScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const demoSel = '[data-doc-demo="avatar-basic"]';

  await page.waitForFunction((sel) => document.querySelector(sel) != null, demoSel, {
    timeout: timeoutMs,
  });

  await page.waitForFunction(
    (sel) => document.querySelectorAll(`${sel} .avatar`).length >= 3,
    demoSel,
    { timeout: timeoutMs },
  );

  // Broken avatar should end up in error state.
  await page.waitForFunction(
    (sel) => document.querySelector(`${sel} .avatar[data-test="broken"]`)?.getAttribute("data-state") === "error",
    demoSel,
    { timeout: timeoutMs },
  );

  const states = await page.evaluate((sel) => {
    const ok = document.querySelector(`${sel} .avatar[data-test="ok"]`);
    const broken = document.querySelector(`${sel} .avatar[data-test="broken"]`);
    const initials = document.querySelector(`${sel} .avatar[data-test="initials"]`);
    return {
      ok: ok?.getAttribute("data-state") ?? null,
      broken: broken?.getAttribute("data-state") ?? null,
      initials: initials?.getAttribute("data-state") ?? null,
    };
  }, demoSel);

  if (states.broken !== "error" || states.initials !== "error") {
    throw new Error(`Unexpected avatar states: ${JSON.stringify(states)}`);
  }
  // ok may be loaded or error depending on environment, but should exist.
  if (!states.ok) {
    throw new Error(`Missing ok avatar: ${JSON.stringify(states)}`);
  }
}

