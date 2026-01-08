import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRuntimeReactivityBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final count = createSignal(0);
    final doubled = createMemo(() => count.value * 2);

    final row = web.HTMLDivElement()..className = "row";
    final inc = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Increment";
    on(inc, "click", (_) => count.value++);
    row.appendChild(inc);

    final dec = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Decrement";
    on(dec, "click", (_) => count.value--);
    row.appendChild(dec);

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "count=${count.value} • doubled=${doubled.value}"));
    row.appendChild(status);

    return row;
  });
  // #doc:endregion snippet
}

