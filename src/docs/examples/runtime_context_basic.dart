import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

final _NameContext = createContext<String>("(default)");

Dispose mountDocsRuntimeContextBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    web.HTMLElement renderReader(String label) {
      final p = web.HTMLParagraphElement()..className = "muted";
      p.appendChild(text(() => "$label: ${useContext(_NameContext)}"));
      return p;
    }

    final root = web.HTMLDivElement();
    root.appendChild(renderReader("Outside provider"));

    final card = web.HTMLDivElement()..className = "card";
    provideContext<String, void>(_NameContext, "provided", () {
      card.appendChild(renderReader("Inside provider"));
    });
    root.appendChild(card);

    return root;
  });
  // #doc:endregion snippet
}

