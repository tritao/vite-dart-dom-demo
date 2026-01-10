export async function runDocsNavScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  const sidebar = page.locator(".docsSidebar");
  await sidebar.waitFor({ state: "visible", timeout: timeoutMs });

  // Wait for the manifest to be loaded at least once.
  await page.waitForFunction(() => {
    const el = document.querySelector(".docsSidebar");
    if (!el) return false;
    const t = el.textContent ?? "";
    return t.includes("Runtime") || t.includes("Overlays") || t.includes("Docs");
  });

  // After initial load, sidebar should stay populated during SPA navigation.
  await page.waitForFunction(() => {
    const el = document.querySelector(".docsSidebar");
    if (!el) return false;
    return !(el.textContent ?? "").includes("Loading…");
  });

  // Clicking a docs link should not trigger a full reload. Same-document
  // navigation (hash navigation) is expected.
  const sentinel = await page.evaluate(() => {
    window.__docsNavSentinel = Math.random();
    return window.__docsNavSentinel;
  });
  await sidebar.getByRole("link", { name: "Dialog" }).click();
  await page.waitForURL(/#\\/dialog/, { timeout: timeoutMs });

  const stillThere = await page.evaluate(() => window.__docsNavSentinel);
  if (stillThere !== sentinel) {
    throw new Error("Docs link caused a full reload (sentinel lost).");
  }

  await page.waitForFunction(() => {
    const t = document.querySelector("#docs-title")?.textContent ?? "";
    return t.includes("Dialog");
  });

  const sidebarText = await sidebar.innerText();
  if (sidebarText.includes("Loading…")) {
    throw new Error("Sidebar showed Loading… during docs page change.");
  }
}
