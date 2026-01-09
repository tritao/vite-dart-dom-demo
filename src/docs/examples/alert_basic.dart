import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsAlertBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final stack = web.HTMLDivElement()..className = "stack";

    final normal = Alert(
      children: [
        AlertTitle("Heads up!"),
        AlertDescription("This is a default alert with some helpful context."),
      ],
    )..setAttribute("data-test", "default");

    final destructive = Alert(
      variant: AlertVariant.destructive,
      children: [
        AlertTitle("Something went wrong"),
        AlertDescription("There was a problem processing your request."),
      ],
    )..setAttribute("data-test", "destructive");

    stack.appendChild(normal);
    stack.appendChild(destructive);
    return stack;
  });
  // #doc:endregion snippet
}
