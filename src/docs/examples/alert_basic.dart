import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsAlertBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
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

    return stack(children: [normal, destructive]);
  });
  // #doc:endregion snippet
}
