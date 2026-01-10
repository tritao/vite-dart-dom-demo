import "dart:convert";
import "dart:io";

final class PropsRow {
  PropsRow({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
    this.notes,
  });

  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
  final String? notes;

  Map<String, Object?> toJson() {
    final m = <String, Object?>{
      "name": name,
      "type": type,
    };
    if (required) m["required"] = true;
    if (defaultValue != null) m["default"] = defaultValue;
    if (notes != null && notes!.trim().isNotEmpty) m["notes"] = notes;
    return m;
  }
}

final class PropsSpec {
  PropsSpec({required this.title, required this.rows});
  final String title;
  final List<PropsRow> rows;

  Map<String, Object?> toJson() => {
        "title": title,
        "rows": [for (final r in rows) r.toJson()],
      };
}

Future<void> main(List<String> args) async {
  final strict = args.contains("--strict");
  final pathArg = args.where((a) => a != "--strict").toList();
  final outPath = pathArg.isNotEmpty ? pathArg.first : "docs/api/props.json";
  final names = _collectPropsNames();

  final old = _readExisting(outPath);
  final specs = <String, PropsSpec>{};

  // Components that don't have a 1:1 `Name(...)` UI function.
  const symbolOverrides = <String, String>{
    "Toast": "createToaster",
    "Listbox": "createListbox",
  };

  for (final name in names) {
    final symbol = symbolOverrides[name] ?? name;
    final extracted = _extractComponentSpec(symbol);

    final oldSpec = old[name];
    if (extracted == null) {
      // Keep the previous spec if present; avoids dropping docs tables for
      // components that don't map cleanly to a single function signature yet.
      if (oldSpec is Map) continue;
      stderr.writeln("[generate_props] WARN: could not find signature for $name");
      continue;
    }

    final title = name;
    if (oldSpec is Map) {
      final notesByParam = <String, String>{};
      final oldRows = oldSpec["rows"];
      for (final row in (oldRows is List ? oldRows : const [])) {
        if (row is! Map) continue;
        final paramName = row["name"];
        final notes = row["notes"];
        if (paramName is String && notes is String) {
          notesByParam[paramName] = notes;
        }
      }

      final mergedRows = <PropsRow>[];
      for (final r in extracted.rows) {
        mergedRows.add(
          PropsRow(
            name: r.name,
            type: r.type,
            required: r.required,
            defaultValue: r.defaultValue,
            notes: notesByParam[r.name],
          ),
        );
      }
      specs[name] = PropsSpec(title: title, rows: mergedRows);
    } else {
      specs[name] = PropsSpec(title: title, rows: extracted.rows);
    }
  }

  // Merge: generated specs override old ones; old ones fill gaps.
  final out = <String, Object?>{};
  for (final entry in old.entries) {
    if (!names.contains(entry.key)) continue;
    out[entry.key] = entry.value;
  }
  for (final entry in specs.entries) {
    out[entry.key] = entry.value.toJson();
  }

  final sortedKeys = out.keys.toList()..sort();
  final sortedOut = <String, Object?>{
    for (final k in sortedKeys) k: out[k],
  };

  final outFile = File(outPath);
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent("  ").convert(sortedOut));
  stdout.writeln("[generate_props] Wrote ${sortedKeys.length} specs -> $outPath");

  if (strict) {
    final empty = <String>[];
    for (final k in sortedKeys) {
      final v = sortedOut[k];
      if (v is! Map) continue;
      final rows = v["rows"];
      if (rows is List && rows.isEmpty) empty.add(k);
    }
    if (empty.isNotEmpty) {
      stderr.writeln("[generate_props] ERROR: empty props specs: ${empty.join(', ')}");
      exitCode = 1;
    }
  }
}

Set<String> _collectPropsNames() {
  final names = <String>{};
  final pagesRoot = Directory("docs/pages");
  if (!pagesRoot.existsSync()) return names;

  final re = RegExp(r":::props\s+name=([A-Za-z0-9_]+)");
  for (final ent in pagesRoot.listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    if (!ent.path.endsWith(".md")) continue;
    final raw = ent.readAsStringSync();
    for (final m in re.allMatches(raw)) {
      final name = m.group(1);
      if (name != null && name.isNotEmpty) names.add(name);
    }
  }
  return names;
}

Map<String, Object?> _readExisting(String path) {
  final f = File(path);
  if (!f.existsSync()) return const {};
  try {
    final v = jsonDecode(f.readAsStringSync());
    if (v is Map<String, Object?>) return v;
    if (v is Map) return v.cast<String, Object?>();
  } catch (_) {}
  return const {};
}

PropsSpec? _extractComponentSpec(String name) {
  // Prefer UI components; fall back to primitives/core if needed.
  final searchDirs = <String>[
    "lib/solidus_ui",
    "lib/solidus_dom/core",
    "lib/solidus_dom",
    "lib",
  ];

  for (final dir in searchDirs) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final ent in d.listSync(recursive: true, followLinks: false)) {
      if (ent is! File) continue;
      if (!ent.path.endsWith(".dart")) continue;
      final raw = ent.readAsStringSync();
      final sig = _findFunctionSignature(raw, name);
      if (sig == null) continue;
      final rows = _parseNamedParams(sig);
      return PropsSpec(title: name, rows: rows);
    }
  }
  return null;
}

