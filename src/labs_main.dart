import "package:web/web.dart" as web;

import "./labs/dom_demo.dart";
import "./labs/overlay_demo.dart";
import "./labs/dialog_demo.dart";
import "./labs/popover_demo.dart";
import "./labs/roving_demo.dart";
import "./labs/toast_demo.dart";
import "./labs/catalog_demo.dart";
import "./labs/dropdown_menu_demo.dart";
import "./labs/menubar_demo.dart";
import "./labs/context_menu_demo.dart";
import "./labs/tooltip_demo.dart";
import "./labs/select_demo.dart";
import "./labs/combobox_demo.dart";
import "./labs/listbox_demo.dart";
import "./labs/selection_demo.dart";
import "./labs/tabs_demo.dart";
import "./labs/accordion_demo.dart";
import "./labs/switch_demo.dart";
import "./labs/nesting_demo.dart";
import "./labs/toast_modal_demo.dart";
import "./labs/optionbuilder_demo.dart";
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
  if (docs != null) {
    web.window.location.assign("docs.html$search");
    return;
  }
  if (demos != null) {
    web.window.location.assign("./$search");
    return;
  }

  final mode = lab ?? "catalog";

  if (mode == "overlay") {
    mountLabsOverlayDemo(mount);
    return;
  }
  if (mode == "dialog") {
    mountLabsDialogDemo(mount);
    return;
  }
  if (mode == "popover") {
    mountLabsPopoverDemo(mount);
    return;
  }
  if (mode == "roving") {
    mountLabsRovingDemo(mount);
    return;
  }
  if (mode == "toast") {
    mountLabsToastDemo(mount);
    return;
  }
  if (mode == "catalog") {
    mountLabsCatalogDemo(mount);
    return;
  }
  if (mode == "dropdownmenu") {
    mountLabsDropdownMenuDemo(mount);
    return;
  }
  if (mode == "menubar") {
    mountLabsMenubarDemo(mount);
    return;
  }
  if (mode == "contextmenu") {
    mountLabsContextMenuDemo(mount);
    return;
  }
  if (mode == "tooltip") {
    mountLabsTooltipDemo(mount);
    return;
  }
  if (mode == "select") {
    mountLabsSelectDemo(mount);
    return;
  }
  if (mode == "combobox") {
    mountLabsComboboxDemo(mount);
    return;
  }
  if (mode == "listbox") {
    mountLabsListboxDemo(mount);
    return;
  }
  if (mode == "selection") {
    mountLabsSelectionDemo(mount);
    return;
  }
  if (mode == "tabs") {
    mountLabsTabsDemo(mount);
    return;
  }
  if (mode == "accordion") {
    mountLabsAccordionDemo(mount);
    return;
  }
  if (mode == "switch") {
    mountLabsSwitchDemo(mount);
    return;
  }
  if (mode == "nesting") {
    mountLabsNestingDemo(mount);
    return;
  }
  if (mode == "toast-modal") {
    mountLabsToastModalDemo(mount);
    return;
  }
  if (mode == "optionbuilder") {
    mountLabsOptionBuilderDemo(mount);
    return;
  }
  if (mode == "dom") {
    mountLabsDomDemo(mount);
    return;
  }

  mountLabsCatalogDemo(mount);
}
