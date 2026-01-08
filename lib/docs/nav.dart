import "dart:js_interop";

import "package:web/web.dart" as web;

web.HTMLElement solidDocsNav({required String active}) {
  final nav = web.HTMLDivElement()
    ..className = "docsTopbar"
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", "Solidus navigation");

  final inner = web.HTMLDivElement()..className = "docsTopbarInner";
  nav.appendChild(inner);

  final brand = web.HTMLAnchorElement()
    ..href = "?docs=1"
    ..className = "docsTopbarBrand";
  final brandLogo = web.HTMLImageElement()
    ..className = "docsTopbarLogo"
    ..src = "assets/solidus-mark.png"
    ..alt = "";
  brand.appendChild(brandLogo);
  brand.appendChild(web.Text("Solidus"));
  inner.appendChild(brand);

  web.HTMLElement link(String label, String href, {bool current = false}) {
    final a = web.HTMLAnchorElement()
      ..href = href
      ..textContent = label
      ..className = "docsTopbarLink";
    if (current) a.setAttribute("aria-current", "page");
    return a;
  }

  final links = web.HTMLDivElement()..className = "docsTopbarLinks";
  links.appendChild(link("Docs", "?docs=1", current: active == "docs"));
  links.appendChild(link("Labs", "?solid=catalog", current: active == "labs"));
  inner.appendChild(links);

  final search = web.HTMLDivElement()..className = "docsTopbarSearch";
  final input = web.HTMLInputElement()
    ..id = "docs-search"
    ..className = "input docsTopbarSearchInput"
    ..type = "search"
    ..placeholder = "Search docs…";
  search.appendChild(input);
  inner.appendChild(search);

  final actions = web.HTMLDivElement()..className = "docsTopbarActions";
  final github = web.HTMLAnchorElement()
    ..className = "docsTopbarIcon"
    ..href = "https://github.com/tritao/solidus"
    ..target = "_blank"
    ..rel = "noreferrer"
    ..setAttribute("aria-label", "GitHub");
  github.innerHTML = (r"""
<svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
  <path fill="currentColor" d="M12 .5C5.73.5.5 5.86.5 12.44c0 5.3 3.44 9.79 8.2 11.38.6.12.82-.27.82-.6 0-.3-.01-1.28-.02-2.32-3.34.75-4.04-1.47-4.04-1.47-.54-1.45-1.32-1.83-1.32-1.83-1.08-.76.08-.75.08-.75 1.19.09 1.82 1.29 1.82 1.29 1.06 1.9 2.77 1.35 3.45 1.03.11-.8.41-1.35.74-1.66-2.67-.31-5.47-1.4-5.47-6.2 0-1.37.46-2.49 1.22-3.37-.12-.31-.53-1.57.12-3.28 0 0 1-.33 3.3 1.28a11.07 11.07 0 0 1 6 0C17.7 5.74 18.7 6.07 18.7 6.07c.65 1.71.24 2.97.12 3.28.76.88 1.22 2 1.22 3.37 0 4.82-2.8 5.88-5.48 6.19.42.39.8 1.17.8 2.36 0 1.7-.02 3.07-.02 3.49 0 .33.22.72.83.6 4.75-1.59 8.18-6.09 8.18-11.38C23.5 5.86 18.27.5 12 .5z"/>
</svg>
""").toJS;
  actions.appendChild(github);

  final theme = web.HTMLButtonElement()
    ..id = "docs-theme"
    ..type = "button"
    ..className = "docsTopbarIcon"
    ..setAttribute("aria-label", "Theme");
  theme.innerHTML = (r"""
<svg class="docsThemeIcon docsThemeIcon--system" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
  <path fill="currentColor" d="M4 5a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-5l1 2H8l1-2H6a2 2 0 0 1-2-2V5zm2 0v10h12V5H6z"/>
</svg>
<svg class="docsThemeIcon docsThemeIcon--light" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
  <path fill="currentColor" d="M12 18a6 6 0 1 1 0-12 6 6 0 0 1 0 12zm0-16h0v3h0V2zm0 19h0v3h0v-3zM4.22 4.22h0l2.12 2.12h0L4.22 4.22zm13.44 13.44h0l2.12 2.12h0l-2.12-2.12zM2 12h3v0H2v0zm19 0h3v0h-3v0zM4.22 19.78h0l2.12-2.12h0l-2.12 2.12zM17.66 6.34h0l2.12-2.12h0l-2.12 2.12z"/>
</svg>
<svg class="docsThemeIcon docsThemeIcon--dark" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
  <path fill="currentColor" d="M21 14.5A8.5 8.5 0 0 1 9.5 3 6.5 6.5 0 1 0 21 14.5z"/>
</svg>
""").toJS;
  actions.appendChild(theme);

  final back = web.HTMLAnchorElement()
    ..href = "./"
    ..className = "docsTopbarIcon"
    ..setAttribute("aria-label", "Back to demo home")
    ..textContent = "↩";
  actions.appendChild(back);

  inner.appendChild(actions);

  return nav;
}
