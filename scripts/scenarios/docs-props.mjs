async function assertPropsHydrated(page, { timeoutMs }) {
  await page.waitForFunction(() => {
    const nodes = Array.from(document.querySelectorAll("[data-doc-props]"));
    if (nodes.length === 0) return false;
    return nodes.every((n) => {
      const t = (n.textContent ?? "").trim();
      if (!t) return false;
      if (t.includes("Loading")) return false;
      if (t.includes("Unknown props")) return false;
      return n.querySelector("table") != null;
    });
  }, { timeout: timeoutMs });
}

async function gotoDocs(page, slug, timeoutMs) {
  const u = new URL(page.url());
  u.searchParams.delete("docs");
  u.hash = slug === "1" || slug === "index" ? "#/" : `#/${slug}`;
  await page.goto(u.toString(), { timeout: timeoutMs });
  await page.waitForURL(new RegExp(`#\\/${slug.replace(/[-/]/g, "[-/]")}`), {
    timeout: timeoutMs,
  });
}

export async function runDocsPropsScenario(page, ctx) {
  const { timeoutMs = 120_000 } = ctx ?? {};

  // A small representative set including generic components.
  const slugs = [
    "input",
    "textarea",
    "select",
    "combobox",
    "listbox",
    "input-otp",
  ];

  for (const slug of slugs) {
    await gotoDocs(page, slug, timeoutMs);
    await assertPropsHydrated(page, { timeoutMs });
  }
}
