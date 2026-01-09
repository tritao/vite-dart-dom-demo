import { runDocsNavScenario } from "./docs-nav.mjs";
import { runDocsDialogScenario } from "./docs-dialog.mjs";
import { runDocsPopoverScenario } from "./docs-popover.mjs";
import { runDocsTooltipScenario } from "./docs-tooltip.mjs";
import { runDocsDropdownMenuScenario } from "./docs-dropdown-menu.mjs";
import { runDocsMenubarScenario } from "./docs-menubar.mjs";
import { runDocsContextMenuScenario } from "./docs-context-menu.mjs";
import { runDocsToastScenario } from "./docs-toast.mjs";

async function gotoDocs(page, slug, timeoutMs) {
  const u = new URL(page.url());
  u.searchParams.set("docs", slug);
  await page.goto(u.toString(), { timeout: timeoutMs });
  await page.waitForURL(new RegExp(`\\?docs=${slug.replace(/[-/]/g, "[-/]")}`), {
    timeout: timeoutMs,
  });
}

export async function runDocsOverlaySuiteScenario(page, ctx) {
  const { timeoutMs = 240_000 } = ctx ?? {};

  await runDocsNavScenario(page, { timeoutMs });

  await gotoDocs(page, "dialog", timeoutMs);
  await runDocsDialogScenario(page, { timeoutMs });

  await gotoDocs(page, "popover", timeoutMs);
  await runDocsPopoverScenario(page, { timeoutMs });

  await gotoDocs(page, "tooltip", timeoutMs);
  await runDocsTooltipScenario(page, { timeoutMs });

  await gotoDocs(page, "dropdown-menu", timeoutMs);
  await runDocsDropdownMenuScenario(page, { timeoutMs });

  await gotoDocs(page, "menubar", timeoutMs);
  await runDocsMenubarScenario(page, { timeoutMs });

  await gotoDocs(page, "context-menu", timeoutMs);
  await runDocsContextMenuScenario(page, { timeoutMs });

  await gotoDocs(page, "toast", timeoutMs);
  await runDocsToastScenario(page, { timeoutMs });
}

