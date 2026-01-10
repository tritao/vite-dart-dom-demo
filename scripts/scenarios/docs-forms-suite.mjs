import { runDocsNavScenario } from "./docs-nav.mjs";
import { runDocsInputScenario } from "./docs-input.mjs";
import { runDocsFormFieldScenario } from "./docs-form-field.mjs";
import { runDocsComboboxScenario } from "./docs-combobox.mjs";
import { runDocsCheckboxScenario } from "./docs-checkbox.mjs";
import { runDocsRadioGroupScenario } from "./docs-radio-group.mjs";
import { runDocsToggleGroupScenario } from "./docs-toggle-group.mjs";
import { runDocsListboxScenario } from "./docs-listbox.mjs";
import { runDocsInputOtpScenario } from "./docs-input-otp.mjs";
import { runDocsTextareaAutosizeScenario } from "./docs-textarea-autosize.mjs";
import { runDocsSliderScenario } from "./docs-slider.mjs";
import { runDocsScrollAreaScenario } from "./docs-scroll-area.mjs";

async function gotoDocs(page, slug, timeoutMs) {
  const u = new URL(page.url());
  u.searchParams.delete("docs");
  u.hash = slug === "1" || slug === "index" ? "#/" : `#/${slug}`;
  await page.goto(u.toString(), { timeout: timeoutMs });
  await page.waitForURL(new RegExp(`#\\/${slug.replace(/[-/]/g, "[-/]")}`), {
    timeout: timeoutMs,
  });
}

export async function runDocsFormsSuiteScenario(page, ctx) {
  const { timeoutMs = 240_000 } = ctx ?? {};

  // Ensure docs SPA navigation stays warm.
  await runDocsNavScenario(page, { timeoutMs });

  await gotoDocs(page, "input", timeoutMs);
  await runDocsInputScenario(page, { timeoutMs });

  await gotoDocs(page, "form-field", timeoutMs);
  await runDocsFormFieldScenario(page, { timeoutMs });

  await gotoDocs(page, "combobox", timeoutMs);
  await runDocsComboboxScenario(page, { timeoutMs });

  await gotoDocs(page, "input-otp", timeoutMs);
  await runDocsInputOtpScenario(page, { timeoutMs });

  // Autosize lives on the Textarea docs page.
  await gotoDocs(page, "textarea", timeoutMs);
  await runDocsTextareaAutosizeScenario(page, { timeoutMs });

  await gotoDocs(page, "checkbox", timeoutMs);
  await runDocsCheckboxScenario(page, { timeoutMs });

  await gotoDocs(page, "radio-group", timeoutMs);
  await runDocsRadioGroupScenario(page, { timeoutMs });

  await gotoDocs(page, "toggle-group", timeoutMs);
  await runDocsToggleGroupScenario(page, { timeoutMs });

  await gotoDocs(page, "slider", timeoutMs);
  await runDocsSliderScenario(page, { timeoutMs });

  await gotoDocs(page, "listbox", timeoutMs);
  await runDocsListboxScenario(page, { timeoutMs });

  await gotoDocs(page, "scroll-area", timeoutMs);
  await runDocsScrollAreaScenario(page, { timeoutMs });
}
