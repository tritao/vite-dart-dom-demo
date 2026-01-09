import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsProgressBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal<double?>(25);

    Timer? timer;
    onCleanup(() {
      timer?.cancel();
      timer = null;
    });

    void start() {
      timer?.cancel();
      timer = Timer.periodic(const Duration(milliseconds: 160), (_) {
        final v = value.value;
        if (v == null) return;
        final next = (v + 7) % 101;
        value.value = next.toDouble();
      });
    }

    void stop() {
      timer?.cancel();
      timer = null;
    }

    final determinate = Progress(
      ariaLabel: "Download progress",
      value: () => value.value,
      max: () => 100,
    );

    final indeterminate = Progress(
      ariaLabel: "Loading",
      value: () => null,
    );

    final row = web.HTMLDivElement()..className = "row";
    final startBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Start";
    on(startBtn, "click", (_) => start());
    final stopBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Stop";
    on(stopBtn, "click", (_) => stop());
    final toggleBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn outline"
      ..textContent = "Toggle indeterminate";
    on(toggleBtn, "click", (_) {
      value.value = value.value == null ? 25 : null;
    });

    row.appendChild(startBtn);
    row.appendChild(stopBtn);
    row.appendChild(toggleBtn);

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "value=${value.value?.toStringAsFixed(0) ?? "indeterminate"}"));

    final stack = web.HTMLDivElement()
      ..className = "stack"
      ..style.maxWidth = "520px";
    stack.appendChild(row);
    stack.appendChild(determinate);
    stack.appendChild(indeterminate);
    stack.appendChild(status);
    return stack;
  });
  // #doc:endregion snippet
}
