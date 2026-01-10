import "dart:async";

import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
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

    final controls = row(children: [startBtn, stopBtn, toggleBtn]);

    final status = p(
      "",
      className: "muted",
      children: [
        text(
          () =>
              "value=${value.value?.toStringAsFixed(0) ?? "indeterminate"}",
        ),
      ],
    );

    final root = stack(children: [
      controls,
      determinate,
      indeterminate,
      status,
    ])..style.maxWidth = "520px";
    return root;
  });
  // #doc:endregion snippet
}
