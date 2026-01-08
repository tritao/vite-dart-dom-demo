import "package:web/web.dart" as web;

final class DocsPropRow {
  const DocsPropRow({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.notes,
  });

  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
  final String? notes;

  static DocsPropRow fromJson(Map<String, Object?> json) {
    final requiredValue = json["required"];
    final defaultValue = json["default"] ?? json["defaultValue"];
    return DocsPropRow(
      name: (json["name"] as String?) ?? "",
      type: (json["type"] as String?) ?? "",
      required: requiredValue is bool ? requiredValue : false,
      defaultValue: defaultValue is String ? defaultValue : null,
      notes: (json["notes"] as String?) ?? (json["description"] as String?),
    );
  }
}

final class DocsPropsSpec {
  const DocsPropsSpec({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<DocsPropRow> rows;

  static DocsPropsSpec fromJson(Map<String, Object?> json) {
    final rows = <DocsPropRow>[];
    final rawRows = json["rows"];
    if (rawRows is List) {
      for (final r in rawRows) {
        if (r is! Map) continue;
        rows.add(DocsPropRow.fromJson((r as Map).cast<String, Object?>()));
      }
    }
    return DocsPropsSpec(
      title: (json["title"] as String?) ?? "",
      rows: rows,
    );
  }
}

Map<String, DocsPropsSpec> parseDocsPropsJson(Object? decoded) {
  if (decoded is! Map) return const {};
  final out = <String, DocsPropsSpec>{};
  for (final entry in decoded.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String) continue;
    if (value is! Map) continue;
    out[key] = DocsPropsSpec.fromJson((value as Map).cast<String, Object?>());
  }
  return out;
}

web.HTMLElement renderDocsPropsTable(DocsPropsSpec spec) {
  final wrap = web.HTMLDivElement()..className = "docPropsInner";

  final table = web.document.createElement("table") as web.HTMLTableElement
    ..className = "docTable";

  final thead = web.document.createElement("thead") as web.HTMLTableSectionElement;
  final headRow = web.document.createElement("tr") as web.HTMLTableRowElement;
  for (final col in const ["Prop", "Default", "Type"]) {
    final th = web.document.createElement("th") as web.HTMLTableCellElement
      ..textContent = col;
    headRow.appendChild(th);
  }
  thead.appendChild(headRow);
  table.appendChild(thead);

  final tbody = web.document.createElement("tbody") as web.HTMLTableSectionElement;
  for (final row in spec.rows) {
    final tr = web.document.createElement("tr") as web.HTMLTableRowElement;

    final prop = web.document.createElement("td") as web.HTMLTableCellElement;

    final propLine = web.document.createElement("div") as web.HTMLDivElement
      ..className = "docPropLine";
    final propCode = web.document.createElement("code") as web.HTMLElement
      ..textContent = row.name;
    propLine.appendChild(propCode);
    if (row.required) {
      final req = web.document.createElement("span") as web.HTMLElement
        ..className = "docReq"
        ..textContent = "required";
      propLine.appendChild(web.Text(" "));
      propLine.appendChild(req);
    }
    prop.appendChild(propLine);

    final notesText = (row.notes ?? "").trim();
    if (notesText.isNotEmpty) {
      final notes = web.document.createElement("div") as web.HTMLDivElement
        ..className = "docPropNotes"
        ..textContent = notesText;
      prop.appendChild(notes);
    }
    tr.appendChild(prop);

    final def = web.document.createElement("td") as web.HTMLTableCellElement;
    final defaultValue = row.defaultValue ?? (row.required ? "—" : "null");
    final defCode = web.document.createElement("code") as web.HTMLElement
      ..textContent = defaultValue;
    def.appendChild(defCode);
    tr.appendChild(def);

    final type = web.document.createElement("td") as web.HTMLTableCellElement;
    final typeCode = web.document.createElement("code") as web.HTMLElement
      ..textContent = row.type;
    type.appendChild(typeCode);
    tr.appendChild(type);

    tbody.appendChild(tr);
  }
  table.appendChild(tbody);

  final foot = web.HTMLParagraphElement()
    ..className = "muted"
    ..textContent = "* required";

  wrap.appendChild(table);
  wrap.appendChild(foot);
  return wrap;
}
