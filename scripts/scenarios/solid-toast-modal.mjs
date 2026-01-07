export async function runSolidToastModalScenario(page, { timeoutMs, jitter }) {
  const root = page.locator("#toast-modal-root");
  const openModal = page.locator("#toast-modal-open");
  if (!(await root.count()) || !(await openModal.count())) {
    return {
      name: "solid-toast-modal",
      ok: false,
      details: { reason: "missing toast-modal root/trigger" },
    };
  }

  // Open modal.
  await openModal.first().click({ timeout: timeoutMs });
  await jitter?.();
  await page.waitForFunction(
    () => document.querySelector("#toast-modal-panel") != null,
    { timeout: timeoutMs },
  );

  // Show toast from within modal.
  await page.locator("#toast-modal-show-toast").click({ timeout: timeoutMs });
  await jitter?.();
  await page.waitForFunction(
    () => document.querySelector("#toast-1") != null,
    { timeout: timeoutMs },
  );

  // Toast dismiss should be clickable and must not dismiss the modal.
  await page.locator("#toast-1 button").first().click({ timeout: timeoutMs });
  await jitter?.();
  await page.waitForFunction(
    () => document.querySelector("#toast-1") == null,
    { timeout: timeoutMs },
  );
  const modalStillOpenAfterToast = await page.evaluate(
    () => document.querySelector("#toast-modal-panel") != null,
  );

  // Outside click should dismiss the modal without interacting with background UI.
  const clicksBefore = await page.evaluate(
    () => document.querySelector("#toast-modal-status")?.textContent ?? "",
  );
  await page.click("#toast-modal-backdrop", {
    timeout: timeoutMs,
    position: { x: 5, y: 5 },
  });
  await jitter?.();
  await page.waitForFunction(
    () => document.querySelector("#toast-modal-panel") == null,
    { timeout: timeoutMs },
  );
  const clicksAfter = await page.evaluate(
    () => document.querySelector("#toast-modal-status")?.textContent ?? "",
  );

  const ok =
    modalStillOpenAfterToast === true &&
    (clicksAfter ?? "").includes(clicksBefore ?? "");

  return {
    name: "solid-toast-modal",
    ok,
    details: {
      modalStillOpenAfterToast,
      clicksBefore,
      clicksAfter,
    },
  };
}
