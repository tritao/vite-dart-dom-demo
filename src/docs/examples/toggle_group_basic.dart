import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsToggleGroupBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final single = createSignal<String?>("bold");
    final multi = createSignal<Set<String>>({"left"});

    web.HTMLButtonElement item(String text) =>
        web.HTMLButtonElement()..type = "button"..textContent = text;

    final singleGroup = ToggleGroup(
      ariaLabel: "Text style",
      type: () => ToggleGroupType.single,
      value: () => single.value,
      setValue: (next) => single.value = next,
      items: [
        ToggleGroupItem(key: "bold", item: item("Bold")),
        ToggleGroupItem(key: "italic", item: item("Italic")),
        ToggleGroupItem(
          key: "underline",
          item: item("Underline (disabled)"),
          disabled: true,
        ),
      ],
    );

    final multiGroup = ToggleGroup(
      ariaLabel: "Alignment",
      type: () => ToggleGroupType.multiple,
      values: () => multi.value,
      setValues: (next) => multi.value = next,
      items: [
        ToggleGroupItem(key: "left", item: item("Left")),
        ToggleGroupItem(key: "center", item: item("Center")),
        ToggleGroupItem(key: "right", item: item("Right")),
      ],
    );

    final status = p(
      "",
      className: "muted",
      children: [
        text(
          () =>
              "single=${single.value ?? "none"} • multi=${multi.value.join(",")}",
        ),
      ],
    );

    return stack(children: [
      p("Single (toggleable)", className: "muted"),
      singleGroup,
      p("Multiple", className: "muted"),
      multiGroup,
      status,
    ]);
  });
  // #doc:endregion snippet
}
