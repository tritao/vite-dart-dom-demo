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
          dom.linkButton("Docs", href: "?docs=1"),
          dom.linkButton("Labs", href: "?lab=catalog"),
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
            dom.linkButton("DropdownMenu", href: "?lab=dropdownmenu"),
            dom.linkButton("Menubar", href: "?lab=menubar"),
            dom.linkButton("ContextMenu", href: "?lab=contextmenu"),
            dom.linkButton("Dialog", href: "?lab=dialog"),
            dom.linkButton("Popover", href: "?lab=popover"),
            dom.linkButton("Tooltip", href: "?lab=tooltip"),
            dom.linkButton("Select", href: "?lab=select"),
            dom.linkButton("Listbox", href: "?lab=listbox"),
            dom.linkButton("Combobox", href: "?lab=combobox"),
            dom.linkButton("Tabs", href: "?lab=tabs"),
            dom.linkButton("Accordion", href: "?lab=accordion"),
            dom.linkButton("Switch", href: "?lab=switch"),
          ]),
        ],
      ),
    ]);
  }
}
