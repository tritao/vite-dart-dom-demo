import "package:web/web.dart" as web;

web.HTMLElement labsDemoHelp({
  required String title,
  required List<String> bullets,
}) {
  final wrap = web.HTMLDivElement()..className = "card demoHelp";

  wrap.appendChild(web.HTMLHeadingElement.h2()..textContent = title);

  final ul = web.HTMLUListElement();
  for (final b in bullets) {
    ul.appendChild(web.HTMLLIElement()..textContent = b);
  }
  wrap.appendChild(ul);

  return wrap;
}
