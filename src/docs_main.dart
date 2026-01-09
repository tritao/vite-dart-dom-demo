import "package:web/web.dart" as web;

import "./docs/router.dart";
import "package:dart_web_test/dom_ui/theme.dart" as theme;

void main() {
  final mount = web.document.querySelector("#app");
  if (mount == null) return;

  theme.initTheme();

  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final params = Uri.splitQueryString(query);
  final docs = params["docs"];
  final solid = params["solid"];
  final demos = params["demos"];

  // Cross-page navigation: prefer the dedicated bundles.
  if (solid != null) {
    web.window.location.assign("labs.html$search");
    return;
  }
  if (demos != null) {
    web.window.location.assign("./$search");
    return;
  }

  mountSolidDocs(mount, docs);
}

