import "dart:async";
import "dart:convert";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";
import "package:web/web.dart" as web;

import "./editor_bridge.dart";

final class WordprocSection {
  WordprocSection({required this.id, required this.title});
  final String id;
  final String title;
}

const _storageKey = "wordproc.v1";
const _storageVersion = 2;

String _defaultDocJson(WordprocSection section) {
  return jsonEncode({
    "type": "doc",
    "content": [
      {
        "type": "heading",
        "attrs": {"level": 2},
        "content": [
          {"type": "text", "text": section.title}
        ],
      },
      {
        "type": "paragraph",
        "content": [
          {
            "type": "text",
            "text": "Start writing here…",
          }
        ],
      },
    ],
  });
}

List<WordprocSection> _defaultOutline() =>
    <WordprocSection>[WordprocSection(id: "sec-1", title: "Chapter 1")];

({
  int version,
  String? selectedId,
  List<WordprocSection> outline,
  Map<String, String> docsById
}) _loadPersisted() {
  final storage = web.window.localStorage;
  if (storage == null)
    return (
      version: _storageVersion,
      selectedId: null,
      outline: _defaultOutline(),
      docsById: <String, String>{},
    );
  final raw = storage.getItem(_storageKey);
  if (raw == null || raw.isEmpty)
    return (
      version: _storageVersion,
      selectedId: null,
      outline: _defaultOutline(),
      docsById: <String, String>{},
    );

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map)
      return (
        version: _storageVersion,
        selectedId: null,
        outline: _defaultOutline(),
        docsById: <String, String>{},
      );

    final version = (decoded["v"] as num?)?.toInt() ?? 1;
    final selectedId = decoded["selectedId"] as String?;

    final outline = <WordprocSection>[];
    final rawOutline = decoded["outline"];
    if (rawOutline is List) {
      for (final entry in rawOutline) {
        if (entry is! Map) continue;
        final id = entry["id"];
        final title = entry["title"];
        if (id is String && id.isNotEmpty) {
          outline.add(
            WordprocSection(
              id: id,
              title: title is String && title.isNotEmpty ? title : id,
            ),
          );
        }
      }
    }
    if (outline.isEmpty) outline.addAll(_defaultOutline());

    final docs = <String, String>{};
    final rawDocs = decoded["docs"];
    if (rawDocs is Map) {
      for (final entry in rawDocs.entries) {
        final k = entry.key.toString();
        final v = entry.value;
        if (v is String && v.isNotEmpty) docs[k] = v;
      }
    }
    return (
      version: version,
      selectedId: selectedId,
      outline: outline,
      docsById: docs,
    );
  } catch (_) {
    return (
      version: _storageVersion,
      selectedId: null,
      outline: _defaultOutline(),
      docsById: <String, String>{},
    );
  }
}

void _persist({
  required String selectedId,
  required List<WordprocSection> outline,
  required Map<String, String> docsById,
}) {
  final storage = web.window.localStorage;
  if (storage == null) return;
  storage.setItem(
    _storageKey,
    jsonEncode({
      "v": _storageVersion,
      "selectedId": selectedId,
      "outline": outline.map((s) => {"id": s.id, "title": s.title}).toList(),
      "docs": docsById,
    }),
  );
}

void mountSolidWordprocShellDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "wordproc-root"
      ..className = "wordproc";

    root.appendChild(solidDemoNav(active: "wordproc"));
    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Wordproc Shell Demo",
    );

    final persisted = _loadPersisted();
    final docsById = Map<String, String>.from(persisted.docsById);
    final sections = createSignal<List<WordprocSection>>(persisted.outline);

    final query = createSignal("");
    final filtered = createSignal<List<WordprocSection>>(sections.value);
    final selectedId = createSignal(
      sections.value.any((s) => s.id == persisted.selectedId)
          ? persisted.selectedId!
          : sections.value.first.id,
    );
    final selectedTitle = createMemo(() {
      final id = selectedId.value;
      for (final s in sections.value) {
        if (s.id == id) return s.title;
      }
      return id;
    });

    final heavyMounted = createSignal(false);
    final cleanupCount = createSignal(0);
    final editorReady = createSignal(false);
    Timer? persistTimer;

    createEffect(() {
      final q = query.value.trim().toLowerCase();
      final all = sections.value;
      if (q.isEmpty) {
        filtered.value = all;
        return;
      }
      final next = all
          .where((s) => s.title.toLowerCase().contains(q) || s.id.contains(q))
          .toList(growable: false);
      filtered.value = next;
      final currentSelected = untrack(() => selectedId.value);
      if (next.isNotEmpty && !next.any((s) => s.id == currentSelected)) {
        selectedId.value = next.first.id;
      }
    });

    final chrome = web.HTMLDivElement()..className = "wordproc-chrome";

    late final web.HTMLInputElement searchInput;

    final toolbar = web.HTMLDivElement()
      ..className = "wordproc-toolbar"
      ..setAttribute("role", "toolbar");
    final addSection = web.HTMLButtonElement()
      ..id = "wordproc-add-section"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "New section";
    final toggleHeavy = web.HTMLButtonElement()
      ..id = "wordproc-toggle-heavy"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle heavy subtree";
    on(toggleHeavy, "click", (_) => heavyMounted.value = !heavyMounted.value);

    int nextSectionNumber() {
      var max = 0;
      for (final s in sections.value) {
        final m = RegExp(r"^sec-(\d+)$").firstMatch(s.id);
        final n = int.tryParse(m?.group(1) ?? "");
        if (n != null && n > max) max = n;
      }
      return max + 1;
    }

    on(addSection, "click", (_) {
      final n = nextSectionNumber();
      final id = "sec-$n";
      final title = "Section $n";
      final next = <WordprocSection>[
        ...sections.value,
        WordprocSection(id: id, title: title),
      ];
      sections.value = next;
      selectedId.value = id;
      query.value = "";
      if (searchInput.isConnected) searchInput.value = "";
      docsById.putIfAbsent(
        id,
        () => _defaultDocJson(WordprocSection(id: id, title: title)),
      );

      persistTimer?.cancel();
      persistTimer = Timer(
        const Duration(milliseconds: 50),
        () => _persist(selectedId: id, outline: sections.value, docsById: docsById),
      );
    });

    final status = web.HTMLParagraphElement()
      ..id = "wordproc-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Selected: ${selectedId.value} · Cleanup: ${cleanupCount.value}"),
    );

    toolbar.appendChild(addSection);
    toolbar.appendChild(toggleHeavy);
    toolbar.appendChild(status);
    chrome.appendChild(toolbar);

    final layout = web.HTMLDivElement()
      ..id = "wordproc-layout"
      ..className = "wordproc-layout";

    // Outliner (left).
    final outliner = web.HTMLDivElement()
      ..id = "wordproc-outliner"
      ..className = "wordproc-panel outliner";
    outliner.appendChild(web.HTMLHeadingElement.h2()..textContent = "Outliner");

    searchInput = web.HTMLInputElement()
      ..id = "wordproc-outline-search"
      ..className = "input"
      ..placeholder = "Search sections…";
    on(searchInput, "input", (_) => query.value = searchInput.value);
    outliner.appendChild(searchInput);

    final outlineMeta = web.HTMLParagraphElement()
      ..id = "wordproc-outline-meta"
      ..className = "muted";
    outlineMeta.appendChild(text(() => "Items: ${filtered.value.length}"));
    outliner.appendChild(outlineMeta);

    final list = web.HTMLDivElement()
      ..id = "wordproc-outline-list"
      ..className = "wordproc-outline-list";
    list.appendChild(
      For<WordprocSection, String>(
        each: () => filtered.value,
        key: (s) => s.id,
        children: (s) {
          final button = web.HTMLButtonElement()
            ..id = "wordproc-outline-item-${s().id}"
            ..type = "button"
            ..className = "wordproc-outline-item"
            ..setAttribute("data-section-id", s().id);
          button.appendChild(web.HTMLSpanElement()..textContent = s().title);
          classList(
            button,
            () => {
              "active": selectedId.value == s().id,
            },
          );
          on(button, "click", (_) => selectedId.value = s().id);
          return button;
        },
      ),
    );
    outliner.appendChild(list);

    // Editor (center). Mount a JS editor into #wordproc-editor-mount.
    final editor = web.HTMLDivElement()
      ..id = "wordproc-editor"
      ..className = "wordproc-panel editor";
    final editorHeader = web.HTMLDivElement()..className = "wordproc-panel-header";
    final editorTitle = web.HTMLHeadingElement.h2()..textContent = "Editor";
    final editorSub = web.HTMLParagraphElement()
      ..id = "wordproc-editor-selected"
      ..className = "muted";
    editorSub.appendChild(text(() => "${selectedTitle.value} (${selectedId.value})"));
    editorHeader.appendChild(editorTitle);
    editorHeader.appendChild(editorSub);
    editor.appendChild(editorHeader);

    final editorMount = web.HTMLDivElement()
      ..id = "wordproc-editor-mount"
      ..className = "wordproc-editor-mount";
    editor.appendChild(editorMount);

    // Agent (right).
    final agent = web.HTMLDivElement()
      ..id = "wordproc-agent"
      ..className = "wordproc-panel agent";
    agent.appendChild(web.HTMLHeadingElement.h2()..textContent = "Agent");

    final nextMsgId = createSignal(2);
    final messages = createSignal<List<({int id, String text})>>(<({int id, String text})>[
      (id: 1, text: "Try: select items, search, send a message."),
    ]);

    final log = web.HTMLDivElement()
      ..id = "wordproc-agent-log"
      ..className = "wordproc-agent-log";
    log.appendChild(
      For<({int id, String text}), int>(
        each: () => messages.value,
        key: (m) => m.id,
        children: (m) {
          final line = web.HTMLDivElement()..className = "wordproc-agent-msg";
          line.appendChild(web.HTMLSpanElement()..textContent = m().text);
          return line;
        },
      ),
    );
    agent.appendChild(log);

    final inputRow = web.HTMLDivElement()..className = "row";
    final msgInput = web.HTMLInputElement()
      ..id = "wordproc-agent-input"
      ..className = "input"
      ..placeholder = "Ask the agent…";
    final send = web.HTMLButtonElement()
      ..id = "wordproc-agent-send"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Send";
    void sendMessage() {
      final v = msgInput.value.trim();
      if (v.isEmpty) return;
      final id = nextMsgId.value;
      nextMsgId.value = id + 1;
      messages.value = <({int id, String text})>[...messages.value, (id: id, text: v)];
      msgInput.value = "";
      scheduleMicrotask(() => msgInput.focus());
    }

    on(send, "click", (_) => sendMessage());
    on(msgInput, "keydown", (e) {
      if (e is web.KeyboardEvent && e.key == "Enter") {
        e.preventDefault();
        sendMessage();
      }
    });
    inputRow.appendChild(msgInput);
    inputRow.appendChild(send);
    agent.appendChild(inputRow);

    void ensureEditorDocFor(String sectionId) {
      if (docsById.containsKey(sectionId)) return;
      final section = sections.value.firstWhere(
        (s) => s.id == sectionId,
        orElse: () => WordprocSection(id: sectionId, title: sectionId),
      );
      docsById[sectionId] = _defaultDocJson(section);
    }

    // Init the JS editor once the mount is connected.
    void initEditorWhenConnected() {
      if (!editorMount.isConnected) {
        scheduleMicrotask(initEditorWhenConnected);
        return;
      }
      if (editorReady.value) return;
      final current = selectedId.value;
      ensureEditorDocFor(current);
      wordprocEditorInit(editorMount, docsById[current]);
    }

    scheduleMicrotask(initEditorWhenConnected);

    // Track editor lifecycle.
    on(editorMount, "wordproc:editor-ready", (_) => editorReady.value = true);
    on(editorMount, "wordproc:editor-changed", (e) {
      final current = selectedId.value;
      if (e is! web.CustomEvent) return;
      final detail = e.detail;
      if (detail == null) return;
      final jsonStr = detail.toString();
      if (jsonStr.isEmpty) return;
      docsById[current] = jsonStr;
      persistTimer?.cancel();
      persistTimer = Timer(
        const Duration(milliseconds: 250),
        () => _persist(selectedId: selectedId.value, outline: sections.value, docsById: docsById),
      );
    });

    // Switch editor doc when the selected section changes.
    createEffect(() {
      final id = selectedId.value;
      // Always persist selection even if editor isn't ready yet.
      _persist(selectedId: id, outline: sections.value, docsById: docsById);
      if (!editorReady.value) return;
      ensureEditorDocFor(id);
      wordprocEditorSetDoc(editorMount, docsById[id]);
    });

    onCleanup(() {
      persistTimer?.cancel();
      if (editorMount.isConnected) {
        try {
          wordprocEditorDestroy(editorMount);
        } catch (_) {}
      }
    });

    // Heavy subtree mount/unmount to shake out lifecycle cleanup issues.
    final heavyMountHost = web.HTMLDivElement()..id = "wordproc-heavy-host";
    heavyMountHost.appendChild(
      Show(
        when: () => heavyMounted.value,
        children: () {
          final heavy = web.HTMLDivElement()
            ..id = "wordproc-heavy"
            ..className = "wordproc-heavy card";
          heavy.appendChild(
            web.HTMLHeadingElement.h2()..textContent = "Heavy subtree",
          );
          heavy.appendChild(
            web.HTMLParagraphElement()
              ..className = "muted"
              ..textContent = "Mount/unmount should not leak listeners.",
          );

          on(web.document, "click", (_) {});
          on(web.window, "resize", (_) {});
          onCleanup(() => cleanupCount.value++);

          final grid = web.HTMLDivElement()..className = "wordproc-heavy-grid";
          for (var i = 0; i < 80; i++) {
            final b = web.HTMLButtonElement()
              ..type = "button"
              ..className = "btn secondary"
              ..textContent = "Btn ${i + 1}";
            on(b, "click", (_) {});
            grid.appendChild(b);
          }
          heavy.appendChild(grid);
          return heavy;
        },
      ),
    );

    layout.appendChild(outliner);
    layout.appendChild(editor);
    layout.appendChild(agent);
    chrome.appendChild(layout);
    chrome.appendChild(heavyMountHost);

    root.appendChild(chrome);
    return root;
  });
}
