import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsAvatarBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final row = web.HTMLDivElement()..className = "row";

    final ok = Avatar(
      src: () => "assets/solidus-small-logo.png",
      alt: "Solidus",
      fallback: () => "S",
      size: 40,
    )..setAttribute("data-test", "ok");

    final broken = Avatar(
      src: () => "assets/does-not-exist.png",
      alt: "Broken",
      fallback: () => "BK",
      size: 40,
    )..setAttribute("data-test", "broken");

    final initials = Avatar(
      src: () => null,
      alt: "No image",
      fallback: () => "JD",
      size: 40,
    )..setAttribute("data-test", "initials");

    row.appendChild(ok);
    row.appendChild(broken);
    row.appendChild(initials);

    final label = web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Image, broken image (fallback), and initials.";

    final root = web.HTMLDivElement()..className = "stack";
    root.appendChild(row);
    root.appendChild(label);
    return root;
  });
  // #doc:endregion snippet
}

