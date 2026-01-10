import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsAvatarBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
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

    final avatarsRow = row(children: [ok, broken, initials]);

    final label = p(
      "Image, broken image (fallback), and initials.",
      className: "muted",
    );

    return stack(children: [avatarsRow, label]);
  });
  // #doc:endregion snippet
}
