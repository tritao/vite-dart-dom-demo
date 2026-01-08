import "package:web/web.dart" as web;

web.HTMLElement docSection({
  required String title,
  required List<web.Node> children,
  String? id,
}) {
  final section = web.HTMLDivElement()
    ..className = "docSection card";
  if (id != null) section.id = id;
  section.appendChild(web.HTMLHeadingElement.h2()..textContent = title);
  for (final child in children) {
    section.appendChild(child);
  }
  return section;
}

web.HTMLElement docCode(String textContent) {
  final pre = web.document.createElement("pre") as web.HTMLPreElement;
  pre.className = "docCode";
  pre.textContent = textContent;
  return pre;
}

web.HTMLElement docKbd(String label) {
  final el = web.document.createElement("kbd") as web.HTMLElement;
  el.className = "docKbd";
  el.textContent = label;
  return el;
}

web.HTMLElement docTable(List<List<String>> rows) {
  final table = web.document.createElement("table") as web.HTMLTableElement
    ..className = "docTable";
  final tbody = web.document.createElement("tbody") as web.HTMLTableSectionElement;
  for (final row in rows) {
    final tr = web.document.createElement("tr") as web.HTMLTableRowElement;
    for (var i = 0; i < row.length; i++) {
      final cell = web.document.createElement(i == 0 ? "th" : "td") as web.HTMLTableCellElement
        ..textContent = row[i];
      tr.appendChild(cell);
    }
    tbody.appendChild(tr);
  }
  table.appendChild(tbody);
  return table;
}
