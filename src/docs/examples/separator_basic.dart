import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsSeparatorBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final card = web.HTMLDivElement()..className = "card";
    card.appendChild(web.HTMLHeadingElement.h2()..textContent = "Separator");

    final p1 = web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Horizontal";
    card.appendChild(p1);
    card.appendChild(Separator(decorative: true));
    card.appendChild(web.HTMLParagraphElement()..textContent = "Below the line");

    card.appendChild(web.HTMLDivElement()..className = "spacer");

    final p2 = web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Vertical (inside a row)";
    card.appendChild(p2);

    final row = web.HTMLDivElement()
      ..className = "row"
      ..style.alignItems = "stretch";
    row.appendChild(web.HTMLSpanElement()..textContent = "Left");
    final v = Separator(orientation: SeparatorOrientation.vertical, decorative: true);
    v.style.height = "24px";
    row.appendChild(v);
    row.appendChild(web.HTMLSpanElement()..textContent = "Right");
    card.appendChild(row);

    return card;
  });
  // #doc:endregion snippet
}
