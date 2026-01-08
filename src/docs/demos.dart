import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./examples/dialog_basic.dart";
import "./examples/overlay_basic.dart";
import "./examples/focus_scope_basic.dart";
import "./examples/interact_outside_basic.dart";
import "./examples/popper_basic.dart";
import "./examples/selection_core_basic.dart";
import "./examples/runtime_reactivity_basic.dart";
import "./examples/runtime_ownership_basic.dart";
import "./examples/runtime_dom_basic.dart";
import "./examples/runtime_resources_basic.dart";
import "./examples/runtime_context_basic.dart";

typedef DocsDemoMount = Dispose Function(web.Element mount);

final Map<String, DocsDemoMount> docsDemos = {
  "dialog-basic": mountDocsDialogBasic,
  "overlay-basic": mountDocsOverlayBasic,
  "focus-scope-basic": mountDocsFocusScopeBasic,
  "interact-outside-basic": mountDocsInteractOutsideBasic,
  "popper-basic": mountDocsPopperBasic,
  "selection-core-basic": mountDocsSelectionCoreBasic,
  "runtime-reactivity-basic": mountDocsRuntimeReactivityBasic,
  "runtime-ownership-basic": mountDocsRuntimeOwnershipBasic,
  "runtime-dom-basic": mountDocsRuntimeDomBasic,
  "runtime-resources-basic": mountDocsRuntimeResourcesBasic,
  "runtime-context-basic": mountDocsRuntimeContextBasic,
};
