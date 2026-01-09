import "dart:convert";
import "dart:io";

import "package:markdown/markdown.dart" as md;
import "package:yaml/yaml.dart";

import "./generate_props.dart" as gen;

final class DocsPage {
  DocsPage({
    required this.sourcePath,
    required this.slug,
    required this.title,
    required this.group,
    required this.order,
    required this.description,
    required this.labHref,
    required this.status,
    required this.tags,
    required this.html,
  });

  final String sourcePath;
  final String slug;
  final String title;
  final String group;
  final int order;
  final String? description;
  final String? labHref;
  final String status;
  final List<String> tags;
  final String html;

  Map<String, Object?> toJson() => {
        "slug": slug,
        "title": title,
        "group": group,
        "order": order,
        "description": description,
        "labHref": labHref,
        "status": status,
        "tags": tags,
        "sourcePath": sourcePath,
      };
}

Future<void> main(List<String> args) async {
  // Keep `docs/api/props.json` in sync with source by generating it before
  // building pages (avoids drift from manual edits).
  try {
    await gen.main(const []);
  } catch (e) {
    stderr.writeln("WARN: props generation failed: $e");
  }

  final pagesRoot = Directory("docs/pages");
  if (!pagesRoot.existsSync()) {
    stderr.writeln("Missing docs/pages. Nothing to build.");
    exitCode = 1;
    return;
  }

  final outRoot = Directory("public/assets/docs");
  final outPages = Directory("public/assets/docs/pages");

  if (outRoot.existsSync()) {
    outRoot.deleteSync(recursive: true);
  }
  outPages.createSync(recursive: true);

  final pages = <DocsPage>[];
  await for (final ent in pagesRoot.list(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    if (!ent.path.endsWith(".md")) continue;
    final raw = await ent.readAsString();
    final parsed = _parseFrontmatter(raw);
    final meta = parsed.meta;
    final body = parsed.body;

    final slug = _string(meta["slug"]) ?? _slugFromPath(ent.path);
    final title = _string(meta["title"]) ?? slug;
    final group = _string(meta["group"]) ?? "Docs";
    final order = _int(meta["order"]) ?? 1000;
    final description = _string(meta["description"]);
    final labHref = _string(meta["labHref"]);
    final status = _string(meta["status"]) ?? "draft";
    final tags = _stringList(meta["tags"]);

    final html = _renderMarkdownWithDirectives(body, labHref: labHref);

    pages.add(
      DocsPage(
        sourcePath: ent.path,
        slug: slug,
        title: title,
        group: group,
        order: order,
        description: description,
        labHref: labHref,
        status: status,
        tags: tags,
        html: html,
      ),
    );

    final outFile = File("public/assets/docs/pages/$slug.html");
    outFile.createSync(recursive: true);
    await outFile.writeAsString(html);
  }

  pages.sort((a, b) {
    final g = a.group.compareTo(b.group);
    if (g != 0) return g;
    final o = a.order.compareTo(b.order);
    if (o != 0) return o;
    return a.title.compareTo(b.title);
  });

  final groups = <String, List<DocsPage>>{};
  for (final p in pages) {
    (groups[p.group] ??= <DocsPage>[]).add(p);
  }

  final manifest = {
    "generatedAt": DateTime.now().toUtc().toIso8601String(),
    "groups": [
      for (final entry in groups.entries)
        {
          "label": entry.key,
          "pages": [for (final p in entry.value) p.toJson()],
        }
    ],
  };

  final manifestFile = File("public/assets/docs/manifest.json");
  await manifestFile.writeAsString(const JsonEncoder.withIndent("  ").convert(manifest));

  _copyOptionalDocsAssets();
  stdout.writeln("Built ${pages.length} docs page(s) -> public/assets/docs/");
}

void _copyOptionalDocsAssets() {
  final outDir = Directory("public/assets/docs");
  outDir.createSync(recursive: true);

  final props = File("docs/api/props.json");
  if (props.existsSync()) {
    props.copySync("public/assets/docs/props.json");
  }
}

({Map<String, Object?> meta, String body}) _parseFrontmatter(String raw) {
  final trimmed = raw.replaceAll("\r\n", "\n");
  if (!trimmed.startsWith("---\n")) {
    return (meta: const {}, body: trimmed);
  }
  final end = trimmed.indexOf("\n---\n", 4);
  if (end == -1) {
    return (meta: const {}, body: trimmed);
  }
  final fm = trimmed.substring(4, end);
  final body = trimmed.substring(end + 5);

  final yaml = loadYaml(fm);
  if (yaml is! YamlMap) {
    return (meta: const {}, body: body);
  }

  final meta = <String, Object?>{};
  for (final key in yaml.keys) {
    if (key is! String) continue;
    meta[key] = yaml[key];
  }
  return (meta: meta, body: body);
}

String _renderMarkdownWithDirectives(String raw, {String? labHref}) {
  final normalized = raw.replaceAll("\r\n", "\n");
  final expanded = _expandDirectives(normalized, labHref: labHref);
  final html = md.markdownToHtml(
    expanded,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );
  return _wrapMarkedCodeBlocks(html);
}

String _expandDirectives(String input, {String? labHref}) {
  final lines = input.split("\n");
  final out = StringBuffer();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!line.startsWith(":::")) {
      out.writeln(line);
      continue;
    }

    final header = line.substring(3).trim();
    final parts = header.split(RegExp(r"\s+"));
    final kind = parts.isEmpty ? "" : parts.first;
    final attrs = _parseAttrs(parts.skip(1).join(" "));

    final bodyLines = <String>[];
    i++;
    for (; i < lines.length; i++) {
      if (lines[i].trim() == ":::") break;
      bodyLines.add(lines[i]);
    }
    final body = bodyLines.join("\n").trim();

    if (kind == "demo") {
      final id = attrs["id"] ?? "";
      final title = attrs["title"] ?? "Demo";
      final bodyHtml = body.isEmpty ? "" : md.markdownToHtml(body, extensionSet: md.ExtensionSet.gitHubFlavored);
      final openLab = (labHref ?? attrs["labHref"])?.trim();
      out.writeln('<div class="docDemo card">');
      out.writeln('  <div class="docDemoHeader">');
      out.writeln('    <div class="docDemoTitle">');
      out.writeln('      <span class="docBadge">Example</span>');
      out.writeln('      <strong>${_escapeHtml(title)}</strong>');
      out.writeln("    </div>");
      if (openLab != null && openLab.isNotEmpty) {
        out.writeln('    <a class="btn secondary" href="${_escapeHtml(openLab)}">Open lab</a>');
      }
      out.writeln("  </div>");
      if (bodyHtml.isNotEmpty) {
        out.writeln('  <div class="docDemoDesc muted">$bodyHtml</div>');
      }
      out.writeln('  <div class="docDemoMount" data-doc-demo="${_escapeHtml(id)}"></div>');
      out.writeln("</div>");
      continue;
    }

    if (kind == "code") {
      final file = attrs["file"];
      final region = attrs["region"];
      final lang = attrs["lang"] ?? "text";
      final code = file == null ? "" : _readRegion(file, region: region);
      // Use fenced code blocks (so markdown handles escaping), and add marker
      // comments so we can wrap the resulting <pre> in a <details> block.
      out.writeln("<!--DOC_CODE_START-->");
      out.writeln("```$lang");
      out.writeln(code);
      out.writeln("```");
      out.writeln("<!--DOC_CODE_END-->");
      continue;
    }

    if (kind == "props") {
      final name = attrs["name"] ?? "";
      out.writeln('<div class="docProps card" data-doc-props="${_escapeHtml(name)}"></div>');
      continue;
    }

    if (kind == "note" || kind == "warning" || kind == "tip") {
      final bodyHtml = body.isEmpty ? "" : md.markdownToHtml(body, extensionSet: md.ExtensionSet.gitHubFlavored);
      out.writeln('<div class="docCallout docCallout-${_escapeHtml(kind)}">');
      out.writeln('  <div class="docCalloutTitle">${_escapeHtml(kind.toUpperCase())}</div>');
      out.writeln('  <div class="docCalloutBody">$bodyHtml</div>');
      out.writeln("</div>");
      continue;
    }

    out.writeln(body);
  }

  return out.toString();
}

