import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsCheckboxBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final checked = createSignal(false);
    final indeterminate = createSignal(false);

    final label = web.HTMLLabelElement()
      ..style.display = "inline-flex"
      ..style.alignItems = "center"
      ..style.gap = "10px"
      ..style.cursor = "pointer"
      ..style.userSelect = "none";

    final box = Checkbox(
      checked: () => checked.value,
      setChecked: (next) => checked.value = next,
      indeterminate: () => indeterminate.value,
      setIndeterminate: (next) => indeterminate.value = next,
      ariaLabel: "Accept terms",
    );

    final textEl = web.HTMLSpanElement()..textContent = "Accept terms";
    label.appendChild(box);
    label.appendChild(textEl);

    final mixedBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle indeterminate";
    on(mixedBtn, "click", (_) {
      indeterminate.value = !indeterminate.value;
      if (indeterminate.value) checked.value = false;
    });

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(
      text(
        () =>
            "checked=${checked.value} • indeterminate=${indeterminate.value}",
      ),
    );

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(label);
    root.appendChild(mixedBtn);
    root.appendChild(status);
    return root;
  });
  // #doc:endregion snippet
}

