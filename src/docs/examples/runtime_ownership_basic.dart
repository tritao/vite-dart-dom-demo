import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRuntimeOwnershipBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final running = createSignal(false);
    final ticks = createSignal(0);
    final info = createSignal("stopped");

    Dispose? disposeChild;

    void start() {
      if (running.value) return;
      running.value = true;
      info.value = "running";
      disposeChild = createChildRoot((dispose) {
        final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          ticks.value++;
        });
        onCleanup(() => timer.cancel());
        return dispose;
      });
    }

    void stop() {
      if (!running.value) return;
      running.value = false;
      info.value = "stopped";
      disposeChild?.call();
      disposeChild = null;
    }

    onCleanup(stop);

    final row = web.HTMLDivElement()..className = "row";
    final startBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Start";
    on(startBtn, "click", (_) => start());
    row.appendChild(startBtn);

    final stopBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Stop";
    on(stopBtn, "click", (_) => stop());
    row.appendChild(stopBtn);

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "${info.value} • ticks=${ticks.value}"));
    row.appendChild(status);

    return row;
  });
  // #doc:endregion snippet
}

