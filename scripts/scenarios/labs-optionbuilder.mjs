export async function runLabsOptionBuilderScenario(page, { timeoutMs, jitter }) {
  const root = page.locator("#optionbuilder-root");
  const listbox = page.locator("#optionbuilder-listbox");
  const virtualInput = page.locator("#optionbuilder-virtual-input");
  const virtualListbox = page.locator("#optionbuilder-virtual-listbox");
  if (
    !(await root.count()) ||
    !(await listbox.count()) ||
    !(await virtualInput.count()) ||
    !(await virtualListbox.count())
  ) {
    return {
      name: "labs-optionbuilder",
      ok: false,
      details: { reason: "missing optionbuilder elements" },
    };
  }

  // Focus first option in standard listbox.
  await listbox.locator("[role=option]").first().click({ timeout: timeoutMs });
  await jitter?.();
  await page.waitForTimeout(60);

  const activeBefore = await page.evaluate(() => ({
    activeId: document.activeElement?.id ?? null,
    activeFromBuilder:
      document.querySelector("#optionbuilder-listbox [data-active-from-builder]")
        ?.id ?? null,
  }));

  // ArrowDown should move active (skipping disabled).
  await page.keyboard.press("ArrowDown");
  await jitter?.();
  await page.waitForTimeout(60);
  await page.keyboard.press("ArrowDown");
  await jitter?.();
  await page.waitForTimeout(60);

  const activeAfter = await page.evaluate(() => ({
    activeId: document.activeElement?.id ?? null,
    activeFromBuilder:
      document.querySelector("#optionbuilder-listbox [data-active-from-builder]")
        ?.id ?? null,
    activeAria:
      document.querySelector("#optionbuilder-listbox [data-active=true]")?.id ??
      null,
  }));

  // Enter selects active; builder should expose selected.
  await page.keyboard.press("Enter");
  await jitter?.();
  await page.waitForTimeout(60);

  const selectedAfter = await page.evaluate(() => ({
    status: document.querySelector("#optionbuilder-status")?.textContent ?? null,
    selectedAria:
      document.querySelector("#optionbuilder-listbox [aria-selected=true]")?.id ??
      null,
    selectedFromBuilder:
      document.querySelector(
        "#optionbuilder-listbox [data-selected-from-builder]",
      )?.id ?? null,
  }));

  // Virtual focus: active descendant should match builder's active marker.
  await virtualInput.first().click({ timeout: timeoutMs });
  await jitter?.();
  await page.keyboard.press("ArrowDown");
  await jitter?.();
  await page.waitForTimeout(60);

  const virtualAfter = await page.evaluate(() => ({
    activeId: document.activeElement?.id ?? null,
    activeDescendant:
      document
        .querySelector("#optionbuilder-virtual-input")
        ?.getAttribute("aria-activedescendant") ?? null,
    activeFromBuilder:
      document.querySelector(
        "#optionbuilder-virtual-listbox [data-active-from-builder]",
      )?.id ?? null,
  }));

  const ok =
    typeof activeBefore.activeId === "string" &&
    activeBefore.activeId.length > 0 &&
    typeof activeAfter.activeFromBuilder === "string" &&
    activeAfter.activeFromBuilder.length > 0 &&
    activeAfter.activeAria === activeAfter.activeFromBuilder &&
    typeof selectedAfter.selectedAria === "string" &&
    selectedAfter.selectedAria === selectedAfter.selectedFromBuilder &&
    (selectedAfter.status ?? "").includes("Last: select") &&
    virtualAfter.activeId === "optionbuilder-virtual-input" &&
    virtualAfter.activeDescendant === virtualAfter.activeFromBuilder;

  return {
    name: "labs-optionbuilder",
    ok,
    details: {
      activeBefore,
      activeAfter,
      selectedAfter,
      virtualAfter,
    },
  };
}
