import "package:web/web.dart" as web;

const _storageKey = "solidui.theme";

/// Allowed values: `system`, `light`, `dark`.
String getThemePreference() {
  final storage = web.window.localStorage;
  final raw = storage?.getItem(_storageKey);
  switch (raw) {
    case "light":
    case "dark":
    case "system":
      return raw!;
  }
  return "system";
}

void setThemePreference(String mode) {
  final storage = web.window.localStorage;
  if (storage == null) return;
  if (mode == "system") {
    storage.removeItem(_storageKey);
    return;
  }
  storage.setItem(_storageKey, mode);
}

void applyThemePreference(String mode) {
  final root = web.document.documentElement;
  if (root == null) return;

  // `system` means: let CSS `prefers-color-scheme` drive token selection.
  if (mode == "system") {
    root.removeAttribute("data-theme");
    return;
  }

  if (mode == "light" || mode == "dark") {
    root.setAttribute("data-theme", mode);
  }
}

/// Reads persisted preference (if any) and applies it to `<html data-theme>`.
void initTheme() {
  applyThemePreference(getThemePreference());
}
