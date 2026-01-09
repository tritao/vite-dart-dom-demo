import "package:web/web.dart" as web;

import "./solid/dom_demo.dart";
import "./solid/overlay_demo.dart";
import "./solid/dialog_demo.dart";
import "./solid/popover_demo.dart";
import "./solid/roving_demo.dart";
import "./solid/toast_demo.dart";
import "./solid/catalog_demo.dart";
import "./solid/dropdown_menu_demo.dart";
import "./solid/menubar_demo.dart";
import "./solid/context_menu_demo.dart";
import "./solid/tooltip_demo.dart";
import "./solid/select_demo.dart";
import "./solid/combobox_demo.dart";
import "./solid/listbox_demo.dart";
import "./solid/selection_demo.dart";
import "./solid/tabs_demo.dart";
import "./solid/accordion_demo.dart";
import "./solid/switch_demo.dart";
import "./solid/nesting_demo.dart";
import "./solid/toast_modal_demo.dart";
import "./solid/optionbuilder_demo.dart";
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
  if (docs != null) {
    web.window.location.assign("docs.html$search");
    return;
  }
  if (demos != null) {
    web.window.location.assign("./$search");
    return;
  }

  final mode = solid ?? "catalog";

  if (mode == "overlay") {
    mountSolidOverlayDemo(mount);
    return;
  }
  if (mode == "dialog") {
    mountSolidDialogDemo(mount);
    return;
  }
  if (mode == "popover") {
    mountSolidPopoverDemo(mount);
    return;
  }
  if (mode == "roving") {
    mountSolidRovingDemo(mount);
    return;
  }
  if (mode == "toast") {
    mountSolidToastDemo(mount);
    return;
  }
  if (mode == "catalog") {
    mountSolidCatalogDemo(mount);
    return;
  }
  if (mode == "dropdownmenu") {
    mountSolidDropdownMenuDemo(mount);
    return;
  }
  if (mode == "menubar") {
    mountSolidMenubarDemo(mount);
    return;
  }
  if (mode == "contextmenu") {
    mountSolidContextMenuDemo(mount);
    return;
  }
  if (mode == "tooltip") {
    mountSolidTooltipDemo(mount);
    return;
  }
  if (mode == "select") {
    mountSolidSelectDemo(mount);
    return;
  }
  if (mode == "combobox") {
    mountSolidComboboxDemo(mount);
    return;
  }
  if (mode == "listbox") {
    mountSolidListboxDemo(mount);
    return;
  }
  if (mode == "selection") {
    mountSolidSelectionDemo(mount);
    return;
  }
  if (mode == "tabs") {
    mountSolidTabsDemo(mount);
    return;
  }
  if (mode == "accordion") {
    mountSolidAccordionDemo(mount);
    return;
  }
  if (mode == "switch") {
    mountSolidSwitchDemo(mount);
    return;
  }
  if (mode == "nesting") {
    mountSolidNestingDemo(mount);
    return;
  }
  if (mode == "toast-modal") {
    mountSolidToastModalDemo(mount);
    return;
  }
  if (mode == "optionbuilder") {
    mountSolidOptionBuilderDemo(mount);
    return;
  }
  if (mode == "1") {
    mountSolidDomDemo(mount);
    return;
  }

  mountSolidCatalogDemo(mount);
}

