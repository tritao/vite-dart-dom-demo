import "package:web/web.dart" as web;

import "package:dart_web_test/dom_ui/component.dart";
import "package:dart_web_test/dom_ui/dom.dart" as dom;

final class IntroComponent extends Component {
  @override
  web.Element render() {
    final logo = web.HTMLImageElement()
      ..className = "introLogo"
      ..src = "assets/solidus-logo.png"
      ..alt = "Solidus";

    return dom.div(id: "intro-root", className: "container containerWide", children: [
      logo,
      dom.header(
        title: "Solidus (Dart on the web)",
        subtitle:
            "A Solid-style runtime + robust DOM primitives (focus, overlay, positioning, selection) for building high-quality web apps in Dart.",
        actions: [
          dom.linkButton("Docs", href: "?docs=1"),
          dom.linkButton("Labs", href: "?solid=catalog"),
          dom.linkButton("Demos", href: "?demos=1", kind: "primary"),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: "What’s here",
        subtitle: "Docs are copy-paste examples; Labs are conformance/edge-cases; Demos are the original playground apps.",
        children: [
          dom.spacer(),
          dom.list(children: [
            dom.li(
              text:
                  "Docs: API notes + minimal examples (what you’d copy into an app).",
              className: "muted",
            ),
            dom.li(
              text:
                  "Labs: edge cases + Playwright scenarios to harden behavior.",
              className: "muted",
            ),
            dom.li(
              text: "Demos: the original counter/todos/users playground app.",
              className: "muted",
            ),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: "Quick links",
        subtitle: "Direct links into the Solid-style component demos.",
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.linkButton("DropdownMenu", href: "?solid=dropdownmenu"),
            dom.linkButton("Menubar", href: "?solid=menubar"),
            dom.linkButton("ContextMenu", href: "?solid=contextmenu"),
            dom.linkButton("Dialog", href: "?solid=dialog"),
            dom.linkButton("Popover", href: "?solid=popover"),
            dom.linkButton("Tooltip", href: "?solid=tooltip"),
            dom.linkButton("Select", href: "?solid=select"),
            dom.linkButton("Listbox", href: "?solid=listbox"),
            dom.linkButton("Combobox", href: "?solid=combobox"),
            dom.linkButton("Tabs", href: "?solid=tabs"),
            dom.linkButton("Accordion", href: "?solid=accordion"),
            dom.linkButton("Switch", href: "?solid=switch"),
          ]),
        ],
      ),
    ]);
  }
}
