import { runDocsNavScenario } from "./docs-nav.mjs";
import { runDocsButtonScenario } from "./docs-button.mjs";
import { runDocsBadgeScenario } from "./docs-badge.mjs";
import { runDocsSeparatorScenario } from "./docs-separator.mjs";
import { runDocsProgressScenario } from "./docs-progress.mjs";
import { runDocsSpinnerScenario } from "./docs-spinner.mjs";
import { runDocsAvatarScenario } from "./docs-avatar.mjs";
import { runDocsBreadcrumbsScenario } from "./docs-breadcrumbs.mjs";
import { runDocsAlertScenario } from "./docs-alert.mjs";
import { runDocsToggleScenario } from "./docs-toggle.mjs";
import { runDocsScrollAreaScenario } from "./docs-scroll-area.mjs";
import { runDocsCardScenario } from "./docs-card.mjs";
import { runDocsTableScenario } from "./docs-table.mjs";

async function gotoDocs(page, slug, timeoutMs) {
  const u = new URL(page.url());
  u.searchParams.delete("docs");
  u.hash = slug === "1" || slug === "index" ? "#/" : `#/${slug}`;
  await page.goto(u.toString(), { timeout: timeoutMs });
  await page.waitForURL(new RegExp(`#\\/${slug.replace(/[-/]/g, "[-/]")}`), {
    timeout: timeoutMs,
  });
}

export async function runDocsUiSuiteScenario(page, ctx) {
  const { timeoutMs = 240_000 } = ctx ?? {};

  await runDocsNavScenario(page, { timeoutMs });

  await gotoDocs(page, "button", timeoutMs);
  await runDocsButtonScenario(page, { timeoutMs });

  await gotoDocs(page, "badge", timeoutMs);
  await runDocsBadgeScenario(page, { timeoutMs });

  await gotoDocs(page, "separator", timeoutMs);
  await runDocsSeparatorScenario(page, { timeoutMs });

  await gotoDocs(page, "progress", timeoutMs);
  await runDocsProgressScenario(page, { timeoutMs });

  await gotoDocs(page, "spinner", timeoutMs);
  await runDocsSpinnerScenario(page, { timeoutMs });

  await gotoDocs(page, "avatar", timeoutMs);
  await runDocsAvatarScenario(page, { timeoutMs });

  await gotoDocs(page, "breadcrumbs", timeoutMs);
  await runDocsBreadcrumbsScenario(page, { timeoutMs });

  await gotoDocs(page, "alert", timeoutMs);
  await runDocsAlertScenario(page, { timeoutMs });

  await gotoDocs(page, "toggle", timeoutMs);
  await runDocsToggleScenario(page, { timeoutMs });

  await gotoDocs(page, "scroll-area", timeoutMs);
  await runDocsScrollAreaScenario(page, { timeoutMs });

  await gotoDocs(page, "card", timeoutMs);
  await runDocsCardScenario(page, { timeoutMs });

  await gotoDocs(page, "table", timeoutMs);
  await runDocsTableScenario(page, { timeoutMs });
}
