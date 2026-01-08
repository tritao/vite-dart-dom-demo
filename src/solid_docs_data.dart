final class DocsEntry {
  const DocsEntry({
    required this.key,
    required this.label,
    required this.labHref,
  });

  final String key;
  final String label;
  final String labHref;
}

final class DocsGroup {
  const DocsGroup({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<DocsEntry> entries;
}

const docsGroups = <DocsGroup>[
  DocsGroup(
    label: "Foundations",
    entries: [
      DocsEntry(key: "overlay", label: "Overlay", labHref: "/?solid=overlay"),
      DocsEntry(key: "focus-scope", label: "FocusScope", labHref: "/?solid=dialog"),
      DocsEntry(
        key: "interact-outside",
        label: "InteractOutside",
        labHref: "/?solid=popover",
      ),
      DocsEntry(key: "popper", label: "Popper/Positioning", labHref: "/?solid=popover"),
      DocsEntry(key: "selection-core", label: "Selection core", labHref: "/?solid=selection"),
    ],
  ),
  DocsGroup(
    label: "Overlays & Menus",
    entries: [
      DocsEntry(key: "dialog", label: "Dialog", labHref: "/?solid=dialog"),
      DocsEntry(key: "popover", label: "Popover", labHref: "/?solid=popover"),
      DocsEntry(key: "tooltip", label: "Tooltip", labHref: "/?solid=tooltip"),
      DocsEntry(
        key: "dropdownmenu",
        label: "DropdownMenu",
        labHref: "/?solid=dropdownmenu",
      ),
      DocsEntry(key: "menubar", label: "Menubar", labHref: "/?solid=menubar"),
      DocsEntry(
        key: "contextmenu",
        label: "ContextMenu",
        labHref: "/?solid=contextmenu",
      ),
      DocsEntry(key: "toast", label: "Toast", labHref: "/?solid=toast"),
    ],
  ),
  DocsGroup(
    label: "Selection",
    entries: [
      DocsEntry(key: "select", label: "Select", labHref: "/?solid=select"),
      DocsEntry(key: "listbox", label: "Listbox", labHref: "/?solid=listbox"),
      DocsEntry(key: "combobox", label: "Combobox", labHref: "/?solid=combobox"),
    ],
  ),
  DocsGroup(
    label: "Navigation",
    entries: [
      DocsEntry(key: "tabs", label: "Tabs", labHref: "/?solid=tabs"),
      DocsEntry(key: "accordion", label: "Accordion", labHref: "/?solid=accordion"),
    ],
  ),
  DocsGroup(
    label: "Forms",
    entries: [
      DocsEntry(key: "switch", label: "Switch", labHref: "/?solid=switch"),
    ],
  ),
];

DocsEntry? findDocsEntry(String key) {
  for (final group in docsGroups) {
    for (final entry in group.entries) {
      if (entry.key == key) return entry;
    }
  }
  return null;
}

