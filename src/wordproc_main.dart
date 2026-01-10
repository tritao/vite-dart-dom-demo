import "package:web/web.dart" as web;

import "package:solidus/wordproc/wordproc.dart";

void main() {
  final mount = web.document.querySelector("#app");
  if (mount == null) return;
  mountWordprocShellDemo(mount);
}
