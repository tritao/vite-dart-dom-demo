import "package:web/web.dart" as web;

/// ScrollArea primitive (unstyled).
///
/// Returns the root element and exposes the viewport/content for composition.
final class ScrollAreaHandle {
  ScrollAreaHandle({
    required this.root,
    required this.viewport,
    required this.content,
  });

  final web.HTMLElement root;
  final web.HTMLElement viewport;
  final web.HTMLElement content;
}

ScrollAreaHandle createScrollArea({
  String? id,
  String rootClassName = "",
  String viewportClassName = "",
  String contentClassName = "",
}) {
  final root = web.HTMLDivElement()
    ..id = id ?? ""
    ..className = rootClassName
    ..setAttribute("data-solidus-scroll-area", "1");

  final viewport = web.HTMLDivElement()
    ..className = viewportClassName
    ..setAttribute("data-solidus-scroll-viewport", "1");

  final content = web.HTMLDivElement()
    ..className = contentClassName
    ..setAttribute("data-solidus-scroll-content", "1");

  viewport.appendChild(content);
  root.appendChild(viewport);
  return ScrollAreaHandle(root: root, viewport: viewport, content: content);
}