String _wrapMarkedCodeBlocks(String html) {
  const start = "<!--DOC_CODE_START-->";
  const end = "<!--DOC_CODE_END-->";
  var out = html;

  while (true) {
    final s = out.indexOf(start);
    if (s == -1) break;
    final preStart = out.indexOf("<pre", s);
    if (preStart == -1) break;
    final preEnd = out.indexOf("</pre>", preStart);
    if (preEnd == -1) break;
    final e = out.indexOf(end, preEnd);
    if (e == -1) break;

    final block = out.substring(preStart, preEnd + "</pre>".length);
    final replacement = [
      '<details class="docCodeBlock">',
      "<summary>Code</summary>",
      block,
      "</details>",
    ].join("\n");

    out = out.substring(0, s) + replacement + out.substring(e + end.length);
  }

  return out;
}

Map<String, String> _parseAttrs(String raw) {
  final out = <String, String>{};
  final re = RegExp('(\\w+)=("([^"]*)"|\\\'([^\\\']*)\\\'|(\\S+))');
  for (final m in re.allMatches(raw)) {
    final key = m.group(1)!;
    final value = m.group(3) ?? m.group(4) ?? m.group(5) ?? "";
    out[key] = value;
  }
  return out;
}

String _readRegion(String path, {String? region}) {
  final file = File(path);
  if (!file.existsSync()) return "";
  final contents = file.readAsStringSync().replaceAll("\r\n", "\n");
  if (region == null || region.isEmpty) return contents;

  final start = "// #doc:region $region";
  final end = "// #doc:endregion $region";
  final startIdx = contents.indexOf(start);
  if (startIdx == -1) return contents;
  final endIdx = contents.indexOf(end, startIdx + start.length);
  if (endIdx == -1) return contents.substring(startIdx + start.length).trim();

  return contents.substring(startIdx + start.length, endIdx).trim();
}

String _escapeHtml(String input) {
  return input
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
}

String _slugFromPath(String path) {
  final name = path.split(Platform.pathSeparator).last;
  return name.endsWith(".md") ? name.substring(0, name.length - 3) : name;
}

String? _string(Object? v) => v is String ? v : null;

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

List<String> _stringList(Object? v) {
  if (v is YamlList) {
    return [for (final e in v) if (e is String) e];
  }
  if (v is List) {
    return [for (final e in v) if (e is String) e];
  }
  return const [];
}
