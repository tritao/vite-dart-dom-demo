import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsSpinnerBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final row = web.HTMLDivElement()..className = "row";
    row.appendChild(Spinner(ariaLabel: "Loading"));
    row.appendChild(web.HTMLSpanElement()..className = "muted"..textContent = "Loading…");
    return row;
  });
  // #doc:endregion snippet
}

