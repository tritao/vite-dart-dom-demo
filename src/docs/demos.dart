import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./examples/dialog_basic.dart";

typedef DocsDemoMount = Dispose Function(web.Element mount);

final Map<String, DocsDemoMount> docsDemos = {
  "dialog-basic": mountDocsDialogBasic,
};

