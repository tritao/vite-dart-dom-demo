import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRadioGroupBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal("email");

    final label = web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Delivery method";

    web.HTMLButtonElement item(String text) =>
        web.HTMLButtonElement()..type = "button"..textContent = text;

    final group = RadioGroup(
      ariaLabel: "Delivery method",
      value: () => value.value,
      setValue: (next) => value.value = next,
      items: [
        RadioGroupItem(key: "email", item: item("Email")),
        RadioGroupItem(key: "sms", item: item("SMS")),
        RadioGroupItem(
          key: "push",
          item: item("Push (disabled)"),
          disabled: true,
        ),
      ],
    );

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "value=${value.value}"));

    final root = web.HTMLDivElement()..className = "stack";
    root.appendChild(label);
    root.appendChild(group);
    root.appendChild(status);
    return root;
  });
  // #doc:endregion snippet
}
