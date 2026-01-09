import "package:web/web.dart" as web;

import "../solid_dom/core/navigation_menu.dart";

/// Styled NavigationMenu (Solidus UI skin).
///
/// For the unstyled primitive, use `createNavigationMenu` from `solid_dom`.
web.HTMLElement NavigationMenu({
  required Iterable<NavigationMenuItem> items,
  bool openOnHover = true,
  int closeDelayMs = 140,
  int openDelayMs = 0,
  String ariaLabel = "navigation",
  String? id,
}) {
  return createNavigationMenu(
    items: items,
    openOnHover: openOnHover,
    closeDelayMs: closeDelayMs,
    openDelayMs: openDelayMs,
    ariaLabel: ariaLabel,
    id: id,
    rootClassName: "navigationMenu",
    listClassName: "navigationMenuList",
    triggerClassName: "navigationMenuTrigger",
    contentClassName: "navigationMenuContent",
  );
}

