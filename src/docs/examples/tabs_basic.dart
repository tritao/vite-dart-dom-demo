import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsTabsBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal("tab-a");

    TabsItem item(String key, String label, String content) {
      final trigger = web.HTMLButtonElement()
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      final panel = web.HTMLDivElement()..textContent = content;
      return TabsItem(key: key, trigger: trigger, panel: panel);
    }

    final tabs = Tabs(
      items: [
        item("tab-a", "Account", "Account settings panel."),
        item("tab-b", "Billing", "Billing panel."),
        item("tab-c", "Security", "Security panel."),
      ],
      value: () => value.value,
      setValue: (next) => value.value = next,
    );

    return tabs;
  });
  // #doc:endregion snippet
}

