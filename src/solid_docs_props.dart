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
}

final class DocsPropsSpec {
  const DocsPropsSpec({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<DocsPropRow> rows;
}

final Map<String, DocsPropsSpec> docsProps = {
  "Dialog": DocsPropsSpec(
    title: "Dialog",
    rows: [
      DocsPropRow(
        name: "open",
        type: "bool Function()",
        required: true,
        notes: "Controls visibility.",
      ),
      DocsPropRow(
        name: "setOpen",
        type: "void Function(bool next)",
        required: true,
        notes: "Called on dismiss/close; update your signal/state here.",
      ),
      DocsPropRow(
        name: "builder",
        type: "DialogBuilder (close) → HTMLElement",
        required: true,
        notes: "Builds the dialog content; call close(reason?) to dismiss.",
      ),
      DocsPropRow(
        name: "onClose",
        type: "void Function(String reason)?",
        notes: "Dismiss reason: escape/outside/close/etc (implementation-defined).",
      ),
      DocsPropRow(
        name: "modal",
        type: "bool",
        defaultValue: "true",
        notes:
            "When true: traps focus, disables outside pointer events, scroll-locks, and aria-hides outside content.",
      ),
      DocsPropRow(
        name: "backdrop",
        type: "bool",
        defaultValue: "false",
        notes: "Renders a backdrop element behind the dialog panel.",
      ),
      DocsPropRow(
        name: "exitMs",
        type: "int",
        defaultValue: "120",
        notes: "Presence exit duration for animations.",
      ),
      DocsPropRow(
        name: "initialFocus",
        type: "HTMLElement?",
        notes: "Element to focus on open (modal focus-scope only).",
      ),
      DocsPropRow(
        name: "restoreFocus",
        type: "bool",
        defaultValue: "true",
        notes: "Restore focus to the previously focused element on close.",
      ),
      DocsPropRow(
        name: "onOpenAutoFocus",
        type: "void Function(FocusScopeAutoFocusEvent event)?",
        notes: "Preventable hook to customize autofocus on mount.",
      ),
      DocsPropRow(
        name: "onCloseAutoFocus",
        type: "void Function(FocusScopeAutoFocusEvent event)?",
        notes: "Preventable hook to customize autofocus on unmount.",
      ),
      DocsPropRow(
        name: "labelledBy",
        type: "String?",
        notes: "Sets aria-labelledby on the dialog content.",
      ),
      DocsPropRow(
        name: "describedBy",
        type: "String?",
        notes: "Sets aria-describedby on the dialog content.",
      ),
      DocsPropRow(
        name: "role",
        type: "String",
        defaultValue: "\"dialog\"",
        notes: "Use \"alertdialog\" for urgent confirmations.",
      ),
      DocsPropRow(
        name: "portalId",
        type: "String?",
        notes: "Optional id for the Portal container.",
      ),
    ],
  ),
};

web.HTMLElement renderDocsPropsTable(DocsPropsSpec spec) {
  final wrap = web.HTMLDivElement()..className = "docPropsInner";

  final table = web.document.createElement("table") as web.HTMLTableElement
    ..className = "docTable";

  final thead = web.document.createElement("thead") as web.HTMLTableSectionElement;
  final headRow = web.document.createElement("tr") as web.HTMLTableRowElement;
  for (final col in const ["Prop", "Type", "Default", "Notes"]) {
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
    final propName = row.required ? "${row.name} *" : row.name;
    prop.textContent = propName;
    tr.appendChild(prop);

    final type = web.document.createElement("td") as web.HTMLTableCellElement;
    type.textContent = row.type;
    tr.appendChild(type);

    final def = web.document.createElement("td") as web.HTMLTableCellElement;
    def.textContent = row.defaultValue ?? (row.required ? "—" : "null");
    tr.appendChild(def);

    final notes = web.document.createElement("td") as web.HTMLTableCellElement;
    notes.textContent = row.notes ?? "";
    tr.appendChild(notes);

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