String? _findFunctionSignature(String raw, String name) {
  // Match `Name<...>(...)` or `Name(...)` (for generic helpers like Select<T>).
  final re = RegExp(
    r"(^|\n)\s*[^\n;]*\b" + name + r"(?:<[^\n]*>)?\s*\(",
    multiLine: true,
  );
  Match? m;
  for (final cand in re.allMatches(raw)) {
    // Skip comment lines like `/// Styled X (foo)`.
    final nameIndex = raw.indexOf(name, cand.start);
    if (nameIndex == -1 || nameIndex >= cand.end) continue;
    final lineStart = raw.lastIndexOf("\n", nameIndex) + 1;
    final lineEnd = raw.indexOf("\n", lineStart);
    final line =
        (lineEnd == -1 ? raw.substring(lineStart) : raw.substring(lineStart, lineEnd))
            .trimLeft();
    if (line.startsWith("//") || line.startsWith("/*") || line.startsWith("*")) {
      continue;
    }
    m = cand;
    break;
  }
  if (m == null) return null;

  final startParen = m.end - 1; // regex ends at '('

  var i = startParen;
  var depth = 0;
  var inSingle = false;
  var inDouble = false;
  for (; i < raw.length; i++) {
    final ch = raw[i];
    if (inSingle) {
      if (ch == "'" && raw[i - 1] != "\\") inSingle = false;
      continue;
    }
    if (inDouble) {
      if (ch == "\"" && raw[i - 1] != "\\") inDouble = false;
      continue;
    }
    if (ch == "'") {
      inSingle = true;
      continue;
    }
    if (ch == "\"") {
      inDouble = true;
      continue;
    }
    if (ch == "(") depth++;
    if (ch == ")") {
      depth--;
      if (depth == 0) {
        return raw.substring(startParen, i + 1);
      }
    }
  }
  return null;
}

List<PropsRow> _parseNamedParams(String sig) {
  // sig includes surrounding parens: `( ... )`
  final start = sig.indexOf("{");
  final end = sig.lastIndexOf("}");
  if (start == -1 || end == -1 || end <= start) return const [];
  final inner = sig.substring(start + 1, end).trim();
  if (inner.isEmpty) return const [];

  final parts = _splitTopLevel(inner);
  final rows = <PropsRow>[];
  for (final rawPart in parts) {
    var part = rawPart.trim();
    if (part.isEmpty) continue;
    if (part.startsWith("//")) continue;
    if (part.startsWith("/*")) continue;

    var isRequired = false;
    if (part.startsWith("required ")) {
      isRequired = true;
      part = part.substring("required ".length).trim();
    }

    String? defaultValue;
    final eq = _indexOfTopLevelEquals(part);
    if (eq != -1) {
      defaultValue = part.substring(eq + 1).trim();
      part = part.substring(0, eq).trim();
    }

    // Strip trailing commas.
    if (part.endsWith(",")) part = part.substring(0, part.length - 1).trim();
    if (part.isEmpty) continue;

    final tokens = part.split(RegExp(r"\s+")).where((t) => t.isNotEmpty).toList();
    if (tokens.length < 2) continue;
    final paramName = tokens.last;
    final type = tokens.sublist(0, tokens.length - 1).join(" ");

    rows.add(
      PropsRow(
        name: paramName,
        type: type,
        required: isRequired,
        defaultValue: defaultValue,
      ),
    );
  }
  return rows;
}

int _indexOfTopLevelEquals(String s) {
  var angle = 0;
  var paren = 0;
  var bracket = 0;
  var brace = 0;
  var inSingle = false;
  var inDouble = false;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (inSingle) {
      if (ch == "'" && s[i - 1] != "\\") inSingle = false;
      continue;
    }
    if (inDouble) {
      if (ch == "\"" && s[i - 1] != "\\") inDouble = false;
      continue;
    }
    if (ch == "'") {
      inSingle = true;
      continue;
    }
    if (ch == "\"") {
      inDouble = true;
      continue;
    }
    if (ch == "<") angle++;
    if (ch == ">") angle = angle > 0 ? angle - 1 : 0;
    if (ch == "(") paren++;
    if (ch == ")") paren = paren > 0 ? paren - 1 : 0;
    if (ch == "[") bracket++;
    if (ch == "]") bracket = bracket > 0 ? bracket - 1 : 0;
    if (ch == "{") brace++;
    if (ch == "}") brace = brace > 0 ? brace - 1 : 0;
    if (ch == "=" && angle == 0 && paren == 0 && bracket == 0 && brace == 0) {
      return i;
    }
  }
  return -1;
}

List<String> _splitTopLevel(String s) {
  final out = <String>[];
  final buf = StringBuffer();
  var angle = 0;
  var paren = 0;
  var bracket = 0;
  var brace = 0;
  var inSingle = false;
  var inDouble = false;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (inSingle) {
      buf.write(ch);
      if (ch == "'" && s[i - 1] != "\\") inSingle = false;
      continue;
    }
    if (inDouble) {
      buf.write(ch);
      if (ch == "\"" && s[i - 1] != "\\") inDouble = false;
      continue;
    }
    if (ch == "'") {
      inSingle = true;
      buf.write(ch);
      continue;
    }
    if (ch == "\"") {
      inDouble = true;
      buf.write(ch);
      continue;
    }

    if (ch == "<") angle++;
    if (ch == ">") angle = angle > 0 ? angle - 1 : 0;
    if (ch == "(") paren++;
    if (ch == ")") paren = paren > 0 ? paren - 1 : 0;
    if (ch == "[") bracket++;
    if (ch == "]") bracket = bracket > 0 ? bracket - 1 : 0;
    if (ch == "{") brace++;
    if (ch == "}") brace = brace > 0 ? brace - 1 : 0;

    if (ch == "," && angle == 0 && paren == 0 && bracket == 0 && brace == 0) {
      out.add(buf.toString());
      buf.clear();
      continue;
    }
    buf.write(ch);
  }
  final tail = buf.toString();
  if (tail.trim().isNotEmpty) out.add(tail);
  return out;
}
