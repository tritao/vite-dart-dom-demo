export async function runSolidWordprocScenario(page, { timeoutMs }) {
  const root = page.locator("#wordproc-root");
  const outliner = page.locator("#wordproc-outliner");
  const editor = page.locator("#wordproc-editor");
  const agent = page.locator("#wordproc-agent");
  if (
    !(await root.count()) ||
    !(await outliner.count()) ||
    !(await editor.count()) ||
    !(await agent.count())
  ) {
    return {
      name: "solid-wordproc",
      ok: false,
      details: { reason: "missing wordproc root/panels" },
    };
  }

  await page.waitForTimeout(150);

  const widths = await page.evaluate(() => {
    const outliner = document.querySelector("#wordproc-outliner");
    const agent = document.querySelector("#wordproc-agent");
    const editor = document.querySelector("#wordproc-editor");
    const r = (el) => (el ? el.getBoundingClientRect() : null);
    return {
      outliner: r(outliner),
      agent: r(agent),
      editor: r(editor),
      viewportW: window.innerWidth,
    };
  });

  const itemsBefore = await page.evaluate(
    () => document.querySelectorAll("[id^=wordproc-outline-item-]").length,
  );

  // Create a new section from the empty/default outline.
  await page.locator("#wordproc-add-section").click({ timeout: timeoutMs });
  await page.waitForFunction(
    () => document.querySelectorAll("[id^=wordproc-outline-item-]").length >= 2,
    undefined,
    { timeout: timeoutMs },
  );
  const itemsAfterAdd = await page.evaluate(
    () => document.querySelectorAll("[id^=wordproc-outline-item-]").length,
  );

  const editorSelectedAfterClick = await page.evaluate(
    () => document.querySelector("#wordproc-editor-selected")?.textContent ?? "",
  );

  // Editor should be mounted (Tiptap/ProseMirror) and editable.
  await page.waitForFunction(
    () => document.querySelector("#wordproc-editor-mount .ProseMirror") != null,
    undefined,
    { timeout: timeoutMs },
  );
  const proseMirror = page.locator("#wordproc-editor-mount .ProseMirror");
  await proseMirror.first().click({ timeout: timeoutMs });
  await proseMirror.first().type(" hello", { delay: 5 });

  // Local storage should reflect a persisted doc for the current section.
  await page.waitForFunction(
    ({ key, expected }) => {
      try {
        const raw = window.localStorage?.getItem(key);
        if (!raw) return false;
        return raw.includes(expected);
      } catch {
        return false;
      }
    },
    { key: "wordproc.v1", expected: "hello" },
    { timeout: timeoutMs },
  );

  // Search should narrow the list.
  const search = page.locator("#wordproc-outline-search");
  const searchHeights = [];
  const height0 = await search.first().evaluate((el) =>
    el.getBoundingClientRect().height,
  );
  searchHeights.push(height0);
  await search.first().type("Section 2", { delay: 10 });
  await page.waitForTimeout(80);
  const height1 = await search.first().evaluate((el) =>
    el.getBoundingClientRect().height,
  );
  searchHeights.push(height1);
  const itemsAfterSearch = await page.evaluate(
    () => document.querySelectorAll("[id^=wordproc-outline-item-]").length,
  );

  const beforeRandom = null;
  const afterRandom = null;

  // Agent send.
  const msgCountBefore = await page.evaluate(
    () => document.querySelectorAll("#wordproc-agent-log .wordproc-agent-msg").length,
  );
  await page.locator("#wordproc-agent-input").fill("hello");
  await page.locator("#wordproc-agent-send").click({ timeout: timeoutMs });
  await page.waitForFunction(
    ({ before }) =>
      document.querySelectorAll("#wordproc-agent-log .wordproc-agent-msg").length ===
      before + 1,
    { before: msgCountBefore },
    { timeout: timeoutMs },
  );
  const msgCountAfter = await page.evaluate(
    () => document.querySelectorAll("#wordproc-agent-log .wordproc-agent-msg").length,
  );

  // Heavy subtree mount/unmount increments cleanup count on disposal.
  await page.locator("#wordproc-toggle-heavy").click({ timeout: timeoutMs });
  await page.waitForFunction(
    () => document.querySelector("#wordproc-heavy") != null,
    undefined,
    { timeout: timeoutMs },
  );
  await page.locator("#wordproc-toggle-heavy").click({ timeout: timeoutMs });
  await page.waitForFunction(
    () => document.querySelector("#wordproc-heavy") == null,
    undefined,
    { timeout: timeoutMs },
  );
  await page.waitForFunction(
    () =>
      (document.querySelector("#wordproc-status")?.textContent ?? "").includes(
        "Cleanup: 1",
      ),
    undefined,
    { timeout: timeoutMs },
  );

  const ok =
    itemsBefore >= 1 &&
    itemsAfterAdd >= 2 &&
    itemsAfterSearch > 0 &&
    itemsAfterSearch < itemsAfterAdd &&
    /sec-2/.test(editorSelectedAfterClick) &&
    msgCountAfter === msgCountBefore + 1 &&
    widths?.outliner?.width != null &&
    widths?.agent?.width != null &&
    // Only enforce fixed widths when viewport is wide enough.
    (widths.viewportW < 1120 ||
      (Math.abs(widths.outliner.width - 471) <= 3 &&
        Math.abs(widths.agent.width - 472) <= 3));

  return {
    name: "solid-wordproc",
    ok,
    details: {
      widths,
      itemsBefore,
      itemsAfterAdd,
      itemsAfterSearch,
      searchHeights,
      editorSelectedAfterClick,
      beforeRandom,
      afterRandom,
      msgCountBefore,
      msgCountAfter,
    },
  };
}
