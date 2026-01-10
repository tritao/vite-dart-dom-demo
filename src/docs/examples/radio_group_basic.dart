import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRadioGroupBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal("email");

    final label = p("Delivery method", className: "muted");

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

    final status =
        p("", className: "muted", children: [text(() => "value=${value.value}")]);

    return stack(children: [label, group, status]);
  });
  // #doc:endregion snippet
}
