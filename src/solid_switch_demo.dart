import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidSwitchDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "switch-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "switch"));

    final checked = createSignal(false);
    final disabled = createSignal(false);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Switch Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Click toggles; Enter/Space toggles when focused.",
          "Tab to the switch and verify focus ring.",
          "Disable it: it should not toggle via click or keyboard.",
        ],
      ),
    );

    final controls = web.HTMLDivElement()..className = "row";

    final disableBtn = web.HTMLButtonElement()
      ..id = "switch-disable-toggle"
      ..type = "button"
      ..className = "btn secondary";
    createRenderEffect(() {
      disableBtn.textContent = disabled.value ? "Enable switch" : "Disable switch";
    });
    on(disableBtn, "click", (_) => disabled.value = !disabled.value);
    controls.appendChild(disableBtn);

    root.appendChild(controls);

    final status = web.HTMLParagraphElement()
      ..id = "switch-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Checked: ${checked.value ? "true" : "false"} • Disabled: ${disabled.value ? "true" : "false"}",
      ),
    );
    root.appendChild(status);

    final sw = Switch(
      id: "switch-control",
      ariaLabel: "Demo switch",
      checked: () => checked.value,
      setChecked: (next) => checked.value = next,
      disabled: () => disabled.value,
    );

    final label = web.HTMLLabelElement()
      ..htmlFor = "switch-control"
      ..textContent = "Notifications";

    final row = web.HTMLDivElement()
      ..className = "switchRow";
    row.appendChild(sw);
    row.appendChild(label);

    root.appendChild(row);

    return root;
  });
}

