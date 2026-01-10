import "package:web/web.dart" as web;

import "./docs/router.dart";
import "package:solidus/dom_ui/router.dart" as router;
import "package:solidus/dom_ui/theme.dart" as theme;

void main() {
  final mount = web.document.querySelector("#app");
  if (mount == null) return;

  theme.initTheme();

  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final params = Uri.splitQueryString(query);
  final docs = params["docs"];
  final lab = params["lab"];
  final demos = params["demos"];

  // Cross-page navigation: prefer the dedicated bundles.
  if (lab != null) {
    web.window.location.assign("labs.html$search");
    return;
  }
  if (demos != null) {
    web.window.location.assign("./$search");
    return;
  }

  // Back-compat: convert the legacy `?docs=` route to a hash route.
  if (docs != null) {
    final slug = router.normalizeDocsSlug(docs);
    final nextFragment = slug == "index" ? "/" : "/$slug";
    final nextParams = Map<String, String>.from(params)..remove("docs");
    final nextUri = Uri.base.replace(
      queryParameters: nextParams.isEmpty ? null : nextParams,
      fragment: nextFragment,
    );
    web.window.history.replaceState(null, "", nextUri.toString());
  }

  mountSolidDocs(mount);
}
