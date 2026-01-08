import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidTabsDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "tabs-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "tabs"));

    final value = createSignal<String?>("account");
    final activation = createSignal(TabsActivationMode.automatic);
    final orientation = createSignal(Orientation.horizontal);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Tabs Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Tab to the tablist; use Arrow keys + Home/End (disabled tab is skipped).",
          "Automatic activation: arrows change selection immediately.",
          "Manual activation: arrows move focus; Enter/Space activates the focused tab.",
          "Tab moves into the panel content; Shift+Tab returns to the active tab.",
        ],
      ),
    );

    final controls = web.HTMLDivElement()..className = "row";

    web.HTMLButtonElement pill(
      String label, {
      required String id,
      required void Function() onClick,
    }) {
      final el = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      on(el, "click", (_) => onClick());
      return el;
    }

    controls.appendChild(
      pill(
        "Activation: automatic",
        id: "tabs-activation-automatic",
        onClick: () => activation.value = TabsActivationMode.automatic,
      ),
    );
    controls.appendChild(
      pill(
        "Activation: manual",
        id: "tabs-activation-manual",
        onClick: () => activation.value = TabsActivationMode.manual,
      ),
    );
    controls.appendChild(
      pill(
        "Horizontal",
        id: "tabs-orientation-horizontal",
        onClick: () => orientation.value = Orientation.horizontal,
      ),
    );
    controls.appendChild(
      pill(
        "Vertical",
        id: "tabs-orientation-vertical",
        onClick: () => orientation.value = Orientation.vertical,
      ),
    );

    root.appendChild(controls);

    final status = web.HTMLParagraphElement()
      ..id = "tabs-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Value: ${value.value ?? "none"} • Activation: ${activation.value.name} • Orientation: ${orientation.value.name}",
      ),
    );
    root.appendChild(status);

    web.HTMLButtonElement tab(String id, String label, {bool disabled = false}) {
      final el = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "tabsTrigger"
        ..textContent = label;
      if (disabled) {
        el.disabled = true;
        el.setAttribute("aria-disabled", "true");
      }
      return el;
    }

    web.HTMLElement panel(String id, String title, String body) {
      final el = web.HTMLDivElement()
        ..id = id
        ..className = "card";

      el.appendChild(web.HTMLHeadingElement.h2()..textContent = title);
      el.appendChild(web.HTMLParagraphElement()..textContent = body);

      final input = web.HTMLInputElement()
        ..id = "$id-input"
        ..className = "input"
        ..placeholder = "Focusable input in $title";
      el.appendChild(input);

      return el;
    }

    web.HTMLElement buildTabs() {
      final accountTab = tab("tabs-account", "Account");
      final passwordTab = tab("tabs-password", "Password");
      final disabledTab = tab("tabs-billing", "Billing (disabled)", disabled: true);

      final accountPanel = panel(
        "tabs-panel-account",
        "Account",
        "Account settings panel. Tab here to validate focus moves into content.",
      );
      final passwordPanel = panel(
        "tabs-panel-password",
        "Password",
        "Password settings panel. Shift+Tab should bring focus back to the active tab.",
      );
      final billingPanel = panel(
        "tabs-panel-billing",
        "Billing",
        "Disabled tab panel (should never be reachable).",
      );

      return Tabs(
        id: "tabs-demo",
        ariaLabel: "Settings tabs",
        activationMode: () => activation.value,
        orientation: () => orientation.value,
        value: () => value.value,
        setValue: (next) => value.value = next,
        items: [
          TabsItem(
            key: "account",
            trigger: accountTab,
            panel: accountPanel,
            textValue: "Account",
          ),
          TabsItem(
            key: "password",
            trigger: passwordTab,
            panel: passwordPanel,
            textValue: "Password",
          ),
          TabsItem(
            key: "billing",
            trigger: disabledTab,
            panel: billingPanel,
            disabled: true,
            textValue: "Billing",
          ),
        ],
      );
    }

    final host = web.HTMLDivElement()..id = "tabs-host";
    host.appendChild(buildTabs());
    root.appendChild(host);

    return root;
  });
}
