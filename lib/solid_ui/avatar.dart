import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom/solid_dom.dart";

/// Avatar primitive (shadcn-ish).
///
/// - Renders an image when `src` loads, otherwise shows a fallback.
/// - Sets `data-state="loaded" | "error"` on the root for styling/testing.
web.HTMLElement Avatar({
  String? Function()? src,
  String? alt,
  String? Function()? fallback,
  int size = 32,
  String rootClassName = "avatar",
  String imageClassName = "avatarImage",
  String fallbackClassName = "avatarFallback",
}) {
  final srcAccessor = src ?? () => null;
  final fallbackAccessor = fallback ?? () => "";

  final supportedSizes = const <int>{24, 32, 40, 48, 64};
  final resolvedSize = supportedSizes.contains(size) ? size : 32;

  final root = web.HTMLSpanElement()
    ..className = rootClassName
    ..setAttribute("data-size", resolvedSize.toString());

  final img = web.HTMLImageElement()..className = imageClassName;
  if (alt != null && alt.isNotEmpty) img.alt = alt;

  final fb = web.HTMLSpanElement()
    ..className = fallbackClassName
    ..textContent = "";

  root.appendChild(img);
  root.appendChild(fb);

  final state = createSignal("error");

  void setState(String next) {
    if (state.value != next) state.value = next;
  }

  Timer? loadPoll;
  void stopPoll() {
    loadPoll?.cancel();
    loadPoll = null;
  }

  onCleanup(stopPoll);

  // Some browsers may not fire load/error in all caching cases; poll `complete`
  // after setting src as a fallback.
  void startPoll() {
    stopPoll();
    loadPoll = Timer.periodic(const Duration(milliseconds: 50), (_) {
      try {
        if (img.complete) {
          // If naturalWidth is 0, the load failed.
          setState(img.naturalWidth > 0 ? "loaded" : "error");
          stopPoll();
        }
      } catch (_) {}
    });
  }

  on(img, "load", (_) {
    setState("loaded");
  });
  on(img, "error", (_) {
    setState("error");
  });

  createRenderEffect(() {
    final s = srcAccessor();
    final f = fallbackAccessor();
    fb.textContent = f;

    if (s == null || s.trim().isEmpty) {
      img.src = "";
      setState("error");
      return;
    }

    // Assigning the same src can sometimes suppress events; force reload when
    // the value changes.
    if (img.src != s) {
      img.src = s;
      setState("error");
      // Defer polling until the element is connected.
      scheduleMicrotask(() {
        if (!root.isConnected) {
          scheduleMicrotask(() => startPoll());
          return;
        }
        startPoll();
      });
    }
  });

  createRenderEffect(() {
    root.setAttribute("data-state", state.value);
  });

  return root;
}
