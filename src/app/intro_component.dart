import "package:web/web.dart" as web;

import "package:solidus/dom_ui/component.dart";
import "package:solidus/dom_ui/dom.dart" as dom;

final class IntroComponent extends Component {
  @override
  web.Element render() {
    return dom.div(id: "intro-root", className: "container containerWide", children: [
      dom.div(className: "header introHeader", children: [
        dom.div(className: "introTitleRow", children: [
          web.HTMLImageElement()
            ..className = "introTitleLogo"
            ..src = "assets/solidus-mark.png"
            ..alt = "",
          dom.h1("Solidus (Dart on the web)"),
        ]),
        dom.p(
          "A Solid-style runtime + robust DOM primitives (focus, overlay, positioning, selection) for building high-quality web apps in Dart.",
          className: "muted",
        ),
        dom.buttonRow(children: [
          dom.linkButton("Docs", href: "docs.html#/"),
          dom.linkButton("Labs", href: "labs.html?lab=catalog"),
          dom.linkButton("Demos", href: "?demos=1", kind: "primary"),
        ]),
      ]),
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
            dom.linkButton("DropdownMenu", href: "labs.html?lab=dropdownmenu"),
            dom.linkButton("Menubar", href: "labs.html?lab=menubar"),
            dom.linkButton("ContextMenu", href: "labs.html?lab=contextmenu"),
            dom.linkButton("Dialog", href: "labs.html?lab=dialog"),
            dom.linkButton("Popover", href: "labs.html?lab=popover"),
            dom.linkButton("Tooltip", href: "labs.html?lab=tooltip"),
            dom.linkButton("Select", href: "labs.html?lab=select"),
            dom.linkButton("Listbox", href: "labs.html?lab=listbox"),
            dom.linkButton("Combobox", href: "labs.html?lab=combobox"),
            dom.linkButton("Tabs", href: "labs.html?lab=tabs"),
            dom.linkButton("Accordion", href: "labs.html?lab=accordion"),
            dom.linkButton("Switch", href: "labs.html?lab=switch"),
          ]),
        ],
      ),
    ]);
  }
}
