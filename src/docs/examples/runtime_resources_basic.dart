import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRuntimeResourcesBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final version = createSignal(0);

    final res = createResourceWithSource(
      () => version.value,
      (v) async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        return "result v$v";
      },
    );

    final row = web.HTMLDivElement()..className = "row";
    final refetch = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Refetch";
    on(refetch, "click", (_) => version.value++);
    row.appendChild(refetch);

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() {
      if (res.loading) return "loading…";
      if (res.error != null) return "error: ${res.error}";
      return "value: ${res.value}";
    }));
    row.appendChild(status);

    return row;
  });
  // #doc:endregion snippet
}

